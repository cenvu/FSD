# ADR-034 noMatch runtime repair

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_CLASSIFIER_NOMATCH_RUNTIME_REPAIR_D_20261006-192830.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=6ea54eb0aa40f5c4ab04f4ca3b039eeccf9afbb8
REMOTE_HEAD=8677dcdd287e305fdd043bd5f5263578d6f06d41
LAST_VERIFIED_AT=2026-10-06T19:28:30+07:00
AUTHORITY_PTRS=AGENTS.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|STATE/PROJECT_STATE.md|docs/DECISIONS.md|docs/ARCHITECTURE.md|docs/P15_RUNTIME_PLAN.md|docs/TEST_PLAN.md|docs/UX_UI_SPEC.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_CLASSIFIER_NOMATCH_RUNTIME_REPAIR_031
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE
PROPOSED_NEXT=FSD_CLASSIFIER_NATIVE_FEASIBILITY_SPIKE_029R
NO_AUTO_NEXT=YES

## Task lock and result

TASK_ID=FSD_CLASSIFIER_NOMATCH_RUNTIME_REPAIR_031
ROLE=WORKER
MODE=BOUNDED_ADR034_RUNTIME_IMPLEMENTATION
BASE_HEAD=8677dcdd287e305fdd043bd5f5263578d6f06d41
UPSTREAM_HEAD=8677dcdd287e305fdd043bd5f5263578d6f06d41
EXPECTED_CANONICAL_HEAD=8677dcdd287e305fdd043bd5f5263578d6f06d41
TASK030_PUBLICATION=ca90122d1f30a295517d40783dc9f149b1011111
TECHNICAL_SHA=6ea54eb0aa40f5c4ab04f4ca3b039eeccf9afbb8
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=ADR034_ENUM_HELPER_PARSER_RUNTIME_NO_ROW_SELECTED_ENTRY_UI_PERMANENT_DETERMINISTIC_TESTS
ALLOWED_PATHS=FSD/Classification/LocalFileClassificationProvider.swift|FSD/Classification/BundledMagikaClassificationProvider.swift|FSD/Classification/ClassificationRuntimeService.swift|FSD/UI/SnapshotBrowserView.swift|FSDTests/ClassificationProviderContractTests.swift|FSDTests/BundledMagikaClassificationProviderTests.swift|FSDTests/ClassificationRuntimeServiceTests.swift|FSDTests/SnapshotBrowserClassificationTests.swift|handoffs/FSD_CLASSIFIER_NOMATCH_RUNTIME_REPAIR_D_20261006-192830.md|handoffs/CURRENT_HANDOFF.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl
FORBIDDEN_PATHS=ALL_OTHER_REPO_PATHS;SCHEMA_MIGRATIONS_STORAGE_FORMAT;SOURCE_READER_SEMANTICS;APP_OWNERSHIP;SEARCH_COMPARE_EXPORT_CAPTURE;DOCS_ADR_PRD_PRODUCT_STATE;STATE/PROJECT_STATE.md;STATE/RULE_PROMOTION_LEDGER.tsv;HISTORICAL_HANDOFFS;DEPENDENCIES_VENDOR_MODELS_HELPERS_FILETYPE_GO;PROVIDER_INTEGRATION;TASK029_RETRY;SLICE08
SUCCESS_CRITERIA=SEVEN_TYPED_RESULTS;WIRE_no_match_NULL_METADATA;PROVIDER_RAN_TRUE;APPEND0_ROWS0_PROVENANCE_NONE;EMPTY_INPUT_VALID;STALE_AND_CANCEL_SUPPRESSION;NEUTRAL_CURRENT_UI_REFRESH0;ALL_EXISTING_BOUNDARIES_PRESERVED
VALIDATIONS=CAUSAL_BEHAVIORAL_RED;FRESH_DERIVEDDATA_CLEAN_DEBUG_BUILD;FOCUSED_FOUR_SUITES;FULL_DEBUG;GIT_DIFF_CHECK;EXACT_SCOPE_PROTECTED_BYTES;FINALIZER_CHECKER_DESKTOP_PUSH_FETCH
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
RESULT=PASS
RESULT_AUTHORITY=WORKER_EVIDENCE_ONLY_PENDING_BRAIN

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=33
WORKER_REQUIREMENTS_EVIDENCED=33
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

