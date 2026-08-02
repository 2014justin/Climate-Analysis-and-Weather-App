import Foundation

/// ECCC's description of how a temperature value was produced.
///
/// This remains an extensible string wrapper because ECCC may introduce
/// additional trend descriptions without warning.
nonisolated struct ECCCMeteocodeTemperatureTrend: RawRepresentable, Hashable, Codable, Sendable {
    
    let rawValue: String
    
    init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    static let interpolated = ECCCMeteocodeTemperatureTrend(rawValue: "interpolated")
    
    static let intermediatePoint = ECCCMeteocodeTemperatureTrend(rawValue: "intermediate point")
    
    static let minimum = ECCCMeteocodeTemperatureTrend(rawValue: "min")
    
    static let maximum = ECCCMeteocodeTemperatureTrend(rawValue: "max")
}

/// One native temperature entry from a Meteocode temperature list.
///
/// ECCC normally supplies identical lower and upper limits for its hourly
/// temperatures. Both are preserved because the XML schema allows a range.
nonisolated struct ECCCMeteocodeTemperatureReading: Hashable, Codable, Sendable {
    
    let validStart: Date
    let validEnd: Date
    let trend: ECCCMeteocodeTemperatureTrend?
    
    let lowerLimitCelsius: Double?
    let upperLimitCelsius: Double?
    
    /// A single representative value used when converting the native
    /// Meteocode reading into a provider-neutral forecast.
    var representativeCelsius: Double? {
        let usableLimits = [
            usableTemperature(lowerLimitCelsius),
            usableTemperature(upperLimitCelsius)
        ]
            .compactMap { $0 }
        
        guard !usableLimits.isEmpty else {
            return nil
        }
        
        return usableLimits.reduce(0.0,+) / Double(usableLimits.count)
    }
    
    /// ECCC uses large negative sentinel values,  commonly -9999,
    /// when a temperature is unavailable
    fileprivate func usableTemperature(
        _ value: Double?
    ) -> Double? {
        guard let value,
              value.isFinite,
              value > -1000.0 else {
            return nil
        }
        
        return value
    }
}

/// Forecast values belonging to one region inside a Meteocode bulletin.
nonisolated struct ECCCMeteocodeRegionForecast: Hashable, Codable, Sendable {
    let regionCode: String
    let englishName: String?
    let frenchName: String?
    
    let airTemperatures: [ECCCMeteocodeTemperatureReading]
    let dewPoints: [ECCCMeteocodeTemperatureReading]
}

/// One parsed ECCC Meteocode document.
///
/// A single bulletin can contain multiple forecast regions. The provider will
/// later select the region matching the station's resolved product metadata.
///
nonisolated struct ECCCMeteocodeForecastDocument: Hashable, Codable, Sendable {
    let bulletinCode: String
    let issuedAt: Date
    let validStart: Date
    let validEnd: Date
    
    let regions: [ECCCMeteocodeRegionForecast]
}
/// One Meteocode forecast segment selected for a resolved geographic region.
///
/// A region may use multiple products with adjoining forecast windows.
/// Keeping the document metadata attached prevents us from losing issuance
/// and validity information while those products are combined.

nonisolated struct ECCCMeteocodeRegionForecastSegment: Hashable, Codable, Sendable {
    
    let product: ECCCMeteocodeRegionProduct
    
    let issuedAt: Date
    let validStart: Date
    let validEnd: Date
    
    let forecast: ECCCMeteocodeRegionForecast
}


