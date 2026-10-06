# Classifier provider selection — Advisor decision

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_CLASSIFIER_PROVIDER_SELECTION_ADVISOR_R_20261006-175200.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=c99e6587fec49ea88815f2bef0377dd0f229898f
REMOTE_HEAD=c99e6587fec49ea88815f2bef0377dd0f229898f
LAST_VERIFIED_AT=2026-10-06T17:52:00+07:00
AUTHORITY_PTRS=AGENTS.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|STATE/PROJECT_STATE.md|handoffs/FSD_CLASSIFIER_PROVIDER_ALTERNATIVES_RESEARCH_A_20261006-173501.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_CLASSIFIER_PROVIDER_SELECTION_ADVISOR_028
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE
PROPOSED_NEXT=FSD_CLASSIFIER_NATIVE_FEASIBILITY_SPIKE_029
NO_AUTO_NEXT=YES

## Task lock and decision

TASK_ID=FSD_CLASSIFIER_PROVIDER_SELECTION_ADVISOR_028
ROLE=ADVISOR
MODE=COMPACT_PROVIDER_SELECTION_DECISION
BASE_HEAD=c99e6587fec49ea88815f2bef0377dd0f229898f
UPSTREAM_HEAD=c99e6587fec49ea88815f2bef0377dd0f229898f
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=ADVISOR_SELECTION_ONLY;ONE_FEASIBILITY_TARGET;NO_IMPLEMENTATION;NO_VENDOR;NO_BUILD;NO_DOWNLOAD;NO_PRODUCT_MUTATION
ALLOWED_PATHS=handoffs/FSD_CLASSIFIER_PROVIDER_SELECTION_ADVISOR_R_20261006-175200.md|handoffs/CURRENT_HANDOFF.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl
DESKTOP_TRANSPORT=/Users/cenvu/Desktop/04_FSD_BRAIN.md
FORBIDDEN_PATHS=PRODUCTION;TESTS;DOCS;XCODE_PROJECT;SCHEMA;DEPENDENCY_FILES;VENDOR_MODEL_HELPER_ARTIFACTS;STATE/PROJECT_STATE.md;STATE/RULE_PROMOTION_LEDGER.tsv;PRIOR_HANDOFFS
SUCCESS_CRITERIA=EXACTLY_ONE_TARGET_OR_STOP;Q1_Q8_ANSWERED;FOUR_CANDIDATE_CHALLENGES;TASK029_CONTRACT;NO_FALSE_FINAL_SELECTION
VALIDATIONS=FRESH_FETCH_FF_ONLY_RECONCILE;PACKET_SECTIONS_READ;MAX_SIX_UPSTREAM_SLICES;REPOSITORY_DIFF_ALLOWLIST;CANONICAL_CHECKER;PUSH_FETCH_CLEAN_0_0;CURRENT_DESKTOP_PARITY
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
RESULT=PASS_WITH_ADVISORY
TECHNICAL_SHA=c99e6587fec49ea88815f2bef0377dd0f229898f
RESULT_AUTHORITY=ADVISOR_RECOMMENDATION_ONLY;NO_BRAIN_ACCEPTANCE;NO_PRODUCTION_PROVIDER

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=21
WORKER_REQUIREMENTS_EVIDENCED=21
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

## DECISION

DECISION=SELECT_ONE_FEASIBILITY_TARGET
FEASIBILITY_TARGET=CAND_05 filetype v1.1.3 (github.com/h2non/filetype, Go)

PROVIDER_PRODUCTION_SELECTED=NO
FEASIBILITY_TARGET_SELECTED=YES
MACOS15_RUNTIME_PROVEN=NO
INTEGRATION_AUTHORIZED=NO
SLICE08_AUTHORIZED=NO
NO_TIE_NO_RANKED_LIST=YES
MAGIKA=BLOCKED_REFERENCE_UNCHANGED
CAND_02_CAND_06_CAND_07_NOT_RESURRECTED=YES
MACOS15_PROVEN_FOR_ANY_CANDIDATE=NO

DECISIVE_INVARIANT=Enter feasibility with the candidate whose entire runtime trust surface is one exactly pinned, checksum-database-closed, zero-third-party-dependency MIT source tree: no external rules/model/database, no parser dependency, one notice, one ordered in-memory `Match([]byte)` entry point. Every other candidate adds a closure or truthfulness burden the spike would have to resolve first.

## Hard gates

