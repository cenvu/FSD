import XCTest
import SQLite3
@testable import FSD

/// Builds the version-4 and version-5 catalogs that really exist in the wild,
/// by taking the canonical schema apart again.
///
/// Deriving the fixtures from `schema.sql` rather than checking in a frozen copy
/// keeps them honest: if a later version's additions are ever renamed or
/// restructured, `remove(...)` fails immediately instead of quietly producing a
/// fixture that is no longer the version it claims to be.
enum CatalogSchemaFixture {
    static var canonicalSchemaURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/database/schema.sql")
    }

    /// Removes the schema-version-6 additions (ADR-027): the profile version
    /// and frozen profile_version columns, the three terminal-result guards,
    /// and the differences-only index.
    private static func removeVersion6Additions(from sql: inout String) throws {
        for column in [
            "    version                     INTEGER NOT NULL DEFAULT 1,\n",
            "    profile_version     INTEGER NOT NULL DEFAULT 1,\n"
        ] {
            try remove(exactly: column, from: &sql)
        }
        for trigger in [
            "CREATE TRIGGER IF NOT EXISTS trg_comparisons_terminal_immutable",
            "CREATE TRIGGER IF NOT EXISTS trg_comparison_results_insert_guard",
            "CREATE TRIGGER IF NOT EXISTS trg_comparison_results_update_guard"
        ] {
            try removeStatement(startingWith: trigger, from: &sql)
        }
        try remove(
            exactly: "CREATE INDEX IF NOT EXISTS idx_comparison_results_type\nON comparison_results(comparison_id, result_type);\n",
            from: &sql
        )
    }

    /// Removes the schema-version-8 addition (ADR-030): the dedicated
    /// parent-result cascade index and the version row bump.
    private static func removeVersion8Additions(from sql: inout String) throws {
        try remove(
            exactly: "CREATE INDEX IF NOT EXISTS idx_comparison_results_parent_result_id\nON comparison_results(parent_result_id);\n",
            from: &sql
        )
        try remove(exactly: "VALUES (8, CURRENT_TIMESTAMP);", from: &sql, replacement: "VALUES (7, CURRENT_TIMESTAMP);")
    }

    /// Removes the schema-version-7 additions (ADR-028): the seven terminal
    /// comparison-evidence guards and the version row bump.
    private static func removeVersion7Additions(from sql: inout String) throws {
        for trigger in [
            "CREATE TRIGGER IF NOT EXISTS trg_comparison_results_delete_guard",
            "CREATE TRIGGER IF NOT EXISTS trg_comparison_collision_groups_insert_guard",
            "CREATE TRIGGER IF NOT EXISTS trg_comparison_collision_groups_update_guard",
            "CREATE TRIGGER IF NOT EXISTS trg_comparison_collision_groups_delete_guard",
            "CREATE TRIGGER IF NOT EXISTS trg_comparison_collision_members_insert_guard",
            "CREATE TRIGGER IF NOT EXISTS trg_comparison_collision_members_update_guard",
            "CREATE TRIGGER IF NOT EXISTS trg_comparison_collision_members_delete_guard"
        ] {
            try removeStatement(startingWith: trigger, from: &sql)
        }
        try remove(exactly: "VALUES (7, CURRENT_TIMESTAMP);", from: &sql, replacement: "VALUES (6, CURRENT_TIMESTAMP);")
    }

    /// A schema-version-6 catalog, as a version-6 catalog really exists after
    /// ADR-027: the canonical schema with the version-7 additions removed.
    static func version6SQL() throws -> String {
        var sql = try version7SQL()
        try removeVersion7Additions(from: &sql)
        return sql
    }

    /// A schema-version-7 catalog, as a version-7 catalog really exists after
    /// ADR-028 and before the ADR-030 index correction.
    static func version7SQL() throws -> String {
        var sql = try version8SQL()
        try removeVersion8Additions(from: &sql)
        return sql
    }

    /// The real v8 schema: remove only the v9 column and version-row bump.
    static func version8SQL() throws -> String {
        var sql = try String(contentsOf: canonicalSchemaURL, encoding: .utf8)
        try remove(exactly: "    provider_identifier TEXT,\n", from: &sql)
        try remove(exactly: "VALUES (9, CURRENT_TIMESTAMP);", from: &sql, replacement: "VALUES (8, CURRENT_TIMESTAMP);")
        return sql
    }

    /// - Parameter withImmutabilityGuards: `false` reproduces a catalog created
    ///   before 2026-08-04 01:24, which had no completed-snapshot guards at all;
    ///   `true` reproduces one that received them from the unconditional DDL
    ///   install that schema version 5 removes.
    static func version4SQL(withImmutabilityGuards: Bool) throws -> String {
        var sql = try version5SQL()

        for column in [
            "    volume_display_name_at_capture        TEXT,\n",
            "    volume_identifier_at_capture          TEXT,\n",
            "    volume_total_capacity_bytes_at_capture INTEGER,\n"
        ] {
            try remove(exactly: column, from: &sql)
        }
        try removeStatement(startingWith: "CREATE TRIGGER IF NOT EXISTS trg_snapshots_capture_facts_immutable", from: &sql)
        try remove(
            exactly: "CREATE INDEX IF NOT EXISTS idx_entries_snapshot_extension\nON entries(snapshot_id, file_extension);\n",
            from: &sql
        )
        try remove(exactly: "VALUES (5, CURRENT_TIMESTAMP);", from: &sql, replacement: "VALUES (4, CURRENT_TIMESTAMP);")

        if !withImmutabilityGuards {
            for trigger in [
                "CREATE TRIGGER IF NOT EXISTS trg_completed_entries_insert_guard",
                "CREATE TRIGGER IF NOT EXISTS trg_completed_entries_update_guard",
                "CREATE TRIGGER IF NOT EXISTS trg_completed_entries_delete_guard",
                "CREATE TRIGGER IF NOT EXISTS trg_completed_scan_issues_insert_guard"
            ] {
                try removeStatement(startingWith: trigger, from: &sql)
            }
        }
        return sql
    }

    /// A schema-version-5 catalog, as a version-5 catalog really exists today:
    /// the canonical schema with the version-7 and version-6 additions removed.
    static func version5SQL() throws -> String {
        var sql = try version6SQL()
        try removeVersion6Additions(from: &sql)
        try remove(exactly: "VALUES (6, CURRENT_TIMESTAMP);", from: &sql, replacement: "VALUES (5, CURRENT_TIMESTAMP);")
        return sql
    }

    static func createDatabase(at url: URL, sql: String) throws {
        var handle: OpaquePointer?
        let openResult = url.path.withCString {
            sqlite3_open_v2($0, &handle, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil)
        }
        guard openResult == SQLITE_OK, let handle else {
            throw NSError(domain: "CatalogSchemaFixture", code: Int(openResult))
        }
        defer { sqlite3_close(handle) }
        var errorMessage: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(handle, sql, nil, nil, &errorMessage)
        let message = errorMessage.map { String(cString: $0) } ?? ""
        if let errorMessage { sqlite3_free(errorMessage) }
        guard result == SQLITE_OK else {
            throw NSError(domain: "CatalogSchemaFixture", code: Int(result), userInfo: [NSLocalizedDescriptionKey: message])
        }
    }

    private static func remove(exactly text: String, from sql: inout String, replacement: String = "") throws {
        guard let range = sql.range(of: text) else {
            throw NSError(
                domain: "CatalogSchemaFixture", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "schema.sql no longer contains \(text.debugDescription)"]
            )
        }
        sql.replaceSubrange(range, with: replacement)
    }

    private static func removeStatement(startingWith prefix: String, from sql: inout String) throws {
        guard let start = sql.range(of: prefix) else {
            throw NSError(
                domain: "CatalogSchemaFixture", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "schema.sql no longer contains a statement starting with \(prefix)"]
            )
        }
        guard let end = sql.range(of: "\nEND;\n", range: start.upperBound..<sql.endIndex) else {
            throw NSError(
                domain: "CatalogSchemaFixture", code: 3,
                userInfo: [NSLocalizedDescriptionKey: "no terminator found for \(prefix)"]
            )
        }
        sql.replaceSubrange(start.lowerBound..<end.upperBound, with: "")
    }
}

