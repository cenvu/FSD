# Task051 — Snapshot Collections Organizer Slice

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD2_STAGE1_SNAPSHOT_COLLECTIONS_ORGANIZER
HANDOFF_ID=handoffs/FSD_FSD2_SNAPSHOT_COLLECTIONS_ORGANIZER_SLICE_051_D_20261018-130245.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=2703f1c00ce5dbfcf29e8ed9daa35561cad1c95a
REMOTE_HEAD=2703f1c00ce5dbfcf29e8ed9daa35561cad1c95a
LAST_VERIFIED_AT=2026-10-18T13:03:08+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|STATE/PROJECT_STATE.md|STATE/TASK_LEDGER.tsv|handoffs/CURRENT_HANDOFF.md|docs/UX_UI_SPEC.md|docs/SNAPSHOT_COLLECTIONS.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|scripts/check_control_plane.py
CURRENT_PHASE=POST_V0_1_FSD2_FOUNDATION
CURRENT_GATE=FSD2_SNAPSHOT_COLLECTIONS_ORGANIZER_SLICE_051
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE;ADVISORY=OWNER_COLLECTIONS_VISUAL_ACCEPTANCE_PENDING|MANUAL_VOICEOVER_NOT_PERFORMED|TASK047_EXTERNAL_RETENTION_UNPROVEN|TASK041_PROCESS_PRIVACY_UNPROVEN_OWNER_ACCEPTED
PROPOSED_NEXT=WAIT(OWNER_TASK051_COLLECTIONS_VISUAL_ACCEPTANCE)
NO_AUTO_NEXT=YES

## Task lock and authority

PROJECT=FSD
TASK_ID=FSD2_SNAPSHOT_COLLECTIONS_ORGANIZER_SLICE_051
ROLE=WORKER
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
BASE_HEAD=2703f1c00ce5dbfcf29e8ed9daa35561cad1c95a
UPSTREAM_HEAD=2703f1c00ce5dbfcf29e8ed9daa35561cad1c95a
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=OWNER_APPROVED_ONE_STAGE1_SNAPSHOT_COLLECTIONS_ORGANIZER_VERTICAL_SLICE
ALLOWED_PATHS=FSD/Catalog/SnapshotCollectionRepository.swift|FSD/UI/ComparisonSharedViews.swift|FSD.xcodeproj/project.pbxproj|FSDTests/SnapshotCollectionsTests.swift|docs/UX_UI_SPEC.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|handoffs/CURRENT_HANDOFF.md|handoffs/FSD_FSD2_SNAPSHOT_COLLECTIONS_ORGANIZER_SLICE_051_D_20261018-130245.md
FORBIDDEN_PATHS=STATE/PROJECT_STATE.md|STATE/RULE_PROMOTION_LEDGER.tsv|AGENTS.md|docs/BRAIN_OPERATOR.md|database/schema/migrations|scanner_providers_classifier_helper|SnapshotHistoryRepository|comparison_engine|historical_handoffs|public_release_assets_tags
SUCCESS_CRITERIA=LOGICAL_COLLECTIONS_BY_STABLE_ID|UNSORTED_IS_NULL|BOUNDED_DETERMINISTIC_READS|SCHEMA_V9_UNCHANGED|SOURCE_READ_ONLY|NO_SOURCE_OR_CLASSIFICATION_ACCESS|TESTS_BUILDS_SCREENSHOTS|CANONICAL_REPORTING
VALIDATIONS=FOCUSED_XCTEST|ARM64_DEBUG_RELEASE|FSD_WINDOW_SYNTHETIC_SCREENSHOTS|GIT_DIFF_CHECK|CANONICAL_CHECKER|DESKTOP_CURRENT_PARITY|NORMAL_PUBLICATION
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY

The Owner decision of 2026-10-18 authorized exactly one Task051 Snapshot Collections organizer slice after visually accepting the Task050 Explorer polish from synthetic screenshots. The authorization is limited to logical Collection create/list and moving existing user snapshots by stable SnapshotID, with Unsorted represented as NULL and schema v9 unchanged. Collections are explicitly not physical Drive Sets. The required local Owner Policy (AGENTS.md Owner Policy Always Read), docs/BRAIN_OPERATOR.md, accepted STATE/PROJECT_STATE.md, CURRENT HOT, docs/UX_UI_SPEC.md, docs/SNAPSHOT_COLLECTIONS.md, the task-execution skill, the finalizer skill and the canonical checker were read. Ordinary in-scope implementation, iterative compile/debug, test correction, code review and reporting were completed inside this one Task051 per Owner Issue #1.

