import XCTest
@testable import FSD

/// Milestone 5 Part 6 — repeated cancellation, race and recovery stress.
/// Every iteration asserts the same terminal invariants: exactly one terminal
/// state wins, cancelled work never becomes complete, orphaned work never
/// appears complete, completed snapshots/results stay immutable, no deadlock,
/// no residue, and integrity/foreign keys stay clean.
final class CancellationRaceStressTests: XCTestCase {
    private var directory: URL!
    private var database: CatalogDatabase!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-M5-Cancel-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        database = try CatalogDatabase(
            url: directory.appendingPathComponent("catalog.sqlite3"),
            schemaURL: CatalogSchemaFixture.canonicalSchemaURL
        )
    }

    override func tearDownWithError() throws {
        database?.close()
        database = nil
        try? FileManager.default.removeItem(at: directory)
        directory = nil
    }

    /// A small real source tree (payload bytes are fixture content; product
    /// code never reads them).
    private func makeSourceTree(files: Int, prefix: String) throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-M5-Cancel-Source-\(prefix)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        for index in 0..<files {
            try Data(repeating: UInt8(index % 251), count: 16)
                .write(to: root.appendingPathComponent(String(format: "f%05d.bin", index)))
        }
        return root
    }

    private func assertCleanCatalog() throws {
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
    }

    private func snapshotStatuses() throws -> [String] {
        try database.query("SELECT status FROM snapshots ORDER BY id").map { $0["status"]?.stringValue ?? "?" }
    }

    // MARK: - Capture cancellation

    func testRepeatedCaptureCancellationExactlyOneTerminalState() throws {
        let source = try makeSourceTree(files: 1200, prefix: "cap")
        defer { try? FileManager.default.removeItem(at: source) }
        for iteration in 0..<5 {
            let token = CaptureCancellationToken()
            let scanner = SnapshotScanner(database: database, batchSize: 50)
            var result: SnapshotRecord?
            XCTAssertNoThrow(
                try scanner.capture(root: source, token: token) { progress in
                    if progress.processedEntries >= 300 + Int64(iteration * 100) { token.cancel() }
                },
                "iteration \(iteration) must terminate without a deadlock"
            )
            result = try SnapshotRepository(database: database).listSnapshots().first
            XCTAssertEqual(result?.status, .cancelled, "iteration \(iteration): the one terminal state is cancelled")
            XCTAssertFalse(result?.isComplete ?? true, "cancelled work never becomes complete")
        }
        let statuses = try snapshotStatuses()
        XCTAssertEqual(statuses.count, 5)
        XCTAssertTrue(statuses.allSatisfy { $0 == "cancelled" })
        try assertCleanCatalog()
    }

    // MARK: - Live-mode cancellation through ComparisonService

    func testRepeatedLiveToSnapshotCancellationLeavesNoResidue() throws {
        let source = try makeSourceTree(files: 800, prefix: "l2s")
        defer { try? FileManager.default.removeItem(at: source) }
        let repository = SnapshotRepository(database: database)
        try repository.createVolume(id: 31, displayName: "Ref")
        let snapshot = try repository.createSnapshot(volumeID: 31, sessionNumber: 1, scanRootName: "Ref")
        _ = try repository.addRoot(to: snapshot, name: "Ref")
        try repository.complete(snapshot)

        for iteration in 0..<3 {
            let token = CaptureCancellationToken()
            let service = ComparisonService(database: database)
            XCTAssertThrowsError(try service.liveToSnapshot(liveRoot: source, snapshotID: snapshot, token: token) { progress in
                if progress.processedEntries >= 200 + Int64(iteration * 150) { token.cancel() }
            }) { error in
                guard case ComparisonError.cancelled = error else {
                    return XCTFail("iteration \(iteration): expected cancelled, got \(error)")
                }
            }
            let comparisons = try ComparisonResultRepository(database: database).listComparisons()
            XCTAssertTrue(comparisons.isEmpty, "a cancelled live comparison leaves no comparison record")
            let transients = try database.scalar(
                "SELECT COUNT(*) FROM snapshots WHERE snapshot_kind = 'transient'"
            )?.int64Value ?? -1
            XCTAssertEqual(transients, 0, "a cancelled live comparison leaves no transient residue")
            XCTAssertEqual(try repository.snapshot(id: snapshot)?.status, .complete, "the reference snapshot stays complete and immutable")
        }
        try assertCleanCatalog()
    }

    func testLiveToLiveCancellationOnEitherSide() throws {
        // The left tree is much smaller than the right, so a progress tick
        // past the left tree's total can only belong to the right capture —
        // this distinguishes the sides without depending on phase timing.
        let leftSource = try makeSourceTree(files: 100, prefix: "l")
        let rightSource = try makeSourceTree(files: 5000, prefix: "r")
        defer {
            try? FileManager.default.removeItem(at: leftSource)
            try? FileManager.default.removeItem(at: rightSource)
        }

        // Cancel during the left capture (mid-way through its 100 entries).
        let tokenLeft = CaptureCancellationToken()
        let service = ComparisonService(database: database)
        var cancelledLeftCapture = false
        XCTAssertThrowsError(try service.liveToLive(leftRoot: leftSource, rightRoot: rightSource, token: tokenLeft) { progress in
            if progress.processedEntries >= 50 {
                cancelledLeftCapture = true
                tokenLeft.cancel()
            }
        }) { error in
            guard case ComparisonError.cancelled = error else {
                return XCTFail("left-side cancellation: expected cancelled, got \(error)")
            }
        }
        XCTAssertTrue(cancelledLeftCapture)

        // Cancel during the right capture: any tick past 100 entries is the
        // right capture (5000 entries), so this cannot hit the left one.
        let tokenRight = CaptureCancellationToken()
        var cancelledRightCapture = false
        XCTAssertThrowsError(try service.liveToLive(leftRoot: leftSource, rightRoot: rightSource, token: tokenRight) { progress in
            if progress.processedEntries >= 300 {
                cancelledRightCapture = true
                tokenRight.cancel()
            }
        }) { error in
            guard case ComparisonError.cancelled = error else {
                return XCTFail("right-side cancellation: expected cancelled, got \(error)")
            }
        }
        XCTAssertTrue(cancelledRightCapture)

        // Cancel at the start of the merge phase: both captures are done and
        // the comparison row exists; the merge throws cancelled, the row is
        // terminalized cancelled (never complete) and the referenced
        // transients stay retained as the cancelled comparison's evidence.
        let tokenMerge = CaptureCancellationToken()
        XCTAssertThrowsError(try service.liveToLive(leftRoot: leftSource, rightRoot: rightSource, token: tokenMerge) { progress in
            if progress.phase == "Matching" { tokenMerge.cancel() }
        }) { error in
            guard case ComparisonError.cancelled = error else {
                return XCTFail("merge cancellation: expected cancelled, got \(error)")
            }
        }
        let comparisons = try ComparisonResultRepository(database: database).listComparisons()
        XCTAssertEqual(comparisons.count, 1)
        XCTAssertEqual(comparisons[0].status, .cancelled, "a merge-cancelled live comparison is cancelled — never complete")
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM comparisons WHERE status = 'running'")?.int64Value, 0)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM snapshots WHERE snapshot_kind = 'transient'")?.int64Value, 2, "the cancelled comparison's referenced transients are its retained evidence")
        let persisted = try database.scalar(
            "SELECT COUNT(*) FROM comparison_results WHERE comparison_id = ?",
            bindings: [.integer(comparisons[0].id.rawValue)]
        )?.int64Value ?? 0
        XCTAssertEqual(comparisons[0].matchedCount + comparisons[0].changedCount + comparisons[0].addedCount + comparisons[0].removedCount + comparisons[0].uncertainCount, persisted)
        try assertCleanCatalog()
    }

    // MARK: - Comparison matching and persistence cancellation

    func testRepeatedComparisonCancellationDuringMatchingAndPersistence() throws {
        // One synthetic pair, three cancellation points: 30%, 55%, 90%.
        let leftID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 41, session: 1, sensitivity: .sensitive)
        let rightID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 41, session: 2, sensitivity: .sensitive)
        let built = SyntheticSnapshot.treeEntries(
            directoryCount: 50, filesPerDirectory: 1000,
            sizeOfFile: { syntheticSize($0, $1) }, modifiedAt: "1234"
        )
        let mirrored = SyntheticSnapshot.treeEntries(
            directoryCount: 50, filesPerDirectory: 1000,
            firstID: 100_000, sizeOfFile: { syntheticSize($0, $1) }, modifiedAt: "1234"
        )
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: leftID, entries: built.entries)
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: rightID, entries: mirrored.entries)
        try SyntheticSnapshot.complete(database: database, snapshotID: leftID)
        try SyntheticSnapshot.complete(database: database, snapshotID: rightID)

        let total = Int64(built.entries.count + mirrored.entries.count)
        for (iteration, fraction) in [0.3, 0.55, 0.9].enumerated() {
            let token = CaptureCancellationToken()
            let service = ComparisonService(database: database)
            var lastProgress: Int64 = 0
            var didCancel = false
            XCTAssertThrowsError(try service.snapshotToSnapshot(leftSnapshotID: leftID, rightSnapshotID: rightID, token: token) { progress in
                lastProgress = progress.processedEntries
                if !didCancel, Double(progress.processedEntries) >= Double(total) * fraction {
                    didCancel = true
                    token.cancel()
                }
            }) { error in
                guard case ComparisonError.cancelled = error else {
                    return XCTFail("iteration \(iteration): expected cancelled, got \(error)")
                }
            }
            XCTAssertTrue(didCancel)
            XCTAssertLessThanOrEqual(lastProgress, Int64(Double(total) * fraction) + 20_000, "processing stops shortly after the cancel point")
            let records = try ComparisonResultRepository(database: database).listComparisons()
            XCTAssertEqual(records.count, iteration + 1)
            let record = records[0] // listComparisons orders by started_at DESC, id DESC
            XCTAssertEqual(record.status, .cancelled)
            let persisted = try database.scalar(
                "SELECT COUNT(*) FROM comparison_results WHERE comparison_id = ?",
                bindings: [.integer(record.id.rawValue)]
            )?.int64Value ?? 0
            XCTAssertEqual(
                record.matchedCount + record.changedCount + record.addedCount + record.removedCount + record.uncertainCount,
                persisted,
                "each cancelled comparison's summary matches its retained evidence exactly"
            )
            XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM comparisons WHERE status = 'running'")?.int64Value, 0, "no comparison is left running")
        }
        try assertCleanCatalog()
    }

    // MARK: - Cancellation near terminalization

    func testCancellationNearTerminalizationIsDeterministicAndConsistent() throws {
        let leftID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 51, session: 1, sensitivity: .sensitive)
        let rightID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 51, session: 2, sensitivity: .sensitive)
        let built = SyntheticSnapshot.treeEntries(directoryCount: 30, filesPerDirectory: 500, sizeOfFile: { syntheticSize($0, $1) })
        let mirrored = SyntheticSnapshot.treeEntries(directoryCount: 30, filesPerDirectory: 500, firstID: 1_000_000, sizeOfFile: { syntheticSize($0, $1) })
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: leftID, entries: built.entries)
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: rightID, entries: mirrored.entries)
        try SyntheticSnapshot.complete(database: database, snapshotID: leftID)
        try SyntheticSnapshot.complete(database: database, snapshotID: rightID)

        for iteration in 0..<3 {
            let token = CaptureCancellationToken()
            let service = ComparisonService(database: database)
            var returned: ComparisonRecord?
            do {
                returned = try service.snapshotToSnapshot(leftSnapshotID: leftID, rightSnapshotID: rightID, token: token) { progress in
                    if progress.phase == "Finalizing" { token.cancel() }
                }
            } catch let error as ComparisonError {
                XCTAssertEqual(error, .cancelled)
            }
            // The finalization lock decides. When the cancel lands before the
            // lock, the call returns a record already terminalized cancelled
            // (never complete); when it lands after, the call throws
            // cancelled. Either way exactly one terminal state wins and the
            // summary matches the retained rows.
            let records = try ComparisonResultRepository(database: database).listComparisons()
            let record = records[0] // listComparisons orders by started_at DESC, id DESC
            if let returned {
                XCTAssertEqual(returned.id, record.id)
            }
            XCTAssertTrue(record.status == .complete || record.status == .cancelled, "iteration \(iteration): exactly one terminal state wins")
            let persisted = try database.scalar(
                "SELECT COUNT(*) FROM comparison_results WHERE comparison_id = ?",
                bindings: [.integer(record.id.rawValue)]
            )?.int64Value ?? 0
            XCTAssertEqual(record.matchedCount + record.changedCount + record.addedCount + record.removedCount + record.uncertainCount, persisted, "iteration \(iteration): the summary always matches the retained evidence")
            XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM comparisons WHERE status = 'running'")?.int64Value, 0, "iteration \(iteration): no comparison survives running")
        }
        try assertCleanCatalog()
    }

    // MARK: - Process interruption and repeated recovery

    func testRepeatedOrphanRecoveryExactlyOneTerminalStateEachTime() throws {
        for iteration in 0..<3 {
            // A crashed capture: a scanning snapshot with no terminal state.
            let repository = SnapshotRepository(database: database)
            let volumeID = Int64(61 + iteration)
            try repository.createVolume(id: volumeID, displayName: "Crash")
            let orphanedScan = try repository.createSnapshot(volumeID: volumeID, sessionNumber: Int64(iteration * 3 + 1), scanRootName: "Orphan")
            // A crashed live comparison: a `running` comparison referencing
            // two transients, plus one transient no comparison references.
            // All transients are complete — a crash leaves completed
            // scaffolding with only the scan still non-terminal.
            let unreferencedTransient = try repository.createSnapshot(
                volumeID: volumeID, sessionNumber: Int64(iteration * 3 + 2), scanRootName: "U",
                kind: .transient, sourceCaseSensitivity: .sensitive
            )
            let leftTransient = try repository.createSnapshot(
                volumeID: volumeID, sessionNumber: Int64(iteration * 3 + 3), scanRootName: "L",
                kind: .transient, sourceCaseSensitivity: .sensitive
            )
            let rightTransient = try repository.createSnapshot(
                volumeID: volumeID, sessionNumber: Int64(iteration * 3 + 4), scanRootName: "R",
                kind: .transient, sourceCaseSensitivity: .sensitive
            )
            // A crash leaves completed transients and a running comparison row
            // (the source-eligibility trigger requires complete sides).
            _ = try repository.addRoot(to: unreferencedTransient, name: "U")
            try repository.complete(unreferencedTransient)
            _ = try repository.addRoot(to: leftTransient, name: "L")
            try repository.complete(leftTransient)
            _ = try repository.addRoot(to: rightTransient, name: "R")
            try repository.complete(rightTransient)
            try database.execute(
                """
                INSERT INTO comparisons (left_snapshot_id, right_snapshot_id, profile_id, profile_version, status, started_at, created_at)
                VALUES (?, ?, 1, 1, 'running', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """,
                bindings: [.integer(leftTransient.rawValue), .integer(rightTransient.rawValue)]
            )

            // Full launch sequence: scan recovery, comparison recovery,
            // transient cleanup.
            let recovery = try RecoveryService(database: database).recoverOrphanedScans()
            XCTAssertEqual(recovery.recoveredSnapshotIDs, [orphanedScan])
            let lifecycle = TransientSnapshotLifecycle(database: database)
            let comparisonReport = try lifecycle.recoverOrphanedComparisons()
            XCTAssertEqual(comparisonReport.recoveredComparisonIDs.count, 1)
            _ = try lifecycle.cleanupUnreferencedTransients()

            XCTAssertEqual(try repository.snapshot(id: orphanedScan)?.status, .interrupted, "an orphaned scan recovers as interrupted — never complete")
            XCTAssertNil(try repository.snapshot(id: unreferencedTransient), "an unreferenced transient is deleted")
            // Referenced transients are retained: the failed comparison row
            // is the safe evidence of the abandoned work (lifecycle policy).
            XCTAssertNotNil(try repository.snapshot(id: leftTransient))
            XCTAssertNotNil(try repository.snapshot(id: rightTransient))
            let comparisonStatus = try database.scalar("SELECT status FROM comparisons ORDER BY id DESC LIMIT 1")?.stringValue
            XCTAssertEqual(comparisonStatus, "failed", "an orphaned comparison recovers as failed — never complete")

            // Repeated recovery is idempotent.
            XCTAssertEqual(try RecoveryService(database: database).recoverOrphanedScans().recoveredSnapshotIDs, [])
            XCTAssertEqual(try lifecycle.recoverOrphanedComparisons().recoveredComparisonIDs, [])
            XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM comparisons WHERE status = 'running'")?.int64Value, 0)
        }
        try assertCleanCatalog()
    }

    // MARK: - Workspace close during a running live comparison

    func testWorkspaceCloseDuringRunningLiveComparisonEndsCleanly() throws {
        let leftSource = try makeSourceTree(files: 4000, prefix: "ws-l")
        let rightSource = try makeSourceTree(files: 4000, prefix: "ws-r")
        defer {
            try? FileManager.default.removeItem(at: leftSource)
            try? FileManager.default.removeItem(at: rightSource)
        }

        let token = CaptureCancellationToken()
        let service = ComparisonService(database: database)
        var backgroundResult: Result<ComparisonRecord, Error>?
        let expectation = expectation(description: "live comparison finishes or cancels")
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let record = try service.liveToLive(leftRoot: leftSource, rightRoot: rightSource, token: token)
                backgroundResult = .success(record)
            } catch {
                backgroundResult = .failure(error)
            }
            expectation.fulfill()
        }

        // Let the capture/merge get underway, then close the workspace.
        Thread.sleep(forTimeInterval: 0.25)
        token.cancel()
        try service.closeWorkspace()

        wait(for: [expectation], timeout: 120)

        // The workspace is closed: no running comparison, no transient
        // residue, nothing left behind.
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM comparisons WHERE status = 'running'")?.int64Value, 0)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM snapshots WHERE snapshot_kind = 'transient'")?.int64Value, 0)
        XCTAssertEqual(try ComparisonResultRepository(database: database).listComparisons().count, 0, "live-side comparisons are disposed on close")
        if let backgroundResult {
            switch backgroundResult {
            case .success(let record):
                XCTAssertEqual(record.status, .complete, "a completed comparison still completes, but its row is disposed by close")
            case .failure(let error):
                XCTAssertNotNil(error)
            }
        }
        try assertCleanCatalog()
    }

    // MARK: - Repeated launch/close cycles

    func testRepeatedLaunchCycleRecoveryIsIdempotent() throws {
        // Seed one orphaned scanning snapshot and one orphaned running
        // comparison, then run five simulated launches over the same catalog.
        let repository = SnapshotRepository(database: database)
        try repository.createVolume(id: 71, displayName: "Cycles")
        let orphan = try repository.createSnapshot(volumeID: 71, sessionNumber: 1, scanRootName: "Orphan")
        let transient = try repository.createSnapshot(volumeID: 71, sessionNumber: 2, scanRootName: "T", kind: .transient)
        _ = try repository.addRoot(to: transient, name: "T")
        try repository.complete(transient)
        try database.execute(
            """
            INSERT INTO comparisons (left_snapshot_id, right_snapshot_id, profile_id, profile_version, status, started_at, created_at)
            VALUES (?, ?, 1, 1, 'running', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            """,
            bindings: [.integer(transient.rawValue), .integer(transient.rawValue)]
        )

        for cycle in 0..<5 {
            _ = try RecoveryService(database: database).recoverOrphanedScans()
            let lifecycle = TransientSnapshotLifecycle(database: database)
            _ = try lifecycle.recoverOrphanedComparisons()
            _ = try lifecycle.cleanupUnreferencedTransients()
            XCTAssertEqual(try repository.snapshot(id: orphan)?.status, .interrupted, "cycle \(cycle): recovery is idempotent")
            XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM comparisons WHERE status = 'running'")?.int64Value, 0)
        }
        try assertCleanCatalog()
    }
}
