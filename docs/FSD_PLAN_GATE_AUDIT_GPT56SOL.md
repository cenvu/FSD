# FSD Consolidated Plan Gate Audit

**Audit date:** 2026-07-24
**Task:** FSD-PLAN-GATE-AUDIT-0724-06
**Scope:** Planning/schema audit only. No application code, canonical-document, or schema changes were made.

## 1. Executive Decision

**REJECT — CORRECTIONS REQUIRED.**

The package has useful corrective planning work and a reproducibly applicable schema v3, but it is not ready for Phase 0A. Four foundational R0 behaviours remain open in the actual DDL: completion can bypass the one-root rule, a normalization-version mismatch can be introduced by `UPDATE`, a comparison can consume an interrupted transient snapshot, and comparison results can arbitrarily pair collision members. The canonical normalization contract also conflicts with the accepted ADRs, and the migration history is not an executable v1-to-v3 upgrade path.

## 2. Repository State

- `FSD_ROOT`: `/Users/cenvu/Desktop/DEV/FSD` (the supplied `DEV` spelling exists).
- Current state is **AUDIT AND PLANNING**. `docs/PRODUCT_STATE.md` states Phase 0 planning; no Swift, Objective-C, C, C++, Xcode project, or production application source was found.
- `.git` and `.codegraph` are absent.
- The current schema identifies itself as version 3 and a fresh database receives `schema_migrations` rows `1`, `2`, and `3`.
- This audit created only this report and the required flat Audit Handoff.

## 3. Evidence Reviewed

Read all five flat Handoffs in `handoffs/`, including the required R0 correction, R0 closure, R0 audit, filesystem replan, and Collections replan Handoffs. Read every document and SQL file named in the task, including the canonical planning documents, filesystem package, Collections package, `docs/database/schema.sql`, and `docs/database/verify.sql`.

The original R0 audit, `handoffs/FSD_R0BLOCKERSAUDIT_A_20260724-211837.md`, supplied the baseline fourteen required fixes. Its dated rejection is treated as historical evidence; each item below was independently evaluated against the current files and a fresh SQLite database.

## 4. R0 Findings Closure Matrix

