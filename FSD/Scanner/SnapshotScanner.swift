import Foundation

public struct CaptureProgress: Sendable, Equatable {
    public let processedEntries: Int64
    public let currentPath: String
    public let phase: String

    public init(processedEntries: Int64, currentPath: String, phase: String) {
        self.processedEntries = processedEntries
        self.currentPath = currentPath
        self.phase = phase
    }
}

public enum SnapshotScannerError: Error, LocalizedError, Equatable {
    case provider(FilesystemProviderError)
    case writer(SnapshotWriterError)
    case detector(FilesystemDetectorError)
    case captureFailed(String)

    public var errorDescription: String? {
        switch self {
        case let .provider(error): return error.localizedDescription
        case let .writer(error): return error.localizedDescription
        case let .detector(error): return error.localizedDescription
        case let .captureFailed(message): return "Metadata capture failed: \(message)"
        }
    }
}

/// The scanner's configuration is immutable after initialization. Capture
/// state is local to one invocation, while catalog mutation is serialized by
/// `CatalogDatabase`; the provider callback is consumed by that invocation's
/// worker only.
public final class SnapshotScanner: @unchecked Sendable {
    public let detector: FilesystemDetector
    public let providerFactory: @Sendable (FilesystemDescriptor) -> FilesystemProvider
    public let writer: SnapshotWriter

    public init(
        database: CatalogDatabase,
        detector: FilesystemDetector = FilesystemDetector(),
        providerFactory: @escaping @Sendable (FilesystemDescriptor) -> FilesystemProvider = { NativeMountedProvider(descriptor: $0) },
        batchSize: Int = 2000
    ) {
        self.detector = detector
        self.providerFactory = providerFactory
        self.writer = SnapshotWriter(database: database, batchSize: batchSize)
    }

    @discardableResult
    public func capture(
        root: URL,
        token: CaptureCancellationToken = CaptureCancellationToken(),
        kind: SnapshotKind = .user,
        onProgress: @escaping (CaptureProgress) -> Void = { _ in }
    ) throws -> SnapshotRecord {
        let descriptor: FilesystemDescriptor
        do {
            descriptor = try detector.detect(root: root)
        } catch let error as FilesystemDetectorError {
            throw SnapshotScannerError.detector(error)
        }
        let rootName = descriptor.rootURL.lastPathComponent.isEmpty ? descriptor.volumeName : descriptor.rootURL.lastPathComponent
        // The provider is built before the snapshot row so the row records the
        // version of the code that actually produced the capture.
        let provider = providerFactory(descriptor)
        let session: SnapshotWriteSession
        do {
            session = try writer.beginCapture(
                descriptor: descriptor,
                scanRootName: rootName,
                kind: kind,
                providerVersion: provider.providerVersion,
                token: token
            )
        } catch let error as SnapshotWriterError {
            throw SnapshotScannerError.writer(error)
        }
        var entryBuffer: [MetadataEntry] = []
        var issueCount: Int64 = 0
        var result: EnumerationResult?
        do {
            result = try provider.enumerate(
                onEntry: { entry in
                    if entry.relativePath.isEmpty { return }
                    entryBuffer.append(entry)
                    if entryBuffer.count >= self.writer.batchSize {
                        try session.append(contentsOf: entryBuffer)
                        entryBuffer.removeAll(keepingCapacity: true)
                    }
                },
                onIssue: { issue in
                    if !entryBuffer.isEmpty {
                        try session.append(contentsOf: entryBuffer)
                        entryBuffer.removeAll(keepingCapacity: true)
                    }
                    try session.append(issue: issue)
                    issueCount += issue.severity == "info" ? 0 : 1
                },
                onProgress: { progress in
                    onProgress(CaptureProgress(
                        processedEntries: progress.processedEntries,
                        currentPath: progress.currentPath,
                        phase: "Scanning"
                    ))
                },
                isCancelled: { token.isCancelled }
            )
            if !entryBuffer.isEmpty {
                try session.append(contentsOf: entryBuffer)
                entryBuffer.removeAll(keepingCapacity: true)
            }
            if token.isCancelled || result?.wasCancelled == true {
                try session.finish(preferredStatus: .cancelled)
            } else {
                onProgress(CaptureProgress(processedEntries: result?.processedEntries ?? 0, currentPath: "", phase: "Finalizing"))
                try session.finish(preferredStatus: issueCount == 0 ? .complete : .completeWithWarnings)
            }
        } catch let error as SnapshotWriterError {
            if !isTerminal(session.snapshotID) {
                try? session.finish(preferredStatus: token.isCancelled ? .cancelled : .failed)
            }
            throw SnapshotScannerError.writer(error)
        } catch let error as FilesystemProviderError {
            try? session.finish(preferredStatus: token.isCancelled ? .cancelled : .interrupted)
            throw SnapshotScannerError.provider(error)
        } catch {
            try? session.finish(preferredStatus: token.isCancelled ? .cancelled : .failed)
            throw SnapshotScannerError.captureFailed(error.localizedDescription)
        }
        let repository = SnapshotRepository(database: writer.database)
        guard let record = try repository.snapshot(id: session.snapshotID) else {
            throw SnapshotScannerError.captureFailed("The completed snapshot could not be read back.")
        }
        return record
    }

    private func isTerminal(_ snapshotID: SnapshotID) -> Bool {
        (try? writer.database.scalar(
            "SELECT status FROM snapshots WHERE id = ?", bindings: [.integer(snapshotID.rawValue)]
        )?.stringValue).flatMap(SnapshotStatus.init(rawValue:))?.isTerminal ?? true
    }
}
