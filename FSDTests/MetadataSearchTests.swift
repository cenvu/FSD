import XCTest
@testable import FSD

final class MetadataSearchTests: XCTestCase {
    private var directory: URL!
    private var source: URL!
    private var database: CatalogDatabase!
    private var snapshotID: SnapshotID!
    private var search: MetadataSearchService!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-Search-\(UUID().uuidString)", isDirectory: true)
        source = directory.appendingPathComponent("source", isDirectory: true)
        try FileManager.default.createDirectory(at: source.appendingPathComponent("Photos/RAW"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: source.appendingPathComponent("Docs"), withIntermediateDirectories: true)
        database = try CatalogDatabase(
            url: directory.appendingPathComponent("catalog.sqlite3"),
            schemaURL: CatalogSchemaFixture.canonicalSchemaURL
        )

        try Data("0123456789".utf8).write(to: source.appendingPathComponent("Photos/RAW/A001C002.ARW"))
        try Data("0123456789abcdef".utf8).write(to: source.appendingPathComponent("Photos/RAW/A001C003.arw"))
        try Data("x".utf8).write(to: source.appendingPathComponent("Photos/Cover.JPG"))
        try Data("y".utf8).write(to: source.appendingPathComponent("Docs/Café Notes.txt"))
        try Data("z".utf8).write(to: source.appendingPathComponent("Docs/report_final.txt"))
        try Data("w".utf8).write(to: source.appendingPathComponent("Docs/report2final.txt"))
        try Data().write(to: source.appendingPathComponent(".hidden-marker"))

        let record = try SnapshotScanner(database: database).capture(root: source)
        snapshotID = record.id
        search = MetadataSearchService(database: database)
    }

    override func tearDownWithError() throws {
        search = nil
        database?.close()
        database = nil
        try? FileManager.default.removeItem(at: directory)
        directory = nil
        source = nil
        snapshotID = nil
    }

    func testResultsIdentifyTheSnapshotAndAreDeterministic() throws {
        let first = try search.search(MetadataSearchQuery(text: "report"), in: snapshotID)
        let second = try search.search(MetadataSearchQuery(text: "report"), in: snapshotID)

        XCTAssertEqual(first.snapshotID, snapshotID)
        XCTAssertEqual(first.hits.map(\.id), second.hits.map(\.id))
        XCTAssertEqual(first.hits.map(\.relativePath), ["Docs/report2final.txt", "Docs/report_final.txt"])
        XCTAssertFalse(first.isTruncated)
    }

    func testNameAndPathFieldsAreDistinct() throws {
        let byName = try search.search(MetadataSearchQuery(text: "RAW", field: .name), in: snapshotID)
        let byPath = try search.search(MetadataSearchQuery(text: "RAW", field: .path), in: snapshotID)

        XCTAssertEqual(byName.hits.map(\.name), ["RAW"])
        XCTAssertEqual(
            byPath.hits.map(\.relativePath),
            ["Photos/RAW", "Photos/RAW/A001C002.ARW", "Photos/RAW/A001C003.arw"]
        )
    }

    func testSearchIsCaseInsensitiveThroughTheStoredFoldedKeys() throws {
        for needle in ["a001c002", "A001C002", "a001C002"] {
            let results = try search.search(MetadataSearchQuery(text: needle, field: .name), in: snapshotID)
            XCTAssertEqual(results.hits.map(\.name), ["A001C002.ARW"], "needle: \(needle)")
        }
    }

    func testUnicodeNeedleMatchesRegardlessOfNormalizationForm() throws {
        let composed = "Café"
        let decomposed = composed.decomposedStringWithCanonicalMapping
        XCTAssertNotEqual(Array(composed.unicodeScalars), Array(decomposed.unicodeScalars))

        for needle in [composed, decomposed, "café", "CAFÉ"] {
            let results = try search.search(MetadataSearchQuery(text: needle, field: .name), in: snapshotID)
            XCTAssertEqual(results.hits.map(\.name), ["Café Notes.txt"], "needle: \(needle.debugDescription)")
        }
    }

    func testExtensionFilterIgnoresCaseAndLeadingDot() throws {
        for value in ["arw", "ARW", ".arw"] {
            let results = try search.search(MetadataSearchQuery(fileExtension: value), in: snapshotID)
            XCTAssertEqual(results.hits.map(\.name).sorted(), ["A001C002.ARW", "A001C003.arw"], "value: \(value)")
        }
    }

    func testItemKindFilterSelectsDirectoriesOnly() throws {
        let results = try search.search(MetadataSearchQuery(itemKinds: [.directory]), in: snapshotID)
        XCTAssertEqual(results.hits.map(\.name).sorted(), ["Docs", "Photos", "RAW", "source"])
        XCTAssertTrue(results.hits.allSatisfy { $0.itemKind == .directory })
    }

