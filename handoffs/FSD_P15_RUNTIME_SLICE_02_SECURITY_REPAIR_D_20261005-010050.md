# P15 Slice 02 bounded source-authority security repair

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_P15_RUNTIME_SLICE_02_SECURITY_REPAIR_D_20261005-010050.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=1e6f72b8f329fff5fe54234037b3af3d02e803ed
REMOTE_HEAD=7b0012ed956afaff927ee8ad7d111266d7efb16e
LAST_VERIFIED_AT=2026-10-05T01:00:50+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|STATE/PROJECT_STATE.md|docs/P15_RUNTIME_PLAN.md|docs/ARCHITECTURE.md|docs/SECURITY_AND_READ_ONLY_POLICY.md|docs/DECISIONS.md|docs/TEST_PLAN.md|handoffs/FSD_P15_RUNTIME_SLICE_02_SOURCE_AUTHORITY_AUDIT_R_20261004-222405.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_P15_RUNTIME_SLICE_02_SECURITY_REPAIR_014
STATUS=EXECUTION_VERIFIED_PENDING_PUBLICATION_AT_CAPTURE
BLOCKER=NONE
PROPOSED_NEXT=FSD_P15_RUNTIME_SLICE_02_SECURITY_REAUDIT_015
NO_AUTO_NEXT=YES

## Task lock / execution guard

TASK_ID=FSD_P15_RUNTIME_SLICE_02_SECURITY_REPAIR_014
ROLE=WORKER
MODE=BOUNDED_SOURCE_AUTHORITY_SECURITY_REPAIR
BASE_HEAD=7b0012ed956afaff927ee8ad7d111266d7efb16e
UPSTREAM_HEAD_AT_PREFLIGHT=7b0012ed956afaff927ee8ad7d111266d7efb16e
TECHNICAL_SHA=1e6f72b8f329fff5fe54234037b3af3d02e803ed
REVIEWED_IMPLEMENTATION_SHA=1316b937ebd74d07a990bf0d2f59210a039e58c2
AUDIT_PUBLICATION_SHA=73ec848b69b13ca253f3748f16c96be801f97c4a
AUDIT_HANDOFF=handoffs/FSD_P15_RUNTIME_SLICE_02_SOURCE_AUTHORITY_AUDIT_R_20261004-222405.md
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=F1_PRE_READ_OBJECT_AUTHORITY;F2_CANCELLATION_PRECEDENCE;F3_CAPTURE_ADMISSION_PROOF;OWNER_AUTHORIZED_CHECKER_PREDICATE_REPAIR
ALLOWED_PATHS=FSD/Classification/BoundedClassificationSourceReader.swift|FSD/Catalog/SnapshotWriter.swift|FSDTests/ClassificationSourceReaderTests.swift|FSDTests/SnapshotHistoryTests.swift|docs/P15_RUNTIME_PLAN.md|scripts/check_control_plane.py|handoffs/FSD_P15_RUNTIME_SLICE_02_SECURITY_REPAIR_D_20261005-010050.md|handoffs/CURRENT_HANDOFF.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl
FORBIDDEN_PATHS=ALL_OTHER_TRACKED_PATHS;PROVIDER;DETECTOR;ENTRY_CLASSIFICATION_REPOSITORY;SCHEMA_SQL_MIGRATIONS;SCANNER;UI_SEARCH_COMPARE_EXPORT;HELPER_RUNTIME_SLICE03;DEPENDENCIES;STATE/PROJECT_STATE.md;STATE/RULE_PROMOTION_LEDGER.tsv;HISTORICAL_HANDOFFS
SUCCESS_CRITERIA=CAUSAL_RED_F1_F2_F3;PERMANENT_REGRESSIONS_GREEN;LOCKED_OBJECT_AUTHORITY;ONE_READ;ADMISSION_ROLLBACK;FRESH_BUILD_FOCUSED_FULL;EXACT_SCOPE_RETURN
VALIDATIONS=CAUSAL_RED;CLEAN_DEBUG_BUILD;103_FOCUSED;384_FULL_DEBUG;CHECKER_PREDICATE_MATRIX;DIFF_SCOPE_PARITY;FINALIZER_CANONICAL_CHECKER
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
WORKER_RESULT=PASS_WITH_ADVISORY
RESULT_AUTHORITY=WORKER_EVIDENCE_ONLY

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=27
WORKER_REQUIREMENTS_EVIDENCED=27
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

## Authority / baseline / scope exception

