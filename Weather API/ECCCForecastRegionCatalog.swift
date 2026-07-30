import Foundation

enum ECCCForecastRegionCatalogError: LocalizedError, Sendable {
    case emptyCatalog
    case invalidCoordinate(GeographicCoordinate)
    case regionNotFound(GeographicCoordinate)
    case ambiguousRegions(
        coordinate: GeographicCoordinate,
        regionIDs: [String]
    )
    
    var errorDescription: String? {
        switch self {
        case .emptyCatalog:
            return "The ECCC forecast-region catalog is empty."
            
        case .invalidCoordinate(let coordinate):
            return """
                Invalid forecast coordinate: latitude \(coordinate.latitude), \
                longitude \(coordinate.longitude).
                """
            
        case .regionNotFound(let coordinate):
            return """
                No ECCC forecast region contains latitude \
                \(coordinate.latitude), longitude \(coordinate.longitude).
                """
            
        case .ambiguousRegions(let coordinate, let regionIDs):
            return """
                Latitude \(coordinate.latitude), longitude \
                \(coordinate.longitude) matches multiple ECCC forecast \
                regions : \(regionIDs.joined(separator: ", ")).
                """
        }
    }
}


/// Resolves coordinates against a prepared collection of official ECCC
/// forecast-region geometries.
struct ECCCForecastRegionCatalog: ECCCForecastRegionResolving, Sendable {
    
    let geometries: [ECCCForecastRegionGeometry]
    
    nonisolated init(
        geometries: [ECCCForecastRegionGeometry]
    ) {
        self.geometries = geometries
    }
    
    func region(
        containingLatitude latitude: Double,
        longitude: Double
    ) async throws -> ECCCForecastRegion {
        guard geometries.isEmpty == false else {
            throw ECCCForecastRegionCatalogError.emptyCatalog
        }
        
        let coordinate = GeographicCoordinate(
            latitude: latitude, longitude: longitude
        )
        
        guard coordinate.isValid else {
            throw ECCCForecastRegionCatalogError.invalidCoordinate(coordinate)
        }
        
        let candidates = geometries.filter {
            $0.boundingBox.contains(coordinate)
        }
        
        var interiorMatches: Set<ECCCForecastRegion> = []
        var boundaryMatches: Set<ECCCForecastRegion> = []
        
        for geometry in candidates {
            for polygon in geometry.polygons {
                switch GeographicPolygonContainment.location(
                    of: coordinate,
                    in: polygon
                ) {
                case .outside:
                    continue
                    
                case .inside:
                    interiorMatches.insert(geometry.region)
                    
                case .boundary:
                    boundaryMatches.insert(geometry.region)
                }
            }
        }
        
        if let region = try uniqueRegion(
            in: interiorMatches,
            at: coordinate
        ) {
            return region
        }
        
        if let region = try uniqueRegion(
            in: boundaryMatches,
            at: coordinate
        ) {
            return region
        }
        
        throw ECCCForecastRegionCatalogError.regionNotFound(
            coordinate
        )
    }
    
    private func uniqueRegion(
        in matches: Set<ECCCForecastRegion>,
        at coordinate: GeographicCoordinate
    ) throws -> ECCCForecastRegion? {
        guard matches.count > 1 else {
            return matches.first
        }
        
        throw ECCCForecastRegionCatalogError.ambiguousRegions(
            coordinate: coordinate,
            regionIDs: matches
                .map(\.id)
                .sorted()
        )
    }
}
