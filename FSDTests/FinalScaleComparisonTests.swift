import XCTest
@testable import FSD

/// Milestone 5 Part 3 — the final-scale comparison gate: two synthetic
/// snapshots of ~1,003,xxx entries each, compared through the production
/// engine with deterministic composition (predominantly matched, modified,
/// added and removed branches, inaccessible/uncertain, case-fold collision
/// groups, ignored service files). All timing evidence is printed with the
/// machine/toolchain context recorded in the Handoff; Release evidence is the
/// acceptance basis, Debug runs are correctness evidence.
final class FinalScaleComparisonTests: XCTestCase {
    private static let oneMillionResultCount: Int64 = 1_000_000

    private var directory: URL!
    private var database: CatalogDatabase!
    private var service: ComparisonService!
    private var results: ComparisonResultRepository!
    private var pair: M5ComparisonPair.Result!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-M5-Compare-\(UUID().uuidString)", isDirectory: true)
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
        pair = nil
        try? FileManager.default.removeItem(at: directory)
        directory = nil
    }

    private func seedPair() throws {
        pair = try M5ComparisonPair.populate(database: database)
        XCTAssertEqual(pair.leftCount, 1_003_104)
        XCTAssertEqual(pair.rightCount, 1_003_205)
    }

    private func fingerprint(of comparisonID: ComparisonID) throws -> String {
        let rows = try database.query(
            """
            SELECT result_type, COUNT(*) AS n, SUM(difference_flags) AS flags,
                   MIN(result_path) AS lo, MAX(result_path) AS hi
            FROM comparison_results WHERE comparison_id = ? GROUP BY result_type ORDER BY result_type
            """,
            bindings: [.integer(comparisonID.rawValue)]
        )
        return rows.map { row in
            "\(row["result_type"]?.stringValue ?? "")|\(row["n"]?.int64Value ?? 0)|\(row["flags"]?.int64Value ?? 0)|\(row["lo"]?.stringValue ?? "")|\(row["hi"]?.stringValue ?? "")"
        }.joined(separator: "\n")
    }

    func testMillionEntryComparisonCompletesWithExactClassification() throws {
        try seedPair()

        let compareStart = Date()
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: pair.leftID, rightSnapshotID: pair.rightID)
        let compareSeconds = Date().timeIntervalSince(compareStart)

        XCTAssertEqual(comparison.status, .complete)
        XCTAssertEqual(comparison.matchedCount, pair.expectedMatched)
        XCTAssertEqual(comparison.changedCount, pair.expectedChanged)
        XCTAssertEqual(comparison.addedCount, pair.expectedAdded)
        XCTAssertEqual(comparison.removedCount, pair.expectedRemoved)
        XCTAssertEqual(comparison.uncertainCount, pair.expectedUncertain)
        // The record's compared total is the persisted outcome count;
        // ignored rows are recorded evidence but outside the compared
        // universe, exactly as the Milestone 4 scale record's 100,303 was.
        XCTAssertEqual(
            comparison.totalComparedEntries,
            pair.expectedMatched + pair.expectedChanged + pair.expectedAdded + pair.expectedRemoved + pair.expectedUncertain
        )

        // First result page.
        let firstPageStart = Date()
        let firstPage = try results.results(comparisonID: comparison.id, filter: .all, offset: 0, limit: 100)
        let firstPageSeconds = Date().timeIntervalSince(firstPageStart)
        XCTAssertEqual(firstPage.rows.count, 100)
        XCTAssertEqual(firstPage.totalCount, pair.expectedTotal)
        XCTAssertTrue(firstPage.isTruncated)

        // Differences-only page.
        let differencesStart = Date()
        let differences = try results.results(comparisonID: comparison.id, filter: .differences, offset: 0, limit: 100)
        let differencesSeconds = Date().timeIntervalSince(differencesStart)
        XCTAssertEqual(differences.rows.count, 100)
        XCTAssertEqual(differences.totalCount, pair.expectedChanged + pair.expectedAdded + pair.expectedRemoved + pair.expectedUncertain)
        XCTAssertTrue(differences.rows.allSatisfy { $0.resultType != .matched && $0.resultType != .ignored })

        // Per-outcome filters.
        let added = try results.results(comparisonID: comparison.id, filter: .added, offset: 0, limit: 2000)
        let removed = try results.results(comparisonID: comparison.id, filter: .removed, offset: 0, limit: 2000)
        let modified = try results.results(comparisonID: comparison.id, filter: .modified, offset: 0, limit: 2000)
        let unchanged = try results.results(comparisonID: comparison.id, filter: .unchanged, offset: 0, limit: 2000)
        let conflicts = try results.results(comparisonID: comparison.id, filter: .conflicts, offset: 0, limit: 2000)
        let ignored = try results.results(comparisonID: comparison.id, filter: .ignored, offset: 0, limit: 2000)
        XCTAssertEqual(added.totalCount, pair.expectedAdded)
        XCTAssertEqual(removed.totalCount, pair.expectedRemoved)
        XCTAssertEqual(modified.totalCount, pair.expectedChanged)
        XCTAssertEqual(unchanged.totalCount, pair.expectedMatched)
        XCTAssertEqual(conflicts.totalCount, pair.expectedUncertain)
        XCTAssertEqual(ignored.totalCount, pair.expectedIgnored)

        // Collision evidence is retained and never paired.
        let groupCount = try database.scalar(
            "SELECT COUNT(*) FROM comparison_collision_groups WHERE comparison_id = ?",
            bindings: [.integer(comparison.id.rawValue)]
        )?.int64Value ?? -1
        let memberCount = try database.scalar(
            "SELECT COUNT(*) FROM comparison_collision_members WHERE group_id IN (SELECT id FROM comparison_collision_groups WHERE comparison_id = ?)",
            bindings: [.integer(comparison.id.rawValue)]
        )?.int64Value ?? -1
        XCTAssertEqual(groupCount, pair.expectedCollisionGroups)
        XCTAssertEqual(memberCount, pair.expectedCollisionMembers)

        // Bounded paging at every page of a large filter.
        var walked: Int64 = 0
        var offset = 0
        while true {
            let page = try results.results(comparisonID: comparison.id, filter: .differences, offset: offset, limit: 500)
            XCTAssertLessThanOrEqual(page.rows.count, 500)
            walked += Int64(page.rows.count)
            if !page.isTruncated { break }
            offset += 500
        }
        XCTAssertEqual(walked, pair.expectedChanged + pair.expectedAdded + pair.expectedRemoved + pair.expectedUncertain)

        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)

        print("""
        [FSD-M5-Scale:comparison]
          left entries             : \(pair.leftCount)
          right entries            : \(pair.rightCount)
          persisted results        : \(pair.expectedTotal)
          matched / changed        : \(pair.expectedMatched) / \(pair.expectedChanged)
          added / removed          : \(pair.expectedAdded) / \(pair.expectedRemoved)
          uncertain / ignored      : \(pair.expectedUncertain) / \(pair.expectedIgnored)
          collision groups/members : \(groupCount) / \(memberCount)
          compare duration         : \(String(format: "%.3f", compareSeconds)) s
          first-page latency       : \(String(format: "%.4f", firstPageSeconds)) s
          differences latency      : \(String(format: "%.4f", differencesSeconds)) s
        """)
    }

    func testMillionEntryRepeatRunIsDeterministic() throws {
        try seedPair()
        let first = try service.snapshotToSnapshot(leftSnapshotID: pair.leftID, rightSnapshotID: pair.rightID)
        let firstFingerprint = try fingerprint(of: first.id)
        let second = try service.snapshotToSnapshot(leftSnapshotID: pair.leftID, rightSnapshotID: pair.rightID)

        XCTAssertEqual(first.status, .complete)
        XCTAssertEqual(second.status, .complete)
        XCTAssertEqual(first.matchedCount, second.matchedCount)
        XCTAssertEqual(first.changedCount, second.changedCount)
        XCTAssertEqual(first.addedCount, second.addedCount)
        XCTAssertEqual(first.removedCount, second.removedCount)
        XCTAssertEqual(first.uncertainCount, second.uncertainCount)
        XCTAssertEqual(try fingerprint(of: second.id), firstFingerprint, "repeat run produces the identical result set")
        print("[FSD-M5-Scale:comparison] repeat run deterministic; result fingerprint identical")
    }

    func testMillionEntryDifferencesNavigationAcrossPageBoundaries() throws {
        try seedPair()
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: pair.leftID, rightSnapshotID: pair.rightID)
        let navigationStart = Date()
        let differenceCount = Int(pair.expectedChanged + pair.expectedAdded + pair.expectedRemoved + pair.expectedUncertain)

        // Walk the whole differences set with next/previous navigation in
        // bounded steps; every row must appear exactly once.
        var walkedForward: [ComparisonResultRow] = []
        var anchor: ComparisonResultAnchor? = nil
        while true {
            let page = try results.navigate(comparisonID: comparison.id, filter: .differences, from: anchor, direction: .next, limit: 200)
            if page.isEmpty { break }
            walkedForward.append(contentsOf: page)
            anchor = ComparisonResultAnchor(resultPath: page.last!.resultPath, id: page.last!.id)
            if walkedForward.count >= differenceCount { break }
        }
        XCTAssertEqual(walkedForward.count, differenceCount)
        XCTAssertEqual(Set(walkedForward.map(\.id)).count, differenceCount, "next/previous navigation never repeats a row")

        // Previous navigation from the end reaches the same set in reverse.
        // The anchor row itself is the starting point of the reverse walk
        // (navigation is strictly-before / strictly-after the anchor).
        let lastRow = walkedForward.last!
        let lastAnchor = ComparisonResultAnchor(resultPath: lastRow.resultPath, id: lastRow.id)
        var walkedBackward: [ComparisonResultRow] = [lastRow]
        var backAnchor: ComparisonResultAnchor? = lastAnchor
        while true {
            let page = try results.navigate(comparisonID: comparison.id, filter: .differences, from: backAnchor, direction: .previous, limit: 200)
            if page.isEmpty { break }
            walkedBackward.insert(contentsOf: page, at: 0)
            backAnchor = ComparisonResultAnchor(resultPath: page.first!.resultPath, id: page.first!.id)
            if walkedBackward.count >= differenceCount { break }
        }
        XCTAssertEqual(walkedBackward, walkedForward, "previous navigation traverses the same deterministic order")

        let navigationSeconds = Date().timeIntervalSince(navigationStart)
        print("[FSD-M5-Scale:comparison] differences \(differenceCount); navigation walk \(String(format: "%.3f", navigationSeconds)) s")
    }

    func testMillionEntryCancellationDuringMatchingStopsBoundedProcessing() throws {
        try seedPair()
        let token = CaptureCancellationToken()
        var didCancel = false
        var lastProgress: Int64 = 0

        XCTAssertThrowsError(try service.snapshotToSnapshot(
            leftSnapshotID: pair.leftID,
            rightSnapshotID: pair.rightID,
            token: token
        ) { progress in
            lastProgress = progress.processedEntries
            if !didCancel, progress.processedEntries >= 500_000 {
                didCancel = true
                token.cancel()
            }
        }) { error in
            guard case ComparisonError.cancelled = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }

        XCTAssertTrue(didCancel)
        XCTAssertLessThanOrEqual(lastProgress, 500_000 + 20_000, "processing stopped shortly after the cancel point")
        let records = try results.listComparisons()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0].status, .cancelled, "exactly one terminal state, and it is cancelled — never complete")
        let persisted = try database.scalar(
            "SELECT COUNT(*) FROM comparison_results WHERE comparison_id = ?",
            bindings: [.integer(records[0].id.rawValue)]
        )?.int64Value ?? 0
        XCTAssertLessThan(persisted, pair.expectedTotal, "only the bounded evidence persisted before cancellation remains")
        XCTAssertGreaterThan(persisted, 0)
        XCTAssertEqual(
            records[0].matchedCount + records[0].changedCount + records[0].addedCount + records[0].removedCount + records[0].uncertainCount,
            persisted,
            "a cancelled comparison's summary always matches its retained evidence"
        )
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
        print("[FSD-M5-Scale:comparison] cancellation at \(lastProgress) processed; \(persisted) rows retained; status cancelled")
    }

    func testMillionEntryResultReopen() throws {
        try seedPair()
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: pair.leftID, rightSnapshotID: pair.rightID)

        // Result reopen: close and reopen the catalog, then read results again.
        database.close()
        database = try CatalogDatabase(
            url: directory.appendingPathComponent("catalog.sqlite3"),
            schemaURL: CatalogSchemaFixture.canonicalSchemaURL
        )
        results = ComparisonResultRepository(database: database)
        let reopened = try XCTUnwrap(try results.record(id: comparison.id))
        XCTAssertEqual(reopened.status, .complete)
        XCTAssertEqual(reopened.matchedCount, pair.expectedMatched)
        let page = try results.results(comparisonID: comparison.id, filter: .all, offset: 0, limit: 100)
        XCTAssertEqual(page.totalCount, pair.expectedTotal)
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
        print("[FSD-M5-Scale:comparison] 1M result reopen ok; record and paging readable after relaunch")
    }

    /// Whole-comparison disposal at the class where it completes in a
    /// reasonable time (100,202 entries per side — the Milestone 4 scale
    /// class). At the 1,000,000-entry class the same cascade is O(n²): the
    /// self-referential `comparison_results.parent_result_id` FK has no
    /// dedicated leading index, so every cascade-deleted row scans the table
    /// (KI-024 — measured in progress at >45 minutes; a schema fix would
    /// require version 8, out of scope for this milestone). Correctness is
    /// identical at any size: zero residue, immutable snapshots, clean
    /// integrity and foreign keys.
    func testHundredThousandDisposalLeavesNoResidue() throws {
        // A 100,202-per-side pair with the M4 shape: 100 dirs × 1,000 files,
        // 100 modified, one added and one removed branch.
        let leftID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 15, session: 1, sensitivity: .sensitive)
        let rightID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 15, session: 2, sensitivity: .sensitive)
        var nextLeft: Int64 = 1
        var nextRight: Int64 = 100_102
        var leftEntries: [SyntheticSnapshot.SeedEntry] = []
        var rightEntries: [SyntheticSnapshot.SeedEntry] = []
        let leftRootID = nextLeft
        let rightRootID = nextRight
        leftEntries.append(SyntheticSnapshot.root(id: leftRootID, name: "Root"))
        rightEntries.append(SyntheticSnapshot.root(id: rightRootID, name: "Root"))
        nextLeft += 1
        nextRight += 1
        for dirIndex in 0..<100 {
            let dirName = String(format: "d%03d", dirIndex)
            let leftDirID = nextLeft
            let rightDirID = nextRight
            nextLeft += 1
            nextRight += 1
            leftEntries.append(SyntheticSnapshot.SeedEntry(id: leftDirID, parentID: leftRootID, relativePath: dirName, name: dirName, itemKind: .directory))
            rightEntries.append(SyntheticSnapshot.SeedEntry(id: rightDirID, parentID: rightRootID, relativePath: dirName, name: dirName, itemKind: .directory))
            for fileIndex in 0..<1_000 {
                let fileName = String(format: "f%05d.bin", fileIndex)
                let filePath = "\(dirName)/\(fileName)"
                let leftSize = syntheticSize(dirIndex, fileIndex)
                let rightSize = (dirIndex == 0 && fileIndex < 100) ? leftSize + 1 : leftSize
                leftEntries.append(SyntheticSnapshot.SeedEntry(id: nextLeft, parentID: leftDirID, relativePath: filePath, name: fileName, logicalSizeBytes: leftSize))
                rightEntries.append(SyntheticSnapshot.SeedEntry(id: nextRight, parentID: rightDirID, relativePath: filePath, name: fileName, logicalSizeBytes: rightSize))
                nextLeft += 1
                nextRight += 1
            }
        }
        let zaddedDirID: Int64 = 500_102
        rightEntries.append(SyntheticSnapshot.SeedEntry(id: zaddedDirID, parentID: rightRootID, relativePath: "zadded", name: "zadded", itemKind: .directory))
        for fileIndex in 0..<100 {
            let fileName = String(format: "f%05d.bin", fileIndex)
            rightEntries.append(SyntheticSnapshot.SeedEntry(id: 500_103 + Int64(fileIndex), parentID: zaddedDirID, relativePath: "zadded/\(fileName)", name: fileName, logicalSizeBytes: syntheticSize(99, fileIndex)))
        }
        let zremovedDirID: Int64 = 500_000
        leftEntries.append(SyntheticSnapshot.SeedEntry(id: zremovedDirID, parentID: leftRootID, relativePath: "zremoved", name: "zremoved", itemKind: .directory))
        for fileIndex in 0..<100 {
            let fileName = String(format: "f%05d.bin", fileIndex)
            leftEntries.append(SyntheticSnapshot.SeedEntry(id: 500_001 + Int64(fileIndex), parentID: zremovedDirID, relativePath: "zremoved/\(fileName)", name: fileName, logicalSizeBytes: syntheticSize(98, fileIndex)))
        }
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: leftID, entries: leftEntries)
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: rightID, entries: rightEntries)
        try SyntheticSnapshot.complete(database: database, snapshotID: leftID)
        try SyntheticSnapshot.complete(database: database, snapshotID: rightID)

        let pairFingerprint = try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: leftID)
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: leftID, rightSnapshotID: rightID)
        XCTAssertEqual(comparison.status, .complete)

        let disposalStart = Date()
        try results.deleteComparison(comparison.id)
        let disposalSeconds = Date().timeIntervalSince(disposalStart)
        XCTAssertNil(try results.record(id: comparison.id))
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM comparison_results WHERE comparison_id = ?", bindings: [.integer(comparison.id.rawValue)])?.int64Value ?? 0, 0)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM comparison_collision_groups WHERE comparison_id = ?", bindings: [.integer(comparison.id.rawValue)])?.int64Value ?? 0, 0)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM comparison_collision_members WHERE group_id IN (SELECT id FROM comparison_collision_groups WHERE comparison_id = ?)", bindings: [.integer(comparison.id.rawValue)])?.int64Value ?? 0, 0)
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
        XCTAssertEqual(
            try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: leftID),
            pairFingerprint,
            "comparison and disposal never mutate snapshot entries"
        )
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
        print("[FSD-M5-Scale:comparison] disposal (100,202/side) \(String(format: "%.3f", disposalSeconds)) s; residue 0; integrity ok; fk clean")
    }

    /// Direct synthetic SQLite metadata insertion for the canonical one-million
    /// result class. No physical source files are created. The comparison owns
    /// ordinary snapshots, entries, one collision group/member pair, and one
    /// million result rows so disposal exercises every relevant FK cascade.
    private func seedMillionResultDisposalFixture(
        comparisonID: Int64,
        leftKind: SnapshotKind,
        rightKind: SnapshotKind
    ) throws -> (left: SnapshotID, right: SnapshotID, leftRoot: Int64, rightRoot: Int64, leftCollision: Int64, rightCollision: Int64) {
        let left = try SyntheticSnapshot.createSnapshot(
            database: database, volumeID: 81, session: comparisonID * 2, sensitivity: .sensitive, kind: leftKind
        )
        let right = try SyntheticSnapshot.createSnapshot(
            database: database, volumeID: 81, session: comparisonID * 2 + 1, sensitivity: .sensitive, kind: rightKind
        )
        let leftRootSeed = comparisonID * 100
        let rightRootSeed = leftRootSeed + 1
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: left, entries: [SyntheticSnapshot.root(id: leftRootSeed, name: "Left")])
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: right, entries: [SyntheticSnapshot.root(id: rightRootSeed, name: "Right")])
        let leftRoot = try XCTUnwrap(try database.scalar(
            "SELECT id FROM entries WHERE snapshot_id = ? AND parent_id IS NULL",
            bindings: [.integer(left.rawValue)]
        )?.int64Value)
        let rightRoot = try XCTUnwrap(try database.scalar(
            "SELECT id FROM entries WHERE snapshot_id = ? AND parent_id IS NULL",
            bindings: [.integer(right.rawValue)]
        )?.int64Value)
        let leftCollision = leftRoot + 10_000_000
        let rightCollision = rightRoot + 10_000_000
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: left, entries: [
            SyntheticSnapshot.SeedEntry(id: leftCollision, parentID: leftRoot, relativePath: "collision-left", name: "collision-left")
        ])
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: right, entries: [
            SyntheticSnapshot.SeedEntry(id: rightCollision, parentID: rightRoot, relativePath: "collision-right", name: "collision-right")
        ])
        try SyntheticSnapshot.complete(database: database, snapshotID: left)
        try SyntheticSnapshot.complete(database: database, snapshotID: right)

        try database.execute(
            """
            INSERT INTO comparisons (id, left_snapshot_id, right_snapshot_id, profile_id, profile_version,
                                     status, started_at, created_at)
            VALUES (?, ?, ?, 1, 1, 'running', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            """,
            bindings: [.integer(comparisonID), .integer(left.rawValue), .integer(right.rawValue)]
        )
        try database.execute(
            "INSERT INTO comparison_collision_groups (id, comparison_id, result_path, created_at) VALUES (?, ?, '/collision', CURRENT_TIMESTAMP)",
            bindings: [.integer(comparisonID), .integer(comparisonID)]
        )
        try database.execute(
            "INSERT INTO comparison_collision_members (id, group_id, side, entry_id, created_at) VALUES (?, ?, 'left', ?, CURRENT_TIMESTAMP), (?, ?, 'right', ?, CURRENT_TIMESTAMP)",
            bindings: [
                .integer(comparisonID * 10 + 1), .integer(comparisonID), .integer(leftCollision),
                .integer(comparisonID * 10 + 2), .integer(comparisonID), .integer(rightCollision)
            ]
        )

        // All rows use the ordinary root entries; the collision members are
        // separate entries so the collision-pair guard remains exercised.
        try database.execute(
            """
            WITH RECURSIVE sequence(n) AS (
                SELECT 1
                UNION ALL
                SELECT n + 1 FROM sequence WHERE n < \(Self.oneMillionResultCount)
            )
            INSERT INTO comparison_results (
                comparison_id, parent_result_id, result_path, display_name,
                result_type, left_entry_id, right_entry_id, created_at
            )
            SELECT ?, NULL, printf('/result-%07d', n), printf('result-%07d', n),
                   'matched', ?, ?, CURRENT_TIMESTAMP
            FROM sequence
            """,
            bindings: [.integer(comparisonID), .integer(leftRoot), .integer(rightRoot)]
        )
        return (left, right, leftRoot, rightRoot, leftCollision, rightCollision)
    }

    private func assertReleaseThreshold(_ seconds: Double, label: String) {
        #if DEBUG
        print("[FSD-M5-SchemaV8][Debug-correctness-only] \(label): \(String(format: "%.3f", seconds)) s")
        #else
        XCTAssertLessThan(seconds, 120, "Release \(label) must complete under 120 seconds")
        #endif
    }

    func testOneMillionExplicitDisposalCompletesWithCleanCascade() throws {
        let fixture = try seedMillionResultDisposalFixture(comparisonID: 8_001, leftKind: .user, rightKind: .user)
        try database.execute(
            "UPDATE comparisons SET status = 'complete', matched_count = ?, completed_at = CURRENT_TIMESTAMP WHERE id = ?",
            bindings: [.integer(Self.oneMillionResultCount), .integer(8_001)]
        )
        let leftFingerprint = try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: fixture.left)
        let rightFingerprint = try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: fixture.right)
        let databaseAttributesBefore = try FileManager.default.attributesOfItem(atPath: database.url.path)
        let databaseBytesBefore = (databaseAttributesBefore[.size] as? NSNumber)?.int64Value ?? -1

        let start = Date()
        try results.deleteComparison(ComparisonID(rawValue: 8_001))
        let seconds = Date().timeIntervalSince(start)
        assertReleaseThreshold(seconds, label: "explicit one-million disposal")

        XCTAssertNil(try results.record(id: ComparisonID(rawValue: 8_001)))
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM comparison_results WHERE comparison_id = 8001")?.int64Value, 0)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM comparison_collision_groups WHERE comparison_id = 8001")?.int64Value, 0)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM comparison_collision_members WHERE id IN (80011, 80012)")?.int64Value, 0)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM snapshots WHERE id IN (?, ?)", bindings: [.integer(fixture.left.rawValue), .integer(fixture.right.rawValue)])?.int64Value, 2)
        XCTAssertEqual(try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: fixture.left), leftFingerprint)
        XCTAssertEqual(try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: fixture.right), rightFingerprint)
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
        let databaseAttributesAfter = try FileManager.default.attributesOfItem(atPath: database.url.path)
        let databaseBytesAfter = (databaseAttributesAfter[.size] as? NSNumber)?.int64Value ?? -1
        print("[FSD-M5-SchemaV8] explicit disposal rows=\(Self.oneMillionResultCount), db_bytes=\(databaseBytesBefore)->\(databaseBytesAfter), duration=\(String(format: "%.3f", seconds)) s, residue=0, integrity=ok, foreign_keys=clean")
    }

    func testOneMillionAutomaticLiveWorkspaceCloseCompletesAndReleasesTransient() throws {
        let fixture = try seedMillionResultDisposalFixture(comparisonID: 8_002, leftKind: .transient, rightKind: .user)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM snapshots WHERE snapshot_kind = 'user'")?.int64Value, 1)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM snapshots WHERE snapshot_kind = 'transient'")?.int64Value, 1)
        let start = Date()
        try service.closeWorkspace()
        let seconds = Date().timeIntervalSince(start)
        assertReleaseThreshold(seconds, label: "automatic live workspace close")

        XCTAssertEqual(try results.listComparisons().count, 0)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM comparison_results WHERE comparison_id = 8002")?.int64Value, 0)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM comparison_collision_groups WHERE comparison_id = 8002")?.int64Value, 0)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM snapshots WHERE snapshot_kind = 'transient'")?.int64Value, 0)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM snapshots WHERE id = ?", bindings: [.integer(fixture.right.rawValue)])?.int64Value, 1)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM entries WHERE snapshot_id = ?", bindings: [.integer(fixture.right.rawValue)])?.int64Value, 2)
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
        let writeStart = Date()
        try database.transaction {
            try database.execute(
                "INSERT INTO collections (id, name, normalized_name, created_at, updated_at) VALUES (88002, 'post-close', 'post-close', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
            )
            try database.execute("DELETE FROM collections WHERE id = 88002")
        }
        let writeSeconds = Date().timeIntervalSince(writeStart)
        XCTAssertLessThan(writeSeconds, 5, "a subsequent small write must succeed promptly")
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
        print("[FSD-M5-SchemaV8] workspace close rows=\(Self.oneMillionResultCount), duration=\(String(format: "%.3f", seconds)) s, post_write=\(String(format: "%.3f", writeSeconds)) s, transient=0, user_snapshots=1, integrity=ok, foreign_keys=clean")
    }
}
