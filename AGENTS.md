# Agent Instructions

This project is a SwiftUI macOS weather and climate app, and the owner is using it to learn Swift while building a real tool. Treat the collaboration as guided pair programming.

## How To Work With Justin

- Justin wants to type most Swift code himself. Unless he explicitly authorizes direct implementation, do not edit Swift source files or one-shot entire features.
- Before giving code, inspect the current repository and anchor advice to the actual files and line locations.
- Give one manageable change at a time. Prefer small, testable steps that can be built with Command-R in Xcode before moving on.
- Explain the reasoning behind each change, especially Swift concepts such as `@State`, `Binding`, optionals, `Codable`, `Equatable`, enum-as-namespace patterns, async functions, closures, guards, and computed properties.
- Preserve working behavior. Avoid large refactors while a feature is midstream unless the owner asks for one.
- If a bug appears, diagnose from the current code before proposing edits. Do not guess from memory.
- Keep UI changes consistent with the existing compact macOS dashboard style.
- It is acceptable to add or update Markdown documentation directly when requested.

## Source-Editing Rule

Do not modify application Swift source code during documentation or planning tasks. For feature work, default to instruction-first: identify the file, the approximate location, the exact code to add or replace, and why it works. Only directly edit Swift after explicit permission.

## Project Path

The active project is:

`/Users/justinac/Documents/Weather API`

The app source folder is:

`/Users/justinac/Documents/Weather API/Weather API`

The Xcode project uses a filesystem-synchronized source group, so Swift files in the app source folder are included without old-style per-file entries in `project.pbxproj`.

## Build Habit

After each small change, ask Justin to build/run in Xcode. If reporting build status in a handoff, distinguish between a user-reported successful build and a build that Codex personally verified.
