import Foundation

public enum CompletionReceiptError: Error, Equatable {
    case invalidEvidence(String)
    case metadataLimit
    case staleComparison
}

/// Tagged SQLite values: JSON never rounds Int64 through Double or conflates
/// NULL, empty TEXT and empty BLOB. BLOB uses Codable's base64 encoding.
public enum CompletionMetadataValue: Codable, Equatable, Sendable {
    case null
    case integer(Int64)
    case text(String)
    case blob(Data)

    init(_ value: DatabaseValue) throws {
        switch value {
        case .null: self = .null
        case .integer(let number): self = .integer(number)
        case .text(let string): self = .text(string)
        case .blob(let data): self = .blob(data)
        case .real: throw CompletionReceiptError.invalidEvidence("Unexpected REAL metadata")
        }
    }
    var integer: Int64? { if case .integer(let n) = self { return n }; return nil }
    var text: String? { if case .text(let s) = self { return s }; return nil }
}

/// v1 pins every column and its SQLite storage type. These are header values
/// observed at COMPLETION; mutable labels/totals/features/issues are not claimed
/// to be new immutable capture-time facts. *_at_capture retains recorded NULL.
public struct CompletionSnapshotEvidence: Codable, Equatable, Sendable {
    public let header: [String: CompletionMetadataValue]
    public let issues: [[String: CompletionMetadataValue]]
}

public struct CompletionProfileDefinition: Codable, Equatable, Sendable {
    public let id: Int64
    public let revision: Int64
    public let name: String
    public let compareItemType: Bool
    public let compareLogicalSize: Bool
    public let compareAllocatedSize: Bool
    public let compareModifiedAt: Bool
    public let compareCreatedAt: Bool
    public let timestampToleranceSeconds: Int64
    public let includeHiddenItems: Bool
    public let ignoreRules: [String]
    public let isBuiltin: Bool

    init(_ profile: ComparisonProfile) {
        id = profile.id; revision = profile.version; name = profile.name
        compareItemType = profile.compareItemType; compareLogicalSize = profile.compareLogicalSize
        compareAllocatedSize = profile.compareAllocatedSize; compareModifiedAt = profile.compareModifiedAt
        compareCreatedAt = profile.compareCreatedAt; timestampToleranceSeconds = profile.timestampToleranceSeconds
        includeHiddenItems = profile.includeHiddenItems; ignoreRules = profile.ignoreRules; isBuiltin = profile.isBuiltin
    }
    func validate() throws {
        guard id > 0, revision > 0, timestampToleranceSeconds >= 0,
              name.utf8.count <= 4096, !name.contains("\0"), ignoreRules.count <= 1000,
              ignoreRules.allSatisfy({ $0.utf8.count <= 4096 && !$0.contains("\0") }),
              ignoreRules.reduce(0, { $0 + $1.utf8.count }) <= 262144 else {
            throw CompletionReceiptError.invalidEvidence("Invalid executed profile")
        }
    }
}

public struct CompletionResultClosure: Codable, Equatable, Sendable {
    /// Includes ignored rows, unlike the five displayed summary counts.
    public let counts: [String: Int64]
    public let resultRows: Int64
    public let collisionGroups: Int64
    public let collisionMembers: Int64
    public let leftEntries: Int64
    public let rightEntries: Int64
    /// SHA256 of length-framed canonical typed persisted metadata, never file
    /// content. Versions below pin row fields, order and validation semantics.
    public let metadataSHA256: String
}