FACT: initial local main was audit publication 73ec848, origin/main one BRAIN control commit ahead at exact expected 7b0012ed956afaff927ee8ad7d111266d7efb16e. Inspected ancestry/diff: only accepted STATE, audit ledger classification, and BRAIN events. Non-destructive fetch and git pull --ff-only origin main applied that existing canonical commit without a new merge commit/history rewrite. Pre-edit root/branch/HEAD/upstream were exact expected main, 0/0 and tracked/untracked clean. Owner ignored material retained; no reset/clean/stash/rebase/force/discard.

Loaded AGENTS, task-execution with WORKER, accepted STATE, CURRENT HOT, applicable Compact rules and direct product authorities; read the complete accepted audit. Accepted state records audit_013 as accepted REPAIR, task_014 active, Slice 03 blocked. Source bytes, not earlier implementer claims, govern the repair.

OWNER_EXPLICIT_SCOPE_EXCEPTION=scripts/check_control_plane.py accepted-classification predicate only.
Baseline checker required LAST_ACCEPTED_TASK classification PASS/PASS_WITH_ADVISORY, conflicting with the BRAIN-accepted Reviewer REPAIR at this baseline. Before changing it, asked a concrete scope question: permit REPAIR only for EXECUTOR=REVIEWER and STATUS=ACCEPTED, preserving every other check. Owner answered exactly: "Cho phép sửa checker trong phạm vi trên". This authorizes the additional checker path; no STATE/ledger acceptance rewrite or broader checker change. The original production predicate evaluated false on the actual accepted Reviewer REPAIR row (causal RED); fixed predicate runs 8 positive/negative production-expression cases, all correct. Independent re-audit remains mandatory; this Worker does not perform it.

## Concrete implementation

### F1 — pre-read object authorization

After existing no-follow final open + regular fstat/dev+ino check, the opened fd remains pinned in the initial DescriptorBag. Before payload I/O, validateOpenedAuthority freshly detects exact recorded volumeIdentifier and physical mount, rewalks validated root + parent components from that mount using existing no-follow primitives, compares every directory by both device/inode against the originally acquired chain, and performs final statNoFollow from the fresh parent. Its regular-file device/inode must equal the opened fd.

Any failed barrier maps existing typed source/error outcomes with zero payload reads. Cancellation is observed after the barrier and again immediately before the single read. The fd/object just authorized is the capability: a later namespace rename cannot redirect that fd to a different object. Post-read metadata revalidation still detects persistent namespace/source changes and can return sourceChanged. No perpetual pathname stability/atomic namespace lock is claimed.

The same small metadata-only helper is reused for post-read source/path revalidation. There is still exactly one production Darwin.read callsite and one reader invocation of readOnce, maximum 4096, fresh file fd offset zero, no seek/tail/fill/retry. No provider/source-capability changes.

### F2 — late cancellation completion boundary

finishAfterRead is used only after the payload attempt starts. Every terminal post-read failure, short-read/truncation path, fd identity error, source/walk/final stat failure/mismatch, constructor failure and prefix handoff passes through cancellation observation. Immediate post-attempt cancellation remains. It wins over late failed/sourceChanged, without retry. Genuine earlier pre-read sourceChanged/unsupported results never pass through that post-read completion helper.

Existing EINTR and read+disappearance cancellation RED repairs remain green. New late-error schedules run once with cancellation=false to preserve original mapping and once with cancellation=true to prove precedence, with exactly one read in both cases.

### F3 — pin proof through capture admission

SnapshotWriter.beginCapture now receives a private RootLocatorProof rather than a detached locator String. Direct lexical proof contains no alias token and both admission validations perform no alias filesystem I/O. AliasRootProof retains the actual no-follow candidate directory fd plus sampled device/inode and selected/canonical/mount/component context. Candidate construction still occurs exactly once, from POSIX realpath of selected capture root only; revalidations reuse that one stored candidate, with no alternate derivation/fallback.

Inside the existing SQLite transaction, immediately before snapshot INSERT and again after root INSERT/totals but before transaction acceptance, current selected-root and canonical-root associations, a fresh no-follow physical-candidate walk, and the pinned fd must all identify the original directory object. Substitution fails with sourceRootNotWithinMount; the existing transaction rolls back snapshot/root/volume admission. A deferred withExtendedLifetime keeps the proof alive through transaction completion or rollback; token deinit closes the pinned fd. Ancestor/fresh-walk fds are closed on all paths.

