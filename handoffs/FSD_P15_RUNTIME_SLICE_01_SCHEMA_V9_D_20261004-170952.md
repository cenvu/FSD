# FSD P15 Runtime Slice 01 — schema v9 and provider provenance

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_P15_RUNTIME_SLICE_01_SCHEMA_V9_D_20261004-170952.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=5e016b5c21691ad18e9e941462e8d4c389f3683a
REMOTE_HEAD=50b7d7649d2c9adfcb5aeb67585bd7e1f5540267
LAST_VERIFIED_AT=2026-10-04T17:09:52+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|STATE/PROJECT_STATE.md|docs/P15_RUNTIME_PLAN.md|docs/ARCHITECTURE.md|docs/DECISIONS.md|docs/PRODUCT_STATE.md|docs/TEST_PLAN.md|docs/UX_UI_SPEC.md|docs/database/schema.sql|docs/database/verify.sql
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_P15_RUNTIME_SLICE_01_SCHEMA_V9_009
STATUS=EXECUTION_VERIFIED_PENDING_PUBLICATION_AT_CAPTURE
BLOCKER=NONE
PROPOSED_NEXT=FSD_P15_RUNTIME_SLICE_01_SCHEMA_V9_INDEPENDENT_AUDIT
NO_AUTO_NEXT=YES

## Task lock and execution guard

TASK_ID=FSD_P15_RUNTIME_SLICE_01_SCHEMA_V9_009
ROLE=WORKER
MODE=PRODUCT_IMPLEMENTATION_SCHEMA_BOUNDARY
BASE_HEAD=50b7d7649d2c9adfcb5aeb67585bd7e1f5540267
UPSTREAM_HEAD=50b7d7649d2c9adfcb5aeb67585bd7e1f5540267
TECHNICAL_SHA=5e016b5c21691ad18e9e941462e8d4c389f3683a
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=P15_RUNTIME_SLICE_01_SCHEMA_AND_PROVIDER_PROVENANCE_ONLY
ALLOWED_PATHS=docs/database/schema.sql|docs/database/verify.sql|FSD/Catalog/CatalogMigrations.swift|FSD/Catalog/CatalogDatabase.swift|FSD/Catalog/EntryClassificationRepository.swift|FSDTests/SchemaMigrationTests.swift|FSDTests/SchemaSafetyCorrectionTests.swift|FSDTests/CatalogDatabaseTests.swift|FSDTests/ClassificationEnrichmentTests.swift|FSDTests/ComparisonGUISourceBoundaryTests.swift|FSDTests/ComparisonSemanticsTests.swift|FSDTests/M5ReliabilityTests.swift|FSDTests/MilestoneConditionTests.swift|FSDTests/FinalScaleSnapshotTests.swift|FSDTests/ManualSessionASubstituteTests.swift|handoffs/FSD_P15_RUNTIME_SLICE_01_SCHEMA_V9_D_20261004-170952.md|handoffs/CURRENT_HANDOFF.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl
FORBIDDEN_PATHS=ALL_OTHER_TRACKED_PATHS;STATE/PROJECT_STATE.md;STATE/RULE_PROMOTION_LEDGER.tsv;PRIOR_HISTORICAL_HANDOFFS
SUCCESS_CRITERIA=SCHEMA_9_SINGLE_NULLABLE_COLUMN;TRANSACTIONAL_MIGRATION;INDEPENDENT_PROVENANCE;UNCHANGED_APPEND_ONLY_AND_SNAPSHOT_TRUTH;REQUIRED_VALIDATION
VALIDATIONS=CLEAN_DEBUG_BUILD;FOCUSED_AND_SAFETY_CLASSES;FULL_DEBUG_SUITE;SQL_SUBSET;DIFF_SCOPE_AND_DIFF_CHECK;CONTROL_PLANE_CLOSURE
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
WORKER_RESULT=PASS_WITH_ADVISORY
RESULT_AUTHORITY=WORKER_EVIDENCE_ONLY

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=23
WORKER_REQUIREMENTS_EVIDENCED=22
WORKER_REQUIREMENTS_NOT_APPLICABLE=1
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

## Authority / reconciliation

