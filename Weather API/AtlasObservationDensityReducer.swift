import Foundation

/// 35 deg+ longitude span = up to three stations per state
/// 12 - 35 deg long span = maximum one preferred station in each of 180 cells
/// 5 to 12 deg = finer 336-cell layout
/// Under 5 deg = every visible station.
struct AtlasObservationDensityReducer:
    Sendable {

    func observations(
        from snapshot: AtlasObservationSnapshot,
        in bounds: AtlasMapBounds,
        allowedCountryCodes:
            Set<String> = ["US"]
    ) -> [AtlasObservation] {
        let visibleObservations =
            snapshot.observations.filter {
                observation in

                allowedCountryCodes.contains(
                    observation.station
                        .source.countryCode
                )
                && bounds.contains(
                    latitude:
                        observation.station.latitude,
                    longitude:
                        observation.station.longitude
                )
            }

        switch bounds.longitudeSpan {
        case 35...:
            return nationalSelection(
                from: visibleObservations,
                stationsPerArea: 3
            )

        case 12..<35:
            return gridSelection(
                from: visibleObservations,
                in: bounds,
                columns: 18,
                rows: 10
            )

        case 5..<12:
            return gridSelection(
                from: visibleObservations,
                in: bounds,
                columns: 24,
                rows: 14
            )

        default:
            return sortedByPreference(
                visibleObservations
            )
        }
    }

    private func nationalSelection(
        from observations:
            [AtlasObservation],
        stationsPerArea: Int
    ) -> [AtlasObservation] {
        let observationsByArea = Dictionary(
            grouping: observations
        ) { observation in
            let station = observation.station

            let areaCode =
                station.administrativeAreaCode
                ?? "UNASSIGNED"

            return """
                \(station.source.countryCode)/\(areaCode)
                """
        }

        return observationsByArea.keys
            .sorted()
            .flatMap { areaKey in
                sortedByPreference(
                    observationsByArea[
                        areaKey
                    ] ?? []
                )
                .prefix(stationsPerArea)
            }
    }

    private func gridSelection(
        from observations:
            [AtlasObservation],
        in bounds: AtlasMapBounds,
        columns: Int,
        rows: Int
    ) -> [AtlasObservation] {
        guard bounds.latitudeSpan > 0,
              bounds.longitudeSpan > 0 else {
            return []
        }

        var selectedByCell:
            [GridCell: AtlasObservation] = [:]

        for observation in
            sortedByPreference(observations) {

            let longitudeOffset =
                eastwardDegrees(
                    from: bounds.west,
                    to:
                        observation.station
                            .longitude
                )

            let horizontalFraction =
                longitudeOffset
                / bounds.longitudeSpan

            let verticalFraction =
                (
                    bounds.north
                    - observation.station.latitude
                )
                / bounds.latitudeSpan

            let column = min(
                max(
                    Int(
                        horizontalFraction
                        * Double(columns)
                    ),
                    0
                ),
                columns - 1
            )

            let row = min(
                max(
                    Int(
                        verticalFraction
                        * Double(rows)
                    ),
                    0
                ),
                rows - 1
            )

            let cell = GridCell(
                column: column,
                row: row
            )

            if selectedByCell[cell] == nil {
                selectedByCell[cell] =
                    observation
            }
        }

        return selectedByCell.values.sorted {
            $0.station.source.stationID
                < $1.station.source.stationID
        }
    }

    private func sortedByPreference(
        _ observations:
            [AtlasObservation]
    ) -> [AtlasObservation] {
        observations.sorted { first, second in
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

            if first.observedAt
                != second.observedAt {
                return first.observedAt
                    > second.observedAt
            }

            return first.station.source.stationID
                < second.station.source.stationID
        }
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
        var result = longitude
            .truncatingRemainder(
                dividingBy: 360
            )

        if result > 180 {
            result -= 360
        } else if result < -180 {
            result += 360
        }

        return result
    }

    private struct GridCell: Hashable {
        let column: Int
        let row: Int
    }
}
