/// Find the newest bulletin for each Meteocode product, download it,
/// and pass the XML into the parser.

import Foundation

/// One Meteocode XML Document discovered in an ECCC Datamart directory.
/// This represents the document before it is downloaded and parsed.
///
nonisolated fileprivate struct ECCCMeteocodeDatamartDocumentReference: Hashable, Sendable {
    let feed: ECCCForecastFeed
    let bulletinCode: String
    let issueDate: Date
    let isAmendment: Bool
    let url: URL
}

nonisolated enum ECCCMeteocodeDatamartServiceError: LocalizedError, Sendable {
    
    case invalidDirectoryURL(ECCCForecastFeed)
    case invalidDirectoryResponse(ECCCForecastFeed)
    case unexpectedDirectoryStatusCode(
        feed: ECCCForecastFeed,
        statusCode: Int
    )
    case unreadableDirectory(ECCCForecastFeed)
    case noDocuments(ECCCForecastFeed)
    case invalidDocumentResponse(URL)
    case unexpectedDocumentStatusCode(
        url: URL,
        statusCode: Int
    )
    case bulletinCodeMismatch(
        expected: String,
        actual: String,
        url: URL
    )
    case emptyRegionCatalog
    
    var errorDescription: String? {
        switch self {
        case .invalidDirectoryURL(let feed):
            return """
                Could not construct the ECCC Meteocode directory URL \
                for the \(feed.rawValue) feed.
                """
            
        case .invalidDirectoryResponse(let feed):
            return """
                ECCC returned an invalid Meteocode directory response
                for the \(feed.rawValue) feed.
                """
            
        case .unexpectedDirectoryStatusCode(
            let feed,
            let statusCode
        ):
            return """
                ECCC returned HTTP \(statusCode) for the \
                \(feed.rawValue) Meteocode directory.
                """
            
        case .unreadableDirectory(let feed):
            return """
                The ECCC \(feed.rawValue) Meteocode directory listing \
                could not be read as text.
                """
            
        case .noDocuments(let feed):
            return """
                the ECCC \(feed.rawValue) Meteocode directory listing contains \
                no usable XML documents.
                """
            
        case .invalidDocumentResponse(let url):
            return """
                ECCC returned an invalid response for Meteocode \
                document \(url.lastPathComponent).
                """
            
        case .unexpectedDocumentStatusCode(
            let url,
            let statusCode
        ):
            return """
                ECCC returned HTTP \(statusCode) for Meteocode \
                document \(url.lastPathComponent).
                """
        
        case .bulletinCodeMismatch(
            let expected,
            let actual,
            let url
        ):
            return """
            ECCC Meteocode document \(url.lastPathComponent) was listed as bulletin \
            \(expected), but its XML identifies itself as \(actual).
            """
            
        case .emptyRegionCatalog:
            return """
                The downloaded ECCC Meteocode documents produced no \
                usable forecast-region descriptors.
                """
        }
    }
}

nonisolated fileprivate enum ECCCMeteocodeDatamartFilenameParser {
    
    static func documentReference(
        from fileName: String,
        feed: ECCCForecastFeed,
        relativeTo directoryURL: URL,
        referenceDate: Date = Date()
    ) -> ECCCMeteocodeDatamartDocumentReference? {
        
        let filenameComponents = fileName
            .split(separator: ".", omittingEmptySubsequences: false)
            .map(String.init)
        
        guard filenameComponents.count == 6 || filenameComponents.count == 7,
              filenameComponents[0].uppercased() == "TRANSMIT",
              filenameComponents.last?.lowercased() == "xml"
        else {
            return nil
        }
        
        let isAmendment = filenameComponents.count == 7
        
        /// AMD = Amended. An amendment might happen because a storm developed faster than expected, or
        /// temperatures were corrected, or a typo was fixed, or new model guidance came in, etc
        if isAmendment {
            guard filenameComponents[5].uppercased() == "AMD" else {
                return nil
            }
        }
        
        let bulletinCode = filenameComponents[1].uppercased()
        
        /// Make sure the bulletin code exactly follows the format FP + two uppercase letters + two digits,
        /// otherwise, reject this filename.
        guard bulletinCode.range(
            of: #"^FP[A-Z]{2}[0-9]{2}$"#,
            options: .regularExpression
        ) != nil else {
            return nil
        }
        
        guard let month = Int(filenameComponents[2]),
              let day = Int(filenameComponents[3]),
              (1...12).contains(month),
              (1...31).contains(day)
        else {
            return nil
        }
        
        let timeCode = filenameComponents[4].uppercased()
        
        guard timeCode.count == 5,
              timeCode.hasSuffix("Z"),
              let hour = Int(timeCode.prefix(2)),
              let minute = Int(
                timeCode
                    .dropFirst(2)
                    .prefix(2)
              ),
              (0...23).contains(hour),
              (0...59).contains(minute)
        else {
            return nil
        }
        
        /// Filenames are written in UTC, the ECCC might publish something looking like:
        /// TRANSMIT.FPWG12.07.30.0026Z.AMD.xml
        guard let utcTimeZone = TimeZone(secondsFromGMT: 0) else {
            return nil
        }
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utcTimeZone
        
        let referenceYear = calendar.component(
            .year,
            from: referenceDate
        )
        
        let candidateDates = (
            (referenceYear - 1)...(referenceYear + 1)
        ).compactMap { year -> Date? in
            var dateComponents = DateComponents()
            dateComponents.calendar = calendar
            dateComponents.timeZone = utcTimeZone
            dateComponents.year = year
            dateComponents.month = month
            dateComponents.day = day
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            return calendar.date(from: dateComponents)
        }
        
        guard let issueDate = candidateDates.min(
            by: {
                abs($0.timeIntervalSince(referenceDate))
                < abs($1.timeIntervalSince(referenceDate))
            }
        ) else {
            return nil
        }
        
        let documentURL = directoryURL.appendingPathComponent(
            fileName,
            isDirectory: false
        )
        
        guard documentURL.scheme?.lowercased() == "https",
              documentURL.host?.lowercased() == "dd.weather.gc.ca"
        else {
            return nil
        }
        
        return ECCCMeteocodeDatamartDocumentReference(
            feed: feed,
            bulletinCode: bulletinCode,
            issueDate: issueDate,
            isAmendment: isAmendment,
            url: documentURL
        )
    }
}

/// This fileprivate enum has a few functions:
/// -Searches the directory HTML specifically for XML links.
/// -Extracts each filename from its href.
/// -Rejects path-like values instead of blindly trusting the HTML.
/// -Sends each filename through our strict filename parser
/// -Deduplicates
/// -Orders newest bulletins first, with amendments preferred when timestamps match.

nonisolated fileprivate enum ECCCMeteocodeDatamartDirectoryParser {
    static func documentReferences(
        from directoryHTML: String,
        feed: ECCCForecastFeed,
        directoryURL: URL,
        referenceDate: Date = Date()
    ) -> [ECCCMeteocodeDatamartDocumentReference] {
        
        let hrefPattern = #"href\s*=\s*["']([^"'?#]+\.xml)["']"#
        
        guard let regularExpression = try? NSRegularExpression(
            pattern: hrefPattern,
            options: [.caseInsensitive]
        ) else {
            return []
        }
        
        let source = directoryHTML as NSString
        let sourceRange = NSRange(
            location: 0,
            length: source.length
        )
        
        let matches = regularExpression.matches(
            in: directoryHTML,
            range: sourceRange
        )
        
        let documentReferences = matches.compactMap {
            match -> ECCCMeteocodeDatamartDocumentReference? in
            
            guard match.numberOfRanges > 1 else {
                return nil
            }
            
            let hrefRange = match.range(at: 1)
            
            guard hrefRange.location != NSNotFound else {
                return nil
            }
            
            let rawFileName = source.substring(with: hrefRange)
            
            let fileName = rawFileName.removingPercentEncoding ?? rawFileName
            
            guard !fileName.contains("/"),
                  !fileName.contains("\\")
            else {
                return nil
            }
            
            return ECCCMeteocodeDatamartFilenameParser
                .documentReference(
                    from: fileName,
                    feed: feed,
                    relativeTo: directoryURL,
                    referenceDate: referenceDate
                )
        }
        
        return Array(Set(documentReferences)).sorted {
            left,
            right in
            
            if left.issueDate != right.issueDate {
                return left.issueDate > right.issueDate
            }
            
            if left.isAmendment != right.isAmendment {
                return left.isAmendment && !right.isAmendment
            }
            
            if left.bulletinCode != right.bulletinCode {
                return left.bulletinCode < right.bulletinCode
            }
            
            return left.url.absoluteString
                < right.url.absoluteString
        }
    }
}

