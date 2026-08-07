import SwiftUI

struct ComparisonWorkspaceView: View {
    @ObservedObject var model: ComparisonWorkspaceModel

    var body: some View {
        if let browser = model.activeBrowser {
            ComparisonBrowserView(workspace: model, browser: browser)
                .id(browser.record.id)
        } else {
            EmptyStateView(
                title: "No Comparison Selected",
                systemImage: "arrow.left.arrow.right",
                detail: "Select or start a comparison."
            )
        }
    }
}

struct ComparisonBrowserView: View {
    @ObservedObject var workspace: ComparisonWorkspaceModel
    @ObservedObject var browser: ComparisonBrowserModel

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button(action: { workspace.closeComparison() }) {
                    Image(systemName: "chevron.left")
                    Text("Back to Creation")
                }
                .padding(.trailing, 8)
                .accessibilityLabel("Back to creation — close comparison workspace")

                Picker("Filter", selection: $browser.activeFilter) {
                    ForEach(ComparisonResultFilter.allCases, id: \.self) { filter in
                        Text(filter.label).tag(filter)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 200)
                .accessibilityLabel("Result filter")

                Spacer()

                // Summary counts — every canonical outcome category is visible.
                HStack(spacing: 12) {
                    summaryPill(title: "All", count: browser.record.totalComparedEntries, color: .secondary)
                    summaryPill(title: "Differences", count: browser.record.totalDifferences, color: .primary)
                    summaryPill(title: "Matched", count: browser.record.matchedCount, color: .secondary)
                    summaryPill(title: "Added", count: browser.resultCounts[.added] ?? 0, color: .green)
                    summaryPill(title: "Removed", count: browser.resultCounts[.removed] ?? 0, color: .red)
                    summaryPill(title: "Changed", count: browser.resultCounts[.changed] ?? 0, color: .blue)
                    summaryPill(title: "Uncertain", count: browser.resultCounts[.uncertain] ?? 0, color: .orange)
                    summaryPill(title: "Ignored", count: browser.resultCounts[.ignored] ?? 0, color: .gray)
                }

                Spacer()

                HStack(spacing: 2) {
                    Button(action: { browser.navigate(direction: .previous) }) {
                        Image(systemName: "chevron.up")
                    }
                    .disabled(!browser.canGoPrevious)
                    .keyboardShortcut(.upArrow, modifiers: .command)
                    .help("Previous difference (⌘↑)")
                    .accessibilityLabel("Previous difference")
                    .accessibilityHint(browser.canGoPrevious ? "Moves to the previous result" : "No previous result")

                    Button(action: { browser.navigate(direction: .next) }) {
                        Image(systemName: "chevron.down")
                    }
                    .disabled(!browser.canGoNext)
                    .keyboardShortcut(.downArrow, modifiers: .command)
                    .help("Next difference (⌘↓)")
                    .accessibilityLabel("Next difference")
                    .accessibilityHint(browser.canGoNext ? "Moves to the next result" : "No next result")
                }

                HStack(spacing: 2) {
                    Button("Previous Page", action: { browser.showPreviousPage() })
                        .disabled(!browser.canShowPreviousPage)
                        .accessibilityLabel("Previous page of results")
                    Button("Next Page", action: { browser.showNextPage() })
                        .disabled(!browser.canShowNextPage)
                        .accessibilityLabel("Next page of results")
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            if let page = browser.currentPage {
                Text(pageRangeText(page))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
                    .accessibilityLabel(pageRangeText(page))
            }

            Divider()

            HSplitView {
                // Results List
                VStack(spacing: 0) {
                    if let error = browser.error {
                        Text(error).foregroundStyle(.red).padding()
                            .accessibilityLabel("Comparison error: \(error)")
                    } else if browser.isLoading && browser.currentPage == nil {
                        ProgressView().padding()
                            .accessibilityLabel("Loading results")
                    } else if let page = browser.currentPage {
                        if page.rows.isEmpty {
                            EmptyStateView(
                                title: "No Results",
                                systemImage: "magnifyingglass",
                                detail: "No results matched the current filter."
                            )
                        } else {
                            List(selection: $browser.selectedRowID) {
                                ForEach(page.rows) { row in
                                    ComparisonResultRowView(row: row)
                                        .tag(row.id)
                                        .onAppear {
                                            if row == page.rows.last && page.isTruncated {
                                                browser.showNextPage()
                                            }
                                        }
                                }
                                if page.isTruncated {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                        Spacer()
                                    }
                                }
                            }
                            .accessibilityLabel("Comparison results")
                        }
                    }
                }
                .frame(minWidth: 400)

                // Detail Pane
                ComparisonDetailPane(browser: browser)
                    .frame(minWidth: 300, idealWidth: 350)
            }
        }
    }

    private func pageRangeText(_ page: ComparisonResultPage) -> String {
        let first = page.offset + 1
        let last = page.offset + page.rows.count
        return "Showing rows \(first)–\(last) of \(page.totalCount)"
    }

    @ViewBuilder
    private func summaryPill(title: String, count: Int64, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text("\(count)").font(.caption).bold().foregroundStyle(color)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(count)")
    }
}

struct ComparisonResultRowView: View {
    let row: ComparisonResultRow

