import XCTest
@testable import FSD

/// Agent-observed probe seeding. With `FSD_PROBE_CATALOG` set to an absolute
/// path, this seeds an isolated catalog with:
///
/// * a completed **snapshot-to-snapshot** comparison containing every
///   canonical outcome (matched / added / removed / changed / ignored /
///   uncertain) — offline by construction, no source folders involved;
/// * a completed **live-to-snapshot** comparison against a generated live
///   folder, whose referenced transient snapshot survives launch recovery.
///
/// Inert (skipped) in ordinary runs, exactly like the filesystem-matrix probe
/// tests. This is automated seeding for an agent-run launch probe — not manual
/// acceptance.
final class FSDProbeSeedTests: XCTestCase {
    func testSeedIsolatedProbeCatalog() throws {
        // The test host's environment is scrubbed by the test manager, so the
        // path arrives through a marker file the agent-run shell writes at
        // /tmp/fsd-probe-catalog-path.txt (one line). No marker → inert.
        let markerURL = URL(fileURLWithPath: "/tmp/fsd-probe-catalog-path.txt")
        let marker = try? String(contentsOf: markerURL, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        let rawPath = ProcessInfo.processInfo.environment["FSD_PROBE_CATALOG"]
            ?? (marker != nil && !marker!.isEmpty ? marker! : nil)
        guard let rawPath, !rawPath.isEmpty else {
            throw XCTSkip("FSD_PROBE_CATALOG is not set and no marker file exists; the probe seeding is inert in ordinary runs")
        }
        let catalogURL = URL(fileURLWithPath: rawPath)
        let parent = catalogURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: catalogURL.path) {
            try FileManager.default.removeItem(at: catalogURL)
        }
        let database = try CatalogDatabase(url: catalogURL, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        defer { database.close() }
        let service = ComparisonService(database: database)

        // 1. Snapshot-to-snapshot with every canonical outcome.
        let leftID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 21, session: 1, sensitivity: .sensitive)
        let rightID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 21, session: 2, sensitivity: .sensitive)
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: leftID, entries: [
            SyntheticSnapshot.root(id: 7100, name: "Root"),
            SyntheticSnapshot.SeedEntry(id: 7101, parentID: 7100, relativePath: "same.txt", name: "same.txt", logicalSizeBytes: 1024, allocatedSizeBytes: 4096),
            SyntheticSnapshot.SeedEntry(id: 7102, parentID: 7100, relativePath: "grown.bin", name: "grown.bin", logicalSizeBytes: 10, allocatedSizeBytes: 10),
            SyntheticSnapshot.SeedEntry(id: 7103, parentID: 7100, relativePath: "gone.txt", name: "gone.txt", logicalSizeBytes: 1, allocatedSizeBytes: 1),
            SyntheticSnapshot.SeedEntry(id: 7104, parentID: 7100, relativePath: ".DS_Store", name: ".DS_Store", logicalSizeBytes: 1, allocatedSizeBytes: 1),
            SyntheticSnapshot.SeedEntry(id: 7105, parentID: 7100, relativePath: "locked.bin", name: "locked.bin", logicalSizeBytes: 1, allocatedSizeBytes: 1)
        ])
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: rightID, entries: [
            SyntheticSnapshot.root(id: 7200, name: "Root"),
            SyntheticSnapshot.SeedEntry(id: 7201, parentID: 7200, relativePath: "same.txt", name: "same.txt", logicalSizeBytes: 1024, allocatedSizeBytes: 4096),
            SyntheticSnapshot.SeedEntry(id: 7202, parentID: 7200, relativePath: "grown.bin", name: "grown.bin", logicalSizeBytes: 99, allocatedSizeBytes: 99),
            SyntheticSnapshot.SeedEntry(id: 7203, parentID: 7200, relativePath: "fresh.txt", name: "fresh.txt", logicalSizeBytes: 2, allocatedSizeBytes: 2),
            SyntheticSnapshot.SeedEntry(id: 7204, parentID: 7200, relativePath: ".DS_Store", name: ".DS_Store", logicalSizeBytes: 1, allocatedSizeBytes: 1),
            SyntheticSnapshot.SeedEntry(id: 7205, parentID: 7200, relativePath: "locked.bin", name: "locked.bin", logicalSizeBytes: 1, allocatedSizeBytes: 1, isInaccessible: true)
        ])
        try SyntheticSnapshot.complete(database: database, snapshotID: leftID)
        try SyntheticSnapshot.complete(database: database, snapshotID: rightID)
        let stored = try service.snapshotToSnapshot(leftSnapshotID: leftID, rightSnapshotID: rightID)
        XCTAssertEqual(stored.status, .complete)
        XCTAssertEqual(stored.matchedCount, 2)
        XCTAssertEqual(stored.addedCount, 1)
        XCTAssertEqual(stored.removedCount, 1)
        XCTAssertEqual(stored.changedCount, 1)
        XCTAssertEqual(stored.uncertainCount, 1)

        // 2. Live-to-snapshot against a generated live folder; its transient
        // snapshot must remain referenced after this seed completes.
        let liveRoot = parent.appendingPathComponent("probe-live", isDirectory: true)
        try FileManager.default.createDirectory(at: liveRoot, withIntermediateDirectories: true)
        try Data(repeating: 0x41, count: 1024).write(to: liveRoot.appendingPathComponent("same.txt"))
        try Data("new since snapshot".utf8).write(to: liveRoot.appendingPathComponent("new.txt"))
        let live = try service.liveToSnapshot(liveRoot: liveRoot, snapshotID: leftID)
        XCTAssertEqual(live.status, .complete)
        XCTAssertEqual(live.addedCount, 1, "new.txt")
        XCTAssertEqual(live.right.kind, .transient)

        // 3. No classification rows ever.
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM entry_classifications")?.int64Value ?? -1, 0)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM comparisons")?.int64Value ?? -1, 2)

        // 4. Consume the marker so the next run starts clean.
        try? FileManager.default.removeItem(at: markerURL)
    }
}
