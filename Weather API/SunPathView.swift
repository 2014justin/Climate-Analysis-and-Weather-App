import SwiftUI
import Foundation

struct SunPathView: View {
    let latitude: Double
    let longitude: Double
    let timeZone: TimeZone
    
    
    
    fileprivate let sunColor = Color(
        red: 1.00,
        green: 0.67,
        blue: 0.08
    )
    
    var body: some View {
        TimelineView(
            .periodic(from: .now, by: 60)
        ) { context in
            let solarDayState = WeatherAlmanac.solarDayState(
                for: context.date,
                latitude: latitude,
                longitude: longitude,
                timeZone: timeZone
            )
            
            switch solarDayState {
            case .normal(let sunTimes):
                let progress = daylightProgress(
                    at: context.date,
                    sunTimes: sunTimes
                )
                
                VStack(spacing: 5) {
                    GeometryReader { proxy in
                        let centerX = proxy.size.width / 2
                        let baselineY = proxy.size.height - 4

                        let horizontalRadius = max(
                            centerX - 12,
                            0
                        )

                        let verticalRadius = max(
                            min(42, baselineY - 6),
                            0
                        )

                        let angle =
                            Double.pi * (1.0 - progress)

                        let sunX =
                            centerX + horizontalRadius * CGFloat(cos(angle))

                        let sunY =
                            baselineY - verticalRadius * CGFloat(sin(angle))
                        
                        ZStack {
                            Path { path in
                                for step in 0...48 {
                                    let fraction = Double(step) / 48.0
                                    
                                    let arcAngle = Double.pi * (1.00 - fraction)
                                    
                                    let x =
                                        centerX + horizontalRadius * CGFloat(cos(arcAngle))

                                    let y =
                                        baselineY - verticalRadius * CGFloat(sin(arcAngle))
                                    
                                    if step == 0 {
                                        path.move(
                                            to: CGPoint(x: x, y: y)
                                        )
                                    } else {
                                        path.addLine(
                                            to: CGPoint(x: x, y: y)
                                        )
                                    }
                                }
                            }
                            .stroke(
                                DashboardTheme.textSecondary.opacity(0.550),
                                style: StrokeStyle(
                                    lineWidth: 1.20,
                                    lineCap: .round,
                                    dash: [2, 4]
                                )
                            )
                            
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 17))
                                .foregroundStyle(sunColor)
                                .shadow(
                                    color: sunColor.opacity(0.350),
                                    radius: 5
                                )
                                .position(
                                    x: sunX,
                                    y: sunY
                                )
                                .opacity(
                                    isDaylight(
                                        context.date,
                                        sunTimes: sunTimes
                                    )
                                    ? 1
                                    : 0
                                )
                        }
                    }
                    .frame(height: 66)
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "sunrise.fill")
                                .foregroundStyle(sunColor)

                            Text(timeText(sunTimes.sunrise))
                        }

                        Spacer()

                        Text("Daylight Progress")
                            .foregroundStyle(
                                DashboardTheme.textSecondary
                            )

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "sunset.fill")
                                .foregroundStyle(sunColor)

                            Text(timeText(sunTimes.sunset))
                        }
                    }
                    .font(.caption2)
                    .monospacedDigit()
                }
            case .polarDay:
                polarStateView(
                    title: "Midnight Sun",
                    detail: "24 hours of daylight",
                    symbol: "sun.max.fill",
                    color: sunColor
                )
                
            case .polarNight:
                polarStateView(
                    title: "Polar Night",
                    detail: "Sun remains below the horizon",
                    symbol: "moon.stars.fill",
                    color: DashboardTheme.dayGlow
                )
            }
        }
    }
    
    
        
    fileprivate func daylightProgress(
        at date: Date,
        sunTimes: SunTimes
    ) -> Double {
        let daylightDuration =
            sunTimes.sunset.timeIntervalSince(sunTimes.sunrise)
        
        guard daylightDuration > 0 else {
            return 0
        }
        
        let elapsed = date.timeIntervalSince(sunTimes.sunrise)
        
        return min(
            max(elapsed / daylightDuration, 0), 1
        )
    }
        
    fileprivate func polarStateView(
        title: String,
        detail: String,
        symbol: String,
        color: Color
    ) -> some View {
        VStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 22))
                .foregroundStyle(color)
                .shadow(
                    color: color.opacity(0.30),
                    radius: 5
                )

            Text(title)
                .font(.caption.weight(.semibold))

            Text(detail)
                .font(.caption2)
                .foregroundStyle(
                    DashboardTheme.textSecondary
                )
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 85
        )
    }
    
    fileprivate func isDaylight(
        _ date: Date,
        sunTimes: SunTimes
    ) -> Bool {
        date >= sunTimes.sunrise && date <= sunTimes.sunset
    }
    
    fileprivate func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.timeZone = timeZone
        
        return formatter.string(from: date)
    }
}
