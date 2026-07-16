import Foundation

/// One station's latest live observation, converted into the units
/// used by the app. Provider-specific response models remain separate

struct AtlasObservation: Identifiable, Codable, Hashable, Sendable {
    let station: AtlasStation
    let observedAt: Date
    let temperatureFahrenheit: Double
    let dewPointFahrenheit: Double?
    let windSpeedMilesPerHour: Double?
    let conditionDescription: String?

    var id: String {
        station.id
    }
}

/// The result of one Atlas observation request.
/// Lets the UI distinguish between Raw METAR reports downloaded, unique usable stations produced,
/// and a potentially incomplete response requiring the user to zoom in.
struct AtlasObservationBatch: Codable, Hashable, Sendable {
    let observations: [AtlasObservation]
    let rawRecordCount: Int
    
    /// Aviation Weather custom queries must stop at 400 raw records.
    let mayBeTruncated: Bool
}
