import Foundation
import CoreLocation
import MapKit

/// This keeps the existing authoritative NWS behavior for America and uses Apple's coordinate lookup for
/// Canada. Supplying coordinates does not require requesting the user's physical location.
struct AtlasStationTimeZoneResolver {
    nonisolated init() {}
    
    func timeZone(
        for station: AtlasStation
    ) async throws -> TimeZone? {
        switch station.source.countryCode {
        case "US" :
            return try await unitedStatesTimeZone(
                for: station
            )
            
        case "CA":
            return try await coordinateTimeZone(
                for: station
            )
            
        default:
            return nil
        }
    }
    
    private func unitedStatesTimeZone(
        for station: AtlasStation
    ) async throws -> TimeZone? {
        let metadata = try await WeatherService()
            .fetchStationMetadata(stationID: station.source.stationID)
        
        guard let identifier = metadata.properties.timeZone
                
        else {
            return nil
        }
        
        return TimeZone(identifier: identifier)
    }
    
    private func coordinateTimeZone(
        for station: AtlasStation
    ) async throws -> TimeZone? {
        let location = CLLocation(
            latitude: station.latitude,
            longitude: station.longitude
        )
        
        guard let request = MKReverseGeocodingRequest(
            location: location
        ) else {
            return nil
        }

        let mapItems = try await request.mapItems

        return mapItems.first?.timeZone
    }
}
