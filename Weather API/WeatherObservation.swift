import Foundation
struct WeatherObservation {
    let stationID: String
    let airTemperature: Double
    let dewPoint: Double
    let heatIndex: Double
    let relativeHumidity: Double
    let windSpeed: Double
    let pressure: Double
    let wetBulb: Double
    let coolingPotential: Double
    let condition: String
    let lastUpdated: String
}

struct NWSObservationResponse: Decodable {
    let features: [NWSObservationFeature]
    let pagination: NWSPagination?
}

struct NWSPagination: Decodable {
    let next: URL?
}

struct NWSObservationFeature: Decodable {
    let properties: NWSObservationProperties
}

struct NWSObservationProperties: Decodable {
    let timestamp: Date
    let textDescription: String?
    let temperature: NWSMeasurement
    let dewpoint: NWSMeasurement
    let relativeHumidity: NWSMeasurement
    let windSpeed: NWSMeasurement
    let barometricPressure: NWSMeasurement
}

struct NWSMeasurement: Decodable {
    let unitCode: String
    let value: Double?
}

struct TemperaturePoint: Identifiable {
    let timestamp: Date
    let temperatureFahrenheit: Double
    
    var id: Date {
        return timestamp
    }
}

struct NWSPointResponse: Decodable {
    let properties: NWSPointProperties
}

struct NWSPointProperties: Decodable {
    let forecastHourly: URL
}

struct NWSHourlyForecastResponse: Decodable {
    let properties: NWSHourlyForecastProperties
}

struct NWSHourlyForecastProperties: Decodable {
    let periods: [NWSForecastPeriod]
}

struct NWSForecastPeriod: Decodable {
    let startTime: Date
    let temperature: Double
    let temperatureUnit: String
    let windSpeed: String
    let shortForecast: String
}


