OWNER_PRODUCT_UX_DIRECTION=YES
IMPLEMENTATION_PROOF=TASK047_MAIN_HOME|TASK048_MAIN_POLISH|TASK049_OFFLINE_EXPLORE|TASK050_EXPLORE_POLISH|TASK051_COLLECTIONS_ORGANIZER|TASK052_LABEL_NOTE_EDITOR|PHASE_1_5_RUNTIME_ACCEPTED
IMPLEMENTATION_AUTHORIZATION=HISTORICAL_TASKS_ONLY;NO_PRODUCT_IMPLEMENTATION_AUTHORIZED_BY_THIS_DOCUMENT
WAVE_A_ADR_STATUS=PROPOSED;OWNER_DIRECTION_APPROVED;TECHNICAL_PROOF_PENDING;BRAIN_REVIEW_PENDING

# UX and UI Specification

This document defines the canonical Owner Product/UX Direction for FSD.

The accepted implementation baseline and open implementation gaps are recorded
in [PRODUCT_STATE.md](PRODUCT_STATE.md). Tasks 047–052 are accepted bounded
product slices, not FSD2 Full acceptance. The Owner approved the Wave A target
direction on 2026-10-18; ADR-036–038 in [DECISIONS.md](DECISIONS.md) remain
proposed pending technical proof and BRAIN review. This document does not
authorize implementation.

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

### 5.1 Owner-approved Main/Home implementation — Task047

Owner approved **Direction A — Source Navigator** for the FSD Main/Home screen.
Task047 implements that screen only; this approval does not mean the remaining
Direction A screens or product-wide Stage1 work are complete.

The implemented Main/Home contract is:

- Keep the native persistent sidebar, with Home as the launch destination and
  clear selection state. Preserve the existing Recent Captures, Comparisons and
  manual Capture routes.
- Read saved capture context from `ApplicationModel.history`, backed by the
  persisted snapshot catalog. Select by stable `SnapshotID`; identical display
  names remain separate catalog records and are never merged by label or path.
- Show the capture-time source label when recorded, otherwise say it was not
  recorded at capture time. Show the snapshot ID, capture timestamp, truthful
  status, and persisted file, folder, inaccessible-item and warning counts.
- State that live source identity and original-source connection are unverified.
  Do not use mount-path existence as proof of a connected physical drive.
- Keep the primary Browse Snapshot action attached to the selected completed
  snapshot and open the existing stored-metadata browser. A partial capture is
  marked partial and is not presented as the last complete snapshot. Selecting
  a capture changes context only; it does not open a content preview.
- Provide actual actions to open Recent Captures history, the existing Compare
  workspace, and the existing explicit manual Capture flow. Compare source
  selection remains inside that workspace.
- For an empty catalog, explain how to start a manual metadata capture. Show
  catalog/startup failures as unavailable rather than inventing empty counts.
  The Home content uses a vertical scroll surface to retain the source heading,
  primary action and sidebar at supported window widths.

The Main/Home screen does **not** implement the rest of Direction A. Tasks049
and 050 subsequently delivered the bounded Offline Snapshot Explore workspace
and its polish; Tasks051 and 052 added the Snapshot Collections organizer and
snapshot label/note editor. These accepted slices still do not complete
Direction A or FSD2 Full. Mount detection/Connected Now, Auto Capture,
dashboard aggregates, paged per-drive history, broader search scopes, and
compare ancestor/reveal navigation remain gaps. Physical-drive identity and
mount/remount behavior have Owner-approved target direction but still lack a
validated evidence/ambiguity contract and identity-aware availability service.
Until that proof is accepted, no physical-drive identity or connection is
asserted from a recorded display name or mount path. Collection semantics stay
unchanged; Drive Sets have a separate proposed ADR-037, not an accepted
implementation.

### 5.2 Owner-authorized Offline Snapshot Explore slice — Task049

Task049 reuses the stored snapshot history, `SnapshotBrowserModel`, paged
`SnapshotTreeDataSource`, AppKit outline, selected-entry inspector and bounded
`MetadataSearchService`. The route remains Home → Browse Snapshot → Recent
Captures / Explore. Each workspace identifies its stable SnapshotID, capture-
time source label, capture timestamp and complete/partial status. Its context
states that browsing is read-only and uses stored metadata, and that current
source connection and physical identity are unverified. Explore does not use
mount-path existence to assert connection.

Search is explicitly **THIS SNAPSHOT** and carries that exact SnapshotID through
the existing bounded metadata query. Its result state distinguishes no matches,
query failure, a truncated result set and a cleared query. Selecting a result
updates the inspector; the tree remains where it was because Reveal in Tree is
not implemented. Search does not inspect payload bytes or span snapshots,
drives or a Library.

