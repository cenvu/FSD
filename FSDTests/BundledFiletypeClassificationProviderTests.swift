import XCTest
import Darwin
import CryptoKit
@testable import FSD

final class BundledFiletypeClassificationProviderTests: XCTestCase {
    private let valid = Data(#"{"schemaVersion":1,"resultKind":"classified","detectedType":"fixture","mimeType":"application/x-fixture","confidence":0.75,"detectorVersion":"detector-fixture","modelVersion":"model-fixture"}"#.utf8)
    private let root = URL(fileURLWithPath: "/Fixture/FSD.app")

    private func classify(_ output: Data, input: Data = Data(), status: Int32 = 0,
                          crash: Bool = false, stderr: Int = 0) async -> (LocalClassificationProviderResult, FakeHelperRunner) {
        let runner = FakeHelperRunner(frames: [HelperProcessFrame(stdout: output, stderrCount: stderr, finished: true)],
                                      exit: HelperProcessExit(status: status, crashed: crash))
        let provider = BundledFiletypeClassificationProvider(bundleRoot: root, makeRunner: { runner }, canonicalize: { $0 }, isExecutable: { _ in true })
        let result = await provider.classify(LocalClassificationRequest(boundedPrefix: input)!)
        return (result, runner)
    }

    func testRawInputEmptyMaximumAndExactlyOneClosedDelivery() async {
        for input in [Data(), Data([0, 255, 10, 13, 34, 92]), Data((0..<4096).map { UInt8(truncatingIfNeeded: $0) })] {
            let (result, runner) = await classify(valid, input: input)
            guard case .classified = result else { return XCTFail("valid envelope rejected") }
            XCTAssertEqual(runner.deliveries, [input])
            XCTAssertEqual(runner.events, ["launch", "deliver", "closeInput", "poll", "reap", "closePipes"])
            XCTAssertEqual(runner.launchedURL, root.appendingPathComponent(BundledFiletypeClassificationProvider.helperRelativePath))
            XCTAssertTrue(runner.reaped)
            XCTAssertTrue(runner.pipesClosed)
        }
    }

    func testProductionPipePumpCapsBothChannelsWithoutLaunchingAChild() throws {
        for length in [0, 4096, 4097] {
            let stdout = Pipe(), stderr = Pipe()
            let pump = HelperPipePump(stdout: stdout.fileHandleForReading, stderr: stderr.fileHandleForReading)
            defer { pump.close(); try? stdout.fileHandleForWriting.close(); try? stderr.fileHandleForWriting.close() }
            try pump.configure()
            try stdout.fileHandleForWriting.write(contentsOf: Data(repeating: 32, count: length))
            try stderr.fileHandleForWriting.write(contentsOf: Data(repeating: 88, count: length))
            try stdout.fileHandleForWriting.close()
            try stderr.fileHandleForWriting.close()
            var out = 0, err = 0, ended = false, oversized = false
            for _ in 0..<8 {
                let frame = try pump.poll(stdoutBudget: 4096 - out, stderrBudget: 4096 - err, stopped: true)
                XCTAssertLessThanOrEqual(frame.stdout.count, 1024)
                XCTAssertLessThanOrEqual(frame.stderrCount, 1024)
                out += frame.stdout.count; err += frame.stderrCount
                if frame.oversized { oversized = true; break }
                if frame.finished { ended = true; break }
            }
            XCTAssertEqual(out, min(length, 4096))
            XCTAssertEqual(err, min(length, 4096))
            XCTAssertEqual(oversized, length > 4096)
            XCTAssertEqual(ended, length <= 4096)
        }
    }

    func testProductionPipePumpServicesStderrWhileStdoutHasNoBytes() throws {
        let stdout = Pipe(), stderr = Pipe()
        let pump = HelperPipePump(stdout: stdout.fileHandleForReading, stderr: stderr.fileHandleForReading)
        defer { pump.close(); try? stdout.fileHandleForWriting.close(); try? stderr.fileHandleForWriting.close() }
        try pump.configure()
        try stderr.fileHandleForWriting.write(contentsOf: Data("HOSTILE_STDERR".utf8))
        let frame = try pump.poll(stdoutBudget: 4096, stderrBudget: 4096, stopped: false)
        XCTAssertTrue(frame.stdout.isEmpty)
        XCTAssertEqual(frame.stderrCount, 14)
        XCTAssertFalse(frame.finished)
        XCTAssertFalse(String(reflecting: frame).contains("HOSTILE_STDERR"))
    }

    func testFixedResolutionStandardizesAndRejectsEscapesAndSiblingPrefix() {
        let expected = root.appendingPathComponent(BundledFiletypeClassificationProvider.helperRelativePath)
        var inspected: [URL] = []
        let resolved = BundledFiletypeClassificationProvider.resolveExecutable(bundleRoot: root,
            canonicalize: { $0.standardizedFileURL }, isExecutable: { inspected.append($0); return true })
        XCTAssertEqual(resolved, expected)
        XCTAssertEqual(inspected, [expected])
        for escape in [URL(fileURLWithPath: "/outside/helper"), URL(fileURLWithPath: "/Fixture/FSD.app-evil/helper")] {
            XCTAssertNil(BundledFiletypeClassificationProvider.resolveExecutable(bundleRoot: root,
                canonicalize: { $0 == root ? root : escape }, isExecutable: { _ in XCTFail("outside executable inspected"); return true }))
        }
        XCTAssertNil(BundledFiletypeClassificationProvider.resolveExecutable(bundleRoot: root,
            canonicalize: { $0 }, isExecutable: { _ in false }))
    }

    func testPhysicalMissingNonExecutableDirectoryAndSymlinkResolution() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("FSD-AdapterResolution-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let bundle = directory.appendingPathComponent("FSD.app")
        let helper = bundle.appendingPathComponent(BundledFiletypeClassificationProvider.helperRelativePath)
        try FileManager.default.createDirectory(at: helper.deletingLastPathComponent(), withIntermediateDirectories: true)
        XCTAssertNil(BundledFiletypeClassificationProvider.resolveExecutable(bundleRoot: bundle))
        // Empty permission fixture only; never a runnable helper or input sample.
        XCTAssertTrue(FileManager.default.createFile(atPath: helper.path, contents: nil, attributes: [.posixPermissions: 0o600]))
        XCTAssertNil(BundledFiletypeClassificationProvider.resolveExecutable(bundleRoot: bundle))
        try FileManager.default.removeItem(at: helper)
        try FileManager.default.createDirectory(at: helper, withIntermediateDirectories: false)
        XCTAssertNil(BundledFiletypeClassificationProvider.resolveExecutable(bundleRoot: bundle))
        try FileManager.default.removeItem(at: helper)
        let outside = directory.appendingPathComponent("outside")
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: false)
        try FileManager.default.createSymbolicLink(at: helper, withDestinationURL: outside)
        XCTAssertNil(BundledFiletypeClassificationProvider.resolveExecutable(bundleRoot: bundle,
            isExecutable: { _ in XCTFail("escaped path reached permission check"); return true }))
    }

