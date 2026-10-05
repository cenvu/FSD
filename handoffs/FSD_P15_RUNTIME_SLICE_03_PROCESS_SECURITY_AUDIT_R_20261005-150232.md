# P15 Slice 03 independent process/security audit

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_P15_RUNTIME_SLICE_03_PROCESS_SECURITY_AUDIT_R_20261005-150232.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=a898e9e6b1d0c48864fb39aa12fac2d85be4dea6
REMOTE_HEAD=a898e9e6b1d0c48864fb39aa12fac2d85be4dea6
LAST_VERIFIED_AT=2026-10-05T15:02:32+07:00
AUTHORITY_PTRS=AGENTS.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-independent-review/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|STATE/PROJECT_STATE.md|docs/P15_RUNTIME_PLAN.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_P15_RUNTIME_SLICE_03_PROCESS_SECURITY_AUDIT_019
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=MATERIAL_EXECUTABLE_TOCTOU_AND_PRELAUNCH_CANCELLATION_GAP
PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_FSD_P15_SLICE_03_PROCESS_SECURITY_AUDIT_ADJUDICATION
NO_AUTO_NEXT=YES

## Task lock and audit verdict

TASK_ID=FSD_P15_RUNTIME_SLICE_03_PROCESS_SECURITY_AUDIT_019
ROLE=REVIEWER
MODE=INDEPENDENT_PROCESS_SECURITY_AUDIT
BASE_HEAD=a898e9e6b1d0c48864fb39aa12fac2d85be4dea6
UPSTREAM_HEAD=a898e9e6b1d0c48864fb39aa12fac2d85be4dea6
TECHNICAL_SHA=aafe69fe7b074d9964c338bf91b3603300df6e26
IMPLEMENTER_PUBLICATION_SHA=e1570110bace482ba5399bfea76fc2eea25857a1
IMPLEMENTER_HANDOFF=handoffs/FSD_P15_RUNTIME_SLICE_03_BUNDLED_HELPER_HOST_ADAPTER_D_20261005-130041.md
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=READ_ONLY_ACCEPTED_SLICE_03_PROCESS_SECURITY_AUDIT;NO_REPAIR;NO_REAL_HELPER;NO_SLICE_04
ALLOWED_PATHS=handoffs/FSD_P15_RUNTIME_SLICE_03_PROCESS_SECURITY_AUDIT_R_20261005-150232.md|handoffs/CURRENT_HANDOFF.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl
DESKTOP_TRANSPORT=/Users/cenvu/Desktop/04_FSD_BRAIN.md
FORBIDDEN_PATHS=SWIFT|TESTS|DOCS|CHECKER|SCHEMA|XCODE_PROJECT|STATE/PROJECT_STATE.md|STATE/RULE_PROMOTION_LEDGER.tsv|HISTORICAL_HANDOFFS
SUCCESS_CRITERIA=INDEPENDENT_SEVEN_AUDITS;CAUSAL_TEST_REVIEW;FRESH_CLEAN_BUILD_AND_FOCUSED_TESTS;ONE_REVIEWER_RETURN
VALIDATIONS=FRESH_XCODEBUILD_CLEAN_BUILD;FOCUSED_TWO_CLASSES;SOURCE_AND_TEST_INSPECTION;ISOLATED_FAKE_RUNNER_CANCELLATION_PROBE;GIT_BYTE_SCOPE;CANONICAL_FINALIZER
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
WORKER_RESULT=REPAIR
RESULT_AUTHORITY=REVIEWER_EVIDENCE_ONLY;BRAIN_ADJUDICATION_PENDING

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=20
WORKER_REQUIREMENTS_EVIDENCED=20
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

REPAIR: the whole Slice-03 boundary does not pass. F1 establishes a material pathname-validation/launch gap; F2 reproduces launch after cancellation already won before launch. No repair is authorized or applied by this review. The counts describe completed audit questions, including evidenced defects; they do not assert that every production requirement passes. Slice 04 and Slice 07 remain closed. BRAIN alone adjudicates the accepted state and repair scope.

## Reanchor, provenance, scope and evidence limits

