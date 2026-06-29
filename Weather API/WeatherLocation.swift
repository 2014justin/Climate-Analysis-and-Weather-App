import Foundation

enum ClimatologyProfile: String, Hashable {
    case northLasVegas
    case fairbanks
    case ely
    case stanley
    case saltlakecity
    case denver
}

struct WeatherLocation: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let observationStationID: String
    let displayStationID: String
    let latitude: Double
    let longitude: Double
    let forecastDiscussionOffice: String
    let climatologyProfile: ClimatologyProfile
    let timeZoneIdentifier: String
}

extension WeatherLocation {
    /// We need to add one for each selectable station
    /// Here is North Las Vegas
    static let northLasVegas = WeatherLocation(
        id: "north-las-vegas",
        name: "North Las Vegas",
        observationStationID: "F0069",
        displayStationID: "FW0069",
        latitude: 36.313,
        longitude: -115.19167,
        forecastDiscussionOffice: "VEF",
        climatologyProfile: .northLasVegas,
        timeZoneIdentifier: "America/Los_Angeles"
    )
    /// Here is Fairbanks, AK
    static let fairbanks = WeatherLocation(
        id: "fairbanks",
        name: "Fairbanks, AK",
        observationStationID: "PAFA",
        displayStationID: "PAFA",
        latitude: 64.8378,
        longitude: -147.7164,
        forecastDiscussionOffice: "AFG",
        climatologyProfile: .fairbanks,
        timeZoneIdentifier: "America/Anchorage"
    )
    /// Here is Ely, NV
    static let ely = WeatherLocation(
        id: "ely",
        name: "Ely, NV",
        observationStationID: "KELY",
        displayStationID: "KELY",
        latitude: 39.2474,
        longitude: -114.8886,
        forecastDiscussionOffice: "LKN",
        climatologyProfile: .ely,
        timeZoneIdentifier: "America/Los_Angeles"
    )
    /// Stanley, ID has joined the chat
    static let stanley = WeatherLocation(
        id: "stanley",
        name: "Stanley, ID",
        observationStationID: "KSNT",
        displayStationID: "KSNT",
        latitude: 44.20861,
        longitude: -114.93444,
        forecastDiscussionOffice: "PIH",
        climatologyProfile: .stanley,
        timeZoneIdentifier: "America/Denver"
    )
    /// Salt Lake City, UT
    static let saltlakecity = WeatherLocation(
        id: "saltlakecity",
        name: "Salt Lake City, UT",
        observationStationID: "KSLC",
        displayStationID: "KSLC",
        latitude: 40.77069,
        longitude: -111.96503,
        forecastDiscussionOffice: "AFDSLC",
        climatologyProfile: .saltlakecity,
        timeZoneIdentifier: "America/Denver"
    )
    /// Denver, CO
    static let denver = WeatherLocation(
        id: "denver",
        name: "Denver, CO",
        observationStationID: "KDEN",
        displayStationID: "KDEN",
        latitude: 39.84658,
        longitude: -104.65622,
        forecastDiscussionOffice: "BOU",
        climatologyProfile: .denver,
        timeZoneIdentifier: "America/Denver"
    )
    static let allLocations: [WeatherLocation] = [
        .northLasVegas,
        .fairbanks,
        .ely,
        .stanley,
        .saltlakecity,
        .denver
    ]
    
    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }
}
