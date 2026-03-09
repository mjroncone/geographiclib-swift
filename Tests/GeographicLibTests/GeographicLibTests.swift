import Testing

@testable import GeographicLib

struct TestGeodesic {
	let latitude1: Double
	let longitude1: Double
	let azimuth1: Double
	let latitude2: Double
	let longitude2: Double
	let azimuth2: Double

	// s12 in the source material
	let distance: Double

	// a12 in the source material
	let arcLength: Double

	let m12: Double
	let M12: Double
	let M21: Double

	// S12 in the source material
	let areaUnder: Double
}

let TEST_GEODESICS = [
	TestGeodesic(latitude1: 35.60777, longitude1: -139.44815, azimuth1: 111.098748429560326,
					   latitude2: -11.17491, longitude2: -69.95921, azimuth2: 129.289270889708762,
					   distance: 8935244.5604818305, arcLength: 80.50729714281974, m12: 6273170.2055303837,
					   M12: 0.16606318447386067, M21: 0.16479116945612937, areaUnder: 12841384694976.432),
	TestGeodesic(latitude1: 55.52454, longitude1: 106.05087, azimuth1: 22.020059880982801,
					   latitude2: 77.03196, longitude2: 197.18234, azimuth2: 109.112041110671519,
					   distance: 4105086.1713924406, arcLength: 36.892740690445894, m12: 3828869.3344387607,
					   M12: 0.80076349608092607, M21: 0.80101006984201008, areaUnder: 61674961290615.615),
	TestGeodesic(latitude1: -21.97856, longitude1: 142.59065, azimuth1: -32.44456876433189,
					   latitude2: 41.84138, longitude2: 98.56635, azimuth2: -41.84359951440466,
					   distance: 8394328.894657671, arcLength: 75.62930491011522, m12: 6161154.5773110616,
					   M12: 0.24816339233950381, M21: 0.24930251203627892, areaUnder: -6637997720646.717),
	TestGeodesic(latitude1: -66.99028, longitude1: 112.2363, azimuth1: 173.73491240878403,
					   latitude2: -12.70631, longitude2: 285.90344, azimuth2: 2.512956620913668,
					   distance: 11150344.2312080241, arcLength: 100.278634181155759, m12: 6289939.5670446687,
					   M12: -0.17199490274700385, M21: -0.17722569526345708, areaUnder: -121287239862139.744),
	TestGeodesic(latitude1: -17.42761, longitude1: 173.34268, azimuth1: -159.033557661192928,
					   latitude2: -15.84784, longitude2: 5.93557, azimuth2: -20.787484651536988,
					   distance: 16076603.1631180673, arcLength: 144.640108810286253, m12: 3732902.1583877189,
					   M12: -0.81273638700070476, M21: -0.81299800519154474, areaUnder: 97825992354058.708),
	TestGeodesic(latitude1: 32.84994, longitude1: 48.28919, azimuth1: 150.492927788121982,
					   latitude2: -56.28556, longitude2: 202.29132, azimuth2: 48.113449399816759,
					   distance: 16727068.9438164461, arcLength: 150.565799985466607, m12: 3147838.1910180939,
					   M12: -0.87334918086923126, M21: -0.86505036767110637, areaUnder: -72445258525585.010),
	TestGeodesic(latitude1: 6.96833, longitude1: 52.74123, azimuth1: 92.581585386317712,
					   latitude2: -7.39675, longitude2: 206.17291, azimuth2: 90.721692165923907,
					   distance: 17102477.2496958388, arcLength: 154.147366239113561, m12: 2772035.6169917581,
					   M12: -0.89991282520302447, M21: -0.89986892177110739, areaUnder: -1311796973197.995),
	TestGeodesic(latitude1: -50.56724, longitude1: -16.30485, azimuth1: -105.439679907590164,
					   latitude2: -33.56571, longitude2: -94.97412, azimuth2: -47.348547835650331,
					   distance: 6455670.5118668696, arcLength: 58.083719495371259, m12: 5409150.7979815838,
					   M12: 0.53053508035997263, M21: 0.52988722644436602, areaUnder: 41071447902810.047),
	TestGeodesic(latitude1: -58.93002, longitude1: -8.90775, azimuth1: 140.965397902500679,
					   latitude2: -8.91104, longitude2: 133.13503, azimuth2: 19.255429433416599,
					   distance: 11756066.0219864627, arcLength: 105.755691241406877, m12: 6151101.2270708536,
					   M12: -0.26548622269867183, M21: -0.27068483874510741, areaUnder: -86143460552774.735),
	TestGeodesic(latitude1: -68.82867, longitude1: -74.28391, azimuth1: 93.774347763114881,
					   latitude2: -50.63005, longitude2: -8.36685, azimuth2: 34.65564085411343,
					   distance: 3956936.926063544, arcLength: 35.572254987389284, m12: 3708890.9544062657,
					   M12: 0.81443963736383502, M21: 0.81420859815358342, areaUnder: -41845309450093.787),
	TestGeodesic(latitude1: -10.62672, longitude1: -32.0898, azimuth1: -86.426713286747751,
					   latitude2: 5.883, longitude2: -134.31681, azimuth2: -80.473780971034875,
					   distance: 11470869.3864563009, arcLength: 103.387395634504061, m12: 6184411.6622659713,
					   M12: -0.23138683500430237, M21: -0.23155097622286792, areaUnder: 4198803992123.548),
	TestGeodesic(latitude1: -21.76221, longitude1: 166.90563, azimuth1: 29.319421206936428,
					   latitude2: 48.72884, longitude2: 213.97627, azimuth2: 43.508671946410168,
					   distance: 9098627.3986554915, arcLength: 81.963476716121964, m12: 6299240.9166992283,
					   M12: 0.13965943368590333, M21: 0.14152969707656796, areaUnder: 10024709850277.476),
	TestGeodesic(latitude1: -19.79938, longitude1: -174.47484, azimuth1: 71.167275780171533,
					   latitude2: -11.99349, longitude2: -154.35109, azimuth2: 65.589099775199228,
					   distance: 2319004.8601169389, arcLength: 20.896611684802389, m12: 2267960.8703918325,
					   M12: 0.93427001867125849, M21: 0.93424887135032789, areaUnder: -3935477535005.785),
	TestGeodesic(latitude1: -11.95887, longitude1: -116.94513, azimuth1: 92.712619830452549,
					   latitude2: 4.57352, longitude2: 7.16501, azimuth2: 78.64960934409585,
					   distance: 13834722.5801401374, arcLength: 124.688684161089762, m12: 5228093.177931598,
					   M12: -0.56879356755666463, M21: -0.56918731952397221, areaUnder: -9919582785894.853),
	TestGeodesic(latitude1: -87.85331, longitude1: 85.66836, azimuth1: -65.120313040242748,
					   latitude2: 66.48646, longitude2: 16.09921, azimuth2: -4.888658719272296,
					   distance: 17286615.3147144645, arcLength: 155.58592449699137, m12: 2635887.4729110181,
					   M12: -0.90697975771398578, M21: -0.91095608883042767, areaUnder: 42667211366919.534),
	TestGeodesic(latitude1: 1.74708, longitude1: 128.32011, azimuth1: -101.584843631173858,
					   latitude2: -11.16617, longitude2: 11.87109, azimuth2: -86.325793296437476,
					   distance: 12942901.1241347408, arcLength: 116.650512484301857, m12: 5682744.8413270572,
					   M12: -0.44857868222697644, M21: -0.44824490340007729, areaUnder: 10763055294345.653),
	TestGeodesic(latitude1: -25.72959, longitude1: -144.90758, azimuth1: -153.647468693117198,
					   latitude2: -57.70581, longitude2: -269.17879, azimuth2: -48.343983158876487,
					   distance: 9413446.7452453107, arcLength: 84.664533838404295, m12: 6356176.6898881281,
					   M12: 0.09492245755254703, M21: 0.09737058264766572, areaUnder: 74515122850712.444),
	TestGeodesic(latitude1: -41.22777, longitude1: 122.32875, azimuth1: 14.285113402275739,
					   latitude2: -7.57291, longitude2: 130.37946, azimuth2: 10.805303085187369,
					   distance: 3812686.035106021, arcLength: 34.34330804743883, m12: 3588703.8812128856,
					   M12: 0.82605222593217889, M21: 0.82572158200920196, areaUnder: -2456961531057.857),
	TestGeodesic(latitude1: 11.01307, longitude1: 138.25278, azimuth1: 79.43682622782374,
					   latitude2: 6.62726, longitude2: 247.05981, azimuth2: 103.708090215522657,
					   distance: 11911190.819018408, arcLength: 107.341669954114577, m12: 6070904.722786735,
					   M12: -0.29767608923657404, M21: -0.29785143390252321, areaUnder: 17121631423099.696),
	TestGeodesic(latitude1: -29.47124, longitude1: 95.14681, azimuth1: -163.779130441688382,
					   latitude2: -27.46601, longitude2: -69.15955, azimuth2: -15.909335945554969,
					   distance: 13487015.8381145492, arcLength: 121.294026715742277, m12: 5481428.9945736388,
					   M12: -0.51527225545373252, M21: -0.51556587964721788, areaUnder: 104679964020340.318)
]

