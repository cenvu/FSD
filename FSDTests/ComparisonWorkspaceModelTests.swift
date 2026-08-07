import XCTest
@testable import FSD

@MainActor
final class ComparisonWorkspaceModelTests: XCTestCase {
    var database: CatalogDatabase!
    var model: ComparisonWorkspaceModel!
    
    override func setUpWithError() throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sqlite")
        database = try CatalogDatabase(url: tempURL)
        model = ComparisonWorkspaceModel(database: database)
        // Give it a dummy profile selection so we can test modes
        model.selectedProfileID = 1
    }
    
    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: database.url)
    }
    
    func testInitialState() {
        XCTAssertEqual(model.mode, .snapshotToSnapshot)
        XCTAssertFalse(model.isRunning)
        XCTAssertFalse(model.canStart)
    }
    
    func testCanStartSnapshotToSnapshot() {
        model.mode = .snapshotToSnapshot
        XCTAssertFalse(model.canStart)
        
        model.selectedLeftSnapshotID = SnapshotID(rawValue: 1)
        model.selectedRightSnapshotID = SnapshotID(rawValue: 2)
        XCTAssertTrue(model.canStart)
        
        // Cannot select same snapshot
        model.selectedRightSnapshotID = SnapshotID(rawValue: 1)
        XCTAssertFalse(model.canStart)
    }
    
    func testCanStartLiveToSnapshot() {
        // Canonical orientation: the snapshot is the left/reference side and
        // the live folder is the right/changed side (ADR-027).
        model.mode = .liveToSnapshot
        XCTAssertFalse(model.canStart)

        model.selectedLeftSnapshotID = SnapshotID(rawValue: 1)
        XCTAssertFalse(model.canStart) // Needs right live folder

        model.selectedRightLiveRoot = URL(fileURLWithPath: "/tmp/a")
        XCTAssertTrue(model.canStart)
    }
    
    func testCanStartLiveToLive() {
        model.mode = .liveToLive
        XCTAssertFalse(model.canStart)
        
        model.selectedLeftLiveRoot = URL(fileURLWithPath: "/tmp/a")
        model.selectedRightLiveRoot = URL(fileURLWithPath: "/tmp/b")
        XCTAssertTrue(model.canStart)
        
        // Cannot select same folder
        model.selectedRightLiveRoot = URL(fileURLWithPath: "/tmp/a")
        XCTAssertFalse(model.canStart)
    }
    
    func testModeChangeResetsState() {
        model.selectedLeftSnapshotID = SnapshotID(rawValue: 1)
        model.selectedLeftLiveRoot = URL(fileURLWithPath: "/tmp/a")
        
        model.mode = .liveToSnapshot
        
        XCTAssertNil(model.selectedLeftSnapshotID)
        XCTAssertNil(model.selectedLeftLiveRoot)
    }
}
