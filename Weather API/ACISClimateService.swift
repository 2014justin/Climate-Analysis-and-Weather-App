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
/// Converts ACIS's app-facing record into the provider-neutral daily record
/// used by the generated-profile pipeline
enum ACISClimateDailyObservationAdapter {
    
    static func observation(
        from source: ACISDailyObservation
    ) -> ClimateDailyObservation? {
        
        guard let localDate = ClimateDate(utcDate: source.date)
        else {
            return nil
        }
        
        return ClimateDailyObservation(
            localDate: localDate,
            minimumTemperature: temperatureReading(
                from: source.minimumTemperature
            ),
            maximumTemperature: temperatureReading(
                from: source.maximumTemperature
            )
        )
    }
    
    static func observations(
        from sources: [ACISDailyObservation]
    ) -> [ClimateDailyObservation] {
        
        sources.compactMap { source in
            observation(from: source)
        }
    }
    
    private static func temperatureReading(
        from value: Double?
    ) -> ClimateTemperatureReading {
        ClimateTemperatureReading(
            fahrenheit: value,
            quality: value == nil
            /// Is value nil? If yes, use .missing. Otherwise use .observed
                ? .missing
                : .observed,
            sourceFlag: nil
        )
    }
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

///Add ACIS Station metadata
struct ACISStationInfoResponse: Decodable {
    let meta: [ACISStationInfo]
}

struct ACISStationInfo: Decodable {
    let name: String?
    let state: String?
    let elevation: Double?
    let coordinates: [Double]
    let stationIdentifiers: [String]?
    let validDateRanges: [[String]]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case state
        case elevation = "elev"
        case coordinates = "ll"
        case stationIdentifiers = "sids"
        case validDateRanges = "valid_daterange"
    }
    
    var longitude: Double? {
        guard coordinates.count >= 2 else { return nil }
        return coordinates[0]
    }
    
    var latitude: Double? {
        guard coordinates.count >= 2 else { return nil }
        return coordinates[1]
    }
    
    /// See how complete a nearby station's data is:
    /// validDateRanges should contain one range for maxt and onother for mint, matching our query order.
    /// If either range is missing, the station fails, as it should
    /// prefix(2) considers those first two temperature ranges.
    /// allSatisfy returns true only if both ranges path. Each must begin on or befor Jan 1 1991 and end on or
    /// after Dec 31, 2020.
    var coversNormalPeriod: Bool {
        guard let validDateRanges,
              validDateRanges.count >= 2 else {
            return false
        }
        
        let requiredStart =
            "\(GeneratedClimateProfileBuilder.normalStartYear)-01-01"
        
        let requiredEnd =
        "\(GeneratedClimateProfileBuilder.normalEndYear)-12-31"
        
        return validDateRanges
            .prefix(2)
            .allSatisfy { dateRange in
                guard dateRange.count >= 2 else {
                    return false
                }
                
                let stationStart = dateRange[0]
                let stationEnd = dateRange[1]
                
                return stationStart <= requiredStart
                    && stationEnd >= requiredEnd
            }
    }
    
    /// True great-circle distance calculation. Differential geometry
    func distanceMiles(
        fromLatitude sourceLatitude: Double,
        longitude sourceLongitude: Double
    ) -> Double? {
        guard let stationLatitude = latitude,
              let stationLongitude = longitude else {
            return nil
        }
        
        let sourceCoordinate =
            GeographicCoordinate(
                latitude: sourceLatitude,
                longitude: sourceLongitude
            )
        
        let stationCoordinate =
            GeographicCoordinate(
                latitude: stationLatitude,
                longitude: stationLongitude
            )
        
        return GeodesicDistance.miles(
            from: sourceCoordinate,
            to: stationCoordinate
        )
    }
    
    var ghcnStationID: String? {
        let ghcnIdentifiers = stationIdentifiers?
            .compactMap { identifier -> String? in
                let pieces = identifier.split(separator: " ")
                
                guard pieces.count >= 2,
                      pieces.last == "6",
                      let stationID = pieces.first else {
                    return nil
                }
                
                /// If the result is nil. use an empty array. That lets ghcnIdentifiers always be a normal
                /// [String], never [String]?. We can safely search it without repeatedly unwrapping an optional.
                return String(stationID)
            } ?? []
        
        /// Return the first USC... identifier if one exists. Otherwise, return the first USW... identifier, otherwise return any availble GHCN identifier. If the array is empty the final result is nol.
        ///
        /// USC... generally represents a US cooperative/climatological station in GHCN.
        ///  USW.... generally represents a US airport/WMo-style station in GHCN.
        return ghcnIdentifiers.first(where: { $0.hasPrefix("USC") })
            ?? ghcnIdentifiers.first(where: { $0.hasPrefix("USW") })
            ?? ghcnIdentifiers.first
    }
}

