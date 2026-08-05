/// Resolves the provider-neutral forecast sample that applies at one
/// selected playback instant.
///
/// Interval samples use a half-open range:
/// validStart is included, while validEnd is excluded.
/// This prevents adjoining samples from both claiming the same boundary.
///
///An instantaneous value applies only at its exact valid time.
///An interval applies from its start up to—but not including—its end.
///At an adjoining boundary, the new sample wins.
///If overlapping samples exist, the one with the latest start wins.
///No interpolation or provider-specific assumptions occur here.

import Foundation

nonisolated enum ForecastSampleResolver {
    
    static func sample(
        in forecast: Forecast,
        validAt instant: Date
    ) -> ForecastSample? {
        var resolvedSample: ForecastSample?
        
        for sample in forecast.samples {
            guard contains(
                instant,
                in: sample
            ) else {
                continue
            }
            
            guard let currentSample =
                    resolvedSample else {
                resolvedSample = sample
                continue
            }
            
            if sample.validStart > currentSample.validStart {
                resolvedSample = sample
            }
        }
        
        return resolvedSample
    }
    
    static func airTemperature(
        in forecast: Forecast,
        validAt instant: Date
    ) -> ForecastTemperature? {
        sample(
            in: forecast,
            validAt: instant
        )?
            .airTemperature
    }
    
    fileprivate static func contains(
        _ instant: Date,
        in sample: ForecastSample
    ) -> Bool {
        guard let validEnd = sample.validEnd else {
            return instant == sample.validStart
        }
        
        guard validEnd > sample.validStart else {
            return false
        }
        
        return instant >= sample.validStart
        && instant < validEnd
    }
}
