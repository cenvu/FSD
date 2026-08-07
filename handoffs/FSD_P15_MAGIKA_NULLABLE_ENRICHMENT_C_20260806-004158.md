UPDATED_AT: 2026-08-06T00:41:58+0700

# Handoff — Phase 1.5 Magika Nullable Metadata Enrichment

Task: `FSD-P15-MAGIKA-NULLABLE-ENRICHMENT-0805-18`

## Status

COMPLETE for the requested nullable-enrichment preparation slice. Magika
runtime inference is **not active**: no model, dependency, download, network
service or runtime adapter was added or executed.

## Architecture

AUTOMATED VERIFIED — `LocalFileClassificationProvider` is a typed local-only
boundary with typed classified/unavailable/failed results and no diagnostic
channel. `DisabledFileClassificationProvider` performs no filesystem access.
`ClassificationEnrichmentService` is an explicit caller-only seam; it is not
injected into capture, browsing, search, export or comparison. Provider
identity is runtime-only because schema v8 has detector/model provenance but
no separate provider column.

## Schema and persistence

AUTOMATED VERIFIED — schema remains version 8 and reuses the existing nullable
`entry_classifications` table; no schema version 9 was introduced. The
append-only `EntryClassificationRepository` exposes typed nullable reads,
bounded latest-per-entry page reads, bounded history reads and explicit writes.
Writes reject nonexistent entries and duplicate `(entry_id,
classification_run_id)` values. There is no update or delete API. Fresh and
migrated catalog ExpectedState remains valid; schema, integrity and foreign
key checks pass.

## History and browsing

AUTOMATED VERIFIED — selected-entry detail reads one bounded classification
query and presents inferred type, MIME, detector/model, confidence and a
bounded status. A missing row presents `Not classified`. Root and child
browsing remain lazy and do not issue classification N+1 queries. The UI
labels the data as inferred metadata and not content verification.

## Export decision

AUTOMATED VERIFIED — canonical JSON export remains format version 1 and
excludes classification. Absence is therefore deterministic and no provider
diagnostic, payload or source path is exposed. This is an intentional
contract-preserving decision documented in `MVP_PLAN.md` and `DECISIONS.md`.

## Safety boundary

AUTOMATED VERIFIED — ordinary capture, search, export and comparison tests
create zero classification rows and comparison tests prove differing stored
classification metadata cannot change comparison outcomes. Classification
does not mutate `snapshot_entries`, snapshot totals or completion state. A
disabled provider leaves the row absent; a hostile provider is reduced to a
bounded typed failed status with no visible diagnostic. No hashing, sampling,
networking, background job, watcher, old-snapshot backfill or payload read was
added to ordinary workflows.

## Tests and query-plan evidence

AUTOMATED VERIFIED — new `ClassificationEnrichmentTests` has 8 executed, 8
passed, 0 failed, 0 skipped in Debug. It covers absent/present metadata,
round-trip, bounded retrieval, duplicate/missing-entry rejection, snapshot
immutability, disabled provider, hostile diagnostics, and ordinary workflow
row absence.

AUTOMATED VERIFIED — full fresh Debug XCTest suite:
293 executed, 290 passed, 0 failed, 3 skipped. The exact skips were:

- `FSDProbeSeedTests.testSeedIsolatedProbeCatalog`: `FSD_PROBE_CATALOG` is not
  set and no marker file exists.
- `FilesystemMatrixTests.testCaptureExternallyPreparedMountedFilesystem`:
  `FSD_MATRIX_SOURCE` is not set.
- `FilesystemMatrixTests.testReopenCapturedSnapshotWithTheSourceDetached`:
  `FSD_MATRIX_OFFLINE_CATALOG` is not set.

AUTOMATED VERIFIED — focused Release classification/history/safety suite:
60 executed, 60 passed, 0 failed, 0 skipped, using
`ENABLE_TESTABILITY=YES` only for the test host. Result:
`/tmp/FSD-P15-Release-Test-080518/Logs/Test/Test-FSD-2026.08.05_23-49-25-+0700.xcresult`.

AUTOMATED VERIFIED — isolated query-plan validation reports:
`SEARCH comparison_results USING COVERING INDEX
idx_comparison_results_parent_result_id (parent_result_id=?)`; no full scan
is reported for the parent-result child lookup.

## Builds and machine context

AUTOMATED VERIFIED — Xcode 26.3 (Build 17C529), Swift 6.2.4, macOS 15.7.7
(Build 24G720), host arm64. Fresh clean Debug build passed at:
`/tmp/FSD-P15-Debug-080518/Build/Products/Debug/FSD.app`.
Fresh clean Release build passed at:
`/tmp/FSD-P15-Release-080518/Build/Products/Release/FSD.app`.
Both application executables are Mach-O arm64. Full Debug result:
`/tmp/FSD-P15-Debug-Full-080518/Logs/Test/Test-FSD-2026.08.05_23-49-50-+0700.xcresult`.

AGENT-OBSERVED — build output included the standard multiple-destination
selection notice and AppIntents metadata omission because the target declares
no AppIntents. The full suite also emitted existing test-host SQLite vnode
unlink/API-violation logging and one Thread Performance Checker priority
inversion diagnostic; all affected tests passed. The first focused Release
test invocation without test-host testability failed before execution due the
project Release setting; the required retry with `ENABLE_TESTABILITY=YES`
passed completely.

## Existing final-scale evidence

AUTOMATED VERIFIED — the full Debug run also exercised the existing final-scale
comparison tests. It observed one-million automatic live-workspace close in
11.398 s with post-write latency 0.000 s, transient rows 0, user snapshots 1,
integrity `ok` and foreign keys clean; explicit one-million disposal in
11.322 s with 1,000,000 rows, residue 0, integrity `ok` and foreign keys
clean. These are Debug correctness-only observations. Per task instruction,
no separate Release one-million campaign was rerun because this slice did not
change comparison, schema or lifecycle behavior. Prior independently approved
Release evidence remains 9.930 s explicit and 10.018 s automatic close,
both below the 120-second threshold.

## Exact files changed

- `FSD/Catalog/EntryClassificationRepository.swift`
- `FSD/Catalog/CatalogDatabase.swift`
- `FSD/Browser/SnapshotTreeDataSource.swift`
- `FSD/UI/SnapshotBrowserView.swift`
- `FSDTests/ClassificationEnrichmentTests.swift`
- `FSDTests/ComparisonSemanticsTests.swift`
- `FSD.xcodeproj/project.pbxproj`
- `docs/PRODUCT_STATE.md`
- `docs/MVP_PLAN.md`
- `docs/TEST_PLAN.md`
- `docs/KNOWN_ISSUES.md`
- `docs/ARCHITECTURE.md`
- `docs/DECISIONS.md`
- `docs/database/schema.sql`
- `docs/database/verify.sql`

## Documentation and limitations

AUTOMATED VERIFIED — canonical documentation records schema v8, nullable
non-authoritative classification, unchanged comparison/export semantics,
metadata-only ordinary workflows, no old-snapshot backfill and inactive
Magika runtime. The canonical Debug wording is corrected to
`284 executed, 281 passed, 0 failed, 3 skipped`; historical Handoffs were not
rewritten.

NOT PERFORMED — DEFERRED BY OWNER — human UI/manual acceptance. Automated
detail-model and source-level UI checks passed, but no manual acceptance is
claimed. The separate startup-error wording finding and `.gemini-derived-data`
hygiene observation remain preserved and were not repaired or deleted.

## Exactly one next action

Run an independent Codex focused audit of the Phase 1.5 nullable Magika
enrichment boundary.
