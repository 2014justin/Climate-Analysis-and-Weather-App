import Foundation

/// One GeoJSON feature containing provider-defined properties and an optional geographic geometry.
///
/// GeoJSON permits a feature's geometry to be null, so geometry remains
/// optional until the provider-specific conversion layer validates it.
nonisolated struct GeoJSONFeature<
    Properties: Decodable & Sendable
>: Decodable, Sendable {
    let geometry: GeoJSONGeometry?
    let properties: Properties
    
    fileprivate enum CodingKeys: String, CodingKey {
        case type
        case geometry
        case properties
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let documentType = try container.decode(
            String.self,
            forKey: .type
        )
        
        guard documentType == "Feature" else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: """
                    Expected a GeoJSON feature but received \(documentType).
                    """
            )
        }
        
        geometry = try container.decodeIfPresent(
            GeoJSONGeometry.self,
            forKey: .geometry
        )
        
        properties = try container.decode(
            Properties.self,
            forKey: .properties
        )
    }
}

/// One navigation or metadata link published with a GeoJSON document.
nonisolated struct GeoJSONLink: Decodable, Hashable, Sendable {
    let relationship: String
    let href: String
    let mediaType: String?
    let title: String?
    
    fileprivate enum CodingKeys: String, CodingKey {
        case relationship = "rel"
        case href
        case mediaType = "type"
        case title
        
    }
}

/// The top-level GeoJSON document containing a collection of features.
///
nonisolated struct GeoJSONFeatureCollection<
    Properties: Decodable & Sendable
>: Decodable, Sendable {
    let features: [GeoJSONFeature<Properties>]
    let numberMatched: Int?
    let numberReturned: Int?
    let links: [GeoJSONLink]
    
    fileprivate enum CodingKeys: String, CodingKey {
        case type
        case features
        case numberMatched
        case numberReturned
        case links
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let documentType = try container.decode(
            String.self,
            forKey: .type
        )
        
        guard documentType == "FeatureCollection" else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: """
                    Expected a GeoJSON FeatureCollection but received \
                    \(documentType).
                    """
            )
        }
        
        features = try container.decode(
            [GeoJSONFeature<Properties>].self,
            forKey: .features
        )
        
        numberMatched = try container.decodeIfPresent(Int.self, forKey: .numberMatched)
        
        numberReturned = try container.decodeIfPresent(Int.self, forKey: .numberReturned)
        
        links = try container.decodeIfPresent(
            [GeoJSONLink].self,
            forKey: .links
        ) ?? []
    }
}
