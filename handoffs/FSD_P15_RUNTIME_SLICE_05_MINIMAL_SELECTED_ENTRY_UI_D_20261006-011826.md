# P15 Slice 05 minimal selected-entry UI

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_P15_RUNTIME_SLICE_05_MINIMAL_SELECTED_ENTRY_UI_D_20261006-011826.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=11655156b78cc1a3acd07c40a0a9a4ac82fb400f
REMOTE_HEAD=0bffe9bf1837d78065cd036fab202d1125f6ffc9
LAST_VERIFIED_AT=2026-10-06T01:18:26+07:00
AUTHORITY_PTRS=AGENTS.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|STATE/PROJECT_STATE.md|docs/P15_RUNTIME_PLAN.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_P15_RUNTIME_SLICE_05_MINIMAL_SELECTED_ENTRY_UI_023
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_WITHIN_SLICE05;BRAIN_ADJUDICATION_PENDING
PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_FSD_P15_SLICE_05_ADJUDICATION
NO_AUTO_NEXT=YES

## Task lock and Worker-local result

TASK_ID=FSD_P15_RUNTIME_SLICE_05_MINIMAL_SELECTED_ENTRY_UI_023
ROLE=WORKER
MODE=BOUNDED_SELECTED_ENTRY_UI_IMPLEMENTATION
BASE_HEAD=0bffe9bf1837d78065cd036fab202d1125f6ffc9
UPSTREAM_HEAD_AT_ADMISSION=0bffe9bf1837d78065cd036fab202d1125f6ffc9
TECHNICAL_SHA=11655156b78cc1a3acd07c40a0a9a4ac82fb400f
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=P15_SLICE05_ONLY;ONE_SHARED_RUNTIME;EXPLICIT_SELECTED_ACTION;DELAYED_PROGRESS_CANCEL;STALE_SUPPRESSION;TRUTHFUL_WORDING
ALLOWED_PATHS=FSD/App/FSDApp.swift|FSD/UI/SnapshotBrowserView.swift|FSD.xcodeproj/project.pbxproj|FSDTests/SnapshotBrowserClassificationTests.swift|handoffs/FSD_P15_RUNTIME_SLICE_05_MINIMAL_SELECTED_ENTRY_UI_D_20261006-011826.md|handoffs/CURRENT_HANDOFF.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl
DESKTOP_TRANSPORT=/Users/cenvu/Desktop/04_FSD_BRAIN.md
FORBIDDEN_PATHS=SCHEMA;MIGRATIONS;REPOSITORY_SEMANTICS;SOURCE_READER;PROVIDER_PROCESS;CAPTURE_SCANNER;SEARCH_COMPARE_EXPORT_PRODUCTION;REAL_HELPER;DEPENDENCIES;NETWORK;PRODUCT_DOCS;SLICE06_PLUS;STATE/PROJECT_STATE.md;STATE/RULE_PROMOTION_LEDGER.tsv;PRIOR_HANDOFFS
SUCCESS_CRITERIA=CAUSAL_RUNNABLE_RED;SHARED_RUNTIME_COUNT_1;EXPLICIT_ACTION_ONLY;BUSY_NO_QUEUE_RETRY;HALF_SECOND_DELAY;STALE_UI_NONE;SELECTED_REFRESH_ONLY;TRUTHFUL_4096_WORDING;FRESH_BUILD_FOCUSED_FULL
VALIDATIONS=CLEAN_DEBUG_BUILD;FOCUSED_CLASSIFICATION_XCTEST;FULL_DEBUG_XCTEST;GIT_DIFF_CHECK;FINALIZER_CHECKER_PUBLICATION_PARITY
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
WORKER_RESULT=PASS
RESULT_AUTHORITY=WORKER_EVIDENCE_ONLY;NO_BRAIN_ACCEPTANCE

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=32
WORKER_REQUIREMENTS_EVIDENCED=30
WORKER_REQUIREMENTS_NOT_APPLICABLE=2
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

