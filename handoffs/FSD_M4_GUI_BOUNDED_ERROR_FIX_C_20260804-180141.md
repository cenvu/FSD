# Handoff

## Identity

- Project: FSD (FishSock Differ)
- Task: FSD-M4-GUI-BOUNDED-ERROR-FIX-0804-12
- Case code: FSD_M4_GUI_BOUNDED_ERROR_FIX
- Role: Writer (C)
- Agent / model: Claude Code / deepseek-v4-flash
- Session ID: FSD-M4-GUI-BOUNDED-ERROR-FIX-0804-12
- Started: 2026-08-04T17:50:00+0700 (approximate)
- Completed: 2026-08-04T18:02:19+0700

## Status

**COMPLETE — the single remaining rejection-level Milestone 4 GUI defect is
fixed.** The visible comparison-GUI error mapper no longer interpolates the
arbitrary string carried by `SnapshotScannerError.captureFailed(String)`;
typed bounded distinctions (cancellation, provider/unavailable source,
ineligible snapshot, missing selection, comparison failure, catalog failure)
are preserved; a focused regression test proves two different arbitrary
underlying messages produce the same safe visible text; a fresh isolated
arm64 clean/build/full-suite run passes (242 executed, 239 passed, 0 failed,
3 skipped); schema remains version 7. Milestone 4 audit approval is NOT
claimed; the Milestone 4 GUI awaits one focused independent Codex re-audit of
this correction. Milestone 5 was not begun. Manual acceptance remains
**NOT PERFORMED — DEFERRED BY OWNER**.

## Repository State

- Root: `/Users/cenvu/DEV/FSD`
- Branch: unavailable; `.git` is absent
- Commit: unavailable; `.git` is absent
- Git status: `BLOCKED — NOT A REPOSITORY`
- `git diff --check`: `BLOCKED — NOT A REPOSITORY`
- Pre-existing user changes: cannot be separated without Git. The Writer
  changed only the files listed in "Files Changed" below.

## Original Defect

The re-audit (`handoffs/FSD_M4_COMPARISON_GUI_REAUDIT_R_20260804-174451.md`)
recorded a new High/rejection-level closeout finding at
`FSD/UI/ComparisonSharedViews.swift:52-58`:

```swift
case let .captureFailed(message):
    return "Metadata capture failed: \(message)"
```

`FSD/Scanner/SnapshotScanner.swift:128-130` constructs
`SnapshotScannerError.captureFailed(error.localizedDescription)` from an
arbitrary underlying error, so a live-capture/database failure can expose raw
provider, filesystem, database, path or implementation details in visible
comparison-UI text. `ComparisonService.captureTransient` wraps the scanner
error as `ComparisonError.liveCaptureFailed(scannerError)`
(`FSD/Diff/ComparisonService.swift:138`), and `ComparisonWorkspaceModel.start`
passes it to the GUI mapper (`FSD/UI/ComparisonWorkspaceModel.swift:211`),
which recursed into the interpolating `SnapshotScannerError` overload. The
existing GUI test only exercised an ineligible-snapshot error and did not
cover this case. No production fix existed at re-audit time.

## Correction Applied

### Production fix — `FSD/UI/ComparisonSharedViews.swift`

`ComparisonUIErrorDescription.message(for: SnapshotScannerError)` now maps the
typed cases to fixed, bounded text. The `.captureFailed` case never
interpolates the carried string:

```swift
static func message(for error: SnapshotScannerError) -> String {
    switch error {
    case .captureFailed:
        // Fixed, bounded presentation. This case carries an arbitrary
        // underlying `localizedDescription` (raw SQLite, POSIX/Cocoa,
        // path or provider internals), so the carried string must never
        // reach the user. The user only needs to know the capture failed
        // and what they can do next.
        return "Metadata capture failed. Verify that the source is available and try again."
    default:
        // Provider, writer and detector conditions keep their own fixed
        // wording; nothing here interpolates underlying error text.
        return "The live source could not be captured as metadata."
    }
}
```

