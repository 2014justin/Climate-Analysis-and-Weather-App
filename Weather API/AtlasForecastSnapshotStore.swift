/// One completed station forecast retains for Atlas reuse.
///
import Foundation
nonisolated fileprivate struct AtlasStationForecastCacheEntry: Sendable {
    
    let forecast: Forecast
    let storedAt: Date
    
    func isFresh(
        at date: Date,
        lifetime: TimeInterval
    ) -> Bool {
        let age = date.timeIntervalSince(storedAt)
        
        return age >= 0.0
        && age <= lifetime
    }
}

/// The result of loading one station without failing the entire Atlas snapshot.
nonisolated fileprivate enum AtlasStationForecastLoadResult: Sendable {
    
    case success(
        stationID: String,
        forecast: Forecast
    )
    
    case failure(
        stationID: String,
        description: String
    )
}

/// Loads and retains provider-neutral forecasts for Atlas stations.
///
/// The persistent router keeps provider actors and their feed caches
/// alive while the user pans, zooms, and scrubs the map.
actor AtlasForecastSnapshotStore {
    
    fileprivate let router: WeatherForecastRouter
    
    fileprivate let cacheLifetime: TimeInterval
    
    fileprivate var forecastCache: [String: AtlasStationForecastCacheEntry] = [:]
    
    /// Overlapping requests for the same station await one task.
    fileprivate var forecastTasks:
    [String: Task<Forecast, Error>] = [:]
    
    init(
        router: WeatherForecastRouter = WeatherForecastRouter(),
        cacheLifetime: TimeInterval = 15.0 * 60.0
    ) {
        self.router = router
        self.cacheLifetime = cacheLifetime
    }
    
    /// Loads one forecast snapshot for the current zoom-dependent station set.
    func snapshot(
        for observations: [AtlasObservation],
        forceRefresh: Bool = false,
        maximumConcurrentRequests: Int = 8
    ) async -> AtlasForecastSnapshot {
        var encounteredStationIDs = Set<String>()
        
        let uniqueObservations = observations.filter { observation in
            encounteredStationIDs
                .insert(observation.station.id)
                .inserted
        }
        
        guard uniqueObservations.isEmpty == false else {
            return AtlasForecastSnapshot(
                forecastsByStationID: [:],
                failureDescriptionsByStationID: [:],
                loadedAt: Date(),
                requestedStationCount: 0
            )
        }
        
        let concurrentRequestLimit = min(
            max(maximumConcurrentRequests, 1),
            uniqueObservations.count
        )
        
        return await withTaskGroup(
            of: AtlasStationForecastLoadResult.self,
            returning: AtlasForecastSnapshot.self
        ) { group in
            var nextObservationIndex = concurrentRequestLimit
            
            var forecastsByStationID: [String: Forecast] = [:]
            var failureDescriptionsByStationID: [String: String] = [:]
            
            for observation in uniqueObservations.prefix(
                concurrentRequestLimit
            ) {
                group.addTask {
                    await self.loadResult(for: observation, forceRefresh: forceRefresh)
                }
            }
            
            while let result = await group.next() {
                switch result {
                case .success(let stationID, let forecast):
                    forecastsByStationID[stationID] = forecast
                    
                case .failure(let stationID, let description):
                    failureDescriptionsByStationID[stationID] = description
                }
                
                if nextObservationIndex < uniqueObservations.count {
                    let nextObservation = uniqueObservations[nextObservationIndex]
                    
                    nextObservationIndex += 1
                    
                    group.addTask {
                        await self.loadResult(for: nextObservation, forceRefresh: forceRefresh)
                    }
                }
            }
            
            return AtlasForecastSnapshot(
                forecastsByStationID: forecastsByStationID,
                failureDescriptionsByStationID: failureDescriptionsByStationID,
                loadedAt: Date(),
                requestedStationCount: uniqueObservations.count
            )
        }
    }
    
    fileprivate func forecast(
        for observation: AtlasObservation,
        forceRefresh: Bool = false
    ) async throws -> Forecast {
        let stationID = observation.station.id
        let requestDate = Date()
        
        if forceRefresh == false,
           let cachedEntry = forecastCache[stationID],
           cachedEntry.isFresh(at: requestDate, lifetime: cacheLifetime) {
            return cachedEntry.forecast
        }
        
        if let existingTask = forecastTasks[stationID] {
            return try await existingTask.value
        }
        
        let station = observation.station
        
        /// Forecast samples use absolute Date Values. The shared Atlas
        /// timeline is also absolute, so fetching does not require a
        /// station-local display time zone.
        ///
        let request = ForecastRequest(
            latitude: station.latitude,
            longitude: station.longitude,
            timeZoneIdentifier: "UTC",
            countryCode: station.source.countryCode,
            stationIdentifier: station.source.stationID
        )
        
        let router = self.router
        
        let forecastTask = Task {
            try await router.forecast(for: request)
        }
        
        forecastTasks[stationID] = forecastTask
        
        do {
            let forecast = try await forecastTask.value
            
            forecastCache[stationID] =
                AtlasStationForecastCacheEntry(forecast: forecast, storedAt: Date())
            
            forecastTasks[stationID] = nil
            
            return forecast
        } catch {
            forecastTasks[stationID] = nil
            throw error
        }
    }
    
    /// How did this station turn out?
    fileprivate func loadResult(
        for observation: AtlasObservation,
        forceRefresh: Bool
    ) async -> AtlasStationForecastLoadResult {
        let stationID = observation.station.id
        
        do {
            let loadedForecast = try await forecast(for: observation, forceRefresh: forceRefresh)
            
            return .success(stationID: stationID, forecast: loadedForecast)
        } catch {
            return .failure(stationID: stationID, description: error.localizedDescription)
        }
    }
}

