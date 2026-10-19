import XCTest
import SQLite3
@testable import FSD

/// Every catalog and source fact here is synthetic, isolated and disposable.
final class PhysicalDriveMigrationTests: XCTestCase {
    private var directory: URL!
    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("FSD-task058-migrations-\(UUID())")
        try FileManager.default.createDirectory(at: directory,withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: directory) }
    private func v9(_ name: String) throws -> URL {
        let url = directory.appendingPathComponent(name + ".sqlite")
        try CatalogSchemaFixture.createDatabase(at: url,sql: CatalogSchemaFixture.version9SQL())
        return url
    }
    private func raw(_ url: URL, _ sql: String) throws -> [String] {
        var handle: OpaquePointer?
        guard sqlite3_open_v2(url.path,&handle,SQLITE_OPEN_READONLY,nil) == SQLITE_OK, let handle else { throw PhysicalDriveIdentityError.notFound }
        defer { sqlite3_close(handle) }
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle,sql,-1,&statement,nil) == SQLITE_OK,let statement else { throw PhysicalDriveIdentityError.invalidInput }
        defer { sqlite3_finalize(statement) }
        var output: [String] = []
        while true {
            let result = sqlite3_step(statement)
            if result == SQLITE_DONE { return output }
            guard result == SQLITE_ROW else { throw PhysicalDriveIdentityError.corruptRecord }
            output.append((0..<sqlite3_column_count(statement)).map { i in
                sqlite3_column_text(statement,i).map { String(cString: $0) } ?? "<NULL>"
            }.joined(separator: "|"))
        }
    }
    private func schema(_ db: CatalogDatabase, type: String) throws -> [DatabaseRow] {
        try db.query("SELECT name,sql FROM sqlite_master WHERE type=? AND name NOT LIKE 'sqlite_%' ORDER BY name",bindings: [.text(type)])
    }
    func testV9MigrationPreservesEveryLegacyRowAndInventsNoIdentity() throws {
        let url = try v9("legacy")
        try CatalogSchemaFixture.createDatabase(at: url,sql: Self.legacyFacts)
        let legacyTables = CatalogMigrations.ExpectedState.tables.filter { !(CatalogMigrations.identityTableDefinitions + CatalogMigrations.driveSetTableDefinitions + CatalogMigrations.receiptTableDefinitions + CatalogMigrations.savedTableDefinitions).map(\.name).contains($0) && $0 != "schema_migrations" }
        var before: [String: [String]] = [:]
        for table in legacyTables { before[table] = try raw(url,"SELECT * FROM \(table) ORDER BY rowid") }
        let db = try CatalogDatabase(url: url)
        defer { db.close() }
        XCTAssertEqual(try db.schemaVersion,CatalogDatabase.currentSchemaVersion)
        for table in CatalogMigrations.identityTableDefinitions {
            XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM \(table.name)")?.int64Value,0)
        }
        for table in legacyTables { XCTAssertEqual(try raw(url,"SELECT * FROM \(table) ORDER BY rowid"),before[table],table) }
        let repo = PhysicalDriveRepository(database: db)
        let drive = try repo.createDrive(provenance: "synthetic manual record")
        let o = try repo.recordObservation(sessionID: UUID(),revision: 1,scope: .volume,provenance: "synthetic",observedAt: Date())
        let first = try repo.setManualAssociation(operationID: UUID(),observationID: o.id,expectedObservationRevision: 1,
            expectedAssociationRevision: 0,target: drive.id,expectedTargetRevision: 1,action: .associate,actor: "user",reason: "synthetic")
        _ = try repo.setManualAssociation(operationID: UUID(),observationID: o.id,expectedObservationRevision: 1,
            expectedAssociationRevision: first.revision,target: nil,expectedTargetRevision: nil,action: .revoke,actor: "user",reason: "correction")
        _ = try repo.retireDrive(id: drive.id,expectedRevision: 1)
        XCTAssertThrowsError(try db.execute("DELETE FROM physical_drives"))
        for table in legacyTables { XCTAssertEqual(try raw(url,"SELECT * FROM \(table) ORDER BY rowid"),before[table],table) }
        XCTAssertThrowsError(try db.execute("UPDATE snapshots SET mount_path_at_capture='changed' WHERE id=1"))
        XCTAssertThrowsError(try db.execute("UPDATE entries SET name='changed' WHERE id=11"))
        XCTAssertThrowsError(try db.execute("UPDATE comparison_results SET display_name='changed'"))
        XCTAssertEqual(try db.scalar("PRAGMA integrity_check")?.stringValue,"ok")
        XCTAssertTrue(try db.query("PRAGMA foreign_key_check").isEmpty)
    }
    func testFreshAndAllSupportedMigratedSchemasConverge() throws {
        let fresh = try CatalogDatabase(url: directory.appendingPathComponent("fresh.sqlite"),schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        defer { fresh.close() }
        let fixtures = try [CatalogSchemaFixture.version4SQL(withImmutabilityGuards: false),CatalogSchemaFixture.version4SQL(withImmutabilityGuards: true),
            CatalogSchemaFixture.version5SQL(),CatalogSchemaFixture.version6SQL(),CatalogSchemaFixture.version7SQL(),
            CatalogSchemaFixture.version8SQL(),CatalogSchemaFixture.version9SQL()]
        for (number,sql) in fixtures.enumerated() {
            let url = directory.appendingPathComponent("chain-\(number).sqlite")
            try CatalogSchemaFixture.createDatabase(at: url,sql: sql)
            let migrated = try CatalogDatabase(url: url)
            XCTAssertEqual(try migrated.schemaVersion,CatalogDatabase.currentSchemaVersion)
            for type in ["table","trigger","index"] {
                let a = try schema(fresh,type: type); let b = try schema(migrated,type: type)
                XCTAssertEqual(a.map { $0["name"] },b.map { $0["name"] })
                // Existing ALTER TABLE migrations change physical column order;
                // new tables must match exact DDL and all legacy columns match by name.
                for table in CatalogMigrations.identityTableDefinitions {
                    XCTAssertEqual(try migrated.scalar("SELECT sql FROM sqlite_master WHERE name=?",bindings: [.text(table.name)]).map { $0.stringValue.map(CatalogMigrations.ExpectedState.normalizedObjectSQL) },
                        try fresh.scalar("SELECT sql FROM sqlite_master WHERE name=?",bindings: [.text(table.name)]).map { $0.stringValue.map(CatalogMigrations.ExpectedState.normalizedObjectSQL) })
                }
                if type != "table" {
                    XCTAssertEqual(a.compactMap { $0["sql"]?.stringValue }.map(CatalogMigrations.ExpectedState.normalizedObjectSQL),
                        b.compactMap { $0["sql"]?.stringValue }.map(CatalogMigrations.ExpectedState.normalizedObjectSQL))
                }
            }
            for table in CatalogMigrations.ExpectedState.tables {
                let query = "SELECT name,type,\"notnull\",dflt_value,pk FROM pragma_table_info('\(table)') ORDER BY name"
                XCTAssertEqual(try fresh.query(query),try migrated.query(query),table)
            }
            XCTAssertTrue(try migrated.query("PRAGMA foreign_key_check").isEmpty)
            XCTAssertEqual(try migrated.scalar("PRAGMA integrity_check")?.stringValue,"ok")
            migrated.close()
        }
    }
    func testEveryDDLBoundaryAndVersionWriteFailureRollBackThenReopen() throws {
        let statements = CatalogMigrations.migrationToVersion10.statements
        for boundary in 0...statements.count {
            let url = try v9("rollback-\(boundary)")
            try CatalogSchemaFixture.createDatabase(at: url,sql: Self.legacyFacts)
            let originalSchema = try raw(url,"SELECT type,name,sql FROM sqlite_master ORDER BY type,name")
            if boundary == statements.count {
                try CatalogSchemaFixture.createDatabase(at: url,sql: "CREATE TRIGGER fixture_version_failure BEFORE INSERT ON schema_migrations WHEN NEW.version=10 BEGIN SELECT RAISE(ABORT,'version-write failure'); END;")
            }
            var injected = statements
            if boundary < statements.count { injected.insert("CREATE TABLE invalid(",at: boundary) }
            XCTAssertThrowsError(try CatalogDatabase(url: url,migrations: [SchemaMigration(version: 10,statements: injected)])) { error in
                guard case CatalogDatabaseError.migrationFailed(10,_) = error else { return XCTFail("\(error)") }
            }
            XCTAssertEqual(try raw(url,"SELECT MAX(version) FROM schema_migrations"),["9"])
            XCTAssertEqual(try raw(url,"SELECT COUNT(*) FROM snapshots"),["2"])
            XCTAssertEqual(try raw(url,"SELECT COUNT(*) FROM comparison_results"),["1"])
            if boundary == statements.count { try CatalogSchemaFixture.createDatabase(at: url,sql: "DROP TRIGGER fixture_version_failure;") }
            XCTAssertEqual(try raw(url,"SELECT type,name,sql FROM sqlite_master ORDER BY type,name"),originalSchema)
            let repaired = try CatalogDatabase(url: url)
            XCTAssertEqual(try repaired.schemaVersion,CatalogDatabase.currentSchemaVersion)
            XCTAssertEqual(try repaired.scalar("PRAGMA integrity_check")?.stringValue,"ok")
            XCTAssertTrue(try repaired.query("PRAGMA foreign_key_check").isEmpty)
            repaired.close()
            let after = try raw(url,"SELECT version,applied_at FROM schema_migrations ORDER BY version")
            let reopened = try CatalogDatabase(url: url,migrations: [SchemaMigration(version: 10,statements: ["CREATE TABLE invalid("])])
            XCTAssertEqual(try reopened.schemaVersion,CatalogDatabase.currentSchemaVersion)
            reopened.close()
            XCTAssertEqual(try raw(url,"SELECT version,applied_at FROM schema_migrations ORDER BY version"),after)
        }
    }
    func testSuccessfulButIncompleteOrAlteredDDLDoesNotCommitVersionTen() throws {
        for altered in [false,true] {
            let url = try v9("invalid-inventory-\(altered)")
            let before = try raw(url,"SELECT type,name,sql FROM sqlite_master ORDER BY type,name")
            var statements = CatalogMigrations.migrationToVersion10.statements
            if altered {
                statements.append("ALTER TABLE physical_drives ADD COLUMN fabricated TEXT")
            } else {
                statements.removeLast()
            }
            XCTAssertThrowsError(try CatalogDatabase(url: url,migrations: [SchemaMigration(version: 10,statements: statements)])) { error in
                guard case CatalogDatabaseError.migrationFailed(10,_) = error else { return XCTFail("\(error)") }
            }
            XCTAssertEqual(try raw(url,"SELECT MAX(version) FROM schema_migrations"),["9"])
            XCTAssertEqual(try raw(url,"SELECT type,name,sql FROM sqlite_master ORDER BY type,name"),before)
            let reopened = try CatalogDatabase(url: url); defer { reopened.close() }
            XCTAssertEqual(try reopened.schemaVersion,CatalogDatabase.currentSchemaVersion)
        }
    }

    func testVersionTenRecordedOnlyAfterAllObjectsExist() throws {
        let url = try v9("version-last")
        try CatalogSchemaFixture.createDatabase(at: url,sql: """
            CREATE TRIGGER fixture_version_last BEFORE INSERT ON schema_migrations WHEN NEW.version=10 BEGIN
            SELECT CASE WHEN (SELECT MAX(version) FROM schema_migrations) != 9
                OR (SELECT COUNT(*) FROM sqlite_master WHERE name='trg_manual_associations_admission') != 1
                THEN RAISE(ABORT,'version before DDL') END; END;
            """)
        let db = try CatalogDatabase(url: url); defer { db.close() }
        XCTAssertEqual(try db.schemaVersion,CatalogDatabase.currentSchemaVersion)
    }
    func testNewerVersionRejectedWithoutCatalogMutation() throws {
        let url = try v9("future")
        try CatalogSchemaFixture.createDatabase(at: url,sql: "INSERT INTO schema_migrations VALUES (999,'future');")
        let before = try raw(url,"SELECT type,name,sql FROM sqlite_master ORDER BY type,name")
        XCTAssertThrowsError(try CatalogDatabase(url: url)) { error in
            XCTAssertEqual(error as? CatalogDatabaseError,.unsupportedSchemaVersion(999))
        }
        XCTAssertEqual(try raw(url,"SELECT type,name,sql FROM sqlite_master ORDER BY type,name"),before)
        XCTAssertEqual(try raw(url,"SELECT MAX(version) FROM schema_migrations"),["999"])
    }
    func testUnsupportedCatalogDoesNotChangePersistentJournalModeOrBytes() throws {
        for version in [2,999] {
            let url = directory.appendingPathComponent("unsupported-bytes-\(version).sqlite")
            try CatalogSchemaFixture.createDatabase(at: url,sql: "CREATE TABLE schema_migrations(version INTEGER PRIMARY KEY,applied_at TEXT); INSERT INTO schema_migrations VALUES (\(version),'synthetic');")
            let before = try Data(contentsOf: url)
            XCTAssertThrowsError(try CatalogDatabase(url: url)) { error in
                XCTAssertEqual(error as? CatalogDatabaseError,.unsupportedSchemaVersion(Int64(version)))
            }
            XCTAssertEqual(try Data(contentsOf: url),before,"Unsupported catalogs must not switch from DELETE to WAL")
            XCTAssertEqual(try raw(url,"PRAGMA journal_mode"),["delete"])
        }
    }

    func testDamagedNewTableOrIndexOrTriggerRejectedOnStartup() throws {
        for kind in ["table","index","trigger"] {
            let url = directory.appendingPathComponent("damaged-\(kind).sqlite")
            let db = try CatalogDatabase(url: url,schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
            let sql: String
            switch kind {
            case "table": sql = "ALTER TABLE identity_evidence ADD COLUMN fabricated TEXT"
            case "index": sql = "DROP INDEX idx_identity_evidence_observation"
            default: sql = "DROP TRIGGER trg_physical_drives_no_delete"
            }
            try db.execute(sql); db.close()
            XCTAssertThrowsError(try CatalogDatabase(url: url)) { error in
                guard case CatalogDatabaseError.schemaStateInvalid = error else { return XCTFail("\(error)") }
            }
        }
    }
    private static let legacyFacts = """
        INSERT INTO collections(id,name,normalized_name,created_at,updated_at) VALUES (1,'Synthetic','synthetic','then','then');
        INSERT INTO volumes (id,display_name,persistent_uuid,first_seen_at,last_seen_at,created_at,updated_at)
        VALUES (1,'same','duplicate','then','then','then','then'),(2,'same','duplicate','then','then','then','then');
        INSERT INTO source_collection_defaults(source_kind,volume_id,collection_id,created_at,updated_at) VALUES ('volume',1,1,'then','then');
        INSERT INTO snapshots(id,volume_id,session_number,scan_root_name,status,scanner_version,schema_version,normalization_version,
            display_name,capture_policy_json,started_at,created_at,updated_at,collection_id,mount_path_at_capture,volume_display_name_at_capture)
        VALUES (1,1,1,'A','scanning','synthetic',9,'fsd-normalizer-v1_app-1.0_os-1','A','{}','then','then','then',1,'/synthetic/reused','old label'),
               (2,2,1,'B','scanning','synthetic',9,'fsd-normalizer-v1_app-1.0_os-1','B','{}','then','then','then',NULL,'/synthetic/reused',NULL);
        INSERT INTO entries(id,snapshot_id,parent_id,relative_path,case_preserving_path,case_folded_path,name,case_preserving_name,case_folded_name,item_type,sort_key,created_at)
        VALUES (11,1,NULL,'','','','A','A','a','directory','0','then'),(12,2,NULL,'','','','B','B','b','directory','0','then');
        INSERT INTO scan_issues(snapshot_id,relative_path,severity,source,message,was_skipped,created_at)
        VALUES (1,'','warning','scanner','synthetic',0,'then');
        INSERT INTO entry_classifications(entry_id,classification_run_id,created_at) VALUES (11,'synthetic','then');
        UPDATE snapshots SET status='complete',completed_at='then';
        INSERT INTO comparisons(id,left_snapshot_id,right_snapshot_id,profile_id,profile_version,status,matched_count,started_at,created_at)
        VALUES (1,1,2,1,1,'running',1,'then','then');
        INSERT INTO comparison_results(comparison_id,result_path,display_name,result_type,left_entry_id,right_entry_id,difference_flags,created_at)
        VALUES (1,'','A','matched',11,12,0,'then');
        INSERT INTO comparison_collision_groups(id,comparison_id,result_path,created_at) VALUES (1,1,'/synthetic/collision','then');
        INSERT INTO comparison_collision_members(id,group_id,side,entry_id,created_at) VALUES (1,1,'left',11,'then'),(2,1,'right',12,'then');
        UPDATE comparisons SET status='complete',completed_at='then';
        """
}
