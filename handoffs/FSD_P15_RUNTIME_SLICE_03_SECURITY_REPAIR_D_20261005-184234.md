# P15 Slice 03 bounded process/security repair

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_P15_RUNTIME_SLICE_03_SECURITY_REPAIR_D_20261005-184234.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=41b1e6f6269c4efb2ea3c6b4eb78a9fc24cdedea
REMOTE_HEAD=936756ec610e0fe0a2e5620b2d2689b67d89e40a
LAST_VERIFIED_AT=2026-10-05T18:42:34+07:00
AUTHORITY_PTRS=AGENTS.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|STATE/PROJECT_STATE.md|docs/P15_RUNTIME_PLAN.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_P15_RUNTIME_SLICE_03_SECURITY_REPAIR_020
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_WITHIN_REPAIR_SCOPE;BRAIN_REVIEW_AND_INDEPENDENT_REAUDIT_REQUIRED
PROPOSED_NEXT=FSD_P15_RUNTIME_SLICE_03_SECURITY_REAUDIT_021
NO_AUTO_NEXT=YES

## Task lock and disposition

TASK_ID=FSD_P15_RUNTIME_SLICE_03_SECURITY_REPAIR_020
ROLE=WORKER
MODE=BOUNDED_PROCESS_SECURITY_REPAIR
BASE_HEAD=936756ec610e0fe0a2e5620b2d2689b67d89e40a
UPSTREAM_HEAD=936756ec610e0fe0a2e5620b2d2689b67d89e40a
TECHNICAL_SHA=41b1e6f6269c4efb2ea3c6b4eb78a9fc24cdedea
TECHNICAL_BASE=aafe69fe7b074d9964c338bf91b3603300df6e26
AUDIT_PUBLICATION=350769b7d42052916eb80c1d38d767ab469a57a2
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=F1_SLICE03_TRUST_BOUNDARY_PROJECTION;F2_ATOMIC_LAUNCH_AUTHORIZATION_AND_CAUSAL_TESTS
ALLOWED_PATHS=FSD/Classification/BundledMagikaClassificationProvider.swift|FSDTests/BundledMagikaClassificationProviderTests.swift|docs/P15_RUNTIME_PLAN.md|handoffs/FSD_P15_RUNTIME_SLICE_03_SECURITY_REPAIR_D_20261005-184234.md|handoffs/CURRENT_HANDOFF.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl
DESKTOP_TRANSPORT=/Users/cenvu/Desktop/04_FSD_BRAIN.md
FORBIDDEN_PATHS=ALL_OTHER_PRODUCT_TEST_DOC_CHECKER_SCHEMA_PROJECT_PATHS;STATE/PROJECT_STATE.md;STATE/RULE_PROMOTION_LEDGER.tsv;PRIOR_HANDOFFS
SUCCESS_CRITERIA=LOCKED_F1_DISPOSITION;CAUSAL_RED_GREEN_F2;CLEAN_BUILD;FOCUSED_AND_FULL_DEBUG;ONE_RETURN;CLEAN_SYNCED_PUBLICATION
VALIDATIONS=XCODEBUILD_RED_GREEN_CLEAN_BUILD_FOCUSED_FULL;GIT_DIFF_CHECK;PROTECTED_BYTE_PARITY;CANONICAL_CONTROL_PLANE_CHECKER
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
WORKER_RESULT=PASS_WITH_ADVISORY
RESULT_AUTHORITY=WORKER_LOCAL_EVIDENCE_ONLY;BRAIN_ADJUDICATION_PENDING

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=20
WORKER_REQUIREMENTS_EVIDENCED=20
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

The bounded repair passes its execution gates. F1 is projected from explicit BRAIN authority, not technically eliminated. F2 is repaired at an atomic launch-authorization boundary. Advisory: no real helper integration or process-tree containment is proved; independent re-audit 021 is mandatory before Slice 04. Accepted STATE remains untouched and still requires repair/re-audit adjudication.

## Reanchor and scope

