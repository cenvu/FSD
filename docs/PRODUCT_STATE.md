# Product State

Last updated: **2026-10-03**, owner-directed model-benchmark removal and fresh automated readiness validation; no product implementation or owner manual acceptance.
Current Handoff: `handoffs/FSD_MODEL_BENCHMARK_PURGE_READINESS_D_20261003-220825.md`.
Prior entry: Phase 1.5 nullable classification enrichment audit (`handoffs/FSD_P15_MAGIKA_NULLABLE_ENRICHMENT_AUDIT_R_20260807-142313.md`).
Prior entry: Phase 1.5 nullable classification enrichment (`handoffs/FSD_P15_MAGIKA_NULLABLE_ENRICHMENT_C_20260806-004158.md`).
Prior entry: Milestone 5 performance/closeout (`handoffs/FSD_M5_PERFORMANCE_PREMVP_C_20260805-034539.md`).
Latest accepted audit evidence: M5 schema-v8/disposal re-audit (2026-08-05), nullable enrichment boundary audit (2026-08-07), and runtime design completion (2026-08-07), referenced below.

## Current phase

**Milestones 1–5 technical core: CLOSED WITH KNOWN LIMITATIONS.** Owner
manual acceptance remains **NOT PERFORMED — DEFERRED BY OWNER**; overall
MVP approval is **NOT CLAIMED**. Current schema remains **v8**.

**Milestone 5 schema-v8/disposal re-audit: CLOSED — APPROVE WITH CONDITIONS
(2026-08-05)**, per
`handoffs/FSD_M5_SCHEMA_V8_DISPOSAL_REAUDIT_A_20260805-223211.md`.
This supersedes the correction-stage pending gate. The non-safety test-count
wording condition is already corrected in `TEST_PLAN.md`: 284 executed,
281 passed, 0 failed, 3 skipped. KI-024 is fixed by the
dedicated `comparison_results(parent_result_id)` index, explicit transactional
v7-to-v8 migration, complete ExpectedState drift protection, and focused
one-million-result disposal regressions. Release evidence is below the
120-second threshold for both explicit disposal (9.930 s) and canonical live
workspace close (10.018 s), with clean integrity/foreign-key checks and a
successful post-disposal write. These are historical correction-run measurements;
the accepted re-audit independently reproduced both disposal gates. Technical
closure does not claim manual acceptance or overall MVP approval.

**Phase 1.5 nullable enrichment preparation (2026-08-05): implemented without
Magika inference.** FSD now has a typed local-only provider boundary, an
explicit append-only repository/service for nullable entry classifications
already supported by schema version 8, and bounded presentation in the
selected-entry history browser. The disabled provider performs no filesystem
access and ordinary capture, browsing, search, export and comparison remain
metadata-only. Classification is inferred, optional and non-authoritative; it
does not affect snapshot identity, counts, completion, comparison outcomes or
immutable entry metadata. No old-snapshot backfill occurs. The JSON export
contract remains unchanged and excludes classification. Magika is not
installed, not a dependency and never executed.

**Nullable enrichment boundary audit: CLOSED — APPROVE WITH CONDITIONS
(2026-08-07)**, per
`handoffs/FSD_P15_MAGIKA_NULLABLE_ENRICHMENT_AUDIT_R_20260807-142313.md`.
Manual/UI acceptance and the separately tracked limitations remain deferred.

**Magika runtime design: COMPLETE (2026-08-07)**, per
`handoffs/FSD_P15_MAGIKA_RUNTIME_DESIGN_A_20260807-155630.md` and ADR-032.
Runtime implementation is **NOT STARTED / INACTIVE**. The design requires
**SCHEMA CHANGE REQUIRED BEFORE RUNTIME**; schema v8 remains current and any
runtime schema change requires separate authorization. This reconciliation
authorizes neither a schema migration nor runtime implementation.

### Historical milestone context (superseded gate selection)

The following milestone-era reports preserve their original scope, dates,
measurements and then-next actions. The accepted closures above supersede
their pending/next-gate wording; they are not current task instructions.

