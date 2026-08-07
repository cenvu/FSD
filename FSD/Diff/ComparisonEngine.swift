import Foundation

/// The metadata comparison engine: one stored snapshot against another.
///
/// Bounded by construction — the two sides are never materialized as trees.
/// Both sides are read as keyset-paged, `ORDER BY <key>, id` streams (the key
/// being `case_preserving_path` when both sources are case-sensitive and
/// `case_folded_path` otherwise, per ADR-010) and merged in lockstep, so only
/// one page per side plus the current key group is ever in memory. Results
/// are persisted in bounded transactions. The same input always produces the
/// same logical result set: ordering, classification and counts are
/// deterministic.
///
/// The engine is metadata-only and offline: it reads `entries` and
/// `snapshots` and writes the comparison tables; it never touches the
/// filesystem, never reads a payload, never consults `entry_classifications`.
public final class ComparisonEngine: @unchecked Sendable {
    public let pageSize: Int
    public let batchSize: Int

    /// KI-019: a single equal-key collision group is materialized in one
    /// array before persistence, so a pathological key must never be allowed
    /// to grow without limit. A group beyond this many members is a typed
    /// failure (`ComparisonError.collisionGroupTooLarge`), never a
    /// memory-bound hazard. Ordinary keys are page-bounded; a legitimate
    /// group is two to a handful of members (case-fold or normalization
    /// collisions), so this ceiling is far above any real key and only
    /// pathological synthetic keys can reach it.
    public static let maxCollisionGroupMemberCount: Int64 = 100_000

    private let database: CatalogDatabase
    private let profiles: ComparisonProfileRepository

    public init(database: CatalogDatabase, pageSize: Int = 5000, batchSize: Int = 2000) {
        self.database = database
        self.pageSize = max(1, pageSize)
        self.batchSize = max(1, batchSize)
        self.profiles = ComparisonProfileRepository(database: database)
    }

    /// Runs one snapshot-to-snapshot comparison and returns the completed
    /// record. Throws `ComparisonError.cancelled` when the token cancels;
    /// the comparison row (if one was already created) is left `cancelled`
    /// with the counts of whatever was persisted — a cancelled comparison is
    /// never `complete`.
    @discardableResult
    public func compare(
        leftSnapshotID: SnapshotID,
        rightSnapshotID: SnapshotID,
        profileID: Int64,
        token: ComparisonCancellationToken = ComparisonCancellationToken(),
        onProgress: @escaping (ComparisonProgress) -> Void = { _ in }
    ) throws -> ComparisonRecord {
        if token.isCancelled { throw ComparisonError.cancelled }

        let left = try loadSide(leftSnapshotID)
        let right = try loadSide(rightSnapshotID)

        guard left.record.normalizationVersion == right.record.normalizationVersion else {
            throw ComparisonError.normalizationMismatch(
                left: left.record.normalizationVersion.rawValue,
                right: right.record.normalizationVersion.rawValue
            )
        }

        guard let profile = try profiles.profile(id: profileID) else {
            throw ComparisonError.profileNotFound(profileID)
        }

        // The compatibility warnings (ADR-010) are re-derived deterministically
        // by the result repository when the record is read back, so the engine
        // only needs the selected key column here.
        let (keyColumn, _) = Self.selectedKey(left: left.record, right: right.record)
        let comparisonID: ComparisonID
        do {
            comparisonID = try createComparison(
                leftSnapshotID: leftSnapshotID,
                rightSnapshotID: rightSnapshotID,
                profile: profile
            )
        } catch let error as CatalogDatabaseError {
            throw ComparisonError.database(error)
        }
        onProgress(ComparisonProgress(processedEntries: 0, phase: "Matching"))

        do {
            try merge(
                comparisonID: comparisonID.rawValue,
                left: left,
                right: right,
                keyColumn: keyColumn,
                profile: profile,
                token: token,
                onProgress: onProgress
            )
            try terminalize(comparisonID: comparisonID, status: .complete, token: token)
        } catch let error as ComparisonError where error == .cancelled {
            try? terminalize(comparisonID: comparisonID, status: .cancelled, token: token)
            throw error
        } catch let error as CatalogDatabaseError {
            try? terminalize(comparisonID: comparisonID, status: .failed, token: token)
            throw ComparisonError.database(error)
        } catch {
            try? terminalize(comparisonID: comparisonID, status: .failed, token: token)
            throw error
        }

        let results = ComparisonResultRepository(database: database)
        guard let record = try results.record(id: comparisonID) else {
            throw ComparisonError.database(.schemaStateInvalid("comparison row vanished after completion"))
        }
        return record
    }

