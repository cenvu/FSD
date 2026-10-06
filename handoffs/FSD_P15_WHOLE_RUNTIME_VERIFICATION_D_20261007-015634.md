# Canonical Phase 1.5 runtime — Slice 08 whole-runtime verification

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_P15_WHOLE_RUNTIME_VERIFICATION_D_20261007-015634.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=3cbe4b461c388aa3b6b15c0c898b7a9deb34fe9d
REMOTE_HEAD=9d1a8ea237c6c2941895b1c3640118371d2e2d4d
LAST_VERIFIED_AT=2026-10-07T02:36:10+07:00
AUTHORITY_PTRS=AGENTS.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|docs/BRAIN_OPERATOR.md|STATE/PROJECT_STATE.md|handoffs/FSD_CLASSIFIER_FILETYPE_INTEGRATION_AUDIT_R_20261007-001045.md|handoffs/FSD_CLASSIFIER_FILETYPE_BUNDLED_HELPER_INTEGRATION_RESCOPE_D_20261006-225618.md|docs/P15_RUNTIME_PLAN.md|docs/DECISIONS.md|docs/ARCHITECTURE.md|docs/SECURITY_AND_READ_ONLY_POLICY.md|docs/TEST_PLAN.md|docs/MVP_PLAN.md|docs/PRODUCT_STATE.md|docs/CLASSIFIER_FILETYPE_INTEGRATION_CONTRACT.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_P15_WHOLE_RUNTIME_VERIFICATION_035
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_FOR_TASK035;FINAL_INDEPENDENT_AUDIT_AND_BRAIN_ADJUDICATION_PENDING
PROPOSED_NEXT=FSD_P15_RUNTIME_FINAL_AUDIT_036
NO_AUTO_NEXT=YES

## Task lock and Worker result

TASK_ID=FSD_P15_WHOLE_RUNTIME_VERIFICATION_035
ROLE=WORKER
MODE=WHOLE_RUNTIME_VERIFICATION_AND_CANONICAL_HANDOFF
BASE_HEAD=9d1a8ea237c6c2941895b1c3640118371d2e2d4d
UPSTREAM_HEAD=9d1a8ea237c6c2941895b1c3640118371d2e2d4d
CHECKER_BASE=3cbe4b461c388aa3b6b15c0c898b7a9deb34fe9d
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=CANONICAL_SLICE08_VERIFICATION_AND_PROVEN_STATUS_DOCUMENTATION_ONLY
ALLOWED_PATHS=docs/ARCHITECTURE.md|docs/DECISIONS.md|docs/SECURITY_AND_READ_ONLY_POLICY.md|docs/TEST_PLAN.md|docs/MVP_PLAN.md|docs/PRODUCT_STATE.md|STATE/PROJECT_STATE.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|handoffs/CURRENT_HANDOFF.md|handoffs/FSD_P15_WHOLE_RUNTIME_VERIFICATION_D_20261007-015634.md
FORBIDDEN_PATHS=ALL_PRODUCTION_SWIFT|ALL_TEST_SOURCE|SCHEMA_SQL_MIGRATIONS|FSD.xcodeproj|HELPER_SOURCE_BINARY_MANIFEST_NOTICES_BUILD_SCRIPT|GO_MODULE_VENDOR_EXTERNAL_DEPENDENCIES|UNRELATED_DOCUMENTATION|PRIOR_HISTORICAL_HANDOFFS|STATE/RULE_PROMOTION_LEDGER.tsv
SUCCESS_CRITERIA=ALL_MANDATORY_VERIFICATION_GATES_PASS;CANONICAL_STATUS_SYNC;ONE_HANDOFF;VERIFIED_CLEAN_SYNCED_PUBLICATION
VALIDATIONS=CLEAN_DEBUG;FULL_DEBUG_XCTEST;CLEAN_RELEASE;FOCUSED_CLASSIFIER_ISOLATION_SCHEMA;REAL_HELPER_MATRIX;BUNDLE_PROVENANCE;PROCESS_NETWORK_OBSERVATION;ADHOC_SIGNING_COPY;DIFF_SCOPE;CONTROL_CHECKER_PRE_POSTPUBLICATION
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY;036_PROPOSAL_ONLY
RESULT=PASS_WITH_ADVISORY
RESULT_AUTHORITY=WORKER_EVIDENCE_PENDING_BRAIN
TECHNICAL_SHA=3cbe4b461c388aa3b6b15c0c898b7a9deb34fe9d
REVIEWED_IMPLEMENTATION_SHA=556872844b90640cc2a64e40d99594a78cef61af
INTEGRATION_AUDITED=YES
PRODUCTION_PROVIDER_ACCEPTED=YES
PRODUCTION_PROVIDER=filetype_v1.1.3
SLICE08_UNBLOCKED=YES
PHASE15_FINAL_ACCEPTANCE=PENDING_BRAIN_AFTER_INDEPENDENT_FINAL_AUDIT
MANUAL_ACCEPTANCE=NOT PERFORMED — DEFERRED BY OWNER

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=28
WORKER_REQUIREMENTS_EVIDENCED=27
WORKER_REQUIREMENTS_NOT_APPLICABLE=1
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

