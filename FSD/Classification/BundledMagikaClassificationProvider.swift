import Foundation
import Darwin

/// FSD's future bundled-helper HOST contract, not an upstream Magika API.
/// Construction is inert. Only classify launches, and only from the app bundle.
struct BundledMagikaClassificationProvider: LocalFileClassificationProvider, @unchecked Sendable {
    // Internal placeholder: no real helper, upstream filename or CLI is asserted.
    static let helperRelativePath = "Contents/Helpers/FSDClassificationHostSeam"
    static let stdoutCap = 4096
    static let stderrCap = 4096
    let providerIdentifier = "fsd.bundled-helper-host.v1"
    let detectorVersion: String? = nil
    let modelVersion: String? = nil
    private let bundleRoot: URL
    private let makeRunner: () -> any HelperProcessRunner
    private let resolve: (URL) -> URL?

    init() {
        self.init(bundleRoot: Bundle.main.bundleURL, makeRunner: { FoundationHelperProcessRunner() },
                  isExecutable: Self.isExecutable)
    }

    /// Internal dependency injection only. The provider request has Data alone.
    init(bundleRoot: URL, makeRunner: @escaping () -> any HelperProcessRunner,
         canonicalize: @escaping (URL) -> URL = { $0.resolvingSymlinksInPath().standardizedFileURL },
         isExecutable: @escaping (URL) -> Bool) {
        self.bundleRoot = bundleRoot
        self.makeRunner = makeRunner
        self.resolve = { Self.resolveExecutable(bundleRoot: $0, canonicalize: canonicalize, isExecutable: isExecutable) }
    }

    private static func isExecutable(_ url: URL) -> Bool {
        FileManager.default.isExecutableFile(atPath: url.path)
            && (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
    }

    static func resolveExecutable(bundleRoot: URL,
        canonicalize: (URL) -> URL = { $0.resolvingSymlinksInPath().standardizedFileURL },
        isExecutable: (URL) -> Bool = Self.isExecutable) -> URL? {
        let root = canonicalize(bundleRoot).standardizedFileURL
        let executable = canonicalize(root.appendingPathComponent(helperRelativePath)).standardizedFileURL
        guard root.isFileURL, executable.isFileURL,
              executable.path.hasPrefix(root.path + "/"), isExecutable(executable) else { return nil }
        return executable
    }

    func classify(_ request: LocalClassificationRequest) async -> LocalClassificationProviderResult {
        let cancellation = HelperCancellation()
        return await withTaskCancellationHandler(operation: {
            if Task.isCancelled { cancellation.cancel() }
            return await withCheckedContinuation { continuation in
                // Owned operation: continuation resumes only after cleanup/reap.
                // Blocking process work never occupies the cooperative executor.
                DispatchQueue.global(qos: .utility).async {
                    continuation.resume(returning: execute(request.data, cancellation: cancellation))
                }
            }
        }, onCancel: { cancellation.cancel() })
    }

    private func execute(_ input: Data, cancellation: HelperCancellation) -> LocalClassificationProviderResult {
        if cancellation.isCancelled { return cancellation.complete(.cancelled) }
        guard let executable = resolve(bundleRoot) else { return cancellation.complete(.unavailable) }
        let runner = makeRunner()
        // Runner construction launches nothing. This locked authorization,
        // rather than the later kernel launch, is the launch/cancel boundary.
        guard cancellation.authorizeLaunch() else { return cancellation.complete(.cancelled) }
        var output = Data()
        var stderrCount = 0
        var result: LocalClassificationProviderResult = .failed
        var exit: HelperProcessExit?
        do {
            try runner.launch(executable: executable)
            if cancellation.isCancelled {
                result = .cancelled
            } else {
                try runner.deliverInputOnce(input)
                runner.closeInput()
                while !cancellation.isCancelled {
                    let frame = try runner.poll(stdoutBudget: Self.stdoutCap - output.count,
                                                stderrBudget: Self.stderrCap - stderrCount, cancellation: cancellation)
                    if cancellation.isCancelled { result = .cancelled; break }
                    guard !frame.oversized, frame.stdout.count <= Self.stdoutCap - output.count,
                          frame.stderrCount >= 0, frame.stderrCount <= Self.stderrCap - stderrCount else { break }
                    output.append(frame.stdout)
                    stderrCount += frame.stderrCount
                    if frame.finished {
                        exit = runner.reap()
                        if exit?.status == 0, exit?.crashed == false {
                            result = HelperMetadataEnvelope.parse(output)
                        }
                        break
                    }
                }
            }
        } catch {
            // No raw process error or child diagnostic escapes this boundary.
            result = .failed
        }
        if exit == nil {
            // Also safe for failed launch: runner records whether a child exists.
            runner.terminate()
            runner.closePipes()
            _ = runner.reap()
        } else {
            runner.closePipes()
        }
        // The lock is the completion point. Cancellation before it wins; after
        // it, a completed deterministic outcome stays completed. No later check.
        return cancellation.complete(result)
    }
}

/// Only bounded stdout metadata and a stderr BYTE COUNT cross the runner seam.
/// Production emits at most 1024 stdout bytes and 1024 discarded stderr bytes
/// per poll. The driver enforces cumulative caps before appending anything.
struct HelperProcessFrame {
    let stdout: Data
    let stderrCount: Int
    let finished: Bool
    var oversized: Bool = false
}
struct HelperProcessExit { let status: Int32; let crashed: Bool }
protocol HelperProcessRunner: AnyObject {
    func launch(executable: URL) throws
    func deliverInputOnce(_ input: Data) throws
    func closeInput()
    func poll(stdoutBudget: Int, stderrBudget: Int, cancellation: HelperCancellation) throws -> HelperProcessFrame
    func terminate()
    func reap() -> HelperProcessExit
    func closePipes()
}

final class HelperCancellation: @unchecked Sendable {
    private let lock = NSCondition()
    private var cancelled = false
    private var completed = false
    private var launchAuthorized = false
    var isCancelled: Bool { lock.lock(); defer { lock.unlock() }; return cancelled }
    func authorizeLaunch() -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard !cancelled, !completed, !launchAuthorized else { return false }
        launchAuthorized = true
        // No process work under this lock; later cancellation may still win
        // completion and the owned operation must clean up any launched child.
        return true
    }
    func cancel() {
        lock.lock(); defer { lock.unlock() }
        if !completed { cancelled = true; lock.broadcast() }
    }
    /// Internal deterministic synchronization for runner fixtures.
    func waitUntilCancelled() {
        lock.lock(); defer { lock.unlock() }
        while !cancelled && !completed { lock.wait() }
    }
    func complete(_ result: LocalClassificationProviderResult) -> LocalClassificationProviderResult {
        lock.lock(); defer { lock.unlock() }
        completed = true
        lock.broadcast()
        return cancelled ? .cancelled : result
    }
}

