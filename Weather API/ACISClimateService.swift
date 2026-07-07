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
///temperature field
enum ACISTemperatureField {
    case minimum
    case maximum
    
    func value(from observation: ACISDailyObservation) -> Double? {
        switch self {
        case .minimum:
            return observation.minimumTemperature
        case .maximum:
            return observation.maximumTemperature
        }
    }
}
///threshold comparison, maximum or minimum temp
enum ACISThresholdComparison {
    case lessThan
    case lessThanOrEqual
    case greaterThan
    case greaterThanOrEqual
    
    func matches(value: Double, threshold: Double) -> Bool {
        switch self {
        case .lessThan:
            return value < threshold
        case .lessThanOrEqual:
            return value <= threshold
        case .greaterThan:
            return value > threshold
        case .greaterThanOrEqual:
            return value >= threshold
        }
    }
}
///season eventwhen we find matching dates, do we want the first one or the last one?
///so like the last afternoon high below 80 degrees in las vegas is late may.
enum ACISSeasonEventChoice {
    case first
    case last
    
    func date(from dates: [Date]) -> Date? {
        switch self {
        case .first:
            return dates.min()
        case .last:
            return dates.max()
        }
    }
}

///Define threshold seasons like date of last spring freeze & first fall freeze. But eventually we can do any temperature
///threshold.
///Las vegas might not hit mintemp less than 20 every year, so last spring, and first fall might be nil.
struct ACISThresholdSeason: Identifiable {
    let id = UUID()
    let year: Int
    let lastSpringDate: Date?
    let firstFallDate: Date?
}
///custom struct that returns threshold percent after/before a certain date.
///this works for 20, 26, 28, 32, 36, 40, 45 and gives you the percentile bands.
///this is incredibly useful for agriculture.
struct ACISThresholdRiskPoint: Identifiable {
    let percent: Double
    let springRiskDay: Double?
    let fallRiskDay: Double?
    
    var id: Double { percent }
}

///Threshold Summary for nice compactness
struct ACISThresholdSummary {
    let startYear: Int
    let endYear: Int
    let threshold: Double
    let seasons: [ACISThresholdSeason]
    let completeSeasonCount: Int
    let springEventCount: Int
    let fallEventCount: Int
    let averageLastSpringDay: Double?
    let averageFirstFallDay: Double?
    let averageAboveThresholdSeasonLength: Double?
    let thresholdRiskPoints: [ACISThresholdRiskPoint]
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

enum WeatherYearCalculator {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }()
    
    private static func referenceDate(from date: Date) -> Date? {
        let components = calendar.dateComponents([.month, .day], from: date)
        
        guard let month = components.month,
              let day = components.day else {
            return nil
        }
        
        if month == 2 && day == 29 {
            return nil
        }
        
        return calendar.date(
            from: DateComponents(year: 2001, month: month, day: day)
        )
    }
    
    private static func referenceDayOfYear(from date: Date) -> Int? {
        guard let referenceDate = referenceDate(from: date) else {
            return nil
        }
        
        return calendar.ordinality(of: .day, in: .year, for: referenceDate)
    }
    
    static func weatherYearDays(
        from observations: [ACISDailyObservation],
        selectedYear: Int,
        location: WeatherLocation
    ) -> [WeatherYearDay] {
        var observationsByDay: [Int: [ACISDailyObservation]] = [:]
        var selectedYearObservationsByDay: [Int: ACISDailyObservation] = [:]
        
        for observation in observations {
            guard let dayOfYear = referenceDayOfYear(from: observation.date) else {
                continue
            }
            
            observationsByDay[dayOfYear, default: []].append(observation)
            
            if calendar.component(.year, from: observation.date) == selectedYear {
                selectedYearObservationsByDay[dayOfYear] = observation
            }
        }
        
        let startDate = calendar.date(
            from: DateComponents(year: 2001, month:1, day: 1)
        )!
        
        return(1...365).compactMap { dayOfYear in
            guard let date = calendar.date(
                byAdding: .day,
                value: dayOfYear - 1,
                to: startDate
            ) else {
                return nil
            }
            
            let dayObservations = observationsByDay[dayOfYear] ?? []
            let selectedObservation = selectedYearObservationsByDay[dayOfYear]
            
            let minimumTemperatures = dayObservations.compactMap { observation in
                observation.minimumTemperature
            }
            
            let maximumTemperatures = dayObservations.compactMap { observation in
                observation.maximumTemperature
            }
            
            return WeatherYearDay(
                dayOfYear: dayOfYear,
                date: date,
                selectedYearMinimum: selectedObservation?.minimumTemperature,
                selectedYearMaximum: selectedObservation?.maximumTemperature,
                normalLow: WeatherAlmanac.normalLowFahrenheit(
                    dayOfYear: dayOfYear,
                    profile: location.climatologyProfile
                ),
                normalHigh: WeatherAlmanac.normalHighFahrenheit(
                    dayOfYear: dayOfYear,
                    profile: location.climatologyProfile
                ),
                recordLowMinimum: minimumTemperatures.min(),
                recordHighMaximum: maximumTemperatures.max(),
                recordWarmMinimum: minimumTemperatures.max(),
                recordCoolMaximum: maximumTemperatures.min(),
                sampleCount: dayObservations.count
            )
        }
    }
    
    static func recordInfo(from observations: [ACISDailyObservation]) -> WeatherYearRecordInfo {
        let years = Set(
            observations.map { observation in
                calendar.component(.year, from: observation.date)
            }
        )
        
        return WeatherYearRecordInfo(
            startDate: observations.map { $0.date }.min(),
            endDate: observations.map { $0.date }.max(),
            rowCount: observations.count,
            representedYearCount: years.count
        )
    }
}

///This asks ACIS for daily station data and returns ACISDailyObservation
enum ACISClimateService {
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

///Threshold calculator
enum ACISThresholdCalculator {
    static func thresholdSeason(
        from observations: [ACISDailyObservation],
        year: Int,
        threshold: Double,
        field: ACISTemperatureField = .minimum,
        comparison: ACISThresholdComparison = .lessThanOrEqual,
        springEventChoice: ACISSeasonEventChoice = .last,
        fallEventChoice: ACISSeasonEventChoice = .first
    ) -> ACISThresholdSeason {
        let calendar = Calendar(identifier: .gregorian)
        ///filters observations to temps in spring that match our threshold
        ///the number 8 is because thermal midsommar boundary is usually Aug 1.
        let springObservations = observations.filter { observation in
            guard let temperatureValue = field.value(from: observation),
                  calendar.component(.year, from: observation.date) == year,
                  calendar.component(.month, from: observation.date) < 8 else {
                return false
            }
            
            return comparison.matches(value: temperatureValue, threshold: threshold)
        }

        let fallObservations = observations.filter { observation in
            guard let temperatureValue = field.value(from: observation),
                  calendar.component(.year, from: observation.date) == year,
                  calendar.component(.month, from: observation.date) >= 8 else {
                return false
            }
            
            return comparison.matches(value: temperatureValue, threshold: threshold)
        }
        /// last spring date is when the latest 32 F morning was found in the spring column, hence the max
        /// first fall date is when the earliest 32 F morning was found in the fall column, hence the minimum
        let lastSpringDate = springEventChoice.date(
            from: springObservations.map { $0.date }
        )

        let firstFallDate = fallEventChoice.date(
            from: fallObservations.map { $0.date }
        )
        
        return ACISThresholdSeason(
            year: year,
            lastSpringDate: lastSpringDate,
            firstFallDate: firstFallDate
        )
    }
    static func thresholdSeasons(
        from observations: [ACISDailyObservation],
        startYear: Int,
        endYear: Int,
        threshold: Double,
        field: ACISTemperatureField = .minimum,
        comparison: ACISThresholdComparison = .lessThanOrEqual,
        springEventChoice: ACISSeasonEventChoice = .last,
        fallEventChoice: ACISSeasonEventChoice = .first
    ) -> [ACISThresholdSeason] {
        (startYear...endYear).map { year in
            thresholdSeason(
                from: observations,
                year: year,
                threshold: threshold,
                field: field,
                comparison: comparison,
                springEventChoice: springEventChoice,
                fallEventChoice: fallEventChoice
            )
        }
    }
    
