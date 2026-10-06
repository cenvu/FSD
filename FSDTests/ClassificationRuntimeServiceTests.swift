import XCTest
@testable import FSD

private typealias Runtime = ClassificationRuntimeService

final class ClassificationRuntimeServiceTests: XCTestCase {
    private let runtime = Runtime.shared
    override func tearDown() async throws {
        await runtime.cancel()
        await runtime.waitForCleanup()
    }

    private static let observation = LocalClassificationObservation(
        detectedType: "text", mimeType: "text/plain", confidence: 0.75,
        detectorVersion: "observed-detector", modelVersion: "observed-model",
        classifiedAt: "2026-10-05T00:00:00Z"
    )

    func testSingleFlightBusyDoesNotQueueOrTouchDependencies() async throws {
        let entered = expectation(description: "first provider active")
        let gate = RuntimeTestGate(entered: entered)
        let firstProbe = RuntimeTestProbe()
        let first = Task { await runtime.start(entryID: 2, dependencies: dependencies(
            probe: firstProbe, provider: RuntimeTestProvider { _ in
                await gate.wait()
                return .classified(Self.observation)
            }
        )) }
        await fulfillment(of: [entered], timeout: 5)
        let secondProbe = RuntimeTestProbe()
        let second = await runtime.start(entryID: 3, dependencies: dependencies(
            probe: secondProbe, source: .unavailable
        ))
        // First provider stays blocked. Busy must return before its release;
        // admission owns the ordering, with no second run/row/current state.
        XCTAssertEqual(second, .busy)
        XCTAssertEqual(secondProbe.reads, 0)
        XCTAssertEqual(secondProbe.ids, 0)
        XCTAssertEqual(secondProbe.inputs.count, 0)
        await gate.release()
        _ = await first.value
        await runtime.waitForCleanup()
    }

    func testCancelledGenerationRejectsLateClassifiedAppendAndPublication() async throws {
        let entered = expectation(description: "old provider active")
        let gate = RuntimeTestGate(entered: entered)
        let probe = RuntimeTestProbe()
        let oldGeneration = await runtime.generation
        let run = Task { await runtime.start(entryID: 2, dependencies: dependencies(
            probe: probe, provider: RuntimeTestProvider { _ in
                await gate.wait() // Deliberately ignores cancellation until released.
                return .classified(Self.observation)
            }
        )) }
        await fulfillment(of: [entered], timeout: 5)
        await runtime.cancel()
        let cancelledGeneration = await runtime.generation
        XCTAssertGreaterThan(cancelledGeneration, oldGeneration)
        await gate.release()
        // Cancellation is deliberately first. Late success owns neither a row
        // nor current terminal success, even after provider cleanup returns.
        let result = await run.value
        await runtime.waitForCleanup()
        XCTAssertEqual(classification(result), .cancelled)
        XCTAssertEqual(probe.inputs.count, 0)
        let state = await runtime.state
        XCTAssertEqual(state, .idle)
    }

    func testReaderFailureAppendsOneFailedRowWithoutProviderProvenance() async throws {
        let probe = RuntimeTestProbe()
        let result = await runtime.start(entryID: 2, dependencies: dependencies(
            probe: probe, source: .failed
        ))
        XCTAssertEqual(classification(result), .failed)
        XCTAssertEqual(probe.inputs.count, 1)
        XCTAssertEqual(probe.inputs.first?.detectionStatus, .failed)
        XCTAssertNil(probe.inputs.first?.providerIdentifier)
        XCTAssertNil(probe.inputs.first?.detectorVersion)
        XCTAssertNil(probe.inputs.first?.modelVersion)
        XCTAssertEqual(probe.ids, 1)
    }

    func testConstructionAndStateObservationAreInert() async {
        await runtime.waitForCleanup()
        let sameService = Runtime.shared
        XCTAssertTrue(runtime === sameService, "all callers share the sole service")
        let probe = RuntimeTestProbe()
        _ = dependencies(probe: probe)
        XCTAssertEqual(probe.reads, 0)
        XCTAssertEqual(probe.ids, 0)
        XCTAssertEqual(probe.inferences, 0)
        XCTAssertEqual(probe.inputs.count, 0)
    }

    func testAllSevenOutcomesAndExactObservationProvenance() async throws {
        let cases: [(BoundedClassificationSourceOutcome?, LocalClassificationProviderResult,
                     LocalClassificationProviderResult, Bool, String?)] = [
            (nil, .classified(Self.observation), .classified(Self.observation), true, "actual-provider"),
            (.failed, .classified(Self.observation), .failed, true, nil),
            (nil, .failed, .failed, true, "actual-provider"),
            (.sourceChanged, .classified(Self.observation), .sourceChanged, true, nil),
            (.unsupportedEntry, .classified(Self.observation), .unsupportedEntry, true, nil),
            (.unavailable, .classified(Self.observation), .unavailable, false, nil),
            (nil, .unavailable, .unavailable, false, nil),
            (.cancelled, .classified(Self.observation), .cancelled, false, nil),
            (nil, .cancelled, .cancelled, false, nil),
            (nil, .noMatch, .noMatch, false, nil)
        ]
        for (source, provided, expected, writes, identifier) in cases {
            let probe = RuntimeTestProbe()
            let result = await runtime.start(entryID: 2, dependencies: dependencies(
                probe: probe, source: source, provider: RuntimeTestProvider { _ in provided }
            ))
            await runtime.waitForCleanup()
            XCTAssertEqual(classification(result), expected)
            XCTAssertEqual(probe.inputs.count, writes ? 1 : 0)
            XCTAssertEqual(probe.ids, 1)
            XCTAssertEqual(probe.inferences, source == nil ? 1 : 0)
            if let input = probe.inputs.first {
                XCTAssertEqual(input.providerIdentifier, identifier)
                if case let .classified(observation) = expected {
                    XCTAssertEqual(input.detectionStatus, .classified)
                    XCTAssertEqual(input.detectedType, observation.detectedType)
                    XCTAssertEqual(input.mimeType, observation.mimeType)
                    XCTAssertEqual(input.confidence, observation.confidence)
                    XCTAssertEqual(input.detectorVersion, observation.detectorVersion)
                    XCTAssertEqual(input.modelVersion, observation.modelVersion)
                    XCTAssertEqual(input.classifiedAt, observation.classifiedAt)
                } else {
                    assertFailedMetadata(input)
                }
            }
        }
    }

