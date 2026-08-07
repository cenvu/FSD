import AppKit
import SwiftUI
import Combine

/// Bounded, view-ready browsing of one stored comparison's results.
///
/// Contract (Milestone 4 GUI correction):
///
/// * The repository is the only data boundary — no raw SQL, no schema
///   knowledge, no `CatalogDatabase` querying in the UI layer. Metadata and
///   field differences come from `ComparisonResultRepository.entryMetadata`
///   and `fieldDifferences`.
/// * Paging is bounded: the model retains exactly one page of at most
///   `pageSize` rows. Advancing to the next or previous page replaces the
///   current page; the retained row count can never grow with the result
///   count, so a 100,000-result comparison never becomes 100,000 rows in UI
///   state.
/// * Navigation is deterministic and cross-page: `navigate` follows the
///   repository's `(result_path, id)` anchor API, and when the adjacent row
///   lies outside the loaded page the model materializes the bounded page
///   containing it and selects it. Boundary availability is repository truth,
///   never an artifact of the current page.
/// * Stale asynchronous responses are ignored via `searchGeneration`; a
///   filter change resets the page to offset zero.
@MainActor
final class ComparisonBrowserModel: ObservableObject {
    let record: ComparisonRecord

    /// Fixed, configurable page size, clamped to the repository maximum.
    let pageSize: Int

    @Published private(set) var resultCounts: [ComparisonResultType: Int64] = [:]

    // Filter & Paging State
    @Published var activeFilter: ComparisonResultFilter = .all {
        didSet { loadInitialPage() }
    }
    @Published private(set) var currentPage: ComparisonResultPage?
    @Published private(set) var activePageOffset: Int = 0
    @Published private(set) var error: String?
    @Published private(set) var isLoading = false

    // Selection & Metadata Detail State
    @Published var selectedRowID: Int64? {
        didSet { fetchDetailsForSelection() }
    }
    @Published private(set) var selectedRow: ComparisonResultRow?
    @Published private(set) var selectedLeftMetadata: SideMetadata?
    @Published private(set) var selectedRightMetadata: SideMetadata?
    @Published private(set) var selectedFieldDifferences: [FieldDifference] = []

    // Navigation availability from repository truth
    @Published private(set) var canGoPrevious = false
    @Published private(set) var canGoNext = false

    private let database: CatalogDatabase
    private let resultRepository: ComparisonResultRepository
    private var searchGeneration: UInt64 = 0

    init(database: CatalogDatabase, record: ComparisonRecord, pageSize: Int = 500) {
        self.database = database
        self.record = record
        self.pageSize = min(max(1, pageSize), ComparisonResultRepository.maximumPageSize)
        self.resultRepository = ComparisonResultRepository(database: database)
    }

    func open() {
        do {
            resultCounts = try resultRepository.resultCounts(comparisonID: record.id)
            loadInitialPage()
        } catch {
            self.error = ComparisonUIErrorDescription.message(for: error)
        }
    }

    // MARK: - Bounded paging

    /// First page at offset zero; also the filter-change reset path.
    func loadInitialPage() {
        loadPage(at: 0)
    }

    /// Advances to the page after the current one. The page replaces the
    /// current page — rows are never accumulated.
    func showNextPage() {
        guard let current = currentPage, current.isTruncated, !isLoading else { return }
        loadPage(at: current.offset + current.limit)
    }

    /// Moves back one full page. The page replaces the current page.
    func showPreviousPage() {
        guard let current = currentPage, current.offset > 0, !isLoading else { return }
        loadPage(at: max(0, current.offset - current.limit))
    }

    var canShowNextPage: Bool { currentPage?.isTruncated == true && !isLoading }
    var canShowPreviousPage: Bool { (currentPage?.offset ?? 0) > 0 && !isLoading }

