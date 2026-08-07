# Phase 1.5 Runtime — Gemini vs DeepSeek V4 Flash A/B Coding Benchmark

Prepared by: Tech Lead / Architect (planning only)  
Selected implementation contract: `TODO_GEMINI_P15_RUNTIME_IMPL_01.md`  
Contract size: **4 major TODOs**  
Benchmark boundary: schema-v9/provider-provenance slice only

## Why Slice 01 is selected

Slice 01 is deterministic, bounded, compilable/testable, meaningful production work, independent of external Magika binaries, and free of subjective UI judgment. All load-bearing schema semantics are locked in its TODO file: version 9; one nullable/no-default `provider_identifier` column; no fabricated legacy value; exact migration chain; current-schema verification; model/repository round-trip; and append-only/provenance tests. The Writers implement these decisions; they do not choose them.

The slice's schema risk is controlled by isolated worktrees, identical contracts, mandatory automated gates, no merge before review, and an independent persistent-data audit at the comparison boundary.

## Benchmark setup

### Base-state requirement

The current planning directory does not contain `.git`, so it cannot itself prove a base commit. CONTROL must run this benchmark from the canonical Git repository and record:

- full base commit SHA;
- branch/worktree creation commands;
- clean `git status --short` for the base;
- SHA-256 of `TODO_GEMINI_P15_RUNTIME_IMPL_01.md` and this benchmark file;
- Xcode/Swift/macOS/architecture versions.

If no exact base commit can be recorded, the benchmark must not start.

### Isolated branches/worktrees

Create both worktrees from the same recorded base commit/state:

- **Worktree G — Gemini**; branch name such as `bench/p15-schema-gemini`
- **Worktree D — DeepSeek V4 Flash**; branch name such as `bench/p15-schema-deepseek`

Use separate catalog/temp/DerivedData locations. Recommended DerivedData paths:

- G: `/tmp/FSD-P15-Bench-G-DerivedData`
- D: `/tmp/FSD-P15-Bench-D-DerivedData`

Neither Writer may inspect, import, cherry-pick, repair, continue, or discuss the other's output. Do not run one Writer after the other in the same worktree. Do not let one model's build artifacts, temporary databases, logs, or Handoff overwrite the other's.

### Identical input contract

Both Writers receive only:

- the exact same `TODO_GEMINI_P15_RUNTIME_IMPL_01.md` bytes;
- the exact same starting repository state/base SHA;
- the same project instructions (`AGENTS.md`/`docs/AGENT.md` as present at that base);
- the exact same required build/test commands and stop condition from Slice 01;
- the same maximum **4 major TODO** horizon;
- the same instruction to make no architecture decisions and no external access.

No model-specific hints, corrections, hidden patches, extra context, different timeout, or different test subset. If one environment has an infrastructure failure, fix the environment for both and restart both from the base; do not continue only one branch.

### Execution and evidence capture

For each worktree, record without editorial repair:

- start/end wall time;
- commands attempted and exit statuses;
- compiler/test iteration count when observable;
- exact changed-file list and diff;
- build/test logs and XCTest passed/failed/skipped counts;
- Writer final response and required slice Handoff;
- any unsupported claim, omitted TODO, or stop-condition violation.

The independent auditor evaluates both anonymous patches where practical. Speed is descriptive only and never breaks a correctness tie.

## Required gates for each Writer

Run the exact Slice 01 commands using that Writer's isolated DerivedData path, then the full Debug test suite. Additionally inspect:

```bash
git status --short
git diff --check
git diff --name-only <BASE_SHA>...HEAD
```

If Writers do not commit, compare their worktrees directly against the recorded base SHA. Do not normalize or repair their diffs before scoring.

## Scoring rubric

Score each dimension from 0–10. Use whole or half points and cite concrete evidence for every deduction.

