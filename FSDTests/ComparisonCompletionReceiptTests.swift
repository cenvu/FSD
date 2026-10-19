import XCTest
@testable import FSD

/// Synthetic metadata and isolated catalogs only; no source observation.
final class ComparisonCompletionReceiptTests: XCTestCase {
    private var directory: URL!
    private var db: CatalogDatabase!
    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("FSD-task061-\(UUID())")
        db = try CatalogDatabase(url: directory.appendingPathComponent("catalog.sqlite"), schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
    }
    override func tearDownWithError() throws { db?.close(); try? FileManager.default.removeItem(at: directory) }
    private func pair(beforeComplete: (SnapshotID,SnapshotID) throws -> Void = { _,_ in }) throws -> (SnapshotID, SnapshotID) {
        let left = try SyntheticSnapshot.createSnapshot(database: db, volumeID: 1, session: 1)
        let right = try SyntheticSnapshot.createSnapshot(database: db, volumeID: 1, session: 2, sensitivity: .unknown)
        try SyntheticSnapshot.insertEntries(database: db, snapshotID: left, entries: [SyntheticSnapshot.root(id: 11)])
        try SyntheticSnapshot.insertEntries(database: db, snapshotID: right, entries: [SyntheticSnapshot.root(id: 12)])
        try beforeComplete(left,right)
        try SyntheticSnapshot.complete(database: db, snapshotID: left)
        try SyntheticSnapshot.complete(database: db, snapshotID: right)
        return (left,right)
    }
    func testEveryNewCompletionHasOneReceipt() throws {
        let (left,right) = try pair()
        let result = try ComparisonEngine(database: db).compare(leftSnapshotID: left, rightSnapshotID: right, profileID: 1)
        XCTAssertEqual(result.status,.complete)
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM comparison_completion_receipts WHERE comparison_id=?",bindings:[.integer(result.id.rawValue)])?.int64Value,1)
        let receipt = try XCTUnwrap(ComparisonCompletionReceiptRepository(database:db).receipt(comparisonID:result.id))
        XCTAssertEqual(receipt.left.header["id"],.integer(left.rawValue))
        XCTAssertEqual(receipt.right.header["id"],.integer(right.rawValue))
        XCTAssertEqual(receipt.closure.counts["matched"],result.matchedCount)
        XCTAssertEqual(receipt.warnings,result.warnings)
        XCTAssertEqual(receipt.selectedPathKey,"case_folded_path")
        XCTAssertEqual(receipt.orientation,"left-reference_right-changed-v1")
        XCTAssertTrue(try ComparisonCompletionReceiptRepository(database:db).isEligibleForExactSave(comparisonID:result.id))
        try healthy()
    }
    private func healthy() throws {
        XCTAssertEqual(try db.scalar("PRAGMA foreign_keys")?.int64Value,1)
        XCTAssertTrue(try db.query("PRAGMA foreign_key_check").isEmpty)
        XCTAssertEqual(try db.scalar("PRAGMA integrity_check")?.stringValue,"ok")
    }
    private func run(_ left: SnapshotID, _ right: SnapshotID, token: ComparisonCancellationToken = ComparisonCancellationToken(), progress: @escaping (ComparisonProgress)->Void = { _ in }) throws -> ComparisonRecord {
        try ComparisonEngine(database:db,pageSize:1,batchSize:1).compare(leftSnapshotID:left,rightSnapshotID:right,profileID:1,token:token,onProgress:progress)
    }
    func testExecutedProfileIsFrozenDespiteConcurrentRegistryEdit() throws {
        let (l,r) = try pair { l,r in
            try SyntheticSnapshot.insertEntries(database:self.db,snapshotID:l,entries:[.init(id:21,parentID:11,relativePath:"a",name:"a",logicalSizeBytes:1)])
            try SyntheticSnapshot.insertEntries(database:self.db,snapshotID:r,entries:[.init(id:22,parentID:12,relativePath:"a",name:"a",logicalSizeBytes:2)])
        }
        let original = try XCTUnwrap(ComparisonProfileRepository(database:db).profile(id:1))
        let comparison = try run(l,r) { progress in
            if progress.phase == "Matching" {
                try! self.db.execute("UPDATE comparison_profiles SET name='new current',version=version+1,compare_logical_size=0,include_hidden_items=1,ignore_rules_json='[\"**\"]' WHERE id=1")
            }
        }
        let receipt = try XCTUnwrap(ComparisonCompletionReceiptRepository(database:db).receipt(comparisonID:comparison.id))
        XCTAssertEqual(receipt.profile,CompletionProfileDefinition(original))
        XCTAssertEqual(comparison.changedCount,1,"engine used original logical size flag")
        XCTAssertNotEqual(receipt.profile.name,try ComparisonProfileRepository(database:db).profile(id:1)?.name)
        XCTAssertEqual(receipt.profile.revision,comparison.profileVersion)
    }
    func testCompletionHeadersIssuesNullBlobAndIntegerExtremesRemainFrozen() throws {
        let (l,r) = try pair { l,_ in
            try self.db.execute("UPDATE snapshots SET user_note='',root_metadata_signature=X'00FF',root_subtree_signature=X'',filesystem_features_json=NULL,duration_ms=? WHERE id=?",bindings:[.integer(Int64.max),.integer(l.rawValue)])
            try self.db.execute("INSERT INTO scan_issues(snapshot_id,entry_id,relative_path,error_domain,error_code,severity,source,message,was_skipped,created_at) VALUES (?,11,'',NULL,?,'warning','reader','Synthetic metadata only',1,'then')",bindings:[.integer(l.rawValue),.integer(Int64.min)])
            try self.db.execute("INSERT INTO scan_issues(snapshot_id,entry_id,relative_path,error_domain,error_code,severity,source,message,was_skipped,created_at) VALUES (?,NULL,'missing','synthetic',NULL,'info','scanner','',0,'then')",bindings:[.integer(l.rawValue)])
        }
        let result = try run(l,r)
        let repo = ComparisonCompletionReceiptRepository(database:db)
        let first = try XCTUnwrap(repo.receipt(comparisonID:result.id))
        XCTAssertEqual(first.left.header["volume_display_name_at_capture"],.null)
        XCTAssertEqual(first.left.header["duration_ms"],.integer(Int64.max))
        XCTAssertEqual(first.left.header["root_metadata_signature"],.blob(Data([0,255])))
        XCTAssertEqual(first.left.header["root_subtree_signature"],.blob(Data()))
        XCTAssertEqual(first.left.header["user_note"],.text(""))
        XCTAssertEqual(first.left.issues[0]["error_code"],.integer(Int64.min))
        XCTAssertEqual(first.left.issues[0]["entry_id"],.integer(11))
        XCTAssertEqual(first.left.issues[1]["entry_id"],.null)
        XCTAssertEqual(try ComparisonCompletionReceipt.decode(first.encoded()),first)
        try db.execute("UPDATE snapshots SET display_name='later',user_note='later',total_files=999,warning_count=999,filesystem_features_json='{}' WHERE id=?",bindings:[.integer(l.rawValue)])
        try db.execute("UPDATE scan_issues SET message='later',entry_id=NULL WHERE snapshot_id=?",bindings:[.integer(l.rawValue)])
        try db.execute("DELETE FROM scan_issues WHERE snapshot_id=?",bindings:[.integer(l.rawValue)])
        try db.execute("UPDATE volumes SET display_name='current registry changed'")
        XCTAssertEqual(try repo.receipt(comparisonID:result.id),first)
        db.close(); db = try CatalogDatabase(url:directory.appendingPathComponent("catalog.sqlite"))
        XCTAssertEqual(try ComparisonCompletionReceiptRepository(database:db).receipt(comparisonID:result.id),first)
        try healthy()
    }
    func testCancelledAndFailedComparisonsHaveNoSuccessfulReceipt() throws {
        let (l,r) = try pair()
        for phase in ["Matching","Finalizing"] {
            let token = ComparisonCancellationToken()
            XCTAssertThrowsError(try run(l,r,token:token) { if $0.phase == phase { token.cancel() } }) { XCTAssertEqual($0 as? ComparisonError,.cancelled) }
        }
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM comparison_completion_receipts")?.int64Value,0)
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM comparisons WHERE status='cancelled'")?.int64Value,2)
        try healthy()
    }
    func testReceiptWriteAndTerminalTransitionFailuresRollbackWithoutErasingResults() throws {
        let (l,r) = try pair()
        for trigger in [
            "BEFORE INSERT ON comparison_completion_receipts",
            "AFTER INSERT ON comparison_completion_receipts",
            "BEFORE UPDATE OF status ON comparisons WHEN NEW.status='complete'",
            "AFTER UPDATE OF status ON comparisons WHEN NEW.status='complete'"
        ] {
            try db.execute("CREATE TRIGGER synthetic_failure \(trigger) BEGIN SELECT RAISE(ABORT,'synthetic failure'); END")
            XCTAssertThrowsError(try run(l,r))
            XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM comparisons WHERE status='complete'")?.int64Value,0)
            XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM comparison_completion_receipts")?.int64Value,0)
            let last = try XCTUnwrap(db.query("SELECT id,status,matched_count FROM comparisons ORDER BY id DESC LIMIT 1").first)
            XCTAssertEqual(last["status"]?.stringValue,"failed")
            XCTAssertEqual(last["matched_count"]?.int64Value,1)
            XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM comparison_results WHERE comparison_id=?",bindings:[last["id"]!])?.int64Value,1)
            try db.execute("DROP TRIGGER synthetic_failure")
            try healthy()
        }
        let success = try run(l,r)
        XCTAssertNotNil(try ComparisonCompletionReceiptRepository(database:db).receipt(comparisonID:success.id))
    }
    func testMissingStaleOrTerminalTargetCannotBeCompletedOrBackfilled() throws {
        let (l,r) = try pair()
        let history = SnapshotHistoryRepository(database:db)
        let left = try XCTUnwrap(history.summary(id:l)); let right = try XCTUnwrap(history.summary(id:r))
        let profile = try XCTUnwrap(ComparisonProfileRepository(database:db).profile(id:1))
        let selection = ComparisonEngine.selectedKey(left:left,right:right)
        let repo = ComparisonCompletionReceiptRepository(database:db)
        func complete(_ id:ComparisonID) throws { try repo.complete(comparisonID:id,profile:profile,key:selection.column,warnings:selection.warnings,leftUsed:left,rightUsed:right) }
        XCTAssertThrowsError(try complete(ComparisonID(rawValue:999)))
        let result = try run(l,r)
        let first = try XCTUnwrap(repo.receipt(comparisonID:result.id))
        XCTAssertThrowsError(try complete(result.id))
        XCTAssertEqual(try repo.receipt(comparisonID:result.id),first)
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM comparison_completion_receipts")?.int64Value,1)
        XCTAssertThrowsError(try db.execute("UPDATE comparison_completion_receipts SET completed_at='changed'"))
        XCTAssertThrowsError(try db.execute("DELETE FROM comparison_completion_receipts"))
        for column in ["profile_id=2","profile_version=99","completed_at='other'","started_at='other'","id=88","created_at='other'"] { XCTAssertThrowsError(try db.execute("UPDATE comparisons SET \(column) WHERE id=?",bindings:[.integer(result.id.rawValue)])) }
        XCTAssertThrowsError(try db.execute("UPDATE comparison_receipt_catalog SET generation='00000000-0000-0000-0000-000000000000'"))
        XCTAssertThrowsError(try db.execute("DELETE FROM comparison_receipt_catalog"))
        try db.execute("DELETE FROM comparisons WHERE id=?",bindings:[.integer(result.id.rawValue)])
        XCTAssertNil(try repo.receipt(comparisonID:result.id))
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM snapshots")?.int64Value,2)
        try healthy()
    }
    func testMissingOrMalformedProfileFactsFailBeforeSuccessfulComparison() throws {
        let (l,r) = try pair()
        for sql in ["ignore_rules_json='not JSON'","ignore_rules_json='[1]'","name=CAST(X'FF' AS TEXT)","name='a'||char(0)||'b'","timestamp_tolerance_seconds=-1","compare_item_type=2","ignore_rules_json=NULL"] {
            do {
                let original = try XCTUnwrap(db.query("SELECT * FROM comparison_profiles WHERE id=1").first)
                if sql.hasSuffix("NULL") { XCTAssertThrowsError(try db.execute("UPDATE comparison_profiles SET \(sql) WHERE id=1")); continue }
                try db.execute("UPDATE comparison_profiles SET \(sql) WHERE id=1")
                XCTAssertThrowsError(try run(l,r))
                for (key,value) in original { try db.execute("UPDATE comparison_profiles SET \(key)=? WHERE id=1",bindings:[value]) }
            }
        }
        // Unrelated invalid profile cannot poison a selected valid profile.
        try db.execute("UPDATE comparison_profiles SET ignore_rules_json='bad' WHERE id=2")
        XCTAssertNoThrow(try run(l,r))
        XCTAssertThrowsError(try ComparisonEngine(database:db).compare(leftSnapshotID:l,rightSnapshotID:r,profileID:999))
    }
    func testOversizedInvalidUTF8AndCrossSideIssueEvidenceFailClosed() throws {
        for (i,sql) in [
            "UPDATE snapshots SET user_note=? WHERE id=1",
            "UPDATE snapshots SET user_note=CAST(X'FF' AS TEXT) WHERE id=1",
            "UPDATE snapshots SET root_metadata_signature=zeroblob(65537) WHERE id=1",
            "UPDATE snapshots SET user_note='a'||char(0)||'b' WHERE id=1",
            "UPDATE scan_issues SET message=?",
            "UPDATE scan_issues SET entry_id=12"
        ].enumerated() {
            let (l,r) = try pair { l,_ in
                try self.db.execute("INSERT INTO scan_issues(snapshot_id,entry_id,relative_path,severity,message,was_skipped,created_at) VALUES (?,11,'','warning','synthetic',0,'then')",bindings:[.integer(l.rawValue)])
            }
            try db.execute(sql,bindings:sql.contains("?") ? [.text(String(repeating:"x",count:65537))] : [])
            XCTAssertThrowsError(try run(l,r),"negative fixture \(i)")
            XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM comparison_completion_receipts")?.int64Value,0)
            db.close(); try FileManager.default.removeItem(at:directory)
            db = try CatalogDatabase(url:directory.appendingPathComponent("catalog.sqlite"),schemaURL:CatalogSchemaFixture.canonicalSchemaURL)
        }
    }
    func testInvalidNoncanonicalAndContradictorySerializedReceiptsReject() throws {
        let (l,r) = try pair { l,_ in
            try self.db.execute("INSERT INTO scan_issues(snapshot_id,relative_path,severity,message,created_at) VALUES (?,'','info','synthetic','then')",bindings:[.integer(l.rawValue)])
        }
        let result = try run(l,r)
        let receipt = try XCTUnwrap(ComparisonCompletionReceiptRepository(database:db).receipt(comparisonID:result.id))
        let data = try receipt.encoded()
        XCTAssertThrowsError(try ComparisonCompletionReceipt.decode(Data()))
        XCTAssertThrowsError(try ComparisonCompletionReceipt.decode(Data(repeating:1,count:ComparisonCompletionReceipt.maximumBytes+1)))
        XCTAssertThrowsError(try ComparisonCompletionReceipt.decode(Data("{}".utf8)))
        for replacement in [("\"version\":1","\"version\":99"),("\"resultRows\":1","\"resultRows\":2"),("\"status\":\"complete\"","\"status\":\"failed\""),("\"matched\":1","\"matched\":9223372036854775807")] {
            let text = String(decoding:data,as:UTF8.self).replacingOccurrences(of:replacement.0,with:replacement.1)
            XCTAssertThrowsError(try ComparisonCompletionReceipt.decode(Data(text.utf8)))
        }
        for missing in ["profile","side","issue","null-field"] {
            var object = try XCTUnwrap(JSONSerialization.jsonObject(with:data) as? [String:Any])
            if missing == "profile" { object.removeValue(forKey:"profile") }
            else if missing == "side" { object.removeValue(forKey:"right") }
            else {
                var side = try XCTUnwrap(object["left"] as? [String:Any])
                if missing == "issue" {
                    var issues = try XCTUnwrap(side["issues"] as? [[String:Any]])
                    issues[0].removeValue(forKey:"entry_id"); side["issues"] = issues
                } else {
                    var header = try XCTUnwrap(side["header"] as? [String:Any])
                    header.removeValue(forKey:"volume_display_name_at_capture"); side["header"] = header
                }
                object["left"] = side
            }
            let invalid = try JSONSerialization.data(withJSONObject:object,options:[.sortedKeys,.withoutEscapingSlashes])
            XCTAssertThrowsError(try ComparisonCompletionReceipt.decode(invalid),missing)
        }
        XCTAssertThrowsError(try ComparisonCompletionReceipt.decode(data+Data([32])))
    }
    func testFinalizationRejectsMissingResultsRatherThanFabricatingClosure() throws {
        let (l,r) = try pair()
        XCTAssertThrowsError(try run(l,r) { progress in
            if progress.phase == "Finalizing" { try! self.db.execute("DELETE FROM comparison_results") }
        })
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM comparisons WHERE status='complete'")?.int64Value,0)
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM comparison_completion_receipts")?.int64Value,0)
    }
    func testAtomicVisibilityAndUnchangedProtectedRows() throws {
        let (l,r) = try pair()
        let protected = CatalogMigrations.ExpectedState.tables.filter { !["comparisons","comparison_results","comparison_collision_groups","comparison_collision_members","comparison_completion_receipts"].contains($0) }
        let before = try protected.map { try db.query("SELECT * FROM \($0) ORDER BY rowid") }
        let peer = try CatalogDatabase(url:directory.appendingPathComponent("catalog.sqlite")); defer { peer.close() }
        let result = try run(l,r) { p in
            if p.phase == "Finalizing" {
                XCTAssertEqual(try! peer.scalar("SELECT COUNT(*) FROM comparisons WHERE status='complete'")?.int64Value,0)
                XCTAssertEqual(try! peer.scalar("SELECT COUNT(*) FROM comparison_completion_receipts")?.int64Value,0)
            }
        }
        XCTAssertEqual(try protected.map { try db.query("SELECT * FROM \($0) ORDER BY rowid") },before)
        XCTAssertEqual(try peer.scalar("SELECT COUNT(*) FROM comparisons WHERE status='complete'")?.int64Value,1)
        XCTAssertEqual(try peer.scalar("SELECT COUNT(*) FROM comparison_completion_receipts")?.int64Value,1)
        XCTAssertNotNil(try ComparisonCompletionReceiptRepository(database:peer).receipt(comparisonID:result.id))
        try healthy()
    }
    func testTransientWorkspaceDisposalStillCascadesReceiptThenSnapshot() throws {
        let l = try SyntheticSnapshot.createSnapshot(database:db,volumeID:1,session:1,kind:.transient)
        let r = try SyntheticSnapshot.createSnapshot(database:db,volumeID:1,session:2)
        try SyntheticSnapshot.insertEntries(database:db,snapshotID:l,entries:[SyntheticSnapshot.root(id:11)])
        try SyntheticSnapshot.insertEntries(database:db,snapshotID:r,entries:[SyntheticSnapshot.root(id:12)])
        try SyntheticSnapshot.complete(database:db,snapshotID:l); try SyntheticSnapshot.complete(database:db,snapshotID:r)
        let result = try run(l,r)
        XCTAssertNotNil(try ComparisonCompletionReceiptRepository(database:db).receipt(comparisonID:result.id))
        try TransientSnapshotLifecycle(database:db).closeWorkspace()
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM comparison_completion_receipts")?.int64Value,0)
        XCTAssertNil(try SnapshotHistoryRepository(database:db).summary(id:l))
        XCTAssertNotNil(try SnapshotHistoryRepository(database:db).summary(id:r))
        try healthy()
    }

