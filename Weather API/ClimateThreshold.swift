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

struct ClimateThresholdDefinition: Codable, Equatable, Hashable, Sendable {
    
    let threshold: Double
    let field: ClimateTemperatureField
    let comparison: ClimateThresholdComparison
    let springEventChoice: ClimateThresholdEventChoice
    let fallEventChoice: ClimateThresholdEventChoice
}

enum ClimateThresholdFamily: String, CaseIterable, Codable, Hashable, Sendable {
    
    case coldNights
    case warmAfternoon
    case warmAfternoonLockIn
    case mildNights
    
    var thresholdPresets: [Double] {
        
        switch self {
            
        case .coldNights:
            return [0, 10, 20, 24, 28, 32, 36, 40, 45, 50, 55, 60]
            
        case .warmAfternoon:
            return [50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100]
            
        case .warmAfternoonLockIn:
            return [32, 36, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85]
            
        case .mildNights:
            return [28, 32, 36, 40, 45, 50, 55, 60, 70]
        }
    }
    
    var field: ClimateTemperatureField {
        switch self {
            
        case .coldNights, .mildNights:
            return .minimum
            
        case .warmAfternoon, .warmAfternoonLockIn:
            return .maximum
        }
    }
    
    var comparison: ClimateThresholdComparison {
        switch self {
            
        case .coldNights:
            return .lessThanOrEqual
            
        case .warmAfternoon, .mildNights:
            return .greaterThanOrEqual
            
        case .warmAfternoonLockIn:
            return .lessThan
        }
    }
    
    var springEventChoice: ClimateThresholdEventChoice {
        switch self {
            
        case .coldNights, .warmAfternoonLockIn:
            return .last
            
        case .warmAfternoon, .mildNights:
            return .first
        }
    }
    
    var fallEventChoice: ClimateThresholdEventChoice {
        switch self {
            
        case .coldNights, .warmAfternoonLockIn:
            return .first
            
        case .warmAfternoon, .mildNights:
            return .last
        }
    }
    
    var definitions: [ClimateThresholdDefinition] {
        thresholdPresets.map { threshold in
            ClimateThresholdDefinition(
                threshold: threshold,
                field: field,
                comparison: comparison,
                springEventChoice: springEventChoice,
                fallEventChoice: fallEventChoice
            )
        }
    }
}

enum ClimateThresholdCatalog {
    
    static let standardDefinitions:
        [ClimateThresholdDefinition] =
            ClimateThresholdFamily.allCases.flatMap { family in
                family.definitions
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
    
    /// Generalized season percentile.
    var seasonLength: Double? {
        guard let springRiskDay,
              let fallRiskDay,
              fallRiskDay >= springRiskDay else {
            return nil
        }
        
        return fallRiskDay - springRiskDay
    }
    
    var boundaryConfidencePercent: Double {
        100.00 - percent
    }
    
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
    
    let averageSpringEventDay: Double?
    let averageFallEventDay: Double?
    
    let thresholdRiskPoints:
        [ClimateThresholdRiskPoint]
}

extension ClimateThresholdSummary {
    
    /// Reconstructs the scientific definition that produced this stored summary.
    var definition: ClimateThresholdDefinition {
        ClimateThresholdDefinition(
            threshold: threshold,
            field: field,
            comparison: comparison,
            springEventChoice: springEventChoice,
            fallEventChoice: fallEventChoice
        )
    }
    
    private var springEventDates:
        [ClimateDate] {
        
        seasons.compactMap {
            $0.springEventDate
        }
    }
    
    private var fallEventDates:
        [ClimateDate] {
        
        seasons.compactMap {
            $0.fallEventDate
        }
    }
    
    /// Finds an already-calculated risk point without recalculating its percentiles.
    func riskPoint(
        eventRiskPercent: Double
    ) -> ClimateThresholdRiskPoint? {
        
        guard eventRiskPercent.isFinite else {
            return nil
        }
        
        return thresholdRiskPoints.first {
            $0.percent == eventRiskPercent
        }
    }
    
    var earliestSpringEventDay: Double? {
        ClimateThresholdCalculator
            .percentileDayOfYear(
                from: springEventDates,
                percentile: 0.0
            )
    }
    
    var latestSpringEventDay: Double? {
        ClimateThresholdCalculator
            .percentileDayOfYear(
                from: springEventDates,
                percentile: 100.0
            )
    }
    