ROOT_LOCATOR_PROOF=POINT_IN_TIME_CAPTURE_ADMISSION_PROOF
After successful admission, later namespace changes are ordinary live-source changes; this is not a namespace lock. The internal rootRelativePath String helper remains locator inspection for existing tests; production admission never consumes its detached string. The narrow internal Writer observer schedules fixture actors after preparation / row insertion; production default is nil and no callback is passed to a provider.

### Permanent tests / documentation / checker

Added 14 reader tests and 5 history tests in the two allowed test files. Existing reader-private wrapper remains backed by real Darwin operations; new hooks schedule actor mutation/error/cancellation at precise stat/open/read boundaries. Actor mutations affect only owned disposable fixtures. In-memory test lastReadBytes proves the post-barrier fd read original bytes rather than a newly substituted object; no real sampled payload is persisted/logged by production.

Adjusted existing post-read identity-substitution schedule to execute after the now-added pre-read source detect; it asserts one actual read and three detections. Strengthened initial-disappearance coverage to assert zero reads. Updated only P15 plan Slice 02 for object-barrier authority, token admission checks, point-in-time semantics and late cancellation. Before/after all other slice bytes are identical.

Checker delta is only its accepted-classification guard: original PASS variants remain admitted; REPAIR additionally requires exactly REVIEWER + ACCEPTED. WORKER/ACCEPTED/REPAIR, Reviewer pending-status REPAIR, PENDING_BRAIN, STOP and OWNER_DECISION remain rejected by this predicate. All ownership/scope/history/ancestry/event/guard/parity checks are unchanged. Full canonical checker is executed by finalizer after projecting the return; predicate matrix alone is not whole-checker proof.

## Requirement / evidence map

All EVIDENCED from source, actual tests, Git and command receipts; no material UNPROVEN.

| # | Requirement | Evidence |
|---|---|---|
| 1 | Expected canonical preflight, preservation, authorities | Exact 7b0012e main/origin 0/0 clean before edit; inspected FF; mandatory reads; no destructive Git operation. |
| 2 | Causal RED for three findings | Corrected RED 83 tests/27 assertion failures/0 unexpected, before semantic repair. F1 readCalls1 vs0, F2 wrong terminal mapping, F3 accepted rows vs rejection/rollback. |
| 3 | Acquired parent outside before final stat | testAcquiredParentRenamedOutsideBeforeFinalStatReadsNothing: real outside child substitution, sourceChanged, readCalls0, no bytes. |
| 4 | Acquired parent outside after file open | testAcquiredParentRenamedOutsideAfterOpenBeforeBarrierReadsNothing: sourceChanged/readCalls0. |
| 5 | Fresh parent different directory | testFreshAuthorityParentDifferentDirectoryReadsNothing, dev+ino chain check/readCalls0. |
| 6 | Fresh final different file | testFreshAuthorityFinalDifferentFileReadsNothing, fresh final vs opened object/readCalls0. |
| 7 | Fresh exact current source identity | testPreReadAuthorityRequiresFreshExactVolumeIdentity, exact mismatch/readCalls0; unchanged exact mount guard and missing-source tests. |
| 8 | Authority green / one read | testUnchangedAuthorityBarrierPerformsExactlyOnePayloadRead: three metadata walks/final stats, one 4096-byte payload call. |
| 9 | Authorized pinned object after namespace move | testNamespaceMoveAfterBarrierCannotRedirectPinnedFile: original bytes read once, substitute never read, sourceChanged after validation. |
| 10 | Cancellation after barrier / pre-payload | testCancellationAfterAuthorityBarrierBeforePayloadReadsNothing: cancelled/readCalls0. |
| 11 | Late fd stat failure cancellation | testCancellationDuringLateFDStatFailureWins: true cancelled, false failed, one read. |
| 12 | Late source detect failure cancellation | testCancellationDuringLateSourceDetectionFailureWins: true cancelled, false sourceChanged, one read. |
| 13 | Late directory walk failure cancellation | testCancellationDuringLateDirectoryWalkFailureWins: true cancelled, false sourceChanged, one read. |
| 14 | Late final stat / identity cancellation | testCancellationDuringLateFinalStatFailureWins and testCancellationDuringLateFinalIdentityMismatchWins; true cancelled, false failed/sourceChanged, one read. |
| 15 | Existing repairs / pre-read genuine outcomes | EINTR and concurrent disappearance cancellation tests retained; testPreReadGenuineOutcomesAreNotMaskedByFutureCancellation green. |
| 16 | Pinned alias token retained through admission | Private AliasRootProof holds real fd, deferred lifetime through transaction; pre/post validations compare pinned identity with both selected/canonical and fresh physical associations. |
| 17 | Replacement before admission rejected | testAliasCandidateReplacedAfterProofBeforeAdmissionRejectsCapture: actor reached after genuine proof, no admitted capture/entries/volumes. |
| 18 | Candidate replacement during admission rollback | testAliasCandidateReplacedDuringAdmissionRollsBackCapture: snapshot/root present inside transaction, zero rows after rejection. |
| 19 | Canonical replacement during admission rollback | testCanonicalPathReplacedDuringAdmissionRollsBackCapture, sourceRootNotWithinMount and whole admission rolled back. |
| 20 | Unchanged alias / direct no alias I/O | testUnchangedAliasProofAdmitsCaptureThroughBothTransactionBoundaries and testDirectLexicalCaptureNeverEntersAliasProofAdmission; existing direct missing-path/root/nested locator tests retained. |
| 21 | Canonical single candidate / no entry realpath | One physicalCandidate derivation; no /var mapping/firmlink parser/second candidate. Only capture root uses realpath. Detector unchanged. |
| 22 | 4096/one-read/no-follow/data-only/no source writes | Source inspection + focused below/exact/above/short/EINTR/unsupported/escape/provider tests; provider bytes unchanged; no new source writes/network/sample storage/hash/log API. |
| 23 | Schema/legacy/immutability/default workflows preserved | Protected paths byte-identical; legacy/no-backfill/fingerprint tests; full comparison/export/capture/lifecycle suite green. |
| 24 | Exact P15 Slice-02 projection | Outside Slice-02 plan prefix/suffix byte parity; no ADR/other docs/schema/Scanner/provider change. |
| 25 | Owner-authorized checker predicate | Actual baseline causal rejection + 8/8 actual-production-predicate matrix; exact narrow diff and explicit Owner scope approval. |
| 26 | Required fresh executable validations | Clean Debug build exit0; final focused 103/103, no skip/fail; full 384 executed, 381 pass, 3 external skips, 0 fail, exit0. |
| 27 | Fresh postflight / scope / no next task | Re-fetched base, inspected full six-path diff, protected parity and no untracked; technical candidate committed. Finalizer closure pending at immutable capture, terminal claim waits for actual publication/parity/checker verification. |

