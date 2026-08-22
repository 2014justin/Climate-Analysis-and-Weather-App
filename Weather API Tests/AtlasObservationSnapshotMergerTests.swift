import XCTest
@testable import Weather_API

@MainActor
final class
AtlasObservationSnapshotMergerTests:
    XCTestCase {

    func testKeepsMETARAndAddsUniqueSupplementalStations()
        throws {

        let metarDownloadDate =
            Date(timeIntervalSince1970: 2_000)

        let supplementalDownloadDate =
            Date(timeIntervalSince1970: 1_500)

        let primarySnapshot =
            AtlasObservationSnapshot(
                observations: [
                    observation(
                        stationID: "KLAS",
                        providerID: "aviationWeather",
                        tier: .primary,
                        temperatureFahrenheit: 105
                    )
                ],
                downloadedAt: metarDownloadDate,
                rawReportCount: 1_000
            )

        let supplementalSnapshot =
            AtlasObservationSnapshot(
                observations: [
                    observation(
                        stationID: "KLAS",
                        providerID:
                            WeatherGovAPI.providerID,
                        tier: .supplemental,
                        temperatureFahrenheit: 106
                    ),
                    observation(
                        stationID: "CMP17",
                        providerID:
                            WeatherGovAPI.providerID,
                        tier: .supplemental,
                        temperatureFahrenheit: 103
                    )
                ],
                downloadedAt:
                    supplementalDownloadDate,
                rawReportCount: 2
            )

        let merged =
            AtlasObservationSnapshotMerger.merged(
                primary: primarySnapshot,
                supplemental:
                    supplementalSnapshot
            )

        XCTAssertEqual(
            merged.observations.count,
            2
        )

        XCTAssertEqual(
            merged.rawReportCount,
            1_002
        )

        XCTAssertEqual(
            merged.downloadedAt,
            supplementalDownloadDate
        )

        let lasVegas = try XCTUnwrap(
            merged.observations.first {
                $0.station.source.stationID
                    == "KLAS"
            }
        )

        XCTAssertEqual(
            lasVegas.station.source.providerID,
            "aviationWeather"
        )

        XCTAssertEqual(
            lasVegas.temperatureFahrenheit,
            105
        )

        let pahrump = try XCTUnwrap(
            merged.observations.first {
                $0.station.source.stationID
                    == "CMP17"
            }
        )

        XCTAssertEqual(
            pahrump.station.source.providerID,
            WeatherGovAPI.providerID
        )
    }

    private func observation(
        stationID: String,
        providerID: String,
        tier: AtlasStationTier,
        temperatureFahrenheit: Double
    ) -> AtlasObservation {

        AtlasObservation(
            station: AtlasStation(
                source: AtlasStationSource(
                    countryCode: "US",
                    providerID: providerID,
                    stationID: stationID
                ),
                name: stationID,
                latitude: 36.0,
                longitude: -115.0,
                elevationMeters: nil,
                networkName: nil,
                tier: tier,
                administrativeAreaCode: "NV",
                displayPriority: nil
            ),
            observedAt:
                Date(timeIntervalSince1970: 1_000),
            temperatureFahrenheit:
                temperatureFahrenheit,
            dewPointFahrenheit: nil,
            windSpeedMilesPerHour: nil,
            conditionDescription: nil
        )
    }
}