FACT: initial local main was implementer publication e157011, clean, while non-destructive fetch found the exact Owner-specified canonical a898e9e one commit ahead. Inspected that single BRAIN authorization/state commit, then performed a non-destructive fast-forward to the exact expected base (git merge --ff-only a898e9e). No merge commit, reset, clean, stash, rebase or force operation occurred. Re-read accepted STATE after reanchor. HEAD and origin/main then equalled the expected full SHA, ahead/behind=0/0. Existing ignored state was retained; before reporting, tracked bytes were unchanged and all 10,395 ignored path names were unchanged.
FACT: git diff --exit-code aafe69fe7b074d9964c338bf91b3603300df6e26 HEAD for adapter, adapter tests, contract tests and project returned 0. Technical commit added only the adapter/test files and Xcode registrations. No reviewed bytes were changed here. Canonical accepted STATE explicitly requires this audit before Slice 04.
Read set: kernel, CURRENT HOT/implementer evidence, execution/review/finalizer skills, accepted STATE, P15 Slice 03 and Slice 07 only; adapter and its tests; relevant contract boundary tests. Concrete launch-authority contradiction justified bounded searches of SECURITY_AND_READ_ONLY_POLICY, ARCHITECTURE and AGENT for bundle/signing authority, and ARCHITECTURE lines 398–435. No immutability/signing invariant supporting launch-time containment was supplied. LocalClassificationProvider request/disabled definitions were expanded to verify the structural byte/capability assertions directly. Compact Operator, ledger/event tails, Desktop envelope and checker mechanics were read only for authorized finalization. Local Apple SDK NSTask.h and sys/filio.h/ioccom.h supplied process and ioctl definitions. No external Magika facts, dependencies or assets were researched or introduced.
Limits: no actual executable/helper was created or launched. The focused suite uses fake runners and local pipes. The independent cancellation probe uses exact unchanged production-source copies plus a recording runner, outside the repository. Direct process/OS lifecycle reasoning is marked STRONG_INFERENCE rather than real-child runtime proof. Prior full suite is admissible implementer evidence only: 399 executed, 396 passed, 3 existing external-fixture skips, 0 failures; not repeated because findings are local to the new adapter and no product changes occurred.

## Material findings

F1 — executable authority is not bound to the executed object
SEVERITY=HIGH
FACT_OR_INFERENCE=STRONG_INFERENCE
EVIDENCE=FSD/Classification/BundledMagikaClassificationProvider.swift:32-44,63-71,170-186; docs/P15_RUNTIME_PLAN.md:245-260; STATE/PROJECT_STATE.md:20-23
BLAST_RADIUS=A caller's bounded prefix may reach a substituted executable outside the validated app bundle; that executable runs with host-launch credentials. Requires write/rename/symlink authority over a bundle path component during resolution-to-launch, not a data-only helper request capability.
WHY_EXISTING_TESTS_CATCH_OR_MISS=Resolver tests at FSDTests/BundledMagikaClassificationProviderTests.swift:68-102 reject a symlink that already escapes at check time. They never replace a checked path before Process.run; all driver launch tests use a fake. Source-token assertions cannot pin a filesystem object.
SMALLEST_REPAIR_DIRECTION=Bind executable launch authority to the validated object using a supported launch boundary, or obtain BRAIN's explicit, evidence-backed bundle-immutability threat-model decision. A second pathname check merely shortens the interval and does not close it. Add a causal substitution-boundary regression in a separately authorized repair.
Classification=MATERIAL_TOCTOU. FACT: canonicalization returns an ordinary URL string, permissions/regular-file checks are separate path operations, and Process receives that URL later; no open descriptor, stable object identity, launch requirement or mutation exclusion is retained. STRONG_INFERENCE: after validation, replace the regular helper at that canonical URL with an outside-pointing symlink, or replace an ancestor directory with one; a later path-based launch resolves the changed object. No $PATH/shell/argv/env override is needed. A signed or unwritable app bundle could supply an external invariant, but this task's actual authority does not establish it. The current design therefore relies on an unapproved bundle-namespace stability assumption; it cannot be classified SAFE_BY_EXISTING_INVARIANT.

F2 — prelaunch cancellation has a check/use gap
SEVERITY=MEDIUM
FACT_OR_INFERENCE=FACT
EVIDENCE=FSD/Classification/BundledMagikaClassificationProvider.swift:64-75,137-150; /tmp/FSD-P15-S03-Audit-cancellation-probe.swift and .log; FSDTests/BundledMagikaClassificationProviderTests.swift:234-251
BLAST_RADIUS=A call already cancelled before launch can still launch one child before the post-launch check terminates it. For the default runner, cancellation can win during runner construction or launch setup; this does not itself cause an unreaped child or a non-cancelled returned result.
WHY_EXISTING_TESTS_CATCH_OR_MISS=Existing prelaunch test cancels before classify starts; ordering test exercises the token alone. Active cancellation waits until poll. None gates cancellation after line 64 and before line 71. The independent fake-only probe gates makeRunner, waits until it is entered, synchronously cancels, then releases; unchanged execute calls launch afterward.
SMALLEST_REPAIR_DIRECTION=Define and synchronize launch authorization with cancellation so cancellation winning before that launch boundary prevents launch; add a deterministic driver regression for this interval. Preserve cleanup-before-completion and the existing final completion linearization.
FACT: probe exit 0 with CANCEL_BEFORE_LAUNCH_RESULT=cancelled and EVENTS=launch,terminate,closePipes,reap. It runs no real child. Thus the requested absolute cancel-before-launch/no-child invariant is false, while the eventual cancelled result and cleanup remain intact.

## Audit 1 — executable authority

Default construction captures Bundle.main.bundleURL (19). classify queues execute, which resolves the canonical standardized file root (40), appends fixed Contents/Helpers/FSDClassificationHostSeam, canonicalizes the executable (41), requires file URLs and root.path + slash containment (42–43), then executable permission and regular-file checks (32–34). Only that resolved URL reaches Process.executableURL (171); args=[] and env=[:] (172–173); run is direct (186). Missing/nonexecutable/directory/existing outside-symlink returns unavailable before runner creation. No user/default/environment executable override, $PATH search, shell or argv executable selection exists in the default path. Internal injection is a module testing seam, not provider input. These static selection checks pass; external executable acceptance at launch is not proven and is contradicted by F1.

## Audit 2 — raw input

FACT: LocalClassificationRequest has immutable Data alone, internal initializer rejects >4096 (LocalFileClassificationProvider.swift:14-27); contract tests:32-55 exercise shape, empty/max/oversize and copied slice storage. execute passes request.data unchanged to deliverInputOnce exactly once (55,75); production guards launched, !delivered and ceiling, sets delivered before I/O, and calls exactly one Darwin.write over the original buffer (194–202). Successful delivery closes stdin immediately (76). Failure takes terminate/closePipes/reap and closeInput (98–102,232–239). No encode/wrap/temp file/argv/env payload or second-read/source callback exists.
Zero bytes still invoke write with count=0 (nil base pointer is permitted for a zero transfer); result 0 satisfies exact count. Any syscall error, including an empty-write error, fails closed. EINTR/EAGAIN return -1, a short write differs from bytes.count, and early child closure returns failure such as EPIPE. F_SETNOSIGPIPE (185) prevents pipe failure from killing the host. No retry/fill-loop exists; delivered was set before the call, so a second delivery cannot occur. The fake test proves driver equality/count/order, not actual syscall behavior; production code establishes the one syscall path.

## Audit 3 — actual HelperPipePump, caps and deadlock

FACT: configure sets both read FDs O_NONBLOCK (255–259). Each 20ms poll iteration attempts one bounded read from EACH open channel, irrespective of readiness of the other (263–303). Scratch <=1024 per channel; stdout frame <=1024, stderr becomes only a count; driver cumulative guards precede append (78–84). Retained stdout <=4096, drained stderr <=4096, no stderr Data/text crosses the runner seam. Parser input is also <=4096. No unbounded accumulation/read-to-end appears.
Child writes stdout only: empty stderr read returns EAGAIN without blocking; reverse case is symmetric and has a real-pipe test. Filling both channels: each gets bounded nonblocking relief per loop; overflow terminates instead of waiting for exit. Child exits with buffered bytes: stopped=true still drains until EOF/EAGAIN on every channel. Snapshot stopped=false just defers final completion to another poll; it cannot call normal wait early. Normal waitUntilExit is reached only on finished=true, requiring stopped && both channels closed (304).
At exact cap while child runs, budget==0 queries FIONREAD (278–288), not read; pending=0 neither overflows nor closes without HUP. It can wait until runtime cancellation (no Slice-03 deadline). A 4097th byte queued later gives pending>0 on the next iteration, causing failed/terminate/close/reap; none is retained or drained beyond cap. Header-derived request equals _IOR('f',127,int); fresh real-pipe tests substantiate this encoding on this SDK.
POLLHUP with buffered bytes at positive budget still reads bytes before EOF; at zero budget pending>0 overrides HUP and fails. Empty HUP closes. read EAGAIN keeps a running channel open; stopped+EAGAIN closes. read EINTR retries only a later bounded polling read, never payload delivery; poll EINTR is tolerated, other poll/read/ioctl errors fail closed. No direct-child output can appear after stopped=true; no timing permits that direct child's cap overflow to pass unseen while keeping a full-pipe parent/child wait cycle. STRONG_INFERENCE: direct-child draining/reap ordering prevents such a cycle.
Descendant inheritance is a distinct limit: after direct child exit, empty inherited-writer pipes close deliberately instead of awaiting descendant EOF. Later descendant output can go unobserved after closure (including the zero-budget pending=0/stopped race). The caps govern bytes consumed/retained while pipes are owned, not lifetime production by arbitrary descendants. That prevents an inherited-open-FD wait but does not contain a process tree; see Audit 4.