func isEqual(_ lhs: Double, _ rhs: Double, precision: Double = 0.000001) -> Bool {
	return abs(lhs - rhs) <= precision
}

@Suite("Geodesic Tests")
struct GeodesicTests {
	@Test("General Inverse Geodesic problem", arguments: TEST_GEODESICS)
	func testGeneralInverse(_ testCase: TestGeodesic) async throws {
		let geod = Geodesic.WGS84
		let result = geod.generalInverse(
			latitude1: testCase.latitude1,
			longitude1: testCase.longitude1,
			latitude2: testCase.latitude2,
			longitude2: testCase.longitude2
		)

		#expect(isEqual(result.azimuth1, testCase.azimuth1, precision: 1e-13))
		#expect(isEqual(result.azimuth2, testCase.azimuth2, precision: 1e-13))
		#expect(isEqual(result.distance, testCase.distance, precision: 1e-8))
		#expect(isEqual(result.arcLength, testCase.arcLength, precision: 1e-13))
		#expect(isEqual(result.m12, testCase.m12, precision: 1e-8))
		#expect(isEqual(result.M12, testCase.M12, precision: 1e-15))
		#expect(isEqual(result.M21, testCase.M21, precision: 1e-15))
		#expect(isEqual(result.areaUnder, testCase.areaUnder, precision: 0.1))
	}

	@Test("Reduced Inverse Geodesic problem", arguments: TEST_GEODESICS)
	func testInverse(_ testCase: TestGeodesic) async throws {
		let geod = Geodesic.WGS84
		let result = geod.inverse(
			latitude1: testCase.latitude1,
			longitude1: testCase.longitude1,
			latitude2: testCase.latitude2,
			longitude2: testCase.longitude2
		)

		#expect(isEqual(result.distance, testCase.distance, precision: 1e-8))
		#expect(isEqual(result.azimuth1, testCase.azimuth1, precision: 1e-13))
		#expect(isEqual(result.azimuth2, testCase.azimuth2, precision: 1e-13))
	}

	@Test("General Direct Geodesic problem", arguments: TEST_GEODESICS)
	func testGeneralDirect(_ testCase: TestGeodesic) async throws {
		let geod = Geodesic.WGS84
		let result = geod.generalDirect(
			latitude: testCase.latitude1,
			longitude: testCase.longitude1,
			azimuth: testCase.azimuth1,
			distance: testCase.distance,
			flags: [.longitudeUnroll]
		)

		#expect(isEqual(result.latitude, testCase.latitude2, precision: 1e-13))
		#expect(isEqual(result.longitude, testCase.longitude2, precision: 1e-13))
		#expect(isEqual(result.azimuth, testCase.azimuth2, precision: 1e-13))
		#expect(result.distance == testCase.distance)
		#expect(isEqual(result.arcLength, testCase.arcLength, precision: 1e-13))
		#expect(isEqual(result.m12, testCase.m12, precision: 1e-8))
		#expect(isEqual(result.M12, testCase.M12, precision: 1e-15))
		#expect(isEqual(result.M21, testCase.M21, precision: 1e-15))
		#expect(isEqual(result.areaUnder, testCase.areaUnder, precision: 0.1))
	}

	@Test("Reduced Direct Geodesic problem", arguments: TEST_GEODESICS)
	func testDirect(_ testCase: TestGeodesic) async throws {
		let geod = Geodesic.WGS84
		let result = geod.direct(
			latitude: testCase.latitude1,
			longitude: testCase.longitude1,
			azimuth: testCase.azimuth1,
			distance: testCase.distance,
			flags: [.longitudeUnroll]
		)

		#expect(isEqual(result.latitude, testCase.latitude2, precision: 1e-13))
		#expect(isEqual(result.longitude, testCase.longitude2, precision: 1e-13))
		#expect(isEqual(result.azimuth, testCase.azimuth2, precision: 1e-13))
	}


	@Test("Arc Direct mode", arguments: TEST_GEODESICS)
	func testarcdirect(_ testCase: TestGeodesic) {
		let flags: Set<Flag> = [.arcMode, .longitudeUnroll]
		let geod = Geodesic.WGS84
		let result = geod.generalDirect(
			latitude: testCase.latitude1,
			longitude: testCase.longitude1,
			azimuth: testCase.azimuth1,
			distance: testCase.arcLength,
			flags: flags
		)
		#expect(isEqual(result.latitude, testCase.latitude2, precision: 1e-13))
		#expect(isEqual(result.longitude, testCase.longitude2, precision: 1e-13))
		#expect(isEqual(result.azimuth, testCase.azimuth2, precision: 1e-13))
		#expect(isEqual(result.distance, testCase.distance, precision: 1e-8))
		#expect(result.arcLength == testCase.arcLength)
		#expect(isEqual(result.m12, testCase.m12, precision: 1e-8))
		#expect(isEqual(result.M12, testCase.M12, precision: 1e-15))
		#expect(isEqual(result.M21, testCase.M21, precision: 1e-15))
		#expect(isEqual(result.areaUnder, testCase.areaUnder, precision: 0.1))
	}

	@Test
	func testGeodSolve0() {
		let geod = Geodesic.WGS84
		let result = geod.inverse(latitude1: 40.6, longitude1: -73.8, latitude2: 49.01666667, longitude2: 2.55)

		#expect(isEqual(result.azimuth1, 53.47022, precision: 0.5e-5))
		#expect(isEqual(result.azimuth2, 111.59367, precision: 0.5e-5))
		#expect(isEqual(result.distance, 5853226, precision: 0.5))
	}

	@Test
	func testGeodSolve1() {
		let geod = Geodesic.WGS84
		let result = geod.direct(latitude: 40.63972222, longitude: -73.77888889, azimuth: 53.5, distance: 5850e3)
		#expect(isEqual(result.latitude, 49.01467, precision: 0.5e-5))
		#expect(isEqual(result.longitude, 2.56106, precision: 0.5e-5))
		#expect(isEqual(result.azimuth, 111.62947, precision: 0.5e-5))
	}

