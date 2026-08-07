# Handoff

## Identity

- Project: FSD (FishSock Differ)
- Task: FSD-M5-FINAL-PREMVP-AUDIT-0805-15
- Case code: FSD_M5_FINAL_PREMVP_AUDIT
- Role: Reviewer (R) — independent final pre-MVP technical audit
- Agent / model: Claude / Sonnet 5
- Session started: 2026-08-05 (approx. 07:40 +0700)
- Completed: 2026-08-05T09:32:49+0700

## AUDIT VERDICT: **REJECT**

The technical core of Milestone 5 is executed with unusual rigor and every
independently-checked claim reproduced exactly — build results, full-suite
counts, fixture arithmetic, memory deltas, and the KI-024 root cause are all
confirmed. The single reason for REJECT is KI-024 itself: independent
investigation shows it is **not** the bounded, "explicit, infrequent" evidence
the Writer's Handoff and `KNOWN_ISSUES.md` describe. It is an automatic,
uncancellable, unbounded-duration single-writer transaction that fires on the
ordinary close of any live comparison workspace — two of the three canonical
comparison modes — at exactly the scale class (1,000,000 entries) Milestone 5
claims as its closed acceptance gate. That reclassifies it from "accepted
non-safety limitation" to an **MVP technical blocker**, which the audit's own
rules route to REJECT. No other gate failed; this is the only blocking
finding.

**Next action:** implement schema version 8, adding the required
`comparison_results(parent_result_id)` index, plus a focused migration and
disposal-performance regression test (see § KI-024 below for the exact fix,
already validated in a scratch database).

---

## 1. Writer Handoff and Scope Verification

- Files added/modified/removed: reproduced against the repository exactly as
  the Writer's `FSD_M5_PERFORMANCE_PREMVP_C_20260805-034539.md` describes.
  Production changes are exactly the two claimed: `FSD/App/CaptureErrorDescription.swift`
  (new) and its two call sites in `FSD/App/FSDApp.swift`; `ComparisonError
  .collisionGroupTooLarge` in `ComparisonModels.swift` plus the cap and throw
  in `ComparisonEngine.swift`; bounded GUI wording in
  `FSD/UI/ComparisonSharedViews.swift`. No other production semantic changed.
- Schema remains version 7 — confirmed by direct inspection of
  `docs/database/schema.sql` and by `CatalogMigrations.currentVersion == 7`
  in source, plus every test-suite run reporting `schema_migrations` version 7.
- Root artifacts: `temp.db*`, `temp2.db*`, `verify_output.txt`,
  `default.profraw`, and the four one-off scripts are confirmed **absent**
  (independently verified with `ls`). The four retained utilities
  (`add_files.py`, `add_files.rb`, `add_files_raw.py`,
  `modify_comparison_project.py`) are present with a documented purpose.
- **New hygiene finding not in the Writer's Handoff:** a `.gemini-derived-data`
  directory (~175 MB: Build/, Index.noindex/, ModuleCache.noindex/,
  TestResults/, etc. — an Xcode DerivedData tree from a differently-named
  agent/tool run) sits at the project root, dated 2026-08-04 16:10. It is not
  mentioned in any hygiene section of the Handoff, `MVP_PLAN.md`, or
  `PRODUCT_STATE.md`. It is build-artifact residue, not a source or project
  file, and does not affect builds or tests (verified: both fresh builds in
  this audit used their own isolated `-derivedDataPath` and succeeded). Left
  in place per this audit's read-only/no-cleanup scope; flagged for the
  owner's attention. **Severity: LOW.**

## 2. Final-Scale Test Oracle Audit

