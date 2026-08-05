import Foundation
import SwiftUI

struct ThermalGaugeView: View {
    let scale: ThermalGaugeScale
    
    let airTemperature: Double?
    let heatIndex: Double?
    let wetBulb: Double?
    let dewPoint: Double?
    let conditionDescription: String
    let windSpeed: Double?
    let pressure: Double?
    
    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    gaugeRing(
                        value: airTemperature,
                        color: DashboardTheme.observedTemperature,
                        inset: 0.0,
                        lineWidth: 11.0
                    )
                    
                    gaugeRing(
                        value: heatIndex,
                        color: DashboardTheme.heatIndex,
                        inset: 17.0,
                        lineWidth: 9.0
                    )
                    
                    gaugeRing(
                        value: wetBulb,
                        color: DashboardTheme.wetBulb,
                        inset: 32.0,
                        lineWidth: 8.0
                    )
                    
                    gaugeRing(
                        value: dewPoint,
                        color: DashboardTheme.dewPoint,
                        inset: 46.0,
                        lineWidth: 7.0
                    )
                    
                    ThermalGaugeScaleMarks(scale: scale)
                    
                    VStack(spacing: 2) {
                        HStack(spacing: 7) {
                            Image(systemName: "thermometer.medium")
                                .font(
                                    .system(
                                        size: 25,
                                        weight: .medium
                                    )
                                )
                                .foregroundStyle(DashboardTheme.observedTemperature)
                            
                            Text(
                                airTemperature.map {
                                    String(
                                        format: "%.1f°F",
                                        $0
                                    )
                                } ?? "-"
                            )
                            .font(.title2.weight(.semibold))
                            .monospacedDigit()
                        }
                        
                        
                        
                        Text("AIR TEMPERATURE")
                            .font(.caption2.weight(.semibold))
                            .tracking(0.8)
                            .foregroundStyle(
                                DashboardTheme.textSecondary
                            )
                    }
                    .padding(.bottom, 8)
                }
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height,
                    alignment: .bottom
                )
            }
            .frame(height: 170)
            
            HStack {
                Text(
                    String(
                        format: "%.0f°F",
                        scale.lowerBoundFahrenheit
                    )
                )
                
                Spacer()
                
                Text(
                    String(
                        format: "%.0f°F",
                        scale.upperBoundFahrenheit
                    )
                )
            }
            .font(.caption.weight(.medium))
            .monospacedDigit()
            .foregroundStyle(
                DashboardTheme.textSecondary
            )
            
            HStack(spacing: 6) {
                supportingMeasurement(
                    symbol: "thermometer.high",
                    title: "Heat Index",
                    value: heatIndex,
                    color: DashboardTheme.heatIndex
                )
                
                supportingMeasurement(
                    symbol: "drop.degreesign",
                    title: "Wet Bulb",
                    value: wetBulb,
                    color: DashboardTheme.wetBulb
                )
                
                supportingMeasurement(
                    symbol: "drop.fill",
                    title: "Dew Point",
                    value: dewPoint,
                    color: DashboardTheme.dewPoint
                )
            }
            HStack(spacing: 6) {
                atmosphericMeasurement(
                    symbol: conditionSymbol,
                    title: "Conditions",
                    value: conditionDescription
                )
                
                atmosphericMeasurement(
                    symbol: "wind",
                    title: "Wind",
                    value:
                        windSpeed.map {
                            String(
                                format: "%.1f mph",
                                $0
                            )
                        } ?? "—"
                )
                
                atmosphericMeasurement(
                    symbol: "barometer",
                    title: "Pressure",
                    value:
                        pressure.map {
                            String(
                                format: "%.2f inHg",
                                $0
                            )
                        } ?? "—"
                )
            }
        }
    }
    
    fileprivate var conditionSymbol: String {
        let condition =
            conditionDescription.lowercased()
        
        if condition.contains("thunder")
            || condition.contains("lightning") {
            return "cloud.bolt.rain.fill"
        }
        
        if condition.contains("snow")
            || condition.contains("flurr")
            || condition.contains("blizzard") {
            return "cloud.snow.fill"
        }
        
        if condition.contains("rain")
            || condition.contains("shower")
            || condition.contains("drizzle") {
            return "cloud.rain.fill"
        }
        
        if condition.contains("fog")
            || condition.contains("mist")
            || condition.contains("haze")
            || condition.contains("smoke") {
            return "cloud.fog.fill"
        }
        
        if condition.contains("partly")
            || condition.contains("mostly cloudy") {
            return "cloud.sun.fill"
        }
        
        if condition.contains("cloud")
            || condition.contains("overcast") {
            return "cloud.fill"
        }
        
        if condition.contains("clear")
            || condition.contains("sunny") {
            return "sun.max.fill"
        }
        
        return "cloud.sun.fill"
    }
    
    fileprivate func atmosphericMeasurement(
        symbol: String,
        title: String,
        value: String
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 4
        ) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(
                        .system(
                            size: 11,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        DashboardTheme.forecastTemperature
                    )
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(
                        DashboardTheme.textSecondary
                    )
            }
            
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(
                cornerRadius: 7,
                style: .continuous
            )
            .fill(
                Color.white.opacity(0.035)
            )
        }
    }
    
    fileprivate func supportingMeasurement(
        symbol: String,
        title: String,
        value: Double?,
        color: Color
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 4
        ) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(
                        .system(size:11, weight: .semibold)
                    )
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .foregroundStyle(DashboardTheme.textSecondary)
            }
            Text(
                value.map {
                    String(
                        format: "%.1f°F",
                        $0
                    )
                } ?? "-"
            )
            .font(.subheadline.weight(.semibold))
            .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(
                cornerRadius: 7,
                style: .continuous
            )
            .fill(Color.white.opacity(0.035))
        }
    }
    
    @ViewBuilder
    fileprivate func gaugeRing(
        value: Double?,
        color: Color,
        inset: CGFloat,
        lineWidth: CGFloat
    ) -> some View {
        let placement =
            scale.placement(
                for: value
            )
        
        ZStack {
            ThermalGaugeArc(
                progress: 1.0
            )
            .stroke(
                Color.white.opacity(0.08),
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round
                )
            )
            
            if let placement {
                ThermalGaugeArc(
                    progress: placement.progress
                )
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .animation(
                    .easeInOut(duration: 0.35),
                    value: placement.progress
                )
            }
        }
        .padding(
            .horizontal,
            inset
        )
    }
}
