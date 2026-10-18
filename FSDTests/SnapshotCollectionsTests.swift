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

    private func metadataEditEvidenceFingerprint(_ id: SnapshotID) throws -> String {
        var parts: [String] = []
        let snapshots = try database.query("SELECT * FROM snapshots WHERE id = ?", bindings: [.integer(id.rawValue)])
        for row in snapshots {
            for key in row.keys.sorted() where key != "display_name" && key != "user_note" {
                parts.append("s.\(key)=\(row[key]!)")
            }
        }
        for (table, predicate, bindings) in [
            ("entries", "snapshot_id = ? ORDER BY id", [DatabaseValue.integer(id.rawValue)]),
            ("scan_issues", "snapshot_id = ? ORDER BY id", [DatabaseValue.integer(id.rawValue)])
        ] {
            let rows = try database.query("SELECT * FROM \(table) WHERE \(predicate)", bindings: bindings)
            for row in rows {
                for key in row.keys.sorted() { parts.append("\(table).\(key)=\(row[key]!)") }
            }
        }
        for table in ["comparisons", "comparison_results", "comparison_collision_groups", "comparison_collision_members"] {
            let rows = try database.query("SELECT * FROM \(table) ORDER BY id")
            for row in rows {
                for key in row.keys.sorted() { parts.append("\(table).\(key)=\(row[key]!)") }
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

    // MARK: - Snapshot label and note editing

    func testSnapshotLabelAndNoteSaveByStableIDAndReloadsPersistedValues() throws {
        let collection = try repository.createCollection(name: "Project").id
        let editedID = try makeUserSnapshot(volume: 1, session: 1, name: "Original")
        let otherID = try makeUserSnapshot(volume: 2, session: 1, name: "Existing Label")
        try repository.assign(snapshotID: editedID, to: collection)
        let comparison = try ComparisonService(database: database).snapshotToSnapshot(
            leftSnapshotID: editedID,
            rightSnapshotID: otherID
        )
        XCTAssertGreaterThan(
            try XCTUnwrap(try database.scalar(
                "SELECT COUNT(*) FROM comparison_results WHERE comparison_id = ?",
                bindings: [.integer(comparison.id.rawValue)]
            )?.int64Value),
            0,
            "the fixture carries persisted comparison evidence"
        )

        let priorLastUsed = try XCTUnwrap(try repository.collection(id: collection)?.lastUsedAt)
        let priorCollectionFilter = CollectionFilter.collection(id: collection, name: "Project")
        let beforeEvidence = try metadataEditEvidenceFingerprint(editedID)
        let otherBefore = try XCTUnwrap(try repository.snapshotLabelAndNote(for: otherID))

        let model = SnapshotCollectionsModel(database: database)
        model.reload()
        model.select(priorCollectionFilter)
        model.selectedSnapshotID = editedID
        model.beginEditingSelectedSnapshotMetadata()
        XCTAssertTrue(model.isShowingSnapshotMetadataEditor)
        XCTAssertEqual(model.snapshotLabelDraft, "Original")
        XCTAssertEqual(model.snapshotUserNoteDraft, "")

        // The label intentionally duplicates another snapshot's label.
        model.snapshotLabelDraft = "Existing Label"
        model.snapshotUserNoteDraft = "Saved for the next review"
        XCTAssertTrue(model.saveSnapshotLabelAndNote())

        let reloaded = try SnapshotCollectionRepository(database: database)
            .snapshotLabelAndNote(for: editedID)
        XCTAssertEqual(reloaded.snapshotID, editedID)
        XCTAssertEqual(reloaded.displayName, "Existing Label")
        XCTAssertEqual(reloaded.userNote, "Saved for the next review")
        XCTAssertFalse(model.isShowingSnapshotMetadataEditor)
        XCTAssertEqual(model.selectedSnapshotID, editedID, "saving retains stable SnapshotID selection")
        XCTAssertEqual(model.selectedFilter, priorCollectionFilter, "saving retains the current Collection filter")
        XCTAssertEqual(model.snapshots.first(where: { $0.id == editedID })?.displayName, reloaded.displayName)
        XCTAssertEqual(model.snapshots.first(where: { $0.id == editedID })?.userNote, reloaded.userNote)
        XCTAssertEqual(try repository.listSnapshots(filter: .collection(collection)).snapshots.map(\.id), [editedID])
        XCTAssertEqual(try repository.collection(id: collection)?.lastUsedAt, priorLastUsed,
                       "a label and note edit must not advance Collection last_used_at")
        XCTAssertEqual(try repository.snapshotLabelAndNote(for: otherID), otherBefore,
                       "editing one stable SnapshotID leaves another snapshot unchanged")
        XCTAssertEqual(
            try repository.listSnapshots(filter: .all).snapshots.filter { $0.displayName == "Existing Label" }.count,
            2,
            "duplicate snapshot display labels are allowed"
        )
        XCTAssertEqual(try metadataEditEvidenceFingerprint(editedID), beforeEvidence,
                       "entries, aggregates, comparison evidence and all non-label capture facts remain unchanged")
        XCTAssertEqual(try historyRepository.summary(id: editedID)?.displayName, reloaded.displayName,
                       "History reads the persisted user label while capture-time source facts remain separate")
        XCTAssertEqual(try database.scalar("SELECT user_note FROM snapshots WHERE id = ?", bindings: [.integer(editedID.rawValue)])?.stringValue,
                       "Saved for the next review")
    }

    func testEmptyNoteIsStoredAsNullAndLoadedAsOptional() throws {
        let snapshot = try makeUserSnapshot(volume: 1, session: 1, name: "Label")
        _ = try repository.saveSnapshotLabelAndNote(snapshotID: snapshot, displayName: "  Label  ", userNote: "First note")
        let saved = try repository.saveSnapshotLabelAndNote(snapshotID: snapshot, displayName: "  Label  ", userNote: "")

        XCTAssertEqual(saved.displayName, "  Label  ", "user labels are not silently trimmed or normalized")
        XCTAssertNil(saved.userNote)
        XCTAssertNil(try database.scalar("SELECT user_note FROM snapshots WHERE id = ?", bindings: [.integer(snapshot.rawValue)])?.stringValue)
        XCTAssertNil(try repository.snapshotLabelAndNote(for: snapshot).userNote)
    }

    func testBlankAndOversizedSnapshotMetadataIsRejectedWithoutMutation() throws {
        let snapshot = try makeUserSnapshot(volume: 1, session: 1, name: "Original")
        let before = try repository.snapshotLabelAndNote(for: snapshot)

        XCTAssertThrowsError(try repository.saveSnapshotLabelAndNote(snapshotID: snapshot, displayName: " \n\t ", userNote: nil)) {
            XCTAssertEqual($0 as? SnapshotCollectionError, .blankSnapshotDisplayName)
        }
        XCTAssertThrowsError(try repository.saveSnapshotLabelAndNote(
            snapshotID: snapshot,
            displayName: String(repeating: "L", count: SnapshotCollectionRepository.maximumSnapshotDisplayNameCharacters + 1),
            userNote: nil
        )) {
            XCTAssertEqual($0 as? SnapshotCollectionError, .snapshotDisplayNameTooLong(maximumCharacters: 120))
        }
        XCTAssertThrowsError(try repository.saveSnapshotLabelAndNote(
            snapshotID: snapshot,
            displayName: "Original",
            userNote: String(repeating: "N", count: SnapshotCollectionRepository.maximumSnapshotUserNoteCharacters + 1)
        )) {
            XCTAssertEqual($0 as? SnapshotCollectionError, .snapshotUserNoteTooLong(maximumCharacters: 2_000))
        }
        XCTAssertEqual(try repository.snapshotLabelAndNote(for: snapshot), before)

        let model = SnapshotCollectionsModel(database: database)
        model.reload()
        model.selectedSnapshotID = snapshot
        model.beginEditingSelectedSnapshotMetadata()
        model.snapshotLabelDraft = " \t\n "
        XCTAssertFalse(model.saveSnapshotLabelAndNote())
        XCTAssertTrue(model.isShowingSnapshotMetadataEditor)
        XCTAssertEqual(model.snapshotMetadataEditorError, "Enter a snapshot label.",
                       "validation is shown near the editable draft")
        XCTAssertEqual(model.snapshotLabelDraft, " \t\n ", "validation failure retains the user's draft")
        XCTAssertEqual(try repository.snapshotLabelAndNote(for: snapshot), before)
    }

    func testMissingAndTransientSnapshotsAreRejectedForMetadataReadAndSave() throws {
        let missing = SnapshotID(rawValue: 999_999)
        XCTAssertThrowsError(try repository.snapshotLabelAndNote(for: missing)) {
            XCTAssertEqual($0 as? SnapshotCollectionError, .snapshotNotFound(missing))
        }
        XCTAssertThrowsError(try repository.saveSnapshotLabelAndNote(snapshotID: missing, displayName: "Label", userNote: nil)) {
            XCTAssertEqual($0 as? SnapshotCollectionError, .snapshotNotFound(missing))
        }

        let transient = try SyntheticSnapshot.createSnapshot(
            database: database, volumeID: 1, session: 1, kind: .transient, name: "Transient"
        )
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: transient, entries: [
            SyntheticSnapshot.root(id: 901, name: "Transient")
        ])
        try SyntheticSnapshot.complete(database: database, snapshotID: transient)
        let transientMetadataOperations: [() throws -> Void] = [
            { try self.repository.snapshotLabelAndNote(for: transient); return () },
            { try self.repository.saveSnapshotLabelAndNote(snapshotID: transient, displayName: "Changed", userNote: nil); return () }
        ]
        for operation in transientMetadataOperations {
            XCTAssertThrowsError(try operation()) {
                XCTAssertEqual($0 as? SnapshotCollectionError, .snapshotNotUser(transient))
            }
        }
    }

    func testCancelDoesNotWriteAndFailedSaveRetainsDraftAndStoredValues() throws {
        let snapshot = try makeUserSnapshot(volume: 1, session: 1, name: "Stored Label")
        _ = try repository.saveSnapshotLabelAndNote(snapshotID: snapshot, displayName: "Stored Label", userNote: "Stored note")
        var successfulRefreshes = 0
        let model = SnapshotCollectionsModel(database: database, onMetadataSaved: { successfulRefreshes += 1 })
        model.reload()
        model.selectedSnapshotID = snapshot
        model.beginEditingSelectedSnapshotMetadata()
        model.snapshotLabelDraft = "Cancelled draft"
        model.snapshotUserNoteDraft = "Cancelled note"
        model.cancelSnapshotMetadataEdit()
        XCTAssertFalse(model.isShowingSnapshotMetadataEditor)
        XCTAssertEqual(try repository.snapshotLabelAndNote(for: snapshot).displayName, "Stored Label")
        XCTAssertEqual(try repository.snapshotLabelAndNote(for: snapshot).userNote, "Stored note")

        model.beginEditingSelectedSnapshotMetadata()
        model.snapshotLabelDraft = "Failed draft"
        model.snapshotUserNoteDraft = "Failed note"
        try database.execute(
            """
            CREATE TRIGGER reject_snapshot_metadata_edit
            BEFORE UPDATE OF display_name, user_note ON snapshots
            BEGIN SELECT RAISE(ABORT, 'private sqlite detail'); END
            """
        )
        XCTAssertFalse(model.saveSnapshotLabelAndNote(), "a failed catalog write must not report success")
        XCTAssertTrue(model.isShowingSnapshotMetadataEditor)
        XCTAssertEqual(model.snapshotLabelDraft, "Failed draft")
        XCTAssertEqual(model.snapshotUserNoteDraft, "Failed note")
        XCTAssertNotNil(model.snapshotMetadataEditorError)
        XCTAssertFalse(model.snapshotMetadataEditorError?.contains("private sqlite detail") ?? true)
        XCTAssertEqual(try repository.snapshotLabelAndNote(for: snapshot).displayName, "Stored Label")
        XCTAssertEqual(try repository.snapshotLabelAndNote(for: snapshot).userNote, "Stored note")
        XCTAssertEqual(successfulRefreshes, 0, "failure and cancellation do not refresh as if saved")
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
        XCTAssertTrue(source.contains(".onAppear { model.refresh() }"), "Recent Captures reloads history when visited")
        XCTAssertTrue(source.contains(".onAppear {\n            model.refresh()\n            if selectedSnapshotID == nil"),
                       "Home reloads history when visited")

        XCTAssertTrue(source.contains("Move to Collection"))
        XCTAssertTrue(source.contains("Create Collection"))
        XCTAssertTrue(source.contains(".keyboardShortcut(.defaultAction)"))
        XCTAssertTrue(source.contains(".keyboardShortcut(.cancelAction)"))
        XCTAssertTrue(source.contains("accessibilityLabel(\"Create a new Collection\")"))
        XCTAssertTrue(source.contains("accessibilityLabel(\"Move selected snapshot to a Collection\")"))
        XCTAssertTrue(source.contains("Label(\"Edit Label & Note\""))
        XCTAssertTrue(source.contains("Open All Snapshots or Unsorted, select a capture, then move it into this Collection."))
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
        _ = try makeUserSnapshot(volume: 2, session: 1, name: "Card B")
        _ = try repository.saveSnapshotLabelAndNote(
            snapshotID: snapshot,
            displayName: "Card A",
            userNote: "Keep this capture for the next review"
        )
        try repository.assign(snapshotID: snapshot, to: assignedCollection.id)

        let appModel = ApplicationModel(catalogForTesting: database)
        let model = SnapshotCollectionsModel(database: database, onMetadataSaved: appModel.refresh)
        model.reload()
        model.selectedSnapshotID = snapshot
        let shell = FSDAppShellView(
            model: appModel,
            initialDestination: .collections,
            collectionsModel: model
        )
        let hosting = NSHostingView(rootView: shell)
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
            .appendingPathComponent(".ai-scratch/task052/screenshots", isDirectory: true)
        try FileManager.default.createDirectory(at: captureDirectory, withIntermediateDirectories: true)

        func capture(_ targetWindow: NSWindow, name: String, width: CGFloat? = nil) throws {
            if let width {
                targetWindow.setContentSize(NSSize(width: width, height: 720))
            }
            targetWindow.contentView?.layoutSubtreeIfNeeded()
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
            let content = try XCTUnwrap(targetWindow.contentView)
            if let width {
                XCTAssertEqual(Int(content.bounds.width), Int(width), "the FSD shell fills the window at \(Int(width)) pt")
            }
            let bitmap = try XCTUnwrap(content.bitmapImageRepForCachingDisplay(in: content.bounds))
            content.cacheDisplay(in: content.bounds, to: bitmap)
            let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
            try png.write(to: captureDirectory.appendingPathComponent(name), options: .atomic)
            print("COLLECTIONS_GUI_CAPTURE path=\(captureDirectory.appendingPathComponent(name).path)")
        }

        try capture(window, name: "collections-selected-1120.png", width: 1120)
        try capture(window, name: "collections-selected-1330.png", width: 1330)
        try capture(window, name: "collections-selected-1440.png", width: 1440)

        model.beginEditingSelectedSnapshotMetadata()
        XCTAssertTrue(model.isShowingSnapshotMetadataEditor)
        XCTAssertEqual(model.snapshotLabelDraft, "Card A", "the editor loads the persisted label")
        XCTAssertEqual(model.snapshotUserNoteDraft, "Keep this capture for the next review", "the editor loads the persisted note")
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        let editorWindow = try XCTUnwrap(window.attachedSheet, "the editor is a native sheet attached to the FSD window")
        try capture(editorWindow, name: "edit-label-note-populated.png")

        model.snapshotLabelDraft = "Card A — Review Set"
        model.snapshotUserNoteDraft = "Use this label in Home and Recent Captures"
        XCTAssertTrue(model.saveSnapshotLabelAndNote())
        XCTAssertEqual(appModel.history.first(where: { $0.id == snapshot })?.displayName, "Card A — Review Set",
                       "a successful editor save refreshes the app's cached history")
        XCTAssertNil(appModel.browser, "saving metadata does not auto-open a snapshot or start another action")
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        try capture(window, name: "snapshot-updated-after-save-1120.png", width: 1120)

        let emptyID = try XCTUnwrap(try repository.listCollections().collections.first { $0.name == "Empty Reel" }?.id)
        model.select(.collection(id: emptyID, name: "Empty Reel"))
        XCTAssertTrue(model.snapshots.isEmpty)
        try capture(window, name: "collections-empty-reel-guidance-1120.png")
        XCTAssertEqual(
            model.selectedFilter.title,
            "Empty Reel",
            "the existing Collection stays selected while the guidance is shown"
        )
        model.select(.collection(id: assignedCollection.id, name: assignedCollection.name))
        model.selectedSnapshotID = snapshot
        model.beginEditingSelectedSnapshotMetadata()
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        let narrowEditorWindow = try XCTUnwrap(window.attachedSheet)
        try capture(narrowEditorWindow, name: "edit-label-note-narrow-1120.png")
        model.cancelSnapshotMetadataEdit()
    }

    func testMetadataEditorUsesAccessibleKeyboardSaveCancelAndShowsUserNoteAsOrganizationMetadata() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: repoRoot.appendingPathComponent("FSD/UI/ComparisonSharedViews.swift"),
            encoding: .utf8
        )
        XCTAssertTrue(source.contains(".accessibilityLabel(\"Edit selected snapshot label and note\")"))
        XCTAssertTrue(source.contains(".accessibilityLabel(\"Snapshot label\")"))
        XCTAssertTrue(source.contains(".accessibilityLabel(\"Snapshot note (optional)\")"))
        XCTAssertTrue(source.contains(".accessibilityLabel(\"Cancel editing snapshot label and note\")"))
        XCTAssertTrue(source.contains(".accessibilityLabel(\"Save snapshot label and note\")"))
        XCTAssertTrue(source.contains(".keyboardShortcut(.cancelAction)"))
        XCTAssertTrue(source.contains(".keyboardShortcut(.defaultAction)"))
        XCTAssertTrue(source.contains(".onSubmit(save)"), "Return submits the label field")
        XCTAssertTrue(source.contains(".disabled(model.isSavingSnapshotMetadata)"), "duplicate Save activation is disabled")
        XCTAssertTrue(source.contains("Text(\"User note: \\(note)\")"), "the note is visibly distinguished from capture facts")
    }
}
