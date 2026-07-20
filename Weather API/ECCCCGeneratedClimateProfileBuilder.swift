/// Actually builds the climate profile. Will tell us what the fourier fit order is, RMSE, all the good
/// stuff.

import Foundation

enum ECCCGeneratedClimateProfileBuilderError: LocalizedError {
    
    case invalidStationIdentifier
    case noClimateStationThread(String)
    
    case ambiguousClimateStationThreads(
        String,
        Int
    )
    
    case noDailyObservations(String)
    
    case timeZoneUnavailable(String)
    
    case selectedClimateStationNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidStationIdentifier:
            return """
                The Canadian aviation station \
                identifier is empty.
                """
            
        case .noClimateStationThread(
            let stationID
        ):
            return """
                No ECCC climate-station thread \
                was found for \(stationID).
                """
            
        case .ambiguousClimateStationThreads(
            let stationID,
            let count
        ):
            return """
                ECCC returned \(count) \
                climate-station threads for \
                \(stationID)
                """
            
        case .noDailyObservations(
            let stationID
        ):
            return """
                ECCC returned no 1991-2020 \
                daily observations for \
                \(stationID)
                """
        case .timeZoneUnavailable(
            let stationID
        ):
            return """
                No Canadian time zone could be resolved \
                for \(stationID).
                """
            
        case .selectedClimateStationNotFound(
            let climateStationID
        ):
            return """
                The selected Canadian climate-station \
                thread \(climateStationID) could not be found.
                """
        }
    }
}

enum ECCCGeneratedClimateProfileBuilder {
    static let normalStartYear = 1991
    static let normalEndYear = 2020
    
    private struct SourceStationContext {
        let aviationStationID: String
        let displayName: String
        let coordinate: GeographicCoordinate
        let elevationMeters: Double?
        let provinceCode: String
        let timeZoneIdentifier: String
    }
    
    private static func resolveSourceStation(
        aviationStationID: String,
        catalogService: ECCCClimateStationCatalogService,
        timeZoneResolver: AtlasStationTimeZoneResolver,
        progress:
            (@MainActor (String) -> Void)?
        
    ) async throws -> SourceStationContext {
        
        let safeStationID = aviationStationID
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        
        guard safeStationID.isEmpty == false else {
            throw ECCCGeneratedClimateProfileBuilderError
                .invalidStationIdentifier
        }
        
        progress?(
            "Resolving Canadian aviation station..."
        )
        let sourceRecords =
            try await catalogService
                .fetchStations(
                    forAviationStationID: safeStationID
                )
        
        let sourceThreads =
            ECCCClimateStationThreadBuilder
                .threads(from: sourceRecords)
        
        guard sourceThreads.isEmpty == false else {
            throw ECCCGeneratedClimateProfileBuilderError
                .noClimateStationThread(safeStationID)
        }
        
        guard sourceThreads.count == 1,
              let sourceThread =
                sourceThreads.first else {
            throw ECCCGeneratedClimateProfileBuilderError
                .ambiguousClimateStationThreads(
                    safeStationID,
                    sourceThreads.count
                )
        }
        
        let atlasStation = AtlasStation(
            source: AtlasStationSource(
                countryCode: "CA",
                providerID: "aviationWeather",
                stationID: safeStationID
            ),
            name: sourceThread.stationName,
            latitude: sourceThread.coordinate.latitude,
            longitude: sourceThread.coordinate.longitude,
            elevationMeters: sourceThread.elevationMeters,
            networkName: "ECCC",
            tier: .primary,
            administrativeAreaCode: sourceThread.provinceCode,
            displayPriority: nil
        )
        
        guard let timeZone =
                try await timeZoneResolver
                    .timeZone(for: atlasStation) else {
            throw ECCCGeneratedClimateProfileBuilderError
                .timeZoneUnavailable(safeStationID)
        }
        
        return SourceStationContext(
            aviationStationID: safeStationID,
            displayName: sourceThread.stationName,
            coordinate: sourceThread.coordinate,
            elevationMeters: sourceThread.elevationMeters,
            provinceCode: sourceThread.provinceCode,
            timeZoneIdentifier: timeZone.identifier
        )
    }
    
    /// 
    