APP_SCOPED_RUNTIME_COUNT=1
EXPLICIT_SELECTED_ACTION=PASS
OPEN_AUTO_CLASSIFY=NONE
SELECT_AUTO_CLASSIFY=NONE
SEARCH_AUTO_CLASSIFY=NONE
COMPARE_AUTO_CLASSIFY=NONE
EXPORT_AUTO_CLASSIFY=NONE
BUSY_REPEAT_DISABLED=PASS
QUEUE=NONE
RETRY=NONE
PROGRESS_DELAY_SECONDS=0.5
FAST_PROGRESS_FLASH=NONE
CANCEL_ACTION=PASS
SELECTION_STALE_UI=NONE
SNAPSHOT_STALE_UI=NONE
BROWSER_REPLACEMENT_STALE_UI=NONE
SELECTED_DETAILS_REFRESH_ONLY=PASS
ABSENCE_NEUTRAL=PASS
CONFIDENCE_CONDITIONAL=PASS
RAW_DIAGNOSTIC_VISIBLE=NONE
PRIVATE_PATH_VISIBLE=NONE
CURRENT_SOURCE_WORDING=PASS
MAX_SAMPLE_WORDING=4096
HISTORICAL_CONTENT_VERIFICATION_CLAIM=NONE
RUNTIME_SEMANTICS_DELTA=NONE
SOURCE_CAPABILITY_DELTA=NONE
SCHEMA_DELTA=NONE
BULK_CLASSIFICATION=NONE
AUTOMATIC_TRIGGER=NONE
REAL_HELPER=NONE
NETWORK=NONE
SLICE06_DELTA=NONE
MANUAL_UI_ACCEPTANCE=DEFERRED_BY_OWNER
VOICEOVER_MANUAL_ACCEPTANCE=DEFERRED_BY_OWNER
FOCUSED=PASS
FULL_DEBUG=PASS

No separate independent audit is required before Slice 06 when build/focused/full pass and UI remains within the locked contract. Manual appearance/VoiceOver acceptance remains deferred by Owner. BRAIN must adjudicate this Worker return before any next authorization.

## Reanchor and bounded authority

FACT: local main was clean at 0bffe9bf1837d78065cd036fab202d1125f6ffc9, exactly the task EXPECTED_CANONICAL_HEAD. Non-destructive fetch revealed origin/main already at that SHA (local had lagged 3 BRAIN commits behind before pull: accept Slice04, classify Slice04, authorize Slice05). Inspected the 3-commit BRAIN diff (PROJECT_STATE/ledger/events only) before `git pull --ff-only origin main`. Fresh HEAD=origin/main=0bffe9b, ahead0/behind0, clean. Accepted STATE authorizes only task023 with Slice04 accepted. No reset/clean/stash/rebase/force or merge commit. Baseline was never recaptured to absorb drift.

Read set: AGENTS; task-execution skill; CURRENT HOT plus task lock/guard; fresh accepted STATE; P15 Slice05 plan (purpose/prerequisites/locked decisions/files/steps); SnapshotBrowserModel/SnapshotBrowserView/ApplicationModel; ClassificationRuntimeService API ranges (Identity/Result/Completion/StartResult/State, start/entryID/database/provider, start/dependencies, cancel/invalidate, isActive/waitForCleanup, generation/state); BundledMagikaClassificationProvider construction/classify/providerIdentifier; EntryClassificationRepository status/display/provenance; ClassificationEnrichmentTests; RuntimeServiceTests gates/probes/deadlines; TestSupport synthetic fixtures; CatalogLocation test-host isolation; SnapshotHistoryRepository summary type. No historical Slice02/03 handoffs, no Slice06, no Magika research loaded. No MCP use.

## Technical delta and ownership

Exactly four technical paths: FSD/App/FSDApp.swift (+11/-2), FSD/UI/SnapshotBrowserView.swift (+223/-13 across model/control/text/UI), FSD.xcodeproj/project.pbxproj (6 lines: build/file/group wiring for the one new test file), FSDTests/SnapshotBrowserClassificationTests.swift (new, 624 lines, 25 tests). No SnapshotTreeDataSource change, no ClassificationRuntimeService change, no schema/migration/repository/reader/provider-process/capture/search/compare/export/doc/helper change.

