import Foundation

/// Selects a readable, spatially distributed subset of
/// observations without needing to know whether the map
/// covers an urban or rural area.
///
/// Sparse regions naturally retain nearly every station.
/// Dense regions are limited by screen-relative spacing.
nonisolated struct
AtlasObservationDensityReducer:
    Sendable {

    func observations(
        from snapshot: AtlasObservationSnapshot,
        in bounds: AtlasMapBounds,
        scope: AtlasStationScope,
        displayedMetric: AtlasMapMetric,
        annotationSize: AtlasAnnotationSize,
        showsMaximumDensity:
            Bool = false,
        allowedCountryCodes:
            Set<String>? = Set(["US"])
    ) -> [AtlasObservation] {

        let visibleObservations =
            snapshot.observations.filter {
                observation in

                let countryIsAllowed =
                    allowedCountryCodes?
                        .contains(
                            observation
                                .station
                                .source
                                .countryCode
                        )
                    ?? true

                return countryIsAllowed
                    && bounds.contains(
                        latitude:
                            observation.station.latitude,
                        longitude:
                            observation.station.longitude
                    )
            }

        guard visibleObservations.isEmpty == false else {
            return []
        }
        
        if showsMaximumDensity {
            return sortedByPreference(
                visibleObservations,
                scope: scope,
                displayedMetric:
                    displayedMetric
            )
            .sorted {
                $0.station.id
                    < $1.station.id
            }
        }

        let layout =
            densityLayout(
                for: annotationSize,
                scope: scope,
                bounds: bounds
            )

        let automaticSelection =
            spatiallySeparatedSelection(
                from: visibleObservations,
                in: bounds,
                scope: scope,
                displayedMetric: displayedMetric,
                columns: layout.columns,
                rows: layout.rows
            )

        guard scope == .allNetworks else {
            return automaticSelection
        }

        // METAR observations are already available from the
        // bulk Aviation Weather snapshot. Give them roughly
        // twice the local visual capacity without changing
        // the supplemental-network density.
        let primaryObservations =
            visibleObservations.filter {
                $0.station.tier == .primary
            }

        guard primaryObservations.isEmpty == false else {
            return automaticSelection
        }

        let squareRootOfTwo =
            2.0.squareRoot()

        let denserPrimaryColumns =
            Int(
                ceil(
                    Double(layout.columns)
                    * squareRootOfTwo
                )
            )

        let denserPrimaryRows =
            Int(
                ceil(
                    Double(layout.rows)
                    * squareRootOfTwo
                )
            )

        let additionalPrimarySelection =
            spatiallySeparatedSelection(
                from: primaryObservations,
                in: bounds,
                scope: .primary,
                displayedMetric: displayedMetric,
                columns: denserPrimaryColumns,
                rows: denserPrimaryRows
            )

        var observationsByID:
            [String: AtlasObservation] = [:]

        for observation in
            automaticSelection
            + additionalPrimarySelection {

            observationsByID[
                observation.id
            ] = observation
        }

        return observationsByID
            .values
            .sorted {
                $0.station.id
                    < $1.station.id
            }
    }

    private func densityLayout(
        for annotationSize:
            AtlasAnnotationSize,
        scope: AtlasStationScope,
        bounds: AtlasMapBounds
    ) -> (
        columns: Int,
        rows: Int
    ) {
        switch scope {
        case .allNetworks:
            // Keep the calmer automatic layout already
            // established through visual testing.
            switch annotationSize {
            case .medium:
                return (
                    columns: 15,
                    rows: 10
                )

            case .mediumPlus:
                return (
                    columns: 13,
                    rows: 9
                )

            case .large:
                return (
                    columns: 11,
                    rows: 8
                )
            }

        case .primary:
            // METAR is naturally much sparser. Allow
            // progressively closer stations as the user
            // moves from continental to regional views.
            let largestSpan =
                max(
                    bounds.latitudeSpan,
                    bounds.longitudeSpan
                )

            if largestSpan <= 8 {
                switch annotationSize {
                case .medium:
                    return (
                        columns: 40,
                        rows: 25
                    )

                case .mediumPlus:
                    return (
                        columns: 36,
                        rows: 22
                    )

                case .large:
                    return (
                        columns: 31,
                        rows: 19
                    )
                }
            }

            if largestSpan <= 20 {
                switch annotationSize {
                case .medium:
                    return (
                        columns: 24,
                        rows: 16
                    )

                case .mediumPlus:
                    return (
                        columns: 21,
                        rows: 14
                    )

                case .large:
                    return (
                        columns: 18,
                        rows: 12
                    )
                }
            }

            switch annotationSize {
            case .medium:
                return (
                    columns: 17,
                    rows: 11
                )

            case .mediumPlus:
                return (
                    columns: 15,
                    rows: 10
                )

            case .large:
                return (
                    columns: 13,
                    rows: 9
                )
            }
        }
    }

    private func spatiallySeparatedSelection(
        from observations: [AtlasObservation],
        in bounds: AtlasMapBounds,
        scope: AtlasStationScope,
        displayedMetric: AtlasMapMetric,
        columns: Int,
        rows: Int
    ) -> [AtlasObservation] {

        guard bounds.latitudeSpan > 0,
              bounds.longitudeSpan > 0,
              columns > 0,
              rows > 0 else {
            return []
        }

        let minimumHorizontalSeparation =
            1.0 / Double(columns)

        let minimumVerticalSeparation =
            1.0 / Double(rows)

        let maximumCount =
            columns * rows

        var selected:
            [PositionedObservation] = []

        let rankedObservations =
            sortedByPreference(
                observations,
                scope: scope,
                displayedMetric:
                    displayedMetric
            )

        for observation in rankedObservations {
            let horizontalPosition =
                eastwardDegrees(
                    from: bounds.west,
                    to:
                        observation
                            .station
                            .longitude
                )
                / bounds.longitudeSpan

            let verticalPosition =
                (
                    bounds.north
                    - observation.station.latitude
                )
                / bounds.latitudeSpan

            let overlapsExistingObservation =
                selected.contains {
                    selectedObservation in

                    abs(
                        selectedObservation
                            .horizontalPosition
                        - horizontalPosition
                    )
                    < minimumHorizontalSeparation

                    && abs(
                        selectedObservation
                            .verticalPosition
                        - verticalPosition
                    )
                    < minimumVerticalSeparation
                }

            guard overlapsExistingObservation == false else {
                continue
            }

            selected.append(
                PositionedObservation(
                    observation: observation,
                    horizontalPosition:
                        horizontalPosition,
                    verticalPosition:
                        verticalPosition
                )
            )

            if selected.count >= maximumCount {
                break
            }
        }

        return selected
            .map {
                $0.observation
            }
            .sorted {
                $0.station.id
                    < $1.station.id
            }
    }

    private func sortedByPreference(
        _ observations: [AtlasObservation],
        scope: AtlasStationScope,
        displayedMetric: AtlasMapMetric
    ) -> [AtlasObservation] {

        observations.sorted {
            first,
            second in

            let firstHasDisplayedMetric =
                hasDisplayedMetric(
                    first,
                    displayedMetric:
                        displayedMetric
                )

            let secondHasDisplayedMetric =
                hasDisplayedMetric(
                    second,
                    displayedMetric:
                        displayedMetric
                )

            if firstHasDisplayedMetric
                != secondHasDisplayedMetric {
                return firstHasDisplayedMetric
            }

            if scope == .primary {
                let firstPriority =
                    first.station.displayPriority
                    ?? Int.max

                let secondPriority =
                    second.station.displayPriority
                    ?? Int.max

                if firstPriority != secondPriority {
                    return firstPriority
                        < secondPriority
                }
            }

            let firstFreshnessBucket =
                freshnessBucket(
                    for: first.observedAt
                )

            let secondFreshnessBucket =
                freshnessBucket(
                    for: second.observedAt
                )

            if firstFreshnessBucket
                != secondFreshnessBucket {
                return firstFreshnessBucket
                    > secondFreshnessBucket
            }

            if scope == .allNetworks,
               first.station.tier
                != second.station.tier {
                return first.station.tier
                    == .primary
            }

            return first.station.id
                < second.station.id
        }
    }

    private func hasDisplayedMetric(
        _ observation: AtlasObservation,
        displayedMetric: AtlasMapMetric
    ) -> Bool {

        switch displayedMetric {
        case .temperature:
            return true

        case .dewPoint:
            return observation
                .dewPointFahrenheit != nil

        case .rolling24HourMaximum,
             .rolling24HourMinimum:
            // Rolling extrema live in a separate store,
            // so this reducer cannot inspect them yet.
            return true
        }
    }

    private func freshnessBucket(
        for date: Date
    ) -> Int {

        Int(
            date.timeIntervalSince1970
            / (10 * 60)
        )
    }

    private func eastwardDegrees(
        from westernLongitude: Double,
        to longitude: Double
    ) -> Double {

        let normalizedWest =
            normalized(westernLongitude)

        let normalizedLongitude =
            normalized(longitude)

        let difference =
            normalizedLongitude
            - normalizedWest

        return difference >= 0
            ? difference
            : difference + 360
    }

    private func normalized(
        _ longitude: Double
    ) -> Double {

        var result =
            longitude.truncatingRemainder(
                dividingBy: 360
            )

        if result > 180 {
            result -= 360
        } else if result < -180 {
            result += 360
        }

        return result
    }

    private struct
    PositionedObservation:
        Sendable {

        let observation:
            AtlasObservation

        let horizontalPosition:
            Double

        let verticalPosition:
            Double
    }
}
