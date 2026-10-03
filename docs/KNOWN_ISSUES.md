# Known Issues and Open Risks

## KI-025 — Magika runtime inference remains inactive after nullable-boundary preparation

Phase 1.5 currently provides a typed local-only provider boundary, disabled
provider, nullable schema-v8 repository and bounded history/detail
presentation. No Magika model or dependency is installed, no inference runs,
and no ordinary workflow reads payload bytes or backfills old snapshots.
Classification is inferred, optional and non-authoritative; comparison
semantics and canonical JSON export ignore it. Schema v8 has detector/model
provenance fields but no separate provider-identifier column, so the adapter
identifier remains runtime-only. The completed runtime design (ADR-032,
`handoffs/FSD_P15_MAGIKA_RUNTIME_DESIGN_A_20260807-155630.md`) requires a
separately authorized schema change before runtime; schema remains v8 and
runtime implementation is not started/inactive.
Manual acceptance remains **NOT PERFORMED — DEFERRED BY OWNER**.

## KI-001 — Metadata equality is not content verification

Two files can have the same relative path and logical size while containing different bytes. The application must always disclose this limitation.

## KI-002 — Snapshot is captured over an interval

A live volume may change while scanning. The snapshot is not an atomic filesystem image. Store scan start and completion times and report detected changes where possible.

## KI-003 — Volume UUID may be unavailable or duplicated

Some filesystems do not provide a stable UUID. Cloned filesystems may expose duplicate identities. A fallback fingerprint and manual physical label are required.

## KI-004 — Allocated size is not portable

Allocated bytes can differ between filesystems, sparse files, APFS clones and allocation unit sizes. Logical size is the default comparison field.

## KI-005 — NTFS read access is native but write-capable third-party drivers change what's mounted

macOS mounts NTFS read-only natively, with no third-party driver required (`DEPENDENCY_AND_LICENSE_REVIEW.md` §2) — FSD only ever needs read access, so this is not a dependency risk for FSD specifically. The residual risk is narrower: if the user has a write-capable third-party NTFS driver installed (e.g. Paragon, Tuxera) for their own purposes, that driver — not macOS's native read-only path — may end up mounting the volume, and its metadata reporting (timestamp precision, resource identifier stability) has not been characterized and may differ from the native driver's. Record which mount path served a given capture where feasible.

## KI-006 — Very large trees require lazy UI loading

SwiftUI `OutlineGroup` alone may perform poorly for hundreds of thousands of entries. Use `NSOutlineView` backed by paged SQLite queries.

## KI-007 — Network volume behavior is not guaranteed in MVP

SMB and other network filesystems can expose high latency, unstable identifiers and inconsistent timestamps. Treat network support as experimental until tested.

## KI-008 — Package traversal changes expected counts

Finder packages may be treated as single items or expanded directories. The chosen capture policy must be stored with each snapshot.

## KI-009 — Embedded ext2/3/4 reader is new, third-party, untrusted-input attack surface

libfsext (or its TSK fallback) parses on-disk structures FSD did not create and cannot assume are well-formed. It is isolated in a separate reader helper process specifically because of this (`FILESYSTEM_PROVIDER_ARCHITECTURE.md` §8), but it is new to FSD and unproven until Phase 0A/2 (`FILESYSTEM_FEASIBILITY_PLAN.md`) completes against real and adversarial fixtures, including non-UTF-8 filenames and fscrypt-encrypted subtrees.

## KI-010 — Raw-device authorization mechanics are unverified

Whether a read-only raw partition device node (`/dev/rdiskN`) can be opened directly, or requires a scoped `authopen` authorization prompt, is not settled by research alone and varies by media class and macOS version in the sources consulted (`DEPENDENCY_AND_LICENSE_REVIEW.md` §4). This must be proven empirically on real hardware in Phase 3 before it is treated as reliable.

## KI-011 — Most required filesystems needed no new dependency at all

APFS, HFS+, FAT16, FAT32, exFAT, NTFS (read-only), and UDF are all natively readable by macOS across the 13–26 range with no user-installed driver — see `DEPENDENCY_AND_LICENSE_REVIEW.md` §2. This is recorded as a known-issue-adjacent fact, not a risk: it substantially narrows the surface this replan needed to solve, and a future contributor should not reintroduce a third-party dependency for any of these seven filesystems without first re-reading that section.

## KI-012 — Remembered Collection defaults only cover volume sources