MODEL_SHA256=fea784523c9d4dbc1470190ba8ed2f1abad3dda249d539d980c4a82a393e4cc2
TEST_LINES=624; MODEL_LINES=672; APP_LINES=450

FACT: ApplicationModel owns `let classificationRuntime: ClassificationRuntimeService = .shared` (FSDApp.swift:64). No `ClassificationRuntimeService()` construction exists in production outside the service's own shared definition. openSnapshot cancels the old browser via `cancelClassificationForSnapshotClose()` before replacing, then creates `SnapshotBrowserModel(database:summary:runtime:classificationRuntime)`; closeSnapshot cancels before niling. Construction/launch/history/snapshot/browser/selection/expansion/search/compare/export/probe never call start.

FACT: SnapshotBrowserModel receives the same runtime capability explicitly (`runtime:` init param, default `.shared`; stored as `classificationRuntime`). Test seams are model-only: optional `SelectedEntryClassificationControl` (start/cancel closures), `progressDelay` sleeper (production `.milliseconds(500)`), optional `classificationDetailsLoader` for refresh observation. Production control wraps the shared runtime with `BundledMagikaClassificationProvider()` and maps StartResult to six UI outcomes; it creates no second runtime and broadens no runtime API. `productionStart` is the only production caller of `runtime.start`.

FACT: selection/snapshot/browser lifecycle uses a model-local monotonically increasing `classificationOperation` generation. `select()` increments, fire-and-forget cancels, resets to idle with nil message, then loads new details. `cancelClassificationForSnapshotClose()` increments, cancels, idles with nil message (no user-facing cancelled text on new selection/browser). Explicit `cancelClassification()` increments, cancels, idles with bounded cancelled text. Delayed progress captures (operation, entryID) and only transitions `runningBeforeProgress` to `runningWithProgress` when operation/phase/selection still match. `classifySelectedFile()` guards nil selection and non-idle phase (repeat disabled, no second start), then after `await control.start` rechecks operation/selection before any UI mutation or details refresh. Stale completions return without touching selectedDetails, phase, message or inspector.

### Lifecycle truth table

| Boundary | Control/runtime call | UI mutation |
| --- | --- | --- |
| Explicit Classify selected file | exactly one `control.start(entryID)` for current selection | busy immediately (`runningBeforeProgress`), message nil |
| 0.5 s elapses, same operation still running | none (injected sleeper resolves) | `runningWithProgress` + Cancel appears |
| Fast completion before 0.5 s | start returns | idle, no flash; stale sleeper suppressed |
| Explicit Cancel (only with progress) | exactly one `control.cancel()` + operation invalidation | idle + cancelled message, no row, late completion suppressed |
| Selection change | operation +1, `control.cancel()`, idle, message nil | new details load; old completion suppressed |
| Snapshot close / browser replace | old `cancelClassificationForSnapshotClose()` before new browser | old completion cannot alter new inspector |
| Global busy (retained cleanup or concurrent) | start returns `.busy` immediately | idle + busy message, no queue/retry/auto-start |

FACT: the service remains the global single-flight authority. The model disables repeat while locally running and maps `.busy` to bounded text with no follow-up action. `waitForCleanup`/`isActive` are not polled; the retained slot is observed only through the authoritative `.busy` result on the next explicit press, which never auto-starts. No queue, retry, bulk, backfill, watcher or background trigger exists in production (grep for bulk/backfill/watcher/classifyAll/automatic returns none in App/Browser files).

### Result to UI mapping

| Runtime/UI outcome | Row | Refresh | Message |
| --- | --- | --- | --- |
| classified + persisted row | 1 classified | exactly `classificationDetails(for: selectedEntryID)` once | nil (inspector shows stored row) |
| failed / sourceChanged / unsupported + persisted failed row | 1 failed, nil provenance except provider-ran failed | exactly once | nil (bounded status text via stored row) |
| unavailable | none | zero | Classification unavailable. |
| cancelled (explicit current) | none | zero | Classification cancelled. |
| busy | none | zero | Classification busy. Try again. |
| repositoryFailure / rejected | none (typed) | zero | Classification failed to save. |

