/// Gives the user options to adjust the live Climate atlas, such as icon size and what
/// meteorological variable is being displayed
///

/// The live measurement displayed over each Atlas station.
///
import Foundation
import SwiftUI

enum AtlasMapMetric: String, CaseIterable, Identifiable, Hashable {
    case temperature = "Temperature"
    case dewPoint = "Dew Point"
    
    var id: Self {
        self
    }
}

/// The visual size of each station annotation.
enum AtlasAnnotationSize: String, CaseIterable, Identifiable, Hashable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    
    var id: Self {
        self
    }
    
    var scale: CGFloat {
        switch self {
        case .small:
            return 0.80
        case .medium:
            return 1.10
        case .large:
            return 1.40
        }
    }
}

struct AtlasMapOptionsView: View {
    @Binding var displayedMetric: AtlasMapMetric
    @Binding var annotationSize: AtlasAnnotationSize
    
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
                        Text(metric.rawValue)
                            .tag(metric)
                    }
                }
                .pickerStyle(.segmented)
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
        }
        .padding(16)
        .frame(width: 300)
        .foregroundStyle(DashboardTheme.textPrimary)
        .background(DashboardTheme.panel)
    }
}
