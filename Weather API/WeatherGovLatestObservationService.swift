import Foundation

nonisolated struct WeatherGovLatestObservationResponse: Decodable, Sendable {
    let properties: WeatherGovLatestObservationProperties
}

nonisolated struct WeatherGovLatestObservationProperties: Decodable, Sendable {
    let timestamp: Date
    let textDescription: String?
    let temperature: WeatherGovObservationMeasurement?
    let dewpoint: WeatherGovObservationMeasurement?
    let windSpeed: WeatherGovObservationMeasurement?
}

nonisolated struct WeatherGovObservationMeasurement: Decodable, Sendable {
    let unitCode: String?
    let value: Double?
}

nonisolated enum WeatherGovLatestObservationFetchResult: Sendable {
    case observation(AtlasObservation)
    
    case noCurrentObservation
    
    case observationWithoutTemperature
}

nonisolated enum WeatherGovLatestObservationServiceError: LocalizedError, Sendable {
    case unsupportedProvider(String)
    case invalidStationID
    case invalidURL
    case invalidResponse
    case unexpectedStatusCode(Int)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedProvider(let providerID):
            return """
                        Cannot request a Weather.gov observation \
                        for provider \(providerID).
                        """
            
        case .invalidStationID:
            return """
                        The Weather.gov station identifier \
                        was empty.
                        """
            
        case .invalidURL:
            return """
                        Could not construct the latest \
                        Weather.gov observation URL.
                        """
            
        case .invalidResponse:
            return """
                        Weather.gov returned an invalid \
                        observation response.
                        """
            
        case .unexpectedStatusCode(let statusCode):
            return """
                        Weather.gov returned HTTP \
                        \(statusCode) for the latest observations.
                        """
        }
    }
}

nonisolated struct WeatherGovLatestObservationService: Sendable {
    func fetchLatestObservation(
        for station: AtlasStation
    ) async throws -> AtlasObservation? {
        let result =
            try await fetchLatestObservationResult(
                for: station
            )

        switch result {
        case .observation(let observation):
            return observation

        case .noCurrentObservation,
             .observationWithoutTemperature:
            return nil
        }
    }

    func fetchLatestObservationResult(
        for station: AtlasStation
    ) async throws
        -> WeatherGovLatestObservationFetchResult {

        guard station.source.providerID
                == WeatherGovAPI.providerID else {

            throw WeatherGovLatestObservationServiceError
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
            throw WeatherGovLatestObservationServiceError
                .invalidStationID
        }

        var components =
            URLComponents()

        components.scheme = "https"
        components.host = "api.weather.gov"

        components.path =
            "/stations/\(stationID)"
            + "/observations/latest"

        components.queryItems = [
            URLQueryItem(
                name: "require_qc",
                value: "true"
            )
        ]

        guard let url = components.url else {
            throw WeatherGovLatestObservationServiceError
                .invalidURL
        }

        let request =
            WeatherGovAPI.request(
                for: url
            )

        let (data, response) =
            try await WeatherGovAPI.data(
                for: request
            )

        guard let httpResponse =
                response as? HTTPURLResponse else {

            throw WeatherGovLatestObservationServiceError
                .invalidResponse
        }

        if httpResponse.statusCode == 404 {
            return .noCurrentObservation
        }

        guard httpResponse.statusCode == 200 else {
            throw WeatherGovLatestObservationServiceError
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
                WeatherGovLatestObservationResponse.self,
                from: data
            )

        guard let airTemperatureFahrenheit =
                temperatureFahrenheit(
                    from:
                        responseBody
                            .properties
                            .temperature
                ) else {

            return .observationWithoutTemperature
        }

        let observation =
            AtlasObservation(
                station: station,
                observedAt:
                    responseBody
                        .properties
                        .timestamp,
                temperatureFahrenheit:
                    airTemperatureFahrenheit,
                dewPointFahrenheit:
                    temperatureFahrenheit(
                        from:
                            responseBody
                                .properties
                                .dewpoint
                    ),
                windSpeedMilesPerHour:
                    windSpeedMilesPerHour(
                        from:
                            responseBody
                                .properties
                                .windSpeed
                    ),
                conditionDescription:
                    cleaned(
                        responseBody
                            .properties
                            .textDescription
                    )
            )

        return .observation(
            observation
        )
    }
    
    fileprivate func temperatureFahrenheit(
        from measurement: WeatherGovObservationMeasurement?
    ) -> Double? {
        guard let measurement, let value = measurement.value, value.isFinite else {
            return nil
        }
        
        switch measurement.unitCode {
        case "wmoUnit:degC":
            return WeatherMath.celsiusToFahrenheit(value)
            
        case "wmoUnit:degF":
            return value
            
        default:
            return nil
        }
    }
    
    fileprivate func windSpeedMilesPerHour(
        from measurement: WeatherGovObservationMeasurement?
    ) -> Double? {
        guard let measurement, let value = measurement.value, value.isFinite else {
            return nil
        }
        
        switch measurement.unitCode {
        case "wmoUnit:km_h-1":
            return WeatherMath
                .kilometersPerHourToMilesPerHour(value)
            
        case "wmoUnit:m_s-1":
            return value * 2.236936
            
        case "wmoUnit:kt":
            return WeatherMath.knotsToMilesPerHour(value)
            
        case "wmoUnit:mi_h-1":
            return value
            
        default:
            return nil
        }
    }
    
    fileprivate func cleaned(
        _ value: String?
    ) -> String? {
        guard let value else {
            return nil
        }
        
        let cleanedValue = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanedValue.isEmpty
            ? nil
            : cleanedValue
    }
}
