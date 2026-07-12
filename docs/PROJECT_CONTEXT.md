# Project Context

## Purpose

Weather API is a SwiftUI macOS app that combines live National Weather Service weather data with deeper climatology tools. The app is both a learning project and a serious weather/climate workstation for exploring station-level conditions, normals, seasonal timing, and risk windows.

The guiding idea is: choose a station, see current weather and forecast history, then open climate views that explain the station's annual thermal behavior.

## Main User-Facing Features

- Weather dashboard with station picker, live current conditions, and a temperature history/forecast chart.
- Optional chart overlays for dew point and heat index.
- Dynamic base-5 Y-axis scaling for the dashboard chart, including dew point and heat index when enabled.
- NWS forecast discussion viewer.
- Climate graph modal with multiple views:
  - Annual Temperature Curve
  - Seasonal Hysteresis Curve
  - Threshold Seasons
  - Weather for the Year
- Chart hover tools for dashboard and climate charts.
- Export commands for CSV, JPG, and PDF.
- Keyboard shortcuts for refresh, history duration, climate graph, forecast discussion, overlays, exports, and curated stations.
- Station adder in progress: enter a live weather station and optional separate climate station, validate, generate climate normals, and add it to the station picker.

## Weather And Climate Terminology

- `Weather station`: the live observation station used for recent observations from `api.weather.gov/stations/{id}/observations`.
- `Climate station`: the ACIS station used for historical daily data and 1991-2020 normals. It can differ from the live weather station.
- `Tmax(t)` and `Tmin(t)`: Fourier-fitted daily normal high and low temperature curves.
- `S(t)`: extraterrestrial daily solar energy in `kWh/m^2/day`, computed from solar geometry.
- `s(t)`: normalized solar energy, `(S(t) - Smin) / (Smax - Smin)`.
- `Thermal midsommar`: warm-season window based on the upper part of the annual normal-low curve.
- `Thermal midwinter`: cold-season window based on the lower part of the annual normal-low curve.
- `Seasonal hysteresis`: phase-space plot of normalized solar energy against normal low temperature.
- `SMI`: Seasonal Memory Index, currently computed as the loop area-like integral of normal low temperature against normalized solar energy.
- `MECD`: Maximum Eigendate Chord Depth, the largest cool-branch vs warm-branch normal-low separation at matched normalized solar.

## Integrations

The app currently uses two remote data sources:

- NWS API (`api.weather.gov`) for live observations, hourly forecasts, station metadata, and forecast discussion products.
- ACIS/RCC API (`data.rcc-acis.org`) for station metadata and daily historical observations (`mint`, `maxt`, `pcpn`, `snow`, `snwd`).

## Station System

Curated stations are defined statically in `WeatherLocation.swift`. Generated stations are being added through `StationAdderView.swift`, `GeneratedClimateProfileBuilder.swift`, `GeneratedClimateProfile.swift`, and `SavedGeneratedStation.swift`.

The current generated-station flow supports:

1. User enters a weather station ID.
2. User may optionally enter a separate ACIS climate station ID.
3. NWS metadata provides the live station name, coordinates, and time zone.
4. ACIS metadata provides climate station name and coordinates when available.
5. ACIS 1991-2020 daily rows are fetched.
6. Daily normals are generated, Gaussian-smoothed, Fourier-fitted, and packed into a `GeneratedClimateProfile`.
7. The generated station can be added to the picker for the current app session.

Persistence scaffolding now exists, but `ContentView` has not yet been fully wired to load/save generated stations.

## Long-Term Goals

- Replace manual station discovery with a native NWS-style station map, not a browser wrapper.
- Let users click live stations on a map, pair them with climate stations when needed, and generate climate profiles automatically.
- Improve station pairing for cases where live NWS stations and long-term climate stations are not the same physical site.
- Add a climate table summary similar to Wikipedia climate tables.
- Add station removal/management UI and persistent custom stations.
- Continue improving graph polish, hover performance, and handling of stations with partial live observations.
