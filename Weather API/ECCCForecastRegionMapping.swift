//
//  ECCCForecastRegionMapping.swift
//
//  ECCC publishes forecast-zone geometry and live Meteocode forecasts
//  as separate datasets that do not share a common identifier.
//  This file defines the provider-neutral identity layer that joins
//  those datasets using ECCC's official bilingual forecast-zone names,
//  allowing map polygons to be matched to their corresponding forecasts.
//
import Foundation

enum ECCCForecastRegionMappingError: LocalizedError, Sendable {
    case forecastRegionNotFound(
        featureID: String,
        feed: ECCCForecastFeed,
        englishName: String
    )
    
    case ambiguousForecastRegions(
        featureID: String,
        regionIDs: [String]
    )
    
    case unsupportedProvinceCode(String)
    case incompatibleProvinceCodes(String)
    
    var errorDescription: String? {
        switch self {
            
        case .unsupportedProvinceCode(let provinceCode):
            return """
                ECCC forecast-zone province code \(provinceCode) does not map \
                to a supported Meteocode feed.
                """
            
        case .incompatibleProvinceCodes(let provinceCode):
            return """
                ECCC forecast-zone province value \(provinceCode) spans \
                provinces assigned to different Meteocode feeds.
                """
            
        case .forecastRegionNotFound(
            let featureID,
            let feed,
            let englishName
        ):
            return """
                ECCC forecast zone \(featureID), \(englishName), could not be matched \
                to a Meteocode region in the \(feed.rawValue)
                """
            
        case .ambiguousForecastRegions(
            let featureID,
            let regionIDs
        ):
            return """
                ECCC forecast zone \(featureID) matched multiple Meteocode regions: \
                \(regionIDs.joined(separator: ", ")).
                """
        }
    }
}

nonisolated struct ECCCForecastZoneIdentity: Hashable, Codable, Sendable {
    
    let englishName: String
    let frenchName: String?
    
    init(
        englishName: String,
        frenchName: String?
    ) {
        self.englishName = Self.normalized(englishName)
        
        self.frenchName = frenchName.flatMap { name in
            let normalizedName = Self.normalized(name)
            return normalizedName.isEmpty ? nil : normalizedName
        }
    }
    
    /// Compares identities after normalization.
    ///
    /// English names must match. When both datasets provide a French name,
    /// those French names must also match. If either French name is absent,
    /// the normalized English identity is sufficient.
    nonisolated func matches(
        _ other: ECCCForecastZoneIdentity
    ) -> Bool {
        guard englishName == other.englishName else {
            return false
        }
        
        switch (frenchName, other.frenchName) {
            case (
                let firstFrenchName?,
                let secondFrenchName?
            ):
            return firstFrenchName == secondFrenchName
            
        default:
            return true
        }
    }
    
    fileprivate static func normalized(
        _ value: String
    ) -> String {
        let normalizedPunctuation = value
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
            .replacingOccurrences(of: "‑", with: "-")
            .replacingOccurrences(of: "’", with: "'")
        
        return normalizedPunctuation
            .folding(
                options: [
                    .caseInsensitive,
                    .diacriticInsensitive,
                    .widthInsensitive
                ],
                locale: Locale(identifier: "en_CA")
            )
            .split { $0.isWhitespace }
            .joined(separator: " ")
            .lowercased(with: Locale(identifier: "en_CA"))
    }
}

nonisolated struct ECCCMeteocodeRegionDescriptor: Hashable, Codable, Sendable {
    let feed: ECCCForecastFeed
    let bulletinCode: String
    let regionCode: String
    let englishName: String
    let frenchName: String?
    
    var identity: ECCCForecastZoneIdentity {
        ECCCForecastZoneIdentity(englishName: englishName, frenchName: frenchName)
    }
    
    /// Gives every descriptor a typed product identity without changing existing behavior.
    var product: ECCCMeteocodeRegionProduct {
        ECCCMeteocodeRegionProduct(bulletinCode: bulletinCode, regionCode: regionCode)
    }
    
    var forecastRegion: ECCCForecastRegion {
        ECCCForecastRegion(
            feed: feed,
            identity: identity,
            name: englishName,
            products: [product]
        )
    }
}