## Re-anchor and supplied BRAIN projection — AUTOMATED VERIFIED / authority provenance

Physical canonical Git root `/Users/cenvu/DEV/FSD`, origin `https://github.com/cenvu/FSD.git`, branch `main`. Initial non-destructive `git fetch origin` established clean local/upstream `9d1a8ea237c6c2941895b1c3640118371d2e2d4d`, ahead 0 / behind 0. `git merge-base --is-ancestor` exited 0 separately for audit publication `9d1a8ea237c6c2941895b1c3640118371d2e2d4d`, task033A publication `cd41457f1ac6160ba3cb12d58d846d70ea708c58`, and implementation `556872844b90640cc2a64e40d99594a78cef61af`. New DerivedData paths did not exist before their builds. Owner dirty/ignored bytes and prior historical handoffs were preserved; no reset/clean/stash/rebase/discard.

Required execution/finalizer skills, CURRENT HOT, AGENTS, Compact, accepted STATE, exact audit/rescope handoffs, Slice08, ADR-031/032/034/035, architecture §9/§9a, security §2.1, Test Plan §9, MVP Phase1.5, PRODUCT_STATE/KI-025 and the full integration contract were loaded. The Slice06 §9 coverage ledger was expanded for exact current test traceability; accepted schema/source/process/implementation prerequisites were verified in TASK_LEDGER, including schema audit010, source closure017 and process re-audit021. Prior returns remain historical evidence, not current counts.

Before Slice08 execution, only the supplied Owner/BRAIN decision was mechanically projected in commit `3cbe4b461c388aa3b6b15c0c898b7a9deb34fe9d`: task034 accepted PASS_WITH_ADVISORY at `9d1a8ea237c6c2941895b1c3640118371d2e2d4d`; integration audited YES; production provider accepted filetype v1.1.3; Slice08 unblocked YES. CURRENT_GATE and exactly-one active ACTION remain task035. Two append-only BRAIN events cite that explicit authorization. This projection is the checker base because accepted STATE/prior classifications must be stable across Worker finalization. It is a known verification basis SHA, not this immutable handoff's future publication. No Phase1.5 final acceptance or rule promotion was authored.

Task034 process advisory preserved: Reviewer-only Homebrew/system Go introspection caused one macOS local telemetry counter entry. It did not come from the shipped helper, normal FSD runtime/Xcode build, controlled task033A rebuild or controlled task034 rebuild, and changed no Go configuration. Accepted controlled-rebuild evidence still proves Owner-global telemetry metadata unchanged during those scratch-contained runs. Task035 runs **no Go command**, performs no controlled Go rebuild, and changes no Owner-global Go configuration or telemetry mode. Binary provenance below is read directly from embedded build-info bytes and tied to the accepted SHA.

## Current builds and full/focused tests — AUTOMATED VERIFIED

Observed test host: macOS15.7.7 arm64 (osBuild24G720), from xcresult; `xcodebuild -version` exited0 with Xcode26.3/build17C529. All commands run from the physical canonical root. Test commands add a unique result bundle only; no historical count is merged into these receipts. Debug correctness evidence establishes no new Release performance threshold acceptance.

