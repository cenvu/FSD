# Task058 Local PhysicalDrive Identity Foundation — Worker return

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD2_IMPLEMENTATION_PHYSICAL_DRIVE_FOUNDATION
HANDOFF_ID=handoffs/FSD_FSD2_LOCAL_PHYSICAL_DRIVE_IDENTITY_FOUNDATION_058_D_20261018-232736.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=cb60fc3161d0fddf57d145c0692a910744ed9cfd
REMOTE_HEAD=cb60fc3161d0fddf57d145c0692a910744ed9cfd
LAST_VERIFIED_AT=2026-10-18T23:27:36+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|docs/AGENT.md|STATE/PROJECT_STATE.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|handoffs/CURRENT_HANDOFF.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|.agents/skills/fsd-independent-review/SKILL.md|docs/DECISIONS.md|docs/ARCHITECTURE.md|docs/TEST_PLAN.md|docs/MVP_PLAN.md|docs/PRODUCT_STATE.md|docs/UX_UI_SPEC.md|docs/database/schema.sql|FSD/Catalog/CatalogDatabase.swift|FSD/Catalog/CatalogMigrations.swift|FSD/Catalog/PhysicalDriveRepository.swift|FSD/Model/PhysicalDriveModels.swift|FSDTests/PhysicalDriveIdentityTests.swift|FSDTests/PhysicalDriveMigrationTests.swift|scripts/check_control_plane.py
CURRENT_PHASE=POST_V0_1_FSD2_FOUNDATION
CURRENT_GATE=FSD2_LOCAL_PHYSICAL_DRIVE_IDENTITY_FOUNDATION_058
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_FOR_LOCAL_MANUAL_FOUNDATION;REAL_HARDWARE_PROOF_AND_FUTURE_FEATURES_PENDING
PROPOSED_NEXT=WAIT(BRAIN_REVIEW_TASK058_LOCAL_PHYSICAL_DRIVE_FOUNDATION)
NO_AUTO_NEXT=YES

## Task lock and authority

PROJECT=FSD
TASK_ID=FSD2_LOCAL_PHYSICAL_DRIVE_IDENTITY_FOUNDATION_058
ROLE=WORKER
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
BASE_HEAD=cb60fc3161d0fddf57d145c0692a910744ed9cfd
UPSTREAM_HEAD=cb60fc3161d0fddf57d145c0692a910744ed9cfd
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=LOCAL_OPAQUE_ID_TYPED_EVIDENCE_MANUAL_ASSOCIATION_ADDITIVE_V10_SYNTHETIC_ONLY
ALLOWED_PATHS=18_IMPLEMENTATION_DOC_TEST_PROJECT_PATHS_LISTED_BELOW|one_new_history|CURRENT|Worker_ledger_event|Desktop_transport
FORBIDDEN_PATHS=ACCEPTED_STATE|RULE_PROMOTION_LEDGER|OLD_HISTORIES|UNRELATED_PRODUCT|SOURCE_MEDIA|OWNER_CATALOG|HARDWARE|DRIVE_SETS|UI|AUTO_CAPTURE|SAVE_COMPARISON|RELEASE|TASK059
SUCCESS_CRITERIA=DURABLE_LOCAL_IDENTITY|TYPED_EVIDENCE|EXPLICIT_REVISION_BOUND_MANUAL_HISTORY|ATOMIC_ADDITIVE_SCHEMA|SYNTHETIC_PROOF|REGRESSION_BUILD_REVIEW|FINALIZER
VALIDATIONS=ARM64_DEBUG_RELEASE|XCTEST|INTEGRITY_FK|EXPECTED_STATE|PARITY|ROLLBACK_REOPEN|INDEPENDENT_REVIEW|SCOPE_HASH|DIFF_CHECK|CANONICAL_PRE_POST
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY

Canonical accepted State explicitly authorizes exactly ACTION(Task058); the
exact task is the Owner's production-code exception to Wave A's earlier ban.
Worker-local result: PASS_WITH_ADVISORY. BRAIN classification remains pending.
Owner subsequently explicitly approved six stale current-version expectation
corrections in five extra existing test files, through two asynchronous replies:
ManualSessionASubstituteTests and MilestoneConditionTests (one each), then
M5ReliabilityTests (two), ComparisonGUISourceBoundaryTests and
FinalScaleSnapshotTests (one each). The GUI boundary assertion also requires
`import FSD`. These are the only five allowlist exceptions; no related refactor.

