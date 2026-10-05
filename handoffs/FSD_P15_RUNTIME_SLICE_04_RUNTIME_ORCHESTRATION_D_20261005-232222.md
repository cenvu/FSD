# P15 Slice 04 explicit runtime orchestration

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_P15_RUNTIME_SLICE_04_RUNTIME_ORCHESTRATION_D_20261005-232222.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=a740fda1426dad0f4908b4faf7501cc53b56f8a2
REMOTE_HEAD=2da7434bccefcec5c13ce735e17cf337cb7ea844
LAST_VERIFIED_AT=2026-10-05T23:22:22+07:00
AUTHORITY_PTRS=AGENTS.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|STATE/PROJECT_STATE.md|docs/P15_RUNTIME_PLAN.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_P15_RUNTIME_SLICE_04_RUNTIME_ORCHESTRATION_022
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_WITHIN_SLICE04;BRAIN_ADJUDICATION_PENDING
PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_FSD_P15_SLICE_04_ADJUDICATION
NO_AUTO_NEXT=YES

## Task lock and Worker-local result

TASK_ID=FSD_P15_RUNTIME_SLICE_04_RUNTIME_ORCHESTRATION_022
ROLE=WORKER
MODE=BOUNDED_RUNTIME_ORCHESTRATION_IMPLEMENTATION
BASE_HEAD=2da7434bccefcec5c13ce735e17cf337cb7ea844
UPSTREAM_HEAD_AT_ADMISSION=2da7434bccefcec5c13ce735e17cf337cb7ea844
TECHNICAL_SHA=a740fda1426dad0f4908b4faf7501cc53b56f8a2
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=P15_SLICE04_ONLY;EXPLICIT_GLOBAL_SINGLE_FLIGHT_RUNTIME;FIVE_SECOND_INFERENCE_DEADLINE;CANCELLATION_GENERATIONS;SIX_OUTCOME_APPEND_MAPPING
ALLOWED_PATHS=FSD/Classification/ClassificationRuntimeService.swift|FSDTests/ClassificationRuntimeServiceTests.swift|FSD.xcodeproj/project.pbxproj|handoffs/FSD_P15_RUNTIME_SLICE_04_RUNTIME_ORCHESTRATION_D_20261005-232222.md|handoffs/CURRENT_HANDOFF.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl
DESKTOP_TRANSPORT=/Users/cenvu/Desktop/04_FSD_BRAIN.md
FORBIDDEN_PATHS=SCHEMA;MIGRATIONS;SNAPSHOT_WRITER_SCANNER;FILESYSTEM_DETECTOR;UI;APP_AUTOMATIC_TRIGGER;SEARCH_COMPARE_EXPORT;PRODUCT_DOCS;REAL_HELPER;DEPENDENCIES;SLICE05_PLUS;STATE/PROJECT_STATE.md;STATE/RULE_PROMOTION_LEDGER.tsv;PRIOR_HANDOFFS
SUCCESS_CRITERIA=CAUSAL_RUNNABLE_RED;ONE_SHARED_ACTOR;BUSY_NO_QUEUE;OWNED_CLEANUP_SLOT;FIVE_SECOND_INFERENCE_ONLY_TIMEOUT;STALE_NO_APPEND_OR_CURRENT_SUCCESS;EXACT_ROWS_AND_PROVENANCE;TYPED_DUPLICATE_FAILURE;PAYLOAD_AND_SOURCE_SAFETY;FRESH_BUILD_FOCUSED_FULL
VALIDATIONS=CLEAN_DEBUG_BUILD;FOCUSED_RUNTIME_AND_ENRICHMENT_XCTEST;FULL_DEBUG_XCTEST;BASELINE_BYTE_PROTECTION;GIT_DIFF_CHECK;FINALIZER_CHECKER_PUBLICATION_PARITY
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
WORKER_RESULT=PASS_WITH_ADVISORY
RESULT_AUTHORITY=WORKER_EVIDENCE_ONLY;NO_BRAIN_ACCEPTANCE

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=26
WORKER_REQUIREMENTS_EVIDENCED=26
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