	@Test
	func testGeodSolve2() {
		/* Check fix for antipodal prolate bug found 2010-09-04 */
		let geod = Geodesic(equatorialRadius: 6.4e6, flattening: -1/150.0)
		var result = geod.inverse(latitude1: 0.07476, longitude1: 0, latitude2: -0.07476, longitude2: 180)
		#expect(isEqual(result.azimuth1, 90.00078, precision: 0.5e-5))
		#expect(isEqual(result.azimuth2, 90.00078, precision: 0.5e-5))
		#expect(isEqual(result.distance, 20106193, precision: 0.5))

		result = geod.inverse(latitude1: 0.1, longitude1: 0, latitude2: -0.1, longitude2: 180)
		#expect(isEqual(result.azimuth1, 90.00105, precision: 0.5e-5))
		#expect(isEqual(result.azimuth2, 90.00105, precision: 0.5e-5))
		#expect(isEqual(result.distance, 20106193, precision: 0.5))
	}

	@Test
	func testGeodSolve4() {
		/* Check fix for short line bug found 2010-05-21 */
		let geod = Geodesic.WGS84
		let result = geod.inverse(
			latitude1: 36.493349428792,
			longitude1: 0,
			latitude2: 36.49334942879201,
			longitude2: 0.00000080
		)
		#expect(isEqual(result.distance, 0.072, precision: 0.5e-3))
	}

	@Test
	func testGeodSolve5() {
		/* Check fix for point2=pole bug found 2010-05-03 */
		let geod = Geodesic.WGS84
		let result = geod.direct(latitude: 0.01777745589997, longitude: 30, azimuth: 0, distance: 10e6)

		#expect(isEqual(result.latitude, 90, precision: 0.5e-5))
		if (result.longitude < 0) {
			#expect(isEqual(result.longitude, -150, precision: 0.5e-5))
			#expect(isEqual(abs(result.azimuth), 180, precision: 0.5e-5))
		} else {
			// I'm getting longitude 210, which is impossible, because it should be capped at 180.
			// Since 30 is the difference between those two numbers, I'm assuming there's a clamp
			// that's not working as expected somewhere.
			#expect(isEqual(result.longitude, 30, precision: 0.5e-5))
			#expect(isEqual(result.azimuth, 0, precision: 0.5e-5))
		}
	}

	@Test
	func testGeodSolve6() {
		/* Check fix for volatile sbet12a bug found 2011-06-25 (gcc 4.4.4
		 * x86 -O3).  Found again on 2012-03-27 with tdm-mingw32 (g++ 4.6.1). */
		let geod = Geodesic.WGS84
		let result1 = geod.inverse(
			latitude1: 88.202499451857,
			longitude1: 0,
			latitude2: -88.202499451857,
			longitude2: 179.981022032992859592
		)
		#expect(isEqual(result1.distance, 20003898.214, precision: 0.5e-3))
		let result2 = geod.inverse(
			latitude1: 89.262080389218,
			longitude1: 0,
			latitude2: -89.262080389218,
			longitude2: 179.992207982775375662,
		)
		#expect(isEqual(result2.distance, 20003925.854, precision: 0.5e-3))
		let result3 = geod.inverse(
			latitude1: 89.333123580033,
			longitude1: 0,
			latitude2: -89.333123580032997687,
			longitude2: 179.99295812360148422,
		)
		#expect(isEqual(result3.distance, 20003926.881, precision: 0.5e-3))
	}

	@Test
	func testGeodSolve9() {
		/* Check fix for volatile x bug found 2011-06-25 (gcc 4.4.4 x86 -O3) */
		let geod = Geodesic.WGS84
		let result = geod.inverse(
			latitude1: 56.320923501171,
			longitude1: 0,
			latitude2: -56.320923501171,
			longitude2: 179.664747671772880215
		)
		#expect(isEqual(result.distance, 19993558.287, precision: 0.5e-3))
	}

	@Test
	func testGeodSolve10() {
		/* Check fix for adjust tol1_ bug found 2011-06-25 (Visual Studio
		 * 10 rel + debug) */
		let geod = Geodesic.WGS84
		let result = geod.inverse(
			latitude1: 52.784459512564,
			longitude1: 0,
			latitude2: -52.784459512563990912,
			longitude2: 179.634407464943777557,
		)
		#expect(isEqual(result.distance, 19991596.095, precision: 0.5e-3))
	}

	@Test
	func testGeodSolve11() {
		/* Check fix for bet2 = -bet1 bug found 2011-06-25 (Visual Studio
		 * 10 rel + debug) */
		let geod = Geodesic.WGS84
		let result = geod.inverse(
			latitude1: 48.522876735459,
			longitude1: 0,
			latitude2: -48.52287673545898293,
			longitude2: 179.599720456223079643,
		)
		#expect(isEqual(result.distance, 19989144.774, precision: 0.5e-3))
	}

	@Test
	func testGeodSolve12() {
		/* Check fix for inverse geodesics on extreme prolate/oblate
		 * ellipsoids Reported 2012-08-29 Stefan Guenther
		 * <stefan.gunther@embl.de>) fixed 2012-10-07 */
		let geod = Geodesic(equatorialRadius: 89.8, flattening: -1.83)
		let result = geod.inverse(latitude1: 0, longitude1: 0, latitude2: -10, longitude2: 160)
		#expect(isEqual(result.azimuth1, 120.27, precision: 1e-2))
		#expect(isEqual(result.azimuth2, 105.15, precision: 1e-2))
		#expect(isEqual(result.distance, 266.7, precision: 1e-1))
	}

	@Test()
	func testGeodSolve14() {
		/* Check fix for inverse ignoring lon12 = nan */
		let geod = Geodesic.WGS84
		let result = geod.inverse(latitude1: 0, longitude1: 0, latitude2: 1, longitude2: .nan)
		#expect(result.azimuth1.isNaN)
		#expect(result.azimuth2.isNaN)
		#expect(result.distance.isNaN)
	}

	@Test
	func testGeodSolve15() {
		/* Initial implementation of Math::eatanhe was wrong for e^2 < 0.  This
		 * checks that this is fixed. */
		let geod = Geodesic(equatorialRadius: 6.4e6, flattening: -1/150.0)
		let result = geod.generalDirect(latitude: 1, longitude: 2, azimuth: 3, distance: 4)
		#expect(isEqual(result.areaUnder, 23700, precision: 0.5))
	}

	@Test
	func testGeodSolve17() {
		/* Check fix for LONG_UNROLL bug found on 2015-05-07 */
		let geod = Geodesic.WGS84
		let flags = Set<Flag>([.longitudeUnroll])
		let result = geod.generalDirect(
			latitude: 40,
			longitude: -75,
			azimuth: -10,
			distance: 2e7,
			flags: flags
		)
		#expect(isEqual(result.latitude, -39, precision: 1))
		#expect(isEqual(result.longitude, -254, precision: 1))
		#expect(isEqual(result.azimuth, -170, precision: 1))

		let result2 = geod.direct(
			latitude: 40,
			longitude: -75,
			azimuth: -10,
			distance: 2e7
		)
		#expect(isEqual(result2.latitude, -39, precision: 1))
		#expect(isEqual(result2.longitude, 105, precision: 1))
		#expect(isEqual(result2.azimuth, -170, precision: 1))
	}

	@Test
	func testGeodSolve26() {
		/* Check 0/0 problem with area calculation on sphere 2015-09-08 */
		let geod = Geodesic(equatorialRadius: 6.4e6, flattening: 0)
		let result = geod.generalInverse(latitude1: 1, longitude1: 2, latitude2: 3, longitude2: 4)
		#expect(isEqual(result.areaUnder, 49911046115.0, precision: 0.5))
	}

	@Test
	func testGeodSolve28() {
		/* Check for bad placement of assignment of r.a12 with |f| > 0.01 (bug in
		 * Java implementation fixed on 2015-05-19). */
		let geod = Geodesic(equatorialRadius: 6.4e6, flattening: 0.1)
		let result = geod.generalDirect(latitude: 1, longitude: 2, azimuth: 10, distance: 5e6, flags: [])
		#expect(isEqual(result.arcLength, 48.55570690, precision: 0.5e-8))
	}

