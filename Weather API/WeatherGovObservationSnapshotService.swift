import Foundation

nonisolated enum
WeatherGovObservationFetchOutcome:
    Sendable {

    case observation(
        AtlasObservation
    )

    case noCurrentObservation

    case observationWithoutTemperature

    case observationOutsideAcceptedTimeRange

    case transientFailure
}

nonisolated struct
WeatherGovStationObservationFetchResult:
    Sendable {

    let station: AtlasStation

    let outcome:
        WeatherGovObservationFetchOutcome
}

nonisolated struct
WeatherGovObservationFetchBatch:
    Sendable {

    let results:
        [WeatherGovStationObservationFetchResult]

    let downloadedAt: Date
    let rawReportCount: Int

    var snapshot:
        AtlasObservationSnapshot {

        let observations =
            results.compactMap {
                result -> AtlasObservation? in

                guard case
                    .observation(
                        let observation
                    ) = result.outcome else {

                    return nil
                }

                return observation
            }
            .sorted {
                $0.station.source.stationID
                    < $1.station.source.stationID
            }

        return AtlasObservationSnapshot(
            observations: observations,
            downloadedAt: downloadedAt,
            rawReportCount: rawReportCount
        )
    }
}

/// Requests supplemental Weather.gov observations with
/// a bounded concurrency limit. Every station receives a
/// typed result so a normal 404 is not confused with a
/// provider or transport failure.
nonisolated struct
WeatherGovObservationSnapshotService:
    Sendable {

    static let defaultMaximumObservationAge:
        TimeInterval = 60 * 60

    static let defaultConcurrentRequestLimit =
        6

    func fetchSnapshot(
        for stations: [AtlasStation],
        now: Date = Date(),
        maximumObservationAge:
            TimeInterval =
                Self.defaultMaximumObservationAge,
        concurrentRequestLimit: Int =
            Self.defaultConcurrentRequestLimit
    ) async -> AtlasObservationSnapshot {

        let batch =
            await fetchBatch(
                for: stations,
                now: now,
                maximumObservationAge:
                    maximumObservationAge,
                concurrentRequestLimit:
                    concurrentRequestLimit
            )

        return batch.snapshot
    }

    func fetchBatch(
        for stations: [AtlasStation],
        now: Date = Date(),
        maximumObservationAge:
            TimeInterval =
                Self.defaultMaximumObservationAge,
        concurrentRequestLimit: Int =
            Self.defaultConcurrentRequestLimit
    ) async -> WeatherGovObservationFetchBatch {

        var uniqueStationsByID:
            [String: AtlasStation] = [:]

        for station in stations {
            guard station.source.providerID
                    == WeatherGovAPI.providerID else {
                continue
            }

            uniqueStationsByID[
                station.id
            ] = station
        }

        let candidates =
            uniqueStationsByID
                .values
                .sorted {
                    $0.source.stationID
                        < $1.source.stationID
                }

        guard candidates.isEmpty
                == false else {

            return WeatherGovObservationFetchBatch(
                results: [],
                downloadedAt: now,
                rawReportCount: 0
            )
        }

        let requestLimit =
            min(
                max(
                    concurrentRequestLimit,
                    1
                ),
                12
            )

        let usableMaximumAge =
            max(
                maximumObservationAge,
                60
            )

        let oldestAcceptedDate =
            now.addingTimeInterval(
                -usableMaximumAge
            )

        let newestAcceptedDate =
            now.addingTimeInterval(
                10 * 60
            )

        let latestService =
            WeatherGovLatestObservationService()

        let results =
            await withTaskGroup(
                of:
                    WeatherGovStationObservationFetchResult
                        .self
            ) { group in

                var stationIterator =
                    candidates.makeIterator()

                for _ in 0..<min(
                    requestLimit,
                    candidates.count
                ) {
                    guard let station =
                            stationIterator
                                .next() else {
                        break
                    }

                    addTask(
                        for: station,
                        to: &group,
                        latestService:
                            latestService,
                        oldestAcceptedDate:
                            oldestAcceptedDate,
                        newestAcceptedDate:
                            newestAcceptedDate
                    )
                }

                var collectedResults:
                    [
                        WeatherGovStationObservationFetchResult
                    ] = []

                while let result =
                        await group.next() {

                    collectedResults.append(
                        result
                    )

                    if let nextStation =
                            stationIterator.next() {

                        addTask(
                            for: nextStation,
                            to: &group,
                            latestService:
                                latestService,
                            oldestAcceptedDate:
                                oldestAcceptedDate,
                            newestAcceptedDate:
                                newestAcceptedDate
                        )
                    }
                }

                return collectedResults
                    .sorted {
                        $0.station.source.stationID
                            < $1.station.source.stationID
                    }
            }

        return WeatherGovObservationFetchBatch(
            results: results,
            downloadedAt: Date(),
            rawReportCount:
                candidates.count
        )
    }

    private func addTask(
        for station: AtlasStation,
        to group:
            inout TaskGroup<
                WeatherGovStationObservationFetchResult
            >,
        latestService:
            WeatherGovLatestObservationService,
        oldestAcceptedDate: Date,
        newestAcceptedDate: Date
    ) {
        group.addTask {
            do {
                let latestResult =
                    try await latestService
                        .fetchLatestObservationResult(
                            for: station
                        )

                switch latestResult {
                case .observation(
                    let observation
                ):
                    guard observation.observedAt
                            >= oldestAcceptedDate,
                          observation.observedAt
                            <= newestAcceptedDate else {

                        return WeatherGovStationObservationFetchResult(
                            station: station,
                            outcome:
                                .observationOutsideAcceptedTimeRange
                        )
                    }

                    return WeatherGovStationObservationFetchResult(
                        station: station,
                        outcome:
                            .observation(
                                observation
                            )
                    )

                case .noCurrentObservation:
                    return WeatherGovStationObservationFetchResult(
                        station: station,
                        outcome:
                            .noCurrentObservation
                    )

                case .observationWithoutTemperature:
                    return WeatherGovStationObservationFetchResult(
                        station: station,
                        outcome:
                            .observationWithoutTemperature
                    )
                }
            } catch {
                return WeatherGovStationObservationFetchResult(
                    station: station,
                    outcome:
                        .transientFailure
                )
            }
        }
    }
}
