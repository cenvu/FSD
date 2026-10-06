# FSD accepted control state

STATE_VERSION=1.0.0
PROJECT=FSD
CURRENT_PHASE=DEMO_SPRINT
ACTIVE_WORKSTREAM=FSD_DEMO_CRITICAL_PATH
STATUS=RUSH_SPRINT_LEAN;MACOS15_CANONICALIZED;PROVIDER_NEUTRAL_CLASSIFIER_RESEARCH_AUTHORIZED
CURRENT_GATE=FSD_CLASSIFIER_PROVIDER_ALTERNATIVES_RESEARCH_027
BLOCKERS=NONE
LAST_ACCEPTED_TASK=FSD_PLATFORM_MACOS15_CLASSIFIER_STRATEGY_CANONICALIZATION_RESCOPE_026A
LAST_ACCEPTED_HEAD=3e6f7d714cc23087d36272426c3bf761e387e0d1
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|docs/AGENT.md|docs/UX_UI_SPEC.md|docs/PRD.md|docs/PRODUCT_STATE.md|docs/MVP_PLAN.md|docs/ARCHITECTURE.md|docs/DECISIONS.md|docs/DEPENDENCY_AND_LICENSE_REVIEW.md|docs/SECURITY_AND_READ_ONLY_POLICY.md|docs/TEST_PLAN.md|docs/P15_RUNTIME_PLAN.md
PARKED_PRODUCT_WORKSTREAM=MAGIKA_INTEGRATION_BLOCKED_AT_025
EXACTLY_ONE_NEXT_DECISION=ACTION(FSD_CLASSIFIER_PROVIDER_ALTERNATIVES_RESEARCH_027)

Accepted-state provenance: BRAIN adjudication at 2026-10-06T15:06:11+07:00.
Task 026A macOS15/provider-neutral canonicalization is accepted PASS at publication 3e6f7d714cc23087d36272426c3bf761e387e0d1.
The accepted product floor is macOS 15 Sequoia or later, Apple Silicon arm64. All six active Xcode deployment targets are 15.0. ADR-033 supersedes active macOS13 floor assumptions and ADR-032's Magika-specific provider commitment while preserving the locally bundled helper/process-isolation decision.
Current classifier strategy is provider-neutral. Magika remains a blocked non-exclusive candidate with task025 evidence preserved; no replacement provider has been selected or integrated.
Classification safety invariants remain unchanged: explicit selected-entry action only; FSD-owned Data prefix <=4096 bytes; no provider path/URL/fd/source callback/additional-byte authority; offline/no network/telemetry; no sampled-byte persistence/hash/log; source read-only; immutable snapshot facts; inferred metadata only; no Python/system/user-installed runtime dependency.
Validation evidence for 026A: clean Debug build PASS; full Debug 472 executed / 469 passed / 3 existing external-fixture skips / 0 failed; clean Release build PASS; no Swift/test/schema/dependency/helper artifact delta.
The pre-existing control-plane inconsistency exposed by 026A is repaired by adding the missing ledger projection for FSD_P15_RUNTIME_SLICE_07_ARCHITECT_ESCALATION; append-only events remain unchanged.
Task 027 is authorized as research-only comparison of native classifier candidates against the canonical macOS15+ bundled-helper contract. No implementation is authorized.
Owner-authorized RUSH/SPRINT/LEAN progression remains active.