	@Test
	func testGeodSolve33() {
		/* Check max(-0.0,+0.0) issues 2015-08-22 (triggered by bugs in Octave --
		 * sind(-0.0) = +0.0 -- and in some version of Visual Studio --
		 * fmod(-0.0, 360.0) = +0.0. */
		let geod = Geodesic.WGS84
		var result = geod.inverse(latitude1: 0, longitude1: 0, latitude2: 0, longitude2: 179, capabilities: [.distance, .azimuth])
		#expect(isEqual(result.azimuth1, 90.00000, precision: 0.5e-5))
		#expect(isEqual(result.azimuth2, 90.00000, precision: 0.5e-5))
		#expect(isEqual(result.distance, 19926189, precision: 0.5))

		result = geod.inverse(latitude1: 0, longitude1: 0, latitude2: 0, longitude2: 179.5)
		#expect(isEqual(result.azimuth1, 55.96650, precision: 0.5e-5))
		#expect(isEqual(result.azimuth2, 124.03350, precision: 0.5e-5))
		#expect(isEqual(result.distance, 19980862, precision: 0.5))

		result = geod.inverse(latitude1: 0, longitude1: 0, latitude2: 0, longitude2: 180)
		#expect(isEqual(result.azimuth1, 0.00000, precision: 0.5e-5))
		#expect(isEqual(abs(result.azimuth2), 180.00000, precision: 0.5e-5))
		#expect(isEqual(result.distance, 20003931, precision: 0.5))

		result = geod.inverse( latitude1: 0, longitude1: 0, latitude2: 1, longitude2: 180)
		#expect(isEqual(result.azimuth1, 0.00000, precision: 0.5e-5))
		#expect(isEqual(abs(result.azimuth2), 180.00000, precision: 0.5e-5))
		#expect(isEqual(result.distance, 19893357, precision: 0.5))

		let geod2 = Geodesic(equatorialRadius: 6.4e6, flattening: 0)
		let result2 = geod2.inverse(
			latitude1: 0,
			longitude1: 0,
			latitude2: 0,
			longitude2: 179,
		)
		#expect(isEqual(result2.azimuth1, 90.00000, precision: 0.5e-5))
		#expect(isEqual(result2.azimuth2, 90.00000, precision: 0.5e-5))
		#expect(isEqual(result2.distance, 19994492, precision: 0.5))

		let result3 = geod2.inverse(
			latitude1: 0,
			longitude1: 0,
			latitude2: 0,
			longitude2: 180
		)
		#expect(isEqual(result3.azimuth1, 0.00000, precision: 0.5e-5))
		#expect(isEqual(abs(result3.azimuth2), 180.00000, precision: 0.5e-5))
		#expect(isEqual(result3.distance, 20106193, precision: 0.5))

		let result4 = geod2.inverse(
			latitude1: 0,
			longitude1: 0,
			latitude2: 1,
			longitude2: 180,
		)
		#expect(isEqual(result4.azimuth1, 0.00000, precision: 0.5e-5))
		#expect(isEqual(abs(result4.azimuth2), 180.00000, precision: 0.5e-5))
		#expect(isEqual(result4.distance, 19994492, precision: 0.5))

		let geod3 = Geodesic(equatorialRadius: 6.4e6, flattening: -1/300.0)
		let result5 = geod3.inverse(latitude1: 0, longitude1: 0, latitude2: 0, longitude2: 179)
		#expect(isEqual(result5.azimuth1, 90.00000, precision: 0.5e-5))
		#expect(isEqual(result5.azimuth2, 90.00000, precision: 0.5e-5))
		#expect(isEqual(result5.distance, 19994492, precision: 0.5))
		let result6 = geod3.inverse(latitude1: 0, longitude1: 0, latitude2: 0, longitude2: 180)
		#expect(isEqual(result6.azimuth1, 90.00000, precision: 0.5e-5))
		#expect(isEqual(result6.azimuth2, 90.00000, precision: 0.5e-5))
		#expect(isEqual(result6.distance, 20106193, precision: 0.5))
		let result7 = geod3.inverse(latitude1: 0, longitude1: 0, latitude2: 0.5, longitude2: 180)
		#expect(isEqual(result7.azimuth1, 33.02493, precision: 0.5e-5))
		#expect(isEqual(result7.azimuth2, 146.97364, precision: 0.5e-5))
		#expect(isEqual(result7.distance, 20082617, precision: 0.5))
		let result8 = geod3.inverse(latitude1: 0, longitude1: 0, latitude2: 1, longitude2: 180)
		#expect(isEqual(result8.azimuth1, 0.00000, precision: 0.5e-5))
		#expect(isEqual(abs(result8.azimuth2), 180.00000, precision: 0.5e-5))
		#expect(isEqual(result8.distance, 20027270, precision: 0.5))
	}

	@Test()
	func testGeodSolve55() {
		/* Check fix for nan + point on equator or pole not returning all nans in
		 * Geodesic::Inverse, found 2015-09-23. */
		let geod = Geodesic.WGS84
		var result = geod.inverse(
			latitude1: .nan,
			longitude1: 0,
			latitude2: 0,
			longitude2: 90
		)

		#expect(result.azimuth1.isNaN)
		#expect(result.azimuth2.isNaN)
		#expect(result.distance.isNaN)

		result = geod.inverse(
			latitude1: .nan,
			longitude1: 0,
			latitude2: 90,
			longitude2: 9
		)
		#expect(result.azimuth1.isNaN)
		#expect(result.azimuth2.isNaN)
		#expect(result.distance.isNaN)
	}

	@Test
	func testGeodSolve59() {
		/* Check for points close with longitudes close to 180 deg apart. */
		let geod = Geodesic.WGS84
		let result = geod.inverse(
			latitude1: 5,
			longitude1: 0.00000000000001,
			latitude2: 10,
			longitude2: 180
		)
		#expect(isEqual(result.azimuth1, 0.000000000000035, precision: 1.5e-14))
		#expect(isEqual(result.azimuth2, 179.99999999999996, precision: 1.5e-14))
		#expect(isEqual(result.distance, 18345191.174332713, precision: 5e-9))
	}

	@Test
	func testGeodSolve61() {
		/* Make sure small negative azimuths are west-going */
		let flags = Set<Flag>([.longitudeUnroll])
		let geod = Geodesic.WGS84
		let result = geod.generalDirect(
			latitude: 45,
			longitude: 0,
			azimuth: -0.000000000000000003,
			distance: 1e7,
			flags: flags
		)
		#expect(isEqual(result.latitude, 45.30632, precision: 0.5e-5))
		#expect(isEqual(result.longitude, -180, precision: 0.5e-5))
		#expect(isEqual(abs(result.azimuth), 180, precision: 0.5e-5))
	}

