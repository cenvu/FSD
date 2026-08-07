import Foundation

/// Reads comparison profiles from the catalog. Profiles are schema-owned:
/// the built-in rows are seeded by `schema.sql`, and a profile's stable
/// identity is its row id while its `version` column is the revision the
/// engine freezes into each comparison record.
public final class ComparisonProfileRepository {
    public static let fastMetadataProfileID: Int64 = 1
    public static let structureOnlyProfileID: Int64 = 2
    public static let strictMetadataProfileID: Int64 = 3

    private let database: CatalogDatabase

    public init(database: CatalogDatabase) {
        self.database = database
    }

    public func profile(id: Int64) throws -> ComparisonProfile? {
        let rows = try database.query(
            """
            SELECT id, version, name, compare_item_type, compare_logical_size,
                   compare_allocated_size, compare_modified_at, compare_created_at,
                   timestamp_tolerance_seconds, include_hidden_items, ignore_rules_json,
                   is_builtin
            FROM comparison_profiles WHERE id = ?
            """,
            bindings: [.integer(id)]
        )
        return try rows.first.map(Self.makeProfile)
    }

    public func allProfiles() throws -> [ComparisonProfile] {
        let rows = try database.query(
            """
            SELECT id, version, name, compare_item_type, compare_logical_size,
                   compare_allocated_size, compare_modified_at, compare_created_at,
                   timestamp_tolerance_seconds, include_hidden_items, ignore_rules_json,
                   is_builtin
            FROM comparison_profiles ORDER BY id
            """
        )
        return try rows.map(Self.makeProfile)
    }

    private static func makeProfile(from row: DatabaseRow) throws -> ComparisonProfile {
        guard
            let id = row["id"]?.int64Value,
            let version = row["version"]?.int64Value,
            let name = row["name"]?.stringValue,
            let ignoreRulesRaw = row["ignore_rules_json"]?.stringValue
        else {
            throw ComparisonError.database(.schemaStateInvalid("comparison profile row is incomplete"))
        }
        return ComparisonProfile(
            id: id,
            version: version,
            name: name,
            compareItemType: (row["compare_item_type"]?.int64Value ?? 0) == 1,
            compareLogicalSize: (row["compare_logical_size"]?.int64Value ?? 0) == 1,
            compareAllocatedSize: (row["compare_allocated_size"]?.int64Value ?? 0) == 1,
            compareModifiedAt: (row["compare_modified_at"]?.int64Value ?? 0) == 1,
            compareCreatedAt: (row["compare_created_at"]?.int64Value ?? 0) == 1,
            timestampToleranceSeconds: row["timestamp_tolerance_seconds"]?.int64Value ?? 0,
            includeHiddenItems: (row["include_hidden_items"]?.int64Value ?? 0) == 1,
            ignoreRules: Self.decodeIgnoreRules(ignoreRulesRaw),
            isBuiltin: (row["is_builtin"]?.int64Value ?? 0) == 1
        )
    }

    /// The rule list is stored as a JSON string array by the schema seed.
    /// Decoded deterministically; an unparseable value yields no rules rather
    /// than a silently different comparison universe.
    static func decodeIgnoreRules(_ raw: String) -> [String] {
        guard let data = raw.data(using: .utf8),
              let decoded = try? JSONSerialization.jsonObject(with: data) as? [String]
        else { return [] }
        return decoded
    }
}
