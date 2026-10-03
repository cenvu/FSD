# FSD model-benchmark purge and final readiness

## Identity
TASK=FSD_BENCHMARK_MODEL_PURGE_AND_READINESS_GATE_001
PROJECT=FSD
ROLE=WORKER (D — control-plane documentation and fresh automated validation)
MODE=CONTROL_PLANE_CLEANUP_PLUS_FINAL_READINESS
COMPLETED_AT=2026-10-03T22:08:25+07:00
STATUS=COMPLETE_WITH_KNOWN_LIMITATIONS
RESULT=PASS_WITH_ADVISORY
READY_TO_IMPLEMENT=YES
READINESS_SCOPE=Separately authorized ADR-032 schema prerequisite only; no implementation is authorized by this report.

## RAW_REFS
REPO_ROOT=/Users/cenvu/DEV/FSD
REMOTE_ORIGIN=https://github.com/cenvu/FSD.git
BRANCH=main
UPSTREAM=origin/main
EXPECTED_AND_VERIFIED_PREFLIGHT_HEAD=78ab13f2a07b6c45407043d53fe699ab8480c843
PREFLIGHT_LOCAL_EQUALS_UPSTREAM=YES
PREFLIGHT_AHEAD_BEHIND=0/0
PREFLIGHT_PRIMARY_WORKTREE_CLEAN=YES
PREEXISTING_NONIGNORED_UNTRACKED_PATHS=NONE
CLEANUP_COMMIT=1b1c63dd134f52555d85bff7cdbc7b203e7247eb
CLEANUP_PUSH=CONFIRMED
POST_CLEANUP_FETCH=PASS
READINESS_SNAPSHOT_LOCAL_HEAD=1b1c63dd134f52555d85bff7cdbc7b203e7247eb
READINESS_SNAPSHOT_UPSTREAM_HEAD=1b1c63dd134f52555d85bff7cdbc7b203e7247eb
READINESS_SNAPSHOT_AHEAD_BEHIND=0/0
READINESS_SNAPSHOT_PRIMARY_WORKTREE_CLEAN=YES
READINESS_SNAPSHOT_UNSYNCED_DURABLE_CONTROL_PLANE=NONE
READINESS_SNAPSHOT_WORKTREE_REGISTRATIONS=PRIMARY_ONLY

These Git facts were measured after cleanup publication and before creating
this immutable handoff. Publication of this handoff, CURRENT copy and current
product-state pointer follows that snapshot; the final Worker return records
the actual publication commit and post-fetch sync result. Resolve the
self-containing publication commit without relying on an invented SHA:
`git log -1 --format='%H %s' -- handoffs/FSD_MODEL_BENCHMARK_PURGE_READINESS_D_20261003-220825.md`.

Accepted authority inputs, unchanged:
- `handoffs/FSD_M5_SCHEMA_V8_DISPOSAL_REAUDIT_A_20260805-223211.md`
- `handoffs/FSD_P15_MAGIKA_NULLABLE_ENRICHMENT_AUDIT_R_20260807-142313.md`
- `handoffs/FSD_P15_MAGIKA_RUNTIME_DESIGN_A_20260807-155630.md`
- `docs/AGENT.md`, current product/plan/decision/test authority, and project Handoff Skill.

## REPORT
MODEL_BENCHMARK_ACTIVITY=REMOVED
MODEL_BENCHMARK_CURRENT_OR_FUTURE_GATE=NONE
PRODUCT_PERFORMANCE_VALIDATION=PRESERVED
PRODUCT_EXECUTABLE_DIFF=EMPTY
UNRESOLVED_CURRENT_AUTHORITY_CONTRADICTIONS=0

Deleted `P15_RUNTIME_MULTI_MODEL_BENCHMARK.md`. Its prior bytes remain in Git
history at the preflight commit (blob 6e19e6a125bb1ae86a917ed5ab82e3fa5fc082de); no timestamped
historical evidence was rewritten. Removed slice 01's parallel model run,
benchmark setup/provenance dependency, scoring/patch-selection boundary and
worktree-specific benchmark build-path instruction. Slice 02 now requires
the independent schema/persistent-data audit alone. The schema audit remains
mandatory; removing model comparisons does not waive product safety review.

