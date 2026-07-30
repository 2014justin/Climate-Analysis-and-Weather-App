import Foundation

/// Convert Celsius to Fahrenheit

enum WeatherMath {
    static func celsiusToFahrenheit(_ celsius: Double) -> Double {
        return (celsius * 9.0 / 5.0) + 32.0
    }
    
    static func fahrenheitToCelsius(
        _ fahrenheit: Double
    ) -> Double {
        return (fahrenheit - 32.0) * 5.0 / 9.0
    }

    static func kelvinToCelsius(
        _ kelvin: Double
    ) -> Double {
        return kelvin - 273.15
    }

    static func celsiusToKelvin(
        _ celsius: Double
    ) -> Double {
        return celsius + 273.15
    }
    
    /// Derives rel humidity from temperature and dew point. We can take the dew point and temperature from the atlas observations,
    /// calculate the rel humidity, and then pass it into our WeatherMath.heatIndex
    
    static func relativeHumidityPercent(
        temperatureFahrenheit: Double,
        dewPointFahrenheit: Double
    ) -> Double {
        let temperatureCelsius =
            fahrenheitToCelsius(temperatureFahrenheit)
        
        let dewPointCelsius =
            fahrenheitToCelsius(dewPointFahrenheit)
        
        
        let relativeHumidity = 100.0 * exp(
            (17.625 * dewPointCelsius) / (243.04 + dewPointCelsius)
            - (17.625 * temperatureCelsius ) / (243.04 + temperatureCelsius)
        )
        
        return min(max(relativeHumidity, 0.0), 100.0)
    }
    
    /// Calculat the Wet Bulb Temperature in Celsius, to be converted to F later
    static func wetBulbCelsius(
        temperatureCelsius: Double,
        relativeHumidity: Double
    ) -> Double {
        let temperaturePart = temperatureCelsius * atan(0.151977 * sqrt(relativeHumidity + 8.313659))
        
        let humidityPart = atan(temperatureCelsius + relativeHumidity) - atan(relativeHumidity - 1.676331)
        
        let correctionPart = 0.00391838 * pow(relativeHumidity, 1.5) * atan(0.023101 * relativeHumidity)
        
        return temperaturePart + humidityPart + correctionPart - 4.686035
    }
    /// Convert kph to mph
    
    static func kilometersPerHourToMilesPerHour(
        _ kilometersPerHour: Double
    ) -> Double {
        return kilometersPerHour * 0.621371
    }
    
    /// Convert aviation wind speed from knots to miles per hour.
    static func knotsToMilesPerHour(
        _ knots: Double
    ) -> Double {
        return knots * 1.15078
    }
    
    /// Convert Pa to inHg
    
    static func pascalsToInchesOfMercury(
        _ pascals: Double) -> Double {
        return pascals * 0.00029529983071445
    }
    
    /// Calculate standard deviation
    static func sampleStandardDeviation(_ values: [Double]) -> Double? {
        
        guard values.count >= 10 else {
            return nil
        }
        
        let mean = values.reduce(0,+) / Double(values.count)
        let sqDev = values.reduce(0.0) { total, value in
            total + pow(value - mean, 2)
        }
        
        return sqrt(sqDev / Double(values.count - 1))
    }
    
    /// Calculates centered rolling averages for indexed values.
    ///
    /// The function knows nothing about ACIS, ECCC, temperatures,
    /// or calendar dates. A caller may optionally provide a cycle
    /// length when the indices belong to a repeating domain such
    /// as the 365-day climatological year.
    static func centeredRollingAverage(
        valuesByIndex: [Int: Double],
        centeredAt centerIndices: [Int],
        radius: Int,
        minimumSampleCount: Int,
        cycleLength: Int? = nil
    ) -> [Int: Double] {
        
        guard radius >= 0,
              minimumSampleCount > 0 else {
            return [:]
        }
        
        let maximumSampleCount =
            (radius * 2) + 1
        
        let requiredSampleCount =
            min(
                minimumSampleCount,
                maximumSampleCount
            )
        
        return centerIndices.reduce(
            into: [Int: Double]()
        ) { result, centerIndex in
            
            let samples =
                (-radius...radius).compactMap {
                    offset -> Double? in
                    
                    let candidateIndex =
                        centerIndex + offset
                    
                    let resolvedIndex: Int
                    
                    if let cycleLength,
                       cycleLength > 0 {
                        
                        resolvedIndex =
                            (
                                (
                                    candidateIndex - 1
                                )
                                % cycleLength
                                + cycleLength
                            )
                            % cycleLength
                            + 1
                    } else {
                        resolvedIndex =
                            candidateIndex
                    }
                    
                    guard let value =
                            valuesByIndex[
                                resolvedIndex
                            ],
                          value.isFinite else {
                        return nil
                    }
                    
                    return value
                }
            
            guard samples.count
                    >= requiredSampleCount else {
                return
            }
            
            result[centerIndex] =
                samples.reduce(0.0, +)
                / Double(samples.count)
        }
    }
    
