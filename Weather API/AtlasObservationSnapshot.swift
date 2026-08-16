import Foundation

/// One worldwide live-weather download held in memory.
///
/// Map movement will filter this collection locally instead
/// of issuing another network request.
struct AtlasObservationSnapshot: Sendable {
    let observations: [AtlasObservation]
    let downloadedAt: Date
    let rawReportCount: Int
}
/// Converts the provider-facing Atlas observations into the compact, provider-agnostic samples retained by the rolling avg.
extension AtlasObservationSnapshot {
    var temperatureHistorySamples: [AtlasTemperatureHistorySample] {
        observations.map { observation in
            AtlasTemperatureHistorySample(
                stationID: observation.station.id,
                observedAt: observation.observedAt,
                temperatureFahrenheit: observation.temperatureFahrenheit
            )
        }
    }
}
