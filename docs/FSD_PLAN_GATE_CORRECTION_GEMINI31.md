# FSD Plan Gate Correction

## Executive Summary
This correction addresses all high-severity blockers identified in the Phase 0A Plan Gate Audit. The SQLite schema, constraints, test fixtures, and canonical planning documents have been modified to firmly enforce foundational R0 rules and Phase 0A prerequisites without making arbitrary data mutations or generating unverifiable claims.

## Audit Findings Addressed
* FSD-AUDIT-001 (High): Root completion integrity bypass corrected.
* FSD-AUDIT-002 (High): Normalization-version comparison update bypass corrected.
* FSD-AUDIT-003 (High): Arbitrary collision pairing replaced with a durable group/member model.
* FSD-AUDIT-004 (High): Interrupted transient snapshots rejected from comparisons.
* FSD-AUDIT-005 (High): Canonical normalization contract contradictions resolved.
* FSD-AUDIT-006 (High): Schema v3 explicitly set as implementation baseline.
* FSD-AUDIT-007 (High): Explicit mount consent required; auto-mount contradictions removed.
* FSD-AUDIT-008 (Medium): Collection `last_used_at` behavior converted to an executable trigger.

## Root Integrity Correction
Added explicit trigger constraints to ensure that `snapshots` can only be inserted in a `scanning` state and can only transition to a `complete` status if exactly one corresponding root entry exists. Terminal states (like `complete` and `complete_with_warnings`) are now strictly enforced as immutable via an update trigger, preventing reversion to an incomplete or mutable state.

## Comparison Source and Normalization Correction
The schema now explicitly prevents changes to `left_snapshot_id` and `right_snapshot_id` after a comparison is created, cementing immutability. Normalization-version compatibility constraints remain robust and are fully protected against circumvention because source modification is strictly disallowed.

## Collision Group Model
Created `comparison_collision_groups` and `comparison_collision_members` tables to act as a first-class model for path collisions, replacing the previous unstructured storage of collision results. This completely eliminates arbitrary member pairing and duplicate `uncertain` rows, while preserving the structural facts of all source members and enforcing that they correctly tie back to their parent comparison sides.

## Transient Eligibility Correction
An INSERT trigger on `comparisons` has been introduced to ensure both left and right target snapshots possess a `complete` or `complete_with_warnings` status, preventing `scanning`, `interrupted`, `cancelled`, and `failed` inputs from entering comparisons, enforcing the snapshot completion invariant comprehensively.

## Canonical Normalization Contrac
References to "exact byte representation" and arbitrary "lowercase path" behaviors were eliminated across the documentation matrix. Instead, the contract specifies a robust Unicode text representation, standardizing on the Foundation NFC normalizer algorithm and locale-independent case-folding. The normalization version is standardized to `fsd-algo-v1_app-v1.0_unicode-15.0`.

## Schema Baseline Policy
Migration claims for non-existent applications have been wiped, with schema version 3 now firmly established as the canonical baseline (`schema_migrations` contains only version 3). Outdated v2 references in `MVP_PLAN.md` and related documents have been updated. Previous test planning versions are firmly labeled as discarded.

## Filesystem Scope and Mount Consen
Documented FSKit accurately as an app extension rather than a system extension. "Silent mount" wording has been expunged and a clear "Explicit Mount Consent Policy" added across all relevant documents to firmly guarantee that users must explicitly authorize mounts of unmounted recognizable native systems, resolving the read-only contradiction. The documentation correctly lists 10 variants across 7 families, explicitly noting `mountfs` as reference-only and excluded.

## Collection Last-Used Contrac
Replaced implicit UI expectations with robust database layer logic. Triggers automatically update the `last_used_at` timestamp on a Collection whenever a snapshot is initially assigned or subsequently moved to it, while remaining silent on unrelated changes (e.g. name edits) ensuring consistency.

## Schema Verification Results
A rigorous evaluation utilizing fresh `sqlite3` temporary databases running both the updated `schema.sql` and heavily expanded `verify.sql` was conducted. `PRAGMA integrity_check` returned `ok`, and `PRAGMA foreign_key_check` reported zero violations. All negative test cases failed expectedly, and all intended successes passed cleanly. The manual forbidden state queries returned precisely zero rows.

## Documentation Consistency Results
A comprehensive `regex` sweep over the full Markdown repository confirmed zero remaining instances of "exact byte", "schema version 2", contradictory mount behaviors, or unverified claims concerning 8/9 filesystems. All canonical and planning documents align.

## Remaining Risks
Until actual physical device interaction is established during Phase 0A or 2, parsing edge cases with libfsext on ext2/3/4 partitions may require fallback mitigations or expose parsing differences across raw boundaries.

## Readiness for Independent Re-Audi
The planning and foundational specification tasks for Phase 0A gate entry are fully addressed. All contradictory or non-executable claims have been corrected across the SQL definition and the accompanying canonical documents.

## Final Status
READY FOR INDEPENDENT RE-AUDIT
