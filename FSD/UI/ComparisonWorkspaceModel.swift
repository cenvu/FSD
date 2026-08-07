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

    private let database: CatalogDatabase
    private let comparisonService: ComparisonService
    private let historyRepository: SnapshotHistoryRepository
    private let resultRepository: ComparisonResultRepository
    private let profileRepository: ComparisonProfileRepository
    private var cancellationToken: ComparisonCancellationToken?

    init(database: CatalogDatabase) {
        self.database = database
        self.comparisonService = ComparisonService(database: database)
        self.historyRepository = SnapshotHistoryRepository(database: database)
        self.resultRepository = ComparisonResultRepository(database: database)
        self.profileRepository = ComparisonProfileRepository(database: database)

        self.selectedProfileID = ComparisonProfileRepository.fastMetadataProfileID
    }

    func refresh() {
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
        validationMessage == nil
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
        activeComparisonID = record.id
        activeBrowser = ComparisonBrowserModel(database: database, record: record)
        activeBrowser?.open()
    }

    /// Canonical workspace close (ADR-012 / `ComparisonService.closeWorkspace`):
    /// running live-side comparisons are terminalized, live-side comparison
    /// records are disposed, and the transient snapshots they referenced are
    /// deleted. Snapshot-to-snapshot comparisons and ordinary snapshots are
    /// never touched, so leaving a snapshot-to-snapshot workspace preserves
    /// the persisted comparison.
    func closeComparison() {
        do {
            try comparisonService.closeWorkspace()
        } catch {
            self.error = ComparisonUIErrorDescription.message(for: error)
        }
        activeComparisonID = nil
        activeBrowser = nil
        refresh()
    }

    /// Explicit whole-comparison disposal (the schema's disposal API,
    /// ADR-027/ADR-028), then lifecycle transient release (ADR-012). The
    /// delete confirmation lives in the creation view; it always routes
    /// through this path.
    func deleteComparison(_ record: ComparisonRecord) {
        do {
            try resultRepository.deleteComparison(record.id)
            try TransientSnapshotLifecycle(database: database).cleanupUnreferencedTransients()
            if activeComparisonID == record.id {
                activeComparisonID = nil
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
