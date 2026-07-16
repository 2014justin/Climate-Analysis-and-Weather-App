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
}

struct AppSectionPicker: View {
    /// Binding means this picker does now own the selection. It receives a two-way connection to the
    /// selection owned by ContentView. When the picker changes it, ContentView sees the change immediately
    @Binding var selection: AppSection
    
    var body: some View {
        Picker("App section", selection: $selection) {
            ForEach(AppSection.allCases) { section in
                Text(section.rawValue)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: 220)
    }
}
