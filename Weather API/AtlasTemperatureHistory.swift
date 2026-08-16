/// One historical air-temperature observation.
///
/// This deliberately avoids storing a complete atlasstation for every historical report.
/// The station catalog already owns that metadata.
/// We should be able to feed it synthetic observations and prove that 'previous 24 hours'
/// means exactly what we think it means.

import Foundation

nonisolated struct AtlasTemperatureHistorySample: Codable, Hashable, Sendable {
    let stationID: String
    let observedAt: Date
    let temperatureFahrenheit: Double
}

/// The observed temperture extrema within one rolling time window.
nonisolated struct AtlasRollingTemperatureExtrema: Codable, Hashable, Sendable {
    let stationID: String
    
    let minimumTemperatureFahrenheit: Double
    let minimumObservedAt: Date
    
    let maximumTemperatureFahrenheit: Double
    let maximumObservedAt: Date
    
    let windowStart: Date
    let windowEnd: Date
    let sampleCount: Int
}

/// Pure calculation with no networking, caching, or UI dependency.
/// Establishes that the window is rolling in real time, not calendar-day based.
/// Interval includes observations exactly at both endpoints.
/// Other stations' observations are ignored
/// Invalid NaN or inf temperatures are ignored
/// Invalid NaN or infinite temperatures are ignored
/// No samples means nil, which will display as an em dash
/// Both extrema come from the identical 24-hour observation set.
/// The result retains occurrence times and sample count for later debugging
///
nonisolated enum AtlasTemperatureExtremaCalculator {
    static let defaultWindow: TimeInterval = 24.0 * 60.0 * 60.0
    
    
    
    static func rollingExtrema(
        for stationID: String,
        in samples: [AtlasTemperatureHistorySample],
        endingAt windowEnd: Date,
        window: TimeInterval = defaultWindow
    ) -> AtlasRollingTemperatureExtrema? {
        guard window > 0.0 else {
            return nil
        }
        
        let windowStart = windowEnd.addingTimeInterval(-window)
        
        var minimumSample: AtlasTemperatureHistorySample?
        
        var maximumSample: AtlasTemperatureHistorySample?
        
        var sampleCount = 0
        
        for sample in samples {
            guard sample.stationID == stationID,
                  sample.observedAt >= windowStart,
                  sample.observedAt <= windowEnd,
                  sample.temperatureFahrenheit.isFinite == true else {
                continue
            }
            
            sampleCount += 1
            
            if let currentMinimum = minimumSample {
                if sample.temperatureFahrenheit < currentMinimum.temperatureFahrenheit {
                    minimumSample = sample
                }
            } else {
                minimumSample = sample
            }
            
            if let currentMaximum = maximumSample {
                if sample.temperatureFahrenheit > currentMaximum.temperatureFahrenheit {
                    maximumSample = sample
                }
            } else {
                maximumSample = sample
            }
        }
        
        guard let minimumSample,
              let maximumSample else {
            return nil
        }
        
        return AtlasRollingTemperatureExtrema(
            stationID: stationID,
            minimumTemperatureFahrenheit: minimumSample.temperatureFahrenheit,
            minimumObservedAt: minimumSample.observedAt,
            maximumTemperatureFahrenheit: maximumSample.temperatureFahrenheit,
            maximumObservedAt: maximumSample.observedAt,
            windowStart: windowStart,
            windowEnd: windowEnd,
            sampleCount: sampleCount
        )
    }
}

/// In-memory rolling temperature history for Atlas stations.
///
/// The store accepts provider-neutral samples, so live METAR snapshots and a
/// future historical seed service can feed the same data path. Exact duplicate
/// station/timestamp pairs replace the earlier value rather than inflating the
/// sample count.
actor AtlasTemperatureHistoryStore {
    private let retentionWindow: TimeInterval

    private var samplesByStationID:
        [String: [Date: AtlasTemperatureHistorySample]] = [:]

    init(
        retentionWindow: TimeInterval =
            AtlasTemperatureExtremaCalculator.defaultWindow
    ) {
        precondition(retentionWindow > 0.0)
        self.retentionWindow = retentionWindow
    }

    /// Adds a batch and discards samples outside the retained rolling window.
    /// `referenceDate` should normally be the snapshot download time so one
    /// batch uses a single, deterministic cutoff.
    func ingest(
        _ newSamples: [AtlasTemperatureHistorySample],
        referenceDate: Date = .now
    ) {
        let cutoff = referenceDate.addingTimeInterval(-retentionWindow)

        prune(before: cutoff, after: referenceDate)

        for sample in newSamples {
            guard sample.stationID.isEmpty == false,
                  sample.temperatureFahrenheit.isFinite,
                  sample.observedAt >= cutoff,
                  sample.observedAt <= referenceDate else {
                continue
            }

            samplesByStationID[sample.stationID, default: [:]][sample.observedAt] =
                sample
        }
    }

    /// Calculates extrema from the samples currently retained for one station.
    func rollingExtrema(
        for stationID: String,
        endingAt windowEnd: Date = .now
    ) -> AtlasRollingTemperatureExtrema? {
        let samples = Array(
            samplesByStationID[stationID, default: [:]].values
        )

        return AtlasTemperatureExtremaCalculator.rollingExtrema(
            for: stationID,
            in: samples,
            endingAt: windowEnd,
            window: retentionWindow
        )
    }
    
    func rollingExtrema(
        for stationIDs: [String],
        endingAt windowEnd: Date = .now
    ) -> [String: AtlasRollingTemperatureExtrema] {
        var extremaByStationID: [String: AtlasRollingTemperatureExtrema] = [:]
        
        for stationID in Set(stationIDs) {
            guard let extrema = rollingExtrema(for: stationID, endingAt: windowEnd) else {
                continue
            }
            
            extremaByStationID[stationID] = extrema
        }
        
        return extremaByStationID
    }
    
    /// Sorted access is useful for tests, diagnostics, and a future details UI.
    func samples(
        for stationID: String
    ) -> [AtlasTemperatureHistorySample] {
        samplesByStationID[stationID, default: [:]]
            .values
            .sorted { $0.observedAt < $1.observedAt }
    }

    func removeAll() {
        samplesByStationID.removeAll(keepingCapacity: false)
    }

    private func prune(
        before cutoff: Date,
        after referenceDate: Date
    ) {
        for stationID in Array(samplesByStationID.keys) {
            let retained = samplesByStationID[stationID, default: [:]]
                .filter { observedAt, _ in
                    observedAt >= cutoff && observedAt <= referenceDate
                }

            if retained.isEmpty {
                samplesByStationID.removeValue(forKey: stationID)
            } else {
                samplesByStationID[stationID] = retained
            }
        }
    }
}
