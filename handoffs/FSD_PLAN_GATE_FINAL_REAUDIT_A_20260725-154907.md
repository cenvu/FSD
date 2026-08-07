# FSD Unified Session Handoff

AGENT: Claude (FINAL INDEPENDENT PLAN-GATE AUDITOR role assignment)
ROLE: AUDIT
TASK ID: FSD-PLAN-GATE-FINAL-REAUDIT-0725-12
PHASE: AUDIT AND PLANNING

## 1. Session Identity

- **Objective:** Independently determine whether the third Plan Gate correction round (`handoffs/FSD_PLAN_GATE_CORRECTION3_F_20260725-153912.md`) closes the six findings from `handoffs/FSD_PLAN_GATE_REAUDIT2_A_20260725-000114.md` (FSD-REAUDIT2-001 through 006), and whether FSD may now be authorized to begin Phase 0A.
- **Method:** No claim in the correction Handoff was accepted on the correcting agent's word. Every schema-level claim was independently reproduced against fresh SQLite databases built outside the repository, using self-authored fixtures. Every document claim was independently re-greped against live files, repository-wide (`docs` and `handoffs`, not `docs` alone).
- **Scope discipline:** No schema, fixture, or canonical document was modified. No Git repository was initialized. No CodeGraph index was created or queried. No Phase 0A work was started. Exactly one Handoff file was created by this session (this file).

## 2. Executive Decision

**APPROVE — READY FOR PHASE 0A**, with required corrections carried forward that block Phase 0 (real catalog/persistence code) but not Phase 0A (the disk-image-only feasibility spike).

The third correction round closed five of the six findings this session was asked to verify, each independently reproduced, not re-asserted:

- **FSD-REAUDIT2-001** (filesystem cardinality) — **CLOSED.** All three previously-cited live instances are fixed, including the one that sat directly inside Phase 0A's own objective statement in `FILESYSTEM_FEASIBILITY_PLAN.md`. `MVP_PLAN.md` and `DECISIONS.md` ADR-014 are also fixed, the latter now explicitly labeling the old "nine-filesystem" framing as a historical miscount rather than leaving it ambiguous.
- **FSD-REAUDIT2-003** (collision result-path exclusivity) — **CLOSED.** All ten required tests behave exactly as specified: nine forbidden writes rejected, the one valid control write accepted, on both INSERT and UPDATE paths.
- **FSD-REAUDIT2-004** (SQLite connection policy) — **CLOSED.** `ARCHITECTURE.md` now states a mandatory, explicit distinction between database-persistent and per-connection settings, and requires a startup assertion; `TEST_PLAN.md` adds the corresponding test.
- **FSD-REAUDIT2-005/006** (hygiene, README staleness) — **CLOSED.** Zero live "a app extension" instances, zero trailing whitespace, zero merge markers, and `README.md`'s Status section is now accurate.

**FSD-REAUDIT2-002** (normalization-compatibility identity) is **only partially closed**. Genuine, verified progress: the schema `DEFAULT` was removed (any INSERT that omits or nulls the column is now rejected outright), an explicit blank string is rejected at completion, and `DECISIONS.md` ADR-009 now states one coherent runtime-identity format, resolving the three-way ADR/schema mismatch this task's prior round found. But independent fixture testing (§8) confirms the completion-time guard is a single hardcoded substring blacklist (`= '' OR LIKE '%UNRECORDED_PLACEHOLDER%'`), exactly the narrow-validation risk this task's own brief asked to check for by name. A whitespace-only value (`'   '`) and any other arbitrary fake value not containing that exact substring — independently tested: `UNKNOWN`, `PLACEHOLDER`, `NOT_SET`, `PENDING` — all reach `complete` status completely unblocked.

This finding is real and must be corrected before Phase 0. It does **not** block Phase 0A: `FILESYSTEM_FEASIBILITY_PLAN.md` §1 and `MVP_PLAN.md`'s own two-gate model (independently re-confirmed unchanged, §16) state Phase 0A is a disk-image-only spike that "do[es] not touch the SQLite catalog... may run in parallel with R0's corrective work," prints to stdout, and creates no snapshot rows at all — the normalization-identity field is never written or read by the task this audit is asked to authorize.

Two further issues were newly discovered during this session's own independent reproduction, not part of the tracked FSD-REAUDIT2 list (§14, FSD-FINAL-REAUDIT-002 and -003): `docs/database/verify.sql`'s normalization-version backfill is incomplete (2 of 17 snapshot `INSERT`s still omit the column, causing genuine cascading test failures unrelated to what those fixtures were meant to prove), and `docs/TEST_PLAN.md` line 201 still asserts an expected test outcome ("schema versions 1, 2, and 3 all recorded") that contradicts the schema's actual, correct, and repeatedly-independently-verified behavior (`schema_migrations` contains exactly one row, `3`). Neither blocks Phase 0A; both should be fixed before Phase 0 so future test-writers do not inherit a false expectation or an untrustworthy regression suite.