The guard accounts for the 33 execution requirements below. Finalizer mechanical
closure checks run after this immutable source is created; their actual receipt
belongs in Desktop transport and final return. This source does not assert a
future publication SHA or claim an unexecuted checker as passed.

## Exact implementation delta

FACT: eight authorized Swift paths, 243 insertions and 11 deletions; four
production paths and four existing test paths. Production adds one payloadless
provider case, one wire token, one no-row switch member and one current-action
UI outcome/message. The UI's existing runtime-result mapping is extracted into
a pure internal method used by productionStart and its deterministic regression.

- LocalClassificationProviderResult.noMatch means a successful provider operation
  with no recognized type. Disabled provider remains unavailable. No request or
  protocol capability changes.
- Helper schemaVersion remains the exact integer 1, seven envelope fields. The
  recognized result kinds are classified/no_match/unavailable/failed. Existing
  nonclassified all-null enforcement rejects metadata in every no_match field.
  Unknown/malformed/oversize/version-invalid output stays failed. Runner,
  process resolution, stdin/caps/cancellation/launch/terminate/close/reap and
  host-owned providerIdentifier code are unchanged.
- Runtime's only production line change adds noMatch to input=nil. The unchanged
  inference result path returns (result,true), so providerRan is true. Completion
  is classification(noMatch,nil), append count zero and real row delta zero.
  No provenance or type is constructed for noMatch. Generation/active ownership,
  race deadlines, cancellation locks, commit authorization, append ordering,
  stale suppression and single-flight control remain unchanged.
- SelectedEntryClassificationResult.noMatch maps from the production provider
  result and returns the current action to idle with "No file type recognized."
  It does not refresh or replace selectedDetails. Persistent absence remains
  "Not classified." Selection/snapshot/browser generation guards are unchanged.
- Permanent tests prove seven closed enum cases and no associated noMatch value;
  exact parser success; all five metadata rejections; unknown kinds and required
  classified type; real-repository zero row/append/provenance and empty input;
  blocked late noMatch after invalidation; caller cancellation before noMatch
  completion; timeout stability despite late noMatch; production UI mapping,
  neutral current action, full selected-details preservation and stale entry A
  completion suppression after selecting B. No arbitrary sleeps were added.
  Existing source inspection assertions and race tests were not weakened.

## Requirement and evidence map

