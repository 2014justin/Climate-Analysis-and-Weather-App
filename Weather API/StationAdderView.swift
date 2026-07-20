import SwiftUI

struct StationAdderView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var stationID: String
    @State private var climateStationID = ""
    @State private var isValidating = false
    @State private var validationMessage = "Enter a station ID such as KBIL."
    @State private var buildResult: GeneratedStationBuildResult?
    @State private var candidateSearchResult:
        GeneratedClimateCandidateSearchResult?
    
    @State private var selectedCandidateStationID: String?
    @State private var validatedStationSource: AtlasStationSource?
    @FocusState private var stationFieldIsFocused: Bool
    
    let onAdd: (GeneratedStationBuildResult) -> Void
    
    private let initialStationSource: AtlasStationSource?
    
    ///Creates the initializer ContentView is trying to call.
    init(
        initialStationSource:
            AtlasStationSource? = nil,
        onAdd: @escaping (
            GeneratedStationBuildResult
        ) -> Void
    ) {
        self.initialStationSource =
            initialStationSource
        
        _stationID = State(
            initialValue:
                initialStationSource?
                    .stationID
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .uppercased()
                ?? ""
        )
        
        self.onAdd = onAdd
    }
    
    private func stationSource(
        for safeStationID: String
    ) -> AtlasStationSource {
        let originalStationID =
            initialStationSource?
                .stationID
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
        
        if let initialStationSource,
           originalStationID == safeStationID {
            return initialStationSource
        }
        
        /// Manually-entered IDs retain the existing US-station behavior
        ///
        return AtlasStationSource(
            countryCode: "US",
            providerID: "manualEntry",
            stationID: safeStationID
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Add Station")
                        .font(.title2)
                        .bold()

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut("w", modifiers: .command)
                }

                TextField("Station ID", text: $stationID)
                    .textFieldStyle(.roundedBorder)
                    .focused($stationFieldIsFocused)
                    .disabled(isValidating)
                
                TextField("Climate station ID, optional, e.g. USC00485345", text: $climateStationID)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isValidating)
                    .keyboardShortcut(.cancelAction)

                HStack {
                    if candidateSearchResult == nil
                        && buildResult == nil {
                        validationButton
                            .keyboardShortcut(.defaultAction)
                    } else {
                        validationButton
                    }

                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isValidating)
                }

                HStack(spacing: 8) {
                    if isValidating {
                        ProgressView()
                            .controlSize(.small)
                    }
                    
                    Text(validationMessage)
                        .foregroundStyle(.secondary)
                }
                
                if let candidateSearchResult,
                   candidateSearchResult.candidates.isEmpty == false {
                    candidateSelectionSection(
                        candidateSearchResult
                    )
                }

                if let buildResult {
                    let generatedProfile = buildResult.profile
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text(generatedProfile.displayName)
                            .font(.headline)

                        Text("Station: \(generatedProfile.stationID)")
                        Text("Latitude: \(generatedProfile.latitude, specifier: "%.4f")")
                        Text("Longitude: \(generatedProfile.longitude, specifier: "%.4f")")
                        Text("Fit order: \(generatedProfile.fitOrder)")
                        Text("High RMSE: \(generatedProfile.highRMSE, specifier: "%.2f") °F")
                        Text("Low RMSE: \(generatedProfile.lowRMSE, specifier: "%.2f") °F")
                        Text("Source: \(String(generatedProfile.sourceStartYear))-\(String(generatedProfile.sourceEndYear))")
                    }
                    .monospacedDigit()
                    
                    Button("Add Station") {
                        onAdd(buildResult)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding()
        }
        .frame(width: 560, height: 680)
        .background(DashboardTheme.panel)
        .onAppear {
            /// Focus the  field only when the ordinary blank Add Sation sheet was opened.
            /// Makes it easy to build a climate profile upon selection in the Atlas.
            stationFieldIsFocused = stationID.isEmpty
        }
        .task {
            /// An Atlas station arrives prefilled, so begin its validation workflow automatically
            guard !stationID.isEmpty else {
                return
            }
            
            await validateStation()
        }
    }
    
    private var validationButton: some View {
        Button(
            isValidating
                ? "Validating ..."
                : "Validate Station"
        ) {
            Task {
                await validateStation()
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(
            isValidating
            || stationID
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
        )
    }
    
    private func candidateSelectionSection(
        _ searchResult: GeneratedClimateCandidateSearchResult
    ) -> some View {
        

        let recommendedStationID =
            searchResult.candidates.first?
                .stationID

        return VStack(alignment: .leading, spacing: 10) {
            Divider()

            Text("Climate matches for \(searchResult.displayName)")
                .font(.headline)

            Text(
                "Select the long-term climate record "
                + "that should represent this weather station."
            )
            .font(.caption)
            .foregroundStyle(DashboardTheme.textSecondary)

            ForEach(
                searchResult.candidates,
                id: \.stationID
            ) { candidate in
                candidateSelectionRow(
                    candidate,
                    isRecommended:
                        candidate.stationID
                        == recommendedStationID
                )
            }

            
            Button {
                Task {
                    await addSelectedCandidate()
                }
            } label: {
                HStack(spacing: 8) {
                    if isValidating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    
                    Text(
                        isValidating
                            ? "Building Climate Profile..."
                            : "Build Station"
                    )
                    .bold()
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .disabled(
                isValidating
                || selectedCandidateStationID == nil
            )
            .padding(.top, 4)
        }
    }
    
    private func qualityColor(
        for rating: GeneratedClimateStationQualityRating
    ) -> Color {
        switch rating {
        case .excellent, .good:
            return DashboardTheme.success
            
        case .acceptable:
            return DashboardTheme.normal
            
        case .marginal:
            return .orange
            
        case .poor:
            return DashboardTheme.failure
        }
    }
    
    private func candidateSelectionRow(
        _ candidate:
            GeneratedClimateStationCandidate,
        isRecommended: Bool
    ) -> some View {
        let isSelected =
            selectedCandidateStationID
            == candidate.stationID

        let stationName =
            candidate.displayName

        let completeness =
            candidate.pairedCompleteness
                .formatted(
                    .percent.precision(
                        .fractionLength(1)
                    )
                )

        return Button {
            selectedCandidateStationID =
                candidate.stationID
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(
                    systemName: isSelected
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .font(.title3)
                .foregroundStyle(
                    isSelected
                        ? Color.accentColor
                        : DashboardTheme.textSecondary
                )

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(stationName)
                            .font(.headline)

                        Spacer()

                        if isRecommended {
                            Text("RECOMMENDED")
                                .font(.caption2)
                                .bold()
                                .foregroundStyle(
                                    Color.accentColor
                                )
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background {
                                    Capsule()
                                        .fill(
                                            Color.accentColor
                                                .opacity(0.15)
                                        )
                                }
                        }
                    }

                    HStack(spacing: 5) {
                        if let administrativeAreaCode =
                                candidate.administrativeAreaCode {
                            Text(administrativeAreaCode)
                            Text("•")
                        }

                        Text(candidate.stationID)
                            .monospaced()
                    }
                    .font(.caption)
                    .foregroundStyle(
                        DashboardTheme.textSecondary
                    )

                    Text(
                        candidate.qualityRating
                            .rawValue.capitalized
                        + " · \(completeness) complete"
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        qualityColor(
                            for: candidate.qualityRating
                        )
                    )

                    HStack(spacing: 5) {
                        Text(
                            "\(candidate.distanceMiles, specifier: "%.1f") mi away"
                        )

                        if let elevationDifference =
                                candidate.elevationDifferenceFeet {
                            Text("•")

                            Text(
                                "\(elevationDifference, specifier: "%.0f") ft elevation difference"
                            )
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(
                        DashboardTheme.textSecondary
                    )
                }
            }
            .padding(12)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(
                    cornerRadius:
                        DashboardTheme.cardCornerRadius
                )
                .fill(
                    isSelected
                        ? Color.accentColor.opacity(0.14)
                        : DashboardTheme.plotArea
                )
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius:
                        DashboardTheme.cardCornerRadius
                )
                .stroke(
                    isSelected
                        ? Color.accentColor.opacity(0.8)
                        : DashboardTheme.border,
                    lineWidth: isSelected ? 1.5 : 1
                )
            }
        }
        .buttonStyle(.plain)
        .disabled(isValidating)
    }
    
    @MainActor
    private func addSelectedCandidate() async {
        guard candidateSearchResult != nil,
              let selectedCandidateStationID,
                let validatedStationSource
        else {
            validationMessage =
                "Select a climate station before adding."
            return
        }
        
        isValidating = true
        validationMessage =
            "Building climate profile for "
            + selectedCandidateStationID
            + "..."
        
        defer {
            isValidating = false
        }
        
        do {
            guard let result =
                    try await GeneratedClimateProfileBuildRouter
                        .buildProfile(
                            for: validatedStationSource,
                            climateStationID: selectedCandidateStationID,
                            progress: { message in
                                validationMessage = message
                            }
                        )
            else {
                validationMessage =
                    selectedCandidateStationID
                    + " did not produce 365" + "daily normals."
                return
            }
            
            onAdd(result)
            dismiss()
        } catch {
            validationMessage =
                selectedCandidateStationID
                + " failed: "
                + error.localizedDescription
        }
    }

    private func validateStation() async {
            let safeStationID = stationID
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()

            guard safeStationID.isEmpty == false else {
                validationMessage = "Enter a station ID."
                return
            }
        
            let source = stationSource(for: safeStationID)
        
            validatedStationSource = source

            isValidating = true
            buildResult = nil
            candidateSearchResult = nil
            selectedCandidateStationID = nil
            validationMessage = "Validating \(safeStationID)..."

            defer {
                isValidating = false
            }

            do {
                let safeClimateStationID = climateStationID
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .uppercased()
                
                if safeClimateStationID.isEmpty {
                    let searchResult =
                        try await GeneratedClimateProfileBuildRouter
                            .findClimateCandidates(
                                for: source,
                                progress: { message in
                                    validationMessage = message
                                }
                            )
                    
                    candidateSearchResult = searchResult
                    selectedCandidateStationID =
                        searchResult.candidates.first?
                            .stationID
                    
                    if let recommendedCandidate =
                            searchResult.candidates.first {
                        let candidateCount =
                            searchResult.candidates.count

                        validationMessage =
                            "Found \(candidateCount) climate matches. "
                            + "Recommended: "
                            + recommendedCandidate.stationID
                            + "."
                    } else {
                        validationMessage =
                            "No qualifying 1991–2020 climate stations "
                            + "were found within 100 miles."
                    }
                    return
                }
                
                if let result =
                    try await GeneratedClimateProfileBuildRouter
                        .buildProfile(
                            for: source,
                            climateStationID: safeClimateStationID,
                            progress: { message in
                                validationMessage = message
                            }
                        ) {
                    buildResult = result
                    validationMessage = "Valid climate profile found."
                } else {
                    validationMessage = "\(safeStationID) loaded but did not produce 365 usable daily normals."
                }
            } catch {
                validationMessage = "\(safeStationID) failed: \(error.localizedDescription)"
            }
        }
    }
