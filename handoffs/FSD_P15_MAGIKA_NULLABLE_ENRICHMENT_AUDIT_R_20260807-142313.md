# Handoff — Independent Audit: Phase 1.5 Magika Nullable Classification Enrichment Boundary

Task: `FSD-P15-MAGIKA-NULLABLE-ENRICHMENT-AUDIT-0806-19`
Role: Reviewer (read-only independent audit)
Audited Writer slice: `FSD-P15-MAGIKA-NULLABLE-ENRICHMENT-0805-18`
(`handoffs/FSD_P15_MAGIKA_NULLABLE_ENRICHMENT_C_20260806-004158.md`)

## AUDIT VERDICT: **APPROVE WITH CONDITIONS**

All safety and correctness gates pass under independent, direct verification:
no automatic classifier path exists, no payload byte is read, schema v8 is
intact and unmutated in effect, classification is nullable/append-only,
snapshot immutability holds, retrieval is bounded with no N+1, UI and
diagnostics are bounded and truthful, comparison and export contracts are
unchanged, and builds/critical tests pass — independently reproduced, not
merely re-read from the Writer's Handoff. The only remaining open items are
exactly the categories `AGENT.md`/this task's own rubric allow under
"APPROVE WITH CONDITIONS": deferred manual UI acceptance, an inactive
Magika runtime (by design), and two pre-existing, unrelated hygiene/wording
findings that were correctly left open rather than repaired. See
**Conditions** below.

---

## 1. Architecture boundary — call-site inventory

Read `FSD/Catalog/EntryClassificationRepository.swift` in full (429 lines) and
grepped every production source file for `ClassificationProvider`,
`ClassificationEnrichmentService`, `EntryClassificationRepository`,
`LocalFileClassificationProvider`, `DisabledFileClassificationProvider`.

**Complete reference inventory (production code):**

| File | Reference | Classification |
|---|---|---|
| `FSD/Catalog/EntryClassificationRepository.swift` | Defines all types (protocol, disabled provider, service, repository) | Definition site |
| `FSD/Browser/SnapshotTreeDataSource.swift` | Constructs `EntryClassificationRepository`; calls `classifications.classification(for:)` **only** inside `details(for:)` | Bounded, selected-entry-only read |
| `FSD/UI/SnapshotBrowserView.swift` | Renders `SnapshotEntryDetails.classification` | Display only, no write path |

`grep -rl "Classification" FSD/Diff FSD/Export FSD/Search FSD/Scanner FSD/Provider FSD/Model` → **zero matches**. `grep -n "Classification|Magika" FSD/App/FSDApp.swift` → **zero matches**.

`grep -rn "ClassificationEnrichmentService(\|DisabledFileClassificationProvider("` across `FSD` and `FSDTests` → **only** `FSDTests/ClassificationEnrichmentTests.swift` instantiates the service and the disabled provider. **`ClassificationEnrichmentService` is never constructed anywhere in production code, including app startup.** It exists as a wired-but-uncalled seam, exactly as documented; there is no hidden automatic call path.

`DisabledFileClassificationProvider.classify(_:)` is a one-line `return .unavailable` with no use of `request` — confirmed by direct read, it performs no filesystem access.

**Result: PASS.** No automatic classifier path exists anywhere in capture, browse, search, export, comparison, or app startup.

## 2. Payload-read boundary

`grep -n "FileHandle|Data(contentsOf|InputStream|mmap|CC_SHA|CryptoKit|Insecure\.|read("` over `EntryClassificationRepository.swift`, `SnapshotTreeDataSource.swift`, `SnapshotBrowserView.swift`, `CatalogDatabase.swift` → **zero matches**. `LocalClassificationRequest.sourceURL`/`byteBudget` are stored fields never dereferenced by the only implementation (`DisabledFileClassificationProvider`) that exists. The one test-suite payload write (`ClassificationEnrichmentTests.testOrdinaryCaptureSearchAndExportDoNotCreateClassificationRows`) writes a synthetic fixture file under `FileManager.default.temporaryDirectory` and reads it back only through the production `SnapshotScanner`'s existing metadata-only path — isolated, not copied into production behavior.

**Result: PASS.** Ordinary capture, browse, search, export and comparison remain metadata-only.

## 3. Schema v8 / DDL audit

