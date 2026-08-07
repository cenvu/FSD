# Handoff: FSD-COLLECTIONS-REPLAN-0724-05

AGENT: Claude
ROLE: LOGIC, DATA MODEL, UX, AND DOCUMENTATION REVIEW
MODE: review and documentation
TASK ID: FSD-COLLECTIONS-REPLAN-0724-05
PHASE: Phase 0 — Planning and architecture definition (Snapshot Collections feature added to the plan; R0 correction and Phase 0A/0B feasibility remain separate, still-open gates)

## OBJECTIVE

Design and document a human-friendly organization layer ("Collection") above raw snapshot sessions and timestamps: a logical, user-defined grouping stored in SQLite, never a physical folder, never a mutation of snapshot contents, never a replacement for volume identity. Cover Collection semantics, the manual capture-organization sheet, remembered per-source defaults, automatic-capture behavior, deletion behavior, the database model, UI/navigation, search, and comparison-workspace impact — documentation and schema review only, folded into the existing Phase 4/5/7 plan rather than a new major phase.

## REPOSITORY STATE BEFORE

- `FSD_ROOT` resolved to `/Users/cenvu/Desktop/DEV/FSD`. Not a Git repository.
- Phase 0 — Planning and architecture definition. Two gates already established and unchanged by this task: R0 schema/normalization correction still open (independently audited, **REJECT**, 14 required fixes outstanding); Phase 0A/0B multi-filesystem feasibility proof not yet executed.
- The prior filesystem-provider replan (`FSD-FSCORE-REPLAN-0724-04`) had already produced schema version 2, `FILESYSTEM_PROVIDER_ARCHITECTURE.md`, `FILESYSTEM_SUPPORT_MATRIX.md`, `DEPENDENCY_AND_LICENSE_REVIEW.md`, `FILESYSTEM_FEASIBILITY_PLAN.md`, and `FILESYSTEM_REPLAN_CLAUDE.md`, and had already migrated and deleted the legacy `AI_HANDOFFS/` directory.
- `handoffs/` already contained three flat files (`FSD_R0_CORRECTION_F_...`, `FSD_R0BLOCKERSCLOSURE_C_...`, `FSD_R0BLOCKERSAUDIT_A_...`, `FSD_FSCORE_REPLAN_F_...`), no checksums, no nested directories.
- No production Swift/Xcode project existed.

## FILES READ

`handoffs/FSD_FSCORE_REPLAN_F_20260724-221931.md`, `docs/FILESYSTEM_REPLAN_CLAUDE.md`, `docs/UX_UI_SPEC.md` (fresh re-read to confirm no drift since the prior task; it was unchanged). All other canonical documents touched in this task were already current in context from the immediately preceding task in this same session (`PRD.md`, `ARCHITECTURE.md`, `MVP_PLAN.md`, `PRODUCT_STATE.md`, `DECISIONS.md`, `PROJECT_MANIFEST.md`, `KNOWN_ISSUES.md`, `TEST_PLAN.md`, `FILESYSTEM_PROVIDER_ARCHITECTURE.md`, `database/schema.sql`, `database/verify.sql`).

## FILES CHANGED

`docs/PRD.md` (new US-06), `docs/ARCHITECTURE.md` (CatalogRepository responsibility line), `docs/MVP_PLAN.md` (Phases 4/5/7 deliverables/exit-criteria, deferred backlog), `docs/PRODUCT_STATE.md`, `docs/DECISIONS.md` (ADR-019, ADR-020), `docs/PROJECT_MANIFEST.md` (canonical documents list, invariant 11, MVP deliverable line), `docs/KNOWN_ISSUES.md` (KI-012), `docs/TEST_PLAN.md` (new §7, §5 additions), `docs/UX_UI_SPEC.md` (sidebar, new §3.1 capture sheet, snapshot row redesign, comparison-pane note, empty state), `docs/FILESYSTEM_PROVIDER_ARCHITECTURE.md` (one-line scope-boundary note), `docs/database/schema.sql` (version 3), `docs/database/verify.sql` (extended fixtures 23–38, plus `display_name` added to every pre-existing snapshot fixture).

## FILES CREATED

`docs/SNAPSHOT_COLLECTIONS.md` (canonical Collection specification), `docs/SNAPSHOT_COLLECTIONS_REVIEW_CLAUDE.md` (decision report), this handoff.

