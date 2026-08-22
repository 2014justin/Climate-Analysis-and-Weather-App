import Foundation

nonisolated struct
WeatherGovPointStateResponse:
    Decodable,
    Sendable {

    let properties:
        WeatherGovPointStateProperties
}

nonisolated struct
WeatherGovPointStateProperties:
    Decodable,
    Sendable {

    let relativeLocation:
        WeatherGovRelativeLocation?
}

nonisolated struct
WeatherGovRelativeLocation:
    Decodable,
    Sendable {

    let properties:
        WeatherGovRelativeLocationProperties
}

nonisolated struct
WeatherGovRelativeLocationProperties:
    Decodable,
    Sendable {

    let state: String?
}

nonisolated enum
WeatherGovStateCodeServiceError:
    LocalizedError,
    Sendable {

    case invalidCoordinate
    case invalidURL
    case invalidResponse
    case unexpectedStatusCode(Int)

    var errorDescription: String? {
        switch self {
        case .invalidCoordinate:
            return """
                Weather.gov state lookup received \
                an invalid coordinate.
                """

        case .invalidURL:
            return """
                Could not construct the Weather.gov \
                point URL.
                """

        case .invalidResponse:
            return """
                Weather.gov returned an invalid \
                point response.
                """

        case .unexpectedStatusCode(let statusCode):
            return """
                Weather.gov returned HTTP \
                \(statusCode) for the point lookup.
                """
        }
    }
}

nonisolated struct
WeatherGovStateCodeService:
    Sendable {

    func fetchStateCode(
        latitude: Double,
        longitude: Double
    ) async throws -> String? {

        guard latitude.isFinite,
              longitude.isFinite,
              (-90...90).contains(latitude),
              (-180...180).contains(longitude) else {
            throw WeatherGovStateCodeServiceError
                .invalidCoordinate
        }

        let locale =
            Locale(identifier: "en_US_POSIX")

        let latitudeText =
            String(
                format: "%.4f",
                locale: locale,
                latitude
            )

        let longitudeText =
            String(
                format: "%.4f",
                locale: locale,
                longitude
            )

        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.weather.gov"
        components.path =
            "/points/\(latitudeText),\(longitudeText)"

        guard let url = components.url else {
            throw WeatherGovStateCodeServiceError
                .invalidURL
        }

        let request =
            WeatherGovAPI.request(for: url)

        let (data, response) =
            try await WeatherGovAPI.data(
                for: request
            )

        guard let httpResponse =
                response as? HTTPURLResponse else {
            throw WeatherGovStateCodeServiceError
                .invalidResponse
        }

        if httpResponse.statusCode == 404 {
            return nil
        }

        guard httpResponse.statusCode == 200 else {
            throw WeatherGovStateCodeServiceError
                .unexpectedStatusCode(
                    httpResponse.statusCode
                )
        }

        let responseBody =
            try JSONDecoder().decode(
                WeatherGovPointStateResponse.self,
                from: data
            )

        guard let rawStateCode =
                responseBody
                    .properties
                    .relativeLocation?
                    .properties
                    .state else {
            return nil
        }

        let stateCode =
            rawStateCode
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .uppercased()

        guard stateCode.range(
            of: #"^[A-Z]{2}$"#,
            options: .regularExpression
        ) != nil else {
            return nil
        }

        return stateCode
    }
}
