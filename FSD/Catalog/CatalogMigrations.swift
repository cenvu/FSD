import Foundation

/// One explicit, transactional step from `version - 1` to `version`.
///
/// FSD deliberately has no implicit migration mechanism. `docs/database/schema.sql`
/// creates a catalog at the current version and is never replayed against an
/// existing database; moving an existing catalog forward is only ever done by a
/// step in `CatalogMigrations.all`, inside one transaction, with the version row
/// written last. This is the correction for Condition C2 of the Milestone 2
/// acceptance audit, where two materially different schemas both reported
/// version 4 because DDL was installed unconditionally on every open.
public struct SchemaMigration: Sendable {
    public let version: Int64
    public let statements: [String]

    public init(version: Int64, statements: [String]) {
        self.version = version
        self.statements = statements
    }
}

public enum CatalogMigrations {
    /// The version a fresh `schema.sql` records and the version every supported
    /// catalog is brought to on open.
    public static let currentVersion: Int64 = 9

    /// The oldest version that can be migrated forward. Versions 1 through 3
    /// never existed as a materialized database, so they have no migration and
    /// are rejected rather than guessed at.
    public static let oldestMigratableVersion: Int64 = 4

    public static let all: [SchemaMigration] = [
        migrationToVersion5, migrationToVersion6, migrationToVersion7, migrationToVersion8, migrationToVersion9
    ]

    /// Version 4 to version 5.
    ///
    /// Converges the two known version-4 variants onto one state:
    ///
    /// * pre-Milestone-2 version 4 — created before 2026-08-04 01:24, missing the
    ///   four completed-snapshot immutability guards entirely;
    /// * post-Milestone-2 version 4 — the same schema plus those four guards,
    ///   installed by the unconditional DDL pass this migration replaces.
    ///
    /// The four guard statements are the only deliberately idempotent DDL here;
    /// everything else is new in version 5 and cannot already exist.
    public static let migrationToVersion5 = SchemaMigration(
        version: 5,
        statements: [
            """
            CREATE TRIGGER IF NOT EXISTS trg_completed_entries_insert_guard
            BEFORE INSERT ON entries
            WHEN (SELECT status FROM snapshots WHERE id = NEW.snapshot_id) IN ('complete', 'complete_with_warnings')
            BEGIN
                SELECT RAISE(ABORT, 'Cannot insert entries into a completed snapshot');
            END
            """,
            """
            CREATE TRIGGER IF NOT EXISTS trg_completed_entries_update_guard
            BEFORE UPDATE ON entries
            WHEN (SELECT status FROM snapshots WHERE id = OLD.snapshot_id) IN ('complete', 'complete_with_warnings')
            BEGIN
                SELECT RAISE(ABORT, 'Cannot update entries in a completed snapshot');
            END
            """,
            """
            CREATE TRIGGER IF NOT EXISTS trg_completed_entries_delete_guard
            BEFORE DELETE ON entries
            WHEN (SELECT status FROM snapshots WHERE id = OLD.snapshot_id) IN ('complete', 'complete_with_warnings')
            BEGIN
                SELECT RAISE(ABORT, 'Cannot delete entries from a completed snapshot');
            END
            """,
            """
            CREATE TRIGGER IF NOT EXISTS trg_completed_scan_issues_insert_guard
            BEFORE INSERT ON scan_issues
            WHEN (SELECT status FROM snapshots WHERE id = NEW.snapshot_id) IN ('complete', 'complete_with_warnings')
            BEGIN
                SELECT RAISE(ABORT, 'Cannot add scan issues to a completed snapshot');
            END
            """,
            "ALTER TABLE snapshots ADD COLUMN volume_display_name_at_capture TEXT",
            "ALTER TABLE snapshots ADD COLUMN volume_identifier_at_capture TEXT",
            "ALTER TABLE snapshots ADD COLUMN volume_total_capacity_bytes_at_capture INTEGER",
            """
            CREATE TRIGGER IF NOT EXISTS trg_snapshots_capture_facts_immutable
            BEFORE UPDATE OF
                volume_id, session_number, scan_root_name, mount_path_at_capture,
                root_relative_path, scanner_version, schema_version, normalization_version,
                snapshot_kind, source_case_sensitivity, filesystem_provider,
                provider_version, source_access_mode, device_identifier,
                partition_identifier, partition_offset, partition_length,
                filesystem_variant, started_at, volume_display_name_at_capture,
                volume_identifier_at_capture, volume_total_capacity_bytes_at_capture
            ON snapshots
            WHEN OLD.volume_id IS NOT NEW.volume_id
              OR OLD.session_number IS NOT NEW.session_number
              OR OLD.scan_root_name IS NOT NEW.scan_root_name
              OR OLD.mount_path_at_capture IS NOT NEW.mount_path_at_capture
              OR OLD.root_relative_path IS NOT NEW.root_relative_path
              OR OLD.scanner_version IS NOT NEW.scanner_version
              OR OLD.schema_version IS NOT NEW.schema_version
              OR OLD.normalization_version IS NOT NEW.normalization_version
              OR OLD.snapshot_kind IS NOT NEW.snapshot_kind
              OR OLD.source_case_sensitivity IS NOT NEW.source_case_sensitivity
              OR OLD.filesystem_provider IS NOT NEW.filesystem_provider
              OR OLD.provider_version IS NOT NEW.provider_version
              OR OLD.source_access_mode IS NOT NEW.source_access_mode
              OR OLD.device_identifier IS NOT NEW.device_identifier
              OR OLD.partition_identifier IS NOT NEW.partition_identifier
              OR OLD.partition_offset IS NOT NEW.partition_offset
              OR OLD.partition_length IS NOT NEW.partition_length
              OR OLD.filesystem_variant IS NOT NEW.filesystem_variant
              OR OLD.started_at IS NOT NEW.started_at
              OR OLD.volume_display_name_at_capture IS NOT NEW.volume_display_name_at_capture
              OR OLD.volume_identifier_at_capture IS NOT NEW.volume_identifier_at_capture
              OR OLD.volume_total_capacity_bytes_at_capture IS NOT NEW.volume_total_capacity_bytes_at_capture
            BEGIN
                SELECT RAISE(ABORT, 'Snapshot capture-time facts are immutable');
            END
            """,
            """
            CREATE INDEX IF NOT EXISTS idx_entries_snapshot_extension
            ON entries(snapshot_id, file_extension)
            """
        ]
    )

