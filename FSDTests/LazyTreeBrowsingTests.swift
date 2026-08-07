import XCTest
@testable import FSD

/// Builds a large catalog without creating a large source tree.
///
/// The point of the exercise is to prove the browser never loads a snapshot
/// eagerly, and that is a property of the queries, not of the filesystem. Writing
/// 100,000 real files would test the scanner instead and take minutes.
enum SyntheticCatalog {
    struct Result {
        let snapshotID: SnapshotID
        let entryCount: Int64
        let directoryCount: Int
        let filesPerDirectory: Int
        let insertSeconds: Double
    }

    static func populate(
        database: CatalogDatabase,
        directoryCount: Int,
        filesPerDirectory: Int,
        batchSize: Int = 500
    ) throws -> Result {
        let started = Date()
        let repository = SnapshotRepository(database: database)
        try repository.createVolume(id: 4242, displayName: "Synthetic Volume")
        let snapshotID = try repository.createSnapshot(
            volumeID: 4242, sessionNumber: 1, scanRootName: "Synthetic", displayName: "Synthetic capture"
        )
        _ = try repository.addRoot(to: snapshotID, name: "Synthetic")
        let rootID = try XCTUnwrapValue(
            database.scalar(
                "SELECT id FROM entries WHERE snapshot_id = ? AND parent_id IS NULL",
                bindings: [.integer(snapshotID.rawValue)]
            )?.int64Value
        )

        // Directory names are zero-padded so folded-path ordering and numeric
        // ordering agree, which keeps the ordering assertions readable.
        let directories = (0..<directoryCount).map { String(format: "dir-%04d", $0) }
        try insert(
            database: database, snapshotID: snapshotID, parentID: rootID,
            rows: directories.map { (path: $0, name: $0, kind: "directory") },
            batchSize: batchSize
        )

        let directoryRows = try database.query(
            "SELECT id, relative_path FROM entries WHERE snapshot_id = ? AND parent_id = ? ORDER BY sort_key",
            bindings: [.integer(snapshotID.rawValue), .integer(rootID)]
        )
        for row in directoryRows {
            guard let parentID = row["id"]?.int64Value, let prefix = row["relative_path"]?.stringValue else { continue }
            let files = (0..<filesPerDirectory).map { index -> (path: String, name: String, kind: String) in
                let name = String(format: "file-%04d.dat", index)
                return ("\(prefix)/\(name)", name, "file")
            }
            try insert(
                database: database, snapshotID: snapshotID, parentID: parentID,
                rows: files, batchSize: batchSize
            )
        }

        let entryCount = database.scalarInt(
            "SELECT COUNT(*) FROM entries WHERE snapshot_id = ?", bindings: [.integer(snapshotID.rawValue)]
        )
        try database.execute(
            """
            UPDATE snapshots SET total_files = ?, total_folders = ?, total_logical_bytes = 0
            WHERE id = ?
            """,
            bindings: [
                .integer(Int64(directoryCount * filesPerDirectory)),
                .integer(Int64(directoryCount + 1)),
                .integer(snapshotID.rawValue)
            ]
        )
        try repository.complete(snapshotID)

        return Result(
            snapshotID: snapshotID,
            entryCount: entryCount,
            directoryCount: directoryCount,
            filesPerDirectory: filesPerDirectory,
            insertSeconds: Date().timeIntervalSince(started)
        )
    }

    private static func insert(
        database: CatalogDatabase,
        snapshotID: SnapshotID,
        parentID: Int64,
        rows: [(path: String, name: String, kind: String)],
        batchSize: Int
    ) throws {
        var index = 0
        while index < rows.count {
            let batch = Array(rows[index..<min(index + batchSize, rows.count)])
            index += batch.count
            let placeholders = batch
                .map { _ in "(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)" }
                .joined(separator: ", ")
            var bindings: [DatabaseValue] = []
            bindings.reserveCapacity(batch.count * 10)
            for row in batch {
                let folded = PathIdentity.caseFold(row.path)
                bindings.append(contentsOf: [
                    .integer(snapshotID.rawValue), .integer(parentID), .text(row.path),
                    .text(PathIdentity.casePreserving(row.path)), .text(folded),
                    .text(row.name), .text(PathIdentity.casePreserving(row.name)),
                    .text(PathIdentity.caseFold(row.name)), .text(row.kind), .text(folded)
                ])
            }
            try database.transaction {
                try database.execute(
                    """
                    INSERT INTO entries (
                        snapshot_id, parent_id, relative_path, case_preserving_path, case_folded_path,
                        name, case_preserving_name, case_folded_name, item_type, sort_key, created_at
                    ) VALUES \(placeholders)
                    """,
                    bindings: bindings
                )
            }
        }
    }

