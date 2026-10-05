# P15 runtime implementation plan

Planning contracts only. This document owns the bounded runtime slice sequence;
it grants no execution authority and claims no slice is implemented.
[PRODUCT_STATE.md](PRODUCT_STATE.md) owns the implementation baseline;
[../STATE/PROJECT_STATE.md](../STATE/PROJECT_STATE.md) owns accepted control state.
ADR-032 in [DECISIONS.md](DECISIONS.md) and [ARCHITECTURE.md](ARCHITECTURE.md)
§9a own the approved design. [TEST_PLAN.md](TEST_PLAN.md) §9 owns validation
requirements; [SECURITY_AND_READ_ONLY_POLICY.md](SECURITY_AND_READ_ONLY_POLICY.md)
owns source safety. Numeric runtime limits remain proposed implementation
constraints, not measurements of actual Magika behavior.

## Sequence and independent boundaries

Execute only a separately authorized bounded task from a freshly verified base.
The sequence is 01 → schema audit → 02 → source audit → 03 → process audit →
04 → 05 → 06 → 07 external verification → separately authorized real-helper
integration → integration audit → 08 whole-runtime verification → final audit.
No model/harness comparison, scoring or winner selection is permitted.
No stage's dependency clearance authorizes the next task. Required audits are
independent of implementation; defects return to BRAIN for a correction task.
Per-slice file lists describe future scope ceilings, not permission in this
documentation task. All returns use the canonical
[finalizer](../.agents/skills/fsd-handoff-finalizer/SKILL.md), including STATE
mechanics, immutable history, CURRENT and Desktop transport. Prior historical
handoffs remain immutable. Ordinary workflows remain metadata-only; optional
classification is inferred current-source enrichment, never snapshot byte proof.

## OLD_FILE_MAPPING

Exact old bytes remain in Git at baseline `041d2af2076ff4418f9ea5d98b124c435ea8db43`.
Old filenames below are historical lookup keys, not live file references.

| Deleted runtime TODO | Section in this plan |
|---|---|
| `TODO_GEMINI_P15_RUNTIME_IMPL_01.md` | Slice 01 — Schema v9 and provider provenance |
| `TODO_GEMINI_P15_RUNTIME_IMPL_02.md` | Slice 02 — Bounded source authority and Data-only provider contract |
| `TODO_GEMINI_P15_RUNTIME_IMPL_03.md` | Slice 03 — Bundled-helper host adapter seam |
| `TODO_GEMINI_P15_RUNTIME_IMPL_04.md` | Slice 04 — Runtime orchestration, cancellation, and six outcomes |
| `TODO_GEMINI_P15_RUNTIME_IMPL_05.md` | Slice 05 — Minimal selected-entry UI |
| `TODO_GEMINI_P15_RUNTIME_IMPL_06.md` | Slice 06 — Cross-workflow and security regression matrix |
| `TODO_GEMINI_P15_RUNTIME_IMPL_07.md` | Slice 07 — External Magika integration gate |
| `TODO_GEMINI_P15_RUNTIME_IMPL_08.md` | Slice 08 — Whole-runtime verification and canonical Handoff |

## Slice 01 — Schema v9 and provider provenance

### Purpose

Introduce the one approved persistence prerequisite for the runtime: schema version 9 adds `entry_classifications.provider_identifier`, and the typed repository round-trips it without overloading `detector_version` or `model_version`. This slice contains no source reads, provider-contract change, runtime orchestration, UI, helper process, or Magika dependency.

### Prerequisites

- Start from the exact Phase 1.5 audited-design base state and read `handoffs/CURRENT_HANDOFF.md`, `docs/ARCHITECTURE.md` §9/§9a, ADR-031/032, and this file completely.
- Record the freshly verified canonical base commit and confirm the working tree has no unrelated changes. If the environment is not a Git worktree, stop.

### Locked implementation decisions

- When separately authorized and implemented, schema becomes **9**. Migration order is 4→5→6→7→8→9; the version row is written last by the existing transaction machinery.
- The v8→v9 change is exactly one added column: `provider_identifier TEXT` on `entry_classifications`. It is appended after the existing columns so fresh and ALTER-migrated `PRAGMA table_info` order converges.
- The column is **nullable with no default**. Existing v8 rows remain `NULL`; no identity is fabricated and no row is backfilled.
- `EntryClassification.providerIdentifier` is optional because legacy and pre-provider host outcomes can truthfully lack an adapter identity.
- Repository writes for `.classified` require a non-empty provider identifier of at most 256 characters. A provider-executed `.failed` row will supply it in Slice 04. Pre-provider `.sourceChanged` / `.unsupportedEntry` rows may persist `.failed` with `NULL` because no adapter ran. `unavailable` and `cancelled` never write a row.
- `detector_version`, `model_version`, and `provider_identifier` remain three independent fields.
- Append-only behavior and `UNIQUE(entry_id, classification_run_id)` do not change. Do not add update/delete APIs.
- No schema table rebuild, trigger redesign, status-enum expansion, run table, payload/hash/path column, default sentinel, or broader schema work.

### Files/modules the Writer may modify

- `docs/database/schema.sql`
- `docs/database/verify.sql`
- `FSD/Catalog/CatalogMigrations.swift`
- `FSD/Catalog/CatalogDatabase.swift`
- `FSD/Catalog/EntryClassificationRepository.swift`
- `FSDTests/SchemaMigrationTests.swift`
- `FSDTests/SchemaSafetyCorrectionTests.swift`
- `FSDTests/CatalogDatabaseTests.swift`
- `FSDTests/ClassificationEnrichmentTests.swift`
- `FSDTests/ComparisonGUISourceBoundaryTests.swift`
- `FSDTests/M5ReliabilityTests.swift`
- `FSDTests/MilestoneConditionTests.swift`
- `FSDTests/FinalScaleSnapshotTests.swift`
- `FSDTests/ManualSessionASubstituteTests.swift`

### Files/modules the Writer must not modify

- All other production Swift, tests, Xcode project files, product/design docs, and historical Handoffs
- `SnapshotWriter`, provider/request/result types beyond the minimum compile-compatible provenance argument, UI, scanner, search, export, comparison, and helper integration
- Any dependency or external source

### Ordered steps

#### Step 1 — Add the canonical schema-v9 migration and verification state

Set `CatalogMigrations.currentVersion` to 9, append `migrationToVersion9` to `all`, add only the nullable/no-default `provider_identifier` column, seed fresh schema version 9, and extend `ExpectedState` / `verifyCurrentSchemaState()` to require the column. Preserve the existing transaction/version-last behavior.

#### Step 2 — Extend the typed repository and model round-trip

Add `providerIdentifier` to `EntryClassification` and `EntryClassificationInput`, every INSERT/SELECT/row decoder, value-length validation, equality round-trip, history, latest-row, and visible-page read. Enforce non-empty provider provenance for `.classified` inputs while retaining the locked nullable semantics above.

#### Step 3 — Extend migration-chain, rollback, fresh-schema, and damaged-schema coverage

Derive a real version-8 fixture by removing only the v9 addition from canonical schema. Prove v8→v9 migration, v4→…→v9 chain, version-row ordering, transactional rollback to v8 on a failed v9 migration, no replay on reopen, fresh/migrated column equivalence, integrity/foreign-key cleanliness, and rejection of a current-version catalog missing `provider_identifier`. Update tests whose current-version assertions are intentionally hard-coded.

#### Step 4 — Prove provenance and append-only behavior

Prove legacy v8 classification rows migrate with `provider_identifier == nil`; fresh typed classified writes require and round-trip provider identity independently of detector/model versions; duplicate-run rejection and history ordering remain unchanged; no snapshot/entry mutation occurs; and `docs/database/verify.sql` covers the new column without altering unrelated fixtures.

### Required build/test commands

Use an isolated DerivedData directory:

```bash
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Impl01-DerivedData clean build

xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Impl01-DerivedData \
  -only-testing:FSDTests/SchemaMigrationTests \
  -only-testing:FSDTests/SchemaSafetyCorrectionTests \
  -only-testing:FSDTests/CatalogDatabaseTests \
  -only-testing:FSDTests/ClassificationEnrichmentTests
```

Then run the full Debug suite with the same DerivedData path. Do not hide failed or skipped tests.

### Completion checks

- Fresh catalogs report version 9; migrated version-8 catalogs report 9 and retain all classification rows.
- Fresh and migrated `entry_classifications` column lists are identical.
- `provider_identifier` is nullable/no-default and no legacy value is invented.
- Typed classified rows round-trip three independent provenance fields.
- ExpectedState rejects a version-9 catalog missing the column.
- Duplicate-run, append-only, snapshot immutability, integrity, and foreign-key checks pass.
- Only the allowlisted files changed; no runtime/provider/UI behavior was introduced.
- Handoff reports exact commands and results; manual test state remains `NOT PERFORMED — DEFERRED BY OWNER`.

### Stop condition

Stop immediately if adding the single nullable column cannot preserve existing rows, transactional migration, or fresh/migrated equivalence. Mark `ARCHITECT ESCALATION REQUIRED`; do not rebuild the table, invent a sentinel provider, or broaden the schema. Also stop on any unrelated pre-existing failure rather than repairing outside scope.

### Audit gate

**Independent audit is required before Slice 02.** This is the schema/persistent-data boundary. Independent review evaluates product safety and persistent-data correctness.

## Slice 02 — Bounded source authority and Data-only provider contract

### Purpose

Establish the security boundary FSD must own: reliable source-root capture for new snapshots, source re-resolution and identity validation, one no-follow 4096-byte prefix read, and a provider request that contains bytes only. This slice does not implement a helper process, runtime persistence orchestration, or UI.

### Prerequisites

- Slice 01 is merged and its independent schema/persistent-data audit is approved. A separately authorized implementation task is required; no model-benchmark gate applies.
- Read the approved design, `docs/SECURITY_AND_READ_ONLY_POLICY.md` §2.1, `docs/TEST_PLAN.md` §9, `FilesystemDetector`, `SnapshotWriter`, `SnapshotTreeDataSource`, and current classification types/tests.

### Locked implementation decisions

