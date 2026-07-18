/// When the user clicks on a station, it should present a nice card that has
/// information like air temp, dew point, windspeed, and conditions (sunny, stormy)
/// At the bottom of the card should be a nice 'Build climate station' button that invites
/// the user to click it and add it to user-generated stations.
///
import SwiftUI
import Foundation

/// Add a cardScale that we can freely adjust later on to optimize size. Maybe later we add a slider to
/// the atlas options.
private let cardScale = CGFloat(sqrt(0.8))

struct AtlasStationCardView: View {
    let observation: AtlasObservation
    let onBuildClimateProfile: () -> Void
    
    
    
    /// Wires the existing sunrise data.
    @State private var sunTimes: SunTimes?
    @State private var sunTimeZone: TimeZone?
    @State private var didRequestSunTimes = false
    
    private var coordinateText: String {
        let station = observation.station
        
        let coordinates = String(
            format: "%.4f° %@ • %.4f° %@",
            abs(station.latitude),
            station.latitude >= 0 ? "N" : "S",
            abs(station.longitude),
            station.longitude >= 0 ? "E" : "W"
        )
        
        guard let elevationMeters = station.elevationMeters else {
            return coordinates
        }
        
        let elevationFeet = Measurement(
            value: elevationMeters,
            unit: UnitLength.meters
        )
            .converted(to: .feet)
            .value
        
        return "\(coordinates) | \(Int(elevationFeet.rounded())) ft"
    }
    
    /// Make the Canadian card safe.
    private var isUnitedStatesStation: Bool {
        observation.station.source.countryCode == "US"
    }
    
    private var stationID: String {
        observation.station.source.stationID
    }
    
    private var temperatureText: String {
        "\(Int(observation.temperatureFahrenheit.rounded()))°F"
    }
    
    private var dewPointText: String {
        guard let dewPoint = observation.dewPointFahrenheit else {
            return "Not reported"
        }
        
        return "\(Int(dewPoint.rounded()))°F"
    }
    
    /// Calculate heat index which we can display on the card.
    private var heatIndexText: String {
        guard let dewPoint =
                observation.dewPointFahrenheit else {
            return "—"
        }
        
        let relativeHumidity =
            WeatherMath.relativeHumidityPercent(
                temperatureFahrenheit: observation.temperatureFahrenheit,
                dewPointFahrenheit: dewPoint
            )
        
        let heatIndex =
            WeatherMath.heatIndexFahrenheit(
                temperature: observation.temperatureFahrenheit,
                relativeHumidity: relativeHumidity
            )
        
        return "\(Int(heatIndex.rounded())) °F"
    }
    
    private var windSpeedText: String {
        guard let windSpeed = observation.windSpeedMilesPerHour else {
            return "Not reported"
        }
        
        return "\(Int(windSpeed.rounded())) mph"
    }
    
    /// Converts common METAR abbreviations into more readable language.
    private var conditionText: String {
        guard let rawCondition =
                observation.conditionDescription?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !rawCondition.isEmpty
        else {
            return "Not reported"
        }
        
        let condition = rawCondition.uppercased()
        
        /// Thunderstorms
        if condition.contains("TS") {
            return "Thunderstorms"
        }
        
        /// Snow
        if condition.contains("SN") {
            return "Snow"
        }
        
        /// Rain
        if condition.contains("RA") {
            return "Rain"
        }
        
        /// Drizzle
        if condition.contains("DZ") {
            return "Drizzle"
        }
        
        /// Fog
        if condition.contains("FG") {
            return "Fog"
        }
        
        /// Haze
        if condition.contains("HZ") {
            return "Haze"
        }
        
        /// Translate codes to what the conditions actually are in more readable terms
        switch condition {
        case "CLR", "SKC", "CAVOK":
            return "Clear"
            
        case "FEW":
            return "Mostly clear"
            
        case "SCT":
            return "Partly cloudy"
            
        case "BKN":
            return "Mostly cloudy"
            
        case "OVC":
            return "Cloudy"
            
        default:
            return rawCondition
        }
    }
    
    
    /// Only loads suntimes as needed. Otherwise every time the graph would load all the US stations, the app would
    /// calculate sunrise/set times for every single one. That is unneccesary, as only the station card the users selects should display
    /// that information.
    
    @MainActor
    private func loadSunTimesIfNeeded() async {
        guard !didRequestSunTimes else {
            return
        }
        
        didRequestSunTimes = true
        
        do {
            guard let timeZone =
                    try await AtlasStationTimeZoneResolver()
                        .timeZone(
                            for: observation.station
                        )
            else {
                return
            }
            
            sunTimeZone = timeZone
            
            sunTimes = WeatherAlmanac.sunTimes(
                latitude: observation.station.latitude,
                longitude: observation.station.longitude,
                timeZone: timeZone
            )
        } catch {
            /// Sunrise and sunset are supplementary.
            /// A timezone failure should not break the station card.
        }
    }
    
