# Handoff

## Identity

- Project: FSD
- Task: FSD-M4-SCHEMA-SAFETY-FIX-DEEPSEEK-0804-07C
- Case code: M4-SCHEMA-SAFETY-FIX
- Role: WRITER (correction)
- Agent / model: DeepSeek V4 / Claude Code
- Session ID: not exposed by the runtime
- Started: 2026-08-04
- Completed: 2026-08-04T15:53:32+07:00

## Status

Correction task **COMPLETE_WITH_KNOWN_LIMITATIONS**. Schema version 7
(ADR-028) closes both rejection-level findings of the Milestone 4
comparison-core audit:

- **H1 — terminal collision evidence is now immutable.** `comparison_results`
  gained the missing DELETE guard, and `comparison_collision_groups` /
  `comparison_collision_members` gained INSERT/UPDATE/DELETE guards that
  reject direct mutation once a comparison is `complete`, `cancelled` or
  `failed`, while writes stay legal during `running` and whole-comparison
  disposal still cascades without residue. Verified by direct SQLite
  reproduction, by 11 new rejection fixtures in `docs/database/verify.sql`
  (X5-X13), and by the focused Swift suites.
- **H2 — the ExpectedState inventory is now complete.** `ExpectedState` is
  the single canonical inventory of every table (13), trigger (30) and
  index (16), with normalized DDL definition checks for every trigger and
  index. A v7 catalog that is missing a required object — or that keeps the
  name of a safety-critical trigger while substituting its definition — is
  rejected loudly on open. `ExpectedStateInventoryTests` derives the
  canonical object set from `docs/database/schema.sql` and fails on drift in
  either direction.

The remaining items are the bounded medium conditions from the audit
(pathological collision-group memory, aggregate-signature subtree skipping,
collision-member read API, broad concurrency, peak-memory measurement) and
the untouched low conditions. The comparison core awaits an independent
Codex re-audit of this correction before the Gemini visual interface begins.
No GUI work is claimed; no comparison-core audit approval is claimed; no MVP
completion is claimed.

## Repository State

- Root: `/Users/cenvu/DEV/FSD`
- Branch: unavailable — not a Git repository
- Commit: unavailable — not a Git repository
- Git status: `BLOCKED — NOT A REPOSITORY`
- Pre-existing user changes: none known; the audit preserved all milestone
  files and this correction modified only the files listed below.

## Inputs Read

- `handoffs/CURRENT_HANDOFF.md` (the Milestone 4 audit report)
- `docs/AGENT.md`, `docs/PRODUCT_STATE.md`, `docs/MVP_PLAN.md`,
  `docs/DECISIONS.md`, `docs/TEST_PLAN.md`
- `docs/database/schema.sql`, `docs/database/verify.sql`
- `FSD/Catalog/CatalogMigrations.swift`, `FSD/Catalog/CatalogDatabase.swift`
- `FSD/Diff/ComparisonEngine.swift` (collision write paths),
  `FSD/Diff/ComparisonResultRepository.swift` (disposal API)
- Comparison persistence/identity/migration tests and `TestSupport.swift`

## Audit Findings Addressed

1. **H1 (rejection-level) — Terminal collision evidence is mutable.**
   Reproduced in the audit: after a comparison reached `complete`, rows could
   still be inserted into `comparison_collision_groups` and
   `comparison_collision_members`. Now rejected at the SQLite boundary.
2. **H2 (rejection-level) — Incomplete ExpectedState inventory.** The audit
   proved `ExpectedState` covered only a subset of canonical triggers and
   indexes. Now the complete canonical inventory with normalized definition
   checks; the parity test fails on any drift either direction.
3. The audit's GUI-readiness conditions 1 and 2 are resolved by H1 and H2.
   Condition 3 (collision-member read API) remains a bounded follow-up.

## Schema v7 Design (ADR-028)

Seven new triggers, all probing the owning comparison's status:

| Trigger | Guards |
|---|---|
| `trg_comparison_results_delete_guard` | result-row DELETE |
| `trg_comparison_collision_groups_insert_guard` | group INSERT |
| `trg_comparison_collision_groups_update_guard` | group UPDATE |
| `trg_comparison_collision_groups_delete_guard` | group DELETE |
| `trg_comparison_collision_members_insert_guard` | member INSERT |
| `trg_comparison_collision_members_update_guard` | member UPDATE |
| `trg_comparison_collision_members_delete_guard` | member DELETE |

Behavior:

- status `running`: INSERT/UPDATE/DELETE of collision evidence and result
  rows remain legal (the engine writes groups/members during matching;
  covered by `testCollisionGroupAndMemberInsertAreAllowedWhileRunning`,
  `testCollisionEvidenceMutationIsAllowedWhileRunning`,
  `testResultRowDeleteIsAllowedWhileRunning`);
- status `complete`/`cancelled`/`failed`: direct INSERT/UPDATE/DELETE of
  collision groups, collision members, and result rows is rejected; retained
  evidence is untouched (`testCollisionGroupAndMemberMutationIsRejectedAfterEveryTerminalState`,
  `testResultRowDeleteIsRejectedAfterTerminalState` — each iterating over all
  three terminal states);
- deleting the comparison itself through the repository disposal API still
  cascades collision members, collision groups and results without residue
  (`testWholeComparisonDisposalCascadesWithoutResidue`,
  `testTerminalComparisonDisposalStillCascades`);
- the cascade does not trip the DELETE guards: SQLite fires the cascade's
  child-table DELETE triggers only after the parent comparison row is gone,
  so the guard's status probe finds no row. This ordering was verified
  directly against SQLite before the schema change (a minimal parent/child/
  grandchild reproduction) and is pinned by the tests and verify.sql X14.
- snapshots, snapshot entries, and `comparisons` status/summary immutability
  are untouched (ADR-027 guards unchanged; `testGuardsLeaveSnapshotsAndEntriesUntouched`).

## Migration Behavior

- `CatalogMigrations.currentVersion` is 7; `all` is now
  `[migrationToVersion5, migrationToVersion6, migrationToVersion7]`.
- The v6-to-v7 migration is one explicit transactional step (ADR-024): all
  seven `CREATE TRIGGER` statements plus the version row commit together or
  nothing does. A failed migration leaves version 6 recorded with no v7
  object behind
  (`testFailedVersionSevenMigrationRollsBackAndLeavesVersionSixStanding`).
- Version 7 is recorded only after every new object installs successfully
  (version row is the last statement of the migration).
- Existing v6 catalogs converge to the same object state as fresh v7
  catalogs (`testVersionSixMigratesToVersionSeven`,
  `testVersionSixCollisionEvidenceSurvivesMigrationAndIsProtected` — seeded
  v6 collision evidence survives the migration, is protected by the v7
  guards, and is still disposable); v5 and both known v4 variants continue
  through the chain to v7 (`testVersionFiveMigratesToCurrentVersion`, both
  v4 tests, `testFreshAndMigratedSchemasAreEquivalent`).
- Reopen of a current catalog does not replay migrations
  (`testReopeningCurrentVersionDoesNotReplayTheMigrations` now expects
  `[4, 5, 6, 7]`).
- Unsupported future versions remain rejected; versions 1-3 still have no
  fake migration.
- The bundled `schema.sql` resource records version 7 and is still never
  replayed against an existing catalog.

## Terminal Evidence Guards — Reproduction Evidence

Direct SQLite reproduction on a fresh v7 catalog (before the Swift tests were
written): while `running`, group and member INSERT succeeded; after
`UPDATE comparisons SET status = 'complete'`, all seven mutation paths —
group INSERT/UPDATE/DELETE, member INSERT/UPDATE/DELETE, result INSERT —
aborted with the intended messages; `DELETE FROM comparisons` then cascaded
everything to zero rows with `integrity_check = ok`. The same scenario runs
inside `docs/database/verify.sql` (X1-X14) against a fresh schema: 11 new
intended rejections all fired with the exact documented messages.

## ExpectedState Inventory (H2)

- `ExpectedState` now carries: `tables` (13 names), `triggerDefinitions`
  (30 name + canonical-DDL pairs), `indexDefinitions` (16 name + canonical
  DDL pairs), `snapshotColumns` (3 capture-fact columns), `comparisonColumns`
  (`profile_version`), `profileColumns` (`version`). The old name-only
  `triggers`/`indexes` arrays are gone — there is exactly one inventory.
