OWNER_PRODUCT_UX_DIRECTION=YES
IMPLEMENTATION_PROOF=NO
IMPLEMENTATION_AUTHORIZATION=NO

# UX and UI Specification

This document defines the canonical Owner Product/UX Direction for FSD.

It clearly distinguishes:
- TARGET UX
- CURRENT BACKEND SUPPORT
- GAP
- ADR REQUIRED
- DEFERRED / NON-GOAL

## 1. PRODUCT NORTH STAR

Remember the drive
→ Browse it later
→ Compare it
→ Find the change.

FSD must feel like a filesystem/productivity tool, not primarily a database or forensics tool.

## 2. ABSOLUTE SAFETY

- source absolutely read-only;
- ordinary capture metadata-only;
- completed snapshot facts immutable;
- interrupted never replaces last complete;
- metadata equality never content verification;
- symlinks not traversed by default;
- large trees bounded/lazy;
- classification bounded and optional;
- classification never affects snapshot/comparison truth;
- unknown/uncertain explicit.

Canonical successful compare wording:
Metadata Match
Content Not Verified

## 3. TARGET DEMO STORY

Canonical E2E:

Home/Library
→ connect production drive
→ connected-drive card
→ explicit Capture Snapshot
→ inline non-blocking capture
→ completed snapshot opens
→ browse hierarchy
→ selected-entry Detected File Type while source available
→ eject
→ continue offline browse
→ choose snapshot/current source
→ Compare
→ hero counts
→ click Changed/other category
→ navigate to exact result
→ expand ancestors
→ select exact item
→ Before/After Inspector.

## 4. THREE WOW MOMENTS

- drive gone but still browsable;
- find exact difference in huge tree;
- friendly Detected File Type without content-verification claim.

## 5. VISUAL / IA DIRECTION

FST visual DNA + Finder/Xcode-style information architecture.

Do not clone FST's linear Transfer layout.

Target first-pass IA:

HOME

LIBRARY
  All Drives
  Recent Captures

DRIVE SETS
  <groups>
  + New Drive Set

COMPARE
  Comparisons

CONNECTED NOW
  <mounted drives>

## 6. DRIVE SET DIRECTION

A Drive Set is a user-created group of PHYSICAL DRIVES.

DRIVE_SET_VS_COLLECTION=ADR_REQUIRED

Until that ADR exists:
- Collection remains current accepted implementation semantics.
- Drive Set remains Owner target direction.
- no mass rename;
- no schema inference;
- no claim existing Collections already implement Drive Sets.

## 7. HOME / DASHBOARD CONTRACT

Target:
- Library aggregates;
- Recent Comparisons;
- Recent Captures;
- Recent Drives;
- Connected Drive card.

All metrics database-backed and bounded.

## 8. CAPTURE UX

Target:
- mount detection;
- explicit capture by default;
- optional Auto Capture setting;
- inline progress;
- rest of app remains usable;
- manual completion opens snapshot;
- auto completion does not steal focus.

Naming target:
<Drive Label> · <Capture Date/Time>

Optional mutable user label is organization metadata only.
Immutable capture facts remain unchanged.

## 9. DRIVE IDENTITY / HISTORY

Target:
- strong automatic identity only with strong evidence;
- ambiguity surfaced for confirmation;
- never identify from display name/mount path alone;
- latest snapshot;
- paged history per physical drive;
- immutable capture facts;
- mutable organization metadata separate.

PHYSICAL_DRIVE_IDENTITY_AND_MOUNT_POLICY=ADR_REQUIRED

This ADR candidate includes:
- identity evidence tiers;
- stable vs ambiguous identity;
- remount reconciliation;
- eligible mounted drive;
- mount event handling;
- Auto Capture policy;
- confirmation behavior.

## 10. OFFLINE BROWSER

Target:
- explicit offline/history icon;
- OFFLINE SNAPSHOT;
- prominent capture timestamp;
- Name / Size / Modified;
- collapsible Inspector;
- source availability;
- classification display;
- Technical Details;
- normal branch expansion;
- Reveal in Tree;
- no global Expand All.

