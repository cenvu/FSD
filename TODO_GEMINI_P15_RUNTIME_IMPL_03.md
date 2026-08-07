# TODO_GEMINI_P15_RUNTIME_IMPL_03.md — Bundled-helper host adapter seam

Prepared by: Tech Lead / Architect (planning only)  
Sequence: 3 of 8  
Major TODO count: **3**  
Risk: **HIGH**  
Recommended Writer: **Gemini**

## Purpose

Implement and test the FSD-side process boundary for a locally bundled helper without downloading, vendoring, building, or pretending to implement Magika itself. The host adapter accepts only the bounded bytes from Slice 02, launches only an executable resolved inside the FSD app bundle, uses bounded raw-byte IPC, and converts helper/process behavior to typed results.

## Prerequisites

- Slices 01 and 02 are merged and their independent audits approved.
- No external Magika facts may be assumed. Read Slice 07's escalation gate before coding this slice.

## Locked implementation decisions

- Packaging remains a locally bundled helper executable. The host never searches `$PATH`, invokes a shell, or accepts a user/defaults/environment override for the executable.
- The helper URL is resolved from a fixed bundle-relative location and must remain inside the standardized bundle root. Missing/non-executable helper maps to `.unavailable`.
- The 0–4096 input bytes are written as raw stdin once, then stdin is closed. Do not base64/hex/JSON-wrap the sample, write it to disk, pass it in argv/environment, or expose the source path.
- Stdout is a small versioned metadata envelope only: schema version, result kind, detected type, MIME type, confidence, detector version, model version. Lock a 4096-byte stdout cap and a 4096-byte stderr drain cap; stderr is never stored or shown. Oversize/malformed/unknown output is `.failed`.
- `providerIdentifier` is a host-defined stable adapter identifier, independent from helper-reported detector/model versions. Helper output cannot override it.
- Adapter cancellation terminates the child, closes pipes, reaps the process, and returns `.cancelled`. Crash/non-zero exit/malformed output returns `.failed`. Timeout policy is enforced by Slice 04's runtime, but cancellation must reliably stop the process.
- No persistent helper daemon, background watcher, telemetry, network API, sampled-byte persistence, or automatic launch.
- Tests use an injected fake process runner. They do not execute Magika, install dependencies, use an external command, or require a real helper binary.

## Files/modules the Writer may modify

- New `FSD/Classification/BundledMagikaClassificationProvider.swift`
- `FSD/Classification/LocalFileClassificationProvider.swift` only if the audited Slice 02 contract needs the adapter conformance hook; no source capabilities may be added
- `FSD.xcodeproj/project.pbxproj`
- New `FSDTests/BundledMagikaClassificationProviderTests.swift`
- `FSDTests/ClassificationProviderContractTests.swift` for additive adapter-boundary assertions only
- One new `handoffs/FSD_P15_RUNTIME_IMPL_03_C_<timestamp>.md` and `handoffs/CURRENT_HANDOFF.md` for closeout only

## Files/modules the Writer must not modify

- Schema/repository/source-reader/capture files, app/UI, orchestration, search/export/comparison, product docs, unrelated tests
- No helper target, Magika source/model/binary, package manifest, downloaded artifact, network entitlement, shell script, or dependency

## Ordered TODOs

### TODO 1 — Implement the bounded process-runner boundary

Add a narrow internal runner that validates the bundle-contained executable, starts `Process` directly with fixed arguments, streams the already-bounded input to stdin, caps/drains stdout and stderr without deadlock, reaps every termination path, and exposes cancellation. Process objects, pipes, and diagnostics stay behind this file and never enter the provider request/result.

### TODO 2 — Implement the typed bundled-helper provider adapter

Parse the locked versioned metadata envelope with strict field/count/length/confidence validation, keep provider/detector/model provenance separate, and deterministically map missing helper, success, declared unavailable, failure, crash, malformed/oversized output, and cancellation to the approved typed results. Do not add a fallback classifier.

### TODO 3 — Prove process-boundary failure handling and scope

With a fake runner, test exact raw input bytes and length, one stdin delivery, fixed executable resolution, no path/handle in request or IPC, output caps, hostile stderr suppression, unknown envelope/version rejection, provenance separation, cancellation/termination/reaping, and every typed process outcome. Add source-boundary assertions that no shell, `$PATH`, temporary sample file, URLSession/network API, telemetry, or persistent process was introduced.

## Required build/test commands

```bash
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Impl03-DerivedData clean build

xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/FSD-P15-Impl03-DerivedData \
  -only-testing:FSDTests/BundledMagikaClassificationProviderTests \
  -only-testing:FSDTests/ClassificationProviderContractTests
```

Then run the full Debug suite.

## Completion checks

- Production host adapter compiles and is inert until explicitly called.
- No real helper or Magika asset exists; tests use only the injected runner.
- Input/output caps and all termination paths are deterministic and covered.
- Provider identity cannot be supplied or overwritten by helper output.
- Missing helper is unavailable; process faults are failed; cancellation is runtime-only.
- Only allowlisted files changed and every required command/result is reported honestly.

## Stop condition

If safe bounded pipe draining, cancellation, or child reaping cannot be implemented without unbounded buffering, shell invocation, temporary sample files, or source authority, mark `ARCHITECT ESCALATION REQUIRED` and stop. Do not invent Magika CLI/output/license/model facts.

## Audit gate

**Independent audit is required before Slice 04** because this is a HIGH-risk process/security boundary. The audit evaluates the whole three-TODO slice once.

