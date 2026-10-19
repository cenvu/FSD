UPDATED_AT: 2026-10-19T11:09:06+07:00

# Task063 Explicit Save Comparison UI — Worker return

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD2_EXPLICIT_SAVE_COMPARISON_UI
HANDOFF_ID=handoffs/FSD_FSD2_EXPLICIT_SAVE_COMPARISON_UI_063_D_20261019-110906.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=53d4478e8023eab8419116cdaabcf8e97657aaef
REMOTE_HEAD=53d4478e8023eab8419116cdaabcf8e97657aaef
LAST_VERIFIED_AT=2026-10-19T11:09:06+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|docs/AGENT.md|STATE/PROJECT_STATE.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-independent-review/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|docs/DECISIONS.md|handoffs/FSD_FSD2_COMPARISON_COMPLETION_RECEIPT_FOUNDATION_061_D_20261019-094910.md|handoffs/FSD_FSD2_SAVED_COMPARISON_DURABLE_BACKING_062_D_20261019-102428.md|FSD.xcodeproj/project.pbxproj|FSD/Diff/SavedComparisonRepository.swift|FSD/UI/ComparisonCreationView.swift|FSD/UI/ComparisonDestinationView.swift|FSD/UI/ComparisonWorkspaceModel.swift|FSD/UI/ComparisonWorkspaceView.swift|FSD/UI/SavedComparisonsModel.swift|FSD/UI/SavedComparisonsView.swift|FSDTests/SavedComparisonUITests.swift|docs/ARCHITECTURE.md|docs/PRODUCT_STATE.md|docs/TEST_PLAN.md|docs/UX_UI_SPEC.md|FSD/UI/ComparisonBrowserModel.swift
CURRENT_PHASE=POST_V0_1_FSD2_FOUNDATION
CURRENT_GATE=FSD2_EXPLICIT_SAVE_COMPARISON_UI_063
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_FOR_SCOPED_UI;MANUAL_VOICEOVER_OWNER_VISUAL_REAL_STORAGE_HARDWARE_ACCEPTANCE_PENDING
PROPOSED_NEXT=WAIT(BRAIN_REVIEW_TASK063_EXPLICIT_SAVE_UI)
NO_AUTO_NEXT=YES

## Execution lock and authority

PROJECT=FSD
TASK_ID=FSD2_EXPLICIT_SAVE_COMPARISON_UI_063
ROLE=WORKER
BASE_HEAD=53d4478e8023eab8419116cdaabcf8e97657aaef
UPSTREAM_HEAD=53d4478e8023eab8419116cdaabcf8e97657aaef
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=EXPLICIT_SAVE_UI_IDEMPOTENT_DISCOVERY_OFFLINE_PAGED_LIBRARY_SAFE_DELETE_SYNTHETIC_ONLY
ALLOWED_PATHS=14_SUBSTANTIVE_EXACT_PATHS_BELOW_PLUS_THIS_HISTORY_CURRENT_WORKER_LEDGER_EVENT_DESKTOP
FORBIDDEN_PATHS=SCHEMA_MIGRATIONS_FORMAT_RECEIPT_WRITER_ACCEPTED_PROJECT_STATE_RULE_LEDGER_OLD_HISTORY_ADR_STATUS_PROVIDER_HELPER_OWNER_DATA_HARDWARE_RELEASE_TASK064
SUCCESS_CRITERIA=EXPLICIT_SAVE_RECEIPT_ELIGIBILITY_STABLE_RETRY_RESTART_OFFLINE_TYPED_BROWSE_SAFE_DELETE_CLOSE_ORDERING_RESPONSIVE_UI_TESTS_REVIEW_PUBLICATION
VALIDATIONS=GENERATED_FILE_CATALOG_SWIFT_SQLITE_XCTEST_OWN_WINDOW_AX_CAPTURE_FK_INTEGRITY_ARM64_BUILDS_PROTECTED_HASHES_EXACT_CHECKER
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
WORKER_RESULT=PASS_WITH_ADVISORY

