import XCTest
import AppKit
import SwiftUI
import ScreenCaptureKit
@testable import FSD

@MainActor
final class ComparisonBrowserModelTests: XCTestCase {
    var database: CatalogDatabase!
    var historyRepo: SnapshotHistoryRepository!
    var resultRepo: ComparisonResultRepository!
    
    override func setUpWithError() throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sqlite")
        database = try CatalogDatabase(url: tempURL)
        historyRepo = SnapshotHistoryRepository(database: database)
        resultRepo = ComparisonResultRepository(database: database)
        
        // We'll test with a dummy record structure as real seeding requires more database setup.
        // We rely on the backend being tested, and we just need to ensure the View Model calls it safely.
    }
    
    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: database.url)
    }
    
    func testInitialState() {
        let dummyLeft = ComparisonSideDescriptor(snapshotID: SnapshotID(rawValue: 1), kind: .user, displayName: "A", scanRootName: "A", status: .complete, caseSensitivity: .sensitive, normalizationVersion: .current, warningCount: 0, mountPath: nil, volumeDisplayName: nil, startedAt: "")
        let dummyRight = ComparisonSideDescriptor(snapshotID: SnapshotID(rawValue: 2), kind: .user, displayName: "B", scanRootName: "B", status: .complete, caseSensitivity: .sensitive, normalizationVersion: .current, warningCount: 0, mountPath: nil, volumeDisplayName: nil, startedAt: "")
        
        let record = ComparisonRecord(
            id: ComparisonID(rawValue: 1),
            mode: .snapshotToSnapshot,
            left: dummyLeft,
            right: dummyRight,
            profileID: 1,
            profileName: "Fast",
            profileVersion: 1,
            status: .complete,
            startedAt: "",
            completedAt: "",
            matchedCount: 10,
            addedCount: 5,
            removedCount: 3,
            changedCount: 2,
            uncertainCount: 1,
            warnings: []
        )
        
        let model = ComparisonBrowserModel(database: database, record: record)
        
        XCTAssertEqual(model.activeFilter, .all)
        XCTAssertNil(model.currentPage)
        XCTAssertFalse(model.isLoading)
        XCTAssertNil(model.selectedRowID)
        
        // Counts
        XCTAssertEqual(model.record.totalDifferences, 11)
        XCTAssertEqual(model.record.totalComparedEntries, 21)
    }
    
    func testFilterMapping() {
        XCTAssertEqual(ComparisonResultFilter.all.types, ComparisonResultType.allCases)
        XCTAssertEqual(ComparisonResultFilter.differences.types, [.added, .removed, .changed, .uncertain])
        XCTAssertEqual(ComparisonResultFilter.added.types, [.added])
        XCTAssertEqual(ComparisonResultFilter.removed.types, [.removed])
    }
}