## Re-anchor and protected state

Physical repository: /Users/cenvu/DEV/FSD. Origin: https://github.com/cenvu/FSD.git. Branch main. A non-destructive `git fetch origin` confirmed local HEAD=origin/main=2703f1c00ce5dbfcf29e8ed9daa35561cad1c95a and ahead/behind 0/0 at re-anchor. The baseline working tree was clean. Implementation changes are confined to the authorized paths: FSD/Catalog/SnapshotCollectionRepository.swift (new), FSD/UI/ComparisonSharedViews.swift (add-only), FSD.xcodeproj/project.pbxproj (two file registrations), FSDTests/SnapshotCollectionsTests.swift (new) and docs/UX_UI_SPEC.md (new subsection 5.3).

STATE/PROJECT_STATE.md stayed byte-identical to the base (SHA-256 a4716931c102f53d2d3db6237e75f0c11459e1f91adc61a1c826e70e6c52b4b4). STATE/RULE_PROMOTION_LEDGER.tsv and all accepted historical handoffs stayed unchanged. No schema, migration, scanner, provider, classifier, helper, comparison-engine or public release asset was changed. FSD/Catalog/SnapshotHistoryRepository.swift was not modified. The existing Desktop packet was byte-copied before finalizer work to .ai-scratch/task051/finalizer/04_FSD_BRAIN.prepublication.md (SHA-256 55250b373de3180c53e20f7b8233318f007426fdc03c8eaec339318864b49217) as recovery evidence.

## Work completed

### Catalog repository

`FSD/Catalog/SnapshotCollectionRepository.swift` (new, 383 lines) is the only new access layer. It reads and writes the existing schema-version-9 `collections` table and `snapshots.collection_id` and nothing else: no `FileManager`, no URL/provider access, no filesystem or classification call. Types: `SnapshotCollection`, `SnapshotCollectionPage`, `CollectionSnapshot`, `CollectionSnapshotPage`, `CollectionMembershipFilter` (`.all` / `.unsorted` / `.collection(Int64)`), `CollectionMembershipCounts`, and `SnapshotCollectionError` (blankName, duplicateName, collectionNotFound, snapshotNotFound, snapshotNotUser, database) with bounded `errorDescription` that never surfaces raw SQLite text.

- `normalize` applies the single ADR-009/ADR-019 recipe: trim, then whole-string `PathIdentity.caseFold` (NFC + `en_US_POSIX` case fold).
- `createCollection` rejects a blank name and rejects a name whose normalized form already exists, then inserts and reads the row back inside one transaction.
- `listCollections` orders by `normalized_name ASC, id ASC` with a bounded page (`LIMIT limit+1`) and an explicit truncation flag; a single query, no per-row reads.
- `assign(snapshotID:to:)` verifies the row is a `user` snapshot, verifies the target Collection exists, and performs one `UPDATE snapshots SET collection_id = ?`. The existing trigger advances the target `last_used_at`; nothing else is touched.
- `listSnapshots(filter:)` excludes `snapshot_kind = 'transient'` in SQL, filters Unsorted by `collection_id IS NULL` or by exact Collection id, orders newest-first with a bounded page and truncation flag.
- `membershipCounts()` is one bounded `GROUP BY collection_id` aggregate for the sidebar.

### Collections UI

`FSD/UI/ComparisonSharedViews.swift` was extended add-only: a new `FSDDestination.collections` case with breadcrumb "Library / Collections", a sidebar `navigationRow("Collections", …)`, and a destination switch that hosts `SnapshotCollectionsView`, routing Browse back through `model.openSnapshot(summary)` and `selection = .recentCaptures` (falling back to the existing "Catalog unavailable" empty state when the catalog is absent). A new block adds `CollectionFilter`, `@MainActor final class SnapshotCollectionsModel`, `enum SnapshotCollectionsLayout`, `struct SnapshotCollectionsView` and `private struct SnapshotCollectionRow`. The sidebar lists All Captures / Unsorted / each Collection with counts; the snapshot pane lists captured user snapshots with a Move menu labelled "Move to Collection" and a Create Collection form. Create uses `.keyboardShortcut(.defaultAction)`/`.keyboardShortcut(.cancelAction)` with accessibility labels "Create a new Collection" and "Move selected snapshot to a Collection". Layout widths key off `FSDDesignTokens.sidebarBreakpoint` (1280). All pre-existing view text and route callbacks are unchanged.

