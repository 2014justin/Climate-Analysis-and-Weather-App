/// One swift file to explain every single climate chart.
///
import SwiftUI
import Foundation

enum ChartsHelpInfo {}

extension ChartsHelpInfo {
    
    /// Shared scrollable window used by every climate chart.
    struct Sheet<Content: View>: View {
        
        let title: String
        let subtitle: String
        
        private let content: Content
        
        @Environment(\.dismiss)
        private var dismiss
        
        init(
            title: String,
            subtitle: String,
            @ViewBuilder content: () -> Content
        ) {
            self.title = title
            self.subtitle = subtitle
            self.content = content()
        }
        
        var body: some View {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(
                        alignment: .leading,
                        spacing: 5
                    ) {
                        Text(title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(DashboardTheme.textPrimary)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(DashboardTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .frame(
                                width: 24,
                                height: 18
                            )
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)
                    .help("Close")
                }
                .padding(22)
                
                Divider()
                
                ScrollView {
                    content
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .padding(22)
                }
            }
            .frame(
                width: 780,
                height: 680
            )
            .background(DashboardTheme.canvas)
        }
    }
}

extension ChartsHelpInfo {
    
    /// One thermal-event family with its spring and fall interpretations
    struct ThresholdEventCard: View {
        
        let title: String
        let technicalLabel: String
        let systemImage: String
        let tint: Color
        
        let springTitle: String
        let springExplanation: String
        
        let fallTitle: String
        let fallExplanation: String
        
        var body: some View {
            VStack(
                alignment: .leading,
                spacing: 16
            ) {
                HStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .font(.title2)
                        .foregroundStyle(tint)
                        .frame(width: 30)
                    
                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(DashboardTheme.textPrimary)
                        
                        Text(technicalLabel)
                            .font(.caption.monospaced())
                            .foregroundStyle(tint)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                HStack(
                    alignment: .top,
                    spacing: 20
                ) {
                    boundaryColumn(
                        eyebrow: "SPRING",
                        title: springTitle,
                        explanation: springExplanation
                    )
                    
                    Rectangle()
                        .fill(DashboardTheme.border)
                        .frame(width: 1)
                    
                    boundaryColumn(
                        eyebrow: "FALL",
                        title: fallTitle,
                        explanation: fallExplanation
                    )
                }
            }
            .padding(18)
            .background(DashboardTheme.panel)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .stroke(
                    DashboardTheme.border,
                    lineWidth: 1
                )
            }
        }
        
        private func boundaryColumn(
            eyebrow: String,
            title: String,
            explanation: String
        ) -> some View {
            VStack(
                alignment: .leading,
                spacing: 7
            ) {
                Text(eyebrow)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(tint)
                
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DashboardTheme.textPrimary)
                
                Text(explanation)
                    .font(.callout)
                    .foregroundStyle(DashboardTheme.textSecondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }
}

extension ChartsHelpInfo {
    
    /// Complete educational guide for the Threshold Seasons chart.
    struct ThresholdSeasons: View {
        
        var body: some View {
            Sheet(
                title: "Understanding Threshold Seasons",
                subtitle: "Eight ways to describe when temperature thresholds arrive, depart, and lock in."
            ) {
                VStack(
                    alignment: .leading,
                    spacing: 18
                ) {
                    howToReadCard
                    
                    Divider()
                    
                    ThresholdEventCard(
                        title: "Cold Nights",
                        technicalLabel: "Tmin ≤ threshold",
                        systemImage: "snowflake",
                        tint: .cyan,
                        springTitle: "Last cold morning",
                        springExplanation: """
                        The final spring morning on which the minimum temperature reaches or falls below the selected threshold. At 32°F, this is the traditional last spring freeze. At 28°F, it marks the end of hard freezes.
                        
                            For other thresholds, such as 65°F, the significance is warm summer nights,
                            which could be a significant measure of heat stress if there is a season
                            where nights fail to cool below 65°F.
                        """,
                        fallTitle: "First cold morning",
                        fallExplanation: """
                        The first fall morning on which the minimum temperature reaches or falls below the threshold. At 32°F, this is the first fall freeze. Lower thresholds describe the return of progressively more serious cold.
                        """
                    )
                    
                    ThresholdEventCard(
                        title: "Mild Night Onset",
                        technicalLabel: "Tmin ≥ threshold",
                        systemImage: "moon.stars.fill",
                        tint: .indigo,
                        springTitle: "First mild morning",
                        springExplanation: """
                        The first spring morning whose minimum reaches or exceeds the selected threshold. This is spring knocking on the door. It does not mean the last freeze has passed. Winter may still answer the door with violence.
                        """,
                        fallTitle: "Last mild morning",
                        fallExplanation: """
                        The final fall morning whose minimum reaches or exceeds the threshold. This marks the seasonal departure of nights that remain unusually mild.
                        """
                    )
                    
                    ThresholdEventCard(
                        title: "Warm Afternoons",
                        technicalLabel: "Tmax ≥ threshold",
                        systemImage: "sun.max.fill",
                        tint: .orange,
                        springTitle: "First warm afternoon",
                        springExplanation: """
                        The first spring afternoon whose maximum reaches or exceeds the threshold. In Fairbanks, the first 50°F afternoon is a real event and should be treated with the appropriate amount of emotional investment.
                        
                        One warm afternoon does not mean warmth is established. This is a first occurrence, not a lock-in.
                        """,
                        fallTitle: "Last warm afternoon",
                        fallExplanation: """
                        The final fall afternoon whose maximum reaches or exceeds the threshold. This describes the last qualifying warm day of each historical year.
                        """
                    )
                    
                    ThresholdEventCard(
                        title: "Warm Afternoon Lock-In",
                        technicalLabel: "Tmax < threshold",
                        systemImage: "sun.haze.fill",
                        tint: .yellow,
                        springTitle: "Last failure to reach the threshold",
                        springExplanation: """
                        The final spring afternoon whose maximum remains below the selected threshold. After this boundary, every afternoon in that year’s uninterrupted lock-in interval reaches at least that temperature.
                        
                        This is the “okay, summer actually means business now” boundary.
                        """,
                        fallTitle: "First failure to reach the threshold",
                        fallExplanation: """
                        The first fall afternoon whose maximum remains below the threshold, ending the uninterrupted warm-afternoon season.
                        
                        Warm afternoons may return afterward. Summer is allowed to stage a comeback. The continuous streak has simply been broken.
                        """
                    )
                    
                    Divider()
                    
                    technicalNote
                }
            }
        }
        
