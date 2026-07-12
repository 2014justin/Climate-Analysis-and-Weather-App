import Foundation

struct WeatherService {
    private func observationsURL(stationID: String, hours: Int) throws -> URL {
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(
            -Double(hours) * 60.0 * 60.0
        )

        let formatter = ISO8601DateFormatter()

        var components = URLComponents(
            string: "https://api.weather.gov/stations/\(stationID)/observations"
        )

        components?.queryItems = [
            URLQueryItem(
                name: "start",
                value: formatter.string(from: startDate)
            ),
            URLQueryItem(
                name: "end",
                value: formatter.string(from: endDate)
            ),
            URLQueryItem(
                name: "limit",
                value: "500"
            )
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        return url
    }
    func fetchLatestObservationData() async throws -> Data {
        guard let url = URL(
            string: "https://api.weather.gov/stations/F0069/observations?limit=500"
        ) else {
            throw URLError(.badURL)
        }
        return try await fetchData(from: url)
    }
    
    func fetchRecentObservations(
        stationID: String,
        hours: Int
    ) async throws -> NWSObservationResponse {
        var nextURL: URL? = try observationsURL(stationID: stationID, hours: hours)
        var allFeatures: [NWSObservationFeature] = []
        
        while let pageURL = nextURL {
            let data = try await fetchData(from: pageURL)
            let page = try decodeObservations(from: data)
            
            allFeatures.append(contentsOf: page.features)
            nextURL = page.pagination?.next
        }
        
        return NWSObservationResponse(
            features: allFeatures,
            pagination: nil
        )
    }
    
    func fetchHourlyForecast(
        latitude: Double,
        longitude: Double,
    ) async throws -> NWSHourlyForecastResponse {
        guard let pointURL = URL(
            string: "https://api.weather.gov/points/\(latitude),\(longitude)"
        ) else {
            throw URLError(.badURL)
        }
        
        let pointData = try await fetchData(from: pointURL)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let pointResponse = try decoder.decode(
            NWSPointResponse.self,
            from: pointData
        )
        
        let forecastData = try await fetchData(
            from: pointResponse.properties.forecastHourly
        )
        
        return try decoder.decode(
            NWSHourlyForecastResponse.self,
            from: forecastData
        )
    }
    
    func fetchForecastOffice(
        latitude: Double,
        longitude: Double
    ) async throws -> String {
        guard let pointURL = URL(
            string:
                "https://api.weather.gov/points/"
                + "\(latitude),\(longitude)"
        ) else {
            throw URLError(.badURL)
        }
        
        let pointData = try await fetchData(
            from: pointURL
        )
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let pointResponse = try decoder.decode(
            NWSPointResponse.self,
            from: pointData
        )
        
        guard let office =
                pointResponse.properties.gridId?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
              office.isEmpty == false else {
            throw URLError(.cannotParseResponse)
        }
        
        return office.uppercased()
    }
    
    func fetchLatestForecastDiscussion(
        office: String
    ) async throws -> ForecastDiscussion {
        let listURL = URL(string: "https://api.weather.gov/products/types/AFD/locations/\(office)")!
        
        let listData = try await fetchData(from: listURL)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let listResponse = try decoder.decode(ForecastDiscussionListResponse.self, from: listData)
        
        guard let latestSummary = listResponse.graph.first else {
            throw URLError(.badServerResponse)
        }
        
        let discussionURL = URL(string: "https://api.weather.gov/products/\(latestSummary.id)")!
        
        let discussionData = try await fetchData(from: discussionURL)
        
        let discussion = try decoder.decode(ForecastDiscussion.self, from: discussionData)
        
        return discussion
    }
    
    private func fetchData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        
        request.setValue(
            "WeatherAPILearningProject/v1.0",
            forHTTPHeaderField: "User-Agent"
        )
        
        let (data, response) = try await URLSession.shared.data(
            for: request
        )
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return data
        
    }
    
    ///fetch station metadata via api.weather.gov.
    func fetchStationMetadata(
        stationID: String
    ) async throws -> NWSStationResponse {
        let safeStationID = stationID
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        
        guard let url = URL(
            string: "https://api.weather.gov/stations/\(safeStationID)"
        ) else {
            throw URLError(.badURL)
        }
        
        let data = try await fetchData(from: url)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(
            NWSStationResponse.self,
            from: data
        )
    }
    
    func decodeObservations(from data: Data) throws -> NWSObservationResponse {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(
            NWSObservationResponse.self,
            from: data
        )
    }
}
