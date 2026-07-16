import Foundation

/// Short-lived, in-memory storage for Atlas observations.
///
/// The cache exists only while the app is running. it does not save weather obs
/// permanently to disk
///
///
///The cache key includes AtlasStationScope. Therefore, future All Networks results cannot accidentally masquerade as complete Primary NWS/FAA coverage.
///We remember both the stations and the geographic area searched. Otherwise an empty area would be ambiguous: no stations exist there, or we never downloaded it.
///If the API hits its 400-report limit, we refuse to cache that area as complete.
struct AtlasObservationCache: Sendable {
    private struct CacheKey: Hashable, Sendable {
        let scope: AtlasStationScope
        let stationID: String
    }
    
    private struct CachedObservation: Sendable {
        let observation: AtlasObservation
        let fetchedAt: Date
    }
    
    private struct CachedCoverage: Sendable {
        let scope: AtlasStationScope
        let bounds: AtlasMapBounds
        let fetchedAt: Date
    }
    
    private var observationsByKey:
        [CacheKey: CachedObservation] = [:]
    
    private var coverages:
        [CachedCoverage] = []
    
    private let freshnessInterval: TimeInterval
    
    init(
        freshnessInterval: TimeInterval = 10 * 60
    ) {
        self.freshnessInterval = freshnessInterval
    }
    
    /// Returns fresh cached stations located in side the requested map.
    ///
    
    func observations(
        in bounds: AtlasMapBounds,
        scope: AtlasStationScope,
        now: Date = Date()
    ) -> [AtlasObservation] {
        observationsByKey.compactMap { element in
            let key = element.key
            let cached = element.value
            
            guard
                key.scope == scope,
                isFresh(cached.fetchedAt, at: now),
                bounds.contains(
                    latitude: cached.observation.station.latitude,
                    longitude: cached.observation.station.longitude
                )
            else {
                return nil
            }
            
            return cached.observation
        }
        .sorted {
            $0.station.id < $1.station.id
        }
    }
    
    /// Tells the caller whether the entire requested map was searched
    /// recently - not merely whether a few stale stations happen to exist.
    func hasFreshCoverage(
        containing requestedBounds: AtlasMapBounds,
        scope: AtlasStationScope,
        now: Date = Date()
    ) -> Bool {
        coverages.contains { coverage in
            coverage.scope == scope
            && isFresh(coverage.fetchedAt, at: now)
            && coverage.bounds.contains(requestedBounds)
        }
    }
    
    /// Stores a complete provider response.
    ///
    /// Truncated responses are deliberately not marked as complete
    /// coverage because some stations may be missing.
    mutating func store(
        _ batch: AtlasObservationBatch,
        scope: AtlasStationScope,
        covering bounds: AtlasMapBounds,
        fetchedAt: Date = Date()
    ) {
        removeExpiredEntries(at: fetchedAt)
        
        guard !batch.mayBeTruncated else {
            return
        }
        
        for observation in batch.observations {
            let key = CacheKey(
                scope: scope,
                stationID: observation.station.id
            )
            
            let observationToKeep: AtlasObservation
            
            if let existing = observationsByKey[key]?.observation,
               existing.observedAt > observation.observedAt {
                observationToKeep = existing
            } else {
                observationToKeep = observation
            }
            
            observationsByKey[key] = CachedObservation(
                observation: observationToKeep,
                fetchedAt: fetchedAt
            )
        }
        
        coverages.append(
            CachedCoverage(
                scope: scope,
                bounds: bounds,
                fetchedAt: fetchedAt)
            
        )
    }
    
    private func isFresh(
        _ fetchedAt: Date,
        at now: Date
    ) -> Bool {
        now.timeIntervalSince(fetchedAt) <= freshnessInterval
    }
    
    private mutating func removeExpiredEntries(
        at now: Date
    ) {
        /// Takes a local snapshot before mutation begins. The removeAll closure now reads only
        /// coverage, now, and maximum Age. It no longer reaches back into self while self.coverages is being modified.
        let maximumAge = freshnessInterval

        observationsByKey = observationsByKey.filter { element in
            now.timeIntervalSince(element.value.fetchedAt)
                <= maximumAge
        }

        coverages.removeAll { coverage in
            now.timeIntervalSince(coverage.fetchedAt)
                > maximumAge
        }
    }}
