# Architecture Decision Log

## ADR-001 — SQLite is the canonical store

**Status:** Accepted

JSON and HTML are export formats only. SQLite provides transactions, indexes, lazy loading, large-catalog support and efficient diff queries.

## ADR-002 — SwiftUI shell with AppKit tree

**Status:** Accepted

Use SwiftUI for navigation, forms, settings and summaries. Use `NSOutlineView` through `NSViewRepresentable` for large snapshot trees and two-pane comparison.

## ADR-003 — Metadata-only default scanner

**Status:** Accepted

The scanner reads directory entries and filesystem metadata only. It does not open file payloads, hash contents, parse media or generate thumbnails.

## ADR-004 — Immutable snapshot generations

**Status:** Accepted

Every capture creates a new snapshot generation. A generation is marked complete only after all entries and aggregate values commit successfully.

## ADR-005 — Logical size drives default equality

**Status:** Accepted

Allocated size is retained for storage analysis but excluded from default equality because it varies across filesystems.

## ADR-006 — Local-only distribution

**Status:** Accepted

Initial internal builds are for local distribution only. They do not require notarization, Developer ID, App Store packaging, or public DMG infrastructure. Sandboxing and public release processes are out of scope for MVP.

## ADR-007 — VisualDiffer is reference-only

**Status:** Accepted

VisualDiffer validates several macOS folder-comparison UX patterns, but FSD — FishSock Differ remains an independent implementation. Do not fork or copy VisualDiffer code or assets into FSD. Preserve the SQLite snapshot architecture, exclude all source-file mutation features, and follow `REFERENCE_VISUALDIFFER.md`.


## ADR-008 — Project naming

**Status:** Accepted

The canonical project name is **FSD — FishSock Differ**. Use `FSD` for repository names, Xcode targets, executable names, test targets, release artifacts, Application Support directories and technical identifiers. Use `FishSock Differ` or `FSD — FishSock Differ` in user-facing product copy. The former working title must not be used in new documentation or code.

## ADR-009 — Unicode-text path identity and normalization v1

**Status:** Accepted

`relative_path` is the Unicode String returned by the supported Foundation filesystem enumeration path. It is case-preserving and stored without intentional normalization. It is not described as an exact filesystem byte sequence (raw filename byte preservation is out of scope for MVP). If Foundation cannot represent a name, the scanner records an issue and marks the affected region uncertain (complete_with_warnings).
Normalization v1 explicitly uses Foundation algorithms: case-preserving key uses `String.precomposedStringWithCanonicalMapping`, while case-folded key uses `String.folding(options: [.caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))` followed by `precomposedStringWithCanonicalMapping`. The compatibility identity string is structured as `fsd-normalizer-v1_app-<implementation-version>_os-<ProductBuildVersion>`, where `fsd-path-v1-foundation-nfc-posix-casefold` may be used as the algorithm identifier component, but not as the complete runtime compatibility identity. Milestone 1's supported runtime identity is exactly `fsd-normalizer-v1_app-1.0_os-1`; other values are not accepted for snapshot completion until explicitly added to the allowlist.

## ADR-010 — Source case sensitivity

**Status:** Accepted

Snapshot source case sensitivity is tracked explicitly as `sensitive`, `insensitive`, or `unknown`. When comparing snapshots, if both are sensitive, the case-preserving key is used; if either is insensitive or unknown, the case-folded key is used (unknown also yields an explicit compatibility warning). No arbitrary member pairing occurs; every selected-key collision becomes an `uncertain` result.

## ADR-011 — Normalization-version mismatch policy

**Status:** Accepted

Comparison requires equal normalization_version values. Mismatched versions block comparison outright with an explicit compatibility error. We do not silently regenerate or mutate keys belonging to immutable historical snapshots.

## ADR-012 — Transient snapshot comparison and lifecycle

**Status:** Accepted

Live comparison uses transient captures. Transient snapshots use the normal metadata-only scanner and atomic status transitions, but never appear in normal user history and are never automatically deleted from standard user rotation. A transient snapshot referenced by a pending or running comparison cannot be deleted (enforced via database `ON DELETE RESTRICT`). Closing a comparison workspace terminalizes disposable comparison state first, then deletes unreferenced transient snapshots. Abandoned transient snapshots from crashes are cleaned up on launch.

## ADR-013 — Flat Markdown-only Handoff storage

**Status:** Accepted (amended)

Handoffs are stored in a single flat directory `<FSD_ROOT>/handoffs`. There are no date subdirectories, no SESSION directories, and no `.sha256` checksum files. One Markdown file is created per agent session using the format `FSD_<CASE_CODE>_<ROLE_CODE>_<YYYYMMDD-HHMMSS>.md`.

Amendment (2026-07-24, task FSD-FSCORE-REPLAN-0724-04): the legacy nested `AI_HANDOFFS/` directory has been inventoried, its two unique files migrated verbatim into `handoffs/` (`FSD_R0BLOCKERSCLOSURE_C_20260724-210734.md` and `FSD_R0BLOCKERSAUDIT_A_20260724-211837.md`, checksums intentionally dropped), and the `AI_HANDOFFS/` directory deleted. The original text of this ADR required historical `AI_HANDOFFS/` files to remain untouched; that requirement is superseded now that migration is complete and nothing remains to preserve in place.

## ADR-014 — Native-first, embedded-raw-fallback filesystem provider

**Status:** Accepted

