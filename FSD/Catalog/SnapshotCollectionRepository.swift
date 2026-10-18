import Foundation

/// A logical, user-defined grouping of snapshots (docs/SNAPSHOT_COLLECTIONS.md).
///
/// A Collection is catalog metadata only. It is never a folder on a source
/// volume, never a mutation of snapshot contents, and never a stand-in for
/// physical-drive identity (`volumes` remains the canonical physical-source
/// table). "Unsorted" is never a row here: it is `collection_id IS NULL`.
public struct SnapshotCollection: Identifiable, Hashable, Sendable {
    public let id: Int64
    public let name: String
    public let normalizedName: String
    public let note: String?
    public let createdAt: String
    public let updatedAt: String
    /// Advances when a snapshot is assigned or moved into this Collection; not
    /// updated by merely viewing it.
    public let lastUsedAt: String?
}

/// One bounded page of Collections in deterministic order.
public struct SnapshotCollectionPage: Sendable, Equatable {
    public let collections: [SnapshotCollection]
    /// True when more Collections exist than this page returned.
    public let isTruncated: Bool
    public let limit: Int
}

/// One user snapshot as the organizer lists it. Membership is carried by the
/// stable `SnapshotID` and the nullable `collectionID` only; display/source
/// names and mount paths are never used to infer a Collection.
public struct CollectionSnapshot: Identifiable, Hashable, Sendable {
    public let id: SnapshotID
    public let displayName: String
    /// The source label recorded at capture time, if it was recorded.
    public let sourceLabelAtCapture: String?
    public let status: SnapshotStatus
    public let startedAt: String
    /// `nil` means Unsorted.
    public let collectionID: Int64?

    public var isComplete: Bool {
        status == .complete || status == .completeWithWarnings
    }
}

/// One bounded page of snapshots in deterministic newest-first order.
public struct CollectionSnapshotPage: Sendable, Equatable {
    public let snapshots: [CollectionSnapshot]
    public let isTruncated: Bool
    public let limit: Int
}

/// Which snapshots an organizer list request wants.
public enum CollectionMembershipFilter: Sendable, Hashable {
    case all
    case unsorted
    case collection(Int64)
}

/// Bounded aggregate counts for the sidebar. `total` counts every user
/// snapshot; `unsorted` counts `collection_id IS NULL`; `byCollection` maps a
/// Collection id to its user-snapshot count.
public struct CollectionMembershipCounts: Sendable, Equatable {
    public let total: Int64
    public let unsorted: Int64
    public let byCollection: [Int64: Int64]

    public func count(for filter: CollectionMembershipFilter) -> Int64 {
        switch filter {
        case .all: return total
        case .unsorted: return unsorted
        case let .collection(id): return byCollection[id] ?? 0
        }
    }
}

public enum SnapshotCollectionError: Error, LocalizedError, Equatable {
    case blankName
    case duplicateName(existing: SnapshotCollection)
    case collectionNotFound(Int64)
    case snapshotNotFound(SnapshotID)
    case snapshotNotUser(SnapshotID)
    case database(CatalogDatabaseError)

    public var errorDescription: String? {
        switch self {
        case .blankName:
            return "A Collection name is required."
        case let .duplicateName(existing):
            return "A Collection named \"\(existing.name)\" already exists."
        case .collectionNotFound:
            return "That Collection is no longer available."
        case .snapshotNotFound:
            return "That capture is no longer in the catalog."
        case .snapshotNotUser:
            return "Only saved user captures can be organized into Collections."
        case let .database(error):
            // Bounded presentation: never surface raw SQLite text or paths.
            if case let .sqlite(code, _) = error {
                return "The catalog database reported an error (code \(code))."
            }
            return "The catalog could not complete the Collection operation."
        }
    }
}

/// Reads and writes Collections and snapshot membership in SQLite and nothing
/// else. There is no `FileManager`, no source URL handling and no provider: a
/// Collection and a snapshot's membership are fully described by the catalog,
/// so organizing works with every source disconnected, erased or never
/// reconnected. No snapshot content, entry row, aggregate or capture fact is
/// ever touched by this type.
public final class SnapshotCollectionRepository {
    /// Collections are listed in `normalized_name` order; this bounds a page.
    public static let defaultCollectionLimit = 500
    /// Snapshots are listed newest-first; this bounds a page.
    public static let defaultSnapshotLimit = 200

    private let database: CatalogDatabase

    public init(database: CatalogDatabase) {
        self.database = database
    }

