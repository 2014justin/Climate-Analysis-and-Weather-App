///show climate graph content.

import SwiftUI
import Charts
import AppKit

struct ClimateGraphView: View {
    @Binding var graphType: ClimateGraphType
    let location: WeatherLocation
    @State private var keyMonitor: Any?
    @State private var selectedClimatePoint: ClimateDayPoint?
    ///holds the calculated ACIS result
    @State private var thresholdSummaries: [ACISThresholdSummary] = []
    ///lets us show loading state or disable buttons
    @State private var isLoadingThresholdSummary = false
    ///human readable status or error message.
    @State private var thresholdSummaryStatus = "Not loaded yet"
    /// loader function for climate data
    @State private var selectedThresholds: Set<Double> = [32.0]
    @State private var selectedThresholdEventMode = ThresholdEventMode.coldNights
    @State private var selectedThresholdRiskSeason = ThresholdRiskSeason.spring
    @State private var selectedThresholdRiskPoint: ThresholdRiskChartPoint?
    @State private var selectedWeatherYearDay: WeatherYearDay?
    @State private var thresholdOutputMode = ThresholdOutputMode.graph
    @State private var thresholdObservations: [ACISDailyObservation] = []
    @State private var selectedWeatherYear = 2020
    @State private var weatherYearDays: [WeatherYearDay] = []
    @State private var weatherYearRecordInfo: WeatherYearRecordInfo?
    @State private var selectedWeatherYearOverlays: Set<WeatherYearOverlay> = [
        ///Make record low and highs avail immediately, then record high minimum and record low minimum.
        .observedRange,
        .normalRange,
        .recordLowMinimum,
        .recordHighMaximum
    ]
    ///which station the current ACIS rows belong to
    @State private var loadedACISStationID: String?
    
    ///threshold buttons can change based on mode: cold nights, first/last warm afternoon, warm afternoon lock in, and
    ///mild night onset.
    private var thresholdPresets: [Double] {
        selectedThresholdEventMode.thresholdPresets
    }
    ///convert a double like 32.0 into a display text like "32"
    private func thresholdText(_ threshold: Double) -> String {
        threshold.formatted(.number.precision(.fractionLength(0)))
    }

    private var sortedSelectedThresholds: [Double] {
        thresholdPresets.filter { threshold in
            selectedThresholds.contains(threshold)
        }
    }

    private var selectedThresholdText: String {
        let selectedTexts = sortedSelectedThresholds.map { threshold in
            "\(thresholdText(threshold))°F"
        }

        return selectedTexts.isEmpty ? "none" : selectedTexts.joined(separator: ", ")
    }
    ///makes it possible to select mult temperatures
    private func toggleThreshold(_ threshold: Double) {
        if selectedThresholds.contains(threshold) {
            if selectedThresholds.count > 1 {
                selectedThresholds.remove(threshold)
            }
        } else {
            selectedThresholds.insert(threshold)
        }
    }
    
    private func resetThresholdsForSelectedMode() {
        let presets = selectedThresholdEventMode.thresholdPresets
        let stillValidThresholds = selectedThresholds.filter { threshold in            presets.contains(threshold)
        }
        ///select the first preset mode. The ?? 32.0 is fallback protection in case some
        ///future mode accidentally has an empty preset list
        if stillValidThresholds.isEmpty {
            selectedThresholds = [presets.first ?? 32.0]
        } else {
            selectedThresholds = stillValidThresholds
        }
        ///updates the results using the new mode/thresholds
        recalculateThresholdSummaries()
    }
    
    ///same function riskDateText, different parameter list. Swift can tell which one you mean whether we include the argument 'season'
    private func riskDateText(
        for riskPoint: ACISThresholdRiskPoint,
        season: ThresholdRiskSeason
    ) -> String {
        switch season {
        case .spring:
            return ACISThresholdCalculator.monthDayText(
                fromAverageDayOfYear: riskPoint.springRiskDay
            )
        case .fall:
            return ACISThresholdCalculator.monthDayText(
                fromAverageDayOfYear: riskPoint.fallRiskDay
            )
        }
    }
    
    ///One risk Point might contain: percent: 50 | springRiskDay: 133.0 (may 13) | fallRiskDay: 253.0 (Sep 10)
    ///the chart will only draw one season at a time
    private func riskDay(for riskPoint: ACISThresholdRiskPoint) -> Double? {
        switch selectedThresholdRiskSeason {
        case .spring:
            return riskPoint.springRiskDay
        case .fall:
            return riskPoint.fallRiskDay
        }
    }
    
    ///date from day of year mapping function
    private func dateFromDayOfYear(_ dayOfYear: Double?) -> Date? {
        guard let dayOfYear else {
            return nil
        }
        
        let calendar = Calendar(identifier: .gregorian)
        let roundedDay = Int(dayOfYear.rounded())
        
        return calendar.date(
            from: DateComponents(year: 2001, day: roundedDay)
        )
    }
    
    private var thresholdRiskDateDomain: ClosedRange<Date> {
        let dates = thresholdRiskChartPoints.map { point in
            point.date
        }

        guard let earliestDate = dates.min(),
              let latestDate = dates.max() else {
            let calendar = Calendar(identifier: .gregorian)
            let startDate = calendar.date(from: DateComponents(year: 2001, month: 1, day: 1))!
            let endDate = calendar.date(from: DateComponents(year: 2001, month: 12, day: 31))!
            return startDate...endDate
        }

        let calendar = Calendar(identifier: .gregorian)
        let paddedStart = calendar.date(byAdding: .day, value: -7, to: earliestDate) ?? earliestDate
        let paddedEnd = calendar.date(byAdding: .day, value: 7, to: latestDate) ?? latestDate

        return paddedStart...paddedEnd
    }

    private var thresholdMajorAxisDates: [Date] {
        let calendar = Calendar(identifier: .gregorian)
        let domain = thresholdRiskDateDomain

        return (1...12).compactMap { month in
            calendar.date(from: DateComponents(year: 2001, month: month, day: 1))
        }
        .filter { date in
            domain.contains(date)
        }
    }

