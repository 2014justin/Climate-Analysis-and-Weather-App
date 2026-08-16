import XCTest
@testable import Weather_API

final class AtlasTemperatureExtremaCalculatorTests:
    XCTestCase {

    private let stationID = "KTEST"

    private let windowEnd =
        Date(timeIntervalSince1970: 2_000_000_000)

    private func sample(
        stationID: String = "KTEST",
        hoursBeforeEnd: Double,
        temperatureFahrenheit: Double
    ) -> AtlasTemperatureHistorySample {

        AtlasTemperatureHistorySample(
            stationID: stationID,
            observedAt: windowEnd.addingTimeInterval(
                -hoursBeforeEnd * 60.0 * 60.0
            ),
            temperatureFahrenheit:
                temperatureFahrenheit
        )
    }

    func testFindsExtremaWithinPrevious24Hours() {
        let samples = [
            sample(
                hoursBeforeEnd: 2,
                temperatureFahrenheit: 70
            ),
            sample(
                hoursBeforeEnd: 8,
                temperatureFahrenheit: 38
            ),
            sample(
                hoursBeforeEnd: 16,
                temperatureFahrenheit: 82
            )
        ]

        let result =
            AtlasTemperatureExtremaCalculator
                .rollingExtrema(
                    for: stationID,
                    in: samples,
                    endingAt: windowEnd
                )

        XCTAssertEqual(
            result?.minimumTemperatureFahrenheit,
            38
        )
        XCTAssertEqual(
            result?.maximumTemperatureFahrenheit,
            82
        )
        XCTAssertEqual(result?.sampleCount, 3)
    }

    func testExcludesObservationsOlderThan24Hours() {
        let samples = [
            sample(
                hoursBeforeEnd: 6,
                temperatureFahrenheit: 45
            ),
            sample(
                hoursBeforeEnd: 12,
                temperatureFahrenheit: 75
            ),
            sample(
                hoursBeforeEnd: 25,
                temperatureFahrenheit: -30
            )
        ]

        let result =
            AtlasTemperatureExtremaCalculator
                .rollingExtrema(
                    for: stationID,
                    in: samples,
                    endingAt: windowEnd
                )

        XCTAssertEqual(
            result?.minimumTemperatureFahrenheit,
            45
        )
        XCTAssertEqual(
            result?.maximumTemperatureFahrenheit,
            75
        )
        XCTAssertEqual(result?.sampleCount, 2)
    }

    func testIgnoresOtherStations() {
        let samples = [
            sample(
                hoursBeforeEnd: 4,
                temperatureFahrenheit: 50
            ),
            sample(
                hoursBeforeEnd: 10,
                temperatureFahrenheit: 78
            ),
            sample(
                stationID: "KOTHER",
                hoursBeforeEnd: 5,
                temperatureFahrenheit: -40
            ),
            sample(
                stationID: "KOTHER",
                hoursBeforeEnd: 7,
                temperatureFahrenheit: 120
            )
        ]

        let result =
            AtlasTemperatureExtremaCalculator
                .rollingExtrema(
                    for: stationID,
                    in: samples,
                    endingAt: windowEnd
                )

        XCTAssertEqual(
            result?.minimumTemperatureFahrenheit,
            50
        )
        XCTAssertEqual(
            result?.maximumTemperatureFahrenheit,
            78
        )
        XCTAssertEqual(result?.sampleCount, 2)
    }

    func testHistoryStoreDeduplicatesStationTimestampPairs() async {
        let store = AtlasTemperatureHistoryStore()

        let original = sample(
            hoursBeforeEnd: 2,
            temperatureFahrenheit: 70
        )
        let corrected = sample(
            hoursBeforeEnd: 2,
            temperatureFahrenheit: 71
        )

        await store.ingest(
            [original, corrected],
            referenceDate: windowEnd
        )

        let result = await store.rollingExtrema(
            for: stationID,
            endingAt: windowEnd
        )

        XCTAssertEqual(result?.minimumTemperatureFahrenheit, 71)
        XCTAssertEqual(result?.maximumTemperatureFahrenheit, 71)
        XCTAssertEqual(result?.sampleCount, 1)
    }

    func testHistoryStorePrunesExpiredSamples() async {
        let store = AtlasTemperatureHistoryStore()

        await store.ingest(
            [
                sample(
                    hoursBeforeEnd: 23,
                    temperatureFahrenheit: 40
                ),
                sample(
                    hoursBeforeEnd: 1,
                    temperatureFahrenheit: 75
                )
            ],
            referenceDate: windowEnd
        )

        let laterWindowEnd = windowEnd.addingTimeInterval(
            2 * 60 * 60
        )

        await store.ingest(
            [],
            referenceDate: laterWindowEnd
        )

        let result = await store.rollingExtrema(
            for: stationID,
            endingAt: laterWindowEnd
        )

        XCTAssertEqual(result?.minimumTemperatureFahrenheit, 75)
        XCTAssertEqual(result?.maximumTemperatureFahrenheit, 75)
        XCTAssertEqual(result?.sampleCount, 1)
    }
    
    func testHistoryStoreReturnsRequestedStationsAsBatch() async {
        let store = AtlasTemperatureHistoryStore()
        
        await store.ingest(
            [
                sample(
                    stationID: "KTEST",
                    hoursBeforeEnd: 12,
                    temperatureFahrenheit: 40
                ),
                sample(stationID: "KTEST", hoursBeforeEnd: 2, temperatureFahrenheit: 75),
                sample(stationID: "KOTHER", hoursBeforeEnd: 8, temperatureFahrenheit: 20),
                sample(stationID: "KOTHER", hoursBeforeEnd: 1, temperatureFahrenheit: 60)
            ],
            referenceDate: windowEnd
        )
        
        let results = await store.rollingExtrema(
            for: [
                "KTEST",
                "KOTHER",
                "KMISSING",
                "KTEST"
            ],
            endingAt: windowEnd
        )
        
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(
            results["KTEST"]?.minimumTemperatureFahrenheit, 40
        )
        XCTAssertEqual(
            results["KTEST"]?.maximumTemperatureFahrenheit,
            75
        )
        XCTAssertEqual(
            results["KOTHER"]?.minimumTemperatureFahrenheit, 20
        )
        XCTAssertEqual(
            results["KOTHER"]?.maximumTemperatureFahrenheit, 60
        )
        
        XCTAssertNil(results["KMISSING"])
    }
}
