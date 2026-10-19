import XCTest
import SQLite3
@testable import FSD

final class SavedComparisonMigrationTests: XCTestCase {
    private var directory: URL!
    override func setUpWithError() throws {
        directory=FileManager.default.temporaryDirectory.appendingPathComponent("FSD-task062-migration-\(UUID())")
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
    }
    override func tearDownWithError() throws { try? FileManager.default.removeItem(at:directory) }
    private func fixture(_ name: String) throws -> URL {
        let url=directory.appendingPathComponent(name+".sqlite")
        let sql=try CatalogSchemaFixture.version11SQL()+"\n"+CompletionReceiptMigrationTests.legacyFacts+"\n"+CatalogMigrations.migrationToVersion12.statements.joined(separator:"\n")+"\nINSERT INTO schema_migrations VALUES(12,'then');"
        try CatalogSchemaFixture.createDatabase(at:url,sql:sql)
        return url
    }
    private func raw(_ url: URL, _ query: String) throws -> [String] {
        var handle: OpaquePointer?; guard sqlite3_open_v2(url.path,&handle,SQLITE_OPEN_READONLY,nil)==SQLITE_OK,let handle else { throw SavedComparisonError.notFound }; defer { sqlite3_close(handle) }
        var stmt: OpaquePointer?; guard sqlite3_prepare_v2(handle,query,-1,&stmt,nil)==SQLITE_OK,let stmt else { throw SavedComparisonError.corrupt(query) }; defer { sqlite3_finalize(stmt) }
        var rows:[String]=[]
        while true { let status=sqlite3_step(stmt); if status==SQLITE_DONE { return rows }; guard status==SQLITE_ROW else { throw SavedComparisonError.corrupt(query) }; rows.append((0..<sqlite3_column_count(stmt)).map { i in sqlite3_column_text(stmt,i).map { String(cString:$0) } ?? "<NULL>" }.joined(separator:"|")) }
    }
    private func inventory(_ url: URL) throws -> [String] { try raw(url,"SELECT type,name,sql FROM sqlite_master ORDER BY type,name") }
    private func legacy(_ url: URL) throws -> [String:[String]] {
        var result:[String:[String]]=[:]
        for table in CatalogMigrations.ExpectedState.tables where !table.hasPrefix("saved_") && table != "schema_migrations" {
            let columns=try raw(url,"SELECT name FROM pragma_table_info('\(table)') ORDER BY cid")
            result[table]=try raw(url,"SELECT "+columns.map { "typeof(\($0))||':'||hex(CAST(\($0) AS BLOB))" }.joined(separator:",")+" FROM \(table) ORDER BY rowid")
        }
        return result
    }
    func testFreshAndBothV4VariantsThroughV12HaveExactMigrationParity() throws {
        let fresh=try CatalogDatabase(url:directory.appendingPathComponent("fresh.sqlite"),schemaURL:CatalogSchemaFixture.canonicalSchemaURL); defer { fresh.close() }
        let fixtures=try [CatalogSchemaFixture.version4SQL(withImmutabilityGuards:false),CatalogSchemaFixture.version4SQL(withImmutabilityGuards:true),CatalogSchemaFixture.version5SQL(),CatalogSchemaFixture.version6SQL(),CatalogSchemaFixture.version7SQL(),CatalogSchemaFixture.version8SQL(),CatalogSchemaFixture.version9SQL(),CatalogSchemaFixture.version10SQL(),CatalogSchemaFixture.version11SQL(),CatalogSchemaFixture.version12SQL()]
        for (i,sql) in fixtures.enumerated() {
            let url=directory.appendingPathComponent("chain-\(i).sqlite"); try CatalogSchemaFixture.createDatabase(at:url,sql:sql)
            let migrated=try CatalogDatabase(url:url); XCTAssertEqual(try migrated.schemaVersion,13)
            for type in ["table","index","trigger"] {
                let q="SELECT name,sql FROM sqlite_master WHERE type=? AND name NOT LIKE 'sqlite_%' ORDER BY name"
                let a=try fresh.query(q,bindings:[.text(type)]),b=try migrated.query(q,bindings:[.text(type)])
                XCTAssertEqual(a.map { $0["name"] },b.map { $0["name"] })
                if type != "table" { XCTAssertEqual(a.compactMap { $0["sql"]?.stringValue }.map(CatalogMigrations.ExpectedState.normalizedObjectSQL),b.compactMap { $0["sql"]?.stringValue }.map(CatalogMigrations.ExpectedState.normalizedObjectSQL)) }
            }
            for table in CatalogMigrations.ExpectedState.tables {
                XCTAssertEqual(try fresh.query("SELECT name,type,\"notnull\",dflt_value,pk FROM pragma_table_info('\(table)') ORDER BY name"),try migrated.query("SELECT name,type,\"notnull\",dflt_value,pk FROM pragma_table_info('\(table)') ORDER BY name"),table)
            }
            for item in CatalogMigrations.savedTableDefinitions {
                XCTAssertEqual(try fresh.scalar("SELECT sql FROM sqlite_master WHERE name=?",bindings:[.text(item.name)])?.stringValue.map(CatalogMigrations.ExpectedState.normalizedObjectSQL),try migrated.scalar("SELECT sql FROM sqlite_master WHERE name=?",bindings:[.text(item.name)])?.stringValue.map(CatalogMigrations.ExpectedState.normalizedObjectSQL))
            }
            XCTAssertTrue(try migrated.query("PRAGMA foreign_key_check").isEmpty); XCTAssertEqual(try migrated.scalar("PRAGMA integrity_check")?.stringValue,"ok"); migrated.close()
            let reopened=try CatalogDatabase(url:url); XCTAssertEqual(try reopened.schemaVersion,13); reopened.close()
        }
    }
    func testPopulatedV12PreservesEveryLegacyByteAndRejectsCompletedReceiptlessSave() throws {
        let url=try fixture("preserved"); let before=try legacy(url)
        let db=try CatalogDatabase(url:url); defer { db.close() }
        XCTAssertEqual(try legacy(url),before)
        XCTAssertEqual(try db.scalar("SELECT status FROM comparisons WHERE id=1")?.stringValue,"complete")
        XCTAssertNil(try ComparisonCompletionReceiptRepository(database:db).receipt(comparisonID:.init(rawValue:1)))
        // A genuine receipt from a separate generated comparison cannot confer
        // eligibility upon the old complete row even if its comparison ID agrees.
        let left=try SyntheticSnapshot.createSnapshot(database:db,volumeID:1,session:2)
        let right=try SyntheticSnapshot.createSnapshot(database:db,volumeID:2,session:2)
        try SyntheticSnapshot.insertEntries(database:db,snapshotID:left,entries:[SyntheticSnapshot.root(id:101)])
        try SyntheticSnapshot.insertEntries(database:db,snapshotID:right,entries:[SyntheticSnapshot.root(id:201)])
        try SyntheticSnapshot.complete(database:db,snapshotID:left); try SyntheticSnapshot.complete(database:db,snapshotID:right)
        let c=try ComparisonEngine(database:db).compare(leftSnapshotID:left,rightSnapshotID:right,profileID:1)
        let receipt=try XCTUnwrap(ComparisonCompletionReceiptRepository(database:db).receipt(comparisonID:c.id))
        var json=try XCTUnwrap(JSONSerialization.jsonObject(with:receipt.encoded()) as? [String:Any]); json["comparisonID"]=1
        let reused=try JSONDecoder().decode(ComparisonCompletionReceipt.self,from:JSONSerialization.data(withJSONObject:json))
        XCTAssertThrowsError(try SavedComparisonRepository(database:db).save(.init(operationID:UUID(),receipt:reused))) { XCTAssertEqual($0 as? SavedComparisonError,.ineligible) }
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM saved_operations")?.int64Value,0)
        XCTAssertTrue(try db.query("PRAGMA foreign_key_check").isEmpty); XCTAssertEqual(try db.scalar("PRAGMA integrity_check")?.stringValue,"ok")
    }
    func testEveryDDLAndVersionFailureRollsBackWithSafeProductionReopen() throws {
        let ddl=CatalogMigrations.migrationToVersion13.statements
        for boundary in 0...ddl.count {
            let url=try fixture("rollback-\(boundary)"),before=try legacy(url),schema=try inventory(url)
            var statements=ddl
            if boundary<ddl.count { statements.insert("CREATE TABLE invalid(",at:boundary) }
            else { try CatalogSchemaFixture.createDatabase(at:url,sql:"CREATE TRIGGER synthetic_version BEFORE INSERT ON schema_migrations WHEN NEW.version=13 BEGIN SELECT RAISE(ABORT,'synthetic'); END;") }
            XCTAssertThrowsError(try CatalogDatabase(url:url,migrations:[SchemaMigration(version:13,statements:statements)])) { guard case CatalogDatabaseError.migrationFailed(13,_)=($0) else { return XCTFail("\($0)") } }
            XCTAssertEqual(try raw(url,"SELECT MAX(version) FROM schema_migrations"),["12"]); XCTAssertEqual(try legacy(url),before)
            if boundary==ddl.count { try CatalogSchemaFixture.createDatabase(at:url,sql:"DROP TRIGGER synthetic_version") }
            XCTAssertEqual(try inventory(url),schema)
            let migrated=try CatalogDatabase(url:url); XCTAssertEqual(try migrated.schemaVersion,13); migrated.close()
            let after=try raw(url,"SELECT * FROM schema_migrations ORDER BY version")
            let reopened=try CatalogDatabase(url:url,migrations:[SchemaMigration(version:13,statements:["CREATE TABLE invalid("])])
            XCTAssertEqual(try reopened.schemaVersion,13); XCTAssertTrue(try reopened.query("PRAGMA foreign_key_check").isEmpty); XCTAssertEqual(try reopened.scalar("PRAGMA integrity_check")?.stringValue,"ok"); reopened.close()
            XCTAssertEqual(try raw(url,"SELECT * FROM schema_migrations ORDER BY version"),after); XCTAssertEqual(try legacy(url),before)
        }
        print("TASK062_MIGRATION_ROLLBACK boundaries=\(ddl.count+1)")
    }

