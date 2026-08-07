# Handoff — FSD-M5 Schema v8 Disposal Performance Fix

Task: `FSD-M5-SCHEMA-V8-DISPOSAL-FIX-0805-16`
Role: WRITER / Coding
Status: COMPLETE
Date: 2026-08-05 (Asia/Ho_Chi_Minh)

## Outcome

KI-024 is fixed with the smallest additive schema correction. The catalog is
now schema version 8. The new application-owned index
`idx_comparison_results_parent_result_id` leads with `parent_result_id`; the
existing composite index remains unchanged. No comparison semantics, profile,
outcome, capture, cancellation, transient-retention or GUI behavior changed.

## Schema v8 design

Canonical DDL:

```sql
CREATE INDEX idx_comparison_results_parent_result_id
ON comparison_results(parent_result_id);
```

The index supports SQLite's child lookup for the self-referencing
`comparison_results.parent_result_id` foreign key during `ON DELETE CASCADE`.
The existing `idx_comparison_results_parent` composite index is retained.
Fresh `docs/database/schema.sql` records version 8.

## Migration

`CatalogMigrations.currentVersion` is 8 and `migrationToVersion8` is one
explicit v7-to-v8 migration. It runs inside the existing `BEGIN IMMEDIATE`
transaction mechanism. The index is created before the version-8 row is
recorded; failure rolls back both. The focused rollback test leaves version 7
recorded and no partial v8 index. Reopen does not replay a current catalog.
Fresh catalogs and v4, v5, v6 and v7 catalogs converge to the same current
object state. Unsupported future versions and versions below the migration
floor remain rejected. Existing v5, v6 and v7 safety objects remain present.

## ExpectedState and damaged-schema coverage

The single canonical `CatalogMigrations.ExpectedState` inventory now includes
the new index with normalized canonical DDL. Current-schema verification still
runs on every open. Automated tests cover:

- fresh schema v8 and v7-to-v8 migration;
- v6-to-v8, v5-to-v8 and both known v4-to-v8 chains;
- failed v8 migration rollback and reopen without replay;
- fresh/migrated equivalence, integrity and foreign-key checks;
- missing new index;
- same-name index with wrong columns;
- same-name index with wrong ordering;
- unsupported future schema and versions below the supported floor;
- two-way parity between `schema.sql` and ExpectedState.

## Query-plan evidence

Automated isolated-catalog evidence for
`SELECT id FROM comparison_results WHERE parent_result_id = ?`:

```text
SEARCH comparison_results USING COVERING INDEX
idx_comparison_results_parent_result_id (parent_result_id=?)
```

The plan no longer reports a full scan. EXPLAIN output is validation evidence
only; production behavior does not depend on it.

## One-million explicit disposal

`FinalScaleComparisonTests.testOneMillionExplicitDisposalCompletesWithCleanCascade`
uses direct synthetic SQLite metadata insertion, no physical files, exactly
1,000,000 `comparison_results` rows, collision evidence, and ordinary
completed snapshots/entries that must survive. It calls the public
`ComparisonResultRepository.deleteComparison` API.

Release evidence: 9.930 seconds, below the 120-second threshold. Database
size was 192,974,848 bytes before and after. The comparison, results, collision
groups and members were removed; ordinary snapshots and entries remained;
classification rows stayed zero; residue was zero; integrity was `ok`; and
foreign-key checks were clean. Debug runs were correctness-only and logged
10.669 seconds in the final full-suite run.

## One-million automatic live-workspace close

`FinalScaleComparisonTests.testOneMillionAutomaticLiveWorkspaceCloseCompletesAndReleasesTransient`
seeds a controlled transient/user comparison with exactly 1,000,000 result
rows and collision evidence, then invokes the canonical
`TransientSnapshotLifecycle.closeWorkspace()` path.

