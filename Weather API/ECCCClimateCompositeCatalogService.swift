import Foundation

/// Answers the one question: Can I load a valid official ECCC composite catalog?
/// Loads, validates, and geographically searches the bundled catalog.
/// 
enum ECCCClimateCompositeCatalogServiceError:
    LocalizedError {

    case resourceNotFound(String)

    case invalidCatalog(String)
    
    case invalidSearchArea

    case unsupportedSchemaVersion(Int)

    case unsupportedNormalPeriod(
        startYear: Int,
        endYear: Int
    )

    var errorDescription: String? {
        switch self {
        case .resourceNotFound(let resourceName):
            return """
                The bundled ECCC composite catalog \
                \(resourceName).json could not be found.
                """

        case .invalidCatalog(let reason):
            return """
                The bundled ECCC composite catalog \
                is invalid: \(reason)
                """
            
        case .invalidSearchArea:
            return """
                The ECCC composite search coordinate \
                or radius is invalid.
                """

        case .unsupportedSchemaVersion(let version):
            return """
                ECCC composite catalog schema version \
                \(version) is not supported.
                """

        case .unsupportedNormalPeriod(
            let startYear,
            let endYear
        ):
            return """
                ECCC composite catalog normal period \
                \(startYear)-\(endYear) is not supported.
                """
        }
    }
}

struct ECCCClimateCompositeMatch: Identifiable, Hashable, Sendable {
    
    let composite: ECCCClimateComposite
    
    let distanceMiles: Double
    
    var id: String {
        composite.id
    }
}

struct ECCCClimateCompositeCatalogService {

    static let supportedSchemaVersion = 1

    static let expectedNormalStartYear = 1991

    static let expectedNormalEndYear = 2020

    private let bundle: Bundle

    nonisolated init(bundle: Bundle = .main) {
        self.bundle = bundle
    }
    
    /// Loads and validates the bundled catalog.
    func composite(
        withCanonicalIdentifier rawIdentifier: String
    ) throws -> ECCCClimateComposite? {
        let catalog = try loadCatalog()
        
        return composite(
            in: catalog,
            withCanonicalIdentifier: rawIdentifier
        )
    }
    
    /// Performs a pure in-memory lookup, making it independently testable and reusable without forcing another file read.
    func composite(
        in catalog: ECCCClimateCompositeCatalog,
        withCanonicalIdentifier rawIdentifier: String
    ) -> ECCCClimateComposite? {
        
        let safeIdentifier = rawIdentifier
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        
        guard safeIdentifier.isEmpty == false else {
            return nil
        }
        
        return catalog.composites.first { composite in
            composite
                .canonicalClimateIdentifier
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
                == safeIdentifier
        }
    }
    
    func findNearbyComposites(
        latitude: Double,
        longitude: Double,
        radiusMiles: Double = 100.0
    ) throws -> [ECCCClimateCompositeMatch] {
        
        let catalog = try loadCatalog()
        
        return try findNearbyComposites(
            in: catalog,
            latitude: latitude,
            longitude: longitude,
            radiusMiles: radiusMiles
        )
    }
    
    func findNearbyComposites(
        in catalog: ECCCClimateCompositeCatalog,
        latitude: Double,
        longitude: Double,
        radiusMiles: Double = 100.0
    ) throws -> [ECCCClimateCompositeMatch] {
        
        let sourceCoordinate =
            GeographicCoordinate(
                latitude: latitude,
                longitude: longitude
            )
        
        guard sourceCoordinate.isValid,
              radiusMiles.isFinite,
              radiusMiles > 0.0 else {
            throw ECCCClimateCompositeCatalogServiceError
                .invalidSearchArea
        }
        
        return catalog.composites
            .compactMap {
                composite
                -> ECCCClimateCompositeMatch? in
                
                guard let distanceMiles =
                        GeodesicDistance.miles(
                            from: sourceCoordinate,
                            to: composite.coordinate
                        ),
                      distanceMiles <= radiusMiles else {
                    return nil
                }
                
                return ECCCClimateCompositeMatch(
                    composite: composite,
                    distanceMiles: distanceMiles
                )
            }
            .sorted {
                firstMatch,
                secondMatch in
                
                if firstMatch.distanceMiles
                    != secondMatch.distanceMiles {
                    return firstMatch.distanceMiles < secondMatch.distanceMiles
                }
                
                return firstMatch.composite
                    .canonicalClimateIdentifier
                    < secondMatch.composite
                    .canonicalClimateIdentifier
                    
            }
    }