Prior status (Milestone 5 performance/closeout,
COMPLETE_WITH_KNOWN_LIMITATIONS, deferred manual acceptance and stock-NTFS
environment limitation only) for context: The one-million-entry final-scale
gates are closed: a 1,002,182-entry snapshot catalog opens, pages, searches
and exports with bounded memory (streamed ~340 MB JSON), and a
1,003,104-vs-1,003,205-entry comparison classifies exactly (1,000,003
matched / 1,000 changed / 1,001 added / 1,001 removed / 601 uncertain — 500
collision groups with 2,000 members, never paired — / 200 ignored), repeats
deterministically, cancels with count-consistent evidence, navigates
differences across page boundaries and reopens. Whole-comparison disposal is
verified residue-free at the 100,202-per-side class; at the 1,000,000-entry
class the cascade is O(n²) with the root cause identified and the schema fix
deferred (KI-024). Memory probes measure bounded browsing/search/export
footprint, a bounded merge peak, page caps and the pathological equal-key
collision group as a typed failure (`ComparisonError.collisionGroupTooLarge`,
KI-023 — the Milestone 4 follow-up condition is closed with an explicit safe
cap).
Cancellation/race stress and startup/recovery reliability suites pass.
KI-022 (legacy capture UI exposing raw error text) is fixed via the shared
bounded `CaptureErrorDescription` mapper with adversarial regression tests.
Fresh Debug and Release arm64 builds pass; the full suite passes (see the
Handoff for exact counts); isolated app launch probes reach all three
destinations with no owner-catalog access and no network activity. The
consolidated deferred manual acceptance session is prepared in `TEST_PLAN.md`
§8.2 and remains **NOT PERFORMED — DEFERRED BY OWNER**. Manual acceptance is
not claimed; notarization/distributable release readiness is not claimed;
the MVP is not approved — the **next action is the independent Codex final
pre-MVP audit**. Milestone 2 was technically audited APPROVE WITH CONDITIONS;
its five technical conditions (C2–C6) are implemented and covered by
automated tests. Milestone 2 acceptance sign-off remains open on C1 alone:
Manual Session A is **NOT PERFORMED — DEFERRED BY OWNER**.

Milestone 3 delivers schema version 5 with the project's first real transactional migration, offline snapshot history, lazy `NSOutlineView` tree browsing, offline metadata search, deterministic JSON export, an explicit nested-mount boundary, capture-time volume truth, single-process catalog ownership, and a catalog-path override.

Milestone 4 delivers the comparison backend and a partial frontend on **schema version 7** (ADR-027 for the v6 result-integrity wave, ADR-028 for the v7 terminal-evidence and inventory correction): the deterministic metadata comparison engine over keyset-paged ordered streams (bounded memory — no whole-tree arrays), all three canonical modes (snapshot-to-snapshot offline, live-to-snapshot and live-to-live through the existing scanner into transient snapshots), typed comparison profiles with frozen profile revisions, ADR-010/011 identity semantics (case sensitivity selection, case-fold collisions as never-paired `uncertain` groups, normalization-version enforcement), field-level differences via `difference_flags`, terminal-state immutability at the schema boundary — now covering result DELETE and collision group/member INSERT/UPDATE/DELETE, with whole-comparison disposal still cascading — deterministic cancellation/recovery (orphaned `running` comparisons recover as `failed`, never `complete`), the transient-snapshot lifecycle (ADR-012: workspace close and launch cleanup), and a view-ready result API (paging, per-outcome filters, next/previous difference navigation, side descriptors). The independent visual-interface audit rejected the first GUI attempt; the correction slice (2026-08-04) closed all five rejection-level findings and the app now builds and passes the full suite (240 executed, 237 passed, 0 failed, 3 skipped) — see the Milestone 4 visual comparison interface bullet below. Backend scale evidence remains 100,202 entries per side with exact classification; the 1,000,000-entry class remains the Milestone 5 gate.

The Milestone 2 acceptance audit independently reproduced the clean build and full test suite (23/23 passing, 0 failed, 0 skipped, Xcode 26.3 / Swift 6.2.4, arm64), and found **no rejection-level defect**: no regular-file payload read, no source mutation API, no symlink or root-boundary escape, no silent path-identity collision, snapshot immutability enforced at both Swift and SQLite boundaries, cancellation provably unable to reach `complete`, and safe idempotent startup recovery.

**Manual Session A remains NOT PERFORMED — DEFERRED BY OWNER.** Per `AGENT.md` § Deferred Manual Testing Rule, it is not re-attempted and not re-labelled. Milestone 3 replaced everything in that session that evidence can settle with automated and Agent-observed checks (`TEST_PLAN.md` §8.1); what is left needs a human at the window. Original audit finding, unchanged: Hard gates A2b (controlled-fixture capture), A3 (source unchanged), A4 (cancellation) and A6 (force-quit recovery) have no supporting evidence: the catalog contains no such snapshots, `scan_issues` is empty, and the prepared `/tmp` fixtures show an access time unchanged since creation. One real capture of a mounted exFAT volume (`/Volumes/A006C84S`, 45 entries) was performed by the project owner and independently verified clean in the catalog, but it used an uncontrolled source with no pre-capture baseline, so it cannot satisfy A3. Source read-only safety nonetheless remains **VERIFIED** by static analysis and by the automated source-listing test.

FSD is transitioning out of planning. The two historical gates that blocked Phase 0 (Xcode/catalog implementation) have been re-examined against the actual evidence and the actual schema, and neither blocks starting the application foundation:

1. **R0 lineage — CLOSED.** The 2026-07-24 REJECT (`handoffs/FSD_R0BLOCKERSAUDIT_A_20260724-211837.md`) was followed by three correction rounds and a final independent audit that returned **APPROVE** (`handoffs/FSD_PLAN_GATE_FINAL_REAUDIT_A_20260725-154907.md`). Earlier wording in this file and in `MVP_PLAN.md` claiming R0 "remains open ... unchanged since that audit" was stale and has been corrected.

2. **Filesystem feasibility — partially complete, and not a blocker for core MVP foundation.** The ext2/3/4 sub-gate passed with deferred production conditions across three independent reviews. Native APFS/HFS+/APFSX/HFSX feasibility passed on disk images. FAT16/FAT32/exFAT/NTFS/UDF have not been tested. None of this blocks the Xcode project, the SQLite catalog, the snapshot model, or native folder scanning — see `MVP_PLAN.md` and `FILESYSTEM_FEASIBILITY_PLAN.md`.

The two residual foundational defects are closed in Milestone 1:

- **FSD-FINAL-REAUDIT-001 — CLOSED.** Snapshot completion now requires exact equality to `fsd-normalizer-v1_app-1.0_os-1` in both Swift and the SQLite trigger.
- **FSD-FINAL-REAUDIT-002 — CLOSED.** The two embedded-raw verification fixtures now include `normalization_version`, so provider constraints are exercised directly.

## Production implementation status

**Milestones 1-3 production foundation exists.** `FSD.xcodeproj` contains a macOS 13+ arm64 SwiftUI app and XCTest target.

Implemented: `CatalogDatabase` with explicit transactional migrations (schema version 8); `CatalogMigrations` (v4 to v5 converging both known v4 variants, then v5 to v6, v6 to v7, and v7 to v8); `CatalogLocation` (catalog-path override plus XCTest-host isolation); `CatalogProcessLock` (single-process ownership); snapshot lifecycle models and repository; `SnapshotHistoryRepository` (offline history, capture-time source facts); `NativeMountedProvider` with an explicit `st_dev` mount-boundary policy; `FilesystemDetector`; metadata-only streaming `SnapshotScanner`; batched `SnapshotWriter`; cancellation; startup recovery; `SnapshotTreeDataSource` (bounded lazy tree queries with query/row instrumentation); `MetadataSearchService` (offline, bounded, indexed); `JSONSnapshotExporter` (deterministic, streamed, metadata-only); capture UI, snapshot-history UI, and a lazy `NSOutlineView` browser with an inspector, search and offline labelling; and the Milestone 4 comparison backend — `ComparisonEngine` (bounded ordered-stream merge, deterministic classification, field-level `difference_flags`), `ComparisonProfileRepository` (built-in Fast Metadata / Structure Only / Strict Metadata with frozen profile revisions), `ComparisonService` (the three modes with transient captures through the production scanner, ADR-012), `ComparisonResultRepository` (view-ready records, stable paging, per-outcome filters, next/previous difference navigation, side descriptors, field differences), and `TransientSnapshotLifecycle` (workspace close, orphaned-comparison recovery, unreferenced-transient cleanup).