    ///turns each data into day of year
    static func averageDayOfYear(from dates: [Date]) -> Double? {
        let calendar = Calendar(identifier: .gregorian)
        
        let dayValues = dates.compactMap { date in
            calendar.ordinality(of: .day, in: .year, for: date)
        }
        
        guard dayValues.isEmpty == false else {
            return nil
        }
        
        let total = dayValues.reduce(0, +)
        return Double(total) / Double(dayValues.count)
    }
    ///percentile calculator for freeze dates. calculates "there is x % chance of a freeze after this spring date"
    ///fall calculator says "there is an x % chance of a freeze BEFORE this fall date. Useful for agriculture
    static func percentileDayOfYear(
        from dates: [Date], ///input is an array of dates
        percentile: Double /// input the desired percentile, like 10, 50, 90.
    ) -> Double? { ///output an optional double, optional because if there are no usable dates
        ///there is no percentile to calculate.
        let calendar = Calendar(identifier: .gregorian)
        
        let sortedDayValues = dates
            .compactMap { date in
                calendar.ordinality(of: .day, in: .year, for: date)
            } ///converts each date into day of year.
        /// need a compact map because ordinality returns an optional Int. If swift cannot convert a date for some reason
        /// it skips that value
            .sorted()
        ///if sorted day value is empty is FALSE
        ///
        ///the guard says if the sorted list is NOT empty, keep going. otherwise, stop and return 'nil'.
        ///if we input the empty set [] the function safely says nil. without this guard, the next lines
        ///would eventually try to access an index in an empty array, which would crash.
        guard sortedDayValues.isEmpty == false else {
            return nil
        }
        ///define percentiles. ensures we cannot do a -20 % percentile
        let clampedPercentile = min(max(percentile, 0.0), 100.0)
        ///rank converts the percentile into a position in the sorted array. If there are 30
        ///If thre are 30 years of dates, the valid array indicies are 0 through 29.
        ///0th percentile points near index 0, 50th near 14.5, 100th near 29.
        let rank = (clampedPercentile / 100.0) * Double(sortedDayValues.count - 1)
        ///If rank is 14.5, lower index is 14
        let lowerIndex = Int(floor(rank))
        ///if rank is 14.5, upper index is 15
        let upperIndex = Int(ceil(rank))
        
        if lowerIndex == upperIndex {
            return Double(sortedDayValues[lowerIndex])
        }
        ///grabs the two neighboring day-of-year values
        let lowerValue = Double(sortedDayValues[lowerIndex])
        let upperValue = Double(sortedDayValues[upperIndex])
        ///finds how far between them we are. If the rank is 14.25, fraction is 0.25
        let fraction = rank - Double(lowerIndex)
        
        return lowerValue + (upperValue - lowerValue) * fraction
    }
    
    ///calc spring freeze risk
    static func springThresholdRiskDay(
        from seasons: [ACISThresholdSeason],
        percentChanceAfter: Double
    ) -> Double? {
        let springDates = seasons.compactMap { season in
            season.lastSpringDate
        }
        
        let percentile = 100.0 - percentChanceAfter
        
        return percentileDayOfYear(
            from: springDates,
            percentile: percentile
        )
    }
    ///calc fall freeze risk
    static func fallThresholdRiskDay(
        from seasons: [ACISThresholdSeason],
        percentChanceBefore: Double
    ) -> Double? {
        let fallDates = seasons.compactMap { season in
            season.firstFallDate
        }
        
        return percentileDayOfYear(
            from: fallDates,
            percentile: percentChanceBefore
        )
    }
    
