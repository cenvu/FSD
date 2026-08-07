import Foundation

/// Orchestrates the three comparison modes over the one engine.
///
/// Orientation convention (canonical): the **left side is the reference
/// ("before") tree** and the **right side is the changed ("after") tree**.
/// `added` = present only on the right; `removed` = present only on the left.
///
/// * **Snapshot to snapshot** — both sides are stored, immutable snapshots;
///   the engine runs fully offline. The source paths may be gone; no source
///   access ever happens. The caller chooses which snapshot is the reference.
/// * **Live to snapshot** — the live side is captured first through the
///   existing metadata-only scanner into a transient snapshot (ADR-012), then
///   compared with the snapshot as the reference: `added` therefore means
///   "new since the snapshot". A failed or cancelled capture never produces a
///   comparison.
/// * **Live to live** — each live side is captured independently into a
///   transient snapshot; comparison starts only after both captures are
///   complete. Cancellation or failure on either side terminates safely and
///   leaves no completed comparison and no orphaned completed capture.
///
/// Transient snapshots are never presented as ordinary history (the history
/// repository excludes `snapshot_kind = 'transient'`); their cleanup is the
/// explicit lifecycle in `TransientSnapshotLifecycle`, invoked on workspace
/// close and at application launch.
public final class ComparisonService: @unchecked Sendable {
    public let database: CatalogDatabase
    public let engine: ComparisonEngine

    public init(database: CatalogDatabase, engine: ComparisonEngine? = nil) {
        self.database = database
        self.engine = engine ?? ComparisonEngine(database: database)
    }

    // MARK: - Modes

    public func snapshotToSnapshot(
        leftSnapshotID: SnapshotID,
        rightSnapshotID: SnapshotID,
        profileID: Int64 = ComparisonProfileRepository.fastMetadataProfileID,
        token: ComparisonCancellationToken = ComparisonCancellationToken(),
        onProgress: @escaping (ComparisonProgress) -> Void = { _ in }
    ) throws -> ComparisonRecord {
        try engine.compare(
            leftSnapshotID: leftSnapshotID,
            rightSnapshotID: rightSnapshotID,
            profileID: profileID,
            token: token,
            onProgress: onProgress
        )
    }

    public func liveToSnapshot(
        liveRoot: URL,
        snapshotID: SnapshotID,
        profileID: Int64 = ComparisonProfileRepository.fastMetadataProfileID,
        token: ComparisonCancellationToken = ComparisonCancellationToken(),
        onProgress: @escaping (ComparisonProgress) -> Void = { _ in }
    ) throws -> ComparisonRecord {
        let transient = try captureTransient(liveRoot: liveRoot, token: token, onProgress: onProgress)
        return try compareOrDispose(transient: transient) {
            // The snapshot is the reference (left); the live tree is the
            // changed side (right), so `added` means "new since the snapshot".
            try engine.compare(
                leftSnapshotID: snapshotID,
                rightSnapshotID: transient.id,
                profileID: profileID,
                token: token,
                onProgress: onProgress
            )
        }
    }

    public func liveToLive(
        leftRoot: URL,
        rightRoot: URL,
        profileID: Int64 = ComparisonProfileRepository.fastMetadataProfileID,
        token: ComparisonCancellationToken = ComparisonCancellationToken(),
        onProgress: @escaping (ComparisonProgress) -> Void = { _ in }
    ) throws -> ComparisonRecord {
        let leftTransient = try captureTransient(liveRoot: leftRoot, token: token, onProgress: onProgress)
        let rightTransient: SnapshotRecord
        do {
            rightTransient = try captureTransient(liveRoot: rightRoot, token: token, onProgress: onProgress)
        } catch {
            // The first capture is unreferenced scaffolding; delete it now so
            // a failure on either side terminates safely with no residue.
            _ = try? TransientSnapshotLifecycle(database: database).deleteTransient(leftTransient.id)
            throw error
        }
        return try compareOrDispose(transient: leftTransient, otherTransient: rightTransient) {
            try engine.compare(
                leftSnapshotID: leftTransient.id,
                rightSnapshotID: rightTransient.id,
                profileID: profileID,
                token: token,
                onProgress: onProgress
            )
        }
    }

    // MARK: - Workspace lifecycle

    /// Closes the comparison workspace: running live-side comparisons are
    /// cancelled, live-side comparison records are disposed, and the
    /// transient snapshots they referenced are deleted. Snapshot-to-snapshot
    /// comparisons and their snapshots are untouched.
    public func closeWorkspace() throws {
        try TransientSnapshotLifecycle(database: database).closeWorkspace()
    }

    // MARK: - Live capture

    /// One live side through the existing scanner path (ADR-012): the same
    /// provider, the same batching writer, the same cancellation invariants,
    /// only marked `transient` so it is excluded from user history.
    private func captureTransient(
        liveRoot: URL,
        token: CaptureCancellationToken,
        onProgress: @escaping (ComparisonProgress) -> Void
    ) throws -> SnapshotRecord {
        let scanner = SnapshotScanner(database: database)
        do {
            return try scanner.capture(root: liveRoot, token: token, kind: .transient) { progress in
                onProgress(ComparisonProgress(processedEntries: progress.processedEntries, phase: "Capturing live source"))
            }
        } catch {
            // The failed or cancelled capture's own snapshot row (if any) is
            // unreferenced scaffolding — no comparison row exists yet. Remove
            // it now so a failed live capture terminates with no residue;
            // only disposable transient scaffolding is ever touched, never a
            // completed snapshot.
            _ = try? TransientSnapshotLifecycle(database: database).cleanupUnreferencedTransients()
            if token.isCancelled {
                throw ComparisonError.cancelled
            }
            if let scannerError = error as? SnapshotScannerError {
                throw ComparisonError.liveCaptureFailed(scannerError)
            }
            throw error
        }
    }

    /// Runs the comparison; if it fails or is cancelled, the just-captured
    /// transient(s) are deleted because no comparison row references them —
    /// a failed live comparison must not leave orphaned completed captures.
    private func compareOrDispose(
        transient: SnapshotRecord,
        otherTransient: SnapshotRecord? = nil,
        body: () throws -> ComparisonRecord
    ) throws -> ComparisonRecord {
        do {
            return try body()
        } catch {
            _ = try? TransientSnapshotLifecycle(database: database).deleteTransient(transient.id)
            if let otherTransient {
                _ = try? TransientSnapshotLifecycle(database: database).deleteTransient(otherTransient.id)
            }
            throw error
        }
    }
}
