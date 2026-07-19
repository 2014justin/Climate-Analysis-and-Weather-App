import Foundation
enum ECCCClimateStationThreadDailyServiceError: LocalizedError {
    
    case invalidDateRange
    
    var errorDescription: String? {
        switch self {
        case .invalidDateRange:
            return """
                The Canadian climate-thread \
                request has an invalid date range.
                """
        }
    }
}

struct ECCCClimateStationThreadDailyService {
    private let dailyService:
        ECCCClimateDailyService
    
    init(
        dailyService:
            ECCCClimateDailyService = ECCCClimateDailyService()
    ) {
        self.dailyService = dailyService
    }
    
    func fetchObservations(
        for thread: ECCCClimateStationThread,
        startDate: ClimateDate,
        endDate: ClimateDate
    ) async throws
    -> [ClimateDailyObservation] {
        guard startDate <= endDate else {
            throw ECCCClimateStationThreadDailyServiceError
                .invalidDateRange
        }
        
        let overlappingRecords =
            thread.records(
                overlapping: startDate,
                through: endDate
            )
        
        var observationsByDate:
        [
            ClimateDate:
                ClimateDailyObservation
        ] = [:]
        
        for record in overlappingRecords {
            guard let recordStart =
                    record.dailyRecordStart,
                  let recordEnd =
                    record.dailyRecordEnd else {
                continue
            }
            
            let requestStart = max(
                startDate,
                recordStart
            )
            
            let requestEnd = min(
                endDate,
                recordEnd
            )
            
            let observations =
                try await dailyService
                    .fetchObservations(
                        climateIdentifier: record.climateIdentifier,
                        startDate: requestStart,
                        endDate: requestEnd
                    )
            
            for observation in observations {
                if let existing =
                    observationsByDate[
                        observation.localDate
                    ] {
                    
                    observationsByDate[
                        observation.localDate
                    ] = Self.merged(
                        existing: existing,
                        replacement: observation
                    )
                } else {
                    observationsByDate[
                        observation.localDate
                    ] = observation
                }
            }
        }
        
        return observationsByDate.values
            .sorted {
                $0.localDate < $1.localDate
            }
    }
    
    private static func merged(
        existing: ClimateDailyObservation,
        replacement: ClimateDailyObservation
    ) -> ClimateDailyObservation {
        ClimateDailyObservation(
            localDate: replacement.localDate,
            minimumTemperature:
                preferredReading(
                    existing: existing.minimumTemperature,
                    replacement: replacement.minimumTemperature
                ),
            maximumTemperature:
                preferredReading(
                    existing: existing.maximumTemperature,
                    replacement: replacement.maximumTemperature
                )
        )
    }
    
    private static func preferredReading(
        existing: ClimateTemperatureReading,
        replacement: ClimateTemperatureReading
    ) -> ClimateTemperatureReading {
        let existingRank = qualityRank(existing.quality)
        
        let replacementRank = qualityRank(replacement.quality)
        
        if existingRank > replacementRank {
            return existing
        }
        
        return replacement
    }
    
    private static func qualityRank(
        _ quality: ClimateObservationQuality
    ) -> Int {
        switch quality {
        case .observed:
            return 3
            
        case .estimated:
            return 2
            
        case .rejected:
            return 1
            
        case .missing:
            return 0
        }
    }
}