## 11. SEARCH

Target scope abstraction:
THIS_SNAPSHOT
THIS_DRIVE
THIS_LIBRARY

Search may cover:
filename/path
metadata filters
source/filesystem/date/status
classification

Must remain indexed/bounded.
Currently, the backend only implements bounded single-snapshot metadata search.

## 12. CLASSIFICATION

User wording:
Detected File Type

Disclosure:
Detected from a small file sample · Not content verification

Default UI hides:
provider
model
detector
provider identifier
byte budget
helper/process jargon

Technical Details may expose provenance.

Preserve existing P15 boundaries:
- capture stays metadata-only;
- explicit selected-entry current-source classification;
- Data-only provider;
- bounded bytes;
- append-only enrichment;
- no automatic whole-library classification;
- no snapshot/diff truth dependency.

No-match presentation (ADR-034, Accepted 2026-10-06):
- when an explicit classification completes with `noMatch`, the persistent
  inspector classification stays neutral/absent — "Not classified.";
- the current operation may state "No file type recognized." or the exact
  approved equivalent, as a bounded transient current-result message;
- it must never show "Failed", "Unavailable" or "Inferred file type: Unknown"
  for a `noMatch`;
- this message is not a persisted classification, invents no detected type and
  does not survive as historical classification truth;
- stale-result suppression on selection/snapshot/browser change is unchanged;
- no automatic classification, no new workflow and no bulk action is added;
- implementation is pending and is owned by the runtime implementation task,
  not by this specification.

## 13. COMPARE

Canonical:
LEFT=BEFORE/REFERENCE
RIGHT=AFTER/CHANGED

Added = present Right, absent Left.

Target:
- hero result counts;
- synchronized dual hierarchy;
- explicit missing side;
- filters;
- next/previous differences;
- click category → filter → locate → expand ancestors → scroll → select;
- Before/After metadata;
- color never only signal.

## 14. COMPARISON PERSISTENCE

CURRENT:
snapshot/snapshot comparison persists;
live-side comparison is workspace-scoped and transient evidence is disposed.

OWNER_TARGET:
easy durable comparison reopening, preferably automatic.

DURABLE_LIVE_COMPARISON_SEMANTICS=ADR_REQUIRED

Explicit options:
A. demo only promises durable snapshot/snapshot comparisons;
B. promote live inputs into durable snapshots;
C. introduce another durable comparison/evidence lifecycle.

## 15. LIBRARY / BACKUP / MULTI-MACHINE

Direction only:
future Library may contain drives/snapshots/comparisons/Drive Sets/search data.

Multiple Libraries, automatic backup/restore and cross-machine sync are not demo-critical.

Explicit:
DO NOT sync a live/open SQLite catalog by simply putting it in Google Drive.

## 16. BACKEND CONTRACTS TO PRESERVE

Record narrow/testable UX-facing seams:

HOME:
bounded aggregates
recent captures
recent durable comparisons
mounted drives
active capture state/progress

DRIVE IDENTITY:
strong identity
ambiguity/confidence
physical label separate from mount/display name

HISTORY:
latest lookup
paged history per drive
immutable capture facts
mutable organization metadata separate

BROWSER:
lazy paged children
selected details
ancestor lookup / Reveal in Tree
source online/offline state

SEARCH:
indexed bounded paging
explicit SearchScope abstraction
avoid snapshot-only coupling in future interfaces

CLASSIFICATION:
Data-only bounded input
append-only results
provider/detector/model provenance separate
latest + history
never diff/snapshot truth

COMPARE:
summary counts
paged relative hierarchy
Before/After orientation
counterpart state
ancestor-chain lookup
next/previous across pages
filters
immutable terminal evidence

ORGANIZATION:
future Drive Set direction must remain separate from capture truth.

These contracts are architecture constraints, NOT instructions to implement all APIs.

## 17. CURRENT BACKEND ALIGNMENT

