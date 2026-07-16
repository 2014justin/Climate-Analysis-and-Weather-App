import Foundation

/// Owns the live worldwide snapshot for this app session.
///
/// An actor is a protected room: asynchronous tasks may
/// ask it for data, but only one task can modify its stored
/// values at a time.
actor AviationWeatherSnapshotStore {
    static let refreshInterval:
        TimeInterval = 10 * 60
    
    private var stationCatalog:
        AviationWeatherStationCatalog?
    
    private var latestSnapshot:
        AtlasObservationSnapshot?
    
    func snapshot(
        forceRefresh: Bool = false,
        now: Date = Date()
    ) async throws -> AtlasObservationSnapshot {
        if !forceRefresh,
           let latestSnapshot,
           now.timeIntervalSince(
            latestSnapshot.downloadedAt
           ) < Self.refreshInterval {
            return latestSnapshot
        }
        
        let catalog =
            try await catalogForSession()
        
        let refreshedSnapshot =
            try await AviationWeatherSnapshotService()
                .fetchSnapshot(using: catalog)
        
        latestSnapshot = refreshedSnapshot
        
        return refreshedSnapshot
    }
    
    func cachedSnapshot()
    -> AtlasObservationSnapshot? {
        latestSnapshot
    }
    
    private func catalogForSession()
        async throws
    -> AviationWeatherStationCatalog {
        
        if let stationCatalog {
            return stationCatalog
        }
        
        let downloadedCatalog =
            try await
                AviationWeatherStationCatalogService()
                    .fetchCatalog()
        
        stationCatalog = downloadedCatalog
        
        return downloadedCatalog
    }
}