    func testMissingAndNonExecutableHelpersAreUnavailableAndNeverLaunch() async {
        for _ in ["missing", "nonExecutable"] {
            let runner = FakeHelperRunner(frames: [])
            let provider = BundledFiletypeClassificationProvider(bundleRoot: root, makeRunner: { runner }, canonicalize: { $0 }, isExecutable: { _ in false })
            let result = await provider.classify(LocalClassificationRequest(boundedPrefix: Data())!)
            XCTAssertEqual(result, .unavailable)
            XCTAssertTrue(runner.events.isEmpty)
        }
    }

    func testClassifiedEnvelopeAndIndependentHostProvenance() async {
        let (result, _) = await classify(valid)
        XCTAssertEqual(result, .classified(LocalClassificationObservation(detectedType: "fixture", mimeType: "application/x-fixture",
            confidence: 0.75, detectorVersion: "detector-fixture", modelVersion: "model-fixture")))
        let provider = BundledFiletypeClassificationProvider()
        XCTAssertEqual(provider.providerIdentifier, "fsd.bundled-helper-host.v1")
        XCTAssertNil(provider.detectorVersion)
        XCTAssertNil(provider.modelVersion)
        let overridden = String(decoding: valid, as: UTF8.self).replacingOccurrences(of: "}", with: ",\"providerIdentifier\":\"hostile\"}")
        let (rejected, _) = await classify(Data(overridden.utf8))
        XCTAssertEqual(rejected, .failed)
        XCTAssertEqual(provider.providerIdentifier, "fsd.bundled-helper-host.v1")
    }

