import XCTest
@testable import FSD

/// Milestone 5 Part 2 — the final-scale snapshot catalog gate (CT-005):
/// an isolated synthetic catalog of at least 1,000,000 snapshot entries,
/// opened, browsed, searched and exported with bounded queries and without
/// ever materializing the tree. All timing evidence is printed with the
/// machine/toolchain context recorded in the Handoff; acceptance thresholds
/// apply to Release evidence, Debug runs are correctness evidence.
final class FinalScaleSnapshotTests: XCTestCase {
    private var directory: URL!
    private var database: CatalogDatabase!
    private var result: M5SnapshotCatalog.Result!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-M5-Snapshot-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        database = try CatalogDatabase(
            url: directory.appendingPathComponent("catalog.sqlite3"),
            schemaURL: CatalogSchemaFixture.canonicalSchemaURL
        )
    }

    override func tearDownWithError() throws {
        database?.close()
        database = nil
        result = nil
        try? FileManager.default.removeItem(at: directory)
        directory = nil
    }

    private var catalogURL: URL { directory.appendingPathComponent("catalog.sqlite3") }

    func testMillionEntryCatalogGenerationOpenBrowsingAndSearch() throws {
        // Fixture generation (timed separately from every operation below).
        let generationStart = Date()
        result = try M5SnapshotCatalog.populate(database: database)
        let generationSeconds = Date().timeIntervalSince(generationStart)
        XCTAssertEqual(result.entryCount, M5SnapshotCatalog.expectedEntryCount, "1,002,182 entries")
        XCTAssertGreaterThanOrEqual(result.entryCount, 1_000_000)

        // History first load.
        let historyRepository = SnapshotHistoryRepository(database: database)
        let historyStart = Date()
        let summaries = try historyRepository.listSnapshots()
        let historySeconds = Date().timeIntervalSince(historyStart)
        XCTAssertEqual(summaries.count, 1)
        XCTAssertEqual(summaries[0].totalFiles, 1_001_140)

        // Root first-page load (bounded, 200-row page).
        let tree = SnapshotTreeDataSource(database: database, snapshotID: result.snapshotID, pageSize: 200)
        let openStart = Date()
        let root = try XCTUnwrap(try tree.root())
        let openSeconds = Date().timeIntervalSince(openStart)
        XCTAssertEqual(root.relativePath, "")
        XCTAssertTrue(root.hasChildren)

        tree.resetInstrumentation()
        let rootPageStart = Date()
        let rootPage = try tree.children(ofParent: root.id)
        let rootPageSeconds = Date().timeIntervalSince(rootPageStart)
        XCTAssertEqual(rootPage.count, 200, "first page is bounded by the page size, not by the 1,002 children")
        XCTAssertEqual(tree.rowsFetched, 200)

        // Direct-child page load.
        tree.resetInstrumentation()
        let childPageStart = Date()
        let childPage = try tree.children(ofParent: rootPage[0].id)
        let childPageSeconds = Date().timeIntervalSince(childPageStart)
        XCTAssertEqual(childPage.count, 200, "a 1,000-file directory pages at 200 rows")
        XCTAssertEqual(tree.queryCount, 1)
        XCTAssertEqual(tree.rowsFetched, 200)

        // Deep-path expansion: walk all 40 levels, then page the deepest.
        // deep00 sorts after the 1,000 d-directories, so the walk starts at
        // the root's offset page that holds it.
        let deepStart = Date()
        let deepPage = try tree.children(ofParent: root.id, offset: M5SnapshotCatalog.directoryCount, limit: 200)
        let deep00 = try XCTUnwrap(deepPage.first { $0.itemKind == .directory && $0.name == "deep00" })
        var currentParent = deep00.id
        var expandedDeep: [SnapshotTreeNode] = [deep00]
        while let page = try? tree.children(ofParent: currentParent), let next = page.first(where: { $0.itemKind == .directory }) {
            expandedDeep.append(next)
            currentParent = next.id
        }
        let deepLeafPage = try tree.children(ofParent: currentParent)
        let deepSeconds = Date().timeIntervalSince(deepStart)
        XCTAssertEqual(expandedDeep.count, 40, "all 40 deep levels expand")
        XCTAssertEqual(deepLeafPage.count, 200, "the deepest level's 1,000 files page at 200 rows")

        // Deterministic ordering: root children pages are sorted and unique.
        let pageOne = try tree.children(ofParent: root.id, offset: 0, limit: 200)
        let pageTwo = try tree.children(ofParent: root.id, offset: 200, limit: 200)
        let pageThree = try tree.children(ofParent: root.id, offset: 400, limit: 200)
        let combined = (pageOne + pageTwo + pageThree).map(\.name)
        XCTAssertEqual(combined, combined.sorted(), "stable folded-path ordering across pages")
        XCTAssertEqual(Set(combined).count, combined.count, "no row repeats across pages")

        // Bounded metadata search — first-page latency, truncated result set.
        let search = MetadataSearchService(database: database)
        let searchStart = Date()
        let hits = try search.search(MetadataSearchQuery(text: "f00500", limit: 100), in: result.snapshotID)
        let searchSeconds = Date().timeIntervalSince(searchStart)
        XCTAssertEqual(hits.hits.count, 100)
        XCTAssertTrue(hits.isTruncated, "f00500 exists once per directory: 1,000 matches total")

        // Filter behavior: hidden-only and hidden-excluded searches.
        let hiddenOnly = try search.search(
            MetadataSearchQuery(text: "h000", hidden: .only, limit: 500), in: result.snapshotID
        )
        XCTAssertEqual(hiddenOnly.hits.count, 10)
        XCTAssertTrue(hiddenOnly.hits.allSatisfy { $0.isHidden })
        let hiddenExcluded = try search.search(
            MetadataSearchQuery(text: "h000", hidden: .exclude, limit: 500), in: result.snapshotID
        )
        XCTAssertEqual(hiddenExcluded.hits.count, 0)
        let pathField = try search.search(
            MetadataSearchQuery(text: "zhidden/h0000", field: .path, limit: 100), in: result.snapshotID
        )
        XCTAssertEqual(pathField.hits.count, 1)
        XCTAssertEqual(pathField.hits[0].relativePath, "zhidden/h0000.dat")

        // Totals fetched across the whole exercise stay far below the entry
        // count — the tree was never materialized.
        XCTAssertLessThan(tree.rowsFetched + rootPage.count + childPage.count + deepLeafPage.count + hits.hits.count, 2000)

        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)

        print("""
        [FSD-M5-Scale:snapshot-catalog]
          entries                 : \(result.entryCount)
          fixture generation       : \(String(format: "%.2f", generationSeconds)) s
          history first load       : \(String(format: "%.4f", historySeconds)) s
          open snapshot (1 row)    : \(String(format: "%.4f", openSeconds)) s
          root first page          : \(rootPage.count) rows \(String(format: "%.4f", rootPageSeconds)) s
          direct-child page        : \(childPage.count) rows \(String(format: "%.4f", childPageSeconds)) s
          deep expansion (40 lvls) : \(String(format: "%.4f", deepSeconds)) s
          search first page        : \(hits.hits.count) hits \(String(format: "%.4f", searchSeconds)) s
          rows fetched in exercise : \(tree.rowsFetched)
        """)
    }

    func testMillionEntryCatalogJSONExportOffline() throws {
        result = try M5SnapshotCatalog.populate(database: database)
        let exporter = JSONSnapshotExporter(database: database, pageSize: 1000)
        let exportURL = directory.appendingPathComponent("export.json")

        let started = Date()
        let summary = try exporter.export(snapshotID: result.snapshotID, to: exportURL)
        let duration = Date().timeIntervalSince(started)
        let size = try FileManager.default.attributesOfItem(atPath: exportURL.path)[.size] as? Int64 ?? -1

        XCTAssertEqual(summary.entryCount, result.entryCount)
        XCTAssertEqual(summary.issueCount, 0)
        XCTAssertGreaterThan(size, 100_000_000, "a million metadata entries export to a substantial document")

        // Deterministic: a second export has the same size and the same head.
        let secondURL = directory.appendingPathComponent("export2.json")
        let secondSummary = try exporter.export(snapshotID: result.snapshotID, to: secondURL)
        let secondSize = try FileManager.default.attributesOfItem(atPath: secondURL.path)[.size] as? Int64 ?? -1
        XCTAssertEqual(secondSummary.entryCount, summary.entryCount)
        XCTAssertEqual(secondSize, size)
        let head = try Data(contentsOf: exportURL).prefix(512)
        let secondHead = try Data(contentsOf: secondURL).prefix(512)
        XCTAssertEqual(head, secondHead)

        print("[FSD-M5-Scale:export] entries \(summary.entryCount); duration \(String(format: "%.2f", duration)) s; output \(size) bytes")
    }

    func testMillionEntryCatalogReopenIntegrityAndForeignKeys() throws {
        result = try M5SnapshotCatalog.populate(database: database)

        // Catalog reopen: close the connection and reopen the same file.
        database.close()
        let reopenStart = Date()
        database = try CatalogDatabase(
            url: catalogURL,
            schemaURL: CatalogSchemaFixture.canonicalSchemaURL
        )
        let reopenSeconds = Date().timeIntervalSince(reopenStart)

        XCTAssertEqual(try database.scalar("SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1")?.int64Value, 8)
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)

        let history = try SnapshotHistoryRepository(database: database).listSnapshots()
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history[0].status, .complete)
        let tree = SnapshotTreeDataSource(database: database, snapshotID: result.snapshotID, pageSize: 200)
        let root = try XCTUnwrap(try tree.root())
        XCTAssertEqual(try tree.children(ofParent: root.id).count, 200)

        print("[FSD-M5-Scale:reopen] reopen \(String(format: "%.3f", reopenSeconds)) s; schema version 8; integrity ok; fk clean; classification rows 0")
    }
}
