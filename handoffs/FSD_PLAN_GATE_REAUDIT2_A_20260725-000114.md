# FSD Unified Session Handoff

AGENT: Claude (PRIMARY INDEPENDENT PLAN-GATE RE-AUDIT role assignment)
ROLE: AUDIT
TASK ID: FSD-PLAN-GATE-REAUDIT2-0724-10
PHASE: AUDIT AND PLANNING

## 1. Session Identity

- **Objective:** Independently re-audit the second Plan Gate correction round (`handoffs/FSD_PLAN_GATE_CORRECTION2_F_20260724-163544.md`, "Forge") to determine whether the seven defect classes carried over from `handoffs/FSD_PLAN_GATE_REAUDIT_A_20260724-232243.md` (FSD-REAUDIT-001 through 009) are genuinely closed, and whether FSD may begin Phase 0A.
- **Method:** No claim in the correction Handoff was accepted on the correcting agent's word. Every schema-level claim was independently reproduced against fresh SQLite databases built outside the repository, using self-authored fixtures, not `docs/database/verify.sql`. Every document claim was independently re-greped against live files.
- **Scope discipline:** No schema, fixture, or canonical document was modified. No Git repository was initialized. No CodeGraph index was created or queried. No Phase 0A work (feasibility spike, disk images, libfsext) was started. Exactly one Handoff file was created by this session (this file).

## 2. Executive Decision

**REJECT — CORRECTIONS REQUIRED.**

The second correction round made real, independently-verified progress: both originally-CRITICAL, explicitly Phase-0A-blocking findings from the prior re-audit — **FSD-REAUDIT-001** (arbitrary collision-member pairing in `comparison_results`) and **FSD-REAUDIT-002** (the auto-mount contradiction in `FILESYSTEM_PROVIDER_ARCHITECTURE.md` §3) — are now genuinely closed. This is not a re-assertion; both were independently reproduced as fixed against fresh fixtures this session authored itself (§7, §8). **FSD-REAUDIT-004** (non-`scanning` direct snapshot inserts) is also genuinely closed, and **FSD-REAUDIT-007** (five-way policy duplication) is genuinely closed down to one canonical copy plus one cross-reference.

However, **FSD-REAUDIT-003** (filesystem-cardinality miscounts) is **not closed** and has **regressed further**. The prior re-audit's own gating logic explicitly said this finding blocks Phase 0A "because the 'other three' error appears directly inside Phase 0A's own objective statement in `MVP_PLAN.md` and `FILESYSTEM_FEASIBILITY_PLAN.md`." That exact sentence in `FILESYSTEM_FEASIBILITY_PLAN.md` §3 (line 27) is **still unedited** — "other three filesystems" remains, uncorrected, inside the disk-image spike's own objective text. Separately, `MVP_PLAN.md` §"Phase 1" (lines 39 and 42) was edited but produced a **new, different, self-contradictory miscount**: "the path six of the nine required filesystems use," followed two lines later by "all six natively-mountable filesystems (APFS, HFS+, FAT16, FAT32, exFAT, NTFS-ro, UDF)" — a parenthetical that lists **seven** names while the prose says "six." The correct figures are ten variants / seven native-readable / three embedded-raw throughout.

**FSD-REAUDIT-005** (normalization-compatibility identity) is also **not closed**. The literal `unicode-15.0` false-precision claim is genuinely gone from `schema.sql`'s default — real progress — but it was replaced with a self-admitted placeholder, `'fsd-normalizer-v1_app-v1_os-UNRECORDED_PLACEHOLDER'`, that nothing in the schema rejects for a `complete` snapshot, and a blank string (`''`) is equally accepted. Two independent snapshots that both silently inherit this identical placeholder default can be compared as if verified-compatible — defeating ADR-011's mismatch-blocks-comparison guarantee in exactly the case it exists to catch (§9 below). A new inconsistency was also found: `DECISIONS.md` ADR-009 states the normalization-version string should literally be `fsd-path-v1-foundation-nfc-posix-casefold` — a **third**, different value from both the old and new schema defaults, so the canonical ADR and the schema now disagree with each other about what this field should even contain.

