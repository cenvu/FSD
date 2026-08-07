# TODO — FSD-P15-MAGIKA-RUNTIME-DESIGN-0807-20

Prepared by: Tech Lead / Planner (planning-only session)
For: Gemini Writer (single sequential execution round)
Followed by: independent Auditor evaluation of the completed round (not part of this file)

This file operationalizes the full task specification
`FSD-P15-MAGIKA-RUNTIME-DESIGN-0807-20` as a deterministic, ordered checklist.
It preserves every safety rule, completion-status term, documentation rule,
Handoff requirement, and the exactly-one-next-action requirement from that
task without weakening any of them. Where the source task left a decision to
the Writer, this file gives an explicit decision rule so no architectural
judgment call is left open during execution.

**This is a DESIGN task, not an implementation task.** The deliverable is a
written, internally consistent architecture decision plus updated
documentation and one Handoff. No Magika model, dependency, subprocess,
network call, or runtime is installed, downloaded, or executed. No
production Swift, test, schema, migration, or Xcode project file changes.

---

## 0. Global safety rules (apply to every TODO below, no exceptions)

- Do not modify any `.swift` file under `FSD/` or `FSDTests/`.
- Do not modify `docs/database/schema.sql`, `docs/database/verify.sql`, or any `CatalogMigrations*` file.
- Do not modify `FSD.xcodeproj/project.pbxproj` or any Xcode project file.
- Do not download, install, or vendor anything: no Magika model, no Python, no Homebrew, no package dependency, no subprocess binary.
- Do not access GitHub or any network resource.
- Do not execute, simulate executing, or claim to have executed a Magika model, inference process, or subprocess classifier.
- Do not read any real source-volume payload byte as part of doing this design work.
- Do not start, simulate, or reference an independent Auditor/Reviewer role at any point in this run. That happens after this round, separately.
- Do not delete `.gemini-derived-data`.
- Do not fix the separately tracked legacy startup-error wording issue — out of scope.
- Do not rename, rewrite, or delete any existing file under `handoffs/`.
- Do not expand scope into unrelated documentation cleanup beyond what each TODO names explicitly.
- Manual test status is always `NOT PERFORMED — DEFERRED BY OWNER`. Never mark any manual gate PASS.
- Any fact about Magika itself (model format, runtime requirements, performance, accuracy, packaging) that cannot be verified by reading files already in this repository must be labeled exactly `EXTERNAL VERIFICATION REQUIRED` — never asserted as fact, never guessed.
- Every new numeric threshold you propose (byte ceilings, timeouts, concurrency, memory deltas, latency targets) must be labeled exactly `PROPOSED`. Never label a new number `VERIFIED` unless it is copied directly from existing repository evidence (e.g., an existing constant already in source).

## 0.1 Gemini execution discipline

- Execute the TODOs below strictly in numeric order.
- Do not skip a TODO silently. If a TODO cannot be completed, record the exact blocker in your working notes and continue only if later TODOs remain safe to attempt; reflect the blocker honestly in the final Handoff's execution ledger.
- Mark a TODO's local completion check passed only when it actually passes — never assume.
- Never claim a command, test, or check was run if it was not run.
- Never report a file as modified unless you actually modified it.
- Never silently broaden scope beyond what a TODO's "files that may be modified" list allows.
- Never perform work that belongs to the next implementation slice (i.e., do not write the actual runtime adapter code — that is explicitly the next action after this round, not part of it).
- Do not rewrite this TODO.md while executing it, unless an objective repository contradiction makes a step literally impossible to perform as written — if that happens, do not silently change the plan; record the contradiction and your resolution explicitly in the final Handoff.
- Maintain a compact execution ledger for the final Handoff: each TODO (1–10) marked exactly `DONE`, `BLOCKED`, or `NOT REQUIRED`. No percentage-complete estimates, ever.

## 0.2 Completion semantics (preserved verbatim from the source task)

- `COMPLETE` — an implementation-ready bounded-byte design exists and no prohibited product/runtime change occurred.
- `PARTIAL` — only when a genuinely load-bearing FSD-side design boundary remains unresolved. A fact labeled `EXTERNAL VERIFICATION REQUIRED` does **not** by itself force `PARTIAL` if the local FSD-side architecture can still be fully specified around that unknown.
- Manual test: always `NOT PERFORMED — DEFERRED BY OWNER`.

## 0.3 Exactly one next action (preserved verbatim; do not add a second one)

When status is `COMPLETE`, the Handoff's next action must read exactly:

