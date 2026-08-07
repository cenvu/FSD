import Foundation

public struct SnapshotTreeNode: Identifiable, Hashable, Sendable {
    public let id: Int64
    public let snapshotID: SnapshotID
    public let parentID: Int64?
    public let name: String
    public let relativePath: String
    public let itemKind: FilesystemItemKind
    public let logicalSizeBytes: Int64?
    public let isHidden: Bool
    public let isPackage: Bool
    public let isInaccessible: Bool
    /// Resolved by the same query that produced the row, so expanding a branch
    /// never needs a second round trip just to decide whether it can expand.
    public let hasChildren: Bool

    public var isExpandable: Bool { hasChildren }
}

public struct SnapshotEntryDetails: Hashable, Sendable {
    public let id: Int64
    public let relativePath: String
    public let name: String
    public let casePreservingPath: String
    public let caseFoldedPath: String
    public let fileExtension: String?
    public let itemKind: FilesystemItemKind
    public let logicalSizeBytes: Int64?
    public let allocatedSizeBytes: Int64?
    public let createdAtSource: String?
    public let modifiedAtSource: String?
    public let contentTypeIdentifier: String?
    public let symlinkTarget: String?
    public let isHidden: Bool
    public let isPackage: Bool
    public let isInaccessible: Bool
    public let classification: EntryClassification?
}

/// Bounded, offline access to one snapshot's stored tree.
///
/// The contract is that opening a snapshot reads the root row and nothing else,
/// and expanding a directory reads that directory's direct children and nothing
/// else. There is no query here that can return a subtree, so no caller can
/// accidentally materialise one — including the UI, which holds no tree of its
/// own beyond the rows currently on screen.
///
/// Every query is filtered by `snapshot_id` and served by
/// `idx_entries_snapshot_parent_sort`, and every multi-row query is bounded by
/// `LIMIT`. Nothing in this type touches the filesystem: a snapshot browses
/// identically whether its source is connected, ejected or destroyed.
public final class SnapshotTreeDataSource {
    public let snapshotID: SnapshotID
    public let pageSize: Int

    private let database: CatalogDatabase
    private let classifications: EntryClassificationRepository
    private let counters = NSLock()
    private var queries = 0
    private var rows = 0
    private var generationValue: UInt64 = 0

    public init(database: CatalogDatabase, snapshotID: SnapshotID, pageSize: Int = 500) {
        self.database = database
        self.classifications = EntryClassificationRepository(database: database)
        self.snapshotID = snapshotID
        self.pageSize = max(1, pageSize)
    }

    // MARK: - Instrumentation
    //
    // Cheap counters, kept in production rather than in a test shim, so that
    // "expanding one directory fetched N rows" is something the app can be
    // asked at any time instead of something a test has to infer.

    public var queryCount: Int {
        counters.lock(); defer { counters.unlock() }
        return queries
    }

    public var rowsFetched: Int {
        counters.lock(); defer { counters.unlock() }
        return rows
    }

    public func resetInstrumentation() {
        counters.lock(); defer { counters.unlock() }
        queries = 0
        rows = 0
    }

    /// Increments when the caller abandons in-flight work — for example the user
    /// selecting a different snapshot or collapsing a branch mid-load. A result
    /// carrying a stale generation is discarded rather than applied.
    @discardableResult
    public func invalidate() -> UInt64 {
        counters.lock(); defer { counters.unlock() }
        generationValue += 1
        return generationValue
    }

    public var generation: UInt64 {
        counters.lock(); defer { counters.unlock() }
        return generationValue
    }

    public func isCurrent(_ generation: UInt64) -> Bool {
        counters.lock(); defer { counters.unlock() }
        return generation == generationValue
    }

    // MARK: - Queries

    /// The snapshot's single root row. This is all that opening a snapshot reads.
    public func root() throws -> SnapshotTreeNode? {
        let result = try query(
            """
            \(Self.nodeColumns)
            WHERE e.snapshot_id = ? AND e.parent_id IS NULL
            ORDER BY e.sort_key, e.id LIMIT 1
            """,
            bindings: [.integer(snapshotID.rawValue)]
        )
        return result.first
    }

    public func childCount(ofParent parentID: Int64) throws -> Int {
        countQuery(1)
        let value = try database.scalar(
            "SELECT COUNT(*) FROM entries WHERE snapshot_id = ? AND parent_id = ?",
            bindings: [.integer(snapshotID.rawValue), .integer(parentID)]
        )?.int64Value ?? 0
        return Int(value)
    }

