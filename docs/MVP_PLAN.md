# MVP Implementation Plan

## Status

This is the single canonical implementation sequence for FSD. Restructured 2026-08-04 by independent audit (`handoffs/FSD_MVP_DEEP_AUDIT_R_20260804-003039.md`) from eight small phases into **five large milestones**, so that one Writer can implement a coherent slice without repeatedly reopening the same architecture.

**Current status (authority reconciliation 2026-10-03; accepted evidence through 2026-08-07): Magika runtime design COMPLETE; runtime implementation NOT STARTED / INACTIVE.** Milestones 1–5 technical core is closed with known limitations; Phase 1.5
nullable enrichment preparation is implemented and its focused independent
boundary audit is closed with `APPROVE WITH CONDITIONS` (`handoffs/FSD_P15_MAGIKA_NULLABLE_ENRICHMENT_AUDIT_R_20260807-142313.md`). KI-024
is fixed by an additive `comparison_results(parent_result_id)` index, one
explicit transactional v7→v8 migration, complete ExpectedState validation and
one-million-result explicit/automatic disposal regressions. Release timings
are 9.930 s explicit disposal and 10.018 s canonical live-workspace close,
both below the 120-second threshold. No other Milestone 5 gate failed. Manual
acceptance remains **NOT PERFORMED — DEFERRED BY OWNER**; MVP approval is not
claimed. The M5 focused schema-v8/disposal re-audit is **CLOSED — APPROVE WITH
CONDITIONS** (`handoffs/FSD_M5_SCHEMA_V8_DISPOSAL_REAUDIT_A_20260805-223211.md`).
Schema remains **v8**. The accepted runtime design
(`handoffs/FSD_P15_MAGIKA_RUNTIME_DESIGN_A_20260807-155630.md`, ADR-032)
requires **SCHEMA CHANGE REQUIRED BEFORE RUNTIME**, under separate
authorization. This reconciliation does not authorize schema or runtime work.

[`FILESYSTEM_FEASIBILITY_PLAN.md`](FILESYSTEM_FEASIBILITY_PLAN.md) supplies feasibility methodology and current per-filesystem status; [`SNAPSHOT_COLLECTIONS.md`](SNAPSHOT_COLLECTIONS.md) supplies the full Collection specification; [`TEST_PLAN.md`](TEST_PLAN.md) §8 supplies the consolidated manual acceptance sessions. None is duplicated here.

## Historical foundation entry gates (2026-08-04)

The milestone requirements below retain their original planning context.
Current closure notes supersede historical pending and then-next actions.
The foundation authorization in this section is not a current runtime authorization.

Both historical gates in front of Phase 0 have been resolved against actual evidence:

1. **R0 lineage — CLOSED.** Final independent audit returned APPROVE (`handoffs/FSD_PLAN_GATE_FINAL_REAUDIT_A_20260725-154907.md`). Prior text in this file claiming R0 "remains open ... a fresh audit APPROVE is required" was stale and is superseded.
2. **Filesystem feasibility — no longer a blanket gate.** ext2/3/4 and native APFS/HFS+ feasibility passed. FAT/exFAT/NTFS/UDF are untested but are **provider-specific**, not foundational: they are gated at Milestone 3, not in front of Milestone 1.

**Two carried-forward defects must be closed inside Milestone 1** (they block trustworthy snapshot completion, not project setup):

**Closure amendment:** both defects below were closed by Milestone 1
(`handoffs/FSD_M1_FOUNDATION_C_20260804-010259.md`); the original entry
requirements are retained as history, not open blockers.

- **FSD-FINAL-REAUDIT-001** — the `normalization_version` completion guard is a two-clause literal blacklist (`= '' OR LIKE '%UNRECORDED_PLACEHOLDER%'`), not a positive format check. Re-verified 2026-08-04: `'   '`, `'UNKNOWN'`, `'PLACEHOLDER'`, `'NOT_SET'`, `'PENDING'` all reach `complete`. Replace with a positive check against ADR-009's documented shape `fsd-normalizer-<algorithm-version>_app-<implementation-version>_os-<ProductBuildVersion>`.
- **FSD-FINAL-REAUDIT-002** — `database/verify.sql` has two `INSERT INTO snapshots` statements (the embedded-raw disk-image and raw-physical-device fixtures) that omit `normalization_version`, so they fail on an incidental `NOT NULL` violation before the provider constraints they claim to test are ever exercised. Re-confirmed still present 2026-08-04.

## Milestone 1 — Application, catalog, and snapshot foundation

- **Outcome:** an FSD application that launches on Apple Silicon, creates its catalog database at schema version 4, and can create and terminalize a snapshot row through a trustworthy lifecycle — with no scanner yet.
- **Major components:** Xcode project (macOS 13+, arm64, Swift 5.9+); `CatalogDatabase` SQLite wrapper with per-connection `PRAGMA foreign_keys = ON` startup assertion; migration runner against `database/schema.sql`; snapshot lifecycle model (`scanning` → `complete` / `complete_with_warnings` / `interrupted` / `cancelled` / `failed`); normalization identity (ADR-009); logging and error model; SwiftUI navigation shell; Application Support directory layout.
- **Files/modules likely involved:** `FSD.xcodeproj`, `FSD/App/`, `FSD/Catalog/CatalogDatabase.swift`, `FSD/Catalog/Migrations.swift`, `FSD/Model/Snapshot*.swift`, `FSD/Model/Normalization.swift`, `FSDUnitTests/`, `docs/database/schema.sql`, `docs/database/verify.sql`.
- **Dependencies:** none. This milestone is unblocked today.
- **Required fixes folded in:** FSD-FINAL-REAUDIT-001 and FSD-FINAL-REAUDIT-002 above.
- **Targeted automated validation:** fresh schema apply + `PRAGMA integrity_check` + `PRAGMA foreign_key_check` as an Xcode test target; `verify.sql` run clean with each intended rejection firing for its intended reason; positive-format normalization fixtures (the five fake values above must now be rejected at completion); snapshot lifecycle fixtures (terminal reversion rejected, zero-root completion rejected, cross-snapshot parent rejected); startup assertion that `foreign_keys` is ON.
- **Manual test requirement:** none. Nothing user-facing exists yet to test by hand.
- **Independent audit required:** **NO** — but see Milestone 2, which audits this milestone's immutability work together with capture safety.
- **Explicitly deferred:** any scanner, any provider, any browsing, any comparison, any UI beyond a navigation shell, all Collection UI.

## Milestone 2 — Metadata capture, interruption safety, and the provider boundary

- **Outcome:** the user can point FSD at a folder or mounted volume and get an immutable, complete metadata snapshot — and an interrupted capture is provably never presented as complete.
- **Major components:** `FilesystemProvider` protocol and `NativeMountedProvider` over `FileManager`/`URL` with prefetched resource keys (`ARCHITECTURE.md` §4); `FilesystemDetector` with the deterministic fallback rule (embedded-raw branch stubbed to "unsupported"); `SnapshotScanner`; `SnapshotWriter` with batched transactional inserts; progress and cancellation; interruption and crash recovery (stale `scanning` snapshots reconciled at launch); Collection **data layer** (`collections`, `source_collection_defaults`, `snapshots.collection_id`/`display_name`/`user_note`) without its UI; `NSOpenPanel` source selection.
- **Files/modules likely involved:** `FSD/Providers/`, `FSD/Scanner/`, `FSD/Catalog/SnapshotWriter.swift`, `FSD/Catalog/RecoveryService.swift`, `FSD/Model/Collection*.swift`, `FSDIntegrationTests/`.
- **Dependencies:** Milestone 1.
- **Targeted automated validation:** scan a generated 100,000-entry tree without blocking the UI; assert the scanner opens zero file payloads (no `read`/`open` on regular files outside metadata APIs); kill/interrupt mid-scan and assert the snapshot lands `interrupted` and the previous complete snapshot remains default; batch-insert throughput; the full Collection test list in `TEST_PLAN.md` §7; source-tree byte-comparison before and after capture.
- **Manual test requirement:** **YES — Manual Session A** (`TEST_PLAN.md` §8). This is the first point a human can meaningfully exercise FSD end to end.
- **Independent audit required:** **YES.** This milestone crosses three foundational risk boundaries at once: source read-only safety, snapshot immutability, and interruption/crash recovery.
- **Explicitly deferred:** `EmbeddedRawProvider` and all raw-device access; browsing; comparison; export; Collection UI; automatic mount-triggered capture.

**Milestone 2 implementation status (2026-08-04): COMPLETE_WITH_KNOWN_LIMITATIONS.** The native mounted provider, mounted-source detection, streaming metadata scanner, bounded batch writer, atomic terminal lifecycle, cancellation, startup recovery, and minimal capture UI are implemented. Embedded raw and remaining filesystem providers, offline browsing, comparison, export, and Magika runtime remain deferred.

**Milestone 2 acceptance audit (2026-08-04): APPROVE WITH CONDITIONS** — `handoffs/FSD_M2_ACCEPTANCE_AUDIT_R_20260804-112704.md`. Clean build and 23/23 tests independently reproduced. No rejection-level defect: no payload read, no source mutation, no boundary escape, no silent identity collision, immutability enforced, cancellation cannot reach `complete`, recovery safe. **Milestone 3 is authorized to begin.** C1 — Manual Session A (A2b/A3/A4/A6) remains **NOT PERFORMED — DEFERRED BY OWNER**; C2–C6 are technically closed and recorded in `PRODUCT_STATE.md` § Milestone 2 audit conditions.

## Milestone 3 — Offline history, browsing, large-tree lazy loading, and the remaining providers

- **Outcome:** a captured snapshot stays fully browsable and searchable after the source is ejected, an approximately 100,000-entry tree navigates without eager loading, and the remaining native filesystems are proven. The million-entry class is a later Milestone 5 gate.
- **Status (2026-08-04): COMPLETE_WITH_KNOWN_LIMITATIONS.** See the implementation note at the end of this section.
- **Major components:** volume/snapshot sidebar including the Collections section; lazy `NSOutlineView` tree backed by bounded SQLite queries; summary inspector; search by name/path extended to Collection, display name, source, capture date, filesystem, status; offline state labels; capture-organization sheet UI wired to Milestone 2's data layer; rename/move/note controls; JSON snapshot export.
- **Filesystem work folded in here:** feasibility + provider support for **FAT16, FAT32, exFAT, NTFS read-only, UDF** (disk images first, per `FILESYSTEM_FEASIBILITY_PLAN.md` §1). This is the correct home for it — it is provider-specific and was never a foundation blocker.
- **Files/modules likely involved:** `FSD/Browser/`, `FSD/UI/Sidebar/`, `FSD/UI/Inspector/`, `FSD/Search/`, `FSD/Export/JSONExporter.swift`, `FSD/Providers/` (matrix completion).
- **Dependencies:** Milestone 2.
- **Targeted automated validation:** browse a snapshot with the source path absent and assert no blocking filesystem access; assert expanding one branch issues bounded queries and never materializes the full tree; approximately 100,000-entry fixture memory ceiling; per-filesystem fixture enumeration against ground truth for the newly-covered filesystems; JSON export schema validation. The 1,000,000-entry large-catalog class is the Milestone 5 acceptance gate.
- **Manual test requirement:** folded into Manual Session B (final acceptance). No separate session.
- **Independent audit required:** **NO**, unless the FAT/NTFS/UDF work forces a change to the provider contract or to snapshot immutability — in which case it inherits Milestone 2's boundary.
- **Explicitly deferred:** comparison; `EmbeddedRawProvider` production integration; physical raw devices; HTML export.

**Milestone 3 implementation status (2026-08-04): COMPLETE_WITH_KNOWN_LIMITATIONS; closeout validation complete.**

Delivered: schema version 5 and the project's first real transactional migration (ADR-024), closing the version-4 drift; capture-time volume truth (ADR-023); an explicit `st_dev` nested-mount boundary; single-process catalog ownership (ADR-025); a catalog-path override with automatic XCTest-host isolation (ADR-026); offline snapshot history; lazy `NSOutlineView` tree browsing over bounded SQLite queries; offline metadata search; deterministic streamed JSON export. Clean arm64 build, 100 tests, 0 failures, 2 skipped.

A latent Milestone 2 defect was found and fixed here: `skipDescendants()` was called for symlinks as well as packages, which made the enumerator skip descent into the *next* sibling directory and silently omit that subtree. See `PRODUCT_STATE.md` § Production implementation status.

Known limitations carried forward:

- **NTFS is ENVIRONMENT-BLOCKED for a stock-macOS proof.** It captured correctly, but only through a third-party driver; this macOS build ships no `mount_ntfs` helper and no NTFS formatter (`FILESYSTEM_SUPPORT_MATRIX.md` §2.2). The provider path is not invalidated.
- **The M3 large-catalog gate ran at 100,101 entries.** The 1,000,000-entry class is reserved for the Milestone 5 acceptance gate; M3 does not claim that final-scale result.
- **Collection UI, the capture-organization sheet, and rename/move/note controls are not built.** Milestone 3's scope statement listed them; the milestone delivered the history, browsing, search, export and provider work instead, and the Collection data layer from Milestone 2 remains unexposed. This is the one part of Milestone 3's stated scope that was not completed, and it is not blocked by anything.
- **Manual Session A remains deferred**, so no part of this milestone has been seen by a human.

## Milestone 4 — Metadata comparison and the essential user workflow

- **Outcome:** the user can compare two snapshots, or a live folder against a snapshot, and find a single-entry difference in a large tree without expanding it — with the UI never claiming content was verified.
- **Major components:** comparison engine; left/right source picker (Gemini task); transient-snapshot capture for live sources (ADR-012); Fast Metadata / Structure Only / Strict Metadata profiles; matched/added/removed/changed/uncertain classification (inaccessible entries classify as `uncertain` — recorded metadata is not a trustworthy picture); collision handling producing `uncertain` (ADR-010); differences-only mode; next/previous difference navigation; report summary; "Content Not Verified" labeling. Aggregate-signature subtree skipping is not implemented in this backend; matched-subtree visual collapse remains deferred with the GUI.
- **Files/modules involved (implemented):** `FSD/Diff/` (ComparisonModels, ComparisonProfileRepository, ComparisonEngine, ComparisonResultRepository, ComparisonService), `FSD/Catalog/TransientSnapshotLifecycle.swift`; pending: `FSD/UI/Comparison/`.
- **Dependencies:** Milestone 3.
- **Targeted automated validation:** known added/removed/changed/matched fixture sets classify exactly as specified; logical-size changes detected; ignored service files do not affect the Fast Metadata summary; normalization-version mismatch blocked; collision members never arbitrarily paired; transient snapshots excluded from user history and cleaned up on close and on launch-after-crash; cross-provider comparison produces no provider-specific special-casing.
- **Manual test requirement:** folded into Manual Session B.
- **Independent audit required:** **YES** — broad comparison semantics is an explicit review boundary.
- **Explicitly deferred:** automatic mount-triggered capture; HTML export.

**Milestone 4 implementation status (2026-08-04): COMPLETE_WITH_KNOWN_LIMITATIONS; focused bounded-error re-audit APPROVE WITH CONDITIONS.** The correction slice (`handoffs/FSD_M4_COMPARISON_GUI_FIX_C_20260804-172438.md`) and bounded-error fix (`handoffs/FSD_M4_GUI_BOUNDED_ERROR_FIX_C_20260804-180141.md`) are independently verified for clean arm64 compilation, canonical orientation, no GUI raw SQL, bounded paging, cross-page navigation, lifecycle, details and accessibility. The fixed mapper is production-tested against two hostile arbitrary messages and the live-capture wrapper; typed distinctions remain bounded. Full clean-build evidence after the fix is 242 total / 239 passed / 0 failed / 3 skipped with schema v7 unchanged. Milestone 4 is closed with deferred manual GUI/VoiceOver observation and a separate legacy capture-surface error wording issue tracked for Milestone 5. Milestone 5 is the next implementation phase.

**Supersession note:** Milestone 5 has since closed technically with known
limitations. The dated Milestone 4 next-phase wording above is historical;
the current status and M5 closure amendment govern task selection.

## Milestone 5 — Performance, consolidated acceptance, and pre-MVP audit

- **Outcome:** FSD meets its stated performance targets, passes one consolidated human acceptance session, and clears a mandatory pre-MVP independent audit.
- **Major components:** performance measurement harness (entries/sec, insert throughput, peak memory, search latency, diff latency, database size per 100k entries); self-contained HTML snapshot and diff export; database backup/recovery; schema migration tests; accessibility review (keyboard tree navigation, VoiceOver labels, non-color status indicators); local ad-hoc-signed `.app`.
- **Files/modules likely involved:** `FSD/Export/HTMLExporter.swift`, `FSDPerformanceTests/`, `FSD/Catalog/Backup*.swift`.
- **Dependencies:** Milestone 4.
- **Targeted automated validation:** the `TEST_PLAN.md` §4 benchmark classes (10k / 100k / 1M) run and recorded; migration preserves prior snapshots; HTML report opens with neither the app nor the source volume present; full read-only suite re-run.
- **Manual test requirement:** **YES — Manual Session B**, the final consolidated MVP acceptance session (`TEST_PLAN.md` §8).
- **Independent audit required:** **YES — mandatory pre-MVP audit.**
- **Explicitly deferred:** automatic mount-triggered capture and login-item support, unless the project owner pulls them into MVP scope; notarization and any distribution channel (ADR-006).

**Milestone 5 implementation status (2026-08-05): COMPLETE_WITH_KNOWN_LIMITATIONS;
schema-v8 correction complete; the correction-stage re-audit requirement is
closed by the amendment below.**

**Closure amendment (2026-08-05): focused schema-v8/disposal re-audit CLOSED —
APPROVE WITH CONDITIONS**, per
`handoffs/FSD_M5_SCHEMA_V8_DISPOSAL_REAUDIT_A_20260805-223211.md`.
The reporting-only condition is already corrected in `TEST_PLAN.md`
(284 executed, 281 passed, 0 failed, 3 skipped). Manual acceptance remains
**NOT PERFORMED — DEFERRED BY OWNER**; overall MVP approval is **NOT CLAIMED**.

Delivered within the M5 slice (no new product features, no schema change):

- **Final-scale gates (1,000,000-entry class, CT-005):** a 1,002,182-entry
  synthetic snapshot catalog (history, root/direct-child/deep pages, bounded
  search, filters, deterministic ordering, streamed ~340 MB JSON export,
  reopen, integrity/foreign-key/classification checks) and a
  1,003,104-vs-1,003,205-entry comparison class (exact six-outcome
  classification with 500 case-fold collision groups of 2,000 members,
  differences-only paging, per-outcome filters, next/previous navigation,
  cancellation with count-consistent evidence, repeat-run determinism,
  result reopen, whole-comparison disposal with zero residue). Debug runs are
  correctness evidence; Release runs are the performance acceptance basis
  (`FinalScaleSnapshotTests`, `FinalScaleComparisonTests`).
- **Memory and boundedness:** resident-footprint probes for browsing, search,
  export streaming and the comparison merge peak; page caps verified; the
  pathological equal-key collision group is an explicit typed failure
  (`ComparisonError.collisionGroupTooLarge`, cap 100,000 — KI-023), closing
  the Milestone 4 follow-up condition KI-019
  (`FinalScaleMemoryProbeTests`).
- **Cancellation/race stress:** repeated capture, live-mode and merge
  cancellation; finalization races; orphan scan/comparison recovery; workspace
  close during a running live comparison; exactly one terminal state wins,
  cancelled work never completes, no residue (`CancellationRaceStressTests`).
- **Startup/recovery reliability:** fresh v8 startup, lock contention,
  repeated open/close cycles, interrupted-op relaunch stability,
  damaged-schema rejection, owner-catalog isolation (`M5ReliabilityTests`;
  migration-chain and damaged-schema suites already existed).
- **KI-022 fix:** the legacy capture UI now maps all visible failures through
  the shared bounded `CaptureErrorDescription` (raw diagnostics stay on
  standard error), with adversarial regression tests
  (`CaptureErrorBoundaryTests`).
- **Offline/read-only regression:** the existing end-to-end probe, source-
  unchanged, JSON export and no-payload-handle suites re-run clean; the
  filesystem matrix evidence from Milestone 3 remains valid; stock-macOS NTFS
  remains ENVIRONMENT-BLOCKED.
- **Builds:** fresh Debug and Release arm64 builds, full XCTest suite, focused
  final-scale and race/recovery runs, and isolated app launch probes
  (snapshots / compare / capture destinations, isolated catalogs, schema 8,
  no owner access, no network).
- **Consolidated deferred manual session:** prepared in `TEST_PLAN.md` §8.2
  (steps M1–M25) — **NOT PERFORMED — DEFERRED BY OWNER**.
- **Repository hygiene:** prior-Agent scratch artifacts (`temp.db*`,
  `temp2.db*`, `verify_output.txt`, `default.profraw`, four one-off planning
  scripts) removed; the four pbxproj wiring utilities are retained as
  documented developer utilities.

Known limitations carried forward: deferred owner manual acceptance; stock-
macOS NTFS environment limitation; bounded visual/VoiceOver observation
deferred; HTML export remains deferred (out of M5 scope per the task).

**Independent pre-MVP audit (2026-08-05): REJECT**
(`handoffs/FSD_M5_FINAL_PREMVP_AUDIT_R_20260805-093249.md`) and corrected in
schema version 8. KI-024 is fixed (see `KNOWN_ISSUES.md`); every other gate
reproduced exactly. At the correction stage, the focused independent re-audit
was the next action; the closure amendment above supersedes that gate.
**Overall MVP approval remains NOT CLAIMED.**

## Deferred beyond the MVP milestones

- `EmbeddedRawProvider` production integration for ext2/3/4, including libfsext Conditions A, B, D, F (`FILESYSTEM_FEASIBILITY_PLAN.md` §7) and the reader helper process (ADR-017).
- Physical raw-device access and `authopen` authorization (ADR-016) — unverified on real hardware.
- Automatic mount detection and capture; login-at-start support.
- LGPL-3.0 compliance review (libfsext Condition C) — triggered only by distribution, not by local builds.

## Phase 1.5 — Nullable Magika enrichment preparation (implemented and audited; runtime deferred)

**Audit closure (2026-08-07): APPROVE WITH CONDITIONS** —
`handoffs/FSD_P15_MAGIKA_NULLABLE_ENRICHMENT_AUDIT_R_20260807-142313.md`.
The boundary audit is closed. Runtime design subsequently completed under
ADR-032; runtime remains not started/inactive and its separately authorized
schema-change gate remains in force. Owner manual acceptance is deferred.

- **Current slice:** a typed `LocalFileClassificationProvider` boundary, disabled/no-op provider, explicit `ClassificationEnrichmentService`, append-only `EntryClassificationRepository`, nullable model round-trip, bounded selected-entry browser presentation, and comparison/safety regression tests.
- **Preparation-slice schema:** reuse schema version 8's existing nullable `entry_classifications` table; no schema version 9 and no speculative provider column were introduced by this slice. Persisted provenance is limited to the supported detector/model version fields. ADR-032 separately requires a schema change before future runtime implementation.
- **Runtime status:** Magika is not installed, not a dependency, not downloaded and not active. The disabled provider never reads a source URL, bytes or payload. A future provider requires a separate approved task and bounded local policy.
- **Dependencies / entry gate:** the MVP core gate has passed technically, so this preparation slice may proceed. Actual runtime inference remains optional and does not block MVP criteria.
- **Export:** JSON export remains format version 1 and excludes classification because the canonical export contract does not require nullable enrichment.
- **Requirements binding on this phase:**
  - fully offline execution, no network access;
  - only bounded byte-range reads — never full-file reads, never full-file hashing;
  - no sampled-byte persistence — bytes read for classification are never written to storage;
  - no source-volume modification;
  - detector and model versions tracked and traceable on every result;
  - append-only/versioned results — a later run never overwrites or reinterprets an earlier run's stored result;
  - no mutation of immutable snapshot metadata;
  - no change to any historical diff conclusion; Metadata Match continues to be computed without regard to classification;
  - a classification failure never invalidates or changes the status of an otherwise-valid completed metadata snapshot.
- **Append-only enforcement:** this slice uses the repository-level guarantee (no update/delete API, deterministic duplicate-run rejection) together with the existing unique key. Direct SQL remains outside the typed application API and is covered by the existing schema verification seam.
- **Explicitly out of scope for this phase's entry:** backfilling or reclassifying any snapshot captured before Phase 1.5 begins.

## Deferred backlog

- metadata Merkle subtree signatures;
- incremental rescan optimization;
- network volume support;
- optional file resource identifiers;
- optional content checksum verification as a separate explicit mode;
- CSV and Markdown exports;
- volume labels and rental-house inventory fields;
- TSK as the ext2/3/4 reader, if libfsext fails production integration (`DEPENDENCY_AND_LICENSE_REVIEW.md` §3.2);
- a normalized `devices`/`partitions` identity table, if raw-device identity needs grow;
- a normalized source-identity table for folders/disk-images/raw-partitions, which would let `source_collection_defaults` cover those source kinds (currently volume-only — `SNAPSHOT_COLLECTIONS.md` §9.3);
- Collection assignment for saved comparison sessions (`SNAPSHOT_COLLECTIONS.md` §9.4);
- camera-vendor folder recognition, media validation, codec analysis — explicitly not planned at any phase, not merely deferred; see `PRD.md` §4.1.
