# Current Status

## Repository State

The active repository is:

`/Users/justinac/Documents/Weather API`

The worktree is dirty with in-progress app changes. At handoff time, `git status --short` showed modified Swift files and added/generated station-adder files, plus modified Xcode user state files. Do not assume a clean commit.

Recent commits visible in `git log --oneline -5`:

- `02d02a8 Add full-featured Weather Year viewer`
- `eabce0d Add threshold chart hover polish`
- `4aed90b Generalize ACIS threshold climate modes`
- `8e4dc1f Add ACIS threshold probability charts`
- `71ef3fe Add ACIS climate data parsing foundation`

Build state was not re-verified by Codex during this documentation handoff. The owner previously reported successful Xcode builds after the generated-station and performance changes.

## Recently Completed Work

- Added generated climate profile types and calculator.
- Added ACIS 1991-2020 daily-observation pipeline for generated stations.
- Added cyclic Gaussian smoothing for daily normals.
- Added adaptive Fourier fitting for normal high and low curves, including support for higher-order winter wobble behavior.
- Added extraterrestrial solar energy `S(t)` and normalized `s(t)` for generated stations.
- Added NWS station metadata lookup for generated station latitude, longitude, name, and time zone.
- Added optional separate climate station ID in the station adder.
- Added station-adder sheet with validation progress messages and generated profile preview.
- Added `SavedGeneratedStation` and `GeneratedStationStore` scaffolding.
- Added `WeatherLocation.generated(from result:)` and `WeatherLocation.generated(from savedStation:)`.
- Fixed annual temperature and seasonal hysteresis hover lag by caching `climatePoints` in `ClimateGraphView` and avoiding redundant hover state updates.
- Fixed dashboard chart Y-axis domain so dew point and heat index are included when those overlays are enabled.
- Removed the temporary KBIL test button/function from the dashboard, according to the owner's report.

## Current In-Progress Feature

Custom station persistence and station management UI are halfway started.

Already present:

- `SavedGeneratedStation`
- `GeneratedStationStore.load()`
- `GeneratedStationStore.save(_:)`
- `WeatherLocation.generated(from savedStation:)`

Not yet wired:

- `ContentView` still stores generated stations in `customLocations: [WeatherLocation]`.
- Generated stations are not loaded from `UserDefaults` on app launch.
- New generated stations are not saved to `UserDefaults` when added.
- The blue plus button has not yet been replaced with an ellipsis menu.
- Remove-current-generated-station action and confirmation alert are not yet implemented.

Recommended next small step:

Convert `ContentView` from in-memory `customLocations` to saved generated stations:

- add `@State private var savedGeneratedStations: [SavedGeneratedStation] = []`
- make `customLocations` a computed array from `savedGeneratedStations.map(WeatherLocation.generated(from:))`
- load saved stations on appear/task
- save after adding a generated station
- replace the plus button with a compact station management menu containing `Add Station...` and `Remove Current Station`

## Known Bugs And Rough Edges

- Generated stations have `forecastDiscussionOffice: ""`. Pressing "Show Forecast Discussion" for a generated station can request an invalid forecast discussion URL. Disable the button or store/derive the office before enabling it.
- If no complete live observation is found, dashboard numeric values are currently displayed as `0.0`. This is misleading; prefer `--`, `Unavailable`, or optional display rows.
- `isBuildingGeneratedClimateProfile` exists in `ContentView` but appears unused.
- `SavedGeneratedStation.swift` has a comment saying `__` when it means a single underscore `_` for an unlabeled parameter.
- Generated station persistence uses `UserDefaults`; this is fine for now, but a later app with many generated profiles may want a small file store.
- Forecast discussion office IDs are curated manually for built-in stations and absent for generated stations.
- ACIS normal generation currently requires 365 usable daily normals with at least 20 samples per calendar day. Some valid but sparse stations, such as the Fort Yukon attempt, fail this requirement.
- Live and climate station pairing is manual. The app does not yet discover nearby long-term climate stations.
- The source contains many learning comments. Preserve them unless the owner asks for cleanup.

## Important Decisions From The Conversation

- Justin wants to learn Swift by typing code himself. Future agents should provide exact, small edits and explain why.
- The station adder should support non-`K` weather and climate station codes.
- Weather station and climate station should be separate fields because live NWS stations and long-term climate stations often differ.
- If the climate station field is blank, the builder should use the weather station ID for climate data.
- Generated station keyboard shortcuts are not necessary.
- The plus button should become a compact station management menu with add/remove actions.
- Station removal should not be a separate minus button next to the picker.
- Built-in curated stations should not be removable.
- Long-term station-map work is deferred. The desired future version is a native in-app station map with live station observations, not a browser wrapper.
- Dynamic nearby climate-station search is also deferred.

## Useful Test Examples

Known working or useful station-pair patterns discussed:

- Billings: weather `KBIL`, blank climate field or `KBIL`
- Phoenix Sky Harbor: weather `KPHX`, blank climate field or matching climate ID if needed
- Yellowstone Lake: weather `KP60`, climate `USC00485345`

Known stubborn/failure examples:

- Fort Yukon: weather `PFYU`, climate `USS0045R01S` did not produce 365 usable normals under the current 20-sample/day requirement.
- Yellowstone attempts such as `A3792`, `UUYNB`, `KP60`, and `OFAW4` were confusing until separating live weather station from climate station; `KP60` plus `USC00485345` worked.

## Next Intended Steps

1. Finish persistence wiring in `ContentView`.
2. Replace the plus button with an ellipsis station management menu.
3. Add remove-current-generated-station with a confirmation alert.
4. Disable or handle forecast discussion for generated stations without a valid office.
5. Improve no-live-observation display so missing values do not appear as zeros.
6. Continue UI polish before starting the larger native station-map feature.

## Larger Future Work

- Native weather/hazards station map with live observations.
- Climate-station pairing/search around a selected weather station.
- Climate summary table similar to Wikipedia climate tables.
- Better generated-station persistence and possible import/export of custom station profiles.
- More robust tests or small verification utilities for generated normals, Fourier RMSE, and solar energy.
