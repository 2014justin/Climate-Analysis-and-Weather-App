/// Preserves namespaced provider identities generally while applying one narrow deduplication rule across
/// the two layers, an exact country-and-station-ID match belongs to the METAR base layer.

import Foundation
nonisolated enum AtlasObservationSnapshotMerger {
    
    static func merged(
        primary: AtlasObservationSnapshot,
        supplemental: AtlasObservationSnapshot,
    ) -> AtlasObservationSnapshot {
        let primaryStationKeys = Set(
            primary.observations.map {
                physicalStationKey(for: $0.station)
            }
        )
        
        let uniqueSupplementalObservations = supplemental.observations.filter {
            primaryStationKeys.contains(
                physicalStationKey(for: $0.station)
            ) == false
        }
        
        let mergedObservations =
        (primary.observations + uniqueSupplementalObservations).sorted {
            $0.id < $1.id
        }
        
        return AtlasObservationSnapshot(
            observations: mergedObservations,
            downloadedAt: min(primary.downloadedAt, supplemental.downloadedAt),
            rawReportCount: primary.rawReportCount + supplemental.rawReportCount
        )
    }
    
    fileprivate static func physicalStationKey(
        for station: AtlasStation
    ) -> String {
        let countryCode  = station.source.countryCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        
        let stationID = station.source.stationID
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        
        return "\(countryCode)/\(stationID)"
    }
}
