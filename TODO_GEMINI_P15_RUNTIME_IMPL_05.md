# TODO_GEMINI_P15_RUNTIME_IMPL_05.md — Minimal selected-entry UI

Prepared by: Tech Lead / Architect (planning only)  
Sequence: 5 of 8  
Major TODO count: **3**  
Risk: **MEDIUM**  
Recommended Writer: **either Writer**

## Purpose

Expose the approved runtime only as an explicit action for the currently selected entry. Add bounded progress/cancel/status behavior and refresh the inspector without creating a bulk classifier, destination, background trigger, or historical-content claim.

## Prerequisites

- Slices 01–04 are merged and green; all required prior audits are approved.
- Read the current `SnapshotBrowserModel`, `SnapshotBrowserView`, `EntryInspectorView`, `ApplicationModel`, and existing UI/model test patterns before editing.

## Locked implementation decisions

- `ApplicationModel` owns exactly one app-scoped `ClassificationRuntimeService` and injects it into each `SnapshotBrowserModel`; opening another browser cannot create a second runtime.
- Construction, application launch, history loading, snapshot open/reopen, browsing, selection, search, comparison, and export do not call `start`.
- Only a user-pressed **Classify selected file** action starts work. The action is shown/enabled only for a selected snapshot entry; runtime preflight remains authoritative for file-kind/source checks.
- Selection change, snapshot close, or browser replacement calls cancel/invalidate. A stale completion cannot alter the new selection or its inspector.
- A second action while busy is disabled and also protected by service `.busy`; there is no queue or bulk action.
- Show a progress/cancel affordance only after 0.5 seconds if still running. Fast completion does not flash progress. UI timing is injectable/deterministic in model tests.
- Absence remains neutral “Not classified.” Failed/source-changed/unsupported persisted rows use bounded status text only. Unavailable/cancelled/busy are runtime messages and do not fabricate a row.
- Confidence is shown only when present. Provider stderr/raw errors/stack traces/private paths never reach visible text.
- Replace the now-false blanket statement “FSD never read this file's contents” with accurate bounded wording: snapshot metadata is not byte proof; optional classification samples at most the 4096-byte prefix of the currently attached source and is not historical verification.
- No new destination, sheet, bulk list, automatic retry, backfill control, or classification in comparison/export.

## Files/modules the Writer may modify

- `FSD/App/FSDApp.swift`
- `FSD/UI/SnapshotBrowserView.swift`
- `FSD/Browser/SnapshotTreeDataSource.swift` only for a bounded selected-entry classification refresh/invalidation hook; no filesystem work
- `FSD/Classification/ClassificationRuntimeService.swift` only for the already-planned observable state adapter, not semantics
- `FSD.xcodeproj/project.pbxproj`
- New `FSDTests/SnapshotBrowserClassificationTests.swift`
- Existing `FSDTests/ClassificationEnrichmentTests.swift` only for inspector/model regression assertions
- One new `handoffs/FSD_P15_RUNTIME_IMPL_05_C_<timestamp>.md` and `handoffs/CURRENT_HANDOFF.md` for closeout only

## Files/modules the Writer must not modify

- Schema/repository/source-reader/provider-process implementation, capture/scanner, search/export/comparison production code, docs, helper target/binary, external dependencies, unrelated tests

## Ordered TODOs

### TODO 1 — Inject the single runtime and add selected-entry model actions

Create the service once at app scope, inject it without invoking it, add explicit classify/cancel methods and bounded state to `SnapshotBrowserModel`, and cancel/invalidate on selection/snapshot lifecycle changes. Refresh only the selected entry's bounded details query after a current persisted result.

### TODO 2 — Implement the minimal inspector controls and truthful wording

Add the single-entry action, delayed progress/cancel affordance, bounded runtime messages, neutral absence, conditional confidence, and current-source/inferred-only disclaimer. Keep existing metadata inspector layout and accessibility conventions; add no bulk UI or destination.

### TODO 3 — Verify UI invocation and stale-state behavior

With an injected spy runtime/provider and deterministic timing, prove open/select/search/export do not start classification; one button action starts exactly one request for the selected entry; busy disables repeat action; 0.5-second progress behavior is correct; cancel/selection change prevents stale UI/persistence; and all displayed strings exclude raw diagnostics/paths and never imply historical byte verification.

## Required build/test commands

```bash
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Impl05-DerivedData clean build

xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Impl05-DerivedData \
  -only-testing:FSDTests/SnapshotBrowserClassificationTests \
  -only-testing:FSDTests/ClassificationEnrichmentTests
```

Then run the full Debug suite.

## Completion checks

- There is one app-scoped runtime and one explicit selected-entry action.
- No ordinary workflow invokes the provider as a side effect.
- Progress/cancel, busy, selection change, and late-result behavior are deterministic and tested.
- UI remains neutral on absence, bounded on error, conditional on confidence, and explicit that classification is inferred current-source metadata.
- No bulk/new-destination/background feature or external helper was added.

## Stop condition

Stop if correct single-flight ownership would require per-view runtimes, or if selection changes cannot cancel and suppress stale persistence/UI. Mark `ARCHITECT ESCALATION REQUIRED`; do not add a queue, global singleton with hidden side effects, or main-thread blocking.

## Audit gate

No separate independent audit is required before Slice 06 when build/focused/full tests pass and the UI change remains within the locked contract. UI/manual appearance remains `NOT PERFORMED — DEFERRED BY OWNER`.

