# Handoff

## Identity

- Project: FSD (FishSock Differ)
- Task: FSD-M4-COMPARISON-GUI-REAUDIT-0804-11
- Case code: FSD_M4_COMPARISON_GUI_REAUDIT
- Role: Reviewer (R)
- Agent / model: Codex / GPT-5
- Session ID: FSD-M4-COMPARISON-GUI-REAUDIT-0804-11
- Started: 2026-08-04T17:30:00+0700 (approximate)
- Completed: 2026-08-04T17:44:51+0700

## Status

**COMPLETE — audit completed; Milestone 4 verdict: REJECT.** The five prior
rejection-level GUI findings are closed and independently verified. A new
rejection-level GUI error-boundary defect remains: the visible mapper
interpolates arbitrary `SnapshotScannerError.captureFailed(String)` text,
although the correction claims raw underlying details are suppressed. No
production implementation was repaired in this review. Milestone 5 must not
begin.

## Repository State

- Root: `/Users/cenvu/DEV/FSD`
- Branch: unavailable; `.git` is absent
- Commit: unavailable; `.git` is absent
- Git status: `BLOCKED — NOT A REPOSITORY`
- `git diff --check`: `BLOCKED — NOT A REPOSITORY`
- Pre-existing user changes: cannot be separated without Git. Production and
  test sources were not modified by this audit.

## Interrupted / Corrected Task Under Review

The reviewed Writer report is
`handoffs/FSD_M4_COMPARISON_GUI_FIX_C_20260804-172438.md`.
It identifies task `FSD-M4-COMPARISON-GUI-FIX-0804-10`, claims
`COMPLETE_WITH_KNOWN_LIMITATIONS`, and reports all five former GUI findings
closed, 240 total tests with 237 passed/0 failed/3 skipped, and an isolated
Agent-observed comparison launch probe. The report lists schema, migration,
engine, service, profile, and transient-lifecycle files as untouched.

## Inputs Read

- `handoffs/CURRENT_HANDOFF.md`
- `handoffs/FSD_M4_COMPARISON_GUI_FIX_C_20260804-172438.md`
- `docs/AGENT.md`
- `docs/PRODUCT_STATE.md`
- `docs/MVP_PLAN.md`
- `docs/PRD.md`
- `docs/ARCHITECTURE.md`
- `docs/DECISIONS.md` — ADR-012, ADR-027, ADR-028
- `docs/TEST_PLAN.md`
- `docs/KNOWN_ISSUES.md`
- The specified comparison GUI, repository boundary, app, tests, and project
  reference files.

## Verified Completed Work

### Former rejection findings

| Finding | Result | Evidence |
|---|---|---|
| H1 compile/private `EmptyStateView` | CLOSED | `ComparisonSharedViews.swift` defines one internal shared component; `FSDApp.swift` has no private duplicate; fresh arm64 build succeeded. |
| H2 live-to-snapshot orientation | CLOSED | Three real service/model tests pass. Snapshot is left/reference, live is right/changed; added is live/right-only and removed is snapshot/left-only. |
| H3 GUI raw SQL/schema knowledge | CLOSED | Source-boundary test passes; no comparison UI source contains the forbidden SQL/schema tokens or `ComparisonMetadataDataSource`; metadata and field differences use repository APIs. |
| H4 cumulative paging | CLOSED | Browser model replaces one page; page-size ceiling is clamped; 20-row multi-page and 200-entry fixtures pass bounded-retention tests. |
| H5 cross-page navigation | CLOSED | Next and previous boundary tests materialize the target page, select the target row, load details, and retain a bounded page. |

### Other corrected areas

Workspace close and explicit deletion route through the canonical lifecycle
APIs. Summary and detail views expose canonical outcome wording, profile and
version, side descriptors, warning counts/status, field differences,
missing-side explanations, uncertainty, and `Content Not Verified`.
Programmatic accessibility labels and ⌘↑/⌘↓ bindings are present. The GUI
does not read payloads, classification rows, or source files for stored
snapshot-to-snapshot display.

