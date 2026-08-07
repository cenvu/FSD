# Handoff

## Identity

Task: `FSD-M5-SCHEMA-V8-DISPOSAL-REAUDIT-0805-17`
Role: REVIEWER / Audit
Status: COMPLETE
Date: 2026-08-05 (Asia/Ho_Chi_Minh)

## AUDIT VERDICT: **APPROVE WITH CONDITIONS**

Schema version 8, the v7-to-v8 migration, `ExpectedState` drift protection, the
query-plan correction, both one-million-row disposal paths, and full
regression safety are all independently reproduced and sound. The only
condition is non-safety: the Writer's Handoff and `docs/TEST_PLAN.md` state
the full Debug suite as "284 executed, 284 passed, 0 failed, 3 skipped," which
is arithmetically self-contradictory. The independently reproduced, xcresult-
verified truth is **284 executed, 281 passed, 0 failed, 3 skipped** (284 = 281
+ 3). The underlying suite is fully green — this is a wording/reporting defect
only, not a functional regression — but it should be corrected in
`docs/TEST_PLAN.md` before or alongside the next task. This condition does not
block Phase 1.5.

## Scope and method

This audit re-examined only the schema-v8/KI-024 correction, independently of
the Writer's claims, per `handoffs/FSD_M5_SCHEMA_V8_DISPOSAL_FIX_C_20260805-114256.md`.
No production Swift, test, schema, migration, or Xcode-project file was
modified. All verification was either direct SQLite inspection in scratch
databases outside the repository (`/tmp/FSD-Reaudit-sqlite/`, deleted at the
end of this session) or execution of the project's own existing, unmodified
XCTest suite in fresh, isolated `-derivedDataPath` locations. No new test was
written; none was needed — `SchemaMigrationTests`, `TerminalCollisionEvidenceTests`,
`ExpectedStateInventoryTests` and `FinalScaleComparisonTests` (all pre-existing,
authored by the Writer) already cover every required verification point.

