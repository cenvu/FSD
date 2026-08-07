# Handoff: FSD Plan Gate Correction 2 (Forge)

## Objective
Correct all outstanding Phase 0A Plan Gate blockers identified during the independent re-audit, strictly following the rules for FSD (no source volume writes, no production app source yet, no Git, no MCP CodeGraph).

## Repository State
- No production Swift/Objective-C/C/C++ or Xcode project source exists.
- The Git repository has not been initialized.
- The SQLite catalog schema (v3) has been updated and tested using command-line scripts.
- The single-file handoff policy is fully enacted. The legacy separated report file (`docs/FSD_PLAN_GATE_REAUDIT_GPT56SOL.md`) has been merged into its corresponding handoff file, and all future sessions are instructed to produce exactly one Markdown handoff.

## Files Changed
- **`docs/database/schema.sql`**: Added `trg_comparison_results_no_collision_pairs` and `trg_comparison_results_no_collision_pairs_update` to prevent arbitrary pairing of collision members. Modified snapshot status constraint to ensure snapshots require `scanning` status at initialization, and added `normalization_version` to the snapshots schema.
- **`docs/database/verify.sql`**: Added negative test fixtures to verify collision-member pairing rejection.
- **`docs/FILESYSTEM_PROVIDER_ARCHITECTURE.md`**: Fixed filesystem cardinality statements (10 variants, 7 native-readable). Removed contradictory "Explicit Mount Consent Policy" block since the normative policy already resides in `SECURITY_AND_READ_ONLY_POLICY.md`.
- **`docs/TEST_PLAN.md`**: Fixed filesystem cardinality logic and removed the duplicate Explicit Mount Consent Policy block.
- **`docs/MVP_PLAN.md`**: Fixed filesystem cardinality wording and removed duplicate Explicit Mount Consent Policy block.
- **`docs/PRODUCT_STATE.md`**: Fixed filesystem cardinality wording (7 native-readable variants).
- **`docs/PRD.md`**: Removed duplicate Explicit Mount Consent Policy block.
- **`docs/DECISIONS.md`**: Updated ADR-013 to reference the new `.sha256` checksum removal, update the handoff layout, and rename the legacy folder reference to `AI_HANDOFFS/`.
- **`docs/AGENT.md` & `docs/PROJECT_SUPPORT/HANDOFFS.md` & `docs/README.md`**: Documented the "Mandatory Single-File Handoff Policy" (no separate session report files).
- **`docs/PROJECT_MANIFEST.md` & `docs/DEPENDENCY_AND_LICENSE_REVIEW.md`**: Fixed "a app extension" grammar error and the System Extension contradiction for FSKit.
- **`docs/FSD_PLAN_GATE_CORRECTION_GEMINI31.md`**: Stripped trailing whitespace as requested.
- **`handoffs/FSD_PLAN_GATE_REAUDIT_A_20260724-232243.md`**: Merged the contents of `docs/FSD_PLAN_GATE_REAUDIT_GPT56SOL.md` into this file to abide by the single-file handoff rule for historical parity.

## Decisions Made
- Collision group member pairing logic has been fortified at the schema level using SQLite triggers. Any `comparison_results` insert or update involving an `entry_id` currently within a collision group will now fail if attempted as `matched`, `changed`, `added`, or `removed`.
- The single-file handoff policy is now the standard for FSD; reports and handoffs must merge into one Markdown document.
- Filesystem cardinality logic is now precisely standard as "10 variants across 7 filesystem families" (7 natively readable, 3 embedded raw readers).

## Tests Run
- `sqlite3 /tmp/fsd_test.db < docs/database/schema.sql` (Passed)
- `sqlite3 /tmp/fsd_test.db < docs/database/verify.sql` (Passed, properly raised all expected runtime errors for new negative test cases including arbitrary pairing).
- `grep -rlnE "[ \t]+$" docs --include="*.md"` (Clean)
- `grep -rlnE "^(<<<<<<<|=======|>>>>>>>)" docs --include="*.md"` (Clean)

## Unresolved Risks
- None at this time. All blockers cited in the re-audit have been thoroughly addressed in documentation and schema verification.

## Exact Next Action
- READY FOR INDEPENDENT RE-AUDIT. Proceed to a fresh audit of these corrections.
