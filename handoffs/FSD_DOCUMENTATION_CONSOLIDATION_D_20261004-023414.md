# FSD Stage D — documentation consolidation

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_CONTROL_PLANE_DOCUMENTATION_CONSOLIDATION
HANDOFF_ID=handoffs/FSD_DOCUMENTATION_CONSOLIDATION_D_20261004-023414.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=041d2af2076ff4418f9ea5d98b124c435ea8db43
REMOTE_HEAD=041d2af2076ff4418f9ea5d98b124c435ea8db43
LAST_VERIFIED_AT=2026-10-04T02:34:14+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|STATE/PROJECT_STATE.md|STATE/TASK_LEDGER.tsv|docs/README.md|docs/PRODUCT_STATE.md|docs/P15_RUNTIME_PLAN.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|scripts/check_control_plane.py
CURRENT_PHASE=DOCUMENTATION_CONSOLIDATION_WORKER_RETURN
CURRENT_GATE=STAGE_D_DOCUMENTATION_CONSOLIDATION_AND_BRAIN_ADJUDICATION
STATUS=COMPLETE_WITH_KNOWN_LIMITATIONS
BLOCKER=NONE_FOR_AUTHORIZED_DOCUMENTATION_SCOPE
PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_FSD_DOCUMENTATION_CONSOLIDATION_ADJUDICATION
NO_AUTO_NEXT=YES

## Identity, authority and publication boundary

TASK=FSD_DOCUMENTATION_CONSOLIDATION_004
ROLE=WORKER
MODE=CONTROL_PLANE_DOCUMENTATION_CONSOLIDATION
WORKER_RESULT=PASS_WITH_ADVISORY
RESULT_AUTHORITY=WORKER_EVIDENCE_ONLY
RECORDED_AT=2026-10-04T02:34:14+07:00

Owner's Stage-D directive authorizes documentation consolidation, this one return,
Desktop recovery and Git publication. Product work remains paused. No implementation,
manual acceptance, BRAIN classification or product progression is authorized here.
This immutable source records verified prepublication facts. Canonical checker,
commit/push/final fetch receipts follow creation and are recorded truthfully in
Desktop and ignored local receipts. Its own future publication SHA is not invented;
resolve it with `git log -1 --format=%H -- handoffs/FSD_DOCUMENTATION_CONSOLIDATION_D_20261004-023414.md`.

## Re-anchor and preservation

Initial main HEAD was 006dba30c6539592542a6eccb5330421b473c844 with clean tracked /
untracked primary state. Non-destructive `git fetch origin` found expected upstream
041d2af2076ff4418f9ea5d98b124c435ea8db43, ahead/behind 0/1. The intervening BRAIN commit
changed only the four STATE files: Stage-C acceptance, Stage-D authorization and
accepted rule/task projections. Reviewed that complete diff, restored exactly those
four files from the fetched SHA to index/worktree and advanced refs/heads/main with
`git update-ref` checking the old SHA. This was reconciliation of verified BRAIN
projection; no reset/clean/stash/rebase/merge was used. Repeated fetch before final
record confirmed expected main/origin/main SHA and 0/0; task mutations only.

Baseline inventory: 1454 tracked regular files, 50 timestamped histories, no owner
untracked files. Ignored inventory: 10299 original path size/mtime records, excluding
this task's ignored scratch. 10296 retained their recorded metadata; CodeGraph's
codegraph.db, codegraph.db-wal and daemon.log changed. Existing FSD daemon process
and log show an active auto-sync watcher. Worker did not write/restore/delete these
owner files or stop/reconfigure the daemon. Metadata preservation is not claimed as
ignored byte parity. `.gemini-derived-data`, fixtures, build/runtime state remain.
Task scratch is grouped in `.agent/FSD_DOCUMENTATION_CONSOLIDATION_004/`; disposable checker clone was removed.
Desktop output is explicitly authorized at the existing fallback path only.

## Resulting truth ownership

STATE/PROJECT_STATE.md is the sole accepted live control owner. EVENTS owns
append-only transitions; TASK_LEDGER owns retrieval; RULE_PROMOTION_LEDGER owns
accepted promotions. AGENTS kernel / BRAIN_OPERATOR stable governance are unchanged.
Canonical finalizer remains unchanged and directly referenced. CURRENT remains
Worker continuity and full mirror; immutable histories remain evidence; Desktop
remains full transport. Nothing in product docs sets current task/gate/next.

