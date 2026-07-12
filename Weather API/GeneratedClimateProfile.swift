/// Generate a climate profile from a station ID. For example,  the user should
/// be able to just enter 'KBIL' into the station adder and the app knows
/// "Hey this is Billings, MT, let's compute smooth climate normal highs
/// and lows from the ACIS API, then fit T max and T min to fourier harmonics
/// so we have a closed form solution. Then use Solar Energy algorithm in
/// Weather Almanac to get us a closed form S(t) and therefore normalized
/// s(t). This makes it a more flexible app as it just requires a NWS abbreviated
/// station.

import Foundation

///Fourier series. Codable is short for
struct FourierSeries: Codable, Equatable, Hashable {
    let constant: Double
    let cosineCoefficients: [Double]
    let sineCoefficients: [Double]
    
    func value(dayOfYear t: Double) -> Double {
        let w = 2.0 * Double.pi / 365.0
        
        var result = constant
        
        for index in cosineCoefficients.indices {
            let harmonic = Double(index + 1)
            result += cosineCoefficients[index] * cos(harmonic * w * t)
        }
        
        for index in sineCoefficients.indices {
            let harmonic = Double(index + 1)
            result += sineCoefficients[index] * sin(harmonic * w * t)
        }
        
        return result
    }
    
    func value(dayOfYear t: Int) -> Double {
        value(dayOfYear: Double(t))
    }
}

///generate a climate profile from a station id, e.g. 'KBIL'. Future station-adder result. Once we fetch
///ACIS normals and fit them, this struct can answer the same questions our graphs need.
struct GeneratedClimateProfile: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let stationID: String
    let displayName: String
    let latitude: Double
    let longitude: Double
    
    let solarMinimumEnergy: Double
    let solarMaximumEnergy: Double
    
    ///FourierSeries is a reusable math object. A new station can just store coefficients as data, not the whole linear
    ///combination of sines and cosines. These coefficients completely specify normal Highs and Lows. Some stations
    ///must have a higher order fit, especially colder high desert climates in the intermountain West , like Stanley ID
    ///or even Denver CO experiences this. The solution is to just throw more coefficients/fit order at it until the
    ///RMSE gets acceptably low
    let normalHighSeries: FourierSeries
    let normalLowSeries: FourierSeries
    
    let sourceStartYear: Int
    let sourceEndYear: Int
    let usableObservationCount: Int
    let fitOrder: Int
    let highRMSE: Double
    let lowRMSE: Double
    
    ///Normal High
    func normalHigh(dayOfYear t: Int) -> Double {
        normalHighSeries.value(dayOfYear: t)
    }
    
    ///Normal Low
    func normalLow(dayOfYear t: Int) -> Double {
        normalLowSeries.value(dayOfYear: t)
    }
    
    ///Solar Energy S(t)
    func solarEnergy(dayOfYear t: Int) -> Double {
        WeatherAlmanac.eTSolarEnergy(
            dayOfYear: t,
            latitude: latitude
        )
    }
    
    ///Normalized solar s(t)
    func normalizedSolarEnergy(dayOfYear t: Int) -> Double {
        guard solarMaximumEnergy > solarMinimumEnergy else {
            return 0.0
        }

        let solarEnergy = solarEnergy(dayOfYear: t)

        return (solarEnergy - solarMinimumEnergy) / (solarMaximumEnergy - solarMinimumEnergy)
    }
}

struct GeneratedDailyClimateNormal: Identifiable, Equatable {
    let dayOfYear: Int
    let normalHigh: Double
    let normalLow: Double
    let highSampleCount: Int
    let lowSampleCount: Int
    
    var id: Int {
        dayOfYear
    }
}

///We use a no-case enum for stateless utility code.
enum GeneratedClimateNormalCalculator {
    
