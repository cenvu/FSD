# Reference Study — VisualDiffer

## Document status

- **Role:** External reference implementation study
- **Reference repository:** `visualdiffer/visualdiffer`
- **Repository URL:** https://github.com/visualdiffer/visualdiffer
- **Inspected branch:** `main`
- **Inspected commit:** `fbd1ef685626cc6dd25976e6e9670adba204e33a`
- **Inspection date:** 2026-07-24
- **License observed:** GPLv3
- **FSD policy:** Reference-only; do not use VisualDiffer as the base repository

This document records what FSD — FishSock Differ may learn from VisualDiffer while preserving FSD's independent product scope, architecture, data model, and implementation.

---

## 1. Executive conclusion

VisualDiffer strongly validates the user experience and several technical patterns required for FSD:

- Native macOS folder comparison.
- Side-by-side tree presentation.
- AppKit `NSOutlineView` for hierarchical data.
- Synchronized navigation between left and right panels.
- Added, removed, changed, older, and matched states.
- Configurable metadata comparison.
- File and folder exclusion filters.
- Symbolic-link, package, and sandbox handling.

However, VisualDiffer is not the same product and should not become the architectural base for FSD.

The central distinction is:

> **VisualDiffer compares files and folders that are currently accessible.**
>
> **FSD — FishSock Differ captures persistent metadata snapshots so that disconnected volumes can still be browsed and compared later.**

VisualDiffer's history stores comparison-session configuration and paths. It does not appear to persist a complete immutable metadata tree for offline browsing. FSD — FishSock Differ therefore requires a different canonical data layer and lifecycle.

---

## 2. Product overlap assessment

### Approximate overlap

| Area | Estimated overlap | Notes |
|---|---:|---|
| Folder comparison user interface | 60–70% | Two panels, hierarchical rows, status visualization and filters are highly relevant. |
| Comparison concepts | 50–60% | Filename, size and timestamp comparisons overlap; content and text diff are outside FSD MVP. |
| Runtime scanner behavior | 35–45% | Both enumerate filesystem entries, but FSD — FishSock Differ writes immutable snapshot generations to SQLite. |
| Persistent data architecture | 10–20% | VisualDiffer persists session settings; FSD — FishSock Differ must persist complete volume and entry histories. |
| Offline volume catalog | Near 0% | This is FSD's primary differentiator. |
| Read-only product invariant | Low | VisualDiffer includes copy, move, delete, rename and touch operations. |

### Shared product surface

Both products may present:

- Left and right folder trees.
- Differences by relative path.
- Missing or orphan items.
- File-size mismatches.
- Optional timestamp comparison.
- Exclusion filters.
- Summary counters.
- Expand, collapse, next difference and synchronized scrolling.

### FSD-only product surface

FSD — FishSock Differ must additionally provide:

- Persistent volume identity.
- Automatic recognition of previously seen volumes.
- Multiple capture sessions per volume.
- Immutable and atomic snapshot generations.
- Offline browsing after eject.
- Live-to-snapshot comparison.
- Snapshot-to-snapshot comparison.
- Interrupted capture recovery.
- Per-snapshot aggregate counts and sizes.
- JSON and self-contained HTML snapshot export.
- A read-only architecture with no source-file mutation features.

---

## 3. Confirmed VisualDiffer characteristics

The inspected repository describes VisualDiffer as a macOS application for visually comparing folders and files through a side-by-side interface. Its documented features include added, removed and modified states, file-level diff, filters, drag and drop, export or automation hooks, and an optimized comparison engine.

The repository currently targets:

- macOS 13.5+.
- Swift 6.2.
- A notarized application.
- App Sandbox.
- GPLv3 licensing.

The codebase is a Swift rewrite of an earlier Objective-C project. Legacy Objective-C files still exist in selected areas.

---

## 4. Relevant source areas

The following source locations are useful for architectural study. They are listed for orientation only and are not approved copy sources.

### Folder tree and synchronized UI

```text
Sources/Features/FoldersCompare/Components/FoldersOutlineView/FoldersOutlineView.swift
Sources/Features/FoldersCompare/Controller/OutlineViewItemDelegate.swift
Sources/Features/FoldersCompare/Controller/FileSystemController/Sync/SyncOutlineView.swift
Sources/Features/FoldersCompare/Components/FolderPanelView.swift
Sources/Features/FoldersCompare/Controller/FoldersWindowController+FoldersOutlineView.swift
```

Relevant concepts:

- `NSOutlineView` hierarchy presentation.
- Paired left and right panels.
- Visible-row management.
- Selection and expansion synchronization.
- Difference-oriented navigation.

