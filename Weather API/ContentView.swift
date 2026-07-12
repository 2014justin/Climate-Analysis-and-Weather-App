import SwiftUI
import Playgrounds
import Charts
import AppKit
import UniformTypeIdentifiers

struct RefreshWeatherActionKey: FocusedValueKey {
    typealias Value = () -> Void
}
/// Make 24, 48, 72 , and 96 hours selectable
struct SelectHistoryDurationActionKey: FocusedValueKey {
    typealias Value = (HistoryDuration) -> Void
}

/// Make it possible to export data as .pdf, .jpg, and .csv formats.
enum ExportFormat {
    case pdf
    case jpg
    case csv
}
///Adds Daylight phase so the app background can intellegently adjust to day, dusk, dawn and night.
///It depends on  the selected climate site's local sunrise/set time. So fairbanks AK might be dramatically
///different than southerly locations.
enum DaylightPhase {
    case sunrise
    case day
    case sunset
    case night
}
struct ExportWeatherActionKey: FocusedValueKey {
    typealias Value = (ExportFormat) -> Void
}
/// Forecast Discussion shortcut Command + F
struct ShowForecastDiscussionActionKey: FocusedValueKey {
    typealias Value = () -> Void
}
/// Climate graph shortcut Command + Shift + C
struct ShowClimateGraphActionKey: FocusedValueKey {
    typealias Value = () -> Void
}
///Station selector shortcut Com + Op + Number
struct SelectLocationActionKey: FocusedValueKey {
    typealias Value = (WeatherLocation) -> Void
}
///Graph value toggle shortcuts. Cmd + Shift + D for dew point. Cmd + Shift + H for heat index
struct ToggleDewPointActionKey: FocusedValueKey {
    typealias Value = () -> Void
}
///Heat index Command + Shift + H
struct ToggleHeatIndexActionKey: FocusedValueKey {
    typealias Value = () -> Void
}
extension FocusedValues {
    var refreshWeather: (() -> Void)? {
        get {
            self[RefreshWeatherActionKey.self]
        }
        
        set {
            self[RefreshWeatherActionKey.self] = newValue
        }
    }
    
    var selectHistoryDuration: ((HistoryDuration) -> Void)? {
        get {
            self[SelectHistoryDurationActionKey.self]
        }
        
        set {
            self[SelectHistoryDurationActionKey.self] = newValue
        }
    }
    
    var exportWeather: ((ExportFormat) -> Void)? {
        get {
            self[ExportWeatherActionKey.self]
        }
        
        set {
            self[ExportWeatherActionKey.self] = newValue
        }
    }
    ///Forecast Discussion
    var showForecastDiscussion: (() -> Void)? {
        get {
            self[ShowForecastDiscussionActionKey.self]
        }
        
        set {
            self[ShowForecastDiscussionActionKey.self] = newValue
        }
    }
    
    /// CLimate graph shortcut Command + Shift + C
    /// Remember that Void? means "an optional function that takes no inputs and returns nothing
    /// refreshWeather() takes no arguments and returns no meaningful value
    /// (() -> Void)? means the action might not exist right now, i.e. when the app window is not focused
    /// If there is no active ContentView, then there is no action to call, so swift stores nil
    var showClimateGraph: (() -> Void)? {
        get {
            self[ShowClimateGraphActionKey.self]
        }
        ///The bracket means, inside this focusedValues storage box, get the value associated with
        ///SelectLocationActionKey
        ///SelectLocationActionKey is the type. the dot self means "the type object itself.
        ///Swift uses that type to look up a key
        set {
            self[ShowClimateGraphActionKey.self] = newValue
        }
    }
    /// Station selector. Command + Shift + 1, 2, 3, 4, etc
    var selectLocation: ((WeatherLocation) -> Void)? {
        get {
            self[SelectLocationActionKey.self]
        }
        
        set {
            self[SelectLocationActionKey.self] = newValue
        }
    }
    ///Dew point + heat index graph toggler
    var toggleDewPoint: (() -> Void)? {
        get {
            self[ToggleDewPointActionKey.self]
        }
        
        set {
            self[ToggleDewPointActionKey.self] = newValue
        }
    }
    
    var toggleHeatIndex: (() -> Void)? {
        get {
            self[ToggleHeatIndexActionKey.self]
        }
        
        set {
            self[ToggleHeatIndexActionKey.self] = newValue
        }
    }
}

struct WeatherCommands: Commands {
    @FocusedValue(\.refreshWeather) private var refreshWeather
    @FocusedValue(\.selectHistoryDuration) private var selectHistoryDuration
    @FocusedValue(\.exportWeather) private var exportWeather
    @FocusedValue(\.showForecastDiscussion) private var showForecastDiscussion
    @FocusedValue(\.showClimateGraph) private var showClimateGraph
    @FocusedValue(\.selectLocation) private var selectLocation
    @FocusedValue(\.toggleDewPoint) private var toggleDewPoint
    @FocusedValue(\.toggleHeatIndex) private var toggleHeatIndex
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Refresh Weather") {
                refreshWeather?()
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(refreshWeather == nil)
            
