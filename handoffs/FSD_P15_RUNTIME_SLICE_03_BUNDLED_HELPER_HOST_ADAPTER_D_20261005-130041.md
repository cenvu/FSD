# P15 Slice 03 bundled-helper host adapter

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_P15_RUNTIME_SLICE_03_BUNDLED_HELPER_HOST_ADAPTER_D_20261005-130041.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=aafe69fe7b074d9964c338bf91b3603300df6e26
REMOTE_HEAD=95295efb2c88485f022e0f77cad65af4e9f00a44
LAST_VERIFIED_AT=2026-10-05T13:00:41+07:00
AUTHORITY_PTRS=AGENTS.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|STATE/PROJECT_STATE.md|docs/P15_RUNTIME_PLAN.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_P15_RUNTIME_SLICE_03_BUNDLED_HELPER_HOST_ADAPTER_018
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_FOR_SLICE_03_HOST_SEAM
PROPOSED_NEXT=FSD_P15_RUNTIME_SLICE_03_PROCESS_SECURITY_AUDIT_019
NO_AUTO_NEXT=YES

## Task lock / execution guard

TASK_ID=FSD_P15_RUNTIME_SLICE_03_BUNDLED_HELPER_HOST_ADAPTER_018
ROLE=WORKER
MODE=BOUNDED_PROCESS_SECURITY_IMPLEMENTATION
BASE_HEAD=95295efb2c88485f022e0f77cad65af4e9f00a44
UPSTREAM_HEAD=95295efb2c88485f022e0f77cad65af4e9f00a44
TECHNICAL_SHA=aafe69fe7b074d9964c338bf91b3603300df6e26
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=SLICE_03_HOST_SEAM_ONLY;NO_REAL_HELPER;NO_EXTERNAL_FACTS;NO_RUNTIME_ORCHESTRATION
ALLOWED_PATHS=FSD/Classification/BundledMagikaClassificationProvider.swift|FSDTests/BundledMagikaClassificationProviderTests.swift|FSD.xcodeproj/project.pbxproj|handoffs/FSD_P15_RUNTIME_SLICE_03_BUNDLED_HELPER_HOST_ADAPTER_D_20261005-130041.md|handoffs/CURRENT_HANDOFF.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl
FORBIDDEN_PATHS=SOURCE_READER;SCHEMA;CATALOG;SCANNER;APP_UI;SEARCH_COMPARE_EXPORT;PRODUCT_DOCS;HELPER_ASSETS_DEPENDENCIES;STATE/PROJECT_STATE.md;STATE/RULE_PROMOTION_LEDGER.tsv;PRIOR_HANDOFFS
SUCCESS_CRITERIA=FIXED_BUNDLE;RAW_STDIN_ONCE;STRICT_METADATA;DUAL_PIPE_CAPS;CANCEL_TERMINATE_CLOSE_REAP;INERT;BUILD_FOCUSED_FULL_PASS
VALIDATIONS=REQUIRED_XCODEBUILD_CLEAN_BUILD;FOCUSED_TWO_CLASSES;FULL_DEBUG;SOURCE_INSPECTION;GIT_DIFF_CHECK;CANONICAL_CONTROL_CHECKER_AND_FINALIZER
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
WORKER_RESULT=PASS_WITH_ADVISORY
RESULT_AUTHORITY=WORKER_EVIDENCE_ONLY;BRAIN_ACCEPTANCE_PENDING

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=32
WORKER_REQUIREMENTS_EVIDENCED=32
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

## Delta / host contract

FACT: the technical commit adds the adapter (405 lines), its tests (321 lines), and two Xcode source registrations. No existing Swift contract/test source was changed. The internal placeholder is Contents/Helpers/FSDClassificationHostSeam; this is not an asserted upstream filename. Default construction captures Bundle.main.bundleURL only; resolution and runner creation occur on classify.
FACT: request.data goes unchanged to one raw nonblocking write, then stdin closes. Short writes/EINTR/EAGAIN fail closed without retrying delivery. There are no CLI flags, sample arguments, environment payloads, temporary samples or additional byte requests.
FACT: the host envelope is strict flat JSON with exactly seven keys listed in the map. Schema token is integer 1; helper result kinds are classified/unavailable/failed. Four metadata text fields are null or 1...256 UTF-8 bytes without controls; classified requires detectedType. Confidence is null or finite 0...1. Unavailable/failed require null metadata. Unknown/duplicate/missing/extra/nested/malformed data fails. This specifies FSD's seam only; upstream output, filename, license, model, build, dependency and version behavior remain externally unverified.
FACT: provider identity is constant and absent from the envelope. Helper detector/model versions remain separate optional observation values; no fabricated real detector/model versions or persistence.

