# FSD Architecture and Implementation Review

> Historical reference only. Original schema/status/findings/then-next language
> below is dated evidence, not live control authority. Use `STATE/PROJECT_STATE.md`
> for control, `PRODUCT_STATE.md` for implementation and `MVP_PLAN.md` for roadmap.
> Retired paths in the original body are historical citations: retrieve exact
> bytes with `git show 041d2af2076ff4418f9ea5d98b124c435ea8db43:<repo-relative-path>`.
> Former known-issue IDs resolve in `docs/PRODUCT_STATE.md`; bundle/manifest/support
> citations have Git-history-only recovery. Original body is preserved verbatim.

- **Reviewer role:** Senior macOS application architect, filesystem engineer, SQLite performance reviewer, UX reviewer
- **Review date:** 2026-07-24
- **FSD_ROOT:** `/Users/cenvu/Desktop/DEV/FSD`
- **Project state at review:** Documentation-only scaffold. No Swift code exists. `docs/` contains 16 markdown documents, `database/schema.sql`, two JSON samples, and `PROJECT_SUPPORT/`.
- **Reference checkout:** `visualdiffer/visualdiffer` cloned read-only to `/tmp/FSD_VISUALDIFFER_REFERENCE`, commit `fbd1ef685626cc6dd25976e6e9670adba204e33a` (matches the commit recorded in `REFERENCE_VISUALDIFFER.md`). No files in the checkout were modified.

---

## 1. Executive Verdict

**GO WITH REQUIRED REVISIONS.**

The product logic is coherent and unusually well-bounded for a planning-stage project. The core differentiator — persistent, immutable, metadata-only snapshot generations in SQLite, browsable after eject — is correctly identified, correctly distinguished from VisualDiffer's live-only model, and correctly protected by product-language rules ("Metadata Match", never "Verified").

However, three specification-level defects must be fixed **before any production Swift code is written**, because they sit under everything else:

1. The `entries` table's `UNIQUE(snapshot_id, normalized_path)` constraint will abort legitimate scans of case-sensitive filesystems (a fixture case the project's own `TEST_PLAN.md` requires).
2. Path normalization — the equality key of the entire product — is undefined at the byte level (no Unicode normalization form, no case-folding rule, no cross-filesystem comparison rule).
3. Comparison against a *live* folder or volume has no defined execution model; the architecture only defines snapshot-row comparison, so PRD user story US-04 is currently unimplementable as specified.

None of these require redesign. They require decisions and one schema change. Everything else in this report is prioritized hardening.

---

## 2. Documents Reviewed

All files under `FSD_ROOT/docs` were read in full:

| Document | Notes |
|---|---|
| `README.md` | Identity, capability list, recommended implementation order |
| `PRD.md` | User stories, functional/non-functional requirements, language rules |
| `AGENT.md` | Contributor invariants, prohibited behaviors, handoff protocol |
| `PROJECT_MANIFEST.md` | Canonical invariants list |
| `PRODUCT_STATE.md` | Confirms nothing implemented |
| `DECISIONS.md` | ADR-001 … ADR-008 |
| `ARCHITECTURE.md` | Components, scanner phases, concurrency, failure handling |
| `UX_UI_SPEC.md` | Screens A–C, states, settings, safety copy |
| `MVP_PLAN.md` | Phases 0–5 plus deferred backlog |
| `KNOWN_ISSUES.md` | KI-001 … KI-008 |
| `TEST_PLAN.md` | CT-001 … CT-005, fixtures, filesystem matrix |
| `SECURITY_AND_READ_ONLY_POLICY.md` | Allowed/prohibited writes (note: the task brief calls this `READ_ONLY_POLICY.md`; only the longer filename exists) |
| `REFERENCE_VISUALDIFFER.md` | Reference study — largely accurate; verified against source below |
| `PLACEMENT.md`, `BUNDLE_FILE_MANIFEST.md` | Bundle mechanics |
| `database/schema.sql` | v1 schema — findings below |
| `samples/snapshot.example.json`, `samples/diff.example.json` | Export shape examples |
| `PROJECT_SUPPORT/*` | App structure, config, releases, scripts, test layout, handoffs, gitignore |

Cross-checking found the contradictions and gaps recorded in Section 5. The documentation set is consistent in tone and invariants; drift is mostly in vocabulary (snapshot status names) and in scope boundaries (signatures, export ordering).

---

## 3. VisualDiffer Areas Reviewed

Verified from source, not from its README. Files read in full or in relevant part:

- `Sources/Features/FoldersCompare/CompareItem/CompareItem.swift` (387 lines) — canonical in-memory tree node: `parent`, `children`, `linkedItem` (opposite panel), `visibleItem`, `CompareSummary`, flag set (`isFile/isFolder/isSymbolicLink/isPackage/isResourceFork/isLocked/isValidFile`).
- `Sources/Features/FoldersCompare/Services/FolderReader/FolderReader.swift` (391 lines) — recursive enumeration via `FileManager.contentsOfDirectory(atPath:)` + **per-entry `attributesOfItem(atPath:)`**; symlink-loop protection by walking ancestors and comparing `systemFileNumber`/`systemNumber` (more stat calls per symlink); package skip via `filterConfig.skipPackages`; sandbox fallback through `SecureBookmark` when a symlink escapes granted scope.
- `Sources/Features/FoldersCompare/Services/ItemComparator/ItemComparator.swift`, `+Compare.swift`, `+Align.swift` — flag-driven comparison (`filename`, `timestamp`, `size`, `content`, `asText`, Finder labels/tags); pairwise merge-join alignment over the two sorted child arrays (`AlignPosition` advancing left/right indexes), with regex-based alignment rules and a per-directory match cache; **`compareContent`/`compareAsText` open and read file payloads, including resource forks**.
- `Sources/Features/FoldersCompare/CompareItem/CompareItem+Comparison.swift`, `+VisibleItem.swift` — status propagation into parent summaries.
- `Sources/Core/History/HistoryEntity.swift`, `HistorySessionManager.swift`, `Sources/Core/SessionDiff/SessionDiff.swift` — Core Data entities. **Verified: history stores `leftPath`, `rightPath`, comparator/display/filter flags, sort state, timestamps, starred. No scanned tree entries are persisted.** Reopening a session revalidates and re-reads the live paths (`awakeFromFetch` re-standardizes paths; `SessionDiff+ResolvePath.swift`).
- `Sources/Core/Document/VDDocument.swift`, `VDDocumentController` — document lifecycle around sessions.
- `Sources/Features/FoldersCompare/Components/FoldersOutlineView/FoldersOutlineView.swift` — paired panels via `linkedView` with a `lockExpand` reentrancy guard for synchronized expand/collapse; registers only `NSPasteboard.PasteboardType.fileURL` for drops; drags out real file URLs.
- `Sources/Features/FoldersCompare/Controller/FoldersWindowController+FoldersOutlineView.swift` — drop validation calls `FileManager.default.fileExists(atPath:isDirectory:)` and only accepts existing directories; 1 dropped URL sets the drop-side path, 2 URLs set left and right; drop triggers `reloadAll` (full re-scan).
- `Sources/Features/FoldersCompare/Controller/OutlineViewItemDelegate.swift`, `Controller/FileSystemController/Sync/SyncOutlineView.swift` — note: `SyncOutlineView` is the *synchronize-files operation preview* (part of the sync file-operation UI), not the synchronized-scrolling mechanism; the panel pairing lives in `FoldersOutlineView.linkedView`.
- `Sources/Features/FoldersCompare/FileManager/` — `FileOperationManager` plus Copy/Move/Delete/Rename/Touch executors; `Controller/FileSystemController/` Copy/Delete/Move/Sync/Touch. All out of FSD scope.
- `Sources/SharedKit/Utilities/Document/SecureBookmark.swift` (171 lines) — security-scoped bookmark store in `UserDefaults`, ancestor-path reuse (`findClosestPath`), stale-refresh with balanced start/stop access, lock-protected mutation.
- `Sources/SharedKit/Utilities/View/FileDrop/FileDropView.swift` — path-well drop target; accepts `fileURL` only; icon feedback via `NSWorkspace` (live path required).
- `Tests/Sources/FileSystem/`, `Tests/Sources/UI/` — present; test layout confirms filesystem-operation coverage exists (further reinforcing that mutation is a first-class VisualDiffer feature FSD must not inherit).

Answers to the six mandated distinctions are in Section 12.

---

## 4. Product Logic Assessment

**Coherent: yes.** The product is a *catalog with comparison*, not a differ with history bolted on. The documents consistently enforce:

- metadata-only capture (ADR-003, PRD §8, `AGENT.md`);
- immutable generations (ADR-004, `PROJECT_MANIFEST.md` invariant 5);
- read-only sources (`SECURITY_AND_READ_ONLY_POLICY.md`, PRD §7);
- honest equality language (PRD §10, UX safety copy, `contentVerified: false` in both JSON samples).

**Sufficiently constrained: mostly.** The MVP boundary (no hashing, no playback, no sync, no thumbnails) is stated in five separate documents without contradiction. The under-constrained areas are exactly the ones a scanner implementer hits first: path normalization bytes, item-type taxonomy, live-source comparison, and volume identity fallback. These are itemized as findings.

**Equality terminology check: passes.** No document presents metadata equality as "bit-identical", "checksum verified", "verified backup", or "content verified". PRD §10 explicitly bans these. Recommended product terms are already present and correct:

- structure-only match → **"Structure Match"**;
- path-and-size match → **"Metadata Match"** (Fast Metadata profile);
- strict metadata match → **"Strict Metadata Match"** (recommend surfacing the profile name in the result banner);
- verification status → **"Content Not Verified"** (already required as a persistent disclaimer).

One addition is recommended: when a comparison involves a snapshot, the summary bar should state the *capture timestamps* of both sides ("comparing state as of 24 Jul 17:42 vs live state now"), because a metadata match against a stale snapshot is a temporally-qualified claim, not just a content-qualified one.

**Read-only invariant: strong on paper, one structural weakness.** The policy prohibits the right things and asks for architectural controls (separate service interfaces, mutation-free scanner protocols, before/after integration test CT-001). The weakness is ADR-006: deferring App Sandbox removes the single strongest *platform-enforced* control available — `com.apple.security.files.user-selected.read-only` makes source mutation impossible at the kernel boundary rather than at code review. See FSD-ARCH-004. Additional recommended controls (none currently documented):

- a `ReadOnlySourceRoot` wrapper type that is the *only* way scanner code receives a URL, constructed solely by the capture coordinator;
- put the scanner and repository in separate SwiftPM modules where the scanner module does not link any code path that can obtain a writable `FileManager` operation (enforced by a lint deny-list: `copyItem`, `moveItem`, `removeItem`, `createFile`, `createDirectory`, `setAttributes`, `replaceItem`, `trashItem`, `setResourceValues`, `URLResourceValues` setters);
- a CI grep/SwiftLint custom rule failing the build on those symbols inside `Capture/` and `Catalog/` targets;
- CT-001 automated (APFS sparse-image fixture, snapshot before/after via `fs_usage`-free directory state diff), not manual-only.