            Divider()
            ///Show forecast discussion
            Button("Show Forecast Discussion") {
                showForecastDiscussion?()
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])
            .disabled(showForecastDiscussion == nil)
            ///Show CLimate graph
            Button("Show Climate Graph for Location") {
                showClimateGraph?()
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
            .disabled(showClimateGraph == nil)
            
            Divider()
            /// History selector
            Button("History: 24 Hours") {
                selectHistoryDuration?(.twentyFourHours)
            }
            .keyboardShortcut("1", modifiers: .command)
            .disabled(selectHistoryDuration == nil)
            
            Button("History: 48 Hours") {
                selectHistoryDuration?(.fortyEightHours)
            }
            .keyboardShortcut("2", modifiers: .command)
            .disabled(selectHistoryDuration == nil)
            
            Button("History: 72 Hours") {
                selectHistoryDuration?(.seventyTwoHours)
            }
            .keyboardShortcut("3", modifiers: .command)
            .disabled(selectHistoryDuration == nil)
            
            Button("History: 96 Hours") {
                selectHistoryDuration?(.ninetySixHours)
            }
            .keyboardShortcut("4", modifiers: .command)
            .disabled(selectHistoryDuration == nil)
            
            Button("History: 120 Hours") {
                selectHistoryDuration?(.oneTwentyHours)
            }
            .keyboardShortcut("5", modifiers: .command)
            .disabled(selectHistoryDuration == nil)
            
            Divider()
            
            ///Heat index + Dew point graph toggle keyboard shortcut
            
            Button("Toggle Dew Point") {
                toggleDewPoint?()
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])
            .disabled(toggleDewPoint == nil)

            Button("Toggle Heat Index") {
                toggleHeatIndex?()
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])
            .disabled(toggleHeatIndex == nil)
            Divider()
            
            ///Adds the station selector
            ///North las vegas
            Button("Location: North Las Vegas, NV") {
                selectLocation?(.northLasVegas)
            }
            .keyboardShortcut("1", modifiers: [.command, .option])
            .disabled(selectLocation == nil)
            
            ///Fairbanks
            Button("Location: Fairbanks, AK") {
                selectLocation?(.fairbanks)
            }
            .keyboardShortcut("2", modifiers: [.command, .option])
            .disabled(selectLocation == nil)
            
            ///Ely, NV
            Button("Location: Ely, NV") {
                selectLocation?(.ely)
            }
            .keyboardShortcut("3", modifiers: [.command, .option])
            .disabled(selectLocation == nil)
            
            ///Stanley, ID
            Button("Location: Stanley, ID") {
                selectLocation?(.stanley)
            }
            .keyboardShortcut("4", modifiers: [.command, .option])
            .disabled(selectLocation == nil)
            
            ///Salt Lake City, UT
            Button("Location: Salt Lake City, UT") {
                selectLocation?(.saltlakecity)
            }
            .keyboardShortcut("5", modifiers: [.command, .option])
            .disabled(selectLocation == nil)
            ///Denver, CO
            Button("Location: Denver, CO") {
                selectLocation?(.denver)
            }
            .keyboardShortcut("6", modifiers: [.command, .option])
            .disabled(selectLocation == nil)
            ///Mount Charleston, NV
            Button("Location: Mount Charleston, NV") {
                selectLocation?(.mountCharleston)
            }
            .keyboardShortcut("7", modifiers: [.command, .option])
            .disabled(selectLocation == nil)
            
            ///Long Beach, CA unfortunately had to do Com + Shift + Op + 7 because C + O + 8 is a MacOS shortcut
            ///
            Button("Location: Long Beach, CA") {
                selectLocation?(.longBeach)
            }
            .keyboardShortcut("8", modifiers: [.command, .option, .shift])
            .disabled(selectLocation == nil)
            Divider()
            
            
            /// PDF/JPG/CSV exported
            Button("Export PDF") {
                exportWeather?(.pdf)
            }
            .keyboardShortcut("p", modifiers: .command)
            .disabled(exportWeather == nil)
            
            Button("Export JPG") {
                exportWeather?(.jpg)
            }
            .keyboardShortcut("j", modifiers: .command)
            .disabled(exportWeather == nil)

            Button("Export CSV") {
                exportWeather?(.csv)
            }
            .keyboardShortcut("e", modifiers: .command)
            .disabled(exportWeather == nil)

            Divider()
        }
    }
}

@main struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 1350, height: 790)
        .commands {
            WeatherCommands()
        }
    }
}
///Important: Selects the valid future and past durations in time. 96 shows four day into the future
///but also four days into the past.
enum HistoryDuration: Int, CaseIterable, Identifiable {
    case twentyFourHours = 24
    case fortyEightHours = 48
    case seventyTwoHours = 72
    case ninetySixHours = 96
    case oneTwentyHours = 120
    
    var id: Int {
        return rawValue
    }
    
    var label: String {
        return "\(rawValue) hours"
    }
}

/// Add UI element for the climate analyzer drop down menu and make sure
/// the climate graph of interest is selected.
/// added threshold seasons climate chart. three climate views in rotation.
enum ClimateGraphType: Identifiable {
    case annualTemperatureCurve
    case seasonalHysteresisCurve
    case thresholdSeasons
    case weatherForTheYear
    static let allGraphs: [ClimateGraphType] = [
        .annualTemperatureCurve,
        .seasonalHysteresisCurve,
        .thresholdSeasons,
        .weatherForTheYear
    ]
    var id: String {
        title
    }
    var title: String {
        switch self {
        case .annualTemperatureCurve:
            return "Annual Temperature Curve"
        case .seasonalHysteresisCurve:
            return "Seasonal Hysteresis Curve"
        case .thresholdSeasons:
            return "Threshold Seasons"
        case .weatherForTheYear:
            return "Weather for the Year"
        }
    }
}

///Add background stars to the app at nighttime. This depends on station.
struct BackgroundStar: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let size: Double
    let opacity: Double
}

struct ContentView: View {
    @State private var observation = WeatherObservation(
        /// Start by defining the state variables. These are variables that can change in real time and be displayed
        /// to the user. Private makes it access-controlled. So @State private variable really means
        ///  SwiftUI watches this changing value, and only this view can access it directly.
        stationID: WeatherLocation.northLasVegas.displayStationID,
        airTemperature: 72.0,
        dewPoint: 45.0,
        heatIndex: 72.0,
        relativeHumidity: 38.0,
        windSpeed: 0.0,
        pressure: 0.0,
        wetBulb: 58.0,
        coolingPotential: 14.0,
        condition: "Unknown",
        lastUpdated: "10:30 AM"
    )
    ///State variables are the core of the app
    @State private var selectedClimateGraph = ClimateGraphType.annualTemperatureCurve
    @State private var activeClimateGraph: ClimateGraphType?
    @State private var networkStatus = "Not requested yet"
    @State private var isLoading = false
    @State private var temperatureHistory: [TemperaturePoint] = [] /// Start this array empty but grow & shrink as needed.
    @State private var temperatureForecast: [TemperaturePoint] = [] /// It will change in size depending on selected duration (24, 48, or 72 hours).
    @State private var selectedTemperaturePoint: TemperaturePoint? = nil ///Holds the point currently under the mouse
    @State private var isShowingDewPoint = false
    @State private var isShowingHeatIndex = false
    @State private var selectedHistoryDuration = HistoryDuration.twentyFourHours
    @State private var forecastDiscussion: ForecastDiscussion?
    @State private var isShowingForecastDiscussion = false
    @State private var isLoadingForecastDiscussion = false
    @State private var selectedLocation = WeatherLocation.northLasVegas
    @State private var isShowingStationAdder = false
    @State private var isShowingStationRemovalConfirmation = false
    @State private var isBuildingGeneratedClimateProfile = false
    @State private var savedGeneratedStations: [SavedGeneratedStation] = []
    
    /// Converts persistent station records into locations the picker can display.
    private var customLocations: [WeatherLocation] {
        savedGeneratedStations.map { savedStation in
            WeatherLocation.generated(from: savedStation)
        }
    }
    
    /// Combines built-in locations with user-created locations
    private var availableLocations: [WeatherLocation] {
        WeatherLocation.allLocations + customLocations
    }
    
    /// Returns a saved station only when the current selected station is in view.
    private var selectedSavedGeneratedStation: SavedGeneratedStation? {
        savedGeneratedStations.first { savedStation in
            savedStation.id == selectedLocation.id
        }
    }
    
