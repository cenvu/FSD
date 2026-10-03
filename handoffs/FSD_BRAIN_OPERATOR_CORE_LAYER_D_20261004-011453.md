# FSD Stage B — canonical BRAIN Operator core layer

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_CONTROL_PLANE_OPERATOR_CORE
HANDOFF_ID=handoffs/FSD_BRAIN_OPERATOR_CORE_LAYER_D_20261004-011453.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=481d0b17ff748c983d37e0ca4de0f62fd75d59e5
REMOTE_HEAD=481d0b17ff748c983d37e0ca4de0f62fd75d59e5
LAST_VERIFIED_AT=2026-10-04T01:10:44+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|docs/AGENT.md|handoffs/FSD_BRAIN_OPERATOR_DISCOVERY_AND_BASELINE_D_20261004-003712.md
CURRENT_PHASE=CONTROL_PLANE_STAGE_B_ONLY
CURRENT_GATE=CORE_LAYER_BRAIN_ADJUDICATION_PENDING
STATUS=COMPLETE_WITH_KNOWN_LIMITATIONS
BLOCKER=NONE_FOR_STAGE_B_SCOPE
PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_FSD_BRAIN_OPERATOR_CORE_LAYER_ADJUDICATION
NO_AUTO_NEXT=YES

## Identity and result scope

TASK=FSD_BRAIN_OPERATOR_CORE_LAYER_002
ROLE=WORKER (D — control-plane core implementation)
MODE=CONTROL_PLANE_OPERATOR_MIGRATION
RECORDED_AT=2026-10-04T01:14:53+07:00
WORKER_RESULT=PASS_WITH_ADVISORY
RESULT_AUTHORITY=WORKER_EVIDENCE_ONLY
BRAIN_ADJUDICATION=NOT_PERFORMED_BY_WORKER
STAGE_SCOPE=B_ONLY

Owner explicitly accepted the Stage-A discovery findings and authorized this
bounded Stage-B implementation. The canonical core exists locally and its
prepublication checks passed. This immutable record captures the verified
prepublication snapshot; the publication SHA/push/final-fetch/status receipts
are recorded after commit in the refreshed Desktop Worker envelope. No future
Git SHA or successful push is invented inside its own historical file.

## Git re-anchor and preservation baseline

- Root: `/Users/cenvu/DEV/FSD`; branch `main`; remote fetch/push
  `https://github.com/cenvu/FSD.git`; upstream `origin/main`.
- Initial non-destructive fetch and the second fetch before this handoff exited 0:
  `git -c gc.auto=0 fetch --no-prune --no-tags --no-recurse-submodules origin`.
- At 2026-10-04T00:58:56+07:00, local/upstream both `481d0b17ff748c983d37e0ca4de0f62fd75d59e5`;
  ahead/behind `0/0`; tracked/index/nonignored-untracked primary state clean.
  At 2026-10-04T01:10:44+07:00, both still that baseline. No head reconciliation was needed.
- One registered primary worktree; inactive historical benchmark refs preserved.
  No benchmark run, reset/clean/stash/rebase/merge/prune or config mutation.
- Original tracked-file content inventory: 1443 SHA-256 records,
  including all **48** prior timestamped handoffs. Existing ignored-state inventory:
  **10294** path metadata records (size, mtime, mode and link
  target). All remained unchanged at prepublication except authorized docs/AGENT.
  Ignored metadata comparison is not a claim of full ignored-content hashing.
- Raw local evidence: `.agent/FSD_BRAIN_OPERATOR_CORE_LAYER_002/`, already ignored
  by the existing root policy. No extra tracked report or persistent checker source.

Resolve this handoff's publication commit from repository history:
`git log -1 --format='%H %s' -- handoffs/FSD_BRAIN_OPERATOR_CORE_LAYER_D_20261004-011453.md`.
LOCAL_HEAD/REMOTE_HEAD in HOT are the snapshot at LAST_VERIFIED_AT, not a fabricated
self-containing publication SHA. BRAIN must fetch/re-anchor for adjudication.

## Implemented core and bounded FULL changes

| Surface | Implemented role | Exact bytes / lines |
|---|---|---:|
| `AGENTS.md` | Discoverable omission-critical root kernel | 1,387 / 39 |
| `docs/BRAIN_OPERATOR.md` | Canonical stable Compact, VERSION=1.0.0 | 9,222 / 219 |
| `docs/AGENT.md` | Existing FULL/deep reference; on-demand loading and permanent compact Worker return | 10,534 / 207 |

