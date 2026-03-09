import Foundation
import os

fileprivate let logger = Logger(subsystem: "GeographicLib", category: "GeographicLib")

public let WGS84_SEMIMAJOR_AXIS: Double = 6_378_137
public let WGS84_FLATTENING: Double = 1 / 298.257223563

private let GEODESIC_ORDER = 6
private let nA1 = GEODESIC_ORDER
private let nC1 = GEODESIC_ORDER
private let nC1p = GEODESIC_ORDER
private let nA2 = GEODESIC_ORDER
private let nC2 = GEODESIC_ORDER
private let nA3 = GEODESIC_ORDER
private let nA3x = nA3
private let nC3 = GEODESIC_ORDER
private let nC3x = (nC3 * (nC3 - 1)) / 2
private let nC4 = GEODESIC_ORDER
private let nC4x = (nC4 * (nC4 + 1)) / 2
private let nC = GEODESIC_ORDER + 1
private let maxit1  = 20
private let maxit2  = maxit1 + Int(Double.significandBitCount) + 10

private let tiny = sqrt(Double.leastNormalMagnitude)
private let tol0 = Double.ulpOfOne
private let tol1 = 200 * tol0
private let tol2 = sqrt(tol0)
private let tolb = tol0
private let xthresh = 1000 * tol2

private let degree  = Double.pi / hd

// quarter turn, half turn, full turn in degrees
private let qd = 90.0
private let hd = 180.0
private let td = 360.0

public enum Capability: Sendable, CaseIterable {
	case latitude
	case longitude
	case azimuth
	case distance
	case distanceIn
	case reducedLength
	case geodesicScale
	case area
}

public let ALL_CAPS = Set<Capability>(Capability.allCases)
public let NO_CAPS = Set<Capability>()

let CAP_C1 = Set<Capability>([.distance, .distanceIn, .reducedLength, .geodesicScale]) // 1U<<0
let CAP_C1P = Set<Capability>([.distanceIn]) // 1U<<1
let CAP_C2 = Set<Capability>([.reducedLength, .geodesicScale]) // 1U<<2
let CAP_C3 = Set<Capability>([.longitude]) // 1U<<3
let CAP_C4 = Set<Capability>([.area]) // 1U << 4
// CAP_ALL 0x1FU
// OUT_ALL = 0x7F80U

public enum Flag {
	case arcMode
	case longitudeUnroll
}

// MARK: - Math helpers

private func sq(_ x: Double) -> Double {
	pow(x, 2)
}

/// Error-free sum: returns s = u + v, sets t = error term.
private func sum(_ u: Double, _ v: Double) -> (s: Double, t: Double) {
	let s = u + v
	var up = s - v
	var vpp = s - up
	up -= u
	vpp -= v

	let t: Double = s != 0 ? 0 - (up + vpp) : s

	return (s, t)
}

// Polynomial evaluation
private func polyval(_ N: Int, _ p: [Double], _ start: Int, _ x: Double) -> Double {
	var idx = start
	var y = N < 0 ? 0.0 : p[start]

	guard N > 0 else { return y }

	for _ in stride(from: N, through: 1, by: -1) {
		idx += 1
		y = y * x + p[idx]
	}

	return y
}

private func norm(_ sinx: inout Double, _ cosx: inout Double) {
	let r = hypot(sinx, cosx)
	sinx /= r
	cosx /= r
}

/// angNormalize clamps the angle to [-180, 180]
private func angNormalize(_ x: Double) -> Double {
	let y = x.remainder(dividingBy: td)
	return abs(y) == hd ? copysign(hd, x) : y
}

/// latFix verifies the supplied latitude is valid (within [-90, 90]) and returns NaN otherwise.
private func latFix(_ x: Double) -> Double {
	abs(x) > qd ? .nan : x
}

/// angDiff calculates the rotational difference between two angles, clamped to [-360, 360]
private func angDiff(_ x: Double, _ y: Double) -> (d: Double, e: Double) {
	let r1 = -x.remainder(dividingBy: td)
	let r2 = y.remainder(dividingBy: td)
	var (d, t) = sum(r1, r2)
	(d, t) = sum(d.remainder(dividingBy: td), t)
	if d == 0 || abs(d) == hd {
		d = copysign(d, t == 0 ? y - x : -t)
	}
	return (d, t)
}

private func angRound(_ x: Double) -> Double {
	let z = 1.0 / 16.0
	var y = abs(x)
	let w = z - y

	y = w > 0 ? z - w : y

	return copysign(y, x)
}

/// sincosd computes the sine and cosine of x in degrees
private func sincosd(_ x: Double) -> (sin: Double, cos: Double) {
	var qi: Int32 = 0
	let r = remquo(x, qd, &qi)
	let q = Int(qi)

	let rad = r * degree
	let s = sin(rad)
	let c = cos(rad)

	var sinx: Double
	var cosx: Double
	switch (q & 3) {
	case 0:
		sinx = s
		cosx = c
	case 1:
		sinx = c
		cosx = -s
	case 2:
		sinx = -s
		cosx = -c
	default:
		sinx = -c
		cosx = s
	}
	
	if sinx == 0 {
		sinx = copysign(sinx, x)
	}
	return (sinx, cosx)
}

// sincosde computes the sine and cosine of (x + t) in degrees and clamps it to [-180, 180]
private func sincosde(_ x: Double, _ t: Double) -> (sin: Double, cos: Double) {
	var q: Int32 = 0
	let raw = remquo(x, qd, &q)
	let r = angRound(raw + t) * degree
	let s = sin(r)
	let c = cos(r)

	var sinx: Double
	var cosx: Double
	switch (Int(q) & 3) {
	case 0:
		sinx =  s
		cosx =  c
	case 1:
		sinx =  c
		cosx = -s
	case 2:
		sinx = -s
		cosx = -c
	default:
		sinx = -c
		cosx =  s
	}
	if sinx == 0 {
		sinx = copysign(sinx, x)
	}
	return (sinx, cosx)
}

/// atan2d copmutes atan2(y, x) in degrees
private func atan2d(_ y: Double, _ x: Double) -> Double {
	/* In order to minimize round-off errors, this function rearranges the
	 * arguments so that result of atan2 is in the range [-pi/4, pi/4] before
	 * converting it to degrees and mapping the result to the correct
	 * quadrant.
	 */
	var q: Int = 0
	var modX: Double = x, modY: Double = y

	if abs(modY) > abs(modX) {
		modX = y
		modY = x
		q = 2
	}

	if modX < 0 {
		modX = -modX
		q += 1
	}

	/* here x >= 0 and x >= abs(y), so angle is in [-pi/4, pi/4] */
	var ang = atan2(modY, modX) / degree

	switch (q) {
	case 1:
		ang = copysign(hd, modY) - ang
	case 2:
		ang = qd - ang
	case 3:
		ang = -qd + ang
	default:
		break
	}

	return ang
}

public struct Geodesic: Sendable {
	let equatorialRadius: Double  // a
	let flattening: Double        // f

	// Derived
	internal let f1: Double    // 1 - f
	internal let e2: Double    // f*(2-f)
	internal let ep2: Double   // e2/(1-e2)
	internal let n: Double     // f/(2-f)
	internal let b: Double     // a*f1
	internal let c2: Double    // authalic radius squared
	internal let etol2: Double

	// Coefficient arrays
	internal let A3x: [Double]
	internal let C3x: [Double]
	internal let C4x: [Double]

	public static let WGS84 = Geodesic(
		equatorialRadius: WGS84_SEMIMAJOR_AXIS,
		flattening: WGS84_FLATTENING
	)

	public init(equatorialRadius a: Double, flattening f: Double) {
		self.equatorialRadius = a
		self.flattening = f
		self.f1 = 1 - flattening
		self.e2 = flattening * (2 - flattening)
		self.ep2 = e2 / sq(f1)
		self.n = flattening / (2 - flattening)
		self.b =  equatorialRadius * f1

		// Authalic radius squared
		if e2 == 0 {
			self.c2 = (sq(equatorialRadius) + sq(b)) / 2
		} else if e2 > 0 {
			self.c2 = (sq(equatorialRadius) + sq(b) * (atanh(sqrt(e2)) / sqrt(abs(e2)))) / 2
		} else {
			self.c2 = (sq(equatorialRadius) + sq(b) * (atan(sqrt(-e2)) / sqrt(abs(e2)))) / 2
		}

		self.etol2 = 0.1 * tol2 / sqrt(max(0.001, abs(flattening)) * min(1.0, 1 - flattening / 2) / 2)

		self.A3x = Geodesic.computeA3x(n: n)
		self.C3x = Geodesic.computeC3x(n: n)
		self.C4x = Geodesic.computeC4x(n: n)
	}