    static func monthDayText(fromAverageDayOfYear averageDay: Double?) -> String {
        guard let averageDay else {
            return "none"
        }
        ///rounds calendar dates. Use 2001 as a non-leap reference year.
        let calendar = Calendar(identifier: .gregorian)
        let roundedDay = Int(averageDay.rounded())
        
        guard let date = calendar.date(
            from: DateComponents(year: 2001, day: roundedDay)
        ) else {
            return "none"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        return formatter.string(from: date)
    }
    
    static func averageAboveThresholdSeasonLength(from seasons: [ACISThresholdSeason]) -> Double? {
        let calendar = Calendar(identifier: .gregorian)
        
        let lengths = seasons.compactMap { season -> Int? in
            guard let lastSpringDate = season.lastSpringDate,
                  let firstFallDate = season.firstFallDate,
                  let springDay = calendar.ordinality(of: .day, in: .year, for: lastSpringDate),
                  let fallDay = calendar.ordinality(of: .day, in: .year, for: firstFallDate) else {
                return nil
            }
            
            return fallDay - springDay
        }
        
        guard lengths.isEmpty == false else {
            return nil
        }
        
        let total = lengths.reduce(0, +)
        return Double(total) / Double(lengths.count)
    }
    
    ///refrence threshold summary
    static func thresholdSummary(
        from observations: [ACISDailyObservation],
        startYear: Int,
        endYear: Int,
        threshold: Double,
        field: ACISTemperatureField = .minimum,
        comparison: ACISThresholdComparison = .lessThanOrEqual,
        springEventChoice: ACISSeasonEventChoice = .last,
        fallEventChoice: ACISSeasonEventChoice = .first
    ) -> ACISThresholdSummary {
        let seasons = thresholdSeasons(
            from: observations,
            startYear: startYear,
            endYear: endYear,
            threshold: threshold,
            field: field,
            comparison: comparison,
            springEventChoice: springEventChoice,
            fallEventChoice: fallEventChoice
        )
        ///Look through all the yearly threshold seasons. Keep only the years where we found both
        ///a last spring freeze date and a first fall freeze date. Then count how many year survived.
        ///So both spring and fall must have a freeze event to count.
        ///Miami rould return nil here for most years as they can go decades without a freeze.
        let completeSeasonCount = seasons.filter { season in
            season.lastSpringDate != nil && season.firstFallDate != nil
        }.count
        ///Next two constants are good for super warm climates that don't have a guaranteed freeze.
        ///since there might be a spring freeze but no corresponding fall freeze. Locations like
        ///Phoenix , AZ and Miami FL.
        let springEventCount = seasons.filter { season in
            season.lastSpringDate != nil
        }.count
        
        let fallEventCount = seasons.filter { season in
            season.firstFallDate != nil
        }.count
        
        let springDates = seasons.compactMap { season in
            season.lastSpringDate
        }
        
        let fallDates = seasons.compactMap { season in
            season.firstFallDate
        }
        
        let averageLastSpringDay = averageDayOfYear(from: springDates)
        let averageFirstFallDay = averageDayOfYear(from: fallDates)
        let averageAboveThresholdSeasonLength = averageAboveThresholdSeasonLength(from: seasons)

        let riskPercents = Array(stride(from: 10.0, through: 90.0, by: 10.0))

        let thresholdRiskPoints = riskPercents.map { percent in
            ACISThresholdRiskPoint(
                percent: percent,
                springRiskDay: springThresholdRiskDay(
                    from: seasons,
                    percentChanceAfter: percent
                ),
                fallRiskDay: fallThresholdRiskDay(
                    from: seasons,
                    percentChanceBefore: percent
                )
            )
        }
        
        return ACISThresholdSummary(
            startYear: startYear,
            endYear: endYear,
            threshold: threshold,
            seasons: seasons,
            completeSeasonCount: completeSeasonCount,
            springEventCount: springEventCount,
            fallEventCount: fallEventCount,
            averageLastSpringDay: averageLastSpringDay,
            averageFirstFallDay: averageFirstFallDay,
            averageAboveThresholdSeasonLength: averageAboveThresholdSeasonLength,
            thresholdRiskPoints: thresholdRiskPoints
        )
    }
}
