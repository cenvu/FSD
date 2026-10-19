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
            SaveComparisonControls(workspace:workspace, model:workspace.savedComparisons)
                .disabled(workspace.isClosing)
            // Toolbar
            HStack {
                Button(action: { workspace.closeComparison() }) {
                    Image(systemName: "chevron.left")
                    Text("Back to Creation")
                }
                .disabled(workspace.isClosing)
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
            .disabled(workspace.savedComparisons.isSaving || workspace.isClosing)
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            LazyVGrid(columns:[GridItem(.adaptive(minimum:105),spacing:6)],spacing:6) {
                summaryPill(title:"All",count:browser.record.totalComparedEntries,filter:.all)
                summaryPill(title:"Differences",count:browser.record.totalDifferences,filter:.differences)
                summaryPill(title:"Matched",count:browser.record.matchedCount,filter:.unchanged)
                summaryPill(title:"Added",count:browser.resultCounts[.added] ?? 0,filter:.added)
                summaryPill(title:"Removed",count:browser.resultCounts[.removed] ?? 0,filter:.removed)
                summaryPill(title:"Changed",count:browser.resultCounts[.changed] ?? 0,filter:.modified)
                summaryPill(title:"Uncertain",count:browser.resultCounts[.uncertain] ?? 0,filter:.conflicts)
                summaryPill(title:"Ignored",count:browser.resultCounts[.ignored] ?? 0,filter:.ignored)
            }
            .padding(.horizontal).padding(.bottom,8)
            .disabled(workspace.savedComparisons.isSaving || workspace.isClosing)
            Text("“All” counts compared entries. Ignored rows remain browsable and are excluded from summary totals.")
                .font(.caption2).foregroundStyle(.secondary).padding(.bottom,4)
            ancestorBreadcrumb

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
                            ScrollViewReader { proxy in
                                List(selection:$browser.selectedRowID) {
                                    ForEach(page.rows) { row in
                                        ComparisonResultRowView(row:row).tag(row.id).id(row.id)
                                    }
                                }
                                .accessibilityLabel("Comparison results")
                                .onChange(of:browser.revealGeneration) { _,_ in
                                    if let id = browser.selectedRowID, page.rows.contains(where:{ $0.id == id }) {
                                        proxy.scrollTo(id,anchor:.center)
                                    }
                                }
                                .onAppear {
                                    if let id = browser.selectedRowID { proxy.scrollTo(id,anchor:.center) }
                                }
                            }
                        }
                    }
                }
                .frame(minWidth: 400)

                // Detail Pane
                ComparisonDetailPane(browser: browser)
                    .frame(minWidth: 300, idealWidth: 350)
            }
            .disabled(workspace.savedComparisons.isSaving || workspace.isClosing)
        }
    }

    private func pageRangeText(_ page: ComparisonResultPage) -> String {
        let first = page.offset + 1
        let last = page.offset + page.rows.count
        return page.rows.isEmpty ? "No stored results for this filter" : "Showing rows \(first)–\(last) of \(page.totalCount)"
    }

    @FocusState private var focusedCategory: ComparisonResultFilter?

    private func summaryPill(title: String, count: Int64, filter: ComparisonResultFilter) -> some View {
        Button {
            focusedCategory = filter
            browser.selectCategory(filter)
        } label: {
            HStack(spacing:4) {
                Image(systemName:browser.activeFilter == filter ? "checkmark.circle.fill" : "circle")
                Text(title).font(.caption)
                Text("\(count)").font(.caption).bold()
            }
            .frame(maxWidth:.infinity)
        }
        .focusable()
        .focused($focusedCategory,equals:filter)
        .accessibilityLabel("\(title): \(count)")
        .accessibilityValue(browser.activeFilter == filter ? "Selected" : "Not selected")
        .accessibilityHint("Filter and select the first stored \(title.lowercased()) result")
        .help("Show \(title); locate and select its first stored result")
    }

    @ViewBuilder private var ancestorBreadcrumb: some View {
        VStack(alignment:.leading,spacing:4) {
            if let message = browser.ancestorError {
                Text(message).font(.caption).accessibilityLabel("Ancestor context unavailable: \(message)")
            } else if let context = browser.ancestorContext {
                Text("Stored ancestor context — \(context.boundary.rawValue)")
                    .font(.caption).foregroundStyle(.secondary)
                ScrollView(.horizontal) {
                    HStack(spacing:6) {
                        ForEach(context.ancestors) { row in
                            Button(row.resultPath.isEmpty ? "Recorded root" : row.displayName) { browser.revealAncestor(row) }
                                .accessibilityLabel("Reveal stored ancestor \(row.resultPath.isEmpty ? "root" : row.resultPath), result \(row.id)")
                            Image(systemName:"chevron.right").accessibilityHidden(true)
                        }
                        Text("\(context.target.displayName) · #\(context.target.id)")
                            .font(.caption).bold().textSelection(.enabled)
                    }
                }
                .accessibilityLabel("Stored result ancestors")
            } else if browser.isLoading {
                Text("Loading stored result context…").font(.caption)
            }
            if let target = browser.returnTarget {
                Button("Return to target: \(target.displayName) · #\(target.id)") { browser.returnToTarget() }
                    .accessibilityLabel("Return to stored target result \(target.id)")
            }
        }
        .frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal).padding(.bottom,6)
        .disabled(workspace.savedComparisons.isSaving || workspace.isClosing || browser.isLoading)
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
                        title: "Left — Before / Reference",
                        descriptor: browser.record.left,
                        metadata: browser.selectedLeftMetadata,
                        isMissing: row.resultType == .added
                    )

                    Divider()

                    sideMetadataView(
                        title: "Right — After / Changed",
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
