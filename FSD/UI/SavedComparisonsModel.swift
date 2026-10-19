import Foundation
import Combine
import CryptoKit

/// All catalog work runs on this serial worker, including receipt validation and
/// offline seal validation. The main actor only publishes bounded view state.
@MainActor
final class SavedComparisonsModel: ObservableObject {
    enum Eligibility: Equatable {
        case checking, available, deleted, saved(UUID), unavailable(String)
    }
    enum PageKind: String, CaseIterable {
        case results = "Results", left = "Left Evidence", right = "Right Evidence"
        case groups = "Collisions", members = "Collision Members"
        case leftIssues = "Left Issues", rightIssues = "Right Issues"
    }
    @Published private(set) var eligibility: Eligibility = .unavailable("Open a completed comparison to save it.")
    @Published private(set) var isSaving = false
    @Published private(set) var saveMessage: String?
    @Published private(set) var saveError: String?
    @Published private(set) var operationID: UUID?
    @Published private(set) var summaries: [SavedComparisonSummary] = []
    @Published private(set) var libraryLoading = false
    @Published private(set) var libraryError: String?
    @Published private(set) var libraryHasNext = false
    @Published private(set) var libraryPage = 0
    @Published private(set) var readerID: UUID?
    @Published private(set) var receipt: ComparisonCompletionReceipt?
    @Published private(set) var readerLoading = false
    @Published private(set) var readerError: String?
    @Published private(set) var rows: [SavedEvidenceRow] = []
    @Published private(set) var selected: SavedEvidenceRow?
    @Published private(set) var detailsLoading = false
    @Published private(set) var selectedLeft: SavedEvidenceRow?
    @Published private(set) var selectedRight: SavedEvidenceRow?
    @Published private(set) var pageIndex = 0
    @Published private(set) var hasNext = false
    @Published private(set) var isDeleting = false
    @Published var deletionCandidate: UUID?
    @Published var pageKind: PageKind = .results { didSet { if oldValue != pageKind { loadPage(reset:true) } } }

    private let database: CatalogDatabase
    private let repository: SavedComparisonRepository
    private let worker = DispatchQueue(label:"FSD.saved-comparison-ui",qos:.userInitiated)
    private var originalRecord: ComparisonRecord?
    private var request: SavedComparisonRequest?
    private var token: ComparisonCancellationToken?
    private var reader: SavedComparisonReader?
    private var prepareGeneration = UUID()
    private var readerGeneration = UUID()
    private var libraryGeneration = UUID()
    private var pageCursors: [Int64] = [0]
    private var libraryCursors = [""]
    // Only lower ceilings can be supplied by isolated tests.
    var saveLimits = SavedComparisonLimits()

    init(database: CatalogDatabase, repository: SavedComparisonRepository? = nil) {
        self.database = database
        self.repository = repository ?? SavedComparisonRepository(database:database)
    }

    static func operationID(receipt: ComparisonCompletionReceipt, deleted: [UUID]) -> UUID {
        let identity = ["FSD-explicit-save-ui-v1",receipt.catalogGeneration.uuidString,receipt.completionToken.uuidString,String(receipt.comparisonID)] + deleted.map(\.uuidString).sorted()
        let bytes = Array(SHA256.hash(data:Data(identity.joined(separator:"\n").utf8)).prefix(16))
        return UUID(uuid:(bytes[0],bytes[1],bytes[2],bytes[3],bytes[4],bytes[5],bytes[6],bytes[7],bytes[8],bytes[9],bytes[10],bytes[11],bytes[12],bytes[13],bytes[14],bytes[15]))
    }

    func prepare(_ record: ComparisonRecord) {
        guard !isSaving else { return }
        originalRecord = record
        let generation = UUID(); prepareGeneration = generation
        eligibility = .checking; saveError = nil; saveMessage = nil
        request = nil; operationID = nil
        guard record.status == .complete else {
            eligibility = .unavailable("Only a completed comparison can be saved. This comparison is \(record.status.rawValue).")
            return
        }
        let db = database, repo = repository
        worker.async {
            let result = Result { () -> (ComparisonCompletionReceipt,[SavedComparisonOperation]) in
                guard let receipt = try ComparisonCompletionReceiptRepository(database:db).receipt(comparisonID:record.id) else { throw SavedComparisonError.ineligible }
                let operations = try repo.operations(for:receipt)
                if let operation = operations.first(where:{ !$0.isDeleted }) { _ = try repo.open(id:operation.artifactID) }
                return (receipt,operations)
            }
            DispatchQueue.main.async { [self] in
                guard prepareGeneration == generation else { return }
                switch result {
                case .success(let (receipt,operations)):
                    let id = Self.operationID(receipt:receipt,deleted:operations.filter(\.isDeleted).map(\.id))
                    operationID = id; request = SavedComparisonRequest(operationID:id,receipt:receipt)
                    if let existing = operations.first(where:{ !$0.isDeleted }) { eligibility = .saved(existing.artifactID) }
                    else { eligibility = operations.isEmpty ? .available : .deleted }
                case .failure(let error): eligibility = .unavailable(Self.message(error))
                }
            }
        }
    }

