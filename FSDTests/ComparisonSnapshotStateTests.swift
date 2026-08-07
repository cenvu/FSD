import XCTest
@testable import FSD

/// Snapshot eligibility policy: only `complete` and `complete_with_warnings`
/// snapshots may participate; every other state is rejected with a typed
/// eligibility error, and warnings on an eligible side stay visible.
final class ComparisonSnapshotStateTests: XCTestCase {
    private var directory: URL!
    private var database: CatalogDatabase!
    private var service: ComparisonService!
    private var results: ComparisonResultRepository!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-State-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
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
    }

    private func makeSnapshot(id: Int64, status: SnapshotStatus, warningCount: Int64 = 0) throws -> SnapshotID {
        let snapshotID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 5, session: id, sensitivity: .sensitive)
        try SyntheticSnapshot.insertEntries(
            database: database, snapshotID: snapshotID,
            entries: [SyntheticSnapshot.root(id: id * 100, name: "Root"), SyntheticSnapshot.SeedEntry(id: id * 100 + 1, parentID: id * 100, relativePath: "a.txt", name: "a.txt", logicalSizeBytes: 1)]
        )
        if status == .completeWithWarnings {
            // One atomic update: the status and the warning count land
            // together, exactly as the writer's terminal transition would
            // have left them for a capture that finished with warnings. The
            // completion trigger still validates root and normalization.
            try database.execute(
                "UPDATE snapshots SET status = 'complete_with_warnings', completed_at = CURRENT_TIMESTAMP, warning_count = ? WHERE id = ?",
                bindings: [.integer(warningCount), .integer(snapshotID.rawValue)]
            )
        } else if status == .complete {
            try SyntheticSnapshot.complete(database: database, snapshotID: snapshotID)
        } else if status != .scanning {
            // A scanning snapshot is already in the state we need.
            try SnapshotRepository(database: database).transition(snapshotID, to: status)
        }
        return snapshotID
    }

    private func makeComplete(id: Int64) throws -> SnapshotID {
        try makeSnapshot(id: id, status: .complete)
    }

    private func assertEligibilityError(_ error: Error, for id: SnapshotID, status: SnapshotStatus) {
        guard case let ComparisonError.ineligibleSnapshot(reportedID, reportedStatus, _) = error else {
            return XCTFail("Unexpected error: \(error)")
        }
        XCTAssertEqual(reportedID, id)
        XCTAssertEqual(reportedStatus, status)
    }

    // MARK: - Eligible states

    func testCompleteSnapshotIsEligible() throws {
        let left = try makeComplete(id: 1)
        let right = try makeComplete(id: 2)
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: left, rightSnapshotID: right)
        XCTAssertEqual(comparison.status, .complete)
        XCTAssertEqual(comparison.matchedCount, 2)
    }

    func testCompleteWithWarningsSnapshotIsEligibleAndWarningsAreSurfaced() throws {
        let left = try makeSnapshot(id: 1, status: .completeWithWarnings, warningCount: 3)
        let right = try makeComplete(id: 2)
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: left, rightSnapshotID: right)
        XCTAssertEqual(comparison.status, .complete)
        XCTAssertEqual(comparison.left.warningCount, 3)
        XCTAssertEqual(comparison.left.status, .completeWithWarnings)
        XCTAssertEqual(comparison.right.warningCount, 0)
    }

    // MARK: - Rejected states

    func testScanningSnapshotIsRejected() throws {
        let scanning = try makeSnapshot(id: 1, status: .scanning)
        let right = try makeComplete(id: 2)
        XCTAssertThrowsError(try service.snapshotToSnapshot(leftSnapshotID: scanning, rightSnapshotID: right)) { error in
            self.assertEligibilityError(error, for: scanning, status: .scanning)
        }
    }

    func testInterruptedSnapshotIsRejected() throws {
        let interrupted = try makeSnapshot(id: 1, status: .interrupted)
        let right = try makeComplete(id: 2)
        XCTAssertThrowsError(try service.snapshotToSnapshot(leftSnapshotID: interrupted, rightSnapshotID: right)) { error in
            self.assertEligibilityError(error, for: interrupted, status: .interrupted)
        }
    }

    func testCancelledSnapshotIsRejected() throws {
        let cancelled = try makeSnapshot(id: 1, status: .cancelled)
        let right = try makeComplete(id: 2)
        XCTAssertThrowsError(try service.snapshotToSnapshot(leftSnapshotID: cancelled, rightSnapshotID: right)) { error in
            self.assertEligibilityError(error, for: cancelled, status: .cancelled)
        }
    }

    func testFailedSnapshotIsRejected() throws {
        let failed = try makeSnapshot(id: 1, status: .failed)
        let right = try makeComplete(id: 2)
        XCTAssertThrowsError(try service.snapshotToSnapshot(leftSnapshotID: failed, rightSnapshotID: right)) { error in
            self.assertEligibilityError(error, for: failed, status: .failed)
        }
    }

    func testEligibilityFailureLeavesNoComparisonRow() throws {
        let scanning = try makeSnapshot(id: 1, status: .scanning)
        let right = try makeComplete(id: 2)
        _ = try? service.snapshotToSnapshot(leftSnapshotID: scanning, rightSnapshotID: right)
        XCTAssertEqual(try results.count(), 0)
    }

    /// The schema itself also enforces eligibility: even a direct INSERT of a
    /// comparison against a non-complete snapshot is rejected by the trigger,
    /// so the engine and the database agree.
    func testSchemaTriggerRejectsNonCompleteSourcesIndependently() throws {
        let scanning = try makeSnapshot(id: 1, status: .scanning)
        let right = try makeComplete(id: 2)
        XCTAssertThrowsError(try database.execute(
            """
            INSERT INTO comparisons (left_snapshot_id, right_snapshot_id, profile_id, status, started_at, created_at)
            VALUES (?, ?, 1, 'running', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            """,
            bindings: [.integer(scanning.rawValue), .integer(right.rawValue)]
        ))
    }

    // MARK: - Missing snapshot

    func testUnknownSnapshotProducesTypedNotFoundError() throws {
        let right = try makeComplete(id: 2)
        let missing = SnapshotID(rawValue: 4242)
        XCTAssertThrowsError(try service.snapshotToSnapshot(leftSnapshotID: missing, rightSnapshotID: right)) { error in
            guard case ComparisonError.snapshotNotFound(missing) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }
}
