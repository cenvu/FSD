# Handoff

## Identity
- Project: FSD — FishSock Differ
- Task: FSD-M2-CAPTURE-SAFETY-0804-04
- Case code: FSD_M2_CAPTURE_SAFETY_C
- Role: WRITER
- Agent / model: Codex / GPT-5
- Session ID: N/A (API session)
- Started: 2026-08-04T01:05:02+0700
- Completed: 2026-08-04T01:43:16+0700

## Status

COMPLETE_WITH_KNOWN_LIMITATIONS. Milestone 2's controlled-folder metadata capture workflow is implemented and validated. Manual Session A has not been performed, and no independent audit was performed in this Writer task.

## Repository State
- Root: `/Users/cenvu/DEV/FSD`
- Branch: N/A — not a Git repository
- Commit: N/A — no commit created
- Git status: `git status --short: BLOCKED — NOT A REPOSITORY`; `git diff --check: BLOCKED — NOT A REPOSITORY`
- Pre-existing user changes: M1 project/source/tests and handoff files, plus existing scratch artifacts (`temp.db*`, `fix_mount_consent.py`, `modify_schema.py`, `modify_verify.py`, `replace_docs.py`, `verify_output.txt`) were present and preserved. The existing CodeGraph directory was not edited.

## Objective

Deliver the Milestone 2 metadata-only capture foundation: native mounted provider boundary, filesystem detection, streaming enumeration, bounded SQLite persistence, atomic completion, cancellation, startup recovery, minimal capture UI, source-safety tests, and Manual Session A readiness.

## Inputs Read

Read `handoffs/CURRENT_HANDOFF.md`, the Milestone 2 sections of `docs/MVP_PLAN.md`, `docs/PRODUCT_STATE.md`, `docs/PRD.md`, `docs/ARCHITECTURE.md`, `docs/FILESYSTEM_PROVIDER_ARCHITECTURE.md`, `docs/DECISIONS.md` ADR-009 through ADR-012 and directly related provider decisions, `docs/SECURITY_AND_READ_ONLY_POLICY.md`, relevant `docs/TEST_PLAN.md` sections, `docs/database/schema.sql`, `docs/database/verify.sql`, `docs/AGENT.md`, the M1 Swift source and tests, and the project file. CodeGraph was queried for the existing foundation symbols before editing.

## Implementation Summary

Added a production native-mounted capture path with no third-party dependencies. Enumeration remains metadata-only and callback-based; persistence is isolated in `SnapshotWriter`; UI uses `NSOpenPanel` and reports honest progress/status. Existing v4 catalogs receive additive immutable-entry guards idempotently on open without inventing migrations for v1–v3.

## Architecture and File Structure

- `FSD/Provider/FilesystemProvider.swift`: provider contract, descriptors, metadata entries, scan issues, progress, cancellation result, and ADR-009 path identity.
- `FSD/Provider/FilesystemDetector.swift`: mounted-source URL/statfs detection.
- `FSD/Provider/NativeMountedProvider.swift`: FileManager streaming provider.
- `FSD/Catalog/SnapshotWriter.swift`: volume/snapshot/root creation, bounded batches, totals, issues, terminal transition, cancellation token.
- `FSD/Catalog/RecoveryService.swift`: idempotent orphaned-scan recovery.
- `FSD/Scanner/SnapshotScanner.swift`: detector/provider/writer orchestration.
- `FSD/App/FSDApp.swift`: source picker, capture progress/cancel/result UI, startup recovery status.
- `FSD.xcodeproj/xcshareddata/xcschemes/FSD.xcscheme`: shared build and test action.

## Provider Boundary

`FilesystemProvider` exposes a source descriptor, provider version, streaming entry callbacks, scan issues, progress, cooperative cancellation, and terminal enumeration result. It has no SQLite, UI, mutation, classification, or Magika methods. The shape is ready for later `EmbeddedRawProvider` and other adapters without adding them now.

## NativeMountedProvider

Uses `FileManager.enumerator(at:includingPropertiesForKeys:)` with prefetched URL resource keys. It persists relative paths, parent paths, NFC/case-fold keys, item kind, sizes, allocation, dates, extension, content-type identifier, resource identifier, hidden/package/inaccessible flags, and symlink target when available. Package directories are recorded as atomic package entries and descendants are skipped. Symlinks, including broken symlinks, are recorded and `skipDescendants()` is called; their destinations are not traversed. No payload API is used.

## Filesystem Detection

`FilesystemDetector` validates the selected folder, reads URL volume metadata, uses `statfs` for filesystem type, mount path, and read-only state, and records volume identifier, capacity, availability, and case sensitivity when macOS supplies it. The native mounted path is the only provider path implemented in this milestone; raw-device detection and embedded readers remain deferred.

## Path Identity and Normalization

All provider entries use `fsd-normalizer-v1_app-1.0_os-1`. Case-preserving keys use Foundation precomposed canonical mapping. Case-folded keys use POSIX-locale case folding followed by precomposed canonical mapping. The implementation does not claim raw filename-byte preservation. The source-root boundary uses lexical paths with only the macOS `/private` mount alias normalized; symlink destinations are not resolved for entries.

## Scanner Orchestration

`SnapshotScanner` detects the source, creates a scanning snapshot and exactly one root through the writer, streams provider entries into a bounded buffer, flushes batches, stores issues, emits processed-entry progress, and performs a separate terminal transition. Provider failures produce interrupted/failed terminal states; cancellation produces cancelled and never complete.

## SnapshotWriter and Persistence

`SnapshotWriter` creates or refreshes a volume record, allocates a session number, creates the snapshot with provider metadata, inserts one root, and writes entry batches in configurable transactions (default 2,000). Parent IDs are resolved by bounded SQLite lookups rather than retaining the entire tree. Snapshot totals and inaccessible counts are updated by deltas. Scan issues are persisted separately. Completed snapshots reject later entry and issue mutation at both writer and SQLite trigger boundaries. Classification rows remain unused.

## Cancellation and Interruption Safety

`CaptureCancellationToken` is checked during enumeration and owns a finalization lock. Finalization reads the cancellation decision while holding that lock, so cancellation before the terminal commit wins and completion cannot race it. Already committed batches remain evidence in cancelled/interrupted/failed snapshots; the source is never modified.

## Startup Crash Recovery

`RecoveryService` runs after database initialization, finds `scanning` snapshots, records one bounded recovery issue, and transitions them to `interrupted`. It is idempotent, preserves entries, never touches completed snapshots, and does not resume scans. The UI exposes a bounded recovery message.

## Collection Data Layer

The existing snapshot repository listing/read path remains the minimal collection data layer needed by the shell. No Collection UI, offline tree browsing, lazy outline tree, comparison, or export was added.

## Capture UI

The SwiftUI shell now presents `NSOpenPanel` folder selection, selected source, start/cancel controls, processed-entry progress, terminal status, startup catalog/recovery errors, an empty state, and “Metadata only. Content Not Verified.” Compare and Collections remain visibly not implemented.

## Source Read-Only Evidence

The production provider/scanner paths contain no `Data(contentsOf:)`, `String(contentsOf:)`, `FileHandle`, `InputStream`, payload `open/read/pread`, hashing, or source write API. The only `String(contentsOf:)` match in production is `CatalogDatabase` loading the bundled schema resource. Automated tests captured a controlled temporary source, compared pre/post listings, asserted no catalog/index/marker names appeared, and verified symlink and broken-symlink non-traversal. The test suite created no classification rows.

## Automated Tests

The final suite contains 23 XCTest tests: 5 catalog tests, 8 Milestone 2 capture/provider tests, and 10 M1 lifecycle tests. Coverage includes fresh/current schema integrity, provider metadata and package/symlink behavior, path identity, detection, one root and parent links, totals, completed-snapshot immutability, cancellation during enumeration, cancellation/finalization race, recovery idempotence, source listing preservation, and classification-row absence. All 23 passed; 0 failed; 0 skipped.

## Scaling Smoke Test

`testScalingSmokeUsesBoundedWriterBatches` generated 5,000 empty metadata files, captured 5,001 entries including the root with batch size 200, and completed in approximately 1.5 seconds in the final clean run. This is a bounded-memory smoke test, not the final 100k/1M performance gate; peak memory was not measured.

## Build Results

- Xcode: 26.3 (17C529)
- Swift: Apple Swift 6.2.4
- Deployment: macOS 13.0, arm64
- Clean: PASS
- Build: PASS with `CODE_SIGNING_ALLOWED=NO`
- Test: PASS, 23/23 passed, 0 failed, 0 skipped
- Final app: `/tmp/FSD-M2-Clean2/Build/Products/Debug/FSD.app`
- Final executable: `/tmp/FSD-M2-Clean2/Build/Products/Debug/FSD.app/Contents/MacOS/FSD`, Mach-O arm64
- Bundled schema: `/tmp/FSD-M2-Clean2/Build/Products/Debug/FSD.app/Contents/Resources/schema.sql`
- Important warnings: AppIntents metadata skipped because AppIntents is not a dependency; XCTest support frameworks report macOS 14 linkage while the app/test target deploys to macOS 13; no signing was requested.

## Manual Session A Readiness

Manual acceptance was not performed. The exact built app is `/tmp/FSD-M2-Clean2/Build/Products/Debug/FSD.app`. Generate a controlled fixture with:

```sh
manual_fixture=$(mktemp -d /tmp/FSD-ManualA.XXXXXX)
mkdir -p "$manual_fixture/Deep/Branch" "$manual_fixture/Empty Folder" "$manual_fixture/Package.app"
touch "$manual_fixture/Unicode café.txt" "$manual_fixture/Deep/Branch/leaf.dat" "$manual_fixture/Package.app/child.dat"
printf '%s\n' "$manual_fixture"
```

1. Launch the app. Expected: it opens, initializes the local catalog, and shows the capture shell. Evidence: launch screenshot and catalog path. Hard gate: yes.
2. Choose the printed fixture folder and run capture. Expected: one complete metadata snapshot with root/file/folder totals; no content verification claim. Evidence: status/totals screenshot. Hard gate: yes.
3. Compare a pre-capture and post-capture listing of the fixture. Expected: source listing and timestamps are unchanged; no marker/index/database files appear. Evidence: both listings and empty diff. Hard gate: yes.
4. Start a capture of the fixture or a larger controlled folder and cancel while progress is moving. Expected: terminal status is cancelled/interrupted, never complete; app remains usable. Evidence: status screenshot. Hard gate: yes.
5. Relaunch after cancellation. Expected: the cancelled/interrupted record remains non-complete and a prior complete snapshot, if present, remains usable. Evidence: history/status screenshot. Hard gate: yes.
6. Force-quit during an active capture and relaunch. Expected: the orphaned scanning row is reconciled to interrupted, partial evidence remains, and database startup succeeds. Evidence: launch/status screenshot and integrity output. Hard gate: no.

## Files Changed

- `FSD.xcodeproj/project.pbxproj`
- `FSD.xcodeproj/xcshareddata/xcschemes/FSD.xcscheme`
- `FSD/App/FSDApp.swift`
- `FSD/Catalog/CatalogDatabase.swift`
- `FSD/Catalog/RecoveryService.swift`
- `FSD/Catalog/SnapshotWriter.swift`
- `FSD/Provider/FilesystemDetector.swift`
- `FSD/Provider/FilesystemProvider.swift`
- `FSD/Provider/NativeMountedProvider.swift`
- `FSD/Scanner/SnapshotScanner.swift`
- `FSDTests/Milestone2CaptureTests.swift`
- `docs/database/schema.sql`
- `docs/MVP_PLAN.md`
- `docs/PRODUCT_STATE.md`
- `handoffs/FSD_M2_CAPTURE_SAFETY_C_20260804-014316.md`

`docs/database/verify.sql` was re-run unchanged because the two normalization-version fixture corrections were already present from Milestone 1; no unrelated rewrite was made.

## Commands and Tests

- `xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug -derivedDataPath /tmp/FSD-M2-Clean2 clean`
- `xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-M2-Clean2 CODE_SIGNING_ALLOWED=NO build`
- `xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-M2-Clean2 CODE_SIGNING_ALLOWED=NO test`
- Fresh verify: `sqlite3 <temporary>/catalog.sqlite3 < docs/database/schema.sql` followed by `sqlite3 <temporary>/catalog.sqlite3 < docs/database/verify.sql`
- Production safety scan: `rg` deny-list over `FSD/Provider`, `FSD/Scanner`, and related capture code.
- Repository checks: `git status --short` and `git diff --check` were attempted and are blocked because `.git` is absent.

## Results

Fresh catalog verification returned `PRAGMA integrity_check = ok` and no `foreign_key_check` rows at the script checkpoints. `verify.sql` exited 1 because its intentional rejection fixtures are executed as plain SQL; the corrected embedded-raw fixtures reached the intended provider checks, and the provider-combination, partition, foreign-key, scan-issue-source, root, collection, and classification rejection messages were observed. The final clean arm64 build and 23-test suite passed.

## Decisions

- Kept schema version 4 and installed new immutable-entry guards idempotently when opening an existing v4 catalog; no fake v1–v3 migrations were added.
- Used FileManager/URL/statfs for mounted native capture only; raw-device and unmounted filesystem work remains outside this milestone.
- Used lexical root-boundary checks with `/private` alias normalization while deliberately not resolving entry symlinks.
- Kept progress as processed-entry count because the native enumerator does not provide a reliable total without a second traversal.

## Constraints Preserved

No third-party dependencies, network access, telemetry, signing, notarization, DMG, Magika, classification runtime, payload reads, byte sampling, content hashing, source writes, symlink traversal, automatic removable-media scan, raw-device access, filesystem spikes, fixture-image changes, unrelated file deletion, Git initialization, commit, push, or independent audit was performed.

## Known Issues

- Manual Session A and its physical-source acceptance evidence are pending.
- Only the native mounted provider is implemented; embedded raw, FAT/exFAT/NTFS/UDF provider-specific work remains deferred.
- The 5,000-entry test is a development smoke test, not the final 100,000/1,000,000-entry acceptance benchmark.
- Git status/diff evidence is unavailable because the supplied workspace is not a Git repository.

## Exactly One Next Action

Run the Milestone 2 acceptance audit with Manual Session A evidence.

## Resume Context

Start from the final clean artifact at `/tmp/FSD-M2-Clean2/Build/Products/Debug/FSD.app`, read this handoff through `handoffs/CURRENT_HANDOFF.md`, and run only the required Milestone 2 acceptance audit next. Do not treat the successful automated suite as manual acceptance or as an independent audit. After that audit, Milestone 3 is the next implementation milestone: offline history, browsing, lazy large-tree loading, and remaining providers.
