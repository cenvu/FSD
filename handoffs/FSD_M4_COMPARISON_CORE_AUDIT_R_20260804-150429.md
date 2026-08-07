# Handoff

## Identity

- Project: FSD
- Task: FSD-M4-COMPARISON-CORE-AUDIT-0804-07B
- Case code: M4-COMPARISON-CORE-AUDIT
- Role: REVIEWER
- Agent / model: Codex / GPT-5
- Session ID: not exposed by the runtime
- Started: 2026-08-04
- Completed: 2026-08-04T15:04:29+07:00

## Status

Audit task COMPLETE. Comparison-core verdict: **REJECT**.

DeepSeek V4's comparison backend is present, builds for arm64, and passes the
existing automated suite, but two independent schema-safety defects prevent
approval: terminal comparison collision groups/members remain mutable, and
`CatalogMigrations.ExpectedState` does not verify the complete canonical object
inventory. The visual GUI task must not begin until the highest-severity
comparison-core blocker is fixed and re-audited.

GUI API readiness: **GUI API READY WITH CONDITIONS**. The result repository
exposes records, side descriptors, status/progress-compatible data, paging,
filters, navigation, field differences, and metadata lookup. It is not a safe
foundation for shipping UI behavior until terminal collision evidence is
immutable and schema-state validation is complete. The API also has no public
collision-member detail query, which should be resolved or explicitly bounded
before the conflict view is designed.

## Repository State

- Root: `/Users/cenvu/DEV/FSD`
- Branch: unavailable — not a Git repository
- Commit: unavailable — not a Git repository
- Git status: `BLOCKED — NOT A REPOSITORY`
- `git diff --check`: `BLOCKED — NOT A REPOSITORY`
- Pre-existing user changes: Git could not establish a baseline. Existing
  milestone implementation files and scratch files recorded by the preceding
  Writer handoff were preserved. No production implementation, test, schema,
  migration, Xcode project, or helper source was changed by this audit.

## Interrupted Task

This was an independent audit of the completed DeepSeek V4 Milestone 4
comparison-core Writer slice. The Writer claimed schema v6, transactional
v5-to-v6 migration, all three modes, metadata-only matching, profile freezing,
collision uncertainty, bounded traversal, cancellation/recovery, transient
lifecycle, GUI-ready APIs, 100,202 entries per side, 175 tests, and an isolated
end-to-end probe.

## Inputs Read

- `handoffs/CURRENT_HANDOFF.md`
- `docs/AGENT.md`, `docs/PRODUCT_STATE.md`, `docs/MVP_PLAN.md`
- `docs/PRD.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`
- `docs/TEST_PLAN.md`
- `docs/database/schema.sql`, `docs/database/verify.sql`
- Comparison sources in `FSD/Diff/`
- `FSD/Catalog/CatalogMigrations.swift`, `FSD/Catalog/CatalogDatabase.swift`
- `FSD/Scanner/SnapshotScanner.swift`, `FSD/App/FSDApp.swift`
- Comparison, mode, persistence, scale, end-to-end, and migration tests
- Xcode project references and build settings

## Verified Completed Work

- `FSD.xcodeproj` references all six comparison production files and all seven
  comparison test files; the project has a macOS 13.0 arm64 app and XCTest
  target with the bundled canonical schema resource.
- Schema v6 exists in `docs/database/schema.sql` and fresh bootstrap records
  version 6. `comparison_profiles.version`, `comparisons.profile_version`, the
  v6 terminal/result guards, and `idx_comparison_results_type` are present.
- `CatalogMigrations` contains explicit transactional v4-to-v5 and v5-to-v6
  steps. Existing migration tests cover both known v4 variants, v5-to-v6,
  rollback, current reopen, future-version rejection, integrity, and
  fresh/migrated object convergence.
- The engine performs metadata-only ordered keyset traversal and stores result
  rows and collision members in bounded persistence batches.
- The service implements snapshot-to-snapshot, live-to-snapshot, and
  live-to-live through transient scanner captures.