    func testNoMatchAndZeroBytePrefixRunProviderWithoutAppendOrPersistedMetadata() async throws {
        let (directory, database) = try noMatchDatabase()
        defer { database.close(); try? FileManager.default.removeItem(at: directory) }
        let repository = EntryClassificationRepository(database: database)
        for bytes in [Data([0, 255, 10]), Data()] {
            let probe = RuntimeTestProbe()
            let rowsBefore = try EntrySnapshotProbe.classificationRowCount(database: database)
            var deps = dependencies(
                probe: probe, source: .prefix(LocalClassificationRequest(boundedPrefix: bytes)!),
                provider: RuntimeTestProvider { request in
                    XCTAssertEqual(request.data, bytes)
                    XCTAssertEqual(request.data.count, bytes.count)
                    return .noMatch
                }, deadline: RuntimeTestDeadline()
            )
            deps.append = { input in
                _ = probe.append(input) // Existing append probe counts every call.
                return try repository.append(input)
            }
            let result = await runtime.start(entryID: 2, dependencies: deps)
            await runtime.waitForCleanup()
            guard case let .completed(completion) = result else { return XCTFail("not completed") }
            XCTAssertEqual(completion.result, .classification(.noMatch, nil))
            XCTAssertEqual(probe.inferences, 1, "provider ran exactly once, including empty Data")
            XCTAssertEqual(probe.inputs.count, 0, "append call count is zero")
            XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database) - rowsBefore, 0)
            XCTAssertTrue(try repository.history(for: 2).isEmpty, "no type, MIME, confidence or provider/detector/model provenance persisted")
            let state = await runtime.state
            XCTAssertEqual(state, .terminal(completion))
        }
    }

    func testInvalidatedGenerationRejectsLateNoMatchAppendAndPublication() async throws {
        let (directory, database) = try noMatchDatabase()
        defer { database.close(); try? FileManager.default.removeItem(at: directory) }
        let repository = EntryClassificationRepository(database: database)
        let entered = expectation(description: "noMatch provider active")
        let gate = RuntimeTestGate(entered: entered)
        let probe = RuntimeTestProbe()
        var deps = dependencies(probe: probe, provider: RuntimeTestProvider { _ in
            await gate.wait() // Noncooperative provider deliberately returns noMatch later.
            XCTAssertTrue(Task.isCancelled)
            return .noMatch
        }, deadline: RuntimeTestDeadline())
        deps.append = { input in
            _ = probe.append(input)
            return try repository.append(input)
        }
        let fixed = deps
        let run = Task { await runtime.start(entryID: 2, dependencies: fixed) }
        await fulfillment(of: [entered], timeout: 5)
        let prior = await runtime.generation
        await runtime.invalidate()
        let generation = await runtime.generation
        XCTAssertGreaterThan(generation, prior)
        let result = await run.value // Cancellation publishes before the provider returns.
        guard case let .completed(completion) = result else { return XCTFail("not completed") }
        XCTAssertEqual(completion.result, .classification(.cancelled, nil))
        await gate.release()
        await runtime.waitForCleanup()
        XCTAssertEqual(probe.inferences, 1)
        XCTAssertEqual(probe.inputs.count, 0)
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
        let state = await runtime.state
        XCTAssertEqual(state, .idle, "late noMatch must never publish as current")
    }

    func testCallerCancellationBeforeNoMatchCompletionWins() async {
        let entered = expectation(description: "noMatch before completion authorization")
        let gate = RuntimeTestGate(entered: entered)
        let probe = RuntimeTestProbe()
        let run = Task { await runtime.start(entryID: 2, dependencies: dependencies(
            probe: probe, provider: RuntimeTestProvider { _ in .noMatch },
            deadline: RuntimeTestDeadline(),
            checkpoint: { if $0 == .beforePersistence { await gate.wait() } }
        )) }
        await fulfillment(of: [entered], timeout: 5)
        run.cancel()
        await gate.release()
        let result = await run.value
        await runtime.waitForCleanup()
        guard case let .completed(completion) = result else { return XCTFail("not completed") }
        XCTAssertEqual(completion.result, .classification(.cancelled, nil))
        XCTAssertEqual(probe.inferences, 1)
        XCTAssertEqual(probe.inputs.count, 0)
        let state = await runtime.state
        XCTAssertEqual(state, .idle)
    }

    func testTimeoutRemainsFailedWhenLateProviderReturnsNoMatch() async {
        let entered = expectation(description: "provider before timeout")
        let gate = RuntimeTestGate(entered: entered)
        let clock = RuntimeTestDeadline()
        let probe = RuntimeTestProbe()
        let run = Task { await runtime.start(entryID: 2, dependencies: dependencies(
            probe: probe, provider: RuntimeTestProvider { _ in
                await gate.wait()
                return .noMatch
            }, deadline: clock
        )) }
        await fulfillment(of: [entered], timeout: 5)
        clock.fire()
        let result = await run.value
        XCTAssertEqual(classification(result), .failed)
        XCTAssertEqual(probe.inputs.count, 1)
        assertFailedMetadata(probe.inputs.first)
        XCTAssertEqual(probe.inputs.first?.providerIdentifier, "actual-provider")
        let timedOut = await runtime.state
        await gate.release()
        await runtime.waitForCleanup()
        let state = await runtime.state
        XCTAssertEqual(state, timedOut, "late noMatch cannot replace the timeout")
        XCTAssertEqual(probe.inputs.count, 1)
    }

    func testCancellationBeforeSourceResolutionDoesNotCallReader() async {
        let entered = expectation(description: "before source resolution")
        let gate = RuntimeTestGate(entered: entered)
        let probe = RuntimeTestProbe()
        let run = Task { await runtime.start(entryID: 2, dependencies: dependencies(
            probe: probe, checkpoint: { stage in
                if stage == .beforeSource { await gate.wait() }
            }
        )) }
        await fulfillment(of: [entered], timeout: 5)
        await runtime.cancel() // Cancel owns generation before source begins.
        await gate.release()
        let result = await run.value
        await runtime.waitForCleanup()
        XCTAssertEqual(classification(result), .cancelled)
        XCTAssertEqual(probe.reads, 0)
        XCTAssertEqual(probe.inferences, 0)
        XCTAssertTrue(probe.inputs.isEmpty)
        let state = await runtime.state
        XCTAssertEqual(state, .idle)
    }

    func testAlreadyCancelledCallerDoesNotResolveSource() async {
        let entered = expectation(description: "caller before start")
        let gate = RuntimeTestGate(entered: entered)
        let probe = RuntimeTestProbe()
        let run = Task {
            await gate.wait()
            return await runtime.start(entryID: 2, dependencies: dependencies(probe: probe))
        }
        await fulfillment(of: [entered], timeout: 5)
        run.cancel()
        await gate.release()
        let result = await run.value
        await runtime.waitForCleanup()
        XCTAssertEqual(classification(result), .cancelled)
        XCTAssertEqual(probe.reads, 0)
        XCTAssertEqual(probe.inferences, 0)
        XCTAssertTrue(probe.inputs.isEmpty)
    }

    func testCancellationDuringReaderPropagatesTaskCancellationAndHoldsSlot() async {
        let entered = expectation(description: "reader active")
        let gate = RuntimeTestGate(entered: entered)
        let probe = RuntimeTestProbe()
        var deps = dependencies(probe: probe)
        deps.readPrefix = { _ in
            probe.didRead()
            await gate.wait()
            XCTAssertTrue(Task.isCancelled, "reader uses existing Task cancellation")
            return .cancelled
        }
        let readerDeps = deps
        let run = Task { await runtime.start(entryID: 2, dependencies: readerDeps) }
        await fulfillment(of: [entered], timeout: 5)
        let previous = await runtime.generation
        await runtime.invalidate() // Invalidation first; reader unwinds later.
        let current = await runtime.generation
        XCTAssertGreaterThan(current, previous)
        let result = await run.value
        XCTAssertEqual(classification(result), .cancelled)
        let blocked = await runtime.start(entryID: 3, dependencies: dependencies(probe: RuntimeTestProbe()))
        XCTAssertEqual(blocked, .busy)
        await gate.release()
        await runtime.waitForCleanup()
        XCTAssertEqual(probe.inferences, 0)
        XCTAssertTrue(probe.inputs.isEmpty)
    }

    func testCancellationAfterReadAndBeforeInference() async {
        for boundary in [Runtime.Checkpoint.afterRead, .beforeInference] {
            let entered = expectation(description: "\(boundary)")
            let gate = RuntimeTestGate(entered: entered)
            let probe = RuntimeTestProbe()
            let run = Task { await runtime.start(entryID: 2, dependencies: dependencies(
                probe: probe, checkpoint: { stage in
                    if stage == boundary { await gate.wait() }
                }
            )) }
            await fulfillment(of: [entered], timeout: 5)
            await runtime.cancel() // Cancel before inference admission; zero rows.
            await gate.release()
            let result = await run.value
            await runtime.waitForCleanup()
            XCTAssertEqual(classification(result), .cancelled)
            XCTAssertEqual(probe.reads, 1)
            XCTAssertEqual(probe.inferences, 0)
            XCTAssertTrue(probe.inputs.isEmpty)
        }
    }

    func testCancellationAfterInferenceAndImmediatelyBeforeAppend() async {
        for boundary in [Runtime.Checkpoint.afterInference, .beforePersistence] {
            let entered = expectation(description: "\(boundary)")
            let gate = RuntimeTestGate(entered: entered)
            let probe = RuntimeTestProbe()
            let run = Task { await runtime.start(entryID: 2, dependencies: dependencies(
                probe: probe, provider: RuntimeTestProvider { _ in .classified(Self.observation) },
                checkpoint: { stage in if stage == boundary { await gate.wait() } }
            )) }
            await fulfillment(of: [entered], timeout: 5)
            await runtime.cancel() // Cancel first, before atomic append authority.
            await gate.release()
            let result = await run.value
            await runtime.waitForCleanup()
            XCTAssertEqual(classification(result), .cancelled)
            XCTAssertEqual(probe.inferences, 1)
            XCTAssertTrue(probe.inputs.isEmpty)
            let state = await runtime.state
            XCTAssertEqual(state, .idle)
        }
    }

    func testCallerTaskCancellationImmediatelyBeforePersistenceCannotAppend() async {
        let entered = expectation(description: "before atomic persistence")
        let gate = RuntimeTestGate(entered: entered)
        let probe = RuntimeTestProbe()
        let run = Task { await runtime.start(entryID: 2, dependencies: dependencies(
            probe: probe, provider: RuntimeTestProvider { _ in .classified(Self.observation) },
            checkpoint: { if $0 == .beforePersistence { await gate.wait() } }
        )) }
        await fulfillment(of: [entered], timeout: 5)
        run.cancel() // Synchronous cancellation token must win before gate opens.
        await gate.release()
        let result = await run.value
        await runtime.waitForCleanup()
        XCTAssertEqual(classification(result), .cancelled)
        XCTAssertTrue(probe.inputs.isEmpty)
    }

    func testCancelledGenerationRejectsLateFailureAndRetainsBusyUntilCleanup() async {
        let entered = expectation(description: "late failing provider")
        let gate = RuntimeTestGate(entered: entered)
        let probe = RuntimeTestProbe()
        let run = Task { await runtime.start(entryID: 2, dependencies: dependencies(
            probe: probe, provider: RuntimeTestProvider { _ in
                await gate.wait()
                XCTAssertTrue(Task.isCancelled)
                return .failed
            }
        )) }
        await fulfillment(of: [entered], timeout: 5)
        await runtime.cancel() // Cancel first; late failure is stale and rowless.
        let result = await run.value
        XCTAssertEqual(classification(result), .cancelled)
        let secondProbe = RuntimeTestProbe()
        let blocked = await runtime.start(entryID: 3, dependencies: dependencies(probe: secondProbe))
        XCTAssertEqual(blocked, .busy)
        XCTAssertEqual(secondProbe.reads, 0)
        await gate.release()
        await runtime.waitForCleanup()
        XCTAssertTrue(probe.inputs.isEmpty)
        let next = await runtime.start(entryID: 3, dependencies: dependencies(probe: secondProbe, source: .unavailable))
        await runtime.waitForCleanup()
        XCTAssertEqual(classification(next), .unavailable)
        XCTAssertEqual(secondProbe.reads, 1, "new explicit start, no queued busy work")
    }

    func testCompletionFirstStaysStableAfterCancelAndInvalidate() async {
        let probe = RuntimeTestProbe()
        let result = await runtime.start(entryID: 2, dependencies: dependencies(
            probe: probe, provider: RuntimeTestProvider { _ in .classified(Self.observation) }
        ))
        await runtime.waitForCleanup()
        let state = await runtime.state
        let previous = await runtime.generation
        await runtime.cancel()
        await runtime.invalidate()
        // Completion and append authority won first: one row and stable history.
        let after = await runtime.state
        let generation = await runtime.generation
        XCTAssertEqual(after, state)
        XCTAssertGreaterThan(generation, previous)
        XCTAssertEqual(classification(result), .classified(Self.observation))
        XCTAssertEqual(probe.inputs.count, 1)
    }

    func testTimeoutReturnsWhileLateProviderStillOwnsSlotAndCannotPublishSuccess() async {
        let entered = expectation(description: "inference active")
        let completed = expectation(description: "timeout returned before provider released")
        let gate = RuntimeTestGate(entered: entered)
        let clock = RuntimeTestDeadline()
        let probe = RuntimeTestProbe()
        let run = Task {
            let result = await runtime.start(entryID: 2, dependencies: dependencies(
                probe: probe, provider: RuntimeTestProvider { _ in
                    await gate.wait() // Noncooperative loser returns success only later.
                    XCTAssertTrue(Task.isCancelled)
                    return .classified(Self.observation)
                }, deadline: clock
            ))
            completed.fulfill()
            return result
        }
        await fulfillment(of: [entered], timeout: 5)
        clock.fire() // Deadline first; late provider is still blocked.
        await fulfillment(of: [completed], timeout: 5)
        XCTAssertEqual(clock.interval, .seconds(5))
        XCTAssertEqual(Runtime.inferenceTimeout, .seconds(5))
        XCTAssertEqual(probe.inputs.count, 1)
        assertFailedMetadata(probe.inputs.first)
        XCTAssertEqual(probe.inputs.first?.providerIdentifier, "actual-provider")
        let timeoutState = await runtime.state
        let secondProbe = RuntimeTestProbe()
        let blocked = await runtime.start(entryID: 3, dependencies: dependencies(probe: secondProbe))
        XCTAssertEqual(blocked, .busy)
        XCTAssertEqual(secondProbe.ids, 0)
        XCTAssertEqual(secondProbe.reads, 0)
        await gate.release()
        let result = await run.value
        await runtime.waitForCleanup()
        let after = await runtime.state
        XCTAssertEqual(classification(result), .failed)
        XCTAssertEqual(after, timeoutState)
        XCTAssertEqual(probe.inputs.count, 1)
    }

    func testDeadlineStartsOnlyAfterReaderAndExactlyAtInferenceHandoff() async {
        let readEntered = expectation(description: "reader phase")
        let inferenceEntered = expectation(description: "inference phase")
        let readGate = RuntimeTestGate(entered: readEntered)
        let inferenceGate = RuntimeTestGate(entered: inferenceEntered)
        let clock = RuntimeTestDeadline()
        let probe = RuntimeTestProbe()
        var deps = dependencies(probe: probe, provider: RuntimeTestProvider { _ in
            await inferenceGate.wait()
            return .failed
        }, deadline: clock)
        deps.readPrefix = { _ in
            probe.didRead()
            await readGate.wait()
            return .prefix(LocalClassificationRequest(boundedPrefix: Data())!)
        }
        let sourceDeps = deps
        let run = Task { await runtime.start(entryID: 2, dependencies: sourceDeps) }
        await fulfillment(of: [readEntered], timeout: 5)
        XCTAssertNil(clock.interval, "source read cannot start deadline")
        await readGate.release()
        await fulfillment(of: [inferenceEntered], timeout: 5)
        clock.fire()
        await inferenceGate.release()
        _ = await run.value
        await runtime.waitForCleanup()
        XCTAssertEqual(clock.interval, .seconds(5))
    }

    func testTimeoutThenUserCancelBeforeAppendWritesNoRow() async {
        let inferenceEntered = expectation(description: "provider active")
        let persistenceEntered = expectation(description: "timeout result before append")
        let providerGate = RuntimeTestGate(entered: inferenceEntered)
        let persistenceGate = RuntimeTestGate(entered: persistenceEntered)
        let clock = RuntimeTestDeadline()
        let probe = RuntimeTestProbe()
        let run = Task { await runtime.start(entryID: 2, dependencies: dependencies(
            probe: probe, provider: RuntimeTestProvider { _ in
                await providerGate.wait(); return .classified(Self.observation)
            }, deadline: clock, checkpoint: { stage in
                if stage == .beforePersistence { await persistenceGate.wait() }
            }
        )) }
        await fulfillment(of: [inferenceEntered], timeout: 5)
        clock.fire()
        await fulfillment(of: [persistenceEntered], timeout: 5)
        await runtime.cancel() // Timeout first; user cancellation before append wins.
        await persistenceGate.release()
        await providerGate.release()
        let result = await run.value
        await runtime.waitForCleanup()
        XCTAssertEqual(classification(result), .cancelled)
        XCTAssertTrue(probe.inputs.isEmpty)
        let state = await runtime.state
        XCTAssertEqual(state, .idle)
    }

    func testUserCancelBeforeDeadlineWinsNoFailedRow() async {
        let entered = expectation(description: "provider active")
        let gate = RuntimeTestGate(entered: entered)
        let clock = RuntimeTestDeadline()
        let probe = RuntimeTestProbe()
        let run = Task { await runtime.start(entryID: 2, dependencies: dependencies(
            probe: probe, provider: RuntimeTestProvider { _ in await gate.wait(); return .failed }, deadline: clock
        )) }
        await fulfillment(of: [entered], timeout: 5)
        await runtime.cancel() // User first; any subsequent deadline is stale.
        clock.fire()
        await gate.release()
        let result = await run.value
        await runtime.waitForCleanup()
        XCTAssertEqual(classification(result), .cancelled)
        XCTAssertTrue(probe.inputs.isEmpty)
    }

    func testProviderCompletionBeforeDeadlineWinsExactlyOneClassifiedRow() async {
        let probe = RuntimeTestProbe()
        let clock = RuntimeTestDeadline()
        let result = await runtime.start(entryID: 2, dependencies: dependencies(
            probe: probe, provider: RuntimeTestProvider { _ in .classified(Self.observation) }, deadline: clock
        ))
        await runtime.waitForCleanup()
        clock.fire() // Completion is already committed; deadline cannot replace it.
        XCTAssertEqual(classification(result), .classified(Self.observation))
        XCTAssertEqual(probe.inputs.count, 1)
        XCTAssertEqual(probe.inputs.first?.detectionStatus, .classified)
    }

    func testBundledProviderTimeoutCancelsTerminatesClosesReapsBeforeSlotRelease() async {
        let active = expectation(description: "fake child polling")
        let reaping = expectation(description: "owned fake child reaping")
        let reapRelease = DispatchSemaphore(value: 0)
        let runner = RuntimeTestHelperRunner(active: active, reaping: reaping, release: reapRelease)
        let provider = BundledFiletypeClassificationProvider(
            bundleRoot: URL(fileURLWithPath: "/Applications/FSD.app"), makeRunner: { runner },
            canonicalize: { $0 }, isExecutable: { _ in true }
        )
        let clock = RuntimeTestDeadline()
        let probe = RuntimeTestProbe()
        let run = Task { await runtime.start(entryID: 2, dependencies: dependencies(
            probe: probe, provider: provider, deadline: clock
        )) }
        await fulfillment(of: [active], timeout: 5)
        clock.fire() // Deadline first; child cleanup is held at reap boundary.
        await fulfillment(of: [reaping], timeout: 5)
        let result = await run.value
        let blocked = await runtime.start(entryID: 3, dependencies: dependencies(probe: RuntimeTestProbe()))
        XCTAssertEqual(blocked, .busy)
        reapRelease.signal()
        await runtime.waitForCleanup()
        XCTAssertEqual(classification(result), .failed)
        XCTAssertEqual(probe.inputs.count, 1)
        XCTAssertEqual(probe.inputs.first?.providerIdentifier, provider.providerIdentifier)
        XCTAssertEqual(runner.cleanupEvents, ["terminate", "closePipes", "reap"])
    }

    func testRealRepositoryDuplicateRunRemainsTypedNoRetryAndFactsImmutable() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Runtime-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let database = try CatalogDatabase(url: directory.appendingPathComponent("catalog.sqlite3"),
                                           schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        defer { database.close(); try? FileManager.default.removeItem(at: directory) }
        let snapshot = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 1, session: 1)
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: snapshot, entries: [
            SyntheticSnapshot.root(id: 1), SyntheticSnapshot.SeedEntry(
                id: 2, parentID: 1, relativePath: "fixture.txt", name: "fixture.txt"
            )
        ])
        try SyntheticSnapshot.complete(database: database, snapshotID: snapshot)
        let entries = try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: snapshot)
        let snapshotFacts = try EntrySnapshotProbe.snapshotFingerprint(database: database, snapshotID: snapshot)
        let repository = EntryClassificationRepository(database: database)
        let probe = RuntimeTestProbe()
        var deps = dependencies(probe: probe, provider: RuntimeTestProvider { request in
            XCTAssertEqual(request.data, Data([0, 255, 10]))
            XCTAssertEqual(Mirror(reflecting: request).children.map(\.label), ["data"])
            return .classified(Self.observation)
        })
        deps.makeRunID = { _ = probe.makeID(); return "duplicate-fixed-id" }
        deps.append = { try repository.append($0) }
        let fixed = deps
        let first = await runtime.start(entryID: 2, dependencies: fixed)
        await runtime.waitForCleanup()
        let duplicate = await runtime.start(entryID: 2, dependencies: fixed)
        await runtime.waitForCleanup()
        XCTAssertEqual(classification(first), .classified(Self.observation))
        guard case let .completed(completion) = duplicate else { return XCTFail("not completed") }
        XCTAssertEqual(completion.result, .repositoryFailure(.duplicateRun(entryID: 2, runID: "duplicate-fixed-id")))
        XCTAssertEqual(probe.ids, 2, "exactly one mint per admitted run, no replacement ID")
        XCTAssertEqual(try repository.history(for: 2).count, 1)
        XCTAssertEqual(try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: snapshot), entries)
        XCTAssertEqual(try EntrySnapshotProbe.snapshotFingerprint(database: database, snapshotID: snapshot), snapshotFacts)
        // A real failed classification row also preserves both immutable facts.
        var failed = dependencies(probe: RuntimeTestProbe(), source: .sourceChanged)
        failed.makeRunID = { "failed-facts" }
        failed.append = { try repository.append($0) }
        _ = await runtime.start(entryID: 2, dependencies: failed)
        await runtime.waitForCleanup()
        XCTAssertEqual(try repository.history(for: 2).count, 2)
        XCTAssertEqual(try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: snapshot), entries)
        XCTAssertEqual(try EntrySnapshotProbe.snapshotFingerprint(database: database, snapshotID: snapshot), snapshotFacts)
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
    }

    func testRepositoryFailureIsSanitizedAndNeverAppendedTwice() async {
        let probe = RuntimeTestProbe()
        var deps = dependencies(probe: probe, provider: RuntimeTestProvider { _ in .failed })
        deps.append = { input in
            _ = probe.append(input)
            throw EntryClassificationRepositoryError.invalidInput("raw diagnostic must not escape")
        }
        let result = await runtime.start(entryID: 2, dependencies: deps)
        await runtime.waitForCleanup()
        guard case let .completed(completion) = result else { return XCTFail("not completed") }
        XCTAssertEqual(completion.result, .repositoryFailure(.invalidInput))
        XCTAssertEqual(probe.ids, 1)
        XCTAssertEqual(probe.inputs.count, 1)
        XCTAssertFalse(String(describing: completion).contains("raw diagnostic"))
    }

    func testRuntimeStateAndCompletionContainNoPayloadOrSourceCapability() async {
        let probe = RuntimeTestProbe()
        let result = await runtime.start(entryID: 2, dependencies: dependencies(
            probe: probe, provider: RuntimeTestProvider { _ in .classified(Self.observation) }
        ))
        await runtime.waitForCleanup()
        func inspect(_ value: Any) {
            XCTAssertFalse(value is Data || value is LocalClassificationRequest || value is URL)
            for child in Mirror(reflecting: value).children { inspect(child.value) }
        }
        let state = await runtime.state
        inspect(state)
        inspect(result)
        inspect(probe.inputs)
    }

    func testProductionCompositionChecksEntryAndUsesAuditedReaderWithoutProviderRun() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Runtime-Context-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let database = try CatalogDatabase(url: directory.appendingPathComponent("catalog.sqlite3"),
                                           schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        defer { database.close(); try? FileManager.default.removeItem(at: directory) }
        let snapshot = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 1, session: 1)
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: snapshot, entries: [
            SyntheticSnapshot.root(id: 1), SyntheticSnapshot.SeedEntry(
                id: 2, parentID: 1, relativePath: "fixture.txt", name: "fixture.txt"
            )
        ])
        try SyntheticSnapshot.complete(database: database, snapshotID: snapshot)
        let probe = RuntimeTestProbe()
        let provider = RuntimeTestProvider { _ in probe.didInfer(); return .failed }
        let missing = await runtime.start(entryID: 999, database: database, provider: provider)
        await runtime.waitForCleanup()
        guard case let .completed(missingCompletion) = missing else { return XCTFail("not completed") }
        XCTAssertEqual(missingCompletion.result, .repositoryFailure(.entryNotFound(999)))
        // The synthetic snapshot lacks a trustworthy source locator. The real
        // reader must fail closed before any source content/provider capability.
        let unavailable = await runtime.start(entryID: 2, database: database, provider: provider)
        await runtime.waitForCleanup()
        guard case let .completed(unavailableCompletion) = unavailable else { return XCTFail("not completed") }
        XCTAssertEqual(classification(unavailable), .unavailable)
        XCTAssertNotEqual(missingCompletion.identity.runID, unavailableCompletion.identity.runID)
        XCTAssertGreaterThan(unavailableCompletion.identity.generation, missingCompletion.identity.generation)
        XCTAssertEqual(probe.inferences, 0)
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
    }

    func testContextStorageErrorIsTypedAndStopsBeforeReader() async {
        let probe = RuntimeTestProbe()
        var deps = dependencies(probe: probe)
        deps.context = { _ in throw EntryClassificationRepositoryError.database(.schemaStateInvalid("raw context diagnostic")) }
        let result = await runtime.start(entryID: 2, dependencies: deps)
        await runtime.waitForCleanup()
        guard case let .completed(completion) = result else { return XCTFail("not completed") }
        XCTAssertEqual(completion.result, .repositoryFailure(.storage))
        XCTAssertEqual(probe.reads, 0)
        XCTAssertEqual(probe.inferences, 0)
        XCTAssertTrue(probe.inputs.isEmpty)
        XCTAssertFalse(String(describing: completion).contains("raw context diagnostic"))
    }

    func testInvalidInjectedRunIDIsRejectedWithoutUnboundedStateOrReplacement() async {
        let probe = RuntimeTestProbe()
        var deps = dependencies(probe: probe)
        deps.makeRunID = { _ = probe.makeID(); return String(repeating: "x", count: 257) }
        let previous = await runtime.state
        let result = await runtime.start(entryID: 2, dependencies: deps)
        XCTAssertEqual(result, .rejected(.invalidInput))
        XCTAssertEqual(probe.ids, 1)
        XCTAssertEqual(probe.reads, 0)
        XCTAssertTrue(probe.inputs.isEmpty)
        let after = await runtime.state
        XCTAssertEqual(after, previous)
    }

    func testCommitAuthorizationDoesNotHoldCancellationLockAcrossAppend() async {
        let entered = expectation(description: "before commit authorization")
        let gate = RuntimeTestGate(entered: entered)
        let caller = RuntimeTestCaller()
        let probe = RuntimeTestProbe()
        var deps = dependencies(probe: probe, provider: RuntimeTestProvider { _ in .classified(Self.observation) },
                                checkpoint: { if $0 == .beforePersistence { await gate.wait() } })
        deps.append = { input in
            // Commit authorization has won. Cancel later, during the synchronous
            // append. The handler must return before append can finish, without
            // holding a cancellation lock across database work. One row/current
            // classified completion owns this ordering; no rollback or rewrite.
            let cancellationReturned = DispatchSemaphore(value: 0)
            DispatchQueue.global().async {
                caller.cancel()
                cancellationReturned.signal()
            }
            XCTAssertEqual(cancellationReturned.wait(timeout: .now() + 5), .success,
                           "caller cancellation must not block on repository append")
            return probe.append(input)
        }
        let commitDeps = deps
        let run = Task { await runtime.start(entryID: 2, dependencies: commitDeps) }
        caller.set(run)
        await fulfillment(of: [entered], timeout: 5)
        await gate.release() // Authorization first, cancellation deliberately later.
        let result = await run.value
        await runtime.waitForCleanup()
        XCTAssertEqual(classification(result), .classified(Self.observation))
        XCTAssertEqual(probe.inputs.count, 1)
        let state = await runtime.state
        guard case let .completed(completion) = result else { return XCTFail("not completed") }
        XCTAssertEqual(state, .terminal(completion))
    }

    private func noMatchDatabase() throws -> (URL, CatalogDatabase) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Runtime-NoMatch-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let database = try CatalogDatabase(url: directory.appendingPathComponent("catalog.sqlite3"),
                                           schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        let snapshot = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 1, session: 1)
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: snapshot, entries: [
            SyntheticSnapshot.root(id: 1),
            SyntheticSnapshot.SeedEntry(id: 2, parentID: 1, relativePath: "fixture.txt", name: "fixture.txt")
        ])
        try SyntheticSnapshot.complete(database: database, snapshotID: snapshot)
        return (directory, database)
    }

    private func assertFailedMetadata(_ input: EntryClassificationInput?, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(input?.detectionStatus, .failed, file: file, line: line)
        XCTAssertNil(input?.detectedType, file: file, line: line)
        XCTAssertNil(input?.mimeType, file: file, line: line)
        XCTAssertNil(input?.confidence, file: file, line: line)
        XCTAssertNil(input?.detectorVersion, file: file, line: line)
        XCTAssertNil(input?.modelVersion, file: file, line: line)
        XCTAssertNil(input?.classifiedAt, file: file, line: line)
    }

    private func dependencies(probe: RuntimeTestProbe,
                              source: BoundedClassificationSourceOutcome? = nil,
                              provider: any LocalFileClassificationProvider = RuntimeTestProvider { _ in .failed },
                              deadline: RuntimeTestDeadline? = nil,
                              checkpoint: (@Sendable (Runtime.Checkpoint) async -> Void)? = nil) -> Runtime.Dependencies {
        Runtime.Dependencies(
            context: { _ in },
            readPrefix: { _ in
                probe.didRead()
                return source ?? .prefix(LocalClassificationRequest(boundedPrefix: Data([0, 255, 10]))!)
            },
            provider: RuntimeTestProvider(identifier: provider.providerIdentifier) { request in
                probe.didInfer()
                return await provider.classify(request)
            },
            append: { probe.append($0) },
            makeRunID: { probe.makeID() },
            deadline: { start, interval in
                if let deadline { try await deadline.wait(start: start, interval: interval) }
                else { try await ContinuousClock().sleep(until: start.advanced(by: interval)) }
            },
            checkpoint: checkpoint
        )
    }

    private func classification(_ result: Runtime.StartResult) -> LocalClassificationProviderResult? {
        guard case let .completed(completion) = result,
              case let .classification(outcome, _) = completion.result else { return nil }
        return outcome
    }
}

