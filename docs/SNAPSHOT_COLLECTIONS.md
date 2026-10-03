# Snapshot Collections

## Status

Canonical for everything Collection-related: semantics, the capture-organization prompt, default-remembering behavior, `Unsorted` representation, mutable catalog metadata, deletion behavior, and the UI/search expectations that follow from them. Other documents (`PRD.md`, `ARCHITECTURE.md`, `MVP_PLAN.md`, `UX_UI_SPEC.md`, `TEST_PLAN.md`) reference this document and do not restate its rules. Schema fields are defined once in [`database/schema.sql`](database/schema.sql); this document explains *why* they exist and how they behave, not their column types.

## 1. The problem this solves

A snapshot identified only by a technical session number and a capture timestamp ("KN_SSD_014 · Session 008 · 2026-07-24 17:42:31") is correct but not how a person thinks about their own work. A user organizes by client, project, or production ("XYZ", "ABC", "NA", "CEN" — or whatever they call their own work), and wants to recognize a snapshot by a human label first, with the technical identity always available underneath, never hidden and never replaced.

## 2. Term

**Collection.** A logical, user-defined grouping of snapshots, stored in SQLite as ordinary catalog metadata. No better term was found — "Collection" reads correctly for "a client's or project's snapshots grouped together" without implying a folder, a project-management workflow, or a physical location, which is exactly the boundary this feature needs to hold.

A Collection is explicitly **not**: a folder created on any source volume, a directory of separate SQLite databases, a mutation of snapshot contents, a filesystem operation of any kind, or a replacement for volume identity (`volumes` remains the canonical physical-source identity table; a Collection is a purely logical layer above it). The SQLite catalog remains the single source of truth, unchanged by this feature.

## 3. Collection semantics

A Collection has: a user-facing Unicode `name` (required, blank rejected), an optional short `note`, `created_at`/`updated_at` timestamps, and a `last_used_at` timestamp that advances whenever a snapshot is assigned or moved into it (used for "recent Collections" ordering in pickers — not updated by merely viewing it).

**Duplicate names are rejected, predictably, at creation time.** A Collection's name is compared using the same normalization recipe already established for path identity (`DECISIONS.md` ADR-009: NFC via `precomposedStringWithCanonicalMapping`, then locale-independent case folding), applied to the whole name string rather than per path component, and stored as `normalized_name` under a `UNIQUE` constraint. Attempting to create "xyz" when "XYZ" already exists fails with a clear message offering to open the existing Collection instead — never a silently-created near-duplicate. This was chosen over "allow duplicates, disambiguate somehow" because client/project codes are exactly the kind of short, collision-prone strings where a silent duplicate is a user-visible mistake waiting to happen, and rejecting it outright is simpler than any disambiguation scheme.

**Renaming a Collection changes its `name` (and recomputed `normalized_name`) only.** Its `id` — the value every snapshot's `collection_id` foreign key actually points at — never changes. Renaming therefore cannot affect snapshot identity, comparison results, or any foreign-key relationship; it is a pure display-string edit, re-checked against the same uniqueness rule.

MVP explicitly does **not** include: nested Collections, an arbitrary tag system, team sharing, cloud sync, permissions, billing, or any production-management workflow. A snapshot belongs to zero or one Collection — never more than one, never a hierarchy.

## 4. `Unsorted` — model decision

Two models were evaluated:

1. **A built-in system Collection row** that every unassigned snapshot points at. Would let the sidebar list Collections uniformly (`SELECT * FROM collections`), but requires protecting that one row from rename and deletion (an `is_system` flag and special-case checks everywhere a Collection can be edited), and turns "delete a Collection" into two different code paths depending on whether the target is that protected row.
2. **`NULL` `collection_id`, displayed as "Unsorted" in the UI only.** No protected row, no special-case flag, no code path that has to know about one magic Collection.

**Decision: `NULL`, displayed as `Unsorted`.** It is the simpler model and it is what SQLite's own `ON DELETE SET NULL` is built for: "this snapshot's Collection went away, so it has none" and "this snapshot never had a Collection" become the exact same, unremarkable database state, with zero extra schema or application logic to keep a phantom row safe from the very rename/delete operations every other Collection supports. The sidebar constructs the `Unsorted` entry synthetically (a `WHERE collection_id IS NULL` count), which is a few lines of query, not a standing schema liability.

## 5. Manual capture flow

Before a manual snapshot starts, show a lightweight capture-organization sheet:

```text
Source
Collection
Snapshot name
[ ] Use this Collection by default for this source
```

- **Collection** field: choose an existing Collection, create a new one inline, or choose none (`Unsorted`). Never forces a choice.
- **Snapshot name**: optional. If left blank, FSD generates `display_name` once, at capture time, as `<source display name> — <capture date/time>` (example: `ARRI_CARD_01 — 2026-07-24 22:19`), using whatever date/time formatting is active at that moment. This generated string is stored exactly like a user-typed name and can be renamed later like any other — there is no ongoing "is this generated or custom" distinction to maintain, and no live re-formatting logic needed on every render.
- The technical snapshot id, `session_number`, and all capture timestamps are completely unaffected by anything in this sheet — Collection and name are catalog metadata layered on top of an unchanged immutable snapshot (Section 8).

