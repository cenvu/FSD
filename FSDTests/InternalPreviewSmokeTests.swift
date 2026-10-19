import AppKit
import CryptoKit
import ScreenCaptureKit
import SwiftUI
import XCTest
@testable import FSD

/// Task065 integrated synthetic product smoke. It drives the real production
/// application stack (scanner, catalog, comparison engine, saved evidence) over
/// generated local fixtures and isolated temporary catalogs. It never reads the
/// Owner's production or preview catalog, any real volume, or any source media.
@MainActor
final class InternalPreviewSmokeTests: XCTestCase {
    private var root: URL!
    private var database: CatalogDatabase!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-task065-smoke-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        database = try CatalogDatabase(
            url: root.appendingPathComponent("isolated-preview-catalog.sqlite3"),
            schemaURL: CatalogSchemaFixture.canonicalSchemaURL
        )
    }

    override func tearDownWithError() throws {
        database?.close()
        database = nil
        try? FileManager.default.removeItem(at: root)
        root = nil
    }

    private func settle(_ condition: () -> Bool, timeout: TimeInterval = 30, file: StaticString = #filePath, line: UInt = #line) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.01)) }
        XCTAssertTrue(condition(), "Async operation did not settle", file: file, line: line)
    }

    private func healthy() throws {
        XCTAssertEqual(try database.scalar("PRAGMA foreign_keys")?.int64Value, 1)
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
    }

    /// Writes a small deterministic synthetic source tree.
    @discardableResult
    private func makeSource(_ name: String, files: [(String, String)]) throws -> URL {
        let source = root.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        for (relative, contents) in files {
            let url = source.appendingPathComponent(relative)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(contents.utf8).write(to: url)
        }
        return source
    }

    /// A stable name + size + content-hash fingerprint of a directory tree.
    private func fingerprint(of directory: URL) throws -> String {
        var lines: [String] = []
        let keys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey]
        guard let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: keys) else { return "" }
        for case let url as URL in enumerator {
            let values = try url.resourceValues(forKeys: Set(keys))
            let relative = url.path.replacingOccurrences(of: directory.path + "/", with: "")
            if values.isDirectory == true {
                lines.append("D|\(relative)")
            } else {
                let bytes = try Data(contentsOf: url)
                let digest = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
                lines.append("F|\(relative)|\(values.fileSize ?? 0)|\(digest)")
            }
        }
        return lines.sorted().joined(separator: "\n")
    }

    private func capture(_ source: URL) throws -> SnapshotRecord {
        try SnapshotScanner(database: database).capture(root: source)
    }

    // MARK: - Journey A: capture, explore, organize, source preservation

    func testCaptureExploreSnapshotsCollectionsDriveSetsAndSourcePreservation() throws {
        let source = try makeSource("source-a", files: [
            ("a.txt", "alpha"),
            ("sub/b.bin", String(repeating: "b", count: 4096)),
            ("sub/c.bin", String(repeating: "c", count: 128))
        ])
        let before = try fingerprint(of: source)

        let record = try capture(source)
        XCTAssertEqual(record.status, .complete, "capture must terminalize complete")

        let after = try fingerprint(of: source)
        XCTAssertEqual(before, after, "capture must not write to, create or remove anything in the source tree")

        // History.
        let history = try SnapshotHistoryRepository(database: database).listSnapshots()
        XCTAssertTrue(history.contains { $0.id == record.id })

        // Offline explore over stored metadata: remove the synthetic source, then
        // browse. No filesystem access to the source is needed or performed.
        try FileManager.default.removeItem(at: source)
        let tree = SnapshotTreeDataSource(database: database, snapshotID: record.id)
        let rootNode = try XCTUnwrap(tree.root())
        let names = try tree.children(ofParent: rootNode.id).map(\.name)
        XCTAssertTrue(names.contains("a.txt"), "stored metadata must remain browsable offline: \(names)")

        // Snapshot Collection organizer.
        let collections = SnapshotCollectionRepository(database: database)
        let collection = try collections.createCollection(name: "Preview shoot")
        try collections.assign(snapshotID: record.id, to: collection.id)
        let membership = try collections.listSnapshots(filter: .collection(collection.id))
        XCTAssertEqual(membership.snapshots.map(\.id), [record.id])

        // Manual unverified Drive Set (explicit local record, no hardware claim).
        let drives = PhysicalDriveRepository(database: database)
        let drive = try drives.createDrive(label: "Preview local record", provenance: "task065-smoke")
        let sets = DriveSetRepository(database: database)
        let set = try sets.create(name: "Preview set")
        let updated = try sets.setMembership(
            setID: set.id,
            expectedRevision: set.revision,
            driveID: drive.id,
            expectedDriveRevision: drive.revision,
            included: true
        )
        let members = try sets.members(setID: updated.id)
        XCTAssertEqual(members.records.map(\.id), [drive.id])

        // Launch-style recovery must not fabricate classification or snapshots.
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM entry_classifications")?.int64Value, 0)
        try healthy()
    }

    // MARK: - Journey B: comparison, save, offline reopen, delete

    func testComparisonCategoryAncestorSaveOfflineReopenAndSafeDelete() throws {
        let left = try makeSource("left", files: [("keep.txt", "same"), ("only-left.txt", "left")])
        let right = try makeSource("right", files: [("keep.txt", "same"), ("only-right.txt", "right")])
        let leftRecord = try capture(left)
        let rightRecord = try capture(right)
        try FileManager.default.removeItem(at: left)
        try FileManager.default.removeItem(at: right)

        let comparison = try ComparisonEngine(database: database).compare(
            leftSnapshotID: leftRecord.id,
            rightSnapshotID: rightRecord.id,
            profileID: 1
        )
        let results = ComparisonResultRepository(database: database)
        let counts = try results.resultCounts(comparisonID: comparison.id)
        XCTAssertGreaterThan(counts[.added] ?? 0, 0)
        XCTAssertGreaterThan(counts[.removed] ?? 0, 0)

        // Category-first selection through the real comparison browser model.
        let browser = ComparisonBrowserModel(database: database, record: comparison)
        browser.open()
        browser.selectCategory(.differences)
        settle { browser.currentPage != nil && !browser.isLoading }
        let page = try XCTUnwrap(browser.currentPage)
        XCTAssertFalse(page.rows.isEmpty)
        let target = try XCTUnwrap(page.rows.first)
        browser.revealAncestor(target)
        settle { browser.selectedRow != nil || browser.ancestorError != nil }
        if let context = browser.ancestorContext {
            // The current engine records NULL parents, so the honest stored
            // boundary is "not recorded"; no ancestor is invented.
            XCTAssertEqual(context.boundary, .notRecorded)
            XCTAssertTrue(context.ancestors.isEmpty)
        } else {
            // Otherwise the model must report an explicit ancestor error, never a
            // fabricated node.
            XCTAssertNotNil(browser.ancestorError)
        }
        browser.close()

        // Explicit Save Comparison through the production workspace model.
        let workspace = ComparisonWorkspaceModel(database: database)
        workspace.refresh()
        workspace.openComparison(comparison)
        settle { workspace.savedComparisons.eligibility != .checking }
        let saved = workspace.savedComparisons
        XCTAssertEqual(saved.eligibility, .available)
        saved.save()
        settle { !saved.isSaving }
        guard case .saved(let savedID) = saved.eligibility else {
            return XCTFail("Save Comparison did not report a saved artifact: \(saved.saveError ?? "no error")")
        }
        XCTAssertEqual(try SavedComparisonRepository(database: database).list(), [savedID])

        // Saved Comparisons list.
        saved.reloadLibrary()
        settle { !saved.libraryLoading }
        XCTAssertTrue(saved.summaries.contains { $0.id == savedID })

        // Close the original workspace, then relaunch the catalog and reopen the
        // saved comparison entirely offline.
        workspace.closeComparison()
        settle { !workspace.isClosing }
        saved.closeReader()

        let catalogURL = database.url
        database.close()
        database = try CatalogDatabase(url: catalogURL, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)

        let offline = SavedComparisonsModel(database: database)
        offline.open(savedID)
        settle { !offline.readerLoading }
        XCTAssertNil(offline.readerError)
        let rows = offline.rows
        XCTAssertFalse(rows.isEmpty, "offline reader must page stored evidence without source media")

        // Safe deletion of the saved artifact only.
        offline.deletionCandidate = savedID
        offline.confirmDeletion()
        settle { !offline.isDeleting }
        XCTAssertTrue(try SavedComparisonRepository(database: database).list().isEmpty)
        // The original snapshots and comparison remain intact.
        let history = try SnapshotHistoryRepository(database: database).listSnapshots()
        XCTAssertTrue(history.contains { $0.id == leftRecord.id })
        XCTAssertTrue(history.contains { $0.id == rightRecord.id })
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM entry_classifications")?.int64Value, 0)
        try healthy()
    }

    // MARK: - FSD-owned window screenshots at representative widths

    func testShellRendersFSDOwnWindowsAtRepresentativeWidths() throws {
        _ = try capture(try makeSource("shots", files: [("a.txt", "alpha"), ("dir/b.bin", "beta")]))
        let model = ApplicationModel(catalogForTesting: database)
        let host = NSHostingView(rootView: AnyView(FSDAppShellView(model: model).preferredColorScheme(.dark)))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1120, height: 760), styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        window.title = "FSD Task065 Synthetic"
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentView = host
        window.makeKeyAndOrderFront(nil)
        defer { window.orderOut(nil) }

        let output = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent(".ai-scratch/task065/screenshots")
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

        for width in [1120, 1330, 1440] {
            window.setContentSize(NSSize(width: width, height: 760))
            host.layoutSubtreeIfNeeded()
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
            var captured = false
            var captureError: Error?
            Task { @MainActor in
                do {
                    // currentProcess returns only this test host's shareable
                    // windows; no other application is enumerated.
                    let content = try await SCShareableContent.currentProcess
                    let own = try XCTUnwrap(content.windows.first { $0.windowID == CGWindowID(window.windowNumber) })
                    let config = SCStreamConfiguration()
                    config.width = width * 2
                    config.height = Int(window.frame.height) * 2
                    config.showsCursor = false
                    let image = try await SCScreenshotManager.captureImage(
                        contentFilter: SCContentFilter(desktopIndependentWindow: own),
                        configuration: config
                    )
                    let bitmap = NSBitmapImageRep(cgImage: image)
                    try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
                        .write(to: output.appendingPathComponent("shell-\(width).png"))
                } catch { captureError = error }
                captured = true
            }
            settle({ captured }, timeout: 15)
            if let captureError { throw captureError }
            XCTAssertEqual(Int(try XCTUnwrap(window.contentView).bounds.width), width)
        }
        try healthy()
    }
}
