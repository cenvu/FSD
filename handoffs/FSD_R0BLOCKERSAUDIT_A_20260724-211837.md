<!-- Migrated verbatim from AI_HANDOFFS/2026-07-24/SESSION_2f0cf146-bfd5-4531-b0a1-dcc1b0986930/H_R0BLOCKERS_A_0724211837.md during the AI_HANDOFFS -> handoffs/ cleanup performed under task FSD-FSCORE-REPLAN-0724-04. No content was altered. The .sha256 sidecar that accompanied the original file was intentionally not migrated, per the flat Markdown-only Handoff policy (ADR-013, AGENT.md). This file's DECISION: REJECT is the reason a further R0 corrective round is required; do not delete or summarize it away. -->

# Audit Handoff: R0 Schema and Specification Closure

AGENT: Codex
ROLE: PRIMARY AUDIT
MODE: audit
TASK ID: FSD-R0-BLOCKERS-AUDIT-0724-02
SESSION ID: 2f0cf146-bfd5-4531-b0a1-dcc1b0986930
PHASE: Phase 0 — Planning and architecture definition; R0 blockers remain open
OBJECTIVE: Independently audit the actual R0 schema/documentation patch, re-run focused SQLite verification, and decide whether Phase 0 may proceed to Xcode/catalog foundation work.

## REPOSITORY STATE BEFORE

- VERIFIED: The resolved repository root is `/Users/cenvu/Desktop/DEV/FSD`.
- VERIFIED: `.codegraph/` is absent, so CodeGraph was not used.
- VERIFIED: `.git/` is absent. Git history and Git-based before/after comparison are unavailable.
- VERIFIED: No `.swift`, `Package.swift`, `.xcodeproj`, or `project.pbxproj` path was found.
- VERIFIED: `docs/PRODUCT_STATE.md` identifies the current phase as Phase 0, planning and architecture definition.
- VERIFIED: The applied schema records schema version `1`.
- VERIFIED: Filesystem modification times group the five Forge-reported canonical edits between 21:06:01 and 21:06:44 +0700: `docs/database/schema.sql`, `docs/ARCHITECTURE.md`, `docs/PRD.md`, `docs/TEST_PLAN.md`, and `docs/PRODUCT_STATE.md`.
- VERIFIED: `docs/MVP_PLAN.md`, `docs/DECISIONS.md`, and `docs/PROJECT_MANIFEST.md` retain earlier 13:37:58 +0700 modification times.
- BLOCKED: Exact pre-patch diffs cannot be reconstructed because there is no Git repository and no `.bak`, `.orig`, `.patch`, `.diff`, or archive containing a prior canonical copy.

## FILES READ

- `docs/PRODUCT_STATE.md`
- `docs/MVP_PLAN.md`
- `docs/DECISIONS.md`
- `docs/ARCHITECTURE.md`
- `docs/PRD.md`
- `docs/TEST_PLAN.md`
- `docs/database/schema.sql`
- `docs/PROJECT_MANIFEST.md`
- `docs/PROJECT_SUPPORT/AI_HANDOFFS.md`
- `docs/PROJECT_SUPPORT/SCRIPTS.md`
- `docs/AGENT.md`
- `docs/README.md`
- `docs/UX_UI_SPEC.md`
- `docs/KNOWN_ISSUES.md`
- `docs/SECURITY_AND_READ_ONLY_POLICY.md`
- `AI_HANDOFFS/2026-07-24/SESSION_bc4dfe17-4bd0-414b-906f-891524a4904f/H_R0BLOCKERS_C_0724210734.md`
- `AI_HANDOFFS/2026-07-24/SESSION_bc4dfe17-4bd0-414b-906f-891524a4904f/H_R0BLOCKERS_C_0724210734.md.sha256`

## FILES CHANGED

