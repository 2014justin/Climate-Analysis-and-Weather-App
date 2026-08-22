import Foundation

nonisolated enum WeatherGovAPIActivityLevel:
    String,
    Sendable,
    Equatable {

    case normal
    case elevated
    case high
}

nonisolated enum WeatherGovAPIEndpointKind:
    String,
    CaseIterable,
    Sendable,
    Hashable {

    case stateLookup
    case stationCatalog
    case latestObservation
    case temperatureHistory
    case other

    init(url: URL?) {
        let path =
            url?.path.lowercased() ?? ""

        if path.hasPrefix("/points/") {
            self = .stateLookup
        } else if path.hasSuffix(
            "/observations/latest"
        ) {
            self = .latestObservation
        } else if path.hasSuffix(
            "/observations"
        ) {
            self = .temperatureHistory
        } else {
            self = .other
        }
    }
}

nonisolated enum WeatherGovAPIRequestOutcome:
    String,
    CaseIterable,
    Sendable,
    Hashable {

    case successful
    case noCurrentObservation
    case providerRejected
    case providerError
    case clientError
    case transportFailure

    init(
        response: URLResponse,
        endpoint: WeatherGovAPIEndpointKind
    ) {
        guard let response =
                response as? HTTPURLResponse else {

            self = .transportFailure
            return
        }

        let statusCode =
            response.statusCode

        if (200..<400).contains(statusCode) {
            self = .successful
        } else if statusCode == 404,
                  endpoint == .latestObservation {

            // A weather station can legitimately have no
            // latest observation. This is not an API failure.
            self = .noCurrentObservation
        } else if statusCode == 403
                    || statusCode == 429 {

            self = .providerRejected
        } else if (500..<600).contains(
            statusCode
        ) {
            self = .providerError
        } else if (400..<500).contains(
            statusCode
        ) {
            self = .clientError
        } else {
            self = .providerError
        }
    }

    var countsAsFailure: Bool {
        switch self {
        case .successful,
             .noCurrentObservation:
            return false

        case .providerRejected,
             .providerError,
             .clientError,
             .transportFailure:
            return true
        }
    }
}

nonisolated struct WeatherGovAPIActivitySnapshot:
    Sendable,
    Equatable {

    static let advisoryRequestsPerMinute =
        160

    let requestsLastMinute: Int
    let inFlightRequestCount: Int
    let successfulRequestsLastMinute: Int
    let failedRequestsLastMinute: Int
    let observationCacheHitsLastMinute: Int

    let requestsLastFiveMinutes: Int
    let peakRequestsPerMinuteLastFiveMinutes:
        Int
    let observationCacheHitsLastFiveMinutes:
        Int

    let requestsLastFiveMinutesByEndpoint:
        [WeatherGovAPIEndpointKind: Int]

    let outcomesLastFiveMinutes:
        [WeatherGovAPIRequestOutcome: Int]

    init(
        requestsLastMinute: Int,
        inFlightRequestCount: Int,
        successfulRequestsLastMinute: Int,
        failedRequestsLastMinute: Int,
        observationCacheHitsLastMinute: Int,
        requestsLastFiveMinutes: Int = 0,
        peakRequestsPerMinuteLastFiveMinutes:
            Int = 0,
        observationCacheHitsLastFiveMinutes:
            Int = 0,
        requestsLastFiveMinutesByEndpoint:
            [WeatherGovAPIEndpointKind: Int] = [:],
        outcomesLastFiveMinutes:
            [WeatherGovAPIRequestOutcome: Int] = [:]
    ) {
        self.requestsLastMinute =
            requestsLastMinute

        self.inFlightRequestCount =
            inFlightRequestCount

        self.successfulRequestsLastMinute =
            successfulRequestsLastMinute

        self.failedRequestsLastMinute =
            failedRequestsLastMinute

        self.observationCacheHitsLastMinute =
            observationCacheHitsLastMinute

        self.requestsLastFiveMinutes =
            requestsLastFiveMinutes

        self.peakRequestsPerMinuteLastFiveMinutes =
            peakRequestsPerMinuteLastFiveMinutes

        self.observationCacheHitsLastFiveMinutes =
            observationCacheHitsLastFiveMinutes

        self.requestsLastFiveMinutesByEndpoint =
            requestsLastFiveMinutesByEndpoint

        self.outcomesLastFiveMinutes =
            outcomesLastFiveMinutes
    }

    var level:
        WeatherGovAPIActivityLevel {

        switch requestsLastMinute {
        case ..<96:
            return .normal

        case ..<Self.advisoryRequestsPerMinute:
            return .elevated

        default:
            return .high
        }
    }

    func requestCountLastFiveMinutes(
        for endpoint:
            WeatherGovAPIEndpointKind
    ) -> Int {
        requestsLastFiveMinutesByEndpoint[
            endpoint,
            default: 0
        ]
    }

    func outcomeCountLastFiveMinutes(
        for outcome:
            WeatherGovAPIRequestOutcome
    ) -> Int {
        outcomesLastFiveMinutes[
            outcome,
            default: 0
        ]
    }
}

