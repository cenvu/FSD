# Handoff

## Identity

- Project: FSD (FishSock Differ)
- Task: FSD-M4-GUI-BOUNDED-ERROR-REAUDIT-0804-13
- Case code: FSD_M4_GUI_BOUNDED_ERROR_REAUDIT
- Role: Reviewer (R)
- Agent / model: Codex / GPT-5
- Session ID: FSD-M4-GUI-BOUNDED-ERROR-REAUDIT-0804-13
- Started: 2026-08-04T18:03:00+0700 (approximate)
- Completed: 2026-08-04T18:15:30+0700

## Status

**COMPLETE — verdict: APPROVE WITH CONDITIONS.** The single remaining
Milestone 4 comparison-GUI bounded-error defect is independently closed.
Milestone 4 is now **COMPLETE_WITH_KNOWN_LIMITATIONS**. Milestone 5 is the
next implementation phase. Manual acceptance remains **NOT PERFORMED —
DEFERRED BY OWNER**.

## Repository State

- Root: `/Users/cenvu/DEV/FSD`
- Branch: unavailable; `.git` is absent
- Commit: unavailable; `.git` is absent
- Git status: `BLOCKED — NOT A REPOSITORY`
- `git diff --check`: `BLOCKED — NOT A REPOSITORY`
- Pre-existing user changes: cannot be separated without Git. This audit did
  not modify production or test source.

## Previous Defect Baseline

The previous independent re-audit was
`handoffs/FSD_M4_COMPARISON_GUI_REAUDIT_R_20260804-174451.md`. It had already
verified closure of the five former GUI findings and rejected only the path
where `ComparisonUIErrorDescription` interpolated
`SnapshotScannerError.captureFailed(String)` into visible comparison-GUI
text.

The reviewed Writer correction was
`handoffs/FSD_M4_GUI_BOUNDED_ERROR_FIX_C_20260804-180141.md`, task
`FSD-M4-GUI-BOUNDED-ERROR-FIX-0804-12`. Its claim was
`COMPLETE`, pending this focused independent re-audit.

## Production Mapping Audit

The reachable comparison-GUI error path is:

```text
SnapshotScannerError.captureFailed(String)
  -> ComparisonService.liveCaptureFailed
  -> ComparisonWorkspaceModel catch
  -> ComparisonUIErrorDescription.message(for:)
  -> ComparisonDestinationView / ComparisonWorkspaceView
```

`FSD/UI/ComparisonSharedViews.swift` now switches on `.captureFailed` without
binding or interpolating its associated String and returns exactly:

`Metadata capture failed. Verify that the source is available and try again.`

`ComparisonError.liveCaptureFailed(scannerError)` explicitly recurses to the
same scanner-error overload. The browser and workspace models route visible
errors through `ComparisonUIErrorDescription`; comparison destination and
workspace views only render the already-mapped `error` state. No comparison UI
source returns `error.localizedDescription`, renders provider output, or
interpolates POSIX/Cocoa paths.

The scanner still retains full detail in its diagnostic
`errorDescription`, and `SnapshotScanner` may still construct the associated
String from `localizedDescription`. That is internal diagnostic state, not the
visible comparison-GUI presentation path, and was not changed by this audit.

## Adversarial Regression Probe

The focused test suite called the production mapper directly with:

1. `SnapshotScannerError.captureFailed("SQLITE_CORRUPT at /secret/path/provider-internal-detail")`;
2. `SnapshotScannerError.captureFailed("POSIX error: Operation not permitted (errno 1) at /private/var/fsd/provider")`;
3. `ComparisonError.liveCaptureFailed(scannerError)` using the first hostile
   scanner error.

`testCaptureFailedArbitraryTextIsNeverVisible` passed. It verified that the
wrapper and direct forms are equal, both hostile messages produce the same
fixed visible text, and SQL/path/provider tokens are absent.

## Typed Distinctions

`testTypedScannerErrorDistinctionsRemainBounded` passed against the production
mapper and verified:

- capture failure: fixed retry/source-availability text;
- provider/unavailable source: fixed
  `The live source could not be captured as metadata.` text, distinct from
  capture failure;
- cancellation: `The comparison was cancelled.` for both CancellationError
  and `ComparisonError.cancelled`;
- catalog/database failure: category plus approved SQLite code only, with raw
  SQLite message and path suppressed;
- ineligible snapshot and missing selection: bounded typed model messages;
- comparison failure: fixed fallback wording.

The comparison-GUI source scan found no alternate visible error path that
returns the carried scanner String. The `ComparisonError` cases handled by the
generic mapper contain fixed wording or bounded identifiers/policy text; the
live-capture case is handled explicitly before that fallback.

## Regression Test Validity

The two new tests are in
`FSDTests/ComparisonGUIValidationTests.swift` and use
`@testable import FSD`. They invoke `ComparisonUIErrorDescription.message`
directly, not a duplicate test helper. The first covers direct and wrapped
production shapes, two arbitrary messages, and hostile SQL/path/provider
tokens. The second covers provider, capture, cancellation, and catalog
distinctions. The focused suite executed both tests as part of 34/34 passing.

No materially reachable comparison-GUI error path was found untested for the
bounded-error defect. Human-rendered VoiceOver and visual behavior remain
**NOT PERFORMED — DEFERRED BY OWNER** and are not claimed as automated proof.

## Separate Legacy Capture Surface

