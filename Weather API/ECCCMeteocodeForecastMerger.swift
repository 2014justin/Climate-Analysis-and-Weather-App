import Foundation

/// Identifies one complete forecast interval.
///
/// Both boundaries belong to the identity. Two readings with the same start time but
/// different end times are not necessarily the same forecast slot.
nonisolated fileprivate struct ECCCMeteocodeForecastIntervalKey: Hashable, Sendable  {
    
    let validStart: Date
    let validEnd: Date
}

/// One possible value for a merged interval.
///
/// Issuance times and product identity provide deterministic precedence when adjoining
/// Meteocode products publish the same interval.
nonisolated fileprivate struct ECCCMeteocodeForecastValueCandidate: Sendable {
    
    let valueCelsius: Double
    let issuedAt: Date
    let productID: String
}

/// Air-temp and dew point candidates accumulated independetly.
///
/// This prevents a newer air temp value from accidentally deleting a valid
/// dew point supplied by another Meteocode list.
nonisolated fileprivate struct ECCCMeteocodeForecastIntervalAccumulator: Sendable {
    
    var airTemperature: ECCCMeteocodeForecastValueCandidate?
    var dewPoint: ECCCMeteocodeForecastValueCandidate?
}

extension ECCCMeteocodeResolvedRegionForecast {
    
    /// Combines adjoining and overlapping Meteocode products into one
    /// ordered temperature timeline.
    nonisolated func mergedTemperatureIntervals() -> [ECCCMeteocodeMergedTemperatureInterval] {
        var valuesByInterval:
            [ECCCMeteocodeForecastIntervalKey: ECCCMeteocodeForecastIntervalAccumulator] = [:]
        
        for segment in segments {
            for reading in segment.forecast.airTemperatures {
                guard reading.validEnd >= reading.validStart,
                      let valueCelsius =
                        reading.representativeCelsius else {
                    continue
                }
                
                let key = ECCCMeteocodeForecastIntervalKey(
                    validStart: reading.validStart,
                    validEnd: reading.validEnd
                )
                
                let candidate =
                ECCCMeteocodeForecastValueCandidate(
                    valueCelsius: valueCelsius,
                    issuedAt: segment.issuedAt,
                    productID: segment.product.id
                )
                
                var accumulator =
                    valuesByInterval[key] ?? ECCCMeteocodeForecastIntervalAccumulator()
                
                if shouldPrefer(
                    candidate,
                    over: accumulator.airTemperature
                ) {
                    accumulator.airTemperature = candidate
                }
                
                valuesByInterval[key] = accumulator
            }
            
            for reading in segment.forecast.dewPoints {
                guard reading.validEnd >= reading.validStart,
                      let valueCelsius =
                        reading.representativeCelsius else {
                    continue
                }
                
                let key = ECCCMeteocodeForecastIntervalKey(
                    validStart: reading.validStart,
                    validEnd: reading.validEnd
                )
                
                let candidate =
                ECCCMeteocodeForecastValueCandidate(
                    valueCelsius: valueCelsius,
                    issuedAt: segment.issuedAt,
                    productID: segment.product.id
                )
                
                var accumulator =
                    valuesByInterval[key]
                    ?? ECCCMeteocodeForecastIntervalAccumulator()
                
                if shouldPrefer(
                    candidate,
                    over: accumulator.dewPoint
                ) {
                    accumulator.dewPoint = candidate
                }
                
                valuesByInterval[key] = accumulator
            }
        }
        
        return valuesByInterval
            .map { key, accumulator in
                ECCCMeteocodeMergedTemperatureInterval(
                    validStart: key.validStart,
                    validEnd: key.validEnd,
                    airTemperatureCelsius: accumulator.airTemperature?.valueCelsius,
                    dewPointCelsius: accumulator.dewPoint?.valueCelsius
                )
            }
            .filter {
                $0.airTemperatureCelsius != nil
                || $0.dewPointCelsius != nil
            }
            .sorted {
                if $0.validStart != $1.validStart {
                    return $0.validStart < $1.validStart
                }
                
                return $0.validEnd < $1.validEnd
            }
    }
    
    /// A newer bulletin wins.
    nonisolated fileprivate func shouldPrefer(
        _ candidate: ECCCMeteocodeForecastValueCandidate,
        over existing: ECCCMeteocodeForecastValueCandidate?
    ) -> Bool {
        guard let existing else {
            return true
        }
        
        if candidate.issuedAt != existing.issuedAt {
            return candidate.issuedAt > existing.issuedAt
        }
        
        return candidate.productID > existing.productID
    }
}