- `AI_HANDOFFS/2026-07-24/SESSION_2f0cf146-bfd5-4531-b0a1-dcc1b0986930/H_R0BLOCKERS_A_0724211837.md`
- `AI_HANDOFFS/2026-07-24/SESSION_2f0cf146-bfd5-4531-b0a1-dcc1b0986930/H_R0BLOCKERS_A_0724211837.md.sha256`

No schema, canonical documentation, source, project, or Git file was edited.

## WORK COMPLETED

- VERIFIED: Established repository, phase, implementation, schema-version, and Handoff truth.
- VERIFIED: Audited entry types, collations, constraints, indexes, root behavior, normalization text, collision semantics, transient lifecycle, canonical alignment, and Handoff compliance.
- VERIFIED: Applied `docs/database/schema.sql` to a fresh temporary SQLite database.
- VERIFIED: Re-ran required user/transient kind, invalid kind, case collision, exact duplicate, NFC/NFD collision, collision query, root, integrity, foreign-key, schema/index, normalization-version, and active transient-reference fixtures.
- VERIFIED: Ran the required Git commands; both are BLOCKED because the directory is not a Git repository.
- VERIFIED: Ran non-Git trailing-whitespace and merge-marker checks on the audited canonical files; both returned no matches.

## IMPLEMENTATION OR REVIEW DETAILS

### Actual uniqueness and root behavior

- VERIFIED: `entries.relative_path` is `TEXT NOT NULL` with no explicit collation.
- VERIFIED: `UNIQUE(snapshot_id, relative_path)` creates `sqlite_autoindex_entries_1` using SQLite `BINARY` collation for both indexed columns.
- VERIFIED: The constraint permits `Report.txt` and `REPORT.TXT` in one snapshot.
- VERIFIED: The constraint permits canonically equivalent but textually distinct NFC/NFD relative paths in one snapshot.
- VERIFIED: The constraint rejects a second identical stored `relative_path` in the same snapshot.
- VERIFIED: Uniqueness does not depend on `parent_id`; `parent_id IS NULL` does not weaken it.
- VERIFIED: A second root path `relative_path = ''` in the same snapshot is rejected.
- VERIFIED: The schema nevertheless accepts a non-root path with `parent_id IS NULL`; it does not enforce that the only parentless entry is the documented root.
- VERIFIED: `parent_id REFERENCES entries(id)` does not enforce that parent and child belong to the same snapshot.
- REJECTED CLAIM: A Swift `String` or SQLite `TEXT` value is not an “exact byte sequence.” The schema contains no separate raw-path `BLOB`. It preserves the stored Unicode text value under BINARY comparison, not arbitrary original filesystem filename bytes.

### Exact normalization algorithm found

The complete normative text found in `docs/ARCHITECTURE.md` Section 5 is:

- root path is `""`;
- separator is `/`;
- `relative_path` is described as the “exact byte/string representation provided by the filesystem”;
- `case_preserving_path` is a canonically normalized string, “e.g. NFC,” preserving case;
- `case_folded_path` is canonically normalized and case-folded, “e.g. NFC lowercase”;
- the snapshot stores `normalization_version`, defaulting to `"1.0"` in schema;
- both case-sensitive sources select `case_preserving_path`; if either is case-insensitive, select `case_folded_path`;
- selected-key multiplicity is `uncertain` and must not be paired arbitrarily;
- excessive or unrepresentable paths are logged and excluded from standard comparison;
- different normalization versions “should warn” or “automatically upgrade” if safely possible.

Assessment:

- VERIFIED: Root representation, separator, two key columns, version storage, two-source selection intent, and collision classification are present.
- HIGH: “e.g. NFC” does not select a normalization form or concrete API.
- HIGH: “e.g. NFC lowercase” does not define operation order, Unicode data version, full versus simple fold, locale behavior, or a concrete API. Lowercasing is not full Unicode case folding.
- HIGH: The schema stores filesystem type but no captured case-sensitivity property. Filesystem type alone cannot deterministically select a key for variants such as case-sensitive and case-insensitive APFS.
- HIGH: Cross-version behavior is nondeterministic: “warn or upgrade” defines two incompatible outcomes and no safe upgrade procedure.
- MEDIUM: Invalid, unrepresentable, excessive-length, and invalid-component handling does not define limits, scanner API errors, snapshot status, ancestor uncertainty, or whether exclusion may coexist with `complete`.

