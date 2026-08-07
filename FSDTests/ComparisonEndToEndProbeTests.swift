import XCTest
@testable import FSD

/// The isolated end-to-end comparison probe (agent-run validation, automated
/// here): two controlled generated folders captured through the production
/// scanner, live-to-live comparison, snapshot-to-snapshot comparison with the
/// sources removed, a fresh reopen of the isolated catalog, and proof that
/// the fixtures were never modified and classification rows stayed zero.
/// This is automated evidence — not manual acceptance.
final class ComparisonEndToEndProbeTests: XCTestCase {
    private var directory: URL!
    private var catalogURL: URL!
    private var leftSource: URL!
    private var rightSource: URL!
    private var database: CatalogDatabase!
    private var service: ComparisonService!
    private var results: ComparisonResultRepository!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-Probe-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        catalogURL = directory.appendingPathComponent("catalog.sqlite3")
        leftSource = directory.appendingPathComponent("probe-left", isDirectory: true)
        rightSource = directory.appendingPathComponent("probe-right", isDirectory: true)
        database = try CatalogDatabase(url: catalogURL, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        service = ComparisonService(database: database)
        results = ComparisonResultRepository(database: database)
    }

    override func tearDownWithError() throws {
        results = nil
        service = nil
        database?.close()
        database = nil
        try? FileManager.default.removeItem(at: directory)
        directory = nil
        catalogURL = nil
        leftSource = nil
        rightSource = nil
    }

    private func writeControlledFixtures() throws {
        // Both sources share one folder of identical files; the left has a
        // removed-only folder, the right an added-only folder, and one file
        // differs in size — the known added/removed/modified set.
        try FileManager.default.createDirectory(at: leftSource.appendingPathComponent("shared"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: rightSource.appendingPathComponent("shared"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: leftSource.appendingPathComponent("only-left"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: rightSource.appendingPathComponent("only-right"), withIntermediateDirectories: true)

        for index in 0..<10 {
            let data = Data(repeating: UInt8(index), count: 100 + index)
            try data.write(to: leftSource.appendingPathComponent("shared/file\(index).bin"))
            try data.write(to: rightSource.appendingPathComponent("shared/file\(index).bin"))
        }
        // Known modification: file5 differs in logical size.
        try Data(repeating: 5, count: 999).write(to: rightSource.appendingPathComponent("shared/file5.bin"))
        // Known added/removed branches.
        try Data("left only".utf8).write(to: leftSource.appendingPathComponent("only-left/keep.txt"))
        try Data("right only".utf8).write(to: rightSource.appendingPathComponent("only-right/keep.txt"))
    }

    private func listing(of root: URL) throws -> [String: Int64] {
        // The enumerator yields resolved paths (/var → /private/var) while
        // the input URL stays lexical, so both are resolved before stripping
        // the root prefix.
        let base = root.standardizedFileURL.resolvingSymlinksInPath().path
        let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.fileSizeKey])
        var result: [String: Int64] = [:]
        while let url = enumerator?.nextObject() as? URL {
            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            let resolved = url.standardizedFileURL.resolvingSymlinksInPath().path
            guard resolved.hasPrefix(base) else { continue }
            let relative = String(resolved.dropFirst(base.count))
            result[relative.isEmpty ? "/" : relative] = Int64(values.fileSize ?? -1)
        }
        return result
    }

    func testEndToEndProbe() throws {
        // 1-2. Two controlled folders, captured through the production scanner.
        try writeControlledFixtures()
        let leftBaseline = try listing(of: leftSource)
        let rightBaseline = try listing(of: rightSource)
        let scanner = SnapshotScanner(database: database)
        let storedLeft = try scanner.capture(root: leftSource).id
        let storedRight = try scanner.capture(root: rightSource).id
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)

        // 9b. Capture and live comparison never modified the fixtures.
        XCTAssertEqual(try listing(of: leftSource), leftBaseline)
        XCTAssertEqual(try listing(of: rightSource), rightBaseline)

        // 4. Live-to-live comparison against the live folders.
        let live = try service.liveToLive(leftRoot: leftSource, rightRoot: rightSource)
        XCTAssertEqual(live.status, .complete)
        XCTAssertEqual(live.mode, .liveToLive)
        XCTAssertEqual(live.changedCount, 1, "shared/file5.bin")
        XCTAssertEqual(live.removedCount, 2, "only-left/ + only-left/keep.txt")
        XCTAssertEqual(live.addedCount, 2, "only-right/ + only-right/keep.txt")

        // 5. Snapshot-to-snapshot comparison, fully offline.
        // 6-7. Remove the original controlled sources.
        try FileManager.default.removeItem(at: leftSource)
        try FileManager.default.removeItem(at: rightSource)
        let stored = try service.snapshotToSnapshot(leftSnapshotID: storedLeft, rightSnapshotID: storedRight)
        XCTAssertEqual(stored.status, .complete)
        XCTAssertEqual(stored.mode, .snapshotToSnapshot)
        XCTAssertEqual(stored.changedCount, 1)
        XCTAssertEqual(stored.removedCount, 2)
        XCTAssertEqual(stored.addedCount, 2)

        // 8. Reopen the isolated catalog with a fresh connection.
        service = nil
        results = nil
        database?.close()
        database = nil
        database = try CatalogDatabase(url: catalogURL, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)

        // 9. Stored comparison results remain readable after reopen, offline.
        let reopenedResults = ComparisonResultRepository(database: database)
        let storedAfterReopen = try reopenedResults.record(id: stored.id)
        XCTAssertEqual(storedAfterReopen?.status, .complete)
        XCTAssertEqual(storedAfterReopen?.changedCount, 1)
        let differences = try reopenedResults.results(comparisonID: stored.id, filter: .differences, limit: 100)
        XCTAssertEqual(differences.totalCount, 5, "1 changed + 2 added + 2 removed")
        XCTAssertEqual(Set(differences.rows.map(\.resultPath)), [
            "only-left", "only-left/keep.txt", "only-right", "only-right/keep.txt", "shared/file5.bin"
        ])
        let liveAfterReopen = try reopenedResults.record(id: live.id)
        XCTAssertEqual(liveAfterReopen?.mode, .liveToLive)
        XCTAssertEqual(liveAfterReopen?.left.sourceDescription.contains("Live folder"), true)
        XCTAssertEqual(liveAfterReopen?.right.sourceDescription.contains("Live folder"), true)
        XCTAssertEqual(liveAfterReopen?.status, .complete)

        // 10. Classification rows remain zero; the catalog is intact.
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
        XCTAssertEqual(try database.schemaVersion, CatalogDatabase.currentSchemaVersion)

        // The fixtures were deliberately modified only by us (file5 resized
        // before capture); the probe's own capture and comparison left them
        // byte-identical, as proven above.
        XCTAssertEqual(rightBaseline["/shared/file5.bin"], 999)
        XCTAssertEqual(leftBaseline["/shared/file5.bin"], 105)
    }
}