The visible text communicates only that metadata capture failed and that the
user may retry or verify source availability. It contains no arbitrary
underlying error text, no raw SQLite messages, no POSIX/Cocoa descriptions,
no filesystem implementation details, no internal paths, no provider command
output, no exception names and no stack details.

Typed bounded distinctions preserved (unchanged or already bounded):

- **Cancellation** — `CancellationError` and `ComparisonError.cancelled` map
  to "The comparison was cancelled."; the workspace model additionally routes
  cancelled runs to a `.cancelled` terminal state without error text.
- **Inaccessible/unavailable source** — `SnapshotScannerError.provider` keeps
  its own fixed wording "The live source could not be captured as metadata."
  (distinct from the captureFailed wording).
- **Ineligible snapshot** — `ComparisonError.ineligibleSnapshot` keeps its
  bounded typed wording via `errorDescription` ("… cannot be compared …").
- **Missing selection** — workspace `validationMessage` (not the mapper)
  unchanged.
- **Comparison failure** — generic fallback "The comparison could not be
  completed." unchanged.
- **Database/catalog failure** — `CatalogDatabaseError` mapping unchanged
  (code-only for `.sqlite`, raw SQLite message suppressed).

No change was made to the underlying diagnostic: `SnapshotScannerError.errorDescription`
and `ComparisonError.errorDescription` still carry the full detail for
internal logging/diagnostics; only the user-visible mapping is bounded.

No other production behavior was modified: no schema, migration, engine,
repository, service, provider, profile, paging, navigation, workspace
lifecycle, accessibility or Xcode project changes.

## Regression Test

Added to the existing GUI validation file `FSDTests/ComparisonGUIValidationTests.swift`
(two tests; suite grew 32 → 34):

`testCaptureFailedArbitraryTextIsNeverVisible`:

- constructs `SnapshotScannerError.captureFailed("SQLITE_CORRUPT at /secret/path/provider-internal-detail")`;
- passes it through the same mapper the GUI uses (`ComparisonUIErrorDescription.message(for:)`);
- asserts the returned text is a fixed bounded description that:
  - contains "Metadata capture failed";
  - does not contain `SQLITE`;
  - does not contain `/secret/path`;
  - does not contain `provider-internal-detail`;
- asserts the production wrapping shape the workspace actually receives
  (`ComparisonError.liveCaptureFailed(scannerError)` from
  `ComparisonService.captureTransient`) maps to the identical visible text;
- asserts a second arbitrary message
  (`"POSIX error: Operation not permitted (errno 1) at /private/var/fsd/provider"`)
  produces the exact same visible text.

`testTypedScannerErrorDistinctionsRemainBounded`:

- asserts the provider (inaccessible/unavailable source) condition keeps its
  own fixed wording with no underlying text and stays distinct from the
  captureFailed wording;
- asserts cancellation keeps its bounded wording on both `CancellationError`
  and `ComparisonError.cancelled`;
- asserts a catalog `.sqlite(11, …)` failure shows only the code, never the
  raw SQLite message or path.

Existing typed-distinction tests still pass unchanged:
`testFailedComparisonIsPresentedWithBoundedMessage` (ineligible snapshot) and
`testCancellationIsPresentedAsCancelled`.

The test exercises the production UI mapper directly (`@testable import FSD`
against `ComparisonUIErrorDescription`), not a copied helper.

## Files Changed

Production:

- `FSD/UI/ComparisonSharedViews.swift` — bounded `.captureFailed` mapping
  (the only production file changed).

Tests:

- `FSDTests/ComparisonGUIValidationTests.swift` — two regression tests added.

Documentation (minimum current state):

- `docs/PRODUCT_STATE.md` — current-phase and Milestone 4 GUI bullet updated:
  defect fixed, 242/239/0/3 evidence, schema v7, one focused Codex re-audit
  pending, manual acceptance deferred.
