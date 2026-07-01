import Foundation

///ACISDailyObservation is the clean app-friendly model we want to use. Optional
///inputs for missing data. Lets us access climatological data like snow
///and precipiration
struct ACISDailyObservation: Identifiable {
    let id = UUID()
    let date: Date
    let minimumTemperature: Double?
    let maximumTemperature: Double?
    let precipitation: Double?
    let snowfall: Double?
    let snowDepth: Double?
}

struct ACISStationMetadata: Decodable {
    let name: String?
    let state: String?
    let elevation: Double?
    
    enum CodingKeys: String, CodingKey {
        case name
        case state
        case elevation = "elev"
    }
}

struct ACISDailyDateResponse: Decodable {
    let meta: ACISStationMetadata
    let data: [[String]]
}

enum ACISValueParser {
    static func double(from rawValue: String) -> Double? {
        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedValue == "M" || trimmedValue.isEmpty {
            return nil
        }
        ///T is trace, so like trace amounts of snow or rain
        if trimmedValue == "T" {
            return 0.0
        }
        
        return Double(trimmedValue)
    }
}

///ACIS sends dates as trings like "2020-01-05". Swift charts/math need actual Date values. so this
///creates one reusable parser for that exact format. Using en US POSIX because it makes the formatter stable and boring.

///enum is being used here NOT for a choice or list type, but for a namespace or utility container.
///ACISDateParser is not something we ever need to create as an object. We just want a labeled drawer for related
///helper code.
///
///an enum with no cases is a nice Swift trick for saying "This is just a utility namespace, don't instantiate it"
enum ACISDateParser {
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        
        return formatter
    }()
    
    static func date(from rawValue: String) -> Date? {
        formatter.date(from: rawValue)
    }
}

///ACIS gives us something like ["2020-01-01", "-18", "6", "0.00", "0.0", "10"]
///and the mapper turns it into date: ..., minimum temperature : -18, maximumTemperature: 6, precipitation: 0, snowfall: 0, snowdepth : 10
enum ACISDailyObservationMapper {
    static func observation(from row: [String]) -> ACISDailyObservation? {
        guard row.count >= 6,
              let date = ACISDateParser.date(from: row[0]) else {
            return nil
        }
        
        return ACISDailyObservation(
            date: date,
            minimumTemperature: ACISValueParser.double(from: row[1]),
            maximumTemperature: ACISValueParser.double(from: row[2]),
            precipitation: ACISValueParser.double(from: row[3]),
            snowfall: ACISValueParser.double(from: row[4]),
            snowDepth: ACISValueParser.double(from: row[5])
        )
    }2
}
