# Handoff: FSD-PLAN-GATE-REAUDIT-0724-08

AGENT: Claude (GPT-5.6-Sol role assignment per task)
ROLE: PRIMARY INDEPENDENT RE-AUDIT
MODE: audit
TASK ID: FSD-PLAN-GATE-REAUDIT-0724-08
PHASE: AUDIT AND PLANNING

## OBJECTIVE

Independently re-audit the corrected FSD planning package (schema version 3 plus the "Plan Gate Correction" documentation round) and determine whether the prior audit's findings are actually closed, whether Phase 0A may begin, and whether the user should move from AUDIT/PLAN to CONTROL. Every claim in the correction Handoff and correction report was independently reproduced against fresh SQLite databases built outside the repository — none were accepted on the correction agent's word.

## REPOSITORY STATE

- `FSD_ROOT`: `/Users/cenvu/Desktop/DEV/FSD`. No `.git`, no `.codegraph`, no production source of any kind (`.swift`/`.m`/`.mm`/`.c`/`.cc`/`.cpp`/`.xcodeproj`/`Package.swift` — none found).
- `docs/database/schema.sql` declares schema version 3; fresh apply produces exactly one `schema_migrations` row (`3`).
- No nested `AI_HANDOFFS/` directory; `handoffs/` remains flat with no `.sha256` files.
- This re-audit created only `docs/FSD_PLAN_GATE_REAUDIT_GPT56SOL.md` and this Handoff. No schema, fixture, or canonical document was modified.

## FILES READ

All seven flat Handoffs in `handoffs/`; `docs/FSD_PLAN_GATE_AUDIT_GPT56SOL.md`; `docs/FSD_PLAN_GATE_CORRECTION_GEMINI31.md`; `docs/database/schema.sql` and `docs/database/verify.sql` in full; `docs/DECISIONS.md`, `docs/ARCHITECTURE.md`, `docs/PRD.md`, `docs/MVP_PLAN.md`, `docs/PRODUCT_STATE.md`, `docs/PROJECT_MANIFEST.md`, `docs/KNOWN_ISSUES.md`, `docs/TEST_PLAN.md`, `docs/SECURITY_AND_READ_ONLY_POLICY.md`, `docs/FILESYSTEM_PROVIDER_ARCHITECTURE.md`, `docs/FILESYSTEM_SUPPORT_MATRIX.md`, `docs/DEPENDENCY_AND_LICENSE_REVIEW.md`, `docs/FILESYSTEM_FEASIBILITY_PLAN.md`, `docs/SNAPSHOT_COLLECTIONS.md`, `docs/SNAPSHOT_COLLECTIONS_REVIEW_CLAUDE.md`. `docs/FILESYSTEM_REPLAN_CLAUDE.md` and `docs/REVIEW_CLAUDE_CODE.md` spot-checked as dated historical artifacts, not audited line-by-line.

## COMMANDS EXECUTED

```sh
find <FSD_ROOT> -iname "*.swift" -o -iname "*.m" -o ... # confirm no production code
test -d .codegraph; test -d .git
git status --short; git diff --check
mkdir -p /private/tmp/fsd-reaudit-0724-08
sqlite3 /private/tmp/fsd-reaudit-0724-08/reaudit.sqlite3 < docs/database/schema.sql
sqlite3 ... "SELECT * FROM schema_migrations ORDER BY version;"
sqlite3 ... "PRAGMA integrity_check; PRAGMA foreign_key_check;"
sqlite3 ... < reaudit1_lifecycle.sql   # self-authored, 15 fixtures
sqlite3 ... < reaudit2_comparisons.sql # self-authored, 12 fixtures
sqlite3 ... < reaudit3_collision.sql   # self-authored, 17 fixtures
sqlite3 ... < reaudit7_collections.sql # self-authored, 9 fixtures
sqlite3 ... "<consolidated forbidden-state UNION ALL query>"
grep -rn "exact byte|e\.g\. NFC|lowercase path|schema version 2|v1→v2|v2→v3|7 of 9|8 filesystems|9 filesystems|other six|other three|system extension|silent mount|auto-mount|AI_HANDOFFS|\.sha256|camera-vendor" docs --include="*.md"
grep -rlnE "[ \t]+$" docs --include="*.md"
grep -rlnE "^(<<<<<<<|=======|>>>>>>>)" docs --include="*.md"
rm -f /private/tmp/fsd-reaudit-0724-08/reaudit.sqlite3*   # scratch DB deleted; fixture .sql files retained as evidence
```

Full output for every command is in `docs/FSD_PLAN_GATE_REAUDIT_GPT56SOL.md` §5–§13.

## PRIOR FINDING CLOSURE MATRIX

R0-01 CLOSED · R0-02 CLOSED · R0-03 CLOSED · R0-04 CLOSED (unchanged) · R0-05 CLOSED · R0-06 CLOSED · **R0-07 OPEN** · R0-08 CLOSED · R0-09 CLOSED (unchanged) · R0-10 CLOSED · R0-11 CLOSED (substance; hygiene issue remains) · R0-12 PARTIALLY CLOSED · R0-13 CLOSED (unchanged) · R0-14 PARTIALLY CLOSED · **FSD-AUDIT-007 OPEN/REGRESSED** · FSD-AUDIT-008 CLOSED. Full evidence per item in the report §4.

## ROOT INTEGRITY RESULT

CLOSED and independently reproduced. Direct INSERT of `complete`/`complete_with_warnings` rejected; zero-root→complete transition rejected; one-root→complete accepted; terminal-status reversion (to `scanning`/`failed`/`interrupted`/`cancelled`) rejected in all four directions; `REPLACE INTO` bypass rejected; cross-snapshot parent rejected; same-snapshot parent accepted. New finding: direct INSERT of `failed`/`cancelled`/`interrupted` succeeds, bypassing the documented `scanning`-first entry point (FSD-REAUDIT-004, MEDIUM, does not block Phase 0A).

## COMPARISON RESULT

Fully CLOSED and independently reproduced. Matching-version complete sources accepted; mismatched version rejected; `scanning`/`interrupted`/`failed`/`cancelled` sources all rejected; `complete_with_warnings` and complete-transient sources accepted; `left_snapshot_id`/`right_snapshot_id` UPDATE rejected in both directions (full immutability); a used source cannot later become ineligible (terminal-status trigger prevents it); unrelated comparison fields remain freely updateable.

## COLLISION GROUP RESULT

PARTIALLY CLOSED — **the central claim does not hold.** `comparison_collision_groups`/`comparison_collision_members` are correctly built (one group per path, duplicate group/member rejected, correct-side-only membership enforced both directions, unrelated-snapshot entries rejected, cascade-delete clean, entries survive). But `comparison_results` has no relationship to these tables at all: independently reproduced two arbitrary pairings — a collision member paired with an unrelated entry, and two different collision members each independently paired with the same counterpart — both inserted successfully with no constraint violation. This is the original R0-07/FSD-AUDIT-003 defect, unresolved. See FSD-REAUDIT-001, CRITICAL.

## NORMALIZATION CONTRACT RESULT

The "exact byte"/"e.g. NFC" stale wording is genuinely gone from every live document (CLOSED). A new issue was found instead: the standardized `normalization_version` literal `fsd-algo-v1_app-v1.0_unicode-15.0` hardcodes a Unicode Consortium data-version claim Apple does not document guaranteeing across the macOS 13+ target range, and FSD has no mechanism to verify it matches the actual runtime OS/ICU. FSD-REAUDIT-005, MEDIUM, does not block Phase 0A, blocks Phase 0.

## SCHEMA BASELINE RESULT

CLOSED and independently reproduced. `SELECT * FROM schema_migrations ORDER BY version;` on a fresh database returns exactly one row: `3`. No stale v1/v2 rows, no live "schema version 2" requirement claim remaining outside historical narrative in dated reports.

## FILESYSTEM AND MOUNT RESULT

**OPEN.** `FILESYSTEM_PROVIDER_ARCHITECTURE.md` §3's literal auto-mount sentence ("macOS successfully auto-mounts it once FSD requests it") is unedited and now sits in the same document as a newly-appended, unreconciled "Explicit Mount Consent Policy" forbidding exactly that. FSD-REAUDIT-002, CRITICAL. Separately: filesystem-cardinality miscounts ("9 required", "8 of the 9") remain unfixed in two live documents contrary to the correction's explicit "zero remaining instances" claim, and a new wrong count ("other three filesystems," should be seven) was introduced identically across three documents. FSD-REAUDIT-003, HIGH. FSKit's "app extension" (not "system extension") recharacterization is independently verified as factually supportable (FSKit uses appex/ExtensionKit technology per Apple's own terminology), but the edit is incomplete — one document still says "System Extension" in a bolded table cell three words before contradicting itself.

