import SQLite3
import XCTest
@testable import FSD

/// Generated populated historical catalogs only. Never resolves Owner locations.
final class CompletionReceiptMigrationTests: XCTestCase {
    private var directory: URL!
    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("FSD-task061-migrations-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: directory) }
    private func fixture(_ name: String) throws -> URL {
        let url = directory.appendingPathComponent(name + ".sqlite")
        try CatalogSchemaFixture.createDatabase(at: url, sql: CatalogSchemaFixture.version11SQL() + "\n" + Self.legacyFacts)
        return url
    }
    private func raw(_ url: URL, _ sql: String) throws -> [String] {
        var handle: OpaquePointer?
        guard sqlite3_open_v2(url.path,&handle,SQLITE_OPEN_READONLY,nil) == SQLITE_OK, let handle else { throw DriveSetError.notFound }
        defer { sqlite3_close(handle) }
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle,sql,-1,&statement,nil) == SQLITE_OK, let statement else { throw DriveSetError.corruptRecord }
        defer { sqlite3_finalize(statement) }
        var result: [String] = []
        while true {
            let status = sqlite3_step(statement)
            if status == SQLITE_DONE { return result }
            guard status == SQLITE_ROW else { throw DriveSetError.corruptRecord }
            result.append((0..<sqlite3_column_count(statement)).map { sqlite3_column_text(statement,$0).map { String(cString:$0) } ?? "<NULL>" }.joined(separator:"|"))
        }
    }
    private func legacy(_ url: URL) throws -> [String:[String]] {
        var result: [String:[String]] = [:]
        for table in CatalogMigrations.ExpectedState.tables where table != "schema_migrations" && !CatalogMigrations.receiptTableDefinitions.map(\.name).contains(table) {
            result[table] = try raw(url,"SELECT * FROM \(table) ORDER BY rowid")
        }
        return result
    }
    private func schema(_ url: URL) throws -> [String] { try raw(url,"SELECT type,name,sql FROM sqlite_master ORDER BY type,name") }
    func testPopulatedV11MigrationInventsNoReceiptAndPreservesEveryEvidenceRow() throws {
        let url = try fixture("populated")
        let before = try legacy(url)
        let db = try CatalogDatabase(url: url); defer { db.close() }
        XCTAssertEqual(try db.schemaVersion,12)
        XCTAssertEqual(try legacy(url),before)
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM comparison_completion_receipts")?.int64Value,0)
        let receipts = ComparisonCompletionReceiptRepository(database:db)
        XCTAssertFalse(try receipts.isEligibleForExactSave(comparisonID:ComparisonID(rawValue:1)))
        // Old mutable names/issues cannot create a trustworthy missing receipt.
        try db.execute("UPDATE comparison_profiles SET name='later registry' WHERE id=1")
        XCTAssertNil(try receipts.receipt(comparisonID:ComparisonID(rawValue:1)))
        XCTAssertThrowsError(try db.execute("UPDATE comparisons SET status='complete' WHERE id=1"))
        XCTAssertThrowsError(try db.execute("UPDATE snapshots SET mount_path_at_capture='changed' WHERE id=1"))
        XCTAssertThrowsError(try db.execute("UPDATE entries SET name='changed' WHERE id=11"))
        XCTAssertThrowsError(try db.execute("UPDATE comparison_results SET display_name='changed'"))
        XCTAssertThrowsError(try db.execute("DELETE FROM identity_evidence"))
        XCTAssertEqual(try db.scalar("PRAGMA foreign_keys")?.int64Value,1)
        XCTAssertEqual(try db.scalar("PRAGMA integrity_check")?.stringValue,"ok")
        XCTAssertTrue(try db.query("PRAGMA foreign_key_check").isEmpty)
    }
    func testFreshAndEverySupportedUpgradeConvergeExactly() throws {
        let fresh = try CatalogDatabase(url:directory.appendingPathComponent("fresh.sqlite"),schemaURL:CatalogSchemaFixture.canonicalSchemaURL)
        defer { fresh.close() }
        let fixtures = try [CatalogSchemaFixture.version4SQL(withImmutabilityGuards:false),CatalogSchemaFixture.version4SQL(withImmutabilityGuards:true),CatalogSchemaFixture.version5SQL(),CatalogSchemaFixture.version6SQL(),CatalogSchemaFixture.version7SQL(),CatalogSchemaFixture.version8SQL(),CatalogSchemaFixture.version9SQL(),CatalogSchemaFixture.version10SQL(),CatalogSchemaFixture.version11SQL()]
        for (i,sql) in fixtures.enumerated() {
            let url = directory.appendingPathComponent("chain-\(i).sqlite")
            try CatalogSchemaFixture.createDatabase(at:url,sql:sql)
            let migrated = try CatalogDatabase(url:url); defer { migrated.close() }
            XCTAssertEqual(try migrated.schemaVersion,12)
            for type in ["table","index","trigger"] {
                let query = "SELECT name,sql FROM sqlite_master WHERE type=? AND name NOT LIKE 'sqlite_%' ORDER BY name"
                let a = try fresh.query(query,bindings:[.text(type)]); let b = try migrated.query(query,bindings:[.text(type)])
                XCTAssertEqual(a.map { $0["name"] },b.map { $0["name"] })
                if type != "table" { XCTAssertEqual(a.compactMap { $0["sql"]?.stringValue }.map(CatalogMigrations.ExpectedState.normalizedObjectSQL),b.compactMap { $0["sql"]?.stringValue }.map(CatalogMigrations.ExpectedState.normalizedObjectSQL)) }
            }
            for table in CatalogMigrations.ExpectedState.tables {
                let columns = "SELECT name,type,\"notnull\",dflt_value,pk FROM pragma_table_info('\(table)') ORDER BY name"
                XCTAssertEqual(try fresh.query(columns),try migrated.query(columns),table)
            }
            for table in CatalogMigrations.receiptTableDefinitions {
                let query = "SELECT sql FROM sqlite_master WHERE name=?"
                XCTAssertEqual(try fresh.scalar(query,bindings:[.text(table.name)])?.stringValue.map(CatalogMigrations.ExpectedState.normalizedObjectSQL),try migrated.scalar(query,bindings:[.text(table.name)])?.stringValue.map(CatalogMigrations.ExpectedState.normalizedObjectSQL))
            }
            XCTAssertTrue(try migrated.query("PRAGMA foreign_key_check").isEmpty)
            XCTAssertEqual(try migrated.scalar("PRAGMA integrity_check")?.stringValue,"ok")
        }
    }
    func testEveryDDLAndVersionWriteFailureRollBackThenReopenIdempotently() throws {
        let ddl = CatalogMigrations.migrationToVersion12.statements
        for i in 0...ddl.count {
            let url = try fixture("rollback-\(i)")
            let before = try legacy(url); let originalSchema = try schema(url)
            if i == ddl.count { try CatalogSchemaFixture.createDatabase(at:url,sql:"CREATE TRIGGER synthetic_version_failure BEFORE INSERT ON schema_migrations WHEN NEW.version=12 BEGIN SELECT RAISE(ABORT,'synthetic'); END;") }
            var statements = ddl
            if i < ddl.count { statements.insert("CREATE TABLE invalid(",at:i) }
            XCTAssertThrowsError(try CatalogDatabase(url:url,migrations:[SchemaMigration(version:12,statements:statements)])) { error in
                guard case CatalogDatabaseError.migrationFailed(12,_) = error else { return XCTFail("\(error)") }
            }
            XCTAssertEqual(try raw(url,"SELECT MAX(version) FROM schema_migrations"),["11"])
            XCTAssertEqual(try legacy(url),before)
            if i == ddl.count { try CatalogSchemaFixture.createDatabase(at:url,sql:"DROP TRIGGER synthetic_version_failure") }
            XCTAssertEqual(try schema(url),originalSchema)
            let migrated = try CatalogDatabase(url:url); migrated.close()
            let after = try raw(url,"SELECT * FROM schema_migrations ORDER BY version")
            let reopened = try CatalogDatabase(url:url,migrations:[SchemaMigration(version:12,statements:["CREATE TABLE invalid("])])
            XCTAssertEqual(try reopened.schemaVersion,12); reopened.close()
            XCTAssertEqual(try raw(url,"SELECT * FROM schema_migrations ORDER BY version"),after)
            XCTAssertEqual(try legacy(url),before)
        }
    }
    func testIncompleteOrAlteredDDLIsRejectedBeforeVersionWrite() throws {
        for altered in [false,true] {
            let url = try fixture("inventory-\(altered)")
            let before = try schema(url)
            var statements = CatalogMigrations.migrationToVersion12.statements
            if altered { statements.append("ALTER TABLE comparison_completion_receipts ADD COLUMN fabricated TEXT") } else { statements.removeLast() }
            XCTAssertThrowsError(try CatalogDatabase(url:url,migrations:[SchemaMigration(version:12,statements:statements)]))
            XCTAssertEqual(try schema(url),before)
            XCTAssertEqual(try raw(url,"SELECT MAX(version) FROM schema_migrations"),["11"])
        }
    }
    func testNewerVersionRejectedWithoutWritingBytes() throws {
        let url = try fixture("future")
        try CatalogSchemaFixture.createDatabase(at:url,sql:"INSERT INTO schema_migrations VALUES (999,'future')")
        let before = try Data(contentsOf:url)
        XCTAssertThrowsError(try CatalogDatabase(url:url)) { XCTAssertEqual($0 as? CatalogDatabaseError,.unsupportedSchemaVersion(999)) }
        XCTAssertEqual(try Data(contentsOf:url),before)
    }
    func testDamagedNewObjectFailsStartupClosed() throws {
        for (i,sql) in ["ALTER TABLE comparison_completion_receipts ADD COLUMN invalid TEXT","DROP INDEX idx_comparison_results_receipt","DROP TRIGGER trg_receipts_no_update","DROP TRIGGER trg_receipts_no_delete"].enumerated() {
            let url = directory.appendingPathComponent("damaged-\(i).sqlite")
            let db = try CatalogDatabase(url:url,schemaURL:CatalogSchemaFixture.canonicalSchemaURL)
            try db.execute(sql); db.close()
            let before = try schema(url)
            let versions = try raw(url,"SELECT * FROM schema_migrations ORDER BY version")
            XCTAssertThrowsError(try CatalogDatabase(url:url))
            XCTAssertEqual(try schema(url),before)
            XCTAssertEqual(try raw(url,"SELECT * FROM schema_migrations ORDER BY version"),versions)
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
        INSERT INTO drive_sets(id,name,normalized_name,normalization_version,revision,created_at,updated_at) VALUES ('00000000-0000-0000-0000-000000000009','Synthetic','synthetic','fsd-drive-set-name-v1',1,'then','then');
        INSERT INTO physical_drives(id,label,admission,provenance,created_at,updated_at) VALUES ('00000000-0000-0000-0000-000000000001','same','explicit_local','synthetic','then','then');
        INSERT INTO identity_observations(id,session_id,revision,scope,state,provenance,observed_at) VALUES ('00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000003',1,'volume','unknown','synthetic','then');
        INSERT INTO identity_evidence(id,observation_id,observation_revision,scope,kind,provider,property,dependency_group,value,validation,provenance,observed_at) VALUES ('00000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000002',1,'volume','displayName','synthetic','generated-label','displayName','same','unverified','synthetic','then');
        INSERT INTO drive_set_memberships(set_id,physical_drive_id,added_at,admission) VALUES ('00000000-0000-0000-0000-000000000009','00000000-0000-0000-0000-000000000001','then','explicit_local_selection');
        INSERT INTO manual_drive_associations(id,observation_id,observation_revision,revision,target_drive_id,target_revision,action,actor,reason,created_at) VALUES ('00000000-0000-0000-0000-000000000005','00000000-0000-0000-0000-000000000002',1,1,'00000000-0000-0000-0000-000000000001',1,'associate','synthetic user','generated manual choice','then');
        INSERT INTO manual_drive_associations(id,observation_id,observation_revision,revision,previous_event_id,action,actor,reason,created_at) VALUES ('00000000-0000-0000-0000-000000000006','00000000-0000-0000-0000-000000000002',1,2,'00000000-0000-0000-0000-000000000005','revoke','synthetic user','generated revocation','then');
        """
}