| ID | Requirement | Status | Evidence |
|---|---|---|---|
| R01 | Canonical identity and task authority | EVIDENCED (FACT) | Fetch + clean fast-forward ca90122 → 8677dcdd287e305fdd043bd5f5263578d6f06d41; main; accepted gate031; ADR034/direct noMatch contract read. |
| R02 | Exactly seven closed results, busy excluded, payloadless noMatch | EVIDENCED (FACT) | ClassificationProviderContractTests.testResultVocabularyIsExactlyTheSevenLockedCases exhaustively maps all seven with no default; testNoMatchHasNoPayloadPathOrDiagnostic checks zero associated children. |
| R03 | Byte-only capability surface and 4096 ceiling | EVIDENCED (FACT) | Existing request reflection, hostile provider and ceiling tests unchanged and passing. |
| R04 | Disabled provider remains unavailable | EVIDENCED (FACT) | Existing testDisabledProviderIsSideEffectFreeAndReturnsUnavailable unchanged and passing. |
| R05 | Valid schema1 seven-field all-null no_match maps exactly noMatch | EVIDENCED (FACT) | BundledMagikaClassificationProviderTests.testValidNoMatchEnvelope; exact .noMatch assertion; unchanged envelope schemaVersion token1. |
| R06 | All five non-null metadata fields rejected | EVIDENCED (FACT) | testNoMatchRejectsEachNonNullMetadataField: detectedType/mimeType/confidence/detectorVersion/modelVersion, five independent envelope mutations; all .failed. |
| R07 | Unknown and alternate helper tokens fail | EVIDENCED (FACT) | testUnknownResultKindsFailAndClassifiedRequiresDetectedType + existing malformed-kind test; unknown/unrecognized/not_classified rejected. |
| R08 | Classified requires detectedType | EVIDENCED (FACT) | testUnknownResultKindsFailAndClassifiedRequiresDetectedType + unchanged strict parser regressions. |
| R09 | Unavailable and failed all-null semantics unchanged | EVIDENCED (FACT) | testDeclaredUnavailableAndFailed unchanged and passing. |
| R10 | Process lifecycle, raw stdin, output caps and resolution unchanged | EVIDENCED (FACT) | Production parser-only diff; all 21 bundled-provider tests pass including empty/maximum stdin, caps, launch/cancel/terminate/close/reap and containment. |
| R11 | noMatch inference records providerRan=true | EVIDENCED (FACT) | FACT: unchanged produceOutcome .result(result) → (result,true); runtime probe observes exactly one inference for noMatch. |
| R12 | noMatch completion nil row, zero append calls and row delta | EVIDENCED (FACT) | testNoMatchAndZeroBytePrefixRunProviderWithoutAppendOrPersistedMetadata: exact .classification(.noMatch,nil), existing append probe=0, real repository row delta=0. |
| R13 | no type/MIME/confidence/provider/detector/model persistence | EVIDENCED (FACT) | Same real-repository test: history is empty and total row delta=0 despite provider properties containing non-null version sentinels. |
| R14 | Reader failed/sourceChanged/unsupportedEntry row mapping unchanged | EVIDENCED (FACT) | testAllSevenOutcomesAndExactObservationProvenance + existing reader failure test; four row-writing outcomes retained. |
| R15 | Empty eligible prefix valid and reaches provider as count0 | EVIDENCED (FACT) | Runtime noMatch test loops nonempty and Data(); source .prefix(empty request), provider observes exact count0 and returns noMatch; helper empty delivery test passes. Unchanged ClassificationSourceReaderTests.testEmptyFileReturnsEmptyPrefixInOneRead also passes against the real reader. |
| R16 | Invalidated late noMatch cannot publish or append | EVIDENCED (FACT) | testInvalidatedGenerationRejectsLateNoMatchAppendAndPublication: gate blocks provider, invalidate wins, cancelled completion/idle state, late noMatch, probe append0 and real rows0. |
| R17 | Caller cancellation before noMatch completion wins | EVIDENCED (FACT) | testCallerCancellationBeforeNoMatchCompletionWins: deterministic beforePersistence gate, caller cancellation first, cancelled nil-row completion, idle state and append0. |
| R18 | Five-second timeout remains failed despite late noMatch | EVIDENCED (FACT) | testTimeoutRemainsFailedWhenLateProviderReturnsNoMatch + existing deadline and cleanup races; late noMatch leaves failed terminal and exactly one failed row unchanged. |
| R19 | Missing helper/unavailable/cancelled remain distinct | EVIDENCED (FACT) | Existing bundled missing helper, runtime outcome matrix, cancellation races and production UI missing-helper test pass. |
| R20 | Single-flight, generation, locks, deadline, commit and ordering preserved | EVIDENCED (FACT) | Runtime production diff is only noMatch in no-row branch; 30 runtime tests pass including original busy/cleanup/authorization races unchanged. |
| R21 | Production UI mapping preserves noMatch | EVIDENCED (FACT) | SnapshotBrowserClassificationTests.testProductionMappingPreservesNoMatch exercises the same selectedEntryResult mapping called by productionStart; no provider launch required. |
| R22 | Current UI noMatch is idle and bounded neutral | EVIDENCED (FACT) | testCurrentNoMatchIsNeutralWithoutRefreshOrFabricatedStatus: idle; exact No file type recognized. message. |
| R23 | Current noMatch refresh0 and complete details preserved | EVIDENCED (FACT) | Same UI test: refresh delta0; selectedDetails full value equality; no classification status fabricated; real catalog rows0. |
| R24 | Persistent absence remains Not classified. | EVIDENCED (FACT) | Same UI test + unchanged inspector row-driven absence path and wording test. |
| R25 | Stale noMatch cannot change entry B/current browser | EVIDENCED (FACT) | testStaleNoMatchCannotAlterNewSelectionMessageOrDetails: start A on continuation gate, select B, release A noMatch, full B details/message/phase/refresh unchanged; existing browser replacement guards unchanged. |
| R26 | No raw diagnostic/privacy wording exposure | EVIDENCED (FACT) | ClassificationUIText.noMatch included in existing bounded-message privacy assertions; no associated noMatch diagnostic. |
| R27 | Source/network/path/payload/hash/logging/shell security preserved | EVIDENCED (FACT) | Existing capability and source inspection assertions unchanged; full security integration tests pass; only parser/enum/no-row/UI mapping production delta. |
| R28 | No schema/storage/reader/app/search/capture/export/compare/wiring/docs/dependency/provider acquisition delta | EVIDENCED (FACT) | Exact eight-file implementation allowlist; protected paths byte-equal to base; all excluded tracked paths have zero delta; no integration/029R/Slice08 executed. |
| R29 | Behavioral causal RED before production implementation | EVIDENCED (FACT) | Unchanged production: testValidNoMatchEnvelope compiled, executed1/passed0/skipped0/failed1, XCTAssertNotEqual(.failed,.failed); exit65. Final assertion strengthened to exact .noMatch. |
| R30 | Fresh DerivedData clean Debug build | EVIDENCED (FACT) | /tmp/FSD-NoMatch031-DerivedData; required clean build; exit0 BUILD SUCCEEDED. |
| R31 | Focused four-suite validation | EVIDENCED (FACT) | EXECUTED=89 PASSED=89 SKIPPED=0 FAILED=0; exit0 TEST SUCCEEDED. |
| R32 | Full Debug suite with explicit fixture skips | EVIDENCED (FACT) | Exact final receipt captured below; unchanged external fixture skips reported explicitly. |
| R33 | Fresh implementation postflight and diff check | EVIDENCED (FACT) | Complete production/test diff reviewed; git diff --check exit0; exact allowed paths verified; current identities and requirement map rechecked; return only to BRAIN. |

