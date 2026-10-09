import AppKit
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
        volumeID: Int64 = 4242,
        sessionNumber: Int64 = 1,
        batchSize: Int = 500
    ) throws -> Result {
        let started = Date()
        let repository = SnapshotRepository(database: database)
        try repository.createVolume(id: volumeID, displayName: "Synthetic Volume")
        let snapshotID = try repository.createSnapshot(
            volumeID: volumeID, sessionNumber: sessionNumber,
            scanRootName: "Synthetic", displayName: "Synthetic capture"
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
    private var coordinatorScrollView: NSScrollView?

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
        coordinatorScrollView = nil
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

    func testAppKitCoordinatorReachesEveryRequiredSiblingBoundaryOnceInRepositoryOrder() throws {
        let boundaries = [0, 1, 499, 500, 501, 1_000, 1_001, 1_500]

        for (index, siblingCount) in boundaries.enumerated() {
            let result = try SyntheticCatalog.populate(
                database: database,
                directoryCount: 1,
                filesPerDirectory: siblingCount,
                volumeID: Int64(45_000 + index),
                sessionNumber: 1
            )
            let tree = SnapshotTreeDataSource(database: database, snapshotID: result.snapshotID)
            let root = try XCTUnwrap(try tree.root())
            var selections: [Int64?] = []
            var rootExpansionCallbackSequence: [String] = []
            let (coordinator, outline, rootItem) = try coordinatorFixture(
                dataSource: tree,
                root: root,
                onSelect: { selections.append($0) },
                childCountLoader: { parentID in
                    if parentID == root.id {
                        rootExpansionCallbackSequence.append(
                            "numberOfChildrenOfItem(root) -> childRows(root) -> loadPage(root).childCount"
                        )
                    }
                    return try tree.childCount(ofParent: parentID)
                }
            )
            XCTAssertEqual(outline.tableColumns.map { $0.identifier.rawValue }, ["name", "kind", "size"])
            XCTAssertEqual(outline.outlineTableColumn?.identifier.rawValue, "name")
            XCTAssertTrue(outline.dataSource === coordinator)
            XCTAssertTrue(outline.delegate === coordinator)
            XCTAssertTrue(coordinator.outlineView === outline)
            XCTAssertTrue(coordinatorScrollView?.documentView === outline)
            XCTAssertTrue(outline.isItemExpanded(rootItem), "setRoot must finish AppKit root expansion")
            XCTAssertEqual(rootExpansionCallbackSequence, [
                "numberOfChildrenOfItem(root) -> childRows(root) -> loadPage(root).childCount"
            ])
            print("APPKIT_ROOT_EXPANSION_CALLBACK_SEQUENCE=setRoot -> NSOutlineView.expandItem(root) -> \(rootExpansionCallbackSequence.joined(separator: " -> "))")

            let folder = try XCTUnwrap(appKitRows(of: rootItem, outline: outline).compactMap { $0 as? SnapshotTreeItem }.first)
            tree.resetInstrumentation()
            outline.expandItem(folder)
            XCTAssertTrue(outline.isItemExpanded(folder), "the folder page must load through AppKit expansion callbacks")

            var traversedIDs: [Int64] = []
            var firstPageIDs: [Int64] = []
            var lastPageIDs: [Int64] = []
            var visitedPages = 0
            while true {
                let rows = appKitRows(of: folder, outline: outline)
                let entries = rows.compactMap { $0 as? SnapshotTreeItem }
                let control = try XCTUnwrap(rows.compactMap { $0 as? SnapshotTreePageControlItem }.first)
                XCTAssertLessThanOrEqual(entries.count, 500, "each AppKit page must stay within the repository bound")
                let pageIDs = entries.map { $0.node.id }
                if visitedPages == 0 { firstPageIDs = pageIDs }
                lastPageIDs = pageIDs
                traversedIDs.append(contentsOf: pageIDs)
                visitedPages += 1

                let message = controlMessage(control, coordinator: coordinator, outline: outline)
                if siblingCount == 0 {
                    XCTAssertEqual(message, "Empty folder · 0 entries")
                }

                if let next = controlButton("Next", for: control, coordinator: coordinator, outline: outline) {
                    XCTAssertLessThan(visitedPages, max(1, (siblingCount + 499) / 500))
                    next.performClick(nil)
                } else {
                    XCTAssertTrue(message.contains("Last page") || siblingCount == 0)
                    break
                }
            }

            let firstPageRange = firstPageIDs.isEmpty ? "empty" : "\(firstPageIDs[0])...\(firstPageIDs[firstPageIDs.count - 1])"
            let lastPageRange = lastPageIDs.isEmpty ? "empty" : "\(lastPageIDs[0])...\(lastPageIDs[lastPageIDs.count - 1])"
            print("APPKIT_PAGING_BOUNDARY siblings=\(siblingCount) pages=\(visitedPages) firstPageCount=\(firstPageIDs.count) firstPageIDs=\(firstPageRange) lastPageCount=\(lastPageIDs.count) lastPageIDs=\(lastPageRange)")

            let expectedIDs = try database.query(
                "SELECT id FROM entries WHERE snapshot_id = ? AND parent_id = ? ORDER BY sort_key, id",
                bindings: [.integer(result.snapshotID.rawValue), .integer(folder.node.id)]
            ).compactMap { $0["id"]?.int64Value }
            XCTAssertEqual(expectedIDs.count, siblingCount)
            XCTAssertEqual(traversedIDs, expectedIDs, "paging must preserve repository order at boundary count \(siblingCount)")
            XCTAssertEqual(Set(traversedIDs).count, traversedIDs.count, "a page traversal must not repeat an entry")
            XCTAssertEqual(tree.rowsFetched, siblingCount, "only the direct sibling pages should be read")
            XCTAssertLessThanOrEqual(coordinator.retainedEntryItemCount, coordinator.maximumRetainedEntryItems)
            XCTAssertLessThanOrEqual(coordinator.retainedOutlineItemCount, coordinator.maximumRetainedOutlineItems)
        }
    }

    func testCoordinatorShowsQueryErrorAndRetriesTheSameFolderWithoutReopening() throws {
        let result = try SyntheticCatalog.populate(
            database: database, directoryCount: 1, filesPerDirectory: 1, volumeID: 45_100
        )
        let tree = SnapshotTreeDataSource(database: database, snapshotID: result.snapshotID)
        let root = try XCTUnwrap(try tree.root())
        let expectedFolderID = try XCTUnwrap(try tree.children(ofParent: root.id).first?.id)
        var shouldFail = true
        var selections: [Int64?] = []
        let (coordinator, outline, rootItem) = try coordinatorFixture(
            dataSource: tree,
            root: root,
            onSelect: { selections.append($0) },
            childCountLoader: { parentID in
                if parentID == expectedFolderID && shouldFail {
                    shouldFail = false
                    throw CatalogDatabaseError.sqlite(1, "synthetic transient read error")
                }
                return try tree.childCount(ofParent: parentID)
            }
        )
        let folder = try XCTUnwrap(callbackChild(0, of: rootItem, coordinator: coordinator, outline: outline) as? SnapshotTreeItem)
        let failedRows = callbackRows(of: folder, coordinator: coordinator, outline: outline)
        XCTAssertEqual(failedRows.compactMap { $0 as? SnapshotTreeItem }.count, 0)
        let failedControl = try XCTUnwrap(failedRows.compactMap { $0 as? SnapshotTreePageControlItem }.first)
        XCTAssertTrue(controlMessage(failedControl, coordinator: coordinator, outline: outline).contains("Couldn't load this folder"))
        XCTAssertNotNil(controlButton("Retry", for: failedControl, coordinator: coordinator, outline: outline))
        XCTAssertFalse(coordinator.outlineView(outline, shouldSelectItem: failedControl))
        selections.removeAll()

        try clickButton("Retry", for: failedControl, coordinator: coordinator, outline: outline)
        let recoveredRows = callbackRows(of: folder, coordinator: coordinator, outline: outline)
        XCTAssertEqual(recoveredRows.compactMap { $0 as? SnapshotTreeItem }.map { $0.node.name }, ["file-0000.dat"])
        let recoveredControl = try XCTUnwrap(recoveredRows.compactMap { $0 as? SnapshotTreePageControlItem }.first)
        XCTAssertTrue(controlMessage(recoveredControl, coordinator: coordinator, outline: outline).contains("Last page"))
        XCTAssertTrue(selections.isEmpty, "retry controls must not select a fabricated entry ID")
        XCTAssertEqual(try tree.childCount(ofParent: folder.node.id), 1)
    }

    func testCoordinatorPreservesCurrentPageOnFailedNextAndKeepsSelectionSemantics() throws {
        let result = try SyntheticCatalog.populate(
            database: database, directoryCount: 1, filesPerDirectory: 501, volumeID: 45_101
        )
        let tree = SnapshotTreeDataSource(database: database, snapshotID: result.snapshotID)
        let root = try XCTUnwrap(try tree.root())
        let expectedFolderID = try XCTUnwrap(try tree.children(ofParent: root.id).first?.id)
        var shouldFail = true
        var selections: [Int64?] = []
        let (coordinator, outline, rootItem) = try coordinatorFixture(
            dataSource: tree,
            root: root,
            onSelect: { selections.append($0) },
            pageLoader: { parentID, offset, limit in
                if parentID == expectedFolderID && offset == 500 && shouldFail {
                    shouldFail = false
                    throw CatalogDatabaseError.sqlite(1, "synthetic transient page error")
                }
                return try tree.children(ofParent: parentID, offset: offset, limit: limit)
            }
        )
        let folder = try XCTUnwrap(callbackChild(0, of: rootItem, coordinator: coordinator, outline: outline) as? SnapshotTreeItem)
        outline.expandItem(folder)
        let firstRows = callbackRows(of: folder, coordinator: coordinator, outline: outline)
        let firstPage = firstRows.compactMap { $0 as? SnapshotTreeItem }
        XCTAssertEqual(firstPage.count, 500)
        let selectedID = firstPage[0].node.id
        try select(firstPage[0], coordinator: coordinator, outline: outline)
        XCTAssertEqual(selections.last!, Optional(selectedID))
        let retainedSelectionEvents = selections

        let firstControl = try XCTUnwrap(firstRows.compactMap { $0 as? SnapshotTreePageControlItem }.first)
        try clickButton("Next", for: firstControl, coordinator: coordinator, outline: outline)
        let failedRows = callbackRows(of: folder, coordinator: coordinator, outline: outline)
        XCTAssertEqual(failedRows.compactMap { $0 as? SnapshotTreeItem }.map { $0.node.id }, firstPage.map { $0.node.id })
        XCTAssertEqual(selections, retainedSelectionEvents, "a failed page change must preserve the selected metadata")
        let errorControl = try XCTUnwrap(failedRows.compactMap { $0 as? SnapshotTreePageControlItem }.first)
        XCTAssertTrue(controlMessage(errorControl, coordinator: coordinator, outline: outline).contains("Couldn't load entries 501–501 of 501"))
        XCTAssertTrue(controlMessage(errorControl, coordinator: coordinator, outline: outline).contains("Showing 1–500 of 501 remains available"))

        try clickButton("Retry", for: errorControl, coordinator: coordinator, outline: outline)
        let lastRows = callbackRows(of: folder, coordinator: coordinator, outline: outline)
        XCTAssertEqual(lastRows.compactMap { $0 as? SnapshotTreeItem }.map { $0.node.name }, ["file-0500.dat"])
        XCTAssertEqual(selections, retainedSelectionEvents, "paging UI must not call onSelect for a control row")
        try select(try XCTUnwrap(lastRows.compactMap { $0 as? SnapshotTreeItem }.first), coordinator: coordinator, outline: outline)
        XCTAssertEqual(selections.last!, lastRows.compactMap { $0 as? SnapshotTreeItem }.first?.node.id)
    }

    func testCoordinatorKeepsNestedBranchPagesIndependentAndDoesNotLoadDescendantsEarly() throws {
        let snapshotID = try populateNestedSnapshot(filesPerBranch: 501, volumeID: 45_102)
        let tree = SnapshotTreeDataSource(database: database, snapshotID: snapshotID)
        let root = try XCTUnwrap(try tree.root())
        let (coordinator, outline, rootItem) = try coordinatorFixture(dataSource: tree, root: root)
        let rootRows = callbackRows(of: rootItem, coordinator: coordinator, outline: outline)
        let branches = rootRows.compactMap { $0 as? SnapshotTreeItem }
        XCTAssertEqual(branches.map { $0.node.name }, ["Alpha", "Beta"])
        // Counts the root metadata row from tree.root() plus direct branches, not paging controls.
        XCTAssertEqual(tree.rowsFetched, 1 + branches.count)

        let alpha = branches[0]
        let beta = branches[1]
        tree.resetInstrumentation()
        outline.expandItem(alpha)
        let alphaFirstRows = callbackRows(of: alpha, coordinator: coordinator, outline: outline)
        XCTAssertEqual(alphaFirstRows.compactMap { $0 as? SnapshotTreeItem }.count, 500)
        XCTAssertEqual(tree.rowsFetched, 500)
        let alphaControl = try XCTUnwrap(alphaFirstRows.compactMap { $0 as? SnapshotTreePageControlItem }.first)
        try clickButton("Next", for: alphaControl, coordinator: coordinator, outline: outline)
        let alphaLastRows = callbackRows(of: alpha, coordinator: coordinator, outline: outline)
        let alphaLastItems = alphaLastRows.compactMap { $0 as? SnapshotTreeItem }
        XCTAssertEqual(alphaLastItems.count, 2)
        XCTAssertEqual(alphaLastItems.last?.node.name, "Inner")

        outline.expandItem(beta)
        let betaFirstRows = callbackRows(of: beta, coordinator: coordinator, outline: outline)
        XCTAssertEqual(betaFirstRows.compactMap { $0 as? SnapshotTreeItem }.count, 500)
        let betaControl = try XCTUnwrap(betaFirstRows.compactMap { $0 as? SnapshotTreePageControlItem }.first)
        try clickButton("Next", for: betaControl, coordinator: coordinator, outline: outline)
        XCTAssertEqual(callbackRows(of: alpha, coordinator: coordinator, outline: outline)
            .compactMap { $0 as? SnapshotTreeItem }.map { $0.node.id }, alphaLastItems.map { $0.node.id })
        XCTAssertTrue(controlMessage(alphaControl, coordinator: coordinator, outline: outline).contains("Last page"))

        let inner = try XCTUnwrap(alphaLastItems.last)
        outline.expandItem(inner)
        let innerRows = callbackRows(of: inner, coordinator: coordinator, outline: outline)
        XCTAssertEqual(innerRows.compactMap { $0 as? SnapshotTreeItem }.map { $0.node.name }, ["inside.dat"])
        XCTAssertLessThanOrEqual(coordinator.retainedEntryItemCount, coordinator.maximumRetainedEntryItems)
    }

    func testCoordinatorEvictsVisitedPagesAndReleasesThemOnCollapseRootChangeAndExit() throws {
        let result = try SyntheticCatalog.populate(
            database: database, directoryCount: 18, filesPerDirectory: 501, volumeID: 45_103
        )
        let tree = SnapshotTreeDataSource(database: database, snapshotID: result.snapshotID)
        let root = try XCTUnwrap(try tree.root())
        let (coordinator, outline, rootItem) = try coordinatorFixture(dataSource: tree, root: root)
        let folders = callbackRows(of: rootItem, coordinator: coordinator, outline: outline)
            .compactMap { $0 as? SnapshotTreeItem }
        XCTAssertEqual(folders.count, 18)

        for folder in folders {
            _ = callbackRows(of: folder, coordinator: coordinator, outline: outline)
            XCTAssertLessThanOrEqual(coordinator.retainedEntryItemCount, coordinator.maximumRetainedEntryItems)
            XCTAssertLessThanOrEqual(coordinator.cachedBranchPageCount, coordinator.maximumCachedBranchPages)
        }
        XCTAssertEqual(coordinator.maximumCachedBranchPagesObserved, coordinator.maximumCachedBranchPages)
        XCTAssertLessThanOrEqual(coordinator.maximumRetainedEntryItemsObserved, coordinator.maximumRetainedEntryItems)
        XCTAssertLessThanOrEqual(coordinator.maximumRetainedOutlineItemsObserved, coordinator.maximumRetainedOutlineItems)
        print("CACHE_OBSERVED branchPages=\(coordinator.maximumCachedBranchPagesObserved)/\(coordinator.maximumCachedBranchPages) entryItems=\(coordinator.maximumRetainedEntryItemsObserved)/\(coordinator.maximumRetainedEntryItems) outlineItems=\(coordinator.maximumRetainedOutlineItemsObserved)/\(coordinator.maximumRetainedOutlineItems)")
        XCTAssertEqual(callbackRows(of: folders[0], coordinator: coordinator, outline: outline).compactMap { $0 as? SnapshotTreeItem }.count, 0)
        let evictedControl = try XCTUnwrap(callbackRows(of: folders[0], coordinator: coordinator, outline: outline)
            .compactMap { $0 as? SnapshotTreePageControlItem }.first)
        XCTAssertTrue(controlMessage(evictedControl, coordinator: coordinator, outline: outline).contains("released"))

        coordinator.outlineViewItemDidCollapse(Notification(
            name: NSNotification.Name("NSOutlineViewItemDidCollapseNotification"),
            object: outline,
            userInfo: ["NSObject": folders[1]]
        ))
        XCTAssertLessThanOrEqual(coordinator.cachedBranchPageCount, coordinator.maximumCachedBranchPages)

        let replacement = try SyntheticCatalog.populate(
            database: database, directoryCount: 1, filesPerDirectory: 1, volumeID: 45_104
        )
        let replacementTree = SnapshotTreeDataSource(database: database, snapshotID: replacement.snapshotID)
        let replacementRoot = try XCTUnwrap(try replacementTree.root())
        coordinator.setRoot(replacementRoot, dataSource: replacementTree)
        XCTAssertEqual(coordinator.retainedEntryItemCount, 1, "only the replacement root's direct page may be loaded")
        let queriesAfterReplacement = replacementTree.queryCount
        _ = callbackRows(of: folders[0], coordinator: coordinator, outline: outline)
        XCTAssertEqual(replacementTree.queryCount, queriesAfterReplacement, "stale rows from the prior snapshot must not query or attach")

        coordinator.releaseForBrowserExit()
        XCTAssertEqual(coordinator.retainedEntryItemCount, 0)
        XCTAssertEqual(coordinator.retainedOutlineItemCount, 0)
        XCTAssertEqual(coordinator.outlineView(outline, numberOfChildrenOfItem: nil), 0)
    }

    func testAppKitWindowWidthsAndKeyboardAccessiblePagingControls() throws {
        let result = try SyntheticCatalog.populate(
            database: database, directoryCount: 1, filesPerDirectory: 501, volumeID: 45_105
        )
        let tree = SnapshotTreeDataSource(database: database, snapshotID: result.snapshotID)
        let root = try XCTUnwrap(try tree.root())
        let folderID = try XCTUnwrap(try tree.children(ofParent: root.id).first?.id)
        var shouldFailNextPage = true
        let (coordinator, outline, rootItem) = try coordinatorFixture(
            dataSource: tree,
            root: root,
            pageLoader: { parentID, offset, limit in
                if parentID == folderID && offset == 500 && shouldFailNextPage {
                    shouldFailNextPage = false
                    throw CatalogDatabaseError.sqlite(1, "synthetic transient page error")
                }
                return try tree.children(ofParent: parentID, offset: offset, limit: limit)
            }
        )
        let scrollView = try XCTUnwrap(coordinatorScrollView)
        let folder = try XCTUnwrap(appKitRows(of: rootItem, outline: outline)
            .compactMap { $0 as? SnapshotTreeItem }.first)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1120, height: 700),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        defer { window.orderOut(nil) }
        window.contentView = scrollView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        outline.expandItem(folder)
        XCTAssertTrue(outline.isItemExpanded(folder))

        let pageRows = appKitRows(of: folder, outline: outline)
        XCTAssertEqual(pageRows.compactMap { $0 as? SnapshotTreeItem }.count, 500)
        let nextControl = try XCTUnwrap(pageRows.compactMap { $0 as? SnapshotTreePageControlItem }.first)
        let nextRow = outline.row(forItem: nextControl)
        XCTAssertGreaterThanOrEqual(nextRow, 0)
        outline.scrollRowToVisible(nextRow)

        let repoRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let captureDirectory = repoRoot.appendingPathComponent(".ai-scratch/task045/real-gui", isDirectory: true)
        try FileManager.default.createDirectory(at: captureDirectory, withIntermediateDirectories: true)
        for width in [1120, 1330, 1440] {
            window.setContentSize(NSSize(width: width, height: 700))
            window.displayIfNeeded()
            scrollView.layoutSubtreeIfNeeded()
            outline.layoutSubtreeIfNeeded()
            XCTAssertEqual(Int(scrollView.bounds.width), width)
            let view = try XCTUnwrap(window.contentView)
            let bitmap = try XCTUnwrap(view.bitmapImageRepForCachingDisplay(in: view.bounds))
            view.cacheDisplay(in: view.bounds, to: bitmap)
            let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
            let imageURL = captureDirectory.appendingPathComponent("snapshot-browser-\(width).png")
            try png.write(to: imageURL, options: .atomic)
            print("GUI_CAPTURE width=\(width)pt scrollViewWidth=\(Int(scrollView.bounds.width))pt path=\(imageURL.path)")
        }

        let nameColumn = outline.column(withIdentifier: NSUserInterfaceItemIdentifier("name"))
        let nextCell = try XCTUnwrap(outline.view(atColumn: nameColumn, row: nextRow, makeIfNecessary: true) as? NSTableCellView)
        let nextButton = try XCTUnwrap(buttons(in: nextCell).first { $0.title == "Next" })
        XCTAssertEqual(nextButton.accessibilityLabel(), "Next page, entries 501–501 of 501.")
        XCTAssertTrue(window.makeFirstResponder(nextButton), "the paging button must accept keyboard focus")
        try sendSpaceKey(in: window)

        let failedRows = appKitRows(of: folder, outline: outline)
        XCTAssertEqual(failedRows.compactMap { $0 as? SnapshotTreeItem }.count, 500)
        let errorControl = try XCTUnwrap(failedRows.compactMap { $0 as? SnapshotTreePageControlItem }.first)
        XCTAssertTrue(controlMessage(errorControl, coordinator: coordinator, outline: outline)
            .contains("Couldn't load entries 501–501 of 501"))
        let errorRow = outline.row(forItem: errorControl)
        outline.scrollRowToVisible(errorRow)
        outline.layoutSubtreeIfNeeded()
        let errorCell = try XCTUnwrap(outline.view(atColumn: nameColumn, row: errorRow, makeIfNecessary: true) as? NSTableCellView)
        XCTAssertTrue(errorCell.textField?.stringValue.contains("Couldn't load entries 501–501 of 501") == true)
        let retryButton = try XCTUnwrap(buttons(in: errorCell).first { $0.title == "Retry" })
        XCTAssertEqual(retryButton.accessibilityLabel(), "Retry loading entries 501–501 of 501 from the saved snapshot.")
        window.displayIfNeeded()
        let errorView = try XCTUnwrap(window.contentView)
        let errorBitmap = try XCTUnwrap(errorView.bitmapImageRepForCachingDisplay(in: errorView.bounds))
        errorView.cacheDisplay(in: errorView.bounds, to: errorBitmap)
        let errorPNG = try XCTUnwrap(errorBitmap.representation(using: .png, properties: [:]))
        let errorImageURL = captureDirectory.appendingPathComponent("snapshot-browser-error-state-1440.png")
        try errorPNG.write(to: errorImageURL, options: .atomic)
        print("GUI_ERROR_CAPTURE path=\(errorImageURL.path)")
        XCTAssertTrue(window.makeFirstResponder(retryButton), "Retry must accept keyboard focus")
        try sendSpaceKey(in: window)

        let retriedRows = appKitRows(of: folder, outline: outline)
        XCTAssertEqual(retriedRows.compactMap { $0 as? SnapshotTreeItem }.map { $0.node.name }, ["file-0500.dat"])
        let lastControl = try XCTUnwrap(retriedRows.compactMap { $0 as? SnapshotTreePageControlItem }.first)
        let previousButton = try XCTUnwrap(controlButton("Prev", for: lastControl, coordinator: coordinator, outline: outline))
        XCTAssertEqual(previousButton.accessibilityLabel(), "Previous page, entries 1–500 of 501.")
        let lastPageRow = outline.row(forItem: lastControl)
        outline.scrollRowToVisible(lastPageRow)
        outline.layoutSubtreeIfNeeded()
        let lastPageCell = try XCTUnwrap(outline.view(atColumn: nameColumn, row: lastPageRow, makeIfNecessary: true) as? NSTableCellView)
        XCTAssertEqual(buttons(in: lastPageCell).first?.accessibilityLabel(), "Previous page, entries 1–500 of 501.")
        window.displayIfNeeded()
        let lastPageView = try XCTUnwrap(window.contentView)
        let lastPageBitmap = try XCTUnwrap(lastPageView.bitmapImageRepForCachingDisplay(in: lastPageView.bounds))
        lastPageView.cacheDisplay(in: lastPageView.bounds, to: lastPageBitmap)
        let lastPagePNG = try XCTUnwrap(lastPageBitmap.representation(using: .png, properties: [:]))
        let lastPageImageURL = captureDirectory.appendingPathComponent("snapshot-browser-last-page-state-1440.png")
        try lastPagePNG.write(to: lastPageImageURL, options: .atomic)
        print("GUI_LAST_PAGE_CAPTURE path=\(lastPageImageURL.path)")
        print("GUI_KEYBOARD_ACCESSIBILITY=Space activated Next and Retry; AX labels verified; error recovered")
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

    private func coordinatorFixture(
        dataSource: SnapshotTreeDataSource,
        root: SnapshotTreeNode,
        onSelect: @escaping (Int64?) -> Void = { _ in },
        childCountLoader: ((Int64) throws -> Int)? = nil,
        pageLoader: ((Int64, Int, Int) throws -> [SnapshotTreeNode])? = nil
    ) throws -> (LazyMetadataOutlineView.Coordinator, NSOutlineView, SnapshotTreeItem) {
        let coordinator = LazyMetadataOutlineView.Coordinator(
            dataSource: dataSource,
            onSelect: onSelect,
            childCountLoader: childCountLoader,
            pageLoader: pageLoader
        )
        let outline = NSOutlineView()
        outline.style = .inset
        outline.rowSizeStyle = .default
        outline.usesAlternatingRowBackgroundColors = true
        outline.autoresizesOutlineColumn = false

        let nameColumn = NSTableColumn(identifier: .init("name"))
        nameColumn.title = "Name"
        nameColumn.width = 320
        outline.addTableColumn(nameColumn)
        outline.outlineTableColumn = nameColumn

        let kindColumn = NSTableColumn(identifier: .init("kind"))
        kindColumn.title = "Kind"
        kindColumn.width = 90
        outline.addTableColumn(kindColumn)

        let sizeColumn = NSTableColumn(identifier: .init("size"))
        sizeColumn.title = "Logical size"
        sizeColumn.width = 110
        outline.addTableColumn(sizeColumn)

        outline.dataSource = coordinator
        outline.delegate = coordinator
        coordinator.outlineView = outline
        let scrollView = NSScrollView()
        scrollView.documentView = outline
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        coordinatorScrollView = scrollView
        coordinator.setRoot(root)
        let rootItem = try XCTUnwrap(callbackChild(0, of: nil, coordinator: coordinator, outline: outline) as? SnapshotTreeItem)
        return (coordinator, outline, rootItem)
    }

    private func callbackChild(
        _ index: Int,
        of parent: SnapshotTreeItem?,
        coordinator: LazyMetadataOutlineView.Coordinator,
        outline: NSOutlineView
    ) -> Any {
        coordinator.outlineView(outline, child: index, ofItem: parent)
    }

    private func callbackRows(
        of parent: SnapshotTreeItem,
        coordinator: LazyMetadataOutlineView.Coordinator,
        outline: NSOutlineView
    ) -> [Any] {
        let count = coordinator.outlineView(outline, numberOfChildrenOfItem: parent)
        return (0..<count).map { coordinator.outlineView(outline, child: $0, ofItem: parent) }
    }

    private func appKitRows(of parent: Any?, outline: NSOutlineView) -> [Any] {
        let count = outline.numberOfChildren(ofItem: parent)
        return (0..<count).map { outline.child($0, ofItem: parent) ?? NSNull() }
    }

    private func controlCell(
        _ control: SnapshotTreePageControlItem,
        coordinator: LazyMetadataOutlineView.Coordinator,
        outline: NSOutlineView
    ) -> NSTableCellView {
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        return coordinator.outlineView(outline, viewFor: nameColumn, item: control) as! NSTableCellView
    }

    private func controlMessage(
        _ control: SnapshotTreePageControlItem,
        coordinator: LazyMetadataOutlineView.Coordinator,
        outline: NSOutlineView
    ) -> String {
        controlCell(control, coordinator: coordinator, outline: outline).textField?.stringValue ?? ""
    }

    private func controlButton(
        _ title: String,
        for control: SnapshotTreePageControlItem,
        coordinator: LazyMetadataOutlineView.Coordinator,
        outline: NSOutlineView
    ) -> NSButton? {
        buttons(in: controlCell(control, coordinator: coordinator, outline: outline))
            .first { $0.title == title }
    }

    private func clickButton(
        _ title: String,
        for control: SnapshotTreePageControlItem,
        coordinator: LazyMetadataOutlineView.Coordinator,
        outline: NSOutlineView,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let button = try XCTUnwrap(
            controlButton(title, for: control, coordinator: coordinator, outline: outline),
            "Missing \(title) page control",
            file: file,
            line: line
        )
        button.performClick(nil)
    }

    private func buttons(in view: NSView) -> [NSButton] {
        var collected = (view as? NSButton).map { [$0] } ?? []
        for child in view.subviews { collected.append(contentsOf: buttons(in: child)) }
        return collected
    }

    private func sendSpaceKey(in window: NSWindow) throws {
        for eventType in [NSEvent.EventType.keyDown, .keyUp] {
            let event = try XCTUnwrap(NSEvent.keyEvent(
                with: eventType,
                location: .zero,
                modifierFlags: [],
                timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: window.windowNumber,
                context: nil,
                characters: " ",
                charactersIgnoringModifiers: " ",
                isARepeat: false,
                keyCode: 49
            ))
            NSApp.sendEvent(event)
        }
    }

    private func select(
        _ item: SnapshotTreeItem,
        coordinator: LazyMetadataOutlineView.Coordinator,
        outline: NSOutlineView,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        outline.reloadData()
        let row = outline.row(forItem: item)
        XCTAssertGreaterThanOrEqual(row, 0, "selected entry must be a real visible AppKit row", file: file, line: line)
        guard row >= 0 else { return }
        outline.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        coordinator.outlineViewSelectionDidChange(Notification(
            name: NSNotification.Name("NSOutlineViewSelectionDidChangeNotification"),
            object: outline
        ))
    }

    private func populateNestedSnapshot(filesPerBranch: Int, volumeID: Int64) throws -> SnapshotID {
        let snapshotID = try SyntheticSnapshot.createSnapshot(
            database: database, volumeID: volumeID, session: 1, name: "Nested"
        )
        var entries = [
            SyntheticSnapshot.root(id: 1, name: "Nested"),
            SyntheticSnapshot.SeedEntry(id: 2, parentID: 1, relativePath: "Alpha", name: "Alpha", itemKind: .directory),
            SyntheticSnapshot.SeedEntry(id: 3, parentID: 1, relativePath: "Beta", name: "Beta", itemKind: .directory)
        ]
        var nextID: Int64 = 10
        for index in 0..<filesPerBranch {
            let name = String(format: "file-%04d.dat", index)
            entries.append(SyntheticSnapshot.SeedEntry(
                id: nextID, parentID: 2, relativePath: "Alpha/\(name)", name: name
            ))
            nextID += 1
        }
        let innerID = nextID
        entries.append(SyntheticSnapshot.SeedEntry(
            id: innerID, parentID: 2, relativePath: "Alpha/Inner", name: "Inner", itemKind: .directory
        ))
        entries.append(SyntheticSnapshot.SeedEntry(
            id: innerID + 1, parentID: innerID,
            relativePath: "Alpha/Inner/inside.dat", name: "inside.dat"
        ))
        nextID = innerID + 2
        for index in 0..<filesPerBranch {
            let name = String(format: "file-%04d.dat", index)
            entries.append(SyntheticSnapshot.SeedEntry(
                id: nextID, parentID: 3, relativePath: "Beta/\(name)", name: name
            ))
            nextID += 1
        }
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: snapshotID, entries: entries)
        try SyntheticSnapshot.complete(database: database, snapshotID: snapshotID)
        return snapshotID
    }

    private func catalogFileSize() -> Int64 {
        let url = directory.appendingPathComponent("catalog.sqlite3")
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return (attributes?[.size] as? NSNumber)?.int64Value ?? -1
    }
}
