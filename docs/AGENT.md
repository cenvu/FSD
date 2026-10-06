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

- macOS 15+
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

- Load [task-execution](../.agents/skills/fsd-task-execution/SKILL.md) for every
  meaningful Worker execution; independent review also loads
  [independent-review](../.agents/skills/fsd-independent-review/SKILL.md).
- Keep implementation changes small and reviewable.
- Record architecture decisions in `DECISIONS.md`.
- Update `PRODUCT_STATE.md` after meaningful milestones.
- Record product limitations in `PRODUCT_STATE.md` or their specialized authority.
- Accepted control state and transitions belong to `STATE/PROJECT_STATE.md` and
  `STATE/EVENTS.jsonl`; Worker continuity belongs to `handoffs/CURRENT_HANDOFF.md`.
- Use the sole [FSD finalizer](../.agents/skills/fsd-handoff-finalizer/SKILL.md)
  for immutable history, full CURRENT, pending Worker ledger/event projection,
  Desktop recovery parity and publication checks. It owns the procedure.
- `BRAIN_OPERATOR.md` owns Worker terminal return, section ownership and routing;
  this FULL reference does not define a competing procedure or live decision.

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
authorize execution. `P15_RUNTIME_PLAN.md` sections are planning contracts and require a
separately authorized task, starting at ADR-032's schema prerequisite.
Product performance validation remains required: scanner/database throughput,
lazy-tree bounds, memory probes, comparison scale, 10k/100k/1M fixtures and
cancellation/reliability stress tests. Ordinary model routing is not a benchmark.

Canonical handoff procedure is the finalizer linked above. Stable model/harness
routing is owned by [BRAIN_OPERATOR.md](BRAIN_OPERATOR.md) §ROUTING; prompts are
model-agnostic. [P15_RUNTIME_PLAN.md](P15_RUNTIME_PLAN.md) contains future runtime
contracts and requires separate authorization, beginning with ADR-032's schema
prerequisite. Load exact relevant sections, not all historical packets.

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