    func loadCatalog(
        resourceName: String =
            "ECCCClimateComposites"
    ) throws -> ECCCClimateCompositeCatalog {

        guard let resourceURL =
                bundle.url(
                    forResource: resourceName,
                    withExtension: "json"
                ) else {
            throw ECCCClimateCompositeCatalogServiceError
                .resourceNotFound(resourceName)
        }

        do {
            let data = try Data(
                contentsOf: resourceURL
            )

            return try decodeCatalog(
                from: data
            )
        } catch let catalogError
                    as ECCCClimateCompositeCatalogServiceError {
            throw catalogError
        } catch {
            throw ECCCClimateCompositeCatalogServiceError
                .invalidCatalog(
                    error.localizedDescription
                )
        }
    }

    func decodeCatalog(
        from data: Data
    ) throws -> ECCCClimateCompositeCatalog {

        let catalog: ECCCClimateCompositeCatalog

        do {
            catalog = try JSONDecoder().decode(
                ECCCClimateCompositeCatalog.self,
                from: data
            )
        } catch {
            throw ECCCClimateCompositeCatalogServiceError
                .invalidCatalog(
                    error.localizedDescription
                )
        }

        try validate(catalog)

        return catalog
    }

    private func validate(
        _ catalog: ECCCClimateCompositeCatalog
    ) throws {

        guard catalog.schemaVersion ==
                Self.supportedSchemaVersion else {
            throw ECCCClimateCompositeCatalogServiceError
                .unsupportedSchemaVersion(
                    catalog.schemaVersion
                )
        }

        guard catalog.normalPeriodStartYear ==
                Self.expectedNormalStartYear,
              catalog.normalPeriodEndYear ==
                Self.expectedNormalEndYear else {
            throw ECCCClimateCompositeCatalogServiceError
                .unsupportedNormalPeriod(
                    startYear:
                        catalog.normalPeriodStartYear,
                    endYear:
                        catalog.normalPeriodEndYear
                )
        }

        guard catalog.composites.isEmpty == false else {
            throw ECCCClimateCompositeCatalogServiceError
                .invalidCatalog(
                    "The catalog contains no composites."
                )
        }

        var identifiers = Set<String>()

        for composite in catalog.composites {
            let identifier =
                composite
                    .canonicalClimateIdentifier
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

            guard identifier.isEmpty == false else {
                throw ECCCClimateCompositeCatalogServiceError
                    .invalidCatalog(
                        "A composite has an empty identifier."
                    )
            }

            guard identifiers.insert(identifier).inserted else {
                throw ECCCClimateCompositeCatalogServiceError
                    .invalidCatalog(
                        "Duplicate composite identifier: "
                        + identifier
                    )
            }

            guard composite.coordinate.isValid else {
                throw ECCCClimateCompositeCatalogServiceError
                    .invalidCatalog(
                        "Composite \(identifier) has invalid coordinates."
                    )
            }

            try validate(
                composite.maximumTemperatureThread,
                expectedElement:
                    .dailyMaximumTemperature,
                compositeIdentifier: identifier
            )

            try validate(
                composite.minimumTemperatureThread,
                expectedElement:
                    .dailyMinimumTemperature,
                compositeIdentifier: identifier
            )
        }
    }

    private func validate(
        _ thread: ECCCClimateElementThread,
        expectedElement: ECCCClimateElement,
        compositeIdentifier: String
    ) throws {

        guard thread.element == expectedElement else {
            throw ECCCClimateCompositeCatalogServiceError
                .invalidCatalog(
                    "Composite \(compositeIdentifier) "
                    + "contains a mismatched climate element."
                )
        }

        guard thread.segments.isEmpty == false else {
            throw ECCCClimateCompositeCatalogServiceError
                .invalidCatalog(
                    "Composite \(compositeIdentifier) "
                    + "contains an empty station thread."
                )
        }

        for segment in thread.segments {
            guard segment.climateIdentifier
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty == false else {
                throw ECCCClimateCompositeCatalogServiceError
                    .invalidCatalog(
                        "Composite \(compositeIdentifier) "
                        + "contains an empty station identifier."
                    )
            }

            guard segment.normalStartDate <=
                    segment.normalEndDate else {
                throw ECCCClimateCompositeCatalogServiceError
                    .invalidCatalog(
                        "Composite \(compositeIdentifier) "
                        + "contains reversed segment dates."
                    )
            }
        }
    }
}