## 3. Repository State

- `FSD_ROOT` resolves to `/Users/cenvu/Desktop/DEV/FSD` (the `Dev` spelling is the identical inode on case-insensitive APFS).
- No `.git` directory — confirmed via `git status --short` (exit 128) and `git diff --check` (exit 0, no repository to diff against; the "usage" message is `git`'s own response to being given no comparable index). Not initialized, per constraints.
- No `.codegraph` directory.
- No production source of any kind anywhere in the tree: `find` for `*.swift`, `*.m`, `*.mm`, `*.c`, `*.cc`, `*.cpp`, `*.xcodeproj`, `Package.swift` returned zero results.
- `docs/database/schema.sql` is 548 lines (up from 546 in the previous round), still declares schema version 3; a fresh database's `schema_migrations` table contains exactly one row, `3`.
- `docs/database/verify.sql` is unchanged in line count (408) from the previous round but its content changed materially (most, not all, `INSERT INTO snapshots` statements gained an explicit `normalization_version` value).
- `docs/FSD_PLAN_GATE_REAUDIT_GPT56SOL.md` remains absent from `docs/`; no new companion report was created anywhere under `docs/` by the correction round or by this session.
- `handoffs/` remains flat, twelve files after this session's own Handoff, no nested date/session directories, no `.sha256` files anywhere in the tree.
- This session created only this Handoff. No schema, fixture, or canonical document was modified. All SQLite work ran against fresh databases under `/private/tmp/fsd-final-reaudit-0725-12/`, outside the repository.

## 4. Evidence Reviewed

Read in full: `handoffs/FSD_PLAN_GATE_CORRECTION3_F_20260725-153912.md` (the correction Handoff under audit); `docs/database/schema.sql` (548 lines, in full, diffed mentally against the previously-reviewed 546-line version); `docs/database/verify.sql` (408 lines, in full, including every `INSERT INTO snapshots` statement's exact column list).

Targeted reading/grep against: `docs/AGENT.md`, `docs/PROJECT_SUPPORT/HANDOFFS.md`, `docs/README.md`, `docs/DECISIONS.md` (ADR-009, ADR-011, ADR-014 in full), `docs/PROJECT_MANIFEST.md`, `docs/ARCHITECTURE.md` (SQLite settings section in full), `docs/PRD.md`, `docs/MVP_PLAN.md` (Phase 1 section in full), `docs/PRODUCT_STATE.md`, `docs/KNOWN_ISSUES.md`, `docs/TEST_PLAN.md` (Collections and schema-baseline sections in full), `docs/SECURITY_AND_READ_ONLY_POLICY.md`, `docs/FILESYSTEM_PROVIDER_ARCHITECTURE.md`, `docs/FILESYSTEM_SUPPORT_MATRIX.md`, `docs/DEPENDENCY_AND_LICENSE_REVIEW.md`, `docs/FILESYSTEM_FEASIBILITY_PLAN.md` (§3 in full), `docs/SNAPSHOT_COLLECTIONS.md`. Prior Handoffs (`handoffs/FSD_PLAN_GATE_REAUDIT2_A_20260725-000114.md` and earlier) treated as historical evidence establishing baseline findings, not re-litigated except where this session's own independent reproduction confirms or contradicts them.

Independent SQL evidence (all self-authored this session, not `verify.sql`): `fixture_normalization.sql` (12-test normalization-identity suite), `fixture_collision_path.sql` (10-test collision result-path exclusivity suite), `fixture_invariants.sql` (foundational-invariant regression suite) — all under `/private/tmp/fsd-final-reaudit-0725-12/`.

## 5. Prior Finding Closure Matrix

| ID | Prior status | This session's independent finding |
|---|---|---|
| FSD-REAUDIT2-001 (filesystem cardinality) | OPEN, HIGH, Phase-0A-blocking | **CLOSED.** `FILESYSTEM_FEASIBILITY_PLAN.md` line 27 now reads "other seven native-readable variants"; `MVP_PLAN.md` lines 39/42 now read "seven of the ten"/"all seven native-readable filesystem variants"; `DECISIONS.md` ADR-014 explicitly parenthesizes the old count as "an earlier planning miscount." Repository-wide grep for every previously-flagged phrase returns zero live hits. See §6. |
| FSD-REAUDIT2-002 (normalization identity) | OPEN, MEDIUM | **PARTIALLY CLOSED.** `DEFAULT` removed, `NULL`/omitted rejected at INSERT, blank string rejected at completion, ADR-009 now internally coherent. Whitespace-only and arbitrary non-blacklisted fake values still reach `complete` unblocked — see §8. |
| FSD-REAUDIT2-003 (collision result-path exclusivity) | OPEN, MEDIUM | **CLOSED.** New `EXISTS` clause against `comparison_collision_groups` (keyed on `comparison_id`+`result_path`, independent of entry membership) added to both the INSERT and UPDATE trigger, closing exactly the gap the prior round found. All 10 required tests pass. See §9. |
| FSD-REAUDIT2-004 (SQLite connection policy) | OPEN, LOW | **CLOSED.** `ARCHITECTURE.md` now uses mandatory language ("must apply," "must execute on every new connection") and separates persistent vs. per-connection settings explicitly; `TEST_PLAN.md` adds the startup-assertion test. See §10. |
| FSD-REAUDIT2-005 ("a app extension", trailing whitespace) | OPEN, LOW | **CLOSED.** Zero live "a app extension" hits anywhere in `docs/`; zero trailing-whitespace files across `docs/` and `handoffs/`; zero merge-marker files. See §12. |
| FSD-REAUDIT2-006 (README staleness) | OPEN, LOW | **CLOSED.** `docs/README.md` Status section now accurately states R0 is closed and Phase 0A pending audit, with no misleading claim. See §12. |

## 6. Filesystem Cardinality Audit

Repository-wide search (`docs` and `handoffs`) for every listed phrase, classified:

| Phrase | Result | Classification |
|---|---|---|
| `8 of the 9` | Zero live hits | — |
| `9 required filesystems` | One hit: `docs/FILESYSTEM_REPLAN_CLAUDE.md` line 9 | HISTORICAL / DATED AUDIT EVIDENCE — this document is explicitly a dated, non-continuously-maintained decision report per the project's own document map, unchanged across every audit round, consistently classified this way |
| `all 9 required filesystems` | Zero hits | — |
| `six of the nine` | Zero hits | — |
| `other three filesystems` | Zero hits | — |
| `other six filesystems` | Zero hits | — |
| `all six natively` | Zero hits | — |

Independently confirmed by direct reading:

- `docs/FILESYSTEM_FEASIBILITY_PLAN.md` §3 (Phase 0A's own objective statement): *"...that `NativeMountedProvider` correctly reads metadata from mounted images of the other seven native-readable variants..."* — correct.
- `docs/MVP_PLAN.md` §"Phase 1": *"the path seven of the ten filesystem variants use"* and *"all seven native-readable filesystem variants (APFS, HFS+, FAT16, FAT32, exFAT, NTFS-ro, UDF)"* — correct, and the prose count now matches the parenthetical's seven names (previously self-contradictory).
- `docs/DECISIONS.md` ADR-014: *"This narrows the embedded-reader problem down to a three-filesystem (ext2/3/4) one... (Note: prior historical wording framing this as a nine-filesystem problem was an earlier planning miscount.)"* — the ambiguity flagged in the prior round (whether "nine-filesystem" was a genuine historical scope or an uncorrected propagation of the miscount) is now resolved explicitly in the ADR's own text.
- No Phase 0A objective or exit criterion anywhere in `FILESYSTEM_FEASIBILITY_PLAN.md` or `MVP_PLAN.md` uses a wrong count.

**FSD-REAUDIT2-001 is closed.** This was the only remaining Phase-0A-gating finding from the prior round.

## 7. Snapshot Lifecycle Audit

Fixture: `/private/tmp/fsd-final-reaudit-0725-12/fixture_invariants.sql`, single connection, `PRAGMA foreign_keys = ON` throughout. No regressions found against any previously-verified behavior:

| Test | Result | Verdict |
|---|---|---|
| Zero-root `scanning`→`complete` | Rejected: `Snapshot must have exactly one root entry to complete`; stays `scanning` | PASS |
| One-root `scanning`→`complete` | Accepted, becomes `complete` | PASS |
| Cross-snapshot parent (`entries.parent_id` referencing a different snapshot's entry) | Rejected: `FOREIGN KEY constraint failed` (the composite `FOREIGN KEY (parent_id, snapshot_id) REFERENCES entries(id, snapshot_id)`) | PASS |
| Valid same-snapshot parent | Accepted | PASS |
| Terminal reversion `complete`→`scanning` | Rejected: `Cannot transition out of a terminal status` | PASS |

Combined with §8's normalization fixtures (which also independently re-exercised direct non-`scanning` INSERT rejection, `INSERT OR REPLACE` bypass rejection, and both terminal statuses), the full snapshot lifecycle contract remains intact with no regressions from the third correction round.

## 8. Comparison and Normalization Audit

Fixture: `/private/tmp/fsd-final-reaudit-0725-12/fixture_normalization.sql`, all 12 required tests.

| # | Test | Result | Verdict |
|---|---|---|---|
| 1 | INSERT omitting `normalization_version` entirely | Rejected: `NOT NULL constraint failed: snapshots.normalization_version` | PASS (new: `DEFAULT` removal means omission is now rejected, not silently placeholder-filled) |
| 2 | INSERT with explicit `NULL` | Rejected, same constraint | PASS |
| 3 | INSERT with `''`, then attempt `complete` | Insert succeeds (column is nullable-shaped-but-not-NULL, i.e. empty string is a valid string); completion **rejected**: `Snapshot must have a valid normalization_version to complete` | PASS |
| 4 | INSERT with `'   '` (whitespace only), then attempt `complete` | Insert succeeds; completion **accepted** — `status='complete'`, `normalization_version='   '` | **FAIL — see FSD-FINAL-REAUDIT-001** |
| 5 | INSERT containing `UNRECORDED_PLACEHOLDER` literal, then attempt `complete` | Completion rejected: same message | PASS |
| 6a–d | INSERT with `UNKNOWN` / `PLACEHOLDER` / `NOT_SET` / `PENDING`, then attempt `complete` | **All four accepted** — every one reaches `status='complete'` with the fake literal intact | **FAIL — see FSD-FINAL-REAUDIT-001** |
| 7 | (covered by 3–6 above) | — | — |
| 8 | Transition to `complete_with_warnings` with `UNRECORDED_PLACEHOLDER` | Rejected, same trigger fires for both terminal-complete statuses | PASS |
| 9 | Completion with a valid runtime-shaped identity (`fsd-normalizer-v1_app-1.0_os-23A344`) | Accepted | PASS |
| 10 | Comparison between two snapshots sharing the identical valid identity | Accepted | PASS |
| 11 | Comparison between snapshots with different OS-build identities (`os-23A344` vs. `os-24B999`) | Rejected: `Mismatched normalization versions block comparison` | PASS |
| 12 | `UPDATE comparisons SET left_snapshot_id = ...` (source-ID mutation attempt) | Rejected: `Comparison source snapshot IDs are immutable` | PASS |

8 of 12 required tests pass cleanly; test 4 and the four sub-cases of test 6 fail. This is the confirmed, reproducible form of exactly the risk this task's own brief named by example ("Check whether validation only rejects one literal substring while allowing equivalent fake values such as: UNKNOWN, PLACEHOLDER, UNRECORDED, NOT_SET, PENDING"). The schema's guard, `NEW.normalization_version = '' OR NEW.normalization_version LIKE '%UNRECORDED_PLACEHOLDER%'`, is a two-clause literal blacklist, not a positive format check against the documented shape `fsd-normalizer-<algorithm-version>_app-<implementation-version>_os-<ProductBuildVersion>` (which `DECISIONS.md` ADR-009 now states correctly, §12).

**Documentation consistency**, independently re-checked: `DECISIONS.md` ADR-009 now states one coherent format matching the audit brief's expected shape; ADR-011's mismatch-blocks-comparison policy is unchanged and independently reconfirmed (tests 10–11 above); `ARCHITECTURE.md` §5 describes the general mechanism without restating the literal (correctly deferring); `PRD.md` and `TEST_PLAN.md` likewise do not restate it. No remaining three-way (or any) contradiction between canonical documents was found — this specific defect from the prior round is closed even though the schema-enforcement gap is not.

**This finding (FSD-FINAL-REAUDIT-001) does not block Phase 0A.** Per `FILESYSTEM_FEASIBILITY_PLAN.md` §1 and `MVP_PLAN.md`'s two-gate model (independently re-confirmed, §16), Phase 0A is disk-image-only, creates no snapshot rows, and never touches the SQLite catalog at all — the field this finding concerns is not written or read by the task this audit may authorize.

## 9. Collision Group Audit

Fixture: `/private/tmp/fsd-final-reaudit-0725-12/fixture_collision_path.sql`, all 10 required tests, single connection with `PRAGMA foreign_keys = ON`.

Setup: `Report.txt` (10) and `REPORT.txt` (11) as left-side collision members of group `report.txt`; `report.TXT` (12) as the right-side counterpart; `Ordinary.txt`/`Unrelated.txt` (20/21/13) as genuinely unrelated, non-collision entries on different paths.

| # | Test | Result | Verdict |
|---|---|---|---|
| 1 | Ordinary `matched` at `result_path='report.txt'` using unrelated entries (1, 2 — the snapshot roots) | Rejected: `Ordinary results cannot use a result_path already assigned to a collision group` | PASS |
| 2 | Same, `result_type='changed'` | Rejected, same message | PASS |
| 3 | Same, `result_type='added'` | Rejected, same message | PASS |
| 4 | Same, `result_type='removed'` | Rejected, same message | PASS |
| 5 | Ordinary row using unrelated entries but the collision-group path (identical mechanism to test 1, the specific bypass the prior round found) | Rejected, same message | PASS |
| 6 | `UPDATE` of a valid non-collision row (`result_path='ordinary.txt'`) onto `result_path='report.txt'` | Rejected, same message; row remains at `'ordinary.txt'`, unchanged | PASS |
| 7 | Collision member (10) paired as an ordinary result with an unrelated entry (13) | Rejected: `Collision members cannot be paired as matched/changed/added/removed` | PASS |
| 8 | Collision member (10) paired with an unrelated entry (1) at a non-colliding path | Rejected, same message | PASS |
| 9 | Two collision members (10, 11) each independently paired to the same counterpart (12) | Both inserts rejected, same message | PASS |
| 10 | Valid ordinary result on a genuinely non-collision path (`'unrelated.txt'`) | **Accepted** | PASS (control) |

All ten tests behave exactly as required. Final row inventory in `comparison_results` after the full test sequence contains exactly two rows: the untouched `'ordinary.txt'` setup row and the test-10 control row — no forbidden row of any kind persisted.

**Invariants re-confirmed:** all collision members remain represented only through the group/member tables (never duplicated into `comparison_results` as ordinary pairs); exactly one group exists per `(comparison_id, result_path)` (`UNIQUE` constraint, unchanged); duplicate members and wrong-side members remain rejected (unchanged triggers, not touched by this round, re-verified no regression via the same setup).

**FSD-REAUDIT2-003 is closed.**

## 10. SQLite Connection Policy Audit

`docs/ARCHITECTURE.md` now reads:

> "Mandatory SQLite settings: The database connection factory must apply all required per-connection pragmas before any query or transaction. `schema.sql`'s pragmas only apply to the connection running the script.
> Database-persistent settings (apply once): `PRAGMA journal_mode = WAL;`
> Per-connection settings (must execute on every new connection): `PRAGMA foreign_keys = ON; PRAGMA busy_timeout = 5000; PRAGMA synchronous = NORMAL; PRAGMA temp_store = MEMORY;`
> A debug assertion or startup verification must confirm `PRAGMA foreign_keys;` returns `1` before repositories are allowed to operate."

This is mandatory language, not a recommendation, and correctly distinguishes persistent (`journal_mode`, which SQLite itself persists in the database file) from per-connection (`foreign_keys`, `busy_timeout`, `synchronous`, `temp_store`, none of which SQLite persists). `docs/TEST_PLAN.md` line 139 adds "per-connection `PRAGMA foreign_keys = ON` verification (startup assertion)" as a required test, matching the `PRAGMA foreign_keys;` = `1` check this task's brief asks for.

Independent demonstration, `PRAGMA foreign_keys = ON` genuinely active for the deleting connection (same collision fixture database as §9, after all ten tests): pre-delete state was 1 collision group / 3 collision members / 2 comparison_results rows / 8 entries across both snapshots. `DELETE FROM comparisons WHERE id = 1` correctly cascaded groups/members/results to 0/0/0; entries remained at 8 (all survived). `PRAGMA foreign_key_check` after the delete returned no rows.

Per the brief's own instruction, this audit does not manufacture a finding merely because SQLite requires per-connection enforcement — the architectural mandate is now explicit, testable, and independently demonstrated to produce the correct cascade/survival behavior when honored. **FSD-REAUDIT2-004 is closed.**

## 11. SQLite Verification

```text
$ sqlite3 <fresh-db> < docs/database/schema.sql
wal
$ sqlite3 <fresh-db> "PRAGMA integrity_check;"
ok
$ sqlite3 <fresh-db> "PRAGMA foreign_key_check;"
(no rows)
$ sqlite3 <fresh-db> "SELECT * FROM schema_migrations ORDER BY version;"
3|2026-07-25 08:47:05
```

```text
$ sqlite3 <fresh-db> < docs/database/verify.sql
(exit 1 -- see FSD-FINAL-REAUDIT-002 below; the failure is not the constraint the fixture was
 written to test)
```

Consolidated forbidden-state queries, run against this session's own fixture databases after all negative-test attempts had been made:

```text
non_scanning_direct_snapshots                    0
terminal_without_one_root                        0
completed_snapshots_UNRECORDED_PLACEHOLDER        0
comparisons_incomplete_sources                    0
comparisons_incompatible_normalization            0
ordinary_results_on_collision_paths               0
collision_members_as_ordinary_results             0
duplicate_collision_groups                        0
duplicate_collision_members                       0
blank_collection_names                            0
blank_snapshot_display_names                      0
completed_snapshots_blank_or_whitespace_normalization   1   -- KNOWN GAP, see FSD-FINAL-REAUDIT-001
completed_snapshots_generic_placeholder_words           4   -- KNOWN GAP, see FSD-FINAL-REAUDIT-001
```

The two non-zero rows are not contradictions of the otherwise-clean sweep — they are the direct, expected signature of the one confirmed-open finding (§8), reported transparently rather than omitted from the query set.

### FSD-FINAL-REAUDIT-002 — `verify.sql`'s own normalization-version backfill is incomplete

`grep -n "^INSERT INTO snapshots" docs/database/verify.sql` finds 17 `INSERT INTO snapshots` statements; 15 explicitly list `normalization_version` in their column list, but the two multi-line, fully-qualified-column-list statements at lines 46 and 64 (comments: "Embedded-raw snapshot over a disk image succeeds with full provider detail" / "...over a raw physical device succeeds, authorization_required=1") do not. Independently reproduced: applying `verify.sql` fresh fails at line 46 with `NOT NULL constraint failed: snapshots.normalization_version`, again at line 64 with the same error, and cascades to a third failure at line ~94 (`FOREIGN KEY constraint failed`, a `scan_issues` row referencing snapshot id 4, which the line-46 failure never let exist). These three fixtures were written to test filesystem-provider metadata (`CHECK` constraints, `authorization_required`, the `scan_issues.source` discriminator) and a legitimate reader-sourced warning — none of that is what actually fails; the real constraints under test are never exercised because an unrelated, incidental `NOT NULL` violation fires first. The correction Handoff's §15 "Full SQLite Evidence" states only that "scripts successfully asserted the updated constraints via expected runtime failures," which is true in aggregate but does not disclose that at least three of those "expected" failures are not the constraints the surrounding comments say they test.

## 12. Documentation and Handoff Policy Audit

```text
$ grep -rlnE "[ \t]+$" docs handoffs --include="*.md"
(no output — zero trailing-whitespace files)
$ grep -rlnE "^(<<<<<<<|=======|>>>>>>>)" docs handoffs --include="*.md"
(no output — zero merge-marker files)
```

`AI_HANDOFFS/` is consistently described as legacy/deleted in `docs/AGENT.md`, `docs/PROJECT_SUPPORT/HANDOFFS.md`, and `docs/DECISIONS.md` ADR-013; `handoffs/` is consistently described as the current, active, flat location. No `.sha256` requirement exists anywhere. `docs/AGENT.md` and `docs/PROJECT_SUPPORT/HANDOFFS.md` both state the Mandatory Single-File Handoff Policy identically (exactly one Handoff per session, no separate report, the Handoff is the complete record, the user uploads only the latest one). This session's own Handoff filename role code (`A`) matches its stated role (AUDIT).

`docs/README.md` §"Status" now reads: *"Planning scaffold complete, filesystem scope replanned... Foundational R0 schema issues have been independently closed; final plan-gate correction and audit remain. Phase 0A is not authorized until the next audit approves; Phase 0 implementation remains separately gated by normalization and catalog schema readiness."* This is accurate as of the state prior to this Handoff's own decision and does not overclaim; it will need one further update once this Handoff's approval is available for the user to act on (§22).

### FSD-FINAL-REAUDIT-003 — `TEST_PLAN.md` line 201 asserts an incorrect expected outcome for the schema-baseline test

`docs/TEST_PLAN.md` line 201: *"apply schema migration version 3 to a fresh database and confirm `PRAGMA integrity_check`/`PRAGMA foreign_key_check` are both clean, with schema versions 1, 2, and 3 all recorded in `schema_migrations`."* This directly contradicts the schema's actual, intentional, and repeatedly-independently-verified behavior: `schema.sql`'s own header comment states it "remains a single cumulative DDL file, not an incremental migration script sequence," and every fresh apply in this and the two prior independent re-audits confirms `schema_migrations` contains exactly one row, `3` — never three rows. This line was not part of the tracked FSD-REAUDIT2 list and was not touched by the third correction round; it appears to be a pre-existing, previously-unswept defect discovered by this session's own document reading, not a regression introduced by this round.

## 13. MCP CodeGraph Status

**NOT RUN — APPROPRIATE AT CURRENT STAGE.** Independently confirmed: no `.codegraph` directory exists; no production source scaffold of any kind exists anywhere in the tree. Not invoked by this audit, per instruction — the mandatory first-implementation-session gate (check availability → scaffold → index → real query → record → report `BLOCKED` if unavailable) does not apply because no implementation session is underway.

## 14. Findings

### [MEDIUM] FSD-FINAL-REAUDIT-001 — Normalization-identity completion guard is a narrow literal blacklist, not a format check; whitespace-only and arbitrary fake values pass unblocked

**Evidence**

- `docs/database/schema.sql` line 226: `WHEN NEW.normalization_version = '' OR NEW.normalization_version LIKE '%UNRECORDED_PLACEHOLDER%' THEN RAISE(ABORT, ...)`.
- `/private/tmp/fsd-final-reaudit-0725-12/fixture_normalization.sql`, tests 4 and 6a–6d: snapshots completed with `normalization_version` = `'   '`, `'UNKNOWN'`, `'PLACEHOLDER'`, `'NOT_SET'`, `'PENDING'` all reached `status='complete'` with no rejection.

**Finding**

The schema does not validate `normalization_version` against the documented shape (`fsd-normalizer-<algorithm-version>_app-<implementation-version>_os-<ProductBuildVersion>`, per `DECISIONS.md` ADR-009). It only blocks an exact empty string and one specific historical placeholder substring.

**Impact**

A scanner bug that populates this field with any value other than a genuinely absent one or the one specifically-blacklisted string — including trivial mistakes like leaving it whitespace, or a lazier future placeholder like `"TODO"` or `"UNKNOWN"` — would silently produce a `complete` snapshot carrying a fake compatibility identity, and two such snapshots sharing the same fake value would compare as verified-compatible. This is the same failure mode ADR-011 exists to prevent, now narrower in surface area than before this round but not eliminated.

**Required correction**

Replace the literal blacklist with either a structural format check (e.g. `GLOB 'fsd-normalizer-*_app-*_os-*'` combined with `trim(...) != ''`) or, preferably, capture and pin the actual runtime OS build/normalizer implementation version at scan time so the value is populated by fact rather than validated by shape alone.

**Gate**

- Blocks Phase 0A: NO (the disk-image feasibility spike creates no snapshot rows and does not touch the SQLite catalog, per `FILESYSTEM_FEASIBILITY_PLAN.md` §1 and the two-gate model in `MVP_PLAN.md`/`PRODUCT_STATE.md`, independently re-confirmed unchanged this session)
- Blocks Phase 0: YES

### [LOW] FSD-FINAL-REAUDIT-002 — `verify.sql`'s normalization-version backfill missed two fixtures, breaking three unrelated test assertions

**Evidence**

- `docs/database/verify.sql` lines 46 and 64: `INSERT INTO snapshots (...)` column lists omit `normalization_version`; independently reproduced failures at those lines (`NOT NULL constraint failed`) and a cascading failure at line ~94 (`FOREIGN KEY constraint failed`, `scan_issues` referencing the never-created snapshot).

**Finding**

15 of 17 `INSERT INTO snapshots` statements in `verify.sql` were correctly backfilled; two were missed, and both were meant to demonstrate successful inserts for filesystem-provider metadata scenarios, not to test normalization at all.

**Impact**

The correction Handoff's self-reported "Full SQLite Evidence" is not fully trustworthy as written: it reports errors occurred as expected, but does not disclose that at least three of those errors are not the constraints the surrounding test comments describe. A future reader relying on `verify.sql` passing (or failing in the expected places) as evidence of filesystem-provider metadata correctness would be misled.

**Required correction**

Add `normalization_version` to the two INSERT statements at lines 46 and 64 (any value already used elsewhere in the file, e.g. `'fsd-normalizer-v1_app-1.0_os-1'`, is sufficient), then re-run and confirm every subsequent fixture that depends on snapshots 4/5 now exercises its intended constraint.

**Gate**

- Blocks Phase 0A: NO
- Blocks Phase 0: YES (fix before relying on `verify.sql` as a regression gate for real persistence code)

### [LOW] FSD-FINAL-REAUDIT-003 — `TEST_PLAN.md` describes an incorrect expected schema-baseline outcome

**Evidence**

- `docs/TEST_PLAN.md` line 201: "...with schema versions 1, 2, and 3 all recorded in `schema_migrations`."
- Independently reproduced, this session and the two prior independent re-audits: a fresh `schema.sql` apply always yields exactly one row, `3`.

**Finding**

This test-plan line has not been updated to match the schema's actual, intentional, cumulative-DDL design (documented in `schema.sql`'s own header comment) and was not part of the tracked FSD-REAUDIT2 findings, so it was not addressed by this correction round.

**Impact**

A future test-writer implementing this line literally would either write an assertion that fails against correct behavior, or misdiagnose a correctly-behaving schema as broken.

**Required correction**

Update `TEST_PLAN.md` line 201 to expect exactly one row, `3`, matching every independently-verified fresh-apply result across all three re-audit rounds.

**Gate**

- Blocks Phase 0A: NO
- Blocks Phase 0: NO (documentation-only; the schema itself is correct)

## 15. Remaining Risks

- FSD-FINAL-REAUDIT-001 is the only finding in this Handoff that blocks Phase 0. It is narrower in scope than any single finding from the two prior rounds (a two-clause `WHEN` condition needs a shape check or real runtime capture, not a redesign), but it is real and independently confirmed, and should not be carried silently into Phase 0 implementation.
- FSD-FINAL-REAUDIT-002 means `verify.sql` cannot currently be trusted as a complete regression gate for filesystem-provider-metadata scenarios specifically — anyone relying on "verify.sql passes" as evidence for that subsystem should re-run it after the two-line fix and confirm the intended constraints, not just "an error occurred," are what fire.
- The pattern across three correction rounds — a targeted fix closing the specifically-cited defect while a narrower, adjacent gap survives (arbitrary pairing → result-path exclusivity → format-blacklist-vs-shape-validation; and unrelated to the six-item list, an incomplete backfill and a stale test-plan line surfaced only by this session's own independent reading) — continues to argue for grep/query verification after every edit, not assertion, exactly as this task's own brief requires.

## 16. Phase 0A Readiness

**APPROVED**, per the brief's own checklist, each independently verified this session:

- Filesystem cardinality is correct in every live planning document — YES (§6).
- No operative mount contradiction exists — YES (unchanged from the second re-audit round, `FILESYSTEM_PROVIDER_ARCHITECTURE.md` §3 confirmed still consistent with `SECURITY_AND_READ_ONLY_POLICY.md`; not touched by this round, no regression found by this session's grep sweep).
- Schema fresh apply passes — YES (§11: `integrity_check` = `ok`, `foreign_key_check` = no rows, `schema_migrations` = `{3}`).
- No arbitrary collision pairing is possible — YES (unchanged from the second re-audit round; re-confirmed no regression via §9's setup, which re-exercises the original pairing triggers alongside the new path-exclusivity ones).
- No ordinary result can share a collision-group path — YES (§9, 10/10 tests).
- Snapshot lifecycle remains valid — YES (§7).
- Normalization identity contract is coherent enough not to mislead the feasibility spike — YES: the contract has a real, documented gap (§8, FSD-FINAL-REAUDIT-001), but Phase 0A creates no snapshot rows and never touches this field, per `FILESYSTEM_FEASIBILITY_PLAN.md` §1's own explicit scope ("no SQLite persistence... the spike may print to stdout") and the two-gate model independently re-confirmed unchanged in `MVP_PLAN.md`/`PRODUCT_STATE.md`.
- No remaining canonical contradiction changes the Phase 0A task — YES.
- The next executable task is precise — YES, unchanged and fully specified independent of this audit's findings.

The next executable task:

> Build and run the disk-image-only ext2/ext3/ext4 libfsext feasibility spike.

Constraints (all independently re-confirmed unchanged from `FILESYSTEM_FEASIBILITY_PLAN.md` §3): disk images only; no physical-device access; no raw writes (the provider contract has no write method); no Xcode UI requirement; no external dependency installation for the final app (libfsext vendored, not user-installed); clear libfsext pass/fail criteria against the non-UTF-8-filename and fscrypt-encrypted-subtree fixtures; TSK retained only as the documented, pre-evaluated fallback.

This task is not authorized to start during this audit.

## 17. Chatbox Transition Decision

READY TO MOVE TO CONTROL

## 18. Git Status

```text
$ git status --short
fatal: not a git repository (or any of the parent directories): .git   (exit 128)
$ git diff --check
usage: git diff --no-index ...   (exit 0, no repository/index to diff against)
```

GIT STATUS: BLOCKED — NOT A REPOSITORY

## 19. Commit Readiness

NOT APPLICABLE — no Git repository exists. No commit was made or attempted.

## 20. Push Readiness

NOT AUTHORIZED — no Git repository, no remote, no push performed or requested.

## 21. Final Decision

APPROVE — READY FOR PHASE 0A

## 22. Exact Next Action

Move to the CONTROL chatbox and authorize:

> Build and run the disk-image-only ext2/ext3/ext4 libfsext feasibility spike.

Independent of Phase 0A, assign a small corrective round — it does not need to block starting Phase 0A and can run in parallel, consistent with the project's own two-gate model — to close the three findings in §14 before Phase 0 (real Xcode/catalog implementation) begins: replace the normalization-identity literal blacklist with a real format check or genuine runtime capture (FSD-FINAL-REAUDIT-001); backfill `normalization_version` into the two remaining `verify.sql` fixtures at lines 46 and 64 (FSD-FINAL-REAUDIT-002); and correct `TEST_PLAN.md` line 201's schema-baseline expectation to match the schema's actual single-row, cumulative-DDL design (FSD-FINAL-REAUDIT-003). Update `README.md`'s Status section once Phase 0A is actually underway to reflect that authorization, rather than the current "pending audit" language.
