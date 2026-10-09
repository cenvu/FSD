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

/// Stable identity for one stored entry row. Folder children live in the
/// coordinator's bounded page-window cache rather than a recursive tree.
final class SnapshotTreeItem {
    let node: SnapshotTreeNode
    let rootGeneration: UInt64
    weak var parentItem: SnapshotTreeItem?
    fileprivate var pageControl: SnapshotTreePageControlItem?
    fileprivate var releaseReason: SnapshotTreePageReleaseReason?

    init(node: SnapshotTreeNode, rootGeneration: UInt64, parentItem: SnapshotTreeItem? = nil) {
        self.node = node
        self.rootGeneration = rootGeneration
        self.parentItem = parentItem
    }
}

private enum SnapshotTreePageAction: Int {
    case previous
    case next
    case retry
    case reload
}

private struct SnapshotTreePageButton {
    let title: String
    let accessibilityLabel: String
    let action: SnapshotTreePageAction
}

private struct SnapshotTreePagePresentation {
    let message: String
    let buttons: [SnapshotTreePageButton]
}

private enum SnapshotTreePageReleaseReason {
    case collapsed
    case evicted
    case capacity
}

private enum SnapshotTreePageLoadError: Error {
    case invalidCount
    case incompletePage
}

/// A native, non-selectable outline row that represents a UI action, never a
/// catalog entry.
final class SnapshotTreePageControlItem: NSObject {
    weak var parentItem: SnapshotTreeItem?
    weak var coordinator: LazyMetadataOutlineView.Coordinator?
    let rootGeneration: UInt64
    fileprivate var presentation = SnapshotTreePagePresentation(message: "", buttons: [])

    init(parentItem: SnapshotTreeItem, rootGeneration: UInt64,
         coordinator: LazyMetadataOutlineView.Coordinator) {
        self.parentItem = parentItem
        self.rootGeneration = rootGeneration
        self.coordinator = coordinator
    }

    @objc fileprivate func activate(_ sender: NSButton) {
        guard let action = SnapshotTreePageAction(rawValue: sender.tag) else { return }
        coordinator?.activate(action, from: self)
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
        context.coordinator.setRoot(root, dataSource: dataSource)
    }

    static func dismantleNSView(_ nsView: NSScrollView, coordinator: Coordinator) {
        coordinator.releaseForBrowserExit()
    }

    final class Coordinator: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
        private static let pageSizeCeiling = 500
        private static let maximumCachedBranchPageWindows = 16

        var cachedBranchPageCount: Int { cachedPages.count }
        var maximumCachedBranchPages: Int { Self.maximumCachedBranchPageWindows }

        private final class CachedBranchPage {
            weak var parentItem: SnapshotTreeItem?
            let rootGeneration: UInt64
            var childItems: [SnapshotTreeItem] = []
            var currentPage: Int?
            var totalCount: Int?
            var failedPage: Int?
            var lastUsed: UInt64 = 0

            init(parentItem: SnapshotTreeItem, rootGeneration: UInt64) {
                self.parentItem = parentItem
                self.rootGeneration = rootGeneration
            }
        }

        private var dataSource: SnapshotTreeDataSource
        private let injectedChildCount: ((Int64) throws -> Int)?
        private let injectedPageLoader: ((Int64, Int, Int) throws -> [SnapshotTreeNode])?
        var onSelect: (Int64?) -> Void
        weak var outlineView: NSOutlineView?
        private var rootItem: SnapshotTreeItem?
        private var rootGeneration: UInt64 = 0
        private var cachedPages: [ObjectIdentifier: CachedBranchPage] = [:]
        private var accessClock: UInt64 = 0
        private var isReloadingOutline = false
        private var selectedEntryID: Int64?

        private(set) var maximumCachedBranchPagesObserved = 0
        private(set) var maximumRetainedEntryItemsObserved = 0
        private(set) var maximumRetainedOutlineItemsObserved = 0

        var retainedEntryItemCount: Int {
            cachedPages.values.reduce(0) { $0 + $1.childItems.count }
        }

