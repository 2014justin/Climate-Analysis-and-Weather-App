import XCTest
@testable import Weather_API

final class
AviationWeatherTemperatureHistoryServiceTests:
    XCTestCase {

    func testDecodesFiltersConvertsAndSortsHistory() throws {
        let json = """
        [
          {
            "icaoId": "KDEN",
            "obsTime": 2000003600,
            "temp": 20
          },
          {
            "icaoId": "CYEG",
            "obsTime": 2000000000,
            "temp": 10
          },
          {
            "icaoId": "KDEN",
            "obsTime": 2000000000,
            "temp": 15
          },
          {
            "icaoId": "KOTHER",
            "obsTime": 2000000000,
            "temp": -10
          },
          {
            "icaoId": "KDEN",
            "obsTime": 2000007200
          }
        ]
        """

        let data = try XCTUnwrap(
            json.data(using: .utf8)
        )

        let samples =
            try AviationWeatherTemperatureHistoryService
                .decodeSamples(
                    from: data,
                    requestedStationIDs: [
                        "KDEN",
                        "CYEG"
                    ]
                )

        XCTAssertEqual(samples.count, 3)

        XCTAssertEqual(samples[0].stationID, "CYEG")
        XCTAssertEqual(
            samples[0].temperatureFahrenheit,
            50,
            accuracy: 0.0001
        )

        XCTAssertEqual(samples[1].stationID, "KDEN")
        XCTAssertEqual(
            samples[1].temperatureFahrenheit,
            59,
            accuracy: 0.0001
        )

        XCTAssertEqual(samples[2].stationID, "KDEN")
        XCTAssertEqual(
            samples[2].temperatureFahrenheit,
            68,
            accuracy: 0.0001
        )

        XCTAssertLessThan(
            samples[1].observedAt,
            samples[2].observedAt
        )
    }
}