FSD reads a filesystem through `NativeMountedProvider` whenever macOS can mount it (APFS, HFS+, FAT16, FAT32, exFAT, NTFS read-only, UDF — all native across macOS 13–26 with no user-installed driver, kext, or app extension). `EmbeddedRawProvider` exists only for the filesystems macOS cannot mount at all (ext2, ext3, ext4). Provider selection is deterministic, not user-chosen. Full contract and fallback rule: `FILESYSTEM_PROVIDER_ARCHITECTURE.md`. This narrows the embedded-reader problem down to a three-filesystem (ext2/3/4) one — see `DEPENDENCY_AND_LICENSE_REVIEW.md` §2 for the research this is based on. (Note: prior historical wording framing this as a nine-filesystem problem was an earlier planning miscount.)

## ADR-015 — libfsext for the ext2/ext3/ext4 gap

**Status:** Accepted, pending Phase 0A/2 empirical confirmation

The embedded reader for ext2/ext3/ext4 is libfsext (libyal project, LGPL-3.0-or-later), dynamically linked inside `FSD.app/Contents/Frameworks/`. The Sleuth Kit, e2fsprogs/libext2fs, and FSKit were evaluated and not selected — reasons in `DEPENDENCY_AND_LICENSE_REVIEW.md` §3. This ADR is provisional in the sense that Phase 0A/2 (`FILESYSTEM_FEASIBILITY_PLAN.md`) is the actual proof; if libfsext fails that proof, TSK is the documented fallback and this ADR is revised, not silently overridden.

## ADR-016 — Raw-device authorization via `authopen`, never a custom privileged helper

**Status:** Accepted, pending Phase 3 empirical confirmation

When a raw partition device node cannot be opened read-only without elevated rights, FSD invokes the system `/usr/libexec/authopen` utility for a one-time, scoped, read-only file descriptor, rather than building a custom `SMJobBless`/`SMAppService` helper or root daemon. No standing privilege, no Full Disk Access grant, no sudo. See `FILESYSTEM_PROVIDER_ARCHITECTURE.md` §7 and `DEPENDENCY_AND_LICENSE_REVIEW.md` §5. Whether this mechanism is actually needed on real target hardware (versus plain `open()` already succeeding for removable media) is unverified until Phase 3.

## ADR-017 — Reader helper process isolation for embedded-raw parsing

**Status:** Accepted

`EmbeddedRawProvider`'s filesystem parsing runs inside a separate bundled process (XPC service or subprocess), never in the main app process, because it parses untrusted on-disk structures from media FSD did not create. This is a security boundary independent of any license consideration. See `FILESYSTEM_PROVIDER_ARCHITECTURE.md` §8.

## ADR-018 — No camera-vendor or media-specific recognition, at any phase

**Status:** Accepted

FSD does not recognize ARRI/RED/Sony/Canon/Nikon (or any other vendor's) camera folder layouts, validate media, analyze codecs, or apply a media-specific capture profile, at any point on the roadmap. This is a permanent scope exclusion, not a deferred backlog item — see `PRD.md` §4.1 and `MVP_PLAN.md`'s deferred-backlog section, which lists it separately from things that are merely deferred.

## ADR-019 — Snapshot Collections: NULL-based Unsorted, unique normalized names, immutable snapshot boundary

**Status:** Accepted

Snapshot Collections are a purely logical, user-defined grouping stored in `collections`, never a folder on a source volume. `Unsorted` is represented as `snapshots.collection_id IS NULL`, not a protected system row — evaluated against a built-in-row alternative and rejected because `NULL` needs no special-casing anywhere a Collection can be renamed or deleted, and `ON DELETE SET NULL` already expresses "this snapshot's Collection went away" with no application logic. Collection names are compared using the same normalization recipe as ADR-009 (NFC + locale-independent case fold) and are `UNIQUE` on the normalized form — a duplicate-name creation attempt is rejected outright, not silently disambiguated. `collections.id` is the only thing a snapshot's `collection_id` foreign key ever points at, so renaming a Collection cannot affect snapshot identity. `snapshots.collection_id`/`display_name`/`user_note` are mutable catalog metadata layered on an otherwise-unchanged-by-this-feature immutable snapshot: moving a snapshot between Collections never rescans the source, never duplicates entries, and never touches a capture timestamp, `session_number`, or any comparison result. Full specification: `SNAPSHOT_COLLECTIONS.md`.

## ADR-020 — Source-collection defaults are volume-only until a normalized non-volume source-identity table exists

**Status:** Accepted

`source_collection_defaults` remembers one Collection per stable source identity, keyed by `(source_kind, volume_id)` for `source_kind = 'volume'` only, referencing the existing `volumes` table's own canonical identity (persistent UUID or fallback fingerprint) — never a display name or a current mount path. `folder`, `disk_image`, and `raw_partition` are reserved in the `source_kind` enumeration but blocked by a `CHECK` constraint in schema version 3, because no canonical, foreign-key-able identity table exists yet for any of them (a live folder's only durable identity would be a security-scoped bookmark plus a stable file identifier, which has no schema representation today). Inventing a text key from a path or a device node name for these would be exactly the fragile-key problem this feature must avoid. Extending remembered defaults to those source kinds is deferred until that identity table is built (`MVP_PLAN.md` deferred backlog), not worked around with a weaker key now. Full specification: `SNAPSHOT_COLLECTIONS.md` §9.3.

## ADR-021 — Magika content classification deferred to Phase 1.5; architecture seam prepared now, runtime not built

**Status:** Accepted

