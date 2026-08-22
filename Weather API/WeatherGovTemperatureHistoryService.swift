import Foundation
/// Creates reusable weather.gov history adapter.
fileprivate nonisolated struct
WeatherGovTemperatureHistoryResponse:
    Decodable,
    Sendable {

    let features:
        [WeatherGovTemperatureHistoryFeature]

    let pagination:
        WeatherGovTemperatureHistoryPagination?
}

fileprivate nonisolated struct
WeatherGovTemperatureHistoryFeature:
    Decodable,
    Sendable {

    let properties:
        WeatherGovTemperatureHistoryProperties
}

fileprivate nonisolated struct
WeatherGovTemperatureHistoryProperties:
    Decodable,
    Sendable {

    let timestamp: Date

    let temperature:
        WeatherGovObservationMeasurement?
}

fileprivate nonisolated struct
WeatherGovTemperatureHistoryPagination:
    Decodable,
    Sendable {

    let next: URL?
}

nonisolated enum
WeatherGovTemperatureHistoryServiceError:
    LocalizedError,
    Sendable {

    case unsupportedProvider(String)
    case invalidStationID
    case invalidURL
    case invalidResponse
    case unexpectedStatusCode(Int)
    case invalidPaginationURL
    case responseMayBeTruncated

    var errorDescription: String? {
        switch self {
        case .unsupportedProvider(
            let providerID
        ):
            return """
                Cannot request Weather.gov temperature history \
                for provider \(providerID).
                """

        case .invalidStationID:
            return """
                The Weather.gov station identifier was empty.
                """

        case .invalidURL:
            return """
                Could not construct the Weather.gov \
                temperature-history URL.
                """

        case .invalidResponse:
            return """
                Weather.gov returned an invalid \
                temperature-history response.
                """

        case .unexpectedStatusCode(
            let statusCode
        ):
            return """
                Weather.gov returned HTTP \(statusCode) \
                for temperature history.
                """

        case .invalidPaginationURL:
            return """
                Weather.gov returned an invalid or unsafe \
                temperature-history pagination URL.
                """

        case .responseMayBeTruncated:
            return """
                Weather.gov temperature history exceeded the \
                service's safe pagination limit.
                """
        }
    }
}