## Completion gates observed

F1_PARENT_RENAME_OUTSIDE_ZERO_READ=PASS
F1_PRE_READ_REBIND=PASS
F1_OPENED_OBJECT_AUTHORITY=PASS
F2_PRE_PAYLOAD_CANCEL=PASS
F2_LATE_FSTAT_CANCEL=PASS
F2_LATE_DETECT_CANCEL=PASS
F2_LATE_WALK_CANCEL=PASS
F2_LATE_FINAL_STAT_CANCEL=PASS
CONTENT_READ_RETRY=NONE
F3_PROOF_TOKEN_RETAINED_THROUGH_ADMISSION=PASS
F3_REPLACEMENT_BEFORE_ADMISSION=REJECTED
F3_REPLACEMENT_DURING_ADMISSION=REJECTED
F3_TRANSACTION_ROLLBACK=PASS
MAX_BYTES=4096
CONTENT_READ_CALLS<=1
NOFOLLOW=PASS
EXACT_VOLUME_IDENTITY=PASS
DATA_ONLY_PROVIDER_UNCHANGED=YES
SOURCE_WRITE=NONE
NETWORK=NONE
SAMPLE_PERSISTENCE=NONE
FILESYSTEM_DETECTOR_DELTA=NONE
SCHEMA_DELTA=NONE
SLICE_03_DELTA=NONE
FOCUSED=PASS
FULL_DEBUG=PASS

## Commands / real receipts / investigated failure

DerivedData /tmp/FSD-P15-S02-Repair-DerivedData was absent at task start; all execution evidence is grouped there or named /tmp/FSD-P15-S02-Repair-*.log.

```sh
xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-P15-S02-Repair-DerivedData -only-testing:FSDTests/ClassificationSourceReaderTests -only-testing:FSDTests/SnapshotHistoryTests
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-P15-S02-Repair-DerivedData clean build
xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-P15-S02-Repair-DerivedData -only-testing:FSDTests/ClassificationSourceReaderTests -only-testing:FSDTests/SnapshotHistoryTests -only-testing:FSDTests/ClassificationProviderContractTests -only-testing:FSDTests/ClassificationEnrichmentTests
xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-P15-S02-Repair-DerivedData
git diff --check
```

