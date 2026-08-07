import Foundation

/// The source facts recorded at capture time.
///
/// Condition C4 of the Milestone 2 acceptance audit: `SnapshotWriter.ensureVolume`
/// refreshes `volumes.display_name`, `filesystem_type` and
/// `total_capacity_bytes` on every capture, so anything read from that registry
/// and shown beside an older snapshot silently reflects a *later* capture. The
/// decision (ADR-023) is that history reads only immutable snapshot columns.
///
/// Every field is optional because a snapshot captured before schema version 5
/// genuinely has no record of it. That is displayed as "not recorded at capture
/// time" — never back-filled from the registry, which would reintroduce exactly
/// the untruth this closes.
public struct CaptureTimeSourceFacts: Hashable, Sendable {
    public let volumeDisplayName: String?
    public let volumeIdentifier: String?
    public let volumeTotalCapacityBytes: Int64?
    public let mountPath: String?
    public let filesystemVariant: String?
    public let caseSensitivity: SourceCaseSensitivity

    /// False for snapshots captured before schema version 5, whose volume-level
    /// facts were never written down.
    public var isFullyRecorded: Bool {
        volumeDisplayName != nil && volumeIdentifier != nil
    }

    public var displayNameForHistory: String {
        volumeDisplayName ?? "Not recorded at capture time"
    }
}

public struct SnapshotSummary: Identifiable, Hashable, Sendable {
    public let id: SnapshotID
    public let volumeID: Int64
    public let sessionNumber: Int64
    public let displayName: String
    public let scanRootName: String
    public let status: SnapshotStatus
    public let kind: SnapshotKind
    public let startedAt: String
    public let completedAt: String?
    public let totalFiles: Int64
    public let totalFolders: Int64
    public let totalLogicalBytes: Int64
    public let totalAllocatedBytes: Int64
    public let inaccessibleItems: Int64
    public let warningCount: Int64
    public let filesystemProvider: String
    public let providerVersion: String?
    public let sourceAccessMode: String
    public let scannerVersion: String
    public let schemaVersion: Int64
    public let normalizationVersion: NormalizationVersion
    public let capture: CaptureTimeSourceFacts

    public var isComplete: Bool { status == .complete || status == .completeWithWarnings }

    /// True when the capture stopped before it finished, so the stored tree is a
    /// partial view of the source rather than a full one.
    public var isPartialCapture: Bool {
        status == .interrupted || status == .cancelled || status == .failed
    }

    /// Text the browser shows above a snapshot whose contents cannot be treated
    /// as a full picture of the source. `nil` when the capture ran to completion
    /// with no warnings.
    public var partialStateWarning: String? {
        switch status {
        case .complete:
            return warningCount > 0 ? "This capture recorded \(warningCount) warning(s)." : nil
        case .completeWithWarnings:
            return "This capture completed with \(warningCount) warning(s); some items may be missing or unreadable."
        case .interrupted:
            return "This capture was interrupted. The stored tree is partial and does not describe the whole source."
        case .cancelled:
            return "This capture was cancelled. The stored tree is partial and does not describe the whole source."
        case .failed:
            return "This capture failed. The stored tree is partial and does not describe the whole source."
        case .scanning:
            return "This capture has not finished."
        }
    }
}

public struct SnapshotIssue: Identifiable, Hashable, Sendable {
    public let id: Int64
    public let entryID: Int64?
    public let relativePath: String
    public let severity: String
    public let source: String
    public let message: String
    public let wasSkipped: Bool
    public let createdAt: String
}

/// Whether the source a snapshot was taken from is present right now.
///
/// Deliberately separate from `SnapshotHistoryRepository`, which never touches
/// the filesystem: browsing, searching and exporting a snapshot must work with
/// the source ejected, so the only filesystem call in this area is this one
/// explicit, optional check used to label the UI.
public enum SourceAvailability: String, Sendable {
    case available
    case unavailable
    case unknown

    public var label: String {
        switch self {
        case .available: return "Source connected"
        case .unavailable: return "Source offline — browsing stored metadata"
        case .unknown: return "Source location not recorded — browsing stored metadata"
        }
    }
}

public struct SourceAvailabilityProbe {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Existence check only. Never opens, mounts, reads or writes the source.
    public func availability(for summary: SnapshotSummary) -> SourceAvailability {
        guard let mountPath = summary.capture.mountPath, !mountPath.isEmpty else { return .unknown }
        return fileManager.fileExists(atPath: mountPath) ? .available : .unavailable
    }
}

/// Reads snapshot history from SQLite and nothing else.
///
/// This type has no `FileManager`, no `URL` source handling and no provider: a
/// snapshot's history entry is fully described by the catalog, so history works
/// with the original source ejected, erased or never reconnected.
public final class SnapshotHistoryRepository {
    private let database: CatalogDatabase

    public init(database: CatalogDatabase) {
        self.database = database
    }

    /// Deterministic newest-first order. `id` breaks ties so two captures that
    /// share a timestamp always list in the same sequence.
    ///
    /// Transient snapshots (ADR-012) are excluded by default: they are
    /// comparison scaffolding, not user history.
    public func listSnapshots(kind: SnapshotKind? = .user) throws -> [SnapshotSummary] {
        let filter = kind.map { _ in "WHERE snapshot_kind = ?" } ?? ""
        let bindings = kind.map { [DatabaseValue.text($0.rawValue)] } ?? []
        let rows = try database.query(
            "\(Self.summaryColumns) \(filter) ORDER BY started_at DESC, id DESC",
            bindings: bindings
        )
        return try rows.map(Self.makeSummary)
    }

