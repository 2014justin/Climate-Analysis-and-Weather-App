import Foundation

fileprivate nonisolated struct AviationWeatherTemperatureHistoryRecord: Decodable {
    let icaoId: String?
    let obsTime: TimeInterval?
    let temp: Double?
}

nonisolated enum AviationWeatherTemperatureHistoryServiceError: LocalizedError, Sendable {
    
    case noStationIDs
    case tooManyStationIDs(maximum: Int)
    case invalidURL
    case invalidResponse
    case unexpectedStatusCode(Int)
    case responseMayBeTruncated
    
    var errorDescription: String? {
        switch self {
        case .noStationIDs:
            return """
                No station identifiers were supplied for \
                temperature-history seeding.
                """
            
        case .tooManyStationIDs(let maximum):
            return """
                Temperature-history requests support at most \
                \(maximum) stations per batch
                """
            
        case .invalidURL:
            return """
                Could not construct the Aviation Weather \
                temperature-history request.
                """
            
        case .invalidResponse:
            return """
                Aviation Weather returned an invalid \
                temperature-history response.
                """
            
        case .unexpectedStatusCode(let statusCode):
            return """
                Aviation Weather returned HTTP \(statusCode) \
                for temperature history.
                """
            
        case .responseMayBeTruncated:
            return """
                Aviation Weather has reached its 400-report limit. \
                This station batch must be retried in smaller  groups.
                """
        }
    }
}

nonisolated struct AviationWeatherTemperatureHistoryService: Sendable {
    
    /// Five stations normally remain comfortably below Aviation Weather's 400-report response cap, even when
    /// SPECI reports occur.
    static let maximumStationCount = 5
    
    func fetchPrevious24Hours(
        for rawStationIDs: [String]
    ) async throws -> [AtlasTemperatureHistorySample] {
        let stationIDs = Array(
            Set(
                rawStationIDs.compactMap { rawStationID in
                    let stationID = rawStationID
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .uppercased()
                    
                    return stationID.isEmpty
                    ? nil
                    : stationID
                }
            )
        )
            .sorted()
        
        guard stationIDs.isEmpty == false else {
            throw AviationWeatherTemperatureHistoryServiceError
                .noStationIDs
        }
        
        guard stationIDs.count <= Self.maximumStationCount else {
            throw AviationWeatherTemperatureHistoryServiceError
                .tooManyStationIDs(maximum: Self.maximumStationCount)
        }
        
        var components = URLComponents(
            string: "https://aviationweather.gov/api/data/metar"
        )
        
        components?.queryItems = [
            URLQueryItem(name: "ids", value: stationIDs.joined(separator: ",")),
            
            URLQueryItem(name: "format", value: "json"),
            
            URLQueryItem(name: "hours", value: "24")
        ]
        
        guard let url = components?.url else {
            throw AviationWeatherTemperatureHistoryServiceError
                .invalidURL
        }
        
        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 30
        )
        
        request.setValue(
            "WeatherAndClimateAtlasSwiftApp v2.43 (https://github.com/2014justin/Climate-Analysis-and-Weather-App)",
            forHTTPHeaderField: "User-Agent"
        )
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AviationWeatherTemperatureHistoryServiceError
                .invalidResponse
        }
        
        if httpResponse.statusCode == 204 {
            return []
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AviationWeatherTemperatureHistoryServiceError
                .unexpectedStatusCode(httpResponse.statusCode)
        }
        
        return try Self.decodeSamples(
            from: data,
            requestedStationIDs: Set(stationIDs)
        )
    }
    
    static func decodeSamples(
        from data: Data,
        requestedStationIDs: Set<String>
    ) throws -> [AtlasTemperatureHistorySample] {
        let records = try JSONDecoder().decode(
            [AviationWeatherTemperatureHistoryRecord].self,
            from: data
        )
        
        guard records.count < 400 else {
            throw AviationWeatherTemperatureHistoryServiceError
                .responseMayBeTruncated
        }
        
        return records.compactMap { record in
            guard let rawStationID = record.icaoId,
                  let observedAt = record.obsTime,
                  let temperatureCelsius = record.temp else {
                return nil
            }
            
            let stationID = rawStationID
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .uppercased()
            
            guard requestedStationIDs.contains(stationID),
                  observedAt.isFinite,
                  temperatureCelsius.isFinite else {
                return nil
            }
            
            return AtlasTemperatureHistorySample(
                stationID: stationID,
                observedAt: Date(
                    timeIntervalSince1970: observedAt
                ),
                temperatureFahrenheit:
                    WeatherMath.celsiusToFahrenheit(
                        temperatureCelsius
                    )
            )
        }
        .sorted {
            if $0.stationID != $1.stationID {
                return $0.stationID < $1.stationID
            }
            
            return $0.observedAt < $1.observedAt
        }
    }
}

