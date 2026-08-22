import SwiftUI
import MapKit

struct ClimateAtlasView: View {
    @Binding var selectedAppSection: AppSection
    
    /// Give the atlas a real handoff closure.
    let onBuildClimateProfile: (
        AtlasObservation
    ) -> Void
    
    /// Both cameraPosition and visibleRegion need the same starting rectange. initialRegion gives us
    /// one autoritative copy instead of repeating the four geographic numbers.
    /// cameraPosition controls where MapKit's viewpoint is.
    /// visibleRegion records the geographical region our station service should eventually search.
    fileprivate static let initialRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 39.5,
            longitude: -98.35
        ),
        span: MKCoordinateSpan(
            latitudeDelta: 25,
            longitudeDelta: 58
        )
    )
    
    @State private var cameraPosition: MapCameraPosition = .region(
        ClimateAtlasView.initialRegion
    )
    
    @State private var visibleRegion = ClimateAtlasView.initialRegion
    
    @State private var stationScope: AtlasStationScope = .primary
    @State private var weatherLayer: AtlasWeatherLayer = .observations
    @State private var displayedMetric: AtlasMapMetric = .temperature
    @State private var annotationSize: AtlasAnnotationSize = .mediumPlus
    @State private var liveSolarInstant = Date.now
    @State private var showsSolarIllumination = true
    @State private var isShowingMapOptions = false
    
    @AppStorage(
        "atlas.showsWeatherGovAPIActivity"
    )
    private var showsWeatherGovAPIActivity = false
    
    @State private var weatherGovAPIActivitySnapshot =
        WeatherGovAPIActivitySnapshot(
            requestsLastMinute: 0,
            inFlightRequestCount: 0,
            successfulRequestsLastMinute: 0,
            failedRequestsLastMinute: 0,
            observationCacheHitsLastMinute: 0
        )
    
    @State private var showsMaximumStationDensity: Bool = false
    @State private var selectedObservationID: String?
    @State private var visibleObservations:
        [AtlasObservation] = []

    @State private var isLoadingObservations = false
    
    @State private var isLoadingAllNetworksObservations = false
    
    @State private var allNetworksObservationReloadPending = false
    
    @State private var allNetworksPendingForceRefresh = false

    @State private var observationStatusDetail =
        "Open Atlas to load live stations."
    
    @State private var isShowingObservationInfo = false

    @State private var observationSnapshot: AtlasObservationSnapshot?

    @State private var snapshotStore = AviationWeatherSnapshotStore()
    
    @State private var allNetworksObservationSnapshot: AtlasObservationSnapshot?
    
    @State private var weatherGovObservationStore = WeatherGovObservationStore()
    
    @State private var temperatureHistoryStore = AtlasTemperatureHistoryStore()
    
    private let temperatureHistoryService = AviationWeatherTemperatureHistoryService()
    
    private let weatherGovTemperatureHistoryService = WeatherGovTemperatureHistoryService()
    
    @State private var isLoadingWeatherGovTemperatureHistory: Bool = false
    
    @State private var weatherGovTemperatureHistoryReloadPending: Bool = false
    
    @State private var temperatureHistoryRequestedStationIDs: Set<String> = []
    
    @State private var temperatureHistoryReadyStationIDs: Set<String> = []
    
    /// Dictionary would look like
    /// [
    ///     "KDEN": denverExtrema,
    ///     "CYEG": edmontonExtrema
    /// ]
    @State private var temperatureExtremaByStationID: [String: AtlasRollingTemperatureExtrema] = [:]
    
    /// Provider-agnostic forecasts loaded for the current visible station set.
    @State private var forecastSnapshot: AtlasForecastSnapshot?
    
    @State private var forecastSnapshotStore = AtlasForecastSnapshotStore()
    
    @State private var isLoadingForecastSnapshot = false
    
    @State private var forecastStatus = "Forecast layer not loaded."
    
    /// Search field text for the atlas location search.
    @State private var searchQuery = ""
    
    /// Results of the last completed search (stations first, then places).
    @State private var searchResults: [AtlasSearchResult] = []
    
    /// True while a station + MapKit search is in flight.
    @State private var isSearchingAtlas = false
    
    /// A MapKit-only hit shown as a temporary pin. Never backed by an Atlas Observation - the app must
    /// not fabricate live weather.
    @State private var selectedPlaceResult: AtlasSearchResult?
    
    /// Owns the shared 121-frame, five-day playback timeline.
    @State private var forecastTimelineController = ForecastTimelineController()
    
    
    
    /// Derive bounds from MapKit. Whenever visibleRegion changes, visibleBounds is recalculated from it.
    private var visibleBounds: AtlasMapBounds {
        AtlasMapBounds(
            centerLatitude: visibleRegion.center.latitude,
            centerLongitude: visibleRegion.center.longitude,
            latitudeSpan: visibleRegion.span.latitudeDelta,
            longitudeSpan: visibleRegion.span.longitudeDelta
        )
    }
    
    private var isDisplayingRollingTemperatureExtrema: Bool {
        guard weatherLayer == .observations else {
            return false
        }
        
        switch displayedMetric {
        case .temperature:
            return false
        case .dewPoint:
            return false
        case .rolling24HourMaximum:
            return true
        case .rolling24HourMinimum:
            return true
        }
    }
    
    /// One row in the atlas search dropdown. Stations carry an observationID; places are geographic-only hits for
    /// this temporary pin.
    struct AtlasSearchResult: Identifiable {
        enum Kind {
            case station
            case place
        }
        
        let kind: Kind
        let title: String
        let detail: String
        let coordinate: CLLocationCoordinate2D
        let observationID: String?
        let temperatureFahrenheit: Double?
        
        var id: String {
            if let observationID = observationID {
                return observationID
            }
            
            let coordinateKey = String(
                format: "%.6f,%.6f",
                coordinate.latitude,
                coordinate.longitude
            )
            
            return "place-\(coordinateKey)"
        }
    }
    
    @MainActor
    fileprivate func refreshVisibleTemperatureExtrema(
        endingAt windowEnd: Date = .now
    ) async {
        let visibleStationIDs =
            Set(visibleObservations.map(\.id))

        let requestedStationIDs =
            visibleStationIDs
                .intersection(
                    temperatureHistoryReadyStationIDs
                )
                .sorted()

        guard requestedStationIDs.isEmpty == false else {
            temperatureExtremaByStationID = [:]
            return
        }

        let results =
            await temperatureHistoryStore
                .rollingExtrema(
                    for: requestedStationIDs,
                    endingAt: windowEnd
                )

        let currentReadyVisibleIDs =
            Set(visibleObservations.map(\.id))
                .intersection(
                    temperatureHistoryReadyStationIDs
                )

        guard currentReadyVisibleIDs
                == Set(requestedStationIDs) else {
            return
        }

        temperatureExtremaByStationID =
            results
    }
    
    @MainActor
    fileprivate func loadVisibleTemperatureHistory() async {
        // Preserve namespaced IDs inside the provider-agnostic history store,
        // but translate them to plain ICAO IDs at the network boundary.
        
        guard isDisplayingRollingTemperatureExtrema else {
            return
        }
        var aviationIDByNamespacedID: [String: String] = [:]

        for observation in visibleObservations {
            let source = observation.station.source

            guard source.providerID == "aviationWeather" else {
                continue
            }

            let aviationID = source.stationID
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()

            guard aviationID.isEmpty == false else {
                continue
            }

            aviationIDByNamespacedID[observation.id] =
                aviationID
        }

        let visibleNamespacedIDs =
            Set(aviationIDByNamespacedID.keys)

        let newNamespacedIDs = visibleNamespacedIDs
            .subtracting(
                temperatureHistoryRequestedStationIDs
            )
            .sorted()

        guard newNamespacedIDs.isEmpty == false else {
            await refreshVisibleTemperatureExtrema()
            return
        }

        temperatureHistoryRequestedStationIDs
            .formUnion(newNamespacedIDs)

        let batchSize =
            AviationWeatherTemperatureHistoryService
                .maximumStationCount

        for batchStart in stride(
            from: 0,
            to: newNamespacedIDs.count,
            by: batchSize
        ) {
            let batchEnd = min(
                batchStart + batchSize,
                newNamespacedIDs.count
            )

            let namespacedBatch = Array(
                newNamespacedIDs[batchStart..<batchEnd]
            )

            var aviationIDs: [String] = []
            var namespacedIDByAviationID:
                [String: String] = [:]

            for namespacedID in namespacedBatch {
                guard let aviationID =
                        aviationIDByNamespacedID[
                            namespacedID
                        ] else {
                    continue
                }

                aviationIDs.append(aviationID)

                namespacedIDByAviationID[aviationID] =
                    namespacedID
            }

            do {
                let providerSamples =
                    try await temperatureHistoryService
                        .fetchPrevious24Hours(
                            for: aviationIDs
                        )
                
                let namespacedSamples: [AtlasTemperatureHistorySample] =
                    providerSamples.compactMap {
                        sample -> AtlasTemperatureHistorySample? in

                        guard let namespacedID =
                                namespacedIDByAviationID[
                                    sample.stationID
                                ] else {
                            return nil
                        }

                        return AtlasTemperatureHistorySample(
                            stationID: namespacedID,
                            observedAt: sample.observedAt,
                            temperatureFahrenheit:
                                sample.temperatureFahrenheit
                        )
                    }
                
                #if DEBUG
                print(
                    "Atlas history loaded "
                    + "\(namespacedSamples.count) reports for "
                    + "\(aviationIDs)"
                )
                #endif
                
                let loadedNamespacedIDs =
                    Set(
                        namespacedSamples.map(\.stationID)
                    )

                let missingNamespacedIDs =
                    Set(namespacedBatch)
                        .subtracting(
                            loadedNamespacedIDs
                        )

                await temperatureHistoryStore.ingest(
                    namespacedSamples,
                    referenceDate: Date.now
                )

                temperatureHistoryReadyStationIDs
                    .formUnion(
                        loadedNamespacedIDs
                    )

                temperatureHistoryRequestedStationIDs
                    .subtract(
                        missingNamespacedIDs
                    )

                await refreshVisibleTemperatureExtrema()
                
                #if DEBUG
                print(
                    "Rolling extrema available for "
                    + "\(temperatureExtremaByStationID.count) visible stations."
                )
                #endif
            } catch {
                temperatureHistoryRequestedStationIDs
                    .subtract(namespacedBatch)

                print(
                    "Atlas temperature-history batch failed "
                    + "for \(aviationIDs): \(error)"
                )
            }
        }
    }
    
    @MainActor
    fileprivate func loadVisibleWeatherGovTemperatureHistory() async {
        guard stationScope == .allNetworks,
              isDisplayingRollingTemperatureExtrema else {
            return
        }

        if isLoadingWeatherGovTemperatureHistory {
            weatherGovTemperatureHistoryReloadPending =
                true

            return
        }

        var stationsByID:
            [String: AtlasStation] = [:]

        for observation in visibleObservations {
            let station =
                observation.station

            guard station.source.providerID
                    == WeatherGovAPI.providerID else {
                continue
            }

            stationsByID[station.id] =
                station
        }

        let newStations =
            stationsByID
                .values
                .filter {
                    temperatureHistoryRequestedStationIDs
                        .contains($0.id)
                        == false
                }
                .sorted {
                    $0.id < $1.id
                }

        // Show All Stations can expose a very large number of
        // supplemental stations. Limit each deliberate loading
        // pass while preserving the remainder for a later pass.
        let stationsToLoad =
            Array(
                newStations.prefix(40)
            )

        guard stationsToLoad.isEmpty == false else {
            await refreshVisibleTemperatureExtrema()
            return
        }

        isLoadingWeatherGovTemperatureHistory =
            true

        weatherGovTemperatureHistoryReloadPending =
            false

        let windowEnd =
            Date.now

        let pacingClock =
            ContinuousClock()

        for (
            stationIndex,
            station
        ) in stationsToLoad.enumerated() {
            guard Task.isCancelled == false,
                  stationScope == .allNetworks,
                  isDisplayingRollingTemperatureExtrema else {
                break
            }

            let currentlyVisibleStationIDs =
                Set(
                    visibleObservations.map(\.id)
                )

            // Do not spend a request on a station that left the
            // viewport while earlier history was downloading.
            guard currentlyVisibleStationIDs
                    .contains(station.id) else {
                continue
            }

            temperatureHistoryRequestedStationIDs
                .insert(station.id)

            do {
                let samples =
                    try await
                        weatherGovTemperatureHistoryService
                            .fetchPrevious24Hours(
                                for: station,
                                endingAt: windowEnd
                            )

                await temperatureHistoryStore.ingest(
                    samples,
                    referenceDate: windowEnd
                )

                // A successful empty history is still a
                // completed lookup. Its annotation correctly
                // remains an em dash without repeated requests.
                if samples.isEmpty == false {
                    temperatureHistoryReadyStationIDs.insert(station.id)
                }
            } catch is CancellationError {
                temperatureHistoryRequestedStationIDs
                    .remove(station.id)

                break
            } catch {
                temperatureHistoryRequestedStationIDs
                    .remove(station.id)

                #if DEBUG
                print(
                    "Weather.gov history failed for "
                    + "\(station.id): "
                    + error.localizedDescription
                )
                #endif
            }

            // Publish results progressively rather than making
            // every annotation wait for the entire pass.
            await refreshVisibleTemperatureExtrema(
                endingAt: windowEnd
            )

            // Deliberately pace station starts to roughly one
            // per second. Individual stations may paginate.
            if stationIndex
                < stationsToLoad.count - 1 {

                do {
                    try await pacingClock.sleep(
                        for: .seconds(1)
                    )
                } catch {
                    break
                }
            }
        }

        let shouldReloadLatestViewport =
            weatherGovTemperatureHistoryReloadPending

        weatherGovTemperatureHistoryReloadPending =
            false

        isLoadingWeatherGovTemperatureHistory =
            false

        if shouldReloadLatestViewport {
            await loadVisibleWeatherGovTemperatureHistory()
        }
    }
    
    @MainActor
    fileprivate func showSnapshotObservations(
        from snapshot: AtlasObservationSnapshot?,
        in bounds: AtlasMapBounds,
        scope: AtlasStationScope
    ) {
        

        guard let snapshot else {
            visibleObservations = []
            selectedObservationID = nil

            if !isLoadingObservations {
                observationStatusDetail =
                    "Live snapshot not loaded yet."
            }

            return
        }

        let reducedObservations =
            AtlasObservationDensityReducer()
                .observations(
                    from: snapshot,
                    in: bounds,
                    scope: scope,
                    displayedMetric: displayedMetric,
                    annotationSize: annotationSize,
                    showsMaximumDensity: showsMaximumStationDensity,
                    allowedCountryCodes: nil
                )

        visibleObservations =
            reducedObservations

        if let selectedObservationID,
           !reducedObservations.contains(
                where: {
                    $0.id == selectedObservationID
                }
           ) {
            self.selectedObservationID = nil
        }

        let ageMinutes = max(
            Int(
                Date().timeIntervalSince(
                    snapshot.downloadedAt
                ) / 60
            ),
            0
        )

        let ageDescription =
            ageMinutes == 0
                ? "updated now"
                : "\(ageMinutes)m old"

        let reportDescription = scope == .primary
            ? "Metar reports"
            : "combined reports"
        
        observationStatusDetail =
        "\(snapshot.rawReportCount) \(reportDescription) → "
        + "\(snapshot.observations.count) live stations → "
        + "\(reducedObservations.count) shown • "
        + "\(ageDescription)."
    }
    
    @MainActor
    fileprivate func redisplayCurrentObservationSnapshot() {
        let snapshot:
            AtlasObservationSnapshot?

        switch stationScope {
        case .primary:
            snapshot =
                observationSnapshot

        case .allNetworks:
            snapshot =
                allNetworksObservationSnapshot
                ?? observationSnapshot
        }

        showSnapshotObservations(
            from: snapshot,
            in: visibleBounds,
            scope: stationScope
        )
    }

    @MainActor
    private func loadObservationSnapshot(
        forceRefresh: Bool = false
    ) async {
        guard stationScope == .primary,
              !isLoadingObservations else {
            return
        }

        isLoadingObservations = true

        observationStatusDetail =
            observationSnapshot == nil
                ? "Loading worldwide METAR snapshot..."
                : "Refreshing worldwide METAR snapshot..."

        defer {
            isLoadingObservations = false
        }

        do {
            let snapshot =
                try await snapshotStore.snapshot(
                    forceRefresh: forceRefresh
                )

            observationSnapshot = snapshot
            
            await temperatureHistoryStore.ingest(
                snapshot.temperatureHistorySamples,
                referenceDate: snapshot.downloadedAt
            )

            showSnapshotObservations(
                from: snapshot,
                in: visibleBounds,
                scope: stationScope
            )
            await loadVisibleTemperatureHistory()
        } catch {
            if let cachedSnapshot =
                    await snapshotStore
                        .cachedSnapshot() {

                observationSnapshot = cachedSnapshot
                
                await temperatureHistoryStore.ingest(
                    cachedSnapshot.temperatureHistorySamples,
                    referenceDate: cachedSnapshot.downloadedAt
                )

                showSnapshotObservations(
                    from: cachedSnapshot,
                    in: visibleBounds,
                    scope: stationScope
                )
                await loadVisibleTemperatureHistory()

                observationStatusDetail +=
                    " Refresh failed; cached data retained."
            } else {
                visibleObservations = []

                observationStatusDetail =
                    "Station snapshot failed: "
                    + error.localizedDescription
            }
        }
    }
    
    @MainActor
    fileprivate func loadAllNetworksObservationSnapshot(
        forceRefresh: Bool = false
    ) async {
        guard stationScope == .allNetworks else {
            return
        }

        if isLoadingAllNetworksObservations {
            allNetworksObservationReloadPending = true
            allNetworksPendingForceRefresh =
                allNetworksPendingForceRefresh || forceRefresh
            return
        }

        guard let primarySnapshot = observationSnapshot else {
            observationStatusDetail =
                "The METAR base must finish loading "
                + "before All Networks can load."
            return
        }

        let requestedBounds = visibleBounds

        guard requestedBounds.longitudeSpan <= 8,
              requestedBounds.latitudeSpan <= 8 else {
            showSnapshotObservations(
                from: primarySnapshot,
                in: requestedBounds,
                scope: .allNetworks
            )

            observationStatusDetail =
                "METAR is shown at this scale. "
                + "Zoom into a region smaller than "
                + "8° x 8° to load All Networks."

            return
        }

        let supplementalBounds =
            requestedBounds.padded(
                by: 0.15,
                maximumDegreesPerEdge: 0.35
            )

        isLoadingAllNetworksObservations = true

        observationStatusDetail =
            "Loading supplemental stations "
            + "for the visible region..."

        defer {
            isLoadingAllNetworksObservations = false

            if stationScope == .allNetworks,
               allNetworksObservationReloadPending {
                let shouldForceRefresh =
                    allNetworksPendingForceRefresh

                allNetworksObservationReloadPending = false
                allNetworksPendingForceRefresh = false

                Task {
                    await loadAllNetworksObservationSnapshot(
                        forceRefresh: shouldForceRefresh
                    )
                }
            } else {
                allNetworksObservationReloadPending = false
                allNetworksPendingForceRefresh = false
            }
        }

        let cachedSupplementalSnapshot =
            await weatherGovObservationStore.cachedSnapshot(
                in: supplementalBounds
            )

        guard Task.isCancelled == false,
              stationScope == .allNetworks,
              requestedBounds == visibleBounds else {
            return
        }

        if cachedSupplementalSnapshot
            .observations
            .isEmpty == false {
            let cachedMergedSnapshot =
                AtlasObservationSnapshotMerger.merged(
                    primary: primarySnapshot,
                    supplemental:
                        cachedSupplementalSnapshot
                )

            allNetworksObservationSnapshot =
                cachedMergedSnapshot

            showSnapshotObservations(
                from: cachedMergedSnapshot,
                in: requestedBounds,
                scope: .allNetworks
            )

            observationStatusDetail +=
                " Refreshing supplemental stations..."
        }

        do {
            /// The small margin avoids stations popping in and out
            /// along the exact screen boundary.
            let supplementalSnapshot =
                try await weatherGovObservationStore.snapshot(
                    in: supplementalBounds,
                    forceRefresh: forceRefresh
                )

            guard Task.isCancelled == false,
                  stationScope == .allNetworks,
                  requestedBounds == visibleBounds else {
                return
            }

            let mergedSnapshot =
                AtlasObservationSnapshotMerger.merged(
                    primary: primarySnapshot,
                    supplemental: supplementalSnapshot
                )

            allNetworksObservationSnapshot = mergedSnapshot

            showSnapshotObservations(
                from: mergedSnapshot,
                in: requestedBounds,
                scope: .allNetworks
            )

            Task {
                await temperatureHistoryStore.ingest(
                    supplementalSnapshot.temperatureHistorySamples,
                    referenceDate: supplementalSnapshot.downloadedAt
                )

                await loadVisibleTemperatureHistory()
                await loadVisibleWeatherGovTemperatureHistory()
            }
        } catch is CancellationError {
            return
        } catch {
            guard stationScope == .allNetworks,
                  requestedBounds == visibleBounds else {
                return
            }

            let fallbackSnapshot =
                allNetworksObservationSnapshot
                ?? primarySnapshot

            showSnapshotObservations(
                from: fallbackSnapshot,
                in: visibleBounds,
                scope: .allNetworks
            )

            observationStatusDetail =
                "Supplemental Weather.gov loading failed; "
                + "cached data retained. "
                + error.localizedDescription
        }
    }
    
    /// Loads forecasts for the Atlas's current reduced visible-station set.
    @MainActor
    fileprivate func loadVisibleForecastSnapshot(
        forceRefresh: Bool = false
    ) async {
        guard stationScope == .primary,
              isLoadingForecastSnapshot == false else {
            return
        }
        
        let requestedObservations = visibleObservations
        
        guard requestedObservations.isEmpty == false else {
            forecastSnapshot = nil
            
            forecastTimelineController
                .replaceAvailableInstants([])
            
            forecastStatus = "No visible stations are available for forecasting."
            
            return
        }
        
        isLoadingForecastSnapshot = true
        
        forecastStatus =
            "Loading forecasts for "
        + "\(requestedObservations.count) visible stations..."
        
        defer {
            isLoadingForecastSnapshot = false
        }
        
        let loadedSnapshot =
        await forecastSnapshotStore.snapshot(
            for: requestedObservations,
            forceRefresh: forceRefresh,
            maximumConcurrentRequests: 8
        )
        
        forecastSnapshot = loadedSnapshot
        
        forecastTimelineController
            .replaceWithHourlyForecastTimeline(startingAt: loadedSnapshot.loadedAt)
        
        forecastStatus =
        "\(loadedSnapshot.loadedStationCount)"
        + "/\(loadedSnapshot.requestedStationCount)"
        + "station forecasts loaded"
        
        if loadedSnapshot.failedStationCount > 0 {
            forecastStatus +=
            " • \(loadedSnapshot.failedStationCount)"
        }
        
        forecastStatus += "."
    }
    
    /// Resolves one station's temperature at the currently-selected
    /// shared Atlas forecast instant.
    @MainActor
    fileprivate func forecastTemperatureFahrenheit(
        for observation: AtlasObservation,
        validAt selectedInstant: Date?
    ) -> Double? {
        guard weatherLayer == .forecast,
              let selectedInstant, let stationForecast = forecastSnapshot?.forecast(for: observation),
              let forecastTemperature =
                ForecastSampleResolver.airTemperature(
                    in: stationForecast,
                    validAt: selectedInstant
                ) else {
            return nil
        }
        
        return forecastTemperature.fahrenheit
    }
    
    /// Station search index rebuilt from the current live snapshot.
    /// Each entry already carrier the joined catalog metadata
    /// (name, state/province, country), which the METAR snapshot alone does not.
    private var stationLookup: [AtlasObservation] {
        observationSnapshot?.observations ?? []
    }
    
    /// Runs the two-state search: local live stations first, then MapKit
    /// places that no nearby live station already covers.
    @MainActor
    fileprivate func performAtlasSearch(
        query: String
    ) async {
        let trimmedQuery =
            query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmedQuery.isEmpty == false else {
            searchResults = []
            isSearchingAtlas = false
            return
        }
        
        isSearchingAtlas = true
        defer {
            isSearchingAtlas = false
        }
        
        let lookup = stationLookup
        
        /// Stage 1: match live stations by name or ICAO id.
        let stationMatches =
            lookup
            .filter {
                $0.station.name
                    .localizedCaseInsensitiveContains(trimmedQuery)
                || $0.station.source.stationID
                    .localizedCaseInsensitiveContains(trimmedQuery)
            }
            .sorted {
                let firstIsNameHit =
                $0.station.name
                    .localizedCaseInsensitiveContains(trimmedQuery)
                let secondIsNameHit =
                $1.station.name
                    .localizedCaseInsensitiveContains(trimmedQuery)
                
                if firstIsNameHit != secondIsNameHit {
                    return firstIsNameHit
                }
                
                if $0.station.source.countryCode != $1.station.source.countryCode {
                    return $0.station.source.countryCode < $1.station.source.countryCode
                }
                
                return $0.station.source.stationID < $1.station.source.stationID
            }
            .prefix(6)
        
        var results: [AtlasSearchResult] =
        stationMatches.map {
            let station = $0.station
            
            let area = station.administrativeAreaCode ?? station.source.countryCode
            
            return AtlasSearchResult(
                kind: .station,
                title: station.name,
                detail: "\(station.source.stationID) x \(area) \(station.source.countryCode)",
                coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude),
                observationID: $0.id,
                temperatureFahrenheit: $0.temperatureFahrenheit
            )
        }
        
        /// State 2: MapKit place search for geographic locations with no live station nearby, like 'Pahrump'
        do {
            let request = MKLocalSearch.Request()
            
            request.naturalLanguageQuery = trimmedQuery
            request.resultTypes = .address.union(.pointOfInterest)
            
            let placeResponse = try await MKLocalSearch(request: request).start()
            
            let coveredStationIDs = Set(
                stationMatches.map(\.id)
            )
            
            for mapItem in placeResponse.mapItems.prefix(5) {
                let coordinate = mapItem.placemark.coordinate
                
                /// A place is redundant when a live station within 25km already exists - that station
                /// is the real answer for this location.
                let nearbyLive =
                lookup.first {
                    $0.station.latitude.distance(to: coordinate.latitude) < 0.23
                    &&
                    $0.station.longitude.distance(to: coordinate.longitude) < 0.23
                }
                
                if let nearbyLive {
                    if !coveredStationIDs.contains(nearbyLive.id) {
                        let station = nearbyLive.station
                        
                        let area = station.administrativeAreaCode ?? station.source.countryCode
                        
                        results.append(
                            AtlasSearchResult(
                                kind: .station,
                                title: station.name,
                                detail: "\(station.source.stationID) - \(area) \(station.source.countryCode)",
                                coordinate: CLLocationCoordinate2D(
                                    latitude: station.latitude,
                                    longitude: station.longitude
                                ),
                                observationID: nearbyLive.id,
                                temperatureFahrenheit: nearbyLive.temperatureFahrenheit
                            )
                        )
                    }
                    continue
                }
                let placemark = mapItem.placemark
                
                let placeDetail =
                    [
                        placemark.locality,
                        placemark.administrativeArea,
                        placemark.country
                    ]
                    .compactMap { $0 }
                    .filter {
                        $0.isEmpty == false
                    }
                    .joined(separator: " x ")
                
                results.append(
                    AtlasSearchResult(
                        kind: .place,
                        title: mapItem.name ?? trimmedQuery,
                        detail: placeDetail,
                        coordinate: coordinate,
                        observationID: nil,
                        temperatureFahrenheit: nil
                    )
                )
            }
        } catch {
            /// Mapkit failures (offline, bad query) degrade to station-only results instead of killing the search.
        }
        
        /// Guard against a stale response landing after the user has already typed a new query.
        guard searchQuery
            .trimmingCharacters(in: .whitespacesAndNewlines) == trimmedQuery
        else {
            return
        }
        
        searchResults = results
    }
    
    var body: some View {
        let selectedForecastInstant = forecastTimelineController.selectedInstant
        let solarIlluminationInstant =
        weatherLayer == .forecast
            ? selectedForecastInstant ?? liveSolarInstant
            : liveSolarInstant
        
        let solarEphemeris =
            SolarPositionCalculator.ephemeris(at: solarIlluminationInstant)
        
        
        /// Entire window, arranged top-to-bottom
        VStack(alignment: .leading, spacing: -13) {
            
            VStack(spacing: 0) {
                /// Header, arranged left-to-right.
                HStack {
                    ///Title block "Climate Atlas", "Point, choose, understand." Top left
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .center, spacing: 8) {
                            Text("Climate Atlas")
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                                
                            
                            Button {
                                isShowingObservationInfo.toggle()
                            } label: {
                                Image(systemName: "info.circle.fill")
                                    .symbolRenderingMode(.monochrome)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(DashboardTheme.forecastTemperature)
                            }
                            .buttonStyle(.plain)
                            
                            .contentShape(Rectangle())
                            
                            /// Attach the popover directly to the info button, uses weatherLayer to
                            /// choose between forecast status and the richer observation status,
                            /// builds the obs panel with freshness indicator, report/station/visible counts,
                            /// divider and update age. Wraps everything in a common VStack then applied
                            /// padding and minimum width once.
                            .popover(isPresented: $isShowingObservationInfo) {
                                VStack(alignment: .leading, spacing: 10) {
                                    if weatherLayer == .forecast {
                                        Text(forecastStatus)
                                            .font(.subheadline)
                                    } else {
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Circle()
                                                    .fill(displayedSnapshotFreshnessColor)
                                                    .frame(width: 8, height: 8)
                                                Text("Atlas Status")
                                                    .font(.headline)
                                            }
                                            
                                            Group {
                                                Text("\(observationSnapshot?.rawReportCount ?? 0) worldwide reports")
                                                Text("\(observationSnapshot?.observations.count ?? 0) live stations")
                                                Text("\(visibleObservations.count) currently shown")
                                            }
                                            .font(.subheadline)
                                            .foregroundStyle(DashboardTheme.textSecondary)
                                            
                                            Divider()
                                            
                                            let age = observationSnapshot.map {
                                                max(
                                                    0, liveSolarInstant.timeIntervalSince($0.downloadedAt)
                                                )
                                            } ?? 0
                                            
                                            Text(observationSnapshot == nil ? "No snapshot loaded" :
                                                age < 60 ? "Updated just now" :
                                                age < 3600 ? "Updated \(Int(age / 60)) minutes ago" :
                                                "Updated \(Int(age / 3600)) hours ago")
                                                .font(.caption)
                                                .foregroundStyle(DashboardTheme.textSecondary)
                                        }
                                    }
                                }
                                .padding()
                                .frame(minWidth: 280)
                            }
                        }
                        
                        Text("Point, choose, understand.")
                            .foregroundStyle(DashboardTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    HStack(
                        alignment: .top,
                        spacing: 12
                    ) {
                        atlasDisplayControls
                    }
                }
                /// Controls 'Refresh forecast' and how many stations loaded on the top left of the view.
                /// The button is centered under the Dashboard | Atlas picker
                /// via the overlay; the search field keeps the left edge.
                HStack(
                    alignment: .center,
                    spacing: 12
                ) {
                    atlasSearchField
                    
                    Spacer()
                }
                .overlay {
                    HStack(spacing: 8) {
                        refreshAction
                        showAllStationsAction
                    }
                }
                .offset(y: -20)
            }
            
            ///$cameraPosition is two-way binding. The map can update the stored camera when the user moves it.
            Map(position: $cameraPosition) {
                if showsSolarIllumination {
                    AtlasSolarIlluminationLayer(ephemeris: solarEphemeris)
                }
                if let selectedPlaceResult {
                    Annotation(
                        selectedPlaceResult.title,
                        coordinate: selectedPlaceResult.coordinate,
                        anchor: .bottom
                    ) {
                        VStack(spacing: 3) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 30))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, DashboardTheme.forecastTemperature)
                            
                            Text(selectedPlaceResult.title)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(1)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                    }
                }
                ForEach(visibleObservations) { observation in
                    Annotation(
                        observation.station.name,
                        coordinate: CLLocationCoordinate2D(
                            latitude:
                                observation.station.latitude,
                            longitude:
                                observation.station.longitude
                        ),
                        anchor: .center
                    ) {
                        Button {
                            if selectedObservationID
                                == observation.id {
                                selectedObservationID = nil
                            } else {
                                selectedObservationID =
                                observation.id
                            }
                        } label: {
                            AtlasTemperatureAnnotationView(
                                observation: observation,
                                displayedMetric: displayedMetric,
                                annotationSize: annotationSize,
                                weatherLayer: weatherLayer,
                                rollingTemperatureExtrema:
                                    temperatureExtremaByStationID[observation.id],
                                forecastTemperatureFahrenheit:
                                    forecastTemperatureFahrenheit(
                                        for: observation,
                                        validAt:
                                            selectedForecastInstant
                                    )
                            )
                            
                        }
                        .buttonStyle(.plain)
                        .popover(
                            isPresented: Binding(
                                get: {
                                    selectedObservationID
                                    == observation.id
                                },
                                set: { isPresented in
                                    if !isPresented {
                                        selectedObservationID = nil
                                    }
                                }
                            ),
                            arrowEdge: .bottom
                        ) {
                            AtlasStationCardView(
                                observation: observation
                            ) {
                                
                                selectedObservationID = nil
                                onBuildClimateProfile(observation)
                            }
                        }
                    }
                }
            }
                .mapStyle(
                    .standard(elevation: .realistic)
                )
                /// Compass scale, zoom stepper are native MapKit controls.
                .mapControls {
                    MapCompass()
                    MapScaleView()
                    MapZoomStepper()
                }
                .onMapCameraChange(
                    frequency: .onEnd
                ) { context in
                    ///context.region is MapKit's approximation of the map area currently visible. Apple's .onEnd
                    ///frequency waits until the map interation/scrubbing finishes, rather than firing constantly while the mouse is
                    ///moving. This will help us avoid hammering a weather API with dozens of requests with one drag of the mouse.
                    let newBounds = AtlasMapBounds(
                        centerLatitude: context.region.center.latitude,
                        centerLongitude: context.region.center.longitude,
                        latitudeSpan: context.region.span.latitudeDelta,
                        longitudeSpan: context.region.span.longitudeDelta
                    )
                    
                    visibleRegion = context.region
                    selectedPlaceResult = nil
                    searchResults = []
                    switch stationScope {
                    case .primary:
                        showSnapshotObservations(
                            from: observationSnapshot,
                            in: newBounds,
                            scope: .primary
                        )
                        
                        Task { await loadVisibleTemperatureHistory() }
                    case .allNetworks:
                        /// Immediately reuse the merged snapshot already held in RAM while checking the new viewport
                        showSnapshotObservations(
                            from: allNetworksObservationSnapshot ?? observationSnapshot,
                            in: newBounds,
                            scope: .allNetworks
                        )
                        
                        Task { await loadAllNetworksObservationSnapshot() }
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            /// Map's border overlay
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: DashboardTheme.cardCornerRadius
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: DashboardTheme.cardCornerRadius
                    )
                    .stroke(DashboardTheme.border)
                    /// Ensures the decorative border cannot intercept map clicks or dragging.
                    .allowsHitTesting(false)
                }
                .overlay(alignment: .topTrailing) {
                    VStack(
                        alignment: .trailing,
                        spacing: 8
                    ) {
                        mapOptionsButton
                        
                        if showsWeatherGovAPIActivity {
                            WeatherGovAPIActivityBadge(snapshot: weatherGovAPIActivitySnapshot)
                                .transition(
                                    .opacity
                                        .combined(
                                            with: .move(
                                                edge: .top
                                            )
                                        )
                                )
                        }
                    }
                    .padding(12)
                    .animation(
                        .easeInOut(duration: 0.18),
                        value: showsWeatherGovAPIActivity
                    )
                }
            
                /// This diagnostic means center is the latitude & longitude at the middle of the screen.
            /// Span is approx how many degrees of
                /// latitude and longitude are visible. Small span means user is zoomed in.
            /// Shows the latitude range box in the upper left of the map view
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(
                            "Center \(visibleRegion.center.latitude, specifier: "%.2f")°, \(visibleRegion.center.longitude, specifier: "%.2f")°"
                        )

                        Text(
                            "N \(visibleBounds.north, specifier: "%.2f")°  S \(visibleBounds.south, specifier: "%.2f")°  W \(visibleBounds.west, specifier: "%.2f")°  E \(visibleBounds.east, specifier: "%.2f")°"
                        )

                        if visibleBounds.crossesAntimeridian {
                            Text("Visible region crosses 180° longitude")
                                .foregroundStyle(.orange)
                        }
                    }
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(DashboardTheme.textPrimary)
                    .padding(8)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .padding(12)
                    .allowsHitTesting(false)
                }
                .overlay(alignment: .topLeading) {
                    if searchQuery.isEmpty == false,
                       searchResults.isEmpty == false || isSearchingAtlas == false {
                        searchResultsDropdown
                            .padding(.top, 8)
                            .padding(.leading, 12)
                    }
                }
            /// Map reclaims timeline's reserved vertical space. The timeline floats over the bottom of the map.
            /// 
                .overlay(alignment: .bottom) {
                    if weatherLayer == .forecast {
                        AtlasForecastTimelineView(controller: forecastTimelineController)
                            .frame(maxWidth: 900)
                            .padding(.horizontal, 120)
                            .padding(.bottom, 16)
                    }
                }
        }
        .padding(10)
        
        /// Lets the Atlas fill the whole application window.
        .frame(
            minWidth: 900,
            maxWidth: .infinity,
            minHeight: 600,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .foregroundStyle(DashboardTheme.textPrimary)
        .background(DashboardTheme.canvas)
        
        /// Load the zip when atlas is loaded.
        .task {
            guard selectedAppSection == .atlas else {
                return
            }
            
            await loadObservationSnapshot()
        }
        
        .task {
            let clock = ContinuousClock()
            
            while !Task.isCancelled {
                liveSolarInstant = Date.now
                
                do {
                    try await clock.sleep(for: .seconds(60))
                } catch {
                    return
                }
            }
        }
        /// Polls only the actor's RAM state. Does not touch weather.gov
        .task(
            id: showsWeatherGovAPIActivity
        ) {
            guard showsWeatherGovAPIActivity else {
                return
            }
            
            let clock = ContinuousClock()
            
            while !Task.isCancelled {
                weatherGovAPIActivitySnapshot = await WeatherGovAPIActivityMeter
                    .shared
                    .snapshot()
                
                do {
                    try await clock.sleep(
                        for: .seconds(1)
                    )
                } catch {
                    return
                }
            }
        }
        
        .onChange(
            of: selectedAppSection
        ) {_, newSection in
            guard newSection == .atlas else {
                return
            }
            
            Task {
                await loadObservationSnapshot()
            }
        }
        
        .onChange(
            of: displayedMetric
        ) { _, newMetric in
            guard weatherLayer == .observations else {
                return
            }
            
            switch newMetric {
            case .rolling24HourMaximum, .rolling24HourMinimum:
                
                Task {
                    await loadVisibleTemperatureHistory()
                    
                    await loadVisibleWeatherGovTemperatureHistory()
                }
                
            case .temperature, .dewPoint:
                break
            }
            
        }
    }
    
    fileprivate var atlasDisplayControls: some View {
        VStack(
            alignment: .trailing,
            spacing: 8
        ) {
            HStack(spacing: 10) {
                Text("Station Scope")
                    .font(.caption)
                    .foregroundStyle(DashboardTheme.textSecondary)
                    .frame(width: 90, alignment: .trailing)
                
                Picker(
                    "Station Scope",
                    selection: $stationScope
                ) {
                    ForEach(
                        AtlasStationScope.allCases
                    ) { scope in
                        Text(scope.rawValue)
                            .tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 284)
                .onChange(
                    of: stationScope
                ) { _, newScope in
                    selectedObservationID = nil
                    
                    switch newScope {
                    case .primary:
                        showSnapshotObservations(
                            from: observationSnapshot,
                            in: visibleBounds,
                            scope: .primary
                        )
                        
                        Task {
                            await loadVisibleTemperatureHistory()
                        }
                    case .allNetworks:
                        showSnapshotObservations(
                            from: allNetworksObservationSnapshot ?? observationSnapshot,
                            in: visibleBounds,
                            scope: .allNetworks
                        )
                        
                        Task {
                            await loadAllNetworksObservationSnapshot()
                        }
                    }
                }
            }
            
            HStack(spacing: 10) {
                Text("Weather Layer")
                    .font(.caption)
                    .foregroundStyle(DashboardTheme.textSecondary)
                    .frame(width: 90, alignment: .trailing)
                
                Picker(
                    "Weather Layer",
                    selection: $weatherLayer
                ) {
                    ForEach(AtlasWeatherLayer.allCases) { layer in
                        Text(layer.rawValue)
                            .tag(layer)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 284)
                .onChange(of: weatherLayer) { _, newLayer in
                    selectedObservationID = nil
                    
                    switch newLayer {
                    case .observations:
                        forecastTimelineController.pause()
                        
                    case .forecast:
                        displayedMetric = .temperature
                        
                        if showsMaximumStationDensity {
                            showsMaximumStationDensity = false
                            redisplayCurrentObservationSnapshot()
                        }
                        
                        Task {
                            await loadVisibleForecastSnapshot()
                        }
                    }
                }
            }
        }
    }
    /// Make the map options button look like the station settings on the dashboard.
    
    fileprivate var mapOptionsButton: some View {
        Button {
            isShowingMapOptions.toggle()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "gearshape.fill")
                    .symbolRenderingMode(.monochrome)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DashboardTheme.forecastTemperature)
                
                Text("Map Options")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DashboardTheme.textPrimary)
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: 140, height: 32)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(DashboardTheme.panelElevated.opacity(0.88))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(DashboardTheme.border, lineWidth: 1)
                .allowsHitTesting(false)
        }
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help("Map Options")
        .popover(
            isPresented: $isShowingMapOptions,
            arrowEdge: .top
        ) {
            AtlasMapOptionsView(
                displayedMetric: $displayedMetric,
                annotationSize: $annotationSize,
                showsSolarIllumination: $showsSolarIllumination,
                showsWeatherGovAPIActivity: $showsWeatherGovAPIActivity
            )
        }
    }
    
    /// Search field with a clear button and the debounced result dropdown. Results overlay under the field, so the
    /// map and header layout are untouched.
    fileprivate var atlasSearchField: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DashboardTheme.textSecondary)
            
            TextField(
                "Search location, station, or ICAO ID",
                text: $searchQuery
            )
            .textFieldStyle(.plain)
            .font(.subheadline)
            .lineLimit(1)
            .onExitCommand {
                searchResults = []
            }
            if isSearchingAtlas {
                ProgressView()
                    .controlSize(.small)
            } else if searchQuery.isEmpty == false {
                Button {
                    searchQuery = ""
                    searchResults = []
                    selectedPlaceResult = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(DashboardTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Clear search")
            }
        }
        .padding(.horizontal, 10)
        .frame(width: 300, height: 32)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(DashboardTheme.panelElevated.opacity(0.88))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(DashboardTheme.border, lineWidth: 1)
                .allowsHitTesting(false)
        }
        
        .task(id: searchQuery) {
            try? await Task.sleep(for: .milliseconds(300))
            
            await performAtlasSearch(query: searchQuery)
        }
    }
    
    /// Dropdown of the station and place matches. Station rows select the real observation and
    /// pop the existing card; place rows drop the temporary pin only.
    fileprivate var searchResultsDropdown: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(searchResults.prefix(8)) { result in
                searchResultRow(result)
            }
            
            if searchResults.isEmpty,
               isSearchingAtlas == false {
                Text("No matches for \(searchQuery)")
                    .font(.caption)
                    .foregroundStyle(DashboardTheme.textSecondary)
                    .padding(.vertical, 8)
            }
        }
        .frame(width: 340)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(DashboardTheme.panel)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(DashboardTheme.border, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.250), radius: 10, y: 4)
    }
    
    fileprivate func searchResultRow(
        _ result: AtlasSearchResult
    ) -> some View {
        Button {
            selectSearchResult(result)
        } label: {
            HStack(spacing: 8) {
                Image(systemName:
                        result.kind == .station
                        ? "antenna.radiowaves.left.and.right"
                      : "mappin.and.ellipse")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(
                    result.kind == .station
                    ? DashboardTheme.success
                    : DashboardTheme.forecastTemperature
                )
                .frame(width: 16)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(result.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    
                    Text(result.detail)
                        .font(.caption)
                        .foregroundStyle(DashboardTheme.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 8)
                
                if let temperatureFahrenheit = result.temperatureFahrenheit {
                    Text(
                        String(
                            format: "%.0f°F",
                            temperatureFahrenheit
                        )
                    )
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(DashboardTheme.textPrimary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(DashboardTheme.textPrimary)
    }
    
    /// Station hits move the camera, select the real observation (which opens the existing card), and clear the pin.
    /// Place hits only move the camera and drop the temporary pin.
    fileprivate func selectSearchResult(
        _ result: AtlasSearchResult
    ) {
        searchResults = []
        selectedPlaceResult = nil
        
        let targetRegion = MKCoordinateRegion(
            center: result.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.6, longitudeDelta: 0.6)
        )
        
        withAnimation(.easeInOut(duration: 0.8)) {
            cameraPosition = .region(targetRegion)
        }
        
        if let observationID = result.observationID {
            selectedObservationID = observationID
        } else {
            selectedPlaceResult = result
        }
    }
    
    /// Display the timestamp.
    fileprivate var displayedSnapshotTimestamp: Date? {
        switch weatherLayer {
        case .observations:
            if stationScope == .allNetworks {
                return allNetworksObservationSnapshot?.downloadedAt
                ?? observationSnapshot?.downloadedAt
            }
            
            return observationSnapshot?.downloadedAt
        case .forecast:
            return forecastSnapshot?.loadedAt
        }
    }
    
    /// Freshness color. How stale or fresh are these observations?
    fileprivate var displayedSnapshotFreshnessColor: Color {
        guard let timestamp = displayedSnapshotTimestamp else {
            return DashboardTheme.failure
        }
        
        let age = max(
            0, liveSolarInstant.timeIntervalSince(timestamp)
        )
        /// Data age in seconds
        switch age {
        case ..<300:
            return DashboardTheme.success
            
        case ..<900:
            return .yellow
            
        default:
            return DashboardTheme.failure
        }
    }
    
    fileprivate var showAllStationsAction: some View {
        Button {
            showsMaximumStationDensity.toggle()
            redisplayCurrentObservationSnapshot()
            
            Task {
                await loadVisibleWeatherGovTemperatureHistory()
            }
        } label: {
            HStack(spacing: 7) {
                Image(
                    systemName:
                        showsMaximumStationDensity
                        ? "checkmark.circle.fill"
                        : "square.grid.3x3.fill"
                )
                .symbolRenderingMode(.monochrome)
                .font(
                    .system(
                        size: 13,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    DashboardTheme.forecastTemperature
                )

                Text("Show All Stations")
                    .font(
                        .subheadline
                            .weight(.semibold)
                    )
                    .foregroundStyle(
                        DashboardTheme.textPrimary
                    )
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(
            width: 210,
            height: 32
        )
        .background {
            RoundedRectangle(
                cornerRadius: 8,
                style: .continuous
            )
            .fill(
                showsMaximumStationDensity
                ? DashboardTheme
                    .forecastTemperature
                    .opacity(0.20)
                : DashboardTheme
                    .panelElevated
                    .opacity(0.88)
            )
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: 8,
                style: .continuous
            )
            .stroke(
                showsMaximumStationDensity
                ? DashboardTheme
                    .forecastTemperature
                    .opacity(0.75)
                : DashboardTheme.border,
                lineWidth: 1
            )
            .allowsHitTesting(false)
        }
        .contentShape(
            RoundedRectangle(
                cornerRadius: 8,
                style: .continuous
            )
        )
        .help(
            showsMaximumStationDensity
            ? "Return to automatic station density"
            : "Show every loaded station. API request safeguards remain active."
        )
        .disabled(
            weatherLayer == .forecast
        )
        .opacity(
            weatherLayer == .forecast
            ? 0.48
            : 1
        )
    }
    
    fileprivate var refreshAction: some View {
        Button {
            Task {
                switch weatherLayer {
                case .observations:
                    switch stationScope {
                    case .primary:
                        await loadObservationSnapshot(forceRefresh: true)
                    case .allNetworks:
                        await loadAllNetworksObservationSnapshot(forceRefresh: true)
                    }
                case .forecast:
                    await loadVisibleForecastSnapshot(forceRefresh: true)
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(displayedSnapshotFreshnessColor)
                    .frame(width: 8, height: 8)
                    .shadow(
                        color:
                            displayedSnapshotFreshnessColor
                                .opacity(0.45),
                        radius: 3
                    )
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(.leading, 12)
                    .accessibilityLabel("Data freshness")

                HStack(spacing: 7) {
                    Image(
                        systemName:
                            "arrow.trianglehead.2.clockwise.rotate.90"
                    )
                    .symbolRenderingMode(.monochrome)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(
                        DashboardTheme.forecastTemperature
                    )

                    Text(
                        weatherLayer == .forecast
                            ? "Refresh Forecast"
                            : "Refresh Live Data"
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(
                        DashboardTheme.textPrimary
                    )
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(
            width: 220,
            height: 32
        )
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(DashboardTheme.panelElevated.opacity(0.88))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(DashboardTheme.border, lineWidth: 1)
                .allowsHitTesting(false)
        }
        .contentShape(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .help(
            weatherLayer == .forecast
            ? "Refresh visible forecasts"
            : "Refresh live stations observations"
        )
        .disabled(
            weatherLayer == .forecast
            ? ( stationScope != .primary || isLoadingForecastSnapshot )
            : ( stationScope == .primary
                    ? isLoadingObservations
                    : isLoadingAllNetworksObservations
            )
        )
    }
}
