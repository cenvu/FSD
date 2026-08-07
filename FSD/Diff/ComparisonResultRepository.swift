import Foundation

/// Read-side API over stored comparison results: view-ready immutable models,
/// bounded paging, outcome filtering, deterministic difference navigation,
/// and field-level differences. This is the contract the future comparison
/// GUI consumes; no raw database rows or statement handles leave this type.
///
/// Offline by construction: every query is against the catalog, so results
/// stay readable after the sources are removed, ejected or destroyed. Nothing
/// here touches the filesystem or `entry_classifications`.
public final class ComparisonResultRepository: @unchecked Sendable {
    public static let maximumPageSize = 5000

    private let database: CatalogDatabase

    public init(database: CatalogDatabase) {
        self.database = database
    }

    // MARK: - Comparison records

    /// Recent comparisons, newest first. Deterministic: `started_at DESC,
    /// id DESC`. Transient-referencing comparisons appear here too while they
    /// exist; their live sides are labelled by the side descriptors.
    public func listComparisons(limit: Int = 100) throws -> [ComparisonRecord] {
        let bounded = max(1, min(limit, 5000))
        let rows = try database.query(
            "\(Self.recordColumns) ORDER BY c.started_at DESC, c.id DESC LIMIT ?",
            bindings: [.integer(Int64(bounded))]
        )
        return try rows.map(Self.makeRecord)
    }

    public func record(id: ComparisonID) throws -> ComparisonRecord? {
        let rows = try database.query(
            "\(Self.recordColumns) WHERE c.id = ? LIMIT 1",
            bindings: [.integer(id.rawValue)]
        )
        return try rows.first.map(Self.makeRecord)
    }

    public func count() throws -> Int64 {
        try database.scalar("SELECT COUNT(*) FROM comparisons")?.int64Value ?? 0
    }

    /// Per-outcome counts, read from the catalog (the authoritative source).
    public func resultCounts(comparisonID: ComparisonID) throws -> [ComparisonResultType: Int64] {
        let rows = try database.query(
            "SELECT result_type, COUNT(*) AS count FROM comparison_results WHERE comparison_id = ? GROUP BY result_type",
            bindings: [.integer(comparisonID.rawValue)]
        )
        var counts: [ComparisonResultType: Int64] = [:]
        for row in rows {
            guard let raw = row["result_type"]?.stringValue, let type = ComparisonResultType(rawValue: raw) else { continue }
            counts[type] = row["count"]?.int64Value ?? 0
        }
        return counts
    }

    // MARK: - Result rows

    /// One deterministic page. Ordering is `result_path, id` (BINARY path
    /// order, id breaks ties), so a page boundary never reorders or drops a
    /// row and repeated requests return the same page.
    public func results(
        comparisonID: ComparisonID,
        filter: ComparisonResultFilter = .all,
        offset: Int = 0,
        limit: Int = 500
    ) throws -> ComparisonResultPage {
        let bounded = max(1, min(limit, Self.maximumPageSize))
        let safeOffset = max(0, offset)
        let types = filter.types.map(\.rawValue)
        let placeholders = types.map { _ in "?" }.joined(separator: ", ")
        var bindings: [DatabaseValue] = [.integer(comparisonID.rawValue)]
        bindings.append(contentsOf: types.map(DatabaseValue.text))

        let total = try database.scalar(
            "SELECT COUNT(*) FROM comparison_results WHERE comparison_id = ? AND result_type IN (\(placeholders))",
            bindings: bindings
        )?.int64Value ?? 0

        bindings.append(.integer(Int64(bounded)))
        bindings.append(.integer(Int64(safeOffset)))
        let rows = try database.query(
            """
            SELECT id, comparison_id, result_path, display_name, result_type,
                   left_entry_id, right_entry_id, difference_flags
            FROM comparison_results
            WHERE comparison_id = ? AND result_type IN (\(placeholders))
            ORDER BY result_path, id
            LIMIT ? OFFSET ?
            """,
            bindings: bindings
        )
        return ComparisonResultPage(
            comparisonID: comparisonID,
            filter: filter,
            rows: rows.compactMap(Self.makeResultRow),
            offset: safeOffset,
            limit: bounded,
            totalCount: total
        )
    }

