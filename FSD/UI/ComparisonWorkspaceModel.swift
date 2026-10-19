import AppKit
import SwiftUI
import Combine

/// Orchestrates comparison creation, history, the active workspace and the
/// canonical workspace lifecycle.
///
/// Canonical orientation (ADR-027): the **left side is the reference
/// ("before") tree** and the **right side is the changed ("after") tree**.
/// In live-to-snapshot mode the snapshot is therefore the left/reference side
/// and the live folder is the right/changed side, so `added` means "new since
/// the snapshot". The creation view, `canStart`, request construction and the
/// service call all agree on this mapping.
@MainActor
final class ComparisonWorkspaceModel: ObservableObject {
    @Published private(set) var history: [ComparisonRecord] = []
    @Published private(set) var error: String?
    @Published private(set) var availableSnapshots: [SnapshotSummary] = []
    @Published private(set) var profiles: [ComparisonProfile] = []

    // Creation State
    @Published var mode: ComparisonMode = .snapshotToSnapshot {
        didSet { resetCreationState() }
    }
    @Published var selectedLeftSnapshotID: SnapshotID?
    @Published var selectedRightSnapshotID: SnapshotID?
    @Published var selectedLeftLiveRoot: URL?
    @Published var selectedRightLiveRoot: URL?
    @Published var selectedProfileID: Int64?

    // Execution State
    @Published private(set) var isRunning = false
    @Published private(set) var progress = ComparisonProgress(processedEntries: 0, phase: "")
    @Published private(set) var terminalState: ComparisonStatus?

    // View State
    @Published var activeComparisonID: ComparisonID?
    @Published private(set) var activeBrowser: ComparisonBrowserModel?

    let savedComparisons: SavedComparisonsModel
    @Published var showsSavedComparisons = false {
        didSet { updateOriginalBrowserPause() }
    }
    @Published private(set) var isClosing = false

    private let database: CatalogDatabase
    private let comparisonService: ComparisonService
    private let historyRepository: SnapshotHistoryRepository
    private let resultRepository: ComparisonResultRepository
    private let profileRepository: ComparisonProfileRepository
    private var savedObservation: AnyCancellable?
    private var savedBusyObservation: AnyCancellable?
    private var cancellationToken: ComparisonCancellationToken?

    init(database: CatalogDatabase, savedRepository: SavedComparisonRepository? = nil) {
        self.database = database
        self.savedComparisons = SavedComparisonsModel(database:database,repository:savedRepository)
        self.comparisonService = ComparisonService(database: database)
        self.historyRepository = SnapshotHistoryRepository(database: database)
        self.resultRepository = ComparisonResultRepository(database: database)
        self.profileRepository = ComparisonProfileRepository(database: database)

        self.savedObservation = savedComparisons.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
        self.savedBusyObservation = savedComparisons.$isSaving.removeDuplicates().sink { [weak self] active in
            self?.updateOriginalBrowserPause(activeSave:active)
        }
        self.selectedProfileID = ComparisonProfileRepository.fastMetadataProfileID
    }

    private func updateOriginalBrowserPause(activeSave: Bool? = nil) {
        guard !isClosing, let browser = activeBrowser else { return }
        if (activeSave ?? savedComparisons.isSaving) || showsSavedComparisons {
            browser.setSaveInProgress(true)
        } else {
            // A closed/hidden reader can still be finishing its queued seal
            // validation. Resume original main-actor reads only past that work.
            savedComparisons.whenCatalogIdle { [weak self, weak browser] in
                guard let self, !self.isClosing, !self.showsSavedComparisons,
                      !self.savedComparisons.isSaving, self.activeBrowser === browser else { return }
                browser?.setSaveInProgress(false)
            }
        }
    }

    func refresh() {
        guard !savedComparisons.isSaving, !isClosing else { return }
        do {
            history = try resultRepository.listComparisons()
            availableSnapshots = try historyRepository.listSnapshots().filter { $0.isComplete }
            profiles = try profileRepository.allProfiles()
            error = nil
        } catch {
            self.error = ComparisonUIErrorDescription.message(for: error)
        }
    }

    func resetCreationState() {
        selectedLeftSnapshotID = nil
        selectedRightSnapshotID = nil
        selectedLeftLiveRoot = nil
        selectedRightLiveRoot = nil
        error = nil
    }