FACT: same task continued after supplied BRAIN REPAIR; prior stop caused no mutation/handoff. Repair 1 authorized pure fast-forward: clean local 95c98110ec6e82f931efa0470da35fbd9237df20 was an ancestor of origin/main, 0/2, two STATE-only commits. `git fetch origin`, status, rev-list and merge-base checks passed; `git merge --ff-only origin/main` advanced to the exact base with no merge commit, conflict resolution, rewrite or discarded state. Post-FF HEAD/upstream equaled base, 0/0 clean. Accepted STATE freshly reported DEMO_SPRINT/task 009; CURRENT HOT remained the prior Owner UX return. That prior HOT did not override accepted STATE or explicit authorization.

Task-execution and handoff-finalizer skills and applicable Compact rules were read. Direct authorities: P15 Slice 01, ARCHITECTURE §9/§9a, ADR-031/032, PRODUCT_STATE, TEST_PLAN, schema/verify SQL. UX_UI_SPEC was direction only.

At capture: technical commit above contains the 15 reviewed implementation paths; origin/main remains base, ahead/behind 1/0, clean before finalizer projections. No drift was absorbed by recapturing base. Publication/synchronization is pending at immutable capture. Resolve publication with `git log -1 --format=%H -- handoffs/FSD_P15_RUNTIME_SLICE_01_SCHEMA_V9_D_20261004-170952.md` and the final Desktop Git receipt. Final completion waits for push/fetch and clean 0/0.

## Concrete delta

- Current version 8→9, canonical sequence 4→5→6→7→8→9. Sole new DDL: `ALTER TABLE entry_classifications ADD COLUMN provider_identifier TEXT`. Fresh schema appends after created_at. Nullable/no default/no backfill; legacy provider remains nil.
- Existing transaction/version-last migration mechanism unchanged. ExpectedState inventory adds the classification column and checks it on every open, rejecting declared v9 without the column.
- EntryClassification/Input add optional providerIdentifier; INSERT, every SELECT and decoder round-trip through history/latest/visible page and synthesized equality. Classified writes reject nil, blank/whitespace-only and >256 characters; existing metadata-length loop is reused. Non-blank raw identity is preserved.
- Existing classified service forwards the provider's already-declared identifier through the minimum provenance argument. Detector/model/provider stay independent. Provider/request/result shapes, sourceURL, byteBudget and failure handling unchanged; no future outcomes/runtime/source reader/provider implementation/helper/dependency/UI/Slice 02 work.
- v8 fixture removes only the v9 column/version bump from canonical SQL, then earlier versions use existing removal helpers. Disposable fixtures use row copies/version-order probes; canonical tables/triggers/indexes and UNIQUE(entry_id, classification_run_id) unchanged. No update/delete API.

## Execution requirements / evidence

EVIDENCED items are FACT from executable tests, complete diff/status inspection and real receipts. No coverage percentage is claimed.