    func testActualProductionReceiptAndTerminalFactsSurviveV12Upgrade() throws {
        let url=directory.appendingPathComponent("receipt-v12.sqlite")
        let db=try CatalogDatabase(url:url,schemaURL:CatalogSchemaFixture.canonicalSchemaURL)
        let l=try SyntheticSnapshot.createSnapshot(database:db,volumeID:1,session:1),r=try SyntheticSnapshot.createSnapshot(database:db,volumeID:2,session:1)
        try SyntheticSnapshot.insertEntries(database:db,snapshotID:l,entries:[SyntheticSnapshot.root(id:11)])
        try SyntheticSnapshot.insertEntries(database:db,snapshotID:r,entries:[SyntheticSnapshot.root(id:12)])
        try SyntheticSnapshot.complete(database:db,snapshotID:l); try SyntheticSnapshot.complete(database:db,snapshotID:r)
        let c=try ComparisonEngine(database:db).compare(leftSnapshotID:l,rightSnapshotID:r,profileID:1)
        let receipt=try XCTUnwrap(ComparisonCompletionReceiptRepository(database:db).receipt(comparisonID:c.id)); db.close()
        // Reconstruct exact generated v12 by removing only empty additive v13
        // objects; receipt was made by unchanged production completion code.
        var sql=CatalogMigrations.savedTriggerDefinitions.map { "DROP TRIGGER \($0.name);" }.joined(separator:"\n")
        sql+="\n"+CatalogMigrations.savedTableDefinitions.reversed().map { "DROP TABLE \($0.name);" }.joined(separator:"\n")
        sql+="\nDELETE FROM schema_migrations WHERE version=13; INSERT INTO schema_migrations VALUES(12,'generated historical fixture');"
        try CatalogSchemaFixture.createDatabase(at:url,sql:sql)
        let before=try legacy(url)
        let migrated=try CatalogDatabase(url:url); defer { migrated.close() }
        XCTAssertEqual(try legacy(url),before)
        XCTAssertEqual(try ComparisonCompletionReceiptRepository(database:migrated).receipt(comparisonID:c.id),receipt)
        let repo=SavedComparisonRepository(database:migrated); let id=try repo.save(.init(operationID:UUID(),receipt:receipt))
        XCTAssertEqual(try repo.open(id:id).receipt,receipt)
    }

