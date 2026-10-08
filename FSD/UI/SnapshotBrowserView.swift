import AppKit
import SwiftUI

/// View state for browsing one stored snapshot.
///
/// Holds a summary, the current selection's details, and the current search
/// results — never the tree. The rows on screen live in the `NSOutlineView`
/// coordinator's per-parent cache, which is only ever populated for branches the
/// user actually expanded.
/// Bounded selected-entry classification phase. Progress affordance appears
/// only in `runningWithProgress`, which the model enters after exactly 0.5 s
/// when the same operation is still running. Fast completions never flash.
enum SelectedEntryClassificationPhase: String, Sendable, Equatable {
    case idle
    case runningBeforeProgress
    case runningWithProgress
}

/// Minimal UI outcome of one explicit selected-entry classification.
/// Persisted cases refresh exactly the selected entry's details; all other
/// cases show only a bounded runtime message and never a raw diagnostic.
enum SelectedEntryClassificationResult: Sendable, Equatable {
    case busy
    case cancelled
    case unavailable
    case noMatch
    case classifiedPersisted
    case failedPersisted
    case repositoryFailure
}

/// Narrow model-only seam around the global runtime. Production wraps the one
/// app-scoped `ClassificationRuntimeService`; tests inject a fake. The seam
/// never broadens the runtime API and never creates a second production run.
struct SelectedEntryClassificationControl: Sendable {
    var start: @Sendable (Int64) async -> SelectedEntryClassificationResult
    var cancel: @Sendable () async -> Void
}

/// Bounded, truthful inspector wording. No sample bytes, paths, errors,
/// diagnostics or provider internals ever reach visible text.
enum ClassificationUIText {
    static let absence = "Not classified."
    static let noMatch = "No file type recognized."
    static let unavailable = "Classification unavailable."
    static let cancelled = "Classification cancelled."
    static let busy = "Classification busy. Try again."
    static let saveFailure = "Classification failed to save."
    static let disclaimer = "Snapshot metadata is not byte proof. Optional classification may sample at most the first 4096 bytes of the currently attached source; it does not verify historical content."
}

@MainActor
final class SnapshotBrowserModel: ObservableObject {
    @Published private(set) var summary: SnapshotSummary
    @Published private(set) var rootNode: SnapshotTreeNode?
    @Published private(set) var selectedDetails: SnapshotEntryDetails?
    @Published private(set) var sourceAvailability: SourceAvailability = .unknown
    @Published private(set) var issues: [SnapshotIssue] = []
    @Published private(set) var searchResults: MetadataSearchResults?
    @Published private(set) var isSearching = false
    @Published private(set) var error: String?
    @Published var searchText: String = ""
    @Published var searchField: MetadataSearchQuery.Field = .nameOrPath
    @Published var exportMessage: String?
    @Published private(set) var selectedEntryID: Int64?
    @Published private(set) var classificationPhase: SelectedEntryClassificationPhase = .idle
    @Published private(set) var classificationMessage: String?

    var canClassifySelectedFile: Bool { selectedEntryID != nil && classificationPhase == .idle }

    let dataSource: SnapshotTreeDataSource
    let classificationRuntime: ClassificationRuntimeService
    var classificationControl: SelectedEntryClassificationControl
    var classificationProgressDelay: @Sendable () async -> Void
    var classificationDetailsLoader: ((Int64) throws -> SnapshotEntryDetails?)?
    private var classificationOperation: UInt64 = 0
    private let database: CatalogDatabase
    private let history: SnapshotHistoryRepository
    private let search: MetadataSearchService
    private var searchGeneration: UInt64 = 0

    init(database: CatalogDatabase, summary: SnapshotSummary,
         runtime: ClassificationRuntimeService = .shared,
         control: SelectedEntryClassificationControl? = nil,
         progressDelay: @escaping @Sendable () async -> Void = { try? await Task.sleep(for: .milliseconds(500)) },
         detailsLoader: ((Int64) throws -> SnapshotEntryDetails?)? = nil) {
        self.database = database
        self.summary = summary
        self.history = SnapshotHistoryRepository(database: database)
        self.search = MetadataSearchService(database: database)
        self.dataSource = SnapshotTreeDataSource(database: database, snapshotID: summary.id)
        self.classificationRuntime = runtime
        self.classificationProgressDelay = progressDelay
        self.classificationDetailsLoader = detailsLoader
        if let control {
            self.classificationControl = control
        } else {
            let capturedDatabase = database
            let capturedRuntime = runtime
            self.classificationControl = SelectedEntryClassificationControl(
                start: { entryID in
                    await Self.productionStart(entryID: entryID, database: capturedDatabase, runtime: capturedRuntime)
                },
                cancel: { await capturedRuntime.cancel() }
            )
        }
    }