FACT: physical main began clean30914b3801e70b3a4095b980f7bf35d01e4257c7.
Fetch found exactly one BRAIN-only commit,53d4478,changing only accepted State,
ledger andappend-only events;inspected before safe ff-only to expected baseline.
Task063 is explicitly authorized. No reset,clean,stash,force,rebase,Ownerwork overwrite.
Final fresh fetch/status observed same base0/0 before finalization. Origin canonical.
Read local Ownerpolicy,Compact,canonical State/ledger/events,CURRENT,ADR012/028/038,
UX13–14,Architecture17–18,Tasks061/062immutable handoffs andactual named implementations,
models/tests/Xcode. Loaded execution,independent-review,finalizer andmacOS SwiftUI/build
skills. Exact task supersedes generic run-script/environment setup suggestions;
no new helper/config/launch infrastructure or Owner catalog was introduced.

## Concrete implementation

SaveComparisonControls exposes intentional Save Comparison/Command-S,eligibility
reason,indeterminate busy/cancel,retry,bounded error andsuccess/Open Saved feedback.
Completion/startup/navigation/selection/close never invoke Save. Only complete work
with a genuine validated receipt is admitted;legacy receiptless andinvalid terminal
evidence reject without reconstruction,currentprofile substitution or source rescan.
Save remains Task062's unchanged single-transaction all-or-none backend.

SavedComparisonsModel serializes all saved receipt/discovery/copy/seal/reader work on
a dedicated background queue. UI IDs derive deterministically from a versioned
namespace+exact cataloggeneration/completiontoken/ComparisonID+sorted observeddeleted
operation IDs. Uncertain retry/redraw/restart therefore reuse identity. Read-only
operations lookup admits at most4096 total catalog operations via256-row primary-key
pages plus one bounded overflow page(max4352fixed-size rows read),including
tombstones;above the4096 supported catalog limit eligibility fails closed with
specific messaging. Any exact existing READY suppresses another Save. Deletion never
silently regenerates evidence;Save Again as New is a separate confirmed intent.
No schema14,new preferencefile,format change or unsafe name/content deduplication.

ComparisonWorkspaceModel subscribes synchronously to saving state. The original
browser invalidates queued callbacks andpauses all main-actor catalog-read entrypoints
before the transaction starts;after settlement it reloads its bounded current page.
The original browser also remains paused ontheSavedsurface andresumes only after
a queued catalog-idle barrier whenreturningtoCompare,includinga readerclosedbefore
itsvalidationfinishes. Explicit Cancel Save andClose cancels then waits behind Save's worker/main-outcome
barrier before existing workspace disposal. A late cancellation may lose to commit;
UI preserves and reports that actual saved success. No speculative onDisappear
cleanup was added for an existing running capture/comparison.

Saved Comparisons is a labelled separate destination subsection;Recent history now
explicitly explains its temporary live lifecycle. Library uses stable artifact IDs,
frozen receipt summaries,empty/loading/error/reload,up-to20-artifact pages and8MiB
receipt prefix admission. A valid large receipt always remains reachable;next-page
truth uses an ID-only keyset probe rather than assuming20rows. Corrupt summaries
surface a bounded error;full graph validation is performed on opening.

Offline detail uses only SavedComparisonReader andfrozen receipt values,with256-row
pages for all results,sides,issues,collision groups/members andexact side-owned
selected-entry lookup. LEFT=Before/Reference;RIGHT=After/Changed. Frozen executed
profile/revision/flags/rules/tolerance,completion time,warnings,counts includingignored
meaning are visible. Typed NULL/Int64/TEXT/BLOB values preserve exact display and
base64;local navigation IDs andoriginal provenance are distinguished. Missing links
remain missing;collision membership never invents a match. Content Not Verified
explicitly excludes content hashing andphysical-device verification. No newhierarchy.

Delete requires destructive confirmation identifying exact artifact UUID;the existing
repository tombstone deletion owns only that savedgraph. Reader closes andlibrary
refreshes after success. Captures,organizers,identity evidence andother artifacts
remain unchanged. Small read-only adapters add operation discovery,frozen summaries
andexact side entry lookup;schema/DDL/receiptformat/writer andsave/delete bodies are
byte-identical to baseline. Sendable repository/reader use immutable ownership and
CatalogDatabase's recursive lock;testobserver configured before concurrent dispatch.

## Executed validation and limits

