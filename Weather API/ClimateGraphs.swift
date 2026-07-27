import SwiftUI
import Charts

/// Adds options for the Annual Temperature graph
struct AnnualTemperatureChartOptions {
    
    /// Master visibility switch for both variability envelopes.
    var showsVariabilityBands = true
    
    /// Number of std dev displayed (z-value):
    var sigmaLevel = 1
    
    /// Independently controls Tmax variability
    var showsHighTemperatureSpread = true
    
    /// Independent control of Tmin visibility
    var showsLowTemperatureSpread = true
    
    /// Shows the selected Tmin and Tmax variability ranges in the hover annotation.
    var showsStandardDeviationInHover = true
    
    /// Shows abs daily solar insolation S(t)
    var showsSolarInsolationInHover = true
    
    /// Shows normalized solar insolation s(t). ranges from 0 to 1.
    var showsNormalizedSolarInHover = true
    
    /// Shows the persistent midsommar and midwinter summary.
    var showsThermalTimingSummary = true
    
    var sigmaMultiplier: Double {
        Double(sigmaLevel)
    }
}

/// Polished controls for the Annual Temperature Curve.
///
/// Kept outside ClimateGraphView so the main chartdoes not become responsible
/// for constructing its own settings UI.
struct AnnualTemperatureGraphOptionsView: View {
    
    @Binding
    var options: AnnualTemperatureChartOptions
    
    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 11
        ) {
            HStack(spacing: 11) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .foregroundStyle(DashboardTheme.observedTemperature)
                
                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    Text("Graph Options")
                        .font(.headline)
                        .foregroundStyle(DashboardTheme.textPrimary)
                    
                    Text("Annual Temperature Curve")
                        .font(.caption)
                        .foregroundStyle(DashboardTheme.textSecondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                Toggle(
                    "Show variability bands",
                    isOn: $options.showsVariabilityBands
                )
                .toggleStyle(.switch)
                
                HStack {
                    Text("Band magnitude")
                        .foregroundStyle(DashboardTheme.textSecondary)
                    
                    Spacer()
                    
                    Picker(
                        "Band Magnitude",
                        selection: $options.sigmaLevel
                    ) {
                        Text("±1σ")
                            .tag(1)
                        
                        Text("±2σ")
                            .tag(2)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 130)
                }
                
                VStack(
                    alignment: .leading,
                    spacing: 9
                ) {
                    Text("Displayed envelopes")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DashboardTheme.textSecondary)
                    
                    Toggle(
                        isOn: $options.showsHighTemperatureSpread
                    ) {
                        Label {
                            Text("Tmax variability")
                        } icon: {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                    .toggleStyle(.checkbox)
                    
                    Toggle(
                        isOn: $options.showsLowTemperatureSpread
                    ) {
                        Label {
                            Text("Tmin variability")
                        } icon: {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    .toggleStyle(.checkbox)
                }
            }
            .padding(11)
            .background(DashboardTheme.panel)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
            )
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
            
            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                Text("Hover details")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DashboardTheme.textSecondary)
                
                Toggle(
                    "Temperature variability, σ",
                    isOn:
                        $options.showsStandardDeviationInHover
                )
                .toggleStyle(.checkbox)
                
                Toggle(
                    "Solar insolation, S(t)",
                    isOn: $options.showsSolarInsolationInHover
                )
                .toggleStyle(.checkbox)
                
                Toggle(
                    "Normalized solar, s(t)",
                    isOn: $options.showsNormalizedSolarInHover
                )
                .toggleStyle(.checkbox)
            }
            .padding(11)
            .background(DashboardTheme.panel)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
            )
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
            
            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                Text("Annotations")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DashboardTheme.textSecondary)
                
                Toggle(
                    "Thermal midsommar and midwinter",
                    isOn: $options.showsThermalTimingSummary
                )
                .toggleStyle(.checkbox)
            }
            .padding(11)
            .background(DashboardTheme.panel)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
            )
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
        .padding(14)
        .frame(width: 350)
        .background(DashboardTheme.panelElevated)
    }
}