> Implement the approved bounded-byte Magika runtime adapter as one isolated Writer slice.

---

## Read first (before starting TODO 1)

- `handoffs/CURRENT_HANDOFF.md`
- `docs/AGENT.md`
- `docs/PRODUCT_STATE.md`
- `docs/MVP_PLAN.md` (Phase 1.5 section)
- `docs/PRD.md` (§8.1 Future content classification)
- `docs/ARCHITECTURE.md` §9
- `docs/DECISIONS.md` (ADR-021, ADR-031, and skim the ADR list for the highest existing number)
- `docs/TEST_PLAN.md` (Phase 1.5 section)
- `docs/KNOWN_ISSUES.md` (KI-024, KI-025)
- `docs/SECURITY_AND_READ_ONLY_POLICY.md`
- `docs/database/schema.sql` (`entry_classifications` only)
- `docs/database/verify.sql` (the Magika nullable-enrichment check block only)
- `FSD/Catalog/EntryClassificationRepository.swift`
- `FSD/Browser/SnapshotTreeDataSource.swift`
- `FSD/UI/SnapshotBrowserView.swift`
- `docs/FILESYSTEM_PROVIDER_ARCHITECTURE.md` §7–8 (existing authorization/isolated-helper-process precedent — read for architectural analogy only, not for filesystem-provider work)

