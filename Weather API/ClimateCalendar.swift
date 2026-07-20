/// Re-usable climate calendar that maps number day of year to an actual calendar date.
/// for example 32 = Feb 1.
///
import Foundation

enum ClimateLeapDayPolicy: Sendable {
    case omit
    case mapToFebruary28
}

enum ClimateCalendar {
    
    private static let referenceYear = 2001
    
    private static let referenceCalendar: Calendar = {
        var calendar =
            Calendar(identifier: .gregorian)
        
        calendar.timeZone =
            TimeZone(secondsFromGMT: 0)
            ?? .current
        
        return calendar
    }()
    
    static func climatologicalDayOfYear(
        for climateDate: ClimateDate,
        leapDayPolicy:
            ClimateLeapDayPolicy = .omit
    ) -> Int? {
        
        let month = climateDate.month
        var day = climateDate.day
        
        if month == 2,
           day == 29 {
            switch leapDayPolicy {
            case .omit:
                return nil
                
            case .mapToFebruary28:
                day = 28
            }
        }
        
        let components =
            DateComponents(
                year: referenceYear,
                month: month,
                day: day
            )
        
        guard let referenceDate =
                referenceCalendar.date(
                    from: components
                ),
              referenceCalendar.component(
                .month,
                from: referenceDate
              ) == month,
              referenceCalendar.component(
                .day,
                from: referenceDate
              ) == day,
              let dayOfYear =
                referenceCalendar.ordinality(
                    of: .day,
                    in: .year,
                    for: referenceDate
                ) else {
            return nil
        }
        
        return dayOfYear
    }
}