	@Test(.disabled("TODO: InverseLine not implemented"))
	func testGeodSolve65() {
		/* Check for bug in east-going check in GeodesicLine (needed to check for
		 * sign of 0) and sign error in area calculation due to a bogus override of
		 * the code for alp12.  Found/fixed on 2015-12-19. */
		let flags: Set<Flag> = [.longitudeUnroll]
		let caps: Set<Capability> = Set(Capability.allCases)
		let geod = Geodesic.WGS84

		let line = Line(geodesic: geod, latitude: 0, longitude: 0, azimuth: 0, capabilities: caps)
//		let line = geod.inverseline(
//			latitude1: 30,
//			longitude1: -0.000000000000000001,
//			latitude2: -31,
//			longitude2: 180,
//			capabilities: caps
//		)

		let result = geod.genposition(line: line, s12_a12: 1e7, flags: flags)
		#expect(isEqual(result.latitude, -60.23169, precision: 0.5e-5))
		#expect(isEqual(result.longitude, -0.00000, precision: 0.5e-5))
		#expect(isEqual(abs(result.azimuth), 180.00000, precision: 0.5e-5))
		#expect(isEqual(result.distance, 10000000, precision: 0.5))
		#expect(isEqual(result.arcLength, 90.06544, precision: 0.5e-5))
		#expect(isEqual(result.m12, 6363636, precision: 0.5))
		#expect(isEqual(result.M12, -0.0012834, precision: 0.5e-7))
		#expect(isEqual(result.M21, 0.0013749, precision: 0.5e-7))
		#expect(isEqual(result.areaUnder, 0, precision: 0.5))

		let result2 = geod.genposition(line: line, s12_a12: 2e7, flags: flags)
		#expect(isEqual(result2.latitude, -30.03547, precision: 0.5e-5))
		#expect(isEqual(result2.longitude, -180.00000, precision: 0.5e-5))
		#expect(isEqual(result2.azimuth, -0.00000, precision: 0.5e-5))
		#expect(isEqual(result2.distance, 20000000, precision: 0.5))
		#expect(isEqual(result2.arcLength, 179.96459, precision: 0.5e-5))
		#expect(isEqual(result2.m12, 54342, precision: 0.5))
		#expect(isEqual(result2.M12, -1.0045592, precision: 0.5e-7))
		#expect(isEqual(result2.M21, -0.9954339, precision: 0.5e-7))
		#expect(isEqual(result2.areaUnder, 127516405431022.0, precision: 0.5))
	}

	@Test(.disabled("TODO: InverseLine not implemented"))
	func testGeodSolve67() {
		/* Check for InverseLine if line is slightly west of S and that s13 is
		 * correctly set. */
		let flags: Set<Flag> = [.longitudeUnroll]
		let geod = Geodesic.WGS84

		let line = Line(geodesic: geod, latitude: 0, longitude: 0, azimuth: 0, capabilities: [])
//		let line = geod.inverseline(
//			latitude1: -5,
//			longitude1: -0.000000000000002,
//			latitude2: -10,
//			longitude2: 180,
//			capabilities: []
//		)

		let result = geod.genposition(line: line, s12_a12: 2e7, flags: flags)
		#expect(isEqual(result.latitude, 4.96445, precision: 0.5e-5))
		#expect(isEqual(result.longitude, -180.00000, precision: 0.5e-5))
		#expect(isEqual(result.azimuth, -0.00000, precision: 0.5e-5))

		let result2 = geod.genposition(line: line, s12_a12: 0.5 * line.distance, flags: flags)
		#expect(isEqual(result2.latitude, -87.52461, precision: 0.5e-5))
		#expect(isEqual(result2.longitude, -0.00000, precision: 0.5e-5))
		#expect(isEqual(result2.azimuth, -180.00000, precision: 0.5e-5))
	}

	@Test(.disabled("TODO: implement DirectLine"))
	func testGeodSolve71() {
		/* Check that DirectLine sets s13. */
		let geod = Geodesic.WGS84

		let line = Line(geodesic: geod, latitude: 1, longitude: 2, azimuth: 45, capabilities: [])
//		let line = geod.directline(latitude1: 1, longitude1: 2, azimuth: 45, s12_a12: 1e7, flags: [])
		let result = geod.genposition(line: line, s12_a12: 0.5 * line.distance, flags: [])

		#expect(isEqual(result.latitude, 30.92625, precision: 0.5e-5))
		#expect(isEqual(result.longitude, 37.54640, precision: 0.5e-5))
		#expect(isEqual(result.azimuth, 55.43104, precision: 0.5e-5))
	}

	@Test
	func testGeodSolve73() {
		/* Check for backwards from the pole bug reported by Anon on 2016-02-13.
		 * This only affected the Java implementation.  It was introduced in Java
		 * version 1.44 and fixed in 1.46-SNAPSHOT on 2016-01-17.
		 * Also the + sign on azi2 is a check on the normalizing of azimuths
		 * (converting -0.0 to +0.0). */
		let geod = Geodesic.WGS84
		let result = geod.direct(latitude: 90, longitude: 10, azimuth: 180, distance: -1e6)
		#expect(isEqual(result.latitude, 81.04623, precision: 0.5e-5))
		#expect(isEqual(result.longitude, -170, precision: 0.5e-5))
		#expect(result.azimuth == 0)
		// TODO: does this need to be a special case handled specifically?
		// In the original implementation, this was equal to 0
		#expect(1 / result.azimuth == .infinity)
	}


	func planimeter(_ geod: Geodesic, points: [Point]) -> (area: Double, perimeter: Double) {
		let polygon = Polygon(isPolyline: false, points: points, geodesic: geod)
		return polygon.compute(geod: geod, reverse: false, sign: true)
	}

	func polylength(_ geod: Geodesic, points: [Point]) -> Double {
		let polygon = Polygon(isPolyline: true, points: points, geodesic: geod)
		return polygon.compute(geod: geod, reverse: false, sign: true).perimeter
	}

	@Test
	func testGeodSolve74() {
		/* Check fix for inaccurate areas, bug introduced in v1.46, fixed
		 * 2015-10-16. */
		let geod = Geodesic.WGS84
		let result = geod.generalInverse(
			latitude1: 54.1589,
			longitude1: 15.3872,
			latitude2: 54.1591,
			longitude2: 15.3877
		)
		#expect(isEqual(result.azimuth1, 55.723110355, precision: 5e-9))
		#expect(isEqual(result.azimuth2, 55.723515675, precision: 5e-9))
		#expect(isEqual(result.distance, 39.527686385, precision: 5e-9))
		#expect(isEqual(result.arcLength, 0.000355495, precision: 5e-9))
		#expect(isEqual(result.m12, 39.527686385, precision: 5e-9))
		#expect(isEqual(result.M12, 0.999999995, precision: 5e-9))
		#expect(isEqual(result.M21, 0.999999995, precision: 5e-9))
		#expect(isEqual(result.areaUnder, 286698586.30197, precision: 5e-4))
	}

	@Test
	func testGeodSolve76() {
		/* The distance from Wellington and Salamanca (a classic failure of
		 * Vincenty) */
		let geod = Geodesic.WGS84
		let result = geod.inverse(
			latitude1: -(41+19/60.0),
			longitude1: 174+49/60.0,
			latitude2: 40+58/60.0,
			longitude2: -(5+30/60.0)
		)
		#expect(isEqual(result.azimuth1, 160.39137649664, precision: 0.5e-11))
		#expect(isEqual(result.azimuth2,  19.50042925176, precision: 0.5e-11))
		#expect(isEqual(result.distance,  19960543.857179, precision: 0.5e-6))
	}

	@Test
	func testGeodSolve78() {
		/* An example where the NGS calculator fails to converge */
		let geod = Geodesic.WGS84
		let result = geod.inverse(
			latitude1: 27.2,
			longitude1: 0.0,
			latitude2: -27.1,
			longitude2: 179.5
		)
		#expect(isEqual(result.azimuth1,  45.82468716758, precision: 0.5e-11))
		#expect(isEqual(result.azimuth2, 134.22776532670, precision: 0.5e-11))
		#expect(isEqual(result.distance,  19974354.765767, precision: 0.5e-6))
	}

