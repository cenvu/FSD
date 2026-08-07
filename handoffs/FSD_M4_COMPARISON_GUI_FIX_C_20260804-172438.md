# Handoff — Milestone 4 Visual Comparison GUI Correction

## Identity

- Project: FSD (FishSock Differ)
- Task: FSD-M4-COMPARISON-GUI-FIX-0804-10
- Case code: FSD_M4_COMPARISON_GUI_FIX
- Role: Writer (C)
- Agent / model: Claude / deepseek-v4-flash
- Session ID: not exposed by the runtime; task ID used as the session identifier
- Started: 2026-08-04T16:45:00+0700 (approximate)
- Completed: 2026-08-04T17:24:38+0700

## Status

**COMPLETE_WITH_KNOWN_LIMITATIONS** — all five rejection-level audit findings
are closed, the app builds cleanly, the full suite passes, paging is bounded,
cross-page navigation works, no raw SQL exists in the UI, orientation is
canonical, the workspace lifecycle is canonical, required details/errors/
accessibility are implemented, and the isolated Agent-observed validation
succeeded. Remaining limitations are bounded visual polish and deferred manual
acceptance. This is not GUI audit approval and not manual acceptance; an
independent Codex re-audit of the Milestone 4 visual comparison interface is
the required next action.

## Repository State

- Root: `/Users/cenvu/DEV/FSD`
- Branch: unavailable; this directory has no `.git`
- Commit: unavailable; this directory has no `.git`
- Git status: `BLOCKED — NOT A REPOSITORY`
- Pre-existing user changes: cannot be separated through Git. This task
  modified only the comparison GUI, its tests, the project references, the
  two additive repository members, and the minimum current-state documents.

## Audit Findings Addressed (the five rejection-level findings)

| # | Finding | Disposition |
|---|---|---|
| H1 | Target does not compile — `EmptyStateView` private to `FSDApp.swift`, referenced from three GUI files | **CLOSED.** Shared `FSD/UI/ComparisonSharedViews.swift`; app shell no longer declares a private duplicate. |
| H2 | Live-to-snapshot orientation reversed (live left, snapshot right) | **CLOSED.** Snapshot is the left/reference selector, live folder the right/changed selector; `canStart`, validation, request construction and `ComparisonService.liveToSnapshot(liveRoot:snapshotID:)` agree (ADR-027). |
| H3 | GUI-owned raw SQL `ComparisonMetadataDataSource` reading `entries` | **CLOSED.** Data source deleted; metadata/field differences come only from `ComparisonResultRepository.entryMetadata` / `fieldDifferences`. |
| H4 | Unbounded cumulative paging (`current.rows + newPage.rows`) | **CLOSED.** Single retained page of fixed `pageSize` (default 500, clamped to the repository ceiling 5000); deterministic offset; filter change resets to offset 0; stale responses ignored by generation guard; tested row-count ceiling. |
| H5 | Cross-page navigation broken (off-page row not materialized, selection cleared; boundary state wrong) | **CLOSED.** `navigate` follows the repository anchor API; an off-page target materializes the bounded page containing it (offset from the new read-only `position(of:comparisonID:filter:)` adapter) and is selected with details loaded; boundary buttons derive from repository navigation truth, not page emptiness. |

Medium findings from the audit are also closed: `closeComparison()` now
invokes the canonical `ComparisonService.closeWorkspace()` path (ADR-012);
summary pills show every canonical outcome including Matched and Ignored; the
detail pane shows profile name/version, per-side warning counts and snapshot
status; errors are translated to bounded messages with no raw SQLite detail;
accessibility labels, textual outcome wording and ⌘↑/⌘↓ keyboard shortcuts are
in place; the `DispatchQueue` captures follow the existing project pattern.
The Low finding (Compare under "Coming later") is fixed — Compare now sits in
the Catalog sidebar section.

## UI Architecture Correction