As of this planning session, `docs/DECISIONS.md`'s highest existing ADR is
**ADR-031** ("Nullable classification enrichment boundary uses schema
version 8") — your new ADR in TODO 8 must be **ADR-032**. `docs/KNOWN_ISSUES.md`'s
highest existing KI is **KI-025**. Do not renumber either.

Do not access GitHub. Do not download dependencies. Do not inspect external
Magika documentation of any kind — everything you need about the *existing
FSD-side* boundary is in this repository; everything about *Magika itself*
that is not in this repository stays `EXTERNAL VERIFICATION REQUIRED`.

---

## TODO 1 — Inspect and record the current classification seam

**Objective:** Build an accurate, current inventory of the existing nullable
classification boundary so every later decision in this file is grounded in
actual code, not assumption or memory of the source task description.

**Files that may be inspected:** every file in "Read first" above.

**Files that may be modified:** none.

**Exact output required.** Write down (in your own working notes — this does
not need to be a new file) answers to each of the following, each traceable
to a specific file you read:

1. The exact method signature of `LocalFileClassificationProvider.classify(_:)`, and the exact stored properties of `LocalClassificationRequest` and `LocalClassificationProviderResult` (`FSD/Catalog/EntryClassificationRepository.swift`).
2. Whether `LocalClassificationRequest` currently exposes an unrestricted `sourceURL: URL?` field that a provider implementation could dereference directly (it does, as of this writing — confirm this yourself rather than trusting this note).
3. The exact column list of `entry_classifications` (from `schema.sql`) and the exact set of fields `EntryClassificationRepository.append(_:)` actually writes (from the Swift source) — confirm they match.
4. Confirmation, by direct `grep`, that `ClassificationEnrichmentService(` and `DisabledFileClassificationProvider(` are constructed only inside `FSDTests/`, nowhere in `FSD/` production code.
5. Confirmation, by direct read, that `SnapshotTreeDataSource.root()` and `.children(...)` never reference `entry_classifications`, and that `details(for:)` is the only method that does, exactly once per call.
6. The literal integer value of `CatalogMigrations.currentVersion` as it exists today.
7. The current verdict recorded in `handoffs/CURRENT_HANDOFF.md` for the prior Phase 1.5 audit (should read `APPROVE WITH CONDITIONS` as of this writing — confirm, do not assume).

**Invariants:** this step changes nothing; it is observation only.

**Do NOT:** modify any file; draw runtime-packaging conclusions yet (that is TODO 2); assume any of the parenthetical hints above without confirming them yourself against the actual file.

**Local completion check:** you can state, from what you actually read, the exact signature from item 1, the exact column list from item 3, and the exact integer from item 6 — each with a file reference.

---

## TODO 2 — Resolve the runtime packaging and invocation-trigger decision

**Objective:** Decide, only after a genuine four-way comparison grounded in
local evidence, how a future adapter would be packaged/hosted, and reaffirm
that invocation stays explicit-only.

**Files that may be inspected:** `docs/AGENT.md` (platform invariant: single
self-contained `.app`, never require the user to install Homebrew, macFUSE,
ntfs-3g, a kernel extension, or an app extension; "Minimal dependencies"
engineering priority); `docs/FILESYSTEM_PROVIDER_ARCHITECTURE.md` §8 (the
existing isolated-helper-process pattern already used for the embedded raw
filesystem reader — an untrusted-third-party-code isolation precedent
already accepted in this codebase); `docs/SECURITY_AND_READ_ONLY_POLICY.md`
§2/§4.1.

**Files that may be modified:** none (decision text carried forward to TODO 8 — do not rephrase it later, transcribe verbatim).

**Decision rule (apply exactly):** Do not predetermine native in-process
embedding as the required final answer. Perform and record a genuine
four-way comparison before deciding, covering exactly these four shapes:

1. Native in-process library/model embedding (no subprocess, no interpreter, no network).
2. A locally bundled helper executable, isolated per the existing pattern in `FILESYSTEM_PROVIDER_ARCHITECTURE.md` §8 (single bounded handle, no other filesystem access, no privilege escalation, no network).
3. A Python/runtime dependency embedded in or alongside the `.app`.
4. An external, separately installed command-line Magika installation invoked by FSD.

For each of the four, record: (a) what local repository evidence — AGENT.md
invariants, the existing §8 precedent, `SECURITY_AND_READ_ONLY_POLICY.md` —
counts for or against it; (b) its user-visible install burden (does it
require anything beyond the single `.app`?); (c) its network/telemetry
exposure; (d) its dependency-footprint/licensing implications, marking any
unknown licensing, platform, or distribution fact `EXTERNAL VERIFICATION
REQUIRED` rather than guessing.

You may state a preferred bias grounded in AGENT.md's self-contained-`.app`
and minimal-dependency invariants, but you must not select a final
packaging decision until the four-way comparison table above is complete.
State the final decision only after that comparison, and name, for each of
the three shapes ruled out, the specific repository-grounded reason it was
ruled out — not merely "we prefer this default."

- Any claim about what Magika's actual model format, runtime, licensing, or command-line packaging requires is `EXTERNAL VERIFICATION REQUIRED` — write it down as exactly that phrase in every row of the comparison where it applies, do not assert it as fact either way.
- Invocation trigger: explicit, single-selected-entry, caller-initiated action only. Restate by name, from Section A of the source task, every workflow that must never trigger it: capture, application launch, history open, snapshot reopen, browsing, search, comparison, JSON export. This invocation-trigger rule holds regardless of which packaging shape is finally chosen.
- No background watcher, queue, or timer-based invocation, ever, in this design.

**Invariants:** metadata-only default is preserved regardless of packaging choice; zero network traffic regardless of packaging choice (this explicitly rules out shape 4 unless the external installation is invoked strictly locally with no network call ever made by FSD).

**Do NOT:** assert a specific Magika model format/runtime/licensing fact as verified; design a new subprocess isolation mechanism when the existing §8 pattern already covers shape 2; select a final packaging decision without completing all four rows of the comparison.

**Local completion check:** a four-row comparison table exists (one row per shape) each with the (a)–(d) evidence points and any `EXTERNAL VERIFICATION REQUIRED` labels; a final packaging decision is stated only after that table, with a named repository-grounded reason for ruling out each of the three shapes not chosen; and all seven workflows that must never trigger classification automatically are listed.

---

## TODO 3 — Resolve the bounded-byte contract

**Objective:** Pin down exactly how many bytes, from where, and under what
FSD-enforced ceiling a future provider may ever see.

**Files that may be inspected:** `FSD/Catalog/EntryClassificationRepository.swift` (current unenforced `byteBudget: Int64?` field).

**Files that may be modified:** none (decision carried forward to TODO 8).

**Exact output required:**

1. Restate the mandatory sequence verbatim: FSD source resolution → FSD identity validation → FSD bounded reader → bounded byte input → classifier provider → typed result. The classifier never receives a path, URL, or open handle — only an already-bounded, already-read byte buffer.
2. Explicitly flag, as a load-bearing concern requiring resolution in TODO 4, that today's `LocalClassificationRequest.sourceURL: URL?` is unrestricted and must not survive into any real implementation in that form.
3. Propose one concrete byte-ceiling number for a single classification request, labeled `PROPOSED`, chosen only from the "favor a deliberately small first implementation" bias — not from any assumption about what Magika needs.
4. Range count: `1` (single prefix range only — no tail read, no adaptive additional read), labeled `PROPOSED`.
5. Concurrency at the read layer: `1` (single classification at a time), labeled `PROPOSED`.
6. State explicitly and unconditionally: bytes read for classification are never persisted, never hashed, never logged to any diagnostic surface, in any outcome.

**Invariants:** the byte ceiling is enforced by FSD's own reader component, never trusted to the provider; the provider protocol never receives raw filesystem access.

**Do NOT:** implement the bounded reader; pick a byte number by researching or assuming Magika's real input requirements.

**Local completion check:** the 6-stage sequence is restated verbatim, the `sourceURL` concern is flagged explicitly, and items 3–5 each have one concrete `PROPOSED` value.

---

## TODO 4 — Resolve the provider API boundary (decision only, no code)

**Objective:** Decide the corrected provider-facing protocol *shape*, given
the `sourceURL` concern from TODO 3, without changing any actual Swift file.

**Files that may be inspected:** `FSD/Catalog/EntryClassificationRepository.swift` (current protocol/struct/enum definitions, for exact naming continuity in your written decision).

**Files that may be modified:** none. This explicitly includes not editing `EntryClassificationRepository.swift` itself — the decision is recorded in prose (TODO 8), not implemented.

**Exact output required:**

1. State the corrected conceptual request shape: the provider-facing request carries only a bounded `Data` (or equivalent already-read byte buffer) — no `URL`, no path, no handle. `classify(_:)` remains the entry point, but its request type must be redesigned (in a future implementation slice, not here) before any real provider exists.
2. State verbatim: "No production protocol change is implemented in this design task."
3. Cross-reference the existing three `LocalClassificationProviderResult` cases (`classified`, `unavailable`, `failed`) against the six outcomes required by Section E of the source task (success, unavailable, failed, cancelled, source-changed, unsupported-entry) and name exactly which three are currently missing.

**Invariants:** the protocol boundary stays local-only, `Sendable`, and free of any raw-diagnostic channel; no implicit background execution.

**Do NOT:** edit `EntryClassificationRepository.swift`; add cases to the live enum.

**Local completion check:** your written decision names the corrected request shape, contains the verbatim no-protocol-change sentence, and lists the exact three missing result cases.

---

## TODO 5 — Define source identity and invocation semantics

**Objective:** Define what "the source" means at classification time and
what must be validated before FSD's bounded reader may touch it, given that
a historical snapshot entry's live path may have changed, disappeared, or
changed identity since capture.

**Files that may be inspected:** `FSD/Browser/SnapshotTreeDataSource.swift` (`SnapshotEntryDetails` fields: `relativePath`, `casePreservingPath`, `symlinkTarget`, `isInaccessible`); `docs/DECISIONS.md` ADR-023 (the existing "never silently substitute a later live state for a historical fact" principle — apply the same principle here, do not restate ADR-023 itself).

**Files that may be modified:** none (decision carried forward to TODO 8).

**Exact output required:**

1. Identity-validation rule: before any bounded read, FSD must independently re-resolve the live path from the entry's stored relative path against the *currently attached* source, and must positively confirm the live item is a regular file — not a directory, not an auto-followed symlink target, not a special/device file — before reading a single byte. Directory/symlink/special-file entries always resolve to the `.unsupported-entry` outcome (from TODO 4's expanded set), never silently treated as success or silently skipped without a typed outcome.
2. Non-implication rule (Section C, restate as binding): classifying live bytes located behind a historical snapshot entry must never be presented or persisted as proof that those live bytes ARE the historical snapshot's content. The stored classification is time-of-classification metadata about currently-attached bytes, never a retroactive fact about the immutable snapshot.
3. If the source is detached, missing, or has changed identity at classification time, the outcome is `.source-changed` or `.unavailable` (from TODO 4) — never silently reinterpreted as `.unsupported-entry` or dropped without a typed result.
4. Explicitly forbid following any symlink beyond the entry's own recorded target, and forbid recursing into a directory under any circumstance.

