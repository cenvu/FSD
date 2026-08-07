import Foundation

/// Comparison cancellation is the same atomic flag-and-finalization semantics
/// as capture cancellation (`CaptureCancellationToken`): `cancel()` and the
/// terminal decision share one lock, so a late cancel request can never race
/// a comparison into `complete`.
public typealias ComparisonCancellationToken = CaptureCancellationToken

public struct ComparisonID: Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: Int64

    public init(rawValue: Int64) {
        self.rawValue = rawValue
    }

    public var description: String { String(rawValue) }
}

/// The three canonical comparison modes. The mode is fully determined by the
/// two sides' `SnapshotKind` values: both `user` is snapshot-to-snapshot, one
/// `transient` is live-to-snapshot, both `transient` is live-to-live. It is
/// therefore derived, never stored — the schema records the sides.
public enum ComparisonMode: String, Codable, CaseIterable, Sendable {
    case snapshotToSnapshot = "snapshot_to_snapshot"
    case liveToSnapshot = "live_to_snapshot"
    case liveToLive = "live_to_live"

    public var label: String {
        switch self {
        case .snapshotToSnapshot: return "Snapshot vs Snapshot"
        case .liveToSnapshot: return "Live vs Snapshot"
        case .liveToLive: return "Live vs Live"
        }
    }

    public static func mode(leftKind: SnapshotKind, rightKind: SnapshotKind) -> ComparisonMode {
        switch (leftKind, rightKind) {
        case (.user, .user): return .snapshotToSnapshot
        case (.transient, .user), (.user, .transient): return .liveToSnapshot
        case (.transient, .transient): return .liveToLive
        }
    }
}

public enum ComparisonStatus: String, Codable, CaseIterable, Sendable {
    case running
    case complete
    case cancelled
    case failed

    public var isTerminal: Bool {
        switch self {
        case .running: return false
        case .complete, .cancelled, .failed: return true
        }
    }
}

/// The canonical outcome set of one compared entry. These are the exact names
/// the schema's `comparison_results.result_type` CHECK constraint defines.
public enum ComparisonResultType: String, Codable, CaseIterable, Sendable {
    case matched
    case added
    case removed
    case changed
    case ignored
    case uncertain
}

/// The metadata fields a profile may compare. This is exactly the field set
/// the schema's `comparison_profiles` columns support; fields such as
/// extension, symlink target or scan-issue state are not compared anywhere.
public enum ComparisonField: String, Codable, CaseIterable, Sendable {
    case itemType = "item_type"
    case logicalSize = "logical_size"
    case allocatedSize = "allocated_size"
    case modifiedAt = "modified_at"
    case createdAt = "created_at"

    /// One bit per field, in canonical order. Stored in
    /// `comparison_results.difference_flags`.
    public var flagBit: Int64 {
        guard let index = Self.allCases.firstIndex(of: self) else { return 0 }
        return Int64(1) << Int64(index)
    }

    public static func fields(for flags: Int64) -> [ComparisonField] {
        allCases.filter { flags & $0.flagBit != 0 }
    }
}

/// One field-level difference between a matched pair. Values are recorded
/// metadata only — sizes and source timestamps — never payload data.
public struct FieldDifference: Hashable, Sendable {
    public let field: ComparisonField
    public let leftValue: String?
    public let rightValue: String?
    public let changed: Bool

    public init(field: ComparisonField, leftValue: String?, rightValue: String?, changed: Bool) {
        self.field = field
        self.leftValue = leftValue
        self.rightValue = rightValue
        self.changed = changed
    }
}

public struct ComparisonProgress: Sendable, Equatable {
    public let processedEntries: Int64
    public let phase: String

    public init(processedEntries: Int64, phase: String) {
        self.processedEntries = processedEntries
        self.phase = phase
    }
}

public enum ComparisonError: Error, LocalizedError, Equatable {
    case database(CatalogDatabaseError)
    case profileNotFound(Int64)
    case snapshotNotFound(SnapshotID)
    case ineligibleSnapshot(SnapshotID, SnapshotStatus, String)
    case normalizationMismatch(left: String, right: String)
    case liveCaptureFailed(SnapshotScannerError)
    case cancelled
    case comparisonNotFound(ComparisonID)
    /// KI-019: a single equal-key collision group materializes in one array
    /// before persistence. A pathological key with an unbounded number of
    /// members is a typed failure, never a memory-bound hazard.
    case collisionGroupTooLarge(Int64)

