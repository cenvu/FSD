import Darwin
import XCTest
@testable import FSD

/// Read-authority matrix for `BoundedClassificationSourceReader`.
///
/// Fixtures are disposable directories owned by the test. Production code under
/// test only reads; every mutation below (swapping a file, removing a
/// directory, changing a mode) is performed by the test itself to simulate a
/// hostile or racing source.
final class ClassificationSourceReaderTests: XCTestCase {
    private typealias Boundary = BoundedClassificationSourceReader.CancellationBoundary

    private var directory: URL!
    private var source: URL!
    private var outside: URL!
    private var database: CatalogDatabase!
    private var detected: FilesystemDescriptor!
    private var rawSnapshotCounter: Int64 = 0

    private let secret = Data("TOP-SECRET-OUTSIDE-CONTENT".utf8)

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-ClassSource-\(UUID().uuidString)", isDirectory: true)
        source = directory.appendingPathComponent("source", isDirectory: true)
        outside = directory.appendingPathComponent("outside", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
        try secret.write(to: outside.appendingPathComponent("secret.txt"))
        database = try CatalogDatabase(
            url: directory.appendingPathComponent("catalog.sqlite3"),
            schemaURL: CatalogSchemaFixture.canonicalSchemaURL
        )
        detected = try FilesystemDetector().detect(root: source)
    }