    private static func XCTUnwrapValue<T>(_ value: T?) throws -> T {
        guard let value else { throw NSError(domain: "SyntheticCatalog", code: 1) }
        return value
    }
}

extension CatalogDatabase {
    func scalarInt(_ sql: String, bindings: [DatabaseValue] = []) -> Int64 {
        (try? scalar(sql, bindings: bindings))??.int64Value ?? -1
    }
}

final class LazyTreeBrowsingTests: XCTestCase {
    private var directory: URL!
    private var database: CatalogDatabase!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-Tree-\(UUID().uuidString)", isDirectory: true)
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

    func testChildQueryReturnsOnlyImmediateChildren() throws {
        let result = try SyntheticCatalog.populate(database: database, directoryCount: 3, filesPerDirectory: 4)
        let tree = SnapshotTreeDataSource(database: database, snapshotID: result.snapshotID)

        let root = try XCTUnwrap(try tree.root())
        XCTAssertEqual(root.relativePath, "")
        XCTAssertTrue(root.hasChildren)

        let level1 = try tree.children(ofParent: root.id)
        XCTAssertEqual(level1.count, 3)
        XCTAssertTrue(level1.allSatisfy { $0.itemKind == .directory })
        XCTAssertTrue(level1.allSatisfy { $0.hasChildren })

        let level2 = try tree.children(ofParent: level1[0].id)
        XCTAssertEqual(level2.count, 4)
        XCTAssertTrue(level2.allSatisfy { $0.itemKind == .file })
        XCTAssertTrue(level2.allSatisfy { !$0.hasChildren })
        XCTAssertTrue(level2.allSatisfy { $0.relativePath.hasPrefix("dir-0000/") })
    }

    func testExpandingOneDirectoryDoesNotFetchDescendants() throws {
        let result = try SyntheticCatalog.populate(database: database, directoryCount: 5, filesPerDirectory: 20)
        let tree = SnapshotTreeDataSource(database: database, snapshotID: result.snapshotID)

        let root = try XCTUnwrap(try tree.root())
        tree.resetInstrumentation()
        let level1 = try tree.children(ofParent: root.id)
        XCTAssertEqual(tree.rowsFetched, 5, "opening the root must read five directory rows, not the tree")

        tree.resetInstrumentation()
        _ = try tree.children(ofParent: level1[0].id)
        XCTAssertEqual(tree.queryCount, 1)
        XCTAssertEqual(tree.rowsFetched, 20, "expanding one directory must read only its own children")
        XCTAssertEqual(result.entryCount, 106)
    }

    func testSiblingOrderingIsDeterministicAndPagesWithoutGaps() throws {
        let result = try SyntheticCatalog.populate(database: database, directoryCount: 1, filesPerDirectory: 25)
        let tree = SnapshotTreeDataSource(database: database, snapshotID: result.snapshotID, pageSize: 10)
        let root = try XCTUnwrap(try tree.root())
        let parent = try XCTUnwrap(try tree.children(ofParent: root.id).first)

        let full = try (0..<3).flatMap { page in
            try tree.children(ofParent: parent.id, offset: page * 10, limit: 10)
        }
        XCTAssertEqual(full.count, 25)
        XCTAssertEqual(Set(full.map(\.id)).count, 25, "paging must not repeat or drop a sibling")
        XCTAssertEqual(full.map(\.name), full.map(\.name).sorted())

        let repeated = try (0..<3).flatMap { page in
            try tree.children(ofParent: parent.id, offset: page * 10, limit: 10)
        }
        XCTAssertEqual(full.map(\.id), repeated.map(\.id))
    }

    func testChildrenAreBoundedByPageSize() throws {
        let result = try SyntheticCatalog.populate(database: database, directoryCount: 1, filesPerDirectory: 40)
        let tree = SnapshotTreeDataSource(database: database, snapshotID: result.snapshotID, pageSize: 12)
        let root = try XCTUnwrap(try tree.root())
        let parent = try XCTUnwrap(try tree.children(ofParent: root.id).first)

        XCTAssertEqual(try tree.children(ofParent: parent.id).count, 12)
        XCTAssertEqual(try tree.children(ofParent: parent.id, limit: 10_000).count, 12, "a caller cannot raise the ceiling")
        XCTAssertEqual(try tree.childCount(ofParent: parent.id), 40)
    }