    private func timeText(for date: Date?) -> String {
        guard let date,
              let sunTimeZone else {
            return "—"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = sunTimeZone
        
        return formatter.string(from: date)
    }
    
    /// Times for sunrise and sunset
    private var sunriseText: String {
        timeText(for: sunTimes?.sunrise)
    }
    
    private var sunsetText: String {
        timeText(for: sunTimes?.sunset)
    }
    
    /// honest UTC fallback.
    private var observationTimeText: String {
        if sunTimeZone != nil {
            return timeText(for: observation.observedAt)
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        return "\(formatter.string(from: observation.observedAt)) UTC"
    }
    
    private var cardHeader: some View {
        VStack(
            alignment: .leading,
            spacing: 4 * cardScale
        ) {
            Text(stationID)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(
                alignment: .firstTextBaseline,
                spacing: 8 * cardScale
            ) {
                Text(coordinateText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.80)
                
                Spacer(minLength: 8 * cardScale)
                
                Text("Observed \(observationTimeText)")
                    .fixedSize()
            }
            .font(.caption)
            .monospacedDigit()
            .foregroundStyle(DashboardTheme.textSecondary)
        }
    }
    
    /// Astronomy row or Sunrise & sunset.
    private func astronomyRow(
        symbol: String,
        title: String,
        value: String
    ) -> some View {
        HStack(spacing: 10 * cardScale) {
            Image(systemName: symbol)
                .font(.system(size: 25 * cardScale))
                .foregroundStyle(Color.blue.opacity(0.75))
                .frame(width: 32 * cardScale)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(DashboardTheme.textSecondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
        }
    }
    
    /// Hero weather. Displays temperature with symbols very prominently when user selects a station card.
    private var heroWeather: some View {
        HStack(spacing: 0) {
            HStack(spacing: 14 * cardScale) {
                Image(systemName: "thermometer.medium")
                    .font(
                        .system(size: 44 * cardScale)
                    )
                    .foregroundStyle(
                        Color.blue.opacity(0.75)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(temperatureText)
                        .font(
                            .system(
                                size: 46 * cardScale,
                                weight: .semibold,
                                design: .rounded
                            )
                        )
                        .monospacedDigit()

                    Text("Temperature")
                        .font(.subheadline)
                        .foregroundStyle(
                            DashboardTheme.textSecondary
                        )
                }
            }
            .padding(.trailing, 12 * cardScale)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )

            Divider()
                .frame(height: 90 * cardScale)

            VStack(
                alignment: .leading,
                spacing: 14 * cardScale
            ) {
                astronomyRow(
                    symbol: "sunrise",
                    title: "Sunrise",
                    value: sunriseText
                )

                astronomyRow(
                    symbol: "sunset",
                    title: "Sunset",
                    value: sunsetText
                )
            }
            .padding(.leading, 12 * cardScale)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
        .padding(.vertical, 4 * cardScale)
    }
    
    /// Supporting-metric helper:
    private func metricCell(
        symbol: String,
        title: String,
        value: String
    ) -> some View {
        HStack(spacing: 5 * cardScale) {
            Image(systemName: symbol)
                .font(
                    .system(size: 20 * cardScale)
                )
                .foregroundStyle(
                    Color.blue.opacity(0.75)
                )
                .frame(width: 22 * cardScale)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(
                        DashboardTheme.textSecondary
                    )

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .layoutPriority(1)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
    
    /// Three-cell strip:
    private var supportingMetrics: some View {
        HStack(spacing: 0) {
            metricCell(
                symbol: "drop",
                title: "Dew Point",
                value: dewPointText
            )
            .padding(.trailing, 6 * cardScale)

            Divider()
                .frame(height: 58 * cardScale)

            metricCell(
                symbol: "sun.max",
                title: "Heat Index",
                value: heatIndexText
            )
            .padding(.horizontal, 6 * cardScale)

            Divider()
                .frame(height: 58 * cardScale)

            metricCell(
                symbol: "wind",
                title: "Wind Speed",
                value: windSpeedText
            )
            .padding(.horizontal, 6 * cardScale)

            Divider()
                .frame(height: 58 * cardScale)

            metricCell(
                symbol: "cloud.sun",
                title: "Conditions",
                value: conditionText
            )
            .padding(.leading, 6 * cardScale)
        }
        .padding(.vertical, 4 * cardScale)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14 * cardScale) {
            cardHeader
            
            Divider()
            
            heroWeather
            
            Divider()
            
            supportingMetrics
            
            Button(
                action: onBuildClimateProfile
            ) {
                Text(
                    isUnitedStatesStation
                        ? "Build Climate Profile"
                        : "Climate Profile Coming Soon"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .controlSize(.large)
            .disabled(!isUnitedStatesStation)
            .padding(.top, 4)
        }
        .padding(18 * cardScale)
        .frame(width: 400 * cardScale)
        .foregroundStyle(DashboardTheme.textPrimary)
        .backgroundStyle(DashboardTheme.panelElevated)
        .task(id: stationID) {
            await loadSunTimesIfNeeded()
        }
    }
}