    static func productionStart(entryID: Int64, database: CatalogDatabase,
                                runtime: ClassificationRuntimeService) async -> SelectedEntryClassificationResult {
        let provider = BundledFiletypeClassificationProvider()
        let started = await runtime.start(entryID: entryID, database: database, provider: provider)
        return selectedEntryResult(started)
    }

    /// Shared production mapping, exercised without launching a real helper.
    static func selectedEntryResult(_ started: ClassificationRuntimeService.StartResult) -> SelectedEntryClassificationResult {
        switch started {
        case .busy:
            return .busy
        case .rejected:
            return .repositoryFailure
        case .completed(let completion):
            switch completion.result {
            case .repositoryFailure:
                return .repositoryFailure
            case .classification(let outcome, let row):
                switch outcome {
                case .classified:
                    return row == nil ? .repositoryFailure : .classifiedPersisted
                case .failed, .sourceChanged, .unsupportedEntry:
                    return row == nil ? .repositoryFailure : .failedPersisted
                case .unavailable:
                    return .unavailable
                case .cancelled:
                    return .cancelled
                case .noMatch:
                    return .noMatch
                }
            }
        }
    }

    /// Opening a snapshot reads the summary that is already in hand, the root
    /// row, and a bounded issue list. No entry below the root is touched.
    func open() {
        do {
            rootNode = try dataSource.root()
            issues = try history.issues(for: summary.id, limit: 100)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        // The one deliberate filesystem call in the browser, and only to label
        // the source state. Nothing below depends on its answer.
        sourceAvailability = SourceAvailabilityProbe().availability(for: summary)
    }

    func select(entryID: Int64?) {
        // Changing selection invalidates old classification ownership first.
        // No user-facing cancelled message on the new selection.
        classificationOperation += 1
        let control = classificationControl
        Task { await control.cancel() }
        classificationPhase = .idle
        classificationMessage = nil
        guard let entryID else {
            selectedEntryID = nil
            selectedDetails = nil
            return
        }
        selectedEntryID = entryID
        do {
            selectedDetails = try classificationDetails(for: entryID)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func classificationDetails(for entryID: Int64) throws -> SnapshotEntryDetails? {
        if let loader = classificationDetailsLoader {
            return try loader(entryID)
        }
        return try dataSource.details(for: entryID)
    }

    /// Explicit user action only. No caller besides the inspector button may
    /// invoke the runtime. Delayed progress appears after exactly 0.5 s when
    /// the same operation is still running; stale completions never mutate.
    func classifySelectedFile() async {
        guard let entryID = selectedEntryID else { return }
        guard classificationPhase == .idle else { return }
        classificationOperation += 1
        let operation = classificationOperation
        classificationPhase = .runningBeforeProgress
        classificationMessage = nil
        let delay = classificationProgressDelay
        Task { [weak self] in
            await delay()
            await MainActor.run {
                guard let self,
                      self.classificationOperation == operation,
                      self.classificationPhase == .runningBeforeProgress,
                      self.selectedEntryID == entryID else { return }
                self.classificationPhase = .runningWithProgress
            }
        }
        let outcome = await classificationControl.start(entryID)
        guard classificationOperation == operation, selectedEntryID == entryID else { return }
        switch outcome {
        case .busy:
            classificationPhase = .idle
            classificationMessage = ClassificationUIText.busy
        case .cancelled:
            classificationPhase = .idle
            classificationMessage = ClassificationUIText.cancelled
        case .unavailable:
            classificationPhase = .idle
            classificationMessage = ClassificationUIText.unavailable
        case .noMatch:
            classificationPhase = .idle
            classificationMessage = ClassificationUIText.noMatch
        case .classifiedPersisted, .failedPersisted:
            do {
                if let refreshed = try classificationDetails(for: entryID) {
                    guard classificationOperation == operation, selectedEntryID == entryID else { return }
                    selectedDetails = refreshed
                    classificationMessage = nil
                } else {
                    classificationMessage = nil
                }
            } catch {
                classificationMessage = ClassificationUIText.saveFailure
            }
            classificationPhase = .idle
        case .repositoryFailure:
            classificationPhase = .idle
            classificationMessage = ClassificationUIText.saveFailure
        }
    }

    /// Explicit Cancel, visible only with delayed progress. Shows a bounded
    /// cancelled message and invalidates the old operation so a late
    /// completion cannot alter the inspector.
    func cancelClassification() {
        guard classificationPhase != .idle else { return }
        classificationOperation += 1
        let control = classificationControl
        Task { await control.cancel() }
        classificationPhase = .idle
        classificationMessage = ClassificationUIText.cancelled
    }

    /// Selection/snapshot/browser lifecycle cancellation. No user-facing
    /// cancelled message on the new selection or browser.
    func cancelClassificationForSnapshotClose() {
        classificationOperation += 1
        let control = classificationControl
        Task { await control.cancel() }
        classificationPhase = .idle
        classificationMessage = nil
    }

    func runSearch() {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            searchResults = nil
            return
        }
        searchGeneration += 1
        let generation = searchGeneration
        let query = MetadataSearchQuery(text: text, field: searchField)
        let snapshotID = summary.id
        let service = search
        isSearching = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let outcome = Result { try service.search(query, in: snapshotID) }
            DispatchQueue.main.async {
                guard let self, generation == self.searchGeneration else { return }
                self.isSearching = false
                switch outcome {
                case let .success(results): self.searchResults = results
                case let .failure(failure): self.error = failure.localizedDescription
                }
            }
        }
    }

    func clearSearch() {
        searchGeneration += 1
        searchText = ""
        searchResults = nil
        isSearching = false
    }

    func exportJSON() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(summary.displayName).fsd-metadata.json"
        panel.allowedContentTypes = [.json]
        panel.prompt = "Export Metadata"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let result = try JSONSnapshotExporter(database: database).export(snapshotID: summary.id, to: url)
            exportMessage = "Exported \(result.entryCount) metadata entries — content not verified."
        } catch {
            exportMessage = nil
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Lazy outline view

/// Stable identity for one row. `NSOutlineView` compares items by object
/// identity, and the cached `children` is what keeps an expanded branch from
/// being re-queried on every layout pass.
final class SnapshotTreeItem {
    let node: SnapshotTreeNode
    var children: [SnapshotTreeItem]?

    init(node: SnapshotTreeNode) {
        self.node = node
    }
}

struct LazyMetadataOutlineView: NSViewRepresentable {
    let dataSource: SnapshotTreeDataSource
    let root: SnapshotTreeNode?
    let onSelect: (Int64?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(dataSource: dataSource, onSelect: onSelect)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let outlineView = NSOutlineView()
        outlineView.style = .inset
        outlineView.rowSizeStyle = .default
        outlineView.usesAlternatingRowBackgroundColors = true
        outlineView.autoresizesOutlineColumn = false

        let nameColumn = NSTableColumn(identifier: .init("name"))
        nameColumn.title = "Name"
        nameColumn.width = 320
        outlineView.addTableColumn(nameColumn)
        outlineView.outlineTableColumn = nameColumn

        let kindColumn = NSTableColumn(identifier: .init("kind"))
        kindColumn.title = "Kind"
        kindColumn.width = 90
        outlineView.addTableColumn(kindColumn)

        let sizeColumn = NSTableColumn(identifier: .init("size"))
        sizeColumn.title = "Logical size"
        sizeColumn.width = 110
        outlineView.addTableColumn(sizeColumn)

        outlineView.dataSource = context.coordinator
        outlineView.delegate = context.coordinator
        context.coordinator.outlineView = outlineView

        let scrollView = NSScrollView()
        scrollView.documentView = outlineView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.onSelect = onSelect
        context.coordinator.setRoot(root)
    }

    final class Coordinator: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
        private let dataSource: SnapshotTreeDataSource
        var onSelect: (Int64?) -> Void
        weak var outlineView: NSOutlineView?
        private var rootItem: SnapshotTreeItem?
        private var rootEntryID: Int64?

        init(dataSource: SnapshotTreeDataSource, onSelect: @escaping (Int64?) -> Void) {
            self.dataSource = dataSource
            self.onSelect = onSelect
        }

        func setRoot(_ node: SnapshotTreeNode?) {
            guard node?.id != rootEntryID else { return }
            rootEntryID = node?.id
            rootItem = node.map(SnapshotTreeItem.init)
            dataSource.invalidate()
            outlineView?.reloadData()
            if let rootItem {
                outlineView?.expandItem(rootItem)
            }
        }

        /// The only place children are read. `NSOutlineView` calls it for the
        /// root and for branches the user expands, so an unvisited subtree is
        /// never queried.
        private func children(of item: SnapshotTreeItem) -> [SnapshotTreeItem] {
            if let cached = item.children { return cached }
            let loaded = ((try? dataSource.children(ofParent: item.node.id)) ?? []).map(SnapshotTreeItem.init)
            item.children = loaded
            return loaded
        }

        func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
            guard let item = item as? SnapshotTreeItem else { return rootItem == nil ? 0 : 1 }
            return children(of: item).count
        }

        func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
            guard let item = item as? SnapshotTreeItem else { return rootItem as Any }
            return children(of: item)[index]
        }

