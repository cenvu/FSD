import Foundation
import SQLite3

public struct SnapshotID: Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: Int64

    public init(rawValue: Int64) {
        self.rawValue = rawValue
    }

    public var description: String { String(rawValue) }
}

public enum SnapshotStatus: String, Codable, CaseIterable, Sendable {
    case scanning
    case complete
    case completeWithWarnings = "complete_with_warnings"
    case interrupted
    case cancelled
    case failed

    public var isTerminal: Bool {
        switch self {
        case .scanning: return false
        case .complete, .completeWithWarnings, .interrupted, .cancelled, .failed: return true
        }
    }
}

public enum SnapshotKind: String, Codable, CaseIterable, Sendable {
    case user
    case transient
}

public enum SourceCaseSensitivity: String, Codable, CaseIterable, Sendable {
    case sensitive
    case insensitive
    case unknown
}

public struct NormalizationVersion: Hashable, Codable, Sendable, CustomStringConvertible {
    public static let current = NormalizationVersion(rawValue: "fsd-normalizer-v1_app-1.0_os-1")

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public var isSupported: Bool { self == Self.current }
    public var description: String { rawValue }
}

public struct SnapshotRecord: Identifiable, Hashable, Sendable {
    public let id: SnapshotID
    public let volumeID: Int64
    public let sessionNumber: Int64
    public let scanRootName: String
    public let status: SnapshotStatus
    public let scannerVersion: String
    public let schemaVersion: Int64
    public let normalizationVersion: NormalizationVersion
    public let kind: SnapshotKind
    public let sourceCaseSensitivity: SourceCaseSensitivity
    public let displayName: String
    public let startedAt: String
    public let completedAt: String?

    public var isComplete: Bool {
        status == .complete || status == .completeWithWarnings
    }
}

public enum SnapshotRepositoryError: Error, LocalizedError, Equatable {
    case database(CatalogDatabaseError)
    case notFound(SnapshotID)
    case invalidTransition(from: SnapshotStatus, to: SnapshotStatus)
    case unsupportedNormalizationVersion(String)

    public var errorDescription: String? {
        switch self {
        case let .database(error): return error.localizedDescription
        case let .notFound(id): return "Snapshot \(id) was not found."
        case let .invalidTransition(from, to): return "Invalid snapshot transition from \(from.rawValue) to \(to.rawValue)."
        case let .unsupportedNormalizationVersion(value): return "Unsupported normalization version: \(value)"
        }
    }
}

public final class SnapshotRepository {
    public static let scannerVersion = "fsd-scanner-m1"

    private let database: CatalogDatabase

    public init(database: CatalogDatabase) {
        self.database = database
    }

    public func createVolume(id: Int64, displayName: String) throws {
        do {
            try database.execute(
                """
                INSERT INTO volumes (id, display_name, first_seen_at, last_seen_at, created_at, updated_at)
                VALUES (?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """,
                bindings: [.integer(id), .text(displayName)]
            )
        } catch let error as CatalogDatabaseError {
            throw SnapshotRepositoryError.database(error)
        }
    }

    @discardableResult
    public func createSnapshot(
        volumeID: Int64,
        sessionNumber: Int64,
        scanRootName: String,
        normalizationVersion: NormalizationVersion = .current,
        kind: SnapshotKind = .user,
        sourceCaseSensitivity: SourceCaseSensitivity = .unknown,
        displayName: String? = nil
    ) throws -> SnapshotID {
        do {
            return try database.transaction {
                let name = displayName ?? scanRootName
                try database.execute(
                    """
                    INSERT INTO snapshots (
                        volume_id, session_number, scan_root_name, status, scanner_version,
                        schema_version, normalization_version, snapshot_kind,
                        source_case_sensitivity, display_name, capture_policy_json,
                        started_at, created_at, updated_at
                    ) VALUES (?, ?, ?, 'scanning', ?, ?, ?, ?, ?, ?, '{}',
                              CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                    """,
                    bindings: [
                        .integer(volumeID), .integer(sessionNumber), .text(scanRootName),
                        .text(Self.scannerVersion), .integer(CatalogDatabase.currentSchemaVersion),
                        .text(normalizationVersion.rawValue), .text(kind.rawValue),
                        .text(sourceCaseSensitivity.rawValue), .text(name)
                    ]
                )
                return SnapshotID(rawValue: try database.lastInsertRowID())
            }
        } catch let error as SnapshotRepositoryError {
            throw error
        } catch let error as CatalogDatabaseError {
            throw SnapshotRepositoryError.database(error)
        } catch {
            throw SnapshotRepositoryError.database(.sqlite(SQLITE_ERROR, error.localizedDescription))
        }
    }

    @discardableResult
    public func addRoot(to snapshotID: SnapshotID, name: String) throws -> SnapshotID {
        do {
            return try database.transaction {
                guard try snapshotExists(snapshotID) else { throw SnapshotRepositoryError.notFound(snapshotID) }
                try database.execute(
                    """
                    INSERT INTO entries (
                        snapshot_id, parent_id, relative_path, case_preserving_path,
                        case_folded_path, name, case_preserving_name, case_folded_name,
                        item_type, sort_key, created_at
                    ) VALUES (?, NULL, '', '', '', ?, ?, ?, 'directory', '0', CURRENT_TIMESTAMP)
                    """,
                    bindings: [
                        .integer(snapshotID.rawValue), .text(name), .text(name), .text(name.lowercased())
                    ]
                )
                return SnapshotID(rawValue: try database.lastInsertRowID())
            }
        } catch let error as SnapshotRepositoryError {
            throw error
        } catch let error as CatalogDatabaseError {
            throw SnapshotRepositoryError.database(error)
        } catch {
            throw SnapshotRepositoryError.database(.sqlite(SQLITE_ERROR, error.localizedDescription))
        }
    }

