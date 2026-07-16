import SwiftUI

/// Semantic colors and measurements shared by the dashboard.
///
/// These names describe what a color does rather than what literal
/// color it currently contains. A future light theme can therefore
/// replace the values without rewriting every view.
enum DashboardTheme {
    // MARK: - Application canvas

    static let canvasDeep = Color(
        red: 0.015,
        green: 0.025,
        blue: 0.075
    )

    static let canvas = Color(
        red: 0.025,
        green: 0.055,
        blue: 0.130
    )

    static let canvasSoft = Color(
        red: 0.065,
        green: 0.085,
        blue: 0.180
    )

    static let dayAccent = Color(
        red: 0.070,
        green: 0.140,
        blue: 0.210
    )

    static let sunriseAccent = Color(
        red: 0.160,
        green: 0.110,
        blue: 0.200
    )

    static let sunsetAccent = Color(
        red: 0.180,
        green: 0.100,
        blue: 0.170
    )

    // MARK: - Surfaces

    static let panel = Color(
        red: 0.035,
        green: 0.070,
        blue: 0.130
    )

    static let panelElevated = Color(
        red: 0.050,
        green: 0.100,
        blue: 0.170
    )

    static let plotArea = Color(
        red: 0.020,
        green: 0.045,
        blue: 0.085
    )

    static let border = Color.white.opacity(0.10)
    static let chartGridMajor = Color.white.opacity(0.16)
    static let chartGridMinor = Color.white.opacity(0.08)

    // MARK: - Text

    static let textPrimary = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.72)

    // MARK: - Scientific data colors

    static let observedTemperature = Color(
        red: 0.10,
        green: 0.52,
        blue: 0.98
    )

    static let forecastTemperature = Color(
        red: 0.30,
        green: 0.80,
        blue: 0.95
    )

    static let dewPoint = Color(
        red: 0.24,
        green: 0.78,
        blue: 0.72
    )

    static let heatIndex = Color(
        red: 0.90,
        green: 0.25,
        blue: 0.62
    )

    static let normal = Color(
        red: 0.95,
        green: 0.65,
        blue: 0.15
    )

    static let success = Color.green
    static let failure = Color.red

    // MARK: - Measurements

    static let cardCornerRadius: CGFloat = 10

    // MARK: - Atmospheric background

    static func backgroundColors(
        for phase: DaylightPhase
    ) -> [Color] {
        switch phase {
        case .sunrise:
            return [
                canvasDeep,
                sunriseAccent,
                canvasSoft
            ]

        case .day:
            return [
                canvasDeep,
                dayAccent,
                canvasSoft
            ]

        case .sunset:
            return [
                canvasDeep,
                sunsetAccent,
                canvasSoft
            ]

        case .night:
            return [
                canvasDeep,
                canvas,
                canvasSoft
            ]
        }
    }
}