SERVICE_ACTOR=PASS
GLOBAL_IN_FLIGHT_MAX=1
BUSY_IMMEDIATE=PASS
QUEUE=NONE
RETRY=NONE
TIMEOUT_SECONDS=5
TIMEOUT_SCOPE=INFERENCE_ONLY
TIMEOUT_CANCELS_PROVIDER=PASS
GENERATION_MONOTONIC=PASS
STALE_APPEND=NONE
STALE_SUCCESS_PUBLICATION=NONE
CANCEL_NO_ROW=PASS
UNAVAILABLE_NO_ROW=PASS
BUSY_NO_ROW=PASS
CLASSIFIED_ROW_COUNT=1
READER_FAILED_ROW_COUNT=1
PROVIDER_FAILED_ROW_COUNT=1
SOURCE_CHANGED_ROW_COUNT=1
UNSUPPORTED_ROW_COUNT=1
PROVENANCE_MAPPING=PASS
DUPLICATE_RUN_NO_RETRY=PASS
PAYLOAD_PERSISTENCE=NONE
PAYLOAD_HASH=NONE
PAYLOAD_LOG=NONE
PAYLOAD_ENCODED_COPY=NONE
SOURCE_CAPABILITY_DELTA=NONE
SNAPSHOT_MUTATION=NONE
ENTRY_FACT_MUTATION=NONE
UI_DELTA=NONE
AUTOMATIC_TRIGGER=NONE
REAL_HELPER=NONE
NETWORK=NONE_IN_PRODUCT
SLICE05_DELTA=NONE
FOCUSED=PASS
FULL_DEBUG=PASS

Advisory: three pre-existing external-fixture tests skipped because their inputs are absent. Prior Slice-03 real signing/packaging/integrity and persistent-descendant verification remain Slice-07 obligations, with no new real-helper claim. All Slice-04 automated tests executed and passed. No additional independent audit was started or claimed. BRAIN must adjudicate this Worker return before any next authorization.

## Reanchor and bounded authority

FACT: local main initially clean at d70739c21dd45ac013a4fd7e32ea8e439d18e0eb. Non-destructive git fetch origin revealed exactly the expected 2da7434bccefcec5c13ce735e17cf337cb7ea844. The complete three-file BRAIN authorization diff (PROJECT_STATE, ledger, events) was inspected before git pull --ff-only origin main. Fresh HEAD=origin/main=2da7434bccefcec5c13ce735e17cf337cb7ea844, ahead0/behind0, clean. Accepted STATE closes Slice-03 security and authorizes only task022. No reset/clean/stash/rebase/force or merge commit.

FACT: baseline captured before task mutation: 1454 tracked SHA-256 byte hashes (symlink target bytes for symlinks), 10396 ignored path names, no untracked Owner files and original Desktop transport. Baseline was never recaptured to absorb drift. Protected bytes and all prior historical handoffs remain unchanged. Prepublication technical capture is a740fda1426dad0f4908b4faf7501cc53b56f8a2, upstream 2da7434bccefcec5c13ce735e17cf337cb7ea844, ahead1/behind0, clean before reporting projection. Publication synchronization is a later closure check, not an invented receipt in this immutable source.

Read set: AGENTS; task-execution/finalizer skills; CURRENT HOT plus a small overread into its task lock/guard (first65 lines, no historical report preload); fresh accepted STATE; directly applicable Operator rules; canonical P15 Slice04; provider request/results/protocol; reader outcome/init/readPrefix including existing cancellation barriers; bundled classify cancellation/cleanup; classification repository input/append/duplicate validation; relevant existing enrichment tests. One bounded read-set expansion for the concurrency-ownership check inspected CatalogDatabase's @unchecked Sendable/NSRecursiveLock declarations: production reader/context run off the service actor, so shared catalog synchronization was physically confirmed. This small declaration read was beyond the listed files for an ownership check, rather than a demonstrated material contradiction; no adjacent implementation was loaded or changed. No unrelated long history, Slice02/03 handoffs, Slice05, or real Magika research loaded.

Research: Swift's official [Concurrency chapter](https://github.com/swiftlang/swift-book/blob/main/TSPL.docc/LanguageGuide/Concurrency.md) distinguishes structured child lifetime/cancellation from explicitly owned unstructured tasks. A structured race can retain its scope while a losing task ignores cancellation. The runtime therefore publishes through a one-shot continuation before awaiting losing-task cleanup, while retaining the active slot and task handles. Official documentation lookup only; no product network capability/dependency or Magika lookup. No model benchmark or delegate execution.

