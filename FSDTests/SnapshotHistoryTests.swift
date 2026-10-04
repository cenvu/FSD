import Darwin
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

    // MARK: - Schema-v9 source-root locator (P15 Slice 02)

    func testV9MountRootCaptureStoresEmptyRootLocator() throws {
        let session = try SnapshotWriter(database: database).beginCapture(
            descriptor: locatorDescriptor(rootURL: source, mountPath: source.path), scanRootName: "MountRoot"
        )
        try session.finish(preferredStatus: .complete)
        XCTAssertEqual(try rootLocator(session.snapshotID), "")
        XCTAssertEqual(try schemaVersion(session.snapshotID), CatalogDatabase.currentSchemaVersion)
    }

    func testV9NestedRootCaptureStoresExactNormalizedLexicalLocator() throws {
        let nested = source.appendingPathComponent("a", isDirectory: true)
            .appendingPathComponent("b", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        let session = try SnapshotWriter(database: database).beginCapture(
            descriptor: locatorDescriptor(rootURL: nested, mountPath: directory.path), scanRootName: "Nested"
        )
        try session.finish(preferredStatus: .complete)
        XCTAssertEqual(try rootLocator(session.snapshotID), "source/a/b")
    }

    func testLocatorNeverContainsDotComponentsAfterLexicalNormalization() throws {
        let nested = source.appendingPathComponent("a", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        let dotted = URL(fileURLWithPath: directory.path + "/./source/a/../a/./")
        let session = try SnapshotWriter(database: database).beginCapture(
            descriptor: locatorDescriptor(rootURL: dotted, mountPath: directory.path + "/"), scanRootName: "Dotted"
        )
        try session.finish(preferredStatus: .complete)
        let locator = try XCTUnwrap(try rootLocator(session.snapshotID))
        XCTAssertEqual(locator, "source/a")
        XCTAssertFalse(locator.hasPrefix("/"))
        XCTAssertFalse(locator.split(separator: "/", omittingEmptySubsequences: false).contains { $0 == "." || $0 == ".." || $0.isEmpty })
    }

    func testRealDetectorCaptureLocatorProvablyReachesTheSelectedRootFromTheMountRoot() throws {
        let detected = try FilesystemDetector().detect(root: source)
        let session = try SnapshotWriter(database: database).beginCapture(descriptor: detected, scanRootName: "Detected")
        try session.finish(preferredStatus: .complete)
        let locator = try XCTUnwrap(try rootLocator(session.snapshotID))
        XCTAssertFalse(locator.isEmpty, "the temp source is nested beneath its mount root")
        XCTAssertFalse(locator.hasPrefix("/"))
        let reached = URL(fileURLWithPath: detected.mountPath).appendingPathComponent(locator).resolvingSymlinksInPath()
        XCTAssertEqual(reached.path, source.resolvingSymlinksInPath().path)
        XCTAssertEqual(
            try database.scalar("SELECT mount_path_at_capture FROM snapshots WHERE id = ?",
                                bindings: [.integer(session.snapshotID.rawValue)])?.stringValue,
            detected.mountPath
        )
    }

    func testDirectLexicalLocatorUsesDescriptorAuthorityWithoutAliasIO() throws {
        let missing = source.appendingPathComponent("not-created")
        XCTAssertEqual(try SnapshotWriter.rootRelativePath(for:
            locatorDescriptor(rootURL: missing, mountPath: source.path)), "not-created")
    }

    func testVarSymlinkPresentationAcceptsCanonicalPrivateCandidate() throws {
        // Deterministic macOS unified-namespace case with a synthetic descriptor:
        // the presentation root lives in /var/... while the physical mount is the
        // Data volume, so direct lexical containment fails and only the POSIX
        // canonical root (/private/var/...) can supply the single candidate.
        // This does not depend on what the detector reports for temp directories
        // on any particular host (it reports "/" there); it exercises the real
        // system namespace that production captures present on macOS.
        let mount = "/System/Volumes/Data"
        let presentation = URL(fileURLWithPath: "/var/folders")
        guard let resolved = Darwin.realpath(presentation.path, nil) else {
            throw XCTSkip("host cannot canonicalize /var/folders")
        }
        defer { free(resolved) }
        let canonical = String(cString: resolved)
        let stripped = String(canonical.dropFirst())
        XCTAssertTrue(stripped.hasPrefix("private/var/"),
                      "POSIX canonical root lives under /private/var/..., got \(stripped)")
        let candidate = mount + "/" + stripped
        guard FileManager.default.fileExists(atPath: candidate) else {
            throw XCTSkip("host lacks the Data-volume presentation of \(stripped)")
        }
        // Same-object proof between the canonical root and the single
        // mount-joined candidate, independent of the locator under test.
        let fs = DarwinBoundedSourceFilesystem()
        let canonicalFD = try fs.openMountRoot(path: canonical)
        defer { fs.close(descriptor: canonicalFD) }
        let candidateFD = try fs.openMountRoot(path: candidate)
        defer { fs.close(descriptor: candidateFD) }
        let a = try fs.stat(descriptor: canonicalFD)
        let b = try fs.stat(descriptor: candidateFD)
        XCTAssertEqual(a.device, b.device)
        XCTAssertEqual(a.inode, b.inode)
        // The accepted locator is the canonical derivation. No raw-presentation
        // second candidate is ever attempted (see the unit test below: there is
        // exactly one construction site and it takes only canonical components).
        // Note the raw presentation candidate (mount + "/var/...") does not even
        // exist on macOS, so guessing from raw components could never succeed.
        XCTAssertFalse(FileManager.default.fileExists(atPath: mount + "/var/folders"))
        XCTAssertEqual(
            try SnapshotWriter.rootRelativePath(for:
                locatorDescriptor(rootURL: presentation, mountPath: mount)),
            stripped
        )
    }

    func testExactlyOnePhysicalCandidateIsConstructedFromCanonicalComponents() throws {
        XCTAssertEqual(
            SnapshotWriter.physicalCandidate(mountPath: "/System/Volumes/Data", canonicalRoot: "/private/var/folders/T"),
            "private/var/folders/T"
        )
        XCTAssertEqual(SnapshotWriter.physicalCandidate(mountPath: "/", canonicalRoot: "/a/b"), "a/b")
        XCTAssertEqual(SnapshotWriter.physicalCandidate(mountPath: "/", canonicalRoot: "/"), "")
        XCTAssertNil(SnapshotWriter.physicalCandidate(mountPath: "/mount", canonicalRoot: "relative/path"))
    }

    func testAliasCandidateWithSamePathSuffixButDifferentObjectIsRejected() throws {
        let mount = directory.appendingPathComponent("different-mount")
        let canonical = source.resolvingSymlinksInPath()
        let candidate = mount.appendingPathComponent(String(canonical.path.dropFirst()))
        try FileManager.default.createDirectory(at: candidate, withIntermediateDirectories: true)
        XCTAssertTrue(FileManager.default.fileExists(atPath: candidate.path))
        XCTAssertThrowsError(try SnapshotWriter(database: database).beginCapture(
            descriptor: locatorDescriptor(rootURL: source, mountPath: mount.path), scanRootName: "Different"))
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM snapshots")?.int64Value, 0)
    }

    func testMissingAliasCandidateFailsCapture() throws {
        let mount = directory.appendingPathComponent("empty-mount")
        try FileManager.default.createDirectory(at: mount, withIntermediateDirectories: true)
        XCTAssertThrowsError(try SnapshotWriter(database: database).beginCapture(
            descriptor: locatorDescriptor(rootURL: source, mountPath: mount.path), scanRootName: "Missing"))
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM snapshots")?.int64Value, 0)
    }

    func testCanonicalizationFailureFailsCapture() throws {
        let mount = directory.appendingPathComponent("empty-mount")
        try FileManager.default.createDirectory(at: mount, withIntermediateDirectories: true)
        let missing = URL(fileURLWithPath: "/definitely-not-present-fsd-probe-\(UUID().uuidString)")
        XCTAssertThrowsError(try SnapshotWriter(database: database).beginCapture(
            descriptor: locatorDescriptor(rootURL: missing, mountPath: mount.path), scanRootName: "Uncanonical"))
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM snapshots")?.int64Value, 0)
    }

    func testAliasCandidateEscapingThroughSymlinkIsRejectedEvenForSameTarget() throws {
        let mount = directory.appendingPathComponent("symlink-mount")
        let canonical = source.resolvingSymlinksInPath()
        let candidate = mount.appendingPathComponent(String(canonical.path.dropFirst()))
        try FileManager.default.createDirectory(at: candidate.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: candidate, withDestinationURL: source)
        XCTAssertThrowsError(try SnapshotWriter(database: database).beginCapture(
            descriptor: locatorDescriptor(rootURL: source, mountPath: mount.path), scanRootName: "Escape"))
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM snapshots")?.int64Value, 0)
    }

    func testAliasWithoutReadableIdentityProofFailsCapture() throws {
        let mount = directory.appendingPathComponent("unprovable-mount")
        let canonical = source.resolvingSymlinksInPath()
        let candidate = mount.appendingPathComponent(String(canonical.path.dropFirst()))
        try FileManager.default.createDirectory(at: candidate, withIntermediateDirectories: true)
        XCTAssertEqual(chmod(candidate.path, 0), 0)
        defer { _ = chmod(candidate.path, 0o755) }
        XCTAssertThrowsError(try SnapshotWriter(database: database).beginCapture(
            descriptor: locatorDescriptor(rootURL: source, mountPath: mount.path), scanRootName: "Unprovable"))
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM snapshots")?.int64Value, 0)
    }

    func testRootOutsideDetectedMountFailsCaptureWithoutPersistingAnything() throws {
        let otherMount = directory.appendingPathComponent("other-mount", isDirectory: true)
        try FileManager.default.createDirectory(at: otherMount, withIntermediateDirectories: true)
        let escaping = [
            locatorDescriptor(rootURL: source, mountPath: otherMount.path),
            locatorDescriptor(rootURL: otherMount.appendingPathComponent("../source"), mountPath: otherMount.path),
            locatorDescriptor(rootURL: source, mountPath: "relative/mount")
        ]
        for descriptor in escaping {
            XCTAssertThrowsError(try SnapshotWriter(database: database).beginCapture(
                descriptor: descriptor, scanRootName: "Escape"
            ))
        }
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM snapshots")?.int64Value, 0)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM entries")?.int64Value, 0)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM volumes")?.int64Value, 0)
    }

    func testLegacyV8SnapshotIsNeitherBackfilledNorReinterpretedByLaterCapture() throws {
        try database.execute(
            """
            INSERT INTO volumes (id, display_name, first_seen_at, last_seen_at, created_at, updated_at)
            VALUES (50, 'Legacy', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            """
        )
        try database.execute(
            """
            INSERT INTO snapshots (
                id, volume_id, session_number, scan_root_name, mount_path_at_capture, status, scanner_version,
                schema_version, normalization_version, display_name, capture_policy_json,
                volume_identifier_at_capture, started_at, created_at, updated_at
            ) VALUES (900, 50, 1, 'Legacy', '/Volumes/Legacy', 'scanning', 'legacy', 8, ?, 'Legacy', '{}',
                      'LEGACY-ID', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            """,
            bindings: [.text(NormalizationVersion.current.rawValue)]
        )
        try SyntheticSnapshot.insertEntries(
            database: database,
            snapshotID: SnapshotID(rawValue: 900),
            entries: [SyntheticSnapshot.root(id: 901, name: "Legacy")]
        )
        try database.execute("UPDATE snapshots SET status = 'complete', completed_at = CURRENT_TIMESTAMP WHERE id = 900")
        let fingerprint = """
            SELECT root_relative_path || '|' || schema_version || '|' || mount_path_at_capture || '|' ||
                   volume_identifier_at_capture || '|' || scan_root_name || '|' || status
            FROM snapshots WHERE id = 900
            """
        let before = try XCTUnwrap(try database.scalar(fingerprint)?.stringValue)
        let session = try SnapshotWriter(database: database).beginCapture(
            descriptor: locatorDescriptor(rootURL: source, mountPath: directory.path), scanRootName: "Later"
        )
        try session.finish(preferredStatus: .complete)
        XCTAssertEqual(try database.scalar(fingerprint)?.stringValue, before)
        XCTAssertEqual(try rootLocator(SnapshotID(rawValue: 900)), "")
        XCTAssertEqual(try schemaVersion(SnapshotID(rawValue: 900)), 8)
    }

    func testRootLocatorIsImmutableCaptureFact() throws {
        let session = try SnapshotWriter(database: database).beginCapture(
            descriptor: locatorDescriptor(rootURL: source, mountPath: directory.path), scanRootName: "Fact"
        )
        try session.finish(preferredStatus: .complete)
        XCTAssertThrowsError(try database.execute(
            "UPDATE snapshots SET root_relative_path = ? WHERE id = ?",
            bindings: [.text("elsewhere"), .integer(session.snapshotID.rawValue)]
        ))
        XCTAssertEqual(try rootLocator(session.snapshotID), "source")
    }

    // MARK: - Helpers

    private func locatorDescriptor(rootURL: URL, mountPath: String) -> FilesystemDescriptor {
        FilesystemDescriptor(
            rootURL: rootURL, volumeName: "Locator Volume", volumeIdentifier: "LOCATOR-VOLUME-UUID",
            filesystemType: "apfs", sourceCaseSensitivity: .insensitive, isReadOnly: false,
            mountPath: mountPath, capacityBytes: 1_000_000, availableBytes: 500_000
        )
    }

    private func rootLocator(_ id: SnapshotID) throws -> String? {
        try database.scalar(
            "SELECT root_relative_path FROM snapshots WHERE id = ?", bindings: [.integer(id.rawValue)]
        )?.stringValue
    }

    private func schemaVersion(_ id: SnapshotID) throws -> Int64? {
        try database.scalar(
            "SELECT schema_version FROM snapshots WHERE id = ?", bindings: [.integer(id.rawValue)]
        )?.int64Value
    }

    private func descriptor(volumeName: String, capacity: Int64) -> FilesystemDescriptor {
        FilesystemDescriptor(
            rootURL: source,
            volumeName: volumeName,
            volumeIdentifier: "TEST-VOLUME-UUID",
            filesystemType: "exfat",
            sourceCaseSensitivity: .insensitive,
            isReadOnly: false,
            mountPath: directory.path,
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