	private static func computeA3x(n: Double) -> [Double] {
		let coeff: [Double] = [
			-3, 128,
			 -2, -3, 64,
			 -1, -3, -1, 16,
			 3, -1, -2, 8,
			 1, -1, 2,
			 1, 1,
		]
		var A3x = [Double](repeating: 0, count: nA3x)
		var o = 0
		var k = 0
		for j in stride(from: nA3 - 1, through: 0, by: -1) {
			let m = min(nA3 - j - 1, j)
			A3x[k] = polyval(m, coeff, o, n) / coeff[o + m + 1]
			k += 1
			o += m + 2
		}
		return A3x
	}

	private static func computeC3x(n: Double) -> [Double] {
		let coeff: [Double] = [
			3, 128,
			2, 5, 128,
			-1, 3, 3, 64,
			-1, 0, 1, 8,
			-1, 1, 4,
			5, 256,
			1, 3, 128,
			-3, -2, 3, 64,
			1, -3, 2, 32,
			7, 512,
			-10, 9, 384,
			5, -9, 5, 192,
			7, 512,
			-14, 7, 512,
			21, 2560,
		]
		var C3x = [Double](repeating: 0, count: nC3x)
		var o = 0
		var k = 0
		for l in 1..<nC3 {
			for j in stride(from: nC3 - 1, through: l, by: -1) {
				let m = min(nC3 - j - 1, j)
				C3x[k] = polyval(m, coeff, o, n) / coeff[o + m + 1]
				k += 1
				o += m + 2
			}
		}
		return C3x
	}

	private static func computeC4x(n: Double) -> [Double] {
		let coeff: [Double] = [
			97, 15015,
			1088, 156, 45045,
			-224, -4784, 1573, 45045,
			-10656, 14144, -4576, -858, 45045,
			64, 624, -4576, 6864, -3003, 15015,
			100, 208, 572, 3432, -12012, 30030, 45045,
			1, 9009,
			-2944, 468, 135135,
			5792, 1040, -1287, 135135,
			5952, -11648, 9152, -2574, 135135,
			-64, -624, 4576, -6864, 3003, 135135,
			8, 10725,
			1856, -936, 225225,
			-8448, 4992, -1144, 225225,
			-1440, 4160, -4576, 1716, 225225,
			-136, 63063,
			1024, -208, 105105,
			3584, -3328, 1144, 315315,
			-128, 135135,
			-2560, 832, 405405,
			128, 99099,
		]
		var C4x = [Double](repeating: 0, count: nC4x)
		var o = 0
		var k = 0
		for l in 0..<nC4 {
			for j in stride(from: nC4 - 1, through: l, by: -1) {
				let m = nC4 - j - 1
				C4x[k] = polyval(m, coeff, o, n) / coeff[o + m + 1]
				k += 1
				o += m + 2
			}
		}
		return C4x
	}

	internal func a3f(_ eps: Double) -> Double {
		polyval(nA3 - 1, A3x, 0, eps)
	}

	internal func c3f(_ eps: Double, _ c: inout [Double]) {
		var mult = 1.0
		var o = 0
		for l in 1..<nC3 {
			let m = nC3 - l - 1
			mult *= eps
			c[l] = mult * polyval(m, C3x, o, eps)
			o += m + 1
		}
	}

	internal func c4f(_ eps: Double, _ c: inout [Double]) {
		var mult = 1.0
		var o = 0
		for l in 0..<nC4 {
			let m = nC4 - l - 1
			c[l] = mult * polyval(m, C4x, o, eps)
			o += m + 1
			mult *= eps
		}
	}

	internal func genposition(
		line: Line,
		s12_a12: Double,
		flags: Set<Flag>,
	) -> GeneralDirectGeodesicResult {
		var lat2: Double = 0, lon2: Double = 0, azi2: Double = 0, s12: Double = 0, m12: Double = 0, M12: Double = 0, M21: Double = 0, S12: Double = 0
		/* Avoid warning about uninitialized B12. */
		var sig12: Double, ssig12: Double, csig12: Double, B12: Double = 0, AB1: Double = 0
		var omg12: Double, lam12: Double, lon12: Double
		var ssig2: Double, csig2: Double, sbet2: Double, cbet2: Double, somg2: Double, comg2: Double, salp2: Double, calp2: Double, dn2: Double
		
		if (
			!(
				flags.contains(.arcMode) ||
				line.capabilities.contains(.distanceIn)
			)
		) {
			/* Impossible distance calculation requested */
			return GeneralDirectGeodesicResult(latitude: .nan, longitude: .nan, azimuth: .nan, distance: .nan, m12: .nan, M12: .nan, M21: .nan, areaUnder: .nan, arcLength: .nan)
		}

		if flags.contains(.arcMode) {
			/* Interpret s12_a12 as spherical arc length */
			sig12 = s12_a12 * degree
			(ssig12, csig12) = sincosd(s12_a12)
		} else {
			/* Interpret s12_a12 as distance */
			let tau12 = s12_a12 / (line.b * (1 + line.A1m1))
			let s = sin(tau12)
			let c = cos(tau12)
			B12 = -sinCosSeries(true,
								line.stau1 * c + line.ctau1 * s,
								line.ctau1 * c - line.stau1 * s,
								line.C1pa,
								nC1p)
			sig12 = tau12 - (B12 - line.B11)
			ssig12 = sin(sig12)
			csig12 = cos(sig12)
			if (abs(line.flattening) > 0.01) {
				/* Reverted distance series is inaccurate for |f| > 1/100, so correct
				 * sig12 with 1 Newton iteration.  The following table shows the
				 * approximate maximum error for a = WGS_a() and various f relative to
				 * GeodesicExact.
				 *     erri = the error in the inverse solution (nm)
				 *     errd = the error in the direct solution (series only) (nm)
				 *     errda = the error in the direct solution (series + 1 Newton) (nm)
				 *
				 *       f     erri  errd errda
				 *     -1/5    12e6 1.2e9  69e6
				 *     -1/10  123e3  12e6 765e3
				 *     -1/20   1110 108e3  7155
				 *     -1/50  18.63 200.9 27.12
				 *     -1/100 18.63 23.78 23.37
				 *     -1/150 18.63 21.05 20.26
				 *      1/150 22.35 24.73 25.83
				 *      1/100 22.35 25.03 25.31
				 *      1/50  29.80 231.9 30.44
				 *      1/20   5376 146e3  10e3
				 *      1/10  829e3  22e6 1.5e6
				 *      1/5   157e6 3.8e9 280e6 */
				ssig2 = line.ssig1 * csig12 + line.csig1 * ssig12
				csig2 = line.csig1 * csig12 - line.ssig1 * ssig12
				B12 = sinCosSeries(true, ssig2, csig2, line.C1a, nC1)
				let serr = (1 + line.A1m1) * (sig12 + (B12 - line.B11)) - s12_a12 / line.b
				sig12 = sig12 - serr / sqrt(1 + line.k2 * sq(ssig2))
				ssig12 = sin(sig12)
				csig12 = cos(sig12)
				/* Update B12 below */
			}
		}
		
		/* sig2 = sig1 + sig12 */
		ssig2 = line.ssig1 * csig12 + line.csig1 * ssig12
		csig2 = line.csig1 * csig12 - line.ssig1 * ssig12
		dn2 = sqrt(1 + line.k2 * sq(ssig2))
		
		if line.capabilities.intersection(Set<Capability>([.distance, .reducedLength, .geodesicScale])).count > 0 {
			if (flags.contains(.arcMode) || fabs(line.flattening) > 0.01) {
				B12 = sinCosSeries(true, ssig2, csig2, line.C1a, nC1)
			}
			AB1 = (1 + line.A1m1) * (B12 - line.B11)
		}
		
		sbet2 = line.calp0 * ssig2
		
		cbet2 = hypot(line.salp0, line.calp0 * csig2)
		
		if (cbet2 == 0) {
			cbet2 = tiny
			csig2 = tiny
		}
		
		salp2 = line.salp0
		calp2 = line.calp0 * csig2 /* No need to normalize */
		
		if (line.capabilities.contains(.distance)) {
			s12 = flags.contains(.arcMode) ? line.b * ((1 + line.A1m1) * sig12 + AB1) : s12_a12
		}
		
		if (line.capabilities.contains(.longitude)) {
			let E: Double = copysign(1, line.salp0) /* east or west going? */
			somg2 = line.salp0 * ssig2
			comg2 = csig2  /* No need to normalize */
			omg12 = flags.contains(.longitudeUnroll) ? E * (
				sig12 - (atan2(ssig2, csig2) - atan2(line.ssig1, line.csig1)) + (atan2(E * somg2, comg2) - atan2(E * line.somg1, line.comg1))
			) : (
				atan2(somg2 * line.comg1 - comg2 * line.somg1, comg2 * line.comg1 + somg2 * line.somg1)
			)
			lam12 = omg12 + line.A3c * ( sig12 + (sinCosSeries(true, ssig2, csig2, line.C3a, nC3-1) - line.B31))
			lon12 = lam12 / degree
			lon2 = flags.contains(.longitudeUnroll) ? line.longitude + lon12 : angNormalize(angNormalize(line.longitude) + angNormalize(lon12))
		}

		if (line.capabilities.contains(.latitude)) {
			lat2 = atan2d(sbet2, line.f1 * cbet2)
		}

		if (line.capabilities.contains(.azimuth)) {
			azi2 = atan2d(salp2, calp2)
		}

		if line.capabilities.intersection(Set<Capability>([.reducedLength, .geodesicScale])).count > 0 {
			let B22: Double = sinCosSeries(true, ssig2, csig2, line.C2a, nC2)
			let AB2: Double = (1 + line.A2m1) * (B22 - line.B21)
			let J12: Double = (line.A1m1 - line.A2m1) * sig12 + (AB1 - AB2)
			if line.capabilities.contains(.reducedLength) {
				/* Add parens around (csig1 * ssig2) and (ssig1 * csig2) to ensure
				 * accurate cancellation in the case of coincident points. */
				m12 = line.b * ((dn2 * (line.csig1 * ssig2) - line.dn1 * (line.ssig1 * csig2)) - line.csig1 * csig2 * J12)
			}
			if line.capabilities.contains(.geodesicScale) {
				let t: Double = line.k2 * (ssig2 - line.ssig1) * (ssig2 + line.ssig1) / (line.dn1 + dn2)
				M12 = csig12 + (t *  ssig2 -  csig2 * J12) * line.ssig1 / line.dn1
				M21 = csig12 - (t * line.ssig1 - line.csig1 * J12) *  ssig2 /  dn2
			}
		}

		if line.capabilities.contains(.area) {
			let B42: Double = sinCosSeries(false, ssig2, csig2, line.C4a, nC4)
			let salp12: Double, calp12: Double
			if (line.calp0 == 0 || line.salp0 == 0) {
				/* alp12 = alp2 - alp1, used in atan2 so no need to normalize */
				salp12 = salp2 * line.calp1 - calp2 * line.salp1
				calp12 = calp2 * line.calp1 + salp2 * line.salp1
			} else {
				/* tan(alp) = tan(alp0) * sec(sig)
				 * tan(alp2-alp1) = (tan(alp2) -tan(alp1)) / (tan(alp2)*tan(alp1)+1)
				 * = calp0 * salp0 * (csig1-csig2) / (salp0^2 + calp0^2 * csig1*csig2)
				 * If csig12 > 0, write
				 *   csig1 - csig2 = ssig12 * (csig1 * ssig12 / (1 + csig12) + ssig1)
				 * else
				 *   csig1 - csig2 = csig1 * (1 - csig12) + ssig12 * ssig1
				 * No need to normalize */
				salp12 = line.calp0 * line.salp0 * (
					csig12 <= 0 ?
					line.csig1 * (1 - csig12) + ssig12 * line.ssig1 :
						ssig12 * (line.csig1 * ssig12 / (1 + csig12) + line.ssig1)
				)
				calp12 = sq(line.salp0) + sq(line.calp0) * line.csig1 * csig2
			}
			S12 = line.c2 * atan2(salp12, calp12) + line.A4 * (B42 - line.B41)
		}

		return GeneralDirectGeodesicResult(
			//			if ((outmask & GEOD_LATITUDE) && plat2)
			latitude: lat2,
			//			if ((outmask & GEOD_LONGITUDE) && plon2)
			longitude: lon2,
			//			if ((outmask & GEOD_AZIMUTH) && pazi2)
			azimuth: azi2,
			//		if ((outmask & GEOD_DISTANCE) && ps12)
			distance: s12,
			//		if ((outmask & GEOD_REDUCEDLENGTH) && pm12)
			m12: m12,
			//		if (outmask & GEOD_GEODESICSCALE) {
			M12: M12,
			M21: M21,
			//		if ((outmask & GEOD_AREA) && pS12)
			areaUnder: S12,
			arcLength: flags.contains(.arcMode) ? s12_a12 : sig12 / degree
		)
	}

