import XCTest
@testable import Weather_API

actor
CountingStateCodeResolver:
    WeatherGovStateCodeResolving {

    private var callCount = 0

    func stateCodes(
        in bounds: AtlasMapBounds
    ) async throws -> [String] {
        callCount += 1
        return ["NV"]
    }

    func recordedCallCount() -> Int {
        callCount
    }
}

@MainActor
final class
WeatherGovStateCodeStoreTests:
    XCTestCase {

    func testSmallPanReusesCoverage()
        async throws {

        let resolver =
            CountingStateCodeResolver()

        let store =
            WeatherGovStateCodeStore(
                resolver: resolver
            )

        let initialBounds =
            AtlasMapBounds(
                north: 37,
                south: 36,
                east: -115,
                west: -116
            )

        let nearbyBounds =
            AtlasMapBounds(
                north: 37.20,
                south: 36.20,
                east: -115.20,
                west: -116.20
            )

        let firstStateCodes =
            try await store.stateCodes(
                in: initialBounds
            )

        let secondStateCodes =
            try await store.stateCodes(
                in: nearbyBounds
            )

        XCTAssertEqual(
            firstStateCodes,
            ["NV"]
        )

        XCTAssertEqual(
            secondStateCodes,
            ["NV"]
        )

        let callCount =
            await resolver
                .recordedCallCount()

        XCTAssertEqual(callCount, 1)
    }

    func testDistantViewportRequiresNewLookup()
        async throws {

        let resolver =
            CountingStateCodeResolver()

        let store =
            WeatherGovStateCodeStore(
                resolver: resolver
            )

        let nevadaBounds =
            AtlasMapBounds(
                north: 37,
                south: 36,
                east: -115,
                west: -116
            )

        let distantBounds =
            AtlasMapBounds(
                north: 34,
                south: 33,
                east: -111,
                west: -112
            )

        _ = try await store.stateCodes(
            in: nevadaBounds
        )

        _ = try await store.stateCodes(
            in: distantBounds
        )

        let callCount =
            await resolver
                .recordedCallCount()

        XCTAssertEqual(callCount, 2)
    }
}
