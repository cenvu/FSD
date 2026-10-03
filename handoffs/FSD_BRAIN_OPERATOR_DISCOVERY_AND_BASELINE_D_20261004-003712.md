# FSD Stage A — BRAIN Operator discovery and baseline

## HOT orientation

PROJECT=FSD
TASK=FSD_BRAIN_OPERATOR_DISCOVERY_AND_BASELINE_001
ROLE=WORKER (D — discovery/documentation)
MODE=CONTROL_PLANE_DISCOVERY_READ_MOSTLY
RECORDED_AT=2026-10-04T00:37:12+07:00
STATUS=COMPLETE_WITH_KNOWN_LIMITATIONS
DISCOVERY_RESULT=PASS_WITH_ADVISORY
RESULT_SCOPE=WORKER_LOCAL_DISCOVERY_ONLY
BRAIN_ACCEPTANCE=NOT_AUTHORED
WORKSTREAM=CONTROL_PLANE_STAGE_A_DISCOVERY
PARKED_PRODUCT_WORKSTREAM=PHASE_1_5_MAGIKA_RUNTIME
CURRENT_GATE=RETURN_EVIDENCE_FOR_STAGE_A_ADJUDICATION
PRODUCT_RUNTIME_IMPLEMENTATION=NOT_STARTED_INACTIVE
CURRENT_SCHEMA=v8
MANUAL_ACCEPTANCE=NOT_PERFORMED_DEFERRED_BY_OWNER
OVERALL_MVP_APPROVAL=NOT_CLAIMED
REPO=/Users/cenvu/DEV/FSD
CANONICAL_UPSTREAM=https://github.com/cenvu/FSD.git
BRANCH=main
LOCAL_HEAD_AT_DISCOVERY=22640bef294eff146777dd45db545c995384afa2
UPSTREAM=origin/main
UPSTREAM_HEAD_AT_DISCOVERY=22640bef294eff146777dd45db545c995384afa2
AHEAD_BEHIND_AT_DISCOVERY=0/0
AUTHORITY_REFS=docs/AGENT.md|docs/PRODUCT_STATE.md|docs/DECISIONS.md#ADR-032|handoffs/CURRENT_HANDOFF.md
HANDOFF_ID=handoffs/FSD_BRAIN_OPERATOR_DISCOVERY_AND_BASELINE_D_20261004-003712.md
HOT_NEXT_REF=#exactly-one-proposed-next
NO_AUTO_NEXT=YES
NO_MODEL_BENCHMARK=YES
PRODUCT_MUTATION=FORBIDDEN

## Identity, authority and Git freshness

Owner's current Stage-A directive controls scope and authorization. Physical Git state controls implemented facts. The pilot handover at `/Users/cenvu/Downloads/FSD_BRAIN_OPERATOR_ARCHITECTURE_PILOT_HANDOVER_20261003.md` was read as migration guidance only. Its bootstrap SHA, old CURRENT and then-next are superseded by physical evidence. Owner authorization and repository truth concern different questions: neither chat intent nor this report proves implementation.

- Root resolved with `git rev-parse --show-toplevel`: `/Users/cenvu/DEV/FSD`; Git dir `.git`.
- `origin` fetch and push URL: `https://github.com/cenvu/FSD.git`; branch `main`, configured remote `origin`, merge ref `refs/heads/main`, upstream `origin/main`.
- Initial `git fetch origin` exited 0. Explicit non-pruning/no-tag/no-recursion fetch before evidence publication also exited 0. Both local/upstream equal the expected routing SHA `22640bef294eff146777dd45db545c995384afa2`; `git rev-list --left-right --count HEAD...origin/main` = `0 0`.
- Primary tracked/index/untracked nonignored preflight state clean. One registered primary worktree only. Inactive preserved benchmark branch refs both at the old bootstrap are historical; no run or benchmark was started.
- 1,443 tracked files recorded by SHA-256, including all 47 existing historical handoffs. 10,246 pre-existing ignored paths recorded by size/mtime/mode/link metadata; ignored state was preserved, including DerivedData, spikes, `.codegraph` and `.DS_Store`. This metadata proof is not a content digest claim for ignored artifacts.
- Prepublication comparison: 1,443 tracked files unchanged; all 47 old historical handoffs unchanged; all 10,246 ignored metadata records unchanged. No reset/clean/stash/rebase/merge/prune was performed in this task.

This immutable record captures a prepublication snapshot. It does not predict its own commit SHA or falsely report a future push as completed. Resolve the publication commit with:
`git log -1 --format='%H %s' -- handoffs/FSD_BRAIN_OPERATOR_DISCOVERY_AND_BASELINE_D_20261004-003712.md`.
The refreshed Desktop Worker envelope records the actual final publication SHA, push/fetch result and primary status. A later BRAIN must fetch/re-anchor again.

RAW_EVIDENCE_ROOT=.agent/FSD_BRAIN_OPERATOR_DISCOVERY_AND_BASELINE_001/
RAW_RECOVERABILITY=LOCAL_IGNORED_ONLY;DURABLE_FINDINGS_INLINE_IN_THIS_HANDOFF
Evidence includes command receipts, safe configuration allowlist, original CURRENT/Desktop/pilot/task bytes, file/section metrics, tracked SHA-256 inventory and ignored preservation metadata. Ignored logs are not required for recovering the material findings below.

## A. Entrypoint and harness discovery

### Evidence method and limits

Local executable presence, `--version`, `--help`, app Info.plist/product metadata and allowlisted configuration fields were inspected first. Official upstream pages were then actually opened and their text captured locally. No harness was installed, authenticated or used to execute a model discovery prompt. No credentials were read; full user settings, auth stores and session transcripts were not dumped. No isolated fixture was needed to answer the documented discovery rules. Therefore runtime activation fidelity, undisclosed managed policy and vendor rollout differences remain UNKNOWN; documented behavior is not relabeled as a model-observed activation trace.

### Harness matrix

