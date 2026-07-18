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

/// Switch between the dashboard and the Atlas.
struct SelectAppSectionActionKey: FocusedValueKey {
    typealias Value = (AppSection) -> Void
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
    
    ///Export weather
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
    
    /// Add SelectApp focus to FocusedValues
    
    var selectAppSection: ((AppSection) -> Void)? {
        get {
            self[SelectAppSectionActionKey.self]
        }
        
        set {
            self[SelectAppSectionActionKey.self] = newValue
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
    @FocusedValue(\.selectAppSection) private var selectAppSection
    
    var body: some Commands {
        CommandGroup(after: .newItem) {
            
            /// Switch between Atlas and Dashboard
            Button("Show Dashboard") {
                selectAppSection?(.dashboard)
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])
            .disabled(selectAppSection == nil)
            
            Button("Show Climate Atlas") {
                selectAppSection?(.atlas)
            }
            .keyboardShortcut("a", modifiers: [.command, .shift])
            .disabled(selectAppSection == nil)
            
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
            .keyboardShortcut("t", modifiers: [.command, .shift])
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

/// Define the selectable variable for the climate widget Tmin and Tmax
enum ThermalPaceVariable: String, CaseIterable, Identifiable {
    case minimum
    case maximum
    
    var id: String {
        rawValue
    }
    var label: String {
        switch self {
        case .minimum:
            return "Tmin"
        case .maximum:
            return "Tmax"
        }
    }
    
    var subtitle: String {
        switch self {
        case .minimum:
            return "Normal minimum-temperature progression"
        case .maximum:
            return "Normal maximum-temperature progression"
        }
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

private enum WeatherRefreshState {
    case idle
    case refreshing
    case updated(Date)
    case failed
}

///Add background stars to the app at nighttime. This depends on station.
struct BackgroundStar: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let size: Double
    let opacity: Double
}


/// Add the chart point model for normal climate widget
struct ThermalPacePoint: Identifiable {
    let dayOffset: Int
    let date: Date
    let temperature: Double
    let standardDeviation: Double?
    
    /// dayOffset does 14 days before and after.
    var id: Int {
        dayOffset
    }
}

/// Phase-point model for our phase portrait climate widget
struct SeasonalPhasePoint: Identifiable {
    let dayOfYear: Int
    let normalizedSolar: Double
    let minimumTemperature: Double
    
    var id: Int {
        dayOfYear
    }
}


///Reusable bar component for threshold season
struct SeasonalWindowBar: View {
    let leftOuterDay: Double
    let leftInnerDay: Double
    let rightInnerDay: Double
    let rightOuterDay: Double
    let currentDay: Double
    
    private func xPosition(for day: Double, width: CGFloat) -> CGFloat {
        let clampedDay = min(max(day, 1.0), 365.0)
        let fraction = (clampedDay - 1.0) / 364.0
        
        return CGFloat(fraction) * width
    }
    
    private func clampedLabelX(_ position: CGFloat, width: CGFloat) -> CGFloat {
        min(max(position, 22), max(22, width - 22))
    }
    
    private func shortDateText(for day: Double) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        guard let date = calendar.date(
            from: DateComponents(year: 2001, day: Int(day.rounded()))
        ) else {
            return "-"
        }
        
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "M/d"
        
        return formatter.string(from: date)
    }
    
    private func boundaryLabel(percent: String, day: Double) -> some View {
        VStack(spacing: 0) {
            Text(percent)
                .font(.system(size: 9, weight: .semibold))
            
            Text(shortDateText(for: day))
                .font(.system(size: 9))
        }
        .monospacedDigit()
        .foregroundStyle(DashboardTheme.textSecondary)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let trackY: CGFloat = 27
            
            let leftOuterX = xPosition(for: leftOuterDay, width: width)
            let leftInnerX = xPosition(for: leftInnerDay, width: width)
            let rightInnerX = xPosition(for: rightInnerDay, width: width)
            let rightOuterX = xPosition(for: rightOuterDay, width: width)
            let currentX = xPosition(for: currentDay, width: width)
            
            ZStack {
                Capsule()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: width, height: 10)
                    .position(x: width / 2, y: trackY)
                
                Capsule()
                    .fill(DashboardTheme.forecastTemperature.opacity(0.42))
                    .frame(
                        width: max(leftInnerX - leftOuterX, 2),
                        height: 10
                    )
                    .position(
                        x: (leftOuterX + leftInnerX) / 2,
                        y: trackY
                    )
                
                Capsule()
                    .fill(DashboardTheme.observedTemperature)
                    .frame(
                        width: max(rightInnerX - leftInnerX, 2),
                        height: 10
                    )
                    .position(
                        x: (leftInnerX + rightInnerX) / 2,
                        y: trackY
                    )
                
                Capsule()
                    .fill(DashboardTheme.forecastTemperature.opacity(0.42))
                    .frame(
                        width: max(rightOuterX - rightInnerX, 2),
                        height: 10
                    )
                    .position(
                        x: (rightInnerX + rightOuterX) / 2,
                        y: trackY
                    )
                
                Circle()
                    .fill(DashboardTheme.normal)
                    .frame(
                        width: 11,
                        height: 11
                    )
                    .overlay {
                        Circle()
                            .stroke(DashboardTheme.plotArea, lineWidth: 2)
                    }
                    .position(x: currentX, y: trackY)
                    .help("Today: \(shortDateText(for: currentDay))")
                
                boundaryLabel(percent: "90%", day: leftOuterDay)
                    .position(
                        x: clampedLabelX(leftOuterX, width: width),
                        y: 8
                    )
                
                boundaryLabel(percent: "10%", day: leftInnerDay)
                    .position(
                        x: clampedLabelX(leftInnerX, width: width),
                        y: 48
                    )
                
                boundaryLabel(percent: "10%", day: rightInnerDay)
                    .position(
                        x: clampedLabelX(rightInnerX, width: width),
                        y: 48
                    )
                
                boundaryLabel(percent: "90%", day: rightOuterDay)
                    .position(
                        x: clampedLabelX(rightOuterX, width: width),
                        y: 8
                    )
            }
        }
        .frame(height: 56)
    }
}

/// Add a sheet-request type. Guarantees that every Atlas selection creates a fresh sheet
/// and fresh StationAdderView state.
private struct StationAdderRequest: Identifiable {
    let id = UUID()
    let initialStationID: String
}

struct ContentView: View {
    /// App's memory of which section (atlas/dashboard) is being selected.
    
    @State private var selectedAppSection: AppSection = .dashboard
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
        pressure: nil,
        wetBulb: 58.0,
        coolingPotential: 14.0,
        condition: "Unknown",
        lastUpdated: "10:30 AM"
    )
    ///State variables are the core of the app
    @State private var selectedClimateGraph = ClimateGraphType.annualTemperatureCurve
    @State private var activeClimateGraph: ClimateGraphType?
    @State private var networkStatus = "Not requested yet"
    @State private var weatherRefreshState = WeatherRefreshState.idle
    @State private var isLoading = false
    @State private var temperatureHistory: [TemperaturePoint] = [] /// Start this array empty but grow & shrink as needed.
    @State private var temperatureForecast: [TemperaturePoint] = [] /// It will change in size depending on selected duration (24, 48, or 72 hours).
    @State private var selectedTemperaturePoint: TemperaturePoint? = nil ///Holds the point currently under the mouse
    @State private var isShowingDewPoint = false
    @State private var isShowingHeatIndex = false
    @State private var selectedHistoryDuration = HistoryDuration.twentyFourHours
    @State private var selectedThermalPaceVariable = ThermalPaceVariable.minimum
    @State private var liveWeatherYearDays: [WeatherYearDay] = []
    @State private var liveSeasonalPhaseStatus = "Current weather year not loaded yet."
    @State private var thresholdNormalPeriodObservations: [ACISDailyObservation] = []
    @State private var thresholdWidgetStatus = "Normal-period thresholds not loaded yet."
    @State private var thresholdWidgetFreezeSummary: ACISThresholdSummary?
    @State private var thresholdWidgetWarmSummaries: [ACISThresholdSummary] = []
    @State private var forecastDiscussion: ForecastDiscussion?
    @State private var isShowingForecastDiscussion = false
    @State private var isLoadingForecastDiscussion = false
    @State private var selectedLocation = WeatherLocation.northLasVegas
    /// A non-nil request presents the builder and carries
    /// its starting weather-station ID.
    @State private var stationAdderRequest:
        StationAdderRequest?
    
    ///Let ContentView remember the Atlas station
    @State private var stationAdderInitialStationID = ""
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
            longitude: selectedLocation.longitude,
            timeZone: selectedLocation.timeZone
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
    
    /// Pretty-UI for station refresh
    @ViewBuilder
    private var stationRefreshStatus: some View {
        switch weatherRefreshState {
        case .idle:
            EmptyView()
        case .refreshing:
            Label(
                "Refreshing...",
                systemImage: "arrow.triangle.2.circlepath"
            )
            .foregroundStyle(DashboardTheme.forecastTemperature)
        
        case .updated(let timestamp):
            Label(
                "Updated: \(timestamp.formatted(date: .omitted, time: .shortened))",
                systemImage: "checkmark.circle.fill"
            )
            .foregroundStyle(DashboardTheme.success)
            
        case .failed:
            Label(
                "Update failed",
                systemImage: "xmark.circle.fill"
            )
            .foregroundStyle(DashboardTheme.failure)
        }
    }
    
    ///Dashboard UI
    private var dashboardView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weather Dashboard")
                .font(.largeTitle)
            /// Gives the application a text identifying itself as a 'weather dashboard'
            HStack(spacing: 8) {
                Text("Location")
                
                StationLibraryPicker(
                    selection: $selectedLocation,
                    locations: availableLocations
                )
                .onChange(of: selectedLocation) {
                    Task {
                        await refreshWeather()
                    }
                }

                Menu {
                    Button {
                        stationAdderRequest = StationAdderRequest(
                            initialStationID: ""
                        )
                    } label: {
                        Label(
                            "Add Station...",
                            systemImage: "plus"
                        )
                    }

                    Divider()

                    Button(role: .destructive) {
                        isShowingStationRemovalConfirmation = true
                    } label: {
                        Label(
                            "Remove Current Location...",
                            systemImage: "trash"
                        )
                    }
                    .disabled(
                        selectedSavedGeneratedStation == nil
                    )
                } label: {
                    Image(systemName: "ellipsis")
                        .font(
                            .system(
                                size: 15,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.white)
                        .accessibilityLabel("Manage Stations")
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 50, height: 32)
                .background {
                    RoundedRectangle(
                        cornerRadius: 8,
                        style: .continuous
                    )
                    .fill(
                        DashboardTheme.observedTemperature
                    )
                }
                .overlay {
                    RoundedRectangle(
                        cornerRadius: 8,
                        style: .continuous
                    )
                    .stroke(
                        Color.white.opacity(0.22),
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
                .shadow(
                    color:
                        DashboardTheme.observedTemperature
                            .opacity(0.28),
                    radius: 4,
                    y: 1
                )
                .help("Manage Stations")
                
            }
            .controlSize(.large)

            HStack(spacing: 10) {
                Text("Station: \(selectedLocation.displayStationID)")
                    .font(.headline)
                
                stationRefreshStatus
                    .font(.subheadline.weight(.semibold))
            }
                        
            Divider()
            
            /// Dashboard's main HStack here.
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 12) {
                    leftDashboardPanel
                    dashboardActionButtons
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    temperatureChart
                    climateAtAGlanceSection
                }
            }

            ///Network status
            Text(networkStatus)
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
    
    /// Dashboard controls that live beneath the left information cards.
    private var dashboardActionButtons: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(
                isLoading
                    ? "Refreshing..."
                    : "Refresh Weather"
            ) {
                Task {
                    await refreshWeather()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(isLoading)
            
            Button(
                isLoadingForecastDiscussion
                    ? "Loading Discussion..."
                    : "Show Forecast Discussion"
            ) {
                Task {
                    await loadForecastDiscussion()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(isLoadingForecastDiscussion)
            
            Menu("Climate ▾") {
                Button("Show Annual Temperature Curve") {
                    selectedClimateGraph =
                        .annualTemperatureCurve
                    activeClimateGraph =
                        .annualTemperatureCurve
                }
                
                Button("Show Seasonal Hysteresis Curve") {
                    selectedClimateGraph =
                        .seasonalHysteresisCurve
                    activeClimateGraph =
                        .seasonalHysteresisCurve
                }
                
                Button("Show Threshold Seasons") {
                    selectedClimateGraph =
                        .thresholdSeasons
                    activeClimateGraph =
                        .thresholdSeasons
                }
                
                Button("Show Weather Year Graph") {
                    selectedClimateGraph =
                        .weatherForTheYear
                    activeClimateGraph =
                        .weatherForTheYear
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
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
    
    /// A compact card inside Climate-at-a-Glance.
    /// Real chart content will replace the subtitle later.
    private func climateAtAGlanceCard(
        title: String,
        subtitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Image(
                    systemName:
                        "arrow.up.left.and.arrow.down.right"
                )
                .font(.caption)
                .foregroundStyle(DashboardTheme.textSecondary)
            }
            
            Spacer()
            
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(DashboardTheme.textSecondary)
        }
        .padding(12)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background(DashboardTheme.plotArea)
        .clipShape(
            RoundedRectangle(cornerRadius: DashboardTheme.cardCornerRadius)
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: DashboardTheme.cardCornerRadius
            )
            .stroke(
                DashboardTheme.border,
                lineWidth: 1
            )
        }
    }
    
    /// Creates the two phase datasets; one for s(t) and one for T min
    private var climatologicalSeasonalPhasePoints:
    [SeasonalPhasePoint] {
        (1...365).map { dayOfYear in
            SeasonalPhasePoint(
                dayOfYear: dayOfYear,
                normalizedSolar: selectedLocation.normalizedSolarEnergy(dayOfYear: dayOfYear),
                minimumTemperature: selectedLocation.normalLow(dayOfYear: dayOfYear)
            )
        }
    }
    
    private var liveSeasonalPhasePoints:
    [SeasonalPhasePoint] {
        liveWeatherYearDays.compactMap { day in
            guard let minimumTemperature = day.selectedYearMinimum
            else {
                return nil
            }
            
            return SeasonalPhasePoint(
                dayOfYear: day.dayOfYear,
                normalizedSolar: selectedLocation.normalizedSolarEnergy(dayOfYear: day.dayOfYear),
                minimumTemperature: minimumTemperature
            )
        }
    }
    
    /// Creates the shared smoothed series for our hysteresis widget and graph.
    private func referenceDayOfYear(for date: Date) -> Int? {
        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = selectedLocation.timeZone
        
        let components = localCalendar.dateComponents([.month, .day], from: date)
        
        guard let month = components.month,
              var day = components.day else {
            return nil
        }
        
        if month == 2 && day == 29 {
            day = 28
        }
        
        var referenceCalendar = Calendar(identifier: .gregorian)
        referenceCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        guard let referenceDate = referenceCalendar.date(
            from: DateComponents(year: 2001, month: month, day: day)
        ) else {
            return nil
        }
        
        return referenceCalendar.ordinality(
            of: .day,
            in: .year,
            for: referenceDate
        )
    }
    
    /// This function forces any integer onto the repeating interval 1...365. For example 370 % 365 == 5, because day 370 is day 5.
    /// The extra + 365 makes it so we don't have a negative remainder.
    private func wrappedClimateDay(_ day: Int) -> Int {
        ((day - 1) % 365 + 365) % 365 + 1
    }
    
    /// Returns a array like [ 207:68.3, 208: 67.1, 209: 69.0 ] The integer is a dictionary entry.
    private var forecastDailyMinimumsByDayOfYear: [Int: Double] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = selectedLocation.timeZone
        
        let today = calendar.startOfDay(for: Date())
        
        ///.filter examines every element and keeps only those for which the closure returns true. point is one
        ///hourly forecast point, we find its station-local calendar day. If that day is later than today, keep it, otherwise discard.
        let futurePoints = temperatureForecast.filter { point in
            calendar.startOfDay(for: point.timestamp) > today
        }
        
        ///Groups all hourly points sharing the same station-local date.
        ///That lets us calculate one minimum temperature from each day's hourly points
        let groupedPoints = Dictionary(grouping: futurePoints) { point in
            calendar.startOfDay(for: point.timestamp)
        }
        
        /// convert the date to a climatological day number, extract every hourly temperature, find the ssmallest temperature,
        /// if either operation fails, skip that entry
        return groupedPoints.reduce(into: [:]) { result, entry in
            let date = entry.key
            let points = entry.value
            
            guard let dayOfYear = referenceDayOfYear(for: date),
                  let minimum = points.map(\.temperatureFahrenheit).min() else {
                return
            }
            
            result[dayOfYear] = minimum
        }
    }
    
    private var smoothedLiveSeasonalPhasePoints: [SeasonalPhasePoint] {
        let observedPoints = liveSeasonalPhasePoints
        
        let observedMinimums = Dictionary(
            uniqueKeysWithValues: observedPoints.map {
                ($0.dayOfYear, $0.minimumTemperature)
            }
        )
        
        let forecastMinimums = forecastDailyMinimumsByDayOfYear
        
        ///creates a new dictionary containing entries from both dictionaries. the closure is needed in case both
        ///dictionaries contain the same day. The underscore means swift passes the existing observed value here,
        ///but we intentionally do not need to name or use it.
        let combinedMinimums = observedMinimums.merging(forecastMinimums) {
            _, forecastValue in forecastValue
        }
        
        let latestObservedDay = observedPoints.map(\.dayOfYear).max()
        
        /// .compactMap transforms each input into a new value, discards any transformation that returns nil.
        
        return observedPoints.compactMap { point in
            if point.dayOfYear == latestObservedDay {
                let hasFiveForecastDays = (1...5).allSatisfy { offset in
                    let day = wrappedClimateDay(point.dayOfYear + offset)
                    return forecastMinimums[day] != nil
                }
                
                guard hasFiveForecastDays else {
                    return nil
                }
            }
            
            /// From -5 to 5 because we do a 5-day rolling average. compactMap discards days whose temperature is unavailable.
            let temperatures = (-5...5).compactMap { offset in
                let day = wrappedClimateDay(point.dayOfYear + offset)
                return combinedMinimums[day]
            }
            
            ///Needs at least 7 usable values, so 3 days before, 3 days after, and the center day.
            guard temperatures.count >= 7 else {
                return nil
            }
            
            ///Adds the temperatures and divides by how many.
            let average = temperatures.reduce(0,+) / Double(temperatures.count)
            
            /// return the raw Tmin with the local moving average.
            return SeasonalPhasePoint(
                dayOfYear: point.dayOfYear,
                normalizedSolar: point.normalizedSolar,
                minimumTemperature: average
            )
        }
    }
    
    private var seasonalPhaseYDomain:
    ClosedRange<Double> {
        let temperatures =
            climatologicalSeasonalPhasePoints.map(
                \.minimumTemperature
            )
            + liveSeasonalPhasePoints.map(
                \.minimumTemperature
            )
        
        guard
            let minimum = temperatures.min(),
            let maximum = temperatures.max()
        else {
            return 0.0...100.0
        }
        
        return (minimum - 5.0)...(maximum + 5.0)
    }
    
    /// Calculate our standard deviation for thermal pace. Takes the climate normal and shows the standard deviation
    /// of temperature for max/min for a given date.
    private func thermalPaceStandardDeviation(month: Int, day: Int) -> Double? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        let values = thresholdNormalPeriodObservations.compactMap { observation -> Double? in
            guard calendar.component(.month, from: observation.date) == month,
                  calendar.component(.day, from: observation.date) == day else {
                return nil
            }
            
            switch selectedThermalPaceVariable {
            case .minimum:
                return observation.minimumTemperature
            case .maximum:
                return observation.maximumTemperature
            }
        }
        
        guard values.count >= 10 else {
            return nil
        }
        
        /// Calculates the arithmetic mean.
        let mean = values.reduce(0, +) / Double(values.count)
        
        ///For each value, subtract it from the mean, then square it and add them all up at the end
        let squaredDeviations = values.reduce(0.0) { total, value in
            total + pow(value - mean, 2)
        }
        
        /// Sample standard deviation because the available normal-period observations estimate
        /// the broadder climatic distribution. Requiring ten observations prevents a visually authoritative
        /// band from being generated from a tiny sample.
        return sqrt(
            squaredDeviations / Double(values.count - 1)
        )
    }
    
    /// Generate the 29 fitted-normal points
    private var thermalPacePoints: [ThermalPacePoint] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = selectedLocation.timeZone
        
        let today = calendar.startOfDay(for: Date())
        
        return (-14...14).compactMap { dayOffset in
            guard let date = calendar.date(
                byAdding: .day,
                value: dayOffset,
                to: today
            ) else {
                return nil
            }
            
            let month = calendar.component(.month, from: date)
            var day = calendar.component(.day, from: date)
            
            /// The climate fits use a 365-day year.
            if month == 2 && day == 29 {
                day = 28
            }
            
            var referenceComponents = DateComponents()
            referenceComponents.calendar = calendar
            referenceComponents.timeZone = selectedLocation.timeZone
            referenceComponents.year = 2001
            referenceComponents.month = month
            referenceComponents.day = day
            
            guard
                let referenceDate = calendar.date(
                    from: referenceComponents
                ),
                let climateDay = calendar.ordinality(
                    of: .day,
                    in: .year,
                    for: referenceDate
                )
            else {
                return nil
            }
            
            let temperature: Double
            let standardDeviation = thermalPaceStandardDeviation(
                month: month,
                day: day
            )
            
            switch selectedThermalPaceVariable {
            case .minimum:
                temperature = selectedLocation.normalLow(
                    dayOfYear: climateDay
                )
                
            case .maximum:
                temperature = selectedLocation.normalHigh(
                    dayOfYear: climateDay
                )
            }
            
            return ThermalPacePoint(
                dayOffset: dayOffset,
                date: date,
                temperature: temperature,
                standardDeviation: standardDeviation
            )
        }
    }
    
    /// y Range domain helper. The idea is we want the y-axis to be 10 deg F above and below the bounds of what is shown on the screen.
    /// So let's say you are centered at a date, and 14 days before T min is 72. 14 days later T min is 62. Well then we would want the yRange to be
    /// from 82 to 52. This gives us a not-too-big yRange. We will also add standard deviation later so the plus minus 10 rule gives us cushioning
    
    private func thermalPaceYDomain(
        for points: [ThermalPacePoint]
    ) -> ClosedRange<Double> {
        let bandValues = points.flatMap { point -> [Double] in
            guard let standardDeviation = point.standardDeviation else {
                return [point.temperature]
            }

            return [
                point.temperature - standardDeviation,
                point.temperature + standardDeviation
            ]
        }

        guard let minimumValue = bandValues.min(),
              let maximumValue = bandValues.max() else {
            return 0.0...100.0
        }

        let includesSpread = points.contains {
            $0.standardDeviation != nil
        }

        let padding = includesSpread ? 2.0 : 8.0

        return (minimumValue - padding)...(maximumValue + padding)
    }
    
    private func thermalPaceAxisAnchor(index: Int, count: Int) -> UnitPoint {
        if index == 0 {
            return .topLeading
        }
        
        if index == count - 1 {
            return .topTrailing
        }
        
        return .top
    }
    
    ///Adds the specialized card. Puts all the points in the climatological phase portrait.
    private var liveSeasonalPhaseCard: some View {
        let climatePoints =
            climatologicalSeasonalPhasePoints
        
        let observedPoints =
            liveSeasonalPhasePoints
        
        let smoothedPoints =
            smoothedLiveSeasonalPhasePoints
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Live Seasonal Phase")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    selectedClimateGraph = .seasonalHysteresisCurve
                    activeClimateGraph = .seasonalHysteresisCurve
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption)
                        .foregroundStyle(DashboardTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .help("Open full seasonal hysteresis chart.")
            }
            
            Chart {
                
                ///Climatology purple curve
                ForEach(climatePoints) { point in
                    LineMark(
                        x: .value(
                            "Normalized Solar",
                            point.normalizedSolar
                        ),
                        y: .value(
                            "Normal Tmin",
                            point.minimumTemperature
                        ),
                        series: .value(
                            "Series",
                            "Climatology"
                        )
                    )
                    .foregroundStyle(
                        Color(
                            red: 0.78,
                            green: 0.25,
                            blue: 0.95
                        )
                    )
                    .lineStyle(
                        StrokeStyle(
                            lineWidth: 2.0,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                }
                
                ///5-day rolling average smoothed
                ForEach(smoothedPoints) { point in
                    LineMark(
                        x: .value("Normalized Solar", point.normalizedSolar),
                        y: .value("Smoothed Tmin", point.minimumTemperature),
                        series: .value("Series", "Current Weather Year")
                    )
                    .foregroundStyle(DashboardTheme.observedTemperature)
                    .lineStyle(StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round))
                }
                
                ///Observed 'chaotic' T min plotted
                ForEach(observedPoints) { point in
                    PointMark(
                        x: .value(
                            "Normalized Solar",
                            point.normalizedSolar
                        ),
                        y: .value(
                            "Observed Tmin",
                            point.minimumTemperature
                        )
                    )
                    .foregroundStyle(
                        Color.white.opacity(0.42)
                    )
                    .symbolSize(9)
                }
                
                if let latestPoint = smoothedPoints.last {
                    PointMark(
                        x: .value(
                            "Latest Solar",
                            latestPoint.normalizedSolar
                        ),
                        y: .value(
                            "Latest Tmin",
                            latestPoint.minimumTemperature
                        )
                    )
                    .foregroundStyle(
                        DashboardTheme.observedTemperature
                    )
                    .symbolSize(38)
                }
            }
            .chartLegend(.hidden)
            .chartXScale(domain: 0.0...1.0)
            .chartYScale(domain: seasonalPhaseYDomain)
            .chartXAxis {
                AxisMarks(values: [0.0, 0.5, 1.0]) { _ in
                    AxisGridLine()
                        .foregroundStyle(
                            Color.white.opacity(0.08)
                        )
                    
                    AxisValueLabel()
                        .font(.caption)
                        .foregroundStyle(
                            DashboardTheme.textSecondary
                        )
                }
            }
            .chartYAxis {
                AxisMarks(
                    position: .leading,
                    values: .automatic(desiredCount: 3)
                ) { _ in
                    AxisGridLine()
                        .foregroundStyle(
                            Color.white.opacity(0.08)
                        )
                    
                    AxisValueLabel()
                        .font(.caption)
                        .foregroundStyle(
                            DashboardTheme.textSecondary
                        )
                }
            }
            .frame(
                minHeight: 90,
                maxHeight: .infinity
            )
            
            Text(liveSeasonalPhaseStatus)
                .font(.caption)
                .foregroundStyle(
                    DashboardTheme.textSecondary
                )
        }
        .padding(12)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background(DashboardTheme.plotArea)
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                    DashboardTheme.cardCornerRadius
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius:
                    DashboardTheme.cardCornerRadius
            )
            .stroke(
                DashboardTheme.border,
                lineWidth: 1
            )
        }
    }
    
    /// Create the seasonal normal climate widget. Gives us station-local calendar handling. Automatic zoomed y-axis.
    /// A gold fitted-normal curve. A blue point and dashed rule identifying today, working Tmax and Tmin switching
    private var thermalPaceCard: some View {
        let points = thermalPacePoints
        
        let yDomain = thermalPaceYDomain(for: points)
        
        let axisDates = points
            .filter { point in
                [-14, 0, 14].contains(point.dayOffset)
            }
            .map(\.date)
        
        let todayPoint = points.first {
            $0.dayOffset == 0
        }
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("Thermal Pace")
                    .font(.headline)
                
                Spacer()
                
                Picker(
                    "Thermal variable",
                    selection: $selectedThermalPaceVariable
                ) {
                    ForEach(ThermalPaceVariable.allCases) { variable in
                        Text(variable.label)
                            .tag(variable)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 100)
                
                Button {
                    selectedClimateGraph = .annualTemperatureCurve
                    activeClimateGraph = .annualTemperatureCurve
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption)
                        .foregroundStyle(DashboardTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .help("Open annual temperature curve.")
                .font(.caption)
                .foregroundStyle(DashboardTheme.textSecondary)
            }
            
            Chart {
                ///Adds standard-deviation band to the thermal pace chart.
                ForEach(points) { point in
                    if let standardDeviation = point.standardDeviation {
                        AreaMark(
                            x: .value("Date", point.date),
                            yStart: .value(
                                "Lower sigma",
                                point.temperature - standardDeviation
                            ),
                            yEnd: .value(
                                "Upper sigma",
                                point.temperature + standardDeviation
                            )
                        )
                        .foregroundStyle(Color.white.opacity(0.11))
                        .interpolationMethod(.catmullRom)
                    }
                }
                
                ForEach(points) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(
                            "Normal temperature",
                            point.temperature
                        )
                    )
                    .foregroundStyle(DashboardTheme.normal)
                    .lineStyle(
                        StrokeStyle(
                            lineWidth: 2.2,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                
                if let todayPoint {
                    RuleMark(
                        x: .value("Today", todayPoint.date)
                    )
                    .foregroundStyle(
                        Color.white.opacity(0.25)
                    )
                    .lineStyle(
                        StrokeStyle(
                            lineWidth: 1,
                            dash: [3, 3]
                        )
                    )
                    
                    PointMark(
                        x: .value("Today", todayPoint.date),
                        y: .value(
                            "Current normal",
                            todayPoint.temperature
                        )
                    )
                    .foregroundStyle(
                        DashboardTheme.observedTemperature
                    )
                    .symbolSize(32)
                }
            }
            .chartLegend(.hidden)
            .chartYScale(domain: yDomain)
            .chartXScale(
                range: .plotDimension(
                    startPadding: 18,
                    endPadding: 18
                )
            )
            .chartPlotStyle { plotArea in
                plotArea
                    .background(DashboardTheme.plotArea)
            }
            .chartXAxis {
                AxisMarks(values: axisDates) { axisValue in
                    AxisTick()
                        .foregroundStyle(DashboardTheme.textSecondary)

                    AxisValueLabel(
                        format: .dateTime.month(.abbreviated).day(),
                        anchor: thermalPaceAxisAnchor(
                            index: axisValue.index,
                            count: axisValue.count
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(DashboardTheme.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks(
                    position: .leading,
                    values: .automatic(desiredCount: 3)
                ) { _ in
                    AxisGridLine()
                        .foregroundStyle(
                            Color.white.opacity(0.08)
                        )
                    
                    AxisValueLabel()
                        .font(.caption)
                        .foregroundStyle(
                            DashboardTheme.textSecondary
                        )
                }
            }
            .environment(
                \.timeZone,
                selectedLocation.timeZone
            )
            .frame(
                minHeight: 76,
                maxHeight: .infinity
            )
            
            Text(
                "\(selectedThermalPaceVariable.label) normal ± 1σ • ±14 days"
            )
            .font(.caption)
            .foregroundStyle(DashboardTheme.textSecondary)
        }
        .padding(12)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background(DashboardTheme.plotArea)
        .clipShape(
            RoundedRectangle(
                cornerRadius: DashboardTheme.cardCornerRadius
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: DashboardTheme.cardCornerRadius
            )
            .stroke(
                DashboardTheme.border,
                lineWidth: 1
            )
        }
    }
    
    ///Places a reference date for our threshold seasons climate widget.
    private var selectedLocationReferenceDayOfYear: Double {
        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = selectedLocation.timeZone
        
        let localComponents = localCalendar.dateComponents(
            [.month, .day],
            from: Date()
        )
        
        var referenceCalendar = Calendar(identifier: .gregorian)
        referenceCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        guard let month = localComponents.month,
              let day = localComponents.day,
              let referenceDate = referenceCalendar.date(
                from: DateComponents(year: 2001, month: month, day : day)
              ),
              let dayOfYear = referenceCalendar.ordinality(
                of: .day,
                in: .year,
                for: referenceDate
              ) else {
            return 1.0
        }
        
        return Double(dayOfYear)
    }
    
    /// Creates an adaptive selector and display its chosen threshold as a compact row.
    /// It requires a climatologically meaningful spring lock-in, at least 15 complete seasons.
    /// Most importantly today lying between the 90% spring and fall outer boudnaries -- at least 10%
    /// historical season membership. Of all the qualifying  thresholds, select the highest.
    private var adaptiveWarmLockInSummary: ACISThresholdSummary? {
        let currentDay = selectedLocationReferenceDayOfYear
        
        return thresholdWidgetWarmSummaries
            .filter { summary in
                let ninetyPercentPoint = summary.thresholdRiskPoints.first {
                    $0.percent == 90.0
                }
                
                guard summary.hasMeaningfulSpringLockIn,
                      summary.completeSeasonCount >= 15,
                      let springOuterDay = ninetyPercentPoint?.springRiskDay,
                      let fallOuterDay = ninetyPercentPoint?.fallRiskDay else {
                    return false
                }
                
                return currentDay >= springOuterDay &&
                    currentDay <= fallOuterDay
            }
            .max { firstSummary, secondSummary in
                firstSummary.threshold < secondSummary.threshold
            }
    }
    
    private var thresholdSeasonsCard: some View {
        let tenPercentRiskPoint = thresholdWidgetFreezeSummary?
            .thresholdRiskPoints
            .first { $0.percent == 10.0 }
        
        let ninetyPercentRiskPoint = thresholdWidgetFreezeSummary?
            .thresholdRiskPoints
            .first { $0.percent == 90.0 }
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Threshold Seasons")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    selectedClimateGraph = .thresholdSeasons
                    activeClimateGraph = .thresholdSeasons
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption)
                        .foregroundStyle(DashboardTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .help("Open threshold seasons.")
            }
            
            if let freezeSummary = thresholdWidgetFreezeSummary {
                HStack(spacing: 10) {
                    Image(systemName: "snowflake")
                        .font(.title3)
                        .foregroundStyle(.cyan)
                        .frame(width: 26)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("32°F Freeze-Free")
                            .font(.subheadline.weight(.semibold))
                        
                        Text("10-90% climatological bounds")
                            .font(.caption2)
                            .foregroundStyle(DashboardTheme.textSecondary)
                    }
                    
                    Spacer()
                }
                
                if let leftOuterDay = ninetyPercentRiskPoint?.springRiskDay,
                   let leftInnerDay = tenPercentRiskPoint?.springRiskDay,
                   let rightInnerDay = tenPercentRiskPoint?.fallRiskDay,
                   let rightOuterDay = ninetyPercentRiskPoint?.fallRiskDay {
                    
                    SeasonalWindowBar(
                        leftOuterDay: leftOuterDay,
                        leftInnerDay: leftInnerDay,
                        rightInnerDay: rightInnerDay,
                        rightOuterDay: rightOuterDay,
                        currentDay: selectedLocationReferenceDayOfYear
                    )
                } else {
                    Text("No defined freeze-free season.")
                        .font(.caption)
                        .foregroundStyle(DashboardTheme.textSecondary)
                }
                
                if let warmSummary = adaptiveWarmLockInSummary {
                    let tenPercentPoint = warmSummary.thresholdRiskPoints.first {
                        $0.percent == 10.0
                    }
                    
                    let ninetyPercentPoint = warmSummary.thresholdRiskPoints.first {
                        $0.percent == 90.0
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "sun.max.fill")
                                .foregroundStyle(DashboardTheme.normal)
                            
                            Text(
                                "\(warmSummary.threshold, specifier: "%.0f")°F+ Afternoon Lock-In"
                            )
                            .font(.caption.weight(.semibold))
                            
                            Spacer()
                        }
                        
                        if let leftOuterDay = ninetyPercentPoint?.springRiskDay,
                           let leftInnerDay = tenPercentPoint?.springRiskDay,
                           let rightInnerDay = tenPercentPoint?.fallRiskDay,
                           let rightOuterDay = ninetyPercentPoint?.fallRiskDay {
                            
                            SeasonalWindowBar(
                                leftOuterDay: leftOuterDay,
                                leftInnerDay: leftInnerDay,
                                rightInnerDay: rightInnerDay,
                                rightOuterDay: rightOuterDay,
                                currentDay: selectedLocationReferenceDayOfYear
                            )
                        }
                    }
                }
                
                Spacer()
                
                Text("\(freezeSummary.completeSeasonCount) complete seasons")
                    .font(.caption)
                    .foregroundStyle(DashboardTheme.textSecondary)
            } else {
                Spacer()
                
                Text(thresholdWidgetStatus)
                    .font(.caption)
                    .foregroundStyle(DashboardTheme.textSecondary)
            }
        }
        .padding(12)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background(DashboardTheme.plotArea)
        .clipShape(
            RoundedRectangle(cornerRadius: DashboardTheme.cardCornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: DashboardTheme.cardCornerRadius)
                .stroke(DashboardTheme.border, lineWidth: 1)
        }
    }
    
    private var climateAtAGlanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Climate at a Glance")
                .font(.headline)
                .foregroundStyle(DashboardTheme.textPrimary)
            
            HStack(spacing: 8) {
                liveSeasonalPhaseCard
                
                thermalPaceCard
                
                thresholdSeasonsCard
            }
            .frame(height: 260)
        }
        .padding(12)
        .frame(width: 892, alignment: .leading)
        .background(DashboardTheme.panel)
        .clipShape(
            RoundedRectangle(cornerRadius: DashboardTheme.cardCornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: DashboardTheme.cardCornerRadius)
            .stroke(
                DashboardTheme.border,
                lineWidth: 1
            )
        }
    }
    
    ///Current year loader.
    private func loadLiveWeatherYear() async {
        let requestedLocation = selectedLocation
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = requestedLocation.timeZone
        
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        let currentDay = calendar.component(.day, from: now)
        
        let startDate = "\(currentYear)-01-01"
        
        let endDate = String(
            format: "%04d-%02d-%02d",
            currentYear,
            currentMonth,
            currentDay
        )
        
        liveWeatherYearDays = []
        liveSeasonalPhaseStatus = "Loading \(currentYear) daily minima"
        
        do {
            let observations =
                try await ACISClimateService
                    .fetchDailyObservations(
                        stationID: requestedLocation.acisStationID,
                        startDate: startDate,
                        endDate: endDate
                    )
            
            /// Ignore a result if the user selected another location whilst this request was running.
            guard
                Task.isCancelled == false,
                selectedLocation.id == requestedLocation.id
            else {
                return
            }
            
            let weatherYearDays =
                WeatherYearCalculator.weatherYearDays(
                    from: observations,
                    selectedYear: currentYear,
                    location: requestedLocation
                )
            
            liveWeatherYearDays = weatherYearDays
            
            let minimumCount = weatherYearDays
                .compactMap { day in
                    day.selectedYearMinimum
                }
                .count
            
            if minimumCount == 0 {
                liveSeasonalPhaseStatus = "No current-year daily minima available."
            } else {
                liveSeasonalPhaseStatus = "\(minimumCount) current-year daily minima loaded."
            }
        } catch {
            guard
                Task.isCancelled == false,
                selectedLocation.id == requestedLocation.id
            else {
                return
            }
            
            liveWeatherYearDays = []
            liveSeasonalPhaseStatus = "Current-year climate data unavailable."
        }
    }
    
    ///Threshold loader. Only requests Tmax and Tmin because that's all we need.
    private func loadThresholdWidgetClimateData() async {
        let requestedLocation = selectedLocation
        
        thresholdNormalPeriodObservations = []
        thresholdWidgetWarmSummaries = []
        thresholdWidgetFreezeSummary = nil
        thresholdWidgetStatus = "Loading 1991-2020 threshold data..."
        
        do {
            let observations =
                try await ACISClimateService
                    .fetchNormalPeriodTemperatureObservations(stationID: requestedLocation.acisStationID)
            
            guard
                Task.isCancelled == false,
                    selectedLocation.id == requestedLocation.id
            else {
                return
            }
            
            thresholdNormalPeriodObservations = observations
            
            let pairedTemperatureCount = observations.filter { observation in
                observation.minimumTemperature != nil && observation.maximumTemperature != nil
            }
                .count
            
            if pairedTemperatureCount == 0 {
                thresholdWidgetStatus = "No normal-period temperature data"
            } else {
                let freezeSummary =
                    ACISThresholdCalculator.thresholdSummary(
                        from: observations,
                        startYear: GeneratedClimateProfileBuilder.normalStartYear,
                        endYear: GeneratedClimateProfileBuilder.normalEndYear,
                        threshold: 32.0,
                        field: .minimum,
                        comparison: .lessThanOrEqual,
                        springEventChoice: .last,
                        fallEventChoice: .first
                    )

                thresholdWidgetFreezeSummary = freezeSummary
                
                let warmMode = ThresholdEventMode.warmAfternoonLockIn
                
                thresholdWidgetWarmSummaries = warmMode.thresholdPresets.map { threshold in
                    ACISThresholdCalculator.thresholdSummary(
                        from: observations,
                        startYear: GeneratedClimateProfileBuilder.normalStartYear,
                        endYear: GeneratedClimateProfileBuilder.normalEndYear,
                        threshold: threshold,
                        field: warmMode.field,
                        comparison: warmMode.comparison,
                        springEventChoice: warmMode.springEventChoice,
                        fallEventChoice: warmMode.fallEventChoice
                    )
                }

                let medianRiskPoint =
                    freezeSummary.thresholdRiskPoints.first { riskPoint in
                        riskPoint.percent == 50.0
                    }

                let springText =
                    ACISThresholdCalculator.monthDayText(
                        fromAverageDayOfYear: medianRiskPoint?.springRiskDay
                    )

                let fallText =
                    ACISThresholdCalculator.monthDayText(
                        fromAverageDayOfYear: medianRiskPoint?.fallRiskDay
                    )

                if springText == "none" && fallText == "none" {
                    thresholdWidgetStatus = "No defined 32°F freeze season"
                } else {
                    thresholdWidgetStatus =
                        "32°F freeze-free: \(springText) → \(fallText)"
                }
            }
        } catch {
            guard
                Task.isCancelled == false,
                selectedLocation.id == requestedLocation.id
            else {
                return
            }
            
            thresholdNormalPeriodObservations = []
            thresholdWidgetWarmSummaries = []
            thresholdWidgetFreezeSummary = nil
            thresholdWidgetStatus = "Threshold climate data unavailable"
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
    
    /// Current conditions grid only displays measurements after a successful station refresh.
    private func currentConditionText(
        _ value: Double?,
        decimalPlaces: Int = 1
    ) -> String {
        ///Continue only if weatherRefreshState matches the .updated case. Otherwise, return an em dash.
        guard case .updated = weatherRefreshState,
              let value else {
            return "—"
        }
        
        return value.formatted(
            .number.precision(
                .fractionLength(decimalPlaces)
            )
        )
    }
    
    private var currentConditionDescription: String {
        guard case .updated = weatherRefreshState else {
            return "Unavailable"
        }
        
        return observation.condition
    }
    
    private var currentConditionsGrid: some View { /// this is the same currentConditionsGrid that was called in line 187.
        Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 8) {
            /// Makes sure the grid is nice and neat. Solves the problem of some weather parameters like Temperature
            ///  having much longer names than something like Wind. All nice and lined up.
            GridRow {
                Text("Air Temperature")
                Text(currentConditionText(observation.airTemperature)) /// Makes it so air temperature is a floating point number with just one digit after the decimal.
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
                Text(currentConditionText(observation.dewPoint))
                    .monospacedDigit()
                Text("°F")
            }

            GridRow {
                Text("Heat index")
                Text(currentConditionText(observation.heatIndex))
                    .monospacedDigit()
                Text("°F")
            }

            GridRow {
                Text("Relative Humidity")
                Text(currentConditionText(observation.relativeHumidity))
                    .monospacedDigit()
                Text("%")
            }

            GridRow {
                Text("Wind Speed")
                Text(currentConditionText(observation.windSpeed))
                    .monospacedDigit()
                Text("mph")
            }

            GridRow {
                Text("Pressure")
                Text(
                    currentConditionText(
                        observation.pressure,
                        decimalPlaces: 2
                    )
                )
                .monospacedDigit()
                
                Text("inHg")
            }

            GridRow {
                Text("Wet Bulb")
                Text(currentConditionText(observation.wetBulb))
                    .monospacedDigit()
                Text("°F")
            }

            GridRow {
                Text("Evaporative Cooling Potential")
                Text(currentConditionText(observation.coolingPotential))
                    .monospacedDigit()
                Text("°F")
            }
            
            GridRow {
                Text("Conditions")
                Text(currentConditionDescription)
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
            longitude: selectedLocation.longitude,
            timeZone: selectedLocation.timeZone
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
            /// Horizontal 5°F guides.
            ForEach(Array(stride(from: chartTemperatureDomain.lowerBound, through: chartTemperatureDomain.upperBound, by: 5.0)), id: \.self) { temperature in
                RuleMark(y: .value("Temperature grid", temperature))
                    .foregroundStyle(DashboardTheme.chartGridMajor)
                    .lineStyle(StrokeStyle(lineWidth: 0.65))
            }

            /// Time guides matching the current dashboard duration.
            ForEach(Array(stride(from: chartTimeDomain.lowerBound, through: chartTimeDomain.upperBound, by: Double(chartXAxisHourStride) * 60 * 60)), id: \.self) { date in
                RuleMark(x: .value("Time grid", date))
                    .foregroundStyle(DashboardTheme.chartGridMinor)
                    .lineStyle(StrokeStyle(lineWidth: 0.6, dash: [3, 5]))
            }
            
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
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.65))
                    .foregroundStyle(DashboardTheme.chartGridMajor)
                AxisTick()
                    .foregroundStyle(DashboardTheme.textSecondary)
                AxisValueLabel()
                    .foregroundStyle(DashboardTheme.textSecondary)
            }
        }
        
        /// This makes it so if 72 hours is selected, the x axis doesn't have labeled tick marks every 3 pixels so it looks fucked up. spaced more out
        /// on longer durations.
        /// Main temperature chart.
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: chartXAxisHourStride)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.6, dash: [3, 5]))
                    .foregroundStyle(DashboardTheme.chartGridMinor)
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
            ///Switch between the two screens, either the dashboard or the climate atlas.
            ///Switch guarantees that exactly one screen is being displayed. Because all the dashboard data remains owned
            ///by ContentView, switching to Atlas should not erase the selected station or downloaded weather data.
            
            /// Both screens remain alive for the lifetime of the app in runtime.
            /// The inactive screen is invisible and cannot receive input.
            
            ZStack {
                dashboardView
                    .padding()
                    .frame(
                        minWidth: 1210,
                        maxWidth: .infinity,
                        minHeight: 550,
                        maxHeight: .infinity,
                        alignment: .topLeading
                    )
                    .opacity(
                        selectedAppSection == .dashboard
                            ? 1
                            : 0
                    )
                    .allowsHitTesting(
                        selectedAppSection == .dashboard
                    )
                    .accessibilityHidden(
                        selectedAppSection != .dashboard
                    )
                
                ClimateAtlasView(
                    selectedAppSection:
                        $selectedAppSection,
                    onBuildClimateProfile: {
                        observation in
                        
                        stationAdderRequest =
                            StationAdderRequest(
                                initialStationID:
                                    observation
                                        .station
                                        .source
                                        .stationID
                            )
                    }
                )
                .opacity(
                    selectedAppSection == .atlas
                        ? 1
                        : 0
                )
                .allowsHitTesting(
                    selectedAppSection == .atlas
                )
                .accessibilityHidden(
                    selectedAppSection != .atlas
                )
            }
        }
            .overlay(alignment: .top) {
                AppSectionPicker(
                    selection: $selectedAppSection
                )
                .padding(.top, 20)
            }
            /// Load the user-created stations.
            .task {
                loadGeneratedStations()
            }
        
            /// Load weather year data automatically for each selected station
            .task(id: selectedLocation.id) {
                await loadLiveWeatherYear()
            }
        
            /// Trigger threshold widget on station selection.
            .task(id: selectedLocation.id) {
                await loadThresholdWidgetClimateData()
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
        
            .focusedSceneValue(\.selectAppSection) { section in
                selectedAppSection = section
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
                    location: selectedLocation,
                    liveSeasonalPhasePoints: liveSeasonalPhasePoints,
                    smoothedLiveSeasonalPhasePoints: smoothedLiveSeasonalPhasePoints,
                    normalPeriodObservations: thresholdNormalPeriodObservations
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
            .sheet(
                item: $stationAdderRequest
            ) { request in
                StationAdderView(
                    initialStationID:
                        request.initialStationID
                ) { result in
                    saveGeneratedStation(result)
                    selectedAppSection = .dashboard
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
        weatherRefreshState = .refreshing
        
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
            let forecast = try? await service.fetchHourlyForecast(
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
            
            temperatureForecast = forecast?.properties.periods.compactMap { period in
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
            } ?? []
            
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
                let pressureInHg = latestObservation.properties.barometricPressure.value.map { pressurePascals in
                    WeatherMath.pascalsToInchesOfMercury(pressurePascals)
                }

                let fahrenheit = WeatherMath.celsiusToFahrenheit(temperature)
                let dewpointFahrenheit = WeatherMath.celsiusToFahrenheit(dewpoint)
                let windSpeedMph = WeatherMath.kilometersPerHourToMilesPerHour(windSpeedKph)
                
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
                    displayCondition = forecast?.properties.periods.first?.shortForecast ?? "Unknown"
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
                weatherRefreshState = .updated(
                    latestObservation.properties.timestamp
                )
                let formattedFetchSeconds = fetchSeconds.formatted(.number.precision(.fractionLength(2))
                )
                
                networkStatus = "Weather updated successfully in \(formattedFetchSeconds) seconds. \(temperatureHistory.count) graph points loaded. \(forecast?.properties.periods.count ?? 0) forecast hours loaded."
            } else {
                observation = WeatherObservation(
                    stationID: selectedLocation.displayStationID,
                    airTemperature: 0.0,
                    dewPoint: 0.0,
                    heatIndex: 0.0,
                    relativeHumidity: 0.0,
                    windSpeed: 0.0,
                    pressure: nil,
                    wetBulb: 0.0,
                    coolingPotential: 0.0,
                    condition: "No live observation",
                    lastUpdated: "Unavailable"
                )
                weatherRefreshState = .failed
                networkStatus = "No complete live observation found for \(selectedLocation.displayStationID). Forecast still loaded from location coordinates."
            }
        } catch {
            networkStatus = "Request failed: \(error.localizedDescription)"
            weatherRefreshState = .failed
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