private enum HelperProcessFault: Error { case io }

/// All methods execute on the single owned worker operation. No readability
/// handlers, background children or competing close/read/write callbacks.
private final class FoundationHelperProcessRunner: HelperProcessRunner {
    private let process = Process()
    private let input = Pipe()
    private let output = Pipe()
    private let error = Pipe()
    private var launched = false
    private var delivered = false
    private var inputClosed = false
    private var allClosed = false
    private var exit: HelperProcessExit?
    private lazy var pump = HelperPipePump(stdout: output.fileHandleForReading, stderr: error.fileHandleForReading)

    func launch(executable: URL) throws {
        process.executableURL = executable
        process.arguments = []
        process.environment = [:]
        process.standardInput = input
        process.standardOutput = output
        process.standardError = error
        // Nonblocking descriptors prevent a child from withholding reads or
        // flooding one channel while the parent services the other.
        try pump.configure()
        for handle in [input.fileHandleForWriting] {
            let fd = handle.fileDescriptor
            let flags = fcntl(fd, F_GETFL)
            guard flags >= 0, fcntl(fd, F_SETFL, flags | O_NONBLOCK) == 0 else { throw HelperProcessFault.io }
        }
        guard fcntl(input.fileHandleForWriting.fileDescriptor, F_SETNOSIGPIPE, 1) == 0 else { throw HelperProcessFault.io }
        try process.run()
        launched = true
        // Parent must not retain child ends and accidentally prevent EOF.
        try? input.fileHandleForReading.close()
        try? output.fileHandleForWriting.close()
        try? error.fileHandleForWriting.close()
    }

    func deliverInputOnce(_ bytes: Data) throws {
        guard launched, !delivered, bytes.count <= LocalClassificationRequest.maximumByteCount else { throw HelperProcessFault.io }
        delivered = true
        // Exactly one raw write, including an empty request. A short write,
        // EINTR or EAGAIN fails closed; never request/retry a second payload.
        let written = bytes.withUnsafeBytes { buffer in
            Darwin.write(input.fileHandleForWriting.fileDescriptor, buffer.baseAddress, buffer.count)
        }
        guard written == bytes.count else { throw HelperProcessFault.io }
    }

    func closeInput() {
        if !inputClosed { try? input.fileHandleForWriting.close(); inputClosed = true }
    }

