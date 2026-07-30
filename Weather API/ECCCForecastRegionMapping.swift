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
    
    var forecastRegion: ECCCForecastRegion {
        ECCCForecastRegion(
            feed: feed,
            bulletinCode: bulletinCode,
            regionCode: regionCode,
            name: englishName
        )
    }
}

extension ECCCForecastZoneGeoJSONProperties {
    nonisolated var forecastZoneIdentity: ECCCForecastZoneIdentity {
        
        ECCCForecastZoneIdentity(
            englishName: name,
            frenchName: frenchName
        )
    }
}
