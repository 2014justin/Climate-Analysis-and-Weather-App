import Foundation

private struct ECCCClimateStationPage: Decodable {
    let features: [ECCCClimateStationFeature]
    let links: [ECCCClimateStationLink]
}

private struct ECCCClimateStationLink: Decodable {
    let rel: String
    let href: String
}

private struct ECCCClimateStationFeature: Decodable {
    let properties: ECCCClimateStationProperties
    let geometry: ECCCClimateStationGeometry?
}

private struct ECCCClimateStationGeometry: Decodable {
    let coordinates: [Double]
}

private struct ECCCClimateStationProperties: Decodable {
    let climateIdentifier: String
    let stationName: String
    let provinceCode: String
    
    let elevation: String?
    
    let transportCanadaIdentifier: String?
    let wmoIdentifier: String?
    let timeZoneCode: String?
    
    let stationType: String?
    let operatorName: String?
    
    let dailyRecordStart: String?
    let dailyRecordEnd: String?
    
    enum CodingKeys: String, CodingKey {
        case climateIdentifier = "CLIMATE_IDENTIFIER"
        
        case stationName = "STATION_NAME"
        
        case provinceCode = "PROV_STATE_TERR_CODE"
        
        case elevation = "ELEVATION"
        
        case transportCanadaIdentifier = "TC_IDENTIFIER"
        
        case wmoIdentifier = "WMO_IDENTIFIER"
        
        case timeZoneCode = "TIMEZONE"
        
        case stationType = "STATION_TYPE"
        
        case operatorName = "ENG_STN_OPERATOR_NAME"
        
        case dailyRecordStart = "DLY_FIRST_DATE"
        
        case dailyRecordEnd = "DLY_LAST_DATE"
    }
}

/// Append the mapper
private extension ECCCClimateStationFeature {
    var climateStation: ECCCClimateStation? {
        guard let geometry,
              geometry.coordinates.count >= 2 else {
            return nil
        }
        
        let longitude = geometry.coordinates[0]
        let latitude = geometry.coordinates[1]
        
        guard longitude.isFinite,
              latitude.isFinite,
              (-180.0...180.0).contains(longitude),
              (-90.0...90.0).contains(latitude),
              let climateIdentifier = Self.cleaned(
                properties.climateIdentifier
              ),
              let stationName = Self.cleaned(
                properties.stationName
              ),
              let provinceCode = Self.cleaned(
                properties.provinceCode
              ) else {
            return nil
        }
        
        let elevationMeters = Self.cleaned(
            properties.elevation
        ).flatMap {
            Double($0)
        }
        
        return ECCCClimateStation(
            climateIdentifier: climateIdentifier.uppercased(),
            stationName: stationName,
            provinceCode: provinceCode.uppercased(),
            latitude: latitude,
            longitude: longitude,
            elevationMeters: elevationMeters,
            transportCanadaIdentifier:
                Self.cleaned(
                    properties
                        .transportCanadaIdentifier
                )?.uppercased(),
            wmoIdentifier:
                Self.cleaned(
                    properties.wmoIdentifier
                )?.uppercased(),
            timeZoneCode:
                Self.cleaned(
                    properties.timeZoneCode
                )?.uppercased(),
            stationType:
                Self.cleaned(
                    properties.stationType
                ),
            operatorName:
                Self.cleaned(
                    properties.operatorName
                ),
            dailyRecordStart:
                Self.climateDate(
                    from: properties.dailyRecordStart
                ),
            dailyRecordEnd:
                Self.climateDate(
                    from: properties.dailyRecordEnd
                )
        )
    }
    
    static func cleaned(
        _ value: String?
    ) -> String? {
        guard let value else {
            return nil
        }
        
        let cleanedValue =
            value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanedValue.isEmpty
            ? nil
            : cleanedValue
    }
    
    static func climateDate(
        from rawValue: String?
    ) -> ClimateDate? {
        guard let rawValue = cleaned(rawValue) else {
            return nil
        }
        
        let components = rawValue
            .prefix(10)
            .split(separator: "-")
        
        guard components.count == 3,
              let year = Int(components[0]),
              let month = Int(components[1]),
              let day = Int(components[2]),
              (1...12).contains(month),
              (1...31).contains(day) else {
            return nil
        }
        
        return ClimateDate(
            year: year,
            month: month,
            day: day
        )
    }
}

