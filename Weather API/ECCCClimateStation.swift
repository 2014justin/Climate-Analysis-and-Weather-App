import Foundation

struct ECCCClimateStation: Identifiable, Codable, Hashable, Sendable {
    let climateIdentifier: String
    let stationName: String
    let provinceCode: String
    
    let latitude: Double
    let longitude: Double
    let elevationMeters: Double?
    
    let transportCanadaIdentifier: String?
    let wmoIdentifier: String?
    let timeZoneCode: String?
    
    let stationType: String?
    let operatorName: String?
    
    let dailyRecordStart: ClimateDate?
    let dailyRecordEnd: ClimateDate?
    
    var id: String {
        climateIdentifier
    }
    
    var coordinate: GeographicCoordinate {
        GeographicCoordinate(
            latitude: latitude,
            longitude: longitude
        )
    }
    
    func distanceMiles(
        from sourceCoordinate:
            GeographicCoordinate
    ) -> Double? {
        GeodesicDistance.miles(
            from: sourceCoordinate,
            to: coordinate
        )
    }
    
    var hasDailyRecord: Bool {
        dailyRecordStart != nil
            && dailyRecordEnd != nil
    }
}