The existing lazy outline retains direct-child paging, retry, stable row
identity, bounded caches and eviction. The inspector remains optional and can
collapse without clearing its selected metadata. Classification remains an
explicit inspector action. No schema, capture facts, comparison evidence,
Home semantics or physical-drive identity behavior changes in this slice.

### 5.3 Owner-authorized Snapshot Collections organizer slice — Task051

Task051 implements the first bounded Stage1 Collections vertical slice on top of
the existing schema version 9 `collections` table and `snapshots.collection_id`
field. It adds one new destination, **Collections**, reachable from the sidebar
alongside Home, Recent Captures, Comparisons and Capture.

The implemented contract is:

- A Collection is catalog metadata only: a user-defined logical grouping of
  saved user captures. It is never a folder on a source volume and never mutates
  snapshot contents, entry rows, aggregates, capture timestamps, `session_number`
  or any source-identity field.
- "Unsorted" is never a stored Collection row. It is `collection_id IS NULL`,
  rendered as Unsorted in the UI only. A missing Collection is never invented.
- The sidebar lists All Captures, Unsorted (with live counts) and each Collection
  in deterministic normalized-name order. Each row shows its bounded snapshot
  count and the selected grouping is clearly indicated.
- The snapshot pane lists saved user captures newest-first, bounded with an
  explicit truncation indicator. Membership is carried by stable `SnapshotID`
  and Collection id only; display names, source labels and mount paths are never
  used to infer a Collection. Identical display names remain distinct records.
- A snapshot is moved into a Collection, or back to Unsorted, through an
  explicit Move control attached to the selected snapshot. Moving updates only
  `snapshots.collection_id`; the database trigger advances the target
  Collection's `last_used_at`. It never deletes a snapshot.
- Creating a Collection trims the name, rejects a blank name, and rejects a name
  whose normalized form (ADR-009/ADR-019 NFC + locale-independent case fold)
  already exists rather than silently creating a case/Unicode near-duplicate.
- Transient comparison snapshots are excluded from every list and rejected for
  assignment; only saved user captures can be organized.
- Organizing works fully offline: it reads and writes the catalog and never
  accesses a source, a mount path or a provider. A capture stays in its
  Collection when its original source is disconnected, erased or never
  reconnected, and its physical identity is never asserted from the grouping.
- Catalog read/write failures are surfaced as bounded user-facing text; raw
  SQLite text, internal table names and paths are never shown, and a read
  failure is never presented as an empty Collections list.

At Task051 closeout, the following were deferred. Task052 subsequently added
snapshot display-name and user-note editing; that does not change Collection
semantics. Still not implemented: renaming or deleting a Collection; the
capture-time organization sheet; a remembered default Collection and
`source_collection_defaults` writes; mount detection and Auto Capture; Drive
Sets; physical source identity; library-wide search; content preview and
automatic classification; and any schema, migration, or comparison-engine
change. The current FSD2 Full target and Wave A ADR status are summarized in
§§6–14 and [PRODUCT_STATE.md](PRODUCT_STATE.md).

### 5.4 Owner-authorized snapshot label and note editor — Task052

Task052 adds a compact **Edit Label & Note** sheet to the existing Collections
organizer. The editor loads and saves the existing schema version 9
`snapshots.display_name` and nullable `snapshots.user_note` fields by stable
`SnapshotID`. It accepts duplicate labels, rejects blank labels, and limits
labels to 120 and notes to 2,000 Swift characters (`String.count`, extended
grapheme clusters). Labels are stored exactly as entered; clearing the note
stores `NULL`. A failed write keeps the sheet and its draft open.

Only those two snapshot columns are updated. The SnapshotID, Collection
membership, capture-time source label, source identity, capture timestamps,
`session_number`, lifecycle state, entries, aggregates and comparison evidence
remain unchanged. The note is shown as **User note** so it cannot be mistaken
for a capture-time fact. Home and Recent Captures refresh their cached history
when visited, and a successful save refreshes the app-scoped history model.

The Empty Reel instruction directs users to All Snapshots or Unsorted before
moving a capture into the empty Collection. Source access, classification,
schema changes and wider Collections redesign remain outside this slice.

## 6. DRIVE SET DIRECTION

A Drive Set is a user-created group of PHYSICAL DRIVES.

WAVE_A_STATUS=OWNER_DIRECTION_APPROVED;ADR_037_PROPOSED;TECHNICAL_PROOF_PENDING