| Current task035 command | Exit | Wall seconds | Executed | Passed | Failed | Skipped |
|---|---:|---:|---:|---:|---:|---:|
| `xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug -destination platform=macOS,arch=arm64 -derivedDataPath /tmp/FSD-P15-Final-Debug clean build` | 0 | 14.842 | 0 | 0 | 0 | 0 |
| `xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug -destination platform=macOS,arch=arm64 -derivedDataPath /tmp/FSD-P15-Final-Debug -resultBundlePath /Users/cenvu/DEV/FSD/.ai-scratch/task035/full-debug.xcresult` | 0 | 2697.696 | 494 | 491 | 0 | 3 |
| `xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Release -destination platform=macOS,arch=arm64 -derivedDataPath /tmp/FSD-P15-Final-Release clean build` | 0 | 14.271 | 0 | 0 | 0 | 0 |
| `xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug -destination platform=macOS,arch=arm64 -derivedDataPath /tmp/FSD-P15-Final-Debug -resultBundlePath /Users/cenvu/DEV/FSD/.ai-scratch/task035/focused.xcresult -only-testing:FSDTests/BundledFiletypeClassificationProviderTests -only-testing:FSDTests/ClassificationEnrichmentTests -only-testing:FSDTests/ClassificationSourceReaderTests -only-testing:FSDTests/ClassificationProviderContractTests -only-testing:FSDTests/ClassificationRuntimeServiceTests -only-testing:FSDTests/SnapshotBrowserClassificationTests -only-testing:FSDTests/ClassificationInvocationIsolationTests -only-testing:FSDTests/ClassificationSecurityIntegrationTests -only-testing:FSDTests/ComparisonSemanticsTests -only-testing:FSDTests/JSONExportTests -only-testing:FSDTests/SchemaMigrationTests -only-testing:FSDTests/SchemaSafetyCorrectionTests -only-testing:FSDTests/CatalogDatabaseTests` | 0 | 83.572 | 242 | 242 | 0 | 0 |
| `xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug -destination platform=macOS,arch=arm64 -derivedDataPath /tmp/FSD-P15-Final-Debug -resultBundlePath /Users/cenvu/DEV/FSD/.ai-scratch/task035/schema-safety.xcresult -only-testing:FSDTests/ExpectedStateInventoryTests -only-testing:FSDTests/TerminalCollisionEvidenceTests` | 0 | 4.821 | 18 | 18 | 0 | 0 |

Build rows execute zero tests; both logs report BUILD SUCCEEDED. All three test logs report TEST SUCCEEDED. Individual XCTest terminal identities were counted independently and cross-checked against `xcrun xcresulttool get test-results summary --path <the recorded result bundle> --compact` (exit0). Current full suite: 494 executed / 491 passed / 0 failed / 3 skipped. Current focused run: 242 executed / 242 passed / 0 failed / 0 skipped; the eight classifier suites are augmented by comparison/export isolation and SchemaMigrationTests/CatalogDatabaseTests, followed by supplemental schema-safety 18 executed / 18 passed / 0 failed / 0 skipped. The first focused command included an ineffective file-named SchemaSafetyCorrectionTests selector (no such XCTest class); it selected zero tests and is not counted as coverage. Fresh result/class inventory exposed the command-selection mistake, so the actual classes ExpectedStateInventoryTests and TerminalCollisionEvidenceTests were explicitly rerun in the supplemental command above. Both also passed in the full run; no product or test defect/repair is involved.