    // MARK: - Sides and policy

    private struct Side {
        let record: SnapshotSummary
        let snapshotID: SnapshotID
    }

    private func loadSide(_ id: SnapshotID) throws -> Side {
        let history = SnapshotHistoryRepository(database: database)
        guard let record = try history.summary(id: id) else {
            throw ComparisonError.snapshotNotFound(id)
        }
        guard record.isComplete else {
            throw ComparisonError.ineligibleSnapshot(
                id,
                record.status,
                "Only complete or complete-with-warnings snapshots may participate; scanning, interrupted, cancelled and failed snapshots are excluded."
            )
        }
        return Side(record: record, snapshotID: id)
    }

    /// ADR-010: both sources sensitive → case-preserving key; otherwise
    /// case-folded, with an explicit compatibility warning for `unknown`.
    static func selectedKey(left: SnapshotSummary, right: SnapshotSummary) -> (column: String, warnings: [String]) {
        if left.capture.caseSensitivity == .sensitive && right.capture.caseSensitivity == .sensitive {
            return ("case_preserving_path", [])
        }
        var warnings: [String] = []
        if left.capture.caseSensitivity == .unknown {
            warnings.append("Left snapshot's source case sensitivity is unknown; case-folded identity was used (ADR-010).")
        }
        if right.capture.caseSensitivity == .unknown {
            warnings.append("Right snapshot's source case sensitivity is unknown; case-folded identity was used (ADR-010).")
        }
        return ("case_folded_path", warnings)
    }

    private func createComparison(leftSnapshotID: SnapshotID, rightSnapshotID: SnapshotID, profile: ComparisonProfile) throws -> ComparisonID {
        try database.transaction {
            try database.execute(
                """
                INSERT INTO comparisons (
                    left_snapshot_id, right_snapshot_id, profile_id, profile_version,
                    status, started_at, created_at
                ) VALUES (?, ?, ?, ?, 'running', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """,
                bindings: [
                    .integer(leftSnapshotID.rawValue), .integer(rightSnapshotID.rawValue),
                    .integer(profile.id), .integer(profile.version)
                ]
            )
            return ComparisonID(rawValue: try database.lastInsertRowID())
        }
    }

    // MARK: - Merge traversal

    private struct PendingResult: Sendable {
        let path: String
        let name: String
        let type: ComparisonResultType
        let leftID: Int64?
        let rightID: Int64?
        let flags: Int64
    }

    private struct PendingCollisionGroup: Sendable {
        let path: String
        let members: [(side: String, entryID: Int64)]
    }

