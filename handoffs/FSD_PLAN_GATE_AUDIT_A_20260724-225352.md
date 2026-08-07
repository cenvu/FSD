# FSD Plan Gate Audit Handoff

AGENT: GPT-5.6-Sol / Codex
ROLE: PRIMARY INDEPENDENT AUDIT
MODE: audit
TASK ID: FSD-PLAN-GATE-AUDIT-0724-06
PHASE: AUDIT AND PLANNING

## OBJECTIVE

Independently audit the complete FSD planning package, the fourteen prior R0 required fixes, filesystem-provider replan, Collections model, schema version 3, documentation alignment, repository state, and readiness to start Phase 0A. No application implementation was authorized.

## REPOSITORY STATE

- Repository root resolved: `/Users/cenvu/Desktop/DEV/FSD`.
- No `.git` directory; Git checks are blocked. Git was not initialized.
- No `.codegraph` directory or evidence of a CodeGraph index/query.
- No Swift, Objective-C, C, C++, Xcode project, or production application code found.
- Current SQL declares schema version 3; fresh apply inserts migration ledger rows 1, 2, 3.
- Files created by this audit only: `docs/FSD_PLAN_GATE_AUDIT_GPT56SOL.md` and this Handoff.

## FILES READ

All flat Handoffs in `handoffs/`, including:

- `handoffs/FSD_R0_CORRECTION_F_20260724-213226.md`
- `handoffs/FSD_R0BLOCKERSCLOSURE_C_20260724-210734.md`
- `handoffs/FSD_R0BLOCKERSAUDIT_A_20260724-211837.md`
- `handoffs/FSD_FSCORE_REPLAN_F_20260724-221931.md`
- `handoffs/FSD_COLLECTIONS_REPLAN_F_20260724-223906.md`

Canonical/review material read:

- `docs/README.md`, `docs/PRD.md`, `docs/ARCHITECTURE.md`, `docs/MVP_PLAN.md`, `docs/PRODUCT_STATE.md`, `docs/DECISIONS.md`, `docs/PROJECT_MANIFEST.md`, `docs/KNOWN_ISSUES.md`, `docs/TEST_PLAN.md`, `docs/SECURITY_AND_READ_ONLY_POLICY.md`, `docs/UX_UI_SPEC.md`, `docs/AGENT.md`, `docs/PROJECT_SUPPORT/HANDOFFS.md`
- `docs/FILESYSTEM_PROVIDER_ARCHITECTURE.md`, `docs/FILESYSTEM_SUPPORT_MATRIX.md`, `docs/DEPENDENCY_AND_LICENSE_REVIEW.md`, `docs/FILESYSTEM_FEASIBILITY_PLAN.md`, `docs/FILESYSTEM_REPLAN_CLAUDE.md`
- `docs/SNAPSHOT_COLLECTIONS.md`, `docs/SNAPSHOT_COLLECTIONS_REVIEW_CLAUDE.md`
- `docs/database/schema.sql`, `docs/database/verify.sql`

## COMMANDS EXECUTED

```sh
pwd
test -d .codegraph
rg --files
rg --files | rg '\.(swift|m|mm|c|cc|cpp|xcodeproj)$'
git status --short
git diff --check
sqlite3 /private/tmp/fsd-plan-gate-0724-06.doy4Us/schema-v3.sqlite3 < docs/database/schema.sql
sqlite3 /private/tmp/fsd-plan-gate-0724-06.doy4Us/schema-v3.sqlite3 < docs/database/verify.sql
sqlite3 /private/tmp/fsd-plan-gate-0724-06.doy4Us/schema-v3.sqlite3 "PRAGMA integrity_check; PRAGMA foreign_key_check; SELECT version FROM schema_migrations ORDER BY version;"
sqlite3 /private/tmp/fsd-plan-gate-0724-06.doy4Us/schema-v3.sqlite3 "SELECT type,name,sql FROM sqlite_master ..."
```

Fresh SQLite negative fixtures were also run outside the repository at `/private/tmp/fsd-plan-gate-0724-06.doy4Us/negative-fixtures.sqlite3` and `collection-fixtures.sqlite3`.

## R0 CLOSURE RESULT