    private var thresholdMinorAxisDates: [Date] {
        let calendar = Calendar(identifier: .gregorian)
        let domain = thresholdRiskDateDomain

        return (1...12).compactMap { month in
            calendar.date(from: DateComponents(year: 2001, month: month, day: 15))
        }
        .filter { date in
            domain.contains(date)
        }
    }
    ///This is a computed property, not a stored variable. Basically whenever someone asks for 'thresholdRiskChartPoints'
    ///calculate and return an array of chart-ready points.
    ///It transforms thresholdSummaries into a flat list the chart dan draw like: point: 32 F, 10%, May 21.
    ///this function is a data-shaping bridge. It takes climate/scientific summary data and reshapes it into
    ///a simple x,y, color-group chart points.
    private var thresholdRiskChartPoints: [ThresholdRiskChartPoint] {
        ///The flatMap line means "for every selected threshold summary, produce chart points, then flatten them all into
        ///one array.
        thresholdSummaries.flatMap { summary in
            ///for each risk point, try to convert it into a chart point. if conversion fails, top.
            summary.thresholdRiskPoints.compactMap { riskPoint in
                guard let date = dateFromDayOfYear(riskDay(for: riskPoint)) else {
                    return nil
                }
                ///builds the actual point the chart can draw.
                return ThresholdRiskChartPoint(
                    threshold: summary.threshold,
                    percent: riskPoint.percent,
                    date: date
                )
            }
            .sorted { firstPoint, secondPoint in
                firstPoint.date < secondPoint.date
            }
        }
    }
    ///Separate downloaded raw ACIS data from calculated threshold summaries
    ///the first let statement says "If someone handed me fresh observations, use those. otherwise, use the observations
    ///we already have saved in states.
    ///
    ///remember thresholdObservations have all daily minimum temperatures from 1991-2020. It is a huge array.
    private func recalculateThresholdSummaries(from observations: [ACISDailyObservation]? = nil) {
        let sourceObservations = observations ?? thresholdObservations
        ///If we have no ACIS daily rows yet, clear the summary list and stop.
        guard sourceObservations.isEmpty == false else {
            thresholdSummaries = []
            return
        }
        ///For every selected threshold (20, 28, 32, 36, 40) run the calculator five times. and produce
        ///five ACISThresholdSummary value. The calculations change with the threshold
        ///the raw data stays the same
        thresholdSummaries = sortedSelectedThresholds.map { threshold in
            ACISThresholdCalculator.thresholdSummary(
                from: sourceObservations,
                startYear: 1991,
                endYear: 2020,
                threshold: threshold,
                field: selectedThresholdEventMode.field,
                comparison: selectedThresholdEventMode.comparison,
                springEventChoice: selectedThresholdEventMode.springEventChoice,
                fallEventChoice: selectedThresholdEventMode.fallEventChoice
            )
        }
    }
    ///threshold seasons & weather for the year both use the same raw ACIS rows, but they produce different derived
    ///products. this keeps those calculations separate
    private func recalculateWeatherYearDays(from observations: [ACISDailyObservation]? = nil) {
        let sourceObservations = observations ?? thresholdObservations
        ///When you switch from 2020 to 2026, we do not want the hover tooltip stuck on an old day from the
        ///previous selected year
        selectedWeatherYearDay = nil
        
        guard sourceObservations.isEmpty == false else {
            weatherYearDays = []
            weatherYearRecordInfo = nil
            return
        }
        
        weatherYearDays = WeatherYearCalculator.weatherYearDays(
            from: sourceObservations,
            selectedYear: selectedWeatherYear,
            location: location
        )
        
        weatherYearRecordInfo = WeatherYearCalculator.recordInfo(
            from: sourceObservations
        )
    }
    ///async means the function is allowed to pause while waiting for network data.
    ///basically go get ACIS data, save it, then calculate summary.
    private func loadThresholdSummary() async {
        isLoadingThresholdSummary = true
        thresholdSummaryStatus = "Loading ACIS threshold data..."
        ///run this later when the function is about to exit. because the function might succeed or fail.
        defer {
            isLoadingThresholdSummary = false
        }
        ///climatology = 1991 to 2020. do blocks mean it starts a block of code that might throw an error.
        ///let observations means use the selected locations ACIS ID, ask ACIS for daily observations
        ///from Jan 1 1991 to Dec 31 2020 and wait for the result
        let todayString = Date.now.formatted(
            .iso8601
                .year()
                .month()
                .day()
                .dateSeparator(.dash)
        )
        do {
            let observations = try await ACISClimateService.fetchDailyObservations(
                stationID: location.acisStationID,
                startDate: "1991-01-01",
                endDate: todayString
            )
            ///recalculatethresholdsummaries turns daw daily obs into useful threshold summaries.
            thresholdObservations = observations
            loadedACISStationID = location.acisStationID
            let thresholdPeriodObservations = observations.filter { observation in
                let year = Calendar.current.component(.year, from: observation.date)
                return year >= 1991 && year <= 2020
            }
            recalculateThresholdSummaries(from: thresholdPeriodObservations)
            recalculateWeatherYearDays(from: observations)
            thresholdSummaryStatus = "Loaded \(observations.count) ACIS daily rows. \(weatherYearDays.count) weather-year days ready."
            ///if ACIS fails, we should clear all derived ACIS products.
        } catch {
            thresholdSummaries = []
            thresholdSummaryStatus = "ACIS threshold load failed: \(error.localizedDescription)"
            thresholdObservations = []
            weatherYearDays = []
            weatherYearRecordInfo = nil
            loadedACISStationID = nil
        }
    }
    
    
    /// Adds a current graph index. So annual temp curve would be index 0.
    private var currentGraphIndex: Int {
        ClimateGraphType.allGraphs.firstIndex { $0.id == graphType.id } ?? 0
    }
    
    private var canGoBackward: Bool {
        currentGraphIndex > 0
    }
    private var canGoForward: Bool {
        currentGraphIndex < ClimateGraphType.allGraphs.count - 1
    }
    private func goBackward() {
        guard canGoBackward else {
            return
        }
        
        graphType = ClimateGraphType.allGraphs[currentGraphIndex - 1]
    }
    
    private func goForward() {
        guard canGoForward else {
            return
        }
        
        graphType = ClimateGraphType.allGraphs[currentGraphIndex + 1]
    }
    
    ///toggle the weather overaly
    private func toggleWeatherYearOverlay(_ overlay: WeatherYearOverlay) {
        if selectedWeatherYearOverlays.contains(overlay) {
            if selectedWeatherYearOverlays.count > 1 {
                selectedWeatherYearOverlays.remove(overlay)
            }
        } else {
            selectedWeatherYearOverlays.insert(overlay)
        }
    }
    ///threshold seasons & weather-year both use the same ACIS daily rows, so we only fetch when the current graph actually needs ACIS data,
    ///and only if we do not already have rows for this station
    
    private var graphNeedsACISData: Bool {
        graphType == .thresholdSeasons || graphType == .weatherForTheYear
    }
    
    private func loadACISDataIfNeeded() async {
        guard graphNeedsACISData else {
            return
        }
        
        guard loadedACISStationID != location.acisStationID || thresholdObservations.isEmpty else {
            return
        }
        
        await loadThresholdSummary()
    }
    
    @Environment(\.dismiss) private var dismiss
    
