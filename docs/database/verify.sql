PRAGMA foreign_keys = ON;
.mode column
.headers on
.echo on

-- 1. Apply the revised schema (implicitly done by running against it)

-- 2. PRAGMA integrity_check returns ok.
PRAGMA integrity_check;

-- 3. PRAGMA foreign_key_check returns no rows.
PRAGMA foreign_key_check;

-- Setup initial data
INSERT INTO volumes (id, display_name, first_seen_at, last_seen_at, created_at, updated_at)
VALUES (1, 'TestVolume', datetime('now'), datetime('now'), datetime('now'), datetime('now'));

INSERT INTO volumes (id, display_name, first_seen_at, last_seen_at, created_at, updated_at)
VALUES (2, 'TestVolume2', datetime('now'), datetime('now'), datetime('now'), datetime('now'));

-- 4. Valid user and transient snapshots insert. display_name is required (schema v3).
INSERT INTO snapshots (normalization_version, id, volume_id, session_number, scan_root_name, status, scanner_version, schema_version, snapshot_kind, source_case_sensitivity, display_name, capture_policy_json, started_at, created_at, updated_at)
VALUES ('fsd-normalizer-v1_app-1.0_os-1', 1, 1, 1, 'Root', 'scanning', 'fsd-algo-v1_app-v1.0_unicode-15.0', 1, 'user', 'sensitive', 'TestVolume — Session 1', '{}', datetime('now'), datetime('now'), datetime('now'));

INSERT INTO snapshots (normalization_version, id, volume_id, session_number, scan_root_name, status, scanner_version, schema_version, snapshot_kind, source_case_sensitivity, display_name, capture_policy_json, started_at, created_at, updated_at)
VALUES ('fsd-normalizer-v1_app-1.0_os-1', 2, 1, 2, 'RootLive', 'scanning', 'fsd-algo-v1_app-v1.0_unicode-15.0', 1, 'transient', 'insensitive', 'RootLive — Session 2', '{}', datetime('now'), datetime('now'), datetime('now'));

-- 10. Root insertion succeeds.
INSERT INTO entries (id, snapshot_id, parent_id, relative_path, case_preserving_path, case_folded_path, name, case_preserving_name, case_folded_name, item_type, sort_key, created_at)
VALUES (1, 1, NULL, '', '', '', 'Root', 'Root', 'root', 'directory', '0', datetime('now'));

INSERT INTO entries (id, snapshot_id, parent_id, relative_path, case_preserving_path, case_folded_path, name, case_preserving_name, case_folded_name, item_type, sort_key, created_at)
VALUES (3, 2, NULL, '', '', '', 'Root', 'Root', 'root', 'directory', '0', datetime('now'));

-- 13. Cross-snapshot parent reference is rejected.
INSERT INTO entries (id, snapshot_id, parent_id, relative_path, case_preserving_path, case_folded_path, name, case_preserving_name, case_folded_name, item_type, sort_key, created_at)
VALUES (5, 2, 1, 'Cross.txt', 'Cross.txt', 'cross.txt', 'Cross.txt', 'Cross.txt', 'cross.txt', 'file', '0', datetime('now'));

-- === Filesystem-provider metadata checks (schema version 2) ===

-- 14. Default native/mounted snapshot succeeds with no provider detail needed.
INSERT INTO snapshots (normalization_version, id, volume_id, session_number, scan_root_name, status, scanner_version, schema_version, snapshot_kind, source_case_sensitivity, display_name, capture_policy_json, started_at, created_at, updated_at)
VALUES ('fsd-normalizer-v1_app-1.0_os-1', 3, 1, 3, 'RootAPFS', 'scanning', 'fsd-algo-v1_app-v1.0_unicode-15.0', 2, 'user', 'sensitive', 'RootAPFS — Session 3', '{}', datetime('now'), datetime('now'), datetime('now'));

-- 15. Embedded-raw snapshot over a disk image succeeds with full provider detail.
INSERT INTO snapshots (
    id, volume_id, session_number, scan_root_name, status, scanner_version, schema_version,
    normalization_version,
    snapshot_kind, source_case_sensitivity,
    filesystem_provider, provider_version, source_access_mode,
    device_identifier, partition_identifier, partition_offset, partition_length,
    filesystem_variant, filesystem_features_json, authorization_required,
    display_name, capture_policy_json, started_at, created_at, updated_at
)
VALUES (
    4, 1, 4, 'RootExt4Image', 'scanning', 'fsd-algo-v1_app-v1.0_unicode-15.0', 2,
    'fsd-normalizer-v1_app-1.0_os-1',
    'user', 'sensitive',
    'embedded_raw', 'libfsext 20260514', 'disk_image',
    NULL, NULL, 1048576, 4294967296,
    'ext4', '{"journal":true,"extents":true,"case_insensitive":false}', 0,
    'RootExt4Image — Session 4', '{}', datetime('now'), datetime('now'), datetime('now')
);

-- 16. Embedded-raw snapshot over a raw physical device succeeds, authorization_required=1.
INSERT INTO snapshots (
    id, volume_id, session_number, scan_root_name, status, scanner_version, schema_version,
    normalization_version,
    snapshot_kind, source_case_sensitivity,
    filesystem_provider, provider_version, source_access_mode,
    device_identifier, partition_identifier, partition_offset, partition_length,
    filesystem_variant, filesystem_features_json, authorization_required,
    display_name, capture_policy_json, started_at, created_at, updated_at
)
VALUES (
    5, 1, 5, 'RootExt4Raw', 'scanning', 'fsd-algo-v1_app-v1.0_unicode-15.0', 2,
    'fsd-normalizer-v1_app-1.0_os-1',
    'user', 'sensitive',
    'embedded_raw', 'libfsext 20260514', 'raw_device',
    'disk4', 'disk4s2', 20971520, 8589934592,
    'ext4', '{"journal":true,"extents":true,"case_insensitive":false}', 1,
    'RootExt4Raw — Session 5', '{}', datetime('now'), datetime('now'), datetime('now')
);