    func poll(stdoutBudget: Int, stderrBudget: Int, cancellation: HelperCancellation) throws -> HelperProcessFrame {
        try pump.poll(stdoutBudget: stdoutBudget, stderrBudget: stderrBudget, stopped: !process.isRunning)
    }

    func terminate() {
        guard launched, process.isRunning else { return }
        process.terminate()
        // SIGTERM may be ignored. Immediate forced termination is cancellation
        // cleanup, not a runtime timeout policy. No new process is spawned.
        if process.isRunning { _ = Darwin.kill(process.processIdentifier, SIGKILL) }
    }

    func reap() -> HelperProcessExit {
        if let exit { return exit }
        guard launched else { return HelperProcessExit(status: -1, crashed: false) }
        // Normal: both pipes drained and child already exited. Error/cancel:
        // forced termination and pipes closed first, so no full-pipe wait cycle.
        process.waitUntilExit()
        let result = HelperProcessExit(status: process.terminationStatus, crashed: process.terminationReason == .uncaughtSignal)
        exit = result
        return result
    }

    func closePipes() {
        guard !allClosed else { return }
        closeInput()
        pump.close()
        try? input.fileHandleForReading.close()
        try? output.fileHandleForWriting.close()
        try? error.fileHandleForWriting.close()
        allClosed = true
    }
}

/// Shared production pipe pump, testable using local pipes without any child or
/// executable. Memory and drained byte limits apply before each system read.
final class HelperPipePump {
    // macOS SDK sys/filio.h: FIONREAD = _IOR('f', 127, int).
    // The function-like _IOR macro is not imported by Swift. Encoding follows
    // sys/ioccom.h exactly (IOC_OUT | sizeof(int)<<16 | 'f'<<8 | 127).
    private static let queuedByteCountRequest: UInt = 0x40000000 | (UInt(MemoryLayout<Int32>.size) << 16) | (0x66 << 8) | 127
    private let stdout: FileHandle
    private let stderr: FileHandle
    private var outputClosed = false
    private var errorClosed = false
    init(stdout: FileHandle, stderr: FileHandle) { self.stdout = stdout; self.stderr = stderr }
    func configure() throws {
        for handle in [stdout, stderr] {
            let flags = fcntl(handle.fileDescriptor, F_GETFL)
            guard flags >= 0, fcntl(handle.fileDescriptor, F_SETFL, flags | O_NONBLOCK) == 0 else { throw HelperProcessFault.io }
        }
    }
    func poll(stdoutBudget: Int, stderrBudget: Int, stopped: Bool) throws -> HelperProcessFrame {
        guard (0...4096).contains(stdoutBudget), (0...4096).contains(stderrBudget) else { throw HelperProcessFault.io }
        var descriptors = [
            pollfd(fd: outputClosed ? -1 : stdout.fileDescriptor, events: Int16(POLLIN), revents: 0),
            pollfd(fd: errorClosed ? -1 : stderr.fileDescriptor, events: Int16(POLLIN), revents: 0)
        ]
        // 20ms is an I/O/cancellation servicing interval, never a runtime deadline.
        let polled = Darwin.poll(&descriptors, nfds_t(descriptors.count), 20)
        if polled < 0, errno != EINTR { throw HelperProcessFault.io }
        var stdoutBytes = Data()
        var stderrCount = 0
        var oversized = false
        // One bounded nonblocking read from EACH channel on EVERY iteration.
        // No channel can monopolize draining; no waitUntilExit precedes relief.
        for index in 0..<2 {
            if descriptors[index].fd < 0 { continue }
            let budget = index == 0 ? stdoutBudget : stderrBudget
            if budget == 0 {
                // Inspect queued byte COUNT without consuming beyond the cap.
                // EOF readiness alone is not evidence of oversized output.
                var pending: Int32 = 0
                guard ioctl(descriptors[index].fd, Self.queuedByteCountRequest, &pending) == 0 else { throw HelperProcessFault.io }
                if pending > 0 { oversized = true }
                else if stopped || descriptors[index].revents & Int16(POLLHUP) != 0 {
                    if index == 0 { try? stdout.close(); outputClosed = true }
                    else { try? stderr.close(); errorClosed = true }
                }
                continue
            }
            var scratch = [UInt8](repeating: 0, count: min(1024, budget))
            let count = scratch.withUnsafeMutableBytes { Darwin.read(descriptors[index].fd, $0.baseAddress, $0.count) }
            if count > 0 {
                if index == 0 { stdoutBytes = Data(scratch.prefix(count)) }
                else { stderrCount = count } // stderr scratch is discarded here.
            } else if count == 0 || (stopped && count < 0 && errno == EAGAIN) {
                // After child exit drain available bytes, then close even if an
                // inherited descriptor could otherwise hold EOF open forever.
                if index == 0 { try? stdout.close(); outputClosed = true }
                else { try? stderr.close(); errorClosed = true }
            } else if errno != EAGAIN && errno != EINTR {
                throw HelperProcessFault.io
            }
        }
        return HelperProcessFrame(stdout: stdoutBytes, stderrCount: stderrCount, finished: stopped && outputClosed && errorClosed, oversized: oversized)
    }
    func close() {
        if !outputClosed { try? stdout.close(); outputClosed = true }
        if !errorClosed { try? stderr.close(); errorClosed = true }
    }
}

