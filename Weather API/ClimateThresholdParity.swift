#if DEBUG

import Foundation

/// One scientific difference between the legacy ACIS calculator and the
/// provider-neutral calculator.


struct ClimateThresholdParityDifference: Equatable, Sendable {
    
    let metric: String
    let legacyValue: String
    let neutralValue: String
}

/// Complete comparison result for one threshold definition
///
struct ClimateThresholdParityReport: Equatable, Sendable {
    
    let label: String
    let threshold: Double
    let differences:
        [ClimateThresholdParityDifference]
    
    var passed: Bool {
        differences.isEmpty
    }
    
    var formattedText: String {
        let status =
            passed ? "PASS" : "FAIL"
        
        let heading =
            "\(status): \(label), \(threshold)°F"
        
        guard differences.isEmpty == false
        else {
            return heading
        }
        
        let detailLines =
            differences.map { difference in
                "\(difference.metric): "
                + "legacy="
                + difference.legacyValue
                + ", neutral="
                + difference.neutralValue
        }
        
        return (
            [heading] + detailLines
        )
        .joined(separator: "\n")
    }
}

enum ClimateThresholdParityChecker {
    
    private static let tolerance =
        0.000_001
    
    private static func recordDifference(
        metric: String,
        legacyValue: Int,
        neutralValue: Int,
        differences:
            inout [ClimateThresholdParityDifference]
    ) {
        
        guard legacyValue != neutralValue
        else {
            return
        }
        
        differences.append(
            ClimateThresholdParityDifference(
                metric: metric,
                legacyValue: String(legacyValue),
                neutralValue: String(neutralValue)
            )
        )
    }
    
    private static func recordDifference(
        metric: String,
        legacyValue: Double?,
        neutralValue: Double?,
        differences:
            inout [ClimateThresholdParityDifference]
    ) {
        
        switch(legacyValue, neutralValue) {
        case (nil, nil):
            return
            
        case let(
            legacyValue?,
            neutralValue?
        ):
            guard abs(legacyValue - neutralValue) > tolerance else {
                return
            }
            
            differences.append(
                ClimateThresholdParityDifference(
                    metric: metric,
                    legacyValue: String(legacyValue),
                    neutralValue: String(neutralValue)
                )
            )
            
        case let (legacyValue?, nil):
            differences.append(
                ClimateThresholdParityDifference(
                    metric: metric,
                    legacyValue: String(legacyValue),
                    neutralValue: "nil"
                )
            )
            
        case let (nil, neutralValue?):
            differences.append(
                ClimateThresholdParityDifference(
                    metric: metric,
                    legacyValue: "nil",
                    neutralValue: String(neutralValue)
                )
            )
        }
    }
    
    /// Converts a legacy ACIS Date into the same stable
    /// climatological coordinate used by the neutral calendar.
    private static func climatologicalDay(
        from date: Date?
    ) -> Double? {
        
        guard let date,
              let climateDate =
                ClimateDate(utcDate: date),
              let dayOfYear =
                ClimateCalendar
                    .climatologicalDayOfYear(
                        for: climateDate,
                        leapDayPolicy: .mapToFebruary28
                    ) else {
            return nil
        }
        
        return Double(dayOfYear)
    }
    
    /// Converts a provider-neutral ClimateDate into its stable climatological
    /// cooridnate
    private static func climatologicalDay(
        from date: ClimateDate?
    ) -> Double? {
        
        guard let date,
              let dayOfYear =
                ClimateCalendar
                    .climatologicalDayOfYear(
                        for: date,
                        leapDayPolicy: .mapToFebruary28
                    ) else {
            return nil
        }
        
        return Double(dayOfYear)
    }
    
    private static func seasonLength(
        springDay: Double?,
        fallDay: Double?
    ) -> Double? {
        
        guard let springDay,
              let fallDay,
              springDay.isFinite == true,
              fallDay.isFinite == true,
              fallDay >= springDay else {
            return nil
        }
        
        return fallDay - springDay
    }
    
