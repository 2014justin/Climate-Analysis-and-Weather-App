import Foundation

enum ECCCClimateDailyServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unexpectedStatusCode(Int)
    case invalidDateRange
    case paginationLoop
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not construct the ECCC climate-daily URL."
        case .invalidResponse:
            return "ECCC returned an invalid climate-daily response."
        case .unexpectedStatusCode(let statusCode):
            return "ECCC returned HTTP \(statusCode) for climate-daily data."
        case .invalidDateRange:
            return "The ECCC climate request has an invalid date range."
        case .paginationLoop:
            return "ECCC returned a repeating climate-daily pagination link."
        }
    }
}

struct ECCCClimateDailyService {
    private let session: URLSession
    
    nonisolated init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchObservations(
        climateIdentifier: String,
        startDate: ClimateDate,
        endDate: ClimateDate
    ) async throws -> [ClimateDailyObservation] {
        guard startDate <= endDate else {
            throw ECCCClimateDailyServiceError.invalidDateRange
        }
        
        var nextURL: URL? = try initialURL(
            climateIdentifier: climateIdentifier,
            startDate: startDate,
            endDate: endDate
        )
        
        var visitedURLs = Set<URL>()
        var observations: [ClimateDailyObservation] = []
        
        while let pageURL = nextURL {
            guard visitedURLs.insert(pageURL).inserted else {
                throw ECCCClimateDailyServiceError.paginationLoop
            }
            
            var request = URLRequest(
                url: pageURL,
                cachePolicy: .useProtocolCachePolicy,
                timeoutInterval: 60
            )
            
            request.setValue(
                "Weather & Climate Atlas Swift App v1.53b",
                forHTTPHeaderField: "User-Agent"
            )
            
            request.setValue(
                "application/geo+json, application/json",
                forHTTPHeaderField: "Accept"
            )
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ECCCClimateDailyServiceError.invalidResponse
            }
            
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw ECCCClimateDailyServiceError.unexpectedStatusCode(
                    httpResponse.statusCode
                )
            }
            
            let page = try JSONDecoder().decode(
                ECCCClimateDailyPage.self,
                from: data
            )
            
            observations.append(
                contentsOf: page.features.compactMap {
                    ECCCClimateDailyObservationMapper.observation(from: $0)
                }
            )
            
            nextURL = page.links
                .first { $0.rel.lowercased() == "next" }
                /// FlatMap is taking an optional link and transforming it into the next page URL
                /// while gracefully handling the case where there isn't one. 'href' might be "...page=2..."
                /// FlatMap is removing one layer of optionality.
                /// If the page has no 'next' section, the whole expression simply evaluates to nil.
                ///  In that sense it is kind of a while loop.
                /// Keep asking for the next page until the server stops giving me one.
                .flatMap {
                    URL(string: $0.href, relativeTo: pageURL)?.absoluteURL
                }
        }
        
        /// What if the API gives me the same day twice? The dictionary removed duplicates automatically
        /// When you write observationByDate... Swift interprets that is "Store this observation under this data.
        /// If one already exists, Jan 1 -> Old Obs, and another one comes in Jan 1 -> new obs
        /// the dictionary becomes: Jan 1 -> new obs. Exactly one survives. This is called deduplication.
        ///
        /// It scales naturally from "pagination deduplication" today to "merging historical station threads later".
        var observationByDate: [
            ClimateDate: ClimateDailyObservation
        ] = [:]
        
        for observation in observations {
            observationByDate[observation.localDate] = observation
        }
        
        /// Sorts it because our Fourier fitter likes the dates sorted.
        return observationByDate.values.sorted {
            $0.localDate < $1.localDate
        }
    }
    
    private func initialURL(
        climateIdentifier: String,
        startDate: ClimateDate,
        endDate: ClimateDate
    ) throws -> URL {
        var components = URLComponents(
            string: """
                https://api.weather.gc.ca/collections/climate-daily/items
                """
        )
        
        components?.queryItems = [
            URLQueryItem(
                name: "f",
                value: "json"
            ),
            URLQueryItem(
                name: "CLIMATE_IDENTIFIER",
                value: climateIdentifier
            ),
            URLQueryItem(
                name: "datetime",
                value: "\(apiDate(startDate))/\(apiDate(endDate))"
            ),
            URLQueryItem(
                name: "properties",
                value: [
                    "LOCAL_DATE",
                    "MIN_TEMPERATURE",
                    "MIN_TEMPERATURE_FLAG",
                    "MAX_TEMPERATURE",
                    "MAX_TEMPERATURE_FLAG"
                ].joined(separator: ",")
            ),
            URLQueryItem(
                name: "sortby",
                value: "LOCAL_DATE"
            ),
            URLQueryItem(
                name: "limit",
                value: "10000"
            )
        ]
        
        guard let url = components?.url else {
            throw ECCCClimateDailyServiceError.invalidURL
        }
        
        return url
    }
    
    /// ECCC server expects text in ISO-8601 calendar. This converts Swift Object -> 1991-01-03.
    /// startDate = 1991-01-01, endDate = 2020-12-31
    ///
    /// The query becomes datetime = 1991-01-01/2020-12-31.
    ///
    /// Our URL might look something like: https://api.weather.gc.ca/collections/climate-daily/items?
    /// CLIMATE_IDENTIFIER=6158733&
    /// datetime=1991-01-01/2020-12-31
    private func apiDate(_ date: ClimateDate) -> String {
        String(
            format: "%04d-%02d-%02d",
            date.year,
            date.month,
            date.day
        )
    }
}

