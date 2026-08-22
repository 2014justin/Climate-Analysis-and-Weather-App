import Foundation
import SwiftUI

struct WeatherGovAPIActivityBadge:
    View {

    let snapshot:
        WeatherGovAPIActivitySnapshot

    @State private var
    isShowingDetails = false

    var body: some View {
        Button {
            isShowingDetails.toggle()
        } label: {
            HStack(spacing: 7) {
                Circle()
                    .fill(activityColor)
                    .frame(
                        width: 8,
                        height: 8
                    )
                    .shadow(
                        color:
                            activityColor
                                .opacity(0.45),
                        radius: 3
                    )

                Text("Weather.gov")
                    .font(
                        .caption
                            .weight(.semibold)
                    )

                Text(
                    "\(snapshot.requestsLastMinute)"
                    + " / "
                    + "\(WeatherGovAPIActivitySnapshot.advisoryRequestsPerMinute)"
                    + " req/min"
                )
                .font(
                    .caption
                        .monospacedDigit()
                )
                .foregroundStyle(
                    DashboardTheme.textSecondary
                )
            }
            .foregroundStyle(
                DashboardTheme.textPrimary
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(
            width: 220,
            height: 32
        )
        .background {
            RoundedRectangle(
                cornerRadius: 8,
                style: .continuous
            )
            .fill(
                DashboardTheme
                    .panelElevated
                    .opacity(0.92)
            )
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: 8,
                style: .continuous
            )
            .stroke(
                activityColor.opacity(0.45),
                lineWidth: 1
            )
            .allowsHitTesting(false)
        }
        .contentShape(
            RoundedRectangle(
                cornerRadius: 8,
                style: .continuous
            )
        )
        .help(
            "Open Weather.gov API activity details"
        )
        .accessibilityLabel(
            "Weather.gov API activity"
        )
        .accessibilityValue(
            "\(snapshot.requestsLastMinute) "
            + "of "
            + "\(WeatherGovAPIActivitySnapshot.advisoryRequestsPerMinute) "
            + "advisory requests per minute. "
            + activityDescription
        )
        .popover(
            isPresented: $isShowingDetails,
            arrowEdge: .top
        ) {
            detailPanel
        }
    }

    private var detailPanel:
        some View {

        VStack(
            alignment: .leading,
            spacing: 13
        ) {
            HStack(spacing: 8) {
                Circle()
                    .fill(activityColor)
                    .frame(
                        width: 10,
                        height: 10
                    )

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    Text(
                        "Weather.gov Activity"
                    )
                    .font(.headline)

                    Text(activityDescription)
                        .font(.caption)
                        .foregroundStyle(
                            activityColor
                        )
                }
            }

            Divider()

            sectionTitle("Traffic")

            VStack(spacing: 8) {
                metricRow(
                    "Requests, last 60 sec",
                    value:
                        snapshot
                            .requestsLastMinute
                )

                metricRow(
                    "Requests, last 5 min",
                    value:
                        snapshot
                            .requestsLastFiveMinutes
                )

                metricRow(
                    "Peak 60-sec rate, last 5 min",
                    value:
                        snapshot
                            .peakRequestsPerMinuteLastFiveMinutes
                )

                metricRow(
                    "Currently in flight",
                    value:
                        snapshot
                            .inFlightRequestCount
                )
            }

            Divider()

            sectionTitle(
                "Request types — last 5 min"
            )

            VStack(spacing: 8) {
                metricRow(
                    "Latest observations",
                    value:
                        endpointCount(
                            .latestObservation
                        )
                )

                metricRow(
                    "Station catalog pages",
                    value:
                        endpointCount(
                            .stationCatalog
                        )
                )

                metricRow(
                    "State lookups",
                    value:
                        endpointCount(
                            .stateLookup
                        )
                )

                metricRow(
                    "Other",
                    value:
                        endpointCount(.other)
                )
                
                metricRow(
                    "24h station histories",
                    value: endpointCount(.temperatureHistory)
                )
            }

            Divider()

            sectionTitle(
                "Outcomes — last 5 min"
            )

            VStack(spacing: 8) {
                metricRow(
                    "Successful",
                    value:
                        outcomeCount(
                            .successful
                        ),
                    valueColor:
                        outcomeCount(
                            .successful
                        ) > 0
                        ? DashboardTheme.success
                        : nil
                )

                metricRow(
                    "No current observation (404)",
                    value:
                        outcomeCount(
                            .noCurrentObservation
                        )
                )

                metricRow(
                    "Rejected / throttled (403/429)",
                    value:
                        outcomeCount(
                            .providerRejected
                        ),
                    valueColor:
                        failureColor(
                            for:
                                outcomeCount(
                                    .providerRejected
                                )
                        )
                )

                metricRow(
                    "Provider errors (5xx)",
                    value:
                        outcomeCount(
                            .providerError
                        ),
                    valueColor:
                        failureColor(
                            for:
                                outcomeCount(
                                    .providerError
                                )
                        )
                )

                metricRow(
                    "Other client errors (4xx)",
                    value:
                        outcomeCount(
                            .clientError
                        ),
                    valueColor:
                        failureColor(
                            for:
                                outcomeCount(
                                    .clientError
                                )
                        )
                )

                metricRow(
                    "Transport failures",
                    value:
                        outcomeCount(
                            .transportFailure
                        ),
                    valueColor:
                        failureColor(
                            for:
                                outcomeCount(
                                    .transportFailure
                                )
                        )
                )

                metricRow(
                    "Observation cache hits",
                    value:
                        snapshot
                            .observationCacheHitsLastFiveMinutes,
                    valueColor:
                        snapshot
                            .observationCacheHitsLastFiveMinutes
                        > 0
                        ? DashboardTheme.success
                        : nil
                )
            }

            Divider()

            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                Text(
                    "A station-level 404 means that station "
                    + "has no current observation. It is not "
                    + "an API failure."
                )

                Text(
                    "\(WeatherGovAPIActivitySnapshot.advisoryRequestsPerMinute)"
                    + " requests/min is the app’s local advisory "
                    + "ceiling, not an official provider quota."
                )

                Text(
                    "A nonzero rejected/throttled count means "
                    + "Weather.gov returned HTTP 403 or 429."
                )
            }
            .font(.caption)
            .foregroundStyle(
                DashboardTheme.textSecondary
            )
            .fixedSize(
                horizontal: false,
                vertical: true
            )
        }
        .padding(16)
        .frame(width: 390)
        .foregroundStyle(
            DashboardTheme.textPrimary
        )
        .background(
            DashboardTheme.panel
        )
    }

    private func sectionTitle(
        _ title: String
    ) -> some View {

        Text(title)
            .font(
                .caption
                    .weight(.semibold)
            )
            .foregroundStyle(
                DashboardTheme.textSecondary
            )
    }

    private func metricRow(
        _ title: String,
        value: Int,
        valueColor: Color? = nil
    ) -> some View {

        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(
                    DashboardTheme.textSecondary
                )

            Spacer()

            Text("\(value)")
                .font(
                    .subheadline
                        .weight(.semibold)
                        .monospacedDigit()
                )
                .foregroundStyle(
                    valueColor
                    ?? DashboardTheme.textPrimary
                )
        }
    }

    private func endpointCount(
        _ endpoint:
            WeatherGovAPIEndpointKind
    ) -> Int {
        snapshot.requestCountLastFiveMinutes(
            for: endpoint
        )
    }

    private func outcomeCount(
        _ outcome:
            WeatherGovAPIRequestOutcome
    ) -> Int {
        snapshot.outcomeCountLastFiveMinutes(
            for: outcome
        )
    }

    private func failureColor(
        for count: Int
    ) -> Color? {
        count > 0
        ? DashboardTheme.failure
        : nil
    }

    private var hasProviderRejection:
        Bool {

        outcomeCount(.providerRejected) > 0
    }

    private var activityColor:
        Color {

        if hasProviderRejection {
            return DashboardTheme.failure
        }

        switch snapshot.level {
        case .normal:
            return DashboardTheme.success

        case .elevated:
            return .yellow

        case .high:
            // Above our advisory is orange.
            // Red is reserved for a real rejection.
            return .orange
        }
    }

    private var activityDescription:
        String {

        if hasProviderRejection {
            return "Provider rejection detected"
        }

        switch snapshot.level {
        case .normal:
            return "Normal activity"

        case .elevated:
            return "Elevated activity"

        case .high:
            return "Above local advisory"
        }
    }
}