- `FSD/UI/ComparisonSharedViews.swift` (new): shared `EmptyStateView`
  (internal, with an accessibility label), `ComparisonUIErrorDescription`
  (bounded error → user-facing message mapping; never raw SQLite text), and
  `ComparisonOutcomeWording` (canonical textual outcome labels that encode
  the left/reference–right/changed orientation).
- `FSD/UI/ComparisonBrowserModel.swift` (rewritten): repository-only data
  boundary; bounded single-page retention; cross-page navigation via the
  anchor API plus the offset adapter; repository-truth navigation availability
  (`canGoNext`/`canGoPrevious`); selection loads both sides' metadata and
  field differences through the repository.
- `FSD/UI/ComparisonWorkspaceModel.swift` (rewritten): canonical orientation
  semantics (`isLiveSelector`, `validationMessage`, `canStart`), request
  construction for all three modes, canonical workspace close and explicit
  disposal, bounded error mapping, `allProfiles()` (the repository's real
  API).
- `FSD/UI/ComparisonCreationView.swift` (rewritten): canonical side selectors
  (left/reference right/changed; live-to-snapshot snapshot-left/live-right),
  validation hint text, accessibility labels/hints, cancel/terminal
  presentation.
- `FSD/UI/ComparisonWorkspaceView.swift` (rewritten): full summary pills,
  page controls with truth-derived disabled states, ⌘↑/⌘↓ next/previous
  difference buttons bound to repository truth, result-row and detail-pane
  accessibility labels, profile/warnings/status in the detail pane, field
  differences from the repository.