### Reporting and tests

`FSDTests/SnapshotCollectionsTests.swift` (new, 405 lines) exercises the repository, the model and the view against isolated synthetic catalogs. `docs/UX_UI_SPEC.md` gained subsection 5.3 recording the implemented contract and the explicit deferrals.

## Validation evidence

Focused command:

xcodebuild test-without-building -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -resultBundlePath .ai-scratch/task051/results/focused-suites.xcresult -only-testing:FSDTests/SnapshotCollectionsTests -only-testing:FSDTests/SnapshotHistoryTests -only-testing:FSDTests/ComparisonGUIValidationTests -only-testing:FSDTests/ComparisonGUISourceBoundaryTests -only-testing:FSDTests/SnapshotLifecycleTests -only-testing:FSDTests/ComparisonWorkspaceModelTests -only-testing:FSDTests/ComparisonBrowserModelTests -only-testing:FSDTests/SchemaMigrationTests -only-testing:FSDTests/CatalogDatabaseTests -only-testing:FSDTests/SnapshotBrowserClassificationTests

Result: exit 0; 169 executed, 169 passed, 0 failed, 0 skipped. Per suite: SnapshotCollectionsTests 18, SnapshotHistoryTests 28, ComparisonGUIValidationTests 40, ComparisonGUISourceBoundaryTests 7, SnapshotLifecycleTests 10, ComparisonWorkspaceModelTests 5, ComparisonBrowserModelTests 2, SchemaMigrationTests 25, CatalogDatabaseTests 6, SnapshotBrowserClassificationTests 28. Evidence log: .ai-scratch/task051/logs/focused-suites.log. The first build of the new test file failed once on an argument-order diagnostic (`kind` must precede `name`) and was corrected in-scope; the test-only source-scan assertion was corrected to ignore comment lines; a model-error assertion was corrected from an accidental double-optional check. These are ordinary in-scope corrections.

Normal arm64 builds passed: `xcodebuild build -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64'` and the equivalent Release build both report BUILD SUCCEEDED. `git diff --check` passes.

GUI evidence used only the FSD window and an isolated synthetic catalog. `SnapshotCollectionsTests.testCollectionsGUIRendersAtSupportedWidthsAndCapturesScreenshots` hosts `SnapshotCollectionsView` in an `NSWindow`, resizes it, and writes five synthetic screenshots:

- .ai-scratch/task051/screenshots/collections-all-1120.png — All Captures at 1120 pt with two Collections and Unsorted.
- .ai-scratch/task051/screenshots/collections-all-1330.png — All Captures at 1330 pt.
- .ai-scratch/task051/screenshots/collections-unsorted-1120.png — Unsorted grouping.
- .ai-scratch/task051/screenshots/collections-assigned-1330.png — a Collection holding an assigned snapshot with the Move control.
- .ai-scratch/task051/screenshots/collections-empty-1120.png — an empty Collection.

No native folder picker, Owner catalog/media, Finder, global/recursive accessibility probe or other application was inspected.

## Code review and privacy

Code review: PASS. The repository is a pure catalog access layer using one bounded query per operation and one single-row UPDATE per move; all `CatalogDatabaseError` values are wrapped and presented as bounded text. `createCollection` and `assign` run inside transactions; a failed assignment leaves the snapshot unchanged. The organizer never deletes snapshot or Collection rows and never writes entry rows. The UI change is add-only; existing Main/Home, Explore, Compare and Capture routes and their asserted source strings are preserved. No source contents, Owner folders or physical media were read; no source was changed; no picker or classification was launched. Manual VoiceOver was not performed. Task047 external accessibility retention and the Task041/Task044 process-privacy residual remain UNPROVEN and open. Owner visual acceptance of the Collections organizer remains pending. No release, Task052 or other Stage1/Stage2 work started.

## Worker execution requirement map