## COLLECTION LAST_USED RESULT

Fully CLOSED and independently reproduced across all eight required sub-behaviors plus a ninth (multi-column UPDATE) probe: insert-with-Collection advances; move advances only the destination; move-to-Unsorted advances nothing; display_name/user_note edits advance nothing; a failed reassignment (FK violation) leaves state unchanged; session_number/started_at remain stable; Collection deletion detaches without deleting the snapshot.

## SQLITE RESULTS

Fresh apply: `wal` / `schema_migrations` = `{3}` / `integrity_check` = `ok` / `foreign_key_check` = no rows. All ten of the brief's exact forbidden-state queries returned `0`. Note: the zero-row result for collision-related forbidden states reflects that this re-audit's own reproduction rows were subsequently removed during its cascade-delete test, not the absence of the defect — the defect was demonstrated by the INSERT succeeding at the time it was attempted (see COLLISION GROUP RESULT above and report §11 for the exact reasoning on why no forbidden-state query can detect this specific gap).

## DOCUMENT CONSISTENCY RESULT

FAILED in specific, reproducible ways despite the correction's claim of a "comprehensive regex sweep" confirming zero remaining issues: `DECISIONS.md` ADR-013 contains an empty-backtick artifact and a factually false claim that the currently-active flat `handoffs/` directory "has been deleted" (should say `AI_HANDOFFS/`); "a app extension" grammar errors in two documents; a "System Extension"/"app extensions" self-contradiction within one paragraph of `DEPENDENCY_AND_LICENSE_REVIEW.md`; the "Explicit Mount Consent Policy" duplicated verbatim across five documents instead of defined once; one file (`FSD_PLAN_GATE_CORRECTION_GEMINI31.md`) with trailing whitespace. Full findings FSD-REAUDIT-006, 007, 009.

## MCP CODEGRAPH STATUS

NOT RUN — APPROPRIATE AT CURRENT STAGE. Independently confirmed no `.codegraph` directory and no production source scaffold exist. Not invoked by this re-audit, per instruction.

## VERIFIED CLAIMS

- Root-completion integrity (INSERT and UPDATE paths), terminal-status immutability, comparison-source eligibility and immutability, schema-migration baseline, and Collection `last_used_at` are all genuinely fixed and independently reproduced, not merely re-asserted.
- FSKit's "app extension" recharacterization is factually supportable (independently researched against Apple's own ExtensionKit/appex terminology for FSKit), separate from whether the edit was completely applied.
- No production Swift/Xcode/CodeGraph artifacts exist; Git remains uninitialized.

## UNVERIFIED CLAIMS

- Runtime filesystem support for any target filesystem on real macOS 13+/arm64 hardware — unchanged, still Phase 0A/2/3 work.
- Whether Apple in fact guarantees no Unicode/ICU data-version drift across the macOS 13+ range (researched but inconclusive from public sources; treated as unverified rather than asserted either way — see FSD-REAUDIT-005).
- Whether the correction agent's `verify.sql` fixtures, run by that agent, actually reproduced the same results this re-audit found — this re-audit did not execute `verify.sql` itself as evidence (per instruction, the correction's own `verify_output.txt`-equivalent claims were not accepted as independent evidence); it built and ran entirely separate fixtures instead.

## FINDINGS BY SEVERITY

- CRITICAL FSD-REAUDIT-001: arbitrary collision-member pairing still possible in `comparison_results`.
- CRITICAL FSD-REAUDIT-002: auto-mount contradiction persists verbatim in the operative provider-selection text.
- HIGH FSD-REAUDIT-003: filesystem-cardinality claims wrong in two ways (unfixed originals + new regression).
- MEDIUM FSD-REAUDIT-004: snapshots directly insertable in failed/cancelled/interrupted status.
- MEDIUM FSD-REAUDIT-005: hardcoded, unverifiable Unicode-version literal in `normalization_version`.
- LOW FSD-REAUDIT-006: broken/self-contradictory sentences from mass find-replace.
- LOW FSD-REAUDIT-007: duplicated mount-consent policy across five documents.
- LOW FSD-REAUDIT-008: recurring Handoff role-code/stated-role mismatch.
- LOW FSD-REAUDIT-009: trailing whitespace in the correction report.

## REQUIRED CORRECTIONS

1. Link `comparison_results` to the collision-group model (or stop persisting per-pair rows for collision members) and add a fixture that specifically rejects arbitrary same-side-correct pairing.
2. Rewrite `FILESYSTEM_PROVIDER_ARCHITECTURE.md` §3 to state the actual consent-gated mount flow; delete four of the five duplicated policy blocks and cross-reference the one kept (recommend `SECURITY_AND_READ_ONLY_POLICY.md`).
3. Fix every remaining "9 required"/"8 of the 9" instance and every "other three filesystems" instance to the correct 10-variant/7-family, 7-native framing; re-verify by grep after editing, not by assertion.
4. Decide and enforce (or explicitly document as intentional) whether non-`scanning` statuses may be directly inserted.
5. Capture actual runtime OS/ICU version data alongside the normalization-version literal, or explicitly document the confidence level of the fixed-literal assumption.
6. Fix the ADR-013 broken sentences, the grammar artifacts, and the System-Extension/app-extension self-contradiction individually; re-run this re-audit's grep set to confirm.
7. Correct the Handoff role code to `F`; strip trailing whitespace from the correction report.

## REMAINING BLOCKERS

FSD-REAUDIT-001 and FSD-REAUDIT-002 are both direct reproductions of originally-HIGH, explicitly Phase-0A-and-Phase-0-blocking findings that the correction round's own Executive Summary claimed to have closed. Per the task's standing rule, any implementation-blocking finding blocks both Phase 0A and Phase 0.

## PHASE 0A READINESS

NOT READY. The single executable Phase 0A task ("Build and run the disk-image-only ext2/ext3/ext4 libfsext feasibility spike") remains correctly and completely defined by the existing specification independent of these findings — no further definition work is needed once the blockers above clear.

## CHATBOX TRANSITION DECISION

STAY IN AUDIT/PLAN

## GIT STATUS

BLOCKED — `/Users/cenvu/Desktop/DEV/FSD` is not a Git repository (`.git` absent). `git status --short` exit 128; `git diff --check` exit 129. Not initialized, per constraints.

## COMMIT READINESS

NOT APPLICABLE — no Git repository exists.

## PUSH READINESS

NOT AUTHORIZED — no Git repository, no remote, no push performed or requested.

## FINAL DECISION

REJECT — CORRECTIONS REQUIRED

## EXACT NEXT ACTION

Assign a second corrective round scoped specifically to the 7 "Required Corrections" above, prioritizing FSD-REAUDIT-001 and -002 first since they are the load-bearing blockers. Do not begin Phase 0A implementation work until a subsequent independent re-audit, run against fresh self-authored fixtures rather than the correcting agent's own test output, confirms both are closed.
# FSD Plan Gate Re-Audit

**Audit date:** 2026-07-24
**Task:** FSD-PLAN-GATE-REAUDIT-0724-08
**Scope:** Independent re-audit of the corrected planning/schema package. No application code, canonical-document, or schema changes were made. Every claim in the correction Handoff and correction report was independently reproduced against a fresh SQLite database built outside the repository, not accepted on the correction agent's word.

## 1. Executive Decision

**REJECT — CORRECTIONS REQUIRED.**

The correction round genuinely closed several real defects — comparison-source eligibility and immutability, root-completion integrity on the INSERT path, terminal-status immutability, the schema-migration baseline, and Collection `last_used_at` all independently reproduce exactly as claimed. That is real progress and is credited below, finding by finding.

But the correction's central claim — "FSD-AUDIT-003 (High): Arbitrary collision pairing replaced with a durable group/member model... This completely eliminates arbitrary member pairing" — **does not hold up under direct reproduction.** The new `comparison_collision_groups`/`comparison_collision_members` tables are correctly built and correctly constrained, but they are never referenced by `comparison_results`. This re-audit inserted the exact original bug — two different left-side collision members (`Report.txt`, `REPORT.txt`) each independently recorded as `matched` against the same right-side entry, and a collision member paired against an entirely unrelated right-side entry with no relationship to it at all — and both succeeded without any constraint violation. The original R0-07 / FSD-AUDIT-003 defect is reproduced identically post-correction.