///threshold risk season. gives us exactly two valid modes: Spring risk and fall risk.
enum ThresholdRiskSeason: String, CaseIterable, Identifiable {
    case spring
    case fall
    
    var id: String {
        rawValue
    }
    
    var title: String {
        switch self {
        case .spring:
            return "Spring"
        case .fall:
            return "Fall"
        }
    }
    
    var datePhrase: String {
        switch self {
        case .spring:
            return "Spring after"
        case .fall:
            return "Fall before"
        }
    }
}
///output thresholds as graphs
enum ThresholdOutputMode: String, CaseIterable, Identifiable {
    case graph
    case table
    
    var id: String {
        rawValue
    }
    
    var title: String {
        switch self {
        case .graph:
            return "Graph"
        case .table:
            return "Table"
        }
    }
}
enum ThresholdEventMode: String, CaseIterable, Identifiable {
    case coldNights
    case warmAfternoon
    case warmAfternoonLockIn
    case mildNights
    
    var id: String {
        rawValue
    }
    
    /// Connects this UI mode to its provider-agnostic scientific destination family.
    var family: ClimateThresholdFamily {
        switch self {
            
        case .coldNights:
            return .coldNights
            
        case .warmAfternoon:
            return .warmAfternoon
            
        case .warmAfternoonLockIn:
            return .warmAfternoonLockIn
            
        case .mildNights:
            return .mildNights
        }
    }
    
    var title: String {
        switch self {
        case .coldNights:
            return "Cold Nights"
        case .warmAfternoon:
            return "Warm Afternoons" /// first occurence of a 50 degree day in spring
        case .warmAfternoonLockIn:
            return "Warm Afternoon Lock-In"
        case .mildNights:
            return "Mild Night Onset"
        }
    }
    
    var technicalLabel: String {
        switch self {
        case .coldNights:
            return "Tmin ≤ threshold"
        case .warmAfternoon:
            return "Tmax ≥ threshold"
        case .warmAfternoonLockIn:
            return "Tmax < threshold"
        case .mildNights:
            return "Tmin ≥ threshold"
        }
    }
    
    /// A curated subset for visible UI buttons. The complete threshold catalog remains
    /// available for saved profiles and future advanced controls.
    var thresholdPresets: [Double] {
        let preferredPresets: [Double]
        
        switch self {
            
        case .coldNights:
            preferredPresets =
                [28, 32, 36, 40]
            
        case .warmAfternoon:
            preferredPresets = [
                60, 70, 80, 90,
            ]
            
        case .warmAfternoonLockIn:
            preferredPresets = [
                40, 50, 60, 70
            ]
            
        case .mildNights:
            preferredPresets = [
                32, 40, 50, 60
            ]
        }
        
        let availableThresholds =
            Set(family.thresholdPresets)
        
        return preferredPresets.filter {
            availableThresholds.contains($0)
        }
    }
    
    var field: ClimateTemperatureField {
        family.field
    }
    
    var comparison: ClimateThresholdComparison {
        family.comparison
    }
    
    var springEventChoice: ClimateThresholdEventChoice {
        family.springEventChoice
    }
    
    var fallEventChoice: ClimateThresholdEventChoice {
        family.fallEventChoice
    }
    
    ///explains the thresholds
    var explanation: String {
        switch self {
        case .coldNights:
            return "After this point in spring, nights won't drop to OR below the threshold temperature until the fall."
        case .warmAfternoon:
            return "First occurence of a threshold temperature in Spring. Useful for cold climates like Fairbanks, AK since the first 50 degree day is welcomed after the long winter."
        case .warmAfternoonLockIn:
            return "By this point in spring, afternoons in summer usually always reach at least this high. For fall it is afternoons usually remain below x degrees until the following spring."
        case .mildNights:
            return "Spring shows the first mild night; e.g. the first April night that doesn't drop below freezing. This does NOT mean the last spring freeze. It is just spring knocking on the door."
        }
    }
}

enum WeatherYearOverlay: String, CaseIterable, Identifiable {
    case observedRange
    case normalRange
    case recordLowMinimum
    case recordHighMaximum
    case recordWarmMinimum
    case recordCoolMaximum
    
