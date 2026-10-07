import SwiftUI

struct ComparisonCreationView: View {
    @ObservedObject var model: ComparisonWorkspaceModel

    var body: some View {
        HSplitView {
            historySidebar
            mainCreationPane
        }
        .background(FSDDesignTokens.window)
        .foregroundStyle(FSDDesignTokens.primaryText)
        .tint(FSDDesignTokens.accent)
    }

    private var historySidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Recent Comparisons")
                        .font(.system(size: FSDDesignTokens.sectionTitleSize, weight: .semibold))
                        .foregroundStyle(FSDDesignTokens.primaryText)
                    Spacer(minLength: 8)
                    Text("\(model.history.count)")
                        .font(.system(size: FSDDesignTokens.labelSize, weight: .medium))
                        .foregroundStyle(FSDDesignTokens.mutedText)
                }
                Text("Saved comparison history")
                    .font(.system(size: FSDDesignTokens.overviewSubtitleSize))
                    .foregroundStyle(FSDDesignTokens.secondaryText)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Rectangle().fill(FSDDesignTokens.separator).frame(height: 1)

            if model.history.isEmpty {
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundStyle(FSDDesignTokens.accent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No comparisons yet")
                            .font(.system(size: FSDDesignTokens.bodySize, weight: .semibold))
                            .foregroundStyle(FSDDesignTokens.primaryText)
                        Text("Start a comparison to see history.")
                            .font(.system(size: FSDDesignTokens.bodySize))
                            .foregroundStyle(FSDDesignTokens.secondaryText)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                List(model.history, id: \.id) { record in
                    ComparisonHistoryRow(record: record, onDelete: {
                        model.deleteComparison(record)
                    })
                    .contentShape(Rectangle())
                    .onTapGesture {
                        model.openComparison(record)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .listRowInsets(EdgeInsets(top: 5, leading: 12, bottom: 5, trailing: 12))
                .listRowSeparatorTint(FSDDesignTokens.separator)
                .background(FSDDesignTokens.window)
            }
            Spacer()
        }
        .frame(minWidth: 300, idealWidth: 360)
        .background(FSDDesignTokens.window)
    }

    private var mainCreationPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("New Comparison")
                        .font(.system(size: FSDDesignTokens.overviewTitleSize, weight: .semibold))
                        .foregroundStyle(FSDDesignTokens.primaryText)
                    Text("Choose the source for each side and compare metadata.")
                        .font(.system(size: FSDDesignTokens.overviewSubtitleSize))
                        .foregroundStyle(FSDDesignTokens.secondaryText)
                }

                VStack(alignment: .leading, spacing: 8) {
                    fieldLabel("COMPARISON MODE")
                    HStack(spacing: 2) {
                        ForEach(ComparisonMode.allCases, id: \.self) { mode in
                            Button {
                                model.mode = mode
                            } label: {
                                Text(mode.label)
                                    .font(.system(size: FSDDesignTokens.bodySize, weight: model.mode == mode ? .semibold : .medium))
                                    .foregroundStyle(model.mode == mode ? FSDDesignTokens.primaryText : FSDDesignTokens.secondaryText)
                                    .frame(maxWidth: .infinity, minHeight: 32)
                                    .background(
                                        model.mode == mode ? FSDDesignTokens.selected : .clear,
                                        in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius)
                                    )
                                    .contentShape(RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(mode.label)
                            .accessibilityAddTraits(model.mode == mode ? .isSelected : [])
                        }
                    }
                    .padding(3)
                    .background(FSDDesignTokens.inset, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
                    .overlay(RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius).stroke(FSDDesignTokens.separator, lineWidth: 1))
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Comparison mode")
                    .accessibilityHint("Left is the reference (before) side; right is the changed (after) side.")
                }

                HStack(alignment: .top, spacing: 12) {
                    sideSelector(side: .left)
                    sideSelector(side: .right)
                }

                VStack(alignment: .leading, spacing: 8) {
                    fieldLabel("PROFILE")
                    profileSelector
                }

                HStack(spacing: 10) {
                    Button(action: model.start) {
                        Label("Start Comparison", systemImage: "arrow.left.arrow.right")
                    }
                    .buttonStyle(FSDPrimaryActionButtonStyle())
                    .disabled(!model.canStart || model.isRunning)
                    .accessibilityLabel("Start Comparison")
                    .accessibilityHint(model.validationMessage ?? "Compares the left reference side against the right changed side.")

                    if model.isRunning {
                        Button("Cancel", action: model.cancel)
                            .buttonStyle(FSDSecondaryActionButtonStyle())
                            .accessibilityLabel("Cancel comparison")
                    }

                    if let validation = model.validationMessage, !model.isRunning {
                        Label(validation, systemImage: "info.circle")
                            .font(.system(size: FSDDesignTokens.bodySize))
                            .foregroundStyle(FSDDesignTokens.warning)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityLabel("Start unavailable: \(validation)")
                    }
                }

                if model.isRunning {
                    VStack(alignment: .leading, spacing: 7) {
                        ProgressView().tint(FSDDesignTokens.accent)
                        Text(model.progress.phase)
                            .font(.system(size: FSDDesignTokens.bodySize))
                            .foregroundStyle(FSDDesignTokens.secondaryText)
                        Text("\(model.progress.processedEntries) entries processed")
                            .font(.system(size: FSDDesignTokens.labelSize))
                            .foregroundStyle(FSDDesignTokens.mutedText)
                    }
                    .padding(.top, 4)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Comparison running — \(model.progress.phase), \(model.progress.processedEntries) entries processed")
                }

                if let terminal = model.terminalState {
                    terminalStateView(terminal)
                }
            }
            .padding(.horizontal, FSDDesignTokens.pageInsetHorizontal)
            .padding(.top, FSDDesignTokens.pageInsetTop)
            .padding(.bottom, FSDDesignTokens.pageInsetBottom)
            .frame(maxWidth: 940, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 560, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(FSDDesignTokens.window)
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: FSDDesignTokens.labelSize, weight: .semibold))
            .tracking(0.7)
            .foregroundStyle(FSDDesignTokens.mutedText)
    }

    @ViewBuilder
    private func sideSelector(side: ComparisonWorkspaceModel.Side) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            VStack(alignment: .leading, spacing: 4) {
                fieldLabel(side == .left ? "REFERENCE · LEFT" : "CHANGED · RIGHT")
                Text(side == .left ? "Before / Reference" : "After / Changed")
                    .font(.system(size: FSDDesignTokens.bodySize))
                    .foregroundStyle(FSDDesignTokens.secondaryText)
            }

            if model.isLiveSelector(side) {
                Button(action: { model.chooseLiveRoot(for: side) }) {
                    Label("Choose Folder…", systemImage: "folder")
                }
                .buttonStyle(FSDSecondaryActionButtonStyle())
                .disabled(model.isRunning)
                .accessibilityLabel(side == .left ? "Choose live reference folder" : "Choose live changed folder")

                let selectedRoot = side == .left ? model.selectedLeftLiveRoot : model.selectedRightLiveRoot
                Text(selectedRoot?.lastPathComponent ?? "No folder selected")
                    .font(.system(size: FSDDesignTokens.bodySize))
                    .foregroundStyle(selectedRoot == nil ? FSDDesignTokens.secondaryText : FSDDesignTokens.primaryText)
                    .lineLimit(2)
                    .accessibilityLabel(selectedRoot?.lastPathComponent ?? "No folder selected")
            } else {
                snapshotSelector(side: side)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FSDDesignTokens.panel, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius).stroke(FSDDesignTokens.separator, lineWidth: 1))
    }

    private var profileSelector: some View {
        let selectedProfile = model.profiles.first { $0.id == model.selectedProfileID }

        return Menu {
            if model.profiles.isEmpty {
                Text("No comparison profiles available")
            } else {
                ForEach(model.profiles) { profile in
                    Button {
                        model.selectedProfileID = profile.id
                    } label: {
                        if profile.id == model.selectedProfileID {
                            Label(profile.name, systemImage: "checkmark")
                        } else {
                            Text(profile.name)
                        }
                    }
                }
            }
        } label: {
            selectorMenuLabel(selectedProfile?.name ?? "Select a Profile…")
        }
        .buttonStyle(.plain)
        .disabled(model.isRunning)
        .accessibilityLabel("Comparison profile")
        .accessibilityHint(selectedProfile?.name ?? "Select a comparison profile.")
    }

    private func snapshotSelector(side: ComparisonWorkspaceModel.Side) -> some View {
        let binding = side == .left ? $model.selectedLeftSnapshotID : $model.selectedRightSnapshotID
        let selectedSnapshot = model.availableSnapshots.first { $0.id == binding.wrappedValue }

        return Menu {
            if selectedSnapshot != nil {
                Button("Clear Selection", systemImage: "xmark") {
                    binding.wrappedValue = nil
                }
                Divider()
            }
            if model.availableSnapshots.isEmpty {
                Text("No completed snapshots available")
            } else {
                ForEach(model.availableSnapshots) { snapshot in
                    Button {
                        binding.wrappedValue = snapshot.id
                    } label: {
                        if snapshot.id == selectedSnapshot?.id {
                            Label(snapshot.displayName, systemImage: "checkmark")
                        } else {
                            Text(snapshot.displayName)
                        }
                    }
                }
            }
        } label: {
            selectorMenuLabel(selectedSnapshot?.displayName ?? "Select a Snapshot…")
        }
        .buttonStyle(.plain)
        .disabled(model.isRunning)
        .accessibilityLabel(side == .left ? "Reference snapshot (left)" : "Changed snapshot (right)")
        .accessibilityHint(selectedSnapshot?.displayName ?? "Select a completed snapshot.")
    }

    private func selectorMenuLabel(_ title: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: FSDDesignTokens.bodySize))
                .foregroundStyle(FSDDesignTokens.primaryText)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 4)
            Image(systemName: "chevron.down")
                .font(.system(size: FSDDesignTokens.labelSize, weight: .semibold))
                .foregroundStyle(FSDDesignTokens.mutedText)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
        .background(FSDDesignTokens.inset, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius).stroke(FSDDesignTokens.separator, lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
    }

    @ViewBuilder
    private func terminalStateView(_ state: ComparisonStatus) -> some View {
        HStack {
            let icon = state == .complete ? "checkmark.seal.fill" : (state == .cancelled ? "xmark.circle" : "exclamationmark.octagon")
            let color = state == .complete ? FSDDesignTokens.success : (state == .cancelled ? FSDDesignTokens.warning : FSDDesignTokens.destructive)
            Image(systemName: icon).foregroundStyle(color)
            Text(state == .complete ? "Complete" : state.rawValue.capitalized).bold().foregroundStyle(color)
        }
        .font(.system(size: FSDDesignTokens.bodySize))
        .padding(.top, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(state == .complete ? "Comparison complete" : "Comparison \(state.rawValue)")
    }
}