    override func tearDownWithError() throws {
        database?.close()
        database = nil
        if let directory {
            _ = try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: directory.appendingPathComponent("source/locked.txt").path)
            try? FileManager.default.removeItem(at: directory)
        }
        directory = nil
        source = nil
        outside = nil
        detected = nil
    }

    // MARK: - Legacy / missing context

    func testLegacyV8SnapshotClassificationIsUnavailableWithoutRowOrBackfill() throws {
        let ids = try rawSnapshot(schema: 8, mount: detected.mountPath, identity: detected.volumeIdentifier,
                                  files: ["report.txt"])
        try write("report.txt", Data("legacy".utf8))
        let beforeFacts = try snapshotFacts()
        let filesystem = RecordingFilesystem()

        let outcome = try reader(filesystem).readPrefix(forEntryID: ids["report.txt"]!)

        XCTAssertEqual(outcome, .unavailable)
        XCTAssertEqual(filesystem.readCalls, 0)
        XCTAssertEqual(filesystem.mountOpens, 0)
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
        XCTAssertEqual(try snapshotFacts(), beforeFacts, "no backfill or reinterpretation of the old snapshot")
        XCTAssertEqual(
            try database.scalar("SELECT root_relative_path FROM snapshots WHERE schema_version = 8")?.stringValue, ""
        )
    }

    func testMissingRecordedContextIsUnavailable() throws {
        try write("a.txt", Data("a".utf8))
        let cases: [(mount: String?, identity: String?)] = [
            (nil, detected.volumeIdentifier), (detected.mountPath, nil), (detected.mountPath, ""), ("", detected.volumeIdentifier),
            ("relative/mount", detected.volumeIdentifier)
        ]
        for (index, context) in cases.enumerated() {
            let ids = try rawSnapshot(schema: 9, mount: context.mount, identity: context.identity, files: ["a.txt"])
            let filesystem = RecordingFilesystem()
            XCTAssertEqual(
                try reader(filesystem).readPrefix(forEntryID: ids["a.txt"]!), .unavailable, "case \(index)"
            )
            XCTAssertEqual(filesystem.mountOpens, 0, "case \(index)")
            XCTAssertEqual(filesystem.readCalls, 0, "case \(index)")
        }
    }

    func testSyntheticSnapshotWithoutCaptureContextAndUnknownEntryAreUnavailable() throws {
        let snapshotID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 1, session: 1)
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: snapshotID, entries: [
            SyntheticSnapshot.root(id: 1),
            SyntheticSnapshot.SeedEntry(id: 2, parentID: 1, relativePath: "a.txt", name: "a.txt")
        ])
        try SyntheticSnapshot.complete(database: database, snapshotID: snapshotID)
        let filesystem = RecordingFilesystem()
        XCTAssertEqual(try reader(filesystem).readPrefix(forEntryID: 2), .unavailable)
        XCTAssertEqual(try reader(filesystem).readPrefix(forEntryID: 424_242), .unavailable)
        XCTAssertEqual(filesystem.readCalls, 0)
    }

    func testMalformedStoredRootLocatorIsUnavailableBeforeAnyIO() throws {
        try write("a.txt", Data("a".utf8))
        for locator in ["../outside", "/etc", "a/./b", "a//b", "a/", "./a", ".."] {
            let ids = try rawSnapshot(schema: 9, mount: detected.mountPath, identity: detected.volumeIdentifier,
                                      rootLocator: locator, files: ["a.txt"])
            let filesystem = RecordingFilesystem()
            XCTAssertEqual(try reader(filesystem).readPrefix(forEntryID: ids["a.txt"]!), .unavailable, locator)
            XCTAssertEqual(filesystem.mountOpens, 0, locator)
            XCTAssertEqual(filesystem.readCalls, 0, locator)
        }
    }

    func testSnapshotStillScanningIsUnavailable() throws {
        try write("a.txt", Data("a".utf8))
        let ids = try rawSnapshot(schema: 9, mount: detected.mountPath, identity: detected.volumeIdentifier,
                                  status: "scanning", files: ["a.txt"])
        let filesystem = RecordingFilesystem()
        XCTAssertEqual(try reader(filesystem).readPrefix(forEntryID: ids["a.txt"]!), .unavailable)
        XCTAssertEqual(filesystem.readCalls, 0)
    }

    // MARK: - Source identity

    func testSourceDetachedBeforeResolutionIsUnavailable() throws {
        try write("a.txt", Data("a".utf8))
        let ids = try capture([.init("a.txt", .file)])
        let filesystem = RecordingFilesystem()
        let outcome = try reader(filesystem, detect: { _ in throw FilesystemDetectorError.sourceDoesNotExist("gone") })
            .readPrefix(forEntryID: ids["a.txt"]!)
        XCTAssertEqual(outcome, .unavailable)
        XCTAssertEqual(filesystem.mountOpens, 0)
        XCTAssertEqual(filesystem.readCalls, 0)
    }

    func testVolumeIdentityMismatchIsSourceChangedEvenWithMatchingNames() throws {
        try write("a.txt", Data("a".utf8))
        let ids = try capture([.init("a.txt", .file)])
        let impostor = FilesystemDescriptor(
            rootURL: detected.rootURL, volumeName: detected.volumeName,
            volumeIdentifier: detected.volumeIdentifier + "-OTHER", filesystemType: detected.filesystemType,
            sourceCaseSensitivity: detected.sourceCaseSensitivity, isReadOnly: detected.isReadOnly,
            mountPath: detected.mountPath, capacityBytes: detected.capacityBytes, availableBytes: detected.availableBytes
        )
        let filesystem = RecordingFilesystem()
        let outcome = try reader(filesystem, detect: { _ in impostor }).readPrefix(forEntryID: ids["a.txt"]!)
        XCTAssertEqual(outcome, .sourceChanged, "same display name and mount folder never prove identity")
        XCTAssertEqual(filesystem.mountOpens, 0)
        XCTAssertEqual(filesystem.readCalls, 0)
    }

    func testMountPathNoLongerTheCapturedMountRootIsSourceChanged() throws {
        try write("a.txt", Data("a".utf8))
        let ids = try capture([.init("a.txt", .file)])
        let moved = FilesystemDescriptor(
            rootURL: detected.rootURL, volumeName: detected.volumeName, volumeIdentifier: detected.volumeIdentifier,
            filesystemType: detected.filesystemType, sourceCaseSensitivity: detected.sourceCaseSensitivity,
            isReadOnly: detected.isReadOnly, mountPath: detected.mountPath + "/elsewhere",
            capacityBytes: detected.capacityBytes, availableBytes: detected.availableBytes
        )
        XCTAssertEqual(try reader(RecordingFilesystem(), detect: { _ in moved }).readPrefix(forEntryID: ids["a.txt"]!), .sourceChanged)
    }

    func testDisplayNameChangeAloneDoesNotBlockAnIdentifiedSource() throws {
        try write("a.txt", Data("hello".utf8))
        let ids = try capture([.init("a.txt", .file)])
        let renamed = FilesystemDescriptor(
            rootURL: detected.rootURL, volumeName: "Renamed Volume", volumeIdentifier: detected.volumeIdentifier,
            filesystemType: detected.filesystemType, sourceCaseSensitivity: detected.sourceCaseSensitivity,
            isReadOnly: detected.isReadOnly, mountPath: detected.mountPath,
            capacityBytes: detected.capacityBytes, availableBytes: detected.availableBytes
        )
        let outcome = try reader(RecordingFilesystem(), detect: { _ in renamed }).readPrefix(forEntryID: ids["a.txt"]!)
        XCTAssertEqual(prefix(outcome), Data("hello".utf8))
    }

    func testSourceDisappearingAfterInitialValidationIsSourceChanged() throws {
        try write("a.txt", Data("a".utf8))
        let ids = try capture([.init("a.txt", .file)])
        var calls = 0
        let outcome = try reader(RecordingFilesystem(), detect: { [detected] url in
            calls += 1
            if calls > 1 { throw FilesystemDetectorError.sourceDoesNotExist("gone") }
            return detected!
        }).readPrefix(forEntryID: ids["a.txt"]!)
        XCTAssertEqual(outcome, .sourceChanged)
        XCTAssertEqual(calls, 2)
    }

    func testIdentitySubstitutionAfterReadIsSourceChanged() throws {
        try write("a.txt", Data("a".utf8))
        let ids = try capture([.init("a.txt", .file)])
        var calls = 0
        let outcome = try reader(RecordingFilesystem(), detect: { [detected] _ in
            calls += 1
            guard calls > 1 else { return detected! }
            return FilesystemDescriptor(
                rootURL: detected!.rootURL, volumeName: detected!.volumeName, volumeIdentifier: "SUBSTITUTE",
                filesystemType: detected!.filesystemType, sourceCaseSensitivity: detected!.sourceCaseSensitivity,
                isReadOnly: detected!.isReadOnly, mountPath: detected!.mountPath,
                capacityBytes: nil, availableBytes: nil
            )
        }).readPrefix(forEntryID: ids["a.txt"]!)
        XCTAssertEqual(outcome, .sourceChanged)
    }

    // MARK: - Entry kinds

    func testStoredNonFileKindsAreUnsupportedWithZeroContentIO() throws {
        try write("dir/inner.txt", Data("inner".utf8))
        try write("pkg.app/Contents/Info.txt", Data("pkg".utf8))
        try write("file.txt", Data("file".utf8))
        let ids = try capture([
            .init("dir", .directory), .init("pkg.app", .package, isPackage: true),
            .init("flagged.txt", .file, isPackage: true), .init("link", .symlink), .init("odd", .other)
        ])
        let rootID = try XCTUnwrap(try database.scalar("SELECT id FROM entries WHERE relative_path = '' ORDER BY id DESC LIMIT 1")?.int64Value)
        let filesystem = RecordingFilesystem()
        let reader = reader(filesystem)
        for (path, id) in [("dir", ids["dir"]!), ("pkg.app", ids["pkg.app"]!), ("flagged.txt", ids["flagged.txt"]!),
                           ("link", ids["link"]!), ("odd", ids["odd"]!), ("<root>", rootID)] {
            XCTAssertEqual(try reader.readPrefix(forEntryID: id), .unsupportedEntry, path)
        }
        XCTAssertEqual(filesystem.readCalls, 0)
        XCTAssertEqual(filesystem.fileOpens, [])
        XCTAssertEqual(filesystem.mountOpens, 0, "stored kind is decided before any filesystem access")
    }

    func testLiveDirectorySymlinkAndSpecialFileAreUnsupportedWithZeroContentReads() throws {
        let ids = try capture([.init("d.txt", .file), .init("s.txt", .file), .init("p.txt", .file)])
        try FileManager.default.createDirectory(at: source.appendingPathComponent("d.txt"), withIntermediateDirectories: false)
        try FileManager.default.createSymbolicLink(
            at: source.appendingPathComponent("s.txt"), withDestinationURL: outside.appendingPathComponent("secret.txt")
        )
        XCTAssertEqual(mkfifo(source.appendingPathComponent("p.txt").path, 0o600), 0)
        let filesystem = RecordingFilesystem()
        let reader = reader(filesystem)
        for path in ["d.txt", "s.txt", "p.txt"] {
            XCTAssertEqual(try reader.readPrefix(forEntryID: ids[path]!), .unsupportedEntry, path)
        }
        XCTAssertEqual(filesystem.readCalls, 0)
        XCTAssertEqual(filesystem.fileOpens, [], "no non-regular object is ever opened for content")
    }

    // MARK: - One bounded read

    func testSmallFileReturnsExactBytesInOneRead() throws {
        let bytes = Data("tiny prefix".utf8)
        try write("small.txt", bytes)
        let ids = try capture([.init("small.txt", .file)])
        let filesystem = RecordingFilesystem()
        let outcome = try reader(filesystem).readPrefix(forEntryID: ids["small.txt"]!)
        XCTAssertEqual(prefix(outcome), bytes)
        XCTAssertEqual(filesystem.readCalls, 1)
        XCTAssertEqual(filesystem.readRequestSizes, [4096])
    }

    func testEmptyFileReturnsEmptyPrefixInOneRead() throws {
        try write("empty.bin", Data())
        let ids = try capture([.init("empty.bin", .file)])
        let filesystem = RecordingFilesystem()
        XCTAssertEqual(prefix(try reader(filesystem).readPrefix(forEntryID: ids["empty.bin"]!)), Data())
        XCTAssertEqual(filesystem.readCalls, 1)
    }

    func testExact4096ByteFileReturnsExactly4096InOneRead() throws {
        let bytes = pattern(4096)
        try write("exact.bin", bytes)
        let ids = try capture([.init("exact.bin", .file)])
        let filesystem = RecordingFilesystem()
        let result = prefix(try reader(filesystem).readPrefix(forEntryID: ids["exact.bin"]!))
        XCTAssertEqual(result?.count, 4096)
        XCTAssertEqual(result, bytes)
        XCTAssertEqual(filesystem.readCalls, 1)
    }

    func testLargeFileReturnsOnlyTheFirst4096BytesInOneRead() throws {
        let bytes = pattern(10_000)
        try write("large.bin", bytes)
        let ids = try capture([.init("large.bin", .file)])
        let filesystem = RecordingFilesystem()
        let result = prefix(try reader(filesystem).readPrefix(forEntryID: ids["large.bin"]!))
        XCTAssertEqual(result?.count, 4096)
        XCTAssertEqual(result, bytes.prefix(4096))
        XCTAssertEqual(filesystem.readCalls, 1, "no tail, adaptive, retry or whole-file read")
        XCTAssertEqual(filesystem.readRequestSizes, [4096])
    }

    func testRealScannerCaptureReadsThroughTheDefaultReaderAndRealMountRoot() throws {
        let bytes = pattern(6000)
        try write("nested/deep/real.bin", bytes)
        let record = try SnapshotScanner(database: database).capture(root: source)
        let id = try entryID("nested/deep/real.bin", snapshot: record.id)
        let outcome = try BoundedClassificationSourceReader(database: database).readPrefix(forEntryID: id)
        XCTAssertEqual(prefix(outcome), bytes.prefix(4096))
    }

    func testNestedRootCaptureReadsThroughTheValidatedRootLocator() throws {
        let bytes = pattern(300)
        try write("outer/inner/file.bin", bytes)
        let nestedRoot = source.appendingPathComponent("outer", isDirectory: true)
        let record = try SnapshotScanner(database: database).capture(root: nestedRoot)
        XCTAssertEqual(
            try database.scalar("SELECT root_relative_path FROM snapshots WHERE id = ?",
                                bindings: [.integer(record.id.rawValue)])?.stringValue.map { $0.hasSuffix("source/outer") },
            true
        )
        let id = try entryID("inner/file.bin", snapshot: record.id)
        XCTAssertEqual(prefix(try BoundedClassificationSourceReader(database: database).readPrefix(forEntryID: id)), bytes)
    }

    // MARK: - Path construction

    func testPathValidatorRejectsEveryInvalidForm() {
        for invalid in ["", "/abs", "a//b", "a/", "/", ".", "..", "a/./b", "a/../b", "../a", "a/..", "a/\u{0}b",
                        String(repeating: "x", count: 256)] {
            XCTAssertNil(ClassificationSourcePath.components(of: invalid, allowEmpty: false), invalid)
        }
        XCTAssertNil(ClassificationSourcePath.components(of: "a//b", allowEmpty: true))
        XCTAssertEqual(ClassificationSourcePath.components(of: "", allowEmpty: true), [])
        XCTAssertEqual(ClassificationSourcePath.components(of: "a/b c/é", allowEmpty: false), ["a", "b c", "é"])
        XCTAssertEqual(ClassificationSourcePath.components(of: "..hidden/.x", allowEmpty: false), ["..hidden", ".x"])
    }

    func testPathTraversalAndMalformedEntryPathsAreRejectedBeforeContentIO() throws {
        try write("a.txt", Data("a".utf8))
        let traversal = ["../outside/secret.txt", "../../../../etc/hosts", "a/../../outside/secret.txt",
                         "/etc/hosts", "./a.txt", "a.txt/.", "x//y", "trailing/"]
        let ids = try capture(traversal.map { .init($0, .file) })
        let filesystem = RecordingFilesystem()
        let reader = reader(filesystem)
        for path in traversal {
            XCTAssertEqual(try reader.readPrefix(forEntryID: ids[path]!), .unavailable, path)
        }
        XCTAssertEqual(filesystem.readCalls, 0)
        XCTAssertEqual(filesystem.mountOpens, 0)
        XCTAssertEqual(filesystem.fileOpens, [])
    }

    func testFinalComponentSymlinkSwapIsUnsupportedAndTargetIsNeverRead() throws {
        try write("swap.txt", Data("original".utf8))
        let ids = try capture([.init("swap.txt", .file)])
        try FileManager.default.removeItem(at: source.appendingPathComponent("swap.txt"))
        try FileManager.default.createSymbolicLink(
            at: source.appendingPathComponent("swap.txt"), withDestinationURL: outside.appendingPathComponent("secret.txt")
        )
        let filesystem = RecordingFilesystem()
        let outcome = try reader(filesystem).readPrefix(forEntryID: ids["swap.txt"]!)
        XCTAssertEqual(outcome, .unsupportedEntry)
        XCTAssertNil(prefix(outcome))
        XCTAssertEqual(filesystem.readCalls, 0)
        XCTAssertEqual(filesystem.fileOpens, [])
    }

    func testIntermediateDirectorySymlinkEscapeIsBlockedAndTargetNeverRead() throws {
        try write("sub/nested.txt", Data("original".utf8))
        try secret.write(to: outside.appendingPathComponent("nested.txt"))
        let ids = try capture([.init("sub", .directory), .init("sub/nested.txt", .file)])
        try FileManager.default.moveItem(at: source.appendingPathComponent("sub"), to: source.appendingPathComponent("sub-moved"))
        try FileManager.default.createSymbolicLink(at: source.appendingPathComponent("sub"), withDestinationURL: outside)
        let filesystem = RecordingFilesystem()
        let outcome = try reader(filesystem).readPrefix(forEntryID: ids["sub/nested.txt"]!)
        XCTAssertEqual(outcome, .sourceChanged)
        XCTAssertNil(prefix(outcome))
        XCTAssertEqual(filesystem.readCalls, 0)
        XCTAssertEqual(filesystem.fileOpens, [])
    }

    func testSymlinkedRootLocatorComponentIsNeverFollowed() throws {
        try write("real/inner.txt", Data("inner".utf8))
        let record = try SnapshotScanner(database: database).capture(root: source.appendingPathComponent("real"))
        let id = try entryID("inner.txt", snapshot: record.id)
        try FileManager.default.moveItem(at: source.appendingPathComponent("real"), to: source.appendingPathComponent("real-moved"))
        try FileManager.default.createSymbolicLink(at: source.appendingPathComponent("real"), withDestinationURL: outside)
        try secret.write(to: outside.appendingPathComponent("inner.txt"))
        let filesystem = RecordingFilesystem()
        XCTAssertEqual(try reader(filesystem).readPrefix(forEntryID: id), .sourceChanged)
        XCTAssertEqual(filesystem.readCalls, 0)
    }

    // MARK: - Races and substitution

    func testSubstitutionBetweenLstatAndOpenIsSourceChanged() throws {
        try write("race.txt", Data("original".utf8))
        let ids = try capture([.init("race.txt", .file)])
        let filesystem = RecordingFilesystem()
        filesystem.beforeOpenFile = { [self] _ in replaceFile("race.txt", with: Data("substitute".utf8)) }
        let outcome = try reader(filesystem).readPrefix(forEntryID: ids["race.txt"]!)
        XCTAssertEqual(outcome, .sourceChanged)
        XCTAssertEqual(filesystem.readCalls, 0, "substitution is caught on the opened object before any content read")
    }

    func testSubstitutionAfterReadIsSourceChangedWithNoSecondRead() throws {
        try write("race.txt", Data("original".utf8))
        let ids = try capture([.init("race.txt", .file)])
        let filesystem = RecordingFilesystem()
        filesystem.afterRead = { [self] in replaceFile("race.txt", with: Data("substitute".utf8)) }
        let outcome = try reader(filesystem).readPrefix(forEntryID: ids["race.txt"]!)
        XCTAssertEqual(outcome, .sourceChanged)
        XCTAssertNil(prefix(outcome), "bytes read from a since-substituted path are never handed over")
        XCTAssertEqual(filesystem.readCalls, 1)
    }

    func testSubstitutionBySymlinkAfterReadIsSourceChanged() throws {
        try write("race.txt", Data("original".utf8))
        let ids = try capture([.init("race.txt", .file)])
        let filesystem = RecordingFilesystem()
        filesystem.afterRead = { [self] in
            try? FileManager.default.removeItem(at: source.appendingPathComponent("race.txt"))
            try? FileManager.default.createSymbolicLink(
                at: source.appendingPathComponent("race.txt"), withDestinationURL: outside.appendingPathComponent("secret.txt")
            )
        }
        XCTAssertEqual(try reader(filesystem).readPrefix(forEntryID: ids["race.txt"]!), .sourceChanged)
        XCTAssertEqual(filesystem.readCalls, 1)
    }

    func testFileDisappearingAfterReadOrBeforeOpenIsSourceChanged() throws {
        try write("gone-after.txt", Data("x".utf8))
        try write("gone-before.txt", Data("x".utf8))
        let ids = try capture([.init("gone-after.txt", .file), .init("gone-before.txt", .file)])

        let after = RecordingFilesystem()
        after.afterRead = { [self] in try? FileManager.default.removeItem(at: source.appendingPathComponent("gone-after.txt")) }
        XCTAssertEqual(try reader(after).readPrefix(forEntryID: ids["gone-after.txt"]!), .sourceChanged)
        XCTAssertEqual(after.readCalls, 1)

        let before = RecordingFilesystem()
        before.beforeOpenFile = { [self] _ in try? FileManager.default.removeItem(at: source.appendingPathComponent("gone-before.txt")) }
        XCTAssertEqual(try reader(before).readPrefix(forEntryID: ids["gone-before.txt"]!), .sourceChanged)
        XCTAssertEqual(before.readCalls, 0)
    }

    func testDirectoryDisappearingAfterValidationIsSourceChanged() throws {
        try write("sub/f.txt", Data("x".utf8))
        let ids = try capture([.init("sub", .directory), .init("sub/f.txt", .file)])
        let filesystem = RecordingFilesystem()
        filesystem.beforeOpenDirectory = { [self] _ in try? FileManager.default.removeItem(at: source.appendingPathComponent("sub")) }
        XCTAssertEqual(try reader(filesystem).readPrefix(forEntryID: ids["sub/f.txt"]!), .sourceChanged)
        XCTAssertEqual(filesystem.readCalls, 0)
    }

    func testDirectorySubstitutionBetweenWalksIsSourceChanged() throws {
        try write("sub/f.txt", Data("x".utf8))
        let ids = try capture([.init("sub", .directory), .init("sub/f.txt", .file)])
        let filesystem = RecordingFilesystem()
        filesystem.afterRead = { [self] in
            try? FileManager.default.moveItem(at: source.appendingPathComponent("sub"), to: source.appendingPathComponent("sub-old"))
            try? FileManager.default.createDirectory(at: source.appendingPathComponent("sub"), withIntermediateDirectories: false)
            try? Data("x".utf8).write(to: source.appendingPathComponent("sub/f.txt"))
        }
        XCTAssertEqual(try reader(filesystem).readPrefix(forEntryID: ids["sub/f.txt"]!), .sourceChanged)
        XCTAssertEqual(filesystem.readCalls, 1)
    }

    func testTruncationDuringReadIsSourceChanged() throws {
        try write("shrink.bin", pattern(10_000))
        let ids = try capture([.init("shrink.bin", .file)])
        let filesystem = RecordingFilesystem()
        filesystem.afterRead = { [self] in truncate(source.appendingPathComponent("shrink.bin").path, 10) }
        XCTAssertEqual(try reader(filesystem).readPrefix(forEntryID: ids["shrink.bin"]!), .sourceChanged)
        XCTAssertEqual(filesystem.readCalls, 1)
    }

    func testShortPlatformReadIsFailedAndNeverToppedUpWithASecondRead() throws {
        try write("big.bin", pattern(10_000))
        let ids = try capture([.init("big.bin", .file)])
        let filesystem = RecordingFilesystem()
        filesystem.forcedReadCount = 100
        let outcome = try reader(filesystem).readPrefix(forEntryID: ids["big.bin"]!)
        XCTAssertEqual(outcome, .failed)
        XCTAssertEqual(filesystem.readCalls, 1)
    }

    // MARK: - Permission and I/O failure

    func testPermissionFailureWithIdentifiedSourceIsFailed() throws {
        try write("locked.txt", Data("locked".utf8))
        let ids = try capture([.init("locked.txt", .file)])
        XCTAssertEqual(chmod(source.appendingPathComponent("locked.txt").path, 0), 0)
        let filesystem = RecordingFilesystem()
        let outcome = try reader(filesystem).readPrefix(forEntryID: ids["locked.txt"]!)
        XCTAssertEqual(outcome, .failed)
        XCTAssertEqual(filesystem.readCalls, 0)
    }

    func testInjectedPermissionAndIOFailuresAreFailedNotSourceChanged() throws {
        try write("a.txt", Data("a".utf8))
        let ids = try capture([.init("a.txt", .file)])
        for code in [EACCES, EPERM, EIO] {
            let open = RecordingFilesystem()
            open.openFileFailure = code
            XCTAssertEqual(try reader(open).readPrefix(forEntryID: ids["a.txt"]!), .failed, "open \(code)")
            let read = RecordingFilesystem()
            read.readFailure = code
            XCTAssertEqual(try reader(read).readPrefix(forEntryID: ids["a.txt"]!), .failed, "read \(code)")
            XCTAssertEqual(read.readCalls, 1, "a failed read is not retried")
        }
        let interrupted = RecordingFilesystem()
        interrupted.readFailure = EINTR
        XCTAssertEqual(try reader(interrupted).readPrefix(forEntryID: ids["a.txt"]!), .failed)
        XCTAssertEqual(interrupted.readCalls, 1, "EINTR is not retried")
    }

    // MARK: - Cancellation

    func testCancelBeforeResolutionStopsBeforeAnyResolutionOrIO() throws {
        try write("a.txt", Data("a".utf8))
        let ids = try capture([.init("a.txt", .file)])
        let filesystem = RecordingFilesystem()
        var detectCalls = 0
        let outcome = try reader(filesystem, detect: { [detected] _ in detectCalls += 1; return detected! },
                                 cancel: { $0 == .beforeResolution }).readPrefix(forEntryID: ids["a.txt"]!)
        XCTAssertEqual(outcome, .cancelled)
        XCTAssertEqual(detectCalls, 0)
        XCTAssertEqual(filesystem.mountOpens, 0)
    }

    func testCancelBeforeContentReadAndAfterOpenNeverReadContent() throws {
        try write("a.txt", Data("a".utf8))
        let ids = try capture([.init("a.txt", .file)])

        let beforeRead = RecordingFilesystem()
        XCTAssertEqual(
            try reader(beforeRead, cancel: { $0 == .beforeRead }).readPrefix(forEntryID: ids["a.txt"]!), .cancelled
        )
        XCTAssertEqual(beforeRead.mountOpens, 0)
        XCTAssertEqual(beforeRead.readCalls, 0)

        let afterOpen = RecordingFilesystem()
        XCTAssertEqual(
            try reader(afterOpen, cancel: { $0 == .afterOpen }).readPrefix(forEntryID: ids["a.txt"]!), .cancelled
        )
        XCTAssertEqual(afterOpen.fileOpens, ["a.txt"])
        XCTAssertEqual(afterOpen.readCalls, 0)
    }

    func testCancelAfterReadBeforeHandoffDiscardsTheBytes() throws {
        try write("a.txt", Data("sampled".utf8))
        let ids = try capture([.init("a.txt", .file)])
        let filesystem = RecordingFilesystem()
        let outcome = try reader(filesystem, cancel: { $0 == .afterRead }).readPrefix(forEntryID: ids["a.txt"]!)
        XCTAssertEqual(outcome, .cancelled)
        XCTAssertNil(prefix(outcome))
        XCTAssertEqual(filesystem.readCalls, 1)
    }

    func testCancellationDuringFailedReadOverridesIOFailureWithoutRetry() throws {
        try write("a.txt", Data("a".utf8))
        let ids = try capture([.init("a.txt", .file)])
        let filesystem = RecordingFilesystem()
        var cancelled = false
        filesystem.beforeRead = { cancelled = true }
        filesystem.readFailure = EINTR
        XCTAssertEqual(try reader(filesystem, cancel: { _ in cancelled })
            .readPrefix(forEntryID: ids["a.txt"]!), .cancelled)
        XCTAssertEqual(filesystem.readCalls, 1)
    }

    func testCancellationDuringReadOverridesConcurrentDisappearance() throws {
        try write("a.txt", Data("a".utf8))
        let ids = try capture([.init("a.txt", .file)])
        let filesystem = RecordingFilesystem()
        var cancelled = false
        filesystem.afterRead = { [self] in
            cancelled = true
            try? FileManager.default.removeItem(at: source.appendingPathComponent("a.txt"))
        }
        XCTAssertEqual(try reader(filesystem, cancel: { _ in cancelled })
            .readPrefix(forEntryID: ids["a.txt"]!), .cancelled)
        XCTAssertEqual(filesystem.readCalls, 1)
    }

    func testObservedTaskCancellationIsCancelled() async throws {
        try write("a.txt", Data("a".utf8))
        let ids = try capture([.init("a.txt", .file)])
        let filesystem = RecordingFilesystem()
        let reader = BoundedClassificationSourceReader(
            database: database,
            detectMount: { try FilesystemDetector().detect(root: $0) },
            filesystem: filesystem,
            isCancelled: { _ in Task.isCancelled }
        )
        let id = ids["a.txt"]!
        let task = Task { () -> BoundedClassificationSourceOutcome in
            while !Task.isCancelled { await Task.yield() }
            return try reader.readPrefix(forEntryID: id)
        }
        task.cancel()
        let outcome = try await task.value
        XCTAssertEqual(outcome, .cancelled)
        XCTAssertEqual(filesystem.readCalls, 0)
    }

    // MARK: - Immutability

    func testReaderNeverWritesTheCatalogOrTheSource() throws {
        let bytes = pattern(5000)
        try write("keep.bin", bytes)
        let ids = try capture([.init("keep.bin", .file), .init("dir", .directory)])
        let snapshotID = SnapshotID(rawValue: try XCTUnwrap(
            try database.scalar("SELECT snapshot_id FROM entries WHERE id = ?", bindings: [.integer(ids["keep.bin"]!)])?.int64Value
        ))
        let beforeEntries = try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: snapshotID)
        let beforeSnapshot = try EntrySnapshotProbe.snapshotFingerprint(database: database, snapshotID: snapshotID)
        var before = stat()
        XCTAssertEqual(stat(source.appendingPathComponent("keep.bin").path, &before), 0)

        let reader = reader(RecordingFilesystem())
        XCTAssertEqual(prefix(try reader.readPrefix(forEntryID: ids["keep.bin"]!)), bytes.prefix(4096))
        XCTAssertEqual(try reader.readPrefix(forEntryID: ids["dir"]!), .unsupportedEntry)

        var after = stat()
        XCTAssertEqual(stat(source.appendingPathComponent("keep.bin").path, &after), 0)
        XCTAssertEqual(before.st_mtimespec.tv_sec, after.st_mtimespec.tv_sec)
        XCTAssertEqual(before.st_mtimespec.tv_nsec, after.st_mtimespec.tv_nsec)
        XCTAssertEqual(before.st_size, after.st_size)
        XCTAssertEqual(before.st_ino, after.st_ino)
        XCTAssertEqual(try Data(contentsOf: source.appendingPathComponent("keep.bin")), bytes)
        XCTAssertEqual(try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: snapshotID), beforeEntries)
        XCTAssertEqual(try EntrySnapshotProbe.snapshotFingerprint(database: database, snapshotID: snapshotID), beforeSnapshot)
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
    }

    func testPreProviderResultMapsEveryReaderOutcomeToTheLockedVocabulary() throws {
        let request = try XCTUnwrap(LocalClassificationRequest(boundedPrefix: Data([1])))
        XCTAssertNil(BoundedClassificationSourceOutcome.prefix(request).preProviderResult)
        XCTAssertEqual(BoundedClassificationSourceOutcome.failed.preProviderResult, .failed)
        XCTAssertEqual(BoundedClassificationSourceOutcome.sourceChanged.preProviderResult, .sourceChanged)
        XCTAssertEqual(BoundedClassificationSourceOutcome.unsupportedEntry.preProviderResult, .unsupportedEntry)
        XCTAssertEqual(BoundedClassificationSourceOutcome.unavailable.preProviderResult, .unavailable)
        XCTAssertEqual(BoundedClassificationSourceOutcome.cancelled.preProviderResult, .cancelled)
    }

    // MARK: - Helpers

    private struct Fixture {
        let path: String
        let kind: FilesystemItemKind
        let isPackage: Bool
        init(_ path: String, _ kind: FilesystemItemKind, isPackage: Bool = false) {
            self.path = path
            self.kind = kind
            self.isPackage = isPackage
        }
    }

    private func reader(
        _ filesystem: BoundedSourceFilesystem,
        detect: ((URL) throws -> FilesystemDescriptor)? = nil,
        cancel: @escaping (Boundary) -> Bool = { _ in false }
    ) -> BoundedClassificationSourceReader {
        BoundedClassificationSourceReader(
            database: database,
            detectMount: detect ?? { try FilesystemDetector().detect(root: $0) },
            filesystem: filesystem,
            isCancelled: cancel
        )
    }

    /// Captures a manual v9 snapshot through the production `SnapshotWriter`
    /// (real detector descriptor, so the stored locator and identity are
    /// genuine) with caller-chosen stored entries.
    private func capture(_ fixtures: [Fixture]) throws -> [String: Int64] {
        let session = try SnapshotWriter(database: database).beginCapture(descriptor: detected, scanRootName: "source")
        try session.append(contentsOf: fixtures.map(Self.entry))
        try session.finish(preferredStatus: .complete)
        let rows = try database.query(
            "SELECT id, relative_path FROM entries WHERE snapshot_id = ?",
            bindings: [.integer(session.snapshotID.rawValue)]
        )
        var ids: [String: Int64] = [:]
        for row in rows {
            if let path = row["relative_path"]?.stringValue, let id = row["id"]?.int64Value { ids[path] = id }
        }
        return ids
    }

    private static func entry(_ fixture: Fixture) -> MetadataEntry {
        let name = fixture.path.split(separator: "/").last.map(String.init) ?? fixture.path
        return MetadataEntry(
            relativePath: fixture.path, parentRelativePath: "", name: name,
            casePreservingPath: fixture.path, caseFoldedPath: fixture.path.lowercased(),
            casePreservingName: name, caseFoldedName: name.lowercased(), fileExtension: nil,
            itemKind: fixture.kind, logicalSizeBytes: nil, allocatedSizeBytes: nil, createdAt: nil,
            modifiedAt: nil, contentTypeIdentifier: nil, resourceIdentifier: nil, symlinkTarget: nil,
            isHidden: false, isPackage: fixture.isPackage, isInaccessible: false, sortKey: fixture.path
        )
    }

    /// Inserts a snapshot row directly so schema version, mount, identity,
    /// locator and status can be set independently of the production writer.
    private func rawSnapshot(
        schema: Int64,
        mount: String?,
        identity: String?,
        rootLocator: String = "",
        status: String = "complete",
        files: [String]
    ) throws -> [String: Int64] {
        rawSnapshotCounter += 1
        let volumeID = 700 + rawSnapshotCounter
        let snapshotID = 7000 + rawSnapshotCounter
        try database.execute(
            """
            INSERT INTO volumes (id, display_name, first_seen_at, last_seen_at, created_at, updated_at)
            VALUES (?, 'Raw', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            """,
            bindings: [.integer(volumeID)]
        )
        try database.execute(
            """
            INSERT INTO snapshots (
                id, volume_id, session_number, scan_root_name, mount_path_at_capture, root_relative_path, status,
                scanner_version, schema_version, normalization_version, display_name, capture_policy_json,
                volume_identifier_at_capture, started_at, created_at, updated_at
            ) VALUES (?, ?, 1, 'Raw', ?, ?, 'scanning', 'raw', ?, ?, 'Raw', '{}', ?,
                      CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            """,
            bindings: [
                .integer(snapshotID), .integer(volumeID),
                mount.map(DatabaseValue.text) ?? .null, .text(rootLocator), .integer(schema),
                .text(NormalizationVersion.current.rawValue), identity.map(DatabaseValue.text) ?? .null
            ]
        )
        let base = snapshotID * 100
        var seeds = [SyntheticSnapshot.root(id: base)]
        var ids: [String: Int64] = [:]
        for (offset, path) in files.enumerated() {
            let id = base + Int64(offset) + 1
            seeds.append(SyntheticSnapshot.SeedEntry(id: id, parentID: base, relativePath: path, name: path))
            ids[path] = id
        }
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: SnapshotID(rawValue: snapshotID), entries: seeds)
        if status != "scanning" {
            try database.execute(
                "UPDATE snapshots SET status = ?, completed_at = CURRENT_TIMESTAMP WHERE id = ?",
                bindings: [.text(status), .integer(snapshotID)]
            )
        }
        return ids
    }

    private func snapshotFacts() throws -> String {
        let rows = try database.query(
            """
            SELECT id, schema_version, root_relative_path, mount_path_at_capture, volume_identifier_at_capture, status
            FROM snapshots ORDER BY id
            """
        )
        return rows.map { row in
            ["id", "schema_version", "root_relative_path", "mount_path_at_capture", "volume_identifier_at_capture", "status"]
                .map { column in row[column]?.stringValue ?? row[column]?.int64Value.map(String.init) ?? "NULL" }
                .joined(separator: "|")
        }.joined(separator: "\n")
    }

    private func entryID(_ path: String, snapshot: SnapshotID) throws -> Int64 {
        try XCTUnwrap(try database.scalar(
            "SELECT id FROM entries WHERE snapshot_id = ? AND relative_path = ?",
            bindings: [.integer(snapshot.rawValue), .text(path)]
        )?.int64Value)
    }

    private func write(_ relative: String, _ data: Data) throws {
        let url = source.appendingPathComponent(relative)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }

    private func replaceFile(_ relative: String, with data: Data) {
        let target = source.appendingPathComponent(relative)
        let temporary = source.appendingPathComponent(".swap-\(UUID().uuidString)")
        try? data.write(to: temporary)
        _ = rename(temporary.path, target.path)
    }

    private func pattern(_ count: Int) -> Data {
        Data((0..<count).map { UInt8(truncatingIfNeeded: ($0 &* 31) &+ ($0 >> 8)) })
    }

    private func prefix(_ outcome: BoundedClassificationSourceOutcome) -> Data? {
        if case let .prefix(request) = outcome { return request.data }
        return nil
    }
}