    private func merge(
        comparisonID: Int64,
        left: Side,
        right: Side,
        keyColumn: String,
        profile: ComparisonProfile,
        token: ComparisonCancellationToken,
        onProgress: @escaping (ComparisonProgress) -> Void
    ) throws {
        let leftStream = try EntryStream(database: database, snapshotID: left.snapshotID, keyColumn: keyColumn, pageSize: pageSize)
        let rightStream = try EntryStream(database: database, snapshotID: right.snapshotID, keyColumn: keyColumn, pageSize: pageSize)

        var pending: [PendingResult] = []
        var groups: [PendingCollisionGroup] = []
        var processed: Int64 = 0

        func flushIfNeeded() throws {
            if pending.count + groups.count >= batchSize {
                try persist(comparisonID: comparisonID, results: pending, groups: groups)
                pending.removeAll(keepingCapacity: true)
                groups.removeAll(keepingCapacity: true)
                onProgress(ComparisonProgress(processedEntries: processed, phase: "Persisting"))
            }
        }

        while let leftRow = leftStream.current, let rightRow = rightStream.current {
            if token.isCancelled { throw ComparisonError.cancelled }
            let leftKey = Self.key(of: leftRow, column: keyColumn)
            let rightKey = Self.key(of: rightRow, column: keyColumn)
            let order = Self.compareKeys(leftKey, rightKey)
            if order < 0 {
                emitOnly(leftRow, side: "left", keyColumn: keyColumn, profile: profile, into: &pending)
                processed += 1
                try leftStream.advance()
            } else if order > 0 {
                emitOnly(rightRow, side: "right", keyColumn: keyColumn, profile: profile, into: &pending)
                processed += 1
                try rightStream.advance()
            } else {
                let leftGroup = try leftStream.consumeGroup(key: leftKey, keyColumn: keyColumn)
                let rightGroup = try rightStream.consumeGroup(key: rightKey, keyColumn: keyColumn)
                processed += Int64(leftGroup.count + rightGroup.count)
                emitGroup(
                    left: leftGroup, right: rightGroup, key: leftKey, keyColumn: keyColumn,
                    profile: profile, into: &pending, groups: &groups
                )
            }
            try flushIfNeeded()
        }

        // One side exhausted: every remaining row on the other side is a
        // one-sided outcome (added / removed / ignored / uncertain).
        if leftStream.current == nil {
            while let row = rightStream.current {
                if token.isCancelled { throw ComparisonError.cancelled }
                emitOnly(row, side: "right", keyColumn: keyColumn, profile: profile, into: &pending)
                processed += 1
                try rightStream.advance()
                try flushIfNeeded()
            }
        } else {
            while let row = leftStream.current {
                if token.isCancelled { throw ComparisonError.cancelled }
                emitOnly(row, side: "left", keyColumn: keyColumn, profile: profile, into: &pending)
                processed += 1
                try leftStream.advance()
                try flushIfNeeded()
            }
        }

        if !pending.isEmpty || !groups.isEmpty {
            try persist(comparisonID: comparisonID, results: pending, groups: groups)
        }
        onProgress(ComparisonProgress(processedEntries: processed, phase: "Finalizing"))
    }

    /// One-sided outcome. The left side is the reference ("before") tree, so
    /// an entry present only on the left is `removed` and an entry present
    /// only on the right is `added`. A profile-ignored entry becomes an
    /// `ignored` row (it is outside the compared universe, recorded for
    /// transparency); an inaccessible entry becomes `uncertain` — its
    /// recorded metadata is not a trustworthy picture, so no safe conclusion
    /// exists even though its identity is known.
    private func emitOnly(
        _ row: SideMetadata,
        side: String,
        keyColumn: String,
        profile: ComparisonProfile,
        into pending: inout [PendingResult]
    ) {
        _ = keyColumn
        if profile.isIgnored(row) {
            pending.append(PendingResult(
                path: row.relativePath, name: row.name, type: .ignored,
                leftID: side == "left" ? row.id : nil, rightID: side == "right" ? row.id : nil, flags: 0
            ))
            return
        }
        if row.isInaccessible {
            pending.append(PendingResult(
                path: row.relativePath, name: row.name, type: .uncertain,
                leftID: side == "left" ? row.id : nil, rightID: side == "right" ? row.id : nil, flags: 0
            ))
            return
        }
        pending.append(PendingResult(
            path: row.relativePath, name: row.name, type: side == "left" ? .removed : .added,
            leftID: side == "left" ? row.id : nil, rightID: side == "right" ? row.id : nil, flags: 0
        ))
    }

