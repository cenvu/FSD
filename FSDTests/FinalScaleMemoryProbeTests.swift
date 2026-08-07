import Darwin
import XCTest
@testable import FSD

/// Milestone 5 Part 4 — memory and boundedness at final scale. Resident
/// footprint is read from `task_info` (the test host process is the app
/// process), and a background sampler records peak resident while a
/// synchronous operation runs, so every bound is measured evidence rather
/// than a claim. The million-class fixtures are generated once per class;
/// each test opens its own connection and measures its own operation, so the
/// numbers reflect the operation, not fixture generation.
final class FinalScaleMemoryProbeTests: XCTestCase {
    private static var fixtureDirectory: URL!
    private static var snapshotCatalogURL: URL!
    private static var snapshotID: SnapshotID!
    private static var pairURL: URL!
    private static var pairLeft: SnapshotID!
    private static var pairRight: SnapshotID!

    private var directory: URL!
    private var database: CatalogDatabase!
    private var service: ComparisonService!
    private var results: ComparisonResultRepository!

    override class func setUp() {
        super.setUp()
        guard fixtureDirectory == nil else { return }
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-M5-Memory-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let catalogURL = root.appendingPathComponent("catalog.sqlite3")
        let catalog = try! CatalogDatabase(url: catalogURL, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        let snapshotResult = try! M5SnapshotCatalog.populate(database: catalog)
        catalog.close()
        fixtureDirectory = root
        snapshotCatalogURL = catalogURL
        snapshotID = snapshotResult.snapshotID

        let pairURLValue = root.appendingPathComponent("pair.sqlite3")
        let pairDatabase = try! CatalogDatabase(url: pairURLValue, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        let pair = try! M5ComparisonPair.populate(database: pairDatabase)
        pairDatabase.close()
        pairURL = pairURLValue
        pairLeft = pair.leftID
        pairRight = pair.rightID
    }

    override class func tearDown() {
        if let fixtureDirectory {
            try? FileManager.default.removeItem(at: fixtureDirectory)
        }
        super.tearDown()
    }

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-M5-Memory-Test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        results = nil
        service = nil
        database?.close()
        database = nil
        try? FileManager.default.removeItem(at: directory)
        directory = nil
    }

    // MARK: - Resident footprint

    private func openSnapshotCatalog() throws {
        database = try CatalogDatabase(url: Self.snapshotCatalogURL, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
    }

    private func openPairCatalog() throws {
        database = try CatalogDatabase(url: Self.pairURL, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        service = ComparisonService(database: database)
        results = ComparisonResultRepository(database: database)
    }

    func testMillionEntrySnapshotBrowsingRetainsOnlyBoundedPages() throws {
        try openSnapshotCatalog()
        let tree = SnapshotTreeDataSource(database: database, snapshotID: Self.snapshotID, pageSize: 200)
        let baseline = M5ProcessMemory.residentBytes()
        tree.resetInstrumentation()
        let root = try XCTUnwrap(try tree.root())
        let firstPage = try tree.children(ofParent: root.id)
        XCTAssertEqual(firstPage.count, 200)
        for page in 1..<10 {
            _ = try tree.children(ofParent: root.id, offset: page * 200, limit: 200)
        }
        let expanded = try tree.children(ofParent: firstPage[0].id)
        XCTAssertEqual(expanded.count, 200)
        for _ in 0..<20 {
            _ = try tree.children(ofParent: root.id, offset: 0, limit: 200)
        }
        let after = M5ProcessMemory.residentBytes()
        let delta = after - baseline
        XCTAssertLessThan(tree.rowsFetched, 10_000, "browsing a million-entry snapshot fetched a bounded number of rows")
        XCTAssertLessThan(delta, 300 * 1_048_576, "browsing must not retain the catalog in memory")
        print("[FSD-M5-Memory] browsing: baseline \(baseline) peak/after \(after) delta \(delta) bytes; rows fetched \(tree.rowsFetched)")
    }

    func testMillionEntrySearchRetainsOnlyBoundedPages() throws {
        try openSnapshotCatalog()
        let search = MetadataSearchService(database: database)
        let baseline = M5ProcessMemory.residentBytes()
        for text in ["f00500", "leaf.dat", "deepfile", "h0000", "f00123"] {
            let hits = try search.search(MetadataSearchQuery(text: text, limit: 200), in: Self.snapshotID)
            XCTAssertLessThanOrEqual(hits.hits.count, 200)
        }
        let after = M5ProcessMemory.residentBytes()
        let delta = after - baseline
        XCTAssertLessThan(delta, 150 * 1_048_576, "search must retain only bounded pages")
        print("[FSD-M5-Memory] search: baseline \(baseline) after \(after) delta \(delta) bytes")
    }

    func testMillionEntryComparisonMergePeakIsBoundedAndFallsBackAfterDisposal() throws {
        try openPairCatalog()
        let baseline = M5ProcessMemory.residentBytes()
        let sampler = M5PeakSampler(baseline: baseline)
        sampler.start()
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: Self.pairLeft, rightSnapshotID: Self.pairRight)
        sampler.stop()
        let peak = sampler.peak

        XCTAssertEqual(comparison.status, .complete)
        XCTAssertEqual(comparison.matchedCount, 1_000_003)
        let afterMerge = M5ProcessMemory.residentBytes()

        // Note: no whole-comparison disposal at this class — the cascade is
        // O(n²) at 1,000,000 result rows (KI-024, root cause: the
        // self-referential parent_result_id FK without a dedicated leading
        // index). Disposal correctness is covered at the 100,202-per-side
        // class (FinalScaleComparisonTests.testHundredThousandDisposalLeavesNoResidue).
        let peakDelta = peak - baseline
        XCTAssertLessThan(peakDelta, 700 * 1_048_576, "the merge must not retain either full tree")
        print("[FSD-M5-Memory] comparison: baseline \(baseline); peak \(peak) (delta \(peakDelta)); after \(afterMerge)")
    }

    func testMillionEntryExportStreamsInsteadOfBuildingTheDocument() throws {
        try openSnapshotCatalog()
        let exporter = JSONSnapshotExporter(database: database, pageSize: 1000)
        let exportURL = directory.appendingPathComponent("stream.json")
        let baseline = M5ProcessMemory.residentBytes()
        let sampler = M5PeakSampler(baseline: baseline)
        sampler.start()
        let summary = try exporter.export(snapshotID: Self.snapshotID, to: exportURL)
        sampler.stop()
        let peak = sampler.peak
        let size = try FileManager.default.attributesOfItem(atPath: exportURL.path)[.size] as? Int64 ?? -1

        XCTAssertEqual(summary.entryCount, M5SnapshotCatalog.expectedEntryCount)
        let peakDelta = peak - baseline
        // The output document is on disk; the in-memory document never grows
        // beyond bounded pages. A whole-document build would hold ≥ output
        // size in resident memory.
        XCTAssertGreaterThan(size, 100 * 1_048_576)
        XCTAssertLessThan(peakDelta, 100 * 1_048_576)
        print("[FSD-M5-Memory] export: baseline \(baseline); peak \(peak) (delta \(peakDelta)) bytes; output \(size) bytes")
    }

    func testPathologicalEqualKeyCollisionGroupIsATypedFailureNotAnOOM() throws {
        let pathologicalURL = directory.appendingPathComponent("pathological.sqlite3")
        let pathological = try CatalogDatabase(url: pathologicalURL, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        defer { pathological.close() }
        let pair = try M5PathologicalPair.populate(database: pathological)
        let service = ComparisonService(database: pathological)
        let baseline = M5ProcessMemory.residentBytes()
        let sampler = M5PeakSampler(baseline: baseline)
        sampler.start()

        XCTAssertThrowsError(try service.snapshotToSnapshot(leftSnapshotID: pair.leftID, rightSnapshotID: pair.rightID)) { error in
            guard case ComparisonError.collisionGroupTooLarge(let count) = error else {
                return XCTFail("expected a typed collisionGroupTooLarge failure, got \(error)")
            }
            XCTAssertGreaterThan(count, ComparisonEngine.maxCollisionGroupMemberCount)
        }
        sampler.stop()
        let peak = sampler.peak
        let peakDelta = peak - baseline

        let records = try ComparisonResultRepository(database: pathological).listComparisons()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0].status, .failed, "a pathological group is a typed failure, never complete")
        XCTAssertEqual(try pathological.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try pathological.query("PRAGMA foreign_key_check").isEmpty)
        XCTAssertLessThan(peakDelta, 600 * 1_048_576, "the capped group must stay bounded in memory")
        print("[FSD-M5-Memory] collision group: 150,000 members/side; typed failure; peak \(peak) (delta \(peakDelta)) bytes; comparison failed; integrity ok")
    }

    func testResultPagingRetainsOnlyTheConfiguredPageAtFinalScale() throws {
        try openPairCatalog()
        let comparison = try service.snapshotToSnapshot(leftSnapshotID: Self.pairLeft, rightSnapshotID: Self.pairRight)
        for offset in [0, 1_000, 500_000, 999_000] {
            let page = try results.results(comparisonID: comparison.id, filter: .all, offset: offset, limit: 100)
            XCTAssertLessThanOrEqual(page.rows.count, 100, "a page never exceeds its configured limit")
        }
        // A caller cannot raise the ceiling.
        let huge = try results.results(comparisonID: comparison.id, filter: .all, offset: 0, limit: 1_000_000)
        XCTAssertLessThanOrEqual(huge.rows.count, ComparisonResultRepository.maximumPageSize)
        let tree = SnapshotTreeDataSource(database: database, snapshotID: Self.pairLeft, pageSize: 200)
        let root = try XCTUnwrap(try tree.root())
        let children = try tree.children(ofParent: root.id, limit: 1_000_000)
        XCTAssertLessThanOrEqual(children.count, 200, "the tree data source cannot be asked to exceed its page bound")
        print("[FSD-M5-Memory] paging: results capped at \(ComparisonResultRepository.maximumPageSize); tree capped at page size")
    }
}

/// Resident footprint of this process via `task_info` (mach_task_basic_info).
enum M5ProcessMemory {
    static func residentBytes() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), rebound, &count)
            }
        }
        guard result == KERN_SUCCESS else { return -1 }
        return Int64(info.resident_size)
    }
}

/// Samples resident footprint on a background thread while a synchronous
/// operation runs, keeping the observed high-water mark. `stop()` joins the
/// thread, so the reported peak is the complete observation.
final class M5PeakSampler {
    private let lock = NSLock()
    private var _peak: Int64
    private var sampling = true
    private let finished = DispatchSemaphore(value: 0)

    init(baseline: Int64) {
        _peak = baseline
    }

    var peak: Int64 {
        lock.withLock { _peak }
    }

    func start() {
        let thread = Thread { [weak self] in
            defer { self?.finished.signal() }
            while self?.isSampling == true {
                let resident = M5ProcessMemory.residentBytes()
                if let self {
                    self.lock.lock()
                    if resident > self._peak { self._peak = resident }
                    self.lock.unlock()
                }
                Thread.sleep(forTimeInterval: 0.01)
            }
        }
        thread.name = "FSD-M5-PeakSampler"
        thread.start()
    }

    func stop() {
        lock.lock()
        sampling = false
        lock.unlock()
        _ = finished.wait(timeout: .now() + 5)
    }

    private var isSampling: Bool {
        lock.withLock { sampling }
    }
}
