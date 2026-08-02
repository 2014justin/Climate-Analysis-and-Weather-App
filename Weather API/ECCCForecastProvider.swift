import Foundation

enum ECCCForecastProviderError: LocalizedError, Sendable {
    
    case noUsableAirTemperature(
        regionIdentifier: String
    )
    
    var errorDescription: String? {
        switch self {
        case .noUsableAirTemperature(let regionIdentifier):
            return """
                ECCC returned no usable air-temperature forecast values for \
                region \(regionIdentifier)
                """
        }
    }
}

/// Converts ECCC Meteocode products into the provider-agnostic forecast model.
/// Every ECCC-specific cornern: including geographic region resolution, bulletin selection, XML parsing, and interval
/// merging, remains below this boundary. Forecast consumers receive the same model used by
/// NWS and future international providers.
struct ECCCForecastProvider: WeatherForecastProviding {
    let providerID: ForecastProviderID =
        .ecccMeteocode
    
    fileprivate let regionCatalogService: ECCCForecastRegionCatalogService
    
    nonisolated init(
        session: URLSession = .shared
    ) {
        regionCatalogService =
            ECCCForecastRegionCatalogService(session: session)
    }
    
    func forecast(
        for request: ForecastRequest
    ) async throws -> Forecast {
        let resolvedForecast =
        try await regionCatalogService.resolvedForecast(
            containingLatitude: request.latitude,
            longitude: request.longitude
        )
        
        let mergedIntervals = resolvedForecast.mergedTemperatureIntervals()
        
        let samples = mergedIntervals.map { interval in
            let isInstantaneous =
                interval.validEnd == interval.validStart

            return ForecastSample(
                validStart: interval.validStart,
                validEnd: isInstantaneous
                    ? nil
                    : interval.validEnd,
                timeSemantics: isInstantaneous
                    ? .instantaneous
                    : .intervalRepresentative,
                airTemperature: interval.airTemperatureCelsius.map {
                    ForecastTemperature(celsius: $0)
                },
                dewPoint: interval.dewPointCelsius.map {
                    ForecastTemperature(celsius: $0)
                },
                reportedRelativeHumidityPercent: nil,
                conditionText: nil
            )
        }
        .sorted {
            if $0.validStart != $1.validStart {
                return $0.validStart < $1.validStart
            }

            return ($0.validEnd ?? $0.validStart)
                < ($1.validEnd ?? $1.validStart)
        }
        
        guard samples.contains(
            where: {
                $0.airTemperature != nil
            }
        ) else {
            throw ECCCForecastProviderError
                .noUsableAirTemperature(regionIdentifier: resolvedForecast.region.id)
        }
        
        let uniqueValidStarts =
        Array(Set(samples.map(\.validStart)))
            .sorted()
        
        let positiveSampleSpacing =
            zip(
                uniqueValidStarts,
                uniqueValidStarts.dropFirst()
            )
            .compactMap { pair -> TimeInterval? in
                let spacing =
                pair.1.timeIntervalSince(pair.0)
                
                return spacing > 0.0
                ? spacing
                : nil
            }
        
        let nativeCadenceSeconds =
        WeatherMath.percentile(of: positiveSampleSpacing, percentile: 50.0)
        
        let issuedAt =
        resolvedForecast.segments
            .map(\.issuedAt)
            .max()
        
        return Forecast(
            metadata: ForecastMetadata(
                providerID: providerID,
                productName: "ECCC Meteocode Regional Forecast",
                productClass: .officialForecast,
                spatialTarget: .region(
                    identifier: resolvedForecast.region.id,
                    name: resolvedForecast.region.name
                ),
                issuedAt: issuedAt,
                modelRunAt: nil,
                fetchedAt: Date(),
                nativeCadenceSeconds: nativeCadenceSeconds,
                attribution: "Environment and Climate Change Canada"
            ),
            samples: samples
        )
    }
}