Not implemented: Collection UI, HTML export, `EmbeddedRawProvider` and raw-device access, and the Magika runtime.

Milestone 3 evidence: 100 XCTest tests pass on arm64 (0 failures, 2 skipped). A 100,101-entry synthetic catalog opens by reading **1 row**, displays its first page with **100 rows**, and expands one directory with **200 rows** — three orders of magnitude below the entry count. Bounded search over that catalog returns in 0.021 s. Eight host-capable filesystem variants captured from generated read-only disk images with the image file byte-identical before and after (`FILESYSTEM_SUPPORT_MATRIX.md` §2.1.1).

### A Milestone 2 defect found and fixed during Milestone 3

`NativeMountedProvider` called `enumerator.skipDescendants()` for symbolic links as well as packages. `skipDescendants()` skips "the most recently obtained subdirectory"; a symlink is not one, so the enumerator skipped descent into **the next directory at that level** instead — silently omitting that whole subtree from the snapshot, with no scan issue and no error. Whether it triggered depended on enumeration order, which is directory order rather than alphabetical, so it was latent and data-dependent. It was reproduced directly against `FileManager` before the fix, and the call proved unnecessary: `FileManager.enumerator` does not follow a symlink to a directory in the first place. Fixed by skipping descendants for packages only; three regression tests cover the symlink-before-sibling ordering, symlink-to-directory non-traversal, and package atomicity.

Consequence for existing data: any snapshot captured by Milestone 2 code may be missing a subtree. The project owner's single existing snapshot (`A006C84S`, 45 entries) is flat enough that this is unlikely, but it has not been re-verified against the source, and comparisons against Milestone 2 snapshots could report false "removed" entries. Re-capturing anything captured before 2026-08-04 is the safe course.

## Completed

Milestone-specific schema versions, test counts and then-next actions below
describe their dated closeouts. The current accepted gate summary above
supersedes historical task-selection wording.

- Product purpose, MVP boundary, and core user stories defined.
- SQLite schema at **version 8** (`database/schema.sql`, ADR-027 + ADR-028 + ADR-030). Fresh and migrated catalogs converge; `PRAGMA integrity_check` = `ok`, `PRAGMA foreign_key_check` = clean. A fresh database records only version 8; a migrated one records 4, 5, 6, 7 and 8. `schema.sql` creates a catalog and is never replayed against an existing one — forward movement is the job of `CatalogMigrations` alone (ADR-024).
- Initial UX wireframes drafted.
- Read-only safety policy documented, extended to raw-device access (`SECURITY_AND_READ_ONLY_POLICY.md`).
- Filesystem-provider architecture, per-filesystem support matrix, and dependency/license research documented.
- Snapshot Collections specification drafted (`SNAPSHOT_COLLECTIONS.md`), folded into the milestone plan.
- **Phase 0A — ext2/ext3/ext4 (libfsext):** feasibility proven on disk images; three independent reviews concluded **PASS WITH DEFERRED PRODUCTION CONDITIONS**. Artifacts in `spikes/phase0a-libfsext/`.
- **Phase 0A — native APFS / APFS case-sensitive / HFS+ / HFSX:** feasibility proven on disk images (read-only guarantee by pre/post image hash, 3-run determinism, case-sensitivity and NFC/NFD behavior characterized). Artifacts in `spikes/phase0a-native-applefs/`. Determinism and case-distinct fixtures independently re-verified 2026-08-04.
- **Magika Phase 1.5 nullable boundary:** typed local-only provider and explicit enrichment service/repository in the Catalog target, nullable entry-classification persistence on schema v8, bounded selected-entry browser presentation, and regression coverage. Runtime Magika inference remains inactive.
- `database/verify.sql` extended with a targeted schema-v4 classification block and a schema-v5 capture-time-facts block (2026-08-04; both authored alongside the work they check, not independently reviewed). Run clean 2026-08-04: 36 intended rejections fire, including both new `Snapshot capture-time facts are immutable` cases.
- **Milestone 1 foundation:** native Xcode project, SQLite catalog layer, transactional schema bootstrap, snapshot lifecycle foundation, exact normalization guard (2026-08-04).
- **Milestone 2 capture:** native mounted provider, mounted-source detection, streaming metadata scanner, bounded batch writer, atomic terminal lifecycle, cancellation, startup recovery, capture UI. Audited APPROVE WITH CONDITIONS (2026-08-04).
- **Milestone 3 history, browsing and providers:** schema version 5 with the first real transactional migration; capture-time volume truth; explicit nested-mount boundary; single-process catalog lock; catalog-path override; offline snapshot history; lazy `NSOutlineView` browsing; offline metadata search; deterministic JSON export; APFS/APFS case-sensitive/HFS+/HFSX/FAT16/FAT32/exFAT/UDF promoted to Supported (2026-08-04 closeout).
- **Milestone 4 comparison backend:** schema version 7 at the time, now carried forward to schema version 8 by ADR-030; deterministic bounded-memory comparison engine; snapshot-to-snapshot, live-to-snapshot and live-to-live modes via transient captures (ADR-012); built-in profiles with frozen profile revisions; ADR-010/011 identity semantics; field-level differences; comparison/result/collision-evidence terminal guards at the SQLite boundary with whole-comparison disposal preserved; complete `ExpectedState` object inventory with normalized definition checks (damaged or substituted v8 catalogs are rejected on open); deterministic cancellation and orphan recovery; transient lifecycle; view-ready result API with paging, per-outcome filters and difference navigation; and the focused schema-safety regression suite. The backend remains the implemented foundation.
- **Milestone 4 visual comparison interface (GUI correction):** the five prior rejection-level findings and the bounded-error defect are independently closed. `ComparisonUIErrorDescription.message(for: SnapshotScannerError)` now uses fixed bounded text for arbitrary `captureFailed` payloads; the two new regression tests call the production mapper directly, cover the `ComparisonError.liveCaptureFailed` wrapper, compare two hostile messages, suppress SQL/path/provider details, and preserve cancellation/provider/catalog distinctions. The interface retains canonical three-mode orientation, no GUI raw SQL, bounded single-page paging, repository-backed cross-page navigation, canonical workspace/disposal lifecycle, all outcome/detail presentation, accessibility labels and keyboard shortcuts. Fresh arm64 clean/build/full-suite evidence after the fix is 242 total tests, 239 passed, 0 failed, 3 skipped; schema remains v7 with the bundled `schema.sql` byte-identical to `docs/database/schema.sql`. The focused re-audit returned **APPROVE WITH CONDITIONS**. Milestone 4 is closed as **COMPLETE_WITH_KNOWN_LIMITATIONS**; Milestone 5 is the next implementation phase. Manual acceptance remains deferred.
- **Phase 0A native-mounted matrix:** all seven support steps cleared for eight host-capable generated read-only image variants, with image SHA-256 identical before and after each capture (`FILESYSTEM_SUPPORT_MATRIX.md` §2.1.1). Stock-macOS NTFS remains environment-blocked.

## Not started

- HTML export; mount detection; login item support.
- `EmbeddedRawProvider` / reader helper process; volume identity service.
- Collection UI and the Collection-facing repository code behind it.
- **Phase 0A — NTFS:** captured successfully from a generated image, but only through a third-party driver (Tuxera NTFS). This macOS build ships no `mount_ntfs` helper and no NTFS formatter, so a stock-macOS proof is **ENVIRONMENT-BLOCKED — PROVIDER PATH NOT INVALIDATED** (`FILESYSTEM_SUPPORT_MATRIX.md` §2.2).
- **Phase 0B** — the decision-recording phase converting Phase 0A results into finalized ADRs and support-matrix statuses — partially done: ADR-023 to ADR-026 and the §2.1 matrix cover Milestone 3's results.
- **Magika runtime:** not implemented, not installed, not a dependency, never executed. The typed boundary and disabled provider exist, but no provider reads payload bytes or performs inference.
- **Phase 1.5 runtime inference** — deferred; this slice prepares nullable persistence and presentation only. No automatic classification or old-snapshot backfill occurs.

