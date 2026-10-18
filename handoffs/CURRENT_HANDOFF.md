UPDATED_AT: 2026-10-19T01:51:26+07:00

# Task059 Synthetic Source Observation Contract and Fail-Closed Resolver — Worker return

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD2_IMPLEMENTATION_SOURCE_OBSERVATION_RESOLVER
HANDOFF_ID=handoffs/FSD_FSD2_SOURCE_OBSERVATION_FAIL_CLOSED_RESOLVER_059_D_20261019-015126.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=5ddf1cd15c43b351f1e4863c0155ae4ab1de8938
REMOTE_HEAD=5ddf1cd15c43b351f1e4863c0155ae4ab1de8938
LAST_VERIFIED_AT=2026-10-19T01:51:26+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|docs/AGENT.md|STATE/PROJECT_STATE.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|handoffs/CURRENT_HANDOFF.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-independent-review/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|docs/DECISIONS.md|docs/ARCHITECTURE.md|docs/TEST_PLAN.md|docs/PRODUCT_STATE.md|docs/database/schema.sql|FSD/Model/PhysicalDriveModels.swift|FSD/Catalog/PhysicalDriveRepository.swift|FSD/Model/SourceObservationResolver.swift|FSD/Catalog/SyntheticSourceResolutionRepository.swift|FSDTests/SourceObservationResolverTests.swift|FSDTests/SyntheticSourceResolutionRepositoryTests.swift|scripts/check_control_plane.py
CURRENT_PHASE=POST_V0_1_FSD2_FOUNDATION
CURRENT_GATE=FSD2_SOURCE_OBSERVATION_FAIL_CLOSED_RESOLVER_059
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_FOR_SYNTHETIC_RESOLVER;REAL_HARDWARE_AND_LIVE_OBSERVATION_PENDING
PROPOSED_NEXT=WAIT(BRAIN_REVIEW_TASK059_SYNTHETIC_OBSERVATION_RESOLVER)
NO_AUTO_NEXT=YES

## Task lock, authority and recovery

PROJECT=FSD
TASK_ID=FSD2_SOURCE_OBSERVATION_FAIL_CLOSED_RESOLVER_059
ROLE=WORKER
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
BASE_HEAD=5ddf1cd15c43b351f1e4863c0155ae4ab1de8938
UPSTREAM_HEAD=5ddf1cd15c43b351f1e4863c0155ae4ab1de8938
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=SYNTHETIC_IMMUTABLE_OBSERVATION_PURE_FAIL_CLOSED_RESOLVER_V10_READ_SEAM
ALLOWED_PATHS=8_SUBSTANTIVE_PATHS_LISTED_BELOW|one_new_history|CURRENT|Worker_ledger_event|Desktop_transport
FORBIDDEN_PATHS=ACCEPTED_STATE|RULE_PROMOTION_LEDGER|PRIOR_HISTORY|SCHEMA_MIGRATIONS|UNRELATED_PRODUCT_TESTS|OWNER_DATA_CATALOG_MEDIA|SOURCE_IO|HARDWARE|LIVE_OBSERVATION|AUTO_CAPTURE|DRIVE_SETS|SAVE_COMPARISON|RELEASE|TASK060
SUCCESS_CRITERIA=BOUNDED_TYPED_CONTRACT|DETERMINISTIC_PRECEDENCE|EXPLICIT_MANUAL_REUSE|ZERO_MUTATION_STRONG_MATCH|SYNTHETIC_XCTEST|REGRESSION_BUILDS_REVIEW|CANONICAL_PUBLICATION
VALIDATIONS=NEW_AND_TASK058_XCTEST|CATALOG_SCHEMA_SNAPSHOT_COLLECTION_COMPARISON_SOURCE_REGRESSIONS|CLEAN_ARM64_DEBUG_RELEASE|SQLITE_FK_INTEGRITY|PROTECTED_HASH_SCOPE_DIFF|INDEPENDENT_REVIEW|CANONICAL_PRE_POST_PARITY
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY

The initial Task059 preflight STOP was solely AUTHORIZATION_STATE_SYNC_PENDING.
It made no product or reporting mutation. BRAIN subsequently published the
Owner's existing approval in 5ddf1cd15c43b351f1e4863c0155ae4ab1de8938; it is not
claimed to have been published earlier. Owner explicitly resumed the same task.
Fresh non-destructive fetch verified clean physical main and origin/main at that
exact baseline, 0/0. State has exactly ACTION(Task059), while Task058 remains
accepted PASS_WITH_ADVISORY at d7db0fa426942f24d12569500be3fab1099e0193. No
reset, stash, clean, force, unknown-work overwrite or Owner catalog access.

