import Foundation
import SwiftUI

struct ForecastNormalComparisonView: View {
    let comparison: ForecastNormalComparison?
    
    let timeZone: TimeZone
    
    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            HStack {
                Text("Almanac")
                    .font(.headline)
                
                Spacer()
                
                Text(dateLabel)
                    .font(.caption2.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(DashboardTheme.textSecondary)
            }
            
            HStack(spacing: 8) {
                departurePanel(
                    title: "HIGH",
                    symbol: "thermometer.high",
                    forecast: comparison?.forecastHighFahrenheit,
                    normal: comparison?.normalHighFahrenheit,
                    zScore: comparison?.highZScore
                )
                
                departurePanel(
                    title: "LOW",
                    symbol: "thermometer.low",
                    forecast: comparison?.forecastLowFahrenheit,
                    normal: comparison?.normalLowFahrenheit,
                    zScore: comparison?.lowZScore
                )
                
            }
        }
    }
    
    fileprivate var dateLabel: String {
        guard let comparison else {
            return "NEXT COMPLETE DAY"
        }
        
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = "MMM d"
        
        return formatter
            .string(from: comparison.localDate)
            .uppercased()
    }
    
    fileprivate func departurePanel(
        title: String,
        symbol: String,
        forecast: Double?,
        normal: Double?,
        zScore: Double?
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 5
        ) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(
                        .system(size: 11, weight: .semibold)
                    )
                
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(DashboardTheme.textSecondary)
            
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Forecast")
                        .font(.caption2)
                        .foregroundStyle(DashboardTheme.textSecondary)

                    Text(temperatureText(forecast))
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Normal")
                        .font(.caption2)
                        .foregroundStyle(DashboardTheme.textSecondary)

                    Text(temperatureText(normal))
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Text(
                zScoreText(zScore)
            )
            .font(.caption2.weight(.semibold))
            .foregroundStyle(zScoreColor(zScore))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background {
                Capsule()
                    .fill(
                        zScoreColor(zScore).opacity(0.12)
                    )
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(10)
        .background {
            RoundedRectangle(
                cornerRadius: 8,
                style: .continuous
            )
            .fill(Color.white.opacity(0.035))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(DashboardTheme.border, lineWidth: 1)
        }
    }
    
    fileprivate func temperatureText(
        _ value: Double?
    ) -> String {
        guard let value else {
            return "-"
        }
        
        return String(
            format: "%.1f°F",
            value
        )
    }
    
    fileprivate func zScoreText(
        _ zScore: Double?
    ) -> String {
        guard let zScore,
              zScore.isFinite == true else {
            return "σ unavailable"
        }
        
        if abs(zScore) < 0.05 {
            return "0.0σ near normal"
        }
        
        let description =
        zScore > 0.0
        ? "warmer"
        : "cooler"
        
        return
            String(
                format: "%.1fσ",
                zScore
            )
        + " "
        + description
    }
    
    fileprivate func zScoreColor(
        _ zScore: Double?
    ) -> Color {
        guard let zScore,
              zScore.isFinite == true else {
            return DashboardTheme.textSecondary
        }
        
        if zScore > 0.05 {
            return DashboardTheme.normal
        }
        
        if zScore < 0.05 {
            return DashboardTheme.forecastTemperature
        }
        
        return DashboardTheme.textSecondary
    }
}
