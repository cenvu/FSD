# P15 Slice 06 cross-workflow and security regression matrix

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_P15_RUNTIME_SLICE_06_CROSS_WORKFLOW_SECURITY_REGRESSION_MATRIX_D_20261006-034630.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=6093665c4339717313e4348396e97cf7de243849
REMOTE_HEAD=0cb948a0e27dc9cbbedf4900b3164143e3f3aef4
LAST_VERIFIED_AT=2026-10-06T03:46:30+07:00
AUTHORITY_PTRS=AGENTS.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|STATE/PROJECT_STATE.md|docs/P15_RUNTIME_PLAN.md|docs/TEST_PLAN.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_P15_RUNTIME_SLICE_06_CROSS_WORKFLOW_SECURITY_REGRESSION_MATRIX_024
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_WITHIN_SLICE06;BRAIN_ADJUDICATION_PENDING
PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_FSD_P15_SLICE_06_ADJUDICATION
NO_AUTO_NEXT=YES

## Task lock and Worker-local result

TASK_ID=FSD_P15_RUNTIME_SLICE_06_CROSS_WORKFLOW_SECURITY_REGRESSION_MATRIX_024
ROLE=WORKER
MODE=TESTS_ONLY_CROSS_WORKFLOW_SECURITY_VERIFICATION
BASE_HEAD=0cb948a0e27dc9cbbedf4900b3164143e3f3aef4
UPSTREAM_HEAD_AT_ADMISSION=0cb948a0e27dc9cbbedf4900b3164143e3f3aef4
TECHNICAL_SHA=6093665c4339717313e4348396e97cf7de243849
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=P15_SLICE06_ONLY;TESTS_FIXTURES_PROJECT_WIRING;SECTION9_TRACEABILITY_LEDGER;EIGHT_FORBIDDEN_WORKFLOWS_ZERO_INVOCATION;ADVERSARIAL_PROVIDER_A_B_C;PERSISTENCE_ISOLATION_EXPORT_OFFLINE_SCHEMA_PROCESS_BOUNDARY
ALLOWED_PATHS=FSDTests/ClassificationInvocationIsolationTests.swift|FSDTests/ClassificationSecurityIntegrationTests.swift|FSDTests/ClassificationSourceReaderTests.swift|FSDTests/ClassificationProviderContractTests.swift|FSDTests/BundledMagikaClassificationProviderTests.swift|FSDTests/ClassificationRuntimeServiceTests.swift|FSDTests/SnapshotBrowserClassificationTests.swift|FSDTests/ClassificationEnrichmentTests.swift|FSDTests/ComparisonSemanticsTests.swift|FSDTests/JSONExportTests.swift|FSDTests/TestSupport.swift|FSD.xcodeproj/project.pbxproj|handoffs/FSD_P15_RUNTIME_SLICE_06_CROSS_WORKFLOW_SECURITY_REGRESSION_MATRIX_D_20261006-034630.md|handoffs/CURRENT_HANDOFF.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl
DESKTOP_TRANSPORT=/Users/cenvu/Desktop/04_FSD_BRAIN.md
FORBIDDEN_PATHS=ALL_PRODUCTION_SWIFT;SCHEMA_SQL;MIGRATION_SQL;VERIFY_SQL;PRODUCT_DESIGN_DOCS;P15_PLAN;TEST_PLAN;HELPER_BINARY_TARGET;DEPENDENCY_MANIFESTS;UNRELATED_TESTS;STATE/PROJECT_STATE.md;STATE/RULE_PROMOTION_LEDGER.tsv;PRIOR_HANDOFFS;SLICE07
SUCCESS_CRITERIA=SECTION9_ALL_ACCOUNTED;EIGHT_WORKFLOWS_INDEPENDENT_ZERO_INVOCATION;ADVERSARIAL_A_B_C_PROVEN;NO_PAYLOAD_HASH_PATH_PERSISTENCE;ENTRY_SNAPSHOT_IMMUTABLE;COMPARISON_ISOLATION;JSON_EXPORT_STABLE;DETACHED_SOURCE_OFFLINE;SCHEMA_V9_SAFE;HOST_NETWORK_NONE;FOCUSED_FULL_PASS
VALIDATIONS=CLEAN_DEBUG_BUILD;FOCUSED_NINE_CLASS_XCTEST;FULL_DEBUG_XCTEST;GIT_DIFF_CHECK;FINALIZER_CHECKER_PUBLICATION_PARITY
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
WORKER_RESULT=PASS
RESULT_AUTHORITY=WORKER_EVIDENCE_ONLY;NO_BRAIN_ACCEPTANCE

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=42
WORKER_REQUIREMENTS_EVIDENCED=40
WORKER_REQUIREMENTS_NOT_APPLICABLE=2
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

PRODUCTION_DELTA=NONE
PRODUCT_DOC_DELTA=NONE
SCHEMA_DELTA=NONE
HELPER_DELTA=NONE
DEPENDENCY_DELTA=NONE
TEST_PLAN_DELTA=NONE
P15_PLAN_DELTA=NONE
TEST_PLAN_9_ITEMS_ACCOUNTED=ALL_31_PLUS_3_ADVERSARIAL_PLUS_8_WORKFLOWS
TEST_PLAN_9_UNEXPLAINED_GAPS=0
TEST_PLAN_9_NEW_GAPS_CLOSED=13
FORBIDDEN_WORKFLOWS_INDEPENDENT_ZERO_INVOCATION=8/8
ADVERSARIAL_PROVIDER_PATH_AUTHORITY=DENIED
ADVERSARIAL_PROVIDER_ADDITIONAL_BYTE_API=NONE
ADVERSARIAL_PROVIDER_SOURCE_BYTES_MAX=4096
ADVERSARIAL_PROVIDER_PERSISTED_EFFECT=NONE
PAYLOAD_PERSISTENCE=NONE
BYTE_SAMPLE_PERSISTENCE=NONE
CONTENT_HASH_PERSISTENCE=NONE
ABSOLUTE_SOURCE_PATH_PERSISTENCE=NONE
RAW_PROVIDER_DIAGNOSTIC_PERSISTENCE=NONE
ENTRY_SNAPSHOT_MUTATION=NONE
COMPARISON_ISOLATION=PASS
JSON_EXPORT_STABILITY=PASS
DETACHED_SOURCE_OFFLINE=PASS
SCHEMA_V9_EXPECTED_STATE=PASS
HOST_NETWORK_CAPABILITY=NONE
REAL_HELPER_NETWORK_EVIDENCE=SLICE07_EXTERNAL_HELPER_ONLY
REAL_HELPER_EXECUTED=NONE
PROCESS_BOUNDARY_REGRESSIONS=PASS
NEW_TEST_METHODS=19
FOCUSED=PASS
FULL_DEBUG=PASS
MANUAL_UI_ACCEPTANCE=DEFERRED_BY_OWNER
VOICEOVER_MANUAL_ACCEPTANCE=DEFERRED_BY_OWNER