    func testValidNoMatchEnvelope() async {
        let envelope = Data(#"{"schemaVersion":1,"resultKind":"no_match","detectedType":null,"mimeType":null,"confidence":null,"detectorVersion":null,"modelVersion":null}"#.utf8)
        let (result, runner) = await classify(envelope)
        XCTAssertEqual(result, .noMatch)
        XCTAssertEqual(runner.deliveries, [Data()])
        XCTAssertEqual(runner.events, ["launch", "deliver", "closeInput", "poll", "reap", "closePipes"])
    }

    func testNoMatchRejectsEachNonNullMetadataField() async throws {
        let base: [String: Any] = [
            "schemaVersion": 1, "resultKind": "no_match", "detectedType": NSNull(),
            "mimeType": NSNull(), "confidence": NSNull(), "detectorVersion": NSNull(), "modelVersion": NSNull()
        ]
        for field in ["detectedType", "mimeType", "confidence", "detectorVersion", "modelVersion"] {
            var envelope = base
            envelope[field] = field == "confidence" ? 0.5 : "metadata"
            let (result, runner) = await classify(try JSONSerialization.data(withJSONObject: envelope))
            XCTAssertEqual(result, .failed, "no_match metadata must be null: \(field)")
            XCTAssertTrue(runner.reaped)
            XCTAssertTrue(runner.pipesClosed)
        }
    }

    func testUnknownResultKindsFailAndClassifiedRequiresDetectedType() async {
        for kind in ["unknown", "unrecognized", "not_classified", "classified"] {
            let envelope = Data("{\"schemaVersion\":1,\"resultKind\":\"\(kind)\",\"detectedType\":null,\"mimeType\":null,\"confidence\":null,\"detectorVersion\":null,\"modelVersion\":null}".utf8)
            let (result, _) = await classify(envelope)
            XCTAssertEqual(result, .failed, "kind must fail without a recognized type: \(kind)")
        }
    }

    func testDeclaredUnavailableAndFailed() async {
        for (kind, expected) in [("unavailable", LocalClassificationProviderResult.unavailable), ("failed", .failed)] {
            let envelope = Data("{\"schemaVersion\":1,\"resultKind\":\"\(kind)\",\"detectedType\":null,\"mimeType\":null,\"confidence\":null,\"detectorVersion\":null,\"modelVersion\":null}".utf8)
            let (result, runner) = await classify(envelope)
            XCTAssertEqual(result, expected)
            XCTAssertTrue(runner.reaped)
            XCTAssertTrue(runner.pipesClosed)
        }
    }

    func testStrictMalformedSchemaKindTypesLengthsAndConfidence() async {
        let text = String(decoding: valid, as: UTF8.self)
        let bad = [
            "", "[]", "null", text + "x",
            text.replacingOccurrences(of: "\"schemaVersion\":1", with: "\"schemaVersion\":2"),
            text.replacingOccurrences(of: "\"schemaVersion\":1", with: "\"schemaVersion\":true"),
            text.replacingOccurrences(of: "\"schemaVersion\":1", with: "\"schemaVersion\":1.0"),
            text.replacingOccurrences(of: "\"classified\"", with: "\"unknown\""),
            text.replacingOccurrences(of: "\"fixture\"", with: "42"),
            text.replacingOccurrences(of: "\"fixture\"", with: "null"),
            text.replacingOccurrences(of: "\"fixture\"", with: "\"\""),
            text.replacingOccurrences(of: "\"fixture\"", with: "\"" + String(repeating: "x", count: 257) + "\""),
            text.replacingOccurrences(of: "0.75", with: "-0.1"),
            text.replacingOccurrences(of: "0.75", with: "1.1"),
            text.replacingOccurrences(of: "0.75", with: "true"),
            text.replacingOccurrences(of: "0.75", with: "\"0.75\""),
            text.replacingOccurrences(of: "0.75", with: "1e999"),
            text.replacingOccurrences(of: "\"modelVersion\":\"model-fixture\"", with: "\"modelVersion\":[]"),
            text.replacingOccurrences(of: "}", with: ",\"modelVersion\":\"duplicate\"}"),
            text.replacingOccurrences(of: ",\"modelVersion\":\"model-fixture\"", with: ""),
            text.replacingOccurrences(of: "}", with: ",\"extra\":null}")
        ]
        for envelope in bad {
            let (result, runner) = await classify(Data(envelope.utf8))
            XCTAssertEqual(result, .failed, "invalid fixture accepted: \(envelope)")
            XCTAssertTrue(runner.reaped)
            XCTAssertTrue(runner.pipesClosed)
        }
    }

    func testCapsAreCumulativeAndStderrNeverSurfaces() async {
        let runner = FakeHelperRunner(frames: [
            HelperProcessFrame(stdout: valid, stderrCount: 2048, finished: false),
            HelperProcessFrame(stdout: Data(), stderrCount: 2048, finished: true)
        ])
        let provider = BundledFiletypeClassificationProvider(bundleRoot: root, makeRunner: { runner }, canonicalize: { $0 }, isExecutable: { _ in true })
        let result = await provider.classify(LocalClassificationRequest(boundedPrefix: Data())!)
        guard case .classified = result else { return XCTFail("stderr at cap must be discarded") }
        XCTAssertFalse(String(reflecting: result).contains("HOSTILE_STDERR"))
        for (out, err) in [(Data(count: 4097), 0), (valid, 4097)] {
            let (failed, stopped) = await classify(out, stderr: err)
            XCTAssertEqual(failed, .failed)
            XCTAssertTrue(stopped.terminated)
            XCTAssertTrue(stopped.reaped)
            XCTAssertTrue(stopped.pipesClosed)
            XCTAssertLessThanOrEqual(stopped.stdoutConsumed, 4096)
            XCTAssertLessThanOrEqual(stopped.stderrConsumed, 4096)
        }
        let exact = valid + Data(repeating: 32, count: 4096 - valid.count)
        let (atCap, _) = await classify(exact)
        guard case .classified = atCap else { return XCTFail("stdout exact cap rejected") }
        let accumulated = FakeHelperRunner(frames: [
            HelperProcessFrame(stdout: Data(count: 3000), stderrCount: 0, finished: false),
            HelperProcessFrame(stdout: Data(count: 1097), stderrCount: 0, finished: false)
        ])
        let capped = BundledFiletypeClassificationProvider(bundleRoot: root, makeRunner: { accumulated }, canonicalize: { $0 }, isExecutable: { _ in true })
        let cappedResult = await capped.classify(LocalClassificationRequest(boundedPrefix: Data())!)
        XCTAssertEqual(cappedResult, .failed)
        XCTAssertTrue(accumulated.terminated)
        XCTAssertTrue(accumulated.reaped)
    }

    func testNonzeroCrashLaunchWriteAndReadFaultsReapAndClose() async {
        for (status, crash) in [(Int32(3), false), (0, true)] {
            let (result, runner) = await classify(valid, status: status, crash: crash)
            XCTAssertEqual(result, .failed)
            XCTAssertTrue(runner.reaped)
            XCTAssertTrue(runner.pipesClosed)
        }
        for fault in ["launch", "deliver", "poll"] {
            let runner = FakeHelperRunner(frames: [], fault: fault)
            let provider = BundledFiletypeClassificationProvider(bundleRoot: root, makeRunner: { runner }, canonicalize: { $0 }, isExecutable: { _ in true })
            let result = await provider.classify(LocalClassificationRequest(boundedPrefix: Data())!)
            XCTAssertEqual(result, .failed)
            XCTAssertTrue(runner.reaped)
            XCTAssertTrue(runner.pipesClosed)
        }
    }

    func testCancellationWhileActiveTerminatesReapsAndCloses() async {
        let active = expectation(description: "active child")
        let runner = FakeHelperRunner(frames: [], onPoll: { cancellation in
            active.fulfill()
            cancellation.waitUntilCancelled()
        })
        let provider = BundledFiletypeClassificationProvider(bundleRoot: root, makeRunner: { runner }, canonicalize: { $0 }, isExecutable: { _ in true })
        let task = Task { await provider.classify(LocalClassificationRequest(boundedPrefix: Data([9]))!) }
        await fulfillment(of: [active], timeout: 5)
        task.cancel()
        let result = await task.value
        XCTAssertEqual(result, .cancelled)
        XCTAssertTrue(runner.terminated)
        XCTAssertTrue(runner.reaped)
        XCTAssertTrue(runner.pipesClosed)
    }

    func testCancellationDuringRunnerCreationPreventsLaunchAuthorization() async {
        let creating = expectation(description: "runner factory entered")
        let release = DispatchSemaphore(value: 0)
        let runner = FakeHelperRunner(frames: [])
        let provider = BundledFiletypeClassificationProvider(bundleRoot: root, makeRunner: {
            creating.fulfill()
            XCTAssertEqual(release.wait(timeout: .now() + 5), .success)
            return runner
        }, canonicalize: { $0 }, isExecutable: { _ in true })
        let task = Task { await provider.classify(LocalClassificationRequest(boundedPrefix: Data())!) }
        await fulfillment(of: [creating], timeout: 5)
        task.cancel()
        release.signal()
        let result = await task.value
        XCTAssertEqual(result, .cancelled)
        XCTAssertEqual(runner.events.filter { $0 == "launch" }.count, 0)
        XCTAssertNil(runner.launchedURL, "no modeled child was created")
        XCTAssertFalse(runner.reaped, "nonlaunched runner needs no reap")
        XCTAssertTrue(runner.events.isEmpty)
    }

    func testLaunchAuthorizationFirstThenCancellationDuringLaunchCleansUp() async {
        let launching = expectation(description: "authorized launch entered")
        let release = DispatchSemaphore(value: 0)
        let runner = FakeHelperRunner(frames: [], onLaunch: {
            launching.fulfill()
            XCTAssertEqual(release.wait(timeout: .now() + 5), .success)
        })
        let provider = BundledFiletypeClassificationProvider(bundleRoot: root, makeRunner: { runner }, canonicalize: { $0 }, isExecutable: { _ in true })
        let task = Task { await provider.classify(LocalClassificationRequest(boundedPrefix: Data())!) }
        await fulfillment(of: [launching], timeout: 5)
        task.cancel()
        release.signal()
        let result = await task.value
        XCTAssertEqual(result, .cancelled)
        XCTAssertEqual(runner.events, ["launch", "terminate", "closePipes", "reap"])
        XCTAssertEqual(runner.launchedURL, root.appendingPathComponent(BundledFiletypeClassificationProvider.helperRelativePath))
        XCTAssertTrue(runner.terminated)
        XCTAssertTrue(runner.pipesClosed)
        XCTAssertTrue(runner.reaped)
    }

    func testCompletionFirstRemainsStableAfterTaskCancellation() async {
        let runner = FakeHelperRunner(frames: [HelperProcessFrame(stdout: valid, stderrCount: 0, finished: true)])
        let provider = BundledFiletypeClassificationProvider(bundleRoot: root, makeRunner: { runner }, canonicalize: { $0 }, isExecutable: { _ in true })
        let task = Task { await provider.classify(LocalClassificationRequest(boundedPrefix: Data())!) }
        let completed = await task.value
        guard case .classified = completed else { return XCTFail("completion must succeed") }
        let events = runner.events
        task.cancel()
        let afterCancellation = await task.value
        XCTAssertEqual(afterCancellation, completed)
        XCTAssertEqual(runner.events, events, "no runner activity after completion")
        XCTAssertTrue(runner.reaped)
        XCTAssertTrue(runner.pipesClosed)
    }

    func testCancellationBeforeLaunchAndCompletionOrdering() async {
        let runner = FakeHelperRunner(frames: [])
        let provider = BundledFiletypeClassificationProvider(bundleRoot: root, makeRunner: { runner }, canonicalize: { $0 }, isExecutable: { _ in true })
        let task = Task { () -> LocalClassificationProviderResult in
            while !Task.isCancelled { await Task.yield() }
            return await provider.classify(LocalClassificationRequest(boundedPrefix: Data())!)
        }
        task.cancel()
        let result = await task.value
        XCTAssertEqual(result, .cancelled)
        XCTAssertTrue(runner.events.isEmpty)
        let ordering = HelperCancellation()
        XCTAssertEqual(ordering.complete(.unavailable), .unavailable)
        ordering.cancel()
        XCTAssertFalse(ordering.isCancelled, "completion is the locked linearization point")
        XCTAssertFalse(ordering.authorizeLaunch(), "completion forbids later launch authorization")
        let cancelFirst = HelperCancellation()
        cancelFirst.cancel()
        XCTAssertFalse(cancelFirst.authorizeLaunch())
        XCTAssertEqual(cancelFirst.complete(.unavailable), .cancelled)
        let authorizationFirst = HelperCancellation()
        XCTAssertTrue(authorizationFirst.authorizeLaunch())
        XCTAssertFalse(authorizationFirst.authorizeLaunch(), "launch is authorized only once")
        authorizationFirst.cancel()
        XCTAssertEqual(authorizationFirst.complete(.unavailable), .cancelled)
    }

    func testConstructionAndDisabledProviderAreInert() async {
        var creations = 0
        let provider = BundledFiletypeClassificationProvider(bundleRoot: root, makeRunner: {
            creations += 1
            return FakeHelperRunner(frames: [])
        }, canonicalize: { $0 }, isExecutable: { _ in true })
        XCTAssertEqual(creations, 0)
        XCTAssertEqual(provider.providerIdentifier, "fsd.bundled-helper-host.v1")
        let disabled = await DisabledFileClassificationProvider().classify(LocalClassificationRequest(boundedPrefix: Data())!)
        XCTAssertEqual(disabled, .unavailable)
        XCTAssertEqual(creations, 0)
    }

    func testSourceBoundaryNoPayloadPersistenceShellNetworkOrUnboundedReads() throws {
        let file = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("FSD/Classification/BundledFiletypeClassificationProvider.swift")
        let source = try String(contentsOf: file, encoding: .utf8)
        for forbidden in ["readDataToEndOfFile", "readToEnd", "availableData", "URLSession", "UserDefaults", "getenv", "/bin/sh", "/usr/bin/env",
                          "temporaryDirectory", ".write(to:", "base64", "NSLog", "print(", "Logger(", "Task.detached", "CatalogDatabase"] {
            XCTAssertFalse(source.contains(forbidden), forbidden)
        }
        XCTAssertTrue(source.contains("process.arguments = []"))
        XCTAssertTrue(source.contains("process.environment = [:]"))
    }
}

/// Only the internal runner carries process machinery. Shared driver, not this
/// fake, owns cap enforcement, one delivery, cleanup and cancellation ordering.
private final class FakeHelperRunner: HelperProcessRunner {
    private var frames: [HelperProcessFrame]
    private let exit: HelperProcessExit
    private let fault: String?
    private let onLaunch: (() -> Void)?
    private let onPoll: ((HelperCancellation) -> Void)?
    private(set) var stdoutConsumed = 0
    private(set) var stderrConsumed = 0
    private(set) var events: [String] = []
    private(set) var deliveries: [Data] = []
    private(set) var launchedURL: URL?
    private(set) var terminated = false
    private(set) var reaped = false
    private(set) var pipesClosed = false
    init(frames: [HelperProcessFrame], exit: HelperProcessExit = HelperProcessExit(status: 0, crashed: false),
         fault: String? = nil, onLaunch: (() -> Void)? = nil, onPoll: ((HelperCancellation) -> Void)? = nil) {
        self.frames = frames; self.exit = exit; self.fault = fault; self.onLaunch = onLaunch; self.onPoll = onPoll
    }
    private func record(_ event: String) throws {
        events.append(event)
        if fault == event { throw NSError(domain: "fixture", code: 1) }
    }
    func launch(executable: URL) throws { try record("launch"); launchedURL = executable; onLaunch?() }
    func deliverInputOnce(_ input: Data) throws { try record("deliver"); deliveries.append(input) }
    func closeInput() { events.append("closeInput") }
    func poll(stdoutBudget: Int, stderrBudget: Int, cancellation: HelperCancellation) throws -> HelperProcessFrame {
        try record("poll")
        onPoll?(cancellation)
        if frames.isEmpty { return HelperProcessFrame(stdout: Data(), stderrCount: 0, finished: true) }
        let frame = frames.removeFirst()
        let output = Data(frame.stdout.prefix(stdoutBudget))
        let stderr = min(frame.stderrCount, stderrBudget)
        stdoutConsumed += output.count
        stderrConsumed += stderr
        return HelperProcessFrame(stdout: output, stderrCount: stderr, finished: frame.finished,
                                  oversized: frame.stdout.count > stdoutBudget || frame.stderrCount > stderrBudget)
    }
    func terminate() { events.append("terminate"); terminated = true }
    func reap() -> HelperProcessExit { events.append("reap"); reaped = true; return exit }
    func closePipes() { events.append("closePipes"); pipesClosed = true }
}

extension BundledFiletypeClassificationProviderTests {
    func testActualCommittedHelperIsRequired() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let helper = root.appendingPathComponent("FSD/Helpers/FSDClassificationHostSeam")
        XCTAssertTrue(FileManager.default.isExecutableFile(atPath: helper.path),
                      "The actual committed helper is mandatory; absence is FAILURE, never SKIP")
    }
}