Final exact regression command:
```sh
xcodebuild \
  test \
  -project \
  FSD.xcodeproj \
  -scheme \
  FSD \
  -configuration \
  Debug \
  -destination \
  platform=macOS,arch=arm64 \
  -derivedDataPath \
  .ai-scratch/task063/Debug \
  -only-testing:FSDTests/PhysicalDriveIdentityTests \
  -only-testing:FSDTests/PhysicalDriveMigrationTests \
  -only-testing:FSDTests/SchemaMigrationTests \
  -only-testing:FSDTests/CatalogDatabaseTests \
  -only-testing:FSDTests/ExpectedStateInventoryTests \
  -only-testing:FSDTests/TerminalCollisionEvidenceTests \
  -only-testing:FSDTests/SnapshotLifecycleTests \
  -only-testing:FSDTests/SnapshotHistoryTests \
  -only-testing:FSDTests/SnapshotCollectionsTests \
  -only-testing:FSDTests/Milestone2CaptureTests \
  -only-testing:FSDTests/MilestoneConditionTests \
  -only-testing:FSDTests/ManualSessionASubstituteTests \
  -only-testing:FSDTests/CaptureErrorBoundaryTests \
  -only-testing:FSDTests/M5ReliabilityTests \
  -only-testing:FSDTests/ComparisonSemanticsTests \
  -only-testing:FSDTests/ComparisonIdentityTests \
  -only-testing:FSDTests/ComparisonSnapshotStateTests \
  -only-testing:FSDTests/ComparisonModeTests \
  -only-testing:FSDTests/ComparisonPersistenceTests \
  -only-testing:FSDTests/ComparisonWorkspaceModelTests \
  -only-testing:FSDTests/ComparisonBrowserModelTests \
  -only-testing:FSDTests/ComparisonGUISourceBoundaryTests \
  -only-testing:FSDTests/ComparisonGUIValidationTests \
  -only-testing:FSDTests/ComparisonEndToEndProbeTests \
  -only-testing:FSDTests/LazyTreeBrowsingTests \
  -only-testing:FSDTests/MetadataSearchTests \
  -only-testing:FSDTests/JSONExportTests \
  -only-testing:FSDTests/ClassificationEnrichmentTests \
  -only-testing:FSDTests/ClassificationSourceReaderTests \
  -only-testing:FSDTests/ClassificationProviderContractTests \
  -only-testing:FSDTests/ClassificationRuntimeServiceTests \
  -only-testing:FSDTests/ClassificationInvocationIsolationTests \
  -only-testing:FSDTests/ClassificationSecurityIntegrationTests \
  -only-testing:FSDTests/SnapshotBrowserClassificationTests \
  -skip-testing:FSDTests/MilestoneConditionTests/testNestedMountBoundaryAgainstAGeneratedDiskImage \
  -only-testing:FSDTests/SourceObservationResolverTests \
  -only-testing:FSDTests/SyntheticSourceResolutionRepositoryTests \
  -only-testing:FSDTests/DriveSetsTests \
  -only-testing:FSDTests/DriveSetMigrationTests \
  -only-testing:FSDTests/ComparisonCompletionReceiptTests \
  -only-testing:FSDTests/CompletionReceiptMigrationTests \
  -only-testing:FSDTests/CancellationRaceStressTests \
  -only-testing:FSDTests/FinalScaleComparisonTests/testOneMillionExplicitDisposalCompletesWithCleanCascade \
  -only-testing:FSDTests/SavedComparisonTests \
  -only-testing:FSDTests/SavedComparisonMigrationTests \
  -only-testing:FSDTests/SavedComparisonUITests
```
Actual exit andwall receipt: `.ai-scratch/task063/regressions-final-exit.json`.
Final634/634 selected tests PASS,0fail,0skip. The prohibited
`MilestoneConditionTests/testNestedMountBoundaryAgainstAGeneratedDiskImage` is
explicitly excluded from selection,not reported as an executed skip. This includes
22new focused UI/model/integration tests and612 affected existing catalog,comparison,
Task058–062,snapshot,organizer,source-boundary,lifecycle,cancellation/recovery tests.
Generated file-backed databases report foreign_keys=1,emptyforeign_key_check and
integrity_check=ok. Original user facts/Collections/DriveSets/PhysicalDrive andsaved
transaction/migration/immutability tests remain intact. No hardware acceptance.

Causal/debug evidence,all retained under `.ai-scratch/task063/`:
- red.log/green-1.log: missing XCTest group registration build failure,not causalRED.
- red-2.log: compile optional-detail flattening issue,not causalRED.
- red-3.log: actual1test1failure on mislabelling Recent asSaved;corrected text.
- focused-1.log:16tests3failures;wrong receipt triggerfixture anddestructive semaphore
  predicate consumed twice. Corrected fixture/helper only;guards unchanged.