### Collision semantics and proof

- VERIFIED: Both comparison-key indexes are non-unique and permit collision groups.
- VERIFIED: A selected-key group query detects collisions and uses the covering index.
- VERIFIED: Architecture says collisions are `uncertain` and cannot be arbitrarily paired.
- HIGH: The PRD result list omits `uncertain`; the comparison-result representation for a multi-member collision group is not defined; no executable comparison or result-persistence contract proves that all members remain inspectable.
- HIGH: `TEST_PLAN.md` lists case-collision and NFC/NFD fixtures but does not define expected collision grouping, no-arbitrary-pairing assertions, indexed-query proof, or `uncertain` result checks.

Collision-query output:

```text
selected_key      comparison_key  member_count  members
----------------  --------------  ------------  -----------------------
case_folded_path  café.txt        2             Café.txt | Café.txt
case_folded_path  report.txt      2             Report.txt | REPORT.TXT

selected_key          comparison_key  member_count  members
--------------------  --------------  ------------  --------------------
case_preserving_path  Café.txt        2             Café.txt | Café.txt

QUERY PLAN
`--SEARCH entries USING COVERING INDEX idx_entries_snapshot_case_folded_path (snapshot_id=?)
```

### Transient execution model and lifecycle

- VERIFIED: Architecture defines one engine input path: every comparison is snapshot ID versus snapshot ID.
- VERIFIED: It covers snapshot versus snapshot; a live folder or live volume is captured by the standard scanner as a transient snapshot, so one or both live sides use the same path.
- VERIFIED: It states identical schema/atomicity, incomplete-source exclusion, user-history exclusion, close-session cleanup, and launch cleanup after crash.
- VERIFIED: `snapshot_kind` accepts `user` and `transient` and rejects an invalid kind.
- HIGH: There is no active-reference retention rule, cleanup transaction/precondition, ownership token, lease, or reference count.
- HIGH: The schema explicitly permits deleting a transient snapshot referenced by a `running` comparison because `left_snapshot_id` and `right_snapshot_id` use `ON DELETE SET NULL`.
- VERIFIED: The fixture deleted transient snapshot `11` while comparison `200` was `running`; the comparison remained `running` and `left_snapshot_id` became `NULL`.
- HIGH: Crash/relaunch ordering is incomplete: it does not define how `running` comparisons are terminalized, how `scanning` transients are handled before cleanup, or which completed/transient records are retained.
- HIGH: Cleanup safety and “abandoned” selection criteria are undefined, so “automatically deleted/cleaned up” is not a concrete safe lifecycle.
- INFERRED: `snapshot_kind` separates user and transient records and no documented operation promotes or replaces a user snapshot, but silent replacement prevention is not enforced as a lifecycle invariant.

Active-reference output:

```text
id   status   left_snapshot_id  right_snapshot_id
---  -------  ----------------  -----------------
200  running                    10
integrity_check
---------------
ok
```

### Canonical alignment

- HIGH: `docs/DECISIONS.md` contains no accepted ADR or normative pointer for normalization or transient snapshots, despite `docs/AGENT.md` requiring architecture decisions to be recorded there.
- HIGH: `docs/MVP_PLAN.md` does not make independently approved R0 closure a prerequisite to coding. It begins with Xcode work and its next relevant comparison scope only lists live-folder versus snapshot.
- HIGH: `docs/PRODUCT_STATE.md` says “pre-code closure for R0-BLOCKERS” but immediately names Xcode/scanner foundation as the next milestone; it does not record that independent audit approval is still required.
- HIGH: `docs/PRD.md` uses singular “normalized relative path,” omits `uncertain` from comparison classifications, and does not define version/collision compatibility, so it is not fully aligned with Architecture.
- HIGH: `docs/TEST_PLAN.md` lacks explicit normalization-version, invalid-kind, transient lifecycle/cleanup, active-reference, cross-version, and collision-result tests.
- VERIFIED: No audited document explicitly defines a second direct-live-filesystem diff engine path; Architecture defines the single transient-snapshot path. Other documents mention live sources without describing that execution path.
- VERIFIED: Product language continues to distinguish metadata match from content verification.
- HIGH: Local-only/no-notarization scope is contradicted by `docs/DECISIONS.md` ADR-006, `docs/MVP_PLAN.md` Phase 5, and `docs/PROJECT_MANIFEST.md`, all of which specify signed/notarized DMG distribution. The Forge Handoff claim that notarization remains out of scope is unsupported by canonical documents.

### Forge Handoff compliance

- VERIFIED: Forge Handoff exists at `AI_HANDOFFS/2026-07-24/SESSION_bc4dfe17-4bd0-414b-906f-891524a4904f/H_R0BLOCKERS_C_0724210734.md`.
- VERIFIED: Matching `.sha256` exists and validates:

```text
AI_HANDOFFS/2026-07-24/SESSION_bc4dfe17-4bd0-414b-906f-891524a4904f/H_R0BLOCKERS_C_0724210734.md: OK
```

- VERIFIED: Its required section set is present.
- HIGH: Filename role code `C` is noncompliant with its declared `PRIMARY FORGE` role; `docs/AGENT.md` assigns Forge the code `F`.
- MEDIUM: Important claims in WORK COMPLETED and IMPLEMENTATION OR REVIEW DETAILS are not individually labeled VERIFIED, INFERRED, PROPOSED, BLOCKED, or ACCEPTED RISK.
- MEDIUM: It lists commands and summary claims but does not record exact SQL or sufficient command output for duplicate rejection, Unicode collision, root behavior, schema/index definitions, cross-version handling, or cleanup safety.
- HIGH: Its “exact original byte sequence/string,” “detailed normalization,” and “automatically cleaned up” claims overstate the actual specification.
- BLOCKED: No other Handoff exists in the repository; therefore no separate latest compliant Handoff was available to read.

## COMMANDS EXECUTED

Repository and document inspection:

```text
pwd
test -d .codegraph
test -d .git
rg --files ...
wc -l ...
nl -ba <required documents and Handoff>
stat -f '%Sm %z %N' ...
rg --files | rg '(\.swift$|\.xcodeproj/|Package\.swift$|project\.pbxproj$)'
rg -n -i '<normalization/transient/distribution terms>' docs AI_HANDOFFS/2026-07-24
sha256sum -c AI_HANDOFFS/2026-07-24/SESSION_bc4dfe17-4bd0-414b-906f-891524a4904f/H_R0BLOCKERS_C_0724210734.md.sha256
```

Fresh database:

```text
mktemp -d /private/tmp/fsd-r0-audit-0724-02.XXXXXX
sqlite3 /private/tmp/fsd-r0-audit-0724-02.yk7rX1/audit.sqlite3 < docs/database/schema.sql
sqlite3 -header -column /private/tmp/fsd-r0-audit-0724-02.yk7rX1/audit.sqlite3 \
  "SELECT sqlite_version(); SELECT * FROM schema_migrations; PRAGMA integrity_check; PRAGMA foreign_key_check;"