Initial physical main was clean at 18dd2d4cdfc498a0e4f386325819a79ff6517eed.
Non-destructive fetch found exactly two BRAIN control-state commits ahead.
Their full State/ledger/event diff was inspected; safe ff-only advanced to the
expected baseline above. Origin https://github.com/cenvu/FSD.git; fresh final
fetch reconfirmed HEAD/upstream equality and 0/0 before finalization. No
reset/stash/clean/rebase/force or unknown-work removal. All baseline tracked
bytes were captured before edits (symlinks hashed by link text), and 110 old
historical handoffs remain identical. Accepted State and rule ledger are untouched.

Read authorities: CURRENT HOT first; kernel/local Owner policy, Compact/FULL and
all three skills; accepted State; ADR-004/019/020/023/024/025/026/036/037/038;
architecture identity and migration contracts; TEST_PLAN §§10/13; MVP Wave A;
product/UX §§8–9; canonical schema, migrations, database, repositories and tests.

## Actual production slice and limits

- PhysicalDriveID wraps a random UUID, never an observed identifier. Creation is
  explicit, with optional nonunique local label, explicit-local admission and
  provenance. Stable IDs survive reopen. Revision-checked retirement is a
  tombstone; SQL rejects hard deletion, revival and invalid revision transitions.
  `hardwareVerified` is always false.
- Frozen local observations store distinct opaque subject IDs, caller-supplied
  session UUID/revision, scope, unresolved state, provenance and observation time.
  There is no implemented mount-session service or live observation adapter.
- Evidence is typed by device/media/partition/volume/mount-session scope, kind,
  provider and property. It retains value/status/provenance/revision/time. Host
  dependency groups collapse aliases across providers. UUID candidates are
  syntax-checked and canonically represented; malformed/blank/NUL/oversized,
  wrong-scope and duplicate provider/property input rejects atomically. Repository
  input is capped at 32 facts, 1024 UTF-8 bytes for value/provenance and 256 for
  property. Validated facts are never treated as hardware proof.
- Manual association is an explicit operation over observation ID/revision and
  stable local target ID/revision. Association assertion revision starts at zero;
  associate/correct/revoke appends a new event with operation UUID, prior-event
  pointer, actor, reason and time. Exact operation retries return the original
  event; changed intent, missing target or stale writers reject without mutation.
  Separate connections recheck inside BEGIN IMMEDIATE. Conflicting observations
  cannot be associated; revocation remains available after retirement/conflict.
- The association boundary intentionally does not reference legacy `volumes`.
  New observations require fresh selection. Correction cannot reattribute any
  old snapshot or transfer any historical capture fact. No identity backfill,
  capture receipt, history merge or capture admission is implemented.
- Resolution returns Unknown/Ambiguous/Conflict or explicit ManualAssociation.
  Alias contradictions and retired manual targets fail closed. UniqueStrongMatch
  is reserved as a model case with no producer. Approved real strong profiles=0;
  no scoring, UUID matcher or automatic creation/reconnect/capture exists.
- Reads use PK/indexed local-ID lookups and keyset pages clamped to 1–200 with
  truncation flags; evidence reads are bounded. No source I/O, hardware API,
  mount listener, provider dependency or UI was added.

## Schema and migration

Current schema is v10. Four additive tables: physical_drives,
identity_observations, identity_evidence, manual_drive_associations. Two new
named indexes and ten guards; canonical total inventory is 17 tables, 19 named
indexes and 40 triggers (SQLite internal autoindexes excluded). No legacy table,
FK, normalization constraint or immutability trigger was changed.

CatalogMigrations registers explicit v9→v10 DDL. Tables/indexes/triggers share
canonical definitions with ExpectedState; fresh SQL matches. New table DDL is
verified exactly on every open, including columns, CHECKs, FKs and uniqueness.
The current-version inventory is validated inside the transaction BEFORE the
version row/commit, so successful but missing/altered DDL rolls back too.
Unsupported/missing versions reject before changing persistent journal mode;
per-connection foreign-key safety is still enabled before repositories operate.
Lock ownership and ordinary startup recovery remain unchanged.