    /// Sole production entry to save(). A deleted completion requires the
    /// separate confirmed Save Again action; retry never crosses that boundary.
    func save(asNewAfterDeletion: Bool = false) {
        guard !isSaving, let request else { return }
        guard eligibility == .available || (eligibility == .deleted && asNewAfterDeletion) else { return }
        isSaving = true; saveMessage = "Saving metadata…"; saveError = nil
        let cancellation = ComparisonCancellationToken(); token = cancellation
        let repo = repository, limits = saveLimits
        worker.async {
            let result = Result { try repo.save(request,limits:limits,isCancelled:{ cancellation.isCancelled }) }
            DispatchQueue.main.async { [self] in
                isSaving = false; token = nil
                switch result {
                case .success(let id):
                    eligibility = .saved(id); saveMessage = "Comparison saved. Available offline in Saved Comparisons."
                    reloadLibrary()
                case .failure(let error):
                    saveMessage = nil; saveError = Self.message(error)
                    if (error as? SavedComparisonError) == .deleted {
                        eligibility = .unavailable("This operation was deleted. Reopen the comparison to explicitly save a new copy.")
                    }
                }
            }
        }
    }

    func cancelSave() { token?.cancel(); if isSaving { saveMessage = "Cancelling Save… Waiting for the transaction to finish." } }

    /// Barrier after the Save task and its main-queue outcome. Disposal only
    /// runs after commit/rollback, even if cancellation arrived after commit.
    func cancelAndWait(_ completion: @escaping () -> Void) {
        cancelSave()
        whenCatalogIdle(completion)
    }
    func whenCatalogIdle(_ completion: @escaping () -> Void) {
        worker.async { DispatchQueue.main.async(execute:completion) }
    }

    func reloadLibrary() { libraryCursors = [""]; libraryPage = 0; loadLibrary() }
    func nextLibraryPage() {
        guard !libraryLoading, libraryHasNext, let last = summaries.last else { return }
        libraryCursors.append(last.id.uuidString); libraryPage += 1; loadLibrary()
    }
    func previousLibraryPage() {
        guard !libraryLoading, libraryPage > 0 else { return }
        libraryCursors.removeLast(); libraryPage -= 1; loadLibrary()
    }
    private func loadLibrary() {
        let generation = UUID(); libraryGeneration = generation
        libraryLoading = true; libraryError = nil
        let repo = repository, cursor = libraryCursors.last!
        worker.async {
            let result = Result { () -> ([SavedComparisonSummary],Bool) in
                let page = try repo.summaries(after:cursor)
                let more = try page.last.map { try !repo.list(after:$0.id.uuidString,limit:1).isEmpty } ?? false
                return (page,more)
            }
            DispatchQueue.main.async { [self] in
                guard libraryGeneration == generation else { return }
                libraryLoading = false
                switch result {
                case .success(let (page,more)): summaries = page; libraryHasNext = more
                case .failure(let error): summaries = []; libraryHasNext = false; libraryError = Self.message(error)
                }
            }
        }
    }