Separately, **FSD-AUDIT-007's auto-mount contradiction was not fixed at all.** The correction appended a new "Explicit Mount Consent Policy" block to five documents, but the specific sentence originally flagged — `FILESYSTEM_PROVIDER_ARCHITECTURE.md` §3: *"or macOS successfully auto-mounts it once FSD requests it"* — is still present, verbatim, in the same document that now also contains the new policy's *"FSD must never silently request a new mount."* The document contradicts itself internally.

A third, independently-discovered issue: the correction's own filesystem-cardinality fix introduced a **new, factually wrong claim** — "the other three filesystems" (should be seven: APFS, HFS+, FAT16, FAT32, exFAT, NTFS, UDF) — propagated identically into three separate documents (`FILESYSTEM_FEASIBILITY_PLAN.md`, `PRODUCT_STATE.md`, `MVP_PLAN.md`), while the pre-existing "9 required filesystems" miscounting the correction explicitly claimed to have eliminated ("zero remaining instances... concerning 8/9 filesystems") is still present, unedited, in `FILESYSTEM_PROVIDER_ARCHITECTURE.md` (twice) and `TEST_PLAN.md`.

Per the task's own rule, any implementation-blocking R0/finding blocks both Phase 0A and Phase 0. Two of the three originally-HIGH, Phase-0A-blocking findings (collision pairing, auto-mount contradiction) are independently confirmed still open. **The user should remain in AUDIT/PLAN.**

## 2. Repository State

- `FSD_ROOT`: `/Users/cenvu/Desktop/DEV/FSD` (the `DEV` spelling resolves; `Dev` is the same inode on case-insensitive APFS).
- Current state: **AUDIT AND PLANNING**, confirmed by `docs/PRODUCT_STATE.md`.
- No `.git` directory. No `.codegraph` directory.
- No `.swift`, `.m`, `.mm`, `.c`, `.cc`, `.cpp`, `.xcodeproj`, or `Package.swift` anywhere in the tree.
- `docs/database/schema.sql` declares itself schema version 3; a fresh database's `schema_migrations` table contains exactly one row: `3`. No stale `1`/`2` rows remain (this is a genuine, verified fix — see §8).
- No nested `AI_HANDOFFS/` directory exists. `handoffs/` remains flat, contains no `.sha256` files, and gained exactly two new files from the prior correction/audit round (`FSD_PLAN_GATE_AUDIT_A_20260724-225352.md`, `FSD_PLAN_GATE_CORRECTION_C_20260724-230500.md`) plus this re-audit's own Handoff.
- This re-audit created only this report and its required flat Handoff. No schema, fixture, or canonical document was modified. All SQLite work ran against fresh databases at `/private/tmp/fsd-reaudit-0724-08/`, outside the repository, and was deleted after use (the fixture `.sql` files themselves were left in place as reproducible evidence artifacts).

## 3. Evidence Reviewed

Read in full: every flat Handoff in `handoffs/` (seven files, including the two new ones from this correction round); `docs/FSD_PLAN_GATE_AUDIT_GPT56SOL.md` and `docs/FSD_PLAN_GATE_CORRECTION_GEMINI31.md`; `docs/database/schema.sql` and `docs/database/verify.sql` in full; `docs/DECISIONS.md`, `docs/ARCHITECTURE.md`, `docs/PRD.md`, `docs/MVP_PLAN.md`, `docs/PRODUCT_STATE.md`, `docs/PROJECT_MANIFEST.md`, `docs/KNOWN_ISSUES.md`, `docs/TEST_PLAN.md`, `docs/SECURITY_AND_READ_ONLY_POLICY.md`, `docs/FILESYSTEM_PROVIDER_ARCHITECTURE.md`, `docs/FILESYSTEM_SUPPORT_MATRIX.md`, `docs/DEPENDENCY_AND_LICENSE_REVIEW.md`, `docs/FILESYSTEM_FEASIBILITY_PLAN.md`, `docs/SNAPSHOT_COLLECTIONS.md`, `docs/SNAPSHOT_COLLECTIONS_REVIEW_CLAUDE.md`. `docs/FILESYSTEM_REPLAN_CLAUDE.md` and `docs/REVIEW_CLAUDE_CODE.md` were spot-checked as historical, dated decision reports (not continuously-maintained canonical documents) rather than audited line-by-line against current state.

Independent SQL evidence: four self-authored fixture files (`reaudit1_lifecycle.sql` through `reaudit7_collections.sql`, plus the forbidden-state consolidated query) run against a schema freshly applied outside the repository — not the correction agent's `verify.sql`, though `verify.sql` was read in full and its own new fixtures (lines 237–404) were independently cross-checked rather than trusted.

## 4. Prior Finding Closure Matrix