## Technical delta and ownership

Exactly three technical paths: new service (FSD/Classification/ClassificationRuntimeService.swift,328 lines), new tests (FSDTests/ClassificationRuntimeServiceTests.swift,814 lines), and eight Xcode object/group/source references for the two files. No existing reader/provider/repository/test/doc/build-setting mutation.

SERVICE_SHA256=ab8325651b4838e6cb7c9c1ed0b4e342c4b09933661ef3bc1e21a4e09f52aee5
TEST_SHA256=59b020fe04d8bee9aa90e842bcef56108d743811c04a612093c9b00cb094693c

FACT: the actor has one static shared instance and a private initializer (lines5–8). All callers and catalogs use that sole slot, rather than one independently admitted service per view or entry. Construction has no database/read/provider/task side effects. Production API is explicit start(entryID:database:provider:); internal per-run Dependencies support bounded tests without changing source/provider interfaces. No caller or UI integration was added. State is typed idle/running(identity)/terminal(completion); isActive separately exposes retained cleanup ownership. It holds one bounded result, no runtime history and no bytes/path/raw error/Process/Pipe. Invalid injected run IDs are rejected visibly before entering state, without replacement or source work; busy remains a separate control case and the provider enum still has exactly six cases.

FACT: successful admission guards active==nil, mints one ID (production UUID), increases generation, records identity and owns its Task (lines105–127). Busy returns before ID/context/source/provider/append work. One-shot publication uses active.published and clears the continuation before resuming. A cancelled caller's handler synchronously sets a lock-protected token and relays generation invalidation to the actor. This closes the cancellation-handler/actor-hop window before persistence. No MainActor blocking or UI dependencies were introduced.

FACT: the owned task composes context → reader → bounded request → provider → typed outcome → current/cancellation gate → optional append → publication (lines165–224,266–305). The source helper uses a detached owned Task and a cancellation handler that cancels that Task; existing reader Task.isCancelled checks remain before resolution/open/read, after open and after read. The service checks again after bounded read and before inference. Provider receives exactly the original LocalClassificationRequest, and no database/context/reader/resolver/path/URL/fd/callback. No additional Data allocation, payload encoding/hash/log/store or service-level payload copy is present.

### Slot and cleanup lifecycle

| Boundary | Returned result/current state | Slot ownership |
| --- | --- | --- |
| Admission | running(identity) | one owned task; another start busy immediately |
| Normal result/append | one typed completion/terminal metadata | retained until provider and deadline handles return |
| User cancel/invalidate before completion | cancelled/no row; current state idle | generation increments; run/source/provider/deadline cancelled; retained while unwinding |
| Five-second timeout | failed row/terminal failed if current and not user-cancelled | provider cancelled; timeout caller returns before a noncooperative loser; retained until loser/deadline cleanup returns |
| True cleanup boundary | terminal remains stable, or idle after cancellation | active cleared only after all owned work returns; a new explicit start can admit |
| Cancel after completed terminal | committed result/row/current terminal preserved | generation still increases; any already-pending cleanup can be cancelled again |

A provider that never cooperates can keep isActive=true/busy indefinitely, but cannot prevent the already-defined timeout result from returning and cannot allow another provider overlap. The contract requires cancellation-aware providers; the deliberately late fixture proves prompt publication plus strict retained ownership, not universal eventual cleanup of arbitrary hostile implementations. waitForCleanup observes the existing Task; it is no admission queue or retry mechanism.

### Linearization and stale work

FACT: cancel()/invalidate() increment generation and cancel active task handles (lines130–158). Any old generation fails isCurrent, cannot append and cannot publish current success/failure. Cancelling a running generation publishes its cancelled result directly from the current cancellation operation and sets idle; late old-generation tasks only drain and release their owned slot. They never replace the current state. Completed terminal results remain stable.

