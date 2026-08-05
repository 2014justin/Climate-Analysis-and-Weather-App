import SwiftUI
/// Eventually add a dashboard and atlas toggle-able tab.
/// String supplies the visible button labels. CaseIterable creates [.dashboard, .atlas]
/// through allCases. Identifiable lets SwiftUI loop over those choices.
enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case dashboard = "Dashboard"
    case atlas = "Atlas"
    
    var id: Self {
        self
    }
    
    var systemImage: String {
        switch self {
        case .dashboard:
            return "display"
            
        case .atlas:
            return "map"
        }
    }
}

struct AppSectionPicker: View {
    /// Binding means this picker does now own the selection. It receives a two-way connection to the
    /// selection owned by ContentView. When the picker changes it, ContentView sees the change immediately
    @Binding var selection: AppSection
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(AppSection.allCases) { section in
                Button {
                    withAnimation(
                        .easeInOut(duration: 0.16)
                    ) {
                        selection = section
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: section.systemImage)
                            .font(
                                .system(
                                    size: 15,
                                    weight: .semibold
                                )
                            )
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(DashboardTheme.forecastTemperature)
                        
                        Text(section.rawValue)
                            .font(.headline)
                            .foregroundStyle(
                                selection == section
                                    ? Color.white
                                    : DashboardTheme.textPrimary
                            )
                    }
                    .frame(
                        width: section == .dashboard
                            ? 150
                            : 120
                    )
                    .padding(.vertical, 7)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background {
                    if selection == section {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(DashboardTheme.observedTemperature)
                    }
                }
                .help("Show \(section.rawValue)")
            }
        }
        .padding(3)
        .background(
            DashboardTheme.panelElevated,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DashboardTheme.border, lineWidth: 1)
        }
    }
}
 
