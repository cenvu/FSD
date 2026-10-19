# Product implementation baseline

This file owns implemented capabilities, implementation gaps and product
limitations. Accepted control task, gate, phase, classification and next decision
belong to [../STATE/PROJECT_STATE.md](../STATE/PROJECT_STATE.md); Worker continuity
belongs to [../handoffs/CURRENT_HANDOFF.md](../handoffs/CURRENT_HANDOFF.md).
Neither this baseline nor historical product evidence authorizes product work.

## Owner UX alignment — implementation support/gaps

**Accepted implementation:** Tasks047–052 provide Main/Home, offline Explore,
the Snapshot Collections organizer, and snapshot label/note editing. Phase 1.5
runtime also has final BRAIN technical acceptance. These are bounded accepted
slices; they do not mean FSD2 Full or full internal application acceptance is
complete. See [STATE/PROJECT_STATE.md](../STATE/PROJECT_STATE.md) and
[UX_UI_SPEC.md](UX_UI_SPEC.md).

**Supported foundations:** Read-only metadata capture; immutable snapshots and
interrupted-capture recovery; SQLite history and offline browse; lazy trees;
selected-entry detail and explicit classification; snapshot/snapshot
comparison persistence; bounded comparison paging; append-only classification
storage; Collection create/list/move; snapshot display-name and note editing.

**Partial foundations:** capture has no connected-drive UX; physical-drive
identity lacks an approved hardware strong profile or live observation adapter; current Collection
controls do not cover the full capture-organization/default flow; the dashboard
has no bounded aggregate facade; search lacks drive/library scope; comparison
navigation lacks ancestor projection; live-comparison retention remains
transient by default; Task062 adds an explicit backend Save and saved metadata reader, with no user-facing Save control yet.

**Exact gaps:** observation-only mount detection; opt-in Auto Capture (default
OFF); hardware-backed PhysicalDrive resolution and manual-association UI; paged
per-drive history; bounded dashboard aggregates; This Drive/Library
search; classification search; compare hierarchy/ancestor reveal; explicit
Save Comparison UI over the Task062 backend; full capture
organization/default controls; and consolidated rendered-window, accessibility,
and manual internal acceptance.

The Owner approved Wave A architecture direction on 2026-10-18. Three distinct
states must stay separated here:

- **Current implementation:** Tasks047–052 and the Phase 1.5 runtime, as listed
  below. Task058 adds a backend-only local PhysicalDrive/evidence/manual-assertion
  foundation (BRAIN-accepted with advisory); no hardware proof. Task059 adds a
  synthetic-input observation contract and fail-closed resolver/read seam
  (BRAIN-accepted with advisory), without live observation. Task060 adds manual
  Drive Sets with a production v11 repository and Library workspace (BRAIN-accepted
  with advisory). Task061 adds atomic comparison completion receipts in v12
  (BRAIN-accepted with advisory). Task062 adds the explicit saved evidence backend
  and offline reader in v13, pending BRAIN review.
- **Accepted feasibility (synthetic, not implementation):** Tasks054–056 are
  BRAIN-accepted `PASS_WITH_ADVISORY` for ADR-036 identity, ADR-037 Drive Sets and
  ADR-038 Save Comparison respectively. They are research and isolated synthetic
  SQLite/resolver prototypes only; they prove deterministic rule/relational
  behavior, not any product code, schema, hardware or migration.
- **Future FSD2 Full work (not started):** observation-only mount status, validated
  PhysicalDrive identity, manual-association UI, Save Comparison UI and the remaining UX/gaps below.

ADR-036–038 remain Proposed / Owner Direction Approved / Technical Proof Pending;
the identity evidence threshold/strong-profile set and durable saved-comparison
full acceptance remain `TECHNICAL_PROOF_PENDING`. Task061 supplies completion
receipt evidence; Task062 adds synthetic production saved-graph/migration proof
for BRAIN review. This work
does not promote ADR status or prove physical-device identity.
See [DECISIONS.md](DECISIONS.md), [MVP_PLAN.md](MVP_PLAN.md) and
[UX_UI_SPEC.md](UX_UI_SPEC.md). This status record authorizes no implementation.

## Implemented capabilities

- Native macOS 15+ arm64 SwiftUI app and XCTest target in `FSD.xcodeproj`.
- SQLite catalog schema **v13**; explicit transactional v4→v5 (both known v4
  variants), v5→v6, v6→v7, v7→v8, v8→v9 and additive v9→v10→v11→v12→v13 migrations. The v9 change appends nullable/no-default `provider_identifier`; legacy rows retain NULL without backfill. Fresh and migrated catalogs
  converge. `schema.sql` creates fresh catalogs only; `CatalogMigrations` moves
  existing ones. Complete ExpectedState inventory detects damaged/substituted
  schemas; per-connection foreign-key enforcement, normalization completion
  guards and integrity checks protect catalog data.
- Task061 immutable versioned comparison completion receipt: actual executed
  profile, exact orientation/key/warning contracts, completion-time headers/issues
  and terminal result closure commit atomically with success. Bounded typed
  metadata encoding, new completion token, fail-closed SQL validator, rollback and
  cancellation guards; legacy receiptless comparisons remain readable but
  ineligible for exact Save. No historical backfill or transient retention change.
  Task062 adds dedicated durable saved metadata backing and offline reopening;
  Save Comparison UI remains absent. See [ARCHITECTURE.md §17](ARCHITECTURE.md#17-atomic-comparison-completion-receipts--task061).
- Task058 local PhysicalDrive repository/model: opaque catalog-local UUIDs,
  explicit-local admission, duplicate labels, revision-protected retirement,
  immutable typed observations/evidence and append-only manual association,
  correction/revocation events. Backend only, no legacy attribution/backfill,
  no hardware match, observer, UI or capture integration. Approved real strong
  profiles remain empty. See [ARCHITECTURE.md §14](ARCHITECTURE.md#14-local-physicaldrive-foundation--task058)
  and [TEST_PLAN.md §14](TEST_PLAN.md#14-task058-production-local-identity-tests--synthetic-only).
- Task059 immutable synthetic observation envelopes, pure deterministic Conflict /
  ManualAssociation / Ambiguous / Unknown precedence and a bounded read-only seam
  over stored observations/manual assertions. Explicit candidate hypotheses,
  revision/retirement checks, alias lineage and deterministic ordering; no
  automatic matching, hardware verification, live observer, reconnect or capture.
  Schema v10 and historical facts remain unchanged. See
  [ARCHITECTURE.md §15](ARCHITECTURE.md#15-synthetic-observation-contract-and-resolver--task059)
  and [TEST_PLAN.md §15](TEST_PLAN.md#15-task059-synthetic-observation-and-fail-closed-resolver).
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
- Accepted Task051/052 Collection organizer surface: create/list Collections,
  move user snapshots by stable SnapshotID, preserve `Unsorted` as `NULL`, and
  edit snapshot display name and user note. Full capture-organization and
  remembered-default behavior remains incomplete.
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

- Full capture-organization sheet and remembered-default controls; the current
  Collection organizer supports create/list/move and snapshot label/note editing.
  Full intended semantics remain in [SNAPSHOT_COLLECTIONS.md](SNAPSHOT_COLLECTIONS.md).
- Observation-only mount detection, validated physical-drive identity,
  Auto Capture (which must default OFF), per-drive history, and
  explicit Save Comparison UI over the Task062 separate durable evidence backend.
- HTML export, catalog backup/restore, login-item support,
  EmbeddedRawProvider/reader-helper production integration, physical raw-device
  access, stock-macOS NTFS support proof, and multi-Library/cloud behavior.
  These remain visible PRD/MVP scope items or pending decisions; this status
  update does not remove or mark them complete.

## Phase 1.5 runtime verification status

**Current status (2026-10-18): Phase 1.5 runtime has final BRAIN technical
acceptance.** The accepted State records 29 of 30 requirements evidenced, one
not applicable, and zero unproven; clean arm64 Debug/Release builds, the
historical full Debug run (494 executed / 491 passed / 0 failed / 3 existing
external-probe skips), and the final focused audit (260/260) are part of that
accepted evidence. Task036's immutable review handoff is
[`FSD_P15_RUNTIME_FINAL_AUDIT_R_20261007-094654.md`](../handoffs/FSD_P15_RUNTIME_FINAL_AUDIT_R_20261007-094654.md);
the BRAIN acceptance and control-plane repair are recorded in
[STATE/PROJECT_STATE.md](../STATE/PROJECT_STATE.md). This technical acceptance
does not claim manual VoiceOver, physical-media, or full FSD2 Full internal
application acceptance.

filetype v1.1.3 is the BRAIN-accepted production provider; ADR-035 integration is implemented by task033A (`556872844b90640cc2a64e40d99594a78cef61af`) and independently audited by task034 (accepted `PASS_WITH_ADVISORY` at publication `9d1a8ea237c6c2941895b1c3640118371d2e2d4d`). Task035 verified the physical runtime and synchronized status. Its focused and supplemental suite counts remain historical evidence, not claims that this document change reran them. Exact task035 details are in [FSD_P15_WHOLE_RUNTIME_VERIFICATION_D_20261007-015634.md](../handoffs/FSD_P15_WHOLE_RUNTIME_VERIFICATION_D_20261007-015634.md).

Helper `FSD/Helpers/FSDClassificationHostSeam`, accepted SHA256 `665a6569ee60614313e50629c4166358b89859f15dac4c522905ee5a730752e7`; exact detector `github.com/h2non/filetype@v1.1.3`; host-owned provider `fsd.bundled-helper-host.v1`; classified model version/confidence nil. Fresh Debug/Release unsigned bundles contain byte-identical arm64/minos 13.0 helper at `Contents/Helpers/FSDClassificationHostSeam` and exact `Contents/Resources/THIRD_PARTY_NOTICES.txt`, with no Go construction/download/network in normal builds and no bundled Go cache/module/model/database. Scratch-copy ad-hoc deep/strict signing passed; no distribution readiness follows.

Seven typed outcomes remain classified, failed, sourceChanged, unsupportedEntry, unavailable, cancelled, noMatch. Four write rows; unavailable/cancelled/noMatch write none; busy remains control-only. noMatch fabricates no type or provenance row. Classification is offline inferred current-source metadata only; no sample/path/content-hash persistence, snapshot mutation, comparison-semantic influence or JSON format change. Explicit selected-entry action remains the sole trigger; no automatic invocation across the eight workflows, bulk/background action, queue, automatic retry, watcher or backfill. Detached-source browsing/history/export remains usable in automated deletion-fixture coverage; no physical unmount is claimed.

General realistic legacy DOC/XLS/PPT determinism remains unproven.
Available pinned realistic PNG/DOCX/XLSX/PPTX bounded fixtures were single-valued in accepted implementation/audit evidence.
The demonstrated short legacy-CFB ambiguity is neutralized by the guard.

Magika remains a blocked, non-exclusive candidate; its task025 evidence is preserved.

Residual limits: synthetic CFB discriminants prove adapter routing, not realistic legacy-file coverage; network/process observations cover six current real-helper runs only, corroborated by accepted historical static closure. Task033A/task034 controlled rebuild and notice/dependency closure are accepted historical evidence, not task035 reruns. Task034 Reviewer-only Go introspection telemetry counter is a process advisory, not a product defect; task035 invokes no Go and changes no Owner-global Go configuration/telemetry mode. Source authority is a point-in-time dev+ino proof, not a namespace lock. The accepted schema/provider whitespace-normalization advisory remains historical and is not repaired here. Manual UI, VoiceOver and physical-media acceptance remain **NOT PERFORMED — DEFERRED BY OWNER**. The final runtime audit and Phase 1.5 technical acceptance are complete; the manual and FSD2 Full internal-acceptance gates remain separate.

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
| KI-017 | Current default: live-side comparisons are workspace-scoped and transient evidence is disposed on close; only snapshot/snapshot records persist. ADR-038 now records the Owner-approved explicit Save Comparison direction using separate durable captured evidence. Task062 now implements separate copied backing, exact remapping, v13 migration, transactional rollback and offline reader using generated production-stack tests; UI and real storage durability remain `TECHNICAL_PROOF_PENDING`; never update a completed transient `snapshot_kind` in place. |
| KI-020 | Rendered-window appearance, VoiceOver and focus traversal await owner observation; no XCUITest target exists. Manual requirements/backlog are owned by [TEST_PLAN.md](TEST_PLAN.md) §8. |
| KI-025 | Implementation gap CLOSED by Task035 physical verification and final Task036/BRAIN acceptance: runtime implemented; schema-v9 provider identity and filetype helper integration are independently audited and accepted. This disposition satisfies the three existing absence conditions without redefining them. Manual acceptance remains deferred and separate. Evidence: [FSD_P15_WHOLE_RUNTIME_VERIFICATION_D_20261007-015634.md](../handoffs/FSD_P15_WHOLE_RUNTIME_VERIFICATION_D_20261007-015634.md) and the Task036 handoff above. |

The separately recorded legacy **startup-error wording** finding remains unresolved;
it is distinct from fixed capture and comparison error mappers. The ignored
`.gemini-derived-data` hygiene observation remains unresolved and its owner bytes
are preserved. Neither is repaired by documentation consolidation.

Manual acceptance remains **NOT PERFORMED — DEFERRED BY OWNER**; overall MVP
approval and notarized/distributable release readiness are **NOT CLAIMED**.
FSD2 Full internal application acceptance remains a separate pending gate;
Developer ID signing and notarization are not gates for that internal phase.
Deferred public distribution readiness remains a later Owner decision. Internal
alpha remains local-only macOS 15+ Apple Silicon (ADR-006); local development
needs no Apple Developer account, signing or notarization.

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

## Task060 — manually usable Drive Sets (pending BRAIN review)

Library → Drive Sets provides create, rename, delete, explicit add/remove and
paged local-record selection. Empty sets persist. Records may belong to several
sets; deleting a set deletes its memberships only. The add sheet can explicitly
create an **unverified local organization record**, then requires a separate Add
action. This does not detect hardware, associate an observation or start capture.
Records show **connection unknown**, never an invented connected/offline state;
retired members remain visible and removable. Stable IDs disambiguate equal labels.

Schema v11 adds only `drive_sets` and `drive_set_memberships`; no historical
identity or membership backfill. Versioned Foundation normalization handles
trim/NFC/case folding; SQLite NOCASE is not used as Unicode normalization.
Revision checks reject stale actions and bounded errors offer Refresh. Create
retries reuse the same opaque ID; repeated current membership is a no-op. A
stale retry must refresh. No tombstone/import/merge or live-availability service
is introduced. This is a local manual grouping slice, not the full ADR-037 future
identity/mount integration. Strong hardware profiles remain zero. Owner visual,
manual VoiceOver and real hardware acceptance are not claimed.


## Task062 — explicit saved comparison backend (pending BRAIN review)

Schema v13 and `SavedComparisonRepository` provide intentional metadata-only Save
and an offline reader over two independently copied evidence trees. Task061's
validated immutable receipt is required; legacy receiptless complete comparisons
remain ineligible. Profile/header/issues/orientation/warnings/summary archive by
value; entry/result/collision/parent IDs remap into a separate owned graph. No
original snapshot/comparison/source facts or normal transient cleanup change.

Single-transaction READY publication and permanent operation receipts provide
idempotent replay after original cleanup and non-resurrection after explicit
delete. Reader pages require sealed valid evidence and use no source media or
current profile/volume joins. Save is a backend API only: completion never saves
automatically, and Save button/full browsing UI/export are unimplemented.

Conservative production ceilings are100K accounted rows,256 MiB encoded metadata,
512 MiB logical SQLite growth and60s cooperative elapsed time, with256-row pages
and strict byte preflights. Generated10K-entry work is supported;100K entries plus
50K results is explicitly rejected before copy. Hardware, real power loss/disk
full, Owner catalog migration, UI/manual/VoiceOver and full FSD2 acceptance remain
unproved. ADR036/037/038 statuses and existing privacy advisories are unchanged.
