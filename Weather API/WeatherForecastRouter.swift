import Foundation

enum WeatherForecastRouterError: LocalizedError, Sendable {
    
    case unsupportedCountryCode(String)
    case providerNotRegistered(ForecastProviderID)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedCountryCode(let countryCode):
            return """
                No forecast provider is configured for country code \
                \(countryCode).
                """
            
        case .providerNotRegistered(let providerID):
            return """
                Forecast provider \(providerID.rawValue) is not registered.
                """
        }
    }
}

struct WeatherForecastRouter: Sendable {
    private let providers: [
        ForecastProviderID: any WeatherForecastProviding
    ]
    
    nonisolated init(
        providers: [any WeatherForecastProviding] = [
            NWSForecastProvider(),
            ECCCForecastProvider()
        ]
    ) {
        var registeredProviders: [
            ForecastProviderID: any WeatherForecastProviding
        ] = [:]
        
        for provider in providers {
            registeredProviders[provider.providerID] = provider
        }
        
        self.providers = registeredProviders
    }
    
    func forecast(
        for request: ForecastRequest
    ) async throws -> Forecast {
        let providerID = try selectedProviderID(
            for: request
        )
        
        guard let provider = providers[providerID] else {
            throw WeatherForecastRouterError
                .providerNotRegistered(providerID)
        }
        
        return try await provider.forecast(for: request)
    }
    
    private func selectedProviderID(
        for request: ForecastRequest
    ) throws -> ForecastProviderID {
        if let preferredProviderID =
            request.preferredProviderID {
            return preferredProviderID
        }
        
        switch request.countryCode {
        case "US", "USA":
            return .nwsHourly
            
        case "CA", "CAN":
            return .ecccMeteocode
            
        default:
            throw WeatherForecastRouterError
                .unsupportedCountryCode(request.countryCode)
        }
    }
}
