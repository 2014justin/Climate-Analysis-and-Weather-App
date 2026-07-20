import Foundation

/// Climate elements whose official ECCC station threads
/// are required by the generated temperature profile.
/// Defines those official maximum- and minimum-temperature station threads.

enum ECCCClimateElement: String, Codable, Hashable, Sendable {
    
    case dailyMaximumTemperature = "DAILY MAXIMUM TEMPERATURE"
    
    case dailyMinimumTemperature = "DAILY MINIMUM TEMPERATURE"
}

/// One data-bounded station assignment with an
/// official ECCC climate-element thread.

struct ECCCClimateThreadSegment: Codable, Hashable, Sendable {
    
    /// Official order within the element thread.
    let sequence: Int
    
    /// Human-readable ECCC station name.
    let stationName: String
    
    /// ECCC climate identifier used by the daily API.
    let climateIdentifier: String
    
    /// First date this station contributes to the 1991-2020 normal-period thread.
    let normalStartDate: ClimateDate
    
    /// Last date this station contributes to the 1991-2020 normal period thread.
    let normalEndDate: ClimateDate
    
    /// Earlier starting date used for long-term extremes, when ECCC provides one.
    ///
    /// Retained for the future Canadian records overlay in the Weather Year chart.
    let longTermStartDate: ClimateDate?
}

/// ECCC's ordered station lineage for one climate element, such as daily max temp.
struct ECCCClimateElementThread: Codable, Hashable, Sendable {
    
    let element: ECCCClimateElement
    
    let segments: [ECCCClimateThreadSegment]
}

/// One official ECCC 1991–2020 composite location.
///
/// Maximum and minimum temperature threads remain
/// separate because ECCC may assign different stations
/// or transition dates to each element.
struct ECCCClimateComposite: Codable, Identifiable, Hashable, Sendable {
    
    /// Stable anchor climate identifier used to identify this official composite inside the app.
    let canonicalClimateIdentifier: String
    
    /// Official composite name, such as
    /// WINNIPEG RICHARDSON (AIRPORT).
    let displayName: String
    
    let provinceCode: String
    
    let coordinate: GeographicCoordinate
    
    let elevationMeters: Double?
    
    let maximumTemperatureThread:
        ECCCClimateElementThread
    
    let minimumTemperatureThread:
        ECCCClimateElementThread
    
    var id: String {
        canonicalClimateIdentifier
    }
}


/// Root object for the generated, bundled catalog.
///
/// Version metadata lets a future importer update the official source without making the runtime
/// decoder guess which catalog format it received.

struct ECCCClimateCompositeCatalog: Codable, Sendable {
    
    let schemaVersion: Int
    
    let normalPeriodStartYear: Int
    
    let normalPeriodEndYear: Int
    
    /// ISO-8601 generation timestamp stores as text so decoding does not dep
    /// end on a
    /// Date decoding strategy.
    let generatedAtUTC: String
    
    let sourceInventoryURL: String
    
    let composites: [ECCCClimateComposite]
}


