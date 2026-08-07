# TODO_GEMINI_P15_CORRECTION_B.md — Slice B: Tests + Documentation Housekeeping

Prepared by: Tech Lead / Planner (planning-only session)
For: Gemini Writer, Round 2, Slice B of 3 (A → B → C, sequential, separate sessions)
Runs after: `TODO_GEMINI_P15_CORRECTION_A.md` has completed and written its own
Handoff. Read that Handoff (via `handoffs/CURRENT_HANDOFF.md`, which Slice A's
last TODO overwrote) before starting — Slice A may have changed specific
numbers (byte ceiling, packaging shape, schema verdict) from what Round 1
originally guessed, and this slice must transcribe the **current, corrected**
values, not Round 1's.

This slice does **4 TODOs**.

**This is a documentation/test-design task, not an implementation task.** No
tests are implemented. No production Swift, schema, migration, or Xcode
project file changes.

---

## 0. Global rules for this slice

- Files you may modify in this slice: `docs/TEST_PLAN.md`, `docs/KNOWN_ISSUES.md` (KI-024 heading only), `docs/MVP_PLAN.md`, `docs/PRODUCT_STATE.md`, plus one new historical Handoff under `handoffs/` and an overwrite of `handoffs/CURRENT_HANDOFF.md` (TODO B4 only).
- Do not touch `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, or `docs/SECURITY_AND_READ_ONLY_POLICY.md` — Slice A already corrected those. If you find a genuine inconsistency between those files and what you're transcribing here, record it in this slice's Handoff as a flag for Slice C rather than editing those files yourself.
- Do not create the final canonical design Handoff (`handoffs/FSD_P15_MAGIKA_RUNTIME_DESIGN_A_<timestamp>.md`) — that is Slice C's exclusive work.
- Do not modify any `.swift` file, `docs/database/schema.sql`, `docs/database/verify.sql`, or `FSD.xcodeproj/project.pbxproj`.
- Do not delete, rename, or edit `handoffs/FSD_P15MAGIKADESIGN_C_20260807-120000.md` (Round 1's failed artifact) or Slice A's historical Handoff — both are preserved evidence.
- Do not download, install, or execute anything. Do not access GitHub or any network resource. No tests in this slice are implemented — you are writing a description of future tests, not code.
- Do not fix the separately tracked legacy startup-error wording issue. Do not delete `.gemini-derived-data`.
- Manual test status is always `NOT PERFORMED — DEFERRED BY OWNER`.

## 0.1 Execution discipline

- Read this entire file, and Slice A's Handoff, before editing anything.
- Execute TODOs B1 → B4 strictly in order.
- Do not re-plan or rewrite this TODO file.
- Do not silently skip a requirement; record any blocker explicitly.
- Never claim a file was modified unless it actually was.
- Stop after TODO B4. Do not begin Slice C's work. Do not implement anything.

## 0.2 Completion semantics

- `COMPLETE` — every one of TODO B1–B4's local completion checks passes.
- `PARTIAL` — only if a genuinely load-bearing item remains unresolved (e.g., Slice A's Handoff is missing a value this slice needs to transcribe).

---

## Read first

- `handoffs/CURRENT_HANDOFF.md` (Slice A's just-completed Handoff — the source of truth for current byte ceiling, packaging shape, outcome/schema decisions)
- `docs/ARCHITECTURE.md` §9a (as corrected by Slice A)
- `docs/TEST_PLAN.md` §9 (the existing, currently thin future-test section you are expanding — read it fully before editing)
- `docs/KNOWN_ISSUES.md` KI-024 (currently reads "... FIXED 2026-08-05; focused independent re-audit pending" — this is the stale text you are correcting)
- `handoffs/FSD_M5_SCHEMA_V8_DISPOSAL_REAUDIT_A_20260805-223211.md` (the closing re-audit Handoff — cite its filename, verdict, and date when fixing KI-024)
- `docs/MVP_PLAN.md` (top status paragraph — currently self-contradictory, see TODO B4)
- `docs/PRODUCT_STATE.md` (top provenance lines — currently skips a Handoff in its own chronology, see TODO B4)

Do not access GitHub. Do not download anything.

---

## TODO B1 — Complete the future TEST_PLAN.md expansion

**Objective:** Replace the current 8-bullet `docs/TEST_PLAN.md` §9 with a complete future-test list covering every item the independent audit found missing, using the byte ceiling, packaging shape, and outcome/schema decisions **as corrected by Slice A** (read them from `handoffs/CURRENT_HANDOFF.md`, not from Round 1's original numbers).

**Files that may be inspected:** `docs/TEST_PLAN.md` (existing §9 and its surrounding structure, to match the file's existing test-entry style); `handoffs/CURRENT_HANDOFF.md` (Slice A's corrected values).

**Files that may be modified:** `docs/TEST_PLAN.md` (§9 only — do not touch any other section of this file).

**Exact output required.** §9 must, after your edit, name a distinct future test (one line or short bullet each, no implementation) for every item below. Do not implement any test — this is a description of what a future test must verify, exactly like the current §9 already does for its 8 items:

- exact byte ceiling enforcement (using Slice A's corrected number);
- exact byte boundary (a file of exactly the ceiling size vs. one byte over);
- small file (below the ceiling);
- oversized file (above the ceiling);
- missing source at classification time;
- source that disappears mid-read;
- source that has changed identity since capture;
- wrong/mismatched source identity;
- inaccessible source (permission denied);
- directory entry rejection;
- symlink entry rejection;
- special-file entry rejection;
- cancellation before the read begins;
- cancellation during the read;
- cancellation before inference;
- cancellation during inference;
- provider failure/crash;
- provider timeout;
- successful classification persists correctly;
- cancellation cannot create a successful row (name this as its own distinct test, not folded into the general cancellation tests);
- no payload persistence;
- no byte-sample persistence;
- no content-hash persistence;
- no absolute-source-path persistence;
- no snapshot mutation (`entries`/`snapshots` unchanged by a classification write);
- comparison isolation (divergent classification metadata does not change comparison outcomes — this pattern already has a real, passing precedent: `ComparisonSemanticsTests.testClassificationMetadataCannotChangeComparisonOutcome` in `FSDTests/ComparisonSemanticsTests.swift` — cite it as the existing analogous test the future test should extend, don't just assert isolation abstractly);
- JSON export stability (export excludes classification, unchanged format version);
- zero network activity during classification;
- no automatic invocation (list the 8 workflows by name, matching `ARCHITECTURE.md` §9a's list exactly, word for word);
- offline history/snapshot usability (classification of a detached-source entry behaves per the `.source-changed`/`.unavailable` rule from Slice A, not by crashing or hanging);
- schema/`ExpectedState` safety if a schema change is eventually implemented (only relevant if Slice A's schema verdict was `SCHEMA CHANGE REQUIRED BEFORE RUNTIME` — if so, name this test; if Slice A concluded `SCHEMA V8 SUFFICIENT`, state that this item is not applicable and say why).

**Invariants:** no test is implemented; every listed item traces to a specific requirement from the corrected design, not a generic restatement.

**Do NOT:** implement any test code; invent requirements beyond this list; contradict Slice A's corrected numbers.

**Local completion check:** §9 contains a distinct, separately identifiable line for every bullet above (count them — there are 30), and the "no automatic invocation" line lists all 8 workflows by name.

---

## TODO B2 — Design the mandatory adversarial provider test

**Objective:** Add the one test category the independent audit found completely absent from Round 1: proof that a provider cannot escape FSD's bounded-byte authority.

**Files that may be inspected:** `docs/ARCHITECTURE.md` §9a (the provider API boundary and byte-ceiling enforcement point, as corrected by Slice A); `FSDTests/ClassificationEnrichmentTests.swift` (the existing `HostileDiagnosticProvider` test fixture pattern — a hostile/adversarial fake provider already exists in this codebase for the current nullable-enrichment boundary; the future adversarial test should follow the same *pattern*, not literally reuse today's fixture, since today's provider protocol takes no bytes at all).

**Files that may be modified:** `docs/TEST_PLAN.md` (append this as its own clearly labeled entry within §9, immediately after the items from TODO B1 — do not fold it into a generic bullet).

**Exact output required.** Describe one future test, named explicitly as the adversarial provider test, that proves all three of the following using a fake/hostile provider implementation (description only, no code):

1. the provider cannot reopen or otherwise access the original source path — it only ever receives the bounded `Data` buffer FSD already read, never a `URL`/path/handle;
2. the provider cannot request or receive additional bytes beyond what FSD already handed it — there is no callback or second read path available to it;
3. the provider cannot bypass FSD's hard byte ceiling — even if the fake provider's `classify` implementation tries to claim it read more, FSD's own persisted result only ever reflects what FSD itself bounded and read, never anything the provider asserts about additional bytes.

State explicitly that this test's fake provider should attempt all three violations deliberately (analogous to `FSDTests/ClassificationEnrichmentTests.swift`'s existing `HostileDiagnosticProvider`, which deliberately throws a hostile diagnostic string to prove it doesn't leak into stored/visible state) and that the test passes only if all three attempts fail to have any effect.

**Invariants:** no test is implemented in this slice.

**Do NOT:** implement the test; design a provider protocol change (that remains out of scope, per Slice A's "no production protocol change" statement).

**Local completion check:** `docs/TEST_PLAN.md` contains one clearly labeled adversarial-provider-test entry naming all three required proofs, distinct from the general test list added in TODO B1.

---

## TODO B3 — Correct the stale KI-024 wording

**Objective:** Fix the exact pre-existing documentation-accuracy defect the original design task and the independent audit both flagged, and which Round 1 silently skipped entirely.

**Files that may be inspected:** `docs/KNOWN_ISSUES.md` (KI-024 full text); `handoffs/FSD_M5_SCHEMA_V8_DISPOSAL_REAUDIT_A_20260805-223211.md` (verdict line only — cite its filename, verdict `APPROVE WITH CONDITIONS`, and date).

**Files that may be modified:** `docs/KNOWN_ISSUES.md` — specifically the KI-024 heading line and, if needed, one closing sentence.

**Exact change required:** change the heading away from "... FIXED 2026-08-05; focused independent re-audit pending" to state plainly that the re-audit is closed, naming the closing Handoff filename, its verdict, and its date.

**Invariants:** KI-024's underlying technical description (the O(n²) root cause, the dedicated-index fix, the 1,000,000-row timing evidence) is factual history — do not alter, shorten, or remove it. Only the stale status wording changes.

**Do NOT:** renumber KI-024; touch KI-025 or any other KI entry; fix the separately tracked startup-error wording issue; delete `.gemini-derived-data`.

**Local completion check:** `docs/KNOWN_ISSUES.md` KI-024's heading no longer contains the word "pending" and instead names the specific closing Handoff and verdict. This is a direct, checkable fact — `grep -c pending` against the KI-024 heading line must return `0` after your edit.

---

## TODO B4 — Repair MVP_PLAN.md / PRODUCT_STATE.md consistency, and write Slice B's Handoff

**Objective:** Fix the two concrete cross-file contradictions Round 1 introduced without repairing, then close out this slice with its own Handoff.

**Files that may be inspected:** `docs/MVP_PLAN.md` (top status paragraph); `docs/PRODUCT_STATE.md` (top provenance lines); `docs/AGENT.md` (Handoff filename/format rules).

**Files that may be modified:** `docs/MVP_PLAN.md` (the status paragraph only), `docs/PRODUCT_STATE.md` (the top provenance lines only), plus one new historical Handoff and the `handoffs/CURRENT_HANDOFF.md` overwrite.

**Exact defects to repair, without rewriting historical facts:**

1. `docs/MVP_PLAN.md`'s status paragraph currently states, in the same paragraph, both "Phase 1.5 Magika runtime adapter design is complete; implementation is pending" (Round 1's addition) and "Phase 1.5 nullable enrichment preparation is implemented and awaits one focused independent boundary audit" (older text) — but that audit already closed with `APPROVE WITH CONDITIONS` (`handoffs/FSD_P15_MAGIKA_NULLABLE_ENRICHMENT_AUDIT_R_20260807-142313.md`) before Round 1 even started. Correct the "awaits ... audit" clause to reflect that the audit is closed, citing that Handoff by name — do not delete the sentence's other factual content (the KI-024/disposal details that follow it remain accurate and must stay).
2. `docs/PRODUCT_STATE.md`'s "Prior entry" chronology currently jumps from the Round 1 design Handoff straight to the 2026-08-06 nullable-enrichment Handoff, skipping the 2026-08-07 nullable-enrichment **audit** Handoff (`FSD_P15_MAGIKA_NULLABLE_ENRICHMENT_AUDIT_R_20260807-142313.md`) that sits chronologically between them. Add it as its own "Prior entry" line in the correct chronological position.
3. Update `docs/PRODUCT_STATE.md`'s "Current Handoff" line to reference whatever this slice's own Handoff will be named (see below) — do not point it at Round 1's failed filename or at Slice A's filename once this slice's own Handoff supersedes it as current.

**Invariants:** no historical fact is deleted or reworded — only the stale/incomplete cross-references are corrected. The KI-024/disposal timing details in `MVP_PLAN.md` remain untouched (that's factual Milestone 5 history, not part of this defect).

**Do NOT:** rewrite Milestone 5 history; touch any section of either file beyond the specific lines named above; claim a fact you did not verify by reading the cited Handoff.

**Write the Handoff:**

4. Write one historical Handoff: `handoffs/FSD_P15_MAGIKA_RUNTIME_CORRECTION_B_C_<YYYYMMDD-HHMMSS>.md` (role code `C`). Use a real timestamp obtained from the environment.
5. Overwrite `handoffs/CURRENT_HANDOFF.md`: line 1 exactly `UPDATED_AT: <real timestamp>`, one blank line, then the complete contents of this slice's historical Handoff.
6. The Handoff must state: what TEST_PLAN.md now covers (reference the 30-item list and the adversarial test by name, don't reproduce them verbatim), the exact KI-024 fix made, the exact MVP_PLAN.md/PRODUCT_STATE.md corrections made, the exact files changed, and status `COMPLETE` or `PARTIAL`. Next action: "Proceed to `TODO_GEMINI_P15_CORRECTION_C.md` in a new session."

**Invariants:** historical Handoffs already in `handoffs/` (including Round 1's failed artifact and Slice A's Handoff) are untouched.

**Do NOT:** create the final canonical design Handoff here; start Slice C's work.

**Local completion check:** both cited contradictions no longer exist in their respective files (each traceable to the exact sentence changed); both new Handoff files exist with the correct `UPDATED_AT:`-first format; the Handoff names the next action as proceeding to Slice C.

---

*End of Slice B. 4 TODOs (B1–B4). Stop here — do not begin Slice C.*