---

## 5. Critical Findings

### BLOCKER

### [BLOCKER] FSD-DB-001 — `UNIQUE(snapshot_id, normalized_path)` aborts legitimate scans

**Evidence**

- Document or source file: `database/schema.sql` lines 68–101 (`entries`), line 100: `UNIQUE(snapshot_id, normalized_path)`.
- Relevant section, symbol, or behavior: `TEST_PLAN.md` §2 requires a fixture with "case-collision names on case-sensitive filesystem".

**Problem**

If `normalized_path` is a case-folded (and/or Unicode-normalized) comparison key — which is its stated purpose in `ARCHITECTURE.md` §5 ("store an additional normalized comparison key") — then two distinct files on a case-sensitive volume (`Report.txt` and `REPORT.TXT`) produce the same `normalized_path`. The `INSERT` violates the UNIQUE constraint and the batch transaction fails. The same applies to Unicode-normalization collisions on filesystems that store names as raw byte sequences (exFAT, NTFS, SMB): two distinct names can share one NFC form.

**Impact**

A scan of any case-sensitive APFS volume containing a case collision fails mid-capture or silently drops entries, depending on conflict handling. The project's own required test fixture would fail against its own schema. This also poisons the diff engine, which joins on `normalized_path` and would need collision semantics anyway.

**Recommendation**

- Drop the UNIQUE constraint on `normalized_path`. Keep `idx_entries_snapshot_normalized_path` as a non-unique index.
- If a uniqueness guarantee is wanted for integrity, make it `UNIQUE(snapshot_id, parent_id, name)` — byte-exact original name within a parent is genuinely unique on every filesystem.
- Define diff behavior for collisions: when one side has N entries folding to the same key, classify them `uncertain` (`!`) rather than pairing arbitrarily, and record a scan/compare issue.

**When to address**

- Before coding

---

### [BLOCKER] FSD-ARCH-001 — Path normalization is undefined at the byte level

**Evidence**

- Document or source file: `ARCHITECTURE.md` §5 "Path normalization"; `AGENT.md` ("Relative path normalization must be deterministic"); `database/schema.sql` (`normalized_path`, `normalized_name` columns).
- Relevant section, symbol, or behavior: no document specifies Unicode normalization form, case-folding algorithm, or cross-filesystem comparison policy.

**Problem**

"Deterministic" is asserted but never defined. Missing decisions:

1. **Unicode form.** HFS+ stores NFD; APFS is normalization-preserving/insensitive; exFAT/NTFS/SMB store raw. The same visible filename can arrive as different byte sequences from different sources. Without a declared form (recommend NFC for storage of the comparison key, applied with `precomposedStringWithCanonicalMapping`), snapshot-to-snapshot diffs of the *same physical data* copied between volumes will report phantom adds/removes.
2. **Case folding.** `ARCHITECTURE.md` says "define case-sensitivity behavior from source filesystem" — but a comparison has *two* sources. Case-sensitive APFS vs exFAT: which policy wins? (Recommend: fold case in the comparison key only if *either* side is case-insensitive; or simpler and more predictable: always store a case-preserving key plus a folded key, and let the comparison profile choose — the schema already has both `relative_path` and `normalized_path`, so specify: `relative_path` = original bytes joined by `/`; `normalized_path` = NFC + simple case fold (e.g. `folding: [.caseInsensitive, .diacriticInsensitive:false]` semantics — define exactly which `String` API and locale, use `Locale(identifier: "en_US_POSIX")`-independent folding).)
3. **The `/` separator and edge characters.** Colons (Finder displays `/` as `:`), trailing spaces/dots (NTFS), and path length limits are unaddressed.

**Impact**

Every table, index, join, and product claim rests on this key. Getting it wrong after data exists forces a schema migration that must re-derive keys for millions of rows, and historical snapshots captured with the old rule become incomparable with new ones.

**Recommendation**

Write a one-page `PATH_NORMALIZATION.md` (or an ADR) specifying: storage form (bytes as returned by the filesystem for `name`/`relative_path`), comparison-key derivation (exact API calls: NFC via `precomposedStringWithCanonicalMapping`, then locale-independent case fold), separator, root representation (empty string — already stated), maximum depth/length handling, and the two-sided case-sensitivity resolution rule. Store the normalization-rule version in `capture_policy_json` so future rule changes are detectable.

**When to address**

- Before coding

---

### [BLOCKER] FSD-ARCH-002 — Live-source comparison has no execution model

**Evidence**

- Document or source file: `PRD.md` US-04 ("supported sources: live folder, live volume root, offline snapshot folder"); `ARCHITECTURE.md` §2 TreeDiffEngine ("compare normalized nodes", reads SQLite); `database/schema.sql` `comparisons` table (`left_snapshot_id`/`right_snapshot_id` only — both `REFERENCES snapshots`); `REFERENCE_VISUALDIFFER.md` §14 checklist ("Define the ComparisonSource abstraction") — never defined anywhere.

**Problem**

The diff engine is specified as a SQLite-row comparator, and the `comparisons` table can only reference snapshots. There is no definition of how a *live folder* participates: is it scanned into a transient snapshot first (making live-vs-snapshot a special case of snapshot-vs-snapshot), or does the engine stream filesystem enumeration against snapshot rows? These have very different consequences for cancellation, sorting, memory, progress UI, and the `comparisons` schema.

**Impact**

US-04 and MVP Phase 3 ("compare live folder with snapshot") are unimplementable as documented. If discovered during Phase 3 implementation, it forces either an unplanned schema change or an ad-hoc second diff path that bypasses the SQL engine and its lazy-loading guarantees.

**Recommendation**

Adopt the **ephemeral snapshot** model and document it as an ADR:

- Any live source selected for comparison is captured through the normal scanner into a snapshot row flagged with a new column `kind TEXT CHECK (kind IN ('user','transient')) DEFAULT 'user'`.
- The diff engine then *only ever* compares two snapshots — one code path, one set of guarantees, and live-vs-live, live-vs-snapshot, snapshot-vs-snapshot all unify.
- Transient snapshots are garbage-collected by age/count and are excluded from snapshot history UI, but a user action "Keep this capture" promotes `transient → user`.
- This also cleanly answers "compare volume vs its own history": drag live volume → transient capture → diff.
- Consequence to embrace: comparing a live source is never instant (a capture runs first). Surface capture progress in the compare workspace. This is honest — a metadata scan is the cost of a correct comparison, and it is exactly the cost VisualDiffer pays on every re-open anyway.

Define the `ComparisonSource` abstraction now (see Section 11) so panes, drag-and-drop, and the engine share it.

**When to address**

- Before coding (schema column + ADR); engine work lands before MVP comparison UI

---

### HIGH

### [HIGH] FSD-DB-002 — Subtree-signature scope contradicts itself across three documents

**Evidence**

- Document or source file: `PRD.md` §7 Performance ("Diff must skip identical subtrees when aggregate signatures match"); `ARCHITECTURE.md` §2/§6 (scanner phase 5 "compute metadata signatures"; §6 defines `metadata_signature` and `subtree_signature`); `MVP_PLAN.md` Deferred backlog ("metadata Merkle subtree signatures" — deferred); `database/schema.sql` (`metadata_signature`, `subtree_signature` columns present).

**Problem**

The PRD makes signature-based subtree skipping a *non-functional requirement*, the architecture computes signatures during every scan, the schema reserves per-row BLOBs — and the MVP plan defers the whole mechanism. A subtree signature that recursively hashes child signatures *is* a metadata Merkle tree; the backlog defers a thing the PRD requires.

**Impact**

Either the scanner pays hashing cost for columns nobody reads in MVP, or the diff engine misses its stated performance requirement, or an implementer resolves the contradiction ad hoc. Also, per-row 32-byte BLOB pairs cost ~600 MB at 10M rows if SHA-256 is chosen.

**Recommendation**

Decide now, and the recommended decision is: **MVP ships aggregate-based skipping, not hash-based skipping.** The columns `subtree_file_count`, `subtree_folder_count`, `subtree_logical_bytes` already allow a cheap conservative check: if any aggregate differs the subtree differs; if all match the subtree must still be walked (aggregates can coincide). That satisfies "skip obviously-identical subtrees" honestly for the common case (unchanged subtrees have identical aggregates and their walk short-circuits in SQL as a keyed join with no mismatches). Then:

- amend PRD §7 to "skip subtrees whose aggregate counts and sizes match and whose keyed join yields no differences";
- keep `subtree_signature` columns in the schema but NULL in v1 (documented), and keep true Merkle signatures in the backlog;
- when implemented later, use a fast 8-byte non-cryptographic hash (e.g. xxHash-class) — this is a shortcut key, not a security artifact, and SHA-256 buys nothing here except size; never surface the word "hash" or "signature" in UI (risk of being read as content verification — `ARCHITECTURE.md` §6 already flags this correctly).

**When to address**

- Before coding

---

### [HIGH] FSD-DB-003 — `comparison_results` materializes full result trees, including matched rows

**Evidence**

- Document or source file: `database/schema.sql` lines 163–180: `comparison_results` with `result_type IN (... 'matched' ...)`, `UNIQUE(comparison_id, normalized_path)`, `parent_result_id` tree structure.
- Relevant section, symbol, or behavior: `samples/diff.example.json` summary shows 248,124 matched of 248,130 total.

**Problem**

The schema implies persisting one row per compared path — for the sample volume that is ~250,000 rows per comparison run, ~99.998% of them `matched`. Ten comparisons of a 1M-entry volume ≈ 10M result rows, duplicating `normalized_path` and `display_name` strings a third time. Nothing in the docs states a retention policy for `comparisons`.

**Impact**

Catalog growth dominated by comparison residue rather than snapshots; slow comparison completion (writing 1M rows to record 6 differences); VACUUM pressure after cleanup.

**Recommendation**

- Generate matched results **on demand** from the keyed join of the two snapshots; never persist `matched` rows.
- Persist only: difference rows (`added/removed/changed/uncertain/ignored` if explicitly requested), plus the minimal ancestor-folder rows needed to render the difference tree, plus summary counters on `comparisons`.
- Treat persisted results as a cache: add `expires_at` or delete-on-close policy; document it.
- Large comparisons *can* be done primarily in SQL (this is the right call): `LEFT JOIN`/anti-join on `(normalized_path)` between the two snapshots' entry sets, with `item_type` and profile columns in the join predicate — both sides are indexed by `(snapshot_id, normalized_path)`. Emulate FULL OUTER JOIN with `UNION ALL` of the two anti-joins plus the inner join (or use SQLite 3.39+ `FULL OUTER JOIN`; macOS 13 ships an older system SQLite — if relying on the system library, verify the version at runtime or bundle SQLite; bundling is recommended anyway for deterministic behavior).

**When to address**

- Before MVP comparison UI

---

### [HIGH] FSD-DB-004 — PRAGMA placement in `schema.sql` creates false safety

**Evidence**

- Document or source file: `database/schema.sql` lines 1–3 (`PRAGMA foreign_keys = ON; PRAGMA journal_mode = WAL; PRAGMA synchronous = NORMAL;`); `ARCHITECTURE.md` §2 CatalogRepository "Recommended SQLite settings".