| # | Requirement | Status / evidence |
|---|---|---|
| 1 | Authority/identity/baseline/preservation | EVIDENCED — authorized pure FF, exact base 0/0 clean; protected STATE/historical bytes unchanged, baseline ignored paths present. |
| 2 | Current schema 9 | EVIDENCED — fresh/current CatalogDatabaseTests and SchemaMigrationTests. |
| 3 | Single nullable/no-default/no-backfill field | EVIDENCED — exact DDL diff, fresh PRAGMA and legacy nil checks. |
| 4 | Real derived v8 fixture | EVIDENCED — version8SQL exact removals, raw version8/column absent before open. |
| 5 | v4→9 chain/both v4 variants | EVIDENCED — existing migration cases; recorded versions [4,5,6,7,8,9]. |
| 6 | Transaction/version-last | EVIDENCED — testVersionNineVersionRowIsWrittenAfterEveryMigrationStatement CHECK probe/version-write guard. |
| 7 | Rollback exactly to v8 | EVIDENCED — statement and version-write failure injections; no v9 column/version persists; bidirectional full row-set comparison; real successful retry. |
| 8 | No replay on reopen | EVIDENCED — injected v9 statements would fail on replay; versions/applied_at/history unchanged. |
| 9 | Fresh/migrated physical equivalence | EVIDENCED — full PRAGMA cid/name/type/notnull/dflt_value/pk equality for v8; physical column order also checked in v4 chain. |
| 10 | Declared v9 missing column rejects | EVIDENCED — testVersionNineWithoutProviderIdentifierIsRejected, typed schemaStateInvalid names missing column. |
| 11 | Optional typed/input field and truthful NULL | EVIDENCED — nullable input and legacy classified/failed history decode. |
| 12 | Classified identity required, trimmed non-empty | EVIDENCED — nil/empty/space/tab-newline reject with no row. |
| 13 | Maximum 256 characters | EVIDENCED — 256 Unicode characters round-trip, 257 reject. |
| 14 | Independent provenance | EVIDENCED — distinct field/service round-trips; same detector/model with different providers. |
| 15 | Duplicate guard/append-only | EVIDENCED — duplicate reject preserves history; UNIQUE/API unchanged. |
| 16 | History/latest/visible-page unchanged | EVIDENCED — descending insertion ID despite older classified_at, bounded history/page, multi-entry/duplicate/empty page and existing detail-read tests. |
| 17 | Entries/snapshots and integrity/FK | EVIDENCED — bidirectional row-set checks through migration/rollback, fingerprint checks, integrity ok/FK clean. |
| 18 | Exact product scope/source safety/next boundary | EVIDENCED — authorized complete diff; protected source/runtime/UI/dependency paths untouched; audit proposed only and Slice 02 not begun. |
| 19 | Mechanical fixture repair | EVIDENCED — original 6+2 callsites recorded below; only provider arguments in ComparisonSemantics, assertions unchanged. |
| 20 | Required clean Debug build | EVIDENCED — isolated exact command, exit0 BUILD SUCCEEDED. |
| 21 | Focused plus actual safety classes | EVIDENCED — 44+18 pass, zero skips/failures/expected failures. |
| 22 | Full Debug/diff/scope checks | EVIDENCED — exit0; 302 total, 299 pass, 3 external-probe skips, zero failures/expected failures; diff --check clean; tested hashes preserved. |
| 23 | Manual UI acceptance | NOT_APPLICABLE — Owner explicitly deferred, not performed. |

## Completion gates

SCHEMA_CURRENT=9
V8_TO_V9=PASS
V4_TO_V9_CHAIN=PASS
ROLLBACK_TO_V8_ON_FAILED_V9=PASS
NO_REPLAY_ON_REOPEN=PASS
FRESH_MIGRATED_COLUMN_EQUIVALENCE=PASS
PROVIDER_IDENTIFIER_NULLABLE=PASS
PROVIDER_IDENTIFIER_DEFAULT_NONE=PASS
LEGACY_BACKFILL_NONE=PASS
CLASSIFIED_PROVIDER_REQUIRED=PASS
PROVIDER_MAX_LENGTH=256
PROVENANCE_INDEPENDENCE=PASS
DUPLICATE_RUN_GUARD=PASS
APPEND_ONLY=PASS
SNAPSHOT_MUTATION=NONE
ENTRY_MUTATION=NONE
INTEGRITY_CHECK=PASS
FOREIGN_KEY_CHECK=PASS
FOCUSED_TESTS=PASS
FULL_DEBUG_SUITE=PASS
PRODUCT_SCOPE=SLICE_01_ONLY
MANUAL_UI_ACCEPTANCE=NOT_PERFORMED_DEFERRED_BY_OWNER

## Original fixture callsites / repair propagation

Pre-implementation `rg -n 'EntryClassificationInput\(' FSDTests` returned ClassificationEnrichmentTests.swift:58,84,99,105,106,119 and ComparisonSemanticsTests.swift:131,134. Approved classified fixtures now supply deterministic test-only identifiers; new negative/nullable cases intentionally retain nil.

PATH: FSDTests/ComparisonSemanticsTests.swift. CALLSITE: original lines131/134 in testClassificationMetadataCannotChangeComparisonOutcome. WHY_REQUIRED_BY_SLICE_01: both default-classified inputs now require provider. EXACT_DELTA: add providerIdentifier comparison-fixture-left / comparison-fixture-right, solely under explicit Repair 2. No comparison production/assertion change. Conditionally touched files outside amended explicit allowlist: NONE.

## Commands / receipts / failures

Observed environment: macOS15.7.7 (24G720), arm64; Xcode26.3 (17C529). RAW: existing ignored `.agent/FSD_P15_RUNTIME_SLICE_01_SCHEMA_V9_009/`; xcresults under isolated `/tmp/FSD-P15-Impl01-DerivedData/Logs/Test/`.

