import Foundation

nonisolated enum ECCCForecastZoneCatalogServiceError: LocalizedError, Sendable {
    
    case invalidURL
    case invalidResponse
    case unexpectedStatusCode(Int)
    case invalidPaginationLink(String)
    case paginationLoop
    case emptyCatalog
    case incompleteCatalog(
        expected: Int,
        received: Int
    )
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return """
                Could not construct the ECCC public forecast-zone URL.
                """
            
        case .invalidResponse:
            return """
                ECCC returned an invalid forecast-zone response.
                """
            
        case .unexpectedStatusCode(let statusCode):
            return """
                ECCC returned HTTP \(statusCode) for the forecast-zone catalog.
                """
            
        case .invalidPaginationLink(let link):
            return """
                ECCC returned an invalid forecast-zone pagination link: \(link)
                """
            
        case .paginationLoop:
            return """
                ECCC returned a repeating forecast-zone pagination link.
                """
            
        case .emptyCatalog:
            return """
                ECCC returned an empty public forecast-zone catalog.
                """
            
        case .incompleteCatalog(
            let expected,
            let received
        ):
            return """
                ECCC reported \(expected) forecast zones, but only \
                \(received) unique zones were downloaded.
                """
        }
    }
}

/// Several station refreshes may ask for Canadian forecast zones at roughly the same time. The actor protects
/// cachedZones, ensuring only one task mutates that shared catalog states at once.
actor ECCCForecastZoneCatalogService {
    fileprivate let session: URLSession
    
    /// The geometrically-validated catalog is downloaded
    fileprivate var cachedZones: [ECCCForecastZoneGeometry]?
    
    init(
        session: URLSession = .shared
    ) {
        self.session = session
    }
    
    /// A shared in-progress download. Concurrent callers await the same task
    /// instead of indepdently downloading all forecast-zone pages.
    fileprivate var catalogDownloadTask:
        Task<[ECCCForecastZoneGeometry], Error>?
    
    /// Returns the complete geometrically-validated ECCC forecast-zone catalog.
    ///
    /// The first request downloads every page. Later requests reuse the
    /// in-memory catalog unless a deliberate refresh is requested.
    func forecastZones(
        forceRefresh: Bool = false
    ) async throws -> [ECCCForecastZoneGeometry] {
        if forceRefresh == false,
           let cachedZones {
            return cachedZones
        }
        
        if let catalogDownloadTask {
            return try await catalogDownloadTask.value
        }
        
        let downloadTask = Task {
            try await self.downloadCompleteCatalog()
        }
        
        catalogDownloadTask = downloadTask
        
        do {
            let zones = try await downloadTask.value
            
            cachedZones = zones
            catalogDownloadTask = nil
            
            return zones
        } catch {
            catalogDownloadTask = nil
            throw error
        }
    }
    
    fileprivate nonisolated static func initialCatalogURL() throws -> URL {
        var components = URLComponents()
        
        components.scheme = "https"
        components.host = "api.weather.gc.ca"
        components.path = """
            /collections/public-standard-forecast-zones/items
            """
        
        components.queryItems = [
            URLQueryItem(
                name: "f",
                value: "json"
            ),
            URLQueryItem(
                name: "limit",
                value: "100"
            )
        ]
        
        guard let url = components.url else {
            throw ECCCForecastZoneCatalogServiceError.invalidURL
        }
        
        return url
    }
    
    /// Download one ECCC GeoJSON page, verify that the response is HTTP,
    /// Reject unsuccessful status codes, decode it into our
    /// strongly typed feature collection.
    fileprivate func downloadPage(
        at pageURL: URL
    ) async throws -> ECCCForecastZoneGeoJSONFeatureCollection {
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
            try await session.data(for: request)
        
        guard let httpResponse =
                response as? HTTPURLResponse else {
            throw ECCCForecastZoneCatalogServiceError.invalidResponse
        }
        
        guard (200..<300).contains(
            httpResponse.statusCode
        ) else {
            throw ECCCForecastZoneCatalogServiceError
                .unexpectedStatusCode(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(
            ECCCForecastZoneGeoJSONFeatureCollection.self,
            from: data
        )
    }
    
    fileprivate nonisolated static func nextPageURL(
        in page: ECCCForecastZoneGeoJSONFeatureCollection,
        relativeTo pageURL: URL
    ) throws -> URL? {
        guard let nextLink = page.links.first(
            where: {
                $0.relationship.lowercased() == "next"
            }
        ) else {
            return nil
        }
        
        let cleanedLink = nextLink.href
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanedLink.isEmpty,
              let nextURL = URL(
                string: cleanedLink,
                relativeTo: pageURL
              )?.absoluteURL,
              nextURL.scheme?.lowercased() == "https",
              nextURL.host?.lowercased() ==
                "api.weather.gc.ca" else {
            throw ECCCForecastZoneCatalogServiceError
                .invalidPaginationLink(nextLink.href)
        }
        
        return nextURL
    }
    
    fileprivate func downloadCompleteCatalog() async throws -> [ECCCForecastZoneGeometry] {
        var nextURL: URL? =
            try Self.initialCatalogURL()
        
        var visitedURLs = Set<URL>()
        
        var zonesByFeatureID:
            [String: ECCCForecastZoneGeometry] = [:]
        
        var expectedZoneCount: Int?
        
        while let pageURL = nextURL {
            guard visitedURLs
                .insert(pageURL)
                .inserted else {
                throw ECCCForecastZoneCatalogServiceError
                    .paginationLoop
            }
            
            let page = try await downloadPage(at: pageURL)
            
            if expectedZoneCount == nil,
               let numberMatched = page.numberMatched {
                expectedZoneCount = numberMatched
            }
            
            let pageZones =
                try page.forecastZoneGeometries()
            
            for zone in pageZones {
                zonesByFeatureID[zone.id] = zone
            }
            
            nextURL = try Self.nextPageURL(in: page, relativeTo: pageURL)
        }
        
        let zones = zonesByFeatureID.values
            .sorted { firstZone, secondZone in
                let firstCode =
                    firstZone.properties.publicZoneCode
                
                let secondCode =
                    secondZone.properties.publicZoneCode
                
                if firstCode != secondCode {
                    return firstCode < secondCode
                }
                
                return firstZone.id < secondZone.id
            }
        
        guard !zones.isEmpty else {
            throw ECCCForecastZoneCatalogServiceError.emptyCatalog
        }
        
        if let expectedZoneCount,
           zones.count != expectedZoneCount {
            throw ECCCForecastZoneCatalogServiceError
                .incompleteCatalog(expected: expectedZoneCount, received: zones.count)
        }
        
        return zones
    }
}
