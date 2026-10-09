# FSD2 UI reference research and redesign brief

**Status:** Research and design proposal for Owner review; no UI implementation authorized.
**Research date:** 2026-10-09
**Decision requested:** Choose a design direction before any change to `UX_UI_SPEC.md` or product screens.

This brief separates **Observed** behavior described in public reference-app documentation from **FSD proposal**. It is a documentation study, not a hands-on usability test: no reference-app screenshots were captured, no comparative timing or scale measurements were run, and the sources do not establish user consensus. Official product documentation and vendor manuals are used where available. Community anecdotes were not needed to resolve a research question and are not used as evidence.

## Executive recommendation

Advance **Direction A — Source Navigator** for Owner review. It starts from FSD's durable source and capture relationship, then uses one hierarchical workspace for browsing and a separate compare workspace. That matches the accepted “Remember the drive → Browse it later → Compare it → Find the change” story and the accepted Finder/Xcode-style information architecture without importing either app's data model or copying its visual design. Finder's configurable sidebar and hierarchy views, Xcode's navigator/editor/inspector separation, and the comparison tools' filters and next-difference controls all support these interaction choices.

Direction B — Capture Archive / Compare Bench — is a viable alternative if Owner wants recent activity and comparisons to dominate the landing surface. Its timeline-first hierarchy makes offline history visible, but it puts more pressure on users to infer which source and immutable capture pair is active. Direction A keeps those identities in view through browsing and comparison.

Neither proposal treats metadata equality as file-content verification. The compare result must preserve the accepted wording **“Metadata Match · Content Not Verified.”** Neither direction adds content preview, a Library-wide search claim, a physical-drive identity claim, or a new Drive Set/Collection semantic.

## Evidence method and FSD authority

The source study covers Finder, Xcode, DaisyDisk, ForkLift, Beyond Compare, and VisualDiffer. “Observed” below means the named public source documents a behavior; it does not mean every version or every configuration was tested live. Vendor performance statements are identified as claims rather than benchmarks. Where the reviewed public material is silent, that is recorded as a research limit rather than filled with assumptions.

FSD product facts and boundaries come from [UX_UI_SPEC.md](UX_UI_SPEC.md), [PRODUCT_STATE.md](PRODUCT_STATE.md), and the existing [VisualDiffer reference study](REFERENCE_VISUALDIFFER.md). The accepted FSD visual direction is “FST visual DNA + Finder/Xcode-style information architecture,” with an explicit instruction not to clone FST's linear Transfer layout. This brief proposes information architecture and interaction concepts only. It does not revise that contract.

## Reference-app observations

