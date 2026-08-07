import XCTest
@testable import FSD

/// Offline snapshot history: what the catalog can tell the user about a capture
/// once the source is gone.
final class SnapshotHistoryTests: XCTestCase {
    private var directory: URL!
    private var source: URL!
    private var database: CatalogDatabase!
    private var history: SnapshotHistoryRepository!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-History-\(UUID().uuidString)", isDirectory: true)
        source = directory.appendingPathComponent("source", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        database = try CatalogDatabase(
            url: directory.appendingPathComponent("catalog.sqlite3"),
            schemaURL: CatalogSchemaFixture.canonicalSchemaURL
        )
        history = SnapshotHistoryRepository(database: database)
    }

    override func tearDownWithError() throws {
        history = nil
        database?.close()
        database = nil
        try? FileManager.default.removeItem(at: directory)
        directory = nil
        source = nil
    }

    func testHistoryDistinguishesEveryTerminalStatus() throws {
        let repository = SnapshotRepository(database: database)
        try repository.createVolume(id: 1, displayName: "Statuses")
        let complete = try makeSnapshot(repository, session: 1, name: "Complete", terminal: .complete)
        let interrupted = try makeSnapshot(repository, session: 2, name: "Interrupted", terminal: .interrupted)
        let cancelled = try makeSnapshot(repository, session: 3, name: "Cancelled", terminal: .cancelled)
        let failed = try makeSnapshot(repository, session: 4, name: "Failed", terminal: .failed)

        let summaries = try history.listSnapshots()
        let byID = Dictionary(uniqueKeysWithValues: summaries.map { ($0.id, $0) })

        XCTAssertEqual(summaries.count, 4)
        XCTAssertEqual(byID[complete]?.status, .complete)
        XCTAssertTrue(byID[complete]?.isComplete ?? false)
        XCTAssertFalse(byID[complete]?.isPartialCapture ?? true)
        XCTAssertNil(byID[complete]?.partialStateWarning)

        for id in [interrupted, cancelled, failed] {
            let summary = try XCTUnwrap(byID[id])
            XCTAssertFalse(summary.isComplete, summary.displayName)
            XCTAssertTrue(summary.isPartialCapture, summary.displayName)
            XCTAssertNotNil(summary.partialStateWarning, summary.displayName)
            XCTAssertTrue(summary.partialStateWarning?.contains("partial") ?? false, summary.displayName)
        }
    }

    func testHistoryOrderingIsDeterministic() throws {
        let repository = SnapshotRepository(database: database)
        try repository.createVolume(id: 1, displayName: "Ordering")
        for session in 1...6 {
            _ = try makeSnapshot(repository, session: Int64(session), name: "Capture \(session)", terminal: .complete)
        }

        let first = try history.listSnapshots().map(\.id)
        let second = try history.listSnapshots().map(\.id)
        let third = try SnapshotHistoryRepository(database: database).listSnapshots().map(\.id)

        XCTAssertEqual(first, second)
        XCTAssertEqual(first, third)
        // Newest first, and `id` breaks the tie when timestamps collide, which
        // they do here because all six commit within the same second.
        XCTAssertEqual(first, first.sorted { $0.rawValue > $1.rawValue })
    }

    func testTransientSnapshotsAreExcludedFromUserHistory() throws {
        let repository = SnapshotRepository(database: database)
        try repository.createVolume(id: 1, displayName: "Kinds")
        _ = try repository.createSnapshot(volumeID: 1, sessionNumber: 1, scanRootName: "User", kind: .user)
        _ = try repository.createSnapshot(volumeID: 1, sessionNumber: 2, scanRootName: "Transient", kind: .transient)

        XCTAssertEqual(try history.listSnapshots().count, 1)
        XCTAssertEqual(try history.listSnapshots(kind: nil).count, 2)
        XCTAssertEqual(try history.listSnapshots().first?.kind, .user)
    }

    // MARK: - Offline behaviour

