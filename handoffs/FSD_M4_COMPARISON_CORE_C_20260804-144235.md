# Handoff

## Identity

- Project: FSD
- Task: FSD-M4-COMPARISON-CORE-DEEPSEEK-0804-07A
- Case code: M4-COMPARISON-CORE
- Role: WRITER
- Agent / model: DeepSeek / v4
- Session ID: not exposed by the runtime
- Started: 2026-08-04
- Completed: 2026-08-04T14:42:35+07:00

## Status

COMPLETE.

Milestone 4 comparison core — the non-visual backend slice — is implemented,
tested and validated: canonical comparison semantics, all three modes,
typed profiles, ADR-009/010/011 identity handling, deterministic bounded-
memory matching, schema v6 persistence with terminal-state immutability,
deterministic cancellation and recovery, the transient-snapshot lifecycle,
and a view-ready result API for the later Gemini-built comparison UI.
Clean arm64 build; 175 tests, 0 failures, 2 environment skips; the
100,202-entry-per-side scale class passes with exact classification; the
isolated end-to-end probe passes.

The final visual comparison interface (split view, differences-only
presentation, selection synchronization, navigation controls, empty/error
states, accessibility polish) is NOT implemented — it is the next task's
scope (Gemini), consuming the stable backend API documented here. No GUI
completion, no manual acceptance, and no MVP completion is claimed.

## Repository State

- Root: `/Users/cenvu/DEV/FSD`
- Branch: unavailable — not a Git repository
- Commit: unavailable — not a Git repository
- Git status: `BLOCKED — NOT A REPOSITORY` (git checks attempted; Git was not initialized)
- Pre-existing user changes: none beyond the milestone work; existing scratch
  files (`temp.db`, `temp2.db`, `fix_mount_consent.py`, `modify_schema.py`,
  `modify_verify.py`, `replace_docs.py`, `verify_output.txt`) were preserved
  and not used as production inputs. `modify_comparison_project.py` was added
  this session to wire the new files into the Xcode project, following the
  repository's existing script convention.

## Inputs Read

- `handoffs/CURRENT_HANDOFF.md`
- `docs/AGENT.md`, `docs/PRODUCT_STATE.md`, `docs/MVP_PLAN.md`,
  `docs/PRD.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`,
  `docs/TEST_PLAN.md`, `docs/database/schema.sql`, `docs/database/verify.sql`
- Milestone 1-3 sources: `CatalogDatabase`, `CatalogMigrations`,
  `CatalogLocation`, `CatalogProcessLock`, `SnapshotRepository` /
  `SnapshotModels`, `SnapshotWriter`, `SnapshotScanner`, `RecoveryService`,
  `SnapshotHistoryRepository`, `SnapshotTreeDataSource`,
  `MetadataSearchService`, `JSONSnapshotExporter`, `FilesystemProvider`,
  `FilesystemDetector`, `NativeMountedProvider`, `FSDApp`, `SnapshotBrowserView`
- Existing XCTest suites (all Milestone 1-3 tests plus conventions)

## Comparison Semantics (canonical, implemented)

- Metadata-only, offline, deterministic. Never implies content verification.
  No payload, hash, MIME, Magika/classification field participates anywhere.
- Exact schema outcome names: `matched`, `added`, `removed`, `changed`,
  `ignored`, `uncertain`.
- Orientation: **left = reference ("before"), right = changed ("after")**;
  `added` = present only on the right, `removed` = present only on the left
  (recorded in ADR-027). `liveToSnapshot` stores the snapshot as the left
  side and the live tree as the right side, so `added` means "new since the
  snapshot".
- `changed` rows carry `difference_flags`, one bit per compared field in
  canonical order (`item_type`, `logical_size`, `allocated_size`,
  `modified_at`, `created_at`). Timestamps compare within the profile's
  tolerance; absent equals absent.
- `ignored` rows record entries excluded by a profile (service-file rules,
  hidden items when the profile excludes them) — they exist in the result
  set but are never counted in the summary.
