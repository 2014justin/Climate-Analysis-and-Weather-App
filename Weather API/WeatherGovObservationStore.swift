import Foundation

nonisolated fileprivate struct
WeatherGovCatalogCacheEntry:
    Sendable {

    let stations: [AtlasStation]
    let downloadedAt: Date
}

nonisolated fileprivate enum WeatherGovObservationCacheStatus: Sendable {
    case available
    case noCurrentObservation
    case observationWithoutTemperature
    case observationOutsideAcceptedTimeRange
    case transientFailure
}

nonisolated fileprivate struct WeatherGovObservationCacheEntry: Sendable {
    let observation: AtlasObservation?
    
    let status: WeatherGovObservationCacheStatus
    
    let checkedAt: Date
}

actor WeatherGovObservationStore {
    static let catalogRefreshInterval:
        TimeInterval = 24 * 60 * 60

    static let observationRefreshInterval:
        TimeInterval = 10 * 60
    
    static let noCurrentObservationRefreshInterval:
        TimeInterval = 30 * 60
    
    static let unusableObservationRefreshInterval:
        TimeInterval = 10 * 60
    
    static let transientFailureRetryInterval:
        TimeInterval = 60
    
    private let stateCodeStore: WeatherGovStateCodeStore

    private var catalogCache:
        [String: WeatherGovCatalogCacheEntry] = [:]

    private var observationCache:
        [String: WeatherGovObservationCacheEntry] = [:]
    
    init(
        stateCodeStore:
            WeatherGovStateCodeStore =
                WeatherGovStateCodeStore()
    ) {
        self.stateCodeStore =
            stateCodeStore
    }

    /// Returns every still-usable observation already held in RAM for the
    /// requested region without performing provider or catalog work.
    ///
    /// The request planner limits which stations may be refreshed during one
    /// pass. It must not limit which previously downloaded stations may be
    /// rendered while that refresh is running.
    func cachedSnapshot(
        in bounds: AtlasMapBounds,
        now: Date = Date()
    ) -> AtlasObservationSnapshot {
        let cachedObservations =
            usableCachedObservations(
                in: bounds,
                now: now
            )

        return AtlasObservationSnapshot(
            observations:
                cachedObservations.map(\.observation),
            downloadedAt:
                cachedObservations
                    .map(\.checkedAt)
                    .min()
                    ?? now,
            rawReportCount:
                cachedObservations.count
        )
    }
    
    func snapshot(
        in bounds: AtlasMapBounds,
        forceRefresh: Bool = false,
        forceCatalogRefresh: Bool = false,
        now: Date = Date()
    ) async throws -> AtlasObservationSnapshot {
        let stateCodes = try await stateCodeStore
            .stateCodes(in: bounds, now: now)
        
        return try await snapshot(
            in: bounds,
            stateCodes: stateCodes,
            forceRefresh: forceRefresh,
            forceCatalogRefresh: forceCatalogRefresh,
            now: now
        )
    }
    
    func snapshot(
        in bounds: AtlasMapBounds,
        stateCodes: [String],
        forceRefresh: Bool = false,
        forceCatalogRefresh: Bool = false,
        now: Date = Date()
    ) async throws -> AtlasObservationSnapshot {

        let normalizedStateCodes = Set(
            stateCodes.map {
                $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .uppercased()
            }
        )
        .filter {
            $0.range(
                of: #"^[A-Z]{2}$"#,
                options: .regularExpression
            ) != nil
        }
        .sorted()

        guard normalizedStateCodes.isEmpty == false else {
            return cachedSnapshot(
                in: bounds,
                now: now
            )
        }

        var stationsByID:
            [String: AtlasStation] = [:]

        for stateCode in normalizedStateCodes {
            let stateStations =
                try await stations(
                    inState: stateCode,
                    forceRefresh: forceCatalogRefresh,
                    now: now
                )

            for station in stateStations {
                guard bounds.contains(
                    latitude: station.latitude,
                    longitude: station.longitude
                ) else {
                    continue
                }

                stationsByID[station.id] = station
            }
        }

        let catalogCandidates =
            stationsByID.values.sorted {
                $0.id < $1.id
            }

        let candidates =
            WeatherGovStationRequestPlanner()
                .stations(
                    from: catalogCandidates,
                    in: bounds
                )

        guard candidates.isEmpty == false else {
            return cachedSnapshot(
                in: bounds,
                now: now
            )
        }
        
        var observationCacheHitCount = 0
        
        var stationsNeedingRefresh:
            [AtlasStation] = []

        for station in candidates {
            if forceRefresh {
                stationsNeedingRefresh.append(
                    station
                )
                continue
            }

            guard let cacheEntry =
                    observationCache[station.id] else {
                stationsNeedingRefresh.append(
                    station
                )
                continue
            }

            let cacheAge =
                now.timeIntervalSince(
                    cacheEntry.checkedAt
                )

            let refreshInterval = refreshInterval(for: cacheEntry.status)

            guard cacheAge >= 0,
                  cacheAge < refreshInterval else {
                stationsNeedingRefresh.append(
                    station
                )
                continue
            }
            
            observationCacheHitCount += 1
        }
        
        await WeatherGovAPIActivityMeter
            .shared
            .recordObservationCacheHits(
                observationCacheHitCount,
                at: now
            )

        if stationsNeedingRefresh.isEmpty == false {
            let refreshedBatch = await WeatherGovObservationSnapshotService()
                .fetchBatch(
                    for: stationsNeedingRefresh,
                    now: now
                )
            
            for result in refreshedBatch.results {
                let stationID =
                result.station.id
                
                let previousObservation = observationCache[
                    stationID
                ]?.observation
                
                let cacheEntry: WeatherGovObservationCacheEntry
                
                switch result.outcome {
                case .observation(let observation):
                    cacheEntry = WeatherGovObservationCacheEntry(
                        observation: observation,
                        status: .available,
                        checkedAt: now
                    )
                    
                case .noCurrentObservation:
                    /// A real 404 is stable enough to avoid asking again on every nearby pan.
                    /// A previous good observation may remain visible until its one-hour age limit.
                    cacheEntry = WeatherGovObservationCacheEntry(
                        observation: previousObservation,
                        status: .noCurrentObservation,
                        checkedAt: now
                    )
                    
                case .observationWithoutTemperature:
                    cacheEntry = WeatherGovObservationCacheEntry(
                        observation: previousObservation,
                        status: .observationWithoutTemperature,
                        checkedAt: now
                    )
                    
                case .observationOutsideAcceptedTimeRange:
                    cacheEntry = WeatherGovObservationCacheEntry(
                        observation: previousObservation,
                        status: .observationOutsideAcceptedTimeRange,
                        checkedAt: now
                    )
                    
                case .transientFailure:
                    /// Preserve the last usable observation, but retry much sooner than a real 404.
                    ///
                    cacheEntry = WeatherGovObservationCacheEntry(
                        observation: previousObservation,
                        status: .transientFailure,
                        checkedAt: now
                    )
                }
                
                observationCache[stationID] = cacheEntry
            }
        }

        let cachedObservations =
            usableCachedObservations(
                in: bounds,
                now: now
            )

        return AtlasObservationSnapshot(
            observations:
                cachedObservations.map(\.observation),
            downloadedAt:
                cachedObservations
                    .map(\.checkedAt)
                    .min()
                    ?? now,
            rawReportCount: candidates.count
        )
    }

    /// Reads the renderable cache independently from the planner-selected
    /// refresh candidates. This is the store's stale-while-revalidate layer.
    private func usableCachedObservations(
        in bounds: AtlasMapBounds,
        now: Date
    ) -> [(
        observation: AtlasObservation,
        checkedAt: Date
    )] {
        let oldestAcceptedObservation =
            now.addingTimeInterval(
                -WeatherGovObservationSnapshotService
                    .defaultMaximumObservationAge
            )

        let newestAcceptedObservation =
            now.addingTimeInterval(
                10 * 60
            )

        return observationCache.values
            .compactMap {
                entry -> (
                    observation: AtlasObservation,
                    checkedAt: Date
                )? in

                guard let observation =
                        entry.observation,
                      bounds.contains(
                        latitude:
                            observation.station.latitude,
                        longitude:
                            observation.station.longitude
                      ),
                      observation.observedAt
                        >= oldestAcceptedObservation,
                      observation.observedAt
                        <= newestAcceptedObservation else {
                    return nil
                }

                return (
                    observation: observation,
                    checkedAt: entry.checkedAt
                )
            }
            .sorted {
                $0.observation.station.source.stationID
                    < $1.observation.station.source.stationID
            }
    }
    
    private func refreshInterval(
        for status: WeatherGovObservationCacheStatus
    ) -> TimeInterval {
        switch status {
        case .available:
            return Self.observationRefreshInterval
        case .noCurrentObservation:
            return Self.noCurrentObservationRefreshInterval
            
        case .observationWithoutTemperature, .observationOutsideAcceptedTimeRange:
            return Self.unusableObservationRefreshInterval
            
        case .transientFailure:
            return Self.transientFailureRetryInterval
        }
    }
    
    private func stations(
        inState stateCode: String,
        forceRefresh: Bool,
        now: Date
    ) async throws -> [AtlasStation] {

        if forceRefresh == false,
           let cachedEntry =
                catalogCache[stateCode],
           now.timeIntervalSince(
                cachedEntry.downloadedAt
           ) >= 0,
           now.timeIntervalSince(
                cachedEntry.downloadedAt
           ) < Self.catalogRefreshInterval {
            return cachedEntry.stations
        }

        do {
            let downloadedStations =
                try await
                    WeatherGovStationCatalogService()
                        .fetchStations(
                            inState: stateCode
                        )

            catalogCache[stateCode] =
                WeatherGovCatalogCacheEntry(
                    stations:
                        downloadedStations,
                    downloadedAt: now
                )

            return downloadedStations
        } catch {
            if let cachedEntry =
                    catalogCache[stateCode] {
                return cachedEntry.stations
            }

            throw error
        }
    }
}
