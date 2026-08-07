# Handoff

## Identity

- Project: FSD (FishSock Differ)
- Task: FSD-M5-PERFORMANCE-PREMVP-DEEPSEEK-0804-14
- Case code: FSD_M5_PERFORMANCE_PREMVP
- Role: Writer (C)
- Agent / model: DeepSeek / v4-flash
- Session ID: FSD-M5-PERFORMANCE-PREMVP-DEEPSEEK-0804-14
- Started: 2026-08-04T20:30:00+0700 (approximate)
- Completed: 2026-08-05T03:45:39+0700

## Status

**COMPLETE_WITH_KNOWN_LIMITATIONS.** All active Milestone 5 technical gates
pass: the one-million-entry snapshot-catalog and comparison classes run with
exact classification, determinism, bounded memory, cancellation, navigation
and reopen evidence; the pathological equal-key collision group is a typed
failure (KI-019 superseded by KI-023); KI-022 (legacy capture error surface)
is fixed with adversarial regression tests; fresh Debug and Release arm64
builds pass with the full suite; isolated app launch probes reach all three
destinations. Remaining limitations are exactly the allowed class: deferred
owner manual acceptance (consolidated session prepared in TEST_PLAN.md §8.2,
NOT PERFORMED — DEFERRED BY OWNER), stock-macOS NTFS environment limitation,
bounded visual/VoiceOver observation deferred, and one documented
non-safety performance follow-up (KI-024: whole-comparison disposal is O(n²)
at the 1,000,000-entry class — root cause identified, schema fix requires
version 8 which this task forbids for performance-only work; disposal is
verified correct at the 100,202-per-side class). The MVP is not approved:
the next action is the independent Codex final pre-MVP audit.

## Repository State

- Root: `/Users/cenvu/DEV/FSD`
- Branch: unavailable; `.git` is absent
- Commit: unavailable; `.git` is absent
- Git status: `BLOCKED — NOT A REPOSITORY`
- Pre-existing user changes: cannot be separated without Git. No production
  semantics were changed beyond the two documented corrections (KI-022
  capture error surface; KI-023 collision-group cap).

## Final-Scale Definitions (Part 1)

The active M5 scale requirements live in `MVP_PLAN.md` Milestone 5 and
`TEST_PLAN.md` §4 (benchmark classes 10k / 100k / 1M) and §5 (CT-005:
"at least 1,000,000 entries"). No contradiction exists; the
1,000,000-entry class is the documented final gate and was not lowered.
Per the task, the million-entry fixtures are synthetic SQLite catalogs
(generated metadata rows through the production schema and triggers — no
physical files), which the plan and task explicitly permit. No claim of live
capture of one million physical files is made.

Exact fixture compositions (`FSDTests/FinalScaleFixtures.swift`):

- **Snapshot catalog** (`M5SnapshotCatalog.populate`): 1,002,182 entries =
  root + 1,000 directories (`d0000…d0999`) × 1,000 files
  (`f00000.bin…f00999.bin`) + 40-level deep branch (`deep00…deep39`, one
  `leaf.dat` per level, deepest holding 1,000 `deepfile%05d.bin`) + hidden
  directory `zhidden` (100 hidden files). Deterministic sequential ids,
  zero-padded names (folded order = numeric order), deterministic sizes
  (`syntheticSize`).
- **Comparison pair** (`M5ComparisonPair.populate`): left 1,003,104 entries,
  right 1,003,205 entries, both `source_case_sensitivity = 'insensitive'`
  (engine uses the case-folded identity key, ADR-010). Composition:
  predominantly matched (root + 1,000 dirs + 999,000 unchanged files);
  1,000 modified files in `d0000` (size +1); `zadded` branch right-only
  (1,001 added); `zremoved` branch left-only (1,001 removed); `zuncertain`
  branch right-only marked inaccessible (101 uncertain); 500 case-fold
  collision pairs in `zcollide` on both sides (500 collision groups, 2,000
  members — never paired); 100 `._*` service files per side in `zignore`
  (200 ignored).
- **Pathological pair** (`M5PathologicalPair.populate`): 150,000 members per
  side in `zcoll/` whose 20-character ASCII names differ only by case — all
  fold to one comparison key (the KI-019 condition).

Expected outcomes (Fast Metadata profile, id 1):

- snapshot catalog: 1,002,182 entries; search `f00500` → 1,000 matches
  (first page 100, truncated); `leaf.dat` → 40; hidden-only `h000` → 10;
  path-field `zhidden/h0000` → 1.