    var id: String {
        rawValue
    }
    
    var title: String {
        switch self {
        case .observedRange:
            return "Observed Range"
        case .normalRange:
            return "Normal Range"
        case .recordLowMinimum:
            return "Record Low"
        case .recordHighMaximum:
            return "Record High"
        case .recordWarmMinimum:
            return "Record Warm Low"
        case .recordCoolMaximum:
            return "Record Cool High"
        }
    }
    
    var color: Color {
        switch self {
        case .observedRange:
            return .blue
            
        case .normalRange:
            return .yellow
            
        case .recordLowMinimum:
            return .cyan
            
        case .recordHighMaximum:
            return .red
            
        case .recordWarmMinimum:
            return .orange
            
        case .recordCoolMaximum:
            return .pink
        }
    }
    
    var isRangeOverlay: Bool {
        switch self {
        case .observedRange, .normalRange:
            return true
            
        case .recordLowMinimum, .recordHighMaximum,
                .recordWarmMinimum, .recordCoolMaximum:
            return false
        }
    }
    
    var helpText: String {
        switch self {
        case.observedRange:
            return "Observed daily minimum-to-maximum temperature range."
            
        case .normalRange:
            return "The climatological normal daily temperature range."
            
        case .recordLowMinimum:
            return "Lowest minimum temperature observed on each calendar day."
            
        case .recordHighMaximum:
            return "Highest maximum temperature observed on each calendar day."
            
        case .recordWarmMinimum:
            return """
                Warmest minimum temperature observed on each calendar day. Record warm
                minima ('morning lows') are arguably a stronger measure of heat stress than record high
                maxima.
                """
            
        case .recordCoolMaximum:
            return """
                Coolest maximum temperature observed on each calendar day.
                Informally, this is the coolest possible afternoon for a date.
                """
        }
    }
}

///the points themselves
struct ThresholdRiskChartPoint: Identifiable {
    let threshold: Double
    let percent: Double
    let date: Date
    
    var id: String {
        "\(threshold)-\(percent)"
    }
}

struct ClimateDayPoint: Identifiable {
    let id = UUID()
    let dayOfYear: Int
    let normalHigh: Double
    let normalLow: Double
    let solarEnergy: Double
    let normalizedSolar: Double
}
///1D array with 365 elements. Each row has info on dayOfYear, data, etc (11 pieces of data)
///makes it possible for a NOWData-style weather of the specified year grapher.
struct WeatherYearDay: Identifiable, Equatable {
    let dayOfYear: Int
    let date: Date
    
    let selectedYearMinimum: Double?
    let selectedYearMaximum: Double?
    
    let normalLow: Double
    let normalHigh: Double
    
    let recordLowMinimum: Double? ///what most people think of when they hear record low
    let recordHighMaximum: Double? ///hottest afternoon
    
    let recordWarmMinimum: Double? ///hottest morning
    let recordCoolMaximum: Double? ///coolest afternoon
    
    let sampleCount: Int
    
    var id: Int {
        dayOfYear
    }
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
/// Chart Hover Overlay generalized function we can use anywhere.
struct ChartHoverOverlay: View {
    let proxy: ChartProxy
    let onHover: (CGPoint) -> Void
    let onEnded: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            if let plotFrameAnchor = proxy.plotFrame {
                let plotFrame = geometry[plotFrameAnchor]

                Rectangle()
                    .fill(.clear)
                    .frame(
                        width: plotFrame.width,
                        height: plotFrame.height
                    )
                    .position(
                        x: plotFrame.midX,
                        y: plotFrame.midY
                    )
                    .contentShape(Rectangle())
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            let xPosition =
                                location.x - plotFrame.origin.x

                            let yPosition =
                                location.y - plotFrame.origin.y

                            guard xPosition >= 0,
                                  xPosition <= plotFrame.width,
                                  yPosition >= 0,
                                  yPosition <= plotFrame.height else {
                                onEnded()
                                return
                            }

                            onHover(
                                CGPoint(
                                    x: xPosition,
                                    y: yPosition
                                )
                            )

                        case .ended:
                            onEnded()
                        }
                    }
            }
        }
    }
}


