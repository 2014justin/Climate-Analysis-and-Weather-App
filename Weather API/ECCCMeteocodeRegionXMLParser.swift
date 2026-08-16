/// Answers "What region does this bulletin cover?"
/// Parses only the location blocks of a bulletin XML: msx-zone-code + msc zone-name and the document.
/// Output [ECCCMeteocodeRegionDescriptor] = (feed, bulletinCode, regionCode, englishName, frenchName). No temperatures.
/// Strict guards: missing title, a location missing code/name, a region code defined twice with conflicting names
/// How the app learns which bulletin covers which region.

import Foundation

nonisolated enum ECCCMeteocodeRegionXMLParserError: LocalizedError, Sendable {
    
    case parsingFailed(String)
    case missingBulletinCode
    case incompleteLocation
    case duplicateRegionCode(
        bulletinCode: String,
        regionCode: String
    )
    case emptyRegionCatalog(
        bulletinCode: String
    )
    
    var errorDescription: String? {
        switch self {
        case .parsingFailed(let message):
            return """
                ECCC Meteocode XML parsing failed: \(message)
                """
            
        case .missingBulletinCode:
            return """
                The ECCC Meteocode document contains no bulletin title.
                """
            
        case .incompleteLocation:
            return """
                An ECCC Meteocode location is missing its region code \
                or English forecast-zone name.
                """
            
        case .duplicateRegionCode(
            let bulletinCode,
            let regionCode
        ):
            return """
                ECCC bulletin \(bulletinCode) contains conflicting \
                definitions for region \(regionCode).
                """
            
        case .emptyRegionCatalog(let bulletinCode):
            return """
                ECCC bulletin \(bulletinCode) contains no usable \
                forecast-region declarations.
                """
            
        }
    }
}

nonisolated enum ECCCMeteocodeRegionXMLParser {
    
    static func descriptors(
        from data: Data,
        feed: ECCCForecastFeed
    ) throws -> [ECCCMeteocodeRegionDescriptor] {
        let delegate =
            ECCCMeteocodeRegionXMLParserDelegate(feed: feed)
        
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        
        guard parser.parse() else {
            throw ECCCMeteocodeRegionXMLParserError
                .parsingFailed(
                    parser.parserError?
                        .localizedDescription ?? "Unknown XML parsing error."
                )
        }
        
        return try delegate.validatedDescriptors()
    }
}
/// Read XML. -> Collect Region Names -> Return Descriptors
nonisolated fileprivate final class
ECCCMeteocodeRegionXMLParserDelegate: NSObject, XMLParserDelegate {
    
    fileprivate let feed: ECCCForecastFeed
    fileprivate var bulletinCode: String?
    
    fileprivate var isInsideLocation = false
    fileprivate var currentText = ""
    fileprivate var currentNameLanguage: String?
    
    fileprivate var currentRegionCode: String?
    fileprivate var currentEnglishName: String?
    fileprivate var currentFrenchName: String?
    
    fileprivate var descriptorsByRegionCode:
        [String: ECCCMeteocodeRegionDescriptor] = [:]
    
    fileprivate var validationError: Error?
    
    fileprivate init(feed: ECCCForecastFeed) {
        self.feed = feed
    }
    
    fileprivate func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentText = ""
        
        if elementName == "location" {
            isInsideLocation = true
            currentRegionCode = nil
            currentEnglishName = nil
            currentFrenchName = nil
        }
        
        if elementName == "msc-zone-name",
           isInsideLocation {
            currentNameLanguage =
                attributeDict["lang"]?.lowercased()
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
        let value = currentText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch elementName {
        case "title":
            if bulletinCode == nil,
               !value.isEmpty {
                bulletinCode = value
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
            
        case "location":
            appendCurrentLocation()
            isInsideLocation = false
            
        default:
            break
        }
        currentText = ""
    }
    
    fileprivate func appendCurrentLocation() {
        guard validationError == nil else {
            return
        }
        
        guard let bulletinCode,
              let currentRegionCode,
              let currentEnglishName else {
            validationError =
            ECCCMeteocodeRegionXMLParserError.incompleteLocation
            
            return
        }
        
        let descriptor =
            ECCCMeteocodeRegionDescriptor(
                feed: feed,
                bulletinCode: bulletinCode,
                regionCode: currentRegionCode,
                englishName: currentEnglishName,
                frenchName: currentFrenchName
            )
        
        if let existing =
            descriptorsByRegionCode[currentRegionCode],
           existing.identity != descriptor.identity {
            validationError =
                ECCCMeteocodeRegionXMLParserError
                    .duplicateRegionCode(bulletinCode: bulletinCode, regionCode: currentRegionCode)
            
            return
        }
        
        descriptorsByRegionCode[currentRegionCode] = descriptor
    }
    
    fileprivate func validatedDescriptors() throws -> [ECCCMeteocodeRegionDescriptor] {
        
        if let validationError {
            throw validationError
        }
        
        guard let bulletinCode else {
            throw ECCCMeteocodeRegionXMLParserError.missingBulletinCode
        }
        
        let descriptors =
            descriptorsByRegionCode.values.sorted {
                $0.regionCode < $1.regionCode
            }
        
        guard !descriptors.isEmpty else {
            throw ECCCMeteocodeRegionXMLParserError
                .emptyRegionCatalog(bulletinCode: bulletinCode)
        }
        
        return descriptors
    }
    
}
