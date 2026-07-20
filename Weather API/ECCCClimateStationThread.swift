import Foundation

struct ECCCClimateStationThread: Identifiable, Hashable, Sendable {
    let records: [ECCCClimateStation]
    
    let representativeRecord: ECCCClimateStation
    
    init?(
        records: [ECCCClimateStation]
    ) {
        var recordsByIdentifier:
            [String: ECCCClimateStation] = [:]
        
        for record in records
        where record.hasDailyRecord {
            recordsByIdentifier[
                record.climateIdentifier
            ] = record
        }
        
        let sortedRecords =
            recordsByIdentifier.values.sorted {
                if let firstStart =
                    $0.dailyRecordStart,
                   let secondStart =
                    $1.dailyRecordStart,
                   firstStart != secondStart {
                    return firstStart < secondStart
                }
                
                return $0.climateIdentifier < $1.climateIdentifier
        }
        
        guard let representativeRecord =
                sortedRecords.last else {
            return nil
        }
        
        self.records = sortedRecords
        self.representativeRecord = representativeRecord
    }
    
    var id: String {
        climateIdentifiers.joined(
            separator: "+"
        )
    }
    
    var climateIdentifiers: [String] {
        records.map {
            $0.climateIdentifier
        }
    }
    
    var stationName: String {
        representativeRecord.stationName
    }
    
    var provinceCode: String {
        representativeRecord.provinceCode
    }
    
    var coordinate: GeographicCoordinate {
        representativeRecord.coordinate
    }
    
    var elevationMeters: Double? {
        representativeRecord.elevationMeters
    }
    
    var dailyRecordStart: ClimateDate? {
        records.compactMap {
            $0.dailyRecordStart
        }
        .min()
    }
    
    var dailyRecordEnd: ClimateDate? {
        records.compactMap {
            $0.dailyRecordEnd
        }
        .max()
    }
    
    func distanceMiles(
        from sourceCoordinate: GeographicCoordinate
    ) -> Double? {
        GeodesicDistance.miles(
            from: sourceCoordinate,
            to: coordinate
        )
    }
    
    func records(
        overlapping startDate: ClimateDate,
        through endDate: ClimateDate
    ) -> [ECCCClimateStation] {
        guard startDate <= endDate else {
            return []
        }
        
        return records.filter { record in
            guard let recordStart =
                    record.dailyRecordStart,
                  let recordEnd =
                    record.dailyRecordEnd else {
                return false
            }
            
            return recordEnd >= startDate
                && recordStart <= endDate
        }
    }
}

enum ECCCClimateStationThreadBuilder {
    static func threads(
        from stations: [ECCCClimateStation]
    ) -> [ECCCClimateStationThread] {
        let groupedStations = Dictionary(
            grouping: stations,
            by: groupingKey
        )
        
        return groupedStations.values
            .compactMap {
                ECCCClimateStationThread(records: $0)
            }
            .sorted {
                if $0.stationName
                    != $1.stationName {
                    return $0.stationName
                        .localizedCaseInsensitiveCompare(
                            $1.stationName
                        ) == .orderedAscending
                }
                
                return $0.id < $1.id
            }
    }
    
    nonisolated private static func groupingKey(
        for station: ECCCClimateStation
    ) -> String {
        if let transportCanadaIdentifier =
            station
                .transportCanadaIdentifier {
            return """
                TC:\(transportCanadaIdentifier)
                """
        }
        
        if let wmoIdentifier =
            station.wmoIdentifier {
            return """
                WMO:\(wmoIdentifier)
                """
        }
        
        return """
            CLIMATE:\(station.climateIdentifier)
            """
    }
}
