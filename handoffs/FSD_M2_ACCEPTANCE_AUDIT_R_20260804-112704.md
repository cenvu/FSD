# Handoff

## Identity
- Project: FSD — FishSock Differ
- Task: FSD-M2-ACCEPTANCE-AUDIT-0804-05 — Milestone 2 acceptance, safety audit, and Manual Session A
- Case code: FSD_M2_ACCEPTANCE_AUDIT
- Role: R (Reviewer / independent audit)
- Agent / model: Claude Code, Claude Opus 5
- Session ID: f6f4a226-5125-48a7-966e-83a8fbe9a423
- Started: 2026-08-04T10:44+0700 (approx, first tool call)
- Completed: 2026-08-04T11:27:04+0700

## Status

**COMPLETE_WITH_KNOWN_LIMITATIONS.** The technical audit is complete and independently evidenced. Manual Session A was not performed; its hard gates are recorded as NOT PERFORMED at the project owner's explicit direction after two verified attempts.

## Audit Verdict

**APPROVE WITH CONDITIONS. Milestone 3 may begin.**

No rejection-level defect was found. Milestone 2 **acceptance sign-off remains open** until Manual Session A is completed and database-verified (Condition C1).

## Repository State
- Root: `/Users/cenvu/DEV/FSD` (confirmed)
- Branch: n/a
- Commit: n/a
- Git status: `git status --short`: **BLOCKED — NOT A REPOSITORY**; `git diff --check`: **BLOCKED — NOT A REPOSITORY**
- Pre-existing user changes preserved: M1/M2 source (`FSD/`, `FSDTests/`), `FSD.xcodeproj`, all historical Handoffs, spikes, and root scratch artifacts (`temp.db*`, `*.py`, `verify_output.txt`) untouched. The owner's catalog at `~/Library/Application Support/FSD/catalog.sqlite3` was backed up non-destructively before manual testing and was never modified by this audit.

## Objective

Independently verify the Milestone 2 metadata-capture workflow across source read-only safety, metadata-only enumeration, snapshot immutability, path identity, bounded persistence, cancellation/finalization races, interruption and crash recovery, and user-visible behavior; run Manual Session A with the project owner; decide whether Milestone 2 is accepted and Milestone 3 may begin.

## Inputs Read

`handoffs/CURRENT_HANDOFF.md` (M2 Writer Handoff, full). Production source in full: `FSD/Catalog/CatalogDatabase.swift`, `FSD/Catalog/SnapshotWriter.swift`, `FSD/Catalog/RecoveryService.swift`, `FSD/Provider/FilesystemProvider.swift`, `FSD/Provider/FilesystemDetector.swift`, `FSD/Provider/NativeMountedProvider.swift`, `FSD/Scanner/SnapshotScanner.swift`; targeted reads of `FSD/App/FSDApp.swift` and `FSD/Model/SnapshotModels.swift`. `docs/database/schema.sql` (constraint and trigger regions), `docs/PRODUCT_STATE.md`, `docs/MVP_PLAN.md` (M2/M3 boundaries). Not read: full dependency trees, all historical Handoffs, filesystem feasibility campaigns.

## Writer Claims Reviewed

| Writer claim | Audit result |
|---|---|
| Native mounted capture works end to end | **VERIFIED** — 23/23 tests reproduced; one real exFAT volume captured cleanly |
| Enumeration callback-based and bounded | **VERIFIED** — streaming `for case let url as URL in enumerator`, no full-tree array |
| No regular-file payload API used | **VERIFIED** — zero matches in production; only `String(contentsOf:)` on the bundled schema resource |
| No source writes | **VERIFIED** — zero mutation APIs; only `createDirectory` for FSD's own catalog directory |
| Symlinks recorded, not followed | **VERIFIED** — `skipDescendants()` on symlink/package; only `destinationOfSymbolicLink` (readlink, metadata) |
| Packages recorded atomically | **VERIFIED** — `.package` kind, descendants skipped |
| Path normalization follows ADR-009 | **VERIFIED** — NFC precomposed + POSIX case fold, reproduced independently |
| Case sensitivity detected | **VERIFIED** — `volumeSupportsCaseSensitiveNamesKey`, falls back to `.unknown`; exFAT correctly `insensitive` |
| Bounded batches | **VERIFIED** — default 2,000; scaling test uses 200 |
| Exactly one root | **VERIFIED** — schema + writer + catalog inspection |
| Totals and parent links correct | **VERIFIED** — parent resolved by bounded SQL lookup; missing parent throws, never silently reattaches |
| Scan issues persist | **VERIFIED** — separate transaction, independent of entry batches |
| Completed snapshots reject mutation | **VERIFIED** — insert/update/delete/scan-issue/reversion all rejected at SQLite level |
| Cancellation cannot race into completion | **VERIFIED** — decision read inside the finalization lock |
| Startup recovery safe | **VERIFIED** — idempotent, preserves completed snapshots |
| Classification rows absent | **VERIFIED** — 0 rows in every catalog inspected |
| UI supports selection/capture/progress/cancel/status | **VERIFIED** by source; **USER-OBSERVED** for launch and one capture |
| 23/23 automated tests pass | **VERIFIED** — reproduced in a fresh DerivedData |
| 5,001-entry smoke ≈ 1.5 s | **VERIFIED** — 1.513 s in my run |
| Builds as unsigned arm64 macOS app | **VERIFIED** — Mach-O arm64, ad-hoc, no signing prompt |

## Clean Build and Test Reproduction

Independent, new DerivedData at `/tmp/FSD-M2-Audit-DerivedData`; the Writer's `/tmp/FSD-M2-Clean2` was not reused.

- Xcode **26.3** (17C529); Swift **6.2.4** (swiftlang-6.2.4.1.4)
- `clean` → **CLEAN SUCCEEDED**
- `build` (`CODE_SIGNING_ALLOWED=NO`) → **BUILD SUCCEEDED**, exit 0
- `test` → **TEST SUCCEEDED**, exit 0 — **Executed 23 tests, 0 failures (0 unexpected)**, 0 skipped, 1.749 s
  - CatalogDatabaseTests 5, Milestone2CaptureTests 8, SnapshotLifecycleTests 10
- App: `/tmp/FSD-M2-Audit-DerivedData/Build/Products/Debug/FSD.app`
- Binary: `Mach-O 64-bit executable arm64`; ad-hoc identifier `FSD`, no Developer ID
- Bundled schema present at `Contents/Resources/schema.sql` and **byte-identical** to `docs/database/schema.sql`
- Warnings: AppIntents metadata skipped (not a dependency); XCTest frameworks report macOS 14 linkage while the target deploys to macOS 13. Neither is safety-relevant.

## Source Read-Only and Payload-Read Audit

Exhaustive grep across all production `FSD/`:

- Payload reads (`Data(contentsOf:)`, `String(contentsOf:)`, `FileHandle`, `InputStream`, `mmap`, `pread`, `contentsOfFile`): **one match only** — `CatalogDatabase.swift:240`, `String(contentsOf: schemaURL)`, loading the bundled schema resource. Not a source path.
- Hashing (`CryptoKit`, `CommonCrypto`, SHA/MD5/xxHash): **NONE**.
- FileManager mutation (`removeItem`, `moveItem`, `copyItem`, `createFile`, `replaceItem`, `linkItem`, `trashItem`, `setAttributes`, `setResourceValues`, `setxattr`, `removexattr`): **NONE**.
- `createDirectory`: **one match** — `CatalogDatabase.swift:64`, creating FSD's own Application Support directory. Never on the source.
- Raw syscalls (`open(`, `read(`, `O_RDONLY`, `fopen`): **NONE**. `lstat`/`statfs` only (metadata).
- Magika / classification: **NONE**.

The only file-content read in the entire production target is FSD's own bundled schema. **No regular-file payload read and no source mutation exists.** VERIFIED.

## Provider and Boundary Audit

- **Streaming:** enumerator consumed lazily; entries buffered only to `batchSize` then flushed. No complete-tree retention. VERIFIED.
- **Resource keys:** only the 10 metadata keys are prefetched. VERIFIED.
- **Symlinks:** `.symlink` kind set before directory/package checks, `skipDescendants()` called, destination read via `destinationOfSymbolicLink` (readlink) but never traversed. Broken symlinks handled (target read returns nil via `try?`). Finder aliases are not resolved — no alias-resolution API present. VERIFIED.
- **Root boundary — classified separately from symlink handling.** `isWithinRoot` appends a trailing `/` before prefix comparison, so it is component-aware in effect. Independently probed with a re-implementation of the exact production helpers across 8 cases — **all 8 pass**, including `/tmp/a` vs `/tmp/abc` prefix confusion (correctly excluded), `/private` alias equivalence in both directions (correctly included), sibling paths, and `..` escape (correctly excluded after standardization). The requirement for component-aware rather than raw-prefix comparison is **satisfied**. VERIFIED.
- **Mount boundary — classified separately.** No `st_dev` check exists anywhere. Empirically probed with a generated 10 MB HFS+ image mounted **below** a selected root: `FileManager.enumerator(options: [])` recorded the mount point as a directory but enumerated **zero entries below it**, stable across two runs, while `find` traversed 7. Behaviour is therefore currently **safe**, but it is emergent Foundation behaviour rather than an FSD guard, and the mount point is recorded as an ordinary empty directory with no scan issue. → Condition C3.
- **Cancellation interval:** checked once per enumerated entry — bounded and prompt. VERIFIED.
- **Result fidelity:** `EnumerationResult` distinguishes processed count, issue count and cancellation; provider errors are typed. VERIFIED.

## Unicode and Path Identity Audit

Reproduced the exact `PathIdentity` algorithm independently:

- Normalization identifier `fsd-normalizer-v1_app-1.0_os-1`, applied uniformly. VERIFIED.
- Case-preserving key = `precomposedStringWithCanonicalMapping`; case-folded key = POSIX-locale `.caseInsensitive` fold then precomposed. Matches ADR-009. VERIFIED.
- NFC/NFD collapse under both keys (Swift `String` is canonical-equivalence-based). Golden cases behave correctly: `straße`/`STRASSE` → `strasse`; Greek final/medial sigma → `σίσυφοσ`; `日本語` unchanged.
- **Collision behaviour tested on a real case-sensitive APFS volume** (generated 10 MB image): `Report.txt` and `REPORT.TXT` coexist, producing **distinct** `relative_path` and **identical** `case_folded_path`. The schema's only uniqueness constraint on entries is `UNIQUE(snapshot_id, relative_path)` — there is no unique index on the folded key — so both rows persist distinctly and the fold collision is correctly deferred to ADR-010 comparison-time handling in Milestone 4. **No silent overwrite, no aliasing, no capture failure.**
- The NFC/NFD duplicate-path hazard is **not reachable on APFS**: writing both forms produced a single file, because APFS is normalization-insensitive even when case-sensitive. It remains a future concern for `EmbeddedRawProvider` on ext filesystems, already tracked as libfsext Condition A.
- No claim of raw filename-byte preservation appears anywhere in the implementation. VERIFIED.

**No silent selected-key collision exists.** VERIFIED.

## Schema Compatibility Audit

**Decision: ACCEPTABLE WITH REQUIRED PRE-M3 CORRECTION.**

1. **Objects changed in M2:** four triggers — `trg_completed_entries_insert_guard`, `..._update_guard`, `..._delete_guard`, `trg_completed_scan_issues_insert_guard`.
2. **Did `schema.sql` change while the version stayed 4?** **Yes.** File mtime moved from `Aug 3 18:46` (state at the previous audit) to `Aug 4 01:24`, while `INSERT OR IGNORE INTO schema_migrations VALUES (4, …)` is unchanged.
3. **Does the app execute DDL on opening an existing v4 catalog?** **Yes** — `bootstrapIfNeeded` calls `installCurrentSchemaGuards()` unconditionally on every open of a version-4 catalog.
4. **Can two catalogs both reporting version 4 differ materially?** **Yes — independently reproduced.** A v4 catalog without the guards accepted an entry injected into a **completed** snapshot (entry count went 1 → 2). The same operation against a post-M2 v4 catalog is rejected with `Cannot insert entries into a completed snapshot`. Version 4 no longer identifies a single schema state.
5. **Partial installation possible?** **Yes.** `installCurrentSchemaGuards` runs four `CREATE TRIGGER` statements via `sqlite3_exec` with **no enclosing transaction**; a mid-script failure leaves earlier triggers committed. Self-heals on the next open via `IF NOT EXISTS`, and the failed open aborts, so exposure is bounded.
6. **Can the runtime distinguish pre-M2 v4 from post-M2 v4?** **No.** Both report `MAX(version) = 4`; only `sqlite_master` introspection would reveal the difference, which the code does not perform.
7. **Do fresh and existing catalogs enforce identical rules?** Only *after* an open by M2 code. Confirmed on the owner's real catalog (created 01:00, before the schema change): it now carries all four guards, proving convergence occurred at open.
8. **Conflict with the migration/version contract?** Yes in principle — `schema.sql`'s own header states that a version number "names the cumulative state after this wave", and two different cumulative states now share the name 4.
9. **Bump or explicit migration required before Milestone 3?** **Yes** — carried as Condition C2.

Not treated as a blocking defect because the drift is **additive, convergent and strictly safety-increasing**: the guards only ever add restrictions, every v4 catalog receives them before any capture can run under M2 code, and no user data can be corrupted or lost by the mechanism. Schema was **not** modified by this audit.

## Snapshot Immutability Audit

Verified at the SQLite boundary against a fresh post-M2 catalog — every one rejected:

| Attempt on a completed snapshot | Result |
|---|---|
| INSERT entry | `Cannot insert entries into a completed snapshot` |
| UPDATE entry | `Cannot update entries in a completed snapshot` |
| DELETE entry | `Cannot delete entries from a completed snapshot` |
| INSERT scan issue | `Cannot add scan issues to a completed snapshot` |
| Revert `complete` → `scanning` | `Cannot transition out of a terminal status` |

Entry count remained 1 throughout. Exactly one root preserved. Classification data lives only in `entry_classifications`, which no snapshot, entry or comparison object references — enrichment separation intact, 0 rows everywhere.

At the Swift boundary, `SnapshotWriteSession.persist` re-reads status inside each batch transaction and throws `snapshotNotScanning` if the snapshot is no longer scanning; `finish` refuses a second terminal transition.

**One real finding — Condition C4.** `SnapshotWriter.ensureVolume` performs `UPDATE volumes SET display_name, filesystem_type, total_capacity_bytes, last_seen_at …` on **every** capture of a known volume. A later capture therefore changes volume-level facts that are displayed alongside an older snapshot. The immutable snapshot columns themselves (`scan_root_name`, `mount_path_at_capture`, `filesystem_variant`, `source_case_sensitivity`, `normalization_version`, totals) are untouched, and `volumes` is by design a current-state registry with `first_seen_at`/`last_seen_at`. This is therefore **not** historical snapshot mutation and not rejection-level, but it is a truthfulness gap worth an explicit decision.

## Batched Persistence Audit

- Batch size bounded (default 2,000; configurable; `max(1, …)`). Scanner flushes at `writer.batchSize`. VERIFIED.
- Writer retains only `pending` up to one batch — never the whole tree. VERIFIED.
- Transactions bounded to one batch each; `BEGIN IMMEDIATE` used. VERIFIED.
- Parent IDs resolved by indexed lookup on `(snapshot_id, relative_path)`; a missing parent throws `parentMissing` and **aborts the capture** rather than attaching to a wrong or null parent. Children therefore cannot silently attach to the wrong parent. VERIFIED.
- **Parent-before-child ordering is assumed** (depth-first pre-order from `FileManager`). The assumption is **not** validated up front, but it is **safely handled**: violation produces a loud typed failure, not corruption. Acceptable; noted.
- Duplicate `relative_path` rejected by `UNIQUE(snapshot_id, relative_path)` — loud, not silent.
- Totals updated by delta per entry inside the same transaction as the insert, so committed rows and totals move together.
- Scan issues persist in their own transaction, independent of entry batches; the scanner flushes pending entries first so an issue's `entry_id` can resolve.
- An interrupted batch cannot yield a false `complete`: `finish` re-checks status and the terminal transition is its own transaction guarded by `current == .scanning`.
- Database errors propagate to a terminal `failed`/`interrupted` state via the scanner's catch arms.

## Cancellation and Finalization Audit

The lock protocol and the database transaction were classified **together**, as required.

`CaptureCancellationToken` wraps an `NSLock`. `finish()` executes entirely inside `withFinalizationLock`, reading the cancellation flag **inside** the lock and choosing `.cancelled` over the preferred status when set. Consequences:

- Cancellation before enumeration → provider returns `wasCancelled`, scanner finishes `.cancelled`. VERIFIED (test `testCancellationDuringEnumerationNeverCompletes`).
- Cancellation during enumeration → same path, already-committed batches retained as evidence. VERIFIED.
- Cancellation during batch persistence → next `isCancelled()` check ends enumeration; partial batches already committed.
- **Cancellation immediately before finalization** → the scanner's pre-check at line 101 may pass, but `finish` re-reads the flag under the lock, so `.complete` is overridden to `.cancelled`. This is the critical invariant and it **holds**. VERIFIED (test `testCancellationWinsFinalizationRace`).
- Cancellation while finalization owns the lock → `cancel()` blocks until finalization completes, then the snapshot is already terminal; no second transition occurs.
- Cancellation after completion commits → `isFinished` guard throws `terminalTransitionRejected`; a completed snapshot **cannot** become cancelled or interrupted.
- Provider/database error concurrent with cancellation → scanner catch arms call `finish` with `.cancelled` when the token is set, otherwise `.failed`/`.interrupted`.
- **Deadlock analysis:** nothing reachable inside `withFinalizationLock` (`flush` → `persist` → `currentStatus`/`insertEntry`/`updateTotals`) re-enters the token, and `NSLock` non-recursion is therefore not tripped. In the catch arms, `token.isCancelled` is evaluated as an argument *before* `finish` acquires the lock. **No deadlock path found.**

**Exactly one terminal outcome wins; cancellation can never produce `complete`.** VERIFIED.

## Startup Recovery Audit

`RecoveryService.recoverOrphanedScans` selects all `scanning` snapshots, and per snapshot, inside a transaction, re-checks the status, inserts one bounded recovery `scan_issue` (guarded against duplication by message match), then updates to `interrupted` with a `WHERE … AND status = 'scanning'` guard.

- One or many orphans handled uniformly (ordered loop). VERIFIED by inspection.
- Repeated recovery is idempotent — status guard plus issue-existence check. VERIFIED (test `testRecoveryIsIdempotentAndPreservesCompletedSnapshots`).
- Completed, cancelled, interrupted and failed snapshots are never touched — the query matches only `scanning`. VERIFIED.
- Partial entries and issues preserved; recovery never deletes. VERIFIED.
- Foreign-key integrity after recovery: `integrity_check` = `ok`, `foreign_key_check` clean on the owner's real catalog.
- New captures remain possible afterwards (no lock or flag retained).

**Condition C5 — multi-process hazard.** There is no process-ownership check. A second FSD instance launched while the first is scanning would mark the live scan `interrupted`; the running capture's next batch then fails with `snapshotNotScanning` and terminalizes. This degrades **safely** — no corruption, no data loss — but the single-process assumption is neither enforced nor documented. Cross-process infrastructure is **not** required; documentation or a single-instance guard is.

## UI Truthfulness Audit