    static func compare(
        label: String,
        observations:
            [ACISDailyObservation],
        startYear: Int,
        endYear: Int,
        threshold: Double,
        field: ClimateTemperatureField,
        comparison:
            ClimateThresholdComparison,
        springEventChoice:
            ClimateThresholdEventChoice,
        fallEventChoice:
            ClimateThresholdEventChoice
    ) -> ClimateThresholdParityReport {
        
        let neutralObservations =
            ACISClimateDailyObservationAdapter
                .observations(from: observations)
        
        let legacySummary =
            ACISThresholdCalculator
            .thresholdSummary(
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
        
        let neutralSummary =
            ClimateThresholdCalculator
            .thresholdSummary(
                from: neutralObservations,
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
        
        var differences:
            [ClimateThresholdParityDifference] = []
        
        recordDifference(
            metric: "observation count",
            legacyValue: observations.count,
            neutralValue:
                    neutralObservations.count,
            differences: &differences
        )
            
        recordDifference(
            metric: "season count",
            legacyValue:
                legacySummary.seasons.count,
            neutralValue:
                neutralSummary.seasons.count,
            differences: &differences
        )
            
        recordDifference(
            metric: "complete season count",
            legacyValue:
                legacySummary.completeSeasonCount,
            neutralValue:
                neutralSummary.completeSeasonCount,
            differences: &differences
        )
            
        recordDifference(
            metric: "spring event count",
            legacyValue:
                legacySummary.springEventCount,
            neutralValue:
                neutralSummary.springEventCount,
            differences: &differences
        )
            
        recordDifference(
            metric: "fall event count",
            legacyValue:
                legacySummary.fallEventCount,
            neutralValue:
                neutralSummary.fallEventCount,
            differences: &differences
        )
            
        recordDifference(
            metric: "average spring event day",
            legacyValue:
                legacySummary.averageLastSpringDay,
            neutralValue:
                neutralSummary.averageSpringEventDay,
            differences: &differences
        )
            
        recordDifference(
            metric: "average fall event day",
            legacyValue:
                legacySummary.averageFirstFallDay,
            neutralValue:
                neutralSummary.averageFallEventDay,
            differences: &differences
        )
        
        /// Catches cases where matching averages conceal
        /// different yearly event selections.
        for year in startYear...endYear {
            
            let legacySeason =
                legacySummary.seasons.first {
                    $0.year == year
                }
            
            let neutralSeason =
                neutralSummary.seasons.first {
                    $0.year == year
                }
            
            recordDifference(
                metric: "\(year) spring event day",
                legacyValue:
                    climatologicalDay(from: legacySeason?.springEventDate),
                neutralValue:
                    climatologicalDay(from: neutralSeason?.springEventDate),
                differences: &differences
            )
            
            recordDifference(
                metric: "\(year) fall event day",
                legacyValue:
                    climatologicalDay(from: legacySeason?.firstFallDate),
                neutralValue:
                    climatologicalDay(from: neutralSeason?.fallEventDate),
                differences: &differences
            )
            
        }
        
        recordDifference(
            metric: "risk point count",
            legacyValue: legacySummary
                            .thresholdRiskPoints
                            .count,
            neutralValue: neutralSummary
                            .thresholdRiskPoints
                            .count,
            differences: &differences
        )
        
        let riskPercents =
            Array(
                stride(
                    from: 10.0,
                    through: 90.0,
                    by: 10.0
                )
            )
        
        for percent in riskPercents {
            
            let legacyRiskPoint =
                legacySummary
                    .thresholdRiskPoints
                    .first {
                        $0.percent == percent
                    }
            
            let neutralRiskPoint =
                neutralSummary.riskPoint(
                    eventRiskPercent: percent
                )
            /// spring
            recordDifference(
                metric: "\(percent)% spring risk day",
                legacyValue:
                    legacyRiskPoint?
                        .springRiskDay,
                neutralValue:
                    neutralRiskPoint?
                        .springRiskDay,
                differences: &differences
            )
            
            /// fall
            recordDifference(
                metric: "\(percent)% fall risk day",
                legacyValue:
                    legacyRiskPoint?
                        .fallRiskDay,
                neutralValue:
                    neutralRiskPoint?
                        .fallRiskDay,
                differences: &differences
            )
            
            /// fall minus spring
            recordDifference(
                metric:
                    "\(percent)% season length",
                legacyValue:
                    seasonLength(
                        springDay: legacyRiskPoint?.springRiskDay,
                        fallDay: legacyRiskPoint?.fallRiskDay
                    ),
                neutralValue:
                    neutralRiskPoint?.seasonLength,
                differences: &differences
            )
        }
        
        return ClimateThresholdParityReport(
            label: label,
            threshold: threshold,
            differences: differences
        )
    }
}

#endif