## Audit 4 — termination, cleanup and process tree

Launch failure (including pump/fcntl failure) enters catch, terminate no-ops without launched, closes all six endpoints, and reaches the no-child reap boundary. For launched input/poll/cap failures or cancellation, exit stays nil: terminate, closePipes, reap; closing stdin is included. Valid/nonzero/signal exits reach the safe drained reap, then closePipes. Only zero noncrash parses. Exceptions never expose raw diagnostics. The runner caches exit (221–229), closeInput/allClosed/pump flags make closes idempotent, and there is one owner thread; cancellation handler never touches Process/FDs. No double continuation or competing reaper is introduced.
Local NSTask.h:45 defines terminate as SIGTERM, potentially ineffective. Code immediately checks isRunning and sends SIGKILL if still running (213–219); then closes pipes and waitUntilExit. STRONG_INFERENCE under ordinary same-credential Foundation child ownership: ignoring SIGTERM cannot preserve the direct child after successful SIGKILL; already-exited observations need only reap, and no full-pipe wait remains. A concurrent natural exit does not skip cleanup; subsequent cached reap cannot double-wait. The kill result is ignored, so this is not a universal proof against lost signal permissions or every kernel/framework failure; no authorized real-child test validates SIGTERM-ignore/SIGKILL/reap or launch-error OS behavior. No concrete ordinary direct-child alive/forever-wait race was established. Uninterruptible kernel stalls are not a new host-pipe defect demonstrated here.
PROCESS_TREE=NO_HOST_GUARANTEE. Positive processIdentifier targets only the direct child; no process group/session/tree enumeration exists. Forked descendants can survive cancellation, even after pipe closure, e.g. by ignoring pipe errors or doing no pipe I/O. Slice 03 prohibits the host introducing a daemon/watcher and requires direct-child termination, but does not explicitly require hostile-descendant containment. It adds no persistent service and ships no helper. Future verified helper behavior may supply a no-persistent-descendant invariant under Slice 07, whose locked no-daemon/offline rules remain binding. This is a bounded advisory/integration obligation, not an independently established present daemon defect. Do not claim host process-tree containment. If BRAIN broadens the threat model to arbitrary hostile forking helpers, a separate containment decision is needed before integration.

## Audit 5 — cancellation linearization

HelperCancellation.complete locks NSCondition, sets completed=true, broadcasts and chooses cancelled ? cancelled : result (146–150). This lock acquisition/state update after cleanup is the completion linearization point. cancel wins the same lock first => result cancelled; complete wins first => cancel observes completed and cannot alter result. No later Task.isCancelled check fabricates cancellation. One checked continuation resumes once from one owned queue operation after execute returns (51–55). No runner action occurs after complete; missing-helper/pre-cancel early completions created no runner.
Already-cancelled entry is captured by Task.isCancelled/onCancel and execute's first checks. Active cancellation marks the token; poll is bounded, driver rechecks before accepting the frame, then termination/closure/reaping precedes resume. Cancellation during parse or safe reap still wins complete, while a fully cleaned completed result is stable against later cancellation. All FD access belongs to the worker operation, preventing cancellation-driven use-after-close. There is no lost returned cancellation or double resume found. The stronger prelaunch no-child claim fails specifically in F2; terminal-result linearization does not linearize launch authorization. Real child behavior remains inferred; active test uses a waiting fake runner.

## Audit 6 — strict envelope and provenance

Parser is independent flat token parsing (322–404). Object accepts at most seven unique decoded keys; required schema/kind/four text/confidence account for all seven, so any extra or missing key fails. Escaped duplicate names also compare decoded strings. schemaVersion must be exact numeric token 1, excluding 1.0/1e0/boolean/unknown; kind only classified/unavailable/failed. Scalar accepts strings, JSON-validated numeric tokens, null; boolean/object/array/nested forms fail. Strings are JSONDecoder-validated, including escapes/UTF-8; decoded metadata strings must be nonempty, <=256 UTF-8 bytes and have no CharacterSet.controlCharacters (335–339). Confidence is null or JSON Double finite in closed 0...1 (343–349), excluding NaN/infinity/overflow/string/bool/out-of-range. object requires end after permitted JSON whitespace, rejecting trailing content. A nested empty object is not an exception: scalar rejects its opening token.
Unavailable/failed require text.isEmpty && confidence==nil; all five metadata fields must therefore be null. Classified requires detectedType; MIME/detector/model/confidence may be null. Host identifier fsd.bundled-helper-host.v1 is immutable and not an envelope field; adding providerIdentifier fails exact keys. Detector/model are distinct optional observation values, provider detectorVersion/modelVersion remain nil rather than fabricated constants. No stderr/error/exit message is returned; only closed result cases and approved metadata escape.
Test-table limits: classified invalid fixtures cover many schema/type/count/length/confidence errors, but do not independently exercise controls, malformed UTF-8/surrogates, multibyte byte ceiling, NaN/infinity spellings, escaped duplicate keys, 1e0, or unavailable-with-nonnull metadata. The failed result alone cannot distinguish rejecting an invalid declared-failed envelope from accepting it as failed. Code review supplies these checks, not invented green fixtures.

## Audit 7 — capability and inertness

Adapter receives request.data only; request carries no source path/URL/fd/metadata/resolver/callback/range capability. The provider holds a bundle URL, which is executable packaging authority rather than source authority. No source mutation or sample persistence API is added. Construction merely captures dependencies; no resolver/runner/Process launch until classify. Disabled provider and contract bytes equal the technical/accepted baseline. No network/telemetry/watcher/persistent daemon/schema/catalog/default scanner/automatic launch exists in the adapter. Fixed direct launch is the only activation, with F1/F2 limitations as above. No real helper or integration/runtime Slice 04 was begun.

## Test falsifiability — what production regression makes this fail

| Test boundary | Causal regression caught | Material limit |
|---|---|---|
| Real-pipe caps, tests:29–52 | Pump reads >1024/frame, fails to accumulate both budgets, misencodes FIONREAD, accepts queued 4097th byte, rejects empty/exact EOF | Both writers already closed and stopped=true; no late byte, active exact-cap writer, real exit or descendant timing |
| Stderr-only, tests:55–65 | Blocking stdout read hangs test; failing to service stderr changes count; copying diagnostic into frame fails reflection | Not sustained dual-channel saturation or process-level behavior |
| Fixed/canonical/physical resolution, tests:68–102 | Wrong relative target, no canonicalization, sibling-prefix escape, missing/dir/nonexecute acceptance | No namespace mutation after checks; misses F1 |
| One raw delivery, tests:17–26 | Driver changes bytes, delivers twice, omits close or orders drain before stdin close | Fake deliver does no syscall; a production write retry/encoding mutation alone can evade this test |
| Cumulative fake cap, tests:168–198 | Driver drops budgets, accepts fake oversize flag, skips terminate/reap | Fake itself clips frames; consumed<=4096 is partly fixture behavior, not production pump proof |
| Active-child cancellation, tests:217–231 | Shared driver loses token, omits terminate/reap/close, returns wrong outcome | Fake condition, no child; changing production terminate to no-op can stay green |
| Completion ordering, tests:234–251 | Token permits later cancellation to change completed state or cancellation-first loses | Token alone plus already-cancelled classify; misses F2 and full API completion races |
| Strict table/provenance, tests:114–165 | Parser accepts listed malformed fixtures, drops required metadata/key/type/finite guards, conflates detector/model or allows provider key | Listed fixtures only; declared failed masks acceptance/rejection and uncovered strings need direct review |
| Inert/contract/source tests, tests:254–277; contract:32–55,60–97,114–128 | Eager factory creation, extra request stored capability, >4096 admission, disabled side effects, named forbidden API tokens | Keyword scans are supplementary, not semantic/OS proof or future-helper network observation |

## Fresh validation receipts