    func testPartialSnapshotIsMarkedInHistoryAndStillBrowsable() throws {
        let repository = SnapshotRepository(database: database)
        try repository.createVolume(id: 7, displayName: "Partial")
        let snapshot = try repository.createSnapshot(volumeID: 7, sessionNumber: 1, scanRootName: "Partial")
        _ = try repository.addRoot(to: snapshot, name: "Partial")
        try repository.interrupt(snapshot)

        let summary = try XCTUnwrap(try SnapshotHistoryRepository(database: database).summary(id: snapshot))
        XCTAssertTrue(summary.isPartialCapture)
        XCTAssertEqual(
            summary.partialStateWarning,
            "This capture was interrupted. The stored tree is partial and does not describe the whole source."
        )
        XCTAssertNotNil(try SnapshotTreeDataSource(database: database, snapshotID: snapshot).root())
    }

    // MARK: - Part 13: large catalog

    /// 100,001 entries, browsed with the instrumentation on, so the numbers in
    /// the Handoff are measurements rather than claims.
    func testLargeCatalogOpensAndExpandsWithoutEagerLoading() throws {
        let result = try SyntheticCatalog.populate(database: database, directoryCount: 100, filesPerDirectory: 1000)
        XCTAssertEqual(result.entryCount, 100_101)

        let history = SnapshotHistoryRepository(database: database)
        let historyStart = Date()
        let summaries = try history.listSnapshots()
        let historySeconds = Date().timeIntervalSince(historyStart)
        XCTAssertEqual(summaries.count, 1)
        XCTAssertEqual(summaries[0].totalFiles, 100_000)

        let tree = SnapshotTreeDataSource(database: database, snapshotID: result.snapshotID, pageSize: 200)

        // Opening the snapshot.
        tree.resetInstrumentation()
        let openStart = Date()
        let root = try XCTUnwrap(try tree.root())
        let openSeconds = Date().timeIntervalSince(openStart)
        let openQueries = tree.queryCount
        let openRows = tree.rowsFetched
        XCTAssertEqual(openQueries, 1)
        XCTAssertEqual(openRows, 1, "opening a 100k snapshot must read exactly the root row")

        // First page of the root's children.
        tree.resetInstrumentation()
        let firstPageStart = Date()
        let firstPage = try tree.children(ofParent: root.id)
        let firstPageSeconds = Date().timeIntervalSince(firstPageStart)
        XCTAssertEqual(firstPage.count, 100)
        XCTAssertEqual(tree.rowsFetched, 100)

        // Expanding exactly one directory.
        tree.resetInstrumentation()
        let expandStart = Date()
        let expanded = try tree.children(ofParent: firstPage[0].id)
        let expandSeconds = Date().timeIntervalSince(expandStart)
        let expandRows = tree.rowsFetched
        XCTAssertEqual(expanded.count, 200, "bounded by the page size, not by the 1,000 children present")
        XCTAssertEqual(tree.queryCount, 1)

        // Search stays bounded.
        let search = MetadataSearchService(database: database)
        let searchResults = try search.search(
            MetadataSearchQuery(text: "file-0500", limit: 100), in: result.snapshotID
        )
        XCTAssertEqual(searchResults.hits.count, 100)
        XCTAssertTrue(searchResults.isTruncated)
        XCTAssertLessThan(searchResults.durationSeconds, 10.0)

        // Nothing above accumulated the tree: the totals fetched over the whole
        // exercise are three orders of magnitude below the entry count.
        XCTAssertLessThan(openRows + firstPage.count + expandRows + searchResults.hits.count, 1000)

        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)

        print("""
        [M3 large-catalog measurements]
          generated entries          : \(result.entryCount)
          synthetic insert seconds   : \(String(format: "%.2f", result.insertSeconds))
          history list seconds       : \(String(format: "%.4f", historySeconds))
          open snapshot queries      : \(openQueries)
          open snapshot rows fetched : \(openRows) (\(String(format: "%.4f", openSeconds)) s)
          first display page rows    : \(firstPage.count) (\(String(format: "%.4f", firstPageSeconds)) s)
          one expansion rows fetched : \(expandRows) (\(String(format: "%.4f", expandSeconds)) s)
          search hits / seconds      : \(searchResults.hits.count) / \(String(format: "%.4f", searchResults.durationSeconds))
          catalog file bytes         : \(catalogFileSize())
        """)
    }

    private func catalogFileSize() -> Int64 {
        let url = directory.appendingPathComponent("catalog.sqlite3")
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return (attributes?[.size] as? NSNumber)?.int64Value ?? -1
    }
}