	func polygonArea(points: [Point]) -> (area: Double, perimeter: Double) {
		let polygon = Polygon(isPolyline: false, points: points, geodesic: self)
		return polygon.compute(geod: self, reverse: false, sign: true)
	}

	// TODO: add in all conditional paths, to reduce unncessary computation.
	private func lengths( _ eps: Double, _ sig12: Double,
		_ ssig1: Double, _ csig1: Double, _ dn1: Double,
		_ ssig2: Double, _ csig2: Double, _ dn2: Double,
		_ cbet1: Double, _ cbet2: Double,
		_ Ca: inout [Double]
	) -> (s12b: Double, m12b: Double, m0: Double, M12: Double, M21: Double) {

		var m0 = 0.0, J12 = 0.0, A1 = 0.0, A2 = 0.0
		var Cb = [Double](repeating: 0, count: nC)

		// TODO: what about redlp?
		A1 = a1m1f(eps)
		c1f(eps, &Ca)
		A2 = a2m1f(eps)
		c2f(eps, &Cb)
		m0 = A1 - A2
		A2 = 1 + A2
		A1 = 1 + A1

		let B1 = (
			sinCosSeries(true, ssig2, csig2, Ca, nC1) -
			sinCosSeries(true, ssig1, csig1, Ca, nC1)
		)
		let s12b = A1 * (sig12 + B1)

		let B2 = sinCosSeries(true, ssig2, csig2, Cb, nC2)
		- sinCosSeries(true, ssig1, csig1, Cb, nC2)
		J12 = m0 * sig12 + (A1 * B1 - A2 * B2)

		// TODO: what about redlp J12 adjustment?

		let m12b = dn2 * (csig1 * ssig2) - dn1 * (ssig1 * csig2) - csig1 * csig2 * J12

		let csig12 = csig1 * csig2 + ssig1 * ssig2
		let t = ep2 * (cbet1 - cbet2) * (cbet1 + cbet2) / (dn1 + dn2)
		let M12 = csig12 + (t * ssig2 - csig2 * J12) * ssig1 / dn1
		let M21 = csig12 - (t * ssig1 - csig1 * J12) * ssig2 / dn2

		return (s12b, m12b, m0, M12, M21)
	}

	private func astroid(_ x: Double, _ y: Double) -> Double {
		let p = sq(x), q = sq(y)
		let r = (p + q - 1) / 6

		guard !(q == 0 && r <= 0) else { return 0 }

		let S = p * q / 4
		let r2 = sq(r)
		let r3 = r * r2
		let disc = S * (S + 2 * r3)
		var u = r
		if disc >= 0 {
			var T3 = S + r3
			T3 += T3 < 0 ? -sqrt(disc) : sqrt(disc)
			let T = cbrt(T3)
			u += T + (T != 0 ? r2 / T : 0)
		} else {
			let ang = atan2(sqrt(-disc), -(S + r3))
			u += 2 * r * cos(ang / 3)
		}
		let v = sqrt(sq(u) + q)
		let uv = u < 0 ? q / (v - u) : u + v
		let w = (uv - q) / (2 * v)
		return uv / (sqrt(uv + sq(w)) + w)
	}