All four eligible candidates pass the packet's hard gates (buffer-only entry point available, no internal source-path reopening, no runtime interpreter, no network/telemetry/downloader, no subprocess, permissive license). Common ground: MACOS15_PROVEN=NO for all four (packet U1). Optional `confidence=nil` and `modelVersion=nil` were not used to reject anyone. The decision therefore turns on qualitative factors A–G, applied without scoring, benchmarking or popularity.

## Packet correction found while challenging CAND_01 (decision-critical)

Primary-source reads (infer v0.22.0 Cargo.toml; crates.io sparse index for infer and cfb) contradict the packet's CAND_01 closure statement:

- FACT: infer 0.22.0 declares `cfb = { version = "0.14", optional = true }` with `default = ["std"]`, `std = ["alloc","cfb"]`. The packet's "transitive cfb 0.15.0 (checksum 0f13298d…)" cannot be what resolves; a caret requirement on 0.14 resolves cfb 0.14.0 (index checksum a347dcabdae9c31b0825fd6a8bed285ec9c2acb89c47827126d52fa4f59cece3). infer's own crates.io checksum f4200d43…01f4 is confirmed.
- FACT: cfb (0.14.0 and 0.15.0) itself depends on fnv ^1.0, uuid ^1 and web-time ^1. The packet's "dependency closure is cfb only / MIT-only sole dependency" is therefore incomplete; fnv/uuid/web-time (and their own closure) have no recorded license or checksum facts in task027. Their licenses are UNPROVEN here.
- FACT: with `default-features = false, features=["alloc"]` infer has zero dependencies, but then `ole2()` (src/matchers/doc.rs, `cfg(not(feature="std"))`) returns DOC for ANY buffer starting with the OLE2 magic. That would mislabel xls/ppt/msi/other CFB containers as DOC, which violates truthful output. The truthful infer configuration needs the cfb parser plus its closure.
- This is a closure/notice misstatement, not a change to infer's RESEARCH_FIT class. It is the factor that tips A and D away from infer. No other candidate row was found materially wrong; none resurrected.

## Q1–Q8

Q1 smallest unresolved external-artifact trust surface: filetype. Single module, no third-party dependency, no resource file, go.sum/sum.golang.org h1 closure recorded (h1:FKkx9QbD7HR/zjK1Ia5XiBsq9zdLi5Kf3zGyFTAFkGg=). infer (truthful mode) adds cfb+fnv+uuid+web-time; libmagic adds an unpinned generated magic.mgc; mimetype adds five dependency crates and a single-commit-history source.
Q2 natural Data<=4096 authority fit: filetype `Match(buf []byte)` is buffer-first, length-bounded and path/seek independent. `MatchFile`/`MatchReader` exist but are unused conveniences, and `MatchReader` pads to 8192 bytes, so the helper must call only `Match` (task029 must prove it). infer `get` and mimetype `detect` are equally buffer-only; mimetype internally truncates to 3072, below FSD's authority. libmagic's `magic_buffer` is buffer-only but needs a loaded database path (FSD-owned). No candidate is disqualified here, but filetype has no authority-related surplus surface to explain.
Q3 least new runtime/resource machinery: filetype, infer (std) and mimetype all need none; filetype adds only a build-time Go toolchain. libmagic alone needs resource generation, bundling, lookup and identity pinning.
Q4 smallest additional license/notice closure: filetype (one MIT notice). infer needs MIT plus cfb (MIT) plus unverified fnv/uuid/web-time; mimetype needs Apache-2.0 plus five dependency licenses; libmagic needs BSD-2 plus unresolved generated-database treatment.
Q5 most truthful unknown mapping: filetype. `types.Unknown` with nil error maps to not-classified; `ErrEmptyBuffer` maps to FSD's typed empty/unavailable outcome (host should not even invoke the helper for zero bytes unless the Slice03 seam requires it). infer's `None` is equally clean. mimetype's `application/octet-stream` ROOT fallback is indistinguishable from a legitimate positive without extra logic; libmagic's description-string tokenization is an invented-type risk (U4).
Q6 capability lost vs alternatives: libmagic's database breadth (359 Magdir sources, text/script/legacy descriptions); infer's actively released 91-type README enumeration and July 2026 release cadence; possible weaker deep container classification (the upstream `MatchReader` comment says an 8K buffer "makes msooxml tests happy", so OOXML subtype detection from a 4096-byte prefix may degrade to a generic container; unproven). The packet records only the filetype matcher package organization, not a documented type count.
Q7 acceptable for DEMO/Phase 1.5 selected-entry enrichment: yes, conditionally. Unknown/not-classified is an honest, already-contracted outcome, and enrichment (not authoritative identification) tolerates narrower coverage. Task029 must record the pinned matcher inventory so BRAIN can judge sufficiency. If the inventory is judged insufficient, the result is STOP/return to BRAIN, not a silent switch to another provider.
Q8 can one be selected now without another external architecture question: yes. filetype requires no artifact-identity, database-license or dependency-license question to be resolved first. The Go build toolchain is a build-time dependency the packaging contract already allows; its exact version and provenance are a task029 evidence item, not an architecture question.