    var earliestFallEventDay: Double? {
        ClimateThresholdCalculator
            .percentileDayOfYear(
                from: fallEventDates,
                percentile: 0.0
            )
    }
    
    var latestFallEventDay: Double? {
        ClimateThresholdCalculator
            .percentileDayOfYear(
                from: fallEventDates,
                percentile: 100.00
            )
    }
    
    var medianSpringEventDay: Double? {
        riskPoint(
            eventRiskPercent: 50.0
        )?.springRiskDay
    }
    
    var medianFallEventDay: Double? {
        riskPoint(
            eventRiskPercent: 50.0
        )?.fallRiskDay
    }
    
    /// A 20% chance of the spring event occuring afterwards
    /// means 80% boundary confidence.
    var eightyPercentConfidenceSpringBoundaryDay:
    Double? {
        
        riskPoint(
            eventRiskPercent: 20.0
        )?.springRiskDay
    }
    
    /// 10% chance of the spring event occuring afterward
    /// means 90% boundary confidence.
    
    var ninetyPercentConfidenceSpringBoundaryDay:
    Double? {
        
        riskPoint(
            eventRiskPercent: 10.0
        )?.springRiskDay
    }
    
    /// A 10% chance of a fall event occuring beforehand means
    /// 90% boundary confidence.
    var ninetyPercentConfidenceFallBoundaryDay:
    Double? {
        
        riskPoint(
            eventRiskPercent: 10.0
        )?.fallRiskDay
    }
    
    /// Determines whether this summary represents a genuine spring
    /// temperature lock-in instead of an apparent boundary caused by
    /// the July 31 spring/fall division.
    ///
    /// D50 is the median spring boundary.
    /// D80 is the boundary with 80% confidence.
    /// D90 is the boundary with 90% confidence.
    
    func isMeaningfulSpringLockIn(
        using policy:
            ClimateSpringLockInPolicy
    ) -> Bool {
        let representsBelowThresholdBoundary =
        comparison == .lessThan ||
        comparison == .lessThanOrEqual
        
        guard representsBelowThresholdBoundary,
              springEventChoice == .last,
              let d50 = medianSpringEventDay,
              let d80 =
                eightyPercentConfidenceSpringBoundaryDay,
              let d90 =
                ninetyPercentConfidenceSpringBoundaryDay,
              d50.isFinite == true,
              d80.isFinite == true,
              d90.isFinite == true,
              d80 >= d50,
              d90 >= d80,
              policy.latestMedianDay.isFinite == true,
              policy.maximumMedianToEightyConfidenceSpan.isFinite == true,
              policy.maximumMedianToEightyConfidenceSpan >= 0.0,
              policy.latestNinetyConfidenceDay.isFinite == true
        else {
            return false
        }
        
        let medianToEightyConfidenceSpan =
        d80 - d50
        
        /// Daily-minimum cold events naturally have wider interannual tails. The rapid-transition
        /// requirement reserved for meximum-temperature afternoon lock-in
        let requiresCompactTransition =
            field == .maximum
        
        let satisfiesTransitionSpan =
            requiresCompactTransition == false ||
            medianToEightyConfidenceSpan
                <= policy.maximumMedianToEightyConfidenceSpan
        
        return d50 <= policy.latestMedianDay
            && satisfiesTransitionSpan
            && d90 <= policy.latestNinetyConfidenceDay
    }
    
    var hasMeaningfulSpringLockIn: Bool {
        let policy:
            ClimateSpringLockInPolicy
        
        switch field {
        case .minimum:
            policy = .coldNight
            
        case .maximum:
            policy = .warmAfternoon
        }
        
        return isMeaningfulSpringLockIn(using: policy)
    }
}

/// Climate spring lock-in policy. Some locations have true season-bounding warming
/// into July. This struct tries to distinguish between meaningful spring warming
/// seasons, and lock-ins that seem significant at first but are really artifical, bouncing
/// off the Jul 31 spring/fall boundary. For example, if you try to find a '50 F and above
/// season' for Stanley ID (morning low lock-in), you will see the graph of probability
/// sharply converge towards 0% at the end of the month. There is no true lock in
/// season there because Stanley can have a morning low of 50 or lower any time of the
/// year due to its high-elevation climate. This is the problem the struct tries to solve.
/// It requires D50 to occur no later than July 4, but also D80 no more than 14 days after D50
/// This means the spring warming signal must be tight, the derivative relatively high showing rapid
/// warming. We also require D90 to occur no later than July 20.

struct ClimateSpringLockInPolicy: Codable, Equatable, Hashable, Sendable {
    