### 5.1 Default selection precedence (prefill only)

The sheet's Collection field is **prefilled** using this waterfall, then the user may always change it before starting capture:

1. *(Not a prefill source — this names the final state.)* Whatever the user leaves selected in the sheet when they start the capture is what gets used. This always wins; it is not "competing" with the rules below, it is their result after any edit.
2. Remembered default for the exact source identity (Section 6), if one exists — preselected, and visibly labeled as the remembered default (Section 6), never silently applied without being shown.
3. The Collection the user was actively viewing/focused on in the sidebar when they initiated this capture, if one was intentionally selected (e.g. "Capture into this Collection" from within a Collection's own view).
4. `Unsorted`, if nothing above applies.

Step 2 outranks step 3: a remembered default for *this specific source* is a stronger signal than "whatever Collection happened to be on screen."

## 6. Source default rules

The checkbox **"Use this Collection by default for this source"** saves one remembered Collection per stable source identity in `source_collection_defaults` (Section 9). "Stable identity" excludes display names and current mount paths on purpose — two different cards both mounted as `UNTITLED`, or the same card remounted at a different path, must never accidentally share or lose a default. For MVP, this is implemented for **volume sources only**, keyed on the existing `volumes` table's own identity (UUID or fallback fingerprint) — see Section 9 for why folder/disk-image/raw-partition sources are explicitly deferred rather than given a fragile stand-in key.

Saving a default is an upsert: setting it again for the same source replaces the previous remembered Collection outright (one remembered default per source, not a history of them). Removing it is a plain delete, exposed in the UI as "Remove remembered default" wherever a source's capture defaults are shown. **The checkbox never hides the Collection choice permanently** — every future manual capture for that source still opens the same sheet, just with the remembered value preselected and visibly marked as a default rather than a fresh choice.

## 7. Automatic capture flow

An automatic mount event never opens a blocking dialog — removable media can be disconnected within seconds, and metadata capture must never wait on organization input. The rule is exactly the last two steps of Section 5.1's waterfall, with steps 1 and 3 not applicable (there is no sheet, and no "actively viewed Collection" is meaningfully tied to an unattended background event):

- if the mounted source has a remembered default Collection, the new snapshot is placed there immediately;
- otherwise it is placed in `Unsorted`;
- a non-blocking notification or catalog indicator invites later reclassification;
- a Collection is never required, and capture is never cancelled, delayed, or held open, solely because one hasn't been chosen.

## 8. Snapshot immutability boundary

Captured snapshot data — every row in `entries`, every aggregate, every capture timestamp, the `session_number`, the source identity fields — remains exactly as immutable as it was before this feature. The following are the **only** fields this feature adds, and they are catalog metadata that can change freely without touching any of the above:

- `snapshots.collection_id` — which Collection this snapshot currently belongs to (or `NULL` for `Unsorted`);
- `snapshots.display_name` — the human-facing label;
- `snapshots.user_note` — an optional free-text note.

Moving a snapshot from one Collection to another, or to `Unsorted`, is a single-row `UPDATE snapshots SET collection_id = ...` statement. It never duplicates entry records, never re-scans the source, never changes `started_at`/`completed_at`/`session_number`/any source-identity field, and never invalidates or recomputes any existing `comparisons`/`comparison_results` row — a prior comparison that referenced this snapshot by id continues to reference the same immutable snapshot regardless of which Collection it is filed under today.

## 9. Database model

Full DDL lives in `database/schema.sql` (schema version 3). This section explains the shape and the reasoning; do not restate column-level types here when that file changes.

### 9.1 `collections`

One row per user-defined Collection: `id`, `name`, `normalized_name` (`UNIQUE`, blank rejected via `CHECK`), `note`, `created_at`, `updated_at`, `last_used_at`. No `is_system` flag, no reserved row — see Section 4.

### 9.2 `snapshots` additions

`collection_id` (nullable FK to `collections.id`, `ON DELETE SET NULL`), `display_name` (`NOT NULL`, blank rejected, populated at capture time per Section 5 — either user-entered or generated, never left to be computed ad hoc by every reader), `user_note` (nullable). None of this touches the technical snapshot identifier (`id`, `session_number`) or any existing timestamp column.

### 9.3 `source_collection_defaults` — and why it is volume-only for now

Shape: `id`, `source_kind` (enumerated: `volume`, `folder`, `disk_image`, `raw_partition` — the last three reserved, not yet usable, see below), `volume_id` (FK to `volumes.id`, `ON DELETE CASCADE`), `collection_id` (FK to `collections.id`, `ON DELETE CASCADE`, `NOT NULL`), `created_at`, `updated_at`, with `UNIQUE(source_kind, volume_id)` giving the one-remembered-default-per-source and upsert-to-replace behavior Section 6 describes.

**Only `source_kind = 'volume'` is enabled in schema v3** (enforced by a `CHECK` requiring `volume_id IS NOT NULL` whenever `source_kind = 'volume'`, and requiring `source_kind` to equal `'volume'` — see the schema file for the exact constraint). This is a deliberate, documented gap, not an oversight: `volumes` already has a real canonical identity (persistent UUID, or a fallback fingerprint — `PRODUCT_STATE.md` KI-003, and the identity discussion in `FILESYSTEM_REPLAN_CLAUDE.md`) with a proper integer primary key to reference. **No equivalent canonical identity table exists yet for a live folder, a disk image, or a raw partition** — a live folder's only durable identity would be a security-scoped bookmark plus a stable file/inode identifier, which has no schema representation today (`FILESYSTEM_PROVIDER_ARCHITECTURE.md`'s `AccessGrantStore` is named in the module map but not yet schematized); a disk image or raw partition's identity is presently only captured per-snapshot (`device_identifier`/`partition_identifier`/`partition_offset`/`partition_length` on `snapshots`, added in schema v2), not as a standalone, foreign-key-able record.