    public func snapshot(id: SnapshotID) throws -> SnapshotRecord? {
        do {
            let rows = try database.query(
                """
                SELECT id, volume_id, session_number, scan_root_name, status,
                       scanner_version, schema_version, normalization_version,
                       snapshot_kind, source_case_sensitivity, display_name,
                       started_at, completed_at
                FROM snapshots WHERE id = ?
                """,
                bindings: [.integer(id.rawValue)]
            )
            return try rows.first.map(makeRecord)
        } catch let error as SnapshotRepositoryError {
            throw error
        } catch let error as CatalogDatabaseError {
            throw SnapshotRepositoryError.database(error)
        }
    }

    public func listSnapshots() throws -> [SnapshotRecord] {
        do {
            let rows = try database.query(
                """
                SELECT id, volume_id, session_number, scan_root_name, status,
                       scanner_version, schema_version, normalization_version,
                       snapshot_kind, source_case_sensitivity, display_name,
                       started_at, completed_at
                FROM snapshots ORDER BY started_at DESC, id DESC
                """
            )
            return try rows.map(makeRecord)
        } catch let error as CatalogDatabaseError {
            throw SnapshotRepositoryError.database(error)
        }
    }

    public func transition(_ snapshotID: SnapshotID, to target: SnapshotStatus) throws {
        do {
            try database.transaction {
                guard let current = try snapshot(id: snapshotID) else {
                    throw SnapshotRepositoryError.notFound(snapshotID)
                }
                guard canTransition(from: current.status, to: target) else {
                    throw SnapshotRepositoryError.invalidTransition(from: current.status, to: target)
                }
                if target == .complete || target == .completeWithWarnings,
                   !current.normalizationVersion.isSupported {
                    throw SnapshotRepositoryError.unsupportedNormalizationVersion(current.normalizationVersion.rawValue)
                }
                let completedAt = target == .complete || target == .completeWithWarnings
                    ? "CURRENT_TIMESTAMP"
                    : "completed_at"
                try database.execute(
                    "UPDATE snapshots SET status = ?, completed_at = \(completedAt), updated_at = CURRENT_TIMESTAMP WHERE id = ?",
                    bindings: [.text(target.rawValue), .integer(snapshotID.rawValue)]
                )
            }
        } catch let error as SnapshotRepositoryError {
            throw error
        } catch let error as CatalogDatabaseError {
            throw SnapshotRepositoryError.database(error)
        }
    }

    public func complete(_ snapshotID: SnapshotID) throws {
        try transition(snapshotID, to: .complete)
    }

    public func interrupt(_ snapshotID: SnapshotID) throws {
        try transition(snapshotID, to: .interrupted)
    }

    public func fail(_ snapshotID: SnapshotID) throws {
        try transition(snapshotID, to: .failed)
    }

    private func snapshotExists(_ id: SnapshotID) throws -> Bool {
        try database.scalar(
            "SELECT 1 FROM snapshots WHERE id = ? LIMIT 1",
            bindings: [.integer(id.rawValue)]
        )?.int64Value == 1
    }

    private func canTransition(from: SnapshotStatus, to: SnapshotStatus) -> Bool {
        guard from == .scanning else { return false }
        return to == .complete || to == .completeWithWarnings || to == .interrupted || to == .cancelled || to == .failed
    }

    private func makeRecord(from row: DatabaseRow) throws -> SnapshotRecord {
        guard
            let id = row["id"]?.int64Value,
            let volumeID = row["volume_id"]?.int64Value,
            let sessionNumber = row["session_number"]?.int64Value,
            let scanRootName = row["scan_root_name"]?.stringValue,
            let statusRaw = row["status"]?.stringValue,
            let status = SnapshotStatus(rawValue: statusRaw),
            let scannerVersion = row["scanner_version"]?.stringValue,
            let schemaVersion = row["schema_version"]?.int64Value,
            let normalizationRaw = row["normalization_version"]?.stringValue,
            let kindRaw = row["snapshot_kind"]?.stringValue,
            let kind = SnapshotKind(rawValue: kindRaw),
            let sensitivityRaw = row["source_case_sensitivity"]?.stringValue,
            let sensitivity = SourceCaseSensitivity(rawValue: sensitivityRaw),
            let displayName = row["display_name"]?.stringValue,
            let startedAt = row["started_at"]?.stringValue
        else {
            throw SnapshotRepositoryError.database(.sqlite(SQLITE_CORRUPT, "Snapshot row contains invalid typed data"))
        }
        return SnapshotRecord(
            id: SnapshotID(rawValue: id), volumeID: volumeID, sessionNumber: sessionNumber,
            scanRootName: scanRootName, status: status, scannerVersion: scannerVersion,
            schemaVersion: schemaVersion, normalizationVersion: NormalizationVersion(rawValue: normalizationRaw),
            kind: kind, sourceCaseSensitivity: sensitivity, displayName: displayName,
            startedAt: startedAt, completedAt: row["completed_at"]?.stringValue
        )
    }
}
