import AppKit
import SwiftUI
import XCTest
@testable import FSD

/// Task051 Snapshot Collections organizer slice. Everything runs against an
/// isolated synthetic SQLite catalog; the repository never touches a source,
/// so these are deterministic catalog-behavior and bounded-rendering tests.
@MainActor
final class SnapshotCollectionsTests: XCTestCase {
    private var directory: URL!
    private var database: CatalogDatabase!
    private var repository: SnapshotCollectionRepository!
    private var historyRepository: SnapshotHistoryRepository!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-Collections-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        database = try CatalogDatabase(
            url: directory.appendingPathComponent("catalog.sqlite3"),
            schemaURL: CatalogSchemaFixture.canonicalSchemaURL
        )
        repository = SnapshotCollectionRepository(database: database)
        historyRepository = SnapshotHistoryRepository(database: database)
    }

    override func tearDownWithError() throws {
        repository = nil
        historyRepository = nil
        database?.close()
        database = nil
        try? FileManager.default.removeItem(at: directory)
        directory = nil
    }

    // MARK: - Fixtures

    @discardableResult
    private func makeUserSnapshot(volume: Int64, session: Int64, name: String) throws -> SnapshotID {
        let id = try SyntheticSnapshot.createSnapshot(database: database, volumeID: volume, session: session, name: name)
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: id, entries: [
            SyntheticSnapshot.root(id: volume * 100 + session, name: name)
        ])
        try SyntheticSnapshot.complete(database: database, snapshotID: id)
        return id
    }

    private func databaseFingerprint(_ id: SnapshotID) throws -> String {
        var parts: [String] = []
        let snapshots = try database.query("SELECT * FROM snapshots WHERE id = ?", bindings: [.integer(id.rawValue)])
        for row in snapshots {
            for key in row.keys.sorted() where key != "collection_id" && key != "updated_at" {
                parts.append("s.\(key)=\(row[key]!)")
            }
        }
        let entries = try database.query(
            "SELECT * FROM entries WHERE snapshot_id = ? ORDER BY id",
            bindings: [.integer(id.rawValue)]
        )
        for row in entries {
            for key in row.keys.sorted() {
                parts.append("e.\(key)=\(row[key]!)")
            }
        }
        return parts.joined(separator: "|")
    }

    // MARK: - Create / list / persistence

    func testCreateListAndReloadPersistAcrossInstances() throws {
        let created = try repository.createCollection(name: "  XYZ  ", note: "Client reel")
        XCTAssertEqual(created.name, "XYZ", "the stored name is trimmed")
        XCTAssertEqual(created.normalizedName, SnapshotCollectionRepository.normalize("XYZ"))
        XCTAssertEqual(created.note, "Client reel")
        XCTAssertNil(created.lastUsedAt, "a new Collection has not been used yet")

        let reloaded = try SnapshotCollectionRepository(database: database).listCollections()
        XCTAssertEqual(reloaded.collections.map(\.id), [created.id])
        XCTAssertEqual(try repository.collection(id: created.id)?.name, "XYZ")
    }

    func testBlankNameRejected() throws {
        XCTAssertThrowsError(try repository.createCollection(name: "   ")) {
            XCTAssertEqual($0 as? SnapshotCollectionError, .blankName)
        }
        XCTAssertTrue(try repository.listCollections().collections.isEmpty)
    }

    func testCaseAndUnicodeDuplicateNamesRejected() throws {
        _ = try repository.createCollection(name: "XYZ")
        XCTAssertThrowsError(try repository.createCollection(name: "xyz")) { error in
            guard case .duplicateName = error as? SnapshotCollectionError else {
                return XCTFail("expected duplicateName, got \(error)")
            }
        }

        _ = try repository.createCollection(name: "Café")
        let decomposed = "Cafe\u{0301}"
        XCTAssertThrowsError(try repository.createCollection(name: decomposed)) { error in
            guard case .duplicateName = error as? SnapshotCollectionError else {
                return XCTFail("expected duplicateName for a Unicode-equivalent name, got \(error)")
            }
        }
        XCTAssertEqual(try repository.listCollections().collections.count, 2, "no near-duplicate was created")
    }

    func testListOrderIsDeterministicAndBoundedWithTruncation() throws {
        for name in ["b", "A", "C"] { _ = try repository.createCollection(name: name) }
        let page = try repository.listCollections()
        XCTAssertEqual(page.collections.map(\.name), ["A", "b", "C"], "normalized_name ASC, id ASC")
        XCTAssertFalse(page.isTruncated)

        let firstTwo = try repository.listCollections(limit: 2)
        XCTAssertEqual(firstTwo.collections.count, 2)
        XCTAssertTrue(firstTwo.isTruncated, "a shorter page reports truncation")
    }

    func testUnsortedIsNullNotBuiltInRow() throws {
        let collection = try repository.createCollection(name: "XYZ")
        let a = try makeUserSnapshot(volume: 1, session: 1, name: "A")
        let b = try makeUserSnapshot(volume: 2, session: 1, name: "B")
        try repository.assign(snapshotID: b, to: collection.id)

        let rows = try database.query("SELECT collection_id FROM snapshots ORDER BY id")
        XCTAssertEqual(rows.count, 2)
        XCTAssertNil(rows[0]["collection_id"]?.int64Value, "an unassigned snapshot stores NULL, not a sentinel row")
        XCTAssertEqual(rows[1]["collection_id"]?.int64Value, collection.id)

        let unsorted = try repository.listSnapshots(filter: .unsorted)
        XCTAssertEqual(unsorted.snapshots.map(\.id), [a])
        XCTAssertNil(unsorted.snapshots.first?.collectionID)
        let collections = try repository.listCollections().collections
        XCTAssertFalse(collections.contains { $0.name == "Unsorted" }, "Unsorted is never a stored Collection")
    }

    // MARK: - Membership

    func testMoveAssignsByStableIDAndUpdatesLastUsedAt() throws {
        let collection = try repository.createCollection(name: "XYZ")
        XCTAssertNil(try repository.collection(id: collection.id)?.lastUsedAt)

        let snapshot = try makeUserSnapshot(volume: 1, session: 1, name: "A")
        try repository.assign(snapshotID: snapshot, to: collection.id)

        let assigned = try repository.listSnapshots(filter: .collection(collection.id))
        XCTAssertEqual(assigned.snapshots.map(\.id), [snapshot])
        XCTAssertNotNil(try repository.collection(id: collection.id)?.lastUsedAt, "assignment advances last_used_at")

        let counts = try repository.membershipCounts()
        XCTAssertEqual(counts.count(for: .collection(collection.id)), 1)
        XCTAssertEqual(counts.unsorted, 0)
        XCTAssertEqual(counts.total, 1)
    }

    func testSameDisplayNamesRemainDistinctSnapshots() throws {
        let collection = try repository.createCollection(name: "XYZ")
        let first = try makeUserSnapshot(volume: 1, session: 1, name: "Shared Card")
        let second = try makeUserSnapshot(volume: 2, session: 1, name: "Shared Card")
        XCTAssertNotEqual(first, second)
        try repository.assign(snapshotID: second, to: collection.id)

        let unsorted = try repository.listSnapshots(filter: .unsorted)
        XCTAssertEqual(unsorted.snapshots.map(\.id), [first])
        XCTAssertEqual(unsorted.snapshots.first?.displayName, "Shared Card")
        XCTAssertEqual(try repository.listSnapshots(filter: .collection(collection.id)).snapshots.map(\.id), [second])
    }

    func testMoveBackToUnsortedClearsMembershipWithoutDeleting() throws {
        let collection = try repository.createCollection(name: "XYZ")
        let snapshot = try makeUserSnapshot(volume: 1, session: 1, name: "A")
        try repository.assign(snapshotID: snapshot, to: collection.id)
        try repository.assign(snapshotID: snapshot, to: nil)

        let unsorted = try repository.listSnapshots(filter: .unsorted)
        XCTAssertEqual(unsorted.snapshots.map(\.id), [snapshot])
        XCTAssertNil(unsorted.snapshots.first?.collectionID)
        XCTAssertNotNil(try historyRepository.summary(id: snapshot), "the snapshot itself is never deleted by a move")

        let before = try repository.collection(id: collection.id)?.lastUsedAt
        try repository.assign(snapshotID: snapshot, to: nil)
        XCTAssertEqual(try repository.collection(id: collection.id)?.lastUsedAt, before, "moving out does not touch usage")
    }

    func testInvalidIDsFailSafely() throws {
        let missing = SnapshotID(rawValue: 999)
        XCTAssertThrowsError(try repository.assign(snapshotID: missing, to: nil)) {
            XCTAssertEqual($0 as? SnapshotCollectionError, .snapshotNotFound(missing))
        }

        let snapshot = try makeUserSnapshot(volume: 1, session: 1, name: "A")
        XCTAssertThrowsError(try repository.assign(snapshotID: snapshot, to: 4242)) {
            XCTAssertEqual($0 as? SnapshotCollectionError, .collectionNotFound(4242))
        }
        XCTAssertEqual(try repository.listSnapshots(filter: .unsorted).snapshots.map(\.id), [snapshot],
                       "a failed assignment leaves the snapshot unchanged")
    }

    func testTransientSnapshotsExcludedAndRejected() throws {
        let transient = try SyntheticSnapshot.createSnapshot(
            database: database, volumeID: 1, session: 1, kind: .transient, name: "Scaffolding"
        )
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: transient, entries: [
            SyntheticSnapshot.root(id: 101, name: "Scaffolding")
        ])
        try SyntheticSnapshot.complete(database: database, snapshotID: transient)

        let user = try makeUserSnapshot(volume: 2, session: 1, name: "User")

        XCTAssertEqual(try repository.listSnapshots(filter: .all).snapshots.map(\.id), [user])
        XCTAssertThrowsError(try repository.assign(snapshotID: transient, to: nil)) {
            XCTAssertEqual($0 as? SnapshotCollectionError, .snapshotNotUser(transient))
        }
    }

    // MARK: - Immutability and privacy

    func testCollectionWritesNeverModifyCapturedFacts() throws {
        let collection = try repository.createCollection(name: "XYZ")
        let snapshot = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 1, session: 1, name: "Facts")
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: snapshot, entries: [
            SyntheticSnapshot.root(id: 1, name: "Facts"),
            SyntheticSnapshot.SeedEntry(id: 2, parentID: 1, relativePath: "a.bin", name: "a.bin",
                                        logicalSizeBytes: 42, allocatedSizeBytes: 4096)
        ])
        try SyntheticSnapshot.complete(database: database, snapshotID: snapshot)

        let before = try databaseFingerprint(snapshot)
        try repository.assign(snapshotID: snapshot, to: collection.id)
        try repository.assign(snapshotID: snapshot, to: nil)
        XCTAssertEqual(try databaseFingerprint(snapshot), before,
                       "membership writes must not change entries, aggregates, timestamps or capture facts")
    }

    func testMovingSnapshotsNeverWritesToSourceFiles() throws {
        let source = directory.appendingPathComponent("source", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        let fileURL = source.appendingPathComponent("file.txt")
        try Data("payload".utf8).write(to: fileURL)

        let captured = try SnapshotScanner(database: database).capture(root: source)
        let collection = try repository.createCollection(name: "XYZ")
        let attributesBefore = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let contentBefore = try Data(contentsOf: fileURL)

        try repository.assign(snapshotID: captured.id, to: collection.id)
        try repository.assign(snapshotID: captured.id, to: nil)

        let attributesAfter = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        XCTAssertEqual(attributesAfter[.modificationDate] as? Date, attributesBefore[.modificationDate] as? Date)
        XCTAssertEqual(try Data(contentsOf: fileURL), contentBefore)
    }

    func testAssignmentsWorkWhenSourceDisappears() throws {
        let source = directory.appendingPathComponent("offline-source", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try Data("x".utf8).write(to: source.appendingPathComponent("f.bin"))

        let captured = try SnapshotScanner(database: database).capture(root: source)
        try FileManager.default.removeItem(at: source)
        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))

        let collection = try repository.createCollection(name: "XYZ")
        try repository.assign(snapshotID: captured.id, to: collection.id)
        XCTAssertEqual(try repository.listSnapshots(filter: .collection(collection.id)).snapshots.map(\.id), [captured.id])
    }

    // MARK: - Model error surfacing

    func testModelSurfacesCatalogErrorsInsteadOfEmptyCollections() throws {
        let model = SnapshotCollectionsModel(database: database)
        model.reload()
        XCTAssertNil(model.loadError)
        XCTAssertTrue(model.snapshots.isEmpty)

        try database.execute("ALTER TABLE collections RENAME TO collections_unavailable")
        model.reload()
        XCTAssertNotNil(model.loadError, "a read failure must be visible, not presented as an empty list")
        XCTAssertFalse(model.loadError?.contains("SQLITE") ?? false, "raw SQLite text is never shown")
        XCTAssertFalse(model.loadError?.contains("no such table") ?? false, "internal table names are never shown")
    }

    // MARK: - Layout

    func testLayoutFitsSupportedWidths() {
        for width in [CGFloat(1120), 1330, 1440] {
            let sidebar = SnapshotCollectionsLayout.sidebarWidth(for: width)
            let pane = SnapshotCollectionsLayout.snapshotPaneMinimumWidth(for: width)
            let shellSidebar = FSDDesignTokens.sidebarWidth(for: width)
            XCTAssertGreaterThanOrEqual(sidebar, 240)
            XCTAssertLessThanOrEqual(sidebar + pane + shellSidebar, width,
                                     "the Collections list and rows fit inside the FSD window at \(Int(width)) pt")
        }
        XCTAssertEqual(SnapshotCollectionsLayout.sidebarWidth(for: 1120), 250)
        XCTAssertEqual(SnapshotCollectionsLayout.sidebarWidth(for: 1330), 290)
    }

    // MARK: - Shell wiring and privacy boundary

    func testNavigatorWiresCollectionsAndPreservesExistingRoutes() throws {
        let repoRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: repoRoot.appendingPathComponent("FSD/UI/ComparisonSharedViews.swift"),
            encoding: .utf8
        )
        XCTAssertTrue(source.contains("case collections"), "a Collections destination exists")
        XCTAssertTrue(source.contains("navigationRow(\"Collections\""), "the sidebar links to Collections")
        XCTAssertTrue(source.contains("SnapshotCollectionsView("), "the destination hosts the organizer")
        XCTAssertTrue(source.contains("onBrowse"), "browsing is routed back to the app shell")

        XCTAssertTrue(source.contains("model.openSnapshot(summary)"), "completed Browse keeps the stored-snapshot route")
        XCTAssertTrue(source.contains("onHistory: { selection = .recentCaptures }"))
        XCTAssertTrue(source.contains("onComparisons: { selection = .comparisons }"))
        XCTAssertTrue(source.contains("onCapture: { selection = .capture }"))
        XCTAssertTrue(source.contains("if let startupError = model.startupError"))
        XCTAssertTrue(source.contains("if model.history.isEmpty"))
        XCTAssertTrue(source.contains("No captures yet"))
        XCTAssertTrue(source.contains("title: \"Catalog unavailable\""))

        XCTAssertTrue(source.contains("Move to Collection"))
        XCTAssertTrue(source.contains("Create Collection"))
        XCTAssertTrue(source.contains(".keyboardShortcut(.defaultAction)"))
        XCTAssertTrue(source.contains(".keyboardShortcut(.cancelAction)"))
        XCTAssertTrue(source.contains("accessibilityLabel(\"Create a new Collection\")"))
        XCTAssertTrue(source.contains("accessibilityLabel(\"Move selected snapshot to a Collection\")"))
    }

    func testRepositoryHasNoSourceOrClassificationAccess() throws {
        let repoRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: repoRoot.appendingPathComponent("FSD/Catalog/SnapshotCollectionRepository.swift"),
            encoding: .utf8
        )
        let code = source
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
        for forbidden in ["FileManager", "NSURL", "SourceAvailabilityProbe", "mountPath", "URL("] {
            XCTAssertFalse(code.contains(forbidden), "collection writes must not use \(forbidden)")
        }
        XCTAssertFalse(code.lowercased().contains("classif"), "no classification in the organizer repository")
        XCTAssertFalse(code.contains("DELETE "), "the organizer never deletes rows")
        XCTAssertFalse(code.contains("INSERT INTO entries"), "the organizer never writes entry rows")
        XCTAssertFalse(code.contains("INSERT INTO snapshots"), "the organizer never writes snapshot rows")
    }

    // MARK: - GUI rendering

    func testCollectionsGUIRendersAtSupportedWidthsAndCapturesScreenshots() throws {
        let assignedCollection = try repository.createCollection(name: "XYZ")
        _ = try repository.createCollection(name: "Empty Reel")
        let snapshot = try makeUserSnapshot(volume: 1, session: 1, name: "Card A")
        let unsortedSnapshot = try makeUserSnapshot(volume: 2, session: 1, name: "Card B")
        try repository.assign(snapshotID: snapshot, to: assignedCollection.id)

        let model = SnapshotCollectionsModel(database: database)
        model.reload()
        let view = SnapshotCollectionsView(model: model) { _ in }
        let hosting = NSHostingView(rootView: view)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1120, height: 720),
            styleMask: [.titled, .resizable],
            backing: .buffered,
            defer: false
        )
        defer { window.orderOut(nil) }
        window.contentView = hosting
        window.makeKeyAndOrderFront(nil)

        let captureDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent(".ai-scratch/task051/screenshots", isDirectory: true)
        try FileManager.default.createDirectory(at: captureDirectory, withIntermediateDirectories: true)

        func capture(_ name: String, width: CGFloat) throws {
            window.setContentSize(NSSize(width: width, height: 720))
            hosting.layoutSubtreeIfNeeded()
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
            XCTAssertEqual(Int(hosting.bounds.width), Int(width), "hosted organizer fills the FSD window at \(Int(width)) pt")
            let bitmap = try XCTUnwrap(hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds))
            hosting.cacheDisplay(in: hosting.bounds, to: bitmap)
            let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
            try png.write(to: captureDirectory.appendingPathComponent(name), options: .atomic)
            print("COLLECTIONS_GUI_CAPTURE path=\(captureDirectory.appendingPathComponent(name).path)")
        }

        try capture("collections-all-1120.png", width: 1120)
        try capture("collections-all-1330.png", width: 1330)

        model.select(.unsorted)
        XCTAssertEqual(model.snapshots.map(\.id), [unsortedSnapshot])
        try capture("collections-unsorted-1120.png", width: 1120)

        let assignedFilter = CollectionFilter.collection(id: assignedCollection.id, name: assignedCollection.name)
        model.select(assignedFilter)
        XCTAssertEqual(model.snapshots.map(\.id), [snapshot])
        model.selectedSnapshotID = snapshot
        try capture("collections-assigned-1330.png", width: 1330)

        let emptyID = try XCTUnwrap(try repository.listCollections().collections.first { $0.name == "Empty Reel" }?.id)
        model.select(.collection(id: emptyID, name: "Empty Reel"))
        XCTAssertTrue(model.snapshots.isEmpty)
        try capture("collections-empty-1120.png", width: 1120)
    }
}