Recorded the owner's ban in AGENT, README and PRODUCT_STATE, and removed the
generic model-routing skill's exception allowing a benchmark project.
Ordinary model routing remains routing, with no comparative runs or scoring.
Completed design/correction packets and old handoff next actions are historical
only. Runtime TODOs remain planning contracts requiring separate authorization.

### Dead worktree evidence and safe cleanup
- `/Users/cenvu/DEV/FSD_BENCH_D` and `FSD_BENCH_G` both absent, including symlinks.
- Both registered gitdir targets absent; registrations explicitly prunable.
- Branches `benchmark/deepseek-p15-01-r2` and `benchmark/gemini-p15-01-r2`
  both point to `2cd26901f405a9065e38ae21ada19f2d5f780784`, with zero commits
  unique against canonical upstream.
- Both administrative indexes have an empty cached diff against that commit.
  Per-worktree refs contain no files; HEAD reflogs contain only initial
  registration and reset to that same base. FETCH_HEAD/ORIG_HEAD contain the base.
- No live worktree, dirty/untracked files or unique uncommitted index evidence
  exists to remove. Dry-run selected exactly these two dead registrations.
- `git worktree prune --verbose --expire now` removed exactly those registrations.
  Final porcelain worktree inventory contains the primary FSD worktree only.
- Common Git objects and the two non-unique inactive branch refs were preserved.
  They provide historical provenance and have no active benchmark instructions.

### Remaining search-hit classification
- HISTORICAL_ONLY: old model names, scorecards and benchmark observations in
  timestamped handoffs; completed correction packets A/A_FIX; prior design
  packet TODO.md. Original history remains immutable, not an execution gate.
- PRODUCT_VALIDATION: ARCHITECTURE transaction sizing, MVP_PLAN performance
  harness, TEST_PLAN §4 10k/100k/1M classes and historical technical review
  performance references. All retained.
- CURRENT_CORRECT: owner prohibitions, slice 01's schema audit and slice 02's
  schema audit prerequisite after benchmark removal.
- ORDINARY_ROUTING_OR_EXTERNAL_GATE: generic routing suggestions and slice 07
  external Magika verification stop gate. Neither is model benchmarking.
- UNRESOLVED=NONE. The removed plan has no active nonhistorical dependency.

## Fresh product validation — AUTOMATED VERIFIED
Toolchain: Xcode 26.3 (17C529); arm64; macOS 15.7.7.
Clean Debug build: exit 0; CLEAN SUCCEEDED and BUILD SUCCEEDED.
Full Debug suite: exit 0; TEST SUCCEEDED; xcresult result Passed.
TESTS_EXECUTED=293
TESTS_PASSED=290
TESTS_FAILED=0
TESTS_SKIPPED=3
EXPECTED_FAILURES=0

The three skips are intentionally inert external probes:
FSDProbeSeedTests/testSeedIsolatedProbeCatalog;
FilesystemMatrixTests/testCaptureExternallyPreparedMountedFilesystem;
FilesystemMatrixTests/testReopenCapturedSnapshotWithTheSourceDetached.
No probe inputs were supplied; skips were not hidden or relabeled PASS.
Catalog bootstrap, migration/equivalence/rollback, schema safety, nullable
classification, metadata/read-only boundaries, cancellation/recovery and
reliability tests passed in the unfiltered canonical suite.

All 8 final-scale comparison, 6 memory and 3 snapshot tests passed.
Fresh Debug correctness evidence includes exact 1M comparison, repeat-run
determinism, navigation, reopen, bounded paging, memory ceilings, streamed
export, cancellation and clean disposal. Automatic live workspace close:
10.398 s; explicit disposal: 10.132 s; each processes 1,000,000 result rows
with clean integrity/foreign keys and no residue. These Debug measurements
do not replace historical Release performance acceptance.

Built/canonical schema SHA-256 both:
`51fb289161533c7ea81d7ce99e41c7b0ef88a785e0b141136927a1a0d11baae0`.
CatalogMigrations.currentVersion remains 8. The app contains no Magika/ONNX
model payload. The only production provider conformer remains
DisabledFileClassificationProvider, returning unavailable without filesystem
access; the enrichment service is not injected into ordinary workflows.
Test-host diagnostic names the isolated FSD-TestHost-47211 catalog, not the
owner's Application Support catalog. No owner manual acceptance was performed.

Exact validation commands, from the canonical root:
```sh
git -c gc.auto=0 fetch --no-prune --no-tags --no-recurse-submodules origin
git worktree list --porcelain
git worktree prune --dry-run --verbose --expire now
git --git-dir=.git/worktrees/FSD_BENCH_D diff --cached --name-status 2cd26901f405a9065e38ae21ada19f2d5f780784
git --git-dir=.git/worktrees/FSD_BENCH_G diff --cached --name-status 2cd26901f405a9065e38ae21ada19f2d5f780784
git rev-list --count benchmark/deepseek-p15-01-r2 --not origin/main
git rev-list --count benchmark/gemini-p15-01-r2 --not origin/main
git worktree prune --verbose --expire now
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath "$PWD/.agent/FSD_BENCHMARK_MODEL_PURGE_AND_READINESS_GATE_001/DerivedData" clean build
xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath "$PWD/.agent/FSD_BENCHMARK_MODEL_PURGE_AND_READINESS_GATE_001/DerivedData" -resultBundlePath "$PWD/.agent/FSD_BENCHMARK_MODEL_PURGE_AND_READINESS_GATE_001/FullDebug.xcresult"
xcrun xcresulttool get test-results summary --path .agent/FSD_BENCHMARK_MODEL_PURGE_AND_READINESS_GATE_001/FullDebug.xcresult --compact
git diff --check
git diff --name-only 78ab13f2a07b6c45407043d53fe699ab8480c843 -- FSD FSDTests FSD.xcodeproj docs/database docs/ARCHITECTURE.md docs/SECURITY_AND_READ_ONLY_POLICY.md docs/DEPENDENCY_AND_LICENSE_REVIEW.md
git status --porcelain=v1 --untracked-files=all
git rev-parse HEAD origin/main
git rev-list --left-right --count HEAD...origin/main
git push origin HEAD:refs/heads/main
```
Raw logs and xcresult are grouped in the new ignored project-local task
directory `.agent/FSD_BENCHMARK_MODEL_PURGE_AND_READINESS_GATE_001/`.
No separate report/checksum sidecars or Desktop artifacts were created.

## Authority and boundaries
M1_M5_TECHNICAL_CORE=CLOSED_WITH_KNOWN_LIMITATIONS
M5_REAUDIT=CLOSED_APPROVE_WITH_CONDITIONS
P15_NULLABLE_BOUNDARY=IMPLEMENTED_AND_AUDITED_APPROVE_WITH_CONDITIONS
MANUAL_ACCEPTANCE=NOT_PERFORMED_DEFERRED_BY_OWNER
OVERALL_MVP_APPROVAL=NOT_CLAIMED
MAGIKA_RUNTIME_DESIGN=COMPLETE
MAGIKA_RUNTIME_IMPLEMENTATION=NOT_STARTED
SCHEMA_CURRENT=v8
MAGIKA_RUNTIME_SCHEMA_GATE=SCHEMA_CHANGE_REQUIRED_BEFORE_RUNTIME
READINESS_BLOCKER=NONE_FOR_SEPARATELY_AUTHORIZED_SCHEMA_PREREQUISITE
ADVISORIES=Three probe skips; existing manual/technical limitations; later external Magika verification remains a separate gate.

Exactly nine unique allowlisted control-plane paths change across cleanup and
handoff publication: deleted plan; runtime TODOs 01/02; AGENT; README;
PRODUCT_STATE; MODEL_SUGGESTION_SKILL; this handoff; CURRENT_HANDOFF.
Protected product Swift/tests/Xcode/schema/migration/read-only/license paths
have an empty diff against the verified preflight base. Original source
invariants and executable behavior were not changed by this cleanup.
All 46 prior historical handoff content hashes and metadata of all 4,428
pre-existing ignored paths match the preflight inventory. New ignored build/test
artifacts are separate; no unknown ignored state was cleaned.

## Exactly one proposed next action
PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_READINESS_ADJUDICATION

Worker readiness evidence does not write BRAIN classification or authorization.
STOP: no schema v9, provider_identifier or Magika implementation; no new model
benchmark, owner acceptance or unrelated product repair.
