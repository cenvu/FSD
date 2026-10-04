import XCTest
@testable import FSD

/// Milestone 5 Part 7 — startup, recovery and catalog reliability on isolated
/// catalogs. Migration-chain and damaged-schema evidence is covered by the
/// existing `SchemaMigrationTests` / `SchemaSafetyCorrectionTests` suites
/// (cited in the Handoff); these tests add the fresh-startup, lock-contention,
/// repeated-cycle, interrupted-op-relaunch and owner-catalog isolation probes.
final class M5ReliabilityTests: XCTestCase {
    private var directory: URL!
    private var database: CatalogDatabase!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-M5-Reliable-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        database?.close()
        database = nil
        try? FileManager.default.removeItem(at: directory)
        directory = nil
    }

    private var catalogURL: URL { directory.appendingPathComponent("catalog.sqlite3") }

    func testFreshStartupCreatesV9CatalogCleanIntegrityAndHoldsTheLock() throws {
        database = try CatalogDatabase(url: catalogURL, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        let lock = try CatalogProcessLock(catalogURL: catalogURL)
        XCTAssertTrue(lock.isHeld)
        XCTAssertEqual(try database.scalar("SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1")?.int64Value, 9)
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
        lock.unlock()
        XCTAssertFalse(lock.isHeld)
    }

    func testProcessLockContentionIsRefusedAndReleasedOnUnlock() throws {
        database = try CatalogDatabase(url: catalogURL, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        let first = try CatalogProcessLock(catalogURL: catalogURL)
        XCTAssertThrowsError(try CatalogProcessLock(catalogURL: catalogURL)) { error in
            guard case CatalogProcessLock.LockError.alreadyLocked = error else {
                return XCTFail("expected alreadyLocked, got \(error)")
            }
        }
        // Releasing the first lock lets a second owner in (relaunch case).
        first.unlock()
        let second = try CatalogProcessLock(catalogURL: catalogURL)
        XCTAssertTrue(second.isHeld)
        second.unlock()
    }

    func testRepeatedOpenCloseCyclesLeaveTheCatalogClean() throws {
        database = try CatalogDatabase(url: catalogURL, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        let snapshotID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 81, session: 1, sensitivity: .sensitive)
        let built = SyntheticSnapshot.treeEntries(directoryCount: 2, filesPerDirectory: 3, sizeOfFile: { syntheticSize($0, $1) })
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: snapshotID, entries: built.entries)
        try SyntheticSnapshot.complete(database: database, snapshotID: snapshotID)

        for cycle in 0..<10 {
            database.close()
            database = try CatalogDatabase(url: catalogURL, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
            XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok", "cycle \(cycle)")
            XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty, "cycle \(cycle)")
            let root = try SnapshotTreeDataSource(database: database, snapshotID: snapshotID).root()
            XCTAssertNotNil(root, "cycle \(cycle): the snapshot stays browsable")
            // The lock file is released each cycle (a relaunch can re-acquire).
            let lock = try CatalogProcessLock(catalogURL: catalogURL)
            lock.unlock()
        }
        database.close()
        // Record whether the WAL/SHM siblings were removed by clean close.
        let leftovers = (try? FileManager.default.contentsOfDirectory(atPath: directory.path))?
            .filter { $0.contains("-wal") || $0.contains("-shm") } ?? []
        print("[FSD-M5-Reliability] repeated open/close cycles clean; WAL/SHM files after final close: \(leftovers)")
    }

    func testInterruptedOperationRelaunchShowsTheSameTerminalState() throws {
        // Seed the abandoned-work state, run the full launch sequence, close,
        // then reopen and confirm the terminal state is stable across relaunch.
        database = try CatalogDatabase(url: catalogURL, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        let repository = SnapshotRepository(database: database)
        try repository.createVolume(id: 91, displayName: "Relaunch")
        let orphanedScan = try repository.createSnapshot(volumeID: 91, sessionNumber: 1, scanRootName: "Orphan")
        // A crash leaves a completed transient and a running comparison row
        // (the schema's source-eligibility trigger requires complete sides).
        let transient = try repository.createSnapshot(volumeID: 91, sessionNumber: 2, scanRootName: "T", kind: .transient)
        _ = try repository.addRoot(to: transient, name: "T")
        try repository.complete(transient)
        try database.execute(
            """
            INSERT INTO comparisons (left_snapshot_id, right_snapshot_id, profile_id, profile_version, status, started_at, created_at)
            VALUES (?, ?, 1, 1, 'running', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            """,
            bindings: [.integer(transient.rawValue), .integer(transient.rawValue)]
        )

        func runLaunchSequence() throws {
            _ = try RecoveryService(database: database).recoverOrphanedScans()
            let lifecycle = TransientSnapshotLifecycle(database: database)
            _ = try lifecycle.recoverOrphanedComparisons()
            _ = try lifecycle.cleanupUnreferencedTransients()
        }

        try runLaunchSequence()
        let firstState = try database.query(
            "SELECT status FROM snapshots WHERE id IN (?, ?) ORDER BY id",
            bindings: [.integer(orphanedScan.rawValue), .integer(transient.rawValue)]
        ).map { $0["status"]?.stringValue ?? "?" }
        let firstComparison = try database.scalar("SELECT status FROM comparisons ORDER BY id DESC LIMIT 1")?.stringValue

        database.close()
        database = try CatalogDatabase(url: catalogURL, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        try runLaunchSequence()

        let secondState = try database.query(
            "SELECT status FROM snapshots WHERE id IN (?, ?) ORDER BY id",
            bindings: [.integer(orphanedScan.rawValue), .integer(transient.rawValue)]
        ).map { $0["status"]?.stringValue ?? "?" }
        let secondComparison = try database.scalar("SELECT status FROM comparisons ORDER BY id DESC LIMIT 1")?.stringValue

        XCTAssertEqual(secondState, firstState, "relaunch preserves the exact terminal state")
        XCTAssertEqual(firstState[0], "interrupted")
        XCTAssertEqual(firstComparison, "failed")
        XCTAssertEqual(secondComparison, firstComparison)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM comparisons WHERE status = 'running'")?.int64Value, 0)
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
    }

    func testDamagedCurrentSchemaIsRejectedOnReopen() throws {
        database = try CatalogDatabase(url: catalogURL, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        XCTAssertEqual(try database.scalar("SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1")?.int64Value, 9)
        // Damage the current schema by dropping a canonical trigger.
        try database.execute("DROP TRIGGER trg_snapshots_capture_facts_immutable")
        database.close()
        XCTAssertThrowsError(try CatalogDatabase(url: catalogURL, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)) { error in
            guard case CatalogDatabaseError.schemaStateInvalid = error else {
                return XCTFail("expected schemaStateInvalid, got \(error)")
            }
        }
    }

    func testTestHostNeverTouchesTheOwnerCatalog() throws {
        let resolved = try CatalogLocationResolver.resolve()
        XCTAssertEqual(resolved.origin, .testHost, "the test host always resolves its own isolated catalog")
        let ownerURL = try CatalogLocationResolver.defaultURL()
        XCTAssertNotEqual(ownerURL.path, resolved.url.path)

        // The owner's catalog file must not change while the test host opens,
        // migrates and closes its own catalog.
        let before = try? FileManager.default.attributesOfItem(atPath: ownerURL.path)
        database = try CatalogDatabase(url: catalogURL, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        let snapshotID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 99, session: 1, sensitivity: .sensitive)
        let built = SyntheticSnapshot.treeEntries(directoryCount: 1, filesPerDirectory: 1, sizeOfFile: { syntheticSize($0, $1) })
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: snapshotID, entries: built.entries)
        try SyntheticSnapshot.complete(database: database, snapshotID: snapshotID)
        database.close()
        let after = try? FileManager.default.attributesOfItem(atPath: ownerURL.path)

        XCTAssertEqual(after?[.size] as? Int64, before?[.size] as? Int64, "the owner catalog size is untouched")
        XCTAssertEqual(after?[.modificationDate] as? Date, before?[.modificationDate] as? Date, "the owner catalog is untouched")
        print("[FSD-M5-Reliability] owner catalog at \(ownerURL.path) untouched; test host catalog at \(resolved.url.path)")
    }

}
