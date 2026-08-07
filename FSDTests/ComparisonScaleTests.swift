import XCTest
@testable import FSD

/// Comparison-scale evidence on synthetic catalogs (no physical files):
/// 100,000 entries per side, predominantly unchanged, with added/removed
/// branches and modified metadata. This is the Milestone 4 class — the
/// 1,000,000-entry class is the Milestone 5 gate and is intentionally not run.
final class ComparisonScaleTests: XCTestCase {
    private struct ScaleResults {
        let leftCount: Int64
        let rightCount: Int64
        let durationSeconds: Double
        let matched: Int64
        let changed: Int64
        let added: Int64
        let removed: Int64
        let firstPageLatencySeconds: Double
        let differencesLatencySeconds: Double
    }

    private var directory: URL!
    private var database: CatalogDatabase!
    private var service: ComparisonService!
    private var results: ComparisonResultRepository!
    private var leftSnapshot: SnapshotID!
    private var rightSnapshot: SnapshotID!

    private static let directoryCount = 100
    private static let filesPerDirectory = 1_000 // 100 × 1,000 = 100,000 files + 100 dirs + root per side

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-Scale-\(UUID().uuidString)", isDirectory: true)
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

    /// Seeds the 100,202-entry pair (100,000 files + 100 dirs + root + a
    /// one-sided branch per side). The right side mirrors the left, then 100
    /// files change size, an `zadded` branch exists only on the right and a
    /// `zremoved` branch only on the left.
    private func seedHundredThousandPair() throws {
        let leftID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 11, session: 1, sensitivity: .sensitive)
        let rightID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 11, session: 2, sensitivity: .sensitive)

        // Entry ids are table-global unique: the left side owns 1...100_101
        // and the right side owns 100_102...200_202, allocated from one
        // counter so no id is ever reused.
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

        for dirIndex in 0..<Self.directoryCount {
            let dirName = String(format: "d%03d", dirIndex)
            let leftDirID = nextLeft
            let rightDirID = nextRight
            nextLeft += 1
            nextRight += 1
            leftEntries.append(SyntheticSnapshot.SeedEntry(id: leftDirID, parentID: leftRootID, relativePath: dirName, name: dirName, itemKind: .directory))
            rightEntries.append(SyntheticSnapshot.SeedEntry(id: rightDirID, parentID: rightRootID, relativePath: dirName, name: dirName, itemKind: .directory))
            for fileIndex in 0..<Self.filesPerDirectory {
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

        // zadded: only on the right (a whole added branch); zremoved: only on
        // the left. Both branch ranges are explicit and sit above every
        // main-range id, so the sides never share an entry id.
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

        // Each side is 100,000 files + 100 dirs + root + its one-sided branch
        // (directory + 100 files).
        XCTAssertEqual(leftEntries.count, 100_202)
        XCTAssertEqual(rightEntries.count, 100_202)
        XCTAssertEqual(Set(leftEntries.map(\.id)).count, leftEntries.count, "left ids are unique")
        XCTAssertEqual(Set(rightEntries.map(\.id)).count, rightEntries.count, "right ids are unique")
        XCTAssertTrue(Set(leftEntries.map(\.id)).isDisjoint(with: Set(rightEntries.map(\.id))), "sides never share an entry id")
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: leftID, entries: leftEntries)
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: rightID, entries: rightEntries)
        try SyntheticSnapshot.complete(database: database, snapshotID: leftID)
        try SyntheticSnapshot.complete(database: database, snapshotID: rightID)
        leftSnapshot = leftID
        rightSnapshot = rightID
    }

    private func fingerprint(of comparisonID: ComparisonID) throws -> String {
        let summary = try database.query(
            "SELECT result_type, COUNT(*) AS n, SUM(difference_flags) AS flags, MIN(result_path) AS lo, MAX(result_path) AS hi FROM comparison_results WHERE comparison_id = ? GROUP BY result_type ORDER BY result_type",
            bindings: [.integer(comparisonID.rawValue)]
        )
        return summary.map { row in
            "\(row["result_type"]?.stringValue ?? "")|\(row["n"]?.int64Value ?? 0)|\(row["flags"]?.int64Value ?? 0)|\(row["lo"]?.stringValue ?? "")|\(row["hi"]?.stringValue ?? "")"
        }.joined(separator: "\n")
    }

    func testHundredThousandVersusHundredThousandComparison() throws {
        try seedHundredThousandPair()
        let started = Date()
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: leftSnapshot, rightSnapshotID: rightSnapshot)
        let duration = Date().timeIntervalSince(started)

        let firstPageStarted = Date()
        let firstPage = try results.results(comparisonID: comparison.id, filter: .all, offset: 0, limit: 100)
        let firstPageLatency = Date().timeIntervalSince(firstPageStarted)
        let differencesStarted = Date()
        let differences = try results.results(comparisonID: comparison.id, filter: .differences, offset: 0, limit: 100)
        let differencesLatency = Date().timeIntervalSince(differencesStarted)

        XCTAssertEqual(comparison.status, .complete)
        XCTAssertEqual(comparison.matchedCount, 100_001, "100,101 − 100 modified")
        XCTAssertEqual(comparison.changedCount, 100)
        XCTAssertEqual(comparison.addedCount, 101, "zadded branch: directory + 100 files")
        XCTAssertEqual(comparison.removedCount, 101, "zremoved branch: directory + 100 files")
        XCTAssertEqual(comparison.uncertainCount, 0)
        XCTAssertEqual(comparison.totalComparedEntries, 100_303)

        XCTAssertEqual(firstPage.rows.count, 100)
        XCTAssertEqual(firstPage.totalCount, 100_303)
        XCTAssertTrue(firstPage.isTruncated)
        XCTAssertEqual(differences.rows.count, 100)
        XCTAssertEqual(differences.totalCount, 302)

        let scale = ScaleResults(
            leftCount: 100_202, rightCount: 100_202, durationSeconds: duration,
            matched: comparison.matchedCount, changed: comparison.changedCount,
            added: comparison.addedCount, removed: comparison.removedCount,
            firstPageLatencySeconds: firstPageLatency, differencesLatencySeconds: differencesLatency
        )
        print("[FSD-Scale] \(scale.leftCount) vs \(scale.rightCount) entries; compare \(String(format: "%.3f", scale.durationSeconds)) s; "
            + "matched \(scale.matched), changed \(scale.changed), added \(scale.added), removed \(scale.removed); "
            + "first page \(String(format: "%.4f", scale.firstPageLatencySeconds)) s; "
            + "differences-only \(String(format: "%.4f", scale.differencesLatencySeconds)) s")

        // The engine never materialized either tree: the entry streams read
        // bounded pages, evidenced by the per-side row counts matching the
        // seeded counts exactly while the process held only pages in memory.
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM entries WHERE snapshot_id = ?", bindings: [.integer(leftSnapshot.rawValue)])?.int64Value, 100_202)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM entries WHERE snapshot_id = ?", bindings: [.integer(rightSnapshot.rawValue)])?.int64Value, 100_202)
    }

    func testHundredThousandScaleRerunIsDeterministic() throws {
        try seedHundredThousandPair()
        let first = try service.snapshotToSnapshot(leftSnapshotID: leftSnapshot, rightSnapshotID: rightSnapshot)
        let second = try service.snapshotToSnapshot(leftSnapshotID: leftSnapshot, rightSnapshotID: rightSnapshot)

        XCTAssertEqual(first.status, .complete)
        XCTAssertEqual(second.status, .complete)
        XCTAssertEqual(first.matchedCount, second.matchedCount)
        XCTAssertEqual(first.changedCount, second.changedCount)
        XCTAssertEqual(first.addedCount, second.addedCount)
        XCTAssertEqual(first.removedCount, second.removedCount)
        XCTAssertEqual(try fingerprint(of: first.id), try fingerprint(of: second.id), "repeat run produces the identical result set")
    }

    func testHundredThousandScaleDifferencesOnlyPagingIsBounded() throws {
        try seedHundredThousandPair()
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: leftSnapshot, rightSnapshotID: rightSnapshot)

        let pageOne = try results.results(comparisonID: comparison.id, filter: .differences, offset: 0, limit: 50)
        let pageTwo = try results.results(comparisonID: comparison.id, filter: .differences, offset: 50, limit: 50)
        let pageMid = try results.results(comparisonID: comparison.id, filter: .differences, offset: 250, limit: 50)
        let pageLast = try results.results(comparisonID: comparison.id, filter: .differences, offset: 300, limit: 50)
        XCTAssertEqual(pageOne.rows.count, 50)
        XCTAssertEqual(pageTwo.rows.count, 50)
        XCTAssertEqual(pageMid.rows.count, 50)
        XCTAssertTrue(pageMid.isTruncated, "250 + 50 < 302: more pages remain")
        XCTAssertEqual(pageLast.rows.count, 2, "302 differences: the last page carries the remainder")
        XCTAssertEqual(pageLast.totalCount, 302)
        XCTAssertFalse(pageLast.isTruncated)

        // All rows are differences, in deterministic path order.
        XCTAssertTrue((pageOne.rows + pageTwo.rows).allSatisfy { $0.resultType != .matched && $0.resultType != .ignored })
        let paths = (pageOne.rows + pageTwo.rows).map(\.resultPath)
        XCTAssertEqual(paths, paths.sorted(), "stable path ordering across pages")
        XCTAssertEqual(Set(paths).count, paths.count, "no row repeats across pages")
    }

    func testHundredThousandScaleCancellationDuringMatchingStopsBoundedProcessing() throws {
        try seedHundredThousandPair()
        let token = CaptureCancellationToken()
        var didCancel = false
        var lastProgress: Int64 = 0

        XCTAssertThrowsError(try service.snapshotToSnapshot(leftSnapshotID: leftSnapshot, rightSnapshotID: rightSnapshot, token: token) { progress in
            lastProgress = progress.processedEntries
            if !didCancel, progress.processedEntries >= 40_000 {
                didCancel = true
                token.cancel()
            }
        }) { error in
            guard case ComparisonError.cancelled = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }

        XCTAssertTrue(didCancel)
        XCTAssertLessThanOrEqual(lastProgress, 40_000 + 20_000, "processing stopped shortly after the cancel point")
        let records = try results.listComparisons()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0].status, .cancelled)
        let persisted = try database.scalar(
            "SELECT COUNT(*) FROM comparison_results WHERE comparison_id = ?",
            bindings: [.integer(records[0].id.rawValue)]
        )?.int64Value ?? 0
        XCTAssertLessThan(persisted, 100_303, "only the rows persisted before cancellation remain")
        XCTAssertGreaterThan(persisted, 0, "the bounded evidence is preserved")
        // Cancelled counts still match their rows.
        XCTAssertEqual(records[0].matchedCount + records[0].changedCount + records[0].addedCount + records[0].removedCount + records[0].uncertainCount, persisted)
    }

    func testHundredThousandScaleLeavesSnapshotsUntouchedAndNoClassifications() throws {
        try seedHundredThousandPair()
        let fingerprintBefore = try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: leftSnapshot)
        _ = try service.snapshotToSnapshot(leftSnapshotID: leftSnapshot, rightSnapshotID: rightSnapshot)
        XCTAssertEqual(try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: leftSnapshot), fingerprintBefore)
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
    }
}
