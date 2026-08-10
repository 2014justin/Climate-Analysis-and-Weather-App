/// A map-independent geographic coordinate.

import Foundation
nonisolated struct SolarCoordinate: Equatable, Sendable {
    let latitudeDegrees: Double
    let longitudeDegrees: Double
}

/// Everything derived solely from one UTC instant.
///
/// Consumers can use this for Atlas geometry, station-level solar
/// calculations, annual Sun Graphs, or future solar-energy products.
nonisolated struct SolarEphemeris: Equatable, Sendable {
    let instant: Date
    
    let fractionalYearRadians: Double
    let declinationRadians: Double
    let equationOfTimeMinutes: Double
    
    let subsolarCoordinate: SolarCoordinate
    
    /// Earth-fixed unit vector pointing from Earth toward the Sun.
    ///
    /// x points through 0° longitude.
    /// y points through 90° east longitude.
    /// z points through the North Pole.
    
    let earthFixedSunVector: SIMD3<Double>
}

/// Pure astronomical and spherical-geometry calculations.
///
/// This type deliberately knows nothing about MapKit, SwiftUI,
/// weather providers, or saved climate stations.
nonisolated enum SolarPositionCalculator {
    static func ephemeris(
        at instant: Date
    ) -> SolarEphemeris {
        let time = utcTimeComponents(
            for: instant
        )
        
        let gamma = 2.0 * Double.pi / Double(time.daysInYear) * (
            Double(time.dayOfYear - 1) + (time.fractionalUTCHour - 12.0) / 24.0
        )
        
        let equationOfTimeMinutes =
        229.18 * (
            0.000075
            + 0.001868 * cos(gamma)
            - 0.032077 * sin(gamma)
            - 0.014615 * cos(2.0 * gamma)
            - 0.040849 * sin(2.0 * gamma)
        )
        
        let declinationRadians =
        0.006918
        - 0.399912 * cos(gamma)
        + 0.070257 * sin(gamma)
        - 0.006758 * cos(2.0 * gamma)
        + 0.000907 * sin(2.0 * gamma)
        - 0.002697 * cos(3.0 * gamma)
        + 0.001480 * sin(3.0 * gamma)
        
        let utcMinutes = time.fractionalUTCHour * 60.00
        
        /// Solar noon occurs where:
        /// UTC minutes + 4 times lambda + equnOfTime = 720
        let subsolarLongitudeDegrees =
            normalizedLongitude(
                (720.0 - utcMinutes - equationOfTimeMinutes) / 4.0
            )
        
        let subsolarLatitudeDegrees = declinationRadians * 180.00 / Double.pi
        
        let subsolarCoordinate =
            SolarCoordinate(
                latitudeDegrees: subsolarLatitudeDegrees,
                longitudeDegrees: subsolarLongitudeDegrees
            )
        
        let longitudeRadians = subsolarLongitudeDegrees * Double.pi / 180.0
        
        let sunVector = SIMD3<Double>(
            cos(declinationRadians) * cos(longitudeRadians),
            cos(declinationRadians) * sin(longitudeRadians),
            sin(declinationRadians)
        )
        
        return SolarEphemeris(
            instant: instant,
            fractionalYearRadians: gamma,
            declinationRadians: declinationRadians,
            equationOfTimeMinutes: equationOfTimeMinutes,
            subsolarCoordinate: subsolarCoordinate,
            earthFixedSunVector: sunVector
        )
    }
    
    /// Local outward normal for a geodetic coordinate.
    static func surfaceNormal(
        latitudeDegrees: Double,
        longitudeDegrees: Double
    ) -> SIMD3<Double> {
        let latitudeRadians = latitudeDegrees * Double.pi / 180.00
        
        let longitudeRadians = longitudeDegrees * Double.pi / 180.00
        
        return SIMD3<Double>(
            cos(latitudeRadians) * cos(longitudeRadians),
            cos(latitudeRadians) * sin(longitudeRadians),
            sin(latitudeRadians)
        )
    }
    
    /// n · s, ranging from −1 at the antisolar point
    /// through 0 at the terminator to +1 at the subsolar point.
    ///
    static func facingFactor(
        latitudeDegrees: Double,
        longitudeDegrees: Double,
        using ephemeris: SolarEphemeris
    ) -> Double {
        let normal =
            surfaceNormal(latitudeDegrees: latitudeDegrees, longitudeDegrees: longitudeDegrees)
        
        let sun = ephemeris.earthFixedSunVector
        
        let rawDotProduct =
            normal.x * sun.x + normal.y * sun.y + normal.z * sun.z
        
        /// Protect asin from floating-point values such as 1.000000002.
        return min(
            max(rawDotProduct, -1.0), 1.0
        )
    }
    
    static func solarAltitudeDegrees(
        latitudeDegrees: Double,
        longitudeDegrees: Double,
        using ephemeris: SolarEphemeris
    ) -> Double {
        asin(
            facingFactor(
                latitudeDegrees: latitudeDegrees,
                longitudeDegrees: longitudeDegrees,
                using: ephemeris
            )
        ) * 180.00 / Double.pi
    }
    
    fileprivate static func normalizedLongitude(
        _ longitudeDegrees: Double
    ) -> Double {
        var result = longitudeDegrees.truncatingRemainder(dividingBy: 360.00)
        
        if result >= 180.0 {
            result -= 360.0
        }
        
        if result < -180.0 {
            result += 360.0
        }
        
        return result
    }
    
    fileprivate static func utcTimeComponents(
        for instant: Date
    ) -> (
        dayOfYear: Int,
        daysInYear: Int,
        fractionalUTCHour: Double
    ) {
        var calendar = Calendar(identifier: .gregorian)
        
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        
        let dayOfYear =
            calendar.ordinality(of: .day, in: .year, for: instant)
            ?? 1
        
        let daysInYear =
            calendar.range(of: .day, in: .year, for: instant)?.count
            ?? 365
        
        let components =
        calendar.dateComponents(
            [
                .hour,
                .minute,
                .second,
                .nanosecond
            ],
            from: instant
        )
        
        let fractionalUTCHour =
        Double(components.hour ?? 0)
        + Double( components.minute ?? 0) / 60.0
        + Double( components.second ?? 0) / 3600.0
        + Double(components.nanosecond ?? 0) / 3_600_000_000_000.00
        
        return(
            dayOfYear,
            daysInYear,
            fractionalUTCHour
        )
    }
}