Inventing a text key from a path or a device node name for these would be exactly the "fragile text key" this feature must avoid — device nodes are reused across reboots and enclosures, and paths are not identity. **This document records the requirement explicitly, as instructed, rather than working around it:** a normalized source-identity table for folders/disk-images/raw-partitions is a prerequisite for extending remembered defaults to those source kinds, and is deferred until that table exists (tracked in `MVP_PLAN.md`'s deferred backlog and `PRD.md` §6.1). Until then, a live-folder, disk-image, or raw-partition capture always falls through to Section 5.1 step 3 or 4 — never a broken or silently-wrong "default."

### 9.4 Comparison history is not part of Collections in MVP

Decision: comparisons (`comparisons`/`comparison_results`) remain entirely outside the Collection model for MVP — option 1 of the three the product brief asked to weigh. Comparisons today are transient working state (or, for a live source, a transient snapshot per `ADR-012`), not a saved, user-managed artifact a person would expect to file under a Collection. If/when a "saved comparison session" feature is built (already anticipated as an optional `ComparisonPreset`-style concept, distinct from a snapshot, in `REFERENCE_VISUALDIFFER.md`'s architecture mapping), option 3 — assign a Collection only at the moment a comparison is explicitly saved as a named artifact — is the natural extension, added when that feature is actually built, not speculatively now. This is a deferred decision, not a schema gap: no column is missing today because no comparison-saving feature exists today.

### 9.5 Deletion behavior

Deleting a Collection:

- every `snapshots` row with that `collection_id` is detached to `NULL` (`Unsorted`) by the database's own `ON DELETE SET NULL` — no application-level loop, no risk of forgetting a row;
- every `source_collection_defaults` row pointing at it is removed by `ON DELETE CASCADE` — a "default of a Collection that no longer exists" is meaningless and is deleted outright, not silently repointed at `Unsorted` (a source with no default simply falls through the Section 5.1/7 waterfall next time, which is the correct behavior, not a gap);
- **no snapshot, entry, or comparison row is ever deleted by this operation.** Snapshot deletion remains the separate, explicit, already-existing action it always was — Collections never cascade into it in either direction.

## 10. UI and navigation

Collections and physical volumes are different concepts and must not be merged into one identity model or one sidebar section. Recommended sidebar shape:

```text
Collections
├── All Snapshots
├── Unsorted
├── XYZ
├── ABC
├── NA
└── CEN

Live Volumes
Recent Sources
```

Snapshot rows prioritize, in order: display name, source name, capture date, filesystem, complete/partial status, online/offline state. A raw technical session id or UUID is never the primary title — it remains one click away (an inspector or secondary line), never hidden, per the product intent that the technical identity stays available without being the label a person has to read first.

Editing surface: rename a snapshot's `display_name`; move a snapshot to another Collection (or to `Unsorted`); edit its `user_note`; create and rename Collections; remove a remembered source default; set a new one. Every one of these is local catalog metadata — none of them touch a source volume, re-scan anything, or write anywhere but the local database, consistent with `SECURITY_AND_READ_ONLY_POLICY.md`.

## 11. Search and filtering

The offline catalog supports searching by Collection name, snapshot display name, source name, captured path, capture date, filesystem, and snapshot status — entirely against the local SQLite catalog, never requiring the source to be attached or re-scanned. Every search result surfaces which Collection it belongs to (or `Unsorted`), so a result is never presented without its organizational context.

## 12. Comparison workspace impact

Collections are a navigation and organization aid, not a comparison input. A Collection itself is **not draggable into a comparison pane** — dropping a Collection would be ambiguous (compare against which of its snapshots?) and comparing "everything in a Collection" is exactly the kind of ambiguous, expensive, unrequested behavior this feature must not introduce. A snapshot dragged out of a Collection's listing is an ordinary comparison source, indistinguishable from one dragged from anywhere else in the catalog — the comparison pane continues to accept a live folder, a live volume, a saved snapshot, or a snapshot subfolder exactly as `FILESYSTEM_REPLAN_CLAUDE.md`'s comparison-source model already defines, unmodified by this feature.