	@Test
	func testGeodSolve80() {
		/* Some tests to add code coverage: computing scale in special cases + zero
		 * length geodesic (includes GeodSolve80 - GeodSolve83) + using an incapable
		 * line. */
		let geod = Geodesic.WGS84
		var result = geod.generalInverse(
			latitude1: 0,
			longitude1: 0,
			latitude2: 0,
			longitude2: 90
		)
		#expect(isEqual(result.M12, -0.00528427534, precision: 0.5e-10))
		#expect(isEqual(result.M21, -0.00528427534, precision: 0.5e-10))

		result = geod.generalInverse(
			latitude1: 0,
			longitude1: 0,
			latitude2: 1e-6,
			longitude2: 1e-6,
		)
		#expect(isEqual(result.M12, 1, precision: 0.5e-10))
		#expect(isEqual(result.M21, 1, precision: 0.5e-10))

		result = geod.generalInverse(
			latitude1: 20.001,
			longitude1: 0,
			latitude2: 20.001,
			longitude2: 0
		)
		#expect(isEqual(result.arcLength, 0, precision: 1e-13))
		#expect(isEqual(result.distance, 0, precision: 1e-8))
		#expect(isEqual(result.azimuth1, 180, precision: 1e-13))
		#expect(isEqual(result.azimuth2, 180, precision: 1e-13))
		#expect(isEqual(result.m12, 0, precision: 1e-8))
		#expect(isEqual(result.M12, 1, precision: 1e-15))
		#expect(isEqual(result.M21, 1, precision: 1e-15))
		#expect(isEqual(result.areaUnder, 0, precision: 1e-10))
		#expect(1/result.arcLength > 0)
		#expect(1/result.distance > 0)
		#expect(1/result.m12 > 0)

		result = geod.generalInverse(
			latitude1: 90,
			longitude1: 0,
			latitude2: 90,
			longitude2: 180
		)
		#expect(isEqual(result.arcLength, 0, precision: 1e-13))
		#expect(isEqual(result.distance, 0, precision: 1e-8))
		#expect(isEqual(result.azimuth1, 0, precision: 1e-13))
		#expect(isEqual(result.azimuth2, 180, precision: 1e-13))
		#expect(isEqual(result.m12, 0, precision: 1e-8))
		#expect(isEqual(result.M12, 1, precision: 1e-15))
		#expect(isEqual(result.M21, 1, precision: 1e-15))
		#expect(isEqual(result.areaUnder, 127516405431022.0, precision: 0.5))

		/* An incapable line which can't take distance as input */
		let line = Line(geodesic: geod, latitude: 1, longitude: 2, azimuth: 90, capabilities: [.latitude])
		let result2 = geod.genposition(line: line, s12_a12: 1000, flags: [])
		#expect(result2.arcLength.isNaN)
	}

	@Test
	func testGeodSolve84() {
		/* Tests for python implementation to check fix for range errors with
		 * {fmod,sin,cos}(inf) (includes GeodSolve84 - GeodSolve86). */

		let geod = Geodesic.WGS84
		var result = geod.direct(latitude: 0, longitude: 0, azimuth: 90, distance: .infinity)
		#expect(result.latitude.isNaN)
		#expect(result.longitude.isNaN)
		#expect(result.azimuth.isNaN)

		result = geod.direct(latitude: 0, longitude: 0, azimuth: 90, distance: .nan)
		#expect(result.latitude.isNaN)
		#expect(result.longitude.isNaN)
		#expect(result.azimuth.isNaN)

		result = geod.direct(latitude: 0, longitude: 0, azimuth: .infinity, distance: 1000)
		#expect(result.latitude.isNaN)
		#expect(result.longitude.isNaN)
		#expect(result.azimuth.isNaN)

		result = geod.direct(latitude: 0, longitude: 0, azimuth: .nan, distance: 1000)
		#expect(result.latitude.isNaN)
		#expect(result.longitude.isNaN)
		#expect(result.azimuth.isNaN)

		result = geod.direct(latitude: 0, longitude: .infinity, azimuth: 90, distance: 1000)
		#expect(result.latitude == 0)
		#expect(result.longitude.isNaN)
		#expect(result.azimuth == 90)

		result = geod.direct(latitude: 0, longitude: .nan, azimuth: 90, distance: 1000)
		#expect(result.latitude == 0)
		#expect(result.longitude.isNaN)
		#expect(result.azimuth == 90)

		result = geod.direct(latitude: .infinity, longitude: 0, azimuth: 90, distance: 1000)
		#expect(result.latitude.isNaN)
		#expect(result.longitude.isNaN)
		#expect(result.azimuth.isNaN)

		result = geod.direct(latitude: .nan, longitude: 0, azimuth: 90, distance: 1000)
		#expect(result.latitude.isNaN)
		#expect(result.longitude.isNaN)
		#expect(result.azimuth.isNaN)
	}

	@Test
	func testGeodSolve92() {
		/* Check fix for inaccurate hypot with python 3.[89].  Problem reported
		 * by agdhruv https://github.com/geopy/geopy/issues/466  see
		 * https://bugs.python.org/issue43088 */
		let geod = Geodesic.WGS84
		let result = geod.inverse(
			latitude1: 37.757540000000006,
			longitude1: -122.47018,
			latitude2: 37.75754,
			longitude2: -122.470177,
		)
		#expect(isEqual(result.azimuth1, 89.99999923, precision: 1e-7))
		#expect(isEqual(result.azimuth2, 90.00000106, precision: 1e-7))
		#expect(isEqual(result.distance, 0.264, precision: 0.5e-3))
	}

	@Test()
	func testGeodSolve94() {
		/* Check fix for lat2 = nan being treated as lat2 = 0 (bug found
		 * 2021-07-26) */
		let geod = Geodesic.WGS84
		let result = geod.inverse(latitude1: 0, longitude1: 0, latitude2: .nan, longitude2: 90)
		#expect(result.azimuth1.isNaN)
		#expect(result.azimuth2.isNaN)
		#expect(result.distance.isNaN)
	}

	@Test
	func testGeodSolve96() {
		/* Failure with long doubles found with test case from Nowak + Nowak Da
		 * Costa (2022).  Problem was using somg12 > 1 as a test that it needed
		 * to be set when roundoff could result in somg12 slightly bigger that 1.
		 * Found + fixed 2022-03-30. */
		let geod = Geodesic(equatorialRadius: 6378137, flattening: 1/298.257222101)
		let result = geod.generalInverse(latitude1: 0, longitude1: 0, latitude2: 60.0832522871723, longitude2: 89.8492185074635)
		#expect(isEqual(result.areaUnder, 42426932221845, precision: 0.5))
	}

	@Test
	func testGeodSolve99() {
		/* Test case https://github.com/geographiclib/geographiclib-js/issues/3
		 * Problem was that output of sincosd(+/-45) was inconsistent because of
		 * directed rounding by Javascript's Math.round.  C implementation was OK. */
		let geod = Geodesic.WGS84
		let result = geod.inverse(
			latitude1: 45.0,
			longitude1: 0.0,
			latitude2: -45.0,
			longitude2: 179.572719
		)
		#expect(isEqual(result.azimuth1, 90.00000028, precision: 1e-8))
		#expect(isEqual(result.azimuth2, 90.00000028, precision: 1e-8))
		#expect(isEqual(result.distance, 19987083.007, precision: 0.5e-3))
	}

	@Test
	func testGeodSolve100() {
		/* Check fix for meridional failure for a strongly prolate ellipsoid.
		 * This was caused by assuming that sig12 < 1 guarantees the meridional
		 * geodesic is shortest (even though m12 < 0).  Counter example is tested
		 * here.  Bug is not present for f >= -2, b < 3*a.  For f = -2.1 the
		 * inverse calculation for 30.61 0 30.61 180 exhibits the bug. */
		let geod = Geodesic(equatorialRadius: 1e6, flattening: -3)
		let result = geod.inverse(latitude1: 30.0, longitude1: 0.0, latitude2: 30.0, longitude2: 180.0)
		/* Sloppy bounds checking because series solution is inaccurate for
		 * ellipsoids this eccentric. */
		#expect(isEqual(result.azimuth1, 22.368806, precision: 1.0))
		#expect(isEqual(result.azimuth2, 157.631194, precision: 1.0))
		#expect(isEqual(result.distance, 1074081.6, precision: 1e3))
	}

