import CryptoKit
import XCTest
@testable import FSD

/// The automatable portion of Manual Session A (`docs/TEST_PLAN.md` §8).
///
/// Manual Session A remains **NOT PERFORMED — DEFERRED BY OWNER**. Nothing here
/// is a substitute for a human looking at the window: A1 (launch appearance),
/// the visible "Content Not Verified" wording, and physically disconnecting a
/// drive mid-scan still need the project owner. What these tests do cover is
/// every claim in that session that can be settled by evidence instead of
/// observation — a controlled capture, the source being byte-for-byte untouched,
/// cancellation never reporting completion, state surviving a relaunch, and
/// startup recovery of an orphaned scan.
///
/// Each test runs against its own catalog under the test temporary directory, so
/// none of it can reach the project owner's real catalog.
final class ManualSessionASubstituteTests: XCTestCase {
    private var directory: URL!
    private var catalogURL: URL!
    private var fixture: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-SessionA-\(UUID().uuidString)", isDirectory: true)
        catalogURL = directory.appendingPathComponent("isolated/catalog.sqlite3")
        fixture = directory.appendingPathComponent("fixture", isDirectory: true)
        try makeControlledFixture()
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        directory = nil
        catalogURL = nil
        fixture = nil
    }

    /// A2b — capture a controlled fixture through the production capture service.
    func testControlledFixtureCaptureReachesCompleteWithMatchingTotals() throws {
        let database = try openCatalog()
        let expected = try expectedCounts()

        let record = try SnapshotScanner(database: database).capture(root: fixture)

        XCTAssertEqual(record.status, .complete)
        let summary = try XCTUnwrap(try SnapshotHistoryRepository(database: database).summary(id: record.id))
        XCTAssertEqual(summary.totalFiles, expected.files)
        XCTAssertEqual(summary.totalFolders, expected.folders)
        XCTAssertEqual(summary.inaccessibleItems, 0)
        XCTAssertEqual(summary.warningCount, 0)
        XCTAssertEqual(
            try database.scalar("SELECT COUNT(*) FROM entries WHERE snapshot_id = ? AND parent_id IS NULL",
                                bindings: [.integer(record.id.rawValue)])?.int64Value,
            1
        )
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM entry_classifications")?.int64Value, 0)
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
    }

    /// A3 — the source is unchanged. Listing, sizes, modification times and
    /// test-only content hashes must all be identical before and after.
    ///
    /// The hashing here is deliberately in the test target: the production code
    /// contains no hashing at all, and adding any would break the read-only
    /// contract this test exists to defend.
    func testCaptureLeavesTheSourceByteForByteUnchanged() throws {
        let database = try openCatalog()
        let before = try fixtureFingerprint()

        let record = try SnapshotScanner(database: database).capture(root: fixture)
        XCTAssertEqual(record.status, .complete)

        let after = try fixtureFingerprint()
        XCTAssertEqual(before.count, after.count)
        XCTAssertEqual(before, after)
        for (path, digest) in before {
            XCTAssertEqual(after[path], digest, "content changed at \(path)")
        }
        XCTAssertFalse(
            after.keys.contains { $0.contains("catalog") || $0.contains(".fsd") || $0.contains("index") },
            "no FSD artefact may appear inside a scanned source"
        )
    }

    /// A4 — cancellation. A cancelled capture is never reported as complete, and
    /// the catalog stays usable afterwards.
    func testCancellationNeverProducesACompleteSnapshot() throws {
        let database = try openCatalog()
        for index in 0..<400 {
            try Data().write(to: fixture.appendingPathComponent("bulk-\(index).dat"))
        }
        let token = CaptureCancellationToken()

        _ = try SnapshotScanner(database: database, batchSize: 10).capture(root: fixture, token: token) { progress in
            if progress.processedEntries >= 64 { token.cancel() }
        }

        let summaries = try SnapshotHistoryRepository(database: database).listSnapshots()
        XCTAssertEqual(summaries.count, 1)
        XCTAssertEqual(summaries[0].status, .cancelled)
        XCTAssertFalse(summaries[0].isComplete)
        XCTAssertTrue(summaries[0].isPartialCapture)

        // The catalog still accepts work after a cancellation.
        let second = try SnapshotScanner(database: database).capture(root: fixture)
        XCTAssertEqual(second.status, .complete)
    }

    /// A5 — relaunch. Reopening the same catalog in a fresh connection, the way a
    /// relaunched process would, must show exactly the recorded state: no
    /// resurrected capture, no invented progress.
    func testRelaunchAgainstTheSameCatalogPreservesRecordedState() throws {
        let cancelledID: SnapshotID
        let completeID: SnapshotID
        do {
            let database = try openCatalog()
            let token = CaptureCancellationToken()
            for index in 0..<200 { try Data().write(to: fixture.appendingPathComponent("bulk-\(index).dat")) }
            _ = try SnapshotScanner(database: database, batchSize: 10).capture(root: fixture, token: token) { progress in
                if progress.processedEntries >= 32 { token.cancel() }
            }
            completeID = try SnapshotScanner(database: database).capture(root: fixture).id
            cancelledID = try XCTUnwrap(
                try SnapshotHistoryRepository(database: database).listSnapshots().first { $0.status == .cancelled }?.id
            )
        }

        // A new connection, as a relaunched process would open.
        let reopened = try CatalogDatabase(url: catalogURL, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        let report = try RecoveryService(database: reopened).recoverOrphanedScans()
        let history = try SnapshotHistoryRepository(database: reopened).listSnapshots()

        XCTAssertTrue(report.recoveredSnapshotIDs.isEmpty, "nothing was orphaned, so nothing may be reconciled")
        XCTAssertNil(report.message)
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history.first { $0.id == cancelledID }?.status, .cancelled)
        XCTAssertEqual(history.first { $0.id == completeID }?.status, .complete)
        XCTAssertEqual(try reopened.schemaVersion, 9)
    }

    /// A6 — force-quit recovery. An orphaned `scanning` snapshot, exactly what a
    /// killed process leaves behind, is reconciled to `interrupted` at startup
    /// with a recorded reason, and completed snapshots are untouched.
    func testOrphanedScanIsRecoveredOnTheNextStartup() throws {
        let completeID: SnapshotID
        let orphanID: SnapshotID
        do {
            let database = try openCatalog()
            completeID = try SnapshotScanner(database: database).capture(root: fixture).id
            // Left mid-flight, with no terminal transition — the state a force
            // quit produces.
            let writer = SnapshotWriter(database: database)
            let descriptor = try FilesystemDetector().detect(root: fixture)
            orphanID = try writer.beginCapture(descriptor: descriptor, scanRootName: "Orphan").snapshotID
            XCTAssertEqual(
                try database.scalar("SELECT status FROM snapshots WHERE id = ?",
                                    bindings: [.integer(orphanID.rawValue)])?.stringValue,
                "scanning"
            )
        }

        let reopened = try CatalogDatabase(url: catalogURL, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        let report = try RecoveryService(database: reopened).recoverOrphanedScans()

        XCTAssertEqual(report.recoveredSnapshotIDs, [orphanID])
        XCTAssertNotNil(report.message)
        let history = SnapshotHistoryRepository(database: reopened)
        XCTAssertEqual(try history.summary(id: orphanID)?.status, .interrupted)
        XCTAssertEqual(try history.summary(id: completeID)?.status, .complete)
        XCTAssertEqual(try history.issues(for: orphanID).map(\.message), [RecoveryService.recoveryMessage])
        XCTAssertEqual(try reopened.scalar("PRAGMA integrity_check")?.stringValue, "ok")

        // Idempotent: a second startup changes nothing.
        let second = try RecoveryService(database: reopened).recoverOrphanedScans()
        XCTAssertTrue(second.recoveredSnapshotIDs.isEmpty)
        XCTAssertEqual(try history.issues(for: orphanID).count, 1)
    }

    /// The isolation this session depends on: the catalog under test is created
    /// where the override says, and the Application Support default is untouched.
    func testTheSubstituteSessionRunsEntirelyInAnIsolatedCatalog() throws {
        let location = try CatalogLocationResolver.resolve(
            arguments: ["FSD", CatalogLocationResolver.launchArgumentName, catalogURL.deletingLastPathComponent().path],
            environment: [:],
            overrideAllowed: true
        )
        XCTAssertEqual(location.url, catalogURL)

        _ = try SnapshotScanner(database: try openCatalog()).capture(root: fixture)

        XCTAssertTrue(FileManager.default.fileExists(atPath: catalogURL.path))
        XCTAssertTrue(catalogURL.path.hasPrefix(FileManager.default.temporaryDirectory.path))
        let defaultURL = try CatalogLocationResolver.defaultURL()
        XCTAssertNotEqual(catalogURL.path, defaultURL.path)
    }

    // MARK: - Fixture and evidence helpers

    private func openCatalog() throws -> CatalogDatabase {
        try CatalogDatabase(url: catalogURL, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
    }

    /// The same shape the audit prepared by hand: nesting, an empty folder, a
    /// hidden file, a package, a Unicode name, a valid symlink and a broken one.
    private func makeControlledFixture() throws {
        let manager = FileManager.default
        try manager.createDirectory(at: fixture.appendingPathComponent("Nested/Deeper"), withIntermediateDirectories: true)
        try manager.createDirectory(at: fixture.appendingPathComponent("Empty"), withIntermediateDirectories: true)
        try manager.createDirectory(at: fixture.appendingPathComponent("Bundle.rtfd"), withIntermediateDirectories: true)
        try Data("root file".utf8).write(to: fixture.appendingPathComponent("root.txt"))
        try Data("nested".utf8).write(to: fixture.appendingPathComponent("Nested/one.txt"))
        try Data("deeper".utf8).write(to: fixture.appendingPathComponent("Nested/Deeper/two.txt"))
        try Data("hidden".utf8).write(to: fixture.appendingPathComponent(".hidden.txt"))
        try Data("unicode".utf8).write(to: fixture.appendingPathComponent("Café — ünïcode.txt"))
        try Data("bundled".utf8).write(to: fixture.appendingPathComponent("Bundle.rtfd/TXT.rtf"))
        try manager.createSymbolicLink(
            at: fixture.appendingPathComponent("valid-link"),
            withDestinationURL: fixture.appendingPathComponent("root.txt")
        )
        try manager.createSymbolicLink(
            at: fixture.appendingPathComponent("broken-link"),
            withDestinationURL: fixture.appendingPathComponent("missing.txt")
        )
    }

    private func expectedCounts() throws -> (files: Int64, folders: Int64) {
        var files: Int64 = 0
        var folders: Int64 = 1 // the root itself
        let enumerator = FileManager.default.enumerator(
            at: fixture, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey, .isPackageKey], options: []
        )
        while let url = enumerator?.nextObject() as? URL {
            let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .isPackageKey])
            if values.isSymbolicLink == true { continue }
            if values.isPackage == true {
                folders += 1
                enumerator?.skipDescendants()
            } else if values.isDirectory == true {
                folders += 1
            } else {
                files += 1
            }
        }
        return (files, folders)
    }

    /// Path, size, modification date and a test-only SHA-256 for every regular
    /// file in the fixture.
    private func fixtureFingerprint() throws -> [String: String] {
        var result: [String: String] = [:]
        let keys: [URLResourceKey] = [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey, .contentModificationDateKey]
        guard let enumerator = FileManager.default.enumerator(at: fixture, includingPropertiesForKeys: keys, options: []) else {
            return result
        }
        for case let url as URL in enumerator {
            let relative = url.path.replacingOccurrences(of: fixture.path + "/", with: "")
            let values = try url.resourceValues(forKeys: Set(keys))
            if values.isSymbolicLink == true {
                let target = try FileManager.default.destinationOfSymbolicLink(atPath: url.path)
                result[relative] = "symlink->\(target)"
                continue
            }
            guard values.isRegularFile == true else {
                result[relative] = "directory"
                continue
            }
            let digest = SHA256.hash(data: try Data(contentsOf: url)).map { String(format: "%02x", $0) }.joined()
            let modified = values.contentModificationDate?.timeIntervalSince1970 ?? -1
            result[relative] = "\(values.fileSize ?? -1)|\(modified)|\(digest)"
        }
        return result
    }
}