// ADR-035 acceptance exercises the shipped bytes and the production runner.
// Public pinned upstream fixture prefixes are test assets; no user source is read.
extension BundledFiletypeClassificationProviderTests {
    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    }
    private func committedHelper() throws -> URL {
        let url = repositoryRoot.appendingPathComponent("FSD/Helpers/FSDClassificationHostSeam")
        guard FileManager.default.isExecutableFile(atPath: url.path) else {
            XCTFail("Actual committed helper missing or nonexecutable; never skip")
            throw CocoaError(.fileNoSuchFile)
        }
        return url
    }
    private func directReply(_ data: Data) throws -> [String: Any] {
        let child = Process(), input = Pipe(), output = Pipe(), error = Pipe()
        child.executableURL = try committedHelper()
        child.arguments = []; child.environment = [:]
        child.standardInput = input; child.standardOutput = output; child.standardError = error
        try child.run()
        try input.fileHandleForWriting.write(contentsOf: data)
        try input.fileHandleForWriting.close()
        let reply = output.fileHandleForReading.readDataToEndOfFile()
        let diagnostic = error.fileHandleForReading.readDataToEndOfFile()
        child.waitUntilExit()
        XCTAssertEqual(child.terminationStatus, 0)
        XCTAssertTrue(diagnostic.isEmpty)
        XCTAssertLessThanOrEqual(reply.count, BundledFiletypeClassificationProvider.stdoutCap)
        XCTAssertEqual(reply.filter { $0 == 10 }.count, 1, "one envelope only")
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: reply) as? [String: Any])
        XCTAssertEqual(Set(object.keys), Set(["schemaVersion", "resultKind", "detectedType", "mimeType", "confidence", "detectorVersion", "modelVersion"]))
        XCTAssertEqual(object["schemaVersion"] as? Int, 1)
        XCTAssertTrue(object["confidence"] is NSNull)
        XCTAssertTrue(object["modelVersion"] is NSNull)
        return object
    }
    private func assertNullMetadata(_ object: [String: Any], kind: String = "no_match") {
        XCTAssertEqual(object["resultKind"] as? String, kind)
        for key in ["detectedType", "mimeType", "confidence", "detectorVersion", "modelVersion"] {
            XCTAssertTrue(object[key] is NSNull, key)
        }
    }
    func testActualHelperPNGUnknownEmptyAndExactBounds() throws {
        let png = Data([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
        for payload in [png, png + Data(repeating: 0, count: 4096 - png.count)] {
            let reply = try directReply(payload)
            XCTAssertEqual(reply["resultKind"] as? String, "classified")
            XCTAssertEqual(reply["detectedType"] as? String, "png")
            XCTAssertEqual(reply["mimeType"] as? String, "image/png")
            XCTAssertEqual(reply["detectorVersion"] as? String, "github.com/h2non/filetype@v1.1.3")
        }
        for payload in [Data(), Data([0, 1, 2, 3]), Data(repeating: 0, count: 4096)] {
            assertNullMetadata(try directReply(payload))
        }
        assertNullMetadata(try directReply(png + Data(repeating: 0, count: 4097 - png.count)), kind: "failed")
        XCTAssertNil(LocalClassificationRequest(boundedPrefix: Data(repeating: 0, count: 4097)))
    }
    func testActualHelperShortCFBRegressionAcrossFreshProcesses() throws {
        for length in [4, 32, 513] {
            let data = Data([0xd0, 0xcf, 0x11, 0xe0]) + Data(repeating: 0, count: length - 4)
            for _ in 0..<32 { assertNullMetadata(try directReply(data)) }
        }
    }
    func testActualHelperLongCFBRoutingAndNonmatchingGuardEdge() throws {
        for length in [514, 515, 1024, 4096] {
            for (type, discriminant) in [("doc", [UInt8(0xec), 0xa5]), ("xls", [0x09, 0x08]), ("ppt", [0xa0, 0x46]), ("none", [0x00, 0x00])] {
                var data = Data([0xd0, 0xcf, 0x11, 0xe0]) + Data(repeating: 0, count: length - 4)
                data.replaceSubrange(512..<514, with: discriminant)
                for _ in 0..<16 {
                    let reply = try directReply(data)
                    if type == "none" { assertNullMetadata(reply) }
                    else {
                        XCTAssertEqual(reply["resultKind"] as? String, "classified")
                        XCTAssertEqual(reply["detectedType"] as? String, type)
                    }
                }
            }
        }
    }
    func testActualPinnedFixturesSingleValuedDirectAndThroughProductionRunner() async throws {
        _ = try committedHelper()
        let provider = BundledFiletypeClassificationProvider()
        XCTAssertNotNil(BundledFiletypeClassificationProvider.resolveExecutable(bundleRoot: Bundle.main.bundleURL))
        XCTAssertEqual(provider.providerIdentifier, "fsd.bundled-helper-host.v1")
        for (type, payload) in Self.pinnedFixturePrefixes {
            for _ in 0..<16 {
                let reply = try directReply(payload)
                XCTAssertEqual(reply["detectedType"] as? String, type)
            }
            let result = await provider.classify(try XCTUnwrap(LocalClassificationRequest(boundedPrefix: payload)))
            guard case let .classified(observation) = result else { return XCTFail("real pinned fixture failed: \(type)") }
            XCTAssertEqual(observation.detectedType, type)
            XCTAssertEqual(observation.detectorVersion, "github.com/h2non/filetype@v1.1.3")
            XCTAssertNil(observation.confidence); XCTAssertNil(observation.modelVersion)
        }
        for payload in [Data(), Data([0, 1, 2, 3]), Data([0xd0, 0xcf, 0x11, 0xe0])] {
            let result = await provider.classify(try XCTUnwrap(LocalClassificationRequest(boundedPrefix: payload)))
            XCTAssertEqual(result, .noMatch)
        }
    }
    func testActualHelperCrashAndCancellationReapTheRealChild() async throws {
        _ = try committedHelper()
        for mode in [ActualHelperControlRunner.Mode.crash, .suspend] {
            let active = expectation(description: "actual child controlled")
            let runner = ActualHelperControlRunner(mode: mode, active: active)
            let provider = BundledFiletypeClassificationProvider(bundleRoot: Bundle.main.bundleURL,
                makeRunner: { runner }, isExecutable: { FileManager.default.isExecutableFile(atPath: $0.path) })
            let task = Task { await provider.classify(LocalClassificationRequest(boundedPrefix: Data())!) }
            await fulfillment(of: [active], timeout: 5)
            if mode == .suspend { task.cancel() }
            let result = await task.value
            XCTAssertEqual(result, mode == .crash ? .failed : .cancelled)
            XCTAssertTrue(runner.reaped); XCTAssertTrue(runner.closed)
            XCTAssertGreaterThan(runner.childPID, 0)
            XCTAssertEqual(Darwin.kill(runner.childPID, 0), -1, "child must be reaped before return")
            XCTAssertEqual(errno, ESRCH)
        }
    }
    func testActualHelperFiveSecondRuntimeTimeoutAndNoStaleNoMatchPublication() async throws {
        _ = try committedHelper()
        let runtime = ClassificationRuntimeService.shared
        await runtime.cancel(); await runtime.waitForCleanup()
        let active = expectation(description: "actual child suspended before inference")
        let runner = ActualHelperControlRunner(mode: .suspend, active: active)
        let provider = BundledFiletypeClassificationProvider(bundleRoot: Bundle.main.bundleURL,
            makeRunner: { runner }, isExecutable: { FileManager.default.isExecutableFile(atPath: $0.path) })
        let append = ActualHelperAppendProbe()
        let dependencies = ClassificationRuntimeService.Dependencies(context: { _ in },
            readPrefix: { _ in .prefix(LocalClassificationRequest(boundedPrefix: Data())!) },
            provider: provider, append: { input in append.record(input) })
        let started = ContinuousClock.now
        let run = Task { await runtime.start(entryID: 2, dependencies: dependencies) }
        await fulfillment(of: [active], timeout: 5)
        let outcome = await run.value
        await runtime.waitForCleanup()
        guard case let .completed(completion) = outcome,
              case let .classification(result, _) = completion.result else { return XCTFail("missing timeout completion") }
        XCTAssertEqual(result, .failed)
        XCTAssertGreaterThanOrEqual(started.duration(to: .now), .seconds(5))
        XCTAssertEqual(append.inputs.count, 1); XCTAssertEqual(append.inputs.first?.detectionStatus, .failed)
        XCTAssertTrue(runner.reaped); XCTAssertTrue(runner.closed)

        // Fresh actual helper runs, then generation invalidation wins before append/publication.
        let checkpoint = ActualHelperCheckpoint()
        let staleAppend = ActualHelperAppendProbe()
        var stale = ClassificationRuntimeService.Dependencies(context: { _ in },
            readPrefix: { _ in .prefix(LocalClassificationRequest(boundedPrefix: Data())!) },
            provider: BundledFiletypeClassificationProvider(), append: { staleAppend.record($0) })
        stale.checkpoint = { point in if case .afterInference = point { await checkpoint.arrive() } }
        let staleRun = Task { await runtime.start(entryID: 3, dependencies: stale) }
        await checkpoint.waitForArrival()
        await runtime.invalidate()
        await checkpoint.release()
        let staleResult = await staleRun.value
        await runtime.waitForCleanup()
        guard case let .completed(staleCompletion) = staleResult,
              case let .classification(staleOutcome, row) = staleCompletion.result else { return XCTFail("missing stale completion") }
        XCTAssertEqual(staleOutcome, .cancelled); XCTAssertNil(row)
        XCTAssertTrue(staleAppend.inputs.isEmpty)
    }
    func testActualHelperNoMatchZeroRowsAndFactsUnchanged() async throws {
        _ = try committedHelper()
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("FSD-ActualHelper-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let db = try CatalogDatabase(url: dir.appendingPathComponent("catalog.sqlite3"), schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        defer { db.close() }
        let snapshot = try SyntheticSnapshot.createSnapshot(database: db, volumeID: 21, session: 1)
        try SyntheticSnapshot.insertEntries(database: db, snapshotID: snapshot, entries: [SyntheticSnapshot.root(id: 1), SyntheticSnapshot.SeedEntry(id: 2, parentID: 1, relativePath: "a", name: "a")])
        try SyntheticSnapshot.complete(database: db, snapshotID: snapshot)
        let before = try db.query("SELECT * FROM entries ORDER BY id")
        let repository = EntryClassificationRepository(database: db)
        let runtime = ClassificationRuntimeService.shared
        await runtime.cancel(); await runtime.waitForCleanup()
        let outcome = await runtime.start(entryID: 2, dependencies: .init(context: { _ in },
            readPrefix: { _ in .prefix(LocalClassificationRequest(boundedPrefix: Data())!) },
            provider: BundledFiletypeClassificationProvider(), append: { try repository.append($0) }))
        await runtime.waitForCleanup()
        guard case let .completed(completion) = outcome,
              case let .classification(result, row) = completion.result else { return XCTFail("missing real noMatch") }
        XCTAssertEqual(result, .noMatch); XCTAssertNil(row)
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM entry_classifications")?.int64Value, 0)
        XCTAssertEqual(try db.query("SELECT * FROM entries ORDER BY id"), before)
        let request = LocalClassificationRequest(boundedPrefix: Data())!
        XCTAssertEqual(Mirror(reflecting: request).children.compactMap(\.label), ["data"])
    }
}

/// Controlled signals target the actual production runner's direct child.
/// No alternate executable, response, envelope or cleanup logic substitutes.
private final class ActualHelperControlRunner: HelperProcessRunner, @unchecked Sendable {
    enum Mode { case crash, suspend }
    let mode: Mode
    let active: XCTestExpectation
    let inner = FoundationHelperProcessRunner()
    private(set) var childPID: Int32 = 0
    private(set) var reaped = false
    private(set) var closed = false
    init(mode: Mode, active: XCTestExpectation) { self.mode = mode; self.active = active }
    func launch(executable: URL) throws {
        try inner.launch(executable: executable)
        let ps = Process(), pipe = Pipe()
        ps.executableURL = URL(fileURLWithPath: "/bin/ps")
        ps.arguments = ["-axo", "pid=,ppid=,comm="]; ps.standardOutput = pipe
        try ps.run(); let text = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self); ps.waitUntilExit()
        for line in text.split(separator: "\n") {
            let parts = line.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
            if parts.count == 3, Int32(parts[1]) == getpid(), parts[2].hasSuffix("FSDClassificationHostSeam"), let pid = Int32(parts[0]) { childPID = pid }
        }
        guard childPID > 0, Darwin.kill(childPID, mode == .crash ? SIGKILL : SIGSTOP) == 0 else { throw CocoaError(.executableLoad) }
        active.fulfill()
    }
    func deliverInputOnce(_ input: Data) throws { if mode == .suspend { try inner.deliverInputOnce(input) } }
    func closeInput() { inner.closeInput() }
    func poll(stdoutBudget: Int, stderrBudget: Int, cancellation: HelperCancellation) throws -> HelperProcessFrame {
        try inner.poll(stdoutBudget: stdoutBudget, stderrBudget: stderrBudget, cancellation: cancellation)
    }
    func terminate() { inner.terminate() }
    func reap() -> HelperProcessExit { reaped = true; return inner.reap() }
    func closePipes() { closed = true; inner.closePipes() }
}
private final class ActualHelperAppendProbe: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [EntryClassificationInput] = []
    var inputs: [EntryClassificationInput] { lock.lock(); defer { lock.unlock() }; return storage }
    func record(_ input: EntryClassificationInput) -> EntryClassification {
        lock.lock(); storage.append(input); lock.unlock()
        return EntryClassification(id: 1, entryID: input.entryID, classificationRunID: input.classificationRunID,
            detectedType: input.detectedType, mimeType: input.mimeType, confidence: input.confidence,
            detectionStatus: input.detectionStatus, detectorVersion: input.detectorVersion, modelVersion: input.modelVersion,
            providerIdentifier: input.providerIdentifier, classifiedAt: input.classifiedAt, createdAt: "fixture")
    }
}
private actor ActualHelperCheckpoint {
    private var arrived = false
    private var waiter: CheckedContinuation<Void, Never>?
    private var continuation: CheckedContinuation<Void, Never>?
    func arrive() async {
        arrived = true; waiter?.resume(); waiter = nil
        await withCheckedContinuation { continuation = $0 }
    }
    func waitForArrival() async { if !arrived { await withCheckedContinuation { waiter = $0 } } }
    func release() { continuation?.resume(); continuation = nil }
}