nonisolated struct
WeatherGovTemperatureHistoryService:
    Sendable {

    static let maximumRecordsPerPage =
        500

    /// Three pages cover a full day from a station
    /// reporting once per minute.
    static let maximumPageCount =
        3

    func fetchPrevious24Hours(
        for station: AtlasStation,
        endingAt windowEnd: Date = .now
    ) async throws
        -> [AtlasTemperatureHistorySample] {

        guard station.source.providerID
                == WeatherGovAPI.providerID else {

            throw WeatherGovTemperatureHistoryServiceError
                .unsupportedProvider(
                    station.source.providerID
                )
        }

        let stationID =
            station.source.stationID
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .uppercased()

        guard stationID.isEmpty == false else {
            throw WeatherGovTemperatureHistoryServiceError
                .invalidStationID
        }

        let windowStart =
            windowEnd.addingTimeInterval(
                -AtlasTemperatureExtremaCalculator
                    .defaultWindow
            )

        guard let initialURL =
                historyURL(
                    stationID: stationID,
                    start: windowStart,
                    end: windowEnd
                ) else {

            throw WeatherGovTemperatureHistoryServiceError
                .invalidURL
        }

        var pageURL =
            initialURL

        var visitedPageURLs:
            Set<URL> = []

        var samplesByDate:
            [
                Date:
                    AtlasTemperatureHistorySample
            ] = [:]

        for pageIndex in
            0..<Self.maximumPageCount {

            guard visitedPageURLs
                    .insert(pageURL)
                    .inserted else {

                throw WeatherGovTemperatureHistoryServiceError
                    .invalidPaginationURL
            }

            let request =
                WeatherGovAPI.request(
                    for: pageURL
                )

            let (data, response) =
                try await WeatherGovAPI.data(
                    for: request
                )

            guard let httpResponse =
                    response as?
                        HTTPURLResponse else {

                throw WeatherGovTemperatureHistoryServiceError
                    .invalidResponse
            }

            guard httpResponse.statusCode
                    == 200 else {

                throw WeatherGovTemperatureHistoryServiceError
                    .unexpectedStatusCode(
                        httpResponse.statusCode
                    )
            }

            let decoder =
                JSONDecoder()

            decoder.dateDecodingStrategy =
                .iso8601

            let responseBody =
                try decoder.decode(
                    WeatherGovTemperatureHistoryResponse
                        .self,
                    from: data
                )

            var oldestTimestampOnPage:
                Date?

            for feature in
                responseBody.features {

                let properties =
                    feature.properties

                if oldestTimestampOnPage == nil
                    || properties.timestamp
                        < oldestTimestampOnPage! {

                    oldestTimestampOnPage =
                        properties.timestamp
                }

                guard properties.timestamp
                        >= windowStart,
                      properties.timestamp
                        <= windowEnd,
                      let temperatureFahrenheit =
                        temperatureFahrenheit(
                            from:
                                properties
                                    .temperature
                        ) else {
                    continue
                }

                samplesByDate[
                    properties.timestamp
                ] =
                    AtlasTemperatureHistorySample(
                        stationID:
                            station.id,
                        observedAt:
                            properties.timestamp,
                        temperatureFahrenheit:
                            temperatureFahrenheit
                    )
            }

            let reachedWindowStart =
                oldestTimestampOnPage
                    .map {
                        $0 <= windowStart
                    }
                ?? true

            guard reachedWindowStart
                    == false,
                  let nextURL =
                    responseBody
                        .pagination?
                        .next else {

                return sortedSamples(
                    from: samplesByDate
                )
            }

            guard pageIndex + 1
                    < Self.maximumPageCount else {

                throw WeatherGovTemperatureHistoryServiceError
                    .responseMayBeTruncated
            }

            guard nextURL.scheme == "https",
                  nextURL.host
                    == "api.weather.gov" else {

                throw WeatherGovTemperatureHistoryServiceError
                    .invalidPaginationURL
            }

            pageURL =
                nextURL
        }

        throw WeatherGovTemperatureHistoryServiceError
            .responseMayBeTruncated
    }

    private func historyURL(
        stationID: String,
        start: Date,
        end: Date
    ) -> URL? {
        var components =
            URLComponents()

        components.scheme = "https"
        components.host =
            "api.weather.gov"

        components.path =
            "/stations/\(stationID)"
            + "/observations"

        let formatter =
            ISO8601DateFormatter()

        formatter.formatOptions = [
            .withInternetDateTime
        ]

        components.queryItems = [
            URLQueryItem(
                name: "start",
                value:
                    formatter.string(
                        from: start
                    )
            ),
            URLQueryItem(
                name: "end",
                value:
                    formatter.string(
                        from: end
                    )
            ),
            URLQueryItem(
                name: "limit",
                value:
                    String(
                        Self.maximumRecordsPerPage
                    )
            )
        ]

        return components.url
    }

    private func temperatureFahrenheit(
        from measurement:
            WeatherGovObservationMeasurement?
    ) -> Double? {
        guard let measurement,
              let value =
                measurement.value,
              value.isFinite else {

            return nil
        }

        switch measurement.unitCode {
        case "wmoUnit:degC":
            return WeatherMath
                .celsiusToFahrenheit(
                    value
                )

        case "wmoUnit:degF":
            return value

        default:
            return nil
        }
    }

    private func sortedSamples(
        from samplesByDate:
            [
                Date:
                    AtlasTemperatureHistorySample
            ]
    ) -> [AtlasTemperatureHistorySample] {

        samplesByDate
            .values
            .sorted {
                $0.observedAt
                    < $1.observedAt
            }
    }
}
