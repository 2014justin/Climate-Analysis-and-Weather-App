import Foundation

/// Limits Weather.gov observation requests before they
/// happen while preserving spatial coverage.
///
/// The planner selects at least one station from every
/// occupied screen-relative cell before selecting additional
/// stations from the densest cells.
nonisolated struct
WeatherGovStationRequestPlanner:
    Sendable {

    static let defaultMaximumStationCount =
        160

    private static let columnCount =
        13

    private static let rowCount =
        9

    func stations(
        from candidates: [AtlasStation],
        in bounds: AtlasMapBounds,
        maximumStationCount: Int =
            Self.defaultMaximumStationCount
    ) -> [AtlasStation] {

        let safeMaximum =
            max(maximumStationCount, 0)

        guard safeMaximum > 0,
              bounds.latitudeSpan > 0,
              bounds.longitudeSpan > 0 else {
            return []
        }

        var visibleStationsByID:
            [String: AtlasStation] = [:]

        for station in candidates {
            guard bounds.contains(
                latitude: station.latitude,
                longitude: station.longitude
            ) else {
                continue
            }

            visibleStationsByID[station.id] =
                station
        }

        let visibleStations =
            visibleStationsByID
                .values
                .sorted {
                    $0.id < $1.id
                }

        guard visibleStations.count
                > safeMaximum else {
            return visibleStations
        }

        var stationsByCell:
            [GridCell: [AtlasStation]] = [:]

        for station in visibleStations {
            let cell =
                gridCell(
                    for: station,
                    in: bounds
                )

            stationsByCell[
                cell,
                default: []
            ]
            .append(station)
        }

        for cell in stationsByCell.keys {
            stationsByCell[cell]?.sort {
                $0.id < $1.id
            }
        }

        let orderedCells =
            stationsByCell.keys.sorted {
                first,
                second in

                if first.row != second.row {
                    return first.row
                        < second.row
                }

                return first.column
                    < second.column
            }

        var nextIndexByCell:
            [GridCell: Int] = [:]

        var selectedStations:
            [AtlasStation] = []

        while selectedStations.count
                < safeMaximum {

            let cellsWithRemainingStations =
                orderedCells
                    .filter {
                        cell in

                        let nextIndex =
                            nextIndexByCell[cell]
                            ?? 0

                        return nextIndex
                            < (
                                stationsByCell[cell]?
                                    .count
                                ?? 0
                            )
                    }
                    .sorted {
                        first,
                        second in

                        let firstRemaining =
                            remainingStationCount(
                                in: first,
                                stationsByCell:
                                    stationsByCell,
                                nextIndexByCell:
                                    nextIndexByCell
                            )

                        let secondRemaining =
                            remainingStationCount(
                                in: second,
                                stationsByCell:
                                    stationsByCell,
                                nextIndexByCell:
                                    nextIndexByCell
                            )

                        if firstRemaining
                            != secondRemaining {
                            return firstRemaining
                                > secondRemaining
                        }

                        if first.row
                            != second.row {
                            return first.row
                                < second.row
                        }

                        return first.column
                            < second.column
                    }

            guard cellsWithRemainingStations
                    .isEmpty == false else {
                break
            }

            for cell in
                cellsWithRemainingStations {

                let nextIndex =
                    nextIndexByCell[cell]
                    ?? 0

                guard let stations =
                        stationsByCell[cell],
                      nextIndex
                        < stations.count else {
                    continue
                }

                selectedStations.append(
                    stations[nextIndex]
                )

                nextIndexByCell[cell] =
                    nextIndex + 1

                if selectedStations.count
                    >= safeMaximum {
                    break
                }
            }
        }

        return selectedStations.sorted {
            $0.id < $1.id
        }
    }

    private func gridCell(
        for station: AtlasStation,
        in bounds: AtlasMapBounds
    ) -> GridCell {

        let horizontalFraction =
            eastwardDegrees(
                from: bounds.west,
                to: station.longitude
            )
            / bounds.longitudeSpan

        let verticalFraction =
            (
                bounds.north
                - station.latitude
            )
            / bounds.latitudeSpan

        let column =
            min(
                max(
                    Int(
                        horizontalFraction
                        * Double(
                            Self.columnCount
                        )
                    ),
                    0
                ),
                Self.columnCount - 1
            )

        let row =
            min(
                max(
                    Int(
                        verticalFraction
                        * Double(
                            Self.rowCount
                        )
                    ),
                    0
                ),
                Self.rowCount - 1
            )

        return GridCell(
            column: column,
            row: row
        )
    }

    private func remainingStationCount(
        in cell: GridCell,
        stationsByCell:
            [GridCell: [AtlasStation]],
        nextIndexByCell:
            [GridCell: Int]
    ) -> Int {

        let totalCount =
            stationsByCell[cell]?.count
            ?? 0

        let nextIndex =
            nextIndexByCell[cell]
            ?? 0

        return max(
            totalCount - nextIndex,
            0
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
    GridCell:
        Hashable,
        Sendable {

        let column: Int
        let row: Int
    }
}
