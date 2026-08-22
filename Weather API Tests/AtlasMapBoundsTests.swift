import XCTest
@testable import Weather_API

@MainActor
final class AtlasMapBoundsTests:
    XCTestCase {

    func testSevenDegreePaddingIsCapped() {
        let bounds =
            AtlasMapBounds(
                north: 40,
                south: 33,
                east: -111,
                west: -118
            )

        let padded =
            bounds.padded(
                by: 0.15,
                maximumDegreesPerEdge:
                    0.35
            )

        XCTAssertEqual(
            padded.north,
            40.35,
            accuracy: 0.000_001
        )

        XCTAssertEqual(
            padded.south,
            32.65,
            accuracy: 0.000_001
        )

        XCTAssertEqual(
            padded.east,
            -110.65,
            accuracy: 0.000_001
        )

        XCTAssertEqual(
            padded.west,
            -118.35,
            accuracy: 0.000_001
        )

        XCTAssertEqual(
            padded.latitudeSpan,
            7.70,
            accuracy: 0.000_001
        )

        XCTAssertEqual(
            padded.longitudeSpan,
            7.70,
            accuracy: 0.000_001
        )
    }

    func testSmallViewportStillUsesFractionalPadding() {
        let bounds =
            AtlasMapBounds(
                north: 37,
                south: 36,
                east: -115,
                west: -116
            )

        let padded =
            bounds.padded(
                by: 0.15,
                maximumDegreesPerEdge:
                    0.35
            )

        XCTAssertEqual(
            padded.latitudeSpan,
            1.30,
            accuracy: 0.000_001
        )

        XCTAssertEqual(
            padded.longitudeSpan,
            1.30,
            accuracy: 0.000_001
        )
    }
}
