UPDATED_AT: 2026-08-07T15:56:30+07:00

# Handoff: FSD_P15_MAGIKA_RUNTIME_DESIGN_A
**Role:** Auditor/Reviewer (A)
**Timestamp:** 2026-08-07T15:56:30+07:00

## 1. Status
`COMPLETE`

## 2. Runtime Packaging Decision
The packaging decision is a **Locally bundled helper executable**.
- Shape 1 (Native in-process) was ruled out because a classifier crash would take down the main app.
- Shape 3 (Python/runtime dependency) was ruled out because bundling a Python runtime violates the "minimal dependencies" priority.
- Shape 4 (External command-line) was ruled out because it requires user installation, violating the self-contained `.app` platform invariant.
The full comparison is documented in `docs/ARCHITECTURE.md` §9a and `docs/DECISIONS.md` ADR-032.

## 3. Byte-Access Contract
- **Ceiling**: `4096` bytes. This bounds the single prefix read from the resolved live file; no directory or metadata bytes count against it.
- **Range count**: Exactly `1` single prefix range. No tail reads and no adaptive additional reads (PROPOSED).
- **Concurrency**: Exactly `1` classification in flight at a time (PROPOSED).
- **Small-file behavior**: Files smaller than the ceiling are read in full (their actual size), not padded or treated as an error.
- **Large-file behavior**: Only the first `4096` bytes are ever read.
- **Bytes**: Bytes read for classification are never persisted, never hashed, and never logged to any diagnostic surface.
- **Request shape**: The provider receives only a bounded `Data` buffer (or equivalent byte buffer) — no `URL`, no path, and no file handle at any stage.

## 4. Invocation Policy
- **Trigger scope**: Explicit-only, single-selected-entry action.
- **Workflows that never trigger it**: Capture, application launch, history open, snapshot reopen, browsing, search, comparison, and JSON export.

## 5. Source-Identity Policy
- **Re-resolution**: The live path is re-resolved from the entry's stored relative path against the currently attached source.
- **Regular-file-only gate**: Positively confirms the live item is a regular file.
- **Symlink/directory prohibition**: Forbids following any symlink beyond the entry's recorded target and forbids recursing into directories. Directories, symlinks, and special files immediately resolve to `.unsupported-entry`.
- **Source-changed/unavailable split**: If the source is detached or changed identity, returns `.source-changed` or `.unavailable`.
- **Non-implication rule**: The stored classification represents time-of-classification metadata about currently-attached bytes. It is NEVER retroactive proof of the immutable snapshot's content.

## 6. Adapter API Decision
- **Shape**: No-`URL`/`Data`-only request shape.
- **Production rule**: "No production protocol change is implemented in this design correction slice."
- **Result cases**: The three previously-missing result cases are now explicitly named in the design: `cancelled`, `source-changed`, and `unsupported-entry`.

## 7. Schema/Provenance Decision
`SCHEMA CHANGE REQUIRED BEFORE RUNTIME`

**Reasoning**: Schema v8 provides `detector_version` and `model_version`, which strictly identify the detection algorithm and model version. An independent fact, `provider_identifier`, is required to record which adapter/process produced the row. `detector_version` must not be overloaded to carry this fact because it would merge two orthogonal facts, forcing future queries to rely on undocumented string conventions.

## 8. Cancellation/Resource Limits
- **Concurrency**: exactly `1` classification in flight at a time (PROPOSED).
- **Trigger scope**: single selected-entry action only (PROPOSED).
- **Inference timeout**: `5` seconds (PROPOSED).
- **Memory high-water delta**: `2x` the byte ceiling (8192 bytes) (PROPOSED).
- **Queue/backpressure**: no queue in the first implementation. A second request is rejected if one is in flight (PROPOSED).
- **UI latency expectation**: show progress/cancel affordance after `0.5` seconds (PROPOSED).
- **Cancellation mechanism**: reuses the existing `generation`/`invalidate()` idiom implemented in `SnapshotTreeDataSource.swift`.

## 9. Persistence Policy
Exactly six outcomes:
1. `success/classified`: Row written with `classified` status.
2. `failed`: Row written with `failed` status.
3. `source-changed`: Row written with `failed` status.
4. `unsupported-entry`: Row written with `failed` status.
5. `unavailable`: No row written.
6. `cancelled`: No row written (runtime-only).

## 10. UI Contract
- **Inferred-only & neutral-absence**: Absence of classification is presented as a neutral state ("Not classified" or equivalent), never fabricated as an error.
- **No-fabricated-confidence**: Confidence is shown only when actually present in the data, never fabricated.
- **No-raw-diagnostics**: No raw provider diagnostic, stack trace, or internal path ever reaches visible text.
- Follows the existing pattern in `SnapshotBrowserView.swift`.

## 11. Testing Strategy
- The comprehensive test list spans 30+ items in `docs/TEST_PLAN.md` §9.
- It includes the **Adversarial Provider Test**, which dictates three specific constraints a fake hostile provider must attempt and fail to violate:
  1. Attempt to reopen or access the original source path.
  2. Attempt to request or receive additional bytes.
  3. Attempt to bypass the hard 4096-byte ceiling.

## 12. External Verification Requirements
- `EXTERNAL VERIFICATION REQUIRED` (Compatibility of Magika's license with in-process app distribution).
- `EXTERNAL VERIFICATION REQUIRED` (Compatibility of distributing the model inside the app bundle).
- `EXTERNAL VERIFICATION REQUIRED` (Python runtime and dependency redistribution licensing).

## 13. Exact Documents Changed
- **Round 1 (superseded/failed)**: `handoffs/FSD_P15MAGIKADESIGN_C_20260807-120000.md`
- **Slice A**: `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/SECURITY_AND_READ_ONLY_POLICY.md`, `handoffs/FSD_P15_MAGIKA_RUNTIME_CORRECTION_A_FIX_C_20260807-153125.md`, `handoffs/FSD_P15_MAGIKA_RUNTIME_CORRECTION_A_C_20260807-151218.md`
- **Slice B**: `docs/TEST_PLAN.md`, `docs/KNOWN_ISSUES.md`, `docs/MVP_PLAN.md`, `docs/PRODUCT_STATE.md`, `handoffs/FSD_P15_MAGIKA_RUNTIME_CORRECTION_B_C_20260807-154325.md`
- **Slice C (this slice)**: `handoffs/CURRENT_HANDOFF.md`, `handoffs/FSD_P15_MAGIKA_RUNTIME_DESIGN_A_20260807-155630.md`

## 14. Manual Test State
`NOT PERFORMED — DEFERRED BY OWNER`

## 15. Execution Ledger
- **Slice A**:
  - TODO A1: `DONE`
  - TODO A2: `DONE`
  - TODO A3: `DONE`
  - TODO A4: `DONE`
  - TODO A5: `DONE`
- **Slice B**:
  - TODO B1: `DONE`
  - TODO B2: `DONE`
  - TODO B3: `DONE`
  - TODO B4: `DONE`
- **Slice C**:
  - TODO C1: `DONE`
  - TODO C2: `DONE`

## 16. Next Action
Implement the approved bounded-byte Magika runtime adapter as one isolated Writer slice.