    /// Version 5 to version 6 (Milestone 4, ADR-027).
    ///
    /// Comparison result integrity: profiles and comparisons record a frozen
    /// profile revision, a terminal comparison's status/counts are immutable,
    /// detailed results can only be inserted while a comparison is running,
    /// and differences-only queries are served by a (comparison_id,
    /// result_type) index. Nothing here is idempotent: none of these objects
    /// can exist in a version-5 catalog.
    public static let migrationToVersion6 = SchemaMigration(
        version: 6,
        statements: [
            "ALTER TABLE comparison_profiles ADD COLUMN version INTEGER NOT NULL DEFAULT 1",
            "ALTER TABLE comparisons ADD COLUMN profile_version INTEGER NOT NULL DEFAULT 1",
            """
            CREATE TRIGGER trg_comparisons_terminal_immutable
            BEFORE UPDATE OF status, matched_count, added_count, removed_count, changed_count, uncertain_count ON comparisons
            WHEN OLD.status IN ('complete', 'cancelled', 'failed')
              AND (NEW.status IS NOT OLD.status
                   OR NEW.matched_count IS NOT OLD.matched_count
                   OR NEW.added_count IS NOT OLD.added_count
                   OR NEW.removed_count IS NOT OLD.removed_count
                   OR NEW.changed_count IS NOT OLD.changed_count
                   OR NEW.uncertain_count IS NOT OLD.uncertain_count)
            BEGIN
                SELECT RAISE(ABORT, 'Comparison results are immutable after a terminal state');
            END
            """,
            """
            CREATE TRIGGER trg_comparison_results_insert_guard
            BEFORE INSERT ON comparison_results
            WHEN (SELECT status FROM comparisons WHERE id = NEW.comparison_id) IN ('complete', 'cancelled', 'failed')
            BEGIN
                SELECT RAISE(ABORT, 'Cannot add results to a terminal comparison');
            END
            """,
            """
            CREATE TRIGGER trg_comparison_results_update_guard
            BEFORE UPDATE ON comparison_results
            WHEN (SELECT status FROM comparisons WHERE id = OLD.comparison_id) IN ('complete', 'cancelled', 'failed')
            BEGIN
                SELECT RAISE(ABORT, 'Comparison results are immutable after a terminal state');
            END
            """,
            """
            CREATE INDEX idx_comparison_results_type
            ON comparison_results(comparison_id, result_type)
            """
        ]
    )