Synthetic Swift tests cover both v4 variants and v5/v6/v7/v8/v9 → v10, every
legacy relation's row preservation, zero invented identities, exact fresh/new
DDL and legacy-column parity, existing trigger/index definitions, reopen without
replay, and newer-version rejection. Sixteen v10 statements yield 17 injected
DDL/version failure boundaries; each restores original schema/version and
successfully migrates/reopens on retry. Missing/altered successful DDL also
rolls back. Unsupported v2/v999 DELETE-journal catalogs retain exact file bytes.
No Owner catalog was opened/migrated or authorized for migration.

## Executed evidence and ordinary debugging

All identity/migration proof uses production Swift over unique temporary
synthetic catalogs. Existing regressions use generated catalogs/files and the
existing automatic XCTest host catalog isolation. Established GUI regressions
may refresh their generated ignored screenshot fixtures; no Owner media is used.
Raw receipts are in ignored `.ai-scratch/task058/`; durable executable tests are
in the repository. No empirical physical-device evidence is claimed.

Commands (all from repo; destinations `platform=macOS,arch=arm64`):

1. Initial causal RED: `xcodebuild test -project FSD.xcodeproj -scheme FSD
   -configuration Debug -destination 'platform=macOS,arch=arm64'
   -derivedDataPath .ai-scratch/task058/DerivedData
   -only-testing:FSDTests/PhysicalDriveIdentityTests` — one test failed for the
   intended baseline v9/missing physical_drives boundary (two assertions).
   `red.log`; initial GREEN after implementation: 1/1; expanded 45/45, then 51/51.
2. Unsupported-byte causal RED: same command with derived data
   `.ai-scratch/task058/UnsupportedRedDD` and only
   `PhysicalDriveMigrationTests/testUnsupportedCatalogDoesNotChangePersistentJournalModeOrBytes`
   — intended failure: v2/v999 changed DELETE→WAL despite rejection. Fixed by
   moving WAL configuration after version checks; no global configuration change.
3. Final focused suites: PhysicalDriveIdentityTests, PhysicalDriveMigrationTests,
   SchemaMigrationTests, CatalogDatabaseTests, ExpectedStateInventoryTests —
   65/65 PASS, zero failures/skips. Breakdown 16 + 8 + 25 + 6 + 10.
   `focused-final.log` and its xcresult receipt.
4. Final broad regression: `python3 .ai-scratch/task058/run_final_regressions.py`
   invokes xcodebuild test with the explicit 34-suite selection saved in
   `final-regression-command.json` — 491/491 PASS, zero failures/skips, exit 0.
   `regressions-final.log`; xcresult
   `.ai-scratch/task058/FinalDebug/Logs/Test/Test-FSD-2026.10.18_23-21-41-+0700.xcresult`.
   Includes complete schema/catalog/inventory suites, snapshot lifecycle/history/
   Collections/read-only boundaries, recovery/lock tests, comparison semantics/
   persistence/GUI source boundaries, classification isolation/security/runtime,
   browse/search/export. The generated disk-image mount test is explicitly
   excluded; external device/catalog probes and nonrequired million-entry
   comparison/memory suites were not selected.
5. Final supplemental `xcodebuild test-without-building` with FinalDebug and only
   the unchanged helper call-count test, CancellationRaceStressTests,
   ComparisonScaleTests, and the corrected million-entry snapshot reopen test —
   15/15 PASS, zero failures/skips, exit 0; supplemental-final.log. The million fixture has 1,002,182 generated entries; it is
   database scale/reopen proof, never a source scan or hardware observation.
6. `xcodebuild clean build -project FSD.xcodeproj -scheme FSD -configuration Debug
   -destination 'platform=macOS,arch=arm64' -derivedDataPath .ai-scratch/task058/FinalDebug`
   and equivalent Release/FinalRelease — both exit 0, BUILD SUCCEEDED. Final
   production sources match the reviewed candidate. Logs build-debug-final.log
   and build-release-final.log. Existing unrelated compiler warnings retained.
7. `python3 .ai-scratch/task058/verify_scope.py` — PASS: exact allowed paths,
   protected baseline hashes/110 old histories, append-only Architecture/Test Plan,
   assertion-only approved exceptions, no new source/device APIs, legacy schema
   unchanged except version/header/additive block, generated canonical SQLite
   integrity/FK checks. `git diff --check` PASS. Production XCTest separately
   executes integrity_check, foreign_key_check and index query-plan assertions.

