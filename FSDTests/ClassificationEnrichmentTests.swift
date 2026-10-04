import XCTest
@testable import FSD

final class ClassificationEnrichmentTests: XCTestCase {
    private var directory: URL!
    private var database: CatalogDatabase!
    private var snapshotID: SnapshotID!
    private let entryID: Int64 = 2

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-Classification-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        database = try CatalogDatabase(
            url: directory.appendingPathComponent("catalog.sqlite3"),
            schemaURL: CatalogSchemaFixture.canonicalSchemaURL
        )
        snapshotID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 1, session: 1)
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: snapshotID, entries: [
            SyntheticSnapshot.root(id: 1),
            SyntheticSnapshot.SeedEntry(
                id: entryID, parentID: 1, relativePath: "report.txt", name: "report.txt",
                logicalSizeBytes: 12, allocatedSizeBytes: 4096
            ),
            SyntheticSnapshot.SeedEntry(
                id: 3, parentID: 1, relativePath: "photo.jpg", name: "photo.jpg"
            )
        ])
        try SyntheticSnapshot.complete(database: database, snapshotID: snapshotID)
    }

    override func tearDownWithError() throws {
        database?.close()
        database = nil
        try? FileManager.default.removeItem(at: directory)
        directory = nil
        snapshotID = nil
    }

    func testClassifiedInputRequiresProviderIdentity() throws {
        let repository = EntryClassificationRepository(database: database)
        XCTAssertThrowsError(try repository.append(EntryClassificationInput(
            entryID: entryID, classificationRunID: "missing-provider"
        ))) { error in
            guard case .invalidInput = error as? EntryClassificationRepositoryError else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
    }

    func testClassifiedProviderIdentityRejectsBlankAndOverlongValues() throws {
        let repository = EntryClassificationRepository(database: database)
        for (index, provider) in ["", " ", "\t\n", String(repeating: "é", count: 257)].enumerated() {
            XCTAssertThrowsError(try repository.append(EntryClassificationInput(
                entryID: entryID, classificationRunID: "invalid-provider-\(index)",
                providerIdentifier: provider
            ))) { error in
                guard case .invalidInput = error as? EntryClassificationRepositoryError else {
                    return XCTFail("Unexpected error: \(error)")
                }
            }
        }
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
        let boundary = String(repeating: "é", count: 256)
        let stored = try repository.append(EntryClassificationInput(
            entryID: entryID, classificationRunID: "provider-length-boundary", providerIdentifier: boundary
        ))
        XCTAssertEqual(stored.providerIdentifier, boundary)
        XCTAssertEqual(try repository.classification(for: entryID), stored)
        let padded = try repository.append(EntryClassificationInput(
            entryID: entryID, classificationRunID: "provider-with-padding", providerIdentifier: " provider "
        ))
        XCTAssertEqual(padded.providerIdentifier, " provider ")
    }

    func testNullableInputRoundTripsWithoutFabricatedProvenance() throws {
        let repository = EntryClassificationRepository(database: database)
        let stored = try repository.append(EntryClassificationInput(
            entryID: entryID, classificationRunID: "nullable", detectionStatus: nil
        ))
        XCTAssertNil(stored.providerIdentifier)
        XCTAssertNil(stored.detectorVersion)
        XCTAssertNil(stored.modelVersion)
        XCTAssertEqual(try repository.history(for: entryID), [stored])
        XCTAssertEqual(try repository.latestClassifications(for: [entryID])[entryID], stored)
    }

    func testProviderHistoryRemainsAppendOnlyAndLatestUsesInsertionOrder() throws {
        let repository = EntryClassificationRepository(database: database)
        let first = try repository.append(EntryClassificationInput(
            entryID: entryID, classificationRunID: "history-1", detectorVersion: "detector-A",
            modelVersion: "model-A", providerIdentifier: "provider-A", classifiedAt: "2026-10-04"
        ))
        let second = try repository.append(EntryClassificationInput(
            entryID: entryID, classificationRunID: "history-2", detectorVersion: "detector-A",
            modelVersion: "model-A", providerIdentifier: "provider-B", classifiedAt: "2026-08-01"
        ))
        let other = try repository.append(EntryClassificationInput(
            entryID: 3, classificationRunID: "history-3", detectorVersion: "detector-B",
            modelVersion: "model-C", providerIdentifier: "provider-A"
        ))
        XCTAssertEqual(try repository.history(for: entryID), [second, first])
        XCTAssertEqual(try repository.history(for: entryID, limit: 1), [second])
        XCTAssertEqual(try repository.classification(for: entryID), second)
        XCTAssertEqual(try repository.latestClassifications(for: [entryID, 3]), [entryID: second, 3: other])
        XCTAssertEqual(try repository.latestClassifications(for: [entryID, entryID, 1]), [entryID: second])
        XCTAssertTrue(try repository.latestClassifications(for: []).isEmpty)
        XCTAssertThrowsError(try repository.append(EntryClassificationInput(
            entryID: entryID, classificationRunID: "history-1", providerIdentifier: "replacement"
        ))) { error in
            XCTAssertEqual(error as? EntryClassificationRepositoryError,
                           .duplicateRun(entryID: self.entryID, classificationRunID: "history-1"))
        }
        XCTAssertEqual(try repository.history(for: entryID), [second, first])
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 3)
    }

    func testAbsentClassificationBrowsesWithNeutralStateAndExportsDeterministically() throws {
        let details = try XCTUnwrap(
            try SnapshotTreeDataSource(database: database, snapshotID: snapshotID).details(for: entryID)
        )
        XCTAssertNil(details.classification)
        XCTAssertEqual(details.classification?.statusLabel, nil)

        var first = ""
        var second = ""
        _ = try JSONSnapshotExporter(database: database).write(snapshotID: snapshotID) { first += $0 }
        _ = try JSONSnapshotExporter(database: database).write(snapshotID: snapshotID) { second += $0 }
        XCTAssertEqual(first, second)
        XCTAssertFalse(first.contains("classification"))
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
    }

    func testStoredClassificationRoundTripsAndDetailReadIsBounded() throws {
        let repository = EntryClassificationRepository(database: database)
        let stored = try repository.append(EntryClassificationInput(
            entryID: entryID,
            classificationRunID: "test-run-1",
            detectedType: "text",
            mimeType: "text/plain",
            confidence: 0.875,
            detectorVersion: "adapter-test-1",
            modelVersion: "fixture-model-1",
            providerIdentifier: "fixture-provider-1",
            classifiedAt: "2026-08-05T10:00:00Z"
        ))

        XCTAssertEqual(try repository.classification(for: entryID), stored)
        XCTAssertEqual(try repository.latestClassifications(for: [1, entryID]).count, 1)
        XCTAssertEqual(stored.detectorVersion, "adapter-test-1")
        XCTAssertEqual(stored.modelVersion, "fixture-model-1")
        XCTAssertEqual(stored.providerIdentifier, "fixture-provider-1")
        XCTAssertEqual(stored.statusLabel, "Inferred file type")
        XCTAssertEqual(stored.confidenceLabel, "87.5%")

        let tree = SnapshotTreeDataSource(database: database, snapshotID: snapshotID)
        tree.resetInstrumentation()
        let details = try XCTUnwrap(try tree.details(for: entryID))
        XCTAssertEqual(details.classification, stored)
        XCTAssertEqual(tree.queryCount, 2, "entry details plus one classification query")
        XCTAssertEqual(tree.rowsFetched, 2)
    }

    func testVisiblePageClassificationReadUsesOneBoundedQuery() throws {
        let repository = EntryClassificationRepository(database: database)
        _ = try repository.append(EntryClassificationInput(
            entryID: entryID, classificationRunID: "page-run", detectedType: "text", providerIdentifier: "fixture-provider"
        ))
        XCTAssertEqual(try repository.latestClassifications(for: [entryID]).count, 1)
        XCTAssertThrowsError(try repository.latestClassifications(
            for: Array(1...501).map(Int64.init)
        )) { error in
            guard case .invalidInput = error as? EntryClassificationRepositoryError else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testWriterRejectsUnknownAndDuplicateRuns() throws {
        let repository = EntryClassificationRepository(database: database)
        XCTAssertThrowsError(try repository.append(EntryClassificationInput(
            entryID: 9999, classificationRunID: "missing", providerIdentifier: "fixture-provider"
        ))) { error in
            XCTAssertEqual(error as? EntryClassificationRepositoryError, .entryNotFound(9999))
        }

        _ = try repository.append(EntryClassificationInput(entryID: entryID, classificationRunID: "same-run", providerIdentifier: "fixture-provider"))
        XCTAssertThrowsError(try repository.append(EntryClassificationInput(entryID: entryID, classificationRunID: "same-run", providerIdentifier: "fixture-provider"))) { error in
            XCTAssertEqual(
                error as? EntryClassificationRepositoryError,
                .duplicateRun(entryID: self.entryID, classificationRunID: "same-run")
            )
        }
    }

    func testExplicitEnrichmentPreservesSnapshotAndEntryImmutability() throws {
        let beforeEntries = try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: snapshotID)
        let beforeSnapshot = try EntrySnapshotProbe.snapshotFingerprint(database: database, snapshotID: snapshotID)
        let repository = EntryClassificationRepository(database: database)

        _ = try repository.append(EntryClassificationInput(
            entryID: entryID,
            classificationRunID: "immutable-test",
            detectedType: "plain text",
            providerIdentifier: "fixture-provider"
        ))

        XCTAssertEqual(try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: snapshotID), beforeEntries)
        XCTAssertEqual(try EntrySnapshotProbe.snapshotFingerprint(database: database, snapshotID: snapshotID), beforeSnapshot)
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
    }

    func testOrdinaryCaptureSearchAndExportDoNotCreateClassificationRows() throws {
        let source = directory.appendingPathComponent("generated-source", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try Data("metadata-only".utf8).write(to: source.appendingPathComponent("capture.txt"))
        let captured = try SnapshotScanner(database: database).capture(root: source)

        _ = try MetadataSearchService(database: database).search(
            MetadataSearchQuery(text: "capture", field: .nameOrPath), in: captured.id
        )
        var exported = ""
        _ = try JSONSnapshotExporter(database: database).write(snapshotID: captured.id) { exported += $0 }
        XCTAssertFalse(exported.contains("classification"))
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
    }
}