**Invariants:** read-only; never mutates the entry; a live-path mismatch is always a typed non-success outcome, never silence.

**Do NOT:** design a general-purpose "source identity" subsystem beyond what classification needs — reference existing FSD identity concepts (relative path, case-sensitivity policy, mount-boundary policy) rather than inventing new machinery.

**Local completion check:** the pre-read validation rule, the non-implication rule, and the three named non-success outcomes for identity failure are each stated with the specific triggering condition.

---

## TODO 6 — Define lifecycle, resource, and cancellation policy

**Objective:** Set conservative `PROPOSED` resource limits and a precise
cancellation contract, biased toward the smallest safe first
implementation.

**Files that may be inspected:** `FSD/Browser/SnapshotTreeDataSource.swift` (the existing `generation`/`invalidate()` idiom already used to discard stale in-flight reads when the user abandons a selection — reuse this idiom rather than inventing a new one).

**Files that may be modified:** none (decision carried forward to TODO 8).

**Exact output required, every numeric value labeled `PROPOSED`:**

1. Concurrency: exactly one classification in flight at a time.
2. Trigger scope: single selected-entry action only.
3. Inference timeout: one concrete small number of seconds, justified only as "a conservative default for a first implementation" — not as a Magika-verified figure.
4. Memory high-water delta: one concrete bound expressed as a small constant multiple of the byte ceiling decided in TODO 3 — never unbounded.
5. Queue/backpressure: no queue in the first implementation. Pick and state one deterministic rule for what happens if a second request arrives while one is in flight (reject the second, or supersede/cancel the first) — do not leave this ambiguous.
6. UI latency expectation: one concrete figure for when the UI should show a progress/cancel affordance.
7. Cancellation contract: reuse the existing `generation`/`invalidate()` idiom. A classification in flight for a selection the user has since abandoned must be discarded, and discarding it must never itself write a row for a stale selection. This bounds *when* a cancelled read is discarded; it does not by itself decide whether the `cancelled` outcome is ever persisted for a request that was still live and legitimately targeted when cancellation occurred — that decision is made on evidence in TODO 7, not predetermined here.