**Supersession note:** this ADR retains its original pre-implementation context.
ADR-031 and the accepted 2026-08-07 nullable-boundary audit record the now
implemented and audited preparation seam; ADR-032 records the completed
runtime design. Current schema is v8; runtime implementation remains not
started/inactive and requires a separately authorized schema change.

Magika-based file content classification is explicitly excluded from the MVP runtime and deferred to Phase 1.5 (`MVP_PLAN.md`), which may start only after the MVP core passes its acceptance gates (snapshot capture, offline browsing, snapshot history, metadata diff, interruption safety, performance tests). This ADR prepares the seam for that future phase without building it now:

- a `FileClassificationService` abstraction and a `DisabledFileClassificationService` default are defined as an architecture contract only (`ARCHITECTURE.md` §9) — no Swift target exists yet in this repository, so neither is implemented code;
- `DisabledFileClassificationService` is the only implementation permitted to exist during the MVP: it performs no filesystem access, reads no payload bytes or byte ranges, computes no hashes, schedules no work, and writes no rows;
- the MVP scanner, `TreeDiffEngine`, and UI neither instantiate, call, nor depend on this interface;
- a separate, optional `entry_classifications` table (`database/schema.sql`, schema version 4) holds future results as derived enrichment, fully decoupled from `entries`/`snapshots`, which remain pure immutable snapshot metadata; the MVP writes zero rows to it and may leave it empty for its entire lifecycle;
- future classification results are append-only and version-distinguished (`classification_run_id`, `detector_version`, `model_version` per row) — a later run never rewrites or reinterprets an earlier run's stored result, and no historical Metadata Match or diff conclusion is ever altered by a classification outcome, present or future;
- no sampled bytes and no full-file payload hashes are ever persisted, in the MVP or in the eventual Phase 1.5 implementation — only bounded byte-range reads are permitted once built;
- Magika itself is not installed, not added as a dependency, and not executed anywhere in this repository as of this ADR.

This ADR records schema and architecture preparation only. It does not authorize starting Phase 1.5 implementation; that requires the MVP core acceptance gates above to pass first, per `MVP_PLAN.md`.

## ADR-022 — Gate resolution, milestone restructuring, and risk-based review policy

**Status:** Accepted (2026-08-04, `handoffs/FSD_MVP_DEEP_AUDIT_R_20260804-003039.md`)

Recorded by the single authorized deep audit before accelerated MVP implementation. Four decisions:

**1. The R0 gate is closed.** The 2026-07-24 REJECT was superseded by three correction rounds and a final independent audit returning APPROVE (`handoffs/FSD_PLAN_GATE_FINAL_REAUDIT_A_20260725-154907.md`). `PRODUCT_STATE.md` and `MVP_PLAN.md` had continued to assert R0 "remains open ... unchanged since that audit" while `README.md` asserted it was closed; the three documents contradicted each other for over a week. The audit resolved this against the evidence, not against the wording. Two carried-forward defects remain and are scheduled inside Milestone 1 rather than held as a gate in front of it:

- `normalization_version`'s completion guard is a literal blacklist, not a positive format check against ADR-009's documented shape (independently re-verified 2026-08-04: `'   '`, `'UNKNOWN'`, `'PLACEHOLDER'`, `'NOT_SET'`, `'PENDING'` all reach `complete`);
- two `verify.sql` snapshot fixtures omit `normalization_version` and therefore fail on an incidental `NOT NULL` violation before the provider constraints they document are exercised.

Neither prevents creating the Xcode project, the database wrapper, the snapshot model, or the UI shell. Both must be closed before snapshot completion logic is trusted.

**2. Filesystem feasibility is no longer a blanket gate.** ext2/3/4 and native APFS/HFS+/APFSX/HFSX passed feasibility; FAT16/FAT32/exFAT/NTFS/UDF were never started. Because `FILESYSTEM_PROVIDER_ARCHITECTURE.md` isolates per-filesystem behavior behind a single contract, provider-specific feasibility is separable from core foundation work. The untested filesystems are gated at Milestone 3, not in front of Milestone 1. Full status matrix: `FILESYSTEM_FEASIBILITY_PLAN.md` §7.

**3. The plan is restructured into five large milestones.** The prior eight-phase sequence (0A, 0B, 0, 1–8) fragmented the work such that a Writer repeatedly reopened the same architecture. `MVP_PLAN.md` now carries five coherent milestones, each implementable as one slice. Manual testing is consolidated from per-phase checks into exactly two human sessions (`TEST_PLAN.md` §8): one after the first usable end-to-end capture, one final MVP acceptance pass.

**4. Independent review becomes risk-based, not automatic.** Routine low- and medium-risk implementation slices no longer receive an automatic separate audit. Independent review is required for source read-only safety, snapshot immutability, interruption and crash recovery, schema migration or compatibility, destructive behavior, broad comparison semantics, and pre-MVP acceptance (mandatory). Under `MVP_PLAN.md` this means Milestones 2, 4, and 5 are audited; Milestones 1 and 3 are not, unless they cross one of those boundaries. Policy text: `AGENT.md` § Review policy.

This ADR does not authorize Phase 1.5, does not change any Magika constraint in ADR-021, and does not relax any read-only or immutability invariant.

## ADR-023 — Snapshot history reads capture-time columns, never the mutable volume registry

**Status:** Accepted (2026-08-04, Milestone 3)