**REJECTED.** Exact closure classification is in `docs/FSD_PLAN_GATE_AUDIT_GPT56SOL.md` §4.

- CLOSED: R0-09 referenced transient deletion restriction; R0-13 local-only/no-notarization canonical requirement.
- PARTIALLY CLOSED: R0-01, R0-02, R0-03, R0-04, R0-07, R0-10, R0-11, R0-12, R0-14.
- OPEN: R0-05 normalization mismatch update bypass; R0-06 direct complete/root bypass; R0-08 interrupted transient comparison eligibility.

Additional reproducible foundational issue: collision members are retained but `comparison_results` can arbitrarily pair them and permits duplicate NULL/NULL uncertain rows.

## FILESYSTEM REPLAN RESULT

**APPROVED AS A NON-RUNTIME PLAN WITH REQUIRED CORRECTIONS.** The separation of NativeMountedProvider, EmbeddedRawProvider, reader-helper isolation, authorization, orchestration, and SQLite is coherent and read-only. No write-capable provider API/fallback was found.

Verified from Apple documentation at broad macOS level: APFS, HFS+, FAT16/FAT32, exFAT, UDF, and NTFS read-only. ext reader, libfsext, TSK, macFUSE/ntfs-3g exclusions, and arm64/macOS 13 runtime compatibility are not independently runtime-proven. `mountfs` exclusion is unverified. The project’s claim that FSKit is a system extension is incorrect; Apple documents it as an app extension. Provider auto-mount wording conflicts with the explicit-user-action policy.

## COLLECTIONS RESULT

**MODEL CORE VERIFIED; ONE NON-BLOCKING SPECIFICATION GAP.** Confirmed schema behavior: NULL Collection means Unsorted; nonblank display name/Collection name; normalized-key duplicate rejection; Collection deletion detaches snapshots and deletes defaults; defaults use volume ID; same display-name volumes do not collide; moving a snapshot did not alter its tested entry/capture fields. Collections do not represent physical folders and comparisons remain outside Collections.

`last_used_at` is described as changing on assignment/move but has no schema trigger or specified atomic application transaction; test fixture did not prove it. This is non-blocking for Phase 0A only after R0 is closed.

## SCHEMA V3 RESULT

**FRESH APPLY/INTEGRITY PASS; FOUNDATIONAL INVARIANTS FAIL.**

Fresh apply returned `wal`; `PRAGMA integrity_check` returned `ok`; `PRAGMA foreign_key_check` returned no rows; ledger was `1`, `2`, `3`. `verify.sql` exercised expected rejections but also created three rootless complete snapshots because it directly inserted `status='complete'` and the root trigger is UPDATE-only.

Exact reproduced failures:

- Direct rootless complete insert succeeded: `100|complete`.
- Cross-snapshot parent was correctly rejected: `FOREIGN KEY constraint failed (19)`.
- Mismatched-version INSERT was rejected: `Mismatched normalization versions block comparison (19)`.
- Updating a valid comparison to a different-version right snapshot succeeded: `202|v1|v2`.
- Interrupted transient snapshot was accepted as a running comparison input.
- Referenced transient deletion was rejected: `FOREIGN KEY constraint failed (19)`.
- `Report.txt` and `REPORT.TXT` both retained in `case_folded_path=report.txt`; arbitrary reverse pairs and duplicate NULL/NULL uncertain results were accepted.

Schema current DDL is a full fresh-install create script that marks migrations 1–3, not a reproducible v1→v2→v3 migration history. `MVP_PLAN.md` still names schema v2.

## DOCUMENT CONSISTENCY RESULT

**FAILED — CANONICAL CORRECTIONS REQUIRED.**

- Architecture §5 says exact byte/string path representation and illustrative NFC/lowercase, conflicting with ADR-009’s Unicode-text Foundation recipe.
- Architecture transient cleanup does not implement ADR-012’s lifecycle/recovery details.
- MVP_PLAN says schema v2/v1→v2 migration while schema is v3.
- Filesystem documents conflict on the count of target filesystems (8/9, 7/9, other six, all 9 versus the ten named variants).
- Provider auto-mount wording conflicts with source read-only policy’s explicit-user-action requirement.

