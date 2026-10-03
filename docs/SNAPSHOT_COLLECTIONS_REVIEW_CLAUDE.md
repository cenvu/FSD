# FSD Snapshot Collections Review

> Historical reference only. Original schema/status/findings/then-next language
> below is dated evidence, not live control authority. Use `STATE/PROJECT_STATE.md`
> for control, `PRODUCT_STATE.md` for implementation and `MVP_PLAN.md` for roadmap.
> Retired paths in the original body are historical citations: retrieve exact
> bytes with `git show 041d2af2076ff4418f9ea5d98b124c435ea8db43:<repo-relative-path>`.
> Former known-issue IDs resolve in `docs/PRODUCT_STATE.md`; bundle/manifest/support
> citations have Git-history-only recovery. Original body is preserved verbatim.

- **Task:** FSD-COLLECTIONS-REPLAN-0724-05
- **Date:** 2026-07-24
- **Scope:** documentation, data model, UX, and review only. No production Swift code, no Xcode project, no filesystem feasibility testing, no physical disk access, no Git initialization.

## Executive Verdict

The requirement is straightforward to satisfy without expanding FSD into a project-management tool: a `Collection` is a purely logical grouping row in SQLite, snapshots gain three mutable metadata fields (`collection_id`, `display_name`, `user_note`), and one small table remembers a default Collection per stable source. Every hard case the brief flagged — `Unsorted` representation, duplicate names, non-blocking automatic capture, source-identity fragility, deletion cascades — has a single clearly-simpler answer once SQLite's own `NULL`/`ON DELETE SET NULL`/`ON DELETE CASCADE` semantics are used as designed, rather than modeled around. Schema version 3 was written, applied to a fresh database, and exercised against 16 new fixtures (creation, blank/duplicate rejection, rename, deletion cascades, defaults save/replace/remove/collision-safety, cross-Collection moves, search-with-context) — all passed exactly as designed, including every fixture expected to fail. Full specification: [`SNAPSHOT_COLLECTIONS.md`](SNAPSHOT_COLLECTIONS.md).

One scope boundary is deliberately incomplete and explicitly documented, not silently worked around: remembered source defaults only work for volume sources in this schema version, because no canonical, non-fragile identity table exists yet for live folders, disk images, or raw partitions. Building one is out of this task's scope and is recorded as a deferred prerequisite, not a bug.

## User Problem

A snapshot identified only by a technical session number and a capture timestamp is correct but not how a person recognizes their own work. Users think in terms of client/project/production codes (`XYZ`, `ABC`, `NA`, `CEN`), want a human-facing label first with the technical identity always available underneath, and cannot be asked to re-select an organization for a card that's about to be yanked out of the reader.

## Recommended Product Model

**Term: `Collection`** — no clearer term was found; it reads as "a client's or project's snapshots grouped together" without implying a folder, a workflow, or a physical location. A Collection is logical catalog metadata only: never a folder on a source volume, never a directory of separate databases, never a mutation of snapshot contents, never a filesystem operation, never a replacement for volume identity. The SQLite catalog remains the single source of truth, unchanged in that role by this feature. Full semantics: `SNAPSHOT_COLLECTIONS.md` §2–3.

## Collection Semantics

A Collection has a required Unicode `name` (blank rejected), an optional `note`, `created_at`/`updated_at`, and a `last_used_at` that advances when a snapshot is assigned/moved into it. **Duplicate names are rejected outright**, compared using the same normalization recipe already established for path identity (ADR-009: NFC + locale-independent case fold) applied to the whole name string, enforced by a `UNIQUE(normalized_name)` constraint — tested and confirmed to reject `"xyz"` after `"XYZ"` exists. Renaming changes `name`/`normalized_name` only; `id` — the only thing a snapshot's foreign key references — never changes, so renaming cannot affect snapshot identity, tested and confirmed. MVP excludes nested Collections, tags, sharing, cloud sync, permissions, billing, and production-management workflows — a snapshot belongs to zero or one Collection, never more, never a hierarchy. Full detail: `SNAPSHOT_COLLECTIONS.md` §3.

**`Unsorted` model decision:** evaluated a built-in system Collection row versus `NULL collection_id` displayed as `Unsorted`. Chose `NULL` — it needs no protected row, no rename/delete special-casing, and is exactly what `ON DELETE SET NULL` already expresses natively for "this snapshot's Collection went away." Full reasoning: `SNAPSHOT_COLLECTIONS.md` §4, `DECISIONS.md` ADR-019.

## Manual Capture Flow

A capture-organization sheet (Source / Collection / Snapshot name / "Use this Collection by default for this source" checkbox) appears before a manual capture starts. Collection: choose existing, create new, or none. Name: optional; if blank, `display_name` is generated once at capture time as `<source display name> — <capture date/time>` and behaves exactly like a user-typed name from then on (renamable, no ongoing "is this generated" distinction). The Collection field is **prefilled**, never locked, using this waterfall: (2) remembered default for the exact source, shown as such → (3) the Collection the user was actively viewing when they initiated capture, if any → (4) `Unsorted`; whatever the user leaves selected when they start capture (1) is simply the final result of that prefill, editable at any point. Neither the snapshot id, `session_number`, nor any capture timestamp is affected by anything in this sheet. Full detail: `SNAPSHOT_COLLECTIONS.md` §5.

## Automatic Capture Flow

No sheet, ever — an automatic mount event uses only the last two waterfall steps: remembered default if one exists, otherwise `Unsorted`, always, with a non-blocking notification/catalog indicator inviting later reclassification. Capture is never cancelled, delayed, or held open because a Collection hasn't been chosen — removable media can disconnect within seconds, and organization is explicitly lower priority than getting the metadata at all. Full detail: `SNAPSHOT_COLLECTIONS.md` §7; `MVP_PLAN.md` Phase 7 now names this as the exact rule Phase 7 must consume from Phase 4's data layer, not reinvent.

## Source Default Rules

`source_collection_defaults` remembers one Collection per stable source identity, upserted (saving again replaces, never duplicates) and removable with a plain delete — all three operations (save/replace/remove) tested. **Identity is never a display name or a current mount path** — two differently-identified sources that happen to share a display name (tested: two volumes both capable of being named identically) get independent defaults because the key is `volume_id`, an integer foreign key into the existing `volumes` identity table (persistent UUID or fallback fingerprint), never a string. This is implemented for **volume sources only** in schema v3 — see Database Model below for why. Full detail: `SNAPSHOT_COLLECTIONS.md` §6, §9.3.

## Database Model

Schema version 3, applied fresh and verified (`PRAGMA integrity_check` = `ok`, `PRAGMA foreign_key_check` = clean, all three migration versions recorded):

- **`collections`**: `id`, `name`, `normalized_name` (`UNIQUE`), `note`, `created_at`, `updated_at`, `last_used_at`. Blank names rejected by `CHECK (trim(name) != '')`. No system/reserved row.
- **`snapshots` additions**: `collection_id` (nullable FK → `collections.id`, `ON DELETE SET NULL`), `display_name` (`NOT NULL`, blank rejected), `user_note` (nullable). None of the technical identifier fields were touched.
- **`source_collection_defaults`**: `id`, `source_kind` (enumerated `volume`/`folder`/`disk_image`/`raw_partition`, but a `CHECK` currently requires `source_kind = 'volume' AND volume_id IS NOT NULL` — the other three are reserved, not usable, until a normalized non-volume source-identity table exists), `volume_id` (FK → `volumes.id`, `ON DELETE CASCADE`), `collection_id` (FK → `collections.id`, `ON DELETE CASCADE`, `NOT NULL`), `created_at`, `updated_at`, `UNIQUE(source_kind, volume_id)`.
- **Why volume-only:** `volumes` already has a real canonical identity (UUID or fallback fingerprint) with an integer primary key. No equivalent table exists for a live folder (would need a security-scoped bookmark plus a stable file identifier — no schema representation today), a disk image, or a raw partition (currently only per-snapshot capture-time facts on `snapshots`, not a standalone identity record). Inventing a path- or device-node-based text key would be exactly the fragile key the brief warned against — **this requirement is recorded explicitly** (`SNAPSHOT_COLLECTIONS.md` §9.3, `DECISIONS.md` ADR-020, `KNOWN_ISSUES.md` KI-012) rather than worked around.
- **Comparison history:** remains entirely outside Collections for MVP (option 1 of the three weighed) — comparisons today are transient working state, not a saved user-managed artifact. If a "saved comparison session" feature is ever built, assigning a Collection only at the moment of explicit save (option 3) is the natural extension, added then. No schema gap exists today because no comparison-saving feature exists today.
- **Migration:** version 3 is additive only; versions 1 and 2 (R0 corrections, filesystem-provider metadata) are unchanged and re-verified alongside the new fixtures.

## Snapshot Immutability Boundary

`collection_id`, `display_name`, and `user_note` are the **only** fields this feature adds, and they are the only fields it ever changes. Tested directly: moving snapshot 9 between two Collections left its `entries` count, `started_at`, and `session_number` identical before and after (`database/verify.sql` fixture 37) — a single-row `UPDATE`, no rescan, no duplicated entries, no altered comparison result. Deleting a Collection with an assigned snapshot (fixture 36) left the snapshot row fully intact with `collection_id` set to `NULL` — confirmed via direct query, not inferred.

## Collection Deletion Behavior

Tested directly (fixture 36): deleting a `collections` row (a) detaches every snapshot pointing at it to `NULL`/`Unsorted` via the database's own `ON DELETE SET NULL` — no application loop, no missed row possible; (b) removes every `source_collection_defaults` row pointing at it via `ON DELETE CASCADE` — a default of a deleted Collection is meaningless and is removed outright, not silently repointed at `Unsorted`; (c) never deletes a snapshot, entry, or comparison row — snapshot deletion remains the separate, explicit, pre-existing action it always was, in either direction.

## UI and Navigation

