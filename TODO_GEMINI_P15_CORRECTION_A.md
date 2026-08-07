# TODO_GEMINI_P15_CORRECTION_A.md — Slice A: Architectural Contract Correction

Prepared by: Tech Lead / Planner (planning-only session)
For: Gemini Writer, Round 2, Slice A of 3 (A → B → C, sequential, separate sessions)
Corrects: `FSD-P15-MAGIKA-RUNTIME-DESIGN-0807-20`, Round 1 (`AUDIT FAIL`,
`WRITER SLICE TOO LARGE` — see `handoffs/FSD_P15MAGIKADESIGN_C_20260807-120000.md`
and the independent audit findings for that round)

This slice does **5 TODOs**. It is deliberately smaller than the 11-TODO
Round 1 attempt. Slice B (tests/housekeeping) and Slice C (verification +
canonical Handoff) are separate files, executed in separate sessions, after
this slice's own Handoff is written. Do not attempt their work here.

**This is a DESIGN CORRECTION task, not an implementation task.** No Magika
model, dependency, subprocess, or network call is installed or executed. No
production Swift, test, schema, migration, or Xcode project file changes.

---

## 0. Global rules for this slice

- Files you may modify in this slice: `docs/ARCHITECTURE.md` (§9a only), `docs/DECISIONS.md` (ADR-032 only), `docs/SECURITY_AND_READ_ONLY_POLICY.md` (§2.1 only), plus one new historical Handoff under `handoffs/` and an overwrite of `handoffs/CURRENT_HANDOFF.md` (TODO A5 only).
- Do not touch `docs/TEST_PLAN.md`, `docs/KNOWN_ISSUES.md`, `docs/MVP_PLAN.md`, or `docs/PRODUCT_STATE.md` — those are Slice B's work, not this slice's.
- Do not create the final canonical design Handoff (`handoffs/FSD_P15_MAGIKA_RUNTIME_DESIGN_A_<timestamp>.md`) — that is Slice C's work exclusively, after Slice B has also run.
- Do not modify any `.swift` file, `docs/database/schema.sql`, `docs/database/verify.sql`, or `FSD.xcodeproj/project.pbxproj`.
- Do not delete, rename, or edit `handoffs/FSD_P15MAGIKADESIGN_C_20260807-120000.md` — the failed Round 1 artifact is preserved benchmark evidence, not something to hide or clean up.
- **§9a in `docs/ARCHITECTURE.md`, ADR-032 in `docs/DECISIONS.md`, and §2.1 in `docs/SECURITY_AND_READ_ONLY_POLICY.md` already exist** (written by the failed Round 1 Writer). Your job in this slice is to **correct their content in place** — do not create §9b, ADR-033, or a §2.2 as a parallel/duplicate section. Read each section's current text before editing it.
- Do not download, install, or execute anything. Do not access GitHub or any network resource.
- Any fact about Magika itself that cannot be verified by reading files already in this repository must be labeled exactly `EXTERNAL VERIFICATION REQUIRED` — never asserted as fact. Round 1 used this label **zero times** despite repeated requirement; this is the single most important thing to get right in this slice.
- Every numeric threshold you state or keep must be labeled exactly `PROPOSED` unless copied verbatim from an existing repository constant.
- Do not start, simulate, or reference an independent Auditor/Reviewer role. That happens after this whole slice finishes, not between its TODOs.
- Manual test status is always `NOT PERFORMED — DEFERRED BY OWNER`.

## 0.1 Execution discipline

- Read this entire file before editing anything.
- Execute TODOs A1 → A5 strictly in order.
- Do not re-plan or rewrite this TODO file. If an objective repository contradiction makes a step impossible, do not silently change the plan — record the contradiction and your resolution in this slice's Handoff (TODO A5).
- Do not silently skip a requirement. If something cannot be completed, record the exact blocker and continue only if later TODOs remain safe.
- Never claim a command, file read, or check occurred if it did not.
- Never report a file as modified unless you actually modified it.
- Stop after TODO A5. Do not begin Slice B's work. Do not implement anything.

## 0.2 Completion semantics

- `COMPLETE` — every one of TODO A1–A5's local completion checks passes and no prohibited change occurred.
- `PARTIAL` — only if a genuinely load-bearing FSD-side decision remains unresolved. A fact labeled `EXTERNAL VERIFICATION REQUIRED` does not by itself force `PARTIAL`.