    func testHiddenFilters() throws {
        let onlyHidden = try search.search(MetadataSearchQuery(hidden: .only), in: snapshotID)
        XCTAssertEqual(onlyHidden.hits.map(\.name), [".hidden-marker"])

        let excluded = try search.search(MetadataSearchQuery(hidden: .exclude), in: snapshotID)
        XCTAssertFalse(excluded.hits.contains { $0.name == ".hidden-marker" })
    }

    func testSizeRangeFiltering() throws {
        let large = try search.search(
            MetadataSearchQuery(itemKinds: [.file], minimumLogicalSizeBytes: 10), in: snapshotID
        )
        XCTAssertEqual(large.hits.map(\.name).sorted(), ["A001C002.ARW", "A001C003.arw"])

        let narrow = try search.search(
            MetadataSearchQuery(itemKinds: [.file], minimumLogicalSizeBytes: 10, maximumLogicalSizeBytes: 10),
            in: snapshotID
        )
        XCTAssertEqual(narrow.hits.map(\.name), ["A001C002.ARW"])
    }

    func testWildcardCharactersAreTreatedLiterally() throws {
        let underscore = try search.search(MetadataSearchQuery(text: "report_final", field: .name), in: snapshotID)
        XCTAssertEqual(underscore.hits.map(\.name), ["report_final.txt"], "an underscore must not match any character")

        let percent = try search.search(MetadataSearchQuery(text: "%", field: .name), in: snapshotID)
        XCTAssertTrue(percent.hits.isEmpty, "a percent sign must not match everything")

        XCTAssertEqual(MetadataSearchService.escapeLikePattern("a_b%c\\d"), "a\\_b\\%c\\\\d")
    }

    func testResultsAreBoundedAndTruncationIsReported() throws {
        let results = try search.search(MetadataSearchQuery(text: "", itemKinds: [.file], limit: 2), in: snapshotID)
        XCTAssertEqual(results.hits.count, 2)
        XCTAssertTrue(results.isTruncated)
        XCTAssertEqual(results.limit, 2)

        let capped = try search.search(MetadataSearchQuery(itemKinds: [.file], limit: 10_000_000), in: snapshotID)
        XCTAssertLessThanOrEqual(capped.limit, MetadataSearchService.maximumLimit)
    }

    func testSearchNeverTouchesPayloadsOrClassificationRows() throws {
        try FileManager.default.removeItem(at: source)

        let results = try search.search(MetadataSearchQuery(text: "a001"), in: snapshotID)

        XCTAssertEqual(results.hits.count, 2, "search answers from the catalog with the source gone")
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM entry_classifications")?.int64Value, 0)
        XCTAssertTrue(results.hits.allSatisfy { !$0.hasScanIssue })
    }

    func testInaccessibleAndIssueStateIsSurfaced() throws {
        let repository = SnapshotRepository(database: database)
        try repository.createVolume(id: 90, displayName: "Issues")
        let snapshot = try repository.createSnapshot(volumeID: 90, sessionNumber: 1, scanRootName: "Issues")
        let rootID = try repository.addRoot(to: snapshot, name: "Issues")
        try database.execute(
            """
            INSERT INTO entries (
                snapshot_id, parent_id, relative_path, case_preserving_path, case_folded_path,
                name, case_preserving_name, case_folded_name, item_type, is_inaccessible, sort_key, created_at
            ) VALUES (?, ?, 'locked.bin', 'locked.bin', 'locked.bin', 'locked.bin', 'locked.bin', 'locked.bin',
                      'file', 1, 'locked.bin', CURRENT_TIMESTAMP)
            """,
            bindings: [.integer(snapshot.rawValue), .integer(rootID.rawValue)]
        )
        let entryID = try XCTUnwrap(try database.scalar(
            "SELECT id FROM entries WHERE snapshot_id = ? AND relative_path = 'locked.bin'",
            bindings: [.integer(snapshot.rawValue)]
        )?.int64Value)
        try database.execute(
            """
            INSERT INTO scan_issues (snapshot_id, entry_id, relative_path, severity, source, message, was_skipped, created_at)
            VALUES (?, ?, 'locked.bin', 'warning', 'scanner', 'Permission denied', 1, CURRENT_TIMESTAMP)
            """,
            bindings: [.integer(snapshot.rawValue), .integer(entryID)]
        )

        let results = try search.search(MetadataSearchQuery(inaccessibleOnly: true), in: snapshot)
        XCTAssertEqual(results.hits.map(\.name), ["locked.bin"])
        XCTAssertTrue(results.hits[0].isInaccessible)
        XCTAssertTrue(results.hits[0].hasScanIssue)
    }
}