    /// Add Canadian candidate searching.
    static func findClimateCandidates(
        aviationStationID: String,
        radiusMiles: Double = 100.0,
        maximumCandidateCount: Int = 8,
        catalogService:
            ECCCClimateStationCatalogService =
            ECCCClimateStationCatalogService(),
        threadDailyService:
            ECCCClimateStationThreadDailyService =
            ECCCClimateStationThreadDailyService(),
        timeZoneResolver:
            AtlasStationTimeZoneResolver =
            AtlasStationTimeZoneResolver(),
        progress:
            (@MainActor (String) -> Void)? = nil
    ) async throws
    -> GeneratedClimateCandidateSearchResult {
        
        let normalStartDate = ClimateDate(
            year: normalStartYear,
            month: 1,
            day: 1
        )
        let normalEndDate = ClimateDate(
            year: normalEndYear,
            month: 12,
            day: 31
        )
        
        let sourceContext =
            try await resolveSourceStation(
                aviationStationID: aviationStationID,
                catalogService: catalogService,
                timeZoneResolver: timeZoneResolver,
                progress: progress
            )
        
        let sourceCoordinate = sourceContext.coordinate
        
        progress?("Finding nearby Canadian climate stations...")
        
        let nearbyRecords =
        try await catalogService
            .fetchNearbyStations(
                latitude: sourceCoordinate.latitude,
                longitude: sourceCoordinate.longitude,
                radiusMiles: radiusMiles
            )
        
        let nearbyThreads =
        ECCCClimateStationThreadBuilder
            .threads(from: nearbyRecords)
        
        let rankedThreads =
        nearbyThreads.compactMap {
            thread
            -> (
                thread: ECCCClimateStationThread,
                distanceMiles: Double
            )? in
            
            guard thread.records(
                overlapping: normalStartDate,
                through: normalEndDate
            ).isEmpty == false,
                  let distanceMiles =
                    thread.distanceMiles(from: sourceCoordinate),
                  distanceMiles <= radiusMiles else {
                return nil
            }
            
            return(
                thread: thread,
                distanceMiles: distanceMiles
            )
            
        }
        .sorted {
            firstCandidate,
            secondCandidate in
            
            if firstCandidate.distanceMiles
                != secondCandidate.distanceMiles {
                return firstCandidate.distanceMiles < secondCandidate.distanceMiles
                
            }
            
            return firstCandidate.thread.id < secondCandidate.thread.id
        }
        
        let threadsToEvaluate = Array(
            rankedThreads.prefix(
                max(0, maximumCandidateCount)
            )
        )
        
        var candidates:
        [GeneratedClimateStationCandidate] = []
        
        for (
            index,
            rankedThread
        ) in threadsToEvaluate.enumerated() {
            
            progress?(
                "Evaluating Canadian climate station "
                + "\(index + 1) of "
                + "\(threadsToEvaluate.count)..."
            )
            
            do {
                let observations =
                try await threadDailyService
                    .fetchObservations(
                        for: rankedThread.thread,
                        startDate: normalStartDate,
                        endDate: normalEndDate
                    )
                
                guard observations.isEmpty == false,
                      let pairedCompleteness =
                        ClimateObservationCompletenessCalculator
                    .pairedCompleteness(
                        observations: observations,
                        startDate: normalStartDate,
                        endDate: normalEndDate
                    ) else {
                    continue
                }
                
                let elevationDifferenceFeet:
                Double?
                
                if let sourceElevationMeters =
                    sourceContext.elevationMeters,
                   let candidateElevationMeters =
                    rankedThread.thread
                    .elevationMeters {
                    
                    elevationDifferenceFeet =
                    abs(sourceElevationMeters - candidateElevationMeters) * 3.280839895
                } else {
                    elevationDifferenceFeet = nil
                }
                
                candidates.append(
                    GeneratedClimateStationCandidate(
                        stationID: rankedThread.thread.id,
                        displayName: rankedThread.thread.stationName,
                        administrativeAreaCode: rankedThread.thread.provinceCode,
                        distanceMiles: rankedThread.distanceMiles,
                        elevationDifferenceFeet: elevationDifferenceFeet,
                        pairedCompleteness: pairedCompleteness
                    )
                )
            } catch {
                continue
            }
        }
        
        candidates.sort {
            firstCandidate,
            secondCandidate in
            
            let firstTier =
            firstCandidate.qualityRating.recommendationTier
            
            let secondTier =
            secondCandidate.qualityRating.recommendationTier
            
            if firstTier != secondTier {
                return firstTier < secondTier
            }
            
            if firstCandidate.distanceMiles
                != secondCandidate.distanceMiles {
                return firstCandidate.distanceMiles < secondCandidate.distanceMiles
            }
            
            return firstCandidate
                .pairedCompleteness
            > secondCandidate
                .pairedCompleteness
        }
        
        let sourceElevationFeet =
            sourceContext.elevationMeters.map {
                $0 * 3.280839895
            }
        
        return GeneratedClimateCandidateSearchResult(
            weatherStationID: sourceContext.aviationStationID,
            displayName: sourceContext.displayName,
            weatherLatitude: sourceContext.coordinate.latitude,
            weatherLongitude: sourceContext.coordinate.longitude,
            weatherElevationFeet: sourceElevationFeet,
            timeZoneIdentifier: sourceContext.timeZoneIdentifier,
            candidates: candidates
        )
    }
        
