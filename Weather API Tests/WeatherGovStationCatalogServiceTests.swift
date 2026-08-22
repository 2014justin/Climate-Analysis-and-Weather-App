import XCTest
@testable import Weather_API
@MainActor
final class
WeatherGovStationCatalogServiceTests: XCTestCase {
    func testFetchesNevadaCatalogAndFindsPahrump()
        async throws {
        
            let stations = try await WeatherGovStationCatalogService()
                .fetchStations(inState: "NV")
            
            XCTAssertGreaterThan(
                stations.count, 100
            )
            
            let pahrumpStation = try XCTUnwrap(
                stations.first {
                    $0.source.stationID == "CMP17"
                }
            )
            
            XCTAssertEqual(pahrumpStation.source.countryCode, "US")
            
            XCTAssertEqual(pahrumpStation.source.providerID, "weatherGov")
            
            XCTAssertEqual(
                pahrumpStation.tier,
                .supplemental
            )
            
            XCTAssertEqual(
                pahrumpStation.administrativeAreaCode,
                "NV"
            )
            
            XCTAssertTrue(
                pahrumpStation.networkName?
                    .contains("CEMP") == true
            )
            
            XCTAssertEqual(
                pahrumpStation.latitude,
                36.22111,
                accuracy: 0.01
            )
            
            XCTAssertEqual(
                pahrumpStation.longitude,
                -115.99528,
                accuracy: 0.01
            )
        }
}