    /// Adds daylight phase logic to tint app background as a function of time of day.
    private var daylightPhase: DaylightPhase {
        let now = Date()
        
        guard let sunTimes = WeatherAlmanac.sunTimes(
            for: now,
            latitude: selectedLocation.latitude,
            longitude: selectedLocation.longitude
        ) else {
            return .day
        }
        
        let transitionWindow: TimeInterval = 45 * 60
        
        if abs(now.timeIntervalSince(sunTimes.sunrise)) <= transitionWindow {
            return .sunrise
        }
        
        if abs(now.timeIntervalSince(sunTimes.sunset)) <= transitionWindow {
            return .sunset
        }
        
        if now > sunTimes.sunrise && now < sunTimes.sunset {
            return .day
        }
        
        return .night
    }
    /// Navy background
    private var dashboardGradientColors: [Color] {
        DashboardTheme.backgroundColors(
            for: daylightPhase
        )
    }
    /// Adds stars or starry background
    /// Can 
    private let backgroundStars: [BackgroundStar] = [
        BackgroundStar(x: 0.78, y: 0.12, size: 2.4, opacity: 0.70),
        BackgroundStar(x: 0.86, y: 0.28, size: 3.0, opacity: 0.72),
        BackgroundStar(x: 0.14, y: 0.18, size: 1.8, opacity: 0.90),
        BackgroundStar(x: 0.28, y: 0.10, size: 2.2, opacity: 0.83),
        BackgroundStar(x: 0.78, y: 0.24, size: 1.6, opacity: 0.76),
        BackgroundStar(x: 0.42, y: 0.74, size: 2.1, opacity: 0.75),
        BackgroundStar(x: 0.22, y: 0.60, size: 2.9, opacity: 0.72),
        BackgroundStar(x: 0.76, y: 0.86, size: 3.2, opacity: 0.75),
        BackgroundStar(x: 0.53, y: 0.74, size: 1.7, opacity: 0.89),
        BackgroundStar(x: 0.52, y: 0.85, size: 2.2, opacity: 0.75),
        BackgroundStar(x: 0.92, y: 0.88, size: 2.4, opacity: 0.85),
        BackgroundStar(x: 0.66, y: 0.76, size: 2.0, opacity: 0.85),
        BackgroundStar(x: 0.79, y: 0.92, size: 3.3, opacity: 0.88),
        BackgroundStar(x: 0.57, y: 0.93, size: 4.0, opacity: 0.79),
        BackgroundStar(x: 0.39, y: 0.92, size: 3.3, opacity: 0.88),
        BackgroundStar(x: 0.17, y: 0.93, size: 4.0, opacity: 0.79)
    ]
    