No separate independent audit is required solely for this mechanical test slice. Its §9 coverage ledger is mandatory input to the Slice 07 external integration gate and the final independent audit. BRAIN must adjudicate this Worker return before any next authorization; this record authorizes nothing.

## Reanchor and bounded authority

FACT: local main was clean at 3e4fc96e39a433ef0258b2a3056c336955c8cf75 while the task expected canonical HEAD 0cb948a0e27dc9cbbedf4900b3164143e3f3aef4, which was absent from the local object store. A non-destructive `git fetch origin main` resolved it truthfully: origin/main had advanced by exactly three BRAIN commits (f256790 accept Slice 05, c320956 classify Slice 05, 0cb948a authorize Slice 06). Inspected that 3-commit BRAIN diff (STATE/PROJECT_STATE.md, STATE/TASK_LEDGER.tsv, STATE/EVENTS.jsonl only) before `git merge --ff-only origin main`. Fresh HEAD=origin/main=0cb948a, ahead0/behind0, clean. No reset/clean/stash/rebase/force and no merge commit. The baseline was never recaptured to absorb drift, and the expected base was satisfied exactly after the fast-forward.

Read set: AGENTS; task-execution skill; CURRENT HOT plus task lock/guard; fresh accepted STATE; docs/P15_RUNTIME_PLAN.md Slice 06 section only (purpose, prerequisites, locked decisions, files, ordered steps, required commands, completion checks, stop condition, audit gate); docs/TEST_PLAN.md §9 and its Adversarial Provider Test only; ClassificationRuntimeService (Dependencies/Checkpoint/StartResult/Result/State, start/cancel/invalidate/isActive/waitForCleanup, produceOutcome, readSource, infer, mappedResult, RuntimeCancellation); BoundedClassificationSourceOutcome and the reader's resolution, walk and errno mapping; LocalClassificationRequest and the six locked provider results; EntryClassificationRepository (EntryClassificationInput, status display names, append/history/classification, ORDER BY id DESC); docs/database/schema.sql entry_classifications definition; CatalogMigrations v9 migration and ExpectedState.classificationColumns; BundledMagikaClassificationProvider construction and Host source-boundary audit; SnapshotBrowserModel/View control seam, open/select/runSearch/clearSearch/exportJSON; ApplicationModel init/openSnapshot/closeSnapshot and CatalogLocation test-host isolation; ComparisonService.snapshotToSnapshot and ComparisonEngine; JSONSnapshotExporter write/export summary; MetadataSearchService; SnapshotHistoryRepository; TestSupport SyntheticSnapshot/EntrySnapshotProbe; SnapshotTreeDataSource.details; the exact bodies of every existing test credited below. No Slice 02/03/04/05 historical handoff was re-read beyond the single immediate predecessor required for handoff format parity. Slice 07 was read only far enough to confirm that real-helper network/signing/process-tree evidence is an external-helper obligation. No MCP use, no network research, no real helper executed.

## Technical delta and ownership

Exactly six technical paths, all tests or test wiring:

- `FSDTests/ClassificationInvocationIsolationTests.swift` (new, 352 lines, 8 tests) — the eight forbidden workflows.
- `FSDTests/ClassificationSecurityIntegrationTests.swift` (new, 483 lines, 8 tests) — adversarial provider A/B/C, persistence, immutability, offline, host-network.
- `FSDTests/ClassificationSourceReaderTests.swift` (+26) — the exact 4096/4097 ceiling boundary pair.
- `FSDTests/ComparisonSemanticsTests.swift` (+60) — unenriched-vs-enriched comparison outcome identity.
- `FSDTests/JSONExportTests.swift` (+44) — byte-identical export before/after enrichment.
- `FSD.xcodeproj/project.pbxproj` (8 lines: two build-file refs, two file refs, group and Sources entries for the two new test files only).

No production Swift, schema/migration/verify SQL, product/design doc, P15 plan, TEST_PLAN, helper binary/target, dependency manifest, unrelated test, STATE/PROJECT_STATE.md, RULE_PROMOTION_LEDGER.tsv or prior handoff byte changed.

FACT: `git diff --name-only 0cb948a..HEAD` returns exactly those six paths and nothing under `FSD/`, `docs/` or any other `STATE/` file. `git diff --check` exits 0. The new tests inject only through seams that approved slices already introduced: `SelectedEntryClassificationControl` (model-only start/cancel), `ClassificationRuntimeService.Dependencies` (already public to tests), and the `LocalFileClassificationProvider` protocol. No production file was modified to make any workflow injectable, and no provider contract field was added so that its absence could be proved.

### Isolation measurement contract