final class SchemaMigrationTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-Migration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        directory = nil
    }

    // MARK: - 1. Fresh database

    func testFreshDatabaseReachesCurrentVersionWithCleanIntegrity() throws {
        let database = try open(named: "fresh")

        XCTAssertEqual(try database.schemaVersion, 9)
        XCTAssertEqual(CatalogDatabase.currentSchemaVersion, 9)
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM schema_migrations")?.int64Value, 1)
    }

    // MARK: - 2 and 3. Both known version-4 variants

    func testPreMilestone2Version4MigratesToCurrentVersion() throws {
        let url = try makeVersion4(named: "pre-m2", withImmutabilityGuards: false)
        // Precondition: this fixture really is the unguarded variant.
        XCTAssertEqual(try guardTriggerCount(at: url), 0)

        let database = try CatalogDatabase(url: url)

        XCTAssertEqual(try database.schemaVersion, 9)
        XCTAssertEqual(try triggerCount(database, name: "trg_completed_entries_insert_guard"), 1)
        XCTAssertEqual(try triggerCount(database, name: "trg_snapshots_capture_facts_immutable"), 1)
        XCTAssertEqual(try triggerCount(database, name: "trg_comparisons_terminal_immutable"), 1)
        XCTAssertEqual(try triggerCount(database, name: "trg_comparison_collision_groups_delete_guard"), 1)
        XCTAssertEqual(try triggerCount(database, name: "trg_comparison_collision_members_delete_guard"), 1)
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
    }

    func testPostMilestone2Version4MigratesToCurrentVersion() throws {
        let url = try makeVersion4(named: "post-m2", withImmutabilityGuards: true)
        XCTAssertEqual(try guardTriggerCount(at: url), 4)

        let database = try CatalogDatabase(url: url)

        XCTAssertEqual(try database.schemaVersion, 9)
        XCTAssertEqual(try triggerCount(database, name: "trg_snapshots_capture_facts_immutable"), 1)
        XCTAssertEqual(try triggerCount(database, name: "trg_comparison_results_delete_guard"), 1)
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
    }

    func testExistingVersion4DataSurvivesMigration() throws {
        let url = try makeVersion4(named: "with-data", withImmutabilityGuards: true)
        try seedVersion4Snapshot(at: url)

        let database = try CatalogDatabase(url: url)

        XCTAssertEqual(try database.schemaVersion, 9)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM snapshots")?.int64Value, 1)
        XCTAssertEqual(try database.scalar("SELECT status FROM snapshots")?.stringValue, "complete")
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM entries")?.int64Value, 1)
        // A pre-version-5 snapshot has no recorded volume facts and must not be
        // back-filled from the mutable registry.
        let summary = try XCTUnwrap(
            SnapshotHistoryRepository(database: database).listSnapshots().first
        )
        XCTAssertNil(summary.capture.volumeDisplayName)
        XCTAssertFalse(summary.capture.isFullyRecorded)
        XCTAssertEqual(summary.capture.displayNameForHistory, "Not recorded at capture time")
    }

    // MARK: - 2b. Version 5 and version 6 to the current version

    func testVersionFiveMigratesToCurrentVersion() throws {
        let url = try makeVersion5(named: "v5")
        XCTAssertEqual(try rawScalarInt(at: url, "SELECT MAX(version) FROM schema_migrations"), 5)
        XCTAssertEqual(
            try rawScalarInt(at: url, "SELECT COUNT(*) FROM pragma_table_info('comparisons') WHERE name = 'profile_version'"),
            0
        )

        let database = try CatalogDatabase(url: url)

        XCTAssertEqual(try database.schemaVersion, 9)
        XCTAssertEqual(try triggerCount(database, name: "trg_comparisons_terminal_immutable"), 1)
        XCTAssertEqual(try triggerCount(database, name: "trg_comparison_results_insert_guard"), 1)
        XCTAssertEqual(try triggerCount(database, name: "trg_comparison_results_update_guard"), 1)
        XCTAssertEqual(try triggerCount(database, name: "trg_comparison_collision_groups_insert_guard"), 1)
        XCTAssertEqual(try triggerCount(database, name: "trg_comparison_collision_members_update_guard"), 1)
        XCTAssertEqual(try database.scalar(
            "SELECT COUNT(*) FROM pragma_table_info('comparisons') WHERE name = 'profile_version'"
        )?.int64Value, 1)
        XCTAssertEqual(try database.scalar(
            "SELECT COUNT(*) FROM pragma_table_info('comparison_profiles') WHERE name = 'version'"
        )?.int64Value, 1)
        XCTAssertEqual(try database.scalar(
            "SELECT COUNT(*) FROM sqlite_master WHERE name = 'idx_comparison_results_type'"
        )?.int64Value, 1)
        XCTAssertEqual(try database.scalar(
            "SELECT COUNT(*) FROM sqlite_master WHERE name = 'idx_comparison_results_parent_result_id'"
        )?.int64Value, 1)
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
        // The built-in profiles carried their version through the migration.
        XCTAssertEqual(try database.scalar("SELECT MIN(version) FROM comparison_profiles")?.int64Value, 1)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM comparison_profiles")?.int64Value, 3)
    }

    func testVersionFiveExistingDataSurvivesMigrationToCurrentVersion() throws {
        let url = try makeVersion5(named: "v5-data")
        try seedVersion5Comparison(at: url)

        let database = try CatalogDatabase(url: url)

        XCTAssertEqual(try database.schemaVersion, 9)
        let stored = try XCTUnwrap(try database.scalar(
            "SELECT profile_version FROM comparisons WHERE id = 1"
        )?.int64Value)
        XCTAssertEqual(stored, 1, "existing comparison rows default to profile version 1")
        XCTAssertEqual(try database.scalar(
            "SELECT COUNT(*) FROM comparison_results WHERE comparison_id = 1"
        )?.int64Value, 1)
    }

    func testVersionSixMigratesToVersionSeven() throws {
        let url = try makeVersion6(named: "v6")
        XCTAssertEqual(try rawScalarInt(at: url, "SELECT MAX(version) FROM schema_migrations"), 6)
        XCTAssertEqual(
            try rawScalarInt(at: url, "SELECT COUNT(*) FROM sqlite_master WHERE name = 'trg_comparison_collision_groups_delete_guard'"),
            0
        )

        let database = try CatalogDatabase(url: url)

        XCTAssertEqual(try database.schemaVersion, 9)
        XCTAssertEqual(try triggerCount(database, name: "trg_comparison_results_delete_guard"), 1)
        XCTAssertEqual(try triggerCount(database, name: "trg_comparison_collision_groups_insert_guard"), 1)
        XCTAssertEqual(try triggerCount(database, name: "trg_comparison_collision_groups_update_guard"), 1)
        XCTAssertEqual(try triggerCount(database, name: "trg_comparison_collision_groups_delete_guard"), 1)
        XCTAssertEqual(try triggerCount(database, name: "trg_comparison_collision_members_insert_guard"), 1)
        XCTAssertEqual(try triggerCount(database, name: "trg_comparison_collision_members_update_guard"), 1)
        XCTAssertEqual(try triggerCount(database, name: "trg_comparison_collision_members_delete_guard"), 1)
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
    }

    func testVersionSixCollisionEvidenceSurvivesMigrationAndIsProtected() throws {
        let url = try makeVersion6(named: "v6-data")
        try seedVersion6CollisionEvidence(at: url)

        let database = try CatalogDatabase(url: url)

        XCTAssertEqual(try database.schemaVersion, 9)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM comparison_collision_groups WHERE comparison_id = 1")?.int64Value, 1)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM comparison_collision_members WHERE group_id = 1")?.int64Value, 2)
        XCTAssertEqual(try database.scalar("SELECT status FROM comparisons WHERE id = 1")?.stringValue, "complete")

        // After the migration the v7 guards protect the migrated evidence.
        XCTAssertThrowsError(try database.execute(
            "INSERT INTO comparison_collision_groups (comparison_id, result_path, created_at) VALUES (1, '/late', CURRENT_TIMESTAMP)"
        ))
        XCTAssertThrowsError(try database.execute(
            "DELETE FROM comparison_collision_members WHERE group_id = 1"
        ))
        XCTAssertThrowsError(try database.execute(
            "DELETE FROM comparison_results WHERE comparison_id = 1"
        ))
        // Disposal of the migrated comparison still cascades.
        try database.execute("DELETE FROM comparisons WHERE id = 1")
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM comparison_collision_groups WHERE comparison_id = 1")?.int64Value, 0)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM comparison_collision_members WHERE group_id = 1")?.int64Value, 0)
        XCTAssertEqual(try database.scalar("SELECT COUNT(*) FROM comparison_results WHERE comparison_id = 1")?.int64Value, 0)
    }

    func testVersionEightMigratesLegacyRowsWithoutBackfillAndReopensWithoutReplay() throws {
        let url = try makeVersion8(named: "legacy-v8")
        try seedVersion4Snapshot(at: url)
        try CatalogSchemaFixture.createDatabase(at: url, sql: """
        INSERT INTO entry_classifications (
            entry_id, classification_run_id, detected_type, detection_status,
            detector_version, model_version, classified_at, created_at
        ) VALUES (1, 'legacy-classified', 'text', 'classified', 'legacy-detector', 'legacy-model', '2026-08-01', '2026-08-01'),
                 (1, 'legacy-failed', NULL, 'failed', NULL, NULL, NULL, '2026-08-02');
        CREATE TABLE fixture_entries_before AS SELECT * FROM entries;
        CREATE TABLE fixture_snapshots_before AS SELECT * FROM snapshots;
        """)
        XCTAssertEqual(try rawScalarInt(at: url,
            "SELECT COUNT(*) FROM pragma_table_info('entry_classifications') WHERE name = 'provider_identifier'"), 0)

        let migrated = try CatalogDatabase(url: url)
        let repository = EntryClassificationRepository(database: migrated)
        let history = try repository.history(for: 1)
        XCTAssertEqual(history.map(\.classificationRunID), ["legacy-failed", "legacy-classified"])
        XCTAssertEqual(history.count, 2)
        XCTAssertTrue(history.allSatisfy { $0.providerIdentifier == nil })
        XCTAssertEqual(history.last?.detectorVersion, "legacy-detector")
        XCTAssertEqual(history.last?.modelVersion, "legacy-model")
        XCTAssertEqual(history.last?.detectedType, "text")
        XCTAssertEqual(history.last?.detectionStatus, .classified)
        XCTAssertEqual(history.last?.classifiedAt, "2026-08-01")
        XCTAssertEqual(history.last?.createdAt, "2026-08-01")
        XCTAssertEqual(try repository.classification(for: 1), history.first)
        XCTAssertEqual(try repository.latestClassifications(for: [1])[1], history.first)
        for table in ["entries", "snapshots"] {
            XCTAssertEqual(try migrated.scalar(
                "SELECT COUNT(*) FROM (SELECT * FROM \(table) EXCEPT SELECT * FROM fixture_\(table)_before)"
            )?.int64Value, 0)
            XCTAssertEqual(try migrated.scalar(
                "SELECT COUNT(*) FROM (SELECT * FROM fixture_\(table)_before EXCEPT SELECT * FROM \(table))"
            )?.int64Value, 0)
        }
        XCTAssertEqual(try migrated.schemaVersion, 9)
        let versions = try migrated.query("SELECT version, applied_at FROM schema_migrations ORDER BY version")
        XCTAssertEqual(versions.map { $0["version"]?.int64Value }, [8, 9])
        let fresh = try open(named: "fresh-v9-order")
        let freshColumns = try fresh.query("PRAGMA table_info(entry_classifications)")
        let migratedColumns = try migrated.query("PRAGMA table_info(entry_classifications)")
        for field in ["cid", "name", "type", "notnull", "dflt_value", "pk"] {
            XCTAssertEqual(freshColumns.map { $0[field] }, migratedColumns.map { $0[field] }, field)
        }
        XCTAssertEqual(migratedColumns.last?["name"]?.stringValue, "provider_identifier")
        XCTAssertEqual(migratedColumns.last?["notnull"]?.int64Value, 0)
        XCTAssertEqual(migratedColumns.last?["dflt_value"], .null)
        XCTAssertEqual(try migrated.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try migrated.query("PRAGMA foreign_key_check").isEmpty)
        migrated.close()
        // A migration that would fail immediately cannot run after success.
        let reopened = try CatalogDatabase(url: url, migrations: [SchemaMigration(
            version: 9, statements: ["INSERT INTO must_not_replay VALUES (1)"]
        )])
        XCTAssertEqual(try reopened.schemaVersion, 9)
        let after = try reopened.query("SELECT version, applied_at FROM schema_migrations ORDER BY version")
        for field in ["version", "applied_at"] {
            XCTAssertEqual(versions.map { $0[field] }, after.map { $0[field] })
        }
        XCTAssertEqual(try EntryClassificationRepository(database: reopened).history(for: 1), history)
    }

    func testVersionNineVersionRowIsWrittenAfterEveryMigrationStatement() throws {
        let url = try makeVersion8(named: "version-last-v9")
        try CatalogSchemaFixture.createDatabase(at: url, sql: """
        CREATE TABLE fixture_version_order (
            prior_version INTEGER CHECK (prior_version = 8),
            column_exists INTEGER CHECK (column_exists = 1)
        );
        CREATE TRIGGER fixture_version_last BEFORE INSERT ON schema_migrations
        WHEN NEW.version = 9
        BEGIN
            SELECT CASE WHEN (SELECT COUNT(*) FROM fixture_version_order) != 1
                THEN RAISE(ABORT, 'Version row must be written last') END;
        END;
        """)
        let migration = SchemaMigration(version: 9, statements: CatalogMigrations.migrationToVersion9.statements + [
            """
            INSERT INTO fixture_version_order SELECT MAX(version),
                (SELECT COUNT(*) FROM pragma_table_info('entry_classifications') WHERE name = 'provider_identifier')
            FROM schema_migrations
            """
        ])
        let database = try CatalogDatabase(url: url, migrations: [migration])
        XCTAssertEqual(try database.schemaVersion, 9)
        XCTAssertEqual(try database.scalar("SELECT prior_version FROM fixture_version_order")?.int64Value, 8)
        XCTAssertEqual(try database.scalar("SELECT column_exists FROM fixture_version_order")?.int64Value, 1)
    }

    func testFailedVersionNineRollsBackDDLAndDataAtStatementOrVersionWriteFailure() throws {
        for failAtVersionWrite in [false, true] {
            let url = try makeVersion8(named: "rollback-v9-\(failAtVersionWrite)")
            try seedVersion4Snapshot(at: url)
            try CatalogSchemaFixture.createDatabase(at: url, sql: """
            INSERT INTO entry_classifications (entry_id, classification_run_id, created_at)
            VALUES (1, 'legacy', '2026-08-01');
            CREATE TABLE fixture_entries_before AS SELECT * FROM entries;
            CREATE TABLE fixture_snapshots_before AS SELECT * FROM snapshots;
            CREATE TABLE fixture_classifications_before AS SELECT * FROM entry_classifications;
            """)
            if failAtVersionWrite {
                try CatalogSchemaFixture.createDatabase(at: url, sql: """
                CREATE TRIGGER fixture_reject_v9 BEFORE INSERT ON schema_migrations
                WHEN NEW.version = 9 BEGIN SELECT RAISE(ABORT, 'Injected version write failure'); END;
                """)
            }
            let statements = CatalogMigrations.migrationToVersion9.statements +
                (failAtVersionWrite ? [] : ["INSERT INTO table_that_does_not_exist VALUES (1)"])
            XCTAssertThrowsError(try CatalogDatabase(url: url, migrations: [SchemaMigration(version: 9, statements: statements)])) { error in
                guard case let CatalogDatabaseError.migrationFailed(version, _) = error else {
                    return XCTFail("Unexpected error: \(error)")
                }
                XCTAssertEqual(version, 9)
            }
            XCTAssertEqual(try rawScalarInt(at: url, "SELECT MAX(version) FROM schema_migrations"), 8)
            XCTAssertEqual(try rawScalarInt(at: url, "SELECT COUNT(*) FROM schema_migrations"), 1)
            XCTAssertEqual(try rawScalarInt(at: url,
                "SELECT COUNT(*) FROM pragma_table_info('entry_classifications') WHERE name = 'provider_identifier'"), 0)
            for (table, saved) in [("entries", "fixture_entries_before"), ("snapshots", "fixture_snapshots_before"),
                                   ("entry_classifications", "fixture_classifications_before")] {
                XCTAssertEqual(try rawScalarInt(at: url,
                    "SELECT COUNT(*) FROM (SELECT * FROM \(table) EXCEPT SELECT * FROM \(saved))"), 0)
                XCTAssertEqual(try rawScalarInt(at: url,
                    "SELECT COUNT(*) FROM (SELECT * FROM \(saved) EXCEPT SELECT * FROM \(table))"), 0)
            }
            if failAtVersionWrite {
                try CatalogSchemaFixture.createDatabase(at: url, sql: "DROP TRIGGER fixture_reject_v9;")
            }
            let repaired = try CatalogDatabase(url: url)
            XCTAssertEqual(try repaired.schemaVersion, 9)
            XCTAssertNil(try EntryClassificationRepository(database: repaired).classification(for: 1)?.providerIdentifier)
            XCTAssertEqual(try repaired.scalar("PRAGMA integrity_check")?.stringValue, "ok")
            XCTAssertTrue(try repaired.query("PRAGMA foreign_key_check").isEmpty)
        }
    }

    func testVersionNineWithoutProviderIdentifierIsRejected() throws {
        let url = directory.appendingPathComponent("damaged-v9.sqlite3")
        let sql = try CatalogSchemaFixture.version8SQL().replacingOccurrences(
            of: "VALUES (8, CURRENT_TIMESTAMP);", with: "VALUES (9, CURRENT_TIMESTAMP);"
        )
        try CatalogSchemaFixture.createDatabase(at: url, sql: sql)
        XCTAssertThrowsError(try CatalogDatabase(url: url)) { error in
            guard case let CatalogDatabaseError.schemaStateInvalid(detail) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertTrue(detail.contains("entry_classifications column provider_identifier"), detail)
        }
    }

    // MARK: - 4. Rollback

    func testFailedMigrationRollsBackAndLeavesRecordedVersionUnchanged() throws {
        let url = try makeVersion4(named: "rollback", withImmutabilityGuards: false)
        let broken = SchemaMigration(
            version: 5,
            statements: [
                "ALTER TABLE snapshots ADD COLUMN volume_display_name_at_capture TEXT",
                "CREATE INDEX idx_will_not_exist ON entries(snapshot_id, name)",
                "INSERT INTO table_that_does_not_exist VALUES (1)"
            ]
        )

        XCTAssertThrowsError(try CatalogDatabase(url: url, migrations: [broken])) { error in
            guard case let CatalogDatabaseError.migrationFailed(version, _) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(version, 5)
        }

        // Nothing from the failed attempt survives, and version 4 still stands.
        XCTAssertEqual(try rawScalarInt(at: url, "SELECT MAX(version) FROM schema_migrations"), 4)
        XCTAssertEqual(
            try rawScalarInt(at: url, "SELECT COUNT(*) FROM pragma_table_info('snapshots') WHERE name = 'volume_display_name_at_capture'"),
            0
        )
        XCTAssertEqual(
            try rawScalarInt(at: url, "SELECT COUNT(*) FROM sqlite_master WHERE name = 'idx_will_not_exist'"),
            0
        )

        // The same catalog opens cleanly once the real migrations run.
        let repaired = try CatalogDatabase(url: url)
        XCTAssertEqual(try repaired.schemaVersion, 9)
    }

    func testFailedVersionSixMigrationRollsBackAndLeavesVersionFiveStanding() throws {
        let url = try makeVersion5(named: "rollback-v6")
        let broken = SchemaMigration(
            version: 6,
            statements: [
                "ALTER TABLE comparison_profiles ADD COLUMN version INTEGER NOT NULL DEFAULT 1",
                "CREATE TRIGGER trg_comparison_results_update_guard_x AFTER UPDATE ON comparison_results BEGIN SELECT 1; END",
                "INSERT INTO table_that_does_not_exist VALUES (1)"
            ]
        )

        XCTAssertThrowsError(try CatalogDatabase(url: url, migrations: [broken])) { error in
            guard case let CatalogDatabaseError.migrationFailed(version, _) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(version, 6)
        }

        XCTAssertEqual(try rawScalarInt(at: url, "SELECT MAX(version) FROM schema_migrations"), 5)
        XCTAssertEqual(
            try rawScalarInt(at: url, "SELECT COUNT(*) FROM pragma_table_info('comparisons') WHERE name = 'profile_version'"),
            0
        )
        XCTAssertEqual(
            try rawScalarInt(at: url, "SELECT COUNT(*) FROM sqlite_master WHERE name = 'trg_comparison_results_update_guard_x'"),
            0
        )

        let repaired = try CatalogDatabase(url: url)
        XCTAssertEqual(try repaired.schemaVersion, 9)
    }

    func testFailedVersionSevenMigrationRollsBackAndLeavesVersionSixStanding() throws {
        let url = try makeVersion6(named: "rollback-v7")
        let broken = SchemaMigration(
            version: 7,
            statements: [
                "CREATE TRIGGER trg_comparison_collision_groups_insert_guard_x BEFORE INSERT ON comparison_collision_groups BEGIN SELECT 1; END",
                "INSERT INTO table_that_does_not_exist VALUES (1)"
            ]
        )

        XCTAssertThrowsError(try CatalogDatabase(url: url, migrations: [broken])) { error in
            guard case let CatalogDatabaseError.migrationFailed(version, _) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(version, 7)
        }

        XCTAssertEqual(try rawScalarInt(at: url, "SELECT MAX(version) FROM schema_migrations"), 6)
        XCTAssertEqual(
            try rawScalarInt(at: url, "SELECT COUNT(*) FROM sqlite_master WHERE name = 'trg_comparison_collision_groups_insert_guard_x'"),
            0
        )
        XCTAssertEqual(
            try rawScalarInt(at: url, "SELECT COUNT(*) FROM sqlite_master WHERE name = 'trg_comparison_results_delete_guard'"),
            0,
            "no version-7 object survives the failed migration"
        )

        let repaired = try CatalogDatabase(url: url)
        XCTAssertEqual(try repaired.schemaVersion, 9)
    }

    func testFailedVersionEightMigrationRollsBackAndLeavesVersionSevenStanding() throws {
        let url = try makeVersion7(named: "rollback-v8")
        let broken = SchemaMigration(
            version: 8,
            statements: [
                "CREATE INDEX idx_comparison_results_parent_result_id ON comparison_results(parent_result_id)",
                "INSERT INTO table_that_does_not_exist VALUES (1)"
            ]
        )

        XCTAssertThrowsError(try CatalogDatabase(url: url, migrations: [broken])) { error in
            guard case let CatalogDatabaseError.migrationFailed(version, _) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(version, 8)
        }

        XCTAssertEqual(try rawScalarInt(at: url, "SELECT MAX(version) FROM schema_migrations"), 7)
        XCTAssertEqual(
            try rawScalarInt(at: url, "SELECT COUNT(*) FROM sqlite_master WHERE name = 'idx_comparison_results_parent_result_id'"),
            0,
            "no version-8 object survives the failed migration"
        )

        let repaired = try CatalogDatabase(url: url)
        XCTAssertEqual(try repaired.schemaVersion, 9)
        XCTAssertEqual(
            try repaired.scalar("SELECT COUNT(*) FROM sqlite_master WHERE name = 'idx_comparison_results_parent_result_id'")?.int64Value,
            1
        )
    }

    // MARK: - 5. Reopening does not replay

    func testReopeningCurrentVersionDoesNotReplayTheMigrations() throws {
        let url = try makeVersion4(named: "reopen", withImmutabilityGuards: false)
        let migrated = try CatalogDatabase(url: url)
        let rowsAfterMigration = try migrated.query("SELECT version, applied_at FROM schema_migrations ORDER BY version")
        XCTAssertEqual(rowsAfterMigration.map { $0["version"]?.int64Value }, [4, 5, 6, 7, 8, 9])

        let reopened = try CatalogDatabase(url: url)
        let rowsAfterReopen = try reopened.query("SELECT version, applied_at FROM schema_migrations ORDER BY version")

        XCTAssertEqual(rowsAfterReopen.count, 6)
        XCTAssertEqual(
            rowsAfterMigration.map { $0["applied_at"]?.stringValue },
            rowsAfterReopen.map { $0["applied_at"]?.stringValue }
        )
        XCTAssertEqual(try reopened.schemaVersion, 9)
    }

    // MARK: - 6. Fresh and migrated are the same schema

    func testFreshAndMigratedSchemasAreEquivalent() throws {
        let fresh = try open(named: "equivalence-fresh")
        let migratedURL = try makeVersion4(named: "equivalence-migrated", withImmutabilityGuards: false)
        let migrated = try CatalogDatabase(url: migratedURL)

        XCTAssertEqual(try objectNames(fresh, type: "table"), try objectNames(migrated, type: "table"))
        XCTAssertEqual(try objectNames(fresh, type: "trigger"), try objectNames(migrated, type: "trigger"))
        XCTAssertEqual(try objectNames(fresh, type: "index"), try objectNames(migrated, type: "index"))
        XCTAssertEqual(try snapshotColumnNames(fresh), try snapshotColumnNames(migrated))
        XCTAssertEqual(
            try fresh.query("PRAGMA table_info(entry_classifications)").map { $0["name"] },
            try migrated.query("PRAGMA table_info(entry_classifications)").map { $0["name"] }
        )
        XCTAssertEqual(try tableColumnNames(fresh, table: "comparisons"), try tableColumnNames(migrated, table: "comparisons"))
        XCTAssertEqual(try tableColumnNames(fresh, table: "comparison_profiles"), try tableColumnNames(migrated, table: "comparison_profiles"))
    }

    func testFreshAndVersionFiveMigratedSchemasAreEquivalent() throws {
        let fresh = try open(named: "equivalence-v6-fresh")
        let migratedURL = try makeVersion5(named: "equivalence-v6-migrated")
        let migrated = try CatalogDatabase(url: migratedURL)

        XCTAssertEqual(try objectNames(fresh, type: "table"), try objectNames(migrated, type: "table"))
        XCTAssertEqual(try objectNames(fresh, type: "trigger"), try objectNames(migrated, type: "trigger"))
        XCTAssertEqual(try objectNames(fresh, type: "index"), try objectNames(migrated, type: "index"))
        XCTAssertEqual(try tableColumnNames(fresh, table: "comparisons"), try tableColumnNames(migrated, table: "comparisons"))
        XCTAssertEqual(try tableColumnNames(fresh, table: "comparison_profiles"), try tableColumnNames(migrated, table: "comparison_profiles"))
    }

    func testFreshAndMigratedEnforceIdenticalImmutableEntryRules() throws {
        let fresh = try open(named: "rules-fresh")
        let migratedURL = try makeVersion4(named: "rules-migrated", withImmutabilityGuards: false)
        let migrated = try CatalogDatabase(url: migratedURL)

        for database in [fresh, migrated] {
            let snapshotID = try makeCompletedSnapshot(in: database)

            XCTAssertThrowsError(try insertEntry(into: database, snapshotID: snapshotID, path: "later"))
            XCTAssertThrowsError(try database.execute(
                "UPDATE entries SET name = 'renamed' WHERE snapshot_id = ?", bindings: [.integer(snapshotID)]
            ))
            XCTAssertThrowsError(try database.execute(
                "DELETE FROM entries WHERE snapshot_id = ?", bindings: [.integer(snapshotID)]
            ))
            XCTAssertThrowsError(try database.execute(
                """
                INSERT INTO scan_issues (snapshot_id, relative_path, severity, source, message, was_skipped, created_at)
                VALUES (?, '', 'warning', 'scanner', 'late', 0, CURRENT_TIMESTAMP)
                """,
                bindings: [.integer(snapshotID)]
            ))
            XCTAssertThrowsError(try database.execute(
                "UPDATE snapshots SET status = 'scanning' WHERE id = ?", bindings: [.integer(snapshotID)]
            ))
            XCTAssertEqual(
                try database.scalar("SELECT COUNT(*) FROM entries WHERE snapshot_id = ?", bindings: [.integer(snapshotID)])?.int64Value,
                1
            )
        }
    }

    // MARK: - 7 and 8. Integrity, foreign keys, and rejected versions

    func testMigratedDatabasePassesIntegrityAndForeignKeyChecks() throws {
        let url = try makeVersion4(named: "integrity", withImmutabilityGuards: true)
        try seedVersion4Snapshot(at: url)
        let database = try CatalogDatabase(url: url)

        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
        XCTAssertEqual(try database.scalar("PRAGMA foreign_keys")?.int64Value, 1)
    }

    func testParentResultCascadeLookupUsesTheDedicatedLeadingIndex() throws {
        let database = try open(named: "query-plan")
        let plan = try database.query(
            "EXPLAIN QUERY PLAN SELECT id FROM comparison_results WHERE parent_result_id = ?",
            bindings: [.integer(1)]
        )
        let details = plan.compactMap { $0["detail"]?.stringValue }.joined(separator: "\n")

        XCTAssertFalse(details.contains("SCAN comparison_results"), details)
        XCTAssertTrue(details.contains("idx_comparison_results_parent_result_id"), details)
        print("[FSD-M5-SchemaV8] parent_result_id query plan: \(details)")
    }

    func testVersionsBelowFourAreRejectedRatherThanGuessedAt() throws {
        for version in [Int64(1), 2, 3] {
            let url = directory.appendingPathComponent("legacy-\(version).sqlite3")
            try CatalogSchemaFixture.createDatabase(
                at: url,
                sql: """
                CREATE TABLE schema_migrations (version INTEGER PRIMARY KEY, applied_at TEXT NOT NULL);
                INSERT INTO schema_migrations VALUES (\(version), CURRENT_TIMESTAMP);
                """
            )
            XCTAssertThrowsError(try CatalogDatabase(url: url)) { error in
                guard case let CatalogDatabaseError.unsupportedSchemaVersion(reported) = error else {
                    return XCTFail("Unexpected error for version \(version): \(error)")
                }
                XCTAssertEqual(reported, version)
            }
        }
    }

    func testUnsupportedFutureVersionStillFailsClearly() throws {
        let url = directory.appendingPathComponent("future.sqlite3")
        try CatalogSchemaFixture.createDatabase(
            at: url,
            sql: """
            CREATE TABLE schema_migrations (version INTEGER PRIMARY KEY, applied_at TEXT NOT NULL);
            INSERT INTO schema_migrations VALUES (99, CURRENT_TIMESTAMP);
            """
        )
        XCTAssertThrowsError(try CatalogDatabase(url: url)) { error in
            guard case let CatalogDatabaseError.unsupportedSchemaVersion(reported) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(reported, 99)
        }
    }

    /// The version number alone was what made Condition C2 possible. Opening a
    /// catalog that claims version 5 but is missing a version-5 object must now
    /// fail loudly instead of running with different rules.
    func testOpeningVersionFiveVerifiesTheSchemaState() throws {
        let url = directory.appendingPathComponent("tampered.sqlite3")
        _ = try CatalogDatabase(url: url, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        try CatalogSchemaFixture.createDatabase(at: url, sql: "DROP TRIGGER trg_completed_entries_insert_guard;")

        XCTAssertThrowsError(try CatalogDatabase(url: url)) { error in
            guard case let CatalogDatabaseError.schemaStateInvalid(detail) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertTrue(detail.contains("trg_completed_entries_insert_guard"), detail)
        }
    }

    // MARK: - Helpers

    private func open(named name: String) throws -> CatalogDatabase {
        try CatalogDatabase(
            url: directory.appendingPathComponent("\(name).sqlite3"),
            schemaURL: CatalogSchemaFixture.canonicalSchemaURL
        )
    }

    private func makeVersion4(named name: String, withImmutabilityGuards: Bool) throws -> URL {
        let url = directory.appendingPathComponent("\(name).sqlite3")
        try CatalogSchemaFixture.createDatabase(
            at: url,
            sql: try CatalogSchemaFixture.version4SQL(withImmutabilityGuards: withImmutabilityGuards)
        )
        XCTAssertEqual(try rawScalarInt(at: url, "SELECT MAX(version) FROM schema_migrations"), 4)
        return url
    }

    private func makeVersion5(named name: String) throws -> URL {
        let url = directory.appendingPathComponent("\(name).sqlite3")
        try CatalogSchemaFixture.createDatabase(at: url, sql: try CatalogSchemaFixture.version5SQL())
        XCTAssertEqual(try rawScalarInt(at: url, "SELECT MAX(version) FROM schema_migrations"), 5)
        return url
    }

    private func makeVersion6(named name: String) throws -> URL {
        let url = directory.appendingPathComponent("\(name).sqlite3")
        try CatalogSchemaFixture.createDatabase(at: url, sql: try CatalogSchemaFixture.version6SQL())
        XCTAssertEqual(try rawScalarInt(at: url, "SELECT MAX(version) FROM schema_migrations"), 6)
        return url
    }

    private func makeVersion8(named name: String) throws -> URL {
        let url = directory.appendingPathComponent("\(name).sqlite3")
        try CatalogSchemaFixture.createDatabase(at: url, sql: try CatalogSchemaFixture.version8SQL())
        XCTAssertEqual(try rawScalarInt(at: url, "SELECT MAX(version) FROM schema_migrations"), 8)
        return url
    }

    private func makeVersion7(named name: String) throws -> URL {
        let url = directory.appendingPathComponent("\(name).sqlite3")
        try CatalogSchemaFixture.createDatabase(at: url, sql: try CatalogSchemaFixture.version7SQL())
        XCTAssertEqual(try rawScalarInt(at: url, "SELECT MAX(version) FROM schema_migrations"), 7)
        return url
    }

    /// A completed version-6 comparison carrying collision evidence: one
    /// collision group, two members, and one result row — exactly the data
    /// the v7 guards must protect after migration.
    private func seedVersion6CollisionEvidence(at url: URL) throws {
        try CatalogSchemaFixture.createDatabase(at: url, sql: """
        INSERT INTO volumes (id, display_name, first_seen_at, last_seen_at, created_at, updated_at)
        VALUES (1, 'V6 Volume', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
        INSERT INTO snapshots (
            volume_id, session_number, scan_root_name, status, scanner_version, schema_version,
            normalization_version, display_name, capture_policy_json, started_at, created_at, updated_at
        ) VALUES (1, 1, 'A', 'scanning', 'fsd-scanner-m6', 6,
                  'fsd-normalizer-v1_app-1.0_os-1', 'A', '{}',
                  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
                 (1, 2, 'B', 'scanning', 'fsd-scanner-m6', 6,
                  'fsd-normalizer-v1_app-1.0_os-1', 'B', '{}',
                  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
        INSERT INTO entries (id, snapshot_id, parent_id, relative_path, case_preserving_path, case_folded_path,
                             name, case_preserving_name, case_folded_name, item_type, sort_key, created_at)
        VALUES (11, 1, NULL, '', '', '', 'A', 'A', 'a', 'directory', '0', CURRENT_TIMESTAMP),
               (12, 2, NULL, '', '', '', 'B', 'B', 'b', 'directory', '0', CURRENT_TIMESTAMP);
        UPDATE snapshots SET status = 'complete', completed_at = CURRENT_TIMESTAMP;
        -- The comparison starts running and writes its evidence before the
        -- terminal transition, exactly like the production engine: the v6
        -- result insert guard rejects result rows on a terminal comparison.
        INSERT INTO comparisons (id, left_snapshot_id, right_snapshot_id, profile_id, profile_version, status,
                                 matched_count, started_at, created_at)
        VALUES (1, 1, 2, 1, 1, 'running', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
        INSERT INTO comparison_results (comparison_id, result_path, display_name, result_type,
                                        left_entry_id, right_entry_id, difference_flags, created_at)
        VALUES (1, '', 'A', 'matched', 11, 12, 0, CURRENT_TIMESTAMP);
        INSERT INTO comparison_collision_groups (id, comparison_id, result_path, created_at)
        VALUES (1, 1, '/collide', CURRENT_TIMESTAMP);
        INSERT INTO comparison_collision_members (id, group_id, side, entry_id, created_at)
        VALUES (21, 1, 'left', 11, CURRENT_TIMESTAMP),
               (22, 1, 'right', 12, CURRENT_TIMESTAMP);
        UPDATE comparisons SET status = 'complete', completed_at = CURRENT_TIMESTAMP WHERE id = 1;
        """)
    }

    private func seedVersion5Comparison(at url: URL) throws {
        try CatalogSchemaFixture.createDatabase(at: url, sql: """
        INSERT INTO volumes (id, display_name, first_seen_at, last_seen_at, created_at, updated_at)
        VALUES (1, 'V5 Volume', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
        INSERT INTO snapshots (
            volume_id, session_number, scan_root_name, status, scanner_version, schema_version,
            normalization_version, display_name, capture_policy_json, started_at, created_at, updated_at
        ) VALUES (1, 1, 'A', 'scanning', 'fsd-scanner-m3', 5,
                  'fsd-normalizer-v1_app-1.0_os-1', 'A', '{}',
                  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
                 (1, 2, 'B', 'scanning', 'fsd-scanner-m3', 5,
                  'fsd-normalizer-v1_app-1.0_os-1', 'B', '{}',
                  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
        INSERT INTO entries (snapshot_id, parent_id, relative_path, case_preserving_path, case_folded_path,
                             name, case_preserving_name, case_folded_name, item_type, sort_key, created_at)
        VALUES (1, NULL, '', '', '', 'A', 'A', 'a', 'directory', '0', CURRENT_TIMESTAMP),
               (2, NULL, '', '', '', 'B', 'B', 'b', 'directory', '0', CURRENT_TIMESTAMP);
        UPDATE snapshots SET status = 'complete', completed_at = CURRENT_TIMESTAMP;
        INSERT INTO comparisons (id, left_snapshot_id, right_snapshot_id, profile_id, status,
                                 matched_count, started_at, created_at)
        VALUES (1, 1, 2, 1, 'complete', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
        INSERT INTO comparison_results (comparison_id, result_path, display_name, result_type,
                                        left_entry_id, right_entry_id, difference_flags, created_at)
        VALUES (1, '', 'A', 'matched',
                (SELECT id FROM entries WHERE snapshot_id = 1 AND parent_id IS NULL),
                (SELECT id FROM entries WHERE snapshot_id = 2 AND parent_id IS NULL), 0, CURRENT_TIMESTAMP);
        """)
    }

    private func seedVersion4Snapshot(at url: URL) throws {
        try CatalogSchemaFixture.createDatabase(at: url, sql: """
        INSERT INTO volumes (id, display_name, first_seen_at, last_seen_at, created_at, updated_at)
        VALUES (1, 'Legacy Volume', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
        INSERT INTO snapshots (
            volume_id, session_number, scan_root_name, status, scanner_version, schema_version,
            normalization_version, display_name, capture_policy_json, started_at, created_at, updated_at
        ) VALUES (1, 1, 'Legacy', 'scanning', 'fsd-scanner-m2', 4,
                  'fsd-normalizer-v1_app-1.0_os-1', 'Legacy capture', '{}',
                  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
        INSERT INTO entries (
            snapshot_id, parent_id, relative_path, case_preserving_path, case_folded_path,
            name, case_preserving_name, case_folded_name, item_type, sort_key, created_at
        ) VALUES (1, NULL, '', '', '', 'Legacy', 'Legacy', 'legacy', 'directory', '0', CURRENT_TIMESTAMP);
        UPDATE snapshots SET status = 'complete', completed_at = CURRENT_TIMESTAMP WHERE id = 1;
        """)
    }

    private func makeCompletedSnapshot(in database: CatalogDatabase) throws -> Int64 {
        let repository = SnapshotRepository(database: database)
        let volumeID = Int64.random(in: 1000...9999)
        try repository.createVolume(id: volumeID, displayName: "Rules Volume")
        let snapshot = try repository.createSnapshot(volumeID: volumeID, sessionNumber: 1, scanRootName: "Rules")
        _ = try repository.addRoot(to: snapshot, name: "Rules")
        try repository.complete(snapshot)
        return snapshot.rawValue
    }

    private func insertEntry(into database: CatalogDatabase, snapshotID: Int64, path: String) throws {
        try database.execute(
            """
            INSERT INTO entries (
                snapshot_id, parent_id, relative_path, case_preserving_path, case_folded_path,
                name, case_preserving_name, case_folded_name, item_type, sort_key, created_at
            ) VALUES (?, (SELECT id FROM entries WHERE snapshot_id = ? AND relative_path = ''),
                      ?, ?, ?, ?, ?, ?, 'file', ?, CURRENT_TIMESTAMP)
            """,
            bindings: [
                .integer(snapshotID), .integer(snapshotID), .text(path), .text(path), .text(path),
                .text(path), .text(path), .text(path), .text(path)
            ]
        )
    }

    private func triggerCount(_ database: CatalogDatabase, name: String) throws -> Int64 {
        try database.scalar(
            "SELECT COUNT(*) FROM sqlite_master WHERE type = 'trigger' AND name = ?",
            bindings: [.text(name)]
        )?.int64Value ?? -1
    }

    private func guardTriggerCount(at url: URL) throws -> Int64 {
        try rawScalarInt(
            at: url,
            "SELECT COUNT(*) FROM sqlite_master WHERE type = 'trigger' AND name LIKE 'trg_completed_%'"
        )
    }

    private func objectNames(_ database: CatalogDatabase, type: String) throws -> [String] {
        try database.query(
            "SELECT name FROM sqlite_master WHERE type = ? AND name NOT LIKE 'sqlite_%' ORDER BY name",
            bindings: [.text(type)]
        ).compactMap { $0["name"]?.stringValue }
    }

    private func snapshotColumnNames(_ database: CatalogDatabase) throws -> [String] {
        try tableColumnNames(database, table: "snapshots")
    }

    private func tableColumnNames(_ database: CatalogDatabase, table: String) throws -> [String] {
        try database.query("SELECT name FROM pragma_table_info('\(table)') ORDER BY name")
            .compactMap { $0["name"]?.stringValue }
    }

    /// Reads a value without going through `CatalogDatabase`, so a database that
    /// `CatalogDatabase` refuses to open can still be inspected.
    private func rawScalarInt(at url: URL, _ sql: String) throws -> Int64 {
        var handle: OpaquePointer?
        guard url.path.withCString({ sqlite3_open_v2($0, &handle, SQLITE_OPEN_READONLY, nil) }) == SQLITE_OK,
              let handle else {
            throw NSError(domain: "SchemaMigrationTests", code: 1)
        }
        defer { sqlite3_close(handle) }
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw NSError(domain: "SchemaMigrationTests", code: 2)
        }
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_ROW else { return -1 }
        return sqlite3_column_int64(statement, 0)
    }
}