    static func findOfficialClimateCandidates(
        aviationStationID: String,
        radiusMiles: Double = 100.0,
        maximumCandidateCount: Int = 8,
        sourceCatalogService:
            ECCCClimateStationCatalogService = ECCCClimateStationCatalogService(),
        compositeCatalogService:
            ECCCClimateCompositeCatalogService = ECCCClimateCompositeCatalogService(),
        candidateEvaluator:
            ECCCClimateCompositeCandidateEvaluator = ECCCClimateCompositeCandidateEvaluator(),
        timeZoneResolver:
            AtlasStationTimeZoneResolver = AtlasStationTimeZoneResolver(),
        progress:
            (@MainActor (String) -> Void)? = nil
            
    ) async throws
    -> GeneratedClimateCandidateSearchResult {
        
        let normalStartDate = ClimateDate(
            year: normalStartYear,
            month: 1,
            day: 1
        )
        
        let normalEndDate = ClimateDate(
            year: normalEndYear,
            month: 12,
            day: 31
        )
        
        let sourceContext =
            try await resolveSourceStation(
                aviationStationID: aviationStationID,
                catalogService: sourceCatalogService,
                timeZoneResolver: timeZoneResolver,
                progress: progress
            )
        
        progress?(
            "Finding nearby official Canadian climate composites..."
        )
        
        let matches =
            try compositeCatalogService
                .findNearbyComposites(
                    latitude: sourceContext.coordinate.latitude,
                    longitude: sourceContext.coordinate.longitude,
                    radiusMiles: radiusMiles
                )
        
        let candidates =
            await candidateEvaluator.evaluate(
                matches: matches,
                sourceElevationMeters: sourceContext.elevationMeters,
                startDate: normalStartDate,
                endDate: normalEndDate,
                maximumCandidateCount: maximumCandidateCount,
                progress: progress
            )
        
        let sourceElevationFeet =
            sourceContext.elevationMeters.map {
                $0 * 3.280839895
            }
        
        return GeneratedClimateCandidateSearchResult(
            weatherStationID: sourceContext.aviationStationID,
            displayName: sourceContext.displayName,
            weatherLatitude: sourceContext.coordinate.latitude,
            weatherLongitude: sourceContext.coordinate.longitude,
            weatherElevationFeet: sourceElevationFeet,
            timeZoneIdentifier: sourceContext.timeZoneIdentifier,
            candidates: candidates
        )
    }
    
