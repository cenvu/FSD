-- Schema version 9 (P15 runtime Slice 01; ADR-032): adds only the nullable,
-- no-default provider_identifier after the existing entry_classifications
-- columns. Legacy rows remain NULL; detector/model/provider are independent.
--
-- Schema version 8 (Milestone 5 disposal-performance correction; see
-- docs/DECISIONS.md ADR-030). This wave adds the dedicated leading index
-- required by SQLite's self-referencing comparison-result cascade lookup:
--   * idx_comparison_results_parent_result_id lets SQLite find children by
--     parent_result_id without scanning comparison_results for every deleted
--     result row; the existing composite index is retained unchanged because
--     it serves comparison-scoped result ordering and paging.
--
-- Schema version 7 (Milestone 4 schema-safety correction; see
-- docs/DECISIONS.md ADR-028). This wave makes a terminal comparison's whole
-- retained evidence immutable, not just its status and result rows:
--   * trg_comparison_results_delete_guard closes the one gap in ADR-027: an
--     individual result row could still be deleted after the terminal state;
--   * collision group and member INSERT/UPDATE/DELETE guards reject direct
--     mutation once a comparison is complete, cancelled or failed, while
--     writes stay allowed while it is running;
--   * the DELETE guards deliberately let rows disappear during whole-
--     comparison disposal: the cascade fires after the comparison row itself
--     is gone, so the guard's terminal-state probe finds nothing and disposal
--     (the explicit API, ADR-012/ADR-027) is unaffected.
--
-- Schema version 6 (Milestone 4 -- comparison result integrity; see
-- docs/DECISIONS.md ADR-027). This wave adds:
--   * comparison_profiles.version and comparisons.profile_version, so every
--     comparison record freezes the profile revision that produced it and a
--     later profile edit can never silently rewrite an old conclusion;
--   * trg_comparisons_terminal_immutable, which rejects any later UPDATE of
--     status or summary counts once a comparison reaches a terminal state;
--   * trg_comparison_results_insert_guard / update_guard, which reject any
--     later INSERT or UPDATE of result rows on a terminal comparison (deleting
--     a whole comparison remains the explicit disposal API);
--   * idx_comparison_results_type for bounded differences-only queries.
--
-- Schema version 5 (Milestone 3 -- capture-time volume truth and the first
-- real, explicit migration; see docs/DECISIONS.md ADR-023 and ADR-024). This
-- wave adds:
--   * three capture-time volume-fact columns on `snapshots`
--     (volume_display_name_at_capture, volume_identifier_at_capture,
--     volume_total_capacity_bytes_at_capture) so that history never presents a
--     mutable `volumes` registry value as an immutable historical fact;
--   * trg_snapshots_capture_facts_immutable, which rejects any later UPDATE of
--     a capture-time identity column;
--   * idx_entries_snapshot_extension for bounded offline metadata search.
--
-- Version 4 (Magika classification schema-preparation seam -- see
-- docs/ARCHITECTURE.md §9, docs/DECISIONS.md ADR-021, docs/MVP_PLAN.md
-- Phase 1.5) added ONLY the optional entry_classifications
-- enrichment table below. It is deliberately inert: the MVP scanner, diff
-- engine, and UI never write to or query this table, and it is expected to
-- contain zero rows for the entire MVP lifecycle. Version 3 was the snapshot
-- Collections wave -- see docs/SNAPSHOT_COLLECTIONS.md. Version 2 was the
-- filesystem-provider metadata wave (filesystem_provider,
-- provider_version, source_access_mode, device/partition identifiers,
-- filesystem_variant/features, authorization_required on snapshots; source
-- discriminator on scan_issues). Version 1 was the R0 corrective wave
-- (normalization_version, snapshot_kind, source_case_sensitivity,
-- case_preserving_path/case_folded_path, parent/root integrity constraints
-- and triggers, transient-safe comparisons). Each wave changed the schema
-- materially; schema.sql remains a single cumulative DDL file describing the
-- current state, so "version 9" names the cumulative state after this wave.
-- Applying this file to an empty database is the ONLY supported way to create
-- a catalog; moving an existing catalog forward is the job of the explicit
-- migration list, never of this file. Versions 1 through 3 have no migration
-- and never will: no version-1, -2, or -3 database was ever materialized.
-- All version 1 through version 6 constraints, triggers, and columns are
-- preserved unchanged below.

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;

