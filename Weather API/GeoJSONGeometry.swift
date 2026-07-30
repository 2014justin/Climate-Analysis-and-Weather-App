import Foundation

/// One position decoded from a GeoJSON coordinate array.
///
/// GeoJSON stores coordinates as [longitude, latitude], not the latitude-longitude order
/// commonly used elsewhere in the app.
///
nonisolated struct GeoJSONPosition: Decodable, Hashable, Sendable {
    let coordinate: GeographicCoordinate
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        guard container.isAtEnd == false else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "A GeoJSON position is missing its longitude."
            )
        }
        
        let longitude = try container.decode(Double.self)
        
        guard container.isAtEnd == false else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "A GeoJSON position is missing its latitude"
            )
        }
        
        let latitude = try container.decode(Double.self)
        
        let coordinate = GeographicCoordinate(
            latitude: latitude,
            longitude: longitude
        )
        
        guard coordinate.isValid else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: """
                    Invalid GeoJSON position: longitude \(longitude), \
                    latitude \(latitude).
                    """
                
            )
        }
        
        self.coordinate = coordinate
    }
}

/// GeoJSON nesting levels, named so later decoding remains readable.
typealias GeoJSONLinearRing = [GeoJSONPosition]
typealias GeoJSONPolygonCoordinates = [GeoJSONLinearRing]
typealias GeoJSONMultiPolygonCoordinates = [GeoJSONPolygonCoordinates]


/// A provider-neutral GeoJSON polygon geometry.
///
/// GeoJSON uses the type field to determine how deeply the coordinate arrays are nested.

nonisolated enum GeoJSONGeometry: Decodable, Hashable, Sendable {
    case polygon(GeoJSONPolygonCoordinates)
    case multiPolygon(GeoJSONMultiPolygonCoordinates)
    
    private enum CodingKeys: String, CodingKey {
        case type
        case coordinates
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let geometryType = try container.decode(
            String.self,
            forKey: .type
        )
        
        switch geometryType {
        case "Polygon":
            let coordinates = try container.decode(
                GeoJSONPolygonCoordinates.self,
                forKey: .coordinates
            )
            
            self = .polygon(coordinates)
            
        case "MultiPolygon":
            let coordinates = try container.decode(
                GeoJSONMultiPolygonCoordinates.self,
                forKey: .coordinates
            )
            
            self = .multiPolygon(coordinates)
            
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: """
                    Unsupported GeoJSON geometry type: \(geometryType)
                    """
            )
        }
    }
}


nonisolated enum GeoJSONGeometryConversionError: LocalizedError, Sendable {
    case emptyGeometry
    case polygonWithoutExteriorRing
    case invalidLinearRing(
        positionCount: Int,
        distinctCoordinateCount: Int
    )
    
    var errorDescription: String? {
        switch self {
        case .emptyGeometry:
            return "The GeoJSON geometry contains no polygons."
            
        case .polygonWithoutExteriorRing:
            return "A GeoJSON polygon has no exterior ring."
            
        case .invalidLinearRing(
            let positionCount,
            let distinctCoordinateCount
        ):
            return """
                A GeoJSON linear ring contains \(positionCount) positions but \
                only \(distinctCoordinateCount) distinct coordinates. At least \
                three distinct coordinates are required.
                """
        }
    }
}

extension GeoJSONGeometry {
    /// Converts Polygon and MultiPolygon inputs into one uniform collection
    /// used by the provider-agnostic containment engine.
    nonisolated func geographicPolygons() throws -> [GeographicPolygon] {
        switch self {
        case .polygon(let coordinates):
            return [
                try Self.geographicPolygon(from: coordinates)
            ]
            
        case .multiPolygon(let polygonCoordinates):
            guard polygonCoordinates.isEmpty == false else {
                throw GeoJSONGeometryConversionError.emptyGeometry
            }
            
            return try polygonCoordinates.map { coordinates in
                try Self.geographicPolygon(from: coordinates)
            }
        }
    }
    
    fileprivate nonisolated static func geographicPolygon(
        from coordinates: GeoJSONPolygonCoordinates
    ) throws -> GeographicPolygon {
        guard let exteriorCoordinates = coordinates.first else {
            throw GeoJSONGeometryConversionError
                .polygonWithoutExteriorRing
        }
        
        let exteriorRing = try geographicRing(
            from: exteriorCoordinates
        )
        
        let interiorRings = try coordinates
            .dropFirst()
            .map { ringCoordinates in
                try geographicRing(
                    from: ringCoordinates
                )
            }
        
        return GeographicPolygon(
            exteriorRing: exteriorRing,
            interiorRings: interiorRings
        )
    }
    
    /// Take one GeoJSON ring and convert it to a list of Geographic Coordinates that our app can use.
    /// Removed duplicate closing point. Verifies greater than or equal 3 unique verticies, throws if malform
    /// and you get a clean ring.
    /// 
    fileprivate nonisolated static func geographicRing(
        from positions: GeoJSONLinearRing
    ) throws -> [GeographicCoordinate] {
        
        /// Extract the coordinate.
        var coordinates = positions.map(\.coordinate)
        
        /// GeoJSON normally repeats the first position at the end. Our containment engine closes
        /// the ring itself, so removes duplicates.
        while coordinates.count > 1,
              coordinates.first == coordinates.last {
            coordinates.removeLast()
        }
        
        let distinctCoordinateCount = Set(coordinates).count
        
        guard distinctCoordinateCount >= 3 else {
            throw GeoJSONGeometryConversionError.invalidLinearRing(
                positionCount: positions.count,
                distinctCoordinateCount: distinctCoordinateCount
            )
        }
        
        return coordinates
    }
}
