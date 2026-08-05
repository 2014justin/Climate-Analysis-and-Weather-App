import Foundation
import SwiftUI

/// Subtle ten-degree scale marks for the thermal gauge.
struct ThermalGaugeScaleMarks: View {
    let scale: ThermalGaugeScale
    
    private var tickValues: [Double] {
        let increment = 10.0
        
        let firstValue =
            ceil(
                scale.lowerBoundFahrenheit
                / increment
            ) * increment
        
        let lastValue =
            floor(
                scale.upperBoundFahrenheit
                / increment
            ) * increment
        
        guard firstValue <= lastValue else {
            return []
        }
        
        return Array(
            stride(
                from: firstValue,
                through: lastValue,
                by: increment
            )
        )
    }
    
    var body: some View {
        GeometryReader { geometry in
            let outerRadius =
                min(
                    geometry.size.width / 2.0,
                    geometry.size.height
                )
            
            let tickRadius =
                max(
                    outerRadius - 58.0,
                    0.0
                )
            
            let labelRadius =
                max(
                    outerRadius - 76.0,
                    0.0
                )
            
            let center = CGPoint(
                x: geometry.size.width / 2.0,
                y: geometry.size.height
            )
            
            ZStack {
                ForEach(
                    tickValues,
                    id: \.self
                ) { value in
                    if let placement =
                        scale.placement(
                            for: value
                        ) {
                        let rotation =
                            Angle.degrees(
                                placement.progress
                                * 180.0
                                - 90.0
                            )
                        
                        Capsule()
                            .fill(
                                Color.white.opacity(0.22)
                            )
                            .frame(
                                width: 1.25,
                                height: 7.0
                            )
                            .rotationEffect(rotation)
                            .position(
                                point(
                                    center: center,
                                    radius: tickRadius,
                                    progress:
                                        placement.progress
                                )
                            )
                        
                        if shouldShowLabel(value) {
                            Text(
                                String(
                                    format: "%.0f",
                                    value
                                )
                            )
                            .font(
                                .system(
                                    size: 8,
                                    weight: .semibold,
                                    design: .monospaced
                                )
                            )
                            .foregroundStyle(
                                DashboardTheme
                                    .textSecondary
                                    .opacity(0.62)
                            )
                            .rotationEffect(rotation)
                            .position(
                                point(
                                    center: center,
                                    radius: labelRadius,
                                    progress:
                                        placement.progress
                                )
                            )
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
    
    private func point(
        center: CGPoint,
        radius: CGFloat,
        progress: Double
    ) -> CGPoint {
        let angle =
            Double.pi
            * (1.0 - progress)
        
        return CGPoint(
            x:
                center.x
                + radius * CGFloat(cos(angle)),
            y:
                center.y
                - radius * CGFloat(sin(angle))
        )
    }
    
    /// Exact endpoints already have larger labels beneath the gauge.
    private func shouldShowLabel(
        _ value: Double
    ) -> Bool {
        let tolerance = 0.01
        
        return
            abs(
                value
                - scale.lowerBoundFahrenheit
            ) > tolerance
            &&
            abs(
                value
                - scale.upperBoundFahrenheit
            ) > tolerance
    }
}
