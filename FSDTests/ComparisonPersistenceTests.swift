import XCTest
@testable import FSD

/// Persistence invariants: summary counts match detailed rows, terminal
/// states are protected at both the engine and the schema boundary, profile
/// versions are frozen, repeated comparisons are deterministic, and the
/// comparison pipeline never touches classification or snapshot data.
final class ComparisonPersistenceTests: XCTestCase {
    private var directory: URL!
    private var database: CatalogDatabase!
    private var service: ComparisonService!
    private var results: ComparisonResultRepository!
    private var leftSnapshot: SnapshotID!
    private var rightSnapshot: SnapshotID!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-Persist-\(UUID().uuidString)", isDirectory: true)
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
        leftSnapshot = nil
        rightSnapshot = nil
    }

    private func seedPair() throws {
        let leftID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 3, session: 1, sensitivity: .sensitive)
        let rightID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 3, session: 2, sensitivity: .sensitive)
        let leftRoot = SyntheticSnapshot.root(id: 100, name: "Root")
        let rightRoot = SyntheticSnapshot.root(id: 200, name: "Root")
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: leftID, entries: [
            leftRoot,
            SyntheticSnapshot.SeedEntry(id: 101, parentID: 100, relativePath: "same.bin", name: "same.bin", logicalSizeBytes: 5),
            SyntheticSnapshot.SeedEntry(id: 102, parentID: 100, relativePath: "moved.bin", name: "moved.bin", logicalSizeBytes: 9),
            SyntheticSnapshot.SeedEntry(id: 103, parentID: 100, relativePath: ".DS_Store", name: ".DS_Store", logicalSizeBytes: 1)
        ])
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: rightID, entries: [
            rightRoot,
            SyntheticSnapshot.SeedEntry(id: 201, parentID: 200, relativePath: "same.bin", name: "same.bin", logicalSizeBytes: 5),
            SyntheticSnapshot.SeedEntry(id: 202, parentID: 200, relativePath: "moved.bin", name: "moved.bin", logicalSizeBytes: 99),
            SyntheticSnapshot.SeedEntry(id: 203, parentID: 200, relativePath: ".DS_Store", name: ".DS_Store", logicalSizeBytes: 1),
            SyntheticSnapshot.SeedEntry(id: 204, parentID: 200, relativePath: "added.bin", name: "added.bin", logicalSizeBytes: 2)
        ])
        try SyntheticSnapshot.complete(database: database, snapshotID: leftID)
        try SyntheticSnapshot.complete(database: database, snapshotID: rightID)
        leftSnapshot = leftID
        rightSnapshot = rightID
    }

    // MARK: - Summary/detail consistency

    func testSummaryCountsMatchDetailedRowsExactly() throws {
        try seedPair()
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: leftSnapshot, rightSnapshotID: rightSnapshot)

        let counts = try results.resultCounts(comparisonID: comparison.id)
        XCTAssertEqual(counts[.matched] ?? 0, 2, "root + same.bin")
        XCTAssertEqual(counts[.changed] ?? 0, 1, "moved.bin")
        XCTAssertEqual(counts[.added] ?? 0, 1, "added.bin")
        XCTAssertEqual(counts[.removed] ?? 0, 0)
        XCTAssertEqual(counts[.uncertain] ?? 0, 0)

        XCTAssertEqual(comparison.matchedCount, counts[.matched] ?? 0)
        XCTAssertEqual(comparison.changedCount, counts[.changed] ?? 0)
        XCTAssertEqual(comparison.addedCount, counts[.added] ?? 0)
        XCTAssertEqual(comparison.removedCount, counts[.removed] ?? 0)
        XCTAssertEqual(comparison.uncertainCount, counts[.uncertain] ?? 0)
        XCTAssertEqual(comparison.totalComparedEntries, 4)
        XCTAssertEqual(comparison.totalDifferences, 2)
    }

    func testIgnoredRowsExistButAreNeverCounted() throws {
        try seedPair()
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: leftSnapshot, rightSnapshotID: rightSnapshot)
        let all = try results.results(comparisonID: comparison.id, filter: .all, limit: 100)
        XCTAssertEqual(all.rows.filter { $0.resultType == .ignored }.count, 2, "both .DS_Store rows")
        XCTAssertEqual(try results.resultCounts(comparisonID: comparison.id)[.ignored] ?? 0, 2)
        XCTAssertEqual(comparison.count(for: .ignored), 0, "the record summary has no ignored slot by design")
        XCTAssertEqual(comparison.totalComparedEntries, 4, "ignored rows do not inflate compared totals")
    }

    func testIncompleteResultIsNeverComplete() throws {
        try seedPair()
        // A cancelled comparison (the only observable incomplete terminal).
        // A small-batch engine makes the cancellation land mid-matching.
        let smallBatchService = ComparisonService(
            database: database,
            engine: ComparisonEngine(database: database, pageSize: 10, batchSize: 1)
        )
        let token = CaptureCancellationToken()
        var didCancel = false
        XCTAssertThrowsError(try smallBatchService.snapshotToSnapshot(leftSnapshotID: leftSnapshot, rightSnapshotID: rightSnapshot, token: token) { progress in
            if !didCancel, progress.processedEntries >= 1 {
                didCancel = true
                token.cancel()
            }
        })
        let records = try results.listComparisons()
        XCTAssertEqual(records.count, 1)
        XCTAssertNotEqual(records[0].status, .complete)
        XCTAssertEqual(records[0].status, .cancelled)
    }

    // MARK: - Terminal protection

    func testTerminalComparisonStatusAndCountsAreImmutableAtTheSchemaBoundary() throws {
        try seedPair()
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: leftSnapshot, rightSnapshotID: rightSnapshot)

        XCTAssertThrowsError(try database.execute(
            "UPDATE comparisons SET status = 'running' WHERE id = ?",
            bindings: [.integer(comparison.id.rawValue)]
        ))
        XCTAssertThrowsError(try database.execute(
            "UPDATE comparisons SET matched_count = 999 WHERE id = ?",
            bindings: [.integer(comparison.id.rawValue)]
        ))
        XCTAssertThrowsError(try database.execute(
            "UPDATE comparisons SET added_count = 2 WHERE id = ?",
            bindings: [.integer(comparison.id.rawValue)]
        ))
        XCTAssertEqual(try database.scalar(
            "SELECT status FROM comparisons WHERE id = ?", bindings: [.integer(comparison.id.rawValue)]
        )?.stringValue, "complete")
        XCTAssertEqual(try database.scalar(
            "SELECT matched_count FROM comparisons WHERE id = ?", bindings: [.integer(comparison.id.rawValue)]
        )?.int64Value, comparison.matchedCount)
    }

    func testTerminalResultsCannotBeInsertedOrUpdated() throws {
        try seedPair()
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: leftSnapshot, rightSnapshotID: rightSnapshot)

        XCTAssertThrowsError(try database.execute(
            """
            INSERT INTO comparison_results (comparison_id, result_path, display_name, result_type, created_at)
            VALUES (?, 'late.txt', 'late.txt', 'added', CURRENT_TIMESTAMP)
            """,
            bindings: [.integer(comparison.id.rawValue)]
        ))
        let firstRowID = try XCTUnwrap(try database.scalar(
            "SELECT id FROM comparison_results WHERE comparison_id = ? ORDER BY id LIMIT 1",
            bindings: [.integer(comparison.id.rawValue)]
        )?.int64Value)
        XCTAssertThrowsError(try database.execute(
            "UPDATE comparison_results SET difference_flags = 1 WHERE id = ?",
            bindings: [.integer(firstRowID)]
        ))
        XCTAssertEqual(
            try database.scalar("SELECT difference_flags FROM comparison_results WHERE id = ?", bindings: [.integer(firstRowID)])?.int64Value,
            0
        )
    }

    func testDeletingAComparisonIsTheExplicitDisposalAPI() throws {
        try seedPair()
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: leftSnapshot, rightSnapshotID: rightSnapshot)
        let comparisonID = comparison.id

        try results.deleteComparison(comparisonID)

        XCTAssertEqual(try results.count(), 0)
        XCTAssertNil(try results.record(id: comparisonID))
        XCTAssertEqual(
            try database.scalar("SELECT COUNT(*) FROM comparison_results WHERE comparison_id = ?", bindings: [.integer(comparisonID.rawValue)])?.int64Value,
            0,
            "results cascade with the comparison"
        )
        XCTAssertEqual(try database.scalar(
            "SELECT COUNT(*) FROM snapshots WHERE id IN (?, ?)",
            bindings: [.integer(leftSnapshot.rawValue), .integer(rightSnapshot.rawValue)]
        )?.int64Value, 2, "the snapshots themselves survive")
    }

    func testReferencedTransientCannotBeDeletedWhileItsComparisonLives() throws {
        try seedPair()
        let liveFolder = directory.appendingPathComponent("live", isDirectory: true)
        try FileManager.default.createDirectory(at: liveFolder, withIntermediateDirectories: true)
        try Data("x".utf8).write(to: liveFolder.appendingPathComponent("x.txt"))
        let comparison = try service.liveToSnapshot(liveRoot: liveFolder, snapshotID: leftSnapshot)
        XCTAssertTrue(comparison.right.isLive)

        let transientID = comparison.right.snapshotID.rawValue
        XCTAssertThrowsError(try database.execute(
            "DELETE FROM snapshots WHERE id = ?", bindings: [.integer(transientID)]
        ), "ON DELETE RESTRICT protects a referenced transient (ADR-012)")
        XCTAssertEqual(
            try database.scalar("SELECT COUNT(*) FROM snapshots WHERE id = ?", bindings: [.integer(transientID)])?.int64Value,
            1
        )
    }

    // MARK: - Profile versioning

    func testProfileVersionIsFrozenOnTheComparisonRecord() throws {
        try seedPair()
        let profile = try XCTUnwrap(ComparisonProfileRepository(database: database).profile(id: 1))
        XCTAssertEqual(profile.version, 1)
        XCTAssertEqual(profile.name, "Fast Metadata")
        XCTAssertTrue(profile.isBuiltin)

        let comparison = try service.snapshotToSnapshot(leftSnapshotID: leftSnapshot, rightSnapshotID: rightSnapshot, profileID: 1)
        XCTAssertEqual(comparison.profileID, 1)
        XCTAssertEqual(comparison.profileVersion, profile.version)
        XCTAssertEqual(comparison.profileName, "Fast Metadata")

        let stored = try XCTUnwrap(try database.scalar(
            "SELECT profile_version FROM comparisons WHERE id = ?", bindings: [.integer(comparison.id.rawValue)]
        )?.int64Value)
        XCTAssertEqual(stored, profile.version)
    }

    func testBuiltinProfilesExposeTheCanonicalFieldSelection() throws {
        let profiles = try ComparisonProfileRepository(database: database).allProfiles()
        XCTAssertEqual(profiles.map(\.name), ["Fast Metadata", "Structure Only", "Strict Metadata"])
        let fast = profiles[0]
        XCTAssertTrue(fast.compareItemType && fast.compareLogicalSize)
        XCTAssertFalse(fast.compareAllocatedSize && fast.compareModifiedAt && fast.compareCreatedAt)
        XCTAssertEqual(fast.ignoreRules.count, 6)
        XCTAssertFalse(fast.includeHiddenItems)
        let strict = profiles[2]
        XCTAssertTrue(strict.compareModifiedAt)
        XCTAssertEqual(strict.timestampToleranceSeconds, 2)
        XCTAssertTrue(strict.includeHiddenItems)
        XCTAssertTrue(strict.ignoreRules.isEmpty)
    }

    func testUnknownProfileProducesTypedError() throws {
        try seedPair()
        XCTAssertThrowsError(try service.snapshotToSnapshot(leftSnapshotID: leftSnapshot, rightSnapshotID: rightSnapshot, profileID: 999)) { error in
            guard case ComparisonError.profileNotFound(999) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    // MARK: - Determinism

    func testRepeatedComparisonIsDeterministic() throws {
        try seedPair()
        let first = try service.snapshotToSnapshot(leftSnapshotID: leftSnapshot, rightSnapshotID: rightSnapshot)
        let second = try service.snapshotToSnapshot(leftSnapshotID: leftSnapshot, rightSnapshotID: rightSnapshot)

        XCTAssertEqual(first.matchedCount, second.matchedCount)
        XCTAssertEqual(first.addedCount, second.addedCount)
        XCTAssertEqual(first.changedCount, second.changedCount)
        let firstRows = try results.results(comparisonID: first.id, filter: .all, limit: 1000).rows
            .map { "\($0.resultPath)|\($0.resultType.rawValue)|\($0.differenceFlags)" }
        let secondRows = try results.results(comparisonID: second.id, filter: .all, limit: 1000).rows
            .map { "\($0.resultPath)|\($0.resultType.rawValue)|\($0.differenceFlags)" }
        XCTAssertEqual(firstRows, secondRows)
    }

    // MARK: - Metadata-only boundary

    func testComparisonPipelineNeverTouchesClassificationsOrEntries() throws {
        try seedPair()
        let entriesBefore = try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: leftSnapshot)
        let snapshotBefore = try EntrySnapshotProbe.snapshotFingerprint(database: database, snapshotID: leftSnapshot)

        let comparison = try service.snapshotToSnapshot(leftSnapshotID: leftSnapshot, rightSnapshotID: rightSnapshot)
        _ = try results.fieldDifferences(
            for: XCTUnwrap(try results.results(comparisonID: comparison.id, filter: .modified, limit: 10).rows.first),
            comparisonID: comparison.id
        )
        _ = try results.entryMetadata(id: 101, snapshotID: leftSnapshot)

        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
        XCTAssertEqual(try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: leftSnapshot), entriesBefore)
        XCTAssertEqual(try EntrySnapshotProbe.snapshotFingerprint(database: database, snapshotID: leftSnapshot), snapshotBefore)
    }

    func testResultPagingAndFilteringAreStableAndBounded() throws {
        try seedPair()
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: leftSnapshot, rightSnapshotID: rightSnapshot)

        let pageOne = try results.results(comparisonID: comparison.id, filter: .all, offset: 0, limit: 2)
        let pageTwo = try results.results(comparisonID: comparison.id, filter: .all, offset: 2, limit: 2)
        XCTAssertEqual(pageOne.rows.count, 2)
        XCTAssertEqual(pageTwo.rows.count, 2)
        XCTAssertTrue(pageOne.isTruncated)
        let ids = (pageOne.rows + pageTwo.rows).map(\.id)
        XCTAssertEqual(ids, Set(ids).sorted(), "no overlap, no reordering")

        let differences = try results.results(comparisonID: comparison.id, filter: .differences, limit: 10)
        XCTAssertEqual(differences.rows.map(\.resultPath), ["added.bin", "moved.bin"], "path order, differences only")
        XCTAssertEqual(differences.totalCount, 2)

        let unchanged = try results.results(comparisonID: comparison.id, filter: .unchanged, limit: 10)
        XCTAssertEqual(unchanged.rows.map(\.resultType), [.matched, .matched])
        XCTAssertEqual(unchanged.totalCount, 2)
    }

    func testDifferenceNavigationIsDeterministic() throws {
        try seedPair()
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: leftSnapshot, rightSnapshotID: rightSnapshot)

        let first = try results.navigate(comparisonID: comparison.id, filter: .differences, from: nil, direction: .next)
        XCTAssertEqual(first.count, 2)
        XCTAssertEqual(first.map(\.resultPath), ["added.bin", "moved.bin"])

        let anchor = first[0]
        let next = try results.navigate(comparisonID: comparison.id, filter: .differences, from: ComparisonResultAnchor(resultPath: anchor.resultPath, id: anchor.id), direction: .next)
        XCTAssertEqual(next.map(\.resultPath), ["moved.bin"])

        let previous = try results.navigate(comparisonID: comparison.id, filter: .differences, from: ComparisonResultAnchor(resultPath: next[0].resultPath, id: next[0].id), direction: .previous)
        XCTAssertEqual(previous.map(\.resultPath), ["added.bin"])

        let atEnd = try results.navigate(comparisonID: comparison.id, filter: .differences, from: ComparisonResultAnchor(resultPath: next[0].resultPath, id: next[0].id), direction: .next)
        XCTAssertTrue(atEnd.isEmpty)
    }

    func testRecentComparisonsListIsDeterministicAndInclusive() throws {
        try seedPair()
        _ = try service.snapshotToSnapshot(leftSnapshotID: leftSnapshot, rightSnapshotID: rightSnapshot)
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: rightSnapshot, rightSnapshotID: leftSnapshot)

        let list = try results.listComparisons()
        XCTAssertEqual(list.count, 2)
        XCTAssertEqual(list[0].id, comparison.id, "newest first")
        XCTAssertEqual(list[1].mode, .snapshotToSnapshot)
    }
}