- `CatalogMigrations.swift:25` — `public static let currentVersion: Int64 = 8`. No version 9 exists anywhere in source.
- `entry_classifications` was **not** introduced by this slice — `schema.sql`'s own version-4 changelog comment (line 45–50) states the table was added in schema version 4. This Phase 1.5 slice added only: (a) a second, more detailed comment block directly above the `CREATE TABLE` (lines 812–826) explaining the append-only/nullable contract, and (b) a `verify.sql` block (`C1`–`C10`, lines 414–487) exercising constraints that already existed. **No column, trigger, index or table changed.** I independently confirmed this by hand-bootstrapping `schema.sql` into a scratch database and diffing the `entry_classifications` DDL text against the in-repo `EntryClassificationRepository.swift` INSERT/SELECT column lists — they match exactly (`id, entry_id, classification_run_id, detected_type, mime_type, confidence, detection_status, detector_version, model_version, classified_at, created_at`).
- `CatalogMigrations.ExpectedState.tables` (`CatalogMigrations.swift:291`) lists `entry_classifications`; `ExpectedStateInventoryTests` (`testExpectedStateCoversTheCompleteCanonicalObjectInventory`, `testExpectedStateDefinitionsMatchTheCanonicalSchemaText`) independently re-run by me: **10/10 passed** (Debug and Release).
- **Fresh bootstrap, independently run:** `sqlite3 scratch.db < docs/database/schema.sql` → `PRAGMA integrity_check` = `ok`; `PRAGMA foreign_key_check` = empty (clean); `SELECT max(version) FROM schema_migrations` = `8`.
- Manually exercised `entry_classifications` CHECK/UNIQUE constraints directly via `sqlite3`: confidence `-0.01` → rejected (`CHECK constraint failed`); invalid `detection_status` `'bogus_status'` → rejected; duplicate `(entry_id, classification_run_id)` → rejected (`UNIQUE constraint failed`). All three rejections fired exactly as `verify.sql`'s `C4`/`C6`/`C8` comments claim.
- `CatalogDatabase.swift` is listed in the Writer's "exact files changed," but contains **zero** occurrences of the string `classification` and no repo has git history to diff against. Its generic helpers used by the repository (`lastInsertRowID()`, `transaction`, `scalar`, `query`) are pre-existing and used by `SnapshotWriter`, `ComparisonEngine`, and `SnapshotModels` alike — not classification-specific. **This is a low-severity documentation-accuracy note, not a schema or safety defect** (see Findings).

**Result: PASS.** Schema remains version 8; changes are comments/verification-only, not DDL mutation.

## 4. Persistence semantics (`EntryClassificationRepository`)

Full source read confirms, independent of the Writer's prose:

- `classification(for:)` returns `nil` when no row exists (delegates to `latestClassifications`, empty dictionary on no rows).
- `maxVisibleEntryPage = 500`; `latestClassifications(for:)` throws `.invalidInput` if `entryIDs.count > 500` — confirmed by test and by direct constant read.
- `maxHistoryRows = 100`; `history(for:limit:)` clamps `limit` to `[1, 100]` via `max(1, min(limit, Self.maxHistoryRows))` — cannot be bypassed by caller-supplied limit.
- `append(_:)` runs inside `database.transaction`, checks `SELECT 1 FROM entries WHERE id = ?` first and throws `.entryNotFound` if absent — nonexistent-entry writes are rejected before any INSERT is attempted.
- Duplicate `(entry_id, classification_run_id)` maps the SQLite `UNIQUE` violation to a typed `.duplicateRun` error (deterministic rejection, not silent overwrite or silent no-op).
- **No `update` or `delete` method exists in the type**, and `grep -rn "UPDATE entry_classifications|DELETE FROM entry_classifications" FSD FSDTests` returns **zero matches** anywhere in the codebase — append-only is enforced at both the API surface and the SQL-usage level.
- Persisted columns are exactly: run id, detected type, MIME type, confidence, detection status, detector version, model version, classified-at, created-at. **No `providerIdentifier`, no source path, no payload, no sample, no hash is persisted** — confirmed by reading the `INSERT` statement's bound values list. `providerIdentifier` is truthfully documented (source comment, `ARCHITECTURE.md` §9, `KI-025`) as runtime-only because schema v8 has no dedicated provider column.
- Hostile-provider diagnostics: `ClassificationEnrichmentService.enrich` catches any thrown provider error and discards it, storing only `.failed` with no message — verified against `ClassificationEnrichmentTests.testProviderFailureStoresOnlyBoundedTypedStatus`, whose `HostileDiagnosticProvider` throws `"hostile stack trace and absolute path /private/test"` and the test asserts the resulting `statusLabel` contains neither `"hostile"` nor `"stack"`. I re-ran this test independently (passed, both Debug and Release).

