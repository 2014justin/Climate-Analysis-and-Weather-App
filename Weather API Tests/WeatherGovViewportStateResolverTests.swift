import XCTest
@testable import Weather_API

@MainActor
final class
WeatherGovViewportStateResolverTests:
    XCTestCase {

    func testFindsCaliforniaAndNevadaInViewport()
        async throws {

        let crossBorderBounds =
            AtlasMapBounds(
                north: 36.80,
                south: 36.10,
                east: -115.50,
                west: -117.20
            )

        let stateCodes =
            try await
                WeatherGovViewportStateResolver()
                    .stateCodes(
                        in: crossBorderBounds
                    )

        XCTAssertEqual(
            stateCodes,
            ["CA", "NV"]
        )
    }
}