    func testIncompleteOrAlteredSchemaRollsBackAndDamagedReopenFailsClosed() throws {
        for altered in [false,true] {
            let url=try fixture("inventory-\(altered)"),before=try inventory(url)
            var statements=CatalogMigrations.migrationToVersion13.statements
            if altered { statements.append("ALTER TABLE saved_entries ADD COLUMN fabricated TEXT") } else { statements.removeLast() }
            XCTAssertThrowsError(try CatalogDatabase(url:url,migrations:[SchemaMigration(version:13,statements:statements)]))
            XCTAssertEqual(try inventory(url),before); XCTAssertEqual(try raw(url,"SELECT MAX(version) FROM schema_migrations"),["12"])
        }
        for (i,sql) in ["ALTER TABLE saved_entries ADD COLUMN fabricated TEXT","DROP INDEX idx_saved_results_parent","DROP TRIGGER trg_saved_operation_delete"].enumerated() {
            let url=directory.appendingPathComponent("damaged-\(i).sqlite"); let db=try CatalogDatabase(url:url,schemaURL:CatalogSchemaFixture.canonicalSchemaURL); try db.execute(sql); db.close()
            let before=try inventory(url); XCTAssertThrowsError(try CatalogDatabase(url:url)); XCTAssertEqual(try inventory(url),before)
        }
    }
}