**Invariants:** no unbounded queue; no unbounded memory growth; every numeric limit stays labeled `PROPOSED`.

**Do NOT:** benchmark anything; claim any timeout/memory number is validated by real Magika performance (it is `EXTERNAL VERIFICATION REQUIRED` and irrelevant to how conservatively you bound the first implementation).

**Local completion check:** all seven items above have one concrete value or rule each, all labeled `PROPOSED`, and item 7 explicitly names reuse of the existing `generation`/`invalidate()` idiom.

---

## TODO 7 — Define provenance and persistence policy, including the schema decision

**Objective:** Specify exactly what gets written to `entry_classifications`
for every outcome in TODO 4's expanded result set, and issue the mandatory
schema-sufficiency verdict.

**Files that may be inspected:** `docs/database/schema.sql` (`entry_classifications` DDL, exact column list); `FSD/Catalog/EntryClassificationRepository.swift` (`append`, `validate`, `makeClassification` — the exact persisted-column set already established by ADR-031, and the full `detection_status` model); `FSD/UI/SnapshotBrowserView.swift` (current nullable-UI behavior — how "Not classified" vs. a stored row is presented today); `docs/DECISIONS.md` ADR-031; `docs/KNOWN_ISSUES.md` KI-025 (the existing note that `providerIdentifier` is runtime-only because schema v8 has no dedicated provider column).

**Files that may be modified:** none (decision carried forward to TODO 8).

**Exact output required:**

1. Cancellation persistence is an evidence-based decision, not predetermined — resolve it here, not in TODO 6:
   - Hard constraint, non-negotiable: cancellation must **never** create a row with a successful/`classified` outcome. A cancelled attempt can never be indistinguishable from a real classification result.
   - Inspect the existing `detection_status` model (`not_requested`, `disabled`, `classified`, `failed`), `EntryClassificationRepository`'s append-only/duplicate-run semantics, and the current nullable UI behavior in `SnapshotBrowserView.swift` (what "Not classified" vs. a stored row communicates today).
   - Using that evidence, explicitly decide and state one of the following two shapes — do not leave it open, and do not default to one without stating the reason from the evidence you inspected:
     - **Runtime-only:** a cancelled attempt writes no row at all (the entry stays exactly as if enrichment was never requested — the existing `not_requested`/absent-row state already means this truthfully); or
     - **Append-only persisted:** a cancelled attempt writes one row using the existing `detection_status` vocabulary (e.g. collapsing into `.failed`, or another existing value if you can justify it from the evidence) with no new column and no free-text diagnostic.
   - Whichever shape you choose must preserve append-only semantics (no update/delete path is introduced for it) and must not persist arbitrary diagnostics, payload bytes, samples, hashes, or absolute source paths, and must not persist a stack trace, for the cancelled case, exactly like every other outcome.
