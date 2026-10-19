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

Target responsibilities (not an implemented identity/mount service; ADR-036
remains Proposed / Technical Proof Pending):

- observe mount and unmount events;
- resolve identity only under ADR-036's evidence gates; current real strong-match
  profiles are empty (see §11);
- collect filesystem and capacity metadata;
- run `FilesystemDetector` (`FILESYSTEM_PROVIDER_ARCHITECTURE.md` §5) and select a provider per the deterministic fallback rule when a filesystem does not mount natively;
- queue eligible automatic captures;
- avoid duplicate simultaneous scans.

Suggested APIs, not current runtime interfaces:

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
- **Lifecycle:** Workspace close disposes live-side comparisons before cleaning
  unreferenced transients. Startup marks orphaned running comparisons failed and
  removes only unreferenced transients; referenced evidence remains protected.
  Completed transient `snapshot_kind` cannot be promoted in place. Proposed
  ADR-038 explicit Save creates separate durable metadata evidence; it preserves
  this default unsaved lifecycle and remains technical-proof-pending. See §13.

## 9. Nullable enrichment boundary — `LocalFileClassificationProvider` (implemented Phase 1.5 runtime)

This section is the binding derived-enrichment boundary.
`FSD/Classification/LocalFileClassificationProvider.swift` owns the Data-only protocol and disabled provider; `ClassificationRuntimeService` owns explicit single-flight orchestration; `FSD/Catalog/EntryClassificationRepository.swift` owns append-only persistence. filetype v1.1.3 is the BRAIN-accepted production provider; ADR-035 integration is implemented by task033A (`556872844b90640cc2a64e40d99594a78cef61af`) and independently audited by task034 (accepted `PASS_WITH_ADVISORY` at publication `9d1a8ea237c6c2941895b1c3640118371d2e2d4d`). Task035 verified the runtime; Task036 subsequently completed the independent final audit and BRAIN accepted Phase 1.5 with advisory (see [STATE/PROJECT_STATE.md](../STATE/PROJECT_STATE.md)). This is historical acceptance evidence, not a Task054 rerun; manual and FSD2 Full internal acceptance remain separate.

### Boundary rule

`LocalFileClassificationProvider` is a derived-enrichment boundary sitting
outside the MVP scanner → repository → diff → UI pipeline described in
Sections 1–8. It is not consulted by `SnapshotScanner`, `CatalogRepository`'s
MVP paths, `TreeDiffEngine`, or search/export. Metadata Match, comparison
classification, and snapshot completeness are computed with zero knowledge
that this interface exists.

The verified production protocol is async, cancellation-aware and `Sendable`. Its only request field is immutable `Data`, capped by FSD at 4096 bytes; provider identifier, detector version and model version are independent protocol properties. The exact typed outcomes are `classified`, `failed`, `sourceChanged`, `unsupportedEntry`, `unavailable`, `cancelled`, `noMatch`; `busy` is runtime admission state only.

### Default implementation: `DisabledFileClassificationProvider`

The disabled/no-op provider remains available for explicit callers. The production selected-entry action constructs `BundledFiletypeClassificationProvider`; ordinary workflows invoke neither. The disabled provider must:

- perform no filesystem access;
- never inspect its bounded request bytes;
- open no files;
- read no byte ranges;
- compute no hashes;
- schedule no background work;
- produce no database rows when explicitly queried through the enrichment service;
- produce no UI state;
- produce no diff input;
- return `.unavailable` without a row when explicitly queried, and otherwise do nothing;
- have effectively zero runtime cost while unused — no allocation, no thread, no I/O on the MVP's hot paths.

The MVP scanner remains fully functional without a provider. Capture, history
open, tree browsing, search, export and comparison never invoke the enrichment
service and remain payload-free.

### Phase 1.5 constraints (implemented; binding on later providers)

- fully offline operation, no network access;
- only bounded byte-range reads, never full-file reads and never full-file hashing;
- no sampled-byte persistence — bytes read for classification are never written to storage;
- no modification of the source volume;
- append-only/versioned results through the repository API (see `entry_classifications` in `database/schema.sql`) — a later run never rewrites or reinterprets an earlier run's stored result;
- provenance fields remain independently traceable where present; classified filetype rows carry its exact detector version, host-owned provider ID, nil model version and nil confidence;
- classification never mutates immutable snapshot metadata (`entries`, `snapshots` aggregate fields) and never alters a historical Metadata Match or diff conclusion, past or future;
- classification failure never changes a snapshot's `complete`/`interrupted`/`failed` status.

## 9a. Local Classifier Runtime (Task036 final BRAIN technical acceptance with advisory)

This section preserves the resolved design and records the verified runtime status. Task035 current verification: clean Debug/Release arm64 builds passed; full Debug 494 executed / 491 passed / 0 failed / 3 existing external-probe skips; focused classification/isolation/schema 242 executed / 242 passed / 0 failed / 0 skipped; supplemental schema-safety 18 executed / 18 passed / 0 failed / 0 skipped. Exact commands, durations and per-suite counts: [FSD_P15_WHOLE_RUNTIME_VERIFICATION_D_20261007-015634.md](../handoffs/FSD_P15_WHOLE_RUNTIME_VERIFICATION_D_20261007-015634.md).

### Current provider status

CURRENT_PROVIDER_STRATEGY=PROVIDER_NEUTRAL_LOCAL_CLASSIFIER
MAGIKA_PROVIDER_SELECTION=CURRENTLY_NONE
MAGIKA_STATUS=BLOCKED_CANDIDATE (blocked, non-exclusive; not rejected, not approved)

The packaging decision below remains accepted and provider-independent: the classifier runs as a locally bundled helper process inside `FSD.app`, arm64, macOS 15+ compatible, offline and self-contained. filetype v1.1.3 is the BRAIN-accepted production provider; ADR-035 integration is implemented by task033A (`556872844b90640cc2a64e40d99594a78cef61af`) and independently audited by task034 (accepted `PASS_WITH_ADVISORY` at publication `9d1a8ea237c6c2941895b1c3640118371d2e2d4d`). Task035 verified the runtime; Task036 subsequently completed the independent final audit and BRAIN accepted Phase 1.5 with advisory (see [STATE/PROJECT_STATE.md](../STATE/PROJECT_STATE.md)). This is historical acceptance evidence, not a Task054 rerun; manual and FSD2 Full internal acceptance remain separate.

### Accepted production provider (ADR-035)

```text
INTEGRATION_TARGET=filetype_v1.1.3
PRODUCTION_PROVIDER_ACCEPTED=YES
INTEGRATION=IMPLEMENTED;INDEPENDENTLY_AUDITED
```

Verified physical layering:

```text
FSD Swift host (BoundedClassificationSourceReader reads <=4096 bytes, owns Data)
  -> fixed bundled helper process (Contents/Helpers/FSDClassificationHostSeam, stdin only)
  -> deterministic FSD ambiguity guard (len<=513 && prefix D0 CF 11 E0 -> no_match, no Match call)
  -> filetype.Match (v1.1.3, unmodified, at most one call)
```

The guard receives no additional authority and reads no additional bytes. It is an FSD adapter truthfulness guard against a demonstrated upstream map-order ambiguity, not a forked detector. No universal classifier determinism is claimed: available pinned PNG/DOCX/XLSX/PPTX fixtures were single-valued, and legacy-Office determinism is not proven. Normal Xcode builds consume one committed native helper and require no Go or network. Full contract: `docs/CLASSIFIER_FILETYPE_INTEGRATION_CONTRACT.md` (its task032 creation-time gates remain historical contract state; current acceptance is recorded above and in STATE).

Helper `FSD/Helpers/FSDClassificationHostSeam`, SHA256 `665a6569ee60614313e50629c4166358b89859f15dac4c522905ee5a730752e7`; exact detector `github.com/h2non/filetype@v1.1.3`; host-owned provider `fsd.bundled-helper-host.v1`. Fresh unsigned Debug/Release bundles preserve its bytes at `Contents/Helpers/FSDClassificationHostSeam` and the notice at `Contents/Resources/THIRD_PARTY_NOTICES.txt`; arm64, minos 13.0. Six current observed helper runs had zero sockets/descendants. Normal builds construct/download nothing through Go. The scratch Release copy passed deep/strict ad-hoc signing verification; no Developer ID, notarization or App Store readiness claim.

General realistic legacy DOC/XLS/PPT determinism remains unproven.
Available pinned realistic PNG/DOCX/XLSX/PPTX bounded fixtures were single-valued in accepted implementation/audit evidence.
The demonstrated short legacy-CFB ambiguity is neutralized by the guard.

Manual acceptance: **NOT PERFORMED — DEFERRED BY OWNER**. Optional current-source inference proves neither historical content nor byte identity.

### Historical Magika packaging evaluation (retained as evidence; superseded as provider selection by ADR-033)

The Magika file-type enrichment adapter packaging was evaluated across four shapes. This four-option analysis is preserved verbatim as the historical basis for the packaging decision. Its `macOS 13 arm64 fit` lines record an evaluation made against the then-current macOS 13 deployment floor; the current floor is macOS 15 (ADR-033), so those lines describe no current compatibility claim, and any future candidate must be verified against macOS 15+ instead:

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

**Decision:** Locally bundled helper executable. This decision remains accepted and provider-independent (ADR-033).
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
1. The byte-ceiling is `4096` bytes (IMPLEMENTED). The accounting definition: the ceiling bounds the single prefix read from the resolved live file; nothing else — no directory-listing bytes, no metadata bytes — counts against it.
2. Range count is exactly `1` single prefix range. No tail reads and no adaptive additional reads (IMPLEMENTED).
3. The read layer concurrency is `1` (single classification at a time) (IMPLEMENTED).
4. **Bytes read for classification are never persisted, never hashed, never logged to any diagnostic surface, in any outcome.**
5. The implemented provider-facing request carries only bounded `Data` — no `URL`, path, descriptor, file handle, resolver, callback, range callback or second source-read capability. `sourceURL` and caller-controlled `byteBudget` are absent.
6. Small-file behavior: a file smaller than the ceiling is read in full (its actual size), not padded or treated as an error. The contract is `0...4096` bytes: an eligible zero-byte regular file may reach a provider with empty `Data`, and the provider may truthfully return `noMatch`; a zero-byte regular file is not source unavailable merely because it is empty (ADR-034).
7. Large-file behavior: only the first `4096` bytes are ever read; the rest of the file is never touched.
8. Unreadable files: disappearing-source, inaccessible-source, directory, symlink, and special-file outcomes are handled exactly as defined in the "Source Resolution and Identity" subsection.
9. The exact pipeline is: FSD source resolution → FSD source identity validation → FSD bounded reader → bounded bytes → provider → typed result. The provider receives no `URL`, path, or file handle at any stage.
10. **Historical design-correction evidence (2026-08-04), not current source.** At that milestone the `LocalClassificationProviderResult` enum contained three cases (`classified`, `unavailable`, `failed`) against the six then-required outcomes (success, unavailable, failed, cancelled, source-changed, unsupported-entry), and three were missing from the live enum: `cancelled`, `source-changed` and `unsupported-entry`. This paragraph records that past gap only. It does **not** describe current source: the complete locked set is now **seven** typed outcomes per ADR-034 — `classified`, `failed`, `sourceChanged`, `unsupportedEntry`, `unavailable`, `cancelled`, `noMatch` — and a no production protocol change was implemented by that design-correction slice.
11. No production protocol change is implemented in this design correction slice.

### Lifecycle and Cancellation