    /// Make 365 data points for each day of the year, reference the climate data in
    /// WeatherAlamanc.swift, and make a climate graph for the user's viewing pleasure.
    private var climatePoints: [ClimateDayPoint] {
        (1...365).map { day in
            ClimateDayPoint(
                dayOfYear: day,
                normalHigh: WeatherAlmanac.normalHighFahrenheit(
                    dayOfYear: day,
                    profile: location.climatologyProfile
                ),
                normalLow: WeatherAlmanac.normalLowFahrenheit(
                    dayOfYear: day,
                    profile: location.climatologyProfile
                ),
                solarEnergy: WeatherAlmanac.solarEnergy(
                    dayOfYear: day,
                    profile: location.climatologyProfile
                ),
                normalizedSolar: WeatherAlmanac.normalizedSolarEnergy(
                    dayOfYear: day,
                    profile: location.climatologyProfile
                )
            )
        }
    }
    /// Indexes all 365 climate points and finds where the normal low is highest.
    private var peakNormalLowPoint: ClimateDayPoint? {
        climatePoints.max {first, second in
            first.normalLow < second.normalLow
        }
    }
    ///Define Tau(t)
    private func thermalWindow(threshold: Double, lookingForWarmWindow: Bool) -> ThermalWindow? {
        let lows = climatePoints.map { point in
            point.normalLow
        }
        
        guard let annualLow = lows.min(),
              let annualHigh = lows.max(),
              annualHigh > annualLow else {
            return nil
        }
        
        let matchingDays = climatePoints.filter { point in
            let tau = (point.normalLow - annualLow) / (annualHigh - annualLow)
            
            if lookingForWarmWindow {
                return tau >= threshold
            } else {
                return tau <= threshold
            }
        }
        
        guard !matchingDays.isEmpty else {
            return nil
        }
        
        if !lookingForWarmWindow {
            let matchingDayNumbers = Set(matchingDays.map { $0.dayOfYear })
            let includesStartOfYear = matchingDayNumbers.contains(1)
            let includesEndOfYear = matchingDayNumbers.contains(365)
            
            if includesStartOfYear && includesEndOfYear {
                let earlyYearDays = matchingDays.filter { $0.dayOfYear < 183 }
                let lateYearDays = matchingDays.filter { $0.dayOfYear >= 183 }
                
                guard let startDay = lateYearDays.first?.dayOfYear,
                      let endDay = earlyYearDays.last?.dayOfYear else {
                    return nil
                }
                
                let durationDays = (365 - startDay + 1) + endDay
                
                return ThermalWindow(
                    startDay: startDay,
                    endDay: endDay,
                    durationDays: durationDays
                )
            }
        }
        
        guard let startDay = matchingDays.first?.dayOfYear,
              let endDay = matchingDays.last?.dayOfYear else {
            return nil
        }
        
        return ThermalWindow(
            startDay: startDay,
            endDay: endDay,
            durationDays: endDay - startDay + 1
        )
    }
    
    /// Tau(t) >= 0.9 for thermal midsommar
    /// Tau(t) = or less than 0.1 for thermal midwinter
    private var thermalMidsommarWindow: ThermalWindow? {
        thermalWindow(threshold: 0.9, lookingForWarmWindow: true)
    }
    
    private var thermalMidwinterWindow: ThermalWindow? {
        thermalWindow(threshold: 0.1, lookingForWarmWindow: false)
    }
    
    ///Helps with the base 10 logic. If the annual minimum is 37, chart will start from y = 37.
    ///If it plateuas at 104 in midsommar, it will max out at 110.
    private var annualTemperatureDomain: ClosedRange<Double> {
        let allTemperatures = climatePoints.flatMap { point in
            [
                point.normalHigh,
                point.normalLow
            ]
        }
        
        guard let minimumTemperature = allTemperatures.min(),
              let maximumTemperature = allTemperatures.max() else {
            return 0...100
        }
        
        let lowerBound = floor(minimumTemperature / 10.0) * 10.0
        let upperBound = ceil(maximumTemperature / 10.0) * 10.0
        
        return lowerBound...upperBound
    }

    
    ///Hysteresis point function
    ///The moust is hovering near some point on the hysteresis graph. Which actual calendar day on our
    ///climate loop is closest to that moust position??
    ///Which day's (s, T-min) point is geometrically closest to the cursor??
    ///So we have to use pythagorean distance
    private func hysteresisPoint(
        closestToNormalizedSolar hoveredSolar: Double,
        normalLow hoveredNormalLow: Double
    ) -> ClimateDayPoint? {
        let xRange = 1.2
        let yRange = hysteresisTemperatureDomain.upperBound - hysteresisTemperatureDomain.lowerBound
        
        guard yRange > 0 else {
            return nil
        }
        
        return climatePoints.min { first, second in
            ///Calculate how hoveredSolar differs from normalized solar, and normalize or divide by the xRange
            let firstSolarDistance = (first.normalizedSolar - hoveredSolar) / xRange
            let firstTemperatureDistance = (first.normalLow - hoveredNormalLow) / yRange
            
            let secondSolarDistance = (second.normalizedSolar - hoveredSolar) / xRange
            let secondTemperatureDistance = (second.normalLow - hoveredNormalLow) / yRange
            ///Normalizing by chart range is necessary because s(t) goes from 0 to 1, while temperature might
            ///have an amplitude of 50 degrees or morel.
            ///Almost like a metric tensor square. g uu, or g vv.
            ///We do not need the square root because if a^2 is less than b^2 then a is less than b.
            let firstDistanceSquared =
                firstSolarDistance * firstSolarDistance + firstTemperatureDistance * firstTemperatureDistance
            
            let secondDistanceSquared =
                secondSolarDistance * secondSolarDistance + secondTemperatureDistance * secondTemperatureDistance
            return firstDistanceSquared < secondDistanceSquared
        }
    }
    ///Climate points parser/indexer
    private func climatePoint(for dayOfYear: Int) -> ClimateDayPoint? {
        guard (1...365).contains(dayOfYear) else {
            return nil
        }
        
        return climatePoints.first { point in
            point.dayOfYear == dayOfYear
        }
    }
    ///Define hover rectangle function so we can define it once and use it on any graph without having
    ///Calculate the seasonal memory index defined as the integral from 1 to 365 of T min(t) ds

    private var seasonalMemoryIndex: Double {
        let points = climatePoints.sorted { first, second in
            first.dayOfYear < second.dayOfYear
        }
        
        guard points.count > 1 else {
            return 0.0
        }
        
        var area = 0.0
        
        for index in 0..<(points.count - 1) {
            let currentPoint = points[index]
            let nextPoint = points[index + 1]
            
            let averageTemperature = (currentPoint.normalLow + nextPoint.normalLow) / 2.0
            let changeInSolar = nextPoint.normalizedSolar - currentPoint.normalizedSolar
            
            area += averageTemperature * changeInSolar
        }
        
        if let firstPoint = points.first,
           let lastPoint = points.last {
            let averageTemperature = (lastPoint.normalLow + firstPoint.normalLow) / 2.0
            let changeInSolar = firstPoint.normalizedSolar - lastPoint.normalizedSolar
            
            area += averageTemperature * changeInSolar
        }
        
        return abs(area)
    }
    ///Show the maximum eigendate chord from the code.
    private var maximumEigendateChord: EigendateChordResult? {
        guard let solarMaximumPoint = climatePoints.max(by: { first, second in
            first.normalizedSolar < second.normalizedSolar
        }) else {
            return nil
        }
        
        let solarMaximumDay = solarMaximumPoint.dayOfYear
        
        let coolBranch = climatePoints
            .filter { point in
                point.dayOfYear <= solarMaximumDay
            }
            .sorted { first, second in
                first.dayOfYear < second.dayOfYear
            }
        
        let warmBranch = climatePoints
            .filter { point in
                point.dayOfYear >= solarMaximumDay
            }
            .sorted { first, second in
                first.dayOfYear < second.dayOfYear
            }
        
        let lowerSolarBound = max(
            coolBranch.map { $0.normalizedSolar }.min() ?? 0.0,
            warmBranch.map { $0.normalizedSolar }.min() ?? 0.0
        )
        
        let upperSolarBound = min(
            coolBranch.map { $0.normalizedSolar }.max() ?? 1.0,
            warmBranch.map { $0.normalizedSolar }.max() ?? 1.0
        )
        
        guard lowerSolarBound < upperSolarBound else {
            return nil
        }
        
        var bestResult: EigendateChordResult?
        
        for step in 0...1000 {
            let fraction = Double(step) / 1000.0
            let targetSolar = lowerSolarBound
                + fraction * (upperSolarBound - lowerSolarBound)
            
            guard let coolPoint = interpolatedPoint(
                on: coolBranch,
                atNormalizedSolar: targetSolar
            ),
            let warmPoint = interpolatedPoint(
                on: warmBranch,
                atNormalizedSolar: targetSolar
            ) else {
                continue
            }
            
            let depth = warmPoint.temperature - coolPoint.temperature
            
            guard depth > 0 else {
                continue
            }
            
            if bestResult == nil || depth > bestResult!.depth {
                bestResult = EigendateChordResult(
                    depth: depth,
                    normalizedSolar: targetSolar,
                    coolBranchDay: Int(coolPoint.day.rounded()),
                    warmBranchDay: Int(warmPoint.day.rounded()),
                    coolBranchTemperature: coolPoint.temperature,
                    warmBranchTemperature: warmPoint.temperature
                )
            }
        }
        
        return bestResult
    }
    