FACT: persistence/current completion linearizes in the synchronous mappedResult commit (lines266–295), guarded by active identity, generation, !published, Task cancellation and RuntimeCancellation's short authorization lock (lines313–328). Cancellation that owns the token before authorization prevents append. If commit authorization owns the short lock first, it seals cancellation ownership, releases the lock, then performs the synchronous append and publication; a later cancellation does not rewrite that result. There is no await from the final generation check through append and publication. Production append invokes the existing synchronous append-only repository, with no callback/reentrancy or asynchronous repository redesign. The actor's generation cannot change across that span, and caller Task cancellation is additionally serialized by the token. Post-append publication explicitly checks generation again (line303); no allowed post-append suspension window is introduced. No stale result can sneak through an earlier check made before source/provider awaits.

### Exact inference deadline and losing work

FACT: inferenceTimeout is exactly Duration.seconds(5), and production sleeps on ContinuousClock until inference handoff start advanced by that duration with zero requested tolerance (lines7,60–61,227–246). Source/context time is excluded. Five seconds is the deadline policy; no hard real-time OS scheduling precision is asserted. Deterministic tests inject the deadline operation, inspect the supplied duration and release it only after provider-entry synchronization. Provider and deadline events race through the actor's single continuation; clearing it before resume prevents double-result delivery. Deadline wins → cancel provider Task → .timeout → mapped provider .failed. Cancellation winning the generation/commit gate before persistence still returns cancelled and writes no row.

FACT: the bundled provider's existing withTaskCancellationHandler receives provider Task.cancel, then the audited operation terminates/closes/reaps before its own continuation returns. The service's provider Task is retained until that return. A fake runner holds the actual bundled classify cleanup at reap: timeout can return failed, while another start stays busy; release of reap permits slot release. No real Process child, custom helper executable, new probe program or process-tree technology was created.

## Six-outcome and repository mapping

| Typed outcome | Append | Provider provenance | Other metadata |
| --- | --- | --- | --- |
| classified(observation) | exactly one classified | actual providerIdentifier | all six observation fields preserved, including detector/model/classifiedAt; provider version properties never substituted |
| reader failed | exactly one failed | nil | detected/mime/confidence/detector/model/classifiedAt nil |
| provider failed / timeout after inference handoff | exactly one failed, only current and not user-cancelled | actual providerIdentifier | all other metadata nil |
| sourceChanged | exactly one failed; provider never called for reader outcome | nil | all other metadata nil |
| unsupportedEntry | exactly one failed; provider never called for reader outcome | nil | all other metadata nil |
| reader/provider unavailable | no row | no fabricated row | typed unavailable |
| reader/provider/user cancelled | no row | no fabricated row | typed cancelled |
| busy control | no row/run ID/source/provider call | no row | immediate, no queue |

Repository append errors become typed runtime failures: duplicateRun carries bounded entry/run identity, entryNotFound carries entry ID, invalidInput and storage carry no raw diagnostic. No duplicate overwrite/update/delete/retry or replacement ID. Context catalog errors also remain typed storage failures, rather than fake classification success or a fabricated failed row. Actual duplicate-run test writes one existing row, attempts the same injected ID once on the next admitted run, observes duplicateRun, retains one row and confirms exactly two total mint calls (one per run). Failed append is attempted once only.

## Test-first evidence and falsifiability

Causal RED preceded the new production service. A runnable, test-local MissingRuntime scaffold supplied symbols but deliberately lacked admission, stale gating and failed-row mapping. It was not a compiler/missing-symbol RED. Three eventual permanent behavior assertions executed: busy returned completed/read/minted instead; late cancelled success appended/published; reader failure wrote zero rows instead of one. Actual RED: 3 executed / 0 passed / 0 skipped / 3 failed tests, seven assertion failures; xcodebuild exit65. The scaffold was removed and the same assertion boundaries retargeted to the production shared actor. Reference-first receipt: /tmp/FSD-P15-Impl04-red-scaffold.swift and /tmp/FSD-P15-Impl04-red.log (local operational evidence, not extra tracked reports).

Setup/debug receipts: first test-only project wiring edit matched only up to the first internal semicolon, producing an invalid plist and xcodebuild exit74. The complete error/diff was inspected; one correction used complete physical anchor lines, plutil lint passed, and the runnable RED followed. Initial GREEN compiled production but rejected the injected throwing-continuation's uninferred generic type; full compiler error identified Void as missing, one explicit CheckedContinuation<Void, Error> annotation fixed the test seam. Initial implementation validation was green: initial focused GREEN32/32, then added bounded production-context/ID checks, clean build and focused35/35. Postflight then found the lock-spanning-append concern described below; final clean build/focused36/36/full428 validation followed that repair. Neither setup failure is counted as causal RED. A temporary Desktop formatter compile check also rejected a non-ASCII bytes literal before any write; the unchanged original packet was freshly confirmed, one Unicode-string encoding correction passed compile, and publication later uses that corrected formatter. No checker/immutable-history failure was absorbed or hidden.

