///Station-saver sheet

import Foundation

struct SavedGeneratedStation: Codable, Identifiable {
    let id: String
    let name: String
    let observationStationID: String
    let displayStationID: String
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String
    let acisStationID: String
    let generatedClimateProfile: GeneratedClimateProfile
    
    init(result: GeneratedStationBuildResult) {
        self.id = "\(result.weatherStationID)-\(result.climateStationID)"
        self.name = result.displayName
        self.observationStationID = result.weatherStationID
        self.displayStationID = result.weatherStationID
        self.latitude = result.weatherLatitude
        self.longitude = result.weatherLongitude
        self.timeZoneIdentifier = result.timeZoneIdentifier
        self.acisStationID = result.climateStationID
        self.generatedClimateProfile = result.profile
    }
}

enum GeneratedStationStore {
    private static let storageKey = "savedGeneratedStations"
    
    static func load() throws -> [SavedGeneratedStation] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }
        
        return try JSONDecoder().decode(
            [SavedGeneratedStation].self,
            from: data
        )
    }
    
    ///The '__' means this parameter has no external argument label when the function is called.
    static func save(_ stations: [SavedGeneratedStation]) throws {
        let data = try JSONEncoder().encode(stations)
        
        UserDefaults.standard.set(
            data,
            forKey: storageKey
        )
    }
}