    func testHistoryAndBrowsingWorkAfterTheSourceIsRemoved() throws {
        try Data("payload".utf8).write(to: source.appendingPathComponent("file.txt"))
        try FileManager.default.createDirectory(at: source.appendingPathComponent("nested"), withIntermediateDirectories: true)
        try Data().write(to: source.appendingPathComponent("nested/leaf.bin"))
        let record = try SnapshotScanner(database: database).capture(root: source)
        XCTAssertEqual(record.status, .complete)

        // The source is destroyed, exactly as ejecting a drive would leave it.
        try FileManager.default.removeItem(at: source)
        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))

        let summary = try XCTUnwrap(try history.listSnapshots().first)
        XCTAssertEqual(summary.totalFiles, 2)

        let tree = SnapshotTreeDataSource(database: database, snapshotID: summary.id)
        let root = try XCTUnwrap(try tree.root())
        let children = try tree.children(ofParent: root.id)
        XCTAssertEqual(children.map(\.name).sorted(), ["file.txt", "nested"])

        let nested = try XCTUnwrap(children.first { $0.name == "nested" })
        XCTAssertEqual(try tree.children(ofParent: nested.id).map(\.name), ["leaf.bin"])

        let hits = try MetadataSearchService(database: database).search(
            MetadataSearchQuery(text: "leaf"), in: summary.id
        )
        XCTAssertEqual(hits.hits.map(\.name), ["leaf.bin"])

        var exported = ""
        _ = try JSONSnapshotExporter(database: database).write(snapshotID: summary.id) { exported += $0 }
        XCTAssertTrue(exported.contains("nested/leaf.bin"))
    }

    func testSourceAvailabilityIsReportedWithoutBlockingBrowsing() throws {
        _ = try SnapshotScanner(database: database).capture(root: source)
        let summary = try XCTUnwrap(try history.listSnapshots().first)
        let probe = SourceAvailabilityProbe()

        XCTAssertEqual(probe.availability(for: summary), .available)

        try FileManager.default.removeItem(at: directory.appendingPathComponent("source"))
        // The mount path is the enclosing volume, which still exists; what
        // matters is that the answer is advisory and the tree still reads.
        XCTAssertNotEqual(probe.availability(for: summary), .unknown)
        XCTAssertNotNil(try SnapshotTreeDataSource(database: database, snapshotID: summary.id).root())
    }

    // MARK: - Capture-time volume truth (C4)

    func testLaterCaptureCannotChangeAnEarlierSnapshotsSourceFacts() throws {
        let writer = SnapshotWriter(database: database)
        let first = try writer.beginCapture(
            descriptor: descriptor(volumeName: "Card A", capacity: 64_000_000_000),
            scanRootName: "First"
        )
        try first.finish(preferredStatus: .complete)

        let before = try XCTUnwrap(try history.listSnapshots().first { $0.scanRootName == "First" })
        XCTAssertEqual(before.capture.volumeDisplayName, "Card A")
        XCTAssertEqual(before.capture.volumeTotalCapacityBytes, 64_000_000_000)
        XCTAssertTrue(before.capture.isFullyRecorded)

        // Same volume identity, relabelled and re-measured — exactly what
        // `ensureVolume` writes back into the shared registry row.
        let second = try writer.beginCapture(
            descriptor: descriptor(volumeName: "Card A (renamed)", capacity: 128_000_000_000),
            scanRootName: "Second"
        )
        try second.finish(preferredStatus: .complete)

        XCTAssertEqual(
            try database.scalar("SELECT display_name FROM volumes")?.stringValue,
            "Card A (renamed)",
            "the registry is expected to move; that is why history must not read it"
        )

        let after = try XCTUnwrap(try history.listSnapshots().first { $0.scanRootName == "First" })
        XCTAssertEqual(after.capture.volumeDisplayName, "Card A")
        XCTAssertEqual(after.capture.volumeTotalCapacityBytes, 64_000_000_000)
        XCTAssertEqual(after.capture, before.capture)
    }

    func testCaptureTimeFactsAreRejectedAtTheDatabaseBoundary() throws {
        _ = try SnapshotScanner(database: database).capture(root: source)
        let summary = try XCTUnwrap(try history.listSnapshots().first)

        for (column, value) in [
            ("volume_display_name_at_capture", DatabaseValue.text("Rewritten")),
            ("volume_identifier_at_capture", .text("other-volume")),
            ("volume_total_capacity_bytes_at_capture", .integer(1)),
            ("mount_path_at_capture", .text("/elsewhere")),
            ("scan_root_name", .text("Renamed root")),
            ("filesystem_variant", .text("madeup")),
            ("normalization_version", .text("fsd-normalizer-v9_app-9.9_os-9")),
            ("started_at", .text("1999-01-01 00:00:00"))
        ] {
            XCTAssertThrowsError(
                try database.execute(
                    "UPDATE snapshots SET \(column) = ? WHERE id = ?",
                    bindings: [value, .integer(summary.id.rawValue)]
                ),
                "\(column) must be immutable"
            )
        }

        XCTAssertEqual(try history.summary(id: summary.id), summary)
    }

    func testMutableCatalogMetadataStillUpdates() throws {
        _ = try SnapshotScanner(database: database).capture(root: source)
        let summary = try XCTUnwrap(try history.listSnapshots().first)

        // The capture-facts guard must not freeze the fields that are meant to
        // stay editable: user labelling and Collection assignment.
        XCTAssertNoThrow(try database.execute(
            "UPDATE snapshots SET display_name = ?, user_note = ? WHERE id = ?",
            bindings: [.text("Renamed capture"), .text("a note"), .integer(summary.id.rawValue)]
        ))
        XCTAssertEqual(try history.summary(id: summary.id)?.displayName, "Renamed capture")
        XCTAssertEqual(try history.summary(id: summary.id)?.capture, summary.capture)
    }

    // MARK: - Helpers

    private func descriptor(volumeName: String, capacity: Int64) -> FilesystemDescriptor {
        FilesystemDescriptor(
            rootURL: source,
            volumeName: volumeName,
            volumeIdentifier: "TEST-VOLUME-UUID",
            filesystemType: "exfat",
            sourceCaseSensitivity: .insensitive,
            isReadOnly: false,
            mountPath: "/Volumes/Card A",
            capacityBytes: capacity,
            availableBytes: capacity / 2
        )
    }

    private func makeSnapshot(
        _ repository: SnapshotRepository,
        session: Int64,
        name: String,
        terminal: SnapshotStatus
    ) throws -> SnapshotID {
        let snapshot = try repository.createSnapshot(volumeID: 1, sessionNumber: session, scanRootName: name)
        _ = try repository.addRoot(to: snapshot, name: name)
        try repository.transition(snapshot, to: terminal)
        return snapshot
    }
}
