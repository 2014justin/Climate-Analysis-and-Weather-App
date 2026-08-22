import Foundation

nonisolated fileprivate struct
WeatherGovStateSample:
    Sendable {

    let latitude: Double
    let longitude: Double
}

nonisolated struct
WeatherGovViewportStateResolver:
    Sendable {

    func stateCodes(
        in bounds: AtlasMapBounds
    ) async throws -> [String] {

        let centerLatitude =
            (bounds.north + bounds.south) / 2

        let centerLongitude =
            normalizedLongitude(
                (bounds.east + bounds.west) / 2
            )

        let west =
            normalizedLongitude(bounds.west)

        let east =
            normalizedLongitude(bounds.east)

        let samples = [
            WeatherGovStateSample(
                latitude: centerLatitude,
                longitude: centerLongitude
            ),
            WeatherGovStateSample(
                latitude: bounds.north,
                longitude: west
            ),
            WeatherGovStateSample(
                latitude: bounds.north,
                longitude: east
            ),
            WeatherGovStateSample(
                latitude: bounds.south,
                longitude: west
            ),
            WeatherGovStateSample(
                latitude: bounds.south,
                longitude: east
            )
        ]

        return try await withThrowingTaskGroup(
            of: String?.self
        ) { group in

            for sample in samples {
                group.addTask {
                    try await
                        WeatherGovStateCodeService()
                            .fetchStateCode(
                                latitude:
                                    sample.latitude,
                                longitude:
                                    sample.longitude
                            )
                }
            }

            var resolvedStateCodes:
                Set<String> = []

            for try await stateCode in group {
                if let stateCode {
                    resolvedStateCodes.insert(
                        stateCode
                    )
                }
            }

            return resolvedStateCodes.sorted()
        }
    }

    private func normalizedLongitude(
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
}