/// Task064 uses real generated SQLite evidence and genuine production completion
/// receipts. Only adversarial tests remove a guard in their private catalog.
@MainActor
final class ComparisonAncestorNavigationTests: XCTestCase {
    private var directory: URL!
    private var db: CatalogDatabase!
    private var repo: ComparisonResultRepository!
    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("FSD-task064-\(UUID())")
        db = try CatalogDatabase(url:directory.appendingPathComponent("catalog.sqlite"),schemaURL:CatalogSchemaFixture.canonicalSchemaURL)
        repo = ComparisonResultRepository(database:db)
    }
    override func tearDownWithError() throws { db?.close(); try? FileManager.default.removeItem(at:directory) }
    private func settle(_ model: ComparisonBrowserModel, file: StaticString = #filePath, line: UInt = #line) {
        let end = Date().addingTimeInterval(20)
        while model.isLoading && Date()<end { RunLoop.current.run(until:Date().addingTimeInterval(0.005)) }
        XCTAssertFalse(model.isLoading,file:file,line:line)
    }
    private func healthy() throws {
        XCTAssertEqual(try db.scalar("PRAGMA foreign_keys")?.int64Value,1)
        XCTAssertTrue(try db.query("PRAGMA foreign_key_check").isEmpty)
        XCTAssertEqual(try db.scalar("PRAGMA integrity_check")?.stringValue,"ok")
    }
    private func make(parents: Bool = true, flat: Int = 0, depth: Int = 2, allKinds: Bool = true) throws -> ComparisonRecord {
        let start = (try db.scalar("SELECT COALESCE(MAX(id),0) FROM entries")?.int64Value ?? 0)+1
        let l = try SyntheticSnapshot.createSnapshot(database:db,volumeID:1,session:start)
        let r = try SyntheticSnapshot.createSnapshot(database:db,volumeID:2,session:start)
        var left = [SyntheticSnapshot.root(id:start)], right = [SyntheticSnapshot.root(id:start+20000)]
        var specs: [(String,ComparisonResultType,Int64?,Int64?)] = [("",.matched,start,start+20000)]
        var path = "", parentL = start, parentR = start+20000, n: Int64 = 1
        for i in 0..<depth {
            path = path.isEmpty ? "dir\(i)" : "\(path)/dir\(i)"
            left.append(.init(id:start+n,parentID:parentL,relativePath:path,name:"dir\(i)",itemKind:.directory))
            right.append(.init(id:start+20000+n,parentID:parentR,relativePath:path,name:"dir\(i)",itemKind:.directory))
            parentL = start+n; parentR = start+20000+n
            specs.append((path,.matched,parentL,parentR)); n += 1
        }
        let leaf = path.isEmpty ? "target.bin" : "\(path)/target.bin"
        left.append(.init(id:start+n,parentID:parentL,relativePath:leaf,name:"target.bin",logicalSizeBytes:1))
        right.append(.init(id:start+20000+n,parentID:parentR,relativePath:leaf,name:"target.bin",logicalSizeBytes:2))
        specs.append((leaf,.changed,start+n,start+20000+n)); n += 1
        if allKinds {
            for (name,type) in [("added",ComparisonResultType.added),("removed",.removed),("locked",.uncertain),("ignored",.ignored)] {
                let li = type == .added ? nil : start+n, ri = type == .removed ? nil : start+20000+n
                if let li { left.append(.init(id:li,parentID:start,relativePath:name,name:name)) }
                if let ri { right.append(.init(id:ri,parentID:start+20000,relativePath:name,name:name,isInaccessible:type == .uncertain)) }
                if type == .ignored { specs.append((name,type,li,nil)); specs.append((name,type,nil,ri)) }
                else { specs.append((name,type,li,ri)) }
                n += 1
            }
        }
        for i in 0..<flat {
            let name = String(format:"z%05d.bin",i)
            left.append(.init(id:start+n,parentID:start,relativePath:name,name:name))
            right.append(.init(id:start+20000+n,parentID:start+20000,relativePath:name,name:name))
            specs.append((name,.matched,start+n,start+20000+n)); n += 1
        }
        try SyntheticSnapshot.insertEntries(database:db,snapshotID:l,entries:left)
        try SyntheticSnapshot.insertEntries(database:db,snapshotID:r,entries:right)
        try SyntheticSnapshot.complete(database:db,snapshotID:l); try SyntheticSnapshot.complete(database:db,snapshotID:r)
        try db.execute("INSERT INTO comparisons(left_snapshot_id,right_snapshot_id,profile_id,profile_version,status,started_at,created_at) VALUES (?,?,1,1,'running',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)",bindings:[.integer(l.rawValue),.integer(r.rawValue)])
        let id = ComparisonID(rawValue:try db.lastInsertRowID())
        var ids: [String:Int64] = [:]
        try db.transaction {
            for (path,type,li,ri) in specs {
                let parentPath = path.lastIndex(of:"/").map { String(path[..<$0]) } ?? ""
                let parentID = parents && !path.isEmpty ? ids[parentPath] : nil
                try db.execute("INSERT INTO comparison_results(comparison_id,parent_result_id,result_path,display_name,result_type,left_entry_id,right_entry_id,difference_flags,created_at) VALUES (?,?,?,?,?,?,?,?,CURRENT_TIMESTAMP)",bindings:[.integer(id.rawValue),parentID.map(DatabaseValue.integer) ?? .null,.text(path),.text(path.isEmpty ? "Root" : String(path.split(separator:"/").last!)),.text(type.rawValue),li.map(DatabaseValue.integer) ?? .null,ri.map(DatabaseValue.integer) ?? .null,.integer(type == .changed ? ComparisonField.logicalSize.flagBit : 0)])
                ids[path] = try db.lastInsertRowID()
            }
        }
        let history = SnapshotHistoryRepository(database:db)
        try ComparisonCompletionReceiptRepository(database:db).complete(comparisonID:id,profile:try XCTUnwrap(ComparisonProfileRepository(database:db).profile(id:1)),key:"case_preserving_path",warnings:[],leftUsed:try XCTUnwrap(history.summary(id:l)),rightUsed:try XCTUnwrap(history.summary(id:r)))
        return try XCTUnwrap(repo.record(id:id))
    }
    func testEveryCategorySelectsFirstActualResultAndPreservesCounts() throws {
        let record = try make(), model = ComparisonBrowserModel(database:db,record:record,pageSize:2)
        model.open(); settle(model)
        let changes = try db.scalar("SELECT total_changes()")
        let expected: [ComparisonResultFilter:[ComparisonResultType]] = [.all:ComparisonResultType.allCases,.differences:[.added,.removed,.changed,.uncertain],.unchanged:[.matched],.added:[.added],.removed:[.removed],.modified:[.changed],.conflicts:[.uncertain],.ignored:[.ignored]]
        for (filter,types) in expected {
            model.selectCategory(filter); settle(model)
            XCTAssertEqual(model.activeFilter,filter)
            let first = try XCTUnwrap(repo.results(comparisonID:record.id,filter:filter,limit:1).rows.first)
            XCTAssertEqual(model.selectedRow,first); XCTAssertTrue(types.contains(first.resultType))
            XCTAssertEqual(model.currentPage?.offset,0); XCTAssertLessThanOrEqual(model.currentPage?.rows.count ?? 999,2)
        }
        XCTAssertEqual(try db.scalar("SELECT total_changes()"),changes,"Navigation is read-only")
        XCTAssertEqual(try db.scalar("SELECT count(*) FROM saved_operations")?.int64Value,0,"Category navigation never saves")
        XCTAssertEqual(model.resultCounts[.ignored],2)
        XCTAssertEqual(record.totalComparedEntries,7,"Ignored does not inflate summary")
        try healthy()
    }
    func testEmptyCategoryClearsPreviousSelectionAndMetadata() throws {
        let model = ComparisonBrowserModel(database:db,record:try make(allKinds:false),pageSize:1)
        model.selectCategory(.modified); settle(model); XCTAssertNotNil(model.selectedRow)
        model.selectCategory(.added)
        XCTAssertNil(model.selectedRowID); XCTAssertNil(model.selectedLeftMetadata)
        settle(model); XCTAssertEqual(model.currentPage?.rows.count,0)
        XCTAssertNil(model.selectedRow); XCTAssertNil(model.ancestorContext); XCTAssertFalse(model.canGoNext)
    }
    func testNestedStoredChainAndAncestorReturnUseExactIDAcrossPages() throws {
        let record = try make(), model = ComparisonBrowserModel(database:db,record:record,pageSize:1)
        model.selectCategory(.modified); settle(model)
        let target = try XCTUnwrap(model.selectedRow), context = try XCTUnwrap(model.ancestorContext)
        XCTAssertEqual(context.ancestors.map(\.resultPath),["","dir0","dir0/dir1"])
        XCTAssertEqual(context.boundary,.rooted)
        model.revealAncestor(context.ancestors[1]); settle(model)
        XCTAssertEqual(model.activeFilter,.all); XCTAssertEqual(model.selectedRowID,context.ancestors[1].id)
        XCTAssertEqual(model.currentPage?.rows.map(\.id),[context.ancestors[1].id])
        XCTAssertNotNil(model.returnTarget)
        model.returnToTarget(); settle(model)
        XCTAssertEqual(model.selectedRowID,target.id)
        XCTAssertEqual(model.currentPage?.rows.map(\.id),[target.id])
        XCTAssertGreaterThan(model.activePageOffset,0); XCTAssertGreaterThan(model.revealGeneration,2)
        try healthy()
    }
    func testProductionFlatEvidenceNeverInfersAncestorsFromPaths() throws {
        let record = try make(parents:false), model = ComparisonBrowserModel(database:db,record:record)
        model.selectCategory(.modified); settle(model)
        XCTAssertEqual(model.ancestorContext?.ancestors.count,0)
        XCTAssertEqual(model.ancestorContext?.boundary,.notRecorded)
        XCTAssertEqual(try repo.results(comparisonID:record.id).rows.filter { $0.resultPath == "dir0" }.count,1,"Similar stored row exists but is never guessed as parent")
    }
    func testDuplicatePathsAreDistinctAndAddedRemovedSidesStayCanonical() throws {
        let model = ComparisonBrowserModel(database:db,record:try make(),pageSize:1)
        model.selectCategory(.ignored); settle(model)
        let first = try XCTUnwrap(model.selectedRow)
        model.navigate(direction:.next); settle(model)
        let second = try XCTUnwrap(model.selectedRow)
        XCTAssertEqual(first.resultPath,second.resultPath); XCTAssertNotEqual(first.id,second.id)
        XCTAssertEqual(model.currentPage?.rows.map(\.id),[second.id])
        model.selectCategory(.added); settle(model); XCTAssertNil(model.selectedLeftMetadata); XCTAssertNotNil(model.selectedRightMetadata)
        model.selectCategory(.removed); settle(model); XCTAssertNotNil(model.selectedLeftMetadata); XCTAssertNil(model.selectedRightMetadata)
    }
    func testCorruptCycleCrossComparisonPathAndParentEntryReject() throws {
        let record = try make(), other = try make()
        let target = try XCTUnwrap(repo.results(comparisonID:record.id,filter:.modified).rows.first)
        let root = try XCTUnwrap(repo.results(comparisonID:record.id).rows.first)
        let foreign = try XCTUnwrap(repo.results(comparisonID:other.id).rows.first)
        let original = try XCTUnwrap(db.scalar("SELECT parent_result_id FROM comparison_results WHERE id=?",bindings:[.integer(target.id)])?.int64Value)
        try db.execute("DROP TRIGGER trg_comparison_results_update_guard")
        for parent in [target.id,foreign.id,root.id] {
            try db.execute("UPDATE comparison_results SET parent_result_id=? WHERE id=?",bindings:[.integer(parent),.integer(target.id)])
            XCTAssertThrowsError(try repo.ancestorContext(resultID:target.id,comparisonID:record.id))
        }
        try db.execute("UPDATE comparison_results SET parent_result_id=? WHERE id=?",bindings:[.integer(original),.integer(target.id)])
        // Same comparison and same parent path, but contradictory side entry ancestry.
        try db.execute("UPDATE comparison_results SET left_entry_id=? WHERE id=?",bindings:[.integer(root.leftEntryID!),.integer(original)])
        XCTAssertThrowsError(try repo.ancestorContext(resultID:target.id,comparisonID:record.id))
        XCTAssertThrowsError(try repo.ancestorContext(resultID:target.id,comparisonID:other.id))
        try healthy()
    }
    func testOversizedAndNoncanonicalResultFieldsFailClosed() throws {
        let record = try make(), target = try XCTUnwrap(repo.results(comparisonID:record.id,filter:.modified).rows.first)
        try db.execute("DROP TRIGGER trg_comparison_results_update_guard")
        let originalPath = target.resultPath
        for path in [String(repeating:"x",count:65537),"/absolute","dir0//target.bin","dir0/../target.bin","dir0/./target.bin",originalPath+"/"] {
            try db.execute("UPDATE comparison_results SET result_path=? WHERE id=?",bindings:[.text(path),.integer(target.id)])
            XCTAssertThrowsError(try repo.ancestorContext(resultID:target.id,comparisonID:record.id))
        }
        try db.execute("UPDATE comparison_results SET result_path=?,display_name=? WHERE id=?",bindings:[.text(originalPath),.text(String(repeating:"n",count:4097)),.integer(target.id)])
        XCTAssertThrowsError(try repo.ancestorContext(resultID:target.id,comparisonID:record.id))
        try healthy()
    }
    func testEmbeddedNULInvalidUTF8AndDiscriminatorPrefixesFailClosed() throws {
        let record = try make(), target = try XCTUnwrap(repo.results(comparisonID:record.id,filter:.modified).rows.first)
        let root = try XCTUnwrap(repo.results(comparisonID:record.id).rows.first)
        try db.execute("DROP TRIGGER trg_comparison_results_update_guard")
        // SQL expressions deliberately bypass the binding API's C-string input.
        for value in ["'visible'||char(0)||'hidden'","CAST(X'FF' AS TEXT)","X'41'"] {
            try db.execute("UPDATE comparison_results SET display_name=\(value) WHERE id=?",bindings:[.integer(target.id)])
            XCTAssertThrowsError(try repo.ancestorContext(resultID:target.id,comparisonID:record.id),"No truncated/repaired name may become a breadcrumb")
        }
        try db.execute("UPDATE comparison_results SET display_name=? WHERE id=?",bindings:[.text(target.displayName),.integer(target.id)])
        try db.execute("DROP TRIGGER trg_completed_entries_update_guard")
        for value in ["char(0)||'hidden'","CAST(X'FF' AS TEXT)","X'41'"] {
            try db.execute("UPDATE comparison_results SET result_path=\(value) WHERE id=?",bindings:[.integer(root.id)])
            try db.execute("UPDATE entries SET case_preserving_path=\(value) WHERE id IN (?,?)",bindings:[.integer(root.leftEntryID!),.integer(root.rightEntryID!)])
            XCTAssertThrowsError(try repo.ancestorContext(resultID:root.id,comparisonID:record.id),"Full SQL key equality cannot justify a truncated/repaired root")
        }
        try db.execute("UPDATE comparison_results SET result_path='' WHERE id=?",bindings:[.integer(root.id)])
        try db.execute("UPDATE entries SET case_preserving_path='' WHERE id IN (?,?)",bindings:[.integer(root.leftEntryID!),.integer(root.rightEntryID!)])
        try db.execute("PRAGMA ignore_check_constraints=ON")
        try db.execute("UPDATE comparison_results SET result_type='matched'||char(0)||'hidden' WHERE id=?",bindings:[.integer(root.id)])
        XCTAssertThrowsError(try repo.ancestorContext(resultID:root.id,comparisonID:record.id),"Result type must match the full SQL discriminator")
        try db.execute("UPDATE comparison_results SET result_type='matched' WHERE id=?",bindings:[.integer(root.id)])
        try db.execute("UPDATE entries SET item_type='directory'||char(0)||'hidden' WHERE id IN (?,?)",bindings:[.integer(root.leftEntryID!),.integer(root.rightEntryID!)])
        XCTAssertThrowsError(try repo.ancestorContext(resultID:target.id,comparisonID:record.id),"Directory kind must match the full SQL discriminator")
        try db.execute("PRAGMA ignore_check_constraints=OFF")
        // This private catalog intentionally remains corrupt; no repair/write
        // is performed by the production projection API.
    }
    func testMissingReferenceIsAnExplicitBoundaryAndNoNodeIsFabricated() throws {
        let record = try make(), target = try XCTUnwrap(repo.results(comparisonID:record.id,filter:.modified).rows.first)
        try db.execute("DROP TRIGGER trg_comparison_results_update_guard")
        try db.execute("PRAGMA foreign_keys=OFF")
        try db.execute("UPDATE comparison_results SET parent_result_id=999999 WHERE id=?",bindings:[.integer(target.id)])
        try db.execute("PRAGMA foreign_keys=ON")
        let context = try repo.ancestorContext(resultID:target.id,comparisonID:record.id)
        XCTAssertEqual(context.boundary,.missingParent); XCTAssertTrue(context.ancestors.isEmpty)
        XCTAssertFalse(try db.query("PRAGMA foreign_key_check").isEmpty,"Deliberately corrupt private fixture")
    }
    func testCooperativeReadBudgetFailsClosedWithoutRepair() throws {
        let record = try make(), target = try XCTUnwrap(repo.results(comparisonID:record.id,filter:.modified).rows.first)
        XCTAssertThrowsError(try repo.ancestorContext(resultID:target.id,comparisonID:record.id,timeBudget:0))
        XCTAssertNotNil(try repo.ancestorContext(resultID:target.id,comparisonID:record.id))
        try healthy()
    }
    func testExcessiveDepthFailsClosedAt128AndSupportedBoundaryWorks() throws {
        let record = try make(depth:127,allKinds:false)
        let target = try XCTUnwrap(repo.results(comparisonID:record.id,filter:.modified).rows.first)
        XCTAssertThrowsError(try repo.ancestorContext(resultID:target.id,comparisonID:record.id))
        let lastDirectory = try XCTUnwrap(db.scalar("SELECT parent_result_id FROM comparison_results WHERE id=?",bindings:[.integer(target.id)])?.int64Value)
        let context = try repo.ancestorContext(resultID:lastDirectory,comparisonID:record.id)
        XCTAssertEqual(context.ancestors.count,127)
        try healthy()
    }
    func testTenThousandResultsBoundPagingAndIndexedAncestorPlans() throws {
        let record = try make(flat:11000), model = ComparisonBrowserModel(database:db,record:record,pageSize:17)
        let start = ProcessInfo.processInfo.systemUptime
        model.selectCategory(.unchanged); settle(model)
        XCTAssertLessThanOrEqual(model.currentPage?.rows.count ?? 999,17)
        let last = try XCTUnwrap(repo.navigate(comparisonID:record.id,filter:.unchanged,from:nil,direction:.previous,limit:1).first)
        let position = try XCTUnwrap(repo.position(of:.init(resultPath:last.resultPath,id:last.id),comparisonID:record.id,filter:.unchanged))
        XCTAssertGreaterThan(position,10000)
        let context = try repo.ancestorContext(resultID:last.id,comparisonID:record.id)
        XCTAssertEqual(context.ancestors.count,1)
        let plans = try db.query("EXPLAIN QUERY PLAN "+ComparisonResultRepository.ancestorSQL,bindings:[.integer(last.id),.integer(record.id.rawValue)])
        let plan = plans.compactMap { $0["detail"]?.stringValue }.joined(separator:" | ")
        XCTAssertTrue(plan.contains("SEARCH p USING INTEGER PRIMARY KEY"))
        XCTAssertFalse(plan.contains("SCAN comparison_results"))
        let ordinalPlan = try db.query("EXPLAIN QUERY PLAN SELECT COUNT(*) FROM comparison_results WHERE comparison_id=? AND result_type IN (?) AND (result_path<? OR (result_path=? AND id<?))",bindings:[.integer(record.id.rawValue),.text("matched"),.text(last.resultPath),.text(last.resultPath),.integer(last.id)]).compactMap { $0["detail"]?.stringValue }.joined(separator:" | ")
        let pagePlan = try db.query("EXPLAIN QUERY PLAN SELECT id,comparison_id,result_path,display_name,result_type,left_entry_id,right_entry_id,difference_flags FROM comparison_results WHERE comparison_id=? AND result_type IN (?) ORDER BY result_path,id LIMIT ? OFFSET ?",bindings:[.integer(record.id.rawValue),.text("matched"),.integer(17),.integer(Int64((position/17)*17))]).compactMap { $0["detail"]?.stringValue }.joined(separator:" | ")
        print("TASK064_POSITION_PLAN \(ordinalPlan)")
        print("TASK064_PAGE_PLAN \(pagePlan)")
        print("TASK064_SCALE results=\(model.currentPage?.totalCount ?? 0) retained=\(model.currentPage?.rows.count ?? 0) last_position=\(position) seconds=\(ProcessInfo.processInfo.systemUptime-start) plan=\(plan)")
        try healthy()
    }
    func testFilterPauseCloseAndComparisonSwitchDiscardPendingCallbacksWithoutMainLockWait() throws {
        let record = try make(), other = try make()
        let model = ComparisonBrowserModel(database:db,record:record,pageSize:1)
        model.selectCategory(.modified); settle(model)
        let entered = DispatchSemaphore(value:0), release = DispatchSemaphore(value:0), database = db!
        DispatchQueue.global().async { try? database.transaction { entered.signal(); _ = release.wait(timeout:.now()+2) } }
        XCTAssertEqual(entered.wait(timeout:.now()+3),.success)
        let start = ProcessInfo.processInfo.systemUptime
        model.navigate(direction:.next); model.selectCategory(.removed); model.selectCategory(.added)
        model.setSaveInProgress(true)
        model.selectedRowID = 999999; model.close()
        let fresh = ComparisonBrowserModel(database:db,record:other,pageSize:1)
        fresh.selectCategory(.modified)
        var beat = false; DispatchQueue.main.async { beat = true }
        let end = Date().addingTimeInterval(1)
        while !beat && Date()<end { RunLoop.current.run(until:Date().addingTimeInterval(0.005)) }
        XCTAssertTrue(beat); XCTAssertLessThan(ProcessInfo.processInfo.systemUptime-start,0.5)
        release.signal(); settle(fresh)
        RunLoop.current.run(until:Date().addingTimeInterval(0.1))
        XCTAssertNil(model.currentPage); XCTAssertNil(model.selectedRow); XCTAssertNil(model.ancestorContext)
        XCTAssertEqual(fresh.selectedRow?.comparisonID,other.id)
        fresh.selectCategory(.removed); fresh.selectCategory(.added); settle(fresh)
        XCTAssertEqual(fresh.selectedRow?.resultType,.added)
        try healthy()
    }
    func testWorkspaceCloseWhileAncestorReadWaitsDoesNotBlockMainActor() throws {
        let record = try make(), workspace = ComparisonWorkspaceModel(database:db)
        workspace.refresh(); workspace.openComparison(record)
        let model = try XCTUnwrap(workspace.activeBrowser)
        settle(model)
        let readyDeadline = Date().addingTimeInterval(5)
        while workspace.savedComparisons.eligibility == .checking && Date()<readyDeadline { RunLoop.current.run(until:Date().addingTimeInterval(0.005)) }
        let entered = DispatchSemaphore(value:0), release = DispatchSemaphore(value:0), database = db!
        DispatchQueue.global().async { try? database.transaction { entered.signal(); _ = release.wait(timeout:.now()+2) } }
        XCTAssertEqual(entered.wait(timeout:.now()+3),.success)
        model.selectCategory(.modified)
        let start = ProcessInfo.processInfo.systemUptime
        workspace.closeComparison()
        workspace.refresh()
        var beat = false; DispatchQueue.main.async { beat = true }
        let deadline = Date().addingTimeInterval(1)
        while !beat && Date()<deadline { RunLoop.current.run(until:Date().addingTimeInterval(0.005)) }
        XCTAssertTrue(beat)
        XCTAssertLessThan(ProcessInfo.processInfo.systemUptime-start,0.5,"Workspace disposal cannot wait on a catalog lock on MainActor")
        release.signal()
        let end = Date().addingTimeInterval(5)
        while workspace.isClosing && Date()<end { RunLoop.current.run(until:Date().addingTimeInterval(0.005)) }
        XCTAssertFalse(workspace.isClosing); XCTAssertNil(workspace.activeBrowser)
        RunLoop.current.run(until:Date().addingTimeInterval(0.05))
        XCTAssertNil(model.ancestorContext); XCTAssertNil(model.currentPage)
        XCTAssertNotNil(try repo.record(id:record.id),"Snapshot comparison history survives close")
        try healthy()
    }
    func testOwnWindowCannotSaveOrRefreshDuringPendingClose() throws {
        let record = try make(), workspace = ComparisonWorkspaceModel(database:db)
        workspace.openComparison(record)
        let model = try XCTUnwrap(workspace.activeBrowser); settle(model)
        let deadline = Date().addingTimeInterval(5)
        while workspace.savedComparisons.eligibility == .checking && Date()<deadline { RunLoop.current.run(until:Date().addingTimeInterval(0.005)) }
        XCTAssertEqual(workspace.savedComparisons.eligibility,.available)
        let host = NSHostingView(rootView:ComparisonWorkspaceView(model:workspace))
        let window = NSWindow(contentRect:NSRect(x:0,y:0,width:1120,height:900),styleMask:[.titled,.resizable],backing:.buffered,defer:false)
        window.contentView = host; window.makeKeyAndOrderFront(nil)
        defer { window.orderOut(nil) }
        let attribute = NSAccessibility.Attribute(rawValue:"AXEnhancedUserInterface")
        let prior = NSApplication.shared.accessibilityAttributeValue(attribute)
        NSApplication.shared.accessibilitySetValue(true,forAttribute:attribute)
        defer { NSApplication.shared.accessibilitySetValue(prior,forAttribute:attribute) }
        let entered = DispatchSemaphore(value:0), release = DispatchSemaphore(value:0), database = db!
        DispatchQueue.global().async { try? database.transaction { entered.signal(); _ = release.wait(timeout:.now()+3) } }
        XCTAssertEqual(entered.wait(timeout:.now()+3),.success)
        workspace.closeComparison(); XCTAssertTrue(workspace.isClosing)
        let start = ProcessInfo.processInfo.systemUptime
        workspace.refresh()
        host.layoutSubtreeIfNeeded(); RunLoop.current.run(until:Date().addingTimeInterval(0.1))
        var seen = Set<ObjectIdentifier>(), saveButton: NSObject?
        func visit(_ value: Any, depth: Int) {
            guard depth<40, let object = value as? NSObject, seen.insert(ObjectIdentifier(object)).inserted else { return }
            if (object as AnyObject).accessibilityRole?() == .button, (object as AnyObject).accessibilityLabel?() == "Save Comparison" { saveButton = object }
            if let view = object as? NSView { view.subviews.forEach { visit($0,depth:depth+1) } }
            for child in (object as AnyObject).accessibilityChildren?() ?? [] { visit(child,depth:depth+1) }
        }
        visit(window,depth:0)
        let save = try XCTUnwrap(saveButton)
        XCTAssertFalse((save as AnyObject).isAccessibilityEnabled?() ?? true)
        let key = try XCTUnwrap(NSEvent.keyEvent(with:.keyDown,location:.zero,modifierFlags:.command,timestamp:0,windowNumber:window.windowNumber,context:nil,characters:"s",charactersIgnoringModifiers:"s",isARepeat:false,keyCode:1))
        _ = window.performKeyEquivalent(with:key)
        XCTAssertFalse(workspace.savedComparisons.isSaving)
        XCTAssertLessThan(ProcessInfo.processInfo.systemUptime-start,0.5)
        release.signal()
        let end = Date().addingTimeInterval(5)
        while workspace.isClosing && Date()<end { RunLoop.current.run(until:Date().addingTimeInterval(0.005)) }
        XCTAssertFalse(workspace.isClosing)
        XCTAssertEqual(try db.scalar("SELECT count(*) FROM saved_operations")?.int64Value,0)
        try healthy()
    }
    func testOwnWindowCategoryAncestorNavigationScreenshotsKeyboardAndAX() throws {
        let record = try make(), workspace = ComparisonWorkspaceModel(database:db)
        workspace.openComparison(record)
        let model = ComparisonBrowserModel(database:db,record:record,pageSize:2)
        model.open(); settle(model)
        let attribute = NSAccessibility.Attribute(rawValue:"AXEnhancedUserInterface")
        let prior = NSApplication.shared.accessibilityAttributeValue(attribute)
        NSApplication.shared.accessibilitySetValue(true,forAttribute:attribute)
        defer { NSApplication.shared.accessibilitySetValue(prior,forAttribute:attribute) }
        let host = NSHostingView(rootView:ComparisonBrowserView(workspace:workspace,browser:model).preferredColorScheme(.dark))
        let window = NSWindow(contentRect:NSRect(x:0,y:0,width:1330,height:900),styleMask:[.titled,.resizable],backing:.buffered,defer:false)
        window.title = "FSD Task064 — Synthetic Stored Comparison"
        window.appearance = NSAppearance(named:.darkAqua); window.contentView = host; window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps:true)
        defer { window.orderOut(nil) }
        func layout() { host.layoutSubtreeIfNeeded(); RunLoop.current.run(until:Date().addingTimeInterval(0.15)) }
        func elements() -> [NSObject] {
            var values: [NSObject] = [], seen = Set<ObjectIdentifier>()
            func visit(_ value: Any, depth: Int) {
                guard depth<40, values.count<4000, let object = value as? NSObject, seen.insert(ObjectIdentifier(object)).inserted else { return }
                values.append(object)
                if let view = object as? NSView { view.subviews.forEach { visit($0,depth:depth+1) } }
                for child in (object as AnyObject).accessibilityChildren?() ?? [] { visit(child,depth:depth+1) }
                let selector = NSSelectorFromString("accessibilityRows")
                if object.responds(to:selector), let rows = object.perform(selector)?.takeUnretainedValue() as? NSArray { for child in rows.prefix(256) { visit(child,depth:depth+1) } }
            }
            visit(window,depth:0); return values
        }
        func control(_ label: String) throws -> NSObject {
            layout()
            return try XCTUnwrap(elements().first { ($0 as AnyObject).accessibilityRole?() == .button && (($0 as AnyObject).accessibilityLabel?() == label || ($0 as AnyObject).accessibilityTitle?() == label) },"Missing own-window button \(label)")
        }
        func press(_ label: String) throws {
            let button = try control(label)
            XCTAssertTrue((button as AnyObject).isAccessibilityEnabled?() ?? false)
            _ = (button as AnyObject).accessibilityPerformPress?()
            settle(model); layout()
        }
        let output = URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(".ai-scratch/task064/screenshots")
        try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
        func capture(_ state: String) throws {
            for width in [1120,1330,1440] {
                window.setContentSize(NSSize(width:width,height:900)); layout()
                XCTAssertEqual(Int(host.bounds.width),width)
                var done = false, failure: Error?
                Task { @MainActor in
                    do {
                        let own = try await SCShareableContent.currentProcess
                        let target = try XCTUnwrap(own.windows.first { $0.windowID == CGWindowID(window.windowNumber) })
                        let configuration = SCStreamConfiguration(); configuration.width = width*2; configuration.height = Int(window.frame.height)*2; configuration.showsCursor = false
                        let image = try await SCScreenshotManager.captureImage(contentFilter:SCContentFilter(desktopIndependentWindow:target),configuration:configuration)
                        try XCTUnwrap(NSBitmapImageRep(cgImage:image).representation(using:.png,properties:[:])).write(to:output.appendingPathComponent("\(state)-\(width).png"))
                    } catch { failure = error }
                    done = true
                }
                let deadline = Date().addingTimeInterval(15)
                while !done && Date()<deadline { RunLoop.current.run(until:Date().addingTimeInterval(0.01)) }
                XCTAssertTrue(done); if let failure { throw failure }
            }
        }
        let categories: [(String,ComparisonResultFilter)] = [("All: 7",.all),("Differences: 4",.differences),("Matched: 3",.unchanged),("Added: 1",.added),("Removed: 1",.removed),("Changed: 1",.modified),("Uncertain: 1",.conflicts),("Ignored: 2",.ignored)]
        for (label,filter) in categories {
            try press(label); XCTAssertEqual(model.activeFilter,filter)
            let button = try control(label)
            let valueSelector = NSSelectorFromString("accessibilityValue")
            XCTAssertTrue(button.responds(to:valueSelector))
            XCTAssertEqual(button.perform(valueSelector)?.takeUnretainedValue() as? String,"Selected")
            XCTAssertTrue((button as AnyObject).isAccessibilityFocused?() ?? false,"Selected category receives keyboard focus")
            XCTAssertEqual(model.selectedRow?.id,try repo.results(comparisonID:record.id,filter:filter,limit:1).rows.first?.id)
        }
        try press("Matched: 3")
        let down = try XCTUnwrap(NSEvent.keyEvent(with:.keyDown,location:.zero,modifierFlags:.command,timestamp:0,windowNumber:window.windowNumber,context:nil,characters:String(UnicodeScalar(NSDownArrowFunctionKey)!),charactersIgnoringModifiers:String(UnicodeScalar(NSDownArrowFunctionKey)!),isARepeat:false,keyCode:125))
        XCTAssertTrue(window.performKeyEquivalent(with:down)); settle(model)
        XCTAssertEqual(model.selectedRow?.resultPath,"dir0")
        try capture("category-selected")
        try press("Changed: 1")
        let target = try XCTUnwrap(model.selectedRow)
        XCTAssertEqual(model.ancestorContext?.ancestors.count,3)
        try capture("ancestor-context")
        let parent = try XCTUnwrap(model.ancestorContext?.ancestors.last)
        try press("Reveal stored ancestor \(parent.resultPath), result \(parent.id)")
        XCTAssertEqual(model.selectedRowID,parent.id)
        try press("Return to stored target result \(target.id)")
        XCTAssertEqual(model.selectedRowID,target.id)
        XCTAssertTrue(model.currentPage?.rows.contains { $0.id == target.id } == true)
        try capture("navigated-target")
        let labels = elements().compactMap { ($0 as AnyObject).accessibilityLabel?() }
        XCTAssertTrue(labels.contains("Comparison results"))
        XCTAssertTrue(labels.contains("Stored result ancestors"))
        // Only our window's key-view chain is traversed; no global AX query.
        var focusViews = Set<ObjectIdentifier>()
        window.selectNextKeyView(nil)
        for _ in 0..<30 {
            if let view = window.firstResponder as? NSView { focusViews.insert(ObjectIdentifier(view)) }
            window.selectNextKeyView(nil)
        }
        XCTAssertGreaterThan(focusViews.count,1)
        print("TASK064_OWN_WINDOW categories=8 AX_press=PASS CommandDown=PASS focus_views=\(focusViews.count) screenshots=9")
        try healthy()
    }

}