No sample Data, source path/URL/handle, Process/Pipe, raw Error, stderr, stack, detector/model fabrication or provider diagnostics enter model state or visible text. Model state is exactly `selectedEntryID`, `classificationPhase` (idle/runningBeforeProgress/runningWithProgress), `classificationMessage` (bounded optional) plus the inert operation counter. No history list.

### Truthful inspector wording

Old blanket `FSD never read this file's contents` is absent from production (grep returns none). New disclaimer constant: `Snapshot metadata is not byte proof. Optional classification may sample at most the first 4096 bytes of the currently attached source; it does not verify historical content.` It preserves snapshot-metadata-not-byte-proof, 4096-byte maximum, currently-attached-source and inferred/not-historical-verification meaning. `Content Not Verified` footer semantics intact. Absence is neutral `Not classified.` Confidence renders only when `confidenceLabel` non-nil. Failed rows show bounded `Classification unavailable` status only.

## Test-first evidence and falsifiability

Causal RED preceded GREEN on the final API (not missing symbols). A temporary RED stub started hardcoded 9999, flashed `runningWithProgress` immediately and refreshed without generation guards. Three permanent-behavior assertions executed and failed for the intended reasons; xcodebuild TEST FAILED:

```text
testREDExplicitActionStartsSelectedEntry: [9999] != [2], must start exactly selected entry
testREDProgressDelayedHalfSecond: runningWithProgress != runningBeforeProgress, must stay hidden before 0.5 s
testREDStaleCompletionDoesNotRefreshNewSelection: [9999] != [2], only A may start (no suppression)
Executed 3 tests, 3 failures, exit non-zero
```

The stub was replaced by the bounded GREEN implementation; the same boundaries now pass as permanent tests (explicit selected entry, stale suppression, delayed progress) plus the full 25-test matrix. All ordering uses continuations, actor gates (`ClassificationTestGate.wait/waitUntilEntered/release`), expectations and injected delay. No arbitrary sleeps. Wording absence/confidence/no-raw checks assert the `ClassificationUIText` constants and the production view source (explicit action present, 4096 wording present, old blanket absent); text-presence is valid because the text itself is the contract.

| Permanent behavior/test | Deliberate ordering and regression caught |
| --- | --- |
| testAppOwnsOneSharedRuntime / testOpeningReplacingBrowserUsesSameRuntime / testBrowserDefaultRuntimeIsShared | app/browsers `===` shared; replacement passes same instance; catches per-browser runtime |
| testConstructionOpenSelectSearchDetailsDoNotStart | construction/open/select/details/search/export paths record zero starts and zero rows |
| testExplicitActionStartsExactlySelectedEntry / testNoSelectionNoStart | one start for selected ID; nil selection never starts |
| testRepeatWhileLocallyRunningDisabled | first held by gate, repeats while running add no starts |
| testBusyShowsMessageNoQueueNoAutoStart | fake busy yields message, zero refresh, no second start after yield |
| testFastCompletionNeverFlashesProgress | completes before delay release, stale delay release causes no flash |
| testProgressAppearsAfterHalfSecondWhileRunning | hidden before release, visible after same-operation delay release, hidden after completion |
| testStaleDelayAfterSelectionChangeDoesNotMutate | selection during held start invalidates; old delay release causes no mutation |
| testExplicitCancelCallsRuntimeOnceAndSuppressesLateCompletion | cancel after progress calls once, hides progress, late classified release causes no refresh |
| testLifecycleCancelShowsNoMessage | lifecycle cancel idles with nil message |
| testSelectionChangeCancelsAndSuppressesStale | select B during held A cancels A; A release cannot refresh B |
| testSnapshotCloseCancelsInvalidates / testBrowserReplacementOldCompletionCannotAlterNew | close/replace cancel; old release cannot alter new browser |
| testClassifiedPersistedRefreshesSelectedDetailsOnce | canned classified row refreshes exactly once and surfaces stored values |
| testFailedPersistedRefreshesBoundedStatus | canned failed row refreshes once, bounded status, nil confidence |
| testUnavailable/Cancelled/Busy/RepositoryFailure mapping | zero refresh (except persisted), bounded messages, no raw tokens |
| testWordingAbsenceConfidenceAndNoRaw / testProductionInspectorSourceHasNoBlanketWording | absence/disclaimer/confidence/no-path assertions plus view-source presence/absence |
| testSearchCompareExportDoNotInvokeProvider | open/select/details/search/export + engine isolation produce zero starts/rows |
| testProductionProviderConstructionIsInertAndUnavailableWithoutHelper | Bundled construction inert; real shared-runtime start returns unavailable with zero rows (no simulated success) |

