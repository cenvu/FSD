# filetype v1.1.3 integration contract (task032) — PASS_WITH_ADVISORY

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_CLASSIFIER_FILETYPE_INTEGRATION_CONTRACT_A_20261006-205300.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=56515c6e925127907834322856d9d60a6b0c0bbb
REMOTE_HEAD=56515c6e925127907834322856d9d60a6b0c0bbb
LAST_VERIFIED_AT=2026-10-06T20:52:18+07:00
AUTHORITY_PTRS=AGENTS.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|docs/BRAIN_OPERATOR.md|STATE/PROJECT_STATE.md|handoffs/FSD_CLASSIFIER_NATIVE_FEASIBILITY_CLOSURE_D_20261006-202845.md|docs/CLASSIFIER_FILETYPE_INTEGRATION_CONTRACT.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_CLASSIFIER_FILETYPE_INTEGRATION_CONTRACT_032
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_HARD;SHORT_CFB_NEUTRALIZED_BY_GUARD;LEGACY_OFFICE_DETERMINISM_UNPROVEN_ADVISORY
PROPOSED_NEXT=FSD_CLASSIFIER_FILETYPE_BUNDLED_HELPER_INTEGRATION_033
NO_AUTO_NEXT=YES

## Task lock and result

TASK=FSD_CLASSIFIER_FILETYPE_INTEGRATION_CONTRACT_032
TASK_ID=FSD_CLASSIFIER_FILETYPE_INTEGRATION_CONTRACT_032
ROLE=ARCHITECT
MODE=BOUNDED_REAL_HELPER_INTEGRATION_CONTRACT
BASE_HEAD=56515c6e925127907834322856d9d60a6b0c0bbb
UPSTREAM_HEAD=56515c6e925127907834322856d9d60a6b0c0bbb
EXPECTED_CANONICAL_HEAD=56515c6e925127907834322856d9d60a6b0c0bbb
FEASIBILITY_PUBLICATION=878d3396666a8dae00dda079046aafceb0d96e50
TECHNICAL_SHA=56515c6e925127907834322856d9d60a6b0c0bbb
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=ADR035;DETERMINISTIC_SHORT_CFB_GUARD_CONTRACT;PACKAGING_ARTIFACT_NOTICE_TEST_AUDIT_CONTRACT
ALLOWED_PATHS=docs/DECISIONS.md|docs/ARCHITECTURE.md|docs/P15_RUNTIME_PLAN.md|docs/TEST_PLAN.md|docs/CLASSIFIER_FILETYPE_INTEGRATION_CONTRACT.md|handoffs/FSD_CLASSIFIER_FILETYPE_INTEGRATION_CONTRACT_A_20261006-205300.md|handoffs/CURRENT_HANDOFF.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl
FORBIDDEN_PATHS=SWIFT;TESTS;XCODE;SCHEMA;DEPENDENCY_ARTIFACTS;HELPER_BINARY;STATE/PROJECT_STATE.md;STATE/RULE_PROMOTION_LEDGER.tsv;PRD;MVP_PLAN;UX_UI_SPEC;SECURITY_AND_READ_ONLY_POLICY;DEPENDENCY_AND_LICENSE_REVIEW;PRODUCT_STATE;HISTORICAL_HANDOFFS
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
RESULT=PASS_WITH_ADVISORY
RESULT_AUTHORITY=WORKER_EVIDENCE_ONLY_PENDING_BRAIN
INTEGRATION_TARGET_SELECTED=YES
INTEGRATION_TARGET=filetype_v1.1.3
PRODUCTION_PROVIDER_SELECTED=NO
PRODUCTION_PROVIDER_ACCEPTED=NO
INTEGRATION_AUTHORIZED=NO

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=30
WORKER_REQUIREMENTS_EVIDENCED=30
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

## Git/freshness snapshot

FACT: At start local main was 878d339 and behind origin by 3 with a clean worktree.
After `git fetch`, origin/main was 56515c6e925127907834322856d9d60a6b0c0bbb, the
task's expected canonical head. Reconciled with `git merge --ff-only origin/main`
(non-destructive; no reset/clean/stash/rebase). Base captured before any mutation.
ACCEPTED_STATE read: CURRENT_GATE=task032, LAST_ACCEPTED_TASK=029S.

## Concrete delta (docs only)

- NEW `docs/CLASSIFIER_FILETYPE_INTEGRATION_CONTRACT.md` (24 sections): pins, safety,
  ADR-034 semantics, guard decision order, zero-byte rule, output mapping,
  determinism wording, naming, Go archive pin, containment env, build flags,
  no-Go-in-Xcode, tracked paths, manifest fields, notices, Xcode packaging, integrity,
  code allowlist, helper contract, real-helper and bundle test plans, validation,
  independent audit, task033 stop conditions, not-claimed list.
- `docs/DECISIONS.md`: appended ADR-035 (Accepted, target only, not production).
- `docs/ARCHITECTURE.md` 9a: INTEGRATION_TARGET, PRODUCTION_PROVIDER_ACCEPTED=NO,
  Swift host -> fixed helper -> FSD ambiguity guard -> filetype.Match layering.
- `docs/P15_RUNTIME_PLAN.md` Slice 07: truthful status and 4-step implementation
  contract; Magika task025 evidence untouched.