    ///Adds ability to calculate the maximum differential of T min(t) for a specific s(t) input.
    ///Uses cool branch (a) and warm branch(b) guesses and iterates.
    private func interpolatedPoint(
        on branch: [ClimateDayPoint],
        atNormalizedSolar targetSolar: Double
    ) -> (day: Double, temperature: Double)? {
        guard branch.count >= 2 else {
            return nil
        }
        
        for index in 0..<(branch.count - 1) {
            let first = branch[index]
            let second = branch[index + 1]
            
            let firstSolar = first.normalizedSolar
            let secondSolar = second.normalizedSolar
            
            let targetIsBetween =
                (firstSolar <= targetSolar  && targetSolar <= secondSolar) ||
                (secondSolar <= targetSolar && targetSolar <= firstSolar)
            
            guard targetIsBetween else {
                continue
            }
            
            let solarDifference = secondSolar - firstSolar
            
            guard abs(solarDifference) > 0.000001 else {
                continue
            }
            
            let fraction = (targetSolar - firstSolar) / solarDifference
            
            let day = Double(first.dayOfYear)
                + fraction * Double(second.dayOfYear - first.dayOfYear)
            
            let temperature = first.normalLow
                + fraction * (second.normalLow - first.normalLow)
            return (day, temperature)
        }
        
        return nil
    }
    
    /// Helps with hysteresis graph base ten logic
    
    private var hysteresisTemperatureDomain: ClosedRange<Double> {
        let lowTemperatures = climatePoints.map { point in
            point.normalLow
        }
        
        guard let minimumTemperature = lowTemperatures.min(),
              let maximumTemperature = lowTemperatures.max() else {
            return 0...100
        }
        
        let lowerBound = floor(minimumTemperature / 10.0) * 10.0
        let upperBound = ceil(maximumTemperature / 10.0) * 10.0
        
        return lowerBound...upperBound
    }
    
    /// Adds nice arrow directions for the hysteresis graph.
    private var hysteresisArrowPoints: [ClimateDayPoint] {
        climatePoints.filter { point in
            [45, 90, 135, 180, 225, 270, 315, 360].contains(point.dayOfYear)
        }
    }
    ///Makes proper arrows scaled by how the x axis is scaled
    private func hysteresisArrowAngle(for day: Int) -> Angle {
        let previousDay = max(1, day - 3)
        let nextDay = min(365, day + 3)

        guard let previousPoint = climatePoints.first(where: { $0.dayOfYear == previousDay }),
              let nextPoint = climatePoints.first(where: { $0.dayOfYear == nextDay }) else {
            return .degrees(0)
        }

        let dx = nextPoint.normalizedSolar - previousPoint.normalizedSolar
        let dy = nextPoint.normalLow - previousPoint.normalLow

        let xRange = 1.2
        let yRange = annualTemperatureDomain.upperBound - annualTemperatureDomain.lowerBound

        let scaledDx = dx / xRange
        let scaledDy = -dy / yRange
        /// Properly scale it so the arrows aren't 'off the percs'.
        let angleRadians = atan2(scaledDy, scaledDx)
        let angleDegrees = angleRadians * 180.0 / Double.pi

        return .degrees(angleDegrees)
    }
    ///Convert day-of-year into a month/day label to display our midsommar maximum T min.
    ///Answer will be formatted like
    ///T min = 76.8 deg F
    ///s(t) = 0.91 (Jul 26)
    private func monthDayLabel(for dayOfYear: Int) -> String {
        var components = DateComponents()
        components.year = 2025
        components.day = dayOfYear
        
        let calendar = Calendar(identifier: .gregorian)
        
        guard let date = calendar.date(from: components) else {
            return "Day \(dayOfYear)"
        }
        
        let formatter = DateFormatter()
        ///turns "year 2025, day 207" into a "real" date to look like "Jul 26"
        formatter.dateFormat = "MMM d"
        
        return formatter.string(from: date)
    }
    ///nearest point helper. which actual chart point is closest to the mouse? ordered pairs in this space are like
    ///(May 2, 20%)
    private func thresholdRiskPoint(
        closestTo hoveredDate: Date,
        percent hoveredPercent: Double
        ///the return type is optional because there might be no points to choose from.
    ) -> ThresholdRiskChartPoint? {
        ///If there are no chart points, stop now
        guard thresholdRiskChartPoints.isEmpty == false else {
            return nil
        }
        ///Between the first & second, whichever has the smaller distance.
        return thresholdRiskChartPoints.min { first, second in
            let firstDateDistance = abs(first.date.timeIntervalSince(hoveredDate))
            let secondDateDistance = abs(second.date.timeIntervalSince(hoveredDate))
            
            let firstPercentDistance = abs(first.percent - hoveredPercent)
            let secondPercentDistance = abs(second.percent - hoveredPercent)
            ///without this, date distances would be giant numbers like 172800, and percent distance would be tiny like 3.
            let secondsPerDay = 24.0 * 60.0 * 60.0
            
            let firstScore = (firstDateDistance / secondsPerDay) + firstPercentDistance
            let secondScore = (secondDateDistance / secondsPerDay) + secondPercentDistance
            
            return firstScore < secondScore
        }
    }
    ///adds chart for threshold risks
    ///now for the chart as a secondary source of information
    private var thresholdRiskChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(selectedThresholdRiskSeason.title) Risk Probability")
                .font(.headline)

            Chart {
                ForEach(thresholdMinorAxisDates, id: \.self) { date in
                    RuleMark(
                        x: .value("Half Month", date)
                    )
                    .foregroundStyle(.white.opacity(0.16))
                    .lineStyle(StrokeStyle(lineWidth: 0.75, dash: [3, 5]))
                }
                ForEach(thresholdRiskChartPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Probability", point.percent)
                    )
                    .foregroundStyle(by: .value("Threshold", "\(thresholdText(point.threshold))°F"))
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                }