| ID | Original finding | Required correction | Current evidence | Status | Residual risk |
|---|---|---|---|---|---|
| R0-01 | Accepted decisions not canonicalized | Record normalization/transient decisions in DECISIONS or normative ADR | `DECISIONS.md` has ADR-009 through ADR-012, but `ARCHITECTURE.md` still conflicts | PARTIALLY CLOSED | Implementers can select contradictory contracts |
| R0-02 | Normalization was illustrative | Specify exact API/form/order/case fold/root/separator | ADR-009 provides Foundation NFC/component recipe; Architecture §5 still says “e.g. NFC/lowercase” and does not pin Unicode-data/version semantics | PARTIALLY CLOSED | Non-deterministic cross-machine implementation |
| R0-03 | “Exact bytes” claim unsupported by Swift/SQLite text | Declare Unicode-text boundary or store bytes; define unrepresentable values | ADR-009 rejects raw-byte fidelity and defines Unicode text; Architecture §5 still says “exact byte/string representation” | PARTIALLY CLOSED | False byte-preservation claim remains canonical |
| R0-04 | Case sensitivity state not sufficiently represented | Persist constrained state and unknown handling | Schema has `sensitive/insensitive/unknown`; ADR-010 defines unknown fallback, but Architecture does not align and runtime detection is unproven | PARTIALLY CLOSED | Wrong comparison key could be selected |
| R0-05 | Cross-normalization comparison could proceed | Deterministically block mismatch | INSERT trigger rejects a mismatch; `UPDATE comparisons SET right_snapshot_id=...` bypassed it | OPEN | Existing comparisons can become semantically invalid |
| R0-06 | Parent/root integrity incomplete | Enforce same-snapshot parent and exactly one root | Composite parent FK works; direct INSERT of `status='complete'` with no root succeeds because trigger is UPDATE-only | OPEN | A complete snapshot can be structurally invalid |
| R0-07 | Collisions could be arbitrarily paired | Retain all members, detect group, and prohibit arbitrary pairing | Case-fold query retains both members; `comparison_results` accepts reverse arbitrary pairs and duplicate NULL/NULL group rows | PARTIALLY CLOSED | Incorrect matches can be persisted |
| R0-08 | Transient lifecycle vague | Define ownership, cleanup, crash/relaunch, terminalization | ADR-012 is substantially better; Architecture §8 remains generic and schema permits interrupted transient comparisons | OPEN | Interrupted capture may be used as a comparison source |
| R0-09 | Referenced transient could be removed | Block deletion while active comparison references it | `comparisons` references snapshots with `ON DELETE RESTRICT`; delete of a referenced transient failed | CLOSED | Restriction also applies after completion; retention policy still needs implementation |
| R0-10 | Coding gate not recorded | Gate coding behind R0 approval | MVP/State say Phase 0 gate, but documents allow Phase 0A work in parallel and current task requires no Phase 0A while blockers remain | PARTIALLY CLOSED | Phase 0A could start prematurely |
| R0-11 | PRD did not fully express key/collision/live rules | Align PRD with two-key, uncertainty, transient model | PRD is improved, but it relies on the contradictory Architecture contract | PARTIALLY CLOSED | Canonical readers obtain inconsistent rules |
| R0-12 | Test coverage did not execute contract | Add collision, Unicode/version, transient tests | `TEST_PLAN.md` is expanded, but `verify.sql` creates complete snapshots with no roots and does not test bypasses | PARTIALLY CLOSED | Passing fixture gives false confidence |
| R0-13 | Distribution language implied commercial release/notarization | Remove requirement; retain local-only scope | ADR/MVP/manifest state local-only/no notarization. A non-canonical scripts reference still contains release examples | CLOSED | Low documentation confusion only |
| R0-14 | Forge Handoff evidence/role issues | Provide compliant, evidence-labeled Handoff | Correction Handoff has role `F`; it is not independent proof and does not contain all reproduced outputs | PARTIALLY CLOSED | Handoff assertions alone cannot close the blockers |

### [HIGH] FSD-AUDIT-001 — One-root integrity is bypassable

**Evidence**

`snapshot_root_count_on_complete` is a `BEFORE UPDATE OF status` trigger. In a fresh database, this SQL succeeded:

```sql
INSERT INTO snapshots (..., status, ...) VALUES (100, ..., 'complete', ...);
SELECT id, status FROM snapshots WHERE id = 100;
-- 100|complete
```

The same database rejected changing a rootless `scanning` snapshot to complete with: `Snapshot must have exactly one root entry to complete (19)`. The composite parent key did correctly reject a child whose parent belongs to another snapshot: `FOREIGN KEY constraint failed (19)`.

**Finding**

The parent/snapshot invariant is enforced, but exactly one root is not enforced for every transition into a terminal-complete state.

**Impact**

A snapshot marked complete can have zero roots, invalidating lazy-tree and offline browse assumptions.

**Required correction**

Make the terminal-status/root invariant apply to INSERT and all relevant UPDATE paths, and add a fixture that directly inserts every terminal complete status with zero, one, and two roots.

**Gate**

- Blocks Phase 0A: YES
- Blocks Phase 0: YES

### [HIGH] FSD-AUDIT-002 — Comparison normalization mismatch is bypassable

**Evidence**

The current trigger is `BEFORE INSERT ON comparisons`. An INSERT with versions `v1` and `v2` failed with `Mismatched normalization versions block comparison (19)`. This sequence succeeded:

```sql
INSERT INTO comparisons (id, left_snapshot_id, right_snapshot_id, ...)
VALUES (202, 103, 101, ...); -- both v1 at insertion
UPDATE comparisons SET right_snapshot_id = 104 WHERE id = 202; -- v2
SELECT id, left_version, right_version ...;
-- 202|v1|v2
```

**Finding**

The stated deterministic block is only implemented on INSERT, not on source-snapshot updates.

**Impact**

The same row can be valid at creation and invalid thereafter.

**Required correction**

Apply the invariant to INSERT and updates of both source IDs (and decide whether source IDs are immutable after creation); add negative fixtures for each path.

**Gate**

- Blocks Phase 0A: YES
- Blocks Phase 0: YES

### [HIGH] FSD-AUDIT-003 — Collision retention does not prevent arbitrary pairing

**Evidence**

Two entries were retained in one snapshot:

```text
case_folded_path = report.txt; members = 2; paths = Report.txt | REPORT.TXT
```

That proves indexable retention, not safe comparison semantics. The following rows were accepted: `Report.txt` paired with `REPORT.TXT`, the reverse pair, and two `uncertain` rows with both entry IDs NULL. SQLite’s `UNIQUE(comparison_id, result_path, left_entry_id, right_entry_id)` does not consider NULLs equal, and neither FK ties an entry to the comparison’s left/right snapshot.

**Finding**

There is no first-class collision-group identity/invariant that prevents arbitrary member pairing or duplicate uncertain group records.

**Impact**

The comparison store can encode a false match or an ambiguous result without a durable group-level relationship.

**Required correction**

Define and persist collision groups/members or an equivalent canonical group key; constrain result membership to the relevant side and group; reject arbitrary pairs; add query and constraint fixtures.

**Gate**

- Blocks Phase 0A: YES
- Blocks Phase 0: YES

### [HIGH] FSD-AUDIT-004 — Interrupted transient snapshots may be compared

**Evidence**

An interrupted transient (`snapshot_kind='transient', status='interrupted'`) was accepted as `left_snapshot_id` of a `running` comparison. A referenced complete transient could not be deleted: `FOREIGN KEY constraint failed (19)`.

**Finding**

Deletion reference safety is present, but the schema does not restrict comparison inputs to successful terminal snapshots. The accepted lifecycle in ADR-012 is therefore not executable as a schema invariant.

**Impact**

An incomplete capture may be treated as a comparison source, producing misleading results and violating the atomic-snapshot model.

**Required correction**

Enforce eligible comparison-source statuses/kinds (or make comparison creation exclusively use a guarded transaction/API and prove it), then test interrupted, cancelled, failed, and scanning transient inputs. Align Architecture cleanup/crash text with ADR-012.

**Gate**

- Blocks Phase 0A: YES
- Blocks Phase 0: YES

### [HIGH] FSD-AUDIT-005 — Canonical normalization contract is contradictory

**Evidence**

ADR-009 adopts a Unicode-text Foundation normalization recipe and explicitly rejects byte-exact fidelity. `ARCHITECTURE.md` §5 still describes `relative_path` as an “exact byte/string representation” and describes normalization as “e.g. NFC” and “e.g. NFC lowercase.”

**Finding**

The Architecture is canonical and conflicts with the accepted ADR. “Lowercase” is not a documented replacement for locale-independent full Unicode case folding.

**Impact**

Path identity and comparison-key selection remain ambiguous to an implementer.

**Required correction**

Replace the stale Architecture language with the normative ADR recipe; pin/document the Unicode/case-folding version and failure policy for unrepresentable, invalid, and excessive-length components; add an explicit canonical reference from PRD and tests.

**Gate**

- Blocks Phase 0A: YES
- Blocks Phase 0: YES

### [HIGH] FSD-AUDIT-006 — Schema v3 has no reproducible migration history and phase documents name v2

**Evidence**

