import XCTest
@testable import FSD

/// P15 Slice 06 — `docs/TEST_PLAN.md` §9 "no automatic invocation".
///
/// Each of the eight forbidden workflows gets its own test identity and its own
/// pair of assertions:
///
/// * `CLASSIFICATION_START_COUNT` — measured at the real start seam. Workflows
///   whose production entry point owns a `SelectedEntryClassificationControl`
///   are measured with a counting spy injected there. Workflows that own no
///   classification capability at all are measured on the one app-scoped
///   runtime: `generation` advances only on `start` or `cancel`, so an
///   unchanged generation across the workflow proves no run was admitted. Each
///   such test additionally proves the capability is absent from that
///   workflow's production source, so the measurement is not vacuous.
/// * `CLASSIFICATION_ROW_DELTA` — `entry_classifications` row count measured
///   before and after the workflow against the same catalog.
///
/// Constructing a runtime or a provider is never counted as invocation.
@MainActor
final class ClassificationInvocationIsolationTests: XCTestCase {
    private var directory: URL!
    private var source: URL!
    private var database: CatalogDatabase!
    private var summary: SnapshotSummary!
    private var sourceBytes: Data!

    override func setUp() async throws {
        // Normalize the shared runtime so a previous class's terminal state can
        // never be mistaken for this workflow's evidence. This is a no-op on an
        // idle runtime and is never an invocation.
        await ClassificationRuntimeService.shared.cancel()
        await ClassificationRuntimeService.shared.waitForCleanup()

        try await super.setUp()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-Slice06-Isolation-\(UUID().uuidString)", isDirectory: true)
        source = directory.appendingPathComponent("source", isDirectory: true)
        try FileManager.default.createDirectory(at: source.appendingPathComponent("nested"), withIntermediateDirectories: true)
        database = try CatalogDatabase(
            url: directory.appendingPathComponent("catalog.sqlite3"),
            schemaURL: CatalogSchemaFixture.canonicalSchemaURL
        )
        // A real capture gives every workflow below a real snapshot with real
        // source identity, so no workflow is exercised against a synthetic stub.
        sourceBytes = Data((0..<5000).map { UInt8(truncatingIfNeeded: ($0 &* 17) &+ 3) })
        try sourceBytes.write(to: source.appendingPathComponent("nested/payload.bin"))
        try Data("plain text entry".utf8).write(to: source.appendingPathComponent("note.txt"))
        let captured = try SnapshotScanner(database: database).capture(root: source)
        let found = try XCTUnwrap(try SnapshotHistoryRepository(database: database).listSnapshots()
            .first { $0.id == captured.id })
        summary = found
    }

    override func tearDown() async throws {
        await ClassificationRuntimeService.shared.cancel()
        await ClassificationRuntimeService.shared.waitForCleanup()
        database?.close()
        database = nil
        try? FileManager.default.removeItem(at: directory)
        directory = nil
        source = nil
        summary = nil
        sourceBytes = nil
        try await super.tearDown()
    }

    // MARK: - Shared measurement

    /// One observation of every classification capability, taken either side of
    /// a workflow. Both components must be identical afterwards.
    private struct InvocationLedger: Equatable {
        var seamStarts: [Int64]
        var runtimeGeneration: UInt64
        var runtimeActive: Bool
        var classificationRows: Int64

        var startCount: Int { seamStarts.count }
    }

    /// The counting spy used wherever a workflow owns a start seam.
    private final class CountingStartSpy: @unchecked Sendable {
        private let lock = NSLock()
        private(set) var starts: [Int64] = []
        func record(_ entryID: Int64) { lock.withLock { starts.append(entryID) } }
        var recorded: [Int64] { lock.withLock { starts } }
    }

    private func observe(spy: CountingStartSpy?) async throws -> InvocationLedger {
        let runtime = ClassificationRuntimeService.shared
        return InvocationLedger(
            seamStarts: spy?.recorded ?? [],
            runtimeGeneration: await runtime.generation,
            runtimeActive: await runtime.isActive,
            classificationRows: try EntrySnapshotProbe.classificationRowCount(database: database)
        )
    }

    /// Asserts the one §9 requirement every forbidden workflow shares.
    private func assertNoInvocation(
        _ workflow: String,
        before: InvocationLedger,
        after: InvocationLedger
    ) {
        XCTAssertEqual(after.seamStarts.count, before.seamStarts.count,
                       "\(workflow): CLASSIFICATION_START_COUNT must stay 0")
        XCTAssertEqual(after.seamStarts, before.seamStarts,
                       "\(workflow): no entry may be classified by this workflow")
        XCTAssertEqual(after.runtimeGeneration, before.runtimeGeneration,
                       "\(workflow): the app-scoped runtime admitted no run (generation advances only on start or cancel)")
        XCTAssertFalse(after.runtimeActive, "\(workflow): no classification run may remain active")
        XCTAssertEqual(after.classificationRows, before.classificationRows,
                       "\(workflow): CLASSIFICATION_ROW_DELTA must stay 0")
    }

