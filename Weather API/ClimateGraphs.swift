import SwiftUI
import Charts

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
            return "Tmin <= threshold"
        case .warmAfternoon:
            return "Tmax >= threshold"
        case .warmAfternoonLockIn:
            return "Tmax < threshold"
        case .mildNights:
            return "Tmin >= threshold"
        }
    }
    
    var thresholdPresets: [Double] {
        switch self {
            ///answers last spring freeze/first fall freeze
        case .coldNights:
            return [20, 28, 32, 36, 40, 45]
        case .warmAfternoon: ///first spring occurance of a 50 degree temperature
            return [50, 60, 65, 70, 80, 90, 95, 100, 105, 110]
        case .warmAfternoonLockIn: ///after this point, afternoons are expect to reach at least this temp
            return [40, 45, 50, 55, 60, 65, 70, 75, 80, 90, 100]
        case .mildNights: ///first night in spring that makes it above freezing. NOT the last freeze.
            return [32, 36, 40, 45, 50, 55, 60]
        }
    }
    
    var field: ACISTemperatureField {
        switch self {
        case .coldNights, .mildNights:
            return .minimum
        case .warmAfternoon, .warmAfternoonLockIn:
            return .maximum
        }
    }
    
    var comparison: ACISThresholdComparison {
        switch self {
        case .coldNights:
            return .lessThanOrEqual
        case .warmAfternoon, .mildNights:
            return .greaterThanOrEqual
        case .warmAfternoonLockIn:
            return .lessThan
        }
    }

    var springEventChoice: ACISSeasonEventChoice {
        switch self {
        case .coldNights:
            return .last
        case .warmAfternoon:
            return .first
        case .warmAfternoonLockIn:
            return .last
        case .mildNights:
            return .first
        }
    }

    var fallEventChoice: ACISSeasonEventChoice {
        switch self {
        case .coldNights:
            return .first
        case .warmAfternoon:
            return .last
        case .warmAfternoonLockIn:
            return .first
        case .mildNights:
            return .last
        }
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
struct WeatherYearDay: Identifiable {
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

struct WeatherYearRecordInfo {
    let startDate: Date?
    let endDate: Date?
    let rowCount: Int
    let representedYearCount: Int
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
                        let yPosition = location.y - plotFrame.origin.y
                        
                        guard xPosition >= 0,
                              xPosition <= plotFrame.width,
                              yPosition >= 0,
                              yPosition <= plotFrame.height else {
                            onEnded()
                            return
                        }
                        
                        onHover(CGPoint(x: xPosition, y: yPosition))
                        
                    case .ended:
                        onEnded()
                    }
                }
            
        }
    }
}