| Permanent behavior/test | Deliberate ordering and regression caught |
| --- | --- |
| testSingleFlightBusyDoesNotQueueOrTouchDependencies | first provider held by actor gate before second start; second returns before release, no ID/read/row; catches independent/missing admission or queued work |
| testCancelledGenerationRejectsLateClassifiedAppendAndPublication | cancel first, then release noncooperative provider success; cancelled/zero rows/idle; catches stale append or current-success publication |
| testCancelledGenerationRejectsLateFailureAndRetainsBusyUntilCleanup | cancel first, late failure later; busy until release, new explicit start only after cleanup; catches stale failure row or premature slot release |
| testCancellationBeforeSourceResolutionDoesNotCallReader / testAlreadyCancelledCallerDoesNotResolveSource | cancellation precedes source gate or explicit API; no reader/provider/row |
| testCancellationDuringReaderPropagatesTaskCancellationAndHoldsSlot | invalidate first while reader held; reader observes Task.isCancelled; slot busy until reader returns |
| testCancellationAfterReadAndBeforeInference | afterRead and beforeInference gates; cancellation first means one bounded read/no inference/no row |
| testCancellationAfterInferenceAndImmediatelyBeforeAppend / caller Task variant | result produced then checkpoint held; service/caller cancellation first forbids append and current terminal success |
| testCommitAuthorizationDoesNotHoldCancellationLockAcrossAppend | commit authorization first, then caller cancellation during append; handler returns before append finishes, one row/terminal stable; catches lock held across DB work |
| testCompletionFirstStaysStableAfterCancelAndInvalidate | actual completion/one row first, then cancel/invalidate; generation increases and terminal/history remain stable |
| testTimeoutReturnsWhileLateProviderStillOwnsSlotAndCannotPublishSuccess | injected deadline first while loser blocked; timeout-return expectation fulfilled before loser release; exactly one failed row/provider ID, busy/no second ID/read; late success leaves result/state/row unchanged |
| testDeadlineStartsOnlyAfterReaderAndExactlyAtInferenceHandoff | reader held → no clock invocation; release reader → provider-entry synchronization → clock supplied exactly five seconds |
| testTimeoutThenUserCancelBeforeAppendWritesNoRow / testUserCancelBeforeDeadlineWinsNoFailedRow | both explicit winner schedules; user cancellation before persistence owns final cancelled/no row/idle even when timeout already occurred |
| testProviderCompletionBeforeDeadlineWinsExactlyOneClassifiedRow | provider completion first, late clock fire later; exactly one classified row remains |
| testBundledProviderTimeoutCancelsTerminatesClosesReapsBeforeSlotRelease | real bundled classify with fake active runner; deadline first, reap held; cleanup events terminate/close/reap, busy until actual classify unwind completes |
| testAllSixOutcomesAndExactObservationProvenance / reader-failure causal test | exact nine reader/provider cases, row counts/status/all metadata/properties independence, one mint each; catches wrong row/no-row mapping/provenance |
| testRealRepositoryDuplicateRunRemainsTypedNoRetryAndFactsImmutable | real SQLite append and duplicate; no retry/overwrite; valid classified and pre-provider failed rows leave snapshot/entry fingerprints unchanged |
| context/production-composition/error tests | production entry guard plus real audited reader unavailable, typed missing/storage/invalid failures, no raw error or second append; distinct production UUIDs and generations |
| testRuntimeStateAndCompletionContainNoPayloadOrSourceCapability | recursive reflection of actual state/completion/input excludes Data/request/URL; Data-only provider also receives only the request's data field |