- `FSD/App/FSDApp.swift`: shared `EmptyStateView` removed from the shell;
  Compare moved into the Catalog sidebar section; DEBUG-only probe seam
  `-FSDSelectCompare` (same pattern as ADR-026's `-FSDCatalogPath`).
- `FSD/UI/ComparisonDestinationView.swift`: DEBUG-only stderr diagnostic on
  destination load (same pattern as the startup catalog line) so an automated
  probe can confirm the destination loaded without reading the UI.

## Orientation

Canonical (ADR-027): left = reference/before, right = changed/after;
`added` = right-only; `removed` = left-only. Live-to-snapshot: snapshot is
left/reference, live capture is right/changed. Verified by tests that fail
when either side is reversed:

- `testSnapshotToSnapshotOrientationLeftReferenceRightChanged` —
  left.snapshotID/right.snapshotID asserted; added/removed/uncertain/ignored
  rows land on the expected sides.
- `testLiveToSnapshotOrientationSnapshotLeftLiveRight` — real live folder
  through the production scanner; record.left.kind == .user (snapshot),
  record.right.kind == .transient (live); added == ["only-live.txt"],
  removed == ["gone.txt","grown.bin","locked.bin"] (snapshot-only).
- `testLiveToLiveOrientationLeftReferenceRightChanged` — removed = left-only
  file, added = right-only file.
- `testOrientationWordingIsCanonicalAndNotReversed` — added wording contains
  right/changed and never left; removed wording contains left/reference and
  never right.
- `testSnapshotToSnapshotRequestConstructionKeepsSideOrder` — a swapped
  request would be detected by side snapshot IDs on the record.
- `testCanStartLiveToSnapshot` (updated) — canonical side mapping for
  validation.

## Backend-Boundary Correction

- `ComparisonMetadataDataSource` deleted; no UI file executes SQL, references
  table/column names, receives a `CatalogDatabase` to query comparison
  details, or reconstructs comparison semantics from schema knowledge.
- UI metadata path: `ComparisonResultRepository.entryMetadata(id:snapshotID:)`
  and `fieldDifferences(for:comparisonID:)` (both sides from the record's
  side descriptors).
- Additive, read-only repository members (the only backend change, both
  sanctioned by the task):
  - `ComparisonResultRepository.position(of:comparisonID:filter:) -> Int?` —
    the row's zero-based ordinal in the filter's canonical ordering, used to
    materialize the bounded page containing an off-page navigation target.
  - `ComparisonResultRepository: @unchecked Sendable` — matches the existing
    `ComparisonService` idiom so the model's background captures are warning-
    clean.
- `testNoRawSQLOrSchemaKnowledgeInComparisonUISources` scans every
  `FSD/UI/Comparison*.swift` source on disk for forbidden tokens
  (`.query(`, `.execute(`, `.scalar(`, `PRAGMA`, `SELECT `, `FROM entries`,
  `ComparisonMetadataDataSource`, etc.) — a deterministic source-boundary
  guard preventing raw SQL from returning to comparison UI files.
- Backend files untouched: `schema.sql`, `verify.sql`, `CatalogMigrations`,
  `ExpectedState`, `ComparisonEngine`, `ComparisonService`,
  `ComparisonProfileRepository`, `TransientSnapshotLifecycle`, all
  persistence/outcome/cancellation semantics. Schema remains version 7.

## Paging Design and Bound

- Fixed, configurable page size: `pageSize` parameter (default 500), clamped
  to `ComparisonResultRepository.maximumPageSize` (5000).
- The model retains exactly **one** page; `showNextPage()`/`showPreviousPage()`
  replace the current page at `offset ± pageSize`. No page is ever
  accumulated; a 100,000-result comparison can never materialize 100,000 rows
  in UI state.
- `activePageOffset` is deterministic; filter change (`didSet`) resets to
  offset zero; `searchGeneration` discards stale async responses.
- `testRetainedRowCountIsBoundedAcrossEveryPage` walks a 201-row comparison
  page by page and asserts `rows.count ≤ pageSize` at every step;
  `testNextAndPreviousPageAreBounded` verifies the full offset chain
  0→20→40→60→80→60→40→20→0; `testFilterChangeResetsToOffsetZero` and
  `testStaleAsyncResponsesAreIgnored` pin reset and staleness behavior.

## Cross-Page Navigation

- `navigate(direction:)` calls the approved
  `ComparisonResultRepository.navigate` anchor API with `limit: 1`.
- In-page target → selected directly (details load).
- Off-page target → `position(of:)` resolves its ordinal, the page containing
  it is fetched (`offset = (position / pageSize) * pageSize`), the target is
  selected, its details load, and boundary availability is refreshed.
- Boundary controls are disabled from repository navigation truth
  (`canGoNext`/`canGoPrevious` = repository `navigate(limit: 1)` non-empty;
  previous additionally requires a selection), never from page emptiness.
- Tests: `testNavigationWithinPage`, `testNavigationAcrossPageBoundaryNext`,
  `testNavigationAcrossPageBoundaryPrevious`, `testNavigationAtFirstAndLastResult`,
  `testDifferencesOnlyNavigation` (31 differences across 2 pages),
  `testFilterChangeAfterNavigationResetsPageAndSelection`.

## Workspace Lifecycle

- `closeComparison()` invokes `ComparisonService.closeWorkspace()` — the
  canonical ADR-012 path that cancels running live-side comparisons, disposes
  live-side comparison records, and deletes the transient snapshots they
  referenced, while never touching snapshot-to-snapshot comparisons or
  ordinary snapshots — then clears the active workspace and refreshes.
- Explicit delete keeps its confirmation dialog and routes through the
  schema's disposal API (`ComparisonResultRepository.deleteComparison`) plus
  `TransientSnapshotLifecycle.cleanupUnreferencedTransients()` for the
  ADR-012 transient release.
- Tests: `testClosingPersistedSnapshotWorkspacePreservesTheComparison`
  (record, snapshots and repository row survive), 
  `testClosingLiveWorkspaceInvokesCanonicalCleanup` (comparison disposed,
  transient count 0, user snapshot untouched),
  `testExplicitDeleteDisposesComparisonAndReleasesTransients`,
  `testExplicitDeleteOfPersistedComparisonKeepsSnapshots`.

## Detail / Error / Accessibility Behavior

Details (Correction 7): summary pills show All, Differences, Matched, Added,
Removed, Changed, Uncertain and Ignored (`testSummaryCountsCoverEveryCanonicalOutcome`).
The detail pane shows the outcome text, profile name and version, both side
descriptors with snapshot status and warning counts, ADR-010 compatibility
warnings, field-level differences from the repository, missing-side
explanations for added/removed, the uncertain explanation, and "Metadata only.
Content Not Verified." Uncertain is never presented as added, removed or
matched (`testUncertainIsNotPresentedAsAddedRemovedOrMatched`). No source
content previews exist anywhere.

Errors/empty states (Correction 8): bounded presentations for no comparisons,
no eligible snapshots, invalid side selection, same side twice, missing live
source, ineligible snapshot, missing live source, running/cancelled/failed
terminal states, deleted comparison, empty filter result, no selection, and
database failures — all via `ComparisonUIErrorDescription` which maps
`ComparisonError`, `SnapshotScannerError` and `CatalogDatabaseError` to
bounded text (e.g. "The catalog database reported an error (code N)." instead
of the raw SQLite message). `testFailedComparisonIsPresentedWithBoundedMessage`
asserts no "SQLITE" text reaches the user.

Accessibility (Correction 9): accessibility labels on the mode picker, side
selectors, profile picker, start/cancel, filter, result rows (textual outcome
wording, not color-only), navigation buttons, page controls, delete, close
workspace and detail sections; ⌘↑/⌘↓ keyboard shortcuts for previous/next
difference; disabled states derived from repository truth; the app window
keeps its 960×600 minimum size. Outcome communication is text+icon+color in
every case. Rendering/VoiceOver spot-check remains deferred to the owner
(KI-020).

## Automated Tests

Full suite (fresh arm64, signing disabled, Xcode 26.3 / Swift 6.2.4):

- **240 tests executed, 237 passed, 0 failed, 3 skipped.**
- Skip reasons (exact): (1) `FSDTests.FilesystemMatrixTests
  testCaptureExternallyPreparedMountedFilesystem` — `FSD_MATRIX_SOURCE is not
  set; the filesystem matrix probe is inert in ordinary runs`; (2) `FSDTests.
  FilesystemMatrixTests testReopenCapturedSnapshotWithTheSourceDetached` —
  `FSD_MATRIX_OFFLINE_CATALOG is not set; the offline reopen probe is inert in
  ordinary runs`; (3) `FSDTests.FSDProbeSeedTests
  testSeedIsolatedProbeCatalog` — `FSD_PROBE_CATALOG is not set and no marker
  file exists; the probe seeding is inert in ordinary runs`.
- GUI/view-model suites: `ComparisonGUIValidationTests` 32 executed / 32
  passed; `ComparisonGUISourceBoundaryTests` 7/7; `ComparisonWorkspaceModelTests`
  5/5; `ComparisonBrowserModelTests` 2/2; `FSDProbeSeedTests` 1 skipped
  (marker-gated seeder).
- New coverage: build/boundary (shared component, no-SQL scan, approved API
  surface, schema v7), orientation (3 modes + wording), workflow/terminal
  states (request construction, validation, progress, cancellation, failed
  bounded message), paging (first/next/previous, bound, filter reset, stale
  ignore), navigation (in-page, cross-boundary both directions, first/last,
  boundary truth, differences-only, filter-after-navigation), details
  (repository APIs, missing sides, uncertain wording, profile/warnings/status,
  counts), lifecycle (persisted vs live close, explicit delete), accessibility
  surface (wording + navigation-truth bindings).
- No rendering-golden tests were added; rendering is claimed only where a
  view model proves it.

## Agent-Observed Evidence (isolated catalog `/tmp/fsd-m4-gui-probe`)

1. **Seed (AUTOMATED VERIFIED, `FSDProbeSeedTests`, marker-gated):** isolated
   catalog seeded with a completed snapshot-to-snapshot comparison containing
   every canonical outcome (matched 4 / added 2 / removed 4 / changed 1 /
   ignored 3 / uncertain 1 across both comparisons) plus a live-to-snapshot
   comparison whose transient remains referenced. `PRAGMA integrity_check =
   ok`, `PRAGMA foreign_key_check` clean, schema version 7, classification
   rows 0.
2. **Launch (AGENT-OBSERVED):** the built app
   (`/tmp/FSD-M4-GUI-FIX-FINAL/Build/Products/Debug/FSD.app`, Mach-O 64-bit
   arm64) launched against the isolated catalog with `-FSDCatalogPath` +
   `-FSDSelectCompare`; process alive after 4 s. stderr diagnostics:
   `FSD catalog: /tmp/fsd-m4-gui-probe/catalog.sqlite3 (source:
   launchArgument)` and `FSD comparison destination loaded: 2 comparison(s),
   2 eligible snapshot(s), 3 profile(s). newest complete: matched=2 added=1
   removed=3 changed=0 uncertain=0 differences=4 total=6` — the destination
   loaded recent records, eligible snapshots (transient excluded), profiles
   and outcome counts.
3. **Lock probe (AGENT-OBSERVED):** a second launch refused the catalog with
   the bounded ADR-025 message naming the holder and exited.
4. **Post-launch (AUTOMATED VERIFIED):** catalog unchanged by the reads
   (integrity ok, 2 comparisons, classification 0).
5. **Owner catalog untouched (AUTOMATED VERIFIED):** SHA-256 of
   `~/Library/Application Support/FSD/catalog.sqlite3` identical before and
   after the probe:
   `c2f7f9ba2078c409d00d0053f44f7381103f44b56cd8edc2d8060a748cf1daa6`.
6. **Page-boundary navigation (AUTOMATED VERIFIED):** `testNavigationAcrossPageBoundaryNext`
   / `testNavigationAcrossPageBoundaryPrevious` materialize the bounded page
   containing the off-page row and keep it selected (view-model layer, as the
   task allows).
7. **Offline snapshot-to-snapshot viewability (AUTOMATED VERIFIED):** the
   seeded snapshot-to-snapshot comparison has no source folders at all and
   remains listed/viewable at launch; `ComparisonEndToEndProbeTests` removes
   real generated source folders and reopens the catalog; the workspace
   close/delete lifecycle tests run without any filesystem.
8. **Classification rows (AUTOMATED VERIFIED):** 0 in the probe catalog
   before and after the launches.

This is Agent-observed/automated evidence, not manual acceptance. GUI
appearance and VoiceOver behavior at the window remain **NOT PERFORMED —
DEFERRED BY OWNER**.

## Build Results

- Environment: Xcode 26.3 (build 17C529), Swift 6.2.4 (`swift-driver`
  1.127.15), macOS 15.7.7, arm64 host; deployment target macOS 13.0,
  `ARCHS = arm64`, `SWIFT_VERSION = 5.9`.
- Commands (fresh `/tmp/FSD-M4-GUI-FIX-FINAL` DerivedData, signing disabled):
  `xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug
  -derivedDataPath /tmp/FSD-M4-GUI-FIX-FINAL CODE_SIGNING_ALLOWED=NO clean`
  → SUCCEEDED, 0 errors; `... -destination 'platform=macOS,arch=arm64' ...
  build` → **BUILD SUCCEEDED** (single benign warning: AppIntents metadata
  extraction skipped, no AppIntents dependency); `... test` → **TEST
  SUCCEEDED**, 240 executed / 237 passed / 0 failed / 3 skipped.
- App path: `/tmp/FSD-M4-GUI-FIX-FINAL/Build/Products/Debug/FSD.app`; binary
  `Mach-O 64-bit executable arm64`.
- Schema version: 7 (fresh and probe catalogs); `PRAGMA integrity_check = ok`;
  `PRAGMA foreign_key_check` clean; classification rows 0 in every isolated
  catalog.

## Exact Files Changed

Created:

- `FSD/UI/ComparisonSharedViews.swift` (shared empty state + error wording +
  outcome wording)
- `FSDTests/ComparisonGUIValidationTests.swift` (32 tests)
- `FSDTests/ComparisonGUISourceBoundaryTests.swift` (7 tests)
- `FSDTests/FSDProbeSeedTests.swift` (1 marker/env-gated seeder)

Rewritten:

- `FSD/UI/ComparisonBrowserModel.swift`
- `FSD/UI/ComparisonWorkspaceModel.swift`
- `FSD/UI/ComparisonCreationView.swift`
- `FSD/UI/ComparisonWorkspaceView.swift`

Modified:

- `FSD/App/FSDApp.swift` (shared empty state, sidebar section, DEBUG probe
  seam)
- `FSD/UI/ComparisonDestinationView.swift` (DEBUG stderr diagnostic)
- `FSD/Diff/ComparisonResultRepository.swift` (additive `position(of:)`;
  `@unchecked Sendable` conformance — no semantics change)
- `FSD.xcodeproj/project.pbxproj` (4 new source references, both targets)
- `FSDTests/ComparisonWorkspaceModelTests.swift` (canonical live-to-snapshot
  mapping)
- `FSDTests/ComparisonBrowserModelTests.swift` (`.v2` → `.current`
  `NormalizationVersion` fixture fix)
- `docs/PRODUCT_STATE.md`, `docs/MVP_PLAN.md`, `docs/TEST_PLAN.md`,
  `docs/KNOWN_ISSUES.md` (KI-020)
- `handoffs/CURRENT_HANDOFF.md` (full-report overwrite)

Untouched (verified by source-boundary test and file inventory):
`docs/database/schema.sql`, `docs/database/verify.sql`, `CatalogMigrations`,
`ComparisonEngine.swift`, `ComparisonService.swift`,
`ComparisonProfileRepository.swift`, `TransientSnapshotLifecycle.swift`, all
other backend/provider/scanner sources.

## Remaining Limitations

- GUI window appearance, VoiceOver behavior and keyboard focus traversal have
  not been observed by a human (no XCUITest target; Manual Session B items B7
  and B11 are **NOT PERFORMED — DEFERRED BY OWNER**) — KI-020.
- Matched-subtree visual collapse remains deferred with the GUI (the backend
  never aggregates matched subtrees).
- No XCUITest/automation target exists; keyboard-command behavior is asserted
  through the model state the buttons bind to.
- The task's "no raw SQL" scan covers `FSD/UI/Comparison*` sources only;
  backend repositories remain the only SQL boundary by design.

## Decisions

- Status is COMPLETE_WITH_KNOWN_LIMITATIONS: remaining limitations are
  bounded visual polish and deferred manual acceptance.
- Schema v7 and all comparison backend semantics are unchanged.
- The GUI re-audit is not claimed; the required next action is an independent
  Codex re-audit of the Milestone 4 visual comparison interface.
- Manual acceptance is not claimed; it remains deferred per `AGENT.md`.
- Milestone 5 was not started.

## Constraints Preserved

- No schema, migration, engine, service, profile or lifecycle backend
  semantics changed (two additive read-only repository members only).
- No source-volume writes, no payload/hash/classification access anywhere.
- No Git initialization, no owner interaction requested.
- Deferred manual testing rule honored: evidence labeled AUTOMATED VERIFIED /
  AGENT-OBSERVED only.

## Exactly One Next Action

Run an independent Codex re-audit of the corrected Milestone 4 visual
comparison interface; if a rejection-level defect remains, fix the single
highest-severity remaining Milestone 4 GUI blocker.

## Resume Context

Start from the files listed under "Exact Files Changed". The comparison
destination, workspace model, browser model, creation view, workspace view
and their project references are the corrected implementations; do not
recreate them. The required re-audit must re-run the fresh arm64
clean/build/full-suite (240/237/0/3) and the isolated Agent-observed launch
probe (`/tmp/fsd-m4-gui-probe/catalog.sqlite3`, seeded via
`FSDProbeSeedTests` with the `/tmp/fsd-probe-catalog-path.txt` marker file,
launched with `-FSDCatalogPath ... -FSDSelectCompare`). Keep Manual Session
A/B deferred and do not begin Milestone 5 until the re-audit returns APPROVE
or APPROVE WITH CONDITIONS.