`source_collection_defaults` is scoped to `source_kind = 'volume'` in schema version 3. A live folder, a disk image, or a raw partition has no canonical, non-fragile identity to key a remembered default on yet (`SNAPSHOT_COLLECTIONS.md` §9.3, `DECISIONS.md` ADR-020). Capturing one of these source kinds always falls through to the Section 5.1/7 waterfall's lower steps (active-Collection-in-UI, then `Unsorted`) rather than a remembered default — this is a documented scope boundary, not a bug, and is not silently worked around with a path-based key.

## KI-013 — Snapshots captured before 2026-08-04 may be missing a subtree

Milestone 2's `NativeMountedProvider` called `enumerator.skipDescendants()` for symbolic links as well as packages. `skipDescendants()` skips "the most recently obtained subdirectory"; a symlink is not one, so the enumerator skipped descent into the *next* directory at that level instead, omitting that subtree from the snapshot with no scan issue and no error. Whether it triggered depended on enumeration order, which is directory order rather than alphabetical.

Fixed in Milestone 3 (descendants are skipped for packages only; `FileManager.enumerator` never follows a symlink to a directory in the first place, so the call was never needed). Three regression tests cover it.

The residue is in data, not code: any snapshot captured by Milestone 2 code may be incomplete, and a comparison against one could report false "removed" entries. There is no way to detect this from the snapshot itself. Re-capture anything taken before 2026-08-04 that matters.

## KI-014 — FAT16 and FAT32 are indistinguishable to FSD

Both mount through `msdosfs` and `statfs` reports `msdos` for each, so `filesystem_variant` cannot tell them apart (empirically confirmed 2026-08-04, `FILESYSTEM_SUPPORT_MATRIX.md` §2.1). Nothing in the MVP depends on the distinction. Recorded so that no later feature assumes it exists.

## KI-015 — `filesystem_variant` records the driver, not the filesystem

`filesystem_variant` comes from `statfs.f_fstypename`, which names whatever driver mounted the volume. An NTFS volume mounted by third-party software records `tuxera_ntfs`, not `ntfs` (observed 2026-08-04). Any future code that keys behaviour on `filesystem_variant` must treat it as a driver identifier and tolerate values FSD has never seen.

## KI-016 — Matched-subtree collapse via aggregate signatures is not implemented

The Milestone 4 backend compares per entry and stores one result row per
entry, so a fully matched branch produces as many `matched` rows as it has
entries. The PRD's "matched subtrees can be collapsed" behavior is data-side
available (contiguous `matched` rows under a common `result_path` prefix) but
the aggregate-signature subtree skipping and the visual collapse are not
implemented; the visual collapse is a GUI task. This does not affect
classification correctness — only the amount of stored `matched` evidence and
the eventual rendering strategy.

## KI-017 — Live-side comparisons are workspace-scoped by design

Closing a comparison workspace disposes comparison records whose sides
include a transient snapshot (cancelling any running ones first) and then
deletes the transient snapshots, per ADR-012's "cleaned up on close". Only
snapshot-to-snapshot comparisons persist in the recent-comparisons list. A
future "keep this live comparison" feature would need an explicit promotion
path; it is deliberately not invented here.

## KI-018 — The Milestone 4 scale gate ran at 100,202 entries per side — SUPERSEDED 2026-08-04

The M4 comparison gate is the 100,000-entry class: 100,202 entries per side
(100,000 files + directories + one-sided branches), measured in a Debug
build. **Superseded by the Milestone 5 final-scale gate**: the 1,000,000-entry
class now runs (1,003,104 vs 1,003,205 entries per side) with exact
classification, determinism, cancellation, navigation, disposal and memory
evidence — see the Milestone 5 Handoff and `TEST_PLAN.md` §4/§5.

## KI-019 — A pathological equal-key collision group is not page-bounded — SUPERSEDED 2026-08-04

`ComparisonEngine.EntryStream.consumeGroup` materializes one entire
equal-key collision group in an array before persisting it. Ordinary keys are
page-bounded, but a single pathological key with hundreds of thousands of
members could exceed the normal page memory bound for one group. This
follow-up condition from the Milestone 4 audit is **superseded by KI-023**:
Milestone 5 added an explicit safe cap (100,000 members) that turns the
condition into a typed failure, and the pathological case is verified bounded
at final scale. The repository still has no public collision-member detail
query (the GUI conflict view would need one) — unchanged, GUI follow-up only.
Peak comparison memory is now measured (see the Milestone 5 Handoff memory
evidence).

## KI-020 — Comparison GUI appearance and VoiceOver spot-check await the owner

The corrected comparison interface is verified at the model and source
boundary (orientation, paging, navigation, lifecycle, details, errors,
accessibility labels, keyboard commands) and at the process level
(Agent-observed launch: destination loads history, eligible snapshots,
profiles and outcome counts; owner catalog untouched; classification rows
zero). What has not been observed by a human: the rendered window, VoiceOver
behaviour and keyboard focus traversal in the running app — no XCUITest
target exists and Manual Session B (B7, B11) remains **NOT PERFORMED —
DEFERRED BY OWNER**. This is bounded visual/UX polish and deferred manual
acceptance, not a functional blocker. Matched-subtree visual collapse also
remains deferred with the GUI per `MVP_PLAN.md` (the backend never aggregates
matched subtrees).

## KI-021 — Live-capture error text in the comparison GUI was unbounded — FIXED 2026-08-04

`ComparisonUIErrorDescription.message(for: SnapshotScannerError)` previously
interpolated the string carried by `.captureFailed`, which `SnapshotScanner`
populates from an underlying error's `localizedDescription`, so a
live-capture/database failure could expose implementation details in the
visible comparison error. The corrected GUI re-audit recorded this as a
rejection-level closeout defect on 2026-08-04. Fixed 2026-08-04
(`handoffs/FSD_M4_GUI_BOUNDED_ERROR_FIX_C_20260804-180141.md`): the visible
mapping is now a fixed bounded message ("Metadata capture failed. Verify that
the source is available and try again."), never interpolating the carried
string; typed distinctions (cancellation, provider/unavailable source,
ineligible snapshot, catalog failure) remain bounded and distinct; a regression
test proves two arbitrary underlying messages produce identical safe visible
text. The underlying diagnostic (including `SnapshotScannerError.errorDescription`)
is unchanged. Milestone 5 remains not authorized until one focused independent
Codex re-audit of this correction accepted the GUI with conditions. The
separate legacy capture-surface issue below is not a comparison-GUI defect.

## KI-022 — Legacy capture UI may expose raw capture error text — FIXED 2026-08-04

The older capture screen in `FSD/App/FSDApp.swift` previously stored
`SnapshotScannerError.localizedDescription` and generic `error.localizedDescription`
directly in its capture-state failure text — arbitrary SQLite, POSIX/Cocoa,
filesystem, path and provider diagnostics could reach the visible capture UI.
This path was separate from the Milestone 4 comparison destination, whose
visible failures were already mapped through `ComparisonUIErrorDescription`.

**Fixed 2026-08-04** (Milestone 5, `handoffs/FSD_M5_PERFORMANCE_PREMVP_C_20260805-034539.md`):
`FSD/App/CaptureErrorDescription.swift` now provides one shared bounded
mapper, applied consistently at both failure sites in `FSDApp.swift`. The
visible capture UI shows fixed or safely typed wording (capture failure,
provider/unavailable source, catalog failure, detector failure, cancellation
and a fixed fallback all stay distinct and bounded); the raw diagnostic is
retained only on the internal standard-error channel via
`CaptureErrorDescription.diagnosticLine`, and the capture view now renders the
bounded failure text. Adversarial regression tests
(`FSDTests/CaptureErrorBoundaryTests.swift`) prove two arbitrary hostile
diagnostics produce identical bounded visible text, that SQL/path/provider
tokens never reach visible strings, and that the production source assigns
only bounded text to the capture state. Diagnostics remain available
internally; no raw SQLite message or private path is displayed.

## KI-024 — Whole-comparison disposal at final scale — RE-AUDIT CLOSED 2026-08-05 (`handoffs/FSD_M5_SCHEMA_V8_DISPOSAL_REAUDIT_A_20260805-223211.md`, APPROVE WITH CONDITIONS)

**Current closure amendment:** the accepted re-audit closes the technical
schema-v8/disposal gate. Its reporting-only test-count condition is already
corrected in `TEST_PLAN.md` (284 executed, 281 passed, 0 failed, 3 skipped).
Manual acceptance remains **NOT PERFORMED — DEFERRED BY OWNER** and overall
MVP approval is **NOT CLAIMED**. The diagnoses and correction-stage next
action below are retained as historical context, not current blockers.

**Independent pre-MVP audit finding (2026-08-05,
`handoffs/FSD_M5_FINAL_PREMVP_AUDIT_R_20260805-093249.md`):** the root cause
below is confirmed exactly (independently reproduced via a scratch SQLite
database: `EXPLAIN QUERY PLAN` shows a full table scan on
`parent_result_id`, and timed disposal runs show textbook O(n²) scaling that
a scratch-only index resolves entirely — 1,000,000-row disposal drops from
an unbounded multi-hour operation to ~5 seconds with clean integrity). What
changes the classification from "accepted non-safety limitation" to
**MVP TECHNICAL BLOCKER** was that `TransientSnapshotLifecycle.closeWorkspace()`
disposes **every** live-to-snapshot or live-to-live comparison automatically
on ordinary workspace close — not a separate, deliberate, infrequent "delete"
action — and neither it nor `ComparisonResultRepository.deleteComparison(_:)`
accepts a cancellation token. At the 1,000,000-entry class this makes
closing an ordinary live comparison workspace an unbounded, uncancellable,
single-writer-blocking operation. Data integrity itself is not at risk
(the cascade is transactional; interruption rolls back safely), but this
is not the bounded, infrequent condition previously recorded here. Schema
version 8 (a dedicated index on `comparison_results(parent_result_id)`) is now
implemented; see the correction Handoff for the exact evidence and next
action.

Original diagnosis (2026-08-04), superseded by the schema-v8 correction —
the technical description below describes the pre-v8 schema and measurements:

Deleting a whole comparison (`ComparisonResultRepository.deleteComparison`,
the explicit disposal API) cascades to `comparison_results`,
`comparison_collision_groups` and `comparison_collision_members`. At the
1,000,000-entry class (1,003,806 result rows) the cascade is O(n²) and does
not complete in a practical time: measured in progress at over 45 minutes of
Debug (`-Onone`) wall time with no completion. Root cause (verified against
the schema): `comparison_results.parent_result_id` is a self-referential
foreign key (`REFERENCES comparison_results(id) ON DELETE CASCADE`), and no
index has `parent_result_id` as its leading column
(`idx_comparison_results_parent` starts with `comparison_id`), so SQLite's
per-row FK enforcement scans the whole result table for every cascaded
delete. The fix is a dedicated index on
`comparison_results(parent_result_id)` — a schema change requiring schema
version 8, which the Milestone 5 task explicitly forbids for performance-only
work, so it is deferred with this precise diagnosis for the pre-MVP audit.
Correctness is unaffected: disposal at the class where it completes (100,202
entries per side, 100,303 result rows) finishes with zero residue, immutable
snapshots, `integrity_check` ok and `foreign_key_check` clean
(`FinalScaleComparisonTests.testHundredThousandDisposalLeavesNoResidue`),
and the M4 schema-safety suite verifies the same cascade semantics at small
scale. The correction is additive and changes performance only: no comparison
semantics, ordering, outcome counts, paging, navigation, collision behavior,
terminal immutability or disposal policy changed. Release regressions with
exactly 1,000,000 result rows complete explicit disposal in 9.930 s and
canonical live workspace close in 10.018 s, both under the 120-second
threshold. Both paths preserve ordinary snapshots, clean transient snapshots
according to policy, allow a subsequent write, and finish with clean
integrity/foreign-key checks. At the correction stage, the focused independent
re-audit was the only next action; the closure amendment above supersedes it.
MVP approval is not claimed. Manual acceptance remains
**NOT PERFORMED — DEFERRED BY OWNER**.

## KI-023 — A pathological equal-key collision group is a typed failure, not a memory hazard — CLOSED 2026-08-04

Milestone 5 replaced KI-019's follow-up condition with an explicit safe cap:
`ComparisonEngine.maxCollisionGroupMemberCount` (100,000) bounds the
materialized member array of any single equal-key collision group.
`EntryStream.consumeGroup` throws the typed `ComparisonError.collisionGroupTooLarge`
beyond the cap, the comparison terminalizes `failed` (never `complete`), and
the GUI maps it to bounded fixed wording. Verified at final scale: a fixture
of 150,000 case-variant members per side folds to one key, fails typed with a
bounded memory peak, and leaves `integrity_check` and `foreign_key_check`
clean (`FinalScaleMemoryProbeTests.testPathologicalEqualKeyCollisionGroupIsATypedFailureNotAnOOM`).
Ordinary keys are page-bounded; a legitimate group is two to a handful of
members, so the ceiling is far above any real key. KI-019's remaining
sub-point (no public collision-member detail query for the GUI conflict view)
is unchanged and remains a GUI follow-up, not a correctness defect.