## Bounded draining / ownership / cancellation reasoning

FACT: the shared lifecycle driver is exercised with the injected fake runner. The production pump is additionally exercised with real local pipes, no child or external command: 0, 4096 and 4097 bytes on both channels; stderr readiness with stdout idle; exact caps and overflow outcomes.
FACT: all three parent I/O ends are nonblocking. Poll services BOTH output channels with at most min(1024,remaining budget) per channel per iteration. Stdout accumulation is guarded before append and never exceeds 4096; stderr is transient scratch plus an integer count, never Data/text in the runner result. At a zero remaining budget, the SDK-derived FIONREAD ioctl checks queued byte count without consuming a 4097th byte. Positive pending count fails/terminates. EOF alone is accepted. The query encoding is verified by real-pipe cap tests and comes from local sys/filio.h + sys/ioccom.h, not a helper fact.
STRONG_INFERENCE: noisy stdout or stderr cannot create a parent/child full-pipe exit wait cycle. Both channels receive nonblocking relief before any normal waitUntilExit. Normal reaping occurs only after child exit and both channels drain/close; error/cap/cancel forces termination, closes all pipe ends, then waits/reaps. After child exit, empty inherited output ends close without waiting indefinitely for EOF. Retained payload/metadata memory remains capped; no unbounded read-to-end, Data or String growth exists.
FACT: Process and pipes are private to the adapter file; the runner/pump/token seams are internal. Each default call creates a fresh runner. Cancellation handler mutates the locked token only; the owned utility-queue operation services cancellation before/after poll, terminates active child, closes pipes, reaps, then resumes its awaiting continuation. No detached task or persistent process is created.
STRONG_INFERENCE: direct Process.terminate (SDK: SIGTERM, potentially ignored) followed by SIGKILL for a still-running owned child prevents a signal-ignoring child from blocking cleanup; Process.waitUntilExit supplies the reaping boundary. Foundation process lifecycle is reasoned from production code and local NSTask.h / kill(2) documentation, and causally tested through the shared fake driver. No real executable was launched in tests, as required. The mandatory independent audit is still outstanding.
FACT: cancellation's locked completion point follows pipe closure/reaping. If cancellation wins the lock before completion, result is cancelled; if completion wins first, later cancellation is ignored. The provider performs no later cancellation check that could fabricate cancellation. Condition-based active-child test and both lock orderings passed. Poll's 20ms interval services I/O/cancellation; it imposes no runtime deadline. Slice 04 was not implemented.

## Validation receipts / debug discipline

Commands (all project=FSD.xcodeproj, scheme=FSD, Debug, destination platform=macOS,arch=arm64, derived data=/tmp/FSD-P15-Impl03-DerivedData):

- xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-P15-Impl03-DerivedData clean build: exit 0, BUILD SUCCEEDED. Only SDK AppIntents metadata-extraction warning (no dependency) observed.
- xcodebuild test with the same flags and -only-testing:FSDTests/BundledMagikaClassificationProviderTests -only-testing:FSDTests/ClassificationProviderContractTests: exit 0; EXECUTED=24, PASSED=24, SKIPPED=0, FAILED=0; 0.318 test / 0.326 wall seconds.
- xcodebuild test with the same flags, no filters: exit 0; EXECUTED=399, PASSED=396, SKIPPED=3, FAILED=0; 2526.354 test / 2758.488 wall seconds.
- git diff --check 95295efb2c88485f022e0f77cad65af4e9f00a44: exit 0 on technical candidate. Protected-path diff against base empty; untracked status empty after technical commit.

RAW_REFS=/tmp/FSD-P15-Impl03-build.log|/tmp/FSD-P15-Impl03-focused.log|/tmp/FSD-P15-Impl03-full.log|/tmp/FSD-P15-Impl03-red-causal.log
FOCUSED_XCRESULT=/tmp/FSD-P15-Impl03-DerivedData/Logs/Test/Test-FSD-2026.10.05_12-10-21-+0700.xcresult
FULL_XCRESULT=/tmp/FSD-P15-Impl03-DerivedData/Logs/Test/Test-FSD-2026.10.05_12-10-50-+0700.xcresult