| Focused / supplemental suite | Executed | Passed | Failed | Skipped |
|---|---:|---:|---:|---:|
| BundledFiletypeClassificationProviderTests | 32 | 32 | 0 | 0 |
| CatalogDatabaseTests | 6 | 6 | 0 | 0 |
| ClassificationEnrichmentTests | 10 | 10 | 0 | 0 |
| ClassificationInvocationIsolationTests | 8 | 8 | 0 | 0 |
| ClassificationProviderContractTests | 10 | 10 | 0 | 0 |
| ClassificationRuntimeServiceTests | 30 | 30 | 0 | 0 |
| ClassificationSecurityIntegrationTests | 8 | 8 | 0 | 0 |
| ClassificationSourceReaderTests | 57 | 57 | 0 | 0 |
| ComparisonSemanticsTests | 19 | 19 | 0 | 0 |
| JSONExportTests | 9 | 9 | 0 | 0 |
| SchemaMigrationTests | 25 | 25 | 0 | 0 |
| SnapshotBrowserClassificationTests | 28 | 28 | 0 | 0 |
| ExpectedStateInventoryTests | 10 | 10 | 0 | 0 |
| TerminalCollisionEvidenceTests | 8 | 8 | 0 | 0 |

Exactly three full-suite environment skips: FSDProbeSeedTests/testSeedIsolatedProbeCatalog (`FSD_PROBE_CATALOG` absent); FilesystemMatrixTests/testCaptureExternallyPreparedMountedFilesystem (`FSD_MATRIX_SOURCE` absent); FilesystemMatrixTests/testReopenCapturedSnapshotWithTheSourceDetached (`FSD_MATRIX_OFFLINE_CATALOG` absent). None is classifier/helper/bundle/process coverage. No focused or supplemental schema-safety test skips; the helper-required test calls XCTFail, never XCTSkip, if the committed executable is missing. No defect was repaired or hidden. The full run repeated the previously disclosed test-only Thread Performance Checker QoS diagnostic at M5PeakSampler.stop (same accepted task033A advisory); the related comparison-memory test passed. This is preserved as an existing test-instrumentation advisory, not a new product finding or a claim of repair.

## Source authority, schema and persistence — AUTOMATED VERIFIED / AGENT-OBSERVED source inspection

Fresh schema and migrations require version 9; supported 4→5→6→7→8→9 order and version-last transaction/rollback behavior reran. `entry_classifications` has exactly id, entry_id, classification_run_id, detected_type, mime_type, confidence, detection_status, detector_version, model_version, classified_at, created_at, provider_identifier. The last column is nullable/no-default; legacy v8 rows remain NULL with no fabricated provider or backfill. Fresh/migrated PRAGMA table_info equivalence, no replay, ExpectedState rejection of missing provenance, integrity_check=ok and foreign_key_check empty passed. Typed append-only history, independent provenance round-trip, unique (entry_id, classification_run_id) rejection and immutable entry/snapshot facts passed. No schema/SQL change.

Current protocol reflection/exhaustiveness and hostile-provider tests prove the request's sole stored field is immutable bounded Data, exactly 0...4096 bytes. No original path, URL, descriptor, FileHandle, identity, resolver, read callback, range callback or second read is supplied. The inspected production reader owns O_RDONLY/O_NOFOLLOW/O_CLOEXEC descriptor-relative opens; validates regular-file kind and exact volume/dev+ino authority with a fresh pre-read object barrier; performs one `Darwin.read` at offset zero into at most4096 bytes; and revalidates afterward. Failed pre-read authority performs zero content reads; short reads are never topped up. Small/zero/exact4096/4097/oversized source tests, symlink/substitution/disappearance/permission/cancellation cases passed. These are point-in-time opened-object proofs, not namespace locks.

Typed outcomes are exactly classified, failed, sourceChanged, unsupportedEntry, unavailable, cancelled, noMatch; busy is admission state only. Four outcomes append one row (classified→classified; failed/sourceChanged/unsupportedEntry→failed); unavailable/cancelled/noMatch append none. The real-helper noMatch test reached the production runtime and actual repository, returned no row, counted zero classification rows and preserved entries. No detected type/provider/detector/model row is fabricated. No payload/sample/content hash/source path/diagnostic column or observed persisted value leaks; runtime completion/state carry no source authority. Classification writes preserve snapshots and entries.

Classified provenance is verified across the actual helper/provider plus unchanged runtime mapping and real repository round-trip boundaries: helper observation detector exactly `github.com/h2non/filetype@v1.1.3`, nil model and confidence; runtime copies that observation and supplies host-owned `fsd.bundled-helper-host.v1` rather than trusting a helper provider field. The helper's strict seven-field envelope has no provider-ID field. Cancellation/generation/commit-authorization tests prove cancellation cannot append a later success row, timeout remains failed, cleanup retains ownership until reaped, and stale completions cannot publish into a successor.

