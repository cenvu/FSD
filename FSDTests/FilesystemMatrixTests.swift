import XCTest
@testable import FSD

/// Drives one real capture of an externally-prepared mounted filesystem, so the
/// per-filesystem matrix in `docs/FILESYSTEM_SUPPORT_MATRIX.md` is filled in by
/// running the production capture path rather than by reasoning about it.
///
/// Inert unless a caller supplies `FSD_MATRIX_SOURCE`. The images themselves are
/// created, mounted, checked and destroyed by the driver script — none of that
/// belongs inside the test process, and no physical or removable device is ever
/// involved.
///
/// Environment:
///
/// * `FSD_MATRIX_SOURCE`  — mount point to capture (required, or the test skips)
/// * `FSD_MATRIX_CATALOG` — isolated catalog path (required)
/// * `FSD_MATRIX_REPORT`  — file to write the machine-readable result to
///
/// A second invocation with `FSD_MATRIX_OFFLINE_CATALOG` instead performs step 6
/// of the support definition — reopening the snapshot with the source detached.
final class FilesystemMatrixTests: XCTestCase {
    func testCaptureExternallyPreparedMountedFilesystem() throws {
        let environment = ProcessInfo.processInfo.environment
        guard let sourcePath = Self.value("FSD_MATRIX_SOURCE", in: environment), !sourcePath.isEmpty else {
            throw XCTSkip("FSD_MATRIX_SOURCE is not set; the filesystem matrix probe is inert in ordinary runs")
        }
        let catalogPath = try XCTUnwrap(Self.value("FSD_MATRIX_CATALOG", in: environment), "FSD_MATRIX_CATALOG is required")
        let source = URL(fileURLWithPath: sourcePath, isDirectory: true)
        let database = try CatalogDatabase(
            url: URL(fileURLWithPath: catalogPath),
            schemaURL: CatalogSchemaFixture.canonicalSchemaURL
        )

        let descriptor = try FilesystemDetector().detect(root: source)
        let started = Date()
        let record = try SnapshotScanner(database: database).capture(root: source)
        let elapsed = Date().timeIntervalSince(started)

        let history = SnapshotHistoryRepository(database: database)
        let summary = try XCTUnwrap(try history.summary(id: record.id))
        let issues = try history.issues(for: record.id)
        let entryCount = try history.entryCount(for: record.id)

        XCTAssertTrue(summary.isComplete, "capture status was \(summary.status.rawValue)")
        XCTAssertEqual(
            try database.scalar(
                "SELECT COUNT(*) FROM entries WHERE snapshot_id = ? AND parent_id IS NULL",
                bindings: [.integer(record.id.rawValue)]
            )?.int64Value,
            1
        )
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM entry_classifications")?.int64Value, 0)
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)