`volumes` is a current-state registry by design: `SnapshotWriter.ensureVolume` refreshes `display_name`, `filesystem_type`, `total_capacity_bytes` and `last_seen_at` on every capture of a known volume. Condition C4 of the Milestone 2 acceptance audit observed the consequence — anything read from that registry and shown beside an older snapshot silently describes a *later* capture. Rename a card, capture it again, and last month's snapshot appears to have been taken from the new name.

Two fixes were available: stop mutating the registry, or stop reading it for history. FSD does the second, because a current-state registry is genuinely useful (it is what "have I seen this volume before" is answered from) and freezing it would make that answer wrong instead.

Schema version 5 therefore adds three capture-time columns to `snapshots` — `volume_display_name_at_capture`, `volume_identifier_at_capture`, `volume_total_capacity_bytes_at_capture` — joining the capture-time facts already present (`scan_root_name`, `mount_path_at_capture`, `filesystem_variant`, `source_case_sensitivity`, `normalization_version`, totals). `trg_snapshots_capture_facts_immutable` rejects any later `UPDATE` of any of them. `SnapshotHistoryRepository` reads only these columns and holds no `FileManager`; it never queries `volumes`.

A snapshot captured before version 5 has `NULL` in all three. That is displayed as "Not recorded at capture time" and is **never** back-filled from the registry, which would reintroduce exactly the untruth this closes.

Deliberately still mutable: `display_name`, `user_note`, `collection_id` (user labelling, ADR-019), and the lifecycle fields `status`, `completed_at`, `warning_count`, totals. The guard freezes what a snapshot *is a capture of*, not how the user files it.

## ADR-028 — Terminal comparison evidence is immutable; schema version 7 and the complete object inventory

**Status:** Accepted (2026-08-04, Milestone 4 schema-safety correction)

The independent Milestone 4 audit reproduced two rejection-level defects in
ADR-027's wave. Both are closed here by schema version 7 (ADR-024):

1. **H1 — a terminal comparison's evidence could still be mutated.** ADR-027
   guarded `comparisons` status/counts and `comparison_results` INSERT/UPDATE,
   but not `comparison_results` DELETE, and not
   `comparison_collision_groups`/`comparison_collision_members` at all. The
   audit directly inserted rows into both collision tables after a comparison
   reached `complete` — the uncertainty evidence of a finished conclusion
   could be rewritten after finalization.

   Version 7 adds seven triggers: `trg_comparison_results_delete_guard` and
   INSERT/UPDATE/DELETE guards for collision groups and members. Every guard
   probes the owning comparison's status; when it is `complete`, `cancelled`
   or `failed`, the direct mutation aborts. While a comparison is `running`,
   valid result and collision evidence writes are unaffected (the engine
   writes collision groups and members during matching).

   **Disposal design:** the DELETE guards deliberately do not block
   whole-comparison disposal (ADR-012's workspace close, ADR-027's explicit
   disposal API). SQLite fires the cascade's child-table DELETE triggers only
   after the parent comparison row itself is gone, so the guards' status probe
   finds no row and the cascade completes. Direct evidence DELETE aborts
   because the comparison row still exists. This ordering was verified
   directly against SQLite before the schema change and is pinned by tests on
   both the fresh and the migrated schema.

2. **H2 — the schema-version number no longer identified the object
   inventory.** `CatalogMigrations.ExpectedState` listed only a subset of the
   canonical triggers and indexes, so a catalog reporting the current version
   could silently run without required objects. Version 7 replaces the
   name-only lists with **one complete canonical inventory**: every table,
   and every trigger and index carrying its exact DDL. On every open,
   `verifyCurrentSchemaState()` compares each stored trigger/index definition
   against the canonical one in normalized form (whitespace, case, comments
   and `IF NOT EXISTS` stripped), so a missing object, a removed index, or a
   same-name trigger whose definition was substituted is rejected loudly.
   `ExpectedStateInventoryTests` derives the canonical object set from
   `docs/database/schema.sql` and fails on any drift in either direction, so
   the schema file and the production inventory cannot diverge silently.

The v6-to-v7 migration is one explicit transactional step (ADR-024): all
seven triggers and the version row commit together or nothing does. A failed
migration leaves version 6 recorded and no version-7 object behind. Existing
v4/v5 catalogs converge through the existing chain to the same object state
as a fresh v7 catalog. Snapshots, entries, profile versions, terminal
status/count guards, and all prior constraints are untouched.

## ADR-024 — Catalog schema moves forward only by explicit, transactional migration

**Status:** Accepted (2026-08-04, Milestone 3, supersedes the version-4 behaviour)

Condition C2 of the Milestone 2 acceptance audit reproduced two materially different schemas both reporting version 4: catalogs created before the four completed-snapshot immutability guards existed, and catalogs that received them from `CatalogDatabase.installCurrentSchemaGuards()`, which executed DDL unconditionally on every open. The version number had stopped identifying the schema.

From version 5:

1. `docs/database/schema.sql` creates a catalog at the current version and is **never** replayed against an existing one.
2. An existing catalog moves forward only through a step in `CatalogMigrations.all`: all statements plus the `schema_migrations` row commit in one transaction, or nothing does. A failure rolls back and leaves the recorded version untouched, so the next open retries from a known state.
3. `verifyCurrentSchemaState()` runs on **every** open, fresh or migrated, and fails loudly if any expected table, trigger, index or column is missing. A version number is no longer taken as proof of a schema.
4. Versions 1 through 3 have no migration and never will — no such database was ever materialized. They are rejected rather than guessed at.
5. A version above the current one is rejected, unchanged.

