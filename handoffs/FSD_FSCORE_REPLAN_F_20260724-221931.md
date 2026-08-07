# Handoff: FSD-FSCORE-REPLAN-0724-04

AGENT: Claude
ROLE: LOGIC, ARCHITECTURE, AND PROJECT REPLANNING
MODE: review and documentation
TASK ID: FSD-FSCORE-REPLAN-0724-04
PHASE: Phase 0 — Planning and architecture definition (multi-filesystem scope replan; R0 correction remains a separate, still-open concern)

## OBJECTIVE

Re-evaluate and revise the complete FSD product architecture and implementation plan around a new canonical requirement: FSD must ship as one self-contained `.app` that reads APFS, HFS+, FAT16, FAT32, exFAT, NTFS, ext2, ext3, ext4, and UDF without the user installing Homebrew, macFUSE, ntfs-3g, kernel extensions, or system extensions, with no camera-vendor recognition at any phase. Documentation, architecture, feasibility planning, schema review, and dependency review only — no production Swift code, no Xcode project, no compiled/bundled library, no Git initialization.

## REPOSITORY STATE BEFORE

- `FSD_ROOT` resolved to `/Users/cenvu/Desktop/DEV/FSD` (the `DEV`/`Dev` casing variants are the same inode on case-insensitive APFS — confirmed via `stat -f "%i"`).
- Not a Git repository (`.git` absent).
- Phase 0 — Planning and architecture definition. R0 schema/normalization corrective lineage had been independently audited and returned **REJECT** (`AI_HANDOFFS/2026-07-24/SESSION_2f0cf146.../H_R0BLOCKERS_A_0724211837.md`, 14 required fixes, none of which this task's scope covers or closes).
- `docs/database/schema.sql` was already at an R0-patched but unversioned-past-1 state (`snapshot_kind`, `normalization_version`, `source_case_sensitivity`, `case_preserving_path`/`case_folded_path`, parent/root integrity constraints, transient-safe comparison FKs) plus a `docs/database/verify.sql` fixture script from that lineage.
- Legacy `AI_HANDOFFS/` directory existed with two files plus `.sha256` sidecars; a flat `handoffs/` directory already existed with one migrated file from the R0 corrective round (`FSD_R0_CORRECTION_F_20260724-213226.md`).
- Stray `temp.db`/`temp.db-shm`/`temp.db-wal`/`temp2.db*` files were present at `FSD_ROOT` (previous agent's SQLite verification scratch files, not under `docs/`) — inventoried, not deleted (out of this task's explicit scope; a gitignore pattern was added so they aren't accidentally committed later).
- No production Swift/Xcode project existed.

## FILES READ

`docs/README.md`, `docs/PRD.md`, `docs/ARCHITECTURE.md`, `docs/MVP_PLAN.md`, `docs/PRODUCT_STATE.md`, `docs/DECISIONS.md`, `docs/PROJECT_MANIFEST.md`, `docs/KNOWN_ISSUES.md`, `docs/TEST_PLAN.md`, `docs/SECURITY_AND_READ_ONLY_POLICY.md`, `docs/UX_UI_SPEC.md`, `docs/REFERENCE_VISUALDIFFER.md`, `docs/REVIEW_CLAUDE_CODE.md`, `docs/database/schema.sql`, `docs/database/verify.sql`, `docs/AGENT.md`, `docs/PROJECT_SUPPORT/AI_HANDOFFS.md`, `docs/PROJECT_SUPPORT/GITIGNORE.template`, both files under the legacy `AI_HANDOFFS/` tree, `handoffs/FSD_R0_CORRECTION_F_20260724-213226.md`.

## FILES CHANGED

`docs/PRD.md`, `docs/ARCHITECTURE.md`, `docs/MVP_PLAN.md` (near-total rewrite), `docs/PRODUCT_STATE.md`, `docs/DECISIONS.md` (ADR-014 through ADR-018 added), `docs/PROJECT_MANIFEST.md`, `docs/KNOWN_ISSUES.md` (KI-005 corrected, KI-009/010/011 added), `docs/TEST_PLAN.md`, `docs/SECURITY_AND_READ_ONLY_POLICY.md`, `docs/README.md`, `docs/AGENT.md`, `docs/database/schema.sql` (version 2), `docs/database/verify.sql` (extended fixtures), `docs/PROJECT_SUPPORT/GITIGNORE.template`.

## FILES CREATED

`docs/FILESYSTEM_PROVIDER_ARCHITECTURE.md`, `docs/FILESYSTEM_SUPPORT_MATRIX.md`, `docs/DEPENDENCY_AND_LICENSE_REVIEW.md`, `docs/FILESYSTEM_FEASIBILITY_PLAN.md`, `docs/FILESYSTEM_REPLAN_CLAUDE.md`, `docs/PROJECT_SUPPORT/HANDOFFS.md` (replacing, via rename, `docs/PROJECT_SUPPORT/AI_HANDOFFS.md`), `handoffs/FSD_R0BLOCKERSCLOSURE_C_20260724-210734.md`, `handoffs/FSD_R0BLOCKERSAUDIT_A_20260724-211837.md` (both migrated verbatim from the deleted `AI_HANDOFFS/` tree), this handoff.

## DEPENDENCIES RESEARCHED

libfsapfs/libfshfs/libfsntfs/libfsext/libfsfat (libyal project, LGPL-3.0-or-later, actively maintained, "experimental" label per project convention not a project-specific abandonment signal), The Sleuth Kit / libtsk (IBM Public License 1.0 / Common Public License 1.0, arm64 buildable via a recent Homebrew bottle but historically rough, broader scope than needed), e2fsprogs/libext2fs (GPL-2.0, not evaluated in depth — a harder-to-isolate license than libfsext for the same coverage), macFUSE/ntfs-3g-based tools (excluded — require a user-installed system extension), Apple FSKit (excluded on two independent grounds: requires macOS 15+, above FSD's stated 13+ floor, and packages as a system extension regardless of OS version), `/usr/libexec/authopen` (system BSD utility for scoped one-time read-only device authorization), and — the key scope-changing finding — current documentation of macOS's own native filesystem support across the 13–26 range, establishing that 7 of the 9 required filesystems need no third-party dependency at all. Full citations in `docs/DEPENDENCY_AND_LICENSE_REVIEW.md` §8.

## VERIFIED RESULTS

- VERIFIED: macOS natively mounts APFS, HFS+, FAT16, FAT32, exFAT (read/write) and NTFS (read-only) and UDF, across macOS 13 through 26, with no user-installed driver, kext, or system extension — narrowing the embedded-reader problem to ext2/ext3/ext4 only.
- VERIFIED: Apple FSKit requires macOS 15+ for third-party use and packages as a system extension — excluded on both counts.
- VERIFIED: libfsext/libfsapfs/libfshfs/libfsntfs/libfsfat are LGPL-3.0-or-later and actively maintained (releases as recent as May 2026 in the sources consulted).
- VERIFIED: `docs/database/schema.sql` (revised) applies cleanly to a fresh SQLite database; `PRAGMA integrity_check` returns `ok`; `PRAGMA foreign_key_check` returns no rows; `schema_migrations` records versions 1 and 2.
- VERIFIED (via `docs/database/verify.sql` against a fresh database): a default native/mounted snapshot inserts successfully; an `embedded_raw`/`disk_image` snapshot with full provider metadata inserts successfully; an `embedded_raw`/`raw_device` snapshot with `authorization_required=1` inserts successfully; `embedded_raw`+`mounted` is rejected by the new CHECK constraint; `native`+`raw_device` is rejected; negative `partition_offset` is rejected; `scan_issues.source` accepts `'scanner'`/`'reader'` and rejects any other value; a diagnostic `GROUP BY snapshot_id, source, severity` query correctly derives reader-vs-scanner issue counts without denormalized counter columns.
- VERIFIED: no Markdown file under `docs/` has trailing whitespace or merge-conflict markers.
- VERIFIED: the legacy `AI_HANDOFFS/` directory contained exactly two unique Markdown files (one already-superseded first R0 attempt cited as evidence by the audit, one unmigrated audit REJECT decision); both migrated verbatim into flat `handoffs/` files without their `.sha256` sidecars; `AI_HANDOFFS/` deleted; no remaining nested-Handoff or checksum-policy language in any canonical document.
- VERIFIED: `git status --short` exits 128 ("not a git repository") and `git diff --check` exits 129, confirming no `.git` exists; neither command was worked around, and no repository was initialized.
- VERIFIED: no canonical document requires the user to install Homebrew/macFUSE/ntfs-3g/a kernel or system extension; no camera-vendor recognition remains in scope anywhere except as explicit exclusion language (`PRD.md` §4.1, `DECISIONS.md` ADR-018, `FILESYSTEM_REPLAN_CLAUDE.md`); no new read-write filesystem operation was introduced (raw-device access is read-only by contract, `FILESYSTEM_PROVIDER_ARCHITECTURE.md` §6).

## INFERRED RESULTS

- INFERRED: libfsext will handle ext2/ext3/ext4 detection, read-only opening, and enumeration correctly against real and adversarial fixtures — not yet proven; Phase 0A/2 is the actual proof.
- INFERRED: a plain read-only `open()` or, failing that, a single `authopen` prompt will be sufficient for raw physical-device access — not yet proven; Phase 3 is the actual proof.

## PROPOSED ITEMS

- PROPOSED (recorded, not yet decided): a normalized `devices`/`partitions` identity table separate from `volumes`, if raw-device identity needs grow beyond the per-snapshot fields this replan added (`PRD.md` §6.1).
- PROPOSED: TSK as the ext2/3/4 fallback reader, only if libfsext fails Phase 0A/2 (`DECISIONS.md` ADR-015, `MVP_PLAN.md` deferred backlog).

## BLOCKED ITEMS

- BLOCKED: R0 correction round 2 and its independent audit — out of this task's scope; remains a separate, still-open gate in front of Phase 0 (`MVP_PLAN.md` header, `PRODUCT_STATE.md`).
- BLOCKED: Phase 0A (disk-image feasibility spike) and Phase 3 (physical-device authorization) — both specified in full detail but not executed, since execution requires code and this task is documentation-only.
- BLOCKED: `git status`/`git diff --check` — no `.git` repository exists; not initialized, per constraints.

## ACCEPTED RISKS

- ACCEPTED RISK: libfsext could fail against the harder ext2/3/4 fixtures (non-UTF-8 names, fscrypt-encrypted subtrees); mitigated by a documented TSK fallback and by gating Phase 2's exit criteria on exactly these fixtures, not just the easy ones.
- ACCEPTED RISK: raw-device permission behavior varies across macOS versions/media classes in the sources consulted and is not settled by research; mitigated by treating Phase 3 as a mandatory empirical gate before Phase 7 (automatic capture) rather than assuming an answer.
- ACCEPTED RISK: the R0 wave's schema changes were applied without ever bumping `schema_migrations` past version 1; this replan bumps to version 2 going forward and documents the gap in `schema.sql`'s header comment rather than silently re-committing it.

## SCHEMA CHANGES

Version 2. On `snapshots`: added `filesystem_provider`, `provider_version`, `source_access_mode`, `device_identifier`, `partition_identifier`, `partition_offset`, `partition_length`, `filesystem_variant`, `filesystem_features_json`, `authorization_required`, plus two `CHECK` constraints (provider/access-mode consistency; non-negative offset, positive length). On `scan_issues`: added `source` (`'scanner' | 'reader'`) plus a supporting index, in place of separate `reader_warning_count`/`reader_error_count` columns (rejected as redundant with a `GROUP BY` query — see `FILESYSTEM_REPLAN_CLAUDE.md` Schema Impact section for the full reasoning, including why `raw_source_kind` was folded into `source_access_mode` and why `case_sensitivity_source` was not duplicated against the existing `source_case_sensitivity`). All R0-wave constraints, triggers, and columns preserved unchanged. `schema_migrations` now records both version 1 and 2. Applied fresh and verified — see VERIFIED RESULTS.

## AI_HANDOFFS CLEANUP RESULT

Inventoried 2 unique files under `AI_HANDOFFS/2026-07-24/` (plus their `.sha256` sidecars). Both migrated verbatim into flat `handoffs/` files (`FSD_R0BLOCKERSCLOSURE_C_20260724-210734.md`, `FSD_R0BLOCKERSAUDIT_A_20260724-211837.md`) with a one-line provenance comment each; checksums intentionally not carried over. `AI_HANDOFFS/` directory deleted and confirmed gone. `docs/PROJECT_SUPPORT/AI_HANDOFFS.md` renamed to `docs/PROJECT_SUPPORT/HANDOFFS.md` with updated content. `docs/AGENT.md` and `docs/DECISIONS.md` (ADR-013, amended) updated to drop the now-inapplicable "existing historical AI_HANDOFFS files must remain untouched" clause. `docs/README.md`'s bundle map and `docs/PROJECT_SUPPORT/GITIGNORE.template`'s stale `AI_HANDOFFS/**/TEMP_*` entry updated. Remaining textual mentions of "AI_HANDOFFS" are intentional historical/provenance references (`docs/AGENT.md`, `docs/DECISIONS.md`, `docs/PROJECT_SUPPORT/HANDOFFS.md`) or an untouched prior-review artifact (`docs/REVIEW_CLAUDE_CODE.md`, dated, not a normative document); `docs/BUNDLE_FILE_MANIFEST.md` still references the old filename in a stale point-in-time hash manifest, left as-is since recomputing that manifest is out of this task's scope.

## REVISED PHASE PLAN

Phase 0A (multi-filesystem feasibility, disk-image-only) → Phase 0B (resulting ADRs) → Phase 0 (Xcode/catalog foundation, gated behind R0 audit APPROVE and Phase 0B) → Phase 1 (provider contract + native provider) → Phase 2 (embedded-raw prototype, disk images only) → Phase 3 (physical-device authorization, first real raw-device touch) → Phase 4 (snapshot persistence, provider-agnostic) → Phase 5 (offline browser) → Phase 6 (comparison engine) → Phase 7 (automatic detection/capture, behind the pre-existing four-condition gate plus Phase 3's proof) → Phase 8 (export and local packaging). Full per-phase objective/dependencies/deliverables/exit-criteria/tests/risks/out-of-scope in `docs/MVP_PLAN.md`; Phase 0A/0B detail in `docs/FILESYSTEM_FEASIBILITY_PLAN.md`.

## DECISIONS STILL REQUIRED

1. R0 correction round 2, closing all 14 required fixes from the rejected audit, then a fresh independent audit APPROVE.
2. Phase 0A executed on real disk images — confirms or overturns ADR-015 (libfsext vs. TSK).
3. Phase 3 executed on a real external drive — confirms or overturns ADR-016 (`authopen` vs. plain `open()`).
4. Whether a normalized `devices`/`partitions` table is worth building now (leaning: no, defer).
5. Phase 7's unattended-authorization behavior (defer capture vs. skip with notification), dependent on decision 3.

## COMMANDS EXECUTED

`stat -f "%i"` (confirm DEV/Dev path identity); `find`/`ls` inventory of `AI_HANDOFFS/`, `handoffs/`, `docs/`; `diff` comparing the two pre-existing handoff files to confirm one was unique, not a duplicate; `WebSearch`/`WebFetch` for libyal/TSK/FSKit/authopen/macOS-native-filesystem research (queries and sources listed in `docs/DEPENDENCY_AND_LICENSE_REVIEW.md` §8); `rm -rf AI_HANDOFFS`; `mv docs/PROJECT_SUPPORT/AI_HANDOFFS.md docs/PROJECT_SUPPORT/HANDOFFS.md`; `sqlite3 <fresh-db> < docs/database/schema.sql`; `sqlite3 -header -column <fresh-db> < docs/database/verify.sql`; `PRAGMA integrity_check`; `PRAGMA foreign_key_check`; `grep -rn`/`grep -rlnE` sweeps for stale scope language, trailing whitespace, and merge markers across `docs/`; `git status --short`; `git diff --check`.

## VERIFICATION RESULTS

All required documents exist (17/17 checked). No canonical document requires external filesystem installation (2 informational-only hits, both correctly scoped). No camera-vendor profile remains in scope (3 hits, all exclusion language). No new read-write filesystem operation was introduced (1 hit, correctly describing the absence of a write-capable fallback). No nested `AI_HANDOFFS` policy remains. No `.sha256` Handoff policy remains (1 hit, correctly describing its own absence). `AI_HANDOFFS/` deletion confirmed; 3 files present in `handoffs/`. Zero files with trailing whitespace. Zero merge-conflict markers. SQLite: fresh apply clean, `integrity_check` = `ok`, `foreign_key_check` = no rows, both migration versions recorded. Git: `status --short` exit 128, `diff --check` exit 129, both correctly reported as BLOCKED (no `.git`), no repository initialized.

## GIT STATUS

BLOCKED — `/Users/cenvu/Desktop/DEV/FSD` is not a Git repository (`.git` absent). Not initialized, per constraints.

## COMMIT READINESS

NOT APPLICABLE — no Git repository exists.

## PUSH READINESS

NOT AUTHORIZED — no Git repository, no remote, no push performed or requested.

## EXACT NEXT ACTION

Route this replan to an independent audit (the same process the R0 lineage used) focused on the areas named below. In parallel, and independently, resume the R0 correction round (14 required fixes from `handoffs/FSD_R0BLOCKERSAUDIT_A_20260724-211837.md`) — this replan does not close that gate. Do not begin Xcode/Swift implementation until both R0 audit APPROVE and Phase 0B's ADRs (post-Phase-0A) are in place.

## RECOMMENDED AUDIT FOCUS

1. Whether the "7 of 9 filesystems are already native" finding is correct and sufficiently evidenced (`DEPENDENCY_AND_LICENSE_REVIEW.md` §2) — this is the load-bearing claim the rest of the replan narrows around.
2. The FSKit exclusion reasoning (macOS 15+ floor and system-extension packaging, both independently sufficient) — confirm neither is misstated.
3. The new schema v2 CHECK constraints and `scan_issues.source` discriminator — re-run `database/verify.sql` independently against a fresh database.
4. Whether folding `raw_source_kind` into `source_access_mode`, and not duplicating `case_sensitivity_source`, were the right calls, or whether the brief intended three distinct fields.
5. The authorization boundary (`authopen`, no custom helper) and reader-helper-process isolation design, given both are explicitly unverified until Phase 0A/2/3.
6. Whether the two-independent-gates framing (R0 vs. Phase 0A/0B) in `MVP_PLAN.md`'s header is the correct way to sequence a still-open prior rejection against this new, unrelated work.