    ///Since GeneratedClimateNormalCalculator is an enum utility namespace, we are never making objects from it.
    ///so its helper properties/functions should be static.
    ///
    ///Start by creating one shared Gregorian calendar
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }()
    
    ///multiple years from the same calendar day are being used, like 2020-07-15, 1998-07-15 and 2014-07-15
    ///Maps any real date onto a standard 365-day year. Jan 1, 1991 -> Day 1 . Jan 1, 2007 -> day 1
    private static func referenceDayOfYear(from date: Date) -> Int? {
        let components = calendar.dateComponents([.month, .day], from: date)
        
        ///Try to extract the month and day from this Date. If either one is missing, stop and return nil.
        ///checks whether swift successfully gave us a month and day at all.
        guard let month = components.month,
              let day = components.day else {
            return nil
        }
        
        ///Leap Year
        if month == 2 && day == 29 {
            return nil
        }
        
        guard let referenceDate = calendar.date(
            from: DateComponents(year: 2001, month: month, day: day)
        ) else {
            return nil
        }
        
        return calendar.ordinality(of: .day, in: .year, for: referenceDate)
    }
    
    ///Daily Normals
    ///Other code will eventually call this function, so do NOT private it
    ///This takes raw ACIS rows and produces daily normals. We require 20 day-years of data.
    static func dailyNormals(
        from observations: [ACISDailyObservation],
        minimumSampleCount: Int = 20
    ) -> [GeneratedDailyClimateNormal] {
        ///highsByDay is a nested array. For example the 0th component might be:
        ///1: [55.0, 54.2, 62.3, ... ]
        ///Colon means start as an empty dictionary
        var highsByDay: [Int: [Double]] = [:]
        var lowsByDay: [Int: [Double]] = [:]
        
        for observation in observations {
            
            ///If this obs cannot be mapped onto a normal 365-day year, skip. This catches Feb 29 leap year.
            guard let dayOfYear = referenceDayOfYear(from: observation.date) else {
                continue
            }
            
            ///append adds one item to the end of an array. Adds the temperature value to that day's pile
            ///"Find the array of high temperatures for this day-of-year. If no array exists yet, start with an empty one.
            ///Then add this observation's high temperature
            if let maximumTemperature = observation.maximumTemperature {
                highsByDay[dayOfYear, default: []].append(maximumTemperature)
            }
            
            if let minimumTemperature = observation.minimumTemperature {
                lowsByDay[dayOfYear, default: []].append(minimumTemperature)
            }
        }
        
        ///The returns tries to build one normal for every day of the year. compactMap is important because
        ///it lets the function return nil for bad or incomplete days and Swift will drop those days from the final array.
        return (1...365).compactMap { dayOfYear in
            let highs = highsByDay[dayOfYear] ?? []
            let lows = lowsByDay[dayOfYear] ?? []
            
            ///Needs highs count per day to be at least 20, so 20  years of data. Fort Yukon Alaska fails this
            ///and need to look elsewhere.
            guard highs.count >= minimumSampleCount,
                  lows.count >= minimumSampleCount else {
                return nil
            }
            
            ///Take the arithmetic average of the highs and call it the normal High. Starts with a sum.
            ///This is the unsmoothed, jagged normals. To get the proper smoothing, we do a Gaussian smoothing
            ///function.
            let normalHigh = highs.reduce(0.0, +) / Double(highs.count)
            let normalLow = lows.reduce(0.0, +) / Double(lows.count)
            
            return GeneratedDailyClimateNormal(
                dayOfYear: dayOfYear,
                normalHigh: normalHigh,
                normalLow: normalLow,
                highSampleCount: highs.count,
                lowSampleCount: lows.count
            )
        }
    }
    
    ///Cyclic Gaussian smoothing for the 365 daily normals. Raw 30 year daily means can wobble from sampling noise.
    ///If we didn't do this the climate data would look jaggy. this also helps us faithfully find thermal midsommar and midwinter
    ///for a location, so it is important. Even thermal midspring can be found by setting T''min(t) = 0
    
    ///This helper func takes the daw daily normals and makes them more physically climate-like
    static func smoothedDailyNormals(
        from normals: [GeneratedDailyClimateNormal],
        sigma: Double = 5.0,
        radius: Int = 15
    ) -> [GeneratedDailyClimateNormal] {
        
        ///This guard requires us to have a full 365 day year. If we have 348 usable days, the fit cannot work.
        guard normals.count == 365 else {
            return normals
        }
        
        ///Makes sure the array is in clean calendar order: day 1, day 2, day 3.
        let sortedNormals = normals.sorted { first, second in
            first.dayOfYear < second.dayOfYear
        }
        
        ///Creates the weighting kernel. Radius 15 means each smoothed day looks 15 days backward and 15 days forward
        ///for a total of 31-day smoothing window. Nearby days matter much more than faraway days
        let weights = gaussianWeights(sigma: sigma, radius: radius)
        
        ///Builds a new array of the smoothed normals. One output row for each input day.
        ///so for exmaple, lets say Jan 15 unsmoothed is 57.4 F. Then Jan 15 smoothed might be 59.5 F.
        ///
        ///Cyclic weights matter hear because the real calendar year wraps around. So Jan 1 can borrow days from
        ///Dec 29, 30, 31 but also Jan 2, 3, 4.
        return sortedNormals.indices.map { index in
            let smoothedHigh = cyclicWeightedAverage(
                values: sortedNormals.map { $0.normalHigh },
                centerIndex: index,
                weights: weights
            )
            
            ///Does the same for the lows
            let smoothedLow = cyclicWeightedAverage(
                values: sortedNormals.map { $0.normalLow },
                centerIndex: index,
                weights: weights
            )
            
            ///Returns a new Generated DailyClimateNormal.
            ///
            ///Replaces the high/low values with smoothed values, but keeps the original sample counts.
            return GeneratedDailyClimateNormal(
                dayOfYear: sortedNormals[index].dayOfYear,
                normalHigh: smoothedHigh,
                normalLow: smoothedLow,
                highSampleCount: sortedNormals[index].highSampleCount,
                lowSampleCount: sortedNormals[index].lowSampleCount
            )
        }
    }
    
    ///fourier series fit. We also want to account for some intermountain west climates having noticeable winter wobble, as this is a real climate signal being manifested. QA/QC date from NWS
    ///shows a wobble in midwinter for high desert climates like Denver CO or Stanley ID. This means it is an inherent part of the climate system and should be accomadated.
    ///the following three helper functions: fourierSeries, rootMeanSquareError, and bestFourierSeries fit the smoothed normals to a fourier fit, then decide how many
    ///harmonics it needs. The more complex the climate, the more terms are needed. These are expressed as cosineCoefficients and sineCoefficients.
    
    static func fourierSeries(
        values: [Double],
        order: Int
    ) -> FourierSeries {
        
        ///The guard basically says if someone passes no data, return a harmless zero series in stead of crashing.
        guard values.isEmpty == false else {
            return FourierSeries(
                constant: 0.0,
                cosineCoefficients: [],
                sineCoefficients: []
            )
        }
        
        ///w is the angular frequency of the year. Remember Double(count) is basically always 365.
        let count = values.count
        let w = 2.0 * Double.pi / Double(count)
        
        ///Constant is basically the annual mean level around which the seasonal wave oscillates.
        let constant = values.reduce(0.0,+) / Double(count)
        
        ///Harmonic 1 is the basic annual wave with winter low and summer high. Higher harmonics add shape.
        ///Harmonic 2 can add shoulder season/asymmetry. Harmonic 3 and more can capture extra wiggles like
        ///thermal midwinter temperature fluctuation as seen in stations like Denver CO or Stanley ID.
        ///These aren't random and must be accepted as an intrinsic part of the climate system.
        let cosineCoefficients = (1...order).map { harmonic in
            let k = Double(harmonic)
            
            ///Asks How much does this temperature curve resemble this cosine wave?
            let total = values.indices.reduce(0.0) { partialResult, index in
                let t = Double(index + 1)
                return partialResult + values[index] * cos(k * w * t)
            }
            
            ///normalizes the coefficient
            return 2.0 * total / Double(count)
        }
        
        ///Same but with sine.
        let sineCoefficients = (1...order).map { harmonic in
            let k = Double(harmonic)
            
            let total = values.indices.reduce(0.0) { partialResult, index in
                let t = Double(index + 1)
                return partialResult + values[index] * sin(k * w * t)
            }
            
            return 2.0 * total / Double(count)
        }
        
        return FourierSeries(
            constant: constant,
            cosineCoefficients: cosineCoefficients,
            sineCoefficients: sineCoefficients
        )
    }
    
    ///Measure how good the fit is.
    static func rootMeanSquareError(
        observedValues: [Double],
        fittedSeries: FourierSeries
    ) -> Double {
        guard observedValues.isEmpty == false else {
            return 0.0
        }
        
        ///calculates RMSE
        let squaredErrorTotal = observedValues.indices.reduce(0.0) { partialResult, index in
            let dayOfYear = index + 1
            let fittedValue = fittedSeries.value(dayOfYear: dayOfYear)
            let error = observedValues[index] - fittedValue
            
            return partialResult + error * error
        }
        
        ///RMSE is roughly the typical miss size of the Fourier curve, in deg F. We want RMSE less than 0.4 F for our purposes.
        return sqrt(squaredErrorTotal / Double(observedValues.count))
    }
    
    ///how many harmonics do we actually need?
    ///tried every order from 3...10
    ///finds the absolute best RMSE.
    ///then picks the simplest order whose RMSE is close enough to the best.
    ///Returns a tuple containing series, order, and rmse.
    static func bestFourierSeries(
        values: [Double],
        minOrder: Int = 3,
        maxOrder: Int = 10,
        rmseTolerance: Double = 0.05
    ) -> (series: FourierSeries, order: Int, rmse: Double) {
        let validMinOrder = max(1, minOrder)
        let validMaxOrder = max(validMinOrder, maxOrder)
        
        let fits = (validMinOrder...validMaxOrder).map { order in
            let series = fourierSeries(
                values: values,
                order: order
            )
            
            let rmse = rootMeanSquareError(
                observedValues: values,
                fittedSeries: series
            )
            
            return (
                series: series,
                order: order,
                rmse: rmse
            )
        }
        
        ///Look through all the candidate fits and find the one with the smallest RMSE.
        ///If there is no fit at all, run the fallback code.
        ///The else block is fallback code. In normal use, fits should never be empty because we forced
        ///valid order bounds.
        guard let bestFit = fits.min(by: { first, second in
            first.rmse < second.rmse
        }) else {
            let fallbackSeries = fourierSeries(
                values: values,
                order: validMinOrder
            )
            
            let fallbackRMSE = rootMeanSquareError(
                observedValues: values,
                fittedSeries: fallbackSeries
            )
            
            return (
                series: fallbackSeries,
                order: validMinOrder,
                rmse: fallbackRMSE
            )
        }
        
        ///Say the best fit is order 10 with RMSE of 0.42 F. With a tolerance of 0.05, any fit with RMSE up to
        ///0.47 F is considered close enough.
        let acceptableRMSE = bestFit.rmse + rmseTolerance
        
        ///Since fits is order from low to high, first(where:... picks the simplest acceptable fit.
        ///That's the beauty. If a 6th order works as good (less than 0.05 F difference) as a 10th order,
        ///we use the 6th order.
        if let simplestGoodFit = fits.first(where: { fit in
            fit.rmse <= acceptableRMSE
        }) {
            return simplestGoodFit
        }
        
        return bestFit
    }
    ///First pipeline function. ACIS rows:
    ///-> daily normals -> smoothed normals -> best Fourier fit for highs -> best FF for lows
    ///-> Generated Climate Profile
    static func generatedProfile(
        stationID: String,
        displayName: String,
        latitude: Double,
        longitude: Double,
        observations: [ACISDailyObservation],
        sourceStartYear: Int,
        sourceEndYear: Int,
    ) -> GeneratedClimateProfile? {
        let rawNormals = dailyNormals(
            from: observations
        )
        
        ///If the station cannot produce all 365 usable normal days, the generated profile fails.
        guard rawNormals.count == 365 else {
            return nil
        }
        
        ///Takes the 365 raw daily normals and Gaussian-smooths them.
        ///Makes the dates more smooth and climate-like
        let smoothNormals = smoothedDailyNormals(
            from: rawNormals
        )
        
        ///extracts only the high-temperature curve
        let highValues = smoothNormals.map { normal in
            normal.normalHigh
        }
        
        let lowValues = smoothNormals.map { normal in
            normal.normalLow
        }
        
        ///Fits the smoothed normal high curve
        let highFit = bestFourierSeries(
            values: highValues
        )
        
        ///Fourier fit our smoothed normal low fit
        let lowFit = bestFourierSeries(
            values: lowValues
        )
        
        let fitOrder = max(
            highFit.order,
            lowFit.order
        )
        
        ///Cleans up user input. so if a user types " kbil ", it becomes "KBIL". no need to be super exact. Gives us
        ///stable IDs and prevents whitespace bugs.
        let safeStationID = stationID
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        
        ///Computes extraterrestrial solar energy for every day of the year at that station latitude. Generated from solar geometry.
        ///Units are kWh/m^2/day
        let solarValues = (1...365).map { day in
            WeatherAlmanac.eTSolarEnergy(
                dayOfYear: day,
                latitude: latitude
            )
        }
        
        ///Finds the annual low and high of solar energy values. Should be near winter and summer solstices.
        let solarMinimumEnergy = solarValues.min() ?? 0.0
        let solarMaximumEnergy = solarValues.max() ?? 1.0
        
        ///Packs everything into one generated profile, with solar radiation, smoothed and fourier fitted highs/lows.
        ///Takes raw ACIS data and makes it a reusable in-app climate profile.
        return GeneratedClimateProfile(
            id: "generated-\(safeStationID)",
            stationID: safeStationID,
            displayName: displayName,
            latitude: latitude,
            longitude: longitude,
            solarMinimumEnergy: solarMinimumEnergy,
            solarMaximumEnergy: solarMaximumEnergy,
            normalHighSeries: highFit.series,
            normalLowSeries: lowFit.series,
            sourceStartYear: sourceStartYear,
            sourceEndYear: sourceEndYear,
            usableObservationCount: observations.count,
            fitOrder: fitOrder,
            highRMSE: highFit.rmse,
            lowRMSE: lowFit.rmse
        )
    }
    
    ///Calculates the bell-shaped weights for smoothing. If the radius is 15, then offsets are -15,-14,...,-1,0,1,...14,15
    private static func gaussianWeights(
        sigma: Double,
        radius: Int
    ) -> [Double] {
        let offsets = (-radius...radius)
        
        ///Gaussian bell curve here. Center offset zero gets largest weight. Further away gets smaller basically exponentially.
        let rawWeights = offsets.map { offset in
            let x = Double(offset)
            return exp(-(x * x) / (2.0 * sigma * sigma))
        }
        
        ///Adds up all the raw weights.
        let totalWeight = rawWeights.reduce(0.0,+)
        
        ///Defensive fallback code. If something weird happened and the total weight was zero, the function would not
        ///return equal weights instead of dividing by zero.
        guard totalWeight > 0.0 else {
            return Array(
                repeating: 1.0 / Double(rawWeights.count),
                count: rawWeights.count
            )
        }
        
        ///Normalize the weights so they add up to 1.0
        return rawWeights.map { weight in
            weight / totalWeight
        }
    }
    
    
    ///Gaussian blur works by calculating a weighted average of a central point and its
    ///neighbors using a bell-shaped curve to determine the weights. Points closest to center have the most influence.
    ///This function actually applies those weights.
    private static func cyclicWeightedAverage(
        values: [Double],
        centerIndex: Int,
        weights: [Double]
    ) -> Double {
        guard values.isEmpty == false,
              weights.isEmpty == false else {
            return 0.0
        }
        
        let radius = weights.count / 2
        let count = values.count
        
        var result = 0.0
        
        ///wrapped Index is working on Jan 1, it will wrap around to late december in stead of going out of bounds.
        for weightIndex in weights.indices {
            let offset = weightIndex - radius
            let rawIndex = centerIndex + offset
            let wrappedIndex = (rawIndex % count + count) % count
            
            ///Adds each neighboring value times its Gaussian weight
            result += values[wrappedIndex] * weights[weightIndex]
        }
        
        return result
    }
    
}