    /// Deterministic next/previous navigation over one filter. `anchor` is
    /// the current row's `(result_path, id)`; `nil` navigates to the first
    /// (or last) row of the filtered set. Returns the adjacent row, or `nil`
    /// at the ends — the GUI turns this into next/previous difference
    /// controls without ever loading the whole result set.
    public func navigate(
        comparisonID: ComparisonID,
        filter: ComparisonResultFilter = .differences,
        from anchor: ComparisonResultAnchor?,
        direction: ComparisonDirection,
        limit: Int = 200
    ) throws -> [ComparisonResultRow] {
        let bounded = max(1, min(limit, Self.maximumPageSize))
        let types = filter.types.map(\.rawValue)
        let placeholders = types.map { _ in "?" }.joined(separator: ", ")
        var bindings: [DatabaseValue] = [.integer(comparisonID.rawValue)]
        bindings.append(contentsOf: types.map(DatabaseValue.text))

        let cursor: String
        switch (anchor, direction) {
        case let (.some(anchor), .next):
            cursor = "AND (result_path > ? OR (result_path = ? AND id > ?))"
            bindings += [.text(anchor.resultPath), .text(anchor.resultPath), .integer(anchor.id)]
        case let (.some(anchor), .previous):
            cursor = "AND (result_path < ? OR (result_path = ? AND id < ?))"
            bindings += [.text(anchor.resultPath), .text(anchor.resultPath), .integer(anchor.id)]
        case (nil, .next):
            cursor = ""
        case (nil, .previous):
            cursor = ""
        }
        bindings.append(.integer(Int64(bounded)))
        let ordering = direction == .next ? "ASC" : "DESC"
        let rows = try database.query(
            """
            SELECT id, comparison_id, result_path, display_name, result_type,
                   left_entry_id, right_entry_id, difference_flags
            FROM comparison_results
            WHERE comparison_id = ? AND result_type IN (\(placeholders)) \(cursor)
            ORDER BY result_path \(ordering), id \(ordering)
            LIMIT ?
            """,
            bindings: bindings
        )
        let rowsInCanonicalOrder = direction == .previous ? rows.reversed() : rows
        return rowsInCanonicalOrder.compactMap(Self.makeResultRow)
    }

    public enum ComparisonDirection: Sendable {
        case next
        case previous
    }

    /// The zero-based ordinal position of `anchor` in this filter's canonical
    /// ordering (`result_path, id`). The GUI uses it to materialize the bounded
    /// page containing a row that `navigate` returns outside the currently
    /// loaded page: `offset = (position / pageSize) * pageSize`. Returns `nil`
    /// when the row is not part of the filtered set. Read-only, additive, and
    /// deterministic; ordering semantics are unchanged.
    public func position(
        of anchor: ComparisonResultAnchor,
        comparisonID: ComparisonID,
        filter: ComparisonResultFilter = .all
    ) throws -> Int? {
        let types = filter.types.map(\.rawValue)
        let placeholders = types.map { _ in "?" }.joined(separator: ", ")
        var membership: [DatabaseValue] = [.integer(comparisonID.rawValue)]
        membership.append(contentsOf: types.map(DatabaseValue.text))
        let isMember = try database.scalar(
            """
            SELECT 1 FROM comparison_results
            WHERE comparison_id = ? AND result_type IN (\(placeholders))
              AND result_path = ? AND id = ?
            LIMIT 1
            """,
            bindings: membership + [.text(anchor.resultPath), .integer(anchor.id)]
        )?.int64Value == 1
        guard isMember else { return nil }

        var bindings: [DatabaseValue] = [.integer(comparisonID.rawValue)]
        bindings.append(contentsOf: types.map(DatabaseValue.text))
        bindings += [.text(anchor.resultPath), .text(anchor.resultPath), .integer(anchor.id)]
        let before = try database.scalar(
            """
            SELECT COUNT(*) FROM comparison_results
            WHERE comparison_id = ? AND result_type IN (\(placeholders))
              AND (result_path < ? OR (result_path = ? AND id < ?))
            """,
            bindings: bindings
        )?.int64Value ?? 0
        return Int(before)
    }

    // MARK: - Field-level differences and entry lookup

    /// Decodes one result row's stored field bits into view-ready
    /// differences, reading only the two entries' recorded metadata.
    public func fieldDifferences(for result: ComparisonResultRow, comparisonID: ComparisonID) throws -> [FieldDifference] {
        let fields = result.differenceFields
        guard !fields.isEmpty else { return [] }
        guard let comparison = try record(id: comparisonID) else {
            throw ComparisonError.comparisonNotFound(comparisonID)
        }
        let left = try entryMetadata(id: result.leftEntryID, snapshotID: comparison.left.snapshotID)
        let right = try entryMetadata(id: result.rightEntryID, snapshotID: comparison.right.snapshotID)
        return fields.compactMap { field -> FieldDifference? in
            let leftValue = left?.value(for: field)
            let rightValue = right?.value(for: field)
            return FieldDifference(field: field, leftValue: leftValue, rightValue: rightValue, changed: leftValue != rightValue)
        }
    }

