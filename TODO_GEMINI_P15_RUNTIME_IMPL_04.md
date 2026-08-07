# TODO_GEMINI_P15_RUNTIME_IMPL_04.md — Runtime orchestration, cancellation, and six outcomes

Prepared by: Tech Lead / Architect (planning only)  
Sequence: 4 of 8  
Major TODO count: **4**  
Risk: **MEDIUM**  
Recommended Writer: **Gemini**

## Purpose

Implement the explicit runtime service that joins the audited source reader, Data-only provider, and append-only repository. It enforces one in-flight request, no queue, cancellation/stale-result protection, a five-second inference timeout, and exactly the approved persistence behavior for six outcomes. It does not expose UI or automatically classify anything.

## Prerequisites

- Slices 01–03 are merged; required audits are approved.
- The helper host adapter is a tested seam only. A missing real helper must remain `.unavailable`, not be simulated as success.

## Locked implementation decisions

- Implement one app-scoped actor/service. At most one classification is active globally. A concurrent second start returns typed `.busy` immediately; `.busy` is runtime control state, not a seventh classification outcome, and writes no row.
- No queue, retry, batch, backfill, watcher, launch-time work, or implicit trigger.
- Call order is fixed: repository context → source identity/reader → bounded Data request → provider → typed result → generation/cancellation check → optional append.
- Timeout is exactly 5 seconds around inference. Timeout cancels/terminates the provider and maps to provider `.failed`; it writes one failed row only if the request is still current and not user-cancelled.
- Cancellation is checked before resolution, before open/read, after read, before inference, while inference is active, after inference, and immediately before persistence. It returns `.cancelled`, writes no row, and stale work cannot update UI or database.
- Use an actor-owned monotonically increasing generation plus task cancellation. `cancel()`/`invalidate()` increments generation and cancels the task; only the current generation may persist or publish completion.
- Persistence is exactly:
  1. classified → append `.classified` with provider identifier and detector/model provenance;
  2. provider/read `.failed` → append `.failed` (provider identifier only if the provider actually ran);
  3. `.sourceChanged` → append `.failed` with no fabricated provider/detector/model identity;
  4. `.unsupportedEntry` → append `.failed` with no fabricated provider/detector/model identity;
  5. `.unavailable` → no row;
  6. `.cancelled` → no row.
- The service mints a unique run ID at explicit start and never retries it. Duplicate-run errors remain visible typed failures; no overwrite.
- Bounded bytes exist only for the active call and are released after completion. At most two 4096-byte payload buffers may coexist across the host/IPC handoff; no encoded copy.

## Files/modules the Writer may modify

- New `FSD/Classification/ClassificationRuntimeService.swift`
- `FSD/Classification/BoundedClassificationSourceReader.swift` only for audited cancellation hooks needed by the orchestrator
- `FSD/Classification/LocalFileClassificationProvider.swift` only for audited async/cancellation conformance, never source capability
- `FSD/Classification/BundledMagikaClassificationProvider.swift` only for timeout-triggered cancellation cleanup
- `FSD/Catalog/EntryClassificationRepository.swift` only for persistence calls already locked by Slice 01
- `FSD.xcodeproj/project.pbxproj`
- New `FSDTests/ClassificationRuntimeServiceTests.swift`
- `FSDTests/ClassificationEnrichmentTests.swift` to replace obsolete service tests with final-service behavior
- One new `handoffs/FSD_P15_RUNTIME_IMPL_04_C_<timestamp>.md` and `handoffs/CURRENT_HANDOFF.md` for closeout only

## Files/modules the Writer must not modify

- Schema/migrations, SnapshotWriter/scanner, app/UI, search/export/comparison, documentation, helper binary/target, unrelated tests, external dependencies

## Ordered TODOs

### TODO 1 — Implement single-flight service state and explicit API

Add the app-scoped actor/service with explicit `start` and `cancel/invalidate`, injectable run-ID/timing dependencies for deterministic tests, one active task, immediate typed backpressure, and observable runtime state suitable for Slice 05 without importing SwiftUI.

### TODO 2 — Compose reader, provider, timeout, and stale-result protection

Execute the locked pipeline, race inference against the injected five-second deadline, propagate cancellation into the reader/provider process, and gate every result/persistence action on the current generation. Ensure late provider success after cancel/timeout cannot persist.

### TODO 3 — Implement exact six-outcome persistence mapping

Append only the four row-writing outcomes with semantically honest provenance, return no row for unavailable/cancelled, preserve repository validation and duplicate-run behavior, and keep raw errors/diagnostics/bytes/paths out of stored and visible result types.

### TODO 4 — Prove concurrency and race behavior

Test one in flight, second-request rejection/no queue, every cancellation boundary, timeout, provider crash/failure, stale late completion, cancel-vs-success and timeout-vs-success races, all six persistence outcomes, exact row counts/status/provenance, memory-buffer bounds, and unchanged snapshots/entries.

## Required build/test commands

```bash
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Impl04-DerivedData clean build

xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Impl04-DerivedData \
  -only-testing:FSDTests/ClassificationRuntimeServiceTests \
  -only-testing:FSDTests/ClassificationEnrichmentTests
```

Then run the full Debug suite.

## Completion checks

- Single-flight/backpressure, five-second timeout, cancellation, and generation rules are enforced by production code and deterministic tests.
- Exactly four outcomes can append; unavailable/cancelled/busy cannot.
- Late/stale work cannot persist or publish success.
- Provider/preflight provenance is truthful and detector/model/provider fields remain independent.
- No UI, automatic caller, actual Magika binary, new dependency, or forbidden persistence was added.

## Stop condition

Stop and mark `ARCHITECT ESCALATION REQUIRED` if Swift concurrency/process cancellation cannot prevent a stale or cancelled result from reaching persistence, or if exact single-flight semantics require a queue. Do not weaken cancellation, add retries, or serialize by blocking the main actor.

## Audit gate

No separate independent audit is required before Slice 05 if every automated gate passes and the prior schema/source/process audits are approved. Any persistence-count, race, or cancellation failure stops the sequence and requires a new bounded correction slice.