### Folder reading

```text
Sources/Features/FoldersCompare/Services/FolderReader/FolderReader.swift
Sources/Features/FoldersCompare/Services/FolderReader/FolderReader+Log.swift
```

Relevant concepts:

- Directory enumeration.
- Error propagation through a delegate.
- Package skipping.
- Symbolic-link policy.
- Symlink-loop protection.
- Progress reporting.
- Filtering before recursive traversal.

### Comparison engine

```text
Sources/Features/FoldersCompare/Services/ItemComparator/ItemComparator.swift
Sources/Features/FoldersCompare/Services/ItemComparator/ItemComparator+Compare.swift
Sources/Features/FoldersCompare/Services/ItemComparator/ItemComparator+Align.swift
Sources/Features/FoldersCompare/CompareItem/CompareItem+Comparison.swift
```

Relevant concepts:

- Comparison options represented as flags.
- Separate filename, timestamp, size and content comparisons.
- Left and right item alignment.
- Matched, changed, older and orphan counters.
- Folder summary propagation.

### In-memory item representation

```text
Sources/Features/FoldersCompare/CompareItem/CompareItem.swift
Sources/Features/FoldersCompare/CompareItem/CompareItem+VisibleItem.swift
```

Relevant concepts:

- Parent-child hierarchy.
- Cross-link to the corresponding item on the other side.
- File type, package and symbolic-link flags.
- Per-item summary state.

FSD — FishSock Differ must not adopt this structure as its canonical store because it retains the full compared tree as objects in memory.

### Session history and documents

```text
Sources/Core/History/HistorySessionManager.swift
Sources/Core/History/HistoryEntity.swift
Sources/Core/SessionDiff/SessionDiff.swift
Sources/Core/Document/VDDocument.swift
Models/History.xcdatamodeld/
```

Relevant concepts:

- Core Data-backed comparison history.
- Saved left and right paths.
- Saved comparator, filter and display options.
- Security-scoped bookmark restoration.

Important limitation:

- The stored session fields describe how to reopen or repeat a comparison.
- They do not represent a persisted full offline copy of all scanned entry metadata.
- Reopening a saved session validates and accesses the original paths again.

### File operations

```text
Sources/Features/FoldersCompare/FileManager/FileOperationManager.swift
Sources/Features/FoldersCompare/FileManager/CopyCompareItem.swift
Sources/Features/FoldersCompare/FileManager/MoveCompareItem.swift
Sources/Features/FoldersCompare/FileManager/DeleteCompareItem.swift
Sources/Features/FoldersCompare/FileManager/RenameCompareItem.swift
Sources/Features/FoldersCompare/FileManager/TouchCompareItem.swift
```

These modules are explicitly outside FSD's product scope.

### Sandbox and secure bookmarks

```text
Sources/SharedKit/Utilities/Document/SecureBookmark.swift
```

Relevant concepts:

- Security-scoped bookmarks.
- Stale bookmark refresh.
- Synchronization around shared bookmark storage.
- Reusing an ancestor permission for a descendant path.

---

## 5. Feature comparison matrix

| Capability | VisualDiffer | FSD requirement | Decision |
|---|---:|---:|---|
| Native macOS application | Yes | Yes | Same platform direction. |
| Apple Silicon support | Yes | Yes | Native arm64 remains mandatory. |
| macOS 13+ | Yes | Yes | Compatible target range. |
| Side-by-side folder trees | Yes | Yes | Study interaction patterns. |
| AppKit outline view | Yes | Yes | Keep `NSOutlineView` for large trees. |
| Added, removed and changed states | Yes | Yes | Reimplement with snapshot-aware semantics. |
| Compare filename or path | Yes | Yes | Relative path is mandatory. |
| Compare logical file size | Yes | Yes | Default fast match criterion. |
| Compare modification timestamp | Yes | Optional | Disabled in default DIT profile. |
| Compare file content | Yes | No for MVP | Do not implement in core scanner. |
| Text diff | Yes | No | Out of scope. |
| Finder labels and tags | Yes | Optional future | Do not block MVP. |
| Exclusion filters | Yes | Yes | Include DIT and macOS ignore profiles. |
| Package handling | Yes | Yes | Default to Finder-like package treatment. |
| Symbolic-link controls | Yes | Yes | Default: record link, do not follow. |
| Saved comparison sessions | Yes | Optional | May be added after snapshot workflow. |
| Offline metadata tree | No confirmed implementation | Yes | Core FSD feature. |
| Multiple immutable snapshots | No confirmed implementation | Yes | Core FSD feature. |
| Volume UUID identity | No confirmed implementation | Yes | Core FSD feature. |
| Auto-capture on mount | No confirmed implementation | Yes | Planned after manual MVP. |
| Snapshot-to-snapshot diff | No confirmed implementation | Yes | Core FSD feature. |
| Live-to-snapshot diff | No confirmed implementation | Yes | Core FSD feature. |
| SQLite lazy tree | No | Yes | FSD — FishSock Differ canonical design. |
| Copy, move, rename or delete | Yes | Prohibited | Never port these modules. |
| Read-only architecture | Session-configurable only | Mandatory | Enforce at target and service boundaries. |
| JSON snapshot export | No confirmed core feature | Yes | Required. |
| Self-contained HTML report | No confirmed core feature | Yes | Required. |