    /// Version 6 to version 7 (Milestone 4 schema-safety correction, ADR-028).
    ///
    /// A terminal comparison's retained evidence becomes immutable: result
    /// rows gain the DELETE guard ADR-027 left out, and collision groups and
    /// members are guarded against INSERT, UPDATE and DELETE once the
    /// comparison is complete, cancelled or failed. Writes stay allowed while
    /// a comparison is running, and whole-comparison disposal is unaffected —
    /// the DELETE guards probe the comparison's status, and during disposal
    /// the cascade fires only after the comparison row itself is gone, so the
    /// probe finds nothing and the cascade completes. Nothing here is
    /// idempotent: none of these triggers can exist in a version-6 catalog.
    public static let migrationToVersion7 = SchemaMigration(
        version: 7,
        statements: [
            """
            CREATE TRIGGER trg_comparison_results_delete_guard
            BEFORE DELETE ON comparison_results
            WHEN (SELECT status FROM comparisons WHERE id = OLD.comparison_id) IN ('complete', 'cancelled', 'failed')
            BEGIN
                SELECT RAISE(ABORT, 'Comparison results are immutable after a terminal state');
            END
            """,
            """
            CREATE TRIGGER trg_comparison_collision_groups_insert_guard
            BEFORE INSERT ON comparison_collision_groups
            WHEN (SELECT status FROM comparisons WHERE id = NEW.comparison_id) IN ('complete', 'cancelled', 'failed')
            BEGIN
                SELECT RAISE(ABORT, 'Cannot add collision groups to a terminal comparison');
            END
            """,
            """
            CREATE TRIGGER trg_comparison_collision_groups_update_guard
            BEFORE UPDATE ON comparison_collision_groups
            WHEN (SELECT status FROM comparisons WHERE id = OLD.comparison_id) IN ('complete', 'cancelled', 'failed')
            BEGIN
                SELECT RAISE(ABORT, 'Collision groups are immutable after a terminal state');
            END
            """,
            """
            CREATE TRIGGER trg_comparison_collision_groups_delete_guard
            BEFORE DELETE ON comparison_collision_groups
            WHEN (SELECT status FROM comparisons WHERE id = OLD.comparison_id) IN ('complete', 'cancelled', 'failed')
            BEGIN
                SELECT RAISE(ABORT, 'Collision groups are immutable after a terminal state');
            END
            """,
            """
            CREATE TRIGGER trg_comparison_collision_members_insert_guard
            BEFORE INSERT ON comparison_collision_members
            WHEN (SELECT c.status FROM comparisons c
                  JOIN comparison_collision_groups g ON g.comparison_id = c.id
                  WHERE g.id = NEW.group_id) IN ('complete', 'cancelled', 'failed')
            BEGIN
                SELECT RAISE(ABORT, 'Cannot add collision members to a terminal comparison');
            END
            """,
            """
            CREATE TRIGGER trg_comparison_collision_members_update_guard
            BEFORE UPDATE ON comparison_collision_members
            WHEN (SELECT c.status FROM comparisons c
                  JOIN comparison_collision_groups g ON g.comparison_id = c.id
                  WHERE g.id = OLD.group_id) IN ('complete', 'cancelled', 'failed')
            BEGIN
                SELECT RAISE(ABORT, 'Collision members are immutable after a terminal state');
            END
            """,
            """
            CREATE TRIGGER trg_comparison_collision_members_delete_guard
            BEFORE DELETE ON comparison_collision_members
            WHEN (SELECT c.status FROM comparisons c
                  JOIN comparison_collision_groups g ON g.comparison_id = c.id
                  WHERE g.id = OLD.group_id) IN ('complete', 'cancelled', 'failed')
            BEGIN
                SELECT RAISE(ABORT, 'Collision members are immutable after a terminal state');
            END
            """
        ]
    )

    /// Version 7 to version 8 (Milestone 5 disposal-performance correction,
    /// KI-024). SQLite's foreign-key cascade for the self-referencing
    /// `comparison_results.parent_result_id` relationship must be able to
    /// find child rows by `parent_result_id` alone. The existing composite
    /// index starts with `comparison_id` and cannot serve that lookup.
    public static let migrationToVersion8 = SchemaMigration(
        version: 8,
        statements: [
            """
            CREATE INDEX idx_comparison_results_parent_result_id
            ON comparison_results(parent_result_id)
            """
        ]
    )

    /// Version 8 to version 9: truthful provider provenance, without backfill.
    public static let migrationToVersion9 = SchemaMigration(
        version: 9,
        statements: ["ALTER TABLE entry_classifications ADD COLUMN provider_identifier TEXT"]
    )

    /// The one complete canonical inventory of what a catalog reporting
    /// `currentVersion` must contain, however it got there. Verified on every
    /// open, so a fresh database and a migrated database are held to one
    /// standard and a hand-edited or partially-created catalog fails loudly
    /// instead of behaving differently at runtime.
    ///
    /// Triggers and indexes carry their canonical DDL, compared in normalized
    /// form (whitespace, case, comments and `IF NOT EXISTS` stripped), so a
    /// same-name object with a materially different definition is rejected
    /// just like a missing one. `ExpectedStateInventoryTests` keeps this list
    /// in lockstep with `docs/database/schema.sql`: the test derives the
    /// canonical object set from the schema file and fails on any drift in
    /// either direction.
    public enum ExpectedState {
        public static let tables = [
            "schema_migrations", "volumes", "collections", "source_collection_defaults",
            "snapshots", "entries", "scan_issues", "comparison_profiles", "comparisons",
            "comparison_collision_groups", "comparison_collision_members",
            "comparison_results", "entry_classifications"
        ]

