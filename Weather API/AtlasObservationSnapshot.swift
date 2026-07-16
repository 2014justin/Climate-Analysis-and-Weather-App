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