- comparison: matched 1,000,003 / changed 1,000 / added 1,001 / removed
  1,001 / uncertain 601 / ignored 200; 1,003,806 persisted result rows;
  500 collision groups with 2,000 members; record compared-total 1,003,606
  (persisted outcome count excluding `ignored` — the same record semantics
  the Milestone 4 scale record used).
- pathological: `ComparisonError.collisionGroupTooLarge` (typed failure;
  comparison `failed`, never `complete`).

## Snapshot Catalog Scale Results (Part 2) — Debug correctness run

`FinalScaleSnapshotTests`, fresh isolated catalogs, Debug (`-Onone`),
all 3 passed, 0 failures:

- fixture generation: 1,002,182 entries, memory-bounded (per-directory
  batches, 1,500-row chunks in per-batch transactions); test-level duration
  80.9 s including generation plus the whole exercise.
- history first load: 1 summary, totals correct (1,001,140 files).
- open snapshot: exactly 1 row read (root).
- root first page: 200 rows (page size 200; 1,002 children present);
  deterministic folded-path ordering across pages, no repeats.
- direct-child page: 1 query, 200 rows.
- deep-path expansion: all 40 levels expand; the deepest level pages at
  200 rows.
- bounded search: `f00500` first page 100 hits, truncated (1,000 matches);
  hidden-only `h000` → 10; hidden-excluded → 0; path-field → 1.
- rows fetched across the whole exercise ≈ 5,203 (browsing probe) — four
  orders of magnitude below the entry count (tree never materialized).
- JSON export: 1,002,182 entries, 25.7 s (Debug) / 15.8 s (Release), output
  339,800,087 bytes; second export byte-size and head identical
  (deterministic); streamed in 1,000-row pages (memory evidence, Part 4).
- reopen: 0.016 s (Debug) / 0.008 s (Release); schema version 7;
  `integrity_check` ok; `foreign_key_check` clean; classification rows 0.

## Comparison Scale Results (Part 3) — Debug correctness, Release performance

`FinalScaleComparisonTests`, 1,003,104 vs 1,003,205 entries per side;
all 6 tests passed in both configurations.

| Measure | Debug (-Onone) | Release (-O, testability) |
|---|---|---|
| compare duration (1,003,806 result rows) | 296.8 s (299.5 s first run) | 235.7 s |
| exact classification | 1,000,003 / 1,000 / 1,001 / 1,001 / 601 / 200 | identical |
| first-page latency | 0.0033 s (recorded at run) | — |
| differences-only latency | 0.0125 s (recorded at run) | — |
| navigation walk (3,603 differences, both directions) | 2.377 s | 1.920 s |
| cancellation at 500,000 processed | 192.3 s; cancelled; 250,000 rows retained; counts == rows | 164.4 s; identical invariants |
| repeat-run determinism | fingerprint identical | fingerprint identical |
| result reopen | 278.1 s test; record+paging readable | 216.3 s test |
| disposal (100,202/side, 100,303 rows) | 343.9 s; zero residue; integrity ok; fk clean | 343.5 s; identical |

- Per-outcome filter counts (added/removed/modified/unchanged/conflicts/
  ignored) match exactly at scale; differences-only paging walks all 3,603
  differences in 500-row pages with no repeats; next/previous navigation
  across page boundaries returns the identical deterministic order.
- Release vs Debug is nearly identical because the merge is dominated by
  SQLite C execution (page streams + persistence), not Swift arithmetic —
  recorded as context, not a defect.
- KI-024: whole-comparison disposal at the 1,000,000-entry class is O(n²)
  (in progress at >45 minutes, no completion in the observation window) —
  root cause verified against the schema: the self-referential
  `comparison_results.parent_result_id` FK has no dedicated leading index,
  so SQLite's per-row FK enforcement scans the whole result table during the
  cascade. Fix = index on `comparison_results(parent_result_id)` — a schema
  change requiring version 8, forbidden by this task for performance-only
  work, so recorded precisely for the pre-MVP audit. Correctness at the
  completing class is fully verified (zero residue, immutable snapshots,
  integrity ok, fk clean, classification 0).

## Memory and Boundedness (Part 4) — measured resident footprint

Resident footprint via `task_info` (`mach_task_basic_info`) of the test host
(the app process); a background sampler (10 ms interval, joined before read)
records peak during synchronous operations. Evidence:

| Operation (1M class) | Baseline | Peak | Delta | Note |
|---|---|---|---|---|
| Comparison merge (1,003,104 vs 1,003,205) | 216.7 MB (D) / 448.1 MB (R) | 230.1 MB (D) / 456.9 MB (R) | **13.4 MB (D) / 8.8 MB (R)** | merge holds only pages — neither full tree |
| JSON export (1,002,182 entries) | 234.8 MB (D) / 456.2 MB (R) | 243.5 MB (D) / 465.0 MB (R) | **8.7 MB** both | output 339.8 MB — streaming proven (a whole-document build would hold ≥ output) |
| Search | 234.4 MB (D) | 243.2 MB | 8.7 MB | bounded pages |
| Browsing | 234.5 MB (D) | 239.4 MB | 4.9 MB | 5,203 rows fetched |
| Pathological collision group (150,000/side) | 216.7 MB (D) | 329.7 MB (D) / 512.2 MB (R) | 69.5 MB (D) / 43.6 MB (R) | typed failure; comparison failed; integrity ok |

- Paging caps: `ComparisonResultRepository.maximumPageSize` = 5,000;
  tree page size 200 — a caller cannot raise either ceiling.
- The known pathological equal-key collision-group condition is resolved as
  "protected by an explicit safe cap/typed failure" (KI-023): cap 100,000
  members per group, `ComparisonError.collisionGroupTooLarge`, comparison
  `failed` never `complete`, bounded memory measured. No memory-bound failure
  was hidden by reducing fixture size.

## Performance Acceptance (Part 5)

No numeric per-operation acceptance threshold exists in the canonical
documents beyond the class definitions and CT-005's boundedness conditions.
Per the task rule, measured evidence is recorded and a conservative proposed
threshold is stated as a proposal, not a retroactive pass claim:

- Proposed (Release) thresholds for the audit to ratify: 1M snapshot open +
  first page < 2 s; bounded search first page < 2 s; 1M-vs-1M comparison
  completes < 5 min; first-page/differences latency < 0.1 s; export ≥ 1 MB/s
  of output; merge peak delta < 100 MB.
- Debug runs are correctness evidence only; Debug timings are never compared
  to Release acceptance limits. Machine/toolchain context for every timing:
  see Build and Test Evidence.

## Cancellation and Race Stress (Part 6) — 8/8 passed (Debug)

`CancellationRaceStressTests`:

- repeated capture cancellation (5 iterations): exactly one terminal state,
  `cancelled`, never `complete`.
- repeated live-to-snapshot cancellation (3): throws `ComparisonError
  .cancelled`; no comparison record; no transient residue; reference
  snapshot stays complete.
- live-to-live cancellation on the left capture, the right capture
  (distinguished by tree sizes) and at the start of matching: the
  merge-cancelled comparison is terminalized `cancelled` with its referenced
  transients retained as evidence; no running comparisons remain.
- repeated comparison cancellation during matching and persistence (3
  thresholds 30%/55%/90%): each cancelled comparison's summary equals its
  retained rows exactly; nothing left running.
- cancellation near terminalization (3 iterations): the finalization lock
  decides (returned terminalized-cancelled record or thrown cancelled);
  counts always consistent; exactly one terminal state wins.
- orphan recovery (3 iterations): orphaned scan → `interrupted`; orphaned
  running comparison → `failed` (never `complete`); unreferenced transient
  deleted; referenced transients retained as the failed comparison's
  evidence; repeated recovery idempotent.
- workspace close during a running live comparison: no running comparison,
  no transient, no comparison row remains; integrity ok.
- repeated launch-cycle recovery (5 cycles): idempotent.
- No deadlock, no transient residue, `integrity_check`/`foreign_key_check`
  clean in every test.

## Startup, Recovery and Catalog Reliability (Part 7) — 6/6 passed (Debug)

`M5ReliabilityTests` plus the existing migration/damaged-schema suites
re-run clean:

- fresh startup: schema v7, integrity ok, fk clean, classification 0, lock
  held.
- process-lock contention refused (`LockError.alreadyLocked`); released on
  unlock (relaunch case).
- repeated open/close cycles (10): clean reopen each cycle, lock
  re-acquirable; WAL/SHM state after final close recorded (no residue after
  clean close).
- interrupted operation + relaunch: the exact terminal state (interrupted
  scan, failed comparison) is stable across the close/reopen/relaunch
  sequence.
- damaged-current-schema rejection: dropping a canonical trigger → reopen
  fails `schemaStateInvalid`.