nonisolated enum ECCCMeteocodeForecastSelectionError: LocalizedError, Sendable {
    
    case duplicateBulletinCode(String)
    case missingBulletinCode(String)
    
    case missingRegion(
        bulletinCode: String,
        regionCode: String
    )
    
    case duplicateRegion(
        bulletinCode: String,
        regionCode: String
    )
    
    var errorDescription: String? {
        switch self {
        case .duplicateBulletinCode(let bulletinCode):
            return """
                Multiple parsed Meteocode documents identify themselves as \
                bulletin \(bulletinCode)
                """
            
        case .missingBulletinCode(let bulletinCode):
            return """
                The resolved ECCC forecast region requires Meteocode bulletin \
                \(bulletinCode), but that document was not downloaded.
                """
            
        case .missingRegion(
            let bulletinCode,
            let regionCode
        ):
            return """
                Meteocode bulletin \(bulletinCode) does not contain the required \
                forecast region \(regionCode).
                """
            
        case .duplicateRegion(
            let bulletinCode,
            let regionCode
        ):
            return """
                Meteocode bulletin \(bulletinCode) contains multiple definintions \
                for forecast regoin \(regionCode)
                """
        }
    }
}

extension Collection
where Element == ECCCMeteocodeForecastDocument {
    
    /// Selects every native Meteocode segment required by one resolved region.
    nonisolated func forecastSegments(
        for region: ECCCForecastRegion
    ) throws -> [ECCCMeteocodeRegionForecastSegment] {
        let normalizedCode: (String) -> String = {
            $0
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
        }
        
        var documentsByBulletinCode:
            [String: ECCCMeteocodeForecastDocument] = [:]
        
        for document in self {
            let bulletinCode =
            normalizedCode(document.bulletinCode)
            
            guard documentsByBulletinCode[bulletinCode] == nil else {
                throw ECCCMeteocodeForecastSelectionError
                    .duplicateBulletinCode(bulletinCode)
            }
            
            documentsByBulletinCode[bulletinCode] = document
        }
        
        var segments: [ECCCMeteocodeRegionForecastSegment] = []
        segments.reserveCapacity(region.products.count)
        
        for product in region.products {
            let bulletinCode = normalizedCode(product.bulletinCode)
            
            let regionCode = normalizedCode(product.regionCode)
            
            guard let document = documentsByBulletinCode[bulletinCode] else {
                throw ECCCMeteocodeForecastSelectionError
                    .missingBulletinCode(product.bulletinCode)
            }
            
            let matchingRegions =
            document.regions.filter {
                normalizedCode($0.regionCode) == regionCode
            }
            
            guard let regionalForecast =
                    matchingRegions.first else {
                throw ECCCMeteocodeForecastSelectionError
                    .missingRegion(
                        bulletinCode: product.bulletinCode,
                        regionCode: product.regionCode
                    )
            }
            
            guard matchingRegions.count == 1 else {
                throw ECCCMeteocodeForecastSelectionError
                    .duplicateRegion(
                        bulletinCode: product.bulletinCode,
                        regionCode: product.regionCode
                    )
            }
            
            segments.append(
                ECCCMeteocodeRegionForecastSegment(
                    product: product,
                    issuedAt: document.issuedAt,
                    validStart: document.validStart,
                    validEnd: document.validEnd,
                    forecast: regionalForecast
                )
            )
        }
        
        return segments.sorted {
            if $0.validStart != $1.validStart {
                return $0.validStart < $1.validStart
            }
            
            if $0.validEnd != $1.validEnd {
                return $0.validEnd < $1.validEnd
            }
            
            return $0.product.id < $1.product.id
        }
    }
}

/// The complete native Meteocode forecast resolve for one coordinate.
///
/// This is the final ECCC-specific representation before conversion into
/// provider-agnostic ForecastSamples.
nonisolated struct ECCCMeteocodeResolvedRegionForecast: Hashable, Codable, Sendable {
    let region: ECCCForecastRegion
    let segments: [ECCCMeteocodeRegionForecastSegment]
}

/// One merged Meteocode temperature interval.
///
/// Air temperature and dew point may originate in separate XML lists or
/// adjoining bulletin products. This representation joins them by their
/// complete validity interval before provider-neutral conversion.
///
nonisolated struct ECCCMeteocodeMergedTemperatureInterval: Hashable, Codable, Sendable {
    let validStart: Date
    let validEnd: Date
    
    let airTemperatureCelsius: Double?
    let dewPointCelsius: Double?
}

