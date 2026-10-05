import XCTest
@testable import FSD

final class JSONExportTests: XCTestCase {
    private var directory: URL!
    private var source: URL!
    private var database: CatalogDatabase!
    private var snapshotID: SnapshotID!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-Export-\(UUID().uuidString)", isDirectory: true)
        source = directory.appendingPathComponent("source", isDirectory: true)
        try FileManager.default.createDirectory(at: source.appendingPathComponent("Nested"), withIntermediateDirectories: true)
        database = try CatalogDatabase(
            url: directory.appendingPathComponent("catalog.sqlite3"),
            schemaURL: CatalogSchemaFixture.canonicalSchemaURL
        )
        try Data("abcdef".utf8).write(to: source.appendingPathComponent("Nested/leaf.txt"))
        try Data("x".utf8).write(to: source.appendingPathComponent("Café \"quoted\".txt"))
        try FileManager.default.createSymbolicLink(
            at: source.appendingPathComponent("link"),
            withDestinationURL: source.appendingPathComponent("Nested/leaf.txt")
        )
        snapshotID = try SnapshotScanner(database: database).capture(root: source).id
    }

    override func tearDownWithError() throws {
        database?.close()
        database = nil
        try? FileManager.default.removeItem(at: directory)
        directory = nil
        source = nil
        snapshotID = nil
    }

    func testExportIsDeterministic() throws {
        let first = try exportString()
        let second = try exportString()
        XCTAssertEqual(first, second)

        // A different page size must not change a byte of the output.
        var paged = ""
        _ = try JSONSnapshotExporter(database: database, pageSize: 1).write(snapshotID: snapshotID) { paged += $0 }
        XCTAssertEqual(first, paged)
    }

    func testExportIsValidJSONWithTheExpectedShape() throws {
        let text = try exportString()
        let data = try XCTUnwrap(text.data(using: .utf8))
        let object = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(object["format"] as? String, JSONSnapshotExporter.formatIdentifier)
        XCTAssertEqual(object["formatVersion"] as? Int, 1)
        XCTAssertEqual(object["catalogSchemaVersion"] as? Int, Int(CatalogMigrations.currentVersion))
        XCTAssertEqual(object["contentVerified"] as? Bool, false)

        let snapshot = try XCTUnwrap(object["snapshot"] as? [String: Any])
        XCTAssertEqual(snapshot["status"] as? String, "complete")
        XCTAssertEqual(snapshot["isPartialCapture"] as? Bool, false)
        XCTAssertEqual(snapshot["normalizationVersion"] as? String, NormalizationVersion.current.rawValue)

        let sourceAtCapture = try XCTUnwrap(snapshot["sourceAtCapture"] as? [String: Any])
        XCTAssertEqual(sourceAtCapture["isFullyRecorded"] as? Bool, true)
        XCTAssertNotNil(sourceAtCapture["volumeIdentifier"] as? String)

        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let paths = entries.compactMap { $0["relativePath"] as? String }
        XCTAssertEqual(paths, ["", "Café \"quoted\".txt", "Nested", "Nested/leaf.txt", "link"])
        XCTAssertEqual(paths, paths.sorted(), "entries are exported in a deterministic path order")
        let symlink = try XCTUnwrap(entries.first { $0["itemType"] as? String == "symlink" })
        XCTAssertNotNil(symlink["symlinkTarget"] as? String)
    }

    func testExportIsByteIdenticalBeforeAndAfterClassificationEnrichment() throws {
        // §9: the export is classification-neutral. Enrichment rows exist in the
        // catalog, yet the exported bytes, the format version and the catalog
        // schema version are unchanged, and no classification key appears.
        let before = try exportString()
        let beforeObject = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: try XCTUnwrap(before.data(using: .utf8))) as? [String: Any]
        )
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)

        let entryID = try XCTUnwrap(try database.scalar(
            "SELECT id FROM entries WHERE snapshot_id = ? AND relative_path = 'Nested/leaf.txt'",
            bindings: [.integer(snapshotID.rawValue)]
        )?.int64Value)
        let repository = EntryClassificationRepository(database: database)
        _ = try repository.append(EntryClassificationInput(
            entryID: entryID, classificationRunID: "export-neutrality-run",
            detectedType: "text/plain", mimeType: "text/plain", confidence: 0.5,
            detectionStatus: .classified, detectorVersion: "export-detector",
            modelVersion: "export-model", providerIdentifier: "export-fixture-provider",
            classifiedAt: "2026-10-06T00:00:00Z"
        ))
        _ = try repository.append(EntryClassificationInput(
            entryID: entryID, classificationRunID: "export-neutrality-failed-run",
            detectionStatus: .failed, providerIdentifier: "export-fixture-provider"
        ))
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 2,
                       "enrichment rows exist and are visible to the exporter's own catalog")

        let after = try exportString()
        let afterObject = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: try XCTUnwrap(after.data(using: .utf8))) as? [String: Any]
        )
        XCTAssertEqual(after, before, "classification enrichment must not change one exported byte")
        XCTAssertEqual(afterObject["format"] as? String, JSONSnapshotExporter.formatIdentifier)
        XCTAssertEqual(afterObject["formatVersion"] as? Int, 1, "the export format version is unchanged")
        XCTAssertEqual(afterObject["formatVersion"] as? Int, beforeObject["formatVersion"] as? Int)
        XCTAssertEqual(afterObject["catalogSchemaVersion"] as? Int, beforeObject["catalogSchemaVersion"] as? Int)
        XCTAssertNil(afterObject["classifications"])
        XCTAssertFalse(after.contains("classification"))
        XCTAssertFalse(after.contains("export-fixture-provider"))
        XCTAssertFalse(after.contains("export-detector"))
    }

    func testExportStatesContentIsNotVerifiedAndCarriesNoPayloadOrClassification() throws {
        let text = try exportString()
        let object = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: try XCTUnwrap(text.data(using: .utf8))) as? [String: Any]
        )

        XCTAssertTrue(text.contains("Content Not Verified"))
        XCTAssertTrue(text.contains("\"contentVerified\": false"))
        XCTAssertFalse(text.contains("abcdef"), "the export must not contain any file content")

        let forbiddenKeys: Set<String> = [
            "hash", "sha256", "md5", "checksum", "classification", "detectedType",
            "mimeType", "confidence", "modelVersion", "payload", "sampledBytes"
        ]
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        for entry in entries {
            XCTAssertTrue(
                Set(entry.keys).isDisjoint(with: forbiddenKeys),
                "entry carries a forbidden key: \(Set(entry.keys).intersection(forbiddenKeys))"
            )
        }
        let snapshot = try XCTUnwrap(object["snapshot"] as? [String: Any])
        XCTAssertTrue(Set(snapshot.keys).isDisjoint(with: forbiddenKeys))
        XCTAssertNil(object["classifications"])
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM entry_classifications")?.int64Value, 0)
    }

    func testExportEscapesQuotesAndUnicodeCorrectly() throws {
        let text = try exportString()
        XCTAssertTrue(text.contains("Café \\\"quoted\\\".txt"))
        let data = try XCTUnwrap(text.data(using: .utf8))
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: data))
    }

    func testExportRunsOfflineAndDoesNotMutateTheSnapshot() throws {
        let before = try snapshotFingerprint()
        try FileManager.default.removeItem(at: source)

        let text = try exportString()

        XCTAssertTrue(text.contains("Nested/leaf.txt"))
        XCTAssertEqual(try snapshotFingerprint(), before)
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
    }

    func testExportToFileReportsWhatItWrote() throws {
        let destination = directory.appendingPathComponent("snapshot.json")
        let summary = try JSONSnapshotExporter(database: database).export(snapshotID: snapshotID, to: destination)

        XCTAssertEqual(summary.entryCount, 5)
        XCTAssertEqual(summary.issueCount, 0)
        let written = try String(contentsOf: destination, encoding: .utf8)
        XCTAssertEqual(Int64(written.utf8.count), summary.byteCount)
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: try XCTUnwrap(written.data(using: .utf8))))
    }

    func testExportIncludesScanIssuesAndPartialState() throws {
        let repository = SnapshotRepository(database: database)
        try repository.createVolume(id: 55, displayName: "Partial")
        let partial = try repository.createSnapshot(volumeID: 55, sessionNumber: 1, scanRootName: "Partial")
        _ = try repository.addRoot(to: partial, name: "Partial")
        try database.execute(
            """
            INSERT INTO scan_issues (snapshot_id, relative_path, severity, source, message, was_skipped, created_at)
            VALUES (?, 'locked', 'warning', 'scanner', 'Permission denied', 1, CURRENT_TIMESTAMP)
            """,
            bindings: [.integer(partial.rawValue)]
        )
        try repository.interrupt(partial)

        var text = ""
        _ = try JSONSnapshotExporter(database: database).write(snapshotID: partial) { text += $0 }
        let object = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: try XCTUnwrap(text.data(using: .utf8))) as? [String: Any]
        )
        let snapshot = try XCTUnwrap(object["snapshot"] as? [String: Any])
        XCTAssertEqual(snapshot["isPartialCapture"] as? Bool, true)
        XCTAssertEqual(snapshot["status"] as? String, "interrupted")
        let issues = try XCTUnwrap(object["scanIssues"] as? [[String: Any]])
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues[0]["message"] as? String, "Permission denied")
    }

    func testUnknownSnapshotIsRejected() {
        XCTAssertThrowsError(
            try JSONSnapshotExporter(database: database).write(snapshotID: SnapshotID(rawValue: 99_999)) { _ in }
        ) { error in
            guard case JSONSnapshotExportError.snapshotNotFound = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    private func exportString() throws -> String {
        var text = ""
        _ = try JSONSnapshotExporter(database: database).write(snapshotID: snapshotID) { text += $0 }
        return text
    }

    /// Explicitly ordered, because a `DatabaseRow` is a dictionary and its
    /// description would differ between two identical reads.
    private func snapshotFingerprint() throws -> String {
        let row = try XCTUnwrap(try database.query(
            "SELECT status, updated_at, total_files, total_folders, total_logical_bytes, warning_count FROM snapshots WHERE id = ?",
            bindings: [.integer(snapshotID.rawValue)]
        ).first)
        let fields = ["status", "updated_at", "total_files", "total_folders", "total_logical_bytes", "warning_count"]
            .map { "\($0)=\(String(describing: row[$0]))" }
        let entries = try database.scalar(
            "SELECT COUNT(*) FROM entries WHERE snapshot_id = ?", bindings: [.integer(snapshotID.rawValue)]
        )?.int64Value ?? -1
        return (fields + ["entries=\(entries)"]).joined(separator: "|")
    }
}
