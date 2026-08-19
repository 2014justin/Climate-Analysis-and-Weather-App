import Foundation

/// Builds the final Canada-wide catalog by joining:
///
/// 1. Official ECCC forecast-zone geometry
/// 2. Meteocode forecast-region metadata
///
/// The actor ensures that concurrent station refreshes share one catalog
/// build rather than independently repeating the same network work.

actor ECCCForecastRegionCatalogService: ECCCForecastRegionResolving {
    
    fileprivate let zoneCatalogService:
        ECCCForecastZoneCatalogService
    
    fileprivate let meteocodeService:
        ECCCMeteocodeDatamartService
    
    /// The completed coordinate-resolving catalog.
    fileprivate var cachedCatalog:
        ECCCForecastRegionCatalog?
    
    /// Shared by simultaneous callers while the catalog
    fileprivate var catalogBuildTask:
        Task<ECCCForecastRegionCatalog, Error>?
    
    init(
        session: URLSession = .shared
    ) {
        zoneCatalogService =
            ECCCForecastZoneCatalogService(session: session)
        
        meteocodeService =
            ECCCMeteocodeDatamartService(session: session)
    }
    
    /// Downloads the latest forecast-region metadata from every Canadian
    /// Meteocode feed.
    ///
    /// The five feeds are independent, so they are downloaded concurrently.
    /// A failure in any feed fails the complete catalog rather than silently
    /// leaving part of Canada without forecast coverage.
    fileprivate func downloadForecastRegions(
        referenceDate: Date
    ) async throws -> [ECCCForecastRegion] {
        let service = meteocodeService
        
        return try await withThrowingTaskGroup(
            of: [ECCCForecastRegion].self
        ) { group in
            for feed in ECCCForecastFeed.allCases {
                group.addTask {
                    try await service.forecastRegions(for: feed, referenceDate: referenceDate)
                }
            }
            
            var regions: [ECCCForecastRegion] = []
            
            for try await feedRegions in group {
                regions.append(contentsOf: feedRegions)
            }
            
            return regions.sorted { $0.id < $1.id}
        }
    }
    
    //// Builds one coordinate-resolvable Canadian catalog.
    ///
    /// Zone geometry and Meteocode metadata are independent network resources,
    /// so both downloads begin concurrently. Zones absent from the current
    /// Meteocode metadata are recorded and omitted. Ambiguous or invalid
    /// mappings remain fatal because returning the wrong forecast is unsafe.
    
    fileprivate func buildCatalog(
        referenceDate: Date,
        forceRefresh: Bool
    ) async throws -> ECCCForecastRegionCatalog {
        async let downloadedZones =
        zoneCatalogService.forecastZones(forceRefresh: forceRefresh)
        
        async let downloadedRegions = downloadForecastRegions(referenceDate: referenceDate)
        
        let (zones, regions) =
            try await (
                downloadedZones,
                downloadedRegions
            )
        
        var joinedGeometries: [ECCCForecastRegionGeometry] = []
        var unmappedZoneDescriptions: [String] = []
        
        for zone in zones {
            do {
                joinedGeometries.append(
                    try zone.forecastRegionGeometry(matching: regions)
                )
            } catch let mappingError as ECCCForecastRegionMappingError {
                switch mappingError {
                case .forecastRegionNotFound:
                    unmappedZoneDescriptions.append(
                        "\(zone.properties.featureID): \(zone.properties.name)"
                    )
                    
                case .ambiguousForecastRegions,
                        .unsupportedProvinceCode,
                        .incompatibleProvinceCodes:
                    throw mappingError
                }
            }
        }
        
        guard joinedGeometries.isEmpty == false else {
            throw ECCCForecastRegionCatalogError.emptyCatalog
        }
        
        #if DEBUG
        if unmappedZoneDescriptions.isEmpty == false {
            print(
                "ECCC catalog skipped \(unmappedZoneDescriptions.count) " +
                "unmapped zone(s): " +
                unmappedZoneDescriptions.joined(separator: ", ")
            )
        }
        #endif
        
        joinedGeometries.sort { $0.id < $1.id }
        
        return ECCCForecastRegionCatalog(geometries: joinedGeometries)
    }
    
    /// Returns the complete coordinate-resolving Canadian catalog.
    ///
    /// The first caller builds the catalog. Concurrent callers share the same
    /// in-progress task, while later callers reuse the  completed in-memory catalog.
    func forecastRegionCatalog(
        forceRefresh: Bool = false,
        referenceDate: Date = Date()
    ) async throws -> ECCCForecastRegionCatalog {
        if forceRefresh == false,
           let cachedCatalog {
            return cachedCatalog
        }
        
        if let catalogBuildTask {
            return try await catalogBuildTask.value
        }
        
        let buildTask = Task {
            try await self.buildCatalog(referenceDate: referenceDate, forceRefresh: forceRefresh)
        }
        
        catalogBuildTask = buildTask
        
        do {
            let catalog = try await buildTask.value
            
            cachedCatalog = catalog
            catalogBuildTask = nil
            
            return catalog
        } catch {
            catalogBuildTask = nil
            throw error
        }
    }
    
    /// Resolves a station coordinate to its official ECCC Meteocode region.
    ///
    /// Catalog construction, caching, geometry filtering, and polygon containment
    /// remain hidden behind the provider-agnostic resolver.
    func region(
        containingLatitude latitude: Double,
        longitude: Double
    ) async throws -> ECCCForecastRegion {
        let catalog =
            try await forecastRegionCatalog()
        
        return try await catalog.region(containingLatitude: latitude, longitude: longitude)
    }
    
    /// Resolves a coordinate and downloads every Meteocode product required
    /// to construc tthat region's complete native forecast.
    func resolvedForecast(
        containingLatitude latitude: Double,
        longitude: Double,
        stationIdentifier: String? = nil,
        referenceDate: Date = Date()
    ) async throws -> ECCCMeteocodeResolvedRegionForecast {
        let resolvedRegion =
        try await region(
            containingLatitude: latitude, longitude: longitude
        )
        
        let documents =
            try await meteocodeService.forecastDocuments(
                for: resolvedRegion.feed,
                referenceDate: referenceDate
            )
        
        let supplementalProducts =
            ECCCForecastProductCompatibility
                .supplementalProducts(
                    for: stationIdentifier,
                    resolvedRegion: resolvedRegion
                )
                .filter { product in
                    let normalizedBulletinCode = product.bulletinCode
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .uppercased()
                    let normalizedRegionCode = product.regionCode
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .uppercased()
                    
                    return documents.contains { document in
                        document.bulletinCode
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .uppercased() == normalizedBulletinCode &&
                        document.regions.contains { region in
                            region.regionCode
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                                .uppercased() == normalizedRegionCode
                        }
                    }
                }
        
        let forecastRegion =
            resolvedRegion.addingProducts(supplementalProducts)
        
        let segments =
        try documents.forecastSegments(for: forecastRegion)
        
        return ECCCMeteocodeResolvedRegionForecast(
            region: resolvedRegion,
            segments: segments
        )
    }
}