    /// The stored metadata of one side's entry, for the GUI's left/right
    /// entry panes. `nil` when the result row has no entry on that side
    /// (added/removed/group outcomes).
    public func entryMetadata(id: Int64?, snapshotID: SnapshotID) throws -> SideMetadata? {
        guard let id else { return nil }
        let rows = try database.query(
            """
            SELECT id, relative_path, case_preserving_path, case_folded_path, name,
                   file_extension, item_type, logical_size_bytes, allocated_size_bytes,
                   created_at_source, modified_at_source, symlink_target, is_hidden,
                   is_package, is_inaccessible
            FROM entries WHERE snapshot_id = ? AND id = ? LIMIT 1
            """,
            bindings: [.integer(snapshotID.rawValue), .integer(id)]
        )
        guard let row = rows.first, let parsed = Self.parseSideMetadata(from: row) else { return nil }
        return parsed
    }

    // MARK: - Disposal

    /// Deletes one comparison record (results and collision members cascade).
    /// The schema deliberately allows deleting a whole comparison — it is the
    /// explicit disposal API — while individual result rows are immutable
    /// after the terminal state. Deleting a live-side comparison is what
    /// releases its transient snapshots for cleanup (ADR-012).
    public func deleteComparison(_ id: ComparisonID) throws {
        try database.transaction {
            try database.execute("DELETE FROM comparisons WHERE id = ?", bindings: [.integer(id.rawValue)])
        }
    }

    // MARK: - Internals

    private static let recordColumns = """
    SELECT c.id, c.profile_id, c.profile_version, c.status, c.started_at, c.completed_at,
           c.matched_count, c.added_count, c.removed_count, c.changed_count, c.uncertain_count,
           p.name AS profile_name,
           l.id AS left_id, l.snapshot_kind AS left_kind, l.display_name AS left_display_name,
           l.scan_root_name AS left_scan_root_name, l.status AS left_status,
           l.source_case_sensitivity AS left_sensitivity, l.normalization_version AS left_normalization,
           l.warning_count AS left_warning_count, l.mount_path_at_capture AS left_mount_path,
           l.volume_display_name_at_capture AS left_volume_name, l.started_at AS left_started_at,
           r.id AS right_id, r.snapshot_kind AS right_kind, r.display_name AS right_display_name,
           r.scan_root_name AS right_scan_root_name, r.status AS right_status,
           r.source_case_sensitivity AS right_sensitivity, r.normalization_version AS right_normalization,
           r.warning_count AS right_warning_count, r.mount_path_at_capture AS right_mount_path,
           r.volume_display_name_at_capture AS right_volume_name, r.started_at AS right_started_at
    FROM comparisons c
    JOIN comparison_profiles p ON c.profile_id = p.id
    JOIN snapshots l ON c.left_snapshot_id = l.id
    JOIN snapshots r ON c.right_snapshot_id = r.id
    """

    private static func makeRecord(from row: DatabaseRow) throws -> ComparisonRecord {
        guard
            let id = row["id"]?.int64Value,
            let profileID = row["profile_id"]?.int64Value,
            let profileVersion = row["profile_version"]?.int64Value,
            let profileName = row["profile_name"]?.stringValue,
            let statusRaw = row["status"]?.stringValue,
            let status = ComparisonStatus(rawValue: statusRaw),
            let startedAt = row["started_at"]?.stringValue
        else {
            throw ComparisonError.database(.schemaStateInvalid("comparison record row is incomplete"))
        }
        let left = try makeSide(from: row, prefix: "left")
        let right = try makeSide(from: row, prefix: "right")
        return ComparisonRecord(
            id: ComparisonID(rawValue: id),
            mode: ComparisonMode.mode(leftKind: left.kind, rightKind: right.kind),
            left: left,
            right: right,
            profileID: profileID,
            profileName: profileName,
            profileVersion: profileVersion,
            status: status,
            startedAt: startedAt,
            completedAt: row["completed_at"]?.stringValue,
            matchedCount: row["matched_count"]?.int64Value ?? 0,
            addedCount: row["added_count"]?.int64Value ?? 0,
            removedCount: row["removed_count"]?.int64Value ?? 0,
            changedCount: row["changed_count"]?.int64Value ?? 0,
            uncertainCount: row["uncertain_count"]?.int64Value ?? 0,
            warnings: Self.warnings(for: left, right: right)
        )
    }