	private func inverseStart(
		_ sbet1: Double, _ cbet1: Double, _ dn1: Double,
		_ sbet2: Double, _ cbet2: Double, _ dn2: Double,
		_ lam12: Double, _ slam12: Double, _ clam12: Double,
		_ Ca: inout [Double]
	) -> (sig12: Double, salp1: Double, calp1: Double,
		  salp2: Double, calp2: Double, dnm: Double) {

		var salp1 = 0.0, calp1 = 0.0, salp2 = 0.0, calp2 = 0.0, dnm = 0.0

		let sbet12  = sbet2 * cbet1 - cbet2 * sbet1
		let cbet12  = cbet2 * cbet1 + sbet2 * sbet1
		let sbet12a = sbet2 * cbet1 + cbet2 * sbet1

		let shortline = cbet12 >= 0 && sbet12 < 0.5 && cbet2 * lam12 < 0.5

		var somg12: Double, comg12: Double
		if shortline {
			var sbetm2 = sq(sbet1 + sbet2)
			sbetm2 /= sbetm2 + sq(cbet1 + cbet2)
			dnm = sqrt(1 + ep2 * sbetm2)
			let omg12 = lam12 / (f1 * dnm)
			somg12 = sin(omg12)
			comg12 = cos(omg12)
		} else {
			somg12 = slam12
			comg12 = clam12
		}

		salp1 = cbet2 * somg12
		calp1 = comg12 >= 0 ?
			sbet12  + cbet2 * sbet1 * sq(somg12) / (1 + comg12) :
			sbet12a - cbet2 * sbet1 * sq(somg12) / (1 - comg12)

		let ssig12 = hypot(salp1, calp1)
		let csig12 = sbet1 * sbet2 + cbet1 * cbet2 * comg12

		if shortline && ssig12 < etol2 {
			salp2 = cbet1 * somg12
			calp2 = (
				sbet12 - cbet1 * sbet2 * (
					comg12 >= 0 ? sq(somg12) / (1 + comg12) : 1 - comg12
				)
			)
			norm(&salp2, &calp2)
			let sig12 = atan2(ssig12, csig12)
			return (sig12, salp1, calp1, salp2, calp2, dnm)
		} else if abs(n) > 0.1 || csig12 >= 0 || ssig12 >= 6 * abs(n) * .pi * sq(cbet1) {
			// Nothing to do, zeroth-order approximation is OK
		} else {
			let lam12x = atan2(-slam12, -clam12)
			var x = 0.0, y = 0.0, lamscale = 0.0, betscale = 0.0
			if flattening >= 0 {
				let k2   = sq(sbet1) * ep2
				let eps  = k2 / (2 * (1 + sqrt(1 + k2)) + k2)
				lamscale = flattening * cbet1 * a3f(eps) * .pi
				betscale = lamscale * cbet1
				x = lam12x / lamscale
				y = sbet12a / betscale
			} else {
				let cbet12a = cbet2 * cbet1 - sbet2 * sbet1
				let bet12a  = atan2(sbet12a, cbet12a)
				let (_, m12b, m0, _, _) = lengths(
					n, .pi + bet12a,
					sbet1, -cbet1, dn1, sbet2, cbet2, dn2,
					cbet1, cbet2, &Ca)
				x = -1 + m12b / (cbet1 * cbet2 * m0 * .pi)
				betscale = x < -0.01 ? sbet12a / x : -flattening * sq(cbet1) * .pi
				lamscale = betscale / cbet1
				y = lam12x / lamscale
			}

			if y > -tol1 && x > -1 - xthresh {
				if flattening >= 0 {
					salp1 = min(1.0, -x)
					calp1 = -sqrt(1 - sq(salp1))
				} else {
					calp1 = max(x > -tol1 ? 0.0 : -1.0, x)
					salp1 = sqrt(1 - sq(calp1))
				}
			} else {
				let k = astroid(x, y)
				let omg12a = lamscale * (flattening >= 0 ? -x * k / (1 + k) : -y * (1 + k) / k)
				somg12 = sin(omg12a)
				comg12 = -cos(omg12a)
				salp1 = cbet2 * somg12
				calp1 = sbet12a - cbet2 * sbet1 * sq(somg12) / (1 - comg12)
			}
		}

		if salp1 > 0 {
			norm(&salp1, &calp1)
		} else {
			salp1 = 1
			calp1 = 0
		}

		return (-1, salp1, calp1, salp2, calp2, dnm)
	}

	// TODO: verify what this function is doing
	private func lambda12(
		_ sbet1: Double, _ cbet1: Double, _ dn1: Double,
		_ sbet2: Double, _ cbet2: Double, _ dn2: Double,
		_ salp1: Double, _ calp1In: Double,
		_ slam120: Double, _ clam120: Double,
		_ diffp: Bool,
		_ Ca: inout [Double]
	) -> (lam12: Double, salp2: Double, calp2: Double,
		  sig12: Double, ssig1: Double, csig1: Double,
		  ssig2: Double, csig2: Double, eps: Double,
		  domg12: Double, dlam12: Double) {

		var calp1 = calp1In
		if sbet1 == 0 && calp1 == 0 { calp1 = -tiny }

		let salp0 = salp1 * cbet1
		let calp0 = hypot(calp1, salp1 * sbet1)

		var ssig1 = sbet1, somg1 = salp0 * sbet1
		var csig1 = calp1 * cbet1, comg1 = csig1
		norm(&ssig1, &csig1)

		let salp2 = cbet2 != cbet1 ? salp0 / cbet2 : salp1
		let calp2: Double
		if cbet2 != cbet1 || abs(sbet2) != -sbet1 {
			calp2 = sqrt(sq(calp1 * cbet1) +
						 (cbet1 < -sbet1
						  ? (cbet2 - cbet1) * (cbet1 + cbet2)
						  : (sbet1 - sbet2) * (sbet1 + sbet2))) / cbet2
		} else {
			calp2 = abs(calp1)
		}

		var ssig2 = sbet2, somg2 = salp0 * sbet2
		var csig2 = calp2 * cbet2, comg2 = csig2
		norm(&ssig2, &csig2)

		let sig12 = atan2(max(0.0, csig1 * ssig2 - ssig1 * csig2) + 0,
						  csig1 * csig2 + ssig1 * ssig2)

		let somg12 = max(0.0, comg1 * somg2 - somg1 * comg2) + 0
		let comg12 = comg1 * comg2 + somg1 * somg2
		let eta = atan2(somg12 * clam120 - comg12 * slam120,
						comg12 * clam120 + somg12 * slam120)

		let k2 = sq(calp0) * ep2
		let eps = k2 / (2 * (1 + sqrt(1 + k2)) + k2)
		c3f(eps, &Ca)
		let B312 = sinCosSeries(true, ssig2, csig2, Ca, nC3 - 1)
		- sinCosSeries(true, ssig1, csig1, Ca, nC3 - 1)
		let domg12 = -flattening * a3f(eps) * salp0 * (sig12 + B312)
		let lam12 = eta + domg12

		var dlam12 = 0.0
		if diffp {
			if calp2 == 0 {
				dlam12 = -2 * f1 * dn1 / sbet1
			} else {
				let (_, m12bVal, _, _, _) = lengths(
					eps, sig12,
					ssig1, csig1, dn1,
					ssig2, csig2, dn2,
					0, 0, &Ca)   // cbet1/cbet2 not needed for m12b
				dlam12 = m12bVal * f1 / (calp2 * cbet2)
			}
		}

		return (lam12, salp2, calp2, sig12, ssig1, csig1, ssig2, csig2, eps, domg12, dlam12)
	}