private struct ECCCClimateDailyPage: Decodable {
    let features: [ECCCClimateDailyFeature]
    let links: [ECCCClimateDailyLink]
}

private struct ECCCClimateDailyFeature: Decodable {
    let properties: ECCCClimateDailyProperties
}

private struct ECCCClimateDailyLink: Decodable {
    let rel: String
    let href: String
}

private struct ECCCClimateDailyProperties: Decodable {
    let localDate: String
    let minimumTemperatureCelsius: Double?
    let minimumTemperatureFlag: String?
    let maximumTemperatureCelsius: Double?
    let maximumTemperatureFlag: String?
    
    enum CodingKeys: String, CodingKey {
        case localDate = "LOCAL_DATE"
        case minimumTemperatureCelsius = "MIN_TEMPERATURE"
        case minimumTemperatureFlag = "MIN_TEMPERATURE_FLAG"
        case maximumTemperatureCelsius = "MAX_TEMPERATURE"
        case maximumTemperatureFlag = "MAX_TEMPERATURE_FLAG"
    }
}

/// The translation layer between the ECCC's raw JSON-shaped data and the app's clean, provider-neutral climate model.
/// The service does three broad jobs: Download JSON -> Decode JSON into ECCC-specific structs -> map
/// those structs into ClimateDailyObservations.
/// In one flow, this enum converts stuff that looks like:
///
///
///LOCAL_DATE = "1991-01-03T00:00:00"
///MIN_TEMPERATURE = -9.0
///MIN_TEMPERATURE_FLAG = nil
///MAX_TEMPERATURE = -2.5
///MAX_TEMPERATURE_FLAG = "E"
///
///Into ->
///
///ClimateDailyObservation(
///localDate: ClimateDate(
    ///year: 1991,
    ///month: 1,
    ///day: 3
///),
///minimumTemperature: ClimateTemperatureReading(
/// fahrenheit: 15.8,
/// quality: .observed,
/// sourceFlag: nil
///),
///maximumTemperature: ClimateTemperatureReading(
/// fahrenheit: 27.5,
/// quality: .estimated,
/// sourceFlag: "E"
///)
///)
private enum ECCCClimateDailyObservationMapper {
    static func observation(
        from feature: ECCCClimateDailyFeature
    ) -> ClimateDailyObservation? {
        let properties = feature.properties
        
        guard let localDate = climateDate(
            from: properties.localDate
        ) else {
            return nil
        }
        
        return ClimateDailyObservation(
            localDate: localDate,
            minimumTemperature: reading(
                celsius: properties.minimumTemperatureCelsius,
                flag: properties.minimumTemperatureFlag
            ),
            maximumTemperature: reading(
                celsius: properties.maximumTemperatureCelsius,
                flag: properties.maximumTemperatureFlag
            )
        )
    }
    
    private static func climateDate(
        from rawValue: String
    ) -> ClimateDate? {
        let dateText = String(rawValue.prefix(10))
        let components = dateText.split(separator: "-")
        
        guard components.count == 3,
              let year = Int(components[0]),
              let month = Int(components[1]),
              let day = Int(components[2]) else {
            return nil
        }
        
        return ClimateDate(
            year: year,
            month: month,
            day: day
        )
    }
    
    private static func reading(
        celsius: Double?,
        flag: String?
    ) -> ClimateTemperatureReading {
        let trimmedFlag = flag?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let sourceFlag = trimmedFlag?.isEmpty == false
            ? trimmedFlag
            : nil
        
        guard let celsius else {
            return ClimateTemperatureReading(
                fahrenheit: nil,
                quality: .missing,
                sourceFlag: sourceFlag
            )
        }
        
        let quality: ClimateObservationQuality
        
        switch sourceFlag?.uppercased() {
        case nil:
            quality = .observed
        case "E":
            quality = .estimated
        case "M","N","Y":
            quality = .missing
        default:
            quality = .rejected
        }
        
        return ClimateTemperatureReading(
            fahrenheit: WeatherMath.celsiusToFahrenheit(celsius),
            quality: quality,
            sourceFlag: sourceFlag
        )
    }
}
