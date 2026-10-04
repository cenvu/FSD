# FSD P15 Runtime Slice 01 — schema v9 and provider provenance audit

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_P15_RUNTIME_SLICE_01_SCHEMA_V9_AUDIT_R_20261004-181638.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=227bda03146bf9820465e688b0684a38716581ee
REMOTE_HEAD=227bda03146bf9820465e688b0684a38716581ee
LAST_VERIFIED_AT=2026-10-04T18:16:38.820308+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|STATE/PROJECT_STATE.md|docs/P15_RUNTIME_PLAN.md|docs/ARCHITECTURE.md|docs/DECISIONS.md|docs/PRODUCT_STATE.md|docs/TEST_PLAN.md|docs/UX_UI_SPEC.md|docs/database/schema.sql|docs/database/verify.sql
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_P15_RUNTIME_SLICE_01_SCHEMA_V9_AUDIT_010
STATUS=EXECUTION_VERIFIED_PENDING_PUBLICATION_AT_CAPTURE
BLOCKER=NONE
PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_FSD_P15_SLICE_01_SCHEMA_V9_AUDIT_ADJUDICATION
NO_AUTO_NEXT=YES

## Task lock and execution guard

TASK_ID=FSD_P15_RUNTIME_SLICE_01_SCHEMA_V9_AUDIT_010
ROLE=REVIEWER
MODE=INDEPENDENT_SCHEMA_PERSISTENT_DATA_AUDIT
BASE_HEAD=227bda03146bf9820465e688b0684a38716581ee
UPSTREAM_HEAD=227bda03146bf9820465e688b0684a38716581ee
TECHNICAL_SHA=227bda03146bf9820465e688b0684a38716581ee
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=INDEPENDENT_AUDIT_OF_SCHEMA_V9_AND_PROVIDER_PROVENANCE
ALLOWED_PATHS=handoffs/FSD_P15_RUNTIME_SLICE_01_SCHEMA_V9_AUDIT_R_20261004-181638.md|handoffs/CURRENT_HANDOFF.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl
FORBIDDEN_PATHS=ALL_OTHER_TRACKED_PATHS;STATE/PROJECT_STATE.md;STATE/RULE_PROMOTION_LEDGER.tsv
SUCCESS_CRITERIA=INDEPENDENT_AUDIT_VERDICT;FINDINGS_DOCUMENTED
VALIDATIONS=FOCUSED_AUDIT_TESTS;DIFF_CHECK
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
WORKER_RESULT=PASS_WITH_ADVISORY
RESULT_AUTHORITY=WORKER_EVIDENCE_ONLY

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=5
WORKER_REQUIREMENTS_EVIDENCED=5
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

## Findings

SEVERITY=LOW
EVIDENCE=FSD/Catalog/EntryClassificationRepository.swift:268-272 and testClassifiedProviderIdentityRejectsBlankAndOverlongValues (lines 245-248).
BLAST_RADIUS=Provider identity preserves leading/trailing whitespace. If external adapters supply padded identities, they are stored verbatim, potentially causing mismatch bugs later if "stable provider identifier" implicitly assumes trimmed strings.
COVERAGE=Tests explicitly prove padding is preserved, but existing authorities do not clearly specify if stable identifiers must be stripped.
SMALLEST_REPAIR_DIRECTION=Clarify in architecture whether provider identifiers should be trimmed; if required, add `.trimmingCharacters(in: .whitespacesAndNewlines)` to the final persisted value.

## Audit Summary

- **SCHEMA (V9)**: PASS. Migration 8->9 exactly `ALTER TABLE entry_classifications ADD COLUMN provider_identifier TEXT`. Nullable, no default, no backfill. Rollback on statement/version failure verified. Fresh and migrated physical positions are equivalent.
- **DATA COMPATIBILITY**: PASS. Existing v8 rows survive with NULL provider. No provider value is fabricated from other fields. Entries/snapshots untouched. No UPDATE/DELETE API introduced.
- **TYPED REPOSITORY**: PASS_WITH_ADVISORY. Provider identity is optional typed but required for `.classified`. `.failed` rows correctly lack it. Whitespace preservation is unproven.
- **CLASSIFICATION BOUNDARY**: PASS. No scope widening. Minimum provenance propagates correctly. Comparison assertions/behavior remain unchanged (only fixture provenance updated).
- **TEST QUALITY**: PASS. Rollback, missing-column, and constraint checks correctly exercise constraints. Independent test isolation confirmed. Full suite results accepted as evidence without reproducing all 299 tests.
- **KNOWN ADVISORIES**: The 3 external probe skips, QoS diagnostic, and no-AppIntents warning were inspected and are explicitly NOT material to this schema/persistent-data audit.

## Proposed state / publication closure

Proposed baseline: Independent audit passes with one LOW advisory on whitespace trimming. Worker ledger classification stays PENDING_BRAIN. No repair executed. Slice 02 must NOT start until BRAIN adjudicates.