	private func geninverseInt(
		_ lat1: Double,
		_ lon1: Double,
		_ lat2: Double,
		_ lon2: Double,
		capabilities: Set<Capability> = Set(Capability.allCases)
	) -> (a12: Double, s12: Double, salp1: Double, calp1: Double,
		  salp2: Double, calp2: Double, m12: Double, M12: Double, M21: Double, S12: Double) {

		guard !lat1.isNaN && !lon1.isNaN && !lat2.isNaN && !lon2.isNaN else {
			return (
				a12: .nan, s12: .nan, salp1: .nan, calp1: .nan, salp2: .nan,
				calp2: .nan, m12: .nan, M12: .nan, M21: .nan, S12: .nan
			)
		}
		var s12 = 0.0, m12 = 0.0, M12 = 0.0, M21 = 0.0, S12 = 0.0

		/* Compute longitude difference (AngDiff does this carefully).  Result is
		 * in [-180, 180] but -180 is only for west-going geodesics.  180 is for
		 * east-going and meridional geodesics. */
		var (lon12, lon12s) = angDiff(lon1, lon2)

		// Make longitude difference positive.
		var lonsign = lon12 < 0 ? -1.0 : 1.0
		lon12 *= lonsign
		lon12s *= lonsign
		let lam12 = lon12 * degree

		// Calculate sincos of lon12 + error (this applies AngRound internally).
		let (slam12, clam12) = sincosde(lon12, lon12s)

		// the supplementary longitude difference
		lon12s = (hd - lon12) - lon12s

		
		// If really close to the equator, treat as on equator.
		var lat1 = angRound(latFix(lat1))
		var lat2 = angRound(latFix(lat2))

		/* Swap points so that point with higher (abs) latitude is point 1
		 * If one latitude is a nan, then it becomes lat1. */
		let swapp: Double = (abs(lat1) < abs(lat2) || lat2.isNaN) ? -1 : 1
		if swapp < 0 {
			lonsign *= -1.0
			swap(&lat1, &lat2)
		}

		// Make lat1 <= -0
		let latsign: Double = lat1 < 0 || (lat1 == 0 && lat1.sign == .minus) ? 1 : -1
		lat1 *= latsign
		lat2 *= latsign

		/* Now we have
		 *
		 *     0 <= lon12 <= 180
		 *     -90 <= lat1 <= -0
		 *     lat1 <= lat2 <= -lat1
		 *
		 * longsign, swapp, latsign register the transformation to bring the
		 * coordinates to this canonical form.  In all cases, 1 means no change was
		 * made.  We make these transformations so that there are few cases to
		 * check, e.g., on verifying quadrants in atan2.  In addition, this
		 * enforces some symmetries in the results returned. */
		var (sbet1, cbet1) = sincosd(lat1)
		sbet1 *= f1

		// Ensure cbet1 = +epsilon at poles
		norm(&sbet1, &cbet1)
		cbet1 = max(tiny, cbet1)

		var (sbet2, cbet2) = sincosd(lat2)
		sbet2 *= f1

		// Ensure cbet2 = +epsilon at poles
		norm(&sbet2, &cbet2)
		cbet2 = max(tiny, cbet2)

		/* If cbet1 < -sbet1, then cbet2 - cbet1 is a sensitive measure of the
		 * |bet1| - |bet2|.  Alternatively (cbet1 >= -sbet1), abs(sbet2) + sbet1 is
		 * a better measure.  This logic is used in assigning calp2 in Lambda12.
		 * Sometimes these quantities vanish and in that case we force bet2 = +/-
		 * bet1 exactly.  An example where is is necessary is the inverse problem
		 * 48.522876735459 0 -48.52287673545898293 179.599720456223079643
		 * which failed with Visual Studio 10 (Release and Debug) */
		if cbet1 < -sbet1 {
			if cbet2 == cbet1 {
				sbet2 = copysign(sbet1, sbet2)
			}
		} else {
			if abs(sbet2) == -sbet1 {
				cbet2 = cbet1
			}
		}

		let dn1 = sqrt(1 + ep2 * sq(sbet1))
		let dn2 = sqrt(1 + ep2 * sq(sbet2))

		var Ca = [Double](repeating: 0, count: nC)
		var a12 = 0.0
		var sig12 = 0.0
		var calp1 = 0.0, salp1 = 0.0, calp2 = 0.0, salp2 = 0.0
		var s12x = 0.0, m12x = 0.0
		var omg12 = 0.0, somg12 = 2.0, comg12 = 0.0

		var meridian = lat1 == -qd || slam12 == 0

		if meridian {
			/* Endpoints are on a single full meridian, so the geodesic might lie on
			 * a meridian. */
			calp1 = clam12
			// Head to the target longitude
			salp1 = slam12

			calp2 = 1
			// At the target we're heading north
			salp2 = 0

			let ssig1 = sbet1, csig1 = calp1 * cbet1
			let ssig2 = sbet2, csig2 = calp2 * cbet2

			// tan(bet) = tan(sig) * cos(alp)
			sig12 = atan2(max(0.0, csig1 * ssig2 - ssig1 * csig2) + 0,
						  csig1 * csig2 + ssig1 * ssig2)

			// TODO: pass capabilities to avoid extra calcs
			let r = lengths(n, sig12,
							ssig1, csig1, dn1,
							ssig2, csig2, dn2,
							cbet1, cbet2, &Ca)
			s12x = r.s12b
			m12x = r.m12b

			if capabilities.contains(.geodesicScale) {
				M12 = r.M12
				M21 = r.M21
			}

			/* Add the check for sig12 since zero length geodesics might yield m12 <
			 * 0.  Test case was
			 *
			 *    echo 20.001 0 20.001 0 | GeodSolve -i
			 */
			if sig12 < tol2 || m12x >= 0 {
				// Need at least 2, to handle 90 0 90 180
				if sig12 < 3 * tiny || (sig12 < tol0 && (s12x < 0 || m12x < 0)) {
					sig12 = 0
					m12x = 0
					s12x = 0
				}
				m12x *= b
				s12x *= b
				a12 = sig12 / degree
			} else {
				// m12 < 0, i.e., prolate and too close to anti-podal
				meridian = false
			}
		}

		if !meridian && sbet1 == 0 && (flattening <= 0 || lon12s >= flattening * hd) {
			// equatorial geodesic
			calp1 = 0
			calp2 = 0
			salp1 = 1
			salp2 = 1
			s12x = equatorialRadius * lam12
			sig12 = lam12 / f1
			omg12 = sig12
			m12x = b * sin(sig12)
			if capabilities.contains(.geodesicScale) {
				M12 = cos(sig12)
				M21 = M12
			}
			a12 = lon12 / f1
		} else if !meridian {
			/* Now point1 and point2 belong within a hemisphere bounded by a
			 * meridian and geodesic is neither meridional or equatorial. */

			/* Figure a starting point for Newton's method */
			let start = inverseStart(sbet1, cbet1, dn1, sbet2, cbet2, dn2,
									 lam12, slam12, clam12, &Ca)
			sig12 = start.sig12
			salp1 = start.salp1
			calp1 = start.calp1
			salp2 = start.salp2
			calp2 = start.calp2

			if sig12 >= 0 {
				// Short lines (InverseStart sets salp2, calp2, dnm)
				s12x = sig12 * b * start.dnm
				m12x = sq(start.dnm) * b * sin(sig12 / start.dnm)
				if capabilities.contains(.geodesicScale) {
					M12 = cos(sig12 / start.dnm)
					M21 = M12
				}
				a12 = sig12 / degree
				omg12 = lam12 / (f1 * start.dnm)
			} else {
				/* Newton's method.  This is a straightforward solution of f(alp1) =
				 * lambda12(alp1) - lam12 = 0 with one wrinkle.  f(alp) has exactly one
				 * root in the interval (0, pi) and its derivative is positive at the
				 * root.  Thus f(alp) is positive for alp > alp1 and negative for alp <
				 * alp1.  During the course of the iteration, a range (alp1a, alp1b) is
				 * maintained which brackets the root and with each evaluation of
				 * f(alp) the range is shrunk, if possible.  Newton's method is
				 * restarted whenever the derivative of f is negative (because the new
				 * value of alp1 is then further from the solution) or if the new
				 * estimate of alp1 lies outside (0,pi); in this case, the new starting
				 * guess is taken to be (alp1a + alp1b) / 2. */
				var ssig1 = 0.0, csig1 = 0.0, ssig2 = 0.0, csig2 = 0.0
				var eps = 0.0, domg12 = 0.0
				var numit = 0
				var salp1a = tiny, calp1a = 1.0
				var salp1b = tiny, calp1b = -1.0
				var tripn = false, tripb = false

				while true {
					/* the WGS84 test set: mean = 1.47, sd = 1.25, max = 16
					 * WGS84 and random input: mean = 2.85, sd = 0.60 */
					let r = lambda12(sbet1, cbet1, dn1, sbet2, cbet2, dn2,
									 salp1, calp1, slam12, clam12,
									 numit < maxit1, &Ca)
					let v = r.lam12
					let dv = r.dlam12
					salp2 = r.salp2
					calp2 = r.calp2
					sig12 = r.sig12
					ssig1 = r.ssig1
					csig1 = r.csig1
					ssig2 = r.ssig2
					csig2 = r.csig2
					eps = r.eps
					domg12 = r.domg12

					// Reversed test to allow escape with NaNs, maxit2 iterations is sufficient for an accurate result
					if tripb || !(abs(v) >= (tripn ? 8 : 1) * tol0) || numit == maxit2 {
						break
					}

					// Update bracketing values
					if v > 0 && (numit > maxit1 || calp1 / salp1 > calp1b / salp1b) {
						salp1b = salp1
						calp1b = calp1
					} else if v < 0 && (numit > maxit1 || calp1 / salp1 < calp1a / salp1a) {
						salp1a = salp1
						calp1a = calp1
					}

					if numit < maxit1 && dv > 0 {
						let dalp1 = -v / dv
						if abs(dalp1) < .pi {
							let sdalp1 = sin(dalp1)
							let cdalp1 = cos(dalp1)
							let nsalp1 = salp1 * cdalp1 + calp1 * sdalp1

							if nsalp1 > 0 {
								calp1 = calp1 * cdalp1 - salp1 * sdalp1
								salp1 = nsalp1
								norm(&salp1, &calp1)
								tripn = abs(v) <= 16 * tol0
								numit += 1
								continue
							}
						}
					}
					/* Either dv was not positive or updated value was outside legal
					 * range.  Use the midpoint of the bracket as the next estimate.
					 * This mechanism is not needed for the WGS84 ellipsoid, but it does
					 * catch problems with more eccentric ellipsoids.  Its efficacy is
					 * such for the WGS84 test set with the starting guess set to alp1 =
					 * 90deg:
					 * the WGS84 test set: mean = 5.21, sd = 3.93, max = 24
					 * WGS84 and random input: mean = 4.74, sd = 0.99 */
					salp1 = (salp1a + salp1b) / 2
					calp1 = (calp1a + calp1b) / 2
					norm(&salp1, &calp1)
					tripn = false
					tripb = (
						abs(salp1a - salp1) + (calp1a - calp1) < tolb ||
						abs(salp1 - salp1b) + (calp1 - calp1b) < tolb
					)
					numit += 1
				}

				// TODO: capabilities
				let r2 = lengths(eps, sig12,
								 ssig1, csig1, dn1,
								 ssig2, csig2, dn2,
								 cbet1, cbet2, &Ca)
				s12x = r2.s12b * b
				m12x = r2.m12b * b

				if capabilities.contains(.geodesicScale) {
					M12 = r2.M12
					M21 = r2.M21
				}
				a12 = sig12 / degree

				if (capabilities.contains(.area)) {
					let sdomg12 = sin(domg12)
					let cdomg12 = cos(domg12)
					somg12 = slam12 * cdomg12 - clam12 * sdomg12
					comg12 = clam12 * cdomg12 + slam12 * sdomg12
				}
			}
		}

		if (capabilities.contains(.distance)) {
			s12 = 0 + s12x
		}
		
		if (capabilities.contains(.reducedLength)) {
			m12 = 0 + m12x
		}

		// Area calculation
		if (capabilities.contains(.area)) {
			// From Lambda12: sin(alp1) * cos(bet1) = sin(alp0)
			let salp0 = salp1 * cbet1
			let calp0 = hypot(calp1, salp1 * sbet1) // calp0 > 0

			if calp0 != 0 && salp0 != 0 {
				// From Lambda12: tan(bet) = tan(sig) * cos(alp)
				// TODO: why are these appended with L?
				var ssig1L = sbet1
				var csig1L = calp1 * cbet1
				var ssig2L = sbet2
				var csig2L = calp2 * cbet2
				let k2L = sq(calp0) * ep2
				let epsL = k2L / (2 * (1 + sqrt(1 + k2L)) + k2L)
				// Multiplier = a^2 * e^2 * cos(alpha0) * sin(alpha0).
				let A4 = sq(equatorialRadius) * calp0 * salp0 * e2
				norm(&ssig1L, &csig1L)
				norm(&ssig2L, &csig2L)
				c4f(epsL, &Ca)
				let B41 = sinCosSeries(false, ssig1L, csig1L, Ca, nC4)
				let B42 = sinCosSeries(false, ssig2L, csig2L, Ca, nC4)
				S12 = A4 * (B42 - B41)
			} else {
				// Avoid problems with indeterminate sig1, sig2 on equator
				S12 = 0
			}

			if !meridian && somg12 == 2 {
				somg12 = sin(omg12)
				comg12 = cos(omg12)
			}

			let alp12: Double
			if (
				!meridian &&
				// omg12 < 3/4 * pi
				comg12 > -0.7071 && // Long difference not too big
				sbet2 - sbet1 < 1.75 // Lat difference not too big
			) {
				/* Use tan(Gamma/2) = tan(omg12/2)
				 * * (tan(bet1/2)+tan(bet2/2))/(1+tan(bet1/2)*tan(bet2/2))
				 * with tan(x/2) = sin(x)/(1+cos(x)) */
				let domg12v = 1 + comg12
				let dbet1 = 1 + cbet1
				let dbet2 = 1 + cbet2
				alp12 = 2 * atan2(somg12 * (sbet1 * dbet2 + sbet2 * dbet1),
								  domg12v * (sbet1 * sbet2 + dbet1 * dbet2))
			} else {
				// alp12 = alp2 - alp1, used in atan2 so no need to normalize
				var salp12 = salp2 * calp1 - calp2 * salp1
				var calp12 = calp2 * calp1 + salp2 * salp1
				/* The right thing appears to happen if alp1 = +/-180 and alp2 = 0, viz
				 * salp12 = -0 and alp12 = -180.  However this depends on the sign
				 * being attached to 0 correctly.  The following ensures the correct
				 * behavior. */
				if salp12 == 0 && calp12 < 0 {
					salp12 = tiny * calp1
					calp12 = -1
				}
				alp12 = atan2(salp12, calp12)
			}
			S12 += c2 * alp12
			S12 *= swapp * lonsign * latsign
			S12 += 0
		}

		var salp1Out = salp1
		var calp1Out = calp1
		var salp2Out = salp2
		var calp2Out = calp2
		/* Convert calp, salp to azimuth accounting for lonsign, swapp, latsign. */
		if swapp < 0 {
			swap(&salp1Out, &salp2Out)
			swap(&calp1Out, &calp2Out)
			swap(&M12, &M21)
		}
		salp1Out *= swapp * lonsign
		calp1Out *= swapp * latsign
		salp2Out *= swapp * lonsign
		calp2Out *= swapp * latsign

		return (a12, s12, salp1Out, calp1Out, salp2Out, calp2Out, m12, M12, M21, S12)
	}
}

