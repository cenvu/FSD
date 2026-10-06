import Foundation

/// The sole app-scoped runtime. Construction and observation perform no work.
/// Only explicit start admits a run; busy callers never queue or mint an ID.
actor ClassificationRuntimeService {
    static let shared = ClassificationRuntimeService()
    nonisolated static let inferenceTimeout: Duration = .seconds(5)
    private init() {}

    struct Identity: Sendable, Equatable {
        let entryID: Int64
        let runID: String
        let generation: UInt64
    }
    enum RepositoryFailure: Sendable, Equatable {
        case duplicateRun(entryID: Int64, runID: String)
        case entryNotFound(Int64)
        case invalidInput
        case storage

        fileprivate init(_ error: Error) {
            switch error as? EntryClassificationRepositoryError {
            case let .duplicateRun(entryID, runID): self = .duplicateRun(entryID: entryID, runID: runID)
            case let .entryNotFound(entryID): self = .entryNotFound(entryID)
            case .invalidInput: self = .invalidInput
            default: self = .storage
            }
        }
    }
    enum Result: Sendable, Equatable {
        case classification(LocalClassificationProviderResult, EntryClassification?)
        case repositoryFailure(RepositoryFailure)
    }
    struct Completion: Sendable, Equatable {
        let identity: Identity
        let result: Result
    }
    enum StartResult: Sendable, Equatable {
        case busy
        case rejected(RepositoryFailure)
        case completed(Completion)
    }
    enum State: Sendable, Equatable {
        case idle
        case running(Identity)
        case terminal(Completion)
    }

    /// Internal orchestration seams. Source authority stays with the reader;
    /// none of these closures or catalog identities are given to the provider.
    enum Checkpoint: Sendable { case beforeSource, afterRead, beforeInference, afterInference, beforePersistence }
    struct Dependencies: Sendable {
        var context: @Sendable (Int64) throws -> Void
        var readPrefix: @Sendable (Int64) async throws -> BoundedClassificationSourceOutcome
        let provider: any LocalFileClassificationProvider
        var append: @Sendable (EntryClassificationInput) throws -> EntryClassification
        /// One mint, never a replacement. Production UUIDs are bounded; the
        /// injected seam must obey repository ID bounds too.
        var makeRunID: @Sendable () -> String = { UUID().uuidString }
        var deadline: @Sendable (ContinuousClock.Instant, Duration) async throws -> Void = { start, interval in
            try await ContinuousClock().sleep(until: start.advanced(by: interval), tolerance: .zero)
        }
        var checkpoint: (@Sendable (Checkpoint) async -> Void)? = nil
    }

    private enum InferenceEvent { case result(LocalClassificationProviderResult), timeout, cancelled }
    private final class Active {
        let identity: Identity
        let cancellation: RuntimeCancellation
        var task: Task<Void, Never>?
        var providerTask: Task<Void, Never>?
        var deadlineTask: Task<Void, Never>?
        var continuation: CheckedContinuation<StartResult, Never>?
        var inference: CheckedContinuation<InferenceEvent, Never>?
        var published = false
        init(identity: Identity, cancellation: RuntimeCancellation) {
            self.identity = identity; self.cancellation = cancellation
        }
    }
    private var active: Active?
    private(set) var generation: UInt64 = 0
    private(set) var state: State = .idle
    /// Terminal publication and slot release are separate. Timeout/cancel may
    /// return promptly while this stays true until all owned work has unwound.
    var isActive: Bool { active != nil }

    func start(entryID: Int64, database: CatalogDatabase,
               provider: any LocalFileClassificationProvider) async -> StartResult {
        guard active == nil else { return .busy }
        let reader = BoundedClassificationSourceReader(database: database)
        let repository = EntryClassificationRepository(database: database)
        return await start(entryID: entryID, dependencies: Dependencies(
            context: { entryID in
                guard try database.scalar("SELECT 1 FROM entries WHERE id = ? LIMIT 1",
                                          bindings: [.integer(entryID)])?.int64Value == 1 else {
                    throw EntryClassificationRepositoryError.entryNotFound(entryID)
                }
            },
            readPrefix: { try reader.readPrefix(forEntryID: $0) },
            provider: provider,
            append: { try repository.append($0) }
        ))
    }

    func start(entryID: Int64, dependencies: Dependencies) async -> StartResult {
        guard active == nil else { return .busy }
        let runID = dependencies.makeRunID()
        guard !runID.isEmpty, runID.count <= 256 else { return .rejected(.invalidInput) }
        generation += 1
        let identity = Identity(entryID: entryID, runID: runID, generation: generation)
        let cancellation = RuntimeCancellation()
        let run = Active(identity: identity, cancellation: cancellation)
        active = run
        state = .running(identity)
        let alreadyCancelled = Task.isCancelled
        return await withTaskCancellationHandler(operation: {
            await withCheckedContinuation { continuation in
                run.continuation = continuation
                run.task = Task { await self.execute(identity, dependencies: dependencies) }
                if alreadyCancelled || cancellation.isCancelled { cancel(generation: identity.generation) }
            }
        }, onCancel: {
            // Synchronous token closes the caller-cancellation/actor-hop gap.
            // It shares the final append/completion authorization lock.
            cancellation.cancel()
            Task { await self.cancel(generation: identity.generation) }
        })
    }

    func cancel() {
        generation += 1
        cancelActive()
    }
    func invalidate() { cancel() }

    /// Observes cleanup of the currently owned run; it never admits/queues work.
    func waitForCleanup() async { await active?.task?.value }

    private func cancel(generation ownedGeneration: UInt64) {
        guard let active, active.identity.generation == ownedGeneration, !active.published else { return }
        generation += 1
        cancelActive()
    }
    private func cancelActive() {
        guard let active else { return }
        active.cancellation.cancel()
        active.task?.cancel()
        active.providerTask?.cancel()
        active.deadlineTask?.cancel()
        receive(.cancelled, generation: active.identity.generation)
        if !active.published {
            state = .idle
            active.cancellation.completeCancelled()
            publish(Completion(identity: active.identity, result: .classification(.cancelled, nil)), current: false)
        }
        // A previously published terminal result is immutable, even if its
        // provider is still unwinding. Keep its slot until execute drains it.
    }

    private func isCurrent(_ identity: Identity) -> Bool {
        active?.identity == identity && generation == identity.generation
            && active?.cancellation.isCancelled == false && !Task.isCancelled
    }

    private func execute(_ identity: Identity, dependencies: Dependencies) async {
        let result: Result
        do {
            let (outcome, providerRan) = try await produceOutcome(identity, dependencies: dependencies)
            if let checkpoint = dependencies.checkpoint { await checkpoint(.afterInference) }
            if let checkpoint = dependencies.checkpoint { await checkpoint(.beforePersistence) }
            result = mappedResult(outcome, providerRan: providerRan, identity: identity, dependencies: dependencies)
        } catch {
            result = .repositoryFailure(RepositoryFailure(error))
        }
        if let run = active, run.identity == identity, !run.published {
            // mappedResult performs the atomic commit; a context error still
            // needs completion authorization, but never a persistence attempt.
            if isCurrent(identity), let completed = run.cancellation.complete({ result }) {
                publish(Completion(identity: identity, result: completed), current: true)
            } else {
                cancel(generation: identity.generation)
            }
        }
        // Unstructured handles deliberately avoid a structured race's implicit
        // losing-child wait before timeout publication. Ownership is retained
        // here, AFTER publication, until every provider/deadline task returns.
        if let run = active, run.identity == identity {
            run.deadlineTask?.cancel()
            await run.providerTask?.value
            await run.deadlineTask?.value
            if active?.identity == identity { active = nil }
        }
    }

    /// This scope owns the source request only through inference handoff. The
    /// caller receives metadata only; sampled bytes never enter runtime state.
    private func produceOutcome(_ identity: Identity, dependencies: Dependencies) async throws
        -> (LocalClassificationProviderResult, Bool) {
        if let checkpoint = dependencies.checkpoint { await checkpoint(.beforeSource) }
        guard isCurrent(identity) else { return (.cancelled, false) }
        let source = try await Self.readSource(identity.entryID, dependencies: dependencies)
        if let checkpoint = dependencies.checkpoint { await checkpoint(.afterRead) }
        guard isCurrent(identity) else { return (.cancelled, false) }
        guard case let .prefix(request) = source else { return (source.preProviderResult!, false) }
        if let checkpoint = dependencies.checkpoint { await checkpoint(.beforeInference) }
        guard isCurrent(identity) else { return (.cancelled, false) }
        switch await infer(request, identity: identity, dependencies: dependencies) {
        case let .result(result): return (result, true)
        case .timeout: return (.failed, true)
        case .cancelled: return (.cancelled, true)
        }
    }

    private nonisolated static func readSource(_ entryID: Int64, dependencies: Dependencies) async throws
        -> BoundedClassificationSourceOutcome {
        // Synchronous filesystem/catalog work stays off the service actor and
        // MainActor. Cancellation reaches the reader's existing Task checks.
        let task = Task.detached(priority: .utility) {
            guard !Task.isCancelled else { return BoundedClassificationSourceOutcome.cancelled }
            try dependencies.context(entryID)
            guard !Task.isCancelled else { return .cancelled }
            return try await dependencies.readPrefix(entryID)
        }
        return try await withTaskCancellationHandler(operation: { try await task.value }, onCancel: { task.cancel() })
    }

    private func infer(_ request: LocalClassificationRequest, identity: Identity, dependencies: Dependencies) async -> InferenceEvent {
        guard let run = active, isCurrent(identity) else { return .cancelled }
        // Exact absolute deadline from inference handoff; source time excluded.
        let start = ContinuousClock().now
        let provider = dependencies.provider
        let deadline = dependencies.deadline
        return await withCheckedContinuation { continuation in
            run.inference = continuation
            run.providerTask = Task.detached(priority: .utility) {
                let result = await provider.classify(request)
                await self.providerFinished(result, generation: identity.generation)
            }
            run.deadlineTask = Task.detached(priority: .utility) {
                do {
                    try await deadline(start, Self.inferenceTimeout)
                    if !Task.isCancelled { await self.deadlineReached(generation: identity.generation) }
                } catch {
                    if !Task.isCancelled { await self.deadlineReached(generation: identity.generation) }
                }
            }
        }
    }

    private func providerFinished(_ result: LocalClassificationProviderResult, generation: UInt64) {
        guard let run = active, run.identity.generation == generation else { return }
        run.deadlineTask?.cancel()
        receive(run.cancellation.isCancelled ? .cancelled : .result(result), generation: generation)
    }
    private func deadlineReached(generation: UInt64) {
        guard let run = active, run.identity.generation == generation, run.inference != nil else { return }
        run.providerTask?.cancel()
        receive(run.cancellation.isCancelled ? .cancelled : .timeout, generation: generation)
    }
    private func receive(_ event: InferenceEvent, generation: UInt64) {
        guard let run = active, run.identity.generation == generation, let continuation = run.inference else { return }
        run.inference = nil
        continuation.resume(returning: event)
    }

    private func mappedResult(_ outcome: LocalClassificationProviderResult, providerRan: Bool,
                              identity: Identity, dependencies: Dependencies) -> Result {
        guard let run = active, !run.published, isCurrent(identity) else { return .classification(.cancelled, nil) }
        // No await from this generation check through append and publication.
        // Caller cancellation shares the short commit-authorization lock.
        // Authorization winning first seals the outcome against later cancel;
        // repository work executes after unlock, without an actor suspension.
        guard let result = run.cancellation.complete({
            let input: EntryClassificationInput?
            switch outcome {
            case let .classified(observation):
                input = EntryClassificationInput(
                    entryID: identity.entryID, classificationRunID: identity.runID,
                    detectedType: observation.detectedType, mimeType: observation.mimeType,
                    confidence: observation.confidence, detectionStatus: .classified,
                    detectorVersion: observation.detectorVersion, modelVersion: observation.modelVersion,
                    providerIdentifier: dependencies.provider.providerIdentifier, classifiedAt: observation.classifiedAt
                )
            case .failed, .sourceChanged, .unsupportedEntry:
                input = EntryClassificationInput(
                    entryID: identity.entryID, classificationRunID: identity.runID, detectionStatus: .failed,
                    providerIdentifier: outcome == .failed && providerRan ? dependencies.provider.providerIdentifier : nil
                )
            case .unavailable, .cancelled, .noMatch: input = nil
            }
            do { return Result.classification(outcome, try input.map { try dependencies.append($0) }) }
            catch { return .repositoryFailure(RepositoryFailure(error)) }
        }) else { return .classification(.cancelled, nil) }
        publish(Completion(identity: identity, result: result), current: true)
        return result
    }

    private func publish(_ completion: Completion, current: Bool) {
        guard let run = active, run.identity == completion.identity, !run.published else { return }
        run.published = true
        // Explicit post-append guard. There is intentionally no suspension
        // window between append and this check; future awaits must retain it.
        if current && generation == completion.identity.generation { state = .terminal(completion) }
        let continuation = run.continuation
        run.continuation = nil
        continuation?.resume(returning: .completed(completion))
    }
}

/// Bridges synchronous caller Task cancellation to commit authorization.
/// Only flags are locked. Repository work runs after unlock, so cancelling a
/// caller never waits for an append or executes a repository callback here.
private final class RuntimeCancellation: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false
    private var completionAuthorized = false
    var isCancelled: Bool { lock.withLock { cancelled } }
    func cancel() { lock.withLock { if !completionAuthorized { cancelled = true } } }
    func completeCancelled() { lock.withLock { cancelled = true; completionAuthorized = true } }
    func complete<T>(_ body: () -> T) -> T? {
        let authorized = lock.withLock {
            guard !cancelled, !completionAuthorized else { return false }
            completionAuthorized = true
            return true
        }
        return authorized ? body() : nil
    }
}