- `SnapshotWriter` computes and stores `snapshots.root_relative_path` for every new schema-v9 capture under the FINAL root-locator contract: direct lexical containment needs no alias lookup and no identity proof; otherwise POSIX `realpath` canonicalizes the selected capture root only, exactly one physical-mount candidate is built from the canonical absolute components, and it is accepted only after same-object identity proof (st_dev and st_ino) between the canonical root and the no-follow-walked candidate. The alias proof retains the proven object through snapshot admission: inside the existing transaction, current selected/canonical-root and physical-candidate associations must agree with the pinned identity before row insertion and again before accepting the transaction; substitution fails capture and rolls back the admission. This is a **point-in-time capture admission proof**, not a filesystem namespace lock. No entry symlink resolution, no hard-coded mapping table, no second candidate; canonicalization, candidate or identity failure fails the capture closed.
- Existing snapshots with `schema_version < 9` have no trustworthy root locator because current production always left `root_relative_path` at its default. Classification of them fails closed as `.unavailable` with no row and no backfill. A genuine v9 mount-root capture is distinguishable because its schema version is 9 and its root locator is intentionally empty.
- Source identity is the current detected `volumeIdentifier` compared exactly with `volume_identifier_at_capture`; display name and mount-name coincidence are never identity. Missing recorded identity/root context is `.unavailable`; a present source with mismatched identity is `.sourceChanged`.
- Candidate paths are constructed only from validated root/entry relative components. After no-follow file open and regular-file `fstat`, a **PRE-READ OBJECT BARRIER** re-resolves exact volume/mount identity, performs a fresh no-follow walk from the physical mount through root + parent components, matches every directory by st_dev **and** st_ino, and binds the fresh final regular-file path to the opened fd by exact object identity. Any failed authority check performs zero payload reads. A successful barrier authorizes the **opened object**, not perpetual pathname stability: a later rename cannot redirect its fd; post-read source/path revalidation may still return sourceChanged.
- Only positively confirmed regular files are read. Snapshot directory/package/symlink/other entries and live directory/symlink/special files return `.unsupportedEntry` before content I/O.
- Exactly one prefix range is read. Allocate at most 4096 bytes and perform one bounded read at offset zero; small files return their actual bytes, exact-size files return 4096, and larger files return only 4096. No tail/adaptive read, hashing, persistence, or logging.
- Outcome mapping before provider invocation: detached/missing at initial resolution → `.unavailable`; identity mismatch or disappearance/substitution after initial validation → `.sourceChanged`; permission/read failure on a still-identified source → `.failed`; non-regular kind → `.unsupportedEntry`; observed cancellation at any boundary → `.cancelled`.
- Replace `LocalClassificationRequest.sourceURL` and caller-controlled `byteBudget` with a request whose **only stored field** is immutable bounded `Data`. It has no entry/source metadata, URL/path/handle, read callback, range callback, resolver, or public initializer that bypasses the FSD reader.
- `LocalClassificationProviderResult` contains all six locked cases: classified, failed, sourceChanged, unsupportedEntry, unavailable, cancelled. Providers will normally produce classified/failed/unavailable/cancelled; FSD preflight produces sourceChanged/unsupportedEntry.
- The provider call is async and cancellation-aware. The disabled provider remains side-effect-free and returns unavailable.
- Observe cancellation immediately after the pre-read object barrier and immediately before the single payload call. Once the payload attempt begins, observed cancellation wins over every later validation/error mapping to failed/sourceChanged, including fd stat, source detection, directory walk and final stat. No payload retry; genuine earlier pre-read outcomes reached without cancellation keep their meaning.

### Files/modules the Writer may modify

- `FSD/Catalog/SnapshotWriter.swift`
- `FSD/Catalog/EntryClassificationRepository.swift` (remove/relocate the old unrestricted request/provider/service seam; do not alter schema behavior)
- New `FSD/Classification/LocalFileClassificationProvider.swift`
- New `FSD/Classification/BoundedClassificationSourceReader.swift`
- `FSD.xcodeproj/project.pbxproj`
- `FSDTests/ClassificationEnrichmentTests.swift`
- `FSDTests/SnapshotHistoryTests.swift`
- New `FSDTests/ClassificationSourceReaderTests.swift`
- New `FSDTests/ClassificationProviderContractTests.swift`

### Files/modules the Writer must not modify

- Schema/migrations/verification files completed in Slice 01
- `SnapshotScanner.swift`, app/UI files, search/export/comparison code, helper-process code, product docs, unrelated tests, and external dependencies
- Do not add a provider-accessible filesystem abstraction. Test-only/internal file-access seams belong exclusively behind `BoundedClassificationSourceReader`.

### Ordered steps

#### Step 1 — Persist a trustworthy source-root locator for new captures

Populate the existing immutable `root_relative_path` field for schema-v9 captures under the FINAL root-locator contract above, and add focused capture/history tests for mount-root and nested-root sources, the macOS `/var` presentation case via the canonical `/private/var` candidate with same-object proof, the full rejection matrix (canonicalization failure, missing/different-object/escaping/unprovable candidate), plus fail-closed legacy schema-v8 behavior. Carry the alias proof token through transactional admission, revalidate both before insertion and before acceptance, and prove replacement before/during admission rolls back all new capture rows. Direct lexical admission still requires no alias-proof I/O. Do not backfill or reinterpret old rows.

#### Step 2 — Implement FSD-owned resolution, identity validation, and bounded read

Add a narrow reader that loads only the selected entry/snapshot context, validates stored and live identities, rejects path traversal and non-regular items, freshly rebinds the pinned fd through the pre-read object barrier, performs one no-follow prefix read, revalidates the open object/path with late-cancellation precedence, and returns typed bytes/outcomes. Keep injectable filesystem operations internal so tests can deterministically simulate disappearance, permission failure, substitution, and cancellation without granting provider authority.

#### Step 3 — Correct the provider-facing contract

Move the provider/request/result/disabled types into the new Classification module, remove unrestricted `sourceURL` and caller-selected budgets, expose only bounded immutable bytes, add the three missing typed outcomes, and remove the obsolete direct enrichment service until Slice 04 installs the final orchestrator. Update project wiring and compile callers/tests without creating a temporary bypass API.

#### Step 4 — Prove the read-authority boundary

