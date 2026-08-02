import Foundation

nonisolated enum ECCCMeteocodeForecastXMLParserError: LocalizedError, Sendable {
    
    case parsingFailed(String)
    case missingBulletinCode
    case missingIssuedAt
    case missingValidityWindow
    case malformedDate(String)
    case incompleteRegion
    case incompleteTemperatureReading
    case duplicateRegionCode(String)
    case emptyForecastDocument(String)
    
    var errorDescription: String? {
        switch self {
        case .parsingFailed(let message):
            return """
                ECCC Meteocode forecast XML parsing failed: \(message)
                """
            
        case .missingBulletinCode:
            return """
                The Meteocode forecast document contains no bulletin code.
                """
            
        case .missingIssuedAt:
            return """
                The Meteocode forecast document contains no valid issue time.
                """
            
        case .missingValidityWindow:
            return """
                The Meteocode forecast document contains no valid forecast window.
                """
            
        case .malformedDate(let value):
            return """
                The Meteocode forecast document contains an invalid date: \(value).
                """
            
        case .incompleteRegion:
            return """
                A Meteocode forecast region is missing its region code.
                """
            
        case .incompleteTemperatureReading:
            return """
                A Meteocode temperature reading is missing its valid-time window.
                """
            
        case .duplicateRegionCode(let regionCode):
            return """
                The Meteocode forecast document contains conflicting forecasts
                for region \(regionCode).
                """
            
        case .emptyForecastDocument(let bulletinCode):
            return """
                Meteocode bulletin \(bulletinCode) contains no usable regional \
                forecasts.
                """
        }
    }
}

nonisolated enum ECCCMeteocodeForecastXMLParser {
    
    static func document(
        from data: Data
    ) throws -> ECCCMeteocodeForecastDocument {
        
        let delegate =
            ECCCMeteocodeForecastXMLParserDelegate()
        
        let parser = XMLParser(data: data)
            parser.delegate = delegate
        
        guard parser.parse() else {
            throw ECCCMeteocodeForecastXMLParserError
                .parsingFailed(
                    parser.parserError?
                        .localizedDescription
                    ?? "Unknown XML parsing error."
                )
        }
        
        return try delegate.validatedDocument()
    }
}

nonisolated fileprivate enum ECCCMeteocodeForecastDateParser {
    
    static func date(
        from rawValue: String
    ) -> Date? {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !value.isEmpty else {
            return nil
        }
        
        let formatter = ISO8601DateFormatter()
        
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        
        if let date = formatter.date(from: value) {
            return date
        }
        
        formatter.formatOptions = [
            .withInternetDateTime
        ]
        
        return formatter.date(from: value)
    }
}

nonisolated fileprivate enum ECCCMeteocodeTemperatureListKind {
    case air
    case dewPoint
}

