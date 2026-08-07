# FSD — Milestone 4 Schema-Safety Correction Re-Audit

**Task ID:** FSD-M4-SCHEMA-SAFETY-REAUDIT-0804-07D  
**Role:** Reviewer (A — Audit)  
**Date:** 2026-08-04  
**Schema version under audit:** 7 (ADR-028)  
**Previous writer session:** DeepSeek schema-safety correction (CURRENT_HANDOFF.md)  

---

## Verdict

### **APPROVE**

Both rejection-level defects (H1, H2) are closed. The comparison backend contract
is safe and complete enough for Gemini to begin the visual comparison interface.

No findings require code changes before GUI work begins.

---

## Audit Scope

This audit independently re-verified the focused Milestone 4 schema-safety
correction across 9 areas, as specified in the task brief. All production source
files were read; no production code was modified.

**Correction boundary files:**
- [CatalogMigrations.swift](file:///Users/cenvu/DEV/FSD/FSD/Catalog/CatalogMigrations.swift) — v7 migration + complete ExpectedState inventory
- [CatalogDatabase.swift](file:///Users/cenvu/DEV/FSD/FSD/Catalog/CatalogDatabase.swift) — verifyCurrentSchemaState(), requireSchemaObject()
- [ComparisonResultRepository.swift](file:///Users/cenvu/DEV/FSD/FSD/Diff/ComparisonResultRepository.swift) — read-side API and disposal
- [ComparisonEngine.swift](file:///Users/cenvu/DEV/FSD/FSD/Diff/ComparisonEngine.swift) — collision evidence writes
- [schema.sql](file:///Users/cenvu/DEV/FSD/docs/database/schema.sql) — canonical DDL
- [verify.sql](file:///Users/cenvu/DEV/FSD/docs/database/verify.sql) — X1-X14 fixtures
- [SchemaSafetyCorrectionTests.swift](file:///Users/cenvu/DEV/FSD/FSDTests/SchemaSafetyCorrectionTests.swift) — TerminalCollisionEvidenceTests + ExpectedStateInventoryTests
- [SchemaMigrationTests.swift](file:///Users/cenvu/DEV/FSD/FSDTests/SchemaMigrationTests.swift) — v6→v7 migration, v4/v5 chain, rollback, equivalence

---

## Area 1 — Clean Reproduction

**Status: PASS** — AUTOMATED VERIFIED

Clean build and test run from an isolated DerivedData directory:

```
xcodebuild clean build-for-testing … -derivedDataPath .gemini-derived-data
```

Build: **succeeded** (only Xcode SDK linker warnings, zero errors).

Targeted test execution:
- `SchemaMigrationTests`: **19 tests, 0 failures** (1.852 s)
- `ExpectedStateInventoryTests`: **7 tests, 0 failures** (0.535 s)
- `TerminalCollisionEvidenceTests`: **8 tests, 0 failures** (0.443 s)
- **Total: 34 tests, 0 failures**

All correction-boundary tests pass on a clean build.

---

## Area 2 — H1: Terminal Collision Evidence Immutability

**Status: H1 IS CLOSED** — AUTOMATED VERIFIED

### What was broken (ADR-027 gap)
ADR-027 guarded `comparisons` status/counts and `comparison_results` INSERT/UPDATE,
but NOT:
- `comparison_results` DELETE
- `comparison_collision_groups` INSERT/UPDATE/DELETE
- `comparison_collision_members` INSERT/UPDATE/DELETE

### What v7 adds (ADR-028)
Seven triggers, verified present in all three canonical sources:

| # | Trigger | Table | Operation | Status probe |
|---|---------|-------|-----------|--------------|
| 1 | `trg_comparison_results_delete_guard` | comparison_results | DELETE | direct comparison_id |
| 2 | `trg_comparison_collision_groups_insert_guard` | comparison_collision_groups | INSERT | direct comparison_id |
| 3 | `trg_comparison_collision_groups_update_guard` | comparison_collision_groups | UPDATE | direct comparison_id |
| 4 | `trg_comparison_collision_groups_delete_guard` | comparison_collision_groups | DELETE | direct comparison_id |
| 5 | `trg_comparison_collision_members_insert_guard` | comparison_collision_members | INSERT | JOIN through groups |
| 6 | `trg_comparison_collision_members_update_guard` | comparison_collision_members | UPDATE | JOIN through groups |
| 7 | `trg_comparison_collision_members_delete_guard` | comparison_collision_members | DELETE | JOIN through groups |

### Verification

1. **schema.sql** lines 692-745: all 7 triggers present with correct DDL. ✓
2. **CatalogMigrations.migrationToVersion7** lines 192-255: all 7 CREATE TRIGGER statements match schema.sql. ✓
3. **CatalogMigrations.ExpectedState.triggerDefinitions** lines 326-339: all 7 trigger names and DDL present. ✓
4. **verify.sql** X1-X14: fixtures exercise every path — running writes allowed (X3), terminal INSERT/UPDATE/DELETE rejected for groups, members and results (X5-X11), cancelled/failed also guarded (X12-X13), disposal cascades cleanly (X14). ✓
5. **TerminalCollisionEvidenceTests**: 8 tests exercising:
   - running-phase writes succeed (group/member INSERT, UPDATE, DELETE; result DELETE)
   - terminal rejection across all 3 terminal states × all 6 mutation types (INSERT/UPDATE/DELETE on groups and members) + result DELETE
   - evidence untouched after rejected mutations
   - disposal cascade without residue (running and terminal)
   - integrity_check + foreign_key_check clean after disposal
   - snapshots and entries untouched by the guards

### Member trigger JOIN path
`comparison_collision_members` has no `comparison_id` column; the triggers correctly
JOIN through `comparison_collision_groups` → `comparisons` to reach the status.
During disposal, the cascade chain is:
1. Comparison deleted → groups CASCADE (comparison row already gone) → members CASCADE
2. Group DELETE trigger fires, probes `SELECT status FROM comparisons WHERE id = OLD.comparison_id` → NULL (row gone) → not IN terminal set → cascade proceeds.
3. Member DELETE trigger fires with same probe through JOIN → NULL → proceeds.

This is the correct SQLite behavior verified by tests.

---

## Area 3 — H2: ExpectedState Inventory Completeness

**Status: H2 IS CLOSED** — AUTOMATED VERIFIED

### What was broken
`ExpectedState` listed only a subset of canonical objects, so a catalog reporting
the current version could silently run without required objects.

### What v7 does
`ExpectedState` now carries:
- **13 tables**: exact match with schema.sql `CREATE TABLE` count ✓
- **30 triggers**: exact match with schema.sql `CREATE TRIGGER` count (each with full DDL) ✓
- **16 indexes**: exact match with schema.sql `CREATE INDEX` count (each with full DDL) ✓
- **3 snapshot columns** (capture-time volume facts)
- **1 comparison column** (`profile_version`)
- **1 profile column** (`version`)

### Verification

1. **Static count match**: `grep -c 'CREATE TRIGGER' schema.sql` = 30; `grep -c '"trg_' CatalogMigrations.swift` = 30. Same for indexes (16) and tables (13). ✓
2. **ExpectedStateInventoryTests.testExpectedStateCoversTheCompleteCanonicalObjectInventory**: parses schema.sql, extracts trigger/index/table names, compares against ExpectedState sets in both directions. PASS ✓
3. **testExpectedStateDefinitionsMatchTheCanonicalSchemaText**: for every trigger and index, normalizes both the schema.sql DDL and the ExpectedState DDL, asserts equality. PASS ✓
4. **normalizedObjectSQL** correctly strips comments, `IF NOT EXISTS`, collapses whitespace, lowercases, and removes trailing semicolons. Code-reviewed. ✓
5. **Damaged catalog rejection tests**: 5 tests prove that a catalog reporting v7 is rejected when:
   - a baseline index is dropped → `schemaStateInvalid` mentioning the index ✓
   - a baseline trigger is dropped → same ✓
   - a v7 collision guard is dropped → same ✓
   - a safety trigger is replaced with same-name but different DDL → rejected by definition comparison ✓
   - a v7 guard is replaced with same-name but different DDL → same ✓

---

## Area 4 — Schema Version 7 Migration

**Status: PASS** — AUTOMATED VERIFIED

- `migrationToVersion7` contains exactly 7 `CREATE TRIGGER` statements (no `IF NOT EXISTS` — none can pre-exist in a v6 catalog). ✓
- Migration is one atomic transaction: all 7 triggers + version row commit or rollback together. ✓
- `testVersionSixMigratesToVersionSeven`: v6 catalog migrates to v7, all 7 triggers present, integrity clean. PASS ✓
- `testVersionSixCollisionEvidenceSurvivesMigrationAndIsProtected`: existing v6 collision evidence survives migration and is protected by v7 guards; disposal still cascades. PASS ✓
- `testFailedVersionSevenMigrationRollsBackAndLeavesVersionSixStanding`: broken v7 migration leaves version 6 recorded, no partial v7 objects. PASS ✓

---

## Area 5 — Full Migration Chain

**Status: PASS** — AUTOMATED VERIFIED

- v4 (both variants) → v5 → v6 → v7: all tests pass ✓
- v5 → v6 → v7: PASS ✓
- Fresh v7 and migrated v7 schemas are equivalent (tables, triggers, indexes, columns): `testFreshAndMigratedSchemasAreEquivalent`, `testFreshAndVersionFiveMigratedSchemasAreEquivalent` both PASS ✓
- Reopen without replay: PASS ✓
- Existing data survives all migration paths: PASS ✓

---

## Area 6 — Disposal Safety

**Status: PASS** — AUTOMATED VERIFIED

### DELETE-guard disposal design
The DELETE guards on comparison_results, comparison_collision_groups, and
comparison_collision_members all probe the owning comparison's status via a SELECT.
When a comparison is deleted:
1. The comparison row is removed first.
2. CASCADE fires on child tables.
3. Each child's BEFORE DELETE trigger probes for the comparison's status.
4. The probe returns NULL (row gone) → NULL NOT IN ('complete','cancelled','failed') → cascade proceeds.

This is pinned by:
- `testWholeComparisonDisposalCascadesWithoutResidue` — running comparison ✓
- `testTerminalComparisonDisposalStillCascades` — completed comparison ✓
- verify.sql X14 — explicit disposal of a terminal comparison, all residue counts = 0 ✓
- `ComparisonResultRepository.deleteComparison()` — the only disposal path, uses `DELETE FROM comparisons WHERE id = ?` inside a transaction ✓

---

## Area 7 — verifyCurrentSchemaState() Coverage

**Status: PASS** — AUTOMATED VERIFIED

`verifyCurrentSchemaState()` (CatalogDatabase.swift lines 317-341) checks:
1. Every table in `ExpectedState.tables` exists ✓
2. Every trigger in `ExpectedState.triggerDefinitions` exists AND its stored DDL normalizes equal to the canonical DDL ✓
3. Every index in `ExpectedState.indexDefinitions` exists AND its stored DDL normalizes equal ✓
4. Every column in `ExpectedState.snapshotColumns`, `comparisonColumns`, `profileColumns` exists ✓

This runs on **every open** (fresh or migrated), not just after migration. A version number is never taken as proof of a schema. ✓

---

## Area 8 — ComparisonEngine Integration

**Status: PASS** — INFERRED + AUTOMATED VERIFIED

The engine writes collision evidence during the `running` phase:
- `insertGroups()` (lines 445-466) creates collision groups and members ✓
- The engine terminates via `terminalize()` which transitions to complete/cancelled/failed ✓
- After termination, the v7 guards reject any direct mutation ✓
- The engine never mutates evidence after calling `terminalize()` ✓

The engine's write path is compatible with the v7 guards because:
1. It only writes while the comparison status is `running` ✓
2. It transitions to a terminal state exactly once, atomically ✓
3. It never touches evidence after the terminal transition ✓

---

## Area 9 — Backend API Readiness for Gemini GUI

**Status: READY** — The comparison backend contract is safe and complete.

The GUI can consume:
- `ComparisonResultRepository.listComparisons()` → list of ComparisonRecord ✓
- `ComparisonResultRepository.record(id:)` → one ComparisonRecord ✓
- `ComparisonResultRepository.results(comparisonID:filter:offset:limit:)` → paged ComparisonResultPage ✓
- `ComparisonResultRepository.navigate(comparisonID:filter:from:direction:)` → deterministic next/previous ✓
- `ComparisonResultRepository.fieldDifferences(for:comparisonID:)` → field-level differences ✓
- `ComparisonResultRepository.entryMetadata(id:snapshotID:)` → side metadata for detail panes ✓
- `ComparisonResultRepository.deleteComparison(_:)` → disposal ✓
- `ComparisonResultRepository.resultCounts(comparisonID:)` → per-type counts ✓

All return immutable model types (`ComparisonRecord`, `ComparisonResultRow`,
`ComparisonResultPage`, `SideMetadata`, `FieldDifference`). No raw database
rows leave the repository. The schema guarantees that a terminal comparison's
evidence is frozen, so the GUI can cache and display results without worrying
about concurrent mutation.

The canonical orientation (ADR-027): left = reference/"before", right = "after".

---

## Summary of Evidence

| Area | Status | Evidence Level |
|------|--------|----------------|
| 1. Clean Reproduction | PASS | AUTOMATED VERIFIED |
| 2. H1 — Terminal Evidence Immutability | CLOSED | AUTOMATED VERIFIED |
| 3. H2 — ExpectedState Completeness | CLOSED | AUTOMATED VERIFIED |
| 4. v7 Migration | PASS | AUTOMATED VERIFIED |
| 5. Full Migration Chain | PASS | AUTOMATED VERIFIED |
| 6. Disposal Safety | PASS | AUTOMATED VERIFIED |
| 7. verifyCurrentSchemaState() | PASS | AUTOMATED VERIFIED |
| 8. Engine Integration | PASS | INFERRED + AUTOMATED VERIFIED |
| 9. API Readiness for GUI | READY | AUTOMATED VERIFIED |

**34 tests, 0 failures** across the correction boundary.

---

## Findings

No rejection-level, high-severity, or medium-severity findings.

### Low-severity observations (informational, no action required before GUI)

1. **Linker warnings**: macOS 13.0 deployment target links against Xcode 14.0+
   XCTest dylibs. Cosmetic; no runtime impact on tests.
2. **The `CaptureCancellationToken` type alias** in ComparisonEngine.swift
   (`terminalize` accepts `CaptureCancellationToken` but the parameter is named
   `token: ComparisonCancellationToken`): this is a shared type alias, not a bug;
   the comparison token extends the capture token. No action needed.

---

## Decision Gate

Per the task brief:

> If approved, the next step is for Gemini to begin the visual comparison
> interface implementation.

**Verdict: APPROVE.** The schema-safety correction is complete. Both H1 and H2
are closed. The comparison backend contract is safe and ready for the GUI.
Gemini may proceed with the visual comparison interface.