## Partial / Rejection Finding

`FSD/UI/ComparisonSharedViews.swift:52-58` maps:

```swift
case let .captureFailed(message):
    return "Metadata capture failed: \(message)"
```

`FSD/Scanner/SnapshotScanner.swift:128-130` can construct this case from
`error.localizedDescription`. `ComparisonService` wraps the scanner error as
`ComparisonError.liveCaptureFailed`, and `ComparisonWorkspaceModel` passes it
to the GUI mapper. Therefore a live capture/database failure can expose the
underlying implementation message in visible UI text. The existing test only
checks an ineligible-snapshot error and does not exercise this case. This is a
new High/rejection-level closeout finding because the requested GUI contract
explicitly requires bounded errors and the Writer Handoff claims this path is
bounded.

No production fix was applied.

## Work Not Started By This Audit

- No production source, test, schema, migration, Xcode project, or helper
  source was repaired.
- No Milestone 5 implementation was started.
- No manual GUI, VoiceOver, or visual acceptance was performed. Status:
  **NOT PERFORMED — DEFERRED BY OWNER**.

## Files Changed By the Corrected Writer

As reported and confirmed by file inventory/timestamps:

- Created: `FSD/UI/ComparisonSharedViews.swift`;
  `FSDTests/ComparisonGUIValidationTests.swift`;
  `FSDTests/ComparisonGUISourceBoundaryTests.swift`;
  `FSDTests/FSDProbeSeedTests.swift`.
- Rewritten: `FSD/UI/ComparisonBrowserModel.swift`;
  `FSD/UI/ComparisonWorkspaceModel.swift`;
  `FSD/UI/ComparisonCreationView.swift`;
  `FSD/UI/ComparisonWorkspaceView.swift`.
- Modified: `FSD/App/FSDApp.swift`;
  `FSD/UI/ComparisonDestinationView.swift`;
  `FSD/Diff/ComparisonResultRepository.swift` (additive `position(of:)` and
  `@unchecked Sendable`); `FSD.xcodeproj/project.pbxproj`;
  `FSDTests/ComparisonWorkspaceModelTests.swift`;
  `FSDTests/ComparisonBrowserModelTests.swift`;
  `docs/PRODUCT_STATE.md`; `docs/MVP_PLAN.md`; `docs/TEST_PLAN.md`;
  `docs/KNOWN_ISSUES.md`.
- Historical Writer Handoff: `handoffs/FSD_M4_COMPARISON_GUI_FIX_C_20260804-172438.md`.

The following directly related backend files were not modified by the
correction according to the report, source inventory, and timestamps:
`docs/database/schema.sql`, `docs/database/verify.sql`,
`FSD/Catalog/CatalogMigrations.swift`, `FSD/Diff/ComparisonEngine.swift`,
`FSD/Diff/ComparisonService.swift`, `FSD/Diff/ComparisonProfileRepository.swift`,
and `FSD/Catalog/TransientSnapshotLifecycle.swift`.

## Schema and Backend Scope

Schema remains version 7. The bundled app resource contains `schema.sql` and
records version 7. A fresh SQLite check returned:

- schema version: `7`
- `PRAGMA integrity_check`: `ok`
- `PRAGMA foreign_key_check`: no rows
- `entry_classifications`: `0`

The independent full suite passed the v4/v5/v6/v7 migration and ExpectedState
tests. No GUI correction changed schema version, migration behavior, engine
semantics, profile semantics, transient lifecycle, or terminal guards.

The additive repository `position(of:comparisonID:filter:)` is read-only. It
first verifies filtered membership, then counts strictly preceding
`(result_path, id)` rows, matching the repository's deterministic BINARY
ordering. It returns only an ordinal or nil, so it is bounded in returned data.
The repository's `@unchecked Sendable` is consistent with the existing
serialized `CatalogDatabase` access invariant and introduced no new compiler
concurrency warning in the clean build.

## GUI Contract Audit

- Snapshot-to-snapshot: left selector and request are reference/before; right
  selector and request are changed/after.