Implement the full reader edge matrix: missing/unavailable, identity mismatch, directory, package, symlink, special file, below/exact/above ceiling, disappearing source, inaccessible source, and cancellation before/during/after read. Add the mandatory hostile-provider proof: the request reveals no original path/URL/handle; has no callback for more bytes; and never contains more than 4096 bytes even when the fake attempts all three violations. Assert one content-read call, zero tail reads, and no logged/persisted sample/hash/path. Add causal acquired-parent/outside-child and opened-file replacement regressions requiring zero reads before authority success; verify a namespace move after the barrier cannot redirect the pinned object. Add cancellation/error schedules at each late validation boundary, with cancellation=false controls.

### Required build/test commands

```bash
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Impl02-DerivedData clean build

xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Impl02-DerivedData \
  -only-testing:FSDTests/ClassificationSourceReaderTests \
  -only-testing:FSDTests/ClassificationProviderContractTests \
  -only-testing:FSDTests/ClassificationEnrichmentTests \
  -only-testing:FSDTests/SnapshotHistoryTests
```

Then run the full Debug suite.

### Completion checks

- Provider request contains bounded Data only; no entry/source metadata or source capability exists.
- Reader tests prove one read, maximum 4096 bytes, and every required edge/outcome.
- Symlink/path-race tests show no escape and no followed link.
- New captures record exact root context; old snapshots remain unchanged and fail closed.
- No sampled bytes, hash, absolute path, raw diagnostic, source write, network call, watcher, or automatic invocation was introduced.
- Build and focused/full tests pass with honest counts; only allowlisted files changed.

### Stop condition

If the platform APIs cannot guarantee no-follow open plus object/path identity validation under the locked one-read policy, mark `ARCHITECT ESCALATION REQUIRED` and stop. Do not fall back to `Data(contentsOf:)`, `FileHandle.readToEnd()`, symlink resolution, a provider callback, name-based source matching, or a second content read.

### Audit gate

**Independent audit is required before Slice 03.** This is the source read-authority/read-only-security boundary. Audit occurs after the complete four-step slice, not after individual TODOs.

## Slice 03 — Bundled-helper host adapter seam

### Purpose

Implement and test the FSD-side process boundary for a locally bundled helper without downloading, vendoring, building, or pretending to implement Magika itself. The host adapter accepts only the bounded bytes from Slice 02, selects a fixed executable canonically resolved inside the trusted FSD app bundle, uses bounded raw-byte IPC, and converts helper/process behavior to typed results.

### Prerequisites

- Slices 01 and 02 are merged and their independent audits approved.
- No external Magika facts may be assumed. Read Slice 07's escalation gate before coding this slice.

### Locked implementation decisions

- Packaging remains a locally bundled helper executable. The host never searches `$PATH`, invokes a shell, or accepts a user/defaults/environment override for the executable.
- `TRUSTED_CODE_ROOT=FSD_INSTALLED_SIGNED_APP_BUNDLE`. Same-principal mutation, rename, replacement or rewrite of FSD's own application code bundle after trusted resolution is outside the Slice-03 host-seam threat model; this does not assert filesystem namespace immutability or atomic path protection by macOS/code signing.
- Fixed bundle-relative resolution, canonical containment inside the standardized canonical bundle root, regular-file/executable validation and no PATH/shell/config override remain mandatory defense in depth. Missing/non-executable helper maps to `.unavailable`. Path validation is not an object-bound execution guarantee: pathname TOCTOU under bundle mutation still exists, and `Process` does not launch an opened descriptor.
- Before real integration, Slice 07 must verify nested-helper signing/packaging, bundle placement, real artifact identity and distribution integrity, plus absence of persistent helper descendants. This seam supplies no process-tree containment guarantee.
- The 0–4096 input bytes are written as raw stdin once, then stdin is closed. Do not base64/hex/JSON-wrap the sample, write it to disk, pass it in argv/environment, or expose the source path.
- Stdout is a small versioned metadata envelope only: schema version, result kind, detected type, MIME type, confidence, detector version, model version. Lock a 4096-byte stdout cap and a 4096-byte stderr drain cap; stderr is never stored or shown. Oversize/malformed/unknown output is `.failed`.
- `providerIdentifier` is a host-defined stable adapter identifier, independent from helper-reported detector/model versions. Helper output cannot override it.
- Launch authorization and cancellation linearize under the same lock after side-effect-free runner creation. Cancellation winning before authorization forbids launch; authorization winning first permits launch, with later cancellation terminating any launched child, closing pipes, reaping and returning `.cancelled` if it wins before completion. Completion winning first preserves the deterministic result. The boundary is launch authorization, not the kernel's child-creation instruction; the lock is never held across `Process.run`. Crash/non-zero exit/malformed output returns `.failed`. Timeout policy is enforced by Slice 04's runtime, but cancellation must reliably stop the process.
- No persistent helper daemon, background watcher, telemetry, network API, sampled-byte persistence, or automatic launch.
- Tests use an injected fake process runner. They do not execute Magika, install dependencies, use an external command, or require a real helper binary.

### Files/modules the Writer may modify

- New `FSD/Classification/BundledMagikaClassificationProvider.swift`
- `FSD/Classification/LocalFileClassificationProvider.swift` only if the audited Slice 02 contract needs the adapter conformance hook; no source capabilities may be added
- `FSD.xcodeproj/project.pbxproj`
- New `FSDTests/BundledMagikaClassificationProviderTests.swift`
- `FSDTests/ClassificationProviderContractTests.swift` for additive adapter-boundary assertions only

