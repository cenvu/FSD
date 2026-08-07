import XCTest
@testable import FSD

final class SnapshotLifecycleTests: XCTestCase {
    private var directory: URL!
    private var database: CatalogDatabase!
    private var repository: SnapshotRepository!
    private var nextSession: Int64 = 1

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSDTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let schemaURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/database/schema.sql")
        database = try CatalogDatabase(url: directory.appendingPathComponent("catalog.sqlite3"), schemaURL: schemaURL)
        repository = SnapshotRepository(database: database)
        try repository.createVolume(id: 1, displayName: "Test Volume")
    }

    override func tearDownWithError() throws {
        repository = nil
        database?.close()
        database = nil
        try FileManager.default.removeItem(at: directory)
        directory = nil
    }

    func testSnapshotStartsScanning() throws {
        let snapshot = try makeSnapshot()
        XCTAssertEqual(try repository.snapshot(id: snapshot)?.status, .scanning)
    }

    func testValidSnapshotReachesComplete() throws {
        let snapshot = try makeSnapshot()
        _ = try repository.addRoot(to: snapshot, name: "Root")

        try repository.complete(snapshot)

        XCTAssertEqual(try repository.snapshot(id: snapshot)?.status, .complete)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM entry_classifications")?.int64Value, 0)
    }

    func testInterruptedSnapshotIsNotComplete() throws {
        let snapshot = try makeSnapshot()
        try repository.interrupt(snapshot)

        let record = try XCTUnwrap(try repository.snapshot(id: snapshot))
        XCTAssertEqual(record.status, .interrupted)
        XCTAssertFalse(record.isComplete)
    }

    func testFailedSnapshotIsNotComplete() throws {
        let snapshot = try makeSnapshot()
        try repository.fail(snapshot)

        let record = try XCTUnwrap(try repository.snapshot(id: snapshot))
        XCTAssertEqual(record.status, .failed)
        XCTAssertFalse(record.isComplete)
    }

    func testInvalidStatusTransitionIsRejected() throws {
        let snapshot = try makeSnapshot()
        _ = try repository.addRoot(to: snapshot, name: "Root")
        try repository.complete(snapshot)

        XCTAssertThrowsError(try repository.interrupt(snapshot)) { error in
            guard case let SnapshotRepositoryError.invalidTransition(from, to) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(from, .complete)
            XCTAssertEqual(to, .interrupted)
        }
    }

    func testCompletionWithoutExactlyOneRootIsRejected() throws {
        let snapshot = try makeSnapshot()
        XCTAssertThrowsError(try repository.complete(snapshot))
        XCTAssertEqual(try repository.snapshot(id: snapshot)?.status, .scanning)
    }

    func testCompletionWithInvalidNormalizationVersionsIsRejected() throws {
        let invalidValues = ["", "   ", "UNKNOWN", "PLACEHOLDER", "NOT_SET", "PENDING", "fsd-normalizer-v2_future"]

        for value in invalidValues {
            let snapshot = try makeSnapshot(normalizationVersion: NormalizationVersion(rawValue: value))
            _ = try repository.addRoot(to: snapshot, name: "Root")

            XCTAssertThrowsError(try repository.complete(snapshot), "value: \(value.debugDescription)")
            XCTAssertEqual(try repository.snapshot(id: snapshot)?.status, .scanning)
        }
    }

    func testExactSupportedNormalizationVersionCompletes() throws {
        let snapshot = try makeSnapshot(normalizationVersion: .current)
        _ = try repository.addRoot(to: snapshot, name: "Root")

        try repository.complete(snapshot)

        XCTAssertEqual(try repository.snapshot(id: snapshot)?.normalizationVersion, .current)
        XCTAssertEqual(try repository.snapshot(id: snapshot)?.status, .complete)
    }

    func testSchemaTriggerRejectsUnsupportedNormalizationAtDatabaseBoundary() throws {
        let snapshot = try makeSnapshot(normalizationVersion: NormalizationVersion(rawValue: "future-v9"))
        _ = try repository.addRoot(to: snapshot, name: "Root")

        XCTAssertThrowsError(
            try database.execute(
                "UPDATE snapshots SET status = 'complete' WHERE id = ?",
                bindings: [.integer(snapshot.rawValue)]
            )
        )
        XCTAssertEqual(try repository.snapshot(id: snapshot)?.status, .scanning)
    }

    func testClassificationRowsAreNotRequiredOrCreated() throws {
        let snapshot = try makeSnapshot()
        _ = try repository.addRoot(to: snapshot, name: "Root")
        try repository.complete(snapshot)

        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM entry_classifications")?.int64Value, 0)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM snapshots WHERE status = 'complete'")?.int64Value, 1)
    }

    private func makeSnapshot(normalizationVersion: NormalizationVersion = .current) throws -> SnapshotID {
        defer { nextSession += 1 }
        return try repository.createSnapshot(
            volumeID: 1,
            sessionNumber: nextSession,
            scanRootName: "Root \(nextSession)",
            normalizationVersion: normalizationVersion
        )
    }
}