| # | Requirement | Outcome | Evidence |
|---:|---|---|---|
| 1 | Fresh canonical root, origin, main, expected base and ahead/behind zero | EVIDENCED | Fetch receipt; HEAD=origin/main=2703f1c00ce5dbfcf29e8ed9daa35561cad1c95a. |
| 2 | Exactly one authorized Task051 slice; no broader Stage1/Stage2 or release | EVIDENCED | Owner decision 2026-10-18; scope limited to the allowed paths. |
| 3 | Collections are logical catalog rows, not physical Drive Sets | EVIDENCED | Repository and UI use only `collections`; docs/UX_UI_SPEC.md 5.3 states the boundary. |
| 4 | Create trims the name and rejects a blank name | EVIDENCED | testCreateListAndReloadPersistAcrossInstances, testBlankNameRejected. |
| 5 | Case- and Unicode-normalized duplicate names are rejected outright | EVIDENCED | testCaseAndUnicodeDuplicateNamesRejected (XYZ/xyz and NFC/NFD café). |
| 6 | Deterministic normalized_name order with a bounded page and truncation flag | EVIDENCED | testListOrderIsDeterministicAndBoundedWithTruncation. |
| 7 | Unsorted is `collection_id IS NULL`, never a stored built-in row | EVIDENCED | testUnsortedIsNullNotBuiltInRow; raw column check. |
| 8 | Membership by stable SnapshotID and Collection id only | EVIDENCED | testMoveAssignsByStableIDAndUpdatesLastUsedAt; assign by SnapshotID. |
| 9 | Identical display names remain distinct snapshots | EVIDENCED | testSameDisplayNamesRemainDistinctSnapshots. |
| 10 | Move into a Collection assigns; move back to Unsorted clears without deleting | EVIDENCED | testMoveBackToUnsortedClearsMembershipWithoutDeleting. |
| 11 | `last_used_at` advances on real assignment and not on view or move-out | EVIDENCED | testMoveAssignsByStableIDAndUpdatesLastUsedAt, testMoveBackToUnsortedClearsMembershipWithoutDeleting. |
| 12 | Invalid snapshot/collection IDs fail safely with no partial write | EVIDENCED | testInvalidIDsFailSafely. |
| 13 | Transient snapshots are excluded from lists and rejected for assignment | EVIDENCED | testTransientSnapshotsExcludedAndRejected. |
| 14 | Captured facts, entries and aggregates stay immutable across moves | EVIDENCED | testCollectionWritesNeverModifyCapturedFacts; row fingerprint unchanged across assign/unassign. |
| 15 | Organizing works offline with the original source removed | EVIDENCED | testAssignmentsWorkWhenSourceDisappears; browse route reads the catalog. |
| 16 | Moving never writes to source files | EVIDENCED | testMovingSnapshotsNeverWritesToSourceFiles; modification date and content unchanged. |
| 17 | Repository has no source, filesystem or classification access | EVIDENCED | testRepositoryHasNoSourceOrClassificationAccess; no FileManager/URL/provider/classif. |
| 18 | Catalog read/write failures are surfaced, not shown as an empty list | EVIDENCED | testModelSurfacesCatalogErrorsInsteadOfEmptyCollections; bounded "code 1" text only. |
| 19 | A new Collections destination is reachable from the sidebar | EVIDENCED | testNavigatorWiresCollectionsAndPreservesExistingRoutes; navigationRow("Collections"). |
| 20 | Browse from the organizer reuses the stored-snapshot route | EVIDENCED | onBrowse routes to model.openSnapshot(summary) and selection = .recentCaptures. |
| 21 | Move and Create controls carry keyboard shortcuts and accessibility labels | EVIDENCED | Source assertions for .keyboardShortcut(.defaultAction/.cancelAction) and both labels. |
| 22 | Layout fits the supported 1120/1330/1440 pt window widths | EVIDENCED | testLayoutFitsSupportedWidths. |
| 23 | Existing Main/Home, Explore, Compare and Capture routes remain intact | EVIDENCED | Pre-existing route source strings asserted unchanged. |
| 24 | Schema version 9 and all migrations are unchanged | EVIDENCED | No schema/migration file changed; SchemaMigrationTests 25/25 pass. |
| 25 | Deferred work (rename/delete/note/capture sheet/default Collection/Drive Sets) is not implemented | EVIDENCED | No such code paths added; docs/UX_UI_SPEC.md 5.3 lists deferrals. |
| 26 | Focused XCTest passes with no failures | EVIDENCED | 169/169 executed in the focused command; log .ai-scratch/task051/logs/focused-suites.log. |
| 27 | Normal arm64 Debug and Release builds pass | EVIDENCED | Both xcodebuild configurations report BUILD SUCCEEDED. |
| 28 | Full diff and whitespace check pass within scope | EVIDENCED | `git diff --check` passes; changes confined to the allowed paths. |
| 29 | BRAIN-owned PROJECT_STATE and rule ledger remain byte-identical | EVIDENCED | PROJECT_STATE SHA-256 a4716931c102f53d2d3db6237e75f0c11459e1f91adc61a1c826e70e6c52b4b4; rule ledger unchanged. |
| 30 | GUI evidence is FSD-window-only with synthetic data | EVIDENCED | Five screenshots under .ai-scratch/task051/screenshots from a hosted NSWindow. |
| 31 | No global/recursive AX, native picker, other-app or Owner-media inspection | EVIDENCED | Isolated synthetic catalog and window-hosted view only. |
| 32 | Task047 external-retention and Task041 privacy advisories remain open | EVIDENCED | Preserved as UNPROVEN/OPEN; no new disclosure. |
| 33 | Single Worker return, append-only events, flat immutable history | EVIDENCED | One new handoff, one worker_return, prior history unchanged. |
| 34 | Manual VoiceOver and Owner visual acceptance of the Collections organizer | NOT_APPLICABLE | Not performed; both remain advisory/pending. |

