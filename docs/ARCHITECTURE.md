# System Architecture

## 1. Component overview

```text
┌──────────────────────────────────────────────────────────────┐
│                         App Shell                            │
│ SwiftUI navigation, toolbar, settings, status, inspectors   │
└───────────────────────┬──────────────────────────────────────┘
                        │
          ┌─────────────┴─────────────┐
          │                           │
┌─────────▼─────────┐       ┌─────────▼─────────┐
│ Snapshot Browser  │       │ Compare Workspace │
│ NSOutlineView     │       │ dual NSOutlineView│
└─────────┬─────────┘       └─────────┬─────────┘
          │                           │
          └─────────────┬─────────────┘
                        │
               ┌────────▼────────┐
               │ Repository Layer │
               │ SQLite queries   │
               └────────┬────────┘
                        │
      ┌─────────────────┼──────────────────┐
      │                 │                  │
┌─────▼─────┐   ┌───────▼───────┐  ┌──────▼──────┐
│ Scanner   │   │ Diff Engine    │  │ Export Engine│
│ metadata  │   │ metadata trees │  │ JSON / HTML  │
└─────┬─────┘   └───────────────┘  └─────────────┘
      │
┌─────▼──────────────────────────────────────────┐
│ Filesystem Provider Layer                     │
│ NativeMountedProvider | EmbeddedRawProvider   │
│ (full contract: FILESYSTEM_PROVIDER_ARCHITECTURE.md) │
└─────┬──────────────────────────────────────────┘
      │
┌─────▼──────────────────────────────────────────┐
│ Volume Service                                │
│ NSWorkspace notifications + Disk Arbitration │
└────────────────────────────────────────────────┘
```

The Scanner consumes the Filesystem Provider Layer's contract and never talks to `FileManager`, a raw device, or a reader helper process directly — see [`FILESYSTEM_PROVIDER_ARCHITECTURE.md`](FILESYSTEM_PROVIDER_ARCHITECTURE.md) for the full contract, provider selection rule, authorization boundary, and reader helper process design. This document does not restate that content.

## 2. Modules

### AppShell

Responsibilities:

- window and navigation state;
- sidebar volume list;
- toolbar actions;
- settings and comparison profiles;
- expose user settings through native UI, never require JSON/config editing;
  persist runtime preferences in macOS preferences or the local application database;
- presentation of notifications and warnings.

### VolumeService

Responsibilities:

- observe mount and unmount events;
- resolve persistent identity;
- collect filesystem and capacity metadata;
- run `FilesystemDetector` (`FILESYSTEM_PROVIDER_ARCHITECTURE.md` §5) and select a provider per the deterministic fallback rule when a filesystem does not mount natively;
- queue eligible automatic captures;
- avoid duplicate simultaneous scans.

Suggested APIs:

```swift
protocol VolumeMonitoring {
    var events: AsyncStream<VolumeEvent> { get }
    func mountedVolumes() async throws -> [MountedVolume]
}
```

### SnapshotScanner

Responsibilities:

- enumerate a selected root **through the Filesystem Provider Layer's contract** — it never assumes a live `URL` exists for every item, since an embedded-raw entry has none (`FILESYSTEM_PROVIDER_ARCHITECTURE.md` §4);
- prefetch required URL resource keys (native provider only — the embedded-raw provider supplies its own metadata shape per `FILESYSTEM_SUPPORT_MATRIX.md`);
- normalize relative paths;
- create entry batches;
- track progress and errors;
- calculate subtree aggregates;
- commit or interrupt the snapshot.

Suggested scanner phases:

1. create `scanning` snapshot row;
2. enumerate entries;
3. batch insert raw entries;
4. calculate folder aggregates bottom-up;
5. compute metadata signatures;
6. write final totals;
7. mark snapshot `complete`.

### CatalogRepository

Responsibilities:

- SQLite lifecycle;
- migrations;
- prepared statements;
- batched writes;
- lazy child queries;
- search;
- snapshot and volume management;
- Collection management and source-collection default lookups (`SNAPSHOT_COLLECTIONS.md`) — purely catalog-layer metadata; no other module reads or writes `collections`/`source_collection_defaults` directly.

Database location (as implemented, Milestone 3 — ADR-026):