Additional causal RED: testCommitAuthorizationDoesNotHoldCancellationLockAcrossAppend deliberately authorizes commit first, enters a synchronous injected append, then cancels the caller on another thread. The append waits for the cancellation handler to return. Under the initial lock-spanning-append code this created a dependency cycle; the bounded semaphore timed out and raised one real assertion failure (1 executed/0 passed/0 skipped/1 failed, exit65), safely allowing unwind. Root cause was NSLock held across repository work, which could block cancellation on MainActor or permit lock-order deadlock with an external catalog owner. One minimal repair seals commit authorization under the short lock and unlocks before invoking append. The test now proves the cancellation handler returns while append is still active and the authorization-first result stays classified with one row/current terminal state. Earlier cancel-first tests still prove zero rows. Reference: /tmp/FSD-P15-Impl04-commit-red.log. The initial full run was intentionally interrupted (exit75, TEST_INTERRUPTED; /tmp/FSD-P15-Impl04-full-initial-interrupted.log) to validate the corrected candidate; it supplies no full-suite PASS receipt. The final full run is fresh after the corrected clean build and focused run.

All race ordering uses continuations, actor gates, cancellation tokens, expectations, injected deadlines or a semaphore holding fake reap. Five-second XCTest timeouts detect missing progress; they do not produce winner ordering. No arbitrary sleeps. Fake append/runner tests prove calls/input/order, not universal real-artifact behavior; the real repository tests and unchanged existing process/source tests supply the directly composed production evidence. Tests are falsifiable evidence, not a claim that test-green alone universally proves concurrency or memory safety.

## Fresh validation

DerivedData path absent before first invocation: /tmp/FSD-P15-Impl04-DerivedData. No cache copied from prior tasks. After the commit-lock regression repair, all final required commands run against the final candidate:

```text
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-P15-Impl04-DerivedData clean build
EXIT=0; CLEAN_SUCCEEDED; BUILD_SUCCEEDED
LOG=/tmp/FSD-P15-Impl04-build.log

xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-P15-Impl04-DerivedData -only-testing:FSDTests/ClassificationRuntimeServiceTests -only-testing:FSDTests/ClassificationEnrichmentTests
EXIT=0; EXECUTED=36; PASSED=36; SKIPPED=0; FAILED=0
RUNTIME=26; ENRICHMENT=10
LOG=/tmp/FSD-P15-Impl04-focused.log
XCRESULT=/tmp/FSD-P15-Impl04-DerivedData/Logs/Test/Test-FSD-2026.10.05_22-37-39-+0700.xcresult

xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-P15-Impl04-DerivedData
EXIT=0; EXECUTED=428; PASSED=425; SKIPPED=3; FAILED=0
LOG=/tmp/FSD-P15-Impl04-full.log
XCRESULT=/tmp/FSD-P15-Impl04-DerivedData/Logs/Test/Test-FSD-2026.10.05_22-38-54-+0700.xcresult

git diff --check
EXIT=0
```

Full suite skips: FSDProbeSeedTests.testSeedIsolatedProbeCatalog (FSD_PROBE_CATALOG absent/no marker), FilesystemMatrixTests.testCaptureExternallyPreparedMountedFilesystem (FSD_MATRIX_SOURCE absent), FilesystemMatrixTests.testReopenCapturedSnapshotWithTheSourceDetached (FSD_MATRIX_OFFLINE_CATALOG absent). Existing signed-test-framework strip/AppIntents metadata/deployment-vs-XCTest linker warnings only; no new Swift concurrency or source compile warnings. Prior schema/source/process tests ran unchanged in this full suite; no separate independent audit was manufactured.

## Requirement/evidence map and execution postflight

Every row below is EVIDENCED on the reviewed execution candidate, not BRAIN acceptance or a future publication receipt.

