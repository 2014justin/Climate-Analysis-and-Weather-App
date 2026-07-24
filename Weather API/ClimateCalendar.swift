/// Reusable climate calendar that maps a calendar date
/// onto a stable 365-day climatological year.
/// For example, February 1 becomes day 32.
import Foundation

enum ClimateLeapDayPolicy: Sendable {
    case omit
    case mapToFebruary28
}

enum ClimateMonthDayStyle: Sendable {
    case abbreviated
    case numeric
    
    fileprivate var dateFormat: String {
        switch self {
        case .abbreviated:
            return "MMM d"
            
        case .numeric:
            return "M/d"
        }
    }
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
    
    /// Converts a Foundation Date into a stable climatological day using the station's timezone.
    /// Function overloading.
    
    static func climatologicalDayOfYear(
        for date: Date,
        in timeZone: TimeZone,
        leapDayPolicy:
            ClimateLeapDayPolicy = .omit
    ) -> Int? {
        
        var sourceCalendar =
            Calendar(identifier: .gregorian)
        
        sourceCalendar.timeZone = timeZone
        
        let components =
            sourceCalendar.dateComponents(
                [.year, .month, .day],
                from: date
            )
        
        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            return nil
        }
        
        return climatologicalDayOfYear(
            for: ClimateDate(
                year: year,
                month: month,
                day: day
            ),
            leapDayPolicy: leapDayPolicy
        )
    }
    
    /// Converts a climatological day number into a date canonical
    /// non-leap reference year.
    static func referenceDate(
        forClimatologicalDay dayOfYear: Double?
    ) -> Date? {
        
        guard let dayOfYear,
              dayOfYear.isFinite == true else {
            return nil
        }
        
        let roundedDay =
            Int(dayOfYear.rounded())
        
        guard (1...365).contains(roundedDay),
              let firstDay =
                referenceCalendar.date(
                    from: DateComponents(
                        year: referenceYear,
                        month: 1,
                        day: 1
                    )
                ) else {
            return nil
        }
        
        return referenceCalendar.date(
            byAdding: .day,
            value: roundedDay - 1,
            to: firstDay
        )
    }
    
    /// Formats a climatological day without exposing the reference year.
    static func monthDayText(
        fromClimatologicalDay dayOfYear: Double?,
        style:
            ClimateMonthDayStyle = .abbreviated
    ) -> String? {
        
        guard let date =
                referenceDate(
                    forClimatologicalDay:
                        dayOfYear
                ) else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.calendar = referenceCalendar
        formatter.timeZone =
            referenceCalendar.timeZone
        formatter.locale =
            Locale(identifier: "en_US_POSIX")
        formatter.dateFormat =
            style.dateFormat
        
        return formatter.string(
            from: date
        )
    }
}
