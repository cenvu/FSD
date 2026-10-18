# Test Plan

## Current acceptance gates (authority reconciliation 2026-10-18)

M1–M5 technical core and the schema-v8/disposal/nullable preparation audits remain
closed with their recorded conditions. Phase 1.5 runtime has final BRAIN technical
acceptance with advisory after Task036; schema is **v9**, not v8. Historical
Task035 full Debug evidence is 494 executed / 491 passed / 0 failed / 3 known
external-environment skips; the final Task036 focused audit is 260/260. See
[STATE/PROJECT_STATE.md](../STATE/PROJECT_STATE.md) and
[Task036 audit](../handoffs/FSD_P15_RUNTIME_FINAL_AUDIT_R_20261007-094654.md).
These product tests were not rerun by Task054. Manual UI, VoiceOver,
physical-media and full FSD2 internal acceptance remain separate/pending;
Developer ID/notarization are not current internal-acceptance gates.
ADR-036–038 remain Proposed / Owner Direction Approved / Technical Proof Pending.
Task054 adds only the §10 research/synthetic evidence and future physical gates;
no observer, identity integration, production/schema tests or later task ran.

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

The following is historical preparation-stage evidence. Its inactive-runtime
statements describe that milestone; current Task036 technical acceptance and
schema-v9 runtime status are recorded above and in §9. Counts remain unchanged.

Automated Debug and focused Release coverage verifies the schema-v8
entry-classification seam, typed round-trip, deterministic duplicate and
missing-entry rejection, bounded latest-page retrieval, selected-entry browser
presentation, neutral absence, snapshot/entry immutability, hostile-provider
diagnostic suppression, disabled-provider no-op behavior, metadata-only capture
and export, and comparison isolation. Ordinary workflows create zero
classification rows; rows are created only by explicit enrichment tests.
Classification remains excluded from the canonical JSON export and comparison
semantics. Local classifier inference is **not active**: no model, dependency, network,
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
OWNER**. The preparation-stage next action was one independent Codex focused
audit of the Phase 1.5 nullable Magika enrichment boundary.

**Closure amendment (2026-08-07): that audit is CLOSED — APPROVE WITH CONDITIONS**
(`handoffs/FSD_P15_MAGIKA_NULLABLE_ENRICHMENT_AUDIT_R_20260807-142313.md`).
It independently reproduced the full Debug suite (293 executed, 290 passed,
0 failed, 3 skipped) and its selected focused Release suites (59 executed,
59 passed, 0 failed, 0 skipped). The Writer's 60-test Release selection above
and the Auditor's 59-test selection are distinct historical runs, not counts
to merge. Deferred manual acceptance and inactive runtime remain unchanged.

## 9. Local classifier runtime test plan (Task036 final BRAIN technical acceptance with advisory)

The binding classifier requirements below cover the **seven typed
outcomes** locked by ADR-034 (2026-10-06, Accepted): `classified`, `failed`,
`sourceChanged`, `unsupportedEntry`, `unavailable`, `cancelled`, `noMatch`.
`busy` remains runtime control state, is not a provider-result case and writes no
row. `ROW_WRITING_OUTCOMES=4` and `NO_ROW_TYPED_OUTCOMES=3`. Historical completed
test receipts earlier in this plan describe earlier milestones and are not
rewritten. **`ADR-034 IMPLEMENTATION=ACCEPTED_TASK031`**: the ADR-034 noMatch implementation requirements in the dedicated subsection below were implemented and accepted by task031 at `de8484e203b8b6e259dac90349d44069fc5a6ed0`; accepted earlier Slice02–06/task031 test receipts remain historical evidence; ADR-035 integration was implemented by task033A and independently audited by task034; BRAIN accepted filetype v1.1.3 as production provider in the supplied task035 decision. The requirements below remain unchanged.

**Current task035 evidence (AUTOMATED VERIFIED):** Task035 current verification: clean Debug/Release arm64 builds passed; full Debug 494 executed / 491 passed / 0 failed / 3 existing external-probe skips; focused classification/isolation/schema 242 executed / 242 passed / 0 failed / 0 skipped; supplemental schema-safety 18 executed / 18 passed / 0 failed / 0 skipped. Exact commands, durations and per-suite counts: [FSD_P15_WHOLE_RUNTIME_VERIFICATION_D_20261007-015634.md](../handoffs/FSD_P15_WHOLE_RUNTIME_VERIFICATION_D_20261007-015634.md). filetype v1.1.3 is the BRAIN-accepted production provider; ADR-035 integration is implemented by task033A (`556872844b90640cc2a64e40d99594a78cef61af`) and independently audited by task034 (accepted `PASS_WITH_ADVISORY` at publication `9d1a8ea237c6c2941895b1c3640118371d2e2d4d`). Task035 verified the runtime; Task036 subsequently completed the independent final audit and BRAIN accepted Phase 1.5 with advisory (accepted State and Task036 audit above). These counts remain historical evidence; Task054 did not rerun them.