This session was paused once mid-audit (owner's machine needed to power down)
and resumed in the same conversation. The interrupted first attempt at the
full Debug suite (and a separately interrupted very first attempt, lost to an
earlier session/harness reset before the pause) were both discarded and
**not** counted as evidence; the full Debug suite reported below is a single,
complete, uninterrupted run validated via `xcresulttool`, not a log tail.

## 1. Schema v8 Audit — PASS, AUTOMATED VERIFIED

Applied `docs/database/schema.sql` verbatim to a fresh scratch SQLite database:

- `SELECT MAX(version) FROM schema_migrations` → **8**.
- `PRAGMA integrity_check` → **ok**. `PRAGMA foreign_key_check` → **empty**.
- `idx_comparison_results_parent_result_id` exists **exactly once**, DDL
  `CREATE INDEX idx_comparison_results_parent_result_id ON comparison_results(parent_result_id)`
  — `parent_result_id` is its sole leading (and only) column.
- The existing composite index `idx_comparison_results_parent
  (comparison_id, parent_result_id, result_type, display_name)` is present
  and unchanged.
- No unrelated table, trigger or index differs from the version-7 baseline;
  `docs/database/schema.sql`'s own header comment enumerates exactly the one
  version-8 addition and this audit found nothing beyond it.
- **Bundled schema resource identity**: the Xcode project's `schema.sql`
  file reference literally points at `path = docs/database/schema.sql`
  (`FSD.xcodeproj/project.pbxproj:92`) — there is no separate bundled copy
  that could drift. Confirmed by `diff`: the `schema.sql` inside both the
  freshly built Debug and Release `.app` bundles' `Contents/Resources/` is
  byte-identical to `docs/database/schema.sql`.

## 2. Migration Audit — PASS, AUTOMATED VERIFIED

Independently executed (Release, `ENABLE_TESTABILITY=YES`,
`SchemaMigrationTests`, 21/21 passed, 0.912s):

- `testPreMilestone2Version4MigratesToCurrentVersion` /
  `testPostMilestone2Version4MigratesToCurrentVersion` — both known v4
  variants converge through v5→v6→v7→v8 to the current version.
- `testVersionFiveMigratesToCurrentVersion`,
  `testVersionSixMigratesToVersionSeven` — v5 and v6 catalogs continue
  through the chain to v8 (verified by inspecting `CatalogMigrations.all`:
  migrations are applied in ascending order for every version greater than
  the catalog's current version, so a v6 catalog opened today receives both
  the v7 and v8 steps in one open).
- `testFailedMigrationRollsBackAndLeavesRecordedVersionUnchanged` (v4→v5),
  `testFailedVersionSixMigrationRollsBackAndLeavesVersionFiveStanding`,
  `testFailedVersionSevenMigrationRollsBackAndLeavesVersionSixStanding`,
  `testFailedVersionEightMigrationRollsBackAndLeavesVersionSevenStanding` —
  a deliberately broken v7→v8 migration (valid `CREATE INDEX` statement
  followed by a statement referencing a nonexistent table) leaves
  `schema_migrations` at 7 and **zero** trace of
  `idx_comparison_results_parent_result_id`; reopening then completes the
  migration correctly. Source-level confirmation:
  `CatalogDatabase.apply(_:)` (`FSD/Catalog/CatalogDatabase.swift:292-308`)
  wraps every migration statement plus the version-row insert in one
  `BEGIN IMMEDIATE … COMMIT`, rolling back atomically on any failure — the
  index is created *before* the version-8 row is written, and both commit or
  neither does.
- `testReopeningCurrentVersionDoesNotReplayTheMigrations` — a v8 catalog's
  `schema_migrations` row count and `applied_at` timestamps are unchanged
  across a second open.
- `testFreshAndMigratedSchemasAreEquivalent`,
  `testFreshAndVersionFiveMigratedSchemasAreEquivalent`,
  `testFreshAndMigratedEnforceIdenticalImmutableEntryRules` — fresh and
  migrated catalogs have identical table/trigger/index inventories and
  enforce identical immutability rules.
- `testVersionsBelowFourAreRejectedRatherThanGuessedAt` (versions 1-3),
  `testUnsupportedFutureVersionStillFailsClearly` (version 99) — both
  rejected with `CatalogDatabaseError.unsupportedSchemaVersion`, confirmed
  by source: `CatalogDatabase.bootstrapIfNeeded` compares against
  `CatalogMigrations.oldestMigratableVersion` (4) and
  `currentSchemaVersion` (8) before attempting any migration.

## 3. ExpectedState and Drift Audit — PASS, AUTOMATED VERIFIED

Independently executed (Release, `ExpectedStateInventoryTests`, 10/10
passed, 0.434s):

- `testExpectedStateCoversTheCompleteCanonicalObjectInventory`,
  `testExpectedStateDefinitionsMatchTheCanonicalSchemaText` — two-way parity
  between `CatalogMigrations.ExpectedState` and `docs/database/schema.sql`
  confirmed; `idx_comparison_results_parent_result_id`'s canonical DDL is
  present in `ExpectedState.indexDefinitions`
  (`FSD/Catalog/CatalogMigrations.swift:392-393`).
- `testDamagedV8CatalogRejectsMissingBaselineIndex`,
  `testDamagedV8CatalogRejectsMissingBaselineTrigger`,
  `testDamagedV8CatalogRejectsMissingV7CollisionGuard`,
  `testDamagedV8CatalogRejectsSameNameSubstitutedSafetyTrigger`,
  `testDamagedV8CatalogRejectsSameNameSubstitutedV7Guard` — pre-existing
  (version-5/6/7) safety objects are still drift-checked, not just the new
  index.
- `testDamagedV8CatalogRejectsMissingParentResultCascadeIndex` — dropping
  the index causes the next open to fail with
  `schemaStateInvalid("missing index idx_comparison_results_parent_result_id")`.
- `testDamagedV8CatalogRejectsSameNameParentResultIndexWithWrongColumns` —
  an index of the same name rebuilt on `(comparison_id)` instead of
  `(parent_result_id)` is rejected.
- `testDamagedV8CatalogRejectsSameNameParentResultIndexWithWrongOrdering` —
  an index of the same name rebuilt as `(parent_result_id DESC)` is
  rejected (the index has one column, so `DESC` vs. the canonical implicit
  `ASC` is the only ordering degree of freedom available; this is the
  correct interpretation for a single-column index).

`CatalogDatabase.verifyCurrentSchemaState()` (`CatalogDatabase.swift:317-342`)
runs this check on **every** open, fresh or migrated, comparing normalized
DDL text — confirmed by source read, not merely test-inferred.

## 4. Query-Plan Reproduction — PASS, AUTOMATED VERIFIED

Independent scratch-database check (outside the repository, deleted after
use), applying `docs/database/schema.sql` verbatim:

```
EXPLAIN QUERY PLAN SELECT id FROM comparison_results WHERE parent_result_id = 1;
`--SEARCH comparison_results USING COVERING INDEX idx_comparison_results_parent_result_id (parent_result_id=?)
```

Control catalog (scratch-only, index dropped, never touching the project):

```
EXPLAIN QUERY PLAN SELECT id FROM comparison_results WHERE parent_result_id = 1;
`--SCAN comparison_results USING COVERING INDEX idx_comparison_results_parent
```

Confirms the root-cause diagnosis exactly: without the dedicated index,
SQLite falls back to a full index scan of the composite index (which cannot
serve a `parent_result_id`-only predicate because `comparison_id` leads it) —
functionally a full-table scan for this query shape. Timed confirmation in
the same scratch environment: a 200,000-row cascade delete **with** the new
index completed in **1.016 s**; a 20,000-row cascade delete **without** it
took **12.707 s** (consistent with the O(n²) baseline previously measured in
`handoffs/FSD_M5_FINAL_PREMVP_AUDIT_R_20260805-093249.md`: 20,000 rows without
an index measured 12.97 s there).

Production reproduction: `SchemaMigrationTests.testParentResultCascadeLookupUsesTheDedicatedLeadingIndex`
passed, asserting the plan contains `idx_comparison_results_parent_result_id`
and does not contain `SCAN comparison_results`.

## 5. Explicit One-Million Disposal — PASS, AUTOMATED VERIFIED

`FinalScaleComparisonTests.testOneMillionExplicitDisposalCompletesWithCleanCascade`,
independently executed under Release (`ENABLE_TESTABILITY=YES`, isolated
DerivedData):

- **Duration: 16.932 s** (below the 120 s threshold; Writer's Handoff
  claimed 9.930 s for the same test — see §9 "Notable but non-blocking
  discrepancy" below).
- `db_bytes=192974848->192974848` (file size unchanged — WAL/free-page
  reuse, not a residue signal).
- Comparison record, all `comparison_results`, collision groups and members
  removed (all asserted counts 0); ordinary snapshots/entries preserved
  (fingerprints unchanged before/after); `entry_classifications` row count
  0 throughout; `PRAGMA integrity_check` = `ok`; `PRAGMA foreign_key_check`
  empty.
- Debug correctness-only run (same fixture, unoptimized build, full suite
  below): **11.133 s** — consistent with the Release figure, confirming the
  fix is not merely an artifact of `-O`.

## 6. Automatic Live-Workspace Close — PASS, AUTOMATED VERIFIED

`FinalScaleComparisonTests.testOneMillionAutomaticLiveWorkspaceCloseCompletesAndReleasesTransient`,
independently executed under Release, calling the canonical
`TransientSnapshotLifecycle.closeWorkspace()` (the exact production path —
confirmed by source read, `FSD/Catalog/TransientSnapshotLifecycle.swift:140-171`
— not a substitute):

- **Duration: 15.879 s** (below the 120 s threshold; Writer's Handoff
  claimed 10.018 s — same non-blocking discrepancy as §5).
- Live comparison and all result/evidence rows removed; transient snapshot
  cleaned (0 transient snapshots remain); ordinary user snapshot and its 2
  entries remain; `entry_classifications` count 0.
- Subsequent write transaction (insert+delete on `collections`) completed in
  **0.000 s** — no writer left blocked.
- `PRAGMA integrity_check` = `ok`; `PRAGMA foreign_key_check` empty.
- Debug correctness-only run: **10.478 s**.

This is the mandatory path per the task brief — KI-024 occurred during
ordinary workspace close, not only explicit deletion — and it was exercised
through the real `closeWorkspace()` API, not a stand-in.

## 7. Regression Safety — PASS, AUTOMATED VERIFIED

The complete, unmodified test suite exercises regression safety far beyond
the disposal path itself. Every one of the 32 test suites in the full Debug
run passed (0 failures anywhere), including `ComparisonPersistenceTests`
(terminal immutability), `ComparisonGUISourceBoundaryTests` (confirms the
GUI task never touched schema/migrations), `ComparisonSemanticsTests`,
`ComparisonIdentityTests`, `ComparisonScaleTests`, `SnapshotLifecycleTests`,
and `TerminalCollisionEvidenceTests` (collision-evidence guards, disposal
cascade after terminal state).

Determinism cross-check: the one-million-entry comparison's exact
classification counts are **identical** between the Debug and Release runs
(matched 1,000,003 / changed 1,000 / added 1,001 / removed 1,001 / uncertain
601 / ignored 200 / collision groups 500 / members 2,000; 1,003,806 persisted
results) — comparison semantics are unaffected by the schema/index change or
by optimization level. `testMillionEntryRepeatRunIsDeterministic` (Release,
678.654 s) independently confirms a repeat run produces an identical result
fingerprint.

## 8. Build and Test Reproduction — PASS, AUTOMATED VERIFIED

Machine/toolchain context (directly observed this session):

- host: macOS 15.7.7, arm64, MacBook Pro
- Xcode 26.3 (17C529)
- Swift 6.2.4 / swift-driver 1.127.15
- SDK: MacOSX26.2, target arm64-apple-macos13.0
- schema version: 8 (confirmed §1)
- Debug and Release `FSD.app` executables: both `Mach-O 64-bit executable arm64` (confirmed via `file`)

Isolated DerivedData paths used (all outside the repository, all fresh for
this audit):

- Debug clean build: `/tmp/FSD-Reaudit-Debug`
- Release clean build: `/tmp/FSD-Reaudit-Release`
- Full Debug test run: `/tmp/FSD-Reaudit-DebugTest2`
- Focused Release test runs: `/tmp/FSD-Reaudit-ReleaseFocused`

Results (fresh clean/build, then fresh test, each a distinct invocation):

- Fresh Debug clean/build: **AUTOMATED VERIFIED**, `** BUILD SUCCEEDED **`.
- Fresh Release clean/build: **AUTOMATED VERIFIED**, `** BUILD SUCCEEDED **`.
- **Full Debug XCTest suite** (`xcresulttool get test-results summary`,
  bundle `/tmp/FSD-Reaudit-DebugTest2/Logs/Test/Test-FSD-2026.08.05_21-28-35-+0700.xcresult`,
  validated structurally intact — `Info.plist` present, parses as JSON):
  **284 executed, 281 passed, 0 failed, 3 skipped** (`"result" : "Passed"`,
  `"totalTestCount" : 284`, `"passedTests" : 281`, `"skippedTests" : 3`,
  `"failedTests" : 0`). Wall time 3140.403 s test time / 3475.758 s including
  build (~58 min).
  - Exact skip reasons (from the raw log, matching the xcresult):
    `FSDProbeSeedTests.testSeedIsolatedProbeCatalog` — "FSD_PROBE_CATALOG is
    not set and no marker file exists"; `FilesystemMatrixTests.testCaptureExternallyPreparedMountedFilesystem`
    — "FSD_MATRIX_SOURCE is not set"; `FilesystemMatrixTests.testReopenCapturedSnapshotWithTheSourceDetached`
    — "FSD_MATRIX_OFFLINE_CATALOG is not set". All three are intentional,
    environment/marker-gated, non-blocker skips — identical to the prior
    baseline audit's characterization.
  - **This corrects the Writer's Handoff wording** ("284 executed, 284
    passed, 0 failed, 3 skipped" — self-contradictory, since 284 passed + 3
    skipped would require 287 executed). The suite itself is fully green;
    only the summary sentence was wrong. See §9 condition.
- **Focused Release suites** (`ENABLE_TESTABILITY=YES`; two invocations
  because the first `-only-testing` filter used an incorrect class name —
  `SchemaSafetyCorrectionTests.swift` contains classes `TerminalCollisionEvidenceTests`
  and `ExpectedStateInventoryTests`, not a class literally named
  `SchemaSafetyCorrectionTests`; corrected in the second invocation):
  - Run 1 (`SchemaMigrationTests` + `FinalScaleComparisonTests`): xcresult
    `/tmp/FSD-Reaudit-ReleaseFocused/Logs/Test/Test-FSD-2026.08.05_12-28-37-+0700.xcresult`,
    validated via `xcresulttool` — **29 executed, 29 passed, 0 failed, 0
    skipped**.
  - Run 2 (`TerminalCollisionEvidenceTests` + `ExpectedStateInventoryTests`):
    xcresult `/tmp/FSD-Reaudit-ReleaseFocused/Logs/Test/Test-FSD-2026.08.05_13-06-41-+0700.xcresult`,
    validated via `xcresulttool` — **18 executed, 18 passed, 0 failed, 0
    skipped**.
  - **Combined independent focused-Release total: 47 executed, 47 passed, 0
    failed, 0 skipped.**
- Warnings observed (Debug full run and both builds): the existing
  AppIntents metadata-extraction skip ("No AppIntents.framework dependency
  found") and the existing XCTest deployment-target linker warning
  ("building for macOS-13.0, but linking with dylib … built for newer
  version 14.0"), plus routine codesign "not stripping binary because it is
  signed" notices for Apple's own XCTest frameworks. No build failed on a
  warning; no other warning was observed.

**Notable but non-blocking discrepancy:** this audit's independently
measured Release disposal timings (16.932 s explicit / 15.879 s workspace
close) are higher than the Writer's claimed figures (9.930 s / 10.018 s),
and — unusually — higher than this audit's own Debug correctness-only
figures for the same operations (11.133 s / 10.478 s). The most likely
explanation is that both of this audit's Release timings were captured
immediately after roughly 30 minutes of other heavy tests running in the
same long-lived test-host process (`testMillionEntryComparisonCompletesWithExactClassification`,
`testMillionEntryRepeatRunIsDeterministic`, etc.), which accumulate large
temporary SQLite files and OS page-cache/memory pressure ahead of the
disposal tests — a machine-state effect, not a regression in the index fix
itself. All four measurements (Writer's two, this audit's two) clear the
120 s threshold with 7-12× margin, so this does not change the verdict; it
is recorded for completeness because the task requires exact, not vague,
timing evidence.

## 9. Documentation Truth — PASS with one condition

Verified in `docs/PRODUCT_STATE.md`, `docs/MVP_PLAN.md`, `docs/KNOWN_ISSUES.md`
(KI-024), `docs/DECISIONS.md` (ADR-030):

- Schema v8 is stated correctly everywhere checked.
- KI-024 is recorded as "FIXED 2026-08-05; focused independent re-audit
  pending" — accurate as of the start of this session; this Handoff now
  closes that pending item.
- Both one-million disposal figures (explicit and automatic) are recorded
  with their measured values and the 120 s threshold.
- Manual acceptance is recorded as **NOT PERFORMED — DEFERRED BY OWNER**
  everywhere checked; no document claims owner interaction occurred.
- MVP approval is explicitly **not** claimed in `PRODUCT_STATE.md`,
  `MVP_PLAN.md`, or the Writer's Fix Handoff.
- The separate legacy catalog-startup-error wording finding remains
  preserved and tracked (`PRODUCT_STATE.md:139`), not silently marked
  fixed.
- `.gemini-derived-data` is still present at the project root
  (`ls` confirmed), preserved per the standing hygiene observation, not
  deleted by this or the prior session.

**One condition found:** `docs/TEST_PLAN.md:317` states "the full Debug
suite passed **284 executed, 284 passed, 0 failed, 3 skipped**" — the same
self-contradictory wording as the Writer's Handoff (see §8), and here it is
in a canonical document, not just a historical (immutable) Handoff. Per this
project's audit convention (the prior `FSD_M5_FINAL_PREMVP_AUDIT_R_20260805-093249.md`
did not edit canonical docs itself; it reported findings for the next
Writer task to correct), this audit does **not** edit `TEST_PLAN.md` — it is
read-only production/test/documentation scope for this task type — and
instead records the correction here: the accurate figure is **284 executed,
281 passed, 0 failed, 3 skipped**.

## 10. DeepSeek Milestone 5 Schema-v8/Disposal Correction Scorecard

| # | Criterion | Verdict |
|---|---|---|
| 1 | Schema design | PASS |
| 2 | Migration correctness | PASS |
| 3 | ExpectedState/drift protection | PASS |
| 4 | Query-plan correction | PASS |
| 5 | Explicit disposal performance | PASS |
| 6 | Automatic workspace-close performance | PASS |
| 7 | Data-preservation correctness | PASS |
| 8 | Regression safety | PASS |
| 9 | Build/test quality | PARTIAL — suite is fully green (0 failures), but the Writer's own summary line misreports the split between passed and skipped |
| 10 | Handoff/documentation accuracy | PARTIAL — the same test-count wording error also reached `docs/TEST_PLAN.md`, a canonical document |

**8 PASS / 2 PARTIAL / 0 FAIL / 0 NOT VERIFIED, out of 10.**

Independent tests executed this session: fresh Debug build; fresh Release
build; full Debug XCTest suite (284 tests, xcresult-verified); two focused
Release XCTest runs (47 tests total, xcresult-verified); a from-scratch
scratch-SQLite experiment (2 `EXPLAIN QUERY PLAN` checks, 2 timed cascade-
disposal runs with/without the index); direct source verification of 4
production files (`CatalogMigrations.swift`, `CatalogDatabase.swift`,
`ComparisonResultRepository.swift`, `TransientSnapshotLifecycle.swift`) and
the Xcode project file's schema-resource reference.

High findings: **0**.
Medium findings: **1** — the self-contradictory Debug test-count wording
propagated from the Writer's Handoff into `docs/TEST_PLAN.md`, a canonical
document (not merely a historical, immutable Handoff). Non-safety; the
underlying suite is fully green.
Low findings: **1** — independently measured Release disposal timings ran
1.5-2× higher than the Writer's figures (likely machine-state/test-ordering
effect, not a regression); both still clear the threshold by 7-12×. The
pre-existing, previously-disclosed findings (`.gemini-derived-data` hygiene,
separate startup-error wording) remain correctly preserved, not new.

Estimated remaining rework: **SMALL** — correct the one wording line in
`docs/TEST_PLAN.md` (and anywhere else "284 executed, 284 passed" appears)
to "284 executed, 281 passed, 0 failed, 3 skipped." No schema, migration,
test, or production-code change is required.

**Effectiveness rating: EFFECTIVE.** Every quantitative and structural claim
this audit checked — schema version, index DDL and cardinality, migration
chain and rollback behavior, ExpectedState/drift rejection for all five
damage variants including the two new to schema v8, query-plan text, exact
1,000,000-row disposal and workspace-close timings and postconditions, exact
1M-entry classification counts, and build/binary architecture — reproduced
correctly and matched the Writer's substantive claims within expected
machine-to-machine timing variance. The sole finding is a reporting
arithmetic slip that reached one canonical document; it does not touch
safety, correctness, or performance and is trivially correctable.

## Exact Files Changed By This Audit

**None** in `FSD/`, `FSDTests/`, `docs/database/`, or `FSD.xcodeproj/`. This
audit is read-only for production source, tests, schema, migrations, and the
Xcode project, per its scope. The only repository modifications are this
historical Handoff and the overwritten `handoffs/CURRENT_HANDOFF.md`.

Scratch artifacts created and deleted/left outside the repository: isolated
DerivedData paths under `/tmp/FSD-Reaudit-*` and the scratch SQLite
experiment under `/tmp/FSD-Reaudit-sqlite/` — none under
`/Users/cenvu/DEV/FSD`. No Git action was taken (`.git` remains absent,
unchanged, per scope — not initialized by this audit). No signing,
notarization, packaging, dependency installation, or physical-device access
occurred.

## Exactly One Next Action

Begin Phase 1.5 — Magika nullable metadata enrichment implementation. Before
or alongside that work, correct the "284 executed, 284 passed, 0 failed, 3
skipped" wording in `docs/TEST_PLAN.md` to "284 executed, 281 passed, 0
failed, 3 skipped" (non-blocking condition from this audit).