FACT: causal RED executed 12, passed 2, failed 10, skipped 0, with 99 intended assertions; exit 65. Setup-only missing symbols were not RED evidence. Separate compile boundaries were investigated before repair: unimported function-like FIONREAD macro (derived local SDK encoding), and a Data/FileHandle name shadow during pump extraction (renamed stdoutBytes). The first runnable focused candidate executed 23, passed 22, failed 1, skipped 0 (three URL assertions): injected resolver returned bundle root instead of fixed executable. Repair narrowed injection to canonicalization/permission hooks, ensuring all calls compute and validate the fixed relative location; final focused and full runs passed on the unchanged technical source.
ADVISORY: three existing environment probes skipped: FSDProbeSeedTests.testSeedIsolatedProbeCatalog (FSD_PROBE_CATALOG absent/no marker); FilesystemMatrixTests.testCaptureExternallyPreparedMountedFilesystem (FSD_MATRIX_SOURCE absent); FilesystemMatrixTests.testReopenCapturedSnapshotWithTheSourceDetached (FSD_MATRIX_OFFLINE_CATALOG absent). No skip was counted as pass; no external-helper/offline/license/runtime integration proof or release acceptance is claimed.

## Requirement / evidence map

The 32 execution groups below cover the bounded implementation and execution postflight. Finalizer publication/transport mechanics occur after this immutable capture; their fresh receipt is carried in Desktop before terminal return.

| # | Requirement | Evidence |
|---|---|---|
| 1 | Authority / baseline / bounded Worker scope | Fresh root/kernel/skill/state; canonical fetch and clean ff-only a34935d → 95295ef; expected gate 018 confirmed. |
| 2 | Tests first / causal RED | Inert scaffold: 12 executed, 2 passed, 10 failed, 0 skipped; 99 intended assertions; exit 65. Missing-type setup failure was not counted as RED. |
| 3 | Fixed bundle-relative executable | testFixedResolutionStandardizesAndRejectsEscapesAndSiblingPrefix; raw-input test asserts launched fixed URL. |
| 4 | Canonical containment / symlink escape | testPhysicalMissingNonExecutableDirectoryAndSymlinkResolution; canonical helper outside root rejected before permission check. |
| 5 | Missing / non-executable unavailable | testMissingAndNonExecutableHelpersAreUnavailableAndNeverLaunch plus physical default resolver test. |
| 6 | Exact raw input / empty / maximum | testRawInputEmptyMaximumAndExactlyOneClosedDelivery: 0, 6 hostile binary bytes, and 4096 bytes; Data equality. |
| 7 | One stdin delivery / close before output | Same causal test asserts launch → deliver → closeInput → poll → reap → closePipes; production has one nonblocking Darwin.write and exact count check. |
| 8 | No source capability / second request | Unmodified LocalClassificationRequest/Result/protocol; all nine existing ClassificationProviderContractTests passed. |
| 9 | No sample file / argv / environment payload | Source boundary test plus direct inspection: no sample file; arguments=[]; environment=[:]; input goes to stdin alone. |
| 10 | Strict versioned envelope / exact seven fields | Flat parser accepts schemaVersion,resultKind,detectedType,mimeType,confidence,detectorVersion,modelVersion only; rejects duplicate/extra/missing keys. |
| 11 | Valid classified envelope | testClassifiedEnvelopeAndIndependentHostProvenance; exact observation equality. |
| 12 | Declared unavailable / failed | testDeclaredUnavailableAndFailed; both cleaned/reaped. |
| 13 | Unknown schema / result | testStrictMalformedSchemaKindTypesLengthsAndConfidence; unsupported integer, boolean, fractional schema and unknown kind fail. |
| 14 | Malformed type / count / length | Same table: nested/nontext metadata, missing/extra/duplicate keys, empty/257-byte detected type, trailing garbage fail. |
| 15 | Invalid confidence | Same table: below zero, above one, boolean, string and overflow fail; parser accepts null or finite 0...1. |
| 16 | Stdout cap / cumulative overflow | testCapsAreCumulativeAndStderrNeverSurfaces; exactly 4096 accepted, 4097 and cumulative overflow fail before append. |
| 17 | Stderr cap / no diagnostic exposure | Same test; frame carries byte count only. Real pipe test writes HOSTILE_STDERR and verifies it never crosses the pump result. |
| 18 | Production bounded dual-pipe service | testProductionPipePumpCapsBothChannelsWithoutLaunchingAChild and testProductionPipePumpServicesStderrWhileStdoutHasNoBytes exercise the actual Darwin pump. |
| 19 | Host provider identity | testClassifiedEnvelopeAndIndependentHostProvenance rejects helper providerIdentifier; constant fsd.bundled-helper-host.v1. |
| 20 | Independent detector / model provenance | Same test asserts detector-fixture and model-fixture independently in observation; provider version properties remain nil. |
| 21 | Zero exit / nonzero / crash | Raw/classified tests plus testNonzeroCrashLaunchWriteAndReadFaultsReapAndClose; only zero/noncrash reaches parsing. |
| 22 | Launch / input / read errors cleanup | Same fault test; shared driver terminates, closes pipes and reaps; production no-child launch failure is safely a no-op reap. |
| 23 | Active cancellation terminate / reap / close | testCancellationWhileActiveTerminatesReapsAndCloses uses expectation + condition synchronization without sleeps. |
| 24 | Cancellation ordering / prelaunch | testCancellationBeforeLaunchAndCompletionOrdering; lock completion after cleanup is the linearization point; cancellation before wins, after ignored. |
| 25 | Inert construction / disabled unchanged | testConstructionAndDisabledProviderAreInert plus unmodified disabled provider contract tests. |
| 26 | No shell / PATH / network / daemon | Source inspection and supplementary test: direct fixed Process, empty args/env, no discovery, network, diagnostics logging or detached task. |
| 27 | No real helper / upstream facts / dependencies | Git delta contains two Swift files and source registrations only; internal filename/envelope are host placeholders; no external Magika research or integration. |
| 28 | Protected product boundaries / no Slice 04 | Fresh byte/diff checks: contract, reader, schema/catalog/scanner, UI/search/export/runtime and product docs unchanged; no runtime deadline policy. |
| 29 | Clean Debug build | Exact required clean build in /tmp/FSD-P15-Impl03-DerivedData exited 0; BUILD SUCCEEDED. |
| 30 | Focused validation | Exact required two-class command exited 0; 24 executed / 24 passed / 0 skipped / 0 failed. |
| 31 | Full Debug validation | Full command exited 0; 399 executed / 396 passed / 3 skipped / 0 failed; 2526.354 test seconds / 2758.488 wall seconds. |
| 32 | Fresh scope / preservation / audit boundary | git diff --check PASS; clean technical candidate, only three product/test paths; protected state/history byte parity; audit 019 proposed only. Closure checks are finalizer receipts below. |

