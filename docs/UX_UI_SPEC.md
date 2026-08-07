# UX and UI Specification

## 1. Design principles

- Read-only must be obvious.
- Offline entries should feel like a faithful mirror, not fake playable files.
- Large trees must remain responsive.
- Comparison semantics must be unambiguous.
- Differences receive priority; matching branches can recede.
- Avoid visual similarity to file synchronization tools that imply write actions.

## 2. Main navigation

```text
┌──────────────────────────────────────────────────────────────┐
│ FSD — FishSock Differ                                                │
├────────────────┬─────────────────────────────────────────────┤
│ Collections    │ Content                                     │
│ ├ All Snapshots│                                             │
│ ├ Unsorted     │                                             │
│ ├ XYZ          │                                             │
│ ├ ABC          │                                             │
│ ├ NA           │                                             │
│ └ CEN          │                                             │
│ Live Volumes   │                                             │
│ Recent Sources │                                             │
│ Comparisons    │                                             │
│ Capture Queue  │                                             │
│ Reports        │                                             │
│ Settings       │                                             │
└────────────────┴─────────────────────────────────────────────┘
```

Full semantics: [`SNAPSHOT_COLLECTIONS.md`](SNAPSHOT_COLLECTIONS.md) §10. `Collections` and `Live Volumes` are deliberately separate sidebar sections, never merged into one identity model — a Collection is user-defined catalog organization; a volume is physical source identity. `All Snapshots` lists every snapshot regardless of Collection; `Unsorted` lists only those with no Collection assigned. Each named Collection row shows a snapshot count. Right-click on a Collection offers Rename, Edit Note, and Delete; a `+` control creates a new Collection inline.

## 3. Screen A — Volume library and offline browser

```text
┌────────────────────────────────────────────────────────────────────────────┐
│ FSD — FishSock Differ     [Capture] [Compare] [Search]               Read-only     │
├──────────────────────┬─────────────────────────────────────────────────────┤
│ KN_SSD_014      ●     │ Camera Card A — Day 03            [Rename] [Move]  │
│ CAMERA_MASTER   ○     │ Collection: XYZ Productions · KN_SSD_014 · exFAT   │
│ SHUTTLE_03      ○     │ Captured: 24 Jul 2026, 17:42 · Offline             │
│                      │                                                     │
│ SNAPSHOTS in XYZ Productions │ 248,129 files · 6,442 folders · 4.82 TB    │
│ Camera Card A — Day 03   Complete  ├───────────────────────────────────────┤
│ Camera Card A — Day 02   Complete  │ ▾ PROJECT_A                4.71 TB    │
│ Camera Card A — Day 01   Interrupted│  ▾ CAMERA                 4.52 TB    │
│                      │       A001C001_240724.mxf            109.95 GB       │
│                      │       A001C002_240724.mxf            112.18 GB       │
│                      │   ▸ AUDIO                             85.40 GB       │
│                      │   ▸ REPORT                            12.00 MB       │
├──────────────────────┴─────────────────────────────────────────────────────┤
│ Offline snapshot · Source files are not stored and cannot be modified.     │
└────────────────────────────────────────────────────────────────────────────┘
```

Snapshot rows are labeled by `display_name` first, never by a raw session id or UUID; the technical identity (session number, snapshot id, capture timestamp) is always one click away in the summary inspector, never hidden, never the primary label. Row priority, left to right / top to bottom: display name, source name, capture date, filesystem, complete/partial status, online/offline state (`SNAPSHOT_COLLECTIONS.md` §10).

### Required interactions

- expand and collapse lazily;
- type-to-search by name and relative path;
- select snapshot from history;
- show summary inspector (including the technical session id/timestamp underneath the display name);
- copy virtual relative path;
- reveal live item only when mounted and path exists;
- export current snapshot;
- delete local snapshot after confirmation;
- rename the snapshot's display name;
- move the snapshot to a different Collection, or to `Unsorted` (instant — no rescan, no progress indicator);
- edit the snapshot's optional note.

## 3.1 Screen A1 — Capture-organization sheet

Shown before a manual capture starts:

```text
┌────────────────────────────────────────────────────────────┐
│ Capture Organization                                       │
├──────────────────────────────────────────────────────────────┤
│ Source            REDMAG_A                                 │
│ Collection         [ XYZ Productions ▾ ]   (remembered default) │
│ Snapshot name      [ Camera Card A — Day 03            ]   │
│                                                              │
│ [ ] Use this Collection by default for this source          │
│                                                              │
│                                    [Cancel]   [Start Capture]│
└──────────────────────────────────────────────────────────────┘
```

- The Collection field opens a picker: existing Collections, "New Collection…", or "No Collection (Unsorted)".
- When a value is preselected from a remembered default, the sheet visibly labels it `(remembered default)` — never applied silently and never hidden from the choice.
- Snapshot name is optional; the placeholder text previews the generated name (`<source> — <date/time>`) that will be used if left blank.
- This sheet never appears for automatic (mount-triggered) capture — see `SNAPSHOT_COLLECTIONS.md` §7.

### Required interactions

