/// Atlas Station. User can select any climate station in a map interface and
/// have the app generate a climate profile.
///
/// Codable supports disk caching, hasbale supports MapKit colections, Sendable prepares the types for asynchronous
/// catalogue work.

import Foundation

/// Controls the future map picker: primary stations NWS/FAA and allNetworks for more 'niche' stations.
enum AtlasStationScope: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
    case primary = "Primary NWS/FAA"
    case allNetworks = "All Networks"
    
    var id: Self {
        self
    }
}

/// Classify station as the main NWS stations or the 'side-characters'.
enum AtlasStationTier: String, Codable, Hashable, Sendable {
    case primary
    case supplemental
}

/// Prevents identifier collisions: US/nws can coexist with future canadian stations.
struct AtlasStationSource: Codable, Hashable, Sendable {
    let countryCode: String
    let providerID: String
    let stationID: String
    
    var namespacedID: String {
        "\(countryCode)/\(providerID)/\(stationID)"
    }
}

/// Lightweight map meta data. Live obs and climate profiles will remain separate
struct AtlasStation: Identifiable, Codable, Hashable, Sendable {
    let source: AtlasStationSource
    let name: String
    let latitude: Double
    let longitude: Double
    let elevationMeters: Double?
    let networkName: String?
    let tier: AtlasStationTier
    let administrativeAreaCode: String?
    let displayPriority: Int?
    
    var id: String {
        source.namespacedID
    }
}