SUPPORTED:
- absolute read-only / metadata-only capture foundation;
- immutable completed snapshot lifecycle;
- interrupted/partial semantics;
- offline SQLite history/browse;
- lazy direct-child tree;
- selected-entry inspector;
- capture progress + cancellation;
- snapshot/snapshot comparison persistence;
- Left/Before Right/After orientation;
- comparison result counts;
- filters;
- Before/After metadata;
- bounded comparison paging;
- deterministic next/previous cross-page;
- classification append-only storage/latest/history/presentation foundation.

PARTIAL:
- explicit offline browser state exists but target visual treatment needs redesign;
- capture inline progress exists but no connected-drive UX or auto-open completion;
- capture/display name fields exist but target naming/edit UX is incomplete;
- identity has UUID/fallback foundations but not complete strong/ambiguous service;
- recent captures/comparisons have repository data but no dashboard facade;
- search supports bounded one-snapshot metadata queries but not scope abstraction;
- classification UI can display stored result but real runtime absent;
- compare navigation can locate filtered results but lacks ancestor/hierarchy projection.

GAPS:
- real local classifier runtime;
- schema v9 provider_identifier;
- Data-only classification request;
- mount detection/watcher;
- optional Auto Capture;
- strong physical volume identity service;
- paged per-drive history/latest facade;
- bounded dashboard aggregates;
- This Drive / This Library search;
- classification search/filter;
- comparison hierarchy/ancestor projection;
- category click → tree reveal chain;
- Drive Set implementation;
- durable live-comparison retention;
- multi-Library/backup/cloud;
- manual rendered-window/VoiceOver/focus acceptance.

## 18. OPEN ADR CANDIDATES

ADR_REQUIRED:
1. PHYSICAL_DRIVE_IDENTITY_AND_MOUNT_POLICY
2. DRIVE_SET_SEMANTICS_VS_EXISTING_COLLECTIONS
3. DURABLE_LIVE_COMPARISON_SEMANTICS

## 19. BACKEND / UX DEPENDENCY MAP

OWNER UX DIRECTION
├─ TRACK A: OPENDESIGN
│  ├─ Home / Library Dashboard
│  ├─ Offline Snapshot Browser
│  ├─ Capture Active
│  ├─ Compare / Differences
│  └─ Compare / Metadata Match
│
└─ TRACK B: BACKEND
   ├─ P15 runtime sequence
   │  ├─ Slice 01 schema v9/provider provenance
   │  ├─ Slice 02 Data-only bounded source authority
   │  ├─ Slice 03 helper host seam
   │  ├─ Slice 04 runtime orchestration
   │  ├─ Slice 05 explicit selected-entry UI only
   │  ├─ Slice 06 regression matrix
   │  ├─ Slice 07 external classifier verification
   │  ├─ real helper integration + audit
   │  └─ Slice 08 whole-runtime verification
   │
   ├─ ADR: physical drive identity + mount policy
   │  └─ mounted-source observer / Connected Now / Auto Capture / This Drive search
   │
   ├─ compare navigation backend
   │  └─ hierarchy + ancestor-chain + Reveal exact result
   │
   ├─ bounded dashboard queries
   │  └─ aggregates + recent captures + durable comparisons
   │
   ├─ snapshot history facade
   │  └─ latest + paged per-drive history
   │
   └─ search scope abstraction
      ├─ snapshot existing
      ├─ drive after identity ADR
      └─ library + classification when supporting indexes/runtime exist

## 20. DEMO CRITICAL PATH

DEMO_CRITICAL:
- mounted-drive detection / Connected Now;
- real explicit selected-entry classifier;
- jump-to-exact-difference with ancestor reveal.

Already strong foundations:
- metadata capture;
- offline browse;
- snapshot history;
- comparison truth;
- result counts;
- Before/After detail;
- next/previous difference.

## 21. NON-GOALS FOR FIRST DEMO

Do not delay first coherent demo for:
HTML report
embedded ext reader
physical raw auth
polished Drive Set management
cloud sync
multi-Library UI
custom columns
global Expand All
bulk classification
NAS/network
decorative analytics.

THIS_DOCUMENT_DOES_NOT_AUTHORIZE_IMPLEMENTATION.
