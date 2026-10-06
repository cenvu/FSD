# FSD accepted control state

STATE_VERSION=1.0.0
PROJECT=FSD
CURRENT_PHASE=DEMO_SPRINT
ACTIVE_WORKSTREAM=FSD_DEMO_CRITICAL_PATH
STATUS=RUSH_SPRINT_LEAN;OWNER_DECISION_ACCEPTED;MACOS15_CANONICALIZATION_AUTHORIZED;ALTERNATIVE_CLASSIFIER_STRATEGY_AUTHORIZED
CURRENT_GATE=FSD_PLATFORM_MACOS15_CLASSIFIER_STRATEGY_CANONICALIZATION_026
BLOCKERS=NONE
LAST_ACCEPTED_TASK=FSD_P15_RUNTIME_SLICE_07_EXTERNAL_MAGIKA_VERIFICATION_025
LAST_ACCEPTED_HEAD=7ae9c9782269002fab520b5de285fffd53cd862b
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|docs/UX_UI_SPEC.md|docs/PRD.md|docs/PRODUCT_STATE.md|docs/MVP_PLAN.md|docs/ARCHITECTURE.md|docs/SECURITY_AND_READ_ONLY_POLICY.md|docs/TEST_PLAN.md|docs/P15_RUNTIME_PLAN.md
PARKED_PRODUCT_WORKSTREAM=MAGIKA_INTEGRATION_BLOCKED_AT_025
EXACTLY_ONE_NEXT_DECISION=ACTION(FSD_PLATFORM_MACOS15_CLASSIFIER_STRATEGY_CANONICALIZATION_026)

Accepted-state provenance: Owner decision adjudicated by BRAIN at 2026-10-06T11:39:53+07:00.
Owner selected the alternative-classifier exploration path and changed the minimum supported macOS version from 13+ to 15+.
The new deployment-floor decision must be canonically projected before provider research continues. Magika remains a blocked, non-exclusive candidate; Slice-07 STOP evidence is preserved and is not reinterpreted as integration approval.
Locked classification safety invariants remain unchanged: explicit selected-entry classification only; FSD-owned bounded Data input <=4096 bytes; no provider path/URL/fd/source callback or additional-byte authority; offline/no network/telemetry; no sampled-byte persistence/hash/logging; source read-only; immutable snapshot facts; crash isolation through an app-bundled helper boundary; no Python/system/user-installed runtime dependency.
Task 026 is authorized to canonicalize macOS 15+ across product/architecture/build authorities and record the provider-selection pivot without choosing or integrating a replacement classifier.
After task 026 is accepted, the intended next dependency is a bounded external research task comparing native classifier candidates against the locked contract.
Owner-authorized RUSH/SPRINT/LEAN progression remains active.