## Causal RED and root cause

FACT: production was unchanged at the RED boundary; Git diff contained only six
added lines in BundledMagikaClassificationProviderTests. Existing fake runner
seam delivered a valid schemaVersion1 seven-field no_match envelope with all
five metadata fields null. The test compiled and ran normally.

Command:
```sh
xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-NoMatch031-DerivedData -only-testing:FSDTests/BundledMagikaClassificationProviderTests/testValidNoMatchEnvelope
```

RED_EXECUTED=1
RED_PASSED=0
RED_SKIPPED=0
RED_FAILED=1
RED_EXIT=65
RED_ASSERTION=XCTAssertNotEqual(result, .failed, "valid ADR-034 no_match envelope must not be rejected")
RED_OBSERVED=failed_EQUALS_failed
RED_CAUSAL_BOUNDARY=VALID_no_match_REJECTED_BY_EXISTING_THREE_KIND_ALLOWLIST
RED_COMPILER_OR_SETUP_FAILURE=NO

Exact diagnostic: XCTAssertNotEqual failed: ("failed") is equal to ("failed") -
valid ADR-034 no_match envelope must not be rejected.
The parser's three-kind allowlist caused the rejection. The minimal repair adds
the approved no_match token and maps it to noMatch after the existing all-null
guard. The final permanent test replaces the RED predicate with exact
XCTAssertEqual(result, .noMatch); no weak temporary assertion remains.

