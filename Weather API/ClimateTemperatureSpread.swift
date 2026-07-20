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
                    climatologicalDayOfYear(for: observation.localDate)
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
    
    /// Produces exactly 365 provider-agnostic records, independently calculates Tmin and Tmax spreads,
    /// excludes Feb 29, ignores unusable/non-finite readings, and retains sample counts for debugging.
    private static func climatologicalDayOfYear(
        for climateDate: ClimateDate
    ) -> Int? {
        
        guard !(climateDate.month == 2
                && climateDate.day == 29) else {
            return nil
        }
        
        var calendar =
            Calendar(identifier: .gregorian)
        
        calendar.timeZone =
            TimeZone(secondsFromGMT: 0)
            ?? .current
        
        let components = DateComponents(
            year: 2001,
            month: climateDate.month,
            day: climateDate.day
        )
        
        guard let referenceDate =
                calendar.date(from: components),
              /// month
                calendar.component(
                .month,
                from: referenceDate
              ) == climateDate.month,
              
                /// Day. Prevents an invalid date like April 31 from being normalized into May.
              
                calendar.component(
                    .day,
                    from: referenceDate
                ) == climateDate.day,
                
              let dayOfYear =
                calendar.ordinality(
                    of: .day,
                    in: .year,
                    for: referenceDate
                ) else {
            return nil
        }
        
        return dayOfYear
    }
}