The focused run includes the eight classification suites, ComparisonSemanticsTests, JSONExportTests and SchemaMigrationTests/CatalogDatabaseTests; the supplemental schema-safety run explicitly selects ExpectedStateInventoryTests and TerminalCollisionEvidenceTests declared in SchemaSafetyCorrectionTests.swift. The ineffective file-named selector in the first focused command selected zero tests; it is not counted as coverage. All mandatory real-helper cases reran against the accepted committed helper; missing helper is failure, not skip. Full-suite skips are only FSDProbeSeedTests/testSeedIsolatedProbeCatalog (`FSD_PROBE_CATALOG` absent), FilesystemMatrixTests/testCaptureExternallyPreparedMountedFilesystem (`FSD_MATRIX_SOURCE` absent) and testReopenCapturedSnapshotWithTheSourceDetached (`FSD_MATRIX_OFFLINE_CATALOG` absent); none hides classifier coverage. The current full run also repeats the previously disclosed test-sampler QoS diagnostic at M5PeakSampler.stop; the related test passes and no repair is claimed.

**AGENT-OBSERVED:** six current actual-helper PNG runs had zero sockets/descendants. Both fresh unsigned bundles match helper SHA256 `665a6569ee60614313e50629c4166358b89859f15dac4c522905ee5a730752e7`, arm64/minos 13.0, exact notices and no Go/module/model/database artifacts; scratch Release ad-hoc copy passes deep/strict verification. Detector `github.com/h2non/filetype@v1.1.3`, provider `fsd.bundled-helper-host.v1`, nil model/confidence are verified at the provider/mapping/repository boundaries. No Go command or controlled rebuild was run by task035; historical task033A/task034 reproducibility, dependency/notice inventories remain accepted historical evidence.

General realistic legacy DOC/XLS/PPT determinism remains unproven.
Available pinned realistic PNG/DOCX/XLSX/PPTX bounded fixtures were single-valued in accepted implementation/audit evidence.
The demonstrated short legacy-CFB ambiguity is neutralized by the guard.

**INFERRED:** observed offline behavior is corroborated by the accepted artifact hash and audited static API/dependency closure; bounded observations do not prove universal determinism or every future schedule. **MANUAL NOT PERFORMED:** **NOT PERFORMED — DEFERRED BY OWNER**; automated/agent evidence does not replace visual UI, VoiceOver or physical-media acceptance. No final Phase 1.5 BRAIN acceptance, Developer ID, notarization or App Store readiness is claimed.

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

### Required `noMatch` outcome tests (ADR-034)

These became permanent requirements and were implemented/accepted by task031 at `de8484e203b8b6e259dac90349d44069fc5a6ed0` (not in the ADR-034 canonicalization task):

- the provider enum exposes a `noMatch` case
- the helper parser maps `resultKind="no_match"` to `.noMatch`
- `no_match` requires all of `detectedType`, `mimeType`, `confidence`, `detectorVersion`, `modelVersion` to be null
- `no_match` carrying any non-null metadata field is rejected (`.failed`)
- an unknown/other wire result kind still fails (no silent fallback to `noMatch`)
- runtime `noMatch` writes zero `entry_classifications` rows
- `noMatch` never mints, infers or fabricates a detected type
- `noMatch` stores no provider identifier, detector version or model version
- provider timeout remains `.failed`, never `noMatch`
- a missing helper remains `.unavailable`, never `noMatch`
- cancellation remains `.cancelled`, never `noMatch`
- `busy` remains control-only and is not a provider-result case
- a zero-byte eligible regular file may truthfully return `noMatch` and is not
  reclassified as source unavailable merely because it is empty
- persistent inspector classification details remain "Not classified" when no
  row exists
- the current explicit action may show a bounded neutral no-match message for a
  current `noMatch` completion; it is not an error and shows no detected type
- a stale `noMatch` completion cannot alter the new selection or browser

### Required filetype v1.1.3 real-helper integration and audit tests (ADR-035)