2. For each of the remaining five outcomes (success/classified, unavailable, failed, source-changed, unsupported-entry), state explicitly whether a row is written and, if so, exactly which existing columns it populates.
3. State whether the existing 4-value `detection_status` enum (`not_requested`, `disabled`, `classified`, `failed`) is sufficient to represent the outcomes that do write a row (including your cancellation decision from item 1, if it writes a row), or whether some outcomes must deliberately collapse into an existing value (e.g., `source-changed` and `unsupported-entry` both persisting as `.failed` with no distinguishing column) — say which, explicitly, and why.
4. Restate as unconditionally preserved: append-only semantics; duplicate `(entry_id, classification_run_id)` rejection.
5. State unconditionally, across every one of the six outcomes with no exception: no raw provider diagnostic text, no stack trace, no payload byte, no sample, no content hash, no absolute source path is ever persisted.
6. Issue exactly one schema verdict, using the exact literal token:
   - `SCHEMA V8 SUFFICIENT`, or
   - `SCHEMA CHANGE REQUIRED BEFORE RUNTIME`

   Base this on whether representing the expanded outcome set (item 3, including your cancellation decision from item 1) and a truthful, queryable provider identity (the runtime-only `providerIdentifier` gap already named in ADR-031/KI-025) can be done within the existing `detection_status` enum plus the existing `detector_version`/`model_version` text columns, or whether it genuinely requires a new column. If `SCHEMA CHANGE REQUIRED`, name only the single minimal missing field and the exact reason — do not design or write a migration.

**Invariants:** append-only preserved; no schema version 9 is created by this task, regardless of the verdict reached; `CatalogMigrations.currentVersion` is not touched; cancellation never produces a successful/`classified` row, regardless of which persistence shape is chosen.

**Do NOT:** write a migration; add a column to `schema.sql`; change `CatalogMigrations.currentVersion`; predetermine the cancellation persistence shape without stating the evidence (detection_status model, repository semantics, current UI behavior) that led to it.

**Local completion check:** the cancellation decision in item 1 explicitly names one of the two shapes with its evidence-based reason; a six-outcome table (written-or-not, columns populated) exists covering all six including cancellation; the no-diagnostic/payload/hash/path rule is stated as unconditional across all six; exactly one schema-verdict token is issued, with a named minimal field and reason if change is required.

---

## TODO 8 — Update design, security, and test documentation

**Objective:** Transcribe every decision recorded verbatim in TODOs 2–7 into
the minimum set of documentation files that genuinely need it. Transcribe,
do not rephrase — the exact `PROPOSED` labels, the exact schema-verdict
token, and the exact seven-workflow list must carry through unchanged.

**Files that may be inspected:** current `docs/ARCHITECTURE.md` §9; `docs/DECISIONS.md` (confirm ADR-031 is still the highest number before adding ADR-032); `docs/SECURITY_AND_READ_ONLY_POLICY.md` §2 (states today, accurately, that no `FileHandle(forReadingFrom:)`/`Data(contentsOf:)`/hashing API exists anywhere in the target — this remains true today and must not be contradicted); `docs/TEST_PLAN.md`; `docs/MVP_PLAN.md` Phase 1.5 section; `docs/PRODUCT_STATE.md`.

**Files that may be modified (design prose only, no code):**

- **`docs/ARCHITECTURE.md`** — do not edit the existing §9 prose describing the *implemented* Phase 1.5 boundary (it remains accurate and audited). Append a new, clearly delimited subsection immediately after it (e.g. "§9a — Proposed bounded-byte runtime contract (design only, not implemented)") containing: the packaging/invocation decision (TODO 2), the bounded-byte contract (TODO 3), the provider API boundary decision (TODO 4), source-identity/invocation semantics (TODO 5), lifecycle/resource policy with all `PROPOSED` numbers (TODO 6), and the provenance/persistence table with the schema verdict (TODO 7). State plainly at the top of this new subsection that none of it is implemented yet.
- **`docs/DECISIONS.md`** — add a new entry, **`ADR-032`**, titled to reflect the runtime-packaging and schema-verdict decisions. Status must read `Proposed (design only, not implemented)` — do not reuse ADR-031's "Accepted and implemented" status, since nothing here is implemented. Cross-reference ADR-021 and ADR-031 by number.
- **`docs/SECURITY_AND_READ_ONLY_POLICY.md`** — append a new, clearly labeled subsection (do not edit the existing §2 table or its accurate "no read exists today" sentence) documenting: the *future* bounded read is the only planned addition to the current read-only guarantee; its exact scope/ceiling from TODO 3; and restate zero-network, zero-telemetry, zero-source-write as unconditionally preserved for this future feature too.
- **`docs/TEST_PLAN.md`** — add a new section "Future Magika runtime adapter test plan (not yet implemented)" enumerating every item from the source task's required future-test list verbatim: byte ceiling enforcement; exact byte boundary; small and large files; missing/disappearing source; changed source identity; directory/symlink/special-file rejection; inaccessible file; cancellation at multiple lifecycle points; inference/provider failure; timeout; append-only success persistence; no success persistence after cancellation; no payload/sample/hash/path persistence; no snapshot mutation; comparison isolation; JSON export stability; zero network activity; no automatic invocation; offline snapshot usability; plus one explicit adversarial-provider test proving the classifier cannot reopen the source path, cannot request additional bytes, and cannot bypass FSD's hard byte ceiling.
- **`docs/MVP_PLAN.md`** and **`docs/PRODUCT_STATE.md`** — at most one short status line each, added only if the existing Phase 1.5 status text would otherwise read as stale or misleading without noting that a runtime design now exists (still unimplemented). Check the existing text first; if it already reads correctly without an addition, do not edit these two files at all.

**Files that must NOT be modified in this TODO:** any `.swift` file; `docs/database/schema.sql`; `docs/database/verify.sql`; `FSD.xcodeproj/project.pbxproj`; any file under `FSDTests/`; `docs/FILESYSTEM_SUPPORT_MATRIX.md`; `docs/DEPENDENCY_AND_LICENSE_REVIEW.md`; `docs/SNAPSHOT_COLLECTIONS.md`; `README.md`; any file not explicitly named above.

**Invariants:** every transcribed numeric value keeps its `PROPOSED` label; the schema-verdict token is transcribed verbatim; nothing added here contradicts the existing "no content read exists today" language in `SECURITY_AND_READ_ONLY_POLICY.md` §2 — it must read as a documented future exception, not a retroactive rewrite of what is true today.

**Do NOT:** create new documentation files beyond what's named above; touch any file not explicitly listed; invent new documentation files.

**Local completion check:** `ARCHITECTURE.md`, `DECISIONS.md`, `SECURITY_AND_READ_ONLY_POLICY.md`, and `TEST_PLAN.md` each contain the corresponding new section, and you can name the exact heading you added to each.

---

## TODO 9 — Correct the stale KI-024 wording

**Objective:** Fix exactly one pre-existing documentation-accuracy defect
identified by the prior independent Phase 1.5 audit
(`handoffs/CURRENT_HANDOFF.md`): `docs/KNOWN_ISSUES.md` KI-024's heading
still says its focused independent re-audit is "pending," although
`handoffs/FSD_M5_SCHEMA_V8_DISPOSAL_REAUDIT_A_20260805-223211.md` already
closed it with an `APPROVE WITH CONDITIONS` verdict.

**Files that may be inspected:** `docs/KNOWN_ISSUES.md` (KI-024 full text); `handoffs/FSD_M5_SCHEMA_V8_DISPOSAL_REAUDIT_A_20260805-223211.md` (verdict line only, to cite the exact date and verdict).

**Files that may be modified:** `docs/KNOWN_ISSUES.md` only — specifically the KI-024 heading line and, if needed, one closing sentence.

**Exact change required:** change the heading text away from "... focused independent re-audit pending" to state that the re-audit is closed, naming the closing Handoff filename and its `APPROVE WITH CONDITIONS` verdict and date.

**Invariants:** KI-024's underlying technical description (the O(n²) root cause, the dedicated-index fix, the 1,000,000-row timing evidence) is factual history and must not be altered, shortened, or removed — only the stale status wording changes.

**Do NOT:** renumber KI-024; touch KI-025 or any other KI entry; fix the separately tracked startup-error wording issue; delete `.gemini-derived-data`.

**Local completion check:** `docs/KNOWN_ISSUES.md` KI-024's heading no longer contains the word "pending" and instead names the specific closing Handoff and its verdict.

---

## TODO 10 — Final whole-slice consistency verification (Writer self-check only)

**Objective:** One consolidated self-check before writing the Handoff. This
is not an independent audit and does not involve starting any
Auditor/Reviewer role.

**Files that may be inspected:** re-open briefly every file you actually touched during TODOs 1–9, to confirm each one's content matches what you intended.

**Files that may be modified:** none — verification only.

**Exact checklist to confirm, each as an explicit yes/no you record, naming the file(s) checked:**