    /// The decision for one comparison key shared by both sides.
    ///
    /// * every ignored member is recorded as `ignored` (rule and hidden
    ///   decisions are per entry; hidden state can differ between two entries
    ///   that fold to the same key, so the decision is made per member);
    /// * exactly one eligible member on each side → a pair: `matched` when no
    ///   profile field differs, `changed` with the field bits otherwise, and
    ///   `uncertain` when either member is inaccessible;
    /// * more than one eligible member on either side → a collision group
    ///   (ADR-010): members are recorded in `comparison_collision_members`
    ///   and never paired arbitrarily; the key gets one empty `uncertain`
    ///   result row;
    /// * eligible members on only one side (the other side's members are all
    ///   ignored — only possible through differing hidden state) → one-sided
    ///   outcomes, with the ignored rows documenting the exclusion.
    private func emitGroup(
        left: [SideMetadata],
        right: [SideMetadata],
        key: String,
        keyColumn: String,
        profile: ComparisonProfile,
        into pending: inout [PendingResult],
        groups: inout [PendingCollisionGroup]
    ) {
        let leftIgnored = left.filter { profile.isIgnored($0) }
        let rightIgnored = right.filter { profile.isIgnored($0) }
        let leftEligible = left.filter { !profile.isIgnored($0) }
        let rightEligible = right.filter { !profile.isIgnored($0) }

        for entry in leftIgnored {
            pending.append(PendingResult(
                path: entry.relativePath, name: entry.name, type: .ignored,
                leftID: entry.id, rightID: nil, flags: 0
            ))
        }
        for entry in rightIgnored {
            pending.append(PendingResult(
                path: entry.relativePath, name: entry.name, type: .ignored,
                leftID: nil, rightID: entry.id, flags: 0
            ))
        }

        switch (leftEligible.count, rightEligible.count) {
        case (1, 1):
            let leftEntry = leftEligible[0]
            let rightEntry = rightEligible[0]
            if leftEntry.isInaccessible || rightEntry.isInaccessible {
                pending.append(PendingResult(
                    path: leftEntry.relativePath, name: leftEntry.name, type: .uncertain,
                    leftID: leftEntry.id, rightID: rightEntry.id, flags: 0
                ))
                return
            }
            let flags = Self.differenceFlags(leftEntry, rightEntry, profile: profile)
            pending.append(PendingResult(
                path: leftEntry.relativePath, name: leftEntry.name,
                type: flags == 0 ? .matched : .changed,
                leftID: leftEntry.id, rightID: rightEntry.id, flags: flags
            ))
        case (0, _), (_, 0):
            for entry in leftEligible { emitOnly(entry, side: "left", keyColumn: keyColumn, profile: profile, into: &pending) }
            for entry in rightEligible { emitOnly(entry, side: "right", keyColumn: keyColumn, profile: profile, into: &pending) }
        default:
            // At least two eligible members on one side: ambiguous identity.
            // Never pair arbitrarily; record the whole group as one
            // `uncertain` outcome plus explicit collision members.
            var members: [(String, Int64)] = []
            members.append(contentsOf: leftEligible.map { ("left", $0.id) })
            members.append(contentsOf: rightEligible.map { ("right", $0.id) })
            groups.append(PendingCollisionGroup(path: key, members: members))
            pending.append(PendingResult(
                path: key, name: Self.lastComponent(of: key), type: .uncertain,
                leftID: nil, rightID: nil, flags: 0
            ))
        }
    }

    /// Which profile fields differ between a matched pair, as the stored
    /// `difference_flags` bitmask. Timestamps compare within the profile's
    /// tolerance; absent values equal absent values.
    static func differenceFlags(_ left: SideMetadata, _ right: SideMetadata, profile: ComparisonProfile) -> Int64 {
        var flags: Int64 = 0
        for field in ComparisonField.allCases where profile.compares(field) {
            switch field {
            case .itemType:
                if left.itemKind != right.itemKind { flags |= field.flagBit }
            case .logicalSize:
                if left.logicalSizeBytes != right.logicalSizeBytes { flags |= field.flagBit }
            case .allocatedSize:
                if left.allocatedSizeBytes != right.allocatedSizeBytes { flags |= field.flagBit }
            case .modifiedAt:
                if !timestampsEqual(left.modifiedAtSource, right.modifiedAtSource, tolerance: profile.timestampToleranceSeconds) {
                    flags |= field.flagBit
                }
            case .createdAt:
                if !timestampsEqual(left.createdAtSource, right.createdAtSource, tolerance: profile.timestampToleranceSeconds) {
                    flags |= field.flagBit
                }
            }
        }
        return flags
    }

    static func timestampsEqual(_ a: String?, _ b: String?, tolerance: Int64) -> Bool {
        switch (a, b) {
        case (nil, nil):
            return true
        case let (left?, right?):
            // Stored as String(timeIntervalSince1970); unparseable values are
            // compared as strings so the outcome stays deterministic.
            guard let leftValue = Double(left), let rightValue = Double(right) else { return left == right }
            return abs(leftValue - rightValue) <= Double(tolerance)
        default:
            return false
        }
    }

    // MARK: - Persistence

    private func persist(comparisonID: Int64, results: [PendingResult], groups: [PendingCollisionGroup]) throws {
        guard !results.isEmpty || !groups.isEmpty else { return }
        try database.transaction {
            try insertResults(comparisonID: comparisonID, results: results)
            try insertGroups(comparisonID: comparisonID, groups: groups)
        }
    }