private struct RuntimeTestProvider: LocalFileClassificationProvider {
    let providerIdentifier: String
    let detectorVersion: String? = "property-detector-must-not-be-used"
    let modelVersion: String? = "property-model-must-not-be-used"
    let operation: @Sendable (LocalClassificationRequest) async -> LocalClassificationProviderResult
    init(identifier: String = "actual-provider", _ operation: @escaping @Sendable (LocalClassificationRequest) async -> LocalClassificationProviderResult) {
        self.providerIdentifier = identifier
        self.operation = operation
    }
    func classify(_ request: LocalClassificationRequest) async -> LocalClassificationProviderResult {
        await operation(request)
    }
}

private actor RuntimeTestGate {
    private let entered: XCTestExpectation
    private var continuation: CheckedContinuation<Void, Never>?
    private var released = false
    init(entered: XCTestExpectation) { self.entered = entered }
    func wait() async {
        entered.fulfill()
        await withCheckedContinuation { continuation in
            if released { continuation.resume() }
            else { self.continuation = continuation }
        }
    }
    func release() {
        released = true
        continuation?.resume()
        continuation = nil
    }
}

/// Cancellation-aware injected clock; no wall-clock sleep determines ordering.
private final class RuntimeTestDeadline: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Void, Error>?
    private var fired = false
    private var cancelled = false
    private var observedInterval: Duration?
    var interval: Duration? { lock.withLock { observedInterval } }
    func wait(start: ContinuousClock.Instant, interval: Duration) async throws {
        try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                lock.withLock {
                    observedInterval = interval
                    if cancelled { continuation.resume(throwing: CancellationError()) }
                    else if fired { continuation.resume() }
                    else { self.continuation = continuation }
                }
            }
        }, onCancel: {
            self.lock.withLock {
                self.cancelled = true
                self.continuation?.resume(throwing: CancellationError())
                self.continuation = nil
            }
        })
    }
    func fire() {
        lock.withLock {
            fired = true
            continuation?.resume()
            continuation = nil
        }
    }
}