extension Collection
where Element == ECCCMeteocodeRegionDescriptor {
    
    /// Combines Meteocode products that describe the same geographic region.
    nonisolated func forecastRegions() -> [ECCCForecastRegion] {
        let descriptorsByRegionID =
            Dictionary(grouping: self) { descriptor in
                descriptor.forecastRegion.id
            }
        
        return descriptorsByRegionID.values
            .compactMap { descriptors in
                /// Dictionary grouping guarantees a nonempty descriptor array.
                guard let representative =
                        descriptors.min(
                            by: {
                                $0.product.id < $1.product.id
                            }
                        ) else {
                    return nil
                }
                
                let products = Array(
                    Set(descriptors.map(\.product))
                )
                    .sorted { $0.id < $1.id }
                
                return ECCCForecastRegion(
                    feed: representative.feed,
                    identity: representative.identity,
                    name: representative.englishName,
                    products: products
                )
            }
            .sorted { $0.id < $1.id }
    }
}

extension ECCCForecastZoneGeoJSONProperties {
    nonisolated var forecastZoneIdentity: ECCCForecastZoneIdentity {
        ECCCForecastZoneIdentity(englishName: name, frenchName: frenchName)
    }
    
    /// Identifies the meteocode directory containing this zone's forecasts.
    ///
    /// Some ECCC zones carry combined values such as "AB,SK" or "BC,YT".
    /// Every component must resolve to the same region.
    nonisolated var forecastFeed: ECCCForecastFeed {
        get throws {
            let provinceCodes = provinceCode
                .split(separator: ",")
                .map {
                    String($0)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .uppercased()
                }
                .filter { !$0.isEmpty }
            
            guard !provinceCodes.isEmpty else {
                throw ECCCForecastRegionMappingError.unsupportedProvinceCode(provinceCode)
            }
            
            let feeds = try provinceCodes.map {
                code -> ECCCForecastFeed in
                
                switch code {
                case "NL", "NS", "NB", "PE":
                    return .atl
                    
                case "ON":
                    return .ont
                    
                case "AB", "SK", "MB", "NT", "NU":
                    return .pnr
                    
                case "BC", "YT":
                    return .pyr
                    
                case "QC":
                    return .que
                    
                default:
                    throw ECCCForecastRegionMappingError.unsupportedProvinceCode(code)
                }
            }
            
            guard let firstFeed = feeds.first else {
                throw ECCCForecastRegionMappingError.unsupportedProvinceCode(provinceCode)
            }
            
            guard feeds.dropFirst().allSatisfy({
                $0.rawValue == firstFeed.rawValue
            }) else {
                throw ECCCForecastRegionMappingError.incompatibleProvinceCodes(provinceCode)
            }
            
            return firstFeed
        }
    }
}

extension Collection
where Element == ECCCForecastRegion {
    
    /// Find the single aggregated Meteocode region corresponding to
    /// one official GeoJSON forecast.
    nonisolated func matchingRegion(
        for zone: ECCCForecastZoneGeometry
    ) throws -> ECCCForecastRegion {
        let requiredFeed =
            try zone.properties.forecastFeed
        
        let zoneIdentity =
            zone.properties.forecastZoneIdentity
        
        let matches = filter { region in
            region.feed.rawValue ==
            requiredFeed.rawValue &&
            region.identity.matches(zoneIdentity)
        }
        
        guard matches.isEmpty == false else {
            throw ECCCForecastRegionMappingError
                .forecastRegionNotFound(
                    featureID: zone.properties.featureID,
                    feed: requiredFeed,
                    englishName: zone.properties.name
                )
        }
        
        guard matches.count == 1,
              let matchedRegion = matches.first else {
            throw ECCCForecastRegionMappingError
                .ambiguousForecastRegions(
                    featureID: zone.properties.featureID,
                    regionIDs: matches
                        .map(\.id)
                        .sorted()
                )
        }
        
        return matchedRegion
    }
}

extension ECCCForecastZoneGeometry {
    
    /// Joins this zone's validated polygons to its aggregated
    /// Meteocode forecast products.
    nonisolated func forecastRegionGeometry(
        matching regions: [ECCCForecastRegion]
    ) throws -> ECCCForecastRegionGeometry {
        let matchedRegion =
            try regions.matchingRegion(for: self)
        
        return try ECCCForecastRegionGeometry(
            featureID: properties.featureID,
            publicZoneCode: properties.publicZoneCode,
            region: matchedRegion,
            polygons: polygons
        )
    }
}