`docs/FILESYSTEM_REPLAN_CLAUDE.md` was read and confirmed to need no edit (Collections are unrelated to filesystem providers) — left untouched, consistent with how `docs/REVIEW_CLAUDE_CODE.md` was already treated as a dated, self-contained artifact in the prior task.

## USER REQUIREMENT

A human-facing organization layer, called `Collection`, above raw snapshot sessions/timestamps (examples given: `XYZ`, `ABC`, `NA`, `CEN`), covering: a capture-organization sheet before manual capture (Source / Collection / Snapshot name / remembered-default checkbox); a remembered default Collection per stable source identity with a defined precedence order; non-blocking automatic-capture behavior; Collection CRUD (name, rename, note, timestamps) without nesting/tags/sharing/cloud/permissions/billing; snapshot Collection membership as mutable metadata around an immutable snapshot; Collection deletion that detaches rather than deletes snapshots; a `source_collection_defaults`-shaped table using canonical source identity, not a display name or path; and sidebar/search/comparison-workspace UX consequences.

## RECOMMENDED COLLECTION MODEL

`Unsorted` as `NULL collection_id`, not a built-in system row — simpler, needs no rename/delete special-casing, and matches `ON DELETE SET NULL` natively. Collection names normalized with the existing ADR-009 recipe (NFC + case fold) and enforced `UNIQUE`, so duplicate creation is rejected outright, not silently disambiguated. `collection_id`/`display_name`/`user_note` on `snapshots` are the only new mutable fields; renaming/moving never touches `id`, `session_number`, entries, aggregates, timestamps, or comparison results. `source_collection_defaults` keyed by `(source_kind, volume_id)`, volume-only in this schema version, because no canonical identity table exists yet for folder/disk-image/raw-partition sources — documented as a deferred prerequisite (`DECISIONS.md` ADR-020), not worked around with a fragile text key. Comparisons stay outside the Collection model entirely for MVP.

## DATABASE CHANGES

Schema version 3. New tables: `collections` (`id`, `name`, `normalized_name` `UNIQUE`, `note`, `created_at`, `updated_at`, `last_used_at`, blank-name `CHECK`); `source_collection_defaults` (`id`, `source_kind` enumerated but `CHECK`-restricted to `'volume'` with a required `volume_id` in this version, `volume_id` FK → `volumes.id` `ON DELETE CASCADE`, `collection_id` FK → `collections.id` `ON DELETE CASCADE` `NOT NULL`, `UNIQUE(source_kind, volume_id)`). `snapshots` additions: `collection_id` (FK → `collections.id`, `ON DELETE SET NULL`), `display_name` (`NOT NULL`, blank rejected), `user_note`. New index `idx_snapshots_collection`. All version 1 (R0) and version 2 (filesystem-provider) constraints, triggers, and columns preserved unchanged. `database/verify.sql` extended with 16 new fixtures (23–38) plus a required `display_name` value added to every pre-existing snapshot fixture (11 statements) since the column is now `NOT NULL`.

## SCHEMA VERSION

3. `schema_migrations` now records versions 1, 2, and 3 (confirmed via fresh apply — see VERIFIED RESULTS).

## MANUAL CAPTURE FLOW

A capture-organization sheet (Source / Collection / Snapshot name / "Use this Collection by default" checkbox) precedes manual capture. Collection field prefilled by a waterfall: remembered default for the exact source → the actively-viewed Collection in the UI, if any → `Unsorted`; whatever the user leaves selected when starting capture always wins and is freely editable. Blank snapshot name generates `display_name` once, at capture time, as `<source> — <date/time>`, thereafter indistinguishable from a user-typed name. No effect on `id`, `session_number`, or any capture timestamp. Full detail: `SNAPSHOT_COLLECTIONS.md` §5.

## AUTOMATIC CAPTURE FLOW

No sheet. Remembered default if one exists for the mounted source, else `Unsorted`, always, plus a non-blocking notification for later reclassification. Never cancelled, delayed, or held open pending a Collection choice. `MVP_PLAN.md` Phase 7 now explicitly names this as consuming Phase 4's default-lookup rule. Full detail: `SNAPSHOT_COLLECTIONS.md` §7.

## SOURCE DEFAULT RULES