- Folder selection uses `NSOpenPanel` with `canChooseDirectories = true`, `allowsMultipleSelection = false`. VERIFIED.
- No automatic removable-media scan — no `NSWorkspace` mount observation exists in M2. VERIFIED.
- Capture status derives from the persisted `SnapshotRecord` read back after finalization, not from in-memory optimism. VERIFIED.
- Terminal states distinguishable: `complete` / `completeWithWarnings` mapped separately, plus interrupted/cancelled/failed via `status.rawValue`. VERIFIED.
- Startup recovery message surfaced (`recoveryMessage`). VERIFIED by source; **USER-OBSERVED** present after force-quit is NOT corroborated (see Manual Session A).
- **"Metadata only. Content Not Verified."** present in the capture pane. VERIFIED by source; **USER-OBSERVED PASS**.
- Compare and Collections are explicitly labelled "not implemented" in both sidebar and detail. VERIFIED.
- Nothing in the UI implies content verification. VERIFIED.
- **UI state does not retain the entry tree** — the view model publishes only `[SnapshotRecord]`; no entry array exists. VERIFIED. (`listSnapshots()` is unbounded, but that is per snapshot, not per entry — negligible at MVP scale.)
- Errors bounded: `startupError` and typed `LocalizedError` descriptions.

## Scaling Smoke Audit

From my own test run, not the Writer's:

- Fixture: 5,000 generated empty files; persisted **5,001** entries including the root.
- Batch size 200 (test-configured), proving the bounded-batch path rather than the 2,000 default.
- Wall-clock **1.513 s** for `testScalingSmokeUsesBoundedWriterBatches`; whole M2 suite 1.624 s.
- No complete-tree collection retained (writer holds ≤ one batch; scanner holds ≤ one buffer).
- UI state does not grow per entry — only a progress counter.
- Memory not separately measured. Not the final performance gate; the 100k/1M classes remain Milestone 5.

Additionally, a real mounted **exFAT** volume (`/Volumes/A006C84S`, 679 GB logical, 45 entries) captured to `complete` with 0 warnings, 0 inaccessible items, exactly 1 root, 0 classification rows, `integrity_check` = `ok`, `foreign_key_check` clean, `source_case_sensitivity = insensitive`, `filesystem_variant = exfat`, `normalization_version = fsd-normalizer-v1_app-1.0_os-1`.

## Manual Session A

Environment prepared: audit build at `/tmp/FSD-M2-Audit-DerivedData/…/FSD.app`; small fixture `/tmp/FSD-M2-Manual-Small-2In8XH` (15 entries — nested folders, empty folder, hidden file, `Package.rtfd`, Unicode name, valid symlink, broken symlink, and `escape_link_to_etc → /etc`); large fixture `/tmp/FSD-M2-Manual-Large-5pGGVq` (8,022 entries); evidence dir `/tmp/FSD-M2-Manual-Evidence-wcvlyZ` holding pre-capture sorted path listing, per-file test-only SHA-256, and `stat` baselines.

**Isolated-catalog requirement could not be met (Condition C6).** macOS resolves `NSHomeDirectory()` from the user record, not `$HOME` — independently probed — and FSD has no catalog-path override, so the app always uses `~/Library/Application Support/FSD`. The owner's catalog was therefore backed up non-destructively to the evidence directory (1 snapshot preserved) before any manual step.

- **A1 Launch** — **USER-OBSERVED PASS.** Window opened, no signing or Developer Account prompt, capture shell visible, no startup error. Consistent with agent evidence (app bundle intact, ad-hoc signed, a capture recorded at 11:05).
- **A2 Controlled capture** — **NOT PERFORMED.** The owner instead captured a real mounted exFAT volume (`/Volumes/A006C84S`), which the audit did not request and for which no baseline exists. That capture is **AGENT-VERIFIED clean** (see Scaling Smoke) and reported by the owner as `Complete` with "Content Not Verified" visible (**USER-OBSERVED**), but it cannot satisfy A2's controlled-fixture requirement.
- **A3 Source unchanged** — **NOT PERFORMED.** Requires A2's controlled capture; no baseline exists for the exFAT volume, and it is a real removable device outside the audit's controlled-fixture rule.
- **A4 Cancellation** — **NOT PERFORMED.**
- **A5 Relaunch after cancellation** — **NOT PERFORMED / INCONCLUSIVE.** The catalog `-shm` was touched at 11:18, indicating the app was opened, but there is no cancelled snapshot to relaunch against.
- **A6 Force-quit recovery** — **NOT PERFORMED.**

**Basis for recording these as NOT PERFORMED.** The owner twice reported A2b/A4/A5/A6 as passing. Three independent checks contradict this, all consistent:

1. The catalog contains exactly one snapshot (the exFAT card); `MAX(entries.id) = 45 = COUNT(*)`, and `session_number` has no gaps, so no snapshot was ever created and deleted.
2. `scan_issues` is **empty** — `RecoveryService` writes a row whenever it recovers, so A6 demonstrably never ran.
3. The prepared fixtures' access time is **`10:57:26`**, the moment of creation, unchanged at 11:26 — FSD never enumerated them.

A system-wide search confirmed only one FSD catalog exists. After presenting this evidence, the project owner directed that the gates be recorded as NOT PERFORMED (Condition C1). **No hard gate FAILED; they were not exercised.**

**Evidence separation:** A1 and the exFAT capture's UI wording are USER-OBSERVED. The exFAT capture's database properties are AGENT-VERIFIED. A2b/A3/A4/A6 are NOT PERFORMED — no evidence of any kind.

## Findings by Severity

**Rejection-level:** none.

**Medium**

- **M-1 (C2)** — Schema drift inside recorded version 4; two catalogs reporting v4 can enforce different immutability rules. Reproduced.
- **M-2 (C4)** — `ensureVolume` mutates shared volume facts on every capture, altering volume-level data shown beside older snapshots.

**Low**

- **L-1 (C3)** — Nested-mount non-descent is emergent Foundation behaviour, not an FSD guard; mount point recorded as an empty directory with no scan issue.
- **L-2 (C5)** — Single-process assumption in `RecoveryService` neither enforced nor documented; fails safely.
- **L-3 (C6)** — No catalog-path override; blocked isolated manual testing.
- **L-4** — `installCurrentSchemaGuards` runs four DDL statements outside a transaction; partial installation possible, self-healing.
- **L-5** — Parent-before-child enumeration order assumed, not validated; violation aborts loudly rather than corrupting.

**Process**

- **P-1 (C1)** — Manual Session A hard gates not performed.

## Conditions

| # | Condition | Deadline |
|---|---|---|
| **C1** | Perform Manual Session A A2b/A3/A4/A6 against controlled fixtures and verify each in the catalog | **Blocks Milestone 2 acceptance sign-off. Does not block Milestone 3 start.** |
| **C2** | Resolve schema drift in version 4 — bump the version or add explicit migration/state detection | Before Milestone 3 ships further catalog changes |
| **C3** | Document reliance on non-descent into nested mounts; add a regression test; consider a scan issue at mount points | Milestone 3 |
| **C4** | Decide whether volume facts must be captured per snapshot rather than mutated on the shared row | Milestone 3 |
| **C5** | Document or enforce single-instance operation | Milestone 3 |
| **C6** | Add a debug/test catalog-path override | Milestone 3 |

## Files Changed

- `docs/PRODUCT_STATE.md` — audit result, manual-session status, six open conditions, next milestone
- `docs/MVP_PLAN.md` — Milestone 2 acceptance-audit result and authorization for Milestone 3
- `handoffs/FSD_M2_ACCEPTANCE_AUDIT_R_20260804-112704.md` — new (this file)
- `handoffs/CURRENT_HANDOFF.md` — overwritten with this Handoff

**Not modified:** all production Swift, `FSD.xcodeproj`, all tests, `docs/database/schema.sql`, `docs/database/verify.sql`, spikes, fixtures, historical Handoffs, and the owner's catalog.

## Commands and Tests

- `git status --short` / `git diff --check` → **BLOCKED — NOT A REPOSITORY**
- `xcodebuild clean` / `build` / `test` with `-derivedDataPath /tmp/FSD-M2-Audit-DerivedData`, `CODE_SIGNING_ALLOWED=NO` → CLEAN/BUILD/TEST SUCCEEDED, 23/23
- `file` on the product binary → Mach-O arm64; `codesign -dv` → ad-hoc; bundled schema diffed byte-identical
- Production greps for payload-read, hashing, mutation, syscall and Magika APIs
- Fresh `schema.sql` apply; post-M2 immutability matrix (5 rejections); simulated pre-M2 v4 injection (accepted → drift proven)
- Boundary probe: 8 root/prefix/`/private`/dot-dot cases, all pass
- Nested-mount probe: generated 10 MB HFS+ image mounted under a root, 2 runs, no descent
- Case-sensitivity probe: generated case-sensitive APFS image, `Report.txt`/`REPORT.TXT`/NFC/NFD collision analysis
- `NSHomeDirectory()` isolation probe
- Owner catalog: `integrity_check`, `foreign_key_check`, snapshot/root/entry/classification counts, `scan_issues`, session-number gap analysis, WAL checkpoint, fixture `atime` analysis, system-wide catalog search
- Non-destructive `.backup` of the owner's catalog

All generated disk images were detached and removed. Not run: filesystem feasibility campaigns, Magika, source payload reads, dependency rebuilds.

## Results

Clean build and full suite reproduced independently (23/23, 0 failed, 0 skipped). Source read-only safety, metadata-only enumeration, boundary containment, path identity, snapshot immutability, bounded persistence, cancellation-race safety and startup recovery all **VERIFIED** with no rejection-level defect. Schema compatibility is **ACCEPTABLE WITH REQUIRED PRE-M3 CORRECTION**. Manual Session A hard gates are **NOT PERFORMED**. Verdict **APPROVE WITH CONDITIONS**; Milestone 3 authorized; Milestone 2 acceptance sign-off open pending C1.

## Constraints Preserved

No production Swift, Xcode project, test, schema, migration, spike or fixture modified. No Git init/commit/push, no GitHub access. No real removable media accessed *by the audit* — the exFAT capture was the owner's own action; the audit used only generated `/tmp` fixtures and generated disk images, all detached and cleaned up. No payload read through production code; test-only hashes limited to controlled fixtures. No Magika installed, executed, or added. No classification runtime added; classification rows remain 0. No DMG signed, notarized or packaged. No checksum files. Exactly one Handoff. Milestone 3 not begun. The owner's catalog was backed up and never modified.

## Known Issues

1. **Manual Session A hard gates unperformed (C1)** — A2b/A3/A4/A6 have no evidence; recorded at the owner's direction after two verified attempts.
2. **A3 cannot be satisfied by the exFAT capture** — uncontrolled source, no pre-capture baseline, real removable media.
3. **Schema drift within version 4 (C2)** — reproduced; additive and convergent, but version no longer identifies schema state.
4. **Isolated manual-test catalog unachievable (C6)** — forced manual testing to share the owner's real catalog.
5. Conditions C3, C4, C5 and low findings L-4, L-5 remain open as recorded.
6. All documentation edits in this run are reviewer-authored and have **not** themselves been independently reviewed.

## Exactly One Next Action

**Implement Milestone 3 — Offline history, browsing, lazy large-tree loading, and the remaining providers** (`MVP_PLAN.md`), carrying conditions C2–C6 into that milestone's scope, and completing Manual Session A (C1) to close Milestone 2 acceptance sign-off.

## Resume Context

Milestone 2 is technically approved; Milestone 3 may begin immediately. The authoritative condition list is `docs/PRODUCT_STATE.md` § Open conditions from the Milestone 2 audit.

C2 is the one to handle early: `CatalogDatabase.installCurrentSchemaGuards()` (`FSD/Catalog/CatalogDatabase.swift:271`) executes DDL on every open of a v4 catalog, and `docs/database/schema.sql` gained four triggers without a version bump. Decide between bumping to version 5 with an explicit migration step, or recording a schema-state fingerprint alongside the version.

Manual Session A can be re-run at any time: the fixtures, baselines and catalog backup remain under `/tmp/FSD-M2-Manual-Small-2In8XH`, `/tmp/FSD-M2-Manual-Large-5pGGVq` and `/tmp/FSD-M2-Manual-Evidence-wcvlyZ`, and the audit build at `/tmp/FSD-M2-Audit-DerivedData/Build/Products/Debug/FSD.app`. Reaching `/tmp` from the open panel requires ⌘⇧G. Note that `/tmp` contents are cleared periodically by macOS; regenerate the fixtures if they are gone.
