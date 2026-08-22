import Foundation

nonisolated struct WeatherGovStationCatalogResponse: Decodable {
    let features: [WeatherGovStationFeature]
    let pagination: NWSPagination?
}

nonisolated struct WeatherGovStationFeature: Decodable {
    let geometry: NWSStationGeometry
    let properties: WeatherGovStationProperties
}

nonisolated struct WeatherGovStationProperties: Decodable {
    let stationIdentifier: String?
    let name: String?
    let elevation: NWSMeasurement?
    let provider: String?
    let subProvider: String?
}

nonisolated enum WeatherGovStationCatalogServiceError: LocalizedError, Sendable {
    case invalidStateCode
    case invalidURL
    case invalidResponse
    case unexpectedStatusCode(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidStateCode:
            return """
                Weather.gov station searches require \
                a two-letter state code.
                """
        case .invalidURL:
            return """
                Could not construct the Weather.gov
                station catalog URL.
                """
        case .invalidResponse:
            return """
                Weather.gov returned an invalid \
                station catalog response.
                """
        case .unexpectedStatusCode(let statusCode):
            return """
                Weather.gov returned HTTP \
                \(statusCode) for the station catalog.
                """
        }
    }
}

nonisolated struct WeatherGovStationCatalogService: Sendable {
    
    
    func fetchStations(
        inState rawStateCode: String
    ) async throws -> [AtlasStation] {
        let stateCode = rawStateCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        
        guard stateCode.range(
            of: #"^[A-Z]{2}$"#, /// must be a two character state code like CA or NV or CO
            options: .regularExpression
        ) != nil else {
            throw WeatherGovStationCatalogServiceError
                .invalidStateCode
        }
        
        var components = URLComponents(string: "https://api.weather.gov/stations")
        
        components?.queryItems = [
            URLQueryItem(name: "state", value: stateCode),
            URLQueryItem(name: "limit", value: "500")
        ]
        
        guard var nextURL = components?.url else {
            throw WeatherGovStationCatalogServiceError
                .invalidURL
        }
        
        var stationsByID: [String: AtlasStation] = [:]
        var visitedPageURLs: Set<URL> = []
        
        
        while visitedPageURLs.insert(nextURL).inserted {
            let request = WeatherGovAPI.request(
                for: nextURL,
                includeStationProviderMetadata: true
            )
            
            let (data, response) =
                try await WeatherGovAPI.data(
                    for: request
                )
            
            guard let httpResponse =
                    response as? HTTPURLResponse else {
                throw WeatherGovStationCatalogServiceError
                    .invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw WeatherGovStationCatalogServiceError
                    .unexpectedStatusCode(httpResponse.statusCode)
            }
            
            let page = try JSONDecoder().decode(
                WeatherGovStationCatalogResponse.self,
                from: data
            )
            
            for feature in page.features {
                guard let station = feature.atlasStation(
                    stateCode: stateCode
                ) else {
                    continue
                }
                
                stationsByID[station.id] = station
            }
            
            guard page.features.count == 500,
                  let followingURL =
                    page.pagination?.next else {
                break
            }
            
            nextURL = followingURL
        }
        
        return stationsByID.values.sorted {
            $0.source.stationID < $1.source.stationID
        }
    }
}

fileprivate extension WeatherGovStationFeature {
    func atlasStation(
        stateCode: String
    ) -> AtlasStation? {
        guard geometry.coordinates.count >= 2 else {
            return nil
        }
        
        let longitude = geometry.coordinates[0]
        let latitude = geometry.coordinates[1]
        
        guard longitude.isFinite, latitude.isFinite,
              (-180...180).contains(longitude), (-90...90).contains(latitude),
              let stationID = cleaned(
                properties.stationIdentifier
              )?.uppercased() else {
            return nil
        }
        
        let provider = cleaned(properties.provider)
        
        let subProvider = cleaned(properties.subProvider)
        
        let networkComponents = [
            provider,
            subProvider
        ]
            .compactMap { $0 }
        
        let networkName =
            networkComponents.isEmpty
            ? nil
            : networkComponents.joined(separator: " / ")
        
        return AtlasStation(
            source: AtlasStationSource(
                countryCode: "US",
                providerID: WeatherGovAPI.providerID,
                stationID: stationID
            ),
            name:
                cleaned(properties.name) ?? stationID,
            latitude: latitude,
            longitude: longitude,
            elevationMeters: elevationMeters(from: properties.elevation),
            networkName: networkName,
            tier: .supplemental,
            administrativeAreaCode: stateCode,
            displayPriority: nil
        )
    }
    
    func cleaned(
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
    
    func elevationMeters(
        from measurement: NWSMeasurement?
    ) -> Double? {
        guard let measurement, let value = measurement.value else {
            return nil
        }
        
        switch measurement.unitCode {
        case "wmoUnit:m":
            return value
            
        case "wmoUnit:ft":
            return value * 0.3048
            
        default:
            return nil
        }
    }
}