Idempotent DDL is used only where it is needed to converge the two known version-4 variants; everything else is new in version 5 and cannot already exist.

## ADR-025 — One process owns a catalog, enforced by an advisory lock

**Status:** Accepted (2026-08-04, Milestone 3)

Condition C5 of the Milestone 2 acceptance audit: `RecoveryService` converts every `scanning` snapshot to `interrupted` at startup with no ownership check, so a second FSD instance would mark a live capture interrupted. The running capture then failed safely rather than corrupting data, but the single-process assumption was neither enforced nor documented.

`CatalogProcessLock` takes a non-blocking `flock` on `<catalog>.lock` before the catalog is opened and before recovery runs. A second process fails at startup with a message naming the holder, and quits safely. The lock is per catalog, so tests and probes on separate catalogs never contend. Because `flock` belongs to the open file description, the kernel releases it when the owning process exits for any reason — a crash or a force quit leaves a lock *file* but never a held lock, so a stale file can never permanently block startup.

Explicitly not built: any cross-process coordination protocol, any networking, any shared-catalog concurrency model. Rejecting the second process is the whole mechanism.

## ADR-026 — Catalog path is overridable for development and tests, never silently in a release

**Status:** Accepted (2026-08-04, Milestone 3)

Condition C6 of the Milestone 2 acceptance audit: the catalog path was fixed to Application Support, and macOS resolves `NSHomeDirectory()` from the user record rather than `$HOME`, so no isolated catalog could be created. Every automated run — including the audit's own — had to share the project owner's real catalog.

`CatalogLocationResolver` now resolves in this order:

1. `-FSDCatalogPath <path>` or `FSD_CATALOG_PATH`, honoured in DEBUG builds only. A Release build resolves the default and reports the ignored request rather than silently redirecting a real catalog to an arbitrary path.
2. An XCTest host. FSD's test bundle is hosted by the FSD application, so every `xcodebuild test` run starts a real `ApplicationModel`; without this the test host opened, migrated and locked the person's actual catalog on every run. A test host always gets its own catalog under the temporary directory.
3. `~/Library/Application Support/FSD/catalog.sqlite3` — the production default, unchanged.

The resolved path and any refused override are printed to standard error at startup and shown in the app, so which catalog is in use is never a guess.

## ADR-027 — Comparison result integrity: profile versions, terminal immutability, and schema version 6

**Status:** Accepted (2026-08-04, Milestone 4)

Schema version 5 carried the comparison tables (`comparison_profiles`,
`comparisons`, `comparison_collision_groups/members`, `comparison_results`)
with side-ownership, eligibility and normalization-version triggers, but two
contract requirements of Milestone 4 could not be expressed in version 5:

1. **Profile revisions must be frozen on the comparison record.** A profile
   must record its version, and a later profile edit must never silently
   reinterpret an earlier comparison's conclusion. Version 5 had no version
   anywhere; only the frozen result rows themselves protected conclusions.
2. **Terminal comparison state must be protected.** A completed comparison's
   status and summary counts could be edited and its detailed rows could be
   inserted or updated after the fact with no database guard.

Schema version 6 therefore adds the smallest possible wave (one explicit
transactional migration, ADR-024):

- `comparison_profiles.version INTEGER NOT NULL DEFAULT 1` — the profile's own
  monotonic revision;
- `comparisons.profile_version INTEGER NOT NULL DEFAULT 1` — the revision the
  comparison ran with, frozen at creation;
- `trg_comparisons_terminal_immutable` — rejects any later change of
  `status`/summary counts once a comparison is `complete`, `cancelled` or
  `failed`;
- `trg_comparison_results_insert_guard` / `trg_comparison_results_update_guard`
  — reject any later INSERT or UPDATE of result rows on a terminal comparison
  (deleting a whole comparison remains the explicit disposal API, which is
  also how workspace close releases transient snapshots per ADR-012);
- `idx_comparison_results_type (comparison_id, result_type)` — bounded
  differences-only queries.

Canonical orientation (recorded here because the later comparison UI builds on
it): the **left side is the reference ("before") tree** and the **right side
is the changed ("after") tree**; `added` = present only on the right,
`removed` = present only on the left. `liveToSnapshot` therefore stores the
snapshot as the left side and the live tree as the right side, so `added`
means "new since the snapshot".

Engine invariants that this ADR confirms: comparison is metadata-only and
offline; `added`/`removed`/`changed`/`matched`/`ignored`/`uncertain` are the
exact schema outcome names; entries with `is_inaccessible` on either side
become `uncertain` (recorded metadata is not a trustworthy picture, so no safe
conclusion exists even though identity is known); case-folded key collisions
become `uncertain` groups and are never paired (ADR-010); summary counts are
recomputed from the persisted rows at the terminal transition, so a cancelled
or failed comparison's summary always matches its retained evidence; and an
abandoned `running` comparison is recovered as `failed` at launch, never
`complete`. No classification rows are read or written by any comparison path.

## ADR-029 — Bounded user-visible error surfaces and a typed cap for pathological collision groups (Milestone 5 closeout)

**Status:** Accepted (2026-08-04, Milestone 5)

Two Milestone 5 closeout decisions, both recorded because they are durable
and both verified at final scale:

**1. The visible capture UI uses one shared bounded error mapper.**
`FSD/App/CaptureErrorDescription.swift` maps every failure the legacy capture
screen can show (scanner, provider, writer/database, detector, cancellation,
unknown) to fixed or safely typed wording. Arbitrary diagnostic strings
(SQLite, POSIX/Cocoa, filesystem, path, provider internals) never reach
visible text; the raw diagnostic is retained only on the standard-error
channel, the same channel startup diagnostics already use — no new write path
is introduced. This is the capture surface's own boundary, deliberately
separate from the comparison GUI's `ComparisonUIErrorDescription` (same
policy, no coupling between the two UIs' models). Adversarial tests prove two
arbitrary diagnostics produce identical bounded visible text
(`FSDTests/CaptureErrorBoundaryTests.swift`). KI-022 is closed.

**2. A pathological equal-key collision group is a typed failure, not a
memory hazard.** The comparison engine materializes one equal-key collision
group in an array before persisting it (KI-019 follow-up). `EntryStream
.consumeGroup` now throws the typed `ComparisonError.collisionGroupTooLarge`
once a single group exceeds `ComparisonEngine.maxCollisionGroupMemberCount`
(100,000); the comparison terminalizes `failed` (never `complete`), and the
GUI maps the error to bounded fixed wording. The bound is far above any
legitimate key (a real collision group is two to a handful of members), so it
changes nothing for real catalogs; it converts an unbounded-memory condition
into a safe, deterministic, schema-clean failure (verified at final scale
with a 150,000-member fixture). Ordinary keys remain page-bounded.

## ADR-030 — Dedicated parent-result index for comparison disposal (schema version 8)

**Status:** Accepted and implemented (2026-08-05, Milestone 5 KI-024 correction)

The self-referencing foreign key
`comparison_results.parent_result_id REFERENCES comparison_results(id) ON
DELETE CASCADE` requires SQLite to find child rows by `parent_result_id` while
disposing a comparison. The existing composite index begins with
`comparison_id`, so it cannot serve that parent-only lookup. The canonical
schema therefore adds the small additive index
`idx_comparison_results_parent_result_id` on
`comparison_results(parent_result_id)`. The existing composite index remains;
no query semantics or ordering are reinterpreted.

Schema version 8 is reached only through one explicit transactional v7-to-v8
migration. The index creation and version-8 record commit together or roll
back together. `CatalogMigrations.ExpectedState` includes the index's
normalized canonical DDL, and current-schema verification continues on every
open; missing, substituted-column or substituted-order definitions are
rejected. Fresh catalogs and v4/v5/v6/v7 migrated catalogs converge to the
same object inventory.

The index is an implementation detail and not a product feature. It changes
disposal performance only: comparison matching, result ordering, outcomes,
paging, navigation, collision evidence, terminal immutability, explicit
disposal and ADR-012 workspace-close semantics remain unchanged. Release
synthetic one-million-result regressions measured 9.930 s for explicit
disposal and 10.018 s for automatic live-workspace close, both below the
120-second threshold, with clean integrity/foreign-key checks and a successful
subsequent write. At the correction stage, the focused independent re-audit
remained required; MVP approval and manual acceptance were not claimed.

**Closure amendment (2026-08-05): focused schema-v8/disposal re-audit CLOSED —
APPROVE WITH CONDITIONS**, per
`handoffs/FSD_M5_SCHEMA_V8_DISPOSAL_REAUDIT_A_20260805-223211.md`.
This supersedes the original pending gate. The test-count wording condition
is already corrected in `TEST_PLAN.md` (284 executed, 281 passed, 0 failed,
3 skipped). Manual acceptance remains **NOT PERFORMED — DEFERRED BY OWNER**;
overall MVP approval remains **NOT CLAIMED**.

## ADR-031 — Nullable classification enrichment boundary uses schema version 8

**Status:** Accepted and implemented (2026-08-05, Phase 1.5 preparation)

FSD prepares for optional local file-type enrichment without weakening the
metadata-only product boundary. The existing schema-v8
entry_classifications table is reused; no schema version 9, provider column,
raw provider output, payload, sampled bytes or content hash is introduced.
EntryClassificationRepository exposes typed append-only writes, deterministic
duplicate-run rejection, nonexistent-entry rejection, latest-row reads and a
bounded visible-entry page read. It has no update or delete API, so adding
enrichment cannot mutate entries, snapshots, snapshot totals or completion
state.

LocalFileClassificationProvider is a local-only adapter boundary. The
built-in DisabledFileClassificationProvider returns unavailable without
filesystem access. ClassificationEnrichmentService is explicit-only and is
not injected into capture, browse, search, export or comparison. Stored
classification is inferred metadata only and never affects comparison identity,
outcomes, paging, navigation or terminal evidence. The browser shows bounded
values for a selected entry and a neutral "Not classified" state when absent.
The JSON export remains format version 1 and excludes classification.

Magika inference is not active, not installed and not a dependency. Any future
byte-reading provider requires a separate approved bounded policy and must not
backfill old snapshots. Manual acceptance remains **NOT PERFORMED — DEFERRED BY
OWNER**. The original preparation-stage next action was an independent focused
audit of this boundary.

**Closure amendment (2026-08-07): nullable enrichment boundary audit CLOSED —
APPROVE WITH CONDITIONS**, per
`handoffs/FSD_P15_MAGIKA_NULLABLE_ENRICHMENT_AUDIT_R_20260807-142313.md`.
This supersedes the original audit-next gate. Its deferred manual acceptance,
inactive runtime and separately tracked limitations remain unchanged.

## ADR-032 — Magika Runtime Adapter Design

**Status:** Accepted (Design Phase)