### Files/modules the Writer must not modify

- Schema/repository/source-reader/capture files, app/UI, orchestration, search/export/comparison, product docs, unrelated tests
- No helper target, Magika source/model/binary, package manifest, downloaded artifact, network entitlement, shell script, or dependency

### Ordered steps

#### Step 1 — Implement the bounded process-runner boundary

Add a narrow internal runner that validates the bundle-contained executable, starts `Process` directly with fixed arguments, streams the already-bounded input to stdin, caps/drains stdout and stderr without deadlock, reaps every termination path, and exposes cancellation. Process objects, pipes, and diagnostics stay behind this file and never enter the provider request/result.

#### Step 2 — Implement the typed bundled-helper provider adapter

Parse the locked versioned metadata envelope with strict field/count/length/confidence validation, keep provider/detector/model provenance separate, and deterministically map missing helper, success, declared unavailable, failure, crash, malformed/oversized output, and cancellation to the approved typed results. Do not add a fallback classifier.

#### Step 3 — Prove process-boundary failure handling and scope

With a fake runner, test exact raw input bytes and length, one stdin delivery, fixed executable resolution, no path/handle in request or IPC, output caps, hostile stderr suppression, unknown envelope/version rejection, provenance separation, cancellation/termination/reaping, and every typed process outcome. Add source-boundary assertions that no shell, `$PATH`, temporary sample file, URLSession/network API, telemetry, or persistent process was introduced.

### Required build/test commands

```bash
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Impl03-DerivedData clean build

xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Impl03-DerivedData \
  -only-testing:FSDTests/BundledMagikaClassificationProviderTests \
  -only-testing:FSDTests/ClassificationProviderContractTests
```

Then run the full Debug suite.

### Completion checks

- Production host adapter compiles and is inert until explicitly called.
- No real helper or Magika asset exists; tests use only the injected runner.
- Input/output caps and all termination paths are deterministic and covered.
- Provider identity cannot be supplied or overwritten by helper output.
- Missing helper is unavailable; process faults are failed; cancellation is runtime-only.
- Only allowlisted files changed and every required command/result is reported honestly.

### Stop condition

If safe bounded pipe draining, cancellation, or child reaping cannot be implemented without unbounded buffering, shell invocation, temporary sample files, or source authority, mark `ARCHITECT ESCALATION REQUIRED` and stop. Do not invent Magika CLI/output/license/model facts.

### Audit gate

**Independent audit is required before Slice 04** because this is a HIGH-risk process/security boundary. The audit evaluates the whole three-step slice once.

## Slice 04 — Runtime orchestration, cancellation, and six outcomes

### Purpose

Implement the explicit runtime service that joins the audited source reader, Data-only provider, and append-only repository. It enforces one in-flight request, no queue, cancellation/stale-result protection, a five-second inference timeout, and exactly the approved persistence behavior for six outcomes. It does not expose UI or automatically classify anything.

### Prerequisites

- Slices 01–03 are merged; required audits are approved.
- The helper host adapter is a tested seam only. A missing real helper must remain `.unavailable`, not be simulated as success.

### Locked implementation decisions

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

### Files/modules the Writer may modify

- New `FSD/Classification/ClassificationRuntimeService.swift`
- `FSD/Classification/BoundedClassificationSourceReader.swift` only for audited cancellation hooks needed by the orchestrator
- `FSD/Classification/LocalFileClassificationProvider.swift` only for audited async/cancellation conformance, never source capability
- `FSD/Classification/BundledMagikaClassificationProvider.swift` only for timeout-triggered cancellation cleanup
- `FSD/Catalog/EntryClassificationRepository.swift` only for persistence calls already locked by Slice 01
- `FSD.xcodeproj/project.pbxproj`
- New `FSDTests/ClassificationRuntimeServiceTests.swift`
- `FSDTests/ClassificationEnrichmentTests.swift` to replace obsolete service tests with final-service behavior

### Files/modules the Writer must not modify

- Schema/migrations, SnapshotWriter/scanner, app/UI, search/export/comparison, documentation, helper binary/target, unrelated tests, external dependencies

### Ordered steps

#### Step 1 — Implement single-flight service state and explicit API

Add the app-scoped actor/service with explicit `start` and `cancel/invalidate`, injectable run-ID/timing dependencies for deterministic tests, one active task, immediate typed backpressure, and observable runtime state suitable for Slice 05 without importing SwiftUI.

#### Step 2 — Compose reader, provider, timeout, and stale-result protection

Execute the locked pipeline, race inference against the injected five-second deadline, propagate cancellation into the reader/provider process, and gate every result/persistence action on the current generation. Ensure late provider success after cancel/timeout cannot persist.

#### Step 3 — Implement exact six-outcome persistence mapping

Append only the four row-writing outcomes with semantically honest provenance, return no row for unavailable/cancelled, preserve repository validation and duplicate-run behavior, and keep raw errors/diagnostics/bytes/paths out of stored and visible result types.

#### Step 4 — Prove concurrency and race behavior

Test one in flight, second-request rejection/no queue, every cancellation boundary, timeout, provider crash/failure, stale late completion, cancel-vs-success and timeout-vs-success races, all six persistence outcomes, exact row counts/status/provenance, memory-buffer bounds, and unchanged snapshots/entries.

### Required build/test commands

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

### Completion checks

- Single-flight/backpressure, five-second timeout, cancellation, and generation rules are enforced by production code and deterministic tests.
- Exactly four outcomes can append; unavailable/cancelled/busy cannot.
- Late/stale work cannot persist or publish success.
- Provider/preflight provenance is truthful and detector/model/provider fields remain independent.
- No UI, automatic caller, actual Magika binary, new dependency, or forbidden persistence was added.

