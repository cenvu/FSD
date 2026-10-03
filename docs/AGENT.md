# Full FSD Governance Reference — FSD (FishSock Differ)

## Reference loading

This is the FULL/deep FSD governance reference, loaded on demand; it is not
the default startup context. The omission-critical always-on kernel is
[`AGENTS.md`](../AGENTS.md), and stable BRAIN/Worker operation is canonical in
[`BRAIN_OPERATOR.md`](BRAIN_OPERATOR.md). Read relevant sections here when an
exact task needs detailed policy, an audit, policy ambiguity, governance conflict,
operator repair, rule promotion or high-risk adjudication requires them.

## Product invariant

FSD — FishSock Differ is a metadata-only, read-only catalog and comparison application. Do not introduce source-volume write operations, content hashing, media parsing or synchronization unless explicitly approved as a separate feature.

## Platform invariant

- macOS 13+
- Apple Silicon arm64 only for initial releases
- Swift 5.9+
- SwiftUI shell
- AppKit `NSOutlineView` for large virtualized trees
- SQLite as the canonical persistent store
- Delivered as one self-contained `.app`. Never require the user to install Homebrew, macFUSE, ntfs-3g, a kernel extension, or an app extension — including Apple's own FSKit, which is excluded for this reason regardless of macOS version (`DEPENDENCY_AND_LICENSE_REVIEW.md` §3.5). Filesystem access follows `FILESYSTEM_PROVIDER_ARCHITECTURE.md`; do not add a filesystem-reading code path outside that contract.

## Engineering priorities

1. Data integrity.
2. Read-only safety.
3. Scanner throughput.
4. Low memory use.
5. Clear comparison semantics.
6. Minimal dependencies.

## Required behavior

- All snapshot writes must be transactional.
- A snapshot becomes `complete` only after all entries and aggregates commit successfully.
- Interrupted snapshots must never become the default offline view.
- Source paths are read-only inputs.
- Relative path normalization must be deterministic.
- Symbolic links are recorded but not followed by default.
- Common macOS service files may be ignored for comparison, but not silently deleted.
- UI must never claim content equivalence from metadata alone.

## Prohibited behavior

- Writing a catalog, hidden file or marker onto scanned media.
- Any write syscall against a raw block device, at any privilege level.
- Building a custom privileged helper, root daemon, or `SMJobBless`/`SMAppService` service for raw-device access — the only authorization mechanism in scope is the system `/usr/libexec/authopen` utility, read-only, one device at a time (`DECISIONS.md` ADR-016).
- Loading all entries of a large snapshot into memory.
- Using JSON as the primary database.
- Automatically merging two volumes solely because their display names match.
- Following symbolic links outside the selected scan root.
- Treating modification timestamps as a default equality requirement.
- Camera-vendor folder recognition, media validation, codec analysis, or any media-specific capture profile, at any phase (`DECISIONS.md` ADR-018).
- Claiming a filesystem is "Supported" without the seven-step proof in `FILESYSTEM_SUPPORT_MATRIX.md` §1 — research or library documentation alone is never sufficient.

## Development workflow

- Keep implementation changes small and reviewable.
- Record architecture decisions in `DECISIONS.md`.
- Update `PRODUCT_STATE.md` after meaningful milestones.
- Add known limitations to `KNOWN_ISSUES.md`.
- Store exactly one handoff per task session under the flat `handoffs` directory:

```text
handoffs/FSD_<CASE_CODE>_<ROLE_CODE>_<YYYYMMDD-HHMMSS>.md
```

Use role codes:

- F — Forge or planning
- A — Audit
- R — Research
- C — Coding
- T — Testing
- D — Documentation

Do not create date subdirectories, SESSION directories, or `.sha256` files for new Handoffs.
The legacy nested `AI_HANDOFFS/` directory has been migrated into flat `handoffs/` files and deleted; do not recreate it.

**Mandatory Single-File Handoff Policy**:
- Exactly one Markdown Handoff per session;
- No separate session report file;
- The Handoff is the complete technical record;
- The Handoff may be long because it replaces the report;
- The user only needs to provide the latest single Handoff to CONTROL CENTER.

## FSD Handoff Artifact Rules

Canonical as of 2026-08-04. These rules take priority over any generic Skill default.

When a task requires a Handoff:

- Create exactly one historical Handoff:
  `handoffs/FSD_<CASE>_<ROLE>_<YYYYMMDD-HHMMSS>.md`
- Overwrite `handoffs/CURRENT_HANDOFF.md`.
- The first line of `CURRENT_HANDOFF.md` must be:
  `UPDATED_AT: <machine-local ISO 8601 timestamp with timezone>`
- Add one blank line, then copy the complete historical Handoff.
- `CURRENT_HANDOFF.md` is a full report, not a pointer.
- The final Worker response follows the compact Worker terminal return contract below.

Do not create:

- checksum files;
- `.sha256` files;
- nested date folders;
- `SESSION_*` folders;
- `AI_HANDOFFS/` paths;
- `CURRENT.md`;
- separate audit reports;
- separate manual reports;
- multiple Handoffs for one task.

Historical Handoffs are immutable after creation. Do not rename or overwrite them.

## Worker terminal return

The permanent Worker terminal return contract is:

```text
TASK=<id>
RESULT=<worker-local-result>
WHAT=<dense verifiable delta>
BRAIN=SEND FILE=/Users/cenvu/Desktop/04_FSD_BRAIN.md
```

Optionally add at most five short machine-dense evidence lines, only when
materially required. End exactly `NEW HANDOFF!!!`.

RESULT is Worker evidence, not BRAIN classification or acceptance. Human
explanation is BRAIN's responsibility. Historical handoffs using the old
10-line format remain valid immutable history; do not rewrite them.

## Deferred Manual Testing Rule

Canonical as of 2026-08-04. Until the project owner explicitly states that manual testing is available:

- Do not ask the owner to perform manual steps.
- Maximize automated tests, integration tests, generated fixtures, isolated runtime probes, database inspection, process-launch checks, and Agent-observed evidence.
- Label evidence accurately as:
  - AUTOMATED VERIFIED
  - AGENT-OBSERVED
  - INFERRED
  - NOT PERFORMED — DEFERRED BY OWNER
- Never label Agent-driven or source-inspection evidence as USER-OBSERVED.
- Never mark a manual acceptance gate PASS without actual owner interaction.
- A deferred manual-only gate does not block subsequent implementation when technical safety gates have passed and the current project plan permits continuation.
- Preserve deferred manual tests in one consolidated acceptance backlog.
- When the owner later declares readiness, run one consolidated manual acceptance session rather than repeating manual tests after every task.

The consolidated acceptance backlog lives in [`TEST_PLAN.md`](TEST_PLAN.md) §8.

## Project Skills

**Owner directive (2026-10-03): no AI model or harness benchmarking in FSD.**
Do not start model-vs-model or harness-vs-harness runs, score models, select
winners, or choose benchmark patches. Historical handoffs and completed
design/correction task packets remain evidence only; their old next actions do not
authorize execution. Runtime TODOs are planning contracts and require a
separately authorized task, starting at ADR-032's schema prerequisite.
Product performance validation remains required: scanner/database throughput,
lazy-tree bounds, memory probes, comparison scale, 10k/100k/1M fixtures and
cancellation/reliability stress tests. Ordinary model routing is not a benchmark.

Two generic A4C Skills are installed for reference:

- [`docs/skills/HANDOFF_SKILL.md`](skills/HANDOFF_SKILL.md) — generic AI-to-AI handoff format and discipline.
- [`docs/skills/MODEL_SUGGESTION_SKILL.md`](skills/MODEL_SUGGESTION_SKILL.md) — model/harness routing guidance for Writer/Reviewer pairing.

Neither has `default_load: true`. Load the Handoff Skill only when work continues in another session, project state changed, a blocker or decision must be preserved, or the user explicitly asks for a Handoff. Load the Model Suggestion Skill only when model or harness selection is material, the user asks which model to use, or Writer/Reviewer routing must be decided. Do not load either automatically for a trivial task.

**FSD-specific override (takes priority over the generic Handoff Skill's defaults):** the generic Skill's default `AI_HANDOFFS/<date>/SESSION_<id>/H_<CASE>_<ROLE>_<timestamp>.md` layout, `CURRENT.md` pointer, and optional checksum sidecar do **not** apply to this project. FSD already has its own, stricter convention (ADR-013 above, this file's Handoff section): a single flat `handoffs/` directory, filenames `FSD_<CASE_CODE>_<ROLE_CODE>_<YYYYMMDD-HHMMSS>.md`, no date or SESSION subdirectories, and no `.sha256`/checksum files ever. Direct instructions from Cen and this file override generic Skill defaults whenever the two disagree.

## `handoffs/CURRENT_HANDOFF.md` — required

Required by direct project instruction as of 2026-08-04. After writing the historical Handoff for a session, **overwrite** `handoffs/CURRENT_HANDOFF.md` with:

- line 1: `UPDATED_AT: <machine local time, ISO 8601 with timezone>`
- line 2: blank
- line 3 onward: the **complete contents** of the historical Handoff just created.

`CURRENT_HANDOFF.md` is a full copy, **not** a pointer — this deliberately differs from the generic Skill's `CURRENT.md` pointer semantics. It is the single file the project owner sends back to CONTROL CENTER. Never delete or edit the historical Handoff it was copied from. There is still exactly one historical Handoff per session; `CURRENT_HANDOFF.md` is not a second Handoff.

## Review policy

Default workflow for implementation work (set 2026-08-04):

1. Writer implements one coherent milestone or major feature slice (`MVP_PLAN.md`).
2. Writer runs the milestone's targeted automated checks.
3. Writer creates one historical Handoff and updates `handoffs/CURRENT_HANDOFF.md`.
4. Writer returns the required short summary plus `NEW HANDOFF!!!`.
5. CONTROL CENTER reads the full Handoff.

**Routine low- and medium-risk slices do not automatically require an independent Reviewer.** Independent review is required only when work touches:

- source read-only safety;
- snapshot immutability;
- interruption and crash recovery;
- schema migration or compatibility;
- destructive behavior;
- broad comparison semantics;
- pre-MVP acceptance (mandatory).

Per `MVP_PLAN.md`, that means Milestones 2, 4, and 5 receive an independent audit; Milestones 1 and 3 do not, unless they cross one of the boundaries above.
