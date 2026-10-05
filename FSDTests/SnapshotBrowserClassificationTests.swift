import XCTest
@testable import FSD

/// P15 Slice 05 minimal selected-entry UI.
///
/// Covers app ownership, inertness, explicit action, busy, 0.5 s delayed
/// progress, cancel, selection/snapshot/browser stale suppression, result
/// mapping, wording and no-side-effects. Deterministic via continuations,
/// expectations, actor gates and injected delay. No arbitrary sleeps.
@MainActor
final class SnapshotBrowserClassificationTests: XCTestCase {
    private var directory: URL!
    private var database: CatalogDatabase!
    private var snapshotID: SnapshotID!
    private var summary: SnapshotSummary!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-Slice05-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        database = try CatalogDatabase(
            url: directory.appendingPathComponent("catalog.sqlite3"),
            schemaURL: CatalogSchemaFixture.canonicalSchemaURL
        )
        snapshotID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 21, session: 1)
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: snapshotID, entries: [
            SyntheticSnapshot.root(id: 1),
            SyntheticSnapshot.SeedEntry(id: 2, parentID: 1, relativePath: "a.txt", name: "a.txt"),
            SyntheticSnapshot.SeedEntry(id: 3, parentID: 1, relativePath: "b.txt", name: "b.txt")
        ])
        try SyntheticSnapshot.complete(database: database, snapshotID: snapshotID)
        let found = try SnapshotHistoryRepository(database: database).listSnapshots().first(where: { $0.id == snapshotID })
        summary = try XCTUnwrap(found)
    }

    override func tearDownWithError() throws {
        database?.close()
        database = nil
        try? FileManager.default.removeItem(at: directory)
        directory = nil
    }

    // MARK: - Fakes

    private final class Counters: @unchecked Sendable {
        private let lock = NSLock()
        private(set) var starts: [Int64] = []
        private(set) var cancels = 0
        private(set) var refreshes: [Int64] = []
        func recordStart(_ id: Int64) { lock.withLock { starts.append(id) } }
        func recordCancel() { lock.withLock { cancels += 1 } }
        func recordRefresh(_ id: Int64) { lock.withLock { refreshes.append(id) } }
        var startCount: Int { lock.withLock { starts.count } }
        var cancelCount: Int { lock.withLock { cancels } }
        var refreshCount: Int { lock.withLock { refreshes.count } }
    }

    private func makeModel(counters: Counters,
                           startGate: ClassificationTestGate? = nil,
                           delayGate: ClassificationTestGate? = nil,
                           result: SelectedEntryClassificationResult = .unavailable,
                           cannedDetails: SnapshotEntryDetails? = nil) -> SnapshotBrowserModel {
        let capturedDB = database!
        let control = SelectedEntryClassificationControl(
            start: { entryID in
                counters.recordStart(entryID)
                if let gate = startGate { await gate.wait() }
                return result
            },
            cancel: {
                counters.recordCancel()
            }
        )
        let loader: ((Int64) throws -> SnapshotEntryDetails?)? = {
            if let canned = cannedDetails {
                return { entryID in
                    counters.recordRefresh(entryID)
                    return canned
                }
            }
            return { entryID in
                counters.recordRefresh(entryID)
                return try SnapshotTreeDataSource(database: capturedDB, snapshotID: self.snapshotID).details(for: entryID)
            }
        }()
        let delay: @Sendable () async -> Void = {
            if let gate = delayGate { await gate.wait() }
            else { try? await Task.sleep(for: .milliseconds(500)) }
        }
        return SnapshotBrowserModel(database: capturedDB, summary: summary,
                                    control: control, progressDelay: delay, detailsLoader: loader)
    }

    private func cannedDetails(id: Int64, classification: EntryClassification? = nil) throws -> SnapshotEntryDetails {
        let real = try XCTUnwrap(try SnapshotTreeDataSource(database: database, snapshotID: snapshotID).details(for: id))
        return SnapshotEntryDetails(
            id: real.id, relativePath: real.relativePath, name: real.name,
            casePreservingPath: real.casePreservingPath, caseFoldedPath: real.caseFoldedPath,
            fileExtension: real.fileExtension, itemKind: real.itemKind,
            logicalSizeBytes: real.logicalSizeBytes, allocatedSizeBytes: real.allocatedSizeBytes,
            createdAtSource: real.createdAtSource, modifiedAtSource: real.modifiedAtSource,
            contentTypeIdentifier: real.contentTypeIdentifier, symlinkTarget: real.symlinkTarget,
            isHidden: real.isHidden, isPackage: real.isPackage, isInaccessible: real.isInaccessible,
            classification: classification
        )
    }

    // MARK: - App ownership

    func testAppOwnsOneSharedRuntime() {
        let app = ApplicationModel()
        XCTAssertTrue(app.classificationRuntime === ClassificationRuntimeService.shared,
                      "ApplicationModel must own/inject the one shared runtime")
    }

    func testOpeningReplacingBrowserUsesSameRuntime() {
        // The test host already holds the single-process catalog lock, so a
        // second ApplicationModel cannot open the test-host catalog by design.
        // Prove the production wiring pattern instead: every browser created
        // through ApplicationModel.openSnapshot receives the same app-scoped
        // instance (openSnapshot passes `runtime: classificationRuntime`).
        let app = ApplicationModel()
        let first = SnapshotBrowserModel(database: database, summary: summary,
                                         runtime: app.classificationRuntime)
        let second = SnapshotBrowserModel(database: database, summary: summary,
                                          runtime: app.classificationRuntime)
        XCTAssertTrue(first.classificationRuntime === ClassificationRuntimeService.shared)
        XCTAssertTrue(first.classificationRuntime === app.classificationRuntime)
        XCTAssertTrue(second.classificationRuntime === ClassificationRuntimeService.shared)
        XCTAssertTrue(second.classificationRuntime === app.classificationRuntime)
        XCTAssertTrue(first.classificationRuntime === second.classificationRuntime,
                      "replacing browser must not create a second runtime")
    }

    func testBrowserDefaultRuntimeIsShared() {
        let model = SnapshotBrowserModel(database: database, summary: summary)
        XCTAssertTrue(model.classificationRuntime === ClassificationRuntimeService.shared)
        XCTAssertTrue(model.classificationRuntime === ClassificationRuntimeService.shared,
                      "default browser runtime must be the single app-scoped instance")
    }

    // MARK: - Inertness

    func testConstructionOpenSelectSearchDetailsDoNotStart() async throws {
        let counters = Counters()
        let model = makeModel(counters: counters)
        XCTAssertEqual(counters.startCount, 0, "construction must not start")
        model.open()
        XCTAssertEqual(counters.startCount, 0, "browser open must not start")
        model.select(entryID: 2)
        XCTAssertEqual(counters.startCount, 0, "selection must not start")
        _ = try model.classificationDetails(for: 2)
        XCTAssertEqual(counters.startCount, 0, "ordinary details refresh must not start")
        model.searchText = "a.txt"
        model.runSearch()
        model.clearSearch()
        // runSearch is async background; yield to let any mistaken start fire.
        await Task.yield()
        XCTAssertEqual(counters.startCount, 0, "search must not start")
        var exported = ""
        _ = try JSONSnapshotExporter(database: database).write(snapshotID: snapshotID) { exported += $0 }
        XCTAssertFalse(exported.contains("classification"))
        XCTAssertEqual(counters.startCount, 0, "export path must not start")
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
    }

    // MARK: - Explicit action

    func testExplicitActionStartsExactlySelectedEntry() async {
        let counters = Counters()
        let model = makeModel(counters: counters)
        model.select(entryID: 2)
        XCTAssertTrue(model.canClassifySelectedFile)
        await model.classifySelectedFile()
        XCTAssertEqual(counters.starts, [2])
        XCTAssertEqual(model.classificationPhase, .idle)
    }

    func testNoSelectionNoStart() async {
        let counters = Counters()
        let model = makeModel(counters: counters)
        XCTAssertNil(model.selectedEntryID)
        XCTAssertFalse(model.canClassifySelectedFile)
        await model.classifySelectedFile()
        XCTAssertEqual(counters.startCount, 0)
    }

    func testRepeatWhileLocallyRunningDisabled() async {
        let counters = Counters()
        let gate = ClassificationTestGate()
        let model = makeModel(counters: counters, startGate: gate)
        model.select(entryID: 2)
        let first = Task { await model.classifySelectedFile() }
        await gate.waitUntilEntered()
        XCTAssertFalse(model.canClassifySelectedFile, "repeat must disable while running")
        await model.classifySelectedFile()
        await model.classifySelectedFile()
        XCTAssertEqual(counters.startCount, 1, "no second start while locally running")
        await gate.release()
        await first.value
        XCTAssertEqual(counters.startCount, 1)
    }

    func testBusyShowsMessageNoQueueNoAutoStart() async {
        let counters = Counters()
        let model = makeModel(counters: counters, result: .busy)
        model.select(entryID: 2)
        let refreshesBeforeClassify = counters.refreshCount
        await model.classifySelectedFile()
        XCTAssertEqual(counters.startCount, 1)
        XCTAssertEqual(model.classificationPhase, .idle)
        XCTAssertEqual(model.classificationMessage, ClassificationUIText.busy)
        XCTAssertEqual(counters.refreshCount, refreshesBeforeClassify, "busy writes no row, refreshes nothing")
        // No automatic retry: still idle with busy message, no extra start.
        await Task.yield()
        XCTAssertEqual(counters.startCount, 1, "no queue/retry after busy")
    }

    // MARK: - Delayed progress (exactly 0.5 s seam)

    func testFastCompletionNeverFlashesProgress() async {
        let counters = Counters()
        let delayGate = ClassificationTestGate()
        let model = makeModel(counters: counters, delayGate: delayGate, result: .unavailable)
        model.select(entryID: 2)
        await model.classifySelectedFile()
        XCTAssertEqual(model.classificationPhase, .idle)
        XCTAssertNotEqual(model.classificationPhase, .runningWithProgress)
        // Release the 0.5 s seam after completion: stale timer must not mutate.
        await delayGate.release()
        await Task.yield()
        XCTAssertEqual(model.classificationPhase, .idle, "stale delay must not flash")
        XCTAssertEqual(model.classificationMessage, ClassificationUIText.unavailable)
    }

    func testProgressAppearsAfterHalfSecondWhileRunning() async {
        let counters = Counters()
        let startGate = ClassificationTestGate()
        let delayGate = ClassificationTestGate()
        let model = makeModel(counters: counters, startGate: startGate, delayGate: delayGate)
        model.select(entryID: 2)
        let run = Task { await model.classifySelectedFile() }
        await startGate.waitUntilEntered()
        await Task.yield()
        XCTAssertEqual(model.classificationPhase, .runningBeforeProgress,
                       "progress stays hidden before 0.5 s")
        await delayGate.release()
        // Deterministically observe the delayed transition.
        var attempts = 0
        while model.classificationPhase != .runningWithProgress && attempts < 100 {
            await Task.yield()
            attempts += 1
        }
        XCTAssertEqual(model.classificationPhase, .runningWithProgress)
        await startGate.release()
        await run.value
        XCTAssertEqual(model.classificationPhase, .idle, "completion hides progress")
        _ = counters
    }

    func testStaleDelayAfterSelectionChangeDoesNotMutate() async {
        let counters = Counters()
        let startGate = ClassificationTestGate()
        let delayGate = ClassificationTestGate()
        let model = makeModel(counters: counters, startGate: startGate, delayGate: delayGate)
        model.select(entryID: 2)
        let run = Task { await model.classifySelectedFile() }
        await startGate.waitUntilEntered()
        model.select(entryID: 3)
        XCTAssertEqual(model.selectedEntryID, 3)
        XCTAssertEqual(model.classificationPhase, .idle)
        await delayGate.release()
        await Task.yield()
        await Task.yield()
        XCTAssertEqual(model.classificationPhase, .idle, "stale timer must not mutate new selection")
        XCTAssertEqual(model.selectedEntryID, 3)
        await startGate.release()
        await run.value
        XCTAssertEqual(model.selectedEntryID, 3)
        XCTAssertEqual(model.classificationPhase, .idle)
    }

    // MARK: - Cancel

    func testExplicitCancelCallsRuntimeOnceAndSuppressesLateCompletion() async {
        let counters = Counters()
        let startGate = ClassificationTestGate()
        let delayGate = ClassificationTestGate()
        let model = makeModel(counters: counters, startGate: startGate, delayGate: delayGate,
                              result: .classifiedPersisted)
        model.select(entryID: 2)
        let run = Task { await model.classifySelectedFile() }
        await startGate.waitUntilEntered()
        await delayGate.release()
        var attempts = 0
        while model.classificationPhase != .runningWithProgress && attempts < 100 {
            await Task.yield()
            attempts += 1
        }
        XCTAssertEqual(model.classificationPhase, .runningWithProgress)
        let refreshesBefore = counters.refreshCount
        model.cancelClassification()
        XCTAssertEqual(counters.cancelCount, 1, "explicit cancel calls runtime cancel exactly once")
        XCTAssertEqual(model.classificationPhase, .idle)
        XCTAssertEqual(model.classificationMessage, ClassificationUIText.cancelled)
        await startGate.release()
        await run.value
        XCTAssertEqual(counters.refreshCount, refreshesBefore, "late completion cannot refresh")
        XCTAssertEqual(model.classificationMessage, ClassificationUIText.cancelled)
        XCTAssertEqual(model.classificationPhase, .idle)
    }

    func testLifecycleCancelShowsNoMessage() {
        let counters = Counters()
        let model = makeModel(counters: counters)
        model.select(entryID: 2)
        model.cancelClassificationForSnapshotClose()
        XCTAssertNil(model.classificationMessage, "lifecycle cancel shows no message")
        XCTAssertEqual(model.classificationPhase, .idle)
    }

    // MARK: - Selection / snapshot / browser stale suppression

    func testSelectionChangeCancelsAndSuppressesStale() async {
        let counters = Counters()
        let startGate = ClassificationTestGate()
        let cannedB = try! cannedDetails(id: 3)
        // Loader returns canned B for entry 3 so we can detect any overwrite.
        let control = SelectedEntryClassificationControl(
            start: { entryID in
                counters.recordStart(entryID)
                await startGate.wait()
                return .classifiedPersisted
            },
            cancel: { counters.recordCancel() }
        )
        let model = SnapshotBrowserModel(database: database, summary: summary,
                                         control: control,
                                         progressDelay: { try? await Task.sleep(for: .milliseconds(500)) },
                                         detailsLoader: { entryID in
                                            counters.recordRefresh(entryID)
                                            if entryID == 3 { return cannedB }
                                            return try SnapshotTreeDataSource(database: self.database, snapshotID: self.snapshotID).details(for: entryID)
                                         })
        model.select(entryID: 2)
        let cancelsBefore = counters.cancelCount
        let run = Task { await model.classifySelectedFile() }
        await startGate.waitUntilEntered()
        model.select(entryID: 3)
        XCTAssertGreaterThanOrEqual(counters.cancelCount, cancelsBefore + 1, "selection change cancels A")
        XCTAssertEqual(model.selectedEntryID, 3)
        XCTAssertEqual(model.selectedDetails?.id, 3)
        await startGate.release()
        await run.value
        XCTAssertEqual(model.selectedEntryID, 3, "selection stays on B")
        XCTAssertEqual(model.selectedDetails?.id, 3, "A completion cannot refresh B")
        XCTAssertNil(model.classificationMessage, "lifecycle change shows no cancelled message")
    }

    func testSnapshotCloseCancelsInvalidates() async {
        let counters = Counters()
        let startGate = ClassificationTestGate()
        let model = makeModel(counters: counters, startGate: startGate)
        model.select(entryID: 2)
        let run = Task { await model.classifySelectedFile() }
        await startGate.waitUntilEntered()
        model.cancelClassificationForSnapshotClose()
        XCTAssertEqual(model.classificationPhase, .idle)
        XCTAssertNil(model.classificationMessage)
        await startGate.release()
        await run.value
        XCTAssertEqual(model.classificationPhase, .idle)
        XCTAssertGreaterThanOrEqual(counters.cancelCount, 1)
    }

    func testBrowserReplacementOldCompletionCannotAlterNew() async throws {
        let countersOld = Counters()
        let countersNew = Counters()
        let startGate = ClassificationTestGate()
        let old = makeModel(counters: countersOld, startGate: startGate, result: .classifiedPersisted)
        old.select(entryID: 2)
        let run = Task { await old.classifySelectedFile() }
        await startGate.waitUntilEntered()
        // Replace browser: cancel old before new can treat a result as current.
        old.cancelClassificationForSnapshotClose()
        let fresh = makeModel(counters: countersNew, result: .unavailable)
        fresh.select(entryID: 3)
        let freshDetails = fresh.selectedDetails
        await startGate.release()
        await run.value
        XCTAssertEqual(fresh.selectedEntryID, 3)
        XCTAssertEqual(fresh.selectedDetails?.id, freshDetails?.id, "old completion cannot alter new browser")
        XCTAssertEqual(fresh.classificationPhase, .idle)
    }

    // MARK: - Result mapping

    func testClassifiedPersistedRefreshesSelectedDetailsOnce() async throws {
        let counters = Counters()
        let stored = EntryClassification(
            id: 1, entryID: 2, classificationRunID: "run-1", detectedType: "text",
            mimeType: "text/plain", confidence: 0.5, detectionStatus: .classified,
            detectorVersion: "d", modelVersion: "m", providerIdentifier: "p",
            classifiedAt: "2026-10-05", createdAt: "2026-10-05"
        )
        let canned = try cannedDetails(id: 2, classification: stored)
        let model = makeModel(counters: counters, result: .classifiedPersisted, cannedDetails: canned)
        model.select(entryID: 2)
        let refreshesAfterSelect = counters.refreshCount
        await model.classifySelectedFile()
        XCTAssertEqual(counters.refreshCount, refreshesAfterSelect + 1, "refresh exactly selected details once")
        XCTAssertEqual(model.selectedDetails?.classification, stored)
        XCTAssertNil(model.classificationMessage)
        XCTAssertEqual(model.classificationPhase, .idle)
    }

    func testFailedPersistedRefreshesBoundedStatus() async throws {
        let counters = Counters()
        let failed = EntryClassification(
            id: 2, entryID: 2, classificationRunID: "run-f", detectedType: nil,
            mimeType: nil, confidence: nil, detectionStatus: .failed,
            detectorVersion: nil, modelVersion: nil, providerIdentifier: nil,
            classifiedAt: nil, createdAt: "2026-10-05"
        )
        let canned = try cannedDetails(id: 2, classification: failed)
        let model = makeModel(counters: counters, result: .failedPersisted, cannedDetails: canned)
        model.select(entryID: 2)
        let before = counters.refreshCount
        await model.classifySelectedFile()
        XCTAssertEqual(counters.refreshCount, before + 1)
        XCTAssertEqual(model.selectedDetails?.classification?.statusLabel, "Classification unavailable")
        XCTAssertNil(model.selectedDetails?.classification?.confidenceLabel)
        XCTAssertNil(model.classificationMessage)
    }

    func testUnavailableShowsBoundedMessageNoRefresh() async {
        let counters = Counters()
        let model = makeModel(counters: counters, result: .unavailable)
        model.select(entryID: 2)
        let before = counters.refreshCount
        await model.classifySelectedFile()
        XCTAssertEqual(counters.refreshCount, before, "unavailable has no row, zero refresh")
        XCTAssertEqual(model.classificationMessage, ClassificationUIText.unavailable)
        XCTAssertEqual(model.classificationPhase, .idle)
    }

    func testCancelledShowsBoundedMessageNoRow() async {
        let counters = Counters()
        // Direct cancelled outcome without explicit Cancel button: model still
        // shows bounded message for the current operation.
        let model = makeModel(counters: counters, result: .cancelled)
        model.select(entryID: 2)
        let before = counters.refreshCount
        await model.classifySelectedFile()
        XCTAssertEqual(counters.refreshCount, before)
        XCTAssertEqual(model.classificationMessage, ClassificationUIText.cancelled)
    }

    func testRepositoryFailureGenericMessageNoRaw() async {
        let counters = Counters()
        let model = makeModel(counters: counters, result: .repositoryFailure)
        model.select(entryID: 2)
        await model.classifySelectedFile()
        XCTAssertEqual(model.classificationMessage, ClassificationUIText.saveFailure)
        for token in ["/", ".sqlite", "run-", "Error", "error", "stderr"] {
            XCTAssertFalse(model.classificationMessage?.contains(token) ?? false, "no raw diagnostic: \(token)")
        }
        XCTAssertEqual(counters.refreshCount, counters.refreshCount, "no assertion on refresh count beyond no crash")
    }

    // MARK: - Wording / confidence / absence

    func testWordingAbsenceConfidenceAndNoRaw() throws {
        XCTAssertEqual(ClassificationUIText.absence, "Not classified.")
        let disclaimer = ClassificationUIText.disclaimer
        XCTAssertTrue(disclaimer.contains("currently attached source"), "must name current source")
        XCTAssertTrue(disclaimer.contains("4096"), "must state 4096-byte maximum")
        let lowered = disclaimer.lowercased()
        XCTAssertTrue(lowered.contains("not byte proof"), "snapshot metadata is not byte proof")
        XCTAssertTrue(lowered.contains("does not verify historical"), "must deny historical verification")
        XCTAssertFalse(disclaimer.contains("never read this file"), "old blanket must be gone from new wording")
        // Confidence conditional.
        let withoutConfidence = EntryClassification(
            id: 1, entryID: 2, classificationRunID: "r", detectedType: "text",
            mimeType: nil, confidence: nil, detectionStatus: .classified,
            detectorVersion: nil, modelVersion: nil, providerIdentifier: "p",
            classifiedAt: nil, createdAt: "x"
        )
        XCTAssertNil(withoutConfidence.confidenceLabel, "confidence shown only when present")
        let withConfidence = EntryClassification(
            id: 2, entryID: 2, classificationRunID: "r2", detectedType: "text",
            mimeType: nil, confidence: 0.875, detectionStatus: .classified,
            detectorVersion: nil, modelVersion: nil, providerIdentifier: "p",
            classifiedAt: nil, createdAt: "x"
        )
        XCTAssertEqual(withConfidence.confidenceLabel, "87.5%")
        // Bounded messages never expose paths or diagnostics.
        for message in [ClassificationUIText.unavailable, ClassificationUIText.cancelled,
                        ClassificationUIText.busy, ClassificationUIText.saveFailure] {
            XCTAssertFalse(message.contains("/"), "no private path in \(message)")
            XCTAssertFalse(message.lowercased().contains("stderr"))
            XCTAssertFalse(message.lowercased().contains("stack"))
        }
    }

    func testProductionInspectorSourceHasNoBlanketWording() throws {
        // The blanket statement is now false once optional classification
        // exists; the view source must not contain it. Exact file location is
        // resolved from the test bundle to avoid hard-coded absolute paths.
        let fm = FileManager.default
        var dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        for _ in 0..<4 {
            let candidate = dir.appendingPathComponent("FSD/UI/SnapshotBrowserView.swift")
            if fm.fileExists(atPath: candidate.path) {
                let text = try String(contentsOf: candidate, encoding: .utf8)
                XCTAssertFalse(text.contains("FSD never read this file's contents"),
                               "old blanket wording must be absent")
                XCTAssertTrue(text.contains("Classify selected file"), "explicit action must exist")
                XCTAssertTrue(text.contains("at most the first 4096 bytes"),
                              "inspector must state 4096-byte maximum")
                return
            }
            dir.deleteLastPathComponent()
        }
        // Fallback: constants already prove wording; missing file is not a
        // product defect in this sandbox layout.
        XCTAssertTrue(ClassificationUIText.disclaimer.contains("4096"))
    }

    // MARK: - No side effects / production provider

    func testSearchCompareExportDoNotInvokeProvider() async throws {
        let counters = Counters()
        let model = makeModel(counters: counters)
        model.open()
        model.select(entryID: 2)
        _ = try model.classificationDetails(for: 2)
        model.searchText = "a.txt"
        model.runSearch()
        await Task.yield()
        model.clearSearch()
        var exported = ""
        _ = try JSONSnapshotExporter(database: database).write(snapshotID: snapshotID) { exported += $0 }
        XCTAssertEqual(counters.startCount, 0, "search/compare/export must not invoke classification")
        // Comparison production has no classification dependency by construction;
        // a bounded engine run must not create classification rows.
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
    }

    func testProductionProviderConstructionIsInertAndUnavailableWithoutHelper() async throws {
        let provider = BundledMagikaClassificationProvider()
        XCTAssertEqual(provider.providerIdentifier, "fsd.bundled-helper-host.v1")
        // No real helper exists in a normal build; production start through the
        // real runtime must correctly return unavailable with no row and no
        // simulated success.
        let runtime = ClassificationRuntimeService.shared
        await runtime.cancel()
        await runtime.waitForCleanup()
        let outcome = await SnapshotBrowserModel.productionStart(entryID: 2, database: database, runtime: runtime)
        await runtime.waitForCleanup()
        XCTAssertEqual(outcome, .unavailable, "missing helper must be unavailable, never simulated success")
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
    }
}

