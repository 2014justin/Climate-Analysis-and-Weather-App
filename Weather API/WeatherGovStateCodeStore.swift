/// State-code cache
import Foundation

nonisolated protocol
WeatherGovStateCodeResolving:
    Sendable {

    func stateCodes(
        in bounds: AtlasMapBounds
    ) async throws -> [String]
}

extension WeatherGovViewportStateResolver:
    WeatherGovStateCodeResolving {
}

nonisolated fileprivate struct
WeatherGovStateCodeCoverageEntry:
    Sendable {

    let bounds: AtlasMapBounds
    let stateCodes: [String]
    let resolvedAt: Date
}

/// Retains recently resolved geographic coverage in RAM.
///
/// A small pan contained by a cached coverage box therefore
/// requires no additional Weather.gov point requests.
actor WeatherGovStateCodeStore {
    static let refreshInterval:
        TimeInterval = 24 * 60 * 60

    static let maximumCoverageEntryCount =
        8

    private let resolver:
        any WeatherGovStateCodeResolving

    private var coverageEntries:
        [WeatherGovStateCodeCoverageEntry] = []

    init(
        resolver:
            any WeatherGovStateCodeResolving =
                WeatherGovViewportStateResolver()
    ) {
        self.resolver = resolver
    }

    func stateCodes(
        in bounds: AtlasMapBounds,
        now: Date = Date()
    ) async throws -> [String] {

        if let cachedEntry =
                freshCoverageEntry(
                    containing: bounds,
                    now: now
                ) {
            return cachedEntry.stateCodes
        }

        // Resolve a larger surrounding box so several
        // subsequent small pans remain inside the cache.
        let coverageBounds =
            bounds.padded(
                by: 0.50,
                maximumDegreesPerEdge:
                    1.0
            )

        do {
            let resolvedStateCodes =
                try await resolver.stateCodes(
                    in: coverageBounds
                )

            store(
                stateCodes:
                    resolvedStateCodes,
                covering:
                    coverageBounds,
                resolvedAt: now
            )

            return resolvedStateCodes
        } catch {
            // State boundaries are stable. If Weather.gov
            // temporarily fails, stale RAM coverage remains
            // safer than discarding the dense layer.
            if let staleEntry =
                    coverageEntries.last(
                        where: {
                            $0.bounds.contains(
                                bounds
                            )
                        }
                    ) {
                return staleEntry.stateCodes
            }

            throw error
        }
    }

    private func freshCoverageEntry(
        containing bounds: AtlasMapBounds,
        now: Date
    ) -> WeatherGovStateCodeCoverageEntry? {

        coverageEntries.last {
            entry in

            let age =
                now.timeIntervalSince(
                    entry.resolvedAt
                )

            return age >= 0
                && age
                    < Self.refreshInterval
                && entry.bounds.contains(
                    bounds
                )
        }
    }

    private func store(
        stateCodes: [String],
        covering bounds: AtlasMapBounds,
        resolvedAt: Date
    ) {
        let normalizedStateCodes =
            Array(
                Set(
                    stateCodes.map {
                        $0.trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        )
                        .uppercased()
                    }
                    .filter {
                        $0.range(
                            of:
                                #"^[A-Z]{2}$"#,
                            options:
                                .regularExpression
                        ) != nil
                    }
                )
            )
            .sorted()

        coverageEntries =
            coverageEntries.filter {
                entry in

                let age =
                    resolvedAt.timeIntervalSince(
                        entry.resolvedAt
                    )

                return age >= 0
                    && age
                        < Self.refreshInterval
                    && bounds.contains(
                        entry.bounds
                    ) == false
            }

        coverageEntries.append(
            WeatherGovStateCodeCoverageEntry(
                bounds: bounds,
                stateCodes:
                    normalizedStateCodes,
                resolvedAt: resolvedAt
            )
        )

        let excessCount =
            coverageEntries.count
            - Self.maximumCoverageEntryCount

        if excessCount > 0 {
            coverageEntries.removeFirst(
                excessCount
            )
        }
    }
}