public struct ComparisonCompletionReceipt: Codable, Equatable, Sendable {
    public static let currentVersion = 1
    public static let maximumBytes = 8 * 1024 * 1024
    public static let maximumFieldBytes = 65536
    public static let maximumIssuesPerSide = 10000
    public let version: Int
    public let encoding: String
    public let catalogGeneration: UUID
    public let completionToken: UUID
    public let comparisonID: Int64
    public let status: String
    public let orientation: String
    public let startedAt: String
    public let comparisonCreatedAt: String
    public let completedAt: String
    public let profile: CompletionProfileDefinition
    public let engineVersion: String
    public let identitySelectionVersion: String
    public let ignoreRuleVersion: String
    public let normalizationVersion: String
    public let selectedPathKey: String
    public let warningVersion: String
    public let warnings: [String]
    public let validationVersion: String
    public let left: CompletionSnapshotEvidence
    public let right: CompletionSnapshotEvidence
    public let closure: CompletionResultClosure

    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }
    public func encoded() throws -> Data {
        try validate()
        let data = try Self.encoder().encode(self)
        guard data.count <= Self.maximumBytes else { throw CompletionReceiptError.metadataLimit }
        return data
    }
    public static func decode(_ data: Data) throws -> Self {
        guard !data.isEmpty, data.count <= maximumBytes else { throw CompletionReceiptError.metadataLimit }
        let value = try JSONDecoder().decode(Self.self, from: data)
        try value.validate()
        // A single canonical encoding also rejects unknown fields and duplicate
        // keys, alternative enum forms or noncanonical integer representations.
        guard try encoder().encode(value) == data else { throw CompletionReceiptError.invalidEvidence("Noncanonical receipt encoding") }
        return value
    }
    func validate() throws {
        guard version == 1, encoding == "fsd-receipt-json-utf8-v1", comparisonID > 0,
              status == "complete", orientation == "left-reference_right-changed-v1",
              engineVersion == "fsd-metadata-engine-v1", identitySelectionVersion == "adr010-v1",
              ignoreRuleVersion == "fsd-ignore-glob-v1", warningVersion == "adr010-warning-text-v1",
              validationVersion == "fsd-result-closure-v1", normalizationVersion == NormalizationVersion.current.rawValue,
              ["case_preserving_path", "case_folded_path"].contains(selectedPathKey),
              !startedAt.isEmpty, !comparisonCreatedAt.isEmpty, !completedAt.isEmpty,
              [startedAt,comparisonCreatedAt,completedAt].allSatisfy({ $0.utf8.count <= 65536 && !$0.contains("\0") }) else {
            throw CompletionReceiptError.invalidEvidence("Unsupported completion contract")
        }
        try profile.validate()
        try CompletionEvidenceContract.validate(left)
        try CompletionEvidenceContract.validate(right)
        let selected = try CompletionEvidenceContract.selectedKey(left: left.header, right: right.header)
        guard selectedPathKey == selected.0, warnings == selected.1,
              Set(closure.counts.keys) == Set(ComparisonResultType.allCases.map(\.rawValue)),
              closure.counts.values.allSatisfy({ $0 >= 0 }), closure.resultRows >= 0,
              closure.collisionGroups >= 0, closure.collisionMembers >= 0,
              closure.leftEntries > 0, closure.rightEntries > 0,
              closure.metadataSHA256.count == 64,
              closure.metadataSHA256.allSatisfy({ "0123456789abcdef".contains($0) }) else {
            throw CompletionReceiptError.invalidEvidence("Invalid completion closure")
        }
        var total: Int64 = 0
        for count in closure.counts.values {
            let (sum,overflow) = total.addingReportingOverflow(count)
            guard !overflow else { throw CompletionReceiptError.invalidEvidence("Count overflow") }; total = sum
        }
        guard total == closure.resultRows else { throw CompletionReceiptError.invalidEvidence("Contradictory counts") }
    }
}