struct ComparisonHistoryRow: View {
    let record: ComparisonRecord
    let onDelete: () -> Void
    @State private var showingDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(record.mode.label)
                    .font(.system(size: FSDDesignTokens.bodySize, weight: .semibold))
                    .foregroundStyle(FSDDesignTokens.primaryText)
                    .lineLimit(1)
                Spacer()
                Button(action: { showingDeleteConfirmation = true }) {
                    Image(systemName: "trash").foregroundStyle(FSDDesignTokens.mutedText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete comparison")
                .help("Delete comparison")
            }
            Text("\(record.left.sourceDescription) → \(record.right.sourceDescription)")
                .font(.system(size: FSDDesignTokens.labelSize))
                .foregroundStyle(FSDDesignTokens.secondaryText)
                .lineLimit(2)

            HStack(spacing: 6) {
                Image(systemName: icon).foregroundStyle(tint)
                Text(statusText).foregroundStyle(tint)
                Text("·").foregroundStyle(FSDDesignTokens.mutedText)
                Text(record.startedAt).foregroundStyle(FSDDesignTokens.secondaryText)
            }
            .font(.system(size: FSDDesignTokens.labelSize))
            Text("\(record.totalDifferences) differences (\(record.totalComparedEntries) total)")
                .font(.system(size: FSDDesignTokens.labelSize))
                .foregroundStyle(FSDDesignTokens.mutedText)
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(record.mode.label) — \(record.left.sourceDescription) to \(record.right.sourceDescription) — \(statusText), \(record.totalDifferences) differences")
        .confirmationDialog(
            "Delete Comparison?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Comparison", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The comparison result will be removed. Referenced ordinary snapshots remain. Live transient evidence follows the canonical lifecycle.")
        }
    }

    private var statusText: String {
        switch record.status {
        case .complete: return "Complete"
        case .running: return "Running"
        case .cancelled: return "Cancelled"
        case .failed: return "Failed"
        }
    }

    private var icon: String {
        switch record.status {
        case .complete: return "checkmark.seal"
        case .running: return "clock"
        case .cancelled: return "xmark.circle"
        case .failed: return "exclamationmark.octagon"
        }
    }

    private var tint: Color {
        switch record.status {
        case .complete: return FSDDesignTokens.success
        case .running: return FSDDesignTokens.accent
        case .cancelled: return FSDDesignTokens.warning
        case .failed: return FSDDesignTokens.destructive
        }
    }
}
