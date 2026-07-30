import Foundation

/// An axis-aligned geographic rectangle used as a fast containment check.
nonisolated struct GeographicBoundingBox: Hashable, Codable, Sendable {
    let minimumLatitude: Double
    let maximumLatitude: Double
    let minimumLongitude: Double
    let maximumLongitude: Double
    
    func contains(
        _ coordinate: GeographicCoordinate
    ) -> Bool {
        guard coordinate.isValid == true else {
            return false
        }
        
        return coordinate.latitude >= minimumLatitude &&
        coordinate.latitude <= maximumLatitude &&
        coordinate.longitude >= minimumLongitude &&
        coordinate.longitude <= maximumLongitude
    }
}

/// Smartly decides which polygons contain the station we need. If we naively did a full point-in-polygon
/// for every polygon, we'd have a situation where the user taps Calgary and every polygon 1...15,000
/// is tested. That is not very efficient. The bounding box is the cheap 'bouncer'. Every polygon gets wrapped
/// in the smallest rectangle that completely contains it. Saves a surprising amount of work.

extension GeographicBoundingBox {
    /// Returns one conservative geographic envelope enclosing every polygon.
    ///
    /// Only exterior rings are needed because valid interior rings are already contained
    /// by their polygon's exterior ring.
    nonisolated static func enclosing(
        polygons: [GeographicPolygon]
    ) -> GeographicBoundingBox? {
        let coordinates = polygons.flatMap(\.exteriorRing)
        
        guard let firstCoordinate = coordinates.first else {
            return nil
        }
        
        var minimumLatitude = firstCoordinate.latitude
        var maximumLatitude = firstCoordinate.latitude
        var minimumLongitude = firstCoordinate.longitude
        var maximumLongitude = firstCoordinate.longitude
        
        for coordinate in coordinates.dropFirst() {
            minimumLatitude = min(
                minimumLatitude,
                coordinate.latitude
            )
            
            maximumLatitude = max(
                maximumLatitude,
                coordinate.latitude
            )
            
            minimumLongitude = min(
                minimumLongitude,
                coordinate.longitude
            )
            
            maximumLongitude = max(
                maximumLongitude,
                coordinate.longitude
            )
        }
        
        return GeographicBoundingBox(
            minimumLatitude: minimumLatitude,
            maximumLatitude: maximumLatitude,
            minimumLongitude: minimumLongitude,
            maximumLongitude: maximumLongitude
        )
    }
}

/// One geographic polygon consisting of an exterior boundary and zero or
/// more excluded interior boundaries.
nonisolated struct GeographicPolygon: Hashable, Codable, Sendable {
    let exteriorRing: [GeographicCoordinate]
    let interiorRings: [[GeographicCoordinate]]
    
    init(
        exteriorRing: [GeographicCoordinate],
        interiorRings: [[GeographicCoordinate]] = []
    ) {
        self.exteriorRing = exteriorRing
        self.interiorRings = interiorRings
    }
}

/// Describes a point's relationship to a geographic polygon.
nonisolated enum GeographicPointLocation: Hashable, Sendable {
    case outside
    case inside
    case boundary
}