- `docs/MVP_PLAN.md` — status line and Milestone 4 status note updated.
- `docs/KNOWN_ISSUES.md` — KI-021 updated to FIXED with correction reference.

Handoff artifacts:

- Created: `handoffs/FSD_M4_GUI_BOUNDED_ERROR_FIX_C_20260804-180141.md`
- Overwritten: `handoffs/CURRENT_HANDOFF.md` (full copy, not a pointer)

Not modified (verified): `docs/database/schema.sql`, `docs/database/verify.sql`,
`FSD/Catalog/CatalogMigrations.swift`, `FSD/Catalog/CatalogDatabase.swift`,
`FSD/Diff/ComparisonEngine.swift`, `FSD/Diff/ComparisonResultRepository.swift`,
`FSD/Diff/ComparisonService.swift`, `FSD/Diff/ComparisonProfileRepository.swift`,
`FSD/Scanner/SnapshotScanner.swift`, providers, profiles, paging/navigation
models, workspace lifecycle, accessibility controls, `FSD.xcodeproj/project.pbxproj`.

## Build and Test Evidence

### Toolchain

- Xcode: `26.3 (17C529)`
- Swift: `Apple Swift version 6.2.4`, swift-driver `1.127.15`
- Host binary: `Mach-O 64-bit executable arm64`
- App path: `/tmp/FSD-M4-GUI-BOUNDED-ERROR-FIX-DerivedData/Build/Products/Debug/FSD.app`
- Derived data: `/tmp/FSD-M4-GUI-BOUNDED-ERROR-FIX-DerivedData` (fresh; removed before clean)

### Commands

```text
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -derivedDataPath /tmp/FSD-M4-GUI-BOUNDED-ERROR-FIX-DerivedData clean
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-M4-GUI-BOUNDED-ERROR-FIX-DerivedData \
  CODE_SIGNING_ALLOWED=NO build
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-M4-GUI-BOUNDED-ERROR-FIX-DerivedData \
  CODE_SIGNING_ALLOWED=NO test
```

### Results

- Clean: `** CLEAN SUCCEEDED **`, exit 0.
- Build: `** BUILD SUCCEEDED **`, exit 0.
- Full XCTest suite: **242 total; 239 passed; 0 failed; 3 skipped**.
- `ComparisonGUIValidationTests`: **34/34 passed** (32 existing + 2 new).
- Focused bounded-error tests:
  - `testCaptureFailedArbitraryTextIsNeverVisible` — PASSED.
  - `testTypedScannerErrorDistinctionsRemainBounded` — PASSED.
- Skip reasons (identical to baseline; all environment-gated):
  - `FSDProbeSeedTests.testSeedIsolatedProbeCatalog` — `FSD_PROBE_CATALOG` not
    set and no marker file exists; the probe seeding is inert in ordinary runs.
  - `FilesystemMatrixTests.testCaptureExternallyPreparedMountedFilesystem` —
    `FSD_MATRIX_SOURCE` not set; the filesystem matrix probe is inert in
    ordinary runs.
  - `FilesystemMatrixTests.testReopenCapturedSnapshotWithTheSourceDetached` —
    `FSD_MATRIX_OFFLINE_CATALOG` not set; the offline reopen probe is inert in
    ordinary runs.
- Warnings (all pre-existing, none new):
  - AppIntents metadata extraction skipped (no AppIntents.framework dependency).
  - Test-build `ld` warnings: building for macOS 13.0 while linking Xcode
    XCTest/libXCTestSwiftSupport built for macOS 14.0.
  - "not stripping binary because it is signed" for Apple test frameworks
    (CODE_SIGNING_ALLOWED=NO environment, harmless).
  - Pre-existing unused `transientID` warning in
    `ComparisonGUIValidationTests` (unchanged).

### Schema version

- `CatalogMigrations.currentVersion = 7` (`FSD/Catalog/CatalogMigrations.swift:25`);
  `CatalogDatabase.currentSchemaVersion` follows it.
