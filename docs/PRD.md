# Product Requirements Document — FSD (FishSock Differ)

## 1. Problem

Media professionals regularly work with many external volumes containing camera originals, audio, reports, proxies, deliverables, and backups. After a volume is ejected, Finder can no longer show what was stored on it. Existing folder comparison tools frequently perform content inspection or hashing that is unnecessary and slow for very large media files.

FSD — FishSock Differ must preserve a metadata-only reflection of each volume and allow fast comparison between two directory trees without reading file payloads.

## 2. Product objective

Build a native, read-only macOS application that:

- captures the directory tree and filesystem metadata of a selected volume or folder;
- keeps multiple immutable snapshot sessions;
- allows offline browsing after eject;
- compares two trees by metadata only;
- clearly distinguishes metadata matching from checksum verification.

## 3. Target users

Primary:

- Digital Imaging Technicians;
- data managers;
- editors and assistant editors;
- small rental houses and media teams.

Secondary:

- photographers;
- archive managers;
- users managing many removable disks.

## 4. Supported environment

- macOS 13 Ventura or later;
- Apple Silicon arm64;
- delivered as a single self-contained `.app` — no Homebrew, macFUSE, ntfs-3g, kernel extension, or app extension install required of the user;
- removable HDD, SSD, USB and Thunderbolt storage;
- network volumes may be supported later with explicit limitations (`PRODUCT_STATE.md` KI-007, unchanged by filesystem scope).

### 4.1 Filesystem scope

FSD reads APFS, HFS+, FAT16, FAT32, exFAT, NTFS, ext2, ext3, ext4, and UDF. Most of these are already natively readable once macOS mounts them; ext2/ext3/ext4 are read through an embedded raw filesystem reader bundled inside the app, since macOS has no native support for them at all. FSD does not need Finder-level mounting of a filesystem it doesn't natively support — only enough read access to enumerate it and extract metadata.

The provider mechanics, the per-filesystem support level (nothing is claimed "Supported" until it clears the seven-step proof defined there), and the dependency/license research behind the ext2/3/4 reader are canonical in, respectively: [`FILESYSTEM_PROVIDER_ARCHITECTURE.md`](FILESYSTEM_PROVIDER_ARCHITECTURE.md), [`FILESYSTEM_SUPPORT_MATRIX.md`](FILESYSTEM_SUPPORT_MATRIX.md), and [`DEPENDENCY_AND_LICENSE_REVIEW.md`](DEPENDENCY_AND_LICENSE_REVIEW.md). This PRD does not restate their content.

FSD does not recognize camera-vendor folder layouts (ARRI, RED, Sony, Canon, Nikon, or otherwise), validate media, analyze codecs, or apply any media-specific capture profile. It is a filesystem-metadata catalog, not a media-management tool.

## 5. Core user stories

### US-01 — Capture a mounted volume

As a user, I can select or automatically detect a mounted volume and create a metadata snapshot without modifying that volume.

Acceptance criteria:

- source volume is opened read-only from the application perspective;
- scanner never writes helper files, databases, indexes or markers to the source;
- progress shows scanned files, folders, bytes and current path;
- completed snapshot is immutable;
- interrupted capture is marked partial and never replaces the last complete snapshot.

### US-02 — Browse an offline volume

As a user, I can eject a volume and still browse its last complete directory tree.

Acceptance criteria:

- tree can be expanded lazily;
- search works without the source volume;
- items are visibly marked as offline virtual entries;
- file actions that would modify content are unavailable;
- Reveal in Finder is enabled only when the live item exists.

### US-03 — View capture history

As a user, I can see every snapshot of a known volume and identify the last complete capture.

Acceptance criteria:

- snapshots show timestamp, duration, status and totals;
- complete, interrupted and failed states are visually distinct;
- old snapshots are not overwritten automatically;
- snapshot deletion affects only the local catalog.

### US-04 — Compare two trees

As a user, I can compare two folders or snapshots and see whether their relative paths, item types, file counts and logical sizes match.

Acceptance criteria:

- supported sources: live folder, live volume root, offline snapshot folder;
- live sources are first captured as transient snapshots before comparison;
- transient snapshots are an implementation detail and are excluded from user history;
- default profile compares relative path, item type and logical size;
- results classify entries as matched, added, removed, changed, inaccessible, or uncertain;
- collisions on comparison keys (e.g. case-folded collisions) result in `uncertain` classification;
- comparison keys track original case and case-folded variants based on source case-sensitivity;
- matched subtrees can be collapsed;
- next and previous difference navigation is available;
- comparison explicitly states "Content Not Verified".

### US-05 — Export a report

As a user, I can export snapshot or comparison results to JSON and self-contained HTML.

Acceptance criteria:

- JSON follows a versioned schema;
- HTML can be opened without the application;
- export contains metadata only;
- no source file payload or preview is embedded.

### US-06 — Organize snapshots into Collections

As a user, I can group my snapshots under my own project/client/production names instead of identifying them only by timestamp and technical session number.

Acceptance criteria:

- a snapshot is recognizable primarily by a human-facing display name, its Collection, its source, capture date, and filesystem — never primarily by a raw session id or UUID;
- before a manual capture, a lightweight sheet offers an existing Collection, a new Collection, or no Collection (`Unsorted`), plus an optional snapshot name;
- a remembered default Collection can be set per stable source identity and is preselected (never silently applied) on the next manual capture of that exact source;
- an automatic mount-triggered capture never blocks on this choice — it uses a remembered default if one exists, otherwise `Unsorted`, always;
- moving a snapshot between Collections, renaming its display name, or editing its note never rescans the source, never duplicates entries, and never changes capture timestamps or comparison results;
- deleting a Collection never deletes the snapshots inside it.

Full specification: [`SNAPSHOT_COLLECTIONS.md`](SNAPSHOT_COLLECTIONS.md) — this PRD does not restate its rules.

## 6. Functional requirements

### 6.1 Volume identity

The application shall store:

- persistent volume UUID when available;
- filesystem type;
- volume name;
- total capacity;
- device metadata when available;
- fallback fingerprint;
- user-defined physical label and role.

Potential duplicate identities must require user confirmation before merging histories.

Volumes read through the embedded raw provider (ext2/ext3/ext4) rarely expose a filesystem UUID macOS itself recognizes; identity for those falls back to device/partition identifiers captured per-snapshot (`device_identifier`, `partition_identifier` — see `database/schema.sql` and `FILESYSTEM_PROVIDER_ARCHITECTURE.md`). A normalized `devices`/`partitions` identity table separate from `volumes` remains a future decision, not required for MVP.

### 6.2 Snapshot metadata

Each snapshot shall store:

- start and completion timestamps;
- scan status;
- mount path used during capture;
- file and folder totals;
- logical and allocated byte totals;
- inaccessible item count;
- scanner version, schema version, and normalization identity;
- immutable entry records;
- a mutable Collection membership, display name, and optional note — catalog metadata layered on top of the immutable fields above, never affecting them (`SNAPSHOT_COLLECTIONS.md`).

### 6.3 Entry metadata

Minimum entry fields:

- snapshot identifier;
- parent identifier;
- normalized relative path;
- case-preserving and case-folded paths and names;
- name and extension;
- item type;
- logical size;
- allocated size when available;
- creation and modification timestamps when available;
- symbolic link and package flags;
- scan issue flags;
- direct child and subtree aggregates.

### 6.4 Comparison profiles

#### Fast Metadata

- relative path;
- item type;
- logical file size;
- ignores timestamps;
- ignores common macOS service files by default.

#### Structure Only

- relative path;
- item type;
- ignores all sizes and timestamps.

#### Strict Metadata

- relative path;
- item type;
- logical file size;
- modification date;
- optional creation date;
- includes hidden and service files unless manually excluded.

## 7. Non-functional requirements

### Performance

- UI must not load an entire million-entry tree into memory.
- Tree children must be fetched lazily from SQLite.
- Inserts must be batched in transactions.
- Scanner must not read file payloads in default mode.
- Diff must skip identical subtrees when aggregate signatures match.

### Reliability

- last complete snapshot must remain usable after crash, disconnect or force quit;
- database writes must use transactions;
- schema migrations must be versioned;
- interrupted scans must remain clearly marked.

### Security and safety

- no copy, move, rename, delete or write operation against source volumes;
- no hidden marker file on mounted volumes;
- exported reports contain metadata only;
- application database remains inside the user's Application Support directory.

### Accessibility

- keyboard navigation for the tree and differences;
- VoiceOver labels for status icons and comparison states;
- color must not be the only status indicator.

## 8. Out of scope for MVP

- byte-for-byte verification;
- MD5, SHA or xxHash content hashing;
- media playback;
- thumbnail generation;
- codec and camera metadata extraction;
- copy or synchronization engine;
- file repair or recovery;
- cloud synchronization;
- iOS support;
- Intel macOS builds;
- Magika-based file content/type classification (deferred to Phase 1.5, `MVP_PLAN.md`, `ARCHITECTURE.md` §9).

### 8.1 Future content classification (Phase 1.5, deferred, not MVP)

Magika content classification is a future optional enrichment phase and is not part of the MVP. Specifically:

- file classification is not displayed anywhere in the MVP UI;
- file classification is not used in MVP metadata diff or comparison results;
- Metadata Match continues to be computed from only the existing metadata profile (relative path, item type, logical size, and the other fields already listed in §6.4), unaffected by whether classification exists;
- a detected content type is not content verification and must never be described as such;
- current MVP acceptance criteria (§5, §9) remain unchanged by this future phase.

## 9. Success metrics

MVP is successful when:

- a 100,000-entry volume can be scanned without UI blocking;
- a completed snapshot remains browsable after eject;
- two snapshots can be compared without source media attached;
- a one-entry difference can be located without expanding the entire tree;
- no write operation occurs on test source volumes;
- interrupted capture never corrupts or replaces the previous complete snapshot.

## 10. Product language rules

Use:

- Metadata Match;
- Structure Match;
- Content Not Verified;
- Last Complete Snapshot;
- Partial Snapshot.

Do not use unless content hashing is later implemented:

- Verified Copy;
- Bit-identical;
- Checksum Verified;
- Safe Backup.