## Real helper matrix — AUTOMATED VERIFIED

The actual committed helper `665a6569ee60614313e50629c4166358b89859f15dac4c522905ee5a730752e7` ran directly and through BundledFiletypeClassificationProvider → FoundationHelperProcessRunner. The actual-helper tests passed in both the full and focused runs; no fake runner substitutes for these cases:

- PNG success; unknown and zero-byte noMatch; exact4096 processing and4097 rejection; strict seven keys/one trailing LF, nil confidence/model, exact detector.
- Short CFB lengths4/32/513 each32 fresh launches → noMatch; long synthetic DOC/XLS/PPT and nonmatching CFB at514/515/1024/4096 each16 fresh launches per case → expected single-valued route. Synthetic discriminants are not realistic legacy fixtures.
- Pinned public realistic PNG/DOCX/XLSX/PPTX bounded fixture prefixes each16 direct launches plus each actual production-runner call → correct single-valued type. Their pin/fixture-prefix provenance was independently verified by accepted task034; task035 reruns the committed fixtures, not a download/rebuild.
- Nine LLDB address-relocated cases on the exact shipped SHA prove Match calls: zero for4097 and shortCFB4/32/513; one for empty, unknown, PNG,4096 PNG and longDOC514. The positive Match controls validate the same debugger harness; no instrumented/substituted helper.
- Deliberately missing bundle helper with real runner → unavailable; SIGKILL of actual child → failed; suspended actual child plus cancellation → cancelled and closed/reaped; suspended actual child plus real five-second inference deadline → failed with exactly one failed append and cleanup. That test asserts an elapsed lower bound, not a universal completion upper bound.
- Actual noMatch after inference plus generation invalidation → cancelled, no append, no stale publication. Real noMatch against repository → zero rows and immutable entry facts.

Cumulative stdout/stderr caps4096 each reran in the existing real production pipe-pump tests using local pipes, plus deterministic driver fault injection. Those cap tests are not represented as an actual helper flooding4097 output bytes. Actual helper output in the observed six PNG runs was 181 bytes each, stderr0; direct-helper suite verifies bounded strict outputs. The accepted helper cannot acquire more source bytes: host request/runner caps and stdin4097 rejection remain unchanged.

## Eight-workflow / comparison / export / offline isolation — AUTOMATED VERIFIED

ClassificationInvocationIsolationTests contains eight separately identified tests: capture, application launch, history open, snapshot reopen, ordinary browsing/selection, search, comparison and JSON export. Each passed zero starts/zero classification-row delta, using the real production workflow plus counting seam or unchanged runtime generation/capability absence. Explicit selected-entry action remains the sole trigger. Source inspection and runtime/browser tests preserve no bulk/background classifier, watcher, queue, automatic retry or backfill; 0.5s delayed progress and cancellation/stale UI behavior have automated model evidence only.

ComparisonSemanticsTests proves unchanged result paths/types/flags/counts against an unenriched baseline after divergent classification rows, and no comparison classification-row access. JSONExportTests proves byte-identical before/after enrichment, unchanged formatVersion1 and exclusion of classification. No comparison/export source changed. SecurityIntegration's deleted-source fixture preserves locked unavailable/sourceChanged semantics and usable history/tree/details/export; no physical media detachment is claimed. Full lifecycle/recovery tests preserve completed snapshot immutability and interrupted-never-replaces-last-complete; metadata/structure match remains no content verification.

## Fresh bundle/provenance and signing — AUTOMATED VERIFIED / AGENT-OBSERVED