## Milestone 2 audit conditions

**C2 through C6 are closed by Milestone 3.** C1 remains open by the project owner's decision.

1. **C1 — OPEN, deferred by owner.** Manual Session A hard gates A2b/A3/A4/A6 remain **NOT PERFORMED — DEFERRED BY OWNER**. Blocks Milestone 2 acceptance sign-off; does not block implementation (`AGENT.md` § Deferred Manual Testing Rule). Milestone 3 covered the evidence-settleable part automatically — see `TEST_PLAN.md` §8.1 for exactly what is and is not covered.
2. **C2 — CLOSED.** Schema version 5 plus one explicit transactional migration; `schema.sql` is never replayed; `verifyCurrentSchemaState()` checks the object inventory on every open. Both known version-4 variants converge, proven by tests that derive each variant from the canonical schema. ADR-024.
3. **C3 — CLOSED.** `DeviceIdentityProbe` gives `NativeMountedProvider` an explicit `st_dev` comparison. A nested mount is recorded as metadata, not descended into, and raises one bounded scan issue so the skipped subtree is never presented as cleanly enumerated. Covered by a deterministic fake-probe test and by a real generated-HFS+-image regression test.
4. **C4 — CLOSED.** Three capture-time volume columns on `snapshots`, an immutability trigger, and a history repository that never reads `volumes`. Pre-version-5 snapshots show "Not recorded at capture time" rather than a back-filled value. ADR-023.
5. **C5 — CLOSED.** `CatalogProcessLock` takes an advisory `flock` before the catalog is opened and before recovery runs. Verified at runtime: a second launched process refuses with a user-facing message naming the holder. ADR-025.
6. **C6 — CLOSED.** `-FSDCatalogPath` / `FSD_CATALOG_PATH` in DEBUG builds, plus automatic isolation for XCTest hosts. ADR-026.

### What the C6 work uncovered

FSD's test bundle is hosted by the FSD application, so every `xcodebuild test` run started a real `ApplicationModel` against `~/Library/Application Support/FSD/catalog.sqlite3`. Before this was noticed, one test run in this session migrated that catalog from version 4 to version 5 and held the process lock on it. The migration is the intended forward migration and the catalog verified clean afterwards (1 snapshot, 45 entries, `complete`, `integrity_check` = `ok`, 0 classification rows), but it happened as a side effect rather than by the owner's action. It cannot recur: a test host now always resolves its own catalog under the temporary directory, verified by comparing the real catalog's SHA-256 across a full test run.
## Current control-plane gate

Fresh readiness validation (2026-10-03): clean Debug build and unfiltered
automated suite PASS — 293 executed, 290 passed, 0 failures, 3 intentionally
inert external probe skips. Bootstrap/migration, read-only boundaries and
the 1M comparison/memory/snapshot gates pass. This supports beginning a
separately authorized ADR-032 schema prerequisite; it does not authorize
implementation or claim owner manual acceptance. See the current Handoff.

M5 and the Phase 1.5 nullable enrichment boundary have completed their accepted
independent audits. Runtime design is complete; runtime implementation has not
started and requires a separately authorized schema change before runtime.
AI model/harness benchmarking is removed by the owner's 2026-10-03 directive;
no scoring, winner selection or benchmark patch selection remains an active or
future gate. Product performance validation remains required and unchanged.
Return the cleanup and fresh readiness evidence to BRAIN for adjudication;
no further product work is authorized by this task. Any separately authorized
runtime implementation must begin with ADR-032's schema prerequisite.
Manual acceptance remains **NOT PERFORMED — DEFERRED BY OWNER**; stock-macOS
NTFS and the separate legacy startup-error wording finding remain separately
tracked. The `.gemini-derived-data` hygiene observation is preserved.

## Release target

Internal alpha for macOS 13+ Apple Silicon. Local-only build; no Apple Developer account, notarization, or App Store distribution (ADR-006). Local development requires neither signing nor notarization.