- Live-to-snapshot: snapshot is left/reference and live folder is right/changed.
  Tests verify right-only is `added` and left-only is `removed`.
- Live-to-live: first live folder is left/reference and second is right/changed.
- UI data access is repository-only; no raw SQL appears in comparison UI files.
- Browser state retains one page only; filter changes reset offset and stale
  async generations are ignored.
- In-page and both cross-page navigation directions work, including first and
  last boundaries and differences-only filtering.
- Workspace close preserves ordinary snapshot comparisons and disposes live
  comparison/transient state through the canonical service path. Explicit
  delete preserves ordinary snapshots; full suite checks integrity and FK
  cleanliness.
- Result/detail wording includes all six outcomes and does not label uncertain
  as added, removed, matched, or content-equal.
- “Content Not Verified” is visible in the detail pane.
- Programmatic accessibility labels, textual outcome descriptions, start/cancel,
  filter, row, delete/close, page and previous/next labels exist. Human
  VoiceOver/focus observation remains deferred.

## Tests and Build Evidence

### Toolchain

- Xcode: `26.3 (17C529)`
- Swift: `Apple Swift version 6.2.4`, swift-driver `1.127.15`
- Host binary: `Mach-O 64-bit executable arm64`
- Deployment target observed in build: macOS 13.0
- Bundled schema: `/tmp/FSD-M4-GUI-REAUDIT-DerivedData/Build/Products/Debug/FSD.app/Contents/Resources/schema.sql`

### Independent commands

```text
xcodebuild -version
swift --version
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -derivedDataPath /tmp/FSD-M4-GUI-REAUDIT-DerivedData clean
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-M4-GUI-REAUDIT-DerivedData \
  CODE_SIGNING_ALLOWED=NO build
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-M4-GUI-REAUDIT-DerivedData \
  CODE_SIGNING_ALLOWED=NO test
```

Results:

- Clean: exit 0.
- Build: `BUILD SUCCEEDED`, exit 0.
- Full XCTest suite: **240 total; 237 passed; 0 failed; 3 skipped**.
- GUI suites: `ComparisonGUIValidationTests` 32/32;
  `ComparisonGUISourceBoundaryTests` 7/7;
  `ComparisonWorkspaceModelTests` 5/5;
  `ComparisonBrowserModelTests` 2/2.
- Skips: `FSDProbeSeedTests.testSeedIsolatedProbeCatalog` because
  `FSD_PROBE_CATALOG` and the marker were absent in ordinary full tests;
  `FilesystemMatrixTests.testCaptureExternallyPreparedMountedFilesystem`
  because `FSD_MATRIX_SOURCE` was not set; and
  `FilesystemMatrixTests.testReopenCapturedSnapshotWithTheSourceDetached`
  because `FSD_MATRIX_OFFLINE_CATALOG` was not set.
- Warnings: AppIntents metadata extraction without an AppIntents dependency;
  test-build warnings about signed XCTest frameworks and macOS 13 linking to
  Xcode XCTest built for macOS 14; one existing unused `transientID` test
  warning. No compile error and no unresolved safety-relevant concurrency
  warning.

## Agent-Observed Isolated Probe

The marker-gated `FSDProbeSeedTests.testSeedIsolatedProbeCatalog` was run
against a new temporary catalog and passed. It seeded two comparisons with
canonical outcomes and a referenced live transient. The fresh app was then
launched directly:

```text
/tmp/FSD-M4-GUI-REAUDIT-DerivedData/Build/Products/Debug/FSD.app/Contents/MacOS/FSD \
  -FSDCatalogPath /tmp/fsd-m4-gui-reaudit-probe/catalog.sqlite3 \
  -FSDSelectCompare
```

After five seconds the process was alive. Diagnostic output reported:
`FSD comparison destination loaded: 2 comparison(s), 2 eligible snapshot(s),
3 profile(s)` with counts. Post-launch checks returned schema 7, integrity
`ok`, empty foreign-key check, two comparisons, and zero classification rows.
This is **AGENT-OBSERVED**, not manual acceptance. The owner catalog was not
used; the probe used only the isolated override.

