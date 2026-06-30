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
/// Climate graph shortcut
struct ShowClimateGraphActionKey: FocusedValueKey {
    typealias Value = () -> Void
}
///Station selector shortcut
struct SelectLocationActionKey: FocusedValueKey {
    typealias Value = (WeatherLocation) -> Void
}
///Graph value toggle shortcuts. Cmd + Shift + D for dew point. Cmd + Shift + H for heat index
struct ToggleDewPointActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

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
enum ClimateGraphType: Identifiable {
    case annualTemperatureCurve
    case seasonalHysteresisCurve
    static let allGraphs: [ClimateGraphType] = [
        .annualTemperatureCurve,
        .seasonalHysteresisCurve
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
        }
    }
}

struct ClimateDayPoint: Identifiable {
    let id = UUID()
    let dayOfYear: Int
    let normalHigh: Double
    let normalLow: Double
    let normalizedSolar: Double
}
///Add eigendate chord logic
struct EigendateChordResult {
    let depth: Double
    let normalizedSolar: Double
    let coolBranchDay: Int
    let warmBranchDay: Int
    let coolBranchTemperature: Double
    let warmBranchTemperature: Double
}
///Expresses thermal midsommar as a date window. We nondimensionalize T min(t) by defining
///Tau(t) = (T min(t) - L)/(H - L)
///then setting it equal to 0.9 for midsommar and 0.1 for midwinter.
struct ThermalWindow {
    let startDay: Int
    let endDay: Int
    let durationDays: Int
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
        lastUpdated: "10:30 AM")
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
    /// App shading logic for sunrise, day, sunset, and night
    private var dashboardGradientColors: [Color] {
        switch daylightPhase {
        case .sunrise:
            return [
                Color(red: 0.42, green: 0.34, blue: 0.48),
                Color(red: 0.72, green: 0.50, blue: 0.45),
                Color(red: 0.88, green: 0.67, blue: 0.50)
            ]
        case .day:
            return [
                Color(red: 0.18, green: 0.28, blue: 0.34),
                Color(red: 0.25, green: 0.36, blue: 0.42),
                Color(red: 0.42, green: 0.36, blue: 0.36)
            ]
        case .sunset:
            return [
                Color(red: 0.22, green: 0.24, blue: 0.38),
                Color(red: 0.52, green: 0.35, blue: 0.43),
                Color(red: 0.76, green: 0.48, blue: 0.34)
            ]
        case .night:
            return [
                Color(red: 0.02, green: 0.04, blue: 0.10),
                Color(red: 0.04, green: 0.07, blue: 0.16),
                Color(red: 0.08, green: 0.09, blue: 0.18)
            ]
        }
    }
    /// Adds stars
    private let backgroundStars: [BackgroundStar] = [
        BackgroundStar(x: 0.18, y: 0.12, size: 1.4, opacity: 0.40),
        BackgroundStar(x: 0.16, y: 0.28, size: 1.0, opacity: 0.32),
        BackgroundStar(x: 0.14, y: 0.18, size: 1.8, opacity: 0.39),
        BackgroundStar(x: 0.28, y: 0.10, size: 1.2, opacity: 0.43),
        BackgroundStar(x: 0.78, y: 0.24, size: 1.6, opacity: 0.36),
        BackgroundStar(x: 0.42, y: 0.14, size: 1.1, opacity: 0.45),
        BackgroundStar(x: 0.22, y: 0.30, size: 1.9, opacity: 0.32),
        BackgroundStar(x: 0.76, y: 0.16, size: 1.2, opacity: 0.45),
        BackgroundStar(x: 0.53, y: 0.34, size: 1.7, opacity: 0.39),
        BackgroundStar(x: 0.52, y: 0.58, size: 2.2, opacity: 0.45),
        BackgroundStar(x: 0.92, y: 0.88, size: 1.4, opacity: 0.25),
        BackgroundStar(x: 0.66, y: 0.66, size: 2.0, opacity: 0.45),
        BackgroundStar(x: 0.79, y: 0.92, size: 1.3, opacity: 0.28)
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
            Picker("Location", selection: $selectedLocation) {
                ForEach(WeatherLocation.allLocations) { location in
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
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)

            Text(networkStatus)
                .foregroundStyle(.secondary)

            Divider()
            /// Tells you when weather was last updated.
            Text("Last Updated: \(observation.lastUpdated)")
                .foregroundStyle(.secondary)
        }
    }
    private var leftDashboardPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            currentConditionsGrid
            
            Divider()
            
            almanacGrid
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

        let normalHigh = WeatherAlmanac.normalHighFahrenheit(
            dayOfYear: today,
            profile: selectedLocation.climatologyProfile
        )

        let normalLow = WeatherAlmanac.normalLowFahrenheit(
            dayOfYear: today,
            profile: selectedLocation.climatologyProfile
        )
        let solarEnergy = WeatherAlmanac.solarEnergy(
            dayOfYear: today,
            profile: selectedLocation.climatologyProfile
        )

        let solarIndex = WeatherAlmanac.normalizedSolarEnergy(
            dayOfYear: today,
            profile: selectedLocation.climatologyProfile
        )
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
            ForEach(temperatureHistory) { point in /// point is the temporary name for the current item in the loop
                LineMark(
                    x: .value("Time", point.timestamp), /// time goes to 'x' axis.
                    y: .value("Temperature", point.temperatureFahrenheit), /// Temperature goes to 'y' axis.
                    series: .value("Series", "Observed")
                )
                .foregroundStyle(.blue)
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
                        .foregroundStyle(.black)
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
                        .foregroundStyle(.purple)
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
                .foregroundStyle(.cyan.opacity(0.75)) /// light blue & dashed to make it obviously stand out to weather that has already happened.
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
                        .foregroundStyle(.gray)
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
                        .foregroundStyle(.purple.opacity(0.55))
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
                .foregroundStyle(.blue)
                .symbolSize(80)
                .annotation(position: .top) {
                    chartHoverTooltip(
                        label: "Temperature",
                        value: selectedTemperaturePoint.temperatureFahrenheit,
                        timestamp: selectedTemperaturePoint.timestamp,
                        color: .blue
                    )
                }
                ///Adds a nice solid black dot over dew points
                if isShowingDewPoint,
                   let dewPointFahrenheit = selectedTemperaturePoint.dewPointFahrenheit {
                    PointMark(
                        x: .value("Selected Dew Point Time", selectedTemperaturePoint.timestamp),
                        y: .value("Selected Dew Point", dewPointFahrenheit)
                    )
                    .foregroundStyle(.black)
                    .symbolSize(80)
                    .annotation(position: .top) {
                        chartHoverTooltip(
                            label: "Dew Point",
                            value: dewPointFahrenheit,
                            timestamp: nil,
                            color: .black
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
                    .foregroundStyle(.pink)
                    .symbolSize(80)
                    .annotation(position: .bottom) {
                        chartHoverTooltip(
                            label: "Heat Index",
                            value: heatIndexFahrenheit,
                            timestamp: nil,
                            color: .pink
                        )
                    }
                }
            }
        }
        .frame(width: 860, height: 350)
        .foregroundStyle(.black)
        .padding(16)
        .padding(.top, 28)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius: 10)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.gray.opacity(0.35), lineWidth: 1)
        }
        .overlay(alignment: .topLeading) {
            Text("Temperature History")
                .font(.headline)
                .foregroundStyle(.black)
                .padding(.leading, 16)
                .padding(.top, 14)
        }
        
        .chartYScale(domain: chartTemperatureDomain)
        .chartXScale(domain: chartTimeDomain)
        .chartYAxis {
            AxisMarks(values: .stride(by: 5)) {
                AxisGridLine()
                    .foregroundStyle(.gray.opacity(0.35))
                AxisTick()
                    .foregroundStyle(.gray)
                AxisValueLabel()
                    .foregroundStyle(.black)
            }
        }
        /// This makes it so if 72 hours is selected, the x axis doesn't have labeled tick marks every 3 pixels so it looks fucked up. spaced more out
        /// on longer durations.
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: chartXAxisHourStride)) { value in
                AxisGridLine()
                    .foregroundStyle(.gray.opacity(0.2))
                AxisTick()
                    .foregroundStyle(.gray)
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
                            .foregroundStyle(.black)
                        } else {
                            Text(date.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated))))
                                .foregroundStyle(.black)
                        }
                    }
                }
            }
        }
        ///Creates an invisible rectangle over the clart. When your mouse moves over it: Swift gets the mouse location, we convert the x-position into a date,
        ///we search all temperature chart points, then we store the closest point in selected temperature point.
        .chartOverlay { proxy in
            GeometryReader { geometry in
                let plotFrame = geometry[proxy.plotAreaFrame]
                
                Rectangle()
                    .fill(.clear)
                    .frame(width: plotFrame.width, height: plotFrame.height)
                    .position(x: plotFrame.midX, y: plotFrame.midY)
                    .contentShape(Rectangle())
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            let xPosition = location.x - plotFrame.origin.x
                            
                            guard xPosition >= 0,
                                  xPosition <= plotFrame.width,
                                  let hoveredDate: Date = proxy.value(atX: xPosition) else {
                                selectedTemperaturePoint = nil
                                return
                            }
                            
                            selectedTemperaturePoint = allTemperatureChartPoints.min { first,second in
                                abs(first.timestamp.timeIntervalSince(hoveredDate)) <
                                    abs(second.timestamp.timeIntervalSince(hoveredDate))
                            }
                            
                        case .ended:
                            selectedTemperaturePoint = nil
                        }
                    }
            }
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
                    .foregroundStyle(.black)
                }
                Text("History")
                    .font(.caption)
                    .foregroundStyle(.black)
                
                Picker("History Duration", selection: $selectedHistoryDuration) {
                    ForEach(HistoryDuration.allCases) { duration in
                        Text(duration.label)
                            .tag(duration)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .environment(\.colorScheme, .light)
                .tint(.blue)
                .foregroundStyle(.black)
                .frame(width: 110)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.gray.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(.gray.opacity(0.35), lineWidth: 1)
            }
            .padding(.top, 8)
            .padding(.trailing, 12)
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
                Text(timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Text("\(label): \(String(format: "%.1f", value)) °F")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .padding(6)
        .background(.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .shadow(radius: 3)
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
        var visibleTemperatures = (temperatureHistory + temperatureForecast).map {
            $0.temperatureFahrenheit
        }
        /// Considers dew point when drawing the y-axis tickmarks/range
        if isShowingDewPoint {
            let visibleDewPoints = (temperatureHistory + temperatureForecast).compactMap {
                $0.dewPointFahrenheit
            }
            
            visibleTemperatures.append(contentsOf: visibleDewPoints)
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
    private func loadForecastDiscussion() async {
        isLoadingForecastDiscussion = true
        
        do {
            let discussion = try await WeatherService().fetchLatestForecastDiscussion(
                office: selectedLocation.forecastDiscussionOffice
            )
            forecastDiscussion = discussion
            isShowingForecastDiscussion = true
            networkStatus = "Forecast discussion loaded."
        } catch {
            networkStatus = "Forecast discussion failed: \(error.localizedDescription)"
        }
        
        isLoadingForecastDiscussion = false
        
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
                networkStatus = "No complete observation found."
            }
        } catch {
            networkStatus = "Request failed: \(error.localizedDescription)"
        }
    }
}

/// The next section is integral to displaying climate graphs such as annual temperature curve.
struct ClimateGraphView: View {
    @Binding var graphType: ClimateGraphType
    let location: WeatherLocation
    @State private var keyMonitor: Any?
    /// Add forwards and backward buttons to the climate graph.
    /// Adds a current graph index. So annual temp curve would be index 0.
    private var currentGraphIndex: Int {
        ClimateGraphType.allGraphs.firstIndex { $0.id == graphType.id } ?? 0
    }
    
    private var canGoBackward: Bool {
        currentGraphIndex > 0
    }
    private var canGoForward: Bool {
        currentGraphIndex < ClimateGraphType.allGraphs.count - 1
    }
    private func goBackward() {
        guard canGoBackward else {
            return
        }
        
        graphType = ClimateGraphType.allGraphs[currentGraphIndex - 1]
    }
    
    private func goForward() {
        guard canGoForward else {
            return
        }
        
        graphType = ClimateGraphType.allGraphs[currentGraphIndex + 1]
    }
    
    @Environment(\.dismiss) private var dismiss
    
    /// Make 365 data points for each day of the year, reference the climate data in
    /// WeatherAlamanc.swift, and make a climate graph for the user's viewing pleasure.
    private var climatePoints: [ClimateDayPoint] {
        (1...365).map { day in
            ClimateDayPoint(
                dayOfYear: day,
                normalHigh: WeatherAlmanac.normalHighFahrenheit(
                    dayOfYear: day,
                    profile: location.climatologyProfile
                ),
                normalLow: WeatherAlmanac.normalLowFahrenheit(
                    dayOfYear: day,
                    profile: location.climatologyProfile
                ),
                normalizedSolar: WeatherAlmanac.normalizedSolarEnergy(
                    dayOfYear: day,
                    profile: location.climatologyProfile
                )
            )
        }
    }
    /// Indexes all 365 climate points and finds where the normal low is highest.
    private var peakNormalLowPoint: ClimateDayPoint? {
        climatePoints.max {first, second in
            first.normalLow < second.normalLow
        }
    }
    ///Define Tau(t)
    private func thermalWindow(threshold: Double, lookingForWarmWindow: Bool) -> ThermalWindow? {
        let lows = climatePoints.map { point in
            point.normalLow
        }
        
        guard let annualLow = lows.min(),
              let annualHigh = lows.max(),
              annualHigh > annualLow else {
            return nil
        }
        
        let matchingDays = climatePoints.filter { point in
            let tau = (point.normalLow - annualLow) / (annualHigh - annualLow)
            
            if lookingForWarmWindow {
                return tau >= threshold
            } else {
                return tau <= threshold
            }
        }
        
        guard !matchingDays.isEmpty else {
            return nil
        }
        
        if !lookingForWarmWindow {
            let matchingDayNumbers = Set(matchingDays.map { $0.dayOfYear })
            let includesStartOfYear = matchingDayNumbers.contains(1)
            let includesEndOfYear = matchingDayNumbers.contains(365)
            
            if includesStartOfYear && includesEndOfYear {
                let earlyYearDays = matchingDays.filter { $0.dayOfYear < 183 }
                let lateYearDays = matchingDays.filter { $0.dayOfYear >= 183 }
                
                guard let startDay = lateYearDays.first?.dayOfYear,
                      let endDay = earlyYearDays.last?.dayOfYear else {
                    return nil
                }
                
                let durationDays = (365 - startDay + 1) + endDay
                
                return ThermalWindow(
                    startDay: startDay,
                    endDay: endDay,
                    durationDays: durationDays
                )
            }
        }
        
        guard let startDay = matchingDays.first?.dayOfYear,
              let endDay = matchingDays.last?.dayOfYear else {
            return nil
        }
        
        return ThermalWindow(
            startDay: startDay,
            endDay: endDay,
            durationDays: endDay - startDay + 1
        )
    }
    
    /// Tau(t) = 0.9 for thermal midsommar
    /// Tau(t) =  0.1 for thermal midwinter
    private var thermalMidsommarWindow: ThermalWindow? {
        thermalWindow(threshold: 0.9, lookingForWarmWindow: true)
    }
    
    private var thermalMidwinterWindow: ThermalWindow? {
        thermalWindow(threshold: 0.1, lookingForWarmWindow: false)
    }
    
    ///Helps with the base 10 logic. If the annual minimum is 37, chart will start from y = 37.
    ///If it plateuas at 104 in midsommar, it will max out at 110.
    private var annualTemperatureDomain: ClosedRange<Double> {
        let allTemperatures = climatePoints.flatMap { point in
            [
                point.normalHigh,
                point.normalLow
            ]
        }
        
        guard let minimumTemperature = allTemperatures.min(),
              let maximumTemperature = allTemperatures.max() else {
            return 0...100
        }
        
        let lowerBound = floor(minimumTemperature / 10.0) * 10.0
        let upperBound = ceil(maximumTemperature / 10.0) * 10.0
        
        return lowerBound...upperBound
    }
    ///Calculate the seasonal memory index defined as the integral from 1 to 365 of T min(t) ds

    private var seasonalMemoryIndex: Double {
        let points = climatePoints.sorted { first, second in
            first.dayOfYear < second.dayOfYear
        }
        
        guard points.count > 1 else {
            return 0.0
        }
        
        var area = 0.0
        
        for index in 0..<(points.count - 1) {
            let currentPoint = points[index]
            let nextPoint = points[index + 1]
            
            let averageTemperature = (currentPoint.normalLow + nextPoint.normalLow) / 2.0
            let changeInSolar = nextPoint.normalizedSolar - currentPoint.normalizedSolar
            
            area += averageTemperature * changeInSolar
        }
        
        if let firstPoint = points.first,
           let lastPoint = points.last {
            let averageTemperature = (lastPoint.normalLow + firstPoint.normalLow) / 2.0
            let changeInSolar = firstPoint.normalizedSolar - lastPoint.normalizedSolar
            
            area += averageTemperature * changeInSolar
        }
        
        return abs(area)
    }
    ///Show the maximum eigendate chord from the code.
    private var maximumEigendateChord: EigendateChordResult? {
        guard let solarMaximumPoint = climatePoints.max(by: { first, second in
            first.normalizedSolar < second.normalizedSolar
        }) else {
            return nil
        }
        
        let solarMaximumDay = solarMaximumPoint.dayOfYear
        
        let coolBranch = climatePoints
            .filter { point in
                point.dayOfYear <= solarMaximumDay
            }
            .sorted { first, second in
                first.dayOfYear < second.dayOfYear
            }
        
        let warmBranch = climatePoints
            .filter { point in
                point.dayOfYear >= solarMaximumDay
            }
            .sorted { first, second in
                first.dayOfYear < second.dayOfYear
            }
        
        let lowerSolarBound = max(
            coolBranch.map { $0.normalizedSolar }.min() ?? 0.0,
            warmBranch.map { $0.normalizedSolar }.min() ?? 0.0
        )
        
        let upperSolarBound = min(
            coolBranch.map { $0.normalizedSolar }.max() ?? 1.0,
            warmBranch.map { $0.normalizedSolar }.max() ?? 1.0
        )
        
        guard lowerSolarBound < upperSolarBound else {
            return nil
        }
        
        var bestResult: EigendateChordResult?
        
        for step in 0...1000 {
            let fraction = Double(step) / 1000.0
            let targetSolar = lowerSolarBound
                + fraction * (upperSolarBound - lowerSolarBound)
            
            guard let coolPoint = interpolatedPoint(
                on: coolBranch,
                atNormalizedSolar: targetSolar
            ),
            let warmPoint = interpolatedPoint(
                on: warmBranch,
                atNormalizedSolar: targetSolar
            ) else {
                continue
            }
            
            let depth = warmPoint.temperature - coolPoint.temperature
            
            guard depth > 0 else {
                continue
            }
            
            if bestResult == nil || depth > bestResult!.depth {
                bestResult = EigendateChordResult(
                    depth: depth,
                    normalizedSolar: targetSolar,
                    coolBranchDay: Int(coolPoint.day.rounded()),
                    warmBranchDay: Int(warmPoint.day.rounded()),
                    coolBranchTemperature: coolPoint.temperature,
                    warmBranchTemperature: warmPoint.temperature
                )
            }
        }
        
        return bestResult
    }
    
    ///Adds ability to calculate the maximum differential of T min(t) for a specific s(t) input.
    ///Uses cool branch (a) and warm branch(b) guesses and iterates.
    private func interpolatedPoint(
        on branch: [ClimateDayPoint],
        atNormalizedSolar targetSolar: Double
    ) -> (day: Double, temperature: Double)? {
        guard branch.count >= 2 else {
            return nil
        }
        
        for index in 0..<(branch.count - 1) {
            let first = branch[index]
            let second = branch[index + 1]
            
            let firstSolar = first.normalizedSolar
            let secondSolar = second.normalizedSolar
            
            let targetIsBetween =
                (firstSolar <= targetSolar  && targetSolar <= secondSolar) ||
                (secondSolar <= targetSolar && targetSolar <= firstSolar)
            
            guard targetIsBetween else {
                continue
            }
            
            let solarDifference = secondSolar - firstSolar
            
            guard abs(solarDifference) > 0.000001 else {
                continue
            }
            
            let fraction = (targetSolar - firstSolar) / solarDifference
            
            let day = Double(first.dayOfYear)
                + fraction * Double(second.dayOfYear - first.dayOfYear)
            
            let temperature = first.normalLow
                + fraction * (second.normalLow - first.normalLow)
            return (day, temperature)
        }
        
        return nil
    }
    
    /// Helps with hysteresis graph base ten logic
    
    private var hysteresisTemperatureDomain: ClosedRange<Double> {
        let lowTemperatures = climatePoints.map { point in
            point.normalLow
        }
        
        guard let minimumTemperature = lowTemperatures.min(),
              let maximumTemperature = lowTemperatures.max() else {
            return 0...100
        }
        
        let lowerBound = floor(minimumTemperature / 10.0) * 10.0
        let upperBound = ceil(maximumTemperature / 10.0) * 10.0
        
        return lowerBound...upperBound
    }
    
    /// Adds nice arrow directions for the hysteresis graph.
    private var hysteresisArrowPoints: [ClimateDayPoint] {
        climatePoints.filter { point in
            [45, 90, 135, 180, 225, 270, 315, 360].contains(point.dayOfYear)
        }
    }
    ///Makes proper arrows scaled by how the x axis is scaled
    private func hysteresisArrowAngle(for day: Int) -> Angle {
        let previousDay = max(1, day - 3)
        let nextDay = min(365, day + 3)

        guard let previousPoint = climatePoints.first(where: { $0.dayOfYear == previousDay }),
              let nextPoint = climatePoints.first(where: { $0.dayOfYear == nextDay }) else {
            return .degrees(0)
        }

        let dx = nextPoint.normalizedSolar - previousPoint.normalizedSolar
        let dy = nextPoint.normalLow - previousPoint.normalLow

        let xRange = 1.2
        let yRange = annualTemperatureDomain.upperBound - annualTemperatureDomain.lowerBound

        let scaledDx = dx / xRange
        let scaledDy = -dy / yRange
        /// Properly scale it so the arrows aren't 'off the percs'.
        let angleRadians = atan2(scaledDy, scaledDx)
        let angleDegrees = angleRadians * 180.0 / Double.pi

        return .degrees(angleDegrees)
    }
    ///Convert day-of-year into a month/day label to display our midsommar maximum T min.
    ///Answer will be formatted like
    ///T min = 76.8 deg F
    ///s(t) = 0.91 (Jul 26)
    private func monthDayLabel(for dayOfYear: Int) -> String {
        var components = DateComponents()
        components.year = 2025
        components.day = dayOfYear
        
        let calendar = Calendar(identifier: .gregorian)
        
        guard let date = calendar.date(from: components) else {
            return "Day \(dayOfYear)"
        }
        
        let formatter = DateFormatter()
        ///turns "year 2025, day 207" into a "real" date to look like "Jul 26"
        formatter.dateFormat = "MMM d"
        
        return formatter.string(from: date)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(graphType.title) - \(location.name)")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()

                HStack(spacing: 8) {
                    Button("‹") {
                        goBackward()
                    }
                    .disabled(!canGoBackward)
                    
                    Button("›") {
                        goForward()
                    }
                    .disabled(!canGoForward)
                    
                    Button("X") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    .keyboardShortcut("W", modifiers: .command)
                }
                .keyboardShortcut(.cancelAction)
            }
            
            Divider()
            
            switch graphType {
            case .annualTemperatureCurve:
                annualTemperatureChart
            case .seasonalHysteresisCurve:
                seasonalHysteresisChart
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
        ///The next .onappear block is very important for keyboard navigation of the app
        .onAppear {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                let isCommandW = event.modifierFlags.contains(.command)
                    && event.charactersIgnoringModifiers?.lowercased() == "w"
                ///Makes it so command shift A moves climate tab left
                let isCommandShiftA = event.modifierFlags.contains(.command)
                    && event.modifierFlags.contains(.shift)
                    && event.charactersIgnoringModifiers?.lowercased() == "a"
                /// Command shift D moves climate tab to the right
                let isCommandShiftD = event.modifierFlags.contains(.command)
                    && event.modifierFlags.contains(.shift)
                    && event.charactersIgnoringModifiers?.lowercased() == "d"

                if isCommandW {
                    dismiss()
                    return nil
                }

                if isCommandShiftA {
                    goBackward()
                    return nil
                }

                if isCommandShiftD {
                    goForward()
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
    
    /// This function actually plots the T min and T max for a climate site and graphs it
    /// under our climate UI.
    private var annualTemperatureChart: some View {
        Chart {
            ForEach(climatePoints) { point in
                LineMark(
                    x: .value("Day", point.dayOfYear),
                    y: .value("Temperature", point.normalHigh),
                    series: .value("Series", "Normal High")
                )
                .foregroundStyle(.red)
            }

            ForEach(climatePoints) { point in
                LineMark(
                    x: .value("Day", point.dayOfYear),
                    y: .value("Temperature", point.normalLow),
                    series: .value("Series", "Normal Low")
                )
                .foregroundStyle(.blue)
            }
            
            ///Thermal midwinter & thermal midsommar
            if let peakNormalLowPoint,
               let thermalMidsommarWindow,
               let thermalMidwinterWindow {
                PointMark(
                    x: .value("Day", 15),
                    y: .value("Temperature", annualTemperatureDomain.upperBound)
                )
                .opacity(0)
                .annotation(position: .bottomTrailing, alignment: .leading) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Annual Low-Temperature Timing")
                            .font(.headline)
                        Text(
                            "Peak Normal Low: \(peakNormalLowPoint.normalLow, specifier: "%.1f") °F (\(monthDayLabel(for: peakNormalLowPoint.dayOfYear)))"
                        )
                        
                        Text(
                            "Thermal Midsommar: \(monthDayLabel(for: thermalMidsommarWindow.startDay)) → \(monthDayLabel(for: thermalMidsommarWindow.endDay))"
                        )
                        Text(
                            "Thermal Midwinter: \(monthDayLabel(for: thermalMidwinterWindow.startDay)) → \(monthDayLabel(for: thermalMidwinterWindow.endDay))"
                        )
                    }
                    .font(.callout)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.black.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .chartXScale(domain: 1...365)
        .chartYScale(domain: annualTemperatureDomain)
        /// Now have it label Jan 1 ... Dec 1, Dec 31
        .chartXAxis {
            AxisMarks(values: [1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 365]) { value in
                AxisGridLine()
                AxisTick()
                
                if let day = value.as(Int.self) {
                    switch day {
                    case 1:
                        AxisValueLabel("Jan 1")
                    case 32:
                        AxisValueLabel("Feb 1")
                    case 60:
                        AxisValueLabel("Mar 1")
                    case 91:
                        AxisValueLabel("Apr 1")
                    case 121:
                        AxisValueLabel("May 1")
                    case 152:
                        AxisValueLabel("Jun 1")
                    case 182:
                        AxisValueLabel("Jul 1")
                    case 213:
                        AxisValueLabel("Aug 1")
                    case 244:
                        AxisValueLabel("Sep 1")
                    case 274:
                        AxisValueLabel("Oct 1")
                    case 305:
                        AxisValueLabel("Nov 1")
                    case 335:
                        AxisValueLabel("Dec 1")
                    case 365:
                        AxisValueLabel("Dec 31")
                    default:
                        AxisValueLabel("")
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .stride(by: 10))
        }
        .chartXAxisLabel("Day of Year")
        .chartYAxisLabel("Temperature (°F)")
    }
    /// Add the seasonal hysteresis phase space with arrow seasonal progression
    private var seasonalHysteresisChart: some View {
        Chart {
            ///Adds the points themselves.
            ForEach(climatePoints) { point in
                LineMark(
                    x: .value("Normalized Solar", point.normalizedSolar),
                    y: .value("Normal Low", point.normalLow)
                )
                .foregroundStyle(.purple)
            }
            
            ///Adds the green arrows
            ForEach(hysteresisArrowPoints) { point in
                PointMark(
                    x: .value("Normalized Solar", point.normalizedSolar),
                    y: .value("Normal Low", point.normalLow)
                )
                .foregroundStyle(.clear)
                .annotation(position: .overlay) {
                    Text("➤")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                        .rotationEffect(hysteresisArrowAngle(for: point.dayOfYear))
                }
            }
            PointMark(
                x: .value("Normalized Solar", -0.12),
                y: .value("Normal Low", hysteresisTemperatureDomain.upperBound)
            )
            .foregroundStyle(.clear)
            .annotation(position: .bottomTrailing, alignment: .leading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Seasonal Memory Index")
                        .font(.headline)
                    
                    Text("SMI = \(seasonalMemoryIndex, specifier: "%.1f") °F")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("∮ Tₘᵢₙ ds")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    Divider()
                    /// Adds the peakNormalLowPoint function to do the obvious.
                    
                    if let peak = peakNormalLowPoint {
                        Text("Peak Normal Low: \(peak.normalLow, specifier: "%.1f") °F")
                            .font(.body)
                        Text("at s = \(peak.normalizedSolar, specifier: "%.2f") (\(monthDayLabel(for: peak.dayOfYear)))")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let chord = maximumEigendateChord {
                        Divider()
                        
                        Text("Maximum Eigendate Chord Depth")
                            .font(.body)
                            .fontWeight(.semibold)
                        
                        Text("MECD = \(chord.depth, specifier: "%.1f") °F")
                            .font(.body)
                        
                        Text("s = \(chord.normalizedSolar, specifier: "%.2f")")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        
                        Text("\(monthDayLabel(for: chord.coolBranchDay)) ↔ \(monthDayLabel(for: chord.warmBranchDay))")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .background(.black.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .chartXScale(domain: -0.1...1.1)
        .chartYScale(domain: hysteresisTemperatureDomain)
        /// Make it so that the Y axis goes from base 10 below the minimum temp and above the max temp.
        .chartYAxis {
            AxisMarks(values: .stride(by: 10))
        }
        .chartXAxis {
            AxisMarks(values: Array(stride(from: 0.0, through: 1.0, by: 0.2)))
        }
        
        .chartXAxisLabel("Normalized Solar")
        .chartYAxisLabel("Normal Low (°F)")
    }
}
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