README is now a concise entrypoint with STATE/product ownership and a read-by-task
map. PRD retains requirements/user promise/scope/exclusions; its only change is the
KI-007 pointer. Architecture receives the unique native-settings contract from CONFIG;
all other bytes, including §9/9a, are preserved. DECISIONS is byte-identical.
TEST_PLAN is byte-identical: manual backlog, §9 and test semantics preserved.
MVP_PLAN retains five milestone outcomes/components/dependencies/validation/audit
requirements and deferred scope; dated status/audit reports and task authorization
are removed. Product evidence remains in handoffs and product baseline pointers.
PRODUCT_STATE is implementation-only: implemented capabilities, gaps, KI-compatible
limitations and scoped evidence retrieval; removed current handoff ownership,
control-plane gate, repeated chronology and audit/then-next narrative.

P15_RUNTIME_PLAN is the only new active document: exactly eight ordered planning
slices, seven preserved build-command blocks and all 61 locked contract bullets.
Old metadata/routing/closeout wrappers are normalized to model/harness-agnostic
Worker/BRAIN operation. It preserves schema-v9 prerequisite (currently unimplemented),
nullable no-default independent provider_identifier, no backfill/semantic overloading,
source/root identity and no-follow one-prefix 4096-byte read, Data-only provider,
bounded bundled-helper raw IPC/output, cancellation/reaping, one app-scoped single
flight/no queue/busy, 5-second timeout, generation guard, four-row/two-no-row outcomes,
2x-buffer bound, explicit selected-entry UI and 0.5-second progress, tests-only isolation
matrix, external license/pin/API/build/offline gate, real-helper integration audit
and terminal whole-runtime audit. Numbers remain proposed constraints, not Magika
measurements. OLD_FILE_MAPPING names all eight deleted runtime TODOs. No slice is
claimed implemented; the present seam still has sourceURL/byteBudget and schema v8.
External integration remains separately authorized research and a BRAIN-routed task
contract; no new parallel TODO, helper, schema or dependency is created.

FULL loses repeated handoff/terminal/CURRENT/generic-skill override procedures and
references canonical finalizer/Compact. Its original deferred-manual section and
independent-review policy remain exact, along with safety/rationale/platform rules.
Unique support policies moved to existing authorities: native settings → Architecture;
fixture-generator/source-write boundary and honest release artifacts → safety policy.
No Operator redesign or extra manifest/report/archive/checksum/state surface.

## Deletion and reference audit

Before each deletion, `git grep -n -I -F` searched every tracked file using full
path and basename. Every occurrence was classified: live pointer migrated; candidate
internal link removed with its packet; timestamped handoff retained byte-identical;
dated review-body citation marked historical with Git recovery; eight runtime old
filenames are OLD_FILE_MAPPING lookup keys. No broken live authority link remains.

All deleted original bytes have explicit Git-history recovery:
`git show 041d2af2076ff4418f9ea5d98b124c435ea8db43:<path>` where path is any row below.
No archive copy exists. Historical citations intentionally remain historical, not
live path promises. The four retained dated review bodies are byte-identical below
their new provenance notice. Basename schema/verify citations resolve in docs/database;
handoff basenames resolve in handoffs. Future file/module scopes in MVP/P15 are
prospective ceilings, not existence or implementation claims.

