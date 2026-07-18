import SwiftUI

/// The compact live-temperature label drawn over one station.
///

struct AtlasTemperatureAnnotationView: View {
    let observation: AtlasObservation
    let displayedMetric: AtlasMapMetric
    let annotationSize: AtlasAnnotationSize
    
    private var displayedValue: Double? {
        switch displayedMetric {
        case .temperature:
            return observation.temperatureFahrenheit
        case .dewPoint:
            return observation.dewPointFahrenheit
        }
    }
    
    private var displayedText: String {
        guard let displayedValue else {
            return "-"
        }
        
        return "\(Int(displayedValue.rounded()))"
    }
    
    private var accessibilityValue: String {
        guard let displayedValue else {
            return "\(displayedMetric.rawValue) unavailable"
        }
        
        return "\(displayedMetric.rawValue), \(Int(displayedValue.rounded())) °F"
    }
    
    /// Color-coded temperatures. Cold temperatures should look 'cold'. Hot temperatures
    /// should look 'hot'
    private var displayedValueColor: Color {
        guard let displayedValue else {
            return DashboardTheme.textSecondary
        }
        
        switch displayedValue {
            
        case ..<0:
            return Color(
                red: 0.72,
                green: 0.45,
                blue: 1.00
            )
            
        case 0..<20:
            return Color(
                red: 0.48,
                green: 0.52,
                blue: 1.00
            )
            
        case 20..<32:
            return Color(
                red: 0.25,
                green: 0.58,
                blue: 1.00
            )
            
        case 32..<50:
            return Color(
                red: 0.20,
                green: 0.82,
                blue: 1.00
            )
            
        case 50..<60:
            return Color(
                red: 0.20,
                green: 0.82,
                blue: 1.00
            )
            
        case 60..<70:
            return Color(
                red: 0.45,
                green: 0.88,
                blue: 0.35
            )
            
        case 70..<80:
            return Color(
                red: 0.96,
                green: 0.78,
                blue: 0.20
            )
            
        case 80..<90:
            return Color(
                red: 1.00,
                green: 0.52,
                blue: 0.14
            )
            
        case 90..<100:
            return Color(
                red: 1.00,
                green: 0.25,
                blue: 0.12
            )
            
        case 100..<110:
            return Color(
                red: 1.00,
                green: 0.14,
                blue: 0.10
            )
            
        default:
            return Color(
                red: 1.00,
                green: 0.12,
                blue: 0.35
            )
        }
    }
    
    var body: some View {
        Text(displayedText)
            .font(
                .system(
                    size: 14 * annotationSize.scale,
                    weight: .bold,
                    design: .rounded
                )
            )
            .monospacedDigit()
            .foregroundStyle(displayedValueColor)
            .padding(.horizontal, 5 * annotationSize.scale)
            .padding(.vertical, 2 * annotationSize.scale)
            .background(
                Color.black.opacity(0.72),
                in: RoundedRectangle(cornerRadius: 5 * annotationSize.scale)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 5 * annotationSize.scale)
                .stroke(
                    Color.white.opacity(0.22),
                    lineWidth: 0.75
                )
            }
            .shadow(
                color: Color.black.opacity(0.85),
                radius: 2 * annotationSize.scale,
                x: 0,
                y: 1
            )
            .accessibilityLabel(
                "\(observation.station.name), \(accessibilityValue)"
            )
    }
}