### Root kernel

Contains every requested identity, authority, unknown/dirty preservation,
catastrophic source/snapshot/content-truth rule, research/reuse/no-fallback,
no-benchmark/no-auto-next, BRAIN ownership, proposal-only Worker next, layer path
and progressive-context semantic. Two omission-critical additions retain flat
immutable history/full CURRENT compatibility and existing required review gates.
The exact task resolves executor role/scope; BRAIN_ROLE does not turn a Worker
into BRAIN. No current SHA, schema/slice/workstream/blocker/test/manual state,
model-version recommendation or historical narrative is present.

Original AGENT was **9,492 bytes / 181 lines**. Kernel is **1,387 / 39**:
**8,105 fewer bytes / 142 fewer lines**; its bytes are
14.61% of the original AGENT. This proves material file-size separation,
not harness activation, effective token use or universal context savings.

### Canonical Compact

All 16 requested sections exist: AUTHORITY, BRAIN_ROLE, WORKER_ROLE, ADJUDICATION,
HUMAN_MACHINE_COMMS, HANDOFF_SEMANTICS, RESEARCH_FIRST, REANCHOR, ROUTING,
SECTION_OWNERSHIP, DETERMINISTIC_VS_SEMANTIC, CONTEXT_TIERS, NEXT_DECISION, SAFE_GC,
FSD_NON_NEGOTIABLE_SAFETY and DESKTOP_FALLBACK_CONTRACT.

Reconciles the prior embedded Operator with accepted Stage-A findings: physical
local/worktree truth and owner authorization answer separate questions; Worker
output is evidence; BRAIN verifies/adjudicates/explains/routes. It preserves all
required classification/next enums, Vietnamese owner explanation, dense Worker
communication, exactly one bounded task/proposal, all 12 re-anchor events and
three-cycle watchdog, context tiers and safe GC. Routing has one primary/fallback
and preserves mandatory existing independent-review boundaries without requiring
an extra reviewer for every routine low/medium-risk task.

The old volatile orientation/SEED section is absent. No concrete current SHA,
schema, P15 slice/gate/blocker/test/manual/MVP/runtime implementation state or
model ID is embedded. Policy wording such as CURRENT_MODE/CURRENT_HANDOFF names
stable transport contracts, not a live product status. Safety is omission-critical:
read-only sources, metadata defaults, immutable/transactional complete snapshots,
truthful metadata comparison, bounded memory and optional offline derived
classification isolation. Detailed rationale stays in scoped product authority/FULL.
No product implementation, release or manual acceptance is authorized by policy.

### FULL / return migration

`docs/AGENT.md` changed in three bounded diff hunks: title/loading designation;
one old terminal-return bullet; one new Worker terminal-return section. It adds
root/Compact links and states it is not default startup context. The permanent
return is TASK/RESULT/WHAT/BRAIN file pointer, at most five material dense evidence
lines, then `NEW HANDOFF!!!`. RESULT remains Worker evidence; BRAIN explains to
the human. Historical 10-line returns remain valid immutable evidence.

All **10 other pre-existing level-two sections** remain byte-identical. The
existing Handoff Artifact Rules section differs only in that terminal-return
bullet. No source-safety, snapshot, provider, manual, skill, handoff-path/mirror or
review semantics were broadly rewritten. No generic Handoff Skill byte changed.
FULL grew by **1,042 bytes / 26 lines** for designation/return migration.

## Desktop canonical projection and recovery

PACKET remains `FSD_BRAIN_RETURN_V1_0` with its existing encoding/transport role,
HOT/current facts, Worker envelope and separated BRAIN-owned fields. The stable
Operator is replaced with the canonical Compact; the old independently edited
body and stale SEED/orientation section are removed. Actual policy bytes now
originate from `docs/BRAIN_OPERATOR.md`; the file stays outside Git.

Projection metadata lives outside the policy payload:

```text
BRAIN_OPERATOR_PATH=docs/BRAIN_OPERATOR.md
BRAIN_OPERATOR_VERSION=1.0.0
BRAIN_OPERATOR_SHA256=b78222ad739aaec866e451a303b7c0723c43320b39d826219b4feea04162dd29
BRAIN_OPERATOR_PROJECTION=EXACT
```