Sidebar: a `Collections` section (`All Snapshots`, `Unsorted`, then user Collections) kept structurally separate from `Live Volumes`/`Recent Sources` — Collections and physical volumes are different identity models and are never merged. Snapshot rows lead with `display_name`, then source, capture date, filesystem, status, online/offline state — never a raw session id or UUID as the primary title (it remains one click away in the inspector). Editing surface: rename display name, move between Collections, edit note, create/rename Collections, remove/replace a remembered default — every one of these is local catalog metadata, touching nothing on any source volume. Full wireframes added to `UX_UI_SPEC.md` §2–3.1, §6, §8.

## Search and Filtering

The offline catalog searches by Collection name, snapshot display name, source name, captured path, capture date, filesystem, and status — entirely against the local catalog, never requiring the source attached. Every result surfaces its Collection (or `Unsorted`) — proven with a working query in `database/verify.sql` fixture 38 (`LEFT JOIN collections ... COALESCE(c.name, 'Unsorted')`), not just asserted.

## Comparison Workspace Impact

A Collection is not draggable into a comparison pane — dropping one would be ambiguous (compare against which snapshot inside it?) and "compare everything in a Collection" is exactly the kind of unrequested bulk behavior this feature must not introduce. A snapshot dragged out of a Collection's own listing is an ordinary comparison source, no different from one dragged from anywhere else. The comparison pane's existing acceptance of a live folder, live volume, saved snapshot, or snapshot subfolder (`FILESYSTEM_REPLAN_CLAUDE.md`) is unmodified by this feature.

## Phase Plan Impact

No new major phase. Folded into the existing sequence: **Phase 4** gains the Collection schema, the data layer behind the capture-organization sheet, source-default persistence, `Unsorted` behavior, snapshot reclassification, and the immutable-boundary tests; **Phase 5** gains the Collection sidebar, the capture-organization sheet's actual UI, search/filtering with Collection context, and rename/move/note/default-management controls; **Phase 7** (automatic capture) now explicitly consumes Phase 4's default-lookup rule rather than reinventing it. Exact per-phase deliverables and exit criteria: `MVP_PLAN.md` Phases 4/5/7.

## Tests

All 19 items from the brief's required test list are planned in `TEST_PLAN.md` §7, and the schema-level subset (creation/rejection/rename/deletion-cascade/defaults/reclassification/search-context/migration) was **already executed**, not just planned, against a fresh SQLite database in `database/verify.sql` fixtures 23–38: every expected success succeeded, every expected failure failed with the correct constraint (blank Collection name, duplicate normalized name, blank display name, non-`'volume'` `source_kind`, `NULL volume_id` with `source_kind = 'volume'`), and both `PRAGMA integrity_check` and `PRAGMA foreign_key_check` were clean before and after. The remaining items (manual-capture preselection, automatic-capture fallback, the sheet's own UI behavior) require application code and are deferred to Phase 4/5/7 as planned, not fabricated here.

## Risks

- **Non-volume source defaults are a known, documented gap** (`KNOWN_ISSUES.md` KI-012) — not a correctness risk, since the fallback (waterfall steps 3/4) is well-defined and never produces a wrong or silently-broken default; it is a feature-completeness gap that will need a normalized source-identity table to close.
- **Generated `display_name` freezes the date/time formatting active at capture time.** If a user later changes locale/format preferences, older generated names won't retroactively reformat. Accepted: a display name is just a label the user can always rename, and re-deriving it live on every render would need its own cache-invalidation reasoning for no clear product benefit.
- **`last_used_at`'s exact update trigger (assignment/move only, not viewing) is a product-feel choice**, not empirically validated against real usage — low risk, cheap to revisit post-MVP if "recent Collections" ordering feels wrong in practice.

## Deferred Features

- A normalized source-identity table for folders/disk-images/raw-partitions, which would extend `source_collection_defaults` beyond volumes (`SNAPSHOT_COLLECTIONS.md` §9.3, `DECISIONS.md` ADR-020).
- Collection assignment for saved comparison sessions, if that feature is ever built (`SNAPSHOT_COLLECTIONS.md` §9.4).
- Nested Collections, tags, sharing, cloud sync, permissions, billing, production-management workflows — explicitly and permanently out of scope, not merely deferred (`SNAPSHOT_COLLECTIONS.md` §3).

## Final Verdict

**READY FOR INDEPENDENT AUDIT.**

The Collection specification, schema version 3, and their fixture-level proof are complete, internally consistent, and evidence-based rather than asserted — every deletion/rename/default/immutability claim above was executed against a real SQLite database, not just written down. This does not claim Swift implementation may start: that remains gated, unchanged, behind R0 audit APPROVE and Phase 0A/0B's execution (`MVP_PLAN.md` header) — this task neither touches nor advances either gate. An independent auditor reviewing this package should check whether the Collection model itself holds up, particularly the `Unsorted`-as-`NULL` decision and the volume-only scoping of source defaults, both flagged above as the two judgment calls most worth a second opinion.
