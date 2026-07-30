import Foundation

/// Provider-specific metadata attached to one official ECCC public standard forecast-zone geometry.
nonisolated struct ECCCForecastZoneGeoJSONProperties: Decodable, Sendable, Hashable {
    /// Six-digit CLC public-zone identifier.
    let publicZoneCode: String
    
    /// Stable identifier for the published geographic feature.
    let featureID: String
    
    let name: String
    let frenchName: String?
    
    let provinceCode: String
    let countryCode: String
    
    /// ECCC's geographic calssification, such as "land".
    let kind: String
    
    /// Expected to identify a public standard forecast zone.
    let usage: String
    
    /// ECCC's intended depiction category.
    let depiction: String
    
    fileprivate enum CodingKeys: String, CodingKey {
        case publicZoneCode = "CLC"
        case featureID = "FEATURE_ID"
        case name = "NAME"
        case frenchName = "NOM"
        case provinceCode = "PROVINCE_C"
        case countryCode = "COUNTRY_C"
        case kind = "KIND"
        case usage = "USAGE"
        case depiction = "DEPICTN"
    }
}

/// Concrete GeoJSON type used by the ECCC forecast-zone pipeline.
typealias ECCCForecastZoneGeoJSONFeature = GeoJSONFeature<ECCCForecastZoneGeoJSONProperties>

typealias ECCCForecastZoneGeoJSONFeatureCollection = GeoJSONFeatureCollection<ECCCForecastZoneGeoJSONProperties>


enum ECCCForecastZoneGeoJSONConversionError: LocalizedError, Sendable {
    
    case missingGeometry(featureID: String)
    
    case emptyPolygonCollection(featureID: String)
    
    var errorDescription: String? {
        switch self {
        case .missingGeometry(let featureID):
            return """
                ECCC forecast-zone feature \(featureID) contains no 
                geographic geometry.
                """
            
        case .emptyPolygonCollection(let featureID):
            return """
                ECCC forecast-zone feature \(featureID) produced no usable \
                geographic polygons.
                """
        }
    }
}

/// One decoded and geographically-validated ECCC public forecast zone.
///
/// This type intentionally contains no Meteocode feed or bulletin identifiers.
/// Those are joined later using an authoritative mapping.
nonisolated struct ECCCForecastZoneGeometry: Identifiable, Hashable, Sendable {
    
    let properties: ECCCForecastZoneGeoJSONProperties
    let boundingBox: GeographicBoundingBox
    let polygons: [GeographicPolygon]
    
    init(
        properties: ECCCForecastZoneGeoJSONProperties,
        polygons: [GeographicPolygon]
    ) throws {
        guard let boundingBox = GeographicBoundingBox.enclosing(
            polygons: polygons
        ) else {
            throw ECCCForecastZoneGeoJSONConversionError
                .emptyPolygonCollection(featureID: properties.featureID)
        }
        
        self.properties = properties
        self.boundingBox = boundingBox
        self.polygons = polygons
    }
    
    var id: String { properties.featureID }
}

extension GeoJSONFeature
where Properties == ECCCForecastZoneGeoJSONProperties {
    
    /// Converts the feature's GeoJSON polygon or MultiPolygon into the
    /// provider-agnostic polygons used by the containment engine.
    nonisolated func forecastZonePolygons() throws -> [GeographicPolygon] {
        
        guard let geometry else {
            throw ECCCForecastZoneGeoJSONConversionError
                .missingGeometry(featureID: properties.featureID)
        }
        
        return try geometry.geographicPolygons()
    }
    
    /// Converts the complete GeoJSON feature into a validated forecast zone.
    nonisolated func forecastZoneGeometry() throws -> ECCCForecastZoneGeometry {
        let polygons = try forecastZonePolygons()
        
        return try ECCCForecastZoneGeometry(
            properties: properties,
            polygons: polygons
        )
    }
}

extension GeoJSONFeatureCollection
where Properties == ECCCForecastZoneGeoJSONProperties {
    
    /// Converts every decoded ECCC GeoJSON features into a geographically-validated
    /// forecast zone.
    nonisolated func forecastZoneGeometries() throws -> [ECCCForecastZoneGeometry] {
        
        try features.map { feature in
            try feature.forecastZoneGeometry()
        }
    }
}
