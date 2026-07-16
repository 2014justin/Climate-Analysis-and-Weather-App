/// When the user clicks on a station, it should present a nice card that has
/// information like air temp, dew point, windspeed, and conditions (sunny, stormy)
/// At the bottom of the card should be a nice 'Build climate station' button that invites
/// the user to click it and add it to user-generated stations.
///
import SwiftUI
struct AtlasStationCardView: View {
    let observation: AtlasObservation
    let onBuildClimateProfile: () -> Void
    
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
    
    private func weatherRow(
        _ title: String,
        value: String
    ) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(DashboardTheme.textSecondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(observation.station.name)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    Text(stationID)
                    
                    Spacer()
                    
                    Text(
                        observation.observedAt.formatted(
                            date: .omitted,
                            time: .shortened
                        )
                    )
                }
                .font(.caption)
                .foregroundStyle(DashboardTheme.textSecondary)
            }
            
            Divider()
            
            VStack(spacing: 8) {
                weatherRow(
                    "Temperature",
                    value: temperatureText
                )
                
                weatherRow(
                    "Dew Point",
                    value: dewPointText
                )
                
                weatherRow(
                    "Wind Speed",
                    value: windSpeedText
                )
                
                weatherRow(
                    "Conditions",
                    value: conditionText
                )
            }
            
            Button(
                action: onBuildClimateProfile
            ) {
                Text("Build Climate Profile")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .controlSize(.large)
        }
        .padding(14)
        .frame(width: 275)
        .foregroundStyle(DashboardTheme.textPrimary)
        .background(DashboardTheme.panelElevated)
    }
}