Debug and Release unsigned bundles both have exactly one Helpers file, `Contents/Helpers/FSDClassificationHostSeam`, byte-identical to committed helper and manifest SHA `665a6569ee60614313e50629c4166358b89859f15dac4c522905ee5a730752e7`. `Contents/Resources/THIRD_PARTY_NOTICES.txt` equals committed notices, SHA25617115e870f77043cd5d6a1c60217ec6e0f412d9236f2002425eba3195c12ed38. `file`/`lipo` show non-fat arm64; vtool minos13.0; otool only libSystem.B/libresolv.9 system dylibs. Binary-safe committed bytes and canonical source-set SHA37d3b38eb1e51e74a53c1c37e8389b4bde8b587a1be8ca4abdaf913fbd60feae match. Embedded build-info reports go1.27.1, sole filetype v1.1.3 dependency with pinned Sum, trimpath, CGO0, GOOSdarwin/GOARCHarm64; inspected by raw bytes, with no Go tool invocation.

All bundle files were enumerated. No Go toolchain/cache/module source, classifier model/database or runtime downloader artifact is bundled. Debug inspection includes XCTest's expected injected frameworks/test plug-in and Debug compiler dylibs after the test build; Release contains only FSD, helper, Info.plist, PkgInfo, notices and schema.sql. The Helper directory has no unexpected executable. Empty Xcode shell-script phase plus inspected Debug/Release logs prove no normal-build Go construction/download/network step. COPY_PHASE_STRIP=NO and signing-disabled app configurations preserve helper bytes.

On `.ai-scratch/task035/signed-release/FSD.app`, a COPY of fresh Release, inner-then-outer ad-hoc signing passed, then app deep/strict and helper strict validity passed; -dv reports adhoc and no TeamIdentifier. Signed helper byte equality is not claimed or required. Exact recorded metadata/signing commands:

- `/usr/bin/file /tmp/FSD-P15-Final-Debug/Build/Products/Debug/FSD.app/Contents/Helpers/FSDClassificationHostSeam` → exit 0, 0.009 s.
- `/usr/bin/lipo -info /tmp/FSD-P15-Final-Debug/Build/Products/Debug/FSD.app/Contents/Helpers/FSDClassificationHostSeam` → exit 0, 0.030 s.
- `/usr/bin/xcrun vtool -show-build /tmp/FSD-P15-Final-Debug/Build/Products/Debug/FSD.app/Contents/Helpers/FSDClassificationHostSeam` → exit 0, 0.027 s.
- `/usr/bin/otool -L /tmp/FSD-P15-Final-Debug/Build/Products/Debug/FSD.app/Contents/Helpers/FSDClassificationHostSeam` → exit 0, 0.032 s.
- `/usr/bin/file /tmp/FSD-P15-Final-Release/Build/Products/Release/FSD.app/Contents/Helpers/FSDClassificationHostSeam` → exit 0, 0.005 s.
- `/usr/bin/lipo -info /tmp/FSD-P15-Final-Release/Build/Products/Release/FSD.app/Contents/Helpers/FSDClassificationHostSeam` → exit 0, 0.022 s.
- `/usr/bin/xcrun vtool -show-build /tmp/FSD-P15-Final-Release/Build/Products/Release/FSD.app/Contents/Helpers/FSDClassificationHostSeam` → exit 0, 0.035 s.
- `/usr/bin/otool -L /tmp/FSD-P15-Final-Release/Build/Products/Release/FSD.app/Contents/Helpers/FSDClassificationHostSeam` → exit 0, 0.023 s.
- `/usr/bin/codesign --force --sign - .ai-scratch/task035/signed-release/FSD.app/Contents/Helpers/FSDClassificationHostSeam` → exit 0, 0.024 s.
- `/usr/bin/codesign --force --sign - .ai-scratch/task035/signed-release/FSD.app` → exit 0, 0.033 s.
- `/usr/bin/codesign --verify --deep --strict --verbose=2 .ai-scratch/task035/signed-release/FSD.app` → exit 0, 0.030 s.
- `/usr/bin/codesign --verify --strict --verbose=2 .ai-scratch/task035/signed-release/FSD.app/Contents/Helpers/FSDClassificationHostSeam` → exit 0, 0.013 s.
- `/usr/bin/codesign -dv --verbose=4 .ai-scratch/task035/signed-release/FSD.app` → exit 0, 0.009 s.
- `/usr/bin/codesign -dv --verbose=4 .ai-scratch/task035/signed-release/FSD.app/Contents/Helpers/FSDClassificationHostSeam` → exit 0, 0.010 s.