Implemented by task033A, independently audited by task034, BRAIN-accepted production provider, and rerun by task035 (`INTEGRATION=IMPLEMENTED`, `INDEPENDENTLY_AUDITED`). These remain required cases; historical counts above are not rewritten. Full contract: `docs/CLASSIFIER_FILETYPE_INTEGRATION_CONTRACT.md`
sections 19-22. All run the actual committed helper (directly and through the Swift host
seam); no fake-runner result substitutes, and a missing helper fails rather than skips.

- known PNG classified; unknown bytes `no_match`; empty input `no_match`
- exact 4096 bytes bounded and processed; 4097 bytes rejected before `Match`
- short-CFB advisory regression (prefix `D0 CF 11 E0`, lengths 4, 32 and 513): all
  deterministic `no_match` across fresh helper launches, zero `Match` calls. **This
  regression must never be deleted or weakened because it looks like an odd synthetic
  edge: it guards a demonstrated real upstream map-order nondeterminism.**
- synthetic CFB of length 514 or more: DOC discriminant -> `doc`, XLS -> `xls`,
  PPT -> `ppt`; a non-matching 514+ CFB probe must be single-valued across launches
  (else STOP); no general legacy DOC/XLS/PPT fixture claim
- available pinned DOCX, XLSX, PPTX and PNG fixtures each repeated across fresh helper
  launches and single-valued
- strict seven-field envelope; stdout cap; stderr cap; zero network observation; zero
  descendants; normal exit; crash; SIGTERM/cancellation; five-second host timeout
- no stale publication; no row for `noMatch`; exact `detectorVersion`
  (`github.com/h2non/filetype@v1.1.3`); `modelVersion` nil; `confidence` nil;
  source/path authority absent; sample persistence absent
- built bundle: helper exactly at `Contents/Helpers/FSDClassificationHostSeam`, arm64,
  `minos` at most 15, manifest/hash correspondence for the unsigned artifact, notice
  resource present, no Go toolchain/cache/module source/model/database, no unexpected
  executable; ad-hoc signing/package inspection of a scratch copy (no Developer
  ID/notarization claim)
- full validation: clean Debug, focused real-helper tests, existing classification
  focused tests, full Debug suite, clean Release, `git diff --check`, canonical checker
- independent audit `FSD_CLASSIFIER_FILETYPE_INTEGRATION_AUDIT_034` is mandatory before
  Slice 08

### Adversarial Provider Test

Verify that a provider cannot escape FSD's bounded-byte authority using a fake/hostile provider implementation (analogous to `FSDTests/ClassificationEnrichmentTests.swift`'s existing `HostileDiagnosticProvider`). The fake provider must attempt all three of the following violations deliberately, and the test passes only if all three attempts fail to have any effect:
1. Attempt to reopen or otherwise access the original source path. The provider only ever receives the bounded `Data` buffer FSD already read, never a `URL`/path/handle.
2. Attempt to request or receive additional bytes beyond what FSD already handed it. There is no callback or second read path available to it.
3. Attempt to bypass FSD's hard byte ceiling. Even if the fake provider's `classify` implementation tries to claim it read more, FSD's own persisted result only ever reflects what FSD itself bounded and read, never anything the provider asserts about additional bytes.

## 10. ADR-036 identity feasibility and proof gates — Task054

