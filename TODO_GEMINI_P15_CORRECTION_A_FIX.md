# TODO_GEMINI_P15_CORRECTION_A_FIX.md — Micro-Slice: Schema/Provenance Verdict Only

Prepared by: Tech Lead / Planner (planning-only session)
For: Gemini Writer, Round 2A-FIX (one-TODO micro-slice)
Corrects: the single HIGH finding from the independent Slice A audit —
`SCHEMA V8 SUFFICIENT — UNSUPPORTED` (Audit A5, Round 2A). Runs after
`TODO_GEMINI_P15_CORRECTION_A.md` and before `TODO_GEMINI_P15_CORRECTION_B.md`.

This file contains **exactly one major TODO**. This is intentional: Round 1
(11 TODOs) collapsed at its tail; Slice A (5 TODOs) succeeded on every
dimension except one specific technical conclusion. This micro-slice tests
whether Gemini can correct one precisely-bounded technical error without
touching anything else — including the four other things Slice A got right.

**This is a documentation correction only.** No schema migration, no schema
version 9, no production Swift, test, or Xcode project change. No Magika
model, dependency, subprocess, or network call.

---

## 0. Global rules for this micro-slice

- Files you may modify: **only** `docs/ARCHITECTURE.md` (the schema/provenance portion of §9a — specifically the "Outcomes and Schema Impact" subsection's Schema Verdict paragraph, currently its last two lines), **only** `docs/DECISIONS.md` (the schema/provenance portion of ADR-032 — currently its closing paragraph, "A schema change is required before implementation..." — note: as of Slice A this paragraph may already have been rewritten to match the "sufficient" verdict; correct whatever it currently says to match your new verdict), plus one new historical Handoff and the `handoffs/CURRENT_HANDOFF.md` overwrite.
- Do not touch any other part of `ARCHITECTURE.md` §9a: not the packaging comparison, not the Source Resolution and Identity subsection, not the Bounded Byte Contract subsection, not the Lifecycle and Cancellation subsection (including its cancellation-persistence paragraph), not the UI Contract subsection. All of those were independently audited and passed in Round 2A — leave them exactly as they are.
- Do not touch `docs/SECURITY_AND_READ_ONLY_POLICY.md`, `docs/TEST_PLAN.md`, `docs/KNOWN_ISSUES.md`, `docs/MVP_PLAN.md`, or `docs/PRODUCT_STATE.md`.
- Do not touch `TODO_GEMINI_P15_CORRECTION_B.md` or `TODO_GEMINI_P15_CORRECTION_C.md`.
- Do not modify any `.swift` file, `docs/database/schema.sql`, `docs/database/verify.sql`, or `FSD.xcodeproj/project.pbxproj`. No schema version 9. No migration code, described or written.
- Do not delete, rename, or edit `handoffs/FSD_P15MAGIKADESIGN_C_20260807-120000.md` (Round 1's failed artifact) or Slice A's historical Handoff (`handoffs/FSD_P15_MAGIKA_RUNTIME_CORRECTION_A_C_20260807-151218.md`) — both are preserved benchmark evidence.
- Do not download, install, or execute anything. Do not access GitHub.
- Do not start, simulate, or reference an independent Auditor/Reviewer role — that happens after this micro-slice finishes, separately.
- Manual test status is always `NOT PERFORMED — DEFERRED BY OWNER`.

## 0.1 Execution discipline

- Read this entire file, plus the independent Slice A audit's Audit A5 section (reproduced in "The finding to correct," below), before editing anything.
- This file has exactly one major TODO. Do not split it into sub-sessions, do not add TODOs, do not re-plan.
- Do not broaden scope: do not revisit packaging, byte limits, cancellation, UI, security, or tests, even if you notice something you'd want to change — that is explicitly out of bounds for this micro-slice.
- Do not implement the eventual schema change even if your verdict is `SCHEMA CHANGE REQUIRED BEFORE RUNTIME` — name the field and reasoning only.
- Never claim a check occurred if it did not. Never report a file as modified unless it actually was.
- Stop after the TODO's Handoff step. Do not begin Slice B's work.

## 0.2 Completion semantics

- `COMPLETE` — a verdict is issued, it is reached from repository semantics (not storage capacity alone), it is consistent between both edited files, and nothing outside the allowed scope changed.
- `PARTIAL` — only if a genuinely load-bearing question from the five below cannot be answered from repository evidence.

---

## The finding to correct

Independent Slice A audit, Audit A5 (verbatim): Gemini's Slice A design
concluded `SCHEMA V8 SUFFICIENT`, reasoning that "`detector_version` and
`model_version` are TEXT(256) columns; provider identity can be fully
recorded by including the adapter identifier in the `detector_version`
string (e.g., `magika-helper-1.0.0`)." The audit found this **UNSUPPORTED**:
it is a storage-capacity argument ("a string fits in a TEXT column"), not a
semantic-provenance argument. `detector_version`/`model_version` are
pre-existing, deliberately scoped fields (`ADR-031`, `EntryClassificationRepository.swift`'s
own docstring) meaning "which detection algorithm/model version was used" —
not "which adapter/process produced this row." Provider/adapter identity is
an orthogonal fact: the same detector version can run under different
packaging shapes (Slice A's own four-way comparison established this), and
the same packaging shape can run different detector versions over time.
`docs/KNOWN_ISSUES.md` KI-025 already documents this exact gap as
pre-existing and open ("the adapter identifier remains runtime-only until a
separately approved schema decision") — Slice A's verdict did not cite or
reconcile with this prior, directly contradictory framing.

---

## Read first

- `docs/ARCHITECTURE.md` — the current "Outcomes and Schema Impact" subsection of §9a (its Schema Verdict paragraph is what you are correcting)
- `docs/DECISIONS.md` — ADR-032's current closing schema paragraph (what you are correcting)
- `docs/DECISIONS.md` — ADR-031 ("Nullable classification enrichment boundary uses schema version 8") in full
- `docs/KNOWN_ISSUES.md` — KI-025 in full
- `docs/database/schema.sql` — the exact current `entry_classifications` column list
- `FSD/Catalog/EntryClassificationRepository.swift` — the `ClassificationDetectionStatus` enum, the doc-comment on `EntryClassificationInput` describing detector/model versions as "the persisted provenance fields" with "the adapter identifier remains runtime-only," and `append`'s column list

Do not access GitHub. Do not download anything. Do not inspect external Magika documentation — this correction is about FSD's own schema semantics, not about Magika.

---

## TODO 1 — Re-derive the schema/provenance verdict from semantics, not storage capacity

**Objective:** Replace the unsupported `SCHEMA V8 SUFFICIENT` conclusion in both `ARCHITECTURE.md` and `DECISIONS.md` with a verdict that follows from what `detector_version`, `model_version`, and provider/adapter identity actually mean in this codebase — not from whether a string physically fits in a TEXT column.

**Files that may be inspected:** everything in "Read first" above.

**Files that may be modified:** `docs/ARCHITECTURE.md` (Schema Verdict paragraph of the "Outcomes and Schema Impact" subsection of §9a only), `docs/DECISIONS.md` (ADR-032's closing schema paragraph only), plus this micro-slice's Handoff (see final step below).

**Exact output required — answer all five questions explicitly, in this order, before stating the verdict:**

1. What does `detector_version` identify? (Answer from `EntryClassificationRepository.swift`'s own doc-comment and ADR-031 — quote or closely paraphrase the actual text, don't restate it from memory.)
2. What does `model_version` identify? (Same sourcing requirement.)
3. What independent fact does provider/adapter identity represent, and how is it different from both of the above? (State the concrete scenario that makes this a real, distinct dimension — e.g., the same detector/model version being classifiable through more than one packaging shape over the adapter's lifetime, per Slice A's own packaging comparison, which you must not otherwise reopen.)
4. Why must those three facts remain separately, durably recoverable rather than merged into one field? (Ground this in a concrete query/audit scenario: a future reader needs to answer "which detector version produced this row" and "which adapter produced this row" as two independent questions, without depending on an undocumented, unenforced string convention to disentangle them.)
5. Can schema v8 — as it actually exists today, not as a hypothetical encoding convention — represent all three facts without semantic overloading? Answer this using the real column list you read from `schema.sql`, not a proposed workaround.

**Then issue exactly one final verdict token:**

- `SCHEMA V8 SUFFICIENT`, or
- `SCHEMA CHANGE REQUIRED BEFORE RUNTIME`

The verdict must follow from your answers to questions 1–5, not be chosen first and rationalized afterward. Do not treat `provider_identifier` as the predetermined answer merely because Round 1 used that name — if your evidence review leads to a different minimal field name, or to a different structural solution consistent with "no schema v9, no migration written," use that instead. If your evidence review genuinely supports `SCHEMA V8 SUFFICIENT` after correctly separating storage-capacity from semantics, that is an acceptable outcome too — but only if you can show, specifically, why the semantic-overloading concern in this finding does not actually hold (not by re-asserting the storage-capacity point that was already rejected).

**If `SCHEMA CHANGE REQUIRED BEFORE RUNTIME`:**

- Do not create schema version 9.
- Do not write or describe migration code.
- Specify exactly one minimal missing field, name it, and state its intended semantics in one sentence (what question it answers, distinct from `detector_version` and `model_version`).
- Explain explicitly why `detector_version` must not be overloaded to carry this fact instead — tie this back to your answer to question 4.

**If `SCHEMA V8 SUFFICIENT`:** state explicitly, in the text, why the semantic-overloading objection from the audit finding does not hold — do not simply omit or ignore the objection.

**Consistency check (part of this same TODO, do not treat as separate):** after editing, confirm and state that:

- `ARCHITECTURE.md` and `DECISIONS.md` now state the identical verdict token and the identical reasoning for it (not just a matching token with diverging justification);
- no other part of Slice A's design changed — re-open the packaging, byte-contract, cancellation, and UI Contract subsections of §9a and confirm their text is byte-for-byte what it was before this edit;
- no `.swift`, schema, migration, or Xcode project file changed;
- this correction does not claim any schema migration was implemented — the runtime and the schema both remain exactly as unimplemented as before;
- `CatalogMigrations.currentVersion` is not mentioned as changing anywhere in your edit.

**Write the Handoff (final step of this same TODO):**

- Write one historical Handoff per `docs/AGENT.md`'s normal convention: `handoffs/FSD_P15_MAGIKA_RUNTIME_CORRECTION_A_FIX_C_<YYYYMMDD-HHMMSS>.md` (role code `C`). Obtain the timestamp from an actual system clock read at the moment of writing — never a fabricated or rounded placeholder; the embedded timestamp and the file's actual modification time must agree within seconds.
- Overwrite `handoffs/CURRENT_HANDOFF.md`: line 1 exactly `UPDATED_AT: <real timestamp>`, one blank line, then the complete contents of the new historical Handoff (full copy, not a pointer).
- The Handoff must state explicitly: that this is a correction to Slice A (name it); the exact HIGH audit finding being corrected (quote the `SCHEMA V8 SUFFICIENT — UNSUPPORTED` verdict); the final schema/provenance verdict this TODO reached, with its one-sentence reasoning; the exact two files modified (`ARCHITECTURE.md`, `DECISIONS.md`) and nothing else; an explicit statement that no schema or runtime implementation occurred; status `COMPLETE` or `PARTIAL` per §0.2; and next action: "If this correction is `COMPLETE`, proceed to `TODO_GEMINI_P15_CORRECTION_B.md` in a new session. If `PARTIAL`, do not proceed until the unresolved item is closed."

**Invariants:** no schema version 9; no migration written or described; `CatalogMigrations.currentVersion` untouched; nothing outside the schema/provenance paragraph changes in either edited file; historical Handoffs already in `handoffs/` (Round 1's and Slice A's) are untouched.

**Do NOT:** reopen packaging, byte policy, cancellation, security, or UI decisions; write migration code; create schema v9; predetermine `provider_identifier` as the answer without deriving it; start an Auditor/Reviewer role; claim a consistency check passed without re-reading the actual current text of the untouched subsections.

**Local completion check:** all five questions are answered with citations to actual file text; exactly one verdict token is issued in both `ARCHITECTURE.md` and `DECISIONS.md`, identically, with matching reasoning; if schema change is required, exactly one minimal field is named with its semantics and the overloading objection to `detector_version` explicitly addressed; the consistency-check statements are all present and specific; both Handoff files exist with a real, mtime-consistent timestamp.

---

*End of micro-slice. Exactly 1 major TODO. Stop after its Handoff step — do not begin Slice B.*