### Stop condition

Stop and mark `ARCHITECT ESCALATION REQUIRED` if Swift concurrency/process cancellation cannot prevent a stale or cancelled result from reaching persistence, or if exact single-flight semantics require a queue. Do not weaken cancellation, add retries, or serialize by blocking the main actor.

### Audit gate

No separate independent audit is required before Slice 05 if every automated gate passes and the prior schema/source/process audits are approved. Any persistence-count, race, or cancellation failure stops the sequence and requires a new bounded correction slice.

## Slice 05 — Minimal selected-entry UI

### Purpose

Expose the approved runtime only as an explicit action for the currently selected entry. Add bounded progress/cancel/status behavior and refresh the inspector without creating a bulk classifier, destination, background trigger, or historical-content claim.

### Prerequisites

- Slices 01–04 are merged and green; all required prior audits are approved.
- Read the current `SnapshotBrowserModel`, `SnapshotBrowserView`, `EntryInspectorView`, `ApplicationModel`, and existing UI/model test patterns before editing.

### Locked implementation decisions

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

### Files/modules the Writer may modify

- `FSD/App/FSDApp.swift`
- `FSD/UI/SnapshotBrowserView.swift`
- `FSD/Browser/SnapshotTreeDataSource.swift` only for a bounded selected-entry classification refresh/invalidation hook; no filesystem work
- `FSD/Classification/ClassificationRuntimeService.swift` only for the already-planned observable state adapter, not semantics
- `FSD.xcodeproj/project.pbxproj`
- New `FSDTests/SnapshotBrowserClassificationTests.swift`
- Existing `FSDTests/ClassificationEnrichmentTests.swift` only for inspector/model regression assertions

### Files/modules the Writer must not modify

- Schema/repository/source-reader/provider-process implementation, capture/scanner, search/export/comparison production code, docs, helper target/binary, external dependencies, unrelated tests

### Ordered steps

#### Step 1 — Inject the single runtime and add selected-entry model actions

Create the service once at app scope, inject it without invoking it, add explicit classify/cancel methods and bounded state to `SnapshotBrowserModel`, and cancel/invalidate on selection/snapshot lifecycle changes. Refresh only the selected entry's bounded details query after a current persisted result.

#### Step 2 — Implement the minimal inspector controls and truthful wording

Add the single-entry action, delayed progress/cancel affordance, bounded runtime messages, neutral absence, conditional confidence, and current-source/inferred-only disclaimer. Keep existing metadata inspector layout and accessibility conventions; add no bulk UI or destination.

#### Step 3 — Verify UI invocation and stale-state behavior

With an injected spy runtime/provider and deterministic timing, prove open/select/search/export do not start classification; one button action starts exactly one request for the selected entry; busy disables repeat action; 0.5-second progress behavior is correct; cancel/selection change prevents stale UI/persistence; and all displayed strings exclude raw diagnostics/paths and never imply historical byte verification.

### Required build/test commands

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

### Completion checks

- There is one app-scoped runtime and one explicit selected-entry action.
- No ordinary workflow invokes the provider as a side effect.
- Progress/cancel, busy, selection change, and late-result behavior are deterministic and tested.
- UI remains neutral on absence, bounded on error, conditional on confidence, and explicit that classification is inferred current-source metadata.
- No bulk/new-destination/background feature or external helper was added.

### Stop condition

Stop if correct single-flight ownership would require per-view runtimes, or if selection changes cannot cancel and suppress stale persistence/UI. Mark `ARCHITECT ESCALATION REQUIRED`; do not add a queue, global singleton with hidden side effects, or main-thread blocking.

### Audit gate

No separate independent audit is required before Slice 06 when build/focused/full tests pass and the UI change remains within the locked contract. UI/manual appearance remains `NOT PERFORMED — DEFERRED BY OWNER`.

## Slice 06 — Cross-workflow and security regression matrix

### Purpose

Close automated coverage gaps across `docs/TEST_PLAN.md` §9 after the bounded implementation exists. This is a tests-only verification slice: it may add test infrastructure and project wiring, but it must not repair production behavior or change the approved design.

### Prerequisites

- Slices 01–05 are merged and all automated gates pass.
- Build a traceability checklist from every line in `docs/TEST_PLAN.md` §9 before adding tests; credit existing tests only after reading the exact assertion.

### Locked implementation decisions

- This slice is not permission to refactor production code. A newly exposed product defect stops the slice and returns a focused failure report to CONTROL for a separate correction task.
- Tests may inject spies/fakes only through seams introduced by approved slices. They may not add source/file callbacks to provider contracts.
- Adversarial-provider proof must deliberately attempt all three prohibited capabilities and demonstrate no effect: no original URL/path/handle received; no API for additional bytes; no way to receive more than the reader's 4096 bytes.
- “Zero network” is verified for FSD classification host code by source/API boundary plus a process observation harness where available. Actual Magika-helper zero-network evidence remains a Slice 07 prerequisite and may not be claimed here.
- Manual/visual acceptance remains `NOT PERFORMED — DEFERRED BY OWNER`.

### Files/modules the Writer may modify

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

### Files/modules the Writer must not modify

- Every production Swift file, schema/migration/verify SQL, product/design docs, helper binary/target, external dependencies, and unrelated tests

### Ordered steps

#### Step 1 — Prove all forbidden workflows remain non-invoking