        func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
            (item as? SnapshotTreeItem)?.node.isExpandable ?? false
        }

        func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
            guard let item = item as? SnapshotTreeItem, let tableColumn else { return nil }
            let identifier = tableColumn.identifier
            let cell = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
                ?? Self.makeCell(identifier: identifier)
            cell.textField?.stringValue = Self.text(for: item.node, column: identifier.rawValue)
            cell.textField?.textColor = item.node.isInaccessible ? .systemOrange : .labelColor
            return cell
        }

        func outlineViewSelectionDidChange(_ notification: Notification) {
            guard let outlineView = notification.object as? NSOutlineView else { return }
            let row = outlineView.selectedRow
            guard row >= 0, let item = outlineView.item(atRow: row) as? SnapshotTreeItem else {
                onSelect(nil)
                return
            }
            onSelect(item.node.id)
        }

        private static func makeCell(identifier: NSUserInterfaceItemIdentifier) -> NSTableCellView {
            let cell = NSTableCellView()
            cell.identifier = identifier
            let field = NSTextField(labelWithString: "")
            field.lineBreakMode = .byTruncatingMiddle
            field.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(field)
            cell.textField = field
            NSLayoutConstraint.activate([
                field.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
                field.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -2),
                field.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
            ])
            return cell
        }

        private static func text(for node: SnapshotTreeNode, column: String) -> String {
            switch column {
            case "kind":
                return node.isPackage ? "package" : node.itemKind.rawValue
            case "size":
                guard let bytes = node.logicalSizeBytes else { return "—" }
                return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
            default:
                let name = node.relativePath.isEmpty ? node.name : node.name
                return node.isHidden ? "\(name) (hidden)" : name
            }
        }
    }
}