Read canonical Owner policy/kernel, Compact/FULL, State/ledger/recent events,
CURRENT HOT, Task054/057/058 immutable handoffs, ADR036, architecture §§11–14,
Test Plan §§10/13/14, Product State, v10 identity schema, Task058 models/repository/
tests and catalog/recovery source. All three execution/review/finalizer skills
apply. Before edits, captured hashes for all 1524 tracked paths, symlinks by link
text. Scope validation preserves all 111 old historical handoffs and protected
State, migrations, schema, helper, runtime and comparison sources.

## Implemented contract and precedence

Two focused production files; no existing production Swift changed:

- `SourceObservationEnvelope`: immutable Sendable/Equatable single-subject value
  reusing Task058 IdentityObservation and IdentityEvidenceInput. Includes local
  observation/session IDs, revision, device/media/partition/volume/mountSession
  scope, original Unknown/Ambiguous/Conflict state, time/provenance, typed facts
  and caller-declared complete/partial state. Missing provenance stays explicit;
  it is not a verified fact. Sharing a session does not prove physical topology.
- Bounds: 32 incoming facts before dedup, 1024 UTF-8 bytes per value/provenance,
  256 per property/time, positive revision, parseable observation time, no NUL,
  correct kind/scope and unknown/NULL relationship. UUID kinds are syntax-checked
  and canonicalized. Exact duplicates collapse, contradictory duplicates remain;
  fact ordering is canonical. Kind-defined dependency groups identify correlated
  provider aliases; no caller-supplied independence, score or strong threshold.
- `SourceObservationResolver`: stateless, no I/O or callbacks. Candidates are
  explicit caller hypotheses, never discovered from labels, paths, BSD nodes,
  UUIDs, reader serials or vendor/model. Limit 200 incoming candidates before
  dedup. Sorted unique output IDs; no first/last/recency selection.
- Conflict precedes everything: original Conflict, explicit conflicting typed
  evidence, disagreeing same-subject/kind alias values, inconsistent duplicate
  local records, retired candidates, stale/wrong observation/assertion/target
  references, missing targets or malformed manual structure. A manual selection
  cannot erase contradictory facts or incomplete candidate coverage.
- A current active explicit volume/partition association or correction may
  return ManualAssociation after those checks, including from an ambiguous
  hypothesis set. Incomplete/missing evidence alone is not a contradiction and
  cannot upgrade this manual assertion to hardware verification. Revocation
  removes the target and proceeds to the unresolved outcomes.
- Original Ambiguous or multiple distinct supplied hypotheses returns Ambiguous.
  Zero or one weak hypothesis returns Unknown. UniqueStrongMatch is reserved in
  the existing model with no producer, injection hook or hypothetical profile.
  Approved real strong profiles = 0. No automatic admission/reconnect/capture.
- `SyntheticSourceResolutionRepository`: read seam only. Requires an existing
  exact stored observation (ID/session/revision/scope/state/time/provenance),
  canonical evidence equality, caller's expected current assertion revision and
  existing explicit candidate IDs. New/changed observations cannot reuse an old
  assertion. Latest correction/revocation is authoritative. Target revisions and
  retirement are rechecked. Bounded indexed reads use the existing serialized
  BEGIN IMMEDIATE for one consistent view; it reserves the writer slot but makes
  no row writes. SQL errors propagate; transaction rollback retains ownership.
  The result is point-in-time, never capture/root authorization. The older
  Task058 convenience resolver is unchanged.

No live OS observer/adapter/reducer exists. Repeated, reordered generated envelope
calls simply recompute the same deterministic result; no event delivery mutates
stored state. No new schema, migration, table, capture receipt, snapshot
reattribution, Drive Set, Save Comparison, UI, dependency or device access.

## Executed validation and causal debugging

All new tests use generated values and unique temporary v10 catalogs. Existing
selected regressions use generated catalogs/files and existing XCTest host
isolation. Paths/nodes/serials in the new fixtures are inert strings.

Commands executed from the repo; destination platform=macOS,arch=arm64:

1. Causal RED: `xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration
   Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath
   .ai-scratch/task059/Debug
   -only-testing:FSDTests/SourceObservationResolverTests/testCurrentManualAssociationRemainsManual`.
   `red-manual.log`: exit65, exactly 1 test/1 intended failure, scaffold Unknown
   versus expected ManualAssociation. After production implementation,
   `green-manual.log`: exit0, 1/1. Initial `red.log` had zero tests after a project
   registration script assertion; it is NOT causal RED or a test success claim.
2. Expanded focused command selects SourceObservationResolverTests,
   SyntheticSourceResolutionRepositoryTests, PhysicalDriveIdentityTests and
   PhysicalDriveMigrationTests using the same xcodebuild arguments.
   `focused-2.log`: exit0, 60/60, zero failures/skips: new pure28 + integration8
   + Task058 identity16 + migration8. `focused-1.log` was a setup compile failure
   because the new fixture called nonexistent executeScript. Source inspection
   identified CatalogDatabase.execute; the new fixture now submits its generated
   statements individually. No existing production or test file was weakened.
3. Final regression command is preserved in
   `.ai-scratch/task059/regression-command.json`: xcodebuild test as above,
   explicit 36-suite selection. `regressions-1.log` and regressions-exit.json:
   exit0, 527/527, zero failed/skipped, 52.684 seconds. This is 36 new tests plus
   491 existing regressions (including the 24 Task058 tests), not additive to the
   overlapping focused run. Includes complete SchemaMigration/CatalogDatabase/
   ExpectedState, snapshots/history/Collections/capture/recovery/lock, comparison
   semantics/persistence/GUI source boundaries, browse/search/export and
   classification isolation/security/runtime suites. Exact suite list follows.
   The generated disk-image mount case is explicitly excluded because mount
   operations are forbidden; external device/Owner catalog and nonrequired
   million-entry/helper-LLDB/scale suites were not selected, not claimed tested.
4. Clean normal app builds: `xcodebuild clean build -project FSD.xcodeproj
   -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64'
   -derivedDataPath .ai-scratch/task059/FinalDebug` and corresponding
   Release/FinalRelease: exit0, BUILD SUCCEEDED in build-debug.log and
   build-release.log. Both build the reviewed production sources; unrelated
   existing warnings retained. No release/signing/notarization operation.
5. Integration XCTest compares every catalog relation before/after repeated
   resolution, total_changes unchanged, retained manual event chain, exact
   captured snapshot/entry/Collection/comparison rows after explicit correction/
   revocation, and existing immutability trigger rejection. Reopen reproduces
   identical result. SQLite schema10, foreign_keys=1, integrity_check=ok and empty
   foreign_key_check execute against generated catalogs. Task058 production
   migration/rollback/fresh-parity regressions pass; no migration was changed.
6. `python3 .ai-scratch/task059/verify_scope.py`: PASS, exact 8 substantive paths,
   protected hashes and 111 old histories, architecture/test-plan append-only,
   no new source/device/capture/mutation dependencies, reviewed digest equal.
   `git diff --check`: PASS. Review covered all new source bytes and the exact
   tracked project/doc diff. No accepted ADR or BRAIN State change.

Regression selection (all FSDTests):
- `PhysicalDriveIdentityTests`
- `PhysicalDriveMigrationTests`
- `SchemaMigrationTests`
- `CatalogDatabaseTests`
- `ExpectedStateInventoryTests`
- `TerminalCollisionEvidenceTests`
- `SnapshotLifecycleTests`
- `SnapshotHistoryTests`
- `SnapshotCollectionsTests`
- `Milestone2CaptureTests`
- `MilestoneConditionTests`
- `ManualSessionASubstituteTests`
- `CaptureErrorBoundaryTests`
- `M5ReliabilityTests`
- `ComparisonSemanticsTests`
- `ComparisonIdentityTests`
- `ComparisonSnapshotStateTests`
- `ComparisonModeTests`
- `ComparisonPersistenceTests`
- `ComparisonWorkspaceModelTests`
- `ComparisonBrowserModelTests`
- `ComparisonGUISourceBoundaryTests`
- `ComparisonGUIValidationTests`
- `ComparisonEndToEndProbeTests`
- `LazyTreeBrowsingTests`
- `MetadataSearchTests`
- `JSONExportTests`
- `ClassificationEnrichmentTests`
- `ClassificationSourceReaderTests`
- `ClassificationProviderContractTests`
- `ClassificationRuntimeServiceTests`
- `ClassificationInvocationIsolationTests`
- `ClassificationSecurityIntegrationTests`
- `SnapshotBrowserClassificationTests`
- `SourceObservationResolverTests`
- `SyntheticSourceResolutionRepositoryTests`