---

## 6. Patterns approved for independent reimplementation

The following are general software and UX patterns that FSD — FishSock Differ may independently implement from its own requirements.

### 6.1 Two-panel outline workflow

Approved behavior:

- Left and right trees use equivalent columns.
- Expand or collapse may be synchronized.
- Selection may be synchronized when matching paths exist.
- Scroll position may be loosely synchronized.
- Missing entries leave a visual placeholder on the opposite side.
- Users can jump to the next or previous difference.
- Matched subtrees can be collapsed or hidden.

FSD implementation requirement:

- Each expanded node must query children lazily from SQLite.
- The UI must not require every entry in a snapshot to remain in memory.

### 6.2 Flag-based comparison profiles

Approved model:

```text
Compare relative path
Compare item type
Compare logical size
Compare modification timestamp — optional
Compare selected metadata — optional future
```

FSD profiles:

- `FAST_METADATA`
- `STRUCTURE_ONLY`
- `STRICT_METADATA`
- `DIT_MEDIA`

No content-reading flag may be enabled in the MVP scanner.

### 6.3 Exclusion and visibility rules

Approved behavior:

- Record ignored items or omit them based on capture policy.
- Apply a separate comparison visibility policy.
- Hide macOS noise by default.
- Let users reveal ignored entries.
- Distinguish "not captured" from "captured but ignored during comparison."

Recommended default comparison ignores:

```text
.DS_Store
._*
.Spotlight-V100
.Trashes
.fseventsd
.DocumentRevisions-V100
Temporary Items
```

### 6.4 Symbolic-link safety

Approved behavior:

- Detect symbolic links explicitly.
- Do not follow them by default.
- Never traverse a link that can escape the selected root without explicit policy.
- Prevent ancestor loops.
- Store link-target metadata only when it can be read safely and is useful.

### 6.5 Package policy

Approved behavior:

- Treat Finder packages as single entries by default.
- Allow an advanced option to expand packages during capture.
- Persist the selected capture policy with the snapshot.

### 6.6 Progressive status and cancellation

Approved behavior:

- Report scan start, progress, current path, completion and failure.
- Allow cancellation.
- Keep the last complete snapshot usable when a new scan is cancelled or interrupted.

### 6.7 Security-scoped bookmark concepts

Approved only if FSD — FishSock Differ adopts App Sandbox:

- Store bookmarks for user-granted roots.
- Detect and refresh stale bookmarks.
- Balance `startAccessingSecurityScopedResource()` and stop calls.
- Protect shared bookmark state from concurrent mutation.

Direct-distribution builds without App Sandbox may not require this subsystem in the first implementation.

---

## 7. Patterns that must not be adopted as FSD foundations

### 7.1 Full canonical tree in RAM

VisualDiffer's `CompareItem` hierarchy holds parent, children, linked opposite item, visible state and summaries as objects.

FSD — FishSock Differ must instead use:

```text
SQLite snapshot entries as source of truth
+ lightweight row view models
+ lazy child queries
+ bounded caches
```

Reason:

- A catalog may contain hundreds of thousands or millions of entries.
- Snapshots remain available indefinitely.
- Several snapshots may be compared without loading all entries.

### 7.2 Live path as the persistent identity

A saved absolute path is insufficient because external volumes can:

- Be disconnected.
- Mount under a changed name.
- Be reformatted.
- Be cloned.
- Reappear with a different mount path.

FSD identity must prioritize:

1. Persistent volume UUID.
2. Filesystem or Disk Arbitration identity.
3. Device and partition metadata where available.
4. Fallback fingerprint.
5. User-assigned physical label.

### 7.3 Mutable filesystem operations

FSD — FishSock Differ must not implement:

- Copy.
- Move.
- Delete.
- Rename.
- Touch.
- Replace.
- Synchronize.
- Modify Finder labels or tags on source files.

Read-only must be an architectural invariant, not merely a disabled toolbar state.