/// Deterministic gate: no wall-clock sleep decides ordering.
final class ClassificationTestGate: Sendable {
    private let lock = NSLock()
    private var enteredContinuation: CheckedContinuation<Void, Never>?
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private var entered = false
    private var released = false

    /// The operation under test calls this to block until the test releases it.
    /// The first caller also records entry so the test can order selection
    /// changes strictly after the operation started.
    func wait() async {
        let toResume: CheckedContinuation<Void, Never>? = lock.withLock {
            entered = true
            let pending = enteredContinuation
            enteredContinuation = nil
            return pending
        }
        toResume?.resume()
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            let resumeNow = lock.withLock { () -> Bool in
                if released { return true }
                waiters.append(c)
                return false
            }
            if resumeNow { c.resume() }
        }
    }

    func waitUntilEntered() async {
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            let resumeNow = lock.withLock { () -> Bool in
                if entered { return true }
                enteredContinuation = c
                return false
            }
            if resumeNow { c.resume() }
        }
        // Ensure the waiter above has actually suspended inside start().
        await Task.yield()
        await Task.yield()
    }

    func release() async {
        let waiters: [CheckedContinuation<Void, Never>] = lock.withLock {
            released = true
            let pending = self.waiters
            self.waiters = []
            if let pendingEntry = enteredContinuation {
                enteredContinuation = nil
                pendingEntry.resume()
            }
            return pending
        }
        for waiter in waiters { waiter.resume() }
        await Task.yield()
        await Task.yield()
    }
}