	@Test
	func testPlanimeter0() {
		/* Check fix for pole-encircling bug found 2011-03-16 */
		let pointsA: [Point] = [
			Point(latitude: 89, longitude: 0), Point(latitude: 89, longitude: 90), Point(latitude: 89, longitude: 180), Point(latitude: 89, longitude: 270)
		]
		let pointsB: [Point] = [
			Point(latitude: -89, longitude: 0), Point(latitude: -89, longitude: 90), Point(latitude: -89, longitude: 180), Point(latitude: -89, longitude: 270)
		]
		let pointsC: [Point] = [
			Point(latitude: 0, longitude: -1), Point(latitude: -1, longitude: 0), Point(latitude: 0, longitude: 1), Point(latitude: 1, longitude: 0)
		]
		let pointsD: [Point] = [
			Point(latitude: 90, longitude: 0), Point(latitude: 0, longitude: 0), Point(latitude: 0, longitude: 90)
		]

		let geod = Geodesic.WGS84
		var result = planimeter(geod, points: pointsA)
		#expect(isEqual(result.perimeter, 631819.8745, precision: 1e-4))
		#expect(isEqual(result.area, 24952305678.0, precision: 1))

		result = planimeter(geod, points: pointsB)
		#expect(isEqual(result.perimeter, 631819.8745, precision: 1e-4))
		#expect(isEqual(result.area, -24952305678.0, precision: 1))

		result = planimeter(geod, points: pointsC)
		#expect(isEqual(result.perimeter, 627598.2731, precision: 1e-4))
		#expect(isEqual(result.area, 24619419146.0, precision: 1))

		result = planimeter(geod, points: pointsD)
		#expect(isEqual(result.perimeter, 30022685, precision: 1))
		#expect(isEqual(result.area, 63758202715511.0, precision: 1))

		let perimeter = polylength(geod, points: pointsD)
		#expect(isEqual(perimeter, 20020719, precision: 1))
	}

	@Test
	func testPlanimeter5() {
		/* Check fix for Planimeter pole crossing bug found 2011-06-24 */
		let points = [Point(latitude: 89, longitude: 0.1), Point(latitude: 89, longitude: 90.1), Point(latitude: 89, longitude: -179.9)]
		let geod = Geodesic.WGS84
		let result = planimeter(geod, points: points)
		#expect(isEqual(result.perimeter, 539297, precision: 1))
		#expect(isEqual(result.area, 12476152838.5, precision: 1))
	}

	@Test
	func testPlanimeter6() {
		/* Check fix for Planimeter lon12 rounding bug found 2012-12-03 */
		let pointsA = [
			Point(latitude: 9, longitude: -0.00000000000001),
			Point(latitude: 9, longitude: 180),
			Point(latitude: 9, longitude: 0)
		]
		let pointsB = [
			Point(latitude: 9, longitude: 0.00000000000001),
			Point(latitude: 9, longitude: 0),
			Point(latitude: 9, longitude: 180)
		]
		let pointsC = [
			Point(latitude: 9, longitude: 0.00000000000001),
			Point(latitude: 9, longitude: 180),
			Point(latitude: 9, longitude: 0)
		]
		let pointsD = [
			Point(latitude: 9, longitude: -0.00000000000001),
			Point(latitude: 9, longitude: 0),
			Point(latitude: 9, longitude: 180)
		]

		let geod = Geodesic.WGS84
		var result = planimeter(geod, points: pointsA)
		#expect(isEqual(result.perimeter, 36026861, precision: 1))
		#expect(isEqual(result.area, 0, precision: 1))

		result = planimeter(geod, points: pointsB)
		#expect(isEqual(result.perimeter, 36026861, precision: 1))
		#expect(isEqual(result.area, 0, precision: 1))

		result = planimeter(geod, points: pointsC)
		#expect(isEqual(result.perimeter, 36026861, precision: 1))
		#expect(isEqual(result.area, 0, precision: 1))

		result = planimeter(geod, points: pointsD)
		#expect(isEqual(result.perimeter, 36026861, precision: 1))
		#expect(isEqual(result.area, 0, precision: 1))
	}

	@Test
	func testPlanimeter12() {
		/* Area of arctic circle (not really -- adjunct to rhumb-area test) */
		let points = [
			Point(latitude: 66.562222222, longitude: 0),
			Point(latitude: 66.562222222, longitude: 180),
			Point(latitude: 66.562222222, longitude: 360)
		]
		let geod = Geodesic.WGS84
		let result = planimeter(geod, points: points)
		#expect(isEqual(result.perimeter, 10465729, precision: 1))
		#expect(isEqual(result.area, 0, precision: 1))
	}

	@Test
	func testPlanimeter12r() {
		/* Area of arctic circle (not really -- adjunct to rhumb-area test) */
		let points = [
			Point(latitude: 66.562222222, longitude: -0),
			Point(latitude: 66.562222222, longitude: -180),
			Point(latitude: 66.562222222, longitude: -360)
		]
		let geod = Geodesic.WGS84
		let result = planimeter(geod, points: points)
		#expect(isEqual(result.perimeter, 10465729, precision: 1))
		#expect(isEqual(result.area, 0, precision: 1))
	}

	@Test
	func testPlanimeter13() {
		/* Check encircling pole twice */
		let points = [
			Point(latitude: 89, longitude: -360),
			Point(latitude: 89, longitude: -240),
			Point(latitude: 89, longitude: -120),
			Point(latitude: 89, longitude: 0),
			Point(latitude: 89, longitude: 120),
			Point(latitude: 89, longitude: 240)
		]
		let geod = Geodesic.WGS84
		let result = planimeter(geod, points: points)
		#expect(isEqual(result.perimeter, 1160741, precision: 1))
		#expect(isEqual(result.area, 32415230256.0, precision: 1))
	}

	@Test
	func testPlanimeter15() {
		/* Coverage tests, includes Planimeter15 - Planimeter18 (combinations of
		 * reverse and sign) + calls to testpoint, testedge, geod_polygonarea. */
		let points = [
			Point(latitude: 2, longitude: 1),
			Point(latitude: 1, longitude: 2),
			Point(latitude: 3, longitude: 3)
		]

		let r = 18454562325.45119
		let a0 = 510065621724088.5093  /* ellipsoid area */

		let geod = Geodesic.WGS84
		let polygon = Polygon(isPolyline: false)
		polygon.addPoint(geod: geod, point: points[0])
		polygon.addPoint(geod: geod, point: points[1])

		var result = polygon.testPoint(geod: geod, point: points[2], reverse: false, sign: true)
		#expect(isEqual(result.area, r, precision: 0.5))
		result = polygon.testPoint(geod: geod, point: points[2], reverse: false, sign: false)
		#expect(isEqual(result.area, r, precision: 0.5))
		result = polygon.testPoint(geod: geod, point: points[2], reverse: true, sign: true)
		#expect(isEqual(result.area, -r, precision: 0.5))
		result = polygon.testPoint(geod: geod, point: points[2], reverse: true, sign: false)
		#expect(isEqual(result.area, a0-r, precision: 0.5))

		let inverseResult = geod.inverse(
			latitude1: points[1].latitude,
			longitude1: points[1].longitude,
			latitude2: points[2].latitude,
			longitude2: points[2].longitude
		)

		result = polygon.testEdge(geod: geod, azimuth: inverseResult.azimuth1, distance: inverseResult.distance, reverse: false, sign: true)
		#expect(isEqual(result.area, r, precision: 0.5))

		result = polygon.testEdge(geod: geod, azimuth: inverseResult.azimuth1, distance: inverseResult.distance, reverse: false, sign: false)
		#expect(isEqual(result.area, r, precision: 0.5))

		result = polygon.testEdge(geod: geod, azimuth: inverseResult.azimuth1, distance: inverseResult.distance, reverse: true, sign: true)
		#expect(isEqual(result.area, -r, precision: 0.5))

		result = polygon.testEdge(geod: geod, azimuth: inverseResult.azimuth1, distance: inverseResult.distance, reverse: true, sign: false)
		#expect(isEqual(result.area, a0-r, precision: 0.5))

		polygon.addPoint(geod: geod, point: points[2])
		result = polygon.compute(geod: geod, reverse: false, sign: true)
		#expect(isEqual(result.area, r, precision: 0.5))

		result = polygon.compute(geod: geod, reverse: false, sign: false)
		#expect(isEqual(result.area, r, precision: 0.5))

		result = polygon.compute(geod: geod, reverse: true, sign: true)
		#expect(isEqual(result.area, -r, precision: 0.5))

		result = polygon.compute(geod: geod, reverse: true, sign: false)
		#expect(isEqual(result.area, a0-r, precision: 0.5))

		let areaResult = geod.polygonArea(points: points)
		#expect(isEqual(areaResult.area, r, precision: 0.5))
	}