    /// Loads one deterministic page at `offset`, replacing the current page.
    /// A response is applied only when no newer request superseded it.
    private func loadPage(at offset: Int) {
        searchGeneration += 1
        let generation = searchGeneration
        let filter = activeFilter
        let comparisonID = record.id
        let limit = pageSize
        let repository = resultRepository
        isLoading = true
        error = nil

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let page = try repository.results(
                    comparisonID: comparisonID,
                    filter: filter,
                    offset: offset,
                    limit: limit
                )
                DispatchQueue.main.async {
                    if generation == self.searchGeneration {
                        self.currentPage = page
                        self.activePageOffset = page.offset
                        self.isLoading = false
                        // Reset selection when it is not part of the new page.
                        if let selectedRowID = self.selectedRowID {
                            if !page.rows.contains(where: { $0.id == selectedRowID }) {
                                self.selectedRowID = nil
                            }
                        }
                        self.fetchDetailsForSelection()
                        self.refreshNavigationAvailability()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    if generation == self.searchGeneration {
                        self.error = ComparisonUIErrorDescription.message(for: error)
                        self.isLoading = false
                    }
                }
            }
        }
    }

    // MARK: - Navigation

    /// Deterministic next/previous over the active filter. When the adjacent
    /// row lies outside the loaded page, the bounded page containing it is
    /// materialized and the row is selected within it.
    func navigate(direction: ComparisonResultRepository.ComparisonDirection) {
        let anchor = selectedRow.map { ComparisonResultAnchor(resultPath: $0.resultPath, id: $0.id) }
        let filter = activeFilter
        let comparisonID = record.id
        let repository = resultRepository
        do {
            let target = try repository.navigate(
                comparisonID: comparisonID,
                filter: filter,
                from: anchor,
                direction: direction,
                limit: 1
            ).first
            guard let target else {
                refreshNavigationAvailability()
                return
            }
            if currentPage?.rows.contains(where: { $0.id == target.id }) == true {
                selectedRowID = target.id
                refreshNavigationAvailability()
            } else {
                materializePage(containing: target, direction: direction)
            }
        } catch {
            self.error = ComparisonUIErrorDescription.message(for: error)
        }
    }

    /// Loads the bounded page containing `target`, then selects it.
    private func materializePage(containing target: ComparisonResultRow, direction: ComparisonResultRepository.ComparisonDirection) {
        let anchor = ComparisonResultAnchor(resultPath: target.resultPath, id: target.id)
        let comparisonID = record.id
        let filter = activeFilter
        let limit = pageSize
        let repository = resultRepository
        do {
            guard let position = try repository.position(of: anchor, comparisonID: comparisonID, filter: filter) else {
                // The row left the filtered set (should not happen under a
                // stable filter); select it without a page so the UI shows
                // the empty state rather than a stale row.
                selectedRowID = nil
                refreshNavigationAvailability()
                return
            }
            let pageOffset = (position / pageSize) * pageSize
            searchGeneration += 1
            let generation = searchGeneration
            isLoading = true
            error = nil
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let page = try repository.results(
                        comparisonID: comparisonID,
                        filter: filter,
                        offset: pageOffset,
                        limit: limit
                    )
                    DispatchQueue.main.async {
                        if generation == self.searchGeneration {
                            self.currentPage = page
                            self.activePageOffset = page.offset
                            self.isLoading = false
                            self.selectedRowID = target.id
                            self.fetchDetailsForSelection()
                            self.refreshNavigationAvailability()
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        if generation == self.searchGeneration {
                            self.error = ComparisonUIErrorDescription.message(for: error)
                            self.isLoading = false
                        }
                    }
                }
            }
        } catch {
            self.error = ComparisonUIErrorDescription.message(for: error)
        }
    }

    /// Boundary truth from the repository: with no selection, "next" is
    /// available exactly when the filtered set has a first row; with a
    /// selection, each direction is available exactly when the repository
    /// returns a row beyond it. Never derived from page emptiness.
    func refreshNavigationAvailability() {
        let anchor = selectedRow.map { ComparisonResultAnchor(resultPath: $0.resultPath, id: $0.id) }
        let filter = activeFilter
        let comparisonID = record.id
        let repository = resultRepository
        do {
            let hasNext = try !repository.navigate(
                comparisonID: comparisonID, filter: filter, from: anchor, direction: .next, limit: 1
            ).isEmpty
            var hasPrevious = false
            if anchor != nil {
                hasPrevious = try !repository.navigate(
                    comparisonID: comparisonID, filter: filter, from: anchor, direction: .previous, limit: 1
                ).isEmpty
            }
            canGoNext = hasNext
            canGoPrevious = hasPrevious
        } catch {
            canGoNext = false
            canGoPrevious = false
        }
    }

    // MARK: - Detail materialization

    /// Loads the selected row's two-side metadata and field-level differences
    /// through the approved repository APIs only.
    private func fetchDetailsForSelection() {
        guard let rowID = selectedRowID, let row = currentPage?.rows.first(where: { $0.id == rowID }) else {
            selectedRow = nil
            selectedLeftMetadata = nil
            selectedRightMetadata = nil
            selectedFieldDifferences = []
            refreshNavigationAvailability()
            return
        }
        selectedRow = row
        do {
            selectedLeftMetadata = try resultRepository.entryMetadata(
                id: row.leftEntryID, snapshotID: record.left.snapshotID
            )
            selectedRightMetadata = try resultRepository.entryMetadata(
                id: row.rightEntryID, snapshotID: record.right.snapshotID
            )
            selectedFieldDifferences = try resultRepository.fieldDifferences(for: row, comparisonID: record.id)
            error = nil
        } catch {
            self.error = ComparisonUIErrorDescription.message(for: error)
        }
        refreshNavigationAvailability()
    }
}