FACT: initial clean local main was audit publication 350769b. Non-destructive fetch found precisely the expected 936756e BRAIN commit; inspected its three control-plane changes and accepted-state authorization, then git pull --ff-only origin main fast-forwarded without a merge commit. HEAD=origin/main=936756ec610e0fe0a2e5620b2d2689b67d89e40a, ahead=0, behind=0, primary worktree clean before mutation. No reset/clean/stash/rebase/force or baseline-manufacturing operation. Baseline captured tracked byte hashes (including symlink targets), original Desktop and all 10,396 ignored path names before edits. All pre-existing ignored names and protected tracked bytes remain preserved.
Read scope: AGENTS, execution/finalizer skills, CURRENT HOT, accepted STATE, P15 Slice03 and Slice07 gate, audit F1/F2 and immediate reasoning, adapter and adapter tests. Compact Operator, ledger/event tails and Desktop envelope are directly applicable finalization authority. No long history or other product files loaded for repair.
FACT: technical commit contains exactly the three authorized production/test/doc paths. Historical HOT captures the actual technical commit before publication; upstream was the BRAIN base and ahead=1/behind=0. The reporting publication is resolved externally with git log -1 --format=%H -- the historical path; no self-referential SHA or extra bookkeeping commit.

## F1 — BRAIN-approved boundary projection

F1_CODE_FIX=NOT_APPLICABLE_BY_BRAIN_TRUST_BOUNDARY
F1_PATH_TOCTOU=KNOWN_OUTSIDE_THREAT_MODEL
F1_RUNTIME_IMMUTABILITY_CLAIM=NONE
F1_THREAT_BOUNDARY_CLARIFIED=PASS
F1_PATHNAME_TOCTOU_STILL_EXISTS_UNDER_BUNDLE_MUTATION=YES
F1_BUNDLE_MUTATION_IN_SCOPE=NO
F1_PATH_TOCTOU_FALSE_CLAIM=NONE
F1_REAL_HELPER_SIGNING_CLAIM=NONE

FACT: docs/P15_RUNTIME_PLAN.md:247,257-259 projects TRUSTED_CODE_ROOT=FSD_INSTALLED_SIGNED_APP_BUNDLE. Same-principal application-code mutation/rename/replacement/rewrite after trusted resolution is outside this seam's threat model. Path validation remains a pathname check, not object-bound execution; the wording makes no runtime namespace immutability, macOS atomic protection or signing-prevents-mutation claim. Existing fixed resolution, canonical containment, regular/executable validation, no PATH/shell/config override remain mandatory and source bytes are unchanged. No recheck, sleep/retry, stat, codesign command, helper copy, fd launch trick or new execution technology was introduced.
Slice07 text is byte-identical. The Slice03 cross-reference requires future real nested-helper signing/packaging, bundle placement, artifact identity/distribution integrity and no persistent descendants before integration; it does not assert any such fact is currently verified. Audit019's pathname finding remains factually valid under hostile bundle mutation; the accepted disposition is a scoped trust decision supplied by Owner/BRAIN, not a fake technical closure/test.

## F2 — atomic launch authorization

FACT: FSD/Classification/BundledMagikaClassificationProvider.swift:61-73 now resolves the trusted fixed executable, creates an inert runner, calls HelperCancellation.authorizeLaunch(), returns cancelled immediately if denied, and only then calls runner.launch. The previous separate prelaunch isCancelled check was replaced by this authorization; no process launch occurs in runner creation (production runner:169-197).
The same NSCondition lock protects cancelled, completed and new launchAuthorized (134-161). At 142-143, authorization atomically checks all three states and records permission once. cancel under that lock first means authorization is denied and launch is forbidden. Authorization first means launch is permitted even if cancellation occurs before/during Process.run. The lock's defer unlock executes before authorizeLaunch returns: no condition lock spans launch, blocking OS work or runner callback, and onCancel remains only cancel().
Cancellation after authorization still records cancelled. Once launch returns, the existing driver check and error/cancellation cleanup terminate/close/reap any launched child (100-110); complete uses the same lock after cleanup (157-161). Completion first makes subsequent cancel inert; cancellation first forces the terminal cancelled result even after parse/cleanup. One owned worker operation still resumes one continuation once. No runner work follows completion. Physical kernel child creation is deliberately not the semantic boundary.
Denied authorization returns before any runner launch/terminate/reap call. The inert runner falls out of scope without owning a child; production Pipe/FileHandle objects remain locally owned. No process-tree redesign is needed.

