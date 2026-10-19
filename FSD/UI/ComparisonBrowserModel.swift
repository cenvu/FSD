import AppKit
import SwiftUI
import Combine

/// One bounded original-result page. Every catalog read (including details,
/// position and ancestors) runs off the main actor. A request generation and
/// cancellation token cover the entire page/selection/context publication.
@MainActor
final class ComparisonBrowserModel: ObservableObject {
    let record: ComparisonRecord
    let pageSize: Int
    @Published private(set) var resultCounts: [ComparisonResultType: Int64] = [:]
    @Published var activeFilter: ComparisonResultFilter = .all {
        didSet { if !changingFilter { loadInitialPage() } }
    }
    @Published private(set) var currentPage: ComparisonResultPage?
    @Published private(set) var activePageOffset = 0
    @Published private(set) var error: String?
    @Published private(set) var isLoading = false
    @Published var selectedRowID: Int64? {
        didSet { if !publishing { loadSelection() } }
    }
    @Published private(set) var selectedRow: ComparisonResultRow?
    @Published private(set) var selectedLeftMetadata: SideMetadata?
    @Published private(set) var selectedRightMetadata: SideMetadata?
    @Published private(set) var selectedFieldDifferences: [FieldDifference] = []
    @Published private(set) var ancestorContext: ComparisonAncestorContext?
    @Published private(set) var ancestorError: String?
    @Published private(set) var returnTarget: ComparisonResultRow?
    @Published private(set) var canGoPrevious = false
    @Published private(set) var canGoNext = false
    /// Changes even when a category reselects the same ID, so scroll can reveal it.
    @Published private(set) var revealGeneration: UInt64 = 0
    private let resultRepository: ComparisonResultRepository
    private var searchGeneration: UInt64 = 0
    private var requestToken: ComparisonCancellationToken?
    private var isPausedForSave = false
    private var isClosed = false
    private var publishing = false
    private var changingFilter = false

    init(database: CatalogDatabase, record: ComparisonRecord, pageSize: Int = 500) {
        self.record = record
        self.pageSize = min(max(1,pageSize),ComparisonResultRepository.maximumPageSize)
        resultRepository = ComparisonResultRepository(database:database)
    }

    func setSaveInProgress(_ active: Bool) {
        guard !isClosed, active != isPausedForSave else { return }
        isPausedForSave = active
        if active { invalidate() }
        else { request(.page(activePageOffset,selectedRowID,false)) }
    }

    /// A detached browser can never publish again, even if a read was already
    /// waiting behind Save or disposal when its workspace closed/switched.
    func close() { isClosed = true; invalidate(); clearSelection(); currentPage = nil; returnTarget = nil }
    private func invalidate() {
        searchGeneration += 1; requestToken?.cancel(); requestToken = nil
        isLoading = false; canGoNext = false; canGoPrevious = false
    }
    func open() { loadInitialPage() }
    func loadInitialPage() {
        returnTarget = nil; currentPage = nil; activePageOffset = 0; clearSelection()
        request(.page(0,nil,false))
    }
    /// Exact summary→backend filter mapping is supplied by the button itself.
    /// Counts preserve the existing summary semantics (All excludes ignored).
    func selectCategory(_ filter: ComparisonResultFilter) {
        guard !isClosed, !isPausedForSave else { return }
        changingFilter = true; activeFilter = filter; changingFilter = false
        currentPage = nil; activePageOffset = 0; returnTarget = nil; clearSelection()
        request(.page(0,nil,true))
    }
    func showNextPage() {
        guard canShowNextPage, let page = currentPage else { return }
        request(.page(page.offset+page.limit,nil,false))
    }
    func showPreviousPage() {
        guard canShowPreviousPage, let page = currentPage else { return }
        request(.page(max(0,page.offset-page.limit),nil,false))
    }
    var canShowNextPage: Bool { !isClosed && !isPausedForSave && !isLoading && currentPage?.isTruncated == true }
    var canShowPreviousPage: Bool { !isClosed && !isPausedForSave && !isLoading && (currentPage?.offset ?? 0)>0 }

    func navigate(direction: ComparisonResultRepository.ComparisonDirection) {
        guard !isPausedForSave, !isClosed else { return }
        returnTarget = nil
        request(.navigate(selectedRow,direction))
    }
    func revealAncestor(_ row: ComparisonResultRow) {
        guard !isPausedForSave, !isClosed,
              let context = ancestorContext, context.ancestors.contains(row) else { return }
        returnTarget = returnTarget ?? context.target
        reveal(row)
    }
    func returnToTarget() {
        guard let row = returnTarget, !isPausedForSave, !isClosed else { return }
        returnTarget = nil; reveal(row)
    }
    private func reveal(_ row: ComparisonResultRow) {
        // An ancestor may have a different outcome; showing All is explicit,
        // and position still requires the exact path+ID in this comparison.
        changingFilter = true; activeFilter = .all; changingFilter = false
        request(.locate(row))
    }
    func refreshNavigationAvailability() {
        guard !isLoading else { return }
        request(.page(activePageOffset,selectedRowID,false))
    }
    private func loadSelection() {
        guard !isPausedForSave, !isClosed else { return }
        returnTarget = nil
        let id = selectedRowID
        clearSelection()
        request(.page(activePageOffset,id,false))
    }
    private func clearSelection() {
        publishing = true; selectedRowID = nil; publishing = false
        selectedRow = nil; selectedLeftMetadata = nil; selectedRightMetadata = nil
        selectedFieldDifferences = []; ancestorContext = nil; ancestorError = nil
    }