| Deleted tracked path | Disposition / unique semantic destination | Pre-delete reference occurrences |
|---|---|---:|
| `TODO.md` | FULLY_SUPERSEDED_RECOVERABLE; completed design in ADR-032/Architecture §9a and runtime design handoff; exact old task bytes Git-only | 4 |
| `TODO_GEMINI_P15_CORRECTION_A.md` | FULLY_SUPERSEDED_RECOVERABLE; completed packaging/byte/privacy correction in Architecture/safety and correction-A handoff | 5 |
| `TODO_GEMINI_P15_CORRECTION_A_FIX.md` | FULLY_SUPERSEDED_RECOVERABLE; separate provider provenance in ADR-032; correction-A_FIX handoff preserves rejected-verdict rationale | 2 |
| `TODO_GEMINI_P15_CORRECTION_B.md` | FULLY_SUPERSEDED_RECOVERABLE; §9 requirements in unchanged TEST_PLAN and correction-B handoff; stale control chronology removed | 9 |
| `TODO_GEMINI_P15_CORRECTION_C.md` | FULLY_SUPERSEDED_RECOVERABLE; terminal design verification in FSD_P15_MAGIKA_RUNTIME_DESIGN_A_20260807-155630.md | 5 |
| `TODO_GEMINI_P15_RUNTIME_IMPL_01.md` | Planning contract → docs/P15_RUNTIME_PLAN.md Slice 01; OLD_FILE_MAPPING; exact original Git-only | 4 |
| `TODO_GEMINI_P15_RUNTIME_IMPL_02.md` | Planning contract → docs/P15_RUNTIME_PLAN.md Slice 02; OLD_FILE_MAPPING; exact original Git-only | 4 |
| `TODO_GEMINI_P15_RUNTIME_IMPL_03.md` | Planning contract → docs/P15_RUNTIME_PLAN.md Slice 03; OLD_FILE_MAPPING; exact original Git-only | 2 |
| `TODO_GEMINI_P15_RUNTIME_IMPL_04.md` | Planning contract → docs/P15_RUNTIME_PLAN.md Slice 04; OLD_FILE_MAPPING; exact original Git-only | 2 |
| `TODO_GEMINI_P15_RUNTIME_IMPL_05.md` | Planning contract → docs/P15_RUNTIME_PLAN.md Slice 05; OLD_FILE_MAPPING; exact original Git-only | 2 |
| `TODO_GEMINI_P15_RUNTIME_IMPL_06.md` | Planning contract → docs/P15_RUNTIME_PLAN.md Slice 06; OLD_FILE_MAPPING; exact original Git-only | 2 |
| `TODO_GEMINI_P15_RUNTIME_IMPL_07.md` | Planning contract → docs/P15_RUNTIME_PLAN.md Slice 07; OLD_FILE_MAPPING; exact original Git-only | 2 |
| `TODO_GEMINI_P15_RUNTIME_IMPL_08.md` | Planning contract → docs/P15_RUNTIME_PLAN.md Slice 08; OLD_FILE_MAPPING; exact original Git-only | 2 |
| `docs/BUNDLE_FILE_MANIFEST.md` | Extraction-era stale checksum list; no unique product/control contract; Git-only | 7 |
| `docs/FSD_PLAN_GATE_CORRECTION_GEMINI31.md` | FULLY_SUPERSEDED_RECOVERABLE; complete correction claims in FSD_PLAN_GATE_CORRECTION_C_20260724-230500.md, rebuttal in re-audit, accepted conclusions in final re-audit/ADRs; exact report Git-only | 13 |
| `docs/KNOWN_ISSUES.md` | Unique unresolved KI semantics moved to PRODUCT_STATE/specialized pointers; fixed/superseded narratives in accepted handoffs and exact old bytes Git-only | 78 |
| `docs/PLACEMENT.md` | Superseded Desktop extraction path/instructions; repo identity → README; exact historical bytes Git-only | 6 |
| `docs/PROJECT_MANIFEST.md` | Identity/navigation → README; invariants already PRD/Architecture/ADRs; obsolete schema annotation removed | 39 |
| `docs/PROJECT_SUPPORT/APP_STRUCTURE.md` | Stale pre-Xcode suggested module/file scaffold; implemented architecture/source are authoritative; exact template Git-only | 3 |
| `docs/PROJECT_SUPPORT/CONFIG.md` | Unique native-UI settings/macOS preferences or DB contract → Architecture AppShell | 3 |
| `docs/PROJECT_SUPPORT/GITIGNORE.template` | Stale uninstalled ignore template; actual .gitignore unchanged; exact template Git-only | 7 |
| `docs/PROJECT_SUPPORT/HANDOFFS.md` | Duplicate procedure → canonical finalizer; historical legacy-layout narrative Git-only | 21 |
| `docs/PROJECT_SUPPORT/RELEASES.md` | Honest/explicit release artifact boundary → safety policy; template release layout Git-only; ADR-006 retains distribution scope | 3 |
| `docs/PROJECT_SUPPORT/SCRIPTS.md` | Unique fixture-generator/source-media boundary → safety policy; helper list is placeholder/Git-only | 7 |
| `docs/PROJECT_SUPPORT/TEST_STRUCTURE.md` | Suggested targets/fixture tree superseded by real FSDTests/TEST_PLAN; feasibility pointer migrated to TEST_PLAN §2 | 4 |
| `docs/skills/HANDOFF_SKILL.md` | Supersession-only stub; FULL/checker live refs now direct canonical finalizer; exact stub Git-only | 17 |
| `docs/skills/MODEL_SUGGESTION_SKILL.md` | Generic stack defaults/process duplicated or superseded by accepted Compact ROUTING/context/research/review; no unique accepted FSD rule; Git-only | 9 |