- `uncertain`: case-folded key collisions (ADR-010, never paired arbitrarily;
  members recorded in `comparison_collision_members`) and any entry with
  `is_inaccessible` on either side (recorded metadata is not a trustworthy
  picture; a one-sided inaccessible entry is `uncertain`, never `added`).

## Supported Modes

1. **Snapshot to snapshot** — both sides immutable stored snapshots; fully
   offline; the original source paths may be absent; deterministic across
   repeated runs (proven by repeat-run tests at fixture and 100k scale).
2. **Live to snapshot** — the live side is captured through the existing
   metadata-only scanner into a transient snapshot (ADR-012), the snapshot is
   the reference side. A failed or cancelled capture never produces a
   comparison; the failed capture's residue is removed immediately.
3. **Live to live** — both live sides captured independently into transients;
   comparison starts only after both captures complete. Cancellation or
   failure on either side terminates safely with no residue.

No raw-device or `EmbeddedRawProvider` functionality was added.

## Profile Behavior

- Typed `ComparisonProfile` over the schema's `comparison_profiles` rows:
  Fast Metadata (1), Structure Only (2), Strict Metadata (3), each with the
  canonical field selection, `timestamp_tolerance_seconds`,
  `include_hidden_items`, and `ignore_rules_json`.
- Schema v6 adds `comparison_profiles.version` and freezes the revision into
  `comparisons.profile_version` at creation (ADR-027) — a later profile edit
  can never silently reinterpret an earlier comparison's conclusion.
- Ignore rules use deterministic documented glob semantics (`*`, `?`, `**`,
  name-only vs path rules) matched against ADR-009 case-folded forms, so a
  rule decision is per comparison key and symmetric across sides.
- Classification fields are never included; Metadata Match never claims
  content equality.

## Identity and Collision Handling

- ADR-010 key selection: both sources sensitive → `case_preserving_path`;
  otherwise → `case_folded_path`, with an explicit compatibility warning for
  `unknown` sensitivity (re-derived deterministically on the record).
- Case-sensitive sources preserve case-distinct entries; case-insensitive
  matching folds; NFC/NFD-equivalent paths match via the stored NFC keys;
  raw filename-byte preservation is not claimed (ADR-009).
- Folded collisions are never merged or arbitrarily paired: the whole key
  becomes one `uncertain` result plus explicit collision members; the
  schema's no-collision-pairing triggers enforce it at the database boundary.
- Normalization-version mismatch: the engine carries a typed
  `normalizationMismatch` error and the schema re-checks equality on insert.
  In the current catalog a mismatched snapshot can never even complete (the
  completion guard admits only the ADR-009 allowlist identity), so the
  mismatch path is defense-in-depth — tests assert the whole enforcement
  chain.

## Snapshot Eligibility

- Only `complete` and `complete_with_warnings` snapshots participate; every
  other state (`scanning`, `interrupted`, `cancelled`, `failed`) is rejected
  with a typed `ineligibleSnapshot` error naming the state and the policy,
  and the schema trigger independently enforces the same rule. A
  complete-with-warnings side stays eligible and its warning count is
  surfaced on the record. A failed eligibility check leaves no comparison
  row.

## Engine

- `FSD/Diff/ComparisonEngine.swift`: compares two stored snapshots by
  merging keyset-paged `ORDER BY <key>, id` streams of both sides. Memory is
  bounded by one page per side plus the current key group — no whole-tree
  arrays, no dictionaries of 100k entries. Key comparison is UTF-8 byte
  order, matching SQLite's BINARY collation exactly.
- Progress (`ComparisonProgress`), cancellation (`ComparisonCancellationToken`
  = the capture token's atomic finalization semantics), typed errors
  (`ComparisonError`), deterministic output and stable ordering.
- Results persist in bounded batches (multi-row VALUES chunks) inside
  transactions; summary counts are recomputed from the persisted rows at the
  terminal transition, so a cancelled or failed comparison's summary always
  matches its retained evidence.
- No filesystem access for stored-snapshot sides; no classification access.

## Persistence (schema v6, ADR-027)

Smallest explicit migration from v5 (transactional, converging fresh and
migrated catalogs, rollback-tested, documented in `schema.sql` /
`verify.sql` W1-W10):

- `comparison_profiles.version INTEGER NOT NULL DEFAULT 1`
- `comparisons.profile_version INTEGER NOT NULL DEFAULT 1`
- `trg_comparisons_terminal_immutable` — status/summary counts immutable
  after `complete`/`cancelled`/`failed`
- `trg_comparison_results_insert_guard` / `trg_comparison_results_update_guard`
  — no result INSERT/UPDATE on terminal comparisons (deleting a whole
  comparison remains the explicit disposal API)
- `idx_comparison_results_type (comparison_id, result_type)` — bounded
  differences-only queries

`CatalogMigrations.currentVersion` = 6; `ExpectedState` verifies the new
triggers/index/columns on every open; both known v4 variants migrate to 6
via the v5 step. `verify.sql` fires all 40 intended rejections including the
four new W4-W7 guards. Pre-existing comparison tables/constraints were used
as-is; no parallel schema was introduced.

## Cancellation and Recovery

- Cancellation before work starts → no comparison row at all.
- Cancellation during live capture stops through the scanner's existing
  cancellation path; the capture is terminalized `cancelled` and its residue
  cleaned immediately.
- Cancellation during matching stops bounded processing; the comparison row
  is terminalized `cancelled` with the counts of what was persisted.
- The terminal transition shares the token's finalization lock, so a late
  cancel request can never race the result into `complete`.
- Launch recovery: `TransientSnapshotLifecycle.recoverOrphanedComparisons()`
  marks abandoned `running` comparisons `failed` (counts recomputed from
  retained rows — never `complete`); `cleanupUnreferencedTransients()`
  deletes transient snapshots no comparison references. Runs at app launch
  after the existing scan recovery. Completed snapshot data is never touched.
- Workspace close (ADR-012): running disposable comparisons are cancelled
  first, live-side comparison records are disposed (the explicit deletion
  API), and the transient snapshots they referenced are deleted.
  Snapshot-to-snapshot comparisons persist.

## Transient Lifecycle

Transients are excluded from user history by kind; a transient referenced by
a comparison row is retained (`ON DELETE RESTRICT`, ADR-012) until its
comparison is disposed; unreferenced transients are deleted on workspace
close, on launch, and immediately when a live capture fails or is cancelled.

## Data APIs for the Gemini GUI

`ComparisonResultRepository` (view-ready immutable models only; no statement
handles or raw rows):

- `listComparisons(limit:)`, `record(id:)`, `count()`, `resultCounts(_:)`
- `results(comparisonID:filter:offset:limit:)` with `ComparisonResultFilter`
  (`all`, `differences`, `added`, `removed`, `modified`, `unchanged`,
  `conflicts`, `ignored`), stable `(result_path, id)` ordering, bounded pages
- `navigate(comparisonID:filter:from:direction:limit:)` — deterministic
  next/previous difference navigation
- `fieldDifferences(for:comparisonID:)`, `entryMetadata(id:snapshotID:)`
- `deleteComparison(_:)` — the explicit disposal API
- `ComparisonRecord` carries mode, both side descriptors (label, live flag,
  source description, status, warning count, case sensitivity, normalization
  version), profile id/name/version, status, times, and all counts.

No fake GUI was built to exercise the API.

## Scale Results (Milestone 4 class)

`ComparisonScaleTests`, synthetic catalogs (no physical files): 100,202
entries per side (100,000 files + 100 dirs + root + one one-sided branch),
predominantly unchanged, with modified metadata and added/removed branches:

- compare duration: 12.7 s (Debug `-Onone` build; Release is expected much
  faster — not claimed)
- classification exactly: 100,001 matched / 100 changed / 101 added /
  101 removed; total compared 100,303
- first-page latency 0.0033 s; differences-only latency 0.0125 s
- repeat run produces an identical result set (fingerprint-equal)
- bounded paging: 50-row pages in path order, no overlap, no reordering;
  last page carries the remainder
- cancellation mid-matching stops bounded processing; the cancelled record's
  counts match its retained rows
- snapshots untouched, zero classification rows, `integrity_check` ok,
  `foreign_key_check` clean
- peak memory not measured (only recorded when easily available)
- the 1,000,000-entry class remains the Milestone 5 gate and was not run

## Automated End-to-End Evidence

`ComparisonEndToEndProbeTests` (isolated probe, automated): two controlled
generated folders captured through the production scanner; live-to-live
comparison (known added/removed/modified); sources removed; snapshot-to-
snapshot comparison fully offline; isolated catalog reopened with a fresh
connection; stored results readable after reopen with the sources gone;
fixtures byte-identical before/after (full listing with sizes and
timestamps); classification rows zero; integrity and foreign-key checks
clean; schema version 6.

AGENT-OBSERVED (in addition): the built `FSD.app` was launched for ~3 s
against an isolated catalog (`FSD_CATALOG_PATH` override); it created the
catalog at schema version 6 with `integrity_check` = ok, zero foreign-key
violations, zero classification rows, zero comparisons, and printed its
resolved catalog path to stderr. The binary is Mach-O arm64.

NOT PERFORMED — DEFERRED BY OWNER: all manual acceptance (Manual Session A;
Manual Session B's comparison gates B5/B6/B7 wait for the GUI and the
consolidated session).

## Build and Test Validation

- Xcode: 26.3 (17C529)
- Swift: Apple Swift 6.2.4 / swift-driver 1.127.15
- Architecture: arm64; binary target macOS 13.0
- Clean command: `xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-M4-Clean-DerivedData CODE_SIGNING_ALLOWED=NO clean`
- Build command: same settings, `build`; test command: same settings, `test`
- Clean/build/test result: all exit 0; build succeeded; test succeeded
- Test result bundle: `/tmp/FSD-M4-Clean-DerivedData/Logs/Test/Test-FSD-2026.08.04_14-37-17-+0700.xcresult`
- Full suite: **175 executed, 0 failed, 2 skipped** (the two ordinary
  `FilesystemMatrixTests` are intentionally inert without matrix environment
  values, as before)
- New tests this milestone: 75 (Semantics 17, Identity 9, SnapshotState 9,
  Modes 15, Persistence 15, Scale 5, EndToEndProbe 1, SchemaMigration +3 for
  the v5-to-v6 wave); 3 existing suites bumped their schema-version
  assertions to 6 (CatalogDatabaseTests, ManualSessionASubstituteTests,
  MilestoneConditionTests, JSONExportTests)
- Final warnings: only the toolchain/AppIntents note ("Metadata extraction
  skipped. No AppIntents.framework dependency found") and the pre-existing
  XCTest/macOS linkage notes; zero non-Sendable, zero SQLite-lifetime, zero
  comparison warnings. The clean test log contains zero `vnode unlinked while
  in use` / `invalidated open fd` messages.
- Schema version: 6; migration result: v4→v5→v6 converges both known v4
  variants and v5 (all migration, rollback, reopen, and fresh-vs-migrated
  equivalence tests pass)
- `PRAGMA integrity_check` = ok and `PRAGMA foreign_key_check` = 0 rows on
  the probe catalog, the scale catalogs, and the verify.sql catalog
- `docs/database/verify.sql` run clean on a fresh v6 catalog: 40 intended
  rejections fire, including the new W4-W7 terminal-state guards
- App path: `/tmp/FSD-M4-Clean-DerivedData/Build/Products/Debug/FSD.app`
- Binary: `Mach-O 64-bit executable arm64`

## Files Changed

Production (new):

- `FSD/Diff/ComparisonModels.swift`
- `FSD/Diff/ComparisonProfileRepository.swift`
- `FSD/Diff/ComparisonEngine.swift`
- `FSD/Diff/ComparisonResultRepository.swift`
- `FSD/Diff/ComparisonService.swift`
- `FSD/Catalog/TransientSnapshotLifecycle.swift`

Production (modified):

- `FSD/Catalog/CatalogMigrations.swift` (version 6, migration, ExpectedState)
- `FSD/Catalog/CatalogDatabase.swift` (comparison/profile column verification;
  `executeWithRowCount`)
- `FSD/Scanner/SnapshotScanner.swift` (`kind:` passthrough for transient
  captures)
- `FSD/App/FSDApp.swift` (launch recovery for orphaned comparisons and
  unreferenced transients)
- `FSD.xcodeproj/project.pbxproj` (new files, new Diff group)

Tests (new):

- `FSDTests/TestSupport.swift` (synthetic snapshot seeding)
- `FSDTests/ComparisonSemanticsTests.swift`
- `FSDTests/ComparisonIdentityTests.swift`
- `FSDTests/ComparisonSnapshotStateTests.swift`
- `FSDTests/ComparisonModeTests.swift`
- `FSDTests/ComparisonPersistenceTests.swift`
- `FSDTests/ComparisonScaleTests.swift`
- `FSDTests/ComparisonEndToEndProbeTests.swift`

Tests (modified):

- `FSDTests/SchemaMigrationTests.swift` (v6 fixtures, v5→v6 migration,
  rollback, equivalence)
- `FSDTests/CatalogDatabaseTests.swift`, `FSDTests/ManualSessionASubstituteTests.swift`,
  `FSDTests/MilestoneConditionTests.swift`, `FSDTests/JSONExportTests.swift`
  (schema-version assertions → 6)

Documentation:

- `docs/database/schema.sql` (cumulative schema v6)
- `docs/database/verify.sql` (W1-W10 section; V1 label)
- `docs/DECISIONS.md` (ADR-027)
- `docs/ARCHITECTURE.md` (TreeDiffEngine implementation note)
- `docs/PRODUCT_STATE.md`, `docs/MVP_PLAN.md`, `docs/TEST_PLAN.md`
- `docs/KNOWN_ISSUES.md` (KI-016..KI-018)
- `modify_comparison_project.py` (project-wiring helper script)

## Known Limitations

- The visual comparison interface (split view, differences-only
  presentation, matched-subtree collapse rendering, selection
  synchronization, navigation controls, empty/error states, accessibility
  polish) is not implemented — the next (Gemini) task consumes the stable
  backend API.
- Matched-subtree aggregate-signature skipping is not implemented (KI-016);
  per-entry result rows are produced, which keeps results deterministic and
  self-contained. 100k-class performance is verified; the 1M class is the
  Milestone 5 gate (KI-018).
- Live-side comparisons are workspace-scoped: closing the workspace
  disposes them and their transients (KI-017); only snapshot-to-snapshot
  comparisons persist in the recent list.
- Peak memory was not measured.
- Debug-build timings are recorded; Release-build timings are not claimed.
- Manual acceptance remains deferred; Magika remains Phase 1.5; no content
  verification exists anywhere.

## Unverified Claims

- No user-observed UI acceptance was claimed (all GUI work is deferred).
- No 1,000,000-entry final-scale acceptance was claimed.
- No Release-mode performance claims were made.
- No independent audit was performed in this Writer task.

## Safest Resume Boundary

The safe boundary is after the Milestone 4 comparison core. Do not repeat
the engine, the v6 migration, the comparison tests, or the scale probe
unless a new reproducible defect appears. The next slice is the visual
comparison interface over `ComparisonResultRepository`/`ComparisonService`
(plus the mandatory independent audit of comparison semantics), followed by
Milestone 5.

## Exactly One Next Action

Run an independent Codex audit of the DeepSeek Milestone 4 comparison core
(comparison semantics is an explicit review boundary per `AGENT.md` § Review
policy); with the audit green, implement the visual comparison interface as
the Gemini task.

## Resume Context

Use `docs/PRODUCT_STATE.md`, `docs/MVP_PLAN.md`, `docs/DECISIONS.md`
(ADR-027), `docs/TEST_PLAN.md`, and this handoff. The comparison backend is
metadata-only and offline; the orientation convention (left = reference,
right = changed) is canonical; transient snapshots are workspace-scoped per
ADR-012; schema is version 6; Manual Session A remains in the consolidated
deferred backlog; no Magika runtime, no network, no source mutation.