extension Geodesic {
	public struct GeneralInverseGeodesicResult {
		// Distance reported in meters. (s12 in the source material)
		public let distance: Double

		// Starting azimuth reported in degrees
		public let azimuth1: Double

		// Ending (forward) azimuth reported in degrees
		public let azimuth2: Double

		// Reduced length of geodesic reported in meters.
		public let m12: Double

		// Geodesic scale of point 2 relative to point 1 without dimension
		public let M12: Double

		// Geodesic scale of point 1 relative to point 2 without dimension
		public let M21: Double

		// The area under the geodesic, reported in meters^2 (S12 in the source material)
		public let areaUnder: Double

		// Arc length reported in degrees (a12 in the source material)
		public let arcLength: Double
	}

	public func generalInverse(
		latitude1: Double,
		longitude1: Double,
		latitude2: Double,
		longitude2: Double,
		capabilities: Set<Capability> = Set(Capability.allCases)
	) -> GeneralInverseGeodesicResult {
		let r = geninverseInt(latitude1, longitude1, latitude2, longitude2, capabilities: capabilities)
		return GeneralInverseGeodesicResult(
			distance: r.s12,
			azimuth1: capabilities.contains(.azimuth) ? atan2d(r.salp1, r.calp1) : .nan,
			azimuth2: capabilities.contains(.azimuth) ? atan2d(r.salp2, r.calp2) : .nan,
			m12: r.m12,
			M12: r.M12,
			M21: r.M21,
			areaUnder: r.S12,
			arcLength: r.a12
		)
	}

	public struct InverseGeodesicResult {
		// Distance reported in meters.
		public let distance: Double

		// Starting azimuth reported in degrees
		public let azimuth1: Double

		// Ending (forward) azimuth reported in degrees
		public let azimuth2: Double

		public init(_ generalResult: GeneralInverseGeodesicResult) {
			distance = generalResult.distance
			azimuth1 = generalResult.azimuth1
			azimuth2 = generalResult.azimuth2
		}
	}

	public func inverse(
		latitude1: Double,
		longitude1: Double,
		latitude2: Double,
		longitude2: Double,
		capabilities: Set<Capability> = [.azimuth, .distance]
	) -> InverseGeodesicResult {
		return InverseGeodesicResult(
			generalInverse(
				latitude1: latitude1,
				longitude1: longitude1,
				latitude2: latitude2,
				longitude2: longitude2,
				capabilities: capabilities
			)
		)
	}

	public struct GeneralDirectGeodesicResult {
		// Reported in degrees
		public let latitude: Double

		// Reported in degrees
		public let longitude: Double

		// The ending (forward) azimuth at the destination.
		public let azimuth: Double

		// Distance reported in meters (s12 in the source material).
		public let distance: Double

		// Reduced length of the geodesic reported in meters.
		public let m12: Double

		// Geodesic scale of point 2 relative to point 1 without dimension.
		public let M12: Double

		// Geodesic scale of point 1 relative to point 2 without dimension.
		public let M21: Double

		// Area under the geodesic reported in meters^2 (S12 in the source material).
		public let areaUnder: Double

		// Arc Length between point 1 and 2, reported in degrees (a12 in the source material).
		public let arcLength: Double
	}

	public func generalDirect(
		latitude: Double,
		longitude: Double,
		azimuth: Double,
		distance: Double,
		flags: Set<Flag>? = Set(),
		capabilities: Set<Capability>? = ALL_CAPS
	) -> GeneralDirectGeodesicResult {
		var caps = capabilities ?? []
		if let flags = flags, !flags.contains(.arcMode) {
			caps.insert(.distanceIn)
		}
		let line = Line(
			geodesic: self,
			latitude: latitude,
			longitude: longitude,
			azimuth: azimuth,
			capabilities: caps
		)
		return genposition(
			line: line,
			s12_a12: distance,
			flags: flags ?? [],
		)
	}

	public struct DirectGeodesicResult {
		// Reported in degrees
		public let latitude: Double

		// Reported in degrees
		public let longitude: Double

		// The ending (forward) azimuth at the destination.
		public let azimuth: Double

		public init(_ generalResult: GeneralDirectGeodesicResult) {
			latitude = generalResult.latitude
			longitude = generalResult.longitude
			azimuth = generalResult.azimuth
		}
	}

	public func direct(
		latitude: Double,
		longitude: Double,
		azimuth: Double,
		distance: Double,
		flags: Set<Flag>? = nil
	) -> DirectGeodesicResult {
		DirectGeodesicResult(
			generalDirect(
				latitude: latitude,
				longitude: longitude,
				azimuth: azimuth,
				distance: distance,
				flags: flags,
				capabilities: [.latitude, .longitude, .azimuth, .distanceIn]
			)
		)
	}
}

struct Line {
	let latitude: Double // lat1
	let longitude: Double // lon1
	let azimuth: Double // azi1
	let equatorialRadius: Double // a
	let flattening: Double // f
	let salp1: Double // sineAzimuth
	let calp1: Double // cosineAzimuth
	let arcLength: Double // a13
	let distance: Double // s13