- The result repository provides stable comparison records, side descriptors,
  result paging, differences-only and per-outcome filters, deterministic
  navigation, field differences, and stored metadata lookup.
- Existing tests cover source removal/offline reopen, zero classification rows,
  source listing preservation, cancellation, transient cleanup, orphaned
  running-comparison recovery, and deterministic scale reruns.

## Partial Work

- Terminal immutability covers `comparisons` status/counts and
  `comparison_results` INSERT/UPDATE, but not collision groups or collision
  members. A completed comparison's uncertainty evidence can therefore be
  changed after finalization.
- `ExpectedState` checks only a subset of canonical triggers and indexes. It
  omits, among others, `idx_comparison_results_parent`,
  `idx_comparison_results_uncertain_group`, several source/identity/result
  triggers, and multiple baseline catalog indexes/triggers.
- The engine is page-bounded for ordinary keys but `EntryStream.consumeGroup`
  materializes an entire equal-key collision group. A pathological collision
  group can exceed the claimed page bound.
- The PRD requires aggregate-signature subtree skipping and matched-subtree
  collapse; the implementation records per-entry matched rows and does not
  implement aggregate-signature skipping. This limitation was documented by
  the Writer as KI-016, but the M4 plan had stale wording implying backend
  support.

## Work Not Started

- The visual comparison interface was not implemented, as expected for this
  backend Writer task.
- No independent manual acceptance was performed. Manual testing remains
  `NOT PERFORMED — DEFERRED BY OWNER`.
- The one-million-entry Milestone 5 gate was not run and was not required by
  the canonical M4 plan.
- No physical removable media or raw-device test was used in this audit.

## Files Changed

### Files changed by this audit

- `docs/PRODUCT_STATE.md` — rejected audit state and blockers.
- `docs/MVP_PLAN.md` — corrected M4 completion and aggregate-skip wording.
- `handoffs/FSD_M4_COMPARISON_CORE_AUDIT_R_20260804-150429.md` — this report.
- `handoffs/CURRENT_HANDOFF.md` — overwritten with this report after creation.

No production Swift, tests, schema, migrations, Xcode project, or helper
scripts were edited by this audit.

### DeepSeek-attributed implementation files inspected

Production: `FSD/Diff/ComparisonModels.swift`,
`FSD/Diff/ComparisonProfileRepository.swift`,
`FSD/Diff/ComparisonEngine.swift`,
`FSD/Diff/ComparisonResultRepository.swift`,
`FSD/Diff/ComparisonService.swift`,
`FSD/Catalog/TransientSnapshotLifecycle.swift`,
`FSD/Catalog/CatalogMigrations.swift`,
`FSD/Catalog/CatalogDatabase.swift`,
`FSD/Scanner/SnapshotScanner.swift`, `FSD/App/FSDApp.swift`, and
`FSD.xcodeproj/project.pbxproj`.

Tests: `FSDTests/TestSupport.swift`,
`ComparisonSemanticsTests.swift`, `ComparisonIdentityTests.swift`,
`ComparisonSnapshotStateTests.swift`, `ComparisonModeTests.swift`,
`ComparisonPersistenceTests.swift`, `ComparisonScaleTests.swift`,
`ComparisonEndToEndProbeTests.swift`, plus modified migration/catalog,
manual-substitute, condition, and JSON-export tests.

## Schema and Migration State

- Fresh schema: **verified version 6**; bundled schema resource is present at
  `/tmp/FSD-M4-DeepSeek-Audit-DerivedData/Build/Products/Debug/FSD.app/Contents/Resources/schema.sql`.
- v5-to-v6 migration: **verified by the existing migration tests** and by the
  clean full test run. The migration is transactional and records its version
  row last.
- v4-to-v5-to-v6 convergence: **verified by migration tests** for both known
  v4 variants and by fresh/migrated object comparisons.
- Rollback: **verified by tests** for failed v5 and v6 migration attempts; the
  recorded version remains unchanged and partial DDL is absent.