| # | Requirement | Concrete evidence |
| --- | --- | --- |
| 1 | Authorized base/gate/scope | expected SHA fetched/fast-forwarded; fresh accepted STATE; preserved baseline |
| 2 | Runnable causal RED before production | three scaffold tests/seven behavioral assertion failures, exit65 |
| 3 | One app-scoped actor/inert explicit API | private init/shared actor; no call site/UI integration; construction test |
| 4 | Single-flight/immediate busy/no queue or retry | guard before mint; held-provider busy test; no dependency work |
| 5 | Active-slot lifecycle through cleanup | cancel/timeout held-loser busy; fake bundled reap held; new run after cleanup |
| 6 | One ID per admission/no replacement | injected mint counts, production distinct UUIDs, real duplicate failure |
| 7 | Locked pipeline order | context/readSource/produceOutcome/infer/mappedResult/publish sequence |
| 8 | Source cancellation before resolution/open/read/after read | runtime Task handler plus unchanged reader's physical barriers and full source tests |
| 9 | After read/before inference cancellation | two checkpoint schedules; no provider/row |
| 10 | Active inference cancellation | held provider/cancelled Task and existing bundled handler; zero rows |
| 11 | After inference/immediately preappend cancellation | service and caller-token checkpoint tests; short locked authorization followed by synchronous commit |
| 12 | Monotonic generation/stale success+failure rejected | start/cancel/invalidate increments; both late-result schedules, zero rows/idle |
| 13 | Completion-first stability/postappend guard | no suspension during commit/publish; completed-state test stable after later invalidation |
| 14 | Exactly five-second inference-only timeout | fixed Duration and absolute clock deadline; reader-held/clock-duration test |
| 15 | Timeout provider cancellation/terminate/close/reap | real bundled classify with deterministic fake active runner/reap gate |
| 16 | Timeout returns without losing-provider wait, keeps global slot | timeout expectation before loser release, busy until actual drain |
| 17 | Timeout failed row current/provenance/single append | held-loser timeout test exact failed input and actual provider identifier |
| 18 | Timeout late completion cannot rewrite/current-success/second row | state/row unchanged after release; continuation consumed once |
| 19 | User cancel vs timeout both orders | deadline-first preappend cancel and user-first deadline schedules, zero rows |
| 20 | Six outcomes and busy exact persistence | table-driven nine cases plus busy/cancellation tests; only four row-producing statuses |
| 21 | Observation/provider/pre-provider provenance | exact input fields; property versions excluded; failed metadata nil; source outcomes skip provider |
| 22 | Append-only typed repository errors/no duplicate retry | real duplicate and sanitized storage/invalid error tests; no existing repository mutation |
| 23 | Payload lifetime/bounded state/no hash/log/encode/copy | request scoped to read/inference, no Data allocation in service; reflection; source/state byte review |
| 24 | Source capabilities/snapshot-entry safety unchanged | existing source/provider/repository bytes equal base; request data-only; real immutable facts test |
| 25 | Clean Debug/focused/full/diff validation | fresh logs/xcresults/exits/counts above; skipped fixtures explicit |
| 26 | Forbidden scopes/Owner/accepted state/history/no auto-next protected | exact three technical paths; 1454 baseline hashes/10396 ignored names; no UI/helper/network/docs/Slice05/state decision |

FACT: execution postflight complete before handoff finalization. Product candidate is committed only at the known technical SHA above. Historical source, full CURRENT, pending-BRAIN ledger/event, exact Operator and full CURRENT Desktop are the normal closure projections. Canonical checker, commit/push/fetch clean0/0 and final parity remain separate closure checks at source creation time; their actual subsequent receipts belong in Desktop/terminal, not this immutable file's future self-SHA. Publication will be resolved with git log -1 --format=%H -- this path. No bookkeeping self-reference commit or historical rewrite.

## Ownership, limits and return

BRAIN accepted STATE and RULE_PROMOTION_LEDGER remain untouched. One Worker ledger row/event proposes the Slice04 result and leaves BRAIN_CLASSIFICATION=PENDING_BRAIN. All prior historical handoffs are immutable. Product docs are unchanged. Slice07 trust-root/signing/process-tree obligations remain approved prior caveats, not new runtime capabilities or closure claims. No real helper, custom external process, automatic classification, UI, retry, queue, dependency or Slice05 work.

The service's synchronous commit boundary deliberately admits no asynchronous append race window. Future API changes must preserve that gate and retained losing-task ownership. An arbitrary provider that ignores cancellation forever leaves the service busy forever after timeout publication; this preserves the locked one-global-in-flight invariant while making no eventual-cleanup promise beyond the provider contract. Tests include a late noncooperative provider and actual bundled cancellation cleanup seam.

PROPOSED_STATE_DELTA=ADJUDICATE_SLICE04_AUTOMATED_GATE_EVIDENCE;NO_WORKER_ACCEPTANCE_OR_NEXT_AUTHORIZATION