RED_RAW=/tmp/FSD-NoMatch031-red.log
RED_XCRESULT=/tmp/FSD-NoMatch031-DerivedData/Logs/Test/Test-FSD-2026.10.06_18-36-45-+0700.xcresult

## Executed validation receipts

FACT: local macOS15.7.7 build24G720, arm64 destination, Xcode26.3 build17C529.
Fresh task DerivedData path is /tmp/FSD-NoMatch031-DerivedData. Debug correctness
validation only; no Release performance or provider feasibility claim.

```sh
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-NoMatch031-DerivedData clean build
xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-NoMatch031-DerivedData -only-testing:FSDTests/ClassificationProviderContractTests -only-testing:FSDTests/BundledMagikaClassificationProviderTests -only-testing:FSDTests/ClassificationRuntimeServiceTests -only-testing:FSDTests/SnapshotBrowserClassificationTests
xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-NoMatch031-DerivedData
git diff --check
```

CLEAN_DEBUG_BUILD=PASS;EXIT=0;BUILD_SUCCEEDED
FOCUSED_EXECUTED=89
FOCUSED_PASSED=89
FOCUSED_SKIPPED=0
FOCUSED_FAILED=0
FOCUSED_EXIT=0
FULL_DEBUG_EXECUTED=483
FULL_DEBUG_PASSED=480
FULL_DEBUG_SKIPPED=3
FULL_DEBUG_FAILED=0
FULL_DEBUG_EXIT=0
DIFF_CHECK=PASS;EXIT=0

Focused suite counts: provider contract10, bundled helper21, runtime30, UI28.
Full XCTest executed includes the three skipped test cases; passed=483-3=480.

Existing external-fixture skips, explicitly retained:
1. FSDProbeSeedTests.testSeedIsolatedProbeCatalog: FSD_PROBE_CATALOG unset and no
   marker file; isolated probe seeding is inert in ordinary runs.
2. FilesystemMatrixTests.testCaptureExternallyPreparedMountedFilesystem:
   FSD_MATRIX_SOURCE unset; externally prepared mounted fixture absent.
3. FilesystemMatrixTests.testReopenCapturedSnapshotWithTheSourceDetached:
   FSD_MATRIX_OFFLINE_CATALOG unset; offline fixture absent.

BUILD_RAW=/tmp/FSD-NoMatch031-build.log
FOCUSED_RAW=/tmp/FSD-NoMatch031-focused.log
FULL_DEBUG_RAW=/tmp/FSD-NoMatch031-full.log
FOCUSED_XCRESULT=/tmp/FSD-NoMatch031-DerivedData/Logs/Test/Test-FSD-2026.10.06_18-39-12-+0700.xcresult
FULL_DEBUG_XCRESULT=/tmp/FSD-NoMatch031-DerivedData/Logs/Test/Test-FSD-2026.10.06_18-39-44-+0700.xcresult

## Completion gates