- Future and unsupported versions: **verified rejected**.
- `PRAGMA integrity_check`: fresh verify database `ok`; end-to-end and scale
  tests also passed integrity checks.
- `PRAGMA foreign_key_check`: clean in the end-to-end/scale tests and empty at
  the final canonical verify-script check.
- `docs/database/verify.sql`: direct execution returned shell status 1 because
  the script intentionally executes rejection fixtures without a suppression
  wrapper. The reported errors matched documented intended rejection cases;
  the script reached final `integrity_check = ok` and an empty foreign-key
  check. This is not counted as a clean process exit.
- Schema drift finding: `CatalogMigrations.ExpectedState` arrays do not cover
  every `CREATE TRIGGER`/`CREATE INDEX` in `schema.sql`. This violates the
  requirement that a catalog reporting v6 must be rejected if a required
  object was removed or altered.

## Condition C1–C6 State

- C1: **NOT PERFORMED — DEFERRED BY OWNER**. No manual acceptance was claimed.
- C2: technically implemented and covered by migration tests, but the M4
  audit found the newer `ExpectedState` inventory incomplete.
- C3: technically implemented and covered by prior milestone tests.
- C4: technically implemented and covered by prior milestone tests.
- C5: technically implemented and covered by prior milestone tests.
- C6: technically implemented and covered by prior milestone tests.

## History, Browsing, Search, and Export State

These Milestone 3 features were not reimplemented or audited in depth here.
The full suite compiled and passed their existing tests. They remain outside
the comparison-core verdict except where catalog initialization and schema
version handling were directly relevant.

## Provider Validation State

The ordinary full test run left two environment-gated `FilesystemMatrixTests`
skipped:

- `testCaptureExternallyPreparedMountedFilesystem()` —
  `FSD_MATRIX_SOURCE` was not set.
- `testReopenCapturedSnapshotWithTheSourceDetached()` —
  `FSD_MATRIX_OFFLINE_CATALOG` was not set.

No real removable media or physical raw devices were accessed. Native-provider
matrix claims from prior milestones were not independently rerun in this M4
audit. This audit therefore does not promote or invalidate those prior matrix
claims.

## Tests and Build Evidence

Environment:

- Xcode: `Xcode 26.3`, build `17C529`.
- Swift: `Apple Swift version 6.2.4` / swift-driver `1.127.15`.
- Host: macOS 15.7.7, arm64 MacBook Pro.

Independent clean build/test commands used a new DerivedData path:

```text
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-M4-DeepSeek-Audit-DerivedData \
  CODE_SIGNING_ALLOWED=NO clean

xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-M4-DeepSeek-Audit-DerivedData \
  CODE_SIGNING_ALLOWED=NO build

xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-M4-DeepSeek-Audit-DerivedData \
  CODE_SIGNING_ALLOWED=NO test
```

Results:

- Clean: **SUCCEEDED**.
- Build: **SUCCEEDED**, unsigned local build.
- Test result: **175 total, 173 passed, 0 failed, 2 skipped**.
- Test result bundle:
  `/tmp/FSD-M4-DeepSeek-Audit-DerivedData/Logs/Test/Test-FSD-2026.08.04_14-55-46-+0700.xcresult`.
- App: `/tmp/FSD-M4-DeepSeek-Audit-DerivedData/Build/Products/Debug/FSD.app`.
- App binary: Mach-O arm64; test bundle binary also Mach-O arm64.
- Build warnings: AppIntents metadata extraction skipped because there is no
  AppIntents dependency; test-link warnings note XCTest libraries built for a
  newer deployment target. No comparison-specific or non-Sendable compiler
  warning was emitted.
- Focused scale rerun passed one test and independently printed the evidence
  below.

## Current Failures

- Clean build: no failure.
- Full test suite: no failure; 2 environment-gated skips are listed above.
- Canonical verification script: expected nonzero process status from intended
  rejection fixtures; final integrity and foreign-key checks were clean.