- `docs/TEST_PLAN.md` section 9: forward-looking real-helper/bundle/audit tests with
  explicit short-CFB regression-retention rule.

DELTAS: SWIFT=NONE TEST_CODE=NONE XCODE=NONE SCHEMA=NONE DEPENDENCY_ARTIFACT=NONE
HELPER_BINARY=NONE GO_EXECUTION=NONE DOWNLOAD=NONE BUNDLE_SIGNING=NONE.

## Pre-mutation authority inspection (FACT)

- ADR-033/034: no active text conflicts with a `no_match` guard result. ADR-034
  defines noMatch as successful execution with no recognized type, no row, no schema
  change; the guard fits. ADR-033 decision 8 (rename only after provider selected) is
  addressed in ADR-035 decision 7 / contract section 8.
- `Tools/` and `FSD/Helpers/` do not exist; the proposed paths are not git-ignored;
  `project.pbxproj` uses explicit file references and has no copy-files phase;
  all configs set `CODE_SIGNING_ALLOWED=NO`; helper path constant already
  `Contents/Helpers/FSDClassificationHostSeam`; stdout/stderr caps 4096; envelope is
  the strict flat seven-field object. No repository convention makes a proposed path
  unsafe.
- No STOP condition triggered; no authority outside the allowlist needs change.

## Verified commands

- `git fetch origin`; `git merge --ff-only origin/main` -> HEAD 56515c6, clean.
- Post-mutation grep checks (each exactly 1 match): ADR-035 heading and Accepted;
  INTEGRATION_TARGET=filetype_v1.1.3; PRODUCTION_PROVIDER_ACCEPTED=NO; guard line
  `len<=513 && prefix D0CF11E0 -> noMatch before Match`; UPSTREAM_PATCH=NONE;
  NORMAL_XCODE_REQUIRES_GO=NO; NORMAL_XCODE_REQUIRES_NETWORK=NO; module Sum and
  GoModSum exact; GO_TOOLCHAIN_PIN=go1.27.1_darwin_arm64; archive SHA256
  ee215d57e0ec269c60cc9ceca68e6bda321ba9ee5afe24f4b0988703c2d87d12;
  SLICE08_STARTED=NO; notice set (MIT, LICENSE, PATENTS, Sun) defined.
- `git diff --check` -> exit 0.
- Checker results recorded in the finalizer closure (see Desktop/return); no Swift,
  Xcode or Go command was run (docs-only task).

## Validation limits and advisories

- UNPROVEN-BY-DESIGN (not a requirement of this task): that a CFB-prefixed input of
  length 514 or more is single-valued; the contract makes it a task033 stop probe.
- The contract relies on accepted task029S evidence and the Owner-supplied guard
  threshold (513, offsets 512-513); the task did not re-read upstream source or
  re-run Go (forbidden). Task033 tests (synthetic DOC/XLS/PPT discriminants) must
  verify routing on the exact pin.
- Feasibility module bytes were a reused scratch cache and the feasibility toolchain a
  copied Homebrew libexec; the production official-archive build may legitimately
  produce a different SHA256. Contract section 1/9 handle this; the feasibility SHA is
  not the production SHA.
- Task033 needs module acquisition (filetype v1.1.3 via proxy into scratch) that
  task032 text did not explicitly authorize; contract section 9 requires task033's own
  authorization to cover it or STOP.
- Observed stale text (not changed, outside scope): `docs/P15_RUNTIME_PLAN.md` top
  amendment still says ADR-034 IMPLEMENTATION=PENDING though task031 was accepted;
  `docs/TEST_PLAN.md` section 9 intro says the same. Suggest BRAIN decide a
  correction task. Legacy DOC/XLS/PPT determinism remains an unproven advisory.

## Requirement/evidence map (30, all EVIDENCED)

1 base/head fresh (fetch+ff) | 2 required reads | 3 target pins locked | 4 FSD safety
contract | 5 ADR-034 semantics unchanged | 6 CFB guard policy exact | 7 zero-byte rule |
8 truthful determinism wording | 9 output mapping | 10 provider rename contract | 11 Go
archive pin | 12 scratch containment env | 13 build flags/binary checks | 14 Xcode needs
no Go/network | 15 tracked path allowlist | 16 manifest fields | 17 notice set + rerun
rule | 18 Xcode packaging/signing contract | 19 artifact integrity | 20 code
allowlist | 21 helper contract | 22 real-helper tests | 23 bundle tests | 24
validation list | 25 independent audit mandatory | 26 ADR-035 | 27 only allowed docs
changed | 28 P15 Slice07 | 29 ARCHITECTURE | 30 TEST_PLAN. All by physical doc text
verified with grep/diff above..

## Ownership, state proposal and next

OWNERSHIP: Worker evidence only; BRAIN owns review/classification/acceptance.
PROPOSED_STATE_DELTA: on BRAIN acceptance, mark task032 accepted, record ADR-035,
set the next decision to task033 authorization (implementation only, no self-audit).
Proposed next (single, as in HOT): FSD_CLASSIFIER_FILETYPE_BUNDLED_HELPER_INTEGRATION_033.
The next task was not started (see guard).
