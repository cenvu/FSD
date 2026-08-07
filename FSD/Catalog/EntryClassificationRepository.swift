import Foundation

/// The small, persisted status vocabulary already supported by schema v8.
/// Absence of a row means that enrichment was not requested for this entry.
public enum ClassificationDetectionStatus: String, Sendable, Hashable {
    case notRequested = "not_requested"
    case disabled
    case classified
    case failed

    public var displayName: String {
        switch self {
        case .notRequested: return "Not classified"
        case .disabled: return "Classification unavailable"
        case .classified: return "Inferred file type"
        case .failed: return "Classification unavailable"
        }
    }
}

/// A bounded, typed view of one optional classification row. It contains no
/// payload, sampled bytes, hash, absolute source path or provider diagnostic.
public struct EntryClassification: Identifiable, Hashable, Sendable {
    public let id: Int64
    public let entryID: Int64
    public let classificationRunID: String
    public let detectedType: String?
    public let mimeType: String?
    public let confidence: Double?
    public let detectionStatus: ClassificationDetectionStatus?
    public let detectorVersion: String?
    public let modelVersion: String?
    public let classifiedAt: String?
    public let createdAt: String

    public var statusLabel: String {
        detectionStatus?.displayName ?? "Not classified"
    }

    public var confidenceLabel: String? {
        guard let confidence else { return nil }
        return String(format: "%.1f%%", confidence * 100.0)
    }
}

/// Input accepted by the explicit enrichment writer. The v8 schema has no
/// separate provider column, so detector/model versions are the persisted
/// provenance fields; the adapter identifier remains runtime-only.
public struct EntryClassificationInput: Sendable, Hashable {
    public let entryID: Int64
    public let classificationRunID: String
    public let detectedType: String?
    public let mimeType: String?
    public let confidence: Double?
    public let detectionStatus: ClassificationDetectionStatus?
    public let detectorVersion: String?
    public let modelVersion: String?
    public let classifiedAt: String?

    public init(
        entryID: Int64,
        classificationRunID: String,
        detectedType: String? = nil,
        mimeType: String? = nil,
        confidence: Double? = nil,
        detectionStatus: ClassificationDetectionStatus? = .classified,
        detectorVersion: String? = nil,
        modelVersion: String? = nil,
        classifiedAt: String? = nil
    ) {
        self.entryID = entryID
        self.classificationRunID = classificationRunID
        self.detectedType = detectedType
        self.mimeType = mimeType
        self.confidence = confidence
        self.detectionStatus = detectionStatus
        self.detectorVersion = detectorVersion
        self.modelVersion = modelVersion
        self.classifiedAt = classifiedAt
    }
}

public enum EntryClassificationRepositoryError: Error, LocalizedError, Equatable {
    case database(CatalogDatabaseError)
    case entryNotFound(Int64)
    case duplicateRun(entryID: Int64, classificationRunID: String)
    case invalidInput(String)

    public var errorDescription: String? {
        switch self {
        case let .database(error): return error.localizedDescription
        case let .entryNotFound(entryID): return "Entry \(entryID) was not found."
        case let .duplicateRun(entryID, runID):
            return "Classification run \(runID) already exists for entry \(entryID)."
        case let .invalidInput(message): return "Invalid classification input: \(message)"
        }
    }
}

/// Repository boundary for nullable classification metadata.
///
/// There is deliberately no update or delete method. A run is append-only and
/// `(entry_id, classification_run_id)` is unique in schema v8. This keeps
/// enrichment separate from immutable snapshot entry metadata.
public final class EntryClassificationRepository {
    public static let maxVisibleEntryPage = 500
    public static let maxHistoryRows = 100

    private let database: CatalogDatabase

    public init(database: CatalogDatabase) {
        self.database = database
    }

    @discardableResult
    public func append(_ input: EntryClassificationInput) throws -> EntryClassification {
        try validate(input)
        do {
            return try database.transaction {
                guard try database.scalar(
                    "SELECT 1 FROM entries WHERE id = ? LIMIT 1",
                    bindings: [.integer(input.entryID)]
                )?.int64Value == 1 else {
                    throw EntryClassificationRepositoryError.entryNotFound(input.entryID)
                }
                do {
                    try database.execute(
                        """
                        INSERT INTO entry_classifications (
                            entry_id, classification_run_id, detected_type, mime_type,
                            confidence, detection_status, detector_version, model_version,
                            classified_at, created_at
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
                        """,
                        bindings: [
                            .integer(input.entryID), .text(input.classificationRunID),
                            input.detectedType.map(DatabaseValue.text) ?? .null,
                            input.mimeType.map(DatabaseValue.text) ?? .null,
                            input.confidence.map(DatabaseValue.real) ?? .null,
                            input.detectionStatus.map { .text($0.rawValue) } ?? .null,
                            input.detectorVersion.map(DatabaseValue.text) ?? .null,
                            input.modelVersion.map(DatabaseValue.text) ?? .null,
                            input.classifiedAt.map(DatabaseValue.text) ?? .null
                        ]
                    )
                } catch let error as CatalogDatabaseError {
                    if case let .sqlite(_, message) = error,
                       message.localizedCaseInsensitiveContains("UNIQUE") {
                        throw EntryClassificationRepositoryError.duplicateRun(
                            entryID: input.entryID,
                            classificationRunID: input.classificationRunID
                        )
                    }
                    throw EntryClassificationRepositoryError.database(error)
                }
                guard let result = try classification(id: database.lastInsertRowID()) else {
                    throw EntryClassificationRepositoryError.database(
                        .schemaStateInvalid("inserted classification row could not be read back")
                    )
                }
                return result
            }
        } catch let error as EntryClassificationRepositoryError {
            throw error
        } catch let error as CatalogDatabaseError {
            throw EntryClassificationRepositoryError.database(error)
        }
    }