- `CatalogDatabase.verifyCurrentSchemaState()` compares every stored
  trigger/index definition against the canonical one through
  `ExpectedState.normalizedObjectSQL`, which strips comments, `IF NOT
  EXISTS`, case and whitespace (and collapses line breaks), so a same-name
  object with a materially different definition is rejected exactly like a
  missing one. Tables remain name + required-column checks.
- A standalone harness compiled `CatalogMigrations.swift` alone, applied
  `schema.sql` to a fresh database, and confirmed all 46 stored definitions
  normalize equal to the canonical text.
- No content-file hashing or source-payload hashing was added.

## Damaged-Schema Rejection Evidence

Deliberately damaged v7 catalogs are rejected on open with
`schemaStateInvalid` (`ExpectedStateInventoryTests`):

- `DROP INDEX idx_entries_snapshot_parent_sort` → rejected (missing
  baseline index);
- `DROP TRIGGER trg_snapshots_terminal_status_check` → rejected (missing
  baseline trigger);
- `DROP TRIGGER trg_comparison_collision_groups_insert_guard` → rejected
  (missing v7 collision guard);
- same-name substituted `trg_comparisons_terminal_immutable` (dropped and
  recreated with a different body) → rejected by the definition check;
- same-name substituted `trg_comparison_collision_groups_delete_guard` →
  rejected by the definition check.

## Disposal Behavior

`ComparisonResultRepository.deleteComparison` is unchanged: `DELETE FROM
comparisons` inside one transaction. The new DELETE guards do not block it
for running or terminal comparisons; disposal removes collision members,
collision groups and results without residue, leaves snapshots/entries
untouched, and leaves `integrity_check` ok and `foreign_key_check` clean
(verified by tests and verify.sql X14).

## Tests and Build

Environment (identical to the audit baseline):

- Xcode 26.3 (build 17C529); Apple Swift 6.2.4 (swift-driver 1.127.15);
  macOS 15.7.7 (24G720); arm64 MacBook Pro.

Fresh isolated clean/build/test with signing disabled:

```text
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-M4-Safety-Final2-DerivedData \
  CODE_SIGNING_ALLOWED=NO clean build test
```

Results:

- Clean: **SUCCEEDED**.
- Build: **SUCCEEDED**, unsigned local build.
- Test result: **193 total, 191 passed, 0 failed, 2 skipped** (the two
  environment-gated `FilesystemMatrixTests` skips, unchanged).
- 18 new tests added: `TerminalCollisionEvidenceTests` (8),
  `ExpectedStateInventoryTests` (7), and three new migration tests
  (v6-to-v7, v6 evidence survival, v7 rollback); existing migration and
  version assertions updated 6 → 7.
- Test result bundle:
  `/tmp/FSD-M4-Safety-Final2-DerivedData/Logs/Test/Run-FSD-2026.08.04_15-46-59-+0700.xcresult`.
- App: `/tmp/FSD-M4-Safety-Final2-DerivedData/Build/Products/Debug/FSD.app`;
  binary is Mach-O 64-bit arm64; test bundle also arm64.
- Warnings: only the two known toolchain notices — AppIntents metadata
  extraction skipped (no AppIntents dependency) and the XCTest
  deployment-target link notice. No comparison-specific or
  schema-related warning.
- Focused runs also passed separately: SchemaMigrationTests (19),
  TerminalCollisionEvidenceTests (8), ExpectedStateInventoryTests (7).

`docs/database/verify.sql` (fresh schema v7 database):

- 51 intended rejection fixtures fired with the documented messages — 40
  pre-existing plus 11 new v7 fixtures (X5-X13); process exit status 1 is
  the documented, unchanged behavior of the unsuppressed rejection
  fixtures (L1);
- positive fixtures: `schema_version_is_7 = 7`,
  `version7_objects_present = 7`, running-evidence writes succeed (2
  members), disposal cascades groups/members/results to 0 (X14);
- final `PRAGMA integrity_check = ok` and `PRAGMA foreign_key_check` clean.

## Files Changed

Production:

- `FSD/Catalog/CatalogMigrations.swift` — `currentVersion = 7`,
  `migrationToVersion7`, complete `ExpectedState` inventory with normalized
  definition comparisons.
