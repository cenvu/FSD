import AppKit
import SwiftUI

@main
struct FSDApp: App {
    @StateObject private var model = ApplicationModel()

    var body: some Scene {
        WindowGroup("FishSock Differ") {
            FSDAppShellView(model: model)
                .frame(minWidth: 1120, minHeight: 720)
        }
    }
}

enum CaptureState: Equatable {
    case idle
    case scanning
    case cancelling
    case complete
    case completeWithWarnings
    case interrupted
    case cancelled
    case failed(String)

    var title: String {
        switch self {
        case .idle: return "Ready"
        case .scanning: return "Scanning metadata"
        case .cancelling: return "Cancelling capture"
        case .complete: return "Complete"
        case .completeWithWarnings: return "Complete with warnings"
        case .interrupted: return "Interrupted"
        case .cancelled: return "Cancelled"
        case .failed: return "Failed"
        }
    }

    var isActive: Bool {
        switch self { case .scanning, .cancelling: return true; default: return false }
    }
}

struct CaptureProgressState: Equatable {
    var processedEntries: Int64 = 0
    var currentPath: String = ""
    var phase: String = "Ready"
}

@MainActor
final class ApplicationModel: ObservableObject {
    @Published private(set) var history: [SnapshotSummary] = []
    @Published private(set) var startupError: String?
    @Published private(set) var recoveryMessage: String?
    @Published private(set) var catalogDiagnostics: String = ""
    @Published private(set) var selectedSource: URL?
    @Published private(set) var captureState: CaptureState = .idle
    @Published private(set) var captureProgress = CaptureProgressState()
    @Published private(set) var browser: SnapshotBrowserModel?
    @Published var selectedSnapshotID: SnapshotID?

    /// The one app-scoped classification runtime. Shared by every browser;
    /// opening another browser never creates a second runtime.
    let classificationRuntime: ClassificationRuntimeService = .shared

    let database: CatalogDatabase?
    private let historyRepository: SnapshotHistoryRepository?
    /// Held for the process lifetime. Releasing it would let a second instance
    /// reconcile a capture this process is still running.
    private let processLock: CatalogProcessLock?
    private var cancellationToken: CaptureCancellationToken?

    init() {
        var resolvedDatabase: CatalogDatabase?
        var resolvedHistory: SnapshotHistoryRepository?
        var resolvedLock: CatalogProcessLock?
        do {
            let location = try CatalogLocationResolver.resolve()
            catalogDiagnostics = location.diagnosticLine
            // Startup diagnostics go to standard error as well as the window, so
            // an automated probe can confirm which catalog a launched process
            // used without reading the UI. Standard error rather than standard
            // output because it is unbuffered and survives an abrupt exit.
            FileHandle.standardError.write(Data("\(location.diagnosticLine)\n".utf8))

            // Single-process ownership (ADR-025) is taken before anything reads
            // or reconciles the catalog, so startup recovery can never interrupt
            // a capture owned by another live process.
            resolvedLock = try CatalogProcessLock(catalogURL: location.url)

            let catalog = try CatalogDatabase(url: location.url)
            resolvedDatabase = catalog
            resolvedHistory = SnapshotHistoryRepository(database: catalog)
            let report = try RecoveryService(database: catalog).recoverOrphanedScans()
            // Comparison scaffolding recovery (ADR-012): abandoned `running`
            // comparisons become `failed` — never complete — and transient
            // snapshots no comparison references are deleted. Both run before
            // any capture or comparison can start, and after the scan
            // recovery so a scanning transient is interrupted first.
            let lifecycle = TransientSnapshotLifecycle(database: catalog)
            let comparisonReport = try lifecycle.recoverOrphanedComparisons()
            _ = try lifecycle.cleanupUnreferencedTransients()
            var messages: [String] = []
            if let reportMessage = report.message { messages.append(reportMessage) }
            if let comparisonMessage = comparisonReport.message { messages.append(comparisonMessage) }
            recoveryMessage = messages.isEmpty ? nil : messages.joined(separator: " ")
            history = try resolvedHistory?.listSnapshots() ?? []
        } catch {
            startupError = error.localizedDescription
            // Also to standard error, so a failed startup is diagnosable from a
            // log rather than only from whoever is looking at the window.
            FileHandle.standardError.write(Data("FSD startup failed: \(error.localizedDescription)\n".utf8))
            resolvedLock?.unlock()
            resolvedLock = nil
            resolvedDatabase = nil
            resolvedHistory = nil
        }
        database = resolvedDatabase
        historyRepository = resolvedHistory
        processLock = resolvedLock
    }