    private func insertResults(comparisonID: Int64, results: [PendingResult]) throws {
        let chunkSize = 100
        for start in stride(from: 0, to: results.count, by: chunkSize) {
            let slice = Array(results[start..<min(start + chunkSize, results.count)])
            // Seven placeholders for the seven bound values; parent_result_id
            // is NULL and created_at is CURRENT_TIMESTAMP in SQL.
            let placeholders = slice.map { _ in "(?, NULL, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)" }.joined(separator: ", ")
            var bindings: [DatabaseValue] = []
            bindings.reserveCapacity(slice.count * 7)
            for result in slice {
                bindings.append(.integer(comparisonID))
                bindings.append(.text(result.path))
                bindings.append(.text(result.name))
                bindings.append(.text(result.type.rawValue))
                bindings.append(result.leftID.map(DatabaseValue.integer) ?? .null)
                bindings.append(result.rightID.map(DatabaseValue.integer) ?? .null)
                bindings.append(.integer(result.flags))
            }
            try database.execute(
                """
                INSERT INTO comparison_results (
                    comparison_id, parent_result_id, result_path, display_name,
                    result_type, left_entry_id, right_entry_id, difference_flags, created_at
                ) VALUES \(placeholders)
                """,
                bindings: bindings
            )
        }
    }

    private func insertGroups(comparisonID: Int64, groups: [PendingCollisionGroup]) throws {
        for group in groups {
            try database.execute(
                "INSERT INTO comparison_collision_groups (comparison_id, result_path, created_at) VALUES (?, ?, CURRENT_TIMESTAMP)",
                bindings: [.integer(comparisonID), .text(group.path)]
            )
            let groupID = try database.lastInsertRowID()
            guard !group.members.isEmpty else { continue }
            let placeholders = group.members.map { _ in "(?, ?, ?, CURRENT_TIMESTAMP)" }.joined(separator: ", ")
            var bindings: [DatabaseValue] = []
            bindings.reserveCapacity(group.members.count * 3)
            for member in group.members {
                bindings.append(.integer(groupID))
                bindings.append(.text(member.side))
                bindings.append(.integer(member.entryID))
            }
            try database.execute(
                "INSERT INTO comparison_collision_members (group_id, side, entry_id, created_at) VALUES \(placeholders)",
                bindings: bindings
            )
        }
    }

    /// Terminal transition: status and summary counts commit together, and
    /// the counts are recomputed from the rows actually persisted, so a
    /// cancelled or failed comparison's summary always matches its retained
    /// evidence. The cancellation finalization lock is the same lock the
    /// token's `cancel()` uses, so a late cancel request can never race this
    /// transition into `complete`.
    private func terminalize(comparisonID: ComparisonID, status: ComparisonStatus, token: CaptureCancellationToken) throws {
        try token.withFinalizationLock { cancelled in
            let finalStatus = cancelled ? ComparisonStatus.cancelled : status
            let rows = try database.query(
                "SELECT result_type, COUNT(*) AS count FROM comparison_results WHERE comparison_id = ? GROUP BY result_type",
                bindings: [.integer(comparisonID.rawValue)]
            )
            var counts: [ComparisonResultType: Int64] = [:]
            for row in rows {
                guard let raw = row["result_type"]?.stringValue, let type = ComparisonResultType(rawValue: raw) else { continue }
                counts[type] = row["count"]?.int64Value ?? 0
            }
            try database.transaction {
                try database.execute(
                    """
                    UPDATE comparisons SET
                        status = ?, completed_at = CURRENT_TIMESTAMP,
                        matched_count = ?, added_count = ?, removed_count = ?,
                        changed_count = ?, uncertain_count = ?
                    WHERE id = ? AND status = 'running'
                    """,
                    bindings: [
                        .text(finalStatus.rawValue),
                        .integer(counts[.matched] ?? 0),
                        .integer(counts[.added] ?? 0),
                        .integer(counts[.removed] ?? 0),
                        .integer(counts[.changed] ?? 0),
                        .integer(counts[.uncertain] ?? 0),
                        .integer(comparisonID.rawValue)
                    ]
                )
            }
        }
    }

    // MARK: - Key comparison

    static func key(of row: SideMetadata, column: String) -> String {
        column == "case_preserving_path" ? row.casePreservingPath : row.caseFoldedPath
    }