Use a shared counting spy and row-count assertions to prove zero classification starts during capture, application launch, history open, snapshot reopen, browsing/selection, search, comparison, and JSON export. Each workflow must be a separately identifiable assertion; constructing the runtime/provider is not invocation.

#### Step 2 — Complete persistence and isolation regressions

Prove successful/failed/source-changed/unsupported/unavailable/cancelled row behavior, no cancellation success row, no payload/sample/hash/absolute-path columns or values, no `entries`/`snapshots` mutation, append-only duplicate-run behavior, independent provenance, comparison outcome isolation, deterministic JSON format/version stability, and detached-source offline browsing without crash/hang.

#### Step 3 — Consolidate source/provider/process adversarial coverage

Fill any uncovered §9 reader boundaries and make the hostile provider attempt path recovery, additional-byte request, and ceiling bypass. Verify one 4096-byte maximum prefix, no callback/second range, raw diagnostic suppression, process input/output caps, no host network API/telemetry/watcher, and provider inability to influence persisted byte/path facts.

#### Step 4 — Produce an evidence-backed §9 coverage ledger

In the slice Handoff, map every `docs/TEST_PLAN.md` §9 item to exact test method(s), mark external-helper-only evidence as blocked by Slice 07, list passed/failed/skipped counts and durations, and explicitly identify any gap. Do not edit `docs/TEST_PLAN.md` or convert inferred/source inspection into runtime proof.

### Required build/test commands

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

### Completion checks

- Every §9 item is mapped to implemented evidence or explicitly to the Slice 07 external-helper gate.
- All eight forbidden workflows have independent zero-invocation evidence.
- Mandatory adversarial-provider test proves all three constraints.
- Persistence/isolation/integrity/export/network-host assertions pass without production edits.
- No skipped/failing test is hidden; only allowlisted test/project/Handoff files changed.

### Stop condition

On any production defect, missing injection seam, flaky race, or unprovable required assertion, stop and report the exact gap. Do not modify production, weaken assertions, add sleeps in place of deterministic synchronization, or mark external-helper evidence complete.

### Audit gate

No separate audit is required solely for this mechanical test slice if all gates pass. Its coverage ledger is mandatory input to the external integration gate and the final independent audit.

## Slice 07 — External Magika integration gate

### Purpose

Resolve the external facts required to replace Slice 03's tested host seam with a real locally bundled Magika helper. This file is deliberately a stop gate, not authorization to browse, download, install, vendor, build, or modify production code.

### Unresolved external prerequisite

`EXTERNAL VERIFICATION REQUIRED`; Architect escalation is required before integration. This is a technical prerequisite, not the active control gate.

Repository evidence cannot establish the exact upstream license/model redistribution terms, supported native macOS arm64 embedding/build shape, pinned source/model artifact identities, helper API, or detector/model version reporting. The accepted design did not verify those external Magika facts. Inventing filenames, checksums, build flags, target inputs, or an output mapping would violate the audited design.

### Prerequisites

- Slices 01–06 are merged and green.
- CONTROL explicitly authorizes a separate external-verification session.
- That session starts from the exact accepted base and preserves the fixed locally bundled helper decision, bounded raw-byte host contract, no network/telemetry, and self-contained app invariant.

### Locked decisions that external verification may not overturn

- Provider input is only the already-read 0–4096-byte prefix; no path/URL/handle/callback.
- Helper is bundled inside the app, arm64/macOS 13 compatible, fully offline, separately crash-isolated, and never discovered via `$PATH` or user installation.
- No Python/runtime dependency may be introduced without an explicit new architecture decision; current audited packaging ruled that shape out.
- Model/detector/provider versions are distinct and exact; helper output cannot set provider identity.
- No source write, sample persistence/hash/logging, network, telemetry, watcher, backfill, daemon, or automatic invocation.
- Existing Slice 03 IPC caps/result envelope are the host contract. If verified Magika cannot fit it, stop for architecture review rather than changing it in an implementation task.

### Files/modules the Architect may modify in this gate

- One research return under the canonical finalizer; no product mutation
- A bounded implementation contract supplied in the research handoff/task prompt to BRAIN only after all facts below are verified; no new parallel planning document

### Files/modules that must not be modified under this gate

- All production Swift, tests, schema/SQL, `FSD.xcodeproj`, app bundle contents, other product docs, dependencies, vendor directories, Magika source/model/binaries, and historical Handoffs

### Ordered steps

#### Step 1 — Verify and record the external integration facts

In an explicitly authorized external-research session, record authoritative license and model redistribution terms; exact upstream version/commit and asset checksums; supported macOS arm64 build/runtime path; minimum deployment compatibility; model/runtime footprint; deterministic bounded-input API behavior; exact output/provenance semantics; offline/no-telemetry behavior; and signing/bundle placement requirements. Separate quoted facts from Architect inference. Do not change code.

#### Step 2 — Issue the bounded integration Worker slice or stop permanently

If and only if every fixed requirement is satisfiable, propose a bounded 2–4-step implementation contract to BRAIN with an exact allowlist for helper target sources, pinned vendored artifacts, project copy/sign phases, adapter mapping, license notices, and real integration/network/crash/timeout tests. If any fact conflicts with the fixed design, keep `ARCHITECT ESCALATION REQUIRED`, document the conflict, and do not authorize a workaround.

### Required build/test commands

None in this gate. It performs no implementation. The bounded integration Worker contract must specify its own clean Debug/Release arm64 builds, targeted helper integration tests, full suite, bundle inspection, code-sign/load checks as applicable, crash/timeout/cancellation probes, and zero-network observation.

