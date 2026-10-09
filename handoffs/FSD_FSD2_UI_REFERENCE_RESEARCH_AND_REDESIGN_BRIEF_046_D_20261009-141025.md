# Task046 — UI reference research and redesign brief

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD2_STAGE0_5_UI_RESEARCH
HANDOFF_ID=handoffs/FSD_FSD2_UI_REFERENCE_RESEARCH_AND_REDESIGN_BRIEF_046_D_20261009-141025.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=d1d05a66700c16683e0650ec01454178f09c15df
REMOTE_HEAD=d1d05a66700c16683e0650ec01454178f09c15df
LAST_VERIFIED_AT=2026-10-09T14:10:06+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|STATE/PROJECT_STATE.md|handoffs/CURRENT_HANDOFF.md|docs/AGENT.md|docs/UX_UI_SPEC.md|docs/PRODUCT_STATE.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|scripts/check_control_plane.py
CURRENT_PHASE=POST_V0_1_FSD2_FOUNDATION
CURRENT_GATE=FSD2_STAGE0_5_UI_REFERENCE_RESEARCH_BRIEF
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE
PROPOSED_NEXT=OWNER_DECISION
NO_AUTO_NEXT=YES

## Task lock and authority

TASK_ID=FSD2_UI_REFERENCE_RESEARCH_AND_REDESIGN_BRIEF_046
ROLE=WORKER
MODE=UI_RESEARCH_PLUS_OWNER_POLICY_SYNC
BASE_HEAD=d1d05a66700c16683e0650ec01454178f09c15df
UPSTREAM_HEAD=d1d05a66700c16683e0650ec01454178f09c15df
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=PERMANENT_OWNER_POLICY_SYNC_AND_REFERENCE_APP_RESEARCH_WITH_TWO_DESIGN_DIRECTIONS;NO_PRODUCT_UI_IMPLEMENTATION
ALLOWED_PATHS=AGENTS.md|docs/BRAIN_OPERATOR.md|.agents/skills/fsd-task-execution/SKILL.md|docs/FSD2_UI_REFERENCE_RESEARCH.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|handoffs/CURRENT_HANDOFF.md|handoffs/FSD_FSD2_UI_REFERENCE_RESEARCH_AND_REDESIGN_BRIEF_046_D_20261009-141025.md
FORBIDDEN_PATHS=STATE/PROJECT_STATE.md|STATE/RULE_PROMOTION_LEDGER.tsv|FSD/**|FSDTests/**|SCHEMA_OR_DEPENDENCIES|PUBLIC_RELEASE_TAG_ASSETS|PRIOR_HISTORICAL_HANDOFFS|docs/UX_UI_SPEC.md|PRODUCT_UI_IMPLEMENTATION
SUCCESS_CRITERIA=OWNER_POLICY_LOCAL_AND_ALWAYS_READ;MODEL_ROUTING_SYNCED;SIX_REFERENCE_APPS_SOURCED;TWO_COMPLETE_FSD_DESIGN_DIRECTIONS;RECOMMENDATION_WITH_EVIDENCE;FSD_TRUTH_BOUNDARIES_PRESERVED;REVIEW_AND_CANONICAL_CHECKS_PASS
VALIDATIONS=SOURCE_REVIEW;GOVERNANCE_REVIEW;REFERENCE_CLAIM_REVIEW;GIT_DIFF_CHECK;CONTROL_PLANE_PRE_AND_POSTPUBLICATION
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY

## Re-anchor and protected state

The non-destructive fetch confirmed canonical repository `/Users/cenvu/DEV/FSD`, origin `https://github.com/cenvu/FSD.git`, branch `main`, and `LOCAL_HEAD=REMOTE_HEAD=d1d05a66700c16683e0650ec01454178f09c15df`, with ahead/behind `0/0`. The only task dirt before reporting was the four authorized product/documentation paths. The expected Task045 publication and Task046 authorization commit were already on canonical `main`. The accepted state authorizes Stage0.5 research only; it remains unmodified along with `STATE/RULE_PROMOTION_LEDGER.tsv`. Task045 remains BRAIN accepted PASS_WITH_ADVISORY; Task046 is a new bounded research/policy-sync task, not UI implementation.

Owner Issue #1 was read directly before execution: https://github.com/cenvu/FSD/issues/1. Its reusable anti-bureaucracy decision is now captured locally in `AGENTS.md` §Owner Policy Always Read, linked from the Compact Operator and task-execution skill. The local canonical text means future reads do not require an online fetch while that text remains available. The obsolete one-retry/automatic STOP rule is removed. Three ineffective attempts on one cause trigger official API/SDK, upstream and credible community research plus an alternative approach; this is not an automatic STOP. A failed required test still blocks PASS, while in-scope debugging continues. Source-data safety, credentials/privacy, destructive changes, unexplained dirty conflicts, scope breaches and unresolved technical impasses remain stop gates.

## Work completed

### Permanent Owner policy and routing sync

- `AGENTS.md` now includes an always-read, local canonical Owner policy section with Issue #1 provenance, the exact before-every-prompt/review requirement, the required anti-bureaucracy question, the evidence-first failure loop, the same-cause research trigger, genuine STOP boundaries, and no-redundant-round guidance.
- `docs/BRAIN_OPERATOR.md` is now VERSION `1.4.0`. Its stable task/transport contract and model-agnostic prompts remain intact. It points to the local policy, records that online fetch is not required when the local text is present, and routes Antigravity CLI/IDE to OPUS 4.6 only with SONNET excluded. A cheaper preparation Worker precedes OPUS only when OPUS is actually needed.
- `.agents/skills/fsd-task-execution/SKILL.md` removes `REPAIR_RETRY_MAX=1` and `AFTER_SAME_FAMILY_REPEAT_FAILURE=STOP_AND_RESEARCH`, defines three ineffective same-cause implementation attempts before required research/change of approach, keeps ordinary corrections in the existing scope, and explicitly separates the research trigger from genuine STOP conditions. Finalizer handoff wording now points back to those same rules.
- No accepted STATE, rule-promotion record, product source, test, schema, dependency, release asset, UX spec, or prior historical handoff changed.

### Reference study and design brief

Created `docs/FSD2_UI_REFERENCE_RESEARCH.md` with source-linked behavior observations for Finder, Xcode, DaisyDisk, ForkLift 4, Beyond Compare and VisualDiffer. It separates documented observations from proposed FSD adaptations; vendor performance statements are labeled as claims, not measurements. The brief covers navigation, hierarchy/density, large-directory strategies, path/search/filter scope, multi-pane/inspector patterns, comparison statuses/navigation, keyboard/accessibility limits, and empty/loading/error/offline states.

It presents two complete annotated directions: **Source Navigator** and **Capture Archive / Compare Bench**. Each includes an information-architecture map, text wireframes, Explore/search/Collections, source status, History, overview and dedicated Compare workspace, interaction descriptions, reusable component concepts, density/accessibility trade-offs and risks. It recommends Source Navigator because it most directly follows the accepted FSD north star and Finder/Xcode-style IA while keeping source/snapshot context visible. The alternative is retained for Owner review.

The document is explicitly a public-documentation research study, not a live usability/benchmark report: no reference-app screenshots, timings or user-consensus claims were created. The public docs do not establish full VoiceOver behavior for each reference app. These limits are stated and do not claim that such tests were performed. No UI implementation was made and `docs/UX_UI_SPEC.md` is unchanged pending Owner approval.

FSD semantics remain explicit in both proposals: offline-first browsing of completed captures; metadata-only by default; source read-only; immutable completed snapshots; interrupted capture does not replace the last complete one; “Metadata Match · Content Not Verified”; no physical-drive identity inferred from label/path alone; no automatic content preview; bounded This Snapshot search only until broader search contracts exist; existing Collection semantics retained pending the Drive Set ADR.

## Concise code review

Reviewed the complete governance diff and the full research brief against Issue #1, the accepted control state, UX UI spec, Product State, source links and exact allowed paths.

- Policy review: PASS. The local pointer is in both always-read documents; BRAIN's pre-prompt/pre-review responsibility is explicit; local text replaces a mandatory network read; retry contradiction is removed without weakening source, privacy, destructive, dirty-work, scope or integrity boundaries. Required tests still gate PASS. The Operator version is incremented and the existing return/transport shape is unchanged.
- Routing review: PASS. The mutable Antigravity inventory now states OPUS 4.6 only and SONNET excluded; neither an OPUS review nor a preparatory Worker is imposed on routine fixes.
- Research review: PASS. Every app-specific statement links to public product documentation or the current public VisualDiffer repository/wiki. The distinction between source facts and FSD proposals is explicit. Claims about VisualDiffer scale are attributed to its README, not treated as measurements. No proprietary assets/code or unverified accessibility/user-consensus claim is used.
- Scope review: PASS. Only authorized files are changed. No product UI, UX specification, accepted State, rule ledger, schema, dependency, release, or prior historical handoff is modified.
- `git diff --check`: PASS before reporting projection. Canonical control-plane validation and publication checks are finalizer closure gates and are recorded in the Desktop receipt after execution; no future result is claimed in this immutable handoff.

## Requirement evidence map

| # | Requirement | Result | Evidence |
|---:|---|---|---|
| 1 | Canonical re-anchor and expected HEAD | EVIDENCED | Non-destructive fetch; `main`, `origin/main`, and baseline all `d1d05a66700c16683e0650ec01454178f09c15df`; 0/0. |
| 2 | Owner Issue #1 read and locally discoverable | EVIDENCED | Owner issue read; full reusable directive recorded in `AGENTS.md` with URL provenance and Compact pointer. |
| 3 | Before-every-prompt/review rule and anti-bureaucracy question | EVIDENCED | `AGENTS.md` and `docs/BRAIN_OPERATOR.md`; task-execution preflight pointer. |
| 4 | Local canonical policy removes required-online-fetch dependency | EVIDENCED | Exact local section plus `ONLINE_FETCH_REQUIRED=NO_WHEN_LOCAL_CANONICAL_TEXT_IS_AVAILABLE` in Operator/skill. |
| 5 | Three ineffective same-cause attempts lead to research/change, not automatic STOP | EVIDENCED | Updated task-execution section names official APIs/SDK, upstream docs/issues, credible community and alternatives; old max-one/auto-STOP tokens absent. |
| 6 | Failed required tests block PASS but allow in-scope debugging | EVIDENCED | Explicit declarations and prose in AGENTS, Operator and skill. |
| 7 | Genuine source/safety/privacy/destructive/dirty/scope stops preserved | EVIDENCED | Explicit boundaries retained in all local policy layers. |
| 8 | No repetitive permission rounds/handoffs/duplicate audits | EVIDENCED | Policy and skill specify in-scope corrections, consolidated evidence and one historical handoff. |
| 9 | OPUS-only Antigravity routing synchronized | EVIDENCED | AGENTS, Operator inventory and task-execution; OPUS 4.6 only, SONNET excluded, conditional low-cost preparation. |
| 10 | Finder and Xcode public UI behavior reviewed | EVIDENCED | Linked Apple user/developer documentation and detailed observations in research brief. |
| 11 | DaisyDisk, ForkLift, Beyond Compare and VisualDiffer reviewed | EVIDENCED | Linked official manuals, public repo and vendor wiki; claim limits noted. |
| 12 | Required behavior dimensions analyzed without invented evidence | EVIDENCED | Research cross-cutting sections cover hierarchy, large trees, search, panes, compare, keyboard/accessibility and states; no live measurements or fabricated screenshots. |
| 13 | Two complete directions and evidence-based recommendation | EVIDENCED | Both annotated directions, maps, wireframes, interactions, components, risks, density/accessibility and comparison matrix; Source Navigator recommendation. |
| 14 | FSD identity, offline/read-only/metadata/immutable semantics preserved | EVIDENCED | Non-negotiable rules and both wireframes preserve all requested limitations. |
| 15 | No product UI implementation or UX contract alteration | EVIDENCED | Diff scope and protected-file inspection; UI source/tests and `docs/UX_UI_SPEC.md` unchanged. |
| 16 | Governance/research review and repository hygiene | EVIDENCED | Concise review above; `git diff --check` PASS; protected accepted State and rule ledger unchanged. |

## Remaining advisory and proposal

The reference research is based on public documentation rather than a live app-by-app inspection; complete reference-app VoiceOver behavior and real-world density were not established. The brief labels those limits and proposes later FSD testing. Owner selection of Direction A, Direction B or a bounded revision is pending. This is the sole Worker proposal; no subsequent product task is started or implied.

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=16
WORKER_REQUIREMENTS_EVIDENCED=16
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO
