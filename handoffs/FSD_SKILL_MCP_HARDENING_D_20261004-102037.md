# FSD skill and MCP hardening — Worker evidence

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_CONTROL_PLANE_SKILL_HARDENING
HANDOFF_ID=handoffs/FSD_SKILL_MCP_HARDENING_D_20261004-102037.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=c0b97e8c576e1adf85dc05f884431da7e4df9e5a
REMOTE_HEAD=c0b97e8c576e1adf85dc05f884431da7e4df9e5a
LAST_VERIFIED_AT=2026-10-04T14:59:22+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|STATE/PROJECT_STATE.md|STATE/TASK_LEDGER.tsv|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-independent-review/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|scripts/check_control_plane.py
CURRENT_PHASE=SKILL_MCP_HARDENING_WORKER_RETURN
CURRENT_GATE=FSD_SKILL_MCP_HARDENING_007
STATUS=EXECUTION_VERIFIED_CANONICAL_FINALIZATION_REQUIRED
BLOCKER=NONE_FOR_AUTHORIZED_CONTROL_PLANE_SCOPE
PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_FSD_SKILL_MCP_HARDENING_ADJUDICATION
NO_AUTO_NEXT=YES

## Worker identity and execution guard

TASK=FSD_SKILL_MCP_HARDENING_007
ROLE=WORKER
MODE=CONTROL_PLANE_SKILL_HARDENING
WORKER_RESULT=PASS_WITH_ADVISORY
RESULT_AUTHORITY=WORKER_EVIDENCE_ONLY
RECORDED_AT=2026-10-04T14:59:22+07:00

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=41
WORKER_REQUIREMENTS_EVIDENCED=41
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

This guard accounts for the 41 execution-candidate requirements below. It records
fresh execution postflight before canonical finalization, not a claim that this
self-containing artifact's future commit/push already occurred. Publication,
CURRENT/STATE/Desktop projection and actual-candidate checker obligations are
listed separately below and must all pass before the final task success return.
Their actual post-creation receipts go in Desktop/ignored evidence; no immutable
history rewrite or self-referential future SHA. Resolve publication through
`git log -1 --format=%H -- handoffs/FSD_SKILL_MCP_HARDENING_D_20261004-102037.md`. BRAIN alone adjudicates.

## Re-anchor, resumed session and scope

Owner authorized exactly this control-plane task and its publication. Product work
remains paused. Initial local main was 9d5416b5b00b93a91b45ac6cd782efec2a1e4305;
fetch found expected c0b97e8c576e1adf85dc05f884431da7e4df9e5a, 0 ahead / 2 behind.
Both commits were BRAIN projection only: documentation acceptance/completion and
skill hardening authorization. Reviewed the full diff; restored exactly the three
changed STATE files from expected upstream and compare-and-swap advanced main with
git update-ref. No reset/clean/stash/rebase/merge, no owner work discarded.

Execution preflight at 2026-10-04T10:20:37+07:00 captured the reconciled basis, baseline
hashes, scope and the one handoff filename above. The filename was allocated at
that preflight; RECORDED_AT is actual creation time after the owner's continuation.
The owner subsequently instructed continuation in the same session/worktree.
Resumed fetch proved the same expected main/upstream, 0/0, with the eight intended
partial implementation paths; no restart, scope expansion or new task occurred.

Physical root /Users/cenvu/DEV/FSD; origin https://github.com/cenvu/FSD.git;
branch main; upstream origin/main. Baseline: 1430 tracked files, 52 timestamped
histories, no initial untracked owner work. Current accepted PROJECT_STATE and
RULE_PROMOTION_LEDGER remain exact basis bytes. Existing task rows/events are
preserved; the finalizer adds only this task's pending row and one Worker return.

Exact authorized paths (the FULL edit is only a three-line skill pointer):
- `AGENTS.md`
- `docs/BRAIN_OPERATOR.md`
- `docs/README.md`
- `docs/AGENT.md`
- `.agents/skills/fsd-task-execution/SKILL.md`
- `.agents/skills/fsd-independent-review/SKILL.md`
- `.agents/skills/fsd-handoff-finalizer/SKILL.md`
- `scripts/check_control_plane.py`
- `STATE/TASK_LEDGER.tsv`
- `STATE/EVENTS.jsonl`
- `handoffs/FSD_SKILL_MCP_HARDENING_D_20261004-102037.md`
- `handoffs/CURRENT_HANDOFF.md`

Protected: product Swift/FSDTests/Xcode, schema/database/migrations, samples/spikes,
dependencies, all prior histories, accepted STATE/rules, root script hygiene and
every other tracked path. No product progression or manual acceptance.

## Implemented delta

- fsd-task-execution is the single provider-neutral Anti Forget owner: identity/
  scope lock, minimal changes, bounded context/debug/retry, causal TDD, MCP least
  privilege, fresh requirement postflight and one structural guard.
- fsd-independent-review composes execution with read-only risk-first review,
  precise inputs, fourteen FSD priorities, falsifiable tests, structured findings,
  verified feedback reception and future advisory OCR delegation only.
- Existing finalizer remains the sole projection/publication owner. It requires
  the reviewed execution candidate/guard, refuses scope repair or unsupported PASS,
  and demands fresh post-push/fetch state plus ambiguous-network reconciliation.
- Kernel adds five lines, Compact moves to 1.2.0 with stable concise routing/MCP
  sections, README adds three task rows, FULL adds three pointer lines. No broad
  documentation rewrite or duplicate skill bodies in always-on documents.
- The one checker adds two required skill paths and a new-handoff-only guard
  method. Counts must be nonnegative integers and sum for every result. Passing
  results additionally require zero unproven and pre/postflight PASS; truthful
  STOP/REPAIR may contain FAIL and unproven counts. Historical handoffs need no
  retrofit. Structural consistency does not prove actual skill use or reasoning.

## Execution requirement coverage

Each row is EVIDENCED (FACT about inspected candidate files or observed commands).
The count groups related acceptance clauses without dropping their subclauses.

| # | Requirement group | Status and evidence |
|---|---|---|
| 1 | Authority/re-anchor and identity | EVIDENCED — Exact task, physical root/main, expected base/upstream; initial 0/2 BRAIN-only drift reconciled; resumed fetch 0/0. |
| 2 | Exact scope / protected boundaries | EVIDENCED — 12 allowed paths; 1421 baseline paths outside allowlist byte-identical; accepted STATE/rules protected. |
| 3 | Exactly three canonical skills | EVIDENCED — Two new SKILL.md files plus existing finalizer; no adapters/support files/extra skills. |
| 4 | A: meaningful-task triggers / provider neutrality | EVIDENCED — Task-execution description and opening apply to mutation, evidence, review, publication and handoff for all Workers. |
| 5 | A: full preflight fields | EVIDENCED — Task-execution §1 includes exact task/role/root/branch/SHAs/STATE/scope/paths/success/validations/return boundary. |
| 6 | A: minimum authority load / fail closed | EVIDENCED — §1 requires kernel, accepted STATE, HOT, exact task, direct authorities and applicable skills; missing authority/identity/scope stops. |
| 7 | A: think before coding | EVIDENCED — §2 surfaces assumptions, observable success, smallest change, scope traceability, existing patterns and material-ambiguity STOP. |
| 8 | A: context discipline | EVIDENCED — §2 preserves goal/facts/decisions/identities/evidence/unknowns/next at logical boundaries; no autonomous context stores. |
| 9 | A: debug flow / classification | EVIDENCED — §3 complete error, safe reproduction, fresh state, one hypothesis/experiment and LOGIC/STATE/ENVIRONMENT/POLICY. |
| 10 | A: bounded same-family retry | EVIDENCED — §3 initial=1, repair retry max=1, repeated failure research/return, no new session as retry; negative fixtures distinguished. |
| 11 | A: causal TDD / relevant verification | EVIDENCED — §4 RED for intended reason then minimal GREEN; refactor after GREEN; relevant and task-required broader checks. |
| 12 | A: falsifiable behavior tests / no runner assumptions | EVIDENCED — §4 regression sensitivity; text tests only for text contracts; no blanket 80% quota or web runner. Checker fixtures exercise CLI behavior. |
| 13 | A: eight MCP security defaults | EVIDENCED — §5 exact requested policy keys: none by default, explicit task/Owner authorization, allowlist, untrusted output and external effects. |
| 14 | A: MCP pre-call controls | EVIDENCED — §5 identity/local-remote transport/tool/credential/network checks, least privilege, no secret printing or unapproved private disclosure/setup. |
| 15 | A: ambiguous external effects | EVIDENCED — §5 observation/reconciliation; missing acknowledgement or negative observation is not resend authority. |
| 16 | A: bounded execution | EVIDENCED — §6 no auto-next, hidden fallback, semantic provider switch without authorization or unrelated cleanup. |
| 17 | A: fresh postflight | EVIDENCED — §7 re-read task, requirement map, fresh checks, full diff/status/outputs/identity and contradiction scan; no next task. |
| 18 | A: evidence and PASS limits | EVIDENCED — §7 FACT/STRONG_INFERENCE/UNPROVEN and material-UNPROVEN prohibition; declarations are not semantic proof. |
| 19 | A: exact guard and truthful failed returns | EVIDENCED — Eight ordered unique fields; counts nonnegative/sum; PASS requires pre/post PASS and zero unproven; STOP/REPAIR truthful failures. |
| 20 | A/C: execution→finalizer handoff | EVIDENCED — Sharp canonical pointer; execution postflight precedes projection/publication, with future closure checks never reported as already run. |
| 21 | B: review trigger / read-only / role separation | EVIDENCED — Independent-review uses task-execution ROLE=REVIEWER; high-risk/explicit review; reporting exception does not authorize repair. |
| 22 | B: precise review inputs and context | EVIDENCED — REQUIREMENTS, BASE_SHA, HEAD_SHA, CHANGED_PATHS, DIRECT_AUTHORITIES; no private implementer reasoning/history preload. |
| 23 | B: fourteen FSD review priorities | EVIDENCED — All fourteen source/metadata/snapshot/recovery/schema/identity/compare/race/memory/classification/dependency/tool/evidence/scope priorities retained. |
| 24 | B: material findings and falsifiability | EVIDENCED — All five requested finding fields; causal test review, no quota of invented findings, explicit evidence limits. |
| 25 | B: feedback reception | EVIDENCED — READ→UNDERSTAND→VERIFY AGAINST FSD→EVALUATE→ACCEPT/PUSH BACK; reviewer cannot authorize own repair. |
| 26 | B: OCR future delegation only | EVIDENCED — No current FSD wrapper; no install/config/LLM/autofix; future explicit delegation selects files/rules for host reasoning; absence not blocker. |
| 27 | C: finalizer scope and guard | EVIDENCED — Existing behavior preserved; prerequisite/postflight/guard/unproven/next constraints added; no execution-scope repair. |
| 28 | C: fresh publication / ambiguous push | EVIDENCED — Finalizer requires physical post-push/fetch checks and reconciliation before retry; no blind second push. |
| 29 | D: kernel routing | EVIDENCED — Five added lines: three exact pointers/guard identity plus mandatory meaningful execution/review routing. |
| 30 | D: Compact routing/MCP policy | EVIDENCED — VERSION=1.2.0; concise stable skills/guard/MCP sections; no volatile status or model IDs. |
| 31 | D: navigation / bounded FULL pointer | EVIDENCED — README adds three read-by-task rows; FULL adds only three routing lines to avoid bypass ambiguity. |
| 32 | E: checker required skills | EVIDENCED — REQUIRED includes all three canonical SKILL.md paths; missing new skills rejected in real CLI fixtures. |
| 33 | E: guard structural validation only | EVIDENCED — New handoff only; unique contiguous block, version/enums/integers/arithmetic/next and PASS constraints; no historical retrofit. |
| 34 | E/J: required negative/positive fixtures | EVIDENCED — Causal old-code RED: 15 bad guards wrongly accepted; GREEN: 21/21 CLI fixture expectations pass, including all six required cases. |
| 35 | F: MCP installation result | EVIDENCED — Root MCP/OCR config absent; no MCP calls/config/install/dependency/wrapper created. Existing owner runtime state preserved. |
| 36 | G: conceptual provenance | EVIDENCED — Both new skills name local conceptual inputs and all four reviewed pins; upstream licenses attributed, no vendored text/files. |
| 37 | H/I: forbidden mutation boundaries | EVIDENCED — Product/Xcode/tests/SQL/dependencies/root scripts unchanged; no Magika/provider implementation, manual acceptance, benchmarking, hooks or learning store. |
| 38 | J: YAML frontmatter / unique names | EVIDENCED — Ruby Psych YAML.safe_load parses all three name/description maps; names match folders and are unique. |
| 39 | J: pointers / provider-neutral rules | EVIDENCED — 40 live local links resolve; canonical pointer assignments resolve; common procedure has no family-specific branch. |
| 40 | J: diff and historical preservation | EVIDENCED — git diff --check PASS; 52 prior histories exact; product executable/schema/tests diff EMPTY; owner partial state preserved. |
| 41 | Skill behavior forward check | EVIDENCED — One read-only skill-creator forward evaluation of five scenarios; no material contradiction; no acceptance or product-test claim. |