Each forbidden workflow asserts the same pair. `CLASSIFICATION_START_COUNT` is measured where a start seam genuinely exists (a counting spy injected as the browser's `SelectedEntryClassificationControl`), and where the workflow owns no classification capability at all it is measured on the one app-scoped runtime: `ClassificationRuntimeService.generation` advances only inside `start(entryID:...)` and `cancel()`, so an unchanged generation across the workflow proves no run was admitted, and each such test additionally proves the capability is absent from that workflow's own production source so the measurement is not vacuous. `CLASSIFICATION_ROW_DELTA` is `entry_classifications` row count before versus after on the same catalog. Constructing a runtime or a provider is never counted as invocation.

## TEST_PLAN_SECTION_9_COVERAGE_BEGIN

ITEM=exact_byte_ceiling_4096
EVIDENCE=ClassificationProviderContractTests.testRequestCannotExceedTheCeilingAndHasNoCallerBudget; ClassificationSourceReaderTests.testExact4096ByteFileReturnsExactly4096InOneRead; ClassificationSecurityIntegrationTests.testAdversarialProviderCannotBypassFSDByteCeiling
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=Proves the 4096 ceiling is enforced at request construction and at the single read(2); does not prove behaviour above 4096 for a file that is unreadable.

ITEM=exact_boundary_ceiling_vs_one_byte_over
EVIDENCE=ClassificationSourceReaderTests.testExactOneByteOverCeilingReturnsExactly4096InOneRead
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=Proves 4096 is admitted whole and 4097 truncates to the identical 4096-byte prefix with exactly one read; it does not characterise a source that grows between stat and read beyond the separate sourceChanged cases.

ITEM=small_file
EVIDENCE=ClassificationSourceReaderTests.testSmallFileReturnsExactBytesInOneRead; testEmptyFileReturnsEmptyPrefixInOneRead
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=Exact bytes in one read for a small and an empty file; no claim about sparse or compressed files.

ITEM=oversized_file
EVIDENCE=ClassificationSourceReaderTests.testLargeFileReturnsOnlyTheFirst4096BytesInOneRead
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=10 000-byte source yields the 4096-byte prefix with one read and no tail; not a scale test.

ITEM=missing_source
EVIDENCE=ClassificationSourceReaderTests.testMissingRecordedContextIsUnavailable; testSyntheticSnapshotWithoutCaptureContextAndUnknownEntryAreUnavailable; testMalformedStoredRootLocatorIsUnavailableBeforeAnyIO; testSnapshotStillScanningIsUnavailable
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=Covers absent capture context, malformed locator and scanning snapshots; not every conceivable NULL-column permutation.

ITEM=source_disappears_mid_read
EVIDENCE=ClassificationSourceReaderTests.testSourceDisappearingAfterInitialValidationIsSourceChanged; testFileDisappearingAfterReadOrBeforeOpenIsSourceChanged; testDirectoryDisappearingAfterValidationIsSourceChanged; testCancellationDuringReadOverridesConcurrentDisappearance
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=Disappearance is simulated by test-owned mutation at instrumented boundaries, not by a real concurrent unlink.

ITEM=changed_source_identity
EVIDENCE=ClassificationSourceReaderTests.testVolumeIdentityMismatchIsSourceChangedEvenWithMatchingNames; testMountPathNoLongerTheCapturedMountRootIsSourceChanged; testDisplayNameChangeAloneDoesNotBlockAnIdentifiedSource
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=Volume/mount identity substitution; a real remount is not performed.

ITEM=wrong_or_mismatched_source_identity
EVIDENCE=ClassificationSourceReaderTests.testIdentitySubstitutionAfterReadIsSourceChanged; testSubstitutionAfterReadIsSourceChangedWithNoSecondRead; testSubstitutionBySymlinkAfterReadIsSourceChanged; testSubstitutionBetweenLstatAndOpenIsSourceChanged; testFreshAuthorityFinalDifferentFileReadsNothing
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=Same-device inode substitution and symlink swap; not an adversarial kernel-level attacker.

ITEM=inaccessible_source_permission_denied
EVIDENCE=ClassificationSourceReaderTests.testPermissionFailureWithIdentifiedSourceIsFailed (real chmod 0 fixture); testInjectedPermissionAndIOFailuresAreFailedNotSourceChanged (EACCES/EPERM/EIO/EINTR)
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=Deterministic because the fixture runs as a non-root owner and restores mode 0o755 in teardown; no ACL, sandbox or read-only-volume variant is claimed.

ITEM=directory_entry_rejection
EVIDENCE=ClassificationSourceReaderTests.testStoredNonFileKindsAreUnsupportedWithZeroContentIO; testLiveDirectorySymlinkAndSpecialFileAreUnsupportedWithZeroContentReads
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=Zero content reads asserted; no claim about a directory that is also a package.

ITEM=symlink_entry_rejection
EVIDENCE=ClassificationSourceReaderTests.testFinalComponentSymlinkSwapIsUnsupportedAndTargetIsNeverRead; testIntermediateDirectorySymlinkEscapeIsBlockedAndTargetNeverRead; testSymlinkedRootLocatorComponentIsNeverFollowed
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=O_NOFOLLOW behaviour proven; not a proof against a hostile filesystem.

ITEM=special_file_entry_rejection
EVIDENCE=ClassificationSourceReaderTests.testLiveDirectorySymlinkAndSpecialFileAreUnsupportedWithZeroContentReads
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=FIFO/device-class rejection proven; socket and door kinds are not separately enumerated.

ITEM=cancel_before_the_read_begins
EVIDENCE=ClassificationSourceReaderTests.testCancelBeforeResolutionStopsBeforeAnyResolutionOrIO; testCancelBeforeContentReadAndAfterOpenNeverReadContent
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=Boundaries before resolution, before read and after open; no wall-clock timing claim.

ITEM=cancel_during_the_read
EVIDENCE=ClassificationSourceReaderTests.testCancellationDuringFailedReadOverridesIOFailureWithoutRetry; testCancellationDuringReadOverridesConcurrentDisappearance; testShortPlatformReadIsFailedAndNeverToppedUpWithASecondRead
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=Cancellation wins over a concurrent IO failure with exactly one read; not a torn-write stress test.

ITEM=cancel_before_inference
EVIDENCE=ClassificationRuntimeServiceTests.testCancellationAfterReadAndBeforeInference; testCancellationBeforeSourceResolutionDoesNotCallReader; testAlreadyCancelledCallerDoesNotResolveSource
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=Uses the runtime Checkpoint seam; no provider is entered.

ITEM=cancel_during_inference
EVIDENCE=ClassificationRuntimeServiceTests.testCancellationDuringReaderPropagatesTaskCancellationAndHoldsSlot; testCancelledGenerationRejectsLateClassifiedAppendAndPublication; testCompletionFirstStaysStableAfterCancelAndInvalidate
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=A noncooperative provider is used deliberately; real-helper termination is covered separately by the process-boundary tests.

ITEM=provider_failure_or_crash
EVIDENCE=ClassificationRuntimeServiceTests.testAllSixOutcomesAndExactObservationProvenance; BundledMagikaClassificationProviderTests.testNonzeroCrashLaunchWriteAndReadFaultsReapAndClose; testDeclaredUnavailableAndFailed
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=Fake runner fault injection; no real helper binary crash is claimed (Slice 07).

ITEM=provider_timeout
EVIDENCE=ClassificationRuntimeServiceTests.testTimeoutReturnsWhileLateProviderStillOwnsSlotAndCannotPublishSuccess; testDeadlineStartsOnlyAfterReaderAndExactlyAtInferenceHandoff; testProviderCompletionBeforeDeadlineWinsExactlyOneClassifiedRow; testBundledProviderTimeoutCancelsTerminatesClosesReapsBeforeSlotRelease
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=Injected deadline proves the exact 5 s inference-only rule, not a real 5 s wall-clock wait.

ITEM=successful_classification_persists_correctly
EVIDENCE=ClassificationRuntimeServiceTests.testRealRepositoryDuplicateRunRemainsTypedNoRetryAndFactsImmutable; ClassificationEnrichmentTests.testStoredClassificationRoundTripsAndDetailReadIsBounded; ClassificationSecurityIntegrationTests.testClassificationWritesNeverMutateEntryOrSnapshotFacts
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=Exactly one row per admitted run against the real repository; does not prove a helper-backed provider succeeds.

ITEM=cancellation_cannot_create_a_successful_row
EVIDENCE=ClassificationRuntimeServiceTests.testCancellationAfterInferenceAndImmediatelyBeforeAppend; testCallerTaskCancellationImmediatelyBeforePersistenceCannotAppend; testTimeoutThenUserCancelBeforeAppendWritesNoRow; testUserCancelBeforeDeadlineWinsNoFailedRow; testCancelledGenerationRejectsLateClassifiedAppendAndPublication
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=Asserted at the append boundary through the probe/repository; no scheduling stress loop.

ITEM=no_payload_persistence
EVIDENCE=ClassificationSecurityIntegrationTests.testNoPayloadByteSampleContentHashOrAbsolutePathIsPersisted; ClassificationProviderContractTests.testClassificationSourcesContainNoForbiddenAccessLoggingHashingOrPersistenceAPIs; ClassificationRuntimeServiceTests.testRuntimeStateAndCompletionContainNoPayloadOrSourceCapability
EVIDENCE_TYPE=SCHEMA+RUNTIME
STATUS=PASS
LIMIT=Exact column list asserted plus every persisted text value inspected; proves absence in `entry_classifications`, not across hypothetical future tables.

ITEM=no_byte_sample_persistence
EVIDENCE=ClassificationSecurityIntegrationTests.testNoPayloadByteSampleContentHashOrAbsolutePathIsPersisted
EVIDENCE_TYPE=SCHEMA+RUNTIME
STATUS=PASS
LIMIT=Hex and verbatim renderings of the real sampled prefix are searched in observed values; a provider-specific encoding of the same bytes is not enumerated exhaustively.

ITEM=no_content_hash_persistence
EVIDENCE=ClassificationSecurityIntegrationTests.testNoPayloadByteSampleContentHashOrAbsolutePathIsPersisted; ClassificationProviderContractTests.testClassificationSourcesContainNoForbiddenAccessLoggingHashingOrPersistenceAPIs
EVIDENCE_TYPE=SCHEMA+RUNTIME
STATUS=PASS
LIMIT=No hash column exists and no hash-shaped token reaches a persisted value; not a cryptographic proof about every possible digest encoding.

ITEM=no_absolute_source_path_persistence
EVIDENCE=ClassificationSecurityIntegrationTests.testAdversarialProviderCannotReachOriginalSourceAuthority; testNoPayloadByteSampleContentHashOrAbsolutePathIsPersisted; testHostileProviderDiagnosticsAreNeverPersistedOrReturned
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=The real absolute source path, source directory and test-owned directory are searched in every persisted column and in the returned completion; a differently-normalised rendering of the same path is not enumerated.

ITEM=no_snapshot_mutation_entries_snapshots
EVIDENCE=ClassificationSecurityIntegrationTests.testClassificationWritesNeverMutateEntryOrSnapshotFacts; ClassificationEnrichmentTests.testExplicitEnrichmentPreservesSnapshotAndEntryImmutability; ClassificationRuntimeServiceTests.testRealRepositoryDuplicateRunRemainsTypedNoRetryAndFactsImmutable
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=Fingerprints cover the columns EntrySnapshotProbe selects plus `PRAGMA integrity_check` and `foreign_key_check`; classification rows are expected to append.

ITEM=comparison_isolation
EVIDENCE=ComparisonSemanticsTests.testClassificationEnrichmentLeavesEveryComparisonOutcomeIdenticalToUnenrichedBaseline; testClassificationMetadataCannotChangeComparisonOutcome; testComparisonNeverReadsOrWritesClassificationRows; testComparisonNeverMutatesSnapshotEntries
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=Proven for the Fast Metadata profile and the seeded pair; not for every comparison profile or mode.

ITEM=json_export_stability
EVIDENCE=JSONExportTests.testExportIsByteIdenticalBeforeAndAfterClassificationEnrichment; testExportIsDeterministic; testExportStatesContentIsNotVerifiedAndCarriesNoPayloadOrClassification; testExportIsValidJSONWithTheExpectedShape
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=Byte identity and `formatVersion` 1 asserted before and after two enrichment rows; the exporter's production code is untouched.

ITEM=zero_network_activity_during_classification
EVIDENCE=ClassificationSecurityIntegrationTests.testClassificationProductionSurfacesContainNoNetworkCapability; ClassificationProviderContractTests.testClassificationSourcesContainNoForbiddenAccessLoggingHashingOrPersistenceAPIs; BundledMagikaClassificationProviderTests.testSourceBoundaryNoPayloadPersistenceShellNetworkOrUnboundedReads
EVIDENCE_TYPE=SOURCE_API_BOUNDARY
STATUS=PASS
LIMIT=Proves FSD host/runtime classification surfaces contain no URLSession, Network.framework, socket, telemetry, watcher or updater API. It does NOT prove that a real helper process makes no network call; that remains SLICE07_EXTERNAL_HELPER_ONLY and is not claimed.

ITEM=no_automatic_invocation
EVIDENCE=ClassificationInvocationIsolationTests.testCaptureWorkflowNeverStartsClassification; testApplicationLaunchNeverStartsClassification; testHistoryOpenNeverStartsClassification; testSnapshotReopenNeverStartsClassification; testBrowsingAndSelectionNeverStartClassification; testSearchNeverStartsClassification; testComparisonNeverStartsClassification; testJSONExportNeverStartsClassification
EVIDENCE_TYPE=RUNTIME+SOURCE_API_BOUNDARY
STATUS=PASS
LIMIT=Eight independent test identities; see the workflow ledger below. Runtime generation equality and row delta are the proof where no start seam exists.

ITEM=offline_history_snapshot_usability
EVIDENCE=ClassificationSecurityIntegrationTests.testDetachedSourceYieldsLockedOutcomeAndKeepsSnapshotBrowsable; ClassificationSourceReaderTests.testSourceDetachedBeforeResolutionIsUnavailable
EVIDENCE_TYPE=RUNTIME
STATUS=PASS
LIMIT=A deleted source tree stands in for any detached volume; proves no crash/hang, the locked vocabulary and continued browsing/export, not a physical unmount.

ITEM=schema_expected_state_safety_for_provider_identifier
EVIDENCE=SchemaMigrationTests.testVersionEightMigratesLegacyRowsWithoutBackfillAndReopensWithoutReplay; testVersionNineVersionRowIsWrittenAfterEveryMigrationStatement; testFailedVersionNineRollsBackDDLAndDataAtStatementOrVersionWriteFailure; testVersionNineWithoutProviderIdentifierIsRejected; testFreshDatabaseReachesCurrentVersionWithCleanIntegrity; testFreshAndMigratedSchemasAreEquivalent
EVIDENCE_TYPE=SCHEMA
STATUS=PASS
LIMIT=Column presence, nullability with no default, no legacy backfill and ExpectedState rejection of a damaged v9 are proven; no schema or SQL byte was edited in this slice.

ADVERSARIAL_PROVIDER_A=ClassificationSecurityIntegrationTests.testAdversarialProviderCannotReachOriginalSourceAuthority (end-to-end through the real runtime, reader and repository): the hostile provider's only visible surface is one stored field named `data`; no URL, String, function or handle is reachable, path-recovery probes all find nothing, and the rendered request leaks no absolute path, mount path, volume identifier, entry name, snapshot id or entry id. Corroborated at unit level by ClassificationProviderContractTests.testHostileProviderCannotObtainPathURLHandleIdentityCallbackOrMoreBytes. No path field was added to production to make this provable.
ADVERSARIAL_PROVIDER_B=ClassificationSecurityIntegrationTests.testAdversarialProviderHasNoAdditionalByteRequestAPI: the request type exposes no member beyond `data`, indexing past `data.count` is impossible, and no readMore/moreBytes/byteRange/reader/reopen/nextChunk capability exists, so the provider attempted zero extra reads and zero source reopens. It received no artificial callback from the test.
ADVERSARIAL_PROVIDER_C=ClassificationSecurityIntegrationTests.testAdversarialProviderCannotBypassFSDByteCeiling: a 9000-byte source yields FSD_SOURCE_BYTES_READ_FOR_PROVIDER=4096 and REQUEST_DATA_COUNT=4096 equal to `sourceBytes.prefix(4096)` and unequal to the whole file. The provider allocated a real 4 MiB buffer and claimed 4 194 304 bytes; `LocalClassificationRequest(boundedPrefix:)` still returns nil for it, the ceiling stays 4096, exactly one row is appended, and entry/snapshot fingerprints are unchanged. Provider-allocated bytes are explicitly distinguished from source bytes FSD read.

FORBIDDEN_WORKFLOW_CAPTURE=ClassificationInvocationIsolationTests.testCaptureWorkflowNeverStartsClassification — real SnapshotScanner capture into the catalog; CLASSIFICATION_START_COUNT=0, CLASSIFICATION_ROW_DELTA=0, runtime generation unchanged, SnapshotScanner.swift proven free of any classification symbol.
FORBIDDEN_WORKFLOW_APP_LAUNCH=ClassificationInvocationIsolationTests.testApplicationLaunchNeverStartsClassification — real ApplicationModel startup (test-host catalog); CLASSIFICATION_START_COUNT=0, CLASSIFICATION_ROW_DELTA=0, launch leaves no active run, FSDApp.swift proven to contain no start/classification invocation.
FORBIDDEN_WORKFLOW_HISTORY_OPEN=ClassificationInvocationIsolationTests.testHistoryOpenNeverStartsClassification — SnapshotHistoryRepository listSnapshots (all kinds) + issues; CLASSIFICATION_START_COUNT=0, CLASSIFICATION_ROW_DELTA=0, repository proven free of any classification symbol.
FORBIDDEN_WORKFLOW_SNAPSHOT_REOPEN=ClassificationInvocationIsolationTests.testSnapshotReopenNeverStartsClassification — browser built exactly as ApplicationModel.openSnapshot does, opened, closed, rebuilt and reopened; CLASSIFICATION_START_COUNT=0, CLASSIFICATION_ROW_DELTA=0, same runtime instance across replacement.
FORBIDDEN_WORKFLOW_BROWSE_SELECT=ClassificationInvocationIsolationTests.testBrowsingAndSelectionNeverStartClassification — real browser open, select, details read, deselect, reselect; CLASSIFICATION_START_COUNT=0 at the injected start seam, CLASSIFICATION_ROW_DELTA=0, explicit affordance present but inert.
FORBIDDEN_WORKFLOW_SEARCH=ClassificationInvocationIsolationTests.testSearchNeverStartsClassification — browser runSearch (asserting isSearching proves real dispatch) plus direct MetadataSearchService query; CLASSIFICATION_START_COUNT=0, CLASSIFICATION_ROW_DELTA=0, MetadataSearchService.swift proven free of any classification symbol.
FORBIDDEN_WORKFLOW_COMPARISON=ClassificationInvocationIsolationTests.testComparisonNeverStartsClassification — real ComparisonService.snapshotToSnapshot over a captured pair; CLASSIFICATION_START_COUNT=0, CLASSIFICATION_ROW_DELTA=0, ComparisonEngine.swift proven free of any classification symbol.
FORBIDDEN_WORKFLOW_JSON_EXPORT=ClassificationInvocationIsolationTests.testJSONExportNeverStartsClassification — the exact exporter call the browser export action makes; CLASSIFICATION_START_COUNT=0, CLASSIFICATION_ROW_DELTA=0, exported text carries no classification key, JSONSnapshotExporter.swift proven free of any classification symbol.

TEST_PLAN_SECTION_9_COVERAGE_END

### Traceability checklist outcome

The mandatory pre-test checklist was built for all 31 §9 lines before any test was added, recording existing methods, whether the assertion body was actually read, and status. Result: 18 items `COVERED_EXISTING`, 13 items `GAP_REQUIRES_TEST`, 0 `SLICE07_EXTERNAL_HELPER_ONLY` among the §9 lines themselves (the only external-helper item in the whole slice is the real-helper half of "zero network", carried inside the zero-network line as an explicit limit rather than a separate §9 line). All 13 gaps are now closed by new or extended tests. No existing test was credited from its name; each credited method's body was read, and four methods initially credited in the working checklist were reclassified as gaps after reading, because they asserted plausibility rather than the §9 requirement.

Gap-to-test closure:

1. exact 4096/4097 boundary — `ClassificationSourceReaderTests.testExactOneByteOverCeilingReturnsExactly4096InOneRead`
2. no payload persistence (observed values) — `ClassificationSecurityIntegrationTests.testNoPayloadByteSampleContentHashOrAbsolutePathIsPersisted`
3. no byte-sample persistence — same test
4. no content-hash persistence — same test
5. no absolute-source-path persistence — `testAdversarialProviderCannotReachOriginalSourceAuthority`, `testNoPayloadByteSampleContentHashOrAbsolutePathIsPersisted`, `testHostileProviderDiagnosticsAreNeverPersistedOrReturned`
6. comparison isolation baseline identity — `ComparisonSemanticsTests.testClassificationEnrichmentLeavesEveryComparisonOutcomeIdenticalToUnenrichedBaseline`
7. JSON export stability across enrichment — `JSONExportTests.testExportIsByteIdenticalBeforeAndAfterClassificationEnrichment`
8. zero network across all four classification surfaces — `ClassificationSecurityIntegrationTests.testClassificationProductionSurfacesContainNoNetworkCapability`
9. no automatic invocation, 8 workflows — the eight `ClassificationInvocationIsolationTests` methods
10. offline usability with a real detached source — `ClassificationSecurityIntegrationTests.testDetachedSourceYieldsLockedOutcomeAndKeepsSnapshotBrowsable`
11. adversarial A end-to-end — `testAdversarialProviderCannotReachOriginalSourceAuthority`
12. adversarial B end-to-end — `testAdversarialProviderHasNoAdditionalByteRequestAPI`
13. adversarial C end-to-end — `testAdversarialProviderCannotBypassFSDByteCeiling`

## Persistence and runtime matrix as verified

| Condition | Row | Provider invoked | Evidence |
| --- | --- | --- | --- |
| classified | exactly one `.classified` row with provider identity | yes | `testAllSixOutcomesAndExactObservationProvenance`, `testClassificationWritesNeverMutateEntryOrSnapshotFacts` |
| reader failed | exactly one `.failed` row, NULL provider/detector/model | no | `testReaderFailureAppendsOneFailedRowWithoutProviderProvenance` |
| provider failed | exactly one `.failed` row carrying provider identity | yes | `testAllSixOutcomesAndExactObservationProvenance`, `testTimeoutReturnsWhileLateProviderStillOwnsSlotAndCannotPublishSuccess` |
| sourceChanged | exactly one `.failed` row, NULL provider identity | no | `testAllSixOutcomesAndExactObservationProvenance`, `testDetachedSourceYieldsLockedOutcomeAndKeepsSnapshotBrowsable` |
| unsupported | exactly one `.failed` row, NULL provider identity | no | `testAllSixOutcomesAndExactObservationProvenance`, `testStoredNonFileKindsAreUnsupportedWithZeroContentIO` |
| unavailable | zero rows | no | `testAllSixOutcomesAndExactObservationProvenance`, `testDisabledProviderIsSideEffectFreeAndReturnsUnavailable` |
| cancelled | zero rows | no | four cancellation tests in `ClassificationRuntimeServiceTests` |
| busy | zero rows, no queue, no retry | no | `testSingleFlightBusyDoesNotQueueOrTouchDependencies`, `testBusyShowsMessageNoQueueNoAutoStart` |
| provider timeout | one `.failed` row with provider identity under current-generation rules | yes | `testTimeoutReturnsWhileLateProviderStillOwnsSlotAndCannotPublishSuccess`, `testBundledProviderTimeoutCancelsTerminatesClosesReapsBeforeSlotRelease` |
| duplicate run | append-only, typed `duplicateRun`, no retry, no replacement id | yes | `testRealRepositoryDuplicateRunRemainsTypedNoRetryAndFactsImmutable` |

Provenance independence is proven by `testAllSixOutcomesAndExactObservationProvenance`, which asserts detector version, model version and provider identifier as three separately carried fields, and by `testClassifiedEnvelopeAndIndependentHostProvenance`, which proves a helper cannot override the host's provider identity.

## Process boundary regressions credited

Read and credited from `BundledMagikaClassificationProviderTests` (no real helper executable was run; every test uses the existing fake runner):

- raw stdin only, exactly one closed delivery — `testRawInputEmptyMaximumAndExactlyOneClosedDelivery` (asserts `runner.deliveries == [input]` and the exact event order launch/deliver/closeInput/poll/reap/closePipes).
- stdout 4096 cap and stderr 4096 cap, cumulative — `testProductionPipePumpCapsBothChannelsWithoutLaunchingAChild`, `testCapsAreCumulativeAndStderrNeverSurfaces` (asserts `stdoutConsumed <= 4096`, `stderrConsumed <= 4096`, exact-cap frame accepted, over-cap frame failed and terminated).
- malformed output rejection — `testStrictMalformedSchemaKindTypesLengthsAndConfidence`.
- provider provenance ownership — `testClassifiedEnvelopeAndIndependentHostProvenance`.
- cancellation terminate/close/reap — `testCancellationWhileActiveTerminatesReapsAndCloses`, `testCancellationDuringRunnerCreationPreventsLaunchAuthorization`, `testLaunchAuthorizationFirstThenCancellationDuringLaunchCleansUp`, `testNonzeroCrashLaunchWriteAndReadFaultsReapAndClose`, and at runtime level `testBundledProviderTimeoutCancelsTerminatesClosesReapsBeforeSlotRelease`.
- no PATH, no shell, fixed bundle-relative helper — `testSourceBoundaryNoPayloadPersistenceShellNetworkOrUnboundedReads` (asserts `process.arguments = []`, `process.environment = [:]`, no `/bin/sh`, no `/usr/bin/env`, no `getenv`), `testFixedResolutionStandardizesAndRejectsEscapesAndSiblingPrefix`, `testPhysicalMissingNonExecutableDirectoryAndSymlinkResolution`, `testMissingAndNonExecutableHelpersAreUnavailableAndNeverLaunch`.
- construction inert — `testConstructionAndDisabledProviderAreInert`, `SnapshotBrowserClassificationTests.testProductionProviderConstructionIsInertAndUnavailableWithoutHelper`.

## Verification receipts

Fresh derived data at the task-mandated path:

```text
rm -rf /tmp/FSD-P15-Impl06-DerivedData
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Impl06-DerivedData clean build
** CLEAN SUCCEEDED **
** BUILD SUCCEEDED **
```

Focused, exactly the nine mandated classes:

```text
xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Impl06-DerivedData \
  -only-testing:FSDTests/ClassificationInvocationIsolationTests \
  -only-testing:FSDTests/ClassificationSecurityIntegrationTests \
  -only-testing:FSDTests/ClassificationSourceReaderTests \
  -only-testing:FSDTests/ClassificationProviderContractTests \
  -only-testing:FSDTests/BundledMagikaClassificationProviderTests \
  -only-testing:FSDTests/ClassificationRuntimeServiceTests \
  -only-testing:FSDTests/SnapshotBrowserClassificationTests \
  -only-testing:FSDTests/ComparisonSemanticsTests \
  -only-testing:FSDTests/JSONExportTests
EXECUTED=179; PASSED=179; SKIPPED=0; FAILED=0
TEST SUCCEEDED
LOG=/tmp/fsd-slice06-focused.log
```

Per-class focused counts: BundledMagikaClassificationProviderTests 18, ClassificationInvocationIsolationTests 8, ClassificationProviderContractTests 9, ClassificationRuntimeServiceTests 26, ClassificationSecurityIntegrationTests 8, ClassificationSourceReaderTests 57, ComparisonSemanticsTests 19, JSONExportTests 9, SnapshotBrowserClassificationTests 25.

Full Debug suite:

```text
xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Impl06-DerivedData
Executed 472 tests, with 3 tests skipped and 0 failures (0 unexpected) in 2250.911 (2472.195) seconds
EXECUTED=472; PASSED=469; SKIPPED=3; FAILED=0
TEST SUCCEEDED
LOG=/tmp/fsd-slice06-full.log
```

Full-suite skips (3, all pre-existing external fixtures, unchanged from Slice 05): `FSDProbeSeedTests.testSeedIsolatedProbeCatalog` (FSD_PROBE_CATALOG absent), `FilesystemMatrixTests.testCaptureExternallyPreparedMountedFilesystem` (FSD_MATRIX_SOURCE absent), `FilesystemMatrixTests.testReopenCapturedSnapshotWithTheSourceDetached` (FSD_MATRIX_OFFLINE_CATALOG absent). No skip was added, hidden or removed by this slice. The count grew from 453 to 472 exactly because 19 test methods were added.

```text
git diff --check
EXIT=0
```

No firewall manipulation, packet capture, privileged networking tool, network entitlement or real helper was used at any point. Changed paths versus the base are exactly the six technical paths above. Checker, publication and Desktop parity are closure checks whose receipts belong in Desktop and the terminal return, not in this self-SHA record.

## Two failures that were test defects, not product defects

Recorded because "a failing new test is evidence" and the evidence here contradicts the Worker, not the product:

1. `testClassificationWritesNeverMutateEntryOrSnapshotFacts` first asserted classification history in insertion order. The repository's documented order is newest-first (`ORDER BY id DESC`), corroborated by the existing `ClassificationEnrichmentTests.testProviderHistoryRemainsAppendOnlyAndLatestUsesInsertionOrder`. The test was corrected to the documented order; both elements remain asserted and no assertion was deleted.
2. `testDetachedSourceYieldsLockedOutcomeAndKeepsSnapshotBrowsable` first asserted that a detached source writes zero rows. The locked Slice 01/04 rule is that a pre-provider `.sourceChanged` persists exactly one `.failed` row with a NULL provider identifier, and only `.unavailable` and `.cancelled` write nothing. The test was corrected to assert the exact per-outcome rule, including NULL provider identity and NULL detected type. No production behaviour was changed and no assertion was relaxed to match broken behaviour.

## Requirement/evidence map and execution postflight

1. §9 traceability checklist built for every §9 line before any test was added — EVIDENCED (checklist section above).
2. All 31 §9 lines accounted individually, plus 3 adversarial constraints and 8 workflows — EVIDENCED (ledger).
3. No coverage credited from a test name; every credited assertion body read — EVIDENCED (four methods reclassified after reading).
4. `docs/TEST_PLAN.md` not edited — EVIDENCED (`git diff --name-only` excludes `docs/`).
5. Tests-only slice; no production repair — EVIDENCED (`PRODUCTION_DELTA=NONE`).
6. No product design change — EVIDENCED (no doc or production delta).
7. No real helper run — EVIDENCED (fake runner only; `REAL_HELPER_EXECUTED=NONE`).
8. No Slice 07 work — EVIDENCED (no Slice 07 target, helper or fact claimed).
9. Eight forbidden workflows with independent test identity — EVIDENCED (8 distinct methods).
10. `CLASSIFICATION_START_COUNT=0` per workflow — EVIDENCED (spy where a seam exists; runtime generation where none does).
11. `CLASSIFICATION_ROW_DELTA=0` per workflow — EVIDENCED (row count before/after in all eight).
12. Constructing a runtime/provider is not invocation — EVIDENCED (explicit contract in the isolation ledger; normalization cancel documented as not an invocation).
13. No production change to make a workflow injectable — EVIDENCED (only pre-existing seams used).
14. Hostile provider through the existing Data-only contract — EVIDENCED (`HostileSecurityProvider` uses only `LocalFileClassificationProvider`).
15. Adversarial A: no URL, path, handle, fd, resolver or callback reachable — EVIDENCED (`testAdversarialProviderCannotReachOriginalSourceAuthority`).
16. Provider receives only `LocalClassificationRequest.data` — EVIDENCED (single stored field `data`).
17. No path field added merely to prove absence — EVIDENCED (no production delta).
18. Adversarial B: no second range, read, callback or reopen — EVIDENCED (`testAdversarialProviderHasNoAdditionalByteRequestAPI`).
19. Hostile provider given no artificial callback by the test — EVIDENCED (request type has no member to give).
20. Adversarial C: >4096 source, FSD bytes ≤4096, request data ≤4096 — EVIDENCED (`testAdversarialProviderCannotBypassFSDByteCeiling`, 9000-byte source, exactly 4096 delivered).
21. Provider's larger Data/metadata claims cause no extra read, no persisted bytes/path, no immutable-fact change, no ceiling change — EVIDENCED (same test, fingerprints and ceiling asserted).
22. Exact boundary 4096 vs 4097 — EVIDENCED (`testExactOneByteOverCeilingReturnsExactly4096InOneRead`).
23. Small/oversized/missing/disappearing/identity-mismatch reader cases — EVIDENCED (existing reader matrix, read in full).
24. Deterministic permission fixture — EVIDENCED (real `chmod 0`, non-root, restored in teardown).
25. Directory, symlink and special-file rejection — EVIDENCED (existing reader matrix with zero-read assertions).
26. Cancellation boundaries before/during read and before/during inference — EVIDENCED (reader and runtime checkpoint tests).
27. No sleeps used for race ordering — EVIDENCED (continuations, expectations, injected deadline, actor gates; the one `Task.sleep` in the browser suite is Slice 05's production 0.5 s progress seam, not an ordering device).
28. Runtime/persistence matrix, all eight conditions — EVIDENCED (matrix table).
29. Provider timeout yields a failed row under current-generation rules — EVIDENCED (injected deadline tests).
30. Cancellation cannot create a successful row — EVIDENCED (four append-boundary tests).
31. Duplicate run stays append-only with no retry — EVIDENCED (`testRealRepositoryDuplicateRunRemainsTypedNoRetryAndFactsImmutable`).
32. Provider/detector/model provenance independent — EVIDENCED (six-outcome provenance test plus helper-override rejection).
33. No payload, byte-sample, content-hash or absolute-path persistence, schema and observed values — EVIDENCED (exact column list plus every persisted value).
34. No raw provider diagnostics persisted — EVIDENCED (`testHostileProviderDiagnosticsAreNeverPersistedOrReturned`).
35. Entries/snapshots unchanged by successful and failed classification writes — EVIDENCED (fingerprints, integrity_check, foreign_key_check).
36. No test repairs immutable data — EVIDENCED (tests only read fingerprints).
37. Comparison isolation against an unenriched baseline — EVIDENCED (new baseline test; the pre-existing §9-named test was read and credited for the metadata-divergence half).
38. JSON export excludes classification, format version unchanged, byte-identical before/after enrichment — EVIDENCED (new test).
39. Exporter production untouched — EVIDENCED (`PRODUCTION_DELTA=NONE`).
40. Detached source yields the locked outcome, no crash/hang, snapshot still browsable — EVIDENCED (new offline test).
41. Schema v9 provider_identifier present, nullable, no default/backfill; expected-state verification green — EVIDENCED (SchemaMigrationTests; no SQL edited).
42. Zero network capability on host classification surfaces, using existing source/API inspection patterns only — EVIDENCED (four-file audit); real-helper network behaviour explicitly `SLICE07_EXTERNAL_HELPER_ONLY`.
43. No firewall, packet capture, privileged tooling, entitlement or real helper added — EVIDENCED (no such artifact in the delta).
44. Process boundary regressions credited from existing tests — EVIDENCED (process boundary section).
45. Test-only mutation allowlist respected — EVIDENCED (six changed paths, all allowlisted).
46. No forbidden mutation — EVIDENCED (no production, SQL, doc, manifest, helper, unrelated-test, PROJECT_STATE or RULE_PROMOTION_LEDGER delta).
47. No "test fixes product" — EVIDENCED (the two failures were corrected as test defects, documented above).
48. Deterministic race discipline — EVIDENCED (gates/expectations/deadlines; no retry, no arbitrary sleep, no relaxed count).
49. Fresh clean build in the mandated derived-data path — EVIDENCED (CLEAN/BUILD SUCCEEDED).
50. Focused run over exactly the nine mandated classes — EVIDENCED (179/179).
51. Full Debug suite with exact counts and no hidden skips — EVIDENCED (472/469/3/0, three skips named).
52. §9 coverage ledger present in this handoff — EVIDENCED (ledger section).
53. Exactly one new handoff; normal Worker closure surfaces only — EVIDENCED (this file, CURRENT, ledger, events, Desktop).
54. `STATE/PROJECT_STATE.md` and `STATE/RULE_PROMOTION_LEDGER.tsv` untouched — EVIDENCED (diff excludes them).
55. Desktop fallback refreshed — EVIDENCED (Desktop receipt).
56. Push/fetch reconcile to 0/0 clean — EVIDENCED (Desktop receipt).
57. Manual UI acceptance deferred — NOT_APPLICABLE (deferred by Owner; no visual pass claimed).
58. VoiceOver manual acceptance deferred — NOT_APPLICABLE (deferred by Owner; no VoiceOver pass claimed).

Count reconciliation: 58 mapped lines above, of which 2 are NOT_APPLICABLE (57, 58) and 56 are EVIDENCED. The guard's 42 is the slice-level requirement count BRAIN reviews; every guard requirement is satisfied by one or more of the 58 evidence lines above, with no UNPROVEN item.

FACT: execution postflight complete before finalization. The candidate is the technical SHA above. Historical source, full CURRENT, pending-BRAIN ledger/event, exact Operator and full CURRENT Desktop are the normal closure projections. Checker, commit/push/fetch clean0/0 and final parity are closure checks; their receipts belong in Desktop and the terminal return. Publication SHA is resolved with `git log -1 --format=%H -- <handoff>` after commit; no self-referential bookkeeping commit was created.

## Ownership, limits and return

`STATE/PROJECT_STATE.md` and `STATE/RULE_PROMOTION_LEDGER.tsv` are untouched. One Worker ledger row and one event propose Slice 06 adjudication and leave BRAIN_CLASSIFICATION=PENDING_BRAIN. All prior handoffs remain immutable. `docs/TEST_PLAN.md`, the P15 plan and every product/design document are unchanged. The real Magika helper was never executed, so helper signing, helper network behaviour and helper process-tree evidence remain `SLICE07_EXTERNAL_HELPER_ONLY` and are not claimed here. Manual UI and VoiceOver acceptance remain deferred by Owner. This Worker neither accepted its own work nor authorized any next task.

PROPOSED_STATE_DELTA=ADJUDICATE_SLICE06_SECTION9_LEDGER_AND_AUTOMATED_GATE_EVIDENCE;NO_WORKER_ACCEPTANCE_OR_NEXT_AUTHORIZATION