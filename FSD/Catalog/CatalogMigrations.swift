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
    public static let currentVersion: Int64 = 13

    /// The oldest version that can be migrated forward. Versions 1 through 3
    /// never existed as a materialized database, so they have no migration and
    /// are rejected rather than guessed at.
    public static let oldestMigratableVersion: Int64 = 4

    public static let all: [SchemaMigration] = [
        migrationToVersion5, migrationToVersion6, migrationToVersion7, migrationToVersion8, migrationToVersion9, migrationToVersion10, migrationToVersion11, migrationToVersion12, migrationToVersion13
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
    /// Additive only: no historical identity inference or backfill.
    public static let migrationToVersion10 = SchemaMigration(version: 10, statements:
        identityTableDefinitions.map(\.sql) + identityIndexDefinitions.map(\.sql) + identityTriggerDefinitions.map(\.sql)
    )

    public static let identityTableDefinitions: [(name: String, sql: String)] = [
        ("physical_drives", "CREATE TABLE physical_drives (\n    id TEXT NOT NULL PRIMARY KEY CHECK (length(id) = 36),\n    label TEXT CHECK (label IS NULL OR length(CAST(label AS BLOB)) BETWEEN 1 AND 256),\n    admission TEXT NOT NULL CHECK (admission = 'explicit_local'),\n    provenance TEXT NOT NULL CHECK (length(CAST(provenance AS BLOB)) BETWEEN 1 AND 1024 AND instr(provenance, char(0)) = 0),\n    revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),\n    retired INTEGER NOT NULL DEFAULT 0 CHECK (retired IN (0,1)),\n    created_at TEXT NOT NULL,\n    updated_at TEXT NOT NULL\n);"),
        ("identity_observations", "CREATE TABLE identity_observations (\n    id TEXT NOT NULL PRIMARY KEY CHECK (length(id) = 36),\n    session_id TEXT NOT NULL CHECK (length(session_id) = 36),\n    revision INTEGER NOT NULL CHECK (revision >= 1),\n    scope TEXT NOT NULL CHECK (scope IN ('device','media','partition','volume','mountSession')),\n    state TEXT NOT NULL CHECK (state IN ('unknown','ambiguous','conflict')),\n    provenance TEXT NOT NULL CHECK (length(CAST(provenance AS BLOB)) BETWEEN 1 AND 1024 AND instr(provenance, char(0)) = 0),\n    observed_at TEXT NOT NULL,\n    UNIQUE (id, revision)\n);"),
        ("identity_evidence", "CREATE TABLE identity_evidence (\n    id TEXT NOT NULL PRIMARY KEY CHECK (length(id) = 36),\n    observation_id TEXT NOT NULL,\n    observation_revision INTEGER NOT NULL,\n    scope TEXT NOT NULL,\n    kind TEXT NOT NULL,\n    provider TEXT NOT NULL CHECK (provider IN ('synthetic','diskArbitration','ioKit','foundation')),\n    property TEXT NOT NULL CHECK (length(CAST(property AS BLOB)) BETWEEN 1 AND 256 AND instr(property, char(0)) = 0),\n    dependency_group TEXT NOT NULL,\n    value TEXT CHECK (value IS NULL OR (length(CAST(value AS BLOB)) BETWEEN 1 AND 1024 AND instr(value, char(0)) = 0)),\n    validation TEXT NOT NULL CHECK (validation IN ('unverified','validated','unknown','conflict')),\n    provenance TEXT NOT NULL CHECK (length(CAST(provenance AS BLOB)) BETWEEN 1 AND 1024 AND instr(provenance, char(0)) = 0),\n    observed_at TEXT NOT NULL,\n    CHECK ((kind = 'filesystemUUID' AND dependency_group = 'filesystemUUID' AND scope = 'volume') OR (kind = 'mediaUUID' AND dependency_group = 'mediaUUID' AND scope = 'media') OR (kind = 'partitionUUID' AND dependency_group = 'partitionUUID' AND scope = 'partition') OR (kind = 'deviceSerial' AND dependency_group = 'deviceSerial' AND scope = 'device') OR (kind = 'displayName' AND dependency_group = 'displayName' AND scope = 'volume') OR (kind = 'mountPath' AND dependency_group = 'mountPath' AND scope = 'mountSession') OR (kind = 'bsdNode' AND dependency_group = 'bsdNode' AND scope = 'mountSession') OR (kind = 'vendorModel' AND dependency_group = 'vendorModel' AND scope = 'device')),\n    CHECK ((validation = 'unknown' AND value IS NULL) OR (validation != 'unknown' AND value IS NOT NULL)),\n    FOREIGN KEY (observation_id, observation_revision) REFERENCES identity_observations(id, revision) ON DELETE RESTRICT ON UPDATE RESTRICT,\n    UNIQUE (observation_id, provider, property)\n);"),
        ("manual_drive_associations", "CREATE TABLE manual_drive_associations (\n    id TEXT NOT NULL PRIMARY KEY CHECK (length(id) = 36),\n    observation_id TEXT NOT NULL,\n    observation_revision INTEGER NOT NULL,\n    revision INTEGER NOT NULL CHECK (revision >= 1),\n    previous_event_id TEXT REFERENCES manual_drive_associations(id) ON DELETE RESTRICT ON UPDATE RESTRICT,\n    target_drive_id TEXT REFERENCES physical_drives(id) ON DELETE RESTRICT ON UPDATE RESTRICT,\n    target_revision INTEGER,\n    action TEXT NOT NULL CHECK (action IN ('associate','correct','revoke')),\n    actor TEXT NOT NULL CHECK (length(CAST(actor AS BLOB)) BETWEEN 1 AND 256 AND instr(actor, char(0)) = 0),\n    reason TEXT NOT NULL CHECK (length(CAST(reason AS BLOB)) BETWEEN 1 AND 1024 AND instr(reason, char(0)) = 0),\n    created_at TEXT NOT NULL,\n    CHECK ((action = 'revoke' AND target_drive_id IS NULL AND target_revision IS NULL) OR\n           (action != 'revoke' AND target_drive_id IS NOT NULL AND target_revision >= 1)),\n    FOREIGN KEY (observation_id, observation_revision) REFERENCES identity_observations(id, revision) ON DELETE RESTRICT ON UPDATE RESTRICT,\n    UNIQUE (observation_id, revision)\n);")
    ]

    public static let identityIndexDefinitions: [(name: String, sql: String)] = [
        ("idx_identity_evidence_observation", "CREATE INDEX idx_identity_evidence_observation ON identity_evidence(observation_id, id);"),
        ("idx_manual_associations_observation", "CREATE INDEX idx_manual_associations_observation ON manual_drive_associations(observation_id, revision DESC);")
    ]

    public static let identityTriggerDefinitions: [(name: String, sql: String)] = [
        ("trg_physical_drives_no_delete", "CREATE TRIGGER trg_physical_drives_no_delete\nBEFORE DELETE ON physical_drives\nBEGIN\n    SELECT RAISE(ABORT, 'Local identity history cannot be deleted');\nEND;"),
        ("trg_identity_observations_no_delete", "CREATE TRIGGER trg_identity_observations_no_delete\nBEFORE DELETE ON identity_observations\nBEGIN\n    SELECT RAISE(ABORT, 'Local identity history cannot be deleted');\nEND;"),
        ("trg_identity_observations_no_update", "CREATE TRIGGER trg_identity_observations_no_update\nBEFORE UPDATE ON identity_observations\nBEGIN\n    SELECT RAISE(ABORT, 'Local identity evidence is immutable');\nEND;"),
        ("trg_identity_evidence_no_delete", "CREATE TRIGGER trg_identity_evidence_no_delete\nBEFORE DELETE ON identity_evidence\nBEGIN\n    SELECT RAISE(ABORT, 'Local identity history cannot be deleted');\nEND;"),
        ("trg_identity_evidence_no_update", "CREATE TRIGGER trg_identity_evidence_no_update\nBEFORE UPDATE ON identity_evidence\nBEGIN\n    SELECT RAISE(ABORT, 'Local identity evidence is immutable');\nEND;"),
        ("trg_manual_drive_associations_no_delete", "CREATE TRIGGER trg_manual_drive_associations_no_delete\nBEFORE DELETE ON manual_drive_associations\nBEGIN\n    SELECT RAISE(ABORT, 'Local identity history cannot be deleted');\nEND;"),
        ("trg_manual_drive_associations_no_update", "CREATE TRIGGER trg_manual_drive_associations_no_update\nBEFORE UPDATE ON manual_drive_associations\nBEGIN\n    SELECT RAISE(ABORT, 'Local identity evidence is immutable');\nEND;"),
        ("trg_physical_drives_revision", "CREATE TRIGGER trg_physical_drives_revision\nBEFORE UPDATE ON physical_drives\nWHEN NEW.id IS NOT OLD.id OR NEW.admission IS NOT OLD.admission\n  OR NEW.provenance IS NOT OLD.provenance OR NEW.created_at IS NOT OLD.created_at\n  OR OLD.retired = 1 OR NEW.revision != OLD.revision + 1\nBEGIN\n    SELECT RAISE(ABORT, 'Invalid local drive revision or lifecycle');\nEND;"),
        ("trg_identity_evidence_scope", "CREATE TRIGGER trg_identity_evidence_scope\nBEFORE INSERT ON identity_evidence\nWHEN NEW.scope IS NOT (SELECT scope FROM identity_observations WHERE id = NEW.observation_id AND revision = NEW.observation_revision)\nBEGIN\n    SELECT RAISE(ABORT, 'Evidence scope differs from observation');\nEND;"),
        ("trg_manual_associations_admission", "CREATE TRIGGER trg_manual_associations_admission\nBEFORE INSERT ON manual_drive_associations\nBEGIN\n    SELECT CASE\n      WHEN NEW.revision != COALESCE((SELECT MAX(revision) FROM manual_drive_associations WHERE observation_id = NEW.observation_id),0) + 1\n        OR NEW.previous_event_id IS NOT (SELECT id FROM manual_drive_associations WHERE observation_id = NEW.observation_id ORDER BY revision DESC LIMIT 1)\n        THEN RAISE(ABORT, 'Stale manual association revision')\n      WHEN NEW.action = 'associate' AND NEW.revision != 1\n        THEN RAISE(ABORT, 'Association already has history; use correction')\n      WHEN NEW.action IN ('correct','revoke') AND NEW.revision = 1\n        THEN RAISE(ABORT, 'Correction requires prior history')\n      WHEN NEW.action != 'revoke' AND NOT EXISTS (SELECT 1 FROM physical_drives WHERE id = NEW.target_drive_id AND revision = NEW.target_revision AND retired = 0)\n        THEN RAISE(ABORT, 'Missing, retired or stale drive')\n      WHEN NEW.action != 'revoke' AND NOT EXISTS (SELECT 1 FROM identity_observations WHERE id = NEW.observation_id AND revision = NEW.observation_revision AND scope IN ('volume','partition') AND state != 'conflict')\n        THEN RAISE(ABORT, 'Invalid manual observation')\n    END;\nEND;")
    ]

    public static let migrationToVersion11 = SchemaMigration(version: 11, statements:
        driveSetTableDefinitions.map(\.sql) + driveSetIndexDefinitions.map(\.sql) + driveSetTriggerDefinitions.map(\.sql))

    public static let driveSetTableDefinitions: [(name: String, sql: String)] = [
        ("drive_sets", "CREATE TABLE drive_sets (\n    id TEXT NOT NULL PRIMARY KEY CHECK (length(id) = 36),\n    name TEXT NOT NULL CHECK (length(CAST(name AS BLOB)) BETWEEN 1 AND 256 AND instr(name, char(0)) = 0),\n    normalized_name TEXT NOT NULL UNIQUE CHECK (length(CAST(normalized_name AS BLOB)) BETWEEN 1 AND 1024),\n    normalization_version TEXT NOT NULL CHECK (normalization_version = 'fsd-drive-set-name-v1'),\n    revision INTEGER NOT NULL DEFAULT 1 CHECK (typeof(revision) = 'integer' AND revision >= 1),\n    created_at TEXT NOT NULL,\n    updated_at TEXT NOT NULL\n);"),
        ("drive_set_memberships", "CREATE TABLE drive_set_memberships (\n    set_id TEXT NOT NULL REFERENCES drive_sets(id) ON DELETE CASCADE ON UPDATE RESTRICT,\n    physical_drive_id TEXT NOT NULL REFERENCES physical_drives(id) ON DELETE RESTRICT ON UPDATE RESTRICT,\n    added_at TEXT NOT NULL,\n    admission TEXT NOT NULL CHECK (admission = 'explicit_local_selection'),\n    PRIMARY KEY (set_id, physical_drive_id)\n);")
    ]

    public static let driveSetIndexDefinitions: [(name: String, sql: String)] = [
        ("idx_drive_sets_order", "CREATE INDEX idx_drive_sets_order ON drive_sets(normalized_name, id);"),
        ("idx_drive_set_memberships_drive", "CREATE INDEX idx_drive_set_memberships_drive ON drive_set_memberships(physical_drive_id, set_id);")
    ]

    public static let driveSetTriggerDefinitions: [(name: String, sql: String)] = [
        ("trg_drive_sets_revision", "CREATE TRIGGER trg_drive_sets_revision\nBEFORE UPDATE ON drive_sets\nWHEN NEW.id IS NOT OLD.id OR NEW.created_at IS NOT OLD.created_at\n  OR NEW.normalization_version IS NOT OLD.normalization_version OR NEW.revision != OLD.revision + 1\nBEGIN\n    SELECT RAISE(ABORT, 'Invalid Drive Set revision');\nEND;"),
        ("trg_drive_set_memberships_admission", "CREATE TRIGGER trg_drive_set_memberships_admission\nBEFORE INSERT ON drive_set_memberships\nWHEN NOT EXISTS (SELECT 1 FROM physical_drives WHERE id = NEW.physical_drive_id AND retired = 0)\nBEGIN\n    SELECT RAISE(ABORT, 'Missing or retired local drive');\nEND;"),
        ("trg_drive_set_memberships_no_update", "CREATE TRIGGER trg_drive_set_memberships_no_update\nBEFORE UPDATE ON drive_set_memberships\nBEGIN\n    SELECT RAISE(ABORT, 'Membership must be explicitly removed and added');\nEND;")
    ]

    public static let migrationToVersion12 = SchemaMigration(version: 12, statements:
        receiptTableDefinitions.map(\.sql) + receiptIndexDefinitions.map(\.sql) + receiptTriggerDefinitions.map(\.sql) + ["INSERT INTO comparison_receipt_catalog(singleton,generation) VALUES (1, lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(6))));"])

    public static let receiptTableDefinitions: [(name: String, sql: String)] = [
        ("comparison_receipt_catalog", "CREATE TABLE comparison_receipt_catalog (\n    singleton INTEGER PRIMARY KEY CHECK (singleton = 1),\n    generation TEXT NOT NULL UNIQUE CHECK (length(generation) = 36)\n);"),
        ("comparison_completion_receipts", "CREATE TABLE comparison_completion_receipts (\n    comparison_id INTEGER PRIMARY KEY REFERENCES comparisons(id) ON DELETE CASCADE,\n    catalog_generation TEXT NOT NULL REFERENCES comparison_receipt_catalog(generation) ON DELETE RESTRICT,\n    completion_token TEXT NOT NULL UNIQUE CHECK (length(completion_token) = 36),\n    receipt_version INTEGER NOT NULL CHECK (receipt_version = 1),\n    encoding TEXT NOT NULL CHECK (encoding = 'fsd-receipt-json-utf8-v1'),\n    completed_at TEXT NOT NULL,\n    left_snapshot_id INTEGER NOT NULL,\n    right_snapshot_id INTEGER NOT NULL,\n    profile_id INTEGER NOT NULL,\n    profile_revision INTEGER NOT NULL,\n    matched_count INTEGER NOT NULL CHECK (matched_count >= 0),\n    added_count INTEGER NOT NULL CHECK (added_count >= 0),\n    removed_count INTEGER NOT NULL CHECK (removed_count >= 0),\n    changed_count INTEGER NOT NULL CHECK (changed_count >= 0),\n    uncertain_count INTEGER NOT NULL CHECK (uncertain_count >= 0),\n    payload BLOB NOT NULL CHECK (typeof(payload) = 'blob' AND length(payload) BETWEEN 1 AND 8388608)\n);")
    ]

    public static let receiptIndexDefinitions: [(name: String, sql: String)] = [
        ("idx_receipt_groups_order", "CREATE INDEX idx_receipt_groups_order ON comparison_collision_groups(comparison_id, id);"),
        ("idx_receipt_results_left", "CREATE INDEX idx_receipt_results_left ON comparison_results(comparison_id, left_entry_id) WHERE left_entry_id IS NOT NULL;"),
        ("idx_receipt_results_right", "CREATE INDEX idx_receipt_results_right ON comparison_results(comparison_id, right_entry_id) WHERE right_entry_id IS NOT NULL;"),
        ("idx_receipt_member_entry", "CREATE INDEX idx_receipt_member_entry ON comparison_collision_members(entry_id, side, group_id);"),
        ("idx_comparison_results_receipt", "CREATE INDEX idx_comparison_results_receipt ON comparison_results(comparison_id, id);"),
        ("idx_collision_members_receipt", "CREATE INDEX idx_collision_members_receipt ON comparison_collision_members(group_id, id);")
    ]

    public static let receiptTriggerDefinitions: [(name: String, sql: String)] = [
        ("trg_receipt_catalog_no_replace", "CREATE TRIGGER trg_receipt_catalog_no_replace BEFORE INSERT ON comparison_receipt_catalog\nWHEN EXISTS (SELECT 1 FROM comparison_receipt_catalog)\nBEGIN\n    SELECT RAISE(ABORT, 'Receipt catalog generation already exists');\nEND;"),
        ("trg_receipt_catalog_no_update", "CREATE TRIGGER trg_receipt_catalog_no_update BEFORE UPDATE ON comparison_receipt_catalog\nBEGIN\n    SELECT RAISE(ABORT, 'Receipt catalog generation is immutable');\nEND;"),
        ("trg_receipt_catalog_no_delete", "CREATE TRIGGER trg_receipt_catalog_no_delete BEFORE DELETE ON comparison_receipt_catalog\nBEGIN\n    SELECT RAISE(ABORT, 'Receipt catalog generation is immutable');\nEND;"),
        ("trg_comparisons_insert_not_complete", "CREATE TRIGGER trg_comparisons_insert_not_complete BEFORE INSERT ON comparisons\nWHEN NEW.status = 'complete'\nBEGIN\n    SELECT RAISE(ABORT, 'Completion requires an atomic receipt');\nEND;"),
        ("trg_comparisons_receipt_required", "CREATE TRIGGER trg_comparisons_receipt_required BEFORE UPDATE OF status ON comparisons\nWHEN NEW.status = 'complete' AND NOT EXISTS (\n    SELECT 1 FROM comparison_completion_receipts r WHERE r.comparison_id = NEW.id\n      AND r.completed_at IS NEW.completed_at\n      AND r.left_snapshot_id IS NEW.left_snapshot_id AND r.right_snapshot_id IS NEW.right_snapshot_id\n      AND r.profile_id IS NEW.profile_id AND r.profile_revision IS NEW.profile_version\n      AND r.matched_count = NEW.matched_count AND r.added_count = NEW.added_count\n      AND r.removed_count = NEW.removed_count AND r.changed_count = NEW.changed_count\n      AND r.uncertain_count = NEW.uncertain_count\n)\nBEGIN\n    SELECT RAISE(ABORT, 'Missing or inconsistent completion receipt');\nEND;"),
        ("trg_receipts_insert_guard", "CREATE TRIGGER trg_receipts_insert_guard BEFORE INSERT ON comparison_completion_receipts\nBEGIN\n    SELECT CASE WHEN fsd_completion_receipt_valid(NEW.payload,NEW.comparison_id,NEW.catalog_generation,NEW.completion_token,\n      NEW.receipt_version,NEW.encoding,NEW.completed_at,NEW.left_snapshot_id,NEW.right_snapshot_id,NEW.profile_id,NEW.profile_revision,\n      NEW.matched_count,NEW.added_count,NEW.removed_count,NEW.changed_count,NEW.uncertain_count) != 1\n      THEN RAISE(ABORT, 'Invalid typed completion receipt') END;\n    SELECT CASE WHEN NOT EXISTS (\n        SELECT 1 FROM comparisons c WHERE c.id = NEW.comparison_id AND c.status = 'running'\n          AND c.left_snapshot_id IS NEW.left_snapshot_id AND c.right_snapshot_id IS NEW.right_snapshot_id\n          AND c.profile_id IS NEW.profile_id AND c.profile_version IS NEW.profile_revision\n    ) THEN RAISE(ABORT, 'Receipt requires its running comparison') END;\n    SELECT CASE WHEN NEW.matched_count != (SELECT COUNT(*) FROM comparison_results WHERE comparison_id=NEW.comparison_id AND result_type='matched')\n      OR NEW.added_count != (SELECT COUNT(*) FROM comparison_results WHERE comparison_id=NEW.comparison_id AND result_type='added')\n      OR NEW.removed_count != (SELECT COUNT(*) FROM comparison_results WHERE comparison_id=NEW.comparison_id AND result_type='removed')\n      OR NEW.changed_count != (SELECT COUNT(*) FROM comparison_results WHERE comparison_id=NEW.comparison_id AND result_type='changed')\n      OR NEW.uncertain_count != (SELECT COUNT(*) FROM comparison_results WHERE comparison_id=NEW.comparison_id AND result_type='uncertain')\n      THEN RAISE(ABORT, 'Receipt result counts differ') END;\nEND;"),
        ("trg_receipts_complete_comparison", "CREATE TRIGGER trg_receipts_complete_comparison AFTER INSERT ON comparison_completion_receipts\nBEGIN\n    UPDATE comparisons SET status='complete', completed_at=NEW.completed_at,\n      matched_count=NEW.matched_count, added_count=NEW.added_count, removed_count=NEW.removed_count,\n      changed_count=NEW.changed_count, uncertain_count=NEW.uncertain_count\n    WHERE id=NEW.comparison_id AND status='running';\nEND;"),
        ("trg_receipts_no_update", "CREATE TRIGGER trg_receipts_no_update BEFORE UPDATE ON comparison_completion_receipts\nBEGIN\n    SELECT RAISE(ABORT, 'Completion receipts are immutable');\nEND;"),
        ("trg_receipts_no_delete", "CREATE TRIGGER trg_receipts_no_delete BEFORE DELETE ON comparison_completion_receipts\nWHEN EXISTS (SELECT 1 FROM comparisons WHERE id=OLD.comparison_id)\nBEGIN\n    SELECT RAISE(ABORT, 'Dispose the whole comparison');\nEND;"),
        ("trg_receipted_comparison_identity", "CREATE TRIGGER trg_receipted_comparison_identity BEFORE UPDATE ON comparisons\nWHEN OLD.status = 'complete' AND EXISTS (SELECT 1 FROM comparison_completion_receipts WHERE comparison_id=OLD.id)\n AND (NEW.id IS NOT OLD.id OR NEW.profile_id IS NOT OLD.profile_id\n      OR NEW.profile_version IS NOT OLD.profile_version OR NEW.started_at IS NOT OLD.started_at\n      OR NEW.completed_at IS NOT OLD.completed_at OR NEW.created_at IS NOT OLD.created_at)\nBEGIN\n    SELECT RAISE(ABORT, 'Receipted comparison identity is immutable');\nEND;")
    ]

    public static let migrationToVersion13 = SchemaMigration(version: 13, statements:
        savedTableDefinitions.map(\.sql) + savedIndexDefinitions.map(\.sql) + savedTriggerDefinitions.map(\.sql))

    public static let savedTableDefinitions: [(name: String, sql: String)] = [
        ("saved_comparisons", "CREATE TABLE saved_comparisons (\n    id TEXT PRIMARY KEY NOT NULL CHECK (length(id)=36),\n    state TEXT NOT NULL CHECK (state IN ('building','ready')),\n    format_version INTEGER NOT NULL CHECK (format_version=1),\n    receipt BLOB NOT NULL CHECK (typeof(receipt)='blob' AND length(receipt) BETWEEN 1 AND 8388608),\n    graph_sha256 TEXT CHECK (length(graph_sha256)=64),\n    created_at TEXT NOT NULL\n);"),
        ("saved_operations", "CREATE TABLE saved_operations (\n    id TEXT PRIMARY KEY NOT NULL CHECK (length(id)=36),\n    catalog_generation TEXT NOT NULL CHECK (length(catalog_generation)=36),\n    completion_token TEXT NOT NULL CHECK (length(completion_token)=36),\n    comparison_id INTEGER NOT NULL CHECK (comparison_id>0),\n    artifact_id TEXT NOT NULL UNIQUE CHECK (length(artifact_id)=36),\n    state TEXT NOT NULL CHECK (state IN ('ready','deleted'))\n);"),
        ("saved_trees", "CREATE TABLE saved_trees (\n    id INTEGER PRIMARY KEY,\n    artifact_id TEXT NOT NULL REFERENCES saved_comparisons(id) ON DELETE CASCADE,\n    side TEXT NOT NULL CHECK (side IN ('left','right')),\n    origin_snapshot_id INTEGER NOT NULL CHECK (origin_snapshot_id>0),\n    UNIQUE(artifact_id,side),\n    UNIQUE(id,artifact_id)\n);"),
        ("saved_entries", "CREATE TABLE saved_entries (\n    id INTEGER PRIMARY KEY,\n    artifact_id TEXT NOT NULL,\n    tree_id INTEGER NOT NULL,\n    origin_id INTEGER NOT NULL CHECK (origin_id>0),\n    parent_id INTEGER,\n    payload BLOB NOT NULL CHECK (typeof(payload)='blob' AND length(payload) BETWEEN 1 AND 524288),\n    UNIQUE(tree_id,origin_id),\n    UNIQUE(id,tree_id),\n    FOREIGN KEY (tree_id,artifact_id) REFERENCES saved_trees(id,artifact_id) ON DELETE CASCADE,\n    FOREIGN KEY (parent_id,tree_id) REFERENCES saved_entries(id,tree_id) DEFERRABLE INITIALLY DEFERRED\n);"),
        ("saved_issues", "CREATE TABLE saved_issues (\n    id INTEGER PRIMARY KEY,\n    artifact_id TEXT NOT NULL,\n    tree_id INTEGER NOT NULL,\n    origin_id INTEGER NOT NULL CHECK (origin_id>0),\n    entry_id INTEGER,\n    payload BLOB NOT NULL CHECK (typeof(payload)='blob' AND length(payload) BETWEEN 1 AND 524288),\n    UNIQUE(tree_id,origin_id),\n    FOREIGN KEY (tree_id,artifact_id) REFERENCES saved_trees(id,artifact_id) ON DELETE CASCADE,\n    FOREIGN KEY (entry_id,tree_id) REFERENCES saved_entries(id,tree_id) DEFERRABLE INITIALLY DEFERRED\n);"),
        ("saved_results", "CREATE TABLE saved_results (\n    id INTEGER PRIMARY KEY,\n    artifact_id TEXT NOT NULL REFERENCES saved_comparisons(id) ON DELETE CASCADE,\n    origin_id INTEGER NOT NULL CHECK (origin_id>0),\n    parent_id INTEGER,\n    left_tree_id INTEGER NOT NULL,\n    right_tree_id INTEGER NOT NULL,\n    left_entry_id INTEGER,\n    right_entry_id INTEGER,\n    payload BLOB NOT NULL CHECK (typeof(payload)='blob' AND length(payload) BETWEEN 1 AND 524288),\n    UNIQUE(artifact_id,origin_id),\n    UNIQUE(id,artifact_id),\n    FOREIGN KEY (parent_id,artifact_id) REFERENCES saved_results(id,artifact_id) DEFERRABLE INITIALLY DEFERRED,\n    FOREIGN KEY (left_tree_id,artifact_id) REFERENCES saved_trees(id,artifact_id),\n    FOREIGN KEY (right_tree_id,artifact_id) REFERENCES saved_trees(id,artifact_id),\n    FOREIGN KEY (left_entry_id,left_tree_id) REFERENCES saved_entries(id,tree_id) DEFERRABLE INITIALLY DEFERRED,\n    FOREIGN KEY (right_entry_id,right_tree_id) REFERENCES saved_entries(id,tree_id) DEFERRABLE INITIALLY DEFERRED\n);"),
        ("saved_collision_groups", "CREATE TABLE saved_collision_groups (\n    id INTEGER PRIMARY KEY,\n    artifact_id TEXT NOT NULL REFERENCES saved_comparisons(id) ON DELETE CASCADE,\n    origin_id INTEGER NOT NULL CHECK (origin_id>0),\n    payload BLOB NOT NULL CHECK (typeof(payload)='blob' AND length(payload) BETWEEN 1 AND 524288),\n    UNIQUE(artifact_id,origin_id),\n    UNIQUE(id,artifact_id)\n);"),
        ("saved_collision_members", "CREATE TABLE saved_collision_members (\n    id INTEGER PRIMARY KEY,\n    artifact_id TEXT NOT NULL,\n    origin_id INTEGER NOT NULL CHECK (origin_id>0),\n    group_id INTEGER NOT NULL,\n    side TEXT NOT NULL CHECK (side IN ('left','right')),\n    tree_id INTEGER NOT NULL,\n    entry_id INTEGER NOT NULL,\n    payload BLOB NOT NULL CHECK (typeof(payload)='blob' AND length(payload) BETWEEN 1 AND 524288),\n    UNIQUE(artifact_id,origin_id),\n    UNIQUE(group_id,side,entry_id),\n    FOREIGN KEY (group_id,artifact_id) REFERENCES saved_collision_groups(id,artifact_id) ON DELETE CASCADE,\n    FOREIGN KEY (tree_id,artifact_id) REFERENCES saved_trees(id,artifact_id),\n    FOREIGN KEY (entry_id,tree_id) REFERENCES saved_entries(id,tree_id)\n);")
    ]

    public static let savedIndexDefinitions: [(name: String, sql: String)] = [
        ("idx_saved_entries_parent", "CREATE INDEX idx_saved_entries_parent ON saved_entries(tree_id,parent_id);"),
        ("idx_saved_issues_entry", "CREATE INDEX idx_saved_issues_entry ON saved_issues(tree_id,entry_id);"),
        ("idx_saved_results_order", "CREATE INDEX idx_saved_results_order ON saved_results(artifact_id,id);"),
        ("idx_saved_collision_groups_order", "CREATE INDEX idx_saved_collision_groups_order ON saved_collision_groups(artifact_id,id);"),
        ("idx_saved_collision_members_order", "CREATE INDEX idx_saved_collision_members_order ON saved_collision_members(artifact_id,id);"),
        ("idx_saved_entries_order", "CREATE INDEX idx_saved_entries_order ON saved_entries(artifact_id,id);"),
        ("idx_saved_issues_order", "CREATE INDEX idx_saved_issues_order ON saved_issues(artifact_id,id);"),
        ("idx_saved_results_left", "CREATE INDEX idx_saved_results_left ON saved_results(left_entry_id,left_tree_id) WHERE left_entry_id IS NOT NULL;"),
        ("idx_saved_results_right", "CREATE INDEX idx_saved_results_right ON saved_results(right_entry_id,right_tree_id) WHERE right_entry_id IS NOT NULL;"),
        ("idx_saved_results_parent", "CREATE INDEX idx_saved_results_parent ON saved_results(artifact_id,parent_id);"),
        ("idx_saved_members_entry", "CREATE INDEX idx_saved_members_entry ON saved_collision_members(tree_id,entry_id);"),
        ("idx_saved_members_group", "CREATE INDEX idx_saved_members_group ON saved_collision_members(group_id,origin_id);")
    ]

    public static let savedTriggerDefinitions: [(name: String, sql: String)] = [
        ("trg_saved_artifact_insert", "CREATE TRIGGER trg_saved_artifact_insert BEFORE INSERT ON saved_comparisons\nWHEN NEW.state!='building' OR NEW.graph_sha256 IS NOT NULL OR EXISTS (SELECT 1 FROM saved_comparisons WHERE id=NEW.id) OR EXISTS (SELECT 1 FROM saved_operations WHERE artifact_id=NEW.id)\nBEGIN\n    SELECT RAISE(ABORT,'Saved artifact requires new explicit build');\nEND;"),
        ("trg_saved_artifact_update", "CREATE TRIGGER trg_saved_artifact_update BEFORE UPDATE ON saved_comparisons\nWHEN OLD.state!='building' OR NEW.state!='ready' OR NEW.id IS NOT OLD.id OR NEW.format_version IS NOT OLD.format_version OR NEW.receipt IS NOT OLD.receipt OR NEW.created_at IS NOT OLD.created_at OR NEW.graph_sha256 IS NULL\nBEGIN\n    SELECT RAISE(ABORT,'Saved artifact is immutable');\nEND;"),
        ("trg_saved_artifact_delete", "CREATE TRIGGER trg_saved_artifact_delete BEFORE DELETE ON saved_comparisons\nBEGIN\n    SELECT CASE WHEN OLD.state!='ready' OR NOT EXISTS (SELECT 1 FROM saved_operations WHERE artifact_id=OLD.id AND state='ready') THEN RAISE(ABORT,'Saved deletion requires operation receipt') END;\n    UPDATE saved_operations SET state='deleted' WHERE artifact_id=OLD.id;\nEND;"),
        ("trg_saved_operation_insert", "CREATE TRIGGER trg_saved_operation_insert BEFORE INSERT ON saved_operations\nWHEN NEW.state!='ready' OR NOT EXISTS (SELECT 1 FROM saved_comparisons WHERE id=NEW.artifact_id AND state='ready') OR EXISTS (SELECT 1 FROM saved_operations WHERE id=NEW.id)\nBEGIN\n    SELECT RAISE(ABORT,'Invalid saved operation publication');\nEND;"),
        ("trg_saved_operation_update", "CREATE TRIGGER trg_saved_operation_update BEFORE UPDATE ON saved_operations\nWHEN OLD.state!='ready' OR NEW.state!='deleted' OR NEW.id IS NOT OLD.id OR NEW.catalog_generation IS NOT OLD.catalog_generation OR NEW.completion_token IS NOT OLD.completion_token OR NEW.comparison_id IS NOT OLD.comparison_id OR NEW.artifact_id IS NOT OLD.artifact_id\nBEGIN\n    SELECT RAISE(ABORT,'Saved operation identity is immutable');\nEND;"),
        ("trg_saved_operation_delete", "CREATE TRIGGER trg_saved_operation_delete BEFORE DELETE ON saved_operations\nBEGIN\n    SELECT RAISE(ABORT,'Saved operation tombstones are permanent');\nEND;"),
        ("trg_saved_trees_insert", "CREATE TRIGGER trg_saved_trees_insert BEFORE INSERT ON saved_trees\nWHEN NOT EXISTS (SELECT 1 FROM saved_comparisons WHERE id=NEW.artifact_id AND state='building')\nBEGIN\n    SELECT RAISE(ABORT,'Saved evidence is immutable');\nEND;"),
        ("trg_saved_trees_update", "CREATE TRIGGER trg_saved_trees_update BEFORE UPDATE ON saved_trees\nWHEN EXISTS (SELECT 1 FROM saved_comparisons WHERE id=OLD.artifact_id AND state='ready') OR NEW.artifact_id IS NOT OLD.artifact_id OR NEW.id IS NOT OLD.id\nBEGIN\n    SELECT RAISE(ABORT,'Saved evidence is immutable');\nEND;"),
        ("trg_saved_trees_delete", "CREATE TRIGGER trg_saved_trees_delete BEFORE DELETE ON saved_trees\nWHEN EXISTS (SELECT 1 FROM saved_comparisons WHERE id=OLD.artifact_id AND state='ready')\nBEGIN\n    SELECT RAISE(ABORT,'Saved evidence is immutable');\nEND;"),
        ("trg_saved_entries_insert", "CREATE TRIGGER trg_saved_entries_insert BEFORE INSERT ON saved_entries\nWHEN NOT EXISTS (SELECT 1 FROM saved_comparisons WHERE id=NEW.artifact_id AND state='building')\nBEGIN\n    SELECT RAISE(ABORT,'Saved evidence is immutable');\nEND;"),
        ("trg_saved_entries_update", "CREATE TRIGGER trg_saved_entries_update BEFORE UPDATE ON saved_entries\nWHEN EXISTS (SELECT 1 FROM saved_comparisons WHERE id=OLD.artifact_id AND state='ready') OR NEW.artifact_id IS NOT OLD.artifact_id OR NEW.id IS NOT OLD.id\nBEGIN\n    SELECT RAISE(ABORT,'Saved evidence is immutable');\nEND;"),
        ("trg_saved_entries_delete", "CREATE TRIGGER trg_saved_entries_delete BEFORE DELETE ON saved_entries\nWHEN EXISTS (SELECT 1 FROM saved_comparisons WHERE id=OLD.artifact_id AND state='ready')\nBEGIN\n    SELECT RAISE(ABORT,'Saved evidence is immutable');\nEND;"),
        ("trg_saved_issues_insert", "CREATE TRIGGER trg_saved_issues_insert BEFORE INSERT ON saved_issues\nWHEN NOT EXISTS (SELECT 1 FROM saved_comparisons WHERE id=NEW.artifact_id AND state='building')\nBEGIN\n    SELECT RAISE(ABORT,'Saved evidence is immutable');\nEND;"),
        ("trg_saved_issues_update", "CREATE TRIGGER trg_saved_issues_update BEFORE UPDATE ON saved_issues\nWHEN EXISTS (SELECT 1 FROM saved_comparisons WHERE id=OLD.artifact_id AND state='ready') OR NEW.artifact_id IS NOT OLD.artifact_id OR NEW.id IS NOT OLD.id\nBEGIN\n    SELECT RAISE(ABORT,'Saved evidence is immutable');\nEND;"),
        ("trg_saved_issues_delete", "CREATE TRIGGER trg_saved_issues_delete BEFORE DELETE ON saved_issues\nWHEN EXISTS (SELECT 1 FROM saved_comparisons WHERE id=OLD.artifact_id AND state='ready')\nBEGIN\n    SELECT RAISE(ABORT,'Saved evidence is immutable');\nEND;"),
        ("trg_saved_results_insert", "CREATE TRIGGER trg_saved_results_insert BEFORE INSERT ON saved_results\nWHEN NOT EXISTS (SELECT 1 FROM saved_comparisons WHERE id=NEW.artifact_id AND state='building')\nBEGIN\n    SELECT RAISE(ABORT,'Saved evidence is immutable');\nEND;"),
        ("trg_saved_results_update", "CREATE TRIGGER trg_saved_results_update BEFORE UPDATE ON saved_results\nWHEN EXISTS (SELECT 1 FROM saved_comparisons WHERE id=OLD.artifact_id AND state='ready') OR NEW.artifact_id IS NOT OLD.artifact_id OR NEW.id IS NOT OLD.id\nBEGIN\n    SELECT RAISE(ABORT,'Saved evidence is immutable');\nEND;"),
        ("trg_saved_results_delete", "CREATE TRIGGER trg_saved_results_delete BEFORE DELETE ON saved_results\nWHEN EXISTS (SELECT 1 FROM saved_comparisons WHERE id=OLD.artifact_id AND state='ready')\nBEGIN\n    SELECT RAISE(ABORT,'Saved evidence is immutable');\nEND;"),
        ("trg_saved_collision_groups_insert", "CREATE TRIGGER trg_saved_collision_groups_insert BEFORE INSERT ON saved_collision_groups\nWHEN NOT EXISTS (SELECT 1 FROM saved_comparisons WHERE id=NEW.artifact_id AND state='building')\nBEGIN\n    SELECT RAISE(ABORT,'Saved evidence is immutable');\nEND;"),
        ("trg_saved_collision_groups_update", "CREATE TRIGGER trg_saved_collision_groups_update BEFORE UPDATE ON saved_collision_groups\nWHEN EXISTS (SELECT 1 FROM saved_comparisons WHERE id=OLD.artifact_id AND state='ready') OR NEW.artifact_id IS NOT OLD.artifact_id OR NEW.id IS NOT OLD.id\nBEGIN\n    SELECT RAISE(ABORT,'Saved evidence is immutable');\nEND;"),
        ("trg_saved_collision_groups_delete", "CREATE TRIGGER trg_saved_collision_groups_delete BEFORE DELETE ON saved_collision_groups\nWHEN EXISTS (SELECT 1 FROM saved_comparisons WHERE id=OLD.artifact_id AND state='ready')\nBEGIN\n    SELECT RAISE(ABORT,'Saved evidence is immutable');\nEND;"),
        ("trg_saved_collision_members_insert", "CREATE TRIGGER trg_saved_collision_members_insert BEFORE INSERT ON saved_collision_members\nWHEN NOT EXISTS (SELECT 1 FROM saved_comparisons WHERE id=NEW.artifact_id AND state='building')\nBEGIN\n    SELECT RAISE(ABORT,'Saved evidence is immutable');\nEND;"),
        ("trg_saved_collision_members_update", "CREATE TRIGGER trg_saved_collision_members_update BEFORE UPDATE ON saved_collision_members\nWHEN EXISTS (SELECT 1 FROM saved_comparisons WHERE id=OLD.artifact_id AND state='ready') OR NEW.artifact_id IS NOT OLD.artifact_id OR NEW.id IS NOT OLD.id\nBEGIN\n    SELECT RAISE(ABORT,'Saved evidence is immutable');\nEND;"),
        ("trg_saved_collision_members_delete", "CREATE TRIGGER trg_saved_collision_members_delete BEFORE DELETE ON saved_collision_members\nWHEN EXISTS (SELECT 1 FROM saved_comparisons WHERE id=OLD.artifact_id AND state='ready')\nBEGIN\n    SELECT RAISE(ABORT,'Saved evidence is immutable');\nEND;"),
        ("trg_saved_results_side_insert", "CREATE TRIGGER trg_saved_results_side_insert BEFORE INSERT ON saved_results\nWHEN NOT EXISTS (SELECT 1 FROM saved_trees WHERE id=NEW.left_tree_id AND artifact_id=NEW.artifact_id AND side='left') OR NOT EXISTS (SELECT 1 FROM saved_trees WHERE id=NEW.right_tree_id AND artifact_id=NEW.artifact_id AND side='right')\nBEGIN\n    SELECT RAISE(ABORT,'Wrong saved side');\nEND;"),
        ("trg_saved_results_side_update", "CREATE TRIGGER trg_saved_results_side_update BEFORE UPDATE ON saved_results\nWHEN NOT EXISTS (SELECT 1 FROM saved_trees WHERE id=NEW.left_tree_id AND artifact_id=NEW.artifact_id AND side='left') OR NOT EXISTS (SELECT 1 FROM saved_trees WHERE id=NEW.right_tree_id AND artifact_id=NEW.artifact_id AND side='right')\nBEGIN\n    SELECT RAISE(ABORT,'Wrong saved side');\nEND;"),
        ("trg_saved_collision_members_side_insert", "CREATE TRIGGER trg_saved_collision_members_side_insert BEFORE INSERT ON saved_collision_members\nWHEN NOT EXISTS (SELECT 1 FROM saved_trees WHERE id=NEW.tree_id AND artifact_id=NEW.artifact_id AND side=NEW.side)\nBEGIN\n    SELECT RAISE(ABORT,'Wrong saved side');\nEND;"),
        ("trg_saved_collision_members_side_update", "CREATE TRIGGER trg_saved_collision_members_side_update BEFORE UPDATE ON saved_collision_members\nWHEN NOT EXISTS (SELECT 1 FROM saved_trees WHERE id=NEW.tree_id AND artifact_id=NEW.artifact_id AND side=NEW.side)\nBEGIN\n    SELECT RAISE(ABORT,'Wrong saved side');\nEND;")
    ]

    public enum ExpectedState {
        public static let tables = [
            "schema_migrations", "volumes", "collections", "source_collection_defaults",
            "snapshots", "entries", "scan_issues", "comparison_profiles", "comparisons",
            "comparison_collision_groups", "comparison_collision_members",
            "comparison_results", "entry_classifications"
        ] + identityTableDefinitions.map(\.name) + driveSetTableDefinitions.map(\.name) + receiptTableDefinitions.map(\.name) + savedTableDefinitions.map(\.name)

        /// Every canonical trigger, name and DDL. The DDL text is the
        /// `CREATE TRIGGER ... END;` statement as written in
        /// `docs/database/schema.sql`; `normalizedObjectSQL` removes the
        /// textual differences SQLite itself applies when storing it.
        public static let triggerDefinitions: [(name: String, sql: String)] = identityTriggerDefinitions + driveSetTriggerDefinitions + receiptTriggerDefinitions + savedTriggerDefinitions + [
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
        public static let indexDefinitions: [(name: String, sql: String)] = identityIndexDefinitions + driveSetIndexDefinitions + receiptIndexDefinitions + savedIndexDefinitions + [
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