// Exact prefixes from github.com/h2non/filetype@v1.1.3/fixtures; module Sum is manifest-pinned.
extension BundledFiletypeClassificationProviderTests {
    private static let pinnedFixturePrefixes: [(String, Data)] = [
        ("png", Data(base64Encoded: "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")!),
        ("docx", Data(base64Encoded: "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")!),
        ("xlsx", Data(base64Encoded: "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")!),
        ("pptx", Data(base64Encoded: "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")!),
    ]
}

extension BundledFiletypeClassificationProviderTests {
    private func metadataTool(_ executable: String, _ arguments: [String]) throws -> String {
        let process = Process(), output = Pipe(), error = Pipe()
        process.executableURL = URL(fileURLWithPath: executable); process.arguments = arguments
        process.standardOutput = output; process.standardError = error
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        let diagnostics = error.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0, String(decoding: diagnostics, as: UTF8.self))
        return String(decoding: data, as: UTF8.self)
    }
    func testActualBundleManifestNoticesArchitectureAndResourceClosure() throws {
        let tracked = try committedHelper()
        let manifest = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: repositoryRoot.appendingPathComponent("FSD/Helpers/FSDClassificationHostSeam.manifest.json"))) as? [String: Any])
        let trackedBytes = try Data(contentsOf: tracked)
        let sha = SHA256.hash(data: trackedBytes).map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(manifest["helperSHA256"] as? String, sha)
        XCTAssertEqual(manifest["detectorVersion"] as? String, "github.com/h2non/filetype@v1.1.3")
        XCTAssertEqual(manifest["GOARCH"] as? String, "arm64")
        XCTAssertEqual(manifest["goVersion"] as? String, "go1.27.1")
        var canonical = Data()
        for path in try XCTUnwrap(manifest["helperSourceSet"] as? [String]).sorted() {
            let bytes = try Data(contentsOf: repositoryRoot.appendingPathComponent(path))
            canonical.append(Data(path.utf8)); canonical.append(0)
            canonical.append(Data(String(bytes.count).utf8)); canonical.append(0); canonical.append(bytes)
        }
        XCTAssertEqual(manifest["helperSourceSHA256"] as? String, SHA256.hash(data: canonical).map { String(format: "%02x", $0) }.joined())
        let app = Bundle.main.bundleURL
        let bundled = app.appendingPathComponent(BundledFiletypeClassificationProvider.helperRelativePath)
        XCTAssertEqual(try Data(contentsOf: bundled), trackedBytes, "unsigned bundle must contain the committed artifact")
        let helpers = try FileManager.default.contentsOfDirectory(atPath: bundled.deletingLastPathComponent().path)
        XCTAssertEqual(helpers, ["FSDClassificationHostSeam"])
        let notices = try Data(contentsOf: app.appendingPathComponent("Contents/Resources/THIRD_PARTY_NOTICES.txt"))
        XCTAssertEqual(notices, try Data(contentsOf: repositoryRoot.appendingPathComponent("FSD/Helpers/THIRD_PARTY_NOTICES.txt")))
        let noticeText = String(decoding: notices, as: UTF8.self)
        for token in ["Tomas Aparicio", "The Go Authors", "Additional IP Rights Grant", "Sun Microsystems"] { XCTAssertTrue(noticeText.contains(token)) }
        let arch = try metadataTool("/usr/bin/lipo", ["-info", bundled.path])
        XCTAssertTrue(arch.contains("Non-fat")); XCTAssertTrue(arch.contains("arm64"))
        let build = try metadataTool("/usr/bin/xcrun", ["vtool", "-show-build", bundled.path])
        XCTAssertTrue(build.contains("minos 13.0"))
        let enumeration = try XCTUnwrap(FileManager.default.enumerator(at: app, includingPropertiesForKeys: nil))
        let forbiddenExtensions = Set(["go", "mod", "sum", "sqlite", "sqlite3", "db", "onnx", "tflite"])
        for case let url as URL in enumeration {
            XCTAssertFalse(forbiddenExtensions.contains(url.pathExtension.lowercased()), url.lastPathComponent)
            XCTAssertFalse(["gopath", "gomodcache", "gocache", "toolchain", "go-telemetry"].contains(url.lastPathComponent))
        }
    }
    func testDeliberatelyMissingHelperWithRealRunnerIsUnavailable() async throws {
        _ = try committedHelper()
        let missingRoot = FileManager.default.temporaryDirectory.appendingPathComponent("FSD-MissingBundle-\(UUID().uuidString).app")
        let provider = BundledFiletypeClassificationProvider(bundleRoot: missingRoot,
            makeRunner: { FoundationHelperProcessRunner() }, isExecutable: { FileManager.default.isExecutableFile(atPath: $0.path) })
        let result = await provider.classify(LocalClassificationRequest(boundedPrefix: Data())!)
        XCTAssertEqual(result, .unavailable)
    }
}

