import XCTest
@testable import Weather_API

@MainActor
final class
AtlasObservationDensityReducerTests:
    XCTestCase {

    private let reducer =
        AtlasObservationDensityReducer()

    private let referenceDate =
        Date(
            timeIntervalSince1970:
                2_000_000_000
        )

    func testSparseViewportRetainsEveryStation() {
        let bounds =
            AtlasMapBounds(
                north: 40,
                south: 33,
                east: -111,
                west: -118
            )

        let observations =
            gridObservations(
                rows: 3,
                columns: 3,
                south: 34,
                north: 39,
                west: -117,
                east: -112
            )

        let result =
            reduced(
                observations,
                in: bounds,
                annotationSize:
                    .mediumPlus
            )

        XCTAssertEqual(
            Set(result.map(\.id)),
            Set(observations.map(\.id))
        )
    }

    func testDenseSevenDegreeViewportHonorsCapacity() {
        let bounds =
            AtlasMapBounds(
                north: 40,
                south: 33,
                east: -111,
                west: -118
            )

        let observations =
            gridObservations(
                rows: 40,
                columns: 40,
                south: 33.05,
                north: 39.95,
                west: -117.95,
                east: -111.05
            )

        let result =
            reduced(
                observations,
                in: bounds,
                annotationSize:
                    .mediumPlus
            )

        XCTAssertLessThanOrEqual(
            result.count,
            13 * 9
        )

        XCTAssertGreaterThan(
            result.count,
            50
        )
    }

    func testCloserZoomRevealsMoreOfSameCluster() {
        let observations =
            gridObservations(
                rows: 15,
                columns: 15,
                south: 36.10,
                north: 36.90,
                west: -115.90,
                east: -115.10
            )

        let regionalBounds =
            AtlasMapBounds(
                north: 40,
                south: 33,
                east: -112,
                west: -119
            )

        let urbanBounds =
            AtlasMapBounds(
                north: 37,
                south: 36,
                east: -115,
                west: -116
            )

        let regionalResult =
            reduced(
                observations,
                in: regionalBounds,
                annotationSize:
                    .mediumPlus
            )

        let urbanResult =
            reduced(
                observations,
                in: urbanBounds,
                annotationSize:
                    .mediumPlus
            )

        XCTAssertGreaterThan(
            urbanResult.count,
            regionalResult.count
        )
    }

    func testDewPointAvailabilityWinsCollision() {
        let bounds =
            AtlasMapBounds(
                north: 37,
                south: 36,
                east: -115,
                west: -116
            )

        let newerWithoutDewPoint =
            makeObservation(
                stationID: "NO_DEW",
                latitude: 36.50,
                longitude: -115.50,
                dewPointFahrenheit: nil,
                observedAt:
                    referenceDate
            )

        let olderWithDewPoint =
            makeObservation(
                stationID: "WITH_DEW",
                latitude: 36.5001,
                longitude: -115.5001,
                dewPointFahrenheit: 45,
                observedAt:
                    referenceDate
                        .addingTimeInterval(-300)
            )

        let snapshot =
            makeSnapshot(
                [
                    newerWithoutDewPoint,
                    olderWithDewPoint
                ]
            )

        let result =
            reducer.observations(
                from: snapshot,
                in: bounds,
                scope: .allNetworks,
                displayedMetric: .dewPoint,
                annotationSize: .mediumPlus,
                allowedCountryCodes: nil
            )

        XCTAssertEqual(result.count, 1)

        XCTAssertEqual(
            result.first?
                .station
                .source
                .stationID,
            "WITH_DEW"
        )
    }

    func testLargerAnnotationsNeverIncreaseCount() {
        let bounds =
            AtlasMapBounds(
                north: 40,
                south: 33,
                east: -111,
                west: -118
            )

        let observations =
            gridObservations(
                rows: 40,
                columns: 40,
                south: 33.05,
                north: 39.95,
                west: -117.95,
                east: -111.05
            )

        let medium =
            reduced(
                observations,
                in: bounds,
                annotationSize: .medium
            )

        let mediumPlus =
            reduced(
                observations,
                in: bounds,
                annotationSize:
                    .mediumPlus
            )

        let large =
            reduced(
                observations,
                in: bounds,
                annotationSize: .large
            )

        XCTAssertGreaterThanOrEqual(
            medium.count,
            mediumPlus.count
        )

        XCTAssertGreaterThanOrEqual(
            mediumPlus.count,
            large.count
        )
    }
    
    func testPrimaryScopeUsesMoreAggressiveDensity() {
        let bounds =
            AtlasMapBounds(
                north: 40,
                south: 33,
                east: -111,
                west: -118
            )

        let observations =
            gridObservations(
                rows: 40,
                columns: 40,
                south: 33.05,
                north: 39.95,
                west: -117.95,
                east: -111.05
            )

        let snapshot =
            makeSnapshot(observations)

        let primaryResult =
            reducer.observations(
                from: snapshot,
                in: bounds,
                scope: .primary,
                displayedMetric:
                    .temperature,
                annotationSize:
                    .mediumPlus,
                allowedCountryCodes: nil
            )

        let allNetworksResult =
            reducer.observations(
                from: snapshot,
                in: bounds,
                scope: .allNetworks,
                displayedMetric:
                    .temperature,
                annotationSize:
                    .mediumPlus,
                allowedCountryCodes: nil
            )

        XCTAssertGreaterThan(
            primaryResult.count,
            allNetworksResult.count
        )
    }
    
    func testRegionalPrimaryViewRetainsLasVegasAirports() {
        let bounds =
            AtlasMapBounds(
                north: 37.21,
                south: 34.67,
                east: -111.99,
                west: -117.37
            )

        let observations = [
            makeObservation(
                stationID: "KLAS",
                latitude: 36.0801,
                longitude: -115.1522,
                dewPointFahrenheit: 45,
                observedAt: referenceDate
            ),
            makeObservation(
                stationID: "KVGT",
                latitude: 36.2107,
                longitude: -115.1944,
                dewPointFahrenheit: 45,
                observedAt: referenceDate
            ),
            makeObservation(
                stationID: "KLSV",
                latitude: 36.2362,
                longitude: -115.0343,
                dewPointFahrenheit: 45,
                observedAt: referenceDate
            ),
            makeObservation(
                stationID: "KBVU",
                latitude: 35.9475,
                longitude: -114.8611,
                dewPointFahrenheit: 45,
                observedAt: referenceDate
            )
        ]

        let result =
            reducer.observations(
                from:
                    makeSnapshot(observations),
                in: bounds,
                scope: .primary,
                displayedMetric:
                    .temperature,
                annotationSize:
                    .mediumPlus,
                allowedCountryCodes: nil
            )

        XCTAssertEqual(
            Set(
                result.map {
                    $0.station.source.stationID
                }
            ),
            Set([
                "KLAS",
                "KVGT",
                "KLSV",
                "KBVU"
            ])
        )
    }
    
    func testAllNetworksAllowsDenserPrimaryStations() {
        let bounds =
            AtlasMapBounds(
                north: 1,
                south: 0,
                east: 1,
                west: 0
            )

        let observations = [
            makeObservation(
                stationID: "PRIMARY_ONE",
                latitude: 0.5,
                longitude: 0.45,
                dewPointFahrenheit: 45,
                observedAt: referenceDate,
                tier: .primary
            ),
            makeObservation(
                stationID: "PRIMARY_TWO",
                latitude: 0.5,
                longitude: 0.51,
                dewPointFahrenheit: 45,
                observedAt: referenceDate,
                tier: .primary
            )
        ]

        let result =
            reducer.observations(
                from:
                    makeSnapshot(observations),
                in: bounds,
                scope: .allNetworks,
                displayedMetric:
                    .temperature,
                annotationSize:
                    .mediumPlus,
                allowedCountryCodes: nil
            )

        XCTAssertEqual(
            Set(
                result.map {
                    $0.station.source.stationID
                }
            ),
            Set([
                "PRIMARY_ONE",
                "PRIMARY_TWO"
            ])
        )
    }
    
    func testMaximumDensityReturnsEveryLoadedStation() {
        let bounds =
            AtlasMapBounds(
                north: 40,
                south: 33,
                east: -111,
                west: -118
            )

        let observations =
            gridObservations(
                rows: 20,
                columns: 20,
                south: 33.05,
                north: 39.95,
                west: -117.95,
                east: -111.05
            )

        let result =
            reducer.observations(
                from:
                    makeSnapshot(observations),
                in: bounds,
                scope: .allNetworks,
                displayedMetric:
                    .temperature,
                annotationSize:
                    .mediumPlus,
                showsMaximumDensity: true,
                allowedCountryCodes: nil
            )

        XCTAssertEqual(
            result.count,
            observations.count
        )
    }

    private func reduced(
        _ observations: [AtlasObservation],
        in bounds: AtlasMapBounds,
        annotationSize: AtlasAnnotationSize
    ) -> [AtlasObservation] {

        reducer.observations(
            from:
                makeSnapshot(observations),
            in: bounds,
            scope: .allNetworks,
            displayedMetric: .temperature,
            annotationSize: annotationSize,
            allowedCountryCodes: nil
        )
    }

    private func makeSnapshot(
        _ observations: [AtlasObservation]
    ) -> AtlasObservationSnapshot {

        AtlasObservationSnapshot(
            observations: observations,
            downloadedAt: referenceDate,
            rawReportCount:
                observations.count
        )
    }

    private func gridObservations(
        rows: Int,
        columns: Int,
        south: Double,
        north: Double,
        west: Double,
        east: Double
    ) -> [AtlasObservation] {

        var observations:
            [AtlasObservation] = []

        for row in 0..<rows {
            let verticalFraction =
                rows == 1
                    ? 0.5
                    : Double(row)
                        / Double(rows - 1)

            let latitude =
                south
                + (
                    north - south
                )
                * verticalFraction

            for column in 0..<columns {
                let horizontalFraction =
                    columns == 1
                        ? 0.5
                        : Double(column)
                            / Double(columns - 1)

                let longitude =
                    west
                    + (
                        east - west
                    )
                    * horizontalFraction

                let stationNumber =
                    row * columns
                    + column

                observations.append(
                    makeObservation(
                        stationID:
                            String(
                                format:
                                    "S%04d",
                                stationNumber
                            ),
                        latitude: latitude,
                        longitude: longitude,
                        dewPointFahrenheit: 45,
                        observedAt:
                            referenceDate
                    )
                )
            }
        }

        return observations
    }

    private func makeObservation(
        stationID: String,
        latitude: Double,
        longitude: Double,
        dewPointFahrenheit: Double?,
        observedAt: Date,
        tier: AtlasStationTier =
            .supplemental
    ) -> AtlasObservation {

        AtlasObservation(
            station:
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
                    tier: tier,
                    administrativeAreaCode:
                        "NV",
                    displayPriority: nil
                ),
            observedAt: observedAt,
            temperatureFahrenheit: 100,
            dewPointFahrenheit:
                dewPointFahrenheit,
            windSpeedMilesPerHour: 5,
            conditionDescription: "Clear"
        )
    }
}