    /// Build a profile from the selected official composite.
    static func buildOfficialProfile(
        aviationStationID: String,
        climateStationID: String,
        sourceCatalogService:
            ECCCClimateStationCatalogService =
                ECCCClimateStationCatalogService(),
        compositeCatalogService:
            ECCCClimateCompositeCatalogService =
                ECCCClimateCompositeCatalogService(),
        compositeDailyService:
            ECCCClimateCompositeDailyService =
                ECCCClimateCompositeDailyService(),
        timeZoneResolver:
            AtlasStationTimeZoneResolver =
                AtlasStationTimeZoneResolver(),
        progress:
            (@MainActor (String) -> Void)? = nil
    ) async throws
    -> GeneratedStationBuildResult? {

        let safeStationID = aviationStationID
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .uppercased()

        let safeClimateStationID = climateStationID
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .uppercased()

        guard safeStationID.isEmpty == false else {
            throw ECCCGeneratedClimateProfileBuilderError
                .invalidStationIdentifier
        }

        guard safeClimateStationID.isEmpty == false else {
            throw ECCCGeneratedClimateProfileBuilderError
                .selectedClimateStationNotFound(
                    climateStationID
                )
        }

        let sourceContext =
            try await resolveSourceStation(
                aviationStationID: safeStationID,
                catalogService: sourceCatalogService,
                timeZoneResolver: timeZoneResolver,
                progress: progress
            )

        progress?(
            "Resolving selected official Canadian composite..."
        )

        guard let selectedComposite =
                try compositeCatalogService
                    .composite(
                        withCanonicalIdentifier:
                            safeClimateStationID
                    ) else {
            throw ECCCGeneratedClimateProfileBuilderError
                .selectedClimateStationNotFound(
                    safeClimateStationID
                )
        }

        let normalStartDate = ClimateDate(
            year: normalStartYear,
            month: 1,
            day: 1
        )

        let normalEndDate = ClimateDate(
            year: normalEndYear,
            month: 12,
            day: 31
        )

        progress?(
            "Fetching official 1991-2020 Canadian composite..."
        )

        let observations =
            try await compositeDailyService
                .fetchObservations(
                    for: selectedComposite,
                    startDate: normalStartDate,
                    endDate: normalEndDate
                )

        guard observations.isEmpty == false else {
            throw ECCCGeneratedClimateProfileBuilderError
                .noDailyObservations(
                    safeClimateStationID
                )
        }

        let pairedCompleteness =
            ClimateObservationCompletenessCalculator
                .pairedCompleteness(
                    observations: observations,
                    startDate: normalStartDate,
                    endDate: normalEndDate
                ) ?? 0.0

        progress?(
            "Building official 1991-2020 Canadian normals..."
        )

        guard let profile =
                GeneratedClimateNormalCalculator
                    .generatedProfile(
                        stationID:
                            selectedComposite
                                .canonicalClimateIdentifier,
                        displayName:
                            selectedComposite.displayName,
                        latitude:
                            selectedComposite
                                .coordinate.latitude,
                        longitude:
                            selectedComposite
                                .coordinate.longitude,
                        observations: observations,
                        sourceStartYear: normalStartYear,
                        sourceEndYear: normalEndYear
                    ) else {
            return nil
        }

        return GeneratedStationBuildResult(
            countryCode: "CA",
            weatherStationID:
                sourceContext.aviationStationID,
            climateStationID:
                selectedComposite
                    .canonicalClimateIdentifier,
            displayName:
                sourceContext.displayName,
            weatherLatitude:
                sourceContext.coordinate.latitude,
            weatherLongitude:
                sourceContext.coordinate.longitude,
            timeZoneIdentifier:
                sourceContext.timeZoneIdentifier,
            pairedCompleteness:
                pairedCompleteness,
            profile: profile
        )
    }
    