    private enum Request: Sendable {
        case page(Int,Int64?,Bool)
        case navigate(ComparisonResultRow?,ComparisonResultRepository.ComparisonDirection)
        case locate(ComparisonResultRow)
    }
    private struct Response: Sendable {
        let page: ComparisonResultPage
        let counts: [ComparisonResultType:Int64]
        let selected: ComparisonResultRow?
        let left: SideMetadata?
        let right: SideMetadata?
        let differences: [FieldDifference]
        let context: ComparisonAncestorContext?
        let ancestorError: String?
        let next: Bool
        let previous: Bool
    }
    private func request(_ action: Request) {
        guard !isPausedForSave, !isClosed else { return }
        invalidate()
        let generation = searchGeneration, token = ComparisonCancellationToken()
        requestToken = token; isLoading = true; error = nil
        let repo = resultRepository, record = record, filter = activeFilter, limit = pageSize
        let oldOffset = activePageOffset
        DispatchQueue.global(qos:.userInitiated).async { [weak self] in
            let result = Result { () -> Response in
                func check() throws { if token.isCancelled { throw ComparisonError.cancelled } }
                try check()
                var offset = oldOffset, targetID: Int64?, first = false
                var target: ComparisonResultRow?
                switch action {
                case .page(let requested,let selection,let selectFirst): offset = requested; targetID = selection; first = selectFirst
                case .navigate(let row,let direction):
                    target = try repo.navigate(comparisonID:record.id,filter:filter,from:row.map { .init(resultPath:$0.resultPath,id:$0.id) },direction:direction,limit:1).first ?? row
                case .locate(let row): target = row
                }
                try check()
                if let target {
                    guard target.comparisonID == record.id,
                          let position = try repo.position(of:.init(resultPath:target.resultPath,id:target.id),comparisonID:record.id,filter:filter) else { throw ComparisonAncestorError.unavailable }
                    offset = (position/limit)*limit; targetID = target.id
                }
                let page = try repo.results(comparisonID:record.id,filter:filter,offset:offset,limit:limit)
                try check()
                let row = first ? page.rows.first : page.rows.first { $0.id == targetID }
                var context: ComparisonAncestorContext?, contextError: String?
                if let row {
                    do {
                        context = try repo.ancestorContext(resultID:row.id,comparisonID:record.id)
                        guard context?.target == row else { throw ComparisonAncestorError.invalidEvidence }
                    } catch let error as ComparisonAncestorError { context = nil; contextError = error.errorDescription }
                }
                try check()
                let left = try row.flatMap { try repo.entryMetadata(id:$0.leftEntryID,snapshotID:record.left.snapshotID) }
                let right = try row.flatMap { try repo.entryMetadata(id:$0.rightEntryID,snapshotID:record.right.snapshotID) }
                let differences = try row.map { try repo.fieldDifferences(for:$0,comparisonID:record.id) } ?? []
                try check()
                let anchor = row.map { ComparisonResultAnchor(resultPath:$0.resultPath,id:$0.id) }
                let next = try !repo.navigate(comparisonID:record.id,filter:filter,from:anchor,direction:.next,limit:1).isEmpty
                let previous = try anchor.map { try !repo.navigate(comparisonID:record.id,filter:filter,from:$0,direction:.previous,limit:1).isEmpty } ?? false
                let counts = try repo.resultCounts(comparisonID:record.id)
                try check()
                return Response(page:page,counts:counts,selected:row,left:left,right:right,differences:differences,context:context,ancestorError:contextError,next:next,previous:previous)
            }
            DispatchQueue.main.async {
                guard let self, !self.isClosed, !self.isPausedForSave, !token.isCancelled,
                      generation == self.searchGeneration else { return }
                self.isLoading = false
                switch result {
                case .success(let value):
                    self.currentPage = value.page; self.activePageOffset = value.page.offset
                    self.resultCounts = value.counts
                    self.publishing = true; self.selectedRowID = value.selected?.id; self.publishing = false
                    self.selectedRow = value.selected; self.selectedLeftMetadata = value.left; self.selectedRightMetadata = value.right
                    self.selectedFieldDifferences = value.differences; self.ancestorContext = value.context; self.ancestorError = value.ancestorError
                    self.canGoNext = value.next; self.canGoPrevious = value.previous
                    if value.selected != nil { self.revealGeneration += 1 }
                case .failure(let error):
                    self.clearSelection(); self.currentPage = nil
                    self.error = (error as? ComparisonAncestorError)?.errorDescription ?? ComparisonUIErrorDescription.message(for:error)
                }
            }
        }
    }
}
