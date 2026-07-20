/// Provider-agnostic threshold system. Works for the following thresholds of interest
///---------------
/// Last Daily Minima ("morning lows") below threshold:
/// LAST SPRING DATE: The spring date (up to Jul 31) by which in 50% of years subsequent mornings will remain above
/// the threshold temperature in question. The most important one is the last spring freeze. The calculator also
/// works for last spring morning of 40 F or  below, for example
///
/// FIRST FALL DATE: The fall date (Aug 1 onwards) by which in 50% of years, the daily minima will have reached
/// that value by then. In other words, 50% of a morning this cold by this date. The most important is first fall freeze.
/// It also works for other thresholds like 28 or 36.
///
///----------------
/// First Daily Minima ("morning lows") above threshold:
/// FIRST SPRING DATE: The spring date (up to Jul 31) by which in 50% of years, there will be a morning at least this warm.
/// For example, one threshold of interest for especially cold climates might be the median date of the first spring morning
/// at or above the freezing mark (32 F). This is NOT the avg last freeze, it is simply the avg first occurance
/// of a 'balmy' morning
///
/// LAST FALL DATE:
/// The fall date (Aug 1 -> Dec 31) by which in 50% of years, mornings will generally fail to maintain this threshold value
/// of warmth. For example, Fairbanks AK the 50% date for 32 F in the fall is Oct 7. This means after Oct 7, the qualifying
/// warm morning has already occurred in 50% years.
///
///-------------------
/// First Daily Maximum ("afternoon high") above threshold:
/// FIRST SPRING DATE: The spring date (up to Jul 31) by which, in a median year, the location will experience an afternoon
/// temperature at or above this temperature. This is important for cold continental climates, where the first 50 deg F
/// afternoon is an event. Fairbanks AK usually will have a 50 degree day by April 5. This does not mean 50 deg F
/// afternoons are 'locked-in' yet.
///
/// LAST FALL DATE: The fall date (Aug 1 -> Dec 31) by which, in a median year, the location will fail to break the high
/// temperature in question. For example, in 50% of years, 50 deg F afternoons in Fairbanks are DONE by October 5
/// until the following spring.
///
///------------
/// Daily Maximum ("afternoon high") 'lock-in' temperature:
/// FIRST SPRING DATE: The spring date (up to Jul 31) by which, in a median year, the location will continually exceed the
/// afternoon temperature in question. It is a true sign of summer's advance because after this date, afternoons make it
/// to at least this warm. For example, the 50% date for 50 deg F lock-in afternoons for Fairbanks AK is approximately
/// May 5. This means, in a median year, every afternoon after May 5 should make it to at least 50 deg F until
/// intense fall cooling hits.
///
/// LAST FALL DATE: The fall date (Aug 1 -> Dec 31) by which, in a median year, the location's 'warm afternoon'
/// lock-in threshold will expire. It is a sign of winter knocking because after this dates, afternoons are NOT
/// guaranteed to make it at least this warm. For example, the 50% date for 50 deg in Fairbanks AK is
/// Sep 16. This means after Sep 16, the frequency of afternoons making or exceeding 50 F gets exceedingly
/// rare until winter takes a firm grasp.
///
/// For a 50 F afternoon lock-in:
/// field = .maximum
/// springEventChoice = .last
/// fallEventChoice = .first
/// comparison = .lessThan

import Foundation

enum ClimateTemperatureField: String, Codable, Hashable, Sendable {
    
    case minimum
    
    case maximum
    
    
    /// The calculator doesn't care whether it's Tmin or Tmax.
    func value(
        from observation: ClimateDailyObservation
    ) -> Double? {
        switch self {
        case .minimum:
            return observation
                .minimumTemperature
                .usableFahrenheit
            
        case .maximum:
            return observation
                .maximumTemperature
                .usableFahrenheit
        }
    }
}

enum ClimateThresholdComparison: String , Codable, Hashable, Sendable {
    
    case lessThan
    case lessThanOrEqual
    case greaterThan
    case greaterThanOrEqual
    
    func matches(
        value: Double,
        threshold: Double
    ) -> Bool {
        switch self {
            
        case .lessThan:
            return value < threshold
            
        case .lessThanOrEqual:
            return value <= threshold
            
        case .greaterThan:
            return value > threshold
            
        case .greaterThanOrEqual:
            return value >= threshold
        }
    }
}

