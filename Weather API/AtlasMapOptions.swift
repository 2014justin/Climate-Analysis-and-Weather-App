/// Gives the user options to adjust the live Climate atlas, such as icon size and what
/// meteorological variable is being displayed
///

/// The live measurement displayed over each Atlas station.
///
import Foundation
import SwiftUI

/// Selects whether Atlas anotations display current observations or values from the shared forecast timeline.
nonisolated enum AtlasWeatherLayer: String, CaseIterable, Identifiable, Hashable, Sendable {
    case observations = "Live"
    case forecast = "Forecast"
    
    var id: Self { self }
}

nonisolated enum AtlasMapMetric: String, CaseIterable, Identifiable, Hashable, Sendable {
    case temperature = "Temperature"
    case dewPoint = "Dew Point"
    case rolling24HourMaximum = "24h Daily Maximum"
    case rolling24HourMinimum = "24h Daily Minimum"
    
    var id: Self {
        self
    }
    
    var systemImage: String {
        switch self {
        case .temperature:
            return "thermometer.medium"
            
        case .dewPoint:
            return "drop.fill"
            
        case .rolling24HourMaximum:
            return "arrow.up.circle"
            
        case .rolling24HourMinimum:
            return "arrow.down.circle"
        }
    }
}

/// The visual size of each station annotation.
nonisolated enum AtlasAnnotationSize: String, CaseIterable, Identifiable, Hashable, Sendable {
    case medium = "Medium"
    case mediumPlus = "Medium +"
    case large = "Large"
    
    var id: Self {
        self
    }
    
    var scale: CGFloat {
        switch self {
        case .medium:
            return 1.10
        case .mediumPlus:
            return 1.28
        case .large:
            return 1.52
        }
    }
}

struct AtlasMapOptionsView: View {
    @Binding var displayedMetric: AtlasMapMetric
    @Binding var annotationSize: AtlasAnnotationSize
    @Binding var showsSolarIllumination: Bool
    @Binding var showsWeatherGovAPIActivity: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Map Options")
                .font(.headline)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Displayed value")
                    .font(.caption)
                    .foregroundStyle(DashboardTheme.textSecondary)
                
                Picker(
                    "Displayed value",
                    selection: $displayedMetric
                ) {
                    ForEach(AtlasMapMetric.allCases) { metric in
                        Label(
                            metric.rawValue,
                            systemImage: metric.systemImage
                        )
                        .tag(metric)
                    }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Annotation size")
                    .font(.caption)
                    .foregroundStyle(DashboardTheme.textSecondary)
                
                Picker(
                    "Annotation size",
                    selection: $annotationSize
                ) {
                    ForEach(AtlasAnnotationSize.allCases) { size in
                        Text(size.rawValue)
                            .tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            
            Toggle(
                isOn: $showsWeatherGovAPIActivity
            ) {
                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {
                    Label(
                        "Show API Activity",
                        systemImage: "network"
                    )
                    .font(.subheadline
                        .weight(.semibold)
                    )
                    
                    Text(
                        "Display live Weather.gov request diagnostics"
                    )
                    .font(.caption)
                    .foregroundStyle(DashboardTheme.textSecondary)
                }
            }
            .toggleStyle(.switch)
            
            Divider()
            
            Toggle(
                isOn: $showsSolarIllumination
            ) {
                VStack(alignment: .leading, spacing: 3) {
                    Label(
                        "Day & Twilight",
                        systemImage: "sun.horizon"
                    )
                    .font(.subheadline.weight(.semibold))
                    
                    Text("Solar illumination and twilight bands")
                        .font(.caption)
                        .foregroundStyle(DashboardTheme.textSecondary)
                }
            }
            .toggleStyle(.switch)
        }
        .padding(16)
        .frame(width: 300)
        .foregroundStyle(DashboardTheme.textPrimary)
        .background(DashboardTheme.panel)
    }
}
