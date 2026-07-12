# Architecture

## Project Shape

Active project:

`/Users/justinac/Documents/Weather API`

App source:

`/Users/justinac/Documents/Weather API/Weather API`

This is a SwiftUI macOS app using Charts, AppKit, and UniformTypeIdentifiers. The Xcode project uses `PBXFileSystemSynchronizedRootGroup`, so files in the `Weather API` source folder are included by folder synchronization rather than explicit source-file entries.

## Important Files

- `ContentView.swift`: app entry point, menu commands, dashboard UI, app state, live weather refresh, forecast discussion loading, exports, and climate modal presentation.
- `WeatherLocation.swift`: station model, curated station list, generated station factories, and station-level normal/solar dispatch.
- `WeatherService.swift`: NWS API wrapper for observations, hourly forecast, forecast discussion, and station metadata.
- `WeatherObservation.swift`: NWS decoding models and dashboard weather models.
- `WeatherMath.swift`: unit conversion, wet-bulb approximation, heat index, and dashboard chart bounds.
- `WeatherAlmanac.swift`: hard-coded curated-station Fourier climate functions, solar functions, extraterrestrial solar energy, normalized solar energy, and sun times.
- `GeneratedClimateProfile.swift`: generated-station climate model, Fourier series model, daily normal calculator, Gaussian smoothing, adaptive Fourier fitting, and generated profile creation.
- `GeneratedClimateProfileBuilder.swift`: async station-adder pipeline that combines NWS metadata, ACIS metadata, ACIS daily rows, and generated profile creation.
- `SavedGeneratedStation.swift`: Codable persistence model and UserDefaults store for generated stations.
- `StationAdderView.swift`: station-adder sheet with weather station field, optional climate station field, validation progress, generated profile preview, and add button.
- `ACISClimateService.swift`: ACIS data models, parsing, weather-year calculator, threshold season/risk calculators, and ACIS fetch functions.
- `ClimateGraphs.swift`: graph support models and `ChartHoverOverlay`.
- `ClimateGraphView.swift`: climate modal and all climate chart views.
- `ForecastDiscussion.swift`: forecast discussion product decoding models.

## App State Ownership

`ContentView` owns the main dashboard state:

- current `WeatherObservation`
- selected `WeatherLocation`
- live observation history and forecast arrays
- selected history duration
- dew point and heat index overlay toggles
- forecast discussion sheet state
- climate graph sheet state
- station adder sheet state
- `customLocations`, currently an in-memory array of generated `WeatherLocation` values

`ClimateGraphView` owns modal-specific state:

- selected climate point for hover
- ACIS threshold/weather-year observations
- threshold modes, selected thresholds, risk season, output mode
- selected weather year and overlays
- loaded ACIS station ID

`ClimateGraphView` also precomputes and stores `climatePoints` in its initializer. This is important for hover performance, especially for generated stations.

## Live Weather Flow

1. `ContentView.refreshWeather()` creates `WeatherService`.
2. It calls `fetchRecentObservations(stationID:hours:)`.
3. It calls `fetchHourlyForecast(latitude:longitude:)`.
4. Observed NWS Celsius values are converted to Fahrenheit.
5. Dew point and heat index values are attached to `TemperaturePoint`.
6. Forecast periods become future `TemperaturePoint` values.
7. The latest complete observation updates `WeatherObservation`.
8. If no complete observation is found, the app currently fills dashboard values with `0.0` and condition `"No live observation"`.

Forecasts are location-coordinate based, so a station can still show forecast points even when live observation values are incomplete.

## Dashboard Charting

The dashboard temperature chart combines observed history and forecast points over a symmetric time domain: selected hours backward and selected hours forward.

The Y-axis domain is computed from visible chart data:

- temperature is always included
- dew point is included only when enabled
- heat index is included only when enabled
- lower and upper bounds use base-5 rounding from `WeatherMath`

Hover is handled with `ChartHoverOverlay`, which converts chart coordinates back into values and selects the nearest `TemperaturePoint`.

## Curated Climate Handling

Curated stations use `ClimatologyProfile` and hard-coded climate functions in `WeatherAlmanac.swift`.

`WeatherLocation.normalHigh(dayOfYear:)`, `normalLow(dayOfYear:)`, `solarEnergy(dayOfYear:)`, and `normalizedSolarEnergy(dayOfYear:)` dispatch either to:

- the generated profile, if present, or
- the curated `WeatherAlmanac` functions.

## Generated Climate Handling

Generated station climate profiles are data-driven:

1. `GeneratedClimateProfileBuilder.buildProfile(...)` normalizes user input and chooses a final climate station ID.
2. NWS station metadata supplies live station name, coordinates, and time zone.
3. ACIS station metadata supplies climate station name and climate coordinates when available.
4. ACIS daily observations are fetched for 1991-01-01 through 2020-12-31.
5. `GeneratedClimateNormalCalculator.generatedProfile(...)` builds the profile.

The normal calculator does:

- maps each observation to a non-leap 365-day reference year
- drops Feb 29
- requires at least 20 valid high and low samples per calendar day
- requires all 365 daily normals
- applies cyclic Gaussian smoothing with default `sigma = 5.0` and `radius = 15`
- fits Fourier series for normal highs and lows
- tests orders 3 through 10 by default
- chooses the simplest order within 0.05 degrees F RMSE of the best order
- computes annual solar minimum and maximum from extraterrestrial solar geometry

`GeneratedClimateProfile` stores Fourier coefficients, fit order, RMSE values, source years, usable observation count, station metadata, and solar bounds.

## Solar Geometry

`WeatherAlmanac.eTSolarEnergy(dayOfYear:latitude:)` computes extraterrestrial solar energy in `kWh/m^2/day` using solar declination, inverse Earth-Sun distance, and sunset hour angle. It has `Double` and `Int` overloads.

`WeatherAlmanac.normalizedETSolarEnergy(...)` computes normalized solar values from the station latitude. Generated profiles cache solar min/max so `GeneratedClimateProfile.normalizedSolarEnergy(...)` does not need to recompute the annual min/max every call.

## Climate Modal

`ClimateGraphView` supports four graph types:

- Annual Temperature Curve: normal high and low curves, thermal midsommar/midwinter annotation, hover tooltip.
- Seasonal Hysteresis Curve: normalized solar vs normal low loop, arrows, SMI, MECD, hover tooltip.
- Threshold Seasons: ACIS-derived threshold dates and probability graph/table for cold nights, warm afternoons, warm afternoon lock-in, and mild nights.
- Weather for the Year: selected year observed ranges against normal and record overlays.

ACIS rows are lazy-loaded only when the selected climate graph needs them, and are reused between threshold seasons and weather-year views for the same `acisStationID`.

## Persistence Design In Current Repo

`SavedGeneratedStation.swift` exists and can encode/decode generated stations with `UserDefaults` key `savedGeneratedStations`.

`WeatherLocation.generated(from savedStation:)` exists and can rebuild a selectable `WeatherLocation` from saved data.

`ContentView` is not yet wired to use `SavedGeneratedStation` as the source of truth. It still has:

`@State private var customLocations: [WeatherLocation] = []`

and appends generated locations only for the current session.

## Design Decisions

- No-case enums are used as utility namespaces for stateless calculators and services.
- Climate normals are generated from daily observations rather than monthly normals.
- Gaussian smoothing is cyclic so Jan 1 can borrow signal from late December.
- Fourier fits are adaptive so stations with real winter wobble can use higher harmonics.
- Live weather station and ACIS climate station are allowed to differ.
- Generated profile data is intended to be persisted as coefficients and metadata, not recomputed every launch.