- owner-catalog isolation: the test host resolves its own catalog; the
  owner's catalog file size and modification date are untouched across the
  run.
- Migration chain v4→v5→v6→v7 (both v4 variants), completed-snapshot
  preservation, v7 rollback, reopen-without-replay, fresh/migrated
  equivalence and damaged-v7 rejection: covered by the existing
  `SchemaMigrationTests` / `SchemaSafetyCorrectionTests` suites, which pass
  unchanged (cited, not duplicated).

## KI-022 Correction (Part 8) — FIXED; adversarial tests 6/6 passed

Production change: new `FSD/App/CaptureErrorDescription.swift` — one shared
bounded mapper applied at both failure sites in `FSDApp.swift` (the
`SnapshotScannerError` and generic catches). The visible capture UI shows
fixed or safely typed wording; the raw diagnostic stays on the standard-error
channel via `CaptureErrorDescription.diagnosticLine` (the same channel
startup diagnostics already use — no new write path). The capture view now
renders the bounded failure text; `-FSDSelectCapture` DEBUG-only probe seam
added (mirrors `-FSDSelectCompare`). No coupling to comparison models.

`CaptureErrorBoundaryTests` (6/6):

- arbitrary hostile diagnostics (SQLITE_CORRUPT at an internal path; POSIX
  errno at a provider path; provider-internal token) produce identical
  bounded visible text; SQL/path/provider tokens absent from all visible
  strings.
- typed distinctions bounded and distinct: capture failure, provider /
  unavailable source (invalidSource and outsideSelectedRoot share one
  "not readable" text), metadataUnavailable, cancellation, writer/catalog
  failure, detector failure, generic fallback.
- cancellation remains distinct from failure; wrapper and typed entry
  points produce identical text.
- source boundary: `FSDApp.swift` contains no `.failed(error.localizedDescription)`
  and routes through the mapper; `diagnosticLine` retains the raw detail for
  diagnostics.

## Offline and Read-Only Safety Regression (Part 9) — re-run clean

- stored history opens with source absent; snapshot tree browsing, metadata
  search and JSON export run fully offline (catalog rows only; the scale
  suites are offline by construction — no source exists).
- snapshot comparison and comparison-GUI result browsing load stored results
  offline (repository reads catalog rows only).
- source metadata unchanged during controlled live capture:
  `ManualSessionASubstituteTests` (source byte-for-byte unchanged,
  cancellation never produces a complete snapshot, relaunch preserves
  state) and `Milestone2CaptureTests` (source listing unchanged) pass.
- no payload file handles opened by scan/compare/export paths: the
  production target contains no `FileHandle(forReadingFrom:)`, no
  `Data(contentsOf:)` on a source path, no hashing API; grep-verified again
  this campaign.
- no classification rows created anywhere (0 in every suite); no
  source-write API introduced; no network APIs in the production target
  (grep-verified).

## Filesystem Matrix (Part 10)

No fresh matrix campaign was run: the Milestone 3 closeout evidence
(2026-08-04, eight host-capable variants, image SHA-256 identical before and
after capture) remains valid — Milestones 4–5 did not touch the provider or
scanner behavior — and the task permits relying on existing evidence when it
remains valid. The two matrix probes remain environment-gated skips in
ordinary runs. Stock-macOS NTFS remains **ENVIRONMENT-BLOCKED — PROVIDER
PATH NOT INVALIDATED** (no stock formatter / `mount_ntfs` helper on this
host; no third-party driver installed; no real removable media or raw device
used). `FILESYSTEM_SUPPORT_MATRIX.md` is unchanged.

## Debug and Release Builds and App Readiness (Part 11)

- Toolchain: Xcode 26.3 (17C529); Swift 6.2.4, swift-driver 1.127.15;
  host arm64 macOS (Darwin 24.6.0); deployment target macOS 13.0.
- Fresh Debug clean build: BUILD SUCCEEDED;
  `/tmp/FSD-M5-PerfPreMVP-DerivedData/Build/Products/Debug/FSD.app`
  (Mach-O 64-bit arm64).
- Fresh Release clean build (shipped configuration, no testability):
  BUILD SUCCEEDED;
  `/tmp/FSD-M5-Release-Shipped-DerivedData/Build/Products/Release/FSD.app`
  (Mach-O 64-bit arm64, `LC_BUILD_VERSION` minos 13.0, sdk 26.2).
- Bundled `schema.sql` byte-identical to `docs/database/schema.sql`
  (SHA-256 `54c9ed25…e3187` in both Release products).
