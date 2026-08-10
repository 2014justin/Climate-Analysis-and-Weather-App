import Foundation

nonisolated enum SolarLightPhase: String, CaseIterable, Sendable {
    case daylight
    case civilTwilight
    case nauticalTwilight
    case astronomicalTwilight
    case night
    
    static func phase(
        forSolarAltitudeDegrees altitude: Double
    ) -> SolarLightPhase {
        switch altitude {
        case 0.0...:
            return .daylight
        case -6.0..<0.0:
            return .civilTwilight
        case -12.0..<(-6.0):
            return .nauticalTwilight
        case -18.0..<(-12.0):
            return .astronomicalTwilight
        default:
            return .night
        }
    }
}

nonisolated struct SolarIlluminationBoundary: Sendable {
    let solarAltitudeDegrees: Double
    let coordinates: [SolarCoordinate]
}

nonisolated enum SolarIlluminationGeometry {
    static let twilightAltitudeDegrees = [
        0.0,
        -6.0,
        -12.0,
        -18.0
    ]
    
    static func boundaries(
        using ephemeris: SolarEphemeris,
        sampleCount: Int = 360
    ) -> [SolarIlluminationBoundary] {
        twilightAltitudeDegrees.map { altitude in
            SolarIlluminationBoundary(
                solarAltitudeDegrees: altitude,
                coordinates: boundary(
                    atSolarAltitudeDegrees: altitude,
                    using: ephemeris,
                    sampleCount: sampleCount
                )
            )
        }
    }
    
    static func boundary(
        atSolarAltitudeDegrees altitudeDegrees: Double,
        using ephemeris: SolarEphemeris,
        sampleCount: Int = 360
    ) -> [SolarCoordinate] {
        let altitudeRadians = altitudeDegrees * Double.pi / 180.0
        
        let sun = ephemeris.earthFixedSunVector
        let reference =
        abs(sun.z) < 0.9
        ? SIMD3<Double>(0.0, 0.0, 1.0)
        : SIMD3<Double>(0.0, 1.0, 0.0)
        
        let u = normalized(cross(reference, sun))
        let v = normalized(cross(sun, u))
        
        let axialScale = sin(altitudeRadians)
        let radialScale = cos(altitudeRadians)
        let numberOfSamples = max(sampleCount, 24)
        
        return (0...numberOfSamples).map { index in
            let angle = 2.0 * Double.pi * Double(index) / Double(numberOfSamples)
            
            let radialDirection = u * cos(angle) + v * sin(angle)
            
            let normal = sun * axialScale + radialDirection * radialScale
            
            return coordinate(from: normalized(normal))
        }
    }
    
    fileprivate static func coordinate(
        from vector: SIMD3<Double>
    ) -> SolarCoordinate {
        let clampedZ = min(max(vector.z, -1.0), 1.0)
        
        return SolarCoordinate(
            latitudeDegrees: asin(clampedZ) * 180.00 / Double.pi,
            longitudeDegrees: atan2(vector.y, vector.x) * 180.00 / Double.pi
        )
    }
    /// Cross product
    fileprivate static func cross(
        _ lhs: SIMD3<Double>,
        _ rhs: SIMD3<Double>
    ) -> SIMD3<Double> {
        SIMD3<Double>(
            lhs.y * rhs.z - lhs.z * rhs.y,
            lhs.z * rhs.x - lhs.x * rhs.z,
            lhs.x * rhs.y - lhs.y * rhs.x
        )
    }
    
    fileprivate static func normalized(
        _ vector: SIMD3<Double>
    ) -> SIMD3<Double> {
        let magnitude = sqrt(
            vector.x * vector.x
            + vector.y * vector.y
            + vector.z * vector.z
        )
        
        guard magnitude > 0.0 else {
            return SIMD3<Double>(0.0, 0.0, 0.0)
        }
        
        return vector / magnitude
    }
}