## Validation evidence and limits

`python3 .agent/FSD_SKILL_MCP_HARDENING_007/checker_fixtures.py RED` exercised the
original real checker CLI in a disposable local clone. Four valid cases passed;
all fifteen malformed guard cases were wrongly accepted, giving the intended RED
for missing guard enforcement, not setup failure. After the minimal checker change,
the GREEN invocation passed 21/21 cases, repeated freshly after session continuation:

- valid PASS and PASS_WITH_ADVISORY;
- missing guard, duplicate block/field and noncontiguous guard rejected;
- wrong version, negative/noninteger counts and invalid pre/post enums rejected;
- arithmetic mismatch, PASS/advisory with UNPROVEN, failed PASS pre/postflight and
  NEXT_TASK_STARTED=YES rejected;
- truthful STOP/REPAIR accepted;
- missing task-execution or independent-review canonical skill rejected.

These are behavioral CLI assertions over accept/reject outcomes. The current
version must reject the same invalid candidates accepted by the baseline.
Only temporary fixtures/scripts/receipts under the existing ignored task scratch;
no new tracked test framework/checker/helper. Disposable clones were removed.
Python syntax compilation in memory passed. `git diff --check` passed.
The scope/hash check confirms 1421 protected baseline paths, including 52 old
histories, unchanged. Product executable/schema/tests diff is empty.

The skill-creator quick_validate.py command could not start: ModuleNotFoundError
for yaml (ENVIRONMENT). No dependency installed. Existing Ruby Psych YAML.safe_load
parsed all three frontmatters; required name/description, folder/name agreement,
valid unique names and no extra scaffold files verified. Forty local links and
canonical skill path assignments resolve. This satisfies the requested parsing
check without claiming that the unavailable Python helper passed.

Skill-creator's risk-based forward evaluation used one separate read-only subagent,
with raw skills/task identity and checker diff rather than implementer reasoning.
Five cases: ambiguous mutation/resend, green tests with unproven source identity,
exhausted repair retry, truthful failed preflight STOP, and prepublication candidate.
It found no material contradiction/loophole. Minor presentation advisory: the
example preflight field shows PASS while adjacent prose explicitly permits FAIL
for STOP/REPAIR; checker behavior agrees with that prose. This is bounded reasoning
evidence, not empirical harness qualification or BRAIN acceptance. No model/harness
benchmark, product build/XCTest/schema execution or manual acceptance was performed.

## Conceptual provenance

Read 18 local conceptual input files in LOOP_APP/LOOP_ROUTER without mutation.
Observed local HEADs: LOOP_APP 43703b89c2596d6f18e9dba9eb2e5f48b24c588b;
LOOP_ROUTER d456c9d3ec7861f94f54cf5a447ee042bff5eac6. Content hash receipts identify
the actual working files; local model-specific wrappers are conceptual input only.
Pinned public upstream tree/content reads verified:

| Source | Reviewed pin | Adapted concepts |
|---|---|---|
| affaan-m/ecc | ef648e01899ba3e8dc6371642deaaf64b4477775 | Context, causal TDD, verification, security; reject hook/memory/80%/web-runner installation |
| obra/superpowers | 8ca22dba9a94f28898bbce59f2537ff4d87c747d | Root-cause investigation, fresh verification, technical review reception |
| alibaba/open-code-review | a758d9cbfb689937c7857ad64b2dd66adb58c0c2 | Deterministic file/rule delegation, host reasoning, bounded advisory role |
| multica-ai/andrej-karpathy-skills | 2c606141936f1eeef17fa3043a72095b4765b9c2 | Explicit assumptions, simplicity, surgical changes, observable success |