enum ECCCClimateStationCatalogServiceError:
    LocalizedError {
    
    case invalidIdentifier
    case invalidSearchArea
    case invalidURL
    case invalidResponse
    case unexpectedStatusCode(Int)
    case paginationLoop
    
    var errorDescription: String? {
        switch self {
        case .invalidIdentifier:
            return """
                The Canadian station identifier is empty.
                """
        case .invalidSearchArea:
            return """
            The Canadian station search \
            coordinate or radius is invalid
            """
            
        case .invalidURL:
            return """
                Could not construct the ECCC \
                climate-stations URL.
                """
            
        case .invalidResponse:
            return """
                ECCC returned an invalid \
                climate-stations response.
                """
            
        case .unexpectedStatusCode(let statusCode):
            return """
                ECCC returned HTTP \(statusCode) \
                for the station catalog.
                """
            
        case .paginationLoop:
            return """
                ECCC returned a repeating \
                station-catalog pagination link.
                """
        }
    }
}

struct ECCCClimateStationCatalogService {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchStations(
        forAviationStationID stationID: String
    ) async throws -> [ECCCClimateStation] {
        let identifier =
            try transportCanadaIdentifier(
                from: stationID
            )
        
        let firstPageURL = try initialURL(
            transportCanadaIdentifier: identifier
        )
        
        return try await fetchStations(
            startingAt: firstPageURL
        )
    }
    
    /// Public nearby search
    func fetchNearbyStations(
        latitude: Double,
        longitude: Double,
        radiusMiles: Double = 100.0
    ) async throws -> [ECCCClimateStation] {
        let sourceCoordinate =
            GeographicCoordinate(
                latitude: latitude,
                longitude: longitude
            )
        
        guard sourceCoordinate.isValid,
              radiusMiles.isFinite,
              radiusMiles > 0.0 else {
            throw ECCCClimateStationCatalogServiceError
                .invalidSearchArea
        }
        
        let firstPageURL = try nearbyURL(
            centeredAt: sourceCoordinate,
            radiusMiles: radiusMiles
        )
        
        let stations = try await fetchStations(
            startingAt: firstPageURL
        )
        
        return stations.compactMap { station
            -> (
                station: ECCCClimateStation,
                distance: Double
            )? in
            
            guard let distance =
                    station.distanceMiles(from: sourceCoordinate),
                  distance <= radiusMiles else {
                return nil
            }
            
            return(
                station: station,
                distance: distance
            )
        }
        .sorted {
            if $0.distance != $1.distance {
                return $0.distance < $1.distance
            }
            
            return $0.station.climateIdentifier < $1.station.climateIdentifier
        }
        .map {
            $0.station
        }
    }
    
    /// Shared paging helper
    private func fetchStations(
        startingAt initialURL: URL
    ) async throws -> [ECCCClimateStation] {
        var nextURL: URL? = initialURL
        var visitedURLs = Set<URL>()
        
        var stationsByIdentifier:
        [String: ECCCClimateStation] = [:]
        
        while let pageURL = nextURL {
            guard visitedURLs
                .insert(pageURL)
                .inserted else {
                throw ECCCClimateStationCatalogServiceError
                    .paginationLoop
            }
            
            var request = URLRequest(
                url: pageURL,
                cachePolicy: .useProtocolCachePolicy,
                timeoutInterval: 30
            )
            
            request.setValue(
                """
                Weather & Climate Atlas Swift App v1.53b
                """,
                forHTTPHeaderField: "User-Agent"
            )
            
            request.setValue(
                """
                application/geo+json, application/json
                """,
                forHTTPHeaderField: "Accept"
            )
            
            let (data, response) =
                try await session.data(
                    for: request
                )
            
            guard let httpResponse =
                    response as? HTTPURLResponse else {
                throw ECCCClimateStationCatalogServiceError
                    .invalidResponse
            }
            
            guard (200..<300).contains(
                httpResponse.statusCode
            ) else {
                throw ECCCClimateStationCatalogServiceError
                    .unexpectedStatusCode(
                        httpResponse.statusCode
                    )
            }

            let page = try JSONDecoder().decode(
                ECCCClimateStationPage.self,
                from: data
            )

            for station in page.features.compactMap({
                $0.climateStation
            }) where station.hasDailyRecord {
                stationsByIdentifier[
                    station.climateIdentifier
                ] = station
            }
            
            nextURL = page.links
                .first {
                    $0.rel.lowercased() == "next"
                }
                .flatMap {
                    URL(
                        string: $0.href,
                        relativeTo: pageURL
                    )?.absoluteURL
                }
        }
        
        return stationsByIdentifier.values.sorted {
            if let firstStart =
                $0.dailyRecordStart,
               let secondStart =
                $1.dailyRecordStart,
               firstStart != secondStart {
                return firstStart < secondStart
            }
            
            return $0.climateIdentifier < $1.climateIdentifier
        }
    }
    
    private func transportCanadaIdentifier(
        from stationID: String
    ) throws -> String {
        let normalizedID = stationID
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        
        guard normalizedID.isEmpty == false else {
            throw ECCCClimateStationCatalogServiceError
                .invalidIdentifier
        }
        
        if normalizedID.count == 4,
           normalizedID.hasPrefix("C") {
            return String(normalizedID.dropFirst())
        }
        
        return normalizedID
    }
    
    /// Bounding-box URL builder
    private func nearbyURL(
        centeredAt coordinate: GeographicCoordinate,
        radiusMiles: Double
    ) throws -> URL {
        let latitudeDelta = radiusMiles / 69.0
        
        let latitudeRadians = coordinate.latitude * Double.pi / 180.0
        
        let milesPerLongitudeDegree = max(
            69.0 * abs(cos(latitudeRadians)),
            0.01
        )
        
        let longitudeDelta = min(
            radiusMiles / milesPerLongitudeDegree, 180.0
        )
        
        let minimumLatitude = max(
            coordinate.latitude - latitudeDelta,
            -90.0
        )
        
        let maximumLatitude = min(
            coordinate.latitude + latitudeDelta,
            90.0
        )
        
        let rawMinimumLongitude = coordinate.longitude - longitudeDelta
        
        let rawMaximumLongitude = coordinate.longitude + longitudeDelta
        
        let crossesAntimeridian =
            rawMinimumLongitude < -180.0
            || rawMaximumLongitude > 180.0
        
        let minimumLongitude =
            crossesAntimeridian
                ? -180.0
                : rawMinimumLongitude
        
        let maximumLongitude =
            crossesAntimeridian
                ? 180.0
                : rawMaximumLongitude
        
        let boundingBox =
            "\(minimumLongitude),"
            + "\(minimumLatitude),"
            + "\(maximumLongitude),"
            + "\(maximumLatitude)"
        
        var components = URLComponents(
            string: """
                https://api.weather.gc.ca/collections/climate-stations/items
                """
        )
        
        components?.queryItems = [
            URLQueryItem(
                name: "f",
                value: "json"
            ),
            URLQueryItem(
                name: "bbox",
                value: boundingBox
            ),
            URLQueryItem(
                name: "limit",
                value: "10000"
            )
        ]
        
        guard let url = components?.url else {
            throw ECCCClimateStationCatalogServiceError
                .invalidURL
        }
        
        return url
    }
    
    private func initialURL(
        transportCanadaIdentifier: String
    ) throws -> URL {
        var components = URLComponents(
            string: """
                https://api.weather.gc.ca/collections/climate-stations/items
                """
        )
        
        components?.queryItems = [
            URLQueryItem(
                name: "f",
                value: "json"
            ),
            URLQueryItem(
                name: "TC_IDENTIFIER",
                value: transportCanadaIdentifier
            ),
            URLQueryItem(
                name: "properties",
                value: [
                    "CLIMATE_IDENTIFIER",
                    "STATION_NAME",
                    "PROV_STATE_TERR_CODE",
                    "ELEVATION",
                    "TC_IDENTIFIER",
                    "WMO_IDENTIFIER",
                    "TIMEZONE",
                    "STATION_TYPE",
                    "ENG_STN_OPERATOR_NAME",
                    "DLY_FIRST_DATE",
                    "DLY_LAST_DATE"
                ].joined(separator: ",")
            ),
            URLQueryItem(
                name: "limit",
                value: "10000"
            )
        ]
        
        guard let url = components?.url else {
            throw ECCCClimateStationCatalogServiceError
                .invalidURL
        }
        
        return url
    }
}