**Task054 boundary:** public API/SDK research, pure generated-fact resolver in
ignored `.ai-scratch/task054/`, and documentation only. No live device enumeration,
Owner media/catalog/filesystem-root reads, mount/unmount/eject, observer execution,
Xcode build or production XCTest. ADR-036 remains Proposed / Owner Direction
Approved / Technical Proof Pending. See [architecture §11](ARCHITECTURE.md#11-physical-drive-identity-feasibility--task054)
for E1–E8 official URLs, exact declarations, provenance dependencies, schema-v9
source findings and future migration plan; [ADR-036](DECISIONS.md#adr-036--physical-drive-identity-and-mount-policy-wave-a-candidate)
for deterministic outcome precedence and actions.

Proof labels are independent dimensions: `DOCUMENTED` means the cited API contract
exists, `SYNTHETICALLY_TESTED` means generated rules executed,
`EMPIRICALLY_VERIFIED` requires designated real-media evidence (none in Task054),
`TECHNICAL_PROOF_PENDING` means a future required gate, and
`UNSUPPORTED_OR_UNKNOWN` means no supported identity claim. Documentation and
synthetic PASS never become empirical verification.

### Synthetic inputs, expected results and receipt

Reproduce locally with `python3 .ai-scratch/task054/resolver.py`. Standard library
only; `inputs.json` includes every explicit observation, catalog, options and
expected full result; `results.json` records each actual result. The historical
Task054 handoff embeds the complete runnable harness for recovery because ignored
scratch is not published. Run the recovered file under the same ignored directory.
No filesystem-source strings in the fixtures are dereferenced.

Notation: `a/b` are generated device tokens with explicit separate origins A/B;
`u` is generated volume UUID U. Names, paths, BSD nodes and reader serials are
nonidentity facts. **Pending** is the real profile set (empty); **hypothetical**
is an explicitly synthetic two-device-origin profile, with no mapping to real
Apple keys and no accepted hardware threshold. Candidate IDs D1/D2 are local
synthetic records. All cases check exact outcome, target, candidate set and Auto
Capture eligibility, input immutability and reversed fact/candidate order.

Command executed successfully: **32 cases / 32 PASS / 0 FAIL**. Per-case expected
and actual outcomes follow; only S21 has `auto=True`, under the hypothetical
profile with opt-in, availability, root proof, separate capture authorization and
idle state. Every other case has `auto=False`.

| Case | Generated scenario | Expected | Actual | Profile / target |
|---|---|---|---|---|
| S01 | same name different devices | `Unknown` | `Unknown` PASS | pending / none |
| S02 | mount path reused | `Unknown` | `Unknown` PASS | pending / none |
| S03 | BSD node reused | `Unknown` | `Unknown` PASS | pending / none |
| S04 | BSD changes | `Unknown` | `Unknown` PASS | pending / none |
| S05 | missing UUID | `Unknown` | `Unknown` PASS | pending / none |
| S06 | single unverified UUID | `Unknown` | `Unknown` PASS | pending / none |
| S07 | cloned UUID two records | `Ambiguous` | `Ambiguous` PASS | pending / none |
| S08 | split qualified evidence | `Conflict` | `Conflict` PASS | hypothetical / none |
| S09 | partition one of device | `Unknown` | `Unknown` PASS | pending / none |
| S10 | partition two of device | `Unknown` | `Unknown` PASS | pending / none |
| S11 | same reader different cards | `Ambiguous` | `Ambiguous` PASS | pending / none |
| S12 | reader serial only | `Unknown` | `Unknown` PASS | pending / none |
| S13 | reconnect changed path pending | `Unknown` | `Unknown` PASS | pending / none |
| S14 | current revision manual | `ManualAssociation` | `ManualAssociation` PASS | pending / D1 |
| S15 | manual later contradiction | `Conflict` | `Conflict` PASS | hypothetical / none |
| S16 | stale manual revision | `Conflict` | `Conflict` PASS | pending / none |
| S17 | manual correction to another local record | `ManualAssociation` | `ManualAssociation` PASS | pending / D2 |
| S18 | aliases share origin no corroboration | `Unknown` | `Unknown` PASS | hypothetical / none |
| S19 | two device fields real profile pending | `Unknown` | `Unknown` PASS | pending / none |
| S20 | hypothetical strong default OFF | `UniqueStrongMatch` | `UniqueStrongMatch` PASS | hypothetical / D1 |
| S21 | hypothetical strong opt in all gates | `UniqueStrongMatch` | `UniqueStrongMatch` PASS | hypothetical / D1 |
| S22 | hypothetical strong no root authority | `UniqueStrongMatch` | `UniqueStrongMatch` PASS | hypothetical / D1 |
| S23 | hypothetical strong unavailable | `UniqueStrongMatch` | `UniqueStrongMatch` PASS | hypothetical / D1 |
| S24 | hypothetical strong no capture authorization | `UniqueStrongMatch` | `UniqueStrongMatch` PASS | hypothetical / D1 |
| S25 | hypothetical strong duplicate device tokens | `Ambiguous` | `Ambiguous` PASS | hypothetical / none |
| S26 | contradictory aliases same subject | `Conflict` | `Conflict` PASS | pending / none |
| S27 | unknown lineage not qualified | `Unknown` | `Unknown` PASS | hypothetical / none |
| S28 | unknown no association even opted in | `Unknown` | `Unknown` PASS | pending / none |
| S29 | hypothetical reconnect changed BSD path | `UniqueStrongMatch` | `UniqueStrongMatch` PASS | hypothetical / D1 |
| S30 | hypothetical qualified mismatch | `Conflict` | `Conflict` PASS | hypothetical / none |
| S31 | hypothetical strong busy | `UniqueStrongMatch` | `UniqueStrongMatch` PASS | hypothetical / D1 |
| S32 | manual missing target | `Conflict` | `Conflict` PASS | pending / none |

S09/S10 preserve distinct partition UUIDs under one generated device; they do not
prove topology discovery. S14/S17 exercise explicit local choice/correction;
S15's later contradiction is qualified only under the hypothetical profile.
S18 proves same-origin aliases cannot supply independent corroboration. S19
keeps real-profile strong matching disabled despite matching two strings.
The prototype does not implement persisted collision quarantine, parsing of
untrusted API types, topology discovery, observation lifecycle or manual-event
storage. Those are specified future gates, not synthetic execution claims.
Synthetic tests do not prove API callback ordering, no-write syscall behavior,
SDK/runtime compatibility, actual UUID/serial availability, schema migration,
UI confirmation or hardware uniqueness. Case output is `SYNTHETICALLY_TESTED`;
physical identity and automatic-action integration are `TECHNICAL_PROOF_PENDING`.

### Future designated-media validation matrix

**Not authorized/executed here.** Every row requires a separate explicit,
safety-scoped authorization identifying disposable/designated test media,
allowed metadata-only observation and any permitted manual remount/restart.
No source write, marker, payload read, clone/reformat operation or destructive
preparation is implied. Prepare cloned/missing-ID fixtures only under separate
explicit authority. Use pseudonymous media labels and local bounded evidence.

| ID | Coverage / future observation | DOCUMENTED basis | SYNTHETICALLY_TESTED | EMPIRICALLY_VERIFIED | Remaining disposition |
|---|---|---|---|---|---|
| H01 | APFS removable SSD/HDD; multiple volumes/container/stores and physical backing | E1–E5 expose objects/keys, not guaranteed APFS-to-device mapping | S09–10 generic partitions only | NO | TECHNICAL_PROOF_PENDING; multi-store mapping UNSUPPORTED_OR_UNKNOWN |
| H02 | HFS+ removable volumes; mounted/unmounted UUID exposure | E2/E3/E8 optional/persistent properties | S05–07 | NO | TECHNICAL_PROOF_PENDING |
| H03 | exFAT and FAT32 cards/drives; absent/repeated identifiers | E2/E3 optional keys; no per-format strong-ID guarantee | S05–07/S18 | NO | TECHNICAL_PROOF_PENDING; do not infer FAT variant from `msdos` |
| H04 | NTFS through each explicitly supported/read-only provider and other supported provider paths | E2/E8 do not certify provider support or identity | S05/S19 generic missing/provisional | NO | UNSUPPORTED_OR_UNKNOWN for unvalidated providers; stock-macOS NTFS support remains unproven |
| H05 | USB SSD and HDD, same/different ports/hubs/cables | E2 device/bus path; E6 driver serial property | S01–04/S13/S29 | NO | TECHNICAL_PROOF_PENDING; reconnect/port stability unproven |
| H06 | SD and CFexpress cards, swap in one reader; same card in different readers | E1 explicitly warns to vary devices/card readers; E6 does not prove medium serial exposure | S11–12/S18 | NO | TECHNICAL_PROOF_PENDING; reader vs card subject unresolved |
| H07 | Several partitions on one physical test drive; volume vs partition UUID and offsets | E2 associated whole disk; E3 whole/leaf/base/size | S09–10 | NO | TECHNICAL_PROOF_PENDING; preserve distinct volume records |
| H08 | Same disk through different USB bridges/enclosures; two identical bridges | E4 ancestor GUID derivation/E6 serial subject; no cross-enclosure promise | S11–12/S18/S27 | NO | TECHNICAL_PROOF_PENDING; no inferred bridge pass-through |
| H09 | Multi-LUN bridge/reader, simultaneous media, virtual/RAID/disk image/network exceptions | E5 topology can have multiple parents; no one-device mapping guarantee | S08/S25 generic collision only | NO | UNSUPPORTED_OR_UNKNOWN until bounded topology profile proved |
| H10 | Preprepared cloned UUIDs, duplicated serials and absent keys; offline collision candidates retained | E2/E3 availability limits; collision handling is FSD policy | S05–08/S25–27 | NO | TECHNICAL_PROOF_PENDING; never accept single database hit as uniqueness proof |
| H11 | Remount, disconnect/reconnect, changed name/path/BSD, OS restart and observer restart | E1 ordering warning; E5/E8 restart limits; E7 mount hints | S01–04/S13/S16/S29 | NO | TECHNICAL_PROOF_PENDING; per-OS generation/recovery tests required |
| H12 | Two devices with same name, path reuse and node reuse, both online and sequentially offline | E2/E7 fields describe current presentation/node | S01–04/S07/S25 | NO | TECHNICAL_PROOF_PENDING; false association count must be zero |
| H13 | Manual choice/correction; contradictory later observation, detach during confirmation/admission | E1 events; local decision/revision gates are FSD design | S14–17/S26/S32 | NO | TECHNICAL_PROOF_PENDING for UI, persistence and recovery |
| H14 | Auto Capture OFF/reset, opt-in, mount-only, ambiguous/unknown/conflict/manual and all admission gates | E1/E7 events grant no FSD capture authority | S07/S14/S19–25/S28/S31 | NO | TECHNICAL_PROOF_PENDING for production observer/capture isolation |

For each approved row, record OS/build, provider/version, filesystem, designated
media/reader/enclosure/firmware labels, exact typed key presence/types/origins,
whole/partition relationship, sequence/revision and resolver/profile version.
Compare multiple reconnects, changed ports/readers and restart; test two similar
subjects concurrently and sequentially, including offline stored candidates.
Report missing values/errors and contradictory changes. Sample counts and
retained local evidence must be explicit; a finite run cannot prove universal
uniqueness or resistance to intentionally forged IDs. No empirical columns may
be filled from documentation or inference. The operator must separately approve
the safe test procedure/media before any observation runs.

### Future implementation, migration and safety gates

Traceability: PRD §§5.1/6.1/7 → UX §§8–9 → ADR-036 → architecture §11 →
S01–S32 / H01–H14. PRD remains read-only; its §2 Drive Set and §6.1 raw-provider
wording are advisories, not accepted physical-identity evidence. ADR-037/038
statuses and their implementation gates remain unchanged.

Future production gates, **not executed**: observation-only API allowlist and
no payload/mount/eject/claim/approval action; bounded ancestry and event reducer;
duplicate/late/startup/shutdown callbacks; stale revision rejection; typed
UUID/serial normalization and shared-origin collapse; default-OFF/reset and
revoked opt-in; root authority recheck on admission; cancellation/interruption
and last-complete preservation (CT-001/002/003); schema-v9 additive migration,
FK/integrity, crash/rollback/reopen and tombstone tests; immutable capture facts
and retrospective annotation separation; no legacy UUID/path backfill; bounded
candidate/history query memory. The exact storage/transaction/deletion design
and staged future implementation are in architecture §11. No PhysicalDrive
schema, migration, product test, observer or Auto Capture integration is accepted
or authorized by this feasibility PASS.

## 11. ADR-037 Drive Sets SQLite feasibility — Task055

**SYNTHETIC_PROTOTYPE; 2026-10-18.** No production schema/migration/test, Swift,
UI, source catalog or device access. [ADR-037](DECISIONS.md#adr-037--drive-sets-vs-snapshot-collections-wave-a-candidate)
remains Proposed / Owner Direction Approved / Technical Proof Pending. See
[architecture §12](ARCHITECTURE.md#12-drive-sets-relational-feasibility--task055)
for official SQLite Q1–Q7 sources, candidate keys/DDL/deletion graph, normalization
alternatives, concurrency and additive migration plan. ADR-019/020/036/038 and
accepted history remain unchanged; real strong hardware profiles remain empty.

### Executed inputs, expectations and actual results

Command: `python3 .ai-scratch/task055/harness.py` from the repository root.
Python standard-library sqlite3; every connection is `:memory:` and asserts
`PRAGMA foreign_keys=ON` outside a transaction. Reads only repository schema
text, creates generated v9 rows, and adds proposed DDL in memory. The immutable
Task055 handoff embeds the full runnable source for recovery; generated
`results.json` and initial failure receipt are in ignored `.ai-scratch/task055/`.
No live catalog path is accepted by the harness.

Measured: Python 3.15.0 / SQLite 3.54.0 / Unicode 17.0.0.
**38 executed / 38 PASS / 0 FAIL**, exit 0 after a bounded harness correction:
DS33 first selected the membership-table DDL instead of the reverse-index DDL
while restoring a deliberately dropped index. Initial result 37/38, error
`table drive_set_memberships already exists`; fixed selection by index name,
then all 38 reran. This was test-harness logic, not a product/migration failure.

Each case starts from its own generated v9 memory catalog: two legacy volume
rows with the same synthetic UUID, two complete root snapshots (Collection 1
and NULL Unsorted), entries, a terminal comparison/result and an explicitly
synthetic saved-evidence sentinel. New PhysicalDrives are manually created
unverified stubs. Local IDs are deterministic 32-hex fixtures; names include
Alpha/ALPHA, composed/decomposed Café and Straße/STRASSE. A fixed synthetic time
is used for new facts; the untouched v9 seed has its own SQL timestamps.

After **every** case: compare the complete ordered row values of every legacy
table (excluding the intentionally advanced schema_migrations version) against
its pre-prototype SHA-256; require zero changes, `foreign_key_check=[]`,
`integrity_check=ok` and exact new-object definitions. Setup also checks every
preexisting SQL object definition remains present unchanged. This is semantic
row preservation, not a physical SQLite database-file byte claim. The saved
sentinel proves isolation only, not ADR-038's eventual saved-schema behavior.
String actuals must equal the expected text; DS29 separately asserts full
ordered result equality, uniqueness, page bounds and indexed seek properties.

| Case | Generated action / explicit expected outcome | Actual |
|---|---|---|
| DS01 | empty set created | PASS — empty set created |
| DS02 | two stable set IDs | PASS — two stable set IDs |
| DS03 | many-to-many exact three pairs | PASS — many-to-many exact three pairs |
| DS04 | duplicate PK rejected | PASS — duplicate PK rejected |
| DS05 | missing set FK rejected | PASS — missing set FK rejected |
| DS06 | missing drive FK rejected | PASS — missing drive FK rejected |
| DS07 | rename preserves IDs and membership | PASS — rename preserves IDs and membership |
| DS08 | normalized duplicate rejected | PASS — normalized duplicate rejected |
| DS09 | normalized duplicate rejected | PASS — normalized duplicate rejected |
| DS10 | normalized duplicate rejected | PASS — normalized duplicate rejected |
| DS11 | allow-duplicate alternative permits four; NOCASE misses non-ASCII | PASS — allow-duplicate alternative permits four; NOCASE misses non-ASCII |
| DS12 | membership removed only | PASS — membership removed only |
| DS13 | offline membership retained | PASS — offline membership retained |
| DS14 | Unknown observation admits nothing | PASS — Unknown observation admits nothing |
| DS15 | Ambiguous observation admits nothing | PASS — Ambiguous observation admits nothing |
| DS16 | Conflict observation admits nothing | PASS — Conflict observation admits nothing |
| DS17 | UniqueStrongMatch observation admits nothing | PASS — UniqueStrongMatch observation admits nothing |
| DS18 | manual local membership remains unverified | PASS — manual local membership remains unverified |
| DS19 | contradiction flags local record; no retarget | PASS — contradiction flags local record; no retarget |
| DS20 | only deleted set and its two pairs removed | PASS — only deleted set and its two pairs removed |
| DS21 | drive hard delete prohibited | PASS — drive hard delete prohibited |
| DS22 | tombstone retains pair; new admissions rejected | PASS — tombstone retains pair; new admissions rejected |
| DS23 | whole failed mutation rolled back | PASS — whole failed mutation rolled back |
| DS24 | partial DDL and version roll back; retry succeeds | PASS — partial DDL and version roll back; retry succeeds |
| DS25 | legacy cloned UUIDs create zero drives; unknown and Unsorted preserved | PASS — legacy cloned UUIDs create zero drives; unknown and Unsorted preserved |
| DS26 | committed memory-copy reopen and repeated migration unchanged | PASS — committed memory-copy reopen and repeated migration unchanged |
| DS27 | newer version rejected unchanged | PASS — newer version rejected unchanged |
| DS28 | stale revision rejected | PASS — stale revision rejected |
| DS29 | 257 rows without duplicate/skip; indexed seek; 17+1 bound | PASS — 257 rows without duplicate/skip; 17+1 bound; SEARCH drive_sets USING INDEX sqlite_autoindex_drive_sets_2 (normalized_name>?) |
| DS30 | both membership directions use covering indexed seek | PASS — both membership directions use covering indexed seek |
| DS31 | repeat add/remove/delete is exact no-op after first | PASS — repeat add/remove/delete is exact no-op after first |
| DS32 | existing capture/entry/terminal evidence guards reject mutation | PASS — existing capture/entry/terminal evidence guards reject mutation |
| DS33 | same-version missing index fails; exact index restored in isolated test | PASS — same-version missing index fails; exact index restored in isolated test |
| DS34 | blank and overlong names rejected | PASS — blank and overlong names rejected |
| DS35 | rename collision rolls back label and revision | PASS — rename collision rolls back label and revision |
| DS36 | NULL membership and stable ID rewrite rejected | PASS — NULL membership and stable ID rewrite rejected |
| DS37 | set deletion cascade reaches memberships only | PASS — set deletion cascade reaches memberships only |
| DS38 | matching labels/path/BSD/UUID/Collection imply no membership | PASS — matching labels/path/BSD/UUID/Collection imply no membership |

DS14–17/38 test an explicit admission-policy gate; they do not implement or test
an API observer/resolver. DS17 rejects automatic admission even for a supplied
strong-result label: no real strong profile is approved, and set membership is
an explicit action in any case. DS19 simulates contradictory state on a local
stub; it does not persist ADR-036 manual-event revisions. DS26 uses SQLite
memory backup into a new memory connection to simulate reopen of committed
state; it does not kill a process or test disk/WAL durability. DS28 tests stale
revision detection, not simultaneous writers. DS29 uses 257 sets and 17+1 paging,
not a large-catalog performance acceptance. DS30 observes covering index seeks
in both membership directions. DS37 traverses FK metadata: the only cascade
reachable from Drive Set is its membership relation. No production or hardware
PASS follows from these results.

### Requirements and future production/migration gates

| Requirement / authority | Synthetic evidence | Required future proof — NOT EXECUTED |
|---|---|---|
| UX §6 / ADR-037: empty/many-to-many local-ID sets | DS01–07, DS12, DS36 | Actual ID generation/collision handling, repositories, UI and explicit member selection |
| Separate Collections, zero-or-one/NULL Unsorted; ADR-019/020 | Every-case legacy digest; DS20/25/32/37 | Fresh/migrated production catalogs preserve full entries, Collection/default and comparison facts; no inferred memberships |
| ADR-036 dependency and manual provenance | DS13–19/22/38 | Approved manual record-creation/association persistence, revision revalidation, revoke/correct remove+add rollback; no hardware verification claim, offline/conflict/retired display |
| Safe deletion and evidence retention | DS20–22/32/36/37, every-case FK/integrity | Actual final schema graph audit incl. future ADR-038 tables, tombstone/no-hard-delete, no history or capture loss |
| Duplicate names / rename | DS07–11/34/35 | Owner/BRAIN name-policy approval; Foundation scalar-length/normalization parity; version collisions and input bounds; Collection namespace independent |
| Atomic mutations / idempotency | DS23/28/31/35 | All repository paths, bulk remove+add, no-op revisions, create retry operation-ID verification, uncertain-commit reconciliation |
| ADR-024 forward-only migration | DS24–27/33; all preexisting SQL definitions preserved | New schema + real Swift step, version selected then; fresh and every supported v4 variant→v9→future path; newer/malformed catalog rejection unchanged; no schema.sql replay |
| Unknown legacy physical identity | DS25 and zero automatic admission | No legacy UUID/path/name/fallback/file-ID backfill, no historical ID/receipt fabrication; retrospective assertions remain separate |
| Recovery and concurrency / ADR-025 | DS23/24/26/28 are bounded surrogates | Inject error after each DDL/version/commit boundary; process kill and reopen; busy/IO/disk-full/cancel; one-process lock; preserve original version or complete new state; no startup capture replay |
| Bounded pages and transactions | DS29/30; Q1/Q5 index research | 1–200 clamp + limit+1, hasMore/cursor, invalidation/read consistency under rename and membership writes; bounded page joins/no N+1; large membership deletion latency/cancellation/rollback |
| Existing immutable capture/evidence | DS32 with actual v9 guards; every-case digest | Production expected-object/column/FK verification every open, full source/read-only and last-complete safety regressions; actual saved-evidence retention after ADR-038 design |

Remaining decisions: final PhysicalDrive/entity/association and evidence model;
name policy/normalization version and upgrades; operation receipt strategy,
cursor invalidation and large-set deletion bounds; final versioned schema and
migration chain. All remain **TECHNICAL_PROOF_PENDING** pending separately
reviewed authorization, implementation, production tests and BRAIN acceptance.
No Xcode build or production XCTest ran in Task055. Physical-device inspection
requires a separate safety-scoped authorization; Task055 provides none.

Read-only alignment advisories: SNAPSHOT_COLLECTIONS §9 says schema version 3
(the Collection wave) while cumulative schema is v9; its §§7/9.3 legacy source
default/auto-capture language is not proof of physical-drive identity or permission
to bypass ADR-036. MVP_PLAN's Wave A matrix absence wording predates Task054/055;
the whole Wave A matrix still is not complete (ADR-038 and integrated acceptance
pending). PRD §6.1/§8.1 and ARCHITECTURE §8 legacy language are outside this task's
narrow reconciliation. None is silently rewritten here. PRODUCT_STATE,
SNAPSHOT_COLLECTIONS and MVP_PLAN remain untouched.