## Candidate challenges

INFER (not selected). The cfb parser is real parsing of attacker-controlled bytes, but it is contained by the existing helper boundary and bounded to the supplied slice, so it alone is not a reason to reject infer. The reason infer is not first is the combination: truthful behavior requires cfb, cfb requires fnv/uuid/web-time whose license and checksum facts task027 never recorded, and the packet's pinned cfb version was wrong. 91 documented types is sufficient to justify a spike; coverage is not the objection. Rejecting `default-features` to drop cfb is not an option because it mislabels OLE2 as DOC.
LIBMAGIC (not selected). Maturity is real but not decisive. Task029 would first have to invent artifact identity (no upstream SHA-256; asc-only), settle generated-database license/notice treatment (U3), design stable tokenization of free-text descriptions (U4), build a C/FFI wrapper and ship a resource lookup path. That is multiple unresolved architecture decisions, too much for a first feasibility target while closed alternatives exist.
MIMETYPE (not selected). The small surface does not compensate: three commits all dated 2024-08-11, no tags/releases, one star, no CI, a five-crate dependency closure, an internal 3072-byte truncation below the 4096 authority, and an octet-stream ROOT fallback. Maintenance risk is a legitimate decision input here even though it is not a contract violation.
FILETYPE (selected). Stale release is manageable: pin exactly v1.1.3 (commit a977222ef406; sum.golang.org h1 recorded), never an unreleased repository commit. Static Go packaging is not materially more complex than a Rust helper under FSD's helper boundary: both produce a single Mach-O with no data files, both link libSystem, both need a build-time toolchain, and both need FSD-owned stdin/stdout framing. Go adds a runtime with multiple threads, which is not a subprocess or daemon. Source inspection (match.go, v1.1.3) shows deterministic ordered matcher iteration (`MatcherKeys`), which preserves reproducible results. `ErrEmptyBuffer` is a trivial typed mapping, not an obstacle.

## Task029 smallest feasibility contract

NAME=FSD_CLASSIFIER_NATIVE_FEASIBILITY_SPIKE_029
TARGET=filetype v1.1.3 only. No fallback or silent switch. Failure to prove any item returns evidence to BRAIN.
NOT_PRODUCTION=BundledMagikaClassificationProvider is not replaced; no Slice08; no Xcode project, docs, schema, tests-of-record, dependency-file or helper-in-app-bundle edit; no tracked vendor.
WORK_AREA=isolated scratch/build area outside tracked product paths (existing ignored scratch or a new ignored scratch directory), no tracked-tree mutation beyond the authorized evidence handoff files.
NETWORK_AUTHORITY=BRAIN must explicitly authorize module and Go toolchain acquisition for task029 (this task downloaded nothing). Module fetch only for the exact tag v1.1.3 with GOFLAGS=-mod=readonly, GOTOOLCHAIN pinned/local, verify go.sum and sum.golang.org h1.
Throwaway scratch helper: a minimal Go `main` that reads exactly the supplied bytes from stdin, calls `filetype.Match` only, and writes one bounded versioned result to stdout, shaped like the Slice03 seam without modifying the seam.

Required proofs, each EVIDENCED or UNPROVEN:

