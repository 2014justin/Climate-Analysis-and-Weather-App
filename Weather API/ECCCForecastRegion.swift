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

/// Identifies one Meteocode forecast segment for a geographic region.
///
/// ECCC may divide one region's forecast across multiple bulletins with
/// adjacent valid-time windows. For example, one bulletin may contain the
/// short-range forecast while another continues the same region forward.
nonisolated struct ECCCMeteocodeRegionProduct: Identifiable, Hashable, Codable, Sendable {
    
    let bulletinCode: String
    let regionCode: String
    
    var id: String {
        [
            bulletinCode,
            regionCode
        ]
            .joined(separator: ":")
    }
}

/// Identifies one official ECCC public forecast region.
///
/// A geographic region may be represented by multiple Meteocode products
/// whose valid-time windows continue one another.
nonisolated struct ECCCForecastRegion: Identifiable, Hashable, Codable, Sendable {
    
    let feed: ECCCForecastFeed
    
    /// Normalized bilingual identity shared with ECCC's zone geometry.
    let identity: ECCCForecastZoneIdentity
    
    /// Official English forecast-region name for display.
    let name: String
    
    /// Every Meteocode product contributing forecast data to this region.
    let products: [ECCCMeteocodeRegionProduct]
    
    /// Geographic identity deliberately excludes individual bulletin codes.
    var id: String {
        [
            feed.rawValue,
            identity.englishName,
            identity.frenchName ?? ""
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
nonisolated struct ECCCForecastRegionGeometry: Identifiable, Hashable, Codable, Sendable {
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
