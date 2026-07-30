import Foundation

/// Translates the provider-neautral forecast model into the data structures
/// currently consumed by the dashboard
///
/// This adapter contains no NWS, ECC, or country-specific behavior.
///
/// NWS/ECCC/future provider -> Provider-neutral forecast -> Dashboard Forecast Adapter
/// -> TemperaturePoint and dashboard.

enum DashboardForecastAdapter {
    static func temperaturePoints(
        from forecast: Forecast?
    ) -> [TemperaturePoint] {
        guard let forecast else {
            return []
        }
        
        return forecast.samples.compactMap {
            sample -> TemperaturePoint? in
            
            guard let airTemperature =
                    sample.airTemperature else {
                return nil
            }
            
            let temperatureFahrenheit =
                airTemperature.fahrenheit
            
            let dewPointFahrenheit =
                sample.dewPoint?.fahrenheit
            
            let heatIndexFahrenheit: Double?
            
            if let relativeHumidity =
                sample.resolvedRelativeHumidityPercent {
                heatIndexFahrenheit =
                    WeatherMath.heatIndexFahrenheit(
                        temperature: temperatureFahrenheit,
                        relativeHumidity: relativeHumidity
                    )
            } else {
                heatIndexFahrenheit = nil
            }
            
            return TemperaturePoint(
                timestamp: sample.validStart,
                temperatureFahrenheit: temperatureFahrenheit,
                dewPointFahrenheit: dewPointFahrenheit,
                heatIndexFahrenheit: heatIndexFahrenheit
            )
        }
        .sorted {
            $0.timestamp < $1.timestamp
        }
    }
    
    static func firstConditionText(
        from forecast: Forecast?
    ) -> String? {
        forecast?
            .samples
            .sorted {
                $0.validStart < $1.validStart
            }
            .lazy
            .compactMap { sample in
                sample.conditionText?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .first {
                $0.isEmpty == false
            }
    }
}