**Result: PASS.**

## 5. Snapshot immutability

Independently re-ran (not just read) `ClassificationEnrichmentTests.testExplicitEnrichmentPreservesSnapshotAndEntryImmutability`, which fingerprints `entries` and `snapshots` content before/after an `append`, and separately asserts `PRAGMA integrity_check = ok` and `PRAGMA foreign_key_check` empty after the write — **passed**. `ComparisonSemanticsTests.testComparisonNeverMutatesSnapshotEntries` performs the same fingerprint check around a full comparison run — **passed**. No `UPDATE snapshots` or `UPDATE snapshot_entries`/`entries` statement exists in `EntryClassificationRepository.swift` (only `INSERT`/`SELECT`).

**Result: PASS.**

## 6. Bounded retrieval / N+1 audit

Direct read of `SnapshotTreeDataSource.swift`:

- `root()` and `children(ofParent:offset:limit:)` use only `Self.nodeColumns` (a `SELECT` against `entries` with an `EXISTS` sub-select for `has_children`) — **no join or query against `entry_classifications` anywhere in these two methods.**
- `details(for:)` is the **only** method that calls `classifications.classification(for: id)`, and it is called exactly once per invocation (one bounded query for a single `entryID`), only after the entry-metadata query already succeeded.
- `SnapshotBrowserModel.select(entryID:)` calls `dataSource.details(for: entryID)` exactly once per selection change, synchronously, on the main actor — no async race requiring cancellation, since each call is a single fast local SQLite read gated on the entry already being resolved.
- `ClassificationEnrichmentTests.testStoredClassificationRoundTripsAndDetailReadIsBounded` independently asserts `tree.queryCount == 2` (entry details + one classification query) and `tree.rowsFetched == 2` after selecting one entry with a stored classification — re-run by me, **passed**.
- `ClassificationEnrichmentTests.testVisiblePageClassificationReadUsesOneBoundedQuery` proves `latestClassifications` handles a full 500-row page in one query and throws for 501 — re-run by me, **passed**.
- No SwiftUI view issues raw SQL; all queries are routed through `SnapshotTreeDataSource`/`EntryClassificationRepository`.

**Result: PASS.** No N+1 pattern exists; root/child tree pages never touch classification.

## 7. UI and error boundary

Direct read of `SnapshotBrowserView.swift`'s `EntryInspectorView`:

- Section header explicitly reads `"Inferred classification (optional)"`, separated by a `Divider()` from `"Stored metadata"`.
- Absence renders `"Not classified"` (neutral, no fabricated value).
- Presence renders only `Status`, `Detected type`, `MIME type`, `Detector`, `Model`, and `Confidence` (only shown `if let confidence = classification.confidenceLabel`, i.e., never fabricated) — no raw provider diagnostic field exists in the view or in `EntryClassification` to display.
- Explicit disclaimer text is present twice: `"Inferred metadata only; this is not content verification."` and, at the bottom of every detail panel, `"Recorded metadata only. FSD never read this file's contents, so nothing here confirms what the file contains."`
- `ClassificationDetectionStatus.displayName` maps both `.disabled` and `.failed` to the same bounded string `"Classification unavailable"` — a failed/unavailable provider cannot be confused with "type is known."
- Hostile diagnostics cannot reach visible text: confirmed in §4/§6 above via `testProviderFailureStoresOnlyBoundedTypedStatus`.

**Result: PASS.**

## 8. Comparison isolation