    /// The one normalization recipe (ADR-009/ADR-019): trim, then the whole
    /// name string through `PathIdentity.caseFold` (NFC + locale-independent
    /// case fold). Used for duplicate rejection and stored as `normalized_name`.
    public static func normalize(_ name: String) -> String {
        PathIdentity.caseFold(name.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // MARK: - Collections

    /// Deterministic order (`normalized_name` ASC, `id` ASC) with a bounded page
    /// and an explicit truncation flag. One query, no per-row reads.
    public func listCollections(limit: Int = SnapshotCollectionRepository.defaultCollectionLimit) throws -> SnapshotCollectionPage {
        let boundedLimit = max(1, limit)
        do {
            let rows = try database.query(
                """
                SELECT id, name, normalized_name, note, created_at, updated_at, last_used_at
                FROM collections
                ORDER BY normalized_name ASC, id ASC
                LIMIT ?
                """,
                bindings: [.integer(Int64(boundedLimit + 1))]
            )
            let isTruncated = rows.count > boundedLimit
            let collections = try rows.prefix(boundedLimit).map(Self.makeCollection)
            return SnapshotCollectionPage(collections: collections, isTruncated: isTruncated, limit: boundedLimit)
        } catch let error as CatalogDatabaseError {
            throw SnapshotCollectionError.database(error)
        }
    }

    public func collection(id: Int64) throws -> SnapshotCollection? {
        do {
            let rows = try database.query(
                """
                SELECT id, name, normalized_name, note, created_at, updated_at, last_used_at
                FROM collections WHERE id = ? LIMIT 1
                """,
                bindings: [.integer(id)]
            )
            return try rows.first.map(Self.makeCollection)
        } catch let error as CatalogDatabaseError {
            throw SnapshotCollectionError.database(error)
        }
    }

    /// Creates a Collection after trimming the name. A blank name is rejected;
    /// a name whose normalized form already exists is rejected outright rather
    /// than silently creating a case/Unicode near-duplicate.
    @discardableResult
    public func createCollection(name: String, note: String? = nil) throws -> SnapshotCollection {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SnapshotCollectionError.blankName }
        let normalized = Self.normalize(trimmed)
        do {
            return try database.transaction {
                if let existing = try Self.collection(matchingNormalized: normalized, database: database) {
                    throw SnapshotCollectionError.duplicateName(existing: existing)
                }
                try database.execute(
                    """
                    INSERT INTO collections (name, normalized_name, note, created_at, updated_at, last_used_at)
                    VALUES (?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL)
                    """,
                    bindings: [
                        .text(trimmed),
                        .text(normalized),
                        note.map(DatabaseValue.text) ?? .null
                    ]
                )
                let newID = try database.lastInsertRowID()
                guard let created = try Self.collection(id: newID, database: database) else {
                    throw CatalogDatabaseError.schemaStateInvalid("created Collection could not be read back")
                }
                return created
            }
        } catch let error as SnapshotCollectionError {
            throw error
        } catch let error as CatalogDatabaseError {
            throw SnapshotCollectionError.database(error)
        }
    }

    // MARK: - Membership

    /// Assigns a user snapshot to a Collection, or to Unsorted when
    /// `collectionID` is `nil`. This is a single-row `UPDATE` of
    /// `snapshots.collection_id`; the database trigger advances the target
    /// Collection's `last_used_at` for a real Collection. Entries, aggregates,
    /// timestamps, `session_number`, source-identity fields and any comparison
    /// are untouched. Works fully offline.
    public func assign(snapshotID: SnapshotID, to collectionID: Int64?) throws {
        do {
            try database.transaction {
                guard let kindRaw = try database.scalar(
                    "SELECT snapshot_kind FROM snapshots WHERE id = ? LIMIT 1",
                    bindings: [.integer(snapshotID.rawValue)]
                )?.stringValue else {
                    throw SnapshotCollectionError.snapshotNotFound(snapshotID)
                }
                guard kindRaw == SnapshotKind.user.rawValue else {
                    throw SnapshotCollectionError.snapshotNotUser(snapshotID)
                }
                if let collectionID {
                    let exists = try database.scalar(
                        "SELECT 1 FROM collections WHERE id = ? LIMIT 1",
                        bindings: [.integer(collectionID)]
                    )?.int64Value == 1
                    guard exists else { throw SnapshotCollectionError.collectionNotFound(collectionID) }
                }
                let assignment: DatabaseValue = collectionID.map(DatabaseValue.integer) ?? .null
                try database.execute(
                    "UPDATE snapshots SET collection_id = ? WHERE id = ?",
                    bindings: [assignment, .integer(snapshotID.rawValue)]
                )
            }
        } catch let error as SnapshotCollectionError {
            throw error
        } catch let error as CatalogDatabaseError {
            throw SnapshotCollectionError.database(error)
        }
    }

    /// Lists user snapshots in deterministic newest-first order, bounded by
    /// `limit` with an explicit truncation flag. Transient comparison
    /// scaffolding is always excluded. One query, no per-row reads.
    public func listSnapshots(
        filter: CollectionMembershipFilter,
        limit: Int = SnapshotCollectionRepository.defaultSnapshotLimit
    ) throws -> CollectionSnapshotPage {
        let boundedLimit = max(1, limit)
        var predicates = ["snapshot_kind = ?"]
        var bindings: [DatabaseValue] = [.text(SnapshotKind.user.rawValue)]
        switch filter {
        case .all:
            break
        case .unsorted:
            predicates.append("collection_id IS NULL")
        case let .collection(id):
            predicates.append("collection_id = ?")
            bindings.append(.integer(id))
        }
        bindings.append(.integer(Int64(boundedLimit + 1)))
        let whereClause = predicates.joined(separator: " AND ")
        do {
            let rows = try database.query(
                """
                SELECT id, display_name, status, started_at, collection_id, volume_display_name_at_capture
                FROM snapshots
                WHERE \(whereClause)
                ORDER BY started_at DESC, id DESC
                LIMIT ?
                """,
                bindings: bindings
            )
            let isTruncated = rows.count > boundedLimit
            let snapshots = try rows.prefix(boundedLimit).map(Self.makeSnapshot)
            return CollectionSnapshotPage(snapshots: snapshots, isTruncated: isTruncated, limit: boundedLimit)
        } catch let error as CatalogDatabaseError {
            throw SnapshotCollectionError.database(error)
        }
    }

    /// A single bounded aggregate query for the sidebar counts.
    public func membershipCounts() throws -> CollectionMembershipCounts {
        do {
            let rows = try database.query(
                """
                SELECT collection_id, COUNT(*) AS snapshot_count
                FROM snapshots
                WHERE snapshot_kind = ?
                GROUP BY collection_id
                """,
                bindings: [.text(SnapshotKind.user.rawValue)]
            )
            var total: Int64 = 0
            var unsorted: Int64 = 0
            var byCollection: [Int64: Int64] = [:]
            for row in rows {
                let count = row["snapshot_count"]?.int64Value ?? 0
                total += count
                if let id = row["collection_id"]?.int64Value {
                    byCollection[id] = count
                } else {
                    unsorted += count
                }
            }
            return CollectionMembershipCounts(total: total, unsorted: unsorted, byCollection: byCollection)
        } catch let error as CatalogDatabaseError {
            throw SnapshotCollectionError.database(error)
        }
    }

    // MARK: - Row mapping

    private static func collection(matchingNormalized normalized: String, database: CatalogDatabase) throws -> SnapshotCollection? {
        let rows = try database.query(
            """
            SELECT id, name, normalized_name, note, created_at, updated_at, last_used_at
            FROM collections WHERE normalized_name = ? LIMIT 1
            """,
            bindings: [.text(normalized)]
        )
        return try rows.first.map(makeCollection)
    }

    private static func collection(id: Int64, database: CatalogDatabase) throws -> SnapshotCollection? {
        let rows = try database.query(
            """
            SELECT id, name, normalized_name, note, created_at, updated_at, last_used_at
            FROM collections WHERE id = ? LIMIT 1
            """,
            bindings: [.integer(id)]
        )
        return try rows.first.map(makeCollection)
    }

    private static func makeCollection(from row: DatabaseRow) throws -> SnapshotCollection {
        guard
            let id = row["id"]?.int64Value,
            let name = row["name"]?.stringValue,
            let normalizedName = row["normalized_name"]?.stringValue,
            let createdAt = row["created_at"]?.stringValue,
            let updatedAt = row["updated_at"]?.stringValue
        else {
            throw SnapshotCollectionError.database(.schemaStateInvalid("collection row is incomplete"))
        }
        return SnapshotCollection(
            id: id,
            name: name,
            normalizedName: normalizedName,
            note: row["note"]?.stringValue,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastUsedAt: row["last_used_at"]?.stringValue
        )
    }

    private static func makeSnapshot(from row: DatabaseRow) throws -> CollectionSnapshot {
        guard
            let id = row["id"]?.int64Value,
            let displayName = row["display_name"]?.stringValue,
            let statusRaw = row["status"]?.stringValue,
            let status = SnapshotStatus(rawValue: statusRaw),
            let startedAt = row["started_at"]?.stringValue
        else {
            throw SnapshotCollectionError.database(.schemaStateInvalid("snapshot membership row is incomplete"))
        }
        return CollectionSnapshot(
            id: SnapshotID(rawValue: id),
            displayName: displayName,
            sourceLabelAtCapture: row["volume_display_name_at_capture"]?.stringValue,
            status: status,
            startedAt: startedAt,
            collectionID: row["collection_id"]?.int64Value
        )
    }
}