F2_CANCEL_BEFORE_AUTHORIZATION_LAUNCH_CALLS=0
F2_LAUNCH_AUTHORIZATION_LINEARIZED=PASS
F2_AUTHORIZATION_FIRST_THEN_CANCEL=PASS
F2_COMPLETION_FIRST_STABLE=PASS
ACTIVE_CANCEL_TERMINATE=PASS
ACTIVE_CANCEL_CLOSE=PASS
ACTIVE_CANCEL_REAP=PASS

## Permanent tests and causal falsifiability

| Case / evidence in adapter tests | Deterministic arrangement and observed result | Production regression that makes it fail |
|---|---|---|
| A: testCancellationDuringRunnerCreationPreventsLaunchAuthorization, 234-253 | Factory entered expectation; task.cancel completes before semaphore release. cancelled; launch count0; no modeled child URL; no reap or runner events. No sleep. | Missing/bypassed post-factory authorization, or check before factory with an unlocked gap. Old production actually failed these assertions. |
| B: testLaunchAuthorizationFirstThenCancellationDuringLaunchCleansUp, 255-274 | Fake launch records one modeled child then blocks. Cancel before release; exactly launch/terminate/closePipes/reap and cancelled; no payload. | Preventing permitted launch after authorization, failing post-launch cancellation cleanup/result, skipping/duplicating cleanup, or holding the cancellation lock across launch (timeout assertion). |
| C: testCancellationBeforeLaunchAndCompletionOrdering, 291-315 | Task reaches classify only after already cancelled; no runner events. Token verifies cancel-before-authorization denial. | Losing entry cancellation or authorizing a cancelled token. |
| D: testCompletionFirstRemainsStableAfterTaskCancellation, 276-289; ordering token at303-315 | Classified task completion awaited, then cancel; same result, same events, reaped/closed. Token explicitly checks complete-first cancellation inertness and denial after completion. | Changing locked complete/cancel ordering; runner activity after completion. Awaiting Task.value alone cannot prove the internal completion lock, so the token assertion and source reasoning also matter. |
| Existing active cancellation, 217-232 | Fake poll synchronizes with condition cancellation; terminate/close/reap and cancelled. Kept unchanged. | Removing cancellation servicing or cleanup before returning. |
| Existing resolver/raw/cap/parser/provenance/source tests | Focused and full green; unchanged driver payload/cap/parse code. | Existing tested boundary regressions remain detectable within their established limits. |

New fake launch hook models an active child by recording launchedURL before synchronization; it never creates a real process. Assertions are inspected only after task.value, after the owned driver operation finishes. Expectations/semaphores establish event ordering; five-second limits detect broken synchronization and are not sleeps or the ordering mechanism. Token tests also verify one authorization only and cancellation still winning completion after authorization.
Limits: these driver tests prove host launch/cancellation ordering and calls, not OS SIGTERM/SIGKILL or a real helper's behavior. Existing real-pipe tests still exercise production pump caps without a child. Existing resolution tests reject pre-existing symlink escape; they never claimed pathname TOCTOU elimination, and no new test claims that. Production runner construction is inert with respect to child launch by direct inspection, not a real-process fixture.

## Validation receipts

DerivedData was absent before the first causal RED: /tmp/FSD-P15-S03-Repair-DerivedData. Every xcodebuild invocation used FSD.xcodeproj, scheme FSD, Debug, destination platform=macOS,arch=arm64 and that path. No external helper command/artifact was created or invoked.