| HARNESS | HARNESS_PRESENT / VERSION | AUTO_DISCOVERED_ROOT_INSTRUCTION_FILES | AUTO_DISCOVERED_NESTED_INSTRUCTION_FILES | SKILL_DISCOVERY_LOCATIONS | EXPLICIT_LOAD_REQUIRED | PROJECT_CWD_DEPENDENCE | OBSERVED_OR_DOCUMENTED_PRECEDENCE / UNKNOWN_FIELDS |
|---|---|---|---|---|---|---|---|
| Codex CLI | YES; actual executing harness; `codex-cli 0.160.0` | `AGENTS.override.md`, then `AGENTS.md`, then configured fallback filenames, one nonempty file per directory; global effective CODEX_HOME instruction first | Root-to-CWD ancestry chain, not every descendant instruction at root startup | `.agents/skills` from CWD up to repo root; `~/.agents/skills`; `/etc/codex/skills`; bundled/system/plugin surfaces | YES for `docs/AGENT.md` and both loose `docs/skills/*.md`; standard skills expose metadata before triggered body load | YES; Git root/CWD choose policy ancestry and skill scope | Deeper project files appended after broader ones; override wins within a directory; docs default cap 32 KiB. Effective CODEX_HOME has neither AGENTS file and neither inspected config supplies fallback filenames. Current skill catalog has no FSD project skills. Orchestrator policy injection beyond files: UNKNOWN. |
| Antigravity | YES; `/Applications/Antigravity.app` app 2.12.2; `/Applications/Antigravity IDE.app` app 2.5.5; IDE CLI/platform 1.107.0, commit ecfbad74d93962fc8ca485d93ab9b4f3d4cb6cf8, arm64 | Current official docs: workspace `AGENTS.md` or `GEMINI.md`; `.agents/AGENTS.md` or `.agents/GEMINI.md`; modular `.agents/rules/*.md`, legacy `.agent/rules/*.md`; global `~/.gemini/AGENTS.md`, `GEMINI.md`, corresponding `config/` files/rules | Directory-scoped discovery on file read/edit up to workspace root; rules may be always_on, manual, glob or model_decision | Workspace `.agents/skills/<name>/SKILL.md`, legacy `.agent/skills`; global `~/.gemini/config/skills` | YES for FSD `docs/AGENT.md` and loose skills absent a registered include; plain @filename is a resolved pointer, not body inclusion | YES; active workspace root and accessed file scope, not merely shell cwd | Cumulative scopes, specific directory rules take priority. Inline include syntax is `@{path}`. Docs advertise IDE support; exact rollout/activation on these two installed app builds and simultaneous AGENTS/GEMINI tie order UNKNOWN. Local IDE help supplies no rule-loader trace. |
| Gemini CLI | NO executable on current PATH; VERSION=UNKNOWN_NOT_INSTALLED_ON_PATH; `.gemini` exists, which does not prove CLI installation | Not tested locally. Official CLI docs default to `GEMINI.md`; `context.fileName` can configure names | Docs describe workspace/ancestor and just-in-time directory context | Docs: `.gemini/skills` or `.agents/skills`; user equivalents; extensions/built-ins | FSD AGENT/loose skills would require explicit reference/configuration | Workspace/trusted-root dependent | No context.fileName override in inspected user settings. Installed/runtime behavior UNKNOWN; no install/probe performed. Not an additional active FSD harness assumption. |
| OpenCode | YES on PATH; `1.18.34`; actual FSD usage frequency UNKNOWN | `AGENTS.md`; `CLAUDE.md` fallback; global `~/.config/opencode/AGENTS.md`, falling back to `~/.claude/CLAUDE.md` | CWD ancestor traversal; official rules page does not fully specify every nested read-time loading detail | Project `.opencode/skills`, `.claude/skills`, `.agents/skills`; user `~/.config/opencode/skills`, `~/.claude/skills`, `~/.agents/skills` | YES for `docs/AGENT.md` unless `instructions` configured or agent explicitly reads it; ordinary Markdown file refs are not automatically expanded | YES; project scope and walk to Git worktree root | First match per instruction category, AGENTS before CLAUDE; configured instructions combine with them. User json/jsonc have no instructions or skills fields. Disable-Claude env switches unset. Nested runtime activation and exact duplicate-skill collision ordering UNKNOWN. |
| Claude Code | YES on PATH; `2.1.288`; FSD reviewer evidence exists; current usage frequency UNKNOWN | `CLAUDE.md`, `.claude/CLAUDE.md`, `CLAUDE.local.md`; recent native `AGENTS.md`/`.claude/AGENTS.md` conditionally when no CLAUDE-family project file in CWD/ancestors; user/managed instructions separate | Ancestors at startup; nested files on read; AGENTS conditional on no local CLAUDE-family file; `.claude/rules` path scopes | `.claude/skills/<name>/SKILL.md` at repo ancestry, nested on access; `~/.claude/skills`; managed/plugin/additional-directory locations; old commands supported | YES for FSD `docs/AGENT.md`/loose skills. @path imports in CLAUDE/eligible AGENTS are expanded; native .agents skill discovery is not documented | YES; startup cwd, ancestors, file-access and added-dir rules | Cumulative instruction chain, root toward cwd, local after shared. Native AGENTS requires >=2.1.277; installed version qualifies. Safe inspected settings have no agents-md disable/override; no ancestor project CLAUDE-family files found except user ~/.claude/CLAUDE.md, which docs explicitly exempt from AGENTS suppression. Bundled plugin activation/rollout in a fresh session, managed settings and trust state UNKNOWN. |

The Antigravity app and its separate IDE have different version namespaces; the IDE CLI's 1.107.0 is not substituted for the product's 2.5.5. Gemini user directories are not mistaken for a CLI binary. Presence of OpenCode is not a claim that it ran a prior FSD task.

