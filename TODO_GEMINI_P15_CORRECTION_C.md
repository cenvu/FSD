# TODO_GEMINI_P15_CORRECTION_C.md — Slice C: Final Verification + Canonical Handoff

Prepared by: Tech Lead / Planner (planning-only session)
For: Gemini Writer, Round 2, Slice C of 3 (A → B → C, sequential, separate sessions)
Runs after: `TODO_GEMINI_P15_CORRECTION_A.md` and `TODO_GEMINI_P15_CORRECTION_B.md`
have both completed. Read `handoffs/CURRENT_HANDOFF.md` (Slice B's Handoff)
before starting.

This slice exists specifically because Round 1 collapsed at exactly this
point in an 11-TODO run — the self-check and the final Handoff were the two
steps skipped or severely truncated. This slice does **exactly 2 major
TODOs** and nothing else, to give each one a full attention budget.

**This is a verification and reporting task, not an implementation task.**
No Magika model, dependency, subprocess, or network call is installed or
executed. No production Swift, test, schema, migration, or Xcode project
file changes.

---

## 0. Global rules for this slice

- Files you may modify in this slice: **only** `handoffs/` — one new historical Handoff and the `handoffs/CURRENT_HANDOFF.md` overwrite (TODO C2). TODO C1 modifies nothing.
- Do not edit `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/SECURITY_AND_READ_ONLY_POLICY.md`, `docs/TEST_PLAN.md`, `docs/KNOWN_ISSUES.md`, `docs/MVP_PLAN.md`, or `docs/PRODUCT_STATE.md` in this slice. If TODO C1 finds a genuine defect in one of them, record it as a finding in the Handoff — do not fix it here; that would be starting a new, unplanned correction round.
- Do not modify any `.swift` file, `docs/database/schema.sql`, `docs/database/verify.sql`, or `FSD.xcodeproj/project.pbxproj`.
- Do not delete, rename, or edit `handoffs/FSD_P15MAGIKADESIGN_C_20260807-120000.md` (Round 1's failed artifact), or Slice A's or Slice B's historical Handoffs — all three are preserved evidence.
- Do not download, install, or execute anything. Do not access GitHub or any network resource.
- Do not start, simulate, or reference an independent Auditor/Reviewer role — that happens after this slice, separately, not as part of it.
- Manual test status is always `NOT PERFORMED — DEFERRED BY OWNER`.

## 0.1 Execution discipline

- Read this entire file, and both Slice A's and Slice B's Handoffs, before starting TODO C1.
- Execute TODO C1, then TODO C2, strictly in that order. Do not write the final Handoff before the verification pass is complete.
- Never claim a check was performed if it was not actually performed — re-open the actual file for every checklist line in TODO C1; do not answer from memory of Slice A/B's own Handoff claims.
- Never report a file as modified unless it actually was.
- Do not re-plan or rewrite this TODO file.
- Stop after TODO C2. Do not begin implementation of anything.

## 0.2 Completion semantics

- `COMPLETE` — TODO C1's checklist is fully answered with real evidence and no unresolved contradiction blocks it, and TODO C2's Handoff contains every required field.
- `PARTIAL` — only if TODO C1 surfaces a genuinely load-bearing defect from Slice A or B that this slice cannot fix (per its own scope rules above) — state exactly what it is; do not silently downgrade to `COMPLETE` to avoid saying so.

---

## Read first

- `handoffs/CURRENT_HANDOFF.md` (Slice B's Handoff — the source of truth for what A and B actually did)
- Slice A's and Slice B's historical Handoffs directly (their filenames are recorded in `CURRENT_HANDOFF.md` and in `docs/PRODUCT_STATE.md`'s provenance trail)
- `handoffs/FSD_P15MAGIKADESIGN_C_20260807-120000.md` (Round 1's failed artifact — for comparison only, to confirm this round's corrections actually differ from it)
- `docs/AGENT.md` (exact Handoff filename/format rules, final-report format)
- `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/SECURITY_AND_READ_ONLY_POLICY.md`, `docs/TEST_PLAN.md`, `docs/KNOWN_ISSUES.md`, `docs/MVP_PLAN.md`, `docs/PRODUCT_STATE.md` (the cumulative corrected state — read all of them directly; do not trust Slice A/B's Handoffs as a substitute for reading the actual files)

Do not access GitHub. Do not download anything.

---

## TODO C1 — Whole-slice repository consistency verification (self-check only)

**Objective:** One consolidated, evidence-based self-check across the entire
correction effort (Round 1 + Slice A + Slice B), before writing the final
Handoff. This is not an independent audit and does not involve starting an
Auditor/Reviewer role — it is the Writer confirming its own and the prior
slices' work against the actual repository, the exact step Round 1 skipped
entirely.

**Files that may be inspected:** every file touched by Round 1, Slice A, or
Slice B (Handoffs list them by name) — re-open each one.

**Files that may be modified:** none.

**Exact checklist to confirm, each as an explicit yes/no with the specific file(s) named:**

- no production `.swift` file was modified across Round 1, Slice A, or Slice B (list every `.swift` file with a modification time after Round 1 started — must be empty);
- no file under `FSDTests/` was modified (must be empty);
- no schema/migration file was modified (`docs/database/schema.sql`, `docs/database/verify.sql`, any `CatalogMigrations*.swift` — must be empty);
- `FSD.xcodeproj/project.pbxproj` was not modified;
- no dependency, package reference, or model file was downloaded or added;
- no GitHub access occurred;
- no Magika runtime, Python process, or subprocess classifier was executed;
- no source-volume payload was read by any Writer session in this correction effort;
- `docs/ARCHITECTURE.md` §9a contains: a completed four-shape packaging comparison with a decision that follows it, not predetermined; at least one `EXTERNAL VERIFICATION REQUIRED` label; the 6-stage bounded-byte pipeline stated verbatim; the "no production protocol change is implemented" sentence; a cancellation paragraph that cites its evidence before its conclusion; six (not five) outcomes; a UI Contract subsection;
- `docs/DECISIONS.md` ADR-032 reflects the same corrected packaging and schema content as `ARCHITECTURE.md` (no drift between the two files);
- `docs/SECURITY_AND_READ_ONLY_POLICY.md` §2.1 contains the word "telemetry" and explicit zero-network/no-backfill/no-watcher sentences;
- `docs/TEST_PLAN.md` §9 contains all 30 items from Slice A's/B's list plus the distinct adversarial-provider-test entry naming all three required proofs;
- `docs/KNOWN_ISSUES.md` KI-024's heading no longer contains the word "pending";
- `docs/MVP_PLAN.md` and `docs/PRODUCT_STATE.md` no longer contain the two specific contradictions named in Slice B;
- `handoffs/FSD_P15MAGIKADESIGN_C_20260807-120000.md` (Round 1's failed artifact) is untouched and still present;
- Slice A's and Slice B's historical Handoffs are untouched and still present;
- the metadata-only default (all 8 workflows) is stated identically in `ARCHITECTURE.md` §9a and `docs/TEST_PLAN.md` §9 — word-for-word, not paraphrased differently in each place;
- snapshot-immutability language (Section C's non-implication rule) is present and unchanged in intent since Slice A;
- comparison isolation and JSON export v1 stability are both restated as unchanged somewhere in the corrected documentation;
- the byte ceiling and packaging-shape numbers are identical everywhere they are mentioned across `ARCHITECTURE.md`, `DECISIONS.md`, and `TEST_PLAN.md` (no drift between slices).

**Invariants:** this is a Writer self-check; it must not spawn, simulate, or claim any independent Auditor/Reviewer role.

**Do NOT:** re-run any XCTest suite or build (irrelevant — no test/build files were touched by this correction effort); claim any checklist line passed without actually re-opening the relevant file to confirm it; silently repair a discovered defect (record it for the Handoff instead — repairing here would be starting an unplanned new correction slice).

**Local completion check:** every checklist line above has an explicit yes/no with the specific file(s)/line(s) named next to it. Any "no" is carried forward into TODO C2's Handoff as an explicit open item, not silently dropped.

---

## TODO C2 — Repair and write the canonical final Handoff

**Objective:** Produce the one canonical Handoff for the entire
`FSD-P15-MAGIKA-RUNTIME-DESIGN-0807-20` task — correcting every specific
format and content defect the independent audit found in Round 1's attempt
at this exact step.

**Files that may be inspected:** `docs/AGENT.md` (exact Handoff
filename/format rules, final-report format); TODO C1's completed checklist.

**Files that may be created/modified:**

- create exactly one new file: `handoffs/FSD_P15_MAGIKA_RUNTIME_DESIGN_A_<YYYYMMDD-HHMMSS>.md` — this exact filename, matching the pattern the original task required and Round 1 got wrong (Round 1 used `FSD_P15MAGIKADESIGN_C_20260807-120000.md` — garbled case code, wrong role code `C` instead of `A`, and a fabricated round-number placeholder timestamp `12:00:00`). **Obtain the timestamp for both the filename and the `UPDATED_AT:` line from an actual system clock read at the moment of writing — do not invent, round, or reuse any previous timestamp.** The filename's embedded timestamp and the file's actual filesystem modification time must be consistent with each other (within normal write-latency, i.e., seconds, not hours).
- overwrite `handoffs/CURRENT_HANDOFF.md`: line 1 exactly `UPDATED_AT: <the same real timestamp>`, one blank line, then the complete contents of the new historical Handoff (full copy, not a pointer, and not the file's own title line substituting for the required `UPDATED_AT:` line — this exact defect broke Round 1's `CURRENT_HANDOFF.md`).
- do not modify, rename, or delete any other file under `handoffs/`.

**Exact content required in the Handoff — all 16 fields, each as its own
named section, not folded together (Round 1's Handoff had 8 of these 16
fields; that is the specific defect this TODO exists to fix):**

1. status: `COMPLETE` or `PARTIAL`, per §0.2, reflecting TODO C1's actual findings — not automatically `COMPLETE` if C1 recorded any "no";
2. runtime packaging decision — summarize Slice A's four-shape comparison outcome and cite where the full comparison lives (`ARCHITECTURE.md` §9a, `DECISIONS.md` ADR-032);
3. byte-access contract — the ceiling, range count, concurrency, accounting definition, small/large-file behavior;
4. invocation policy — explicit-only, single-selected-entry, all 8 named workflows that never trigger it;
5. source-identity policy — re-resolution, regular-file-only gate, symlink/directory prohibition, source-changed/unavailable split, the non-implication rule;
6. adapter API decision — no-`URL`/`Data`-only request shape, the "no production protocol change is implemented" statement, the three previously-missing result cases now named;
7. schema/provenance decision — the literal verdict token from Slice A's re-check, with its reasoning;
8. cancellation/resource limits — all seven lifecycle items from Slice A (including the `generation`/`invalidate()` citation), every number still labeled `PROPOSED`;
9. persistence policy — the full six-outcome table (row-or-no-row, columns populated);
10. UI contract — the inferred-only/neutral-absence/no-fabricated-confidence/no-raw-diagnostics rules, citing that they follow the existing `SnapshotBrowserView.swift` pattern;
11. testing strategy — summarize the 30-item `TEST_PLAN.md` §9 list and the adversarial-provider-test entry by name (don't reproduce all 30 verbatim in the Handoff — cite the section);
12. external verification requirements — collect every fact labeled `EXTERNAL VERIFICATION REQUIRED` across `ARCHITECTURE.md`/`DECISIONS.md` into one list here;
13. exact documents changed — the complete file list across Round 1 (for context, marked as superseded/corrected, not re-claimed as this slice's own work), Slice A, Slice B, and this slice;
14. manual test state: `NOT PERFORMED — DEFERRED BY OWNER`;
15. execution ledger — Slice A (TODO A1–A5), Slice B (TODO B1–B4), and this slice (TODO C1–C2), each marked `DONE`, `BLOCKED`, or `NOT REQUIRED` — no percentage-complete estimates;
16. exactly one next action.

**When status is `COMPLETE`, the next action must read exactly:**

> Implement the approved bounded-byte Magika runtime adapter as one isolated Writer slice.

**Do not add a second next action.** If status is `PARTIAL`, state the exact
unresolved item instead, and do not use the `COMPLETE` next-action sentence.

**Invariants:** every historical Handoff already in `handoffs/` — including
Round 1's failed artifact and Slice A's and Slice B's Handoffs — is
untouched; `CURRENT_HANDOFF.md` is a full copy, never a pointer; the final
chat response for this slice ends with the 10 required summary lines
followed by line 11 exactly `NEW HANDOFF!!!`, per `docs/AGENT.md`.

**Do NOT:** invent or round the timestamp; start an independent
Auditor/Reviewer; add a second "next action"; claim manual testing occurred;
claim any of the 16 fields is present without it actually being present in
the file you write.

**Local completion check:** both files exist; the filename matches
`handoffs/FSD_P15_MAGIKA_RUNTIME_DESIGN_A_<YYYYMMDD-HHMMSS>.md` exactly;
`CURRENT_HANDOFF.md` begins with `UPDATED_AT:`, a blank line, then the
historical Handoff's exact content; the embedded timestamp and the file's
actual mtime agree to within seconds; all 16 numbered fields above are
each present as their own identifiable section; the execution ledger lists
all 11 TODOs across Slices A/B/C; the final response's line 11 is exactly
`NEW HANDOFF!!!`.

---

*End of Slice C. 2 major TODOs (C1–C2). This is the last slice of the
correction effort — stop after TODO C2.*