```text
~/Library/Application Support/FSD/catalog.sqlite3
```

resolved by `CatalogLocationResolver`, which honours `-FSDCatalogPath <path>` or `FSD_CATALOG_PATH` in DEBUG builds only, always isolates an XCTest host to its own catalog under the temporary directory, and prints the resolved path to standard error at startup. One process owns a catalog at a time, enforced by `CatalogProcessLock` before the catalog is opened (ADR-025).

Migrations (ADR-024): `schema.sql` creates a catalog at the current version and is never replayed against an existing one. An existing catalog moves forward only through a step in `CatalogMigrations.all`, whose statements and version row commit in one transaction. `verifyCurrentSchemaState()` checks the expected tables, triggers, indexes and columns on **every** open, so a version number is never taken as proof of a schema.

As implemented, the responsibilities above are split across `CatalogDatabase` (connection, pragmas, transactions, migrations), `SnapshotRepository` (lifecycle), `SnapshotWriter` (batched capture writes), `SnapshotHistoryRepository` (offline history and capture-time source facts, ADR-023), `SnapshotTreeDataSource` (bounded lazy child queries), and `MetadataSearchService` (bounded offline search). None of these touches the filesystem; `SourceAvailabilityProbe` is the single, explicitly optional exception, used only to label a snapshot's source as connected or offline.

Mandatory SQLite settings:

The database connection factory must apply all required per-connection pragmas before any query or transaction. `schema.sql`'s pragmas only apply to the connection running the script.

Database-persistent settings (apply once):
```sql
PRAGMA journal_mode = WAL;
```

Per-connection settings (must execute on every new connection):
```sql
PRAGMA foreign_keys = ON;
PRAGMA busy_timeout = 5000;
PRAGMA synchronous = NORMAL;
PRAGMA temp_store = MEMORY;
```

A debug assertion or startup verification must confirm `PRAGMA foreign_keys;` returns `1` before repositories are allowed to operate.

### TreeDiffEngine

Responsibilities:

- compare normalized nodes;
- classify results;
- skip equal subtrees using signatures;
- provide paged child results;
- generate summary counts.

Default equality tuple:

```text
normalized_relative_path + item_type + logical_size
```

As implemented (Milestone 4, `FSD/Diff/ComparisonEngine.swift`): the engine
compares one stored snapshot against another by merging keyset-paged,
`ORDER BY <key>, id` streams of both sides — never a materialized tree, so
memory is bounded by one page per side plus the current key group. The key is
`case_preserving_path` when both sources are case-sensitive and
`case_folded_path` otherwise (ADR-010), with byte-order key comparison
matching SQLite's BINARY collation. Outcomes are the exact schema names
`matched`/`added`/`removed`/`changed`/`ignored`/`uncertain`; `changed` rows
carry per-field `difference_flags`; case-fold collisions become `uncertain`
groups with explicit collision members, never arbitrary pairs; entries with
`is_inaccessible` on either side classify `uncertain`. The orientation is
canonical: left = reference ("before"), right = changed ("after") — `added`
means present only on the right (ADR-027). Subtree-signature skipping (the
"skip equal subtrees using signatures" responsibility above) is not yet
implemented; the engine produces per-entry rows, which also keeps the result
set deterministic and self-contained.

### ExportEngine

Responsibilities:

- snapshot JSON export;
- diff JSON export;
- self-contained HTML report;
- schema versioning;
- streaming output to avoid high memory use.

## 3. Concurrency model

Use Swift structured concurrency.

```text
MainActor
- UI state only

Scanner actor
- traversal coordination
- cancellation
- progress state

Database writer actor
- prepared statements
- transactions
- serialized writes

Diff task
- read-only SQLite connection
- cancellable background work
```

Avoid performing filesystem enumeration, database writes or diff calculation on the main actor.

## 4. Scan strategy

This section describes the `NativeMountedProvider` path (macOS already mounted the volume). The `EmbeddedRawProvider` path (ext2/ext3/ext4 only) has its own mechanics, defined once in [`FILESYSTEM_PROVIDER_ARCHITECTURE.md`](FILESYSTEM_PROVIDER_ARCHITECTURE.md) — not restated here.

### Required URL resource keys

