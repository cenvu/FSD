# FSD accepted control state

STATE_VERSION=1.0.0
PROJECT=FSD
CURRENT_PHASE=DEMO_SPRINT
ACTIVE_WORKSTREAM=FSD_DEMO_CRITICAL_PATH
STATUS=RUSH_SPRINT_LEAN;OWNER_DECISION_ACCEPTED;MACOS15_CANONICALIZATION_RESCOPE_AUTHORIZED;ALTERNATIVE_CLASSIFIER_STRATEGY_AUTHORIZED
CURRENT_GATE=FSD_PLATFORM_MACOS15_CLASSIFIER_STRATEGY_CANONICALIZATION_RESCOPE_026A
BLOCKERS=NONE
LAST_ACCEPTED_TASK=FSD_P15_RUNTIME_SLICE_06_CROSS_WORKFLOW_SECURITY_REGRESSION_MATRIX_024
LAST_ACCEPTED_HEAD=5db49c7cf4f44a8ca44313459bac285b5a1eb074
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|docs/UX_UI_SPEC.md|docs/PRD.md|docs/PRODUCT_STATE.md|docs/MVP_PLAN.md|docs/ARCHITECTURE.md|docs/SECURITY_AND_READ_ONLY_POLICY.md|docs/TEST_PLAN.md|docs/P15_RUNTIME_PLAN.md
PARKED_PRODUCT_WORKSTREAM=MAGIKA_INTEGRATION_BLOCKED_AT_025
EXACTLY_ONE_NEXT_DECISION=ACTION(FSD_PLATFORM_MACOS15_CLASSIFIER_STRATEGY_CANONICALIZATION_RESCOPE_026A)

Accepted-state provenance: BRAIN adjudication/state correction at 2026-10-06T12:00:00+07:00 following Owner decision and Worker STOP 026.
Owner decision remains accepted: minimum supported macOS becomes 15+ and future classifier selection becomes provider-neutral research against the existing bounded bundled-helper safety contract.
Task 026 STOP is accepted as correct allowlist-boundary evidence. Its pre-mutation inventory found two active macOS13 authorities outside the original mutation allowlist: docs/AGENT.md and docs/DEPENDENCY_AND_LICENSE_REVIEW.md. No product/build mutation occurred.
The LAST_ACCEPTED_TASK/LAST_ACCEPTED_HEAD projection is corrected to the most recent PASS-classified task 024, as required by the canonical checker. Accepted STOP evidence for tasks 025 and 026 remains preserved in TASK_LEDGER/EVENTS but is not used as the last-accepted PASS pointer.
Task 026A is authorized to perform the same canonicalization with all discovered active residual authorities explicitly allowlisted: docs/AGENT.md and docs/DEPENDENCY_AND_LICENSE_REVIEW.md for macOS13 platform claims, plus docs/TEST_PLAN.md, docs/UX_UI_SPEC.md and docs/SECURITY_AND_READ_ONLY_POLICY.md for current Magika-specific future-runtime/gate wording. Changes in those files are limited to platform/provider-neutral canonicalization; requirements and safety semantics must not be weakened. No classifier selection/research/integration is authorized in 026A.
Locked classification safety invariants remain unchanged: explicit selected-entry classification only; FSD-owned bounded Data input <=4096 bytes; no provider path/URL/fd/source callback or additional-byte authority; offline/no network/telemetry; no sampled-byte persistence/hash/logging; source read-only; immutable snapshot facts; crash isolation through an app-bundled helper boundary; no Python/system/user-installed runtime dependency.
Owner-authorized RUSH/SPRINT/LEAN progression remains active.