Initial RED log /tmp/FSD-P15-S02-Repair-RED.log: 83 executed, 19 assertions including 4 unexpected fixture errors. F1/F2 causal; F3 setup failed at physical-candidate stat with ENOENT. Investigated locally: Foundation resolvingSymlinksInPath left /var presentation while POSIX realpath returned /private/var. Corrected only new fixture canonicalization using POSIX realpath; no production repair yet, no contract/test weakening.
Causal RED /tmp/FSD-P15-S02-Repair-RED-causal.log: exit65, 83 executed, 27 assertion failures, 0 unexpected; all three accepted findings causally reproduced. Writer observer at this stage only scheduled actors around original detached-string admission, default nil.
Initial minimal GREEN /tmp/FSD-P15-S02-Repair-GREEN.log: exit0, 102/102, no failures/skips.
Clean build /tmp/FSD-P15-S02-Repair-clean-build.log: exit0, CLEAN SUCCEEDED, BUILD SUCCEEDED.
Final focused /tmp/FSD-P15-S02-Repair-focused.log: exit0, 103/103 (56 reader + 28 history + 9 provider + 10 enrichment), 0 skip/fail.
Full /tmp/FSD-P15-S02-Repair-full-debug.log: exit0, TEST SUCCEEDED, 384 executed/381 passed/3 skipped/0 failures. Test-manager elapsed 4150.945 s; XCTest suite elapsed 4137.718 s. Long full run includes all 100k/1M comparison, navigation, determinism, disposal, memory, generation, export and reopen gates; no repeat/bypass of the full run.
Full xcresult: /tmp/FSD-P15-S02-Repair-DerivedData/Logs/Test/Test-FSD-2026.10.04_23-45-27-+0700.xcresult.
Checker predicate matrix: ExecutionEvidence/checker-predicate-matrix.json under the same DerivedData; 8/8 source-expression cases plus Python syntax compile. It evaluates the actual AST production predicate, not a duplicated test implementation; does not replace whole-checker finalization.

## Advisories / limits

Three full-suite skips are external fixtures: FSDProbeSeedTests.testSeedIsolatedProbeCatalog (no FSD_PROBE_CATALOG/marker), FilesystemMatrixTests.testCaptureExternallyPreparedMountedFilesystem (no FSD_MATRIX_SOURCE), and testReopenCapturedSnapshotWithTheSourceDetached (no FSD_MATRIX_OFFLINE_CATALOG). None is claimed passed. New deterministic reader schedules and actual Data-volume alias admission tests all executed, without skip.

Observed build/focused warnings: AppIntents metadata extraction skipped because app has no AppIntents dependency; signed Apple test framework binaries not stripped; macOS-13 target test bundle links installed XCTest/XCTestSwiftSupport built for 14.0. These are real toolchain warnings, not hidden tests or new production dependencies. Full incremental test log has no warning/error lines; the earlier warnings remain recorded here. No release compatibility/distribution acceptance is claimed by Debug tests.

These repairs implement the BRAIN-authorized point-in-time object/admission barriers, not filesystem namespace locking or retroactive content equivalence. Classification still describes live inferred bytes. Fresh independent security re-audit is mandatory before Slice 03; no self-audit acceptance or future task execution.

## Postflight / publication capture

FACT: exact task requirements mapped above against fresh candidate. Full diff inspected; only six authorized implementation/test/doc/checker paths changed. The checker path is the explicit Owner exception; provider/Detector/Repository/Scanner/schema/Xcode/other slices/product paths, accepted STATE/rule ledger and all historical handoffs remain unchanged. No new untracked project files, no next task.

Technical commit 1e6f72b8f329fff5fe54234037b3af3d02e803ed contains the six reviewed paths. At immutable capture main is ahead1/behind0, clean, origin/main=7b0012ed956afaff927ee8ad7d111266d7efb16e; fetch receipt fresh. Finalizer now projects exactly one immutable handoff/CURRENT, one Worker row with pending BRAIN classification and one append-only Worker event, preserves BRAIN-owned Desktop prior fields, embeds exact Operator and full CURRENT. Checker/push/fetch/final receipt/parity are pending at capture; final terminal return is conditional on their actual completion. Publication SHA is resolved externally with git log -1 --format=%H -- <handoff>; no self-containing publication SHA or bookkeeping commit. BRAIN acceptance/active next stay untouched. Return and stop.