    func chooseLiveRoot(for side: Side) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose Live Source"
        if panel.runModal() == .OK, let url = panel.url {
            if side == .left {
                selectedLeftLiveRoot = url
            } else {
                selectedRightLiveRoot = url
            }
        }
    }

    /// Bounded, human-readable reason a comparison cannot start, or `nil`
    /// when it can. Covers invalid side selection, the same side selected
    /// twice, and missing live sources without consulting the backend.
    var validationMessage: String? {
        if isRunning { return nil }
        guard selectedProfileID != nil else { return "Select a comparison profile." }
        switch mode {
        case .snapshotToSnapshot:
            if selectedLeftSnapshotID == nil || selectedRightSnapshotID == nil {
                return "Select a reference snapshot (left) and a changed snapshot (right)."
            }
            if selectedLeftSnapshotID == selectedRightSnapshotID {
                return "The same snapshot cannot be used for both sides."
            }
        case .liveToSnapshot:
            if selectedLeftSnapshotID == nil {
                return "Select the reference snapshot (left)."
            }
            if selectedRightLiveRoot == nil {
                return "Choose the live folder (right / changed side)."
            }
        case .liveToLive:
            if selectedLeftLiveRoot == nil || selectedRightLiveRoot == nil {
                return "Choose both live folders."
            }
            if selectedLeftLiveRoot == selectedRightLiveRoot {
                return "The same folder cannot be used for both sides."
            }
        }
        return nil
    }

    var canStart: Bool {
        validationMessage == nil && !isClosing
    }

    /// Which live side the given side selector presents in the current mode.
    /// Live-to-snapshot is canonical: left = snapshot/reference,
    /// right = live/changed.
    func isLiveSelector(_ side: Side) -> Bool {
        switch mode {
        case .liveToLive: return true
        case .liveToSnapshot: return side == .right
        case .snapshotToSnapshot: return false
        }
    }

    func start() {
        guard canStart, !isRunning, let profileID = selectedProfileID else { return }

        let token = ComparisonCancellationToken()
        cancellationToken = token
        isRunning = true
        terminalState = nil
        error = nil
        progress = ComparisonProgress(processedEntries: 0, phase: "Starting...")

        let service = self.comparisonService
        let currentMode = self.mode
        let leftSnapshotID = self.selectedLeftSnapshotID
        let rightSnapshotID = self.selectedRightSnapshotID
        let leftLiveRoot = self.selectedLeftLiveRoot
        let rightLiveRoot = self.selectedRightLiveRoot

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let record: ComparisonRecord

                let onProgress: (ComparisonProgress) -> Void = { p in
                    DispatchQueue.main.async {
                        self?.progress = p
                    }
                }

                switch currentMode {
                case .snapshotToSnapshot:
                    record = try service.snapshotToSnapshot(
                        leftSnapshotID: leftSnapshotID!,
                        rightSnapshotID: rightSnapshotID!,
                        profileID: profileID,
                        token: token,
                        onProgress: onProgress
                    )
                case .liveToSnapshot:
                    // Canonical request construction: the snapshot is the
                    // left/reference side, the live folder the right/changed.
                    record = try service.liveToSnapshot(
                        liveRoot: rightLiveRoot!,
                        snapshotID: leftSnapshotID!,
                        profileID: profileID,
                        token: token,
                        onProgress: onProgress
                    )
                case .liveToLive:
                    record = try service.liveToLive(
                        leftRoot: leftLiveRoot!,
                        rightRoot: rightLiveRoot!,
                        profileID: profileID,
                        token: token,
                        onProgress: onProgress
                    )
                }

                DispatchQueue.main.async {
                    self?.isRunning = false
                    self?.terminalState = record.status
                    self?.cancellationToken = nil
                    self?.refresh()
                    self?.openComparison(record)
                }
            } catch {
                DispatchQueue.main.async {
                    self?.isRunning = false
                    self?.cancellationToken = nil
                    self?.refresh()
                    if token.isCancelled || (error as? ComparisonError) == .cancelled {
                        self?.terminalState = .cancelled
                    } else {
                        self?.terminalState = .failed
                        self?.error = ComparisonUIErrorDescription.message(for: error)
                    }
                }
            }
        }
    }

    func cancel() {
        guard isRunning else { return }
        cancellationToken?.cancel()
        progress = ComparisonProgress(processedEntries: progress.processedEntries, phase: "Cancelling...")
    }

    func openComparison(_ record: ComparisonRecord) {
        guard !savedComparisons.isSaving, !isClosing else { return }
        savedComparisons.prepare(record)
        activeComparisonID = record.id
        activeBrowser?.close()
        activeBrowser = ComparisonBrowserModel(database: database, record: record)
        activeBrowser?.setSaveInProgress(showsSavedComparisons)
        activeBrowser?.open()
    }

    /// Canonical workspace close (ADR-012 / `ComparisonService.closeWorkspace`):
    /// running live-side comparisons are terminalized, live-side comparison
    /// records are disposed, and the transient snapshots they referenced are
    /// deleted. Snapshot-to-snapshot comparisons and ordinary snapshots are
    /// never touched, so leaving a snapshot-to-snapshot workspace preserves
    /// the persisted comparison.
    func closeComparison() {
        guard !isClosing else { return }
        if savedComparisons.isSaving {
            isClosing = true
            savedComparisons.cancelAndWait { [self] in
                isClosing = false
                closeComparison()
            }
            return
        }
        isClosing = true
        activeBrowser?.close()
        let service = comparisonService, results = resultRepository
        let db = database
        // Disposal can wait behind a pending original/hidden-reader query.
        // Keep that wait off MainActor and publish history only after settlement.
        DispatchQueue.global(qos:.userInitiated).async { [weak self] in
            let outcome = Result {
                try service.closeWorkspace()
                return (try results.listComparisons(),try SnapshotHistoryRepository(database:db).listSnapshots().filter { $0.isComplete },try ComparisonProfileRepository(database:db).allProfiles())
            }
            DispatchQueue.main.async {
                guard let self else { return }
                self.activeComparisonID = nil; self.activeBrowser = nil
                self.isClosing = false
                switch outcome {
                case .success(let values):
                    self.history = values.0; self.availableSnapshots = values.1; self.profiles = values.2; self.error = nil
                case .failure(let error): self.error = ComparisonUIErrorDescription.message(for:error)
                }
            }
        }
    }

    /// Explicit whole-comparison disposal (the schema's disposal API,
    /// ADR-027/ADR-028), then lifecycle transient release (ADR-012). The
    /// delete confirmation lives in the creation view; it always routes
    /// through this path.
    func deleteComparison(_ record: ComparisonRecord) {
        guard !savedComparisons.isSaving, !isClosing else { return }
        do {
            try resultRepository.deleteComparison(record.id)
            try TransientSnapshotLifecycle(database: database).cleanupUnreferencedTransients()
            if activeComparisonID == record.id {
                activeComparisonID = nil
                activeBrowser?.close()
                activeBrowser = nil
            }
            refresh()
        } catch {
            self.error = ComparisonUIErrorDescription.message(for: error)
        }
    }

    enum Side {
        case left
        case right
    }
}
