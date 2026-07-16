/// The METAR snapshot knows locations and observations but not good station names or state/rpvince information

import Foundation

enum AviationWeatherSnapshotServiceError:
    LocalizedError,
    Sendable {

    case invalidURL
    case invalidResponse
    case unexpectedStatusCode(Int)
    case invalidCSV
    case noUsableObservations

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return """
                Could not construct the worldwide \
                METAR snapshot URL.
                """

        case .invalidResponse:
            return """
                Aviation Weather returned an invalid \
                snapshot response.
                """

        case .unexpectedStatusCode(let statusCode):
            return """
                Aviation Weather returned HTTP \
                \(statusCode) for the snapshot.
                """

        case .invalidCSV:
            return """
                The worldwide METAR snapshot was not \
                valid UTF-8 CSV.
                """

        case .noUsableObservations:
            return """
                The worldwide METAR snapshot contained \
                no usable observations.
                """
        }
    }
}

struct AviationWeatherSnapshotService: Sendable {
    func fetchSnapshot(
        using stationCatalog:
            AviationWeatherStationCatalog
    ) async throws -> AtlasObservationSnapshot {
        
        guard let url = URL(
            string: """
                https://aviationweather.gov/data/cache/metars.cache.csv.gz
                """
        ) else {
            throw AviationWeatherSnapshotServiceError
                .invalidURL
        }

        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 30
        )

        request.setValue(
            "WeatherAppSwiftLearningProject/v2.43",
            forHTTPHeaderField: "User-Agent"
        )

        let (compressedData, response) =
            try await URLSession.shared.data(
                for: request
            )

        guard let httpResponse =
                response as? HTTPURLResponse else {
            throw AviationWeatherSnapshotServiceError
                .invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw AviationWeatherSnapshotServiceError
                .unexpectedStatusCode(
                    httpResponse.statusCode
                )
        }

        let csvData = try GzipDecompressor()
            .decompress(compressedData)

        guard let csvText = String(
            data: csvData,
            encoding: .utf8
        ) else {
            throw AviationWeatherSnapshotServiceError
                .invalidCSV
        }

        let rows = csvText.split(
            whereSeparator: {
                $0.isNewline
            }
        )

        guard rows.first?
            .contains("station_id") == true else {
            throw AviationWeatherSnapshotServiceError
                .invalidCSV
        }

        var latestRecordByStation:
            [String: AviationWeatherBulkMETARRecord] = [:]

        for row in rows.dropFirst() {
            guard let record =
                    AviationWeatherBulkMETARRecord(
                        csvRow: row
                    ) else {
                continue
            }

            if let existingRecord =
                    latestRecordByStation[
                        record.stationID
                    ],
               existingRecord.observedAt
                    >= record.observedAt {
                continue
            }

            latestRecordByStation[
                record.stationID
            ] = record
        }

        guard !latestRecordByStation.isEmpty else {
            throw AviationWeatherSnapshotServiceError
                .noUsableObservations
        }

        let observations =
            latestRecordByStation.values
                .map { record in
                    observation(
                        from: record,
                        metadata:
                            stationCatalog[
                                record.stationID
                            ]
                    )
                }
                .sorted {
                    $0.station.source.stationID
                        < $1.station.source.stationID
                }

        return AtlasObservationSnapshot(
            observations: observations,
            downloadedAt: Date(),
            rawReportCount:
                max(0, rows.count - 1)
        )
    }

    private func observation(
        from record:
            AviationWeatherBulkMETARRecord,
        metadata:
            AviationWeatherStationMetadata?
    ) -> AtlasObservation {
        let station = AtlasStation(
            source: AtlasStationSource(
                countryCode:
                    metadata?.countryCode ?? "XX",
                providerID: "aviationWeather",
                stationID: record.stationID
            ),
            name:
                metadata?.displayName
                ?? record.stationID,
            latitude: record.latitude,
            longitude: record.longitude,
            elevationMeters:
                record.elevationMeters
                ?? metadata?.elevationMeters,
            networkName: "METAR",
            tier: .primary,
            administrativeAreaCode:
                metadata?.stateOrProvinceCode,
            displayPriority:
                metadata?.priority
        )

        return AtlasObservation(
            station: station,
            observedAt: record.observedAt,
            temperatureFahrenheit:
                WeatherMath.celsiusToFahrenheit(
                    record.temperatureCelsius
                ),
            dewPointFahrenheit:
                record.dewPointCelsius.map {
                    WeatherMath
                        .celsiusToFahrenheit($0)
                },
            windSpeedMilesPerHour:
                record.windSpeedKnots.map {
                    WeatherMath
                        .knotsToMilesPerHour($0)
                },
            conditionDescription:
                record.conditionDescription
        )
    }
}