Drive Sets group stable local PhysicalDrive IDs and are separate from logical
snapshot Collections. The proposed membership is many-to-many. Existing
Collection semantics remain binding: a snapshot belongs to zero or one
Collection, `Unsorted` remains `collection_id = NULL`, and Collections are not
renamed or reinterpreted as Drive Sets. No existing membership is inferred.
Create, rename, delete, membership changes, offline presentation, and ambiguous
identity behavior are specified as a candidate in ADR-037; exact storage and
migration mechanics remain pending proof.

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
- Auto Capture setting, OFF by default;
- inline progress;
- rest of app remains usable;
- manual completion opens snapshot;
- auto completion does not steal focus.

The mount observer is observation-only: it does not mount, unmount, eject, or
read file payloads. A mount event alone cannot start capture work. A separate
capture policy may start work only after explicit Auto Capture opt-in and a
uniquely resolved, policy-eligible source; unknown, ambiguous, or conflicting
identity evidence fails closed. See proposed ADR-036; its evidence threshold
and hardware behavior remain `TECHNICAL_PROOF_PENDING`.

Naming target:
<Drive Label> · <Capture Date/Time>

Optional mutable user label is organization metadata only.
Immutable capture facts remain unchanged.

## 9. DRIVE IDENTITY / HISTORY

Target:
- strong automatic identity only with strong evidence;
- ambiguity surfaced for confirmation;
- never identify from display name, mount path, BSD node, or one unverified UUID;
- latest snapshot;
- paged history per physical drive;
- immutable capture facts;
- mutable organization metadata separate.

WAVE_A_STATUS=OWNER_DIRECTION_APPROVED;ADR_036_PROPOSED;TECHNICAL_PROOF_PENDING

The target distinguishes `PhysicalDrive`, `Volume/Partition`, `MountSession`,
and immutable capture-time source facts. Only a unique match that satisfies a
validated multi-evidence policy may reconnect automatically. Ambiguous,
unknown, and conflicting evidence stays unassociated until an explicit user
decision. Manual associations are local and do not rewrite capture facts or
silently merge histories. The complete candidate contract and negative-test
gates are in ADR-036; exact evidence classes and thresholds remain pending.

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

**Current status:** Phase 1.5 runtime is BRAIN-accepted and technically closed
in the accepted State projection. The runtime remains explicit selected-entry
work; historical documents that say its final audit or acceptance is pending
are stale. This does not claim manual VoiceOver, physical-media, or full FSD2
Full internal acceptance.

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
- the no-match semantics remain binding under ADR-034. Their implementation
  is part of the BRAIN-accepted Phase 1.5 runtime, not a pending implementation.

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

CURRENT IMPLEMENTATION:
snapshot/snapshot comparison persists; live-side comparison uses transient
snapshots and comparison state that is disposed when the workspace closes or
abandoned transients are cleaned during recovery. This remains the default
behavior for unsaved work. Task063 adds the explicit Save action and the separate
Saved Comparisons destination subsection over schema v13; it never auto-saves.

OWNER DIRECTION APPROVED (2026-10-18):
the user explicitly chooses **Save Comparison** to retain a live comparison.
Saved comparisons reopen offline from durable, metadata-only backing evidence.
No live comparison is saved automatically, and an unsaved comparison keeps the
current transient lifecycle.

WAVE_A_STATUS=ADR_038_PROPOSED;TECHNICAL_PROOF_PENDING;BRAIN_REVIEW_PENDING

The saved artifact must use separate durable backing evidence for transient
live inputs. It must not update a completed transient snapshot into a user
snapshot: schema v9 protects `snapshot_kind` as an immutable capture fact.
Reference integrity, all-or-nothing save, recovery, cleanup, idempotency,
failure behavior, and bounded large-tree handling are candidate requirements in
ADR-038. Exact copying/cloning, reference remapping, schema, and migration
mechanics remain `TECHNICAL_PROOF_PENDING`; ADR-012 and ADR-028 remain binding.

Task056 candidate: a dedicated saved artifact with separate copies of both
sides' metadata, results and completion-time profile/evidence receipt is
preferred for further review. This is a feasibility recommendation, not an
implemented Save action or a final accepted schema. Saved evidence is browsed
under its own stable IDs, with original left/reference and right/changed
orientation and Content Not Verified disclosure; it does not create ordinary
user captures, change Collections or depend on physical-drive verification.

Save eligibility must require a complete evidence closure and a trustworthy
completion receipt. Schema-v9 comparisons without that receipt cannot be
silently upgraded from current mutable profile/header values. No rescan or
historical backfill supplies missing truth. Pending save work is never shown
as saved; failure/cancellation preserves the workspace. After an uncertain
acknowledgement, retry the same operation ID; deleting a saved artifact is
explicit and never deletes ordinary captures or shared evidence still in use.
The current application has none of this new Save/reopen flow. Production
receipt creation, UI, copy limits and real crash/recovery proof remain pending.

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