```

Relevant initial output:

```text
wal
sqlite_version
--------------
3.43.2
schema_version  applied_at
--------------  -------------------
1               2026-07-24 14:16:02
integrity_check
---------------
ok
```

Fixture operations executed with `PRAGMA foreign_keys=ON` on every SQLite connection:

```text
INSERT user snapshot
INSERT transient snapshot
INSERT invalid snapshot kind 'ephemeral'
INSERT root entry
INSERT Report.txt and REPORT.txt
INSERT NFC Café.txt and NFD Café.txt
INSERT exact duplicate Report.txt
INSERT second root path ''
INSERT parentless non-root path 'orphan-top'
GROUP BY case_folded_path HAVING COUNT(*) > 1
GROUP BY case_preserving_path HAVING COUNT(*) > 1
EXPLAIN QUERY PLAN <collision query>
SELECT from sqlite_master
PRAGMA index_list('entries')
PRAGMA index_xinfo('sqlite_autoindex_entries_1')
PRAGMA index_xinfo('idx_entries_snapshot_case_folded_path')
INSERT normalization version 2.0 snapshot
INSERT comparisons for same-version and different-version snapshots
DELETE transient snapshot referenced by running comparison
PRAGMA integrity_check
PRAGMA foreign_key_check
```

Expected rejection output:

```text
Error: stepping, CHECK constraint failed: snapshot_kind IN ('user', 'transient') (19)
Error: stepping, UNIQUE constraint failed: entries.snapshot_id, entries.relative_path (19)
Error: stepping, UNIQUE constraint failed: entries.snapshot_id, entries.relative_path (19)
```

Repository hygiene:

```text
git diff --check
git status --short
rg -n '[[:blank:]]+$' <audited canonical files>
rg -n '^(<<<<<<<|=======|>>>>>>>)' <audited canonical files>
```

Relevant output:

```text
git diff --check: exit 129
warning: Not a git repository. Use --no-index to compare two paths outside a working tree