    private static func makeSide(from row: DatabaseRow, prefix: String) throws -> ComparisonSideDescriptor {
        guard
            let snapshotID = row["\(prefix)_id"]?.int64Value,
            let kindRaw = row["\(prefix)_kind"]?.stringValue,
            let kind = SnapshotKind(rawValue: kindRaw),
            let displayName = row["\(prefix)_display_name"]?.stringValue,
            let scanRootName = row["\(prefix)_scan_root_name"]?.stringValue,
            let statusRaw = row["\(prefix)_status"]?.stringValue,
            let status = SnapshotStatus(rawValue: statusRaw),
            let sensitivityRaw = row["\(prefix)_sensitivity"]?.stringValue,
            let sensitivity = SourceCaseSensitivity(rawValue: sensitivityRaw),
            let normalizationRaw = row["\(prefix)_normalization"]?.stringValue,
            let startedAt = row["\(prefix)_started_at"]?.stringValue
        else {
            throw ComparisonError.database(.schemaStateInvalid("comparison side descriptor is incomplete"))
        }
        return ComparisonSideDescriptor(
            snapshotID: SnapshotID(rawValue: snapshotID),
            kind: kind,
            displayName: displayName,
            scanRootName: scanRootName,
            status: status,
            caseSensitivity: sensitivity,
            normalizationVersion: NormalizationVersion(rawValue: normalizationRaw),
            warningCount: row["\(prefix)_warning_count"]?.int64Value ?? 0,
            mountPath: row["\(prefix)_mount_path"]?.stringValue,
            volumeDisplayName: row["\(prefix)_volume_name"]?.stringValue,
            startedAt: startedAt
        )
    }

    /// The ADR-010 compatibility warnings are deterministic functions of the
    /// stored side facts, so they are re-derived rather than persisted.
    static func warnings(for left: ComparisonSideDescriptor, right: ComparisonSideDescriptor) -> [String] {
        guard !(left.caseSensitivity == .sensitive && right.caseSensitivity == .sensitive) else { return [] }
        var warnings: [String] = []
        if left.caseSensitivity == .unknown {
            warnings.append("Left snapshot's source case sensitivity is unknown; case-folded identity was used (ADR-010).")
        }
        if right.caseSensitivity == .unknown {
            warnings.append("Right snapshot's source case sensitivity is unknown; case-folded identity was used (ADR-010).")
        }
        return warnings
    }

    private static func makeResultRow(from row: DatabaseRow) -> ComparisonResultRow? {
        guard
            let id = row["id"]?.int64Value,
            let comparisonID = row["comparison_id"]?.int64Value,
            let resultPath = row["result_path"]?.stringValue,
            let displayName = row["display_name"]?.stringValue,
            let typeRaw = row["result_type"]?.stringValue,
            let type = ComparisonResultType(rawValue: typeRaw)
        else { return nil }
        return ComparisonResultRow(
            id: id,
            comparisonID: ComparisonID(rawValue: comparisonID),
            resultPath: resultPath,
            displayName: displayName,
            resultType: type,
            leftEntryID: row["left_entry_id"]?.int64Value,
            rightEntryID: row["right_entry_id"]?.int64Value,
            differenceFlags: row["difference_flags"]?.int64Value ?? 0
        )
    }

    private static func parseSideMetadata(from row: DatabaseRow) -> SideMetadata? {
        guard
            let id = row["id"]?.int64Value,
            let relativePath = row["relative_path"]?.stringValue,
            let casePreservingPath = row["case_preserving_path"]?.stringValue,
            let caseFoldedPath = row["case_folded_path"]?.stringValue,
            let name = row["name"]?.stringValue,
            let itemTypeRaw = row["item_type"]?.stringValue,
            let itemKind = FilesystemItemKind(rawValue: itemTypeRaw)
        else { return nil }
        return SideMetadata(
            id: id,
            relativePath: relativePath,
            casePreservingPath: casePreservingPath,
            caseFoldedPath: caseFoldedPath,
            name: name,
            fileExtension: row["file_extension"]?.stringValue,
            itemKind: itemKind,
            logicalSizeBytes: row["logical_size_bytes"]?.int64Value,
            allocatedSizeBytes: row["allocated_size_bytes"]?.int64Value,
            createdAtSource: row["created_at_source"]?.stringValue,
            modifiedAtSource: row["modified_at_source"]?.stringValue,
            symlinkTarget: row["symlink_target"]?.stringValue,
            isHidden: (row["is_hidden"]?.int64Value ?? 0) == 1,
            isPackage: (row["is_package"]?.int64Value ?? 0) == 1,
            isInaccessible: (row["is_inaccessible"]?.int64Value ?? 0) == 1
        )
    }
}