Earlier exploratory broad run: 529 executed, 524 passed, five failing test cases
(seven failing assertions). Four cases were stale v9 expectations corrected with
Owner's explicit allowlist permission. The fifth was an unchanged classifier
helper LLDB launch/attach-pause failure; isolated final rerun passed without
product/helper/test weakening. A subsequent 491-case run exposed the remaining
three stale expectation cases; corrected as authorized, final full selection
passed. One intermediate compile failure from the newly dynamic source-boundary
assertion was corrected with its necessary `import FSD`; final build/test passes.
Earlier failure xcresults and JSON summaries remain in task scratch. No failing
required gate is waived or reported as passing. No model/harness benchmark ran.

## Independent review and final exact scope

Required separate read-only review used fsd-task-execution plus
fsd-independent-review. Reviewer inspected every changed source/schema/test/
project/doc path; no mutations, Owner data access or reviewer test run. Findings:
(1) inventory validation must precede migration commit — repaired and tested;
(2) an initial negative case failed in a trigger before FK evaluation — added
causal wrong-revision composite FK test and outer rollback assertion. Both were
re-reviewed. The later unsupported-version byte-preservation fix and all six
Owner-approved version expectation corrections were independently re-reviewed.
Final conclusion: no remaining material findings. Evidence limitations are
source review plus observed execution receipts, not independent empirical proof.

Final 18-path aggregate SHA256 (sorted path + NUL + per-file SHA256 + LF):
`0da7e09d9b981f6dc3aef81372d318a3012e9dabedabc3c1494b4ea428100414`.
Reviewer timestamp 2026-10-18T23:22:32+07:00; Worker freshly confirmed identical.

Exact implementation/docs/project/test tracked paths:
- `FSD.xcodeproj/project.pbxproj`
- `FSD/Catalog/CatalogDatabase.swift`
- `FSD/Catalog/CatalogMigrations.swift`
- `FSD/Catalog/PhysicalDriveRepository.swift`
- `FSD/Model/PhysicalDriveModels.swift`
- `FSDTests/CatalogDatabaseTests.swift`
- `FSDTests/SchemaMigrationTests.swift`
- `FSDTests/PhysicalDriveIdentityTests.swift`
- `FSDTests/PhysicalDriveMigrationTests.swift`
- `docs/database/schema.sql`
- `docs/ARCHITECTURE.md`
- `docs/TEST_PLAN.md`
- `docs/PRODUCT_STATE.md`
- `FSDTests/ManualSessionASubstituteTests.swift`
- `FSDTests/MilestoneConditionTests.swift`
- `FSDTests/M5ReliabilityTests.swift`
- `FSDTests/FinalScaleSnapshotTests.swift`
- `FSDTests/ComparisonGUISourceBoundaryTests.swift`

Reporting adds exactly this history, CURRENT full mirror, one Task058 Worker
ledger row and one append-only worker_return event. Technical SHA is the known
baseline/basis above; publication resolves from this historical file's Git commit
and the Desktop final Git receipt, not a self-referential future SHA here.
No accepted BRAIN State, ADR status, rule ledger or previous history is changed.

## Requirement accounting — execution postflight

Every row below is EVIDENCED; none is a claim of hardware or full acceptance.