- name;
- directory flag;
- regular file flag;
- symbolic link flag;
- package flag;
- logical size;
- allocated size;
- creation date;
- modification date;
- content type;
- resource identifier when available.

### Default behavior

- do not follow symbolic links;
- do not read payload bytes;
- do not create thumbnails;
- do not rely on Spotlight;
- continue after recoverable permission errors;
- cancel safely on eject.

### Batch size

Begin with 2,000 entries per SQLite transaction and benchmark 1,000–10,000.

## 5. Path normalization

Path representation defines both display identity and diff comparison keys:

- root entry uses an empty relative path;
- separator is `/`;
- `relative_path`: Unicode text representation provided by the filesystem, used for display and internal uniqueness.
- `case_preserving_path`: canonically normalized string (using the Foundation NFC normalizer algorithm) preserving original case.
- `case_folded_path`: canonically normalized and case-folded string (locale-independent case-folded).
- The algorithm/locale version (normalization version) used to produce these keys is stored with the snapshot.
- Avoid resolving symbolic link targets.

### 5.1 Collision and comparison rules

- If both sources are case-sensitive, the diff engine compares using `case_preserving_path`.
- If either source is case-insensitive, the diff engine compares using `case_folded_path`.
- If multiple entries on either side map to one selected comparison key (e.g. a case-folded collision), classify that group as `uncertain` and never pair them arbitrarily.
- Excessive or unrepresentable paths cause an error log for that entry and exclude it from standard comparison.
- Snapshots captured with different normalization versions cannot be compared. Mismatched versions explicitly block comparison with a compatibility error. Keys are not silently regenerated.

## 6. Aggregate signatures

For a file:

```text
metadata_signature = hash(item_type, normalized_name, logical_size)
```

For a folder:

```text
subtree_signature = hash(sorted child names, child types, child signatures)
```

These hashes summarize metadata only. They must never be presented as content checksums.

## 7. Failure handling

### Disconnect during capture

- cancellation signal from volume service;
- stop enumeration;
- commit already-recorded rows if safe;
- mark snapshot `interrupted`;
- preserve previous complete generation.

### Application crash

- WAL recovery restores committed transactions;
- any `scanning` snapshot found on launch becomes `interrupted`;
- incomplete snapshot remains excluded from default browsing and equality conclusions.

### Database migration failure

- back up catalog before migration;
- do not delete previous database automatically;
- show a recoverable error and diagnostic path.

As implemented (ADR-024): a migration's statements and its `schema_migrations` row commit in one transaction, so a failure rolls back completely and leaves the recorded version untouched — the catalog stays at the version it was, and the next open retries from that known state. The failure surfaces as `CatalogDatabaseError.migrationFailed(version, message)` naming both. Automatic pre-migration backup is **not** implemented and remains open.

## 8. Live comparison and Transient Snapshots

To support live folder/volume comparison seamlessly within the snapshot-backed diff engine:

- All diff comparisons strictly compare one snapshot ID to another.
- Live folders or live volumes are first captured using the standard scanner into a **transient snapshot**.
- Transient snapshots are identical in schema, atomicity, and constraints to user snapshots but are marked `snapshot_kind = 'transient'`.
- Transient captures that fail or are interrupted cannot be presented as complete comparison sources.
- Transient snapshots are excluded from standard capture history and user-facing lists.
- **Lifecycle:** Transient snapshots are automatically deleted from SQLite when the comparison session is closed, or cleaned up on application launch if abandoned during a crash. Promotion to a user snapshot may be offered in the future but is deferred.

## 9. Nullable enrichment boundary — `LocalFileClassificationProvider` (Phase 1.5 preparation)

This section is the binding boundary for the Phase 1.5 preparation slice.
`FSD/Catalog/EntryClassificationRepository.swift` implements the typed
`LocalFileClassificationProvider`, `DisabledFileClassificationProvider` and
explicit `ClassificationEnrichmentService` seam. Magika inference is not
implemented, installed or executed.

### Boundary rule

`LocalFileClassificationProvider` is a derived-enrichment boundary sitting
outside the MVP scanner → repository → diff → UI pipeline described in
Sections 1–8. It is not consulted by `SnapshotScanner`, `CatalogRepository`'s
MVP paths, `TreeDiffEngine`, or search/export. Metadata Match, comparison
classification, and snapshot completeness are computed with zero knowledge
that this interface exists.

The production protocol shape is:

```text
protocol LocalFileClassificationProvider {
    func classify(_ request: LocalClassificationRequest) throws -> LocalClassificationProviderResult
}

enum ClassificationResult {
    case notRequested
    case disabled
    case classified(detectedType, mimeType, confidence, detectorVersion, modelVersion)
    case failed
}
```

### Default implementation: `DisabledFileClassificationProvider`

The only built-in provider in this slice is a disabled/no-op default. It must:

- perform no filesystem access;
- receive no payload bytes;
- open no files;
- read no byte ranges;
- compute no hashes;
- schedule no background work;
- produce no database rows when explicitly queried through the enrichment service;
- produce no UI state;
- produce no diff input;
- return `.disabled` (or `.notRequested`) only when explicitly queried, and otherwise do nothing;
- have effectively zero runtime cost while unused — no allocation, no thread, no I/O on the MVP's hot paths.

The MVP scanner remains fully functional without a provider. Capture, history
open, tree browsing, search, export and comparison never invoke the enrichment
service and remain payload-free.

### Future Phase 1.5 constraints (binding on any later real implementation)

- fully offline operation, no network access;
- only bounded byte-range reads, never full-file reads and never full-file hashing;
- no sampled-byte persistence — bytes read for classification are never written to storage;
- no modification of the source volume;
- append-only/versioned results through the repository API (see `entry_classifications` in `database/schema.sql`) — a later run never rewrites or reinterprets an earlier run's stored result;
- detector and model versions are recorded with every result and remain traceable;
- classification never mutates immutable snapshot metadata (`entries`, `snapshots` aggregate fields) and never alters a historical Metadata Match or diff conclusion, past or future;
- classification failure never changes a snapshot's `complete`/`interrupted`/`failed` status.

## 9a. Future Magika Runtime (Not Yet Implemented)

This section documents the resolved design for the future Phase 1.5 Magika runtime adapter. **This is a design constraint only; the runtime is not yet built.**

### Architecture and Packaging

The Magika file-type enrichment adapter packaging was evaluated across four shapes:

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

### Source Resolution and Identity

Before any classification read, the adapter MUST:
1. Re-resolve the live path from the entry's stored relative path against the currently attached source.
2. Positively confirm the live item is a regular file. Directory, symlink, and special-file entries always resolve to `.unsupported-entry` without reading bytes.
3. Forbid following any symlink beyond the entry's recorded target.
4. Forbid recursing into a directory.
5. If the source is detached or changed identity, return `.source-changed` or `.unavailable`.

The stored classification represents time-of-classification metadata about currently-attached bytes. It is NEVER retroactive proof of the immutable snapshot's content.

### Bounded Byte Contract

The runtime operates strictly on bounded byte reads:
1. The byte-ceiling is `4096` bytes (PROPOSED). The accounting definition: the ceiling bounds the single prefix read from the resolved live file; nothing else — no directory-listing bytes, no metadata bytes — counts against it.
2. Range count is exactly `1` single prefix range. No tail reads and no adaptive additional reads (PROPOSED).
3. The read layer concurrency is `1` (single classification at a time) (PROPOSED).
4. **Bytes read for classification are never persisted, never hashed, never logged to any diagnostic surface, in any outcome.**
5. The provider-facing request will carry only a bounded `Data` (or equivalent already-read byte buffer) — no `URL`, no path, no file handle. (The `LocalClassificationRequest.sourceURL` property is flagged for removal before this is implemented).
6. Small-file behavior: a file smaller than the ceiling is read in full (its actual size), not padded or treated as an error.
7. Large-file behavior: only the first `4096` bytes are ever read; the rest of the file is never touched.
8. Unreadable files: disappearing-source, inaccessible-source, directory, symlink, and special-file outcomes are handled exactly as defined in the "Source Resolution and Identity" subsection.
9. The exact pipeline is: FSD source resolution → FSD source identity validation → FSD bounded reader → bounded bytes → provider → typed result. The provider receives no `URL`, path, or file handle at any stage.
10. The `LocalClassificationProviderResult` enum currently contains three cases (`classified`, `unavailable`, `failed`). Against the six required outcomes (success, unavailable, failed, cancelled, source-changed, unsupported-entry), there are three currently missing from the live enum: `cancelled`, `source-changed`, and `unsupported-entry`.
11. No production protocol change is implemented in this design correction slice.

