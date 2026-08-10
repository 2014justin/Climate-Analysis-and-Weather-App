import Foundation

nonisolated enum SolarEventCalculator {
    static func dayProfile(
        for date: Date,
        coordinate: SolarCoordinate,
        timeZone: TimeZone
    ) -> SolarDayProfile? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let dayStart = calendar.startOfDay(for: date)

        guard let nextDayStart = calendar.date(
            byAdding: .day,
            value: 1,
            to: dayStart
        ) else {
            return nil
        }

        let samples = altitudeSamples(
            from: dayStart,
            through: nextDayStart,
            coordinate: coordinate
        )

        guard !samples.isEmpty else {
            return nil
        }


        let eventPairs =
            SolarEventThreshold.allCases.map { threshold in
                let events = thresholdEvents(
                    for: threshold,
                    samples: samples,
                    coordinate: coordinate
                )

                return (threshold, events)
            }

        let eventsByThreshold =
            Dictionary(uniqueKeysWithValues: eventPairs)

        let noon = refinedExtreme(
            .maximum,
            samples: samples,
            coordinate: coordinate
        )

        let midnight = refinedExtreme(
            .minimum,
            samples: samples,
            coordinate: coordinate
        )

        return SolarDayProfile(
            localDayStart: dayStart,
            nextLocalDayStart: nextDayStart,
            coordinate: coordinate,
            timeZoneIdentifier: timeZone.identifier,
            thresholdEvents: eventsByThreshold,
            solarNoon: noon.instant,
            solarMidnight: midnight.instant,
            maximumSolarAltitudeDegrees:
                noon.altitudeDegrees,
            minimumSolarAltitudeDegrees:
                midnight.altitudeDegrees
        )
    }
    
    static func yearProfile(
        for year: Int,
        coordinate: SolarCoordinate,
        timeZone: TimeZone
    ) -> SolarYearProfile? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        
        var startComponents = DateComponents()
        startComponents.timeZone = timeZone
        startComponents.year = year
        startComponents.month = 1
        startComponents.day = 1
        
        var endComponents = startComponents
        endComponents.year = year + 1
        
        guard let yearStart = calendar.date(from: startComponents),
              let nextYearStart = calendar.date(from: endComponents) else {
            return nil
        }
        
        var profiles: [SolarDayProfile] = []
        var date = yearStart
        
        while date < nextYearStart {
            guard let profile = dayProfile(
                for: date,
                coordinate: coordinate,
                timeZone: timeZone
            ) else {
                return nil
            }
            
            profiles.append(profile)
            date = profile.nextLocalDayStart
        }
        
        return SolarYearProfile(
            year: year,
            coordinate: coordinate,
            timeZoneIdentifier: timeZone.identifier,
            days: profiles
        )
    }

    private static func thresholdEvents(
        for threshold: SolarEventThreshold,
        samples: [AltitudeSample],
        coordinate: SolarCoordinate
    ) -> SolarThresholdEvents {
        let target = threshold.solarAltitudeDegrees

        var rising: Date?
        var setting: Date?

        for index in 0..<(samples.count - 1) {
            let first = samples[index]
            let second = samples[index + 1]

            let firstOffset =
                first.altitudeDegrees - target
            let secondOffset =
                second.altitudeDegrees - target

            if firstOffset < 0.0,
               secondOffset >= 0.0,
               rising == nil {
                rising = refinedCrossing(
                    from: first.instant,
                    to: second.instant,
                    targetAltitudeDegrees: target,
                    coordinate: coordinate
                )
            }

            if firstOffset >= 0.0,
               secondOffset < 0.0 {
                setting = refinedCrossing(
                    from: first.instant,
                    to: second.instant,
                    targetAltitudeDegrees: target,
                    coordinate: coordinate
                )
            }
        }

        let condition: SolarThresholdCondition

        if rising != nil || setting != nil {
            condition = .crosses
        } else {
            let lowest =
                samples.map(\.altitudeDegrees).min() ?? -90.0
            let highest =
                samples.map(\.altitudeDegrees).max() ?? 90.0

            if lowest >= target {
                condition = .alwaysAbove
            } else if highest < target {
                condition = .alwaysBelow
            } else {
                condition = .crosses
            }
        }

        return SolarThresholdEvents(
            threshold: threshold,
            rising: rising,
            setting: setting,
            condition: condition
        )
    }

    private static func refinedCrossing(
        from start: Date,
        to end: Date,
        targetAltitudeDegrees: Double,
        coordinate: SolarCoordinate
    ) -> Date {
        var lowerDate = start
        var upperDate = end

        var lowerValue =
            altitude(
                at: lowerDate,
                coordinate: coordinate
            )
            - targetAltitudeDegrees

        for _ in 0..<40 {
            let middleDate = midpoint(
                between: lowerDate,
                and: upperDate
            )

            let middleValue =
                altitude(
                    at: middleDate,
                    coordinate: coordinate
                )
                - targetAltitudeDegrees

            let crossingIsInLowerHalf =
                (lowerValue <= 0.0 && middleValue >= 0.0)
                || (lowerValue >= 0.0 && middleValue <= 0.0)

            if crossingIsInLowerHalf {
                upperDate = middleDate
            } else {
                lowerDate = middleDate
                lowerValue = middleValue
            }
        }

        return midpoint(
            between: lowerDate,
            and: upperDate
        )
    }

    private static func refinedExtreme(
        _ kind: ExtremeKind,
        samples: [AltitudeSample],
        coordinate: SolarCoordinate
    ) -> AltitudeSample {
        var bestIndex = 0

        for index in samples.indices.dropFirst() {
            if kind.prefers(
                samples[index].altitudeDegrees,
                over: samples[bestIndex].altitudeDegrees
            ) {
                bestIndex = index
            }
        }

        guard bestIndex > 0,
              bestIndex < samples.count - 1 else {
            return samples[bestIndex]
        }

        var lowerDate = samples[bestIndex - 1].instant
        var upperDate = samples[bestIndex + 1].instant

        for _ in 0..<36 {
            let duration =
                upperDate.timeIntervalSince(lowerDate)

            let leftDate =
                lowerDate.addingTimeInterval(duration / 3.0)
            let rightDate =
                upperDate.addingTimeInterval(-duration / 3.0)

            let leftAltitude =
                altitude(
                    at: leftDate,
                    coordinate: coordinate
                )
            let rightAltitude =
                altitude(
                    at: rightDate,
                    coordinate: coordinate
                )

            if kind.shouldDiscardLowerSide(
                leftAltitude: leftAltitude,
                rightAltitude: rightAltitude
            ) {
                lowerDate = leftDate
            } else {
                upperDate = rightDate
            }
        }

        let instant = midpoint(
            between: lowerDate,
            and: upperDate
        )

        return AltitudeSample(
            instant: instant,
            altitudeDegrees: altitude(
                at: instant,
                coordinate: coordinate
            )
        )
    }

    private static func altitudeSamples(
        from start: Date,
        through end: Date,
        coordinate: SolarCoordinate,
        step: TimeInterval = 300.0
    ) -> [AltitudeSample] {
        var samples: [AltitudeSample] = []
        var instant = start

        while instant < end {
            samples.append(
                AltitudeSample(
                    instant: instant,
                    altitudeDegrees: altitude(
                        at: instant,
                        coordinate: coordinate
                    )
                )
            )

            instant = instant.addingTimeInterval(step)
        }

        samples.append(
            AltitudeSample(
                instant: end,
                altitudeDegrees: altitude(
                    at: end,
                    coordinate: coordinate
                )
            )
        )

        return samples
    }

    private static func altitude(
        at instant: Date,
        coordinate: SolarCoordinate
    ) -> Double {
        let ephemeris =
            SolarPositionCalculator.ephemeris(at: instant)

        return SolarPositionCalculator.solarAltitudeDegrees(
            latitudeDegrees: coordinate.latitudeDegrees,
            longitudeDegrees: coordinate.longitudeDegrees,
            using: ephemeris
        )
    }

    private static func midpoint(
        between first: Date,
        and second: Date
    ) -> Date {
        first.addingTimeInterval(
            second.timeIntervalSince(first) / 2.0
        )
    }
}

private nonisolated struct AltitudeSample {
    let instant: Date
    let altitudeDegrees: Double
}

private nonisolated enum ExtremeKind {
    case minimum
    case maximum

    func prefers(
        _ candidate: Double,
        over current: Double
    ) -> Bool {
        switch self {
        case .minimum:
            return candidate < current
        case .maximum:
            return candidate > current
        }
    }

    func shouldDiscardLowerSide(
        leftAltitude: Double,
        rightAltitude: Double
    ) -> Bool {
        switch self {
        case .minimum:
            return leftAltitude > rightAltitude
        case .maximum:
            return leftAltitude < rightAltitude
        }
    }
}