One remembered Collection per `(source_kind, volume_id)`, upserted on save (replace, not duplicate), removable by plain delete — all three operations (save/replace/remove) exercised against a fresh database and confirmed correct. Keyed on `volumes.id` (an integer FK into the existing canonical volume-identity table: persistent UUID or fallback fingerprint), never a display name or mount path — tested directly: two distinct volumes were given independent, non-colliding defaults. `folder`/`disk_image`/`raw_partition` are reserved in the enum but blocked by a `CHECK` constraint until a normalized non-volume source-identity table exists (`KNOWN_ISSUES.md` KI-012).

## SNAPSHOT IMMUTABILITY RESULT

VERIFIED, not merely asserted: fixture 37 moved a snapshot between two Collections and confirmed its `entries` count and `started_at`/`session_number` were identical before and after the move. Fixture 36 deleted a Collection with an assigned snapshot and confirmed the snapshot row survived intact with `collection_id` set to `NULL`.

## COLLECTION DELETION RESULT

VERIFIED: deleting a `collections` row (fixture 36) set the referencing snapshot's `collection_id` to `NULL` via `ON DELETE SET NULL` and removed the `source_collection_defaults` row that pointed at it via `ON DELETE CASCADE` — no snapshot, entry, or comparison row was deleted, and `PRAGMA foreign_key_check` remained clean throughout.

## PHASE PLAN CHANGES

No new phase. Folded into `MVP_PLAN.md`: Phase 4 gains the Collection schema, data layer, source-default persistence, and immutability tests; Phase 5 gains the Collection sidebar, capture-sheet UI, search/filter with Collection context, and rename/move/note/default controls; Phase 7 now explicitly consumes Phase 4's default-lookup rule. Deferred backlog gained two items (non-volume source-identity table; Collection-for-saved-comparisons).

## VERIFIED RESULTS

- VERIFIED: `docs/database/schema.sql` (version 3) applies cleanly to a fresh SQLite database; `PRAGMA integrity_check` = `ok`; `PRAGMA foreign_key_check` = no rows; `schema_migrations` records versions 1, 2, and 3.
- VERIFIED (via `docs/database/verify.sql` against a fresh database, fixtures 23–38): Collection creation succeeds; blank Collection name is rejected; normalized duplicate name (`xyz` vs. existing `XYZ`) is rejected; rename changes `name`/`normalized_name` with `id` unchanged; snapshot creation with and without a Collection succeeds; blank `display_name` is rejected; a source default saves, replaces (upsert, confirmed single row), and is removable; two distinct volumes get independent, non-colliding defaults; a non-`'volume'` `source_kind` is rejected; a `'volume'` `source_kind` with `NULL volume_id` is rejected; deleting a Collection detaches its snapshot to `NULL` and removes the default pointing at it, with no foreign-key violation; moving a snapshot between Collections leaves its entry count and capture timestamp/session-number unchanged; a search-with-Collection-context query (`LEFT JOIN` + `COALESCE(..., 'Unsorted')`) returns correct results for every snapshot including `Unsorted` ones.
- VERIFIED: zero Markdown files under `docs/` have trailing whitespace or merge-conflict markers.
- VERIFIED: no nested `AI_HANDOFFS` directory exists; `handoffs/` remains flat with no `.sha256` files; this task added exactly one new flat Handoff and created no checksum.
- VERIFIED: `git status --short` exits 128 ("not a git repository"); no repository was initialized, and no commit or push was performed.
- VERIFIED: no document describes a Collection as a physical folder, a filesystem operation, or a replacement for volume identity; `FILESYSTEM_PROVIDER_ARCHITECTURE.md` explicitly states a provider never queries Collection membership; R0's open status and the Phase 0A/0B gate remain stated verbatim in `PRODUCT_STATE.md` and `MVP_PLAN.md`, unmodified in substance by this task.

## INFERRED RESULTS

- INFERRED: the manual-capture sheet's actual preselection behavior, the automatic-capture notification UX, and the sidebar's live snapshot counts will behave as specified once built — these require application code (Phase 4/5/7) and were not and could not be executed in this documentation-only task.

## PROPOSED ITEMS

- PROPOSED (recorded, not yet decided): a normalized source-identity table for folders/disk-images/raw-partitions, needed before `source_collection_defaults` can cover those source kinds (`DECISIONS.md` ADR-020).
- PROPOSED: Collection assignment for saved comparison sessions, only if/when that feature is separately built (`SNAPSHOT_COLLECTIONS.md` §9.4).

## BLOCKED ITEMS