Excluded method:
`MilestoneConditionTests/testNestedMountBoundaryAgainstAGeneratedDiskImage`.
This is deliberate safety exclusion, not a passing real-device test.
Raw logs and xcresults remain under ignored `.ai-scratch/task059/Debug/Logs/Test/`.
Durable generated test definitions are committed; no hardware/source facts are
needed to reproduce them.

## Independent review and exact scope

Separate read-only reviewer `/root/task059_review` loaded execution and review
skills, independently inspected all eight source/test/project/doc paths and
causal RED/GREEN/final receipts. No reviewer repairs, test executions, State,
Owner-data access or separate reporting mutation. Final result: no material
findings. Coverage includes conflict/manual/revocation/staleness, consistent
transaction and nested failure ownership, input bounds/order, row nonmutation,
zero strong promotion and no source/capture dependency. One nonmaterial note:
pure typed envelopes permit cross-kind provider/property label reuse; kinds
remain host-separated, no profile promotes them, and the persisted seam requires
exact stored facts. No speculative framework or repair was added for this note.

Independent final aggregate SHA256, sorted relative path + NUL + per-file hex
SHA256 + LF, matched by Worker:
`a4bce7914bf8218bf3c967cac7e36f375f6eb2875f1072b2f9ee85b5b0d2d3c2`.
Review inspected Worker execution receipts; it is not an independent test rerun
or hardware/empirical acceptance.

Exact substantive paths:
- `FSD/Model/SourceObservationResolver.swift`
- `FSD/Catalog/SyntheticSourceResolutionRepository.swift`
- `FSDTests/SourceObservationResolverTests.swift`
- `FSDTests/SyntheticSourceResolutionRepositoryTests.swift`
- `FSD.xcodeproj/project.pbxproj`
- `docs/ARCHITECTURE.md`
- `docs/TEST_PLAN.md`
- `docs/PRODUCT_STATE.md`

Reporting paths, all Worker-owned only:
- `handoffs/FSD_FSD2_SOURCE_OBSERVATION_FAIL_CLOSED_RESOLVER_059_D_20261019-015126.md` (one new immutable source)
- `handoffs/CURRENT_HANDOFF.md` (full source mirror)
- `STATE/TASK_LEDGER.tsv` (one new pending Worker row)
- `STATE/EVENTS.jsonl` (one appended Worker return)

Technical SHA is the known baseline/basis, not this source's future publication
SHA. Publication resolves from Git history and Desktop's final fetched receipt.
The recovery BRAIN authorization event/State bytes, accepted ledger rows, rule
ledger and historical handoffs remain unchanged by this Worker cycle.

## Requirement accounting

All rows below are EVIDENCED within the synthetic-only scope; empirical hardware,
live OS notifications, Auto Capture and full acceptance are excluded claims.