    func testCommitFailureRollsBackReceiptAndCompleteStatus() throws {
        let (l,r) = try pair()
        try db.execute("CREATE TABLE synthetic_deferred(id INTEGER REFERENCES snapshots(id) DEFERRABLE INITIALLY DEFERRED)")
        try db.execute("CREATE TRIGGER synthetic_commit_failure AFTER UPDATE OF status ON comparisons WHEN NEW.status='complete' BEGIN INSERT INTO synthetic_deferred VALUES (999999); END")
        XCTAssertThrowsError(try run(l,r))
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM comparison_completion_receipts")?.int64Value,0)
        XCTAssertEqual(try db.scalar("SELECT status FROM comparisons")?.stringValue,"failed")
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM synthetic_deferred")?.int64Value,0)
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM comparison_results")?.int64Value,1)
        try healthy()
    }
    func testTypedSQLFunctionRejectsMalformedPayloadAndContradictoryBindings() throws {
        let (l,r) = try pair(); let result = try run(l,r)
        let stored = try XCTUnwrap(db.query("SELECT * FROM comparison_completion_receipts WHERE comparison_id=?",bindings:[.integer(result.id.rawValue)]).first)
        let columns = ["payload","comparison_id","catalog_generation","completion_token","receipt_version","encoding","completed_at","left_snapshot_id","right_snapshot_id","profile_id","profile_revision","matched_count","added_count","removed_count","changed_count","uncertain_count"]
        let values = columns.map { stored[$0]! }
        let query = "SELECT fsd_completion_receipt_valid(" + Array(repeating:"?",count:16).joined(separator:",") + ")"
        XCTAssertEqual(try db.scalar(query,bindings:values)?.int64Value,1)
        for i in 0..<16 {
            var invalid = values
            switch values[i] {
            case .integer(let n): invalid[i] = .integer(n+1)
            case .text: invalid[i] = .text("invalid")
            case .blob: invalid[i] = .blob(Data("{}".utf8))
            default: XCTFail("unexpected binding")
            }
            XCTAssertEqual(try db.scalar(query,bindings:invalid)?.int64Value,0,"binding \(i)")
        }
        var oversized = values; oversized[0] = .blob(Data(repeating:0,count:8388609))
        XCTAssertEqual(try db.scalar(query,bindings:oversized)?.int64Value,0)
        try db.execute("INSERT INTO comparisons(left_snapshot_id,right_snapshot_id,profile_id,status,started_at,created_at) VALUES (?,?,1,'running','then','then')",bindings:[.integer(l.rawValue),.integer(r.rawValue)])
        let next = try db.lastInsertRowID()
        var insert = stored; insert["comparison_id"] = .integer(next); insert["payload"] = .blob(Data("{}".utf8)); insert["completion_token"] = .text(UUID().uuidString)
        let names = stored.keys.sorted()
        XCTAssertThrowsError(try db.execute("INSERT INTO comparison_completion_receipts("+names.joined(separator:",")+") VALUES ("+names.map { _ in "?" }.joined(separator:",")+")",bindings:names.map { insert[$0]! }))
        XCTAssertEqual(try db.scalar("SELECT status FROM comparisons WHERE id=?",bindings:[.integer(next)])?.stringValue,"running")
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM comparison_completion_receipts")?.int64Value,1)
        XCTAssertThrowsError(try db.execute("UPDATE comparisons SET status='complete' WHERE id=?",bindings:[.integer(next)]))
        XCTAssertThrowsError(try db.execute("INSERT INTO comparisons(profile_id,status,started_at,created_at) VALUES (1,'complete','then','then')"))
        try healthy()
    }
    func testSizeAndCardinalityLimitsFailWithoutTruncation() throws {
        let (l,r) = try pair { l,_ in
            try self.db.execute("WITH RECURSIVE n(x) AS (VALUES(1) UNION ALL SELECT x+1 FROM n WHERE x<10001) INSERT INTO scan_issues(snapshot_id,relative_path,severity,message,created_at) SELECT ?,'','info','synthetic','then' FROM n",bindings:[.integer(l.rawValue)])
        }
        XCTAssertThrowsError(try run(l,r))
        try db.execute("DELETE FROM scan_issues")
        // Per-field values fit, but the complete receipt exceeds its total budget.
        try db.execute("UPDATE snapshots SET user_note=? WHERE id=?",bindings:[.text(String(repeating:"x",count:65536)),.integer(l.rawValue)])
        let valid = try run(l,r)
        XCTAssertNotNil(try ComparisonCompletionReceiptRepository(database:db).receipt(comparisonID:valid.id))
        // Completed-capture INSERT remains guarded; generate a fresh scanning pair.
        let a = try SyntheticSnapshot.createSnapshot(database:db,volumeID:1,session:3)
        let b = try SyntheticSnapshot.createSnapshot(database:db,volumeID:1,session:4)
        try SyntheticSnapshot.insertEntries(database:db,snapshotID:a,entries:[SyntheticSnapshot.root(id:21)])
        try SyntheticSnapshot.insertEntries(database:db,snapshotID:b,entries:[SyntheticSnapshot.root(id:22)])
        try db.execute("WITH RECURSIVE n(x) AS (VALUES(1) UNION ALL SELECT x+1 FROM n WHERE x<130) INSERT INTO scan_issues(snapshot_id,relative_path,severity,message,created_at) SELECT ?,'','info',?,'then' FROM n",bindings:[.integer(a.rawValue),.text(String(repeating:"x",count:65536))])
        try SyntheticSnapshot.complete(database:db,snapshotID:a); try SyntheticSnapshot.complete(database:db,snapshotID:b)
        XCTAssertThrowsError(try run(a,b))
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM comparison_completion_receipts")?.int64Value,1)
    }
    func testReusedNumericComparisonIDGetsDistinctCompletionToken() throws {
        let (l,r) = try pair(); let first = try run(l,r)
        let repo = ComparisonCompletionReceiptRepository(database:db)
        let a = try XCTUnwrap(repo.receipt(comparisonID:first.id))
        try ComparisonResultRepository(database:db).deleteComparison(first.id)
        let second = try run(l,r)
        let b = try XCTUnwrap(repo.receipt(comparisonID:second.id))
        XCTAssertEqual(first.id,second.id,"SQLite may reuse the disposed highest integer ID")
        XCTAssertEqual(a.catalogGeneration,b.catalogGeneration)
        XCTAssertNotEqual(a.completionToken,b.completionToken)
        XCTAssertEqual(a.closure.counts,b.closure.counts)
        XCTAssertEqual(a.closure.resultRows,b.closure.resultRows)
        XCTAssertEqual(a.closure.leftEntries,b.closure.leftEntries)
        XCTAssertEqual(a.closure.rightEntries,b.closure.rightEntries)
    }
    func testSelectedPoliciesAndAllResultKindsHaveVersionedClosure() throws {
        let (l,r) = try pair { l,r in
            try self.db.execute("UPDATE comparison_profiles SET ignore_rules_json='[\"ignored\"]' WHERE id=1")
            try SyntheticSnapshot.insertEntries(database:self.db,snapshotID:l,entries:[
                .init(id:31,parentID:11,relativePath:"removed",name:"removed"),
                .init(id:32,parentID:11,relativePath:"changed",name:"changed",logicalSizeBytes:1),
                .init(id:33,parentID:11,relativePath:"ignored",name:"ignored"),
                .init(id:34,parentID:11,relativePath:"A",name:"A"),
                .init(id:35,parentID:11,relativePath:"a",name:"a")])
            try SyntheticSnapshot.insertEntries(database:self.db,snapshotID:r,entries:[
                .init(id:41,parentID:12,relativePath:"added",name:"added"),
                .init(id:42,parentID:12,relativePath:"changed",name:"changed",logicalSizeBytes:2),
                .init(id:43,parentID:12,relativePath:"ignored",name:"ignored"),
                .init(id:44,parentID:12,relativePath:"A",name:"A")])
        }
        let result = try run(l,r)
        let receipt = try XCTUnwrap(ComparisonCompletionReceiptRepository(database:db).receipt(comparisonID:result.id))
        XCTAssertEqual(receipt.closure.counts,["matched":1,"added":1,"removed":1,"changed":1,"uncertain":1,"ignored":2])
        XCTAssertEqual(receipt.closure.collisionGroups,1); XCTAssertEqual(receipt.closure.collisionMembers,3)
        XCTAssertEqual(receipt.closure.leftEntries,6); XCTAssertEqual(receipt.closure.rightEntries,5)
        let plan = try db.query("EXPLAIN QUERY PLAN SELECT id FROM comparison_results WHERE comparison_id=? AND id>? ORDER BY id LIMIT 256",bindings:[.integer(result.id.rawValue),.integer(0)])
        XCTAssertTrue(plan.compactMap { $0["detail"]?.stringValue }.contains { $0.contains("INDEX") && !$0.contains("TEMP B-TREE") })
        for side in [ComparisonCompletionReceiptRepository.CompletionSide.left,.right] {
            let coverage = try db.query("EXPLAIN QUERY PLAN "+ComparisonCompletionReceiptRepository.coverageSQL(side:side),bindings:[.integer(l.rawValue),.integer(result.id.rawValue),.integer(result.id.rawValue)])
            let details = coverage.compactMap { $0["detail"]?.stringValue }
            XCTAssertFalse(details.contains { $0.contains("TEMP B-TREE") || $0.contains("SCAN r") || $0.contains("SCAN m") })
            XCTAssertTrue(details.contains { $0.contains("idx_receipt_member_entry") })
            XCTAssertTrue(details.contains { $0.contains("idx_receipt_results_") })
        }
    }
}