Byte boundary: one standalone `# BRAIN OPERATOR BEGIN` line terminated by LF;
payload starts immediately after that LF; ends immediately before the first byte
of the standalone `# BRAIN OPERATOR END` line. Canonical trailing LF is included;
markers/wrappers and transport bytes are excluded. No inserted blank line or
newline conversion. Equality is checked on raw bytes, not normalized text.

**Executed prepublication:** actual Desktop payload equals canonical bytes;
SHA-256 of both equals the digest above; metadata version is the actual canonical
VERSION. Current facts remain outside the payload. The final envelope/current
report is refreshed after publication using the actual commit/fetch receipts.
Prior BRAIN-owned review/classification/accepted-state/active-next fields and its
initial note remain labeled prior-session state; Worker does not claim fresh
BRAIN adjudication or rewrite those fields. Recovery keeps the full new CURRENT
report, not just a repository pointer. Repository/worktree facts outrank transport.

## CURRENT and historical compatibility

One new timestamped record: `handoffs/FSD_BRAIN_OPERATOR_CORE_LAYER_D_20261004-011453.md`.
CURRENT is written as `UPDATED_AT: 2026-10-04T01:14:53+07:00` + LF + blank line + these exact complete
historical bytes. HOT is part of this source; HMD_SCHEMA/HMD_VERSION are descriptive
handoff metadata, not a new parser or product schema. No pointer-mode migration,
CURRENT.md, nested AI_HANDOFFS/date/SESSION path or checksum sidecar is introduced.
All **48** prior historical handoffs remain immutable and byte-identical, including
the accepted Stage-A evidence. Product-state's prior historical pointer is left
within the bounded scope; CURRENT owns this task's live continuity projection.

## AFTER context measurement and factual comparison

Metrics are actual UTF-8 bytes and physical lines, including trailing LF. No token
estimator, model scoring, latency comparison or subjective output test was used.

| Package / surface | Files touched by reading | Bytes | Lines |
|---|---:|---:|---:|
| Accepted Stage-A BEFORE operational meaningful-handoff workflow set | 3 | 25,092 | 587 |
| AFTER root-only known always-on project kernel | 1 | 1,387 | 39 |
| AFTER known stable BRAIN startup/operator package: kernel + Compact | 2 | 10,609 | 258 |
| Stage-B HOT section only | 1 section of historical/CURRENT | 764 | 20 |
| AFTER illustrative BRAIN package + actual HOT section | 3 file surfaces, HOT partial | 11,373 | 278 |
| Existing triggered generic Handoff Skill, unchanged | 1 additional | 5,035 | 219 |
| Illustrative BRAIN package + HOT + triggered handoff skill | 4 surfaces, HOT partial | 16,408 | 497 |
| FULL if the exact task requires its complete body | 1 additional | 10,534 | 207 |

Stage-A BEFORE was old AGENT (9,492/181) + then-CURRENT (10,565/187) + triggered
Handoff Skill (5,035/219). It was conditional operational context, not automatic
harness injection. AFTER stable kernel+Compact is arithmetically **14,483
fewer bytes / 329 fewer lines** than that chosen BEFORE set; these sets
contain different roles/sections. The table keeps HOT and the unchanged triggered
skill costs visible rather than assuming them free. Exact task bytes, directly
required product/evidence sections, system/user/global policy and skill metadata
are additional and task/host dependent. Workers need not always read all Compact;
FULL can still be necessary for audits/ambiguity. The new policy does not require
full CURRENT or all history at startup. These are known footprint/separation
measurements, **not a universal context-saving claim or activation proof**.

## Discovery validation

Location verified on disk: `/Users/cenvu/DEV/FSD/AGENTS.md` is a nonempty root file
under the resolved canonical Git/workspace root. No overriding root AGENTS.override
or ancestor project CLAUDE-family suppression files were found. Versions re-read:
Codex CLI **0.160.0**, OpenCode **1.18.34**, Claude Code **2.1.288**. Antigravity
app **2.12.2** and separate IDE **2.5.5** reconfirmed from Info.plist.

