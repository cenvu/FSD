# TODO_GEMINI_P15_RUNTIME_IMPL_07.md — External Magika integration gate

Prepared by: Tech Lead / Architect (planning only)  
Sequence: 7 of 8  
Major TODO count: **2**  
Risk: **HIGH**  
Recommended Writer: **Architect-only / do not delegate**

## Purpose

Resolve the external facts required to replace Slice 03's tested host seam with a real locally bundled Magika helper. This file is deliberately a stop gate, not authorization to browse, download, install, vendor, build, or modify production code.

## Current status

`ARCHITECT ESCALATION REQUIRED`

Repository evidence cannot establish the exact upstream license/model redistribution terms, supported native macOS arm64 embedding/build shape, pinned source/model artifact identities, helper API, or detector/model version reporting. The current planning session was expressly forbidden from consulting external Magika sources. Inventing filenames, checksums, build flags, target inputs, or an output mapping would violate the audited design.

## Prerequisites

- Slices 01–06 are merged and green.
- CONTROL explicitly authorizes a separate external-verification session.
- That session starts from the exact accepted base and preserves the fixed locally bundled helper decision, bounded raw-byte host contract, no network/telemetry, and self-contained app invariant.

## Locked decisions that external verification may not overturn

- Provider input is only the already-read 0–4096-byte prefix; no path/URL/handle/callback.
- Helper is bundled inside the app, arm64/macOS 13 compatible, fully offline, separately crash-isolated, and never discovered via `$PATH` or user installation.
- No Python/runtime dependency may be introduced without an explicit new architecture decision; current audited packaging ruled that shape out.
- Model/detector/provider versions are distinct and exact; helper output cannot set provider identity.
- No source write, sample persistence/hash/logging, network, telemetry, watcher, backfill, daemon, or automatic invocation.
- Existing Slice 03 IPC caps/result envelope are the host contract. If verified Magika cannot fit it, stop for architecture review rather than changing it in an implementation task.

## Files/modules the Architect may modify in this gate

- One new external-verification research Handoff and `handoffs/CURRENT_HANDOFF.md`
- A replacement bounded implementation TODO file created only after all facts below are verified

## Files/modules that must not be modified under this gate

- All production Swift, tests, schema/SQL, `FSD.xcodeproj`, app bundle contents, docs, dependencies, vendor directories, Magika source/model/binaries, and historical Handoffs

## Ordered TODOs

### TODO 1 — Verify and record the external integration facts

In an explicitly authorized external-research session, record authoritative license and model redistribution terms; exact upstream version/commit and asset checksums; supported macOS arm64 build/runtime path; minimum deployment compatibility; model/runtime footprint; deterministic bounded-input API behavior; exact output/provenance semantics; offline/no-telemetry behavior; and signing/bundle placement requirements. Separate quoted facts from Architect inference. Do not change code.

### TODO 2 — Issue the replacement Writer slice or stop permanently

If and only if every fixed requirement is satisfiable, create a new 2–4 TODO implementation contract with an exact allowlist for helper target sources, pinned vendored artifacts, project copy/sign phases, adapter mapping, license notices, and real integration/network/crash/timeout tests. If any fact conflicts with the fixed design, keep `ARCHITECT ESCALATION REQUIRED`, document the conflict, and do not authorize a workaround.

## Required build/test commands

None in this gate. It performs no implementation. The replacement Writer contract must specify its own clean Debug/Release arm64 builds, targeted helper integration tests, full suite, bundle inspection, code-sign/load checks as applicable, crash/timeout/cancellation probes, and zero-network observation.

## Completion checks

- Every external fact is supported by an authoritative source and pinned artifact identity.
- Licensing covers both executable/runtime and model redistribution.
- A real offline arm64 helper can satisfy the already-implemented byte/result contract.
- Replacement TODO has 2–4 major TODOs, exact file/artifact allowlists, commands, stop conditions, and an independent audit gate.
- No code/artifact/dependency was changed during this gate.

## Stop condition

The current file is already stopped at `ARCHITECT ESCALATION REQUIRED`. CONTROL must not route it to Gemini or DeepSeek. Any unresolved license, model, API, build, signing, provenance, offline, or macOS compatibility fact keeps the gate closed.

## Audit gate

The eventual replacement integration slice is **HIGH risk and requires independent audit** before Slice 08. The audit must include app-bundle contents, process isolation, no-network evidence, exact provenance, and full failure-mode behavior.