The browsing transport rejected pinned GitHub URLs as restricted; read-only GitHub
API/raw fetches then succeeded at all four exact pins. No fetched setup instructions
were executed, no private project data was sent, no repository was cloned/vendored
for conceptual research. Only original FSD prose and compact provenance reside in
the new skills. ECC/Superpowers MIT, Karpathy's skill-declared MIT and OCR Apache-2.0
are attributed; no upstream rights are reassigned.

## MCP result and owner-state preservation

FSD_PROJECT_MCP_CONFIG=NONE
MCP_POLICY=EXPLICIT_TASK_ONLY_LEAST_PRIVILEGE
MCP_INSTALLATION_CHANGE=NONE

No project MCP/OCR/Context7 config, remote MCP, OCR wrapper, dependency, npm package,
install/global-config script, hook or skill adapter was added. Existing empty
.claude directory predates this task and remains empty. An initial temporary scope
assertion incorrectly required that directory to be absent; inspection established
the preexisting empty directory and the check was corrected once to verify that no
adapter was created. No owner directory was removed or recreated.

Ignored baseline has 10324 path size/mtime records. Pre-return observation found
only the preexisting CodeGraph database, WAL and daemon log changing, consistent
with its previously observed background watcher; no Worker cleanup/reconfiguration.
Do not equate metadata checks with byte parity of all ignored runtime state.

Across the owner-requested session continuation, ~/.claude.json hash changed from
the initial observation (mtime advanced to 2026-10-04T14:18:39+07:00). None of this
task's commands wrote global configuration. The actor/content-change provenance is
UNPROVEN and remains an external-state advisory; the file was preserved, not restored.
Other sampled global config hashes retained their baseline values. The temporary
verifier now reports the observed external delta rather than falsely claiming all
global bytes unchanged. This does not affect the verified FSD Git identity, candidate
scope or authorization and does not authorize using its configured MCP servers.

## Canonical finalization obligations and ownership

The execution guard above precedes these finalizer-owned checks; they are not
counted as already-executed publication proof in that guard. The final task return
must freshly classify every obligation below EVIDENCED or refuse completion:

| Obligation | Proof required after creation/publication |
|---|---|
| Exactly one immutable handoff and complete CURRENT | Actual file inventory, prior-history hashes and exact timestamp/blank/source byte parity |
| Worker STATE projection only | Exactly one pending task row and append-only worker_return; accepted STATE/rules and other rows exact |
| Desktop full recovery | Actual canonical Operator 1.2.0 bytes/hash, raw four STATE pointers, current task/HEAD and complete CURRENT suffix |
| Canonical checker | Actual invocation with exact 12 allowed paths, base SHA, branch/origin and require-desktop; final require-clean/require-synced |
| Publication | Explicit push, fresh fetch, actual HEAD/upstream 0/0 and clean primary; ambiguous result reconciled before any retry |
| Final return/stop | Actual receipts summarized, one BRAIN proposal, exact Desktop path, no root-script hygiene or product/P15 task started |

The canonical finalizer creates this source once, full CURRENT and Worker-owned
TASK_LEDGER/EVENTS projection with classification pending BRAIN. TECHNICAL_SHA is
the known basis; publication SHA resolves by handoff Git history. No accepted-state
or rule promotion write. Desktop includes canonical 1.2.0 Operator and accepted
STATE copied from repository; the earlier Desktop had no separate BRAIN review/
classification/active-next fields to preserve. Its stale accepted-state projection
is replaced from the explicitly supplied BRAIN commits, not Worker adjudication.

Finalization receipts remain in the Desktop envelope and ignored task evidence.
This source never claims future successful push or modifies historical bytes to
insert that receipt. Material finalization failure blocks the completion return.
Advisories are bounded: optional Python validator dependency absent, no empirical
harness activation claim, observed external owner/runtime drift preserved, and
semantic acceptance remains BRAIN-owned. Stop at the one proposal in HOT.
