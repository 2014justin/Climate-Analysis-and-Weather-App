import Foundation

/// Stable identifier for any forecast provider.
///
/// This is a struct instead of an enum so future providers can add identifier
/// without modifying one enormous central enum.

struct ForecastProviderID: RawRepresentable, Hashable, Codable, Sendable {
    
    let rawValue: String
    
    init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    static let nwsHourly = ForecastProviderID(rawValue: "nws.hourly")
    
    static let ecccMeteocode = ForecastProviderID(rawValue: "eccc.meteocode")
}

/// Describes whether a forecast is an official curated product or direct
/// numerical-model guidance.
enum ForecastProductClass: String, Hashable, Codable, Sendable {
    case officialForecast
    case rawNumericalModel
}

/// The geographic object represented by a provider's forecast.
///
/// Providers do not all describe the same kind of location:
/// NWS can provide a point forecast, Meteocode represents a region,
/// DWD MOSMIX represents a station, and other products use grid cells.
///
enum ForecastSpatialTarget: Hashable, Codable, Sendable {
    
    case point(
        latitude: Double,
        longitude: Double
    )
    
    case station(
        identifier: String,
        latitude: Double?,
        longitude: Double?
    )
    
    case gridCell(
        identifier: String?,
        centerLatitude: Double,
        centerLongitude: Double,
        resolutionKilometers: Double?
    )
    
    case region(
        identifier: String,
        name: String?
    )
}

/// Describes what time interval a forecast value represents
///
enum ForecastTimeSemantics: String, Hashable, Codable, Sendable {
    
    case instantaneous
    /// A value representing a forecast interval without claiming that it is
    /// mathematically the interval's arithmetic mean.
    case intervalRepresentative
    case intervalMean
    case intervalMinimum
    case intervalMaximum
    case accumulation
    case categoricalInterval
}

/// Canonical temperature representation used by the  forecast layer.
///
/// Providers may send Fahrenheit, Calsius, or Kelvin. They are converted
/// here once instead of scattering conversions throughout the application.
///
struct ForecastTemperature: Hashable, Codable, Sendable {
    
    let celsius: Double
    
    init(celsius: Double) {
        self.celsius = celsius
    }
    
    init(fahrenheit: Double) {
        self.celsius = WeatherMath.fahrenheitToCelsius(fahrenheit)
    }
    
    init(kelvin: Double) {
        self.celsius = WeatherMath.kelvinToCelsius(kelvin)
    }
    
    var fahrenheit: Double {
        WeatherMath.celsiusToFahrenheit(celsius)
    }
    
    var kelvin: Double {
        WeatherMath.celsiusToKelvin(celsius)
    }
}

/// Everything a provider needs to resolve and fetch a forecast.
struct ForecastRequest: Hashable, Sendable {
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String
    let countryCode: String
    let stationIdentifier: String?
    let preferredProviderID: ForecastProviderID?
    
    init(
        latitude: Double,
        longitude: Double,
        timeZoneIdentifier: String,
        countryCode: String,
        stationIdentifier: String? = nil,
        preferredProviderID: ForecastProviderID? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZoneIdentifier
        self.countryCode = countryCode.uppercased()
        self.stationIdentifier = stationIdentifier
        self.preferredProviderID = preferredProviderID
    }
}

/// One normalized forecast value.
///
/// 'validEnd' remains nil for instantaneous values. Interval-based products
/// can preserve their complete native time meaning.
struct ForecastSample: Hashable, Codable, Sendable {
    let validStart: Date
    let validEnd: Date?
    let timeSemantics: ForecastTimeSemantics
    let airTemperature: ForecastTemperature?
    let dewPoint: ForecastTemperature?
    let reportedRelativeHumidityPercent: Double?
    let conditionText: String?
    
    var resolvedRelativeHumidityPercent: Double? {
        if let reportedRelativeHumidityPercent,
           reportedRelativeHumidityPercent.isFinite == true {
            return min(
                max(
                    reportedRelativeHumidityPercent, 0.0
                ),
                100.0
            )
        }
        
        guard let airTemperature,
              let dewPoint else {
            return nil
        }
        
        return WeatherMath.relativeHumidityPercent(
            temperatureFahrenheit: airTemperature.fahrenheit,
            dewPointFahrenheit: dewPoint.fahrenheit
        )
    }
}

/// Provenance and scientific meaning for a returned forecast series.
struct ForecastMetadata: Hashable, Codable, Sendable {
    
    let providerID: ForecastProviderID
    let productName: String
    let productClass: ForecastProductClass
    let spatialTarget: ForecastSpatialTarget
    let issuedAt: Date?
    let modelRunAt: Date?
    let fetchedAt: Date
    let nativeCadenceSeconds: TimeInterval?
    let attribution: String
}

/// The complete provider-neutral forecast returned to the application.

struct Forecast: Hashable, Codable, Sendable {
    
    let metadata: ForecastMetadata
    let samples: [ForecastSample]
}
