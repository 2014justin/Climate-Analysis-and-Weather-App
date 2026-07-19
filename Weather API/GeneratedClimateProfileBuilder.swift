import Foundation

///Change the builder result
struct GeneratedStationBuildResult {
    let countryCode: String
    
    let weatherStationID: String
    let climateStationID: String
    let displayName: String
    let weatherLatitude: Double
    let weatherLongitude: Double
    let timeZoneIdentifier: String
    let pairedCompleteness: Double
    let profile: GeneratedClimateProfile

    init(
        countryCode: String = "US",
        weatherStationID: String,
        climateStationID: String,
        displayName: String,
        weatherLatitude: Double,
        weatherLongitude: Double,
        timeZoneIdentifier: String,
        pairedCompleteness: Double,
        profile: GeneratedClimateProfile
        
    ) {
        self.countryCode = countryCode.uppercased()
        self.weatherStationID = weatherStationID
        self.climateStationID = climateStationID
        self.displayName = displayName
        self.weatherLatitude = weatherLatitude
        self.weatherLongitude = weatherLongitude
        self.timeZoneIdentifier = timeZoneIdentifier
        self.pairedCompleteness = pairedCompleteness
        self.profile = profile
    }
}

enum GeneratedClimateStationQualityRating: String, Sendable {
    
    case excellent
    case good
    case acceptable
    case marginal
    case poor
    
    init(pairedCompleteness: Double) {
        switch pairedCompleteness {
        case 0.98...:
            self = .excellent
            
        case 0.965..<0.98:
            self = .good
            
        case 0.95..<0.965:
            self = .acceptable
            
        case let value where value > 0.90:
            self = .marginal
            
        default:
            self = .poor
        }
    }
    
    var recommendationTier: Int {
        switch self {
        case .excellent, .good:
            return 0
            
        case .acceptable:
            return 1
            
        case .marginal:
            return 2
            
        case .poor:
            return 3
        }
    }
}

struct GeneratedClimateStationCandidate: Identifiable, Sendable {
    let stationID: String
    let displayName: String
    let administrativeAreaCode: String?
    let distanceMiles: Double
    let elevationDifferenceFeet: Double?
    let pairedCompleteness: Double
    
    var id: String {
        stationID
    }
    
    var qualityRating:
    GeneratedClimateStationQualityRating {
        
        GeneratedClimateStationQualityRating(pairedCompleteness: pairedCompleteness)
    }
}

struct GeneratedClimateCandidateSearchResult {
    let weatherStationID: String
    let displayName: String
    let weatherLatitude: Double
    let weatherLongitude: Double
    let weatherElevationFeet: Double?
    let timeZoneIdentifier: String
    let candidates: [GeneratedClimateStationCandidate]
}

enum GeneratedClimateProfileBuilder {
    static let normalStartYear = 1991
    static let normalEndYear = 2020
    