```sh
xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-P15-Impl01-DerivedData -only-testing:FSDTests/ClassificationEnrichmentTests/testClassifiedInputRequiresProviderIdentity -only-testing:FSDTests/CatalogDatabaseTests/testFreshDatabaseBootstrapsCurrentSchemaVersionAndIntegrity
```
Causal RED before production changes: exit65, 2 failed tests/4 intended assertions, zero skips. DB reported8/column absent; nil-provider classified append succeeded and wrote a row (red.log / red-summary.json).

```sh
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-P15-Impl01-DerivedData clean build
xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-P15-Impl01-DerivedData -only-testing:FSDTests/SchemaMigrationTests -only-testing:FSDTests/SchemaSafetyCorrectionTests -only-testing:FSDTests/CatalogDatabaseTests -only-testing:FSDTests/ClassificationEnrichmentTests
```
Build exit0. First focused attempt exit65 during compile: fixture substitution accidentally added providerIdentifier to expected duplicateRun error at ClassificationEnrichmentTests:201. Complete diagnostic inspected; original assertion expression restored. One repair retry exit0, 44 pass/0 fail/0 skip/0 expected failures (build.log, focused.log, focused-retry.log / summary). No production correction.

The prescribed SchemaSafetyCorrectionTests selector is a filename; no class has that name. Actual classes were additionally exercised:

```sh
xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-P15-Impl01-DerivedData -only-testing:FSDTests/TerminalCollisionEvidenceTests -only-testing:FSDTests/ExpectedStateInventoryTests
xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-P15-Impl01-DerivedData
```
Supplemental safety exit0:18 pass/0 fail/0 skip/0 expected failures. Full Debug exit0:302 total/299 pass/3 skip/0 fail/0 expected failures, TEST SUCCEEDED. Full suite ended2026-10-04T16:58:23+07:00; full xcresult Test-FSD-2026.10.04_16-13-34-+0700.xcresult (safety-focused.log / summary; full-debug.log / full-debug-summary.json).

Executable verify.sql C7a subset ran against canonical fresh schema with existing disposable seed: independent provider-A/B tuples and retained NULL, integrity ok/FK clean (sql-subset.log). Full verify.sql with its historical deliberate constraint failures was not run. git diff --check exit0; complete scope/status/owner-state/historical-byte checks passed before technical commit; candidate hashes preserved.

Prepublication in-memory guard precheck initially failed because its reused Checker instance lacked ledger/args context. No handoff/STATE mutation occurred. Dependency was inspected and initialized for the one correction; canonical checker source unchanged. Publication-stage physical checker runs separately with the exact amended allowlist/base; its completion is not pre-claimed here.

## Advisories / limits

- Full-suite skips: FSDProbeSeedTests.testSeedIsolatedProbeCatalog (FSD_PROBE_CATALOG unset/no marker); FilesystemMatrixTests.testCaptureExternallyPreparedMountedFilesystem (FSD_MATRIX_SOURCE unset); FilesystemMatrixTests.testReopenCapturedSnapshotWithTheSourceDetached (FSD_MATRIX_OFFLINE_CATALOG unset). These externally prepared probes were not performed. Schema/provenance and actual safety classes all executed.
- Xcode Thread Performance Checker QoS priority-inversion diagnostic during memory comparison; backtrace identifies unchanged M5PeakSampler.stop. Test passed; no unrelated repair. Existing no-AppIntents metadata-extraction-skipped build warning also observed.
- Manual UI/VoiceOver acceptance not performed, deferred by Owner.
- Independent schema/persistent-data audit remains required before Slice 02; Worker did not self-author it.

## Proposed state / publication closure

Proposed baseline: Slice 01 schema-v9/provider-provenance prerequisite implemented, proofs green, advisories above. BRAIN owns adjudication, accepted state and active next. PROJECT_STATE/RULE_PROMOTION_LEDGER and product authorities outside allowed paths remain unchanged. Worker ledger classification stays PENDING_BRAIN.

Finalizer projects this one immutable source/full CURRENT, one Worker row/event, exact Operator/full CURRENT Desktop transport while preserving dated prior BRAIN fields, and publishes. Push/fetch/clean0/0/parity receipts are pending at immutable capture; final completion waits for fresh physical verification. Technical SHA is the implementation commit; handoff publication SHA is resolved from Git, avoiding self-reference. Return to BRAIN and stop.
