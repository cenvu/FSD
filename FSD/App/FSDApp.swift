import AppKit
import SwiftUI

@main
struct FSDApp: App {
    @StateObject private var model = ApplicationModel()

    var body: some Scene {
        WindowGroup("FishSock Differ") {
            ContentView(model: model)
                .frame(minWidth: 960, minHeight: 600)
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

private enum SidebarDestination: Hashable {
    case capture
    case snapshots
    case compare
    case collections
}

struct ContentView: View {
    @ObservedObject var model: ApplicationModel
    @State private var selection: SidebarDestination?

    init(model: ApplicationModel) {
        self.model = model
        // DEBUG-only probe seam (same pattern as ADR-026's `-FSDCatalogPath`):
        // `-FSDSelectCompare` / `-FSDSelectCapture` preselect a destination so
        // an automated probe can launch straight into it without reading the UI.
        var initial: SidebarDestination? = .snapshots
        #if DEBUG
        if CommandLine.arguments.contains("-FSDSelectCompare") {
            initial = .compare
        } else if CommandLine.arguments.contains("-FSDSelectCapture") {
            initial = .capture
        }
        #endif
        _selection = State(initialValue: initial)
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Catalog") {
                    Label("Snapshots", systemImage: "square.stack.3d.up")
                        .tag(SidebarDestination.snapshots)
                    Label("Capture", systemImage: "plus.rectangle.on.folder")
                        .tag(SidebarDestination.capture)
                    Label("Compare", systemImage: "arrow.left.arrow.right")
                        .tag(SidebarDestination.compare)
                }
                Section("Coming later") {
                    Label("Collections — not implemented", systemImage: "folder")
                        .tag(SidebarDestination.collections)
                }
            }
            .navigationTitle("FishSock Differ")
        } detail: {
            detailView
        }
    }

    @ViewBuilder
    private var detailView: some View {
        if let startupError = model.startupError {
            EmptyStateView(title: "Catalog unavailable", systemImage: "exclamationmark.triangle", detail: startupError)
        } else {
            switch selection {
            case .snapshots, nil:
                historyView
            case .capture:
                captureView
            case .compare:
                if let catalog = model.database {
                    ComparisonDestinationView(database: catalog)
                } else {
                    EmptyStateView(title: "Catalog unavailable", systemImage: "exclamationmark.triangle")
                }
            case .collections:
                EmptyStateView(title: "Collections not implemented", systemImage: "folder")
            }
        }
    }

    private var historyView: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Snapshot history").font(.title3).padding(.horizontal, 12).padding(.top, 12)
                Text("Stored in the catalog. Browsing works with the source disconnected.")
                    .font(.caption).foregroundStyle(.secondary).padding(.horizontal, 12)
                if model.history.isEmpty {
                    EmptyStateView(
                        title: "No snapshots yet",
                        systemImage: "square.stack.3d.up.slash",
                        detail: "Use Capture to record the first metadata snapshot."
                    )
                } else {
                    List(model.history, selection: Binding(
                        get: { model.selectedSnapshotID },
                        set: { newValue in
                            guard let newValue, let summary = model.history.first(where: { $0.id == newValue }) else {
                                model.closeSnapshot()
                                return
                            }
                            model.openSnapshot(summary)
                        }
                    )) { summary in
                        SnapshotHistoryRow(summary: summary).tag(summary.id)
                    }
                }
                Spacer()
            }
            .frame(minWidth: 300, idealWidth: 340)
            if let browser = model.browser {
                SnapshotBrowserView(model: browser)
                    .id(browser.summary.id)
                    .frame(minWidth: 560)
            } else {
                EmptyStateView(
                    title: "Select a snapshot",
                    systemImage: "sidebar.right",
                    detail: "Choose a capture to browse its stored metadata offline."
                )
                .frame(minWidth: 560)
            }
        }
    }

    private var captureView: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Metadata Capture").font(.title2)
                Spacer()
                Button("Choose Source…", action: model.chooseSource)
                    .disabled(model.captureState.isActive)
            }
            if let recoveryMessage = model.recoveryMessage {
                Label(recoveryMessage, systemImage: "arrow.clockwise.circle")
                    .foregroundStyle(.orange)
            }
            GroupBox("Capture") {
                VStack(alignment: .leading, spacing: 10) {
                    Text(model.selectedSource?.path ?? "No folder selected")
                        .font(.callout)
                        .foregroundStyle(model.selectedSource == nil ? .secondary : .primary)
                        .lineLimit(2)
                    HStack {
                        Button("Start Metadata Capture", action: model.startCapture)
                            .disabled(model.selectedSource == nil || model.captureState.isActive)
                        if model.captureState.isActive {
                            Button("Cancel", action: model.cancelCapture)
                        }
                        Spacer()
                        Text(model.captureState.title).foregroundStyle(.secondary)
                        if case let .failed(message) = model.captureState {
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    if model.captureState.isActive || model.captureProgress.processedEntries > 0 {
                        ProgressView()
                        Text("\(model.captureProgress.processedEntries) entries — \(model.captureProgress.phase)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if !model.captureProgress.currentPath.isEmpty {
                            Text(model.captureProgress.currentPath)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    Text("Metadata only. Content Not Verified.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(4)
            }
            Text(model.catalogDiagnostics)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            Spacer()
        }
        .padding(24)
    }
}

private struct SnapshotHistoryRow: View {
    let summary: SnapshotSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(summary.displayName).font(.headline).lineLimit(1)
            HStack(spacing: 6) {
                Image(systemName: icon).foregroundStyle(tint)
                Text(statusText).foregroundStyle(tint)
                Text("·").foregroundStyle(.secondary)
                Text(summary.startedAt).foregroundStyle(.secondary)
            }
            .font(.caption)
            Text("\(summary.totalFiles) files · \(summary.totalFolders) folders · "
                 + ByteCountFormatter.string(fromByteCount: summary.totalLogicalBytes, countStyle: .file))
                .font(.caption2).foregroundStyle(.secondary)
            Text("Source at capture: \(summary.capture.displayNameForHistory)")
                .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
        }
        .padding(.vertical, 2)
    }

    private var statusText: String {
        summary.status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var icon: String {
        switch summary.status {
        case .complete: return "checkmark.seal"
        case .completeWithWarnings: return "checkmark.seal.fill"
        case .interrupted: return "bolt.horizontal.circle"
        case .cancelled: return "xmark.circle"
        case .failed: return "exclamationmark.octagon"
        case .scanning: return "clock"
        }
    }

    private var tint: Color {
        switch summary.status {
        case .complete: return .green
        case .completeWithWarnings: return .orange
        case .interrupted, .cancelled: return .orange
        case .failed: return .red
        case .scanning: return .secondary
        }
    }
}

// `EmptyStateView` is shared across the app shell and the comparison UI; it
// lives in FSD/UI/ComparisonSharedViews.swift.
