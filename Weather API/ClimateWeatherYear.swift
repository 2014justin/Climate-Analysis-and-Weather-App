/// Accepts rows from either ACIS, ECCC, or any future country API
/// Goes to ClimateDailyObservation, then ClimateWeatherYearCalculator, then [WeatherYearDay]
/// then a shared SwiftUI chart and table.
///
/// This swift calculates selected-year observations, daily source-period extremes, available years
/// record metadata, and sample counts.
import Foundation

struct ClimateWeatherYearRecordInfo: Equatable, Sendable {
    
    /// Coverage where at least one usable temperature element exists.
    let sourceStartDate: ClimateDate?
    let sourceEndDate: ClimateDate?
    let usableRowCount: Int
    let representedYearCount: Int
    
    /// Tmin and Tmax can have different station lineages and periods
    /// of record. So PoR can span a century or more.
    let minimumTemperatureStartDate: ClimateDate?
    let minimumTemperatureEndDate: ClimateDate?
    let minimumTemperatureObservationCount: Int
    
    let maximumTemperatureStartDate: ClimateDate?
    let maximumTemperatureEndDate: ClimateDate?
    let maximumTemperatureObservationCount: Int
}

enum ClimateWeatherYearCalculator {
    
    /// Chart dates use a fixed non-leap reference year.
    /// The actual observation year remains stored in ClimateDate.
    private static let displayCalendar: Calendar = {
        var calendar =
            Calendar(identifier: .gregorian)
        
        calendar.timeZone =
        TimeZone(secondsFromGMT: 0)
            ?? .current
        
        return calendar
    }()
    
    static func weatherYearDays(
        from observations:
            [ClimateDailyObservation],
        selectedYear: Int,
        location: WeatherLocation
    ) -> [WeatherYearDay] {
        
        var observationsByDay:
            [Int: [ClimateDailyObservation]] = [:]
        
        var selectedYearObservationsByDay:
            [Int: ClimateDailyObservation] = [:]
        
        for observation in observations {
            
            guard let dayOfYear =
                    ClimateCalendar
                        .climatologicalDayOfYear(for: observation.localDate)
            else {
                continue
            }
            
            observationsByDay[
                dayOfYear,
                default: []
            ].append(observation)
            
            if observation.localDate.year
                == selectedYear {
                
                selectedYearObservationsByDay[
                    dayOfYear
                ] = observation
            }
        }
        
        guard let referenceStartDate =
                displayCalendar.date(
                    from: DateComponents(
                        year: 2001,
                        month: 1,
                        day: 1
                    )
                ) else {
            return []
        }
        
        return (1...365).compactMap {
            dayOfYear in
            
            guard let displayDate =
                    displayCalendar.date(
                        byAdding: .day,
                        value: dayOfYear - 1,
                        to: referenceStartDate
                    ) else {
                return nil
            }
            
            let dayObservations =
                observationsByDay[dayOfYear] ?? []
            
            let selectedObservation =
                selectedYearObservationsByDay[
                    dayOfYear
                ]
            
            let minimumTemperatures =
                dayObservations.compactMap {
                    observation in
                    
                    observation
                        .minimumTemperature
                        .usableFahrenheit
                }
            
            let maximumTemperatures =
                dayObservations.compactMap {
                    observation in
                    
                    observation
                        .maximumTemperature
                        .usableFahrenheit
                }
            
            return WeatherYearDay(
                dayOfYear:
                    dayOfYear,
                date:
                    displayDate,
                selectedYearMinimum:
                    selectedObservation?.minimumTemperature.usableFahrenheit,
                selectedYearMaximum:
                    selectedObservation?.maximumTemperature.usableFahrenheit,
                normalLow:
                    location.normalLow(dayOfYear: dayOfYear),
                normalHigh:
                    location.normalHigh(dayOfYear: dayOfYear),
                recordLowMinimum:
                    minimumTemperatures.min(),
                recordHighMaximum:
                    maximumTemperatures.max(),
                recordWarmMinimum:
                    minimumTemperatures.max(),
                recordCoolMaximum:
                    maximumTemperatures.min(),
                sampleCount:
                    dayObservations.count
            )
        }
    }
    
    static func availableYears(
        from observations:
            [ClimateDailyObservation]
    ) -> [Int] {
        
        let years = Set(
            observations.compactMap {
                observation -> Int? in
                
                let hasUsableMinimum =
                    observation
                        .minimumTemperature
                        .usableFahrenheit != nil
                
                let hasUsableMaximum =
                    observation
                        .maximumTemperature
                        .usableFahrenheit != nil
                
                guard hasUsableMinimum
                        || hasUsableMaximum else {
                    return nil
                }
                
                return observation.localDate.year
            }
        )
        
        return years.sorted(
            by: >
        )
    }
    
    static func recordInfo(
        from observations:
            [ClimateDailyObservation]
    ) -> ClimateWeatherYearRecordInfo {
        
        let usableObservations =
            observations.filter { observation in
                observation
                    .minimumTemperature
                    .usableFahrenheit != nil
                || observation
                    .maximumTemperature
                    .usableFahrenheit != nil
            }
        
        let minimumObservations =
            observations.filter { observation in
                observation
                    .minimumTemperature
                    .usableFahrenheit != nil
            }
        
        let maximumObservations =
            observations.filter { observation in
                observation
                    .maximumTemperature
                    .usableFahrenheit != nil
            }
        
        return ClimateWeatherYearRecordInfo(
            sourceStartDate:
                usableObservations
                    .map { $0.localDate }
                    .min(),
            sourceEndDate:
                usableObservations
                    .map { $0.localDate }
                    .max(),
            usableRowCount:
                usableObservations.count,
            representedYearCount:
                availableYears(from: usableObservations).count,
            minimumTemperatureStartDate:
                minimumObservations
                    .map { $0.localDate }
                    .min(),
            minimumTemperatureEndDate:
                minimumObservations
                    .map { $0.localDate }
                    .max(),
            minimumTemperatureObservationCount:
                minimumObservations.count,
            maximumTemperatureStartDate:
                maximumObservations
                    .map { $0.localDate }
                    .min(),
            maximumTemperatureEndDate:
                maximumObservations
                    .map { $0.localDate }
                    .max(),
            maximumTemperatureObservationCount:
                maximumObservations.count
        )
    }
}

enum ClimateWeatherYearObservationServiceError:
    LocalizedError {
    
    case canadianCompositeNotFound(String)
    
    case currentDateUnavailable
    
    var errorDescription: String? {
        switch self {
        case .canadianCompositeNotFound(
            let identifier
        ):
            return """
                No official ECCC climate composite \
                was found for \(identifier).
                """
            
        case .currentDateUnavailable:
            return """
                The current calendar date could not \
                be resolved for the Canadian Weather Year request.
                """
            
            
        }
    }
}

/// Resolves the saved Canadian composite identifier, reconstructs its official separate Tmin/Tmax station threads.
/// Returns one provider-neutral [ClimateDailyObservation]

struct ClimateWeatherYearObservationService {
    
    private let canadianCatalogService:
        ECCCClimateCompositeCatalogService
    
    private let canadianDailyService:
        ECCCClimateCompositeDailyService
    
    nonisolated init(
        canadianCatalogService:
            ECCCClimateCompositeCatalogService =
                ECCCClimateCompositeCatalogService(),
        canadianDailyService:
            ECCCClimateCompositeDailyService =
                ECCCClimateCompositeDailyService()
    ) {
        self.canadianCatalogService =
            canadianCatalogService
        
        self.canadianDailyService =
            canadianDailyService
    }
    
    func fetchCanadianWeatherYearObservations(
        canonicalIdentifier: String
    ) async throws -> [ClimateDailyObservation] {
        
        guard let currentUTCDate =
                ClimateDate(utcDate: Date()) else {
            throw ClimateWeatherYearObservationServiceError.currentDateUnavailable
        }
        
        guard let composite =
                try canadianCatalogService
                    .composite(
                        withCanonicalIdentifier: canonicalIdentifier
                    ) else {
            throw ClimateWeatherYearObservationServiceError
                .canadianCompositeNotFound(canonicalIdentifier)
        }
        
        return try await canadianDailyService
            .fetchObservations(
                for: composite,
                startDate: ClimateDate(
                    year: 1991,
                    month: 1,
                    day: 1
                ),
                endDate: currentUTCDate
                
            )
    }
}