- focused-2/3:AX method/getter andnative key-equivalent spelling compile corrections.
- focused-4:18tests3AX/snapshot test assertions;labels attached togroup explicitly,
  disabledbutton label/title lookup fixed. Native confirmation Cancel returnsfalse
  from AX call butactual candidate cleared;test now verifies the observed state.
- ui-1:15 own-window CLI screenshot failures (couldnotcreateimage),no product claim.
  NSView bitmap nativecontrol rendering was incomplete;not accepted visual evidence.
- ui-2:AX functional1/1;ui-3:2/2 includingvalidlarge-receipt adaptivepage andactual
  current-process ScreenCaptureKit capture. Finalcaptures replaced earlier attempts.
- focused-final:20/20 beforefinal race repair,63.825s body;notfinalbyte proof.
- regressions-superseded:interrupted byWorker exit75 after167.686s whenpending original
  browser callback/main-DB-lock race was found bysource review;never claimedPASS.
- race-red:actual1test1failure,2.039s mainwait versus<0.5s requirement whileSavegateheld.
  Narrow pause/generation guards repair that specific cause;repairedfocused/fullgreen.
- focused-repaired:21newUI+7existingmodel tests PASS;save callback race repaired.
- regressions-superseded-2:Worker interrupted exit75 at133.066s to fixsameboundary
  forhiddenbrowser/offlinereader;notPASS. offline-race-red:1test1failure2.007s.
- focused-repaired-2:22newUI+7existingmodel tests;currentcandidate;finalfullsupersedes.

Final scale/limits measurements:
```text
TASK062_SCALE total=10000 results=5000 save_seconds=9.387411916686688 read_total=10000 page_max=256 sqlite_growth_bytes=18100224 rss_before=672251904 rss_after=672251904
TASK062_SCALE total=100000 results=50000 outcome=FAIL_CLOSED_ROWS save_seconds=0.0029169166809879243 copied_pages=0 rss_before=672251904 rss_after=672251904
TASK063_UI_SCALE entries=10000 results=5000 save_seconds=9.440194499969948 main_heartbeats=472 artifact=C4E1E301-179D-4774-8CD0-FD8DA7F181B7
```
10K-entry Save completes whilemain-actortimer heartbeats continue. The final pending
page race test also keeps maincallback below0.5s during an injected heldtransaction.
100K entries+50Kresults still reject beforecopy under accepted100Kaccounted-row cap;
no claim of100KSave support. Cooperative ceilings remain256MiBmetadata,
512MiBlogicalgrowth,60s;not hardOS limits/diskreservation/fsyncguarantee.

Clean arm64 Debug andRelease `xcodebuild clean build` ran on separate isolated
FinalDebug/FinalRelease derived data,actual logs/exit receipts below. Xcode26.3
build17C529. Existing SnapshotBrowserView interpolation/AppIntents notices and
legacy-style own-process AX test-enablement warnings do not prove product failure;
no new production compiler warning remains. No signing/release or public packaging.

## UI/accessibility and source boundary

15final PNGs in `.ai-scratch/task063/screenshots/`:
`completed-save`, `saved-library`, `offline-detail`, `ineligible-save`, `bounded-error`
eachat1120/1330/1440points. Actual compositor capture uses SDK
SCShareableContent.currentProcess,then exact ownedwindowID andSCScreenshotManager;
no otherapplication/window/global AX enumeration. Error screenshot uses intentionally
lowered rowbudget onsmallgeneratedcatalog,not fabricated100Kthroughput. ActualAX
Save/Open/Delete/Cancel anddestructive confirmation are exercised;actual Command-S
routes to Save;key-view traversal stays withinownwindow. Result/status wording does
not depend only oncolor. Independent review inspected narrow/wide finalimages.
Manual VoiceOver operation,exhaustive keyboardergonomics andOwner visualacceptance
remain PENDING as explicitly allowed bytask,not replaced byautomatedlabels.