### Lifecycle and Cancellation

1. Concurrency: exactly `1` classification in flight at a time (PROPOSED). Kept as it strictly bounds resource contention.
2. Trigger scope: single selected-entry action only (PROPOSED). Kept to avoid unintentional background load. The following workflows must **never** trigger classification automatically: capture, application launch, history open, snapshot reopen, browsing, search, comparison, JSON export.
3. Inference timeout: `5` seconds (PROPOSED). Kept as a reasonable UX bound for a single file.
4. Memory high-water delta: `2x` the byte ceiling (8192 bytes) (PROPOSED). Kept for strict memory budgeting.
5. Queue/backpressure: no queue in the first implementation. A second request is rejected if one is in flight (PROPOSED). Kept to ensure simplicity and single-action UI.
6. UI latency expectation: show progress/cancel affordance after `0.5` seconds (PROPOSED). Kept for responsive feedback.
7. Cancellation mechanism: The cancellation contract reuses the existing `generation`/`invalidate()` idiom implemented in `SnapshotTreeDataSource.swift`.

**Cancellation Persistence:**
- Evidence: The `detection_status` enum supports only `not_requested`, `disabled`, `classified`, and `failed`. `EntryClassificationRepository` enforces strict append-only semantics with duplicate-run-rejection via a `UNIQUE(entry_id, classification_run_id)` constraint. `SnapshotBrowserView.swift` handles the absence of a row cleanly with a "Not classified" neutral state.
- Decision: `runtime-only` (no row). Appending a dummy row for every cancellation wastes space, and missing rows are already handled correctly by the UI as neutral absence.
Append-only semantics and `(entry_id, classification_run_id)` duplicate-rejection are unconditionally preserved.

### Outcomes and Schema Impact

There are exactly **six** outcomes:
1. `success/classified`: Row written with `classified` status.
2. `failed`: Row written with `failed` status.
3. `source-changed`: Row written with `failed` status.
4. `unsupported-entry`: Row written with `failed` status.
5. `unavailable`: No row written.
6. `cancelled`: No row written (runtime-only).

**Schema Verdict:**
1. What does `detector_version` identify? Per `EntryClassificationRepository.swift` and ADR-031, it identifies the detection algorithm version, serving as one of the explicitly "persisted provenance fields".
2. What does `model_version` identify? Per the same sources, it identifies the model version used, serving as the other explicit "persisted provenance field".
3. What independent fact does provider/adapter identity represent, and how is it different from both of the above? Provider/adapter identity represents which packaging shape or process produced the row (e.g., a locally bundled helper executable). This is a distinct dimension because the same detector/model version can run under different packaging shapes over the adapter's lifetime.
4. Why must those three facts remain separately, durably recoverable rather than merged into one field? A future reader needs to answer "which detector version produced this row" and "which adapter produced this row" as two independent questions, without depending on an undocumented, unenforced string convention to disentangle them.
5. Can schema v8 — as it actually exists today, not as a hypothetical encoding convention — represent all three facts without semantic overloading? No. The real column list in `schema.sql` provides only `detector_version` and `model_version`, meaning the adapter identifier remains "runtime-only" without semantic overloading.

Conclusion: `SCHEMA CHANGE REQUIRED BEFORE RUNTIME`.
Exactly one minimal missing field, `provider_identifier`, is required to record which adapter/process produced the row, independent of the algorithm and model versions. `detector_version` must not be overloaded to carry this fact because it would merge two orthogonal facts, forcing future queries to rely on an undocumented string convention to disentangle "which adapter" from "which detector".

### UI Contract

For the future runtime, classification must be presented as inferred metadata, never as content verification. The UI must follow the established pattern in `SnapshotBrowserView.swift`:
- Absence of classification is presented as a neutral state ("Not classified" or equivalent), never fabricated as an error.
- Confidence is shown only when actually present in the data, never fabricated.
- No raw provider diagnostic, stack trace, or internal path ever reaches visible text.