    /// Direct children only. There is no recursive variant by design.
    ///
    /// Ordering is `sort_key` then `id`; `sort_key` is the normalised folded path
    /// (ADR-009), and `id` breaks the ties two names can produce under case or
    /// Unicode folding, so a page boundary never reorders or drops a sibling.
    public func children(ofParent parentID: Int64, offset: Int = 0, limit: Int? = nil) throws -> [SnapshotTreeNode] {
        let bounded = max(1, min(limit ?? pageSize, pageSize))
        return try query(
            """
            \(Self.nodeColumns)
            WHERE e.snapshot_id = ? AND e.parent_id = ?
            ORDER BY e.sort_key, e.id LIMIT ? OFFSET ?
            """,
            bindings: [
                .integer(snapshotID.rawValue), .integer(parentID),
                .integer(Int64(bounded)), .integer(Int64(max(0, offset)))
            ]
        )
    }

    public func node(id entryID: Int64) throws -> SnapshotTreeNode? {
        try query(
            "\(Self.nodeColumns) WHERE e.snapshot_id = ? AND e.id = ? LIMIT 1",
            bindings: [.integer(snapshotID.rawValue), .integer(entryID)]
        ).first
    }

    public func details(for entryID: Int64) throws -> SnapshotEntryDetails? {
        countQuery(1)
        let result = try database.query(
            """
            SELECT id, relative_path, name, case_preserving_path, case_folded_path,
                   file_extension, item_type, logical_size_bytes, allocated_size_bytes,
                   created_at_source, modified_at_source, content_type_identifier,
                   symlink_target, is_hidden, is_package, is_inaccessible
            FROM entries WHERE snapshot_id = ? AND id = ? LIMIT 1
            """,
            bindings: [.integer(snapshotID.rawValue), .integer(entryID)]
        )
        countRows(result.count)
        guard let row = result.first,
              let id = row["id"]?.int64Value,
              let relativePath = row["relative_path"]?.stringValue,
              let name = row["name"]?.stringValue,
              let casePreservingPath = row["case_preserving_path"]?.stringValue,
              let caseFoldedPath = row["case_folded_path"]?.stringValue,
              let itemTypeRaw = row["item_type"]?.stringValue,
              let itemKind = FilesystemItemKind(rawValue: itemTypeRaw)
        else { return nil }
        countQuery(1)
        let classification = try classifications.classification(for: id)
        countRows(classification == nil ? 0 : 1)
        return SnapshotEntryDetails(
            id: id,
            relativePath: relativePath,
            name: name,
            casePreservingPath: casePreservingPath,
            caseFoldedPath: caseFoldedPath,
            fileExtension: row["file_extension"]?.stringValue,
            itemKind: itemKind,
            logicalSizeBytes: row["logical_size_bytes"]?.int64Value,
            allocatedSizeBytes: row["allocated_size_bytes"]?.int64Value,
            createdAtSource: row["created_at_source"]?.stringValue,
            modifiedAtSource: row["modified_at_source"]?.stringValue,
            contentTypeIdentifier: row["content_type_identifier"]?.stringValue,
            symlinkTarget: row["symlink_target"]?.stringValue,
            isHidden: (row["is_hidden"]?.int64Value ?? 0) == 1,
            isPackage: (row["is_package"]?.int64Value ?? 0) == 1,
            isInaccessible: (row["is_inaccessible"]?.int64Value ?? 0) == 1,
            classification: classification
        )
    }

    // MARK: - Internals

    private static let nodeColumns = """
    SELECT e.id, e.parent_id, e.name, e.relative_path, e.item_type,
           e.logical_size_bytes, e.is_hidden, e.is_package, e.is_inaccessible,
           EXISTS (SELECT 1 FROM entries c WHERE c.snapshot_id = e.snapshot_id AND c.parent_id = e.id) AS has_children
    FROM entries e
    """

    private func query(_ sql: String, bindings: [DatabaseValue]) throws -> [SnapshotTreeNode] {
        countQuery(1)
        let result = try database.query(sql, bindings: bindings)
        countRows(result.count)
        return result.compactMap(makeNode)
    }

    private func makeNode(from row: DatabaseRow) -> SnapshotTreeNode? {
        guard
            let id = row["id"]?.int64Value,
            let name = row["name"]?.stringValue,
            let relativePath = row["relative_path"]?.stringValue,
            let itemTypeRaw = row["item_type"]?.stringValue,
            let itemKind = FilesystemItemKind(rawValue: itemTypeRaw)
        else { return nil }
        return SnapshotTreeNode(
            id: id,
            snapshotID: snapshotID,
            parentID: row["parent_id"]?.int64Value,
            name: name,
            relativePath: relativePath,
            itemKind: itemKind,
            logicalSizeBytes: row["logical_size_bytes"]?.int64Value,
            isHidden: (row["is_hidden"]?.int64Value ?? 0) == 1,
            isPackage: (row["is_package"]?.int64Value ?? 0) == 1,
            isInaccessible: (row["is_inaccessible"]?.int64Value ?? 0) == 1,
            hasChildren: (row["has_children"]?.int64Value ?? 0) == 1
        )
    }

    private func countQuery(_ amount: Int) {
        counters.lock(); defer { counters.unlock() }
        queries += amount
    }

    private func countRows(_ amount: Int) {
        counters.lock(); defer { counters.unlock() }
        rows += amount
    }
}