private final class RuntimeTestCaller: @unchecked Sendable {
    private let lock = NSLock()
    private var task: Task<Runtime.StartResult, Never>?
    func set(_ task: Task<Runtime.StartResult, Never>) { lock.withLock { self.task = task } }
    func cancel() { lock.withLock { task }?.cancel() }
}

private final class RuntimeTestHelperRunner: HelperProcessRunner, @unchecked Sendable {
    private let active: XCTestExpectation
    private let reaping: XCTestExpectation
    private let release: DispatchSemaphore
    private(set) var cleanupEvents: [String] = []
    init(active: XCTestExpectation, reaping: XCTestExpectation, release: DispatchSemaphore) {
        self.active = active; self.reaping = reaping; self.release = release
    }
    func launch(executable: URL) throws {}
    func deliverInputOnce(_ input: Data) throws {}
    func closeInput() {}
    func poll(stdoutBudget: Int, stderrBudget: Int, cancellation: HelperCancellation) throws -> HelperProcessFrame {
        active.fulfill()
        cancellation.waitUntilCancelled()
        return HelperProcessFrame(stdout: Data(), stderrCount: 0, finished: false)
    }
    func terminate() { cleanupEvents.append("terminate") }
    func closePipes() { cleanupEvents.append("closePipes") }
    func reap() -> HelperProcessExit {
        cleanupEvents.append("reap")
        reaping.fulfill()
        _ = release.wait(timeout: .now() + 5)
        return HelperProcessExit(status: 0, crashed: false)
    }
}