## Completion gates / closure ownership

HOST_ADAPTER_COMPILES=PASS
REAL_HELPER_ASSET=NONE
REAL_MAGIKA_FACTS_ASSUMED=NONE
INPUT_RAW_BYTES=PASS
INPUT_MAX=4096
STDIN_DELIVERIES=1
STDOUT_CAP=4096
STDERR_CAP=4096
UNBOUNDED_PIPE_READ=NONE
PATH_SEARCH=NONE
SHELL=NONE
TEMP_SAMPLE=NONE
ARGV_SAMPLE=NONE
ENV_SAMPLE=NONE
NETWORK=NONE
PROVIDER_ID_HOST_OWNED=PASS
DETECTOR_MODEL_PROVENANCE_SEPARATE=PASS
CANCEL_TERMINATES=PASS
ALL_PATHS_REAP=PASS
PERSISTENT_PROCESS=NONE
PROVIDER_SOURCE_CAPABILITY_DELTA=NONE
SOURCE_READER_DELTA=NONE
SCHEMA_DELTA=NONE
SLICE04_DELTA=NONE
FOCUSED=PASS
FULL_DEBUG=PASS

FACT: technical capture is clean, local ahead=1 / behind=0; upstream remains the authorized base. This immutable record contains no future publication SHA. Canonical checker, closure commit, push/fetch parity, Desktop exact Operator/full CURRENT projection and final clean state must be verified by fsd-handoff-finalizer before terminal return; this source does not preclaim those later commands ran. Desktop carries the actual final publication/Git receipt. Only this handoff, CURRENT full mirror, one Worker ledger row and one append-only worker_return event are closure mutations; accepted PROJECT_STATE, rule promotion, prior task rows/BRAIN classifications and old historical bytes remain unchanged.
PROPOSED_STATE_DELTA=EVIDENCE_OF_COMPLETED_SLICE_03_HOST_SEAM_ONLY;BRAIN_TO_ADJUDICATE_AND_AUTHORIZE_AUDIT_SEPARATELY
AUDIT_GATE=INDEPENDENT_PROCESS_SECURITY_AUDIT_REQUIRED_BEFORE_SLICE_04;NOT_STARTED
EXTERNAL_INTEGRATION_GATE=SLICE_07_EXTERNAL_VERIFICATION_REQUIRED;UNCHANGED