    public func classification(for entryID: Int64) throws -> EntryClassification? {
        do {
            return try latestRows(for: [entryID]).first
        } catch let error as EntryClassificationRepositoryError {
            throw error
        } catch let error as CatalogDatabaseError {
            throw EntryClassificationRepositoryError.database(error)
        }
    }

    /// Reads at most one latest row per visible entry ID in one query. Callers
    /// must provide a bounded page; this prevents a browse view from creating
    /// an N+1 classification query pattern.
    public func latestClassifications(for entryIDs: [Int64]) throws -> [Int64: EntryClassification] {
        guard entryIDs.count <= Self.maxVisibleEntryPage else {
            throw EntryClassificationRepositoryError.invalidInput("visible entry page exceeds \(Self.maxVisibleEntryPage) rows")
        }
        guard !entryIDs.isEmpty else { return [:] }
        do {
            let placeholders = Array(repeating: "?", count: entryIDs.count).joined(separator: ", ")
            let bindings = entryIDs.map(DatabaseValue.integer)
            let rows = try database.query(
                """
                SELECT c.id, c.entry_id, c.classification_run_id, c.detected_type,
                       c.mime_type, c.confidence, c.detection_status, c.detector_version,
                       c.model_version, c.classified_at, c.created_at
                FROM entry_classifications c
                JOIN (
                    SELECT entry_id, MAX(id) AS latest_id
                    FROM entry_classifications
                    WHERE entry_id IN (\(placeholders))
                    GROUP BY entry_id
                ) latest ON latest.latest_id = c.id
                ORDER BY c.entry_id
                """,
                bindings: bindings
            )
            return try Dictionary(uniqueKeysWithValues: rows.map { row in
                let value = try makeClassification(from: row)
                return (value.entryID, value)
            })
        } catch let error as EntryClassificationRepositoryError {
            throw error
        } catch let error as CatalogDatabaseError {
            throw EntryClassificationRepositoryError.database(error)
        }
    }

    public func history(for entryID: Int64, limit: Int = EntryClassificationRepository.maxHistoryRows) throws -> [EntryClassification] {
        let bounded = max(1, min(limit, Self.maxHistoryRows))
        do {
            let rows = try database.query(
                """
                SELECT id, entry_id, classification_run_id, detected_type, mime_type,
                       confidence, detection_status, detector_version, model_version,
                       classified_at, created_at
                FROM entry_classifications
                WHERE entry_id = ?
                ORDER BY id DESC LIMIT ?
                """,
                bindings: [.integer(entryID), .integer(Int64(bounded))]
            )
            return try rows.map(makeClassification)
        } catch let error as EntryClassificationRepositoryError {
            throw error
        } catch let error as CatalogDatabaseError {
            throw EntryClassificationRepositoryError.database(error)
        }
    }

    private func latestRows(for entryIDs: [Int64]) throws -> [EntryClassification] {
        Array(try latestClassifications(for: entryIDs).values)
            .sorted { $0.id < $1.id }
    }

    private func classification(id: Int64) throws -> EntryClassification? {
        let rows = try database.query(
            """
            SELECT id, entry_id, classification_run_id, detected_type, mime_type,
                   confidence, detection_status, detector_version, model_version,
                   classified_at, created_at
            FROM entry_classifications WHERE id = ? LIMIT 1
            """,
            bindings: [.integer(id)]
        )
        return try rows.first.map(makeClassification)
    }

    private func validate(_ input: EntryClassificationInput) throws {
        guard input.entryID > 0 else { throw EntryClassificationRepositoryError.invalidInput("entry ID must be positive") }
        guard !input.classificationRunID.isEmpty, input.classificationRunID.count <= 256 else {
            throw EntryClassificationRepositoryError.invalidInput("classification run ID must contain 1–256 characters")
        }
        if let confidence = input.confidence, !(0.0...1.0).contains(confidence) {
            throw EntryClassificationRepositoryError.invalidInput("confidence must be between 0 and 1")
        }
        for value in [input.detectedType, input.mimeType, input.detectorVersion, input.modelVersion, input.classifiedAt].compactMap({ $0 }) {
            guard value.count <= 256 else {
                throw EntryClassificationRepositoryError.invalidInput("classification metadata values must be at most 256 characters")
            }
        }
    }