- pick an existing Collection, create a new one inline, or choose none;
- leave the snapshot name blank to accept the generated default;
- check "Use this Collection by default for this source" to remember it (`SNAPSHOT_COLLECTIONS.md` §6);
- Start Capture proceeds regardless of whether a Collection was chosen.

## 4. Screen B — Capture progress

```text
┌────────────────────────────────────────────────────────────────────────────┐
│ Capturing CAMERA_MASTER                                      [Cancel]      │
├────────────────────────────────────────────────────────────────────────────┤
│ /PROJECT_A/CAMERA/A014/...                                                │
│                                                                            │
│ [███████████████████████████──────────────]                                │
│                                                                            │
│ Files       182,441                                                        │
│ Folders       4,920                                                        │
│ Logical       3.91 TB                                                      │
│ Issues             2                                                       │
│ Elapsed        02:41                                                       │
│                                                                            │
│ Metadata only. File contents are not being read.                           │
├────────────────────────────────────────────────────────────────────────────┤
│ Latest issue: Permission denied · /.Spotlight-V100                         │
└────────────────────────────────────────────────────────────────────────────┘
```

### Capture completion states

- Complete;
- Interrupted by disconnect;
- Cancelled by user;
- Failed before usable metadata was recorded;
- Completed with warnings.

## 5. Screen C — Two-pane comparison

```text
┌────────────────────────────────────────────────────────────────────────────┐
│ Compare: Fast Metadata     [Differences Only] [Next ›] [Export Report]     │
├──────────────────────────────────────┬─────────────────────────────────────┤
│ LEFT                                 │ RIGHT                               │
│ KN_SSD_014 · Snapshot 007            │ KN_SSD_014 · Snapshot 008          │
│ 248,127 files · 4.819 TB             │ 248,129 files · 4.821 TB           │
├──────────────────────────────────────┼─────────────────────────────────────┤
│ = PROJECT_A                          │ = PROJECT_A                         │
│   = A001                             │   = A001                            │
│   − A003                             │                                     │
│                                      │   + A004                            │
│   ≠ AUDIO  84.90 GB                  │   ≠ AUDIO  85.40 GB                │
│     = A001.WAV                       │     = A001.WAV                      │
│     − A002.WAV                       │                                     │
│                                      │     + A003.WAV                      │
├──────────────────────────────────────┴─────────────────────────────────────┤
│ Added 3 · Removed 1 · Changed 2 · Matched 248,124                         │
│ Metadata Match only. File contents were not verified.                      │
└────────────────────────────────────────────────────────────────────────────┘
```

### Comparison states

- `=` matched;
- `+` added on right;
- `−` missing on right;
- `≠` same path with changed metadata;
- `!` inaccessible or uncertain;
- `~` ignored by active profile.

### Required interactions

- synchronized expand and collapse where paths align;
- optional synchronized scrolling;
- differences-only filter;
- collapse matched branches;
- next and previous difference;
- copy relative path;
- change comparison profile;
- export self-contained HTML report.

A Collection itself is never a valid drop target's *content* here — it is not draggable into a comparison pane. Dragging a Collection is disabled outright (rather than opening a picker on drop), because a Collection is a navigation aid, not a comparison input, and its sidebar row already expands to let a user pick one specific snapshot from inside it. A snapshot dragged out of a Collection's own listing is an ordinary comparison source, indistinguishable from one dragged from `All Snapshots` or `Unsorted` (`SNAPSHOT_COLLECTIONS.md` §12).

## 6. Volume card states

### Online

```text
● KN_SSD_014
Mounted at /Volumes/CAMERA_MASTER
Last capture: Today, 17:42
```

### Offline

```text
○ KN_SSD_014
Last seen: 24 Jul 2026, 18:03
Last complete snapshot: Session 008
```

### Capture warning

```text
△ KN_SSD_014
Last capture interrupted
Using Session 007 for offline browsing
```

## 7. Settings

### General

- Launch at login;
- show menu bar item;
- default offline snapshot selection;
- database location display;
- report export destination.

### Capture

- automatic capture allowlist;
- delay after mount;
- package traversal policy;
- hidden item policy;
- excluded paths;
- minimum free local database space warning.

### Comparison

- default profile;
- ignore macOS service files;
- case sensitivity policy;
- timestamp tolerance for Strict Metadata;
- show allocated size as informational only.

## 8. Empty states

### No volumes

```text
No captured volumes yet.
Connect a drive or choose a folder to create the first metadata snapshot.
[Choose Folder] [Scan Mounted Volume]
```

### No comparison

```text
Choose a source for the left and right side.
Sources can be live folders or saved snapshots.
```

### No Collections yet

```text
No Collections yet.
Group your snapshots by project, client, or however you like.
[New Collection]
```

Shown under the `Collections` sidebar section when none exist. `All Snapshots` and `Unsorted` remain visible regardless — they are not Collections a user creates, so this empty state never hides them.

## 9. Safety copy

Persistent footer in relevant views:

```text
Read-only catalog. FSD — FishSock Differ never stores file contents or modifies source files.
```

Comparison disclaimer:

```text
Metadata Match does not prove that file contents are identical.
```