    /// Proves a workflow's own production code holds no classification
    /// capability, so its zero-count measurement is not merely unobserved.
    private func assertNoClassificationCapability(in relativePath: String,
                                                 forbidden: [String],
                                                 line: UInt = #line) throws {
        let file = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent(relativePath)
        let text = try String(contentsOf: file, encoding: .utf8)
        for token in forbidden {
            XCTAssertFalse(text.contains(token), "\(relativePath) must not contain \(token)", line: line)
        }
    }

    private func makeBrowser(spy: CountingStartSpy) -> SnapshotBrowserModel {
        SnapshotBrowserModel(
            database: database,
            summary: summary,
            runtime: .shared,
            control: SelectedEntryClassificationControl(
                start: { entryID in
                    spy.record(entryID)
                    return .unavailable
                },
                cancel: {}
            )
        )
    }

    // MARK: - 1. Capture

    func testCaptureWorkflowNeverStartsClassification() async throws {
        let spy = CountingStartSpy()
        let before = try await observe(spy: spy)
        let fresh = directory.appendingPathComponent("capture-source-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: fresh, withIntermediateDirectories: true)
        try Data("captured now".utf8).write(to: fresh.appendingPathComponent("capture.txt"))

        let record = try SnapshotScanner(database: database).capture(root: fresh)
        let listed = try SnapshotHistoryRepository(database: database).listSnapshots()
        XCTAssertTrue(listed.contains { $0.id == record.id }, "the capture itself must have worked")

        let after = try await observe(spy: spy)
        XCTAssertEqual(after.classificationRows - before.classificationRows, 0)
        assertNoInvocation("capture", before: before, after: after)
        try assertNoClassificationCapability(in: "FSD/Scanner/SnapshotScanner.swift", forbidden: [
            "ClassificationRuntimeService", "EntryClassificationRepository", "LocalClassificationRequest",
            "LocalFileClassificationProvider", "BoundedClassificationSourceReader"
        ])
    }

    // MARK: - 2. Application launch

    func testApplicationLaunchNeverStartsClassification() async throws {
        let spy = CountingStartSpy()
        let before = try await observe(spy: spy)

        // A real application launch: the production startup path resolves the
        // test host's own catalog, reconciles it and lists history.
        let app = ApplicationModel()
        XCTAssertTrue(app.classificationRuntime === ClassificationRuntimeService.shared,
                      "launch must own/inject the one app-scoped runtime")
        let launchActive = await app.classificationRuntime.isActive
        XCTAssertFalse(launchActive, "a launch must leave no classification run active")

        let after = try await observe(spy: spy)
        XCTAssertEqual(after.classificationRows - before.classificationRows, 0)
        assertNoInvocation("application launch", before: before, after: after)
        try assertNoClassificationCapability(in: "FSD/App/FSDApp.swift", forbidden: [
            "classificationRuntime.start(", "classifySelectedFile()", "BundledMagikaClassificationProvider(",
            "LocalClassificationRequest", "BoundedClassificationSourceReader", "EntryClassificationRepository"
        ])
    }

    // MARK: - 3. History open

    func testHistoryOpenNeverStartsClassification() async throws {
        let spy = CountingStartSpy()
        let before = try await observe(spy: spy)

        let history = SnapshotHistoryRepository(database: database)
        let listed = try history.listSnapshots()
        XCTAssertTrue(listed.contains { $0.id == summary.id })
        _ = try history.listSnapshots(kind: .user)
        _ = try history.issues(for: summary.id, limit: 100)
        _ = try history.listSnapshots(kind: .transient)
        XCTAssertEqual(Set(listed.map(\.id)), Set(try history.listSnapshots().map(\.id)),
                       "reopening history is stable and non-mutating")

        let after = try await observe(spy: spy)
        XCTAssertEqual(after.classificationRows - before.classificationRows, 0)
        assertNoInvocation("history open", before: before, after: after)
        try assertNoClassificationCapability(in: "FSD/Catalog/SnapshotHistoryRepository.swift", forbidden: [
            "ClassificationRuntimeService", "EntryClassificationRepository", "LocalClassificationRequest",
            "LocalFileClassificationProvider", "BoundedClassificationSourceReader"
        ])
    }

    // MARK: - 4. Snapshot reopen

    func testSnapshotReopenNeverStartsClassification() async throws {
        let spy = CountingStartSpy()
        let before = try await observe(spy: spy)

        // Mirrors `ApplicationModel.openSnapshot`: a fresh browser bound to the
        // app-scoped runtime, opened, closed and opened again.
        let first = makeBrowser(spy: spy)
        first.open()
        XCTAssertNotNil(first.rootNode)
        first.cancelClassificationForSnapshotClose()
        let second = makeBrowser(spy: spy)
        second.open()
        XCTAssertNotNil(second.rootNode)
        XCTAssertTrue(first.classificationRuntime === second.classificationRuntime)

        let after = try await observe(spy: spy)
        XCTAssertEqual(after.classificationRows - before.classificationRows, 0)
        assertNoInvocation("snapshot reopen", before: before, after: after)
        try assertNoClassificationCapability(in: "FSD/App/FSDApp.swift", forbidden: [
            "classificationRuntime.start(", "classifySelectedFile()"
        ])
    }

    // MARK: - 5. Browsing / selection

    func testBrowsingAndSelectionNeverStartClassification() async throws {
        let spy = CountingStartSpy()
        let before = try await observe(spy: spy)
        let model = makeBrowser(spy: spy)

        model.open()
        XCTAssertNotNil(model.rootNode)
        let fileID = try XCTUnwrap(try database.scalar(
            "SELECT id FROM entries WHERE snapshot_id = ? AND relative_path = 'note.txt'",
            bindings: [.integer(summary.id.rawValue)]
        )?.int64Value)
        model.select(entryID: fileID)
        XCTAssertEqual(model.selectedEntryID, fileID)
        XCTAssertNotNil(try model.classificationDetails(for: fileID))
        // The explicit affordance exists but is inert until the user invokes it.
        XCTAssertTrue(model.canClassifySelectedFile)
        model.select(entryID: nil)
        model.select(entryID: fileID)

        let after = try await observe(spy: spy)
        XCTAssertEqual(after.classificationRows - before.classificationRows, 0)
        assertNoInvocation("browsing/selection", before: before, after: after)
    }

    // MARK: - 6. Search

    func testSearchNeverStartsClassification() async throws {
        let spy = CountingStartSpy()
        let before = try await observe(spy: spy)
        let model = makeBrowser(spy: spy)
        model.open()

        // The production metadata search, run through the browser's own model.
        model.searchText = "note"
        model.runSearch()
        XCTAssertTrue(model.isSearching, "runSearch must actually dispatch the background query")
        model.searchText = "payload"
        model.runSearch()
        // Let every dispatched main-queue completion run before measuring.
        for _ in 0..<32 { await Task.yield() }
        model.clearSearch()
        XCTAssertNil(model.searchResults)
        // The search service itself, called directly on the same catalog.
        let direct = try MetadataSearchService(database: database).search(
            MetadataSearchQuery(text: "note", field: .nameOrPath), in: summary.id
        )
        XCTAssertEqual(direct.hits.count, 1)

        let after = try await observe(spy: spy)
        XCTAssertEqual(after.classificationRows - before.classificationRows, 0)
        assertNoInvocation("search", before: before, after: after)
        try assertNoClassificationCapability(in: "FSD/Search/MetadataSearchService.swift", forbidden: [
            "ClassificationRuntimeService", "EntryClassificationRepository", "LocalClassificationRequest",
            "LocalFileClassificationProvider", "BoundedClassificationSourceReader"
        ])
    }

    // MARK: - 7. Comparison

    func testComparisonNeverStartsClassification() async throws {
        let spy = CountingStartSpy()
        let before = try await observe(spy: spy)

        // A real snapshot-to-snapshot comparison over the captured pair.
        let right = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 9, session: 2)
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: right, entries: [
            SyntheticSnapshot.root(id: 900),
            SyntheticSnapshot.SeedEntry(id: 901, parentID: 900, relativePath: "note.txt", name: "note.txt",
                                        logicalSizeBytes: 17, allocatedSizeBytes: 17)
        ])
        try SyntheticSnapshot.complete(database: database, snapshotID: right)
        let record = try ComparisonService(database: database).snapshotToSnapshot(
            leftSnapshotID: summary.id, rightSnapshotID: right
        )
        XCTAssertEqual(record.status, .complete)
        XCTAssertGreaterThan(record.matchedCount + record.changedCount + record.addedCount + record.removedCount, 0)

