///Station-saver sheet

import Foundation

struct SavedGeneratedStation: Codable, Identifiable {
    
    let id: String
    let countryCode: String?
    let name: String
    let observationStationID: String
    let displayStationID: String
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String
    let acisStationID: String
    let pairedCompleteness: Double?
    let generatedClimateProfile: GeneratedClimateProfile
    
    init(result: GeneratedStationBuildResult) {
        self.id = "\(result.weatherStationID)-\(result.climateStationID)"
        self.countryCode = result.countryCode
        self.name = result.displayName
        self.observationStationID = result.weatherStationID
        self.displayStationID = result.weatherStationID
        self.latitude = result.weatherLatitude
        self.longitude = result.weatherLongitude
        self.timeZoneIdentifier = result.timeZoneIdentifier
        self.acisStationID = result.climateStationID
        self.pairedCompleteness = result.pairedCompleteness
        self.generatedClimateProfile = result.profile
    }
    
    var resolvedCountryCode: String {
        countryCode?.uppercased() ?? "US"
    }
}

enum GeneratedStationStore {
    private static let legacyStorageKey =
        "savedGeneratedStations"

    private static var storageFileURL: URL {
        get throws {
            let applicationSupportURL =
                try FileManager.default.url(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )

            let weatherAPIDirectory =
                applicationSupportURL.appendingPathComponent(
                    "Weather API",
                    isDirectory: true
                )

            try FileManager.default.createDirectory(
                at: weatherAPIDirectory,
                withIntermediateDirectories: true
            )

            return weatherAPIDirectory.appendingPathComponent(
                "GeneratedStations.json",
                isDirectory: false
            )
        }
    }

    static func load() throws -> [SavedGeneratedStation] {
        let fileURL = try storageFileURL

        if FileManager.default.fileExists(
            atPath: fileURL.path
        ) {
            let data = try Data(
                contentsOf: fileURL
            )

            return try JSONDecoder().decode(
                [SavedGeneratedStation].self,
                from: data
            )
        }

        // One-time migration from the old UserDefaults store.
        guard let legacyData =
                UserDefaults.standard.data(
                    forKey: legacyStorageKey
                )
        else {
            return []
        }

        let migratedStations =
            try JSONDecoder().decode(
                [SavedGeneratedStation].self,
                from: legacyData
            )

        try save(migratedStations)

        // Remove the oversized value only after the file write succeeds.
        UserDefaults.standard.removeObject(
            forKey: legacyStorageKey
        )

        return migratedStations
    }

    static func save(
        _ stations: [SavedGeneratedStation]
    ) throws {
        let data = try JSONEncoder().encode(
            stations
        )

        try data.write(
            to: storageFileURL,
            options: .atomic
        )
    }
}
