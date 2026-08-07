import Foundation

public struct MetadataSearchQuery: Equatable, Sendable {
    public enum Field: String, CaseIterable, Sendable {
        case nameOrPath
        case name
        case path

        public var label: String {
            switch self {
            case .nameOrPath: return "Name or path"
            case .name: return "Name"
            case .path: return "Path"
            }
        }
    }

    public enum HiddenFilter: String, CaseIterable, Sendable {
        case any
        case only
        case exclude

        public var label: String {
            switch self {
            case .any: return "Include hidden"
            case .only: return "Hidden only"
            case .exclude: return "Exclude hidden"
            }
        }
    }

    public var text: String
    public var field: Field
    public var fileExtension: String?
    public var itemKinds: Set<FilesystemItemKind>
    public var hidden: HiddenFilter
    public var inaccessibleOnly: Bool
    public var minimumLogicalSizeBytes: Int64?
    public var maximumLogicalSizeBytes: Int64?
    public var limit: Int

    public init(
        text: String = "",
        field: Field = .nameOrPath,
        fileExtension: String? = nil,
        itemKinds: Set<FilesystemItemKind> = [],
        hidden: HiddenFilter = .any,
        inaccessibleOnly: Bool = false,
        minimumLogicalSizeBytes: Int64? = nil,
        maximumLogicalSizeBytes: Int64? = nil,
        limit: Int = 500
    ) {
        self.text = text
        self.field = field
        self.fileExtension = fileExtension
        self.itemKinds = itemKinds
        self.hidden = hidden
        self.inaccessibleOnly = inaccessibleOnly
        self.minimumLogicalSizeBytes = minimumLogicalSizeBytes
        self.maximumLogicalSizeBytes = maximumLogicalSizeBytes
        self.limit = limit
    }

    /// True when the query would match everything, which the UI treats as "no
    /// search" rather than issuing a whole-snapshot scan.
    public var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (fileExtension?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            && itemKinds.isEmpty
            && hidden == .any
            && !inaccessibleOnly
            && minimumLogicalSizeBytes == nil
            && maximumLogicalSizeBytes == nil
    }
}

public struct MetadataSearchHit: Identifiable, Hashable, Sendable {
    public let id: Int64
    public let snapshotID: SnapshotID
    public let parentID: Int64?
    public let relativePath: String
    public let name: String
    public let fileExtension: String?
    public let itemKind: FilesystemItemKind
    public let logicalSizeBytes: Int64?
    public let isHidden: Bool
    public let isInaccessible: Bool
    /// Set from one bounded follow-up query over the hits actually returned,
    /// never from a correlated subquery across the whole snapshot.
    public var hasScanIssue: Bool
}

public struct MetadataSearchResults: Sendable {
    /// Always carried with the results: a hit is meaningless without knowing
    /// which snapshot it came from.
    public let snapshotID: SnapshotID
    public let query: MetadataSearchQuery
    public let hits: [MetadataSearchHit]
    public let limit: Int
    public let durationSeconds: Double

    /// True when the result set hit `limit`. The caller must not present a
    /// truncated list as a complete answer.
    public var isTruncated: Bool { hits.count >= limit }
}

/// Offline metadata search over one stored snapshot.
///
/// SQLite only: no source access, no file contents, no classification. The
/// `entry_classifications` table is never referenced here, and there is no code
/// path that could read a byte of a scanned file — search answers questions
/// about recorded metadata and says nothing about content.
/// Search keeps no mutable request state on the service. Each request uses
/// local values and all SQLite access is serialized by `CatalogDatabase`.
public final class MetadataSearchService: @unchecked Sendable {
    public static let maximumLimit = 5000

    private let database: CatalogDatabase

    public init(database: CatalogDatabase) {
        self.database = database
    }

    public func search(_ query: MetadataSearchQuery, in snapshotID: SnapshotID) throws -> MetadataSearchResults {
        let started = Date()
        let limit = max(1, min(query.limit, Self.maximumLimit))
        var conditions = ["snapshot_id = ?"]
        var bindings: [DatabaseValue] = [.integer(snapshotID.rawValue)]

        let text = query.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            // Fold the needle the same way the haystack was folded at capture
            // time (ADR-009), so `CAFÉ`, `café` and its decomposed form all
            // match the one stored key.
            let pattern = "%" + Self.escapeLikePattern(PathIdentity.caseFold(text)) + "%"
            switch query.field {
            case .name:
                conditions.append("case_folded_name LIKE ? ESCAPE '\\'")
                bindings.append(.text(pattern))
            case .path:
                conditions.append("case_folded_path LIKE ? ESCAPE '\\'")
                bindings.append(.text(pattern))
            case .nameOrPath:
                conditions.append("(case_folded_name LIKE ? ESCAPE '\\' OR case_folded_path LIKE ? ESCAPE '\\')")
                bindings.append(.text(pattern))
                bindings.append(.text(pattern))
            }
        }

