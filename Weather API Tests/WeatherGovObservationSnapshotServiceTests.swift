import XCTest
@testable import Weather_API

@MainActor
final class
WeatherGovObservationSnapshotServiceTests:
    XCTestCase {

    func testFetchesPahrumpAndDeathValleyBatch()
        async {

        let requestedStations = [
            station(
                id: "CMP17",
                name: "Pahrump",
                latitude: 36.22111,
                longitude: -115.99528,
                stateCode: "NV"
            ),
            station(
                id: "DEVC1",
                name: "Furnace Creek",
                latitude: 36.46222,
                longitude: -116.86361,
                stateCode: "CA"
            ),
            station(
                id: "BWBC1",
                name: "Badwater Basin",
                latitude: 36.22944,
                longitude: -116.76694,
                stateCode: "CA"
            ),
            station(
                id: "ISWC1",
                name: "Stovepipe Wells",
                latitude: 36.604,
                longitude: -117.144,
                stateCode: "CA"
            )
        ]

        let snapshot =
            await WeatherGovObservationSnapshotService()
                .fetchSnapshot(
                    for: requestedStations,
                    maximumObservationAge:
                        3 * 60 * 60,
                    concurrentRequestLimit: 2
                )

        XCTAssertEqual(
            snapshot.rawReportCount,
            requestedStations.count
        )

        XCTAssertGreaterThanOrEqual(
            snapshot.observations.count,
            3
        )

        let expectedStationIDs: Set<String> = [
            "CMP17",
            "DEVC1",
            "BWBC1",
            "ISWC1"
        ]

        let returnedStationIDs = Set(
            snapshot.observations.map {
                $0.station.source.stationID
            }
        )

        XCTAssertTrue(
            returnedStationIDs.isSubset(
                of: expectedStationIDs
            )
        )

        XCTAssertEqual(
            returnedStationIDs.count,
            snapshot.observations.count
        )

        for observation in snapshot.observations {
            XCTAssertEqual(
                observation.station.source.providerID,
                WeatherGovAPI.providerID
            )

            XCTAssertTrue(
                (-50...150).contains(
                    observation.temperatureFahrenheit
                )
            )
        }
    }

    private func station(
        id: String,
        name: String,
        latitude: Double,
        longitude: Double,
        stateCode: String
    ) -> AtlasStation {

        AtlasStation(
            source: AtlasStationSource(
                countryCode: "US",
                providerID:
                    WeatherGovAPI.providerID,
                stationID: id
            ),
            name: name,
            latitude: latitude,
            longitude: longitude,
            elevationMeters: nil,
            networkName: nil,
            tier: .supplemental,
            administrativeAreaCode: stateCode,
            displayPriority: nil
        )
    }
}
