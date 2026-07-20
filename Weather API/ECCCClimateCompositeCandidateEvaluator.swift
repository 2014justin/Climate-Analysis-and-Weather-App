/// Measures completeness and converts the result into the same candidate-
/// card model used by the US systems


import Foundation

struct ECCCClimateCompositeCandidateEvaluator {

    private let dailyService:
        ECCCClimateCompositeDailyService

    nonisolated init(
        dailyService:
            ECCCClimateCompositeDailyService =
                ECCCClimateCompositeDailyService()
    ) {
        self.dailyService = dailyService
    }

    func evaluate(
        matches: [ECCCClimateCompositeMatch],
        sourceElevationMeters: Double?,
        startDate: ClimateDate,
        endDate: ClimateDate,
        maximumCandidateCount: Int = 8,
        progress:
            (@MainActor (String) -> Void)? = nil
    ) async -> [GeneratedClimateStationCandidate] {

        let matchesToEvaluate = Array(
            matches.prefix(
                max(0, maximumCandidateCount)
            )
        )

        var candidates:
            [GeneratedClimateStationCandidate] = []

        for (
            index,
            match
        ) in matchesToEvaluate.enumerated() {

            progress?(
                "Evaluating official Canadian composite "
                + "\(index + 1) of "
                + "\(matchesToEvaluate.count)..."
            )

            do {
                let observations =
                    try await dailyService
                        .fetchObservations(
                            for: match.composite,
                            startDate: startDate,
                            endDate: endDate
                        )

                guard let pairedCompleteness =
                        ClimateObservationCompletenessCalculator
                            .pairedCompleteness(
                                observations: observations,
                                startDate: startDate,
                                endDate: endDate
                            ) else {
                    continue
                }

                let elevationDifferenceFeet:
                    Double?

                if let sourceElevationMeters,
                   let compositeElevationMeters =
                        match.composite.elevationMeters {

                    elevationDifferenceFeet =
                        abs(
                            sourceElevationMeters
                            - compositeElevationMeters
                        )
                        * 3.280839895
                } else {
                    elevationDifferenceFeet = nil
                }

                candidates.append(
                    GeneratedClimateStationCandidate(
                        stationID:
                            match.composite
                                .canonicalClimateIdentifier,
                        displayName:
                            match.composite.displayName,
                        administrativeAreaCode:
                            match.composite.provinceCode,
                        distanceMiles:
                            match.distanceMiles,
                        elevationDifferenceFeet:
                            elevationDifferenceFeet,
                        pairedCompleteness:
                            pairedCompleteness
                    )
                )
            } catch {
                continue
            }
        }

        candidates.sort {
            firstCandidate,
            secondCandidate in

            let firstTier =
                firstCandidate
                    .qualityRating
                    .recommendationTier

            let secondTier =
                secondCandidate
                    .qualityRating
                    .recommendationTier

            if firstTier != secondTier {
                return firstTier < secondTier
            }

            if firstCandidate.distanceMiles
                != secondCandidate.distanceMiles {
                return firstCandidate.distanceMiles
                    < secondCandidate.distanceMiles
            }

            if firstCandidate.pairedCompleteness
                != secondCandidate.pairedCompleteness {
                return firstCandidate.pairedCompleteness
                    > secondCandidate.pairedCompleteness
            }

            return firstCandidate.stationID
                < secondCandidate.stationID
        }

        return candidates
    }
}