| Dimension | 10-point standard |
|---|---|
| Instruction Fidelity | Followed the exact four-TODO contract, locked semantics, order, allowlist, prohibitions, stop condition, and planning/audit boundary. |
| TODO Completion Accuracy | Every required responsibility and completion check is materially complete; no checkbox-only or partial implementation. |
| Technical Correctness | Migration, schema verification, repository behavior, compatibility, error handling, and tests are correct under normal and failure paths. |
| Cross-File Consistency | Fresh schema, migration, ExpectedState, models, SQL, fixtures, hard-coded current-version checks, and docs/database verification agree. |
| Verification Honesty | Commands/results/counts are exact; failures/skips/limitations are disclosed; no unrun test or inferred behavior is claimed as passing. |
| Scope Discipline | Only authorized files/behavior changed; no refactor, dependency, runtime/UI/provider redesign, artifact, or unrelated cleanup. |
| Final Report Fidelity | Handoff/final response accurately names changes, tests, results, risks, manual state, and stop/next-action status. |

Calculate:

```text
TOTAL = sum of seven dimension scores          # /70
WRITER SCORE = TOTAL / 7                       # /10, round to one decimal
```

## Coding metrics to record

Record for each model:

- clean build: PASS/FAIL;
- required focused tests: passed/failed/skipped;
- full suite: passed/failed/skipped;
- regressions introduced;
- unauthorized files touched;
- implementation TODOs missed;
- correction rounds required;
- compiler/test iterations if observable;
- unsupported claims;
- runtime/test duration where meaningful;
- files and lines changed as descriptive data only, never as a quality score.

## Outcome categories

Hard gates override numeric score.

### RELIABLE

- `TOTAL >= 63/70` (`WRITER SCORE >= 9.0`);
- clean build and every required test pass;
- zero unauthorized files, missed TODOs, unsupported completion claims, and correction rounds;
- no data-safety, migration, compatibility, or provenance defect.

### USABLE WITH CORRECTION

- `TOTAL 49–62.5/70`, or a RELIABLE reporting/scope gate is missed;
- implementation is substantially correct and safely repairable in one bounded correction round;
- no evidence of data loss or an unsafe migration being accepted as correct.

### FAILED

- `TOTAL < 49/70`; or
- build/required tests fail because of the patch; or
- migration can lose/corrupt/misrepresent data; or
- a locked schema semantic is changed; or
- material unauthorized scope, missed TODOs, fabricated verification, or more than one correction round is required.

An environmental failure outside the patch is **NO RESULT**, not FAILED, only when reproduced identically from the untouched base and documented. Restart both sides after the environment is corrected.

## Comparison and selection procedure

1. Freeze both outputs when each Writer stops; no repairs.
2. Run the same independent audit against both patches and logs.
3. Score every dimension and metric separately before revealing model identity where practical.
4. Apply hard gates and assign each outcome category.
5. Prefer correctness, data safety, migration compatibility, verification honesty, and scope discipline over speed or smaller diff size.
6. Select at most one implementation for correction/merge. Never combine the two patches ad hoc. If both fail, reject both and issue a new Architect-authored bounded correction slice from the base.
7. Record the benchmark verdict in the schema audit Handoff before Slice 02 begins.

## Fairness safeguards

- The benchmark compares implementation behavior, not architecture skill; all load-bearing choices are already locked.
- Same TODO bytes, base SHA, tools, commands, stop condition, and evidence requirements.
- No cross-inspection or continuation from the competitor.
- No post-hoc extra tests for only one model. If the auditor adds a valid test, run it unchanged against both frozen patches.
- Timestamp/Handoff filename differences and wall time do not affect quality scoring.
- Lines/files changed never produce points or deductions unless they evidence scope or correctness problems.

## DeepSeek horizon policy

DeepSeek V4 Flash's first FSD attempt is exactly this **4-TODO** slice. No larger task is authorized from context-window size alone.

Experimental ladder, only after a RELIABLE result at the prior level:

1. repeat an independent 4-TODO slice in a different domain;
2. benchmark one 5-TODO slice;
3. only after reliable 5-TODO evidence, benchmark one 6-TODO slice;
4. do not assign 8–10 TODOs without multiple reliable results at intermediate horizons.

This ladder is experimental and does not change current Writer routing until evidence is recorded.

## Benchmark stop condition

Stop both runs and declare NO RESULT if their base SHA, TODO bytes, environment, commands, or available repository state differ. Stop an individual run under Slice 01's own escalation condition without giving the other Writer privileged repair information.

## Required audit boundary

The benchmark comparison and the schema/persistent-data audit are one mandatory boundary after both complete. Slice 02 cannot begin until CONTROL records the two scores/categories, selected/rejected patch disposition, exact test evidence, and independent audit verdict.