extension BundledFiletypeClassificationProviderTests {
    func testActualShippedBytesMatchCallCountsAtEveryGuardBoundary() throws {
        let helper = try committedHelper()
        let manifest = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: repositoryRoot.appendingPathComponent("FSD/Helpers/FSDClassificationHostSeam.manifest.json"))) as? [String: Any])
        let address = try XCTUnwrap(manifest["matchSymbolFileAddress"] as? String)
        let base = try XCTUnwrap(manifest["imageBaseFileAddress"] as? String)
        let helperSHA = SHA256.hash(data: try Data(contentsOf: helper)).map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(helperSHA, manifest["helperSHA256"] as? String, "symbol address belongs to these exact shipped bytes")
        let png = Data([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
        var cases: [(Data, Int)] = [(Data(), 1), (Data([0, 1, 2, 3]), 1), (png, 1),
            (png + Data(repeating: 0, count: 4096 - png.count), 1),
            (png + Data(repeating: 0, count: 4097 - png.count), 0)]
        for length in [4, 32, 513] { cases.append((Data([0xd0, 0xcf, 0x11, 0xe0]) + Data(repeating: 0, count: length - 4), 0)) }
        var long = Data([0xd0, 0xcf, 0x11, 0xe0]) + Data(repeating: 0, count: 510)
        long.replaceSubrange(512..<514, with: [UInt8(0xec), 0xa5]); cases.append((long, 1))
        let fixtureDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("FSD-MatchCount-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: fixtureDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: fixtureDirectory) }
        // Only generated public test patterns, never a user/classified-source sample.
        for (index, item) in cases.enumerated() {
            let input = fixtureDirectory.appendingPathComponent("synthetic-\(index)")
            try item.0.write(to: input)
            let relocation = "script target=lldb.debugger.GetSelectedTarget(); loaded=target.GetModuleAtIndex(0).GetObjectFileHeaderAddress().GetLoadAddress(target); target.BreakpointCreateByAddress(loaded+\(address)-\(base))"
            let output = try metadataTool("/usr/bin/xcrun", ["lldb", "--batch",
                "-o", "settings set target.disable-aslr false",
                "-o", "process launch --stop-at-entry -i \(input.path)", "-o", relocation,
                "-o", "breakpoint command add -s command -o continue 1", "-o", "continue", "-o", "breakpoint list", helper.path])
            XCTAssertTrue(output.contains("exited with status = 0"))
            XCTAssertTrue(output.contains("hit count = \(item.1)"), "actual Match-call count must respect guard and ceiling, case \(index)")
        }
    }
}