        /// Every canonical trigger, name and DDL. The DDL text is the
        /// `CREATE TRIGGER ... END;` statement as written in
        /// `docs/database/schema.sql`; `normalizedObjectSQL` removes the
        /// textual differences SQLite itself applies when storing it.
        public static let triggerDefinitions: [(name: String, sql: String)] = [
            ("trg_snapshots_complete_root_check",
             "CREATE TRIGGER IF NOT EXISTS trg_snapshots_complete_root_check\nBEFORE UPDATE OF status ON snapshots\nWHEN NEW.status IN ('complete', 'complete_with_warnings')\nBEGIN\n    SELECT CASE\n        WHEN (SELECT COUNT(*) FROM entries WHERE snapshot_id = NEW.id AND parent_id IS NULL AND relative_path = '') != 1 THEN\n            RAISE(ABORT, 'Snapshot must have exactly one root entry to complete')\n        WHEN NEW.normalization_version != 'fsd-normalizer-v1_app-1.0_os-1' THEN\n            RAISE(ABORT, 'Snapshot normalization_version is not supported for completion')\n    END;\nEND;"),
            ("trg_snapshots_insert_scanning_only",
             "CREATE TRIGGER IF NOT EXISTS trg_snapshots_insert_scanning_only\nBEFORE INSERT ON snapshots\nWHEN NEW.status != 'scanning'\nBEGIN\n    SELECT RAISE(ABORT, 'Snapshot must be inserted as scanning first.');\nEND;"),
            ("trg_snapshots_capture_facts_immutable",
             "CREATE TRIGGER IF NOT EXISTS trg_snapshots_capture_facts_immutable\nBEFORE UPDATE OF\n    volume_id, session_number, scan_root_name, mount_path_at_capture,\n    root_relative_path, scanner_version, schema_version, normalization_version,\n    snapshot_kind, source_case_sensitivity, filesystem_provider,\n    provider_version, source_access_mode, device_identifier,\n    partition_identifier, partition_offset, partition_length,\n    filesystem_variant, started_at, volume_display_name_at_capture,\n    volume_identifier_at_capture, volume_total_capacity_bytes_at_capture\nON snapshots\nWHEN OLD.volume_id IS NOT NEW.volume_id\n  OR OLD.session_number IS NOT NEW.session_number\n  OR OLD.scan_root_name IS NOT NEW.scan_root_name\n  OR OLD.mount_path_at_capture IS NOT NEW.mount_path_at_capture\n  OR OLD.root_relative_path IS NOT NEW.root_relative_path\n  OR OLD.scanner_version IS NOT NEW.scanner_version\n  OR OLD.schema_version IS NOT NEW.schema_version\n  OR OLD.normalization_version IS NOT NEW.normalization_version\n  OR OLD.snapshot_kind IS NOT NEW.snapshot_kind\n  OR OLD.source_case_sensitivity IS NOT NEW.source_case_sensitivity\n  OR OLD.filesystem_provider IS NOT NEW.filesystem_provider\n  OR OLD.provider_version IS NOT NEW.provider_version\n  OR OLD.source_access_mode IS NOT NEW.source_access_mode\n  OR OLD.device_identifier IS NOT NEW.device_identifier\n  OR OLD.partition_identifier IS NOT NEW.partition_identifier\n  OR OLD.partition_offset IS NOT NEW.partition_offset\n  OR OLD.partition_length IS NOT NEW.partition_length\n  OR OLD.filesystem_variant IS NOT NEW.filesystem_variant\n  OR OLD.started_at IS NOT NEW.started_at\n  OR OLD.volume_display_name_at_capture IS NOT NEW.volume_display_name_at_capture\n  OR OLD.volume_identifier_at_capture IS NOT NEW.volume_identifier_at_capture\n  OR OLD.volume_total_capacity_bytes_at_capture IS NOT NEW.volume_total_capacity_bytes_at_capture\nBEGIN\n    SELECT RAISE(ABORT, 'Snapshot capture-time facts are immutable');\nEND;"),
            ("trg_snapshots_terminal_status_check",
             "CREATE TRIGGER IF NOT EXISTS trg_snapshots_terminal_status_check\nBEFORE UPDATE OF status ON snapshots\nWHEN OLD.status IN ('complete', 'complete_with_warnings', 'cancelled', 'failed')\nBEGIN\n    SELECT RAISE(ABORT, 'Cannot transition out of a terminal status');\nEND;"),
            ("trg_completed_entries_insert_guard",
             "CREATE TRIGGER IF NOT EXISTS trg_completed_entries_insert_guard\nBEFORE INSERT ON entries\nWHEN (SELECT status FROM snapshots WHERE id = NEW.snapshot_id) IN ('complete', 'complete_with_warnings')\nBEGIN\n    SELECT RAISE(ABORT, 'Cannot insert entries into a completed snapshot');\nEND;"),
            ("trg_completed_entries_update_guard",
             "CREATE TRIGGER IF NOT EXISTS trg_completed_entries_update_guard\nBEFORE UPDATE ON entries\nWHEN (SELECT status FROM snapshots WHERE id = OLD.snapshot_id) IN ('complete', 'complete_with_warnings')\nBEGIN\n    SELECT RAISE(ABORT, 'Cannot update entries in a completed snapshot');\nEND;"),
            ("trg_completed_entries_delete_guard",
             "CREATE TRIGGER IF NOT EXISTS trg_completed_entries_delete_guard\nBEFORE DELETE ON entries\nWHEN (SELECT status FROM snapshots WHERE id = OLD.snapshot_id) IN ('complete', 'complete_with_warnings')\nBEGIN\n    SELECT RAISE(ABORT, 'Cannot delete entries from a completed snapshot');\nEND;"),
            ("trg_completed_scan_issues_insert_guard",
             "CREATE TRIGGER IF NOT EXISTS trg_completed_scan_issues_insert_guard\nBEFORE INSERT ON scan_issues\nWHEN (SELECT status FROM snapshots WHERE id = NEW.snapshot_id) IN ('complete', 'complete_with_warnings')\nBEGIN\n    SELECT RAISE(ABORT, 'Cannot add scan issues to a completed snapshot');\nEND;"),
            ("trg_comparisons_version_check",
             "CREATE TRIGGER IF NOT EXISTS trg_comparisons_version_check\nBEFORE INSERT ON comparisons\nWHEN NEW.left_snapshot_id IS NOT NULL AND NEW.right_snapshot_id IS NOT NULL\nBEGIN\n    SELECT CASE\n        WHEN (SELECT normalization_version FROM snapshots WHERE id = NEW.left_snapshot_id) !=\n             (SELECT normalization_version FROM snapshots WHERE id = NEW.right_snapshot_id) THEN\n            RAISE(ABORT, 'Mismatched normalization versions block comparison')\n    END;\nEND;"),
            ("trg_comparisons_source_immutable",
             "CREATE TRIGGER IF NOT EXISTS trg_comparisons_source_immutable\nBEFORE UPDATE OF left_snapshot_id, right_snapshot_id ON comparisons\nWHEN OLD.left_snapshot_id IS NOT NEW.left_snapshot_id OR OLD.right_snapshot_id IS NOT NEW.right_snapshot_id\nBEGIN\n    SELECT RAISE(ABORT, 'Comparison source snapshot IDs are immutable');\nEND;"),
            ("trg_comparisons_source_eligibility_insert",
             "CREATE TRIGGER IF NOT EXISTS trg_comparisons_source_eligibility_insert\nBEFORE INSERT ON comparisons\nWHEN NEW.left_snapshot_id IS NOT NULL AND NEW.right_snapshot_id IS NOT NULL\nBEGIN\n    SELECT CASE\n        WHEN (SELECT status FROM snapshots WHERE id = NEW.left_snapshot_id) NOT IN ('complete', 'complete_with_warnings') OR\n             (SELECT status FROM snapshots WHERE id = NEW.right_snapshot_id) NOT IN ('complete', 'complete_with_warnings') THEN\n            RAISE(ABORT, 'Comparison sources must be complete snapshots')\n    END;\nEND;"),
            ("trg_comparison_collision_member_side_left",
             "CREATE TRIGGER IF NOT EXISTS trg_comparison_collision_member_side_left\nBEFORE INSERT ON comparison_collision_members\nWHEN NEW.side = 'left'\nBEGIN\n    SELECT CASE\n        WHEN (SELECT snapshot_id FROM entries WHERE id = NEW.entry_id) != \n             (SELECT left_snapshot_id FROM comparisons WHERE id = (SELECT comparison_id FROM comparison_collision_groups WHERE id = NEW.group_id)) THEN\n            RAISE(ABORT, 'Collision member entry must belong to the left snapshot of the comparison')\n    END;\nEND;"),
            ("trg_comparison_collision_member_side_right",
             "CREATE TRIGGER IF NOT EXISTS trg_comparison_collision_member_side_right\nBEFORE INSERT ON comparison_collision_members\nWHEN NEW.side = 'right'\nBEGIN\n    SELECT CASE\n        WHEN (SELECT snapshot_id FROM entries WHERE id = NEW.entry_id) != \n             (SELECT right_snapshot_id FROM comparisons WHERE id = (SELECT comparison_id FROM comparison_collision_groups WHERE id = NEW.group_id)) THEN\n            RAISE(ABORT, 'Collision member entry must belong to the right snapshot of the comparison')\n    END;\nEND;"),
            ("trg_comparison_results_entry_left",
             "CREATE TRIGGER IF NOT EXISTS trg_comparison_results_entry_left\nBEFORE INSERT ON comparison_results\nWHEN NEW.left_entry_id IS NOT NULL\nBEGIN\n    SELECT CASE\n        WHEN (SELECT snapshot_id FROM entries WHERE id = NEW.left_entry_id) !=\n             (SELECT left_snapshot_id FROM comparisons WHERE id = NEW.comparison_id) THEN\n            RAISE(ABORT, 'Result left_entry_id must belong to the left snapshot of the comparison')\n    END;\nEND;"),
            ("trg_comparison_results_entry_right",
             "CREATE TRIGGER IF NOT EXISTS trg_comparison_results_entry_right\nBEFORE INSERT ON comparison_results\nWHEN NEW.right_entry_id IS NOT NULL\nBEGIN\n    SELECT CASE\n        WHEN (SELECT snapshot_id FROM entries WHERE id = NEW.right_entry_id) !=\n             (SELECT right_snapshot_id FROM comparisons WHERE id = NEW.comparison_id) THEN\n            RAISE(ABORT, 'Result right_entry_id must belong to the right snapshot of the comparison')\n    END;\nEND;"),
            ("trg_comparison_results_uncertain_empty",
             "CREATE TRIGGER IF NOT EXISTS trg_comparison_results_uncertain_empty\nBEFORE INSERT ON comparison_results\nWHEN NEW.result_type = 'uncertain' AND NEW.left_entry_id IS NULL AND NEW.right_entry_id IS NULL\nBEGIN\n    SELECT CASE\n        WHEN EXISTS (\n            SELECT 1 FROM comparison_results \n            WHERE comparison_id = NEW.comparison_id \n              AND result_path = NEW.result_path \n              AND result_type = 'uncertain' \n              AND left_entry_id IS NULL \n              AND right_entry_id IS NULL\n        ) THEN\n            RAISE(ABORT, 'Duplicate empty uncertain rows are not allowed')\n    END;\nEND;"),
            ("trg_comparison_results_no_collision_pairs",
             "CREATE TRIGGER IF NOT EXISTS trg_comparison_results_no_collision_pairs\nBEFORE INSERT ON comparison_results\nWHEN NEW.result_type IN ('matched', 'changed', 'added', 'removed')\nBEGIN\n    SELECT CASE\n        WHEN EXISTS (\n            SELECT 1 FROM comparison_collision_members\n            WHERE group_id IN (SELECT id FROM comparison_collision_groups WHERE comparison_id = NEW.comparison_id)\n              AND ((side = 'left' AND entry_id = NEW.left_entry_id) OR\n                   (side = 'right' AND entry_id = NEW.right_entry_id))\n        ) THEN\n            RAISE(ABORT, 'Collision members cannot be paired as matched/changed/added/removed')\n        WHEN EXISTS (\n            SELECT 1 FROM comparison_collision_groups\n            WHERE comparison_id = NEW.comparison_id AND result_path = NEW.result_path\n        ) THEN\n            RAISE(ABORT, 'Ordinary results cannot use a result_path already assigned to a collision group')\n    END;\nEND;"),
            ("trg_comparison_results_no_collision_pairs_update",
             "CREATE TRIGGER IF NOT EXISTS trg_comparison_results_no_collision_pairs_update\nBEFORE UPDATE OF result_type, left_entry_id, right_entry_id, result_path ON comparison_results\nWHEN NEW.result_type IN ('matched', 'changed', 'added', 'removed')\nBEGIN\n    SELECT CASE\n        WHEN EXISTS (\n            SELECT 1 FROM comparison_collision_members\n            WHERE group_id IN (SELECT id FROM comparison_collision_groups WHERE comparison_id = NEW.comparison_id)\n              AND ((side = 'left' AND entry_id = NEW.left_entry_id) OR\n                   (side = 'right' AND entry_id = NEW.right_entry_id))\n        ) THEN\n            RAISE(ABORT, 'Collision members cannot be paired as matched/changed/added/removed')\n        WHEN EXISTS (\n            SELECT 1 FROM comparison_collision_groups\n            WHERE comparison_id = NEW.comparison_id AND result_path = NEW.result_path\n        ) THEN\n            RAISE(ABORT, 'Ordinary results cannot use a result_path already assigned to a collision group')\n    END;\nEND;"),
            ("trg_comparisons_terminal_immutable",
             "CREATE TRIGGER IF NOT EXISTS trg_comparisons_terminal_immutable\nBEFORE UPDATE OF status, matched_count, added_count, removed_count, changed_count, uncertain_count ON comparisons\nWHEN OLD.status IN ('complete', 'cancelled', 'failed')\n  AND (NEW.status IS NOT OLD.status\n       OR NEW.matched_count IS NOT OLD.matched_count\n       OR NEW.added_count IS NOT OLD.added_count\n       OR NEW.removed_count IS NOT OLD.removed_count\n       OR NEW.changed_count IS NOT OLD.changed_count\n       OR NEW.uncertain_count IS NOT OLD.uncertain_count)\nBEGIN\n    SELECT RAISE(ABORT, 'Comparison results are immutable after a terminal state');\nEND;"),
            ("trg_comparison_results_insert_guard",
             "CREATE TRIGGER IF NOT EXISTS trg_comparison_results_insert_guard\nBEFORE INSERT ON comparison_results\nWHEN (SELECT status FROM comparisons WHERE id = NEW.comparison_id) IN ('complete', 'cancelled', 'failed')\nBEGIN\n    SELECT RAISE(ABORT, 'Cannot add results to a terminal comparison');\nEND;"),
            ("trg_comparison_results_update_guard",
             "CREATE TRIGGER IF NOT EXISTS trg_comparison_results_update_guard\nBEFORE UPDATE ON comparison_results\nWHEN (SELECT status FROM comparisons WHERE id = OLD.comparison_id) IN ('complete', 'cancelled', 'failed')\nBEGIN\n    SELECT RAISE(ABORT, 'Comparison results are immutable after a terminal state');\nEND;"),
            ("trg_comparison_results_delete_guard",
             "CREATE TRIGGER IF NOT EXISTS trg_comparison_results_delete_guard\nBEFORE DELETE ON comparison_results\nWHEN (SELECT status FROM comparisons WHERE id = OLD.comparison_id) IN ('complete', 'cancelled', 'failed')\nBEGIN\n    SELECT RAISE(ABORT, 'Comparison results are immutable after a terminal state');\nEND;"),
            ("trg_comparison_collision_groups_insert_guard",
             "CREATE TRIGGER IF NOT EXISTS trg_comparison_collision_groups_insert_guard\nBEFORE INSERT ON comparison_collision_groups\nWHEN (SELECT status FROM comparisons WHERE id = NEW.comparison_id) IN ('complete', 'cancelled', 'failed')\nBEGIN\n    SELECT RAISE(ABORT, 'Cannot add collision groups to a terminal comparison');\nEND;"),
            ("trg_comparison_collision_groups_update_guard",
             "CREATE TRIGGER IF NOT EXISTS trg_comparison_collision_groups_update_guard\nBEFORE UPDATE ON comparison_collision_groups\nWHEN (SELECT status FROM comparisons WHERE id = OLD.comparison_id) IN ('complete', 'cancelled', 'failed')\nBEGIN\n    SELECT RAISE(ABORT, 'Collision groups are immutable after a terminal state');\nEND;"),
            ("trg_comparison_collision_groups_delete_guard",
             "CREATE TRIGGER IF NOT EXISTS trg_comparison_collision_groups_delete_guard\nBEFORE DELETE ON comparison_collision_groups\nWHEN (SELECT status FROM comparisons WHERE id = OLD.comparison_id) IN ('complete', 'cancelled', 'failed')\nBEGIN\n    SELECT RAISE(ABORT, 'Collision groups are immutable after a terminal state');\nEND;"),
            ("trg_comparison_collision_members_insert_guard",
             "CREATE TRIGGER IF NOT EXISTS trg_comparison_collision_members_insert_guard\nBEFORE INSERT ON comparison_collision_members\nWHEN (SELECT c.status FROM comparisons c\n      JOIN comparison_collision_groups g ON g.comparison_id = c.id\n      WHERE g.id = NEW.group_id) IN ('complete', 'cancelled', 'failed')\nBEGIN\n    SELECT RAISE(ABORT, 'Cannot add collision members to a terminal comparison');\nEND;"),
            ("trg_comparison_collision_members_update_guard",
             "CREATE TRIGGER IF NOT EXISTS trg_comparison_collision_members_update_guard\nBEFORE UPDATE ON comparison_collision_members\nWHEN (SELECT c.status FROM comparisons c\n      JOIN comparison_collision_groups g ON g.comparison_id = c.id\n      WHERE g.id = OLD.group_id) IN ('complete', 'cancelled', 'failed')\nBEGIN\n    SELECT RAISE(ABORT, 'Collision members are immutable after a terminal state');\nEND;"),
            ("trg_comparison_collision_members_delete_guard",
             "CREATE TRIGGER IF NOT EXISTS trg_comparison_collision_members_delete_guard\nBEFORE DELETE ON comparison_collision_members\nWHEN (SELECT c.status FROM comparisons c\n      JOIN comparison_collision_groups g ON g.comparison_id = c.id\n      WHERE g.id = OLD.group_id) IN ('complete', 'cancelled', 'failed')\nBEGIN\n    SELECT RAISE(ABORT, 'Collision members are immutable after a terminal state');\nEND;"),
            ("trg_collections_last_used_at_insert",
             "CREATE TRIGGER IF NOT EXISTS trg_collections_last_used_at_insert\nAFTER INSERT ON snapshots\nWHEN NEW.collection_id IS NOT NULL\nBEGIN\n    UPDATE collections\n    SET last_used_at = CURRENT_TIMESTAMP\n    WHERE id = NEW.collection_id;\nEND;"),
            ("trg_collections_last_used_at_update",
             "CREATE TRIGGER IF NOT EXISTS trg_collections_last_used_at_update\nAFTER UPDATE OF collection_id ON snapshots\nWHEN NEW.collection_id IS NOT NULL AND (OLD.collection_id IS NULL OR OLD.collection_id != NEW.collection_id)\nBEGIN\n    UPDATE collections\n    SET last_used_at = CURRENT_TIMESTAMP\n    WHERE id = NEW.collection_id;\nEND;")
        ]

