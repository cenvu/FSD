import XCTest
@testable import FSD

/// The provider-facing contract: bounded immutable Data only, async,
/// cancellation-aware, six closed outcomes, no source capability of any kind.
final class ClassificationProviderContractTests: XCTestCase {
    private var directory: URL!
    private var source: URL!
    private var database: CatalogDatabase!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-ProviderContract-\(UUID().uuidString)", isDirectory: true)
        source = directory.appendingPathComponent("source", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        database = try CatalogDatabase(
            url: directory.appendingPathComponent("catalog.sqlite3"),
            schemaURL: CatalogSchemaFixture.canonicalSchemaURL
        )
    }

    override func tearDownWithError() throws {
        database?.close()
        database = nil
        try? FileManager.default.removeItem(at: directory)
        directory = nil
        source = nil
    }

    // MARK: - Request shape

    func testRequestHasExactlyOneStoredFieldAndItIsData() throws {
        let request = try XCTUnwrap(LocalClassificationRequest(boundedPrefix: Data([1, 2, 3])))
        let children = Mirror(reflecting: request).children.map { ($0.label ?? "?", type(of: $0.value)) }
        XCTAssertEqual(children.count, 1)
        XCTAssertEqual(children.first?.0, "data")
        XCTAssertTrue(children.first?.1 == Data.self)
        XCTAssertEqual(request.data, Data([1, 2, 3]))
    }

    func testRequestCannotExceedTheCeilingAndHasNoCallerBudget() throws {
        XCTAssertEqual(LocalClassificationRequest.maximumByteCount, 4096)
        XCTAssertNotNil(LocalClassificationRequest(boundedPrefix: Data(count: 4096)))
        XCTAssertNotNil(LocalClassificationRequest(boundedPrefix: Data()))
        XCTAssertNil(LocalClassificationRequest(boundedPrefix: Data(count: 4097)))
        XCTAssertNil(LocalClassificationRequest(boundedPrefix: Data(count: 1 << 20)))
    }

    func testRequestCopiesIntoIndependentStorage() throws {
        let backing = Data((0..<8192).map { UInt8($0 & 0xFF) })
        let slice = backing[100..<200]
        let request = try XCTUnwrap(LocalClassificationRequest(boundedPrefix: slice))
        XCTAssertEqual(request.data.count, 100)
        XCTAssertEqual(request.data.startIndex, 0, "a slice of a larger buffer is never retained or exposed")
        XCTAssertEqual(request.data, Data(slice))
    }

    // MARK: - Hostile provider

    func testHostileProviderCannotObtainPathURLHandleIdentityCallbackOrMoreBytes() async throws {
        let marker = "HOSTILE-MARKER-\(UUID().uuidString)"
        let bytes = Data((0..<9000).map { UInt8(truncatingIfNeeded: $0 &* 7) })
        try FileManager.default.createDirectory(at: source.appendingPathComponent(marker), withIntermediateDirectories: true)
        try bytes.write(to: source.appendingPathComponent("\(marker)/\(marker).bin"))
        let record = try SnapshotScanner(database: database).capture(root: source)
        let entryID = try XCTUnwrap(try database.scalar(
            "SELECT id FROM entries WHERE snapshot_id = ? AND name = ?",
            bindings: [.integer(record.id.rawValue), .text("\(marker).bin")]
        )?.int64Value)
        let mountPath = try XCTUnwrap(try database.scalar(
            "SELECT mount_path_at_capture FROM snapshots WHERE id = ?", bindings: [.integer(record.id.rawValue)]
        )?.stringValue)
        let volumeIdentifier = try XCTUnwrap(try database.scalar(
            "SELECT volume_identifier_at_capture FROM snapshots WHERE id = ?", bindings: [.integer(record.id.rawValue)]
        )?.stringValue)

        let outcome = try BoundedClassificationSourceReader(database: database).readPrefix(forEntryID: entryID)
        guard case let .prefix(request) = outcome else { return XCTFail("expected a bounded prefix, got \(outcome)") }

        let provider = HostileProvider()
        let result = await provider.classify(request)
        XCTAssertEqual(result, .failed)

        let inspected = provider.inspected
        XCTAssertEqual(inspected.storedFieldLabels, ["data"])
        XCTAssertEqual(inspected.byteCount, 4096)
        XCTAssertEqual(request.data, bytes.prefix(4096))
        XCTAssertFalse(inspected.sawURL)
        XCTAssertFalse(inspected.sawFunction)
        XCTAssertFalse(inspected.sawNonDataValue)
        XCTAssertEqual(inspected.leakedIdentifiers, [], "no path, mount, volume, snapshot or entry identity is reachable")
        XCTAssertFalse(inspected.rendered.contains(marker))
        XCTAssertFalse(inspected.rendered.contains(mountPath))
        XCTAssertFalse(inspected.rendered.contains(volumeIdentifier))
        XCTAssertFalse(inspected.rendered.contains(source.lastPathComponent))
        XCTAssertFalse(inspected.rendered.contains("entry"))
    }

    func testProviderProtocolIsAsyncAndCancellationAware() async {
        let provider: any LocalFileClassificationProvider = CooperativeProvider()
        let request = LocalClassificationRequest(boundedPrefix: Data([9]))!
        let normal = await provider.classify(request)
        XCTAssertEqual(normal, .classified(LocalClassificationObservation(detectedType: "fixture")))

        let task = Task { () -> LocalClassificationProviderResult in
            while !Task.isCancelled { await Task.yield() }
            return await provider.classify(request)
        }
        task.cancel()
        let cancelled = await task.value
        XCTAssertEqual(cancelled, .cancelled)
    }

    // MARK: - Disabled provider

    func testDisabledProviderIsSideEffectFreeAndReturnsUnavailable() async throws {
        let before = try directoryListing()
        let request = LocalClassificationRequest(boundedPrefix: Data([0, 1, 2]))!
        let provider = DisabledFileClassificationProvider()
        let first = await provider.classify(request)
        let second = await provider.classify(request)
        XCTAssertEqual(first, .unavailable)
        XCTAssertEqual(second, .unavailable)
        XCTAssertEqual(provider.providerIdentifier, "disabled")
        XCTAssertNil(provider.detectorVersion)
        XCTAssertNil(provider.modelVersion)
        XCTAssertEqual(try directoryListing(), before)
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
    }

    func testResultVocabularyIsExactlyTheSixLockedCases() {
        let observation = LocalClassificationObservation(detectedType: "x")
        let all: [LocalClassificationProviderResult] = [
            .classified(observation), .failed, .sourceChanged, .unsupportedEntry, .unavailable, .cancelled
        ]
        // No `default`: adding or removing a case breaks compilation here.
        let names = all.map { result -> String in
            switch result {
            case .classified: return "classified"
            case .failed: return "failed"
            case .sourceChanged: return "sourceChanged"
            case .unsupportedEntry: return "unsupportedEntry"
            case .unavailable: return "unavailable"
            case .cancelled: return "cancelled"
            }
        }
        XCTAssertEqual(names, ["classified", "failed", "sourceChanged", "unsupportedEntry", "unavailable", "cancelled"])
        XCTAssertEqual(Set(all).count, 6)
    }

    // MARK: - Supplementary source-text audit (text is the contract here)

    func testClassificationSourcesContainNoForbiddenAccessLoggingHashingOrPersistenceAPIs() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("FSD/Classification", isDirectory: true)
        let names = ["LocalFileClassificationProvider.swift", "BoundedClassificationSourceReader.swift"]
        let forbidden = [
            "Data(contentsOf", "contentsOfFile", "readToEnd", "readData(", "FileHandle", "InputStream", "NSData(",
            "mmap", "pread(", "fopen", "fread", "String(contentsOf",
            "resolvingSymlinksInPath", "realpath(", "destinationOfSymbolicLink", "standardizedFileURL",
            "NSLog", "print(", "os_log", "Logger(", "debugPrint", "dump(",
            "CryptoKit", "CommonCrypto", "SHA256", "SHA1", "CC_MD5", "Hasher(",
            "URLSession", "NWConnection", "Process(", "NSXPC",
            "INSERT INTO", "UPDATE ", "DELETE FROM", "UserDefaults", ".write(to"
        ]
        for name in names {
            let text = try String(contentsOf: root.appendingPathComponent(name), encoding: .utf8)
            for token in forbidden {
                XCTAssertFalse(text.contains(token), "\(name) must not contain \(token)")
            }
        }
        let provider = try String(contentsOf: root.appendingPathComponent(names[0]), encoding: .utf8)
        for token in ["import Darwin", "FileManager", "CatalogDatabase", "URL(", ": URL", "open(", "stat(", "read("] {
            XCTAssertFalse(provider.contains(token), "the provider contract must hold no source capability: \(token)")
        }
    }

    func testRepositoryFileHoldsPersistenceOnlyNoProviderOrSourceSeam() throws {
        let file = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("FSD/Catalog/EntryClassificationRepository.swift")
        let text = try String(contentsOf: file, encoding: .utf8)
        for token in ["sourceURL", "byteBudget", "ClassificationEnrichmentService", "LocalClassificationRequest",
                      "protocol LocalFileClassificationProvider", "DisabledFileClassificationProvider"] {
            XCTAssertFalse(text.contains(token), "persistence file must not carry \(token)")
        }
    }

    // MARK: - Helpers

    private func directoryListing() throws -> [String] {
        try FileManager.default.subpathsOfDirectory(atPath: directory.path).sorted()
    }
}

/// Fake hostile provider. Everything it can do is inspect the one request it is
/// given; there is no API on the request to reach a path, URL, handle,
/// identity, callback, resolver or additional byte range.
private final class HostileProvider: LocalFileClassificationProvider, @unchecked Sendable {
    struct Inspection {
        var storedFieldLabels: [String] = []
        var byteCount = 0
        var sawURL = false
        var sawFunction = false
        var sawNonDataValue = false
        var leakedIdentifiers: [String] = []
        var rendered = ""
    }

    let providerIdentifier = "hostile-test-provider"
    let detectorVersion: String? = nil
    let modelVersion: String? = nil
    private(set) var inspected = Inspection()

    func classify(_ request: LocalClassificationRequest) async -> LocalClassificationProviderResult {
        var inspection = Inspection()
        // Reflection is the broadest probe available: walk every stored value.
        for child in Mirror(reflecting: request).children {
            inspection.storedFieldLabels.append(child.label ?? "?")
            if child.value is URL { inspection.sawURL = true }
            if !(child.value is Data) { inspection.sawNonDataValue = true }
            if String(describing: type(of: child.value)).contains("->") { inspection.sawFunction = true }
        }
        inspection.byteCount = request.data.count
        inspection.rendered = String(reflecting: request) + String(describing: request) + String(describing: Mirror(reflecting: request).children)
        // "Ask for more bytes": there is nothing to call, and the Data itself
        // cannot be indexed past its bounded count.
        let beyond = request.data.count + 1
        if request.data.indices.contains(beyond) { inspection.leakedIdentifiers.append("extra-bytes") }
        inspected = inspection
        return .failed
    }
}

private struct CooperativeProvider: LocalFileClassificationProvider {
    let providerIdentifier = "cooperative-fixture"
    let detectorVersion: String? = nil
    let modelVersion: String? = nil

    func classify(_ request: LocalClassificationRequest) async -> LocalClassificationProviderResult {
        if Task.isCancelled { return .cancelled }
        return .classified(LocalClassificationObservation(detectedType: "fixture"))
    }
}