| ID | Requirement | Actual evidence |
|---|---|---|
| R01 | Authority/baseline/one active task | Accepted ACTION, safe FF, fresh equal main/upstream, task lock |
| R02 | Exact scope and Owner work preservation | Hash baseline, allowlist, six explicitly approved assertion corrections |
| R03 | Opaque local entity/provenance/revision/lifecycle | Models/repository/schema; ID, reopen and retirement tests |
| R04 | Typed evidence subject/provider/value/provenance | All-scope roundtrip, bounds, validation, host dependency groups |
| R05 | Deliberate ID-bound association/correction | Atomic expected target/observation/assertion revisions; event chain |
| R06 | Safe resolution boundary | No strong producer, profile count zero, explicit manual remains manual |
| R07 | Mandatory test 1: fresh schema | Fresh identity/schema/catalog/inventory suites |
| R08 | Mandatory test 2: v9 upgrade | Legacy preservation test and production migration |
| R09 | Mandatory test 3: historical chains | Both v4 variants and v5/v6/v7/v8/v9 parity test |
| R10 | Mandatory test 4: no invented history identity | All four new relations empty after seeded legacy migration |
| R11 | Mandatory test 5: preserve all facts | Every legacy relation before/after row equality |
| R12 | Mandatory test 6: duplicate display labels | Two same labels yield distinct local UUIDs |
| R13 | Mandatory test 7: stable reopen | Drive IDs/records identical on generated catalog reopen |
| R14 | Mandatory test 8: valid target only | Explicit success; unresolved record alone has no association |
| R15 | Mandatory test 9: invalid target no mutation | Missing targets/observations reject; event count unchanged |
| R16 | Mandatory test 10: idempotency | Same operation ID exact retry; changed intent rejects |
| R17 | Mandatory test 11: stale revision | Drive/observation/assertion and separate-connection stale writer |
| R18 | Mandatory test 12: correction provenance/facts | Prior-event/actor/reason chain, legacy rows unchanged |
| R19 | Mandatory test 13: UUID/path/name no fallback | Duplicate/missing UUID and reused path/name remain Unknown |
| R20 | Mandatory test 14: unresolved never verified | Unknown/Ambiguous/Conflict tests and hardwareVerified false |
| R21 | Mandatory test 15: no real strong profile | Constant zero; no repository UniqueStrongMatch return |
| R22 | Mandatory test 16: typed/bounded evidence | All kinds/scopes/provenance; malformed/oversized/blank/NUL rejection |
| R23 | Mandatory test 17: alias independence | Shared group/canonical spelling; alias disagreement Conflict |
| R24 | Mandatory test 18: no cascade | Retirement/no-delete tests; no FK into legacy graph; facts unchanged |
| R25 | Mandatory test 19: FK/transaction rollback | Actual FK engine message, outer transaction and injected failures |
| R26 | Mandatory test 20: DDL/version rollback | 17 failure boundaries plus invalid inventories; original state restored |
| R27 | Mandatory test 21: no replay reopen | Version timestamps stable; poisoned migration never reruns |
| R28 | Mandatory test 22: reject future versions | v999 version/schema and bytes/journal unchanged |
| R29 | Mandatory test 23: bounded/indexed reads | Clamped keyset pages/truncation; EXPLAIN QUERY PLAN assertions |
| R30 | Mandatory test 24: legacy invariants | Final regression selection and scale/recovery supplement |
| R31 | Mandatory test 25: no source/device dependency | Independent changed-source review, scope script, existing boundary suites |
| R32 | Clean arm64 Debug/Release | Both final clean build commands exit zero |
| R33 | Schema/transaction/source/error review | Separate independent review, repaired findings, matching final digest |
| R34 | Truthful docs/ADR/acceptance boundaries | Three narrow docs, unchanged ADRs and accepted State |
| R35 | Exact diff/protected bytes/integrity | Scope/hash checks, git diff --check, canonical synthetic SQLite checks |
| R36 | One task/return boundary | No Task059, no real media/catalog, one pending Worker return/proposal |

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=36
WORKER_REQUIREMENTS_EVIDENCED=36
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

## Finalizer closure and BRAIN return boundary

Execution postflight is complete on the reviewed candidate. Canonical finalizer
closure follows: CURRENT/Worker projection/Desktop, prepublication checker,
normal commit/push/fetch verification, clean/synced postchecker and final Desktop
Git receipt. These are not preclaimed in this immutable prepublication source;
the executed final receipts/publication SHA belong in tool output and Desktop.

Only local persistence, typed evidence, manual association and synthetic
Swift/SQLite referential/migration safety are proved. Hardware identity,
reconnect accuracy, mounted-device detection, UniqueStrongMatch, H01–H14,
Auto Capture, Drive Sets, capture identity receipts, Save Comparison, physical
power-loss testing and FSD2 Full/internal acceptance are not proved. The three
ADRs remain Proposed / Owner Direction Approved / Technical Proof Pending.
Owner catalog migration is not authorized. Manual E2E/VoiceOver and existing
privacy residuals remain separate accepted-state limitations.

BRAIN should independently re-anchor and classify Task058. Worker chooses no
next implementation and stops after publication. Transport:
`/Users/cenvu/Desktop/04_FSD_BRAIN.md`.