## Finalizer closure boundary

At the instant this immutable handoff was sealed, the canonical prepublication checker, Desktop parity, commit/push and postpublication checker had not yet run. They are part of this same authorized Task051 finalizer round and their actual outcomes are recorded in the dated Desktop Task051 receipt. The publication SHA is resolved from Git history after push and is not self-referenced in this immutable handoff. No BRAIN-owned classification or accepted-state projection is authored here.

RESULT=PASS_WITH_ADVISORY
WORKER_RESULT=PASS_WITH_ADVISORY
COLLECTION_CREATE=TRIM;BLANK_REJECTED;CASE_AND_UNICODE_DUPLICATE_REJECTED;ONE_TRANSACTION
COLLECTION_LIST=NORMALIZED_NAME_ASC;ID_ASC;BOUNDED_LIMIT_PLUS_ONE;TRUNCATION_FLAG
UNSORTED=COLLECTION_ID_IS_NULL;NEVER_A_STORED_ROW
SNAPSHOT_ASSIGNMENT=BY_STABLE_SNAPSHOT_ID;SINGLE_ROW_UPDATE;TRIGGER_ADVANCES_LAST_USED_AT;MOVE_OUT_CLEARS_WITHOUT_DELETE
IMMUTABILITY=ENTRIES_AGGREGATES_TIMESTAMPS_AND_CAPTURE_FACTS_UNCHANGED;NO_DELETE;NO_ENTRY_WRITES
OFFLINE_PRIVACY=CATALOG_ONLY;NO_SOURCE_READ_OR_WRITE;NO_PICKER_OR_OTHER_APP;NO_CLASSIFICATION;BOUNDED_ERRORS
NAVIGATION=SIDEBAR_COLLECTIONS_DESTINATION;EXISTING_ROUTES_PRESERVED;BROWSE_REUSES_STORED_SNAPSHOT_ROUTE
TESTS=169_EXECUTED_169_PASS_0_FAIL_0_SKIP;COLLECTIONS_SUITE_18
DEBUG_RELEASE=ARM64_DEBUG_PASS;ARM64_RELEASE_PASS
SCREENSHOTS=.ai-scratch/task051/screenshots/collections-all-1120.png|.ai-scratch/task051/screenshots/collections-all-1330.png|.ai-scratch/task051/screenshots/collections-unsorted-1120.png|.ai-scratch/task051/screenshots/collections-assigned-1330.png|.ai-scratch/task051/screenshots/collections-empty-1120.png
CODE_REVIEW=PASS
CHECKER_PRE=RECORDED_IN_DESKTOP_RECEIPT
CHECKER_POST=RECORDED_IN_DESKTOP_RECEIPT
PUBLICATION_SHA=RESOLVED_FROM_GIT_AFTER_PUSH
PUBLIC_RELEASE=UNCHANGED;NO_NEW_RELEASE_OR_ZIP
OWNER_VISUAL_ACCEPTANCE=PENDING
MANUAL_VOICEOVER=NOT_PERFORMED
TASK047_EXTERNAL_RETENTION=UNPROVEN;OPEN
WORKER_LEDGER_CLASSIFICATION_FIELD=PENDING_BRAIN
WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=34
WORKER_REQUIREMENTS_EVIDENCED=33
WORKER_REQUIREMENTS_NOT_APPLICABLE=1
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO
