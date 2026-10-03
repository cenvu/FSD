# TODO_GEMINI_P15_RUNTIME_IMPL_02.md — Bounded source authority and Data-only provider contract

Prepared by: Tech Lead / Architect (planning only)  
Sequence: 2 of 8  
Major TODO count: **4**  
Risk: **HIGH**  
Recommended Writer: **Gemini**

## Purpose

Establish the security boundary FSD must own: reliable source-root capture for new snapshots, source re-resolution and identity validation, one no-follow 4096-byte prefix read, and a provider request that contains bytes only. This slice does not implement a helper process, runtime persistence orchestration, or UI.

## Prerequisites

- Slice 01 is merged and its independent schema/persistent-data audit is approved. A separately authorized implementation task is required; no model-benchmark gate applies.
- Read the approved design, `SECURITY_AND_READ_ONLY_POLICY.md` §2.1, `TEST_PLAN.md` §9, `FilesystemDetector`, `SnapshotWriter`, `SnapshotTreeDataSource`, and current classification types/tests.

## Locked implementation decisions

- `SnapshotWriter` computes and stores `snapshots.root_relative_path` for every new schema-v9 capture as the normalized lexical path from the detected mount root to `descriptor.rootURL`. It must be relative, must not contain `.`/`..`, and must fail capture rather than guess if the selected root is outside the mount.
- Existing snapshots with `schema_version < 9` have no trustworthy root locator because current production always left `root_relative_path` at its default. Classification of them fails closed as `.unavailable` with no row and no backfill. A genuine v9 mount-root capture is distinguishable because its schema version is 9 and its root locator is intentionally empty.
- Source identity is the current detected `volumeIdentifier` compared exactly with `volume_identifier_at_capture`; display name and mount-name coincidence are never identity. Missing recorded identity/root context is `.unavailable`; a present source with mismatched identity is `.sourceChanged`.
- Candidate paths are constructed only from validated root/entry relative components. Use POSIX no-follow semantics (`lstat`/`open` with `O_NOFOLLOW`, then `fstat`) and post-read identity validation so symlink/race substitution cannot escape the selected root.
- Only positively confirmed regular files are read. Snapshot directory/package/symlink/other entries and live directory/symlink/special files return `.unsupportedEntry` before content I/O.
- Exactly one prefix range is read. Allocate at most 4096 bytes and perform one bounded read at offset zero; small files return their actual bytes, exact-size files return 4096, and larger files return only 4096. No tail/adaptive read, hashing, persistence, or logging.
- Outcome mapping before provider invocation: detached/missing at initial resolution → `.unavailable`; identity mismatch or disappearance/substitution after initial validation → `.sourceChanged`; permission/read failure on a still-identified source → `.failed`; non-regular kind → `.unsupportedEntry`; observed cancellation at any boundary → `.cancelled`.
- Replace `LocalClassificationRequest.sourceURL` and caller-controlled `byteBudget` with a request whose **only stored field** is immutable bounded `Data`. It has no entry/source metadata, URL/path/handle, read callback, range callback, resolver, or public initializer that bypasses the FSD reader.
- `LocalClassificationProviderResult` contains all six locked cases: classified, failed, sourceChanged, unsupportedEntry, unavailable, cancelled. Providers will normally produce classified/failed/unavailable/cancelled; FSD preflight produces sourceChanged/unsupportedEntry.
- The provider call is async and cancellation-aware. The disabled provider remains side-effect-free and returns unavailable.

## Files/modules the Writer may modify

- `FSD/Catalog/SnapshotWriter.swift`
- `FSD/Catalog/EntryClassificationRepository.swift` (remove/relocate the old unrestricted request/provider/service seam; do not alter schema behavior)
- New `FSD/Classification/LocalFileClassificationProvider.swift`
- New `FSD/Classification/BoundedClassificationSourceReader.swift`
- `FSD.xcodeproj/project.pbxproj`
- `FSDTests/ClassificationEnrichmentTests.swift`
- `FSDTests/SnapshotHistoryTests.swift`
- New `FSDTests/ClassificationSourceReaderTests.swift`
- New `FSDTests/ClassificationProviderContractTests.swift`
- One new `handoffs/FSD_P15_RUNTIME_IMPL_02_C_<timestamp>.md` and `handoffs/CURRENT_HANDOFF.md` for closeout only

## Files/modules the Writer must not modify

- Schema/migrations/verification files completed in Slice 01
- `SnapshotScanner.swift`, app/UI files, search/export/comparison code, helper-process code, product docs, unrelated tests, and external dependencies
- Do not add a provider-accessible filesystem abstraction. Test-only/internal file-access seams belong exclusively behind `BoundedClassificationSourceReader`.

## Ordered TODOs

### TODO 1 — Persist a trustworthy source-root locator for new captures

Populate the existing immutable `root_relative_path` field for schema-v9 captures, validate it is beneath the detected mount, and add focused capture/history tests for mount-root and nested-root sources plus fail-closed legacy schema-v8 behavior. Do not backfill or reinterpret old rows.

### TODO 2 — Implement FSD-owned resolution, identity validation, and bounded read

Add a narrow reader that loads only the selected entry/snapshot context, validates stored and live identities, rejects path traversal and non-regular items, performs one no-follow prefix read, revalidates the open object/path, and returns typed bytes/outcomes. Keep injectable filesystem operations internal so tests can deterministically simulate disappearance, permission failure, substitution, and cancellation without granting provider authority.

### TODO 3 — Correct the provider-facing contract

Move the provider/request/result/disabled types into the new Classification module, remove unrestricted `sourceURL` and caller-selected budgets, expose only bounded immutable bytes, add the three missing typed outcomes, and remove the obsolete direct enrichment service until Slice 04 installs the final orchestrator. Update project wiring and compile callers/tests without creating a temporary bypass API.

### TODO 4 — Prove the read-authority boundary

Implement the full reader edge matrix: missing/unavailable, identity mismatch, directory, package, symlink, special file, below/exact/above ceiling, disappearing source, inaccessible source, and cancellation before/during/after read. Add the mandatory hostile-provider proof: the request reveals no original path/URL/handle; has no callback for more bytes; and never contains more than 4096 bytes even when the fake attempts all three violations. Assert one content-read call, zero tail reads, and no logged/persisted sample/hash/path.

## Required build/test commands

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

## Completion checks

- Provider request contains bounded Data only; no entry/source metadata or source capability exists.
- Reader tests prove one read, maximum 4096 bytes, and every required edge/outcome.
- Symlink/path-race tests show no escape and no followed link.
- New captures record exact root context; old snapshots remain unchanged and fail closed.
- No sampled bytes, hash, absolute path, raw diagnostic, source write, network call, watcher, or automatic invocation was introduced.
- Build and focused/full tests pass with honest counts; only allowlisted files changed.

## Stop condition

If the platform APIs cannot guarantee no-follow open plus object/path identity validation under the locked one-read policy, mark `ARCHITECT ESCALATION REQUIRED` and stop. Do not fall back to `Data(contentsOf:)`, `FileHandle.readToEnd()`, symlink resolution, a provider callback, name-based source matching, or a second content read.

## Audit gate

**Independent audit is required before Slice 03.** This is the source read-authority/read-only-security boundary. Audit occurs after the complete four-TODO slice, not after individual TODOs.
