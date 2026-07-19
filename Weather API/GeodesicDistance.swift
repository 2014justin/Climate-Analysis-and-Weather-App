/// Calculate geodesic distance from the selected station in the atlas.
/// Because latitude and longitude coordinate system changes dramatically with latitude, this guarantees it is the same
/// "as the crow flies" distance regardless if the station is on the arctic circle, or near the equator.
///
/// Uses haversine formula to calculate distance
///
import Foundation

struct GeographicCoordinate: Codable, Equatable, Hashable, Sendable {
    
    let latitude: Double
    let longitude: Double
    
    var isValid: Bool {
        latitude.isFinite
            && longitude.isFinite
            && (-90.00...90.00).contains(latitude)
            && (-180.00...180.00).contains(longitude)
    }
}

enum GeodesicDistance {
    private static let earthRadiusMiles = 3_958.8
    
    private static let earthRadiusKilometers = 6_371.0
    
    static func miles(
        from source: GeographicCoordinate,
        to destination: GeographicCoordinate
    ) -> Double? {
        guard let angularDistance =
                angularDistance(
                    from: source,
                    to: destination
                ) else {
            return nil
        }
        
        return earthRadiusMiles * angularDistance
    }
    
    static func kilometers(
        from source: GeographicCoordinate,
        to destination: GeographicCoordinate
    ) -> Double? {
        guard let angularDistance =
                angularDistance(
                    from: source,
                    to: destination
                ) else {
            return nil
        }
        
        return earthRadiusKilometers * angularDistance
    }
    
    private static func angularDistance(
        from source: GeographicCoordinate,
        to destination: GeographicCoordinate
    ) -> Double? {
        guard source.isValid,
              destination.isValid else {
            return nil
        }
        
        let degreesToRadians = Double.pi / 180.0
        
        let sourceLatitude =
            source.latitude * degreesToRadians
        
        let destinationLatitude =
            destination.latitude * degreesToRadians
        
        let latitudeDifference =
            (destination.latitude - source.latitude) * degreesToRadians
        
        let longitudeDifference =
            (destination.longitude - source.longitude) * degreesToRadians
        
        let latitudeTerm = sin(latitudeDifference / 2.0) * sin(latitudeDifference / 2.0)
        
        let longitudeTerm = sin(longitudeDifference / 2.0) * sin(longitudeDifference / 2.0)
        
        let haversineValue = latitudeTerm
            + cos(sourceLatitude) * cos(destinationLatitude) * longitudeTerm
        
        let clampedValue =
            min(max(haversineValue, 0.0), 1.0)
        
        return 2.0 * atan2(
            sqrt(clampedValue),
            sqrt(1.0 - clampedValue)
        )
    }
}
