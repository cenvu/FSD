import XCTest
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