1. Concurrency: exactly `1` classification in flight at a time (IMPLEMENTED). Kept as it strictly bounds resource contention.
2. Trigger scope: single selected-entry action only (IMPLEMENTED). Kept to avoid unintentional background load. The following workflows must **never** trigger classification automatically: capture, application launch, history open, snapshot reopen, browsing, search, comparison, JSON export.
3. Inference timeout: `5` seconds (IMPLEMENTED; actual suspended-child timeout test passed). Kept as a reasonable UX bound for a single file.
4. Memory high-water delta: `2x` the byte ceiling (8192 bytes) (PROPOSED). Kept for strict memory budgeting.
5. Queue/backpressure: no queue in the first implementation. A second request receives `busy` if one is in flight (IMPLEMENTED). Kept to ensure simplicity and single-action UI.
6. UI latency expectation: show progress/cancel affordance after `0.5` seconds (IMPLEMENTED; automated model evidence, manual visual acceptance deferred). Kept for responsive feedback.
7. Cancellation mechanism: The cancellation contract reuses the existing `generation`/`invalidate()` idiom implemented in `SnapshotTreeDataSource.swift`.

**Cancellation Persistence:**
- Evidence: The `detection_status` enum supports only `not_requested`, `disabled`, `classified`, and `failed`. `EntryClassificationRepository` enforces strict append-only semantics with duplicate-run-rejection via a `UNIQUE(entry_id, classification_run_id)` constraint. `SnapshotBrowserView.swift` handles the absence of a row cleanly with a "Not classified" neutral state.
- Decision: `runtime-only` (no row). Appending a dummy row for every cancellation wastes space, and missing rows are already handled correctly by the UI as neutral absence.
Append-only semantics and `(entry_id, classification_run_id)` duplicate-rejection are unconditionally preserved.

### Outcomes and Schema Impact

**Canonical result semantics (ADR-034, Accepted 2026-10-06):** the provider/runtime classification contract has **seven typed outcomes**. `IMPLEMENTATION=ACCEPTED_BY_TASK031` — ADR-034 seven-outcome provider/runtime semantics are implemented and accepted at task031 publication `de8484e203b8b6e259dac90349d44069fc5a6ed0`. `ADR034_RUNTIME_SEMANTICS=IMPLEMENTED`; `FILETYPE_REAL_HELPER_INTEGRATION=IMPLEMENTED_AND_INDEPENDENTLY_AUDITED`.

| Typed outcome | Meaning | `entry_classifications` rows |
|---|---|---|
| `classified` | Provider recognized a type. | 1 row, status `classified` |
| `failed` | Classification operation/provider/process failed. | 1 row, status `failed` |
| `sourceChanged` | Source identity/object changed before provider truth could be trusted. | 1 row, status `failed` |
| `unsupportedEntry` | Entry kind is not eligible for classification. | 1 row, status `failed` |
| `unavailable` | Classification cannot be performed because the required source/provider/helper capability is unavailable. | 0 rows |
| `cancelled` | Classification was cancelled. | 0 rows |
| `noMatch` | Classification **was performed successfully**, but the detector recognized no type. | 0 rows |

`ROW_WRITING_OUTCOMES=4` and `NO_ROW_TYPED_OUTCOMES=3`, totalling `TOTAL_TYPED_OUTCOMES=7`.

`busy` is runtime admission/control state only. It is **not** a `LocalClassificationProviderResult` case and writes no row.

`noMatch` is successful detection execution without recognition: `PROVIDER_RAN=YES`, `TYPE_RECOGNIZED=NO`. It is not `classified` (nothing was recognized), not `failed` (the operation did not fail), not `unavailable` (capability was available and used), not `cancelled`, not `sourceChanged`, and not `unsupportedEntry`. Because it writes no row, it persists no detected type, MIME type, confidence, detector version, model version, provider identifier, sampled bytes or diagnostics. No persisted `no_match` detection_status is created.

Helper IPC token mapping: `resultKind="classified"`, `"no_match"`, `"unavailable"`, `"failed"`. For `no_match`, all of `detectedType`, `mimeType`, `confidence`, `detectorVersion`, `modelVersion` must be null; provider identity remains host-owned and is never emitted by the helper. Unknown or malformed wire `resultKind` values remain `failed`.

Timeout remains `failed`; malformed helper output remains `failed`; a missing helper remains `unavailable`.

**Superseded prior statement (preserved as historical text):** "There are exactly **six** outcomes: success/classified → classified row; failed → failed row; source-changed → failed row; unsupported-entry → failed row; unavailable → no row; cancelled → no row (runtime-only)." That six-outcome statement was the complete locked set until ADR-034 added `noMatch`. Its four row-writing rows remain current and unchanged; the six-outcome completeness claim does not.

**Schema Verdict:**
1. What does `detector_version` identify? Per `EntryClassificationRepository.swift` and ADR-031, it identifies the detection algorithm version, serving as one of the explicitly "persisted provenance fields".
2. What does `model_version` identify? Per the same sources, it identifies the model version used, serving as the other explicit "persisted provenance field".
3. What independent fact does provider/adapter identity represent, and how is it different from both of the above? Provider/adapter identity represents which packaging shape or process produced the row (e.g., a locally bundled helper executable). This is a distinct dimension because the same detector/model version can run under different packaging shapes over the adapter's lifetime.
4. Why must those three facts remain separately, durably recoverable rather than merged into one field? A future reader needs to answer "which detector version produced this row" and "which adapter produced this row" as two independent questions, without depending on an undocumented, unenforced string convention to disentangle them.
5. Could schema v8 — as it existed at design time, not as a hypothetical encoding convention — represent all three facts without semantic overloading? No. The design-time schema-v8 column list provided only `detector_version` and `model_version`, so adapter identity was "runtime-only" without semantic overloading.

Original design conclusion: `SCHEMA CHANGE REQUIRED BEFORE RUNTIME`. **Implemented prerequisite:** schema v9 appends nullable/no-default `provider_identifier`; task035 reran fresh/migrated equivalence, legacy NULL preservation, rollback/version-last, ExpectedState, integrity/foreign-key, append-only and duplicate-run tests. No schema change occurs in task035.
Exactly one minimal missing field, `provider_identifier`, is required to record which adapter/process produced the row, independent of the algorithm and model versions. `detector_version` must not be overloaded to carry this fact because it would merge two orthogonal facts, forcing future queries to rely on an undocumented string convention to disentangle "which adapter" from "which detector".

### UI Contract

For the implemented runtime, classification must be presented as inferred metadata, never as content verification. The UI must follow the established pattern in `SnapshotBrowserView.swift`:
- Absence of classification is presented as a neutral state ("Not classified" or equivalent), never fabricated as an error.
- A current `noMatch` completion for the explicitly executing user action may additionally show a bounded transient runtime message equivalent to "No file type recognized." That message is not a persisted classification, is not an error, invents no detected type and does not survive as historical classification truth. It never renders as "Failed", "Unavailable" or "Inferred file type: Unknown".
- Confidence is shown only when actually present in the data, never fabricated.
- No raw provider diagnostic, stack trace, or internal path ever reaches visible text.

## 10. Product-facing backend contracts for the Owner UX

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
UX projection must not alter snapshot/diff truth.

For comparison:
prefer additive hierarchy/query projection over persisted comparison evidence.
Do not replace canonical comparison truth merely to support a dual-tree presentation.

For search:
future SearchScope abstraction must preserve bounded/indexed execution.

For dashboard:
aggregates must be database-backed and bounded.

## 11. Physical drive identity feasibility — Task054

**Proposal only, 2026-10-18.** ADR-036 is Proposed / Owner Direction Approved /
Technical Proof Pending. This section records feasibility, not an implemented
service, approved migration or empirical hardware result. No live enumeration,
Owner source/media/catalog access, mount/eject operation or device probe ran.
The maximum evidence-supported design contract is observation plus explicit
local association. **No real hardware profile qualifies for `UniqueStrongMatch`.**

### Official evidence inventory

Evidence was checked against installed macOS SDK **26.2** declarations; this
inspection does not prove runtime behavior on the macOS 15 deployment floor.
`SDK` below denotes the path returned by `xcrun --show-sdk-path`, with headers
under `System/Library/Frameworks/`. Hashes and downloaded official sources remain
in ignored `.ai-scratch/task054/{sdk-receipt,official-source-receipt}.json`.
Only public documentation and SDK/source text were read; no described API was
executed. Exact official reference URLs:

- **E1 — callbacks:** [Apple Disk Arbitration notification guide](https://developer.apple.com/library/archive/documentation/DriversKernelHardware/Conceptual/DiskArbitrationProgGuide/ArbitrationBasics/ArbitrationBasics.html).
  `DiskArbitration.framework/Headers/DiskArbitration.h` declares
  `DARegisterDiskAppearedCallback`, `DARegisterDiskDisappearedCallback`, and
  `DARegisterDiskDescriptionChangedCallback` (changed keys arrive in `CFArrayRef`).
  `DASession.h` declares scheduling/unscheduling through a dispatch queue or run loop.
- **E2 — disk objects and optional keys:** [Apple disk/volume guide](https://developer.apple.com/library/archive/documentation/DriversKernelHardware/Conceptual/DiskArbitrationProgGuide/ManipulatingDisks/ManipulatingDisks.html)
  and [pinned Apple DADisk.h](https://github.com/apple-oss-distributions/DiskArbitration/blob/a542bda934211dc3c301bfdcc7f21349c4164a85/DiskArbitration/DADisk.h).
  SDK `DADisk.h` declares nullable `CFDictionaryRef DADiskCopyDescription(DADiskRef)`,
  `io_service_t DADiskCopyIOMedia(DADiskRef)` and nullable
  `DADiskRef DADiskCopyWholeDisk(DADiskRef)`. The callback description is current
  as of that event; outside callbacks the function requests the latest description.
  Retain/release rules require `CFRelease` / `IOObjectRelease` as appropriate.
- **E3 — media properties:** [pinned Apple IOMedia.h](https://github.com/apple-oss-distributions/IOStorageFamily/blob/7edb88fbae296fb7c8ce2f64e115e116e566d51c/IOMedia.h).
  SDK `Kernel.framework/Headers/IOKit/storage/IOMedia.h` declares
  `kIOMediaUUIDKey` (`OSString`, persistent media UUID **if available**),
  `kIOMediaWholeKey`, `kIOMediaLeafKey`, `kIOMediaRemovableKey`, and size/base keys.
- **E4 — identifier derivation:** [pinned Apple daemon DADisk.c](https://github.com/apple-oss-distributions/DiskArbitration/blob/a542bda934211dc3c301bfdcc7f21349c4164a85/diskarbitrationd/DADisk.c#L512-L524).
  This revision converts `kIOMediaUUIDKey` to `kDADiskDescriptionMediaUUIDKey`.
  Its [device GUID block](https://github.com/apple-oss-distributions/DiskArbitration/blob/a542bda934211dc3c301bfdcc7f21349c4164a85/diskarbitrationd/DADisk.c#L696-L718)
  searches ancestor `GUID` and converts it to device GUID data. These are observed
  source derivations, not a promise about every installed daemon release.
- **E5 — registry scope:** [Apple I/O Registry guide](https://developer.apple.com/library/archive/documentation/DeviceDrivers/Conceptual/IOKitFundamentals/TheRegistry/TheRegistry.html)
  and [`IORegistryEntryGetRegistryEntryID`](https://developer.apple.com/documentation/iokit/1514719-ioregistryentrygetregistryentryi).
  SDK `IOKit.framework/Headers/IOKitLib.h` documents entry IDs as shared across
  tasks, valid only until reboot. The registry models live provider/client
  relationships; even tree topology has multi-parent exceptions such as RAID.
- **E6 — serial subject:** [pinned Apple IOStorageDeviceCharacteristics.h](https://github.com/apple-oss-distributions/IOStorageFamily/blob/7edb88fbae296fb7c8ce2f64e115e116e566d51c/IOStorageDeviceCharacteristics.h#L149-L175).
  SDK kernel storage header declares `kIOPropertyProductSerialNumberKey` in
  `Device Characteristics`. Its `Requirement: Mandatory` is a driver-property
  contract; it does not guarantee that an arbitrary DADisk description, USB
  bridge or card exposes the underlying medium's unique serial to an app.
- **E7 — workspace notifications:** [didMountNotification](https://developer.apple.com/documentation/appkit/nsworkspace/didmountnotification)
  and [didUnmountNotification](https://developer.apple.com/documentation/appkit/nsworkspace/didunmountnotification),
  also retrieved from Apple's same URLs with `.md` suffix. SDK
  `AppKit.framework/Headers/NSWorkspace.h` declares `NSWorkspaceVolumeURLKey`
  (mount URL) and `NSWorkspaceVolumeLocalizedNameKey` (display name). Register
  through the workspace notification center; forced disappearance is documented
  for unmount notification. Neither notification is a physical identity proof.
- **E8 — existing Foundation facts:** [`volumeUUIDStringKey`](https://developer.apple.com/documentation/foundation/urlresourcekey/volumeuuidstringkey),
  [`volumeIdentifierKey`](https://developer.apple.com/documentation/foundation/urlresourcekey/volumeidentifierkey),
  [`fileResourceIdentifierKey`](https://developer.apple.com/documentation/foundation/urlresourcekey/fileresourceidentifierkey).
  SDK `Foundation.framework/Headers/NSURL.h` documents a persistent volume UUID
  or nil; volume/file resource identifiers are not persistent across restarts.

| Candidate / declaration | Object and availability | Documented persistence, uniqueness and reconnect limits | Independence / allowed use |
|---|---|---|---|
| `kDADiskDescriptionVolumeUUIDKey` (`CFUUID`); Foundation volume UUID string | Filesystem volume; optional E2/E8 | E8 documents persistent volume UUID when available; no inspected contract guarantees physical uniqueness, clone resistance or universal reconnect behavior | Conservatively one filesystem lineage across APIs; volume candidate only |
| `kDADiskDescriptionMediaUUIDKey` (`CFUUID`); `kIOMediaUUIDKey` (`OSString`) | Particular IOMedia, potentially partition; optional E2/E3 | E3 calls it persistent if available; not a universal physical-device ID or collision guarantee | E4 proves direct derivation at pinned revision: one lineage, never two corroborators |
| Partition UUID, base/size/content (`kIOMediaBaseKey`, `kIOMediaSizeKey`, DA media content) | Partition/media extent, not physical drive; optional | Layout describes that observation; repartitioning, copies and synthesized storage remain unproven | Partition UUID is not necessarily distinct from media UUID; unknown derivation means not independent. Offset/length/type support topology only |
| `kDADiskDescriptionDeviceGUIDKey` (`CFData`) | Reported device/ancestor; optional E2/E4 | No inspected guarantee of availability, spoof resistance or reconnect stability for every USB/reader stack | Ancestor `GUID` alias is same lineage. Subject must be proven; not interchangeable with filesystem UUID |
| `kIOPropertyProductSerialNumberKey` | Driver's storage-device subject; E6 requirement as above, app availability unguaranteed | No inspected guarantee of unique/nonblank/uncloned serial or cross-enclosure/card stability | Distinguish medium, bridge and reader subjects; a serial echoed through two properties is one lineage |
| `IORegistryEntryGetRegistryEntryID`; registry/device/media/bus paths, device unit | Live registry object/topology; calls may fail | Entry ID has reboot limit E5; no persistent physical reconnect guarantee for paths/units | Session correlation only; ancestry fields are correlated topology, not independent IDs |
| `DADiskGetBSDName`; media BSD name/unit/major/minor | Current disk/partition node; optional | No permanent identity promise E2 | Session routing only; never parse node spelling into trusted physical ancestry |
| Volume name/path; NSWorkspace URL/name | Presentation and mount session; may be absent/unmounted | No identity persistence/uniqueness promise E2/E7 | Zero identity strength, even in combination |
| Vendor/model/revision, capacity, protocol, internal/removable, whole/leaf flags | Class characteristics and current topology; optional E2/E3 | No unique physical identity guarantee; `Removable` describes removal from mechanism, not simply external USB | Plausibility/topology only; repeating these does not create strength |
| Foundation volume/file resource identifier, `stat` device/inode | Volume or filesystem object in current OS namespace; optional/errorable | E8 explicitly excludes restart persistence; existing dev+ino root proof is point-in-time source authority | Not a physical-drive identifier or second UUID proof |
| FSD local PhysicalDrive ID / user physical label | Local catalog assertion, generated or user supplied | Stable local reference only; no hardware guarantee | Never counted as hardware corroboration |

Each fact requires typed namespace, subject/object level, API and property,
origin/dependency group, raw value and validated canonical value, observation
revision/time, provider/OS/SDK provenance, quality and profile version. Use exact
UUID parsing only for UUID-typed values; serial/GUID encodings need explicit
profile rules. Do not trim/case-fold arbitrary serials into equivalence. Unknown
origin, unsupported type, blank value, read error and missing key stay distinct.
Two unknown origins cannot be treated as independent by default. Confidence is
categorical with reasons, not a probability or count of matching strings.

### Observation lifecycle and ambiguity model

E1 supports notification-driven observation; a disk/partition appearance need not
mean a mounted accessible volume. A changed volume-path key can signal mount
state; description changes can also change names. Apple warns callback ordering
can vary across media types. **Design inference:** use a serialized reducer,
session/generation IDs and revision-bound decisions; tolerate duplicate/late
callbacks, startup appearances, description updates and disappear-before-mount.
On detach or uncertain event gaps, invalidate availability and pending admission.
Restart creates new sessions and closes old open sessions as interrupted/unknown,
never as proof of a clean unmount. No callback ordering is accepted as tested.

NSWorkspace can feed UI availability hints; it does not supply the IOMedia
ancestry or prove identity for unmounted/unsupported media. Disk Arbitration is
the proposed observation source; bounded per-event IOMedia ancestry traversal
is a separate future adapter. Do not enumerate all devices to guess a match.
Use explicit parent/whole-disk relations, not BSD-name trimming. `Whole` and
`Leaf` do not guarantee one physical storage device. APFS synthesized containers,
multiple stores, RAID, disk images, virtual/network paths and multi-LUN stacks
need a proven mapping or remain `UNSUPPORTED_OR_UNKNOWN` for physical matching.

| Threat / ambiguity | Fail-closed requirement |
|---|---|
| Accidental name/path/BSD reuse | Never candidates from these; preserve new session facts |
| Cloned filesystem/partition IDs, repeated serials, forged device facts | Keep all candidates/collision records; no first/MRU winner. Even two forged fields cannot establish universal authenticated hardware identity |
| Card swap in same reader; drive swap behind bridge; identical readers | Transport identity cannot identify inserted storage; new unresolved media/session |
| Several partitions/volumes on one stack | Record observed relationships separately; never merge volume UUIDs into one partition or manufacture independent device evidence |
| Mixed-time properties, detach/reconnect during confirmation/capture | Revision/generation recheck; stale decision fails closed before capture admission |
| Missing/contradictory facts or unavailable provider | Unknown for insufficiency; Conflict for contradictory linked evidence; no silent fallback |
| Incorrect manual choice or later contrary facts | Versioned manual event/revocation, visible conflict, no history rewrite or hardware verification claim |
| Privacy or unbounded registry logs | Local bounded property allowlist, bounded ancestry and typed error; no payload/raw-device reads or full registry/serial dumps to external services |

The resolver precedence and action eligibility are defined by [ADR-036](DECISIONS.md#adr-036--physical-drive-identity-and-mount-policy-wave-a-candidate).
Collision evidence cannot be discarded because one record is offline. A valid
manual override of a duplicated UUID is visibly manual and never auto eligible.
A validated identity also cannot prove bytes unchanged, capture completeness,
source root authorization or availability. Existing root authority and snapshot
recovery rules remain mandatory. Observation must not mount/unmount/eject/rename,
claim disks, register approval/peek interventions, read payloads or initiate capture.

### Current source and schema-v9 boundary

Read-only inspection found:

- `FSD/Provider/FilesystemDetector.swift`: `volumeUUIDString` → stringified
  `fileResourceIdentifier` → `native-root:<mountPath>`. This legacy descriptor
  combines different identity scopes without persistent-device provenance.
- `FSD/Catalog/SnapshotWriter.swift`, `ensureVolume`: `persistent_uuid` or
  `fallback_fingerprint` lookup with `LIMIT 1`; schema-v9 indexes are nonunique.
  A duplicate can therefore choose one legacy volume row. This is an observed
  code path, not a reproduced hardware incident or permission to repair it here.
- The writer copies source facts into snapshots; `CaptureTimeSourceFacts` and
  `SnapshotHistoryRepository` read those optional immutable facts without
  backfill. `SourceAvailabilityProbe` only tests recorded path existence: it
  cannot close accepted F2 source identity/root-proof risk.
- `docs/database/schema.sql` and `CatalogMigrations.swift` are v9. Snapshots already
  have nullable device/partition/offset/length fields, and the capture-facts
  trigger protects them. Native capture does not currently populate those
  device/partition fields. `volumes` has serial/vendor/model and default-OFF
  auto-capture columns; their presence does not implement a resolver or watcher.
  `snapshots.volume_id` cascades on volume deletion; comparison references use
  RESTRICT. Those existing semantics must not be reused for deleting PhysicalDrive.

### Future data model and bounded implementation plan — no implementation

This is a logical proposal; table names/version numbers/DDL require separate
approval. A future migration version must be chosen against then-current schema,
not reserved here. Do not retrofit hardware meaning into `volumes.id`.

| Proposed local relation | Required contents / ownership |
|---|---|
| PhysicalDrive | Stable local ID, manual label, lifecycle/tombstone; origin manual or approved-profile resolution; no unique constraint on hardware tokens |
| Observed storage objects and topology edges | Distinct volume, partition, media, device, bridge/reader, virtual/unknown subjects; revision-scoped parent edges support one-to-many and unresolved/multi-store topology, not a forced single parent |
| MountSession / observation revision | Local session/boot generation, source/provider, appeared/mounted/unavailable times, path/BSD hints, availability and incomplete/error state; no persistent hardware inference |
| IdentityEvidence | Append-only typed value, subject, API/property, dependency group, timestamps/revision, profile/validation state and reason; nonunique bounded lookup indexes; sensitive facts remain local |
| Resolution / conflict | Append-only candidate IDs/evidence refs, outcome, reason, resolver/profile version and revision; collision quarantine persists independently of current mounts |
| ManualAssociation events | Explicit target, observed volume/partition/session/revision, actor/time/reason and superseded/revoked event; no automatic reusable UUID rule |
| Capture identity receipt / later annotation | New captures record contemporaneous evidence/outcome once in the capture admission transaction; separate later local annotations can refer to old SnapshotIDs but must be labelled retrospective manual assertions, never capture-time facts |

Legacy v9 volumes/snapshots remain intact with **unknown physical identity**.
Do not backfill old snapshots from mutable volume registries, current hardware,
mount paths, stringified file IDs, or shared UUIDs. Existing exports/comparisons,
Collection defaults and `Unsorted` semantics retain their contracts. Per-drive
queries must distinguish confirmed capture-time receipts from later manual
annotations, display provenance and avoid silently merging snapshot histories.

A separately authorized implementation should proceed in these bounded stages:

1. Pure typed facts/resolver with real profile set empty, permanent adversarial
   tests and explicit errors. Add the observation reducer behind an OFF gate;
   demonstrate bounded metadata-only adapters and cancellation without capture.
2. Additive migration and manual-association storage/UI with synthetic catalogs.
   Register migration transaction and version together (ADR-024); verify expected
   schema/columns/indexes/triggers on every open. Keep v9 capture/entry/terminal
   comparison guards and existing FK semantics. No source or historical backfill.
3. Commit an observation revision, evidence, resolution/collision and manual
   event atomically; failed transaction leaves no active relationship. Foreign
   keys enforce valid subjects/targets/evidence; referenced evidence/events/drives
   use RESTRICT or tombstones. Deleting a local drive must never cascade into
   legacy volumes, snapshots, entries, Collections or comparison evidence.
   Deletion/privacy retention policy needs separate explicit design approval.
4. Design new-capture admission so the receipt and snapshot facts commit together
   after fresh generation/root/availability checks; lifecycle cancellation or
   crash leaves incomplete work and preserves the last complete snapshot.
   On recovery, replay no capture automatically; stale manual decisions need
   confirmation and unresolved migrations roll back without version advancement.
5. Run the separately authorized designated-media matrix in [TEST_PLAN.md §10](TEST_PLAN.md#10-adr-036-identity-feasibility-and-proof-gates--task054).
   Pin tested OS/provider/reader/enclosure/firmware conditions and origin evidence.
   Approve only a bounded supported profile; absent two independent appropriate
   device origins, keep automatic strong matching disabled indefinitely. Repeated
   successful reconnects establish evidence for that profile, not universal uniqueness.
6. Production integration, source-root/observer safety audit and BRAIN acceptance
   must precede enabling even opt-in automation. Auto Capture remains OFF by
   default/reset; physical proof, schema implementation and this later work are
   not authorized by Task054. Drive Sets and durable comparison save remain
   ADR-037/038 proposals with unchanged status.

Required future migration tests: v9/new/older catalog paths; nonunique legacy
UUID/fingerprint rows; missing facts; FK/integrity checks; idempotent reopen;
failed-migration rollback; crash between observation/resolution/capture writes;
manual correction/revocation with immutable prior snapshots; drive tombstone
without history loss; bounded indexed candidate/history queries. No such
production or migration test ran in Task054. PRD §2 pre-decision Drive Set wording
and §6.1's legacy raw-provider identity language remain read-only advisories;
they cannot grant physical identity or expand supported provider scope.

## 12. Drive Sets relational feasibility — Task055

**2026-10-18; SYNTHETIC_PROTOTYPE only.** [ADR-037](DECISIONS.md#adr-037--drive-sets-vs-snapshot-collections-wave-a-candidate)
remains Proposed / Owner Direction Approved / Technical Proof Pending. No
production schema, migration, Swift/UI, source observation or hardware proof is
implemented. ADR-036's approved real strong profile set remains empty. Task055
reconciles only PRD §2's dated Drive Set direction; the Task054 §11 note above
records the earlier read-only scope, not a continuing unresolved §2 direction.

### Existing contract and official SQLite evidence

Read-only baseline `1b903385d1093b52dec3661a238e09063ce7b9a2`:

- `docs/database/schema.sql` / `CatalogMigrations.currentVersion` are v9.
  `collections.id` and `snapshots.collection_id` implement zero-or-one
  Collection, NULL Unsorted, normalized unique names and SET NULL on Collection
  deletion. `source_collection_defaults` remains volume-only (ADR-019/020).
  Existing `volumes.id` is not ADR-036's new PhysicalDrive ID.
- `SnapshotCollectionRepository` uses ID-based writes, trim plus
  `PathIdentity.caseFold`, transactions, parameter binding and LIMIT+1 pages.
  Its current listing/count limitations do not authorize a rewrite here.
  `SnapshotRecord` has a volume ID, not a physical-drive membership.
- `CatalogDatabase.transaction` serializes `BEGIN IMMEDIATE`/COMMIT/ROLLBACK;
  opening enables/asserts FK enforcement and rejects unsupported/newer versions.
  `CatalogMigrations` supports materialized v4–v9, explicit steps and expected
  tables, exact trigger/index definitions and columns. ADR-024/025 remain binding.
- Existing volume deletion cascades to snapshots, while comparison source FKs
  RESTRICT deletion and guards preserve capture facts/entries/terminal evidence.
  Drive Set deletion must never enter that graph. No legacy relation is reused.

| Evidence | Official source / relevant contract | Design consequence |
|---|---|---|
| Q1 | [SQLite foreign keys §§2–4.3](https://www.sqlite.org/foreignkeys.html): enforcement per connection, NULL child keys, parent uniqueness, child indexes, cascade/restrict actions | Enable/assert FK before transaction; non-null composite membership key; reverse index; cascade only from set to pairs |
| Q2 | [Transactions §§2–3](https://www.sqlite.org/lang_transaction.html): one writer, BEGIN IMMEDIATE may fail busy; ABORT is not necessarily whole-transaction rollback | Existing serialization/process lock; explicitly roll back all mutations; bounded busy/error reporting, no blind retry |
| Q3 | [Conflict resolution](https://www.sqlite.org/lang_conflict.html): REPLACE deletes conflicting rows; ABORT preserves prior statements | No REPLACE; targeted duplicate-pair handling and whole-operation rollback |
| Q4 | [Collating sequences](https://www.sqlite.org/datatype3.html#collating_sequences): built-in NOCASE folds ASCII | Store versioned application normalization; do not claim universal Unicode equivalence from NOCASE |
| Q5 | [Row values §3.1](https://www.sqlite.org/rowvalue.html): scrolling-window tuple comparisons; [query-plan documentation](https://www.sqlite.org/eqp.html): SEARCH/index evidence and unstable output format | Keyset paging; inspect properties, do not hardcode full EQP prose as a production contract |
| Q6 | [PRAGMA integrity_check / foreign_key_check](https://www.sqlite.org/pragma.html#pragma_integrity_check): integrity check does not find FK violations | Require both checks, separately |
| Q7 | [Python sqlite3 executescript](https://docs.python.org/3/library/sqlite3.html#sqlite3.Connection.executescript): transaction-control caveats | Prototype uses isolation_level=None, explicit BEGIN and individual execute for migration DDL, never executescript inside migration |

Retrieved 2026-10-18. These document SQLite behavior, not macOS application
integration or real-catalog migration proof. Measured interpreter/library:
Python 3.15.0, SQLite 3.54.0, Unicode 17.0.0. Production SDK SQLite/runtime and
Foundation normalization must be checked separately.

### Proposed entities, keys and deletion graph

Logical names and columns are candidates, not an approved final schema. Local
IDs are opaque 128-bit random IDs encoded as 32 lowercase hex characters,
catalog-scoped, generated once, collision-checked and never derived from source
metadata. A primary-key collision is an explicit error/retry with a new ID for
a new operation; retrying the same acknowledged operation keeps its ID.
Cross-catalog import/merge is outside this contract. IDs are immutable; labels
are mutable and never relationship keys.

| Relation | Candidate columns / constraints | Deletion and indexes |
|---|---|---|
| `physical_drives` | ADR-036 local ID PK; user label; creation provenance, lifecycle/tombstone and separately recorded identity evidence/conflicts | Hard delete unsupported, including unreferenced rows; tombstone retains ID/history. No FK to legacy volumes that could cascade into captures |
| `drive_sets` | ID TEXT NOT NULL PK; name NOT NULL; normalized_name NOT NULL UNIQUE; normalization_version; revision >=1; created_at, updated_at | Explicit set deletion only; primary/unique indexes support ID and normalized-name queries |
| `drive_set_memberships` | set_id and physical_drive_id TEXT NOT NULL; composite PK; added_at; admission=`explicit_local_selection`; IDs immutable by API | Set FK DELETE CASCADE, UPDATE RESTRICT; drive FK DELETE/UPDATE RESTRICT. Reverse `(physical_drive_id,set_id)` index |

Minimal relationship DDL exercised by the generated prototype:

```sql
CREATE TABLE drive_set_memberships (
  set_id TEXT NOT NULL REFERENCES drive_sets(id)
    ON DELETE CASCADE ON UPDATE RESTRICT,
  physical_drive_id TEXT NOT NULL REFERENCES physical_drives(id)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  added_at TEXT NOT NULL,
  admission TEXT NOT NULL CHECK(admission='explicit_local_selection'),
  PRIMARY KEY(set_id, physical_drive_id)
);
CREATE INDEX memberships_by_drive
  ON drive_set_memberships(physical_drive_id, set_id);
```

Full executable DDL is preserved in the Task055 handoff/harness. It additionally
rejects ID updates/hard drive deletion and insertion/update to tombstoned drives.
The PhysicalDrive stub's `origin='manual_local_unverified'`, identity-state and
availability columns are synthetic stand-ins, not a replacement for ADR-036's
append-only evidence, resolution revisions, conflicts and manual events.
There is deliberately no verified hardware flag manufactured by membership.

Deleting a set has one outgoing cascade destination: membership. No table in
the prototype references membership as a parent. The transitive CASCADE closure
from `drive_sets` is exactly `{drive_sets, drive_set_memberships}` (DS37).
PhysicalDrive/volume/session/legacy snapshot/entry/Collection/comparison/evidence
rows cannot be deleted by that path. Existing legacy cascades remain untouched.
Future optional membership annotations must belong only to this metadata, with
their deletion graph reviewed again; identity evidence must not depend on a set.

### Operations, normalization and unresolved members

- **Create/rename:** validate local ID, trim whitespace, reject blank/overlong
  names and recompute versioned NFC + locale-independent folded key. Recommended
  uniqueness is per Drive Set namespace, independent of Collections. Proposed
  bound is 256 Unicode scalar values after trim; Python len is only a surrogate
  for a future explicit Swift unicodeScalars check, not String.count parity.
  DB trim/length checks are defense in depth, not a Unicode normalizer. SQLite
  cannot prove a supplied key matches its display name; all writes must pass
  the future validated repository boundary.
- **Alternatives:** duplicates with visible stable-ID disambiguation are feasible
  but need a separate approved UX policy; binary-only equality misses canonical
  equivalents; NOCASE misses non-ASCII; NFKC would additionally collapse
  compatibility distinctions and is not proposed. Pin normalization semantics
  and test macOS supported versions before acceptance. An upgrade must detect
  newly colliding keys and abort unchanged for explicit resolution, never merge.
- **Add/remove:** explicitly selected set and local drive IDs only; recheck
  existence, active lifecycle and revisions under the write lock. Unknown,
  Ambiguous and Conflict observations do not supply selectable resolved drives.
  A user may organize an already selected offline manual/unverified local record
  without asserting it equals any current mount. All memberships are explicit;
  no name/path/BSD/UUID/Collection matching and no automatic admission, even
  from a future strong match. Real drive creation is blocked until its separate
  manual entity/provenance contract is approved; the harness seeds generated IDs.
- **Availability/correction:** offline is retained; unknown observation is shown
  outside membership. A member may have manual/unverified, conflict, revoked or
  retired provenance alongside availability. Revocation invalidates the live
  association, not the local entity or existing pairs. Never silently migrate
  pairs to another drive. Explicit replacement remove+add is atomic after fresh
  confirmation; captured history/receipts are never rewritten. Future association
  events and retrospective annotations remain ADR-036's separate gated design.
- **Transactions:** create/rename/pair changes/delete commit as one operation;
  bulk chosen-ID changes commit all-or-nothing. Increment set revision on actual
  change; stale revision returns conflict, not last-writer-wins. Remove and
  delete are idempotent absent outcomes; duplicate raw inserts fail. A deliberate
  pair retry may use targeted `ON CONFLICT(set_id,physical_drive_id) DO NOTHING`
  after authorization/lifecycle checks, preserving original added_at/provenance.
  Never mask FK/CHECK errors, use broad IGNORE or REPLACE. Create retry must
  compare the original operation ID and intended metadata; prototype does not
  implement a durable operation-receipt registry.
- **Concurrency/recovery:** use existing catalog serialization and process lock;
  no new multi-process coordination or network catalog. An already executing
  add cannot race retirement inside a serialized transaction. BEGIN/COMMIT
  busy/error rolls back and returns truthful failure; uncertain acknowledgement
  requires reading the exact IDs/revision before retry. No association/capture
  replay during startup. Future crash/disk-full tests remain pending.

### Bounded reads and future migration sequence

Clamp page size to 1–200 and request limit+1; return explicit hasMore/cursor.
Set query: `(normalized_name,id) > (?,?) ORDER BY normalized_name,id LIMIT ?`.
Member query: `set_id=? AND physical_drive_id>? ORDER BY physical_drive_id LIMIT ?`;
reverse uses the reverse index. Join only the bounded page to drive labels and
current status; do not materialize all members, fetch all captures or use N+1
queries. Listing must invalidate cursors on rename/membership mutation or hold a
bounded consistent read transaction; index order alone does not solve concurrent
page changes. Per-page counts can be bounded; exact whole-library totals are not
required. The prototype traverses 257 set rows at 17+1 and observes indexed seeks;
it does not prove large-catalog latency/memory or production page invalidation.
Atomic deletion may visit all pairs in a large set: latency/lock duration needs
measurement, cancellation before commit and rollback, not an invented constant
time claim or chunked partially visible deletion.

Separately authorized implementation sequence:

1. Review/approve local entity creation, provenance/manual correction, tombstone,
   name normalization, limits, cursor and conflict policies. Keep ADR-036's real
   profile set empty until its own proof; Drive Set membership needs no hardware
   auto-resolution. Finalize actual tables only after that boundary review.
2. Against then-current schema, choose an additive forward version (not reserved
   here). Existing supported v4–v8 catalogs first run their accepted explicit
   steps to v9; test both fresh-v9 and migrated-v9 states. v1–v3, missing/malformed
   inventories and newer versions fail unchanged. Never replay cumulative
   schema.sql on an existing catalog, nor hide unexpected tables with IF NOT EXISTS.
3. With process ownership and FK enforcement asserted, perform prerequisite
   PhysicalDrive tables and Drive Sets DDL/indexes/guards in explicit ordered
   migration transactions; append each version row atomically. Validate expected
   canonical definitions and required columns/FKs on every open. Keep all old
   tables/triggers/indexes and existing v9 semantics. No legacy data rewrite or
   physical-ID backfill from UUID, fallback/stringified file ID, label or path.
   Unknown legacy captures remain absent identity receipts, never inferred joins.
4. Verify catalog integrity AND foreign keys before enabling repositories;
   validate new objects inside the migration transaction before commit. A partial
   failure rolls back DDL and version, and retry starts from the original version.
   On a version already committed, validate exact structure without replaying DDL.
   Crash/reopen must yield all committed objects or the prior version, including
   a crash after commit but before acknowledgement; older application builds reject
   the newer catalog unchanged. No automatic downgrade/drop-table recovery.
5. Add ID-bound repositories and explicit UI under separately authorized tasks;
   validate full v9 data/immutability/evidence preservation, repeated operations,
   stale actions, normalization parity/collisions and failure recovery. ADR-038's
   saved artifact schema is still pending: run its actual evidence-preservation
   integration tests when defined. The synthetic sentinel is not that proof.
6. Run bounded scale, concurrency/busy, disk-full/interruption/process-crash,
   migration-from-every-supported-version and integrated UI/accessibility tests;
   independent schema/recovery review and BRAIN acceptance precede production use.

The scratch harness uses individual DDL executions in one explicit transaction
and a synthetic version-10 sentinel only. It loads repository v9 DDL into new
memory, seeds generated legacy rows, then validates proposed relations. It does
not execute Swift migration code or construct historical v4–v8 catalogs. Its
memory-copy reopen test proves repeated validation of committed synthetic state;
it is not process-crash, WAL/power-loss or filesystem durability proof.
Requirements and all receipts: [TEST_PLAN §11](TEST_PLAN.md#11-adr-037-drive-sets-sqlite-feasibility--task055).

## 13. Saved live comparison backing feasibility — Task056

**2026-10-18; SYNTHETIC_PROTOTYPE.** [ADR-038](DECISIONS.md#adr-038--durable-live-comparison-via-explicit-save-option-b-candidate)
remains Proposed / Owner Direction Approved / Technical Proof Pending. Dedicated
saved evidence is the preferred candidate, not an accepted schema or implemented
Save. ADR-012/024/027/028 and ADR-036/037 are unchanged. No hardware identity
profile is needed; the approved real strong profile set remains empty.

### Current v9 source, reference graph and truth boundaries

Read-only baseline `3b81377ca03e9e4478658051118bc42d4560f27f`:

| Actual object / source | Persisted facts and ownership | Consequence for saving / original cleanup |
|---|---|---|
| `volumes`, `snapshots`; `SnapshotWriter`, `SnapshotModels` | `snapshots.volume_id` CASCADE from volume; capture kind, provider/access, source fields, versions/times, optional capture-time volume facts, totals/signatures and mutable organization metadata | Do not use volume registry values as capture facts. Preserve recorded NULLs. Completed transient kind cannot become user. New archive has no FK into these rows |
| `entries` | Snapshot FK CASCADE; composite `(parent_id,snapshot_id)` self FK CASCADE; unique original relative path, preserved/folded paths, flags, sizes/times, aggregates and metadata signatures | A result's entry reference depends on the entire source snapshot. Copy by original IDs, preserve parents/metadata; equal folded paths or filenames are not mapping keys |
| `scan_issues` | Snapshot CASCADE, optional entry SET NULL; path/severity/source/error/skipped/message | Copy frozen issues with remapped optional entry link; no new source read to recreate a warning |
| `comparisons`, `comparison_profiles`; `ComparisonEngine` | Left/right snapshot FKs RESTRICT; profile FK; frozen profile version, terminal status/counts; detailed results persisted in batches | Left=reference, right=changed. Save only complete. Profile ID/version alone is not a historical full definition |
| `comparison_results` | Comparison CASCADE; parent result CASCADE; optional left/right entries SET NULL; kind, difference bits and paths | Original disposal deletes results; deleting an entry could null its link. Dedicated copies need new result/entry/parent IDs and owned side FKs |
| `comparison_collision_groups/members` | Groups CASCADE from comparison; member CASCADE from group and entry; side-ownership triggers | Preserve every group/member, including both uncertain sides. Never pick a representative first match |
| `TransientSnapshotLifecycle`, `ComparisonService` | Close cancels running live-side comparisons, deletes live-side comparison rows, then unreferenced transients. Startup marks orphaned running comparisons failed with persisted counts; only unreferenced transients are deleted | Startup does not indiscriminately delete all referenced transient evidence. Ordinary snapshot/snapshot records persist. An archive must survive comparison AND transient cleanup |
| `ComparisonResultRepository`, `ComparisonBrowserModel` | Catalog-only rows/paging/filtering; inspector reads entry metadata; profile name joined from current registry; compatibility warnings re-derived | Copy stored results/bits and versioned derivation inputs; current labels and UI formatting are not frozen historical evidence |
| `JSONSnapshotExporter` | Streams snapshot metadata/issues; no classifications/payload reads | Existing exporter is snapshot-only, not a saved-comparison export. Future archive read/export adapters must remain offline, paged and metadata-only |

Exact immutability inventory: `trg_snapshots_capture_facts_immutable` includes
kind, source identity/provider/root/version/times (not every snapshot column).
Completed entry INSERT/UPDATE/DELETE guards preserve captured rows. Terminal
snapshot status is guarded. Comparison-source IDs are immutable; terminal
comparison status/summary and result INSERT/UPDATE/DELETE are guarded. Collision
group/member INSERT/UPDATE/DELETE are guarded after terminal state. Whole
comparison disposal is intentionally allowed: child guards no longer find the
parent during CASCADE (ADR-028). The dedicated parent-result index from v8
bounds disposal's self-FK lookup. All remain unchanged.

**Observed gap, not a product repair:** v9 has no immutable full profile-revision
history or engine contract receipt. Comparison profile ID/version fields are not
covered by the terminal status/count trigger. Snapshot totals, warning counts,
features/authorization and mutable labels/notes are not all guarded capture
facts; scan-issue INSERT is guarded for completed captures, UPDATE/DELETE are
not. Accepted runtime semantics remain binding, but Save cannot prove what a
mutable row held at completion by reading it later. No experiment rewrites a
real catalog. Generated tests explicitly distinguish these gaps from protected
entry/result truth.

Future eligibility therefore needs an additive **completion receipt**: a stable
catalog generation plus unique completion token bound to ComparisonID; actual
profile definition used (including name, field flags, ignore JSON, tolerance,
ID/revision); engine/result/warning/normalization versions and selected comparison
key; frozen summary/orientation; side headers/aggregates and issue evidence as
completion commits. Receipt publication and terminalization must be atomic.
The fixture creates this receipt in memory; production does not. Legacy v9
comparisons without it fail closed for exact Save; no current-profile guess,
legacy receipt backfill, rescan, historical warning fabrication or content read.

### Backing alternatives and preferred candidate

Official research basis (retrieved 2026-10-18):
[SQLite foreign keys](https://www.sqlite.org/foreignkeys.html) documents
connection-local enforcement, deferred composite references, RESTRICT/CASCADE
and child indexes. [Transactions](https://www.sqlite.org/lang_transaction.html)
and [isolation](https://www.sqlite.org/isolation.html) support one serialized
writer and committed-reader visibility; BEGIN IMMEDIATE may fail busy.
[Conflict resolution](https://www.sqlite.org/lang_conflict.html) explains why
REPLACE can delete prior rows and why statement ABORT needs explicit operation
rollback. [Atomic commit](https://www.sqlite.org/atomiccommit.html) has storage/
flush assumptions; an in-memory test does not exercise them.
[Row-value paging](https://www.sqlite.org/rowvalue.html) and
[query plans](https://www.sqlite.org/eqp.html) support indexed keysets; EQP output
is diagnostic, not a stable serialized contract. Python's
[resource measurement](https://docs.python.org/3/library/resource.html#resource.getrusage)
reports process high-water usage, not an isolated Swift allocation profile.

| Dimension | A: new user-snapshot copies | B: dedicated saved evidence | C: retain original transients |
|---|---|---|---|
| Immutability | New scanning→complete rows could reuse guards; never convert original kind | Separate sealed graph; original rows untouched | Retention alone cannot freeze mutable header/profile dependencies |
| Compatibility/readers | Reuses snapshot readers but adds copied-capture provenance/history/Collection questions | New archive adapters/serializer/guards required | Existing readers work until close/disposal semantics conflict |
| FKs/deletion | New session/volume identity and user-snapshot retention restrictions; full result remapping still needed | No outgoing FK into legacy truth; exact owned graph and shared-tree restriction | A retaining FK may block current workspace cleanup; changing cleanup needs another lifecycle policy |
| Orientation/profile/offline | Must archive profile definition and exact left/right/result closure | Same, copied by value with source provenance | Current profile join and cleanup prevent a sufficient simple-reference solution |
| Size/remapping | Copies live entries; more lifetime coordination if user sides stay referenced | Candidate copies both sides, increasing size but isolating all lifetime dependencies | Initially cheap storage, growing retained scaffolding and coordination cost |
| Recovery/migration/maintenance | Existing table constraints plus new retention/provenance/save metadata | More additive objects/read paths; one independently disposable graph | Fewer initial copy lines do not remove migration/recovery/ownership work |
| Evidence/disposition | Analyzed only; no executed A prototype | **Preferred for further review**: 47 cases plus 10k/100k entry runs | Analyzed and not selected; no safe revised lifecycle claimed |

B is justified by explicit disposal isolation and synthetic FK/remapping/rollback
results, not a claim that production integration is trivial. The Owner's Option B
is the explicit Save behavior; dedicated backing B here preserves that behavior
and the current unsaved ADR-012 default. Sharing/deduplication is not required for
an initial production implementation; the prototype exercises shared reference
protection so future reuse cannot silently delete another artifact's evidence.

### Candidate entities, ownership and exact mappings

These are logical relations. Actual table/column layout, typed serialization,
version numbers, receipt retention and guard inventory need separate review.

| Relation | Candidate keys and references / lifetime |
|---|---|
| Completion receipt / side headers / issues | Unique catalog-scoped completion token bound to original ComparisonID. Immutable profile/summary/contracts; two side header records and paged issue rows. Owned by the original comparison until archive copy. Prototype `p_*` tables simulate this future mechanism |
| `saved_artifacts` | New opaque ID, completion provenance, complete comparison/profile/contract copies, building/ready state, creation time. No FK to disposable comparison/profile registry; ready evidence immutable |
| `saved_trees` | New opaque ID; completion+side provenance; original SnapshotID as informational origin; frozen header/aggregates, sealed state. Separate from ordinary snapshot kind/history |
| `saved_sides` | PK `(artifact_id,side)` where side is left/right; artifact DELETE CASCADE; tree DELETE RESTRICT; unique `(artifact_id,side,tree_id)` supports orientation FKs; reverse tree index |
| `saved_entries` | PK `(tree_id,new_entry_id)`; unique `(tree_id,origin_entry_id)` and original path; optional composite parent FK within same tree, deferred until commit. Tree CASCADE; parent lookup index; origin/page index |
| `saved_issues` | Tree ownership; original issue provenance; optional remapped entry composite FK within tree; severity/source/error/skipped data retained. Tree CASCADE; entry-child index |
| `saved_results` | Artifact CASCADE; new ID + unique origin-result mapping; parent-result composite FK within artifact; path/kind/bits and row metadata. Composite side FKs bind left/right tree to the artifact; each optional entry FK binds that tree. Indexes on artifact/path/ID, parent and both entry references |
| `saved_groups`, `saved_members` | New group IDs within artifact, unique group path, exact original provenance. Member FK to group CASCADE, to artifact side/tree and copied entry. Group/member/entry lookup indexes; no arbitrary collision pairing |
| `save_operations` | Unique operation ID bound to catalog/completion token and original requested comparison; committed/deleted outcome and nullable archive reference. Artifact deletion detaches reference, retaining a deleted tombstone; no retry resurrection |

No relation depends on PhysicalDrive, Drive Set, Collection, source mount or
volume UUID. Origins are informational and must include catalog/completion
provenance; a reused numeric comparison or entry ID is not the same completion.
The fixture uses generated literal generations/IDs and deterministic scoped
strings; production must generate collision-checked opaque tokens and maintain
an explicit mapping, not concatenate global IDs or infer equivalent devices.

Mapping algorithm:

1. Freeze explicit request `(catalog generation, completion token, ComparisonID,
   operation ID)`; compare its full identity on every retry. Under the catalog
   transaction/ownership lock, reject non-complete/missing/mismatched receipts.
   The profile definition comes from the actual comparison-time value, not from
   a profile registry whose revision now differs.
2. Allocate an artifact ID and left/right tree IDs. Preserve the original side
   order; the live/user service normally puts user reference left/live right,
   but copying never swaps sides based on which is live. Both sides are copied.
3. For each tree, stream original entries by indexed SnapshotID+entry ID. Insert
   a unique original→new mapping; point parent IDs through it, allowing deferred
   FK checks/two-pass reference patching before sealing. Do not require parent
   IDs to arrive before children. Exact paths, names/folded forms, types, flags,
   source dates/sizes, resource identifiers, symlink metadata, aggregates and
   existing metadata signatures retain original values. Never follow symlinks.
4. Copy frozen issues and headers. NULL capture-time facts stay NULL; current
   `volumes` cannot fill them. Header display_name/user_note/collection_id copies,
   if retained, are **completion-time organization annotations**, not active
   memberships or immutable original-capture assertions. Do not copy current
   mutable volume registry values. Metadata BLOBs use explicit typed encoding;
   they are existing identifiers/signatures, never sampled source payloads.
5. Map result IDs and parent-result IDs independently. Copy every result type,
   difference_flags, display/path/times, including ignored rows and NULL-side
   rows. Added/removed orientation is never recomputed. Copy every collision
   group/member and remap side-specific entry IDs. FK checks alone do not prove
   counts/closure: validate both sides, roots, full row/mapping counts and exact
   frozen summary. Preserve uncertain conclusions, do not rerun comparison.
6. Seal trees and ready artifact only after validation, then commit its operation
   receipt in the same transaction. Saved offline readers use archive IDs only.
   `Content Not Verified` remains explicit. Derived warning text/field formatting
   must use stored versioned rules/facts; if unsupported, show stored facts with
   an explicit limitation rather than reinterpreting conclusions.

The prototype encodes full generated v9 row dictionaries as sorted JSON (metadata
BLOBs as tagged hex) plus typed structural FK columns. Original references inside
JSON are informational; live links use remapped columns. This preserves generated
values, but is not a final production archive format. A production serializer
needs an explicit metadata-only allowlist, schema/version validation, lossless
NULL/BLOB/integer round-trip, row/string/JSON size limits and rejection of
unsupported fields. SQL FK enforcement cannot validate JSON payload semantics.
Classifications/payload bytes/previews are excluded; no source or content hash is
computed. The harness hashes synthetic metadata only to assert nonmutation.

### Save transaction, retry, cleanup and recovery

- **Eligibility:** explicit action on complete comparison plus complete side
  snapshots (`complete`/`complete_with_warnings`), same supported normalization,
  receipt/profile consistency, all evidence still present and a permitted budget.
  Failed/cancelled/running work is not a successful save. No scan or source access.
- **Single transaction candidate:** existing serialized `BEGIN IMMEDIATE` under
  per-catalog process ownership pins original rows against close/delete; copy
  building graph, validate, seal, ready+receipt and COMMIT. Any exception,
  cancellation, missing reference or limit rolls back the entire new graph.
  Original capture/result rows and last complete captures are untouched.
  No `REPLACE`, first-match lookup or partial-success error recovery.
- **Visibility:** readers expose only committed ready artifacts. Building is
  transaction-local; do not commit a resumable staging phase under this candidate.
  If real budgets require multi-transaction staging, stop and design explicit
  original-evidence leases, staging ownership, atomic publication and recovery
  separately; do not introduce it as a fallback.
- **Retry:** before loading originals, look up the exact operation ID and compare
  its full request identity. A committed ready record returns the same artifact,
  even if original rows have since been disposed. A conflicting token rejects.
  If known rollback left no operation row, retry may reuse the same operation
  ID. A deleted receipt returns AlreadyDeleted, not a recreated archive. Receipt lifetime and
  uncertain-delete reconciliation remain production design gates.
- **Explicit saved deletion:** mark operation deleted, delete that artifact's
  result/group/side graph, then delete only its unreferenced trees in one
  transaction. Shared tree references RESTRICT deletion; never sweep all trees
  or delete ordinary snapshots/Collections. A tree deletion removes its owned
  entries/issues only. Reference checks/indexes and child-delete immutability
  guards must permit whole-owner disposal without permitting direct mutation.
- **Crash/startup:** after restart, committed receipt+ready graph or no save is
  the target. Preserve accepted scanning/comparison recovery and last-complete
  behavior. Reconcile by exact operation IDs; a missing/inconsistent ready graph
  is an integrity error, not permission to rescan or broadly delete history.
  Unexpected committed building rows fail validation/quarantine for a separately
  scoped repair. Do not replay Save/capture or delete shared evidence at startup.
  Real process kill, WAL/fsync, disk-full and ambiguous COMMIT are NOT tested by
  rollback or in-memory backup. Error UI is bounded and omits raw paths/SQL.

Prototype guards reject ready/sealed evidence writes and protect side ownership
through composite FKs. It has no full production expected-object manifest,
parser, completion-event adapter, operation-receipt write guards/retention policy,
concurrent UI reader or file-backed crash simulator. The repository API plus final
schema must enforce those pending boundaries before any product acceptance.

### Large-tree evidence, safeguards and migration sequence

Measured isolated Python/SQLite results are in [TEST_PLAN §12](TEST_PLAN.md#12-adr-038-saved-comparison-feasibility--task056).
Both 10k and 100k **total metadata entries across two trees** were copied and
read; these are not 100k result rows or filesystem measurements. All copy lists
are at most 256 rows; mappings are scoped in SQLite, not a whole-tree Python dict.
Tree read uses `(tree_id,origin_entry_id)` keyset index. Result read uses
`(artifact_id,path,id)` and a first-page query/root-safe cursor. Support tied paths
with ID tie-breaks, empty/end pages and exact orientation. Production pages must
clamp invalid sizes (candidate 1–256) and expose continuation; the toy API uses
fixed positive sizes and does not implement the UI clamp.

Prototype safeguards: 300,000 copied-accounting rows, 512 MiB serialized metadata,
60 seconds cooperative elapsed time; checkpoint each batch and before commit.
These are experiment ceilings, **not approved production limits**. Serialized
bytes are counted from the receipt/header and copied input rows, not actual
SQLite/index/WAL allocation. No hard RSS, COMMIT/rollback duration, per-row byte
bound or disk-free check is claimed. A 256-row cap alone cannot bound bytes if
one row is huge. Production must preflight row+byte/disk budgets with headroom,
cap individual metadata records without truncating evidence, measure lock/
commit/rollback time, report progress and cancellation, and reject over-budget
saves. Whole-catalog FK/integrity scans in the prototype are test observations;
production save needs bounded scoped closure validation plus enforced FKs, with
full catalog checks at migration/maintenance gates. No unbounded source read.

Separately authorized production sequence:

1. Review/finalize B vs alternatives, completion receipt granularity, metadata
   allowlist/encoding, warning/engine contracts, ID-generation/retry/deletion
   retention, ownership/guard/index inventory and measured single-transaction
   limits. Dedicated archive readers/export are separate required work.
2. Choose additive versions against the then-current schema, not a reserved v10.
   Supported materialized v4 variants→v5→v6→v7→v8→v9 follow existing explicit
   steps; then apply reviewed new objects. Fresh schema and migrated catalogs
   converge. No v1–v3 guess, implicit cumulative schema replay, history backfill,
   content read or change to existing snapshot kinds/terminal evidence.
3. Apply each migration's DDL/required indexes/triggers/FKs plus version row as
   one transaction under process ownership. Verify expected canonical definitions,
   typed columns, FK actions and both integrity/FK checks. Inject failure at each
   boundary; partial upgrade rolls back without version advancement. Reject
   newer/incompatible or malformed catalogs unchanged; older binaries refuse new
   versions. Test old/fresh/migrated paths with generated catalogs only.
4. Implement additive completion receipts in actual comparison orchestration,
   freezing the profile value used and side/issue/summary facts before atomically
   publishing completion; no rewrite of old comparison truth. Legacy receiptless
   comparisons retain current persistence/disposal behavior and remain ineligible
   for exact Save. Do not synthesize receipts during migration.
5. Implement bounded Save/read/delete under separate authorization; validate
   closure, all remappings, original guards and exact operation receipts. Retain
   current unsaved cleanup. Integrate offline inspector/filter/navigation and
   future metadata-only JSON/HTML export without current-source/profile joins.
6. Prove disk/WAL crash/reopen and uncertain acknowledgement, cancelled/failed
   migration/save/delete, shared backing, no orphan/resurrection, normalization/
   serializer upgrades, UI/source-independent behavior and production scale.
   PhysicalDrive/Drive Sets remain independent relations with no new cascade
   into saved evidence. Independent schema/recovery review and BRAIN acceptance
   precede any production completion claim. No such work is authorized here.

## 14. Local PhysicalDrive foundation — Task058

Task058 implements a backend-only catalog layer in `PhysicalDriveModels.swift`
and `PhysicalDriveRepository.swift`. This is local identity persistence and
manual organization; it provides no physical-device proof or live observation.
ADR-036/037/038 retain their proposed status and technical proof gates.

Schema v10 adds four tables without changing any legacy table or row:

- `physical_drives`: random catalog-local UUID, optional nonunique label,
  explicit-local admission provenance, timestamps, revision and retirement flag.
  ID generation uses no observed property. Retirement increments the expected
  revision; hard deletion and revival are rejected.
- `identity_observations`: immutable local subject ID, scope, caller-supplied
  session UUID/revision, observation time, provenance and unresolved state.
  Each new observation gets its own local ID; sessions are supplied records,
  not an implemented mount service. No legacy volume or snapshot foreign key.
- `identity_evidence`: immutable typed facts with scope, kind, explicit provider
  and property, host-defined dependency group, bounded candidate value,
  validation state, provenance and observation revision/time. UUID kinds require
  a syntactically valid UUID and store its canonical spelling. `validated`
  describes a caller-validated fact, never verified physical identity. Unknown
  values are NULL; contradictory values remain conflict evidence. Limit: 32
  facts per repository-created observation, 1024 UTF-8 bytes per candidate or
  provenance, 256 bytes per property, with blank/NUL rejection. Aliases from
  different providers for the same kind share one dependency group; conflicting
  non-null values fail closed. The repository exposes no evidence score.
- `manual_drive_associations`: append-only associate/correct/revoke events,
  operation UUID, observation revision, assertion revision, previous-event ID,
  target drive/revision, actor, reason and time. Non-null targets are existing,
  active local IDs; missing, retired, stale or conflicting targets/observations
  reject before mutation. A correction/revocation appends history. Exact operation
  retries return the original event; changed retry intent rejects. Revocation is
  permitted for a conflicting/retired relationship to preserve correction access.

Manual selection applies only to one volume/partition observation, its session
and revision. It creates no reconnect rule and no capture authorization. A new
observation remains unresolved until separately confirmed. `resolution` preserves
Unknown/Ambiguous/Conflict and may return ManualAssociation for the current local
assertion. Retirement makes a retained association Conflict. UniqueStrongMatch
is reserved in the model and has no producer: approved real strong profiles = 0.
There are no hardware adapters, mount listeners, device enumeration or source I/O.

All writes use the existing serialized `BEGIN IMMEDIATE` transaction boundary.
Target and assertion revisions are rechecked inside it, including separate
connections. SQL unique constraints reject duplicate operation IDs and assertion
revisions. FKs use RESTRICT, immutable history has update/delete guards, and no
new relation references legacy volumes, snapshots, entries, Collections or
comparisons. Later local assertions cannot reattribute historical captures.

The explicit v9→v10 migration creates only the new objects. The current-version
ExpectedState check runs inside the migration transaction before its version row
and commit; incomplete or substituted DDL rolls back too. Unsupported versions
are rejected before changing the persistent journal mode. Every open still
verifies canonical tables, triggers, indexes and required legacy columns. New
tables additionally require exact canonical DDL, which includes their column,
CHECK, FK and unique definitions. Fresh and migrated catalogs share that DDL.
Reads use stable-ID lookups and indexed keyset pages, clamped to 1–200 records
with truncation flags; evidence reads are bounded to detect an oversized set.

Synthetic production-stack XCTest covers schema parity, legacy-row preservation,
rollback/reopen and repository behavior. It does not validate hardware identity,
H01–H14, live observer lifecycle, real crash/power-loss behavior, capture receipts,
Drive Sets, UI or Owner catalog migration. Those remain separate work.

## 15. Synthetic observation contract and resolver — Task059

`SourceObservationEnvelope` is an immutable, bounded, single-subject Swift value.
It reuses Task058's observation ID, session ID, revision, scope, original unresolved
state, observation time and typed evidence. Separate envelopes distinguish device,
media, partition, volume and mount-session subjects; sharing a session is no
physical topology proof. A new revision requires a new observation ID and fresh
manual confirmation. The contract contains generated facts only; it implements
no live adapter, mount event subscription, availability service or event reducer.
Repeated/reordered envelope evaluation has no retained state to overwrite.

Inputs retain a caller-declared complete/partial marker and missing provenance;
completeness is not hardware verification. Missing values use typed `unknown` and
NULL. Malformed UUIDs, wrong scopes, invalid revisions/times, NULs and oversized
values reject with a bounded typed error. Limits are 32 input facts, 1024 UTF-8
bytes per value/provenance, 256 per property/time and 200 input candidates before
deduplication. UUID spellings are canonicalized. Exact duplicate facts collapse;
contradictory duplicates remain available to the conflict check. Fact order is
canonical. Host-defined kind dependency groups collapse provider aliases; these
groups are lineage labels, never a count of independent hardware proofs.

`SourceObservationResolver` is stateless. Candidate records are explicit caller
hypotheses, never discovered from observation strings. The resolver performs no
UUID/name/path/BSD/serial search or automatic PhysicalDrive admission. Outputs
retain sorted unique candidate IDs. The deterministic precedence is:

1. Original Conflict, an explicitly conflicting fact, or disagreeing non-null
   aliases for the same subject/kind returns Conflict, regardless of validation
   label, candidate order or manual choice.
2. Inconsistent duplicate local records, retired candidates, stale/mismatched
   observation/assertion/target references, missing manual targets and malformed
   manual-event structure return Conflict. A manual target must be a current,
   active volume/partition selection with matching target revision.
3. Incomplete candidate coverage is quarantined as Conflict; manual/recency
   choices do not erase it. This is caller-supplied coverage, not an implemented
   collision discovery or persistent quarantine service.
4. A current explicit association/correction returns ManualAssociation, including
   when several hypotheses exist. Missing evidence/provenance alone is not a
   contradiction and does not invalidate a current deliberate manual assertion.
   Revocation supplies no target and proceeds to the unresolved outcomes.
5. Original Ambiguous or multiple distinct hypotheses returns Ambiguous. Zero
   or one weak hypothesis returns Unknown. No first/last/recency rule is used.

There is no production UniqueStrongMatch branch or configurable strong profile:
approved real strong profiles remain zero. Validated typed fields and manual
associations never become hardware verification. The contract grants no source
root authority, reconnect, history merge or capture permission.

`SyntheticSourceResolutionRepository` is a read seam over the existing v10
catalog. It requires exact stored observation/session/revision/state/time/
provenance and canonical evidence equality, a caller's expected current assertion
revision, and existing explicitly supplied candidate IDs. Changed evidence or a
new observation cannot reuse an old manual event. Bounded indexed reads execute
inside the existing serialized BEGIN IMMEDIATE transaction for a consistent
view; it reserves the catalog writer slot but performs no row writes. SQL errors
propagate and the transaction rolls back. Results are point-in-time values, not
admission tokens. This seam does not alter the older Task058 convenience resolver.

Schema, migrations, startup/recovery, snapshot/entry/Collection/comparison facts,
manual events and captured attribution are unchanged. Synthetic XCTest exercises
production Swift and isolated generated catalogs; it proves no real storage
observation, H01–H14, reconnect accuracy or hardware identity. ADR-036/037/038
retain Proposed / Owner Direction Approved / Technical Proof Pending status.

## 16. Manual Drive Sets — Task060 production slice

Task060 implements the local organization subset of proposed ADR-037. v11 adds
`drive_sets` (UUID ID, bounded display name, unique Foundation normalized name,
normalization version, optimistic revision, timestamps) and many-to-many
`drive_set_memberships` (explicit pair, added time, fixed admission provenance).
Names use the existing Swift `PathIdentity.caseFold` recipe after trimming: NFC
and locale-independent folding, pinned as `fsd-drive-set-name-v1`. Collection
normalization/semantics are unchanged. No SQLite NOCASE Unicode assumption.

Only the set FK cascades, and only to membership rows. Drive FK is RESTRICT;
PhysicalDrive hard-delete guards remain intact. No legacy snapshot/volume/
Collection/comparison relation references sets. No old row is backfilled.
Membership updates are explicit remove/add, never inferred; retired targets
cannot be admitted and retained retired memberships stay visible/removable.

`DriveSetRepository` serializes atomic create/rename/delete/add/remove through
CatalogDatabase. Existing mutable rows require expected set and target revisions.
Create retry reuses its opaque ID and verifies current name; current identical
membership/rename is a no-op; absent delete/remove is a no-op after applicable
existence/revision checks. A stale retry is rejected, not replayed over newer
organization. No operation receipt/history framework or resurrection protection
across intentional delete-and-recreate is claimed. Set revisions advance on real
membership or name changes. SQL guards enforce immutable IDs/creation/version,
revision increments, active membership admission and no pair updates.

Lists clamp to 1–200, sorted with keyset continuation. Members use one bounded
indexed JOIN; the picker uses a bounded identity page and one bounded membership
query. Pages are current reads, not frozen views; Refresh/First Page resets after
mutation. IDs and new-table DDL, indexes and triggers are in canonical ExpectedState;
current startup rejects drift. v10 retains its prior precommit inventory check,
then v11 checks the complete inventory before its version row commits. DDL and
version failure roll back the current step. Existing supported v4–v10 chains
reach v11; the two known v4 variants remain supported.

`DriveSetsView` is a Library sidebar destination with one set/member workspace,
rename/create sheets, add-record sheet and destructive confirmations. Its model
calls production repository APIs; no fake data adapter. Manual local record
creation reuses Task058's explicit-local admission, marked unverified, then
requires a separate membership action. Labels state connection unknown because
there is no live service; this slice cannot assert offline/connected hardware.
Bounded user errors expose no raw SQL/path. Existing startup catalog ownership,
source/capture/comparison APIs, observation resolver and real strong profile
count (zero) are unchanged. No source/hardware listener or automatic capture.

## 17. Atomic comparison completion receipts — Task061

Schema v12 adds `comparison_receipt_catalog` (one immutable random catalog
creation/generation token) and `comparison_completion_receipts` (one row per
new successful comparison, with its own opaque completion token). They are
catalog references, unrelated to physical hardware identity. No historical
comparison is backfilled. A legacy receiptless terminal comparison remains
readable through existing APIs and permanently ineligible for exact Save.

The engine passes its **actual retained ComparisonProfile value**, loaded before
matching, and its selected key/warnings to receipt finalization. It never
reloads the current profile to reconstruct execution. Profile loading now rejects
malformed ignore-rule JSON, invalid flags/tolerance, UTF8/NUL and bounded-size
violations instead of treating malformed rules as an empty list. A selected
profile is validated independently of unrelated rows.

Successful finalization holds the existing cancellation finalization lock and
one `BEGIN IMMEDIATE` transaction. It verifies the running comparison's IDs and
revision, freezes both completion-time snapshot headers and all current scan
issues, validates terminal result closure, and inserts the receipt. An AFTER
INSERT trigger transitions the comparison to complete using the receipt's exact
counts/time. A complete transition without its matching receipt is rejected;
direct insertion as complete is rejected. A deterministic, per-connection SQLite
function validates the canonical typed payload and all scalar identity/count
bindings before insertion. It reads only bounded arguments, never a database,
profile, device or source. External SQLite without that function fails closed
on receipt insertion. Any validation, DDL/statement, trigger or COMMIT failure
rolls back success; the engine then attempts its existing failed/cancelled
terminalization with counts of retained results. No result evidence is erased.
Stale/deleted/terminal comparison targets reject. Cancellation that wins the
existing lock prevents success; a cancellation arriving after committed success
does not rewrite it.

Receipt **v1**, `fsd-receipt-json-utf8-v1`, uses sorted-key UTF8 JSON with explicit
Codable tags for SQL NULL, Int64, TEXT and base64 BLOB. It pins every allowed
snapshot/issue column and its storage type. Missing fields (even nullable ones),
unknown fields, noncanonical/invalid encoding, unsupported versions, NUL, invalid
UTF8 and type mismatch reject. Integers never round through Double. Each metadata
field is at most 64 KiB; executed profile name 4 KiB, at most1000 ignore rules,
each4 KiB and total256 KiB (raw JSON at most1 MiB before decoding). Each side
has at most10000 issues; side accumulation and complete encoded receipt each
have an8 MiB ceiling. Exceeding a bound fails comparison completion without
truncating evidence. SQL byte-length checks precede loading metadata values.

The immutable receipt freezes:

- Catalog generation, comparison/completion identity, left-reference/right-changed
  orientation, start/create/completion times and terminal complete status.
- Executed profile ID/revision/name, every field flag, tolerance, hidden policy,
  ordered ignore rules and builtin annotation.
- Engine `fsd-metadata-engine-v1`, identity selection `adr010-v1`, glob
  `fsd-ignore-glob-v1`, exact selected key, recorded normalization version,
  deterministic ordered warnings and `adr010-warning-text-v1` interpretation.
- Both full snapshot headers and scan issues at **completion**. Recorded capture
  columns retain their values and NULLs. Mutable labels/notes/Collection IDs,
  features, totals and issue rows are completion-time annotations, not newly
  invented capture-time truth. No current volume registry fields are substituted.
  Issue entry links are validated within their own snapshot; NULL stays NULL.
- `fsd-result-closure-v1`: all six result counts (including ignored), row/group/
  member and side-entry counts, plus SHA256 of length-framed canonical typed
  persisted result/group/member metadata in table order; results and groups use
  ascending row ID, members use ascending group ID then member ID.
  This hashes catalog metadata, never file contents. Paged validation checks
  every entry has exactly one owned result/member reference, group uncertainty,
  parent closure/order and result shape/flags. Swift materializes at most256
  result metadata rows per page. Coverage uses indexed per-entry reference counts
  with no whole-reference GROUP BY/sort; members stream per group without a
  materialized group-ID list.

Receipt reads revalidate immutable terminal linkage/closure and use frozen
profile/headers/issues, without querying their mutable current counterparts.
Existing presentation APIs remain compatible and may still show current labels.
New receipt/header identity is guarded against update; receipt direct DELETE is
blocked while its comparison exists. Whole-comparison deletion cascades receipts
exactly like its other evidence. Workspace close/startup/transient disposal,
Snapshot Collections, Drive Sets, identity evidence and capture facts are not
retained, converted or rewritten by this foundation. A reused numeric comparison
ID receives a different completion token. Tokens do not claim cross-catalog
hardware or content equivalence.

v10/v11 inventory checkpoints remain before their respective version writes;
v12 adds exact table/trigger/index inventory and singleton-generation validation
before its version row. Fresh and all supported migrated catalogs converge.
This is not Save Comparison, durable tree copying, an archive reader or UI.
ADR-038 remains Proposed / Owner Direction Approved / Technical Proof Pending.
Actual crash/power-loss/storage durability and Owner catalog migration are not
proved by generated XCTest rollback/reopen evidence. No hardware proof, mount
observer, Auto Capture, source payload/hash or Task062 is introduced.

## 18. Task062 explicit saved comparison backend — schema v13

Production `SavedComparisonRepository.save` is an intentional caller action;
comparison completion and workspace close never invoke it. New exact Save requires
Task061's genuine validated receipt and remaining immutable terminal graph.
Receiptless legacy comparisons are ineligible: no reconstruction, current profile
substitution, rescan or backfill. ADR-038 status remains unchanged.

Eight dedicated `saved_*` tables own artifacts, persistent operation receipts,
two independent side trees, entries, issues, results and collision groups/members.
There are no outgoing FKs to original comparisons, snapshots, volumes, profiles,
Collections, Drive Sets or hardware. Header/profile/orientation/warnings/summary
and full receipt encoding are copied by value. Entry/result/member payloads use
canonical tagged SQLite NULL/Int64/TEXT/BLOB metadata with fixed field inventories;
unknown columns, unsupported types, malformed UTF8 and oversized fields reject.
Original IDs in payloads are provenance only. Navigation uses new saved-local IDs
and composite ownership FKs, with database-backed unique origin mappings and
indexed parent/entry/group references. Both sides are independently copied even
when the original snapshot is the same. No ordinary user snapshot is created.

One BEGIN IMMEDIATE transaction validates receipt identity/closure, copies bounded
pages, remaps parent/result/member/issue links, verifies copied entry bytes against
the guarded original graph, checks all saved ownership/count/reference closure,
reproduces the original receipt result digest and seals the complete saved graph.
READY plus the operation receipt publish in that same commit. Source rows are
never changed. Any copy, validation, cancellation or COMMIT failure rolls back the
whole operation. The public receipt method retains its transaction; the narrow
internal Save seam validates inside the caller's existing transaction.

Operation UUID binds catalog generation, completion token and comparison ID.
Replay validates and returns the same artifact after original disposal. Explicit
delete removes only its dedicated graph and atomically marks the permanent
operation row deleted. A repeated delete succeeds; old Save replay cannot
resurrect it. Different operations create independent copies; there is no sharing,
name matching, deduplication or INSERT OR REPLACE.

`open` verifies the archived receipt, operation binding, all typed payloads,
remapped references/counts and metadata seal using catalog data only. Its read-only
handle provides entries, issues, results and collision group/member keyset pages,
with exact original metadata and separate saved-local navigation IDs. Each page
requires READY, so deleted handles fail clearly. It never reads current source
headers/profile/registry or accesses source files. Saved evidence survives the
unchanged production workspace/transient cleanup, including removal of both
original sides and their volumes/profiles.

Production ceilings are 100,000 accounted copied rows (receipt plus entries,
issues, results, groups and members), 256 MiB encoded metadata, 512 MiB logical
SQLite page growth and 60 seconds cooperative elapsed time. Callers may reduce
ceilings only. Pages contain at most256 rows; source raw pages at most4 MiB,
encoded saved pages at most8 MiB, individual source fields64 KiB/raw rows256 KiB,
saved payloads512 KiB and receipt8 MiB. Preflight length/type checks precede page
materialization. Checkpoints cover admission, receipt validation, copy/remapping,
saved validation and precommit. These are cooperative application bounds, not a
hard OS memory/timeout limit, WAL/disk reservation or fsync-duration guarantee.
Initial generated 100K-entry/50K-result work reached the60s limit and rolled back;
the conservative100K accounted-row admission cap now rejects that150K-row graph
before copying. No multi-transaction staging fallback exists. Exact measured
10K success/100K rejection receipts belong to the Task062 handoff.

Fresh and supported v4 variants through v12 migrate additively to v13; precise
saved object inventory is verified before recording the version and on reopen.
Injected DDL/version/COMMIT failures and file-backed reopen are synthetic recovery
evidence. They do not prove real power loss, disk full, Owner migration, hardware,
UI acceptance, public release or signing. Save UI/export remain outside this slice.

## 19. Task063 explicit Save and saved-comparison presentation

`SavedComparisonsModel` owns a serial catalog worker. Main-actor state changes
publish busy, cancellation, retry, eligibility and bounded errors without running
the repository transaction on the main actor. No initializer/completion/browse or
navigation path calls Save. `ComparisonWorkspaceModel` cancels an active Save and
waits behind its task/outcome barrier before normal explicit workspace disposal;
committed Save wins over late cancellation. The original browser invalidates pending page callbacks and pauses main-actor
catalog reads synchronously when Save starts; after settlement it reloads its
bounded current page. This prevents an old result callback from waiting on the
long Save transaction on the main actor. The original browser also stays paused
while the Saved surface is visible; returning to Compare resumes only after a
saved-worker barrier, even if a reader was closed before seal validation finished.
Other comparison lifecycle is unchanged.

Deterministic UI operation UUID bytes derive from SHA256 of a versioned namespace,
catalog generation, completion token, ComparisonID and sorted observed tombstone
operation IDs. This is operation identity, not content/device equivalence. Exact
read-only discovery includes tombstones and admits catalogs of at most4096 total
operations. It uses256-row primary-key pages plus one bounded overflow page
(at most4352 fixed-size rows read); exceeding the4096-operation supported limit
rejects eligibility with a specific reason. An existing exact READY artifact is fully opened before it is offered.
Retries never generate a random operation. Explicit Save Again after deletion uses
the new deterministic identity only after confirmation; old replay stays deleted.

Read-only repository adapters add frozen summaries, exact completion operation
lookup and exact side-owned entry lookup. Summary length preflight admits a prefix
of up to20 receipts within8MiB (at least one valid receipt); next-page truth uses
an ID-only keyset probe. The UI retains one library/evidence page and keyset cursors for visited pages. `SavedComparisonReader` supplies all result kinds, independent side
entries, issues, collision groups/members and exact selected metadata. It opens
without original tables/registries or filesystem reads. Local references and
original provenance IDs are labelled separately; collision membership implies no
pairing. UI errors never display arbitrary SQL/provider error text. No schema,
serializer, Save transaction or deletion guard changes are introduced.

The fixed database connection is serialized by CatalogDatabase. Repository and
reader are Sendable by that lock/immutable ownership contract; their internal test
checkpoint is configured before dispatch, never concurrently mutated. UI tests use
isolated files and the FSD test window only. ScreenCaptureKit current-process
shareable content is filtered to the exact owned window ID; no other application
or global Accessibility tree is inspected. Manual VoiceOver/Owner acceptance and
actual power-loss/disk-full proof are separate pending gates.