        var retainedOutlineItemCount: Int {
            var visited = Set<ObjectIdentifier>()
            var count = 0
            func visit(_ item: SnapshotTreeItem) {
                let key = ObjectIdentifier(item)
                guard visited.insert(key).inserted else { return }
                count += 1
                if item.pageControl != nil { count += 1 }
                for child in cachedPages[key]?.childItems ?? [] { visit(child) }
            }
            if let rootItem { visit(rootItem) }
            return count
        }

        var maximumRetainedEntryItems: Int {
            Self.maximumCachedBranchPageWindows * Self.pageSizeCeiling
        }

        var maximumRetainedOutlineItems: Int {
            2 + (2 * Self.maximumCachedBranchPageWindows * Self.pageSizeCeiling)
        }

        init(dataSource: SnapshotTreeDataSource, onSelect: @escaping (Int64?) -> Void,
             childCountLoader: ((Int64) throws -> Int)? = nil,
             pageLoader: ((Int64, Int, Int) throws -> [SnapshotTreeNode])? = nil) {
            self.dataSource = dataSource
            self.injectedChildCount = childCountLoader
            self.injectedPageLoader = pageLoader
            self.onSelect = onSelect
        }

        func setRoot(_ node: SnapshotTreeNode?) {
            setRoot(node, dataSource: dataSource)
        }

        func setRoot(_ node: SnapshotTreeNode?, dataSource newDataSource: SnapshotTreeDataSource) {
            let validNode = node.flatMap { $0.snapshotID == newDataSource.snapshotID ? $0 : nil }
            let sourceChanged = dataSource !== newDataSource
            let rootChanged = validNode?.snapshotID != rootItem?.node.snapshotID
                || validNode?.id != rootItem?.node.id
            guard sourceChanged || rootChanged else { return }

            isReloadingOutline = true
            let oldDataSource = dataSource
            clearAllCachedPages()
            rootGeneration &+= 1
            if sourceChanged { oldDataSource.invalidate() }
            dataSource = newDataSource
            dataSource.invalidate()
            rootItem = validNode.map {
                SnapshotTreeItem(node: $0, rootGeneration: rootGeneration)
            }
            selectedEntryID = nil
            outlineView?.reloadData()
            if let rootItem, outlineView?.isItemExpanded(rootItem) != true {
                outlineView?.expandItem(rootItem)
            }
            isReloadingOutline = false
            onSelect(nil)
        }

        func releaseForBrowserExit() {
            isReloadingOutline = true
            dataSource.invalidate()
            rootGeneration &+= 1
            clearAllCachedPages()
            rootItem = nil
            selectedEntryID = nil
            outlineView?.reloadData()
            isReloadingOutline = false
        }