Only generated isolated catalogs/testhost files andinert synthetic metadata were
used. Save/browse touch no Ownercatalog,sourcepayload,rescan,native sourcepicker,
volume/device probe,classification,AutoCapture,mount observer orphysical media.
Selected broader classification/source-boundary regressions deliberately use their
own generated isolated fixtures,including scoped fixture-content reads;these are
not Save/browse behavior orOwnerdata. Prohibited livemount-image test was unselected. No global userconfig orMCP registration change. Simulated rollback and
file reopen are not realpower-loss/diskfull/hardwareproof. ADR036/037/038 statuses,
accepted PROJECT_STATE andrulepromotion ledger are preserved.

## Independent review and exact scope

Separate read-only reviewer `/root/task063_review` loaded requiredskills anddirect
authorities;reviewed14substantivepaths,actual source/diff/tests/docs,protectedhashes,
finalexecutedlogs/builds andownedwindowimages. Actual result PASS_WITH_ADVISORY;
no unresolved materialfindings. Validlarge-receipt list blockage andpending-page
race were repaired withinTask063 andreviewed. Same-harness reviewer separation is
not claimed model-family diversity. Reviewer made nofileedits/publication anddid
not independently rerun Xcode;claims are bounded byits direct source/evidence read.

Substantive aggregate SHA256=0293600d76ce26053d2dc7ebba62aef85dec19e6604684ae8a80c8ce9df0a340
Protected baseline paths before reporting=1533;previous
immutable histories=115,all byte-identical. Save/delete
bodybyte parity baselinePASS. Exact14substantivepaths:
- FSD.xcodeproj/project.pbxproj
- FSD/Diff/SavedComparisonRepository.swift
- FSD/UI/ComparisonBrowserModel.swift
- FSD/UI/ComparisonCreationView.swift
- FSD/UI/ComparisonDestinationView.swift
- FSD/UI/ComparisonWorkspaceModel.swift
- FSD/UI/ComparisonWorkspaceView.swift
- FSD/UI/SavedComparisonsModel.swift
- FSD/UI/SavedComparisonsView.swift
- FSDTests/SavedComparisonUITests.swift
- docs/ARCHITECTURE.md
- docs/PRODUCT_STATE.md
- docs/TEST_PLAN.md
- docs/UX_UI_SPEC.md

Reporting adds exactly thisone immutablehistory,CURRENTfullmirror,oneWorker-owned
ledger row andoneappend-onlyworker_return event. No acceptedState/classification,
oldhistory,ADRstatus,helper/provider/format/schema orTask064 mutation.

## Requirement-to-evidence postflight

| # | Requirement | Evidence |
|---|---|---|
| 1 | Authority/baseline | Actual clean main30914b3; inspected sole BRAIN State/ledger/events delta; ff-only53d4478 exact baseline and canonical Task063 action. |
| 2 | Explicit Save | Only intentional Save button/Command-S invokes Save; no complete/launch/navigation/browse/close auto-save; executable noSave test. |
| 3 | Eligibility | Complete plus genuine revalidated Task061 receipt; receiptless and running/failed/cancelled/stale/corrupt bounded reasons; no backfill/rescan. |
| 4 | UI states | Indeterminate progress,busy,double-click prevention,cancel,errors/retry and committed-success feedback; lower-budget/time failures no false success. |
| 5 | Main actor responsiveness | Save/all receipt/offline validation worker queue;10K heartbeat measurement;causal pending-original-page RED2.039s fixed by synchronous pause/generation invalidation. |
| 6 | Operation identity | Deterministic versioned SHA256 UUID from generation/token/comparison and exact tombstones;stable retry/redraw/relaunch;concurrent models resolve one artifact. |
| 7 | Uncertain completion recovery | Real backend commit with missing UI acknowledgement;file reopen/fresh model discovers same READY and does not create duplicate. |
| 8 | Deleted operation semantics | Old replay fails;ordinary retry disabled;separate Save Again as New confirmation;new deterministic tombstone-derived identity survives restart. |
| 9 | Read-only adapter bounds | No writes in operations/summaries/entry APIs;4096-operation supported ceiling;256-row pages+oneoverflow(max4352fixedrows);exact triple/side ownership;oversized discovery fails closed. |
| 10 | Saved library | Distinct labels andstable artifact IDs;empty/loading/error/reload;up-to20 rowpages;adaptive8MiB valid-large-receipt pages+exact hasNext probe. |
| 11 | Actual offline reopen | Workspace close deletes both original live transients/entries/comparison;volume/profile deletion;file-backed reopen+fresh model opens exact savedreceipt. |
| 12 | Frozen historical truth | Exact profile/revision/header/issues/time/orientation/summary/warnings retained despite current original/profile mutation;all six kinds andignored meaning. |
| 13 | Typed selected evidence | Independent LEFT before/reference andRIGHT after/changed;missing links staymissing;NULL/BLOB/Int64/Unicode andbase64 no lossy substitution. |
| 14 | Paged results and collision evidence | 256-row pages,next/previous,replaced rows;results/sides/issues/groups/members andemptycategories;collision IDs/provenance clearly labelled,no inferred pairing. |
| 15 | Corruption/errors | Open seals savedgraph before presentation;missing/corrupt/closedcatalog/budget errors clear;no SQL/private provider messages exposed. |
| 16 | Safe confirmed deletion | Destructive dialog names artifactUUID;actual AX confirmation/cancel verified;reader closes+listrefresh;tombstone persists;otherartifact+originalsnapshot bytes preserved. |
| 17 | Save/close ordering | Cancel/wait barrier after actual worker result;rollback then dispose;late cancellation losing to commit retains savedartifact;pending page callbacks cannot block main. |
| 18 | Existing lifecycle/navigation | ADR012 unsaved close disposal andsnapshot history unchanged;original comparison/browser/creation andDriveSets affected regressions run. |
| 19 | Source/privacy scope | Generated catalogs+testhost ownedwindow only;ScreenCaptureKit.currentProcess exactwindowID;no globalAX/Ownerdata/device/picker;Save-browse invokes no sourcepayload/classification calls. |
| 20 | Window/accessibility/keyboard | 15 actual ownedwindow captures5states×1120/1330/1440;AX labels+presses,Command-S,keyview traversal;noncolor statuses. ManualVO/Owneracceptance explicitly pending. |
| 21 | Backend invariants | Schema13/DDL/format/receiptwriter/originals unchanged;save/delete bodybytes exact baseline;Task058–062 migration/FK/integrity/atomicrollback regressions preserved. |
| 22 | Executable regression | Final selected634 XCTest zero failures/skips;prohibited live mount-image test explicitly excluded,not counted as executed skip;exactargv/log below. |
| 23 | Clean builds | Clean macOS arm64 Debug+Release actual BUILD SUCCEEDED;Xcode26.3(17C529);no signing/release. |
| 24 | Independent review/scope | Separate read-only14path reviewer;repaired bounded-list andcallback race;final hashes/logs/screenshots inspected;protectedbaseline paths/history exact;noTask064. |

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=24
WORKER_REQUIREMENTS_EVIDENCED=24
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

## Worker proposal and publication closure

Proposed product-state delta:Task063 explicit Save/offline library now has generated
production-stack UI evidence only;BRAIN adjudicates acceptance. Await BRAIN review
ofTask063;no subsequent product task has started oris self-authorized.

Historical ownpublicationSHA is intentionally not self-referential. ActualprepubHEAD
is recordedabove;resolvepublication with `git log -1 --format=%H -- handoffs/FSD_FSD2_EXPLICIT_SAVE_COMPARISON_UI_063_D_20261019-110906.md`.
Finalizer runs exact canonical prechecker/gitdiffcheck,stages authorized18paths,
normalcommit/push/fetch,postchecker withclean+synced0/0,fullCURRENT/Desktop/Operator
byteparity andprotectedhistory verification. These futurepublication checks are
not claimed executed withinthisprepublication immutable record. Finaltransport and
Worker return contain observed actualpublicationreceipt afterthose checks.

RAW_REFS=.ai-scratch/task063/candidate.json|.ai-scratch/task063/scope-validation.json|.ai-scratch/task063/regression-command.json|.ai-scratch/task063/regressions-final.log|.ai-scratch/task063/regressions-final-exit.json|.ai-scratch/task063/focused-repaired-2.log|.ai-scratch/task063/offline-race-red.log|.ai-scratch/task063/race-red.log|.ai-scratch/task063/build-debug.log|.ai-scratch/task063/build-debug-exit.json|.ai-scratch/task063/build-release.log|.ai-scratch/task063/build-release-exit.json|.ai-scratch/task063/independent-review-final.json|.ai-scratch/task063/screenshots|.ai-scratch/task063/checker-pre.json|.ai-scratch/task063/checker-post.json|.ai-scratch/task063/publication-receipt.json