    public var errorDescription: String? {
        switch self {
        case let .database(error): return error.localizedDescription
        case let .profileNotFound(id): return "Comparison profile \(id) was not found."
        case let .snapshotNotFound(id): return "Snapshot \(id) was not found."
        case let .ineligibleSnapshot(id, status, policy):
            return "Snapshot \(id) is \(status.rawValue) and cannot be compared. \(policy)"
        case let .normalizationMismatch(left, right):
            return "Snapshots use different normalization versions (\(left) vs \(right)) and cannot be compared (ADR-011)."
        case let .liveCaptureFailed(error): return error.localizedDescription
        case .cancelled: return "The comparison was cancelled."
        case let .comparisonNotFound(id): return "Comparison \(id) was not found."
        case let .collisionGroupTooLarge(count):
            return "A single comparison identity has too many members (\(count)) to classify safely. No arbitrary pairing was performed."
        }
    }
}

/// A typed comparison profile. The schema is canonical: exactly the fields
/// below, a stable `id`, a monotonic `version`, and deterministic ignore rules.
public struct ComparisonProfile: Identifiable, Hashable, Sendable {
    public let id: Int64
    public let version: Int64
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

    public init(
        id: Int64,
        version: Int64,
        name: String,
        compareItemType: Bool,
        compareLogicalSize: Bool,
        compareAllocatedSize: Bool,
        compareModifiedAt: Bool,
        compareCreatedAt: Bool,
        timestampToleranceSeconds: Int64,
        includeHiddenItems: Bool,
        ignoreRules: [String],
        isBuiltin: Bool
    ) {
        self.id = id
        self.version = version
        self.name = name
        self.compareItemType = compareItemType
        self.compareLogicalSize = compareLogicalSize
        self.compareAllocatedSize = compareAllocatedSize
        self.compareModifiedAt = compareModifiedAt
        self.compareCreatedAt = compareCreatedAt
        self.timestampToleranceSeconds = timestampToleranceSeconds
        self.includeHiddenItems = includeHiddenItems
        self.ignoreRules = ignoreRules
        self.isBuiltin = isBuiltin
    }

    /// A field participates only when the profile says so. Metadata-only:
    /// no payload, hash, MIME or classification field can ever participate.
    public func compares(_ field: ComparisonField) -> Bool {
        switch field {
        case .itemType: return compareItemType
        case .logicalSize: return compareLogicalSize
        case .allocatedSize: return compareAllocatedSize
        case .modifiedAt: return compareModifiedAt
        case .createdAt: return compareCreatedAt
        }
    }

    /// An entry is outside the compared universe when the profile says so:
    /// a common macOS service file matched by an ignore rule, or a hidden
    /// item excluded by the profile. Hidden items are excluded only when the
    /// profile does not include them; rule-based ignores are deterministic
    /// name/path matches (see `IgnoreRulePattern`).
    public func isIgnored(_ entry: SideMetadata) -> Bool {
        if !includeHiddenItems && entry.isHidden { return true }
        guard !ignoreRules.isEmpty else { return false }
        return ignoreRules.contains { IgnoreRulePattern(pattern: $0).matches(entry) }
    }
}

/// The metadata one compared side reads for an entry — the minimal projection
/// the engine and profiles need, with the identity keys already stored by the
/// scanner (ADR-009). Never carries payload data.
public struct SideMetadata: Hashable, Sendable {
    public let id: Int64
    public let relativePath: String
    public let casePreservingPath: String
    public let caseFoldedPath: String
    public let name: String
    public let fileExtension: String?
    public let itemKind: FilesystemItemKind
    public let logicalSizeBytes: Int64?
    public let allocatedSizeBytes: Int64?
    public let createdAtSource: String?
    public let modifiedAtSource: String?
    public let symlinkTarget: String?
    public let isHidden: Bool
    public let isPackage: Bool
    public let isInaccessible: Bool

    public init(
        id: Int64,
        relativePath: String,
        casePreservingPath: String,
        caseFoldedPath: String,
        name: String,
        fileExtension: String?,
        itemKind: FilesystemItemKind,
        logicalSizeBytes: Int64?,
        allocatedSizeBytes: Int64?,
        createdAtSource: String?,
        modifiedAtSource: String?,
        symlinkTarget: String?,
        isHidden: Bool,
        isPackage: Bool,
        isInaccessible: Bool
    ) {
        self.id = id
        self.relativePath = relativePath
        self.casePreservingPath = casePreservingPath
        self.caseFoldedPath = caseFoldedPath
        self.name = name
        self.fileExtension = fileExtension
        self.itemKind = itemKind
        self.logicalSizeBytes = logicalSizeBytes
        self.allocatedSizeBytes = allocatedSizeBytes
        self.createdAtSource = createdAtSource
        self.modifiedAtSource = modifiedAtSource
        self.symlinkTarget = symlinkTarget
        self.isHidden = isHidden
        self.isPackage = isPackage
        self.isInaccessible = isInaccessible
    }