- BLOCKED: R0 correction round 2 and its independent audit — unchanged, out of this task's scope.
- BLOCKED: Phase 0A/0B multi-filesystem feasibility execution — unchanged, out of this task's scope.
- BLOCKED: any application-level verification of the capture sheet, automatic-capture notification, or sidebar UI — no Swift code exists to run.
- BLOCKED: `git status`/`git diff --check` — no `.git` repository exists; not initialized, per constraints.

## ACCEPTED RISKS

- ACCEPTED RISK: non-volume source defaults are unimplemented in this schema version by design; mitigated by a well-defined, tested fallback (the waterfall's lower steps) that never produces an incorrect or silently-broken default, only a less convenient one.
- ACCEPTED RISK: generated `display_name` freezes the date/time format active at capture time and will not retroactively reformat if locale preferences change later; accepted because it is just a renamable label, not an identity field.
- ACCEPTED RISK: `last_used_at`'s update trigger (assignment/move only) is a product-feel choice not validated against real usage; low cost to revisit post-MVP.

## COMMANDS EXECUTED

`sqlite3 <fresh-db> < docs/database/schema.sql` (twice — once standalone, once immediately before running fixtures); `sqlite3 -header -column <fresh-db> < docs/database/verify.sql`; `PRAGMA integrity_check`; `PRAGMA foreign_key_check`; `grep -rn`/`grep -rlnE` sweeps for Collection-as-physical-folder language, non-blocking-automatic-capture language, stable-identity language, R0/Phase-0A gate visibility, nested-Handoff/checksum remnants, trailing whitespace, and merge markers across `docs/`; `find` sweeps confirming no `AI_HANDOFFS` directory and no `.sha256` files exist anywhere in the tree; `git status --short`; `date` for the handoff filename timestamp.

## VERIFICATION RESULTS

Canonical Collection rules exist in exactly one document (`SNAPSHOT_COLLECTIONS.md`, 37 Collection-related mentions; every other touched document references it rather than restating). No document treats a Collection as a physical source folder (one explicit hit, itself the rule stating the opposite). Snapshot immutability is intact and directly tested, not inferred. Collection deletion cannot cascade-delete a snapshot (`ON DELETE SET NULL`, tested). Automatic capture cannot be blocked by an organization dialog (explicit "never opens a blocking dialog" language in both the spec and the plan). Default source mappings use `volume_id`, never a display name or mount path (tested with two same-shape-but-distinct volumes). `FILESYSTEM_PROVIDER_ARCHITECTURE.md` is otherwise unchanged, with one line confirming providers never touch Collection data. R0's open status and the Phase 0A/0B gate remain visible verbatim. Schema versioning is correct: version 3 recorded, versions 1 and 2 preserved and re-verified. No nested Handoff policy returned; no checksum was created. Zero trailing whitespace; zero merge markers. Git remains untouched (`status --short` exit 128, no `.git`, nothing initialized).

## GIT STATUS

BLOCKED — `/Users/cenvu/Desktop/DEV/FSD` is not a Git repository (`.git` absent). Not initialized, per constraints.

## COMMIT READINESS

NOT APPLICABLE — no Git repository exists.

## PUSH READINESS

NOT AUTHORIZED — no Git repository, no remote, no push performed or requested.

## EXACT NEXT ACTION

Route this Collections specification to an independent audit alongside (or after) the still-pending filesystem-replan audit. In parallel, and independently, continue the R0 correction round — this task did not touch it. Do not begin Xcode/Swift implementation until R0 audit APPROVE and Phase 0A/0B are both complete; when Phase 4 implementation does begin, build the Collection schema and data layer first (per `MVP_PLAN.md`), before the Phase 5 UI that depends on it.

## RECOMMENDED AUDIT FOCUS

1. The `Unsorted`-as-`NULL` decision versus a built-in system-row alternative — confirm the simplicity argument holds and no referential-integrity edge case was missed.
2. The volume-only scoping of `source_collection_defaults` and whether deferring folder/disk-image/raw-partition defaults (rather than inventing an interim key) is the right call given the product's stated use cases.
3. Whether `display_name` should have been nullable-with-live-generation instead of `NOT NULL`-generated-once — re-derive the tradeoff and confirm the chosen direction (uniform downstream queries, no COALESCE branching) is still preferred.
4. Re-run `database/verify.sql` independently against a fresh database and confirm all 38 fixtures behave as this handoff claims.
5. Whether comparison-history's complete exclusion from Collections (option 1) is right for MVP, or whether option 3 (assign at explicit save) should have been scoped in now rather than deferred.