/// Test-owned wrapper around the real Darwin primitives. It counts calls and
/// lets a test run a one-shot mutation at a precise point, simulating a racing
/// or hostile source without any production seam beyond the reader's own.
private final class RecordingFilesystem: BoundedSourceFilesystem {
    private let real = DarwinBoundedSourceFilesystem()
    private(set) var mountOpens = 0
    private(set) var directoryOpens: [String] = []
    private(set) var fileOpens: [String] = []
    private(set) var readCalls = 0
    private(set) var readRequestSizes: [Int] = []

    var beforeOpenDirectory: ((String) -> Void)?
    var beforeOpenFile: ((String) -> Void)?
    var beforeRead: (() -> Void)?
    var afterRead: (() -> Void)?
    var openFileFailure: Int32?
    var readFailure: Int32?
    var forcedReadCount: Int?

    func openMountRoot(path: String) throws -> Int32 {
        mountOpens += 1
        return try real.openMountRoot(path: path)
    }

    func openDirectory(parent: Int32, name: String) throws -> Int32 {
        directoryOpens.append(name)
        if let hook = beforeOpenDirectory { beforeOpenDirectory = nil; hook(name) }
        return try real.openDirectory(parent: parent, name: name)
    }

    func statNoFollow(parent: Int32, name: String) throws -> ClassificationFileStat {
        try real.statNoFollow(parent: parent, name: name)
    }

    func openRegularFile(parent: Int32, name: String) throws -> Int32 {
        fileOpens.append(name)
        if let hook = beforeOpenFile { beforeOpenFile = nil; hook(name) }
        if let code = openFileFailure { throw ClassificationPOSIXFailure(code: code) }
        return try real.openRegularFile(parent: parent, name: name)
    }

    func stat(descriptor: Int32) throws -> ClassificationFileStat {
        try real.stat(descriptor: descriptor)
    }

    func readOnce(descriptor: Int32, into buffer: UnsafeMutableRawBufferPointer) throws -> Int {
        readCalls += 1
        readRequestSizes.append(buffer.count)
        if let hook = beforeRead { beforeRead = nil; hook() }
        if let code = readFailure { throw ClassificationPOSIXFailure(code: code) }
        var count = try real.readOnce(descriptor: descriptor, into: buffer)
        if let forced = forcedReadCount { count = min(count, forced) }
        if let hook = afterRead { afterRead = nil; hook() }
        return count
    }

    func close(descriptor: Int32) {
        real.close(descriptor: descriptor)
    }
}