### 7.4 Content and text diff in the core engine

FSD's scanner must not:

- Open media payloads.
- Compare binary content.
- Parse text.
- Generate Quick Look previews.
- Generate thumbnails.
- Calculate content hashes by default.

Any future verification feature must be a separate opt-in adapter with clear performance and trust labels.

### 7.5 Session history as snapshot history

A history row containing paths and comparator settings is not a snapshot.

A valid FSD snapshot must contain:

- Volume identity.
- Capture start and completion timestamps.
- Capture status.
- Root entry.
- Every captured entry or a documented omission.
- Parent-child relationships.
- Relative paths.
- Item types.
- Logical sizes.
- Optional allocated sizes and timestamps.
- Aggregate counts and sizes.
- Scan issues.
- Schema and scanner versions.

---

## 8. Clean-room implementation policy

Because VisualDiffer is licensed under GPLv3, FSD — FishSock Differ will use a reference-only, clean-room-oriented workflow unless the project owner explicitly changes the licensing strategy after legal review.

This is an internal engineering policy, not legal advice.

### Allowed

Agents and developers may:

- Read VisualDiffer's public documentation and source to understand behavior.
- Record high-level observations in this document.
- Describe user-visible workflows in original language.
- Build FSD — FishSock Differ from its own PRD, architecture and tests.
- Independently implement general patterns such as two-panel trees, filters and comparison flags.
- Refer to public macOS APIs and Apple documentation.
- Compare resulting behavior at a black-box level.

### Prohibited without explicit owner approval

Agents and developers must not:

- Copy VisualDiffer source code into FSD.
- Translate VisualDiffer code line by line into new syntax.
- Copy comments, test fixtures, test cases or error strings verbatim.
- Copy images, icons, screenshots, branding or other repository assets.
- Preserve VisualDiffer's internal class layout merely by renaming symbols.
- Port its Objective-C or Swift modules into FSD.
- Copy file-operation code.
- Represent FSD — FishSock Differ as a fork or derivative build unless that is an intentional GPLv3 decision.

### Agent instruction

When an Agent consults VisualDiffer, its handoff must state:

```text
REFERENCE USED: visualdiffer/visualdiffer
REFERENCE SCOPE: behavior and architectural study only
CODE COPIED: none
ASSETS COPIED: none
IMPLEMENTATION BASIS: FSD — FishSock Differ PRD and architecture documents
```

### Traceability rule

New FSD production code must be traceable to at least one of:

- `PRD.md`
- `ARCHITECTURE.md`
- `UX_UI_SPEC.md`
- `database/schema.sql`
- An accepted ADR in `DECISIONS.md`
- Apple platform documentation
- A FSD-specific test or runtime probe

"VisualDiffer does it this way" is not sufficient justification for a production design decision.

---

## 9. Architecture mapping

| VisualDiffer concept | FSD equivalent | Required change |
|---|---|---|
| `CompareItem` | `SnapshotEntryRecord` plus lightweight row model | Persist in SQLite; do not retain entire tree. |
| Linked left/right items | Diff join result keyed by normalized relative path | Compute lazily or cache bounded results. |
| `FolderReader` | `MetadataScanner` | Write batches to an in-progress snapshot generation. |
| `ItemComparator` | `MetadataDiffEngine` | Compare snapshot rows; no content payload access. |
| `CompareSummary` | `SnapshotAggregate` and `DiffAggregate` | Persist subtree and snapshot aggregates. |
| History session | `ComparisonPreset` | Keep separate from actual snapshots. |
| Saved document paths | `ComparisonSourceReference` | Source can be live root or snapshot ID. |
| Security bookmark | `AccessGrantStore` | Needed only for sandboxed live sources. |
| File-operation manager | No equivalent | Explicitly excluded. |
| File content diff | Optional future verification adapter | Not part of scanner or MVP. |

---

## 10. Proposed FSD modules after this study

```text
FSDApp
├── AppShell
├── VolumeLibrary
│   ├── VolumeIdentityService
│   ├── MountObserver
│   └── VolumeRepository
├── Capture
│   ├── MetadataScanner
│   ├── CaptureCoordinator
│   ├── SnapshotWriter
│   ├── AggregateBuilder
│   └── ScanIssueRecorder
├── Catalog
│   ├── SnapshotRepository
│   ├── EntryRepository
│   ├── SearchRepository
│   └── TreeQueryService
├── Compare
│   ├── ComparisonProfile
│   ├── MetadataDiffEngine
│   ├── DiffRepository
│   └── DiffSummaryBuilder
├── UI
│   ├── VolumeSidebar
│   ├── SnapshotBrowser
│   ├── DualTreeCompare
│   ├── OutlineViewBridge
│   └── Inspector
├── Export
│   ├── JSONExporter
│   └── HTMLExporter
└── Platform
    ├── FileSystemMetadataProvider
    ├── DiskArbitrationAdapter
    └── AccessGrantStore
```

