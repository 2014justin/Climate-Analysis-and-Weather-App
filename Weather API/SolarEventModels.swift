import Foundation

nonisolated enum SolarEventThreshold: String, CaseIterable, Hashable, Sendable {
    case sunriseSunset
    case civilTwilight
    case nauticalTwilight
    case astronomicalTwilight
    
    var solarAltitudeDegrees: Double {
        switch self {
        case .sunriseSunset:
            return -0.833
        case .civilTwilight:
            return -6.0
        case .nauticalTwilight:
            return -12.0
        case .astronomicalTwilight:
            return -18.0
        }
    }
}

nonisolated enum SolarThresholdCondition: Equatable, Sendable {
    case crosses
    case alwaysAbove
    case alwaysBelow
}

nonisolated struct SolarThresholdEvents: Equatable, Sendable {
    let threshold: SolarEventThreshold
    
    /// Morning upward crossing: dawn or sunrise.
    let rising: Date?
    
    /// Evening downward crossing: sunset or dusk.
    let setting: Date?
    
    let condition: SolarThresholdCondition
}

nonisolated struct SolarDayProfile: Equatable, Sendable {
    let localDayStart: Date
    let nextLocalDayStart: Date
    
    let coordinate: SolarCoordinate
    let timeZoneIdentifier: String
    
    let thresholdEvents: [SolarEventThreshold: SolarThresholdEvents]
    
    let solarNoon: Date
    let solarMidnight: Date
    
    let maximumSolarAltitudeDegrees: Double
    let minimumSolarAltitudeDegrees: Double
    
    func events(
        for threshold: SolarEventThreshold
    ) -> SolarThresholdEvents? {
        thresholdEvents[threshold]
    }
}

nonisolated struct SolarYearProfile: Equatable, Sendable {
    let year: Int
    let coordinate: SolarCoordinate
    let timeZoneIdentifier: String
    let days: [SolarDayProfile]
}
