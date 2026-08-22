import XCTest
@testable import Weather_API

@MainActor
final class
WeatherGovStationRequestPlannerTests:
    XCTestCase {

    private let bounds =
        AtlasMapBounds(
            north: 40,
            south: 33,
            east: -111,
            west: -118
        )

    func testSparseCatalogKeepsEveryStation() {
        let stations =
            gridStations(
                rows: 4,
                columns: 5,
                prefix: "SPARSE"
            )

        let result =
            WeatherGovStationRequestPlanner()
                .stations(
                    from: stations,
                    in: bounds
                )

        XCTAssertEqual(
            result.map(\.id),
            stations.sorted {
                $0.id < $1.id
            }
            .map(\.id)
        )
    }

    func testDenseCatalogHonorsRequestLimit() {
        let stations =
            gridStations(
                rows: 40,
                columns: 40,
                prefix: "DENSE"
            )

        let result =
            WeatherGovStationRequestPlanner()
                .stations(
                    from: stations,
                    in: bounds
                )

        XCTAssertEqual(
            result.count,
            WeatherGovStationRequestPlanner
                .defaultMaximumStationCount
        )
    }

    func testPlanningIsDeterministic() {
        let stations =
            gridStations(
                rows: 30,
                columns: 30,
                prefix: "STABLE"
            )

        let planner =
            WeatherGovStationRequestPlanner()

        let firstResult =
            planner.stations(
                from: stations,
                in: bounds
            )

        let secondResult =
            planner.stations(
                from:
                    Array(stations.reversed()),
                in: bounds
            )

        XCTAssertEqual(
            firstResult.map(\.id),
            secondResult.map(\.id)
        )
    }

    private func gridStations(
        rows: Int,
        columns: Int,
        prefix: String
    ) -> [AtlasStation] {

        var stations:
            [AtlasStation] = []

        for row in 0..<rows {
            let verticalFraction =
                (
                    Double(row) + 0.5
                )
                / Double(rows)

            let latitude =
                bounds.south
                + bounds.latitudeSpan
                * verticalFraction

            for column in 0..<columns {
                let horizontalFraction =
                    (
                        Double(column) + 0.5
                    )
                    / Double(columns)

                let longitude =
                    bounds.west
                    + bounds.longitudeSpan
                    * horizontalFraction

                let stationNumber =
                    row * columns
                    + column

                let stationID =
                    String(
                        format:
                            "\(prefix)_%04d",
                        stationNumber
                    )

                stations.append(
                    AtlasStation(
                        source:
                            AtlasStationSource(
                                countryCode: "US",
                                providerID:
                                    WeatherGovAPI
                                        .providerID,
                                stationID:
                                    stationID
                            ),
                        name: stationID,
                        latitude: latitude,
                        longitude: longitude,
                        elevationMeters: nil,
                        networkName:
                            "Test Network",
                        tier: .supplemental,
                        administrativeAreaCode:
                            "NV",
                        displayPriority: nil
                    )
                )
            }
        }

        return stations
    }
}