- Audit failures: H1 terminal collision mutation and H2 incomplete schema
  expected-object inventory remain open.

## Canonical Comparison Semantics

Verified by source inspection, existing tests, and the independent full run:

- Orientation is left = reference/before and right = changed/after.
- Right-only is `added`; left-only is `removed`.
- Exact stored outcomes are `matched`, `added`, `removed`, `changed`,
  `ignored`, and `uncertain`.
- `changed` rows store deterministic `difference_flags`; field-level metadata
  lookup returns the left/right recorded values.
- Ignored rows are retained for transparency and excluded from summary counts.
- Inaccessible entries become `uncertain` rather than being claimed as added,
  removed, or matched.
- No result means content verification; no payload, hash, MIME, Magika, or
  classification access was found in the comparison implementation.

## Profiles

The three seeded built-ins were independently inspected and covered by tests:

- `Fast Metadata` id 1, version 1: item type and logical size; hidden items
  excluded; macOS service-file ignore rules.
- `Structure Only` id 2, version 1: item type only; same service-file rules.
- `Strict Metadata` id 3, version 1: item type, logical size, modified time;
  two-second timestamp tolerance; hidden items included; no service ignores.

The comparison row stores `profile_version`, and an existing test verifies the
version is frozen on the record. A separate repository-level profile editor is
not present, so monotonic version enforcement for arbitrary future profile
edits was not independently demonstrated.

## Identity and Collision Behavior

Verified behavior includes sensitive/sensitive case-preserving matching,
folded matching when either side is insensitive or unknown, POSIX-style
case-folding through the existing path identity helper, NFC/NFD equivalence,
normalization-version mismatch rejection, and uncertain collision results with
persisted members rather than arbitrary pairing. The existing identity suite
passed 9 tests.

The implementation can retain a collision group with more than two members,
but there is no dedicated independent test for a very large group or for every
two-sided multi-member shape. Raw filename-byte preservation is not claimed.

## Persistence and Immutability

Verified:

- running comparisons accept result rows;
- terminal comparison status/counts are guarded;
- terminal result INSERT/UPDATE is guarded;
- summary counts are recomputed from persisted result rows;
- completed snapshots and entries remain untouched;
- classification rows remain zero.

Rejection-level defect reproduced directly with SQLite: after a comparison was
set to `complete`, inserting a row into `comparison_collision_groups` and then
`comparison_collision_members` succeeded (`COUNT(*) = 1` for each), while a
late ordinary result row was correctly rejected by
`Cannot add results to a terminal comparison`. Collision-group/member INSERT,
UPDATE, and DELETE paths need equivalent terminal protection, with tests.

## Cancellation and Recovery

The full suite independently passed comparison cancellation during matching,
live-capture cancellation, cancellation before work, transient cleanup,
workspace disposal, and orphaned running-comparison recovery to `failed`.
The shared locked cancellation/finalization token prevents the tested
cancel-to-complete race. Repeated recovery behavior is covered by the existing
mode/lifecycle tests. No deadlock or premature complete state was observed.

## Scale Reproduction

The canonical M4 gate is the 100,000-entry class; the one-million-entry class
is assigned to Milestone 5 by `docs/TEST_PLAN.md` and was not run.

Focused independent run:

- left entries: 100,202;
- right entries: 100,202;
- result counts: 100,001 matched, 100 changed, 101 added, 101 removed;
- comparison duration: 16.015 seconds inside the test (24.954 seconds test
  case including setup/persistence);
- first page latency: 0.0050 seconds;
- differences-only latency: 0.0316 seconds;
- test result: passed;
- full suite cancellation and deterministic rerun tests also passed;
- no peak-memory measurement was made;
- implementation inspection found no complete-tree array/dictionary, but a
  single equal-key collision group is materialized without an explicit cap.

## End-to-End Probe

