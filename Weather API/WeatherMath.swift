import Foundation

/// Convert Celsius to Fahrenheit

enum WeatherMath {
    static func celsiusToFahrenheit(_ celsius: Double) -> Double {
        return (celsius * 9.0 / 5.0) + 32.0
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
    /// Convert Pa to inHg
    
    static func pascalsToInchesOfMercury( _ pascals: Double) -> Double {
        return pascals * 0.00029529983071445
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
        /// Heat index  calculation
        if relativeHumidity < 13.0,
           temperature >= 80.0,
           temperature <= 112.0 {
            let adjustment =
            ((13.0 - relativeHumidity) / 4.0) * sqrt((17.0 - abs(temperature - 95.0)) / 17.0
            )
            
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
