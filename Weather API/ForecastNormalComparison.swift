/// One complete station-local forecast day compared with that date's temperature climatology.

import Foundation
nonisolated struct ForecastNormalComparison: Equatable, Sendable {
    
    let localDate: Date
    
    let forecastHighFahrenheit: Double
    let forecastLowFahrenheit: Double
    
    let normalHighFahrenheit: Double
    let normalLowFahrenheit: Double
    
    let highStandardDeviation: Double?
    let lowStandardDeviation: Double?
    
    var highDepartureFahrenheit: Double {
        forecastHighFahrenheit - normalHighFahrenheit
    }
    
    var lowDepartureFahrenheit: Double {
        forecastLowFahrenheit - normalLowFahrenheit
    }
    
    var highZScore: Double? {
        Self.zScore(
            value: forecastHighFahrenheit,
            mean: normalHighFahrenheit,
            standardDeviation: highStandardDeviation
        )
    }
    
    var lowZScore: Double? {
        Self.zScore(
            value: forecastLowFahrenheit,
            mean: normalLowFahrenheit,
            standardDeviation: lowStandardDeviation
        )
    }
    
    /// Calculate z score, i.e. standard deviation as a float.
    fileprivate static func zScore(
        value: Double,
        mean: Double,
        standardDeviation: Double?
    ) -> Double? {
        guard value.isFinite, mean.isFinite,
                let standardDeviation, standardDeviation.isFinite,
              standardDeviation > 0.0
        else {
            return nil
        }
        
        return (value - mean) / standardDeviation
    }
}