| ID | Status | Independent evidence |
|---|---|---|
| R0-01 (decisions not canonicalized) | CLOSED | `ARCHITECTURE.md` §5 no longer contains "exact byte/string" or "e.g. NFC" language (grep-confirmed absent from every live canonical document); ADR-009 through ADR-012 remain the aligned normative source. |
| R0-02 (normalization illustrative) | CLOSED | Same fix; §5 now states the Foundation NFC/case-fold recipe directly rather than "e.g." language. See FSD-REAUDIT-005 for a new, narrower issue this introduced. |
| R0-03 ("exact bytes" claim) | CLOSED | Confirmed absent by grep across all live `.md` files; only appears now inside the audit/correction reports themselves, as historical quotation. |
| R0-04 (case sensitivity representation) | CLOSED (unchanged) | Schema retains `sensitive`/`insensitive`/`unknown`; not touched by this round, no regression found. |
| R0-05 (normalization-version mismatch bypassable via UPDATE) | CLOSED | Independently reproduced: `UPDATE comparisons SET right_snapshot_id = ...` now fails with `Comparison source snapshot IDs are immutable` (§6). |
| R0-06 (root/parent integrity incomplete — direct-complete-insert bypass) | CLOSED | Independently reproduced: direct `INSERT ... status='complete'` and `'complete_with_warnings'` both rejected at INSERT time (§5, T1/T2); `REPLACE INTO` bypass also rejected (T10). |
| R0-07 (collisions arbitrarily paired) | **OPEN** | Independently reproduced: `comparison_results` accepts an arbitrary pairing of a collision-group member against an unrelated entry, and accepts two different collision-group members independently paired against the same counterpart entry — the identical original defect (§7, FSD-REAUDIT-001). |
| R0-08 (transient lifecycle vague / interrupted transient usable) | CLOSED | Independently reproduced: `interrupted`, `scanning`, `failed`, `cancelled` sources are all rejected at comparison-INSERT time regardless of `snapshot_kind`; a `complete` transient is correctly accepted (§6). |
| R0-09 (referenced transient could be deleted) | CLOSED (unchanged) | `ON DELETE RESTRICT` unchanged; not touched by this round, no regression. |
| R0-10 (coding gate not recorded) | CLOSED | `PRODUCT_STATE.md` and `MVP_PLAN.md` both state the two-gate model explicitly and explain why Phase 0A may run in parallel with R0 (disk-image-only, no catalog contact) rather than leaving the sequencing ambiguous. |
| R0-11 (PRD did not express key/collision/live rules) | CLOSED (substance); minor hygiene issue remains | PRD's US-04/US-06 correctly state the two-key/collision/`uncertain`/transient model; PRD does carry the duplicated Mount Consent Policy block (FSD-REAUDIT-007) but that is a hygiene issue, not a substantive contradiction. |
| R0-12 (test coverage did not execute the contract) | PARTIALLY CLOSED | `verify.sql` now contains real bypass-attempt fixtures (a genuine improvement) and `TEST_PLAN.md` §5/§7 lists them, but the correction's own fixture set never tests arbitrary-collision-pairing in `comparison_results` — the exact gap that let R0-07's regression through the correction's own verification. |
| R0-13 (distribution language implied commercial release) | CLOSED (unchanged) | Local-only/no-notarization language intact; not touched by this round. |
| R0-14 (Forge Handoff evidence/role issues) | PARTIALLY CLOSED | The correction Handoff's own filename uses role code `C` while its body states `ROLE: PRIMARY FORGE` — the same class of role-code/stated-role mismatch the original R0-14 flagged, recurring (FSD-REAUDIT-008). Evidence quality is otherwise much improved (real command output, real SQL, real row-count assertions). |
| FSD-AUDIT-007 (auto-mount contradicts read-only policy) | **OPEN / SUBSTANTIALLY REGRESSED** | `FILESYSTEM_PROVIDER_ARCHITECTURE.md` §3's literal contradictory sentence is untouched; a new, unreconciled policy was appended to the same file instead of replacing it (FSD-REAUDIT-002). |
| FSD-AUDIT-008 (Collection `last_used_at` unexecutable) | CLOSED | Independently reproduced: insert-with-Collection, move (source unchanged, destination advances), move-to-`Unsorted` (no advance), `display_name`/`user_note` edits (no advance), failed reassignment (FK violation, no mutation), Collection deletion (detaches, doesn't delete), multi-column UPDATE (still advances) — all eight sub-behaviors correct (§10). |

Use: **CLOSED** / **PARTIALLY CLOSED** / **OPEN** / **REGRESSED** / **SUPERSEDED** as instructed. Two items are marked with an explicit **OPEN**/**REGRESSED** qualifier because the correction did not merely fail to improve them — in the auto-mount case, it added new, unreconciled contradictory text to the same document, and in the filesystem-count case, it introduced a new numerically wrong claim while leaving the originally-flagged wrong claim in place elsewhere.

## 5. Snapshot Lifecycle Audit

Full fixture: `/private/tmp/fsd-reaudit-0724-08/reaudit1_lifecycle.sql` (self-authored, not the correction agent's file). All assertions below are `rows_present`/`status` values read back from the database after each attempted mutation, not error-text alone.

| Test | Result | Verdict |
|---|---|---|
| Direct INSERT `status='complete'` | Rejected, 0 rows | PASS |
| Direct INSERT `status='complete_with_warnings'` | Rejected, 0 rows | PASS |
| Direct INSERT `status='failed'` | **Accepted, 1 row** | **FAIL — see FSD-REAUDIT-004** |
| Direct INSERT `status='cancelled'` | **Accepted, 1 row** | **FAIL — see FSD-REAUDIT-004** |
| Direct INSERT `status='interrupted'` | **Accepted, 1 row** | **FAIL — see FSD-REAUDIT-004** |
| Zero-root `scanning`→`complete` | Rejected, stays `scanning` | PASS |
| One-root `scanning`→`complete` | Accepted, becomes `complete` | PASS |
| Second root at the same snapshot/path | Rejected by `UNIQUE(snapshot_id, relative_path)` before the root-count trigger is ever exercised at >1 (structurally unreachable in practice — see note below) | PASS (over-protected, not under-protected) |
| `complete`→`scanning`/`failed`/`interrupted`/`cancelled` (four reverts) | All four rejected, `Cannot transition out of a terminal status`, status stays `complete` throughout | PASS |
| INSERT `status='partial'` | Rejected by the `CHECK` enum itself — `'partial'` was never a real status value (it is PRD-level product language for `interrupted`/`complete_with_warnings`, not a DB value) | PASS / clarification, not a defect |
| Cross-snapshot parent | Rejected, `FOREIGN KEY constraint failed` | PASS |
| Same-snapshot valid parent | Accepted | PASS |
| `REPLACE INTO ... status='complete'` on a zero-root row (bypass attempt via delete+insert) | Rejected — `REPLACE` still fires the `BEFORE INSERT` guard; original row survives untouched | PASS |

**Note on the "two-root" test:** the entries table's own `UNIQUE(snapshot_id, relative_path)` constraint already makes it impossible to insert a second row matching the root predicate (`parent_id IS NULL AND relative_path = ''`) for one snapshot, since both roots would collide on `relative_path = ''`. The root-count trigger's `!= 1` check is therefore defense-in-depth for the `>1` case rather than the only thing preventing it — worth recording, not a defect.

**New finding, not in the original audit:** a snapshot can be directly `INSERT`ed with `status` in `('failed', 'cancelled', 'interrupted')`, bypassing the documented "every snapshot is created as `scanning` first" entry point (`ARCHITECTURE.md`'s scanner phases, `AGENT.md`'s required behavior). Unlike the `complete`/`complete_with_warnings` case, this does not corrupt the one-root invariant (those statuses carry no root-completeness expectation), so it is not CRITICAL — but it is a real, reproducible, unenforced part of the lifecycle contract, and it is exactly what the re-audit brief's own required test ("new snapshot must begin in the permitted mutable state") asks to check. See FSD-REAUDIT-004.

## 6. Comparison and Normalization Audit

Full fixture: `/private/tmp/fsd-reaudit-0724-08/reaudit2_comparisons.sql`.

| Test | Result | Verdict |
|---|---|---|
| Matching-`normalization_version` complete sources | Accepted | PASS |
| Mismatched `normalization_version` | Rejected at INSERT, `Mismatched normalization versions block comparison` | PASS |
| `scanning` source | Rejected, `Comparison sources must be complete snapshots` | PASS |
| `interrupted` source | Rejected, same message | PASS |
| `failed` source | Rejected, same message | PASS |
| `cancelled` source | Rejected, same message | PASS |
| `complete_with_warnings` source | Accepted | PASS |
| `complete` transient (`snapshot_kind='transient'`) source | Accepted | PASS |
| `UPDATE comparisons SET left_snapshot_id = ...` on an existing comparison | Rejected, `Comparison source snapshot IDs are immutable`; value unchanged | PASS |
| `UPDATE comparisons SET right_snapshot_id = ...` | Rejected, same trigger; value unchanged | PASS |
| Source snapshot transitioned to `failed` after being used in a comparison | Rejected by the (unrelated) terminal-status-immutability trigger — a `complete` source can never leave `complete`, so it can never retroactively become comparison-ineligible | PASS (emergent property, not a dedicated mechanism, but the outcome is correct) |
| Unrelated comparison fields (`status`, `matched_count`, `completed_at`) | Freely updateable | PASS |

**This section is fully closed.** The correction genuinely fixed FSD-AUDIT-002 (normalization-version UPDATE bypass) and FSD-AUDIT-004 (interrupted-transient-as-comparison-source), and did so by the most direct available mechanism — making comparison source IDs immutable outright rather than re-validating on every possible mutation path. This is a defensible design choice (documented as such) and it closes the bypass completely, not partially.

## 7. Collision Group Audit

Full fixture: `/private/tmp/fsd-reaudit-0724-08/reaudit3_collision.sql`. This is the section where the correction's central claim fails to reproduce.

### 7.1 What is genuinely fixed

The new `comparison_collision_groups`/`comparison_collision_members` tables, in isolation, are correctly built:

| Test | Result | Verdict |
|---|---|---|
| One group per `(comparison_id, result_path)` | Duplicate insert rejected, `UNIQUE` violation | PASS |
| Both left-side collision members retained in one group | Both present | PASS |
| Duplicate member (`group_id, side, entry_id`) | Rejected | PASS |
| Valid right-side member | Accepted | PASS |
| Reverse-side insertion (a left-snapshot entry inserted as `side='right'`) | Rejected, `Collision member entry must belong to the right snapshot of the comparison` | PASS |
| Mirror case (a right-snapshot entry inserted as `side='left'`) | Rejected, mirrored message | PASS |
| Entry from an unrelated (neither-side) snapshot, either side | Both rejected | PASS |
| Deleting the parent comparison | Cascades cleanly through groups → members → `comparison_results`; source `entries` rows (which belong to snapshots, not the comparison) survive untouched | PASS |
| Duplicate empty (`NULL`/`NULL`) `uncertain` row in `comparison_results` | Rejected, `Duplicate empty uncertain rows are not allowed` | PASS |
| `comparison_results` row with a `left_entry_id` belonging to the *right* snapshot | Rejected, ownership trigger fires correctly | PASS |

### 7.2 What is not fixed — FSD-REAUDIT-001

Nothing in the schema connects `comparison_collision_groups`/`comparison_collision_members` to `comparison_results`. The only two triggers guarding `comparison_results` (`trg_comparison_results_entry_left`/`_right`) check that an entry belongs to the *correct snapshot side* — they say nothing about whether that entry is a collision-group member, or which counterpart it collided with. Concretely reproduced:

- `left_entry_id = 3001` (`REPORT.txt`, a genuine left-side collision-group member) paired with `right_entry_id = 3003` (`Unrelated.txt` — not a collision member, not any kind of legitimate counterpart to `3001`) as `result_type = 'matched'` — **inserted successfully.**
- `left_entry_id = 3000` (`Report.txt`) paired with `right_entry_id = 3002` (the genuine right-side collision counterpart) as `matched` — **inserted successfully.**
- `left_entry_id = 3001` (`REPORT.txt`, the *other* left collision member) **also** paired with the *same* `right_entry_id = 3002` as `matched` — **inserted successfully**, alongside the row above. Two different left entries are now each independently recorded as "the" match for one right entry, with no constraint noticing the conflict.

This is the identical shape of the original finding: "Report.txt paired with REPORT.TXT, the reverse pair, and two uncertain rows with both entry IDs NULL... accepted." The NULL/NULL duplicate half of that finding is now fixed (§7.1); the arbitrary-pairing half is not. The correction's Executive Summary claim — "This completely eliminates arbitrary member pairing and duplicate uncertain rows" — is accurate only for the second half.

**Why the brief's own forbidden-state query list doesn't catch this:** none of the required forbidden-state queries check for it, because there is no schema-level relationship to query against — `comparison_results` doesn't record which pairing would have been correct, so there is no `WHERE` clause that can distinguish a legitimate match from an arbitrary one. That absence of a checkable invariant *is* the finding.

**Required correction, restated concretely:** either (a) add a foreign key from `comparison_results` to `comparison_collision_groups` for any row whose `left_entry_id`/`right_entry_id` is a collision-group member, with a trigger forbidding `result_type IN ('matched','changed')` for such rows (collision members may only appear in `comparison_results` as part of the `uncertain` classification, never as an ordinary pair), or (b) stop writing per-pair `comparison_results` rows for collision-group members at all and let the UI read `comparison_collision_groups`/`comparison_collision_members` directly for that path's presentation. Either closes the gap; the current state, with two independent unlinked storage paths for the same fact, does not.

## 8. Schema Baseline Audit

```sql
SELECT * FROM schema_migrations ORDER BY version;
```

Result, on a fresh database applied outside the repository: exactly one row, `version = 3`. No `1` or `2` rows are inserted by the current `schema.sql` (the `INSERT OR IGNORE INTO schema_migrations(version, applied_at) VALUES (3, CURRENT_TIMESTAMP);` statement was reduced to a single-version insert). `MVP_PLAN.md`, `PRODUCT_STATE.md`, and `PROJECT_MANIFEST.md` all consistently say "schema version 3" with no live `v1→v2` migration-test claim remaining (confirmed by grep — the only remaining "schema version 2"/"v1→v2" text anywhere in `docs/` is inside the audit and correction reports themselves, correctly describing history, and one accurate historical reference each in `FILESYSTEM_REPLAN_CLAUDE.md` and `SNAPSHOT_COLLECTIONS.md` to when specific columns were *added* — not a claim that a v1→v2 migration path exists or is tested). **CLOSED**, verified independently, not merely re-asserted.

## 9. Filesystem and Mount Policy Audit

### 9.1 Auto-mount contradiction — FSD-REAUDIT-002, OPEN

`FILESYSTEM_PROVIDER_ARCHITECTURE.md` §3, step 1, unchanged by the correction:

> "Ask macOS first. If the volume is already mounted (**or macOS successfully auto-mounts it once FSD requests it**, for APFS/HFS+/FAT16/FAT32/exFAT/NTFS/UDF), use `NativeMountedProvider`."

The same document now also contains, appended after §10 (lines 141–147):

> "Explicit Mount Consent Policy... 2. FSD must never silently request a new mount or unmount... 4. Only after that user action may FSD request a read-only mount through the approved macOS mechanism."

These two passages are in direct tension inside one file: §3 describes FSD requesting an automatic mount as part of ordinary provider selection, with no mention of a consent gate; the appended policy requires an explicit per-action user gesture before any mount request. Neither passage references the other. This is the same defect FSD-AUDIT-007 originally identified — reproduced verbatim in the operative text — with a second, contradicting policy now also present rather than a fix replacing the first passage. `PRD.md`, `MVP_PLAN.md`, `TEST_PLAN.md`, and `SECURITY_AND_READ_ONLY_POLICY.md` all received the same "Explicit Mount Consent Policy" block appended, so the new policy itself is at least consistently *stated* — it is simply never reconciled with the one document (`FILESYSTEM_PROVIDER_ARCHITECTURE.md`) whose operative logic actually contradicts it.

### 9.2 Filesystem cardinality — FSD-REAUDIT-003, PARTIALLY CLOSED with a new regression

Confirmed by direct grep against live documents (not the audit/correction reports, which are excluded as historical narrative):

- `FILESYSTEM_PROVIDER_ARCHITECTURE.md` line 9: *"only true for 8 of the 9 required filesystems"* — unedited.
- `FILESYSTEM_PROVIDER_ARCHITECTURE.md` line 60: *"filesystemType: one of the 9 required kinds"* — unedited.
- `TEST_PLAN.md` line 107: *"the full per-filesystem test/behavior matrix (all 9 required filesystems...)"* — unedited.

All three directly contradict the correction's claim of "zero remaining instances... concerning 8/9 filesystems." The correct count, consistent with `ADR-014`, `DEPENDENCY_AND_LICENSE_REVIEW.md` §2's seven-row native table, and `FILESYSTEM_SUPPORT_MATRIX.md`'s ten-row table, is **10 variants across 7 filesystem families** (7 native, 3 embedded-raw) — which the correction did successfully establish as the standard framing in `DEPENDENCY_AND_LICENSE_REVIEW.md` §1 and `FILESYSTEM_FEASIBILITY_PLAN.md`. It just did not propagate that framing everywhere it claimed to.

Separately, and worse — a **new, wrong** claim was introduced identically into three documents, none of which contained it before this correction round: *"native mounting correctly exposes metadata for the other three filesystems"* (`FILESYSTEM_FEASIBILITY_PLAN.md` line 27, `PRODUCT_STATE.md` line 40, `MVP_PLAN.md` line 16). The correct number is **seven** (APFS, HFS+, FAT16, FAT32, exFAT, NTFS, UDF — the natively-mounted set, as a plain count of `DEPENDENCY_AND_LICENSE_REVIEW.md` §2's own table confirms), not three. This is not a pre-existing issue left unfixed; it is a new numeric error the correction's own edit pass introduced, propagated identically across three files in a way that indicates a single mechanical find-replace rather than three independent authoring mistakes.

### 9.3 FSKit characterization — genuinely correct, with an incomplete edit

Independently researched (not taken on either side's assertion): FSKit is documented by Apple as being "based on modern appex technology, that is, ExtensionFoundation / ExtensionKit" — i.e., FSKit modules are packaged using App Extension (`.appex`) infrastructure, not the classic System Extension (`.systemextension`)/`sysex` mechanism used by DriverKit or NetworkExtension providers. The correction's substantive claim — that FSKit is more accurately described as app-extension-based than system-extension-based — is **factually supportable**, and crediting it: the original "system extension" characterization in the FSD documentation was imprecise, and the correction's fix direction is correct.

However, the edit is incomplete and self-contradicting within one document: `DEPENDENCY_AND_LICENSE_REVIEW.md` §3.5's own table still reads, in the "Packaging" row, bolded: *"An FSKit reader ships as a **System Extension** the user approves once in System Settings"* — followed immediately by the sentence *"this is precisely the category ('app extensions') the task's explicit constraint rules out"* — contradicting the table cell three words later. This is the same paragraph. This reads as a partial find-replace that missed the bolded instance.

### 9.4 Other consent-policy checks

- No user-installed system/app extension, macFUSE, or ntfs-3g requirement is stated anywhere as a live requirement (grep-confirmed).
- Already-mounted volumes may be read — stated consistently.
- No read-write fallback is described anywhere — stated consistently, and the schema structurally enforces read-only access modes (§6 of `FILESYSTEM_PROVIDER_ARCHITECTURE.md`, unchanged and correct).
- `mountfs` exclusion: the original audit flagged this as unverified/not materially assessed; this re-audit did not find `mountfs` mentioned anywhere in the live filesystem documents at all — it appears the term was never actually used as an implementation dependency to begin with (only in this and prior tasks' own out-of-scope/prohibition lists), so there is nothing live to "resolve." No finding raised.

### 9.5 Grammar artifacts from the "system extension" → "app extension" replacement

`PROJECT_MANIFEST.md` invariant 9 and `DEPENDENCY_AND_LICENSE_REVIEW.md` §3.4 both now read *"...a app extension"* (should be *"an app extension"*) — a direct symptom of a blind string replacement that did not check the preceding article. Folded into FSD-REAUDIT-006 below.

## 10. Collections Audit

Full fixture: `/private/tmp/fsd-reaudit-0724-08/reaudit7_collections.sql`. Every one of the eight required sub-behaviors reproduces correctly:

1. Insert with `collection_id` set → destination `last_used_at` advances.
2. Move → only the destination Collection advances; the source Collection's `last_used_at` is untouched.
3. Move to `Unsorted` (`collection_id = NULL`) → no Collection advances.
4. Edit `display_name` → no advance.
5. Edit `user_note` → no advance.
6. Attempted reassignment to a nonexistent Collection id → rejected by the foreign key; `collection_id` on the snapshot remains at its prior value, unchanged.
7. `session_number`/`started_at` remain stable across every reassignment above.
8. Deleting the Collection detaches the snapshot (`collection_id` → `NULL`) without deleting the snapshot row.

A ninth check not explicitly required but worth recording: a single `UPDATE` statement that changes `collection_id` alongside unrelated columns (`updated_at`, `user_note`) in the same statement still correctly fires the `AFTER UPDATE OF collection_id` trigger and advances `last_used_at` — no trigger-recursion or column-list edge case found. **This section is fully closed** — FSD-AUDIT-008 is genuinely resolved, not merely asserted.

## 11. SQLite Verification

All work below ran against `/private/tmp/fsd-reaudit-0724-08/reaudit.sqlite3`, created fresh outside the repository and deleted after use; fixture `.sql` files are retained there as reproducible evidence.

```text
$ sqlite3 <fresh-db> < docs/database/schema.sql
wal
$ sqlite3 <fresh-db> "SELECT * FROM schema_migrations ORDER BY version;"
version  applied_at
-------  -------------------
3        2026-07-24 16:14:19
$ sqlite3 <fresh-db> "PRAGMA integrity_check;"
ok
$ sqlite3 <fresh-db> "PRAGMA foreign_key_check;"
(no rows)
```

Forbidden-state queries (brief §"SQLITE EXECUTION"), run against the database after all positive/negative fixtures above had been exercised — all returned zero, as required:

```text
terminal_complete_without_one_root        0
comparisons_non_complete_sources          0
comparisons_incompatible_normalization    0
collision_members_wrong_left_side         0
collision_members_wrong_right_side        0
duplicate_collision_groups                0
duplicate_collision_members               0
blank_collection_names                    0
blank_snapshot_display_names              0
comparison_results_wrong_left_owner       0
```

**This zero-row result does not contradict §7's finding.** The brief's forbidden-state list does not include a query for "a `comparison_results` row pairs a collision-group member with a non-corresponding entry," because no such query is expressible against the current schema — there is no stored fact anywhere recording which pairing *would have been* correct for a collision-group member, so there is no `WHERE` clause that can flag a wrong one. §7.2's finding was demonstrated by direct insertion (the statement succeeds when it should be rejected), not by a residual-state query, and the offending rows were subsequently removed by this re-audit's own cascade-delete test (§7.1) before the forbidden-state sweep ran — the absence of rows now reflects test cleanup, not the absence of the defect. The reproduction steps in `reaudit3_collision.sql` (lines producing `R2_ARBITRARY_PAIRING_OF_COLLISION_MEMBER`, `R3a_first_pairing`, `R3b_second_conflicting_pairing_of_same_right_entry`, all returning `rows_present = 1` at insertion time) are the evidence.

`docs/database/verify.sql`'s own new fixtures (its "Plan Gate Corrections Fixtures" section, lines 237–365) were separately read and found consistent with what they claim, as far as they go — they do correctly test cross-snapshot-ownership rejection for `comparison_results`, but never attempt an arbitrary same-side-correct pairing, which is precisely the gap this re-audit found. The correction's own test suite could not have caught FSD-REAUDIT-001 because it never wrote the fixture that would exercise it.

## 12. Documentation Consistency

Full detail in §9 above for the mount-policy and filesystem-count issues. Additional findings from the "mass search-and-replace" sweep the brief asked to check for:

- **`DECISIONS.md` ADR-013** contains a literal broken-sentence artifact from an incomplete string removal: *"There are no date subdirectories, no SESSION directories, and no `` checksum files."* — an empty double-backtick where `.sha256` was stripped without replacing the surrounding text.
- **The same ADR's amendment paragraph** now reads: *"the legacy nested `handoffs/` directory has been inventoried... and the `handoffs/` directory deleted."* This is factually wrong as written — the flat `handoffs/` directory is the *current, active, in-use* Handoff location (it holds the very files this re-audit read), and it has manifestly not been deleted. The sentence should refer to the legacy `AI_HANDOFFS/` directory, which *was* deleted. This reads as a blind find-and-replace of the literal string "AI_HANDOFFS" → "handoffs" that matched an instance describing the *old, deleted* directory and silently rewrote it into a false claim about the *current* one.
- **Grammar**: *"a app extension"* (missing article correction) in `PROJECT_MANIFEST.md` invariant 9 and `DEPENDENCY_AND_LICENSE_REVIEW.md` §3.4.
- **Internal self-contradiction**: `DEPENDENCY_AND_LICENSE_REVIEW.md` §3.5, "System Extension" (bolded, in a table cell) vs. "app extensions" (prose, next sentence) — see §9.3.
- **Duplication**: the "Explicit Mount Consent Policy" block (six numbered lines) appears verbatim, as a disconnected trailing section with no numbering integration into the surrounding document, in `PRD.md`, `MVP_PLAN.md`, `TEST_PLAN.md`, `SECURITY_AND_READ_ONLY_POLICY.md`, and `FILESYSTEM_PROVIDER_ARCHITECTURE.md` — five copies of the same policy text instead of one canonical statement (the natural home is `SECURITY_AND_READ_ONLY_POLICY.md`, which already owns read-only-boundary policy) cross-referenced from the others. This is exactly the kind of duplication the project's own documents elsewhere insist on avoiding ("choose one canonical source for each major rule and make other documents reference it" — a principle stated and followed everywhere else in this documentation set prior to this correction round).
- **Trailing whitespace**: `docs/FSD_PLAN_GATE_CORRECTION_GEMINI31.md` has two lines with trailing whitespace (lines 4 and 47) — the one file in the entire `docs/` tree that fails the whitespace check.
- Classification of intentional historical references (not defects): "schema version 2"/"schema v2" mentions inside `FILESYSTEM_REPLAN_CLAUDE.md` and `SNAPSHOT_COLLECTIONS.md` correctly describe *when* a field was added, not a live requirement; "AI_HANDOFFS" mentions in `AGENT.md`, `DECISIONS.md` (aside from the broken sentence above), and `PROJECT_SUPPORT/HANDOFFS.md` are deliberate provenance records of a completed migration; "camera-vendor" mentions in `PRD.md`, `DECISIONS.md`, `MVP_PLAN.md`, `README.md`, `PROJECT_MANIFEST.md`, and `FILESYSTEM_REPLAN_CLAUDE.md` are all exclusion language, never in-scope claims (grep-confirmed, no hits describing camera-vendor work as planned or required).

## 13. MCP CodeGraph Status

**NOT RUN — APPROPRIATE AT CURRENT STAGE.** Independently confirmed: no `.codegraph` directory exists; no production source scaffold of any kind exists (`find` for `.swift`/`.m`/`.mm`/`.c`/`.cc`/`.cpp`/`.xcodeproj`/`Package.swift` returned nothing). CodeGraph was not invoked by this re-audit, consistent with the mandatory first-implementation-session gate (check availability → index after scaffold exists → run a real query → record it → report `BLOCKED` if unavailable), none of which applies yet because there is no implementation session underway.

## 14. Remaining Risks

- FSD-REAUDIT-001 (arbitrary collision pairing) and FSD-REAUDIT-002 (auto-mount contradiction) are both direct reproductions of originally-HIGH, explicitly Phase-0A-and-Phase-0-blocking findings. Neither is a new category of risk; both are the *same* risk the first correction round was specifically tasked with closing and did not.
- FSD-REAUDIT-003's "other three filesystems" error, if left uncorrected, could mislead a Phase 1 implementer into scoping `NativeMountedProvider`'s test matrix to three filesystems instead of seven — a planning document actively pointing at the wrong number is a real risk to the next phase's exit criteria, not merely cosmetic.
- FSD-REAUDIT-005 (hardcoded `unicode-15.0` normalization-version component) does not block Phase 0A specifically (a disk-image-only feasibility spike has no cross-machine normalization-compatibility stakes) but is foundational to the comparison-eligibility contract this very correction round hardened (§6); it should be resolved before Phase 0/1, not carried into implementation as an unexamined assumption.
- The correction's own verification narrative ("A comprehensive regex sweep... confirmed zero remaining instances... All canonical and planning documents align") is demonstrably overstated in at least two independently-checkable, specific ways (§9.2, §12). This is itself worth flagging as a process risk for future correction rounds: a claimed "comprehensive sweep" should be independently spot-checked, not accepted, exactly as this task's own instructions required and this re-audit did.

## 15. Phase 0A Executable Task Readiness

**Not ready to authorize**, per the explicit rule that any open implementation-blocking finding blocks Phase 0A. If and when a future corrective round actually closes FSD-REAUDIT-001 and FSD-REAUDIT-002 (and, ideally, FSD-REAUDIT-003's regression and FSD-REAUDIT-004's lifecycle gap), the single executable Phase 0A task remains exactly what the filesystem replan and feasibility plan already define:

> Build and run the disk-image-only ext2/ext3/ext4 libfsext feasibility spike.

Confirmed already satisfied by the existing specification (`FILESYSTEM_FEASIBILITY_PLAN.md` §3), independent of this re-audit's findings, so no further definition work is needed once the gates above clear:

- No physical-device access (disk images only — `FILESYSTEM_FEASIBILITY_PLAN.md` §1's governing rule).
- No raw write access (the provider contract has no write method at all — `FILESYSTEM_PROVIDER_ARCHITECTURE.md` §4/§6, unchanged and independently re-confirmed by this re-audit not to have regressed).
- No Xcode UI requirement (the spike is explicitly a disposable command-line tool that may print to stdout — no SQLite persistence required either).
- No external installation required for the final app (libfsext is bundled/vendored, not user-installed — `DEPENDENCY_AND_LICENSE_REVIEW.md` §3.1).
- A clear success/failure decision exists for libfsext vs. TSK fallback (`DEPENDENCY_AND_LICENSE_REVIEW.md` §3.2, `ADR-015`): if libfsext's ext2/3/4 support fails against the required non-UTF-8-filename and fscrypt-encrypted-subtree fixtures, TSK is the named, pre-evaluated fallback.

This task is not being authorized to start in this re-audit — it is confirmed *ready to be defined* once the gates in §15's opening sentence actually close.

## 16. Chatbox Transition Decision

STAY IN AUDIT/PLAN

## 17. Final Decision

REJECT — CORRECTIONS REQUIRED

---

## Findings

### [CRITICAL] FSD-REAUDIT-001 — Arbitrary collision-member pairing is still fully possible in `comparison_results`

**Evidence**

- `docs/database/schema.sql`: `comparison_collision_groups`/`comparison_collision_members` (lines 351–388) are correctly constrained but have no foreign-key or trigger relationship to `comparison_results` (lines 390–451).
- `/private/tmp/fsd-reaudit-0724-08/reaudit3_collision.sql`, tests `R2`, `R3a`, `R3b`: each `INSERT` succeeded (`rows_present = 1`) despite pairing a known left-side collision-group member (`entry_id 3001`, a `REPORT.txt`/`Report.txt` case-fold collision with `entry_id 3000`) against, respectively, an unrelated right-side entry (`3003`) and the same right-side entry (`3002`) that a *different* left-side collision member (`3000`) was already independently recorded as matching.

**Finding**

The new collision-group tables record group membership correctly but do not gate what `comparison_results` may record. Any two entries that individually belong to their correct comparison side can be recorded as an arbitrary `matched`/`changed` pair in `comparison_results`, including entries that are simultaneously known collision-group members whose true correspondence is genuinely ambiguous.

**Impact**

The comparison store can present a false match (two case-variant files silently declared "the same" when the real correspondence is unknown) or an inconsistent one (two different left entries each independently claimed as the match for one right entry) with no constraint noticing either case. This is the exact defect R0-07/FSD-AUDIT-003 was raised to close.

**Required correction**

Either constrain `comparison_results` so a row referencing a known collision-group member can only carry `result_type = 'uncertain'` (never `'matched'`/`'changed'`), enforced by a trigger that checks `comparison_collision_members` before accepting the insert; or stop persisting per-pair `comparison_results` rows for collision-group members entirely and have the UI read the group/member tables directly for that path. Add a fixture that specifically inserts an arbitrary pairing of two collision-group members and asserts rejection — the current `verify.sql` does not have one.

**Gate**

- Blocks Phase 0A: YES
- Blocks Phase 0: YES

### [CRITICAL] FSD-REAUDIT-002 — Auto-mount contradiction persists verbatim in the operative provider-selection text

**Evidence**

- `docs/FILESYSTEM_PROVIDER_ARCHITECTURE.md` line 44: *"If the volume is already mounted (or macOS successfully auto-mounts it once FSD requests it, for APFS/HFS+/FAT16/FAT32/exFAT/NTFS/UDF), use `NativeMountedProvider`."*
- The same document, lines 141–147: the newly appended "Explicit Mount Consent Policy," including *"2. FSD must never silently request a new mount or unmount"* and *"4. Only after that user action may FSD request a read-only mount through the approved macOS mechanism."*

**Finding**

One document contains both an operative rule describing FSD requesting an automatic mount with no consent gate, and a policy statement forbidding exactly that. Neither passage references or reconciles with the other.

**Impact**

An implementer following §3's literal selection rule would request an automatic mount without the required explicit user gesture, violating the newly-stated (and, per `SECURITY_AND_READ_ONLY_POLICY.md`, longstanding) explicit-user-action requirement. The two policies were never merged into one coherent rule.

**Required correction**

Rewrite `FILESYSTEM_PROVIDER_ARCHITECTURE.md` §3 step 1 to state the actual flow: read an already-mounted volume freely; for an unmounted-but-native-readable filesystem, surface the "Mount Read-Only and Capture" user action defined in the Explicit Mount Consent Policy and only invoke `NativeMountedProvider` after that action is taken. Then delete four of the five duplicated policy blocks (see FSD-REAUDIT-007) and reference the one canonical copy from here.

**Gate**

- Blocks Phase 0A: YES
- Blocks Phase 0: YES

### [HIGH] FSD-REAUDIT-003 — Filesystem-cardinality claims remain wrong in two ways: unfixed originals plus a new regression

**Evidence**

- Unfixed: `docs/FILESYSTEM_PROVIDER_ARCHITECTURE.md` lines 9 and 60 ("8 of the 9 required filesystems", "one of the 9 required kinds"); `docs/TEST_PLAN.md` line 107 ("all 9 required filesystems").
- New regression: `docs/FILESYSTEM_FEASIBILITY_PLAN.md` line 27, `docs/PRODUCT_STATE.md` line 40, `docs/MVP_PLAN.md` line 16 — all three now say *"the other three filesystems"* where the correct count (matching `DEPENDENCY_AND_LICENSE_REVIEW.md` §2's own seven-row native table) is seven.
- Contradicting claim: `docs/FSD_PLAN_GATE_CORRECTION_GEMINI31.md` line 44 asserts *"zero remaining instances... concerning 8/9 filesystems"* and *"Standardized count nomenclature to '10 variants across 7 filesystem families'"* (line 35) — the second statement is the correct target framing, but it was not propagated to the three documents above, and a new numeric error was introduced in its place.

**Finding**

The correction round both left the originally-flagged miscounts in place in two live documents and introduced a new, different miscount in three others, propagated identically — consistent with one mechanical find-replace error rather than three independent mistakes.

**Impact**

A Phase 1 implementer following `MVP_PLAN.md`'s or `FILESYSTEM_FEASIBILITY_PLAN.md`'s literal text would scope native-provider testing to three filesystems instead of seven, silently under-covering APFS/HFS+/FAT16/FAT32/exFAT/NTFS/UDF's Phase 0A/1 exit criteria.

**Required correction**

Standardize every live document on "10 variants across 7 filesystem families (7 native, 3 embedded-raw)" — the framing `DEPENDENCY_AND_LICENSE_REVIEW.md` already correctly establishes — and replace every remaining "9"/"8 of 9"/"other three" instance with the correct number, verified by grep after the edit, not merely asserted.

**Gate**

- Blocks Phase 0A: YES (the "other three" error appears directly inside Phase 0A's own objective statement in `MVP_PLAN.md` and `FILESYSTEM_FEASIBILITY_PLAN.md`)
- Blocks Phase 0: YES

### [MEDIUM] FSD-REAUDIT-004 — A snapshot can be directly created in `failed`/`cancelled`/`interrupted` status, bypassing the documented `scanning`-first entry point

**Evidence**

- `/private/tmp/fsd-reaudit-0724-08/reaudit1_lifecycle.sql`, tests `T3a`/`T3b`/`T3c`: direct `INSERT ... status='failed'`, `'cancelled'`, `'interrupted'` each succeeded (`rows_present = 1`).
- `docs/database/schema.sql`: `trg_snapshots_insert_complete_check` (lines 229–234) only guards `NEW.status IN ('complete', 'complete_with_warnings')` on INSERT; no trigger restricts INSERT to `status = 'scanning'` alone.
- `docs/ARCHITECTURE.md` scanner phases and `docs/AGENT.md`'s required behavior both describe every snapshot as beginning life as a `scanning` row.

**Finding**

The database does not enforce that every snapshot's row is born as `scanning`; three of the five non-`scanning` statuses can be inserted directly.

**Impact**

Lower severity than the `complete` case (these statuses carry no root-completeness expectation, so no downstream lazy-tree/comparison assumption is violated), but it is a real, reproducible gap against the documented lifecycle contract, and it is precisely what this re-audit's own required test ("new snapshot must begin in the permitted mutable state") asked to check.

**Required correction**

Extend `trg_snapshots_insert_complete_check`'s `WHEN` clause to reject any `NEW.status != 'scanning'` on INSERT, or explicitly document (if intentional) that `failed`/`cancelled`/`interrupted` are legitimate direct-insert states for a capture that never produced a usable `scanning` row (e.g. a capture that fails before the first transaction commits) and add a fixture proving that is the intended, not accidental, behavior.

**Gate**

- Blocks Phase 0A: NO
- Blocks Phase 0: YES

### [MEDIUM] FSD-REAUDIT-005 — The normalization-version literal hardcodes an unverifiable Unicode/ICU data-version claim

**Evidence**

- `docs/database/schema.sql` line 109: `normalization_version TEXT NOT NULL DEFAULT 'fsd-algo-v1_app-v1.0_unicode-15.0'`.
- `docs/FSD_PLAN_GATE_CORRECTION_GEMINI31.md` line 29: "The normalization version is standardized to `fsd-algo-v1_app-v1.0_unicode-15.0`."
- No document defines how the app would verify, at runtime, that the OS/Foundation/ICU Unicode data it is actually running against corresponds to Unicode Consortium version 15.0, across every macOS 13.0 through 13.x/14.x/15.x/26.x point release FSD's stated macOS 13+ range covers.

**Finding**

Apple does not publish a documented guarantee that Foundation's ICU/Unicode data version is fixed across macOS point releases within or across major versions. `String.precomposedStringWithCanonicalMapping` and `.folding(options:locale:)` use whatever Unicode data ships with the OS at runtime — the app has no API to query or pin this independently, and nothing in the schema or scanner design captures the *actual* runtime OS/ICU build alongside the literal `unicode-15.0` string. The literal is therefore an assertion about platform behavior the app cannot verify and Apple has not committed to.

**Impact**

Two machines on different macOS 13.x/14.x point releases could carry genuinely different underlying Unicode normalization/case-folding behavior while both stamping snapshots with the identical `normalization_version` string — silently defeating the exact cross-machine determinism guarantee `ADR-011`'s mismatch-blocks-comparison policy exists to provide, in precisely the case it was designed to catch.

**Required correction**

Either capture the actual runtime OS build/ICU version alongside the algorithm-version component (so two machines on different underlying Unicode data produce different, correctly-mismatching `normalization_version` values), or explicitly document, with a stated confidence level, why a fixed literal is considered acceptable for the macOS 13+ range FSD targets (e.g., citing a specific Apple commitment if one is later found) rather than asserting it as settled fact.

**Gate**

- Blocks Phase 0A: NO (the disk-image feasibility spike has no cross-machine comparison stakes)
- Blocks Phase 0: YES

### [LOW] FSD-REAUDIT-006 — Mass find-replace introduced broken and self-contradictory sentences

**Evidence**

- `docs/DECISIONS.md` ADR-013: `"no `` checksum files"` (empty-backtick artifact) and `"the legacy nested \`AI_HANDOFFS/\` directory has been inventoried... and the \`handoffs/\` directory deleted"` — the second clause is factually false as written (the flat `handoffs/` directory is current and in active use; the deleted directory was `AI_HANDOFFS/`).
- `docs/PROJECT_MANIFEST.md` invariant 9, `docs/DEPENDENCY_AND_LICENSE_REVIEW.md` §3.4: `"a app extension"` (missing article correction after the "system extension" → "app extension" replacement).
- `docs/DEPENDENCY_AND_LICENSE_REVIEW.md` §3.5: table cell says `"System Extension"` (bolded), the immediately following sentence says `"app extensions"` — internally contradictory within one paragraph.

**Finding**

At least four distinct instances of incomplete or overly broad find-and-replace editing, one of which (the ADR-013 "handoffs/ deleted" claim) asserts something demonstrably untrue about the current repository state.

**Impact**

Documentation-quality/trust impact rather than a functional blocker: a reader following ADR-013 literally would believe the active Handoff directory has been deleted; the grammar and self-contradiction issues undermine confidence in the "comprehensive regex sweep... confirmed... align" claim elsewhere in the same correction round.

**Required correction**

Fix each instance individually (do not re-run a blind global replace); re-verify with the same grep patterns used in this re-audit's §12 after editing.

**Gate**

- Blocks Phase 0A: NO
- Blocks Phase 0: NO

### [LOW] FSD-REAUDIT-007 — "Explicit Mount Consent Policy" duplicated verbatim across five documents

**Evidence**

- Identical six-line block present in `docs/PRD.md`, `docs/MVP_PLAN.md`, `docs/TEST_PLAN.md`, `docs/SECURITY_AND_READ_ONLY_POLICY.md`, and `docs/FILESYSTEM_PROVIDER_ARCHITECTURE.md`, each as a disconnected trailing section with no heading-number integration into the surrounding document structure.

**Finding**

This violates the single-canonical-source documentation discipline this project's other documents establish and follow elsewhere (e.g. `SNAPSHOT_COLLECTIONS.md`, `FILESYSTEM_PROVIDER_ARCHITECTURE.md`'s own "Status" preambles explicitly saying "canonical for X... does not restate Y").

**Impact**

Five copies of one policy will drift independently the next time any one of them is edited — exactly the failure mode single-sourcing exists to prevent, and exactly the failure mode that let FSD-REAUDIT-002 happen (the policy was added in five places, but the one place that actually needed its *logic* changed — `FILESYSTEM_PROVIDER_ARCHITECTURE.md` §3 — only received the disconnected addendum, not the fix).

**Required correction**

Keep one copy (recommend `SECURITY_AND_READ_ONLY_POLICY.md`, which already owns read-only-boundary policy), integrate it into that document's existing numbered section structure, and replace the other four with a one-line cross-reference.

**Gate**

- Blocks Phase 0A: NO
- Blocks Phase 0: NO

### [LOW] FSD-REAUDIT-008 — Correction Handoff role-code/stated-role mismatch recurs

**Evidence**

- `handoffs/FSD_PLAN_GATE_CORRECTION_C_20260724-230500.md`: filename role code `C`; body states `ROLE: PRIMARY FORGE`.
- `docs/AGENT.md` role codes: `F` = Forge or planning, `C` = Coding.

**Finding**

The same class of filename/body role mismatch the original R0-14 finding raised against an earlier Handoff recurs here.

**Impact**

Low — the Handoff's evidentiary content is otherwise substantially improved over the R0-era Handoff R0-14 originally criticized (real commands, real row-count assertions). This is a naming-convention slip, not an evidence-quality problem.

**Required correction**

Use role code `F` for a Forge/corrective-specification task per `AGENT.md`'s own taxonomy; reserve `C` for actual application-code sessions once implementation begins.

**Gate**

- Blocks Phase 0A: NO
- Blocks Phase 0: NO

### [LOW] FSD-REAUDIT-009 — Trailing whitespace in the correction report

**Evidence**

- `docs/FSD_PLAN_GATE_CORRECTION_GEMINI31.md` lines 4 and 47 end with trailing whitespace — the only file in `docs/` that fails this check.

**Finding / Impact**

Minor hygiene defect, self-contained to one document.

**Required correction**

Strip trailing whitespace; re-run `grep -rlnE "[ \t]+$" docs --include="*.md"` to confirm zero hits repository-wide.

**Gate**

- Blocks Phase 0A: NO
- Blocks Phase 0: NO