No Developer ID, notarization or App Store readiness is claimed. Artifact rebuild reproducibility and final linked-source engineering notice/dependency closure are accepted historical task033A/task034 evidence; task035 does not claim to have rerun those controlled Go builds or inventories. Construction-time false acceptance flags in the immutable manifest/contract and old handoffs are dated evidence; current BRAIN acceptance comes from STATE/the supplied decision, not rewriting artifacts.

## Runtime observation and claim limits — AGENT-OBSERVED / INFERRED / MANUAL NOT PERFORMED

Six fresh committed-helper PNG launches used empty environment and stdin-only bytes. While each helper was alive with stdin held open after the PNG header, `/usr/sbin/lsof -nP -a -p <recorded pid> -i` exited1 with no socket output/error, and `/usr/bin/pgrep -P <recorded pid>` exited1 with no descendant output/error. Closing stdin then produced one classified PNG envelope, exit0 and stderr0 for every run. Exact pids/commands/durations are in ignored process-observation.json. This is a bounded observation of those runs, not continuous syscall tracing or a universal observation.

**INFERRED:** the accepted exact artifact SHA and independently audited no-net/no-os/exec dependency/API closure corroborate the observed offline/process isolation behavior. The helper receives no source authority; this does not mean its binary contains no general file-opening symbol (accepted timezone/runtime detail remains). No universal classifier determinism or historical content equality follows.

General realistic legacy DOC/XLS/PPT determinism remains unproven.
Available pinned realistic PNG/DOCX/XLSX/PPTX bounded fixtures were single-valued in accepted implementation/audit evidence.
The demonstrated short legacy-CFB ambiguity is neutralized by the guard.

The guard remains only `len(input) <= 513 && prefix D0 CF 11 E0 -> noMatch before Match`; no guard broadening, source extension, upstream priority patch or synthetic-to-realistic fixture claim. Point-in-time source/capture standards and the accepted provider whitespace-normalization advisory remain unchanged. Proposed classifier memory-budget wording is not a measured8192-byte helper/process-memory guarantee and is not claimed here. **MANUAL NOT PERFORMED:** NOT PERFORMED — DEFERRED BY OWNER; no visual UI, VoiceOver or physical-media acceptance substituted by automated/agent evidence.

## Canonical document delta and KI-025 — verified status only

Only ARCHITECTURE§9/§9a, DECISIONS ADR031/032/035 status notes, SECURITY§2.1 inventory/status, TEST_PLAN§9 evidence/status, MVP Phase1.5 dependency pointers and PRODUCT_STATE Phase1.5/KI025/residual risks were synchronized after all mandatory gates passed. Historical decision semantics/receipts and prior handoffs remain intact. The integration contract, helper, manifest, notices, build script, source/tests/Xcode/schema/Go module files and rule-promotion ledger are unchanged.

KI-025's canonical pre-task meaning in PRODUCT_STATE was three absences: runtime, durable separate provider identity and real external helper verification. Those exact absence conditions are now satisfied by physical runtime, schema-v9 provenance and accepted independently audited real-helper evidence; the implementation gap is CLOSED without redefining it. Independent final runtime audit, BRAIN Phase1.5 acceptance and deferred manual acceptance remain separate gates. Existing unrelated product/UX/startup/hygiene limitations remain unchanged.

## Requirement map and execution postflight (28 task groups)