enum ClimateThresholdEventChoice: String, Codable, Hashable, Sendable {
    case first
    case last
    
    
    func date(
        from dates: [ClimateDate]
    ) -> ClimateDate? {
        switch self {
        case .first:
            return dates.min()
            
        case .last:
            return dates.max()
        }
    }
}

struct ClimateThresholdSeason: Identifiable, Codable, Equatable, Hashable, Sendable {
    
    let year: Int
    let springEventDate: ClimateDate?
    let fallEventDate: ClimateDate?
    
    var id: Int {
        year
    }
}

struct ClimateThresholdRiskPoint: Identifiable, Codable, Equatable, Hashable, Sendable {
    
    let percent: Double
    let springRiskDay: Double?
    let fallRiskDay: Double?
    
    var id: Double {
        percent
    }
}

struct ClimateThresholdSummary: Codable, Equatable, Hashable, Sendable {
    
    let startYear: Int
    let endYear: Int
    let threshold: Double
    
    let field: ClimateTemperatureField
    let comparison: ClimateThresholdComparison
    
    let springEventChoice:
        ClimateThresholdEventChoice
    let fallEventChoice:
        ClimateThresholdEventChoice
    
    let seasons: [ClimateThresholdSeason]
    let completeSeasonCount: Int
    let springEventCount: Int
    let fallEventCount: Int
    
    let averageLastSpringDay: Double?
    let averageFirstFallDay: Double?
    
    let averageAboveThresholdSeasonLength: Double?
    
    let thresholdRiskPoints:
        [ClimateThresholdRiskPoint]
}

/// Find one year's spring and fall threshold boundaries.

enum ClimateThresholdCalculator {
    
    static func thresholdSeason(
        from observations:
            [ClimateDailyObservation],
        year: Int,
        threshold: Double,
        field:
            ClimateTemperatureField = .minimum,
        comparison:
            ClimateThresholdComparison =
                .lessThanOrEqual,
        springEventChoice:
            ClimateThresholdEventChoice = .last,
        fallEventChoice:
            ClimateThresholdEventChoice = .first
    ) -> ClimateThresholdSeason {
        
        let springDates =
            observations.compactMap {
                observation -> ClimateDate? in
                
                let date =
                    observation.localDate
                
                /// Define the midsommar crossover point as August 1. This is because in the vast
                /// majority of locations, thermal midsommar will have already been realized
                /// by August 1.
                
                guard date.year == year,
                      date.month < 8,
                      let temperature =
                        field.value(
                            from: observation
                        ),
                      temperature.isFinite,
                      comparison.matches(
                        value: temperature,
                        threshold: threshold
                      ) else {
                    return nil
                }
                
                return date
            }
        
        let fallDates =
            observations.compactMap {
                observation -> ClimateDate? in
                
                let date =
                    observation.localDate
                
                /// Define 'fall' as Aug 1 -> Dec 31
                guard date.year == year,
                      date.month >= 8,
                      let temperature =
                        field.value(
                            from: observation
                        ),
                      temperature.isFinite,
                      comparison.matches(
                        value: temperature,
                        threshold: threshold
                      ) else {
                    return nil
                }
                
                return date
            }
        
        return ClimateThresholdSeason(
            year: year,
            springEventDate:
                springEventChoice.date(from: springDates),
            fallEventDate:
                fallEventChoice.date(from: fallDates)
        )
    }
    
    /// Calculates one threshold season for every year in the requested climate period.
    
    static func thresholdSeasons(
        from observations:
            [ClimateDailyObservation],
        startYear: Int,
        endYear: Int,
        threshold: Double,
        field:
            ClimateTemperatureField =
                .minimum,
        comparison:
            ClimateThresholdComparison =
                .lessThanOrEqual,
        springEventChoice:
            ClimateThresholdEventChoice =
                .last,
        fallEventChoice:
            ClimateThresholdEventChoice =
                .first
    ) -> [ClimateThresholdSeason] {
        
        guard startYear <= endYear else {
            return []
        }
        
        return (startYear...endYear).map { year in
            thresholdSeason(
                from: observations,
                year: year,
                threshold: threshold,
                field: field,
                comparison: comparison,
                springEventChoice: springEventChoice,
                fallEventChoice: fallEventChoice
            )
        }
    }
}