    var hasDatabase: Bool { database != nil }

    func chooseSource() {
        guard !captureState.isActive else { return }
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose Source"
        if panel.runModal() == .OK, let url = panel.url {
            selectedSource = url
            captureState = .idle
            captureProgress = CaptureProgressState()
        }
    }

    func startCapture() {
        guard let selectedSource, let database, !captureState.isActive else { return }
        let token = CaptureCancellationToken()
        cancellationToken = token
        captureState = .scanning
        captureProgress = CaptureProgressState(phase: "Detecting source")
        let scanner = SnapshotScanner(database: database)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let record = try scanner.capture(root: selectedSource, token: token) { progress in
                    DispatchQueue.main.async {
                        self?.captureProgress = CaptureProgressState(
                            processedEntries: progress.processedEntries,
                            currentPath: progress.currentPath,
                            phase: progress.phase
                        )
                    }
                }
                DispatchQueue.main.async {
                    self?.captureState = record.status == .completeWithWarnings ? .completeWithWarnings : .complete
                    self?.captureProgress.phase = "Finished"
                    self?.cancellationToken = nil
                    self?.refresh()
                }
            } catch let error as SnapshotScannerError {
                DispatchQueue.main.async {
                    if token.isCancelled {
                        self?.captureState = .cancelled
                    } else if case .provider(.cancelled) = error {
                        self?.captureState = .cancelled
                    } else if case .provider = error {
                        self?.captureState = .interrupted
                    } else {
                        // Bounded user-visible text only; the raw diagnostic
                        // goes to standard error, never to the capture screen.
                        self?.captureState = .failed(CaptureErrorDescription.message(for: error))
                        FileHandle.standardError.write(Data("\(CaptureErrorDescription.diagnosticLine(for: error))\n".utf8))
                    }
                    self?.cancellationToken = nil
                    self?.refresh()
                }
            } catch {
                DispatchQueue.main.async {
                    self?.captureState = .failed(CaptureErrorDescription.message(for: error))
                    FileHandle.standardError.write(Data("\(CaptureErrorDescription.diagnosticLine(for: error))\n".utf8))
                    self?.cancellationToken = nil
                    self?.refresh()
                }
            }
        }
    }

    func cancelCapture() {
        guard captureState == .scanning else { return }
        captureState = .cancelling
        cancellationToken?.cancel()
    }

    func refresh() {
        guard let historyRepository else { return }
        do {
            history = try historyRepository.listSnapshots()
            startupError = nil
        } catch {
            startupError = error.localizedDescription
        }
    }

    /// Opening a snapshot builds a browser over the stored catalog rows only.
    /// It never checks that the source still exists first, and never fails
    /// because it does not. Replacing a browser cancels the old browser's
    /// classification ownership first; opening never starts classification.
    func openSnapshot(_ summary: SnapshotSummary) {
        guard let database else { return }
        browser?.cancelClassificationForSnapshotClose()
        selectedSnapshotID = summary.id
        browser = SnapshotBrowserModel(database: database, summary: summary, runtime: classificationRuntime)
    }

    func closeSnapshot() {
        browser?.cancelClassificationForSnapshotClose()
        selectedSnapshotID = nil
        browser = nil
    }
}