nonisolated fileprivate struct ECCCMeteocodeDatamartSelectionKey: Hashable, Sendable  {
    let feed: ECCCForecastFeed
    let bulletinCode: String
}

nonisolated fileprivate enum ECCCMeteocodeDatamartDocumentSelector {
    static func newestDocumentReferences(
        from documentReferences: [ECCCMeteocodeDatamartDocumentReference]
    ) -> [ECCCMeteocodeDatamartDocumentReference] {
        var newestDocumentByKey: [
            ECCCMeteocodeDatamartSelectionKey: ECCCMeteocodeDatamartDocumentReference
        ] = [:]
        
        for candidate in documentReferences {
            let key = ECCCMeteocodeDatamartSelectionKey(
                feed: candidate.feed,
                bulletinCode: candidate.bulletinCode
            )
            
            guard let currentDocument = newestDocumentByKey[key] else {
                newestDocumentByKey[key] = candidate
                continue
            }
            
            if shouldPrefer(
                candidate,
                over: currentDocument
            ) {
                newestDocumentByKey[key] = candidate
            }
        }
        
        return newestDocumentByKey.values.sorted {
            left,
            right in
            
            if left.feed != right.feed {
                return left.feed.rawValue
                    < right.feed.rawValue
            }
            
            return left.bulletinCode
                < right.bulletinCode
        }
    }
    
    fileprivate static func shouldPrefer(
        _ candidate: ECCCMeteocodeDatamartDocumentReference,
        over currentDocument: ECCCMeteocodeDatamartDocumentReference
    ) -> Bool {
        if candidate.issueDate != currentDocument.issueDate {
            return candidate.issueDate > currentDocument.issueDate
        }
        
        if candidate.isAmendment != currentDocument.isAmendment {
            return candidate.isAmendment
        }
        
        return candidate.url.absoluteString > currentDocument.url.absoluteString
    }
}

