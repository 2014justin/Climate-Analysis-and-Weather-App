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
    private static let initialRegion = MKCoordinateRegion(
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
    @State private var displayedMetric: AtlasMapMetric = .temperature
    @State private var annotationSize: AtlasAnnotationSize = .medium
    @State private var isShowingMapOptions = false
    @State private var selectedObservationID: String?
    @State private var visibleObservations:
        [AtlasObservation] = []

    @State private var isLoadingObservations = false

    @State private var observationStatus =
        "Open Atlas to load live stations."

    @State private var observationSnapshot:
        AtlasObservationSnapshot?

    @State private var snapshotStore =
        AviationWeatherSnapshotStore()
    
    /// Derive bounds from MapKit. Whenever visibleRegion changes, visibleBounds is recalculated from it.
    private var visibleBounds: AtlasMapBounds {
        AtlasMapBounds(
            centerLatitude: visibleRegion.center.latitude,
            centerLongitude: visibleRegion.center.longitude,
            latitudeSpan: visibleRegion.span.latitudeDelta,
            longitudeSpan: visibleRegion.span.longitudeDelta
        )
    }
    
    @MainActor
    private func showSnapshotObservations(
        from snapshot: AtlasObservationSnapshot?,
        in bounds: AtlasMapBounds,
        scope: AtlasStationScope
    ) {
        guard scope == .primary else {
            visibleObservations = []
            selectedObservationID = nil

            observationStatus =
                "All Networks loading will be added after the primary layer."

            return
        }

        guard let snapshot else {
            visibleObservations = []
            selectedObservationID = nil

            if !isLoadingObservations {
                observationStatus =
                    "Live snapshot not loaded yet."
            }

            return
        }

        let reducedObservations =
            AtlasObservationDensityReducer()
                .observations(
                    from: snapshot,
                    in: bounds,
                    allowedCountryCodes: ["US", "CA"]
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

        observationStatus =
            "\(snapshot.rawReportCount) worldwide reports → "
            + "\(snapshot.observations.count) live stations → "
            + "\(reducedObservations.count) shown • "
            + "\(ageDescription)."
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

        observationStatus =
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

            showSnapshotObservations(
                from: snapshot,
                in: visibleBounds,
                scope: stationScope
            )
        } catch {
            if let cachedSnapshot =
                    await snapshotStore
                        .cachedSnapshot() {

                observationSnapshot =
                    cachedSnapshot

                showSnapshotObservations(
                    from: cachedSnapshot,
                    in: visibleBounds,
                    scope: stationScope
                )

                observationStatus +=
                    " Refresh failed; cached data retained."
            } else {
                visibleObservations = []

                observationStatus =
                    "Station snapshot failed: "
                    + error.localizedDescription
            }
        }
    }
    
    var body: some View {
        /// Entire window, arranged top-to-bottom
        VStack(alignment: .leading, spacing: 16) {
            /// Header, arranged left-to-right.
            HStack {
                ///Title block "Climate Atlas", "Point, choose, understand."
                VStack(alignment: .leading, spacing: 4) {
                    Text("Climate Atlas")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                    
                    Text("Point, choose, understand.")
                        .foregroundStyle(DashboardTheme.textSecondary)
                }
                
                Spacer()
                
                
                Picker("Station scope", selection: $stationScope) {
                    ForEach(AtlasStationScope.allCases) { scope in
                        Text(scope.rawValue)
                            .tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
                
                .onChange(
                    of: stationScope
                ) {_, newScope in
                    showSnapshotObservations(
                        from: observationSnapshot,
                        in: visibleBounds,
                        scope: newScope,
                    )
                }
                
                /// Map Options User Interface
                Button {
                    isShowingMapOptions.toggle()
                } label: {
                    Label(
                        "Map Options",
                        systemImage: "gearshape"
                    )
                }
                .buttonStyle(.bordered)
                .popover(
                    isPresented: $isShowingMapOptions,
                    arrowEdge: .top
                ) {
                    AtlasMapOptionsView(
                        displayedMetric: $displayedMetric,
                        annotationSize: $annotationSize
                    )
                }
                .help("Adjust Atlas display options")
            }
            
            HStack(spacing: 10) {
                Button(
                    isLoadingObservations
                        ? "Loading Stations..."
                        : "Refresh Live Data"
                ) {
                    Task {
                        await loadObservationSnapshot(
                            forceRefresh: true
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    isLoadingObservations
                    || stationScope != .primary
                )

                Text(observationStatus)
                    .font(.subheadline)
                    .foregroundStyle(
                        DashboardTheme.textSecondary
                    )

                Spacer()
            }
            
            ///$cameraPosition is two-way binding. The map can update the stored camera when the user moves it.
            Map(position: $cameraPosition) {
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
                                annotationSize: annotationSize
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
                    
                    showSnapshotObservations(
                        from: observationSnapshot,
                        in: newBounds,
                        scope: stationScope,
                    )
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
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
            
                /// This diagnostic means center is the latitude & longitude at the middle of the screen. Span is approx how many degrees of
                /// latitude and longitude are visible. Small span means user is zoomed in.
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
        }
        .padding(20)
        
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
    }
}