## Fresh validation

Fresh DerivedData: /tmp/FSD-P15-Impl05-DerivedData (removed before clean build; no cache from prior slices).

```text
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-P15-Impl05-DerivedData clean build
BUILD SUCCEEDED

xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-P15-Impl05-DerivedData -only-testing:FSDTests/SnapshotBrowserClassificationTests -only-testing:FSDTests/ClassificationEnrichmentTests
EXECUTED=35; PASSED=35; SKIPPED=0; FAILED=0 (25 new + 10 enrichment)
TEST SUCCEEDED

xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-P15-Impl05-DerivedData
EXECUTED=453; PASSED=450; SKIPPED=3; FAILED=0
TEST SUCCEEDED
LOG=/tmp/FSD-P15-Impl05-full.log
```

Full-suite skips (3, pre-existing external fixtures): FSDProbeSeedTests.testSeedIsolatedProbeCatalog (FSD_PROBE_CATALOG absent), FilesystemMatrixTests.testCaptureExternallyPreparedMountedFilesystem (FSD_MATRIX_SOURCE absent), FilesystemMatrixTests.testReopenCapturedSnapshotWithTheSourceDetached (FSD_MATRIX_OFFLINE_CATALOG absent). No new warnings beyond existing signed-test-framework strip/AppIntents/linker notes.

```text
git diff --check
EXIT=0
```

Changed paths are exactly the four technical paths above (three modified + one new test). No ClassificationRuntimeService, SnapshotTreeDataSource, schema, repository, reader, provider-process, capture, search/compare/export production, docs, helper, dependency or Slice06 delta. Checker/publication parity are closure checks; their receipts belong in Desktop/terminal, not this immutable self-SHA record.

## Requirement/evidence map and execution postflight