| Phase | Command tail and actual exit | Executed / passed / skipped / failed | Evidence |
|---|---|---|---|
| Causal RED on unchanged production | test -only-testing:FSDTests/BundledMagikaClassificationProviderTests/testCancellationDuringRunnerCreationPreventsLaunchAuthorization; exit65 | 1 / 0 / 0 / 1, four intended assertion failures | /tmp/FSD-P15-S03-Repair-red.log; /tmp/FSD-P15-S03-Repair-DerivedData/Logs/Test/Test-FSD-2026.10.05_17-56-42-+0700.xcresult |
| Minimal GREEN | test -only-testing:FSDTests/BundledMagikaClassificationProviderTests -only-testing:FSDTests/ClassificationProviderContractTests; exit0 | 27 / 27 / 0 / 0 | /tmp/FSD-P15-S03-Repair-green.log; /tmp/FSD-P15-S03-Repair-DerivedData/Logs/Test/Test-FSD-2026.10.05_17-58-16-+0700.xcresult |
| Clean Debug build | clean build; exit0; BUILD SUCCEEDED | build | /tmp/FSD-P15-S03-Repair-build.log |
| Fresh focused after clean build | test with the same two only-testing classes; exit0 | 27 / 27 / 0 / 0 | /tmp/FSD-P15-S03-Repair-focused.log; /tmp/FSD-P15-S03-Repair-DerivedData/Logs/Test/Test-FSD-2026.10.05_17-59-24-+0700.xcresult |
| Full Debug | test with no only-testing filter; exit0 | 402 / 399 / 3 / 0 | /tmp/FSD-P15-S03-Repair-full.log; /tmp/FSD-P15-S03-Repair-DerivedData/Logs/Test/Test-FSD-2026.10.05_17-59-50-+0700.xcresult |

RED root cause: old execute checked cancellation before entering makeRunner and never checked/authorized atomically afterward. The test returned cancelled but launched once, set a child URL, reaped and emitted events, failing the four no-child assertions (red.log:923-926). No setup/compiler/timeout failure counted as causal RED. One minimal repair attempt succeeded; no repair retry or unrelated refactor.
Focused final receipt: Executed 27 tests, with 0 failures (0 unexpected) in 0.346 (0.355) seconds. Full final receipt: Executed 402 tests, with 3 tests skipped and 0 failures (0 unexpected) in 2245.346 (2468.932) seconds. Skips are the existing external-fixture cases in FSDProbeSeedTests and FilesystemMatrixTests (exact identifiers/reasons recorded below); they are not new skips or suppressed failures. Build/test warnings are existing AppIntents extraction skip for no framework dependency, SDK test-framework stripping/signing and macOS13/newer XCTest linkage; no compiler error. The full run also emitted a Thread Performance Checker priority-inversion diagnostic with M5PeakSampler.stop at the top of its backtrace during the existing million-entry comparison memory probe; that case passed (125.654 seconds). This is a validation advisory outside the three-file repair, not an XCTest failure or a reason to expand scope.

FULL_SKIP_RECEIPTS:
/Users/cenvu/DEV/FSD/FSDTests/FSDProbeSeedTests.swift:26: -[FSDTests.FSDProbeSeedTests testSeedIsolatedProbeCatalog] : Test skipped - FSD_PROBE_CATALOG is not set and no marker file exists; the probe seeding is inert in ordinary runs
Test Case '-[FSDTests.FSDProbeSeedTests testSeedIsolatedProbeCatalog]' skipped (0.001 seconds).
/Users/cenvu/DEV/FSD/FSDTests/FilesystemMatrixTests.swift:25: -[FSDTests.FilesystemMatrixTests testCaptureExternallyPreparedMountedFilesystem] : Test skipped - FSD_MATRIX_SOURCE is not set; the filesystem matrix probe is inert in ordinary runs
Test Case '-[FSDTests.FilesystemMatrixTests testCaptureExternallyPreparedMountedFilesystem]' skipped (0.001 seconds).
/Users/cenvu/DEV/FSD/FSDTests/FilesystemMatrixTests.swift:89: -[FSDTests.FilesystemMatrixTests testReopenCapturedSnapshotWithTheSourceDetached] : Test skipped - FSD_MATRIX_OFFLINE_CATALOG is not set; the offline reopen probe is inert in ordinary runs
Test Case '-[FSDTests.FilesystemMatrixTests testReopenCapturedSnapshotWithTheSourceDetached]' skipped (0.001 seconds).
Test Case '-[FSDTests.MilestoneConditionTests testPackageContentsAreStillSkippedAtomically]' started.
Test Case '-[FSDTests.MilestoneConditionTests testPackageContentsAreStillSkippedAtomically]' passed (0.008 seconds).

## Preserved boundaries and remaining integration obligations