`schema.sql` creates the current full schema and then inserts migration rows 1, 2, and 3 with `INSERT OR IGNORE`; it does not contain v1→v2 or v2→v3 transformations. `MVP_PLAN.md` still declares schema version 2 and a v1→v2 migration test. A fresh v3 database was valid, but that does not prove upgrade safety.

**Finding**

The migration ledger is a fresh-install label, not an executable, testable migration history. Canonical phase planning is stale.

**Impact**

Existing data interpretation and migration readiness cannot be relied on.

**Required correction**

Either declare prior schemas disposable before implementation and remove migration claims, or provide ordered, transactional migration fixtures from true v1 and v2 fixtures to v3. Update MVP_PLAN and all version references.

**Gate**

- Blocks Phase 0A: YES
- Blocks Phase 0: YES

## 5. Filesystem Replan Audit

The architectural separation is sound as a plan: `NativeMountedProvider`, `EmbeddedRawProvider`, a reader-helper isolation boundary, authorization boundary, snapshot orchestration, and SQLite persistence are distinct. The provider contract exposes enumeration/metadata reads only; no write-capable provider operation or write fallback was found. Raw parsers are correctly described as untrusted-input surfaces and the plan preserves metadata-only capture.

| Claim | Assessment | Audit result |
|---|---|---|
| APFS, HFS+, FAT16/FAT32, exFAT natively readable | VERIFIED FROM AUTHORITATIVE SOURCE | Apple Disk Utility and archived File System Programming Guide list/support these macOS formats. No FSD runtime test occurred. |
| NTFS readable read-only | VERIFIED FROM AUTHORITATIVE SOURCE | Apple states macOS can read NTFS-formatted disks but cannot write them. |
| UDF natively readable | VERIFIED FROM AUTHORITATIVE SOURCE | Apple’s archived filesystem guide lists UDF. Runtime/media coverage remains unproven. |
| ext2/ext3/ext4 require embedded reader | SUPPORTED BY PROJECT DOCUMENTATION ONLY | Reasonable from the stated native set; not independently runtime-proven. |
| libfsext first candidate | SUPPORTED BY PROJECT DOCUMENTATION ONLY | Plausibility is a Phase 0A feasibility question, not a verified runtime fact. |
| TSK fallback | SUPPORTED BY PROJECT DOCUMENTATION ONLY | Fallback suitability/license/arm64 packaging are not independently proven. |
| macFUSE and ntfs-3g installation excluded | SUPPORTED BY PROJECT DOCUMENTATION ONLY | The local-only/no-external-install policy is clear; no independent runtime/vendor assessment was performed. |
| mountfs excluded | UNVERIFIED | It is not materially assessed in the reviewed filesystem plan. |
| FSKit excluded as a system extension | INCORRECT | Apple describes FSKit as an app extension. Exclusion from a macOS 13 target may be defensible, but the stated system-extension characterization is not. |
| macOS 13+/Apple Silicon arm64 compatibility | UNVERIFIED | It is a target/plan, not a proven embedded-reader build/runtime result. |