    /// D50 must occur no later than July 4.
    let latestMedianDay: Double
    
    /// D80 may occur no more than 14 days after D50; tight spread = rapid climatological warming.
    let maximumMedianToEightyConfidenceSpan: Double
    
    /// D90 must occur no later July 20
    let latestNinetyConfidenceDay: Double
    
    /// Maximum-temperature afternoon lock-ins retain the more conservative July 29 D90 cutoff
    static let warmAfternoon =
    ClimateSpringLockInPolicy(
        latestMedianDay: 185.0,
        maximumMedianToEightyConfidenceSpan: 16.0,
        latestNinetyConfidenceDay: 201.0
    )
    
    /// Daily-minimum cold-night seasons permit their wider
    /// interannual tail through July 25. This makes sense as T min responds
    /// more gradually due to thermal memory. By July 25, the memory should have established.
    /// If not, we reject.
    static let coldNight =
    ClimateSpringLockInPolicy(
        latestMedianDay: 185.0,
        maximumMedianToEightyConfidenceSpan: 16.0,
        latestNinetyConfidenceDay: 206.0
    )
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
    
    /// Converts threshold-event dates into stable climatological day numbers.
    /// Remove duplicated conversion code from averageDayOfYear(...) & percentileDayOfYear(...)
    private static func climatologicalDayValues(
        from dates: [ClimateDate]
    ) -> [Double] {
        
        dates.compactMap { date in
            guard let dayOfYear =
                    ClimateCalendar
                    .climatologicalDayOfYear(
                        for: date,
                        leapDayPolicy: .mapToFebruary28
                    ) else {
                return nil
            }
            
            return Double(dayOfYear)
        }
    }
    
    /// Calculates the arithmetic mean of a collection
    /// of spring-only or fall-only event dates.
    static func averageDayOfYear(
        from dates: [ClimateDate]
    ) -> Double? {
        
        let dayValues =
            climatologicalDayValues(from: dates)
        
        guard dayValues.isEmpty == false else {
            return nil
        }
        
        let total =
            dayValues.reduce(0.0,+)
        
        return total / Double(dayValues.count)
    }
    
    /// Calculates a linearly-interpolated percentile from threshold-event dates.
    static func percentileDayOfYear(
        from dates: [ClimateDate],
        percentile: Double
    ) -> Double? {
        
        let dayValues =
            climatologicalDayValues(from: dates)
        
        return WeatherMath.percentile(
            of: dayValues,
            percentile: percentile
        )
    }
    
    /// Returns the spring date having the requested probability
    /// of an event occuring afterward.
    ///
    /// For a 90% chance of a freeze occurring after a spring date, we need the early 10th-percentile
    /// date.
    static func springThresholdRiskDay(
        from seasons: [ClimateThresholdSeason],
        percentChanceAfter: Double
    ) -> Double? {
        
        let springDates =
            seasons.compactMap {
                $0.springEventDate
        }
        
        let percentile =
            100 - percentChanceAfter
        
        return percentileDayOfYear(from: springDates, percentile: percentile)
    }
    
    /// Returns the fall date having the requested probability
    /// of an event occuring beforehand.
    /// A 90% chance of a freeze occuring on or before a fall date directly uses the 90th percentile.
    static func fallThresholdRiskDay(
        from seasons: [ClimateThresholdSeason],
        percentChanceBefore: Double
    ) -> Double? {
        
        let fallDates =
            seasons.compactMap {
                $0.fallEventDate
            }
        
        return percentileDayOfYear(
            from: fallDates,
            percentile: percentChanceBefore
        )
    }
    
    /// Calculates the interval between spring and fall
    /// boundaries at a selected event-risk percentage.
    ///
    /// A 10% event risk corresponds to 90% confidence
    /// at each individual boundary.
    ///
    /// A 10% spring risk date means only a 10% chance of another
    /// freeze, for example, afterward: 90% boundary confidence.
    ///
    /// A 10% fall risk date means only a 10% chance of freezing before
    /// then: 90% boundary confidence.
    ///
    /// Therefore, the conservative tomato-growing window connects the 10%
    /// spring-risk date to the 10% fall-risk date.
    ///
    /// We wouldn't want to connec tthe two 90% risk dates, as this is the widest,
    /// riskiest window.
    