private final class RuntimeTestProbe: @unchecked Sendable {
    private let lock = NSLock()
    private var readCount = 0
    private var idCount = 0
    private var inferenceCount = 0
    private var rows: [EntryClassificationInput] = []
    var reads: Int { lock.withLock { readCount } }
    var inferences: Int { lock.withLock { inferenceCount } }
    func didInfer() { lock.withLock { inferenceCount += 1 } }
    var ids: Int { lock.withLock { idCount } }
    var inputs: [EntryClassificationInput] { lock.withLock { rows } }
    func didRead() { lock.withLock { readCount += 1 } }
    func makeID() -> String { lock.withLock { idCount += 1; return "run-\(idCount)" } }
    func append(_ input: EntryClassificationInput) -> EntryClassification {
        lock.withLock {
            rows.append(input)
            return EntryClassification(
                id: Int64(rows.count), entryID: input.entryID,
                classificationRunID: input.classificationRunID,
                detectedType: input.detectedType, mimeType: input.mimeType,
                confidence: input.confidence, detectionStatus: input.detectionStatus,
                detectorVersion: input.detectorVersion, modelVersion: input.modelVersion,
                providerIdentifier: input.providerIdentifier, classifiedAt: input.classifiedAt,
                createdAt: "fixture"
            )
        }
    }
}
