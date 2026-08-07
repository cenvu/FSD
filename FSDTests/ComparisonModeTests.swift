import XCTest
@testable import FSD

/// The three comparison modes end to end against real generated fixtures
/// (production scanner, transient captures), plus cancellation of each live
/// mode and the transient-snapshot lifecycle (ADR-012).
final class ComparisonModeTests: XCTestCase {
    private var directory: URL!
    private var database: CatalogDatabase!
    private var service: ComparisonService!
    private var results: ComparisonResultRepository!

    private var leftSource: URL!
    private var rightSource: URL!
    private var storedLeft: SnapshotID!
    private var storedRight: SnapshotID!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-Modes-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        leftSource = directory.appendingPathComponent("left-source", isDirectory: true)
        rightSource = directory.appendingPathComponent("right-source", isDirectory: true)
        database = try CatalogDatabase(
            url: directory.appendingPathComponent("catalog.sqlite3"),
            schemaURL: CatalogSchemaFixture.canonicalSchemaURL
        )
        service = ComparisonService(database: database)
        results = ComparisonResultRepository(database: database)
    }

    override func tearDownWithError() throws {
        results = nil
        service = nil
        database?.close()
        database = nil
        try? FileManager.default.removeItem(at: directory)
        directory = nil
        leftSource = nil
        rightSource = nil
        storedLeft = nil
        storedRight = nil
    }

    // MARK: - Fixtures

    private func writeSourceFixtures() throws {
        // left: A/one.txt (10B), A/two.txt (20B), B/three.txt (30B), unique.txt
        // right: A/one.txt (10B), A/two.txt (99B — modified), C/four.txt, fresh.txt
        try FileManager.default.createDirectory(at: leftSource.appendingPathComponent("A"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: leftSource.appendingPathComponent("B"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: rightSource.appendingPathComponent("A"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: rightSource.appendingPathComponent("C"), withIntermediateDirectories: true)
        try Data(repeating: 0, count: 10).write(to: leftSource.appendingPathComponent("A/one.txt"))
        try Data(repeating: 0, count: 20).write(to: leftSource.appendingPathComponent("A/two.txt"))
        try Data(repeating: 0, count: 30).write(to: leftSource.appendingPathComponent("B/three.txt"))
        try Data(repeating: 0, count: 5).write(to: leftSource.appendingPathComponent("unique.txt"))
        try Data(repeating: 0, count: 10).write(to: rightSource.appendingPathComponent("A/one.txt"))
        try Data(repeating: 0, count: 99).write(to: rightSource.appendingPathComponent("A/two.txt"))
        try Data(repeating: 0, count: 40).write(to: rightSource.appendingPathComponent("C/four.txt"))
        try Data(repeating: 0, count: 8).write(to: rightSource.appendingPathComponent("fresh.txt"))
    }

    /// A deterministic pre-capture listing: relative path, size, modification
    /// timestamp — the source-safety baseline. The enumerator yields resolved
    /// paths (/var → /private/var) while the input URL stays lexical, so both
    /// are resolved before stripping the root prefix.
    private func listing(of root: URL) throws -> String {
        let base = root.standardizedFileURL.resolvingSymlinksInPath().path
        let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey])
        var lines: [String] = []
        while let url = enumerator?.nextObject() as? URL {
            let values = try url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
            let resolved = url.standardizedFileURL.resolvingSymlinksInPath().path
            guard resolved.hasPrefix(base) else { continue }
            let relative = String(resolved.dropFirst(base.count))
            lines.append("\(relative)|\(values.fileSize ?? -1)|\(values.contentModificationDate?.timeIntervalSince1970 ?? -1)")
        }
        return lines.sorted().joined(separator: "\n")
    }

    private func storeBothSourcesAsUserSnapshots() throws {
        let scanner = SnapshotScanner(database: database)
        storedLeft = try scanner.capture(root: leftSource).id
        storedRight = try scanner.capture(root: rightSource).id
    }

    private func transientCount() throws -> Int64 {
        try database.scalar("SELECT COUNT(*) FROM snapshots WHERE snapshot_kind = 'transient'")?.int64Value ?? -1
    }

    private func userSnapshotCount() throws -> Int64 {
        try database.scalar("SELECT COUNT(*) FROM snapshots WHERE snapshot_kind = 'user'")?.int64Value ?? -1
    }

    // MARK: - Snapshot to snapshot

    func testSnapshotToSnapshotRunsFullyOffline() throws {
        try writeSourceFixtures()
        try storeBothSourcesAsUserSnapshots()
        try FileManager.default.removeItem(at: leftSource)
        try FileManager.default.removeItem(at: rightSource)

        let comparison = try service.snapshotToSnapshot(leftSnapshotID: storedLeft, rightSnapshotID: storedRight)
        XCTAssertEqual(comparison.status, .complete)
        XCTAssertEqual(comparison.mode, .snapshotToSnapshot)
        // Both trees: root, A, A/one.txt, A/two.txt, B, B/three.txt,
        // unique.txt vs root, A, A/one.txt, A/two.txt, C, C/four.txt, fresh.txt.
        XCTAssertEqual(comparison.matchedCount, 3, "roots + A + A/one.txt")
        XCTAssertEqual(comparison.changedCount, 1, "A/two.txt (20 vs 99 bytes)")
        XCTAssertEqual(comparison.addedCount, 3, "C + C/four.txt + fresh.txt")
        XCTAssertEqual(comparison.removedCount, 3, "B + B/three.txt + unique.txt")

        // The stored results are readable with the sources gone.
        let rows = try results.results(comparisonID: comparison.id, filter: .all, limit: 100).rows
        XCTAssertEqual(rows.count, 10)
    }

    // MARK: - Live to snapshot

    func testLiveToSnapshotCapturesTransientlyAndCompares() throws {
        try writeSourceFixtures()
        try storeBothSourcesAsUserSnapshots()
        // The live side: a copy of the right source with one extra file.
        try FileManager.default.createDirectory(at: rightSource.appendingPathComponent("D"), withIntermediateDirectories: true)
        try Data("x".utf8).write(to: rightSource.appendingPathComponent("D/later.txt"))

        let comparison = try service.liveToSnapshot(liveRoot: rightSource, snapshotID: storedLeft)
        XCTAssertEqual(comparison.mode, .liveToSnapshot)
        XCTAssertEqual(comparison.status, .complete)
        XCTAssertFalse(comparison.left.isLive, "the snapshot is the reference (left)")
        XCTAssertTrue(comparison.right.isLive, "the live tree is the changed side (right)")
        XCTAssertEqual(comparison.addedCount, 5, "C + C/four.txt + fresh.txt + D + D/later.txt are new since the snapshot")
        XCTAssertEqual(comparison.removedCount, 3, "B + B/three.txt + unique.txt are gone from the live tree")
    }

    func testTransientSnapshotsAreExcludedFromUserHistory() throws {
        try writeSourceFixtures()
        try storeBothSourcesAsUserSnapshots()
        _ = try service.liveToSnapshot(liveRoot: rightSource, snapshotID: storedLeft)

        XCTAssertEqual(try transientCount(), 1)
        let history = try SnapshotHistoryRepository(database: database).listSnapshots()
        XCTAssertEqual(history.count, 2, "only the two user snapshots appear in history")
        XCTAssertTrue(history.allSatisfy { $0.kind == .user })
    }

    // MARK: - Live to live

    func testLiveToLiveCapturesBothSidesIndependently() throws {
        try writeSourceFixtures()
        let comparison = try service.liveToLive(leftRoot: leftSource, rightRoot: rightSource)
        XCTAssertEqual(comparison.mode, .liveToLive)
        XCTAssertEqual(comparison.status, .complete)
        XCTAssertTrue(comparison.left.isLive)
        XCTAssertTrue(comparison.right.isLive)
        XCTAssertEqual(comparison.matchedCount, 3, "roots + A + A/one.txt")
        XCTAssertEqual(comparison.changedCount, 1, "A/two.txt size differs")
        XCTAssertEqual(comparison.addedCount, 3, "C + C/four.txt + fresh.txt")
        XCTAssertEqual(comparison.removedCount, 3, "B + B/three.txt + unique.txt")
        XCTAssertEqual(try transientCount(), 2)
        XCTAssertEqual(try userSnapshotCount(), 0, "live-to-live creates no user snapshots")
    }

    func testLiveToLiveNeverComparesWhileEitherCaptureIsIncomplete() throws {
        try writeSourceFixtures()
        // Cancel as soon as the first capture starts emitting progress.
        let token = CaptureCancellationToken()
        var progressCount = 0
        XCTAssertThrowsError(try service.liveToLive(leftRoot: leftSource, rightRoot: rightSource, token: token) { _ in
            progressCount += 1
            if progressCount == 1 { token.cancel() }
        }) { error in
            guard case ComparisonError.cancelled = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        // No comparison row exists and the partial transient captures are
        // unreferenced scaffolding, removed by the explicit cleanup.
        XCTAssertEqual(try results.count(), 0)
        XCTAssertEqual(try transientCount(), 0, "cleanup removes unreferenced transients")
    }

    // MARK: - Cancellation

    func testCancellationBeforeWorkStartsProducesNoComparison() throws {
        try writeSourceFixtures()
        try storeBothSourcesAsUserSnapshots()
        let token = CaptureCancellationToken()
        token.cancel()

        XCTAssertThrowsError(try service.snapshotToSnapshot(leftSnapshotID: storedLeft, rightSnapshotID: storedRight, token: token)) { error in
            guard case ComparisonError.cancelled = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertEqual(try results.count(), 0)
    }

    func testCancellationDuringMatchingTerminalizesTheComparisonAsCancelled() throws {
        try writeSourceFixtures()
        try storeBothSourcesAsUserSnapshots()
        let token = CaptureCancellationToken()
        var didCancel = false
        // A small batch engine so progress callbacks fire mid-matching on a
        // fixture this small; the production default batches 2,000.
        let smallBatchService = ComparisonService(
            database: database,
            engine: ComparisonEngine(database: database, pageSize: 10, batchSize: 2)
        )

        XCTAssertThrowsError(try smallBatchService.snapshotToSnapshot(leftSnapshotID: storedLeft, rightSnapshotID: storedRight, token: token) { progress in
            if !didCancel, progress.processedEntries >= 2 {
                didCancel = true
                token.cancel()
            }
        }) { error in
            guard case ComparisonError.cancelled = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }

        XCTAssertTrue(didCancel)
        let comparisons = try results.listComparisons()
        XCTAssertEqual(comparisons.count, 1)
        XCTAssertEqual(comparisons[0].status, .cancelled)
        XCTAssertTrue(comparisons[0].completedAt != nil, "cancellation terminalizes with evidence")
    }

    func testCancellationDuringLiveCaptureNeverProducesAComparison() throws {
        try writeSourceFixtures()
        try storeBothSourcesAsUserSnapshots()
        let token = CaptureCancellationToken()
        token.cancel()

        XCTAssertThrowsError(try service.liveToSnapshot(liveRoot: rightSource, snapshotID: storedLeft, token: token)) { error in
            guard case ComparisonError.cancelled = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertEqual(try results.count(), 0)
        XCTAssertEqual(try transientCount(), 0, "the cancelled capture's transient is cleaned up")
    }

    // MARK: - Source removal after transient capture

    func testLiveComparisonSurvivesSourceRemovalAfterCapture() throws {
        try writeSourceFixtures()
        try storeBothSourcesAsUserSnapshots()
        _ = try service.liveToSnapshot(liveRoot: rightSource, snapshotID: storedLeft)
        try FileManager.default.removeItem(at: rightSource)

        let comparisons = try results.listComparisons()
        XCTAssertEqual(comparisons.count, 1)
        XCTAssertEqual(comparisons[0].status, .complete)
        XCTAssertTrue(comparisons[0].right.isLive, "the live side is retained with the stored comparison")
        XCTAssertEqual(comparisons[0].right.sourceDescription.contains("Live folder"), true)
        let rows = try results.results(comparisonID: comparisons[0].id, filter: .differences, limit: 50).rows
        XCTAssertFalse(rows.isEmpty, "differences stay readable offline")
    }

    // MARK: - Source safety

    func testLiveCaptureLeavesTheSourceByteForByteUnchanged() throws {
        try writeSourceFixtures()
        let leftBaseline = try listing(of: leftSource)
        let rightBaseline = try listing(of: rightSource)
        _ = try service.liveToLive(leftRoot: leftSource, rightRoot: rightSource)
        XCTAssertEqual(try listing(of: leftSource), leftBaseline)
        XCTAssertEqual(try listing(of: rightSource), rightBaseline)
    }

    // MARK: - Workspace close and recovery

    func testCloseWorkspaceDisposesLiveSideComparisonsAndTransients() throws {
        try writeSourceFixtures()
        try storeBothSourcesAsUserSnapshots()
        _ = try service.liveToSnapshot(liveRoot: rightSource, snapshotID: storedLeft)
        let stored = try service.snapshotToSnapshot(leftSnapshotID: storedLeft, rightSnapshotID: storedRight)

        try service.closeWorkspace()

        let remaining = try results.listComparisons()
        XCTAssertEqual(remaining.map(\.id), [stored.id], "only the snapshot-to-snapshot comparison survives close")
        XCTAssertEqual(try transientCount(), 0, "live-side transients are deleted")
        XCTAssertEqual(try userSnapshotCount(), 2, "user snapshots are untouched")
    }

    func testCloseWorkspaceTerminalizesARunningDisposableComparisonFirst() throws {
        try writeSourceFixtures()
        try storeBothSourcesAsUserSnapshots()
        // A live-side comparison left in 'running' (simulating an abandoned
        // workspace) is cancelled and disposed by close.
        let transient = try SnapshotScanner(database: database).capture(root: rightSource, kind: .transient).id
        try database.execute(
            """
            INSERT INTO comparisons (left_snapshot_id, right_snapshot_id, profile_id, status, started_at, created_at)
            VALUES (?, ?, 1, 'running', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            """,
            bindings: [.integer(transient.rawValue), .integer(storedLeft.rawValue)]
        )
        XCTAssertEqual(try results.count(), 1)
        XCTAssertEqual(try transientCount(), 1)

        try service.closeWorkspace()

        XCTAssertEqual(try results.count(), 0, "the running disposable comparison is terminalized and disposed")
        XCTAssertEqual(try transientCount(), 0, "its transient is released and deleted")
        XCTAssertEqual(try userSnapshotCount(), 2, "user snapshots are untouched")
    }

    func testOrphanedRunningComparisonIsRecoveredAsFailedAtLaunch() throws {
        try writeSourceFixtures()
        try storeBothSourcesAsUserSnapshots()
        // A real 'running' comparison, as a crash would leave one: the row
        // exists, some results were persisted, and the process died before
        // the terminal transition. (A completed comparison can no longer be
        // set to running — the v6 trigger rejects it, which is the point.)
        let runningID = try database.transaction { () -> ComparisonID in
            try database.execute(
                """
                INSERT INTO comparisons (left_snapshot_id, right_snapshot_id, profile_id, status, started_at, created_at)
                VALUES (?, ?, 1, 'running', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """,
                bindings: [.integer(storedLeft.rawValue), .integer(storedRight.rawValue)]
            )
            let id = ComparisonID(rawValue: try database.lastInsertRowID())
            let leftRoot = try XCTUnwrap(try database.scalar(
                "SELECT id FROM entries WHERE snapshot_id = ? AND parent_id IS NULL", bindings: [.integer(storedLeft.rawValue)]
            )?.int64Value)
            let rightRoot = try XCTUnwrap(try database.scalar(
                "SELECT id FROM entries WHERE snapshot_id = ? AND parent_id IS NULL", bindings: [.integer(storedRight.rawValue)]
            )?.int64Value)
            try database.execute(
                """
                INSERT INTO comparison_results (comparison_id, result_path, display_name, result_type, left_entry_id, right_entry_id, difference_flags, created_at)
                VALUES (?, '', 'Root', 'matched', ?, ?, 0, CURRENT_TIMESTAMP)
                """,
                bindings: [.integer(id.rawValue), .integer(leftRoot), .integer(rightRoot)]
            )
            return id
        }

        let lifecycle = TransientSnapshotLifecycle(database: database)
        let report = try lifecycle.recoverOrphanedComparisons()
        XCTAssertEqual(report.recoveredComparisonIDs, [runningID])

        let recovered = try results.record(id: runningID)
        XCTAssertEqual(recovered?.status, .failed, "an abandoned comparison is failed, never complete")
        XCTAssertEqual(recovered?.matchedCount, 1, "counts are recomputed from the retained rows")
        XCTAssertEqual(recovered?.completedAt != nil, true)
    }

    func testLaunchCleanupDeletesUnreferencedTransientsButNotReferencedOnes() throws {
        try writeSourceFixtures()
        try storeBothSourcesAsUserSnapshots()
        // One completed live comparison (its transient is referenced) and one
        // abandoned capture (unreferenced).
        _ = try service.liveToSnapshot(liveRoot: rightSource, snapshotID: storedLeft)
        let scanner = SnapshotScanner(database: database)
        let abandoned = try scanner.capture(root: leftSource, kind: .transient).id

        XCTAssertEqual(try transientCount(), 2)
        let lifecycle = TransientSnapshotLifecycle(database: database)
        let deleted = try lifecycle.cleanupUnreferencedTransients()

        XCTAssertEqual(deleted, 1, "the abandoned capture is disposable scaffolding")
        XCTAssertEqual(try transientCount(), 1)
        // The surviving transient is exactly the one the completed live
        // comparison references (ON DELETE RESTRICT honors that reference).
        let comparisons = try results.listComparisons()
        XCTAssertEqual(comparisons.count, 1)
        XCTAssertTrue(comparisons[0].right.isLive, "the live side is the transient side of live-to-snapshot")
        let referencedID = comparisons[0].right.snapshotID.rawValue
        XCTAssertEqual(
            try database.scalar("SELECT COUNT(*) FROM snapshots WHERE id = ?", bindings: [.integer(referencedID)])?.int64Value,
            1
        )
        XCTAssertEqual(
            try database.scalar("SELECT COUNT(*) FROM snapshots WHERE id = ?", bindings: [.integer(abandoned.rawValue)])?.int64Value,
            0
        )
    }

    func testAbandonedScanningTransientIsInterruptedThenCleanedAtLaunch() throws {
        try writeSourceFixtures()
        try storeBothSourcesAsUserSnapshots()
        // A capture interrupted mid-flight: 'scanning' transient.
        let scanner = SnapshotScanner(database: database)
        let session = try scanner.writer.beginCapture(
            descriptor: FilesystemDetector().detect(root: leftSource),
            scanRootName: "abandoned",
            kind: .transient
        )
        _ = session
        XCTAssertEqual(try transientCount(), 1)

        // Launch sequence: scan recovery first, then transient cleanup.
        let recovery = try RecoveryService(database: database).recoverOrphanedScans()
        XCTAssertEqual(recovery.recoveredSnapshotIDs.count, 1)
        XCTAssertEqual(try database.scalar("SELECT status FROM snapshots WHERE snapshot_kind = 'transient'")?.stringValue, "interrupted")

        let deleted = try TransientSnapshotLifecycle(database: database).cleanupUnreferencedTransients()
        XCTAssertEqual(deleted, 1)
        XCTAssertEqual(try transientCount(), 0)
    }
}