    /// SQLite orders TEXT with BINARY collation: unsigned UTF-8 byte order.
    /// The streams use exactly that ordering, so the merge must decide "which
    /// side is smaller" the same way. UTF-8 byte order is code-point order,
    /// so comparing the UTF-8 views byte-wise is equivalent to memcmp.
    static func compareKeys(_ a: String, _ b: String) -> Int {
        let left = a.utf8
        let right = b.utf8
        var leftIterator = left.makeIterator()
        var rightIterator = right.makeIterator()
        while let l = leftIterator.next() {
            guard let r = rightIterator.next() else { return 1 }
            if l != r { return l < r ? -1 : 1 }
        }
        return rightIterator.next() == nil ? 0 : -1
    }

    static func lastComponent(of path: String) -> String {
        guard let slash = path.lastIndex(of: "/") else { return path }
        let after = path.index(after: slash)
        return String(path[after...])
    }
}

/// A keyset-paged, ordered read of one snapshot's entries. `current` is the
/// next unprocessed row, `advance()` steps to it, and `consumeGroup(key:)`
/// returns every consecutive row sharing one comparison key. Only one page
/// plus the current group is held in memory; the `(snapshot_id, <key>)`
/// indexes serve the pages, so a 100,000-entry side costs a few page reads,
/// never a materialized tree.
private final class EntryStream {
    private let database: CatalogDatabase
    private let snapshotID: SnapshotID
    private let keyColumn: String
    private let pageSize: Int

    private var page: [SideMetadata] = []
    private var pageIndex = 0
    private var lastKey: String?
    private var lastID: Int64?

    private(set) var current: SideMetadata?

    init(database: CatalogDatabase, snapshotID: SnapshotID, keyColumn: String, pageSize: Int) throws {
        self.database = database
        self.snapshotID = snapshotID
        self.keyColumn = keyColumn
        self.pageSize = pageSize
        try loadNextPage()
        current = page.isEmpty ? nil : page[0]
        pageIndex = 0
    }

    func advance() throws {
        pageIndex += 1
        if pageIndex < page.count {
            current = page[pageIndex]
            return
        }
        try loadNextPage()
        pageIndex = 0
        current = page.isEmpty ? nil : page[0]
    }

    func consumeGroup(key: String, keyColumn: String) throws -> [SideMetadata] {
        var group: [SideMetadata] = []
        while let row = current, ComparisonEngine.key(of: row, column: keyColumn) == key {
            group.append(row)
            // KI-019: the group is held whole until persist; stop well short
            // of letting a pathological key grow without bound. The engine
            // surfaces this as a typed failure (comparison `failed`, never
            // `complete`) instead of exhausting memory.
            if Int64(group.count) > ComparisonEngine.maxCollisionGroupMemberCount {
                throw ComparisonError.collisionGroupTooLarge(Int64(group.count))
            }
            try advance()
        }
        return group
    }

    private func loadNextPage() throws {
        let bindings: [DatabaseValue]
        let predicate: String
        if let lastKey {
            // One pure range on the (snapshot_id, <key>) index: start at the
            // cursor key and filter the boundary key's rows by id. No OR of
            // index terms, so the plan is unambiguous.
            predicate = "AND \(keyColumn) >= ? AND (\(keyColumn) > ? OR id > ?)"
            bindings = [
                .integer(snapshotID.rawValue), .text(lastKey),
                .text(lastKey), .integer(lastID ?? 0), .integer(Int64(pageSize))
            ]
        } else {
            predicate = ""
            bindings = [.integer(snapshotID.rawValue), .integer(Int64(pageSize))]
        }
        let rows = try database.query(
            """
            SELECT id, relative_path, case_preserving_path, case_folded_path, name,
                   file_extension, item_type, logical_size_bytes, allocated_size_bytes,
                   created_at_source, modified_at_source, symlink_target, is_hidden,
                   is_package, is_inaccessible
            FROM entries
            WHERE snapshot_id = ? \(predicate)
            ORDER BY \(keyColumn), id
            LIMIT ?
            """,
            bindings: bindings
        )
        page = rows.compactMap(Self.makeRow)
        // A page can legitimately be empty only at the end of the snapshot;
        // the cursor is left untouched so a retry cannot loop.
        guard let last = page.last else { return }
        lastKey = ComparisonEngine.key(of: last, column: keyColumn)
        lastID = last.id
    }

    private static func makeRow(from row: DatabaseRow) -> SideMetadata? {
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
