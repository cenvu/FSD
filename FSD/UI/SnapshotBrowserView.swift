import AppKit
import SwiftUI

/// View state for browsing one stored snapshot.
///
/// Holds a summary, the current selection's details, and the current search
/// results — never the tree. The rows on screen live in the `NSOutlineView`
/// coordinator's per-parent cache, which is only ever populated for branches the
/// user actually expanded.
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

    let dataSource: SnapshotTreeDataSource
    private let database: CatalogDatabase
    private let history: SnapshotHistoryRepository
    private let search: MetadataSearchService
    private var searchGeneration: UInt64 = 0

    init(database: CatalogDatabase, summary: SnapshotSummary) {
        self.database = database
        self.summary = summary
        self.history = SnapshotHistoryRepository(database: database)
        self.search = MetadataSearchService(database: database)
        self.dataSource = SnapshotTreeDataSource(database: database, snapshotID: summary.id)
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
        guard let entryID else {
            selectedDetails = nil
            return
        }
        do {
            selectedDetails = try dataSource.details(for: entryID)
        } catch {
            self.error = error.localizedDescription
        }
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
                .frame(minWidth: 380)
                EntryInspectorView(details: model.selectedDetails, summary: model.summary)
                    .frame(minWidth: 260)
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
    let details: SnapshotEntryDetails?
    let summary: SnapshotSummary

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Stored metadata").font(.headline)
                if let details {
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
                    row("Normalization", summary.normalizationVersion.rawValue)
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
                        Text("Not classified")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Divider()
                    Text("Recorded metadata only. FSD never read this file's contents, so nothing here confirms what the file contains.")
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