- `FSD/Catalog/CatalogDatabase.swift` — `verifyCurrentSchemaState` uses the
  definition-checked trigger/index inventory; new
  `requireSchemaObject(type:name:canonicalSQL:)`.
- `docs/database/schema.sql` — schema version 7 header, seven v7 guards,
  version row 7.
- `docs/database/verify.sql` — W1 comment corrected; X1-X14 v7 fixtures.

Tests:

- `FSDTests/SchemaSafetyCorrectionTests.swift` — **new file**:
  `TerminalCollisionEvidenceTests`, `ExpectedStateInventoryTests`.
- `FSDTests/SchemaMigrationTests.swift` — fixture derives v6/v5 from the
  v7 schema; version assertions 6 → 7; three new migration tests; v4/v5
  tests now assert v7 objects.
- `FSDTests/JSONExportTests.swift` — `catalogSchemaVersion` assertion now
  uses `CatalogMigrations.currentVersion` (the exporter truthfully emits
  the current version).
- `FSDTests/CatalogDatabaseTests.swift`, `FSDTests/MilestoneConditionTests.swift`,
  `FSDTests/ManualSessionASubstituteTests.swift` — schema-version assertions
  6 → 7.
- `FSD.xcodeproj/project.pbxproj` — wired the new test file following the
  project's explicit-reference convention.

Documentation:

- `docs/DECISIONS.md` — ADR-028 (terminal evidence immutability, schema v7,
  complete inventory).
- `docs/PRODUCT_STATE.md` — schema v7 state, H1/H2 dispositions, re-audit
  pending, remaining medium conditions.
- `docs/MVP_PLAN.md` — Milestone 4 status: correction applied, re-audit
  pending.
- `docs/TEST_PLAN.md` — M4 schema-safety test list; §7 fresh-schema version
  corrected to 7.
- `docs/KNOWN_ISSUES.md` — KI-019 records the pathological collision-group
  memory condition and the collision-member read API / peak-memory follow-ups.

## Remaining Conditions (unchanged, bounded, follow-up)

- M1 — a single pathological equal-key collision group is not page-bounded
  (recorded as KI-019).
- M2 — aggregate-signature subtree skipping is not implemented (KI-016).
- M3 — no public collision-member detail query on the result repository.
- M4 — broad `@unchecked Sendable` remains; no comparison-specific
  concurrency warning emitted.
- L1 — `verify.sql` intentionally exits with process status 1 on rejection
  fixtures (no suppression wrapper); final integrity/FK checks clean.
- L2 — peak memory not measured.
- L3 — two environment-gated matrix tests remain skipped.
- C1 — Manual Session A remains **NOT PERFORMED — DEFERRED BY OWNER**.

## Preservation Confirmed

- Metadata-only comparison; no payload reads; no file-content hashing; no
  classification access; no Magika runtime; no source writes; no network;
  no third-party dependency.
- Completed snapshot immutability and all ADR-023/024/027 constraints
  unchanged; comparison engine, service modes, profiles, transient
  lifecycle, result repository API, and scale fixtures untouched.
- No Git init, commit, push, or GitHub access.

## Manual Testing Status

**NOT PERFORMED — DEFERRED BY OWNER.** All evidence above is AUTOMATED
VERIFIED / AGENT-OBSERVED; no manual acceptance was performed or requested.

## Decisions

- Schema v7 and ADR-028 are the canonical record of the H1/H2 correction;
  the schema version truthfully identifies the object inventory again.
- The disposal-safe discriminator is the comparison row's absence during
  cascade, verified directly against SQLite — no marker, no status rewrite,
  no weakening of the terminal guards.
- One complete canonical inventory (ExpectedState with definitions) plus a
  schema.sql parity test, rather than two manually maintained lists.

## Exactly One Next Action

Run an independent Codex re-audit of the Milestone 4 schema-safety
correction (H1/H2 disposition, schema v7, migration chain, damaged-catalog
rejection, disposal, and the focused regression suites).

## Safe Resume Boundary

The schema boundary: v7 is the current version; v4/v5/v6 catalogs migrate
transactionally through the chain; fresh and migrated catalogs converge;
terminal evidence is immutable; disposal works. The comparison engine,
modes, profiles, and scale fixtures are untouched and green. Resume with the
independent re-audit.
