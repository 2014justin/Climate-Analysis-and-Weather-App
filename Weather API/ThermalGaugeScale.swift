/// Describes whether a thermal measurement falls inside the station-specific climatological guage range.

import Foundation
nonisolated enum ThermalGaugeRangeStatus: Equatable, Sendable {
    case withinRange
    case belowRange
    case aboveRange
    
}

/// One thermal measurement's resolved position on the shared gauge.
nonisolated struct ThermalGaugePlacement: Equatable, Sendable {
    let valueFahrenheit: Double
    
    /// Left endpoint is 0; right endpoint is 1
    let progress: Double
    
    let rangeStatus: ThermalGaugeRangeStatus
}

/// Converts temperatures into positions on one shared station-specific climatological scale.
nonisolated struct ThermalGaugeScale: Equatable, Sendable {
    
    let lowerBoundFahrenheit: Double
    let upperBoundFahrenheit: Double
    
    init(
        rawLowerBoundFahrenheit: Double,
        rawUpperBoundFahrenheit: Double,
        roundingIncrement: Double = 5.0,
        minimumSpan: Double = 30.0
    ) {
        let validIncrement =
        roundingIncrement.isFinite == true
        && roundingIncrement > 0.0
            ? roundingIncrement
            : 5.0
        
        let validMinimumSpan =
        minimumSpan.isFinite
        && minimumSpan > 0.0
            ? minimumSpan
            : 30.0
        
        let hasValidRawBounds =
        rawLowerBoundFahrenheit.isFinite
        && rawUpperBoundFahrenheit.isFinite
        && rawUpperBoundFahrenheit
        > rawLowerBoundFahrenheit
        
        /// If the station has legit lower bound (2 std deviations) use that. If not, -20 F is our default
        let resolvedRawLower =
        hasValidRawBounds
            ? rawLowerBoundFahrenheit
            : -20.0
        
        /// Likewise for midsommar temperatures.
        let resolvedRawUpper =
        hasValidRawBounds
            ? rawUpperBoundFahrenheit
            : 120.0
        
        var roundedLower = floor(resolvedRawLower / validIncrement) * validIncrement
        
        var roundedUpper = ceil(resolvedRawUpper / validIncrement) * validIncrement
        
        let roundedSpan = roundedUpper - roundedLower
        
        if roundedSpan < validMinimumSpan {
            let missingSpan = validMinimumSpan - roundedSpan
            
            roundedLower =
            floor(
            (roundedLower - missingSpan / 2.0)
                / validIncrement
            ) * validIncrement
            
            roundedUpper =
            ceil(
                (roundedUpper + missingSpan / 2.0)
                / validIncrement
            ) * validIncrement
        }
        
        self.lowerBoundFahrenheit = roundedLower
        
        self.upperBoundFahrenheit = roundedUpper
    }
    
    func placement(
        for valueFahrenheit: Double?
    ) -> ThermalGaugePlacement? {
        guard let valueFahrenheit,
              valueFahrenheit.isFinite else {
            return nil
        }
        
        let span = upperBoundFahrenheit - lowerBoundFahrenheit
        
        guard span > 0.0 else {
            return nil
        }
        
        let rawProgress = (valueFahrenheit - lowerBoundFahrenheit) / span
        
        let rangeStatus: ThermalGaugeRangeStatus
        
        if rawProgress < 0.0 {
            rangeStatus = .belowRange
        } else if rawProgress > 1.0 {
            rangeStatus = .aboveRange
        } else {
            rangeStatus = .withinRange
        }
        
        return ThermalGaugePlacement(
            valueFahrenheit: valueFahrenheit,
            progress: min(max(rawProgress, 0.0), 1.0),
            rangeStatus: rangeStatus
        )
    }
}