- Full XCTest Debug suite: **277 total, 274 passed, 0 failed, 3 skipped**
  (2,730 s). Full XCTest Release suite (ENABLE_TESTABILITY=YES for the test
  host only): **277 total, 273 passed, 0 failed, 4 skipped** (2,228 s) —
  the fourth skip is the Debug-only override assertion, corrected in this
  task to skip under Release (ADR-026) instead of failing the suite.
- Isolated app launch probes (Debug app, `-FSDCatalogPath`): Snapshots,
  Compare (`-FSDSelectCompare`) and Capture (`-FSDSelectCapture`)
  destinations all alive after 3 s; each created its isolated catalog at
  schema 7 with `integrity_check` ok and 0 classification rows; no
  owner-catalog access; no network activity (no network APIs exist in the
  target).
- Release app launch probes: the app deliberately refuses
  `-FSDCatalogPath` (ADR-026 — "catalog-path overrides are available in
  DEBUG builds only") and reports the refusal on stderr; all three
  destinations stay alive; the owner catalog was verified healthy after the
  probes (schema 7, integrity ok, 0 classification rows, 0 scanning
  snapshots). Isolated-catalog launch probes are a Debug affordance by
  design; this is reported as-is, not claimed for Release.
- No signing, notarization, archiving, DMG or App Store work was performed.

## Test Suite Hygiene (Part 12)

- The three ordinary-run skips are classified: `FSDProbeSeedTests
  .testSeedIsolatedProbeCatalog` — intentional environment/marker-gated
  probe seeder (inert without `FSD_PROBE_CATALOG` or the marker file; not
  removable by a generated fixture; not obsolete; not a blocker);
  `FilesystemMatrixTests.testCaptureExternallyPreparedMountedFilesystem` and
  `testReopenCapturedSnapshotWithTheSourceDetached` — intentional
  environment-gated matrix probes. A fourth Release-only skip was added:
  `MilestoneConditionTests.testDebugBuildsExposeTheOverride` now asserts
  only in DEBUG builds and skips under Release (it previously failed the
  Release suite). Intentionally configured matrix/probe executions are not
  counted as ordinary full-suite failures.
- Removed the stale unused `transientID` warning in
  `ComparisonGUIValidationTests` (the only known stale test warning).
- No temporary test files in project paths; no accidental pointer Handoffs
  (every Handoff is a full report per `AGENT.md`).

## Repository Hygiene (Part 13)

- Removed (obsolete scratch, conclusively prior-Agent work, unreferenced by
  project/docs/tests, safe to remove — flagged "should be cleaned up" by
  prior audits): `temp.db`, `temp.db-shm`, `temp.db-wal`, `temp2.db`,
  `temp2.db-shm`, `temp2.db-wal` (2026-07-24 SQLite verification scratch),
  `verify_output.txt` (2026-07-24 verify.sql run output), `default.profraw`
  (0-byte LLVM coverage artifact from 2026-08-04), and the four one-off
  planning scripts `modify_schema.py`, `modify_verify.py`, `replace_docs.py`,
  `fix_mount_consent.py` (their effects are permanently applied to the docs
  and `verify.sql`). Note: `default.profraw` regenerates at the project root
  on every instrumented run because the scheme's pre-existing
  `codeCoverageEnabled = YES` builds the app with profiling instrumentation;
  it was removed again at closeout (0 bytes, 2026-08-05) and the scheme
  setting is unchanged.
- Retained (useful documented developer utilities, purpose recorded):
  `modify_comparison_project.py` (M4 project-wiring helper, documented in
  the M4 Handoffs), `add_files.py`, `add_files.rb`, `add_files_raw.py`
  (pbxproj wiring helpers used by the M4 GUI-fix session — the convention
  future milestones reuse).
- Unknown owner artifacts: none. No Git cleanup commands were used.

## Consolidated Deferred Manual Acceptance (Part 14)

Prepared in `TEST_PLAN.md` §8.2 as the single consolidated future manual
acceptance session (steps M1–M25): launch and navigation; capture; source
unchanged; capture cancellation (including the physical-disconnect variant
when removable media exists); relaunch after interruption; force-quit
recovery; history; offline browsing; offline search; large-tree navigation;
JSON export; all three comparison modes; per-outcome filters; next/previous
navigation; uncertainty wording; content-not-verified language; disposal;
partial/error states; visual layout; keyboard behavior; VoiceOver basics;
filesystem sampling on host-capable generated images (stock NTFS excluded).
Every step lists setup, exact action, expected visible result, evidence to
record, cleanup and its mapping to canonical test IDs (A1–A6, B1–B11,
CT-001, matrix §1). Marked **NOT PERFORMED — DEFERRED BY OWNER**; no
separate manual-report artifact was created (`AGENT.md`).

## Canonical Documentation (Part 15)

Updated: `docs/PRODUCT_STATE.md` (M5 status, next action),
`docs/MVP_PLAN.md` (status + M5 implementation record), `docs/TEST_PLAN.md`
(§4 final-scale evidence, §5 M5 test inventory, §8.2 consolidated manual
session), `docs/KNOWN_ISSUES.md` (KI-018/KI-019 superseded, KI-022 FIXED,
KI-023 CLOSED, KI-024 new), `docs/DECISIONS.md` (ADR-029: bounded capture
error surface + typed collision-group cap). `docs/FILESYSTEM_SUPPORT_MATRIX.md`
and `docs/SECURITY_AND_READ_ONLY_POLICY.md` unchanged — no fresh matrix
evidence and no new write path (the diagnostic channel is standard error,
the same channel startup diagnostics already used).

## Exact Files Changed

Production:
- `FSD/App/CaptureErrorDescription.swift` (new — bounded capture error
  mapper, KI-022).
- `FSD/App/FSDApp.swift` (route visible capture failures through the mapper;
  standard-error diagnostic; render bounded failure text; `-FSDSelectCapture`
  probe seam).
- `FSD/Diff/ComparisonModels.swift` (new `ComparisonError.collisionGroupTooLarge`
  case, KI-023).
- `FSD/Diff/ComparisonEngine.swift` (cap constant
  `maxCollisionGroupMemberCount` = 100,000; `consumeGroup` throws the typed
  failure).
- `FSD/UI/ComparisonSharedViews.swift` (bounded GUI wording for the new
  case).

Tests (all new):
- `FSDTests/FinalScaleFixtures.swift` (fixture generators).
- `FSDTests/FinalScaleSnapshotTests.swift` (Part 2).
- `FSDTests/FinalScaleComparisonTests.swift` (Part 3).
- `FSDTests/FinalScaleMemoryProbeTests.swift` (Part 4).
- `FSDTests/CancellationRaceStressTests.swift` (Part 6).
- `FSDTests/M5ReliabilityTests.swift` (Part 7).
- `FSDTests/CaptureErrorBoundaryTests.swift` (Part 8).

Tests (corrected):
- `FSDTests/ComparisonGUIValidationTests.swift` (removed the unused
  `transientID` variable).
- `FSDTests/MilestoneConditionTests.swift` (`testDebugBuildsExposeTheOverride`
  asserts in DEBUG only and skips under Release).

Project:
- `FSD.xcodeproj/project.pbxproj` (wired the new files).

Docs:
- `docs/PRODUCT_STATE.md`, `docs/MVP_PLAN.md`, `docs/TEST_PLAN.md`,
  `docs/KNOWN_ISSUES.md`, `docs/DECISIONS.md` (ADR-029).

Repository hygiene:
- Removed root scratch: `temp.db*`, `temp2.db*`, `verify_output.txt`,
  `default.profraw`, `modify_schema.py`, `modify_verify.py`,
  `replace_docs.py`, `fix_mount_consent.py`. Retained:
  `modify_comparison_project.py`, `add_files.py`, `add_files.rb`,
  `add_files_raw.py`.

## Known Limitations

- Deferred owner manual acceptance (consolidated session prepared;
  NOT PERFORMED — DEFERRED BY OWNER).
- Stock-macOS NTFS: ENVIRONMENT-BLOCKED — PROVIDER PATH NOT INVALIDATED.
- KI-024: whole-comparison disposal O(n²) at the 1,000,000-entry class;
  root cause identified (missing leading `parent_result_id` index); schema
  fix deferred (would require v8); verified correct at the
  100,202-per-side class.
- KI-019 remainder: no public collision-member detail query for the GUI
  conflict view (GUI follow-up only).
- Bounded visual/VoiceOver observation deferred with manual acceptance.
- HTML export remains deferred (out of M5 scope).
- Xcode AppIntents metadata extraction warning (no AppIntents dependency)
  and XCTest linkage warnings — non-safety toolchain noise, unchanged.
- Release override refusal means isolated-catalog launch probes are a Debug
  affordance by design (ADR-026); reported as-is.

## Exactly One Next Action

Run the independent Codex final pre-MVP audit.
