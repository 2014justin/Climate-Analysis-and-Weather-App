/// Creates the shared hourly frame sequence used by forecast playback.
///
/// A five-day forecast contains 120 one-hour intervals and therefore
/// 121 selectable boundary instants when both endpoints are included.

import Foundation

nonisolated enum ForecastHourlyTimeline {
    
    static let defaultForecastHourCount = 120
    
    static func instants(
        startingAt referenceDate: Date,
        forecastHourCount: Int = defaultForecastHourCount
    ) -> [Date] {
        guard forecastHourCount >= 0 else {
            return []
        }
        
        let secondsPerHour: TimeInterval = 60.00 * 60.00
        
        let startingHourSeconds =
            floor(
                referenceDate.timeIntervalSince1970 / secondsPerHour
            ) * secondsPerHour
        
        let startingHour = Date(
            timeIntervalSince1970: startingHourSeconds
        )
        
        return (0...forecastHourCount).map {
            hourOffset in
            
            startingHour.addingTimeInterval(Double(hourOffset) * secondsPerHour)
        }
    }
}