git status --short: exit 128
fatal: not a git repository (or any of the parent directories): .git

trailing-whitespace check: no output
merge-marker check: no output
```

## AUTOMATED VERIFICATION

- VERIFIED: Schema application succeeded.
- VERIFIED: `PRAGMA integrity_check` returned `ok` before and after fixture mutations.
- VERIFIED: `PRAGMA foreign_key_check` returned no rows before and after fixture mutations.
- VERIFIED: User and transient snapshots inserted successfully.
- VERIFIED: Invalid snapshot kind was rejected.
- VERIFIED: Case variants and NFC/NFD variants inserted successfully.
- VERIFIED: Exact duplicate and duplicate root path were rejected.
- VERIFIED: Collision grouping and covering-index usage were demonstrated.
- VERIFIED: Schema/index definitions use BINARY collation.
- VERIFIED: Normalization version is stored, and schema permits a comparison between versions `1.0` and `2.0` without a database precondition.
- VERIFIED: Active-reference deletion hazard was reproduced.

## REAL MANUAL TESTS

- VERIFIED: None performed; none required by the manual-test policy.
- INFERRED: Scanner behavior, source read-only runtime behavior, offline browsing, lazy UI loading, crash recovery, and comparison runtime behavior cannot be proven because no application code exists.

## VERIFIED RESULTS

- VERIFIED: Metadata-only, source read-only, SQLite-canonical, lazy-loading, no-content-hashing, no-source-mutation, and content-not-verified invariants remain stated in canonical documents.
- VERIFIED: The narrow SQLite uniqueness claim for representable stored text is correct.
- VERIFIED: Collision detection is possible through indexed queries.
- VERIFIED: One transient-backed comparison path is stated.
- VERIFIED: All three R0 blockers are not fully closed.

## INFERRED RESULTS

- INFERRED: A correct implementation could be built on the current non-unique comparison-key indexes after the normalization and collision contracts are made deterministic.
- INFERRED: Existing schema fields are close to a viable transient model, but lifecycle/reference semantics require a foundational decision and likely schema/constraint changes.

## PROPOSED ITEMS

- PROPOSED: Add golden normalization fixtures for ASCII, NFC/NFD, `ß`/`ss`, Greek sigma forms, dotted/dotless I, root, separator rejection, invalid/unrepresentable input, and length limits.
- PROPOSED: Document collision result-group representation and query contract, including how all members remain inspectable.
- PROPOSED: Add schema invariants or repository assertions for same-snapshot parentage and exactly one valid root.

## BLOCKED ITEMS

- BLOCKED: Git diff/status and history-based patch reconstruction because `.git/` is absent.
- BLOCKED: Scanner, UI, runtime comparison, crash recovery, and read-only behavior verification because implementation has not begun.
- BLOCKED: “Exact filesystem bytes” verification because schema stores only `TEXT`.
- BLOCKED: Latest compliant prior Handoff review because the only prior Handoff is role-code/evidence noncompliant.

## ACCEPTED RISKS

- None accepted by this audit.

## KNOWN ISSUES

- The repository is not a Git repository.
- No source implementation exists.
- Root/parent hierarchy integrity is only partially enforced.
- The comparison schema permits active-source deletion through `ON DELETE SET NULL`.
- Normalization version `1.0` has no deterministic normative definition.

## AUDIT SCOPE

- Actual R0 schema and canonical documentation patch.
- Three R0 blockers: path identity/uniqueness, deterministic versioned normalization/key selection, and transient-snapshot live comparison.
- Focused SQLite behavior and Handoff compliance.
- No implementation, Git initialization, GitHub access, VisualDiffer source access, or canonical-document edits.

## EVIDENCE REVIEWED

- Current canonical files listed under FILES READ.
- SQLite DDL and `sqlite_master`/index metadata.
- Fresh disposable SQLite fixture output.
- Filesystem timestamps and absence of Git/history backups.
- Forge Handoff content and checksum.

## FINDINGS BY SEVERITY

### Critical

- None.

### High

1. Normalization and Unicode case folding are not deterministic or implementable as written.
2. Source case sensitivity is not captured in a schema field needed for two-source key selection.
3. Cross-normalization-version behavior is ambiguous and can change snapshot interpretation.
4. “Exact byte sequence” is unsupported by Swift String/SQLite TEXT storage.
5. Root and parent/snapshot hierarchy integrity is incomplete.
6. Collision runtime/result representation and canonical PRD alignment are incomplete.
7. Transient cleanup can invalidate a running comparison; crash/relaunch lifecycle is incomplete.
8. DECISIONS, MVP_PLAN, PRODUCT_STATE, PRD, TEST_PLAN, and distribution statements are not canonically aligned.
9. Forge Handoff role code and foundational claims are noncompliant/overstated.

### Medium

1. Invalid/excessive path handling lacks deterministic limits and snapshot/comparison consequences.
2. TEST_PLAN fixture names are not sufficient executable acceptance tests.
3. Forge Handoff evidence does not contain enough exact SQL/output for its closure claims.

### Low

1. Git hygiene commands are unavailable until a later authorized Git initialization task.

## REQUIRED FIXES

1. Record accepted normalization and transient-snapshot decisions in `docs/DECISIONS.md`, or add explicit accepted ADR entries that point to normative Architecture sections.
2. Replace “e.g.” normalization language with one exact component-by-component algorithm: scanner input representation, fixed Unicode normalization form/API, operation order, locale-independent full Unicode case-fold API/data version, root, separator, invalid separator/component rules, and golden outputs. Bind `normalization_version` to that complete recipe.
3. Choose and state the identity boundary:
   - if identity is Unicode text, remove all “exact byte sequence” claims, define the exact scanner-produced string representation, and define unrepresentable-byte handling; or
   - if exact filesystem bytes are required, add a separately captured raw-byte `BLOB` identity and constrain that value.
4. Persist source case sensitivity per snapshot using a constrained, inspectable value and define behavior for unknown/unsupported sensitivity.
5. Define one deterministic cross-version policy. Do not use “warn or upgrade.” Either block comparison until keys are regenerated under a named version without mutating immutable snapshot facts, or define a specific, tested compatibility/migration procedure.
6. Enforce/document one valid root per snapshot and same-snapshot parentage. At minimum, parentless entries must be limited to `relative_path = ''`, and parent references must not cross snapshots.
7. Define collision groups as first-class uncertain results: all members retained, no arbitrary pairing, indexed query contract, persistence/lazy-query representation, and PRD classification alignment.
8. Define transient ownership and lifecycle precisely: creation owner/session, terminal comparison states, close trigger, cleanup transaction, active-reference prohibition, crash/relaunch ordering, stale-running comparison handling, retention criteria, and user-snapshot non-replacement.
9. Change foreign-key/cleanup behavior or add an enforced repository precondition so a transient snapshot cannot be deleted while referenced by an active comparison. A `running` comparison must never survive with a required source set to `NULL`.
10. Update `docs/MVP_PLAN.md` and `docs/PRODUCT_STATE.md` so independently approved R0 closure is a hard prerequisite to Xcode/catalog work.
11. Align `docs/PRD.md` with the two-key/collision/`uncertain` model and the full live-source matrix.
12. Expand `docs/TEST_PLAN.md` with executable expectations for case and NFC/NFD collisions, full case folding, normalization-version storage/mismatch, source sensitivity selection, invalid kind, transient interruption, close cleanup, crash cleanup, active-reference safety, root invariants, and no-arbitrary-pairing behavior.
13. Remove or explicitly supersede signed/notarized distribution requirements in `docs/DECISIONS.md`, `docs/MVP_PLAN.md`, and `docs/PROJECT_MANIFEST.md` to preserve local-only distribution with no notarization, Developer ID, or App Store requirement.
14. Produce a compliant Forge Handoff using role code `F`, classification labels for important conclusions, and sufficient exact command/SQL output.

## OPTIONAL IMPROVEMENTS

- Add a deterministic local schema-audit script for fresh apply, constraints, collision grouping, root invariants, and transient lifecycle fixtures.
- Add a canonical path-normalization reference document only if an ADR/Architecture section would become too dense; keep one normative source.

## REMAINING WORK IN CURRENT PHASE

- Apply and independently re-audit the required R0 schema/specification corrections.
- Keep all Swift/Xcode/catalog foundation work blocked until an APPROVE audit.

## EXACT NEXT ACTION

Create a focused R0 corrective documentation/schema task covering REQUIRED FIXES 1–14, then run a new independent audit with fresh SQLite fixtures. Do not begin Xcode/catalog foundation work before that audit returns APPROVE.

## GIT STATUS

- BLOCKED: `git diff --check` exit 129; not a Git repository.
- BLOCKED: `git status --short` exit 128; not a Git repository.

## COMMIT READINESS

NOT READY. Git is absent, commit was not authorized, and foundational R0 blockers remain open.

## PUSH READINESS

NOT AUTHORIZED. No GitHub access, commit, or push was performed.

## RECOMMENDED REVIEW FOCUS

1. Exact normalization API/data-version contract and Unicode full case folding.
2. Unicode-text versus raw-byte identity decision.
3. Root/same-snapshot parent constraints.
4. Active-reference-safe transient cleanup and crash ordering.
5. DECISIONS/MVP/PRD/TEST_PLAN/distribution alignment.
6. Re-run the collision and transient-deletion fixtures after correction.

## DECISION: REJECT

Rationale: all three foundational blockers remain unresolved in material ways. SQLite schema application succeeds, but normalization is ambiguous, exact-byte identity is unsupported, root hierarchy is underconstrained, collision semantics lack canonical/runtime closure, and transient cleanup can invalidate an active comparison. Canonical documents and the Forge Handoff are also not aligned/compliant.

Xcode/catalog implementation may begin: NO.