/// Packages together the ACIS metadata, the usable GHCN station ID, and its calculated distance from the requested weather station
struct ACISStationCandidate {
    let metadata: ACISStationInfo
    let stationID: String
    let distanceMiles: Double
    let elevationDifferenceFeet: Double?
}

enum ACISStationQualityRating: String {
    case excellent
    case good
    case acceptable
    case marginal
    case poor
}

struct ACISStationQuality {
    let expectedDayCount: Int
    let minimumValidDayCount: Int
    let maximumValidDayCount: Int
    let pairedValidDayCount: Int
    
    private func completeness(
        validDayCount: Int
    ) -> Double {
        guard expectedDayCount > 0 else {
            return 0.0
        }
        
        return Double(validDayCount)
            / Double(expectedDayCount)
    }
    
    var minimumCompleteness: Double {
        completeness(validDayCount: minimumValidDayCount)
    }
    
    var maximumCompleteness: Double {
        completeness(validDayCount: maximumValidDayCount)
    }
    
    var pairedCompleteness: Double {
        completeness(validDayCount: pairedValidDayCount)
    }
    
    var rating: ACISStationQualityRating {
        switch pairedCompleteness {
        case 0.98...:
            return .excellent
            
        case 0.97..<0.98:
            return .good
            
        case 0.95..<0.97:
            return .acceptable
            
        case let value where value > 0.90:
            return .marginal
            
        default:
            return .poor
        }
    }
}

struct ACISEvaluatedStationCandidate {
    let candidate: ACISStationCandidate
    let quality: ACISStationQuality
    
    var recommendationTier: Int {
        switch quality.rating {
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

/// Calculate quality
enum ACISStationQualityCalculator {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }()
    
    static func quality(
        fromNormalPeriodObservations observations:
            [ACISDailyObservation]
    ) -> ACISStationQuality? {
        let startDateString =
            "\(GeneratedClimateProfileBuilder.normalStartYear)-01-01"
        
        let endDateString =
            "\(GeneratedClimateProfileBuilder.normalEndYear)-12-31"
        
        guard let startDate = ACISDateParser.date(
            from: startDateString
        ),
        let endDate = ACISDateParser.date(
            from: endDateString
        ),
        let dayDifference = calendar.dateComponents(
            [.day],
            from: startDate,
            to: endDate
        ).day else {
            return nil
        }
        
        /// dateComponents measure the distance between the dates.
        /// Adding one includes both January 1 and December 31.
        let expectedDayCount = dayDifference + 1
        
        let minimumValidDates = Set<Date>(
            observations.compactMap { observation in
                guard observation.minimumTemperature != nil else {
                    return nil
                }
                
                return observation.date
                
            }
        )
        
        /// Set<Date> prevents duplicate rows from artificially inflating quality.
        /// Paired completeness required both min and max temperature on the same date.
        /// Exactly 90% is rated poor., values stored as fractions.
        let maximumValidDates = Set<Date>(
            observations.compactMap { observation in
                guard observation.maximumTemperature != nil else {
                    return nil
                }
                
                return observation.date
            }
        )
        
        let pairedValidDates = Set<Date>(
            observations.compactMap { observation in
                guard observation.minimumTemperature != nil,
                      observation.maximumTemperature != nil else {
                    return nil
                }
                
                return observation.date
            }
        )
        
        return ACISStationQuality(
            expectedDayCount: expectedDayCount,
            minimumValidDayCount: minimumValidDates.count,
            maximumValidDayCount: maximumValidDates.count,
            pairedValidDayCount: pairedValidDates.count
        )
    }
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
        ///before pulling ACISDailyObservation, make sure this row has at least
        ///6 pieces of data and make sure the first piece can become a real Date. If either thing fails, return nil.
        ///
        ///
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
    }
}

///Temperature - only row mapper. Good for testinng prospective station health
enum ACISTemperatureObservationMapper {
    static func observation(
        from row: [String]
    ) -> ACISDailyObservation? {
        guard row.count >= 3,
              let date = ACISDateParser.date(
                from: row[0]
              ) else {
            return nil
        }
        
        return ACISDailyObservation(
            date: date,
            minimumTemperature: ACISValueParser.double(from: row[1]),
            maximumTemperature: ACISValueParser.double(from: row[2]),
            precipitation: nil,
            snowfall: nil,
            snowDepth: nil
        )
    }
}


///This asks ACIS for daily station data and returns ACISDailyObservation
enum ACISClimateService {
    