nonisolated fileprivate final class
ECCCMeteocodeForecastXMLParserDelegate: NSObject, XMLParserDelegate {
    
    /// Document metadata
    fileprivate var bulletinCode: String?
    fileprivate var issuedAt: Date?
    fileprivate var validStart: Date?
    fileprivate var validEnd: Date?
    
    /// General XML state
    ///
    fileprivate var currentText = ""
    fileprivate var validationError: ECCCMeteocodeForecastXMLParserError?
    
    /// Regional forecast state
    fileprivate var isInsideMeteocodeForecast = false
    fileprivate var isInsideLocation = false
    
    fileprivate var currentNameLanguage: String?
    fileprivate var currentRegionCode: String?
    fileprivate var currentEnglishName: String?
    fileprivate var currentFrenchName: String?
    
    fileprivate var currentAirTemperatures: [ECCCMeteocodeTemperatureReading] = []
    
    fileprivate var currentDewPoints: [ECCCMeteocodeTemperatureReading] = []
    
    /// Temperature-list state
    fileprivate var currentTemperatureListKind: ECCCMeteocodeTemperatureListKind?
    
    fileprivate var isInsideTemperatureValue = false
    fileprivate var currentReadingStartText: String?
    fileprivate var currentReadingEndText: String?
    fileprivate var currentReadingTrend: ECCCMeteocodeTemperatureTrend?
    
    fileprivate var currentLowerLimitCelsius: Double?
    fileprivate var currentUpperLimitCelsius: Double?
    
    /// Completed results
    fileprivate var regionsByCode:
        [String: ECCCMeteocodeRegionForecast] = [:]
    
    fileprivate func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentText = ""
        
        guard validationError == nil else {
            return
        }
        
        switch elementName {
        case "meteocode-forecast":
            isInsideMeteocodeForecast = true
            
            currentRegionCode = nil
            currentEnglishName = nil
            currentFrenchName = nil
            
            currentAirTemperatures.removeAll(keepingCapacity: true)
            
            currentDewPoints.removeAll(keepingCapacity: true)
            
        case "location":
            guard isInsideMeteocodeForecast else {
                return
            }
            
            isInsideLocation = true
            currentRegionCode = nil
            currentEnglishName = nil
            currentFrenchName = nil
            
        case "msc-zone-name":
            guard isInsideLocation else {
                return
            }
            
            currentNameLanguage =
                attributeDict["lang"]?.lowercased()
            
        case "temperature-list":
            guard isInsideMeteocodeForecast else {
                return
            }
            
            let units =
                attributeDict["units"]?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                ?? "celsius"
            
            guard units == "celsius" else {
                currentTemperatureListKind = nil
                return
            }
            
            switch attributeDict["type"]?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased() {
                
            case "air":
                currentTemperatureListKind = .air
                
            case "dew-point":
                currentTemperatureListKind = .dewPoint
                
            default:
                currentTemperatureListKind = nil
            }
            
        case "temperature-value":
            guard currentTemperatureListKind != nil else {
                return
            }
            
            isInsideTemperatureValue = true
            
            currentReadingStartText = attributeDict["start"]
            
            currentReadingEndText = attributeDict["end"]
            
            if let trend = attributeDict["trend"]?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased(),
               !trend.isEmpty {
                
                currentReadingTrend =
                    ECCCMeteocodeTemperatureTrend(rawValue: trend)
            } else {
                currentReadingTrend = nil
            }
            
            currentLowerLimitCelsius = nil
            currentUpperLimitCelsius = nil
                
            
        default:
            break
        }
    }
    
    fileprivate func parser(
        _ parser: XMLParser,
        foundCharacters string: String
    ) {
        currentText.append(string)
    }
    
    fileprivate func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let value =
            currentText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard validationError == nil else {
            currentText = ""
            return
        }

        switch elementName {
        case "title":
            if bulletinCode == nil,
               !value.isEmpty {
                bulletinCode = value
            }

        case "current-issue":
            if !value.isEmpty {
                if let date =
                    ECCCMeteocodeForecastDateParser.date(
                        from: value
                    ) {
                    issuedAt = date
                } else {
                    validationError = .malformedDate(value)
                }
            }

        case "valid-begin-time":
            if !value.isEmpty {
                if let date =
                    ECCCMeteocodeForecastDateParser.date(
                        from: value
                    ) {
                    validStart = date
                } else {
                    validationError = .malformedDate(value)
                }
            }

        case "valid-end-time":
            if !value.isEmpty {
                if let date =
                    ECCCMeteocodeForecastDateParser.date(
                        from: value
                    ) {
                    validEnd = date
                } else {
                    validationError = .malformedDate(value)
                }
            }
            
        case "msc-zone-code":
            if isInsideLocation,
               !value.isEmpty {
                currentRegionCode = value
            }
            
        case "msc-zone-name":
            if isInsideLocation,
               !value.isEmpty {
                switch currentNameLanguage {
                case "en":
                    currentEnglishName = value
                case "fr":
                    currentFrenchName = value
                    
                default:
                    break
                }
            }
            
            currentNameLanguage = nil
        case "lower-limit":
            if isInsideTemperatureValue,
               !value.isEmpty {
                currentLowerLimitCelsius = Double(value)
            }
            
        case "upper-limit":
            if isInsideTemperatureValue,
               !value.isEmpty {
                currentUpperLimitCelsius = Double(value)
            }
            
        case "temperature-value":
            if isInsideTemperatureValue {
                appendCurrentTemperatureReading()
            }
            
        case "temperature-list":
            currentTemperatureListKind = nil
            
        case "location":
            isInsideLocation = false
            currentNameLanguage = nil
            
        case "meteocode-forecast":
            if isInsideMeteocodeForecast {
                appendCurrentRegion()
            }

        default:
            break
        }

        currentText = ""
    }
    
    fileprivate func appendCurrentTemperatureReading() {
        defer {
            isInsideTemperatureValue = false
            currentReadingStartText = nil
            currentReadingEndText = nil
            currentReadingTrend = nil
            currentLowerLimitCelsius = nil
            currentUpperLimitCelsius = nil
        }
        
        guard validationError == nil else {
            return
        }
        
        guard let currentTemperatureListKind,
              let currentReadingStartText,
              let currentReadingEndText
        else {
            validationError = .incompleteTemperatureReading
            return
        }
        
        guard let validStart =
                ECCCMeteocodeForecastDateParser.date(from: currentReadingStartText)
        else {
            validationError = .malformedDate(currentReadingStartText)
            return
        }
        
        guard let validEnd =
                ECCCMeteocodeForecastDateParser.date(from: currentReadingEndText)
        else {
            validationError = .malformedDate(currentReadingEndText)
            return
        }
        
        let reading = ECCCMeteocodeTemperatureReading(
            validStart: validStart,
            validEnd: validEnd,
            trend: currentReadingTrend,
            lowerLimitCelsius: currentLowerLimitCelsius,
            upperLimitCelsius: currentUpperLimitCelsius
        )
        
        switch currentTemperatureListKind {
        case .air:
            currentAirTemperatures.append(reading)
            
        case .dewPoint:
            currentDewPoints.append(reading)
        }
    }
    
    /// Validates the zone code, requires an actual air-temperature timeline. Sorts reading chronologically, detects
    /// conflicting duplicate regions, stores the completed region, clears all temporary regional state through defer.
    fileprivate func appendCurrentRegion() {
        defer {
            isInsideMeteocodeForecast = false
            isInsideLocation = false
            
            currentRegionCode = nil
            currentEnglishName = nil
            currentFrenchName = nil
            currentNameLanguage = nil
            
            currentAirTemperatures.removeAll(keepingCapacity: true)
            
            currentDewPoints.removeAll(keepingCapacity: true)
            
            currentTemperatureListKind = nil
        }
        
        guard validationError == nil else {
            return
        }
        
        guard let rawRegionCode = currentRegionCode else {
            validationError = .incompleteRegion
            return
        }
        
        let regionCode =
            rawRegionCode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !regionCode.isEmpty else {
            validationError = .incompleteRegion
            return
        }
        
        /// Ignore a region that contains no usable air-temperature timeline.
        guard !currentAirTemperatures.isEmpty else {
            return
        }
        
        let region = ECCCMeteocodeRegionForecast(
            regionCode: regionCode,
            englishName: currentEnglishName,
            frenchName: currentFrenchName,
            airTemperatures: currentAirTemperatures.sorted {
                $0.validStart < $1.validStart
            },
            dewPoints: currentDewPoints.sorted {
                $0.validStart < $1.validStart
            }
        )
        
        if let existingRegion = regionsByCode[regionCode],
           existingRegion != region {
            validationError = .duplicateRegionCode(regionCode)
            return
        }
        
        regionsByCode[regionCode] = region
        
    }
    
    fileprivate func validatedDocument() throws -> ECCCMeteocodeForecastDocument {
        
        if let validationError {
            throw validationError
        }
        
        guard let rawBulletinCode = bulletinCode else {
            throw ECCCMeteocodeForecastXMLParserError.missingBulletinCode
        }
        
        let bulletinCode =
            rawBulletinCode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !bulletinCode.isEmpty else {
            throw ECCCMeteocodeForecastXMLParserError.missingBulletinCode
        }
        
        guard let issuedAt else {
            throw ECCCMeteocodeForecastXMLParserError.missingIssuedAt
        }
        
        guard let validStart,
              let validEnd,
              validEnd >= validStart
        else {
            throw ECCCMeteocodeForecastXMLParserError.missingValidityWindow
        }
        
        let regions =
            regionsByCode.values.sorted {
                $0.regionCode < $1.regionCode
            }
        
        guard !regions.isEmpty else {
            throw ECCCMeteocodeForecastXMLParserError.emptyForecastDocument(bulletinCode)
        }
        
        return ECCCMeteocodeForecastDocument(
            bulletinCode: bulletinCode,
            issuedAt: issuedAt,
            validStart: validStart,
            validEnd: validEnd,
            regions: regions
        )
    }
}