| ID | Requirement | Evidence |
|---|---|---|
| R01 | Authority and accepted Task058 pointer | Canonical ACTION at verified5ddf1cd; clean fetch0/0; no earlier publication claim |
| R02 | Required bootstrap and safe scope | Named authorities/skills, baseline1524 tracked hashes,111 histories protected |
| R03 | Immutable bounded typed envelope | SourceObservationEnvelope; scopes, session/revision, provenance, values/time/state/completeness/lineage |
| R04 | Safe read integration | Stored envelope equality, latest event/expected revision, transaction, bounded indexed reads |
| R05 | Strong profile prohibition | Count0; no UniqueStrongMatch producer; manual stays manual |
| R06 | No schema or forbidden source scope | All schema/migrations/oldproduction hashes unchanged; no source IO/hardware/service |
| R07 | Scenario1 no evidence | testNoEvidenceIsUnknown |
| R08 | Scenario2 same display label | testSameDisplayNameDistinctLocalRecordsNeverMatches |
| R09 | Scenario3 reused path | testReusedMountPathHasNoIdentityOrIO |
| R10 | Scenario4 reused node | testReusedBSDNodeHasNoIdentity |
| R11 | Scenario5 missing/malformed UUID | testMissingAndMalformedUUID |
| R12 | Scenario6 clone UUID | testClonedUUIDCandidateHypothesesRemainAmbiguous |
| R13 | Scenario7 distinct partitions | testDistinctPartitionsUnderOneGeneratedSessionStaySeparate |
| R14 | Scenario8 reader/media | testSameReaderDifferentMediaNeverSelectsDrive |
| R15 | Scenario9 correlated aliases | testIdenticalAliasesShareOneLineageWithoutPromotion |
| R16 | Scenario10 contrary aliases | testContradictoryAliasesConflictInBothOrders |
| R17 | Scenario11 mixed validation | testMixedValidatedAndUnverifiedFieldsNeverVerifyHardware |
| R18 | Scenario12 duplicate candidates | testDuplicateCandidateRecordsDeduplicateOrConflict |
| R19 | Scenario13 singleton weak | testSingleWeakPlausibleCandidateRemainsUnknown |
| R20 | Scenario14 current manual | testCurrentManualAssociationRemainsManual and persisted workflow |
| R21 | Scenario15 correction | testManualCorrectionSelectsExplicitIDDespiteAmbiguity and event chain |
| R22 | Scenario16 revoke | testRevocationDoesNotFallBackToOldTarget and persisted workflow |
| R23 | Scenario17 stale observation | testStaleObservationAndWrongSubjectConflict and seam wrong session/ID/revision |
| R24 | Scenario18 stale target | testStaleTargetRevisionConflicts |
| R25 | Scenario19 retired target | testRetiredTargetConflicts and persisted retirement |
| R26 | Scenario20 missing target | testMissingTargetConflicts and missing candidate seam |
| R27 | Scenario21 later contradiction | testContradictionWinsOverManualAndAllCandidateOrders and altered stored evidence seam |
| R28 | Scenario22 repeated/reordered deliveries | testRepeatedAndReorderedGeneratedDeliveriesAreStateless |
| R29 | Scenario23 partial/provenance | testPartialMissingProvenancePreservedAndManualNeverVerified |
| R30 | Scenario24 retry/nonmutation | testGeneratedRetryAndReorderedCandidatesHaveNoMutation; total_changes unchanged |
| R31 | Scenario25 no strong profiles | testZeroProfilesAcrossEveryScopeAndOriginalState |
| R32 | Scenario26 reopen | testAliasCanonicalizationAndReopenReproduceResult |
| R33 | Scenario27 immutable history | testSnapshotCollectionEntryAndTerminalComparisonFactsStayIdentical |
| R34 | Scenario28 source/capture isolation | No I/O or capture dependency; inert path tests; boundary regression and independent review |
| R35 | Scenario29 bounds/order | testBoundedInputAndTypedValidation; testCandidateOrderingAndMaximumAreDeterministic |
| R36 | Scenario30 no first/last/recency | Reverse facts/candidates, Conflict/incomplete coverage before manual; no match ranking |
| R37 | Required regressions/builds | Executed60focused;527final;clean arm64Debug/Release, zero failures |
| R38 | Independent code review | Separate read-only review, exact8-path digest match, no material findings |
| R39 | Catalog integrity/error/ownership | SQLite FK/integrity; nested transaction failure usable; existing schema/migration invariants pass |
| R40 | Exact diff and honest boundaries | Scope/hash/diff review; narrow docs, no ADR promotion, BRAIN pending; single return |

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=40
WORKER_REQUIREMENTS_EVIDENCED=40
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

## Finalizer closure and acceptance limits

Worker-local result PASS_WITH_ADVISORY; BRAIN alone reviews/classifies/accepts.
Finalizer closure follows execution postflight: one source/CURRENT/Worker ledger
and event/Desktop; canonical prechecker, normal commit/push/fetch, clean/synced
postchecker and exact Desktop/current/operator parity. Future publication/checker
results are not preclaimed in this immutable source. Actual closure receipts and
full publication SHA are returned after execution and placed in Desktop transport.

Proposed State delta is only consideration of this synthetic contract/resolver
implementation for acceptance; no accepted State or active next is authored.
No real hardware identity, approved strong profile, H01–H14, live mount detection,
automatic reconnect, Auto Capture, UI, Drive Sets, saved comparisons, Full Feature
Complete or Internal Acceptance Complete proof. ADR036 remains Proposed / Owner
Direction Approved / Technical Proof Pending, as do the other Wave A technical
boundaries. Existing manual E2E/VoiceOver/privacy advisories remain unchanged.
No Owner catalog migration/open is performed or authorized. Task060 is not
started. Transport: `/Users/cenvu/Desktop/04_FSD_BRAIN.md`.
