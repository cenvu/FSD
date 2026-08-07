# Test Plan

## 1. Critical tests

### CT-001 — No source writes

Mount a writable test volume and capture it. Compare full filesystem state before and after. Repeat against a raw physical device captured through `EmbeddedRawProvider` (Phase 3), comparing full device state (not just filesystem-level state) before and after.

Pass condition:

- no files, folders, extended attributes or timestamps are changed by FSD — FishSock Differ;
- no hidden marker or database is created on the source;
- for a raw-device capture, no byte on the device changed and no write syscall was issued, verified independently of the filesystem-level check.

### CT-006 — Embedded reader crash isolation

Feed the reader helper process (`FILESYSTEM_PROVIDER_ARCHITECTURE.md` §8) a deliberately corrupted ext4 image (truncated superblock, invalid extent tree).

Pass condition:

- the main app process does not crash or hang;
- the capture is marked with bounded `scan_issues` (`source = 'reader'`), never presented as `complete`;
- already-committed rows from earlier in the same capture are not lost.

### CT-007 — Non-native filesystem name edge cases

Capture an ext2/3/4 fixture containing a non-UTF-8 filename byte sequence, and an ext4 fixture with an fscrypt-encrypted subtree.

Pass condition:

- the non-UTF-8 name produces a recorded issue and an excluded-from-comparison entry, never a crash or a silently mangled name;
- the encrypted subtree is recorded as `is_inaccessible = 1` with a `scan_issue`, never as a decoded name or a silently empty folder.

### CT-008 — Cross-provider comparison

Compare a snapshot captured via `EmbeddedRawProvider` (ext4) against one captured via `NativeMountedProvider` (APFS).

Pass condition:

- the diff engine produces the same classification behavior it would for two same-provider snapshots — no provider-specific special case leaks into comparison results.

### CT-002 — Disconnect during scan

Disconnect a test drive during a long capture.

Pass condition:

- application remains responsive;
- active snapshot becomes `interrupted`;
- previous complete snapshot remains default and readable;
- database integrity check passes.

### CT-003 — Offline browsing

Complete a capture, eject the drive and browse every top-level folder.

Pass condition:

- all stored metadata remains available;
- unavailable actions are disabled;
- no unexpected attempt to access the missing mount path blocks UI.

### CT-004 — Metadata diff correctness

Create two fixtures with known added, removed, changed and matched items.

Pass condition:

- every expected classification is correct;
- logical-size changes are detected;
- ignored service files do not affect Fast Metadata summary.

### CT-005 — Large catalog memory behavior (Milestone 5)

Generate or use a fixture containing at least 1,000,000 entries. This is the
Milestone 5 final-scale acceptance gate; Milestone 3 evidence is the verified
100,101-entry lazy-catalog run.

Pass condition:

- tree view opens without loading all rows into memory;
- expanding one branch performs bounded queries;
- scrolling remains usable.

## 2. Scanner fixtures

Include:

- empty folder;
- deeply nested tree;
- wide folder with many children;
- Unicode names;
- canonically equivalent NFC/NFD names and collisions;
- case-collision names on case-sensitive filesystem;
- case-fold golden cases (e.g. ASCII variants, ß and ss, Greek sigma forms, dotted/dotless I, embedded separator rejection);
- files without extensions;
- symbolic links;
- broken symbolic links;
- packages;
- hidden files;
- inaccessible folders;
- sparse files;
- zero-byte files;
- very large logical-size files;
- paths near filesystem length limits.

## 3. Filesystem matrix

The full per-filesystem test/behavior matrix (10 filesystem variants across 7 filesystem families, plus the 7-step definition of "supported") is canonical in [`FILESYSTEM_SUPPORT_MATRIX.md`](FILESYSTEM_SUPPORT_MATRIX.md) — not restated here. This section only records the additional dimensions worth tracking once real fixtures exist, beyond what that matrix already specifies per filesystem:

- UUID availability;
- timestamp precision;
- allocated size reporting;
- resource identifier stability;
- case sensitivity (including per-volume detection, not assumption, for APFS/HFS+/ext4's case-insensitivity feature flag);
- for ext2/ext3/ext4 specifically: non-UTF-8 filename handling and fscrypt-encrypted-subtree handling (CT-007).

## 4. Performance benchmarks

Measure:

- entries per second;
- SQLite insert throughput;
- peak memory;
- UI frame responsiveness;
- database size per 100,000 entries;
- cold and warm search latency;
- snapshot-to-snapshot diff latency.

Benchmark classes:

```text
Small      10,000 entries
Medium    100,000 entries
Large   1,000,000 entries
```

Milestone 4 evidence (automated, `ComparisonScaleTests`, synthetic catalogs):
100,202 entries per side, predominantly unchanged, with added/removed branches
and 100 modified entries — compare duration 12.7 s (Debug `-Onone` build),
classification exactly 100,001 matched / 100 changed / 101 added / 101
removed, first-page latency 0.0033 s, differences-only latency 0.0125 s,
repeat-run result set identical, and paging bounded. Peak memory was not
measured (only recorded when easily available).

**Milestone 5 final-scale evidence (2026-08-04, `FinalScaleSnapshotTests` /
`FinalScaleComparisonTests` / `FinalScaleMemoryProbeTests`, synthetic SQLite
catalogs, no physical files):** the 1,000,000-entry class is now the closed
final gate (CT-005). Snapshot catalog: 1,002,182 entries (1,000 dirs × 1,000
files plus a 40-level deep branch and a hidden directory); history opens,
root first page and direct-child pages stay at the configured 200-row page,
the deep branch expands level by level, bounded search returns first-page
results quickly, deterministic streamed JSON export completes (~340 MB for
the million entries) with byte-identical repeat output, and the catalog
reopens with `integrity_check` ok, `foreign_key_check` clean and zero
classification rows. Comparison: 1,003,104 vs 1,003,205 entries per side with
exact classification 1,000,003 matched / 1,000 changed / 1,001 added / 1,001
removed / 601 uncertain (500 case-fold collision groups with 2,000 members,
never paired) / 200 ignored; 1,003,806 result rows; repeat-run fingerprint
identical; differences-only and per-outcome paging bounded; next/previous
navigation walks the full deterministic order; cancellation at 500,000
processed leaves a cancelled comparison whose counts match its retained
evidence; disposal leaves zero residue. Memory: browsing, search and export
retain only bounded pages (export streams — peak well below the output
size); the merge peak stays far below either full tree; the pathological
150,000-member equal-key collision group is a typed failure
(`ComparisonError.collisionGroupTooLarge`, KI-023), never an OOM. Debug runs
are correctness evidence; Release runs are the performance acceptance basis.
Timings and memory figures are recorded in the Milestone 5 Handoff with the
machine/toolchain context.

## 5. Database tests

- fresh database creation;
- per-connection `PRAGMA foreign_keys = ON` verification (startup assertion);
- migration from every previous schema version that was ever materialized (versions 1-3 never were and are rejected, not migrated — ADR-024);
- both known version-4 variants converge to version 5 (implemented: `FSDTests/SchemaMigrationTests.swift`);
- a failing migration rolls back and leaves the recorded version unchanged (implemented);
- reopening the current version does not replay a migration (implemented);
- a fresh and a migrated database expose the same tables, triggers, indexes and columns, and enforce the same immutable-entry rules (implemented);
- opening a catalog whose version claims more than its objects deliver fails loudly (implemented);
- capture-time snapshot facts reject later mutation while user labelling and lifecycle fields stay writable (implemented; also `database/verify.sql` V1-V9);
- interrupted transaction recovery;
- WAL checkpoint behavior;
- foreign key enforcement;
- orphan entry prevention;
- deletion of one snapshot without affecting another;
- startup recovery of stale `scanning` snapshots;
- invalid `snapshot_kind` is rejected;
- invalid `source_case_sensitivity` is rejected;
- exact duplicate `relative_path` is rejected;
- root insertion succeeds, second root is rejected;
- parentless non-root entry is rejected;
- cross-snapshot parent reference is rejected;
- terminal snapshot status without exactly one valid root is rejected;
- normalization version mismatch comparison is blocked;
- deleting a transient snapshot referenced by a running comparison is rejected;
- transient snapshot cleanup succeeds when comparison is closed or terminal;
- crash cleanup removes unreferenced abandoned transient snapshots;
- collision group members are retained in `comparison_results` and not arbitrarily paired;
- `filesystem_provider`/`source_access_mode` combination mismatches are rejected (native+raw_device, embedded_raw+mounted);
- negative `partition_offset` or non-positive `partition_length` is rejected;
- `scan_issues.source` rejects a value outside `('scanner', 'reader')`;
- blank `collections.name` is rejected; a normalized duplicate `collections.name` is rejected;
- blank `snapshots.display_name` is rejected;
- `source_collection_defaults` rejects any `source_kind` other than `'volume'`, and rejects `source_kind = 'volume'` with a `NULL volume_id`;
- deleting a `collections` row detaches its snapshots (`collection_id` set `NULL`) and removes its `source_collection_defaults` rows, without deleting any snapshot or entry row;
- exercised against a fresh database in `database/verify.sql`.

Milestone 4 comparison backend tests (implemented 2026-08-04): the list above
plus the schema-version-6 wave (`verify.sql` W1-W10 and
`FSDTests/Comparison*Tests` + `SchemaMigrationTests`):

- version 6 records the profile revision on the comparison row and freezes it
  (implemented: `testProfileVersionIsFrozenOnTheComparisonRecord`);
- a terminal comparison's status and summary counts are immutable at the
  schema boundary; result rows cannot be inserted or updated after a terminal
  state (implemented: `testTerminalComparisonStatusAndCountsAreImmutableAtTheSchemaBoundary`,
  `testTerminalResultsCannotBeInsertedOrUpdated`, verify.sql W4-W7);
- deleting a whole comparison is the explicit disposal API and cascades its
  results (implemented: `testDeletingAComparisonIsTheExplicitDisposalAPI`);
- comparison classification semantics: matched/added/removed/changed with
  field-level `difference_flags`, ignored service files, hidden-item policy,
  inaccessible → uncertain, deterministic ordering (implemented:
  `ComparisonSemanticsTests`);
- identity semantics: case sensitivity selection, case-fold collisions never
  paired, NFC/NFD equivalence, unknown sensitivity warning (implemented:
  `ComparisonIdentityTests`);
- snapshot eligibility: only complete / complete-with-warnings, typed errors
  otherwise (implemented: `ComparisonSnapshotStateTests`);
- the three modes with transient captures, cancellation, workspace close,
  launch recovery, and transient cleanup (implemented: `ComparisonModeTests`);
- summary counts match detailed rows for every terminal state (implemented:
  `ComparisonPersistenceTests`);
- 100,000-entry-per-side class: deterministic, bounded, differences-only,
  cancellation, rerun identical (implemented: `ComparisonScaleTests`);
- **1,000,000-entry final-scale class (Milestone 5, implemented 2026-08-04):**
  `FinalScaleSnapshotTests` (1,002,182-entry catalog: generation, history,
  root/direct-child/deep pages, bounded search, hidden/path filters,
  deterministic ordering, streamed JSON export with size and repeat
  determinism, reopen, integrity/foreign-key/classification checks);
  `FinalScaleComparisonTests` (1,003,104 vs 1,003,205 per side: exact
  classification across all six outcome types, 500 collision groups with
  2,000 members, differences-only paging walk, per-outcome filter counts,
  next/previous navigation across page boundaries, cancellation at 500,000
  processed with count-consistent evidence, repeat-run determinism via
  result fingerprint, result reopen, and whole-comparison disposal at the
  100,202-per-side class with zero residue); schema-v8 regression tests add
  query-plan evidence plus direct synthetic one-million-result explicit
  disposal and canonical live-workspace-close disposal under 120 seconds in
  Release, with snapshot/transient preservation, post-disposal write,
  integrity and foreign-key checks (`FinalScaleComparisonTests`); 
  `FinalScaleMemoryProbeTests` (bounded browsing/search/export
  footprint, merge peak, disposal fall-back, page caps, pathological
  collision group as typed failure); `CancellationRaceStressTests` (repeated
  capture/live-mode/merge cancellation, finalization race, orphan recovery,
  workspace close during a running live comparison); `M5ReliabilityTests`
  (fresh startup, lock contention, repeated open/close cycles, interrupted-op
  relaunch stability, damaged-schema rejection, owner-catalog isolation);
- isolated end-to-end probe: two controlled folders through the production
  scanner, live-to-live and offline snapshot-to-snapshot, source removal,
  catalog reopen, fixtures byte-identical, zero classification rows
  (implemented: `ComparisonEndToEndProbeTests`).
- GUI orchestration and result paging boundaries: snapshot/live source mode
  validation, cancellation bindings, and view-ready filter mapping
  (implemented: `ComparisonWorkspaceModelTests`, `ComparisonBrowserModelTests`).

Milestone 4 GUI correction tests (implemented 2026-08-04, `ComparisonGUIValidationTests`
32 tests, `ComparisonGUISourceBoundaryTests` 7 tests, `FSDProbeSeedTests` 1
marker-gated seeder, plus the updated `ComparisonWorkspaceModelTests` 5 and
`ComparisonBrowserModelTests` 2):

- canonical orientation: snapshot-to-snapshot left/reference-right/changed,
  live-to-snapshot snapshot-left/live-right through the production scanner,
  live-to-live left/reference-right/changed, added/right-only and
  removed/left-only wording that fails when a side is reversed;
- workflow and terminal state: request construction keeps side order,
  validation messages (invalid sides, same side twice, missing live source),
  mode switching, progress updates, cancellation presented as cancelled (never
  complete), ineligible snapshot presented as failed with a bounded message
  (no raw SQLite text);
- bounded paging: first page at offset zero, next/previous page, retained row
  count ≤ page size across every page of a 201-row comparison, filter change
  resets to offset zero, stale async responses ignored via the generation
  guard;
- navigation: within page, across a page boundary in both directions with the
  target row materialized, selected and detailed, first/last result, boundary
  buttons disabled from repository navigation truth (not page emptiness),
  differences-only navigation, filter change after navigation resets page and
  selection;
- details: metadata and field differences loaded through
  `ComparisonResultRepository.entryMetadata`/`fieldDifferences` only,
  added/removed missing-side presentation, uncertain never presented as
  added/removed/matched, profile name/version, ADR-010 warnings, side status,
  all canonical summary counts;
- lifecycle: closing a persisted snapshot-to-snapshot workspace preserves the
  comparison and snapshots, closing a live workspace disposes the comparison
  and releases its transient through the canonical lifecycle, explicit delete
  confirmation disposal for live and persisted comparisons;
- source boundary: no SQL/token/table-name access in any `FSD/UI/Comparison*`
  source, shared `EmptyStateView` project-referenced with no private duplicate
  in the app shell, approved repository API surface intact, schema still
  version 8;
- agent-run probe seeding: with `FSD_PROBE_CATALOG` or the
  `/tmp/fsd-probe-catalog-path.txt` marker file, seeds an isolated catalog
  with a full-outcome snapshot-to-snapshot comparison plus a live-to-snapshot
  comparison with its referenced transient; inert (skipped) in ordinary runs.

Full-suite evidence (2026-08-04, fresh arm64, signing disabled, Xcode 26.3 /
Swift 6.2.4): **240 tests executed, 237 passed, 0 failed, 3 skipped**. The
three skips are environment/marker-gated probes only: two filesystem-matrix
probes (`FSD_MATRIX_SOURCE` / `FSD_MATRIX_OFFLINE_CATALOG` not set) and the
probe seeder (marker absent).

Schema-v8 correction evidence (2026-08-05, fresh macOS 15.7.7 arm64,
Xcode 26.3 / Swift 6.2.4, signing disabled): clean Debug and Release builds
passed; the full Debug suite passed **284 executed, 281 passed, 0 failed, 3
skipped** for the same two unset filesystem-matrix variables and absent probe
marker; focused Release schema/drift/disposal suites passed **33 executed, 33
passed, 0 failed, 0 skipped**. Release disposal timings were 9.930 s for
explicit one-million-result disposal and 10.018 s for automatic live-workspace
close, both under the 120-second threshold. Manual acceptance remains
**NOT PERFORMED — DEFERRED BY OWNER**.

Milestone 4 schema-safety correction tests (implemented 2026-08-04,
schema version 8, ADR-028/ADR-030; `verify.sql` X1-X14 plus Y1-Y3 and
`SchemaSafetyCorrectionTests` + the updated `SchemaMigrationTests`):

- terminal collision evidence: group and member INSERT/UPDATE/DELETE are
  allowed while a comparison is `running` and rejected after `complete`,
  `cancelled` and `failed`; ordinary result-row DELETE is rejected after the
  terminal state; snapshots and entries remain untouched;
- whole-comparison disposal still cascades collision members, collision
  groups and results without residue, for running and terminal comparisons
  alike, with `integrity_check` and `foreign_key_check` clean;
- fresh v8; v7-to-v8; v6-to-v8; v5-to-v8 through the chain; both known v4
  variants to v8; v8 migration rollback (version 7 stays recorded, no partial
  objects);
  reopen without replay; fresh and migrated object equivalence;
- ExpectedState inventory parity: every trigger, index and table in
  `database/schema.sql` is represented in the production inventory and vice
  versa, and every canonical definition normalizes equal to the schema text;
- damaged v7 catalogs are rejected on open: missing baseline index, missing
  baseline trigger, missing v7 collision guard, and same-name substituted
  safety triggers (baseline and v7) fail with `schemaStateInvalid`.

## 6. UX tests

- keyboard-only tree navigation;
- VoiceOver labels;
- next-difference navigation;
- large text settings;
- clear distinction between online and offline items;
- clear distinction between Metadata Match and content verification.

## 7. Snapshot Collections tests

Full semantics in [`SNAPSHOT_COLLECTIONS.md`](SNAPSHOT_COLLECTIONS.md); schema-level fixtures exercised in `database/verify.sql`. Planned automated tests:

- create a Collection;
- reject a blank Collection name;
- reject a normalized duplicate Collection name (e.g. `xyz` after `XYZ` exists);
- rename a Collection and confirm its `id` (and every snapshot's `collection_id`) is unaffected;
- delete a Collection without deleting any snapshot inside it;
- confirm deleting a Collection moves its snapshots to `Unsorted` (`collection_id = NULL`), not to any other Collection;
- confirm deleting a Collection removes any `source_collection_defaults` row pointing at it;
- create a snapshot with a Collection assigned;
- create a snapshot with no Collection (`Unsorted`);
- reject a blank snapshot display name;
- rename a snapshot's display name and confirm its `entries`, aggregates, and capture timestamps are byte-for-byte unchanged;
- move a snapshot between Collections and confirm the same;
- save a source default;
- replace a source default (same source, new Collection — upsert, not a second row);
- remove a source default;
- confirm two distinct sources with the same display name never collide on a shared default (keyed by `volume_id`, never a name);
- confirm a manual capture's organization sheet preselects the remembered default for the exact source, per the Section 5.1 waterfall;
- confirm an automatic capture uses the remembered default when one exists;
- confirm an automatic capture falls back to `Unsorted` when none exists, and is never blocked or delayed by the absence of one;
- confirm a snapshot search result surfaces its Collection (or `Unsorted`) alongside the match;
- apply `database/schema.sql` to a fresh database and confirm `PRAGMA integrity_check`/`PRAGMA foreign_key_check` are both clean, with **schema version 8** recorded in `schema_migrations`. A fresh database records only the current version; a database migrated from version 4 records 4, 5, 6, 7 and 8.

## 8. Consolidated manual acceptance

Added 2026-08-04 by independent audit. **Manual testing is not required after every implementation task.** Automated checks own everything they can prove; manual sessions exist only for what a human must judge — physical media behavior, UI responsiveness under real load, and end-to-end product feel.

There are exactly **two** manual sessions in the MVP.

### Manual Session A — First end-to-end capture (run at the end of Milestone 2)

Purpose: confirm that FSD captures real data from a real source, never modifies that source, and never presents an interrupted capture as complete. This is the first point where a human can meaningfully exercise FSD.

Setup: a writable USB or external drive with a known folder tree (a few thousand files, including at least one Unicode name and one deeply nested branch), plus a local control folder. Take a full `find`-based listing with sizes and timestamps before starting.

| # | Test | Steps | Expected result | Evidence to capture | Blocks MVP acceptance |
|---|---|---|---|---|---|
| A1 | Launch | Open FSD on Apple Silicon | App launches; catalog database is created; no crash, no permission surprise | Screenshot of first-run window; database file path | Yes |
| A2 | Capture a controlled folder | Select the local control folder; run a capture to completion | Snapshot reaches `complete`; file/folder/byte totals match the pre-capture listing | Totals screenshot; diff of the two listings | Yes |
| A3 | Source unchanged | Re-run the `find` listing on the source after capture; compare to baseline | Byte-identical listing — no new files, no changed timestamps, no marker or index written to the source | Both listings and their `diff` (must be empty) | **Yes — hard gate** |
| A4 | Interrupt a scan | Start a capture of the external drive; physically disconnect it mid-scan | App stays responsive; snapshot becomes `interrupted`, never `complete` | Screenshot of snapshot status; app remains usable | **Yes — hard gate** |
| A5 | Relaunch after interruption | Quit and relaunch FSD | Interrupted snapshot is still marked interrupted; it is not offered as the default view; a previous complete snapshot (if any) remains the default | Screenshot of history list | **Yes — hard gate** |
| A6 | Force-quit during capture | Start a capture; force-quit the app mid-scan; relaunch | Stale `scanning` snapshot is reconciled to `interrupted` at launch; database integrity check passes; no partial snapshot claims completeness | Launch log; `PRAGMA integrity_check` output | Yes |

### 8.1 Manual Session A status — NOT PERFORMED, DEFERRED BY OWNER

Recorded 2026-08-04. Manual Session A was attempted during the Milestone 2 acceptance audit and its hard gates could not be corroborated; the project owner directed that they be recorded as not performed. It is **pending, not failed**, and it is not re-attempted: per `AGENT.md` § Deferred Manual Testing Rule, no manual step is requested until the owner states that manual testing is available. It will then run once, consolidated, rather than being repeated after each task.

Milestone 3 replaced the evidence-settleable part of the session with automated and Agent-run checks. What each gate's status actually is:

| # | Gate | Status | Evidence |
|---|---|---|---|
| A1 | Launch | **AGENT-OBSERVED** (process), **NOT PERFORMED** (appearance) | The built app was launched against an isolated `/tmp` catalog; it created the catalog at schema version 5, took its process lock, and printed its resolved catalog path. Nobody looked at the window. |
| A2 | Capture a controlled folder | **AUTOMATED VERIFIED** | `ManualSessionASubstituteTests.testControlledFixtureCaptureReachesCompleteWithMatchingTotals` — capture through `SnapshotScanner` reaches `complete` with file/folder totals matching an independent enumeration. |
| A3 | Source unchanged | **AUTOMATED VERIFIED** | `testCaptureLeavesTheSourceByteForByteUnchanged` — full listing, sizes, modification dates and test-only SHA-256 per file, identical before and after. Independently, five disk images were captured with the image file's SHA-256 identical before and after (`FILESYSTEM_SUPPORT_MATRIX.md` §2.1). |
| A4 | Interrupt a scan | **AUTOMATED VERIFIED** (cancellation), **NOT PERFORMED** (physical disconnect) | `testCancellationNeverProducesACompleteSnapshot`. Physically disconnecting a drive mid-scan cannot be automated and remains for the owner. |
| A5 | Relaunch after interruption | **AUTOMATED VERIFIED** | `testRelaunchAgainstTheSameCatalogPreservesRecordedState` — a fresh connection to the same catalog shows exactly the recorded state, with no resurrected capture. |
| A6 | Force-quit during capture | **AUTOMATED VERIFIED** and **AGENT-OBSERVED** | `testOrphanedScanIsRecoveredOnTheNextStartup`, plus a runtime probe: an orphaned `scanning` row was written into an isolated catalog, the real app was launched against it, and the row came back `interrupted` with the recovery scan issue recorded and `integrity_check` = `ok`. |
| — | GUI interaction (menus, panels, buttons, on-screen wording) | **NOT PERFORMED — DEFERRED BY OWNER** | No XCUITest target exists. Not falsified as passing. |

None of the above is manual acceptance. Manual Session A stays open until the project owner performs it.

### Manual Session B — Consolidated MVP acceptance (run at the end of Milestone 5)

**Status: NOT PERFORMED — DEFERRED BY OWNER.** Prepared 2026-08-04 as the
single consolidated future manual acceptance session (Milestone 5 closeout).
It replaces the older B1–B11 table with one session covering launch,
navigation, capture, cancellation, relaunch/recovery, history, offline
browsing/search/export, all three comparison modes, filters, next/previous
navigation, uncertainty wording, disposal, visual layout, keyboard behavior,
VoiceOver basics and filesystem sampling. It will run once, after Milestone
5's automated work is green, when the project owner declares manual testing
available. Every step below lists setup, exact action, expected visible
result, evidence to record, cleanup and its mapping to canonical test IDs.

Session-level setup:
- Two captured snapshots of the same source taken at different times with a
  known small set of differences (one added file, one removed file, one
  resized file) — M3/M13 fixture (`A2`, `B5`).
- One large fixture (≥ 1,000,000 entries) captured — M11 fixture (`B3`).
- The source drive physically ejected after capture — M9/M10 fixture
  (`B1`, `B2`).
- A controlled local folder with known totals for capture tests — M3/M4
  fixture (`A2`, `A3`).
- Host-capable generated images for filesystem sampling — M25 fixture
  (`FILESYSTEM_SUPPORT_MATRIX.md` §2.1; stock NTFS remains environment-blocked).

| # | Focus | Setup | Exact action | Expected visible result | Evidence to record | Cleanup | Maps to |
|---|---|---|---|---|---|---|---|
| M1 | Launch | None | Launch FSD on Apple Silicon | App launches; catalog is created; no crash, no permission surprise | Screenshot of first-run window; catalog path | Quit app | A1 |
| M2 | Navigation | App running | Click Snapshots / Capture / Compare in the sidebar | All three destinations render; no error states | Screenshot per destination | None | A1 |
| M3 | Capture | Controlled local folder with known totals | Capture → Choose Source → the folder → Start Metadata Capture | Snapshot reaches Complete; totals match the pre-capture listing; "Metadata only. Content Not Verified." visible | Totals screenshot; diff of listings | None | A2 |
| M4 | Source unchanged | Same folder as M3 | Re-run the pre-capture listing after M3 | Byte-identical listing — no new files, no changed timestamps, no marker written | Both listings and their diff (must be empty) | None | A3 (hard) |
| M5 | Capture cancellation | A large folder | Start a capture; press Cancel mid-scan | App stays responsive; snapshot becomes Cancelled, never Complete | Screenshot of status | None | A4 |
| M6 | Relaunch after interruption | Capture cancelled in M5 | Quit and relaunch FSD | The cancelled snapshot is still marked so; not offered as default view; a previous complete snapshot remains default | Screenshot of history list | None | A5 (hard) |
| M7 | Force-quit during capture | A large folder | Start capture; force-quit mid-scan; relaunch | Stale scanning snapshot reconciled to Interrupted at launch; integrity passes; no partial snapshot claims completeness | Launch log; `PRAGMA integrity_check` output | None | A6 |
| M8 | History | ≥ 2 snapshots captured | Review the capture history | Timestamp, duration, status and totals shown; Complete / Interrupted / Cancelled visually distinct; no snapshot silently overwritten | Screenshot | None | B4 |
| M9 | Offline browsing | Source ejected | Open the last complete snapshot; expand several top-level folders | All stored metadata available; items visibly marked offline; nothing hangs waiting on the missing mount | Screen recording with drive absent | None | B1 (hard) |
| M10 | Offline search | Source still ejected | Search by file name and by relative path | Results return and navigate to the virtual entry; Collection context shown | Screenshot of results | None | B2 |
| M11 | Large-tree navigation | ≥1M-entry snapshot | Open the large snapshot; expand and scroll several branches | Tree opens promptly without loading all rows; scrolling usable; memory bounded | Screen recording plus peak-memory reading | None | B3 (hard) |
| M12 | JSON export | Any complete snapshot | Export the snapshot to JSON | File written; metadata only; disclaimer present; opens in a text editor | The exported file | Delete the export | B10 (JSON part) |
| M13 | Snapshot-to-snapshot compare | The two prepared snapshots | Compare → both snapshots → run | Summary shows exact counts; the added/removed/changed entries are found and correctly classified | Screenshot of each classification | Dispose comparison | B5 (hard) |
| M14 | Live-to-snapshot compare | Source reconnected | Compare live folder vs. its snapshot | Live side captured as a transient; excluded from user history; cleaned up on close | Screenshot; history list showing no transient | Close workspace | B6 |
| M15 | Live-to-live compare | Two live folders | Compare two live folders | Both captured as transients; comparison completes; both cleaned up on close | Screenshot; history list | Close workspace | B6 |
| M16 | Filters | An open comparison | Differences-only mode; per-outcome filters (Added / Removed / Changed / Conflicts / Ignored) | Each filter shows only its outcome; counts match the summary | Screenshot per filter | None | B5 |
| M17 | Next/previous navigation | A comparison with >1 page of differences | Press next/previous difference controls across page boundaries | Navigation moves to the adjacent difference; page boundary works; first/last disable at the ends | Screen recording | None | B5 |
| M18 | Uncertainty wording | A comparison with collisions or inaccessible items | Open the Conflicts filter; inspect wording | Uncertain rows say "Uncertain — no deterministic conclusion"; never presented as added/removed/matched | Screenshot | None | B7 (hard) |
| M19 | Content-not-verified language | Comparison UI and export | Inspect the summary panel and the export header | "Content Not Verified" stated explicitly; no wording implies checksum, bit-identical, or verified-copy semantics | Screenshot of summary panel | None | B7 (hard) |
| M20 | Disposal | A live comparison workspace | Close the workspace; then delete a persisted comparison with confirmation | Live comparison and its transients gone; persisted comparison disposed; snapshots remain | Screenshots before/after | None | B6, KI-017 |
| M21 | Partial and error states | A snapshot captured with inaccessible items; one interrupted snapshot | Open both | Inaccessible items and scan issues visible and bounded; partial snapshots clearly labeled | Screenshot | None | B8 |
| M22 | Visual layout | App running, all destinations | Inspect spacing, sidebar, list rows, outcome pills, empty states | No clipped text, no overlapping controls, consistent spacing | Screenshot per destination | None | — |
| M23 | Keyboard behavior | Comparison destination focused | Navigate the tree and differences with keyboard only (arrows, Tab, shortcuts) | Keyboard navigation works; focus visible | Screen recording | None | B11 |
| M24 | VoiceOver basics | VoiceOver enabled | Enable VoiceOver on status icons and outcome rows | Status icons are labeled; color is not the sole status indicator | Screen recording | Disable VoiceOver | B11 |
| M25 | Filesystem sampling | Host-capable generated images (APFS, APFS-case-sensitive, HFS+, HFSX, FAT16, FAT32, exFAT, UDF) | Capture one representative folder from each mounted image | Capture completes; image byte-identical before and after | Image SHA-256 before/after; screenshots | Detach images | Matrix §1 seven steps |

Note: M3/M4 and M25 exercise real sources. The physical-disconnect variant of
A4 cannot be automated; if the owner has removable media, M5's manual
disconnect step covers it. Stock-macOS NTFS remains
**ENVIRONMENT-BLOCKED — PROVIDER PATH NOT INVALIDATED** and is not part of
M25. HTML export (the HTML part of B10) remains out of MVP scope.

### What manual testing deliberately does not cover

Anything an automated test can prove is not repeated by hand: schema constraints, snapshot lifecycle transitions, diff classification correctness on fixtures, Collection semantics, transient-snapshot cleanup, and per-filesystem fixture enumeration all stay in the automated suites. Physical raw-device and `authopen` behavior is out of MVP scope entirely (`MVP_PLAN.md`, deferred beyond MVP).

## Phase 1.5 nullable classification preparation

Automated Debug and focused Release coverage verifies the schema-v8
entry-classification seam, typed round-trip, deterministic duplicate and
missing-entry rejection, bounded latest-page retrieval, selected-entry browser
presentation, neutral absence, snapshot/entry immutability, hostile-provider
diagnostic suppression, disabled-provider no-op behavior, metadata-only capture
and export, and comparison isolation. Ordinary workflows create zero
classification rows; rows are created only by explicit enrichment tests.
Classification remains excluded from the canonical JSON export and comparison
semantics. Magika inference is **not active**: no model, dependency, network,
automatic payload read or old-snapshot backfill exists.

Phase 1.5 execution evidence: fresh Debug full suite **293 executed, 290
passed, 0 failed, 3 skipped**; focused Release classification/history/safety
suite **60 executed, 60 passed, 0 failed, 0 skipped** with testability enabled
only for the test host. Fresh Debug and Release application builds both passed
as arm64. The existing final-scale Debug suite also observed one-million
automatic workspace close in 11.398 s and explicit disposal in 11.322 s; this
slice did not change comparison, schema or lifecycle behavior, so no separate
Release one-million campaign was rerun.

Manual-only visual and owner acceptance remains **NOT PERFORMED — DEFERRED BY
OWNER**. The next action is one independent Codex focused audit of the Phase
1.5 nullable Magika enrichment boundary.

## 9. Future Magika runtime adapter test plan (not yet implemented)

- exact byte ceiling enforcement (4096 bytes)
- exact byte boundary (a file of exactly the ceiling size vs. one byte over)
- small file (below the ceiling)
- oversized file (above the ceiling)
- missing source at classification time
- source that disappears mid-read
- source that has changed identity since capture
- wrong/mismatched source identity
- inaccessible source (permission denied)
- directory entry rejection
- symlink entry rejection
- special-file entry rejection
- cancellation before the read begins
- cancellation during the read
- cancellation before inference
- cancellation during inference
- provider failure/crash
- provider timeout
- successful classification persists correctly
- cancellation cannot create a successful row
- no payload persistence
- no byte-sample persistence
- no content-hash persistence
- no absolute-source-path persistence
- no snapshot mutation (`entries`/`snapshots` unchanged by a classification write)
- comparison isolation (divergent classification metadata does not change comparison outcomes — extending the existing `ComparisonSemanticsTests.testClassificationMetadataCannotChangeComparisonOutcome` in `FSDTests/ComparisonSemanticsTests.swift`)
- JSON export stability (export excludes classification, unchanged format version)
- zero network activity during classification
- no automatic invocation (capture, application launch, history open, snapshot reopen, browsing, search, comparison, JSON export)
- offline history/snapshot usability (classification of a detached-source entry behaves per the `.source-changed`/`.unavailable` rule, not by crashing or hanging)
- schema/`ExpectedState` safety when the provider identity schema change is implemented

### Adversarial Provider Test

Verify that a provider cannot escape FSD's bounded-byte authority using a fake/hostile provider implementation (analogous to `FSDTests/ClassificationEnrichmentTests.swift`'s existing `HostileDiagnosticProvider`). The fake provider must attempt all three of the following violations deliberately, and the test passes only if all three attempts fail to have any effect:
1. Attempt to reopen or otherwise access the original source path. The provider only ever receives the bounded `Data` buffer FSD already read, never a `URL`/path/handle.
2. Attempt to request or receive additional bytes beyond what FSD already handed it. There is no callback or second read path available to it.
3. Attempt to bypass FSD's hard byte ceiling. Even if the fake provider's `classify` implementation tries to claim it read more, FSD's own persisted result only ever reflects what FSD itself bounded and read, never anything the provider asserts about additional bytes.