	let b: Double
	let c2: Double
	let f1: Double
	let salp0: Double
	let calp0: Double
	let k2: Double
	let ssig1: Double
	let csig1: Double
	let dn1: Double
	var stau1: Double = 0
	var ctau1: Double = 0
	var somg1: Double = 0
	var comg1: Double = 0
	var A1m1: Double = 0
	var A2m1: Double = 0
	var A3c: Double = 0
	var B11: Double = 0
	var B21: Double = 0
	var B31: Double = 0
	var A4: Double = 0
	var B41: Double = 0
	var C1a: [Double] = []
	var C1pa: [Double] = []
	var C2a: [Double] = []
	var C3a: [Double] = []
	var C4a: [Double] = []

	let capabilities: Set<Capability>

	init(
		geodesic: Geodesic,
		latitude: Double,
		longitude: Double,
		azimuth: Double,
		// If no capabilities are supplied, assume the standard direct calculation.
		capabilities: Set<Capability> = [.distanceIn, .longitude, .latitude, .azimuth]
	) {
		self.azimuth = angNormalize(azimuth)

		let sincos = sincosd(angRound(self.azimuth))
		self.salp1 = sincos.0
		self.calp1 = sincos.1

		self.equatorialRadius = geodesic.equatorialRadius
		self.flattening = geodesic.flattening
		self.b = geodesic.b
		self.c2 = geodesic.c2
		self.f1 = geodesic.f1

		self.capabilities = capabilities.union(Set<Capability>([.latitude, .azimuth]))

		self.latitude = latitude
		self.longitude = longitude

		var sbet1: Double
		var cbet1: Double
		(sbet1, cbet1) = sincosd(angRound(latitude))
		sbet1 *= self.f1
		norm(&sbet1, &cbet1)
		cbet1 = max(tiny, cbet1)
		self.dn1 = sqrt(1 + geodesic.ep2 * sq(sbet1))
		self.salp0 = self.salp1 * cbet1
		self.calp0 = hypot(self.calp1, self.salp1 * sbet1)
		var ssig1 = sbet1
		self.somg1 = self.salp0 * sbet1
		var csig1 = (sbet1 != 0 || self.calp1 != 0) ? cbet1 * self.calp1 : 1
		self.comg1 = csig1
		norm(&ssig1, &csig1)
		self.ssig1 = ssig1
		self.csig1 = csig1
		self.k2 = sq(self.calp0) * geodesic.ep2
		let eps = self.k2 / (2 * (1 + sqrt(1 + self.k2)) + self.k2)

		if (self.capabilities.intersection(CAP_C1).count > 0) {
			self.A1m1 = a1m1f(eps)
			var c1a = [Double](repeating: 0, count: nC)
			c1f(eps, &c1a)
			self.C1a = c1a
			self.B11 = sinCosSeries(true, self.ssig1, self.csig1, self.C1a, nC1)
			let s = sin(self.B11)
			let c = cos(self.B11)
			self.stau1 = self.ssig1 * c + self.csig1 * s
			self.ctau1 = self.csig1 * c - self.ssig1 * s
		}

		if (self.capabilities.intersection(CAP_C1P).count > 0) {
			var c1pa = [Double](repeating: 0, count: nC)
			c1pf(eps, &c1pa)
			self.C1pa = c1pa
		}

		if (self.capabilities.intersection(CAP_C2).count > 0) {
			self.A2m1 = a2m1f(eps)
			var c2a = [Double](repeating: 0, count: nC)
			c2f(eps, &c2a)
			self.C2a = c2a
			self.B21 = sinCosSeries(true, self.ssig1, self.csig1, self.C2a, nC2)
		}

		if (self.capabilities.intersection(CAP_C3).count > 0) {
			var c3a = [Double](repeating: 0, count: nC3)
			geodesic.c3f(eps, &c3a)
			self.C3a = c3a
			self.A3c = -self.flattening * self.salp0 * geodesic.a3f(eps)
			self.B31 = sinCosSeries(true, self.ssig1, self.csig1, self.C3a, nC3-1)
		}

		if (self.capabilities.intersection(CAP_C4).count > 0) {
			var c4a = [Double](repeating: 0, count: nC4)
			geodesic.c4f(eps, &c4a)
			self.C4a = c4a

			self.A4 = sq(self.equatorialRadius) * self.calp0 * self.salp0 * geodesic.e2
			self.B41 = sinCosSeries(false, self.ssig1, self.csig1, self.C4a, nC4)
		}

		self.arcLength = .nan
		self.distance = .nan
	}
}

/**
 * The struct for accumulating information about a geodesic polygon.  This is
 * used for computing the perimeter and area of a polygon.
 * */
internal class Polygon {
	var startPoint: Point?
	var currentPoint: Point?

	var area: [Double] = []
	var perimeter: [Double] = []

	let isPolyline: Bool
	var crossings: Int = 0

	var pointCount: UInt = 0

	init(isPolyline: Bool) {
		self.isPolyline = isPolyline
		self.area = [0, 0]
		self.perimeter = [0, 0]
	}

	init(isPolyline: Bool, points: [Point], geodesic: Geodesic) {
		self.isPolyline = isPolyline
		self.area = [0, 0]
		self.perimeter = [0, 0]

		for point in points {
			self.addPoint(geod: geodesic, point: point)
		}
	}

	func accAdd(_ value: Double, acc: inout [Double]) {
		// Add value to an accumulator

		let (z, u) = sum(value, acc[1])
		(acc[0], acc[1]) = sum(z, acc[0])

		if (acc[0] == 0) {
			acc[0] = u
		} else {
			acc[1] = acc[1] + u
		}
	}

	func accSum(_ value: Double, acc: [Double]) -> Double {
		// Return accumulator + y, but don't add to the accumulator.
		var t = acc
		accAdd(value, acc: &t)
		return t[0]
	}

	func accRem(_ value: Double, acc: inout [Double]) {
		acc[0] = remainder(acc[0], value)
		accAdd(0, acc: &acc)
	}

	func accNeg(_ acc: inout [Double]) {
		acc[0] = -acc[0]
		acc[1] = -acc[1]
	}

	func transit(_ lon1: Double, _ lon2: Double) -> Int {
		let (lon12, _) = angDiff(lon1, lon2)
		let lon1 = angNormalize(lon1)
		let lon2 = angNormalize(lon2)

		if lon12 > 0 && ((lon1 < 0 && lon2 >= 0) || (lon1 > 0 && lon2 == 0)) {
			return 1
		} else if lon12 < 0 && lon1 >= 0 && lon2 < 0 {
			return -1
		} else {
			return 0
		}
	}

	func transitDirect(_ lon1: Double, _ lon2: Double) -> Int {
		// Compute exactly the parity of int(floor(lon2 / 360)) - int(floor(lon1 / 360))
		let lon1rem = remainder(lon1, 2.0 * td)
		let lon2rem = remainder(lon2, 2.0 * td)
		return (
			(lon2rem >= 0 && lon2rem < td ? 0 : 1) -
			(lon1rem >= 0 && lon1rem < td ? 0 : 1)
		)
	}

	func areaReduceA(_ area0: Double, areaAcc: inout [Double], crossings: Int, reverse: Bool, sign: Bool) -> Double {
		accRem(area0, acc: &areaAcc)

		if crossings & 1 == 1 {
			accAdd(
				(areaAcc[0] < 0 ? 1 : -1) * area0 / 2,
				acc: &areaAcc
			)
		}

		// Area is computed clockwise. If !reverse, convert to counter-clockwise convention.
		if !reverse {
			accNeg(&areaAcc)
		}

		// If sign is acceptable, put area in [-area0/2, area0/2], else put area in [0, area0)
		if (sign) {
			if (areaAcc[0] > (area0 / 2)) {
				accAdd(-area0, acc: &areaAcc)
			} else if (areaAcc[0] <= -(area0 / 2)) {
				accAdd(area0, acc: &areaAcc)
			}
		} else {
			if (areaAcc[0] >= area0) {
				accAdd(-area0, acc: &areaAcc)
			} else if (areaAcc[0] < 0) {
				accAdd(+area0, acc: &areaAcc)
			}
		}

		return 0 + areaAcc[0]
	}

	func areaReduceB(_ area: Double, _ area0: Double, crossings: Int, reverse: Bool, sign: Bool) -> Double {
		var area = remainder(area, area0)
		if crossings & 1 == 1 {
			area += (area < 0 ? 1 : -1) * area0 / 2
		}
		if !reverse {
			area *= -1
		}
		if sign {
			if area > (area0 / 2) {
				area -= area0
			} else if area <= -(area0 / 2) {
				area += area0
			}
		} else {
			if area >= area0 {
				area -= area0
			} else if area < 0 {
				area += area0
			}
		}

		return 0 + area
	}