// MARK: - Browser

struct SnapshotBrowserView: View {
    @ObservedObject var model: SnapshotBrowserModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if let warning = model.summary.partialStateWarning {
                Label(warning, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .font(.callout)
            }
            searchBar
            if let results = model.searchResults {
                SearchResultsView(results: results) { model.select(entryID: $0) }
                    .frame(minHeight: 160)
            }
            HSplitView {
                LazyMetadataOutlineView(
                    dataSource: model.dataSource,
                    root: model.rootNode,
                    onSelect: { model.select(entryID: $0) }
                )
                .frame(minWidth: 320)
                EntryInspectorView(model: model)
                    .frame(minWidth: 220)
            }
            footer
        }
        .padding(20)
        .onAppear { model.open() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(model.summary.displayName).font(.title2)
                Spacer()
                Button("Export JSON…", action: model.exportJSON)
            }
            HStack(spacing: 10) {
                Label(model.summary.status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
                      systemImage: model.summary.isComplete ? "checkmark.seal" : "exclamationmark.circle")
                Label(model.sourceAvailability.label,
                      systemImage: model.sourceAvailability == .available ? "externaldrive.connected.to.line.below" : "externaldrive.badge.xmark")
                    .foregroundStyle(model.sourceAvailability == .available ? Color.secondary : Color.orange)
            }
            .font(.callout)
            Text(sourceLine).font(.caption).foregroundStyle(.secondary)
            Text("\(model.summary.totalFiles) files · \(model.summary.totalFolders) folders · "
                 + ByteCountFormatter.string(fromByteCount: model.summary.totalLogicalBytes, countStyle: .file)
                 + " · \(model.summary.inaccessibleItems) inaccessible · \(model.summary.warningCount) warnings")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    /// Everything shown here comes from the snapshot's own capture-time columns
    /// (ADR-023), so a later capture of the same volume cannot rewrite it.
    private var sourceLine: String {
        let capture = model.summary.capture
        var parts = ["Source at capture: \(capture.displayNameForHistory)"]
        if let variant = capture.filesystemVariant { parts.append(variant) }
        if let mountPath = capture.mountPath { parts.append(mountPath) }
        parts.append("case \(capture.caseSensitivity.rawValue)")
        if !capture.isFullyRecorded {
            parts.append("captured before schema version 5 — volume facts not recorded")
        }
        return parts.joined(separator: " · ")
    }

