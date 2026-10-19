import AppKit
import ScreenCaptureKit
import SwiftUI
import XCTest
@testable import FSD

@MainActor
final class SavedComparisonUITests: XCTestCase {
    private var directory: URL!
    private var db: CatalogDatabase!
    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("FSD-task063-\(UUID())")
        db = try CatalogDatabase(url:directory.appendingPathComponent("catalog.sqlite"),schemaURL:CatalogSchemaFixture.canonicalSchemaURL)
    }
    override func tearDownWithError() throws { db?.close(); try? FileManager.default.removeItem(at:directory) }
    private func settle(_ condition: () -> Bool, timeout: TimeInterval = 30, file: StaticString = #filePath, line: UInt = #line) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline { RunLoop.current.run(until:Date().addingTimeInterval(0.01)) }
        XCTAssertTrue(condition(),"Async UI operation did not settle",file:file,line:line)
    }
    private func record(_ receipt: ComparisonCompletionReceipt) throws -> ComparisonRecord {
        try XCTUnwrap(ComparisonResultRepository(database:db).listComparisons().first { $0.id.rawValue == receipt.comparisonID })
    }
    private func prepare(_ model: SavedComparisonsModel, _ receipt: ComparisonCompletionReceipt) throws {
        model.prepare(try record(receipt)); settle { model.eligibility != .checking }
    }
    private func saved(_ model: SavedComparisonsModel) throws -> UUID {
        model.save(); settle { !model.isSaving }
        if case .saved(let id) = model.eligibility { return id }
        XCTFail(model.saveError ?? "No saved artifact"); throw SavedComparisonError.notFound
    }
    private func healthy() throws {
        XCTAssertEqual(try db.scalar("PRAGMA foreign_keys")?.int64Value,1)
        XCTAssertTrue(try db.query("PRAGMA foreign_key_check").isEmpty)
        XCTAssertEqual(try db.scalar("PRAGMA integrity_check")?.stringValue,"ok")
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
    func testRecentHistoryIsNotLabelledDurableSavedHistory() throws {
        let root = CatalogSchemaFixture.canonicalSchemaURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf:root.appendingPathComponent("FSD/UI/ComparisonCreationView.swift"),encoding:.utf8)
        XCTAssertFalse(source.contains("Saved comparison history"), "Recent comparisons include disposable transient work")
    }
    func testExplicitSaveDoubleClickRetryAndFreshModelDiscoverSameOperation() throws {
        let (receipt,_,_) = try make()
        let workspace = ComparisonWorkspaceModel(database:db)
        workspace.refresh(); workspace.openComparison(try record(receipt))
        settle { workspace.savedComparisons.eligibility != .checking }
        XCTAssertEqual(try db.scalar("SELECT count(*) FROM saved_comparisons")?.int64Value,0)
        let model = workspace.savedComparisons
        let operation = try XCTUnwrap(model.operationID)
        model.save(); model.save(); settle { !model.isSaving }
        let id = try XCTUnwrap(try SavedComparisonRepository(database:db).list().first)
        XCTAssertEqual(try db.scalar("SELECT count(*) FROM saved_operations")?.int64Value,1)
        XCTAssertEqual(model.operationID,operation)
        let fresh = SavedComparisonsModel(database:db); try prepare(fresh,receipt)
        XCTAssertEqual(fresh.eligibility,.saved(id)); XCTAssertEqual(fresh.operationID,operation)
        fresh.save()
        XCTAssertEqual(try db.scalar("SELECT count(*) FROM saved_operations")?.int64Value,1)
        workspace.closeComparison()
        settle { !workspace.isClosing }
        XCTAssertEqual(try SavedComparisonRepository(database:db).list(),[id])
        try healthy()
    }
    func testFailedSaveRetryKeepsOperationAndDoesNotClaimSuccess() throws {
        let (receipt,_,_) = try make(); let repo = SavedComparisonRepository(database:db)
        repo.checkpointObserver = { if $0 == "left_entries" { throw SavedComparisonError.corrupt("injected copy failure") } }
        let model = SavedComparisonsModel(database:db,repository:repo); try prepare(model,receipt)
        let operation = model.operationID
        model.save(); settle { !model.isSaving }
        XCTAssertNotNil(model.saveError); XCTAssertNil(model.saveMessage)
        XCTAssertTrue(try repo.list().isEmpty)
        XCTAssertEqual(model.operationID,operation)
        repo.checkpointObserver = nil
        let id = try saved(model)
        XCTAssertEqual(try repo.operations(for:receipt).map(\.id),[operation!])
        let fresh = SavedComparisonsModel(database:db); try prepare(fresh,receipt)
        XCTAssertEqual(fresh.eligibility,.saved(id))
    }
    func testUncertainCommittedOutcomeIsDiscoveredAfterFileReopen() throws {
        let (receipt,_,_) = try make()
        let operation = SavedComparisonsModel.operationID(receipt:receipt,deleted:[])
        let id = try SavedComparisonRepository(database:db).save(.init(operationID:operation,receipt:receipt))
        let url = db.url; db.close(); db = try CatalogDatabase(url:url,schemaURL:CatalogSchemaFixture.canonicalSchemaURL)
        let fresh = SavedComparisonsModel(database:db); try prepare(fresh,receipt)
        XCTAssertEqual(fresh.operationID,operation); XCTAssertEqual(fresh.eligibility,.saved(id))
        fresh.reloadLibrary(); settle { !fresh.libraryLoading }
        XCTAssertEqual(fresh.summaries.map(\.id),[id]); fresh.save()
        XCTAssertEqual(try db.scalar("SELECT count(*) FROM saved_operations")?.int64Value,1)
        try healthy()
    }
    func testLegacyAndNonCompleteComparisonsExplainIneligibility() throws {
        let (receipt,l,r) = try make()
        for state in ["running","failed","cancelled"] {
            try db.execute("INSERT INTO comparisons(left_snapshot_id,right_snapshot_id,profile_id,status,started_at,created_at) VALUES (?,?,1,?,'then','then')",bindings:[.integer(l.rawValue),.integer(r.rawValue),.text(state)])
            let record = try XCTUnwrap(ComparisonResultRepository(database:db).listComparisons().first { $0.id.rawValue != receipt.comparisonID && $0.status.rawValue == state })
            let model = SavedComparisonsModel(database:db); model.prepare(record)
            if case .unavailable(let reason) = model.eligibility { XCTAssertTrue(reason.contains(state)) } else { XCTFail() }
            model.save(); XCTAssertFalse(model.isSaving)
        }
        // Simulate a pre-v12 complete record; do not fabricate any receipt.
        try db.execute("DROP TRIGGER trg_receipts_no_delete")
        try db.execute("DELETE FROM comparison_completion_receipts WHERE comparison_id=?",bindings:[.integer(receipt.comparisonID)])
        let legacy = SavedComparisonsModel(database:db); try prepare(legacy,receipt)
        if case .unavailable(let reason) = legacy.eligibility { XCTAssertTrue(reason.contains("no validated completion receipt")) } else { XCTFail() }
        legacy.save(); XCTAssertTrue(try SavedComparisonRepository(database:db).list().isEmpty)
    }
    func testNoImplicitSaveOnLaunchBrowseOrUnsavedLiveClose() throws {
        let (receipt,l,r) = try make((.transient,.transient))
        let workspace = ComparisonWorkspaceModel(database:db)
        workspace.refresh(); workspace.openComparison(try record(receipt))
        settle { workspace.savedComparisons.eligibility != .checking }
        workspace.savedComparisons.reloadLibrary(); settle { !workspace.savedComparisons.libraryLoading }
        XCTAssertTrue(workspace.savedComparisons.summaries.isEmpty)
        workspace.closeComparison()
        settle { !workspace.isClosing }
        XCTAssertTrue(try SavedComparisonRepository(database:db).list().isEmpty)
        XCTAssertNil(try db.scalar("SELECT id FROM snapshots WHERE id IN (?,?)",bindings:[.integer(l.rawValue),.integer(r.rawValue)]))
    }
    func testOfflineReaderAfterActualWorkspaceCloseAndOriginalDeletion() throws {
        let (receipt,l,r) = try make((.transient,.transient))
        let workspace = ComparisonWorkspaceModel(database:db); workspace.refresh(); workspace.openComparison(try record(receipt))
        settle { workspace.savedComparisons.eligibility != .checking }
        let id = try saved(workspace.savedComparisons)
        workspace.closeComparison()
        settle { !workspace.isClosing }
        XCTAssertNil(try db.scalar("SELECT id FROM snapshots WHERE id IN (?,?)",bindings:[.integer(l.rawValue),.integer(r.rawValue)]))
        XCTAssertEqual(try db.scalar("SELECT count(*) FROM comparisons")?.int64Value,0)
        try db.execute("DELETE FROM volumes"); try db.execute("DELETE FROM comparison_profiles")
        let url = db.url; db.close(); db = try CatalogDatabase(url:url,schemaURL:CatalogSchemaFixture.canonicalSchemaURL)
        let offline = SavedComparisonsModel(database:db); offline.reloadLibrary(); settle { !offline.libraryLoading }
        XCTAssertEqual(offline.summaries.map(\.id),[id]); offline.open(id)
        settle { !offline.readerLoading }; XCTAssertNil(offline.readerError)
        XCTAssertEqual(offline.receipt,receipt)
        XCTAssertEqual(Set(offline.rows.compactMap { $0.original["result_type"]?.text }),Set(ComparisonResultType.allCases.map(\.rawValue)))
        let changed = try XCTUnwrap(offline.rows.first { $0.original["result_type"]?.text == "changed" })
        offline.select(changed); settle { offline.selectedLeft != nil && offline.selectedRight != nil }
        XCTAssertEqual(offline.selectedLeft?.original["logical_size_bytes"],.integer(1))
        XCTAssertEqual(offline.selectedRight?.original["logical_size_bytes"],.integer(2))
        offline.pageKind = .left; settle { !offline.readerLoading }
        let special = try XCTUnwrap(offline.rows.first { $0.original["id"]?.integer == 108 })
        offline.select(special); settle { offline.selectedLeft != nil }
        XCTAssertEqual(offline.selectedLeft?.original["resource_identifier"],.blob(Data([0,255,0])))
        XCTAssertEqual(offline.selectedLeft?.original["allocated_size_bytes"],.integer(Int64.min))
        XCTAssertNil(offline.selectedRight)
        try healthy()
    }
    func testFrozenProfileWarningsSummaryAndMissingSideDetails() throws {
        let (receipt,_,_) = try make(); let model = SavedComparisonsModel(database:db); try prepare(model,receipt)
        try db.execute("UPDATE comparison_profiles SET name='CURRENT NOT EXECUTED' WHERE id=1")
        try db.execute("UPDATE snapshots SET user_note='current not frozen'")
        let id = try saved(model); model.open(id); settle { !model.readerLoading }
        XCTAssertEqual(model.receipt,receipt); XCTAssertNotEqual(model.receipt?.profile.name,"CURRENT NOT EXECUTED")
        XCTAssertFalse(try XCTUnwrap(model.receipt).warnings.isEmpty)
        let added = try XCTUnwrap(model.rows.first { $0.original["result_type"]?.text == "added" })
        model.select(added); settle { model.selectedRight != nil }
        XCTAssertNil(model.selectedLeft); XCTAssertEqual(model.selectedRight?.original["name"]?.text,"added")
        XCTAssertEqual(SavedComparisonDetailView.value(.integer(Int64.max)),"9223372036854775807")
        XCTAssertEqual(SavedComparisonDetailView.value(.null),"NULL")
        XCTAssertEqual(SavedComparisonDetailView.value(.blob(Data())),"BLOB (0 bytes), base64: ")
    }
    func testPagedResultsSidesCollisionsIssuesAndEmptyCategory() throws {
        let (receipt,_,_) = try make(rich:false,beforeComplete:{ l,r in
            let left = (0..<600).map { SyntheticSnapshot.SeedEntry(id:Int64(1000+$0),parentID:101,relativePath:"f\($0)",name:"f\($0)") }
            let right = (0..<600).map { SyntheticSnapshot.SeedEntry(id:Int64(2000+$0),parentID:201,relativePath:"f\($0)",name:"f\($0)") }
            try SyntheticSnapshot.insertEntries(database:self.db,snapshotID:l,entries:left)
            try SyntheticSnapshot.insertEntries(database:self.db,snapshotID:r,entries:right)
        })
        let model = SavedComparisonsModel(database:db); try prepare(model,receipt); let id = try saved(model)
        model.open(id); settle { !model.readerLoading }
        XCTAssertEqual(model.rows.count,256); let first = model.rows
        model.nextPage(); settle { !model.readerLoading }; XCTAssertEqual(model.rows.count,256)
        XCTAssertTrue(Set(first.map(\.id)).isDisjoint(with:model.rows.map(\.id)))
        model.nextPage(); settle { !model.readerLoading }; XCTAssertEqual(model.rows.count,89); XCTAssertFalse(model.hasNext)
        model.previousPage(); settle { !model.readerLoading }; XCTAssertEqual(model.pageIndex,1)
        model.pageKind = .left; settle { !model.readerLoading }; XCTAssertEqual(model.pageIndex,0); XCTAssertEqual(model.rows.count,256)
        model.pageKind = .groups; settle { !model.readerLoading }; XCTAssertTrue(model.rows.isEmpty)
        model.pageKind = .members; settle { !model.readerLoading }; XCTAssertTrue(model.rows.isEmpty)
        model.pageKind = .leftIssues; settle { !model.readerLoading }; XCTAssertTrue(model.rows.isEmpty)
    }
    func testCollisionAndIssuePagesExposeUnpairedEvidence() throws {
        let (receipt,_,_) = try make(); let model = SavedComparisonsModel(database:db); try prepare(model,receipt)
        let id = try saved(model); model.open(id); settle { !model.readerLoading }
        model.pageKind = .groups; settle { !model.readerLoading }; XCTAssertFalse(model.rows.isEmpty)
        model.pageKind = .members; settle { !model.readerLoading }
        let member = try XCTUnwrap(model.rows.first { $0.original["side"]?.text == "left" }); XCTAssertNotNil(member.groupID)
        model.select(member); settle { model.selectedLeft != nil }; XCTAssertNil(model.selectedRight)
        model.pageKind = .leftIssues; settle { !model.readerLoading }; XCTAssertEqual(model.rows.count,2)
    }
    func testCancellationAndBudgetErrorsLeaveNoFalseSuccess() throws {
        let (receipt,_,_) = try make(); let model = SavedComparisonsModel(database:db); try prepare(model,receipt)
        let operation = model.operationID
        model.saveLimits.rows = 1; model.save(); settle { !model.isSaving }
        XCTAssertTrue(model.saveError?.contains("100,000 accounted rows") == true)
        XCTAssertNil(model.saveMessage); XCTAssertEqual(model.eligibility,.available)
        model.saveLimits = .init(); model.saveLimits.elapsedSeconds = 0
        model.save(); settle { !model.isSaving }; XCTAssertNotNil(model.saveError)
        XCTAssertEqual(model.operationID,operation)
        XCTAssertTrue(try SavedComparisonRepository(database:db).list().isEmpty)
    }
    func testPendingOriginalBrowserPageCannotBlockMainActorDuringSave() throws {
        let (receipt,_,_) = try make()
        let repo = SavedComparisonRepository(database:db)
        let entered = DispatchSemaphore(value:0), release = DispatchSemaphore(value:0)
        repo.checkpointObserver = { if $0 == "left_entries" { entered.signal(); _ = release.wait(timeout:.now()+2) } }
        let workspace = ComparisonWorkspaceModel(database:db,savedRepository:repo)
        workspace.refresh(); workspace.openComparison(try record(receipt))
        settle { workspace.savedComparisons.eligibility != .checking && workspace.activeBrowser?.isLoading == false }
        let browser = try XCTUnwrap(workspace.activeBrowser)
        browser.loadInitialPage()
        // Let the background page enqueue its main callback while this test's
        // main actor deliberately does not drain the run loop yet.
        Thread.sleep(forTimeInterval:0.05)
        workspace.savedComparisons.save()
        XCTAssertEqual(entered.wait(timeout:.now()+3),.success)
        var heartbeat = false
        DispatchQueue.main.async { heartbeat = true }
        let start = ProcessInfo.processInfo.systemUptime
        settle { heartbeat }
        XCTAssertLessThan(ProcessInfo.processInfo.systemUptime-start,0.5,"Pending original-page callback must not wait on Save's database lock")
        release.signal(); settle { !workspace.savedComparisons.isSaving }
        settle { !browser.isLoading }
        XCTAssertNotNil(browser.currentPage)
        try healthy()
    }

    func testHiddenOriginalBrowserCannotBlockSavedSurfaceOrReturnWhileOpenSettles() throws {
        let (receipt,_,_) = try make()
        let id = try SavedComparisonRepository(database:db).save(.init(operationID:UUID(),receipt:receipt))
        let workspace = ComparisonWorkspaceModel(database:db); workspace.refresh(); workspace.openComparison(try record(receipt))
        settle { workspace.savedComparisons.eligibility != .checking && workspace.activeBrowser?.isLoading == false }
        let browser = try XCTUnwrap(workspace.activeBrowser)
        browser.loadInitialPage(); Thread.sleep(forTimeInterval:0.05)
        workspace.showsSavedComparisons = true
        let entered = DispatchSemaphore(value:0), release = DispatchSemaphore(value:0), database = db!
        DispatchQueue.global().async {
            try? database.transaction { entered.signal(); _ = release.wait(timeout:.now()+2) }
        }
        XCTAssertEqual(entered.wait(timeout:.now()+3),.success)
        // Model an offline open waiting on its serialized catalog connection.
        workspace.savedComparisons.open(id)
        workspace.savedComparisons.closeReader()
        workspace.showsSavedComparisons = false
        var heartbeat = false; DispatchQueue.main.async { heartbeat = true }
        let start = ProcessInfo.processInfo.systemUptime; settle { heartbeat }
        XCTAssertLessThan(ProcessInfo.processInfo.systemUptime-start,0.5,"Hidden original callbacks must not block saved browsing/return while catalog work settles")
        release.signal()
        // Wait for the cancelled reader's catalog operation to leave the queue.
        var idle = false; workspace.savedComparisons.cancelAndWait { idle = true }; settle { idle }
        settle { !browser.isLoading }
        XCTAssertNotNil(browser.currentPage); try healthy()
    }

    func testCloseWhileSavingCancelsWaitsAndDisposesOnlyAfterRollback() throws {
        let (receipt,l,r) = try make((.transient,.transient))
        let repo = SavedComparisonRepository(database:db)
        let entered = DispatchSemaphore(value:0), release = DispatchSemaphore(value:0)
        repo.checkpointObserver = { if $0 == "left_entries" { entered.signal(); _ = release.wait(timeout:.now()+10) } }
        let workspace = ComparisonWorkspaceModel(database:db,savedRepository:repo)
        workspace.refresh(); workspace.openComparison(try record(receipt)); settle { workspace.savedComparisons.eligibility != .checking }
        workspace.savedComparisons.save()
        var didEnter = false
        settle { if !didEnter { didEnter = entered.wait(timeout:.now()) == .success }; return didEnter }
        workspace.closeComparison(); XCTAssertTrue(workspace.isClosing); XCTAssertNotNil(workspace.activeBrowser)
        // Main-actor work executes while SQLite transaction is deliberately held.
        var heartbeat = false; DispatchQueue.main.async { heartbeat = true }; settle { heartbeat }
        release.signal(); settle { !workspace.isClosing && !workspace.savedComparisons.isSaving }
        XCTAssertNil(workspace.activeBrowser)
        XCTAssertTrue(try repo.list().isEmpty)
        XCTAssertTrue(workspace.savedComparisons.saveError?.contains("cancelled") == true)
        XCTAssertNil(try db.scalar("SELECT id FROM snapshots WHERE id IN (?,?)",bindings:[.integer(l.rawValue),.integer(r.rawValue)]))
        try healthy()
    }
    func testCancelArrivingAfterCommitCheckpointStillPreservesCommittedArtifact() throws {
        let (receipt,_,_) = try make((.transient,.transient))
        let repo = SavedComparisonRepository(database:db)
        let entered = DispatchSemaphore(value:0), release = DispatchSemaphore(value:0)
        // precommit observer executes after cancellation check; an arriving
        // cancellation may lose to commit. UI must show actual success.
        repo.checkpointObserver = { if $0 == "precommit" { entered.signal(); _ = release.wait(timeout:.now()+10) } }
        let workspace = ComparisonWorkspaceModel(database:db,savedRepository:repo)
        workspace.refresh(); workspace.openComparison(try record(receipt)); settle { workspace.savedComparisons.eligibility != .checking }
        workspace.savedComparisons.save(); var didEnter = false
        settle { if !didEnter { didEnter = entered.wait(timeout:.now()) == .success }; return didEnter }
        workspace.closeComparison(); release.signal(); settle { !workspace.isClosing && !workspace.savedComparisons.isSaving }
        XCTAssertEqual(try repo.list().count,1)
        if case .saved = workspace.savedComparisons.eligibility {} else { XCTFail() }
        XCTAssertEqual(try db.scalar("SELECT count(*) FROM snapshots")?.int64Value,0)
        try healthy()
    }
    func testConfirmedDeletionTombstoneNewExplicitActionAndUnrelatedPreservation() throws {
        let (receipt,_,_) = try make(); let model = SavedComparisonsModel(database:db); try prepare(model,receipt)
        let oldOperation = try XCTUnwrap(model.operationID), id = try saved(model)
        let repo = SavedComparisonRepository(database:db)
        let unrelated = try repo.save(.init(operationID:UUID(),receipt:receipt))
        let before = try db.query("SELECT * FROM snapshots ORDER BY id")
        model.open(id); settle { !model.readerLoading }
        model.deletionCandidate = id
        XCTAssertEqual(try repo.list().count,2,"Selecting Delete must only request confirmation")
        model.confirmDeletion(); settle { !model.isDeleting && model.eligibility != .checking }
        XCTAssertNil(model.readerID); XCTAssertEqual(try repo.list(),[unrelated])
        XCTAssertEqual(try db.query("SELECT * FROM snapshots ORDER BY id"),before)
        XCTAssertThrowsError(try repo.save(.init(operationID:oldOperation,receipt:receipt))) { XCTAssertEqual($0 as? SavedComparisonError,.deleted) }
        // Any existing exact READY copy suppresses another Save.
        XCTAssertEqual(model.eligibility,.saved(unrelated))
        try repo.delete(id:unrelated); try prepare(model,receipt)
        XCTAssertEqual(model.eligibility,.deleted); model.save(); XCTAssertFalse(model.isSaving)
        let newOperation = try XCTUnwrap(model.operationID); XCTAssertNotEqual(oldOperation,newOperation)
        let fresh = SavedComparisonsModel(database:db); try prepare(fresh,receipt); XCTAssertEqual(fresh.operationID,newOperation)
        fresh.save(asNewAfterDeletion:true); settle { !fresh.isSaving }
        XCTAssertEqual(try repo.list().count,1); XCTAssertFalse(try repo.list().contains(id))
        try healthy()
    }
    func testEmptyLoadingErrorAndCorruptReaderStates() throws {
        let empty = SavedComparisonsModel(database:db); empty.reloadLibrary(); XCTAssertTrue(empty.libraryLoading)
        settle { !empty.libraryLoading }; XCTAssertTrue(empty.summaries.isEmpty); XCTAssertNil(empty.libraryError)
        let (receipt,_,_) = try make(); try prepare(empty,receipt); let id = try saved(empty)
        try db.execute("DROP TRIGGER trg_saved_entries_update")
        try db.execute("UPDATE saved_entries SET payload=X'00' WHERE id=(SELECT min(id) FROM saved_entries)")
        empty.open(id); XCTAssertTrue(empty.readerLoading); settle { !empty.readerLoading }
        XCTAssertNotNil(empty.readerError); XCTAssertNil(empty.receipt); XCTAssertTrue(empty.rows.isEmpty)
        empty.closeReader(); empty.open(UUID()); settle { !empty.readerLoading }; XCTAssertNotNil(empty.readerError)
        db.close(); empty.reloadLibrary(); settle { !empty.libraryLoading }; XCTAssertNotNil(empty.libraryError)
    }
    func testReadOnlyLookupIsExactBoundedAndDoesNotWrite() throws {
        let (receipt,_,_) = try make(rich:false); let repo = SavedComparisonRepository(database:db)
        let id = try repo.save(.init(operationID:UUID(),receipt:receipt))
        let changes = try db.scalar("SELECT total_changes()")
        XCTAssertEqual(try repo.operations(for:receipt).map(\.artifactID),[id])
        XCTAssertEqual(try repo.summaries().map(\.id),[id]); XCTAssertTrue(try repo.summaries(after:id.uuidString).isEmpty)
        let reader = try repo.open(id:id), left = try XCTUnwrap(try repo.open(id:id).entries(side:.left).first)
        XCTAssertEqual(try reader.entry(id:left.id,side:.left),left)
        XCTAssertNil(try reader.entry(id:left.id,side:.right))
        XCTAssertEqual(try db.scalar("SELECT total_changes()"),changes)
        // Valid persistent operations, tombstoned by real delete. No fake rows.
        for _ in 0..<4096 {
            let other = try repo.save(.init(operationID:UUID(),receipt:receipt)); try repo.delete(id:other)
        }
        XCTAssertThrowsError(try repo.operations(for:receipt)) { XCTAssertEqual($0 as? SavedComparisonError,.budgetExceeded("operation discovery")) }
        try healthy()
    }
    func testConcurrentModelsAndTwentyArtifactLibraryPaging() throws {
        let (receipt,_,_) = try make(rich:false)
        let a = SavedComparisonsModel(database:db), b = SavedComparisonsModel(database:db)
        try prepare(a,receipt); try prepare(b,receipt)
        XCTAssertEqual(a.operationID,b.operationID)
        a.save(); b.save(); settle { !a.isSaving && !b.isSaving }
        let repo = SavedComparisonRepository(database:db)
        XCTAssertEqual(try repo.list().count,1)
        for _ in 0..<20 { _ = try repo.save(.init(operationID:UUID(),receipt:receipt)) }
        a.reloadLibrary(); settle { !a.libraryLoading }
        XCTAssertEqual(a.summaries.count,20); XCTAssertTrue(a.libraryHasNext)
        let firstIDs = Set(a.summaries.map(\.id))
        a.nextLibraryPage(); settle { !a.libraryLoading }
        XCTAssertEqual(a.summaries.count,1); XCTAssertFalse(a.libraryHasNext)
        XCTAssertTrue(firstIDs.isDisjoint(with:a.summaries.map(\.id)))
        a.previousLibraryPage(); settle { !a.libraryLoading }
        XCTAssertEqual(Set(a.summaries.map(\.id)),firstIDs)
        let next = try ComparisonEngine(database:db).compare(leftSnapshotID:SnapshotID(rawValue:receipt.left.header["id"]!.integer!),rightSnapshotID:SnapshotID(rawValue:receipt.right.header["id"]!.integer!),profileID:1)
        let different = try XCTUnwrap(ComparisonCompletionReceiptRepository(database:db).receipt(comparisonID:next.id))
        XCTAssertTrue(try repo.operations(for:different).isEmpty)
        try healthy()
    }

    func testLibraryAdaptiveBytePagesAndOrdinaryPageNavigation() throws {
        let (receipt,_,_) = try make(rich:false,beforeComplete:{ l,_ in
            for i in 0..<80 {
                try self.db.execute("INSERT INTO scan_issues(snapshot_id,relative_path,severity,source,message,was_skipped,created_at) VALUES (?,'','info','scanner',?,0,'then')",bindings:[.integer(l.rawValue),.text(String(repeating:"x",count:60000)+String(i))])
            }
        })
        let repo = SavedComparisonRepository(database:db)
        let a = try repo.save(.init(operationID:UUID(),receipt:receipt))
        let b = try repo.save(.init(operationID:UUID(),receipt:receipt))
        XCTAssertGreaterThan(try receipt.encoded().count,4*1024*1024)
        let first = try repo.summaries(); XCTAssertEqual(first.count,1)
        let second = try repo.summaries(after:first[0].id.uuidString); XCTAssertEqual(second.count,1)
        XCTAssertEqual(Set((first+second).map(\.id)),Set([a,b]))
        let model = SavedComparisonsModel(database:db); model.reloadLibrary(); settle { !model.libraryLoading }
        XCTAssertEqual(model.summaries.count,1); XCTAssertTrue(model.libraryHasNext)
        let firstID = model.summaries[0].id
        model.nextLibraryPage(); settle { !model.libraryLoading }; XCTAssertFalse(model.libraryHasNext)
        XCTAssertNotEqual(model.summaries[0].id,firstID)
        model.previousLibraryPage(); settle { !model.libraryLoading }; XCTAssertEqual(model.summaries[0].id,firstID)
        try healthy()
    }

    func testTenThousandEntrySaveKeepsMainActorResponsive() throws {
        let (receipt,_,_) = try make(rich:false,beforeComplete:{ l,r in
            for (snapshot,root,base) in [(l,Int64(101),Int64(1000)),(r,Int64(201),Int64(10000))] {
                for start in stride(from:0,to:4999,by:256) {
                    try SyntheticSnapshot.insertEntries(database:self.db,snapshotID:snapshot,entries:(start..<min(start+256,4999)).map {
                        SyntheticSnapshot.SeedEntry(id:base+Int64($0),parentID:root,relativePath:"file\($0)",name:"file\($0)")
                    })
                }
            }
        })
        let model = SavedComparisonsModel(database:db); try prepare(model,receipt)
        var heartbeats = 0
        let timer = Timer.scheduledTimer(withTimeInterval:0.02,repeats:true) { _ in heartbeats += 1 }
        defer { timer.invalidate() }
        let started = ProcessInfo.processInfo.systemUptime
        let id = try saved(model)
        let duration = ProcessInfo.processInfo.systemUptime-started
        XCTAssertGreaterThan(heartbeats,10)
        print("TASK063_UI_SCALE entries=10000 results=\(receipt.closure.resultRows) save_seconds=\(duration) main_heartbeats=\(heartbeats) artifact=\(id)")
        try healthy()
    }

    func testOwnWindowSaveLibraryOfflineIneligibleErrorScreenshotsAndAccessibility() throws {
        let (receipt,_,_) = try make((.transient,.transient))
        let workspace = ComparisonWorkspaceModel(database:db); workspace.refresh(); workspace.openComparison(try record(receipt))
        settle { workspace.savedComparisons.eligibility != .checking }
        let model = workspace.savedComparisons
        let attribute = NSAccessibility.Attribute(rawValue:"AXEnhancedUserInterface")
        let prior = NSApplication.shared.accessibilityAttributeValue(attribute)
        NSApplication.shared.accessibilitySetValue(true,forAttribute:attribute)
        defer { NSApplication.shared.accessibilitySetValue(prior,forAttribute:attribute) }
        let host = NSHostingView(rootView:AnyView(ComparisonWorkspaceView(model:workspace).preferredColorScheme(.dark)))
        let window = NSWindow(contentRect:NSRect(x:0,y:0,width:1330,height:900),styleMask:[.titled,.resizable],backing:.buffered,defer:false)
        window.title = "FSD Task063 Synthetic"; window.appearance = NSAppearance(named:.darkAqua)
        window.contentView = host; window.makeKeyAndOrderFront(nil)
        defer { window.orderOut(nil) }
        func layout() { host.layoutSubtreeIfNeeded(); RunLoop.current.run(until:Date().addingTimeInterval(0.2)) }
        func elements() -> [NSObject] {
            var values: [NSObject] = [], seen = Set<ObjectIdentifier>()
            func visit(_ value: Any, depth: Int) {
                guard depth < 40, values.count < 4000, let object = value as? NSObject, seen.insert(ObjectIdentifier(object)).inserted else { return }
                values.append(object)
                if let view = object as? NSView { for child in view.subviews { visit(child,depth:depth+1) } }
                for child in (object as AnyObject).accessibilityChildren?() ?? [] { visit(child,depth:depth+1) }
                let selector = NSSelectorFromString("accessibilityRows")
                if object.responds(to:selector),let rows = object.perform(selector)?.takeUnretainedValue() as? NSArray {
                    for child in rows.prefix(256) { visit(child,depth:depth+1) }
                }
            }
            visit(window,depth:0); for sheet in window.sheets { visit(sheet,depth:0) }
            return values
        }
        func press(_ label: String) throws {
            layout()
            let control = try XCTUnwrap(elements().first {
                ($0 as AnyObject).accessibilityRole?() == .button &&
                (($0 as AnyObject).accessibilityLabel?() == label || ($0 as AnyObject).accessibilityTitle?() == label)
            },"Missing FSD-owned button \(label)")
            XCTAssertTrue((control as AnyObject).isAccessibilityEnabled?() ?? false)
            let response = (control as AnyObject).accessibilityPerformPress?() ?? false
            print("TASK063_OWN_AX press=\(label) response=\(response)")
            layout()
        }
        let output = URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(".ai-scratch/task063/screenshots")
        try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
        func capture(_ name: String) throws {
            for width in [1120,1330,1440] {
                window.setContentSize(NSSize(width:width,height:900)); layout()
                var captured = false
                var captureError: Error?
                Task { @MainActor in
                    do {
                        // SDK currentProcess API returns only this test host's
                        // shareable windows; never enumerate other applications.
                        let content = try await SCShareableContent.currentProcess
                        let ownWindow = try XCTUnwrap(content.windows.first { $0.windowID == CGWindowID(window.windowNumber) })
                        let config = SCStreamConfiguration()
                        config.width = width*2; config.height = Int(window.frame.height)*2
                        config.showsCursor = false
                        let image = try await SCScreenshotManager.captureImage(contentFilter:SCContentFilter(desktopIndependentWindow:ownWindow),configuration:config)
                        let bitmap = NSBitmapImageRep(cgImage:image)
                        try XCTUnwrap(bitmap.representation(using:.png,properties:[:])).write(to:output.appendingPathComponent("\(name)-\(width).png"))
                    } catch { captureError = error }
                    captured = true
                }
                settle({ captured },timeout:15)
                if let captureError { throw captureError }
                XCTAssertEqual(Int(try XCTUnwrap(window.contentView).bounds.width),width)
            }
        }
        model.saveLimits.rows = 1
        try press("Save Comparison"); settle { !model.isSaving }
        XCTAssertNotNil(model.saveError); try capture("bounded-error")
        model.saveLimits = .init()
        let saveKey = try XCTUnwrap(NSEvent.keyEvent(with:.keyDown,location:.zero,modifierFlags:.command,timestamp:0,windowNumber:window.windowNumber,context:nil,characters:"s",charactersIgnoringModifiers:"s",isARepeat:false,keyCode:1))
        XCTAssertTrue(window.performKeyEquivalent(with:saveKey),"Command-S must route to the explicit Save control")
        settle { !model.isSaving }
        guard case .saved(let id) = model.eligibility else { return XCTFail(model.saveError ?? "Save failed") }
        try capture("completed-save")
        try press("Open saved comparison offline"); settle { !model.readerLoading }
        workspace.closeComparison()
        settle { !workspace.isClosing }
        model.closeReader(); model.reloadLibrary(); settle { !model.libraryLoading }
        host.rootView = AnyView(SavedComparisonsView(model:model).preferredColorScheme(.dark)); layout(); try capture("saved-library")
        try press("Open saved comparison \(id.uuidString)"); settle { !model.readerLoading }
        let added = try XCTUnwrap(model.rows.first { $0.original["result_type"]?.text == "added" })
        model.select(added); settle { model.selectedRight != nil }; try capture("offline-detail")
        let labels = elements().compactMap { ($0 as AnyObject).accessibilityLabel?() }
        XCTAssertTrue(labels.contains("Delete Saved Comparison"))
        XCTAssertTrue(labels.contains("Saved evidence category"))
        XCTAssertTrue(labels.contains("Content Not Verified. Historical metadata only. No file content or physical device verification."))
        try press("Delete Saved Comparison"); XCTAssertNotNil(model.deletionCandidate)
        XCTAssertEqual(try SavedComparisonRepository(database:db).list(),[id],"Confirmation has not been accepted")
        // Cancel confirmation using its actual own-window control.
        try press("Cancel"); XCTAssertNil(model.deletionCandidate)
        // Build an ineligible completed legacy workspace with isolated catalog facts.
        let (legacy,_,_) = try make(rich:false)
        try db.execute("DROP TRIGGER trg_receipts_no_delete")
        try db.execute("DELETE FROM comparison_completion_receipts WHERE comparison_id=?",bindings:[.integer(legacy.comparisonID)])
        workspace.openComparison(try record(legacy)); settle { model.eligibility != .checking }
        host.rootView = AnyView(ComparisonWorkspaceView(model:workspace).preferredColorScheme(.dark)); layout(); try capture("ineligible-save")
        let save = try XCTUnwrap(elements().first { ($0 as AnyObject).accessibilityRole?() == .button && (($0 as AnyObject).accessibilityTitle?() == "Save Comparison" || ($0 as AnyObject).accessibilityLabel?() == "Save Comparison") })
        XCTAssertFalse((save as AnyObject).isAccessibilityEnabled?() ?? true)
        let root = CatalogSchemaFixture.canonicalSchemaURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf:root.appendingPathComponent("FSD/UI/SavedComparisonsView.swift"),encoding:.utf8)
        XCTAssertTrue(source.contains("keyboardShortcut(\"s\",modifiers:.command)"))
        XCTAssertTrue(source.contains("keyboardShortcut(.downArrow,modifiers:[.command,.shift])"))
        // Confirm deletion through the dialog, not its model shortcut.
        model.open(id); settle { !model.readerLoading }
        host.rootView = AnyView(SavedComparisonsView(model:model).preferredColorScheme(.dark)); layout()
        window.recalculateKeyViewLoop()
        window.makeFirstResponder(host)
        window.selectNextKeyView(nil)
        XCTAssertNotNil(window.firstResponder)
        if let focused = window.firstResponder as? NSView { XCTAssertTrue(focused.window === window) }
        try press("Delete Saved Comparison")
        layout()
        let destructive = try XCTUnwrap(elements().last {
            ($0 as AnyObject).accessibilityRole?() == .button &&
            (($0 as AnyObject).accessibilityLabel?() == "Delete Saved Comparison" || ($0 as AnyObject).accessibilityTitle?() == "Delete Saved Comparison")
        })
        _ = (destructive as AnyObject).accessibilityPerformPress?()
        layout(); settle { !model.isDeleting && model.readerID == nil }
        XCTAssertTrue(try SavedComparisonRepository(database:db).list().isEmpty)
        try healthy()
    }
}