    private func makeClassification(from row: DatabaseRow) throws -> EntryClassification {
        guard
            let id = row["id"]?.int64Value,
            let entryID = row["entry_id"]?.int64Value,
            let runID = row["classification_run_id"]?.stringValue,
            let createdAt = row["created_at"]?.stringValue
        else {
            throw EntryClassificationRepositoryError.database(
                .schemaStateInvalid("entry classification row is incomplete")
            )
        }
        let status: ClassificationDetectionStatus?
        if let raw = row["detection_status"]?.stringValue {
            guard let parsed = ClassificationDetectionStatus(rawValue: raw) else {
                throw EntryClassificationRepositoryError.database(
                    .schemaStateInvalid("entry classification status is invalid")
                )
            }
            status = parsed
        } else {
            status = nil
        }
        return EntryClassification(
            id: id,
            entryID: entryID,
            classificationRunID: runID,
            detectedType: row["detected_type"]?.stringValue,
            mimeType: row["mime_type"]?.stringValue,
            confidence: row["confidence"]?.realValue,
            detectionStatus: status,
            detectorVersion: row["detector_version"]?.stringValue,
            modelVersion: row["model_version"]?.stringValue,
            classifiedAt: row["classified_at"]?.stringValue,
            createdAt: createdAt
        )
    }
}

/// Request passed only when an explicitly approved enrichment caller invokes a
/// provider. Ordinary capture, browse, search, export and comparison do not
/// construct or submit this request.
public struct LocalClassificationRequest: Sendable, Hashable {
    public let entryID: Int64
    public let sourceURL: URL?
    public let byteBudget: Int64?

    public init(entryID: Int64, sourceURL: URL? = nil, byteBudget: Int64? = nil) {
        self.entryID = entryID
        self.sourceURL = sourceURL
        self.byteBudget = byteBudget
    }
}

public struct LocalClassificationObservation: Sendable, Hashable {
    public let detectedType: String?
    public let mimeType: String?
    public let confidence: Double?
    public let detectorVersion: String?
    public let modelVersion: String?
    public let classifiedAt: String?

    public init(
        detectedType: String?,
        mimeType: String? = nil,
        confidence: Double? = nil,
        detectorVersion: String? = nil,
        modelVersion: String? = nil,
        classifiedAt: String? = nil
    ) {
        self.detectedType = detectedType
        self.mimeType = mimeType
        self.confidence = confidence
        self.detectorVersion = detectorVersion
        self.modelVersion = modelVersion
        self.classifiedAt = classifiedAt
    }
}

public enum LocalClassificationProviderResult: Sendable, Hashable {
    case classified(LocalClassificationObservation)
    case unavailable
    case failed
}

/// Future Magika adapters implement this local-only protocol. The protocol
/// exposes no raw diagnostic channel and no networking hook.
public protocol LocalFileClassificationProvider: Sendable {
    var providerIdentifier: String { get }
    var detectorVersion: String? { get }
    var modelVersion: String? { get }
    func classify(_ request: LocalClassificationRequest) throws -> LocalClassificationProviderResult
}

/// The only built-in provider in this slice. It performs no filesystem access
/// and leaves the nullable table empty when called by the explicit service.
public struct DisabledFileClassificationProvider: LocalFileClassificationProvider {
    public let providerIdentifier = "disabled"
    public let detectorVersion: String? = nil
    public let modelVersion: String? = nil

    public init() {}

    public func classify(_ request: LocalClassificationRequest) throws -> LocalClassificationProviderResult {
        .unavailable
    }
}

/// Explicit enrichment service. It is intentionally not injected into the
/// scanner, browser, search, exporter or comparison services.
public final class ClassificationEnrichmentService {
    private let provider: any LocalFileClassificationProvider
    private let repository: EntryClassificationRepository

    public init(database: CatalogDatabase, provider: any LocalFileClassificationProvider) {
        self.provider = provider
        self.repository = EntryClassificationRepository(database: database)
    }

    public func enrich(
        entryID: Int64,
        classificationRunID: String,
        sourceURL: URL? = nil,
        byteBudget: Int64? = nil
    ) throws -> EntryClassification? {
        let request = LocalClassificationRequest(entryID: entryID, sourceURL: sourceURL, byteBudget: byteBudget)
        let result: LocalClassificationProviderResult
        do {
            result = try provider.classify(request)
        } catch {
            result = .failed
        }
        switch result {
        case .unavailable:
            return nil
        case .failed:
            return try repository.append(EntryClassificationInput(
                entryID: entryID,
                classificationRunID: classificationRunID,
                detectionStatus: .failed,
                detectorVersion: provider.detectorVersion,
                modelVersion: provider.modelVersion
            ))
        case let .classified(observation):
            return try repository.append(EntryClassificationInput(
                entryID: entryID,
                classificationRunID: classificationRunID,
                detectedType: observation.detectedType,
                mimeType: observation.mimeType,
                confidence: observation.confidence,
                detectionStatus: .classified,
                detectorVersion: observation.detectorVersion ?? provider.detectorVersion,
                modelVersion: observation.modelVersion ?? provider.modelVersion,
                classifiedAt: observation.classifiedAt
            ))
        }
    }
}