1. Native arm64 macOS 15 build: produce CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 binary on arm64 macOS 15+; record exact `go version`/toolchain identity.
2. No runtime interpreter: no Python/JVM/Node/Homebrew/$PATH lookup at runtime; observe executed processes.
3. Self-contained packaging shape: single Mach-O, no data/resource files; `otool -L` proves only system libraries; no resource lookup.
4. Exact dependency closure: `go list -deps`/go.mod/go.sum prove zero third-party module dependencies for the pinned module; record go.sum h1 and go.mod h1 for filetype.
5. Exact license/notice closure: verified MIT text at the pinned tag plus Go toolchain/runtime notice requirement for the redistributed binary (BSD-3-Clause Go license) recorded as an explicit notice item.
6. Inputs: Data-only 0-byte, small and exactly-4096-byte inputs; 4097+ bytes rejected/not passed by the host contract; no read beyond supplied length.
7. No path/source callback: source audit and runtime check that only `filetype.Match` is linked/called; `MatchFile`/`MatchReader`/os file opens in the helper path are absent (static symbol inspection and syscall/open observation).
8. Truthful known/unknown mapping: `Unknown`/nil error -> not-classified; `ErrEmptyBuffer` -> typed empty/unavailable outcome; no invented type; also verify truncated-container behavior (for example 4096-byte OOXML/zip/OLE-like synthetic prefixes) never over-claims.
9. Detector provenance: detectorVersion is host-owned text built from the pinned module version/commit and toolchain identity, not claimed as upstream-asserted; providerIdentifier remains host-owned.
10. `modelVersion=nil` for this model-free detector.
11. `confidence=nil`; no fabricated score.
12. No network/telemetry/downloader: static symbol/import audit plus runtime observation with network denied or monitored; no telemetry.
13. No subprocess/daemon/persistent descendants: process-tree observation including after cancellation/crash.
14. Actual helper binary architecture: `lipo -info`/`file` prove arm64 only.
15. Minimum deployment target: `vtool`/`otool -l` LC_BUILD_VERSION `minos` must be <= 15.0; record it.
16. Deterministic artifact identity: two controlled builds (identical flags such as -trimpath, -buildvcs=false, no buildid variance) produce identical SHA-256; record checksum, flags and toolchain.
17. Cancellation/crash behavior compatible with the existing Slice03 host seam: read the Slice03 protocol from the repository and demonstrate compatible exit/timeout/crash/output-bound behavior in scratch without changing the host seam.
18. Also record: the pinned module's registered matcher inventory (types/extensions) so BRAIN can judge Q6/Q7 sufficiency; no accuracy benchmark.
19. Also record: no sampled-byte persistence, hash or logging (helper does not write sampled bytes to stderr/files).

STOP_RULES=Any failed item is reported, not worked around. One repair retry max per failure family per the execution skill, then return to BRAIN. Do not substitute infer, libmagic or mimetype inside task029.

## Evidence limits and deviations

UPSTREAM_SLICES_USED=6 distinct read-only slices (infer Cargo.toml, crates.io sparse index for infer, infer src/lib.rs, crates.io sparse index for cfb, infer src/matchers/doc.rs, filetype v1.1.3 match.go); some were re-fetched via a second transport. DEVIATION=2 of the 6 (cfb sparse index and infer doc.rs) were not among the packet's named shortlist URLs; they were used only to resolve the concrete cfb-closure contradiction. No artifact was downloaded, built or executed. No filetype license/go.mod fact was newly verified in this task; those remain task027 packet facts (EVIDENCE=PACKET) and task029 proofs.
LOCAL_SYNC=local main was 3 commits behind origin/main at start (BRAIN-only state commits); reconciled by non-destructive fast-forward to c99e6587fec49ea88815f2bef0377dd0f229898f with a clean tree. PROJECT_STATE was re-read after the fast-forward.

## Ownership, limits and remaining issues

ADVISOR_RECOMMENDATION_ONLY=YES. BRAIN alone classifies and authorizes task029. No production code, tests, docs, schema, Xcode project, dependency, package manifest, helper/model/vendor artifact, PROJECT_STATE, RULE_PROMOTION_LEDGER or historical handoff was modified.
ADVISORY=task029 must prove arm64/macOS15 build and run, Go toolchain acquisition authority, OOXML/truncated-container behavior at 4096 bytes, and the full notice set including the Go toolchain's license. The BRAIN may also wish to record the CAND_01 closure correction against the task027 packet; this handoff does not edit that immutable packet.

## Proposed state delta and exactly one proposed next

PROPOSED_ACCEPTANCE=FSD_CLASSIFIER_PROVIDER_SELECTION_ADVISOR_028_PASS_WITH_ADVISORY
PROPOSED_NEXT_TASK=FSD_CLASSIFIER_NATIVE_FEASIBILITY_SPIKE_029 (identical to the single HOT PROPOSED_NEXT field)
PROPOSED_NEXT_CONTENT_SUMMARY_ONLY=Worker builds a throwaway scratch filetype v1.1.3 helper and returns the evidence defined by the 19-item contract above; no production integration.
PROPOSED_NEXT_NOT_STARTED=YES
