# FSD BRAIN routing model-pool alignment

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_BRAIN_ROUTING_MODEL_POOL_ALIGNMENT_D_20261004-183521.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=61d7fb3f37a92976d57a0d248d849d62c5c0a72f
REMOTE_HEAD=d1306622006ec645d63dae66a5bdc41bf4bc8a1b
LAST_VERIFIED_AT=2026-10-04T18:35:21+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|STATE/PROJECT_STATE.md|docs/AGENT.md|docs/README.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_BRAIN_ROUTING_MODEL_POOL_ALIGNMENT_011
STATUS=EXECUTION_VERIFIED_PENDING_PUBLICATION_AT_CAPTURE
BLOCKER=NONE
PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_FSD_ROUTING_MODEL_POOL_ALIGNMENT_ADJUDICATION
NO_AUTO_NEXT=YES

## Task lock and execution guard

TASK_ID=FSD_BRAIN_ROUTING_MODEL_POOL_ALIGNMENT_011
ROLE=WORKER
MODE=CONTROL_PLANE_ROUTING_POLICY_ALIGNMENT
BASE_HEAD=d1306622006ec645d63dae66a5bdc41bf4bc8a1b
UPSTREAM_HEAD=d1306622006ec645d63dae66a5bdc41bf4bc8a1b
TECHNICAL_SHA=61d7fb3f37a92976d57a0d248d849d62c5c0a72f
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=CONTROL_PLANE_ROUTING_POOL_ALIGNMENT
ALLOWED_PATHS=docs/BRAIN_OPERATOR.md|handoffs/FSD_BRAIN_ROUTING_MODEL_POOL_ALIGNMENT_D_20261004-183521.md|handoffs/CURRENT_HANDOFF.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl
FORBIDDEN_PATHS=ALL_OTHER_TRACKED_PATHS;STATE/PROJECT_STATE.md;STATE/RULE_PROMOTION_LEDGER.tsv;SWIFT;TESTS;SCHEMA;PRODUCT_DOCS
SUCCESS_CRITERIA=ROUTING_POOL_CURRENT;COST_POLICY_PRESENT;PROMPTS_AGNOSTIC;ONE_PRIMARY_ONE_FALLBACK;REQUIRED_VALIDATION
VALIDATIONS=REPO_SEARCH;DIFF_SCOPE_AND_DIFF_CHECK;CONTROL_PLANE_CLOSURE
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
WORKER_RESULT=PASS_WITH_ADVISORY
RESULT_AUTHORITY=WORKER_EVIDENCE_ONLY

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=10
WORKER_REQUIREMENTS_EVIDENCED=10
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

## Authority / reconciliation

FACT: re-anchored non-destructively at exact base d1306622006ec645d63dae66a5bdc41bf4bc8a1b. Local 98d55f456b429e5175661e011394080be2033629 was an ancestor of origin/main with 0/1 behind; clean worktree; `git merge --ff-only origin/main` advanced with no conflict, rewrite or discarded state. Post-FF HEAD equals upstream equals base, 0/0 clean. Accepted STATE authorizes exactly this alignment task; audit 010 stands accepted. Owner pool names below are taken verbatim as operational inventory, never externally corrected.

Task-execution discipline and applicable Compact rules were read. Direct authorities: this task text, BRAIN_OPERATOR Compact, accepted PROJECT_STATE. AGENT.md routing pointer and README pointer were searched first and left unchanged as consistent.

At capture: technical commit 61d7fb3f37a92976d57a0d248d849d62c5c0a72f holds only the Operator routing delta; origin/main remains base, ahead 1/behind 0, clean before finalizer projections. No drift was absorbed by recapturing base. Publication/synchronization is pending at immutable capture. Final completion waits for push/fetch and clean 0/0.

## Concrete delta

- docs/BRAIN_OPERATOR.md VERSION 1.2.0 to 1.3.0. Only the ROUTING section changed plus the version line: 44 insertions, 9 deletions. No other file touched by the technical commit.
- ROUTING keeps ONE_PRIMARY+ONE_FALLBACK, model-agnostic prompts, and the benchmark prohibition, and adds: prompt IDs forbidden (HARNESS/MODEL/EFFORT never hard-coded); PRIMARY and FALLBACK each state HARNESS, MODEL, EFFORT with WHY_THIS_HARNESS, WHY_THIS_MODEL, WHY_THIS_EFFORT, QUOTA_COST_REASONING and WHEN_OWNER_MAY_OVERRIDE; unsupported effort uses DEFAULT/NATIVE with no invented controls.
- Cost policy FREE_FIRST_WHEN_SAFE=YES: FREE lanes preferred when safe for deterministic docs, finalizer/publication, bounded checker repairs, fixture propagation, mechanical reconciliation, low/medium-risk implementation with strong tests, and repetitive bounded validation; stronger lanes reserved for ambiguity, source-safety, unresolved schema semantics, orchestration, concurrency, security/privacy, multi-system debugging, high-risk review, and hard contradictions. Paid is not always better; free is not always acceptable; choice by risk, ambiguity, validation strength, context size, independence need, quota and cost.
- CURRENT_OPERATIONAL_INVENTORY held only in the Operator as mutable inventory, never as architectural constants: Codex CLI GPT 6.1 SOL and GPT 6 LUNA; AGY CLI SONNET 5.5 and OPUS 5.5; OpenCode Space Bunny Free, Muse Spark 1.3 Contributor FREE, MiMo-V2.6-Flash FREE. Blanket wording replaced: stable prompts carry no model IDs, inventory may change without semantic change, stale entries must not be used once superseded. Prior superseded entries are marked not current and are not pool choices.
- Selection rule: exactly ONE PRIMARY and ONE FALLBACK, no ranked list; FREE-sufficient states why premium quota is conserved; premium states what risk earns the cost; material review prefers a different family when practical without claiming family change proves independence.

