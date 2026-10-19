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
            SELECT id, version, CASE WHEN typeof(name)='text' AND length(CAST(name AS BLOB))<=4096 THEN name END AS name, compare_item_type, compare_logical_size,
                   compare_allocated_size, compare_modified_at, compare_created_at,
                   timestamp_tolerance_seconds, include_hidden_items, CASE WHEN typeof(ignore_rules_json)='text' AND length(CAST(ignore_rules_json AS BLOB))<=1048576 THEN ignore_rules_json END AS ignore_rules_json,
                   is_builtin, CASE WHEN length(CAST(name AS BLOB))<=4096 THEN hex(CAST(name AS BLOB)) END AS receipt_raw_name, CASE WHEN length(CAST(ignore_rules_json AS BLOB))<=1048576 THEN hex(CAST(ignore_rules_json AS BLOB)) END AS receipt_raw_rules
            FROM comparison_profiles WHERE id = ?
            """,
            bindings: [.integer(id)]
        )
        return try rows.first.map(Self.makeProfile)
    }

    public func allProfiles() throws -> [ComparisonProfile] {
        let rows = try database.query(
            """
            SELECT id, version, CASE WHEN typeof(name)='text' AND length(CAST(name AS BLOB))<=4096 THEN name END AS name, compare_item_type, compare_logical_size,
                   compare_allocated_size, compare_modified_at, compare_created_at,
                   timestamp_tolerance_seconds, include_hidden_items, CASE WHEN typeof(ignore_rules_json)='text' AND length(CAST(ignore_rules_json AS BLOB))<=1048576 THEN ignore_rules_json END AS ignore_rules_json,
                   is_builtin, CASE WHEN length(CAST(name AS BLOB))<=4096 THEN hex(CAST(name AS BLOB)) END AS receipt_raw_name, CASE WHEN length(CAST(ignore_rules_json AS BLOB))<=1048576 THEN hex(CAST(ignore_rules_json AS BLOB)) END AS receipt_raw_rules
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
        for (value, column) in [(name,"receipt_raw_name"),(ignoreRulesRaw,"receipt_raw_rules")] {
            guard row[column]?.stringValue == CompletionEvidenceContract.hexUTF8(value) else { throw CompletionReceiptError.invalidEvidence("Invalid UTF8 profile") }
        }
        guard let data = ignoreRulesRaw.data(using: .utf8),
              let rules = try? JSONDecoder().decode([String].self, from: data),
              ignoreRulesRaw.utf8.count <= 1048576 else {
            throw CompletionReceiptError.invalidEvidence("Malformed profile ignore rules")
        }
        for name in ["compare_item_type","compare_logical_size","compare_allocated_size","compare_modified_at","compare_created_at","include_hidden_items","is_builtin"] {
            guard let flag = row[name]?.int64Value, [0,1].contains(flag) else { throw CompletionReceiptError.invalidEvidence("Invalid profile field") }
        }
        guard let tolerance = row["timestamp_tolerance_seconds"]?.int64Value else { throw CompletionReceiptError.invalidEvidence("Invalid profile tolerance") }
        let profile = ComparisonProfile(
            id: id,
            version: version,
            name: name,
            compareItemType: (row["compare_item_type"]?.int64Value ?? 0) == 1,
            compareLogicalSize: (row["compare_logical_size"]?.int64Value ?? 0) == 1,
            compareAllocatedSize: (row["compare_allocated_size"]?.int64Value ?? 0) == 1,
            compareModifiedAt: (row["compare_modified_at"]?.int64Value ?? 0) == 1,
            compareCreatedAt: (row["compare_created_at"]?.int64Value ?? 0) == 1,
            timestampToleranceSeconds: tolerance,
            includeHiddenItems: (row["include_hidden_items"]?.int64Value ?? 0) == 1,
            ignoreRules: rules,
            isBuiltin: (row["is_builtin"]?.int64Value ?? 0) == 1
        )
        try CompletionProfileDefinition(profile).validate()
        return profile
    }

}
