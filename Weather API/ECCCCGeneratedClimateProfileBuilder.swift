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
        
        let safeStationID = aviationStationID
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        
        guard safeStationID.isEmpty == false else {
            throw ECCCGeneratedClimateProfileBuilderError
                .invalidStationIdentifier
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
        
        await progress?("Resolving Canadian aviation station...")
        
        let sourceRecords =
        try await catalogService
            .fetchStations(forAviationStationID: safeStationID)
        
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
        
        let sourceCoordinate = sourceThread.coordinate
        
        await progress?("Finding nearby Canadian climate stations...")
        
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
            
            await progress?(
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
                    sourceThread.elevationMeters,
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
        
        let sourceAtlasStation = AtlasStation(
            source: AtlasStationSource(
                countryCode: "CA",
                providerID: "aviationWeather",
                stationID: safeStationID
            ),
            name: sourceThread.stationName,
            latitude: sourceCoordinate.latitude,
            longitude: sourceCoordinate.longitude,
            elevationMeters: sourceThread.elevationMeters,
            networkName: "ECCC",
            tier: .primary,
            administrativeAreaCode: sourceThread.provinceCode,
            displayPriority: nil
        )
        
        guard let timeZone =
                try await timeZoneResolver
            .timeZone(for: sourceAtlasStation) else {
            throw ECCCGeneratedClimateProfileBuilderError
                .timeZoneUnavailable(safeStationID)
        }
        
        let sourceElevationFeet =
        sourceThread.elevationMeters.map {
            $0 * 3.280839895
        }
        
        return GeneratedClimateCandidateSearchResult(
            weatherStationID: safeStationID,
            displayName: sourceThread.stationName,
            weatherLatitude: sourceCoordinate.latitude,
            weatherLongitude: sourceCoordinate.longitude,
            weatherElevationFeet: sourceElevationFeet,
            timeZoneIdentifier: timeZone.identifier,
            candidates: candidates
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
        
        await progress?(
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
            
            await progress?(
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
        
        await progress?(
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
        
        await progress?(
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
        
        await progress?(
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