Authoritative source links reviewed: [Apple Disk Utility file-system formats](https://support.apple.com/en-gb/guide/disk-utility/dsku19ed921c/22.7/mac/26), [Apple NTFS read-only support](https://support.apple.com/en-afri/guide/mac-help/mchlp1770/mac), [Apple File System Details archive](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemDetails/FileSystemDetails.html), and [Apple FSKit documentation](https://developer.apple.com/documentation/FSKit).

### [HIGH] FSD-AUDIT-007 — Provider auto-mount language conflicts with read-only policy

**Evidence**

`FILESYSTEM_PROVIDER_ARCHITECTURE.md` permits native capture after macOS auto-mounts a volume once FSD requests it. `SECURITY_AND_READ_ONLY_POLICY.md` prohibits mount/unmount without explicit user action.

**Finding**

The selection rule does not state whether the user action must explicitly authorize the OS mount.

**Impact**

The implementation could cause a filesystem state change under a document that promises not to.

**Required correction**

Define the precise user-confirmed mount flow or remove auto-mount from the provider selection rule; preserve no silent mount/unmount.

**Gate**

- Blocks Phase 0A: YES
- Blocks Phase 0: YES

## 6. Collections Audit

The core model is internally coherent: `NULL collection_id` represents Unsorted; `ON DELETE SET NULL` detaches snapshots; source-default rows cascade with a deleted Collection; defaults key by `volumes.id`, not display name or mount path; automatic capture is non-blocking; comparisons remain outside Collections; and `display_name` is non-null/nonblank. Fresh fixtures confirmed that two volumes called `UNTITLED` can retain separate defaults, moving a snapshot leaves its one entry and technical fields unchanged, and deleting the destination Collection detaches the snapshot and removes its default.

Collection duplicate rejection is only as deterministic as the application-supplied `normalized_name`; the DB checks nonblank text and uniqueness of the stored key. That is acceptable only once the canonical normalizer is unambiguous.

### [MEDIUM] FSD-AUDIT-008 — Collection `last_used_at` update responsibility is not executable

**Evidence**

`SNAPSHOT_COLLECTIONS.md` says moving/assigning advances `last_used_at`; the schema has no trigger and `verify.sql` leaves it NULL after its move scenario. No transaction/API requirement identifies who updates it or what happens on failed moves.

**Finding**

The desired UX behavior is described but not assigned to a constrained implementation transaction or test.

**Impact**

Recent-Collection ordering can become inconsistent without corrupting snapshot data.

**Required correction**

Specify an atomic catalog mutation contract (including timestamp source and failed-operation behavior) and test it; do not mutate entry/capture fields.

**Gate**

- Blocks Phase 0A: NO
- Blocks Phase 0: NO

## 7. SQLite Schema Version 3 Audit

A fresh temporary database outside the repository was created at `/private/tmp/fsd-plan-gate-0724-06.doy4Us/schema-v3.sqlite3`.

Commands and relevant output:

```sh
sqlite3 /private/tmp/fsd-plan-gate-0724-06.doy4Us/schema-v3.sqlite3 < docs/database/schema.sql
# wal
sqlite3 ... "PRAGMA integrity_check; PRAGMA foreign_key_check; SELECT version FROM schema_migrations ORDER BY version;"
# ok
# 1
# 2
# 3
sqlite3 ... < docs/database/verify.sql
```

`verify.sql` intentionally exercised several rejected writes (foreign-key, provider/access-mode, partition, source-default, blank/duplicate Collection, and blank display-name constraints). It continued despite those expected errors. It also demonstrated a fixture defect: it inserts three direct `complete` snapshots without roots; the post-run audit query returned `3` complete snapshots missing a root.

Independently inspected `sqlite_master` confirms:

- `entries` has `UNIQUE(snapshot_id, relative_path)`, composite `(parent_id, snapshot_id)` FK, and a root/nonroot shape check. `Report.txt` and `REPORT.TXT` coexist when their original `relative_path` differs; exact duplicate `relative_path` rejects.
- SQLite `TEXT` stores text, not a preserved exact filesystem byte sequence. The accepted ADR’s Unicode-text boundary is supportable; the Architecture byte claim is not.
- `snapshots` checks provider/access-mode combinations, nonnegative offsets, positive specified length, source-case enum, kind enum, and nonblank display name.
- Collections/default constraints, delete behaviors, and volume identity fixture passed.
- The verified upsert fixture changed the same `source_kind='volume', volume_id=1` default from Collection 1 to Collection 2 through `ON CONFLICT(source_kind, volume_id) DO UPDATE`; a separate volume with the same display name retained an independent default. Non-volume defaults and a volume default with NULL `volume_id` were rejected.
- Comparison source/version and collision relationship invariants do not pass as described in Sections 4 and 10.

The following negative expectations succeeded: cross-snapshot parent rejected; invalid provider/access pair rejected; zero partition length rejected with `CHECK constraint failed: partition_length IS NULL OR partition_length > 0 (19)`; blank Collection rejected; normalized duplicate Collection rejected; unsupported non-volume source default rejected; blank snapshot display name rejected. The following expected protections failed: direct complete-without-root insert, comparison-version update, and interrupted transient comparison creation.

## 8. Documentation Consistency

Canonical contradictions requiring correction:

- Architecture §5 contradicts ADR-009 on path/byte identity and case-folding specificity.
- Architecture’s generic transient cleanup text does not operationalize ADR-012.
- MVP_PLAN names schema v2 and v1→v2 migration while current DDL says v3.
- Filesystem documents inconsistently count the target set as 8/9, 7/9, “other six,” and all 9, although the names enumerate APFS, HFS+, FAT16, FAT32, exFAT, NTFS, UDF, ext2, ext3, and ext4 (ten variants; seven native and three ext variants).
- The auto-mount contradiction is recorded in FSD-AUDIT-007.

Stale non-canonical material was separated from canonical contradictions: `BUNDLE_FILE_MANIFEST.md` contains old hashes and references a nonexistent support handoff path; `PROJECT_SUPPORT/SCRIPTS.md` contains release/notarization examples. Neither makes notarization or commercial distribution a current canonical requirement, but both should be kept out of future evidence bundles or refreshed.

## 9. MCP CodeGraph Status

**NOT RUN — APPROPRIATE AT CURRENT STAGE.** No `.codegraph` metadata, invocation record, index output, symbol/dependency query, or impact-analysis record was found. The absence is appropriate because no production source scaffold exists.

Mandatory implementation gate before the first real Swift/C/C++ implementation session:

1. Check CodeGraph MCP availability.
2. Index after the initial source scaffold exists.
3. Run at least one real symbol/dependency query.
4. Record the result in that session’s Handoff.
5. Report `BLOCKED` when CodeGraph is unavailable.

## 10. Remaining Blockers

1. R0-05 normalization mismatch update bypass.
2. R0-06 one-root completion bypass.
3. R0-07 collision-pairing/group invariant missing.
4. R0-08 interrupted transient can enter comparison.
5. Canonical normalization contradiction and incomplete version specification.
6. Schema v3 migration-history/phase-version inconsistency.
7. Native-provider auto-mount authorization contradiction.
8. Filesystem scope cardinality and FSKit/mountfs claims require correction before they are used as implementation requirements.

## 11. Required Corrections

1. Correct the six high-severity findings above in the schema/fixtures and then independently rerun a fresh-DB audit.
2. Make DECISIONS the normative source or fully align Architecture, PRD, TEST_PLAN, MVP_PLAN, and PRODUCT_STATE with it; remove all “exact byte/string,” “e.g.”, and lowercase-as-casefold ambiguity.
3. Define an actual v1→v2→v3 migration posture and executable test, or explicitly declare pre-implementation data non-migratable and eliminate contrary migration claims.
4. Normalize filesystem support counting, correct the FSKit characterization, and expressly decide/document the mountfs policy and explicit auto-mount consent flow.
5. Specify/test Collection `last_used_at` mutation as a catalog-only atomic operation.

## 12. Readiness to Begin Phase 0A

**Not ready.** This task explicitly makes any implementation-blocking R0 finding a Phase 0A gate, and multiple such findings remain reproducible. The filesystem proposal may proceed as a reviewed plan after corrections; it does not prove runtime support and no Phase 0A feasibility implementation may begin from this audit state.

## 13. Chatbox Transition Decision

The required corrective work is planning/schema contract closure, not implementation execution. The user should retain this work in the planning review loop until an independent fresh-DB audit closes the R0 findings and canonical conflicts.

STAY IN AUDIT/PLAN

## 14. Final Decision

REJECT — CORRECTIONS REQUIRED
