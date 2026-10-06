# FSD accepted control state

STATE_VERSION=1.0.0
PROJECT=FSD
CURRENT_PHASE=DEMO_SPRINT
ACTIVE_WORKSTREAM=FSD_DEMO_CRITICAL_PATH
STATUS=RUSH_SPRINT_LEAN;NOMATCH_SEMANTICS_CANONICALIZED;NOMATCH_RUNTIME_REPAIR_AUTHORIZED
CURRENT_GATE=FSD_CLASSIFIER_NOMATCH_RUNTIME_REPAIR_031
BLOCKERS=NONE
LAST_ACCEPTED_TASK=FSD_CLASSIFIER_NOMATCH_SEMANTICS_CANONICALIZATION_030
LAST_ACCEPTED_HEAD=ca90122d1f30a295517d40783dc9f149b1011111
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|docs/AGENT.md|docs/UX_UI_SPEC.md|docs/PRD.md|docs/PRODUCT_STATE.md|docs/MVP_PLAN.md|docs/ARCHITECTURE.md|docs/DECISIONS.md|docs/DEPENDENCY_AND_LICENSE_REVIEW.md|docs/SECURITY_AND_READ_ONLY_POLICY.md|docs/TEST_PLAN.md|docs/P15_RUNTIME_PLAN.md
PARKED_PRODUCT_WORKSTREAM=MAGIKA_INTEGRATION_BLOCKED_AT_025
EXACTLY_ONE_NEXT_DECISION=ACTION(FSD_CLASSIFIER_NOMATCH_RUNTIME_REPAIR_031)

Accepted-state provenance: BRAIN adjudication at 2026-10-06T18:32:08+07:00.
Task030 noMatch semantics canonicalization is accepted PASS at publication ca90122d1f30a295517d40783dc9f149b1011111.
ADR-034 is the active contract: LocalClassificationProviderResult gains noMatch; helper wire resultKind "no_match" is valid only with all five metadata fields null; noMatch means successful provider execution with no recognized type and is distinct from classified/failed/unavailable/cancelled/sourceChanged/unsupportedEntry. It writes no entry_classifications row and stores no provenance.
Current classification contract has seven typed outcomes: four row-writing (classified, failed, sourceChanged, unsupportedEntry) and three no-row (unavailable, cancelled, noMatch). busy remains runtime control state only.
Persistent inspector absence remains neutral "Not classified."; a current explicit noMatch action may show bounded neutral "No file type recognized." Stale-selection/browser suppression, single-flight, timeout, cancellation, source authority, 4096-byte Data-only, offline/no-network and snapshot immutability semantics remain unchanged.
Task031 is authorized to implement ADR-034 in provider enum, helper parser, runtime no-row mapping, selected-entry UI current-result mapping and permanent deterministic tests. No schema/dependency/provider integration/filetype acquisition/build is authorized.
After task031 acceptance, BRAIN may authorize a fresh retry of the filetype native feasibility spike using the already-selected feasibility target. Task031 must not start that retry.
Owner-authorized RUSH/SPRINT/LEAN progression remains active.