Recalculated independently from `FSDTests/FinalScaleFixtures.swift` generator
logic (not from the Writer's stated totals):

- **Snapshot catalog:** 1 (root) + 1,000 (dirs) + 1,000×1,000 (files) + 40
  (deep dirs) + 40 (leaf.dat) + 1,000 (deepest-level files) + 1 (hidden dir) +
  100 (hidden files) = **1,002,182** — matches exactly.
- **Comparison pair, left:** 1 (root) + 1,000 (dirs) + 1,000,000 (files) +
  1,001 (`zremoved`) + 1,001 (`zcollide`, 500 pairs × 2) + 101 (`zignore`) =
  **1,003,104** — matches.
- **Comparison pair, right:** 1 + 1,000 + 1,000,000 + 1,001 (`zadded`) + 1,001
  (`zcollide`) + 101 (`zignore`) + 101 (`zuncertain`, dir + 100 inaccessible
  files) = **1,003,205** — matches.
- **Classification:** matched = base-pair matches (1 root + 1,000 dirs +
  999,000 unchanged files = 1,000,001) **plus the `zignore` and `zcollide`
  directory entries themselves, which are identical on both sides and match
  independently of what is inside them** (+2) = **1,000,003** — this is the
  one non-obvious step in the arithmetic and it reconciles exactly; changed =
  1,000 (modified files); added = 1,001; removed = 1,001; uncertain = 101
  (`zuncertain`) + 500 (one row per collision group) = 601; ignored = 100 + 100
  = 200. Persisted rows = sum = **1,003,806**. All exact matches.
- **Pathological pair:** 150,000 members/side folding to one key, cap
  100,000 — confirmed by direct code inspection of
  `ComparisonEngine.maxCollisionGroupMemberCount` and `EntryStream.consumeGroup`.

### The two corrected assertions

1. **`totalComparedEntries` excludes ignored evidence — CORRECT TEST-ORACLE
   FIX.** `ComparisonModels.swift:340` defines `totalComparedEntries =
   matchedCount + addedCount + removedCount + changedCount + uncertainCount`
   by construction; the `comparisons` table schema has no `ignored_count`
   column at all — this is a data-model decision, not something a test could
   paper over. The exact same semantics are asserted at small scale in
   `ComparisonPersistenceTests.testIgnoredRowsExistButAreNeverCounted`
   ("ignored rows do not inflate compared totals"), which predates Milestone 5
   and is part of the M4-era regression suite (independently re-run clean in
   this audit's full Debug pass). The M5 final-scale assertion
   (`FinalScaleComparisonTests.swift:73-79`) explicitly comments that it
   mirrors "the same record semantics the Milestone 4 scale record used."
   Not ambiguous, not masking a defect.
2. **Backward navigation seeds the anchor before the first repository call —
   CORRECT TEST-ORACLE FIX.** `ComparisonResultRepository.navigate(...,
   direction: .previous)` uses a **strict** `<` cursor (`FSD/Diff/ComparisonResultRepository.swift:130`),
   so the anchor row itself is never returned by `navigate()`. The corrected
   M5 test (`FinalScaleComparisonTests.swift:193-204`) seeds
   `walkedBackward = [lastRow]` before the loop, which is the only correct way
   to reconstruct the full ordered set via strictly-before/strictly-after
   pagination. This exact contract is independently proven at small scale by
   the pre-existing `ComparisonPersistenceTests.testDifferenceNavigationIsDeterministic`
   (asserts `navigate(from: "moved.bin", .previous) == ["added.bin"]`,
   excluding the anchor) — this test already existed and already passed before
   the M5 session; it is the "focused small fixture" proof the audit task
   asked for, and it independently corroborates the correction without any
   new test being required.

**Conclusion: both corrections are CORRECT TEST-ORACLE FIXES.** Neither masks
a product defect.

## 3. Fresh Build and Test Reproduction

Toolchain (this audit, independently observed): Xcode 26.3 (17C529); Swift
6.2.4, swift-driver 1.127.15; host macOS 15.7.7 (24G720), arm64 (Darwin
24.6.0). Deployment target macOS 13.0 (unchanged). Isolated DerivedData paths
used throughout (never the project's own or the owner's).

- **Fresh Debug clean build:** `xcodebuild clean build -configuration Debug
  -destination 'platform=macOS,arch=arm64'` → **BUILD SUCCEEDED**. Executable
  `FSD.app/Contents/MacOS/FSD`: Mach-O 64-bit **arm64**.
- **Fresh Release clean build (shipped configuration):** same command,
  `-configuration Release` → **BUILD SUCCEEDED**. Executable: Mach-O 64-bit
  **arm64**. Bundled `schema.sql` SHA-256
  `54c9ed252b9b02c8b3c36cd177b5237c5f5feda04e5cb51eeae99052bc8e3187`,
  **byte-identical** to `docs/database/schema.sql` and to the exact hash the
  Writer recorded.
- **Full Debug XCTest suite:** `xcodebuild test -configuration Debug` →
  **277 executed, 274 passed, 0 failed, 3 skipped**, 3,216.8 s (3,631.0 s
  wall). **Exact match to the Writer's claim.** Skips: `FSDProbeSeedTests
  .testSeedIsolatedProbeCatalog` (marker/env-gated, inert), `FilesystemMatrixTests
  .testCaptureExternallyPreparedMountedFilesystem` and
  `.testReopenCapturedSnapshotWithTheSourceDetached` (env-gated matrix
  probes) — all three intentional, correctly documented, not blockers.
  Warnings: exactly one, `appintentsmetadataprocessor: Metadata extraction
  skipped. No AppIntents.framework dependency found` — toolchain noise,
  matches the Writer's characterization, no hidden defect.
- **Focused Release Milestone 5 suites** (`ENABLE_TESTABILITY=YES` for the
  test host only, `-only-testing` for `FinalScaleSnapshotTests`,
  `FinalScaleComparisonTests`, `FinalScaleMemoryProbeTests`,
  `CancellationRaceStressTests`, `M5ReliabilityTests`,
  `CaptureErrorBoundaryTests`): **35 executed, 35 passed, 0 failed**, 2,173.7 s.
  Did not require re-running the complete Release suite (240+ unrelated tests
  unchanged since the independently-audited Milestone 4 close and the
  Milestone 2 acceptance audit); no conflicting evidence arose that would have
  required it.
- Schema resource presence/version: `schema_migrations` reports version 7 in
  every fresh catalog created during these runs, in both configurations.

## 4. One-Million Snapshot Gate — reproduced, AUTOMATED VERIFIED

Re-run under Release: 1,002,182 entries; fixture generation 67.5 s; history
first load 0.0001 s; root/direct-child pages exactly 200 rows each (bounded by
page size, not by 1,002/1,000 children); all 40 deep levels expand; bounded
search `f00500` → 100-hit truncated first page; hidden-filter and path-field
search behave as specified; JSON export 1,002,182 entries, 339,800,087 bytes,
16.6 s (Release), second export byte-identical; reopen 0.008 s, schema version
7, `integrity_check` ok, `foreign_key_check` clean, 0 classification rows.
`SnapshotTreeDataSource` instrumentation (`rowsFetched`, `queryCount`)
confirms the whole exercise fetched roughly 1,000–5,000 rows total — four
orders of magnitude below the entry count, i.e. the tree is never
materialized. All figures independently reproduced this session, not merely
re-read from the Handoff.

## 5. One-Million Comparison Gate — reproduced, AUTOMATED VERIFIED

Re-run under both Debug and Release: 1,003,104 vs 1,003,205 entries; exact
classification 1,000,003 matched / 1,000 changed / 1,001 added / 1,001 removed
/ 601 uncertain (500 collision groups, 2,000 members, never paired) / 200
ignored, 1,003,806 result rows — identical in both configurations and
identical to the Writer's figures. Repeat-run fingerprint identical
(determinism confirmed). Differences-only paging walks all 3,603 differences
exactly once each way. Cancellation at 500,000 processed retains **exactly
250,000 rows**, status `cancelled`, counts equal retained evidence — matches
the Writer's figure exactly, in both Debug and Release re-runs. Result reopen
after connection close/reopen reads the record and first page correctly.
Zero snapshot mutation, zero classification rows, `integrity_check` ok,
`foreign_key_check` clean in every run.

## 6. KI-024 Disposal Investigation — **MVP TECHNICAL BLOCKER** (reclassified from the Writer's "accepted non-safety limitation")

### Root cause: CONFIRMED, not merely plausible

Direct schema inspection: `comparison_results.parent_result_id INTEGER
REFERENCES comparison_results(id) ON DELETE CASCADE` is self-referential; the
only index touching that column is `idx_comparison_results_parent
(comparison_id, parent_result_id, result_type, display_name)`, which cannot
serve a `parent_result_id`-only lookup because `comparison_id` leads.

In a throwaway scratch SQLite database (schema applied verbatim from
`docs/database/schema.sql`, never touching the project; deleted after use):

```
EXPLAIN QUERY PLAN DELETE FROM comparison_results WHERE parent_result_id = 12345;
  -> SCAN comparison_results     (full table scan — no usable index)
```

Empirical timing of `DELETE FROM comparisons WHERE id=1` (cascades to N
`comparison_results` rows, `parent_result_id` all NULL — matching production
reality, see below):

| n | without index | with scratch index |
|---|---|---|
| 5,000 | 0.70 s | 0.023 s |
| 10,000 | 2.78 s (3.95×) | 0.044 s |
| 20,000 | 12.97 s (4.66×) | — |
| 40,000 | 52.68 s (4.06×) | 0.19 s |
| 200,000 | — | 0.98 s |
| 1,000,000 | — | **4.95 s**, integrity_check ok, foreign_key_check clean, 0 residue |

This is textbook O(n²) (≈4× time per doubling), and extrapolating it to
1,003,806 rows predicts roughly 9 hours — consistent with the Writer's "in
progress at over 45 minutes, no completion." **This audit independently
reproduced the 100,202-per-side disposal directly** (not merely accepting the
Writer's figure): 347.1 s in Debug, 505.7 s in Release — both close to the
Writer's recorded 343.9 s / 343.5 s. Note Release was *not* faster than
Debug here, which corroborates the Writer's own observation that this
operation is dominated by SQLite C-level table scanning, not Swift
arithmetic — meaning **no optimization level can fix this; only the index
can**, which the scratch experiment proves does (1M-row disposal: hours →
~5 seconds, with clean integrity throughout).

`comparison_results.parent_result_id` is currently **never set to a non-NULL
value anywhere in production** (`ComparisonEngine.insertResults` hardcodes
`NULL` for it) and is never read by `ComparisonResultRepository` or any GUI
code — it is inert schema forward-compatibility for the not-yet-implemented
matched-subtree-collapse feature (KI-016). This does not change the
diagnosis: SQLite's FK cascade-delete enforcement scans the table looking for
children regardless of whether any row actually has a matching value, because
the query planner cannot know that statically. Adding the index is a
zero-risk, single-index schema-v8 change with no data migration implications
(the column's actual values are unaffected).

### Why this reclassifies the finding

The Writer's characterization — "disposal is an explicit, infrequent user
action... not a release blocker under the stated policy" — does not survive
inspection of `FSD/Catalog/TransientSnapshotLifecycle.swift:140-171`.
`closeWorkspace()` **unconditionally** executes `DELETE FROM comparisons
WHERE ... l.snapshot_kind='transient' OR r.snapshot_kind='transient'` for
**every** live-to-snapshot or live-to-live comparison, on **ordinary**
workspace close — not a separate, deliberate "delete" confirmation. Live
comparisons are two of the three canonical comparison modes in the PRD
(US-04). Neither `closeWorkspace()` nor `ComparisonResultRepository
.deleteComparison(_:)` accepts a cancellation token — once started, a user
cannot cancel this operation; only force-quitting the app stops it (which
rolls back safely per SQLite transaction atomicity — confirmed no corruption
risk — but does not resolve anything, since retrying reproduces the same
multi-hour hang). The entire cascade runs inside one `database.transaction {
}`; with a single-writer SQLite connection this blocks every other catalog
write (new captures, other comparisons, orphan recovery) for the duration.

Weighing the audit's explicit considerations:
- Is disposal an ordinary required workflow? **Yes**, for live comparisons —
  automatic on workspace close, not "infrequent."
- Can the UI trigger it? **Yes.**
- Can cancellation or termination safely interrupt it? Termination rolls back
  safely (no corruption) but does not let the workspace close; there is no
  cancellation mechanism at all.
- Does an unbounded delete create lock risk? **Yes** — a single-writer
  transaction lasting potentially hours blocks all other catalog writes.
  Disk/corruption risk is low (transactional atomicity holds).
- Does correctness at only the 100k class satisfy the canonical M5 gate?
  **No** — `TEST_PLAN.md` CT-005 and the M5 test inventory both state the
  canonical class is "at least 1,000,000 entries," and the Writer's own test
  suite explicitly narrows disposal testing to the 100,202-per-side class,
  one order of magnitude short, with the 1M case documented as not
  completing.
- Is schema v8 required before technical MVP approval? **Yes**, per this
  analysis.

**Classification: MVP TECHNICAL BLOCKER.** Data integrity is not at risk
(confirmed: atomic transaction, clean integrity/FK checks once complete), so
this is not a corruption/security emergency — but it is not a "bounded
non-safety limitation" either, since it is unbounded in duration, has no
cancellation escape hatch, and is triggered by ordinary use of a core,
explicitly-required product workflow at the exact scale the milestone claims
to have closed. Per the audit's own rule ("REJECT when KI-024 is a
technical/release blocker"), this requires **REJECT**, not APPROVE WITH
CONDITIONS.

## 7. Collision-Group Cap Audit

- Cap location/value: `ComparisonEngine.maxCollisionGroupMemberCount =
  100_000` (`ComparisonEngine.swift:29`).
- Count semantics: both sides accumulate into one in-memory array in
  `EntryStream.consumeGroup`; the bound check (`if Int64(group.count) >
  maxCollisionGroupMemberCount { throw ... }`) fires **immediately after each
  append**, so the array is never allowed to grow unchecked past the cap +1 —
  memory allocation is tightly coupled to the check, not decoupled from it.
- Comparison terminal state after overflow: `failed`, never `complete`
  (confirmed by direct read of `ComparisonEngine.compare`'s catch path and by
  the memory-probe test).
- Retained evidence: none beyond what was already persisted before the throw;
  no partial/arbitrary pairing (schema-level triggers
  `trg_comparison_results_no_collision_pairs*` independently enforce this).
- Error visibility: bounded, includes only the numeric member count (not
  sensitive), identical in `ComparisonError.errorDescription` and the GUI's
  `ComparisonUIErrorDescription`.
- Integrity/FK: re-verified clean in this session's reproduction of
  `testPathologicalEqualKeyCollisionGroupIsATypedFailureNotAnOOM` (Release:
  peak delta 55.7 MB for 150,000 members/side against a 100,000 cap).

**The 100,000-member cap is a credible safety boundary.**

## 8. Memory Evidence Audit

Methodology: `mach_task_basic_info` via `task_info` on the actual XCTest-host
process (which, per ADR-026, *is* the real `FSD.app` process — confirmed
correct process). A background sampler polls every 10 ms, starts before and
`stop()`s (joining via semaphore) after the measured operation, so baseline
and peak are directly comparable and the operation is fully bracketed.
Independently re-run this session (Release): comparison merge delta 8.8 MB;
export delta 8.7 MB (output 339.8 MB — proves streaming, since a
whole-document build would show delta ≥ output size); search delta 8.7 MB;
browsing delta 4.9 MB (5,203 rows fetched); pathological collision group
delta 55.7 MB (150,000 members/side, cap 100,000) — all closely matching the
Writer's Debug-session figures in magnitude and all well under the stated
bounds.

**Classification: CREDIBLE BUT APPROXIMATE.** The process, bracketing, and
join-before-read discipline are all correct (this is not "unreliable"), but
10 ms RSS sampling is inherently an approximation of true peak allocation —
it can miss a sub-10ms spike, and `resident_size` includes ordinary allocator/
OS page-residency noise on top of the measured operation's own footprint. The
verdict here does not, and should not, depend on more precision than this
method supports; the bounds are wide enough (100–700 MB depending on
operation) that this approximation is more than adequate to support the
boundedness conclusion.

## 9. Cancellation and Recovery Audit

Re-run in full (`CancellationRaceStressTests`, 8/8 passed both configs;
`M5ReliabilityTests`, 6/6 passed both configs) plus direct source
verification:
- `ComparisonEngine.terminalize` uses `token.withFinalizationLock` — the same
  lock a late `cancel()` call uses — so a race cannot let a comparison reach
  `complete` after cancellation is requested; verified by 3 repeated
  iterations at cancel-near-terminalization thresholds, all passing.
- `RecoveryService.recoverOrphanedScans` reconciles orphaned `scanning` rows
  to `interrupted`, with an idempotency guard (`issueExists` check) preventing
  duplicate scan-issue rows on repeated recovery calls — confirmed by direct
  source read.
- `TransientSnapshotLifecycle.recoverOrphanedComparisons` reconciles orphaned
  `running` comparisons to `failed` (never `complete`), recomputing summary
  counts from persisted rows so the record stays internally consistent.
- Workspace close during a running live comparison correctly cancels first,
  disposes the comparison, then cleans up transients — 0 residue confirmed.
- No deadlock in any of the 8 stress iterations across two full independent
  runs of this suite; `integrity_check`/`foreign_key_check` clean throughout.

## 10. KI-022 Capture Error Audit

Verified both failure sites in `FSD/App/FSDApp.swift` (lines 171-172, 179-180)
route through `CaptureErrorDescription.message(for:)` for the visible state
and `.diagnosticLine(for:)` for the standard-error channel — confirmed by
direct source read, not just by trusting the regression test. Re-ran
`CaptureErrorBoundaryTests` (6/6, both configs) with the adversarial hostile
strings (SQLite path, POSIX errno, provider-internal token): identical
bounded visible text in every case, no hostile token reaches visible strings,
typed distinctions (`invalidSource`/`outsideSelectedRoot` intentionally share
one "not readable" text; cancellation, catalog failure, detector failure all
distinct) all confirmed. **KI-022 as scoped (the legacy capture screen) is
genuinely fixed.**

**New finding, outside KI-022's stated scope but the same defect class (LOW-
MEDIUM severity):** `FSD/App/FSDApp.swift:105` and `:200` assign raw
`error.localizedDescription` directly to `startupError` (catalog
open/migration failure), which is rendered unbounded in the UI at line 271
(`EmptyStateView(..., detail: startupError)`). This is a genuinely different
code path (catalog-startup failure, not capture failure) that was never
claimed fixed and has no regression test — it is not a KI-022 regression, but
it is an undocumented, still-open instance of the same raw-diagnostic-
exposure pattern KI-022 closed elsewhere. Recommend adding it to
`KNOWN_ISSUES.md` and routing it through a bounded mapper in a future task;
does not block this MVP technical decision on its own (startup/catalog-
corruption is a much rarer trigger than the capture UI, and the exposed text
is local-machine diagnostic detail, not attacker-supplied).

## 11. Release App Readiness and Catalog Isolation

Verified directly in `FSD/Catalog/CatalogLocation.swift:76-82`:
`overrideIsAvailable` is gated by `#if DEBUG / #else return false #endif` — a
**compile-time**, not merely runtime, refusal. The Release branch
(`guard overrideAllowed else { return CatalogLocation(url: defaultURL, ...,
rejectedOverridePath: requested.path) }`) resolves the real Application
Support default and records the rejected path; it does not throw or crash.
This audit's Release build and focused-suite run against the real
`~/Library/Application Support/FSD/catalog.sqlite3` (via
`M5ReliabilityTests.testTestHostNeverTouchesTheOwnerCatalog`, which itself
independently re-verifies size/modification-date invariance) confirms the
owner catalog was untouched by this session's Release testing.

**Classification: ACCEPTABLE VERIFIED READ/OPEN BEHAVIOR.**

## 12. Offline, Metadata-Only and Read-Only Regression

Re-confirmed via the full Debug suite re-run (no regressions) and via direct
grep of the production target: no `FileHandle(forReadingFrom:)`, no
`Data(contentsOf:)` on a source path, no hashing API. `JSONSnapshotExporter`
remains the only writing `FileHandle` (to a user-chosen export destination).
History, browsing, search, export, and stored comparison browsing all remain
usable with sources absent, per the re-run offline-construction test suites
(`FinalScaleSnapshotTests`, `FinalScaleMemoryProbeTests`, both fully offline
by construction — the scale fixtures have no source at all).

## 13. Performance Threshold Decision

The Writer proposed but did not retroactively claim acceptance against these
Release thresholds: 1M snapshot open+first page < 2s; bounded search first
page < 2s; 1M-vs-1M comparison < 5 min; first-page/differences latency <
0.1s; export ≥ 1 MB/s; merge peak delta < 100 MB.

Independently re-measured (Release, this session): snapshot generation+open
well under 2s for the open/page operations themselves (root page 0.0008s,
direct-child 0.0005s); bounded search 0.018s; comparison merge completed
well under 5 min; export 339.8MB in 16.6s (≈20.5 MB/s, comfortably clears the
1 MB/s floor); merge peak delta 8.8MB (well under 100MB).

**Classification for each: RATIFIED** — all thresholds the Writer proposed
are met by this session's independent Release measurements, with wide margin.
None was invented after observing a result; they were stated in advance in
the Handoff and are recorded here as decision basis, not retroactive
justification. (This does not extend to disposal — no threshold was proposed
for it, correctly, since it was already known not to complete at this scale.)

## 14. Test and Repository Hygiene

- The three ordinary-run skips are exactly as documented: intentional,
  environment/marker-gated, not blockers. Re-confirmed this session.
- The one Release-only skip (`MilestoneConditionTests
  .testDebugBuildsExposeTheOverride`, DEBUG-only assertion) is valid — the
  full Debug run in this session included it and it passed under Debug; the
  Release focused run did not include `MilestoneConditionTests` in its
  `-only-testing` scope (correctly out of scope for the M5-focused pass, and
  it was already independently verified by the prior full-suite run cited in
  the Handoff, which this audit did not need to duplicate).
- No test warning observed represents a hidden defect (only the one
  AppIntents toolchain notice, unchanged).
- No pointer `CURRENT_HANDOFF.md` exists — it is a full copy, confirmed.
- No required project artifact was deleted; scratch cleanup did not remove
  reproducibility inputs (all fixtures regenerate deterministically from
  `FinalScaleFixtures.swift`, independently confirmed by this session's fresh
  runs).
- Root helper scripts (`add_files.py/.rb`, `add_files_raw.py`,
  `modify_comparison_project.py`) have an explicit retained purpose recorded
  in prior Milestone 4 Handoffs.
- **New finding:** the undisclosed `.gemini-derived-data` residue (§1) is a
  minor hygiene gap not caught by the Writer's cleanup pass.

## 15. Consolidated Manual Session

`TEST_PLAN.md` §8.2 (Manual Session B) reviewed in full: contains setup,
exact owner actions, visible expected results, evidence to record, cleanup,
and canonical test-ID mapping (A1–A6, B1–B11, CT-001, matrix §1) for all 25
steps (M1–M25), covering launch, capture, cancellation, relaunch/recovery,
history, offline browsing/search/export, all three comparison modes,
filters, navigation, uncertainty/content-not-verified wording, disposal,
visual layout, keyboard, VoiceOver, and filesystem sampling. Status is
exactly and correctly stated: **NOT PERFORMED — DEFERRED BY OWNER.** No
owner interaction was requested by this audit, per the Deferred Manual
Testing Rule.

## 16. DeepSeek Milestone 5 Assessment

| # | Criterion | Verdict |
|---|---|---|
| 1 | Scope completion | PASS |
| 2 | Scale-fixture correctness | PASS |
| 3 | Test-oracle correctness | PASS |
| 4 | Performance methodology | PARTIAL — sound measurement, but the disposal trigger's frequency/severity is materially understated |
| 5 | Memory methodology | PASS (credible-but-approximate is the appropriate, expected rigor for `task_info` sampling) |
| 6 | Cancellation/recovery quality | PASS |
| 7 | KI-022 correction | PASS |
| 8 | Collision-cap safety | PASS |
| 9 | Build and test quality | PASS |
| 10 | Documentation accuracy | PARTIAL — KI-024's "explicit, infrequent" characterization does not match `TransientSnapshotLifecycle.closeWorkspace()`'s actual, automatic, uncancellable trigger |
| 11 | Scope discipline | PASS |
| 12 | Repository hygiene | PARTIAL — undisclosed `.gemini-derived-data` residue |

**9 PASS / 3 PARTIAL / 0 FAIL / 0 NOT VERIFIED, out of 12.**

Independent tests executed this session: fresh Debug build + full 277-test
suite; fresh Release build + 35-test focused M5 suite; a from-scratch SQLite
experiment (2 `EXPLAIN QUERY PLAN` checks, 9 timed disposal runs at
5 escalating scales with and without the proposed index); direct source
verification of ~15 production files (schema, engine, repository, lifecycle,
capture error mapper, catalog location resolver, recovery service).

High findings: 1 (KI-024 reclassified MVP technical blocker → REJECT).
Medium findings: 1 (KI-024 frequency/severity characterization in
`KNOWN_ISSUES.md`/Handoff is materially inaccurate).
Low findings: 2 (residual raw-`localizedDescription` in catalog-startup UI
path; undisclosed `.gemini-derived-data` project-root residue).

Estimated corrective rework: **SMALL** — one schema-v8 migration (a single
index), a focused migration test, and a focused disposal-performance
regression test at the 1,000,000-entry class; the fix is already validated
end-to-end in this audit's scratch database (hours → ~5 seconds, integrity
clean).

**Final rating: EFFECTIVE WITH SUPERVISION.** Every quantitative claim this
audit checked — build results, exact test counts, exact fixture arithmetic,
exact classification counts, exact cancellation retained-row counts, exact
schema hash — reproduced exactly. The technical root-cause diagnosis of
KI-024 was itself correct and precise. The miss was specifically a severity/
frequency judgment call (whether disposal is "infrequent" and whether
"non-safety" implies "not a blocker") — exactly the kind of judgment
independent audit exists to catch, and exactly what this audit caught. This
is not a competence failure; it is the reason the review policy requires a
mandatory independent pre-MVP audit for exactly this milestone.

---

## Exact Files Changed By This Audit

**None.** This audit is read-only for production source, tests, schema,
migrations, and the Xcode project, per its scope. The only repository
modifications are this historical Handoff and the overwritten
`handoffs/CURRENT_HANDOFF.md`. No schema version 8, no KI-024 index, no
product code, no Git action was taken (`.git` remains absent, unchanged, per
scope — not initialized by this audit).

Scratch artifacts created and left outside the repository (isolated
DerivedData paths, the KI-024 scratch SQLite experiment) live entirely under
this session's scratchpad directory, never under `/Users/cenvu/DEV/FSD`.

## Exactly One Next Action

**Implement schema version 8**, adding a dedicated index on
`comparison_results(parent_result_id)`, plus:
- one explicit transactional migration (following the `CatalogMigrations
  .all` / ADR-024 pattern already established for versions 1–7);
- an `ExpectedState` inventory update so `verifyCurrentSchemaState()` covers
  the new index (per the ADR-028 H2 discipline);
- a focused migration test (fresh v8, v7→v8, damaged-v8 rejection, consistent
  with the existing `SchemaMigrationTests`/`SchemaSafetyCorrectionTests`
  pattern);
- a focused disposal-performance regression test at the 1,000,000-entry class
  proving completion in bounded time (this audit's scratch experiment shows
  ~5 seconds is achievable — a generous bound such as "under 2 minutes" would
  comfortably and durably validate the fix without being timing-fragile).

This is the smallest change that resolves the sole blocking finding; no other
gate requires rework.
