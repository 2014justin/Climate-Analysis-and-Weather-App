import Foundation

/// A source capable of translating its native forecast product into the
/// provider-neautral forecast model used throughout the application.
///
/// Invididual providers remain responsible for resolving the requested
/// coordinate to their own station, grid cell, or forecast region.
///
/// Every forecast provider MUST have a providerID and MUST know how to produce a forecast.
///
/// The dashboard will have no idea if it is talking to NWS, Canada, Germany, France, Austrailia, it just
/// wants a forecast.

protocol WeatherForecastProviding: Sendable {
    /// Stable identify used by routing, caching, and metadata.
    nonisolated var providerID: ForecastProviderID { get }
    
    /// Fetches and translates the provider's best available forecast for
    /// the requested location.
    func forecast(
        for request: ForecastRequest
    ) async throws -> Forecast
}
