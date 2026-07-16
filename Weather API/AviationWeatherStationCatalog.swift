/// Supplies names, state/province, country, and priority. Aviation Weather
/// updates this catalog only once daily, so we'll eventually download it once per app session.
///

import Foundation

struct AviationWeatherStationMetadata:
    Decodable,
    Sendable {

    let id: String
    let icaoID: String?
    let site: String?
    let latitude: Double?
    let longitude: Double?
    let elevationMeters: Double?
    let stateOrProvince: String?
    let country: String?
    let priority: Int?
    let siteTypes: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case icaoID = "icaoId"
        case site
        case latitude = "lat"
        case longitude = "lon"
        case elevationMeters = "elev"
        case stateOrProvince = "state"
        case country
        case priority
        case siteTypes = "siteType"
    }

    var stationID: String {
        (
            Self.cleaned(icaoID)
            ?? Self.cleaned(id)
            ?? id
        )
        .uppercased()
    }

    var displayName: String {
        Self.cleaned(site) ?? stationID
    }

    var countryCode: String {
        Self.cleaned(country)?.uppercased()
            ?? "XX"
    }

    var stateOrProvinceCode: String? {
        Self.cleaned(stateOrProvince)?
            .uppercased()
    }

    private static func cleaned(
        _ value: String?
    ) -> String? {
        guard let value else {
            return nil
        }

        let cleanedValue = value
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return cleanedValue.isEmpty
            ? nil
            : cleanedValue
    }
}

struct AviationWeatherStationCatalog: Sendable {
    let stationsByID:
        [String: AviationWeatherStationMetadata]

    let downloadedAt: Date

    var stationCount: Int {
        stationsByID.count
    }

    subscript(
        stationID: String
    ) -> AviationWeatherStationMetadata? {
        stationsByID[stationID.uppercased()]
    }
}

enum AviationWeatherStationCatalogServiceError:
    LocalizedError,
    Sendable {

    case invalidURL
    case invalidResponse
    case unexpectedStatusCode(Int)
    case emptyCatalog

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return """
                Could not construct the Aviation \
                Weather station catalog URL.
                """

        case .invalidResponse:
            return """
                Aviation Weather returned an invalid \
                station catalog response.
                """

        case .unexpectedStatusCode(let statusCode):
            return """
                Aviation Weather returned HTTP \
                \(statusCode) for the station catalog.
                """

        case .emptyCatalog:
            return """
                The Aviation Weather station catalog \
                was empty.
                """
        }
    }
}

struct AviationWeatherStationCatalogService:
    Sendable {

    func fetchCatalog() async throws
        -> AviationWeatherStationCatalog {

        guard let url = URL(
            string: """
                https://aviationweather.gov/data/cache/stations.cache.json.gz
                """
        ) else {
            throw AviationWeatherStationCatalogServiceError
                .invalidURL
        }

        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 30
        )

        request.setValue(
            "WeatherAppSwiftLearningProject/v2.43",
            forHTTPHeaderField: "User-Agent"
        )

        let (compressedData, response) =
            try await URLSession.shared.data(
                for: request
            )

        guard let httpResponse =
                response as? HTTPURLResponse else {
            throw AviationWeatherStationCatalogServiceError
                .invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw AviationWeatherStationCatalogServiceError
                .unexpectedStatusCode(
                    httpResponse.statusCode
                )
        }

        let jsonData = try GzipDecompressor()
            .decompress(compressedData)

        let records = try JSONDecoder().decode(
            [AviationWeatherStationMetadata].self,
            from: jsonData
        )

        var stationsByID:
            [String: AviationWeatherStationMetadata] = [:]

        for record in records {
            let stationID = record.stationID

            guard !stationID.isEmpty else {
                continue
            }

            stationsByID[stationID] = record
        }

        guard !stationsByID.isEmpty else {
            throw AviationWeatherStationCatalogServiceError
                .emptyCatalog
        }

        return AviationWeatherStationCatalog(
            stationsByID: stationsByID,
            downloadedAt: Date()
        )
    }
}