The completed design/correction packets contain no unique unresolved current product
decision after comparison with Architecture §9a, ADR-032, safety §2.1, TEST_PLAN §9,
and the immutable 2026-08-07 design/correction handoffs. Their stale model-specific
execution/next instructions are removed from HEAD, not propagated into active policy.
All seven PROJECT_SUPPORT entries were audited; directory disappears.

## Retained docs-root historical/research classification

| File | Classification / reason retained |
|---|---|
| docs/REFERENCE_VISUALDIFFER.md | UNIQUE_REFERENCE: detailed comparison/UX study, clean-room and GPL boundary; specialized references depend on it |
| docs/REVIEW_CLAUDE_CODE.md | UNIQUE_REFERENCE: extensive original findings/UX reasoning and §13 four-condition automatic/physical-device gate still referenced by feasibility plan |
| docs/FILESYSTEM_REPLAN_CLAUDE.md | UNIQUE_REFERENCE: schema/provider reasoning and comparison-source model explicitly used by provider/Collection authorities |
| docs/SNAPSHOT_COLLECTIONS_REVIEW_CLAUDE.md | UNIQUE_ACCEPTED_EVIDENCE: dated schema-fixture proof, Unsorted/default rationale and label/last-used tradeoffs; not reproduced as a new acceptance |
| docs/FSD_PLAN_GATE_AUDIT_GPT56SOL.md | UNIQUE_REFERENCE: original independent rejection matrix and executable SQL bypass reproductions; unique diagnostic evidence retained on demand |
| docs/FSD_PLAN_GATE_CORRECTION_GEMINI31.md | FULLY_SUPERSEDED_RECOVERABLE: removed for reasons in deletion table; no live dependency; correction/rebuttal/final accepted handoffs retain conclusions |

Other docs-root files are active specialized authorities, not automatically historical
because of original dates. When evidence compression was uncertain, retained the
unique reference; no unrequested product choice was made.

## Footprint and task retrieval

BEFORE is the exact expected base tree; AFTER is the final documentation plus one
Worker ledger row/event. Census: root .md + all docs/**/*.md + STATE/PROJECT_STATE.md
+ canonical finalizer + CURRENT; excludes immutable timestamped handoffs and ignored
scratch. Active authority census excludes CURRENT (continuity evidence) and the six
named dated/research references, adds the three non-Markdown STATE ledgers/events.
It includes obsolete active templates/packets BEFORE to measure their removal.
Bytes count UTF-8 file bytes; lines count splitlines; no tokenizer or token estimate.

| Measurement | BEFORE | AFTER |
|---|---:|---:|
| Root Markdown/control-plan files | 14 | 1 |
| Root TODOs | 13 | 0 |
| Docs-root Markdown | 26 | 22 |
| CURRENT_ACTIVE_DOCUMENT_FILE_COUNT | 51 | 26 |
| Active authority files | 47 | 23 |
| Active authority bytes | 517963 | 344918 |
| Active authority lines | 6827 | 4561 |
| DUPLICATED_LIVE_STATE_OWNER_COUNT (independent live/stale summary surfaces) | 5 | 1 |
| Extra summary copies beyond canonical owner | 4 | 0 |

Before control summaries: STATE/PROJECT_STATE, PRODUCT_STATE Current Handoff/control
gate, MVP current status/task selection, README current status/gates, KNOWN_ISSUES
KI-021 implementation authorization wording. Count excludes historical handoffs,
transport, ADR/Test Plan dated evidence and prospective runtime dependency gates.
Retired root design/correction task packets are separately counted in root TODOs.
AFTER sole accepted-control owner: STATE/PROJECT_STATE.md.

Task reads use CURRENT HOT only, relevant ledger row, applicable governance/product
sections and source sections needed by the exact question, never whole history:

| Read by task | BEFORE file count | AFTER file count |
|---|---:|---:|
| LOW_RISK_CONTROL | 6 | 6 |
| PRODUCT_REQUIREMENT | 6 | 6 |
| SCHEMA_HIGH_RISK | 16 | 16 |
| P15_RUNTIME_HIGH_RISK | 20 | 13 |

Shared retrieval files: `AGENTS.md`, `docs/BRAIN_OPERATOR.md`, `STATE/PROJECT_STATE.md`, `handoffs/CURRENT_HANDOFF.md`, `STATE/TASK_LEDGER.tsv`.

LOW_RISK_CONTROL adds `.agents/skills/fsd-handoff-finalizer/SKILL.md`.

PRODUCT_REQUIREMENT adds `docs/PRD.md`.

SCHEMA_HIGH_RISK adds `docs/AGENT.md`, `docs/PRD.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/PRODUCT_STATE.md`, `docs/TEST_PLAN.md`, `docs/SECURITY_AND_READ_ONLY_POLICY.md`, `docs/database/schema.sql`, `docs/database/verify.sql`, `FSD/Catalog/CatalogMigrations.swift`, `FSD/Catalog/EntryClassificationRepository.swift`.

P15_RUNTIME_HIGH_RISK adds `docs/AGENT.md`, `docs/PRD.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/PRODUCT_STATE.md`, `docs/TEST_PLAN.md`, `docs/SECURITY_AND_READ_ONLY_POLICY.md`, `docs/P15_RUNTIME_PLAN.md`.

P15 BEFORE adds the eight original runtime TODOs instead of the one runtime plan;
all other tier file sets are the same. These are declared bounded retrieval paths,
not measured model-token consumption or a claim that every task needs entire files.
Context improvement is also semantic: explicit ownership, no ambiguous current gate,
one runtime sequence and no preload of deleted templates/old next instructions.
LOW_RISK and requirements already had the accepted compact bootstrap; their file
counts honestly remain unchanged. No context-quality claim rests solely on bytes.

## Executed validation before immutable creation

- `git diff --check` PASS; repeated non-destructive fetch PASS, basis 0/0.
- Tracked inventory/hash verification PASS: 50 prior histories byte-identical;
  1409 paths outside the exact mutation allowlist byte-identical. Product Swift,
  executable/resources/Xcode, SQL/schema/migrations, samples/spikes/tests diff EMPTY.
- 79 current non-handoff local Markdown links resolve; retired references only in
  labeled original dated bodies or OLD_FILE_MAPPING. Contextual schema/verify and
  handoff basename paths resolve; prospective product source scope is labeled.
- Root TODO=0; support/legacy-skill directories absent; exactly one new product plan
  with eight slices, 61 locked bullets and seven bash build/test blocks preserved.
- PRD pointer-only, Architecture unique settings addition only, DECISIONS/TEST_PLAN,
  kernel/Compact/finalizer exact baseline bytes; FULL manual/review sections exact.
- Eight bounded checker fixture cases PASS: two valid canonical closures without
  legacy skill; six expected rejections (missing canonical skill/Compact/FULL,
  accepted-state mutation, self-acceptance, CURRENT mismatch). Disposable local
  clone; no product build, model run, external research/install or manual test.
- Checker code diff exactly deletes legacy HANDOFF_SKILL from REQUIRED; canonical
  finalizer/STATE/Compact/FULL remain mandatory. No second checker/helper/fixture
  framework or persistent test file. Finalizer needs no corresponding edit because
  it already refers only to the accepted canonical paths/procedure.

Canonical actual-candidate checker and final publication receipts are produced after
this creation. PASS proves mechanics, not independent semantic acceptance. No fresh
Swift/XCTest/SQL/runtime execution or owner manual acceptance is claimed in this task.

## Stage-D STATE projection and limits

Accepted PROJECT_STATE and RULE_PROMOTION_LEDGER remain byte-identical to basis.
Earlier event bytes/ordering and all other task rows remain unchanged. Exactly one
Stage-D Worker row with known basis TECHNICAL_SHA, own scope/result/handoff and
PENDING_BRAIN; exactly one appended worker_return with commit=null and handoff ref.
Publication resolves by Git history rather than a self-referential second commit.
Worker proposes documentation consolidation for adjudication, not accepted policy,
new control phase, implementation authority or product progression.

Advisories: semantic acceptance remains BRAIN-owned; retained unique dated reviews
contain historical paths/then-gates deliberately marked as evidence; ignored
CodeGraph auto-sync is observed background state, not Worker cleanup. Legacy
startup-error wording, owner manual acceptance, stock-macOS NTFS, runtime external
facts and other product gaps remain unresolved in their scoped baseline/contracts.
No automatic next task; stop after canonical publication and Worker return.