`ComparisonEndToEndProbeTests.testEndToEndProbe` passed in the independent full
run. It generated two temporary folders, captured both through the production
scanner, ran live-to-live, removed the source folders, ran offline
snapshot-to-snapshot, reopened the isolated catalog, read stored results, and
asserted unchanged source listings, zero classification rows, integrity `ok`,
and an empty foreign-key check. Existing mode tests separately cover
live-to-snapshot and transient cleanup. This evidence is **AUTOMATED VERIFIED**
and not manual acceptance or USER-OBSERVED evidence.

## Unverified Claims

- No manual/user-observed launch, capture, cancellation, force-quit, or
  disconnected-source acceptance was performed.
- No independent native filesystem matrix rerun was performed in this audit;
  environment-gated probes were skipped because their override variables were
  absent.
- No one-million-entry run or peak-memory measurement was performed.
- Very-large collision-group behavior, monotonic profile-edit enforcement, and
  every two-sided collision shape were not independently exercised.

## GUI Backend Contract

The backend exposes the required ordinary GUI contract: comparison list and
record, side descriptors and warning state, status/progress-compatible data,
summary counts, bounded pages, all/differences/added/removed/modified/
unchanged/conflicts/ignored filters, stable next/previous navigation,
field-level differences, and left/right metadata lookup.

Conditions before Gemini work:

1. Fix and test collision-group/member terminal immutability.
2. Complete schema expected-object validation and test drift rejection.
3. Decide whether the conflict view needs a public collision-member query;
   currently the repository exposes an uncertain result row but not its member
   list.

## DeepSeek Effectiveness Scorecard

| Area | Result | Evidence |
|---|---|---|
| Scope completion | PARTIAL | Backend slice exists; GUI is correctly deferred, but audit blockers remain. |
| Build correctness | PASS | Clean unsigned arm64 build passed. |
| Test correctness | PARTIAL | 175-test suite passes, but missing tests allowed the two schema defects. |
| Comparison semantics | PASS | Orientation, outcome names, flags, ignored and inaccessible behavior pass. |
| Identity and collision safety | PARTIAL | Matching/collision pairing is safe; terminal collision evidence is mutable. |
| Schema and migration quality | FAIL | Migration path passes, but ExpectedState coverage is incomplete. |
| Cancellation and recovery | PASS | Full suite covers cancellation, lifecycle, and orphan recovery. |
| Bounded-memory design | PARTIAL | Ordered paging passes scale; one collision group can be unbounded. |
| Backend API readiness | PARTIAL | Broad API is usable with conditions; collision detail API is absent. |
| Documentation and Handoff accuracy | PARTIAL | Writer recorded KI-016 but claimed complete terminal integrity despite omissions and left stale aggregate wording. |
| Scope discipline | PASS | No payload comparison, classification runtime, Magika, network, or GUI implementation was added. |
| Regression safety | PARTIAL | Existing regressions pass; drift/collision-terminal cases are uncovered. |

Score: **4 PASS / 12 criteria**. Independent test result: **175 total, 173
passed, 0 failed, 2 skipped**, plus the focused scale test passed. DeepSeek
effectiveness rating: **EFFECTIVE WITH SUPERVISION**. The implementation is
substantial and mostly correct, but the omitted database-boundary cases are
too important to accept without corrective review.

## Findings by Severity

### High / rejection-level

- **H1 — Terminal collision evidence is mutable.** `schema.sql` and
  `CatalogMigrations.migrationToVersion6` guard comparison rows and result rows,
  but not `comparison_collision_groups` or `comparison_collision_members`.
  Direct SQLite proof allowed post-terminal group/member insertion. This can
  alter the explanation of a completed uncertain result.
- **H2 — v6 schema drift can be silently accepted.** `ExpectedState` does not
  enumerate all canonical v6 triggers/indexes. A deleted required object can
  coexist with recorded version 6 and pass the current open-time inventory.
  This violates the explicit no-silent-drift audit requirement.

### Medium

- **M1 — Collision groups are not page-bounded.** `consumeGroup` retains every
  equal-key row in an array; a pathological key can defeat the normal page
  memory bound.
