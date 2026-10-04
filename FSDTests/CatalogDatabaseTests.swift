import XCTest
import SQLite3
@testable import FSD

final class CatalogDatabaseTests: XCTestCase {
    func testFreshDatabaseBootstrapsCurrentSchemaVersionAndIntegrity() throws {
        let (directory, databaseURL) = try makeTemporaryDatabase()
        defer { try? FileManager.default.removeItem(at: directory) }

        let database = try CatalogDatabase(url: databaseURL, schemaURL: canonicalSchemaURL)
        defer { database.close() }

        XCTAssertEqual(try database.schemaVersion, 9)
        XCTAssertEqual(try database.scalar(
            "SELECT COUNT(*) FROM pragma_table_info('entry_classifications') WHERE name = 'provider_identifier' AND type = 'TEXT' AND \"notnull\" = 0 AND dflt_value IS NULL"
        )?.int64Value, 1)
        XCTAssertEqual(try database.scalar("PRAGMA foreign_keys")?.int64Value, 1)
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
    }

    func testExistingCurrentSchemaDatabaseReopens() throws {
        let (directory, databaseURL) = try makeTemporaryDatabase()
        defer { try? FileManager.default.removeItem(at: directory) }

        let first = try CatalogDatabase(url: databaseURL, schemaURL: canonicalSchemaURL)
        first.close()
        let reopened = try CatalogDatabase(url: databaseURL, schemaURL: canonicalSchemaURL)
        defer { reopened.close() }

        XCTAssertEqual(try reopened.schemaVersion, CatalogDatabase.currentSchemaVersion)
        XCTAssertEqual(try reopened.scalar("PRAGMA foreign_keys")?.int64Value, 1)
    }

    func testUnsupportedFutureSchemaVersionIsRejected() throws {
        let (directory, databaseURL) = try makeTemporaryDatabase()
        defer { try? FileManager.default.removeItem(at: directory) }
        try createVersionedDatabase(at: databaseURL, version: 99)

        XCTAssertThrowsError(try CatalogDatabase(url: databaseURL, schemaURL: canonicalSchemaURL)) { error in
            guard case let CatalogDatabaseError.unsupportedSchemaVersion(version) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(version, 99)
        }
    }

    func testFailedBootstrapDoesNotMarkSchemaComplete() throws {
        let (directory, databaseURL) = try makeTemporaryDatabase()
        defer { try? FileManager.default.removeItem(at: directory) }
        let invalidSchemaURL = directory.appendingPathComponent("invalid-schema.sql")
        try "CREATE TABLE partial (id INTEGER); INSERT INTO missing_table VALUES (1);".write(to: invalidSchemaURL, atomically: true, encoding: .utf8)

        XCTAssertThrowsError(try CatalogDatabase(url: databaseURL, schemaURL: invalidSchemaURL))

        let database = try CatalogDatabase(url: databaseURL, schemaURL: canonicalSchemaURL)
        defer { database.close() }
        XCTAssertEqual(try database.schemaVersion, CatalogDatabase.currentSchemaVersion)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = 'partial'")?.int64Value, 0)
    }

    func testForeignKeysAreEnabledOnEveryOpenedConnection() throws {
        let (directory, databaseURL) = try makeTemporaryDatabase()
        defer { try? FileManager.default.removeItem(at: directory) }

        let first = try CatalogDatabase(url: databaseURL, schemaURL: canonicalSchemaURL)
        let second = try CatalogDatabase(url: databaseURL, schemaURL: canonicalSchemaURL)
        defer {
            second.close()
            first.close()
        }

        XCTAssertEqual(try first.scalar("PRAGMA foreign_keys")?.int64Value, 1)
        XCTAssertEqual(try second.scalar("PRAGMA foreign_keys")?.int64Value, 1)
    }

    func testExplicitCloseIsIdempotentBeforeTemporaryCatalogRemoval() throws {
        let (directory, databaseURL) = try makeTemporaryDatabase()
        defer { try? FileManager.default.removeItem(at: directory) }

        let database = try CatalogDatabase(url: databaseURL, schemaURL: canonicalSchemaURL)
        database.close()
        database.close()

        XCTAssertThrowsError(try database.scalar("PRAGMA integrity_check")) { error in
            guard case let CatalogDatabaseError.sqlite(code, _) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(code, SQLITE_MISUSE)
        }
    }

    private var canonicalSchemaURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/database/schema.sql")
    }

    private func makeTemporaryDatabase() throws -> (URL, URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSDTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return (directory, directory.appendingPathComponent("catalog.sqlite3"))
    }

    private func createVersionedDatabase(at url: URL, version: Int64) throws {
        var handle: OpaquePointer?
        let openResult = url.path.withCString { sqlite3_open_v2($0, &handle, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil) }
        XCTAssertEqual(openResult, SQLITE_OK)
        defer { if let handle { sqlite3_close(handle) } }
        var errorMessage: UnsafeMutablePointer<CChar>?
        let sql = "CREATE TABLE schema_migrations (version INTEGER PRIMARY KEY, applied_at TEXT NOT NULL); INSERT INTO schema_migrations VALUES (\(version), CURRENT_TIMESTAMP);"
        let result = sqlite3_exec(handle, sql, nil, nil, &errorMessage)
        if let errorMessage { sqlite3_free(errorMessage) }
        XCTAssertEqual(result, SQLITE_OK)
    }
}