Clean build: xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-P15-S03-Audit-DerivedData clean build; exit 0, BUILD SUCCEEDED.
Focused: xcodebuild test with the same flags/path, -only-testing:FSDTests/BundledMagikaClassificationProviderTests -only-testing:FSDTests/ClassificationProviderContractTests; exit 0, TEST SUCCEEDED; adapter 15 + contract 9 = 24 executed/24 passed/0 skipped/0 failed; 0.393 test seconds, 0.401 selected-suite wall seconds. Test-green is compatible with F1/F2 because those intervals are absent from the permanent tests.
Independent probe: xcrun swift /tmp/FSD-P15-S03-Audit-cancellation-probe.swift; exit 0, deterministic fake-runner launch-after-cancel receipt above, unchanged source copies, no helper Process. Source-prefix parity checked before publication.
Warnings: AppIntents extraction skipped without dependency; focused build also had SDK testing-framework signed-strip warnings and XCTest linking newer SDK framework than deployment target. No build/test failures.
RAW_REFS=/tmp/FSD-P15-S03-Audit-build.log|/tmp/FSD-P15-S03-Audit-focused.log|/tmp/FSD-P15-S03-Audit-cancellation-probe.swift|/tmp/FSD-P15-S03-Audit-cancellation-probe.log
FOCUSED_XCRESULT=/tmp/FSD-P15-S03-Audit-DerivedData/Logs/Test/Test-FSD-2026.10.05_14-55-30-+0700.xcresult
No full suite repeated; no skips counted as passes. No real child, helper, download, network probe, model/license/API research or dependency occurred.

## Requirement/evidence map and execution postflight

| # | Audited requirement | Evidence/disposition |
|---|---|---|
| 1 | Authority/base/worktree | Exact canonical reanchor 0/0; kernel/skills/state/task read; preserved ignored names |
| 2 | Technical/publication provenance | Four relevant paths byte-equal technical commit; accepted publication matches task |
| 3 | Fixed executable/overrides | Audit 1; direct args/env and resolution code |
| 4 | Launch TOCTOU challenge | F1 MATERIAL_TOCTOU, STRONG_INFERENCE; no approved immutability assumption |
| 5 | Bounded Data/exact raw one-write | Audit 2, request definition and syscall/driver trace |
| 6 | Empty/EINTR/EAGAIN/short/early-close | Audit 2, fails closed once, SIGPIPE suppression |
| 7 | Memory/channel caps/stderr privacy | Actual pump/driver, real-pipe fresh tests |
| 8 | Both pipes/cap+1/EOF/HUP/errors | Audit 3 source case analysis, bounded normal reap |
| 9 | Descendant writer/tree semantics | Audit 3/4; no host guarantee, future helper obligation |
| 10 | Every lifecycle exit/reap | Audit 4, driver and cached/idempotent production methods |
| 11 | SIGTERM-ignore/SIGKILL races | Audit 4 + SDK NSTask.h; direct-child reasoning, runtime-test limit explicit |
| 12 | Completion/cancel/continuation ordering | Audit 5 token lock and single owner; no fabricated late cancellation |
| 13 | Prelaunch cancellation challenge | F2 FACT, independently reproduced fake-only |
| 14 | Exact envelope/key/token/text/number | Audit 6 independent parser trace, strict table limits |
| 15 | Provider/detector/model/diagnostics | Audit 6 + provenance fixture and typed boundary |
| 16 | Data-only capability/disabled | Audit 7 + request/disabled source + contract tests |
| 17 | Inertness/forbidden product effects | Audit 7, zero reviewed-source delta |
| 18 | Test falsifiability | Causal regression/limits table above |
| 19 | Fresh validation/no real helper | Clean build + focused 24/24 + fake-only probe receipts |
| 20 | Read-only/guard/one return/no next | Pre-report tracked-byte diff empty; one finalizer return; protected authority preserved |

FACT: execution postflight completed on the unchanged reviewed candidate: git diff --check exit 0, tracked-byte delta empty, fresh HEAD/origin expected and 0/0; no untracked task artifacts in repo; unchanged accepted state/rule ledger/history. Audit result REPAIR is evidence, not BRAIN rejection/acceptance or repair authorization. No material audit question is hidden as unproven; authorized lack of real-child evidence is explicitly bounded above.
Finalizer closure is subsequent to this immutable capture: only this source, full CURRENT mirror, one pending Reviewer ledger row and one append-only worker_return event may change. Run canonical checker, commit allowlisted evidence, push/fetch and require clean 0/0; verify CURRENT/source and Desktop Operator/full CURRENT parity. Actual publication SHA and final closure outcome belong to Desktop's later Git receipt, never retroactively in this source.
PROPOSED_STATE_DELTA=REPAIR_EVIDENCE_FOR_F1_EXECUTABLE_TOCTOU_AND_F2_PRELAUNCH_CANCELLATION;BRAIN_TO_ADJUDICATE_BOUNDED_REPAIR;NO_ACCEPTED_STATE_MUTATION