## Source and Test Coverage Limitations

The correction's GUI validation is model/source-boundary coverage, not an
XCUITest rendering suite. The source-boundary test is intentionally static and
does not replace compiler/runtime verification; the fresh build supplies that
verification. There is no direct added test for `position`'s absent-row case,
although the implementation's membership guard and cross-page tests cover the
materialization path. These are coverage limitations, not the rejection
finding.

## Findings By Severity

### High

1. **Unbounded visible live-capture error detail — OPEN / rejection-level.**
   `captureFailed(String)` is built from arbitrary `localizedDescription` and
   is interpolated by the GUI error mapper. Fixing this requires a small
   production mapping correction and a targeted regression test; it was not
   fixed in this audit.

### Medium

- No human-rendered GUI/VoiceOver/focus observation: **NOT PERFORMED —
  DEFERRED BY OWNER**, per policy.
- Direct `position` absent-anchor test and rendered UI tests are missing; the
  behavior is otherwise covered by source inspection, fresh compilation, and
  model tests.

### Low

- Existing unused `transientID` warning in `ComparisonGUIValidationTests`.
- Existing Xcode/AppIntents metadata and XCTest deployment-link warnings.

## DeepSeek Correction Assessment

| Criterion | Result | Evidence |
|---|---|---|
| Build correction | PASS | Fresh clean arm64 build succeeds. |
| Orientation correction | PASS | All three mode tests and request/service assertions pass. |
| Backend-boundary correction | PASS | No-SQL/source-boundary tests and repository API usage pass. |
| Paging correction | PASS | Single-page state and multi-page bounded tests pass. |
| Navigation correction | PASS | In-page, cross-page, boundary, filter and detail-selection tests pass. |
| Lifecycle correction | PASS | Close/delete/transient tests pass with clean integrity/FK state. |
| Detail/error/accessibility correction | PARTIAL | Details/accessibility pass, but live-capture error mapping leaks arbitrary text; human observation deferred. |
| Test quality | PARTIAL | Strong 32 + 7 GUI tests and full suite; no rendering tests and no direct absent-position test. |
| Scope discipline | PASS | No schema/migration/engine/service/profile/lifecycle semantic changes observed. |
| Handoff accuracy | PARTIAL | Build/GUI claims are accurate, but the “no raw SQLite detail” error claim is too broad. |

Score: **6 PASS / 10 criteria; 4 PARTIAL; 0 FAIL; 0 NOT VERIFIED**.

DeepSeek effectiveness rating: **EFFECTIVE WITH SUPERVISION**.

Estimated corrective rework: **SMALL**.

## Verdict

**REJECT.** The corrected interface is not eligible to close because the
explicit bounded-error contract is not satisfied for live-capture failures.
The five former rejection-level findings are closed, schema v7/backend
semantics are unchanged, and all independent build/test/probe evidence other
than this defect is positive.

## Exact Files Changed By This Audit

- `docs/PRODUCT_STATE.md`
- `docs/MVP_PLAN.md`
- `docs/KNOWN_ISSUES.md`
- `handoffs/FSD_M4_COMPARISON_GUI_REAUDIT_R_20260804-174451.md`
- `handoffs/CURRENT_HANDOFF.md`

No production source, tests, schema, migration, Xcode project, or helper source
was changed. Temporary probe catalogs/logs were created only under `/tmp`.

## Exactly One Next Action

Fix the single highest-severity remaining Milestone 4 GUI blocker.

## Resume Context

Resume by replacing the visible `captureFailed` interpolation with a fixed,
bounded user-facing description (while preserving typed cancellation/provider
states), add one focused regression test proving an arbitrary underlying
message is suppressed, run the fresh arm64 build/full suite, and repeat this
GUI re-audit. Do not begin Milestone 5 until the follow-up verdict is APPROVE
or APPROVE WITH CONDITIONS. Manual testing remains **NOT PERFORMED — DEFERRED
BY OWNER**.