**Completion amendment (2026-08-07): runtime design COMPLETE**, per
`handoffs/FSD_P15_MAGIKA_RUNTIME_DESIGN_A_20260807-155630.md`.
Runtime implementation is **NOT STARTED / INACTIVE**, current schema remains
**v8**, and the schema change required below needs separate authorization
before runtime implementation. No migration or runtime is implemented by this ADR.

The Magika file-type enrichment adapter packaging was evaluated across four shapes.

**Supersession amendment (2026-10-06, ADR-033): provider commitment superseded, packaging decision retained.** ADR-032's Magika-specific provider commitment is superseded: no provider is currently selected and future selection is provider-neutral. Magika remains a blocked, non-exclusive candidate; its task-025 verification STOP is preserved as prior candidate evidence and is neither a rejection nor an approval. ADR-032's packaging/process-isolation decision — a locally bundled helper executable inside `FSD.app`, arm64, offline, self-contained, separately crash-isolated — remains accepted, now against a macOS 15+ floor. The historical four-option evaluation below is preserved as the basis of that packaging decision and records the macOS 13 floor current when it was written; it defines no current compatibility claim and no candidate may assume macOS 15 compatibility before the Slice 07 gate verifies it. All bounded-byte, read-only, provenance and snapshot-isolation invariants below are unchanged.

