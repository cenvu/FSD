# Product implementation baseline

This file owns implemented capabilities, implementation gaps and product
limitations. Accepted control task, gate, phase, classification and next decision
belong to [../STATE/PROJECT_STATE.md](../STATE/PROJECT_STATE.md); Worker continuity
belongs to [../handoffs/CURRENT_HANDOFF.md](../handoffs/CURRENT_HANDOFF.md).
Neither this baseline nor historical product evidence authorizes product work.

## Owner UX alignment — implementation support/gaps

**Supported foundations:** Read-only metadata capture; immutable snapshots; interrupted capture; SQLite history/browse; lazy trees; selected-entry detail; snapshot/snapshot comparison persistence; bounded comparison paging; classification append-only storage.

**Partial foundations:** Offline state requires visual redesign; capture lacks connected-drive UX; identity lacks strong/ambiguous service; missing dashboard facade for recent data; search lacks scope abstraction; explicit selected-entry classification runtime is implemented (final acceptance pending); compare navigation lacks ancestor projection.

**Exact gaps:** Mount detection; optional Auto Capture; strong volume identity service; paged per-drive history; bounded dashboard aggregates; This Drive/Library search; classification search; compare hierarchy projection; exact reveal chain; Drive Set implementation; durable live-comparison retention; multi-Library/cloud; rendered-window/VoiceOver acceptance.

**ADR needed:**
1. PHYSICAL_DRIVE_IDENTITY_AND_MOUNT_POLICY
2. DRIVE_SET_SEMANTICS_VS_EXISTING_COLLECTIONS
3. DURABLE_LIVE_COMPARISON_SEMANTICS

See canonical target details in [UX_UI_SPEC.md](UX_UI_SPEC.md).

## Implemented capabilities

- Native macOS 15+ arm64 SwiftUI app and XCTest target in `FSD.xcodeproj`.
- SQLite catalog schema **v9**; explicit transactional v4→v5 (both known v4
  variants), v5→v6, v6→v7, v7→v8 and v8→v9 migrations. The v9 change appends nullable/no-default `provider_identifier`; legacy rows retain NULL without backfill. Fresh and migrated catalogs
  converge. `schema.sql` creates fresh catalogs only; `CatalogMigrations` moves
  existing ones. Complete ExpectedState inventory detects damaged/substituted
  schemas; per-connection foreign-key enforcement, normalization completion
  guards and integrity checks protect catalog data.
- Catalog-path override, automatic XCTest-host isolation and single-process
  catalog lock before open/recovery (ADR-025/026). Tests do not use the owner catalog.
- Metadata-only native mounted capture: detected source/capture-time volume
  facts, streaming scanner, batched transactional writer, cancellation, immutable
  completion and startup recovery. `st_dev` detects nested mounts, records their
  metadata without descent and emits a bounded scan issue. Symlinks are recorded
  without traversal; packages use their captured traversal policy.
- Offline snapshot history, lazy paged `NSOutlineView` browsing, bounded indexed
  metadata search, selected-entry inspector and deterministic streamed JSON
  export (format version 1; no classification).
- Bounded ordered-stream metadata comparison: snapshot/snapshot, live/snapshot
  and live/live through transient captures; frozen profile revisions; Fast
  Metadata, Structure Only and Strict Metadata; field differences, never-paired
  collision groups, normalization-version enforcement, terminal evidence guards,
  deterministic cancellation/orphan recovery, paging/filtering and cross-page
  next/previous navigation. Live workspace close follows ADR-012 disposal.
- Corrected comparison UI with bounded errors, canonical orientation, repository
  paging, details, accessibility labels and keyboard shortcuts. Capture errors
  use the shared bounded `CaptureErrorDescription`; internal diagnostics remain
  separate. v8's dedicated `comparison_results(parent_result_id)` index bounds
  final-scale disposal. Collision groups have a 100,000-member cap and fail typed
  beyond it (`ComparisonError.collisionGroupTooLarge`).
- Optional explicit selected-entry classification runtime: FSD-owned Data-only
  request and one no-follow 0...4096-byte current-source prefix read; app-scoped
  single-flight runtime, five-second inference-only deadline, cancellation/generation
  suppression, bounded helper process and selected-entry UI. BRAIN-accepted
  production provider is filetype v1.1.3 through audited ADR-035 integration;
  disabled provider remains available. Append-only classification
  repository, unique `(entry_id, classification_run_id)` rejection, nullable
  round-trip, bounded latest/history/visible-page and selected-entry presentation.
  Ordinary capture/browse/search/export/comparison never invoke inference.
  Classification cannot affect immutable entries, snapshot identity/totals/status
  or historical comparison outcomes. No old-snapshot backfill.

## Not implemented

- Collection UI, capture-organization sheet and Collection-facing repository/
  rename/move/note controls; schema/data foundations exist. Full intended semantics
  remain in [SNAPSHOT_COLLECTIONS.md](SNAPSHOT_COLLECTIONS.md).