    static func buildProfile(
        aviationStationID: String,
        climateStationID: String? = nil,
        radiusMiles: Double = 100.0,
        catalogService: ECCCClimateStationCatalogService =
            ECCCClimateStationCatalogService(),
        threadDailyService: ECCCClimateStationThreadDailyService =
            ECCCClimateStationThreadDailyService(),
        timeZoneResolver: AtlasStationTimeZoneResolver =
            AtlasStationTimeZoneResolver(),
        progress:
            (@MainActor (String) -> Void)? = nil
    ) async throws
    -> GeneratedStationBuildResult? {
        
        let safeStationID = aviationStationID
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        
        let safeClimateStationID =
            climateStationID?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
        
        guard safeStationID.isEmpty == false else {
            throw ECCCGeneratedClimateProfileBuilderError
                .invalidStationIdentifier
        }
        
        progress?(
            "Resolving Canadian climate-station history..."
        )

        let sourceRecords =
            try await catalogService
                .fetchStations(
                    forAviationStationID:
                        safeStationID
                )

        let sourceThreads =
            ECCCClimateStationThreadBuilder
                .threads(from: sourceRecords)

        guard sourceThreads.isEmpty == false else {
            throw ECCCGeneratedClimateProfileBuilderError
                .noClimateStationThread(
                    safeStationID
                )
        }

        guard sourceThreads.count == 1,
              let sourceThread =
                sourceThreads.first else {
            throw ECCCGeneratedClimateProfileBuilderError
                .ambiguousClimateStationThreads(
                    safeStationID,
                    sourceThreads.count
                )
        }

        let selectedThread:
            ECCCClimateStationThread

        if let safeClimateStationID,
           safeClimateStationID.isEmpty == false {
            
            progress?(
                "Resolving selected Canadian climate station..."
            )
            
            let nearbyRecords =
                try await catalogService
                    .fetchNearbyStations(
                        latitude:
                            sourceThread.coordinate.latitude,
                        longitude:
                            sourceThread.coordinate.longitude,
                        radiusMiles:
                            radiusMiles
                    )
            
            let nearbyThreads =
                ECCCClimateStationThreadBuilder
                    .threads(from: nearbyRecords)
            
            guard let matchingThread =
                    nearbyThreads.first(
                        where: {
                            $0.id.uppercased()
                                == safeClimateStationID
                        }
                    ) else {
                throw ECCCGeneratedClimateProfileBuilderError
                    .selectedClimateStationNotFound(
                        safeClimateStationID
                    )
            }
            
            selectedThread = matchingThread
        } else {
            selectedThread = sourceThread
        }
        
        progress?(
            """
            Fetching 1991-2020 ECCC daily observations...
            """
        )
        
        let observations =
            try await threadDailyService
                .fetchObservations(
                    for: selectedThread,
                    startDate: ClimateDate(
                        year: normalStartYear,
                        month: 1,
                        day: 1
                    ),
                    endDate: ClimateDate(
                        year: normalEndYear,
                        month: 12,
                        day: 31
                    )
                )
        guard observations.isEmpty == false else {
            throw ECCCGeneratedClimateProfileBuilderError
                .noDailyObservations(selectedThread.id)
        }
        
        let pairedCompleteness =
            ClimateObservationCompletenessCalculator
                .pairedCompleteness(
                    observations: observations,
                    startDate: ClimateDate(
                        year: normalStartYear,
                        month: 1,
                        day: 1
                    ),
                    endDate: ClimateDate(
                        year: normalEndYear,
                        month: 12,
                        day: 31
                    )
                ) ?? 0.0
        
        progress?(
            """
            Building 1991-2020 Canadian normals...
            """
        )
        
        guard let profile =
                GeneratedClimateNormalCalculator
                    .generatedProfile(
                        stationID: selectedThread.id,
                        displayName: selectedThread.stationName,
                        latitude: selectedThread.coordinate.latitude,
                        longitude: selectedThread.coordinate.longitude,
                        observations: observations,
                        sourceStartYear: normalStartYear,
                        sourceEndYear: normalEndYear
                    ) else {
            return nil
        }
        
        progress?(
            "Resolving Canadian station time zone..."
        )
        
        let atlasStation = AtlasStation(
            source: AtlasStationSource(
                countryCode: "CA",
                providerID: "aviationWeather",
                stationID: safeStationID
            ),
            name: sourceThread.stationName,
            latitude: sourceThread.coordinate.latitude,
            longitude: sourceThread.coordinate.longitude,
            elevationMeters: sourceThread.elevationMeters,
            networkName: "ECCC",
            tier: .primary,
            administrativeAreaCode: sourceThread.provinceCode,
            displayPriority: nil
        )
        
        guard let timeZone =
                try await timeZoneResolver
                    .timeZone(for: atlasStation) else {
            throw ECCCGeneratedClimateProfileBuilderError
                .timeZoneUnavailable(safeStationID)
        }
        
        return GeneratedStationBuildResult(
            countryCode: "CA",
            weatherStationID: safeStationID,
            climateStationID: selectedThread.id,
            displayName: sourceThread.stationName,
            weatherLatitude: sourceThread.coordinate.latitude,
            weatherLongitude: sourceThread.coordinate.longitude,
            timeZoneIdentifier: timeZone.identifier,
            pairedCompleteness: pairedCompleteness,
            profile: profile
        )
    }
}