        private var howToReadCard: some View {
            VStack(
                alignment: .leading,
                spacing: 14
            ) {
                Text("How to read the chart")
                    .font(.headline)
                    .foregroundStyle(
                        DashboardTheme.textPrimary
                    )
                
                Text(
                    "Every complete historical year contributes one qualifying event date. Percentiles are then calculated across those annual dates."
                )
                .font(.callout)
                .foregroundStyle(
                    DashboardTheme.textSecondary
                )
                
                HStack(
                    alignment: .top,
                    spacing: 16
                ) {
                    guidePoint(
                        title: "50% date",
                        explanation: "The median historical event date—not the average."
                    )
                    
                    guidePoint(
                        title: "Spring risk",
                        explanation: "The chance that the spring event still occurs after the indicated date."
                    )
                    
                    guidePoint(
                        title: "Fall risk",
                        explanation: "The chance that the fall event has already occurred before the indicated date."
                    )
                }
                
                Label(
                    "These are climatological probabilities, not a forecast or promise. Weather will continue doing whatever the hell it wants in an individual year.",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.caption)
                .foregroundStyle(.orange)
            }
            .padding(18)
            .background(DashboardTheme.panelElevated)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .stroke(
                    DashboardTheme.border,
                    lineWidth: 1
                )
            }
        }
        
        private var technicalNote: some View {
            VStack(
                alignment: .leading,
                spacing: 8
            ) {
                Label(
                    "A small but important technical distinction",
                    systemImage: "equal.circle"
                )
                .font(.headline)
                .foregroundStyle(
                    DashboardTheme.textPrimary
                )
                
                Text(
                    "Warm Afternoon Lock-In uses a strict “less than” comparison. If Tmax equals the threshold exactly, that afternoon successfully reached it. Cold Nights uses “less than or equal,” so Tmin = 32°F counts as a freezing morning. Weather enjoys exploiting definitions, so the definitions need to be exact."
                )
                .font(.callout)
                .foregroundStyle(
                    DashboardTheme.textSecondary
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }
            .padding(.horizontal, 4)
        }
        
        private func guidePoint(
            title: String,
            explanation: String
        ) -> some View {
            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(
                        DashboardTheme.textPrimary
                    )
                
                Text(explanation)
                    .font(.caption)
                    .foregroundStyle(
                        DashboardTheme.textSecondary
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }
}

extension ChartsHelpInfo {
    
    /// Compact , reusable invitation to open a climate-chart guide.
    struct Trigger: View {
        
        let title: String
        let detail: String
        let action: () -> Void
        
        @State
        private var isHovering = false
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: 7) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(DashboardTheme.observedTemperature)
                    
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DashboardTheme.textPrimary)
                    
                    Rectangle()
                        .fill(DashboardTheme.border)
                        .frame(
                            width: 1,
                            height: 12
                        )
                    
                    Text(detail)
                        .font(.caption.monospaced())
                        .foregroundStyle(DashboardTheme.textSecondary)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(DashboardTheme.observedTemperature)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(
                    DashboardTheme.observedTemperature
                        .opacity(isHovering ? 0.16 : 0.08)
                )
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(
                            DashboardTheme.observedTemperature
                                .opacity(isHovering ? 0.70 : 0.38),
                            lineWidth: 1
                        )
                }
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .fixedSize()
            .onHover { hovering in
                isHovering = hovering
            }
            .animation(
                .easeOut(duration: 0.14),
                value: isHovering
            )
        }
    }
}