**Problem**

`foreign_keys`, `synchronous`, and `temp_store` are **per-connection** settings; executing them once inside a schema script protects only the connection that ran the script. Any other connection (the read-only diff connection, a future maintenance task) silently runs with `foreign_keys = OFF` — SQLite's default — and cascade rules stop applying. Only `journal_mode = WAL` is persistent in the database file.

**Impact**

Orphaned `entries`/`scan_issues` rows after snapshot deletion on a connection that skipped the pragma; integrity assumptions in `TEST_PLAN.md` §5 ("foreign key enforcement", "orphan entry prevention") silently violated in production while passing in tests that happen to use the initialized connection.

**Recommendation**

Specify in `ARCHITECTURE.md` that the connection factory applies `PRAGMA foreign_keys = ON`, `synchronous = NORMAL`, `temp_store = MEMORY`, `busy_timeout` on **every** connection open, and that `schema.sql` contains only DDL and seed data. Add a startup assertion (`PRAGMA foreign_keys` query) in debug builds. While here: choose and document `wal_autocheckpoint` behavior and an explicit checkpoint on app termination, and consider `PRAGMA page_size = 8192` before first write (larger rows with long paths benefit) — decide before first release since page size is fixed at creation.

**When to address**

- Before coding

---

### [HIGH] FSD-SCAN-001 — `item_type` taxonomy is ambiguous and double-encoded

**Evidence**

- Document or source file: `database/schema.sql` line 77–79 (`item_type IN ('directory','file','symlink','package','other')`) and line 88 (`is_package` flag); `KNOWN_ISSUES.md` KI-008; `PRD.md` §6.3 ("symbolic link and package flags").

**Problem**

A package **is** a directory; the enum and the `is_package` flag can disagree (`item_type='package', is_package=?` vs `item_type='directory', is_package=1`). Nothing defines which representation the scanner writes or which the diff engine trusts. Similarly, `symlink` erases whether the link's *target* is a file or directory (VisualDiffer explicitly substitutes destination attributes — see FSD-VD-003 — which is the opposite policy, and FSD picks neither). Since `item_type` participates in the default equality tuple (`ARCHITECTURE.md` §2: `normalized_relative_path + item_type + logical_size`), any ambiguity here changes comparison results directly — e.g. the same bundle captured under "package as single item" policy vs "package expanded" policy compares as changed/added storms.

**Impact**

Scanner and diff implementers make independent choices; snapshots become internally inconsistent; comparisons across capture policies produce garbage classifications.

**Recommendation**

- Make `item_type` a pure filesystem-kind enum: `'directory' | 'file' | 'symlink' | 'other'`. Drop `'package'` from the enum; packageness stays only in `is_package` (a directory attribute, orthogonal to kind).
- Record symlinks as themselves (kind `symlink`, `symlink_target` string, no target stat by default — consistent with `AGENT.md` "recorded but not followed"). Add `symlink_target_kind TEXT NULL` ('file'/'directory'/'missing'/'unknown') captured from a **non-following** `lstat`-then-optional-`stat` only when cheap and safe; it aids the UI without changing equality.
- Define equality for symlinks: compare kind + target string; logical size of a symlink is excluded (or defined as target-string length — pick one, document it).
- Diff engine must refuse (or downgrade to `uncertain`) comparisons between snapshots whose `capture_policy_json` package policies differ — see FSD-COMP-001.

**When to address**

- Before coding

---

### [HIGH] FSD-VOL-001 — Volume identity fallback is named but never designed

**Evidence**

- Document or source file: `PRD.md` §6.1 ("fallback fingerprint"); `database/schema.sql` `volumes.fallback_fingerprint TEXT`; `KNOWN_ISSUES.md` KI-003; `REFERENCE_VISUALDIFFER.md` §7.2 (identity priority list).
- Relevant section, symbol, or behavior: no document defines what bytes go into the fingerprint, when it is recomputed, or how identity conflicts resolve.

**Problem**

The identity chain is asserted (UUID → DA identity → device metadata → fingerprint → user label) but every hard case is unhandled by design:

- **Reformatted volume:** new `volumeUUID`, same hardware. Docs never say whether this is a new `volumes` row (correct answer: yes — a reformat destroys the catalogued tree's lineage) or a continuation via device serial.
- **Cloned volumes / duplicate UUIDs:** KI-003 names it; the non-unique `idx_volumes_persistent_uuid` permits duplicates (good), and PRD requires user confirmation before merging (good), but there is no flow for *two mounted volumes with the same UUID simultaneously* — which one does an auto-capture rule fire on?
- **APFS:** UUID is per-volume, but multiple volumes share a container/physical store; capacity is shared (`total_capacity_bytes` is misleading per volume); snapshots of two volumes in one container are physically related but modeled as strangers. Not addressed anywhere.
- **Disk images:** a mounted DMG looks like a removable volume, has a UUID that is duplicated by every copy of the image file, and disappears without a physical eject. Not addressed.
- **Network volumes:** KI-007 defers them ("experimental") — acceptable — but the volume table has no `is_network`/transport field to even *detect and exclude* them from auto-capture.
- **Fingerprint composition:** undefined. A workable definition: hash of (filesystem type, capacity bytes, creation date of filesystem root, plus device vendor/model/serial when available). Whatever is chosen must be stated, versioned, and stable.

**Should physical-device identity and logical-volume identity be modeled separately?** Long-term yes; for MVP a single `volumes` table with device columns is acceptable **provided** the docs state that `device_serial` is advisory (absent for many USB bridges, duplicated by cheap enclosures) and never merges identities on its own. Add a `devices` table post-MVP if rental-house inventory features (backlog) materialize.

**Impact**

Auto-capture (Phase 4) targets the wrong volume or duplicates histories; user trust in "this is the same drive" — the emotional core of the product — breaks on the first clone or reformat.

**Recommendation**

Write an ADR: identity resolution order, fingerprint recipe + version, duplicate-UUID runtime behavior (suspend auto-capture, ask user), reformat behavior (new volume row, old row retained with "retired" state), disk-image and network detection via `URLResourceKey.volumeIsLocalKey` / `volumeIsInternalKey` / DA descriptions, and APFS container note. None of this needs code now; all of it needs decisions before Phase 4, and the *schema* fields it needs (e.g. `transport`, `is_disk_image`, `identity_confidence`) should land in schema v1 or a planned v2 migration.

**When to address**

- Before automatic volume capture (decisions before coding Phase 1 where schema is affected)

---

### [HIGH] FSD-UI-001 — Drag-and-drop and split orientation are product requirements with zero specification

**Evidence**

- Document or source file: `UX_UI_SPEC.md` (entire document — contains no drag-and-drop interaction and no orientation switching); this review's terms of reference (Sections 6–7 of the task) treat both as required product behavior.
- Relevant section, symbol, or behavior: `UX_UI_SPEC.md` §5 shows only a fixed Left|Right layout; "No comparison" empty state says "Choose a source" with no drop affordance.

**Problem**

The two most interaction-heavy features of the comparison workspace — dragging sources (live volumes, Finder folders, snapshot sessions, snapshot subfolders) into panes, and switching Left|Right vs Top/Bottom orientation — exist only in the project owner's head. `UX_UI_SPEC.md` cannot drive Phase 3 UI implementation as written.

**Impact**

Phase 3 either ships picker-only comparison (quietly dropping a differentiating interaction) or improvises DnD semantics that then can't be changed without retraining users.

**Recommendation**

Add a "Comparison workspace" chapter to `UX_UI_SPEC.md` adopting the source model in Sections 10–11 of this review: pane source wells, drop targets, badges, replace/duplicate modifiers, orientation toggle, and state preservation across orientation changes. This is a documentation task; it should be written before Phase 3, but the `ComparisonSource` abstraction it depends on must be defined before coding (FSD-ARCH-002).

**When to address**

- Before MVP comparison UI

---

### MEDIUM

### [MEDIUM] FSD-DB-005 — TEXT timestamps with local offsets break ordering and bloat rows

**Evidence**

- Document or source file: `database/schema.sql` (`TEXT` timestamps throughout: `started_at`, `completed_at`, `created_at_source`, `modified_at_source`, per-row `created_at`); `samples/snapshot.example.json` (`"2026-07-24T17:39:13+07:00"` — local offset).

**Problem**

ISO-8601 strings with heterogeneous offsets do not sort chronologically as strings; SQLite date functions parse them per-row; each timestamp costs ~25 bytes vs 8 (or 5–6 varint-packed) for an INTEGER. `entries` carries up to three timestamps per row.

**Impact**

At 10M rows: ~500 MB of timestamp text and slow `ORDER BY completed_at` behavior; subtle bugs when a laptop changes timezone between captures.

**Recommendation**

Store all timestamps as INTEGER Unix epoch (milliseconds for `snapshots`, seconds for `entries` source dates — filesystem mtime sub-second precision varies by FS and is a comparison hazard anyway; `comparison_profiles.timestamp_tolerance_seconds` already implies second granularity). Render local time in UI only. Exports may format ISO-8601 UTC.

**When to address**

- Before coding

---

### [MEDIUM] FSD-DB-006 — Schema storage hygiene: redundant index, per-row `created_at`, duplicated strings

**Evidence**

- Document or source file: `database/schema.sql` — `idx_entries_snapshot_normalized_path` (line 106) duplicates the implicit index of `UNIQUE(snapshot_id, normalized_path)` (line 100); `entries.created_at NOT NULL` (line 99); `sort_key TEXT NOT NULL` (line 98) alongside `name`/`normalized_name`; `relative_path` + `normalized_path` both store full paths.

**Problem & Impact**

Rough row cost as drafted: two full paths (~2×60–120 B), three name-ish strings, three text timestamps, two signature BLOBs → 400–500 B/row plus ~35% index overhead. Estimates: **100k entries ≈ 60–80 MB; 1M ≈ 0.6–0.8 GB; 10M ≈ 6–8 GB**, and every additional session of the same volume repeats all of it (no interning). The duplicated path index alone is ~10% of the file. Per-row `created_at` is snapshot-level information repeated millions of times.

**Recommendation**

- Delete `idx_entries_snapshot_normalized_path` once FSD-DB-001 changes the UNIQUE (keep exactly one index on the path key).
- Drop `entries.created_at`; the snapshot row carries capture time.
- Make `normalized_path` (and `normalized_name`) **nullable, meaning "same as original"** — on mostly-ASCII media volumes this eliminates the second path copy for >95% of rows; the repository layer resolves `COALESCE(normalized_path, relative_path)`.
- Replace `sort_key` with ordering on `normalized_name` (already indexed via `(snapshot_id, parent_id, sort_key)` → change to `(snapshot_id, parent_id, normalized_name)`), unless a documented Finder-like numeric sort is required — in which case document the recipe.
- **Is storing full relative paths on every row acceptable?** Yes for MVP — it makes the diff join trivial and search simple, and is the single most defensible denormalization in this design. Parent-based hierarchy *plus* the path key (both present) is the right combination. Path *hashing* as a join key is unnecessary: SQLite B-trees on text keys are fine at 10M rows, and a hash adds collision handling for no measured win. Revisit interning/prefix-compression only if many-sessions-per-volume growth becomes a real complaint; delta-encoded snapshots are a post-MVP feature, not an MVP requirement.

**When to address**

- Before coding

---

### [MEDIUM] FSD-DB-007 — No space-reclamation strategy after snapshot deletion

**Evidence**

- Document or source file: `PRD.md` US-03 ("snapshot deletion affects only the local catalog"); `UX_UI_SPEC.md` §3 ("delete local snapshot after confirmation"); `database/schema.sql` (no `auto_vacuum`); `TEST_PLAN.md` §5 ("deletion of one snapshot without affecting another").

**Problem**

Deleting a 1M-entry snapshot via `ON DELETE CASCADE` (a) walks the self-referential `parent_id` cascade recursively — slow; (b) leaves the freed pages in the file; full `VACUUM` needs up to 2× free disk and blocks writers.

**Recommendation**

- Delete by `DELETE FROM entries WHERE snapshot_id = ?` (batched) before deleting the snapshot row, so the `parent_id` cascade never drives the deletion; keep cascades as a safety net.
- Enable `PRAGMA auto_vacuum = INCREMENTAL` **at database creation** (cannot be enabled later without VACUUM) and run `PRAGMA incremental_vacuum(N)` opportunistically after deletions; expose "Compact catalog…" in settings for full VACUUM with a disk-space precheck.
- Add a `TEST_PLAN.md` case: delete a large snapshot, assert bounded duration and file-size reduction after incremental vacuum.

**When to address**

- During scanner prototype (DB layer)

---

### [MEDIUM] FSD-SCAN-002 — Aggregates as a post-insert database pass is the slow design

**Evidence**

- Document or source file: `ARCHITECTURE.md` "Suggested scanner phases" (4: "calculate folder aggregates bottom-up"; 5: "compute metadata signatures"; 6: "write final totals").

**Problem**

Computing folder aggregates bottom-up *in SQLite after* inserting raw rows means re-reading and updating large portions of the table (and with signatures, rewriting every row), roughly doubling write volume and WAL churn for 1M–10M-row captures.

**Recommendation**

Compute aggregates **during traversal** with a directory stack: depth-first enumeration keeps one accumulator per open ancestor directory (`FileManager.DirectoryEnumerator.level` gives depth; on level pop, fold the finished directory's totals into its parent and emit a folder-row UPDATE). Only folder rows are updated (thousands, not millions — the sample volume has 6,442 folders vs 248k files). Insert file rows once with final values; update each folder row once. Keep phase 6/7 (totals, status flip) as-is. This also removes the window where a `complete` snapshot could exist with unfilled aggregates.

**When to address**

- During scanner prototype

---

### [MEDIUM] FSD-SCAN-003 — Scanner↔writer backpressure and device-aware concurrency are unspecified

**Evidence**

- Document or source file: `ARCHITECTURE.md` §3 Concurrency model (actors listed; no queue-depth or flow-control statement); §4 batch size guidance only.

**Problem**

An enumerator on a fast SSD can outrun the SQLite writer; an unbounded buffer between the scanner actor and writer actor turns "low memory use" (engineering priority 4 in `AGENT.md`) into an OOM on 10M-entry scans. Separately, nothing addresses HDD vs SSD traversal: parallel directory enumeration helps NVMe and murders spinning rust with seek storms; `REFERENCE_VISUALDIFFER.md` §11 even says "prefer sequential metadata traversal for rotational media" without saying how the scanner knows.

**Recommendation**

- Specify a bounded channel (e.g. `AsyncStream` with buffering policy, or an explicit ring of N batches; N×batch ≈ 4×2,000 entries) between enumeration and writer; enumeration suspends when full.
- MVP: **single-threaded traversal per capture, always** — sequential is correct on HDD and acceptable on SSD for metadata-only work (the writer, not the enumerator, is usually the bottleneck). Record device characteristics via DA/IOKit later; parallelism is a measured post-MVP optimization, not a default.
- One capture at a time globally in MVP (the capture queue already exists in `UX_UI_SPEC.md` navigation).

**When to address**

- During scanner prototype

---

### [MEDIUM] FSD-SCAN-004 — Hard links, APFS clones, sparse files: counting policy missing

**Evidence**

- Document or source file: `TEST_PLAN.md` §2 (fixtures include sparse files); `KNOWN_ISSUES.md` KI-004 (allocated size portability); no document mentions hard links or clone families.

**Problem**

- **Hard links:** two paths to one file are two entries; `subtree_logical_bytes` double-counts. For a *metadata catalog* this is arguably correct (the tree really shows both names) but must be stated, and totals must be labeled "sum of logical sizes" not "data on disk".
- **APFS clones / sparse files:** allocated size can be far below logical; KI-004 covers comparison (logical is default — correct) but capture docs never say allocated size is best-effort and filesystem-dependent (`totalFileAllocatedSizeKey` vs `fileAllocatedSizeKey` differ; pick and document one — recommend `totalFileAllocatedSize`).
- **Resource forks:** `TEST_PLAN.md` matrix mentions them; scanner keys don't. Decide: MVP ignores forks (logical size = data fork), documented. (VisualDiffer's optional fork-size substitution — `CompareItem.setAttributes` swaps `fileSize` for the fork size — is a live-tool feature FSD does not need.)
- **`st_nlink` capture:** cheap to record (`linkCount`) and lets the UI annotate hard links; optional.

**Recommendation**

One paragraph in `ARCHITECTURE.md` §4 fixing: totals are path-tree sums; allocated size uses `totalFileAllocatedSizeKey`, nullable, informational; forks ignored in MVP; hard links recorded as ordinary entries (optionally with link count).

**When to address**

- During scanner prototype

---

### [MEDIUM] FSD-COMP-001 — Comparisons across incompatible capture policies are undefined

**Evidence**

- Document or source file: `database/schema.sql` `snapshots.capture_policy_json`; `KNOWN_ISSUES.md` KI-008 ("chosen capture policy must be stored with each snapshot" — it is); no document defines what happens when two compared snapshots disagree on package traversal, hidden items, or normalization-rule version.

**Problem**

Snapshot A (packages as single items) vs snapshot B (packages expanded): every bundle explodes into an added-subtree storm. Same for hidden-item policy and (after FSD-ARCH-001) normalization-rule version.

**Recommendation**

Diff engine preflight: compare the policy documents; on mismatch, warn and either (a) degrade gracefully — compare package roots as opaque items on both sides when either side captured them opaquely — or (b) require the user to acknowledge. Record the policy pair in the `comparisons` row.

**When to address**

- Before MVP comparison UI

---

### [MEDIUM] FSD-DB-008 — Search-by-substring has no indexed plan

**Evidence**

- Document or source file: `PRD.md` US-02 ("search works without the source volume"); `MVP_PLAN.md` Phase 2 ("search by file name and relative path"); `database/schema.sql` `idx_entries_snapshot_name` on `(snapshot_id, normalized_name)`.

**Problem**

`LIKE '%term%'` cannot use a B-tree index; on a 1M-row snapshot every search is a full scan of that snapshot's rows. Acceptable at 100k, sluggish at 1M, bad at 10M.

**Recommendation**

MVP: prefix search (`LIKE 'term%'`, index-served) plus bounded full-scan substring search with `LIMIT` + incremental results (users type media clip prefixes like `A001C` — prefix search covers the DIT workflow well). Post-MVP: FTS5 external-content table over `name` if substring/token search demands grow. Say so in `ARCHITECTURE.md` so the repository API is shaped for it (search returns pages, not arrays).

**When to address**

- Before MVP comparison UI (Phase 2 browser)

---

### [MEDIUM] FSD-ARCH-004 — Sandbox deferral (ADR-006) discards the strongest read-only enforcement

**Evidence**

- Document or source file: `DECISIONS.md` ADR-006 (Proposed: no sandbox initially); `SECURITY_AND_READ_ONLY_POLICY.md` §5 (controls are code-review and test based); `REFERENCE_VISUALDIFFER.md` §6.7 (bookmark subsystem "may not be required" without sandbox).

**Problem**

Every documented read-only control is a *process* control (review, lint, tests). App Sandbox with `com.apple.security.files.user-selected.read-only` is a *platform* control: the kernel denies writes to scanned roots even if a bug ships. For a product whose one-line promise is "never modifies source files", ADR-006 trades away the only enforcement that survives programmer error. The stated cost (bookmark plumbing) is small and VisualDiffer demonstrates the exact pattern working in a shipping sandboxed differ.

**Recommendation**

Re-open ADR-006. Recommended: sandbox from Phase 0 with read-only user-selected file access + security-scoped bookmarks (the `AccessGrantStore` module is already in the module map). If direct-distribution-without-sandbox is kept for pragmatic reasons, then at minimum adopt the compile-time controls from Section 4 of this review and state in the ADR that sandboxing is reconsidered before any public release. Note: full-volume scanning of `/Volumes/X` root via `NSOpenPanel` works fine under sandbox; automatic capture on mount (Phase 4) is where sandbox friction is real (no user gesture per mount) — solvable with a persisted bookmark granted once per volume root, which is exactly the per-volume allowlist flow `UX_UI_SPEC.md` §7 already describes.

**When to address**

- Before coding (decision); before automatic volume capture (implementation consequence)

---

### [MEDIUM] FSD-DOC-001 — Snapshot status vocabulary drifts across four documents

**Evidence**

- Document or source file: `PRD.md` US-03 ("complete, interrupted and failed"); `database/schema.sql` (`'scanning','complete','complete_with_warnings','interrupted','cancelled','failed'`); `UX_UI_SPEC.md` §4 (adds "Cancelled by user", "Completed with warnings"); `MVP_PLAN.md` Phase 1 ("complete, interrupted and failed snapshot states"); `ARCHITECTURE.md` §7 (launch recovery: `scanning` → `interrupted`).

**Problem**

Three-state, five-state, and six-state vocabularies coexist. The review brief also references a `STALE` state that appears nowhere — correctly so (staleness is a *display* property derived from capture age and volume reappearance, not a lifecycle state), but that reasoning is recorded nowhere. Open questions the docs never answer: can a `cancelled` or `interrupted` snapshot be *browsed* (not just excluded from default)? Can it be a comparison side?

**Recommendation**

Single normative state table in `ARCHITECTURE.md`: the six schema states, allowed transitions, and per-state capabilities (browsable? comparable? default-eligible?). Recommended semantics: `complete`/`complete_with_warnings` fully usable; `interrupted`/`cancelled` browsable behind an explicit "partial capture" banner and usable in comparison only with an `uncertain`-heavy disclaimer (never silently); `failed` not browsable; `scanning` invisible until terminal. Update PRD/MVP wording to reference the table. Explicitly document that "stale" is derived, not stored.

**When to address**

- Before coding

---

### [MEDIUM] FSD-COMP-002 — Change-during-scan handling stops at acknowledgment

**Evidence**

- Document or source file: `KNOWN_ISSUES.md` KI-002 ("report detected changes where possible" — no mechanism); `PRD.md` §6.2 stores start/completion timestamps only.

**Problem**

The snapshot-over-an-interval problem is acknowledged but no detection or messaging mechanism exists. A full post-scan consistency pass (re-walk and compare) doubles scan time and still races; it is the wrong default.

**Recommendation**

MVP: no consistency pass; instead (a) persist scan duration prominently (schema already has it), (b) label every snapshot in UI as "captured over MM:SS", (c) during scan, count enumeration anomalies that *indicate* churn (entry vanished between listing and stat, directory mtime changed after its children were listed — cheap to detect opportunistically) into `warning_count` → `complete_with_warnings`. A verification rescan ("capture again and compare the two sessions") is already the product's own core feature — document that as the recommended workflow instead of building a consistency pass.

**When to address**

- During scanner prototype

---

### LOW

### [LOW] FSD-DOC-002 — README implementation order vs MVP_PLAN phase content drift

**Evidence**

- Document or source file: `README.md` "Recommended implementation order" (export is step 7, last); `MVP_PLAN.md` Phase 2 (JSON snapshot export ships with the browser), Phase 5 (HTML).

**Problem / Impact**

Minor scope drift; an implementer following README defers JSON export that MVP_PLAN requires in Phase 2 exit criteria. Same class of drift: README step 4 "Snapshot history" is folded into Phase 2 deliverables.

**Recommendation**

Delete the README ordering list and point at `MVP_PLAN.md` as the single source of sequence.

**When to address**

- Before coding (one-line edit)

---

### [LOW] FSD-DOC-003 — Handoff directory root is ambiguous

**Evidence**

- Document or source file: `AGENT.md` (path `handoffs/<date>/…` — relative to what?); `PROJECT_SUPPORT/handoffs.md` (same relative path); `PROJECT_SUPPORT/GITIGNORE.template` ignores `handoffs/**/TEMP_*` only.

**Recommendation**

State the absolute root once (suggest `FSD_ROOT/docs/PROJECT_SUPPORT/handoffs/`).

**When to address**

- Before coding

---

### [LOW] FSD-COMP-003 — Folder-level `changed` semantics undefined

**Evidence**

- Document or source file: `samples/diff.example.json` (`PROJECT_A/AUDIO` is `"changed"` with left/right byte totals); `UX_UI_SPEC.md` §5 (`≠ AUDIO`); `database/schema.sql` `result_type` list.

**Problem**

Is a folder ever *itself* `changed`, or does it merely *contain* changes? If folder rows carry `changed` because aggregates differ, then "Changed 2" in the summary mixes files and folders and double-counts (AUDIO changed *and* its children added/removed). VisualDiffer derives folder state purely from child summaries — a cleaner rule.

**Recommendation**

Define: leaf classifications count files (and empty/opaque directories) only; folder rows display a *derived* rollup state and are excluded from summary counters. Fix the sample JSON to match.

**When to address**

- Before MVP comparison UI

---

### [LOW] FSD-DB-009 — `session_number` assignment race

**Evidence**

- Document or source file: `database/schema.sql` `UNIQUE(volume_id, session_number)`.

**Problem**

Two capture flows for one volume (manual + queued auto) computing `MAX(session_number)+1` can collide. Low likelihood in MVP (single capture at a time per FSD-SCAN-003) but cheap to prevent.

**Recommendation**

Assign inside the same transaction that inserts the snapshot row (`INSERT … SELECT COALESCE(MAX(session_number),0)+1 …`), or serialize snapshot creation through the writer actor (already implied).

**When to address**

- During scanner prototype

---

## 6. Snapshot and Volume Identity Review

**Is a snapshot clearly defined?** Yes — `REFERENCE_VISUALDIFFER.md` §7.5 gives the best definition in the bundle (volume identity + timestamps + status + every entry + hierarchy + aggregates + issues + versions). Promote that list into `PRD.md` §6.2, which currently omits "every captured entry or a documented omission".

**Status model:** adequate once FSD-DOC-001's normative table exists. The atomic-generation model (ADR-004, scanner phase 7 status flip after full commit) is **correct**: a snapshot's completeness is a single row update after all entry transactions commit, and WAL recovery plus launch-time `scanning → interrupted` demotion (`ARCHITECTURE.md` §7) covers crash windows. One addition: the status flip must be in the same transaction as final totals (phases 6–7 merged), otherwise a crash between them yields a `complete` snapshot with zeroed totals.

**Can a partial snapshot be used for comparison?** The docs say interrupted snapshots are "excluded from default browsing and equality conclusions" but never define comparison eligibility. Recommendation (also in FSD-DOC-001): allowed only via explicit user override, with every path under unscanned regions classified `uncertain`, and the summary banner stating "compared against a partial capture". Never silently.

**Duplicate paths, inaccessible paths, I/O errors, disappearing volumes:** the `scan_issues` table + `is_inaccessible` flag + `inaccessible_items` counter are a sound design. Gap: an inaccessible *directory* must still produce an entry row (kind `directory`, `is_inaccessible=1`, zero aggregates) so trees align in diffs — state this explicitly.

**Metadata field triage** (PRD §6.3 vs review brief):

| Field | Verdict |
|---|---|
| normalized relative path, original name, item type, logical size, parent ID | **Required (MVP)** — equality core |
| subtree aggregates (counts, logical bytes) | **Required (MVP)** — lazy UI + diff skipping |
| modification time | **Required capture**, optional equality (Strict profile only) — correct as specified |
| creation time, extension/content type, hidden flag, package flag, symlink flag + target | **Useful, capture in MVP** (all are free with prefetched keys) |
| allocated size | Capture nullable, informational only (KI-004 correct); **never equality** |
| file resource identifier | Optional; document that `NSURLFileResourceIdentifierKey` is stable only while a volume stays mounted — it is **not** a durable cross-session identity; capture only if a concrete use exists (backlog lists it — fine) |
| permissions, filesystem flags | Post-MVP; niche for DIT audience, adds capture cost and diff noise |
| metadata signature / subtree signature | Defer per FSD-DB-002 |
| **Unsuitable as equality criteria** | allocated size, timestamps-by-default (correctly excluded), resource identifier, anything derived from content |

---

## 7. SQLite and Scanner Review

**Overall:** SQLite as canonical store (ADR-001) is the right call and the schema is 80% right. Normalization is sensible (volumes → snapshots → entries; issues and profiles separate); foreign keys are declared; the child-listing index `(snapshot_id, parent_id, sort_key)` is exactly what lazy `NSOutlineView` loading needs; WAL + NORMAL is the right durability/throughput point for a local catalog.

Defects and decisions are covered in findings FSD-DB-001…009; consolidated verdicts on the brief's specific questions:

- **Parent-hierarchy + full path per row:** keep both (see FSD-DB-006). The path column is the diff join key and the search field; the parent id is the lazy-tree key. This denormalization is justified.
- **Path hashing:** unnecessary (FSD-DB-006).
- **Persist subtree signatures:** not in MVP (FSD-DB-002); aggregates give the skip behavior.
- **SHA-256 vs other:** if/when signatures come, 8-byte xxHash-class; SHA-256 is oversized and misleadingly "cryptographic" for a UI-invisible shortcut key.
- **Comparisons primarily in SQL:** yes (FSD-DB-003) — indexed keyed joins between two snapshots' entry sets, streamed with `LIMIT`/keyset pagination for UI, summary counts via aggregate queries.
- **Materialize vs on-demand:** differences materialized (small), matches on demand (FSD-DB-003).
- **Migration strategy:** `schema_migrations` table + backup-before-migrate (`ARCHITECTURE.md` §7) is fine; add "migrations are forward-only, applied in one transaction each" and test per `TEST_PLAN.md` §5.
- **Storage growth:** with FSD-DB-005/006 applied ≈ 250–300 B/row: 100k ≈ 30–40 MB; 1M ≈ 0.3–0.4 GB; 10M ≈ 3–4 GB; sessions grow linearly (no interning in MVP — accepted, documented).

**Scanner:**

- **API choice:** `FileManager.enumerator(at:includingPropertiesForKeys:options:errorHandler:)` with prefetched keys (`.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey, .isPackageKey, .fileSizeKey, .totalFileAllocatedSizeKey, .creationDateKey, .contentModificationDateKey, .contentTypeKey, .isHiddenKey, .nameKey`) is correct and is what `ARCHITECTURE.md` §4 implies. **`attributesOfItem(atPath:)` per entry must be avoided** — it is one-plus syscalls per file with no batching; VisualDiffer does exactly this (FSD-VD-002) and it is its scanner's main scaling liability. If profiling later shows enumerator overhead, the escalation path is `getattrlistbulk(2)` — note it in the architecture doc as the known fast path, don't build it first.
- **Error continuation:** the enumerator's `errorHandler` returning `true` + `scan_issues` row matches "continue after recoverable permission errors". Correct.
- **Symlinks/aliases:** enumerator does not follow symlinks into directories by default — matches policy. Finder aliases are *files* (`isAliasFileKey`) — record as files, never resolve; add one line to §4.
- **Eject/cancel:** cancellation via volume-service signal + `Task` cancellation checks per batch; on eject mid-stat, errors surface through the errorHandler — the design already handles it. Ensure the writer commits the in-flight batch before marking `interrupted` ("commit already-recorded rows if safe" — good).
- **exFAT/NTFS/SMB:** expect absent UUIDs (KI-003), 2-second mtime granularity on exFAT (feeds the Strict-profile tolerance default of 2 s already seeded in `comparison_profiles` — good), no hidden-flag fidelity, and SMB enumeration latency (deferred per KI-007 — fine, but detect-and-warn per FSD-VOL-001).

---

## 8. Comparison Engine Review

The default equality tuple (`normalized_relative_path + item_type + logical_size`) is right for the DIT workflow, and the three seeded profiles map cleanly onto it. Required corrections before implementation:

1. **Unify on the ephemeral-snapshot model** (FSD-ARCH-002) so the engine has exactly one input type: `(snapshot_id, root_subpath)` pairs. The `root_subpath` gives "compare a subfolder inside a snapshot" for free: the join key becomes the path suffix after stripping the selected base, computed in SQL with length/substr on the indexed key (prefix-bounded scans: `normalized_path >= base || '/' AND normalized_path < base || '0'` — the standard trick; document the sentinel).
2. **Classification set:** `matched/added/removed/changed/uncertain/ignored` (schema) vs UX symbols (`= + − ≠ ! ~`) are consistent. Define `uncertain` triggers exhaustively: inaccessible either side, normalization collision (FSD-DB-001), policy mismatch (FSD-COMP-001), partial-snapshot region.
3. **Folder rollups** derived, not counted (FSD-COMP-003).
4. **Streaming results:** engine yields difference pages ordered by `normalized_path`; "next difference" is a keyset query (`WHERE path > current AND result_type != 'matched' ORDER BY path LIMIT 1`) — no in-memory diff list. This is the property VisualDiffer cannot have (its navigator walks the in-memory tree) and it is FSD's structural advantage; protect it in code review.
5. **Ignore rules** (`ignore_rules_json` glob list): define glob dialect (recommend `fnmatch`-style with `**`, matching on relative path) and evaluate in Swift during result streaming, not in SQL — keeps SQL planner-friendly and rules testable.

---

## 9. UI Architecture Review

ADR-002 (SwiftUI shell + `NSOutlineView` via `NSViewRepresentable` for trees) is correct for macOS 13 and for 1M-row trees; SwiftUI `List`/`OutlineGroup` at that scale is not viable (KI-006 is accurate). VisualDiffer independently validates AppKit outline views for exactly this UI (REF-VD-002).

**Recommended tree model: hybrid — one canonical merged comparison model, rendered in MVP as a single unified outline with left/right column groups.**

Comparing the three options against the brief's criteria:

| Criterion | Two independent aligned trees | One unified tree, L/R columns | Hybrid (one model, either rendering) |
|---|---|---|---|
| Missing-item alignment | Needs placeholder rows engineered on both sides (VisualDiffer's invalid `CompareItem`s) | Free — one row per path, empty cells | Free (model owns alignment) |
| Performance (1M rows) | Two lazy datasources + sync traffic | One lazy datasource | One datasource |
| Sync scroll/expand | Must build (lockExpand-style guards) | Not needed | Optional feature later |
| Keyboard nav / VoiceOver | Two focus targets, mirrored state | Single target; row reads "AUDIO — left 84.9 GB, right 85.4 GB, changed" | Same as unified |
| Drag-and-drop | Row-level targets ambiguous across panes | Pane *headers* are the drop targets — cleaner | Same |
| Snapshot vs live | Symmetric (both are snapshots after FSD-ARCH-002) | Symmetric | Symmetric |
| Deep trees / long names | Two full name columns | One name column + two size/meta columns — wins on laptops | — |
| Implementation complexity | Highest | Lowest | Low now, extensible |

The merged model is a SQL-backed row provider keyed by aligned path: each row = `(display name, depth, left cell?, right cell?, classification)`. Build **one** `ComparisonTreeDataSource` on that model. MVP renders it in a single `NSOutlineView` whose columns are grouped visually (Name | ⬅ size/date | classification glyph | ➡ size/date). The familiar two-panel look can be added post-MVP as a second rendering of the *same* row model — two `NSOutlineView`s whose row *i* is the same model row (alignment is then trivially perfect and scroll sync is sharing one scroll position), which is a stricter, simpler discipline than VisualDiffer's two linked-but-independent item trees.

Synchronized-tree behaviors from the brief, against this model: synchronized scrolling/expand/collapse and paired row alignment become **model properties, not view synchronization** (nothing to sync in MVP). Next/previous difference = keyset query (Section 8). Collapse-matching-branches and differences-only = row-provider filters (`WHERE result_type != 'matched'` plus ancestor closure). Placeholders for missing items = empty cells. Synchronized vs independent selection: single tree has one selection; an "independent selection mode" only matters in the two-pane rendering — defer it. Reveal in Finder: enabled only when the row's side maps to a currently-mounted live path (`mount_path_at_capture` revalidated at menu time — never stored URLs blindly; PRD US-02 already requires this). Copy relative path, metadata inspector, pinned summary header: straightforward; the summary bar must carry the "Metadata Match only" disclaimer per PRD §10.

## 10. Split Orientation Review

**Feasible: yes — with AppKit `NSSplitView`/`NSSplitViewController`, not SwiftUI split primitives.** SwiftUI `HSplitView`/`VSplitView` are distinct static types with no runtime axis swap, no divider APIs, and poor programmatic control; rebuilding the hierarchy on toggle would recreate the `NSViewRepresentable` trees and lose view state. `NSSplitViewController` supports changing `splitView.isVertical` on a retained view hierarchy; the two arranged subviews (source-pane chrome) keep their identity.

With the recommended unified tree (Section 9), MVP orientation is even simpler: the *panes* being split are the two **source header wells** plus optional per-side inspectors — the tree itself is one view that doesn't split. `Left | Right` puts source wells side-by-side above the tree; `Top/Bottom` stacks them. If/when the two-pane rendering ships, the same `NSSplitViewController` axis flip applies to the two outline panes.

**Live orientation change without losing state** — achievable by keeping all of this in a controller object owned above the view layer, keyed by stable identifiers (normalized path, not row index):

- selected entries → set of normalized paths;
- expanded nodes → set of normalized paths (restore via `expandItem` walk on visible ancestors only);
- scroll position → first-visible normalized path + offset;
- filter state, active profile, comparison result → already model-side;
- active side, in-flight drag → active side is a controller flag; an in-flight *drag* crossing an orientation toggle is not a real scenario (toggle is a toolbar action; drags end first) — document as unsupported rather than engineered.

Persist the orientation preference per window via `NSWindow` restoration + `UserDefaults` default. Auto-suggest vertical when window aspect < 1 is a nicety; never auto-switch while the user has manually chosen (respect explicit preference).

## 11. Drag-and-Drop Source Model

**Can snapshot sessions and live volumes share one pane model? Yes — via the `ComparisonSource` abstraction, which must be defined before the engine or the UI** (FSD-ARCH-002, FSD-UI-001). Recommended shape (names indicative):

```text
ComparisonSource
├── identity      : SourceIdentity        // .liveFolder(bookmarkOrPath), .liveVolume(volumeID),
│                                          // .snapshot(snapshotID), .snapshotSubpath(snapshotID, path),
│                                          // .lastCompleteSnapshot(volumeID)
├── kind          : live | snapshot        // drives capture-before-compare
├── availability  : online | offline | missing   // resolved at use time, never cached long
├── rootSelection : normalized subpath ("" = root)
├── displayTitle  : String                 // "KN_SSD_014 · Session 008" / "CAMERA (live)"
├── captureDate   : Date?                  // nil for live
├── isReadOnly    : always true            // by construction; no setter exists
├── metadataProvider : SnapshotMetadata    // totals, status, policy
└── childProvider    : TreeQueryService    // (snapshotID, parentID) → page of rows
```

Critical property (brief requirement): **no API on this type returns a live filesystem URL for arbitrary items.** Only a narrow `liveURL(for:)` helper exists, returns optional, and is used solely by Reveal-in-Finder after revalidation. `.lastCompleteSnapshot(volumeID)` is late-bound: it resolves to a concrete snapshot at compare time so panes can be "pinned to latest".

**Pasteboard design.** VisualDiffer registers only `public.file-url` — sufficient for a live-only tool, structurally insufficient for FSD (a snapshot session has no URL; and VisualDiffer's `validateDrop` calls `FileManager.fileExists`, which would reject FSD's offline sources outright — see FSD-VD-004). FSD needs a **custom pasteboard type** (`com.fsd.comparison-source`, JSON-encoded `SourceIdentity`) registered alongside `public.file-url`:

- internal drags (sidebar volume, snapshot history row, snapshot-browser folder, recent source) write `com.fsd.comparison-source` (+ a file URL *only* when the source is live and mounted, so dragging a live volume out to Terminal still works);
- Finder drags arrive as `public.file-url` and wrap into `.liveFolder`.

**Drop behaviors** (per the brief's matrix):

| Gesture | Behavior |
|---|---|
| One source → empty workspace | Fills the left/top pane; right pane enters "choose or drop second source" state |
| Second source → other pane | Fills it; comparison readiness reached |
| Drop on occupied pane | **Replace**, with a 2–3 s undo toast ("Replaced Session 007 — Undo") instead of a modal confirmation; modals kill drag flow |
| Option held during drop | On the *other* pane's context: places a copy of the dragged source there (duplicate-to-both, for comparing a snapshot against a subfolder of itself); show ⌥ badge on the drag image |
| Snapshot dropped onto another snapshot('s pane) | Replace that pane (occupied-pane rule); never "merge" |
| Mounted volume dropped onto its own historical snapshot pane | Standard replace of that pane — but the workspace detects same-volume-identity and offers the one-click shortcut banner "Compare live state against Session NNN?" |
| Snapshot dropped onto the same volume's live pane | Symmetric to the above |
| Folder from Finder | `.liveFolder`; will be captured as transient snapshot on compare |
| **File** (not folder) from Finder | Reject with drop-denied cursor + a transient hint "FSD compares folders and volumes" (MVP has no file compare; VisualDiffer's directory-only `validateDrop` check is the right instinct — reimplement the *rule*, not the code) |
| Disconnected/invalid source (stale internal drag, missing snapshot) | Reject with reason in a transient hint; never partially apply |
| Two file URLs at once (Finder multi-drag) | Fill left and right in order — mirror of VisualDiffer's observed two-URL behavior; it is a good pattern |
| Central workspace drop (not on a pane) | Fills the first empty pane; if none empty, reject (ambiguous) |

**Comparison start policy** (brief question): **auto-compare when both sides are snapshot-backed** (metadata diff of indexed rows is cheap — sub-second at 100k, a few seconds at 1M); **require an explicit Compare click when any side is live**, because that triggers a capture whose duration depends on the medium (an HDD volume can take minutes). The Compare button doubles as capture-progress UI. This matches the "automatic for cheap summaries, confirmed for expensive operations" instinct in the brief, with a crisper rule.

**Visual affordances:** pane source wells show kind badge (🖴 live volume / 📁 live folder / 🕘 snapshot with session number), availability dot (matching the ●/○/△ language already in `UX_UI_SPEC.md` §6), and capture date for snapshots ("Session 008 · 24 Jul 2026 17:42" — absolute date, never only "2 days ago", for a forensic-minded audience). Swap-sides button (⇄) in the workspace toolbar; per-pane clear (⌫) with the same undo toast; recent sources in each well's dropdown (last 8, persisted).

All of the above belongs in the new `UX_UI_SPEC.md` chapter (FSD-UI-001).

---

## 12. VisualDiffer Lessons

### Patterns Worth Reimplementing

Verified in source and appropriate for independent reimplementation from FSD's own requirements:

1. **Paired-panel discipline with reentrancy guards** — `FoldersOutlineView.linkedView` + `lockExpand` around synchronized `expandItem`/`collapseItem` (`FoldersOutlineView.swift:195–232`). If FSD ships the two-pane rendering, this guard pattern (a boolean latch, not notification suppression) is the proven shape. In the recommended unified tree it is unnecessary — better still.
2. **Merge-join child alignment** — `ItemComparator+Align.swift` advances left/right indexes over sorted child arrays, emitting orphans on exhaustion. FSD's SQL keyed join is the set-based equivalent; the streaming variant is useful if FSD ever aligns during live enumeration.
3. **Flag-set comparison options** — `ComparatorOptions` as an `OptionSet` driving independent compare steps (`ItemComparator+Compare.swift:41–59`), cleanly mirroring FSD's profile columns.
4. **Separation of filter config from comparator** — `FilterConfig` (traversal-time exclusion) vs comparator options (equality) vs display options (visibility) are three distinct axes; FSD's capture policy / comparison profile / view filter mirrors this exactly and the docs already distinguish "not captured" from "ignored during comparison" (`REFERENCE_VISUALDIFFER.md` §6.3). Keep that three-way split.
5. **Drop-assigns-side, two-URLs-assign-both** — `FoldersWindowController+FoldersOutlineView.swift:263–274`. Good interaction grammar; reimplemented in Section 11's table.
6. **Security-bookmark ancestor reuse** — `SecureBookmark.findClosestPath` + stale-refresh with balanced start/stop and subtree-covering cleanup on force-update. If ADR-006 flips to sandboxed (recommended), FSD's `AccessGrantStore` should have this behavior (per-volume-root grants covering all descendants).
7. **Symlink loop protection** — ancestor identity check before descending (`FolderReader.symbolicLinkToParent`). FSD's "never follow by default" makes this mostly moot, but if a follow-links capture option ever ships, ancestor-inode checking is the right guard (implement with prefetched `fileResourceIdentifierKey`, not per-ancestor stat calls).
8. **Difference navigator as first-class UI** — `Navigator/` module; validates PRD US-04's next/previous requirement.

### Patterns Unsuitable for FSD

1. **Canonical tree in RAM** — `CompareItem` graph with `parent`/`children`/`linkedItem`/`visibleItem` (verified `CompareItem.swift:24–33`). Fine for two live folders; disqualifying for million-entry persistent snapshots. `REFERENCE_VISUALDIFFER.md` §7.1 already forbids it; this review confirms from source that the prohibition is justified. (= brief item 4: the parts that keep full comparison trees in memory are `CompareItem`, `VisibleItem`, and every controller that walks them.)
2. **Per-entry `attributesOfItem` scanning** — `FolderReader.addEntryFile` stats each entry individually, plus `NSWorkspace.isFilePackage(atPath:)` per directory and per-ancestor stats for symlinks. FSD must use enumerator key prefetching (Section 7). This is the single biggest *performance* lesson: do not imitate the reference's scanner mechanics.
3. **Symlink destination substitution** — `CompareItem.setAttributes` replaces a symlink's size/date with its *target's* attributes (`CompareItem.swift:115–122`). Reasonable for a live differ; wrong for FSD, whose policy is "record the link itself" (`AGENT.md`). Explicitly do the opposite.
4. **Live-existence drop validation** — `validateDrop` requires `FileManager.fileExists` for every dropped URL (`FoldersWindowController+FoldersOutlineView.swift:230–244`). Structurally incompatible with offline snapshot sources (= brief item 3: drop validation, session reopening/path revalidation (`SessionDiff.awakeFromFetch`), Quick Look previews (`+QLPreviewPanel`), per-path `NSWorkspace` icons, and Reveal-in-Finder all assume both compared paths remain online).
5. **History-as-session, not history-as-snapshot** — verified: `HistoryEntity` adds only `starred` + `updateTime` to `SessionDiff`, which stores `leftPath`, `rightPath`, and option flags (= brief item 6: **VisualDiffer history stores paths and comparison configuration only; no scanned tree entries are persisted**). This is precisely the model FSD must not confuse with snapshots; `REFERENCE_VISUALDIFFER.md` §7.5 and REF-VD-004 already say so and are confirmed accurate.
6. **Mutation and content subsystems** (= brief item 5) — copy/move/rename/delete/touch/sync: `FileOperationManager` + `CopyCompareItem`/`MoveCompareItem`/`DeleteCompareItem`/`RenameCompareItem`/`TouchCompareItem`, `FileSystemController/{Copy,Move,Delete,Sync,Touch}`, `SyncFileController`. Content/text reading: `ItemComparator.compareContent`, `compareAsText`, `compareBinaryFiles`, `compareTextFiles`, resource-fork reads (`readResFork`), and the `FilesCompare` feature. None may exist in FSD in any form.
7. **`.every` drag operation masks** — `setDraggingSourceOperationMask(.every, …)` (`FoldersOutlineView.swift:68–69`) advertises move-capable drags; FSD sources must advertise `.copy` only (dragging *out of* a catalog must never imply the catalog can move source files).

### GPLv3 Clean-Room Boundary

`REFERENCE_VISUALDIFFER.md` §8 is a sound policy and this review complied with it: VisualDiffer source was read for behavior verification only; no code, comments, fixtures, strings, or assets were copied into FSD; all file/symbol citations above are factual references for evidence, not implementation material. Two reinforcements recommended:

- The traceability rule ("VisualDiffer does it this way" is not sufficient justification) should be added to PR/review templates when the repo gains code.
- This review's Section 12 deliberately describes *behaviors and shapes*, not code structure to replicate. FSD implementers should work from Sections 8–11 of this report and the FSD docs — not from the VisualDiffer checkout. Recommend deleting `/tmp/FSD_VISUALDIFFER_REFERENCE` after the relevant ADRs are written.

---

## 13. Recommended Implementation Sequence

The brief's candidate ordering (`folder picker → metadata scanner → SQLite persistence → …`) is **wrong in one important way**: persistence must precede the scanner, because the scanner's shape (batching, transactions, interrupt semantics) is dictated by the writer. `MVP_PLAN.md` already has this right (Phase 0 database first). The plan's order is fundamentally sound; the required changes are: (a) insert a **CLI scanner spike** before any UI, (b) hold automatic capture until its stated preconditions are demonstrably met, (c) land the blocker ADRs first.

**Answer to the brief's specific question:** yes, an early command-line scanner prototype materially reduces risk — it exercises the two highest-risk subsystems (enumeration throughput, SQLite write path) with zero UI cost, produces the benchmark numbers `TEST_PLAN.md` §4 requires, and validates batch size (2,000 vs 1,000–10,000) empirically. It should be a SwiftPM executable target in the same repo sharing the future `Catalog` + `Capture` modules — not throwaway code.

**Phase R0 — Specification closure (docs only, ~days)**
- *Objective:* resolve every "Before coding" finding.
- *Scope:* ADRs for path normalization (FSD-ARCH-001), ephemeral snapshots + `ComparisonSource` (FSD-ARCH-002), item-type taxonomy (FSD-SCAN-001), signature deferral (FSD-DB-002), sandbox decision (FSD-ARCH-004), status table (FSD-DOC-001); schema.sql v1 revision (FSD-DB-001, -004, -005, -006, and `snapshots.kind`).
- *Exit criteria:* revised `schema.sql` applies cleanly; every ADR accepted in `DECISIONS.md`.
- *Critical tests:* none (docs).
- *Manual validation:* cross-read PRD/ARCHITECTURE/MVP_PLAN for the vocabulary fixes.
- *Risks:* over-designing; timebox it.
- *Must NOT implement yet:* anything in Xcode.

**Phase R1 — Catalog core + CLI scanner spike (replaces the front of Phase 0/1)**
- *Objective:* prove capture throughput and durability without UI.
- *Scope:* SwiftPM package: `CatalogDatabase` (connection factory with per-connection pragmas, migration runner), `SnapshotRepository`, `MetadataScanner` (enumerator + prefetch keys + bounded channel + writer actor), `fsdscan` CLI (`fsdscan capture <path>`, `fsdscan info`, `fsdscan verify-readonly`).
- *Exit criteria:* 100k-entry fixture captured with correct totals; kill -9 during capture → relaunch demotes to `interrupted`, previous snapshot intact (CT-002 core, headless); throughput and DB-size numbers recorded against `TEST_PLAN.md` §4 benchmarks.
- *Critical tests:* CT-001 (before/after source state), interrupted-transaction recovery, normalization golden tests (NFC/NFD, case collisions — the FSD-DB-001 fixture), aggregate correctness vs `find`/`du` ground truth.
- *Manual validation:* scan a real exFAT camera card; eyeball totals against Finder Get Info.
- *Risks:* enumerator perf on network/NTFS — out of scope, note and move on.
- *Must NOT implement yet:* diff engine, any UI, mount observation, signatures.

**Phase R2 — App shell + manual capture UI (≈ MVP Phase 0 remainder + Phase 1)**
- *Objective:* the `PRODUCT_STATE.md` "next milestone", on the proven core.
- *Scope:* Xcode app, SwiftUI shell, `NSOpenPanel` capture, progress/cancel UI, snapshot list.
- *Exit criteria:* MVP_PLAN Phase 1 exit criteria as written.
- *Critical tests:* UI-thread responsiveness during 100k scan; cancel leaves prior snapshots intact.
- *Manual validation:* capture, quit mid-scan, relaunch, verify states.
- *Risks:* sandbox/bookmark plumbing if ADR-006 flips — why the decision is in R0.
- *Must NOT implement yet:* compare workspace, auto-capture.

**Phase R3 — Offline browser (= MVP Phase 2, unchanged scope incl. JSON export)**
- *Exit criteria:* as written, plus CT-003 and CT-005 pass; search returns first page < 100 ms on 1M fixture (prefix mode).
- *Must NOT implement yet:* comparison UI (but `TreeQueryService` built here is the same one comparison uses — design its paging API accordingly).

**Phase R4 — Comparison engine + workspace (= MVP Phase 3 + FSD-UI-001 spec work)**
- *Objective:* snapshot-vs-snapshot first, then live sides via transient capture.
- *Scope:* SQL diff (Section 8), unified tree UI (Section 9), source wells + DnD (Section 11), orientation toggle (Section 10), differences-only, next/prev.
- *Exit criteria:* MVP_PLAN Phase 3 criteria; plus: one-file difference in two 1M-entry snapshots found without full expansion (PRD success metric); policy-mismatch preflight warns.
- *Critical tests:* CT-004 fixtures incl. collision/uncertain cases; diff latency benchmark.
- *Risks:* result paging UX; keep matched rows virtual.
- *Must NOT implement yet:* auto-capture, HTML export.

**Phase R5 — Automatic volume capture (= MVP Phase 4) — gated**
- Explicit entry gate (the brief's question, answered affirmatively): do not start until (1) interrupted-scan recovery has passed CT-002 repeatedly incl. hard-eject during write, (2) volume-identity ADR implemented and duplicate-UUID behavior demonstrated, (3) sandbox/bookmark model settled and per-volume grants persist across relaunch, (4) snapshot persistence stable across ≥ 2 schema migrations. All four are new exit criteria appended to earlier phases.
- *Must NOT implement yet:* login-item until the queue is proven interactively.

**Phase R6 — Reports + hardening (= MVP Phase 5, unchanged).**

---

## 14. Revised MVP Milestones

| # | Milestone | Maps to | Gate |
|---|---|---|---|
| M0 | Spec closure: ADRs accepted, schema v1 revised | R0 | All BLOCKER findings closed |
| M1 | `fsdscan` captures 100k fixture; crash-safe; benchmarks recorded | R1 | CT-001/CT-002 headless pass |
| M2 | App captures via folder picker with progress/cancel | R2 | Phase 1 exit criteria |
| M3 | Offline browse + search + JSON export after eject | R3 | CT-003, CT-005 |
| M4 | Snapshot-vs-snapshot compare with unified tree, DnD sources, orientation toggle | R4 | CT-004; 1-file-diff metric |
| M4.5 | Live-side compare via transient capture | R4 | policy preflight demonstrated |
| M5 | Auto-capture behind the four-condition gate | R5 | gate conditions documented as tests |
| M6 | HTML reports, migrations tested, notarized DMG | R6 | Phase 5 exit criteria |

---

## 15. Required Documentation Changes

1. **`database/schema.sql`** — apply FSD-DB-001 (drop path UNIQUE, add `UNIQUE(snapshot_id,parent_id,name)`), FSD-DB-004 (pragmas out of DDL), FSD-DB-005 (INTEGER epochs), FSD-DB-006 (drop redundant index, drop `entries.created_at`, nullable normalized columns, sort-key decision), FSD-SCAN-001 (item_type enum, `symlink_target_kind`), FSD-ARCH-002 (`snapshots.kind`), FSD-DB-007 (auto_vacuum note), FSD-VOL-001 (transport/disk-image fields or planned v2).
2. **New ADRs in `DECISIONS.md`** — path normalization; ephemeral snapshots + ComparisonSource; item-type taxonomy; signature deferral (amend PRD §7 wording); sandbox revisit of ADR-006; volume-identity resolution & fingerprint recipe; snapshot-state capability table location.
3. **`ARCHITECTURE.md`** — connection-factory pragma rule; aggregates-on-traversal scanner phases (merge phases 6–7 into one transaction); bounded-channel backpressure; alias/hard-link/fork paragraph; search paging note.
4. **`UX_UI_SPEC.md`** — new "Comparison workspace" chapter: source wells, DnD matrix (Section 11), orientation toggle + state preservation (Section 10), unified-tree columns, auto-vs-explicit compare rule, capture-date presentation.
5. **`PRD.md`** — §6.2 add "every captured entry or a documented omission"; §7 signature wording; US-03/US-04 status vocabulary alignment; add snapshot-vs-live temporal disclaimer requirement.
6. **`MVP_PLAN.md`** — insert CLI spike; append the four-condition gate to Phase 4 entry; move JSON-export mention consistency (FSD-DOC-002).
7. **`TEST_PLAN.md`** — add: normalization golden fixtures (NFC/NFD, case collision insert), snapshot deletion size/duration test, policy-mismatch compare test, pragma-per-connection assertion test.
8. **`README.md`** — drop the duplicate ordering list (point to MVP_PLAN); `AGENT.md`/`PROJECT_SUPPORT` handoff root fix (FSD-DOC-003).

---

## 16. Open Technical Decisions

Must be closed in Phase R0 (owner = project owner unless noted):

1. Path normalization recipe and version tag (FSD-ARCH-001).
2. Ephemeral-snapshot GC policy: max count/age of `transient` snapshots (FSD-ARCH-002).
3. Sandbox now vs later (ADR-006 revisit; FSD-ARCH-004).
4. Sort order recipe for tree listing: plain `normalized_name` vs Finder-like numeric sort (FSD-DB-006).
5. Timestamp granularity for `modified_at_source` (seconds recommended) and Strict-profile default tolerance per filesystem (exFAT 2 s already seeded — confirm).
6. Symlink logical-size equality rule (exclude vs target-string length) (FSD-SCAN-001).
7. Volume fingerprint recipe + duplicate-UUID runtime behavior (FSD-VOL-001) — may trail until R5 gate but schema impact should be settled in R0.
8. Bundled SQLite vs system library (affects FULL OUTER JOIN availability, FTS5 versioning; bundling recommended) (FSD-DB-003).
9. Comparison-result retention policy (cache expiry vs delete-on-close) (FSD-DB-003).
10. Whether `interrupted`/`cancelled` snapshots are browsable/comparable and behind what disclaimers (FSD-DOC-001).

---

## 17. Go / Revise / No-Go Verdict

**GO WITH REQUIRED REVISIONS.**

Answers to the eleven mandated questions:

1. **Is the product logic coherent?** Yes. The snapshot-catalog-first model, read-only invariant, and honest equality language are consistent across all documents; the incoherences found are vocabulary drift and unspecified edges, not conceptual conflicts.
2. **Is the SQLite snapshot architecture suitable?** Yes — with the schema revisions in Section 15 item 1. One constraint (path uniqueness) is an outright bug; the rest are storage and durability hardening. The lazy-tree index design and generation model are sound.
3. **Is the current implementation order safe?** Broadly yes (`MVP_PLAN.md` already puts the database before the scanner and defers auto-capture to Phase 4). Required changes: a CLI scanner spike before UI, blocker ADRs before any code, and an explicit four-condition gate before automatic capture. The brief's alternative ordering (folder picker first) is unsafe and should not be adopted.
4. **Can one comparison workspace support both orientations?** Yes — `NSSplitView`/`NSSplitViewController` with `isVertical` toggling and view-model-held state (selection/expansion/scroll keyed by normalized path). Not with SwiftUI `HSplitView`/`VSplitView`. With the recommended unified tree, orientation touches only the source-well chrome in MVP.
5. **Can snapshots and live volumes share one drag-and-drop pane model?** Yes — via the `ComparisonSource` abstraction plus a custom pasteboard type alongside `public.file-url`, with live sources normalized into transient snapshots at compare time. VisualDiffer's file-URL-only, must-exist-on-disk drop model cannot be reused.
6. **Two synchronized trees, one unified tree, or hybrid?** **Hybrid, unified-first:** one canonical SQL-backed merged comparison model; MVP renders a single `NSOutlineView` with left/right column groups; a two-pane rendering of the same row model is an optional post-MVP presentation. Rationale in Section 9.
7. **Decisions before production Swift code:** the ten items in Section 16, of which items 1–6 (normalization, ephemeral snapshots, sandbox, sort order, timestamps, symlink equality) plus the schema revision are hard prerequisites.
8. **VisualDiffer patterns to independently reimplement:** paired-panel reentrancy guards (if two-pane ships), merge-join alignment concept, flag-set comparison options, capture/compare/display filter separation, drop-assigns-side grammar, bookmark ancestor-reuse, symlink loop guard, difference navigator. (Section 12, first list.)
9. **VisualDiffer patterns that must not be carried into FSD:** in-memory canonical `CompareItem` tree, per-entry `attributesOfItem` scanning, symlink destination-attribute substitution, live-existence drop validation, history-as-session mistaken for snapshots, all mutation subsystems (copy/move/delete/rename/touch/sync), all content/text comparison, `.every` drag masks — and, per GPLv3 policy, any code, strings, fixtures, or assets in any form. (Section 12, second list.)
10. **Is the documentation sufficient to begin Phase 1?** Sufficient to begin **Phase R0 immediately and Phase R1 within days of it**. It is not sufficient for Phase 1 as-is: FSD-DB-001/FSD-ARCH-001 would be baked into the first million rows written. After the Section 15 revisions, yes.

And explicitly: metadata equality is never content verification, inaccessible or interrupted snapshots are never presented as complete, and same-path-same-size is a *Metadata Match* claim only — the documentation already holds this line and every recommendation above preserves it.

---

## 18. Vietnamese Summary

**Kết luận: ĐỒNG Ý TRIỂN KHAI SAU KHI SỬA CÁC ĐIỂM BẮT BUỘC (GO WITH REQUIRED REVISIONS).**

FSD có logic sản phẩm nhất quán và ranh giới MVP rõ ràng: chụp snapshot chỉ-metadata, bất biến, lưu trong SQLite, duyệt được sau khi tháo ổ, và so sánh hai cây thư mục mà không bao giờ đọc nội dung file hay ghi lên ổ nguồn. Nghiên cứu tham chiếu VisualDiffer trong tài liệu là chính xác — đã kiểm chứng trực tiếp từ mã nguồn: lịch sử của VisualDiffer chỉ lưu đường dẫn và cấu hình so sánh (không lưu cây đã quét), cây so sánh của nó nằm hoàn toàn trong RAM, và nó chứa các module copy/move/delete/sync cùng so sánh nội dung — tất cả đều không được đưa vào FSD.

**Ba lỗi chặn (BLOCKER) phải sửa trước khi viết code:**

1. **FSD-DB-001:** ràng buộc `UNIQUE(snapshot_id, normalized_path)` trong `schema.sql` sẽ làm hỏng quá trình quét trên ổ phân biệt hoa-thường (hai file `Report.txt` và `REPORT.TXT` cho cùng một khóa chuẩn hóa). Phải bỏ UNIQUE trên đường dẫn chuẩn hóa, thay bằng `UNIQUE(snapshot_id, parent_id, name)`.
2. **FSD-ARCH-001:** quy tắc chuẩn hóa đường dẫn (dạng Unicode NFC/NFD, quy tắc gập hoa-thường, so sánh giữa hai hệ file khác nhau) chưa được định nghĩa ở mức byte — đây là khóa so sánh của toàn bộ sản phẩm.
3. **FSD-ARCH-002:** chưa có mô hình thực thi cho so sánh với thư mục/ổ đĩa đang gắn (live). Khuyến nghị: mọi nguồn live được quét thành **snapshot tạm (transient)** trước, để engine so sánh chỉ có một đường xử lý duy nhất: snapshot với snapshot.

**Các điểm quan trọng khác:** mâu thuẫn về chữ ký subtree giữa PRD và MVP_PLAN (khuyến nghị: MVP dùng bộ đếm tổng hợp, hoãn chữ ký Merkle); bảng `comparison_results` không nên lưu các dòng `matched` (chỉ lưu khác biệt); PRAGMA `foreign_keys` phải đặt trên từng kết nối chứ không phải trong schema.sql; kiểu dữ liệu thời gian nên là INTEGER epoch thay vì TEXT; nên bật sandbox với quyền chỉ-đọc (`user-selected.read-only`) vì đó là cơ chế bảo vệ read-only mạnh nhất; đặc tả UX còn thiếu hoàn toàn phần kéo-thả và chuyển hướng bố cục ngang/dọc.

**Khuyến nghị triển khai:** bắt đầu bằng giai đoạn R0 (chốt các quyết định đặc tả, sửa schema), sau đó R1: **prototype dòng lệnh `fsdscan`** dùng chung module với app để kiểm chứng tốc độ quét và độ bền SQLite trước khi làm UI. Tự động chụp khi gắn ổ (Phase 4) chỉ bắt đầu khi đã chứng minh được: phục hồi quét gián đoạn, định danh ổ đĩa tin cậy, mô hình sandbox/bookmark ổn định, và migration schema an toàn.

**Giao diện so sánh:** khuyến nghị mô hình lai — một mô hình dữ liệu so sánh hợp nhất chạy trên SQL; MVP hiển thị bằng **một cây `NSOutlineView` thống nhất với cột trái/phải**; chế độ hai bảng đồng bộ kiểu VisualDiffer là tùy chọn sau MVP. Chuyển bố cục ngang/dọc dùng `NSSplitViewController` của AppKit (không dùng `HSplitView`/`VSplitView` của SwiftUI), giữ nguyên trạng thái chọn/mở rộng/cuộn bằng khóa đường dẫn chuẩn hóa. Kéo-thả dùng kiểu pasteboard tùy chỉnh `com.fsd.comparison-source` song song với `public.file-url` để snapshot (offline) và ổ live dùng chung một mô hình pane.

Tài liệu hiện tại đủ để bắt đầu R0 ngay; sau khi hoàn tất các sửa đổi trong Mục 15, dự án đủ điều kiện bước vào giai đoạn viết code.