    private var searchBar: some View {
        HStack {
            Picker("Search in", selection: $model.searchField) {
                ForEach(MetadataSearchQuery.Field.allCases, id: \.self) { field in
                    Text(field.label).tag(field)
                }
            }
            .frame(width: 200)
            TextField("Search stored metadata", text: $model.searchText)
                .onSubmit { model.runSearch() }
            Button("Search", action: model.runSearch).disabled(model.searchText.isEmpty)
            if model.searchResults != nil { Button("Clear", action: model.clearSearch) }
            if model.isSearching { ProgressView().controlSize(.small) }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let exportMessage = model.exportMessage {
                Text(exportMessage).font(.caption).foregroundStyle(.secondary)
            }
            if let error = model.error {
                Text(error).font(.caption).foregroundStyle(.red)
            }
            if !model.issues.isEmpty {
                Text("\(model.issues.count) recorded scan issue(s); first: \(model.issues[0].message)")
                    .font(.caption).foregroundStyle(.orange).lineLimit(2)
            }
            Text("Metadata only. Content Not Verified.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

private struct SearchResultsView: View {
    let results: MetadataSearchResults
    let onSelect: (Int64) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(headline).font(.caption).foregroundStyle(.secondary)
            List(results.hits) { hit in
                HStack {
                    Text(hit.relativePath.isEmpty ? hit.name : hit.relativePath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Text(hit.itemKind.rawValue).foregroundStyle(.secondary).font(.caption)
                }
                .contentShape(Rectangle())
                .onTapGesture { onSelect(hit.id) }
            }
        }
    }

    private var headline: String {
        var text = "\(results.hits.count) match(es) in snapshot \(results.snapshotID) "
        text += String(format: "in %.3f s", results.durationSeconds)
        if results.isTruncated { text += " — showing the first \(results.limit); refine the search to see the rest" }
        return text
    }
}

private struct EntryInspectorView: View {
    @ObservedObject var model: SnapshotBrowserModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Stored metadata").font(.headline)
                if let details = model.selectedDetails {
                    row("Name", details.name)
                    row("Path", details.relativePath.isEmpty ? "(root)" : details.relativePath)
                    row("Kind", details.itemKind.rawValue)
                    row("Extension", details.fileExtension ?? "—")
                    row("Logical size", details.logicalSizeBytes.map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) } ?? "—")
                    row("Allocated size", details.allocatedSizeBytes.map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) } ?? "—")
                    row("Created", details.createdAtSource ?? "—")
                    row("Modified", details.modifiedAtSource ?? "—")
                    row("Content type", details.contentTypeIdentifier ?? "—")
                    row("Symlink target", details.symlinkTarget ?? "—")
                    row("Hidden", details.isHidden ? "Yes" : "No")
                    row("Package", details.isPackage ? "Yes" : "No")
                    row("Inaccessible", details.isInaccessible ? "Yes" : "No")
                    row("Normalization", model.summary.normalizationVersion.rawValue)
                    Divider()
                    Text("Inferred classification (optional)").font(.headline)
                    if let classification = details.classification {
                        row("Status", classification.statusLabel)
                        row("Detected type", classification.detectedType ?? "—")
                        row("MIME type", classification.mimeType ?? "—")
                        row("Detector", classification.detectorVersion ?? "—")
                        row("Model", classification.modelVersion ?? "—")
                        if let confidence = classification.confidenceLabel {
                            row("Confidence", confidence)
                        }
                        Text("Inferred metadata only; this is not content verification.")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text(ClassificationUIText.absence)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Divider()
                    if model.selectedEntryID != nil {
                        Button("Classify selected file") {
                            Task { await model.classifySelectedFile() }
                        }
                        .disabled(!model.canClassifySelectedFile)
                    }
                    if model.classificationPhase == .runningWithProgress {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Classifying selected file…")
                                .font(.caption).foregroundStyle(.secondary)
                            Button("Cancel", action: model.cancelClassification)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Classifying selected file. Cancel available.")
                    }
                    if let message = model.classificationMessage {
                        Text(message).font(.caption).foregroundStyle(.secondary)
                    }
                    Text(ClassificationUIText.disclaimer)
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("Select an item to see its stored metadata.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(.caption).foregroundStyle(.secondary).frame(width: 110, alignment: .leading)
            Text(value).font(.caption).textSelection(.enabled)
        }
    }
}
