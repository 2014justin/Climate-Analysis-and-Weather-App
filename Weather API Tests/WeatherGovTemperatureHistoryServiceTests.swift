import XCTest
@testable import Weather_API

@MainActor
final class
WeatherGovTemperatureHistoryServiceTests:
    XCTestCase {

    func testFetchesPahrumpHistoryAndCalculatesExtrema()
        async throws {

        let station =
            AtlasStation(
                source:
                    AtlasStationSource(
                        countryCode: "US",
                        providerID:
                            WeatherGovAPI.providerID,
                        stationID: "CMP17"
                    ),
                name: "Pahrump",
                latitude: 36.22111,
                longitude: -115.99528,
                elevationMeters: 804.7,
                networkName:
                    "MesoWest / CEMP",
                tier: .supplemental,
                administrativeAreaCode: "NV",
                displayPriority: nil
            )

        let windowEnd =
            Date()

        let samples =
            try await
                WeatherGovTemperatureHistoryService()
                    .fetchPrevious24Hours(
                        for: station,
                        endingAt: windowEnd
                    )

        XCTAssertGreaterThan(
            samples.count,
            12
        )

        XCTAssertTrue(
            samples.allSatisfy {
                $0.stationID
                    == station.id
            }
        )

        let windowStart =
            windowEnd.addingTimeInterval(
                -AtlasTemperatureExtremaCalculator
                    .defaultWindow
            )

        XCTAssertTrue(
            samples.allSatisfy {
                $0.observedAt >= windowStart
                    && $0.observedAt <= windowEnd
            }
        )

        XCTAssertTrue(
            samples.allSatisfy {
                (-50...150).contains(
                    $0.temperatureFahrenheit
                )
            }
        )

        let extrema =
            try XCTUnwrap(
                AtlasTemperatureExtremaCalculator
                    .rollingExtrema(
                        for: station.id,
                        in: samples,
                        endingAt: windowEnd
                    )
            )

        XCTAssertEqual(
            extrema.stationID,
            station.id
        )

        XCTAssertEqual(
            extrema.sampleCount,
            samples.count
        )

        XCTAssertLessThanOrEqual(
            extrema.minimumTemperatureFahrenheit,
            extrema.maximumTemperatureFahrenheit
        )

        XCTAssertGreaterThanOrEqual(
            extrema.minimumObservedAt,
            windowStart
        )

        XCTAssertLessThanOrEqual(
            extrema.maximumObservedAt,
            windowEnd
        )
    }
}
