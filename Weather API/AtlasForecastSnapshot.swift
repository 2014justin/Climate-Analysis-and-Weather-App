/// One in-memory collection of forecasts for the Atlas's zoom-dependent visible station set.
///
/// Forecast failures are retained per station so the map can display an explicit unavailable state
/// instead of falling back to an observed temperature.
///

import Foundation

nonisolated struct AtlasForecastSnapshot: Sendable {
    
    let forecastsByStationID: [String: Forecast]
    
    let failureDescriptionsByStationID: [String: String]
    
    let loadedAt: Date
    
    let requestedStationCount: Int
    
    var loadedStationCount: Int {
        forecastsByStationID.count
    }
    
    var failedStationCount: Int {
        failureDescriptionsByStationID.count
    }
    
    func forecast(
        for observation: AtlasObservation
    ) -> Forecast? {
        forecastsByStationID[observation.station.id]
    }
    
    func failureDescription(
        for observation: AtlasObservation
    ) -> String? {
        failureDescriptionsByStationID[observation.station.id]
    }
}
