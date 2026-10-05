import XCTest
@testable import FSD

/// P15 Slice 06 — `docs/TEST_PLAN.md` §9 adversarial provider, persistence,
/// immutability, offline and host-network coverage.
///
/// Everything here drives the **production** runtime path
/// (`ClassificationRuntimeService.start(entryID:database:provider:)`), the real
/// `BoundedClassificationSourceReader` and the real
/// `EntryClassificationRepository` over a real captured snapshot. The only
/// substituted actor is the provider itself, which is the exact seam §9 asks to
/// attack. No production file is modified, and no hostile behaviour is enabled
/// by a new production capability: the fake receives only
/// `LocalClassificationRequest.data`.
final class ClassificationSecurityIntegrationTests: XCTestCase {
    private let runtime = ClassificationRuntimeService.shared
    private var directory: URL!
    private var source: URL!
    private var database: CatalogDatabase!
    private var snapshotID: SnapshotID!
    private var entryID: Int64!
    private var sourceBytes: Data!
    private var sourcePath: String!

    override func setUp() async throws {
        await runtime.cancel()
        await runtime.waitForCleanup()
        try await super.setUp()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-Slice06-Security-\(UUID().uuidString)", isDirectory: true)
        source = directory.appendingPathComponent("source", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        database = try CatalogDatabase(
            url: directory.appendingPathComponent("catalog.sqlite3"),
            schemaURL: CatalogSchemaFixture.canonicalSchemaURL
        )
        // Larger than the ceiling, with a recognisable byte pattern so any leak
        // of sampled bytes into the catalog would be visible.
        sourceBytes = Data((0..<9000).map { UInt8(truncatingIfNeeded: ($0 &* 37) &+ 11) })
        let file = source.appendingPathComponent("hostile-target.bin")
        try sourceBytes.write(to: file)
        sourcePath = file.path
        let captured = try SnapshotScanner(database: database).capture(root: source)
        snapshotID = captured.id
        entryID = try XCTUnwrap(try database.scalar(
            "SELECT id FROM entries WHERE snapshot_id = ? AND relative_path = 'hostile-target.bin'",
            bindings: [.integer(captured.id.rawValue)]
        )?.int64Value)
    }

    override func tearDown() async throws {
        await runtime.cancel()
        await runtime.waitForCleanup()
        database?.close()
        database = nil
        try? FileManager.default.removeItem(at: directory)
        directory = nil
        source = nil
        snapshotID = nil
        entryID = nil
        sourceBytes = nil
        sourcePath = nil
        try await super.tearDown()
    }

    // MARK: - Helpers

    /// Runs the real production classification path once with `provider`.
    private func runProduction(_ provider: any LocalFileClassificationProvider) async -> ClassificationRuntimeService.StartResult {
        let started = await runtime.start(entryID: entryID, database: database, provider: provider)
        await runtime.waitForCleanup()
        return started
    }

    private func outcome(of result: ClassificationRuntimeService.StartResult) -> LocalClassificationProviderResult? {
        guard case let .completed(completion) = result else { return nil }
        guard case let .classification(outcome, _) = completion.result else { return nil }
        return outcome
    }

    /// One persisted classification row split into its stored text values and
    /// the columns that are genuinely SQL NULL, so a NULL is never confused with
    /// an empty string.
    private func persistedRow() throws -> (text: [String: String], nullColumns: Set<String>) {
        let row = try XCTUnwrap(try database.query(
            "SELECT * FROM entry_classifications WHERE entry_id = ?", bindings: [.integer(entryID)]
        ).first)
        var text: [String: String] = [:]
        var nullColumns: Set<String> = []
        for column in row.keys.sorted() {
            if let value = row[column]?.stringValue { text[column] = value } else { nullColumns.insert(column) }
        }
        return (text, nullColumns)
    }

    private func schemaColumnNames() throws -> [String] {
        try database.query("PRAGMA table_info('entry_classifications')")
            .compactMap { $0["name"]?.stringValue }
    }

    // MARK: - A. Original source authority

    func testAdversarialProviderCannotReachOriginalSourceAuthority() async throws {
        let provider = HostileSecurityProvider()
        let result = await runProduction(provider)
        XCTAssertEqual(outcome(of: result), .classified(provider.claim))
        let seen = try XCTUnwrap(provider.inspected)

        // The provider's entire visible request surface is one bounded Data.
        XCTAssertEqual(seen.storedFieldLabels, ["data"], "no second field can carry a path, URL or identity")
        XCTAssertNil(seen.sawURL)
        XCTAssertNil(seen.sawString)
        XCTAssertNil(seen.sawFunction)
        XCTAssertNil(seen.sawHandle)
        XCTAssertEqual(seen.attemptedPathRecovery.count, 0, "the provider found no path to recover")
        let leaks: [String] = [sourcePath, source.path, directory.path, "hostile-target.bin",
                                snapshotID.rawValue.description, entryID.description, "mount_path_at_capture"]
        for leak in leaks {
            XCTAssertFalse(seen.rendered.contains(leak), "provider-visible surface leaked \(leak)")
        }

        // Even a successful classification persists no path.
        let row = try persistedRow()
        XCTAssertEqual(row.text["detection_status"], "classified")
        XCTAssertEqual(row.text["provider_identifier"], HostileSecurityProvider.identifier)
        for (column, value) in row.text {
            XCTAssertFalse(value.contains(sourcePath), "column \(column) persisted the absolute source path")
            XCTAssertFalse(value.contains(source.path), "column \(column) persisted the source directory")
            XCTAssertFalse(value.contains(directory.path), "column \(column) persisted a test-owned absolute path")
        }
    }

    // MARK: - B. Additional byte request

    func testAdversarialProviderHasNoAdditionalByteRequestAPI() async throws {
        let provider = HostileSecurityProvider()
        let result = await runProduction(provider)
        XCTAssertEqual(outcome(of: result), .classified(provider.claim))
        let seen = try XCTUnwrap(provider.inspected)

        // The request exposes no callback, reader, range or resolver of any kind.
        XCTAssertTrue(seen.requestMembers.isEmpty, "the bounded request exposes no member beyond `data`")
        XCTAssertEqual(seen.attemptedExtraByteReads, 0, "no second read, range or callback exists to invoke")
        XCTAssertEqual(seen.attemptedSourceReopens, 0, "no source reopen path exists")
        XCTAssertFalse(seen.rendered.contains("->"), "no function-typed capability is reachable from the request")
        XCTAssertEqual(seen.receivedByteCount, 4096)
    }

    // MARK: - C. Ceiling bypass

    func testAdversarialProviderCannotBypassFSDByteCeiling() async throws {
        let before = try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: snapshotID)
        let beforeSnapshot = try EntrySnapshotProbe.snapshotFingerprint(database: database, snapshotID: snapshotID)
        let beforeRows = try EntrySnapshotProbe.classificationRowCount(database: database)

        let provider = HostileSecurityProvider()
        let result = await runProduction(provider)
        XCTAssertEqual(outcome(of: result), .classified(provider.claim))
        let seen = try XCTUnwrap(provider.inspected)

        // FSD's own read authority is the ceiling, whatever the provider claims.
        XCTAssertEqual(seen.receivedByteCount, 4096, "FSD_SOURCE_BYTES_READ_FOR_PROVIDER must be exactly 4096")
        XCTAssertLessThanOrEqual(seen.receivedByteCount, LocalClassificationRequest.maximumByteCount)
        XCTAssertEqual(seen.receivedBytes, sourceBytes.prefix(4096), "REQUEST_DATA_COUNT is FSD's prefix, in order")
        XCTAssertNotEqual(seen.receivedBytes, sourceBytes, "the provider never received the whole oversized source")
        XCTAssertEqual(provider.claimedByteCount, 1 << 22, "the provider really did claim a far larger read")
        XCTAssertEqual(provider.oversizedBuffer.count, 1 << 22, "the provider allocated its own larger buffer")
        XCTAssertNil(LocalClassificationRequest(boundedPrefix: provider.oversizedBuffer),
                     "even a hostile buffer cannot become a request")

        // The provider's claims reach metadata only. Nothing about them can
        // create a second source read, sample bytes, a path or a bigger ceiling.
        XCTAssertEqual(seen.attemptedExtraByteReads, 0)
        XCTAssertEqual(seen.attemptedSourceReopens, 0)
        let row = try persistedRow()
        XCTAssertEqual(row.text["detection_status"], "classified")
        XCTAssertEqual(row.text["detected_type"], provider.claim.detectedType)
        XCTAssertNotEqual(try EntrySnapshotProbe.classificationRowCount(database: database), beforeRows + 2,
                          "one admitted run writes exactly one row")
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), beforeRows + 1)
        XCTAssertEqual(try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: snapshotID), before,
                       "immutable entry facts are untouched by a hostile provider")
        XCTAssertEqual(try EntrySnapshotProbe.snapshotFingerprint(database: database, snapshotID: snapshotID), beforeSnapshot)
        XCTAssertEqual(LocalClassificationRequest.maximumByteCount, 4096, "the prefix ceiling is FSD-owned and unchanged")
    }

    // MARK: - Persistence: no payload, sample, hash or absolute path

    func testNoPayloadByteSampleContentHashOrAbsolutePathIsPersisted() async throws {
        // Schema boundary: there is no column that could hold any of these.
        let columns = try schemaColumnNames()
        XCTAssertEqual(columns, [
            "id", "entry_id", "classification_run_id", "detected_type", "mime_type", "confidence",
            "detection_status", "detector_version", "model_version", "classified_at", "created_at",
            "provider_identifier"
        ])
        for forbidden in ["payload", "bytes", "sample", "prefix", "content", "hash", "sha", "checksum",
                          "digest", "path", "url", "source", "offset", "length"] {
            XCTAssertFalse(columns.contains { $0.contains(forbidden) },
                           "entry_classifications must not grow a \(forbidden) column")
        }
        XCTAssertEqual(columns.last, "provider_identifier", "v9 provider_identifier stays appended last")

        // Observed values, after a hostile provider ran and succeeded.
        let provider = HostileSecurityProvider()
        let started = await runProduction(provider)
        XCTAssertEqual(outcome(of: started), .classified(provider.claim))
        let row = try persistedRow()
        let sampledPrefix = sourceBytes.prefix(4096)
        let providerBytes = Data(provider.oversizedBuffer.prefix(512))
        var joinedValues = ""
        for value in row.text.values { joinedValues += value + "\u{1}" }

        XCTAssertFalse(joinedValues.contains(sourcePath), "no absolute source path may be persisted")
        XCTAssertFalse(joinedValues.contains(source.path))
        XCTAssertFalse(joinedValues.contains(directory.path))
        // A hex or base64 rendering of any sampled byte run is equally forbidden.
        XCTAssertFalse(joinedValues.contains(sampledPrefix.prefix(64).map { String(format: "%02x", $0) }.joined()),
                       "no hex rendering of the sampled prefix may be persisted")
        XCTAssertFalse(joinedValues.contains(providerBytes.prefix(64).map { String(format: "%02x", $0) }.joined()),
                       "no rendering of provider-allocated bytes may be persisted")
        let verbatimSample = String(decoding: sampledPrefix.prefix(32), as: UTF8.self)
        XCTAssertFalse(verbatimSample.isEmpty)
        XCTAssertFalse(joinedValues.contains(verbatimSample), "no verbatim sample bytes may be persisted")
        for forbidden in ["payload", "sha256", "SHA256", "checksum", "md5", "digest", provider.sourceClaim] {
            XCTAssertFalse(joinedValues.contains(forbidden), "no \(forbidden) may reach a persisted value")
        }
    }

    func testHostileProviderDiagnosticsAreNeverPersistedOrReturned() async throws {
        let provider = HostileSecurityProvider()
        let result = await runProduction(provider)
        XCTAssertEqual(outcome(of: result), .classified(provider.claim))

        let row = try persistedRow()
        let persisted = row.text.values.joined(separator: "\u{1}")
        let secrets: [String] = [provider.sourceClaim, provider.diagnostic, sourcePath, source.path]
        for secret in secrets {
            XCTAssertFalse(persisted.contains(secret), "hostile diagnostic text must not be persisted")
        }
        let rendered = String(describing: result)
        XCTAssertFalse(rendered.contains(provider.sourceClaim))
        XCTAssertFalse(rendered.contains(provider.diagnostic))
        XCTAssertFalse(rendered.contains(sourcePath))
        let state = await runtime.state
        XCTAssertFalse(String(describing: state).contains(provider.diagnostic))
    }

    // MARK: - Snapshot immutability through the real runtime

    func testClassificationWritesNeverMutateEntryOrSnapshotFacts() async throws {
        let entriesBefore = try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: snapshotID)
        let snapshotBefore = try EntrySnapshotProbe.snapshotFingerprint(database: database, snapshotID: snapshotID)

        // Successful classification.
        let success = HostileSecurityProvider()
        let successStarted = await runProduction(success)
        XCTAssertEqual(outcome(of: successStarted), .classified(success.claim))
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 1)

        // Failed classification: a provider that crashes instead of classifying.
        let failure = HostileSecurityProvider(result: .failed)
        let failureStarted = await runProduction(failure)
        XCTAssertEqual(outcome(of: failureStarted), .failed)

        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 2,
                       "one classified row and one failed row, appended independently")
        XCTAssertEqual(try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: snapshotID), entriesBefore)
        XCTAssertEqual(try EntrySnapshotProbe.snapshotFingerprint(database: database, snapshotID: snapshotID), snapshotBefore)
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)

        let repository = EntryClassificationRepository(database: database)
        let history = try repository.history(for: entryID)
        XCTAssertEqual(history.count, 2, "append-only history, no update and no repair of the first row")
        // `history(for:)` is newest-first (ORDER BY id DESC): append-only, never
        // an update of the earlier row.
        XCTAssertEqual(try repository.history(for: entryID).map(\.detectionStatus),
                       [.failed, .classified])
    }

    // MARK: - Detached source, offline usability

    func testDetachedSourceYieldsLockedOutcomeAndKeepsSnapshotBrowsable() async throws {
        let entriesBefore = try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: snapshotID)
        let snapshotBefore = try EntrySnapshotProbe.snapshotFingerprint(database: database, snapshotID: snapshotID)

        // The source is detached after capture: the recorded volume identity no
        // longer resolves, which is the locked `.sourceChanged`/`.unavailable`
        // rule, never a crash and never a hang.
        try FileManager.default.removeItem(at: source)
        XCTAssertFalse(FileManager.default.fileExists(atPath: sourcePath))

        let provider = HostileSecurityProvider()
        let result = await runProduction(provider)
        let locked = try XCTUnwrap(outcome(of: result))
        XCTAssertTrue(locked == .sourceChanged || locked == .unavailable,
                      "a detached source must use the locked vocabulary, got \(locked)")
        XCTAssertEqual(provider.invocationCount, 0, "a detached source never reaches the provider")

        // The locked persistence rule: `unavailable` writes nothing, while the
        // pre-provider `sourceChanged` outcome persists exactly one `.failed`
        // row with a NULL provider identifier, because no adapter ran.
        let rows = try EntrySnapshotProbe.classificationRowCount(database: database)
        switch locked {
        case .unavailable:
            XCTAssertEqual(rows, 0, "unavailable never writes a row")
        case .sourceChanged:
            XCTAssertEqual(rows, 1, "a pre-provider sourceChanged persists exactly one failed row")
            let row = try persistedRow()
            XCTAssertEqual(row.text["detection_status"], "failed")
            XCTAssertTrue(row.nullColumns.contains("provider_identifier"),
                          "no adapter ran, so no provider identity may be fabricated")
            XCTAssertTrue(row.nullColumns.contains("detected_type"))
            XCTAssertTrue(row.nullColumns.contains("confidence"))
            let persisted = row.text.values.joined(separator: "\u{1}")
            XCTAssertFalse(persisted.contains(sourcePath), "a detached-source row still persists no path")
        default:
            XCTFail("unexpected outcome \(locked)")
        }

        // The snapshot itself stays valid and browsable while offline.
        let dataSource = SnapshotTreeDataSource(database: database, snapshotID: snapshotID)
        XCTAssertNotNil(try dataSource.root())
        let details = try XCTUnwrap(try dataSource.details(for: entryID))
        XCTAssertEqual(details.name, "hostile-target.bin")
        XCTAssertEqual(details.classification == nil, locked == .unavailable,
                       "the stored classification mirrors the locked outcome and nothing else")
        if let stored = details.classification {
            XCTAssertEqual(stored.detectionStatus, .failed)
            XCTAssertEqual(stored.statusLabel, ClassificationDetectionStatus.failed.displayName)
            XCTAssertNil(stored.detectedType)
            XCTAssertNil(stored.providerIdentifier)
            XCTAssertNil(stored.confidenceLabel)
        }
        XCTAssertEqual(try SnapshotHistoryRepository(database: database).listSnapshots()
            .first { $0.id == snapshotID }?.id, snapshotID)
        XCTAssertEqual(try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: snapshotID), entriesBefore)
        XCTAssertEqual(try EntrySnapshotProbe.snapshotFingerprint(database: database, snapshotID: snapshotID), snapshotBefore)
        var exported = ""
        _ = try JSONSnapshotExporter(database: database).write(snapshotID: snapshotID) { exported += $0 }
        XCTAssertFalse(exported.isEmpty, "offline export still works with a detached source")
    }

    // MARK: - Host network capability

    func testClassificationProductionSurfacesContainNoNetworkCapability() throws {
        // Host-side only. §9's actual-helper network behaviour stays a Slice 07
        // obligation and is deliberately not claimed here.
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("FSD/Classification", isDirectory: true)
        let names = [
            "LocalFileClassificationProvider.swift",
            "BoundedClassificationSourceReader.swift",
            "ClassificationRuntimeService.swift",
            "BundledMagikaClassificationProvider.swift"
        ]
        let forbidden = [
            "import FoundationNetworking", "URLSession", "URLSessionConfiguration", "URLRequest", "HTTPURLResponse",
            "import Network", "NWConnection", "NWListener", "NWPathMonitor", "NWEndpoint", "NWProtocol",
            "CFStream", "CFSocket", "getaddrinfo", "getpeername", "inet_", "socket(", "connect(", "bind(",
            "listen(", "send(", "recv(", "SOCK_STREAM", "SOCK_DGRAM",
            "telemetry", "Telemetry", "analytics", "Analytics", "metricsEndpoint", "Sentry", "Crashlytics",
            "sparkle", "SUUpdater", "watchForUpdates", "autoUpdater", "downloadTask", "SoftwareUpdate",
            "appcast", "URLSessionDownloadTask"
        ]
        for name in names {
            let text = try String(contentsOf: root.appendingPathComponent(name), encoding: .utf8)
            XCTAssertFalse(text.contains("import Network\n"), "\(name) must not import Network.framework")
            for token in forbidden {
                XCTAssertFalse(text.contains(token), "\(name) must not contain \(token)")
            }
        }
        // The provider that could reach a helper process may not reach a socket.
        let bundled = try String(contentsOf: root.appendingPathComponent(names[3]), encoding: .utf8)
        XCTAssertTrue(bundled.contains("process.arguments = []"))
        XCTAssertTrue(bundled.contains("process.environment = [:]"))
    }
}

// MARK: - Hostile provider

/// Attacks all three forbidden capabilities of the §9 adversarial test through
/// the only surface it is given: `LocalClassificationRequest.data`.
///
/// It attempts path recovery, hunts for any second-read API, allocates a buffer
/// far larger than FSD's ceiling and claims to have read it. Every attempt is
/// recorded; the test passes only when all of them have no effect.
private final class HostileSecurityProvider: LocalFileClassificationProvider, @unchecked Sendable {
    static let identifier = "hostile-security-provider"

    struct Inspection {
        var storedFieldLabels: [String] = []
        var receivedBytes = Data()
        var receivedByteCount = 0
        var requestMembers: [String] = []
        var sawURL: String?
        var sawString: String?
        var sawFunction: String?
        var sawHandle: String?
        var attemptedPathRecovery: [String] = []
        var attemptedExtraByteReads = 0
        var attemptedSourceReopens = 0
        var rendered = ""
    }

    let providerIdentifier = "hostile-security-provider"
    let detectorVersion: String? = "hostile-detector"
    let modelVersion: String? = "hostile-model"

    /// Text the provider invents about the "real" source. It must never persist.
    let sourceClaim = "hostile://recovered/original/source?path=/etc/passwd"
    let diagnostic = "HOSTILE-RAW-DIAGNOSTIC host stderr frame"

    private let forcedResult: LocalClassificationProviderResult?
    private(set) var inspected: Inspection?
    private(set) var invocationCount = 0
    private(set) var oversizedBuffer = Data()
    private(set) var claimedByteCount = 0

    /// What the provider tells FSD it found. Deliberately inflated: the test
    /// proves FSD persists only the observation it was handed, never a claim
    /// about bytes FSD did not read.
    let claim = LocalClassificationObservation(
        detectedType: "application/x-hostile-claimed-type", mimeType: "application/x-hostile",
        confidence: 1.0, detectorVersion: "hostile-detector", modelVersion: "hostile-model",
        classifiedAt: "2026-10-06T00:00:00Z"
    )

    init(result: LocalClassificationProviderResult? = nil) {
        forcedResult = result
    }

    func classify(_ request: LocalClassificationRequest) async -> LocalClassificationProviderResult {
        if Task.isCancelled { return .cancelled }
        invocationCount += 1
        var inspection = Inspection()

        // Capability discovery: walk every stored value and every reachable
        // member of the request type itself.
        let mirror = Mirror(reflecting: request)
        for child in mirror.children {
            inspection.storedFieldLabels.append(child.label ?? "?")
            if child.value is URL { inspection.sawURL = String(describing: child.value) }
            if child.value is String { inspection.sawString = String(describing: child.value) }
            if String(describing: type(of: child.value)).contains("->") {
                inspection.sawFunction = String(describing: type(of: child.value))
            }
        }
        for member in Mirror(reflecting: type(of: request)).children where member.label != nil {
            inspection.requestMembers.append(member.label ?? "?")
        }
        inspection.receivedBytes = request.data
        inspection.receivedByteCount = request.data.count
        inspection.rendered = String(reflecting: request) + String(describing: request)
            + String(describing: mirror.children)

        // Attempt 1 — original source authority: recover a path/URL/handle.
        // There is nothing to read, so every probe finds nothing.
        for candidate in ["sourceURL", "url", "path", "fileHandle", "descriptor", "resolver", "callback"] {
            let probe = Mirror(reflecting: request).descendant(candidate)
            if probe != nil { inspection.attemptedPathRecovery.append(candidate) }
        }
        if inspection.rendered.contains("://") { inspection.attemptedPathRecovery.append("rendered-url") }

        // Attempt 2 — additional bytes: index past the end, look for a range,
        // a reader or a reopen hook. The Data cannot be indexed past its count
        // and no such member exists, so no read is ever attempted.
        let beyond = request.data.count + 1
        if request.data.indices.contains(beyond) { inspection.attemptedExtraByteReads += 1 }
        for candidate in ["readMore", "moreBytes", "byteRange", "reader", "reopen", "nextChunk"] {
            if Mirror(reflecting: request).descendant(candidate) != nil { inspection.attemptedSourceReopens += 1 }
        }

        // Attempt 3 — ceiling bypass: allocate and claim far more than FSD read.
        oversizedBuffer = Data(count: 1 << 22)
        claimedByteCount = 1 << 22

        inspected = inspection
        if let forcedResult { return forcedResult }
        return .classified(claim)
    }
}