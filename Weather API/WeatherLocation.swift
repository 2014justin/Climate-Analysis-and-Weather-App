import Foundation
///each of the cases our code considers. Just look up the station ID, forecast discussion, and ACIS climate code.
enum ClimatologyProfile: String, Hashable {
    case northLasVegas
    case fairbanks
    case ely
    case stanley
    case saltlakecity
    case denver
    case mountCharleston
    case longBeach
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
    let acisStationID: String
    let generatedClimateProfile: GeneratedClimateProfile?
    
    ///existing curated stations can still omit generatedClimateProfile, because the initializer default is nil
    ///Generated station factory can pass generatedClimateProfile: profile
    ///the struct remains hashable, equatable, and first-class for the picker.
    init(
        id: String,
        name: String,
        observationStationID: String,
        displayStationID: String,
        latitude: Double,
        longitude: Double,
        forecastDiscussionOffice: String,
        climatologyProfile: ClimatologyProfile,
        timeZoneIdentifier: String,
        acisStationID: String,
        generatedClimateProfile: GeneratedClimateProfile? = nil
    ) {
        self.id = id
        self.name = name
        self.observationStationID = observationStationID
        self.displayStationID = displayStationID
        self.latitude = latitude
        self.longitude = longitude
        self.forecastDiscussionOffice = forecastDiscussionOffice
        self.climatologyProfile = climatologyProfile
        self.timeZoneIdentifier = timeZoneIdentifier
        self.acisStationID = acisStationID
        self.generatedClimateProfile = generatedClimateProfile
    }
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
        timeZoneIdentifier: "America/Los_Angeles",
        acisStationID: "KVGT"
    )
    /// Here is Fairbanks, AK
    /// flooding data?
    /// 
    static let fairbanks = WeatherLocation(
        id: "fairbanks",
        name: "Fairbanks, AK",
        observationStationID: "PAFA",
        displayStationID: "PAFA",
        latitude: 64.8378,
        longitude: -147.7164,
        forecastDiscussionOffice: "AFG",
        climatologyProfile: .fairbanks,
        timeZoneIdentifier: "America/Anchorage",
        acisStationID: "PAFA"
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
        timeZoneIdentifier: "America/Los_Angeles",
        acisStationID: "KELY"
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
        timeZoneIdentifier: "America/Denver",
        acisStationID: "KSNT"
        
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
        timeZoneIdentifier: "America/Denver",
        acisStationID: "KSLC"
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
        timeZoneIdentifier: "America/Denver",
        acisStationID: "KDEN"
    )
    
    ///Kyle Canyon/Mountain Charleston, NV
    static let mountCharleston = WeatherLocation(
        id: "mountCharleston",
        name: "Mount Charleston",
        observationStationID: "KYCN2",
        displayStationID: "KYCN2",
        latitude: 36.264910,
        longitude: -115.606970,
        forecastDiscussionOffice: "VEF",
        climatologyProfile: .mountCharleston,
        timeZoneIdentifier: "America/Los_Angeles",
        acisStationID: "MCHN2"
    )
    
    ///Long Beach, CA
    static let longBeach = WeatherLocation(
        id: "longBeach",
        name: "Long Beach, CA",
        observationStationID: "KLGB",
        displayStationID: "KLGB",
        latitude: 33.81167,
        longitude: -118.14639,
        forecastDiscussionOffice: "VEF",
        climatologyProfile: .longBeach,
        timeZoneIdentifier: "America/Los_Angeles",
        acisStationID: "KLGB"
    )
    ///Next station goes under here:
    
    
    
    static let allLocations: [WeatherLocation] = [
        .northLasVegas,
        .fairbanks,
        .ely,
        .stanley,
        .saltlakecity,
        .denver,
        .mountCharleston,
        .longBeach
    ]
    
    ///Add a generated location factory
    static func generated(from result: GeneratedStationBuildResult) -> WeatherLocation {
        generated(
            from: SavedGeneratedStation(result: result)
        )
    }
    
    static func generated(from savedStation: SavedGeneratedStation) -> WeatherLocation {
        WeatherLocation(
            id: savedStation.id,
            name: savedStation.name,
            observationStationID: savedStation.observationStationID,
            displayStationID: savedStation.displayStationID,
            latitude: savedStation.latitude,
            longitude: savedStation.longitude,
            forecastDiscussionOffice: "",
            climatologyProfile: .northLasVegas,
            timeZoneIdentifier: savedStation.timeZoneIdentifier,
            acisStationID: savedStation.acisStationID,
            generatedClimateProfile: savedStation.generatedClimateProfile
        )
    }
    
    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }
    
    func normalHigh(dayOfYear t: Int) -> Double {
        if let generatedClimateProfile {
            return generatedClimateProfile.normalHigh(dayOfYear: t)
        }

        return WeatherAlmanac.normalHighFahrenheit(
            dayOfYear: t,
            profile: climatologyProfile
        )
    }

    func normalLow(dayOfYear t: Int) -> Double {
        if let generatedClimateProfile {
            return generatedClimateProfile.normalLow(dayOfYear: t)
        }

        return WeatherAlmanac.normalLowFahrenheit(
            dayOfYear: t,
            profile: climatologyProfile
        )
    }

    func solarEnergy(dayOfYear t: Int) -> Double {
        if let generatedClimateProfile {
            return generatedClimateProfile.solarEnergy(dayOfYear: t)
        }

        return WeatherAlmanac.solarEnergy(
            dayOfYear: t,
            profile: climatologyProfile
        )
    }

    func normalizedSolarEnergy(dayOfYear t: Int) -> Double {
        if let generatedClimateProfile {
            return generatedClimateProfile.normalizedSolarEnergy(dayOfYear: t)
        }

        return WeatherAlmanac.normalizedSolarEnergy(
            dayOfYear: t,
            profile: climatologyProfile
        )
    }
}
