/// Supplies the Bulk National data as a single file to reduce API calling.
///

import Foundation

/// One provider-specific row from Aviation Weather's
/// worldwide METAR CSV file.
struct AviationWeatherBulkMETARRecord: Sendable {
    let stationID: String
    let observedAt: Date
    let latitude: Double
    let longitude: Double
    let temperatureCelsius: Double
    let dewPointCelsius: Double?
    let windSpeedKnots: Double?
    let elevationMeters: Double?
    let conditionDescription: String?

    init?(csvRow: Substring) {
        let fields = csvRow.split(
            separator: ",",
            omittingEmptySubsequences: false
        )

        guard fields.count > 43,
              let rawStationID = Self.cleaned(fields[1]),
              let dateText = Self.cleaned(fields[2]),
              let observedAt = try? Date(
                dateText,
                strategy: .iso8601
              ),
              let latitude = Self.double(fields[3]),
              let longitude = Self.double(fields[4]),
              let temperatureCelsius =
                Self.double(fields[5]) else {
            return nil
        }

        stationID = rawStationID.uppercased()
        self.observedAt = observedAt
        self.latitude = latitude
        self.longitude = longitude
        self.temperatureCelsius =
            temperatureCelsius

        dewPointCelsius = Self.double(fields[6])
        windSpeedKnots = Self.double(fields[8])
        elevationMeters = Self.double(fields[43])

        conditionDescription =
            Self.cleaned(fields[21])
            ?? Self.cleaned(fields[22])
    }

    private static func cleaned(
        _ rawValue: Substring
    ) -> String? {
        let value = String(rawValue)
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return value.isEmpty ? nil : value
    }

    private static func double(
        _ rawValue: Substring
    ) -> Double? {
        guard let value = cleaned(rawValue) else {
            return nil
        }

        return Double(value)
    }
}