    var body: some View {
        HStack {
            Image(systemName: iconForType(row.resultType))
                .foregroundStyle(colorForType(row.resultType))

            VStack(alignment: .leading, spacing: 2) {
                Text(row.displayName)
                    .font(.body)
                    .lineLimit(1)

                HStack {
                    Text(row.resultPath)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    if !row.differenceFields.isEmpty {
                        Text("(\(row.differenceFields.map(\.rawValue).joined(separator: ", ")))")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(ComparisonOutcomeWording.label(for: row.resultType)) — \(row.displayName), \(row.resultPath)")
    }

    private func iconForType(_ type: ComparisonResultType) -> String {
        switch type {
        case .matched: return "equal.circle"
        case .added: return "plus.circle.fill"
        case .removed: return "minus.circle.fill"
        case .changed: return "exclamationmark.triangle.fill"
        case .uncertain: return "questionmark.circle.fill"
        case .ignored: return "slash.circle"
        }
    }

    private func colorForType(_ type: ComparisonResultType) -> Color {
        switch type {
        case .matched: return .secondary
        case .added: return .green
        case .removed: return .red
        case .changed: return .blue
        case .uncertain: return .orange
        case .ignored: return .gray
        }
    }
}

struct ComparisonDetailPane: View {
    @ObservedObject var browser: ComparisonBrowserModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details").font(.headline)

            if let row = browser.selectedRow {
                Text(ComparisonOutcomeWording.shortLabel(for: row.resultType))
                    .font(.title3)
                    .foregroundStyle(colorForType(row.resultType))
                    .accessibilityLabel(ComparisonOutcomeWording.label(for: row.resultType))

                // Profile and version, from the record (frozen at creation).
                Text("Profile: \(browser.record.profileName) (version \(browser.record.profileVersion))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Profile: \(browser.record.profileName), version \(browser.record.profileVersion)")

                if !browser.record.warnings.isEmpty {
                    GroupBox("Compatibility Warnings") {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(browser.record.warnings, id: \.self) { warning in
                                Text(warning).font(.caption).foregroundStyle(.orange)
                            }
                        }
                    }
                }

                if row.resultType == .uncertain {
                    GroupBox {
                        Text("Ambiguous normalized identity. Multiple candidates exist or no deterministic pairing was made.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    .accessibilityLabel("Uncertain: ambiguous normalized identity, no deterministic pairing was made")
                }

                HStack(alignment: .top, spacing: 16) {
                    sideMetadataView(
                        title: "Left (Reference)",
                        descriptor: browser.record.left,
                        metadata: browser.selectedLeftMetadata,
                        isMissing: row.resultType == .added
                    )

                    Divider()

                    sideMetadataView(
                        title: "Right (Changed)",
                        descriptor: browser.record.right,
                        metadata: browser.selectedRightMetadata,
                        isMissing: row.resultType == .removed
                    )
                }

                if !browser.selectedFieldDifferences.isEmpty {
                    GroupBox("Field Differences") {
                        ForEach(browser.selectedFieldDifferences, id: \.self) { difference in
                            HStack {
                                Text(difference.field.rawValue).font(.caption).bold()
                                Spacer()
                                Text(difference.leftValue ?? "none")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.secondary)
                                Text(difference.rightValue ?? "none")
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(difference.field.rawValue): left \(difference.leftValue ?? "none"), right \(difference.rightValue ?? "none")")
                        }
                    }
                }

                Spacer()
                Text("Metadata only. Content Not Verified.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Metadata only. Content Not Verified.")
            } else {
                EmptyStateView(
                    title: "No Selection",
                    systemImage: "list.bullet.rectangle",
                    detail: "Select a result row to view metadata differences."
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }

    @ViewBuilder
    private func sideMetadataView(
        title: String,
        descriptor: ComparisonSideDescriptor,
        metadata: SideMetadata?,
        isMissing: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline).bold()
            Text(descriptor.sourceDescription).font(.caption2).foregroundStyle(.secondary)
            Text("Snapshot status: \(descriptor.status.rawValue.replacingOccurrences(of: "_", with: " "))")
                .font(.caption2)
                .foregroundStyle(.secondary)
            if descriptor.warningCount > 0 {
                Text("\(descriptor.warningCount) warning(s) at capture")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }

            if isMissing {
                Text("Item not present on this side.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                    .accessibilityLabel("Item not present on the \(title) side")
            } else if let md = metadata {
                Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
                    metadataRow("Name", md.name)
                    metadataRow("Path", md.relativePath)
                    metadataRow("Kind", md.itemKind.rawValue)
                    if let lSize = md.logicalSizeBytes {
                        metadataRow("Size", ByteCountFormatter.string(fromByteCount: lSize, countStyle: .file))
                    }
                    if let cTime = md.createdAtSource { metadataRow("Created", cTime) }
                    if let mTime = md.modifiedAtSource { metadataRow("Modified", mTime) }
                    if let target = md.symlinkTarget { metadataRow("Target", target) }
                }
                .padding(.top, 4)

                if md.isInaccessible {
                    Text("Inaccessible source").font(.caption).foregroundStyle(.orange)
                }
            } else {
                Text("Metadata unavailable.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metadataRow(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.caption).textSelection(.enabled)
        }
    }

    private func colorForType(_ type: ComparisonResultType) -> Color {
        switch type {
        case .matched: return .secondary
        case .added: return .green
        case .removed: return .red
        case .changed: return .blue
        case .uncertain: return .orange
        case .ignored: return .gray
        }
    }
}