| Reference | Observed public behavior | FSD relevance and boundary |
|---|---|---|
| **macOS Finder** | The sidebar groups frequently used locations and pinned locations. Finder offers Icon, List, Column, and Gallery views; List emphasizes compact metadata, Column keeps nested hierarchy visible, and Gallery emphasizes previews. Items can be sorted/grouped; tags and Smart Folders expose saved organization. Finder settings let people choose whether a search begins at the whole Mac, the open folder, or the last-used scope. | Borrow a stable location navigator, compact metadata rows, explicit hierarchy, scope-aware search and saved organization concepts. FSD should use a single-snapshot metadata list/tree for offline browsing; no automatic file preview or unsupported cross-Library search. [Finder organization and views](https://support.apple.com/en-au/guide/mac-help/mchle9f0a1b2/27/mac/27), [Finder search scope setting](https://support.apple.com/en-gb/guide/mac-help/mchlp2803/26/mac/26). |
| **Xcode** | The project window separates toolbar, navigator, editor, debug area, and inspector. Selecting a navigator item opens it in the central editor; the navigator can be filtered. Tabs, a jump bar and multiple editor panes support movement among related items. Source control review offers inline and side-by-side comparisons with controls to move between changes. | Borrow the separation between persistent navigation, primary work surface, and contextual inspector; keep navigation state visible while changing selection. For FSD this maps to a snapshot tree and metadata inspector, plus a distinct pair-comparison workspace. Xcode's editing, build, and code-review semantics are not FSD behavior. [Configuring the Xcode project window](https://developer.apple.com/documentation/xcode/configuring-the-xcode-project-window), [managing files and folders in a project](https://developer.apple.com/documentation/xcode/managing-files-and-folders-in-your-xcode-project), [tracking source-control changes](https://developer.apple.com/documentation/xcode/tracking-code-changes-in-a-source-control-repository). |
| **DaisyDisk** | The launch view lists mounted volumes and shows capacity gauges; users explicitly scan a whole disk or folder. A sunburst assigns wedge area by object size, groups very small objects, drills into a folder on click, and returns to its parent from the center. A sidebar gives details for the pointed-at folder. Its manual documents Quick Look/file-content preview and delete actions. It also documents a “File system not responding” timeout state with troubleshooting guidance. | Borrow a strong source overview and explicit scan action, plus a clearly described timeout error and recovery guidance. Do not borrow the size-first sunburst as FSD's main hierarchy: FSD must prioritize name/path/status and immutable capture facts. DaisyDisk's file-content preview and delete flow conflict with FSD's metadata-only/read-only product boundary. Its timing descriptions are vendor guidance, not measurements for this study. [Disk overview and scan](https://daisydiskapp.com/guide/4/en/DisksOverview/), [sunburst navigation](https://daisydiskapp.com/guide/4/en/UnderstandingSunburst/), [previewing](https://daisydiskapp.com/guide/4/en/Previewing/), [timeout error](https://daisydiskapp.com/guide/4/en/TimeoutError/). |
| **ForkLift 4** | The documented window has two central file panes, a left sidebar for devices/connections/shares and grouped favorites, an optional right Info/Activities/Log pane, a path bar and status bar, and tabs. Pane orientation and list/column/icon views are configurable. Search can use ForkLift's active-pane traversal, optionally including subfolders, or local Spotlight metadata/content search; `Command-F` opens search. `Command-Up` and `Command-Down` navigate to parent/child folders. | Borrow optional panes, path context, tabs, explicit search scope and visible activity/log affordances. FSD's search must be bounded by the selected snapshot unless additional backend scope support is implemented. ForkLift's sync, copy, move, delete and remote-connection workflows are excluded. [ForkLift 4 Quick Start Guide](https://binarynights.com/manual). |
| **Beyond Compare** | Folder Compare presents two sides and a navigable hierarchy, with sessions, left/right path selection, expansion controls, filename search, configurable filters, a legend, and next/previous difference commands. The guide describes filters for all/differences/same and saving the active display-filter choice with the session. Session settings can compare names, sizes, timestamps and, when selected, file contents; folder status aggregates contained file results. Keyboard shortcuts can be customized. | Borrow explicit Before/After sides, compact status categories, legend, filters, session reopening and next/previous difference navigation. FSD must expose only its accepted metadata comparison profile and mark matching metadata as “Content Not Verified.” Beyond Compare's merge/sync/copy actions and content-reading profiles are outside FSD. [Folder Compare commands](https://www.scootersoftware.com/v4help/commandsdir.html), [display filters](https://www.scootersoftware.com/v4help/display_filters.html), [comparison criteria](https://www.scootersoftware.com/v4help/dir_how_to_compare.html), [walking through differences](https://www.scootersoftware.com/v4help/walking_through_differences.html). |
| **VisualDiffer** | The public manual documents a path control over two side-by-side directory trees, color-coded comparison results and a scope bar for All, Only Mismatches, Only Matches, No Orphans and Only Orphans. Separate toggles can show empty or orphan folders. The comparison-method page lists metadata and content-based modes, and the legend describes a difference strip that can jump to a marked section in a file diff. The current repository README claims a fast engine for large structures; this is a project claim, not independently measured evidence. | Borrow paired hierarchy, path context, direct status filtering and a textual legend. Do not adopt file-level content diff, color-only status, file-management actions, or its implementation. The current public repo says the project was rewritten in Swift and is GPL-3.0; the older FSD reference study is historical and must not be treated as verification of the current implementation's architecture. [VisualDiffer repository and README](https://github.com/visualdiffer/visualdiffer), [folder compare view](https://wiki.visualdiffer.com/folderView.html), [comparison methods](https://wiki.visualdiffer.com/comparisonMethods.html), [color legend](https://wiki.visualdiffer.com/colorsLegend.html). |

### Cross-cutting analysis

**Sidebar and information hierarchy.** Finder and Xcode establish a left navigation area with a central task surface; Xcode adds an inspector on the right. ForkLift adds a device/favorites sidebar and optional information/activity pane. The comparison products keep the two compared roots visibly oriented. FSD should preserve the active source or snapshot context in navigation and label both comparison sides at all times.

**Large-directory browsing.** Finder documents compact List and hierarchical Column presentations, not a performance guarantee. Xcode documents navigator filtering. ForkLift documents active-location traversal and optional recursive search. DaisyDisk groups small segments in a space visualization, while Beyond Compare and VisualDiffer expose result filters that reduce visible noise. VisualDiffer's large-tree statement is vendor copy, not a measured benchmark. FSD's evidence-backed adaptation is bounded lazy outline browsing with direct-child paging, no eager descendant load, and explicit progress/error/retry rows; never add an unbounded “expand all” as the solution.

**Breadcrumbs, filters and search.** Finder lets users select search scope; ForkLift has both current-pane and local Spotlight search; Beyond Compare and VisualDiffer make result filters directly visible. FSD should show the selected snapshot in the breadcrumb and the search scope next to the field. “This Snapshot” is the supported metadata scope today. “This Drive” and “This Library” remain future scope choices only after their identity/index contracts exist; the brief does not claim Library-wide search is implemented.

**Multi-pane and inspector.** Xcode's navigator/editor/inspector and ForkLift's two file panes plus optional right information pane show two useful patterns. FSD should use a one-tree-plus-inspector layout while browsing a snapshot, then a dedicated dual-tree Compare workspace. Keep the inspector collapsible because three persistent panes compete for space on typical Mac windows.

**Comparison status and navigation.** Beyond Compare and VisualDiffer separate status filters from the tree and expose difference traversal; Xcode also documents inline/side-by-side source review and change navigation. FSD can adopt clear text labels, icon shapes, a legend, direct category filters and Next/Previous Difference. It must keep missing-side states explicit and never let color carry status alone. “Metadata Match” is not a content-equality result.

**Keyboard and accessibility.** The reviewed sources document specific keyboard affordances: Finder lists a shortcut for creating a folder, Xcode points to menu shortcuts, DaisyDisk publishes a shortcut table, ForkLift documents parent/child and search shortcuts, and Beyond Compare lets users configure shortcuts. These public pages do not establish complete VoiceOver support for each reference app. Apple recommends honoring standard shortcuts, supporting Full Keyboard Access where possible, consistent focus and text/shape in addition to color. For FSD, every sidebar item, tree row, filter, page/retry action and inspector field needs a meaningful accessibility label; focus must stay visible; selection and expansion must be separate; all comparison states need text/icon equivalents. These are design requirements, not claims about current FSD accessibility acceptance. [Apple keyboard guidance](https://developer.apple.com/design/human-interface-guidelines/keyboards/), [focus and selection](https://developer.apple.com/design/human-interface-guidelines/focus-and-selection/), [color guidance](https://developer.apple.com/design/human-interface-guidelines/color), [VoiceOver navigation](https://support.apple.com/en-gb/guide/voiceover/mchlp2699/mac).

**Empty, loading, error and offline states.** DaisyDisk's explicit timeout gives a useful error example. Xcode exposes task progress in the toolbar, while ForkLift documents an Activities/Log pane. The reviewed sources provide less detail on generic empty states and do not establish a durable offline snapshot catalog for these products. FSD should show separate states: no captured source, no completed captures, loading a bounded page, empty folder, unavailable live source with a browseable offline snapshot, partial/interrupted capture, failed page with Retry, and compare results with no differences. Keep the last complete immutable capture available during new or interrupted capture work.

## Direction A — Source Navigator (recommended)

**Design thesis.** Keep a stable left navigator around a source-centric overview and one main task surface. Browse one immutable snapshot at a time; open Compare as a separate, clearly oriented workspace. This is an FSD adaptation of Finder/Xcode information hierarchy and the comparison tools' explicit filters.

### Information architecture

```text
HOME
LIBRARY
  All Drives
  Recent Captures
COLLECTIONS
  Current accepted Collection semantics
COMPARE
  Comparisons
CONNECTED NOW
  Only sources actually observed as mounted/available

Global toolbar: Search | Capture Snapshot (when eligible) | Help
Snapshot context: Overview | Explore | History
Compare context: Before / After | Results | Filters
```

“All Drives” is the accepted target label; until strong physical identity exists, rows must not imply that a display name or mount path proves physical identity. “Connected Now” appears only from a real mount observation; mount detection is a known product gap. Existing Collections retain their accepted meaning. The target concept “Drive Set” remains gated by its ADR and is not silently substituted for Collection.

### Annotated overview — selected source/catalog record

```text
┌ FSD ─────────────────────────────────────────────────────────────────┐
│ Search this snapshot…                              Capture Snapshot* │
├ Navigation ─────────┬ Source overview ────────────────────────────────┤
│ Home                │ <Captured source label>       SOURCE IDENTITY   │
│ Library             │                               Not verified**   │
│  All Drives         │ OFFLINE SNAPSHOT                                │
│  Recent Captures    │ Last completed capture: <date/time>             │
│ Collections         │ Source availability: Not connected              │
│ Compare             │                                                   │
│  Comparisons        │ Captures                                         │
│ Connected Now       │ <capture date>  Complete  [Browse] [Compare…]   │
│                     │ <capture date>  Interrupted [Details]           │
│                     │ Recent comparison: <Before> → <After>            │
└─────────────────────┴───────────────────────────────────────────────────┘
* only if an eligible source and capture flow are actually available
** do not render as a definitive physical identity or invent a drive ID
```

The overview makes availability and capture provenance more prominent than storage analytics. Counts and dashboard aggregates appear only when a bounded catalog query supports them. Capture and comparison summaries link to records; completed capture facts remain immutable. An interrupted capture is visibly separate from the last completed snapshot.

### Annotated Explore and Search

```text
┌ Library / <captured source label> / <snapshot timestamp> ─────────────┐
│ OFFLINE SNAPSHOT · Captured <date/time> · Source not connected        │
│ Search: [ THIS SNAPSHOT ▾ ] [ filename or path… ] [Filters ▾]         │
├ tree ────────────────────────────────────┬ Inspector ─────────────────┤
│ ▾ Folder A                               │ Name                       │
│   ▸ Folder B                             │ Path                       │
│     Clip_001.mov                         │ Size · Modified · Kind     │
│   ▸ Folder C                             │ Source availability        │
│                                         │ Technical details ▾        │
└─────────────────────────────────────────┴─────────────────────────────┘
```

Breadcrumb segments navigate to captured ancestors. List rows use columns such as Name, Size, Modified and the supported captured attributes; no thumbnail or content preview is implied. Tree children load on expansion through bounded pages. Search defaults to **This Snapshot** and returns indexed metadata. “This Drive” and “This Library” must not be selectable until the corresponding backend scope is implemented. Filters refine supported metadata, never silently inspect payload bytes.

Collections are a separate saved-organization view with existing semantics; the row describes a Collection only as it exists today. The design does not present Collections as physical-drive groups. No Collection UI is implemented currently, so its view is target design pending product work and Owner approval.

### Annotated History and Drive/source status

```text
History for <catalog source record>
┌ Captures (paged) ────────────────────────────────────────────────────┐
│ Complete · <timestamp> · <entry count>                    [Browse]  │
│ Interrupted · <timestamp> · partial; not the last complete capture  │
│ Complete · <timestamp>                                    [Compare]  │
└──────────────────────────────────────────────────────────────────────┘

Source status
  Mounted now: Yes / No / Unknown (based only on an actual observation)
  Identity: Confirmed / Ambiguous / Not established (only when supported)
  Last observed: <timestamp> (only when recorded)
```

History is a paged per-source timeline, not a mutable rewrite of captured facts. An unplugged source is still browseable through its completed snapshot; show an “Offline Snapshot” badge and capture time persistently. If source identity cannot be established, show that limitation and keep the snapshot accessible under its catalog record without claiming a physical-drive match.

### Dedicated Compare workspace

```text
┌ Compare ──────────────────────────────────────────────────────────────┐
│ BEFORE / REFERENCE                    AFTER / CHANGED                 │
│ <snapshot A · capture time>            <snapshot B · capture time>    │
│ Metadata Match 12  Added 3  Removed 1  Changed 4                      │
│ [All] [Changed] [Added] [Removed] [Metadata Match]  [Prev] [Next]   │
├ Before tree ───────────────────────────┬ After tree ──────────────────┤
│ ▾ Audio                                │ ▾ Audio                      │
│   take_01.wav  Metadata Match*         │   take_01.wav Metadata Match*│
│   ambience.wav Missing on After        │   new_take.wav Added         │
│                                         │                              │
├ Inspector: Before metadata ────────────┴ After metadata ──────────────┤
│ Metadata Match · Content Not Verified                                  │
└──────────────────────────────────────────────────────────────────────┘
* status text/icon shown on both corresponding rows; no color-only cue
```

Choosing a hero count applies the matching result filter, locates the first matching row, expands only its ancestors, scrolls it into view, and selects it. Next/Previous Difference follows deterministic result order and announces the current position. A missing counterpart uses an explicit empty-side cell. Before/After stays visible even when filtering, scrolling, or opening the Inspector. Durable history lists snapshot/snapshot comparisons. A live-side comparison is labeled transient and remains workspace-scoped under current semantics; no new persistence promise is made.

### Visual hierarchy and reusable components

- Use macOS system materials, controls, focus treatment and typography; express FSD identity through measured color accents, compact status badges and restrained separators, not a replica of Finder, Xcode or any competitor.
- Reusable components: source/capture identity header; availability badge; immutable capture row; breadcrumb; scope-aware search field; lazy outline row; filter chips; comparison side header; status label/icon; empty/error/retry row; collapsible metadata inspector.
- Lead with source label, snapshot time and availability, then primary action, then counts/details. Keep Name/path as the strongest content; use secondary type/size/date columns to support scanning.
- At narrower windows, collapse the inspector first and retain one navigable tree; keep the compare side identity, status and filter strip visible. At wider windows, show inspector and synchronized trees together. These are layout hypotheses for later testing, not measured breakpoints.
- Support dark/light appearance, increased contrast, Reduce Motion and Full Keyboard Access; status uses text and symbols as well as color. [Apple's macOS design guidance](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos/) recommends using large displays for more content with comfortable density and allowing window/view personalization.

### Trade-offs and risks

This direction makes the source and offline capture story legible and aligns closely with the accepted IA, but a persistent sidebar plus dual compare trees can become dense. The inspector therefore collapses and the compare toolbar should group controls by status/navigation rather than offer every setting at once. The overview must not imply live-source detection, identity certainty, dashboard aggregates or a complete Library search before those services exist. VoiceOver, keyboard traversal, scroll synchronization and minimum-width layout still require product-specific validation.

## Direction B — Capture Archive / Compare Bench

**Design thesis.** Make the landing surface a chronological archive of captures and comparisons. Users choose a source and capture pair from the archive, then work in task-focused tabs. Navigation is contextual and compact instead of a permanent full sidebar. This makes history prominent but asks the user to hold source/pair context across views.

### Information architecture

```text
HOME / ARCHIVE
  Recent activity · Sources · Captures · Comparisons
EXPLORE (opens one selected snapshot workspace)
SEARCH (snapshot scope by default)
COLLECTIONS (current semantics)
COMPARE (opens a dedicated Compare Bench tab)
CONNECTED NOW (only observed mounted sources)

Workspace tabs: Overview | Explore · <snapshot> | Compare · <A> → <B>
Context rail: current source/capture facts, availability, inspector
```

The archive view is the default after launch. A compact toolbar contains Search, Capture Snapshot when eligible, and a workspace tab strip. Source identity and timestamp remain attached to each workspace tab so opening another task does not silently change context.

### Annotated Overview / Archive

```text
┌ FSD  [Search this snapshot…] [Capture Snapshot*] ────────────────────┐
│ Home   Sources   Captures   Comparisons   Collections   Connected Now │
├ Activity / archive timeline ───────────────────────┬ Context rail ────┤
│ TODAY                                               │ Selected record │
│ <source label> · Complete capture · <time> [Open]  │ captured label  │
│ <A> → <B> · 4 metadata changes [Review]             │ availability    │
│ YESTERDAY                                           │ identity status │
│ <source label> · Complete capture · <time> [Open]  │ snapshot time   │
│                                                     │ Technical info  │
└────────────────────────────────────────────────────┴──────────────────┘
```

The timeline groups immutable capture/comparison events by date and source label. It is a catalog chronology, not a claim about physical drive identity or filesystem change history beyond captured metadata. Selecting an item updates the context rail; opening it creates or focuses a workspace tab.

### Source-centric Overview

```text
Workspace: Source · <captured source label>       [Identity not established]
Availability: Offline · last completed capture <timestamp>
┌ Latest completed capture ─────────────────────────────────────────────┐
│ <timestamp> · <bounded metadata totals, when available>              │
│ [Browse snapshot]  [Compare with earlier capture…]                    │
├ Capture history ──────────────────────────────────────────────────────┤
│ Complete <timestamp> · immutable                                 Open │
│ Interrupted <timestamp> · partial; last complete remains available   │
└──────────────────────────────────────────────────────────────────────┘
```

This source overview is reached from a source row in the archive, then remains associated with that catalog record while users open Explore or Compare tabs. Totals appear only when supported by a bounded query. The identity and availability labels follow observed evidence; a display name never becomes a fabricated disk identifier.

### Annotated Explore and Search / Collections

```text
Workspace: Explore · <captured source label> / <timestamp>
OFFLINE SNAPSHOT · Source unavailable · Captured <date/time>
[breadcrumb]  [THIS SNAPSHOT ▾] [Search name/path…] [Filters]
┌ Outline: Name | Size | Modified ───────────────────┬ Context rail ────┐
│ ▾ Folder A                                          │ Selected facts  │
│   ▸ Folder B                                        │ path            │
│     Clip_001.mov                                    │ size/date/type  │
│                                                     │ availability    │
└────────────────────────────────────────────────────┴──────────────────┘
```

Search is a focused workspace tied to the active snapshot by default. The result header repeats the scope and source/capture identity. Collection results remain based on the current Collection contract; future Drive Set concepts are not presented as shipped functionality. When the inspector competes with tree width it becomes a context rail that can be hidden, not a preview surface.

### Annotated source status and History

```text
Sources archive: <captured source label>  [Identity: not established]
Availability: Offline · last observed <time, if actually recorded>

Capture history (paged, chronological)
  Complete <time>  · immutable facts  · Browse · Compare
  Interrupted <time> · partial; last complete remains unchanged
  Complete <time>  · immutable facts  · Browse · Compare
```

The source status page separates live availability from archived snapshots. “Connected Now” is populated only from an actual mount observer and only links to a source when identity evidence supports the relationship. With the current identity gap, an ambiguous source remains unresolved instead of being fused by display name or path.

### Dedicated Compare Bench

```text
Workspace tab: Compare · <Before capture> → <After capture>
┌ Pair header ─────────────────────────────────────────────────────────┐
│ BEFORE / REFERENCE <source · capture time>   ⇄   AFTER / CHANGED ... │
│ 12 Metadata Match · 3 Added · 1 Removed · 4 Changed                  │
│ [All] [Changed] [Added] [Removed] [Metadata Match] [Prev] [Next]    │
├ Before hierarchy ───────────────────┬ After hierarchy ────────────────┤
│ ▾ Audio                             │ ▾ Audio                         │
│   take_01.wav [Metadata Match]      │   take_01.wav [Metadata Match]  │
│   ambience.wav [Missing on After]   │   new_take.wav [Added]          │
├ Before metadata ────────────────────┴ After metadata ─────────────────┤
│ Metadata Match · Content Not Verified                                  │
└───────────────────────────────────────────────────────────────────────┘
```

Compare is a separate tab with persistent pair identity and independent filters. Count selection reveals a matching entry through its ancestors and focuses it in both aligned trees. The Inspector shows Before/After metadata only. The title and status labels repeat the pair even when the toolbar is compacted. No file-content diff, sync, copy or content preview is introduced.

### Visual hierarchy, trade-offs and risks

Archive cards and chronological grouping make recent work easy to reopen and reduce the permanent navigation footprint. The design gives Comparison and Capture activity equal visual status with source identity, which may pull attention away from FSD's core source-first story. Multiple workspace tabs can obscure whether the user is looking at a live source or an offline snapshot unless each tab repeats state and capture time. It may scale better for compact windows, but the horizontal pair view still needs a minimum useful width and a stacked/one-side-at-a-time fallback that retains clear Before/After orientation. As in Direction A, use native system colors and controls, visible keyboard focus, explicit text/icon status, and a collapsible inspector. Timeline density, keyboard tab order and VoiceOver announcements require later validation.

## Direction comparison and recommendation

| Criterion | Direction A — Source Navigator | Direction B — Capture Archive / Compare Bench |
|---|---|---|
| Primary mental model | Select a source, then browse its immutable captures or compare them. | Reopen a recent capture/comparison from a chronological archive. |
| Match to accepted north star | Strong: source → browse → compare → locate result. | Moderate: history and recent activity lead; source context is secondary. |
| Offline-first clarity | Persistent source/snapshot header on every view. | Explicit archive and workspace labels, but tab/context switches increase reminder burden. |
| Navigation concept | Finder/Xcode-style persistent sidebar and central task surface. | Compact top-level archive navigation plus context-sensitive tabs/rail. |
| Compare workflow | Dedicated route, separate from snapshot browsing. | Dedicated Compare Bench tab, separate from archive. |
| Density risk | Sidebar + outline + inspector; mitigate by collapsing inspector. | Timeline cards + context rail; compare tabs still need two trees. |
| Main product risk | “All Drives” can overstate identity until identity service/ADR lands. | Chronological activity can make captures/comparisons feel primary and hide source lineage. |

**Recommendation: Direction A.** It follows the accepted FSD visual DNA and the explicit Finder/Xcode information-architecture contract while borrowing comparison navigation patterns only where they clarify metadata results. The source/snapshot context remains persistent, which best protects the offline-first story and reduces the chance a user mistakes an archived snapshot for a connected source. Direction B should remain available if Owner review finds that recent capture/comparison resumption is the dominant first-run task.

## Non-negotiable FSD presentation rules for either direction

1. **Offline-first:** a completed snapshot remains browseable when its source is absent; show its capture time and offline state clearly.
2. **Metadata-only by default:** file names, path and captured metadata may be shown; no automatic file-content preview or payload comparison is implied.
3. **Read-only source:** no copy, move, delete, rename, sync or source repair action appears in FSD browsing or comparison.
4. **Immutable captures:** a new/interrupted capture never replaces or mutates the last completed snapshot. Distinguish partial/interrupted from complete.
5. **Truthful comparison:** successful equality uses “Metadata Match · Content Not Verified.” Never imply that matching size/date/name establishes file-content equality.
6. **Identity honesty:** a display name, volume label or mount path alone is not a physical-drive identity. Show ambiguity or “not established” when the identity contract cannot prove the relationship.
7. **Search honesty:** current backend supports bounded metadata search within one snapshot. Do not claim This Drive or This Library search before those services and indexes exist.
8. **No semantic shortcut:** current Collections retain current semantics. “Drive Set” remains a future target behind its ADR.
9. **Accessibility:** expose labels for state, status and actions; keyboard can reach all useful content and actions; focus is visible; status is never color-only; loading/error/retry is announced and retains valid selection where possible.

## Source register

### Apple

- [Organize your files in the Finder on Mac](https://support.apple.com/en-au/guide/mac-help/mchle9f0a1b2/27/mac/27)
- [Change Finder settings on Mac](https://support.apple.com/en-gb/guide/mac-help/mchlp2803/26/mac/26)
- [Configuring the Xcode project window](https://developer.apple.com/documentation/xcode/configuring-the-xcode-project-window)
- [Managing files and folders in an Xcode project](https://developer.apple.com/documentation/xcode/managing-files-and-folders-in-your-xcode-project)
- [Tracking code changes in a source control repository](https://developer.apple.com/documentation/xcode/tracking-code-changes-in-a-source-control-repository)
- [Designing for macOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos/)
- [Keyboards](https://developer.apple.com/design/human-interface-guidelines/keyboards/)
- [Focus and selection](https://developer.apple.com/design/human-interface-guidelines/focus-and-selection/)
- [Color](https://developer.apple.com/design/human-interface-guidelines/color)
- [Use VoiceOver to navigate apps and windows on Mac](https://support.apple.com/en-gb/guide/voiceover/mchlp2699/mac)

### DaisyDisk

- [Version 4 User Guide — Disk overview and scanning](https://daisydiskapp.com/guide/4/en/DisksOverview/)
- [Understanding the disk map](https://daisydiskapp.com/guide/4/en/UnderstandingSunburst/)
- [Previewing file content and details](https://daisydiskapp.com/guide/4/en/Previewing/)
- [File system not responding (time-out) error](https://daisydiskapp.com/guide/4/en/TimeoutError/)
- [Keyboard shortcuts and multi-touch gestures](https://daisydiskapp.com/guide/4/en/Hotkeys/)

### ForkLift

- [ForkLift 4 Quick Start Guide](https://binarynights.com/manual)

### Beyond Compare

- [Beyond Compare User Guide](https://www.scootersoftware.com/v4help/)
- [Folder Compare commands](https://www.scootersoftware.com/v4help/commandsdir.html)
- [Display filters](https://www.scootersoftware.com/v4help/display_filters.html)
- [How to compare in the Folder Compare view](https://www.scootersoftware.com/v4help/dir_how_to_compare.html)
- [Walking through differences](https://www.scootersoftware.com/v4help/walking_through_differences.html)

### VisualDiffer

- [Current public repository and README](https://github.com/visualdiffer/visualdiffer) — GPL-3.0; performance statements are vendor claims.
- [Folder Compare View](https://wiki.visualdiffer.com/folderView.html)
- [Comparison Method](https://wiki.visualdiffer.com/comparisonMethods.html)
- [Colors Legend](https://wiki.visualdiffer.com/colorsLegend.html)

### FSD product authorities

- [UX/UI Specification](UX_UI_SPEC.md)
- [Product implementation baseline](PRODUCT_STATE.md)
- [Existing VisualDiffer reference study](REFERENCE_VISUALDIFFER.md) — earlier, date-bound study; not authority for current VisualDiffer implementation details.

**Pending Owner decision:** select Direction A, Direction B, or request a bounded revision. Until approval, this brief changes no UI spec, product source, tests, schema or dependencies.
