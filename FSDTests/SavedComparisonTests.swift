import XCTest
import Darwin
@testable import FSD

final class SavedComparisonTests: XCTestCase {
    private var directory: URL!
    private var db: CatalogDatabase!
    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("FSD-task062-\(UUID())")
        db = try CatalogDatabase(url:directory.appendingPathComponent("catalog.sqlite"),schemaURL:CatalogSchemaFixture.canonicalSchemaURL)
    }
    override func tearDownWithError() throws { db?.close(); try? FileManager.default.removeItem(at:directory) }
    private func healthy() throws {
        XCTAssertEqual(try db.scalar("PRAGMA foreign_keys")?.int64Value,1)
        XCTAssertTrue(try db.query("PRAGMA foreign_key_check").isEmpty)
        XCTAssertEqual(try db.scalar("PRAGMA integrity_check")?.stringValue,"ok")
    }
    private func originals() throws -> [[DatabaseRow]] {
        try CatalogMigrations.ExpectedState.tables.filter { !$0.hasPrefix("saved_") }.map { try db.query("SELECT * FROM \($0) ORDER BY rowid") }
    }
    private func noSave(operations: Int64 = 0) throws {
        for table in CatalogMigrations.savedTableDefinitions { XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM \(table.name)")?.int64Value,table.name == "saved_operations" ? operations : 0,table.name) }
    }
    private func make(_ kinds: (SnapshotKind,SnapshotKind) = (.user,.user), rich: Bool = true, beforeComplete: (SnapshotID,SnapshotID) throws -> Void = { _,_ in }) throws -> (ComparisonCompletionReceipt,SnapshotID,SnapshotID) {
        let l = try SyntheticSnapshot.createSnapshot(database:db,volumeID:1,session:1,kind:kinds.0)
        let r = try SyntheticSnapshot.createSnapshot(database:db,volumeID:2,session:1,sensitivity:.unknown,kind:kinds.1)
        try SyntheticSnapshot.insertEntries(database:db,snapshotID:l,entries:[SyntheticSnapshot.root(id:101)])
        try SyntheticSnapshot.insertEntries(database:db,snapshotID:r,entries:[SyntheticSnapshot.root(id:201)])
        if rich {
            try db.execute("UPDATE comparison_profiles SET ignore_rules_json='[\"ignored\"]' WHERE id=1")
            try SyntheticSnapshot.insertEntries(database:db,snapshotID:l,entries:[
                .init(id:102,parentID:101,relativePath:"removed",name:"removed"),
                .init(id:103,parentID:101,relativePath:"changed",name:"changed",logicalSizeBytes:1),
                .init(id:104,parentID:101,relativePath:"ignored",name:"ignored"),
                .init(id:105,parentID:101,relativePath:"A",name:"A"),.init(id:106,parentID:101,relativePath:"a",name:"a"),
                .init(id:107,parentID:101,relativePath:"dir",name:"dir",itemKind:.directory),
                .init(id:108,parentID:107,relativePath:"dir/é.bin",name:"é.bin",logicalSizeBytes:Int64.max)])
            try SyntheticSnapshot.insertEntries(database:db,snapshotID:r,entries:[
                .init(id:202,parentID:201,relativePath:"added",name:"added"),
                .init(id:203,parentID:201,relativePath:"changed",name:"changed",logicalSizeBytes:2),
                .init(id:204,parentID:201,relativePath:"ignored",name:"ignored"),.init(id:205,parentID:201,relativePath:"A",name:"A"),
                .init(id:206,parentID:201,relativePath:"dir",name:"dir",itemKind:.directory),
                .init(id:207,parentID:206,relativePath:"dir/é.bin",name:"é.bin",logicalSizeBytes:Int64.max)])
            try db.execute("UPDATE entries SET resource_identifier=X'00FF00',metadata_signature=X'',subtree_signature=NULL,allocated_size_bytes=?,content_type_identifier=NULL WHERE id=108",bindings:[.integer(Int64.min)])
            try db.execute("UPDATE snapshots SET user_note='frozen',duration_ms=?,root_metadata_signature=X'00FF' WHERE id=?",bindings:[.integer(Int64.max),.integer(l.rawValue)])
            try db.execute("INSERT INTO scan_issues(snapshot_id,entry_id,relative_path,error_code,severity,source,message,was_skipped,created_at) VALUES (?,108,'dir/é.bin',?,'warning','reader','frozen issue',1,'then'),(?,NULL,'unknown',NULL,'info','scanner','',0,'then')",bindings:[.integer(l.rawValue),.integer(Int64.min),.integer(l.rawValue)])
        }
        try beforeComplete(l,r)
        try SyntheticSnapshot.complete(database:db,snapshotID:l); try SyntheticSnapshot.complete(database:db,snapshotID:r)
        let comparison = try ComparisonEngine(database:db).compare(leftSnapshotID:l,rightSnapshotID:r,profileID:1)
        return (try XCTUnwrap(ComparisonCompletionReceiptRepository(database:db).receipt(comparisonID:comparison.id)),l,r)
    }
    func testExplicitSaveHasDedicatedSchema() throws {
        XCTAssertEqual(try db.schemaVersion,13)
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM saved_comparisons")?.int64Value,0)
        _ = try make()
        try noSave()
    }
    func testAllModesCopyExactTypedEvidenceAndReferencesWithoutChangingOriginals() throws {
        let identities=PhysicalDriveRepository(database:db)
        let drive=try identities.createDrive(label:"Synthetic only",provenance:"task062 fixture")
        let observation=try identities.recordObservation(sessionID:UUID(),revision:1,scope:.volume,provenance:"synthetic",observedAt:Date())
        _=try identities.setManualAssociation(operationID:UUID(),observationID:observation.id,expectedObservationRevision:1,expectedAssociationRevision:0,target:drive.id,expectedTargetRevision:drive.revision,action:.associate,actor:"test",reason:"generated only")
        let sets=DriveSetRepository(database:db); let set=try sets.create(name:"Synthetic set")
        _=try sets.setMembership(setID:set.id,expectedRevision:set.revision,driveID:drive.id,expectedDriveRevision:drive.revision,included:true)
        let collection=try SnapshotCollectionRepository(database:db).createCollection(name:"Synthetic collection")
        for kinds in [(SnapshotKind.user,SnapshotKind.user),(.transient,.user),(.transient,.transient)] {
            let (receipt,l,_) = try make(kinds)
            if kinds.0 == .user { try SnapshotCollectionRepository(database:db).assign(snapshotID:l,to:collection.id) }
            let before = try originals(); let repo = SavedComparisonRepository(database:db)
            let request = SavedComparisonRequest(operationID:UUID(),receipt:receipt)
            let id = try repo.save(request); let reader = try repo.open(id:id)
            XCTAssertEqual(reader.receipt,receipt); XCTAssertEqual(try originals(),before)
            XCTAssertEqual(try repo.save(request),id)
            XCTAssertEqual(try reader.results().count,Int(receipt.closure.resultRows))
            XCTAssertEqual(Set(try reader.results().compactMap { $0.original["result_type"]?.text }),Set(ComparisonResultType.allCases.map(\.rawValue)))
            let left = try reader.entries(side:.left); let right = try reader.entries(side:.right)
            XCTAssertEqual(left.count,Int(receipt.closure.leftEntries)); XCTAssertEqual(right.count,Int(receipt.closure.rightEntries))
            let child = try XCTUnwrap(left.first { $0.original["id"] == .integer(108) })
            let parent = try XCTUnwrap(left.first { $0.original["id"] == .integer(107) })
            XCTAssertEqual(child.parentID,parent.id)
            XCTAssertEqual(child.original["logical_size_bytes"],.integer(Int64.max)); XCTAssertEqual(child.original["allocated_size_bytes"],.integer(Int64.min))
            XCTAssertEqual(child.original["resource_identifier"],.blob(Data([0,255,0]))); XCTAssertEqual(child.original["metadata_signature"],.blob(Data())); XCTAssertEqual(child.original["subtree_signature"],.null)
            XCTAssertEqual(child.original["relative_path"],.text("dir/é.bin"))
            for result in try reader.results() {
                if let origin = result.original["left_entry_id"]?.integer { XCTAssertEqual(result.leftEntryID,left.first { $0.original["id"] == .integer(origin) }?.id) }
                if let origin = result.original["right_entry_id"]?.integer { XCTAssertEqual(result.rightEntryID,right.first { $0.original["id"] == .integer(origin) }?.id) }
                if let origin = result.original["parent_result_id"]?.integer { XCTAssertEqual(result.parentID,try reader.results().first { $0.original["id"] == .integer(origin) }?.id) }
            }
            XCTAssertEqual(try reader.collisionGroups().count,1); XCTAssertEqual(try reader.collisionMembers().count,3)
            for member in try reader.collisionMembers() {
                let side = member.original["side"]?.text == "left" ? left : right
                XCTAssertEqual(member.entryID,side.first { $0.original["id"] == member.original["entry_id"] }?.id)
                XCTAssertEqual(member.groupID,try reader.collisionGroups().first?.id)
            }
            let issues = try reader.issues(side:.left)
            XCTAssertEqual(issues.map(\.original),receipt.left.issues); XCTAssertEqual(issues[0].entryID,child.id); XCTAssertNil(issues[1].entryID)
            try repo.delete(id:id); try healthy()
            // Reuse this isolated test catalog only after explicit generated cleanup.
            try db.execute("DELETE FROM comparisons"); try db.execute("DELETE FROM snapshots")
        }
    }
    func testFrozenReceiptWinsOverCurrentProfileHeadersIssuesAndRegistry() throws {
        let (receipt,l,_) = try make()
        try db.execute("UPDATE comparison_profiles SET name='later',version=version+1,ignore_rules_json='[]' WHERE id=1")
        try db.execute("UPDATE snapshots SET display_name='later',user_note='later',total_files=999 WHERE id=?",bindings:[.integer(l.rawValue)])
        try db.execute("DELETE FROM scan_issues"); try db.execute("UPDATE volumes SET display_name='later'")
        let repo=SavedComparisonRepository(database:db); let id=try repo.save(.init(operationID:UUID(),receipt:receipt))
        let reader=try repo.open(id:id)
        XCTAssertEqual(reader.receipt,receipt); XCTAssertEqual(try reader.issues(side:.left).map(\.original),receipt.left.issues)
        try healthy()
    }
    func testOfflineFileReopenAfterActualWorkspaceCloseAndAllOriginalDeletion() throws {
        let (receipt,_,_) = try make((.transient,.transient))
        let request=SavedComparisonRequest(operationID:UUID(),receipt:receipt)
        var repo=SavedComparisonRepository(database:db); let id=try repo.save(request)
        try TransientSnapshotLifecycle(database:db).closeWorkspace()
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM snapshots")?.int64Value,0)
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM entries")?.int64Value,0)
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM comparisons")?.int64Value,0)
        try db.execute("DELETE FROM volumes"); try db.execute("DELETE FROM comparison_profiles")
        db.close(); db=try CatalogDatabase(url:directory.appendingPathComponent("catalog.sqlite"))
        repo=SavedComparisonRepository(database:db); XCTAssertEqual(try repo.save(request),id)
        let reader=try repo.open(id:id); XCTAssertEqual(reader.receipt,receipt)
        var cursor: Int64=0; var rows=0
        while true { let page=try reader.entries(side:.left,after:cursor,limit:2); if page.isEmpty { break }; XCTAssertLessThanOrEqual(page.count,2); rows+=page.count; cursor=page.last!.id }
        XCTAssertEqual(rows,Int(receipt.closure.leftEntries)); XCTAssertFalse(try reader.results().isEmpty)
        XCTAssertEqual(try repo.list(),[id]); try healthy()
    }
    func testDeletionTombstoneRetryAndOperationBindingSurviveReopen() throws {
        let (receipt,_,_) = try make(); let repo=SavedComparisonRepository(database:db)
        let op=UUID(), request=SavedComparisonRequest(operationID:op,receipt:receipt); let id=try repo.save(request)
        let (other,_,_)=try anotherComparison(receipt)
        XCTAssertThrowsError(try repo.save(.init(operationID:op,receipt:other))) { XCTAssertEqual($0 as? SavedComparisonError,.identityConflict) }
        let reader=try repo.open(id:id)
        try repo.delete(id:id); try repo.delete(id:id)
        XCTAssertThrowsError(try reader.results())
        for table in CatalogMigrations.savedTableDefinitions where table.name != "saved_operations" { XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM \(table.name)")?.int64Value,0) }
        db.close(); db=try CatalogDatabase(url:directory.appendingPathComponent("catalog.sqlite"))
        XCTAssertThrowsError(try SavedComparisonRepository(database:db).save(request)) { XCTAssertEqual($0 as? SavedComparisonError,.deleted) }
        XCTAssertThrowsError(try db.execute("DELETE FROM saved_operations")); XCTAssertThrowsError(try db.execute("UPDATE saved_operations SET state='ready'"))
        try healthy()
    }
    private func anotherComparison(_ old: ComparisonCompletionReceipt) throws -> (ComparisonCompletionReceipt,SnapshotID,SnapshotID) {
        let l=SnapshotID(rawValue:old.left.header["id"]!.integer!),r=SnapshotID(rawValue:old.right.header["id"]!.integer!)
        let c=try ComparisonEngine(database:db).compare(leftSnapshotID:l,rightSnapshotID:r,profileID:1)
        return (try XCTUnwrap(ComparisonCompletionReceiptRepository(database:db).receipt(comparisonID:c.id)),l,r)
    }
    func testEverySaveBoundaryRollbackAndRetryPreservesOriginals() throws {
        let (receipt,_,_) = try make(); let before=try originals(); let repo=SavedComparisonRepository(database:db)
        for (iteration,stage) in ["artifact","left_tree","left_entries","left_issues","right_tree","right_entries","right_issues","results","groups","members","validated","ready","operation","precommit"].enumerated() {
            let request=SavedComparisonRequest(operationID:UUID(),receipt:receipt)
            repo.checkpointObserver={ if $0==stage { throw SavedComparisonError.cancelled } }
            XCTAssertThrowsError(try repo.save(request),stage)
            try noSave(operations:Int64(iteration)); XCTAssertEqual(try originals(),before)
            repo.checkpointObserver=nil
            let id=try repo.save(request); XCTAssertEqual(try repo.save(request),id)
            try repo.delete(id:id)
            // Tombstone from successful retry is intentionally permanent.
            XCTAssertEqual(try db.scalar("SELECT state FROM saved_operations WHERE id=?",bindings:[.text(request.operationID.uuidString)])?.stringValue,"deleted")
        }
        try healthy()
    }
    func testCommitAndImmediateFKFailureAreAtomicAndPeerNeverSeesPartialArtifact() throws {
        let (receipt,_,_) = try make(); let before=try originals(); let repo=SavedComparisonRepository(database:db)
        let peer=try CatalogDatabase(url:directory.appendingPathComponent("catalog.sqlite")); defer { peer.close() }
        repo.checkpointObserver={ stage in
            if stage == "ready" || stage == "operation" { XCTAssertEqual(try peer.scalar("SELECT COUNT(*) FROM saved_comparisons")?.int64Value,0); XCTAssertEqual(try peer.scalar("SELECT COUNT(*) FROM saved_operations")?.int64Value,0) }
        }
        try db.execute("CREATE TABLE synthetic_deferred(id INTEGER REFERENCES saved_trees(id) DEFERRABLE INITIALLY DEFERRED)")
        try db.execute("CREATE TRIGGER synthetic_commit AFTER INSERT ON saved_operations BEGIN INSERT INTO synthetic_deferred VALUES(999999); END")
        let request=SavedComparisonRequest(operationID:UUID(),receipt:receipt)
        XCTAssertThrowsError(try repo.save(request)); try noSave(); XCTAssertEqual(try originals(),before)
        try db.execute("DROP TRIGGER synthetic_commit")
        repo.checkpointObserver={ if $0=="left_entries" { try self.db.execute("INSERT INTO saved_issues(artifact_id,tree_id,origin_id,entry_id,payload) SELECT artifact_id,tree_id,999,999999,X'7B7D' FROM saved_entries LIMIT 1") } }
        XCTAssertThrowsError(try repo.save(request)); try noSave(); XCTAssertEqual(try originals(),before)
        repo.checkpointObserver=nil; _=try repo.save(request); try healthy()
    }
    func testCancellationAndAllProductionBudgetsFailClosed() throws {
        let (receipt,_,_) = try make(); let repo=SavedComparisonRepository(database:db); let before=try originals()
        XCTAssertThrowsError(try repo.save(.init(operationID:UUID(),receipt:receipt),isCancelled:{ true })) { XCTAssertEqual($0 as? SavedComparisonError,.cancelled) }
        for field in 0..<4 {
            var limits=SavedComparisonLimits()
            switch field { case 0: limits.rows=1; case 1: limits.metadataBytes=1; case 2: limits.elapsedSeconds=0; default: limits.databaseGrowthBytes=0 }
            XCTAssertThrowsError(try repo.save(.init(operationID:UUID(),receipt:receipt),limits:limits),"budget \(field)")
            try noSave(); XCTAssertEqual(try originals(),before)
        }
        var cancelled=false
        repo.checkpointObserver={ if $0=="right_entries" { cancelled=true } }
        XCTAssertThrowsError(try repo.save(.init(operationID:UUID(),receipt:receipt),isCancelled:{ cancelled })) { XCTAssertEqual($0 as? SavedComparisonError,.cancelled) }
        try noSave(); try healthy()
    }
    func testRunningCancelledFailedReceiptlessAndStaleIdentityReject() throws {
        let (receipt,l,r) = try make(); let repo=SavedComparisonRepository(database:db)
        for status in ["running","cancelled","failed"] {
            try db.execute("INSERT INTO comparisons(left_snapshot_id,right_snapshot_id,profile_id,status,started_at,created_at) VALUES (?,?,1,?,'then','then')",bindings:[.integer(l.rawValue),.integer(r.rawValue),.text(status)])
            let id=try db.lastInsertRowID()
            // Request preserves actual receipt identity except the explicit comparison ID in encoded test receipt.
            let bad=try changedReceipt(receipt,comparisonID:id)
            XCTAssertThrowsError(try repo.save(.init(operationID:UUID(),receipt:bad)))
            try noSave()
        }
        let bad=try changedReceipt(receipt,token:UUID())
        XCTAssertThrowsError(try repo.save(.init(operationID:UUID(),receipt:bad))) { XCTAssertEqual($0 as? SavedComparisonError,.identityConflict) }
        try db.execute("DELETE FROM comparisons")
        XCTAssertThrowsError(try repo.save(.init(operationID:UUID(),receipt:receipt)))
        try noSave(); try healthy()
    }
    private func changedReceipt(_ r: ComparisonCompletionReceipt, comparisonID: Int64? = nil, token: UUID? = nil) throws -> ComparisonCompletionReceipt {
        var json=try XCTUnwrap(JSONSerialization.jsonObject(with:r.encoded()) as? [String:Any])
        if let comparisonID { json["comparisonID"]=comparisonID }; if let token { json["completionToken"]=token.uuidString }
        return try JSONDecoder().decode(ComparisonCompletionReceipt.self,from:JSONSerialization.data(withJSONObject:json))
    }
    func testMissingOriginalRowsAndChangedResultEvidenceRejectWithoutSavedResidue() throws {
        let (receipt,_,_) = try make(); let repo=SavedComparisonRepository(database:db)
        try db.execute("DROP TRIGGER trg_comparison_results_delete_guard"); try db.execute("DELETE FROM comparison_results WHERE id=(SELECT MAX(id) FROM comparison_results)")
        XCTAssertThrowsError(try repo.save(.init(operationID:UUID(),receipt:receipt))); try noSave()
        try db.execute(CatalogMigrations.ExpectedState.triggerDefinitions.first { $0.name == "trg_comparison_results_delete_guard" }!.sql)
        try healthy()
    }
    func testSavedReadyGuardsAndOfflineCorruptionFailClosed() throws {
        let (receipt,_,_) = try make(); let repo=SavedComparisonRepository(database:db); let id=try repo.save(.init(operationID:UUID(),receipt:receipt))
        for table in CatalogMigrations.savedTableDefinitions where table.name != "saved_operations" {
            XCTAssertThrowsError(try db.execute("UPDATE \(table.name) SET id=id"),table.name)
            if table.name != "saved_comparisons" { XCTAssertThrowsError(try db.execute("DELETE FROM \(table.name)"),table.name) }
        }
        try db.execute("DROP TRIGGER trg_saved_entries_update")
        try db.execute("UPDATE saved_entries SET payload=X'7B7D' WHERE id=(SELECT MAX(id) FROM saved_entries)")
        XCTAssertThrowsError(try repo.open(id:id))
        try db.execute(CatalogMigrations.savedTriggerDefinitions.first { $0.name=="trg_saved_entries_update" }!.sql)
        db.close(); db=try CatalogDatabase(url:directory.appendingPathComponent("catalog.sqlite"))
        XCTAssertThrowsError(try SavedComparisonRepository(database:db).open(id:id)); try healthy()
    }
    func testBoundedReadPagesHaveIndexedPlans() throws {
        let (receipt,_,_) = try make(); let repo=SavedComparisonRepository(database:db); let id=try repo.save(.init(operationID:UUID(),receipt:receipt)); let reader=try repo.open(id:id)
        XCTAssertEqual(try reader.entries(side:.left,limit:1).count,1)
        for table in ["saved_entries","saved_results","saved_collision_groups","saved_collision_members"] {
            let details=try db.query("EXPLAIN QUERY PLAN SELECT * FROM \(table) WHERE artifact_id=? AND id>? ORDER BY id LIMIT 256",bindings:[.text(id.uuidString),.integer(0)]).compactMap { $0["detail"]?.stringValue }
            XCTAssertTrue(details.contains { $0.contains("INDEX") }); XCTAssertFalse(details.contains { $0.contains("TEMP B-TREE") })
        }
    }

    func testSavedOpenAndRetryHonorReducedRowAndByteLimits() throws {
        let (receipt,_,_)=try make(); let repo=SavedComparisonRepository(database:db)
        let request=SavedComparisonRequest(operationID:UUID(),receipt:receipt); let id=try repo.save(request)
        for isRows in [true,false] {
            var limits=SavedComparisonLimits()
            if isRows { limits.rows=2 } else { limits.metadataBytes=Int64(try receipt.encoded().count)+1 }
            XCTAssertThrowsError(try repo.open(id:id,limits:limits))
            XCTAssertThrowsError(try repo.save(request,limits:limits))
        }
        XCTAssertEqual(try repo.open(id:id).receipt,receipt); try healthy()
    }
    func testTwoArtifactsOwnIndependentTreesAndDeletingOnePreservesTheOther() throws {
        let (receipt,_,_)=try make(); let repo=SavedComparisonRepository(database:db)
        let first=try repo.save(.init(operationID:UUID(),receipt:receipt)),second=try repo.save(.init(operationID:UUID(),receipt:receipt))
        let other=try repo.open(id:second); let before=try other.entries(side:.left)
        let firstTree=try repo.open(id:first).entries(side:.left).first!.treeID
        XCTAssertNotEqual(firstTree,before.first!.treeID)
        for side in ["left","right"] {
            let plans=try db.query("EXPLAIN QUERY PLAN SELECT id FROM saved_results WHERE \(side)_entry_id=? AND \(side)_tree_id=?",bindings:[.integer(1),.integer(1)]).compactMap { $0["detail"]?.stringValue }
            XCTAssertFalse(plans.contains { $0.contains("SCAN saved_results") || $0.contains("TEMP B-TREE") })
        }
        try repo.delete(id:first); XCTAssertEqual(try other.entries(side:.left),before); XCTAssertEqual(try repo.open(id:second).receipt,receipt); try healthy()
    }
    func testCopyInsertionFailureAndCopiedEntryTamperingRollback() throws {
        let (receipt,_,_)=try make(); let repo=SavedComparisonRepository(database:db); let before=try originals()
        try db.execute("CREATE TRIGGER synthetic_copy_failure AFTER INSERT ON saved_entries BEGIN SELECT RAISE(ABORT,'synthetic copy'); END")
        XCTAssertThrowsError(try repo.save(.init(operationID:UUID(),receipt:receipt))); try noSave()
        try db.execute("DROP TRIGGER synthetic_copy_failure")
        repo.checkpointObserver={ stage in
            if stage=="left_entries" {
                let row=try XCTUnwrap(self.db.query("SELECT id,payload FROM saved_entries ORDER BY id LIMIT 1").first)
                guard case .blob(let data)=row["payload"] else { return XCTFail("payload") }
                var metadata=try JSONDecoder().decode([String:CompletionMetadataValue].self,from:data)
                metadata["logical_size_bytes"] = .integer(123)
                try self.db.execute("UPDATE saved_entries SET payload=? WHERE id=?",bindings:[.blob(ComparisonCompletionReceipt.encoder().encode(metadata)),row["id"]!])
            }
        }
        XCTAssertThrowsError(try repo.save(.init(operationID:UUID(),receipt:receipt))) { XCTAssertEqual($0 as? SavedComparisonError,.corrupt("copied entry differs from original")) }
        try noSave(); XCTAssertEqual(try originals(),before); try healthy()
    }
    func testDeleteCommitFailureRollsBackGraphAndTombstoneTogether() throws {
        let (receipt,_,_)=try make(); let repo=SavedComparisonRepository(database:db)
        let request=SavedComparisonRequest(operationID:UUID(),receipt:receipt),id=try repo.save(request)
        try db.execute("CREATE TABLE synthetic_delete_guard(id TEXT REFERENCES saved_comparisons(id) DEFERRABLE INITIALLY DEFERRED)")
        try db.execute("INSERT INTO synthetic_delete_guard VALUES (?)",bindings:[.text(id.uuidString)])
        XCTAssertThrowsError(try repo.delete(id:id))
        XCTAssertEqual(try repo.save(request),id); XCTAssertEqual(try repo.open(id:id).receipt,receipt)
        try db.execute("DELETE FROM synthetic_delete_guard"); try repo.delete(id:id)
        XCTAssertThrowsError(try repo.save(request)) { XCTAssertEqual($0 as? SavedComparisonError,.deleted) }; try healthy()
    }
    func testUnsupportedSourceFieldAndMalformedOriginalMetadataRejectWithoutSubstitution() throws {
        let (receipt,_,_)=try make(); let repo=SavedComparisonRepository(database:db)
        try db.execute("ALTER TABLE entries ADD COLUMN unsupported_fact TEXT")
        XCTAssertThrowsError(try repo.save(.init(operationID:UUID(),receipt:receipt))) { XCTAssertEqual($0 as? SavedComparisonError,.corrupt("unsupported source fields")) }
        try noSave()
    }
    func testCancellationAtPrecommitLeavesNoArtifactOrOperation() throws {
        let (receipt,_,_)=try make(); let repo=SavedComparisonRepository(database:db); var cancelled=false
        repo.checkpointObserver={ if $0=="operation" { cancelled=true } }
        XCTAssertThrowsError(try repo.save(.init(operationID:UUID(),receipt:receipt),isCancelled:{ cancelled })) { XCTAssertEqual($0 as? SavedComparisonError,.cancelled) }
        try noSave(); try healthy()
    }
    func testCollisionPagingUsesGroupAndMemberIndexesWithoutTemporarySorting() throws {
        let (receipt,_,_)=try make(); let repo=SavedComparisonRepository(database:db); let id=try repo.save(.init(operationID:UUID(),receipt:receipt))
        for query in ["SELECT id FROM comparison_collision_members WHERE group_id=? AND id>? ORDER BY id LIMIT 256","SELECT origin_id,payload FROM saved_collision_members WHERE group_id=? AND origin_id>? ORDER BY origin_id LIMIT 256"] {
            let plan=try db.query("EXPLAIN QUERY PLAN "+query,bindings:[.integer(1),.integer(0)]).compactMap { $0["detail"]?.stringValue }
            XCTAssertTrue(plan.contains { $0.contains("INDEX") }); XCTAssertFalse(plan.contains { $0.contains("TEMP B-TREE") })
        }
        XCTAssertEqual(try repo.open(id:id).collisionMembers(limit:1).count,1)
    }


    func testCollisionMembersAcrossPageBoundariesRemainComplete() throws {
        let l=try SyntheticSnapshot.createSnapshot(database:db,volumeID:1,session:1)
        let r=try SyntheticSnapshot.createSnapshot(database:db,volumeID:2,session:1,sensitivity:.unknown)
        try SyntheticSnapshot.insertEntries(database:db,snapshotID:l,entries:[SyntheticSnapshot.root(id:1)])
        let entries=(0..<300).map { value -> SyntheticSnapshot.SeedEntry in
            let name=String((0..<9).map { value & (1 << $0) == 0 ? Character("a") : Character("A") })
            return .init(id:Int64(value+2),parentID:1,relativePath:name,name:name)
        }
        try SyntheticSnapshot.insertEntries(database:db,snapshotID:l,entries:entries)
        try SyntheticSnapshot.insertEntries(database:db,snapshotID:r,entries:[SyntheticSnapshot.root(id:1001),.init(id:1002,parentID:1001,relativePath:"AAAAAAAAA",name:"AAAAAAAAA")])
        try SyntheticSnapshot.complete(database:db,snapshotID:l); try SyntheticSnapshot.complete(database:db,snapshotID:r)
        let c=try ComparisonEngine(database:db).compare(leftSnapshotID:l,rightSnapshotID:r,profileID:1)
        let receipt=try XCTUnwrap(ComparisonCompletionReceiptRepository(database:db).receipt(comparisonID:c.id))
        let repo=SavedComparisonRepository(database:db); let id=try repo.save(.init(operationID:UUID(),receipt:receipt)); let reader=try repo.open(id:id)
        var cursor:Int64=0; var total=0; var pages=0
        while true { let page=try reader.collisionMembers(after:cursor,limit:128); if page.isEmpty { break }; XCTAssertLessThanOrEqual(page.count,128); total+=page.count; cursor=page.last!.id; pages+=1 }
        XCTAssertEqual(total,301); XCTAssertEqual(pages,3); XCTAssertEqual(receipt.closure.collisionMembers,301)
        try repo.delete(id:id); try healthy()
    }


    func testOriginalUnsupportedStorageAndOversizedFieldRejectWithoutLossyConversion() throws {
        for sql in ["UPDATE entries SET resource_identifier=zeroblob(65537) WHERE id=101", "UPDATE entries SET symlink_target=CAST(X'80' AS TEXT) WHERE id=101", "UPDATE entries SET symlink_target=CAST(X'610062' AS TEXT) WHERE id=101", "UPDATE entries SET allocated_size_bytes=1.5 WHERE id=101"] {
            let (receipt,_,_)=try make(rich:false) { _,_ in try self.db.execute(sql) }
            let repo=SavedComparisonRepository(database:db)
            XCTAssertThrowsError(try repo.save(.init(operationID:UUID(),receipt:receipt)))
            try noSave(); try healthy()
            try db.execute("DELETE FROM comparisons"); try db.execute("DELETE FROM snapshots")
        }
    }
    func testSameOriginalSnapshotStillCreatesTwoIndependentBackingTrees() throws {
        let (old,l,_)=try make(rich:false)
        let c=try ComparisonEngine(database:db).compare(leftSnapshotID:l,rightSnapshotID:l,profileID:old.profile.id)
        let receipt=try XCTUnwrap(ComparisonCompletionReceiptRepository(database:db).receipt(comparisonID:c.id))
        let repo=SavedComparisonRepository(database:db),id=try repo.save(.init(operationID:UUID(),receipt:receipt)); let reader=try repo.open(id:id)
        let left=try XCTUnwrap(reader.entries(side:.left).first),right=try XCTUnwrap(reader.entries(side:.right).first)
        XCTAssertNotEqual(left.treeID,right.treeID); XCTAssertNotEqual(left.id,right.id); XCTAssertEqual(left.original,right.original)
        try healthy()
    }

    func testTenThousandAndHundredThousandFileBackedTrees() throws {
        for total in [10_000,100_000] {
            let l=try SyntheticSnapshot.createSnapshot(database:db,volumeID:1,session:Int64(total),kind:.transient)
            let r=try SyntheticSnapshot.createSnapshot(database:db,volumeID:2,session:Int64(total),kind:.transient)
            for (side,snapshot) in [(0,l),(1,r)] {
                let root=Int64(side*total+1)
                try SyntheticSnapshot.insertEntries(database:db,snapshotID:snapshot,entries:[SyntheticSnapshot.root(id:root)])
                for start in stride(from:1,to:total/2,by:256) {
                    let page=(start..<min(start+256,total/2)).map { i in SyntheticSnapshot.SeedEntry(id:root+Int64(i),parentID:root,relativePath:String(format:"f%06d",i),name:String(format:"f%06d",i),logicalSizeBytes:Int64(i)) }
                    try SyntheticSnapshot.insertEntries(database:db,snapshotID:snapshot,entries:page)
                }
                try SyntheticSnapshot.complete(database:db,snapshotID:snapshot)
            }
            let c=try ComparisonEngine(database:db).compare(leftSnapshotID:l,rightSnapshotID:r,profileID:1)
            let receipt=try XCTUnwrap(ComparisonCompletionReceiptRepository(database:db).receipt(comparisonID:c.id))
            let repo=SavedComparisonRepository(database:db),request=SavedComparisonRequest(operationID:UUID(),receipt:receipt)
            var before=rusage(); getrusage(RUSAGE_SELF,&before)
            let started=ProcessInfo.processInfo.systemUptime; let pagesBefore=try db.scalar("PRAGMA page_count")!.int64Value!
            if total == 100_000 {
                XCTAssertThrowsError(try repo.save(request)) { XCTAssertEqual($0 as? SavedComparisonError,.budgetExceeded("rows")) }
                let rejectedSeconds=ProcessInfo.processInfo.systemUptime-started
                var after=rusage(); getrusage(RUSAGE_SELF,&after)
                XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM saved_comparisons")?.int64Value,0)
                XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM entries")?.int64Value,Int64(total))
                print("TASK062_SCALE total=\(total) results=\(receipt.closure.resultRows) outcome=FAIL_CLOSED_ROWS save_seconds=\(rejectedSeconds) copied_pages=0 rss_before=\(before.ru_maxrss) rss_after=\(after.ru_maxrss)")
                try healthy(); try TransientSnapshotLifecycle(database:db).closeWorkspace(); continue
            }
            let id=try repo.save(request)
            let savedSeconds=ProcessInfo.processInfo.systemUptime-started
            let reader=try repo.open(id:id); var read=0
            for side in [SavedComparisonSide.left,.right] { var cursor:Int64=0; while true { let page=try reader.entries(side:side,after:cursor); if page.isEmpty { break }; XCTAssertLessThanOrEqual(page.count,256); read+=page.count; cursor=page.last!.id } }
            var after=rusage(); getrusage(RUSAGE_SELF,&after)
            let bytes=(try db.scalar("PRAGMA page_count")!.int64Value!-pagesBefore)*(try db.scalar("PRAGMA page_size")!.int64Value!)
            print("TASK062_SCALE total=\(total) results=\(receipt.closure.resultRows) save_seconds=\(savedSeconds) read_total=\(read) page_max=256 sqlite_growth_bytes=\(bytes) rss_before=\(before.ru_maxrss) rss_after=\(after.ru_maxrss)")
            XCTAssertEqual(read,total); XCTAssertLessThan(savedSeconds,60); XCTAssertLessThan(bytes,512*1024*1024)
            try healthy(); try repo.delete(id:id); try TransientSnapshotLifecycle(database:db).closeWorkspace(); try healthy()
        }
    }
}