/// Provider-neutral point-in-polygon calculations.
///
/// The implementation uses ray casting after unwrapping longitudes so
/// polygons near the international date line remain usable.
nonisolated enum GeographicPolygonContainment {
    private static let boundaryTolerance = 0.000_000_001
    
    static func location(
        of coordinate: GeographicCoordinate,
        in polygon: GeographicPolygon
    ) -> GeographicPointLocation {
        guard coordinate.isValid == true else {
            return .outside
        }
        
        let exteriorLocation = location(
            of: coordinate,
            in: polygon.exteriorRing
        )
        
        switch exteriorLocation {
        case .outside:
            return .outside
            
        case .boundary:
            return .boundary
            
        case .inside:
            break
        }
        
        for interiorRing in polygon.interiorRings {
            let interiorLocation = location(of: coordinate, in: interiorRing)
            
            switch interiorLocation {
            case .outside:
                continue
                
            case .inside:
                /// the point lies inside an excluded hole.
                return .outside
                
            case .boundary:
                return .boundary
            }
        }
        
        return .inside
    }
    
    static func contains(
        _ coordinate: GeographicCoordinate,
        in polygon: GeographicPolygon,
        includingBoundary: Bool = true
    ) -> Bool {
        switch location(of: coordinate, in: polygon) {
        case .inside:
            return true
            
        case .boundary:
            return includingBoundary
            
        case .outside:
            return false
        }
    }
    
    fileprivate static func location(
        of coordinate: GeographicCoordinate,
        in ring: [GeographicCoordinate]
    ) -> GeographicPointLocation {
        guard ring.count >= 3,
              ring.allSatisfy({ $0.isValid }) else {
            return .outside
        }
        
        let vertices = unwrappedVertices(
            from: ring,
            relativeToLongitude: coordinate.longitude
        )
        
        let point = PlanarVertex(
            x: coordinate.longitude,
            y: coordinate.latitude
        )
        
        var isInside = false
        
        for index in vertices.indices {
            let nextIndex = vertices.index(
                afterWrapping: index
            )
            
            let start = vertices[index]
            let end = vertices[nextIndex]
            
            if pointLiesOnSegment(
                point,
                from: start,
                to: end
            ) {
                return .boundary
            }
            
            let segmentCrossesLatitude =
                (start.y > point.y) != (end.y > point.y)
            
            guard segmentCrossesLatitude else {
                continue
            }
            
            let latitudeFraction =
                (point.y - start.y) /
                (end.y - start.y)
            
            let intersectionLongitude =
                start.x +
                latitudeFraction * (end.x - start.x)
            
            if point.x < intersectionLongitude {
                isInside.toggle()
            }
        }
        return isInside ? .inside : .outside
    }
    
    fileprivate static func pointLiesOnSegment(
        _ point: PlanarVertex,
        from start: PlanarVertex,
        to end: PlanarVertex
    ) -> Bool {
        let segmentX = end.x - start.x
        let segmentY = end.y - start.y
        
        let pointX = point.x - start.x
        let pointY = point.y - start.y
        
        let crossProduct = pointX * segmentY - pointY * segmentX
        
        let segmentScale = max(
            1.0,
            max(abs(segmentX), abs(segmentY))
        )
        
        guard abs(crossProduct) <=
                boundaryTolerance * segmentScale else {
            return false
        }
        
        let minimumX =
            min(start.x, end.x) - boundaryTolerance
        
        let maximumX =
            max(start.x, end.x) + boundaryTolerance
        
        let minimumY =
            min(start.y, end.y) - boundaryTolerance
        
        let maximumY =
            max(start.y, end.y) + boundaryTolerance
        
        return point.x >= minimumX &&
        point.x <= maximumX &&
        point.y >= minimumY &&
        point.y <= maximumY
    }
    
    fileprivate static func unwrappedVertices(
        from ring: [GeographicCoordinate],
        relativeToLongitude referenceLongitude: Double
    ) -> [PlanarVertex] {
        guard let firstCoordinate = ring.first else {
            return []
        }
        
        var previousLongitude =
            firstCoordinate.longitude
        
        var vertices = [
            PlanarVertex(
                x: previousLongitude,
                y: firstCoordinate.latitude
            )
        ]
        
        for coordinate in ring.dropFirst() {
            var longitude = coordinate.longitude
            
            while longitude - previousLongitude > 180.00 {
                longitude -= 360.0
            }
            
            while longitude - previousLongitude < -180.00 {
                longitude += 360.0
            }
            
            vertices.append(
                PlanarVertex(
                    x: longitude,
                    y: coordinate.latitude
                )
            )
            
            previousLongitude = longitude
        }
        
        let meanLongitude =
            vertices.map(\.x).reduce(0.0,+) /
            Double(vertices.count)
        
        let longitudeShift =
            ((referenceLongitude - meanLongitude) / 360.0)
                .rounded() * 360.0
        
        return vertices.map { vertex in
            PlanarVertex(
                x: vertex.x + longitudeShift,
                y: vertex.y
            )
        }
    }
    
    fileprivate struct PlanarVertex {
        let x: Double
        let y: Double
    }
}

fileprivate extension Collection {
    nonisolated func index(
        afterWrapping index: Index
    ) -> Index {
        let followingIndex = self.index(after: index)
        
        return followingIndex == endIndex
            ? startIndex
            : followingIndex
    }
}
