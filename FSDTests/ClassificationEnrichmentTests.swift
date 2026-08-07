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
            classifiedAt: "2026-08-05T10:00:00Z"
        ))

        XCTAssertEqual(try repository.classification(for: entryID), stored)
        XCTAssertEqual(try repository.latestClassifications(for: [1, entryID]).count, 1)
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
            entryID: entryID, classificationRunID: "page-run", detectedType: "text"
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
            entryID: 9999, classificationRunID: "missing"
        ))) { error in
            XCTAssertEqual(error as? EntryClassificationRepositoryError, .entryNotFound(9999))
        }

        _ = try repository.append(EntryClassificationInput(entryID: entryID, classificationRunID: "same-run"))
        XCTAssertThrowsError(try repository.append(EntryClassificationInput(entryID: entryID, classificationRunID: "same-run"))) { error in
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
            detectedType: "plain text"
        ))

        XCTAssertEqual(try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: snapshotID), beforeEntries)
        XCTAssertEqual(try EntrySnapshotProbe.snapshotFingerprint(database: database, snapshotID: snapshotID), beforeSnapshot)
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
    }

    func testDisabledProviderLeavesClassificationAbsent() throws {
        let service = ClassificationEnrichmentService(
            database: database,
            provider: DisabledFileClassificationProvider()
        )
        XCTAssertNil(try service.enrich(entryID: entryID, classificationRunID: "disabled-run"))
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
    }

    func testProviderFailureStoresOnlyBoundedTypedStatus() throws {
        let service = ClassificationEnrichmentService(database: database, provider: HostileDiagnosticProvider())
        let result = try XCTUnwrap(try service.enrich(entryID: entryID, classificationRunID: "failed-run"))
        XCTAssertEqual(result.detectionStatus, .failed)
        XCTAssertNil(result.detectedType)
        XCTAssertNil(result.mimeType)
        XCTAssertNil(result.classifiedAt)
        XCTAssertFalse(result.statusLabel.contains("hostile"))
        XCTAssertFalse(result.statusLabel.contains("stack"))
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

private struct HostileDiagnosticProvider: LocalFileClassificationProvider {
    let providerIdentifier = "hostile-test-provider"
    let detectorVersion: String? = "test-detector"
    let modelVersion: String? = "test-model"

    func classify(_ request: LocalClassificationRequest) throws -> LocalClassificationProviderResult {
        throw NSError(domain: "hostile", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "hostile stack trace and absolute path /private/test"
        ])
    }
}
