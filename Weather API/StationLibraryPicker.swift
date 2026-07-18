/// Create a reusable searchable/scroller control.
///
import Foundation
import SwiftUI

struct StationLibraryPicker: View {
    
    /// Lets this view chage ContentView's existing selectedLocation. It does not create a
    /// competing selection.
    @Binding var selection: WeatherLocation
    
    let locations: [WeatherLocation]
    
    /// Stores temporary UI details - the open popover and search query
    @State private var isPresented = false
    @State private var searchText = ""
    
    /// searches both names and IDs
    private var filteredLocations: [WeatherLocation] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !query.isEmpty else {
            return locations
        }
        
        return locations.filter { location in
            location.name.localizedCaseInsensitiveContains(query)
            || location.displayStationID.localizedCaseInsensitiveContains(query)
        }
    }
    
    private var listSelection: Binding<String?> {
        Binding(
            get: {
                selection.id
            },
            set: { newLocationID in
                guard
                    let newLocationID,
                    let newLocation = locations.first(where: {
                        $0.id == newLocationID
                    })
                else {
                    return
                }
                
                selection = newLocation
                isPresented = false
            }
        )
    }
    
    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            HStack(spacing: 8) {
                Text(selection.name)
                    .lineLimit(1)
                
                Spacer(minLength: 8)
                
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(DashboardTheme.textSecondary)
            }
            .foregroundStyle(DashboardTheme.textPrimary)
            .padding(.horizontal, 10)
            .frame(
                width: 470,
                height: 32
            )
            .background {
                RoundedRectangle(
                    cornerRadius: 8,
                    style: .continuous
                )
                .fill(DashboardTheme.panelElevated)
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: 8,
                    style: .continuous
                )
                .stroke(DashboardTheme.border)
            }
                
        }
        .buttonStyle(.plain)
        .popover(
            isPresented: $isPresented,
            arrowEdge: .top
        ) {
            VStack(spacing: 12) {
                TextField(
                    "Search stations or IDs",
                    text: $searchText
                )
                .textFieldStyle(.roundedBorder)
                
                List(
                    selection: listSelection
                ) {
                    ForEach(filteredLocations) { location in
                        HStack {
                            Text(location.name)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text(location.displayStationID)
                                .foregroundStyle(DashboardTheme.textSecondary)
                        }
                        .padding(.vertical, 3)
                        .tag(location.id)
                    }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
            }
            .padding(12)
            .frame(
                width: 440,
                height: 500
            )
            .background(DashboardTheme.panel)
        }
    }
}