1 E physical re-anchor, clean baseline, non-destructive fetch, identity/branch/upstream and all three SHA ancestries; authority reads above.
2 E supplied BRAIN decision projected first in separate known commit; gates/provider accepted exactly as supplied; one ACTION035; rule ledger/Phase1.5 final acceptance preserved.
3 E task034 Reviewer-only telemetry process advisory preserved; task035 no Go/global configuration action.
4 E verification/documentation-only objective fulfilled; zero production/test defect repair.
5 E immutable source/default metadata-only/snapshot/interruption/no-false-content invariants and exact classifier boundaries retained in current suites/source.
6 E accepted filetype/helper SHA/module/detector/host provenance and no-Go normal-build facts verified against physical bytes/builds.
7 E six-doc subsection allowlist plus authorized STATE/handoff/Desktop finalizer surfaces only.
8 E protected Swift/tests/schema/Xcode/helper/module/dependency/rules/history bytes unchanged.
9 E new clean Debug, full Debug XCTest and clean Release receipts with exact current commands/exits/durations/counts.
10 E complete focused classifier, selected-entry, repository, invocation/security, comparison/export suites; actual helper mandatory; zero focused skips.
11 E schema9 migration/integrity/foreign-key/legacy provenance/append-only/duplicate/immutable facts reran.
12 E actual fresh Debug/Release bundles: exact paths, helper SHA/arm64/minos/provenance/notices, no unexpected Helpers executable or Go/model/database/downloader artifact.
13 E actual-helper success/noMatch/missing/crash/hang-timeout/cancel/stale/generation/4096/4097/CFB; production-pump cap fault injection explicitly distinguished.
14 E Data-only capability reflection/hostile-provider and no-follow single4096 source-read authority; no sample/path/hash/log persistence.
15 E real noMatch zero rows; typed mapping/provenance nil model/confidence; cancellation prevents later success; snapshot/entry immutability.
16 E eight named forbidden workflows each zero-invocation; explicit selected-entry sole trigger; no bulk/background/queue/retry/watcher/backfill.
17 E comparison semantics and JSON version1 byte/export isolation; deleted-source offline usability without physical-media claim.
18 E six bounded real-helper socket/descendant observations combined with accepted static artifact closure; no Go introspection.
19 E unsigned helper byte identity; scratch COPY Release ad-hoc deep/strict package validity; distribution claims excluded.
20 E verbatim legacy Office advisory and exact <=513 guard; pinned realistic vs synthetic evidence distinct.
21 E AUTOMATED VERIFIED / AGENT-OBSERVED / INFERRED / MANUAL NOT PERFORMED categories and current vs historical receipts distinct.
22 E canonical permitted status synchronization only after all mandatory current gates passed; no historical receipt rewrite.
23 E KI025 exact three-absence definition inspected and satisfied; implementation gap disposition separate from final acceptance.
24 N/A manual visual UI/VoiceOver/physical-media execution explicitly deferred by Owner; required manual state preserved verbatim.
25 E no required gate failure/hidden classifier skip/source-authority violation/forbidden mutation/unavailable completion evidence found; no repair performed.
26 E successful Writer verification/handoff remains pending BRAIN and independent final audit; Phase1.5 not finally accepted.
27 E sole proposal036 only; no final audit/self-audit/next task started.
28 E candidate diff/scope/history/rules and exact output preparation verified; publication/checker/Git/Desktop closure is the finalizer's subsequent work, recorded in Desktop/ignored closure receipts after execution, not preclaimed here.

No material execution requirement is UNPROVEN. Fresh candidate postflight checked exact task, all required gates, complete diff/status, protected history/rules, physical identities, allowlist and absence of next-task work. This immutable source necessarily cannot contain its own future publication SHA or preclaim future checker/push results. Canonical finalizer publishes the known reviewed candidate, refreshes the final Desktop Git receipt, requires clean/synced ahead0/behind0 and reruns the checker; final Worker success waits for those physical closure checks.

## Ownership, recovery and next boundary

Worker evidence only; task035 classification stays PENDING_BRAIN. Accepted STATE still authorizes ACTION035; the sole036 proposal in HOT is not active-next authorization. BRAIN reviews the canonical Writer evidence and independently routes the required final audit; this Writer neither performs that audit nor finally accepts Phase1.5. Manual acceptance remains deferred. Stop after publication/return.

Ignored RAW recovery: `.ai-scratch/task035/` baseline/task-lock receipts; debug-build/full-debug/release-build/focused/schema-safety logs, command JSON and unique xcresults; independently cross-checked per-suite counts and xcresult summaries; embedded-buildinfo.txt; bundle-signing-receipts.json and signed-release COPY; process-observation.json; reviewed draft and canonical-checker/pre/postpublication receipts. Essential evidence and scope are preserved in this one handoff; RAW is reference-first. Desktop recovery transport embeds exact canonical Operator and full CURRENT, with final Git/closure facts outside immutable history.
