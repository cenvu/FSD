# TODO_GEMINI_P15_RUNTIME_IMPL_06.md — Cross-workflow and security regression matrix

Prepared by: Tech Lead / Architect (planning only)  
Sequence: 6 of 8  
Major TODO count: **4**  
Risk: **MEDIUM**  
Recommended Writer: **either Writer**

## Purpose

Close automated coverage gaps across `docs/TEST_PLAN.md` §9 after the bounded implementation exists. This is a tests-only verification slice: it may add test infrastructure and project wiring, but it must not repair production behavior or change the approved design.

## Prerequisites

- Slices 01–05 are merged and all automated gates pass.
- Build a traceability checklist from every line in `TEST_PLAN.md` §9 before adding tests; credit existing tests only after reading the exact assertion.

## Locked implementation decisions

- This slice is not permission to refactor production code. A newly exposed product defect stops the slice and returns a focused failure report to CONTROL for a separate correction task.
- Tests may inject spies/fakes only through seams introduced by approved slices. They may not add source/file callbacks to provider contracts.
- Adversarial-provider proof must deliberately attempt all three prohibited capabilities and demonstrate no effect: no original URL/path/handle received; no API for additional bytes; no way to receive more than the reader's 4096 bytes.
- “Zero network” is verified for FSD classification host code by source/API boundary plus a process observation harness where available. Actual Magika-helper zero-network evidence remains a Slice 07 prerequisite and may not be claimed here.
- Manual/visual acceptance remains `NOT PERFORMED — DEFERRED BY OWNER`.

## Files/modules the Writer may modify

- New `FSDTests/ClassificationInvocationIsolationTests.swift`
- New `FSDTests/ClassificationSecurityIntegrationTests.swift`
- `FSDTests/ClassificationSourceReaderTests.swift`
- `FSDTests/ClassificationProviderContractTests.swift`
- `FSDTests/BundledMagikaClassificationProviderTests.swift`
- `FSDTests/ClassificationRuntimeServiceTests.swift`
- `FSDTests/SnapshotBrowserClassificationTests.swift`
- `FSDTests/ClassificationEnrichmentTests.swift`
- `FSDTests/ComparisonSemanticsTests.swift`
- `FSDTests/JSONExportTests.swift`
- `FSDTests/TestSupport.swift` only for reusable isolated fixtures/spies
- `FSD.xcodeproj/project.pbxproj` only to wire new test files
- One new `handoffs/FSD_P15_RUNTIME_IMPL_06_C_<timestamp>.md` and `handoffs/CURRENT_HANDOFF.md` for closeout only

## Files/modules the Writer must not modify

- Every production Swift file, schema/migration/verify SQL, product/design docs, helper binary/target, external dependencies, and unrelated tests

## Ordered TODOs

### TODO 1 — Prove all forbidden workflows remain non-invoking

Use a shared counting spy and row-count assertions to prove zero classification starts during capture, application launch, history open, snapshot reopen, browsing/selection, search, comparison, and JSON export. Each workflow must be a separately identifiable assertion; constructing the runtime/provider is not invocation.

### TODO 2 — Complete persistence and isolation regressions

Prove successful/failed/source-changed/unsupported/unavailable/cancelled row behavior, no cancellation success row, no payload/sample/hash/absolute-path columns or values, no `entries`/`snapshots` mutation, append-only duplicate-run behavior, independent provenance, comparison outcome isolation, deterministic JSON format/version stability, and detached-source offline browsing without crash/hang.

### TODO 3 — Consolidate source/provider/process adversarial coverage

Fill any uncovered §9 reader boundaries and make the hostile provider attempt path recovery, additional-byte request, and ceiling bypass. Verify one 4096-byte maximum prefix, no callback/second range, raw diagnostic suppression, process input/output caps, no host network API/telemetry/watcher, and provider inability to influence persisted byte/path facts.

### TODO 4 — Produce an evidence-backed §9 coverage ledger

In the slice Handoff, map every `TEST_PLAN.md` §9 item to exact test method(s), mark external-helper-only evidence as blocked by Slice 07, list passed/failed/skipped counts and durations, and explicitly identify any gap. Do not edit `TEST_PLAN.md` or convert inferred/source inspection into runtime proof.

## Required build/test commands

```bash
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Impl06-DerivedData clean build

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
```

Then run the full Debug suite.

## Completion checks

- Every §9 item is mapped to implemented evidence or explicitly to the Slice 07 external-helper gate.
- All eight forbidden workflows have independent zero-invocation evidence.
- Mandatory adversarial-provider test proves all three constraints.
- Persistence/isolation/integrity/export/network-host assertions pass without production edits.
- No skipped/failing test is hidden; only allowlisted test/project/Handoff files changed.

## Stop condition

On any production defect, missing injection seam, flaky race, or unprovable required assertion, stop and report the exact gap. Do not modify production, weaken assertions, add sleeps in place of deterministic synchronization, or mark external-helper evidence complete.

## Audit gate

No separate audit is required solely for this mechanical test slice if all gates pass. Its coverage ledger is mandatory input to the external integration gate and the final independent audit.

