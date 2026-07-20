/// Gives the future builder a clean, reusable way to turn official composites
/// into the same candidate cards used by US Stations.
///
/// Downloads each historical segment and statches its reading into one continuos
/// climate record.
///
import Foundation

enum ECCCClimateCompositeDailyServiceError: LocalizedError {
    
    case invalidDateRange
    
    var errorDescription: String? {
        switch self {
        case .invalidDateRange:
            return """
                The ECCC composite climate request \
                has an invalid date range.
                """
        }
    }
}

private struct ECCCClimateCompositeDailyRequest: Hashable {
    
    let climateIdentifier: String
    
    let startDate: ClimateDate
    
    let endDate: ClimateDate
}

struct ECCCClimateCompositeDailyService {
    
    private let dailyService: ECCCClimateDailyService
    
    nonisolated init(
        dailyService: ECCCClimateDailyService =
                        ECCCClimateDailyService()
    ) {
        self.dailyService = dailyService
    }
    
    func fetchObservations(
        for composite: ECCCClimateComposite,
        startDate: ClimateDate,
        endDate: ClimateDate
    ) async throws -> [ClimateDailyObservation] {
        
        guard startDate <= endDate else {
            throw ECCCClimateCompositeDailyServiceError
                .invalidDateRange
        }
        
        let maximumRequests = requests(
            for: composite.maximumTemperatureThread,
            startDate: startDate,
            endDate: endDate
        )
        
        let minimumRequests = requests(
            for: composite.minimumTemperatureThread,
            startDate: startDate,
            endDate: endDate
        )
        
        let uniqueRequests = Array(
            Set(
                maximumRequests + minimumRequests
            )
        )
        .sorted {
             firstRequest,
            secondRequest in
            
            if firstRequest.startDate
                != secondRequest.startDate {
                return firstRequest.startDate
                    < secondRequest.startDate
            }
            
            if firstRequest.endDate
                != secondRequest.endDate {
                return firstRequest.endDate
                    < secondRequest.endDate
            }
            
            return firstRequest.climateIdentifier
                < secondRequest.climateIdentifier
        }
        
        var observationsByRequest:
            [
                ECCCClimateCompositeDailyRequest:
                    [ClimateDailyObservation]
            ] = [:]
        
        for request in uniqueRequests {
            observationsByRequest[request] =
                try await dailyService
                    .fetchObservations(
                        climateIdentifier: request.climateIdentifier,
                        startDate: request.startDate,
                        endDate: request.endDate
                    )
        }
        
        let maximumReadings = readings(
            for: composite.maximumTemperatureThread,
            requests: maximumRequests,
            observationsByRequest: observationsByRequest
        )
        
        let minimumReadings = readings(
            for: composite.minimumTemperatureThread,
            requests: minimumRequests,
            observationsByRequest: observationsByRequest
        )
        
        let allDates = Set(maximumReadings.keys)
            .union(minimumReadings.keys)
            .sorted()
        
        return allDates.map { date in
            ClimateDailyObservation(
                localDate: date,
                minimumTemperature:
                    minimumReadings[date]
                    ?? Self.missingReading,
                maximumTemperature:
                    maximumReadings[date]
                    ?? Self.missingReading
            )
        }
    }
    
    private func requests(
        for thread: ECCCClimateElementThread,
        startDate: ClimateDate,
        endDate: ClimateDate
    ) -> [ECCCClimateCompositeDailyRequest] {
        
        thread.segments
            .sorted {
                $0.sequence < $1.sequence
            }
            .compactMap { segment in
                let requestStartDate = max(
                    startDate,
                    segment.normalStartDate
                )
                
                let requestEndDate = min(
                    endDate,
                    segment.normalEndDate
                )
                
                guard requestStartDate
                        <= requestEndDate else {
                    return nil
                }
                
                return ECCCClimateCompositeDailyRequest(
                    climateIdentifier: segment.climateIdentifier,
                    startDate: requestStartDate,
                    endDate: requestEndDate
                )
            }
    }
    
    private func readings(
        for thread: ECCCClimateElementThread,
        requests: [ECCCClimateCompositeDailyRequest],
        observationsByRequest:
            [
                ECCCClimateCompositeDailyRequest:
                    [ClimateDailyObservation]
            ]
    ) -> [
        ClimateDate: ClimateTemperatureReading
    ] {
        
        var readingsByDate:
            [
                ClimateDate:
                    ClimateTemperatureReading
            ] = [:]
        
        for request in requests {
            let observations =
                observationsByRequest[request]
                ?? []
            
            for observation in observations {
                guard observation.localDate
                        >= request.startDate,
                      observation.localDate
                        <= request.endDate else {
                    continue
                }
                
                let reading: ClimateTemperatureReading
                
                switch thread.element {
                case .dailyMaximumTemperature:
                    reading = observation.maximumTemperature
                    
                case .dailyMinimumTemperature:
                    reading = observation.minimumTemperature
                    
                
                }
                
                
                readingsByDate[
                    observation.localDate
                ] = reading
            }
        }
        
        return readingsByDate
    }
    
    private static let missingReading =
        ClimateTemperatureReading(
            fahrenheit: nil,
            quality: .missing,
            sourceFlag: nil
        )
}