The module boundaries preserve the useful high-level separation seen in mature comparison applications while keeping FSD — FishSock Differ independent and snapshot-centric.

---

## 11. Performance implications

VisualDiffer's live comparison approach is optimized for immediate access to two directories. FSD — FishSock Differ must optimize for different workloads:

- One very large volume captured once.
- Repeated captures over time.
- Offline browsing.
- Many historical snapshots.
- Diffing snapshots without physical media attached.

Required FSD performance rules:

1. Batch SQLite inserts inside explicit transactions.
2. WAL mode for catalog writes and concurrent reads.
3. No full snapshot decoding into arrays.
4. Query children by `snapshot_id + parent_id`.
5. Index normalized relative paths.
6. Store aggregate counts and logical bytes.
7. Use bounded caches for expanded nodes.
8. Separate scan concurrency from database-writer concurrency.
9. Prefer sequential metadata traversal for rotational media.
10. Treat interrupted snapshots as partial and never silently promote them to complete.

---

## 12. Read-only invariant after this study

The existence of comprehensive file-operation modules in VisualDiffer reinforces the need for a stricter FSD — FishSock Differ boundary.

FSD production targets must satisfy all of the following:

- No source mutation service is present in the application target.
- No UI action performs copy, move, delete, rename, replace or touch.
- Source roots are opened only for metadata reads.
- Database writes target the app's private catalog location only.
- Export writes target a user-selected report destination only.
- Tests assert that scanner interfaces expose no mutation methods.
- Any future optional verification feature opens files read-only.

---

## 13. Decisions derived from this reference study

### REF-VD-001 — Keep the independent repository

**Decision:** Accepted

FSD — FishSock Differ will not fork VisualDiffer as its initial implementation base.

### REF-VD-002 — Retain AppKit outline views

**Decision:** Accepted

VisualDiffer provides further evidence that AppKit outline views are appropriate for a native, synchronized folder-tree interface.

### REF-VD-003 — Preserve SQLite snapshot architecture

**Decision:** Accepted

The in-memory live comparison tree used by VisualDiffer does not replace FSD's persistent SQLite catalog.

### REF-VD-004 — Separate presets from snapshots

**Decision:** Accepted

Saved comparison configuration and snapshot history are distinct entities and must remain separate in the schema.

### REF-VD-005 — Exclude file operations

**Decision:** Accepted

No VisualDiffer file-operation subsystem will be ported or recreated for the FSD MVP.

### REF-VD-006 — Apply clean-room reference rules

**Decision:** Accepted

VisualDiffer may inform requirements and behavior, but FSD production code must be independently implemented.

---

## 14. Implementation checklist

Before implementing the folder comparison UI:

- [ ] Define the `ComparisonSource` abstraction for live roots and snapshot IDs.
- [ ] Define normalized relative-path rules.
- [ ] Define placeholder rows for one-sided entries.
- [ ] Define expansion synchronization behavior.
- [ ] Define loose scroll synchronization behavior.
- [ ] Define next and previous difference navigation.
- [ ] Define comparison colors and accessibility labels.
- [ ] Verify that tree rows load lazily from SQLite.

Before implementing the scanner:

- [ ] Confirm the scanner interface is metadata-only.
- [ ] Define package and symbolic-link policy.
- [ ] Define batch size and transaction behavior.
- [ ] Define interruption and cancellation states.
- [ ] Record inaccessible entries as scan issues.
- [ ] Verify that no file payload is read.

Before accepting a contribution influenced by VisualDiffer:

- [ ] Contributor identifies the FSD requirement being implemented.
- [ ] No VisualDiffer source or assets were copied.
- [ ] The implementation follows FSD naming and module boundaries.
- [ ] Tests are written from FSD requirements.
- [ ] Handoff includes the clean-room reference declaration.

---

## 15. Final positioning

VisualDiffer should remain a named reference implementation because it demonstrates that a polished native macOS two-panel folder comparison experience is practical and maintainable.

It should not redefine FSD's product identity.

FSD's durable value remains:

```text
Volume identity
+ immutable capture sessions
+ offline metadata trees
+ historical comparison
+ DIT-oriented profiles
+ read-only guarantees
```

Canonical positioning statement:

> **VisualDiffer compares what is connected now. FSD — FishSock Differ remembers and compares what was connected before.**