A narrower, newly-discovered schema gap (§8.4) allows an ordinary `comparison_results` row to claim a `result_path` that already has a collision group, using entries unrelated to that group — the one specific negative test (`AUDIT 1` item 9 in this task's own brief) that the schema does not defend against.

Per the standing rule that any implementation-blocking finding blocks Phase 0A, and the brief's own Phase 0A readiness checklist requiring "filesystem counts are correct everywhere," **FSD is not ready to move to CONTROL.**

## 3. Repository State

- `FSD_ROOT` resolves to `/Users/cenvu/Desktop/DEV/FSD` (the `Dev` spelling is the identical inode on case-insensitive APFS).
- No `.git` directory — confirmed via `git status --short` (exit 128, "not a git repository") and `git diff --check` (exit 129, no repository to diff). Not initialized, per constraints.
- No `.codegraph` directory.
- No production source of any kind anywhere in the tree: `find` for `*.swift`, `*.m`, `*.mm`, `*.c`, `*.cc`, `*.cpp`, `*.xcodeproj`, `Package.swift` returned zero results.
- `docs/database/schema.sql` declares itself schema version 3 (546 lines, up from the prior round's ~460); a fresh database's `schema_migrations` table contains exactly one row, `3`.
- `docs/FSD_PLAN_GATE_REAUDIT_GPT56SOL.md` is confirmed **absent** from `docs/`. Its unique content is confirmed present, merged, inside `handoffs/FSD_PLAN_GATE_REAUDIT_A_20260724-232243.md` (both the Handoff-format summary and the full §1–§17 detailed report are in that one file — independently read in full this session, 661 lines).
- `handoffs/` remains flat, ten files, no nested date/session directories, no `.sha256` files anywhere in the tree.
- This session created only this Handoff. No schema, fixture, or canonical document was modified. All SQLite work ran against fresh databases under `/private/tmp/fsd-reaudit2-0724-10/`, outside the repository.

## 4. Evidence Reviewed

Read in full: `handoffs/FSD_PLAN_GATE_CORRECTION2_F_20260724-163544.md` (the correction Handoff under audit); `handoffs/FSD_PLAN_GATE_REAUDIT_A_20260724-232243.md` (661 lines, the prior independent re-audit and its merged detailed report); `docs/database/schema.sql` (546 lines, in full); `docs/database/verify.sql` (408 lines, in full, including its new collision-pairing negative-test fixture at lines 360–362).

Targeted reading/grep against: `docs/AGENT.md`, `docs/PROJECT_SUPPORT/HANDOFFS.md`, `docs/README.md`, `docs/DECISIONS.md` (all ADRs, especially ADR-009, ADR-011, ADR-013, ADR-014), `docs/PROJECT_MANIFEST.md`, `docs/ARCHITECTURE.md`, `docs/PRD.md`, `docs/MVP_PLAN.md`, `docs/PRODUCT_STATE.md`, `docs/KNOWN_ISSUES.md`, `docs/TEST_PLAN.md`, `docs/SECURITY_AND_READ_ONLY_POLICY.md`, `docs/FILESYSTEM_PROVIDER_ARCHITECTURE.md`, `docs/FILESYSTEM_SUPPORT_MATRIX.md`, `docs/DEPENDENCY_AND_LICENSE_REVIEW.md`, `docs/FILESYSTEM_FEASIBILITY_PLAN.md`, `docs/SNAPSHOT_COLLECTIONS.md`. `docs/FILESYSTEM_REPLAN_CLAUDE.md` and `docs/REVIEW_CLAUDE_CODE.md` treated as dated historical artifacts (spot-checked, not line-audited), consistent with their role in the project's own document map.

Independent SQL evidence (all self-authored, not `verify.sql`): `fixture1_collision.sql` / `fixture1_full.sql` (collision-pairing forbidden writes, cascade-delete, orphan check), `fixture2_lifecycle.sql` (snapshot initial-status forbidden writes), `fixture3_normalization.sql` (placeholder/blank normalization-version behavior) — all under `/private/tmp/fsd-reaudit2-0724-10/`.

## 5. Prior Finding Closure Matrix

| ID | Prior status | This session's independent finding |
|---|---|---|
| FSD-REAUDIT-001 (arbitrary collision pairing) | OPEN, CRITICAL | **CLOSED.** New triggers `trg_comparison_results_no_collision_pairs` / `_update` block every forbidden pairing on both INSERT and UPDATE paths. See §8. |
| FSD-REAUDIT-002 (auto-mount contradiction) | OPEN, CRITICAL | **CLOSED.** `FILESYSTEM_PROVIDER_ARCHITECTURE.md` §3 step 1 rewritten to the consent-gated flow, cross-references `SECURITY_AND_READ_ONLY_POLICY.md`, no contradictory sentence remains. See §9.1. |
| FSD-REAUDIT-003 (filesystem cardinality) | OPEN, HIGH | **NOT CLOSED, further regressed.** Two originally-flagged instances fixed (`FILESYSTEM_PROVIDER_ARCHITECTURE.md`, `TEST_PLAN.md`); `FILESYSTEM_FEASIBILITY_PLAN.md`'s Phase-0A-gating instance unedited; `MVP_PLAN.md`'s instance replaced with a different, internally self-contradictory miscount. See §9.2. |
| FSD-REAUDIT-004 (non-scanning direct insert) | OPEN, MEDIUM | **CLOSED.** New trigger `trg_snapshots_insert_scanning_only` rejects every non-`scanning` INSERT, including an `INSERT OR REPLACE` bypass attempt. See §6. |
| FSD-REAUDIT-005 (unverifiable normalization identity) | OPEN, MEDIUM | **NOT CLOSED, changed shape.** The `unicode-15.0` literal is gone, but the replacement default is a self-admitted, unrejected placeholder; blank is also accepted; a new ADR/schema literal mismatch was introduced. See §7. |
| FSD-REAUDIT-006 (mass find-replace damage) | OPEN, LOW | **MOSTLY CLOSED.** ADR-013's empty-backtick artifact and false "handoffs/ deleted" claim are both fixed. The two originally-cited "a app extension" instances (`PROJECT_MANIFEST.md`, `DEPENDENCY_AND_LICENSE_REVIEW.md` §3.4) are fixed, as is the System-Extension/app-extension self-contradiction. Two **new-to-this-audit** live instances of "a app extension" remain (`docs/AGENT.md`, `docs/FILESYSTEM_REPLAN_CLAUDE.md`) — not previously cited by name, so not a regression, but not closed as a class. See §10.1. |
| FSD-REAUDIT-007 (5x policy duplication) | OPEN, LOW | **CLOSED.** "Explicit Mount Consent Policy" now appears only in `SECURITY_AND_READ_ONLY_POLICY.md` (canonical) plus one historical, dated correction report. `PRD.md`, `MVP_PLAN.md`, `TEST_PLAN.md`, `FILESYSTEM_PROVIDER_ARCHITECTURE.md` no longer carry copies. See §9.3. |
| FSD-REAUDIT-008 (role-code mismatch) | OPEN, LOW | **CLOSED for this round.** `handoffs/FSD_PLAN_GATE_CORRECTION2_F_20260724-163544.md` uses filename code `F` and its own title says "(Forge)" — consistent. |
| FSD-REAUDIT-009 (trailing whitespace) | OPEN, LOW | **CLOSED for the originally-cited file, recurred in a new one.** `docs/FSD_PLAN_GATE_CORRECTION_GEMINI31.md` is now clean. The **new** correction Handoff itself, `handoffs/FSD_PLAN_GATE_CORRECTION2_F_20260724-163544.md`, has trailing whitespace on lines 4 and 28 — the correction's own "Clean" claim was scoped only to `grep ... docs`, which never covered its own file in `handoffs/`. See §10.2. |

## 6. Snapshot Lifecycle Audit

Fixture: `/private/tmp/fsd-reaudit2-0724-10/fixture2_lifecycle.sql`, run single-connection with `PRAGMA foreign_keys = ON` throughout.

| Test | Result | Verdict |
|---|---|---|
| Direct INSERT `status='scanning'` | Accepted | PASS |
| Direct INSERT `status='complete'` | Rejected: `Snapshot must be inserted as scanning first.` | PASS |
| Direct INSERT `status='complete_with_warnings'` | Rejected, same message | PASS |
| Direct INSERT `status='interrupted'` | Rejected, same message | PASS |
| Direct INSERT `status='failed'` | Rejected, same message | PASS |
| Direct INSERT `status='cancelled'` | Rejected, same message | PASS |
| `INSERT OR REPLACE ... status='complete'` over an existing `scanning` row | Rejected, same trigger fires; original row untouched (`status` still `scanning`) | PASS |
| Zero-root `scanning`→`complete` | Rejected: `Snapshot must have exactly one root entry to complete`; stays `scanning` | PASS |
| One-root `scanning`→`complete` | Accepted, becomes `complete` | PASS |
| Terminal reversion `complete`→`scanning` | Rejected: `Cannot transition out of a terminal status` | PASS |
| Terminal reversion `complete`→`failed` | Rejected, same message | PASS |
| Terminal reversion `complete`→`interrupted` | Rejected, same message | PASS |
| Terminal reversion `complete`→`cancelled` | Rejected, same message | PASS |

**This closes FSD-REAUDIT-004 completely.** The new `trg_snapshots_insert_scanning_only` (`BEFORE INSERT ON snapshots WHEN NEW.status != 'scanning'`) rejects all five non-`scanning` direct-insert states, and the `INSERT OR REPLACE` bypass attempt that previously worked around the `complete`-only guard is independently confirmed still blocked for the broader guard. Only `scanning` succeeds on INSERT, exactly as required.

## 7. Comparison and Normalization Audit

Fixture: `/private/tmp/fsd-reaudit2-0724-10/fixture3_normalization.sql`.

```text
-- snapshot inserted WITHOUT specifying normalization_version --
id=1, normalization_version = 'fsd-normalizer-v1_app-v1_os-UNRECORDED_PLACEHOLDER'
-- completed with one root entry --
id=1, status='complete', normalization_version = 'fsd-normalizer-v1_app-v1_os-UNRECORDED_PLACEHOLDER'   [ACCEPTED — not rejected]
-- second snapshot, same default placeholder, also completed --
id=2, status='complete', normalization_version = 'fsd-normalizer-v1_app-v1_os-UNRECORDED_PLACEHOLDER'
-- comparison between the two placeholder-identity snapshots --
INSERT INTO comparisons(...) → 1 row affected   [ACCEPTED — treated as verified-compatible]
-- snapshot inserted with an EXPLICIT blank normalization_version ('') --
INSERT → 1 row affected; UPDATE status='complete' → succeeds
id=3, status='complete', normalization_version = ''   [ACCEPTED — blank]
```

**FSD-REAUDIT-005 is not closed.** Confirmed genuine progress: `grep -rn "unicode-15.0" docs --include=*.md` (excluding `verify.sql`'s fixture data and historical audit/handoff narrative) returns zero hits in any live prose document — the specific false-precision claim about a fixed Unicode Consortium version is gone. But the replacement schema default, `'fsd-normalizer-v1_app-v1_os-UNRECORDED_PLACEHOLDER'`, is itself an admitted non-value, and nothing in `schema.sql` — no `CHECK`, no `BEFORE UPDATE OF status` trigger — rejects it, or an explicit blank string, when a snapshot transitions to `complete`. Two snapshots that both silently inherit the identical placeholder (e.g. because the scanner forgot to populate it, exactly the failure mode a real default is supposed to guard against) compare as verified-compatible with no warning, which is the precise case ADR-011's mismatch-blocks-comparison policy exists to catch.

**New inconsistency found:** `docs/DECISIONS.md` ADR-009 states, as the canonical decision: *"The normalization version string is `fsd-path-v1-foundation-nfc-posix-casefold`."* This is a **third**, different literal from both the old schema default (`fsd-algo-v1_app-v1.0_unicode-15.0`, still used as test data in `verify.sql`) and the new one (`fsd-normalizer-v1_app-v1_os-UNRECORDED_PLACEHOLDER`). None of the three incorporate a runtime-recordable operating-system build or ICU data-version fact, as this task's own brief asks the compatibility identity to use. The ADR, the schema, and the test fixtures now assert three mutually inconsistent values for what should be one governed fact.

What remains genuinely closed from the prior round, independently re-confirmed via the same mechanism used before (immutable comparison source IDs, `trg_comparisons_source_eligibility_insert`, `trg_comparisons_version_check`): mismatched non-placeholder `normalization_version` values are still correctly rejected; `scanning`/`interrupted`/`failed`/`cancelled` sources are still rejected as comparison inputs; `left_snapshot_id`/`right_snapshot_id` remain immutable after creation.

## 8. Collision Group Audit

Fixtures: `/private/tmp/fsd-reaudit2-0724-10/fixture1_collision.sql` and `fixture1_full.sql` (single-connection, `PRAGMA foreign_keys = ON`).

### 8.1 Forbidden-pairing writes (all nine required tests)

Setup: `Report.txt` (id 10) and `REPORT.txt` (id 11) as left-side collision members of group `report.txt`; `report.TXT` (id 12) and `rePort.txt` (id 14) as right-side collision members of the same group; `Unrelated.txt` (id 13) as a genuine non-collision right-side entry.

| # | Test | Result |
|---|---|---|
| 1 | Collision member (10) paired as `matched` with unrelated entry (13) | **Rejected**: `Collision members cannot be paired as matched/changed/added/removed` |
| 2 | Same pairing as `changed` | **Rejected**, same trigger |
| 3 | Collision member (10) alone as `added` | **Rejected**, same trigger |
| 4 | Collision member (11) alone as `removed` | **Rejected**, same trigger |
| 5 | Unrelated left entry (1) paired with collision member (12) as `matched` | **Rejected**, same trigger |
| 6 | Two different left members (10, 11) each independently `matched` against the same right member (12) | **Both rejected** |
| 7 | Mirror of #6: two different right members (12, 14) each independently `matched` against the same left entry (10) | **Both rejected** |
| 8 | UPDATE: an ordinary `matched` row (unrelated entries 20/21) changed via `UPDATE ... SET left_entry_id=10, right_entry_id=12` | **Rejected**: `trg_comparison_results_no_collision_pairs_update` fires; row unchanged |
| 9 | Ordinary `matched` row inserted with `result_path='report.txt'` (the existing group's path) but using entries that are **not** collision members (root entries 1, 2) | **Accepted** — see §8.4 |

Tests 1–8 (the eight tests this task's brief frames as the core "arbitrary pairing" defense) all pass. **This independently closes FSD-REAUDIT-001** — the specific reproduction that broke the prior correction round (two collision members each independently `matched` to one counterpart, and a collision member matched to an unrelated entry) no longer succeeds on either the INSERT or the UPDATE path.

### 8.2 Group/member table invariants

| Test | Result |
|---|---|
| Duplicate collision group (`comparison_id`, `result_path`) | Rejected: `UNIQUE` constraint |
| Duplicate collision member (`group_id`, `side`, `entry_id`) | Rejected: `UNIQUE` constraint |
| Right-snapshot entry inserted as `side='left'` | Rejected: `Collision member entry must belong to the left snapshot of the comparison` |
| Left-snapshot entry inserted as `side='right'` | Rejected: mirrored message |

### 8.3 Cascade-delete cleanliness

With `PRAGMA foreign_keys = ON` genuinely active for the deleting connection: pre-delete state was 1 group / 3 members / 0 results (test rows had already been rejected) / 6 entries across both snapshots. `DELETE FROM comparisons WHERE id = 1` reduced groups/members/results to 0/0/0; entries remained at 6 (all survived, confirmed by `relative_path` listing). `PRAGMA foreign_key_check` after the delete returned no rows — no orphans.

**Methodological note, reported for transparency:** an earlier attempt at this same test, run as a separate `sqlite3` CLI invocation without re-issuing `PRAGMA foreign_keys = ON` on that connection, produced orphaned `comparison_collision_groups`/`comparison_results` rows referencing a deleted `comparison_id` (`PRAGMA foreign_key_check` flagged them). This was **this session's own testing artifact**, not a schema defect — SQLite's `foreign_keys` pragma is per-connection and is not persisted in the database file, so `schema.sql`'s own `PRAGMA foreign_keys = ON` (line 16) only protects the connection that executes `schema.sql` itself. Re-run correctly in a single connection with the pragma active throughout, cascade deletion is clean (§8.3 above). This finding is not new: `docs/REVIEW_CLAUDE_CODE.md` (a historical, dated review) already flagged this exact operational risk and recommended `ARCHITECTURE.md` mandate that the app's connection factory issue `PRAGMA foreign_keys = ON` on **every** connection open, not just once. `docs/ARCHITECTURE.md` §"Recommended SQLite settings" (line 119–126) still only lists it as "Recommended," not as a mandatory per-connection requirement. This is a real, if not new, risk directly relevant to the guarantees just verified in this section — see Finding FSD-REAUDIT2-004.

### 8.4 New finding: an ordinary result can claim an already-collided path

Test 9 above succeeded: `INSERT INTO comparison_results (comparison_id, result_path, ..., result_type, left_entry_id, right_entry_id, ...) VALUES (1, 'report.txt', ..., 'matched', 1, 2, ...)` — using the two snapshot **root** entries (relative_path `''`), manually mislabeled with `result_path = 'report.txt'` — succeeded with no error. The two collision-pairing triggers (§8.1) key off `comparison_collision_members.entry_id`, not `result_path`; they only fire when `NEW.left_entry_id`/`NEW.right_entry_id` is itself a recorded collision member. They do not check whether `NEW.result_path` coincides with an existing `comparison_collision_groups.result_path` for entries that aren't members at all.

This is real but narrower than FSD-REAUDIT-001: it requires an internally-inconsistent write (a `result_path` that does not match either entry's actual folded path — no correctly-functioning scanner/diff engine would generate this, since `result_path` is derived from the entries being compared, not chosen independently). It does not resurrect the original defect's user-visible failure mode (two collision members silently declared "the same," or two different members each claimed as the one true match). It is nonetheless the literal scenario this task's own Audit 1 item 9 asks to test, and the schema does not defend against it. See Finding FSD-REAUDIT2-003.

## 9. Filesystem and Mount Policy Audit

### 9.1 Auto-mount contradiction — CLOSED

`docs/FILESYSTEM_PROVIDER_ARCHITECTURE.md` §3, step 1, now reads (in full): *"Ask macOS first. If macOS has already mounted the volume independently, FSD may read it through `NativeMountedProvider`. If the volume is recognized as a native-readable filesystem but is not mounted, FSD displays: 'Mount Read-Only and Capture'. FSD requests a read-only mount only after that explicit user action. If the user cancels or authorization fails, FSD performs no mount and no capture. FSD never silently requests a mount. FSD never silently unmounts. No read-write fallback exists. (See `SECURITY_AND_READ_ONLY_POLICY.md` for the complete normative policy.)"* — `grep -rn "successfully auto-mounts it once FSD requests it" docs` returns zero hits anywhere in the live tree; the phrase survives only inside the historical `docs/FSD_PLAN_GATE_AUDIT_GPT56SOL.md`, correctly quoting the original finding. `grep -rn "silent mount"` and `"automatic mount request"` both return zero live hits.

The canonical policy in `docs/SECURITY_AND_READ_ONLY_POLICY.md` ("Explicit Mount Consent Policy," 6 numbered points) independently covers all 7 required elements from this task's brief: already-mounted volumes readable freely (1); no silent mount request (2); explicit user action required for an unmounted native-readable filesystem (3); the action is named "Mount Read-Only and Capture" (3, 4); cancelling performs no mount/capture (5); no silent unmount (2, restated); no read-write fallback (6).

### 9.2 Filesystem cardinality — NOT CLOSED, regressed

`grep -rn "8 of the 9"` and `grep -rn "9 required filesystems"` (excluding historical/audit-report files) now return **zero** hits in `docs/FILESYSTEM_PROVIDER_ARCHITECTURE.md` and `docs/TEST_PLAN.md` — both of the previously-flagged instances there are genuinely fixed (now correctly "7 native-readable target variants," "one of the 10 filesystem variants," "10 filesystem variants across 7 filesystem families").

But:

- `docs/FILESYSTEM_FEASIBILITY_PLAN.md` line 27, inside §3's own "Phase 0A — Multi-filesystem feasibility and dependency proof" objective sentence: *"...that `NativeMountedProvider` correctly reads metadata from mounted images of the other three filesystems..."* — **unedited**. The correct count is seven (APFS, HFS+, FAT16, FAT32, exFAT, NTFS, UDF — everything in §2's fixture table other than ext2/ext3/ext4).
- `docs/MVP_PLAN.md` line 39: *"...`NativeMountedProvider` — the path six of the nine required filesystems use."* and line 42: *"all six natively-mountable filesystems (APFS, HFS+, FAT16, FAT32, exFAT, NTFS-ro, UDF)..."* — the parenthetical lists **seven** names while the prose twice says **six**, and "nine required" should be "ten." This is a **new** miscount (this file's previously-flagged "other three" instance is gone, replaced by this different, internally self-contradictory one) — not a regression of the same text, but a fresh defect introduced by this round's own edit pass.
- `docs/DECISIONS.md` ADR-014 (a live, canonical ADR): *"This narrows what was originally framed as a nine-filesystem embedded-reader problem down to a three-filesystem (ext2/3/4) one."* The "three-filesystem" (ext2/3/4 needing an embedded reader) half is correct. The "originally framed as nine-filesystem" half is not clearly labeled as a historical quotation and cannot be independently verified as an accurate description of an actual prior stated scope, as opposed to a bare propagation of the same recurring 9-vs-10 miscounting bug into a currently-normative decision record (`docs/FILESYSTEM_REPLAN_CLAUDE.md`, a historical document, used "9 required filesystems" from its own original text — it is plausible ADR-014 is just repeating that document's original miscount, not describing a distinct, genuinely-earlier "9" scope). Flagged for clarification, not asserted as definitely wrong.

**This finding directly matters for Phase 0A**, per the prior re-audit's own established reasoning, reproduced here and still applicable: the unedited `FILESYSTEM_FEASIBILITY_PLAN.md` instance sits inside Phase 0A's own objective statement — the same document and the same section this task's brief names as the single next executable task's specification.

### 9.3 Mount-consent duplication — CLOSED

`grep -rln "Explicit Mount Consent Policy" docs` now returns only `docs/SECURITY_AND_READ_ONLY_POLICY.md` (canonical) and `docs/FSD_PLAN_GATE_CORRECTION_GEMINI31.md` (a historical, dated correction report, correctly excluded from "live document" scope). `PRD.md`, `MVP_PLAN.md`, `TEST_PLAN.md`, and `FILESYSTEM_PROVIDER_ARCHITECTURE.md` no longer carry the duplicated six-line block; `FILESYSTEM_PROVIDER_ARCHITECTURE.md` instead cross-references the canonical copy (§9.1 above). This closes FSD-REAUDIT-007.

### 9.4 FSKit / System Extension characterization — CLOSED

`grep -rn "System Extension" docs` (excluding historical audit reports) returns zero hits. `docs/DEPENDENCY_AND_LICENSE_REVIEW.md` §3.5's packaging table now consistently reads "app extension" in both the table cell and the surrounding prose — the previously-flagged self-contradiction is gone.

## 10. Documentation Consistency

### 10.1 Grammar / find-replace damage

- `docs/DECISIONS.md` ADR-013: the empty-backtick artifact (`` no `` checksum files ``) is fixed — now correctly reads `.sha256` throughout. The false "the `handoffs/` directory deleted" claim is fixed — now correctly attributes the deletion to the legacy `AI_HANDOFFS/` directory.
- `docs/PROJECT_MANIFEST.md` invariant 9 and `docs/DEPENDENCY_AND_LICENSE_REVIEW.md` §3.4 — both originally-cited "a app extension" instances are fixed, now correctly "an app extension."
- **Not previously cited by name, still present:** `docs/AGENT.md` line 15 ("...a kernel extension, or a app extension...") and `docs/FILESYSTEM_REPLAN_CLAUDE.md` line 33 (two instances) both still read "a app extension." `AGENT.md` is a live, continuously-maintained canonical document (per the project's own document map) — this is a genuine open grammar defect in a currently-normative file, not merely historical narrative. `FILESYSTEM_REPLAN_CLAUDE.md` is a dated historical decision report; its instance is lower priority but still readable by a future implementer.

### 10.2 Hygiene sweep

```text
$ grep -rlnE "[ \t]+$" docs handoffs --include="*.md"
handoffs/FSD_PLAN_GATE_CORRECTION2_F_20260724-163544.md   (lines 4, 28)

$ grep -rlnE "^(<<<<<<<|=======|>>>>>>>)" docs handoffs --include="*.md"
(no output — zero merge-marker files)
```

The one file that fails the whitespace check is the correction Handoff currently under audit. Its own "Tests Run" section claims `grep -rlnE "[ \t]+$" docs --include="*.md"` returned "(Clean)" — a true statement, since that command was scoped to `docs/` only and the offending file lives in `handoffs/`, which the correction's own verification command never covered. `docs/FSD_PLAN_GATE_CORRECTION_GEMINI31.md`, the file cited by name in the prior re-audit's FSD-REAUDIT-009, is now confirmed clean.

### 10.3 Minor staleness (new observation, not previously flagged)

`docs/README.md` §"Status" still reads: *"R0 schema/normalization correction remains open pending a fresh audit."* Per §5 of this Handoff and the prior re-audit's own closure matrix, R0's substantive content (root integrity, comparison eligibility, normalization-version-mismatch blocking, collision-pairing at the group/member level) has been independently confirmed closed across the last two correction rounds; only the collision-pairing-in-`comparison_results` link (FSD-REAUDIT-001, tracked separately by this point) remained, and that is now also closed (§8.1). This status line is stale and could mislead a reader about how much of R0 is actually settled. Low priority, does not affect Phase 0A.

## 11. SQLite Verification

```text
$ sqlite3 <fresh-db> < docs/database/schema.sql
wal
$ sqlite3 <fresh-db> < docs/database/verify.sql
(applies cleanly; runtime errors shown are the script's own intentional negative-test assertions,
 including a genuinely new fixture at lines 360-362 exercising arbitrary collision-member pairing
 rejection -- this is new test coverage the prior correction round's verify.sql did not have)
$ sqlite3 <fresh-db> "PRAGMA integrity_check;"
ok
$ sqlite3 <fresh-db> "PRAGMA foreign_key_check;"
(no rows)
$ sqlite3 <fresh-db> "SELECT * FROM schema_migrations ORDER BY version;"
3|2026-07-24 16:59:30
```

Forbidden-state queries, run against this session's own collision fixture database after all §8 negative-test attempts had been made (not merely after cleanup):

```text
collision_members_as_ordinary_pairs    0
duplicate_collision_members            0
duplicate_collision_groups             0
```

Consistent with §8.1: these read zero because the forbidden INSERTs were rejected outright by the triggers, not because rows were written and later removed — the stronger form of evidence, per the prior re-audit's own methodological note about why residual-state queries alone are insufficient. §8.4's finding (an ordinary result claiming an already-collided path via unrelated entries) is not expressible by any of the brief's listed forbidden-state queries, for the same structural reason the prior re-audit noted about FSD-REAUDIT-001 itself: there is no stored fact recording which `result_path` "should" be exclusive to a collision group, so no `WHERE` clause can flag the gap. It was demonstrated by direct insertion (§8.1, test 9), not by a query.

## 12. Documentation Consistency

See §10 above (grammar/hygiene) and §9 (filesystem/mount policy documents). Historical-narrative classifications reconfirmed unchanged from the prior re-audit: "schema version 2" references in `FILESYSTEM_REPLAN_CLAUDE.md`/`SNAPSHOT_COLLECTIONS.md` correctly describe when fields were added, not a live requirement; "AI_HANDOFFS" references in `AGENT.md`, `DECISIONS.md`, `PROJECT_SUPPORT/HANDOFFS.md`, and various Handoffs are deliberate, accurate provenance records; "camera-vendor" mentions remain exclusion language throughout, never in-scope claims.

## 13. MCP CodeGraph Status

**NOT RUN — APPROPRIATE AT CURRENT STAGE.** Independently confirmed: no `.codegraph` directory exists; no production source scaffold of any kind exists anywhere in the tree. Not invoked by this audit, per instruction — the mandatory first-implementation-session gate (check availability → scaffold → index → real query → record → report `BLOCKED` if unavailable) does not apply because no implementation session is underway.

## 14. Findings

### [HIGH] FSD-REAUDIT2-001 — Filesystem-cardinality miscounts remain open inside Phase 0A's own objective text, and a new miscount was introduced

**Evidence**

- `docs/FILESYSTEM_FEASIBILITY_PLAN.md` line 27 (inside §3, "Phase 0A — Multi-filesystem feasibility and dependency proof"): *"...that `NativeMountedProvider` correctly reads metadata from mounted images of the other three filesystems..."* — unedited since the prior re-audit flagged it.
- `docs/MVP_PLAN.md` lines 39, 42: *"the path six of the nine required filesystems use"* and *"all six natively-mountable filesystems (APFS, HFS+, FAT16, FAT32, exFAT, NTFS-ro, UDF)"* — a new miscount (prose says six/nine; the parenthetical lists seven names; correct is seven/ten).
- `docs/DECISIONS.md` ADR-014: "originally framed as a nine-filesystem embedded-reader problem" — not clearly labeled as historical quotation, unverifiable against project history.

**Finding**

The correct, established figure (10 variants / 7 native-readable / 3 embedded-raw) is not consistently applied. One of the three instances flagged in the prior re-audit round is completely unaddressed; a second was edited into a different, internally self-contradictory error rather than corrected; a third, newly-noticed instance sits in a currently-normative ADR.

**Impact**

`FILESYSTEM_FEASIBILITY_PLAN.md` §3 is, by this project's own document map, the specification for the single next executable task this audit is asked to authorize. An implementer scoping the spike from this document's literal text would under-provision the native-provider validation matrix.

**Required correction**

Replace "other three filesystems" with "other seven filesystems" in `FILESYSTEM_FEASIBILITY_PLAN.md` line 27. Replace "six of the nine" with "seven of the ten" and "all six natively-mountable filesystems" with "all seven natively-mountable filesystems" in `MVP_PLAN.md` lines 39/42 (the existing seven-name parenthetical is already correct and does not need to change). Clarify or remove the unlabeled "nine-filesystem" framing in `DECISIONS.md` ADR-014. Re-verify by grep afterward, not by assertion, across all live documents including `handoffs/` and any file not previously on the cited list.

**Gate**

- Blocks Phase 0A: YES
- Blocks Phase 0: YES

### [MEDIUM] FSD-REAUDIT2-002 — Normalization-compatibility identity is still an unverifiable, unrejected placeholder, and canonical documents now disagree on its value

**Evidence**

- `docs/database/schema.sql` line 109: `normalization_version TEXT NOT NULL DEFAULT 'fsd-normalizer-v1_app-v1_os-UNRECORDED_PLACEHOLDER'` — no CHECK or trigger anywhere in the schema rejects this value, or an explicit blank string, when a snapshot transitions to `complete` (independently reproduced, §7).
- `docs/DECISIONS.md` ADR-009: states the normalization-version string should be the literal `fsd-path-v1-foundation-nfc-posix-casefold` — a third value, matching neither schema default.

**Finding**

The specific `unicode-15.0` false-precision claim is gone (genuine progress), but the schema still permits a snapshot to reach `complete` status carrying a self-admittedly fake or entirely blank compatibility identity, and two such snapshots can be compared as verified-compatible purely because they share the same placeholder text. The ADR and the schema default no longer agree on what the field's real value should be.

**Impact**

This is precisely the failure mode ADR-011's mismatch-blocks-comparison policy exists to prevent: a scanner bug or omission that fails to populate the real compatibility identity would silently produce false "verified compatible" comparisons rather than a loud, blocking error.

**Required correction**

Either capture the actual runtime OS build/normalizer implementation version at scan time and reject placeholder/blank values via a trigger on the `scanning`→`complete` transition (mirroring `trg_snapshots_complete_root_check`'s pattern), or explicitly document, with a stated confidence level, why a fixed literal is acceptable. Reconcile `DECISIONS.md` ADR-009 with whatever the schema actually asserts once fixed.

**Gate**

- Blocks Phase 0A: NO (the disk-image feasibility spike has no cross-machine comparison stakes and does not touch the catalog, per `FILESYSTEM_FEASIBILITY_PLAN.md` §3's own explicit scope)
- Blocks Phase 0: YES

### [MEDIUM] FSD-REAUDIT2-003 — An ordinary `comparison_results` row can claim a `result_path` already owned by a collision group

**Evidence**

- `/private/tmp/fsd-reaudit2-0724-10/fixture1_full.sql`, test 9 (§8.1, §8.4): `INSERT INTO comparison_results (..., result_path, ..., result_type, left_entry_id, right_entry_id, ...) VALUES (1, 'report.txt', ..., 'matched', 1, 2, ...)` succeeded using two entries that are not collision-group members at all.
- `docs/database/schema.sql` lines 453–491: both collision-pairing triggers key exclusively on `comparison_collision_members.entry_id` membership, never on `comparison_results.result_path` matching an existing `comparison_collision_groups.result_path`.

**Finding**

The schema does not enforce that a `result_path` with an active collision group cannot also host an unrelated ordinary row. This is narrower than FSD-REAUDIT-001 (it requires an internally-inconsistent write no correctly-functioning scanner/diff engine would generate, since `result_path` is normally derived from the entries it labels) but is the literal scenario this task's own Audit 1, item 9 asks to verify, and it is not defended against.

**Impact**

Low likelihood of occurring from correct application code, but if it did (e.g. a diff-engine bug that computes `result_path` independently of the entries it stores), the UI could present both a collision group and a conflicting ordinary row for the same path with no constraint noticing.

**Required correction**

Add a trigger rejecting any `comparison_results` INSERT/UPDATE where `result_type IN ('matched','changed','added','removed')` and `EXISTS (SELECT 1 FROM comparison_collision_groups WHERE comparison_id = NEW.comparison_id AND result_path = NEW.result_path)`, regardless of whether the specific entries are already-recorded members.

**Gate**

- Blocks Phase 0A: NO (catalog-independent per §14/FSD-REAUDIT2-002's same reasoning)
- Blocks Phase 0: YES

### [LOW] FSD-REAUDIT2-004 — Cascade-delete and collision-pairing guarantees depend on every connection enabling `PRAGMA foreign_keys`, which the schema cannot enforce and `ARCHITECTURE.md` does not mandate

**Evidence**

- `docs/database/schema.sql` line 16: `PRAGMA foreign_keys = ON;` — a per-connection SQLite setting, not persisted in the database file (independently reproduced in §8.3: a connection that does not re-issue this pragma can delete a `comparisons` row without cascading to its `comparison_collision_groups`/`comparison_results` children, leaving orphans that `PRAGMA foreign_key_check` then flags).
- `docs/ARCHITECTURE.md` lines 119–126: lists `PRAGMA foreign_keys = ON` under "Recommended SQLite settings," not as a mandatory per-connection requirement.
- `docs/REVIEW_CLAUDE_CODE.md` line 264 (historical, already on record): flags this exact risk and recommends `ARCHITECTURE.md` mandate the connection factory apply it on every connection open — not yet incorporated.

**Finding**

The collision-pairing triggers verified in §8.1 are true SQLite `TRIGGER`s and fire unconditionally regardless of this pragma — they are not at risk. But the cascade-delete cleanliness verified in §8.3, and any other `ON DELETE CASCADE`/`RESTRICT`/`SET NULL` behavior the schema relies on, is entirely contingent on the connecting client enabling foreign-key enforcement on every connection it opens.

**Impact**

Not a schema defect — this is standard SQLite behavior — but a real operational risk to data integrity guarantees this correction round is relying on, already identified once and not yet acted on.

**Required correction**

Update `ARCHITECTURE.md`'s connection-factory description to state `PRAGMA foreign_keys = ON` (and the other per-connection settings) must be applied on every connection open, not merely recommended; consider a debug-build startup assertion.

**Gate**

- Blocks Phase 0A: NO
- Blocks Phase 0: NO (pre-existing, already-documented risk; worth closing before real persistence code lands, not before the disk-image spike)

### [LOW] FSD-REAUDIT2-005 — "a app extension" grammar defect persists in a live canonical document, and the correction's own hygiene sweep missed its own new file

**Evidence**

- `docs/AGENT.md` line 15: "...a kernel extension, or a app extension..." — live, continuously-maintained document, not previously cited by name.
- `docs/FILESYSTEM_REPLAN_CLAUDE.md` line 33 (two instances) — historical document.
- `handoffs/FSD_PLAN_GATE_CORRECTION2_F_20260724-163544.md` lines 4 and 28: trailing whitespace; the Handoff's own "Tests Run" section claims a clean sweep, scoped only to `docs/`.

**Finding**

Both are minor, mechanical hygiene defects in live or newly-created files, not previously flagged by exact name (so not regressions of a specifically-cited item, but not closed as a defect class either).

**Impact**

Cosmetic; does not affect schema behavior or blocking policy logic.

**Required correction**

Fix `docs/AGENT.md` line 15 ("an app extension"); strip trailing whitespace from the correction Handoff; going forward, scope hygiene-sweep grep commands to the whole repository (`docs handoffs`), not `docs` alone, so a session's own new Handoff is checked too.

**Gate**

- Blocks Phase 0A: NO
- Blocks Phase 0: NO

### [LOW] FSD-REAUDIT2-006 — `README.md` Status section is stale regarding R0 closure

**Evidence**

- `docs/README.md` line 97: "R0 schema/normalization correction remains open pending a fresh audit."

**Finding**

Per §5/§8 of this Handoff, R0's substantive content is now closed across two correction rounds; this line has not been updated to reflect that.

**Impact**

Could mislead a reader skimming only the README about how much design work remains open.

**Required correction**

Update `README.md`'s Status section to reflect current closure state once the findings in this Handoff are corrected.

**Gate**

- Blocks Phase 0A: NO
- Blocks Phase 0: NO

## 15. Remaining Risks

- FSD-REAUDIT2-001 (filesystem cardinality) is the only remaining HIGH-severity, Phase-0A-gating item. Its scope is now narrow and purely textual (three sentences across two documents plus one ADR clarification) — unlike the schema-level defects closed this round, it requires no design work, only a careful, verified edit pass, followed by a repository-wide grep (not a `docs`-only grep) to confirm.
- FSD-REAUDIT2-002 (normalization identity) and FSD-REAUDIT2-003 (result_path collision-group leak) are both schema-level gaps that do not block Phase 0A (the disk-image spike is explicitly catalog-independent) but should be closed before Phase 0 begins writing real persistence code against this schema, to avoid building application logic atop an identity contract that will need to change shape.
- The pattern across two consecutive correction rounds — closing the specifically-cited critical items while a cardinality/count-style defect persists or mutates into a new variant — suggests grep-verification-after-edit (not assertion) should be a mandatory last step of any future correction round, exactly as this task's own brief already requires ("re-verify by grep after editing, not by assertion").
- FSD-REAUDIT2-004 (per-connection `PRAGMA foreign_keys`) is a pre-existing, already-once-flagged risk, not new; it does not block either gate but is directly load-bearing for the guarantees this Handoff spent the most independent-verification effort confirming (§8), so it is worth resolving before Phase 0's real connection-factory code is written, not after.

## 16. Phase 0A Readiness

**NOT READY.** Per this task's own Phase 0A readiness checklist: "no arbitrary collision pairing is possible" — true (§8.1, 8 of 9 required tests pass; the 9th is a narrower, separately-tracked gap that does not resurrect arbitrary member pairing); "mount consent is coherent and single-sourced" — true (§9.1, §9.3); "every snapshot begins as `scanning`" — true (§6); "schema and fixtures pass independently" — true (§11) with the two open schema-level findings noted (§14); "no canonical contradiction blocks implementation" — **not true**: FSD-REAUDIT2-001's unedited instance sits directly inside the specification for the one next executable task, which is the specific condition the prior re-audit round used to gate Phase 0A on this exact finding, and that condition has not changed. "Filesystem counts are correct everywhere" is explicitly listed as a readiness requirement and is not met.

The single executable Phase 0A task remains correctly and completely defined independent of this finding — no further definition work is needed once the correction is made:

> Build and run the disk-image-only ext2/ext3/ext4 libfsext feasibility spike.

This task is not authorized to start in this audit.

## 17. Chatbox Transition Decision

STAY IN AUDIT/PLAN

## 18. Git Status

```text
$ git status --short
fatal: not a git repository (or any of the parent directories): .git   (exit 128)
$ git diff --check
usage: git diff --no-index ...   (exit 129, no repository to diff against)
```

GIT STATUS: BLOCKED — NOT A REPOSITORY

## 19. Commit Readiness

NOT APPLICABLE — no Git repository exists. No commit was made or attempted.

## 20. Push Readiness

NOT AUTHORIZED — no Git repository, no remote, no push performed or requested.

## 21. Final Decision

REJECT — CORRECTIONS REQUIRED

## 22. Exact Next Action

Assign a third, narrowly-scoped corrective round limited to the six findings in §14, prioritizing FSD-REAUDIT2-001 first since it is the only remaining Phase-0A-gating item and the smallest in scope (three sentences across two documents plus one ADR clarification). Do not begin Phase 0A until a subsequent independent re-audit — run against fresh, self-authored fixtures and a repository-wide (not `docs`-only) grep sweep, exactly as this round was — confirms FSD-REAUDIT2-001 is closed with zero remaining live-document instances. FSD-REAUDIT2-002 through -006 do not block Phase 0A and may be closed in the same round or deferred to immediately precede Phase 0, at the user's discretion, but should not be carried silently into Phase 0 implementation.