actor ECCCMeteocodeDatamartService {
    fileprivate let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    fileprivate func newestDocumentReferences(
        for feed: ECCCForecastFeed,
        referenceDate: Date = Date()
    ) async throws -> [ECCCMeteocodeDatamartDocumentReference] {
        let directoryURL = try Self.directoryURL(for: feed)
        
        var request = URLRequest(
            url: directoryURL,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 30
        )
        
        request.setValue("Weather & Climate Atlas Swift App v1.53b", forHTTPHeaderField: "User-Agent")
        
        request.setValue("text/html, application/xhtml+xml", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ECCCMeteocodeDatamartServiceError.invalidDirectoryResponse(feed)
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ECCCMeteocodeDatamartServiceError.unexpectedDirectoryStatusCode(
                feed: feed,
                statusCode: httpResponse.statusCode
            )
        }
        
        guard let directoryHTML =
                String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1)
        else {
            throw ECCCMeteocodeDatamartServiceError.unreadableDirectory(feed)
        }
        
        let references =
            ECCCMeteocodeDatamartDirectoryParser.documentReferences(
                from: directoryHTML,
                feed: feed,
                directoryURL: directoryURL,
                referenceDate: referenceDate
            )
        
        let newestReferences =
            ECCCMeteocodeDatamartDocumentSelector.newestDocumentReferences(from: references)
        
        guard !newestReferences.isEmpty else {
            throw ECCCMeteocodeDatamartServiceError.noDocuments(feed)
        }
        
        return newestReferences
    }
    
    fileprivate func downloadDocument(
        _ documentReference: ECCCMeteocodeDatamartDocumentReference
    ) async throws -> Data {
        let documentURL = documentReference.url
        
        var request = URLRequest(url: documentURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        
        request.setValue("Weather & Climate Atlas Swift App v1.53b", forHTTPHeaderField: "User-Agent")
        
        request.setValue("application/xml, text/xml", forHTTPHeaderField: "Accept")
        
        let (data, response) =
            try await session.data(for: request)
        
        guard let httpResponse =
                response as? HTTPURLResponse else {
            throw ECCCMeteocodeDatamartServiceError.invalidDocumentResponse(documentURL)
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ECCCMeteocodeDatamartServiceError
                .unexpectedDocumentStatusCode(url: documentURL, statusCode: httpResponse.statusCode)
        }
        
        return data
    }
    
    func forecastDocuments(
        for feed: ECCCForecastFeed,
        referenceDate: Date = Date()
    ) async throws -> [ECCCMeteocodeForecastDocument] {
        let documentReferences =
            try await newestDocumentReferences(
                for: feed,
                referenceDate: referenceDate
            )
        
        var documents: [ECCCMeteocodeForecastDocument] = []
        documents.reserveCapacity(documentReferences.count)
        
        for documentReference in documentReferences {
            try Task.checkCancellation()
            
            let documentData =
                try await downloadDocument(documentReference)
            
            let document =
                try ECCCMeteocodeForecastXMLParser.document(
                    from: documentData
                )
            
            guard document.bulletinCode.caseInsensitiveCompare(
                documentReference.bulletinCode
            ) == .orderedSame else {
                throw ECCCMeteocodeDatamartServiceError
                    .bulletinCodeMismatch(
                        expected: documentReference.bulletinCode,
                        actual: document.bulletinCode,
                        url: documentReference.url
                    )
            }
            
            documents.append(document)
        }
        
        return documents.sorted {
            if $0.bulletinCode != $1.bulletinCode {
                return $0.bulletinCode < $1.bulletinCode
            }
            
            return $0.issuedAt < $1.issuedAt
        }
    }
    
    func regionDescriptors(
        for feed: ECCCForecastFeed,
        referenceDate: Date = Date()
    ) async throws -> [ECCCMeteocodeRegionDescriptor] {
        let documentReferences =
            try await newestDocumentReferences(for: feed, referenceDate: referenceDate)
        
        var descriptorsByProductID:
            [String: ECCCMeteocodeRegionDescriptor] = [:]
        
        for documentReference in documentReferences {
            try Task.checkCancellation()
            
            let documentData =
                try await downloadDocument(documentReference)
            
            let documentDescriptors =
                try ECCCMeteocodeRegionXMLParser.descriptors(from: documentData, feed: feed)
            
            for descriptor in documentDescriptors {
                let productID = [
                    descriptor.feed.rawValue,
                    descriptor.product.id
                ]
                    .joined(separator: ":")
                
                if let existingDescriptor =
                    descriptorsByProductID[productID],
                   existingDescriptor != descriptor {
                    throw ECCCMeteocodeRegionXMLParserError
                        .duplicateRegionCode(
                            bulletinCode: descriptor.bulletinCode,
                            regionCode: descriptor.regionCode
                        )
                }
                
                descriptorsByProductID[productID] = descriptor
            }
        }
        
        let descriptors =
            descriptorsByProductID.values.sorted {
                firstDescriptor, secondDescriptor in
                
                if firstDescriptor.bulletinCode !=
                    secondDescriptor.bulletinCode {
                    return firstDescriptor.bulletinCode <
                        secondDescriptor.bulletinCode
                }
                
                return firstDescriptor.regionCode <
                    secondDescriptor.regionCode
            }
        
        guard !descriptors.isEmpty else {
            throw ECCCMeteocodeDatamartServiceError.emptyRegionCatalog
        }
        
        return descriptors
    }
    
    /// Downloads and groups Meteocode descriptors into geographic regions.
    ///
    /// A returned region may contain multiple forecast products whose
    /// valid-time windows form one continuous public forecast.
    func forecastRegions(
        for feed: ECCCForecastFeed,
        referenceDate: Date = Date()
    ) async throws -> [ECCCForecastRegion] {
        let descriptors = try await regionDescriptors(for: feed, referenceDate: referenceDate)
        
        return descriptors.forecastRegions()
    }
    
    nonisolated fileprivate static func directoryURL(
        for feed: ECCCForecastFeed
    ) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "dd.weather.gc.ca"
        components.path =
            "/today/meteocode/\(feed.rawValue)/cmml/"
        
        guard let url = components.url else {
            throw ECCCMeteocodeDatamartServiceError.invalidDirectoryURL(feed)
        }
        
        return url
    }
}
