import AppKit
import SwiftUI
import XCTest
@testable import FSD

/// Synthetic catalogs and inert local records only; no empirical device proof.
@MainActor
final class DriveSetsTests: XCTestCase {
    private var directory: URL!
    private var db: CatalogDatabase!
    private var repo: DriveSetRepository!
    private var identities: PhysicalDriveRepository!
    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("FSD-task060-\(UUID())")
        db = try CatalogDatabase(url: directory.appendingPathComponent("generated.sqlite"), schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        repo = DriveSetRepository(database: db); identities = PhysicalDriveRepository(database: db)
    }
    override func tearDownWithError() throws {
        db?.close(); db = nil; repo = nil; identities = nil
        try? FileManager.default.removeItem(at: directory)
    }
    func testCreateEmptySet() throws {
        let created = try repo.create(name: "  Empty  ")
        XCTAssertEqual(created.name, "Empty")
        XCTAssertEqual(created.revision, 1)
        XCTAssertTrue(try repo.members(setID: created.id).records.isEmpty)
        XCTAssertEqual(try repo.set(id: created.id), created)
    }
    func testUnicodeAndDuplicateNames() throws {
        for (a,b) in [("Café","CAFE\u{301}"),("Straße","STRASSE"),("Σ","σ")] {
            let set = try repo.create(name: a)
            XCTAssertThrowsError(try repo.create(name: b)) { XCTAssertEqual($0 as? DriveSetError, .duplicateName) }
            XCTAssertEqual(try repo.rename(id: set.id, expectedRevision: 1, name: b).id, set.id)
        }
        for name in ["", " \n", "a\0b", String(repeating: "é", count: 129), String(repeating: "x", count: 1025)] {
            XCTAssertThrowsError(try repo.create(name: name)) { XCTAssertEqual($0 as? DriveSetError, .invalidName) }
        }
        XCTAssertNoThrow(try repo.create(name: String(repeating: "é", count: 128)))
    }
    func testCreateRetryStableIDAndMismatch() throws {
        let id = DriveSetID()
        let first = try repo.create(id: id, name: "Retry")
        let changes = try db.scalar("SELECT total_changes()")
        XCTAssertEqual(try repo.create(id: id, name: "Retry"), first)
        XCTAssertEqual(try db.scalar("SELECT total_changes()"), changes)
        XCTAssertThrowsError(try repo.create(id: id, name: "Other")) { XCTAssertEqual($0 as? DriveSetError, .operationMismatch) }
        XCTAssertEqual(try repo.list().records.count, 1)
    }
    func testRenameRevisionAndDuplicateRollback() throws {
        let a = try repo.create(name: "A"); _ = try repo.create(name: "B")
        let renamed = try repo.rename(id: a.id, expectedRevision: 1, name: "C")
        XCTAssertEqual(renamed.revision, 2); XCTAssertEqual(renamed.id, a.id)
        let changes = try db.scalar("SELECT total_changes()")
        XCTAssertEqual(try repo.rename(id: a.id, expectedRevision: 2, name: "C"), renamed)
        XCTAssertThrowsError(try repo.rename(id: a.id, expectedRevision: 1, name: "D"))
        XCTAssertThrowsError(try repo.rename(id: a.id, expectedRevision: 2, name: "b"))
        XCTAssertEqual(try repo.set(id: a.id), renamed)
        XCTAssertEqual(try db.scalar("SELECT total_changes()"), changes)
    }
    func testManyToManyExplicitMembershipAndIdempotency() throws {
        let a = try repo.create(name: "A"); let b = try repo.create(name: "B")
        let one = try identities.createDrive(label: "same", provenance: "synthetic")
        let two = try identities.createDrive(label: "same", provenance: "synthetic")
        XCTAssertNotEqual(one.id,two.id)
        let updated = try repo.setMembership(setID: a.id, expectedRevision: 1, driveID: one.id, expectedDriveRevision: 1, included: true)
        XCTAssertEqual(updated.revision, 2)
        let change = try db.scalar("SELECT total_changes()")
        XCTAssertEqual(try repo.setMembership(setID: a.id, expectedRevision: 2, driveID: one.id, expectedDriveRevision: 1, included: true), updated)
        XCTAssertEqual(try db.scalar("SELECT total_changes()"), change)
        _ = try repo.setMembership(setID: a.id, expectedRevision: 2, driveID: two.id, expectedDriveRevision: 1, included: true)
        _ = try repo.setMembership(setID: b.id, expectedRevision: 1, driveID: one.id, expectedDriveRevision: 1, included: true)
        XCTAssertEqual(try repo.members(setID: a.id).records.count,2)
        XCTAssertEqual(try repo.members(setID: b.id).records.map(\.id),[one.id])
        XCTAssertFalse(one.hardwareVerified)
    }
    func testStaleAndMissingMembershipRejectAtomically() throws {
        let set = try repo.create(name: "Set")
        let drive = try identities.createDrive(provenance: "synthetic")
        let before = try db.query("SELECT * FROM drive_sets")
        for (id,rev,driveID,driveRev) in [(set.id,Int64(0),drive.id,Int64(1)),(DriveSetID(),1,drive.id,1),(set.id,1,PhysicalDriveID(),1),(set.id,1,drive.id,2)] {
            XCTAssertThrowsError(try repo.setMembership(setID: id, expectedRevision: rev, driveID: driveID, expectedDriveRevision: driveRev, included: true))
        }
        XCTAssertEqual(try db.query("SELECT * FROM drive_sets"), before)
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM drive_set_memberships")?.int64Value,0)
    }
    func testRetiredMembersRemainVisibleAndCanBeRemoved() throws {
        let set = try repo.create(name: "Set"); let drive = try identities.createDrive(provenance: "synthetic")
        let current = try repo.setMembership(setID: set.id, expectedRevision: 1, driveID: drive.id, expectedDriveRevision: 1, included: true)
        _ = try identities.retireDrive(id: drive.id, expectedRevision: 1)
        let retired = try XCTUnwrap(repo.members(setID: set.id).records.first)
        XCTAssertTrue(retired.retired)
        XCTAssertThrowsError(try repo.setMembership(setID: set.id, expectedRevision: current.revision, driveID: drive.id, expectedDriveRevision: 2, included: true))
        let removed = try repo.setMembership(setID: set.id, expectedRevision: current.revision, driveID: drive.id, expectedDriveRevision: 2, included: false)
        XCTAssertEqual(removed.revision,3)
        XCTAssertTrue(try repo.members(setID: set.id).records.isEmpty)
        XCTAssertEqual(try repo.setMembership(setID: set.id, expectedRevision: 3, driveID: drive.id, expectedDriveRevision: 2, included: false), removed)
    }
    func testDeleteRevisionAndOnlyMembershipCascade() throws {
        let set = try repo.create(name: "Set"); let drive = try identities.createDrive(provenance: "synthetic")
        _ = try repo.setMembership(setID: set.id, expectedRevision: 1, driveID: drive.id, expectedDriveRevision: 1, included: true)
        XCTAssertThrowsError(try repo.delete(id: set.id, expectedRevision: 1))
        try repo.delete(id: set.id, expectedRevision: 2); try repo.delete(id: set.id, expectedRevision: 2)
        XCTAssertNil(try repo.set(id: set.id)); XCTAssertEqual(try identities.drive(id: drive.id),drive)
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM drive_set_memberships")?.int64Value,0)
        XCTAssertThrowsError(try db.execute("DELETE FROM physical_drives"))
        XCTAssertTrue(try db.query("PRAGMA foreign_key_check").isEmpty)
        XCTAssertEqual(try db.scalar("PRAGMA integrity_check")?.stringValue,"ok")
    }
    func testTransactionFailureRollsBackPairAndRevision() throws {
        let set = try repo.create(name: "Set"); let drive = try identities.createDrive(provenance: "synthetic")
        try db.execute("CREATE TRIGGER synthetic_abort BEFORE UPDATE ON drive_sets BEGIN SELECT RAISE(ABORT,'synthetic failure'); END;")
        XCTAssertThrowsError(try repo.setMembership(setID: set.id, expectedRevision: 1, driveID: drive.id, expectedDriveRevision: 1, included: true))
        XCTAssertEqual(try repo.set(id: set.id),set)
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM drive_set_memberships")?.int64Value,0)
        try db.execute("DROP TRIGGER synthetic_abort")
        XCTAssertNoThrow(try repo.setMembership(setID: set.id, expectedRevision: 1, driveID: drive.id, expectedDriveRevision: 1, included: true))
    }
    func testForeignKeysAndSQLGuards() throws {
        let set = try repo.create(name: "Set"); let drive = try identities.createDrive(provenance: "synthetic")
        XCTAssertEqual(try db.scalar("PRAGMA foreign_keys")?.int64Value,1)
        XCTAssertThrowsError(try db.execute("INSERT INTO drive_set_memberships VALUES (?,'missing','then','explicit_local_selection')",bindings: [.text(set.id.rawValue.uuidString)]))
        XCTAssertThrowsError(try db.execute("UPDATE drive_sets SET id='changed',revision=revision+1"))
        _ = try repo.setMembership(setID: set.id, expectedRevision: 1, driveID: drive.id, expectedDriveRevision: 1, included: true)
        XCTAssertThrowsError(try db.execute("UPDATE drive_set_memberships SET added_at='changed'"))
        XCTAssertThrowsError(try db.execute("INSERT INTO drive_set_memberships SELECT * FROM drive_set_memberships"))
    }
    func testBoundedPagesAndIndexes() throws {
        for i in 0..<205 { _ = try repo.create(name: String(format:"Set %03d",i)) }
        let page = try repo.list(limit: Int.max)
        XCTAssertEqual(page.records.count,200)
        let next = try repo.list(after: page.next, limit: 200)
        XCTAssertEqual(next.records.count,5); XCTAssertNil(next.next)
        XCTAssertTrue(Set(page.records.map(\.id)).isDisjoint(with: next.records.map(\.id)))
        XCTAssertEqual(try repo.list(limit: Int.min).records.count,1)
        let plan = try db.query("EXPLAIN QUERY PLAN SELECT * FROM drive_sets WHERE (normalized_name,id) > ('','') ORDER BY normalized_name,id LIMIT 101")
        XCTAssertTrue(plan.contains { $0["detail"]?.stringValue?.contains("INDEX") == true })
        let memberPlan = try db.query("EXPLAIN QUERY PLAN SELECT physical_drive_id FROM drive_set_memberships WHERE set_id='s' AND physical_drive_id>'' ORDER BY physical_drive_id LIMIT 101")
        XCTAssertTrue(memberPlan.contains { $0["detail"]?.stringValue?.contains("INDEX") == true })
    }
    func testMemberAndUIPageBoundariesStayBounded() throws {
        let set = try repo.create(name: "Paged")
        var revision: Int64 = 1
        for i in 0..<205 {
            let drive = try identities.createDrive(label: "Generated \(i)", provenance: "synthetic")
            revision = try repo.setMembership(setID:set.id,expectedRevision:revision,driveID:drive.id,expectedDriveRevision:1,included:true).revision
        }
        let first = try repo.members(setID:set.id,limit:Int.max)
        XCTAssertEqual(first.records.count,200); XCTAssertTrue(first.isTruncated)
        let second = try repo.members(setID:set.id,after:first.records.last?.id,limit:200)
        XCTAssertEqual(second.records.count,5); XCTAssertFalse(second.isTruncated)
        XCTAssertTrue(Set(first.records.map(\.id)).isDisjoint(with:second.records.map(\.id)))
        let model = DriveSetsModel(database:db); model.select(set)
        XCTAssertEqual(model.members.count,100); XCTAssertTrue(model.moreMembers)
        model.nextMembers(); XCTAssertEqual(model.members.count,100)
        model.nextMembers(); XCTAssertEqual(model.members.count,5); XCTAssertFalse(model.moreMembers)
        model.showDrives(); XCTAssertEqual(model.available.count,100); XCTAssertEqual(model.included.count,100)
        model.nextDrives(); XCTAssertEqual(model.available.count,100); XCTAssertEqual(model.included.count,100)
        model.nextDrives(); XCTAssertEqual(model.available.count,5); XCTAssertFalse(model.moreDrives)
    }
    func testCollectionNamesStaySeparateAndNoMembershipIsInferred() throws {
        let collection = try SnapshotCollectionRepository(database:db).createCollection(name:"Same")
        let set = try repo.create(name:"Same")
        _ = try identities.createDrive(label:"Same",provenance:"synthetic")
        XCTAssertTrue(try repo.members(setID:set.id).records.isEmpty)
        try repo.delete(id:set.id,expectedRevision:1)
        XCTAssertEqual(try SnapshotCollectionRepository(database:db).collection(id:collection.id),collection)
    }
    func testRevisionOverflowFailsWithoutMutation() throws {
        let set = try repo.create(name:"Bounded revision")
        // A generated corrupted/extreme record exercises SQLite integer bounds.
        try db.execute("DROP TRIGGER trg_drive_sets_revision")
        try db.execute("UPDATE drive_sets SET revision=9223372036854775807")
        try db.execute(CatalogMigrations.driveSetTriggerDefinitions.first { $0.name == "trg_drive_sets_revision" }!.sql)
        XCTAssertThrowsError(try repo.rename(id:set.id,expectedRevision:Int64.max,name:"Overflow"))
        XCTAssertEqual(try repo.set(id:set.id)?.name,"Bounded revision")
        XCTAssertEqual(try repo.set(id:set.id)?.revision,Int64.max)
    }
    func testRelaunchRetainsSetAndMembers() throws {
        let set = try repo.create(name: "Persistent"); let drive = try identities.createDrive(provenance: "synthetic")
        _ = try repo.setMembership(setID: set.id, expectedRevision: 1, driveID: drive.id, expectedDriveRevision: 1, included: true)
        db.close()
        db = try CatalogDatabase(url: directory.appendingPathComponent("generated.sqlite"))
        repo = DriveSetRepository(database: db)
        XCTAssertEqual(try repo.set(id: set.id)?.name,"Persistent")
        XCTAssertEqual(try repo.members(setID: set.id).records,[drive])
    }
    func testUIModelFullManualWorkflowAndErrors() throws {
        let model = DriveSetsModel(database: db)
        XCTAssertTrue(model.sets.isEmpty); XCTAssertNil(model.selected)
        XCTAssertTrue(model.create(name: "UI Set")); let id = try XCTUnwrap(model.selected?.id)
        XCTAssertTrue(model.members.isEmpty)
        XCTAssertTrue(model.createLocalRecord(label: "Unverified local test"))
        let drive = try XCTUnwrap(model.available.first)
        XCTAssertFalse(drive.hardwareVerified); XCTAssertEqual(model.members.count,0)
        XCTAssertTrue(model.membership(drive, included: true)); XCTAssertEqual(model.members.map(\.id),[drive.id])
        XCTAssertTrue(model.rename(name: "Renamed")); XCTAssertEqual(model.selected?.id,id)
        XCTAssertFalse(model.rename(name: "  ")); XCTAssertNotNil(model.error)
        XCTAssertTrue(model.membership(drive,included: false)); XCTAssertTrue(model.members.isEmpty)
        model.refresh(); XCTAssertEqual(model.selected?.name,"Renamed")
        XCTAssertTrue(model.deleteSelected()); XCTAssertTrue(model.sets.isEmpty)
        XCTAssertNotNil(try identities.drive(id: drive.id))
        let reopened = DriveSetsModel(database: db); XCTAssertTrue(reopened.sets.isEmpty)
    }
    func testUIStaleWriteShowsBoundedErrorAndRefreshRepairs() throws {
        let model = DriveSetsModel(database: db); XCTAssertTrue(model.create(name: "Original"))
        let selected = try XCTUnwrap(model.selected)
        _ = try repo.rename(id: selected.id, expectedRevision: selected.revision, name: "Elsewhere")
        XCTAssertFalse(model.rename(name: "Stale")); XCTAssertEqual(model.error,DriveSetError.staleRevision.localizedDescription)
        model.refresh(); XCTAssertEqual(model.selected?.name,"Elsewhere"); XCTAssertNil(model.error)
        XCTAssertTrue(model.rename(name: "Current"))
    }
    func testActualWorkspaceAndShellRenderWithSyntheticCatalog() throws {
        let model = DriveSetsModel(database: db)
        let view = NSHostingView(rootView: DriveSetsView(model: model))
        view.frame = NSRect(x:0,y:0,width:1000,height:650); view.layoutSubtreeIfNeeded()
        XCTAssertTrue(model.create(name:"Rendered Set")); XCTAssertTrue(model.createLocalRecord(label:"Generated record"))
        let drive = try XCTUnwrap(model.available.first); XCTAssertTrue(model.membership(drive,included:true))
        view.layoutSubtreeIfNeeded()
        let shell = NSHostingView(rootView: FSDAppShellView(model: ApplicationModel(catalogForTesting: db), initialDestination: .driveSets))
        shell.frame = NSRect(x:0,y:0,width:1120,height:720); shell.layoutSubtreeIfNeeded()
        XCTAssertEqual(FSDDestination.driveSets.breadcrumb,"Library  /  Drive Sets")
        XCTAssertNotNil(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        XCTAssertNotNil(shell.bitmapImageRepForCachingDisplay(in: shell.bounds))
    }
    /// In-process accessibility is limited to this test's own synthetic window.
    /// No system-wide AX tree, picker or external process is inspected.
    func testWorkspaceButtonsAndSheetsUseRealBackend() throws {
        let model = DriveSetsModel(database: db)
        // Enable the test process's own SwiftUI accessibility tree only.
        let attribute = NSAccessibility.Attribute(rawValue: "AXEnhancedUserInterface")
        let prior = NSApplication.shared.accessibilityAttributeValue(attribute)
        NSApplication.shared.accessibilitySetValue(true, forAttribute: attribute)
        defer { NSApplication.shared.accessibilitySetValue(prior, forAttribute: attribute) }
        let hosting = NSHostingView(rootView: DriveSetsView(model: model))
        let window = NSWindow(contentRect:NSRect(x:0,y:0,width:1120,height:720),styleMask:[.titled,.resizable],backing:.buffered,defer:false)
        window.appearance = NSAppearance(named:.darkAqua)
        window.contentView = hosting; window.makeKeyAndOrderFront(nil)
        defer { window.orderOut(nil) }
        func settle() { hosting.layoutSubtreeIfNeeded(); RunLoop.current.run(until:Date().addingTimeInterval(0.15)) }
        func elements() -> [NSObject] {
            var result: [NSObject] = []
            var seen: Set<ObjectIdentifier> = []
            func visit(_ value: Any, depth: Int) {
                guard depth < 30, result.count < 2000, let element = value as? NSObject,
                      seen.insert(ObjectIdentifier(element)).inserted else { return }
                result.append(element)
                if let view = element as? NSView { for child in view.subviews { visit(child,depth:depth+1) } }
                for child in (element as AnyObject).accessibilityChildren?() ?? [] { visit(child,depth:depth+1) }
                // SwiftUI rows need not formally adopt AppKit row protocols;
                // inspect the Objective-C NSArray without a typed Swift bridge.
                let rowsSelector = NSSelectorFromString("accessibilityRows")
                if element.responds(to:rowsSelector), let rows = element.perform(rowsSelector)?.takeUnretainedValue() as? NSArray {
                    for row in rows.prefix(200) { visit(row,depth:depth+1) }
                }
            }
            visit(window,depth:0)
            for sheet in window.sheets { visit(sheet,depth:0) }
            return result
        }
        func press(_ label: String) throws {
            settle()
            let ownElements = elements()
            let button = try XCTUnwrap(ownElements.first {
                [NSAccessibility.Role.button, .disclosureTriangle].contains(($0 as AnyObject).accessibilityRole?() ?? .unknown) &&
                (($0 as AnyObject).accessibilityLabel?() == label || ($0 as AnyObject).accessibilityTitle?() == label)
            }, "Missing own-window button \(label)")
            let response = (button as AnyObject).accessibilityPerformPress?()
            XCTAssertNotNil(response, "Own-window action must exist")
            print("DRIVE_SETS_UI_PRESS label=\(label) response=\(String(describing:response)); backend/sheet assertions determine effect")
            settle()
        }
        func enter(_ text: String) throws {
            settle()
            // AppKit text editing must notify the SwiftUI control delegate;
            // merely setting an AX value does not commit its Binding.
            func editable(_ view: NSView) -> NSTextField? {
                if let field = view as? NSTextField, field.isEditable { return field }
                return view.subviews.lazy.compactMap(editable).first
            }
            let sheet = try XCTUnwrap(window.sheets.first)
            let field = try XCTUnwrap(sheet.contentView.flatMap(editable))
            sheet.makeFirstResponder(field)
            field.stringValue = text
            field.currentEditor()?.string = text
            field.delegate?.controlTextDidChange?(Notification(name:NSControl.textDidChangeNotification,object:field))
            settle()
        }
        func capture(_ name: String) throws {
            settle()
            let content = try XCTUnwrap(window.contentView)
            let bitmap = try XCTUnwrap(content.bitmapImageRepForCachingDisplay(in:content.bounds))
            content.cacheDisplay(in:content.bounds,to:bitmap)
            let png = try XCTUnwrap(bitmap.representation(using:.png,properties:[:]))
            try png.write(to:URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(".ai-scratch/task060/" + name + ".png"))
        }
        settle()
        try capture("workspace-empty")
        try press("New Drive Set"); try enter("Clicked Set"); try press("Save")
        XCTAssertEqual(model.selected?.name,"Clicked Set")
        XCTAssertEqual(try repo.list().records.map(\.name),["Clicked Set"])
        try press("Rename"); try enter("Clicked Rename"); try press("Save")
        XCTAssertEqual(model.selected?.name,"Clicked Rename")
        try press("Add Local Records")
        XCTAssertEqual(window.sheets.count,1)
        try press("New Unverified Local Record")
        try enter("Clicked Local Record"); try press("Create Local Record")
        XCTAssertEqual(model.available.count,1); XCTAssertTrue(model.members.isEmpty)
        if let content = window.sheets.first?.contentView, let bitmap = content.bitmapImageRepForCachingDisplay(in:content.bounds) {
            content.cacheDisplay(in:content.bounds,to:bitmap)
            let png = try XCTUnwrap(bitmap.representation(using:.png,properties:[:]))
            try png.write(to:URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(".ai-scratch/task060/add-sheet.png"))
        }
        try press("Add"); XCTAssertEqual(model.members.count,1)
        try press("Done")
        try capture("workspace-member-1120")
        window.setContentSize(NSSize(width:1330,height:720))
        try capture("workspace-member-1330")
        try press("Remove"); try press("Remove from Set")
        XCTAssertTrue(model.members.isEmpty)
        try press("Delete Set"); try press("Delete Drive Set")
        XCTAssertTrue(try repo.list().records.isEmpty)
    }

}