    public func summary(id: SnapshotID) throws -> SnapshotSummary? {
        let rows = try database.query(
            "\(Self.summaryColumns) WHERE id = ?",
            bindings: [.integer(id.rawValue)]
        )
        return try rows.first.map(Self.makeSummary)
    }

    /// Bounded: an unbounded issue list would defeat the point of a bounded
    /// browser. Callers show the count from `SnapshotSummary.warningCount`.
    public func issues(for id: SnapshotID, limit: Int = 200) throws -> [SnapshotIssue] {
        let rows = try database.query(
            """
            SELECT id, entry_id, relative_path, severity, source, message, was_skipped, created_at
            FROM scan_issues WHERE snapshot_id = ? ORDER BY id LIMIT ?
            """,
            bindings: [.integer(id.rawValue), .integer(Int64(max(1, limit)))]
        )
        return rows.compactMap { row in
            guard
                let issueID = row["id"]?.int64Value,
                let relativePath = row["relative_path"]?.stringValue,
                let severity = row["severity"]?.stringValue,
                let source = row["source"]?.stringValue,
                let message = row["message"]?.stringValue,
                let createdAt = row["created_at"]?.stringValue
            else { return nil }
            return SnapshotIssue(
                id: issueID,
                entryID: row["entry_id"]?.int64Value,
                relativePath: relativePath,
                severity: severity,
                source: source,
                message: message,
                wasSkipped: (row["was_skipped"]?.int64Value ?? 0) == 1,
                createdAt: createdAt
            )
        }
    }

    public func entryCount(for id: SnapshotID) throws -> Int64 {
        try database.scalar(
            "SELECT COUNT(*) FROM entries WHERE snapshot_id = ?",
            bindings: [.integer(id.rawValue)]
        )?.int64Value ?? 0
    }

    private static let summaryColumns = """
    SELECT id, volume_id, session_number, display_name, scan_root_name, status, snapshot_kind,
           started_at, completed_at, total_files, total_folders, total_logical_bytes,
           total_allocated_bytes, inaccessible_items, warning_count, filesystem_provider,
           provider_version, source_access_mode, scanner_version, schema_version,
           normalization_version, source_case_sensitivity, mount_path_at_capture,
           filesystem_variant, volume_display_name_at_capture, volume_identifier_at_capture,
           volume_total_capacity_bytes_at_capture
    FROM snapshots
    """

    private static func makeSummary(from row: DatabaseRow) throws -> SnapshotSummary {
        guard
            let id = row["id"]?.int64Value,
            let volumeID = row["volume_id"]?.int64Value,
            let sessionNumber = row["session_number"]?.int64Value,
            let displayName = row["display_name"]?.stringValue,
            let scanRootName = row["scan_root_name"]?.stringValue,
            let statusRaw = row["status"]?.stringValue,
            let status = SnapshotStatus(rawValue: statusRaw),
            let kindRaw = row["snapshot_kind"]?.stringValue,
            let kind = SnapshotKind(rawValue: kindRaw),
            let startedAt = row["started_at"]?.stringValue,
            let filesystemProvider = row["filesystem_provider"]?.stringValue,
            let sourceAccessMode = row["source_access_mode"]?.stringValue,
            let scannerVersion = row["scanner_version"]?.stringValue,
            let schemaVersion = row["schema_version"]?.int64Value,
            let normalizationRaw = row["normalization_version"]?.stringValue,
            let sensitivityRaw = row["source_case_sensitivity"]?.stringValue,
            let sensitivity = SourceCaseSensitivity(rawValue: sensitivityRaw)
        else {
            throw SnapshotRepositoryError.database(.schemaStateInvalid("snapshot history row is incomplete"))
        }
        return SnapshotSummary(
            id: SnapshotID(rawValue: id),
            volumeID: volumeID,
            sessionNumber: sessionNumber,
            displayName: displayName,
            scanRootName: scanRootName,
            status: status,
            kind: kind,
            startedAt: startedAt,
            completedAt: row["completed_at"]?.stringValue,
            totalFiles: row["total_files"]?.int64Value ?? 0,
            totalFolders: row["total_folders"]?.int64Value ?? 0,
            totalLogicalBytes: row["total_logical_bytes"]?.int64Value ?? 0,
            totalAllocatedBytes: row["total_allocated_bytes"]?.int64Value ?? 0,
            inaccessibleItems: row["inaccessible_items"]?.int64Value ?? 0,
            warningCount: row["warning_count"]?.int64Value ?? 0,
            filesystemProvider: filesystemProvider,
            providerVersion: row["provider_version"]?.stringValue,
            sourceAccessMode: sourceAccessMode,
            scannerVersion: scannerVersion,
            schemaVersion: schemaVersion,
            normalizationVersion: NormalizationVersion(rawValue: normalizationRaw),
            capture: CaptureTimeSourceFacts(
                volumeDisplayName: row["volume_display_name_at_capture"]?.stringValue,
                volumeIdentifier: row["volume_identifier_at_capture"]?.stringValue,
                volumeTotalCapacityBytes: row["volume_total_capacity_bytes_at_capture"]?.int64Value,
                mountPath: row["mount_path_at_capture"]?.stringValue,
                filesystemVariant: row["filesystem_variant"]?.stringValue,
                caseSensitivity: sensitivity
            )
        )
    }
}
