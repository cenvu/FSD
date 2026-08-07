import SwiftUI

struct ComparisonCreationView: View {
    @ObservedObject var model: ComparisonWorkspaceModel

    var body: some View {
        HSplitView {
            historySidebar
            mainCreationPane
        }
    }

    private var historySidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Comparisons").font(.title3).padding(.horizontal, 12).padding(.top, 12)
            if model.history.isEmpty {
                EmptyStateView(
                    title: "No comparisons yet",
                    systemImage: "arrow.left.arrow.right",
                    detail: "Start a comparison to see history."
                )
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
            }
            Spacer()
        }
        .frame(minWidth: 300, idealWidth: 340)
    }

    private var mainCreationPane: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Comparison").font(.title)

            Picker("Mode", selection: $model.mode) {
                ForEach(ComparisonMode.allCases, id: \.self) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Comparison mode")
            .accessibilityHint("Left is the reference (before) side; right is the changed (after) side.")
            .padding(.bottom, 8)

            HStack(alignment: .top, spacing: 20) {
                sideSelector(title: "Reference (Left)", side: .left)
                sideSelector(title: "Changed (Right)", side: .right)
            }

            Picker("Profile", selection: $model.selectedProfileID) {
                Text("Select a Profile...").tag(Int64?.none)
                ForEach(model.profiles) { profile in
                    Text(profile.name).tag(Int64?.some(profile.id))
                }
            }
            .frame(maxWidth: 300)
            .accessibilityLabel("Comparison profile")

            HStack {
                Button("Start Comparison", action: model.start)
                    .disabled(!model.canStart || model.isRunning)
                    .accessibilityLabel("Start Comparison")
                    .accessibilityHint(model.validationMessage ?? "Compares the left reference side against the right changed side.")

                if model.isRunning {
                    Button("Cancel", action: model.cancel)
                        .accessibilityLabel("Cancel comparison")
                }
            }
            .padding(.top, 8)

            if let validation = model.validationMessage, !model.isRunning {
                Text(validation)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .accessibilityLabel("Start unavailable: \(validation)")
            }

            if model.isRunning {
                VStack(alignment: .leading) {
                    ProgressView()
                    Text(model.progress.phase).font(.caption).foregroundStyle(.secondary)
                    Text("\(model.progress.processedEntries) entries processed").font(.caption).foregroundStyle(.secondary)
                }
                .padding(.top, 8)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Comparison running — \(model.progress.phase), \(model.progress.processedEntries) entries processed")
            }

            if let terminal = model.terminalState {
                terminalStateView(terminal)
            }

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 560, maxWidth: .infinity)
    }

    @ViewBuilder
    private func sideSelector(title: String, side: ComparisonWorkspaceModel.Side) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.headline)
            Text(side == .left ? "Before / Reference" : "After / Changed")
                .font(.caption)
                .foregroundStyle(.secondary)

            if model.isLiveSelector(side) {
                Button("Choose Folder...") {
                    model.chooseLiveRoot(for: side)
                }
                .disabled(model.isRunning)
                .accessibilityLabel(side == .left ? "Choose live reference folder" : "Choose live changed folder")

                let selectedRoot = side == .left ? model.selectedLeftLiveRoot : model.selectedRightLiveRoot
                Text(selectedRoot?.path ?? "No folder selected")
                    .font(.caption)
                    .foregroundStyle(selectedRoot == nil ? .secondary : .primary)
                    .lineLimit(2)
                    .accessibilityLabel(selectedRoot?.path ?? "No folder selected")
            } else {
                let binding = side == .left ? $model.selectedLeftSnapshotID : $model.selectedRightSnapshotID
                Picker("Snapshot", selection: binding) {
                    Text("Select a Snapshot...").tag(SnapshotID?.none)
                    ForEach(model.availableSnapshots) { snap in
                        Text(snap.displayName).tag(SnapshotID?.some(snap.id))
                    }
                }
                .disabled(model.isRunning)
                .labelsHidden()
                .accessibilityLabel(side == .left ? "Reference snapshot (left)" : "Changed snapshot (right)")
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(NSColor.separatorColor), lineWidth: 1))
    }

    @ViewBuilder
    private func terminalStateView(_ state: ComparisonStatus) -> some View {
        HStack {
            let icon = state == .complete ? "checkmark.seal.fill" : (state == .cancelled ? "xmark.circle" : "exclamationmark.octagon")
            let color = state == .complete ? Color.green : (state == .cancelled ? Color.orange : Color.red)
            Image(systemName: icon).foregroundStyle(color)
            Text(state == .complete ? "Complete" : state.rawValue.capitalized).bold().foregroundStyle(color)
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(state == .complete ? "Comparison complete" : "Comparison \(state.rawValue)")
    }
}

struct ComparisonHistoryRow: View {
    let record: ComparisonRecord
    let onDelete: () -> Void
    @State private var showingDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(record.mode.label).font(.headline).lineLimit(1)
                Spacer()
                Button(action: { showingDeleteConfirmation = true }) {
                    Image(systemName: "trash").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete comparison")
            }
            Text("\(record.left.sourceDescription) → \(record.right.sourceDescription)")
                .font(.caption).lineLimit(2)

            HStack(spacing: 6) {
                Image(systemName: icon).foregroundStyle(tint)
                Text(statusText).foregroundStyle(tint)
                Text("·").foregroundStyle(.secondary)
                Text(record.startedAt).foregroundStyle(.secondary)
            }
            .font(.caption)
            Text("\(record.totalDifferences) differences (\(record.totalComparedEntries) total)")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
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
        case .complete: return .green
        case .running: return .secondary
        case .cancelled: return .orange
        case .failed: return .red
        }
    }
}