RAW_STDIN_CONTRACT_UNCHANGED=YES
STDOUT_CAP_UNCHANGED=4096
STDERR_CAP_UNCHANGED=4096
PARSER_CONTRACT_UNCHANGED=YES
PROVENANCE_CONTRACT_UNCHANGED=YES
REAL_HELPER=NONE
NETWORK=NONE
SLICE04_DELTA=NONE
FOCUSED=PASS
FULL_DEBUG=PASS
PROCESS_TREE=NO_HOST_GUARANTEE

FACT: byte comparisons against base prove resolver/provenance prefix, all driver code from output initialization through existing completion, and all runner/pump/parser bytes from HelperProcessFault onward unchanged. Every doc byte before Slice03 and from Slice04 onward is unchanged. Protected tracked file hashes (including request/source-reader/SnapshotWriter/schema/Xcode/project/state/rule-ledger/prior historical handoffs) remain unchanged; only authorized reporting projections follow. NETWORK=NONE describes classification changes; required Git fetch/push is the authorized publication transport.
No process group, daemon management, tree enumeration, XPC, helper behavior assumption, shell, dependency or Magika integration/research. Slice07 remains closed. Future verified real helper must not spawn persistent descendants; this is an integration obligation, not a repair020 host guarantee. No real signing/packaging facts claimed.

## Requirement/evidence map and execution postflight

All statuses below are EVIDENCED for this bounded repair, not independent security acceptance or verification of future integration.

| # | Requirement | Evidence |
|---|---|---|
| 1 | Exact task/repo/main/base/upstream; fresh0/0 preflight | Non-destructive fetch/FF receipt, base hashes and accepted gate020 |
| 2 | Execution authority/skill and accepted F1/F2 disposition | AGENTS/execution skill; BRAIN STATE and Owner task |
| 3 | Preserve dirty/untracked/ignored/protected state | Clean initial worktree; baseline hashes and all10,396 ignored names preserved |
| 4 | F1 trusted installed/signed code-root wording | Slice03 locked docs:257-259 |
| 5 | No false object-binding/immutability/TOCTOU fix | F1 fields, unchanged resolver; explicit pathname limit |
| 6 | Future signing/identity/integrity gate; Slice07 unchanged | Slice03 cross-reference and byte comparison |
| 7 | Same-lock atomic launch authorization after inert creation | Production61-73,134-161; runner169-197 |
| 8 | CaseA deterministic no-launch/no-child/no-reap | Permanent test234-253; actual causal RED and GREEN |
| 9 | CaseB authorization first/cancel during launch cleanup | Permanent test255-274; exact event sequence |
| 10 | CaseC already-cancelled never launches | Test291-315 |
| 11 | CaseD stable completion and no later activity | Test276-289 plus complete-first token assertions |
| 12 | Active cancellation terminate/close/reap unchanged | Test217-232; production cleanup byte parity |
| 13 | No lock across Process.run/no cancellation-handler blocking on launch | authorizeLaunch unlocks before return; B timed gate; onCancel token only |
| 14 | Raw payload/caps/parser/provenance unchanged | Exact bounded byte comparisons and focused production-pipe/contract tests |
| 15 | Production/test/doc delta confined to three allowed paths/Slice03 | Complete diff/status; protected bytes; technical commit |
| 16 | Process-tree advisory/no real helper/dependency/new execution technology | Source unchanged outside F2; gate/remaining-obligation record |
| 17 | Required clean Debug build | Actual exit0 BUILD SUCCEEDED receipt |
| 18 | Required focused and full exact counts | 27/27/0/0 focused; 402/399/3/0 full; logs/XCResults |
| 19 | Execution diff/byte postflight before finalizer | git diff --check exit0; scope/hash review; no semantic unknown in repair scope |
| 20 | Exactly one handoff, normal closure projections and return-only proposal | This source; finalizer checks publish and Desktop receipts separately; re-audit not started |

Execution postflight passed before invoking finalization: current candidate, full diff, actual logs/exits, all protected paths, exact authority/gates rechecked. Counts do not claim closure mechanics before they occur. Publication/checker/transport outcomes are captured after this immutable record externally in Desktop and the terminal return. No mutable accepted state, prior classification or historical report is replaced.

Proposed state delta: BRAIN reviews the bounded repair evidence and authorizes the one mandatory independent re-audit only if satisfied. The existing accepted STATE remains the audit disposition until BRAIN adjudicates. Worker does not start the proposal or Slice04.
