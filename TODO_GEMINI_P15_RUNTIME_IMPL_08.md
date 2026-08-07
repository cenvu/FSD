# TODO_GEMINI_P15_RUNTIME_IMPL_08.md — Whole-runtime verification and canonical Handoff

Prepared by: Tech Lead / Architect (planning only)  
Sequence: 8 of 8 (terminal)  
Major TODO count: **2**  
Risk: **HIGH**  
Recommended Writer: **Architect-only / do not delegate**

## Purpose

Perform whole-implementation verification, synchronize only the documentation facts proven by the completed runtime, and create the canonical Phase 1.5 runtime Handoff. This terminal slice fixes no production/test defect and makes no unverified release claim.

## Prerequisites

- Slices 01–06 are merged and their required audits passed.
- Slice 07's escalation is resolved by a separately approved replacement implementation slice, and that real helper integration has passed independent audit.
- Every intermediate Writer/audit Handoff and the Slice 06 §9 coverage ledger are available.
- If a real bundled Magika helper is not present and verified, stop; do not finalize a seam/stub as “runtime implemented.”

## Locked decisions

- This slice is verification/documentation only. Any defect creates a new bounded correction task; do not patch code/tests/schema here.
- Manual UI/VoiceOver/physical-media testing remains `NOT PERFORMED — DEFERRED BY OWNER` unless Cen explicitly changes that state.
- “Runtime implemented” requires real helper execution evidence, not fake runner/stub evidence.
- Claims distinguish `AUTOMATED VERIFIED`, `AGENT-OBSERVED`, `INFERRED`, and deferred manual evidence.
- Canonical Handoff follows `docs/AGENT.md`: exactly one new historical Handoff, then a complete overwrite of `handoffs/CURRENT_HANDOFF.md` with local ISO-8601 timestamp.

## Files/modules the Writer may modify

- `docs/ARCHITECTURE.md` §9/§9a status wording only
- `docs/DECISIONS.md` ADR-031/032 status/implementation note only
- `docs/SECURITY_AND_READ_ONLY_POLICY.md` §2.1 status and verified call-site inventory only
- `docs/TEST_PLAN.md` §9 evidence/status only; preserve requirements
- `docs/MVP_PLAN.md` Phase 1.5 status only
- `docs/PRODUCT_STATE.md` current implementation/Handoff lines only
- `docs/KNOWN_ISSUES.md` KI-025 status/residual risks only
- One new `handoffs/FSD_P15_MAGIKA_RUNTIME_IMPL_C_<timestamp>.md`
- `handoffs/CURRENT_HANDOFF.md`

## Files/modules the Writer must not modify

- Every production Swift file, test, schema/SQL, Xcode project/scheme, helper/vendor/model/binary, dependency, unrelated documentation section, and historical Handoff

## Ordered TODOs

### TODO 1 — Run and inspect the complete verification matrix

Run clean Debug and Release arm64 builds, all focused classification suites, the full test suite, schema migration/integrity/foreign-key checks, app-bundle/helper architecture and placement inspection, real success/missing/crash/hang/timeout/cancel probes, 4096-byte and adversarial-provider proofs, eight-workflow no-invocation suite, persistence/isolation/export checks, and zero-network observation during real classification. Record exact commands, durations, passed/failed/skipped counts, helper/provider/detector/model versions, and any environment limitation.

### TODO 2 — Synchronize proven status and write the canonical Handoff

Update only the allowlisted status paragraphs so they agree on schema version, implementation state, six outcomes, explicit-only UI, external artifact/version/license facts, test evidence, remaining limitations, and KI-025 disposition. Write the one canonical historical Handoff and full `CURRENT_HANDOFF.md`; include exact files changed, audit verdicts, evidence labels, manual state, no false content-verification claim, and one next action.

## Required build/test commands

At minimum, with new isolated paths:

```bash
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Final-Debug clean build

xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Final-Debug

xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Final-Release clean build
```

Also run every real-helper command mandated by Slice 07's replacement contract. Do not substitute fake-runner results.

## Completion checks

- All required builds/tests/probes pass, or status is not COMPLETE.
- App bundle contains the exact audited arm64 helper/model/license assets and no unexpected runtime/dependency.
- Schema 9 fresh/migration state and four/no-row persistence outcomes remain correct.
- All eight forbidden workflows remain zero-invocation; explicit UI is the sole trigger.
- No source write/sample/hash/path/network/telemetry/background behavior is observed.
- Documentation agrees and the canonical Handoff contains exact, reproducible evidence.
- `git diff --name-only` (or equivalent recorded manifest when unavailable) contains only allowlisted documentation/Handoff files for this slice.

## Stop condition

Stop on any build/test/probe failure, missing real helper, unresolved Slice 07 fact, documentation contradiction requiring a design change, unexpected changed file, or unavailable evidence needed for a claim. Do not patch, soften wording, or mark COMPLETE.

## Audit gate

**Independent final implementation audit is mandatory.** CONTROL reviews the canonical Handoff plus exact evidence before accepting Phase 1.5 runtime. Manual acceptance remains separately deferred.