- HTML export, automatic mount detection/capture, login-item support, full volume
  identity service, EmbeddedRawProvider/reader-helper production integration and
  physical raw-device access. These remain scoped roadmap requirements, not claims.

## Phase 1.5 runtime verification status

filetype v1.1.3 is the BRAIN-accepted production provider; ADR-035 integration is implemented by task033A (`556872844b90640cc2a64e40d99594a78cef61af`) and independently audited by task034 (accepted `PASS_WITH_ADVISORY` at publication `9d1a8ea237c6c2941895b1c3640118371d2e2d4d`). Task035 verifies the physical runtime and synchronizes status; final independent implementation audit and Phase 1.5 BRAIN acceptance remain pending. Task035 current verification: clean Debug/Release arm64 builds passed; full Debug 494 executed / 491 passed / 0 failed / 3 existing external-probe skips; focused classification/isolation/schema 242 executed / 242 passed / 0 failed / 0 skipped; supplemental schema-safety 18 executed / 18 passed / 0 failed / 0 skipped. Exact commands, durations and per-suite counts: [FSD_P15_WHOLE_RUNTIME_VERIFICATION_D_20261007-015634.md](../handoffs/FSD_P15_WHOLE_RUNTIME_VERIFICATION_D_20261007-015634.md).

Helper `FSD/Helpers/FSDClassificationHostSeam`, accepted SHA256 `665a6569ee60614313e50629c4166358b89859f15dac4c522905ee5a730752e7`; exact detector `github.com/h2non/filetype@v1.1.3`; host-owned provider `fsd.bundled-helper-host.v1`; classified model version/confidence nil. Fresh Debug/Release unsigned bundles contain byte-identical arm64/minos 13.0 helper at `Contents/Helpers/FSDClassificationHostSeam` and exact `Contents/Resources/THIRD_PARTY_NOTICES.txt`, with no Go construction/download/network in normal builds and no bundled Go cache/module/model/database. Scratch-copy ad-hoc deep/strict signing passed; no distribution readiness follows.

Seven typed outcomes remain classified, failed, sourceChanged, unsupportedEntry, unavailable, cancelled, noMatch. Four write rows; unavailable/cancelled/noMatch write none; busy remains control-only. noMatch fabricates no type or provenance row. Classification is offline inferred current-source metadata only; no sample/path/content-hash persistence, snapshot mutation, comparison-semantic influence or JSON format change. Explicit selected-entry action remains the sole trigger; no automatic invocation across the eight workflows, bulk/background action, queue, automatic retry, watcher or backfill. Detached-source browsing/history/export remains usable in automated deletion-fixture coverage; no physical unmount is claimed.

General realistic legacy DOC/XLS/PPT determinism remains unproven.
Available pinned realistic PNG/DOCX/XLSX/PPTX bounded fixtures were single-valued in accepted implementation/audit evidence.
The demonstrated short legacy-CFB ambiguity is neutralized by the guard.

Magika remains a blocked, non-exclusive candidate; its task025 evidence is preserved.

Residual limits: synthetic CFB discriminants prove adapter routing, not realistic legacy-file coverage; network/process observations cover six current real-helper runs only, corroborated by accepted historical static closure. Task033A/task034 controlled rebuild and notice/dependency closure are accepted historical evidence, not task035 reruns. Task034 Reviewer-only Go introspection telemetry counter is a process advisory, not a product defect; task035 invokes no Go and changes no Owner-global Go configuration/telemetry mode. Source authority is a point-in-time dev+ino proof, not a namespace lock. The accepted schema/provider whitespace-normalization advisory remains historical and is not repaired here. Manual UI, VoiceOver and physical-media acceptance remain **NOT PERFORMED — DEFERRED BY OWNER**. Independent final runtime audit and BRAIN Phase 1.5 acceptance are still required.

## Product limitations

Stable KI identifiers are retained for historical cross-reference interpretation.
This section is implementation baseline, not a parallel control issue ledger.

| IDs | Remaining limitation / specialized authority |
|---|---|
| KI-001 | Metadata equality is never content verification. Equal path/size can hide different bytes; disclosure is required by [PRD.md](PRD.md). |
| KI-002 | Capture spans an interval, not an atomic filesystem image. Store start/completion and report detected changes where possible. |
| KI-003 | UUIDs may be missing or cloned/duplicated; fallback fingerprint/manual physical label requirements remain. Do not infer identity from display/mount names. |
| KI-004 | Allocated bytes vary with filesystem, sparse files, clones and allocation units; logical size is the default. See [FILESYSTEM_SUPPORT_MATRIX.md](FILESYSTEM_SUPPORT_MATRIX.md). |
| KI-005, KI-014, KI-015 | Stock-macOS NTFS proof remains environment-blocked; third-party driver metadata is not characterized. FAT16/32 both report `msdos`; `filesystem_variant` records the mounting driver (`tuxera_ntfs` was observed), not guaranteed filesystem identity. Support evidence/behavior belongs to the support matrix. |
| KI-006 | Large trees require bounded lazy database-backed loading; eager OutlineGroup-only trees are unsuitable. Implemented paging does not remove this design constraint. |
| KI-007 | Network volumes remain experimental/deferred: latency, unstable identifiers and timestamp inconsistency are unproven. |
| KI-008 | Package policy affects counts and must be stored per snapshot; no silent traversal-policy equivalence. |
| KI-009, KI-010, KI-011 | Embedded parsers process untrusted disk structures; production integration and real physical-device/authopen behavior remain unproven. Native-readable families need no added reader dependency. Proof, libfsext conditions A/B/D/F and distribution-only LGPL condition C remain in [FILESYSTEM_FEASIBILITY_PLAN.md](FILESYSTEM_FEASIBILITY_PLAN.md), provider architecture and dependency/license review. |
| KI-012 | Remembered Collection defaults are volume-only. Folder/image/raw-partition sources fall through to active Collection then Unsorted; never invent path-based identity. [SNAPSHOT_COLLECTIONS.md](SNAPSHOT_COLLECTIONS.md) §9.3 owns this contract. |
| KI-013 | Milestone-2 snapshots captured before 2026-08-04 may silently lack a sibling subtree due to the fixed skipDescendants/symlink defect. The snapshot cannot reveal this residue; recapture important old data before trusting removed-entry conclusions. The owner's flat 45-entry A006C84S capture has not been source-reverified. |
| KI-016, KI-019, KI-023 | Aggregate-signature skipping and matched-subtree visual collapse are unimplemented. Per-entry matched evidence is correct. Public collision-member detail query is still absent. Over-cap equal-key groups fail typed and bounded; they cannot complete. |
| KI-017 | Live-side comparisons are workspace-scoped: cancel/dispose comparison then delete transient snapshots on close. Only snapshot/snapshot records persist in recent comparisons. Keep-live promotion requires an explicit design. |
| KI-020 | Rendered-window appearance, VoiceOver and focus traversal await owner observation; no XCUITest target exists. Manual requirements/backlog are owned by [TEST_PLAN.md](TEST_PLAN.md) §8. |
| KI-025 | Implementation gap CLOSED by task035 physical verification: runtime implemented, schema-v9 durable separate provider identity verified, and actual filetype helper integration independently audited/BRAIN-accepted. This disposition satisfies the three existing absence conditions without redefining them. Independent final runtime audit, Phase 1.5 BRAIN acceptance and deferred manual acceptance remain separate gates. Evidence: [FSD_P15_WHOLE_RUNTIME_VERIFICATION_D_20261007-015634.md](../handoffs/FSD_P15_WHOLE_RUNTIME_VERIFICATION_D_20261007-015634.md). |

The separately recorded legacy **startup-error wording** finding remains unresolved;
it is distinct from fixed capture and comparison error mappers. The ignored
`.gemini-derived-data` hygiene observation remains unresolved and its owner bytes
are preserved. Neither is repaired by documentation consolidation.

Manual acceptance remains **NOT PERFORMED — DEFERRED BY OWNER**; overall MVP
approval and notarized/distributable release readiness are **NOT CLAIMED**.
Internal alpha remains local-only macOS 15+ Apple Silicon (ADR-006); local
development needs no Apple Developer account, signing or notarization.

## Baseline evidence retrieval

Measurements and audit chronology stay in immutable evidence; this file does not
repeat logs or then-next instructions. Use the task ledger for control returns.

- `handoffs/FSD_M1_FOUNDATION_C_20260804-010259.md` — exact normalization and verification-fixture safeguards.
- `handoffs/FSD_M3_CLOSEOUT_C_20260804-131600.md` — offline history/capture-time facts and test-host isolation.
- `handoffs/FSD_M2_ACCEPTANCE_AUDIT_R_20260804-112704.md` — capture boundary audit.
- `handoffs/FSD_M5_PERFORMANCE_PREMVP_C_20260805-034539.md` — M5 final scale, bounded memory, races/recovery; fixed KI-022; superseded KI-018/019.
- `handoffs/FSD_M5_SCHEMA_V8_DISPOSAL_REAUDIT_A_20260805-223211.md` — accepted v8/disposal closure (KI-024); historical timings/tests belong there and in Test Plan.
- `handoffs/FSD_P15_MAGIKA_NULLABLE_ENRICHMENT_AUDIT_R_20260807-142313.md` — audited nullable boundary and residual startup/hygiene observations.
- `handoffs/FSD_P15_MAGIKA_RUNTIME_DESIGN_A_20260807-155630.md` — completed runtime design, not implementation.
- `handoffs/FSD_MODEL_BENCHMARK_PURGE_READINESS_D_20261003-220825.md` — dated automated readiness evidence; no manual acceptance or product progression.

KI-021/022/024 fixed narratives and older gate corrections are recoverable from
those handoffs and Git history; they are not current blockers.
