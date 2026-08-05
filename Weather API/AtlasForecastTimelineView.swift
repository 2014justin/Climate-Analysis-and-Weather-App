import SwiftUI
import Observation
import Foundation

/// Playback controls for the shared Atlas forecast timeline.
/// Moving the slider changes only in-memory selection state.
struct AtlasForecastTimelineView: View {
    @Bindable var controller: ForecastTimelineController
    
    fileprivate var sliderUpperBound: Double {
        Double(
            max(
                controller.availableInstants.count - 1,
                1
            )
        )
    }
    
    fileprivate var selectedIndexBinding:
    Binding<Double> {
        Binding(
            get: {
                Double(controller.selectedIndex ?? 0)
            },
            set: { newValue in
                controller.select(
                    index: Int(newValue.rounded())
                )
            }
        )
    }
    
    fileprivate var selectedHourText: String {
        guard let selectedIndex = controller.selectedIndex else {
            return "No forecast hour selected"
        }
        
        return "+\(selectedIndex)h"
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Forecast Timeline")
                    .font(.headline)
                
                Spacer()
                
                if let selectedInstant = controller.selectedInstant {
                    Text(
                        selectedInstant.formatted(date: .abbreviated, time: .shortened)
                    )
                    .font(.headline.monospacedDigit())
                } else {
                    Text("Waiting for forecast data")
                        .foregroundStyle(DashboardTheme.textSecondary)
                }
                
                Text(selectedHourText)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(DashboardTheme.forecastTemperature)
                    .frame(width: 64, alignment: .trailing)
            }
            
            HStack(spacing: 10) {
                Button {
                    controller.stepBackward()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.bordered)
                .disabled(controller.canStepBackward == false)
                .help("Previous forecast hour")
                
                Button {
                    controller.togglePlayback()
                } label: {
                    Image(
                        systemName:
                            controller.isPlaying
                                ? "pause.fill"
                                : "play.fill"
                    )
                    .frame(width: 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(DashboardTheme.observedTemperature)
                .disabled(controller.availableInstants.count < 2)
                .help(
                    controller.isPlaying
                        ? "Pause forecast"
                        : "Play forecast"
                )
                
                Button {
                    controller.stepForward()
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.bordered)
                .disabled(controller.canStepForward == false)
                .help("Next forecast hour")
                
                Slider(
                    value: selectedIndexBinding,
                    in: 0...sliderUpperBound,
                    step: 1
                )
                .tint(DashboardTheme.observedTemperature)
                .disabled(controller.availableInstants.count < 2)
                .accessibilityLabel("Forecast hour")
                .accessibilityValue(selectedHourText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            DashboardTheme.panel,
            in: RoundedRectangle(
                cornerRadius: DashboardTheme.cardCornerRadius,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: DashboardTheme.cardCornerRadius,
                style: .continuous
            )
            .stroke(
                DashboardTheme.border,
                lineWidth: 1
            )
        }
    }
}