- Bundled app resource `schema.sql` is byte-identical to the canonical
  `docs/database/schema.sql` (diff confirmed IDENTICAL).
- `SchemaMigrationTests` v7 assertions pass in the full run
  (`testFreshDatabaseReachesCurrentVersionWithCleanIntegrity`,
  `testMigratedDatabasePassesIntegrityAndForeignKeyChecks`).
- Schema version, migration behavior, engine semantics, profile semantics,
  transient lifecycle and terminal guards are unchanged by this correction.

## Source Inspection

- No visible comparison-GUI mapper interpolates arbitrary capture-failure
  text: `FSD/UI/ComparisonSharedViews.swift` is the only UI consumer of
  `SnapshotScannerError` / `captureFailed` and now returns fixed bounded text;
  all comparison-GUI error paths (`ComparisonWorkspaceModel`,
  `ComparisonBrowserModel`) route through `ComparisonUIErrorDescription.message(for:)`.
- `SnapshotScannerError.errorDescription` (the internal diagnostic) still
  carries the full detail by design; it is never rendered by the comparison GUI.

## Remaining Limitations

- **Manual acceptance: NOT PERFORMED — DEFERRED BY OWNER.** No human GUI,
  VoiceOver, focus-traversal or visual acceptance was performed; the
  consolidated acceptance backlog remains `TEST_PLAN.md` §8.
- The correction is model/source-boundary + full-suite coverage; there is no
  XCUITest rendering suite (unchanged from prior milestones).
- Out-of-scope observation (not part of this finding, not modified): the
  Milestone 2/3 capture flow in `FSD/App/FSDApp.swift:160` still surfaces
  `error.localizedDescription` for a failed capture (`captureState = .failed(...)`),
  which for `SnapshotScannerError.captureFailed` includes the carried string.
  The rejection finding and this correction are scoped to the Milestone 4
  comparison-GUI mapper; this M2/M3 surface was not changed per the approved
  file list and is left for the follow-up audit to weigh.
- Pre-existing warnings (AppIntents metadata, XCTest deployment-link,
  unused `transientID`) are unchanged.
- The verified baseline's other confirmed areas (orientation, no GUI raw SQL,
  bounded paging, cross-page navigation, lifecycle, accessibility, backend
  semantics, schema v7) were not re-litigated; this correction touched none of
  them.

## Milestone Position

- Milestone 4 audit approval is **NOT claimed** in this report.
- Milestone 4 GUI awaits **one focused independent Codex re-audit** of the
  bounded-error correction (per CONTROL CENTER direction).
- Milestone 5 implementation was **not begun**.
- Schema remains version 7.

## Exactly One Next Action

Run an independent Codex focused re-audit of the Milestone 4 bounded-error
correction (verify: no visible comparison-GUI path interpolates arbitrary
capture-failure text; typed distinctions intact; regression test proves two
arbitrary messages produce the same safe visible text; fresh clean
arm64 build and full suite pass; schema v7; no unrelated production behavior
changes). If the re-audit accepts the GUI, the Milestone 4 approval decision
and Milestone 5 authorization follow; if it finds the defect remains, fix the
same bounded-error blocker without expanding scope.

## Resume Context

Resume with the focused Codex re-audit of `FSD/UI/ComparisonSharedViews.swift`
and `FSDTests/ComparisonGUIValidationTests.swift`. The production correction
is exactly the fixed `.captureFailed` message in
`ComparisonUIErrorDescription.message(for: SnapshotScannerError)`; the
regression tests are `testCaptureFailedArbitraryTextIsNeverVisible` and
`testTypedScannerErrorDistinctionsRemainBounded`. Full suite evidence is
242/239/0/3 with schema v7. Do not begin Milestone 5 until the follow-up
verdict is APPROVE or APPROVE WITH CONDITIONS. Manual testing remains
**NOT PERFORMED — DEFERRED BY OWNER**.
