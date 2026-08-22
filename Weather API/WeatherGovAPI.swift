import Foundation

nonisolated enum WeatherGovAPI {
    static let providerID = "weatherGov"

    static let userAgent =
        "Weather&ClimateAtlasSwiftApp/v3.0 "
        + "(https://github.com/2014justin/"
        + "Climate-Analysis-and-Weather-App)"

    /// Records each real network request by endpoint and
    /// outcome. A missing latest observation is tracked
    /// separately from a genuine API failure.
    static func data(
        for request: URLRequest
    ) async throws -> (
        Data,
        URLResponse
    ) {
        let meter =
            WeatherGovAPIActivityMeter.shared

        let endpoint =
            WeatherGovAPIEndpointKind(
                url: request.url
            )

        let requestID =
            await meter.requestStarted(
                endpoint: endpoint
            )

        do {
            let result =
                try await URLSession.shared.data(
                    for: request
                )

            let outcome =
                WeatherGovAPIRequestOutcome(
                    response: result.1,
                    endpoint: endpoint
                )

            await meter.requestFinished(
                requestID: requestID,
                outcome: outcome
            )

            return result
        } catch {
            await meter.requestFinished(
                requestID: requestID,
                outcome: .transportFailure
            )

            throw error
        }
    }

    static func request(
        for url: URL,
        includeStationProviderMetadata:
            Bool = false
    ) -> URLRequest {
        var request =
            URLRequest(
                url: url,
                cachePolicy:
                    .useProtocolCachePolicy,
                timeoutInterval: 30
            )

        request.setValue(
            userAgent,
            forHTTPHeaderField:
                "User-Agent"
        )

        if includeStationProviderMetadata {
            request.setValue(
                "obs_station_provider",
                forHTTPHeaderField:
                    "Feature-Flags"
            )
        }

        return request
    }
}
