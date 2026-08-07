import XCTest
@testable import FSD

/// Entry identity and matching semantics (ADR-009, ADR-010, ADR-011):
/// case sensitivity selection, case-fold collisions, Unicode normalization,
/// unknown sensitivity, and normalization-version incompatibility.
final class ComparisonIdentityTests: XCTestCase {
    private var directory: URL!
    private var database: CatalogDatabase!
    private var service: ComparisonService!
    private var results: ComparisonResultRepository!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-Identity-\(UUID().uuidString)", isDirectory: true)
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

    private func makeSnapshot(
        _ id: Int64,
        sensitivity: SourceCaseSensitivity,
        paths: [(path: String, size: Int64?)],
        normalizationVersion: NormalizationVersion = .current
    ) throws -> SnapshotID {
        let snapshotID = try SyntheticSnapshot.createSnapshot(
            database: database, volumeID: 7, session: id,
            sensitivity: sensitivity, name: "Root",
            normalizationVersion: normalizationVersion
        )
        // Each side owns a distinct id range: root `id*100`, entries after it.
        let rootID = id * 100
        let entries: [SyntheticSnapshot.SeedEntry] = [SyntheticSnapshot.root(id: rootID, name: "Root")] + paths.enumerated().map { index, item in
            SyntheticSnapshot.SeedEntry(
                id: rootID + Int64(index + 1), parentID: rootID,
                relativePath: item.path, name: item.path, logicalSizeBytes: item.size
            )
        }
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: snapshotID, entries: entries)
        try SyntheticSnapshot.complete(database: database, snapshotID: snapshotID)
        return snapshotID
    }

    private func allRows(_ comparison: ComparisonRecord) throws -> [ComparisonResultRow] {
        try results.results(comparisonID: comparison.id, filter: .all, limit: 1000).rows
    }

    // MARK: - Case sensitivity

    func testCaseSensitiveSourcesPreserveCaseDistinctEntries() throws {
        let left = try makeSnapshot(1, sensitivity: .sensitive, paths: [
            ("Report.txt", 1), ("report.txt", 2)
        ])
        let right = try makeSnapshot(2, sensitivity: .sensitive, paths: [
            ("Report.txt", 1)
        ])
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: left, rightSnapshotID: right)

        XCTAssertEqual(comparison.matchedCount, 2, "root + Report.txt")
        XCTAssertEqual(comparison.removedCount, 1, "report.txt has no counterpart on the sensitive right side")
        XCTAssertEqual(comparison.warnings, [])
        let rows = try allRows(comparison)
        XCTAssertTrue(rows.contains { $0.resultType == .removed && $0.resultPath == "report.txt" })
        XCTAssertTrue(rows.contains { $0.resultType == .matched && $0.resultPath == "Report.txt" })
    }

    func testCaseInsensitiveSideMatchesAcrossCase() throws {
        let left = try makeSnapshot(1, sensitivity: .insensitive, paths: [("Report.txt", 1)])
        let right = try makeSnapshot(2, sensitivity: .sensitive, paths: [("report.txt", 1)])
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: left, rightSnapshotID: right)

        XCTAssertEqual(comparison.matchedCount, 2, "root + folded match of Report.txt/report.txt")
        XCTAssertEqual(comparison.addedCount, 0)
        XCTAssertEqual(comparison.removedCount, 0)
        let match = try allRows(comparison).first { $0.resultPath == "Report.txt" }
        XCTAssertEqual(match?.resultType, .matched)
        XCTAssertNotNil(match?.leftEntryID)
        XCTAssertNotNil(match?.rightEntryID)
    }

    func testCaseFoldCollisionIsNeverPairedArbitrarily() throws {
        // On the left, two entries fold to the same key ("a.txt" and
        // "A.txt"); the right has one. ADR-010: no arbitrary pairing — the
        // whole key becomes a collision group with an uncertain outcome.
        let left = try makeSnapshot(1, sensitivity: .sensitive, paths: [
            ("a.txt", 1), ("A.txt", 2)
        ])
        let right = try makeSnapshot(2, sensitivity: .insensitive, paths: [("a.txt", 1)])
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: left, rightSnapshotID: right)

        XCTAssertEqual(comparison.uncertainCount, 1)
        XCTAssertEqual(comparison.matchedCount, 1, "only the root entries match")
        XCTAssertEqual(comparison.addedCount, 0)
        XCTAssertEqual(comparison.removedCount, 0)

        let uncertain = try allRows(comparison).first { $0.resultType == .uncertain }
        XCTAssertEqual(uncertain?.resultPath, "a.txt", "the group path is the folded key")
        XCTAssertNil(uncertain?.leftEntryID, "collision members are never paired as a result")
        XCTAssertNil(uncertain?.rightEntryID)

        // The members are all retained in the collision tables.
        let groupCount = try database.scalar(
            "SELECT COUNT(*) FROM comparison_collision_groups WHERE comparison_id = ?",
            bindings: [.integer(comparison.id.rawValue)]
        )?.int64Value
        XCTAssertEqual(groupCount, 1)
        let memberCount = try database.scalar(
            "SELECT COUNT(*) FROM comparison_collision_members m JOIN comparison_collision_groups g ON m.group_id = g.id WHERE g.comparison_id = ?",
            bindings: [.integer(comparison.id.rawValue)]
        )?.int64Value
        XCTAssertEqual(memberCount, 3, "both left members and the right member are recorded")
    }

    func testCollisionWithinOneSideOnSensitiveSources() throws {
        // Two raw names that normalize to the same NFC string collide even
        // under the case-preserving key: the pair cannot be decided safely.
        let composed = "Café"
        let decomposed = composed.decomposedStringWithCanonicalMapping
        XCTAssertNotEqual(Array(composed.unicodeScalars), Array(decomposed.unicodeScalars))

        let left = try makeSnapshot(1, sensitivity: .sensitive, paths: [
            (composed, 1), (decomposed, 2)
        ])
        let right = try makeSnapshot(2, sensitivity: .sensitive, paths: [(composed, 1)])
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: left, rightSnapshotID: right)

        XCTAssertEqual(comparison.uncertainCount, 1)
        XCTAssertEqual(comparison.matchedCount, 1)
    }

    func testNFCEquivalentPathsMatchAcrossNormalizationForms() throws {
        let composed = "Café"
        let decomposed = composed.decomposedStringWithCanonicalMapping

        let left = try makeSnapshot(1, sensitivity: .sensitive, paths: [(composed, 7)])
        let right = try makeSnapshot(2, sensitivity: .sensitive, paths: [(decomposed, 7)])
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: left, rightSnapshotID: right)

        XCTAssertEqual(comparison.matchedCount, 2, "stored NFC keys make the forms equal (ADR-009)")
        XCTAssertEqual(comparison.addedCount, 0)
        XCTAssertEqual(comparison.removedCount, 0)
    }

    func testUnknownCaseSensitivityUsesFoldedKeyWithExplicitWarning() throws {
        let left = try makeSnapshot(1, sensitivity: .unknown, paths: [("Photo.CR2", 1)])
        let right = try makeSnapshot(2, sensitivity: .sensitive, paths: [("photo.cr2", 1)])
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: left, rightSnapshotID: right)

        XCTAssertEqual(comparison.matchedCount, 2, "unknown folds to the safe key (ADR-010)")
        XCTAssertEqual(comparison.warnings.count, 1)
        XCTAssertTrue(comparison.warnings[0].contains("case sensitivity is unknown"))
    }

    func testUnknownSensitivityWarningSurvivesReloadFromTheCatalog() throws {
        let left = try makeSnapshot(1, sensitivity: .unknown, paths: [("Photo.CR2", 1)])
        let right = try makeSnapshot(2, sensitivity: .sensitive, paths: [("photo.cr2", 1)])
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: left, rightSnapshotID: right)

        let reloaded = try results.record(id: comparison.id)
        XCTAssertEqual(reloaded?.warnings, comparison.warnings)
        XCTAssertEqual(reloaded?.mode, .snapshotToSnapshot)
    }

    // MARK: - Normalization version

    func testNormalizationVersionMismatchIsBlockedByTheEnforcementChain() throws {
        let left = try makeSnapshot(1, sensitivity: .sensitive, paths: [("a.txt", 1)])
        // A snapshot with another normalization version can never complete:
        // the completion guard rejects it (ADR-009's allowlist admits only
        // the supported identity), so a mismatched pair cannot even be
        // created. The engine carries a typed `normalizationMismatch` check
        // and the schema trigger re-checks equality on comparison insert, as
        // defense in depth for a future allowlist expansion.
        let mismatched = try SyntheticSnapshot.createSnapshot(
            database: database, volumeID: 7, session: 99, sensitivity: .sensitive,
            normalizationVersion: NormalizationVersion(rawValue: "fsd-algo-v2")
        )
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: mismatched, entries: [
            SyntheticSnapshot.root(id: 9900, name: "Root"),
            SyntheticSnapshot.SeedEntry(id: 9901, parentID: 9900, relativePath: "a.txt", name: "a.txt", logicalSizeBytes: 1)
        ])
        XCTAssertThrowsError(try SyntheticSnapshot.complete(database: database, snapshotID: mismatched)) { error in
            guard case SnapshotRepositoryError.unsupportedNormalizationVersion("fsd-algo-v2") = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        // The engine therefore reports the mismatched snapshot as ineligible
        // and leaves no comparison residue.
        XCTAssertThrowsError(try service.snapshotToSnapshot(leftSnapshotID: left, rightSnapshotID: mismatched)) { error in
            guard case ComparisonError.ineligibleSnapshot = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertEqual(try results.count(), 0)
    }

    // MARK: - Duplicate identity is impossible by schema

    func testExactDuplicateRelativePathIsRejectedByTheCatalog() throws {
        let snapshotID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 7, session: 99)
        let root = SyntheticSnapshot.root(name: "Root")
        let duplicate = SyntheticSnapshot.SeedEntry(id: 2, parentID: 1, relativePath: "dup.txt", name: "dup.txt")
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: snapshotID, entries: [root, duplicate])
        XCTAssertThrowsError(
            try SyntheticSnapshot.insertEntries(
                database: database, snapshotID: snapshotID,
                entries: [SyntheticSnapshot.SeedEntry(id: 3, parentID: 1, relativePath: "dup.txt", name: "dup.txt")]
            )
        )
    }
}