        if let rawExtension = query.fileExtension?.trimmingCharacters(in: .whitespacesAndNewlines), !rawExtension.isEmpty {
            let normalized = PathIdentity.caseFold(rawExtension.hasPrefix(".") ? String(rawExtension.dropFirst()) : rawExtension)
            conditions.append("file_extension IS NOT NULL AND LOWER(file_extension) = ?")
            bindings.append(.text(normalized))
        }

        if !query.itemKinds.isEmpty {
            let kinds = query.itemKinds.map(\.rawValue).sorted()
            let placeholders = kinds.map { _ in "?" }.joined(separator: ", ")
            conditions.append("item_type IN (\(placeholders))")
            bindings.append(contentsOf: kinds.map(DatabaseValue.text))
        }

        switch query.hidden {
        case .any: break
        case .only: conditions.append("is_hidden = 1")
        case .exclude: conditions.append("is_hidden = 0")
        }

        if query.inaccessibleOnly {
            conditions.append("is_inaccessible = 1")
        }

        if let minimum = query.minimumLogicalSizeBytes {
            conditions.append("logical_size_bytes IS NOT NULL AND logical_size_bytes >= ?")
            bindings.append(.integer(minimum))
        }
        if let maximum = query.maximumLogicalSizeBytes {
            conditions.append("logical_size_bytes IS NOT NULL AND logical_size_bytes <= ?")
            bindings.append(.integer(maximum))
        }

        bindings.append(.integer(Int64(limit)))
        let rows = try database.query(
            """
            SELECT id, parent_id, relative_path, name, file_extension, item_type,
                   logical_size_bytes, is_hidden, is_inaccessible
            FROM entries
            WHERE \(conditions.joined(separator: " AND "))
            ORDER BY case_folded_path, id
            LIMIT ?
            """,
            bindings: bindings
        )

        var hits = rows.compactMap { row -> MetadataSearchHit? in
            guard
                let id = row["id"]?.int64Value,
                let relativePath = row["relative_path"]?.stringValue,
                let name = row["name"]?.stringValue,
                let itemTypeRaw = row["item_type"]?.stringValue,
                let itemKind = FilesystemItemKind(rawValue: itemTypeRaw)
            else { return nil }
            return MetadataSearchHit(
                id: id,
                snapshotID: snapshotID,
                parentID: row["parent_id"]?.int64Value,
                relativePath: relativePath,
                name: name,
                fileExtension: row["file_extension"]?.stringValue,
                itemKind: itemKind,
                logicalSizeBytes: row["logical_size_bytes"]?.int64Value,
                isHidden: (row["is_hidden"]?.int64Value ?? 0) == 1,
                isInaccessible: (row["is_inaccessible"]?.int64Value ?? 0) == 1,
                hasScanIssue: false
            )
        }

        try annotateScanIssues(&hits, snapshotID: snapshotID)

        return MetadataSearchResults(
            snapshotID: snapshotID,
            query: query,
            hits: hits,
            limit: limit,
            durationSeconds: Date().timeIntervalSince(started)
        )
    }

    /// One extra query bounded by the number of hits already returned.
    private func annotateScanIssues(_ hits: inout [MetadataSearchHit], snapshotID: SnapshotID) throws {
        guard !hits.isEmpty else { return }
        let placeholders = hits.map { _ in "?" }.joined(separator: ", ")
        var bindings: [DatabaseValue] = [.integer(snapshotID.rawValue)]
        bindings.append(contentsOf: hits.map { .integer($0.id) })
        let rows = try database.query(
            "SELECT DISTINCT entry_id FROM scan_issues WHERE snapshot_id = ? AND entry_id IN (\(placeholders))",
            bindings: bindings
        )
        let flagged = Set(rows.compactMap { $0["entry_id"]?.int64Value })
        guard !flagged.isEmpty else { return }
        for index in hits.indices where flagged.contains(hits[index].id) {
            hits[index].hasScanIssue = true
        }
    }

    /// `LIKE` treats `%` and `_` as wildcards, so a user searching for a literal
    /// underscore must not silently match every single character.
    static func escapeLikePattern(_ value: String) -> String {
        var escaped = ""
        escaped.reserveCapacity(value.count)
        for character in value {
            if character == "\\" || character == "%" || character == "_" {
                escaped.append("\\")
            }
            escaped.append(character)
        }
        return escaped
    }
}