1. **Native in-process library/model embedding:**
   - **Offline behavior:** Fully offline.
   - **Deployment complexity:** High (requires bridging C++ or rewriting in Swift).
   - **Startup cost:** Loads with the app.
   - **Sandbox/process boundary:** None. Runs in the main process.
   - **Dependency management:** Requires vendoring source/models, risking conflict with minimal dependencies.
   - **macOS 13 arm64 fit:** Native fit if compiled correctly.
   - **Licensing/redistribution facts:** `EXTERNAL VERIFICATION REQUIRED` (Compatibility of Magika's license with in-process app distribution).
   - **Failure modes:** Classifier crash takes down the entire FSD application.
   - **Update/version provenance:** Version is implicitly tied to the FSD release cycle.

2. **Locally bundled helper executable:**
   - **Offline behavior:** Fully offline.
   - **Deployment complexity:** Moderate (separate executable bundled in the `.app`).
   - **Startup cost:** Spawns per use (or runs as a persistent service).
   - **Sandbox/process boundary:** Separate process, reusing the isolation pattern established in `FILESYSTEM_PROVIDER_ARCHITECTURE.md` §8.
   - **Dependency management:** Isolated from the main app target.
   - **macOS 13 arm64 fit:** Native fit.
   - **Licensing/redistribution facts:** `EXTERNAL VERIFICATION REQUIRED` (Compatibility of distributing the model inside the app bundle).
   - **Failure modes:** Classifier crash or hang fails the individual classification; the main FSD app survives. Missing helper returns unavailable.
   - **Update/version provenance:** Helper can report its compiled-in version explicitly.

3. **Python/runtime dependency:**
   - **Offline behavior:** Fully offline.
   - **Deployment complexity:** High (requires bundling a Python runtime).
   - **Startup cost:** Spawns per use with Python interpreter overhead.
   - **Sandbox/process boundary:** Separate process.
   - **Dependency management:** Massive footprint increase, conflicting with `AGENT.md` minimal dependencies.
   - **macOS 13 arm64 fit:** Depends on Python runtime availability.
   - **Licensing/redistribution facts:** `EXTERNAL VERIFICATION REQUIRED` (Python runtime and dependency redistribution licensing).
   - **Failure modes:** Crash fails classification; main app survives.
   - **Update/version provenance:** Difficult to pin if relying on environment packages.

4. **External command-line Magika installation:**
   - **Offline behavior:** Fully offline.
   - **Deployment complexity:** Pushes installation burden to the user, violating the self-contained `.app` invariant.
   - **Startup cost:** Spawns per use.
   - **Sandbox/process boundary:** Separate process.
   - **Dependency management:** Zero build-time dependency, but unpredictable runtime dependency.
   - **macOS 13 arm64 fit:** Depends on user's installed build.
   - **Licensing/redistribution facts:** No distribution by FSD.
   - **Failure modes:** Missing or incompatible tool fails classification; main app survives.
   - **Update/version provenance:** Opaque; user can update independently, making exact provenance hard to record.

**Decision:** Locally bundled helper executable.
Shape 1 was ruled out because a classifier crash would take down the main app.
Shape 3 was ruled out because bundling a Python runtime violates the "minimal dependencies" priority.
Shape 4 was ruled out because it requires user installation, which violates the platform invariant of a single self-contained `.app`.
Regardless of the packaging, zero network traffic and the metadata-only default are strictly preserved.

Classification will be bounded to a single 4096-byte prefix read per file (PROPOSED). The provider API will receive only the bounded `Data` buffer, never a `URL` or path, ensuring it cannot independently traverse the filesystem. Bytes read for classification are unconditionally never persisted, hashed, or logged.

**Schema Verdict:**
1. What does `detector_version` identify? Per `EntryClassificationRepository.swift` and ADR-031, it identifies the detection algorithm version, serving as one of the explicitly "persisted provenance fields".
2. What does `model_version` identify? Per the same sources, it identifies the model version used, serving as the other explicit "persisted provenance field".
3. What independent fact does provider/adapter identity represent, and how is it different from both of the above? Provider/adapter identity represents which packaging shape or process produced the row (e.g., a locally bundled helper executable). This is a distinct dimension because the same detector/model version can run under different packaging shapes over the adapter's lifetime.
4. Why must those three facts remain separately, durably recoverable rather than merged into one field? A future reader needs to answer "which detector version produced this row" and "which adapter produced this row" as two independent questions, without depending on an undocumented, unenforced string convention to disentangle them.
5. Can schema v8 — as it actually exists today, not as a hypothetical encoding convention — represent all three facts without semantic overloading? No. The real column list in `schema.sql` provides only `detector_version` and `model_version`, meaning the adapter identifier remains "runtime-only" without semantic overloading.

Conclusion: `SCHEMA CHANGE REQUIRED BEFORE RUNTIME`.
Exactly one minimal missing field, `provider_identifier`, is required to record which adapter/process produced the row, independent of the algorithm and model versions. `detector_version` must not be overloaded to carry this fact because it would merge two orthogonal facts, forcing future queries to rely on an undocumented string convention to disentangle "which adapter" from "which detector".

## ADR-033 — macOS 15+ deployment floor and provider-neutral classification strategy

**Status:** Accepted (2026-10-06, Owner decision)

**Owner decision and provenance:** the Owner changed the minimum supported macOS deployment from 13+ to 15+ and selected a provider-neutral path for future local classifier selection, after BRAIN accepted the task-025 Magika verification STOP (blocked on unresolved redistribution rights, exact artifact SHA256 closure, the then-macOS13 compatibility proof and complete native-runtime license/notice/resource closure) and after Worker task 026 correctly stopped before mutation because active macOS13 authority existed outside its allowlist. Recorded in `STATE/EVENTS.jsonl` as the Owner decision at 2026-10-06T11:39:53+07:00 and authorized for canonicalization as `FSD_PLATFORM_MACOS15_CLASSIFIER_STRATEGY_CANONICALIZATION_RESCOPE_026A`.

### Decision

1. FSD's minimum supported OS is now **macOS 15 (Sequoia) or later**. Current product wording is "macOS 15 Sequoia or later"; the Xcode deployment target is `MACOSX_DEPLOYMENT_TARGET = 15.0`. Architecture remains Apple Silicon `arm64` only, and the Swift 5.9+ / SwiftUI shell / AppKit large-tree / SQLite-canonical / single self-contained `.app` invariants are unchanged.
2. This **supersedes every active** product, architecture, governance and build claim of a macOS 13 minimum — including `macOS 13+`, `macOS 13`, "Ventura or later", `MACOSX_DEPLOYMENT_TARGET = 13.0`, the `Platform invariant` line in `docs/AGENT.md`, and the FSKit exclusion rationale that rested on FSKit's macOS 15+ floor exceeding FSD's macOS 13 minimum. Historical Handoffs, dated receipts and prior ADR evaluation bodies remain immutable historical evidence and are not rewritten.
3. ADR-032's **packaging and process-isolation decision remains accepted**: the classifier runs as a locally bundled helper process inside `FSD.app`, arm64, offline, self-contained, separately crash-isolated, never discovered via `$PATH` and never requiring a Python runtime, Homebrew, or any user/system-installed classifier. The Slice 03 host seam remains accepted infrastructure.
4. ADR-032's **Magika-specific provider commitment is superseded**. The current strategy is `PROVIDER_NEUTRAL_LOCAL_CLASSIFIER`: no provider is selected by this ADR.
5. **Magika remains a blocked candidate** — `BLOCKED_NON_EXCLUSIVE_CANDIDATE` — not rejected and not approved. Its task-025 evidence is preserved exactly: native bounded byte-slice fit was supported and detector/model provenance looked feasible, while model redistribution rights, exact model/resource SHA256 closure, the then-macOS13 compatibility proof and complete native-runtime license/notice/resource closure remained unresolved. Those four gaps were facts about that candidate at that time and are **not** converted into permanent generic blockers for every future candidate.
6. **Future provider selection requires a separate authoritative external research gate** (`docs/P15_RUNTIME_PLAN.md` Slice 07, now provider-neutral) verifying, per candidate: license and redistribution rights, exact artifact identity and checksums, **macOS 15 arm64** compatibility, native runtime/dependency and resource closure, bounded in-memory input API fit, offline/no-network/no-telemetry behavior, process-tree behavior, output/provenance mapping, and bundle/signing placement. No candidate may be assumed macOS 15 compatible before that gate proves it.
7. **All classification safety invariants remain unchanged**: explicit selected-entry invocation only; FSD-owned bounded `Data` input with a single prefix read of at most 4096 bytes; the provider never receives path, URL, file descriptor, `FileHandle`, filesystem resolver, source callback or any additional-byte callback; FSD owns the source bytes and source media stay read-only; no network, telemetry, watcher, backfill, daemon, automatic classification, sampled-byte persistence, sampled-byte hashing or sampled-byte logging; classification is inferred metadata only; snapshot facts are immutable; and a detected content type is never historical content verification.
8. **No provider is selected by this ADR** and **no real helper integration is authorized by this ADR**. Naming of existing `Magika`-containing Swift/Xcode identifiers is implementation history and does not select or imply a provider; a future integration task may address naming only after a provider is actually selected.

### Consequences

Product, architecture, plan, test, UX, security, governance and build authorities now state the macOS 15+ floor and a provider-neutral future classifier gate. Slice 08's prerequisite is a real audited bundled classifier helper rather than a named provider. The FSKit filesystem exclusion stands on its app-extension/user-approval ground alone; the deployment-floor ground is superseded and must not be cited again.