actor WeatherGovAPIActivityMeter {
    static let shared =
        WeatherGovAPIActivityMeter()

    private static let oneMinute:
        TimeInterval = 60

    private static let fiveMinutes:
        TimeInterval = 5 * 60

    private var requestEvents:
        [RequestEvent] = []

    private var observationCacheHitEvents:
        [CacheHitEvent] = []

    @discardableResult
    func requestStarted(
        endpoint:
            WeatherGovAPIEndpointKind = .other,
        at date: Date = Date()
    ) -> UUID {
        pruneEvents(at: date)

        let requestID =
            UUID()

        requestEvents.append(
            RequestEvent(
                id: requestID,
                endpoint: endpoint,
                startedAt: date,
                finishedAt: nil,
                outcome: nil
            )
        )

        return requestID
    }

    func requestFinished(
        requestID: UUID,
        outcome:
            WeatherGovAPIRequestOutcome,
        at date: Date = Date()
    ) {
        pruneEvents(at: date)

        guard let index =
                requestEvents.firstIndex(
                    where: {
                        $0.id == requestID
                    }
                ) else {
            return
        }

        guard requestEvents[index].outcome
                == nil else {
            return
        }

        requestEvents[index].finishedAt =
            date

        requestEvents[index].outcome =
            outcome
    }

    // Keeps the old test call available until
    // we replace the meter tests.
    func requestFinished(
        succeeded: Bool,
        at date: Date = Date()
    ) {
        pruneEvents(at: date)

        guard let requestID =
                requestEvents.first(
                    where: {
                        $0.outcome == nil
                    }
                )?.id else {
            return
        }

        requestFinished(
            requestID: requestID,
            outcome:
                succeeded
                ? .successful
                : .clientError,
            at: date
        )
    }

    func recordObservationCacheHits(
        _ count: Int,
        at date: Date = Date()
    ) {
        guard count > 0 else {
            return
        }

        pruneEvents(at: date)

        observationCacheHitEvents.append(
            CacheHitEvent(
                date: date,
                count: count
            )
        )
    }

    func snapshot(
        at date: Date = Date()
    ) -> WeatherGovAPIActivitySnapshot {
        pruneEvents(at: date)

        let oneMinuteCutoff =
            date.addingTimeInterval(
                -Self.oneMinute
            )

        let fiveMinuteCutoff =
            date.addingTimeInterval(
                -Self.fiveMinutes
            )

        let requestsLastMinute =
            requestEvents.filter {
                $0.startedAt >= oneMinuteCutoff
                    && $0.startedAt <= date
            }

        let requestsLastFiveMinutes =
            requestEvents.filter {
                $0.startedAt >= fiveMinuteCutoff
                    && $0.startedAt <= date
            }

        let completedLastMinute =
            requestEvents.filter {
                guard let finishedAt =
                        $0.finishedAt else {
                    return false
                }

                return finishedAt
                        >= oneMinuteCutoff
                    && finishedAt <= date
            }

        let completedLastFiveMinutes =
            requestEvents.filter {
                guard let finishedAt =
                        $0.finishedAt else {
                    return false
                }

                return finishedAt
                        >= fiveMinuteCutoff
                    && finishedAt <= date
            }

        let cacheHitsLastMinute =
            observationCacheHitEvents
                .filter {
                    $0.date >= oneMinuteCutoff
                        && $0.date <= date
                }
                .reduce(0) {
                    $0 + $1.count
                }

        let cacheHitsLastFiveMinutes =
            observationCacheHitEvents
                .filter {
                    $0.date >= fiveMinuteCutoff
                        && $0.date <= date
                }
                .reduce(0) {
                    $0 + $1.count
                }

        var endpointCounts:
            [WeatherGovAPIEndpointKind: Int] =
                [:]

        for event in requestsLastFiveMinutes {
            endpointCounts[
                event.endpoint,
                default: 0
            ] += 1
        }

        var outcomeCounts:
            [WeatherGovAPIRequestOutcome: Int] =
                [:]

        for event in completedLastFiveMinutes {
            guard let outcome =
                    event.outcome else {
                continue
            }

            outcomeCounts[
                outcome,
                default: 0
            ] += 1
        }

        let successfulLastMinute =
            completedLastMinute.filter {
                $0.outcome == .successful
            }.count

        let failedLastMinute =
            completedLastMinute.filter {
                $0.outcome?.countsAsFailure
                    == true
            }.count

        return WeatherGovAPIActivitySnapshot(
            requestsLastMinute:
                requestsLastMinute.count,
            inFlightRequestCount:
                requestEvents.filter {
                    $0.outcome == nil
                }.count,
            successfulRequestsLastMinute:
                successfulLastMinute,
            failedRequestsLastMinute:
                failedLastMinute,
            observationCacheHitsLastMinute:
                cacheHitsLastMinute,
            requestsLastFiveMinutes:
                requestsLastFiveMinutes.count,
            peakRequestsPerMinuteLastFiveMinutes:
                peakOneMinuteRequestCount(
                    in: requestsLastFiveMinutes
                ),
            observationCacheHitsLastFiveMinutes:
                cacheHitsLastFiveMinutes,
            requestsLastFiveMinutesByEndpoint:
                endpointCounts,
            outcomesLastFiveMinutes:
                outcomeCounts
        )
    }

    private func peakOneMinuteRequestCount(
        in events: [RequestEvent]
    ) -> Int {
        let dates =
            events
                .map(\.startedAt)
                .sorted()

        guard !dates.isEmpty else {
            return 0
        }

        var leftIndex = 0
        var peakCount = 0

        for rightIndex in dates.indices {
            while dates[rightIndex]
                    .timeIntervalSince(
                        dates[leftIndex]
                    )
                    > Self.oneMinute {

                leftIndex += 1
            }

            peakCount =
                max(
                    peakCount,
                    rightIndex - leftIndex + 1
                )
        }

        return peakCount
    }

    private func pruneEvents(
        at date: Date
    ) {
        let cutoff =
            date.addingTimeInterval(
                -Self.fiveMinutes
            )

        requestEvents.removeAll {
            $0.startedAt < cutoff
                && $0.outcome != nil
        }

        observationCacheHitEvents.removeAll {
            $0.date < cutoff
        }
    }

    private struct RequestEvent {
        let id: UUID

        let endpoint:
            WeatherGovAPIEndpointKind

        let startedAt: Date
        var finishedAt: Date?

        var outcome:
            WeatherGovAPIRequestOutcome?
    }

    private struct CacheHitEvent {
        let date: Date
        let count: Int
    }
}