Official sources supporting the matrix: [Codex instructions](https://learn.chatgpt.com/docs/agent-configuration/agents-md), [Codex skills](https://learn.chatgpt.com/docs/build-skills), [Antigravity rules](https://antigravity.google/docs/rules), [Antigravity skills](https://antigravity.google/docs/skills), [Gemini context](https://geminicli.com/docs/cli/gemini-md/), [Gemini skills](https://geminicli.com/docs/cli/skills/), [OpenCode rules](https://opencode.ai/docs/rules/), [OpenCode skills](https://opencode.ai/docs/skills/), [Claude memory/instructions](https://code.claude.com/docs/en/memory), [Claude skills](https://code.claude.com/docs/en/skills). Retrieved in this Stage-A session on 2026-10-04 +07:00; source text remains version/rollout-sensitive.

### FSD-specific answers

1. **Does docs/AGENT.md auto-load anywhere?** No default rule documented for the audited harnesses recognizes the singular loose `docs/AGENT.md`. No repository adapter/registered include/discovery override was found. The current Codex catalog does not expose the two FSD reference skills. An agent may choose to read AGENT from a task/README link; that is explicit or model-directed reading, not automatic injection. Antigravity's global skill collection is not proof it loads FSD AGENT. Hidden host injection remains UNKNOWN.
2. **Would root AGENTS.md materially improve discovery?** YES, documented for Codex/OpenCode/current Antigravity and conditional current Claude. This is a projected discovery advantage, not a completed activation test. Older/restricted Claude sessions may need an import adapter. Gemini CLI, if later installed, needs GEMINI import or a context filename override. No adapter was created.
3. **Can one policy serve them without duplication?** YES as a canonical root kernel plus references and narrowly justified adapters. Native reference/include syntax is not uniform: Codex/OpenCode do not guarantee arbitrary path expansion, while Claude @path and Antigravity @{path} do. Put catastrophic rules in the discoverable kernel itself; make any adapter reference/import the same canonical bytes rather than copying policy. Cross-harness skill bodies can be canonical once, with discovery symlinks/wrappers only where supported and verified in Stage B/C.

Observed local directories: no repo `.agents`, `.opencode`, `.gemini`, `.agent/rules`, `.agent/skills`; `.claude` exists but is empty. `docs/skills` contains two loose files, neither a standard `<name>/SKILL.md` bundle. Their `default_load: false` is a project/reference convention, not a documented discovery switch for these files in all harnesses. The generic handoff name/frontmatter also needs normalization if promoted into strict OpenCode skill discovery.

User instruction files: default `~/.codex/AGENTS.md` and OpenCode global AGENTS are identical 5,406-byte/143-line bodies. This Codex session uses `/Users/cenvu/.antigravity_cockpit/instances/codex/cli-69dff02cc1f2` as CODEX_HOME, where no AGENTS file exists, so the default home's file is not assumed loaded. Gemini global GEMINI is empty; Claude user CLAUDE is one byte. System/managed/host policy context is not quantified. No user/global configuration was changed.

## B. Authority and document inventory

One primary classification is assigned per meaningful current surface; mixed responsibilities/drift are explained in the last column. Historical document review categories indicate evidence to preserve, not permission to rewrite dated reports. Source implementation files were inspected/measured only to ground schema/checker/control references; they are not assigned new control-plane authority roles.

BEFORE_INVENTORY=13_ROOT_TODOS+25_DOCS_ROOT+2_REFERENCE_SKILLS+6_SUPPORT_DOCS+1_CURRENT
BEFORE_CONTROL_FILES=47
BEFORE_CONTROL_BYTES=683135
BEFORE_CONTROL_LINES=9083
BEFORE_TIMESTAMPED_HANDOFFS=47
BEFORE_TIMESTAMPED_HANDOFF_BYTES=814052

| Surface | Classification | Bytes | Lines | Meaning / drift |
|---|---|---:|---:|---|
| `TODO.md` | SUPERSEDED_REFERENCE | 38833 | 447 | Completed/replaced design or correction packet; historical instructions/then-next do not authorize execution. |
| `TODO_GEMINI_P15_CORRECTION_A.md` | SUPERSEDED_REFERENCE | 22442 | 203 | Completed/replaced design or correction packet; historical instructions/then-next do not authorize execution. |
| `TODO_GEMINI_P15_CORRECTION_A_FIX.md` | SUPERSEDED_REFERENCE | 13432 | 138 | Completed/replaced design or correction packet; historical instructions/then-next do not authorize execution. |
| `TODO_GEMINI_P15_CORRECTION_B.md` | SUPERSEDED_REFERENCE | 15515 | 185 | Completed/replaced design or correction packet; historical instructions/then-next do not authorize execution. |
| `TODO_GEMINI_P15_CORRECTION_C.md` | SUPERSEDED_REFERENCE | 13777 | 171 | Completed/replaced design or correction packet; historical instructions/then-next do not authorize execution. |
| `TODO_GEMINI_P15_RUNTIME_IMPL_01.md` | STABLE_PRODUCT_AUTHORITY | 7468 | 109 | Dormant future runtime planning contract; separate authorization/prerequisites required; not proof of implementation. |
| `TODO_GEMINI_P15_RUNTIME_IMPL_02.md` | STABLE_PRODUCT_AUTHORITY | 8656 | 101 | Dormant future runtime planning contract; separate authorization/prerequisites required; not proof of implementation. |
| `TODO_GEMINI_P15_RUNTIME_IMPL_03.md` | STABLE_PRODUCT_AUTHORITY | 6203 | 89 | Dormant future runtime planning contract; separate authorization/prerequisites required; not proof of implementation. |
| `TODO_GEMINI_P15_RUNTIME_IMPL_04.md` | STABLE_PRODUCT_AUTHORITY | 6985 | 101 | Dormant future runtime planning contract; separate authorization/prerequisites required; not proof of implementation. |
| `TODO_GEMINI_P15_RUNTIME_IMPL_05.md` | STABLE_PRODUCT_AUTHORITY | 6195 | 91 | Dormant future runtime planning contract; separate authorization/prerequisites required; not proof of implementation. |
| `TODO_GEMINI_P15_RUNTIME_IMPL_06.md` | STABLE_PRODUCT_AUTHORITY | 6278 | 102 | Dormant future runtime planning contract; separate authorization/prerequisites required; not proof of implementation. |
| `TODO_GEMINI_P15_RUNTIME_IMPL_07.md` | STABLE_PRODUCT_AUTHORITY | 5078 | 72 | Dormant future runtime planning contract; separate authorization/prerequisites required; not proof of implementation. |
| `TODO_GEMINI_P15_RUNTIME_IMPL_08.md` | STABLE_PRODUCT_AUTHORITY | 5550 | 91 | Dormant future runtime planning contract; separate authorization/prerequisites required; not proof of implementation. |
| `docs/AGENT.md` | ALWAYS_ON_CANDIDATE | 9492 | 181 | Mixed product safety, development, handoff, manual and review policy; not auto-discovered by this filename. |
| `docs/ARCHITECTURE.md` | STABLE_PRODUCT_AUTHORITY | 28154 | 501 | Scoped product contract; load only for relevant work. |
| `docs/BUNDLE_FILE_MANIFEST.md` | SUPERSEDED_REFERENCE | 2485 | 28 | 24 bundle hashes: 9 match, 15 differ against current bytes; not a live validator. |
| `docs/DECISIONS.md` | STABLE_PRODUCT_AUTHORITY | 42146 | 507 | Scoped product contract; load only for relevant work. |
| `docs/DEPENDENCY_AND_LICENSE_REVIEW.md` | STABLE_PRODUCT_AUTHORITY | 18933 | 140 | Scoped product contract; load only for relevant work. |
| `docs/FILESYSTEM_FEASIBILITY_PLAN.md` | STABLE_PRODUCT_AUTHORITY | 12204 | 97 | Canonical feasibility methodology; old overview phase-number language is not current milestone selection. |
| `docs/FILESYSTEM_PROVIDER_ARCHITECTURE.md` | STABLE_PRODUCT_AUTHORITY | 14402 | 139 | Scoped product contract; load only for relevant work. |
| `docs/FILESYSTEM_REPLAN_CLAUDE.md` | HISTORICAL_IMMUTABLE | 15073 | 97 | Dated review evidence; retained as history. |
| `docs/FILESYSTEM_SUPPORT_MATRIX.md` | STABLE_PRODUCT_AUTHORITY | 25104 | 223 | Canonical filesystem support/behavior and dated proof statuses. |
| `docs/FSD_PLAN_GATE_AUDIT_GPT56SOL.md` | HISTORICAL_IMMUTABLE | 23879 | 362 | Dated review evidence; retained as history. |
| `docs/FSD_PLAN_GATE_CORRECTION_GEMINI31.md` | HISTORICAL_IMMUTABLE | 5552 | 53 | Dated review evidence; retained as history. |
| `docs/KNOWN_ISSUES.md` | LIVE_STATE | 18915 | 262 | Live limitations; KI-025 repeats runtime/schema/manual state; KI-024 preserves pre-v8 history below closure amendment. |
| `docs/MVP_PLAN.md` | STABLE_PRODUCT_AUTHORITY | 26383 | 240 | Canonical product sequence; duplicates current closure/schema/runtime/manual facts; historical gates explicitly superseded. |
| `docs/PLACEMENT.md` | SUPERSEDED_REFERENCE | 568 | 24 | Old Desktop/DEV/FSD extraction path; README explicitly supersedes it. |
| `docs/PRD.md` | STABLE_PRODUCT_AUTHORITY | 11643 | 285 | Scoped product contract; load only for relevant work. |
| `docs/PRODUCT_STATE.md` | LIVE_STATE | 25472 | 199 | Current product facts plus large explicitly superseded milestone history; current-handoff pointer is a second live pointer. |
| `docs/PROJECT_MANIFEST.md` | STALE_CONTRADICTION | 2844 | 56 | Identity remains useful; line 38 says schema version 5, actual schema/migrations are v8. |
| `docs/PROJECT_SUPPORT/APP_STRUCTURE.md` | SUPERSEDED_REFERENCE | 831 | 41 | Planning-package placeholder says Xcode project not generated; actual project exists. |
| `docs/PROJECT_SUPPORT/CONFIG.md` | STABLE_PRODUCT_AUTHORITY | 319 | 5 | Scoped product contract; load only for relevant work. |
| `docs/PROJECT_SUPPORT/HANDOFFS.md` | STABLE_OPERATOR_POLICY | 1166 | 30 | Flat one-file handoff policy repeats AGENT/ADR-013; does not define CURRENT timestamp mirror. |
| `docs/PROJECT_SUPPORT/RELEASES.md` | STABLE_OPERATOR_POLICY | 360 | 15 | Scoped product contract; load only for relevant work. |
| `docs/PROJECT_SUPPORT/SCRIPTS.md` | STABLE_OPERATOR_POLICY | 390 | 11 | Reserved helpers description; contains no executable checker. |
| `docs/PROJECT_SUPPORT/TEST_STRUCTURE.md` | SUPERSEDED_REFERENCE | 450 | 26 | Suggested three targets differ from current FSDTests target; a template, not actual topology. |
| `docs/README.md` | DUPLICATED_AUTHORITY | 6660 | 116 | Navigation and product introduction plus duplicated current status; sequence correctly delegated to MVP_PLAN. |
| `docs/REFERENCE_VISUALDIFFER.md` | HISTORICAL_IMMUTABLE | 24068 | 704 | Dated review evidence; retained as history. |
| `docs/REVIEW_CLAUDE_CODE.md` | HISTORICAL_IMMUTABLE | 91529 | 1005 | Dated review evidence; retained as history. |
| `docs/SECURITY_AND_READ_ONLY_POLICY.md` | STABLE_PRODUCT_AUTHORITY | 5654 | 97 | Scoped product contract; load only for relevant work. |
| `docs/SNAPSHOT_COLLECTIONS.md` | STABLE_PRODUCT_AUTHORITY | 17682 | 146 | Scoped product contract; load only for relevant work. |
| `docs/SNAPSHOT_COLLECTIONS_REVIEW_CLAUDE.md` | HISTORICAL_IMMUTABLE | 15831 | 94 | Dated review evidence; retained as history. |
| `docs/TEST_PLAN.md` | STABLE_PRODUCT_AUTHORITY | 40503 | 571 | Canonical test requirements and §8 manual backlog; current gate summaries duplicate product live state. |
| `docs/UX_UI_SPEC.md` | STABLE_PRODUCT_AUTHORITY | 15565 | 273 | Scoped product contract; load only for relevant work. |
| `docs/skills/HANDOFF_SKILL.md` | PROCEDURAL_SKILL | 5035 | 219 | Legacy nested path/pointer/optional checksum defaults explicitly overridden by AGENT. |
| `docs/skills/MODEL_SUGGESTION_SKILL.md` | PROCEDURAL_SKILL | 6866 | 249 | Routing reference; missing a4c.model-routing-rule dependency; medium/high review recommendation differs from project risk policy. |
| `handoffs/CURRENT_HANDOFF.md` | LIVE_STATE | 10565 | 187 | Scoped product contract; load only for relevant work. |

Additional surfaces:

| Surface | Classification | Meaning |
|---|---|---|
| Existing 47 `handoffs/FSD_*.md` | HISTORICAL_IMMUTABLE | Flat dated evidence; selected CURRENT source and directly referenced accepted/design reports inspected; no blanket historical preload, no rewriting. |
| `docs/database/verify.sql` | DETERMINISTIC_CHECKER | Product/schema rejection fixtures; not a handoff/control-plane validator. |
| `docs/database/schema.sql` | STABLE_PRODUCT_AUTHORITY | Actual schema v8; `CatalogMigrations.currentVersion=8` corroborates. |
| `docs/PROJECT_SUPPORT/GITIGNORE.template` | SUPERSEDED_REFERENCE | Planning template; actual root .gitignore owns ignore behavior. |
| Root `.gitignore` | STABLE_OPERATOR_POLICY | `.agent/` and `.ai-scratch/` ignored; owner artifacts not cleanup authorization. |
| Desktop `04_FSD_BRAIN.md` before refresh | DUPLICATED_AUTHORITY | Transport includes stable operator and volatile seed/HOT; repository outranks it. Initial bytes saved locally. |
| Owner pilot handover | SUPERSEDED_REFERENCE for live state; migration guidance only | Old SHA/current/task statements are not current authority; Stage-A directive narrows pilot scope. |

No tracked repository reference to `04_FSD_BRAIN`, `BRAIN_RETURN` or `BRAIN_OPERATOR` existed at the verified baseline (`git grep` exit 1, 0 matches, excluding third-party spikes). The fallback mechanism was established in the owner's existing Desktop transport and current directive, not by a repository finalizer. That distinction is preserved.

## C. Duplication and drift map

Rows group repeated instances of the same fact. SAME does not make every surface its owner. Historical statements clearly scoped as old evidence are not treated as live authorization. All recommendations below are proposals only.

| FACT | AUTHORITY_A | AUTHORITY_B / other surfaces | SAME_OR_CONTRADICTORY | TARGET_OWNER | MIGRATION_RECOMMENDATION |
|---|---|---|---|---|---|
| CURRENT_PROJECT_STATE: M1–M5 technical closed; MVP unclaimed | PRODUCT_STATE current phase | MVP_PLAN status, README status, TEST_PLAN acceptance header, current historical report | SAME | PRODUCT_STATE for product facts; CURRENT HOT points to it | Replace repeated live summaries with source pointers/dates; preserve accepted evidence. |
| CURRENT_PROJECT_STATE: nullable boundary implemented/audit closed | PRODUCT_STATE:32–46 | MVP_PLAN Phase 1.5, README, TEST_PLAN; Desktop HOT/operator SEED says boundary audit PENDING | CONTRADICTORY Desktop seed | PRODUCT_STATE + accepted 20260807 audit | Correct transport Worker evidence from repo, retain operator seed bytes as nonauthoritative until authorized migration. |
| CURRENT_PROJECT_STATE: runtime not started/inactive | PRODUCT_STATE:48–53 | MVP_PLAN:7–21, KI-025, README, ADR-032 amendment, CURRENT prior report, Desktop runtime pending | SAME implementation status; Desktop wording less precise | PRODUCT_STATE; source/schema proof before future authorization | One live product status; TODO names are not completion evidence. |
| CURRENT_SCHEMA | schema.sql + CatalogMigrations.currentVersion=8 | PRODUCT_STATE/MVP_PLAN/README/ADR-031 v8; PROJECT_MANIFEST:38 says v5 | CONTRADICTORY manifest | Actual schema and migrations; PRODUCT_STATE live projection | Remove volatile schema version from manifest or derive/reference it; do not implement v9. |
| CURRENT_GATE: prerequisite schema change before runtime | ADR-032 + PRODUCT_STATE + runtime TODO 01 planning status | MVP_PLAN, KI-025, prior CURRENT readiness report; Desktop says reanchor then nullable audit | CONTRADICTORY Desktop; repo product gate SAME | PRODUCT_STATE/plan for product prerequisites; CURRENT HOT for active control gate | Keep paused product prerequisite separate from this Stage-A adjudication. |
| CURRENT_GATE: control pilot pause | Current owner Stage-A task | PRODUCT_STATE/MVP_PLAN still discuss product readiness; Desktop seed predates discovery | DIFFERENT_SCOPE; product docs do not grant pilot progression | CURRENT HOT + owner task authorization | Record pause/active scope in CURRENT; do not rewrite product status during discovery. |
| CURRENT_NEXT | Prior CURRENT proposal RETURN_TO_BRAIN_FOR_READINESS_ADJUDICATION | Desktop BRAIN ACTIVE_NEXT=repo freshness audit; pilot old TASK=full pilot; current owner authorizes Stage A only | STALE_DIFFERENT_TASK_SCOPES | BRAIN accepted ACTIVE_NEXT; Worker one proposal in CURRENT | Preserve dated/brain-owned old values; label pending adjudication; no automatic Stage B. |
| CURRENT_WORKSTREAM | Stage-A owner task | PRODUCT_STATE product P15 orientation; Desktop old freshness gate; TODO 01–08 future runtime sequence | DIFFERENT_SCOPE, not runtime progress | CURRENT HOT active; PRODUCT_STATE parked product | Record control workstream and parked P15 separately; require BRAIN authorization to resume. |
| CURRENT_HANDOFF pointer | handoffs/CURRENT_HANDOFF actual full mirror | PRODUCT_STATE:4 names old timestamped source; prior handoff names itself | SAME before publication; after Stage A product-state pointer necessarily old | CURRENT_HANDOFF only current continuity surface | Keep product-state chronology dated; rename semantic pointer under Stage B rather than update a competing live pointer every task. No PRODUCT_STATE edit now. |
| HANDOFF_POLICY: flat name/no sidecars | AGENT:54–119,149–161 | ADR-013, PROJECT_SUPPORT/HANDOFFS; generic HANDOFF_SKILL:46–94 nested AI_HANDOFFS/pointer/optional checksum | CONTRADICTORY defaults, explicitly resolved by AGENT override | Kernel critical pointer + FSD finalizer procedure | Refactor existing skill to project format; remove need to remember override pairs; preserve historical bytes. |
| HANDOFF_POLICY: CURRENT full mirror | AGENT:86–100,151–161 | Actual CURRENT exact source copy; generic skill pointer; some TODO closeouts repeat full-copy rule | SAME project/actual; CONTRADICTORY generic | Finalizer + deterministic parity check | Retain UPDATED_AT, blank, full historical bytes. HOT belongs inside the one historical body, mirrored into CURRENT. |
| HANDOFF_POLICY: exactly one report/history | AGENT development/artifact rules | HANDOFF_SKILL, PROJECT_SUPPORT/HANDOFFS, TODO closeout sections | SAME, repeated | Finalizer procedure; kernel path/immutability invariant | One procedural source; compatibility Desktop projection is transport, CURRENT is mirror. |
| WORKER_RETURN_POLICY | AGENT:100 exactly 10 summary lines + sentinel | TODO design/correction closeouts repeat 10 lines; pilot requires preserve until accepted; current owner task requests compact 4 + <=5 extra + sentinel | CONTRADICTORY formats; explicit current owner override wins this task | Compact Operator + finalizer contract | Propose explicit permanent replacement and compatibility acceptance in Stage B; use current owner compact return now without modifying AGENT. |
| WORKER/BRAIN field ownership | Existing Desktop operator HANDOFF SEMANTICS/envelope | Generic handoff skill has worker status but no separate BRAIN field ownership | GAP, not proof of acceptance | Compact Operator + checker | Keep Worker results local; never fill accepted BRAIN return fields from Worker validation. |
| MODEL_ROUTING_POLICY: primary/fallback | Existing Desktop operator ROUTING | MODEL_SUGGESTION primary/alternative tables; TODOs name Gemini Writer | PARTLY_SAME; permanent lane biases and old packet executor names differ | Stable routing procedure, referenced by Compact | Verify availability at routing time; task packet executor remains evidence/history; no model comparisons. |
| MODEL_ROUTING_POLICY: review threshold | AGENT Review policy material safety boundaries, low/medium no automatic audit | MODEL_SUGGESTION medium/high select separate Reviewer; Desktop material-boundary independence | CONTRADICTORY generic breadth, project override applies | Kernel catastrophic gates + review skill; Compact role separation | Preserve mandatory source/snapshot/recovery/schema/destructive/comparison/pre-MVP audits; do not blanket-add low-risk reviewers. |
| MODEL_ROUTING_POLICY: no model benchmark | AGENT Project Skills owner directive | README, PRODUCT_STATE, MODEL_SUGGESTION ban, TODO 01/02; old historical benchmark refs | SAME current; older evidence superseded | Kernel ban + owner directive | Preserve ban; routing/discovery/functional product performance are not permission to score models. |
| PRODUCT_INVARIANTS: read-only/metadata/lazy/immutable | PRD, SECURITY, provider contract, schema/migrations | AGENT, PROJECT_MANIFEST, README, Desktop operator safety rules | SAME core; multiple summaries | Scoped product authorities; catastrophic subset in kernel | Reference detailed canonical contracts; keep omission-critical safety always discoverable. |
| PRODUCT_INVARIANTS: optional inferred classification | ADR-031/032 + ARCHITECTURE §9/9a | PRD §8.1, SECURITY §2.1, MVP_PLAN, KI-025, PRODUCT_STATE, Desktop safety | SAME normative boundaries | ADRs + scoped runtime/security contracts | Preserve explicit-only, Data-only future boundary and comparison/snapshot isolation; transport references facts without becoming product authority. |
| MANUAL_ACCEPTANCE_STATE | TEST_PLAN §8 backlog | AGENT deferred rule, PRODUCT_STATE, MVP_PLAN, KI-020/024/025, CURRENT, Desktop seed, TODOs | SAME deferred; no owner interaction performed | TEST_PLAN backlog; PRODUCT_STATE summary | One backlog; preserve evidence labels and unclaimed overall MVP approval. |
| Proof/support status | FILESYSTEM_SUPPORT_MATRIX current proof | PRODUCT_STATE completed/current notes; historical foundation says FAT/NTFS/UDF untested | HISTORICAL_DIFFERENCE explicitly scoped | Support matrix | Keep dated old measurements/history out of HOT; no support promotion without seven-step proof. |
| Repository identity/path | Physical root + PROJECT_MANIFEST + README | PLACEMENT and 20260724 reviews say Desktop/DEV/FSD | SUPERSEDED_REFERENCE; not current repo contradiction | Physical Git + manifest stable identity | Label old placement/template context; do not rewrite historical reviews. |
| Bundle digests | BUNDLE_FILE_MANIFEST 24 archived entries | Actual current file bytes (15 mismatches) | CONTRADICTORY if misused as current validation | Bundle-release artifact only | Treat as extraction-era manifest; do not trust it for Operator/current integrity. No replacement/checksum sidecar created. |

Residual wording such as historical MVP/PRODUCT_STATE then-next gates and KI-021's old conditional is dated/superseded evidence, not an authorization to rerun milestones. Missing `a4c.model-routing-rule` is a dependency/reference gap: no such file/id was found in the repository; whether an external A4C catalog supplies it is UNKNOWN.

## D. Context-tax baseline

Measurement uses actual UTF-8 file byte lengths and physical line counts; no token counts, tokenizer, model benchmark or subjective score. Metrics were frozen at `22640bef294eff146777dd45db545c995384afa2` before replacing CURRENT. The original CURRENT bytes are in ignored `current-before.md` and the public historical source has 10,526 bytes/185 lines; CURRENT adds its 39-byte/two-line timestamp prefix.

### Meaning of always/task-specific

There is **no repository rule requiring all docs, all TODOs, all ADR history or all historical handoffs on every task**. No FSD project policy/skill file was found in a default automatic discovery location. These facts must not be hidden by inventing an enormous mandatory startup pack.

For the four meaningful handoff-producing examples below, the operational ALWAYS_REQUIRED set is `docs/AGENT.md` (9,492/181), baseline `handoffs/CURRENT_HANDOFF.md` (10,565/187), and triggered `docs/skills/HANDOFF_SKILL.md` (5,035/219): **3 files / 25,092 bytes / 587 lines**. It is a conditional workflow set after explicit policy entry, not a trace proving automatic injection, and not a blanket requirement for trivial answers. Model routing skill is conditional, not added automatically to schema/runtime/review. It is part of this Stage-A inventory because the owner explicitly named it.

TASK_SPECIFIC figures below are reproducible **whole-file reading envelopes for chosen task reference sets**, not claims every line must be injected at startup. Where current packets cite §§, section bytes are measured separately in the candidate. Before and candidate represent different loading shapes; they do not establish achieved savings or required total execution context.

| TASK_CLASS | ALWAYS_REQUIRED files / bytes / lines | TASK_SPECIFIC files / bytes / lines (whole-file envelope) | Candidate CTX_S known files / bytes / lines |
|---|---|---|---|
| LOW_RISK_CONTROL_DOC | 3 / 25,092 / 587 | 47 / 707,917 / 10,659 | 8 / 38,939 / 1,148 |
| SCHEMA_HIGH_RISK | 3 / 25,092 / 587 | 18 / 396,913 / 7,129 | 19 / 350,011 / 6,442 |
| RUNTIME_HIGH_RISK | 3 / 25,092 / 587 | 10 / 130,483 / 2,415 | 11 / 88,947 / 1,824 |
| INDEPENDENT_REVIEW | 3 / 25,092 / 587 | 14 / 352,182 / 6,005 + UNKNOWN_PACKET | 14 / 224,024 / 4,355 + UNKNOWN_PACKET |

Representatives and exact measured sets:

- LOW_RISK_CONTROL_DOC = this non-product-mutating Stage-A audit. Its breadth is unusually large: all 44 other control inventory files plus the exact archived owner task (including its code-formatted names), pilot guidance and original Desktop, 47 additional files. The original 47-file control inventory totals 683,135/9,083; excluding the 3-file always set gives 658,043/8,496. External official pages, ignored raw scans and selected historical evidence are separately triggered discovery work, not alleged default project context.
- SCHEMA_HIGH_RISK = dormant `TODO_GEMINI_P15_RUNTIME_IMPL_01.md`. Whole-file task set: `TODO_GEMINI_P15_RUNTIME_IMPL_01.md`, `handoffs/FSD_P15_MAGIKA_RUNTIME_DESIGN_A_20260807-155630.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/database/schema.sql`, `docs/database/verify.sql`, `FSD/Catalog/CatalogMigrations.swift`, `FSD/Catalog/CatalogDatabase.swift`, `FSD/Catalog/EntryClassificationRepository.swift`, `FSDTests/SchemaMigrationTests.swift`, `FSDTests/SchemaSafetyCorrectionTests.swift`, `FSDTests/CatalogDatabaseTests.swift`, `FSDTests/ClassificationEnrichmentTests.swift`, `FSDTests/ComparisonGUISourceBoundaryTests.swift`, `FSDTests/M5ReliabilityTests.swift`, `FSDTests/MilestoneConditionTests.swift`, `FSDTests/FinalScaleSnapshotTests.swift`, `FSDTests/ManualSessionASubstituteTests.swift`. It includes all nine existing allowlisted schema-impact tests; measuring their bytes is not executing/editing them. Future implementation remains forbidden here.
- RUNTIME_HIGH_RISK = dormant Slice 02 source-authority/Data-only boundary. Whole-file task set: `TODO_GEMINI_P15_RUNTIME_IMPL_02.md`, `handoffs/FSD_P15_MAGIKA_RUNTIME_DESIGN_A_20260807-155630.md`, `docs/SECURITY_AND_READ_ONLY_POLICY.md`, `docs/TEST_PLAN.md`, `FSD/Provider/FilesystemDetector.swift`, `FSD/Catalog/SnapshotWriter.swift`, `FSD/Browser/SnapshotTreeDataSource.swift`, `FSD/Catalog/EntryClassificationRepository.swift`, `FSDTests/ClassificationEnrichmentTests.swift`, `FSDTests/SnapshotHistoryTests.swift`. Not-yet-created reader/provider/test files have UNKNOWN sizes and are not invented as zero-cost completed work. Helper/external research is a later separately authorized expansion.
- INDEPENDENT_REVIEW = representative nullable-boundary review from the existing 20260807 audit. Whole-file selected evidence/source set: `handoffs/FSD_P15_MAGIKA_NULLABLE_ENRICHMENT_C_20260806-004158.md`, `handoffs/FSD_P15_MAGIKA_NULLABLE_ENRICHMENT_AUDIT_R_20260807-142313.md`, `docs/ARCHITECTURE.md`, `docs/SECURITY_AND_READ_ONLY_POLICY.md`, `docs/TEST_PLAN.md`, `docs/DECISIONS.md`, `docs/database/schema.sql`, `docs/database/verify.sql`, `FSD/Catalog/CatalogMigrations.swift`, `FSD/Catalog/CatalogDatabase.swift`, `FSD/Catalog/EntryClassificationRepository.swift`, `FSD/Browser/SnapshotTreeDataSource.swift`, `FSD/UI/SnapshotBrowserView.swift`, `FSDTests/ClassificationEnrichmentTests.swift`. This uses the published audit as relevant review evidence, not as the missing original review task packet. **Exact review packet is unavailable: task packet bytes/lines remain UNKNOWN.** These are known subtotals, not a complete review-context measurement; source-wide search results and extra tests may add context.

### Projected minimum calculation

`CTX_S = measured HOT sample + exact task (when available) + direct authority/source refs`.
HOT sample is **933 bytes / 25 lines**, materialized as ignored raw measurement text, not a new kernel/operator. It includes observed facts and one Worker proposal; it is not a promoted schema. Exact task inputs are the owner's archived Stage-A message or the corresponding complete existing TODO packet. Independent review exact-task component remains UNKNOWN.

The target kernel/Compact are not created; their future bytes are UNKNOWN and excluded from these known subtotals. No invented tiny-kernel size is counted as fact. If a harness also injects kernel/Compact/global skill metadata, its measured bytes must be added in Stage B/C. HOT is a section of CURRENT, not a second current file. High-risk source/test context remains substantial because it cannot be assumed away.

Candidate direct refs (RAW means the ignored evidence root):

- LOW_RISK_CONTROL_DOC: `RAW/hot-measurement-sample.txt`, `RAW/owner-stage-a-task.txt`, `docs/AGENT.md`, `docs/PROJECT_MANIFEST.md`, `docs/PROJECT_SUPPORT/HANDOFFS.md`, `docs/skills/HANDOFF_SKILL.md`, `docs/skills/MODEL_SUGGESTION_SKILL.md`, `docs/PRODUCT_STATE.md:1–54`. Full inventory scans expand beyond this initial S packet as required by Stage A.
- SCHEMA_HIGH_RISK: `RAW/hot-measurement-sample.txt`, `TODO_GEMINI_P15_RUNTIME_IMPL_01.md`, `handoffs/FSD_P15_MAGIKA_RUNTIME_DESIGN_A_20260807-155630.md`, `docs/ARCHITECTURE.md:314–501`, `docs/DECISIONS.md:400–507`, `docs/database/schema.sql`, `docs/database/verify.sql`, `FSD/Catalog/CatalogMigrations.swift`, `FSD/Catalog/CatalogDatabase.swift`, `FSD/Catalog/EntryClassificationRepository.swift`, `FSDTests/SchemaMigrationTests.swift`, `FSDTests/SchemaSafetyCorrectionTests.swift`, `FSDTests/CatalogDatabaseTests.swift`, `FSDTests/ClassificationEnrichmentTests.swift`, `FSDTests/ComparisonGUISourceBoundaryTests.swift`, `FSDTests/M5ReliabilityTests.swift`, `FSDTests/MilestoneConditionTests.swift`, `FSDTests/FinalScaleSnapshotTests.swift`, `FSDTests/ManualSessionASubstituteTests.swift`.
- RUNTIME_HIGH_RISK: `RAW/hot-measurement-sample.txt`, `TODO_GEMINI_P15_RUNTIME_IMPL_02.md`, `handoffs/FSD_P15_MAGIKA_RUNTIME_DESIGN_A_20260807-155630.md`, `docs/SECURITY_AND_READ_ONLY_POLICY.md:24–35`, `docs/TEST_PLAN.md:532–571`, `FSD/Provider/FilesystemDetector.swift`, `FSD/Catalog/SnapshotWriter.swift`, `FSD/Browser/SnapshotTreeDataSource.swift`, `FSD/Catalog/EntryClassificationRepository.swift`, `FSDTests/ClassificationEnrichmentTests.swift`, `FSDTests/SnapshotHistoryTests.swift`.
- INDEPENDENT_REVIEW: `RAW/hot-measurement-sample.txt`, `handoffs/FSD_P15_MAGIKA_NULLABLE_ENRICHMENT_C_20260806-004158.md`, `docs/ARCHITECTURE.md:314–376`, `docs/DECISIONS.md:400–434`, `docs/SECURITY_AND_READ_ONLY_POLICY.md`, `docs/TEST_PLAN.md:498–531`, `docs/database/schema.sql`, `docs/database/verify.sql`, `FSD/Catalog/CatalogMigrations.swift`, `FSD/Catalog/CatalogDatabase.swift`, `FSD/Catalog/EntryClassificationRepository.swift`, `FSD/Browser/SnapshotTreeDataSource.swift`, `FSD/UI/SnapshotBrowserView.swift`, `FSDTests/ClassificationEnrichmentTests.swift`, **plus UNKNOWN exact review packet**.

Section endpoints include trailing separation through the line before the next sibling heading. `context-tax.json` retains each path/range/byte/line receipt. These projections are arithmetic lower bounds under selected references, not acceptance evidence for context reduction. No model/harness latency, accuracy or output scoring was attempted.

## E. Current handoff / fallback pipeline

| Surface / transition | Creator today | Scripted or manual | Verified representation / duplication |
|---|---|---|---|
| TIMESTAMPED_HANDOFF | Worker following AGENT/ADR-013/task closeout | Manual/agent file write; no committed generator | Exactly one flat `handoffs/FSD_<CASE>_<ROLE>_<YYYYMMDD-HHMMSS>.md`; complete technical record; immutable once published. |
| CURRENT_HANDOFF | Worker after historical record | Manual full copy | Verified preflight: UPDATED_AT local ISO timestamp, blank line, complete 10,526-byte historical source. CURRENT total 10,565 bytes, exact source parity YES; no pointer/hybrid. |
| GIT_PUBLICATION | Worker explicit Git commands | Manual commands recorded in prior current handoff | Commit/push/fetch precedents exist; no root GitHub CI/finalizer/hook proving publication automatically. Current preflight source is included in 22640be. |
| DESKTOP_04_FSD_BRAIN | Existing BRAIN initialization/Worker-refresh convention | Existing Markdown envelope; no repository script found; prior two tasks explicitly created no Desktop artifacts | PACKET=FSD_BRAIN_RETURN_V1_0; HOT + Worker envelope + embedded Operator + initial BRAIN note. Before refresh, Worker fields UNSET, Git fields UNKNOWN_PENDING_REPO_AUDIT, generated at 2026-10-03T13:24:00Z. No prior completed Worker report in that initial packet. |
| BRAIN_RETURN | Owner sends Desktop; BRAIN reanchors/adjudicates | Human transport and BRAIN workflow | Worker writes evidence/proposals. BRAIN owns accepted review/classification/state/active next. A send-file instruction is not sending a message or BRAIN acceptance. |

**Embedded stable Operator:** YES, bounded by the BRAIN OPERATOR BEGIN/END markers, VERSION=2026-10-03. It includes governance and product safety, but also a volatile `FSD CURRENT PRODUCT ORIENTATION — SEED ONLY` block. Its pending-boundary-audit seed is stale against the repository. Therefore the current embedded body is not cleanly separated stable-only policy. This task preserves every byte of that marked block; it does not refactor it.

**Version/digest validation:** envelope version and Operator date exist as labels; no implemented parser, canonical repo Operator file, digest binding or validation path found. BUNDLE_FILE_MANIFEST is an unrelated extraction-era file, not Operator validation. Ad hoc SHA-256 comparisons used during discovery/preservation do not establish a reusable checker.

**Current drift:** Desktop remained at initialization despite two subsequent repository control tasks. This is direct evidence the fallback refresh is manual and can lag. Its old BRAIN-owned ACTIVE_NEXT/accepted initialization note cannot be silently promoted to a new Worker-authored accepted state. This Stage-A refresh updates Worker/HOT evidence, leaves BRAIN-owned fields and embedded Operator unchanged, and includes the complete new CURRENT body for full recovery.

Compatibility Stage B/C must preserve:

1. Exactly one new flat timestamped historical record per task; no renamed/rewritten history, nested SESSION/AI_HANDOFFS paths, CURRENT.md or checksum sidecars.
2. CURRENT first line `UPDATED_AT: <machine-local ISO 8601 with timezone>`, second blank, then complete historical record bytes. HOT can be inside the historical body and mirrors naturally; changing CURRENT to a pointer requires an explicitly accepted later policy migration.
3. `/Users/cenvu/Desktop/04_FSD_BRAIN.md` remains a single full recovery transport with the Operator/governance, current evidence/report and Worker return needed when repo access is unavailable; it is not repository authority. Stable body may later become a verified projection only after a canonical surface exists.
4. Preserve Worker/BRAIN field ownership; fill Worker facts without inventing BRAIN classification/authorization. Preserve prior BRAIN-owned bytes as prior state pending reanchor. Keep UNKNOWN for unverified facts.
5. Publication SHA is proven after commit/push/fetch, not fabricated inside a self-containing immutable handoff. Do not force remote/local consistency by destructive Git operations.
6. Manual acceptance remains deferred; product technical evidence does not claim owner acceptance, overall MVP approval or permission to start runtime.
7. Current owner's compact Worker return overrides the old 10-line rule for this task only. Permanent replacement remains a Stage-B proposal; sentinel `NEW HANDOFF!!!` is retained.
8. Stop after evidence publication/projection and return. BRAIN, not Worker, chooses the next authorized action.

## F. Checkers and automation inventory

Scope searched: tracked root/local scripts, docs support/scripts/skills, SQL verification, product verification/test references, root CI paths, ignored task directories excluding build/dependency trees, and recorded commands in the current/two recent handoffs. No reusable control-plane checker/finalizer source was found. No checker code was added or executed as if it already existed.

| Capability / surface | Assessment | Evidence / reuse boundary |
|---|---|---|
| Handoff naming/schema | MISSING | Prose templates in AGENT/skill/support, no executable naming/schema check. |
| Exactly one new historical handoff per session | MISSING | Prose and manual diff review; Git file inventory is reusable primitive. |
| CURRENT/source equivalence + UPDATED_AT | MISSING (REUSE byte comparison primitive) | This task directly compared bytes after two-line header; prior mirror conforms. No committed validator. |
| Required refs / existence | MISSING (REUSE Git/path primitives) | Markdown navigation is not a ref validator; manifest has stale schema and historical path names. |
| Git freshness / identity / ahead-behind | REUSE primitives; MISSING integrated gate | Git rev-parse/config/fetch/status/rev-list/worktree and timestamped command receipts; no canonical script. |
| Allowed path scope / owner dirty preservation | REUSE Git diff/status; MISSING reusable contract checker | Prior tasks record scope and preservation comparisons; inline checks, not packaged finalizer. |
| Worker/BRAIN field ownership | MISSING | Existing Desktop envelope comments/Operator specify roles; no parser prevents Worker self-acceptance. |
| Exactly-one-next / dead-end count | MISSING | Generic handoff rule/Operator prose; no parser; count unique decisions, not repeated transport copies. |
| Placeholder detection / honest UNKNOWN | MISSING | No control checker; product normalization tests/SQL reject product placeholders only, not handoff SHAs/status. Intentional UNKNOWN/UNSET in BRAIN fields is not blanket failure. |
| Desktop/Operator/version/full recovery parity | MISSING | Packet/date labels without repository canonical operator, digest validator or finalizer. |
| Finalization/atomic projection/publication receipts | MISSING; HANDOFF_SKILL REFACTOR_CANDIDATE | Generic legacy skill can supply verified-state/one-next/checklist discipline, but no executable finalizer exists. |
| `docs/database/verify.sql` | REUSE for product/schema tasks only | Deterministic SQL expected-rejection fixtures; not run/reworked in Stage A. |
| CatalogMigrations ExpectedState / schema tests | REUSE for high-risk product validation only | Existing schema object/definition/column checks; no claim they validate control fields. No tests run here. |
| `add_files.py`, `add_files_raw.py`, `modify_comparison_project.py` | OBSOLETE for control-plane migration | One-off Xcode project mutation helpers; not handoff automation; not executed. |
| Native/libfsext spike fixture/run scripts | REUSE within their product feasibility scope | Isolated disk-image generation/probes, not control-plane checks; not executed. |
| Vendored autotools/tests/check_source.yml | OBSOLETE for control-plane purposes | Third-party reader build/test infrastructure; not FSD governance CI. Root `.github` has no tracked workflows. |
| `docs/PROJECT_SUPPORT/SCRIPTS.md` | MISSING executable implementation | Reserved descriptions of helper categories only. |
| BUNDLE_FILE_MANIFEST.md | OBSOLETE as current integrity check | 24 hashes, 9 matches/15 mismatches; no current pipeline executes it. Preserve historical bundle context. |

Minimal future mechanical coverage can share one checker executable with subcommands; no separate script per rule is justified. Architecture correctness, model suitability, sufficient independent review and BRAIN acceptance remain semantic decisions.

## G. Minimum Stage-B proposal — not implemented or authorized by this report

CANONICAL_KERNEL=AGENTS.md (CREATE; only catastrophic invariants, authority/ownership, preserve dirty/unknown, no benchmark/no auto-next, current/trigger pointers)
COMPACT_OPERATOR=docs/BRAIN_OPERATOR.md (CREATE; stable BRAIN/Worker operating contract only)
FULL_REFERENCE=docs/AGENT.md (REUSE/REFACTOR as existing deep policy/reference and rationale; direct product authorities remain scoped)
CURRENT_HANDOFF=handoffs/CURRENT_HANDOFF.md (REUSE; maintain full-copy compatibility and HOT inside source)
TASK_EXECUTION_SKILL=.agents/skills/fsd-task-execution/SKILL.md (CREATE packaging/procedure by extracting existing workflow prose)
HANDOFF_FINALIZER_SKILL=.agents/skills/fsd-handoff-finalizer/SKILL.md (REFACTOR existing docs/skills/HANDOFF_SKILL.md into one canonical FSD procedure; old path becomes a reference if retained)
INDEPENDENT_REVIEW_SKILL=.agents/skills/fsd-independent-review/SKILL.md (CREATE procedure from existing AGENT risk boundaries and accepted review evidence)
MODEL_ROUTING_SKILL=docs/skills/MODEL_SUGGESTION_SKILL.md (REUSE/REFACTOR triggered routing reference; no universal default load)
CHECKER_SET=one proposed scripts/check_control_plane.py with handoff/ref/ownership/next/freshness/scope/projection checks; publication steps remain explicit finalizer actions
DESKTOP_FALLBACK=~/Desktop/04_FSD_BRAIN.md (REUSE full recovery transport)

CREATE justifications (all future, none created now):

- **Root AGENTS.md:** existing singular `docs/AGENT.md` is not in default discovery locations; user-global defaults are profile-specific and cannot establish checked-in FSD policy. A small discoverable root kernel is the smallest shared path documented for the installed harnesses. Long policy copying into each harness would recreate duplication. Do not move the entire 9,492-byte AGENT body into always-on context.
- **docs/BRAIN_OPERATOR.md:** there is no repository BRAIN operating-policy surface. The only current BRAIN contract is embedded in Desktop and contains volatile seed state. Reusing PRODUCT_STATE/CURRENT would mix stable governance with live state; AGENT is chiefly Worker/product policy. Extract the stable embedded contract once, excluding all SHAs/current slices/blockers/counts/seeds. Keep governance prose compact; reference AGENT for deeper rules. **No new FULL file is justified:** existing AGENT can serve the full reference.
- **Task execution skill bundle:** AGENT has workflow fragments, but neither current skill provides task reanchor/allowed-scope/already-done/research/validation/stop procedure. Extract/reuse that prose in one trigger-specific procedure; the SKILL.md path and frontmatter are required for standard skill metadata discovery. Avoid a giant all-FSD Operator skill.
- **Handoff finalizer bundle:** reuse existing Handoff Skill discipline; its loose filename and legacy generic defaults cannot serve direct FSD discovery/finalization as-is. One canonical bundle removes nested-path/pointer overrides; do not retain two divergent handoff procedures.
- **Independent review bundle:** AGENT lists required risk boundaries but lacks a triggered independent evidence/reproduction/ownership/return procedure. MODEL_SUGGESTION chooses a lane, not an audit protocol. Reuse accepted review structure and existing gates in a narrowly triggered skill; do not add routine low-risk independent review automatically.
- **Single checker executable:** no existing source proves naming/parity/refs/ownership/next/freshness/scope together. SQL/Xcode helpers act on different invariants and should not be repurposed. One code surface is enough; avoid creating similarly named scripts to match other projects.
- **Harness adapter views only if needed after bounded activation evidence:** `.agents/skills` is shared by Codex/OpenCode/current Antigravity (and Gemini if installed). Claude documents `.claude/skills`, so a `.claude/skills/<name>/SKILL.md` symlink/view to each canonical bundle is a candidate CREATE for discovery only; no duplicated policy body. Verify symlink/trust behavior first. If Claude native AGENTS works in the installed session, no root CLAUDE adapter is needed. If it does not, a minimal `CLAUDE.md` import of `AGENTS.md` is justified because the existing kernel cannot be reached in that session. No GEMINI adapter is needed for the absent CLI; revisit only if it becomes an actual lane. Preserve older Antigravity compatibility only when a fixture demonstrates need.

Minimum checker responsibilities proposed for Stage B: flat name + one new history; local ISO UPDATED_AT/full-source parity; required refs; Git root/upstream/timestamp/ahead-behind with dirty preservation; explicit allowed/forbidden diff; Worker/BRAIN field ownership; exactly one distinct proposal; placeholders with explicit allowed UNKNOWN/UNSET semantics; Desktop complete report/Operator projection/version validation after a canonical Operator exists. Reuse Git/byte-comparison primitives. Prefer checker results recorded with timestamps and paths over self-attested PASS. Do not let a checker grant BRAIN acceptance.

Migration must explicitly decide the permanent compact terminal-return rule, remove volatile live facts from stable Operator/reference surfaces, normalize skill frontmatter, define canonical rule ownership, and measure actual newly created startup bytes. Full-copy CURRENT remains compatible until an accepted change says otherwise. Promotion/activation/context reduction require a separately authorized Stage-B/C cycle; this discovery report does not claim pilot acceptance.

## Validation, publication and preserved boundaries

Performed here: root/upstream/version/help/config discovery, two successful fetches before publication, CURRENT source parity, file/section measurements, actual schema-version source read, tracked/hash and ignored-metadata preservation. `git diff --check` and scope/parity checks are required on the final two-file publication before commit; final push/fetch/status are captured after immutable creation in the Desktop Worker envelope. No product XCTest/build/SQL fixture/manual test was run; product behavior preservation is proved by unchanged bytes and the restricted publication diff, not a newly claimed runtime test result.

Authorized tracked publication is exactly this new historical file and `handoffs/CURRENT_HANDOFF.md`. Every pre-existing timestamped historical handoff remains byte-identical. All product executable/source/schema/test/project/resource paths and all pre-existing docs/skills/TODOs remain byte-identical to baseline. No root AGENTS, kernel, Compact/FULL file, procedural-skill refactor, checker, schema v9/provider_identifier or Magika runtime is created. The Desktop refresh uses the existing packet/Worker envelope/full-fallback semantics and preserves the original embedded Operator and BRAIN-owned bytes.

Files changed: `handoffs/FSD_BRAIN_OPERATOR_DISCOVERY_AND_BASELINE_D_20261004-003712.md` (create once), `handoffs/CURRENT_HANDOFF.md` (overwrite as prescribed), `/Users/cenvu/Desktop/04_FSD_BRAIN.md` (authorized full fallback refresh), ignored raw evidence under the task-specific .agent directory. No extra tracked report, checksum file, historical rewrite or product mutation.

## Unknowns and advisories

- Harness rules are documented; fresh-session activation was not model-probed. Exact Antigravity build rollout, Claude bundled agents-md enable/trust/managed settings, and OpenCode nested dynamic/collision behavior remain UNKNOWN. Do not call documented defaults empirical activation success.
- Gemini CLI absent on PATH; no binary elsewhere was assumed, installed or searched through credential-bearing locations.
- Generic model-routing dependency missing in repository; external A4C availability UNKNOWN.
- Independent review original exact packet unavailable; no invented bytes/lines. New kernel/Compact sizes unknown; candidate footprint is known subtotal only.
- Root policy discovery gap, generic handoff default drift, schema-v5 manifest error, transport stale seeds/old BRAIN next, duplicate live pointers and missing reusable finalizer/checkers remain findings. Stage A deliberately leaves repository authority documents unchanged.
- Existing accepted audits and deferred manual state are dated evidence; no new BRAIN acceptance, owner manual interaction or product readiness authorization is self-authored.
- Ignored raw evidence is local only; complete material findings and measurement definitions are in this immutable tracked handoff. Future reviewer can recompute file metrics from the recorded base and cited ranges.
- After CURRENT advances, PRODUCT_STATE's old "Current Handoff" line remains dated product provenance due the explicit mutation boundary. This is a known residual competing-pointer drift, not an omitted unauthorized repair.

## Exactly one proposed next

PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_FSD_BRAIN_OPERATOR_DISCOVERY_ADJUDICATION

STOP_AFTER_PUBLICATION_AND_CURRENT_DESKTOP_PROJECTION=YES
WORKER_NEXT_IS_PROPOSAL_ONLY=YES
