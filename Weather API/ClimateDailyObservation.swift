/// Provider-neutral local calendar date.
///
/// Climate observations represent a station's local climate day,
/// rather than an arbitrary UTC isntant.
///
/// Creates a common language between weather-data providers and the climate mathematics
///
/// Previously the pipeline was: ACISDailyObservation -> Daily Normals -> Smoothing -> Fourier.
///
/// The new flow is:
///    ACIS response ──→ ACIS adapter ──┐
///                                  ├─→ ClimateDailyObservation
///  ECCC response ──→ ECCC adapter ──┘              ↓
///                                  shared climate engine
///

import Foundation

///Stores a station's local calendar date.
struct ClimateDate: Codable, Equatable, Hashable, Sendable {
    let year: Int
    let month: Int
    let day: Int
    
    init(
        year: Int,
        month: Int,
        day: Int
    ) {
        self.year = year
        self.month = month
        self.day = day
    }
    
    /// ACIS Dates are currently parsed as UTC Dates.
    
    init?(utcDate: Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone =
        TimeZone(secondsFromGMT: 0) ?? .current
        
        let components = calendar.dateComponents(
            [.year, .month, .day],
            from: utcDate
        )
        
        guard let year = components.year,
                let month = components.month,
                let day = components.day
        else {
            return nil
        }
        
        self.init(
            year: year,
            month: month,
            day: day
        )
    }
}

extension ClimateDate: Comparable {
    static func < (lhs: ClimateDate, rhs: ClimateDate) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }
        
        if lhs.month != rhs.month {
            return lhs.month < rhs.month
        }
        
        return lhs.day < rhs.day
    }
}

/// Provider-neutral interpretation of a reported value. ECCC has quality flags such as estimated or missing.
/// The shared calculator should not need to understand what an ECCC "E" or "M" means. Instead, the ECCC
/// adapter translates those flags: ECCC "E" -> .estimated & ECCC "M" -> .missing
///
/// The original flag can still be retained in sourceFlag for provenance and debugging.
enum ClimateObservationQuality: String, Codable, Equatable, Hashable, Sendable {
    
    case observed
    case estimated
    case missing
    case rejected
    
    var isUsableForClimateNormals: Bool {
        switch self {
        case .observed, .estimated:
            return true
            
        case .missing, .rejected:
            return false
        }
    }
}

/// One temperature value with explicit units and retained quality.
struct ClimateTemperatureReading: Codable, Equatable, Hashable, Sendable {
    let fahrenheit: Double?
    let quality: ClimateObservationQuality
    let sourceFlag: String?
    
    var usableFahrenheit: Double? {
        guard quality.isUsableForClimateNormals else {
            return nil
        }
        
        return fahrenheit
    }
}

/// Provider-neutral dialy temperatures consumed by the shared
/// climate-normal and Fourier-fitting pipeline. It intentionally only contains the information
/// required to generate a temperature climate profile. ACIS precip, snowfall, Weather Year, and threshold-season features
/// continue using ACISDailyObservation for now.
struct ClimateDailyObservation: Identifiable, Codable, Equatable, Hashable, Sendable {
    let localDate: ClimateDate
    let minimumTemperature: ClimateTemperatureReading
    let maximumTemperature: ClimateTemperatureReading
    
    var id: ClimateDate {
        localDate
    }
}

enum ClimateObservationCompletenessCalculator {
    static func pairedCompleteness(
        observations: [ClimateDailyObservation],
        startDate: ClimateDate,
        endDate: ClimateDate
    ) -> Double? {
        guard startDate <= endDate else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone =
            TimeZone(secondsFromGMT: 0) ?? .current

        let startComponents = DateComponents(
            year: startDate.year,
            month: startDate.month,
            day: startDate.day
        )

        let endComponents = DateComponents(
            year: endDate.year,
            month: endDate.month,
            day: endDate.day
        )

        guard let firstDate =
                calendar.date(from: startComponents),
              let lastDate =
                calendar.date(from: endComponents),
              let dayDifference =
                calendar.dateComponents(
                    [.day],
                    from: firstDate,
                    to: lastDate
                ).day else {
            return nil
        }

        let expectedDayCount = dayDifference + 1

        guard expectedDayCount > 0 else {
            return nil
        }

        let pairedDates = Set(
            observations.compactMap {
                observation -> ClimateDate? in

                guard observation.localDate >= startDate,
                      observation.localDate <= endDate,
                      observation.minimumTemperature
                        .usableFahrenheit != nil,
                      observation.maximumTemperature
                        .usableFahrenheit != nil else {
                    return nil
                }

                return observation.localDate
            }
        )

        return Double(pairedDates.count)
            / Double(expectedDayCount)
    }
}
