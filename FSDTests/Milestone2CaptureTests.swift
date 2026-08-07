import XCTest
@testable import FSD

final class Milestone2CaptureTests: XCTestCase {
    private var directory: URL!
    private var source: URL!
    private var database: CatalogDatabase!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("FSD-M2-\(UUID().uuidString)", isDirectory: true)
        source = directory.appendingPathComponent("source", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        let schemaURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("docs/database/schema.sql")
        database = try CatalogDatabase(url: directory.appendingPathComponent("catalog.sqlite3"), schemaURL: schemaURL)
    }

    override func tearDownWithError() throws {
        database?.close()
        database = nil
        try FileManager.default.removeItem(at: directory)
        directory = nil
        source = nil
    }

    func testNativeProviderStreamsNestedMetadataAndDoesNotFollowSymlink() throws {
        let nested = source.appendingPathComponent("Folder", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try Data().write(to: nested.appendingPathComponent("empty.txt"))
        try Data("outside".utf8).write(to: directory.appendingPathComponent("outside.txt"))
        try Data("inside".utf8).write(to: source.appendingPathComponent("café.txt"))
        try FileManager.default.createDirectory(at: source.appendingPathComponent("Bundle.app"), withIntermediateDirectories: true)
        try Data("not enumerated as a package child".utf8).write(to: source.appendingPathComponent("Bundle.app/child.txt"))
        try FileManager.default.createSymbolicLink(at: source.appendingPathComponent("outside-link"), withDestinationURL: directory.appendingPathComponent("outside.txt"))
        try FileManager.default.createSymbolicLink(at: source.appendingPathComponent("broken-link"), withDestinationURL: source.appendingPathComponent("missing"))

        let descriptor = try FilesystemDetector().detect(root: source)
        XCTAssertEqual(descriptor.rootURL.path, source.resolvingSymlinksInPath().path)
        XCTAssertFalse(descriptor.volumeIdentifier.isEmpty)
        XCTAssertFalse(descriptor.filesystemType.isEmpty)
        XCTAssertTrue([.sensitive, .insensitive, .unknown].contains(descriptor.sourceCaseSensitivity))
        let provider = NativeMountedProvider(descriptor: descriptor)
        var entries: [MetadataEntry] = []
        let result = try provider.enumerate(
            onEntry: { entries.append($0) }, onIssue: { _ in }, onProgress: { _ in }, isCancelled: { false }
        )

        XCTAssertFalse(result.wasCancelled)
        XCTAssertEqual(entries.filter { $0.relativePath.isEmpty }.count, 1)
        XCTAssertTrue(entries.contains { $0.relativePath == "Folder/empty.txt" && $0.itemKind == .file && $0.logicalSizeBytes == 0 })
        XCTAssertTrue(entries.contains { $0.relativePath == "café.txt" && $0.casePreservingPath == "café.txt" })
        XCTAssertTrue(entries.contains { $0.relativePath == "outside-link" && $0.itemKind == .symlink })
        XCTAssertTrue(entries.contains { $0.relativePath == "broken-link" && $0.itemKind == .symlink })
        XCTAssertTrue(entries.contains { $0.relativePath == "Bundle.app" && $0.itemKind == .package })
        XCTAssertFalse(entries.contains { $0.relativePath == "Bundle.app/child.txt" })
        XCTAssertFalse(entries.contains { $0.relativePath == "outside.txt" })
    }

    func testCapturePersistsOneRootParentLinksTotalsAndNoClassificationRows() throws {
        let child = source.appendingPathComponent("A", isDirectory: true)
        try FileManager.default.createDirectory(at: child, withIntermediateDirectories: true)
        try Data("12345".utf8).write(to: child.appendingPathComponent("file.txt"))
        let scanner = SnapshotScanner(database: database, batchSize: 2)

        let record = try scanner.capture(root: source)
        XCTAssertEqual(record.status, .complete)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM entries WHERE snapshot_id = ? AND parent_id IS NULL", bindings: [.integer(record.id.rawValue)])?.int64Value, 1)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM entries WHERE snapshot_id = ?", bindings: [.integer(record.id.rawValue)])?.int64Value, 3)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM entries WHERE snapshot_id = ? AND relative_path = 'A/file.txt' AND parent_id = (SELECT id FROM entries WHERE snapshot_id = ? AND relative_path = 'A')", bindings: [.integer(record.id.rawValue), .integer(record.id.rawValue)])?.int64Value, 1)
        XCTAssertEqual(try database.scalar("SELECT total_files FROM snapshots WHERE id = ?", bindings: [.integer(record.id.rawValue)])?.int64Value, 1)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM entry_classifications")?.int64Value, 0)
    }

    func testCompletedSnapshotRejectsLaterEntryMutation() throws {
        let record = try SnapshotScanner(database: database).capture(root: source)
        XCTAssertEqual(record.status, .complete)
        XCTAssertThrowsError(try database.execute(
            "INSERT INTO entries (snapshot_id, parent_id, relative_path, case_preserving_path, case_folded_path, name, case_preserving_name, case_folded_name, item_type, sort_key, created_at) VALUES (?, NULL, 'later', 'later', 'later', 'later', 'later', 'later', 'file', 'later', CURRENT_TIMESTAMP)",
            bindings: [.integer(record.id.rawValue)]
        ))
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM entries WHERE snapshot_id = ?", bindings: [.integer(record.id.rawValue)])?.int64Value, 1)
    }

    func testCancellationWinsFinalizationRace() throws {
        let descriptor = try FilesystemDetector().detect(root: source)
        let token = CaptureCancellationToken()
        let session = try SnapshotWriter(database: database).beginCapture(
            descriptor: descriptor, scanRootName: "Race", token: token
        )
        token.cancel()
        try session.finish(preferredStatus: .complete)

        let record = try XCTUnwrap(try SnapshotRepository(database: database).snapshot(id: session.snapshotID))
        XCTAssertEqual(record.status, .cancelled)
        XCTAssertFalse(record.isComplete)
    }

    func testCancellationDuringEnumerationNeverCompletes() throws {
        for index in 0..<180 {
            try Data().write(to: source.appendingPathComponent("file-\(index).dat"))
        }
        let token = CaptureCancellationToken()
        let scanner = SnapshotScanner(database: database, batchSize: 10)
        var result: SnapshotRecord?
        XCTAssertNoThrow(try scanner.capture(root: source, token: token) { progress in
            if progress.processedEntries >= 64 { token.cancel() }
        })
        result = try SnapshotRepository(database: database).listSnapshots().first
        XCTAssertEqual(result?.status, .cancelled)
        XCTAssertFalse(result?.isComplete ?? true)
    }

    func testRecoveryIsIdempotentAndPreservesCompletedSnapshots() throws {
        let repository = SnapshotRepository(database: database)
        try repository.createVolume(id: 77, displayName: "Recovery Volume")
        let scanning = try repository.createSnapshot(volumeID: 77, sessionNumber: 1, scanRootName: "Scanning")
        let complete = try repository.createSnapshot(volumeID: 77, sessionNumber: 2, scanRootName: "Complete")
        _ = try repository.addRoot(to: complete, name: "Complete")
        try repository.complete(complete)

        let service = RecoveryService(database: database)
        XCTAssertEqual(try service.recoverOrphanedScans().recoveredSnapshotIDs, [scanning])
        XCTAssertEqual(try service.recoverOrphanedScans().recoveredSnapshotIDs, [])
        XCTAssertEqual(try repository.snapshot(id: scanning)?.status, .interrupted)
        XCTAssertEqual(try repository.snapshot(id: complete)?.status, .complete)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM scan_issues WHERE snapshot_id = ?", bindings: [.integer(scanning.rawValue)])?.int64Value, 1)
    }

    func testSourceListingIsUnchangedByCapture() throws {
        try Data("safe".utf8).write(to: source.appendingPathComponent("safe.txt"))
        let before = try sourceListing()
        _ = try SnapshotScanner(database: database).capture(root: source)
        let after = try sourceListing()
        XCTAssertEqual(before, after)
        XCTAssertFalse(after.contains { $0.contains("catalog") || $0.contains("index") || $0.contains("marker") })
    }

    func testScalingSmokeUsesBoundedWriterBatches() throws {
        for index in 0..<5000 {
            try Data().write(to: source.appendingPathComponent("entry-\(index).tmp"))
        }
        let start = Date()
        let record = try SnapshotScanner(database: database, batchSize: 200).capture(root: source)
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertEqual(record.status, .complete)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM entries WHERE snapshot_id = ?", bindings: [.integer(record.id.rawValue)])?.int64Value, 5001)
        XCTAssertLessThan(elapsed, 60.0)
    }

    private func sourceListing() throws -> [String] {
        guard let enumerator = FileManager.default.enumerator(at: source, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey], options: []) else { return [] }
        return ([source.path] + enumerator.compactMap { ($0 as? URL)?.path }.sorted())
    }
}