Stale non-canonical artifacts were separated: old `BUNDLE_FILE_MANIFEST.md` hashes/paths and release examples in `PROJECT_SUPPORT/SCRIPTS.md` do not create a current notarization/commercial-release requirement.

## MCP CODEGRAPH STATUS

**NOT RUN — APPROPRIATE AT CURRENT STAGE.** No source scaffold, `.codegraph`, invocation log, index output, or query evidence exists.

Mandatory first implementation-session gate: check MCP availability; index after source scaffold; run a real symbol/dependency query; record output in Handoff; report `BLOCKED` if unavailable.

## VERIFIED CLAIMS

- FSD currently contains planning/SQL documentation rather than production implementation.
- Schema applies to a fresh SQLite database and baseline integrity/foreign-key checks pass.
- Composite entry parent/snapshot FK rejects cross-snapshot parentage.
- A referenced transient cannot be deleted under current `ON DELETE RESTRICT` FKs.
- Case-collision members can be retained and queried by folded key.
- Core Collections delete/default/volume-identity behavior succeeds in fresh fixtures.
- Provider contract has no discovered write operation.

## UNVERIFIED CLAIMS

- Runtime filesystem support for every target filesystem on macOS 13+/arm64.
- libfsext and TSK build, licensing, helper isolation, and raw-device authorization feasibility.
- Full Unicode case-folding/version behavior across actual scanner inputs.
- Scanner, browse, comparison engine, crash recovery, and source read-only runtime behavior.
- Any actual v1→v2→v3 migration.

## FINDINGS BY SEVERITY

- HIGH FSD-AUDIT-001: root completion integrity bypass.
- HIGH FSD-AUDIT-002: normalization-version comparison update bypass.
- HIGH FSD-AUDIT-003: arbitrary collision pairing/no durable collision group invariant.
- HIGH FSD-AUDIT-004: interrupted transient accepted as comparison input.
- HIGH FSD-AUDIT-005: Architecture/ADR normalization contract conflict.
- HIGH FSD-AUDIT-006: schema-v3 migration and canonical v2-plan conflict.
- HIGH FSD-AUDIT-007: auto-mount policy contradiction.
- MEDIUM FSD-AUDIT-008: Collection `last_used_at` update contract missing.

## REQUIRED CORRECTIONS

1. Enforce one root for every terminal-complete creation/transition.
2. Enforce normalization-version compatibility for all comparison source-ID mutations or make IDs immutable.
3. Persist/constrain collision groups so all members survive but no arbitrary pairing/duplicate uncertain result can be stored.
4. Prevent non-successful transient snapshots from entering a comparison and align lifecycle/crash cleanup docs.
5. Align canonical docs with ADR-009–012, including Unicode-data version and text-vs-byte boundary.
6. Supply true sequential migration fixtures or remove pre-implementation migration claims; update all v2 references to v3.
7. Resolve mount auto-request consent, filesystem cardinality, FSKit characterization, and mountfs policy.
8. Specify/test atomic Collection `last_used_at` update behavior.

## REMAINING BLOCKERS

R0-05, R0-06, and R0-08 are OPEN. R0-07 and canonical normalization are not closed because their stated safety properties are not enforced. Per task rule, any such implementation-blocking R0 finding blocks Phase 0A and Phase 0.

## PHASE 0A READINESS

**NOT READY.** No Phase 0A feasibility implementation may start until the required corrections are made and independently reproduced against a fresh database.

## CHATBOX TRANSITION DECISION

**STAY IN AUDIT/PLAN.**

## GIT STATUS

**BLOCKED — NOT A REPOSITORY.** `git status --short` exited 128 and `git diff --check` exited 129 with not-a-repository messages. Git was not initialized.

## COMMIT READINESS

NOT READY. No Git repository exists; no commit was created.

## PUSH READINESS

NOT READY. No remote/Git repository was accessed; nothing was pushed.

## FINAL DECISION

**REJECT — CORRECTIONS REQUIRED.**

## EXACT NEXT ACTION

Remain in the AUDIT/PLAN chatbox. Assign a corrective specification/schema task that fixes the R0 integrity, comparison eligibility, collision-group, normalization-contract, and migration-history issues above; then run a new independent fresh-database audit before any Phase 0A implementation work.