        func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
            guard let item = item as? SnapshotTreeItem else { return rootItem == nil ? 0 : 1 }
            return childRows(of: item).count
        }

        func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
            guard let item = item as? SnapshotTreeItem else {
                return rootItem.map { $0 as Any } ?? NSNull()
            }
            let rows = childRows(of: item)
            guard rows.indices.contains(index) else {
                if let control = item.pageControl { return control }
                return NSNull()
            }
            return rows[index]
        }

        func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
            guard let item = item as? SnapshotTreeItem else { return false }
            return item.node.itemKind == .directory && isCurrent(item)
        }

        func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
            item is SnapshotTreeItem
        }

        func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
            guard let tableColumn else { return nil }
            if let control = item as? SnapshotTreePageControlItem {
                if tableColumn.identifier.rawValue == "name" {
                    return Self.makeControlCell(control)
                }
                return Self.makeCell(identifier: tableColumn.identifier, text: "")
            }
            guard let item = item as? SnapshotTreeItem else { return nil }
            let identifier = tableColumn.identifier
            let cell = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
                ?? Self.makeCell(identifier: identifier)
            cell.textField?.stringValue = Self.text(for: item.node, column: identifier.rawValue)
            cell.textField?.textColor = item.node.isInaccessible ? .systemOrange : .labelColor
            return cell
        }

        func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
            item is SnapshotTreePageControlItem ? 26 : outlineView.rowHeight
        }

        func outlineViewSelectionDidChange(_ notification: Notification) {
            guard !isReloadingOutline,
                  let outlineView = notification.object as? NSOutlineView else { return }
            let row = outlineView.selectedRow
            guard row >= 0 else {
                selectedEntryID = nil
                onSelect(nil)
                return
            }
            guard let item = outlineView.item(atRow: row) as? SnapshotTreeItem,
                  isCurrent(item) else { return }
            selectedEntryID = item.node.id
            onSelect(item.node.id)
        }

        func outlineViewItemDidCollapse(_ notification: Notification) {
            guard !isReloadingOutline,
                  let item = notification.userInfo?["NSObject"] as? SnapshotTreeItem,
                  isCurrent(item) else { return }
            releasePageTree(for: item, reason: .collapsed)
            recordCacheMaximums()
        }

        fileprivate func activate(_ action: SnapshotTreePageAction, from control: SnapshotTreePageControlItem) {
            guard control.rootGeneration == rootGeneration,
                  let parent = control.parentItem,
                  isCurrent(parent), parent.pageControl === control else { return }

            guard let page = cachedPages[ObjectIdentifier(parent)] else {
                guard parent.releaseReason != nil else { return }
                parent.releaseReason = nil
                switch action {
                case .retry, .reload:
                    _ = loadPage(for: parent, targetPage: 0)
                case .previous, .next:
                    return
                }
                return
            }

            touch(page)
            let targetPage: Int
            switch action {
            case .previous:
                guard let current = page.currentPage, current > 0 else { return }
                targetPage = current - 1
            case .next:
                guard let current = page.currentPage, let total = page.totalCount,
                      current + 1 < pageCount(for: total) else { return }
                targetPage = current + 1
            case .retry:
                guard let failedPage = page.failedPage else { return }
                targetPage = failedPage
            case .reload:
                targetPage = 0
            }
            _ = loadPage(for: parent, targetPage: targetPage)
        }

        private func childRows(of item: SnapshotTreeItem) -> [Any] {
            guard isCurrent(item), item.node.itemKind == .directory else { return [] }
            let key = ObjectIdentifier(item)
            if let page = cachedPages[key] {
                touch(page)
                return rows(for: page, parent: item)
            }
            if let reason = item.releaseReason {
                let row = controlItem(for: item, presentation: releasePresentation(for: reason))
                recordCacheMaximums()
                return [row]
            }
            guard ensureCacheSlot(for: item) else {
                item.releaseReason = .capacity
                let row = controlItem(for: item, presentation: releasePresentation(for: .capacity))
                recordCacheMaximums()
                return [row]
            }
            let page = CachedBranchPage(parentItem: item, rootGeneration: rootGeneration)
            cachedPages[key] = page
            touch(page)
            _ = loadPage(for: item, targetPage: 0, notifyOutline: false)
            return rows(for: page, parent: item)
        }

        private func rows(for page: CachedBranchPage, parent: SnapshotTreeItem) -> [Any] {
            updatePresentation(for: page, parent: parent)
            var rows = page.childItems.map { $0 as Any }
            rows.append(controlItem(for: parent, presentation: pagePresentation(for: page)))
            recordCacheMaximums()
            return rows
        }

        @discardableResult
        private func loadPage(for parent: SnapshotTreeItem, targetPage: Int, notifyOutline: Bool = true) -> Bool {
            guard isCurrent(parent), let page = cachedPages[ObjectIdentifier(parent)],
                  page.rootGeneration == rootGeneration else { return false }

            let expectedDataSource = dataSource
            let expectedGeneration = rootGeneration
            do {
                let total: Int
                if let injectedChildCount {
                    total = try injectedChildCount(parent.node.id)
                } else {
                    total = try expectedDataSource.childCount(ofParent: parent.node.id)
                }
                guard isCurrent(parent, dataSource: expectedDataSource, generation: expectedGeneration) else { return false }
                guard total >= 0 else { throw SnapshotTreePageLoadError.invalidCount }
                page.totalCount = total

                let normalizedTarget = total == 0 ? 0 : targetPage
                guard total == 0 || normalizedTarget < pageCount(for: total) else { return false }

                let nodes: [SnapshotTreeNode]
                if total == 0 {
                    nodes = []
                } else {
                    let pageSize = effectivePageSize
                    let offset = normalizedTarget * pageSize
                    if let injectedPageLoader {
                        nodes = try injectedPageLoader(parent.node.id, offset, pageSize)
                    } else {
                        nodes = try expectedDataSource.children(
                            ofParent: parent.node.id, offset: offset, limit: pageSize
                        )
                    }
                    guard isCurrent(parent, dataSource: expectedDataSource, generation: expectedGeneration) else { return false }
                    guard !nodes.isEmpty || offset >= total else { throw SnapshotTreePageLoadError.incompletePage }
                }

                releaseDescendantPages(of: page.childItems)
                page.childItems = nodes.map {
                    SnapshotTreeItem(node: $0, rootGeneration: expectedGeneration, parentItem: parent)
                }
                page.currentPage = normalizedTarget
                page.totalCount = total
                page.failedPage = nil
                parent.releaseReason = nil
                updatePresentation(for: page, parent: parent)
                if notifyOutline { reloadChildren(of: parent) }
                recordCacheMaximums()
                return true
            } catch {
                guard isCurrent(parent, dataSource: expectedDataSource, generation: expectedGeneration) else { return false }
                page.failedPage = targetPage
                updatePresentation(for: page, parent: parent)
                if notifyOutline { reloadChildren(of: parent) }
                recordCacheMaximums()
                return false
            }
        }

        private var effectivePageSize: Int {
            min(max(1, dataSource.pageSize), Self.pageSizeCeiling)
        }

        private func pageCount(for total: Int) -> Int {
            total <= 0 ? 1 : 1 + (total - 1) / effectivePageSize
        }

        private func pagePresentation(for page: CachedBranchPage) -> SnapshotTreePagePresentation {
            if let failedPage = page.failedPage {
                if let total = page.totalCount, total > 0, failedPage < pageCount(for: total) {
                    let range = pageRange(failedPage, total: total)
                    let prior = page.currentPage.map { pageRange($0, total: total) }
                    let suffix = prior.map { " Showing \($0) remains available." } ?? ""
                    return SnapshotTreePagePresentation(
                        message: "Couldn't load entries \(range).\(suffix)",
                        buttons: [SnapshotTreePageButton(
                            title: "Retry",
                            accessibilityLabel: "Retry loading entries \(range) from the saved snapshot.",
                            action: .retry
                        )]
                    )
                }
                return SnapshotTreePagePresentation(
                    message: "Couldn't load this folder from the saved snapshot.",
                    buttons: [SnapshotTreePageButton(
                        title: "Retry",
                        accessibilityLabel: "Retry loading this folder from the saved snapshot.",
                        action: .retry
                    )]
                )
            }

            guard let total = page.totalCount, let current = page.currentPage else {
                return SnapshotTreePagePresentation(
                    message: "Folder page not loaded.",
                    buttons: [SnapshotTreePageButton(
                        title: "Retry", accessibilityLabel: "Retry loading this folder.", action: .retry
                    )]
                )
            }
            guard total > 0 else {
                return SnapshotTreePagePresentation(message: "Empty folder · 0 entries", buttons: [])
            }

            let pages = pageCount(for: total)
            let range = pageRange(current, total: total)
            var message = "Entries \(range) · Page \(current + 1) of \(pages)"
            if current + 1 == pages { message += " · Last page" }
            var buttons: [SnapshotTreePageButton] = []
            if current > 0 {
                let previousRange = pageRange(current - 1, total: total)
                buttons.append(SnapshotTreePageButton(
                    title: "Prev",
                    accessibilityLabel: "Previous page, entries \(previousRange).",
                    action: .previous
                ))
            }
            if current + 1 < pages {
                let nextRange = pageRange(current + 1, total: total)
                buttons.append(SnapshotTreePageButton(
                    title: "Next",
                    accessibilityLabel: "Next page, entries \(nextRange).",
                    action: .next
                ))
            }
            return SnapshotTreePagePresentation(message: message, buttons: buttons)
        }

        private func releasePresentation(for reason: SnapshotTreePageReleaseReason) -> SnapshotTreePagePresentation {
            switch reason {
            case .collapsed:
                return SnapshotTreePagePresentation(
                    message: "Folder rows were released after collapse. Reload to browse again.",
                    buttons: [SnapshotTreePageButton(
                        title: "Reload", accessibilityLabel: "Reload this folder page.", action: .reload
                    )]
                )
            case .evicted:
                return SnapshotTreePagePresentation(
                    message: "Folder rows were released to stay within the memory limit.",
                    buttons: [SnapshotTreePageButton(
                        title: "Reload", accessibilityLabel: "Reload this folder page.", action: .reload
                    )]
                )
            case .capacity:
                return SnapshotTreePagePresentation(
                    message: "The folder cache is full. Collapse another open folder, then retry.",
                    buttons: [SnapshotTreePageButton(
                        title: "Retry", accessibilityLabel: "Retry after collapsing another open folder.", action: .retry
                    )]
                )
            }
        }

        private func pageRange(_ page: Int, total: Int) -> String {
            let pageSize = effectivePageSize
            let first = page * pageSize + 1
            let last = min((page + 1) * pageSize, total)
            return "\(first)–\(last) of \(total)"
        }

        private func updatePresentation(for page: CachedBranchPage, parent: SnapshotTreeItem) {
            let presentation = pagePresentation(for: page)
            controlItem(for: parent, presentation: presentation).presentation = presentation
        }

        private func controlItem(for parent: SnapshotTreeItem,
                                 presentation: SnapshotTreePagePresentation) -> SnapshotTreePageControlItem {
            let control = parent.pageControl ?? SnapshotTreePageControlItem(
                parentItem: parent, rootGeneration: rootGeneration, coordinator: self
            )
            parent.pageControl = control
            control.presentation = presentation
            return control
        }

        private func ensureCacheSlot(for target: SnapshotTreeItem) -> Bool {
            guard cachedPages.count >= Self.maximumCachedBranchPageWindows else { return true }
            let targetKey = ObjectIdentifier(target)
            let candidates = cachedPages
                .filter { key, page in
                    key != targetKey && page.parentItem.map { !isAncestor($0, of: target) } == true
                }
                .sorted { $0.value.lastUsed < $1.value.lastUsed }
            guard let victim = candidates.first?.value, let victimItem = victim.parentItem else { return false }

            if outlineView?.isItemExpanded(victimItem) == true {
                isReloadingOutline = true
                outlineView?.collapseItem(victimItem, collapseChildren: true)
                isReloadingOutline = false
            }
            releasePageTree(for: victimItem, reason: .evicted)
            return cachedPages.count < Self.maximumCachedBranchPageWindows
        }

        private func touch(_ page: CachedBranchPage) {
            accessClock &+= 1
            page.lastUsed = accessClock
        }

        private func isAncestor(_ possibleAncestor: SnapshotTreeItem, of item: SnapshotTreeItem) -> Bool {
            var ancestor = item.parentItem
            while let current = ancestor {
                if current === possibleAncestor { return true }
                ancestor = current.parentItem
            }
            return false
        }

        private func releaseDescendantPages(of items: [SnapshotTreeItem]) {
            for item in items { releasePageTree(for: item, reason: .evicted) }
        }

        private func releasePageTree(for item: SnapshotTreeItem, reason: SnapshotTreePageReleaseReason) {
            let key = ObjectIdentifier(item)
            if let page = cachedPages.removeValue(forKey: key) {
                for child in page.childItems { releasePageTree(for: child, reason: .evicted) }
                page.childItems.removeAll(keepingCapacity: false)
            }
            item.releaseReason = reason
            if let control = item.pageControl { control.presentation = releasePresentation(for: reason) }
        }

        private func clearAllCachedPages() {
            if let rootItem { clearControls(in: rootItem) }
            cachedPages.removeAll(keepingCapacity: false)
        }

        private func clearControls(in item: SnapshotTreeItem) {
            let children = cachedPages[ObjectIdentifier(item)]?.childItems ?? []
            item.pageControl = nil
            item.releaseReason = nil
            for child in children { clearControls(in: child) }
        }

        private func reloadChildren(of parent: SnapshotTreeItem) {
            guard let outlineView, outlineView.isItemExpanded(parent) else { return }
            isReloadingOutline = true
            if let selectedEntryID,
               let selectedItem = visibleItem(withID: selectedEntryID, in: outlineView),
               isAncestor(parent, of: selectedItem),
               !isRetained(selectedItem, below: parent) {
                outlineView.deselectRow(outlineView.row(forItem: selectedItem))
            }
            outlineView.reloadItem(parent, reloadChildren: true)
            isReloadingOutline = false
        }

        private func visibleItem(withID entryID: Int64, in outlineView: NSOutlineView) -> SnapshotTreeItem? {
            guard outlineView.numberOfRows > 0 else { return nil }
            for row in 0..<outlineView.numberOfRows {
                if let item = outlineView.item(atRow: row) as? SnapshotTreeItem, item.node.id == entryID {
                    return item
                }
            }
            return nil
        }

        private func isRetained(_ item: SnapshotTreeItem, below ancestor: SnapshotTreeItem) -> Bool {
            var child = item
            while let parent = child.parentItem {
                guard let page = cachedPages[ObjectIdentifier(parent)],
                      page.childItems.contains(where: { $0 === child }) else { return false }
                if parent === ancestor { return true }
                child = parent
            }
            return false
        }

        private func isCurrent(_ item: SnapshotTreeItem) -> Bool {
            isCurrent(item, dataSource: dataSource, generation: rootGeneration)
        }

        private func isCurrent(_ item: SnapshotTreeItem, dataSource source: SnapshotTreeDataSource,
                               generation: UInt64) -> Bool {
            item.rootGeneration == generation
                && item.node.snapshotID == source.snapshotID
                && source === dataSource
                && rootItem?.rootGeneration == generation
        }

        private func recordCacheMaximums() {
            maximumCachedBranchPagesObserved = max(maximumCachedBranchPagesObserved, cachedPages.count)
            maximumRetainedEntryItemsObserved = max(maximumRetainedEntryItemsObserved, retainedEntryItemCount)
            maximumRetainedOutlineItemsObserved = max(maximumRetainedOutlineItemsObserved, retainedOutlineItemCount)
        }

        private static func makeControlCell(_ item: SnapshotTreePageControlItem) -> NSTableCellView {
            let cell = NSTableCellView()
            cell.identifier = NSUserInterfaceItemIdentifier("snapshot-page-control")
            let label = NSTextField(labelWithString: item.presentation.message)
            label.lineBreakMode = .byTruncatingTail
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            label.setAccessibilityLabel(item.presentation.message)
            cell.textField = label
            let arranged: [NSView] = [label] + item.presentation.buttons.map { descriptor in
                let button = NSButton(
                    title: descriptor.title,
                    target: item,
                    action: #selector(SnapshotTreePageControlItem.activate(_:))
                )
                button.tag = descriptor.action.rawValue
                button.controlSize = .small
                button.setAccessibilityLabel(descriptor.accessibilityLabel)
                button.setAccessibilityHelp(item.presentation.message)
                return button
            }
            let stack = NSStackView(views: arranged)
            stack.orientation = .horizontal
            stack.alignment = .centerY
            stack.distribution = .fill
            stack.spacing = 5
            stack.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
                stack.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -2),
                stack.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                stack.topAnchor.constraint(greaterThanOrEqualTo: cell.topAnchor, constant: 1),
                stack.bottomAnchor.constraint(lessThanOrEqualTo: cell.bottomAnchor, constant: -1)
            ])
            return cell
        }

        private static func makeCell(identifier: NSUserInterfaceItemIdentifier) -> NSTableCellView {
            makeCell(identifier: identifier, text: "")
        }

        private static func makeCell(identifier: NSUserInterfaceItemIdentifier, text: String) -> NSTableCellView {
            let cell = NSTableCellView()
            cell.identifier = identifier
            let field = NSTextField(labelWithString: text)
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