    static func fetchStationInfo(
        stationID: String
    ) async throws -> ACISStationInfo? {
        var components = URLComponents(string: "https://data.rcc-acis.org/StnMeta")
        components?.queryItems = [
            URLQueryItem(name: "sids", value: stationID),
            URLQueryItem(name: "meta", value: "name,state,ll,elev,sids")
        ]
        
        guard let url = components?.url else {
            return nil
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ACISStationInfoResponse.self, from: data)
        
        return response.meta.first
    }
    
    /// This helper function is important. It creates a rectangular search area around the weather station.
    /// Requests only stations reporting maximum and minimum temperature. Retrieves coordinates. elevation, identifiers,
    /// and record ranges. Returns metadata only-no daily observations yet.
    /// The longitude calc needs extra math because longitude gets physically narrower towards the poles.
    /// One degree of longitude in Eagle Alaska is vastly different than one degree of longitude near Florida
    static func fetchNearbyStations(
        latitude: Double,
        longitude: Double,
        radiusMiles: Double = 100.0
    ) async throws -> [ACISStationInfo] {
        let latitudeDelta = radiusMiles / 69.0
        
        let milesPerLongitudeDegree = max(
            69.0 * cos(latitude * .pi / 180),
            1.0
        )
        
        let longitudeDelta = radiusMiles / milesPerLongitudeDegree
        
        let west = longitude - longitudeDelta
        let south = latitude - latitudeDelta
        let east = longitude + longitudeDelta
        let north = latitude + latitudeDelta
        
        let boundingBox = String(
            format: "%.4f,%.4f,%.4f,%.4f",
            locale: Locale(identifier: "en_US_POSIX"),
            west,
            south,
            east,
            north
        )
        
        var components = URLComponents(
            string: "https://data.rcc-acis.org/StnMeta"
        )
        
        components?.queryItems = [
            URLQueryItem(name: "bbox", value: boundingBox),
            URLQueryItem(
                name: "meta",
                value: "name,state,ll,elev,sids,valid_daterange"
            ),
            URLQueryItem(name: "elems", value: "maxt,mint"),
            URLQueryItem(
                name: "sdate",
                value: "\(GeneratedClimateProfileBuilder.normalStartYear)-01-01"
            ),
            URLQueryItem(
                name: "edate",
                value: "\(GeneratedClimateProfileBuilder.normalEndYear)-12-31"
            )
        ]
        
        guard let url = components?.url else {
            return []
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let response = try JSONDecoder().decode(
            ACISStationInfoResponse.self,
            from: data
        )
        
        return response.meta
    }
    
    /// Create the ranked candidate queue.
    /// Process: Rectangular ACIS Search -> Must span 1991-2020 -> Must have a usable GHCN ID -> Calc spherical distance
    ///  -> Reject bounding-box corner stations beyond 100 miles -> Sort nearest-first
    static func rankedNearbyClimateCandidates(
        latitude: Double,
        longitude: Double,
        sourceElevationFeet: Double? = nil,
        radiusMiles: Double = 100.0
    ) async throws -> [ACISStationCandidate] {
        let nearbyStations = try await fetchNearbyStations(
            latitude: latitude,
            longitude: longitude,
            radiusMiles: radiusMiles
        )
        
        /// compactMap is doing a lot of heavy lifting here. Filtering and transformation. Every rejected station returns nil; every
        /// accepted station becomes an ACISStationCandidate
        return nearbyStations
            .compactMap { station -> ACISStationCandidate? in
                guard station.coversNormalPeriod,
                      let stationID = station.ghcnStationID,
                      let distanceMiles = station.distanceMiles(
                        fromLatitude: latitude,
                        longitude: longitude
                      ),
                      /// ACIS search is rectangular. A station in a corner of that rectange could be 140 miles
                      /// away even though the requested radius was 100 miles.
                      distanceMiles <= radiusMiles else {
                    return nil
                }
                
                let elevationDifferenceFeet: Double?
                
                if let sourceElevationFeet,
                   let climateElevationFeet = station.elevation {
                    elevationDifferenceFeet = abs(
                        climateElevationFeet - sourceElevationFeet
                    )
                } else {
                    elevationDifferenceFeet = nil
                }
                
                return ACISStationCandidate(
                    metadata: station,
                    stationID: stationID,
                    distanceMiles: distanceMiles,
                    elevationDifferenceFeet: elevationDifferenceFeet
                )
            }
            .sorted { firstCandidate, secondCandidate in
                firstCandidate.distanceMiles
                    < secondCandidate.distanceMiles
            }
    }
    
    /// Lightweight API request
    static func fetchNormalPeriodTemperatureObservations(
        stationID: String
    ) async throws -> [ACISDailyObservation] {
        let startDate =
            "\(GeneratedClimateProfileBuilder.normalStartYear)-01-01"

        let endDate =
            "\(GeneratedClimateProfileBuilder.normalEndYear)-12-31"

        var components = URLComponents(
            string: "https://data.rcc-acis.org/StnData"
        )

        components?.queryItems = [
            URLQueryItem(name: "sid", value: stationID),
            URLQueryItem(name: "sdate", value: startDate),
            URLQueryItem(name: "edate", value: endDate),
            URLQueryItem(name: "elems", value: "mint,maxt")
        ]

        guard let url = components?.url else {
            return []
        }

        let (data, _) = try await URLSession.shared.data(
            from: url
        )

        let response = try JSONDecoder().decode(
            ACISDailyDateResponse.self,
            from: data
        )

        return response.data.compactMap { row in
            ACISTemperatureObservationMapper.observation(
                from: row
            )
        }
    }
    
    /// Evaluate and sort the candidates
    static func evaluatedNearbyClimateCandidates(
        latitude: Double,
        longitude: Double,
        sourceElevationFeet: Double? = nil,
        radiusMiles: Double = 100.0,
        maximumCandidateCount: Int = 8
    ) async throws -> [ACISEvaluatedStationCandidate] {
        guard maximumCandidateCount > 0 else {
            return []
        }
        
        let nearbyCandidates =
            try await rankedNearbyClimateCandidates(
                latitude: latitude,
                longitude: longitude,
                sourceElevationFeet: sourceElevationFeet,
                radiusMiles: radiusMiles
            )
        
        var evaluatedCandidates:
            [ACISEvaluatedStationCandidate] = []
        
        for candidate in nearbyCandidates.prefix(
            maximumCandidateCount
        ) {
            let observations =
                try await fetchNormalPeriodTemperatureObservations(
                    stationID: candidate.stationID
                )
            
            guard let quality =
                    ACISStationQualityCalculator.quality(
                        fromNormalPeriodObservations: observations
                    ) else {
                continue
            }
            
            evaluatedCandidates.append(
                ACISEvaluatedStationCandidate(
                    candidate: candidate,
                    quality: quality
                )
            )
        }
        
        return evaluatedCandidates.sorted {
            firstCandidate,
            secondCandidate in
            
            if firstCandidate.recommendationTier
                != secondCandidate.recommendationTier {
                return firstCandidate.recommendationTier
                    < secondCandidate.recommendationTier
            }
            
            if firstCandidate.candidate.distanceMiles
                != secondCandidate.candidate.distanceMiles {
                return firstCandidate.candidate.distanceMiles
                    < secondCandidate.candidate.distanceMiles
            }
            
            return firstCandidate.quality.pairedCompleteness
                > secondCandidate.quality.pairedCompleteness
        }
        
    }
    
    static func fetchDailyObservations(
        stationID: String,
        startDate: String,
        endDate: String
    ) async throws -> [ACISDailyObservation] {
        var components = URLComponents(string: "https://data.rcc-acis.org/StnData")
        components?.queryItems = [
            URLQueryItem(name: "sid", value: stationID),
            URLQueryItem(name: "sdate", value: startDate),
            URLQueryItem(name: "edate", value: endDate),
            URLQueryItem(name: "elems", value: "mint,maxt,pcpn,snow,snwd")
        ]
        ///try to turn my URL components into a real URL. If that fails, stop here and return an empty array.
        ///components?.url is optional because URL construct can fail
        guard let url = components?.url else {
            return []
        }
        ///This actually downloads the raw response from ACIS, data is the JSON bytes.
        ///The underscore "_"_ means there is a second thing returned here, but I do not care about it right now.
        ///response.data is the ACIS matrix or table
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ACISDailyDateResponse.self, from: data)
        ///compactMap transforms every item and keeps only the successful non-nil results
        return response.data.compactMap { row in
            ACISDailyObservationMapper.observation(from: row)
        }
    }
}