| Harness | Documented location/eligibility verified | Limit |
|---|---|---|
| Codex | Root AGENTS participates in project root-to-CWD instruction discovery; effective profile has no project fallback/override changing this name | Newly created file is not claimed injected into this already-running session; restart/new-session activation not probed. |
| OpenCode | Root AGENTS is the preferred project rules surface; project/ancestor traversal documented | Nested runtime timing, custom managed configuration and execution-time uptake remain version-sensitive. |
| Current Antigravity | Root workspace AGENTS is documented alongside GEMINI and directory rules; scoped discovery documented | Exact installed app/IDE rollout and active workspace/session uptake not activation-probed. |
| Eligible Claude | Installed version exceeds documented native-AGENTS minimum 2.1.277; no project/ancestor CLAUDE-family suppressor; inspected safe user settings have no agents-md override/disable | User ~/.claude/CLAUDE.md is exempt from suppressing native AGENTS. Plugin rollout, trust/managed policy and fresh activation remain unverified. |

Official discovery sources actually fetched during accepted Stage A in this same
session/date and reused as primary evidence: [Codex instructions](https://learn.chatgpt.com/docs/agent-configuration/agents-md),
[OpenCode rules](https://opencode.ai/docs/rules/), [Antigravity rules](https://antigravity.google/docs/rules),
[Claude memory/instructions](https://code.claude.com/docs/en/memory).
Source receipts remain in the ignored Stage-A directory; material findings are
also durable in its accepted handoff. This is documented-location/local-eligibility
validation, **not model-observed functional activation**. No harness installation,
login/global config change, discovery model call or model-vs-model run occurred.
No additional adapters/skills were required or created in this bounded task.

## Validation receipts and publication boundary

Executed before creating this historical record:

- Two non-destructive fetches; baseline/upstream equality and clean initial primary.
- `git diff --check` passed on current tracked modifications.
- SHA-256 comparison of every inventoried prior tracked file: only allowed
  docs/AGENT changed; new untracked candidates exactly AGENTS and Compact.
- All 48 old historical handoffs, generic skills, product source/resources,
  schema/SQL, tests/project and remaining docs/TODOs unchanged.
- 10294 existing ignored metadata records preserved.
- Required kernel semantics, all Compact sections/events/enums/context/ownership
  semantics present; prohibited volatile terms/concrete SHA absent in core policy.
- Root kernel materially smaller than original AGENT; exact metrics/digests captured.
- Actual Desktop payload/canonical byte parity and digest/version match passed.
- FULL section comparison proved the bounded edits; all protected sections intact.

After this record/CURRENT are written, run staged and unstaged `git diff --check`,
verify exactly the five allowlisted paths, source/full-copy parity, one proposal,
unchanged historical hashes and Desktop binding, then commit/push the bounded
publication. Final fetch/local-upstream relation and clean primary are recorded
in the final Desktop Worker envelope/local receipts. This immutable snapshot
separates already-executed checks from post-creation publication verification.
No product build/XCTest/SQL/manual acceptance was run or claimed; protected-byte
and diff-scope proof establishes this task's lack of executable/schema/test change.

Expected complete tracked publication scope:

```text
AGENTS.md
docs/BRAIN_OPERATOR.md
docs/AGENT.md
handoffs/FSD_BRAIN_OPERATOR_CORE_LAYER_D_20261004-011453.md
handoffs/CURRENT_HANDOFF.md
```

External authorized refresh: `/Users/cenvu/Desktop/04_FSD_BRAIN.md`.
Ignored evidence: task-specific .agent directory. No other tracked path is needed.
Desktop contains full recovery evidence and the exact canonical policy projection;
it is not repository authority and is not added to Git.

## Advisories and retained boundaries

- Documented discoverability is implemented; actual fresh-session harness uptake
  remains version/configuration-sensitive and unprobed. BRAIN acceptance remains
  pending; no Worker-authored BRAIN review/classification/accepted-state/active-next.
- Generic Handoff Skill legacy defaults and other Stage-A drift remain unchanged.
  FSD's existing FULL overrides still apply. No .agents skills, review skill,
  persistent checker or finalizer script exists as a result of this task.
- Product-state/MVP/known-issues/TODO/manifest consolidation or correction remains
  outside scope. No Swift, test semantics, schema, provider_identifier, Magika,
  Phase 1.5 progression, manual acceptance or unrelated cleanup.
- Compact version/digest metadata is a manual exact projection contract with
  executed inline verification; it does not pretend persistent automation exists.
- Local ignored receipts are not pushed. All material implementation/metric/
  boundary/discovery evidence needed for review is in this one durable record.

## Exactly one proposed next and stop

The only proposal is the PROPOSED_NEXT field in HOT. It is Worker evidence, not
BRAIN-authorized continuation. Stop after publication, full Desktop refresh and
final verification. Stage C and product work are not started.