`FSD/App/FSDApp.swift` still assigns `error.localizedDescription` to the
older Milestone 2/3 capture UI's `captureState` failure text. This is not used
by `ComparisonDestinationView`, `ComparisonWorkspaceModel`, or
`ComparisonBrowserModel` for comparison-GUI errors. Classification:

**SEPARATE KNOWN ISSUE — DOES NOT BLOCK M4 COMPARISON GUI.**

It is recorded as `KI-022` in `docs/KNOWN_ISSUES.md` for Milestone 5/pre-MVP
error-surface consolidation. No repair was made in this audit.

## Scope Discipline

Writer source/test scope was limited to:

- `FSD/UI/ComparisonSharedViews.swift` — production fixed mapper;
- `FSDTests/ComparisonGUIValidationTests.swift` — the two focused tests;
- allowed documentation and Handoff updates.

The following were not modified by the correction according to the Writer
report, source inventory, and modification timestamps:

- `docs/database/schema.sql`, `docs/database/verify.sql`;
- `FSD/Catalog/CatalogMigrations.swift`, `FSD/Catalog/CatalogDatabase.swift`;
- `FSD/Diff/ComparisonEngine.swift`,
  `FSD/Diff/ComparisonResultRepository.swift`,
  `FSD/Diff/ComparisonService.swift` semantics;
- `FSD/Scanner/SnapshotScanner.swift` behavior;
- paging, navigation, workspace lifecycle, accessibility controls, and
  `FSD.xcodeproj/project.pbxproj`.

The audit itself changed only `docs/PRODUCT_STATE.md`, `docs/MVP_PLAN.md`,
`docs/KNOWN_ISSUES.md`, this historical Handoff, and
`handoffs/CURRENT_HANDOFF.md`.

## Build and Test Evidence

### Toolchain

- Xcode: `26.3 (17C529)`
- Swift: `Apple Swift version 6.2.4`, swift-driver `1.127.15`
- Host architecture: arm64
- Deployment target observed: macOS 13.0
- App: `/tmp/FSD-M4-GUI-BOUNDED-ERROR-REAUDIT-DerivedData/Build/Products/Debug/FSD.app`
- Binary: Mach-O 64-bit executable arm64

### Independent commands

```text
xcodebuild -version
swift --version
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -derivedDataPath /tmp/FSD-M4-GUI-BOUNDED-ERROR-REAUDIT-DerivedData clean
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-M4-GUI-BOUNDED-ERROR-REAUDIT-DerivedData \
  CODE_SIGNING_ALLOWED=NO build
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-M4-GUI-BOUNDED-ERROR-REAUDIT-DerivedData \
  CODE_SIGNING_ALLOWED=NO -only-testing:FSDTests/ComparisonGUIValidationTests test
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-M4-GUI-BOUNDED-ERROR-REAUDIT-DerivedData \
  CODE_SIGNING_ALLOWED=NO test
```

Results:

- Clean: exit 0.
- Build: `BUILD SUCCEEDED`, exit 0.
- Focused GUI validation: **34 executed, 34 passed, 0 failed**.
- Full XCTest suite: **242 total, 239 passed, 0 failed, 3 skipped**.
- Full-suite skips, exact reasons:
  - `FSDProbeSeedTests.testSeedIsolatedProbeCatalog` —
    `FSD_PROBE_CATALOG is not set and no marker file exists; the probe seeding is inert in ordinary runs`.
  - `FilesystemMatrixTests.testCaptureExternallyPreparedMountedFilesystem` —
    `FSD_MATRIX_SOURCE is not set; the filesystem matrix probe is inert in ordinary runs`.
  - `FilesystemMatrixTests.testReopenCapturedSnapshotWithTheSourceDetached` —
    `FSD_MATRIX_OFFLINE_CATALOG is not set; the offline reopen probe is inert in ordinary runs`.
- Focused regression tests: both named tests passed.
- Warnings: Xcode AppIntents metadata extraction skipped because no
  AppIntents dependency exists; test host emits signed XCTest-framework and
  macOS 13/macOS 14 XCTest linkage warnings; the existing unused `transientID`
  test warning remains. No build/test failure or safety-relevant concurrency
  warning occurred.

## Schema and Resource Check

The fresh app contains `Contents/Resources/schema.sql`. It is byte-identical
to `docs/database/schema.sql`. A fresh SQLite catalog created from the
canonical schema reported:

- schema version: `7`;
- `PRAGMA integrity_check`: `ok`;
- `PRAGMA foreign_key_check`: no rows;
- classification rows: `0`.

The full suite's schema migration and ExpectedState tests also passed. No
schema or backend behavior changed.

## Milestone Decision

**APPROVE WITH CONDITIONS.** The comparison GUI bounded-error defect is
closed, the focused tests exercise the production mapper and wrapper path,
the clean arm64 build and full suite pass, and no unrelated production
behavior changed. The only remaining condition is separate legacy capture UI
error wording (`KI-022`) plus deferred human visual/VoiceOver observation;
neither blocks closure of the Milestone 4 comparison GUI under the stated
policy.

Milestone 4 status: **COMPLETE_WITH_KNOWN_LIMITATIONS**.

## Exactly One Next Action

Implement Milestone 5 — performance gates, consolidated acceptance preparation
and pre-MVP audit.

## Resume Context

Begin Milestone 5 from the current schema-v7 comparison foundation. Preserve
the bounded comparison error mapper, the two regression tests, `KI-022` as a
separate legacy capture-surface issue, and Manual Session A/B status as
**NOT PERFORMED — DEFERRED BY OWNER**. Do not relabel Agent-observed or
automated evidence as manual acceptance.