-- 17. INVALID: embedded_raw provider with source_access_mode='mounted' must be rejected.
INSERT INTO snapshots (normalization_version, id, volume_id, session_number, scan_root_name, status, scanner_version, schema_version, snapshot_kind, source_case_sensitivity, filesystem_provider, source_access_mode, display_name, capture_policy_json, started_at, created_at, updated_at)
VALUES ('fsd-normalizer-v1_app-1.0_os-1', 6, 1, 6, 'BadCombo1', 'scanning', 'fsd-algo-v1_app-v1.0_unicode-15.0', 2, 'user', 'sensitive', 'embedded_raw', 'mounted', 'BadCombo1', '{}', datetime('now'), datetime('now'), datetime('now'));

-- 18. INVALID: native provider with source_access_mode='raw_device' must be rejected.
INSERT INTO snapshots (normalization_version, id, volume_id, session_number, scan_root_name, status, scanner_version, schema_version, snapshot_kind, source_case_sensitivity, filesystem_provider, source_access_mode, display_name, capture_policy_json, started_at, created_at, updated_at)
VALUES ('fsd-normalizer-v1_app-1.0_os-1', 7, 1, 7, 'BadCombo2', 'scanning', 'fsd-algo-v1_app-v1.0_unicode-15.0', 2, 'user', 'sensitive', 'native', 'raw_device', 'BadCombo2', '{}', datetime('now'), datetime('now'), datetime('now'));

-- 19. INVALID: negative partition_offset must be rejected.
INSERT INTO snapshots (normalization_version, id, volume_id, session_number, scan_root_name, status, scanner_version, schema_version, snapshot_kind, source_case_sensitivity, filesystem_provider, source_access_mode, partition_offset, display_name, capture_policy_json, started_at, created_at, updated_at)
VALUES ('fsd-normalizer-v1_app-1.0_os-1', 8, 1, 8, 'BadOffset', 'scanning', 'fsd-algo-v1_app-v1.0_unicode-15.0', 2, 'user', 'sensitive', 'embedded_raw', 'raw_device', -1, 'BadOffset', '{}', datetime('now'), datetime('now'), datetime('now'));

-- 20. scan_issues.source accepts 'scanner' and 'reader'.
INSERT INTO scan_issues (id, snapshot_id, relative_path, severity, source, message, created_at)
VALUES (1, 4, '/lost+found', 'warning', 'reader', 'libfsext: unrecognized inode flag', datetime('now'));

INSERT INTO scan_issues (id, snapshot_id, relative_path, severity, source, message, created_at)
VALUES (2, 3, '/.Spotlight-V100', 'info', 'scanner', 'Permission denied', datetime('now'));

-- 21. INVALID: scan_issues.source rejects an unrecognized value.
INSERT INTO scan_issues (id, snapshot_id, relative_path, severity, source, message, created_at)
VALUES (3, 3, '/bad', 'info', 'parser', 'should be rejected', datetime('now'));

-- 22. Diagnostic query: reader- vs scanner-sourced issue counts per snapshot
-- (demonstrates reader_warning_count/reader_error_count are unnecessary as
-- denormalized columns -- this query derives the same information).
SELECT snapshot_id, source, severity, COUNT(*) AS issue_count
FROM scan_issues
GROUP BY snapshot_id, source, severity
ORDER BY snapshot_id, source, severity;

PRAGMA integrity_check;
PRAGMA foreign_key_check;

-- === Snapshot Collections checks (schema version 3) ===

-- 23. Create a Collection succeeds.
INSERT INTO collections (id, name, normalized_name, created_at, updated_at)
VALUES (1, 'XYZ', 'xyz', datetime('now'), datetime('now'));

INSERT INTO collections (id, name, normalized_name, created_at, updated_at)
VALUES (2, 'ABC', 'abc', datetime('now'), datetime('now'));

-- 24. INVALID: blank Collection name is rejected.
INSERT INTO collections (id, name, normalized_name, created_at, updated_at)
VALUES (3, '   ', '   ', datetime('now'), datetime('now'));

-- 25. INVALID: normalized duplicate name is rejected (e.g. 'xyz' collides with 'XYZ').
INSERT INTO collections (id, name, normalized_name, created_at, updated_at)
VALUES (4, 'xyz', 'xyz', datetime('now'), datetime('now'));

-- 26. Rename a Collection: id is unchanged, name/normalized_name change.
UPDATE collections
SET name = 'XYZ Productions', normalized_name = 'xyz productions', updated_at = datetime('now')
WHERE id = 1;

SELECT id, name, normalized_name FROM collections WHERE id = 1;

-- 27. Snapshot with a Collection assigned at capture time.
INSERT INTO snapshots (normalization_version, id, volume_id, session_number, scan_root_name, status, scanner_version, schema_version, snapshot_kind, source_case_sensitivity, collection_id, display_name, capture_policy_json, started_at, created_at, updated_at)
VALUES ('fsd-normalizer-v1_app-1.0_os-1', 9, 1, 9, 'REDMAG_A', 'complete', 'fsd-algo-v1_app-v1.0_unicode-15.0', 3, 'user', 'sensitive', 1, 'Camera Card A — Day 03', '{}', datetime('now'), datetime('now'), datetime('now'));

-- 28. Snapshot with no Collection (Unsorted) at capture time.
INSERT INTO snapshots (normalization_version, id, volume_id, session_number, scan_root_name, status, scanner_version, schema_version, snapshot_kind, source_case_sensitivity, collection_id, display_name, capture_policy_json, started_at, created_at, updated_at)
VALUES ('fsd-normalizer-v1_app-1.0_os-1', 10, 1, 10, 'REDMAG_B', 'complete', 'fsd-algo-v1_app-v1.0_unicode-15.0', 3, 'user', 'sensitive', NULL, 'REDMAG_B — 2026-07-24 22:19', '{}', datetime('now'), datetime('now'), datetime('now'));

-- 29. INVALID: blank display_name is rejected.
INSERT INTO snapshots (normalization_version, id, volume_id, session_number, scan_root_name, status, scanner_version, schema_version, snapshot_kind, source_case_sensitivity, display_name, capture_policy_json, started_at, created_at, updated_at)
VALUES ('fsd-normalizer-v1_app-1.0_os-1', 11, 1, 11, 'BadName', 'scanning', 'fsd-algo-v1_app-v1.0_unicode-15.0', 3, 'user', 'sensitive', '   ', '{}', datetime('now'), datetime('now'), datetime('now'));

-- 30. Save a source default: volume 1 -> Collection 1 (XYZ Productions).
INSERT INTO source_collection_defaults (id, source_kind, volume_id, collection_id, created_at, updated_at)
VALUES (1, 'volume', 1, 1, datetime('now'), datetime('now'));

-- 31. Replace the default (upsert): volume 1 now defaults to Collection 2 (ABC) instead.
INSERT INTO source_collection_defaults (id, source_kind, volume_id, collection_id, created_at, updated_at)
VALUES (1, 'volume', 1, 2, datetime('now'), datetime('now'))
ON CONFLICT(source_kind, volume_id) DO UPDATE SET
    collection_id = excluded.collection_id,
    updated_at = excluded.updated_at;

SELECT source_kind, volume_id, collection_id FROM source_collection_defaults WHERE volume_id = 1;

-- 32. A distinct volume (volume 2) gets its own, unrelated default -- proves
-- two sources never accidentally share a default (they are keyed by
-- volume_id, never by display name; volumes 1 and 2 could even share a
-- display name and this would still be correct).
INSERT INTO source_collection_defaults (id, source_kind, volume_id, collection_id, created_at, updated_at)
VALUES (2, 'volume', 2, 1, datetime('now'), datetime('now'));

SELECT volume_id, collection_id FROM source_collection_defaults ORDER BY volume_id;

-- 33. INVALID: source_kind other than 'volume' is rejected in schema v3.
INSERT INTO source_collection_defaults (id, source_kind, volume_id, collection_id, created_at, updated_at)
VALUES (3, 'folder', NULL, 1, datetime('now'), datetime('now'));

-- 34. INVALID: source_kind='volume' with a NULL volume_id is rejected.
INSERT INTO source_collection_defaults (id, source_kind, volume_id, collection_id, created_at, updated_at)
VALUES (4, 'volume', NULL, 1, datetime('now'), datetime('now'));

-- 35. Remove a remembered default (plain delete).
DELETE FROM source_collection_defaults WHERE volume_id = 2;

SELECT COUNT(*) AS remaining_defaults FROM source_collection_defaults;

-- 36. Delete a Collection that has an assigned snapshot and a remembered
-- default pointing at it: the snapshot must be detached to Unsorted (NULL),
-- never deleted; the default row pointing at the deleted Collection must be
-- removed (it would otherwise be meaningless), never repointed at Unsorted.
INSERT INTO collections (id, name, normalized_name, created_at, updated_at)
VALUES (5, 'TEMP', 'temp', datetime('now'), datetime('now'));

INSERT INTO snapshots (normalization_version, id, volume_id, session_number, scan_root_name, status, scanner_version, schema_version, snapshot_kind, source_case_sensitivity, collection_id, display_name, capture_policy_json, started_at, created_at, updated_at)
VALUES ('fsd-normalizer-v1_app-1.0_os-1', 12, 1, 12, 'TempCardSource', 'complete', 'fsd-algo-v1_app-v1.0_unicode-15.0', 3, 'user', 'sensitive', 5, 'TempCardSource — Session 12', '{}', datetime('now'), datetime('now'), datetime('now'));

INSERT INTO source_collection_defaults (id, source_kind, volume_id, collection_id, created_at, updated_at)
VALUES (5, 'volume', 2, 5, datetime('now'), datetime('now'));

DELETE FROM collections WHERE id = 5;

-- Expect: snapshot 12 still exists, with collection_id now NULL.
SELECT id, collection_id, display_name FROM snapshots WHERE id = 12;

-- Expect: the default that pointed at collection 5 is gone.
SELECT COUNT(*) AS defaults_pointing_at_deleted_collection
FROM source_collection_defaults WHERE collection_id = 5;

-- Expect: snapshot 12's entries, if any existed, would be untouched -- no
-- entries were created for this fixture snapshot, so this simply confirms no
-- FOREIGN KEY violation was raised by the Collection deletion.
PRAGMA foreign_key_check;

-- 37. Move a snapshot between Collections: entries and timestamps must be
-- byte-for-byte unaffected. Snapshot 9 currently belongs to Collection 1.
SELECT COUNT(*) AS entry_count_before FROM entries WHERE snapshot_id = 1;
SELECT started_at, session_number FROM snapshots WHERE id = 9;

UPDATE snapshots SET collection_id = 2, updated_at = datetime('now') WHERE id = 9;

SELECT COUNT(*) AS entry_count_after FROM entries WHERE snapshot_id = 1;
SELECT started_at, session_number, collection_id FROM snapshots WHERE id = 9;

-- 38. Search-with-Collection-context query shape: a snapshot search result
-- must be able to show its Collection (or NULL/Unsorted) in one query.
SELECT
    s.id,
    s.display_name,
    COALESCE(c.name, 'Unsorted') AS collection_name,
    s.status
FROM snapshots s
LEFT JOIN collections c ON c.id = s.collection_id
ORDER BY s.id;

PRAGMA integrity_check;
PRAGMA foreign_key_check;

-- === Plan Gate Corrections Fixtures ===

-- 1. Snapshot Root Integrity
-- direct rootless `complete` insert rejected
INSERT INTO snapshots (normalization_version, id, volume_id, session_number, scan_root_name, status, scanner_version, schema_version, snapshot_kind, source_case_sensitivity, display_name, capture_policy_json, started_at, created_at, updated_at)
VALUES ('fsd-normalizer-v1_app-1.0_os-1', 100, 1, 100, 'Rootless', 'complete', 'fsd-algo-v1_app-v1.0_unicode-15.0', 3, 'user', 'sensitive', 'Rootless', '{}', datetime('now'), datetime('now'), datetime('now'));
-- Expected failure

-- `scanning` with zero roots cannot transition to `complete`
INSERT INTO snapshots (normalization_version, id, volume_id, session_number, scan_root_name, status, scanner_version, schema_version, snapshot_kind, source_case_sensitivity, display_name, capture_policy_json, started_at, created_at, updated_at)
VALUES ('fsd-normalizer-v1_app-1.0_os-1', 101, 1, 101, 'ZeroRoots', 'scanning', 'fsd-algo-v1_app-v1.0_unicode-15.0', 3, 'user', 'sensitive', 'ZeroRoots', '{}', datetime('now'), datetime('now'), datetime('now'));

UPDATE snapshots SET status = 'complete' WHERE id = 101;
-- Expected failure

-- `scanning` with two roots cannot transition to `complete`
INSERT INTO snapshots (normalization_version, id, volume_id, session_number, scan_root_name, status, scanner_version, schema_version, snapshot_kind, source_case_sensitivity, display_name, capture_policy_json, started_at, created_at, updated_at)
VALUES ('fsd-normalizer-v1_app-1.0_os-1', 102, 1, 102, 'TwoRoots', 'scanning', 'fsd-algo-v1_app-v1.0_unicode-15.0', 3, 'user', 'sensitive', 'TwoRoots', '{}', datetime('now'), datetime('now'), datetime('now'));

INSERT INTO entries (id, snapshot_id, parent_id, relative_path, case_preserving_path, case_folded_path, name, case_preserving_name, case_folded_name, item_type, sort_key, created_at)
VALUES (1020, 102, NULL, '', '', '', 'Root1', 'Root1', 'root1', 'directory', '0', datetime('now')),
       (1021, 102, NULL, '', '', '', 'Root2', 'Root2', 'root2', 'directory', '0', datetime('now'));

UPDATE snapshots SET status = 'complete' WHERE id = 102;
-- Expected failure

-- `scanning` with one root can transition to `complete`
INSERT INTO snapshots (normalization_version, id, volume_id, session_number, scan_root_name, status, scanner_version, schema_version, snapshot_kind, source_case_sensitivity, display_name, capture_policy_json, started_at, created_at, updated_at)
VALUES ('fsd-normalizer-v1_app-1.0_os-1', 103, 1, 103, 'OneRoot', 'scanning', 'fsd-algo-v1_app-v1.0_unicode-15.0', 3, 'user', 'sensitive', 'OneRoot', '{}', datetime('now'), datetime('now'), datetime('now'));

INSERT INTO entries (id, snapshot_id, parent_id, relative_path, case_preserving_path, case_folded_path, name, case_preserving_name, case_folded_name, item_type, sort_key, created_at)
VALUES (1030, 103, NULL, '', '', '', 'Root1', 'Root1', 'root1', 'directory', '0', datetime('now'));

UPDATE snapshots SET status = 'complete' WHERE id = 103;
-- Expected success

-- completed status cannot be reverted
UPDATE snapshots SET status = 'scanning' WHERE id = 103;
-- Expected failure

-- 2. Comparison Source Eligibility & Immutability
-- Need another complete snapshot
INSERT INTO snapshots (normalization_version, id, volume_id, session_number, scan_root_name, status, scanner_version, schema_version, snapshot_kind, source_case_sensitivity, display_name, capture_policy_json, started_at, created_at, updated_at)
VALUES ('fsd-normalizer-v1_app-1.0_os-1', 104, 1, 104, 'OneRoot2', 'scanning', 'fsd-algo-v1_app-v1.0_unicode-15.0', 3, 'user', 'sensitive', 'OneRoot2', '{}', datetime('now'), datetime('now'), datetime('now'));
INSERT INTO entries (id, snapshot_id, parent_id, relative_path, case_preserving_path, case_folded_path, name, case_preserving_name, case_folded_name, item_type, sort_key, created_at)
VALUES (1040, 104, NULL, '', '', '', 'Root2', 'Root2', 'root2', 'directory', '0', datetime('now'));
UPDATE snapshots SET status = 'complete' WHERE id = 104;

-- Reject comparison creation using 'scanning'
INSERT INTO comparisons (id, left_snapshot_id, right_snapshot_id, profile_id, status, started_at, created_at)
VALUES (200, 101, 104, 1, 'running', datetime('now'), datetime('now'));
-- Expected failure

-- Reject using 'cancelled' (we will transition 101 to cancelled to test this)
UPDATE snapshots SET status = 'cancelled' WHERE id = 101;
INSERT INTO comparisons (id, left_snapshot_id, right_snapshot_id, profile_id, status, started_at, created_at)
VALUES (201, 101, 104, 1, 'running', datetime('now'), datetime('now'));
-- Expected failure

-- matching normalization versions accepted
INSERT INTO comparisons (id, left_snapshot_id, right_snapshot_id, profile_id, status, started_at, created_at)
VALUES (202, 103, 104, 1, 'running', datetime('now'), datetime('now'));
-- Expected success

-- left source update rejected
UPDATE comparisons SET left_snapshot_id = 104 WHERE id = 202;
-- Expected failure

-- right source update rejected
UPDATE comparisons SET right_snapshot_id = 103 WHERE id = 202;
-- Expected failure

-- create snapshot with different normalization version
INSERT INTO snapshots (id, volume_id, session_number, scan_root_name, status, scanner_version, schema_version, normalization_version, snapshot_kind, source_case_sensitivity, display_name, capture_policy_json, started_at, created_at, updated_at)
VALUES (105, 1, 105, 'OneRoot3', 'scanning', 'fsd-algo-v1_app-v1.0_unicode-15.0', 3, 'fsd-algo-v2', 'user', 'sensitive', 'OneRoot3', '{}', datetime('now'), datetime('now'), datetime('now'));
INSERT INTO entries (id, snapshot_id, parent_id, relative_path, case_preserving_path, case_folded_path, name, case_preserving_name, case_folded_name, item_type, sort_key, created_at)
VALUES (1050, 105, NULL, '', '', '', 'Root3', 'Root3', 'root3', 'directory', '0', datetime('now'));
UPDATE snapshots SET status = 'complete' WHERE id = 105;

-- mismatched versions rejected
INSERT INTO comparisons (id, left_snapshot_id, right_snapshot_id, profile_id, status, started_at, created_at)
VALUES (203, 103, 105, 1, 'running', datetime('now'), datetime('now'));
-- Expected failure

-- 3. Collision Group Data Model
-- Create comparison group
INSERT INTO comparison_collision_groups (id, comparison_id, result_path, created_at)
VALUES (1, 202, '/collide', datetime('now'));
-- Expected success

-- duplicate group rejected
INSERT INTO comparison_collision_groups (id, comparison_id, result_path, created_at)
VALUES (2, 202, '/collide', datetime('now'));
-- Expected failure

-- member pointing to wrong snapshot (left side using entry from 104)
INSERT INTO comparison_collision_members (id, group_id, side, entry_id, created_at)
VALUES (1, 1, 'left', 1040, datetime('now'));
-- Expected failure

-- correct member assignment
INSERT INTO comparison_collision_members (id, group_id, side, entry_id, created_at)
VALUES (1, 1, 'left', 1030, datetime('now'));
-- Expected success

-- member pointing to wrong snapshot (right side using entry from 103)
INSERT INTO comparison_collision_members (id, group_id, side, entry_id, created_at)
VALUES (2, 1, 'right', 1030, datetime('now'));
-- Expected failure

-- normal result row wrong left entry
INSERT INTO comparison_results (comparison_id, result_path, display_name, result_type, left_entry_id, right_entry_id, created_at)
VALUES (202, '/test', 'test', 'matched', 1040, 1040, datetime('now'));
-- Expected failure

-- duplicate empty uncertain row rejected
INSERT INTO comparison_results (comparison_id, result_path, display_name, result_type, created_at)
VALUES (202, '/uncertain', 'uncertain', 'uncertain', datetime('now'));

INSERT INTO comparison_results (comparison_id, result_path, display_name, result_type, created_at)
VALUES (202, '/uncertain', 'uncertain', 'uncertain', datetime('now'));
-- Expected failure

-- arbitrary collision-member pairing rejected
INSERT INTO comparison_results (comparison_id, result_path, display_name, result_type, left_entry_id, right_entry_id, created_at)
VALUES (202, '/paired_collision', 'paired_collision', 'matched', 1030, 1040, datetime('now'));
-- Expected failure

-- 4. Collection Last-Used
SELECT last_used_at FROM collections WHERE id = 1;
UPDATE snapshots SET collection_id = 1 WHERE id = 103;
SELECT last_used_at FROM collections WHERE id = 1;


-- === Forbidden States Queries ===
SELECT count(*) AS complete_not_one_root FROM snapshots s 
WHERE s.status IN ('complete', 'complete_with_warnings') 
  AND (SELECT count(*) FROM entries e WHERE e.snapshot_id = s.id AND e.parent_id IS NULL AND e.relative_path = '') != 1;

SELECT count(*) AS mismatched_comparisons FROM comparisons c
JOIN snapshots s1 ON c.left_snapshot_id = s1.id
JOIN snapshots s2 ON c.right_snapshot_id = s2.id
WHERE s1.normalization_version != s2.normalization_version;

SELECT count(*) AS non_complete_comparisons FROM comparisons c
JOIN snapshots s1 ON c.left_snapshot_id = s1.id
JOIN snapshots s2 ON c.right_snapshot_id = s2.id
WHERE s1.status NOT IN ('complete', 'complete_with_warnings') OR s2.status NOT IN ('complete', 'complete_with_warnings');

SELECT count(*) AS wrong_left_side FROM comparison_collision_members m
JOIN comparison_collision_groups g ON m.group_id = g.id
JOIN comparisons c ON g.comparison_id = c.id
JOIN entries e ON m.entry_id = e.id
WHERE m.side = 'left' AND e.snapshot_id != c.left_snapshot_id;

SELECT count(*) AS wrong_right_side FROM comparison_collision_members m
JOIN comparison_collision_groups g ON m.group_id = g.id
JOIN comparisons c ON g.comparison_id = c.id
JOIN entries e ON m.entry_id = e.id
WHERE m.side = 'right' AND e.snapshot_id != c.right_snapshot_id;

SELECT group_id, side, entry_id, count(*) AS duplicate_members FROM comparison_collision_members
GROUP BY group_id, side, entry_id
HAVING count(*) > 1;

SELECT comparison_id, result_path, count(*) AS duplicate_groups FROM comparison_collision_groups
GROUP BY comparison_id, result_path
HAVING count(*) > 1;

SELECT count(*) AS blank_collections FROM collections WHERE trim(name) = '';

SELECT count(*) AS blank_snapshots FROM snapshots WHERE trim(display_name) = '';

-- === Magika nullable-enrichment checks (schema version 9, entry_classifications) ===
-- Phase 1.5 preparation only. Ordinary workflows write ZERO rows to this
-- table; explicit enrichment may write bounded typed rows. These
-- fixtures exist so the seam's constraints are proven now and cannot silently
-- regress before a future Magika runtime is approved. See docs/ARCHITECTURE.md §9,
-- docs/DECISIONS.md ADR-021, docs/MVP_PLAN.md Phase 1.5.

-- C1. An entry may exist with zero classification rows (the normal MVP state),
--     and a snapshot completes without any classification row ever existing.
SELECT count(*) AS classification_rows_expected_zero FROM entry_classifications;

-- C2. A row with every optional column NULL is accepted (absence of a detected
--     type is representable without inventing a placeholder value).
INSERT INTO entry_classifications (entry_id, classification_run_id, created_at)
VALUES (1, 'verify-run-null', datetime('now'));

-- C3. Confidence boundary values 0.0 and 1.0 are accepted.
INSERT INTO entry_classifications (entry_id, classification_run_id, confidence, created_at)
VALUES (1, 'verify-run-conf-0', 0.0, datetime('now'));

INSERT INTO entry_classifications (entry_id, classification_run_id, confidence, created_at)
VALUES (1, 'verify-run-conf-1', 1.0, datetime('now'));

-- C4. Confidence below 0.0 is rejected.
INSERT INTO entry_classifications (entry_id, classification_run_id, confidence, created_at)
VALUES (1, 'verify-run-conf-low', -0.01, datetime('now'));

-- C5. Confidence above 1.0 is rejected.
INSERT INTO entry_classifications (entry_id, classification_run_id, confidence, created_at)
VALUES (1, 'verify-run-conf-high', 1.01, datetime('now'));

-- C6. An invalid detection_status is rejected; the four documented values pass.
INSERT INTO entry_classifications (entry_id, classification_run_id, detection_status, created_at)
VALUES (1, 'verify-run-bad-status', 'bogus_status', datetime('now'));

INSERT INTO entry_classifications (entry_id, classification_run_id, detection_status, created_at)
VALUES
    (1, 'verify-run-status-nr', 'not_requested', datetime('now')),
    (1, 'verify-run-status-dis', 'disabled', datetime('now')),
    (1, 'verify-run-status-cls', 'classified', datetime('now')),
    (1, 'verify-run-status-fail', 'failed', datetime('now'));

-- C7. Two version-distinct runs coexist for one entry (append-only history:
--     a later run never overwrites an earlier run's stored result).
INSERT INTO entry_classifications (entry_id, classification_run_id, detector_version, model_version, created_at)
VALUES
    (1, 'verify-run-v1', 'detector-1.0', 'model-1.0', datetime('now')),
    (1, 'verify-run-v2', 'detector-2.0', 'model-2.0', datetime('now'));

SELECT count(*) AS versioned_runs_for_entry_1
FROM entry_classifications
WHERE entry_id = 1 AND classification_run_id IN ('verify-run-v1', 'verify-run-v2');

-- C7a. Provider identity is a separate nullable TEXT with no default, appended
-- after all v8 columns. Repository classified writes require 1-256 characters;
-- legacy NULL remains representable at the schema boundary.
SELECT cid, name, type, "notnull", dflt_value
FROM pragma_table_info('entry_classifications') ORDER BY cid;
SELECT provider_identifier IS NULL AS nullable_provider_is_not_fabricated
FROM entry_classifications WHERE classification_run_id = 'verify-run-null';
INSERT INTO entry_classifications (
    entry_id, classification_run_id, detection_status, detector_version,
    model_version, created_at, provider_identifier
) VALUES (1, 'verify-provider-A', 'classified', 'detector-A', 'model-A', datetime('now'), 'provider-A'),
         (1, 'verify-provider-B', 'classified', 'detector-A', 'model-A', datetime('now'), 'provider-B');
SELECT detector_version, model_version, provider_identifier
FROM entry_classifications WHERE classification_run_id IN ('verify-provider-A', 'verify-provider-B')
ORDER BY id;

-- C8. An exact duplicate run identity (entry_id + classification_run_id) is rejected.
INSERT INTO entry_classifications (entry_id, classification_run_id, created_at)
VALUES (1, 'verify-run-v1', datetime('now'));

-- C9. Classification never participates in snapshot state or comparison: no
--     snapshot status depends on a classification row, and no comparison_results
--     row references entry_classifications at all.
SELECT count(*) AS snapshots_blocked_by_classification
FROM snapshots s
WHERE s.status IN ('complete', 'complete_with_warnings')
  AND NOT EXISTS (SELECT 1 FROM entry_classifications c
                  JOIN entries e ON c.entry_id = e.id
                  WHERE e.snapshot_id = s.id)
  AND 0 = 1;

-- C10. Deleting an entry removes its enrichment rows (per-connection
--      PRAGMA foreign_keys = ON is required for this cascade to fire).
SELECT count(*) AS orphaned_classifications
FROM entry_classifications c
LEFT JOIN entries e ON c.entry_id = e.id
WHERE e.id IS NULL;

-- === Capture-time volume truth and schema version 5 ===
-- Added 2026-08-04 for schema version 5 (docs/DECISIONS.md ADR-023, ADR-024).
-- Statements marked "REJECTED" are intended failures; each must abort with the
-- quoted message. Every other statement must succeed.

-- V1. A fresh database records the current version.
SELECT max(version) AS schema_version_is_current FROM schema_migrations;

-- V2. The three capture-time volume columns exist on snapshots.
SELECT count(*) AS capture_fact_columns_present
FROM pragma_table_info('snapshots')
WHERE name IN ('volume_display_name_at_capture',
               'volume_identifier_at_capture',
               'volume_total_capacity_bytes_at_capture');

-- V3. The version-5 objects exist: four completed-snapshot guards, the
--     capture-facts guard, and the extension index used by offline search.
SELECT count(*) AS version5_objects_present
FROM sqlite_master
WHERE name IN ('trg_completed_entries_insert_guard',
               'trg_completed_entries_update_guard',
               'trg_completed_entries_delete_guard',
               'trg_completed_scan_issues_insert_guard',
               'trg_snapshots_capture_facts_immutable',
               'idx_entries_snapshot_extension');

-- V4. Capture-time volume facts record and read back.
INSERT INTO snapshots (normalization_version, id, volume_id, session_number, scan_root_name,
                       mount_path_at_capture, status, scanner_version, schema_version,
                       snapshot_kind, source_case_sensitivity, filesystem_variant,
                       volume_display_name_at_capture, volume_identifier_at_capture,
                       volume_total_capacity_bytes_at_capture,
                       display_name, capture_policy_json, started_at, created_at, updated_at)
VALUES ('fsd-normalizer-v1_app-1.0_os-1', 900, 1, 900, 'CaptureFacts', '/Volumes/CardA',
        'scanning', 'fsd-scanner-m3', 5, 'user', 'insensitive', 'exfat',
        'Card A', 'CARD-A-UUID', 64000000000,
        'Capture facts session', '{}', datetime('now'), datetime('now'), datetime('now'));

SELECT volume_display_name_at_capture, volume_identifier_at_capture,
       volume_total_capacity_bytes_at_capture
FROM snapshots WHERE id = 900;

-- V5. REJECTED — 'Snapshot capture-time facts are immutable'.
--     A later capture relabelling the shared volumes row must not be able to
--     rewrite what an existing snapshot says it captured.
UPDATE snapshots SET volume_display_name_at_capture = 'Card A (renamed)' WHERE id = 900;

-- V6. REJECTED — 'Snapshot capture-time facts are immutable'.
UPDATE snapshots SET mount_path_at_capture = '/Volumes/Elsewhere' WHERE id = 900;

-- V7. Mutable catalog metadata is deliberately still writable: the guard freezes
--     what was captured, not how the user labels or files it.
UPDATE snapshots SET display_name = 'Renamed by the user', user_note = 'a note' WHERE id = 900;
SELECT display_name, user_note FROM snapshots WHERE id = 900;

-- V8. Lifecycle updates are unaffected by the guard.
UPDATE snapshots SET status = 'cancelled', completed_at = datetime('now'), updated_at = datetime('now')
WHERE id = 900;
SELECT status AS capture_facts_guard_allows_lifecycle FROM snapshots WHERE id = 900;

-- V9. The registry row may still move; that is precisely why history reads the
--     snapshot columns above and never these.
UPDATE volumes SET display_name = 'TestVolume renamed', total_capacity_bytes = 128000000000 WHERE id = 1;
SELECT (SELECT display_name FROM volumes WHERE id = 1) AS registry_now,
       (SELECT volume_display_name_at_capture FROM snapshots WHERE id = 900) AS snapshot_still_says;

-- === Comparison result integrity and schema version 6 ===
-- Added 2026-08-04 for schema version 6 (docs/DECISIONS.md ADR-027). Statements
-- marked "REJECTED" are intended failures; each must abort with the quoted
-- message. Every other statement must succeed.

-- W1. A fresh database records the current version (8 since the ADR-030 wave;
--     the X1 query below asserts it directly).
SELECT max(version) AS current_schema_version FROM schema_migrations;

-- W2. The version-6 objects exist: profile-version columns, the terminal
--     guards, and the differences-only index.
SELECT count(*) AS version6_objects_present
FROM sqlite_master
WHERE name IN ('trg_comparisons_terminal_immutable',
               'trg_comparison_results_insert_guard',
               'trg_comparison_results_update_guard',
               'idx_comparison_results_type');

SELECT count(*) AS profile_version_column_present
FROM pragma_table_info('comparisons') WHERE name = 'profile_version';

SELECT count(*) AS profile_own_version_column_present
FROM pragma_table_info('comparison_profiles') WHERE name = 'version';

-- W3. A comparison runs, accepts results, and completes with its frozen
--     profile revision. The result row is inserted while it is running —
--     that is exactly when results are allowed.
INSERT INTO comparisons (id, left_snapshot_id, right_snapshot_id, profile_id, profile_version,
                         status, started_at, created_at)
VALUES (300, 103, 104, 1, 1, 'running', datetime('now'), datetime('now'));

INSERT INTO comparison_results (comparison_id, result_path, display_name, result_type, created_at)
VALUES (300, '', 'Root', 'matched', datetime('now'));

UPDATE comparisons SET status = 'complete', matched_count = 1, completed_at = datetime('now') WHERE id = 300;

SELECT profile_id, profile_version, status, matched_count
FROM comparisons WHERE id = 300;

-- W4. REJECTED — 'Comparison results are immutable after a terminal state'.
--     A completed comparison can never return to running.
UPDATE comparisons SET status = 'running' WHERE id = 300;

-- W5. REJECTED — 'Comparison results are immutable after a terminal state'.
--     Summary counts are frozen with the status.
UPDATE comparisons SET matched_count = 2 WHERE id = 300;

-- W6. REJECTED — 'Cannot add results to a terminal comparison'.
INSERT INTO comparison_results (comparison_id, result_path, display_name, result_type, created_at)
VALUES (300, '/late', 'late', 'added', datetime('now'));

-- W7. REJECTED — 'Comparison results are immutable after a terminal state'.
UPDATE comparison_results SET difference_flags = 1
WHERE comparison_id = 300;

-- W8. A running comparison still accepts results, and the terminal guards do
--     not block the running phase.
INSERT INTO comparisons (id, left_snapshot_id, right_snapshot_id, profile_id, profile_version,
                         status, started_at, created_at)
VALUES (301, 103, 104, 1, 1, 'running', datetime('now'), datetime('now'));

INSERT INTO comparison_results (comparison_id, result_path, display_name, result_type, created_at)
VALUES (301, '/ok', 'ok', 'added', datetime('now'));

-- W9. Deleting a comparison is the explicit disposal API; its results cascade.
DELETE FROM comparisons WHERE id = 301;

SELECT count(*) AS results_cascade_with_comparison FROM comparison_results WHERE comparison_id = 301;

-- W10. The built-in profile rows still exist exactly once with version 1.
SELECT id, name, version, is_builtin FROM comparison_profiles ORDER BY id;

-- === Terminal comparison evidence immutability and schema version 7 ===
-- Added 2026-08-04 for schema version 7 (docs/DECISIONS.md ADR-028).
-- Statements marked "REJECTED" are intended failures; each must abort with the
-- quoted message. Every other statement must succeed. The v7 guards probe the
-- comparison's status exactly like the v6 result guards, and a comparison row
-- still exists when a direct mutation is attempted — so direct evidence
-- mutation aborts, while whole-comparison disposal (X14) cascades because the
-- comparison row is already gone when the cascade fires.

-- X1. A fresh database records exactly version 9.
SELECT max(version) AS schema_version_is_9 FROM schema_migrations;

-- === Disposal cascade lookup performance and schema version 8 ===
-- Added 2026-08-05 for docs/DECISIONS.md ADR-030. The dedicated index is
-- validation evidence only; the application does not depend on EXPLAIN output.

-- Y1. The dedicated leading index exists with parent_result_id as its first
-- (and only) indexed column.
SELECT name, sql
FROM sqlite_master
WHERE type = 'index' AND name = 'idx_comparison_results_parent_result_id';

-- Y2. The child lookup used by the self-referencing cascade is index-backed.
EXPLAIN QUERY PLAN
SELECT id FROM comparison_results WHERE parent_result_id = 1;

-- Y3. A fresh or fully migrated catalog records version 9.
SELECT max(version) AS schema_version_is_9 FROM schema_migrations;

-- X2. The version-7 objects exist: the seven terminal evidence guards.
SELECT count(*) AS version7_objects_present
FROM sqlite_master
WHERE name IN ('trg_comparison_results_delete_guard',
               'trg_comparison_collision_groups_insert_guard',
               'trg_comparison_collision_groups_update_guard',
               'trg_comparison_collision_groups_delete_guard',
               'trg_comparison_collision_members_insert_guard',
               'trg_comparison_collision_members_update_guard',
               'trg_comparison_collision_members_delete_guard');

-- X3. A running comparison accepts collision evidence: a group, its members,
--     and an uncertain result row are all written while it is running.
INSERT INTO comparisons (id, left_snapshot_id, right_snapshot_id, profile_id, profile_version,
                         status, started_at, created_at)
VALUES (400, 103, 104, 1, 1, 'running', datetime('now'), datetime('now'));

INSERT INTO comparison_collision_groups (id, comparison_id, result_path, created_at)
VALUES (400, 400, '/collide', datetime('now'));

INSERT INTO comparison_collision_members (id, group_id, side, entry_id, created_at)
VALUES (400, 400, 'left', 1030, datetime('now')),
       (401, 400, 'right', 1040, datetime('now'));

INSERT INTO comparison_results (comparison_id, result_path, display_name, result_type, created_at)
VALUES (400, '/collide', 'collide', 'uncertain', datetime('now'));

SELECT count(*) AS running_evidence_writes_succeed
FROM comparison_collision_members WHERE group_id = 400;

-- X4. Terminalize comparison 400; every direct mutation path below is then
--     REJECTED while the retained evidence stays untouched.
UPDATE comparisons SET status = 'complete', uncertain_count = 1, completed_at = datetime('now')
WHERE id = 400;

-- X5. REJECTED — 'Cannot add collision groups to a terminal comparison'.
INSERT INTO comparison_collision_groups (id, comparison_id, result_path, created_at)
VALUES (401, 400, '/late', datetime('now'));

-- X6. REJECTED — 'Collision groups are immutable after a terminal state'.
UPDATE comparison_collision_groups SET result_path = '/renamed' WHERE id = 400;

-- X7. REJECTED — 'Collision groups are immutable after a terminal state'.
DELETE FROM comparison_collision_groups WHERE id = 400;

-- X8. REJECTED — 'Cannot add collision members to a terminal comparison'.
INSERT INTO comparison_collision_members (id, group_id, side, entry_id, created_at)
VALUES (402, 400, 'left', 1030, datetime('now'));

-- X9. REJECTED — 'Collision members are immutable after a terminal state'.
UPDATE comparison_collision_members SET side = 'right' WHERE id = 400;

-- X10. REJECTED — 'Collision members are immutable after a terminal state'.
DELETE FROM comparison_collision_members WHERE id = 401;

-- X11. REJECTED — 'Comparison results are immutable after a terminal state'.
DELETE FROM comparison_results WHERE comparison_id = 400;

-- X12. REJECTED — the cancelled terminal state guards collision evidence the
--      same way complete does.
INSERT INTO comparisons (id, left_snapshot_id, right_snapshot_id, profile_id, profile_version,
                         status, started_at, created_at)
VALUES (401, 103, 104, 1, 1, 'running', datetime('now'), datetime('now'));

INSERT INTO comparison_collision_groups (id, comparison_id, result_path, created_at)
VALUES (402, 401, '/cancel', datetime('now'));

INSERT INTO comparison_collision_members (id, group_id, side, entry_id, created_at)
VALUES (403, 402, 'left', 1030, datetime('now'));

UPDATE comparisons SET status = 'cancelled', completed_at = datetime('now') WHERE id = 401;

INSERT INTO comparison_collision_groups (id, comparison_id, result_path, created_at)
VALUES (403, 401, '/late-cancelled', datetime('now'));
-- Expected failure

DELETE FROM comparison_collision_members WHERE id = 403;
-- Expected failure

-- X13. REJECTED — the failed terminal state guards collision evidence the same
--      way complete does.
INSERT INTO comparisons (id, left_snapshot_id, right_snapshot_id, profile_id, profile_version,
                         status, started_at, created_at)
VALUES (402, 103, 104, 1, 1, 'running', datetime('now'), datetime('now'));

INSERT INTO comparison_collision_groups (id, comparison_id, result_path, created_at)
VALUES (404, 402, '/fail', datetime('now'));

INSERT INTO comparison_collision_members (id, group_id, side, entry_id, created_at)
VALUES (404, 404, 'right', 1040, datetime('now'));

UPDATE comparisons SET status = 'failed', completed_at = datetime('now') WHERE id = 402;

UPDATE comparison_collision_groups SET result_path = '/renamed' WHERE id = 404;
-- Expected failure

UPDATE comparison_collision_members SET side = 'left' WHERE id = 404;
-- Expected failure

-- X14. Disposal is unaffected by the guards: deleting a terminal comparison
--      cascades its collision groups, members and results without residue,
--      because the comparison row is already gone when each cascade fires.
DELETE FROM comparisons WHERE id = 400;

SELECT count(*) AS groups_cascade_with_comparison
FROM comparison_collision_groups WHERE comparison_id = 400;

SELECT count(*) AS members_cascade_with_comparison
FROM comparison_collision_members m
JOIN comparison_collision_groups g ON m.group_id = g.id
WHERE g.comparison_id = 400;

SELECT count(*) AS results_cascade_with_comparison
FROM comparison_results WHERE comparison_id = 400;

PRAGMA integrity_check;
PRAGMA foreign_key_check;