Re-ran `ComparisonSemanticsTests.testClassificationMetadataCannotChangeComparisonOutcome` independently: two entries with **identical** file metadata but **deliberately divergent** classification (`confidence 0.10` / `"text/plain"` vs `confidence 0.99` / `"application/octet-stream"`) still produce `resultType == .matched`, `differenceFlags == 0`, and unchanged aggregate `matchedCount`/`changedCount` — **passed**. `testComparisonNeverReadsOrWritesClassificationRows` (comparison creates zero classification rows) and `testComparisonNeverMutatesSnapshotEntries` (comparison doesn't touch `entries`/`snapshots`) — both **passed**. `grep -rln "Classification" FSD/Diff` → zero matches, confirming no comparison profile or the engine itself ever reads `entry_classifications`.

**Result: PASS.**

## 9. Export contract

`FSD/Export/JSONSnapshotExporter.swift`: `public static let formatVersion = 1` (unchanged); source comment states `entry_classifications` "is never joined." `ClassificationEnrichmentTests.testAbsentClassificationBrowsesWithNeutralStateAndExportsDeterministically` exports the same snapshot twice and asserts byte-for-byte equality (`XCTAssertEqual(first, second)`) and `XCTAssertFalse(first.contains("classification"))` — re-run by me, **passed**. `testOrdinaryCaptureSearchAndExportDoNotCreateClassificationRows` performs the same check against a real `SnapshotScanner`-captured snapshot — **passed**.

**Result: PASS.** No silent contract change.

## 10. Explicit-enrichment behavior — row counts (independently re-run)

| Scenario | Test | Rows before | Rows after | Result |
|---|---|---|---|---|
| Disabled provider | `testDisabledProviderLeavesClassificationAbsent` | 0 | 0 | No row written |
| Classified result | `testStoredClassificationRoundTripsAndDetailReadIsBounded` | 0 | 1 | One valid row |
| Failed/hostile provider | `testProviderFailureStoresOnlyBoundedTypedStatus` | 0 | 1 (`.failed`, bounded) | One typed-failure row, no diagnostic |
| Nonexistent entry | `testWriterRejectsUnknownAndDuplicateRuns` | n/a | n/a | Throws `.entryNotFound(9999)` |
| Duplicate run id | `testWriterRejectsUnknownAndDuplicateRuns` | 1 | 1 (unchanged) | Throws `.duplicateRun` |

All five re-run independently, all passed, both Debug and (as part of the focused suite) Release configurations.

## 11. Ordinary-workflow zero-row evidence

- **Capture, search, export:** `testOrdinaryCaptureSearchAndExportDoNotCreateClassificationRows` drives the real `SnapshotScanner`, `MetadataSearchService`, and `JSONSnapshotExporter` against a freshly written fixture directory and asserts `EntrySnapshotProbe.classificationRowCount == 0` afterward — production workflow, not a copied helper. Re-run: **passed**.
- **Browse:** `testAbsentClassificationBrowsesWithNeutralStateAndExportsDeterministically` drives `SnapshotTreeDataSource.details(for:)` and asserts 0 rows and `nil` classification. Re-run: **passed**.
- **Comparison:** `testComparisonNeverReadsOrWritesClassificationRows` drives the real `ComparisonService`/`ComparisonEngine`. Re-run: **passed**.
- **Application launch / reopening old snapshots:** no dedicated row-count XCTest exists for these two specific scenarios. Evidence here is the call-site inventory in §1: `ClassificationEnrichmentService` is constructed nowhere in `FSD/App/FSDApp.swift` or any snapshot-reopen path, so no code path exists that could write a row on launch or reopen. This is **AUTOMATED VERIFIED at the static call-site level**, not backed by a dedicated dynamic row-counter test — a narrower form of evidence than the other five items above. Recorded honestly rather than overstated.

## 12. Build and test reproduction (independently executed by this audit, fresh isolated DerivedData paths — not copied from the Writer's Handoff)

- **Toolchain:** Xcode 26.3 (Build 17C529), `xcodebuild -version` confirmed. macOS 15.7.7 (Build 24G720), arm64 — matches the Writer's recorded machine context exactly (same host).
- **Focused Debug run 1** (`/tmp/FSD-Audit-DerivedData-Debug`, isolated): `ClassificationEnrichmentTests` + `ComparisonSemanticsTests` + `ExpectedStateInventoryTests` → **36 executed, 36 passed, 0 failed, 0 skipped.**
- **Full Debug XCTest suite** (`/tmp/FSD-Audit-DerivedData-Debug-Full`, isolated, fresh): **293 executed, 290 passed, 0 failed, 3 skipped** — an exact independent reproduction of the Writer's claimed counts, including identical skip reasons:
  - `FSDProbeSeedTests.testSeedIsolatedProbeCatalog` — `FSD_PROBE_CATALOG` not set.
  - `FilesystemMatrixTests.testCaptureExternallyPreparedMountedFilesystem` — `FSD_MATRIX_SOURCE` not set.
  - `FilesystemMatrixTests.testReopenCapturedSnapshotWithTheSourceDetached` — `FSD_MATRIX_OFFLINE_CATALOG` not set.
  - Total wall time: 2238.619s (this run included the full `FinalScaleComparisonTests` million-entry suite; see below).
- **Final-scale (1,000,000-entry) evidence, independently re-observed in this Debug run** (Debug `-Onone`, correctness-only, not a Release performance regression):
  - `testOneMillionAutomaticLiveWorkspaceCloseCompletesAndReleasesTransient`: automatic close 9.874 s, rows=1,000,000, post_write=0.000 s, transient=0, user_snapshots=1, integrity=ok, foreign_keys=clean.
  - `testOneMillionExplicitDisposalCompletesWithCleanCascade`: explicit disposal 9.989 s, residue=0, integrity=ok, foreign_keys=clean.
  - Both figures track closely with the Writer's previously reported 11.398 s / 11.322 s (same class of Debug correctness-only run; minor variance is expected run-to-run noise, not a regression). All 8 `FinalScaleComparisonTests` passed. Per task instruction, no separate Release 1,000,000-row performance campaign was rerun, since source inspection (§1–§9 above) confirms this slice changed neither schema, comparison, nor lifecycle semantics — only an additive, isolated enrichment seam.
- **Fresh Release clean build** (`/tmp/FSD-Audit-DerivedData-Release`, isolated): `xcodebuild clean build -configuration Release` → **BUILD SUCCEEDED**; `FSD.app/Contents/MacOS/FSD` confirmed `Mach-O 64-bit executable arm64`.
- **Focused Release test run** (`/tmp/FSD-Audit-DerivedData-Release-Test`, isolated, `ENABLE_TESTABILITY=YES`): `ClassificationEnrichmentTests` (8) + `ComparisonPersistenceTests` (15) + `ComparisonSemanticsTests` (18) + `ExpectedStateInventoryTests` (10) + `SnapshotHistoryTests` (8) → **59 executed, 59 passed, 0 failed, 0 skipped.** (This audit's own suite selection differs slightly from the Writer's 60/60 figure — different class list, same conclusion: zero failures across every classification-, comparison-, schema-safety-, and history-relevant Release suite reachable under `ENABLE_TESTABILITY=YES`.)
- **Fresh schema-v8 bootstrap** (independent of the app, via `sqlite3 < docs/database/schema.sql`): `PRAGMA integrity_check` = `ok`; `PRAGMA foreign_key_check` = clean; `schema_migrations` max version = `8`.
- **Warnings:** none observed beyond the standard multi-destination selection notice and AppIntents metadata omission (target declares no AppIntents) — consistent with the Writer's report.

## 13. Documentation truth

Read `docs/PRODUCT_STATE.md`, `docs/MVP_PLAN.md` (Phase 1.5 section, lines 176–194), `docs/ARCHITECTURE.md` §9 (lines 314–373+), `docs/DECISIONS.md` ADR-021, `docs/KNOWN_ISSUES.md` KI-025, `docs/TEST_PLAN.md` (Phase 1.5 section). All consistently and accurately state: Magika runtime inactive; classification nullable/non-authoritative; ordinary workflows metadata-only; no automatic backfill; comparison ignores classification; export v1 excludes classification; schema remains v8; manual acceptance deferred. `docs/PRODUCT_STATE.md:150–151` explicitly preserves — does not repair — "the separate legacy startup-error wording finding" and the `.gemini-derived-data` hygiene observation, exactly as instructed. Historical Handoffs under `handoffs/` were spot-checked by filename/timestamp continuity (e.g., the Milestone 5 Handoffs dated 2026-08-05 show no modification signal); none were rewritten by this Phase 1.5 slice.

**Out-of-scope observation (not a Phase 1.5 defect):** `KNOWN_ISSUES.md` KI-024's heading still reads "focused independent re-audit pending," but `handoffs/FSD_M5_SCHEMA_V8_DISPOSAL_REAUDIT_A_20260805-223211.md` (dated after KI-024 was last edited) already closed that re-audit with **APPROVE WITH CONDITIONS**. This is a pre-existing Milestone 5 documentation-staleness item, unrelated to and not introduced by this Phase 1.5 slice; flagged for housekeeping only, out of this audit's scope to fix.

**Result: PASS**, with the one out-of-scope stale-wording note above.

## 14. Writer scorecard

| # | Criterion | Verdict |
|---|---|---|
| 1 | Architecture boundary | PASS |
| 2 | Payload-read safety | PASS |
| 3 | Schema discipline | PASS |
| 4 | Persistence design | PASS |
| 5 | Snapshot immutability | PASS |
| 6 | Bounded retrieval | PASS |
| 7 | UI/error boundary | PASS |
| 8 | Comparison isolation | PASS |
| 9 | Export stability | PASS |
| 10 | Test/build quality | PASS |
| 11 | Documentation accuracy | PASS |
| 12 | Scope discipline | PASS |

**Passed criteria: 12/12.**

**Independent tests executed by this audit:** 36 (initial focused Debug) + 293 (full Debug, superset of the 36) + 59 (focused Release) = 352 XCTest test-method executions, all 0 failures; plus manual `sqlite3` fresh-bootstrap/integrity/foreign-key/CHECK-constraint probing; plus a full clean Release build; plus exhaustive `grep`-based call-site and payload-API inventories across every production source directory (`App`, `Catalog`, `Browser`, `UI`, `Diff`, `Export`, `Search`, `Scanner`, `Provider`, `Model`) and `FSD.xcodeproj/project.pbxproj` (confirming only `libsqlite3.tbd` is linked and the shell-script build phase is empty — no new dependency, subprocess, or download step).

**High findings:** 0
**Medium findings:** 0
**Low findings:** 2
  1. `CatalogDatabase.swift` is listed in the Writer's "exact files changed" but contains no classification-specific code detectable by source inspection (no git repository exists to diff against); its generic helpers used by the repository are pre-existing and shared by unrelated repositories. No safety impact; recommend the next Writer session double-check that file listing.
  2. `KNOWN_ISSUES.md` KI-024 heading is stale relative to the already-closed M5 disposal re-audit. Pre-existing, unrelated to Phase 1.5, no action required by this task.

**Estimated corrective rework: NONE.**
**Effectiveness rating: EFFECTIVE.**

## Conditions (attached to APPROVE WITH CONDITIONS)

1. Human UI/manual acceptance (including VoiceOver/accessibility spot-check of the new "Inferred classification" panel) remains **NOT PERFORMED — DEFERRED BY OWNER**, per the project's Deferred Manual Testing Rule. Does not block this approval; blocks only final manual sign-off.
2. Magika runtime inference remains intentionally inactive (no model, dependency, download, subprocess, or network service) — this is the correct and required state for this phase, not a defect.
3. The pre-existing, separately tracked legacy startup-error wording finding remains open (correctly not repaired here, out of this task's scope).
4. The pre-existing `.gemini-derived-data` project-root hygiene observation remains open (correctly not deleted here, explicitly out of scope).
5. The two low-severity findings in §14 are housekeeping-only and carry no safety or correctness impact.

## Exact files inspected (all read-only; nothing modified)

- `handoffs/CURRENT_HANDOFF.md`, `handoffs/FSD_P15_MAGIKA_NULLABLE_ENRICHMENT_C_20260806-004158.md`
- `docs/AGENT.md`, `docs/PRODUCT_STATE.md`, `docs/MVP_PLAN.md`, `docs/ARCHITECTURE.md` §9, `docs/DECISIONS.md` ADR-021, `docs/KNOWN_ISSUES.md` KI-025/KI-024, `docs/TEST_PLAN.md`, `docs/SECURITY_AND_READ_ONLY_POLICY.md`
- `docs/database/schema.sql`, `docs/database/verify.sql`
- `FSD/Catalog/EntryClassificationRepository.swift` (full), `FSD/Catalog/CatalogDatabase.swift` (relevant sections), `FSD/Catalog/CatalogMigrations.swift` (relevant sections)
- `FSD/Browser/SnapshotTreeDataSource.swift` (full), `FSD/UI/SnapshotBrowserView.swift` (full)
- `FSD/Export/JSONSnapshotExporter.swift` (relevant sections)
- `FSDTests/ClassificationEnrichmentTests.swift` (full), `FSDTests/ComparisonSemanticsTests.swift` (relevant sections)
- `FSD.xcodeproj/project.pbxproj` (frameworks, package references, shell-script build phases)
- `FSD/App/FSDApp.swift`

No production source, test, schema, migration, or Xcode project file was modified by this audit. Only this Handoff and `handoffs/CURRENT_HANDOFF.md` were written.

## Exactly one next action

Design the separately authorized bounded-byte Magika runtime adapter task
(local-only, offline, bounded byte-range reads only, no full-file hashing,
append-only writes through the existing `EntryClassificationRepository` API,
no schema version 9 unless a provider-identifier column is separately
approved) — without implementing automatic classification or old-snapshot
backfill.
