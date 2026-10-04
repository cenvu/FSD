import XCTest
@testable import FSD

/// Reports a chosen path — and everything beneath it — as living on a different
/// filesystem, so the mount-boundary policy can be exercised without mounting
/// anything.
private struct FakeDeviceIdentityProbe: DeviceIdentityProbe {
    let rootDevice: dev_t
    let foreignDevice: dev_t
    let foreignPrefix: String

    func deviceIdentifier(atPath path: String) throws -> dev_t {
        let standardized = URL(fileURLWithPath: path).standardizedFileURL.path
        if standardized == foreignPrefix || standardized.hasPrefix(foreignPrefix + "/") {
            return foreignDevice
        }
        return rootDevice
    }
}

private struct FailingDeviceIdentityProbe: DeviceIdentityProbe {
    func deviceIdentifier(atPath path: String) throws -> dev_t {
        throw FilesystemProviderError.metadataUnavailable(path)
    }
}

final class MilestoneConditionTests: XCTestCase {
    private var directory: URL!
    private var source: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-Conditions-\(UUID().uuidString)", isDirectory: true)
        source = directory.appendingPathComponent("source", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        directory = nil
        source = nil
    }

    // MARK: - C3: nested mount boundary

    func testNestedMountIsRecordedButNotDescendedInto() throws {
        let mountPoint = source.appendingPathComponent("attached", isDirectory: true)
        try FileManager.default.createDirectory(at: mountPoint.appendingPathComponent("deep/deeper"), withIntermediateDirectories: true)
        try Data("other filesystem".utf8).write(to: mountPoint.appendingPathComponent("inside.txt"))
        try Data("other filesystem".utf8).write(to: mountPoint.appendingPathComponent("deep/deeper/buried.txt"))
        try FileManager.default.createDirectory(at: source.appendingPathComponent("local"), withIntermediateDirectories: true)
        try Data("same filesystem".utf8).write(to: source.appendingPathComponent("local/kept.txt"))

        let descriptor = try FilesystemDetector().detect(root: source)
        let probe = FakeDeviceIdentityProbe(
            rootDevice: 1, foreignDevice: 2,
            foreignPrefix: mountPoint.standardizedFileURL.resolvingSymlinksInPath().path
        )
        let provider = NativeMountedProvider(descriptor: descriptor, deviceProbe: probe)

        var entries: [MetadataEntry] = []
        var issues: [ScanIssue] = []
        let result = try provider.enumerate(
            onEntry: { entries.append($0) }, onIssue: { issues.append($0) },
            onProgress: { _ in }, isCancelled: { false }
        )

        // The mount point itself is recorded as metadata.
        XCTAssertTrue(entries.contains { $0.relativePath == "attached" && $0.itemKind == .directory })
        // Nothing below it is.
        XCTAssertFalse(entries.contains { $0.relativePath.hasPrefix("attached/") })
        // The rest of the selected root is unaffected.
        XCTAssertTrue(entries.contains { $0.relativePath == "local/kept.txt" })
        // Exactly one bounded issue, so the skipped subtree is never mistaken
        // for an empty one.
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues[0].relativePath, "attached")
        XCTAssertEqual(issues[0].message, NativeMountedProvider.mountBoundaryMessage)
        XCTAssertEqual(issues[0].severity, "warning")
        XCTAssertTrue(issues[0].wasSkipped)
        XCTAssertEqual(result.issueCount, 1)
    }

    func testCaptureAcrossAMountBoundaryCompletesWithWarnings() throws {
        let mountPoint = source.appendingPathComponent("attached", isDirectory: true)
        try FileManager.default.createDirectory(at: mountPoint, withIntermediateDirectories: true)
        try Data().write(to: mountPoint.appendingPathComponent("inside.txt"))

        let database = try makeDatabase()
        let probe = FakeDeviceIdentityProbe(
            rootDevice: 10, foreignDevice: 11,
            foreignPrefix: mountPoint.standardizedFileURL.resolvingSymlinksInPath().path
        )
        let scanner = SnapshotScanner(
            database: database,
            providerFactory: { NativeMountedProvider(descriptor: $0, deviceProbe: probe) }
        )

        let record = try scanner.capture(root: source)

        XCTAssertEqual(record.status, .completeWithWarnings, "a skipped subtree is not a clean enumeration")
        let issues = try SnapshotHistoryRepository(database: database).issues(for: record.id)
        XCTAssertEqual(issues.map(\.message), [NativeMountedProvider.mountBoundaryMessage])
        XCTAssertEqual(
            try database.scalar(
                "SELECT COUNT(*) FROM entries WHERE snapshot_id = ? AND relative_path LIKE 'attached/%'",
                bindings: [.integer(record.id.rawValue)]
            )?.int64Value,
            0
        )
    }

    func testMountGuardNeverInventsABoundaryItCannotObserve() throws {
        try FileManager.default.createDirectory(at: source.appendingPathComponent("plain"), withIntermediateDirectories: true)
        try Data().write(to: source.appendingPathComponent("plain/file.txt"))

        let descriptor = try FilesystemDetector().detect(root: source)
        let provider = NativeMountedProvider(descriptor: descriptor, deviceProbe: FailingDeviceIdentityProbe())

        var entries: [MetadataEntry] = []
        var issues: [ScanIssue] = []
        _ = try provider.enumerate(
            onEntry: { entries.append($0) }, onIssue: { issues.append($0) },
            onProgress: { _ in }, isCancelled: { false }
        )

        XCTAssertTrue(issues.isEmpty, "an unreadable device identity is not evidence of a mount boundary")
        XCTAssertTrue(entries.contains { $0.relativePath == "plain/file.txt" })
    }

    func testMountGuardIsSeparateFromSymlinkHandling() throws {
        let outside = directory.appendingPathComponent("outside", isDirectory: true)
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
        try Data().write(to: outside.appendingPathComponent("secret.txt"))
        try FileManager.default.createSymbolicLink(at: source.appendingPathComponent("link"), withDestinationURL: outside)

        let descriptor = try FilesystemDetector().detect(root: source)
        let probe = FakeDeviceIdentityProbe(rootDevice: 1, foreignDevice: 2, foreignPrefix: outside.standardizedFileURL.path)
        let provider = NativeMountedProvider(descriptor: descriptor, deviceProbe: probe)

        var entries: [MetadataEntry] = []
        var issues: [ScanIssue] = []
        _ = try provider.enumerate(
            onEntry: { entries.append($0) }, onIssue: { issues.append($0) },
            onProgress: { _ in }, isCancelled: { false }
        )

        XCTAssertTrue(entries.contains { $0.relativePath == "link" && $0.itemKind == .symlink })
        XCTAssertFalse(entries.contains { $0.relativePath.contains("secret") })
        XCTAssertTrue(issues.isEmpty, "a symlink is handled as a symlink, never as a mount boundary")
    }

    /// The abstraction test above proves the policy. This one proves the policy
    /// matches a real mount, and is skipped rather than faked when the host
    /// cannot create or attach a disk image.
    func testNestedMountBoundaryAgainstAGeneratedDiskImage() throws {
        guard FileManager.default.fileExists(atPath: "/usr/bin/hdiutil") else {
            throw XCTSkip("ENVIRONMENT-BLOCKED — hdiutil is unavailable")
        }
        let imageURL = directory.appendingPathComponent("nested.dmg")
        let mountPoint = source.appendingPathComponent("attached", isDirectory: true)
        try FileManager.default.createDirectory(at: mountPoint, withIntermediateDirectories: true)

        guard Self.run("/usr/bin/hdiutil", ["create", "-size", "10m", "-fs", "HFS+", "-volname", "FSDNested",
                                            "-quiet", imageURL.path]) == 0 else {
            throw XCTSkip("ENVIRONMENT-BLOCKED — hdiutil could not create a test image")
        }
        guard Self.run("/usr/bin/hdiutil", ["attach", imageURL.path, "-mountpoint", mountPoint.path,
                                            "-nobrowse", "-quiet"]) == 0 else {
            throw XCTSkip("ENVIRONMENT-BLOCKED — hdiutil could not attach a test image")
        }
        defer { _ = Self.run("/usr/bin/hdiutil", ["detach", mountPoint.path, "-force", "-quiet"]) }

        try Data("inside the nested filesystem".utf8).write(to: mountPoint.appendingPathComponent("inside.txt"))
        try FileManager.default.createDirectory(at: mountPoint.appendingPathComponent("deep"), withIntermediateDirectories: true)
        try Data().write(to: mountPoint.appendingPathComponent("deep/buried.txt"))
        try Data().write(to: source.appendingPathComponent("kept.txt"))

        let descriptor = try FilesystemDetector().detect(root: source)
        let provider = NativeMountedProvider(descriptor: descriptor)
        var entries: [MetadataEntry] = []
        var issues: [ScanIssue] = []
        _ = try provider.enumerate(
            onEntry: { entries.append($0) }, onIssue: { issues.append($0) },
            onProgress: { _ in }, isCancelled: { false }
        )

        XCTAssertTrue(entries.contains { $0.relativePath == "attached" })
        XCTAssertTrue(entries.contains { $0.relativePath == "kept.txt" })
        XCTAssertFalse(entries.contains { $0.relativePath.hasPrefix("attached/") })
        XCTAssertEqual(issues.filter { $0.message == NativeMountedProvider.mountBoundaryMessage }.count, 1)
    }

    // MARK: - Regression: a symlink must not suppress a sibling directory

    /// Milestone 2 called `skipDescendants()` for symlinks as well as packages.
    /// `skipDescendants()` skips "the most recently obtained subdirectory", and a
    /// symlink is not one, so the enumerator skipped descent into the next
    /// directory at that level instead — dropping a whole subtree from the
    /// snapshot with no scan issue and no error.
    ///
    /// Whether it bit depended on enumeration order, which is directory order,
    /// not alphabetical. The fixture below is built so the symlink is returned
    /// before its sibling directory.
    func testSymlinkDoesNotSuppressASiblingDirectorySubtree() throws {
        // Created in this order so the symlink is enumerated first.
        try FileManager.default.createSymbolicLink(
            at: source.appendingPathComponent("alias"),
            withDestinationURL: source.appendingPathComponent("Nested/leaf.txt")
        )
        try FileManager.default.createDirectory(
            at: source.appendingPathComponent("Nested/Deeper"), withIntermediateDirectories: true
        )
        try Data("kept".utf8).write(to: source.appendingPathComponent("Nested/leaf.txt"))
        try Data("kept".utf8).write(to: source.appendingPathComponent("Nested/Deeper/buried.txt"))

        let descriptor = try FilesystemDetector().detect(root: source)
        var entries: [MetadataEntry] = []
        var issues: [ScanIssue] = []
        _ = try NativeMountedProvider(descriptor: descriptor).enumerate(
            onEntry: { entries.append($0) }, onIssue: { issues.append($0) },
            onProgress: { _ in }, isCancelled: { false }
        )

        let paths = Set(entries.map(\.relativePath))
        XCTAssertTrue(paths.contains("alias"))
        XCTAssertTrue(paths.contains("Nested"))
        XCTAssertTrue(paths.contains("Nested/leaf.txt"), "the sibling subtree must survive the symlink")
        XCTAssertTrue(paths.contains("Nested/Deeper"))
        XCTAssertTrue(paths.contains("Nested/Deeper/buried.txt"))
        XCTAssertTrue(issues.isEmpty)
    }

    /// The other half of the same fix: a symlink to a directory is still recorded
    /// and still never traversed.
    func testSymlinkToADirectoryIsRecordedAndNeverTraversed() throws {
        let outside = directory.appendingPathComponent("outside", isDirectory: true)
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
        try Data("secret".utf8).write(to: outside.appendingPathComponent("secret.txt"))
        try FileManager.default.createSymbolicLink(
            at: source.appendingPathComponent("dirlink"), withDestinationURL: outside
        )
        try FileManager.default.createDirectory(
            at: source.appendingPathComponent("Inside"), withIntermediateDirectories: true
        )
        try Data("kept".utf8).write(to: source.appendingPathComponent("Inside/kept.txt"))

        let descriptor = try FilesystemDetector().detect(root: source)
        var entries: [MetadataEntry] = []
        _ = try NativeMountedProvider(descriptor: descriptor).enumerate(
            onEntry: { entries.append($0) }, onIssue: { _ in },
            onProgress: { _ in }, isCancelled: { false }
        )

        let link = try XCTUnwrap(entries.first { $0.relativePath == "dirlink" })
        XCTAssertEqual(link.itemKind, .symlink)
        XCTAssertEqual(link.symlinkTarget, outside.path)
        XCTAssertFalse(entries.contains { $0.relativePath.hasPrefix("dirlink/") })
        XCTAssertFalse(entries.contains { $0.relativePath.contains("secret") })
        XCTAssertTrue(entries.contains { $0.relativePath == "Inside/kept.txt" })
    }

    /// A package is a real subdirectory, so skipping its descendants is the
    /// documented use of `skipDescendants()` and must keep working.
    func testPackageContentsAreStillSkippedAtomically() throws {
        try FileManager.default.createDirectory(
            at: source.appendingPathComponent("Bundle.rtfd"), withIntermediateDirectories: true
        )
        try Data("inside a package".utf8).write(to: source.appendingPathComponent("Bundle.rtfd/TXT.rtf"))
        try FileManager.default.createDirectory(
            at: source.appendingPathComponent("Plain"), withIntermediateDirectories: true
        )
        try Data("kept".utf8).write(to: source.appendingPathComponent("Plain/kept.txt"))

        let descriptor = try FilesystemDetector().detect(root: source)
        var entries: [MetadataEntry] = []
        _ = try NativeMountedProvider(descriptor: descriptor).enumerate(
            onEntry: { entries.append($0) }, onIssue: { _ in },
            onProgress: { _ in }, isCancelled: { false }
        )

        XCTAssertEqual(entries.first { $0.relativePath == "Bundle.rtfd" }?.itemKind, .package)
        XCTAssertFalse(entries.contains { $0.relativePath.hasPrefix("Bundle.rtfd/") })
        XCTAssertTrue(entries.contains { $0.relativePath == "Plain/kept.txt" })
    }

    // MARK: - C5: single-process ownership

    func testASecondProcessCannotTakeTheSameCatalog() throws {
        let catalogURL = directory.appendingPathComponent("locked.sqlite3")
        let first = try CatalogProcessLock(catalogURL: catalogURL)
        XCTAssertTrue(first.isHeld)

        XCTAssertThrowsError(try CatalogProcessLock(catalogURL: catalogURL)) { error in
            guard case let CatalogProcessLock.LockError.alreadyLocked(url, pid) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(url.lastPathComponent, "locked.sqlite3.lock")
            XCTAssertEqual(pid, getpid(), "the lock file names its owner for diagnostics")
            XCTAssertTrue(
                (error as? CatalogProcessLock.LockError)?.errorDescription?.contains("Only one FSD process") ?? false,
                "the failure must be explainable to a user"
            )
        }
    }

    func testSeparateCatalogsAreLockedIndependently() throws {
        let a = try CatalogProcessLock(catalogURL: directory.appendingPathComponent("a.sqlite3"))
        let b = try CatalogProcessLock(catalogURL: directory.appendingPathComponent("b.sqlite3"))
        XCTAssertTrue(a.isHeld)
        XCTAssertTrue(b.isHeld)
    }

    func testReleasingTheLockLetsTheNextProcessStart() throws {
        let catalogURL = directory.appendingPathComponent("released.sqlite3")
        let first = try CatalogProcessLock(catalogURL: catalogURL)
        first.unlock()
        XCTAssertFalse(first.isHeld)

        // The lock file is still on disk; a stale file must never be treated as
        // a held lock, because the advisory lock is what actually owns it.
        XCTAssertTrue(FileManager.default.fileExists(atPath: catalogURL.appendingPathExtension("lock").path))
        let second = try CatalogProcessLock(catalogURL: catalogURL)
        XCTAssertTrue(second.isHeld)
        second.unlock()
    }

    func testUnlockIsIdempotent() throws {
        let lock = try CatalogProcessLock(catalogURL: directory.appendingPathComponent("idempotent.sqlite3"))
        lock.unlock()
        lock.unlock()
        XCTAssertFalse(lock.isHeld)
    }

    func testTheLockLivesBesideTheCatalogAndNotOnAnySource() throws {
        let catalogURL = directory.appendingPathComponent("beside.sqlite3")
        let lock = try CatalogProcessLock(catalogURL: catalogURL)
        defer { lock.unlock() }

        XCTAssertEqual(lock.lockURL.deletingLastPathComponent().path, catalogURL.deletingLastPathComponent().path)
        let sourceContents = try FileManager.default.contentsOfDirectory(atPath: source.path)
        XCTAssertTrue(sourceContents.isEmpty, "nothing is ever written to a scanned source")
    }

    // MARK: - C6: catalog path override

    func testDefaultCatalogPathIsApplicationSupport() throws {
        let location = try CatalogLocationResolver.resolve(arguments: ["FSD"], environment: [:])

        XCTAssertEqual(location.origin, .applicationSupport)
        XCTAssertFalse(location.isOverridden)
        XCTAssertNil(location.rejectedOverridePath)
        XCTAssertTrue(location.url.path.hasSuffix("Application Support/FSD/catalog.sqlite3"), location.url.path)
        XCTAssertTrue(location.diagnosticLine.contains("applicationSupport"))
    }

    func testLaunchArgumentOverrideIsHonouredWhenAvailable() throws {
        let target = directory.appendingPathComponent("isolated", isDirectory: true)
        let location = try CatalogLocationResolver.resolve(
            arguments: ["FSD", CatalogLocationResolver.launchArgumentName, target.path],
            environment: [:],
            overrideAllowed: true
        )

        XCTAssertEqual(location.origin, .launchArgument)
        XCTAssertTrue(location.isOverridden)
        XCTAssertEqual(location.url, target.appendingPathComponent("catalog.sqlite3"))
        XCTAssertTrue(location.diagnosticLine.contains(location.url.path))
    }

    func testEnvironmentOverrideIsHonouredAndAFileNameIsTakenLiterally() throws {
        let explicitFile = directory.appendingPathComponent("named.sqlite3")
        let location = try CatalogLocationResolver.resolve(
            arguments: ["FSD"],
            environment: [CatalogLocationResolver.environmentVariableName: explicitFile.path],
            overrideAllowed: true
        )

        XCTAssertEqual(location.origin, .environment)
        XCTAssertEqual(location.url, explicitFile)
    }

    func testLaunchArgumentWinsOverEnvironment() throws {
        let argument = directory.appendingPathComponent("from-argument", isDirectory: true)
        let location = try CatalogLocationResolver.resolve(
            arguments: ["FSD", CatalogLocationResolver.launchArgumentName, argument.path],
            environment: [CatalogLocationResolver.environmentVariableName: "/tmp/from-environment"],
            overrideAllowed: true
        )

        XCTAssertEqual(location.origin, .launchArgument)
        XCTAssertEqual(location.url.deletingLastPathComponent().lastPathComponent, "from-argument")
    }

    func testOverrideIsRefusedAndReportedWhenNotAvailable() throws {
        let location = try CatalogLocationResolver.resolve(
            arguments: ["FSD", CatalogLocationResolver.launchArgumentName, "/tmp/should-not-be-used"],
            environment: [:],
            overrideAllowed: false
        )

        XCTAssertEqual(location.origin, .applicationSupport, "a release build never silently accepts an arbitrary path")
        XCTAssertEqual(location.rejectedOverridePath, "/tmp/should-not-be-used")
        XCTAssertTrue(location.diagnosticLine.contains("ignored"), location.diagnosticLine)
        XCTAssertFalse(location.url.path.contains("should-not-be-used"))
    }

    func testAnOverriddenCatalogIsUsableAndFullyIsolated() throws {
        let isolated = directory.appendingPathComponent("isolated-catalog", isDirectory: true)
        let location = try CatalogLocationResolver.resolve(
            arguments: ["FSD", CatalogLocationResolver.launchArgumentName, isolated.path],
            environment: [:],
            overrideAllowed: true
        )
        let database = try CatalogDatabase(url: location.url, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)

        XCTAssertEqual(try database.schemaVersion, 9)
        XCTAssertTrue(FileManager.default.fileExists(atPath: location.url.path))
        let defaultURL = try CatalogLocationResolver.defaultURL()
        XCTAssertNotEqual(location.url.path, defaultURL.path)
    }

    /// FSD's test bundle is hosted by the FSD application, so every `xcodebuild
    /// test` run starts a real `ApplicationModel`. Before this was handled, that
    /// model opened, migrated and locked the person's actual catalog on every
    /// run — the exact thing an automated probe must never touch.
    func testATestHostNeverResolvesTheRealCatalog() throws {
        let resolved = try CatalogLocationResolver.resolve(
            arguments: ["FSD"],
            environment: ["XCTestConfigurationFilePath": "/some/path/Test.xctestconfiguration"]
        )

        XCTAssertEqual(resolved.origin, .testHost)
        XCTAssertTrue(resolved.url.path.hasPrefix(FileManager.default.temporaryDirectory.path), resolved.url.path)
        XCTAssertNotEqual(resolved.url, try CatalogLocationResolver.defaultURL())

        // And the process actually running this assertion is such a host.
        XCTAssertTrue(CatalogLocationResolver.isRunningAsTestHost())
        let live = try CatalogLocationResolver.resolve(arguments: ["FSD"])
        XCTAssertEqual(live.origin, .testHost)
        XCTAssertNotEqual(live.url, try CatalogLocationResolver.defaultURL())
    }

    /// An explicit override still wins inside a test host, so the matrix probe
    /// can aim a run at a catalog of its choosing.
    func testAnExplicitOverrideStillWinsInsideATestHost() throws {
        let target = directory.appendingPathComponent("host-override", isDirectory: true)
        let resolved = try CatalogLocationResolver.resolve(
            arguments: ["FSD", CatalogLocationResolver.launchArgumentName, target.path],
            environment: ["XCTestConfigurationFilePath": "/some/path/Test.xctestconfiguration"],
            overrideAllowed: true
        )

        XCTAssertEqual(resolved.origin, .launchArgument)
        XCTAssertEqual(resolved.url, target.appendingPathComponent("catalog.sqlite3"))
    }

    func testDebugBuildsExposeTheOverride() throws {
        // The override exists so that tests and Agent probes never have to share
        // the project owner's real catalog. If this ever compiles to false in a
        // Debug build, the isolation this milestone added is gone. Release
        // builds deliberately refuse overrides (ADR-026), so the assertion
        // applies to Debug only and the test is skipped under Release rather
        // than failing the suite.
        #if DEBUG
        XCTAssertTrue(CatalogLocationResolver.overrideIsAvailable)
        #else
        throw XCTSkip("The catalog override is a DEBUG-only affordance (ADR-026); Release builds deliberately refuse it")
        #endif
    }

    // MARK: - Helpers

    private func makeDatabase() throws -> CatalogDatabase {
        try CatalogDatabase(
            url: directory.appendingPathComponent("catalog.sqlite3"),
            schemaURL: CatalogSchemaFixture.canonicalSchemaURL
        )
    }

    private static func run(_ launchPath: String, _ arguments: [String]) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        } catch {
            return -1
        }
    }
}