STATUS BASIS: accepted Task047–052 work and final Phase 1.5 runtime acceptance
are recorded in [PRODUCT_STATE.md](PRODUCT_STATE.md) and
`STATE/PROJECT_STATE.md`. This is a current implementation summary; it does
not promote a target or a proposed ADR to Accepted.

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
- explicit selected-entry classification runtime and accepted filetype provider;
- Main/Home, offline Explore, Snapshot Collections organizer, and snapshot
  label/note editor slices from Tasks047–052.

PARTIAL:
- capture inline progress exists but there is no mounted-drive observer or
  Auto Capture flow;
- snapshot Collections create/list/move and label/note controls exist, but the
  full capture-organization/default-Collection semantics are incomplete;
- identity has UUID/fallback foundations but no validated strong/ambiguous
  PhysicalDrive resolver;
- recent captures/comparisons have repository data but no dashboard facade;
- search supports bounded one-snapshot metadata queries but not scope abstraction;
- compare navigation can locate filtered results but lacks ancestor/hierarchy projection.

GAPS:
- observation-only mount detection;
- opt-in Auto Capture, default OFF;
- multi-evidence PhysicalDrive identity resolution and manual association;
- per-PhysicalDrive history and paged service;
- Drive Sets with physical-drive membership;
- bounded dashboard aggregates;
- This Drive / This Library search;
- classification search/filter;
- comparison hierarchy/ancestor projection;
- explicit Save Comparison and separate durable backing evidence for live inputs;
- category click → tree reveal chain;
- multi-Library/backup/cloud;
- manual rendered-window/VoiceOver/focus acceptance.

## 18. OPEN ADR CANDIDATES

| Candidate | Owner direction | Current status |
|---|---|---|
| ADR-036 Physical Drive Identity and Mount Policy | Multi-evidence, fail-closed identity; Auto Capture OFF by default | Proposed; technical proof pending; BRAIN review pending |
| ADR-037 Drive Sets vs Snapshot Collections | Separate physical-drive grouping; proposed many-to-many membership | Proposed; technical proof pending; BRAIN review pending |
| ADR-038 Durable Live Comparison | Explicit Save Comparison with separate durable captured backing evidence | Proposed; technical proof pending; BRAIN review pending |

These candidates do not authorize product, schema, migration, watcher, or
automatic-capture implementation.

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
   ├─ P15 runtime sequence — BRAIN-accepted and technically closed
   │  └─ Explicit selected-entry classification remains metadata enrichment,
   │     not capture or comparison truth
   ├─ Wave A proposed ADRs — no implementation authorized by this spec
   │  ├─ ADR-036 identity/mount policy → observation-only mount status/history
   │  ├─ ADR-037 Drive Sets → stable PhysicalDrive IDs, separate from Collections
   │  └─ ADR-038 Save Comparison → separate durable evidence and offline reopen
   │
   ├─ ADR-036 proof gate: physical-drive identity + observation-only mount policy
   │  └─ Connected Now / per-drive history / eligible opt-in Auto Capture / This Drive search
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

These are first-demo deferrals, not removals from FSD2 Full or the historical
PRD/MVP requirement set. Scope dispositions remain explicit in
[MVP_PLAN.md](MVP_PLAN.md).

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

THIS_DOCUMENT_RECORDS_OWNER_PRODUCT_DIRECTION_AND_ACCEPTED_TASK047_052_SLICES.
FSD2_FULL_TARGET=SECTIONS_6_TO_14;WAVE_A_ADRS=PROPOSED_ONLY.
IT_DOES_NOT_AUTHORIZE_PRODUCT_IMPLEMENTATION_OR_CHANGE_ACCEPTED_ADR_SEMANTICS.

### Task063 implemented persistence presentation (Worker evidence)

Save Comparison is visible in the completed workspace with receipt eligibility,
busy/cancel/retry/error/success states and Command-S. Ineligible comparisons show
a reason. Cancel Save and Close waits for transaction settlement before disposal.
Recent Comparisons are explicitly described as potentially temporary work.
Saved Comparisons lists durable artifacts, supports reload/paging/offline opening,
and confirms deletion with the exact artifact ID. A deleted completion needs the
separate Save Again as New confirmation; retry never resurrects it.

Offline detail presents frozen profile/revision/completion/counts/warnings,
Content Not Verified, paged Results/Left/Right/Issues/Collisions/Members and selected
typed metadata. LEFT is Before/Reference; RIGHT is After/Changed. Missing linked
entries stay missing; collisions stay unpaired. This is a paged metadata/detail
view, not a new hierarchical diff or ancestor-reveal implementation. Manual
VoiceOver and Owner visual acceptance remain pending; ADR statuses are unchanged.