---

## Read first

- `handoffs/FSD_P15MAGIKADESIGN_C_20260807-120000.md` (the failed Round 1 design — read to know exactly what exists and what it got wrong; do not treat its conclusions as pre-approved)
- `docs/ARCHITECTURE.md` §9 (implemented Phase 1.5 boundary — do not edit) and §9a (the section you are correcting)
- `docs/DECISIONS.md` ADR-031 (reference, do not edit) and ADR-032 (the entry you are correcting)
- `docs/SECURITY_AND_READ_ONLY_POLICY.md` §2 (existing, accurate, do not edit) and §2.1 (the section you are correcting)
- `docs/FILESYSTEM_PROVIDER_ARCHITECTURE.md` §7–8 (the existing isolated-helper-process precedent, cited by Round 1's packaging choice — read it directly rather than trusting Round 1's characterization of it)
- `docs/database/schema.sql` (`entry_classifications` DDL — exact column list)
- `FSD/Catalog/EntryClassificationRepository.swift` (full: the `detection_status` enum, `LocalClassificationRequest`'s `sourceURL`/`byteBudget` fields, `append`'s append-only/duplicate-rejection behavior)
- `FSD/Browser/SnapshotTreeDataSource.swift` (the existing `generation`/`invalidate()` idiom — `queryCount`/`rowsFetched` instrumentation lives here too, for context only)
- `FSD/UI/SnapshotBrowserView.swift` (`EntryInspectorView` — current nullable-classification presentation: "Not classified" neutral state, "Inferred classification (optional)" section, no fabricated confidence)

Do not access GitHub. Do not download anything. Do not inspect external Magika documentation.

---

## TODO A1 — Re-establish the exact correction evidence (recon, no edits)

**Objective:** Before touching any document, confirm — from the current repository, not from memory of the audit report — exactly what is wrong and exactly what evidence exists to fix it. Round 1 partly failed because its packaging and cancellation decisions were asserted without a shown evidence trail; this TODO exists so that failure mode cannot repeat.

**Files that may be inspected:** everything in "Read first" above.

**Files that may be modified:** none.

**Exact output required** (working notes, not a new file — carry forward into TODO A2–A5):

1. Quote the current packaging conclusion in `DECISIONS.md` ADR-032 and confirm it has exactly one line of reasoning per rejected shape, with no per-shape breakdown across offline behavior / deployment complexity / startup cost / sandbox boundary / dependency management / macOS 13 arm64 fit / licensing / failure modes / update-provenance.
2. Confirm `grep -c "EXTERNAL VERIFICATION REQUIRED" docs/ARCHITECTURE.md docs/DECISIONS.md docs/SECURITY_AND_READ_ONLY_POLICY.md` returns `0` for each file.
3. Quote the current cancellation sentence in `ARCHITECTURE.md` §9a and confirm it cites none of: the `detection_status` enum, `EntryClassificationRepository`'s append-only/duplicate-rejection semantics, or `SnapshotBrowserView.swift`'s current nullable-UI behavior.
4. Confirm `grep -n "generation\|invalidate" ` over the current `ARCHITECTURE.md` §9a text returns no hits (the lifecycle section never cites the existing cancellation idiom).
5. Quote the exact current `entry_classifications` column list from `schema.sql` and the exact current `detection_status` enum values from `EntryClassificationRepository.swift`, so TODO A4's schema re-check has the real evidence in hand rather than a copied conclusion.
6. Confirm whether any explicit UI-contract sentence (inferred-only / neutral-on-absence / no-fabricated-confidence / no-raw-diagnostics, for the *future* runtime) exists anywhere in §9a today (it does not, as of Round 1 — confirm this yourself).

**Invariants:** this step changes nothing.

**Do NOT:** edit any file; assume any of the parenthetical hints above without confirming them against the actual current file text.

**Local completion check:** you can quote, verbatim, the current packaging paragraph, the current cancellation sentence, and the current `entry_classifications`/`detection_status` evidence, each with a file:line reference.

---

## TODO A2 — Correct the packaging decision: genuine four-way comparison

**Objective:** Replace the current one-line-per-shape packaging paragraph in `ARCHITECTURE.md` §9a and `DECISIONS.md` ADR-032 with a genuine, evidence-based four-way comparison, correctly labeling every unverifiable Magika-internals claim.

