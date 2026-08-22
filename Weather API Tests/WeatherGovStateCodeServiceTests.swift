import XCTest
@testable import Weather_API

@MainActor
final class
WeatherGovStateCodeServiceTests:
    XCTestCase {

    func testResolvesPahrumpAsNevada()
        async throws {

        let stateCode =
            try await
                WeatherGovStateCodeService()
                    .fetchStateCode(
                        latitude: 36.2083,
                        longitude: -115.9839
                    )

        XCTAssertEqual(stateCode, "NV")
    }

    func testResolvesDeathValleyAsCalifornia()
        async throws {

        let stateCode =
            try await
                WeatherGovStateCodeService()
                    .fetchStateCode(
                        latitude: 36.4622,
                        longitude: -116.8636
                    )

        XCTAssertEqual(stateCode, "CA")
    }
}