	@Test
	func testPlanimeter19() {
		/* Coverage tests, includes Planimeter19 - Planimeter20 (degenerate
		 * polygons) + extra cases.  */
		let geod = Geodesic.WGS84
		let polygon = Polygon(isPolyline: false)
		var result = polygon.compute(geod: geod, reverse: false, sign: true)
		#expect(result.area == 0)
		#expect(result.perimeter == 0)

		result = polygon.testPoint(geod: geod, point: Point(latitude: 1, longitude: 1), reverse: false, sign: true)
		#expect(result.area == 0)
		#expect(result.perimeter == 0)

		result = polygon.testEdge(geod: geod, azimuth: 90, distance: 1000, reverse: false, sign: true)
		#expect(result.area.isNaN)
		#expect(result.perimeter.isNaN)

		polygon.addPoint(geod: geod, point: Point(latitude: 1, longitude: 1))
		result = polygon.compute(geod: geod, reverse: false, sign: true)
		#expect(result.area == 0)
		#expect(result.perimeter == 0)

		let polylinePolygon = Polygon(isPolyline: true)
		var polyResult = polylinePolygon.compute(geod: geod, reverse: false, sign: true)
		#expect(polyResult.perimeter == 0)

		polyResult = polylinePolygon.testPoint(geod: geod, point: Point(latitude: 1, longitude: 1), reverse: false, sign: true)
		#expect(polyResult.perimeter == 0)

		polyResult = polylinePolygon.testEdge(geod: geod, azimuth: 90, distance: 1000, reverse: false, sign: true)
		#expect(polyResult.perimeter.isNaN)

		polylinePolygon.addPoint(geod: geod, point: Point(latitude: 1, longitude: 1))
		polyResult = polylinePolygon.compute(geod: geod, reverse: false, sign: true)
		#expect(polyResult.perimeter == 0)

		polylinePolygon.addPoint(geod: geod, point: Point(latitude: 1, longitude: 1))

		polyResult = polylinePolygon.testEdge(geod: geod, azimuth: 90, distance: 1000, reverse: false, sign: true)
		#expect(isEqual(polyResult.perimeter, 1000, precision: 1e-10))

		polyResult = polylinePolygon.testPoint(geod: geod, point: Point(latitude: 2, longitude: 2), reverse: false, sign: true)
		#expect(isEqual(polyResult.perimeter, 156876.149, precision: 0.5e-3))
	}

	@Test
	func testPlanimeter21() {
		/* Some tests to add code coverage: multiple circlings of pole (includes
		 * Planimeter21 - Planimeter28) + invocations via testpoint and testedge. */
		let a = 39.2144607176828184218
		let s = 8420705.40957178156285
		// Area for one circuit
		let r = 39433884866571.4277
		// Ellipsoid area
		let a0 = 510065621724088.5093
		let lat = 45.0

		let geod = Geodesic.WGS84
		let polygon = Polygon(isPolyline: false)

		polygon.addPoint(geod: geod, point: Point(latitude: lat, longitude: 60))
		polygon.addPoint(geod: geod, point: Point(latitude: lat, longitude: 180))
		polygon.addPoint(geod: geod, point: Point(latitude: lat, longitude: -60))
		polygon.addPoint(geod: geod, point: Point(latitude: lat, longitude: 60))
		polygon.addPoint(geod: geod, point: Point(latitude: lat, longitude: 180))
		polygon.addPoint(geod: geod, point: Point(latitude: lat, longitude: -60))

		var result: (area: Double, perimeter: Double)
		for i in 3...4 {
			polygon.addPoint(geod: geod, point: Point(latitude: lat, longitude: 60))
			polygon.addPoint(geod: geod, point: Point(latitude: lat, longitude: 180))
			result = polygon.testPoint(geod: geod, point: Point(latitude: lat, longitude: -60), reverse: false, sign: true)
			#expect(isEqual(result.area, Double(i) * r, precision: 0.5))
			result = polygon.testPoint(geod: geod, point: Point(latitude: lat, longitude: -60), reverse: false, sign: false)
			#expect(isEqual(result.area, Double(i) * r, precision: 0.5))
			result = polygon.testPoint(geod: geod, point: Point(latitude: lat, longitude: -60), reverse: true, sign: true)
			#expect(isEqual(result.area, -Double(i) * r, precision: 0.5))
			result = polygon.testPoint(geod: geod, point: Point(latitude: lat, longitude: -60), reverse: true, sign: false)
			#expect(isEqual(result.area, -Double(i) * r + a0, precision: 0.5))

			result = polygon.testEdge(geod: geod, azimuth: a, distance: s, reverse: false, sign: true)
			#expect(isEqual(result.area, Double(i) * r, precision: 0.5))
			result = polygon.testEdge(geod: geod, azimuth:a, distance: s, reverse: false, sign: false)
			#expect(isEqual(result.area, Double(i) * r, precision: 0.5))
			result = polygon.testEdge(geod: geod, azimuth:a, distance: s, reverse: true, sign: true)
			#expect(isEqual(result.area, -Double(i) * r, precision: 0.5))
			result = polygon.testEdge(geod: geod, azimuth:a, distance: s, reverse: true, sign: false)
			#expect(isEqual(result.area, -Double(i) * r + a0, precision: 0.5))

			polygon.addPoint(geod: geod, point: Point(latitude: lat, longitude: -60))

			result = polygon.compute(geod: geod, reverse: false, sign: true)
			#expect(isEqual(result.area, Double(i) * r, precision: 0.5))
			result = polygon.compute(geod: geod, reverse: false, sign: false)
			#expect(isEqual(result.area, Double(i) * r, precision: 0.5))
			result = polygon.compute(geod: geod, reverse: true, sign: true)
			#expect(isEqual(result.area, -Double(i) * r, precision: 0.5))
			result = polygon.compute(geod: geod, reverse: true, sign: false)
			#expect(isEqual(result.area, -Double(i) * r + a0, precision: 0.5))
		}
	}

	@Test
	func testPlanimeter29() {
		/* Check fix to transitdirect vs transit zero handling inconsistency */
		let geod = Geodesic.WGS84
		let polygon = Polygon(isPolyline: false)
		polygon.addPoint(geod: geod, point: Point(latitude: 0, longitude: 0))
		polygon.addEdge(geod: geod, azimuth: 90, distance: 1000)
		polygon.addEdge(geod: geod, azimuth: 0, distance: 1000)
		polygon.addEdge(geod: geod, azimuth: -90, distance: 1000)

		let result = polygon.compute(geod: geod, reverse: false, sign: true)
		/* The area should be 1e6.  Prior to the fix it was 1e6 - A/2, where
		 * A = ellipsoid area. */
		#expect(isEqual(result.area, 1000000.0, precision: 0.01))
	}
}