	func addPoint(geod: Geodesic, point: Point) {
		if let currentPoint = currentPoint {
			let inverse = geod.generalInverse(
				latitude1: currentPoint.latitude,
				longitude1: currentPoint.longitude,
				latitude2: point.latitude,
				longitude2: point.longitude,
				capabilities: [.distance, .area]
				// TODO: remove area if polyline?
			)

			accAdd(inverse.distance, acc: &perimeter)

			if !isPolyline {
				accAdd(inverse.areaUnder, acc: &area)

				crossings += transit(currentPoint.longitude, point.longitude)
			}

			self.currentPoint = point
		} else {
			startPoint = point
			currentPoint = point
		}

		pointCount += 1
	}

	func testPoint(geod: Geodesic, point: Point, reverse: Bool, sign: Bool) -> (area: Double, perimeter: Double) {
		guard let startPoint = startPoint, let currentPoint = currentPoint else {
			return (0, 0)
		}

		var perimeter = perimeter[0]
		var tempSum = isPolyline ? 0 : area[0]
		var crossings = self.crossings

		for i in 0..<(isPolyline ? 1 : 2) {
			let inverse = geod.generalInverse(
				latitude1: i == 0 ? currentPoint.latitude : point.latitude,
				longitude1: i == 0 ? currentPoint.longitude : point.longitude,
				latitude2: i != 0 ? startPoint.latitude: point.latitude,
				longitude2: i != 0 ? startPoint.longitude : point.longitude,
				// TODO: turn off area capability if polyline?
			)

			perimeter += inverse.distance

			if !isPolyline {
				tempSum += inverse.areaUnder
				crossings += transit(
					i == 0 ? currentPoint.longitude : point.longitude,
					i != 0 ? startPoint.longitude : point.longitude
				)
			}
		}

		if isPolyline {
			return (0, perimeter)
		}

		let area = areaReduceB(
			tempSum,
			4 * .pi * geod.c2,
			crossings: crossings,
			reverse: reverse,
			sign: sign
		)

		return (area, perimeter)
	}

	func addEdge(geod: Geodesic, azimuth: Double, distance: Double) {
		guard let currentPoint = currentPoint else {
			logger.warning("Attempted to add an edge to a polygon that does not yet have a starting point")
			return
		}
		let direct = geod.generalDirect(
			latitude: currentPoint.latitude,
			longitude: currentPoint.longitude,
			azimuth: azimuth,
			distance: distance,
			flags: [.longitudeUnroll],
			capabilities: [.distance, .distanceIn, .latitude, .longitude, .area]
		)

		accAdd(distance, acc: &self.perimeter)

		if !isPolyline {
			accAdd(direct.areaUnder, acc: &self.area)
			crossings += transitDirect(currentPoint.longitude, direct.longitude)
		}

		self.currentPoint = Point(latitude: direct.latitude, longitude: direct.longitude)
		self.pointCount += 1
	}

	func testEdge(geod: Geodesic, azimuth: Double, distance: Double, reverse: Bool, sign: Bool) -> (area: Double, perimeter: Double) {
		guard let startPoint = startPoint, let currentPoint = currentPoint else {
			return (.nan, .nan)
		}

		var perimeter = self.perimeter[0] + distance
		if isPolyline {
			return (0, perimeter)
		}

		var tempSum = area[0]
		var crossings = self.crossings

		let direct = geod.generalDirect(
			latitude: currentPoint.latitude,
			longitude: currentPoint.longitude,
			azimuth: azimuth,
			distance: distance,
			flags: [.longitudeUnroll],
			capabilities: Set(Capability.allCases)
			// TODO: turn off area capability if polyline?
		)
		tempSum += direct.areaUnder
		crossings += transitDirect(currentPoint.longitude, direct.longitude)

		let inverse = geod.generalInverse(
			latitude1: direct.latitude,
			longitude1: direct.longitude,
			latitude2: startPoint.latitude,
			longitude2: startPoint.longitude
		)

		perimeter += inverse.distance
		tempSum += inverse.areaUnder
		crossings += transit(direct.longitude, startPoint.longitude)

		let area = areaReduceB(
			tempSum,
			4 * .pi * geod.c2,
			crossings: crossings,
			reverse: reverse,
			sign: sign
		)

		return (area, perimeter)
	}

	func compute(geod: Geodesic, reverse: Bool, sign: Bool) -> (area: Double, perimeter: Double) {
		guard self.pointCount >= 2, let startPoint = startPoint, let currentPoint = currentPoint else {
			return (0, 0)
		}

		if isPolyline {
			return (0, perimeter[0])
		}

		let inverse = geod.generalInverse(
			latitude1: currentPoint.latitude,
			longitude1: currentPoint.longitude,
			latitude2: startPoint.latitude,
			longitude2: startPoint.longitude,
			capabilities: [.distance, .area]
		)

		let perimeter = accSum(inverse.distance, acc: perimeter)

		var t = self.area
		accAdd(inverse.areaUnder, acc: &t)

		let area = areaReduceA(
			4 * .pi * geod.c2,
			areaAcc: &t,
			crossings: self.crossings + transit(currentPoint.longitude, startPoint.longitude),
			reverse: reverse,
			sign: sign
		)

		return (area, perimeter)
	}
}

public struct Point {
	let latitude: Double
	let longitude: Double
}

// MARK: - Series helpers

/// sinCosSeries evaluates a trigonometric series using Clenshaw summation.
private func sinCosSeries(_ sinp: Bool, _ sinx: Double, _ cosx: Double,
						  _ c: [Double], _ n: Int) -> Double {
	guard c.count > 0 else {
		logger.error("sinCosSeries called with empty coefficient array")
		return 0
	}
	/* Evaluate
	 * y = sinp ? sum(c[i] * sin( 2*i    * x), i, 1, n) :
	 *            sum(c[i] * cos((2*i+1) * x), i, 0, n-1)
	 * using Clenshaw summation.  N.B. c[0] is unused for sin series
	 * Approx. operation count = (n + 5) multiplications and (2 * n + 2) additions
	 */

	var idx = n
	if sinp {
		idx += 1
	}

	let ar = 2 * (cosx - sinx) * (cosx + sinx)

	var sum1 = 0.0
	if (n & 1) != 0 {
		idx -= 1
		sum1 = c[idx]
	}
	var sum2 = 0.0

	var nn = n / 2
	while nn > 0 {
		nn -= 1
		idx -= 1
		sum2 = ar * sum1 - sum2 + c[idx]

		idx -= 1
		sum1 = ar * sum2 - sum1 + c[idx]
	}

	return sinp ? 2 * sinx * cosx * sum1 : cosx * (sum1 - sum2)
}

private func a1m1f(_ eps: Double) -> Double {
	let coeff: [Double] = [1, 4, 64, 0, 256]
	let m = nA1 / 2
	let t = polyval(m, coeff, 0, sq(eps)) / coeff[m + 1]
	return (t + eps) / (1 - eps)
}

private func c1f(_ eps: Double, _ c: inout [Double]) {
	let coeff: [Double] = [
		-1, 6, -16, 32,
		 -9, 64, -128, 2048,
		 9, -16, 768,
		 3, -5, 512,
		 -7, 1280,
		 -7, 2048,
	]
	let eps2 = sq(eps)
	var d = eps
	var o = 0
	for l in 1...nC1 {
		let m = (nC1 - l) / 2
		c[l] = d * polyval(m, coeff, o, eps2) / coeff[o + m + 1]
		o += m + 2
		d *= eps
	}
}

private func c1pf(_ eps: Double, _ c: inout [Double]) {
	let coeff: [Double] = [
		205, -432, 768, 1536,
		4005, -4736, 3840, 12288,
		-225, 116, 384,
		-7173, 2695, 7680,
		3467, 7680,
		38081, 61440,
	]
	let eps2 = sq(eps)
	var d = eps
	var o = 0
	for l in 1...nC1p {
		let m = (nC1p - l) / 2
		c[l] = d * polyval(m, coeff, o, eps2) / coeff[o + m + 1]
		o += m + 2
		d *= eps
	}
}

private func a2m1f(_ eps: Double) -> Double {
	let coeff: [Double] = [-11, -28, -192, 0, 256]
	let m = nA2 / 2
	let t = polyval(m, coeff, 0, sq(eps)) / coeff[m + 1]
	return (t - eps) / (1 + eps)
}

private func c2f(_ eps: Double, _ c: inout [Double]) {
	let coeff: [Double] = [
		1, 2, 16, 32,
		35, 64, 384, 2048,
		15, 80, 768,
		7, 35, 512,
		63, 1280,
		77, 2048,
	]
	let eps2 = sq(eps)
	var d = eps
	var o = 0
	for l in 1...nC2 {
		let m = (nC2 - l) / 2
		c[l] = d * polyval(m, coeff, o, eps2) / coeff[o + m + 1]
		o += m + 2
		d *= eps
	}
}