Release evidence: 10.018 seconds, below the 120-second threshold. The live
comparison and all result/evidence rows were removed; transient snapshots
were cleaned according to policy; the ordinary user snapshot and its entries
remained; classification rows stayed zero; integrity was `ok`; foreign-key
checks were clean; and a subsequent small write completed in 0.000 seconds.
Debug correctness-only evidence logged 10.420 seconds in the final full-suite
run. No writer remained blocked.

## Correctness, preservation and interruption

Existing comparison semantics, deterministic ordering, outcome counts, result
paging, navigation, collision behavior, terminal immutability, completed
snapshot immutability, explicit disposal and workspace-close semantics remain
covered by the regression suite and passed. The new index changes disposal
performance only. The migration rollback is transactionally tested. A
separate process-kill during a million-row disposal was not run; no new
cancellation feature was introduced.

## Builds and tests

Machine/toolchain context:

- host: macOS 15.7.7, arm64
- Xcode 26.3 (17C529)
- Swift 6.2.4 / swift-driver 1.127.15
- schema version: 8
- executable architecture: Debug and Release app binaries both Mach-O arm64

Build paths:

- Debug clean build: `/tmp/FSD-M5-SchemaV8-Debug-Clean`
- Release clean build: `/tmp/FSD-M5-SchemaV8-Release`

Verification:

- fresh Debug clean build: AUTOMATED VERIFIED
- fresh Release clean build: AUTOMATED VERIFIED
- full Debug XCTest suite: 284 executed, 284 passed, 0 failed, 3 skipped;
  skipped because `FSD_PROBE_CATALOG`/marker was absent (1 test) and
  `FSD_MATRIX_SOURCE`/`FSD_MATRIX_OFFLINE_CATALOG` were unset (2 tests)
- focused Debug correction smoke: 48 executed, 48 passed, 0 failed, 0 skipped
- focused Release schema/drift/disposal suites: 33 executed, 33 passed, 0
  failed, 0 skipped
- query-plan, migration, drift, explicit disposal and automatic close:
  AUTOMATED VERIFIED

Warnings observed were the existing AppIntents metadata-extraction skip when
no AppIntents dependency is present and the existing XCTest deployment-target
linker warning. No build failed on a warning.

## Documentation and files changed

Production/tests:

- `FSD/Catalog/CatalogMigrations.swift`
- `FSDTests/SchemaMigrationTests.swift`
- `FSDTests/SchemaSafetyCorrectionTests.swift`
- `FSDTests/FinalScaleComparisonTests.swift`
- `FSDTests/CatalogDatabaseTests.swift`
- `FSDTests/ComparisonGUISourceBoundaryTests.swift`
- `FSDTests/FinalScaleSnapshotTests.swift`
- `FSDTests/M5ReliabilityTests.swift`
- `FSDTests/ManualSessionASubstituteTests.swift`
- `FSDTests/MilestoneConditionTests.swift`

Canonical documentation/schema:

- `docs/database/schema.sql`
- `docs/database/verify.sql`
- `docs/PRODUCT_STATE.md`
- `docs/MVP_PLAN.md`
- `docs/TEST_PLAN.md`
- `docs/KNOWN_ISSUES.md`
- `docs/DECISIONS.md` (ADR-030)

Handoff artifacts:

- `handoffs/FSD_M5_SCHEMA_V8_DISPOSAL_FIX_C_20260805-114256.md`
- `handoffs/CURRENT_HANDOFF.md` (full copy with required update timestamp)

No Git repository was initialized, and no commit, push, GitHub access,
packaging, signing, notarization, dependency installation, physical-device
access or unrelated artifact deletion was performed. `.gemini-derived-data`
and the separate catalog-startup error wording finding remain preserved.

## Remaining limitations

- Manual acceptance: NOT PERFORMED — DEFERRED BY OWNER.
- The separate startup-error surface finding remains non-blocking and was not
  repaired in this task.
- `.gemini-derived-data` hygiene observation remains preserved.
- MVP approval is not claimed; Phase 1.5 has not started.
- The focused independent re-audit has not yet been performed.

## Exactly one next action

Run an independent Codex focused re-audit of schema v8 and one-million
comparison disposal.