        let report = """
        detected_filesystem_type=\(descriptor.filesystemType)
        detected_read_only=\(descriptor.isReadOnly)
        detected_case_sensitivity=\(descriptor.sourceCaseSensitivity.rawValue)
        detected_volume_name=\(descriptor.volumeName)
        detected_mount_path=\(descriptor.mountPath)
        detected_capacity_bytes=\(descriptor.capacityBytes.map(String.init) ?? "nil")
        capture_status=\(summary.status.rawValue)
        capture_entries=\(entryCount)
        capture_files=\(summary.totalFiles)
        capture_folders=\(summary.totalFolders)
        capture_logical_bytes=\(summary.totalLogicalBytes)
        capture_inaccessible=\(summary.inaccessibleItems)
        capture_issues=\(issues.count)
        capture_issue_messages=\(issues.map(\.message).joined(separator: " | "))
        capture_seconds=\(String(format: "%.3f", elapsed))
        capture_provider=\(summary.filesystemProvider)/\(summary.providerVersion ?? "nil")
        capture_access_mode=\(summary.sourceAccessMode)
        capture_normalization=\(summary.normalizationVersion.rawValue)
        capture_volume_name_at_capture=\(summary.capture.volumeDisplayName ?? "nil")
        capture_filesystem_variant=\(summary.capture.filesystemVariant ?? "nil")
        """
        print("[FSD matrix probe]\n\(report)")
        if let reportPath = Self.value("FSD_MATRIX_REPORT", in: environment) {
            try report.write(to: URL(fileURLWithPath: reportPath), atomically: true, encoding: .utf8)
        }
    }

    /// Step 6 of the support definition: reopen the snapshot offline. Run after
    /// the image has been detached, so the source genuinely no longer exists.
    func testReopenCapturedSnapshotWithTheSourceDetached() throws {
        let environment = ProcessInfo.processInfo.environment
        guard let catalogPath = Self.value("FSD_MATRIX_OFFLINE_CATALOG", in: environment), !catalogPath.isEmpty else {
            throw XCTSkip("FSD_MATRIX_OFFLINE_CATALOG is not set; the offline reopen probe is inert in ordinary runs")
        }
        let database = try CatalogDatabase(
            url: URL(fileURLWithPath: catalogPath),
            schemaURL: CatalogSchemaFixture.canonicalSchemaURL
        )
        let history = SnapshotHistoryRepository(database: database)
        let summary = try XCTUnwrap(try history.listSnapshots().first)

        // The mount point must be gone; if it is not, this is not an offline test.
        let mountPath = try XCTUnwrap(summary.capture.mountPath)
        XCTAssertFalse(FileManager.default.fileExists(atPath: mountPath), "source is still mounted at \(mountPath)")
        XCTAssertEqual(SourceAvailabilityProbe().availability(for: summary), .unavailable)

        let tree = SnapshotTreeDataSource(database: database, snapshotID: summary.id)
        let root = try XCTUnwrap(try tree.root())
        let children = try tree.children(ofParent: root.id)
        XCTAssertFalse(children.isEmpty)
        let directory = try XCTUnwrap(children.first { $0.hasChildren })
        let grandchildren = try tree.children(ofParent: directory.id)
        XCTAssertFalse(grandchildren.isEmpty)
        let details = try XCTUnwrap(try tree.details(for: grandchildren[0].id))

        let hits = try MetadataSearchService(database: database)
            .search(MetadataSearchQuery(text: "a001", field: .name), in: summary.id)
        var exported = ""
        let exportSummary = try JSONSnapshotExporter(database: database)
            .write(snapshotID: summary.id) { exported += $0 }
        XCTAssertTrue(exported.contains("Content Not Verified"))

        let report = """
        offline_source_present=false
        offline_availability=\(SourceAvailabilityProbe().availability(for: summary).rawValue)
        offline_root=\(root.name)
        offline_root_children=\(children.count)
        offline_expanded=\(directory.relativePath) -> \(grandchildren.count) children
        offline_detail_sample=\(details.relativePath) size=\(details.logicalSizeBytes.map(String.init) ?? "nil")
        offline_search_hits=\(hits.hits.count)
        offline_export_entries=\(exportSummary.entryCount)
        offline_capture_volume_name=\(summary.capture.volumeDisplayName ?? "nil")
        offline_capture_filesystem=\(summary.capture.filesystemVariant ?? "nil")
        """
        print("[FSD matrix offline probe]\n\(report)")
        if let reportPath = Self.value("FSD_MATRIX_OFFLINE_REPORT", in: environment) {
            try report.write(to: URL(fileURLWithPath: reportPath), atomically: true, encoding: .utf8)
        }
    }

    /// Xcode's app-hosted test runner on this host only forwards custom
    /// environment keys with the `TEST_RUNNER_` prefix. Keep the documented
    /// names as the primary interface and accept that runner-specific prefix
    /// solely so the existing matrix test remains executable in an isolated
    /// xctestrun configuration.
    private static func value(_ key: String, in environment: [String: String]) -> String? {
        environment[key] ?? environment["TEST_RUNNER_" + key]
    }
}
