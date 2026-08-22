import XCTest
@testable import Weather_API

@MainActor
final class
WeatherGovObservationStoreTests:
    XCTestCase {

    func testPahrumpViewportReusesObservationCache()
        async throws {

        let store =
            WeatherGovObservationStore()

        let pahrumpBounds =
            AtlasMapBounds(
                north: 36.40,
                south: 35.90,
                east: -115.75,
                west: -116.20
            )

        let firstRequestDate = Date()

        let firstSnapshot =
            try await store.snapshot(
                in: pahrumpBounds,
                now: firstRequestDate
            )

        XCTAssertGreaterThan(
            firstSnapshot.rawReportCount,
            0
        )

        XCTAssertTrue(
            firstSnapshot.observations.contains {
                $0.station.source.stationID
                    == "CMP17"
            }
        )

        let immediateCachedSnapshot =
            await store.cachedSnapshot(
                in: pahrumpBounds,
                now: firstRequestDate
            )

        XCTAssertEqual(
            immediateCachedSnapshot.observations,
            firstSnapshot.observations
        )

        XCTAssertEqual(
            immediateCachedSnapshot.rawReportCount,
            firstSnapshot.observations.count
        )

        // Rendering the RAM cache must not depend on a fresh
        // state/catalog/planner result. The planner is only an
        // API-request budget.
        let cachedWithoutStateCandidates =
            try await store.snapshot(
                in: pahrumpBounds,
                stateCodes: [],
                now: firstRequestDate
            )

        XCTAssertEqual(
            cachedWithoutStateCandidates.observations,
            firstSnapshot.observations
        )

        let secondRequestDate = firstRequestDate

        let secondSnapshot =
            try await store.snapshot(
                in: pahrumpBounds,
                now: secondRequestDate
            )

        XCTAssertEqual(
            secondSnapshot.rawReportCount,
            firstSnapshot.rawReportCount
        )

        XCTAssertEqual(
            secondSnapshot.observations,
            firstSnapshot.observations
        )

        XCTAssertEqual(
            secondSnapshot.downloadedAt,
            firstSnapshot.downloadedAt
        )
    }
}
