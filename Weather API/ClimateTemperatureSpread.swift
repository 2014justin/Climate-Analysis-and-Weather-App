import Foundation

/// Standard-deviation results for one climatological calendar day.

struct ClimateDailyTemperatureSpread: Identifiable, Codable, Equatable, Hashable, Sendable {
    let dayOfYear: Int
    
    let minimumStandardDeviation: Double?
    
    let maximumStandardDeviation: Double?
    
    let minimumSampleCount: Int
    
    let maximumSampleCount: Int
    
    var id: Int {
        dayOfYear
    }
}

/// Converts provider-agnostic daily observations into 365 daily temperature-spread recrods.
enum ClimateTemperatureSpreadCalculator {
    
    static func dailySpreads(
        from observations:
            [ClimateDailyObservation]
    ) -> [ClimateDailyTemperatureSpread] {
        
        var minimumsByDay:
            [Int: [Double]] = [:]
        
        var maximumsByDay:
            [Int: [Double]] = [:]
        
        for observation in observations {
            guard let dayOfYear =
                    ClimateCalendar.climatologicalDayOfYear(for: observation.localDate)
            else {
                continue
            }
            
            if let minimum =
                    observation
                    .minimumTemperature
                    .usableFahrenheit,
               minimum.isFinite {
                
                minimumsByDay[
                    dayOfYear,
                    default: []
                ].append(minimum)
            }
            
            if let maximum =
                    observation
                    .maximumTemperature
                    .usableFahrenheit,
               maximum.isFinite {
                
                maximumsByDay[
                    dayOfYear,
                    default: []
                ].append(maximum)
            }
        }
        
        return (1...365).map { dayOfYear in
            let minimums =
                minimumsByDay[dayOfYear] ?? []
            
            let maximums =
                maximumsByDay[dayOfYear] ?? []
            
            return ClimateDailyTemperatureSpread(
                dayOfYear: dayOfYear,
                minimumStandardDeviation:
                    WeatherMath.sampleStandardDeviation(minimums),
                maximumStandardDeviation:
                    WeatherMath.sampleStandardDeviation(maximums),
                minimumSampleCount: minimums.count,
                maximumSampleCount: maximums.count
            )
            
        }
    }
    
}