### Completion checks

- Every external fact is supported by an authoritative source and pinned artifact identity.
- Licensing covers both executable/runtime and model redistribution.
- A real offline arm64 helper can satisfy the already-implemented byte/result contract.
- Proposed integration contract has 2–4 major steps, exact file/artifact allowlists, commands, stop conditions, and an independent audit gate.
- No code/artifact/dependency was changed during this gate.

### Stop condition

This external gate remains `ARCHITECT ESCALATION REQUIRED` until separately authorized research resolves every required fact. Route to an Architect with external-verification authority. Any unresolved license, model, API, build, signing, provenance, offline, or macOS compatibility fact keeps the gate closed.

### Audit gate

The eventual replacement integration slice is **HIGH risk and requires independent audit** before Slice 08. The audit must include app-bundle contents, process isolation, no-network evidence, exact provenance, and full failure-mode behavior.

## Slice 08 — Whole-runtime verification and canonical Handoff

### Purpose

Perform whole-implementation verification, synchronize only the documentation facts proven by the completed runtime, and create the canonical Phase 1.5 runtime Handoff. This terminal slice fixes no production/test defect and makes no unverified release claim.

### Prerequisites

- Slices 01–06 are merged and their required audits passed.
- Slice 07's escalation is resolved by a separately approved replacement implementation slice, and that real helper integration has passed independent audit.
- Every intermediate Writer/audit Handoff and the Slice 06 §9 coverage ledger are available.
- If a real bundled Magika helper is not present and verified, stop; do not finalize a seam/stub as “runtime implemented.”

### Locked decisions

- This slice is verification/documentation only. Any defect creates a new bounded correction task; do not patch code/tests/schema here.
- Manual UI/VoiceOver/physical-media testing remains `NOT PERFORMED — DEFERRED BY OWNER` unless Cen explicitly changes that state.
- “Runtime implemented” requires real helper execution evidence, not fake runner/stub evidence.
- Claims distinguish `AUTOMATED VERIFIED`, `AGENT-OBSERVED`, `INFERRED`, and deferred manual evidence.
- Canonical Handoff follows `.agents/skills/fsd-handoff-finalizer/SKILL.md`; Worker return remains pending BRAIN adjudication.

### Files/modules the Writer may modify

- `docs/ARCHITECTURE.md` §9/§9a status wording only
- `docs/DECISIONS.md` ADR-031/032 status/implementation note only
- `docs/SECURITY_AND_READ_ONLY_POLICY.md` §2.1 status and verified call-site inventory only
- `docs/TEST_PLAN.md` §9 evidence/status only; preserve requirements
- `docs/MVP_PLAN.md` Phase 1.5 dependency pointers only; implementation status belongs to PRODUCT_STATE
- `docs/PRODUCT_STATE.md` implementation status, KI-025 and residual risks only
- One immutable runtime handoff, CURRENT, Worker ledger/event and Desktop transport under the canonical finalizer

### Files/modules the Writer must not modify

- Every production Swift file, test, schema/SQL, Xcode project/scheme, helper/vendor/model/binary, dependency, unrelated documentation section, and historical Handoff

### Ordered steps

#### Step 1 — Run and inspect the complete verification matrix

Run clean Debug and Release arm64 builds, all focused classification suites, the full test suite, schema migration/integrity/foreign-key checks, app-bundle/helper architecture and placement inspection, real success/missing/crash/hang/timeout/cancel probes, 4096-byte and adversarial-provider proofs, eight-workflow no-invocation suite, persistence/isolation/export checks, and zero-network observation during real classification. Record exact commands, durations, passed/failed/skipped counts, helper/provider/detector/model versions, and any environment limitation.

#### Step 2 — Synchronize proven status and write the canonical Handoff

Update only the allowlisted status paragraphs so they agree on schema version, implementation state, six outcomes, explicit-only UI, external artifact/version/license facts, test evidence, remaining limitations, and KI-025 disposition. Write the one canonical historical Handoff and full `CURRENT_HANDOFF.md`; include exact files changed, audit verdicts, evidence labels, manual state, no false content-verification claim, and one Worker proposal for BRAIN adjudication.

### Required build/test commands

At minimum, with new isolated paths:

```bash
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Final-Debug clean build

xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Final-Debug

xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Final-Release clean build
```

Also run every real-helper command mandated by Slice 07's separately authorized integration contract. Do not substitute fake-runner results.

### Completion checks

- All required builds/tests/probes pass, or status is not COMPLETE.
- App bundle contains the exact audited arm64 helper/model/license assets and no unexpected runtime/dependency.
- Schema 9 fresh/migration state and four/no-row persistence outcomes remain correct.
- All eight forbidden workflows remain zero-invocation; explicit UI is the sole trigger.
- No source write/sample/hash/path/network/telemetry/background behavior is observed.
- Documentation agrees and the canonical Handoff contains exact, reproducible evidence.
- `git diff --name-only` (or equivalent recorded manifest when unavailable) contains only allowlisted documentation/Handoff files for this slice.

### Stop condition

Stop on any build/test/probe failure, missing real helper, unresolved Slice 07 fact, documentation contradiction requiring a design change, unexpected changed file, or unavailable evidence needed for a claim. Do not patch, soften wording, or mark COMPLETE.

### Audit gate

**Independent final implementation audit is mandatory.** CONTROL reviews the canonical Handoff plus exact evidence before accepting Phase 1.5 runtime. Manual acceptance remains separately deferred.
