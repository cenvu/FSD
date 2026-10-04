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
    public let providerIdentifier: String?
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

/// Input accepted by the explicit enrichment writer. Detector, model and
/// provider provenance are independent. Provider identity is optional at the
/// type level, but required for a classified write.
public struct EntryClassificationInput: Sendable, Hashable {
    public let entryID: Int64
    public let classificationRunID: String
    public let detectedType: String?
    public let mimeType: String?
    public let confidence: Double?
    public let detectionStatus: ClassificationDetectionStatus?
    public let detectorVersion: String?
    public let modelVersion: String?
    public let providerIdentifier: String?
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
        providerIdentifier: String? = nil,
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
        self.providerIdentifier = providerIdentifier
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
                            classified_at, created_at, provider_identifier
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, ?)
                        """,
                        bindings: [
                            .integer(input.entryID), .text(input.classificationRunID),
                            input.detectedType.map(DatabaseValue.text) ?? .null,
                            input.mimeType.map(DatabaseValue.text) ?? .null,
                            input.confidence.map(DatabaseValue.real) ?? .null,
                            input.detectionStatus.map { .text($0.rawValue) } ?? .null,
                            input.detectorVersion.map(DatabaseValue.text) ?? .null,
                            input.modelVersion.map(DatabaseValue.text) ?? .null,
                            input.classifiedAt.map(DatabaseValue.text) ?? .null,
                            input.providerIdentifier.map(DatabaseValue.text) ?? .null
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
                       c.model_version, c.classified_at, c.created_at, c.provider_identifier
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
                       classified_at, created_at, provider_identifier
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
                   classified_at, created_at, provider_identifier
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
        if input.detectionStatus == .classified {
            guard let providerIdentifier = input.providerIdentifier,
                  !providerIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw EntryClassificationRepositoryError.invalidInput("classified rows require a non-empty provider identifier")
            }
        }
        if let confidence = input.confidence, !(0.0...1.0).contains(confidence) {
            throw EntryClassificationRepositoryError.invalidInput("confidence must be between 0 and 1")
        }
        for value in [input.detectedType, input.mimeType, input.detectorVersion, input.modelVersion, input.providerIdentifier, input.classifiedAt].compactMap({ $0 }) {
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
            providerIdentifier: row["provider_identifier"]?.stringValue,
            classifiedAt: row["classified_at"]?.stringValue,
            createdAt: createdAt
        )
    }
}