                if let selectedThresholdRiskPoint {
                    PointMark(
                        x: .value("Date", selectedThresholdRiskPoint.date),
                        y: .value("Probability", selectedThresholdRiskPoint.percent)
                    )
                    .foregroundStyle(.white)
                    .symbolSize(60)

                    RuleMark(
                        x: .value("Date", selectedThresholdRiskPoint.date)
                    )
                    .foregroundStyle(.white.opacity(0.45))
                }
            }
            .chartYScale(domain: 0...100)
            .chartXScale(domain: thresholdRiskDateDomain)
            .chartYAxis {
                AxisMarks(position: .leading, values: Array(stride(from: 0.0, through: 100, by: 10.0))) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let percent = value.as(Double.self) {
                            Text("\(percent.formatted(.number.precision(.fractionLength(0))))%")
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: thresholdMajorAxisDates) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date, format: .dateTime.month(.abbreviated).day())
                        }
                    }
                }

                AxisMarks(values: thresholdMinorAxisDates) { _ in
                    AxisTick()
                        .foregroundStyle(.secondary.opacity(0.75))
                    
                    AxisValueLabel {
                        Text("15")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .chartOverlay { proxy in
                ChartHoverOverlay(
                    proxy: proxy,
                    onHover: { plotLocation in
                        guard let hoveredDate = proxy.value(atX: plotLocation.x, as: Date.self),
                              let hoveredPercent = proxy.value(atY: plotLocation.y, as: Double.self) else {
                            selectedThresholdRiskPoint = nil
                            return
                        }

                        selectedThresholdRiskPoint = thresholdRiskPoint(
                            closestTo: hoveredDate,
                            percent: hoveredPercent
                        )
                    },
                    onEnded: {
                        selectedThresholdRiskPoint = nil
                    }
                )
            }
            .chartBackground { proxy in
                GeometryReader { geometry in
                    if let selectedThresholdRiskPoint,
                       let anchor = proxy.plotFrame {
                        let plotFrame = geometry[anchor]
                        let xPosition = proxy.position(forX: selectedThresholdRiskPoint.date) ?? 0
                        let yPosition = proxy.position(forY: selectedThresholdRiskPoint.percent) ?? 0

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(thresholdText(selectedThresholdRiskPoint.threshold))°F")
                                .fontWeight(.bold)

                            Text("\(selectedThresholdRiskPoint.percent.formatted(.number.precision(.fractionLength(0))))%")
                                .foregroundStyle(.secondary)

                            Text(selectedThresholdRiskPoint.date, format: .dateTime.month(.abbreviated).day())
                        }
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.black.opacity(0.78))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .position(
                            x: plotFrame.origin.x + xPosition + (xPosition > plotFrame.width - 120 ? -54 : 54),
                            y: plotFrame.origin.y + yPosition + (yPosition < 48 ? 42 : -34)
                        )
                    }
                }
            }
            .frame(height: 320)
        }
    }
    ///nice formatting for the table:
    private var thresholdRiskTable: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(selectedThresholdRiskSeason.title) Risk Dates")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    Text("Temp")
                        .fontWeight(.semibold)

                    ForEach([90.0, 80.0, 70.0, 60.0, 50.0, 40.0, 30.0, 20.0, 10.0], id: \.self) { percent in
                        Text("\(percent.formatted(.number.precision(.fractionLength(0))))%")
                            .fontWeight(.semibold)
                    }
                }

                Divider()
                    .gridCellColumns(10)

                ForEach(thresholdSummaries, id: \.threshold) { summary in
                    GridRow {
                        Text("\(thresholdText(summary.threshold))°F")
                            .fontWeight(.semibold)

                        ForEach([90.0, 80.0, 70.0, 60.0, 50.0, 40.0, 30.0, 20.0, 10.0], id: \.self) { percent in
                            let matchingPoint = summary.thresholdRiskPoints.first { riskPoint in
                                riskPoint.percent == percent
                            }

                            Text(
                                matchingPoint.map {
                                    riskDateText(
                                        for: $0,
                                        season: selectedThresholdRiskSeason
                                    )
                                } ?? "none"
                            )
                            .monospacedDigit()
                        }
                    }
                }
            }
            .font(.callout)
        }
    }
    
    private var thresholdSeasonsChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Threshold Seasons")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Station: \(location.acisStationID)")
                .font(.headline)
            
            Text("Min temperature thresholds: \(selectedThresholdText), 1991-2020")
                .foregroundStyle(.secondary)
            ///mode picker UI
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Thermal event")
                    .font(.headline)
                
                Picker("Thermal event", selection: $selectedThresholdEventMode) {
                    ForEach(ThresholdEventMode.allCases) { mode in
                        Text(mode.title)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedThresholdEventMode) {
                    resetThresholdsForSelectedMode()
                }
            }
            Text(selectedThresholdEventMode.technicalLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(selectedThresholdEventMode.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Temperature thresholds")

                ForEach(thresholdPresets, id: \.self) { threshold in
                    let isSelected = selectedThresholds.contains(threshold)

                    Button {
                        toggleThreshold(threshold)
                    } label: {
                        Text("\(thresholdText(threshold))°F")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.accentColor.opacity(0.25) : Color.white.opacity(0.08))
                            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .disabled(isSelected && selectedThresholds.count == 1)
                }
            }
            Picker("Risk season", selection: $selectedThresholdRiskSeason) {
                ForEach(ThresholdRiskSeason.allCases) { season in
                    Text(season.title)
                        .tag(season)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 220)
            
            Picker("Output", selection: $thresholdOutputMode) {
                ForEach(ThresholdOutputMode.allCases) { mode in
                    Text(mode.title)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 220)
            
            Text(thresholdSummaryStatus)
                .foregroundStyle(.secondary)
            
            if isLoadingThresholdSummary {
                ProgressView()
            }
            
            if thresholdSummaries.isEmpty == false {
                
                
                Divider()

                switch thresholdOutputMode {
                    ///already defined thresholdRiskChart & threshold risk table
                case .graph:
                    thresholdRiskChart
                    
                case .table:
                    thresholdRiskTable
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .onChange(of: selectedThresholds) {
            recalculateThresholdSummaries()
        }
        
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(graphType.title) - \(location.name)")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()

                HStack(spacing: 8) {
                    Button("‹") {
                        goBackward()
                    }
                    .disabled(!canGoBackward)
                    
                    Button("›") {
                        goForward()
                    }
                    .disabled(!canGoForward)
                    
                    Button("X") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    .keyboardShortcut("W", modifiers: .command)
                }
                .keyboardShortcut(.cancelAction)
            }
            
            Divider()
            
            switch graphType {
            case .annualTemperatureCurve:
                annualTemperatureChart
                
            case .seasonalHysteresisCurve:
                seasonalHysteresisChart
                
            case .thresholdSeasons:
                ScrollView {
                    thresholdSeasonsChart
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .weatherForTheYear:
                weatherForTheYearPlaceholder
            }
        }
        .padding()
        .frame(minWidth: 1000, minHeight: 720)
        ///The next .onappear block is very important for keyboard navigation of the app
        .task(id: "\(location.acisStationID)-\(graphType.id)") {
            await loadACISDataIfNeeded()
        }
        .onAppear {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                let isCommandW = event.modifierFlags.contains(.command)
                    && event.charactersIgnoringModifiers?.lowercased() == "w"
                ///Makes it so command shift A moves climate tab left
                let isCommandShiftA = event.modifierFlags.contains(.command)
                    && event.modifierFlags.contains(.shift)
                    && event.charactersIgnoringModifiers?.lowercased() == "a"
                /// Command shift D moves climate tab to the right
                let isCommandShiftD = event.modifierFlags.contains(.command)
                    && event.modifierFlags.contains(.shift)
                    && event.charactersIgnoringModifiers?.lowercased() == "d"

                if isCommandW {
                    dismiss()
                    return nil
                }

                if isCommandShiftA {
                    goBackward()
                    return nil
                }

                if isCommandShiftD {
                    goForward()
                    return nil
                }

                return event
            }
        }
        .onDisappear {
            if let keyMonitor {
                NSEvent.removeMonitor(keyMonitor)
            }
        }
    }
    
    /// This function actually plots the T min and T max for a climate site and graphs it
    /// under our climate UI.
    private var annualTemperatureChart: some View {
        Chart {
            ///Adds T max (red) but cursor-able
            ForEach(climatePoints) { point in
                LineMark(
                    x: .value("Day", point.dayOfYear),
                    y: .value("Temperature", point.normalHigh),
                    series: .value("Series", "Normal High")
                )
                .foregroundStyle(.red)
            }
            ///Adds T min (blue) but cursor-able
            ForEach(climatePoints) { point in
                LineMark(
                    x: .value("Day", point.dayOfYear),
                    y: .value("Temperature", point.normalLow),
                    series: .value("Series", "Normal Low")
                )
                .foregroundStyle(.blue)
            }
            if let selectedClimatePoint {
                RuleMark(
                    x: .value("Selected Day", selectedClimatePoint.dayOfYear)
                )
                .foregroundStyle(.white.opacity(0.45))
                
                PointMark(
                    x: .value("Selected High Day", selectedClimatePoint.dayOfYear),
                    y: .value("Selected High", selectedClimatePoint.normalHigh)
                )
                .foregroundStyle(.red)
                .symbolSize(70)
                
                PointMark(
                    x: .value("Selected Low Day", selectedClimatePoint.dayOfYear),
                    y: .value("Selected Low", selectedClimatePoint.normalLow)
                )
                .foregroundStyle(.blue)
                .symbolSize(70)
                .annotation(
                    position: selectedClimatePoint.dayOfYear >= 310 ? .leading : .trailing,
                    alignment: .center
                ) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(monthDayLabel(for: selectedClimatePoint.dayOfYear))
                            .font(.headline)
                        
                        Text("Day \(selectedClimatePoint.dayOfYear)")
                            .foregroundStyle(.secondary)
                        
                        Divider()
                        
                        Text("Normal High: \(selectedClimatePoint.normalHigh, specifier: "%.1f") °F")
                        Text("Normal Low: \(selectedClimatePoint.normalLow, specifier: "%.1f") °F")
                        Text("Solar: \(selectedClimatePoint.solarEnergy, specifier: "%.2f") kWh/m²/day")
                        Text("s(t): \(selectedClimatePoint.normalizedSolar, specifier: "%.3f")")
                    }
                    .font(.callout)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.black.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            ///Thermal midwinter & thermal midsommar
            if let peakNormalLowPoint,
               let thermalMidsommarWindow,
               let thermalMidwinterWindow {
                PointMark(
                    x: .value("Day", 15),
                    y: .value("Temperature", annualTemperatureDomain.upperBound)
                )
                .opacity(0)
                .annotation(position: .bottomTrailing, alignment: .leading) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Annual Low-Temperature Timing")
                            .font(.headline)
                        Text(
                            "Peak Normal Low: \(peakNormalLowPoint.normalLow, specifier: "%.1f") °F (\(monthDayLabel(for: peakNormalLowPoint.dayOfYear)))"
                        )
                        
                        Text(
                            "Thermal Midsommar: \(monthDayLabel(for: thermalMidsommarWindow.startDay)) → \(monthDayLabel(for: thermalMidsommarWindow.endDay))"
                        )
                        Text(
                            "Thermal Midwinter: \(monthDayLabel(for: thermalMidwinterWindow.startDay)) → \(monthDayLabel(for: thermalMidwinterWindow.endDay))"
                        )
                    }
                    .font(.callout)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.black.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .chartXScale(domain: 1...365)
        .chartYScale(domain: annualTemperatureDomain)
        ///Add the cursor hover logic. Renders an invisible rectangle. Calls our complicated hover function from earlier
        ///but do not have to build it here so it saves space.
        .chartOverlay { proxy in
            ChartHoverOverlay(
                proxy: proxy,
                onHover: { plotLocation in
                    guard let hoveredDay = proxy.value(atX: plotLocation.x, as: Int.self) else {
                        selectedClimatePoint = nil
                        return
                    }
                    
                    selectedClimatePoint = climatePoint(for: hoveredDay)
                    
                },
                onEnded: {
                    selectedClimatePoint = nil
                }
            )
        }
        /// Now have it label Jan 1 ... Dec 1, Dec 31
        .chartXAxis {
            AxisMarks(values: [1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 365]) { value in
                AxisGridLine()
                AxisTick()
                
                if let day = value.as(Int.self) {
                    switch day {
                    case 1:
                        AxisValueLabel("Jan 1")
                    case 32:
                        AxisValueLabel("Feb 1")
                    case 60:
                        AxisValueLabel("Mar 1")
                    case 91:
                        AxisValueLabel("Apr 1")
                    case 121:
                        AxisValueLabel("May 1")
                    case 152:
                        AxisValueLabel("Jun 1")
                    case 182:
                        AxisValueLabel("Jul 1")
                    case 213:
                        AxisValueLabel("Aug 1")
                    case 244:
                        AxisValueLabel("Sep 1")
                    case 274:
                        AxisValueLabel("Oct 1")
                    case 305:
                        AxisValueLabel("Nov 1")
                    case 335:
                        AxisValueLabel("Dec 1")
                    case 365:
                        AxisValueLabel("Dec 31")
                    default:
                        AxisValueLabel("")
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .stride(by: 10))
        }
        .chartXAxisLabel("Day of Year")
        .chartYAxisLabel("Temperature (°F)")
    }
    /// Add the seasonal hysteresis phase space with arrow seasonal progression
    private var seasonalHysteresisChart: some View {
        Chart {
            ///Adds the points themselves.
            ForEach(climatePoints) { point in
                LineMark(
                    x: .value("Normalized Solar", point.normalizedSolar),
                    y: .value("Normal Low", point.normalLow)
                )
                .foregroundStyle(.purple)
            }
            
            if let selectedClimatePoint {
                PointMark(
                    x: .value("Selected Normalized Solar", selectedClimatePoint.normalizedSolar),
                    y: .value("Selected Normal Low", selectedClimatePoint.normalLow)
                )
                .foregroundStyle(.orange)
                .symbolSize(90)
                .annotation(
                    position: selectedClimatePoint.normalizedSolar >= 0.65 ? .leading : .trailing,
                    alignment: .center
                ) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(monthDayLabel(for: selectedClimatePoint.dayOfYear))
                            .font(.headline)
                        Text("Day \(selectedClimatePoint.dayOfYear)")
                            .foregroundStyle(.secondary)
                        
                        Divider()
                        ///Will display the big four: T min, T max, S(t) and s(t)
                        Text("T_min: \(selectedClimatePoint.normalLow, specifier: "%.1f") °F")
                        Text("T_max: \(selectedClimatePoint.normalHigh, specifier: "%.1f") °F")
                        Text("Solar: \(selectedClimatePoint.solarEnergy, specifier: "%.2f") kWh/m²/day")
                        Text("s(t): \(selectedClimatePoint.normalizedSolar, specifier: "%.3f")")
                    }
                    .font(.callout)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.black.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            
            ///Adds the green arrows
            ForEach(hysteresisArrowPoints) { point in
                PointMark(
                    x: .value("Normalized Solar", point.normalizedSolar),
                    y: .value("Normal Low", point.normalLow)
                )
                .foregroundStyle(.clear)
                .annotation(position: .overlay) {
                    Text("➤")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                        .rotationEffect(hysteresisArrowAngle(for: point.dayOfYear))
                }
            }
            PointMark(
                x: .value("Normalized Solar", -0.12),
                y: .value("Normal Low", hysteresisTemperatureDomain.upperBound)
            )
            .foregroundStyle(.clear)
            .annotation(position: .bottomTrailing, alignment: .leading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Seasonal Memory Index")
                        .font(.headline)
                    
                    Text("SMI = \(seasonalMemoryIndex, specifier: "%.1f") °F")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("∮ Tₘᵢₙ ds")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    Divider()
                    /// Adds the peakNormalLowPoint function to do the obvious.
                    
                    if let peak = peakNormalLowPoint {
                        Text("Peak Normal Low: \(peak.normalLow, specifier: "%.1f") °F")
                            .font(.body)
                        Text("at s = \(peak.normalizedSolar, specifier: "%.2f") (\(monthDayLabel(for: peak.dayOfYear)))")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let chord = maximumEigendateChord {
                        Divider()
                        
                        Text("Maximum Eigendate Chord Depth")
                            .font(.body)
                            .fontWeight(.semibold)
                        
                        Text("MECD = \(chord.depth, specifier: "%.1f") °F")
                            .font(.body)
                        
                        Text("s = \(chord.normalizedSolar, specifier: "%.2f")")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        
                        Text("\(monthDayLabel(for: chord.coolBranchDay)) ↔ \(monthDayLabel(for: chord.warmBranchDay))")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .background(.black.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .chartXScale(domain: -0.1...1.1)
        .chartYScale(domain: hysteresisTemperatureDomain)
        .chartOverlay { proxy in
            ChartHoverOverlay(
                proxy: proxy,
                onHover: { plotLocation in
                    ///Given this mouse location in pixels, can you translate it into real chart values? So T min & s(t)
                    ///plotLocation.x and plotLocation.y are pixel-ish coordinates inside the plot area
                    ///they are not climate values yet
                    ///so proxy.value(atX: plotLocation.x...) means, at this x-pos in the plot, what x-axis value does the chart represent?
                    ///so in one way it is a mapping from pixel space to function space.
                    ///
                    ///The guard basically says If I can successfully get hoveredSolar AND hoveredNormalLow, continue.
                    ///Otherwise: clear selectedClimatePOint and exit this hover update.
                    ///charts might fail to convert if the pointer is outside the plot area, if the cahrt has not laid itself out yet, or
                    ///if the axis type does not match what we had asked for
                    guard let hoveredSolar = proxy.value(atX: plotLocation.x, as: Double.self),
                          let hoveredNormalLow = proxy.value(atY: plotLocation.y, as: Double.self) else {
                        selectedClimatePoint = nil
                        return
                    }
                    
                    selectedClimatePoint = hysteresisPoint(
                        closestToNormalizedSolar: hoveredSolar,
                        normalLow: hoveredNormalLow
                    )
                },
                onEnded: {
                    selectedClimatePoint = nil
                }
            )
        }
        /// Make it so that the Y axis goes from base 10 below the minimum temp and above the max temp.
        .chartYAxis {
            AxisMarks(values: .stride(by: 10))
        }
        .chartXAxis {
            AxisMarks(values: Array(stride(from: 0.0, through: 1.0, by: 0.2)))
        }
        
        .chartXAxisLabel("Normalized Solar")
        .chartYAxisLabel("Normal Low (°F)")
    }
    ///weather for the year
    private var weatherForTheYearPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weather for the Year")
                .font(.headline)
            HStack(spacing: 10) {
                Text("Year")
                    .fontWeight(.semibold)
                
                Picker("Year", selection: $selectedWeatherYear) {
                    ForEach(weatherYearOptions, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .labelsHidden()
                .frame(width: 120)
            }

            Text("Loaded \(weatherYearDays.count) weather-year days.")

            if let recordInfo = weatherYearRecordInfo {
                Text("Record sample: \(recordInfo.rowCount) ACIS rows across \(recordInfo.representedYearCount) years.")
            }
            
            HStack(spacing: 10) {
                Text("Overlays")
                    .fontWeight(.semibold)
                
                ForEach(WeatherYearOverlay.allCases) { overlay in
                    let isSelected = selectedWeatherYearOverlays.contains(overlay)
                    
                    Button {
                        toggleWeatherYearOverlay(overlay)
                    } label: {
                        Text(overlay.title)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.blue.opacity(0.45) : Color.gray.opacity(0.22))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text("Selected overlays: \(selectedWeatherYearOverlays.map { $0.title }.sorted().joined(separator: ", "))")

            if weatherYearDays.isEmpty {
                Text("Weather-year data is loading...")
                    .foregroundStyle(.secondary)
            } else {
                weatherYearChart
            }
        }
        .onChange(of: selectedWeatherYear) {
            recalculateWeatherYearDays()
        }
    }
    ///year option
    private var weatherYearOptions: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((1991...currentYear).reversed())
    }
    
    ///nearest-day helper. rounds the date is it lands on a non-integer value.
    private func weatherYearDay(closestTo hoveredDate: Date) -> WeatherYearDay? {
        guard weatherYearDays.isEmpty == false else {
            return nil
        }
        
        return weatherYearDays.min { first, second in
            abs(first.date.timeIntervalSince(hoveredDate)) < abs(second.date.timeIntervalSince(hoveredDate))
        }
    }
    
    ///temperature formatter helper. Keeps partial years like the current year where future observed values are missing.
    private func weatherYearTemperatureText(_ value: Double?) -> String {
        guard let value else {
            return "n/a"
        }
        
        return "\(value.formatted(.number.precision(.fractionLength(0))))°F"
    }
    
    private var weatherYearChart: some View {
        Chart {
            ///Normal T max & T min
            if selectedWeatherYearOverlays.contains(.normalRange) {
                ForEach(weatherYearDays) { day in
                    AreaMark(
                        x: .value("Date", day.date),
                        yStart: .value("Normal Low", day.normalLow),
                        yEnd: .value("Normal High", day.normalHigh)
                    )
                    .foregroundStyle(Color.yellow.opacity(0.22))
                }
            }
            ///Observed highs/lows in blue
            if selectedWeatherYearOverlays.contains(.observedRange) {
                ForEach(weatherYearDays) { day in
                    if let minimum = day.selectedYearMinimum,
                       let maximum = day.selectedYearMaximum {
                        RuleMark(
                            x: .value("Date", day.date),
                            yStart: .value("Observed Low", minimum),
                            yEnd: .value("Observed High", maximum)
                        )
                        .foregroundStyle(Color.blue.opacity(0.65))
                        .lineStyle(StrokeStyle(lineWidth: 1.4))
                    }
                }
            }
            ///record low minimum/abs min
            if selectedWeatherYearOverlays.contains(.recordLowMinimum) {
                ForEach(weatherYearDays) { day in
                    if let recordLow = day.recordLowMinimum {
                        LineMark(
                            x: .value("Date", day.date),
                            y: .value("Record Low", recordLow),
                            series: .value("Series", "Record Low")
                        )
                        .foregroundStyle(Color.cyan)
                    }
                }
            }
            
            ///record high max/ abs hot
            if selectedWeatherYearOverlays.contains(.recordHighMaximum) {
                ForEach(weatherYearDays) { day in
                    if let recordHigh = day.recordHighMaximum {
                        LineMark(
                            x: .value("Date", day.date),
                            y: .value("Record High", recordHigh),
                            series: .value("Series", "Record high")
                        )
                        .foregroundStyle(Color.red)
                    }
                }
            }
            ///record warm minimum/warmest morning. Important for heat stress. thermal midsommar.
            if selectedWeatherYearOverlays.contains(.recordWarmMinimum) {
                ForEach(weatherYearDays) { day in
                    if let recordWarmLow = day.recordWarmMinimum {
                        LineMark(
                            x: .value("Date", day.date),
                            y: .value("Record Warm Low", recordWarmLow),
                            series: .value("Series", "Record Warm Low")
                        )
                        .foregroundStyle(Color.orange.opacity(0.9))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                }
            }
            ///record cool maximum. Answers questions like, how cool can an afternoon be in July?
            if selectedWeatherYearOverlays.contains(.recordCoolMaximum) {
                ForEach(weatherYearDays) { day in
                    if let recordCoolHigh = day.recordCoolMaximum {
                        LineMark(
                            x: .value("Date", day.date),
                            y: .value("Record Cool High", recordCoolHigh),
                            series: .value("Series", "Record Cool High")
                        )
                        .foregroundStyle(Color.pink.opacity(0.9))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                }
            }
            
            ///hover mouse logic here:
            if let selectedWeatherYearDay {
                RuleMark(
                    x: .value("Selected Date", selectedWeatherYearDay.date)
                )
                .foregroundStyle(Color.white.opacity(0.55))
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                PointMark(
                    x: .value("Selected Date", selectedWeatherYearDay.date),
                    y: .value("Normal High", selectedWeatherYearDay.normalHigh)
                    ///Points out the normal high on the y-axis
                )
                .foregroundStyle(Color.white)
                .symbolSize(60)
                .annotation(
                    position: selectedWeatherYearDay.dayOfYear >= 300 ? .leading : .trailing,
                    alignment:  .center
                ) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedWeatherYearDay.date, format: .dateTime.month(.abbreviated).day())
                            .font(.headline)
                        
                        Divider()
                        ///Observed High and obs low in deg F. Toggle-able
                        if selectedWeatherYearOverlays.contains(.observedRange) {
                            Text("Obs High: \(weatherYearTemperatureText(selectedWeatherYearDay.selectedYearMaximum))")
                            Text("Obs Low: \(weatherYearTemperatureText(selectedWeatherYearDay.selectedYearMinimum))")
                        }
                        
                       
                        
                        ///Normal High "Afternoon high"
                        if selectedWeatherYearOverlays.contains(.normalRange) {
                            Text("Normal High: \(weatherYearTemperatureText(selectedWeatherYearDay.normalHigh))")
                            Text("Normal Low: \(weatherYearTemperatureText(selectedWeatherYearDay.normalLow))")
                        }
                       
                        
                        
                        ///Record High or "absolute high". Hottest day all time
                        if selectedWeatherYearOverlays.contains(.recordHighMaximum) {
                            Text("Record High: \(weatherYearTemperatureText(selectedWeatherYearDay.recordHighMaximum))")
                        }
                        ///Record cool high or "coolest afternoon" for a specific date
                        if selectedWeatherYearOverlays.contains(.recordCoolMaximum) {
                            Text("Record Cool High: \(weatherYearTemperatureText(selectedWeatherYearDay.recordCoolMaximum))")
                        }
                        ///Record Warm Minimum or "Hot mornings"
                        if selectedWeatherYearOverlays.contains(.recordWarmMinimum) {
                            Text("Record Warm Low: \(weatherYearTemperatureText(selectedWeatherYearDay.recordWarmMinimum))")
                        }
                        
                        ///Absolute minimum or coldest temp all time.
                        if selectedWeatherYearOverlays.contains(.recordLowMinimum) {
                            Text("Record Low: \(weatherYearTemperatureText(selectedWeatherYearDay.recordLowMinimum))")
                        }
                    }
                    ///Formatting the hover box itself
                    .font(.caption)
                    .padding(10)
                    .background(Color.black.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        
       
        ///Chart overlay . Gives us the mouse position inside the plot area. proxy.value(atX:as:) converts the cursor's x position back
        ///into a Date. Then weatherYearDay(closestTo:) clamps it to the nearest real calendar date. Allows user
        ///to select only the climate data they need, such as normal low, record warm minimum, etc.
        
        .chartOverlay { proxy in
            ChartHoverOverlay(
                proxy: proxy,
                onHover: { plotLocation in
                    guard let hoveredDate = proxy.value(atX: plotLocation.x, as: Date.self) else {
                        selectedWeatherYearDay = nil
                        return
                    }
                    
                    selectedWeatherYearDay = weatherYearDay(closestTo: hoveredDate)
                },
                onEnded: {
                    selectedWeatherYearDay = nil
                }
            )
        }
        
        ///Chooses the correct domain.
        .chartYScale(domain: weatherYearTemperatureDomain)
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) {
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .stride(by: 10))
        }
        .frame(height: 420)
    }
    
    private var weatherYearTemperatureDomain: ClosedRange<Double> {
        let values = weatherYearDays.flatMap { day in
            [
                day.selectedYearMinimum,
                day.selectedYearMaximum,
                Optional(day.normalLow),
                Optional(day.normalHigh),
                day.recordLowMinimum,
                day.recordHighMaximum,
                day.recordWarmMinimum,
                day.recordCoolMaximum
            ].compactMap { $0 }
        }
        
        guard let minimum = values.min(),
              let maximum = values.max() else {
            return 0...120
        }
        
        let lowerBound = floor((minimum - 5) / 10) * 10
        let upperBound = ceil((maximum + 5) / 10) * 10
        
        return lowerBound...upperBound
    }
}