    static func findClimateCandidates(
        weatherStationID: String,
        radiusMiles: Double = 100.0,
        maximumCandidateCount: Int = 8,
        weatherService: WeatherService = WeatherService(),
        progress: (@MainActor (String) -> Void)? = nil
    ) async throws -> GeneratedClimateCandidateSearchResult {
        let safeWeatherStationID = weatherStationID
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard safeWeatherStationID.isEmpty == false else {
            throw URLError(.badURL)
        }

        await progress?("Fetching weather station metadata...")

        let stationMetadata =
            try await weatherService.fetchStationMetadata(
                stationID: safeWeatherStationID
            )

        guard stationMetadata.geometry.coordinates.count >= 2 else {
            throw URLError(.cannotParseResponse)
        }

        let weatherLongitude =
            stationMetadata.geometry.coordinates[0]

        let weatherLatitude =
            stationMetadata.geometry.coordinates[1]

        let displayName =
            stationMetadata.properties.name
            ?? safeWeatherStationID

        let timeZoneIdentifier =
            stationMetadata.properties.timeZone
            ?? "UTC"

        let weatherElevationFeet =
            stationMetadata.properties.elevationFeet

        await progress?(
            "Finding nearby long-term climate stations..."
        )

        let evaluatedCandidates =
            try await ACISClimateService
                .evaluatedNearbyClimateCandidates(
                    latitude: weatherLatitude,
                    longitude: weatherLongitude,
                    sourceElevationFeet: weatherElevationFeet,
                    radiusMiles: radiusMiles,
                    maximumCandidateCount: maximumCandidateCount
                )
        
        let candidates =
            evaluatedCandidates.map {
                evaluatedCandidate in
                
                let candidate = evaluatedCandidate.candidate
                
                return GeneratedClimateStationCandidate(
                    stationID: candidate.stationID,
                    displayName:
                        candidate.metadata.name
                        ?? candidate.stationID,
                    administrativeAreaCode: candidate.metadata.state,
                    distanceMiles: candidate.distanceMiles,
                    elevationDifferenceFeet: candidate.elevationDifferenceFeet,
                    pairedCompleteness: evaluatedCandidate.quality
                        .pairedCompleteness
                )
        }

        return GeneratedClimateCandidateSearchResult(
            weatherStationID: safeWeatherStationID,
            displayName: displayName,
            weatherLatitude: weatherLatitude,
            weatherLongitude: weatherLongitude,
            weatherElevationFeet: weatherElevationFeet,
            timeZoneIdentifier: timeZoneIdentifier,
            candidates: candidates
        )
    }
    
    static func buildProfile(
        weatherStationID: String,
        climateStationID: String? = nil,
        weatherService: WeatherService = WeatherService(),
        progress: (@MainActor (String) -> Void)? = nil
    ) async throws -> GeneratedStationBuildResult? {
        let safeWeatherStationID = weatherStationID
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        let safeClimateStationID = climateStationID?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        let finalClimateStationID = safeClimateStationID?.isEmpty == false
            ? safeClimateStationID!
            : safeWeatherStationID

        await progress?("Fetching weather station metadata...")
        let stationMetadata = try await weatherService.fetchStationMetadata(
            stationID: safeWeatherStationID
        )

        guard stationMetadata.geometry.coordinates.count >= 2 else {
            throw URLError(.cannotParseResponse)
        }

        let weatherLongitude = stationMetadata.geometry.coordinates[0]
        let weatherLatitude = stationMetadata.geometry.coordinates[1]
        let displayName = stationMetadata.properties.name ?? safeWeatherStationID
        let timeZoneIdentifier = stationMetadata.properties.timeZone ?? "UTC"

        await progress?("Fetching climate station metadata...")
        let climateMetadata = try await ACISClimateService.fetchStationInfo(
            stationID: finalClimateStationID
        )

        let climateLatitude = climateMetadata?.latitude ?? weatherLatitude
        let climateLongitude = climateMetadata?.longitude ?? weatherLongitude
        let climateDisplayName = climateMetadata?.name ?? displayName

        await progress?("Fetching 1991-2020 ACIS daily observations...")
        
        let acisObservations =
        try await ACISClimateService.fetchDailyObservations(
            stationID: finalClimateStationID,
            startDate: "\(normalStartYear)-01-01",
            endDate: "\(normalEndYear)-12-31"
        )
        
        let observations =
            acisObservations.compactMap { observation in
            ACISClimateDailyObservationAdapter
                    .observation(from: observation)
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
                ) ?? 0

        await progress?("Building 1991-2020 normals...")
        guard let profile = GeneratedClimateNormalCalculator.generatedProfile(
            stationID: finalClimateStationID,
            displayName: climateDisplayName,
            latitude: climateLatitude,
            longitude: climateLongitude,
            observations: observations,
            sourceStartYear: normalStartYear,
            sourceEndYear: normalEndYear
        ) else {
            return nil
        }

        return GeneratedStationBuildResult(
            weatherStationID: safeWeatherStationID,
            climateStationID: finalClimateStationID,
            displayName: displayName,
            weatherLatitude: weatherLatitude,
            weatherLongitude: weatherLongitude,
            timeZoneIdentifier: timeZoneIdentifier,
            pairedCompleteness: pairedCompleteness,
            profile: profile
        )
    }
}