## Execution requirements / evidence

EVIDENCED items are FACT from repo search, complete diff/status inspection and real receipts.

| # | Requirement | Status / evidence |
|---|---|---|
| 1 | Authority/identity/baseline/preservation | EVIDENCED — authorized pure FF to exact base, 0/0 clean; protected STATE/historical bytes unchanged; ignored owner state present and untouched. |
| 2 | Current pool exact, old not current | EVIDENCED — each of the 7 Owner names appears exactly once in the Operator pool block; superseded entries marked not current, never as choices. |
| 3 | Agnostic prompts plus PRIMARY/FALLBACK triple | EVIDENCED — prompts carry no IDs; each of PRIMARY/FALLBACK states the three coordinates with the five required explanations. |
| 4 | Effort fallback DEFAULT/NATIVE | EVIDENCED — unsupported effort maps to DEFAULT/NATIVE; no invented HIGH/MEDIUM controls. |
| 5 | Conditional FREE-first cost policy | EVIDENCED — FREE_FIRST_WHEN_SAFE with safe-prefer list, reserve list, both non-absolute rules, and the seven choice factors. |
| 6 | One-plus-one selection, no benchmark | EVIDENCED — exactly ONE PRIMARY and ONE FALLBACK, no ranked list, conserve/earn-cost statements, review-family note; scoring and winner-selection prohibited. |
| 7 | Compact version and artifact budget | EVIDENCED — VERSION 1.3.0; routing-only delta of 44/9 lines; AGENTS.md, AGENT.md and README.md unchanged; zero new routing artifacts. |
| 8 | Forbidden scope respected | EVIDENCED — no Swift, test, schema, Slice 02, UX, ADR, dependency, config, account, benchmark, comparison-experiment or quota-probe delta; PROJECT_STATE and RULE_PROMOTION_LEDGER untouched. |
| 9 | Diff, scope and history mechanics | EVIDENCED — diff check clean; base-to-worktree diff holds only the 5 allowed paths; product diff empty; old handoffs byte-identical. |
| 10 | Closure projections and transport | EVIDENCED — one handoff prepared with exact CURRENT mirror, one Worker ledger row and one worker_return on the repaired base; Desktop embeds new Operator bytes with digest parity; push/fetch 0/0 pending at capture and verified after. |

## Completion gates

ROUTING_OUTPUT=ONE_PRIMARY+ONE_FALLBACK
WORKER_PROMPT_MODEL_AGNOSTIC=YES
HARNESS_MODEL_EFFORT_HARDCODE=NONE
EFFORT_UNSUPPORTED=DEFAULT/NATIVE
FREE_FIRST_WHEN_SAFE=YES
CURRENT_POOL_COUNT=7
STALE_POOL_USE=NONE
RANKED_LIST=NONE
BENCHMARK=NONE
VERSION=1.3.0
ARTIFACT_BUDGET=ONE_HANDOFF_ONLY
AGENTS_UNCHANGED=YES
PRODUCT_SCOPE=NONE

## Advisories / limits

- The Owner pool is mutable inventory pinned at capture time; if Owner updates the pool later, this handoff does not auto-update and stale entries must not be used.
- No live quota probing was performed; availability/cost reasoning stays policy-level and non-destructive.
- BRAIN owns adjudication, accepted state and active next; Worker classification stays pending.

## Proposed state / publication closure

Proposed baseline: routing guidance aligned with the Owner pool and cost policy as a compact control-plane delta; advisories above. Accepted STATE, rule promotions and product authorities outside the allowed paths remain unchanged. Worker ledger classification stays pending.

Finalizer projects this one immutable source with full CURRENT mirror, one Worker row and one worker_return event, exact Operator with full CURRENT Desktop transport while preserving dated prior fields, and publishes. Push, fetch, clean 0/0 and parity receipts are pending at immutable capture; final completion waits for fresh physical verification. Technical SHA is the docs commit; handoff publication SHA is resolved from Git, avoiding self-reference. Return to BRAIN and stop.