    func open(_ id: UUID) {
        closeReader(); readerID = id; readerLoading = true
        let generation = readerGeneration, repo = repository
        worker.async {
            let result = Result { try repo.open(id:id) }
            DispatchQueue.main.async { [self] in
                guard readerGeneration == generation else { return }
                readerLoading = false
                switch result {
                case .success(let value): reader = value; receipt = value.receipt; loadPage(reset:true)
                case .failure(let error): readerError = Self.message(error)
                }
            }
        }
    }
    func closeReader() {
        readerGeneration = UUID(); readerID = nil; receipt = nil; reader = nil
        readerLoading = false; readerError = nil; rows = []; clearSelection()
        pageCursors = [0]; pageIndex = 0; hasNext = false
    }
    func nextPage() {
        guard !readerLoading, hasNext, let last = rows.last else { return }
        pageCursors.append(last.id); pageIndex += 1; loadPage()
    }
    func previousPage() {
        guard !readerLoading, pageIndex > 0 else { return }
        pageCursors.removeLast(); pageIndex -= 1; loadPage()
    }
    func loadPage(reset: Bool = false) {
        guard let reader else { return }
        if reset { pageCursors = [0]; pageIndex = 0 }
        let generation = UUID(); readerGeneration = generation
        readerLoading = true; readerError = nil; clearSelection(); rows = []
        let kind = pageKind, cursor = pageCursors.last!
        worker.async {
            let result = Result { () -> [SavedEvidenceRow] in
                switch kind {
                case .results: return try reader.results(after:cursor)
                case .left: return try reader.entries(side:.left,after:cursor)
                case .right: return try reader.entries(side:.right,after:cursor)
                case .groups: return try reader.collisionGroups(after:cursor)
                case .members: return try reader.collisionMembers(after:cursor)
                case .leftIssues: return try reader.issues(side:.left,after:cursor)
                case .rightIssues: return try reader.issues(side:.right,after:cursor)
                }
            }
            DispatchQueue.main.async { [self] in
                guard readerGeneration == generation else { return }
                readerLoading = false
                switch result {
                case .success(let value): rows = value; hasNext = value.count == 256
                case .failure(let error): readerError = Self.message(error); hasNext = false
                }
            }
        }
    }
    func select(_ row: SavedEvidenceRow?) {
        clearSelection(); selected = row
        guard let row, let reader else { return }
        detailsLoading = true
        let generation = readerGeneration, kind = pageKind
        worker.async {
            let result = Result { () -> (SavedEvidenceRow?,SavedEvidenceRow?) in
                if kind == .left { return (row,nil) }
                if kind == .right { return (nil,row) }
                var left = row.leftEntryID, right = row.rightEntryID
                if let entry = row.entryID {
                    if kind == .leftIssues || row.original["side"]?.text == "left" { left = entry }
                    if kind == .rightIssues || row.original["side"]?.text == "right" { right = entry }
                }
                let l = try left.flatMap { try reader.entry(id:$0,side:.left) }
                let r = try right.flatMap { try reader.entry(id:$0,side:.right) }
                if (left != nil && l == nil) || (right != nil && r == nil) { throw SavedComparisonError.corrupt("selected entry reference") }
                return (l,r)
            }
            DispatchQueue.main.async { [self] in
                guard readerGeneration == generation, selected?.id == row.id else { return }
                detailsLoading = false
                switch result {
                case .success(let (left,right)): selectedLeft = left; selectedRight = right
                case .failure(let error): readerError = Self.message(error)
                }
            }
        }
    }
    private func clearSelection() { detailsLoading = false; selected = nil; selectedLeft = nil; selectedRight = nil }

    func confirmDeletion() {
        guard !isDeleting, let id = deletionCandidate else { return }
        deletionCandidate = nil; isDeleting = true
        let repo = repository
        worker.async {
            let result = Result { try repo.delete(id:id) }
            DispatchQueue.main.async { [self] in
                isDeleting = false
                switch result {
                case .success:
                    if readerID == id { closeReader() }
                    if eligibility == .saved(id), let record = originalRecord { prepare(record) }
                    reloadLibrary()
                case .failure(let error): libraryError = Self.message(error); readerError = Self.message(error)
                }
            }
        }
    }

    static func message(_ error: Error) -> String {
        if let error = error as? SavedComparisonError {
            switch error {
            case .ineligible: return "This comparison has no validated completion receipt. Legacy comparisons cannot be saved exactly."
            case .identityConflict: return "Save identity changed. Reopen the comparison before continuing."
            case .deleted: return "This saved comparison was deleted. An old retry cannot restore it."
            case .notFound: return "Saved evidence is no longer available. Reload Saved Comparisons."
            case .corrupt: return "Evidence is incomplete, stale or corrupt. It cannot be saved or opened exactly."
            case .budgetExceeded("operation discovery"): return "Save discovery exceeds the supported 4,096-operation catalog limit. No new artifact was created; use Saved Comparisons to inspect existing artifacts."
            case .budgetExceeded: return "This operation exceeds the supported metadata, size or time budget (100,000 accounted rows, 60 seconds). No new saved comparison was committed."
            case .cancelled: return "Save cancelled. No new saved comparison was committed."
            }
        }
        if error is CompletionReceiptError { return "Completion evidence is stale or corrupt. Exact Save is unavailable." }
        return "The catalog operation failed. Reload or retry the same Save operation; no success has been confirmed."
    }
}