LOCAL_PROVIDER_RESULT_COUNT=7
NOMATCH_ENUM=.noMatch
HELPER_NOMATCH_TOKEN=no_match
HELPER_NOMATCH_NULL_METADATA_REQUIRED=PASS
HELPER_NOMATCH_METADATA_REJECTED=5/5
UNKNOWN_HELPER_KIND_FAILED=PASS
NOMATCH_PROVIDER_RAN=YES
NOMATCH_ROW_COUNT=0
NOMATCH_APPEND_CALL_COUNT=0
NOMATCH_PERSISTED_PROVENANCE=NONE
ZERO_BYTE_NOMATCH=PASS
STALE_NOMATCH_PUBLICATION=NONE
STALE_NOMATCH_ROW=NONE
TIMEOUT_RESULT=.failed
MISSING_HELPER_RESULT=.unavailable
CANCEL_RESULT=.cancelled
UI_NOMATCH_MESSAGE=BOUNDED_NEUTRAL
UI_NOMATCH_DETAILS_REFRESH=0
PERSISTENT_ABSENCE=NOT_CLASSIFIED
STALE_UI_NOMATCH_MUTATION=NONE
BUSY_PROVIDER_RESULT=NO
SOURCE_CAPABILITY_DELTA=NONE
SOURCE_READ_LIMIT_DELTA=NONE
NETWORK_DELTA=NONE
SCHEMA_DELTA=NONE
REPOSITORY_FORMAT_DELTA=NONE
SINGLE_FLIGHT_DELTA=NONE
TIMEOUT_SEMANTICS_DELTA=NONE
CANCELLATION_SEMANTICS_DELTA=NONE
FILETYPE_ACQUISITION=NONE
PROVIDER_INTEGRATION=NONE
TASK029_RETRY_STARTED=NO
DEBUG_BUILD=PASS
FOCUSED=PASS
FULL_DEBUG=PASS

## Freshness, protected boundaries and finalizer ownership

FACT: initial local main was ca90122 (0 ahead/3 behind). Non-destructive fetch
resolved origin/main to the exact expected base. A clean --ff-only reconciliation
advanced the three BRAIN control files to 8677dcd; no Worker edit to accepted
state occurred. The task lock and actual implementation base remain the full
expected SHA above. Final pre-closure fetch confirmed no upstream movement.
The full implementation diff was freshly reviewed after all tests completed,
with exactly the eight authorized paths and no untracked paths.

FACT: technical commit 6ea54eb0aa40f5c4ab04f4ca3b039eeccf9afbb8 contains the tested implementation and
permanent regressions. At immutable-source creation local/remote were 1/0
ahead/behind and the worktree was clean. Publication is still pending at this
point; finalizer must verify its separate publication receipt rather than
rewrite these historical facts.

FACT: all tracked paths outside the eight implementation files are unchanged
at technical commit. In particular accepted PROJECT_STATE, RULE_PROMOTION_LEDGER,
source reader, repository storage, schema/migrations, pbxproj, app ownership and
all product documents remain byte-equal to base. Existing ignored owner artifacts
were left alone; no reset/clean/stash/rebase or provider acquisition was used.

Finalizer creates only this one historical source, CURRENT's full updated mirror,
one Worker ledger row and one append-only worker_return event. Accepted state,
other task rows/classifications, rule ledger and prior historical bytes are
protected. Desktop refresh preserves dated prior BRAIN-owned bytes, adds the
fresh accepted-state observation, raw canonical Operator bytes/digest and full
CURRENT. The checker is run with the exact twelve-path allowlist, captured base,
expected main/origin and required Desktop parity; after authorized publication
it must pass again with require-clean and require-synced. Resolve publication
from git log -1 --format=%H -- this handoff. No self-referential bookkeeping
commit is requested.

## Limits and proposed return

FACT: no real helper artifact, filetype source/toolchain/module acquisition,
provider integration, task029 retry or Slice08 was started. Parser and process
lifecycle proof uses the existing fake runner and production pipe seam.
Missing production helper remains unavailable. Existing test compiler warnings
(mutable Sendable gate under Swift5 mode, redundant try in comparison tests)
and Xcode support-library/AppIntents notices were preserved; no unrelated fix.

Worker-local code/test result is PASS; BRAIN adjudication and accepted-state
projection remain pending. The sole HOT proposal is a fresh filetype v1.1.3
scratch feasibility retry under implemented ADR-034 after BRAIN acceptance.
The retry was not consumed and no new provider-selection research was done.