    static func riskAdjustedSeasonLength(
        from seasons: [ClimateThresholdSeason],
        eventRiskPercent: Double
    ) -> Double? {
        
        guard eventRiskPercent.isFinite,
                (0.0...100.0).contains(
                    eventRiskPercent
                ) else {
            return nil
        }
        
        guard let springRiskDay =
                springThresholdRiskDay(
                    from: seasons,
                    percentChanceAfter: eventRiskPercent
                ),
              let fallRiskDay =
                fallThresholdRiskDay(
                    from: seasons,
                    percentChanceBefore: eventRiskPercent
                ),
              fallRiskDay >= springRiskDay else {
            return nil
        }
        return fallRiskDay - springRiskDay
    }
    
    /// Builds a complete provider-neutral summary for one temperature and
    /// event definition
    
    static func thresholdSummary(
        from observations:
            [ClimateDailyObservation],
        startYear: Int,
        endYear: Int,
        threshold: Double,
        field:
            ClimateTemperatureField = .minimum,
        comparison:
            ClimateThresholdComparison = .lessThanOrEqual,
        springEventChoice:
            ClimateThresholdEventChoice = .last,
        fallEventChoice:
            ClimateThresholdEventChoice = .first,
        eventRiskPercents: [Double] = [
            10.0,
            20.0,
            30.0,
            40.0,
            50.0,
            60.0,
            70.0,
            80.0,
            90
        ]
    ) -> ClimateThresholdSummary {
        
        let seasons =
            thresholdSeasons(
                from: observations,
                startYear: startYear,
                endYear: endYear,
                threshold: threshold,
                field: field,
                comparison: comparison,
                springEventChoice:
                    springEventChoice,
                fallEventChoice:
                    fallEventChoice
            )
        
        let springDates =
            seasons.compactMap {
                $0.springEventDate
            }
        
        let fallDates =
            seasons.compactMap {
                $0.fallEventDate
            }
        
        let completeSeasonCount =
            seasons.filter { season in
                season.springEventDate != nil
                    && season.fallEventDate != nil
            
            }
            .count
        
        let validRiskPercents =
            Array(
                Set(
                    eventRiskPercents.filter {
                        percent in
                        
                        percent.isFinite
                        && (0.0...100.0)
                            .contains(percent)
                    }
                )
            )
            .sorted()
        
        let thresholdRiskPoints =
            validRiskPercents.map { percent in
                ClimateThresholdRiskPoint(
                    percent: percent,
                    springRiskDay: springThresholdRiskDay(
                        from: seasons,
                        percentChanceAfter: percent
                    ),
                    fallRiskDay: fallThresholdRiskDay(
                        from: seasons,
                        percentChanceBefore: percent
                    )
            )
        }
        
        return ClimateThresholdSummary(
            startYear:
                startYear,
            endYear:
                endYear,
            threshold:
                threshold,
            field:
                field,
            comparison:
                comparison,
            springEventChoice:
                springEventChoice,
            fallEventChoice:
                fallEventChoice,
            seasons:
                seasons,
            completeSeasonCount:
                completeSeasonCount,
            springEventCount:
                springDates.count,
            fallEventCount:
                fallDates.count,
            averageSpringEventDay:
                averageDayOfYear(from: springDates),
            averageFallEventDay:
                averageDayOfYear(from: fallDates),
            thresholdRiskPoints:
                thresholdRiskPoints
        )
    }
    
    
    /// Builds a summary from one catalog definition.
    static func thresholdSummary(
        from observations: [ClimateDailyObservation],
        startYear: Int,
        endYear: Int,
        definition: ClimateThresholdDefinition
    ) -> ClimateThresholdSummary {
        
        thresholdSummary(
            from: observations,
            startYear: startYear,
            endYear: endYear,
            threshold: definition.threshold,
            field: definition.field,
            comparison: definition.comparison,
            springEventChoice: definition.springEventChoice,
            fallEventChoice: definition.fallEventChoice
        )
    }
    
    /// Builds every standard threshold summary that should be stored with a generated climate
    /// profile.
    static func standardThresholdSummaries(
        from observations: [ClimateDailyObservation],
        startYear: Int,
        endYear: Int
    ) -> [ClimateThresholdSummary] {
        
        ClimateThresholdCatalog
            .standardDefinitions
            .map { definition in
                thresholdSummary(
                    from: observations,
                    startYear: startYear,
                    endYear: endYear,
                    definition: definition
                )
            }
    }
}
