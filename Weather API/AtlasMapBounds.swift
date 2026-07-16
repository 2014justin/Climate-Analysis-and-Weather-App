import Foundation

/// The geographic edges currently visible in the Atlas.
///
/// Providers use different bounding-box argument orders, so the edges
/// remain explicitly named until a provider constructs its own request.
///

struct AtlasMapBounds: Codable, Hashable, Sendable {
    let north: Double
    let south: Double
    let east: Double
    let west: Double
    
    init(
        /// The latitude that is focused in the center.
        centerLatitude: Double,
    
        /// The longitude that is focused in the center.
        centerLongitude: Double,
    
        latitudeSpan: Double,
        longitudeSpan: Double
    ) {
        let halfLatitudeSpan = abs(latitudeSpan) / 2.0
        let halfLongitudeSpan = abs(longitudeSpan) / 2.0
        
        north = min(
            centerLatitude + halfLatitudeSpan,
            90.0
        )
        
        south = max(
            centerLatitude - halfLatitudeSpan,
            -90.0
        )
        
        east = centerLongitude + halfLongitudeSpan
        west = centerLongitude - halfLongitudeSpan
    }
    /// Creates bounds directly from four known geographic edges.
    init(
        north: Double,
        south: Double,
        east: Double,
        west: Double
    ) {
        self.north = min(north, 90.0)
        self.south = max(south, -90.0)
        self.east = east
        self.west = west
    }

    /// Adds a margin around the visible map.
    ///
    /// A 0.25 fraction adds 25% of the current width and height
    /// to every edge.
    func padded(by fraction: Double) -> AtlasMapBounds {
        let safeFraction = max(fraction, 0)
        let latitudePadding =
            (north - south) * safeFraction
        let longitudePadding =
            (east - west) * safeFraction

        return AtlasMapBounds(
            north: north + latitudePadding,
            south: south - latitudePadding,
            east: east + longitudePadding,
            west: west - longitudePadding
        )
    }

    /// Returns true when one coordinate falls inside these bounds.
    func contains(
        latitude: Double,
        longitude: Double
    ) -> Bool {
        guard latitude >= south,
            latitude <= north else {
            return false
        }
        
        if coversAllLongitudes {
            return true
        }
        
        guard crossesAntimeridian else {
            return longitude >= west
                && longitude <= east
        }
        
        let normalizedLongitude =
            Self.normalized(longitude)
        
        let normalizedWest =
            Self.normalized(west)
        
        let normalizedEast =
            Self.normalized(east)
        
        return normalizedLongitude >= normalizedWest
            || normalizedLongitude <= normalizedEast

    }

    /// Returns true when these bounds completely contain another box.
    func contains(_ other: AtlasMapBounds) -> Bool {
        guard
            !crossesAntimeridian,
            !other.crossesAntimeridian
        else {
            return false
        }

        return north >= other.north
            && south <= other.south
            && east >= other.east
            && west <= other.west
    }
    
    /// A normal west-to-east request cannot represent this region as one box.
    var crossesAntimeridian: Bool {
        west < -180.0 || east > 180.0
    }
    
    var coversAllLongitudes: Bool {
        east - west >= 360.0
    }
    
    var latitudeSpan: Double {
        max(north - south, 0)
    }
    
    var longitudeSpan: Double {
        min(max(east - west, 0), 360)
    }
    
    private static func normalized(
        _ longitude: Double
    ) -> Double {
        var result = longitude
            .truncatingRemainder(dividingBy: 360)
        
        if result > 180 {
            result -= 360
        } else if result < -180 {
            result += 360
        }
        
        return result
    }
}