    public func value(for field: ComparisonField) -> String? {
        switch field {
        case .itemType: return itemKind.rawValue
        case .logicalSize: return logicalSizeBytes.map(String.init)
        case .allocatedSize: return allocatedSizeBytes.map(String.init)
        case .modifiedAt: return modifiedAtSource
        case .createdAt: return createdAtSource
        }
    }
}

/// Describes one side of a stored comparison — enough for the future GUI to
/// label the left and right source without touching the filesystem.
public struct ComparisonSideDescriptor: Hashable, Sendable {
    public let snapshotID: SnapshotID
    public let kind: SnapshotKind
    public let displayName: String
    public let scanRootName: String
    public let status: SnapshotStatus
    public let caseSensitivity: SourceCaseSensitivity
    public let normalizationVersion: NormalizationVersion
    public let warningCount: Int64
    public let mountPath: String?
    public let volumeDisplayName: String?
    public let startedAt: String

    public var isLive: Bool { kind == .transient }

    public var label: String {
        switch kind {
        case .user: return "Snapshot"
        case .transient: return "Live source"
        }
    }

    public var sourceDescription: String {
        if kind == .transient, let mountPath, !mountPath.isEmpty {
            return "Live folder: \(mountPath)"
        }
        if let volumeDisplayName {
            return "\(label): \(volumeDisplayName)"
        }
        return "\(label): \(displayName)"
    }
}

/// A view-ready, immutable comparison record. This is the only shape the
/// future comparison UI may read; raw database rows never leave the catalog.
public struct ComparisonRecord: Identifiable, Hashable, Sendable {
    public let id: ComparisonID
    public let mode: ComparisonMode
    public let left: ComparisonSideDescriptor
    public let right: ComparisonSideDescriptor
    public let profileID: Int64
    public let profileName: String
    public let profileVersion: Int64
    public let status: ComparisonStatus
    public let startedAt: String
    public let completedAt: String?
    public let matchedCount: Int64
    public let addedCount: Int64
    public let removedCount: Int64
    public let changedCount: Int64
    public let uncertainCount: Int64
    /// Deterministically re-derived compatibility warnings, e.g. an
    /// unknown-case-sensitivity source forcing the case-folded key (ADR-010).
    public let warnings: [String]

    public var totalComparedEntries: Int64 {
        matchedCount + addedCount + removedCount + changedCount + uncertainCount
    }

    public var totalDifferences: Int64 {
        addedCount + removedCount + changedCount + uncertainCount
    }

    public func count(for type: ComparisonResultType) -> Int64 {
        switch type {
        case .matched: return matchedCount
        case .added: return addedCount
        case .removed: return removedCount
        case .changed: return changedCount
        case .uncertain: return uncertainCount
        case .ignored: return 0 // 'ignored' rows exist but are not counted in the summary.
        }
    }
}

/// One stored result row, view-ready. `differenceFlags` carries the field
/// differences; the GUI decodes them through `ComparisonField.fields(for:)`.
public struct ComparisonResultRow: Identifiable, Hashable, Sendable {
    public let id: Int64
    public let comparisonID: ComparisonID
    public let resultPath: String
    public let displayName: String
    public let resultType: ComparisonResultType
    public let leftEntryID: Int64?
    public let rightEntryID: Int64?
    public let differenceFlags: Int64

    public init(
        id: Int64,
        comparisonID: ComparisonID,
        resultPath: String,
        displayName: String,
        resultType: ComparisonResultType,
        leftEntryID: Int64?,
        rightEntryID: Int64?,
        differenceFlags: Int64
    ) {
        self.id = id
        self.comparisonID = comparisonID
        self.resultPath = resultPath
        self.displayName = displayName
        self.resultType = resultType
        self.leftEntryID = leftEntryID
        self.rightEntryID = rightEntryID
        self.differenceFlags = differenceFlags
    }

    public var differenceFields: [ComparisonField] { ComparisonField.fields(for: differenceFlags) }
}

/// The outcome filters the backend can serve. The GUI maps its
/// differences-only mode and its per-outcome filters to these.
public enum ComparisonResultFilter: String, CaseIterable, Sendable {
    case all
    case differences
    case added
    case removed
    case modified
    case unchanged
    case conflicts
    case ignored

    /// The `result_type` values this filter admits. `.all` includes every type
    /// including `ignored`; `.differences` is the differences-only view.
    public var types: [ComparisonResultType] {
        switch self {
        case .all: return ComparisonResultType.allCases
        case .differences: return [.added, .removed, .changed, .uncertain]
        case .added: return [.added]
        case .removed: return [.removed]
        case .modified: return [.changed]
        case .unchanged: return [.matched]
        case .conflicts: return [.uncertain]
        case .ignored: return [.ignored]
        }
    }