- **M2 — Aggregate-signature subtree skipping is not implemented.** This is a
  documented KI-016 and not a failure of the 100k correctness run, but it is a
  mismatch with the PRD performance behavior and the stale M4 plan wording.
- **M3 — Collision-member read API is absent.** The GUI can filter uncertain
  rows but cannot directly retrieve all member metadata through the public
  result repository.
- **M4 — Broad `@unchecked Sendable` remains.** The build emits no
  comparison-specific concurrency warning and the database/token locks are
  clear, but the audit did not prove all future concurrent uses of scanner,
  engine, or service under stricter Swift concurrency.

### Low

- **L1 — `verify.sql` intentionally returns process status 1** because expected
  rejection fixtures are not wrapped in an error-suppression harness. Its
  final integrity/FK checks were clean and the reported errors matched the
  documented rejection cases.
- **L2 — Peak memory was not measured.** The design and scale result are
  bounded-by-inspection evidence, not a peak-memory acceptance measurement.
- **L3 — Two ordinary matrix tests are environment-gated skips** because their
  required override variables were not set; no real media was touched.

## Files Outside Intended Scope

No out-of-scope production behavior was introduced according to the inspected
source and project references. The prior Writer retained
`modify_comparison_project.py` at the repository root as a project-wiring
helper; it is not runtime code and is unnecessary after the project references
are wired. It was not modified or removed by this audit.

## Duplicated or Unnecessary Implementation

The comparison service and engine intentionally separate live capture from
offline merge and are not duplicate implementations. The main unnecessary
artifact is the retained project-wiring helper noted above. No duplicated
comparison algorithm was found.

## Estimated Corrective Rework

**MEDIUM** — add terminal guards for collision groups/members and their
mutation paths, extend `ExpectedState` to the complete canonical object
inventory, add focused regression tests, rerun migration/fresh convergence and
the full comparison suite, then repeat this audit boundary. The collision-group
memory cap and collision-member read API are follow-up conditions unless they
become required by the GUI contract.

## Manual Testing Status

**NOT PERFORMED — DEFERRED BY OWNER.** The isolated end-to-end probe and test
host launch are automated/Agent-run evidence only and are not manual acceptance.

## Decisions

- Verdict is **REJECT**, not APPROVE WITH CONDITIONS, because the audit rules
  classify mutation of a completed comparison conclusion and silent schema
  drift under one recorded version as rejection-level.
- The M4 scale decision follows canonical text: 100,202 entries per side is
  the M4 class; 1,000,000 entries is the M5 gate.
- No production fix was applied during this Reviewer task.

## Constraints Preserved

- No production source, tests, schema, migration, Xcode project, or helper
  source was modified by the audit.
- No payload reads, hashing, classification access, Magika, network access,
  source writes, filesystem mutation, removable-media access, or raw-device
  access was introduced.
- No commit, push, GitHub access, Git initialization, reset, restore, clean,
  or destructive repository operation was performed.
- Manual testing remains deferred and is not relabelled as passed.

## Known Issues

The high-severity H1/H2 findings block comparison-core approval. KI-016,
unbounded pathological collision groups, absent collision-member lookup, broad
unchecked Sendable, unmeasured peak memory, and environment-gated matrix skips
remain as documented conditions.

## Exactly One Next Action

Fix the single highest-severity comparison-core blocker.

## Safe Resume Boundary

The safest resume boundary is the schema boundary: preserve the existing
comparison engine, service modes, profiles, migration steps, passing tests,
and scale fixtures. Correct H1 first, then H2, add focused regression tests,
and rerun the full audit evidence.

## Resume Context

Resume at the schema boundary, beginning with H1: add and test terminal
immutability for collision groups and members across INSERT/UPDATE/DELETE,
then complete `ExpectedState` inventory validation (H2). Do not recreate the
comparison engine, modes, profiles, migration path, or existing passing scale
fixtures. After the corrective Writer work, run a fresh independent comparison
core audit before Gemini starts the visual interface.