/// Strict, flat, seven-field JSON host envelope. All keys occur exactly once;
/// extra keys, nested values, duplicates and trailing content fail. Text fields
/// are null or 1...256 UTF-8 bytes without control characters; classified needs
/// detectedType. Nonclassified kinds require all five metadata fields null.
/// Schema is the exact integer token 1. Confidence is null or finite 0...1.
private struct HelperMetadataEnvelope {
    private enum Scalar { case string(String), number(String), null }
    private var bytes: [UInt8]
    private var index = 0

    static func parse(_ data: Data) -> LocalClassificationProviderResult {
        guard data.count <= BundledMagikaClassificationProvider.stdoutCap else { return .failed }
        var parser = Self(bytes: Array(data))
        guard let fields = parser.object(), fields.count == 7,
              case .number("1")? = fields["schemaVersion"],
              case let .string(kind)? = fields["resultKind"],
              ["classified", "no_match", "unavailable", "failed"].contains(kind) else { return .failed }
        let names = ["detectedType", "mimeType", "detectorVersion", "modelVersion"]
        var text: [String: String] = [:]
        for name in names {
            guard let value = fields[name] else { return .failed }
            switch value {
            case .null: break
            case let .string(string):
                guard !string.isEmpty, string.utf8.count <= 256,
                      !string.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else { return .failed }
                text[name] = string
            default: return .failed
            }
        }
        var confidence: Double?
        switch fields["confidence"] {
        case .null?: break
        case let .number(token)?:
            guard let value = try? JSONDecoder().decode(Double.self, from: Data(token.utf8)),
                  value.isFinite, (0...1).contains(value) else { return .failed }
            confidence = value
        default: return .failed
        }
        if kind != "classified" {
            guard text.isEmpty, confidence == nil else { return .failed }
            if kind == "no_match" { return .noMatch }
            return kind == "unavailable" ? .unavailable : .failed
        }
        guard let detectedType = text["detectedType"] else { return .failed }
        return .classified(LocalClassificationObservation(detectedType: detectedType, mimeType: text["mimeType"],
            confidence: confidence, detectorVersion: text["detectorVersion"], modelVersion: text["modelVersion"]))
    }

    private mutating func whitespace() {
        while index < bytes.count, [UInt8(32), 9, 10, 13].contains(bytes[index]) { index += 1 }
    }
    private mutating func consume(_ byte: UInt8) -> Bool {
        whitespace()
        guard index < bytes.count, bytes[index] == byte else { return false }
        index += 1; return true
    }
    private mutating func string() -> String? {
        whitespace()
        let start = index
        guard index < bytes.count, bytes[index] == 34 else { return nil }
        index += 1
        while index < bytes.count {
            let byte = bytes[index]; index += 1
            if byte == 92 { index += 1 }
            else if byte == 34 {
                return try? JSONDecoder().decode(String.self, from: Data(bytes[start..<index]))
            }
        }
        return nil
    }
    private mutating func scalar() -> Scalar? {
        whitespace()
        guard index < bytes.count else { return nil }
        if bytes[index] == 34 { return string().map { .string($0) } }
        let start = index
        while index < bytes.count, ![UInt8(44), 125, 32, 9, 10, 13].contains(bytes[index]) { index += 1 }
        let token = String(decoding: bytes[start..<index], as: UTF8.self)
        if token == "null" { return .null }
        guard let first = token.utf8.first, first == 45 || (48...57).contains(first),
              (try? JSONDecoder().decode(Double.self, from: Data(token.utf8))) != nil else { return nil }
        return .number(token)
    }
    private mutating func object() -> [String: Scalar]? {
        guard consume(123) else { return nil }
        var fields: [String: Scalar] = [:]
        repeat {
            guard fields.count < 7, let key = string(), fields[key] == nil,
                  consume(58), let value = scalar() else { return nil }
            fields[key] = value
            if consume(125) { whitespace(); return index == bytes.count ? fields : nil }
        } while consume(44)
        return nil
    }
}
