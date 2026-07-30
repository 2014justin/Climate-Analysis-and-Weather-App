import Foundation

enum NWSForecastProviderError: LocalizedError, Sendable {
    case unsupportedTemperatureUnit(String)
    case unsupportedMeasurementUnit(String)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedTemperatureUnit(let unit):
            return "NWS returned an unsupported temperature unit: \(unit)."
            
        case .unsupportedMeasurementUnit(let unit):
            return "NWS returned an unsupported measurement unit: \(unit)"
        }
    }
}

struct NWSForecastProvider: WeatherForecastProviding {
    let providerID: ForecastProviderID = .nwsHourly
    
    nonisolated init() {}
    
    func forecast(
        for request: ForecastRequest
    ) async throws -> Forecast {
        let response = try await WeatherService().fetchHourlyForecast(
            latitude: request.latitude,
            longitude: request.longitude
        )
        
        let samples = try response.properties.periods.map { period in
            let condition = period.shortForecast
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            return ForecastSample(
                validStart: period.startTime,
                validEnd: period.endTime,
                timeSemantics: .intervalRepresentative,
                airTemperature: try Self.temperature(
                    value: period.temperature,
                    unit: period.temperatureUnit
                ),
                dewPoint: try Self.temperature(
                    from: period.dewpoint
                ),
                reportedRelativeHumidityPercent: period.relativeHumidity?.value,
                conditionText: condition.isEmpty ? nil : condition
            )
        }
            .sorted {
                $0.validStart < $1.validStart
            }
        
        return Forecast(
            metadata: ForecastMetadata(
                providerID: providerID,
                productName: "NWS Hourly Forecast",
                productClass: .officialForecast,
                spatialTarget: .point(latitude: request.latitude, longitude: request.longitude),
                issuedAt: response.properties.generatedAt ?? response.properties.updateTime,
                modelRunAt: nil,
                fetchedAt: Date(),
                nativeCadenceSeconds: 60.00 * 60.00,
                attribution: "National Weather Service"
            ),
            samples: samples
        )
    }
    
    fileprivate static func temperature(
        value: Double,
        unit: String
    ) throws -> ForecastTemperature {
        switch unit
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased() {
            
        case "F":
            return ForecastTemperature(
                fahrenheit: value
            )
            
        case "C":
            return ForecastTemperature(
                celsius: value
            )
            
        case "K":
            return ForecastTemperature(
                kelvin: value
            )
            
        default:
            throw NWSForecastProviderError
                .unsupportedTemperatureUnit(unit)
        }
    }
    
    fileprivate static func temperature(
        from measurement: NWSMeasurement?
    ) throws -> ForecastTemperature? {
        guard let measurement,
              let value = measurement.value else {
            return nil
        }
        
        switch measurement.unitCode {
        case "wmoUnit:degC":
            return ForecastTemperature(celsius: value)
            
        case "wmoUnit:degF":
            return ForecastTemperature(fahrenheit: value)
            
        case "wmoUnit:K":
            return ForecastTemperature(kelvin: value)
            
        default:
            throw NWSForecastProviderError.unsupportedMeasurementUnit(measurement.unitCode)
        }
    }
}