        /// Every canonical index, name and DDL, with the same definition
        /// guarantee as the trigger list.
        public static let indexDefinitions: [(name: String, sql: String)] = [
            ("idx_volumes_persistent_uuid",
             "CREATE INDEX IF NOT EXISTS idx_volumes_persistent_uuid\nON volumes(persistent_uuid)\nWHERE persistent_uuid IS NOT NULL;"),
            ("idx_volumes_fallback_fingerprint",
             "CREATE INDEX IF NOT EXISTS idx_volumes_fallback_fingerprint\nON volumes(fallback_fingerprint);"),
            ("idx_snapshots_volume_status",
             "CREATE INDEX IF NOT EXISTS idx_snapshots_volume_status\nON snapshots(volume_id, status, completed_at DESC);"),
            ("idx_snapshots_collection",
             "CREATE INDEX IF NOT EXISTS idx_snapshots_collection\nON snapshots(collection_id, started_at DESC);"),
            ("idx_entries_snapshot_parent_sort",
             "CREATE INDEX IF NOT EXISTS idx_entries_snapshot_parent_sort\nON entries(snapshot_id, parent_id, sort_key);"),
            ("idx_entries_snapshot_case_preserving_path",
             "CREATE INDEX IF NOT EXISTS idx_entries_snapshot_case_preserving_path\nON entries(snapshot_id, case_preserving_path);"),
            ("idx_entries_snapshot_case_folded_path",
             "CREATE INDEX IF NOT EXISTS idx_entries_snapshot_case_folded_path\nON entries(snapshot_id, case_folded_path);"),
            ("idx_entries_snapshot_case_preserving_name",
             "CREATE INDEX IF NOT EXISTS idx_entries_snapshot_case_preserving_name\nON entries(snapshot_id, case_preserving_name);"),
            ("idx_entries_snapshot_case_folded_name",
             "CREATE INDEX IF NOT EXISTS idx_entries_snapshot_case_folded_name\nON entries(snapshot_id, case_folded_name);"),
            ("idx_entries_snapshot_type",
             "CREATE INDEX IF NOT EXISTS idx_entries_snapshot_type\nON entries(snapshot_id, item_type);"),
            ("idx_entries_snapshot_extension",
             "CREATE INDEX IF NOT EXISTS idx_entries_snapshot_extension\nON entries(snapshot_id, file_extension);"),
            ("idx_scan_issues_snapshot",
             "CREATE INDEX IF NOT EXISTS idx_scan_issues_snapshot\nON scan_issues(snapshot_id, severity);"),
            ("idx_scan_issues_snapshot_source",
             "CREATE INDEX IF NOT EXISTS idx_scan_issues_snapshot_source\nON scan_issues(snapshot_id, source, severity);"),
            ("idx_comparison_results_parent",
             "CREATE INDEX IF NOT EXISTS idx_comparison_results_parent\nON comparison_results(comparison_id, parent_result_id, result_type, display_name);"),
            ("idx_comparison_results_parent_result_id",
             "CREATE INDEX IF NOT EXISTS idx_comparison_results_parent_result_id\nON comparison_results(parent_result_id);"),
            ("idx_comparison_results_uncertain_group",
             "CREATE INDEX IF NOT EXISTS idx_comparison_results_uncertain_group\nON comparison_results(comparison_id, result_path)\nWHERE result_type = 'uncertain';"),
            ("idx_comparison_results_type",
             "CREATE INDEX IF NOT EXISTS idx_comparison_results_type\nON comparison_results(comparison_id, result_type);")
        ]