/// Private fixed v1 SQL row schemas, not an extensible provider contract.
enum CompletionEvidenceContract {
    static func hexUTF8(_ value: String) -> String {
        let digits = Array("0123456789ABCDEF".utf8)
        var bytes: [UInt8] = []; bytes.reserveCapacity(value.utf8.count * 2)
        for byte in value.utf8 { bytes.append(digits[Int(byte >> 4)]); bytes.append(digits[Int(byte & 15)]) }
        return String(decoding:bytes,as:UTF8.self)
    }
    static let snapshotColumns: [String: String] = [
        "id": "integer",
        "volume_id": "integer",
        "session_number": "integer",
        "scan_root_name": "text",
        "mount_path_at_capture": "text",
        "root_relative_path": "text",
        "status": "text",
        "scanner_version": "text",
        "schema_version": "integer",
        "normalization_version": "text",
        "snapshot_kind": "text",
        "source_case_sensitivity": "text",
        "filesystem_provider": "text",
        "provider_version": "text",
        "source_access_mode": "text",
        "device_identifier": "text",
        "partition_identifier": "text",
        "partition_offset": "integer",
        "partition_length": "integer",
        "filesystem_variant": "text",
        "filesystem_features_json": "text",
        "authorization_required": "integer",
        "collection_id": "integer",
        "display_name": "text",
        "user_note": "text",
        "capture_policy_json": "text",
        "started_at": "text",
        "completed_at": "text",
        "duration_ms": "integer",
        "total_files": "integer",
        "total_folders": "integer",
        "total_logical_bytes": "integer",
        "total_allocated_bytes": "integer",
        "inaccessible_items": "integer",
        "warning_count": "integer",
        "root_metadata_signature": "blob",
        "root_subtree_signature": "blob",
        "created_at": "text",
        "updated_at": "text",
        "volume_display_name_at_capture": "text",
        "volume_identifier_at_capture": "text",
        "volume_total_capacity_bytes_at_capture": "integer"
    ]
    static let snapshotRequired = Set(["id", "volume_id", "session_number", "scan_root_name", "root_relative_path", "status", "scanner_version", "schema_version", "normalization_version", "snapshot_kind", "source_case_sensitivity", "filesystem_provider", "source_access_mode", "authorization_required", "display_name", "capture_policy_json", "started_at", "total_files", "total_folders", "total_logical_bytes", "total_allocated_bytes", "inaccessible_items", "warning_count", "created_at", "updated_at"])
    static let issueColumns: [String: String] = [
        "id": "integer",
        "snapshot_id": "integer",
        "entry_id": "integer",
        "relative_path": "text",
        "error_domain": "text",
        "error_code": "integer",
        "severity": "text",
        "source": "text",
        "message": "text",
        "was_skipped": "integer",
        "created_at": "text"
    ]
    static let issueRequired = Set(["id", "snapshot_id", "relative_path", "severity", "source", "message", "was_skipped", "created_at"])
    static func validateRow(_ row: [String:CompletionMetadataValue], columns: [String:String], required: Set<String>) throws {
        guard Set(row.keys) == Set(columns.keys) else { throw CompletionReceiptError.invalidEvidence("Incomplete metadata row") }
        for (name,value) in row {
            switch value {
            case .null:
                guard !required.contains(name) else { throw CompletionReceiptError.invalidEvidence("Missing required metadata") }
            case .integer:
                guard columns[name] == "integer" else { throw CompletionReceiptError.invalidEvidence("Metadata type mismatch") }
            case .text(let text):
                guard columns[name] == "text", !text.contains("\0") else { throw CompletionReceiptError.invalidEvidence("Invalid metadata text") }
                guard text.utf8.count <= ComparisonCompletionReceipt.maximumFieldBytes else { throw CompletionReceiptError.metadataLimit }
            case .blob(let data):
                guard columns[name] == "blob" else { throw CompletionReceiptError.invalidEvidence("Metadata type mismatch") }
                guard data.count <= ComparisonCompletionReceipt.maximumFieldBytes else { throw CompletionReceiptError.metadataLimit }
            }
        }
    }
    static func validate(_ side: CompletionSnapshotEvidence) throws {
        try validateRow(side.header, columns: snapshotColumns, required: snapshotRequired)
        guard let id = side.header["id"]?.integer, id > 0,
              ["complete","complete_with_warnings"].contains(side.header["status"]?.text ?? ""),
              side.header["normalization_version"]?.text == NormalizationVersion.current.rawValue,
              side.issues.count <= ComparisonCompletionReceipt.maximumIssuesPerSide else { throw CompletionReceiptError.invalidEvidence("Invalid completed side") }
        var previous: Int64 = 0
        for issue in side.issues {
            try validateRow(issue, columns: issueColumns, required: issueRequired)
            guard let issueID = issue["id"]?.integer, issueID > previous,
                  issue["snapshot_id"]?.integer == id,
                  ["info","warning","error"].contains(issue["severity"]?.text ?? ""),
                  ["scanner","reader"].contains(issue["source"]?.text ?? ""),
                  [0,1].contains(issue["was_skipped"]?.integer ?? -1) else { throw CompletionReceiptError.invalidEvidence("Invalid issue ownership") }
            previous = issueID
        }
    }
    static func selectedKey(left: [String:CompletionMetadataValue], right: [String:CompletionMetadataValue]) throws -> (String,[String]) {
        guard let l = left["source_case_sensitivity"]?.text, let r = right["source_case_sensitivity"]?.text,
              ["sensitive","insensitive","unknown"].contains(l), ["sensitive","insensitive","unknown"].contains(r) else { throw CompletionReceiptError.invalidEvidence("Unknown case contract") }
        if l == "sensitive" && r == "sensitive" { return ("case_preserving_path",[]) }
        var warnings: [String] = []
        if l == "unknown" { warnings.append("Left snapshot's source case sensitivity is unknown; case-folded identity was used (ADR-010).") }
        if r == "unknown" { warnings.append("Right snapshot's source case sensitivity is unknown; case-folded identity was used (ADR-010).") }
        return ("case_folded_path",warnings)
    }
}