    private var starOverlay: some View {
        GeometryReader { geometry in
            ForEach(backgroundStars) { star in
                Circle()
                    .fill(.white)
                    .frame(width: star.size, height: star.size)
                    .opacity(star.opacity)
                    .position(
                        x: geometry.size.width * star.x,
                        y: geometry.size.height * star.y
                    )
            }
        }
        .allowsHitTesting(false)
    }
    ///Dashboard UI
    private var dashboardView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weather Dashboard")
                .font(.largeTitle)
            /// Gives the application a text identifying itself as a 'weather dashboard'
            HStack(spacing: 8) {
                Picker("Location", selection: $selectedLocation) {
                    ForEach(availableLocations) { location in
                        Text(location.name)
                            .tag(location)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedLocation) {
                    Task {
                        await refreshWeather()
                    }
                }
                
                Menu {
                    Button {
                        isShowingStationAdder = true
                    } label: {
                        Label("Add Station...", systemImage: "plus")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        isShowingStationRemovalConfirmation = true
                    } label: {
                        Label("Remove Current Location...", systemImage: "trash")
                    }
                    .disabled(selectedSavedGeneratedStation == nil)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color.blue)
                        )
                }
                .menuStyle(.button)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Manage stations")
            }
            .controlSize(.large)
            
            Text("Station: \(selectedLocation.displayStationID)")
                .font(.headline)

            Divider()

            HStack(alignment: .top, spacing: 8) {
                leftDashboardPanel
                /// Put the live numerical data on the left and the temperature chart on the right
                temperatureChart
            }
            /// Refresh weather button
            Button(isLoading ? "Refreshing ..." : "Refresh Weather") {
                Task {
                    await refreshWeather()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(isLoading)

            Button(isLoadingForecastDiscussion ? "Loading Discussion..." : "Show Forecast Discussion") {
                Task {
                    await loadForecastDiscussion()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(isLoadingForecastDiscussion)

            /// Add the climate analyzer graph selector UI element.
            /// Will show both the annual temperature curve & hysteresis graph
            Menu("Climate ▾") {
                Button("Show Annual Temperature Curve") {
                    selectedClimateGraph = .annualTemperatureCurve
                    activeClimateGraph = .annualTemperatureCurve
                }
                
                Button("Show Seasonal Hysteresis Curve") {
                    selectedClimateGraph = .seasonalHysteresisCurve
                    activeClimateGraph = .seasonalHysteresisCurve
                }
                
                ///threshold seasons button
                Button("Show Threshold Seasons") {
                    selectedClimateGraph = .thresholdSeasons
                    activeClimateGraph = .thresholdSeasons
                }
                
                ///Weather year button
                Button("Show Weather Year Graph") {
                    selectedClimateGraph = .weatherForTheYear
                    activeClimateGraph = .weatherForTheYear
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)

            ///Network status
            Text(networkStatus)
                .foregroundStyle(.secondary)

            Divider()
            /// Tells you when weather was last updated.
            Text("Last Updated: \(observation.lastUpdated)")
                .foregroundStyle(.secondary)
        }
    }
    
    /// Gives current conditions a nice card.
    private var leftDashboardPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            dashboardCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Current Conditions")
                        .font(.headline)
                    
                    currentConditionsGrid
                }
            }
            
            dashboardCard {
                almanacGrid
            }
        }
        .foregroundStyle(DashboardTheme.textPrimary)
        .frame(width: 365)
    }
    
    /// Provides one consistent surface for dashboard information groups.
    private func dashboardCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(14)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(DashboardTheme.panel)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: DashboardTheme.cardCornerRadius
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: DashboardTheme.cardCornerRadius
                )
                .stroke(DashboardTheme.border, lineWidth: 1)
            }
        
    }
    
    /// Load Generated Stations
    private func loadGeneratedStations() {
        do {
            savedGeneratedStations = try GeneratedStationStore.load()
        } catch {
            networkStatus = "Saved stations could not be loaded: \(error.localizedDescription)"
        }
    }
    
    /// Save generated station and remove duplicate stations
    private func saveGeneratedStation(_ result: GeneratedStationBuildResult) {
        let savedStation = SavedGeneratedStation(result: result)
        
        var updatedStations = savedGeneratedStations.filter {
            $0.id != savedStation.id
        }
        
        updatedStations.append(savedStation)
        
        do {
            try GeneratedStationStore.save(updatedStations)
            
            savedGeneratedStations = updatedStations
            selectedLocation = WeatherLocation.generated(from: savedStation)
            
            Task {
                await refreshWeather()
            }
        } catch {
            networkStatus = "Station could not be saved: \(error.localizedDescription)"
        }
    }
    
    /// Removes only a user-created station and updates persistent storage.
    private func removeSelectedGeneratedStation() {
        guard let stationToRemove = selectedSavedGeneratedStation else {
            return
        }
        
        let updatedStations = savedGeneratedStations.filter {
            $0.id != stationToRemove.id
        }
        
        do {
            try GeneratedStationStore.save(updatedStations)
            
            selectedLocation = .northLasVegas
            savedGeneratedStations = updatedStations
            networkStatus = "\(stationToRemove.name) was removed."
        } catch {
            networkStatus = "Station could not be removed: \(error.localizedDescription)"
        }
                
    }
    
    ///Make the Almanac and live weather conditions lined up properly.
    private func dashboardRow(label: String, value: String, unit: String = "") -> some View {
        GridRow {
            Text(label)
                .frame(width: 110, alignment: .leading)
            
            Text(value)
                .monospacedDigit()
                .frame(width: 95, alignment: .trailing)
            
            Text(unit)
                .frame(width: 100, alignment: .leading)
        }
    }
    
    private var currentConditionsGrid: some View { /// this is the same currentConditionsGrid that was called in line 187.
        Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 8) {
            /// Makes sure the grid is nice and neat. Solves the problem of some weather parameters like Temperature
            ///  having much longer names than something like Wind. All nice and lined up.
            GridRow {
                Text("Air Temperature")
                Text("\(observation.airTemperature, specifier: "%.1f")") /// Makes it so air temperature is a floating point number with just one digit after the decimal.
                    .monospacedDigit()
                Text("°F")
            }
            /// observation is an instance of this type from WeatherObservation.swift. Likewise airTemperature, heatIndex, etc.
            /// It looks inside the current WeatherObservation instance and gets its airTemperature value
            ///  So the path is like: NWS JSON -> NWSObservationResponse/NWSObservationProperties -> latestObservation.properties.temperature.value
            ///  -> temperature Celsius -> WeatherMath.celsiusToFahrenheit(...) -> fahrenheit -> WeatherObservation(airTemperature: fahrenheit, ... )
            ///  ->observation.airTemperature -> Text("")
            GridRow {
                Text("Dew Point")
                Text("\(observation.dewPoint, specifier: "%.1f")")
                    .monospacedDigit()
                Text("°F")
            }

            GridRow {
                Text("Heat index")
                Text("\(observation.heatIndex, specifier: "%.1f")")
                    .monospacedDigit()
                Text("°F")
            }

            GridRow {
                Text("Relative Humidity")
                Text("\(observation.relativeHumidity, specifier: "%.1f")")
                    .monospacedDigit()
                Text("%")
            }

            GridRow {
                Text("Wind Speed")
                Text("\(observation.windSpeed, specifier: "%.1f")")
                    .monospacedDigit()
                Text("mph")
            }

            GridRow {
                Text("Pressure")
                Text("\(observation.pressure, specifier: "%.2f")")
                    .monospacedDigit()
                Text("inHg")
            }

            GridRow {
                Text("Wet Bulb")
                Text("\(observation.wetBulb, specifier: "%.1f")")
                    .monospacedDigit()
                Text("°F")
            }

            GridRow {
                Text("Evaporative Cooling Potential")
                Text("\(observation.coolingPotential, specifier: "%.1f")")
                    .monospacedDigit()
                Text("°F")
            }
            
            GridRow {
                Text("Conditions")
                Text(observation.condition)
                Text("")
            }
        }
    }
    
    private var almanacGrid: some View {
        let today = WeatherAlmanac.dayOfYear()

        let normalHigh = selectedLocation.normalHigh(dayOfYear: today)

        let normalLow = selectedLocation.normalLow(dayOfYear: today)

        let solarEnergy = selectedLocation.solarEnergy(dayOfYear: today)

        let solarIndex = selectedLocation.normalizedSolarEnergy(dayOfYear: today)
        
        let sunTimes = WeatherAlmanac.sunTimes(
            latitude: selectedLocation.latitude,
            longitude: selectedLocation.longitude
        )
        let sunFormatter = DateFormatter()
        sunFormatter.timeStyle = .short
        sunFormatter.dateStyle = .none
        sunFormatter.timeZone = selectedLocation.timeZone
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Almanac")
                .font(.headline)
            
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                dashboardRow(
                    label: "Normal High",
                    value: String(format: "%.1f", normalHigh),
                    unit: "°F"
                )
                
                dashboardRow(
                    label: "Normal Low",
                    value: String(format: "%.1f", normalLow),
                    unit: "°F"
                )
                
                dashboardRow(
                    label: "Daily Solar Energy",
                    value: String(format: "%.2f", solarEnergy),
                    unit: "kWh/m²/day"
                )
                
                dashboardRow(
                    label: "Normalized Solar",
                    value: String(format: "%.3f", solarIndex)
                )
                
                dashboardRow(
                    label: "Sunrise",
                    value: sunTimes.map { sunFormatter.string(from: $0.sunrise) } ?? "--"
                )
                
                dashboardRow(
                    label: "Sunset",
                    value: sunTimes.map { sunFormatter.string(from: $0.sunset) } ?? "--"
                )
            }
        }
    }
    
    private var temperatureChart: some View {
        Chart {
            /// Live, future, and past air Temperature
            ForEach(temperatureHistory) { point in /// point is the temporary name for the current item in the loop
                LineMark(
                    x: .value("Time", point.timestamp), /// time goes to 'x' axis.
                    y: .value("Temperature", point.temperatureFahrenheit), /// Temperature goes to 'y' axis.
                    series: .value("Series", "Observed")
                )
                .foregroundStyle(DashboardTheme.observedTemperature)
            }
            /// If shows dew point, show the graph.
            if isShowingDewPoint {
                ForEach(temperatureHistory) { point in
                    if let dewPointFahrenheit = point.dewPointFahrenheit {
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Dew Point", dewPointFahrenheit),
                            series: .value("Series", "Dew Point")
                        )
                        .foregroundStyle(DashboardTheme.dewPoint)
                        .lineStyle(StrokeStyle(lineWidth: 2.0))
                    }
                }
            }
            ///If dew point exists, then automatically heat index exists.
            if isShowingHeatIndex {
                ForEach(temperatureHistory) { point in
                    if let heatIndexFahrenheit = point.heatIndexFahrenheit {
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Heat Index", heatIndexFahrenheit),
                            series: .value("Series", "Heat Index")
                        )
                        .foregroundStyle(DashboardTheme.heatIndex)
                        .lineStyle(StrokeStyle(lineWidth: 2.0))
                    }
                }
            }

            ForEach(temperatureForecast) { point in /// this does the same thing but for integrating forwards in time.
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Temperature", point.temperatureFahrenheit),
                    series: .value("Series", "Forecast")
                )
                .foregroundStyle(DashboardTheme.forecastTemperature) /// light blue & dashed to make it obviously stand out to weather that has already happened.
                .lineStyle(StrokeStyle(lineWidth: 2.5, dash: [7, 4]))
            }
            /// Forecast dew points as grey dashed line
            if isShowingDewPoint {
                ForEach(temperatureForecast) { point in
                    if let dewPointFahrenheit = point.dewPointFahrenheit {
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Forecast Dew Point", dewPointFahrenheit),
                            series: .value("Series", "Forecast Dew Point")
                        )
                        .foregroundStyle(DashboardTheme.dewPoint.opacity(0.60))
                        .lineStyle(StrokeStyle(lineWidth: 2.0, dash: [7,4]))
                    }
                }
            }
            ///Forecast dew points pink dashed.
            if isShowingHeatIndex {
                ForEach(temperatureForecast) { point in
                    if let heatIndexFahrenheit = point.heatIndexFahrenheit {
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Forecast Heat Index", heatIndexFahrenheit),
                            series: .value("Series", "Forecast Heat Index")
                        )
                        .foregroundStyle(DashboardTheme.heatIndex.opacity(0.60))
                        .lineStyle(StrokeStyle(lineWidth: 2.0, dash: [7, 4]))
                    }
                }
            }

            ForEach(dailyTemperatureHighlights) { point in
                PointMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Temperature", point.temperatureFahrenheit)
                )
                .foregroundStyle(.red)
                .symbolSize(70)
                .annotation(position: .top) {
                    Text("\(Int(point.temperatureFahrenheit.rounded()))")
                }
            }
            
            if let selectedTemperaturePoint {
                PointMark(
                    x: .value("Selected Time", selectedTemperaturePoint.timestamp),
                    y: .value("Selected Temperature", selectedTemperaturePoint.temperatureFahrenheit)
                )
                .foregroundStyle(DashboardTheme.observedTemperature)
                .symbolSize(80)
                .annotation(position: .top) {
                    chartHoverTooltip(
                        label: "Temperature",
                        value: selectedTemperaturePoint.temperatureFahrenheit,
                        timestamp: selectedTemperaturePoint.timestamp,
                        color: DashboardTheme.observedTemperature
                    )
                }
                ///Adds a nice solid black dot over dew points
                if isShowingDewPoint,
                   let dewPointFahrenheit = selectedTemperaturePoint.dewPointFahrenheit {
                    PointMark(
                        x: .value("Selected Dew Point Time", selectedTemperaturePoint.timestamp),
                        y: .value("Selected Dew Point", dewPointFahrenheit)
                    )
                    .foregroundStyle(DashboardTheme.dewPoint)
                    .symbolSize(80)
                    .annotation(position: .top) {
                        chartHoverTooltip(
                            label: "Dew Point",
                            value: dewPointFahrenheit,
                            timestamp: nil,
                            color: DashboardTheme.dewPoint
                        )
                    }
                }
                ///Hover table for heat index
                if isShowingHeatIndex,
                   let heatIndexFahrenheit = selectedTemperaturePoint.heatIndexFahrenheit {
                    PointMark(
                        x: .value("Selected Heat Index Time", selectedTemperaturePoint.timestamp),
                        y: .value("Selected Heat Index", heatIndexFahrenheit)
                    )
                    .foregroundStyle(DashboardTheme.heatIndex)
                    .symbolSize(80)
                    .annotation(position: .bottom) {
                        chartHoverTooltip(
                            label: "Heat Index",
                            value: heatIndexFahrenheit,
                            timestamp: nil,
                            color: DashboardTheme.heatIndex
                        )
                    }
                }
            }
        }
        .frame(width: 860, height: 350)
        .foregroundStyle(DashboardTheme.textPrimary)
        .padding(16)
        .padding(.top, 28)
        .background(DashboardTheme.panel)
        .clipShape(
            RoundedRectangle(
                cornerRadius: DashboardTheme.cardCornerRadius
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: DashboardTheme.cardCornerRadius
            )
            .stroke(DashboardTheme.border, lineWidth: 1)
        }
        .overlay(alignment: .topLeading) {
            Text("Temperature History")
                .font(.headline)
                .foregroundStyle(DashboardTheme.textPrimary)
                .padding(.leading, 16)
                .padding(.top, 14)
        }
        .chartPlotStyle { plotArea in
            plotArea
                .background(DashboardTheme.plotArea)
        }
        
        .chartYScale(domain: chartTemperatureDomain)
        .chartXScale(domain: chartTimeDomain)
        .chartYAxis {
            AxisMarks(values: .stride(by: 5)) {
                AxisGridLine()
                    .foregroundStyle(DashboardTheme.border)
                AxisTick()
                    .foregroundStyle(DashboardTheme.textSecondary)
                AxisValueLabel()
                    .foregroundStyle(DashboardTheme.textSecondary)
            }
        }
        /// This makes it so if 72 hours is selected, the x axis doesn't have labeled tick marks every 3 pixels so it looks fucked up. spaced more out
        /// on longer durations.
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: chartXAxisHourStride)) { value in
                AxisGridLine()
                    .foregroundStyle(DashboardTheme.border)
                AxisTick()
                    .foregroundStyle(DashboardTheme.textSecondary)
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        let previousTick = date.addingTimeInterval(
                            -Double(chartXAxisHourStride) * 60 * 60
                        )

                        let isFirstTickOfNewDay = !Calendar.current.isDate(
                            date,
                            inSameDayAs: previousTick
                        )

                        if isFirstTickOfNewDay {
                            Text(
                                date.formatted(.dateTime.month(.abbreviated).day())
                                    .uppercased()
                            )
                            .foregroundStyle(DashboardTheme.textSecondary)
                        } else {
                            Text(date.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated))))
                                .foregroundStyle(DashboardTheme.textSecondary)
                        }
                    }
                }
            }
        }
        ///Creates an invisible rectangle over the clart. When your mouse moves over it: Swift gets the mouse location, we convert the x-position into a date,
        ///we search all temperature chart points, then we store the closest point in selected temperature point.
        .chartOverlay { proxy in
            ChartHoverOverlay(
                proxy: proxy,
                onHover: { plotLocation in
                    guard let hoveredDate: Date = proxy.value(atX: plotLocation.x) else {
                        selectedTemperaturePoint = nil
                        return
                    }
                    
                    selectedTemperaturePoint = allTemperatureChartPoints.min { first, second in
                        abs(first.timestamp.timeIntervalSince(hoveredDate)) <
                            abs(second.timestamp.timeIntervalSince(hoveredDate))
                    }
                },
                onEnded: {
                    selectedTemperaturePoint = nil
                }
            )
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 6) {
                Menu {
                    Label("Temperature", systemImage: "checkmark")
                        .disabled(true)

                    Toggle("Dew Point", isOn: $isShowingDewPoint)
                    Toggle("Heat Index", isOn: $isShowingHeatIndex)
                } label: {
                    HStack(spacing: 4) {
                        Text("Meteorological Values")

                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.caption)
                    .foregroundStyle(DashboardTheme.textPrimary)
                }

                Text("History")
                    .font(.caption)
                    .foregroundStyle(DashboardTheme.textSecondary)

                Picker(
                    "History Duration",
                    selection: $selectedHistoryDuration
                ) {
                    ForEach(HistoryDuration.allCases) { duration in
                        Text(duration.label)
                            .tag(duration)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .tint(DashboardTheme.observedTemperature)
                .foregroundStyle(DashboardTheme.textPrimary)
                .frame(width: 110)
            }
            .environment(\.colorScheme, .dark)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(DashboardTheme.panelElevated)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(DashboardTheme.border, lineWidth: 1)
            }
            .padding(.top, 8)
            .padding(.trailing, 64)
        }
    }
    ///Displays temperature neatly as a point floating above the graph. Does it for air temp, dew point, and heat index.
    private func chartHoverTooltip(
        label: String,
        value: Double,
        timestamp: Date? = nil,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let timestamp {
                Text(
                    timestamp.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )
                .font(.caption2)
                .foregroundStyle(DashboardTheme.textSecondary)
            }

            Text("\(label): \(String(format: "%.1f", value)) °F")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .padding(6)
        .background(DashboardTheme.panelElevated.opacity(0.98))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(DashboardTheme.border, lineWidth: 1)
        }
        .shadow(
            color: .black.opacity(0.35),
            radius: 6,
            x: 0,
            y: 2
        )
    }
    
    ///Daytime = day color gradient. Sunrise/set = sunset color gradient. Night = starry night background.
    var body: some View {
        ZStack {
            LinearGradient(
                colors: dashboardGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            if daylightPhase == .night {
                starOverlay
            }
            ///Adjust APp default window size here
            dashboardView
                .padding()
                .frame(
                    minWidth: 1210,
                    maxWidth: .infinity,
                    minHeight: 550,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
        }
            /// Load the user-created stations.
            .task {
                loadGeneratedStations()
            }
            /// Focused Scene value for File. Refresh Weather
            .focusedSceneValue(\.refreshWeather) {
                Task {
                    await refreshWeather() /// Written as an async function because refreshWeather() might take a minute.
                    /// Don't want to fuck up the whole app
                }
            }
            ///Select History Duration
            .focusedSceneValue(\.selectHistoryDuration) { duration in
                selectedHistoryDuration = duration

                Task {
                    await refreshWeather()
                }
            }
            ///Export Weather
            .focusedSceneValue(\.exportWeather) { format in
                switch format {
                case .pdf:
                    exportPDF()
                case .jpg:
                    exportJPG()
                case .csv:
                    exportCSV()
                }
            }
            /// Forecast discussion shortcut
            .focusedSceneValue(\.showForecastDiscussion) {
                Task {
                    await loadForecastDiscussion()
                }
            }
            /// Show Climate graph shortcut
            .focusedSceneValue(\.showClimateGraph) {
                selectedClimateGraph = .annualTemperatureCurve
                activeClimateGraph = .annualTemperatureCurve
            }
        
            ///Heat index + Dew point graph toggle shortcut
            .focusedSceneValue(\.toggleDewPoint) {
                isShowingDewPoint.toggle()
            }

            .focusedSceneValue(\.toggleHeatIndex) {
                isShowingHeatIndex.toggle()
            }
        
            ///When the menu command sends a location: selectLocation?(.fairbanks) this block receives it as
            ///location. Then it changes selectedLocation, and immediately refreshes weather for the new location
            .focusedSceneValue(\.selectLocation) { location in
                selectedLocation = location
                
                Task {
                    await refreshWeather()
                }
            }
            .sheet(isPresented: $isShowingForecastDiscussion) {
                ForecastDiscussionView(discussion: forecastDiscussion)
            }
        /// Makes sure the desired climate graph is actually the one being selected
            .sheet(item: $activeClimateGraph) { _ in
                ClimateGraphView(
                    graphType: $selectedClimateGraph,
                    location: selectedLocation
                )
            }
            .alert(
                "Remove Current Location?",
                isPresented: $isShowingStationRemovalConfirmation
            ) {
                Button("Cancel", role: .cancel) {
                    
                }
                
                Button("Remove", role: .destructive) {
                    removeSelectedGeneratedStation()
                }
            } message: {
                Text(
                    "Remove \(selectedSavedGeneratedStation?.name ?? "this location") from your saved stations?"
                )
            }
            .sheet(isPresented: $isShowingStationAdder) {
                StationAdderView { result in
                    saveGeneratedStation(result)
                }
            }
    }
    private var allTemperatureChartPoints: [TemperaturePoint] {
        let combinedPoints = temperatureHistory + temperatureForecast
        
        return combinedPoints
            .filter {chartTimeDomain.contains($0.timestamp) }
            .sorted { $0.timestamp < $1.timestamp}
    }
    private var chartXAxisHourStride: Int {
        let hours = selectedHistoryDuration.rawValue
        
        switch hours {
        case ...24:
            return 6
        case ...48:
            return 12
        case ...96:
            return 24
        case ...168:
            return 48
        default:
            return 72
        }
    }
    ///Fixes formatting for x axis depending on hours.
    private var chartTimeDomain: ClosedRange<Date> {
        let now = Date()
        let hours = Double(selectedHistoryDuration.rawValue)
        let start = now.addingTimeInterval(-hours * 60 * 60)
        let end = now.addingTimeInterval(hours * 60 * 60)
        
        return start...end
    }
    private var chartTemperatureDomain: ClosedRange<Double> {
        let visiblePoints = allTemperatureChartPoints
        
        var visibleTemperatures = visiblePoints.map {
            $0.temperatureFahrenheit
        }
        
        if isShowingDewPoint {
            let visibleDewPoints = visiblePoints.compactMap {
                $0.dewPointFahrenheit
            }
            
            visibleTemperatures.append(contentsOf: visibleDewPoints)
        }
        
        if isShowingHeatIndex {
            let visibleHeatIndexes = visiblePoints.compactMap {
                $0.heatIndexFahrenheit
            }
            
            visibleTemperatures.append(contentsOf: visibleHeatIndexes)
        }
        
        guard let minimum = visibleTemperatures.min(),
              let maximum = visibleTemperatures.max() else {
            return 0 ... 150
        }
        
        let lowerBound = WeatherMath.lowerChartBound(for: minimum)
        let upperBound = WeatherMath.upperChartBound(for: maximum)
        
        return lowerBound ... upperBound
    }
    private var dailyTemperatureHighlights: [TemperaturePoint] { /// this is NOT stored data, it is a computed property.
        let calendar = Calendar.current
        /// Basically, whenever someone asks for dialyTemperatureHighlights, run this code and return an array.
        let groupedByDay = Dictionary(grouping: temperatureHistory + temperatureForecast) { point in
            calendar.startOfDay(for: point.timestamp)
        }
        
        var highlights: [TemperaturePoint] = []
        
        for dayPoints in groupedByDay.values {
            let morningPoints = dayPoints.filter { point in
                let hour = calendar.component(.hour, from: point.timestamp)
                return hour < 12
            }
            
            let afternoonPoints = dayPoints.filter { point in
                let hour = calendar.component(.hour, from: point.timestamp)
                return hour >= 12
            }
            
            if let morningLow = morningPoints.min(by: {
                $0.temperatureFahrenheit < $1.temperatureFahrenheit
            }) {
                highlights.append(morningLow)
            }
            
            if let afternoonHigh = afternoonPoints.max(by: {
                $0.temperatureFahrenheit < $1.temperatureFahrenheit
            }) {
                highlights.append(afternoonHigh)
            }
        }
        
        return highlights.sorted {
            $0.timestamp < $1.timestamp
        }
    }
    private func makeCSVText() -> String {
        var lines: [String] = []
        
        lines.append("type,timestamp,temperature_f")
        
        for point in temperatureHistory {
            lines.append(
                "observed,\(point.timestamp.ISO8601Format()),\(point.temperatureFahrenheit)"
            )
        }
        
        for point in temperatureForecast {
            lines.append(
                "forecast,\(point.timestamp.ISO8601Format()),\(point.temperatureFahrenheit)"
            )
        }
        
        return lines.joined(separator: "\n")
    }
    
    private func exportCSV() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "Weather Data.csv"
        
        let result = savePanel.runModal()
        
        guard result == .OK,
              let url = savePanel.url else {
            networkStatus = "CSV export canceled."
            return
        }
        
        do {
            let csvText = makeCSVText()
            
            try csvText.write(
                to: url,
                atomically: true,
                encoding: .utf8
            )
            
            networkStatus = "CSV exported successfully."
        } catch {
            networkStatus = "CSV export failed: \(error.localizedDescription)"
        }
    }
    @MainActor
    private func exportJPG() {
        let renderer = ImageRenderer(
            content: dashboardView
                .padding()
                .frame(width: 1150, height: 620, alignment: .topLeading)
                .background(.white)
        )
        
        renderer.scale = 2.0
        
        guard let image = renderer.nsImage else {
            networkStatus = "JPG export failed: count not render image."
            return
        }
        
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpgData = bitmap.representation(
                using: .jpeg,
                properties: [.compressionFactor: 1.0]
              ) else {
            networkStatus = "JPG export failed: could not encode image."
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.jpeg]
        savePanel.nameFieldStringValue = "Weather Dashboard.jpg"
        
        let result = savePanel.runModal()
        
        guard result == .OK,
              let url = savePanel.url else {
            networkStatus = "JPG export canceled."
            return
        }
        
        do {
            try jpgData.write(to: url)
            networkStatus = "JPG exported successfully."
        } catch {
            networkStatus = "JPG export failed: \(error.localizedDescription)"
        }
    }
    @MainActor
    private func exportPDF() {
        let pageWidth = 1150.0
        let pageHeight = 620.0
        
        let renderer = ImageRenderer(
            content: dashboardView
                .padding()
                .frame(width: pageWidth, height: pageHeight, alignment: .topLeading)
                .background(.white)
                .environment(\.colorScheme, .light)
        )
        
        renderer.scale = 2.0
        
        guard let image = renderer.nsImage else {
            networkStatus = "PDF export failed: could not render image."
            return
        }
        
        let pdfData = NSMutableData()
        var mediaBox = CGRect(
            x: 0,
            y: 0,
            width: pageWidth,
            height: pageHeight
        )
        
        guard let consumer = CGDataConsumer(data: pdfData),
              let context = CGContext(
                consumer: consumer,
                mediaBox: &mediaBox,
                nil
              ) else {
            networkStatus = "PDF export failed: could not create document."
            return
        }
        
        context.beginPDFPage(nil)
        
        let graphicsContext = NSGraphicsContext(
            cgContext: context,
            flipped: false
        )
        
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphicsContext
        
        image.draw(
            in: mediaBox,
            from: .zero,
            operation: .copy,
            fraction: 1.0
        )
        
        NSGraphicsContext.restoreGraphicsState()
        
        context.endPDFPage()
        context.closePDF()
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "Weather Dashboard.pdf"
        
        let result = savePanel.runModal()
        
        guard result == .OK,
              let url = savePanel.url else {
                  networkStatus = "PDF export canceled."
                  return
              }
        do {
            try pdfData.write(to: url)
            networkStatus = "PDF exported successfully."
        } catch {
            networkStatus = "PDF export failed: \(error.localizedDescription)"
        }
    }
    
    ///Loads forecast discussion. Built-in stations uses its configured office immediately.
    ///User-added station Office is empty, look up office from coordinates and fetch that office's latest AFD.
    private func loadForecastDiscussion() async {
        isLoadingForecastDiscussion = true
        
        defer {
            isLoadingForecastDiscussion = false
        }
        
        do {
            let weatherService = WeatherService()
            
            let configuredOffice =
                selectedLocation.forecastDiscussionOffice
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .uppercased()
            
            let forecastOffice: String
            
            if configuredOffice.isEmpty {
                networkStatus =
                    "Finding local NWS forecast office..."
                
                forecastOffice =
                    try await weatherService
                        .fetchForecastOffice(
                            latitude: selectedLocation.latitude,
                            longitude: selectedLocation.longitude
                        )
            } else {
                forecastOffice = configuredOffice
            }
            
            networkStatus =
                "Loading \(forecastOffice) forecast discussion..."
            
            let discussion =
                try await weatherService
                    .fetchLatestForecastDiscussion(office: forecastOffice)
            
            forecastDiscussion = discussion
            isShowingForecastDiscussion = true
            networkStatus =
                "\(forecastOffice) forecast discussion loaded."
        } catch {
            networkStatus =
                "Forecast discussion failed: "
                + error.localizedDescription
        }
    }
    
    private func refreshWeather() async {
        isLoading = true
        
        defer {
            isLoading = false
        }
        do {
            let clock = ContinuousClock()
            let fetchStart = clock.now
            let service = WeatherService()
            
            let response = try await service.fetchRecentObservations(
                stationID: selectedLocation.observationStationID,
                hours: selectedHistoryDuration.rawValue
            )
            let forecast = try await service.fetchHourlyForecast(
                latitude: selectedLocation.latitude,
                longitude: selectedLocation.longitude
            )
            let fetchDuration = fetchStart.duration(to: clock.now)
            
            let fetchSeconds =
            Double(fetchDuration.components.seconds) + Double(fetchDuration.components.attoseconds) / 1_000_000_000_000_000_000.0
            let cutoffDate = Date().addingTimeInterval( -Double(selectedHistoryDuration.rawValue) * 60.0 * 60.0
            )
            
            temperatureHistory = response.features.compactMap { feature -> TemperaturePoint? in
                guard feature.properties.timestamp >= cutoffDate,
                      let temperatureCelsius = feature.properties.temperature.value else {
                    return nil
                }
                
                let temperatureFahrenheit = WeatherMath.celsiusToFahrenheit(temperatureCelsius)

                let dewPointFahrenheit: Double?

                if let dewPointCelsius = feature.properties.dewpoint.value {
                    dewPointFahrenheit = WeatherMath.celsiusToFahrenheit(dewPointCelsius)
                } else {
                    dewPointFahrenheit = nil
                }

                let heatIndexFahrenheit: Double?

                if let relativeHumidity = feature.properties.relativeHumidity.value {
                    heatIndexFahrenheit = WeatherMath.heatIndexFahrenheit(
                        temperature: temperatureFahrenheit,
                        relativeHumidity: relativeHumidity
                    )
                } else {
                    heatIndexFahrenheit = nil
                }

                return TemperaturePoint(
                    timestamp: feature.properties.timestamp,
                    temperatureFahrenheit: temperatureFahrenheit,
                    dewPointFahrenheit: dewPointFahrenheit,
                    heatIndexFahrenheit: heatIndexFahrenheit
                )
            }
            
            .sorted {
                $0.timestamp < $1.timestamp
            }
            let forecastEndDate = Date().addingTimeInterval(
                Double(selectedHistoryDuration.rawValue) * 60 * 60
            )
            
            temperatureForecast = forecast.properties.periods.compactMap { period in
                guard period.startTime <= forecastEndDate else {
                    return nil
                }
                ///Dew point might return nil due to station error
                let forecastDewPointFahrenheit: Double?

                if let dewPointCelsius = period.dewpoint?.value {
                    forecastDewPointFahrenheit = WeatherMath.celsiusToFahrenheit(dewPointCelsius)
                } else {
                    forecastDewPointFahrenheit = nil
                }
                
                let forecastHeatIndexFahrenheit: Double?
                
                if let relativeHumidity = period.relativeHumidity?.value {
                    forecastHeatIndexFahrenheit = WeatherMath.heatIndexFahrenheit(
                        temperature: period.temperature,
                        relativeHumidity: relativeHumidity
                    )
                } else {
                    forecastHeatIndexFahrenheit = nil
                }

                return TemperaturePoint(
                    timestamp: period.startTime,
                    temperatureFahrenheit: period.temperature,
                    dewPointFahrenheit: forecastDewPointFahrenheit,
                    heatIndexFahrenheit: forecastHeatIndexFahrenheit
                )
            }
            
            if let latestObservation = response.features.first(
                where: { observation in
                    observation.properties.temperature.value != nil &&
                    observation.properties.dewpoint.value != nil &&
                    observation.properties.relativeHumidity.value != nil &&
                    observation.properties.windSpeed.value != nil
                }
            ),
               let temperature = latestObservation.properties.temperature.value,
               let dewpoint = latestObservation.properties.dewpoint.value,
               let humidity = latestObservation.properties.relativeHumidity.value,
               let windSpeedKph = latestObservation.properties.windSpeed.value {
               let pressurePascals = latestObservation.properties.barometricPressure.value ?? 0
                let fahrenheit = WeatherMath.celsiusToFahrenheit(temperature)
                let dewpointFahrenheit = WeatherMath.celsiusToFahrenheit(dewpoint)
                let windSpeedMph = WeatherMath.kilometersPerHourToMilesPerHour(windSpeedKph)
                let pressureInHg = WeatherMath.pascalsToInchesOfMercury(pressurePascals)
                
                let wetBulbCelsius = WeatherMath.wetBulbCelsius(
                    temperatureCelsius: temperature,
                    relativeHumidity: humidity
                )
                
                let wetBulbFahrenheit = WeatherMath.celsiusToFahrenheit(
                    wetBulbCelsius
                )
                
                let coolingPotential = fahrenheit - wetBulbFahrenheit
                
                let heatIndex = WeatherMath.heatIndexFahrenheit(
                    temperature: fahrenheit,
                    relativeHumidity: humidity
                )
                
                let observedCondition = latestObservation.properties.textDescription?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                let displayCondition: String
                
                if let observedCondition,
                   observedCondition.isEmpty == false {
                    displayCondition = observedCondition
                } else {
                    displayCondition = forecast.properties.periods.first?.shortForecast ?? "Unknown"
                }
                observation = WeatherObservation(
                    stationID: selectedLocation.displayStationID,
                    airTemperature: fahrenheit,
                    dewPoint: dewpointFahrenheit,
                    heatIndex: heatIndex,
                    relativeHumidity: humidity,
                    windSpeed: windSpeedMph,
                    pressure: pressureInHg,
                    wetBulb: wetBulbFahrenheit,
                    coolingPotential: coolingPotential,
                    condition: displayCondition,
                    lastUpdated: latestObservation.properties.timestamp.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                    )
                let formattedFetchSeconds = fetchSeconds.formatted(.number.precision(.fractionLength(2))
                )
                
                networkStatus = "Weather updated successfully in \(formattedFetchSeconds) seconds. \(temperatureHistory.count) graph points loaded. \(forecast.properties.periods.count) forecast hours loaded."
            } else {
                observation = WeatherObservation(
                    stationID: selectedLocation.displayStationID,
                    airTemperature: 0.0,
                    dewPoint: 0.0,
                    heatIndex: 0.0,
                    relativeHumidity: 0.0,
                    windSpeed: 0.0,
                    pressure: 0.0,
                    wetBulb: 0.0,
                    coolingPotential: 0.0,
                    condition: "No live observation",
                    lastUpdated: "Unavailable"
                )
                networkStatus = "No complete live observation found for \(selectedLocation.displayStationID). Forecast still loaded from location coordinates."
            }
        } catch {
            networkStatus = "Request failed: \(error.localizedDescription)"
        }
    }
}

/// The next section is integral to displaying climate graphs such as annual temperature curve.

struct ForecastDiscussionView: View {
    let discussion: ForecastDiscussion?
    @Environment(\.dismiss) private var dismiss
    @State private var keyMonitor: Any?
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                
                Button("X") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            if let discussion {
                Text(discussion.productName)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Issued by \(discussion.issuingOffice)")
                    .font(.headline)
                
                Text(discussion.issuanceTime.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.secondary)
                
                Divider()
                
                ScrollView{
                    Text(discussion.productText)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text("No forecast discussion loaded")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(minWidth: 700, minHeight: 600)
        /// Makes it so we can use command W to close windows within the app itself
        .onAppear {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                let isCommandW = event.modifierFlags.contains(.command)
                    && event.charactersIgnoringModifiers?.lowercased() == "w"
                
                if isCommandW {
                    dismiss()
                    return nil
                }
                return event
            }
        }
        .onDisappear {
            if let keyMonitor {
                NSEvent.removeMonitor(keyMonitor)
            }
        }
    }
}
