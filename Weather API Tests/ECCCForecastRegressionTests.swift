import XCTest
@testable import Weather_API

final class ECCCForecastRegressionTests: XCTestCase {
    func testForecastParserPreservesEveryLocationInSharedForecastBlock() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <cmml>
          <head>
            <product>
              <title>FPWG13</title>
              <current-issue>2026-08-18T17:00:00Z</current-issue>
              <valid-begin-time>2026-08-18T17:00:00Z</valid-begin-time>
              <valid-end-time>2026-08-20T00:00:00Z</valid-end-time>
            </product>
          </head>
          <data>
            <forecast>
              <meteocode-forecast>
                <location>
                  <msc-zone-code>r3.20</msc-zone-code>
                  <msc-zone-name lang="en">Swift Current</msc-zone-name>
                </location>
                <location>
                  <msc-zone-code>r3.21</msc-zone-code>
                  <msc-zone-name lang="en">Leader</msc-zone-name>
                </location>
                <location>
                  <msc-zone-name lang="en">Metadata-only location</msc-zone-name>
                </location>
                <parameters>
                  <temperature-list type="air" units="celsius">
                    <temperature-value start="2026-08-18T17:00:00Z" end="2026-08-18T17:00:00Z">
                      <lower-limit>20</lower-limit>
                      <upper-limit>20</upper-limit>
                    </temperature-value>
                    <temperature-value start="2026-08-18T18:00:00Z" end="2026-08-18T18:00:00Z">
                      <lower-limit>21</lower-limit>
                      <upper-limit>21</upper-limit>
                    </temperature-value>
                  </temperature-list>
                </parameters>
              </meteocode-forecast>
            </forecast>
          </data>
        </cmml>
        """
        
        let document = try ECCCMeteocodeForecastXMLParser.document(
            from: XCTUnwrap(xml.data(using: .utf8))
        )
        
        XCTAssertEqual(
            document.regions.map(\.regionCode),
            ["r3.20", "r3.21"]
        )
        XCTAssertEqual(
            document.regions.first(where: { $0.regionCode == "r3.20" })?
                .airTemperatures.count,
            2
        )
    }
    
    func testOsoyoosShortRangeCompatibilityIsStationScoped() {
        let region = ECCCForecastRegion(
            feed: .pyr,
            identity: ECCCForecastZoneIdentity(
                englishName: "Okanagan Valley",
                frenchName: nil
            ),
            name: "Okanagan Valley",
            products: [
                ECCCMeteocodeRegionProduct(
                    bulletinCode: "FPVR52",
                    regionCode: "r8"
                )
            ]
        )
        
        let osoyoosProducts =
            ECCCForecastProductCompatibility
                .supplementalProducts(
                    for: "CWYY",
                    resolvedRegion: region
                )
        XCTAssertEqual(
            osoyoosProducts,
            [
                ECCCMeteocodeRegionProduct(
                    bulletinCode: "FPVR13",
                    regionCode: "r83"
                )
            ]
        )
        
        XCTAssertTrue(
            ECCCForecastProductCompatibility
                .supplementalProducts(
                    for: "CYYN",
                    resolvedRegion: region
                )
                .isEmpty
        )
    }
}
