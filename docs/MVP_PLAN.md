# MVP roadmap and dependency sequence

This document owns stable product roadmap requirements and milestone dependencies.
[PRODUCT_STATE.md](PRODUCT_STATE.md) owns implemented capabilities and gaps;
[../STATE/PROJECT_STATE.md](../STATE/PROJECT_STATE.md) owns accepted control state.
No roadmap dependency grants execution authority. Dated milestone evidence stays
in immutable handoffs. [TEST_PLAN.md](TEST_PLAN.md) owns validation/manual backlog;
[SNAPSHOT_COLLECTIONS.md](SNAPSHOT_COLLECTIONS.md) owns Collection semantics;
[FILESYSTEM_FEASIBILITY_PLAN.md](FILESYSTEM_FEASIBILITY_PLAN.md) owns provider proof.

## Owner UX/demo dependency map

- Track A OpenDesign may occur now as design work.
- Backend implementation only after explicit product-resume authorization.
- P15 sequence stays canonical.
- Identity/mount ADR gates mount-dependent features.
- Compare hierarchy/ancestor work is independent of compare truth.
- Dashboard/history/search service additions should be UI-neutral.
- Production UI implementation follows Owner-reviewed design direction.
- E2E/manual validation follows integrated demo path.
- No roadmap item grants authorization.
- Do not reorder or rewrite P15 slice contracts.

## Milestone 1 — Application, catalog, and snapshot foundation

- **Outcome:** an FSD application that launches on Apple Silicon, creates its catalog database at schema version 4, and can create and terminalize a snapshot row through a trustworthy lifecycle — with no scanner yet.
- **Major components:** Xcode project (macOS 15+, arm64, Swift 5.9+); `CatalogDatabase` SQLite wrapper with per-connection `PRAGMA foreign_keys = ON` startup assertion; migration runner against `database/schema.sql`; snapshot lifecycle model (`scanning` → `complete` / `complete_with_warnings` / `interrupted` / `cancelled` / `failed`); normalization identity (ADR-009); logging and error model; SwiftUI navigation shell; Application Support directory layout.
- **Files/modules likely involved:** `FSD.xcodeproj`, `FSD/App/`, `FSD/Catalog/CatalogDatabase.swift`, `FSD/Catalog/Migrations.swift`, `FSD/Model/Snapshot*.swift`, `FSD/Model/Normalization.swift`, `FSDUnitTests/`, `docs/database/schema.sql`, `docs/database/verify.sql`.
- **Dependencies:** none. Implementation requires separate authorization.
- **Safety requirements:** exact normalization completion guard and embedded-raw verification fixtures that exercise provider constraints rather than incidental missing fields (ADR-009).
- **Targeted automated validation:** fresh schema apply + `PRAGMA integrity_check` + `PRAGMA foreign_key_check` as an Xcode test target; `verify.sql` run clean with each intended rejection firing for its intended reason; positive-format normalization fixtures (`'   '`, `'UNKNOWN'`, `'PLACEHOLDER'`, `'NOT_SET'`, `'PENDING'` must be rejected at completion); snapshot lifecycle fixtures (terminal reversion rejected, zero-root completion rejected, cross-snapshot parent rejected); startup assertion that `foreign_keys` is ON.
- **Manual test requirement:** none. This foundation milestone has no manual UI acceptance requirement.
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

## Milestone 3 — Offline history, browsing, large-tree lazy loading, and the remaining providers

- **Outcome:** a captured snapshot stays fully browsable and searchable after the source is ejected, an approximately 100,000-entry tree navigates without eager loading, and the remaining native filesystems are proven. The million-entry class is a later Milestone 5 gate.
- **Major components:** volume/snapshot sidebar including the Collections section; lazy `NSOutlineView` tree backed by bounded SQLite queries; summary inspector; search by name/path extended to Collection, display name, source, capture date, filesystem, status; offline state labels; capture-organization sheet UI wired to Milestone 2's data layer; rename/move/note controls; JSON snapshot export.
- **Filesystem work folded in here:** feasibility + provider support for **FAT16, FAT32, exFAT, NTFS read-only, UDF** (disk images first, per `FILESYSTEM_FEASIBILITY_PLAN.md` §1). This is the correct home for it — it is provider-specific and was never a foundation blocker.
- **Files/modules likely involved:** `FSD/Browser/`, `FSD/UI/Sidebar/`, `FSD/UI/Inspector/`, `FSD/Search/`, `FSD/Export/JSONExporter.swift`, `FSD/Providers/` (matrix completion).
- **Dependencies:** Milestone 2.
- **Targeted automated validation:** browse a snapshot with the source path absent and assert no blocking filesystem access; assert expanding one branch issues bounded queries and never materializes the full tree; approximately 100,000-entry fixture memory ceiling; per-filesystem fixture enumeration against ground truth for the newly-covered filesystems; JSON export schema validation. The 1,000,000-entry large-catalog class is the Milestone 5 acceptance gate.
- **Manual test requirement:** folded into Manual Session B (final acceptance). No separate session.
- **Independent audit required:** **NO**, unless the FAT/NTFS/UDF work forces a change to the provider contract or to snapshot immutability — in which case it inherits Milestone 2's boundary.
- **Explicitly deferred:** comparison; `EmbeddedRawProvider` production integration; physical raw devices; HTML export.

## Milestone 4 — Metadata comparison and the essential user workflow

- **Outcome:** the user can compare two snapshots, or a live folder against a snapshot, and find a single-entry difference in a large tree without expanding it — with the UI never claiming content was verified.
- **Major components:** comparison engine; left/right source picker; transient-snapshot capture for live sources (ADR-012); Fast Metadata / Structure Only / Strict Metadata profiles; matched/added/removed/changed/uncertain classification (inaccessible entries classify as `uncertain` — recorded metadata is not a trustworthy picture); collision handling producing `uncertain` (ADR-010); differences-only mode; next/previous difference navigation; report summary; "Content Not Verified" labeling. Aggregate-signature subtree skipping is not implemented in this backend; matched-subtree visual collapse remains deferred with the GUI.
- **Files/modules:** `FSD/Diff/` (ComparisonModels, ComparisonProfileRepository, ComparisonEngine, ComparisonResultRepository, ComparisonService), `FSD/Catalog/TransientSnapshotLifecycle.swift`; `FSD/UI/Comparison/`.
- **Dependencies:** Milestone 3.
- **Targeted automated validation:** known added/removed/changed/matched fixture sets classify exactly as specified; logical-size changes detected; ignored service files do not affect the Fast Metadata summary; normalization-version mismatch blocked; collision members never arbitrarily paired; transient snapshots excluded from user history and cleaned up on close and on launch-after-crash; cross-provider comparison produces no provider-specific special-casing.
- **Manual test requirement:** folded into Manual Session B.
- **Independent audit required:** **YES** — broad comparison semantics is an explicit review boundary.
- **Explicitly deferred:** automatic mount-triggered capture; HTML export.

## Milestone 5 — Performance, consolidated acceptance, and pre-MVP audit

- **Outcome:** FSD meets its stated performance targets, passes one consolidated human acceptance session, and clears a mandatory pre-MVP independent audit.
- **Major components:** performance measurement harness (entries/sec, insert throughput, peak memory, search latency, diff latency, database size per 100k entries); self-contained HTML snapshot and diff export; database backup/recovery; schema migration tests; accessibility review (keyboard tree navigation, VoiceOver labels, non-color status indicators); local ad-hoc-signed `.app`.
- **Files/modules likely involved:** `FSD/Export/HTMLExporter.swift`, `FSDPerformanceTests/`, `FSD/Catalog/Backup*.swift`.
- **Dependencies:** Milestone 4.
- **Targeted automated validation:** the `TEST_PLAN.md` §4 benchmark classes (10k / 100k / 1M) run and recorded; migration preserves prior snapshots; HTML report opens with neither the app nor the source volume present; full read-only suite re-run.
- **Manual test requirement:** **YES — Manual Session B**, the final consolidated MVP acceptance session (`TEST_PLAN.md` §8).
- **Independent audit required:** **YES — mandatory pre-MVP audit.**
- **Explicitly deferred:** automatic mount-triggered capture and login-item support, unless the project owner pulls them into MVP scope; notarization and any distribution channel (ADR-006).

## Deferred beyond the MVP milestones

- `EmbeddedRawProvider` production integration for ext2/3/4, including libfsext Conditions A, B, D, F (`FILESYSTEM_FEASIBILITY_PLAN.md` §7) and the reader helper process (ADR-017).
- Physical raw-device access and `authopen` authorization (ADR-016) — unverified on real hardware.
- Automatic mount detection and capture; login-at-start support.
- LGPL-3.0 compliance review (libfsext Condition C) — triggered only by distribution, not by local builds.

## Phase 1.5 — Optional nullable enrichment and bounded runtime

Runtime follows the provenance/schema prerequisite and eight bounded slices in
[P15_RUNTIME_PLAN.md](P15_RUNTIME_PLAN.md). Preparation and inference are separate;
optional runtime inference does not block core MVP criteria. ADR-031/032 own the
design; ADR-035 owns the accepted filetype v1.1.3 integration. The schema-v9 provenance prerequisite and independent task034 integration gate are satisfied; task035 Slice08 verification evidence and implementation status are recorded in [PRODUCT_STATE.md](PRODUCT_STATE.md) and [FSD_P15_WHOLE_RUNTIME_VERIFICATION_D_20261007-015634.md](../handoffs/FSD_P15_WHOLE_RUNTIME_VERIFICATION_D_20261007-015634.md). Independent final runtime audit and BRAIN acceptance remain pending. JSON export format version 1 excludes classification. Manual acceptance remains **NOT PERFORMED — DEFERRED BY OWNER**. No runtime or schema work is authorized by this roadmap.

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
- **Append-only enforcement:** the preparation boundary uses the repository-level guarantee (no update/delete API, deterministic duplicate-run rejection) together with the existing unique key. Direct SQL remains outside the typed application API and is covered by the existing schema verification seam.
- **Explicitly out of scope for runtime entry:** backfilling or reclassifying any snapshot captured before Phase 1.5 begins.


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
