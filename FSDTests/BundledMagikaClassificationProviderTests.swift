import XCTest
@testable import FSD

final class BundledMagikaClassificationProviderTests: XCTestCase {
    private let valid = Data(#"{"schemaVersion":1,"resultKind":"classified","detectedType":"fixture","mimeType":"application/x-fixture","confidence":0.75,"detectorVersion":"detector-fixture","modelVersion":"model-fixture"}"#.utf8)
    private let root = URL(fileURLWithPath: "/Fixture/FSD.app")

    private func classify(_ output: Data, input: Data = Data(), status: Int32 = 0,
                          crash: Bool = false, stderr: Int = 0) async -> (LocalClassificationProviderResult, FakeHelperRunner) {
        let runner = FakeHelperRunner(frames: [HelperProcessFrame(stdout: output, stderrCount: stderr, finished: true)],
                                      exit: HelperProcessExit(status: status, crashed: crash))
        let provider = BundledMagikaClassificationProvider(bundleRoot: root, makeRunner: { runner }, canonicalize: { $0 }, isExecutable: { _ in true })
        let result = await provider.classify(LocalClassificationRequest(boundedPrefix: input)!)
        return (result, runner)
    }

    func testRawInputEmptyMaximumAndExactlyOneClosedDelivery() async {
        for input in [Data(), Data([0, 255, 10, 13, 34, 92]), Data((0..<4096).map { UInt8(truncatingIfNeeded: $0) })] {
            let (result, runner) = await classify(valid, input: input)
            guard case .classified = result else { return XCTFail("valid envelope rejected") }
            XCTAssertEqual(runner.deliveries, [input])
            XCTAssertEqual(runner.events, ["launch", "deliver", "closeInput", "poll", "reap", "closePipes"])
            XCTAssertEqual(runner.launchedURL, root.appendingPathComponent(BundledMagikaClassificationProvider.helperRelativePath))
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
        let expected = root.appendingPathComponent(BundledMagikaClassificationProvider.helperRelativePath)
        var inspected: [URL] = []
        let resolved = BundledMagikaClassificationProvider.resolveExecutable(bundleRoot: root,
            canonicalize: { $0.standardizedFileURL }, isExecutable: { inspected.append($0); return true })
        XCTAssertEqual(resolved, expected)
        XCTAssertEqual(inspected, [expected])
        for escape in [URL(fileURLWithPath: "/outside/helper"), URL(fileURLWithPath: "/Fixture/FSD.app-evil/helper")] {
            XCTAssertNil(BundledMagikaClassificationProvider.resolveExecutable(bundleRoot: root,
                canonicalize: { $0 == root ? root : escape }, isExecutable: { _ in XCTFail("outside executable inspected"); return true }))
        }
        XCTAssertNil(BundledMagikaClassificationProvider.resolveExecutable(bundleRoot: root,
            canonicalize: { $0 }, isExecutable: { _ in false }))
    }

    func testPhysicalMissingNonExecutableDirectoryAndSymlinkResolution() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("FSD-AdapterResolution-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let bundle = directory.appendingPathComponent("FSD.app")
        let helper = bundle.appendingPathComponent(BundledMagikaClassificationProvider.helperRelativePath)
        try FileManager.default.createDirectory(at: helper.deletingLastPathComponent(), withIntermediateDirectories: true)
        XCTAssertNil(BundledMagikaClassificationProvider.resolveExecutable(bundleRoot: bundle))
        // Empty permission fixture only; never a runnable helper or input sample.
        XCTAssertTrue(FileManager.default.createFile(atPath: helper.path, contents: nil, attributes: [.posixPermissions: 0o600]))
        XCTAssertNil(BundledMagikaClassificationProvider.resolveExecutable(bundleRoot: bundle))
        try FileManager.default.removeItem(at: helper)
        try FileManager.default.createDirectory(at: helper, withIntermediateDirectories: false)
        XCTAssertNil(BundledMagikaClassificationProvider.resolveExecutable(bundleRoot: bundle))
        try FileManager.default.removeItem(at: helper)
        let outside = directory.appendingPathComponent("outside")
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: false)
        try FileManager.default.createSymbolicLink(at: helper, withDestinationURL: outside)
        XCTAssertNil(BundledMagikaClassificationProvider.resolveExecutable(bundleRoot: bundle,
            isExecutable: { _ in XCTFail("escaped path reached permission check"); return true }))
    }

    func testMissingAndNonExecutableHelpersAreUnavailableAndNeverLaunch() async {
        for _ in ["missing", "nonExecutable"] {
            let runner = FakeHelperRunner(frames: [])
            let provider = BundledMagikaClassificationProvider(bundleRoot: root, makeRunner: { runner }, canonicalize: { $0 }, isExecutable: { _ in false })
            let result = await provider.classify(LocalClassificationRequest(boundedPrefix: Data())!)
            XCTAssertEqual(result, .unavailable)
            XCTAssertTrue(runner.events.isEmpty)
        }
    }

    func testClassifiedEnvelopeAndIndependentHostProvenance() async {
        let (result, _) = await classify(valid)
        XCTAssertEqual(result, .classified(LocalClassificationObservation(detectedType: "fixture", mimeType: "application/x-fixture",
            confidence: 0.75, detectorVersion: "detector-fixture", modelVersion: "model-fixture")))
        let provider = BundledMagikaClassificationProvider()
        XCTAssertEqual(provider.providerIdentifier, "fsd.bundled-helper-host.v1")
        XCTAssertNil(provider.detectorVersion)
        XCTAssertNil(provider.modelVersion)
        let overridden = String(decoding: valid, as: UTF8.self).replacingOccurrences(of: "}", with: ",\"providerIdentifier\":\"hostile\"}")
        let (rejected, _) = await classify(Data(overridden.utf8))
        XCTAssertEqual(rejected, .failed)
        XCTAssertEqual(provider.providerIdentifier, "fsd.bundled-helper-host.v1")
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
        let provider = BundledMagikaClassificationProvider(bundleRoot: root, makeRunner: { runner }, canonicalize: { $0 }, isExecutable: { _ in true })
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
        let capped = BundledMagikaClassificationProvider(bundleRoot: root, makeRunner: { accumulated }, canonicalize: { $0 }, isExecutable: { _ in true })
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
            let provider = BundledMagikaClassificationProvider(bundleRoot: root, makeRunner: { runner }, canonicalize: { $0 }, isExecutable: { _ in true })
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
        let provider = BundledMagikaClassificationProvider(bundleRoot: root, makeRunner: { runner }, canonicalize: { $0 }, isExecutable: { _ in true })
        let task = Task { await provider.classify(LocalClassificationRequest(boundedPrefix: Data([9]))!) }
        await fulfillment(of: [active], timeout: 5)
        task.cancel()
        let result = await task.value
        XCTAssertEqual(result, .cancelled)
        XCTAssertTrue(runner.terminated)
        XCTAssertTrue(runner.reaped)
        XCTAssertTrue(runner.pipesClosed)
    }

    func testCancellationBeforeLaunchAndCompletionOrdering() async {
        let runner = FakeHelperRunner(frames: [])
        let provider = BundledMagikaClassificationProvider(bundleRoot: root, makeRunner: { runner }, canonicalize: { $0 }, isExecutable: { _ in true })
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
        let cancelFirst = HelperCancellation()
        cancelFirst.cancel()
        XCTAssertEqual(cancelFirst.complete(.unavailable), .cancelled)
    }

    func testConstructionAndDisabledProviderAreInert() async {
        var creations = 0
        let provider = BundledMagikaClassificationProvider(bundleRoot: root, makeRunner: {
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
            .appendingPathComponent("FSD/Classification/BundledMagikaClassificationProvider.swift")
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
         fault: String? = nil, onPoll: ((HelperCancellation) -> Void)? = nil) {
        self.frames = frames; self.exit = exit; self.fault = fault; self.onPoll = onPoll
    }
    private func record(_ event: String) throws {
        events.append(event)
        if fault == event { throw NSError(domain: "fixture", code: 1) }
    }
    func launch(executable: URL) throws { try record("launch"); launchedURL = executable }
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
