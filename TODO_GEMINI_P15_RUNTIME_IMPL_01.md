# TODO_GEMINI_P15_RUNTIME_IMPL_01.md — Schema v9 and provider provenance

Prepared by: Tech Lead / Architect (planning only)  
Sequence: 1 of 8  
Major TODO count: **4**  
Risk: **HIGH**  
Execution status: **PLANNING ONLY — separately authorized implementation task required**. Current schema remains v8; this task does not authorize migration or runtime implementation.

## Purpose

Introduce the one approved persistence prerequisite for the runtime: schema version 9 adds `entry_classifications.provider_identifier`, and the typed repository round-trips it without overloading `detector_version` or `model_version`. This slice contains no source reads, provider-contract change, runtime orchestration, UI, helper process, or Magika dependency.

## Prerequisites

- Start from the exact Phase 1.5 audited-design base state and read `handoffs/CURRENT_HANDOFF.md`, `docs/ARCHITECTURE.md` §9/§9a, ADR-031/032, and this file completely.
- Record the freshly verified canonical base commit and confirm the working tree has no unrelated changes. If the environment is not a Git worktree, stop.

## Locked implementation decisions

- Current schema becomes **9**. Migration order is 4→5→6→7→8→9; the version row is written last by the existing transaction machinery.
- The v8→v9 change is exactly one added column: `provider_identifier TEXT` on `entry_classifications`. It is appended after the existing columns so fresh and ALTER-migrated `PRAGMA table_info` order converges.
- The column is **nullable with no default**. Existing v8 rows remain `NULL`; no identity is fabricated and no row is backfilled.
- `EntryClassification.providerIdentifier` is optional because legacy and pre-provider host outcomes can truthfully lack an adapter identity.
- Repository writes for `.classified` require a non-empty provider identifier of at most 256 characters. A provider-executed `.failed` row will supply it in Slice 04. Pre-provider `.sourceChanged` / `.unsupportedEntry` rows may persist `.failed` with `NULL` because no adapter ran. `unavailable` and `cancelled` never write a row.
- `detector_version`, `model_version`, and `provider_identifier` remain three independent fields.
- Append-only behavior and `UNIQUE(entry_id, classification_run_id)` do not change. Do not add update/delete APIs.
- No schema table rebuild, trigger redesign, status-enum expansion, run table, payload/hash/path column, default sentinel, or broader schema work.

## Files/modules the Writer may modify

- `docs/database/schema.sql`
- `docs/database/verify.sql`
- `FSD/Catalog/CatalogMigrations.swift`
- `FSD/Catalog/CatalogDatabase.swift`
- `FSD/Catalog/EntryClassificationRepository.swift`
- `FSDTests/SchemaMigrationTests.swift`
- `FSDTests/SchemaSafetyCorrectionTests.swift`
- `FSDTests/CatalogDatabaseTests.swift`
- `FSDTests/ClassificationEnrichmentTests.swift`
- `FSDTests/ComparisonGUISourceBoundaryTests.swift`
- `FSDTests/M5ReliabilityTests.swift`
- `FSDTests/MilestoneConditionTests.swift`
- `FSDTests/FinalScaleSnapshotTests.swift`
- `FSDTests/ManualSessionASubstituteTests.swift`
- One new `handoffs/FSD_P15_RUNTIME_IMPL_01_C_<timestamp>.md` and `handoffs/CURRENT_HANDOFF.md` for the required slice closeout only

## Files/modules the Writer must not modify

- All other production Swift, tests, Xcode project files, product/design docs, and historical Handoffs
- `SnapshotWriter`, provider/request/result types beyond the minimum compile-compatible provenance argument, UI, scanner, search, export, comparison, and helper integration
- Any dependency or external source

## Ordered TODOs

### TODO 1 — Add the canonical schema-v9 migration and verification state

Set `CatalogMigrations.currentVersion` to 9, append `migrationToVersion9` to `all`, add only the nullable/no-default `provider_identifier` column, seed fresh schema version 9, and extend `ExpectedState` / `verifyCurrentSchemaState()` to require the column. Preserve the existing transaction/version-last behavior.

### TODO 2 — Extend the typed repository and model round-trip

Add `providerIdentifier` to `EntryClassification` and `EntryClassificationInput`, every INSERT/SELECT/row decoder, value-length validation, equality round-trip, history, latest-row, and visible-page read. Enforce non-empty provider provenance for `.classified` inputs while retaining the locked nullable semantics above.

### TODO 3 — Extend migration-chain, rollback, fresh-schema, and damaged-schema coverage

Derive a real version-8 fixture by removing only the v9 addition from canonical schema. Prove v8→v9 migration, v4→…→v9 chain, version-row ordering, transactional rollback to v8 on a failed v9 migration, no replay on reopen, fresh/migrated column equivalence, integrity/foreign-key cleanliness, and rejection of a current-version catalog missing `provider_identifier`. Update tests whose current-version assertions are intentionally hard-coded.

### TODO 4 — Prove provenance and append-only behavior

Prove legacy v8 classification rows migrate with `provider_identifier == nil`; fresh typed classified writes require and round-trip provider identity independently of detector/model versions; duplicate-run rejection and history ordering remain unchanged; no snapshot/entry mutation occurs; and `docs/database/verify.sql` covers the new column without altering unrelated fixtures.

## Required build/test commands

Use an isolated DerivedData directory:

```bash
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Impl01-DerivedData clean build

xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Impl01-DerivedData \
  -only-testing:FSDTests/SchemaMigrationTests \
  -only-testing:FSDTests/SchemaSafetyCorrectionTests \
  -only-testing:FSDTests/CatalogDatabaseTests \
  -only-testing:FSDTests/ClassificationEnrichmentTests
```

Then run the full Debug suite with the same DerivedData path. Do not hide failed or skipped tests.

## Completion checks

- Fresh catalogs report version 9; migrated version-8 catalogs report 9 and retain all classification rows.
- Fresh and migrated `entry_classifications` column lists are identical.
- `provider_identifier` is nullable/no-default and no legacy value is invented.
- Typed classified rows round-trip three independent provenance fields.
- ExpectedState rejects a version-9 catalog missing the column.
- Duplicate-run, append-only, snapshot immutability, integrity, and foreign-key checks pass.
- Only the allowlisted files changed; no runtime/provider/UI behavior was introduced.
- Handoff reports exact commands and results; manual test state remains `NOT PERFORMED — DEFERRED BY OWNER`.

## Stop condition

Stop immediately if adding the single nullable column cannot preserve existing rows, transactional migration, or fresh/migrated equivalence. Mark `ARCHITECT ESCALATION REQUIRED`; do not rebuild the table, invent a sentinel provider, or broaden the schema. Also stop on any unrelated pre-existing failure rather than repairing outside scope.

## Audit gate

**Independent audit is required before Slice 02.** This is the schema/persistent-data boundary. Model or harness comparisons, scoring, winner selection and benchmark patch selection are removed by the owner's 2026-10-03 directive; they are not prerequisites for this product audit.

