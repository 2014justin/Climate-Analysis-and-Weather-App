import Foundation

/// The five regional directories currently published by the
/// ECCC Meteocode Datamart.
enum ECCCForecastFeed: String, CaseIterable, Codable, Sendable {
    case atl
    case ont
    case pnr
    case pyr
    case que
}

/// Identifies one official ECCC public forecast region.
///
/// Meteocode forecasts belong to geographic regions rather than individual
/// weather stations. A station coordinate must therefore be resolved to one
/// of these regions before its forecast can be downloaded.
struct ECCCForecastRegion: Identifiable, Hashable, Codable, Sendable {
    
    let feed: ECCCForecastFeed
    
    /// ECCC bulletin identifier, such as the FPAANN component appearing in Meteocode filenames.
    let bulletinCode: String
    
    /// Meteocode-local region code, including its `r` prefix,
    /// for example `r16.1`.
    let regionCode: String

    /// Official English forecast-region name.
    let name: String
    
    /// Namespaced because a region code alone is not globally unique
    /// across every ECCC forecast bulletin.
    var id: String {
        [
            feed.rawValue,
            bulletinCode,
            regionCode
        ]
            .joined(separator: ":")
    }
}

/// Converts a geographic point into the official ECCC forecast region
/// containing that point.
protocol ECCCForecastRegionResolving: Sendable {
    func region(
        containingLatitude latitude: Double,
        longitude: Double
    ) async throws -> ECCCForecastRegion
}


enum ECCCForecastRegionGeometryError: LocalizedError, Sendable {
    case emptyPolygonCollection(featureID: String)
    
    var errorDescription: String? {
        switch self {
        case .emptyPolygonCollection(let featureID):
            return """
                ECCC forecast-region feature \(featureID) contains no usable \
                geographic polygons.
                """
        }
    }
}

/// Connects ECCC's official public-zone geometry to the Meteocode region
/// whose forecast files represent that geographic area.
struct ECCCForecastRegionGeometry: Identifiable, Hashable, Codable, Sendable {
    /// Identifier from ECCC's published geometry  dataset.
    let featureID: String
    
    /// Six-digit CLC public-zone identifier, such as 076400 for Edmonton.
    let publicZoneCode: String
    
    let region: ECCCForecastRegion
    let boundingBox: GeographicBoundingBox
    let polygons: [GeographicPolygon]
    
    init(
        featureID: String,
        publicZoneCode: String,
        region: ECCCForecastRegion,
        polygons: [GeographicPolygon]
    ) throws {
        guard let boundingBox = GeographicBoundingBox.enclosing(
            polygons: polygons
        ) else {
            throw ECCCForecastRegionGeometryError
                .emptyPolygonCollection(featureID: featureID)
        }
        
        self.featureID = featureID
        self.publicZoneCode = publicZoneCode
        self.region = region
        self.boundingBox = boundingBox
        self.polygons = polygons
    }
    
    var id: String { featureID }
}