**Files that may be inspected:** `docs/AGENT.md` (self-contained-`.app`, minimal-dependency, macOS 13+ Apple Silicon arm64 invariants); `docs/FILESYSTEM_PROVIDER_ARCHITECTURE.md` §8 (read the actual isolated-helper-process mechanics, not Round 1's summary of them); `docs/SECURITY_AND_READ_ONLY_POLICY.md` §2/§4.1.

**Files that may be modified:** `docs/ARCHITECTURE.md` (packaging paragraph inside the existing §9a only), `docs/DECISIONS.md` (ADR-032's packaging paragraph only).

**Do not predetermine the outcome.** Round 1 selected "locally bundled helper executable" — you may reach the same conclusion, a different one, or a hybrid, but only after the comparison below, not because Round 1 already picked one.

**Exact output required.** For each of the four shapes — (1) native in-process library/model embedding, (2) locally bundled helper executable, (3) Python/runtime dependency, (4) external command-line Magika installation — state explicitly:

- offline behavior;
- deployment complexity (what has to be built/bundled/signed);
- startup cost (rough qualitative order — "loads with the app" vs. "spawns per use" — not a fabricated benchmark number);
- sandbox/process boundary (does it need its own isolation, and does one already exist in this codebase to reuse — cite `FILESYSTEM_PROVIDER_ARCHITECTURE.md` §8 by name only for the shape(s) where it's actually relevant);
- dependency management (what would have to be vendored or linked, and against which AGENT.md invariant that does or doesn't conflict);
- macOS 13 arm64 fit;
- licensing/redistribution facts — label anything not answerable from files in this repository exactly `EXTERNAL VERIFICATION REQUIRED`;
- failure modes (what happens when this shape's classifier crashes, hangs, or is missing);
- update/version provenance (how would you know which classifier version produced a result).

State the final decision **only after all four rows exist**, and name the specific repository-grounded reason each of the three non-chosen shapes was ruled out. Any claim about what Magika's actual model format, runtime, or licensing requires must read exactly `EXTERNAL VERIFICATION REQUIRED` in every row where it applies — do not restate it as established fact the way Round 1 did ("Python/C++ footprint" was stated as fact in Round 1's `ARCHITECTURE.md:384`; correct or remove that specific unsupported claim as part of this rewrite).

**Invariants:** zero network traffic and metadata-only default are preserved regardless of which shape is chosen.

**Do NOT:** invent a new isolation mechanism if §8's existing pattern already covers shape 2; fabricate a specific performance number for "startup cost"; leave the previous unlabeled "Python/C++ footprint" sentence in place unexamined.

**Local completion check:** both `ARCHITECTURE.md` and `DECISIONS.md` contain a four-row comparison (one row per shape, all nine dimensions addressed per row), at least one `EXTERNAL VERIFICATION REQUIRED` label appears in the packaging section of each file, and the final decision paragraph explicitly says it follows the comparison rather than restating a predetermined choice.

---

## TODO A3 — Complete the bounded-byte contract and provider API boundary

**Objective:** Fill the concrete gaps the audit found in the byte contract, and add the two required-but-missing provider-API statements.

**Files that may be inspected:** `FSD/Catalog/EntryClassificationRepository.swift` (`LocalClassificationRequest`, `LocalClassificationProviderResult`).

**Files that may be modified:** `docs/ARCHITECTURE.md` (the "Bounded Byte Contract" subsection of §9a only).

**Exact output required**, added to the existing subsection (do not remove the byte-ceiling/range-count/concurrency lines that are already correct — confirm `4096` bytes / range count `1` / concurrency `1` are still there, and either keep them `PROPOSED` or change them only with stated local reasoning, not arbitrarily):

1. State the accounting definition explicitly: what counts against the byte ceiling (e.g., "the ceiling bounds the single prefix read from the resolved live file; nothing else — no directory-listing bytes, no metadata bytes — counts against it").
2. State small-file behavior: a file smaller than the ceiling is read in full (its actual size), not padded or treated as an error.
3. State large-file behavior: only the first `4096` bytes (or whatever ceiling TODO A2/this TODO settles on) are ever read; the rest of the file is never touched.
4. Restate, in this subsection, the disappearing-source, inaccessible-source, directory, symlink, and special-file outcomes by cross-reference to the existing "Source Resolution and Identity" subsection of §9a (that subsection already covers this correctly — do not duplicate its text, just point to it by name so the byte contract and the identity policy are visibly the same design, not two disconnected ones).
5. Restate the 6-stage pipeline verbatim: FSD source resolution → FSD source identity validation → FSD bounded reader → bounded bytes → provider → typed result. State explicitly that the provider receives no `URL`, path, or file handle at any stage.
6. Add the verbatim sentence: "No production protocol change is implemented in this design correction slice."
7. Cross-reference the existing three `LocalClassificationProviderResult` cases (`classified`, `unavailable`, `failed`) against the six required outcomes (success, unavailable, failed, cancelled, source-changed, unsupported-entry) and name the three currently missing from the live enum.

**Invariants:** the byte ceiling is enforced by FSD's reader, never trusted to the provider.

**Do NOT:** edit `EntryClassificationRepository.swift`; duplicate the identity-policy text instead of cross-referencing it.

**Local completion check:** items 1–7 each appear as an explicit sentence or bullet in the corrected subsection, with item 6 present verbatim and item 7 naming exactly three missing cases.

---

## TODO A4 — Evidence-based lifecycle, persistence, and schema re-check

**Objective:** Redo the two decisions the audit found were asserted without evidence: the cancellation persistence shape, and the schema verdict.

**Files that may be inspected:** `FSD/Catalog/EntryClassificationRepository.swift` (`ClassificationDetectionStatus` enum, `append`'s append-only/duplicate-run-rejection code); `FSD/Browser/SnapshotTreeDataSource.swift` (the `generation`/`invalidate()` idiom — read the actual code, not a description of it); `FSD/UI/SnapshotBrowserView.swift` (current nullable-classification UI text); `docs/database/schema.sql` (`entry_classifications` full column list); `docs/DECISIONS.md` ADR-031 and `docs/KNOWN_ISSUES.md` KI-025 (the existing, pre-Round-1 note that `providerIdentifier` is runtime-only).

**Files that may be modified:** `docs/ARCHITECTURE.md` ("Lifecycle and Cancellation" and "Outcomes and Schema Impact" subsections of §9a), `docs/DECISIONS.md` (ADR-032's schema paragraph).

**Exact output required:**

1. Keep the six `PROPOSED` lifecycle values already present (concurrency, trigger scope, timeout, memory delta, queue/backpressure rule, UI latency) unless you have a specific local reason to change one — if you keep them, say so briefly rather than silently leaving them unexamined.
2. Add the missing seventh item: state explicitly that the cancellation contract reuses the existing `generation`/`invalidate()` idiom in `SnapshotTreeDataSource.swift` — name the mechanism, don't just allude to "cancellation."
3. Cancellation persistence — **evidence first, decision second, in that order in the text you write:**
   - Quote or closely paraphrase what the `detection_status` enum, `append`'s append-only/duplicate-rejection behavior, and the current UI's "Not classified" neutral state actually say.
   - Then state your decision: `runtime-only` (no row) or `append-only persisted` (one row, existing vocabulary only, no new column, no free-text diagnostic).
   - The only predetermined constraint: cancellation must never produce a row with a successful/`classified` outcome. Nothing else about this decision is predetermined — do not simply repeat Round 1's "runtime-only" conclusion unless your own evidence review leads there, and if it does, show why.
4. Restate explicitly, in this subsection: append-only semantics and `(entry_id, classification_run_id)` duplicate-rejection are unconditionally preserved.
5. Fix the outcome-count framing: state clearly that there are **six** outcomes (not "five" as Round 1's heading said), listing cancellation alongside the other five with its row-or-no-row answer from item 3.
6. Schema verdict re-check: using the exact column list and enum values you read (not Round 1's conclusion), determine whether representing the six outcomes plus truthful provider identity requires a new column, or fits within `detection_status` + `detector_version`/`model_version`. Issue exactly one token — `SCHEMA V8 SUFFICIENT` or `SCHEMA CHANGE REQUIRED BEFORE RUNTIME` — and if change is required, name the single minimal field and the specific reason drawn from the evidence you just reviewed, not a restatement of Round 1's paragraph.

**Invariants:** no schema version 9; no migration written; `CatalogMigrations.currentVersion` untouched; cancellation never produces a successful/`classified` row regardless of which shape you choose.

**Do NOT:** write a migration; add a column to `schema.sql`; state the cancellation or schema conclusion before the evidence paragraph that leads to it.

**Local completion check:** the cancellation paragraph visibly cites the three named evidence sources before stating its conclusion; the outcome count reads "six," not "five"; exactly one schema-verdict token is issued with a reason traceable to the column list you quoted in this TODO, not to Round 1's text.

---

## TODO A5 — Security/privacy completion, minimal UI contract, consistency pass, and Slice A Handoff

**Objective:** Close the remaining privacy-documentation gaps, add the missing minimal UI contract, verify TODOs A2–A4 are internally consistent with each other, and close out this slice with its own Handoff.

**Files that may be inspected:** `docs/SECURITY_AND_READ_ONLY_POLICY.md` §2.1 (current text); `FSD/UI/SnapshotBrowserView.swift` (`EntryInspectorView`'s existing, already-approved Phase 1.5 UI language — reuse its wording pattern, don't redesign it); `docs/AGENT.md` (Handoff filename/format rules).

**Files that may be modified:** `docs/SECURITY_AND_READ_ONLY_POLICY.md` (§2.1 only), `docs/ARCHITECTURE.md` (add a short "UI Contract" subsection to the existing §9a if one does not already exist after TODO A2–A4's edits — confirm first, do not duplicate), and exactly one new historical Handoff plus the `handoffs/CURRENT_HANDOFF.md` overwrite.

**Exact output required:**

1. In §2.1, add explicit sentences for: zero network traffic (restate locally in this section, don't rely solely on the inherited §9 sentence one section away); zero telemetry (this exact word must appear — it appears nowhere in the current documentation set); no historical backfill; no background watcher. These four are currently either absent or only inherited by proximity, not stated in §2.1 itself.
2. Add a short UI Contract subsection to §9a (only if not already present after A2–A4) stating, for the future runtime: classification is presented as inferred, never as content verification; absence is neutral ("Not classified" or equivalent, not fabricated); confidence is shown only when actually present, never fabricated; no raw provider diagnostic, stack trace, or path reaches visible text. Base this on the wording already used in `SnapshotBrowserView.swift`'s `EntryInspectorView` for the existing Phase 1.5 UI — state that the future runtime's UI must follow the same pattern, don't invent new UI copy.
3. Re-open your own edits from TODO A2, A3, and A4 and confirm they don't contradict each other (e.g., the byte ceiling number is the same everywhere it's mentioned; the packaging shape chosen in A2 is consistent with any isolation language used in A3/A4; the schema verdict in A4 matches what's said about `provider_identifier` anywhere else in §9a/ADR-032).
4. Write one historical Handoff: `handoffs/FSD_P15_MAGIKA_RUNTIME_CORRECTION_A_C_<YYYYMMDD-HHMMSS>.md` (role code `C`, per `docs/AGENT.md`'s standard flat-Handoff convention — this is **not** the final canonical design Handoff, which is Slice C's exclusive responsibility). Use a real timestamp obtained from the environment, not an invented or rounded one.
5. Overwrite `handoffs/CURRENT_HANDOFF.md` per `docs/AGENT.md`: line 1 exactly `UPDATED_AT: <real timestamp>`, one blank line, then the complete contents of the historical Handoff just created (full copy, not a pointer, not the file's own internal title line substituting for the required `UPDATED_AT:` line — this exact defect is what broke Round 1's `CURRENT_HANDOFF.md`).
6. The Handoff must state: what was corrected (packaging comparison, byte contract completeness, provider API statements, cancellation evidence trail, schema re-check, privacy completion, UI contract), the exact files changed, and status `COMPLETE` or `PARTIAL` per §0.2. Next action: "Proceed to `TODO_GEMINI_P15_CORRECTION_B.md` in a new session."

**Invariants:** historical Handoffs already in `handoffs/` (including the failed Round 1 one) are untouched.

**Do NOT:** create the final canonical design Handoff here; start Slice B's work; claim a consistency check passed without re-reading the actual current text of A2–A4's edits.

**Local completion check:** §2.1 contains the word "telemetry"; §9a contains a UI Contract subsection; both new Handoff files exist with the correct `UPDATED_AT:`-first format; the Handoff names the next action as proceeding to Slice B.

---

*End of Slice A. 5 TODOs (A1–A5). Stop here — do not begin Slice B.*
