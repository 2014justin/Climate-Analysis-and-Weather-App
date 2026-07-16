import Foundation

/// Mirrors the abbreviated field names used by Aviation Weather.
///
/// Everything is optional so one incomplete station report does not prevent the rest
/// of the response from decoding.

private struct AviationWeatherMETARRecord: Decodable {
    let icaoId: String?
    let obsTime: TimeInterval?
    let temp: Double?
    let dewp: Double?
    let wspd: Double?
    let lat: Double?
    let lon: Double?
    let elev: Double?
    let name: String?
    let wxString: String?
    let cover: String?
}

private enum AviationWeatherMETARServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unexpectedStatusCode(Int)
    case antimeridianRequiresSplit
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not construct the Aviation Weather request."
        case .invalidResponse:
            return "Aviation Weather returned an invalid response."
        case .unexpectedStatusCode(let statusCode):
            return "Aviation Weather returned HTTP \(statusCode)."
        case .antimeridianRequiresSplit:
            return "This visible region crosses 180° longitude and must be split into two requests."
        }
    }
}

struct AviationWeatherMETARService: Sendable {
    private static let maximumCustomQueryResultCount = 400
    
    func fetchObservations(
        in bounds: AtlasMapBounds
    ) async throws -> AtlasObservationBatch {
        let url = try requestURL(for: bounds)
        
        var request = URLRequest(url: url)
        
        request.setValue(
            "WeatherAppSwiftLearningProject/v2.43",
            forHTTPHeaderField: "User-Agent"
        )
        
        let (data, response) = try await URLSession.shared.data(
            for: request
        )
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AviationWeatherMETARServiceError.invalidResponse
        }
        
        if httpResponse.statusCode == 204 {
            return AtlasObservationBatch(
                observations: [],
                rawRecordCount: 0,
                mayBeTruncated: false
            )
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AviationWeatherMETARServiceError
                .unexpectedStatusCode(httpResponse.statusCode)
        }
        
        let records = try JSONDecoder().decode(
            [AviationWeatherMETARRecord].self,
            from: data
        )
        
        let mappedObservations = records.compactMap {
            observation(from: $0)
        }
        
        var latestObservationByStation:
            [String: AtlasObservation] = [:]
        
        for observation in mappedObservations {
            if let existingObservation =
                latestObservationByStation[observation.id],
               existingObservation.observedAt
                >= observation.observedAt {
                continue
            }
            
            latestObservationByStation[observation.id] =
                observation
        }
        
        let latestObservations =
            latestObservationByStation.values.sorted {
                $0.station.source.stationID
                    < $1.station.source.stationID
            }
        
        return AtlasObservationBatch(
            observations: latestObservations,
            rawRecordCount: records.count,
            mayBeTruncated:
                records.count
            >= AviationWeatherMETARService.maximumCustomQueryResultCount
        )
    }
    
    private func requestURL(
        for bounds: AtlasMapBounds
    ) throws -> URL {
        guard bounds.crossesAntimeridian == false else {
            throw AviationWeatherMETARServiceError.antimeridianRequiresSplit
        }
        
        let boundingBox = String(
            format: "%.4f,%.4f,%.4f,%.4f",
            locale: Locale(identifier: "en_US_POSIX"),
            bounds.south,
            bounds.west,
            bounds.north,
            bounds.east
        )
        
        var components = URLComponents(
            string: "https://aviationweather.gov/api/data/metar"
        )
        
        components?.queryItems = [
            URLQueryItem(
                name: "bbox",
                value: boundingBox
            ),
            URLQueryItem(
                name: "format",
                value: "json"
            ),
            URLQueryItem(
                name: "hours",
                value: "2"
            )
        ]
        
        guard let url = components?.url else {
            throw AviationWeatherMETARServiceError.invalidURL
        }
        
        return url
    }
    
    private func observation(
        from record: AviationWeatherMETARRecord
    ) -> AtlasObservation? {
        guard let rawStationID = record.icaoId,
              let observedAt = record.obsTime,
              let temperatureCelsius = record.temp,
              let latitude = record.lat,
              let longitude = record.lon else {
            return nil
        }
        
        let stationID = rawStationID
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        
        guard stationID.isEmpty == false else {
            return nil
        }
        
        let stationName =
            cleaned(record.name)
            ?? stationID
        
        let station = AtlasStation(
            source: AtlasStationSource(
                countryCode: countryCode(
                    from: stationName
                ),
                providerID: "aviationWeather",
                stationID: stationID
            ),
            name: stationName,
            latitude: latitude,
            longitude: longitude,
            elevationMeters: record.elev,
            networkName: "METAR",
            tier: .primary,
            administrativeAreaCode: nil,
            displayPriority: nil
        )
        
        return AtlasObservation(
            station: station,
            observedAt: Date(
                timeIntervalSince1970: observedAt
            ),
            temperatureFahrenheit:
                WeatherMath.celsiusToFahrenheit(temperatureCelsius),
            dewPointFahrenheit: record.dewp.map {
                WeatherMath.celsiusToFahrenheit($0)
            },
            windSpeedMilesPerHour: record.wspd.map {
                WeatherMath.knotsToMilesPerHour($0)
            },
            conditionDescription:
                cleaned(record.wxString)
                ?? cleaned(record.cover)
        )
    }
    
    private func cleaned(
        _ value: String?
    ) -> String? {
        guard let value else {
            return nil
        }
        
        let cleanedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanedValue.isEmpty
            ? nil
            : cleanedValue
    }
    
    private func countryCode(
        from stationName: String
    ) -> String {
        guard let finalNameComponent =
                stationName.split(separator: ",").last else {
            return "XX"
        }
        
        let possibleCountryCode =
            String(finalNameComponent)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
        
        return possibleCountryCode.count == 2
            ? possibleCountryCode
            : "XX"
    }
}
