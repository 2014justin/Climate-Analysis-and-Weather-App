import XCTest
@testable import Weather_API

@MainActor
final class
WeatherGovLatestObservationServiceTests:
    XCTestCase {

    func testFetchesLatestPahrumpObservation()
        async throws {

        let pahrumpStation = AtlasStation(
            source: AtlasStationSource(
                countryCode: "US",
                providerID:
                    WeatherGovAPI.providerID,
                stationID: "CMP17"
            ),
            name: "Pahrump",
            latitude: 36.22111,
            longitude: -115.99528,
            elevationMeters: 804.7,
            networkName: "MesoWest / CEMP",
            tier: .supplemental,
            administrativeAreaCode: "NV",
            displayPriority: nil
        )

        let fetchedObservation =
            try await
                WeatherGovLatestObservationService()
                    .fetchLatestObservation(
                        for: pahrumpStation
                    )

        let observation = try XCTUnwrap(
            fetchedObservation
        )

        XCTAssertEqual(
            observation.station.source.stationID,
            "CMP17"
        )

        XCTAssertTrue(
            (-50...150).contains(
                observation.temperatureFahrenheit
            )
        )

        XCTAssertGreaterThan(
            observation.observedAt,
            Date().addingTimeInterval(
                -3 * 60 * 60
            )
        )

        if let dewPoint =
                observation.dewPointFahrenheit {
            XCTAssertTrue(
                (-120...120).contains(dewPoint)
            )
        }

        if let windSpeed =
                observation.windSpeedMilesPerHour {
            XCTAssertGreaterThanOrEqual(
                windSpeed,
                0
            )
        }
    }
}