        let after = try await observe(spy: spy)
        XCTAssertEqual(after.classificationRows - before.classificationRows, 0)
        assertNoInvocation("comparison", before: before, after: after)
        try assertNoClassificationCapability(in: "FSD/Diff/ComparisonEngine.swift", forbidden: [
            "ClassificationRuntimeService", "EntryClassificationRepository", "LocalClassificationRequest",
            "LocalFileClassificationProvider", "BoundedClassificationSourceReader"
        ])
    }

    // MARK: - 8. JSON export

    func testJSONExportNeverStartsClassification() async throws {
        let spy = CountingStartSpy()
        let before = try await observe(spy: spy)
        let model = makeBrowser(spy: spy)
        model.open()

        // The exact exporter call the browser's own export action makes, minus
        // the save panel, which cannot run headless.
        var exported = ""
        let result = try JSONSnapshotExporter(database: database).write(snapshotID: summary.id) { chunk in
            exported += chunk
        }
        XCTAssertGreaterThan(result.entryCount, 0)
        XCTAssertFalse(exported.contains("classification"))

        let after = try await observe(spy: spy)
        XCTAssertEqual(after.classificationRows - before.classificationRows, 0)
        assertNoInvocation("JSON export", before: before, after: after)
        try assertNoClassificationCapability(in: "FSD/Export/JSONSnapshotExporter.swift", forbidden: [
            "ClassificationRuntimeService", "EntryClassificationRepository", "LocalClassificationRequest",
            "LocalFileClassificationProvider", "BoundedClassificationSourceReader"
        ])
    }
}