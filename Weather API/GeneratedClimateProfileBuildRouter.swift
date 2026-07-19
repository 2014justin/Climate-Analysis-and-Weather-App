/// Makes the app provider-agnostic. For example. when you click Toronto, somewhere
/// down the chain all that information eventually collapses into weatherStationID = "CYYZ"
/// and the builder happily says "Cool, let's ask NWS where CYYZ is." And then
/// the app explodes. Instead of passing around only a station ID, you preserve the entire identity.
/// It keeps country codes, providerID and of course stationID. It is like a passport so the app
/// never forgets the country of origin.
///
/// So station adder will decide if it goes to US Builder or Canada Builder.
///

import Foundation
enum GeneratedClimateProfileBuildRouterError:
    LocalizedError {
    
    case unsupportedCountry(String)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedCountry(let countryCode):
            if countryCode == "CA" {
                return """
                    Canadian nearby climate-station searching \
                    is not available yet.
                    """
            }
            
            return """
                Climate profile building is not available for \
                \(countryCode) stations.
                """
        }
    }
}

enum GeneratedClimateProfileBuildRouter {
    
    static func findClimateCandidates(
        for source: AtlasStationSource,
        radiusMiles: Double = 100.0,
        maximumCandidateCount: Int = 8,
        progress:
            (@MainActor (String) -> Void)? = nil
    ) async throws
    -> GeneratedClimateCandidateSearchResult {
        
        switch source.countryCode.uppercased() {
        case "US":
            return try await
                GeneratedClimateProfileBuilder
                    .findClimateCandidates(
                        weatherStationID: source.stationID,
                        radiusMiles: radiusMiles,
                        maximumCandidateCount: maximumCandidateCount,
                        progress: progress
                    )
            
        case "CA":
            return try await
                ECCCGeneratedClimateProfileBuilder
                    .findClimateCandidates(
                        aviationStationID: source.stationID,
                        radiusMiles: radiusMiles,
                        maximumCandidateCount: maximumCandidateCount,
                        progress: progress
                    )
            
        default:
            throw GeneratedClimateProfileBuildRouterError
                .unsupportedCountry(source.countryCode)
        }
    }
    
    static func buildProfile(
        for source: AtlasStationSource,
        climateStationID: String? = nil,
        progress:
            (@MainActor (String) -> Void)? = nil
    ) async throws
    -> GeneratedStationBuildResult? {
        switch source.countryCode.uppercased() {
        case "US":
            return try await
            GeneratedClimateProfileBuilder
                .buildProfile(
                    weatherStationID:
                        source.stationID,
                    climateStationID:
                        climateStationID,
                    progress: progress
                )
            
        case "CA":
            return try await
                ECCCGeneratedClimateProfileBuilder
                    .buildProfile(
                        aviationStationID:
                            source.stationID,
                        climateStationID:
                            climateStationID,
                        progress:
                            progress
                    )
            
        default:
            throw GeneratedClimateProfileBuildRouterError
                .unsupportedCountry(
                    source.countryCode
                )
        }
    }
}