    public var label: String {
        switch self {
        case .all: return "All results"
        case .differences: return "Differences only"
        case .added: return "Added"
        case .removed: return "Removed"
        case .modified: return "Modified"
        case .unchanged: return "Unchanged"
        case .conflicts: return "Conflicts / uncertain"
        case .ignored: return "Ignored"
        }
    }
}

public struct ComparisonResultPage: Sendable {
    public let comparisonID: ComparisonID
    public let filter: ComparisonResultFilter
    public let rows: [ComparisonResultRow]
    public let offset: Int
    public let limit: Int
    public let totalCount: Int64

    /// True when `offset + rows.count < totalCount`: more pages exist.
    public var isTruncated: Bool { Int64(offset) + Int64(rows.count) < totalCount }

    public init(
        comparisonID: ComparisonID,
        filter: ComparisonResultFilter,
        rows: [ComparisonResultRow],
        offset: Int,
        limit: Int,
        totalCount: Int64
    ) {
        self.comparisonID = comparisonID
        self.filter = filter
        self.rows = rows
        self.offset = offset
        self.limit = limit
        self.totalCount = totalCount
    }
}

/// Deterministic next/previous navigation anchors on the canonical
/// `(result_path, id)` ordering, so paging never reorders or drops a row.
public struct ComparisonResultAnchor: Hashable, Sendable {
    public let resultPath: String
    public let id: Int64

    public init(resultPath: String, id: Int64) {
        self.resultPath = resultPath
        self.id = id
    }
}

/// Deterministic, documented glob semantics for profile ignore rules.
///
/// * `*` matches any sequence of characters except `/`;
/// * `?` matches exactly one character except `/`;
/// * `**` matches any sequence of characters including `/`;
/// * a pattern containing `/` is matched against the whole relative path;
///   a pattern without `/` is matched against the entry name at any depth;
/// * both the rule and the target are ADR-009 case-folded, so a rule that
///   ignores one entry also ignores every case/Unicode variant of it — the
///   decision is per comparison key and therefore symmetric across sides.
public struct IgnoreRulePattern: Sendable {
    /// The rule exactly as stored in `ignore_rules_json`.
    public let pattern: String
    private let foldedPattern: String

    public init(pattern: String) {
        self.pattern = pattern
        self.foldedPattern = PathIdentity.caseFold(pattern)
    }

    public func matches(_ entry: SideMetadata) -> Bool {
        // The stored folded keys are already ADR-009 folded; the raw name is
        // folded here so a rule decision is case/Unicode symmetric.
        if foldedPattern.contains("/") {
            return matches(foldedPattern, against: entry.caseFoldedPath)
        }
        return matches(foldedPattern, against: PathIdentity.caseFold(entry.name))
    }

    /// Matches a pattern against a target string using the documented glob
    /// semantics. Iterative with an explicit stack: `*`/`**` never recurse
    /// per character, so a pathological pattern cannot exhaust the stack on
    /// a long path. This function is case-sensitive by contract; entry
    /// matching pre-folds both sides via `matches(_:entry:)`.
    public func matches(_ pattern: String, against target: String) -> Bool {
        let p = Array(pattern.unicodeScalars)
        let t = Array(target.unicodeScalars)
        var stack: [(Int, Int)] = [(0, 0)]
        while let (pi, ti) = stack.popLast() {
            var pIndex = pi
            var tIndex = ti
            var matched = true
            while matched {
                if pIndex == p.count {
                    matched = tIndex == t.count
                    break
                }
                let scalar = p[pIndex]
                switch scalar {
                case "?":
                    if tIndex < t.count && t[tIndex] != "/" {
                        pIndex += 1
                        tIndex += 1
                    } else {
                        matched = false
                    }
                case "*":
                    let isDouble = pIndex + 1 < p.count && p[pIndex + 1] == "*"
                    if isDouble {
                        // '**' may match any number of characters including
                        // '/'. Push every split point from here to the end.
                        pIndex += 2
                        while pIndex < p.count && p[pIndex] == "*" { pIndex += 1 }
                        for nextT in tIndex...t.count {
                            stack.append((pIndex, nextT))
                        }
                        matched = false
                    } else {
                        // A single '*' may match any run of non-'/' characters:
                        // every split point from here up to and including the
                        // next '/' (or the end) is a candidate continuation.
                        pIndex += 1
                        var nextT = tIndex
                        while nextT < t.count && t[nextT] != "/" { nextT += 1 }
                        for split in tIndex...nextT {
                            stack.append((pIndex, split))
                        }
                        matched = false
                    }
                default:
                    if tIndex < t.count && t[tIndex] == scalar {
                        pIndex += 1
                        tIndex += 1
                    } else {
                        matched = false
                    }
                }
            }
            if matched { return true }
        }
        return false
    }
}