    /// Calculates percentile for threshold seasons.
    /// Returns a linearly-interpolated percentile, clamped to 0...100.
    /// Non-finite values are ignored
    static func percentile(
        of values: [Double],
        percentile: Double
    ) -> Double? {
        
        guard percentile.isFinite else {
            return nil
        }
        
        let sortedValues =
            values
                .filter(\.isFinite)
                .sorted()
        
        guard sortedValues.isEmpty == false else{
            return nil
        }
        
        let clampedPercentile =
            min(
                max(percentile, 0.0),
                100.00
            )
        
        let rank =
            (clampedPercentile / 100.0)
            * Double(sortedValues.count - 1)
        
        let lowerIndex =
            Int(floor(rank))
        
        let upperIndex =
            Int(ceil(rank))
        
        if lowerIndex == upperIndex {
            return sortedValues[lowerIndex]
        }
        
        let lowerValue =
            sortedValues[lowerIndex]
        
        let upperValue =
            sortedValues[upperIndex]
        
        let interpolationFraction =
            rank - Double(lowerIndex)
        
        return
            lowerValue + (upperValue - lowerValue)
            * interpolationFraction
    }
    
    static func lowerChartBound(for value: Double) -> Double {
        let roundedDown = floor(value / 5.0) * 5.0
        
        if roundedDown == value {
            return roundedDown - 5.0
        }
        return roundedDown
    }
    
    ///base 5 logic for y-axis scaling
    
    static func upperChartBound(for value: Double) -> Double {
        let roundedUp = ceil(value / 5.0) * 5.0
        
        if roundedUp == value {
            return roundedUp + 5.0
        }
        
        return roundedUp
    }
    /// Calculate the heat index from measured air Temperature and dew point.
    static func heatIndexFahrenheit(
        temperature: Double,
        relativeHumidity: Double
    ) -> Double {
        let simpleEstimate = 0.5 * (
            temperature
            + 61.0
            + ((temperature - 68.0) * 1.2)
            + (relativeHumidity * 0.094)
        )
        
        let averagedEstimate = (simpleEstimate + temperature) / 2.0
        
        guard averagedEstimate >= 80.0 else {
            return averagedEstimate
        }
        
        var heatIndex =
        -42.379
        + (2.04901523 * temperature)
        + (10.14333127 * relativeHumidity)
        - (0.22475541 * temperature * relativeHumidity)
        - (0.00683783 * temperature * temperature)
        - (0.05481717 * relativeHumidity * relativeHumidity)
        + (0.00122874 * temperature * temperature * relativeHumidity)
        + (0.00085282 * temperature * relativeHumidity * relativeHumidity)
        - (0.00000199 * temperature * temperature * relativeHumidity * relativeHumidity)
        
        /// Heat index  calculation for dry climates
        if relativeHumidity < 13.0,
           temperature >= 80.0,
           temperature <= 112.0 {
            let adjustment =
            ((13.0 - relativeHumidity) / 4.0) * sqrt((17.0 - abs(temperature - 95.0)) / 17.0)
            
            heatIndex -= adjustment
            ///use this for humid climates.
        } else if relativeHumidity > 85.0,
                  temperature >= 80.0,
                  temperature <= 87.0 {
            let adjustment =
            ((relativeHumidity - 85.0) / 10.0) * ((87.0 - temperature) / 5.0)
            
            heatIndex += adjustment
        }
        return heatIndex
    }
}