CREATE TABLE IF NOT EXISTS schema_migrations (
    version             INTEGER PRIMARY KEY,
    applied_at          TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS volumes (
    id                  INTEGER PRIMARY KEY,
    persistent_uuid     TEXT,
    fallback_fingerprint TEXT,
    display_name        TEXT NOT NULL,
    user_label          TEXT,
    user_role           TEXT,
    filesystem_type     TEXT,
    total_capacity_bytes INTEGER,
    device_vendor       TEXT,
    device_model        TEXT,
    device_serial       TEXT,
    first_seen_at       TEXT NOT NULL,
    last_seen_at        TEXT NOT NULL,
    auto_capture_enabled INTEGER NOT NULL DEFAULT 0 CHECK (auto_capture_enabled IN (0, 1)),
    created_at          TEXT NOT NULL,
    updated_at          TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_volumes_persistent_uuid
ON volumes(persistent_uuid)
WHERE persistent_uuid IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_volumes_fallback_fingerprint
ON volumes(fallback_fingerprint);

-- Snapshot Collections (docs/SNAPSHOT_COLLECTIONS.md). A Collection is a
-- purely logical, user-defined grouping stored in SQLite -- never a folder on
-- a source volume, never a mutation of snapshot contents. There is no
-- built-in/system "Unsorted" row here by design: an unassigned or
-- Collection-deleted snapshot is represented by snapshots.collection_id being
-- NULL, displayed as "Unsorted" in the UI only (SNAPSHOT_COLLECTIONS.md §4).
CREATE TABLE IF NOT EXISTS collections (
    id              INTEGER PRIMARY KEY,
    name            TEXT NOT NULL,
    -- Same normalization recipe as ADR-009 (NFC + locale-independent case
    -- fold), applied to the whole name string rather than per path component.
    normalized_name TEXT NOT NULL,
    note            TEXT,
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL,
    -- Advances when a snapshot is assigned/moved into this Collection; drives
    -- "recent Collections" ordering in pickers. Not updated by mere viewing.
    last_used_at    TEXT,
    CHECK (trim(name) != ''),
    UNIQUE(normalized_name)
);

-- Remembered Collection per stable source identity (SNAPSHOT_COLLECTIONS.md
-- §6, §9.3). Deliberately volume-only in this schema version: `volumes`
-- already has a real canonical identity (persistent UUID or fallback
-- fingerprint) with an integer primary key to reference. No equivalent
-- canonical identity table exists yet for a live folder, a disk image, or a
-- raw partition (a live folder's only durable identity would be a
-- security-scoped bookmark plus a stable file identifier, which has no
-- schema representation today). Inventing a text key from a path or a device
-- node name for those would be exactly the fragile key this feature must
-- avoid, so they are reserved in the enumeration but blocked by the CHECK
-- constraint below until a normalized source-identity table exists for them
-- (tracked in MVP_PLAN.md's deferred backlog).
CREATE TABLE IF NOT EXISTS source_collection_defaults (
    id             INTEGER PRIMARY KEY,
    source_kind    TEXT NOT NULL CHECK (source_kind IN ('volume', 'folder', 'disk_image', 'raw_partition')),
    volume_id      INTEGER REFERENCES volumes(id) ON DELETE CASCADE,
    collection_id  INTEGER NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    created_at     TEXT NOT NULL,
    updated_at     TEXT NOT NULL,
    -- Only 'volume' is usable in schema version 3; see comment above.
    CHECK (source_kind = 'volume' AND volume_id IS NOT NULL),
    UNIQUE(source_kind, volume_id)
);

CREATE TABLE IF NOT EXISTS snapshots (
    id                      INTEGER PRIMARY KEY,
    volume_id               INTEGER NOT NULL REFERENCES volumes(id) ON DELETE CASCADE,
    session_number          INTEGER NOT NULL,
    scan_root_name          TEXT NOT NULL,
    mount_path_at_capture   TEXT,
    root_relative_path      TEXT NOT NULL DEFAULT '',
    status                  TEXT NOT NULL CHECK (
        status IN ('scanning', 'complete', 'complete_with_warnings', 'interrupted', 'cancelled', 'failed')
    ),
    scanner_version         TEXT NOT NULL,
    schema_version          INTEGER NOT NULL,
    normalization_version   TEXT NOT NULL,
    snapshot_kind           TEXT NOT NULL DEFAULT 'user' CHECK (snapshot_kind IN ('user', 'transient')),
    source_case_sensitivity TEXT NOT NULL DEFAULT 'unknown' CHECK (source_case_sensitivity IN ('sensitive', 'insensitive', 'unknown')),
    -- Filesystem-provider metadata (see docs/FILESYSTEM_PROVIDER_ARCHITECTURE.md).
    -- filesystem_provider/source_access_mode record which provider path and
    -- access mechanism actually produced this capture; provider_version and
    -- filesystem_variant/filesystem_features record what that path observed.
    -- All are nullable-by-default-value rather than NOT NULL because a
    -- 'native' + 'mounted' capture is the common case and needs no raw-path
    -- detail; the CHECK constraints still make the enumerations exhaustive.
    filesystem_provider     TEXT NOT NULL DEFAULT 'native' CHECK (filesystem_provider IN ('native', 'embedded_raw')),
    provider_version        TEXT,
    source_access_mode      TEXT NOT NULL DEFAULT 'mounted' CHECK (source_access_mode IN ('mounted', 'raw_device', 'disk_image')),
    device_identifier       TEXT,
    partition_identifier    TEXT,
    partition_offset        INTEGER,
    partition_length        INTEGER,
    filesystem_variant      TEXT,
    filesystem_features_json TEXT,
    authorization_required  INTEGER NOT NULL DEFAULT 0 CHECK (authorization_required IN (0, 1)),
    -- Snapshot Collections (docs/SNAPSHOT_COLLECTIONS.md). Mutable catalog
    -- metadata layered on top of an otherwise-immutable snapshot: changing
    -- any of these three fields never touches entries, aggregates, capture
    -- timestamps, session_number, or any source-identity field above.
    -- collection_id NULL = "Unsorted" (see collections table comment, §4).
    collection_id           INTEGER REFERENCES collections(id) ON DELETE SET NULL,
    -- Always populated at capture time -- either the user's custom name from
    -- the capture-organization sheet, or generated once as
    -- "<scan_root_name> -- <started_at formatted>" if left blank
    -- (SNAPSHOT_COLLECTIONS.md §5). Never NULL, so every reader (search, list,
    -- sort) uses this column directly with no COALESCE/fallback branching.
    display_name            TEXT NOT NULL,
    user_note               TEXT,
    capture_policy_json     TEXT NOT NULL,
    started_at              TEXT NOT NULL,
    completed_at            TEXT,
    duration_ms             INTEGER,
    total_files             INTEGER NOT NULL DEFAULT 0,
    total_folders           INTEGER NOT NULL DEFAULT 0,
    total_logical_bytes     INTEGER NOT NULL DEFAULT 0,
    total_allocated_bytes   INTEGER NOT NULL DEFAULT 0,
    inaccessible_items      INTEGER NOT NULL DEFAULT 0,
    warning_count           INTEGER NOT NULL DEFAULT 0,
    root_metadata_signature BLOB,
    root_subtree_signature  BLOB,
    created_at              TEXT NOT NULL,
    updated_at              TEXT NOT NULL,
    -- Schema version 5 -- capture-time volume truth (docs/DECISIONS.md ADR-023).
    -- `volumes` is a current-state registry: SnapshotWriter.ensureVolume
    -- refreshes display_name, filesystem_type, total_capacity_bytes and
    -- last_seen_at on every capture, so a later capture of the same volume
    -- changes those values for every earlier snapshot that reads them. These
    -- three columns record what was observed at THIS capture and are never
    -- updated afterwards (see trg_snapshots_capture_facts_immutable). Snapshot
    -- history and browsing read these columns, never `volumes`. NULL means the
    -- fact was not recorded at capture time -- true for every snapshot captured
    -- before version 5 -- and must be displayed as "not recorded", never
    -- back-filled from the registry.
    volume_display_name_at_capture        TEXT,
    volume_identifier_at_capture          TEXT,
    volume_total_capacity_bytes_at_capture INTEGER,
    UNIQUE(volume_id, session_number),
    -- A native-provider capture is always a 'mounted' access; an embedded-raw
    -- capture is always 'raw_device' or 'disk_image', never 'mounted' (if it
    -- were mountable, NativeMountedProvider would have been used per the
    -- deterministic fallback rule in FILESYSTEM_PROVIDER_ARCHITECTURE.md §3).
    CHECK (
        (filesystem_provider = 'native' AND source_access_mode = 'mounted') OR
        (filesystem_provider = 'embedded_raw' AND source_access_mode IN ('raw_device', 'disk_image'))
    ),
    CHECK (partition_offset IS NULL OR partition_offset >= 0),
    CHECK (partition_length IS NULL OR partition_length > 0),
    CHECK (trim(display_name) != '')
);

CREATE INDEX IF NOT EXISTS idx_snapshots_volume_status
ON snapshots(volume_id, status, completed_at DESC);

CREATE INDEX IF NOT EXISTS idx_snapshots_collection
ON snapshots(collection_id, started_at DESC);

CREATE TABLE IF NOT EXISTS entries (
    id                      INTEGER PRIMARY KEY,
    snapshot_id             INTEGER NOT NULL REFERENCES snapshots(id) ON DELETE CASCADE,
    parent_id               INTEGER,
    relative_path           TEXT NOT NULL,
    case_preserving_path    TEXT NOT NULL,
    case_folded_path        TEXT NOT NULL,
    name                    TEXT NOT NULL,
    case_preserving_name    TEXT NOT NULL,
    case_folded_name        TEXT NOT NULL,
    file_extension          TEXT,
    item_type               TEXT NOT NULL CHECK (
        item_type IN ('directory', 'file', 'symlink', 'package', 'other')
    ),
    logical_size_bytes      INTEGER,
    allocated_size_bytes    INTEGER,
    created_at_source       TEXT,
    modified_at_source      TEXT,
    content_type_identifier TEXT,
    resource_identifier     BLOB,
    symlink_target          TEXT,
    is_hidden               INTEGER NOT NULL DEFAULT 0 CHECK (is_hidden IN (0, 1)),
    is_package              INTEGER NOT NULL DEFAULT 0 CHECK (is_package IN (0, 1)),
    is_inaccessible         INTEGER NOT NULL DEFAULT 0 CHECK (is_inaccessible IN (0, 1)),
    direct_file_count       INTEGER NOT NULL DEFAULT 0,
    direct_folder_count     INTEGER NOT NULL DEFAULT 0,
    subtree_file_count      INTEGER NOT NULL DEFAULT 0,
    subtree_folder_count    INTEGER NOT NULL DEFAULT 0,
    subtree_logical_bytes   INTEGER NOT NULL DEFAULT 0,
    subtree_allocated_bytes INTEGER NOT NULL DEFAULT 0,
    metadata_signature      BLOB,
    subtree_signature       BLOB,
    sort_key                TEXT NOT NULL,
    created_at              TEXT NOT NULL,
    FOREIGN KEY (parent_id, snapshot_id) REFERENCES entries(id, snapshot_id) ON DELETE CASCADE,
    CHECK (
        (parent_id IS NULL AND relative_path = '') OR
        (parent_id IS NOT NULL AND relative_path != '')
    ),
    UNIQUE(snapshot_id, relative_path),
    UNIQUE(id, snapshot_id)
);

CREATE TRIGGER IF NOT EXISTS trg_snapshots_complete_root_check
BEFORE UPDATE OF status ON snapshots
WHEN NEW.status IN ('complete', 'complete_with_warnings')
BEGIN
    SELECT CASE
        WHEN (SELECT COUNT(*) FROM entries WHERE snapshot_id = NEW.id AND parent_id IS NULL AND relative_path = '') != 1 THEN
            RAISE(ABORT, 'Snapshot must have exactly one root entry to complete')
        WHEN NEW.normalization_version != 'fsd-normalizer-v1_app-1.0_os-1' THEN
            RAISE(ABORT, 'Snapshot normalization_version is not supported for completion')
    END;
END;

CREATE TRIGGER IF NOT EXISTS trg_snapshots_insert_scanning_only
BEFORE INSERT ON snapshots
WHEN NEW.status != 'scanning'
BEGIN
    SELECT RAISE(ABORT, 'Snapshot must be inserted as scanning first.');
END;

-- Schema version 5. Capture-time facts describe what was observed when this
-- snapshot was taken. Status, totals, warning_count, completed_at, duration_ms
-- and the mutable Collection fields (collection_id, display_name, user_note)
-- stay updatable; everything that answers "what was this a capture OF" does
-- not. BEFORE UPDATE OF only fires when one of these columns appears in the
-- SET clause, and the WHEN clause additionally requires a real value change,
-- so ordinary lifecycle updates are unaffected.
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
END;

CREATE TRIGGER IF NOT EXISTS trg_snapshots_terminal_status_check
BEFORE UPDATE OF status ON snapshots
WHEN OLD.status IN ('complete', 'complete_with_warnings', 'cancelled', 'failed')
BEGIN
    SELECT RAISE(ABORT, 'Cannot transition out of a terminal status');
END;

-- Completed metadata is immutable. Interrupted/cancelled/failed captures keep
-- their evidence for recovery diagnostics, but the writer still closes them
-- before accepting another capture operation.
CREATE TRIGGER IF NOT EXISTS trg_completed_entries_insert_guard
BEFORE INSERT ON entries
WHEN (SELECT status FROM snapshots WHERE id = NEW.snapshot_id) IN ('complete', 'complete_with_warnings')
BEGIN
    SELECT RAISE(ABORT, 'Cannot insert entries into a completed snapshot');
END;

CREATE TRIGGER IF NOT EXISTS trg_completed_entries_update_guard
BEFORE UPDATE ON entries
WHEN (SELECT status FROM snapshots WHERE id = OLD.snapshot_id) IN ('complete', 'complete_with_warnings')
BEGIN
    SELECT RAISE(ABORT, 'Cannot update entries in a completed snapshot');
END;

CREATE TRIGGER IF NOT EXISTS trg_completed_entries_delete_guard
BEFORE DELETE ON entries
WHEN (SELECT status FROM snapshots WHERE id = OLD.snapshot_id) IN ('complete', 'complete_with_warnings')
BEGIN
    SELECT RAISE(ABORT, 'Cannot delete entries from a completed snapshot');
END;

CREATE INDEX IF NOT EXISTS idx_entries_snapshot_parent_sort
ON entries(snapshot_id, parent_id, sort_key);

CREATE INDEX IF NOT EXISTS idx_entries_snapshot_case_preserving_path
ON entries(snapshot_id, case_preserving_path);

CREATE INDEX IF NOT EXISTS idx_entries_snapshot_case_folded_path
ON entries(snapshot_id, case_folded_path);

CREATE INDEX IF NOT EXISTS idx_entries_snapshot_case_preserving_name
ON entries(snapshot_id, case_preserving_name);

CREATE INDEX IF NOT EXISTS idx_entries_snapshot_case_folded_name
ON entries(snapshot_id, case_folded_name);

CREATE INDEX IF NOT EXISTS idx_entries_snapshot_type
ON entries(snapshot_id, item_type);

-- Schema version 5. Offline metadata search filters by extension often enough
-- that the (snapshot_id, item_type) index alone forces a scan of one whole
-- snapshot; this keeps an extension filter bounded.
CREATE INDEX IF NOT EXISTS idx_entries_snapshot_extension
ON entries(snapshot_id, file_extension);

CREATE TABLE IF NOT EXISTS scan_issues (
    id                  INTEGER PRIMARY KEY,
    snapshot_id         INTEGER NOT NULL REFERENCES snapshots(id) ON DELETE CASCADE,
    entry_id            INTEGER REFERENCES entries(id) ON DELETE SET NULL,
    relative_path       TEXT NOT NULL,
    error_domain        TEXT,
    error_code          INTEGER,
    severity            TEXT NOT NULL CHECK (severity IN ('info', 'warning', 'error')),
    -- Distinguishes an issue raised by the generic scanner/enumeration layer
    -- from one raised by an embedded-raw filesystem reader (libfsext, or a
    -- future adapter). Deliberately not a separate reader_warning_count /
    -- reader_error_count pair of columns on `snapshots`: those would duplicate
    -- what is already countable here via `GROUP BY source, severity`, and a
    -- denormalized counter would need its own consistency maintenance for no
    -- added correctness or diagnostic value.
    source              TEXT NOT NULL DEFAULT 'scanner' CHECK (source IN ('scanner', 'reader')),
    message             TEXT NOT NULL,
    was_skipped         INTEGER NOT NULL DEFAULT 0 CHECK (was_skipped IN (0, 1)),
    created_at          TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_scan_issues_snapshot
ON scan_issues(snapshot_id, severity);

CREATE INDEX IF NOT EXISTS idx_scan_issues_snapshot_source
ON scan_issues(snapshot_id, source, severity);

CREATE TRIGGER IF NOT EXISTS trg_completed_scan_issues_insert_guard
BEFORE INSERT ON scan_issues
WHEN (SELECT status FROM snapshots WHERE id = NEW.snapshot_id) IN ('complete', 'complete_with_warnings')
BEGIN
    SELECT RAISE(ABORT, 'Cannot add scan issues to a completed snapshot');
END;

CREATE TABLE IF NOT EXISTS comparison_profiles (
    id                          INTEGER PRIMARY KEY,
    name                        TEXT NOT NULL UNIQUE,
    -- Schema version 6 (ADR-027). Monotonic revision of this profile
    -- definition. The engine freezes the version it compared with into
    -- comparisons.profile_version, so editing a profile later can never
    -- silently reinterpret an earlier comparison's conclusion.
    version                     INTEGER NOT NULL DEFAULT 1,
    compare_item_type           INTEGER NOT NULL DEFAULT 1,
    compare_logical_size        INTEGER NOT NULL DEFAULT 1,
    compare_allocated_size      INTEGER NOT NULL DEFAULT 0,
    compare_modified_at         INTEGER NOT NULL DEFAULT 0,
    compare_created_at          INTEGER NOT NULL DEFAULT 0,
    timestamp_tolerance_seconds INTEGER NOT NULL DEFAULT 0,
    include_hidden_items        INTEGER NOT NULL DEFAULT 0,
    ignore_rules_json           TEXT NOT NULL,
    is_builtin                  INTEGER NOT NULL DEFAULT 0,
    created_at                  TEXT NOT NULL,
    updated_at                  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS comparisons (
    id                  INTEGER PRIMARY KEY,
    left_snapshot_id    INTEGER REFERENCES snapshots(id) ON DELETE RESTRICT,
    right_snapshot_id   INTEGER REFERENCES snapshots(id) ON DELETE RESTRICT,
    profile_id          INTEGER NOT NULL REFERENCES comparison_profiles(id),
    -- Schema version 6 (ADR-027). The comparison_profiles.version revision
    -- that produced this comparison, frozen at creation. Together with the
    -- persisted result rows it means a later profile edit cannot silently
    -- change what this comparison concluded.
    profile_version     INTEGER NOT NULL DEFAULT 1,
    status              TEXT NOT NULL CHECK (status IN ('running', 'complete', 'cancelled', 'failed')),
    started_at          TEXT NOT NULL,
    completed_at        TEXT,
    matched_count       INTEGER NOT NULL DEFAULT 0,
    added_count         INTEGER NOT NULL DEFAULT 0,
    removed_count       INTEGER NOT NULL DEFAULT 0,
    changed_count       INTEGER NOT NULL DEFAULT 0,
    uncertain_count     INTEGER NOT NULL DEFAULT 0,
    created_at          TEXT NOT NULL
);

CREATE TRIGGER IF NOT EXISTS trg_comparisons_version_check
BEFORE INSERT ON comparisons
WHEN NEW.left_snapshot_id IS NOT NULL AND NEW.right_snapshot_id IS NOT NULL
BEGIN
    SELECT CASE
        WHEN (SELECT normalization_version FROM snapshots WHERE id = NEW.left_snapshot_id) !=
             (SELECT normalization_version FROM snapshots WHERE id = NEW.right_snapshot_id) THEN
            RAISE(ABORT, 'Mismatched normalization versions block comparison')
    END;
END;

CREATE TRIGGER IF NOT EXISTS trg_comparisons_source_immutable
BEFORE UPDATE OF left_snapshot_id, right_snapshot_id ON comparisons
WHEN OLD.left_snapshot_id IS NOT NEW.left_snapshot_id OR OLD.right_snapshot_id IS NOT NEW.right_snapshot_id
BEGIN
    SELECT RAISE(ABORT, 'Comparison source snapshot IDs are immutable');
END;

CREATE TRIGGER IF NOT EXISTS trg_comparisons_source_eligibility_insert
BEFORE INSERT ON comparisons
WHEN NEW.left_snapshot_id IS NOT NULL AND NEW.right_snapshot_id IS NOT NULL
BEGIN
    SELECT CASE
        WHEN (SELECT status FROM snapshots WHERE id = NEW.left_snapshot_id) NOT IN ('complete', 'complete_with_warnings') OR
             (SELECT status FROM snapshots WHERE id = NEW.right_snapshot_id) NOT IN ('complete', 'complete_with_warnings') THEN
            RAISE(ABORT, 'Comparison sources must be complete snapshots')
    END;
END;


CREATE TABLE IF NOT EXISTS comparison_collision_groups (
    id                  INTEGER PRIMARY KEY,
    comparison_id       INTEGER NOT NULL REFERENCES comparisons(id) ON DELETE CASCADE,
    result_path         TEXT NOT NULL,
    created_at          TEXT NOT NULL,
    UNIQUE(comparison_id, result_path)
);

CREATE TABLE IF NOT EXISTS comparison_collision_members (
    id                  INTEGER PRIMARY KEY,
    group_id            INTEGER NOT NULL REFERENCES comparison_collision_groups(id) ON DELETE CASCADE,
    side                TEXT NOT NULL CHECK (side IN ('left', 'right')),
    entry_id            INTEGER NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
    created_at          TEXT NOT NULL,
    UNIQUE(group_id, side, entry_id)
);

CREATE TRIGGER IF NOT EXISTS trg_comparison_collision_member_side_left
BEFORE INSERT ON comparison_collision_members
WHEN NEW.side = 'left'
BEGIN
    SELECT CASE
        WHEN (SELECT snapshot_id FROM entries WHERE id = NEW.entry_id) != 
             (SELECT left_snapshot_id FROM comparisons WHERE id = (SELECT comparison_id FROM comparison_collision_groups WHERE id = NEW.group_id)) THEN
            RAISE(ABORT, 'Collision member entry must belong to the left snapshot of the comparison')
    END;
END;

CREATE TRIGGER IF NOT EXISTS trg_comparison_collision_member_side_right
BEFORE INSERT ON comparison_collision_members
WHEN NEW.side = 'right'
BEGIN
    SELECT CASE
        WHEN (SELECT snapshot_id FROM entries WHERE id = NEW.entry_id) != 
             (SELECT right_snapshot_id FROM comparisons WHERE id = (SELECT comparison_id FROM comparison_collision_groups WHERE id = NEW.group_id)) THEN
            RAISE(ABORT, 'Collision member entry must belong to the right snapshot of the comparison')
    END;
END;

CREATE TABLE IF NOT EXISTS comparison_results (

    id                  INTEGER PRIMARY KEY,
    comparison_id       INTEGER NOT NULL REFERENCES comparisons(id) ON DELETE CASCADE,
    parent_result_id    INTEGER REFERENCES comparison_results(id) ON DELETE CASCADE,
    result_path         TEXT NOT NULL,
    display_name        TEXT NOT NULL,
    result_type         TEXT NOT NULL CHECK (
        result_type IN ('matched', 'added', 'removed', 'changed', 'ignored', 'uncertain')
    ),
    left_entry_id       INTEGER REFERENCES entries(id) ON DELETE SET NULL,
    right_entry_id      INTEGER REFERENCES entries(id) ON DELETE SET NULL,
    difference_flags    INTEGER NOT NULL DEFAULT 0,
    created_at          TEXT NOT NULL,
    UNIQUE(comparison_id, result_path, left_entry_id, right_entry_id)
);

CREATE INDEX IF NOT EXISTS idx_comparison_results_parent
ON comparison_results(comparison_id, parent_result_id, result_type, display_name);

CREATE INDEX IF NOT EXISTS idx_comparison_results_parent_result_id
ON comparison_results(parent_result_id);

CREATE INDEX IF NOT EXISTS idx_comparison_results_uncertain_group
ON comparison_results(comparison_id, result_path)
WHERE result_type = 'uncertain';

CREATE TRIGGER IF NOT EXISTS trg_comparison_results_entry_left
BEFORE INSERT ON comparison_results
WHEN NEW.left_entry_id IS NOT NULL
BEGIN
    SELECT CASE
        WHEN (SELECT snapshot_id FROM entries WHERE id = NEW.left_entry_id) !=
             (SELECT left_snapshot_id FROM comparisons WHERE id = NEW.comparison_id) THEN
            RAISE(ABORT, 'Result left_entry_id must belong to the left snapshot of the comparison')
    END;
END;

CREATE TRIGGER IF NOT EXISTS trg_comparison_results_entry_right
BEFORE INSERT ON comparison_results
WHEN NEW.right_entry_id IS NOT NULL
BEGIN
    SELECT CASE
        WHEN (SELECT snapshot_id FROM entries WHERE id = NEW.right_entry_id) !=
             (SELECT right_snapshot_id FROM comparisons WHERE id = NEW.comparison_id) THEN
            RAISE(ABORT, 'Result right_entry_id must belong to the right snapshot of the comparison')
    END;
END;

CREATE TRIGGER IF NOT EXISTS trg_comparison_results_uncertain_empty
BEFORE INSERT ON comparison_results
WHEN NEW.result_type = 'uncertain' AND NEW.left_entry_id IS NULL AND NEW.right_entry_id IS NULL
BEGIN
    SELECT CASE
        WHEN EXISTS (
            SELECT 1 FROM comparison_results 
            WHERE comparison_id = NEW.comparison_id 
              AND result_path = NEW.result_path 
              AND result_type = 'uncertain' 
              AND left_entry_id IS NULL 
              AND right_entry_id IS NULL
        ) THEN
            RAISE(ABORT, 'Duplicate empty uncertain rows are not allowed')
    END;
END;

CREATE TRIGGER IF NOT EXISTS trg_comparison_results_no_collision_pairs
BEFORE INSERT ON comparison_results
WHEN NEW.result_type IN ('matched', 'changed', 'added', 'removed')
BEGIN
    SELECT CASE
        WHEN EXISTS (
            SELECT 1 FROM comparison_collision_members
            WHERE group_id IN (SELECT id FROM comparison_collision_groups WHERE comparison_id = NEW.comparison_id)
              AND ((side = 'left' AND entry_id = NEW.left_entry_id) OR
                   (side = 'right' AND entry_id = NEW.right_entry_id))
        ) THEN
            RAISE(ABORT, 'Collision members cannot be paired as matched/changed/added/removed')
        WHEN EXISTS (
            SELECT 1 FROM comparison_collision_groups
            WHERE comparison_id = NEW.comparison_id AND result_path = NEW.result_path
        ) THEN
            RAISE(ABORT, 'Ordinary results cannot use a result_path already assigned to a collision group')
    END;
END;

CREATE TRIGGER IF NOT EXISTS trg_comparison_results_no_collision_pairs_update
BEFORE UPDATE OF result_type, left_entry_id, right_entry_id, result_path ON comparison_results
WHEN NEW.result_type IN ('matched', 'changed', 'added', 'removed')
BEGIN
    SELECT CASE
        WHEN EXISTS (
            SELECT 1 FROM comparison_collision_members
            WHERE group_id IN (SELECT id FROM comparison_collision_groups WHERE comparison_id = NEW.comparison_id)
              AND ((side = 'left' AND entry_id = NEW.left_entry_id) OR
                   (side = 'right' AND entry_id = NEW.right_entry_id))
        ) THEN
            RAISE(ABORT, 'Collision members cannot be paired as matched/changed/added/removed')
        WHEN EXISTS (
            SELECT 1 FROM comparison_collision_groups
            WHERE comparison_id = NEW.comparison_id AND result_path = NEW.result_path
        ) THEN
            RAISE(ABORT, 'Ordinary results cannot use a result_path already assigned to a collision group')
    END;
END;


-- Schema version 6. Comparison result integrity (docs/DECISIONS.md ADR-027).
-- A terminal comparison's status and summary counts never change again, and
-- its detailed result rows can be inserted or updated only while it is
-- running. Deleting the whole comparison remains the explicit disposal API
-- (workspace close / user deletion); deleting result rows individually is not
-- a supported operation.
CREATE TRIGGER IF NOT EXISTS trg_comparisons_terminal_immutable
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
END;

CREATE TRIGGER IF NOT EXISTS trg_comparison_results_insert_guard
BEFORE INSERT ON comparison_results
WHEN (SELECT status FROM comparisons WHERE id = NEW.comparison_id) IN ('complete', 'cancelled', 'failed')
BEGIN
    SELECT RAISE(ABORT, 'Cannot add results to a terminal comparison');
END;

CREATE TRIGGER IF NOT EXISTS trg_comparison_results_update_guard
BEFORE UPDATE ON comparison_results
WHEN (SELECT status FROM comparisons WHERE id = OLD.comparison_id) IN ('complete', 'cancelled', 'failed')
BEGIN
    SELECT RAISE(ABORT, 'Comparison results are immutable after a terminal state');
END;

-- Bounded differences-only queries: the (comparison_id, parent_result_id,
-- result_type) index cannot serve a result_type filter because
-- parent_result_id is skipped.
CREATE INDEX IF NOT EXISTS idx_comparison_results_type
ON comparison_results(comparison_id, result_type);

-- Schema version 7. Terminal comparison evidence immutability
-- (docs/DECISIONS.md ADR-028). A terminal comparison's conclusion is its
-- retained evidence: collision groups and members can be inserted only while
-- the comparison is running, and can never be updated or deleted afterwards.
-- The DELETE guards deliberately allow rows to disappear as part of
-- whole-comparison disposal: when the cascade fires, the comparison row is
-- already gone, so the terminal-state probe below finds no row and disposal —
-- the explicit API (ADR-012, ADR-027) — is unaffected. Direct DELETE of
-- evidence rows on a terminal comparison still aborts, because the comparison
-- row is still there.
CREATE TRIGGER IF NOT EXISTS trg_comparison_results_delete_guard
BEFORE DELETE ON comparison_results
WHEN (SELECT status FROM comparisons WHERE id = OLD.comparison_id) IN ('complete', 'cancelled', 'failed')
BEGIN
    SELECT RAISE(ABORT, 'Comparison results are immutable after a terminal state');
END;

CREATE TRIGGER IF NOT EXISTS trg_comparison_collision_groups_insert_guard
BEFORE INSERT ON comparison_collision_groups
WHEN (SELECT status FROM comparisons WHERE id = NEW.comparison_id) IN ('complete', 'cancelled', 'failed')
BEGIN
    SELECT RAISE(ABORT, 'Cannot add collision groups to a terminal comparison');
END;

CREATE TRIGGER IF NOT EXISTS trg_comparison_collision_groups_update_guard
BEFORE UPDATE ON comparison_collision_groups
WHEN (SELECT status FROM comparisons WHERE id = OLD.comparison_id) IN ('complete', 'cancelled', 'failed')
BEGIN
    SELECT RAISE(ABORT, 'Collision groups are immutable after a terminal state');
END;

CREATE TRIGGER IF NOT EXISTS trg_comparison_collision_groups_delete_guard
BEFORE DELETE ON comparison_collision_groups
WHEN (SELECT status FROM comparisons WHERE id = OLD.comparison_id) IN ('complete', 'cancelled', 'failed')
BEGIN
    SELECT RAISE(ABORT, 'Collision groups are immutable after a terminal state');
END;

CREATE TRIGGER IF NOT EXISTS trg_comparison_collision_members_insert_guard
BEFORE INSERT ON comparison_collision_members
WHEN (SELECT c.status FROM comparisons c
      JOIN comparison_collision_groups g ON g.comparison_id = c.id
      WHERE g.id = NEW.group_id) IN ('complete', 'cancelled', 'failed')
BEGIN
    SELECT RAISE(ABORT, 'Cannot add collision members to a terminal comparison');
END;

CREATE TRIGGER IF NOT EXISTS trg_comparison_collision_members_update_guard
BEFORE UPDATE ON comparison_collision_members
WHEN (SELECT c.status FROM comparisons c
      JOIN comparison_collision_groups g ON g.comparison_id = c.id
      WHERE g.id = OLD.group_id) IN ('complete', 'cancelled', 'failed')
BEGIN
    SELECT RAISE(ABORT, 'Collision members are immutable after a terminal state');
END;

CREATE TRIGGER IF NOT EXISTS trg_comparison_collision_members_delete_guard
BEFORE DELETE ON comparison_collision_members
WHEN (SELECT c.status FROM comparisons c
      JOIN comparison_collision_groups g ON g.comparison_id = c.id
      WHERE g.id = OLD.group_id) IN ('complete', 'cancelled', 'failed')
BEGIN
    SELECT RAISE(ABORT, 'Collision members are immutable after a terminal state');
END;

INSERT OR IGNORE INTO comparison_profiles (
    id, name, compare_item_type, compare_logical_size, compare_allocated_size,
    compare_modified_at, compare_created_at, timestamp_tolerance_seconds,
    include_hidden_items, ignore_rules_json, is_builtin, created_at, updated_at
) VALUES
(
    1,
    'Fast Metadata',
    1, 1, 0, 0, 0, 0, 0,
    '[".DS_Store","._*",".Spotlight-V100/**",".Trashes/**",".fseventsd/**","Temporary Items/**"]',
    1,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
),
(
    2,
    'Structure Only',
    1, 0, 0, 0, 0, 0, 0,
    '[".DS_Store","._*",".Spotlight-V100/**",".Trashes/**",".fseventsd/**","Temporary Items/**"]',
    1,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
),
(
    3,
    'Strict Metadata',
    1, 1, 0, 1, 0, 2, 1,
    '[]',
    1,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

INSERT OR IGNORE INTO schema_migrations(version, applied_at)
VALUES (9, CURRENT_TIMESTAMP);

CREATE TRIGGER IF NOT EXISTS trg_collections_last_used_at_insert
AFTER INSERT ON snapshots
WHEN NEW.collection_id IS NOT NULL
BEGIN
    UPDATE collections
    SET last_used_at = CURRENT_TIMESTAMP
    WHERE id = NEW.collection_id;
END;

CREATE TRIGGER IF NOT EXISTS trg_collections_last_used_at_update
AFTER UPDATE OF collection_id ON snapshots
WHEN NEW.collection_id IS NOT NULL AND (OLD.collection_id IS NULL OR OLD.collection_id != NEW.collection_id)
BEGIN
    UPDATE collections
    SET last_used_at = CURRENT_TIMESTAMP
    WHERE id = NEW.collection_id;
END;

-- Phase 1.5 nullable-enrichment preparation -- Magika content classification
-- schema seam. See
-- docs/ARCHITECTURE.md §9 (FileClassificationService / DisabledFileClassificationService),
-- docs/DECISIONS.md ADR-021, docs/MVP_PLAN.md Phase 1.5. entry_classifications
-- is a separate, optional, append-only enrichment table so that entries
-- remains pure immutable snapshot metadata: the MVP writes zero rows here,
-- MVP browsing and diff never join against this table, and the table may
-- remain empty for the entire MVP lifecycle with no behavioral difference.
-- Absence of a row for a given entry means classification was never
-- requested for it -- not "unknown" or "pending". A disabled classification
-- service (the only implementation that exists during the MVP) creates no
-- row at all; it never writes a placeholder "disabled" row itself. Multiple
-- rows may exist per entry_id, one per classification_run_id, because a
-- later classification run must never overwrite or reinterpret an earlier
-- run's stored result -- classification history is append-only.
CREATE TABLE IF NOT EXISTS entry_classifications (
    id                  INTEGER PRIMARY KEY,
    entry_id            INTEGER NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
    -- Identifies one classification attempt. Free-form (e.g. a UUID or a
    -- detector+model+timestamp stamp minted by the future classification
    -- service) -- deliberately not a foreign key into a separate "runs"
    -- table, since no job/run tracking system exists or is being built here.
    classification_run_id  TEXT NOT NULL,
    detected_type       TEXT,
    mime_type           TEXT,
    confidence          REAL,
    -- Small, documented, future-compatible enumeration mirroring the
    -- ClassificationResult cases sketched in docs/ARCHITECTURE.md §9.
    detection_status    TEXT CHECK (
        detection_status IS NULL OR
        detection_status IN ('not_requested', 'disabled', 'classified', 'failed')
    ),
    detector_version    TEXT,
    model_version       TEXT,
    classified_at       TEXT,
    created_at          TEXT NOT NULL,
    provider_identifier TEXT,
    CHECK (confidence IS NULL OR (confidence >= 0.0 AND confidence <= 1.0)),
    UNIQUE(entry_id, classification_run_id)
);
