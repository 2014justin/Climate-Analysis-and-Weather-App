import SwiftUI
import Playgrounds
import Charts
import AppKit
import UniformTypeIdentifiers
import Foundation


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
            self[SelectHistoryDurationActionKey.self] /// Reads the action associated with selec thistory
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
    /// There may be no Atlas selection action right now
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

/// In this app, struct WeatherCommands becomes the menu layer containing : Refresh Weather, Show Dashboard
/// Show Climate Atlas, history durations, location shortcuts, export commands, and graph toggles.
/// WeatherCommands owns menu labels and shortcuts
/// ContentView owns selected location, weather data, charts, sheets, and refresh logic.
/// The focused-value closures act as wires between the two.
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
    
    /// macOS should add this to the application menu.
    var body: some Commands {
        /// Creates a group of menu commands and places them after macOS's standard New Item command
        CommandGroup(after: .newItem) {
            
            /// Switch between Atlas and Dashboard. If the focused app-section action exists, call it with .dashboard.
            /// User chooses Show Dashboard -> WeatherCommands send .dashboard -> ContentView receives .dashboard
            /// -> selectedAppSeciton changes -> the app displays the dashboard
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

/// launches MyApp and creates content view. This is the app's spawnpoint.
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
    
    /// Numeric short date, e.g. 8/11.
    private func shortDateText(
        for day: Double
    ) -> String {
        
        ClimateCalendar.monthDayText(
            fromClimatologicalDay: day,
            style: .numeric
        ) ?? "-"
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
    let initialStationSource: AtlasStationSource?
    let replacingStationID: String?
    
    var isRebuilding: Bool {
        replacingStationID != nil
    }
}

/// Provider-agnostic metadata consumed by station information.
/// ContentView gathers the information here so StationInfoView does not
/// need to understand saved stations, ACIS, ECCC, or other.
fileprivate struct StationInfoMetadata {
    let stationName: String
    let stationIdentifier: String
    let climateSourceIdentifier: String
    let climateSourceName: String?
    let countryCode: String
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String
    
    let fitOrder: Int?
    let highRMSE: Double?
    let lowRMSE: Double?
    let normalStartYear: Int?
    let normalEndYear: Int?
    let pairedCompleteness: Double?
    let highTemperatureSeries: FourierSeries?
    let lowTemperatureSeries: FourierSeries?
    
    init(
        location: WeatherLocation,
        savedStation: SavedGeneratedStation?
    ) {
        let profile = location.generatedClimateProfile
        
        stationName = location.name
        stationIdentifier = location.displayStationID
        climateSourceIdentifier = profile?.stationID ?? location.acisStationID
        climateSourceName = profile?.displayName
        countryCode = location.countryCode
        latitude = location.latitude
        longitude = location.longitude
        timeZoneIdentifier = location.timeZoneIdentifier
        
        fitOrder = profile?.fitOrder
        highRMSE = profile?.highRMSE
        lowRMSE = profile?.lowRMSE
        normalStartYear = profile?.sourceStartYear
        normalEndYear = profile?.sourceEndYear
        pairedCompleteness = savedStation?.pairedCompleteness
        highTemperatureSeries = profile?.normalHighSeries

        lowTemperatureSeries = profile?.normalLowSeries
    }
}

/// Converts stored Fourier coefficients into a complete, copyable
/// plaintext representation.
///
/// t is the climatological day of year and all output temperatures
/// are degrees Fahrenheit.
private enum FourierFitPlainTextFormatter {
    static func text(
        for metadata: StationInfoMetadata
    ) -> String? {
        guard let highSeries =
                metadata.highTemperatureSeries,
              let lowSeries =
                metadata.lowTemperatureSeries else {
            return nil
        }

        let fitOrder =
            metadata.fitOrder.map {
                String($0)
            } ?? "Unknown"

        let normalPeriod: String

        if let startYear = metadata.normalStartYear,
           let endYear = metadata.normalEndYear {
            normalPeriod = "\(startYear)-\(endYear)"
        } else {
            normalPeriod = "Unknown"
        }

        return """
        STATION FOURIER CLIMATE FIT
        Station: \(metadata.stationName)
        Station ID: \(metadata.stationIdentifier)
        Climate source: \(metadata.climateSourceIdentifier)
        Normal period: \(normalPeriod)
        Fourier order: \(fitOrder)

        Variable:
        t = climatological day of year, 1...365

        Units:
        T_high(t) and T_low(t) are degrees Fahrenheit.

        NORMAL HIGH-TEMPERATURE FIT

        \(equation(
            name: "T_high",
            series: highSeries
        ))

        NORMAL LOW-TEMPERATURE FIT

        \(equation(
            name: "T_low",
            series: lowSeries
        ))
        """
    }

    private static func equation(
        name: String,
        series: FourierSeries
    ) -> String {
        var result =
            "\(name)(t) = \(coefficientText(series.constant))"

        for (
            index,
            coefficient
        ) in series.cosineCoefficients.enumerated() {
            result += signedTerm(
                coefficient: coefficient,
                functionName: "cos",
                harmonic: index + 1
            )
        }

        for (
            index,
            coefficient
        ) in series.sineCoefficients.enumerated() {
            result += signedTerm(
                coefficient: coefficient,
                functionName: "sin",
                harmonic: index + 1
            )
        }

        return result
    }

    private static func signedTerm(
        coefficient: Double,
        functionName: String,
        harmonic: Int
    ) -> String {
        let operation =
            coefficient < 0
                ? " - "
                : " + "

        return operation
            + coefficientText(abs(coefficient))
            + " * \(functionName)"
            + "(2 * pi * \(harmonic) * t / 365)"
    }

    /// String(Double) preserves enough significant digits to reconstruct
    /// the stored binary floating-point value when parsed again.
    private static func coefficientText(
        _ coefficient: Double
    ) -> String {
        String(coefficient)
    }
}

private struct FourierFitView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var didCopy = false

    let fitText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "waveform.path")
                    .symbolRenderingMode(.monochrome)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(
                        DashboardTheme.forecastTemperature
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text("Fourier Climate Fits")
                        .font(.title2.weight(.bold))

                    Text(
                        "Plaintext coefficients and explicit harmonic terms"
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        DashboardTheme.textSecondary
                    )
                }

                Spacer()

                Button {
                    copyFit()
                } label: {
                    Label(
                        didCopy ? "Copied" : "Copy Fit",
                        systemImage:
                            didCopy
                                ? "checkmark"
                                : "doc.on.doc"
                    )
                }
                .buttonStyle(.borderedProminent)

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .symbolRenderingMode(.monochrome)
                        .font(
                            .system(
                                size: 12,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(
                            DashboardTheme.textSecondary
                        )
                        .frame(width: 28, height: 28)
                        .background {
                            Circle()
                                .fill(
                                    DashboardTheme.panelElevated
                                )
                        }
                        .overlay {
                            Circle()
                                .stroke(
                                    DashboardTheme.border,
                                    lineWidth: 1
                                )
                        }
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
                .help("Close Fourier Fits")
            }

            Divider()

            ScrollView([.horizontal, .vertical]) {
                Text(verbatim: fitText)
                    .font(
                        .system(
                            size: 13,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(
                        DashboardTheme.textPrimary
                    )
                    .textSelection(.enabled)
                    .fixedSize(
                        horizontal: true,
                        vertical: true
                    )
                    .padding(16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .fill(
                    DashboardTheme.panelElevated.opacity(0.72)
                )
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .stroke(
                    DashboardTheme.border,
                    lineWidth: 1
                )
            }
        }
        .padding(24)
        .frame(width: 920, height: 580)
        .background(DashboardTheme.panel)
    }

    private func copyFit() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(
            fitText,
            forType: .string
        )

        didCopy = true
    }
}

/// The Station Info sheet has its own presentation shell now so its metadata
/// can be added without revisiting the Station Settings interface.
fileprivate struct StationInfoView: View {
    @Environment(\.dismiss) fileprivate var dismiss
    @State private var isShowingFourierFit = false
    
    let metadata: StationInfoMetadata
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "info.circle.fill")
                    .symbolRenderingMode(.monochrome)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(DashboardTheme.forecastTemperature)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Station Info")
                        .font(.title2.weight(.bold))
                    
                    Text(metadata.stationName)
                        .font(.headline)
                    
                    HStack(spacing: 6) {
                        Text(metadata.stationIdentifier)
                            .monospaced()
                        
                        Text("•")
                        
                        Text(metadata.countryCode)
                        
                        Text("•")
                        
                        Text(metadata.climateSourceIdentifier)
                            .monospaced()
                    }
                    .font(.subheadline)
                    .foregroundStyle(DashboardTheme.textSecondary)
                }
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .symbolRenderingMode(.monochrome)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(
                            DashboardTheme.textSecondary
                        )
                        .frame(width: 28, height: 28)
                        .background {
                            Circle()
                                .fill(
                                    DashboardTheme.panelElevated
                                )
                        }
                        .overlay {
                            Circle()
                                .stroke(
                                    DashboardTheme.border,
                                    lineWidth: 1
                                )
                        }
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
                .help("Close Station Info")
                .accessibilityLabel("Close Station Info")
            }
            
            Divider()
            
            HStack(alignment: .top, spacing: 12) {
                informationCard(
                    title: "Location",
                    systemImage: "location.fill"
                ) {
                    metadataRow(
                        "Latitude",
                        coordinateText(
                            metadata.latitude,
                            positiveSuffix: "N",
                            negativeSuffix: "S"
                        )
                    )
                    
                    metadataRow(
                        "Longitude",
                        coordinateText(
                            metadata.longitude,
                            positiveSuffix: "E",
                            negativeSuffix: "W"
                        )
                    )
                    
                    metadataRow(
                        "Time Zone",
                        metadata.timeZoneIdentifier
                    )
                }
                
                informationCard(
                    title: "Climate Normal",
                    systemImage: "calendar"
                ) {
                    metadataRow(
                        "Period",
                        normalPeriodText
                    )
                    
                    metadataRow(
                        "Completion",
                        completenessText
                    )
                    
                    metadataRow(
                        "Source",
                        metadata.climateSourceName ?? metadata.climateSourceIdentifier
                    )
                }
                
                informationCard(
                    title: "Fourier Fit",
                    systemImage: "waveform.path",
                    actionTitle: "Show Fit",
                    isActionEnabled:
                        metadata.highTemperatureSeries != nil
                    && metadata.lowTemperatureSeries != nil,
                    action: {
                        isShowingFourierFit = true
                    }
                ) {
                    metadataRow(
                        "Order",
                        fitOrderText
                    )
                    
                    metadataRow(
                        "High RMSE",
                        rmseText(metadata.highRMSE)
                    )
                    
                    metadataRow(
                        "Low RMSE",
                        rmseText(metadata.lowRMSE)
                    )
                }
            }
            
            Label(
                """
                RMSE measures the typical difference between the smoothed climate normal and
                its Fourier representation.
                """,
                systemImage: "function"
            )
            .font(.caption)
            .foregroundStyle(DashboardTheme.textSecondary)
            
            Spacer()
        }
        .padding(24)
        .frame(width: 760, height: 390)
        .background(DashboardTheme.panel)
        .sheet(isPresented: $isShowingFourierFit) {
            FourierFitView(
                fitText:
                    FourierFitPlainTextFormatter.text(
                        for: metadata
                    )
                    ?? "Fourier fit coefficients are not recorded for this station."
            )
        }
    }
    
    fileprivate var normalPeriodText: String {
        guard let startYear = metadata.normalStartYear,
              let endYear = metadata.normalEndYear else {
            return "Not recorded"
        }
        
        return "\(startYear)-\(endYear)"
    }
    
    fileprivate var completenessText: String {
        guard let pairedCompleteness = metadata.pairedCompleteness else {
            return "Not recorded"
        }
        
        return pairedCompleteness.formatted(.percent.precision(.fractionLength(1)))
    }
    
    fileprivate var fitOrderText: String {
        guard let fitOrder = metadata.fitOrder else {
            return "Not recorded"
        }
        
        return "Order \(fitOrder)"
    }
    
    fileprivate func rmseText(
        _ value: Double?
    ) -> String {
        guard let value else {
            return "Not recorded"
        }
        
        return String(
            format: "%.2f °F",
            value
        )
    }
    
    fileprivate func coordinateText(
        _ value: Double,
        positiveSuffix: String,
        negativeSuffix: String
    ) -> String {
        let suffix = value >= 0 ? positiveSuffix : negativeSuffix
        
        return String(
            format: "%.4f° %@",
            abs(value),
            suffix
        )
    }
    
    fileprivate func metadataRow(
        _ label: String,
        _ value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(DashboardTheme.textSecondary)
            
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.750)
        }
    }
    
    fileprivate func informationCard<Content: View>(
        title: String,
        systemImage: String,
        actionTitle: String? = nil,
        isActionEnabled: Bool = true,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Label(
                    title,
                    systemImage: systemImage
                )
                .font(.headline)
                .foregroundStyle(
                    DashboardTheme.forecastTemperature
                )
                .lineLimit(1)

                Spacer(minLength: 4)

                if let actionTitle,
                   let action {
                    Button(
                        actionTitle,
                        action: action
                    )
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(!isActionEnabled)
                    .help(
                        isActionEnabled
                            ? "Show plaintext Fourier coefficients"
                            : "Fourier coefficients are not recorded for this station"
                    )
                }
            }

            content()

            Spacer(minLength: 0)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 185,
            alignment: .topLeading
        )
        .padding(16)
        .background {
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .fill(
                DashboardTheme.panelElevated.opacity(0.88)
            )
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .stroke(
                DashboardTheme.border,
                lineWidth: 1
            )
        }
    }
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
    
    @Environment(\.accessibilityReduceMotion)
    private var accessibilityReduceMotion
    
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
    @State private var thresholdWidgetFreezeSummary:
        ClimateThresholdSummary?
    @State private var thresholdWidgetHardFreezeSummary:
        ClimateThresholdSummary?
    @State private var thresholdWidgetWarmSummaries:
        [ClimateThresholdSummary] = []
    @State private var forecastDiscussion: ForecastDiscussion?
    @State private var isShowingForecastDiscussion = false
    @State private var isLoadingForecastDiscussion = false
    @State private var selectedLocation = WeatherLocation.northLasVegas
    @State private var isShowingStationSettings = false
    @State private var isShowingStationInfo = false
    /// A non-nil request presents the builder and carries
    /// its starting weather-station ID.
    @State private var stationAdderRequest:
        StationAdderRequest?
    
    ///Let ContentView remember the Atlas station
    @State private var stationAdderInitialStationID = ""
    @State private var isShowingStationRemovalConfirmation = false
    @State private var isBuildingGeneratedClimateProfile = false
    @State private var savedGeneratedStations: [SavedGeneratedStation] = []
    
    /// Keeps provider catalogs and their network caches alive across refreshes.
    @State private var forecastRouter = WeatherForecastRouter()
    
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
    
    /// Reconstructs the provider-aware observation-station identity
    /// needed to rebuild an existing generated climate station.
    private func stationSource(
        for savedStation: SavedGeneratedStation
    ) -> AtlasStationSource {
        let countryCode =
        savedStation.resolvedCountryCode
        
        return AtlasStationSource(
            countryCode: countryCode,
            providerID: countryCode == "CA"
                ? "aviationWeather"
                : "manualEntry",
            stationID: savedStation.observationStationID
        )
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
        BackgroundStar(x: 0.17, y: 0.93, size: 4.0, opacity: 0.79),
        BackgroundStar(x: 0.32, y: 0.07, size: 1.5, opacity: 0.68),
        BackgroundStar(x: 0.37, y: 0.15, size: 1.1, opacity: 0.58),
        BackgroundStar(x: 0.62, y: 0.07, size: 1.8, opacity: 0.76),
        BackgroundStar(x: 0.67, y: 0.17, size: 1.2, opacity: 0.62),
        BackgroundStar(x: 0.72, y: 0.10, size: 1.4, opacity: 0.70),
        BackgroundStar(x: 0.77, y: 0.19, size: 1.0, opacity: 0.56),
        BackgroundStar(x: 0.82, y: 0.07, size: 1.9, opacity: 0.78),
        BackgroundStar(x: 0.87, y: 0.16, size: 1.3, opacity: 0.66),
        BackgroundStar(x: 0.92, y: 0.09, size: 1.1, opacity: 0.60),
        BackgroundStar(x: 0.95, y: 0.20, size: 1.6, opacity: 0.72),
        BackgroundStar(x: 0.025, y: 0.40, size: 1.2, opacity: 0.58),
        BackgroundStar(x: 0.975, y: 0.48, size: 1.5, opacity: 0.68),
        BackgroundStar(x: 0.26, y: 0.91, size: 1.1, opacity: 0.60),
        BackgroundStar(x: 0.21, y: 0.84, size: 1.7, opacity: 0.72)
    ]
    
    
    
    private var starOverlay: some View {
        TimelineView(
            .animation(
                minimumInterval: 1.0 / 12.0,
                paused: accessibilityReduceMotion
            )
        ) { timeline in
            let elapsed =
                timeline.date
                    .timeIntervalSinceReferenceDate

            let rotationDegrees =
                accessibilityReduceMotion
                    ? 0.0
                    : sin(elapsed / 90.0) * 1.4

            let horizontalDrift: CGFloat =
                accessibilityReduceMotion
                    ? 0.0
                    : CGFloat(
                        cos(elapsed / 110.0) * 4.0
                    )

            let verticalDrift: CGFloat =
                accessibilityReduceMotion
                    ? 0.0
                    : CGFloat(
                        sin(elapsed / 140.0) * 2.5
                    )
            
            GeometryReader { geometry in
                ForEach(backgroundStars) { star in
                    ZStack {
                        Circle()
                            .fill(
                                DashboardTheme
                                    .forecastTemperature
                                    .opacity(0.14)
                            )
                            .frame(
                                width: star.size * 3.2,
                                height: star.size * 3.2
                            )
                        
                        Circle()
                            .fill(.white)
                            .frame(
                                width: star.size,
                                height: star.size
                            )
                    }
                    .opacity(
                        min(
                            star.opacity + 0.10,
                            1.0
                        )
                    )
                    .shadow(
                        color: Color.white.opacity(0.22),
                        radius: star.size * 0.65
                    )
                    .position(
                        x: geometry.size.width * star.x,
                        y: geometry.size.height * star.y
                    )
                }
            }
            .scaleEffect(1.04)
            .rotationEffect(
                .degrees(rotationDegrees)
            )
            .offset(
                x: horizontalDrift,
                y: verticalDrift
            )
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

    /// A custom popover is used instead of Menu because macOS menus always
    /// arrange their commands vertically. This keeps all four station actions
    /// visible as one compact horizontal tool palette.
    private var stationSettingsPopover: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Station Settings")
                    .font(.headline.weight(.bold))

                Spacer()

                Text(selectedLocation.displayStationID)
                    .font(.caption.monospaced().weight(.semibold))
                    .foregroundStyle(DashboardTheme.textSecondary)
            }

            HStack(spacing: 10) {
                stationSettingsAction(
                    title: "Add Station",
                    subtitle: "Create a climate profile",
                    systemImage: "plus.circle.fill",
                    tint: DashboardTheme.forecastTemperature
                ) {
                    isShowingStationSettings = false
                    stationAdderRequest = StationAdderRequest(
                        initialStationSource: nil,
                        replacingStationID: nil
                    )
                }

                stationSettingsAction(
                    title: "Rebuild Station",
                    subtitle: "Refresh climate records",
                    systemImage: "arrow.triangle.2.circlepath",
                    tint: DashboardTheme.dewPoint,
                    isEnabled: selectedSavedGeneratedStation != nil
                ) {
                    guard let savedStation = selectedSavedGeneratedStation else {
                        return
                    }

                    isShowingStationSettings = false
                    stationAdderRequest = StationAdderRequest(
                        initialStationSource: stationSource(for: savedStation),
                        replacingStationID: savedStation.id
                    )
                }

                stationSettingsAction(
                    title: "Remove Station",
                    subtitle: "Delete this saved profile",
                    systemImage: "trash.fill",
                    tint: DashboardTheme.failure,
                    isEnabled: selectedSavedGeneratedStation != nil
                ) {
                    isShowingStationSettings = false
                    isShowingStationRemovalConfirmation = true
                }

                stationSettingsAction(
                    title: "Station Info",
                    subtitle: "Metadata & fit quality",
                    systemImage: "info.circle.fill",
                    tint: DashboardTheme.observedTemperature
                ) {
                    isShowingStationSettings = false
                    isShowingStationInfo = true
                }
            }
        }
        .padding(16)
        .frame(width: 700)
        .background(DashboardTheme.panel)
    }

    private func stationSettingsAction(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .symbolRenderingMode(.monochrome)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(tint.opacity(0.13))
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DashboardTheme.textPrimary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(DashboardTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: 157, height: 106)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(DashboardTheme.panelElevated.opacity(0.88))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DashboardTheme.border, lineWidth: 1)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.43)
    }
    
    ///Dashboard UI
    private var dashboardView: some View {
        VStack(alignment: .leading, spacing: 8) {
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

                Button {
                    isShowingStationSettings.toggle()
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "gearshape.fill")
                            .symbolRenderingMode(.monochrome)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DashboardTheme.forecastTemperature)
                        
                        Text("Station Settings")
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
                    RoundedRectangle(
                        cornerRadius: 8,
                        style: .continuous
                    )
                    .fill(
                        DashboardTheme.panelElevated.opacity(0.88)
                    )
                }
                .overlay {
                    RoundedRectangle(
                        cornerRadius: 8,
                        style: .continuous
                    )
                    .stroke(
                        DashboardTheme.border,
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
                
                .help("Station Settings")
                .popover(
                    isPresented: $isShowingStationSettings,
                    arrowEdge: .bottom
                ) {
                    stationSettingsPopover
                }
                
                HStack(spacing: 8) {
                    Text(
                        "Station: \(selectedLocation.displayStationID)"
                    )
                    .foregroundStyle(DashboardTheme.textSecondary)
                    
                    stationRefreshStatus
                    
                    Divider()
                        .frame(height: 18)

                    Button {
                        Task {
                            await refreshWeather()
                        }
                    } label: {
                        Image(
                            systemName: isLoading
                                ? "arrow.triangle.2.circlepath"
                                : "arrow.clockwise"
                        )
                        .symbolRenderingMode(.monochrome)
                        .font(
                            .system(
                                size: 12,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(
                            DashboardTheme.forecastTemperature
                        )
                        .frame(width: 24, height: 24)
                        .background {
                            RoundedRectangle(
                                cornerRadius: 6,
                                style: .continuous
                            )
                            .fill(
                                DashboardTheme.observedTemperature
                                    .opacity(0.14)
                            )
                        }
                        .contentShape(
                            RoundedRectangle(
                                cornerRadius: 6,
                                style: .continuous
                            )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                    .help(
                        isLoading
                            ? "Refreshing Station"
                            : "Refresh Station"
                    )
                    .accessibilityLabel(
                        isLoading
                            ? "Refreshing Station"
                            : "Refresh Station"
                    )
                }
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .padding(.horizontal, 10)
                .frame(height: 32)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(DashboardTheme.panelElevated.opacity(0.72))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(DashboardTheme.border, lineWidth: 1)
                }
                
                Spacer(minLength: 0)
                
            }
            .controlSize(.large)
            
                        
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
    
    /// Gives current conditions a nice card. Thermal Gauge update as of Aug 3, 2026
    private var leftDashboardPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            dashboardCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Current Conditions")
                        .font(.headline)
                    
                    ThermalGaugeView(
                        scale: thermalGaugeScale,
                        airTemperature:
                            currentConditionValue(
                                observation.airTemperature
                            ),
                        heatIndex:
                            currentConditionValue(
                                observation.heatIndex
                            ),
                        wetBulb:
                            currentConditionValue(
                                observation.wetBulb
                            ),
                        dewPoint:
                            currentConditionValue(
                                observation.dewPoint
                            ),
                        conditionDescription:
                            currentConditionDescription,
                        windSpeed:
                            currentConditionValue(
                                observation.windSpeed
                            ),
                        pressure:
                            currentConditionValue(
                                observation.pressure
                            )
                    )
                }
            }
            
            dashboardCard {
                almanacGrid
            }
        }
        .foregroundStyle(DashboardTheme.textPrimary)
        .frame(width: 365)
    }
    
    /// Dashboard controls that live beneath the left information cards. Specifically
    /// for forecast discussion & Climate graphs
    private var dashboardActionButtons: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            HStack(spacing: 7) {
                /// Climate Graphs
                Button {
                    selectedClimateGraph =
                        .annualTemperatureCurve
                    
                    activeClimateGraph =
                        .annualTemperatureCurve
                } label: {
                    exploreActionLabel(
                        title: "Climate Graphs",
                        subtitle: "Seasonal curves",
                        symbol: "chart.line.uptrend.xyaxis",
                        accent: DashboardTheme.forecastTemperature,
                        trailingSymbol: "chevron.right"
                    )
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                
                .help("Open Climate Graphs")
                .accessibilityLabel("Open Climate Graphs")
                
                /// Forecast Discussion
                Button {
                    Task {
                        await loadForecastDiscussion()
                    }
                } label: {
                    exploreActionLabel(
                        title:
                            isLoadingForecastDiscussion
                        ? "Loading Discussion..."
                        : "Forecast Discussion",
                        subtitle: "Technical discussion",
                        symbol: "text.bubble",
                        accent: DashboardTheme.dayGlow,
                        trailingSymbol: "chevron.right"
                    )
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                
                .disabled(isLoadingForecastDiscussion)
            }
            .padding(.top, -8)
        }
        .padding(.horizontal, 4)
        .frame(
            width: 365,
            alignment: .leading
        )
    }
    
    private func exploreActionLabel(
        title: String,
        subtitle: String,
        symbol: String,
        accent: Color,
        trailingSymbol: String
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .symbolRenderingMode(.monochrome)
                .font(
                    .system(
                        size: 15,
                        weight: .semibold
                    )
                )
                .foregroundStyle(accent)
                .frame(width: 28, height: 28)
                .background {
                    RoundedRectangle(
                        cornerRadius: 7,
                        style: .continuous
                    )
                    .fill(accent.opacity(0.10))
                }

            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(
                        DashboardTheme.textPrimary
                    )
                    .minimumScaleFactor(0.8)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(
                        DashboardTheme.textSecondary
                    )
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 8)

            Image(systemName: trailingSymbol)
                .font(
                    .system(
                        size: 11,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    DashboardTheme.textSecondary
                )
        }
        .padding(.horizontal, 10)
        .frame(
            maxWidth: .infinity,
            minHeight: 48,
            alignment: .leading
        )
        .background {
            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
            .fill(
                DashboardTheme.panelElevated.opacity(0.62)
            )
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
            .stroke(
                DashboardTheme.border,
                lineWidth: 1
            )
        }
        .contentShape(
            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
        )
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
            
            guard let dayOfYear = ClimateCalendar.climatologicalDayOfYear(
                for: date,
                in: selectedLocation.timeZone,
                leapDayPolicy: .mapToFebruary28
            ),
                  let minimum = points.map(\.temperatureFahrenheit).min() else {
                return
            }
            
            result[dayOfYear] = minimum
        }
    }
    
    private var smoothedLiveSeasonalPhasePoints: [SeasonalPhasePoint] {
        let observedPoints = liveSeasonalPhasePoints

        let observedMinimums = Dictionary(
            uniqueKeysWithValues:
                observedPoints.map {
                    (
                        $0.dayOfYear,
                        $0.minimumTemperature
                    )
                }
        )

        let forecastMinimums =
            forecastDailyMinimumsByDayOfYear

        let combinedMinimums =
            observedMinimums.merging(
                forecastMinimums
            ) {
                _,
                forecastValue in

                forecastValue
            }

        let latestObservedDay =
            observedPoints
                .map(\.dayOfYear)
                .max()

        let centerDays =
            observedPoints.compactMap {
                point -> Int? in

                if point.dayOfYear == latestObservedDay {
                    let hasFiveForecastDays =
                        (1...5).allSatisfy {
                            offset in

                            let day =
                                wrappedClimateDay(
                                    point.dayOfYear + offset
                                )

                            return forecastMinimums[day] != nil
                        }

                    guard hasFiveForecastDays else {
                        return nil
                    }
                }

                return point.dayOfYear
            }

        let rollingMinimums =
            WeatherMath.centeredRollingAverage(
                valuesByIndex: combinedMinimums,
                centeredAt: centerDays,
                radius: 5,
                minimumSampleCount: 7,
                cycleLength: 365
            )

        return observedPoints.compactMap {
            point in

            guard let rollingMinimum =
                    rollingMinimums[point.dayOfYear] else {
                return nil
            }

            return SeasonalPhasePoint(
                dayOfYear: point.dayOfYear,
                normalizedSolar: point.normalizedSolar,
                minimumTemperature: rollingMinimum
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
    private func thermalPaceStandardDeviation(
        variable: ThermalPaceVariable,
        month: Int,
        day: Int,
        dayOfYear: Int
    ) -> Double? {
        
        /// Provider-Agnostic spreads stored in a generated US or Canadian profile.
        if let storedSpread =
                selectedLocation
                    .generatedClimateProfile?
                    .dailyTemperatureSpreads?
                    .first(
                        where: {
                            $0.dayOfYear == dayOfYear
                        }
                    ) {
            switch variable {
            case .minimum:
                return storedSpread.minimumStandardDeviation
                
            case .maximum:
                return storedSpread.maximumStandardDeviation
            }
        }
        
        /// Backward-compatible ACIS fallback for built-in location and older
        /// saved US profiles.
        
        var calendar = Calendar(identifier: .gregorian)
        
        calendar.timeZone =
            TimeZone(secondsFromGMT: 0)
            ?? .current
        
        let values =
            thresholdNormalPeriodObservations
                .compactMap {
                    observation -> Double? in
                    
                    guard calendar.component(
                        .month,
                        from: observation.date
                    ) == month,
                    calendar.component(
                        .day,
                        from: observation.date
                    ) == day else {
                        return nil
                    }
                    
                    switch variable {
                    case .minimum:
                        return observation.minimumTemperature
                        
                    case .maximum:
                        return observation.maximumTemperature
                    }
                }
        return WeatherMath.sampleStandardDeviation(values)
    }
    
    /// Builds the shared thermal-gauge range from this station's
    /// annual air-temperature climatology.
    private var thermalGaugeScale: ThermalGaugeScale {
        let climateDays = 1...365
        
        guard
            let coldestNormalDay = climateDays.min(
                by: {
                    selectedLocation.normalLow(dayOfYear: $0)
                        < selectedLocation.normalLow(dayOfYear: $1)
                }
            ),
            let warmestNormalDay = climateDays.max(
                by: {
                    selectedLocation.normalHigh(dayOfYear: $0)
                        < selectedLocation.normalHigh(dayOfYear: $1)
                }
            )
        else {
            return ThermalGaugeScale(
                rawLowerBoundFahrenheit: -20.0,
                rawUpperBoundFahrenheit: 120.0
            )
        }
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = selectedLocation.timeZone
        
        guard
            let referenceYearStart = calendar.date(
                from: DateComponents(
                    year: 2001,
                    month: 1,
                    day: 1
                )
            ),
            let coldestNormalDate = calendar.date(
                byAdding: .day,
                value: coldestNormalDay - 1,
                to: referenceYearStart
            ),
            let warmestNormalDate = calendar.date(
                byAdding: .day,
                value: warmestNormalDay - 1,
                to: referenceYearStart
            )
        else {
            return ThermalGaugeScale(
                rawLowerBoundFahrenheit: -20.0,
                rawUpperBoundFahrenheit: 120.0
            )
        }
        
        let coldestMonth =
            calendar.component(
                .month,
                from: coldestNormalDate
            )
        
        let coldestDay =
            calendar.component(
                .day,
                from: coldestNormalDate
            )
        
        let warmestMonth =
            calendar.component(
                .month,
                from: warmestNormalDate
            )
        
        let warmestDay =
            calendar.component(
                .day,
                from: warmestNormalDate
            )
        
        let minimumStandardDeviation =
            thermalPaceStandardDeviation(
                variable: .minimum,
                month: coldestMonth,
                day: coldestDay,
                dayOfYear: coldestNormalDay
            ) ?? 0.0
        
        let maximumStandardDeviation =
            thermalPaceStandardDeviation(
                variable: .maximum,
                month: warmestMonth,
                day: warmestDay,
                dayOfYear: warmestNormalDay
            ) ?? 0.0
        
        let rawLowerBound =
            selectedLocation.normalLow(
                dayOfYear: coldestNormalDay
            )
            - 2.0 * minimumStandardDeviation
        
        let rawUpperBound =
            selectedLocation.normalHigh(
                dayOfYear: warmestNormalDay
            )
            + 2.0 * maximumStandardDeviation
        
        return ThermalGaugeScale(
            rawLowerBoundFahrenheit: rawLowerBound,
            rawUpperBoundFahrenheit: rawUpperBound
        )
    }
    
    /// Compares the first complete future station-local forecast day with that date's climatology.
    fileprivate var forecastNormalComparison: ForecastNormalComparison? {
        
        var calendar = Calendar(identifier: .gregorian)
        
        calendar.timeZone = selectedLocation.timeZone
        
        let today = calendar.startOfDay(for: Date())
        
        
        guard
            let targetDate =
                calendar.date(
                    byAdding: .day,
                    value: 1,
                    to: today
                )
        else {
            return nil
        }
        
        let forecastPoints =
            temperatureForecast
            .filter { point in
                calendar.isDate(point.timestamp, inSameDayAs: targetDate)
            }
            .sorted {
                $0.timestamp < $1.timestamp
            }
        
        /// Reject an incomplete daily forecast. Still permits hourly & three-horly provider cadences.
        guard
            let firstPoint = forecastPoints.first,
            let lastPoint = forecastPoints.last,
            lastPoint.timestamp
                .timeIntervalSince(firstPoint.timestamp) >= 18.0 * 60.0 * 60.0,
            let forecastHigh = forecastPoints
                .map(\.temperatureFahrenheit)
                .max(),
            let forecastLow =
                forecastPoints
                .map(\.temperatureFahrenheit)
                .min(),
            let climateDay =
                ClimateCalendar
                .climatologicalDayOfYear(
                    for: targetDate,
                    in: selectedLocation.timeZone,
                    leapDayPolicy: .mapToFebruary28
                )
        else {
            return nil
        }
        
        let month = calendar.component(.month, from: targetDate)
        
        let day = calendar.component(.day, from: targetDate)
        
        let highStandardDeviation = thermalPaceStandardDeviation(
            variable: .maximum,
            month: month,
            day: day,
            dayOfYear: climateDay
        )
        
        let lowStandardDeviation = thermalPaceStandardDeviation(
            variable: .minimum,
            month: month,
            day: day,
            dayOfYear: climateDay
        )
        
        return ForecastNormalComparison(
            localDate: targetDate,
            forecastHighFahrenheit: forecastHigh,
            forecastLowFahrenheit: forecastLow,
            normalHighFahrenheit: selectedLocation.normalHigh(dayOfYear: climateDay),
            normalLowFahrenheit: selectedLocation.normalLow(dayOfYear: climateDay),
            highStandardDeviation: highStandardDeviation,
            lowStandardDeviation: lowStandardDeviation
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
            let standardDeviation =
                thermalPaceStandardDeviation(
                    variable: selectedThermalPaceVariable,
                    month: month,
                    day: day,
                    dayOfYear: climateDay
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
            .chartXAxisLabel(
                "Normalized Solar, s(t)",
                position: .bottom,
                alignment: .center
            )
            .chartYAxisLabel(
                "Tmin (°F)",
                position: .leading,
                alignment: .center
            )
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
    
    /// Places today on the stable climatological calendar using
    /// the selected station's local timezone.
    private var selectedLocationReferenceDayOfYear:
    Double {
        Double(
            ClimateCalendar
                .climatologicalDayOfYear(
                    for: Date(),
                    in:
                        selectedLocation.timeZone,
                    leapDayPolicy:
                            .mapToFebruary28
                )
            ?? 1
        )
    }
    
    private var adaptiveFreezeFreeSummary: ClimateThresholdSummary? {
        
        [
            thresholdWidgetFreezeSummary,
            thresholdWidgetHardFreezeSummary
        ]
            .compactMap { $0 }
            .first { summary in
                summary.hasMeaningfulSpringLockIn &&
                summary.completeSeasonCount >= 15
                
            }
    }
    
    /// Creates an adaptive selector and display its chosen threshold as a compact row.
    /// It requires a climatologically meaningful spring lock-in, at least 15 complete seasons.
    /// Most importantly today lying between the 90% spring and fall outer boudnaries -- at least 10%
    /// historical season membership. Of all the qualifying  thresholds, select the highest.
    private var adaptiveWarmLockInSummary: ClimateThresholdSummary? {
        let currentDay = selectedLocationReferenceDayOfYear
        
        return thresholdWidgetWarmSummaries
            .filter { summary in
                let ninetyPercentPoint = summary.riskPoint(eventRiskPercent: 90.0)
                
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
        
        let selectedFreezeSummary =
            adaptiveFreezeFreeSummary
        
        let tenPercentRiskPoint =
            selectedFreezeSummary?
                .riskPoint(eventRiskPercent: 10.0)
        
        let ninetyPercentRiskPoint =
            selectedFreezeSummary?
                .riskPoint(eventRiskPercent: 90.0)
        
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
            
            if let freezeSummary = selectedFreezeSummary {
                HStack(spacing: 10) {
                    Image(systemName: "snowflake")
                        .font(.title3)
                        .foregroundStyle(.cyan)
                        .frame(width: 26)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(
                            freezeSummary.threshold == 32.0
                            ? "32 °F Freeze-Free"
                            : "28 °F Hard-Freeze-Free"
                        )
                        
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
                
            } else {
                Text("No reliable freeze-free saason")
                    .font(.caption)
                    .foregroundStyle(DashboardTheme.textSecondary)
            }
            
            if let warmSummary =
                adaptiveWarmLockInSummary {
                
                let tenPercentPoint =
                    warmSummary.riskPoint(eventRiskPercent: 10.00)
                
                let ninetyPercentPoint =
                    warmSummary.riskPoint(eventRiskPercent: 90.00)
                
                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    HStack(spacing: 6) {
                        Image(
                            systemName: "sun.max.fill"
                        )
                        .foregroundStyle(DashboardTheme.normal)
                        
                        Text(
                            "\(warmSummary.threshold, specifier: "%.0f")°F+ Afternoon Lock-In"
                        )
                        .font(.caption.weight(.semibold))
                        
                        Spacer()
                    }
                    
                    if let leftOuterDay =
                        ninetyPercentPoint?.springRiskDay,
                       let leftInnerDay =
                        tenPercentPoint?.springRiskDay,
                       let rightInnerDay =
                        tenPercentPoint?.fallRiskDay,
                       let rightOuterDay =
                        ninetyPercentPoint?.fallRiskDay {
                        
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
            
            if let summaryForCount =
                selectedFreezeSummary ??
                adaptiveWarmLockInSummary {
                
                Text(
                    "\(summaryForCount.completeSeasonCount) complete seasons"
                )
                .font(.caption)
                .foregroundStyle(DashboardTheme.textSecondary)
            } else {
                Text("No active threshold season.")
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
            let climateObservations: [ClimateDailyObservation]
            
            switch requestedLocation.countryCode {
            case "CA":
                climateObservations =
                    try await
                        ClimateWeatherYearObservationService()
                            .fetchCanadianWeatherYearObservations(
                                canonicalIdentifier: requestedLocation.acisStationID,
                                startDate: ClimateDate(year: currentYear, month: 1, day: 1),
                                endDate: ClimateDate(year: currentYear, month: currentMonth, day: currentDay)
                            )
                
            case "US":
                let observations =
                    try await ACISClimateService
                        .fetchDailyObservations(
                            stationID: requestedLocation.acisStationID,
                            startDate: startDate,
                            endDate: endDate
                        )
                
                climateObservations =
                    ACISClimateDailyObservationAdapter
                        .observations(from: observations)
                
            default :
                liveSeasonalPhaseStatus =
                "Current-year climate data is unsupported for this country"
                + requestedLocation.countryCode
                + " stations."
                
                return
            }
            
            /// Ignore results if the user changed stations while loading.
            guard
                Task.isCancelled == false,
                selectedLocation.id == requestedLocation.id
            else {
                return
            }
            
            let weatherYearDays =
                ClimateWeatherYearCalculator
                    .weatherYearDays(
                        from: climateObservations,
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
    
    /// Selects the compact widget's freeze and adaptive summaries from any
    /// provider-neutral summary collection.
    private func applyThresholdWidgetSummaries(
        _ summaries: [ClimateThresholdSummary]
    ) {
        let coldNightDefinitions =
            ClimateThresholdFamily
                .coldNights
                .definitions

        let freezeDefinition =
            coldNightDefinitions.first { definition in
                definition.threshold == 32.0
            }

        let hardFreezeDefinition =
            coldNightDefinitions.first { definition in
                definition.threshold == 28.0
            }

        let warmDefinitions =
            Set(
                ClimateThresholdFamily
                    .warmAfternoonLockIn
                    .definitions
            )

        thresholdWidgetFreezeSummary =
            freezeDefinition.flatMap { definition in
                summaries.first { summary in
                    summary.definition == definition
                }
            }

        thresholdWidgetHardFreezeSummary =
            hardFreezeDefinition.flatMap { definition in
                summaries.first { summary in
                    summary.definition == definition
                }
            }

        thresholdWidgetWarmSummaries =
            summaries
                .filter { summary in
                    warmDefinitions.contains(
                        summary.definition
                    )
                }
                .sorted { first, second in
                    first.threshold < second.threshold
                }

        let selectedFreezeSummary =
            [
                thresholdWidgetFreezeSummary,
                thresholdWidgetHardFreezeSummary
            ]
            .compactMap { $0 }
            .first { summary in
                summary.hasMeaningfulSpringLockIn &&
                summary.completeSeasonCount >= 15
            }

        guard let selectedFreezeSummary else {
            thresholdWidgetStatus =
                "No reliable 32°F or 28°F freeze-free season"
            return
        }

        let medianRiskPoint =
            selectedFreezeSummary.riskPoint(
                eventRiskPercent: 50.0
            )

        let springText =
            ClimateCalendar.monthDayText(
                fromClimatologicalDay:
                    medianRiskPoint?.springRiskDay
            ) ?? "none"

        let fallText =
            ClimateCalendar.monthDayText(
                fromClimatologicalDay:
                    medianRiskPoint?.fallRiskDay
            ) ?? "none"

        let seasonName =
            selectedFreezeSummary.threshold == 32.0
                ? "32°F freeze-free"
                : "28°F hard-freeze-free"

        thresholdWidgetStatus =
            "\(seasonName): \(springText) → \(fallText)"
    }
    
    ///Threshold loader. Only requests Tmax and Tmin because that's all we need.
    private func loadThresholdWidgetClimateData() async {
        let requestedLocation = selectedLocation
        
        thresholdNormalPeriodObservations = []
        thresholdWidgetWarmSummaries = []
        thresholdWidgetFreezeSummary = nil
        thresholdWidgetHardFreezeSummary = nil
        thresholdWidgetStatus = "Loading normal-period threshold data..."
        
        if let storedSummaries =
                requestedLocation
                    .generatedClimateProfile?
                    .thresholdSummaries,
           storedSummaries.isEmpty == false {
            
            applyThresholdWidgetSummaries(storedSummaries)
            
            return
        }
        
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
            
            let climateObservations =
                ACISClimateDailyObservationAdapter
                    .observations(from: observations)
            
            
            
            let pairedTemperatureCount =
                climateObservations.filter { observation in
                    observation
                        .minimumTemperature
                        .usableFahrenheit != nil
                    && observation
                        .maximumTemperature
                        .usableFahrenheit != nil
                }
                .count
            
            if pairedTemperatureCount == 0 {
                thresholdWidgetStatus = "No normal-period temperature data"
            } else {
               let coldNightDefinitions =
                    ClimateThresholdFamily
                    .coldNights
                    .definitions
                    .filter { definition in
                        definition.threshold == 32.0 ||
                        definition.threshold == 28.0
                    }
                
                let warmlockindefinitions =
                    ClimateThresholdFamily
                        .warmAfternoonLockIn
                        .definitions
                
                let widgetDefinitions =
                    coldNightDefinitions +
                    warmlockindefinitions
                
                let widgetSummaries =
                    widgetDefinitions.map { definition in
                        ClimateThresholdCalculator
                            .thresholdSummary(
                                from: climateObservations,
                                startYear: GeneratedClimateProfileBuilder.normalStartYear,
                                endYear: GeneratedClimateProfileBuilder.normalEndYear,
                                definition: definition
                            )
                    }
                applyThresholdWidgetSummaries(widgetSummaries)
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
            thresholdWidgetHardFreezeSummary = nil
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
    
    /// Saves a new station or atomically replaces the original
    /// station when completing a rebuild.
    private func saveGeneratedStation(
        _ result: GeneratedStationBuildResult,
        replacingStationID: String? = nil
    ) {
        let savedStation =
            SavedGeneratedStation(result: result)

        let replacementIndex =
            replacingStationID.flatMap { originalID in
                savedGeneratedStations.firstIndex {
                    $0.id == originalID
                }
            }

        let stationIDsToReplace = Set(
            [
                savedStation.id,
                replacingStationID
            ]
            .compactMap { $0 }
        )

        var updatedStations =
            savedGeneratedStations.filter {
                stationIDsToReplace.contains($0.id) == false
            }

        if let replacementIndex {
            updatedStations.insert(
                savedStation,
                at: min(
                    replacementIndex,
                    updatedStations.count
                )
            )
        } else {
            updatedStations.append(savedStation)
        }

        do {
            try GeneratedStationStore.save(
                updatedStations
            )

            savedGeneratedStations = updatedStations
            selectedLocation =
                WeatherLocation.generated(
                    from: savedStation
                )

            Task {
                await refreshWeather()
            }
        } catch {
            networkStatus =
                "Station could not be saved: "
                + error.localizedDescription
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
    private func solarMetricRow(
        label: String,
        symbol: String,
        symbolColor: Color,
        value: String,
        unit: String = ""
    ) -> some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
                .symbolRenderingMode(.monochrome)
                .font(
                    .system(
                        size: 11,
                        weight: .semibold
                    )
                )
                .foregroundStyle(symbolColor)
                .frame(width: 14)

            Text(label)
                .lineLimit(1)
                .layoutPriority(1)

            Spacer(minLength: 8)

            HStack(spacing: 5) {
                Text(value)
                    .monospacedDigit()

                if !unit.isEmpty {
                    Text(unit)
                }
            }
            .fixedSize(
                horizontal: true,
                vertical: false
            )
        }
        .font(.subheadline)
    }
    /// Returns a live measurement only after a successful weather refresh.
    private func currentConditionValue(
        _ value: Double?
    ) -> Double? {
        guard case .updated = weatherRefreshState,
              let value else {
            return nil
        }
        
        return value
    }
    
   
    
    private var currentConditionDescription: String {
        guard case .updated = weatherRefreshState else {
            return "Unavailable"
        }
        
        return observation.condition
    }
    
    
    private var almanacGrid: some View {
        let today = WeatherAlmanac.dayOfYear()


        let solarEnergy = selectedLocation.solarEnergy(dayOfYear: today)

        let solarIndex = selectedLocation.normalizedSolarEnergy(dayOfYear: today)
        
        
        
        
        
        return VStack(alignment: .leading, spacing: 8) {
            
            ForecastNormalComparisonView(
                comparison: forecastNormalComparison,
                timeZone: selectedLocation.timeZone
            )
            
            SunPathView(
                latitude: selectedLocation.latitude,
                longitude: selectedLocation.longitude,
                timeZone: selectedLocation.timeZone
                
            )
            
            VStack(
                alignment: .leading,
                spacing: 8
            ) {
                solarMetricRow(
                    label: "Daylight Hours",
                    symbol: "sun.max.fill",
                    symbolColor: .yellow.opacity(0.90),
                    value: WeatherAlmanac.getFormattedDaylight(
                        for: selectedLocation,
                        dayOfYear: Int(selectedLocationReferenceDayOfYear)
                    ),
                    unit: ""
                )
                
                solarMetricRow(
                    label: "Daily Solar Energy",
                    symbol: "sun.max.fill",
                    symbolColor: .orange.opacity(0.90),
                    value: String(
                        format: "%.2f",
                        solarEnergy
                    ),
                    unit: "kWh/m²/day"
                )

                solarMetricRow(
                    label: "Normalized Solar",
                    symbol: "chart.line.uptrend.xyaxis",
                    symbolColor: DashboardTheme.dayGlow,
                    value: String(
                        format: "%.3f",
                        solarIndex
                    )
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

            /// Present temperature now displayed on the temperature graph.
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
            
            /// current real-time indicator
            if let currentPoint = temperatureHistory.last {
                PointMark(
                    x: .value("Time", currentPoint.timestamp),
                    y: .value("Temperature", currentPoint.temperatureFahrenheit)
                )
                .foregroundStyle(.red)
                .symbolSize(90)
                
                .annotation(position: .top) {
                    Text("\(Int(currentPoint.temperatureFahrenheit))")
                        .padding(5)
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
            
            /// Makes the daylight look nicer.
            if daylightPhase == .day {
                RadialGradient(
                    colors: [
                        DashboardTheme.dayGlow.opacity(0.20),
                        DashboardTheme.dayGlow.opacity(0.055),
                        Color.clear
                    ],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 850
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
            
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
                                initialStationSource:
                                    observation.station.source,
                                replacingStationID: nil
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
                .padding(.top, 1)
            }
            /// Load saved stations and automatically refresh the default built-in station
            .task {
                loadGeneratedStations()
                await refreshWeather()
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
            .sheet(isPresented: $isShowingStationInfo) {
                StationInfoView(
                    metadata: StationInfoMetadata(
                        location: selectedLocation,
                        savedStation: selectedSavedGeneratedStation)
                )
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
                    initialStationSource:
                        request.initialStationSource,
                    isRebuilding:
                        request.isRebuilding
                ) { result in
                    saveGeneratedStation(
                        result,
                        replacingStationID:
                            request.replacingStationID
                    )

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
        
        let requestLocation = selectedLocation
        let requestedDurationHours = selectedHistoryDuration.rawValue
        let refreshID = UUID().uuidString
        
        let requestedStationID = requestLocation.observationStationID
        let requestedLocationName = requestLocation.name
        
        defer {
            isLoading = false
        }
        do {
            let clock = ContinuousClock()
            let fetchStart = clock.now
            let service = WeatherService()
            
            let response = try await service.fetchRecentObservations(
                stationID: requestLocation.observationStationID,
                hours: requestedDurationHours
            )
            let forecast: Forecast?
            let forecastFailureDescription: String?
            
            do {
                forecast = try await forecastRouter
                    .forecast(
                        for: ForecastRequest(
                            latitude: requestLocation.latitude,
                            longitude: requestLocation.longitude,
                            timeZoneIdentifier: requestLocation.timeZoneIdentifier,
                            countryCode: requestLocation.countryCode,
                            stationIdentifier: requestLocation.observationStationID
                        )
                    )
                
                forecastFailureDescription = nil
            } catch {
                forecast = nil
                forecastFailureDescription = error.localizedDescription
            }
            
            let fetchDuration = fetchStart.duration(to: clock.now)
            
            let fetchSeconds =
            Double(fetchDuration.components.seconds) + Double(fetchDuration.components.attoseconds) / 1_000_000_000_000_000_000.0
            let cutoffDate = Date().addingTimeInterval( -Double(requestedDurationHours) * 60.0 * 60.0
            )
            
            guard selectedLocation.id == requestLocation.id,
                  selectedHistoryDuration.rawValue == requestedDurationHours else {
                print("""
                [FORECAST DEBUG \(refreshID)] Discarded stale refresh.
                Requested: \(requestLocation.name) \(requestLocation.observationStationID)
                Current: \(selectedLocation.name) \(selectedLocation.observationStationID)
                """)
                return
            }
            
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
            temperatureForecast =
                DashboardForecastAdapter
                    .temperaturePoints(from: forecast)
            
            let diagnosticNow = Date()
            let next24Hours = diagnosticNow.addingTimeInterval(24.0 * 60.0 * 60.0)
            let next72Hours = diagnosticNow.addingTimeInterval(72.0 * 60.0 * 60.0)
            
            let forecastNext24Count = temperatureForecast.filter {
                $0.timestamp >= diagnosticNow && $0.timestamp <= next24Hours
            }.count
            
            let forecastNext72Count = temperatureForecast.filter {
                $0.timestamp >= diagnosticNow && $0.timestamp <= next72Hours
            }.count
            
            let firstForecastTimestamp = temperatureForecast.first?.timestamp.ISO8601Format() ?? "nil"
            
            let lastForecastTimestamp = temperatureForecast.last?.timestamp.ISO8601Format() ?? "nil"
            
            let latestHistoryTimestamp = temperatureHistory.last?.timestamp.ISO8601Format() ?? "nil"
            
            print("""
                [FORECAST DEBUG \(refreshID)]
                Requested station: \(requestedLocationName) \(requestedStationID)
                Current station: \(selectedLocation.name) \(selectedLocation.observationStationID)
                Requested duration: \(requestedDurationHours) hours
                Current duration: \(selectedHistoryDuration.rawValue) hours
                Forecast count: \(temperatureForecast.count)
                Forecast next 24 hours: \(forecastNext24Count)
                Forecast next 72 hours: \(forecastNext72Count)
                First forecast timestamp: \(firstForecastTimestamp)
                Last forecast timestamp: \(lastForecastTimestamp)
                Latest history timestamp: \(latestHistoryTimestamp)
                Forecast error: \(forecastFailureDescription ?? "none")
                Diagnostic now: \(diagnosticNow.ISO8601Format())
                """)
            
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
                    displayCondition =
                        DashboardForecastAdapter
                            .firstConditionText(from: forecast) ?? "Unknown"
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
                
                let forecastStatusText: String
                
                if let forecastFailureDescription {
                    forecastStatusText =
                        "Forecast unavailable: \(forecastFailureDescription)"
                } else {
                    forecastStatusText =
                    "\(forecast?.samples.count ?? 0) forecast hours loaded."
                }
                
                networkStatus =
                    "Weather updated successfully in \(formattedFetchSeconds) seconds. " +
                    "\(temperatureHistory.count) graph points loaded. " +
                    forecastStatusText
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
