/// One swift file to explain every single climate chart.
///
import SwiftUI
import Foundation
import LaTeXSwiftUI
import AppKit

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
    
    /// Turns source-code line wrapping into naturally flowing prose while preserving
    /// intentionally-blank lines between paragraphs. Functions kind of like a function.
    struct Prose: View {
        private let content: String
        
        init(_ content: String) {
            self.content = content
                .components(separatedBy: "\n\n")
                .map { paragraph in
                    paragraph
                        .split(whereSeparator: { $0.isWhitespace })
                        .joined(separator: " ")
                }
                .joined(separator: "\n\n")
        }
        /// Output of Prose is not a "nice text" - it is a rendered view. With a width rule
        /// and a don't truncate me rul.
        var body: some View {
            Text(content)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

extension ChartsHelpInfo {
    
    /// Shared presentation for equations used throughout the climate-chart scientific notes.
    struct EquationBlock: View {
        let expression: String
        let equationNumber: Int?
        let caption: String?
        
        init(
            _ expression: String,
            equationNumber: Int? = nil,
            caption: String? = nil
        ) {
            self.expression = expression
            self.equationNumber = equationNumber
            self.caption = caption
        }
        
        var body: some View {
            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                Group {
                    if let equationNumber {
                        LaTeX("$$\(expression)$$")
                            .font(NSFont.systemFont(ofSize: 30))
                            .equationNumberMode(.right)
                            .equationNumberStart(equationNumber)
                    } else {
                        LaTeX("$$\(expression)$$")
                            .font(NSFont.systemFont(ofSize: 30))
                    }
                }
                .minimumScaleFactor(0.72)
                .lineLimit(1)
                .foregroundStyle(DashboardTheme.textPrimary)
                .frame(
                    maxWidth: .infinity,
                    alignment: .center
                )
                if let caption {
                    Text(caption)
                        .font(.caption)
                        .foregroundStyle(DashboardTheme.textSecondary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(DashboardTheme.panelElevated)
            .clipShape(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DashboardTheme.border, lineWidth: 1)
            }
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
    
    /// Educational guide for the Annual Temperature Curve.
    struct AnnualTemperatureCurve: View {
        
        var body: some View {
            Sheet(
                title: "Understanding the Annual Temperature Curve",
                subtitle: "A fitted portrait of the climatological year—not a forecast and not one particular year."
            ) {
                VStack(
                    alignment: .leading,
                    spacing: 18
                ) {
                    howToReadCard
                    
                    Divider()
                    
                    explanationCard(
                        title: "Normal High and Normal Low",
                        systemImage: "thermometer.medium",
                        tint: .orange,
                        paragraphs: [
                            """
                            The red curve is the fitted normal daily maximum temperature. The blue curve is the fitted normal daily minimum temperature.
                            """,
                            """
                            The climatological normals are first smoothed with a cyclic Gaussian filter using a radius of 15 days, a 31-day weighted window. The smoothed normals are then fitted to an nth order Fourier series. Orders 3 through 10 are evaluated, and the simplest fit whose RMSE is within 0.05 °F of the best-performing fit is selected. Most stations will settle somewhere around order 5 through 9, depending on the complexity of their seasonal temperature curve. For example, some locations in the intermountain west have a second winter minimum in mid-February. A higher order fit might be needed.
                            """,
                            """
                            The distance between the two curves is the typical day-to-night temperature range. It is not a probability band.
                            """
                        ]
                    )
                    
                    explanationCard(
                        title: "Temperature Variability",
                        systemImage: "waveform.path",
                        tint: DashboardTheme.observedTemperature,
                        paragraphs: [
                            """
                            σmax is the standard deviation of historical daily maximum temperatures. σmin is calculated independently from historical daily minimum temperatures.
                            """,
                            """
                            The ±1σ envelopes show ordinary year-to-year temperature variability around each normal curve. The ±2σ envelopes show a much wider range and are therefore allowed to become visually chaotic.
                            """,
                            """
                            Standard deviation is not forecast uncertainty and it is not an error bar around the fitted normal. It measures how variable actual temperatures have historically been on that part of the calendar.
                            """,
                            """
                            The Tmax and Tmin envelopes may overlap. That is mathematically legal and climatologically normal. They describe separate distributions, not the temperature range of one hypothetical day.
                            """
                        ]
                    )
                    
                    explanationCard(
                        title: "Thermal Midsommar and Midwinter",
                        systemImage: "calendar.badge.clock",
                        tint: .purple,
                        paragraphs: [
                            """
                            Thermal midsommar is the portion of the year during which the fitted normal low remains within the warmest 10% of its annual range.
                            """,
                            """
                            Thermal midwinter is the corresponding coldest 10% window. Because winter crosses New Year’s Day, its displayed range may begin in December and end in February or March.
                            """,
                            """
                            These are temperature-phase windows—not astronomical seasons. The atmosphere was not consulted before the Gregorian calendar was invented.
                            """
                        ]
                    )
                    
                    explanationCard(
                        title: "Hover Details",
                        systemImage: "cursorarrow.motionlines",
                        tint: .cyan,
                        paragraphs: [
                            """
                            Hover over the graph to inspect the normal high, normal low, and—when enabled—the selected variability boundaries and their underlying σ values.
                            """,
                            """
                            S(t) is estimated daily solar insolation in kWh/m²/day. The normalized value s(t) expresses the same solar cycle on a dimensionless scale from approximately zero to one.
                            """,
                            """
                            Hover details can be individually enabled or disabled under Graph Options when the information box begins turning into a receipt.
                            """
                        ]
                    )
                    
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
                    .foregroundStyle(DashboardTheme.textPrimary)
                
                Text(
                    "Read horizontally to follow the climatological year. Read vertically to compare normal temperatures and the historical variability surrounding them."
                )
                .font(.callout)
                .foregroundStyle(DashboardTheme.textSecondary)
                
                HStack(
                    alignment: .top,
                    spacing: 16
                ) {
                    guidePoint(
                        title: "Curves",
                        explanation: "Smoothed normal daily high and low temperatures."
                    )
                    
                    guidePoint(
                        title: "Bands",
                        explanation: "Historical variability around each normal curve."
                    )
                    
                    guidePoint(
                        title: "Hover",
                        explanation: "The exact values represented on one calendar day."
                    )
                }
                
                Label(
                    "This is climatology, not prophecy. An individual year remains legally permitted to behave like an idiot.",
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
                    "The normalized thermal phase",
                    systemImage: "function"
                )
                .font(.headline)
                .foregroundStyle(DashboardTheme.textPrimary)
                
                Text(
                    "Thermal timing uses τ(t) = [Tmin(t) − annual Tmin] / [annual Tmax of Tmin − annual Tmin]. Thermal midsommar uses τ ≥ 0.9; thermal midwinter uses τ ≤ 0.1."
                )
                .font(.callout.monospaced())
                .foregroundStyle(DashboardTheme.textSecondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }
            .padding(.horizontal, 4)
        }
        
        private func explanationCard(
            title: String,
            systemImage: String,
            tint: Color,
            paragraphs: [String]
        ) -> some View {
            VStack(
                alignment: .leading,
                spacing: 14
            ) {
                Label {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(DashboardTheme.textPrimary)
                } icon: {
                    Image(systemName: systemImage)
                        .foregroundStyle(tint)
                }
                
                Divider()
                
                ForEach(paragraphs, id: \.self) { paragraph in
                    Text(paragraph)
                        .font(.callout)
                        .foregroundStyle(DashboardTheme.textSecondary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
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
                    .foregroundStyle(DashboardTheme.textPrimary)
                
                Text(explanation)
                    .font(.caption)
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
    
    /// A compact scientific note describing the Seasonal Hysteresis Curve.
    struct SeasonalHysteresis: View {
        
        var body: some View {
            Sheet(
                title: "Understanding Seasonal Hysteresis",
                subtitle: """
                    A phase-space description of how periodic solar forcing evolves minimum temperatures.
                    """
            ) {
                VStack(
                    alignment: .leading,
                    spacing: 18
                ) {
                    abstractCard
                    
                    phaseSpaceSection
                    
                    eigendateSection
                    
                    chordSection
                    
                    memorySection
                    
                    interpretationCard
                    
                    limitationsCard
                }
            }
        }
        
        private var abstractCard: some View {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                Label(
                    "Abstract",
                    systemImage: "doc.text.magnifyingglass"
                )
                .font(.headline)
                .foregroundStyle(DashboardTheme.textPrimary)
                
                Prose(
                    """
                    Seasonal solar forcing rises and falls in a nearly periodic cycle, but temperature
                    does not respond instantaneously. The Seasonal Hysteresis Curve plots fitted normal minimum temperature against normalized solar input, replacing calendar time with
                    a two-dimensional phase trajectory.
                    """
                )
                
                Prose(
                    """
                    The resulting loop measures the thermal asymmetry between the warming and cooling
                    halves of the year. Its local width is described using eigendate chords, while
                    total enclosed area is summarized by the Seasonal Memory Index.
                    """
                )
                Prose(
                    """
                    In a fictional atmosphere with no thermal lag, equal solar inputs would produce
                    equal temperatures during spring and fall. In this limit of zero lag, its enclosed area
                    would vanish.
                    """
                )
            }
            .font(.callout)
            .foregroundStyle(DashboardTheme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(18)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(DashboardTheme.panelElevated)
            .clipShape(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(DashboardTheme.border, lineWidth: 1)
            }
        }
        
        fileprivate var phaseSpaceSection: some View {
            paperSection(
                title: "1. Phase-Space Representation",
                systemImage: "point.3.connected.trianglepath.dotted",
                tint: .purple
            ) {
                Prose(
                    """
                    Let s(t) be normalized daily solar insolation and let Tmin(t) be the
                    fitted climatological normal minimum temperature. The calendar year
                    becomes the closed trajectory.
                    """
                )
                EquationBlock(
                    #"\gamma(t)=\left(s(t),\,T_{\min}(t)\right),\qquad t\in\{1,\ldots,365\}"#,
                    equationNumber: 1,
                    caption:
                        "The annual climatological trajectory in normalized-solar-temperature phase space"
                )
                
                Prose(
                    """
                    Calendar time is implicit in the direction of travel. Green arrows show the progression
                    from winter to summer and back. The arrows' orientation is not coincidental, they are a
                    centered finite-difference estimate of the local phase-curve tangent. Notice that dT/ds > 0 in
                    the spring warming branch. This makes sense because
                    in the spring, the increased solar insolation is accompanied by an increase in
                    the climatological minimum temperature. The opposite is true in the fall, so the negative
                    signs cancel out and thus dT/ds remains positive.
                    
                    Thermal lag in the summer can actually be characterized by the date range for which
                    s(t) is decreasing (right after the June solstice) but Tmin(t) still has a positive derivative.
                    """
                )
            }
        }
        
        private var eigendateSection: some View {
            paperSection(
                title: "2. Eigendates and Eigentemperatures",
                systemImage: "arrow.left.and.right",
                tint: .green
            ) {
                Prose(
                    """
                    All solar-input levels, barring the solstices, occur twice during one year: once while 
                    solar input is increasing, and again while it is decreasing in the fall. These two
                    calendar dates form an eigendate pair.
                    """
                )
                
                EquationBlock(
                    #"""
                    \begin{aligned}
                    s(t_{\uparrow}) &= s(t_{\downarrow}) = s_0, \\
                    \dot{s}(t_{\uparrow}) &> 0,
                    \qquad
                    \dot{s}(t_{\downarrow}) < 0
                    \end{aligned}
                    """#,
                    equationNumber: 2,
                    caption:
                        "The rising- and falling-solar dates associated with the same normalized insolation."
                )
                
                Prose(
                    """
                    Their corresponding minimum temperatures are the cool-branch and warm-branch
                    eigentemperatues. The vertical separation between them is 
                    the eigendate chord depth.
                    """
                )
                
                EquationBlock(
                    #"\Delta T_e(s_0)=T_{\min}(t_{\downarrow})-T_{\min}(t_{\uparrow})"#,
                    equationNumber: 3,
                    caption: """
                        Positive values mean the falling-solar branch is warmer than
                        the rising-solar branch at equal solar input.
                        """
                )
            }
        }
        
        private var chordSection: some View {
            paperSection(
                title: "3. Maximum Eigendate Chord Depth",
                systemImage: "arrow.up.and.down",
                tint: .orange
            ) {
                Prose(
                    """
                    The Maximum Eigendate Chord Depth, or MECD,
                    identifies the solar-input level at which the warm and cool
                    branches are separated most strongly for equal solar input.
                    Informally, it is the temperature distance between two 
                    eigendates that maximizes this temperature distance.
                    """
                )
                
                EquationBlock(
                    #"\mathrm{MECD}=\max_{s\in\mathcal{S}}\Delta T_e(s)"#,
                    equationNumber: 4,
                    caption:
                        "The maximum positive branch separation over their shared solar-input domain."
                )
                
                Text(
                    """
                    The app evaluates 1,001 evenly-spaced solar-input levels and linearly interpolates
                    each branch. MECD is a local diagnostic: it finds the deepest portion of the loop
                    but does not describe the entire loop.
                    """
                )
            }
        }
        
        private var memorySection: some View {
            paperSection(
                title: "4. Seasonal Memory Index",
                systemImage: "integral",
                tint: DashboardTheme.observedTemperature
            ) {
                Prose(
                    """
                    The Seasonal Memory Index, or SMI, measures the absolute value of the signed area enclosed by
                    the complete phase space trajectory.
                    """
                )
                
                EquationBlock(
                    #"\mathrm{SMI}=\left|\oint_{\gamma}T_{\min}\,ds\right|"#,
                    equationNumber: 5,
                    caption:
                        "Because normalized solar input is dimensionless, SMI retains temperature units."
                )
                
                Prose(
                    """
                    The application evaluates this integral numerically using the trapezoidal rule
                    between two consecutive calendar days, including the closing segment from
                    December 31 back to January 1.
                    """
                )
                
                Prose(
                    """
                    Unlike MECD, SMI is an integrated diagnostic: A branch loop with moderate separation may
                    have a larger SMI than a narrow loop containing one unusually deep chord.
                    """
                )
                
                Divider()
                    .padding(.vertical, 4)
                
                Text("4.1 Relative Seasonal Memory Index")
                    .font(.headline)
                    .foregroundStyle(DashboardTheme.textPrimary)
                
                Prose(
                    """
                    Raw SMI retains temperature units, so climates with large annual temperature
                    ranges naturally have more vertical phase space available in which to form a
                    large loop. The Relative Seasonal Memory Index, RSMI,  removes this temperature-scale
                    dependence by dividing SMi by the fitted annual range of normal minimum
                    temperature.
                    """
                )
                
                EquationBlock(
                    #"""
                    \begin{aligned}
                    \Delta T_{\min}
                    &=
                    \max_t T_{\min}(t) - \min_t T_{\min}(t), \\[4pt]
                    \mathrm{RSMI}
                    &=
                    \frac{\mathrm{SMI}}{\Delta T_{\min}}
                    =
                    \frac{\left|\oint_{\gamma}T_{\min}\,ds\right|}
                    {\Delta T_{\min}}
                    \end{aligned}
                    """#,
                    equationNumber: 6,
                    caption:
                        """
                        Because s(t) spans zero to unity, the denominator is the area of the 
                        available phase-space bounding rectangle
                        """
                )
                
                Prose(
                    """
                    RSMI is dimensionless and can therefore be compared more directly among
                    climates processed through the same climatological pipeline. It describes the
                    fraction of the available normalized-solar-temperature phase space enclosed by
                    the seasonal loop. It does not represent a temperature difference, a number of
                    lag days, or a measured atmospheric heat capacity.
                    """
                )
            }
        }
        
        private var interpretationCard: some View {
            paperSection(
                title: "5. Physical Interpretation",
                systemImage: "thermometer.variable.and.figure",
                tint: .pink
            ) {
                Prose(
                    """
                    A larger SMI indicates greater integrated separation between the warming and
                    cooling branches. Locations can be compared within this application when
                    they use the same normal period, solar normalization, temperature variable,
                    smoothing, and fitting pipeline.
                    """
                )
                
                Prose(
                    """
                    Thus, an SMI of 25 °F represents greater apparent season memory than an SMI of
                    14 °F in these coordinates. It does not mean that the location is 11 °F warmer,
                    stores a measured quantity of heat, or experiences a specific number of
                    additional lag days.
                    """
                )
                
                Prose(
                    """
                    Oceans, lakes, soil moisture, snow cover, elevation, atmospheric circulation, and seasonal
                    humidity can all influence the loop. The curve describes their combined climatological
                    expression; it does not isolate any single cause.
                    """
                )
            }
        }
        
        private var limitationsCard: some View {
            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                Label(
                    "Terminology and limitations",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.headline)
                .foregroundStyle(.orange)
                
                Prose(
                    """
                    Seasonal hysteresis is a general physical concept. "Eigendate", "eigentemperature",
                    "Maximum Eigendate Chord Depth", and "Seasonal Memory Index/RSMI" are operational terms
                    defined by this application. As far as I know, these are novel quantities that can
                    be used to characterize a wide range of climates. They are not standardized terms.
                    """
                )
                
                Prose("""
                    These values summarize a fitted-climatological normal curve. They are descriptive
                    diagnostics - not forecasts, causal models, or direct measurements of 
                    atmospheric heat capacity.
                    """
                )
            }
            .font(.callout)
            .foregroundStyle(DashboardTheme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(18)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(Color.orange.opacity(0.07))
            .clipShape(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.orange.opacity(0.35), lineWidth: 1)
            }
        }
        
        private func paperSection<Content: View>(
            title: String,
            systemImage: String,
            tint: Color,
            @ViewBuilder content: () -> Content
        ) -> some View {
            VStack(
                alignment: .leading,
                spacing: 14
            ) {
                Label {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(DashboardTheme.textPrimary)
                } icon: {
                    Image(systemName: systemImage)
                        .foregroundStyle(tint)
                }
                
                Divider()
                
                content()
                    .font(.callout)
                    .foregroundStyle(DashboardTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(DashboardTheme.panel)
            .clipShape(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(DashboardTheme.border, lineWidth: 1)
            }
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