- no production `.swift` file was modified (list every `.swift` file touched this session — must be empty);
- no file under `FSDTests/` was modified (must be empty);
- no schema/migration file was modified (`docs/database/schema.sql`, `docs/database/verify.sql`, any `CatalogMigrations*.swift` — must be empty);
- `FSD.xcodeproj/project.pbxproj` was not modified;
- no dependency, package reference, or model file was downloaded or added;
- no GitHub access occurred;
- no Magika runtime, Python process, or subprocess classifier was executed;
- no source-volume payload was read during this Writer session (distinct from the *design* describing a future bounded read — this session itself reads no payloads);
- the metadata-only default is reaffirmed in the new `ARCHITECTURE.md` §9a text;
- the TODO 1 call-site inventory is still accurate — nothing added during this session introduced a new automatic call site;
- snapshot-immutability language (Section C) is present and unchanged in intent in the new documentation;
- comparison isolation is restated as unchanged;
- JSON export v1 is restated as unchanged;
- the zero-network contract is documented in `SECURITY_AND_READ_ONLY_POLICY.md`;
- the provider-cannot-bypass-the-byte-budget rule is explicitly documented (from TODO 3/4).

**Invariants:** this is a Writer self-check; it must not spawn, simulate, or claim any independent Auditor/Reviewer role.

**Do NOT:** re-run any XCTest suite or build (irrelevant to a documentation-only design task); claim any checklist line passed without actually re-opening the relevant file to confirm it.

**Local completion check:** every checklist line above has an explicit yes/no with the specific file(s)/section(s) named next to it.

---

## TODO 11 — Write the required Handoff

**Objective:** Produce the one historical Handoff and the full
`CURRENT_HANDOFF.md` overwrite, per `docs/AGENT.md`.

**Files that may be inspected:** `docs/AGENT.md` (exact Handoff filename/format rules, final-report format, historical-Handoff preservation rule).

**Files that may be created/modified:**

- create exactly one new file: `handoffs/FSD_P15_MAGIKA_RUNTIME_DESIGN_A_<YYYYMMDD-HHMMSS>.md`, using the machine-local timestamp at the moment of writing;
- overwrite `handoffs/CURRENT_HANDOFF.md` with: line 1 `UPDATED_AT: <machine-local ISO 8601 timestamp with timezone>`, one blank line, then the complete contents of the new historical Handoff (full copy, not a pointer);
- do not modify, rename, or delete any other file under `handoffs/`.

**Exact content required in the Handoff:**

- status: `COMPLETE` or `PARTIAL` (per §0.2 above — state which, and if `PARTIAL`, name the exact unresolved FSD-side boundary);
- runtime packaging decision (TODO 2);
- byte-access contract (TODO 3);
- invocation policy (TODO 2 / TODO 5);
- source-identity policy (TODO 5);
- adapter API decision (TODO 4);
- schema/provenance decision (TODO 7), including the literal `SCHEMA V8 SUFFICIENT` / `SCHEMA CHANGE REQUIRED BEFORE RUNTIME` token;
- cancellation/resource limits (TODO 6), every number still labeled `PROPOSED`;
- persistence policy (TODO 7);
- UI contract: inferred-only, neutral-on-absence, no fabricated confidence, no raw diagnostics — binding on the future implementation, unchanged from the already-approved Phase 1.5 UI contract;
- testing strategy (summarize the `TEST_PLAN.md` addition from TODO 8);
- external verification requirements: every fact you labeled `EXTERNAL VERIFICATION REQUIRED` across TODOs 2–7, collected in one list;
- exact documents changed: the precise file list from TODOs 8 and 9 — nothing else;
- the compact execution ledger from §0.1: TODO 1 through TODO 10, each marked `DONE` / `BLOCKED` / `NOT REQUIRED`;
- exactly one next action, verbatim, per §0.3;
- manual test line: `NOT PERFORMED — DEFERRED BY OWNER`.

**Invariants:** every historical Handoff already in `handoffs/` is untouched; `CURRENT_HANDOFF.md` is a full copy, never a pointer; the final chat response ends with the 10 required summary lines followed by line 11 exactly `NEW HANDOFF!!!`, per `docs/AGENT.md`.

**Do NOT:** start an independent Auditor/Reviewer; add a second "next action"; claim manual testing occurred.

**Local completion check:** both files exist; `CURRENT_HANDOFF.md` begins with `UPDATED_AT:`, a blank line, then the historical Handoff's exact content; the execution ledger lists TODO 1–10 each with a status; the final response's line 11 is exactly `NEW HANDOFF!!!`.

---

*End of TODO.md. 11 ordered sections (TODO 1–11), executed sequentially, no audit loop between them.*