1. App-scoped runtime count 1 — EVIDENCED (shared identity tests + grep no direct init).
2. Explicit injection without second runtime — EVIDENCED (openSnapshot passes runtime; replacement identity test).
3. Inert construction/launch/history/open/reopen/browser/selection/expansion/search/compare/export/probe — EVIDENCED (zero-start test + exporter/row counts).
4. Only Classify selected file may start; no auto inference/launch work — EVIDENCED (explicit tests + inertness).
5. Action exists/enables only when selected — EVIDENCED (canClassify/canonical button gated on selectedEntryID; no-selection test).
6. No file-kind/source pre-decision in UI — EVIDENCED (model passes entryID through; runtime/reader authoritative by unchanged code).
7. No bulk/destination/batch — EVIDENCED (single button grep; no bulk symbols).
8. Bundled provider inert; unavailable without helper; no fake success — EVIDENCED (construction + real-runtime unavailable test).
9. Selection change invalidates/cancels old — EVIDENCED (selection stale test + cancel counts).
10. Snapshot close cancels/invalidates — EVIDENCED (close test).
11. Browser replacement cancels old before new current — EVIDENCED (replacement test + ApplicationModel cancel-before-replace).
12. Model-local generation suppresses old entry/snapshot/browser/operation completions — EVIDENCED (stale/delay/busy tests).
13. Global single-flight busy with disabled repeat, no queue/retry — EVIDENCED (repeat + busy tests).
14. Delayed 0.5 s progress only for same running operation — EVIDENCED (before/after delay tests; production milliseconds(500)).
15. Fast completion never flashes — EVIDENCED (fast test + stale delay release).
16. Stale delayed callback never mutates — EVIDENCED (stale delay + selection tests).
17. Cancel only with delayed progress; calls runtime cancel once; cancelled message; no row; late completion suppressed — EVIDENCED (explicit cancel test).
18. Lifecycle cancel shows no message — EVIDENCED (lifecycle test).
19. Bounded typed UI state (idle/before/with + message); no Data/path/Process/Error/stderr/history — EVIDENCED (code + forbidden-storage grep).
20. Classified persisted refreshes exactly selected details — EVIDENCED (refresh-once test).
21. Failed/sourceChanged/unsupported persisted refresh bounded failed status — EVIDENCED (failed test; all three map to failedPersisted with nil provenance by productionStart).
22. Unavailable/busy/cancelled/repositoryFailure bounded messages with zero refresh from nonexistent rows — EVIDENCED (mapping tests).
23. Repository failure generic only; no raw DB error/run ID/path — EVIDENCED (token absence assertions).
24. Selected-details-only refresh; no tree/snapshot/history reload — EVIDENCED (classificationDetails(for:) single-entry path; instrumentation counts).
25. Truthful current-source/4096/inferred-not-historical wording; old blanket absent; Content Not Verified intact — EVIDENCED (wording + view-source tests + grep).
26. Absence neutral; confidence conditional; no fake detector/model/provider — EVIDENCED (wording tests; inspector shows dash when absent).
27. Accessibility textual labels; progress/cancel combinable label — EVIDENCED (button/ProgressView/Cancel + accessibility label).
28. Runtime/source/schema semantics unchanged — EVIDENCED (diff --name-only excludes those paths).
29. No bulk/automatic/real-helper/network/Slice06 — EVIDENCED (diff + symbol greps).
30. Fresh clean build + focused + full + diff --check — EVIDENCED (receipts above).
31. Manual UI acceptance deferred — NOT_APPLICABLE (deferred by Owner; no visual pass claimed).
32. VoiceOver manual acceptance deferred — NOT_APPLICABLE (deferred by Owner; no VoiceOver pass claimed).

FACT: execution postflight complete before finalization. Candidate is the technical SHA above. Historical source, full CURRENT, pending-BRAIN ledger/event, exact Operator and full CURRENT Desktop are the normal closure projections. Checker, commit/push/fetch clean0/0 and final parity are closure checks; actual receipts belong in Desktop/terminal. Publication SHA resolved via git log after commit; no self-referential bookkeeping commit.

Setup/validation receipt: the first canonical checker invocation returned FAIL `handoff requires exactly one Worker proposal` because this new handoff carried a duplicated `PROPOSED_NEXT=` metadata line in its closing block in addition to the single HOT instance; the next run then returned FAIL `missing/duplicate Worker guard field: NEXT_TASK_STARTED` for a duplicated trailing `NEXT_TASK_STARTED=NO` outside the guard block. Both were pure metadata/format duplicates in this new, still-unpublished handoff, removed in corrective commits that changed no claim, evidence, count, result or guard value; the prior Slice-04 handoff confirms the canonical single-instance shape for both fields. Earlier checker attempts in the same closure sequence failed on my own invocation arguments (`--expect-origin origin/main` instead of the origin URL, then a stale FETCH_HEAD receipt after the initial long full-suite run); both were corrected by re-reading the checker contract and a fresh non-destructive fetch, with no allowlist widening. No product, test, schema or historical-handoff bytes changed.

## Ownership, limits and return

STATE/PROJECT_STATE.md and RULE_PROMOTION_LEDGER.tsv untouched. One Worker ledger row/event proposes Slice05 and leaves BRAIN_CLASSIFICATION=PENDING_BRAIN. All prior handoffs immutable. Product docs unchanged. Slice06, real helper, Slice07 signing/process-tree and network remain out of scope. No queue/retry/backfill/watcher/automatic/bulk work.

PROPOSED_STATE_DELTA=ADJUDICATE_SLICE05_AUTOMATED_GATE_EVIDENCE;NO_WORKER_ACCEPTANCE_OR_NEXT_AUTHORIZATION