        public static let snapshotColumns = [
            "volume_display_name_at_capture",
            "volume_identifier_at_capture",
            "volume_total_capacity_bytes_at_capture"
        ]

        public static let comparisonColumns = ["profile_version"]
        public static let profileColumns = ["version"]
        public static let classificationColumns = ["provider_identifier"]

        /// Deterministic normalization used to compare a stored SQLite object
        /// definition against the canonical one. SQLite stores trigger and
        /// index text as written (minus leading comments), except that
        /// `IF NOT EXISTS` clauses are not preserved and line breaks inside
        /// the statement are. Removing those differences plus case and
        /// whitespace leaves a comparison that rejects any materially
        /// different definition while accepting purely textual variations.
        public static func normalizedObjectSQL(_ sql: String) -> String {
            var stripped = ""
            var index = sql.startIndex
            var inSingleQuote = false
            var inDoubleQuote = false
            while index < sql.endIndex {
                let char = sql[index]
                if char == "'" {
                    inSingleQuote.toggle()
                    stripped.append(char)
                    index = sql.index(after: index)
                    continue
                }
                if char == "\"" {
                    inDoubleQuote.toggle()
                    stripped.append(char)
                    index = sql.index(after: index)
                    continue
                }
                let rest = sql[index...]
                if !inSingleQuote && !inDoubleQuote, rest.hasPrefix("--") {
                    while index < sql.endIndex, sql[index] != "\n" {
                        index = sql.index(after: index)
                    }
                    continue
                }
                if !inSingleQuote && !inDoubleQuote, rest.hasPrefix("/*") {
                    var after = sql.index(after: index)
                    var closed = false
                    while after < sql.endIndex {
                        if sql[after] == "*", sql[sql.index(after: after)...].hasPrefix("/") {
                            closed = true
                            break
                        }
                        after = sql.index(after: after)
                    }
                    // Skip past the closing "*/" (or to the end if unterminated).
                    index = closed ? sql.index(after, offsetBy: 2) : sql.endIndex
                    continue
                }
                stripped.append(char)
                index = sql.index(after: index)
            }

            let withoutIfNotExists = stripped.replacingOccurrences(
                of: #"\bIF\s+NOT\s+EXISTS\b"#,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            let collapsed = withoutIfNotExists
                .split(whereSeparator: { $0.isWhitespace })
                .joined(separator: " ")
                .lowercased()
            var trimmed = collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasSuffix(";") {
                trimmed.removeLast()
            }
            return trimmed
        }
    }
}
