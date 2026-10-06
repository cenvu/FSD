# P15 Slice 07 external Magika verification — Architect STOP

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_P15_RUNTIME_SLICE_07_EXTERNAL_MAGIKA_VERIFICATION_A_20261006-110611.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=3ad6a2ffd0648585d2067ed1f3b6d8115aa03585
REMOTE_HEAD=3ad6a2ffd0648585d2067ed1f3b6d8115aa03585
LAST_VERIFIED_AT=2026-10-06T11:06:11+07:00
AUTHORITY_PTRS=AGENTS.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|STATE/PROJECT_STATE.md|docs/P15_RUNTIME_PLAN.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_P15_RUNTIME_SLICE_07_EXTERNAL_MAGIKA_VERIFICATION_025
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=MODEL_RIGHTS_UNRESOLVED;MODEL_SHA256_NOT_PUBLISHED_IN_INSPECTED_METADATA;MACOS13_UNPROVEN;DEPENDENT_RUNTIME_NOTICES_UNRESOLVED
PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_SLICE07_ARCHITECT_ESCALATION_ADJUDICATION
NO_AUTO_NEXT=YES

## Task lock and decision

TASK_ID=FSD_P15_RUNTIME_SLICE_07_EXTERNAL_MAGIKA_VERIFICATION_025
ROLE=ARCHITECT
MODE=EXTERNAL_INTEGRATION_VERIFICATION_RESEARCH_ONLY
BASE_HEAD=3ad6a2ffd0648585d2067ed1f3b6d8115aa03585
UPSTREAM_HEAD=3ad6a2ffd0648585d2067ed1f3b6d8115aa03585
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=EXTERNAL_FACT_GROUPS_A_K;SLICE06_LIMITS;RESEARCH_RETURN_ONLY
ALLOWED_PATHS=handoffs/FSD_P15_RUNTIME_SLICE_07_EXTERNAL_MAGIKA_VERIFICATION_A_20261006-110611.md|handoffs/CURRENT_HANDOFF.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl
DESKTOP_TRANSPORT=/Users/cenvu/Desktop/04_FSD_BRAIN.md
FORBIDDEN_PATHS=PRODUCTION;TESTS;DOCS;SCHEMA;XCODE_PROJECT;DEPENDENCIES;VENDOR_ARTIFACTS;STATE/PROJECT_STATE.md;STATE/RULE_PROMOTION_LEDGER.tsv;PRIOR_HANDOFFS
SUCCESS_CRITERIA=AUTHORITATIVE_FACT_LEDGER_AND_FIT_MATRIX;PASS_ONLY_IF_ALL_LOCKED_FACTS_VERIFIED;OTHERWISE_STOP_WITH_EXACT_GAPS;CANONICAL_FINALIZER_PUBLICATION
VALIDATIONS=READ_ONLY_OFFICIAL_SOURCE_METADATA;GIT_SCOPE_DIFF_CHECK;CANONICAL_CHECKER;PUSH_FETCH_CLEAN_0_0;CURRENT_DESKTOP_PARITY
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
RESULT=STOP
ARCHITECT_ESCALATION_REQUIRED=YES
INTEGRATION_CONTRACT_STATUS=NOT_READY
TECHNICAL_SHA=3ad6a2ffd0648585d2067ed1f3b6d8115aa03585
RESULT_AUTHORITY=ARCHITECT_RESEARCH_EVIDENCE_ONLY;NO_BRAIN_ACCEPTANCE

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=20
WORKER_REQUIREMENTS_EVIDENCED=14
WORKER_REQUIREMENTS_NOT_APPLICABLE=2
WORKER_REQUIREMENTS_UNPROVEN=4
WORKER_POSTFLIGHT=FAIL
NEXT_TASK_STARTED=NO

BLOCKING_FACTS=B1_MODEL_ARTIFACT_REDISTRIBUTION_GRANT;B2_EXACT_MODEL_AND_RESOURCE_SHA256;B3_MACOS13_MINIMUM_DEPLOYMENT;B4_DEPENDENT_NATIVE_RUNTIME_COMPONENT_LICENSE_NOTICE_SOURCE_OFFER_CLOSURE
CONFLICT_WITH_LOCKED_DESIGN=REQUIRED_VERIFIED_RUNTIME_AND_MODEL_REDISTRIBUTION;PINNED_SOURCE_MODEL_CHECKSUMS;MACOS13_COMPATIBILITY;KNOWN_COMPLETE_SELF_CONTAINED_RUNTIME_INVENTORY
SMALLEST_DECISION_REQUIRED_FROM_BRAIN=KEEP_SLICE07_CLOSED_AND_ADJUDICATE_THE_FOUR_EVIDENCE_GAPS;NO_IMPLEMENTATION_AUTHORIZATION

No established inherent bounded-input conflict was found. The selected native API can classify the supplied prefix as an independent byte buffer. STOP arises from required unresolved distribution/deployment facts, not a claim that all native Magika integrations are impossible. The ONNX full-framework build's 14.0 floor is a direct conflict for that particular artifact shape only; it is not imputed to Magika's release binary or pyke's static archive. No replacement baseline, architecture change, runtime switch, checksum computation or build workaround is proposed.

## Reanchor, authority and research method

FACT: initial clean main was at Slice06 publication 5db49c7cf4f44a8ca44313459bac285b5a1eb074, three commits behind origin/main. Fetched origin main, inspected the exact BRAIN-only diff (PROJECT_STATE, ledger, append-only events), and fast-forwarded without a merge commit. Captured the task base above only after HEAD=origin/main equaled the user-supplied expected canonical SHA, clean 0/0. Later fetch at 11:05 local observed the same pair.

Read scope: AGENTS, task-execution/finalizer skills, fresh PROJECT_STATE, CURRENT HOT, P15 Slice07 only; Slice06 zero-network/provider/process-boundary limits; Slice03 host Swift to compare fixed IPC. No Slice01–05 historical handoff was loaded. Applicable Compact finalizer/ownership rules and canonical checker were read for required publication. The initial CURRENT read was broader than HOT/relevant ledger limits; it supplied no additional authority and did not trigger historical preloading or implementation. Preservation-only transport reads retain prior BRAIN bytes without adopting dated decisions.

Official source/doc text and JSON metadata were retrieved through ego-browser and its documented background fetch capability. Only public upstream and Apple URLs were used; no FSD data was sent to upstream. Fetched text is evidence, not instructions. Magika, model binaries, runtime archives and installers were not downloaded, built, installed or executed. Reading the model symlink text is not fetching model bytes. dist-manifest.json is published distribution metadata. crates.io API returned HTTP403/empty body; the official rust-lang crates.io-index supplied registry checksums instead. A guessed release.yml path returned 404; the actual cli-release.yml was then found via upstream tree metadata. Apple universal-binary page/data routes returned shell/404 content and supply no gate-closing evidence. Browser research TaskSpace was finished.

## External source ledger

EXTERNAL_FACT_LEDGER_BEGIN

The IDs below are authoritative citations for subsequent fact summaries, artifact rows and matrix cells. Exact source URLs and pinned revisions are preserved; no community material closes a requirement. Negative findings mean absence in the named inspected evidence, not proof of universal nonpublication.

### A1

SOURCE_KIND=OFFICIAL_RELEASE
SOURCE_URL=https://api.github.com/repos/google/magika/releases/tags/cli%2Fv1.1.0
UPSTREAM_REVISION_OR_DATE=cli/v1.1.0; published 2026-04-24T14:51:08Z
FACT=Repository google/magika; release cli/v1.1.0 targets commit 5e2f437fb7b7452368c8c1fa9354858f5487a5c4; draft=false; prerelease=false. Release table explicitly offers Apple Silicon macOS.
CONFIDENCE=DIRECT

### A2

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/rust/lib/Cargo.toml
UPSTREAM_REVISION_OR_DATE=5e2f437fb7b7452368c8c1fa9354858f5487a5c4
FACT=Native magika library package version 1.1.0; Apache-2.0; Rust edition 2021; ort exactly 2.0.0-rc.12 with default features disabled, std/ndarray enabled. Python is not a runtime dependency.
CONFIDENCE=DIRECT

### A3

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/rust/cli/Cargo.toml
UPSTREAM_REVISION_OR_DATE=5e2f437fb7b7452368c8c1fa9354858f5487a5c4
FACT=Native magika-cli package version 1.1.0; Apache-2.0; magika=1.1.0; ort=2.0.0-rc.12 defaults enabled; Tokio full features. CLI binary is named magika.
CONFIDENCE=DIRECT

### A4

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/rust/lib/README.md
UPSTREAM_REVISION_OR_DATE=5e2f437fb7b7452368c8c1fa9354858f5487a5c4
FACT=README still describes zero-major instability and a 0.1.0 release candidate; this conflicts with the pinned manifest's 1.1.0 age/status. It also disclaims official Google support. Non-prerelease release metadata establishes the chosen published baseline, not a support guarantee.
CONFIDENCE=DIRECT

### B1

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/LICENSE
UPSTREAM_REVISION_OR_DATE=5e2f437fb7b7452368c8c1fa9354858f5487a5c4
FACT=Apache-2.0 sections 2 and 4 permit modification and source/object redistribution, require a license copy, change notices for modified files, retained applicable source notices, and carried NOTICE attribution if supplied. These terms do not require a source offer. Model-specific scope is not established by this generic root text.
CONFIDENCE=DIRECT

### B2

SOURCE_KIND=OFFICIAL_DOC
SOURCE_URL=https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/website-ng/src/content/docs/additional-resources/license.md
UPSTREAM_REVISION_OR_DATE=5e2f437fb7b7452368c8c1fa9354858f5487a5c4
FACT=License page describes the software as Apache-2.0. It does not expressly name standard_v3_3/model.onnx or grant separate model redistribution rights.
CONFIDENCE=DIRECT

### B3

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/assets/models/standard_v3_3/README.md
UPSTREAM_REVISION_OR_DATE=5e2f437fb7b7452368c8c1fa9354858f5487a5c4
FACT=Model README enumerates tool/model output spaces. No model-specific licensing or redistribution statement was found in this file; metadata/config and the pinned model directory likewise supply no such statement.
CONFIDENCE=DIRECT

### C1

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://api.github.com/repos/google/magika/git/trees/5e2f437fb7b7452368c8c1fa9354858f5487a5c4?recursive=1
UPSTREAM_REVISION_OR_DATE=5e2f437fb7b7452368c8c1fa9354858f5487a5c4
FACT=Complete tree metadata (truncated=false) supplies blob identities and byte sizes. Exact model.onnx is blob e669a1120903d93417f57a1aedd1bc0000819b8b, 3163737 bytes. This is a Git blob identity, not a SHA-256.
CONFIDENCE=DIRECT

### C2

SOURCE_KIND=OFFICIAL_PACKAGE_METADATA
SOURCE_URL=https://raw.githubusercontent.com/rust-lang/crates.io-index/master/ma/gi/magika
UPSTREAM_REVISION_OR_DATE=2026-10-06T11:06:11+07:00
FACT=Registry entry magika 1.1.0 is not yanked, published 2026-04-24T10:29:16Z, cksum=3aee5ecdbd182547ca3dfcd74c5bcd7f8c57384ad03cb79ef6e3bdf8d56abcdf. This authenticates the crate archive, not a separately extracted model's SHA-256.
CONFIDENCE=DIRECT

### C3

SOURCE_KIND=OFFICIAL_PACKAGE_METADATA
SOURCE_URL=https://raw.githubusercontent.com/rust-lang/crates.io-index/master/ma/gi/magika-cli
UPSTREAM_REVISION_OR_DATE=2026-10-06T11:06:11+07:00
FACT=Registry entry magika-cli 1.1.0 is not yanked, published 2026-04-24T10:29:28Z, cksum=7616caf20dbbcfadc9e669b78c02f372cb3c069c5fd6383af4c8dac002ff5f6c.
CONFIDENCE=DIRECT

### D1

SOURCE_KIND=OFFICIAL_RELEASE
SOURCE_URL=https://github.com/google/magika/releases/download/cli/v1.1.0/dist-manifest.json
UPSTREAM_REVISION_OR_DATE=cli/v1.1.0; 2026-04-24
FACT=Apple arm64 archive SHA-256=54b89c59e9ff024699066178c45e58d731833cc25b7c139b42857d5d31b7b804; archive contains magika executable. Build used Cargo 1.95.0 on macOS 15.7.4. Linkage lists only Apple/system libraries and frameworks; no minimum macOS load-command value or helper executable size is published here.
CONFIDENCE=DIRECT

### D2

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/pykeio/ort/blob/f085e4c2516901ee606d1e10022142afa9348bf1/Cargo.toml
UPSTREAM_REVISION_OR_DATE=f085e4c2516901ee606d1e10022142afa9348bf1
FACT=ort 2.0.0-rc.12 wraps ONNX Runtime 1.24; Rust minimum 1.88, edition 2024; MIT OR Apache-2.0. Default features include build-time binary downloading; runtime fetch-models is separate and optional.
CONFIDENCE=DIRECT

### D3

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/pykeio/ort/blob/f085e4c2516901ee606d1e10022142afa9348bf1/ort-sys/build/download/dist.txt
UPSTREAM_REVISION_OR_DATE=f085e4c2516901ee606d1e10022142afa9348bf1
FACT=Official wrapper metadata identifies an aarch64-apple-darwin ONNX 1.24.2 archive at https://cdn.pyke.io/0/pyke:ort-rs/ms@1.24.2/aarch64-apple-darwin.tar.lzma2 and published digest 612739f75438dc0a075461e1fb454226b4a1eb175e60a7271ba966bbbb972cd4. No binary was fetched. Deployment floor, component notice inventory and size are not supplied in this table.
CONFIDENCE=DIRECT

### D4

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/microsoft/onnxruntime/blob/058787ceead760166e3c50a0a4cba8a833a6f53f/tools/ci_build/github/apple/default_full_apple_framework_build_settings.json
UPSTREAM_REVISION_OR_DATE=ONNX v1.24.2; 058787ceead760166e3c50a0a4cba8a833a6f53f
FACT=Official ONNX Apple full-framework build settings list macosx arm64/x86_64 and apple_deploy_target=14.0. That particular framework build is incompatible with a macOS 13 floor. It does not establish the minimum of pyke's static archive or Magika's CLI.
CONFIDENCE=DIRECT

### E1

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/rust/lib/src/builder.rs
UPSTREAM_REVISION_OR_DATE=5e2f437fb7b7452368c8c1fa9354858f5487a5c4
FACT=Session builder loads model via commit_from_memory(include_bytes!(model.onnx)); generated configuration/type mappings are compiled into Rust. Session creation configures graph optimization and thread counts; no documented exact RAM or startup bound is given.
CONFIDENCE=DIRECT

### E2

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/rust/gen/model
UPSTREAM_REVISION_OR_DATE=5e2f437fb7b7452368c8c1fa9354858f5487a5c4
FACT=Generator model symlink points to ../../assets/models/standard_v3_3.
CONFIDENCE=DIRECT

### E3

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/rust/lib/src/model.onnx
UPSTREAM_REVISION_OR_DATE=5e2f437fb7b7452368c8c1fa9354858f5487a5c4
FACT=Library model symlink points to ../../gen/model/model.onnx; therefore pinned model bytes resolve to assets/models/standard_v3_3/model.onnx.
CONFIDENCE=DIRECT

### F1

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/rust/lib/src/session.rs
UPSTREAM_REVISION_OR_DATE=5e2f437fb7b7452368c8c1fa9354858f5487a5c4
FACT=Session::identify_content_sync(&mut self, file: impl SyncInput) returns Result<FileType>; content path extracts features and runs inference without identify_file's path/stat/open branch.
CONFIDENCE=DIRECT

### F2

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/rust/lib/src/input.rs
UPSTREAM_REVISION_OR_DATE=5e2f437fb7b7452368c8c1fa9354858f5487a5c4
FACT=SyncInput is implemented for &[u8] using slice length and copy_from_slice. Empty input returns Ruled(Empty). Nonempty extraction reads beginning and end blocks within that input length, then forms bounded features. Slice implementation performs no filesystem seek or additional source read.
CONFIDENCE=DIRECT

### F3

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/rust/lib/src/model.rs
UPSTREAM_REVISION_OR_DATE=5e2f437fb7b7452368c8c1fa9354858f5487a5c4
FACT=Generated config: beg_size=1024, end_size=1024, block_size=4096, min_file_size_for_dl=8, padding_token=256; 214 model labels. No random input transform is present in inspected extraction/mapping.
CONFIDENCE=DIRECT

### G1

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/rust/lib/src/file.rs
UPSTREAM_REVISION_OR_DATE=5e2f437fb7b7452368c8c1fa9354858f5487a5c4
FACT=FileType::info() yields final TypeInfo with label and mime_type after confidence/overwrite mapping. InferredType::score is model score 0..1; FileType::score() returns 1 for ruled outputs. Low confidence maps to Txt/Unknown according to textness; failures are Result errors, not unknown classifications.
CONFIDENCE=DIRECT

### G2

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/rust/lib/src/content.rs
UPSTREAM_REVISION_OR_DATE=5e2f437fb7b7452368c8c1fa9354858f5487a5c4
FACT=MODEL_NAME is exactly standard_v3_3; MODEL_MAJOR_VERSION=3 is coarser. TypeInfo for Unknown is label unknown and MIME application/octet-stream. Exact model name is distinct from detector package 1.1.0.
CONFIDENCE=DIRECT

### G3

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/rust/lib/src/error.rs
UPSTREAM_REVISION_OR_DATE=5e2f437fb7b7452368c8c1fa9354858f5487a5c4
FACT=Error variants are IO, ONNX Runtime and ndarray shape errors. No FSD result envelope or providerIdentifier exists in the library API.
CONFIDENCE=DIRECT

### H1

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/rust/cli/src/main.rs
UPSTREAM_REVISION_OR_DATE=5e2f437fb7b7452368c8c1fa9354858f5487a5c4
FACT=CLI initializes ort with telemetry(false); '-' reads stdin into a Vec and extracts slice features. Normal CLI requires arguments and returns its own path/result JSON structure. tasks.spawn refers to Tokio tasks, not child processes; no OS Command/fork, updater, daemon, watcher or network call was found in the inspected CLI entry source.
CONFIDENCE=DIRECT

### H2

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/pykeio/ort/blob/f085e4c2516901ee606d1e10022142afa9348bf1/ort-sys/build/main.rs
UPSTREAM_REVISION_OR_DATE=f085e4c2516901ee606d1e10022142afa9348bf1
FACT=ONNX archive downloader is in the build script; download-binaries links static onnxruntime. That source also supports user-provided libraries/dynamic linking. Build downloading must not be reported as runtime model downloading.
CONFIDENCE=DIRECT

### H3

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/pykeio/ort/blob/f085e4c2516901ee606d1e10022142afa9348bf1/src/session/builder/impl_commit.rs
UPSTREAM_REVISION_OR_DATE=f085e4c2516901ee606d1e10022142afa9348bf1
FACT=Model URL download/ureq path is gated behind fetch-models. Magika uses commit_from_memory; its declared library features and CLI defaults do not enable fetch-models.
CONFIDENCE=DIRECT

### H4

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/microsoft/onnxruntime/blob/058787ceead760166e3c50a0a4cba8a833a6f53f/docs/Privacy.md
UPSTREAM_REVISION_OR_DATE=ONNX v1.24.2; 058787ceead760166e3c50a0a4cba8a833a6f53f
FACT=Upstream states active platform telemetry is currently implemented for Windows builds; private source builds do not collect data. This is not observation of an FSD helper.
CONFIDENCE=DIRECT

### H5

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/microsoft/onnxruntime/blob/058787ceead760166e3c50a0a4cba8a833a6f53f/onnxruntime/core/platform/posix/env.cc
UPSTREAM_REVISION_OR_DATE=ONNX v1.24.2; 058787ceead760166e3c50a0a4cba8a833a6f53f
FACT=POSIX Env uses base Telemetry provider.
CONFIDENCE=DIRECT

### H6

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/microsoft/onnxruntime/blob/058787ceead760166e3c50a0a4cba8a833a6f53f/onnxruntime/core/platform/telemetry.cc
UPSTREAM_REVISION_OR_DATE=ONNX v1.24.2; 058787ceead760166e3c50a0a4cba8a833a6f53f
FACT=Base Telemetry IsEnabled returns false; inspected logging methods are stubs. Combined with H5, macOS path has no active telemetry collection in this source.
CONFIDENCE=STRONG_INFERENCE

### I1

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/pykeio/ort/blob/f085e4c2516901ee606d1e10022142afa9348bf1/src/environment.rs
UPSTREAM_REVISION_OR_DATE=f085e4c2516901ee606d1e10022142afa9348bf1
FACT=ONNX environment exposes process-local global/session thread pools and thread creation/join interfaces. These are threads, not evidence of descendant processes or a daemon.
CONFIDENCE=DIRECT

### I2

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/rust/lib/src/future.rs
UPSTREAM_REVISION_OR_DATE=5e2f437fb7b7452368c8c1fa9354858f5487a5c4
FACT=Synchronous inference polls immediate-ready work and runs session.run; inspected native library modules contain no OS subprocess-launch calls. This supports no inherent descendant requirement; it does not prove a built binary's process tree.
CONFIDENCE=STRONG_INFERENCE

### J1

SOURCE_KIND=APPLE_OFFICIAL
SOURCE_URL=https://developer.apple.com/library/archive/technotes/tn2206/_index.html
UPSTREAM_REVISION_OR_DATE=2026-10-06T11:06:11+07:00
FACT=TN2206 lists Contents/Helpers as a nested-code location, requires nested code signed before the outer app, and describes sealing resources/nested signatures. Data belongs in Contents/Resources; verification can use codesign with deep/strict. Model data is not separate executable code.
CONFIDENCE=DIRECT

### B4

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/microsoft/onnxruntime/blob/058787ceead760166e3c50a0a4cba8a833a6f53f/LICENSE
UPSTREAM_REVISION_OR_DATE=ONNX v1.24.2; 058787ceead760166e3c50a0a4cba8a833a6f53f
FACT=ONNX Runtime's own MIT license allows modification/redistribution with copyright and permission notice retained; it does not require a source offer. This alone does not settle bundled third-party component terms.
CONFIDENCE=DIRECT

### B5

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/microsoft/onnxruntime/blob/058787ceead760166e3c50a0a4cba8a833a6f53f/ThirdPartyNotices.txt
UPSTREAM_REVISION_OR_DATE=ONNX v1.24.2; 058787ceead760166e3c50a0a4cba8a833a6f53f
FACT=Upstream carries a large third-party notice collection, including component-specific redistribution/source-compliance material. The exact subset corresponding to pyke's arm64 static archive has not been established; a root MIT/Apache declaration cannot close that whole distribution gate.
CONFIDENCE=DIRECT

### C4

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/rust/lib/Cargo.lock
UPSTREAM_REVISION_OR_DATE=5e2f437fb7b7452368c8c1fa9354858f5487a5c4
FACT=Lockfile publishes exact ort and ort-sys registry versions2.0.0-rc.12 and respective archive checksums d7de3af33d24a745ffb8fab904b13478438d1cd52868e6f17735ef6e1f8bf133 and d7b497d21a8b6fbb4b5a544f8fadb77e801a09ae0add9e411d31c6f89e3c1e90. Optional/build/dev dependencies in a lockfile are not proof of enabled runtime capabilities.
CONFIDENCE=DIRECT

### D5

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/pykeio/ort/blob/f085e4c2516901ee606d1e10022142afa9348bf1/ort-sys/Cargo.toml
UPSTREAM_REVISION_OR_DATE=f085e4c2516901ee606d1e10022142afa9348bf1
FACT=ort-sys2.0.0-rc.12 declares MIT OR Apache-2.0, Rust1.88, build/main.rs, and optional ureq binary-downloader build dependencies. Its license does not by itself settle linked native artifact components.
CONFIDENCE=DIRECT

### I3

SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/dist-workspace.toml
UPSTREAM_REVISION_OR_DATE=5e2f437fb7b7452368c8c1fa9354858f5487a5c4
FACT=Distribution enables a separate installer updater and disables automatic README/LICENSE inclusion. These distribution settings are not runtime classification update calls or permission to omit required attribution.
CONFIDENCE=DIRECT

EXTERNAL_FACT_LEDGER_END

## A — Exact upstream baseline

UPSTREAM_REPOSITORY=https://github.com/google/magika
UPSTREAM_RELEASE_OR_TAG=cli/v1.1.0
UPSTREAM_COMMIT_SHA=5e2f437fb7b7452368c8c1fa9354858f5487a5c4
RELEASE_DATE=2026-04-24T14:51:08Z
STABILITY_STATUS=PUBLISHED_NON_DRAFT_NON_PRERELEASE_1.1.0;NOT_A_GOOGLE_SUPPORT_GUARANTEE
AUTHORITY=A1;A2;A3;C2;C3

Candidate validity: A1 pins a published non-prerelease CLI, manifests pin its matching native library, and registry metadata gives source package digests. It is a reproducible research baseline with a real Apple Silicon artifact, rather than the moving cli-latest channel. A4's stale zero-major README wording is recorded; it does not override the manifest/release identity. Candidate selection is not integration approval.

## B — Separate licensing determinations

RUNTIME_REDISTRIBUTION=MAGIKA_SOURCE_AND_CLI_YES_APACHE2;ORT_WRAPPER_YES_MIT_OR_APACHE2;ONNX_OWN_CODE_YES_MIT;COMPLETE_LINKED_DISTRIBUTION_UNRESOLVED
MODEL_REDISTRIBUTION=UNRESOLVED
NOTICE_REQUIREMENTS=MAGIKA_LICENSE_COPY;MODIFIED_FILE_NOTICES;RETAIN_APPLICABLE_COPYRIGHT_ATTRIBUTION;NOTICE_IF_UPSTREAM_SUPPLIES_ONE;ORT_SELECTED_LICENSE_COPY;ONNX_MIT_COPYRIGHT_PERMISSION;EXACT_LINKED_COMPONENT_NOTICES_UNRESOLVED
LICENSE_CONFLICT_WITH_FSD=UNRESOLVED
AUTHORITY=A2;A3;B1;B2;B3;B4;B5;D2

Client/runtime/source license and CLI redistribution: directly supported for Magika's own code under Apache-2.0. Modification/repackaging is permitted subject to those conditions (B1). No standalone Magika NOTICE was found in C1's full pinned tree; that does not waive dependent component notices. Root LICENSE is 11357 bytes, blob 7a4a3ea2424c09fbe48d455aed1eaa94d9124835. rust/lib/LICENSE and rust/cli/LICENSE are symlinks to that root license (C1). There is no source-offer obligation in the inspected Apache/MIT grants themselves. Exact linked-component source-offer/extra-text requirements remain UNRESOLVED (B5).

Embedded model/data license and model redistribution: B2 says software; B3/model metadata/config do not explicitly apply that license to the exact ONNX artifact. A2's package-level license and inclusion of src are insufficient under this task's separate explicit-model-rights rule. No model rights are inferred from repository membership or a crate checksum. B1 blocker remains.

Complete native runtime redistribution: ONNX's own MIT grant and ort's dual license are established; the exact pyke archive component licenses/notices and any extra source compliance are not. This is an additional required closure gap, not a finding that those licenses prohibit FSD.

## C — Artifact identities and missing checksums

Each row records ARTIFACT_NAME, UPSTREAM_LOCATION, VERSION, UPSTREAM_COMMIT, UPSTREAM_PUBLISHED_SHA256, OTHER_AUTHORITATIVE_IDENTITY, REDISTRIBUTION_LICENSE and authority. NOT_PUBLISHED denotes no individual SHA-256 found in the inspected authoritative metadata. No value was locally computed. This is an evidence inventory, not a vendoring allowlist.

| ARTIFACT_NAME | UPSTREAM_LOCATION | VERSION / UPSTREAM_COMMIT | UPSTREAM_PUBLISHED_SHA256 | OTHER_AUTHORITATIVE_IDENTITY | REDISTRIBUTION_LICENSE / AUTHORITY |
| --- | --- | --- | --- | --- | --- |
| magika native source crate | https://crates.io/crates/magika/1.1.0 | 1.1.0 / 5e2f437fb7b7452368c8c1fa9354858f5487a5c4 research baseline | 3aee5ecdbd182547ca3dfcd74c5bcd7f8c57384ad03cb79ef6e3bdf8d56abcdf | registry version; exact internal crate VCS record not inspected | own Rust code Apache-2.0; model scope unresolved / A2,C2 |
| magika-cli source crate (comparison candidate) | https://crates.io/crates/magika-cli/1.1.0 | 1.1.0 / 5e2f437fb7b7452368c8c1fa9354858f5487a5c4 research baseline | 7616caf20dbbcfadc9e669b78c02f372cb3c069c5fd6383af4c8dac002ff5f6c | registry version; upstream source rust/cli | own CLI Apache-2.0 / A3,C3 |
| Apple arm64 CLI archive (not direct host adapter) | https://github.com/google/magika/releases/download/cli/v1.1.0/magika-cli-aarch64-apple-darwin.tar.xz | cli/v1.1.0 / 5e2f437fb7b7452368c8c1fa9354858f5487a5c4 | 54b89c59e9ff024699066178c45e58d731833cc25b7c139b42857d5d31b7b804 | official release asset404531324; 7732708 bytes | own code Apache-2.0; embedded model/dependent notices unresolved / A1,D1 |
| exact model.onnx | https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/assets/models/standard_v3_3/model.onnx | standard_v3_3 / 5e2f437fb7b7452368c8c1fa9354858f5487a5c4 | NOT_PUBLISHED | Git blob e669a1120903d93417f57a1aedd1bc0000819b8b; 3163737 bytes | UNRESOLVED / B3,C1,E2,E3 |
| model configuration/labels | https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/assets/models/standard_v3_3/config.min.json | standard_v3_3 / 5e2f437fb7b7452368c8c1fa9354858f5487a5c4 | NOT_PUBLISHED | blob f33ef571d83e7c740c2033f7ed39d9d05cec2b77; 2141 bytes | artifact-specific rights unresolved / C1,F3 |
| model metadata | https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/assets/models/standard_v3_3/metadata.json | standard_v3_3 / 5e2f437fb7b7452368c8c1fa9354858f5487a5c4 | NOT_PUBLISHED | blob417994b5d89746427e37ca91d437773a5abceb98; 19 bytes; epoch91 | artifact-specific rights unresolved / C1 |
| generated label/MIME/type metadata | https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/rust/lib/src/content.rs | magika1.1.0/model standard_v3_3 / 5e2f437fb7b7452368c8c1fa9354858f5487a5c4 | NOT_PUBLISHED | blob bdc5ab0dbc7afe3af85f2e3f811e216e839f8927; 65193 bytes | Rust source Apache-2.0 / C1,G2 |
| generated inference config/thresholds | https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/rust/lib/src/model.rs | magika1.1.0/model standard_v3_3 / 5e2f437fb7b7452368c8c1fa9354858f5487a5c4 | NOT_PUBLISHED | blob d6bd5b4187c60c6f0bd68b120f1ba98c7affac6b; 20195 bytes | Rust source Apache-2.0 / C1,F3 |
| ort source crate | https://github.com/pykeio/ort/blob/f085e4c2516901ee606d1e10022142afa9348bf1/Cargo.toml | 2.0.0-rc.12 / f085e4c2516901ee606d1e10022142afa9348bf1 | d7de3af33d24a745ffb8fab904b13478438d1cd52868e6f17735ef6e1f8bf133 | pinned Magika rust/lib/Cargo.lock registry checksum | MIT OR Apache-2.0 / D2,https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/rust/lib/Cargo.lock |
| ort-sys source crate | https://github.com/pykeio/ort/blob/f085e4c2516901ee606d1e10022142afa9348bf1/ort-sys/Cargo.toml | 2.0.0-rc.12 / f085e4c2516901ee606d1e10022142afa9348bf1 | d7b497d21a8b6fbb4b5a544f8fadb77e801a09ae0add9e411d31c6f89e3c1e90 | pinned Magika rust/lib/Cargo.lock registry checksum | MIT OR Apache-2.0 / D2,https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/rust/lib/Cargo.lock |
| dependent ONNX static archive candidate | https://cdn.pyke.io/0/pyke:ort-rs/ms@1.24.2/aarch64-apple-darwin.tar.lzma2 | ms1.24.2; published by ortf085e4c2516901ee606d1e10022142afa9348bf1; ONNX source tag058787ceead760166e3c50a0a4cba8a833a6f53f | 612739f75438dc0a075461e1fb454226b4a1eb175e60a7271ba966bbbb972cd4 | exact wrapper distribution table; archive-internal provenance not inspected | ONNX own code MIT; exact archive third-party terms unresolved / D3,B4,B5 |
| remaining native source dependencies | https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/rust/lib/Cargo.lock | pinned individual versions in lock / 5e2f437fb7b7452368c8c1fa9354858f5487a5c4 | individual registry checksums present; complete artifact/license allowlist NOT_ESTABLISHED | generated dependency closure differs by selected build features | individual license/notice closure UNRESOLVED / A2,D2,B5 |
| FSD-owned thin helper | NO_ARTIFACT_CREATED | no approved version/target/source | NOT_PUBLISHED | design possibility only | FSD ownership; not upstream distribution |

Library source modules at the pinned tree are builder.rs, config.rs, content.rs, error.rs, file.rs, future.rs, input.rs, lib.rs, model.rs, session.rs plus model.onnx symlink and resolved asset. Their enclosing source-crate archive has a registry SHA-256; their individual Git blob identities are in C1. The model/config/metadata are upstream generator inputs; content.rs/model.rs are the compiled metadata used by the runtime (E1,F3,G2). Model README is documentation, not inference input.

Required missing identity B2: a published SHA-256 for the exact standard_v3_3/model.onnx bytes. The model's Git SHA-1, outer crate checksum, archive checksum and model name cannot silently substitute for that required individual asset checksum. Individual metadata identities/checksums and a complete selected dependency/notice inventory also are not closed. Stop rather than fetch a model and manufacture an unofficial digest.

## D/E — Native shape and footprint

NATIVE_COMPONENT=RUST_MAGIKA_1.1.0_LIBRARY_PLUS_POSSIBLE_THIN_FSD_HELPER;UPSTREAM_CLI_IS_COMPARISON_ONLY
BUILD_TOOLCHAIN=RUST_CARGO_AARCH64_APPLE_DARWIN;ORT_REQUIRES_RUST1.88_OR_NEWER;PUBLISHED_CLI_USED_CARGO1.95.0;EXACT_FSD_BUILD_PIN_NOT_AUTHORIZED
RUNTIME_DYNAMIC_DEPENDENCIES=PUBLISHED_CLI_MANIFEST_SYSTEM_AND_APPLE_FRAMEWORKS_ONLY;THIN_HELPER_ACTUAL_LINKAGE_UNPROVEN
MINIMUM_MACOS_SUPPORTED=UNRESOLVED_FOR_SELECTED_MAGIKA_OR_PYKE_ARTIFACT
ARM64_SUPPORT_EVIDENCE=OFFICIAL_RELEASE_AARCH64_APPLE_DARWIN;ORT_DIST_AARCH64_APPLE_DARWIN
SELF_CONTAINED_APP_BUNDLE_FEASIBLE=STRONG_INFERENCE_NATIVE_STATIC_SHAPE;REQUIRED_DEPLOYMENT_AND_DISTRIBUTION_FACTS_UNRESOLVED
MODEL_FOOTPRINT=3163737_BYTES_ONNX_EMBEDDED;UPSTREAM_TREE_METADATA_ONLY
OTHER_REQUIRED_RESOURCE_FOOTPRINT=GENERATED_SOURCE_CONTENT65193_MODEL20195_BYTES;NO_SEPARATE_RUNTIME_LABEL_JSON_IN_THIS_NATIVE_PATH;NATIVE_RUNTIME_AND_LICENSE_FOOTPRINT_UNRESOLVED
APP_BUNDLE_IMPACT_KNOWN=PARTIAL
AUTHORITY=A2;A3;C1;D1;D2;D3;D4;E1;E2;E3

D1 published linkage: /usr/lib/libSystem.B.dylib, libc++.1.dylib, libiconv.2.dylib, libobjc.A.dylib; CoreFoundation, CoreML and Foundation frameworks. That proves reported CLI linkage, not a future adapter's load commands or deployment floor. No user-installed Python, Homebrew or Magika is evidenced as a runtime requirement. Rust/ONNX are native components; native source-build preparation is separate from packaged runtime. The inspected upstream rust/onnx/build.sh uses Python/CMake to build Linux static libraries, not proof of a macOS helper runtime dependency.

D4's full-framework floor is 14.0. The generic live ONNX compatibility page discusses old tested Mac versions and is not specific proof for ONNX1.24.2/Magika1.1.0. Magika's release build host15.7.4 does not establish minOS13. No Mac13 guarantee is inferred from an architecture triple, Homebrew, system linkage or an untested deployment build flag.

Model loads from compiled bytes during Session construction. Generated Rust contains thresholds, labels and MIME data; runtime JSON lookup is absent in that path. ONNX native runtime must be linked/provided (D2,H2). Published archive7732708 bytes is compressed CLI distribution size, not helper size or model RAM. Final helper size, linked runtime footprint, RAM/startup/peak memory are unknown; no benchmark or timing promise is made. The complete selected linked-runtime component and license payload inventory has not been established from authoritative distribution metadata; required resource completeness therefore is not claimed.

## F — Bounded input fit

IN_MEMORY_BYTES_API=magika::Session::identify_content_sync(&mut_self,bytes_as_&[u8])->magika::Result<FileType>
ACCEPTS_0_BYTES=YES_RULED_EMPTY
ACCEPTS_UP_TO_4096=YES_SOURCE_GROUNDED
REQUIRES_PATH=NO_FOR_BYTE_SLICE_API
REQUIRES_MORE_BYTES=NO_BEYOND_SUPPLIED_SLICE
REQUIRES_SEEK=NO_FILESYSTEM_SEEK;YES_INTERNAL_OFFSET_INDEXING_WITHIN_SUPPLIED_SLICE
DETERMINISTIC_FOR_FIXED_INPUT_MODEL=STRONG_INFERENCE_PREPROCESS_AND_MAPPING;NO_BITWISE_FLOAT_REPRODUCIBILITY_GUARANTEE
AUTHORITY=F1;F2;F3;E1

FACT: SyncInput for &[u8] owns no source path or callback. Empty input maps to Empty without model inference. For nonempty bytes the read range is clamped to slice length; at4096 both4096-byte preprocessing blocks remain inside the same received buffer, yielding1024 head and1024 end features from that buffer. For shorter input padding/rules are used. STRONG_INFERENCE: all0..4096 sizes are implementable from the available bytes; no original-file tail, reopen, seek, name, fd or extra-read capability is needed. This is classification of the prefix buffer: its end is the prefix's end, not the real file's end. No whole-file equivalence or quality claim follows.

Fixed model/config/input gives fixed extraction and threshold mapping without randomness in inspected Rust; floating-point ONNX execution determinism across builds/platforms/providers was not verified. This is an explicit inference and non-benchmark limitation, not a new read-contract requirement.

## G — Output and provenance fit

DETECTED_TYPE_MAPPING=FileType.info().label_AFTER_UPSTREAM_OVERWRITE
MIME_MAPPING=FileType.info().mime_type_FROM_SAME_FINAL_TYPE
CONFIDENCE_MAPPING=INFERRED_SCORE_FINITE_0_1;RULED_NULL_TO_AVOID_FAKE_MODEL_PROBABILITY
UNKNOWN_MAPPING=SUCCESSFUL_CLASSIFIED_LABEL_UNKNOWN_MIME_APPLICATION_OCTET_STREAM;GENERIC_TEXT_LABEL_TXT;ERRORS_FAILED_NOT_UNKNOWN
DETECTOR_VERSION_SOURCE=PINNED_MAGIKA_LIBRARY_MANIFEST_VERSION1.1.0_AND_COMMIT
MODEL_VERSION_SOURCE=EXPORTED_MODEL_NAME_STANDARD_V3_3_PLUS_EXACT_MODEL_BLOB_PIN;NOT_PACKAGE_VERSION_OR_MAJOR3_OR_EPOCH91
PROVIDER_ID_HELPER_CONTROL=NO
AUTHORITY=A2;F2;G1;G2;G3;H1;LOCAL_HOST_SOURCE

These are truthful mapping possibilities, not approved adapter code. Model name is exact upstream version identity; artifact SHA-256/rights remain blocked independently. Model scores describe the original inferred class and can accompany a different final overwritten generic class; they must not be represented as calibrated posterior probability for the final generic label. Upstream score1 for rules is a rule score; host confidence may be null. Errors must use failed or truthful initialization-unavailable policy, with raw upstream diagnostics discarded/bounded by host contract; final initialization-error policy is not authorized here.

The host parses exactly seven scalar JSON fields: schemaVersion integer1, resultKind classified/unavailable/failed, detectedType, mimeType, confidence, detectorVersion, modelVersion. Text values are null or1..256 UTF8 bytes without controls; confidence is null or finite0..1; nonclassified fields are all null. No unknown resultKind or providerIdentifier is permitted. Seven compact fields can fit4096 bytes by construction, excluding descriptions/extensions and payload/path metadata. No actual output was emitted/tested. Unmodified upstream CLI is not a drop-in: host passes no args while CLI requires args, and CLI JSON includes path/result rather than the locked envelope. A native thin adapter is an API fit possibility, not permission to implement it.

## H/I — Offline and process evidence boundary

RUNTIME_NETWORK_REQUIRED=NO_SOURCE_STATIC_INFERENCE_FOR_PINNED_NATIVE_MEMORY_PATH
MODEL_DOWNLOAD_REQUIRED=NO_AT_RUNTIME;MODEL_IS_COMPILED_IN
TELEMETRY_PRESENT=NO_ACTIVE_MACOS_COLLECTION_IN_INSPECTED_SOURCE;TELEMETRY_API_AND_WINDOWS_IMPLEMENTATION_EXIST
OFFLINE_AFTER_BUNDLING=YES_SOURCE_STATIC_INFERENCE_CONDITIONAL_ON_COMPLETE_NATIVE_BUNDLING
SPAWNS_DESCENDANTS=NO_INHERENT_REQUIREMENT_FOUND_IN_NATIVE_CLASSIFICATION_PATH;RUNTIME_UNPROVEN
DAEMON=NO_SOURCE_STATIC_EVIDENCE
WATCHER=NO_SOURCE_STATIC_EVIDENCE
BACKGROUND_UPDATER=NO_CLASSIFICATION_PATH;UPSTREAM_INSTALLER_DISTRIBUTION_HAS_SEPARATE_UPDATER
PROCESS_TREE_FUTURE_RUNTIME_TEST_REQUIRED=YES
REAL_HELPER_NETWORK_OBSERVATION=NOT_PERFORMED
REAL_HELPER_PROCESS_TREE_OBSERVATION=NOT_PERFORMED
AUTHORITY=A2;A3;D2;H1;H2;H3;H4;H5;H6;I1;I2;I3

SOURCE_STATIC_EVIDENCE: inspected Magika native modules/CLI have no network/OS subprocess launch calls. ort's ureq runtime model fetch is optional/gated and not enabled on this memory path. ureq downloading also exists in build dependencies; Cargo.lock presence alone is not runtime network proof. Tokio full enables network capability in upstream CLI but does not establish invocation. ONNX macOS POSIX telemetry is stubbed and native CLI explicitly disables telemetry. No model/update/analytics network need was identified for one native-memory classification.

Pinned dist-workspace.toml (C1, https://github.com/google/magika/blob/5e2f437fb7b7452368c8c1fa9354858f5487a5c4/dist-workspace.toml) sets install-updater=true; D1 identifies a separate updater release artifact. It is not in D1's magika archive asset list or invoked by inspected main.rs. Installer/updater distribution must not be confused with classification runtime behavior. No updater is part of the locked FSD helper requirement. No runtime substitute or selective bundling plan is authorized by this STOP.

RUNTIME_OBSERVATION_REQUIRED_DURING_INTEGRATION: actual network attempts, telemetry and descendant lifetime must be observed during successful/error/crash/timeout/cancellation paths of the eventual signed helper. Source inspection and process-local threads do not prove a compiled helper's process tree. ONNX linked binary internals and execution-provider behavior are not exhaustively audited here; actual absence remains NOT_YET_PROVEN. No persistent descendants were established as an inherent requirement.

## J — Bounded placement/signing candidate, not implementation

HELPER_BUNDLE_LOCATION=FSD.app/Contents/Helpers/FSDClassificationHostSeam_CANDIDATE_MATCHING_EXISTING_FIXED_HOST_PATH
MODEL_BUNDLE_LOCATION=COMPILED_IN_HELPER_VIA_INCLUDE_BYTES;GENERATED_TYPE_CONFIG_COMPILED_IN;NO_EXTERNAL_MODEL_RESOURCE_APPROVED
HELPER_SIGNING_REQUIRED=YES_AS_NESTED_CODE_BEFORE_OUTER_APP_SIGNATURE
MODEL_CODE_SIGNING_REQUIRED=NO_SEPARATE_CODE_SIGNATURE_FOR_DATA;EMBEDDED_MODEL_PROTECTED_BY_HELPER_CODE_SIGNATURE
BUNDLE_RESOURCE_SEALING_CONSIDERATION=EXTERNAL_DATA_LICENSE_NOTICES_IN_CONTENTS_RESOURCES_ARE_SEALED_BY_OUTER_APP;MUTATION_AFTER_SIGNING_INVALIDATES_SEAL
AUTHORITY=J1;E1;E2;E3;LOCAL_HOST_SOURCE

Candidate licenses/attribution would be data in Contents/Resources; exact notice contents remain B4-blocked. Any future externalized model would be sealed data, not an unsigned executable, but upstream's actual candidate embeds it. No bundle change/copy/sign phase was created.

INTEGRATION_INSPECTION_COMMANDS=FUTURE_ONLY_NOT_RUN

```sh
file FSD.app/Contents/Helpers/FSDClassificationHostSeam
lipo -archs FSD.app/Contents/Helpers/FSDClassificationHostSeam
otool -L FSD.app/Contents/Helpers/FSDClassificationHostSeam
otool -l FSD.app/Contents/Helpers/FSDClassificationHostSeam
codesign --verify --strict --verbose=4 FSD.app/Contents/Helpers/FSDClassificationHostSeam
codesign --verify --deep --strict --verbose=4 FSD.app
codesign -d --verbose=4 FSD.app/Contents/Helpers/FSDClassificationHostSeam
```

These are Architect-proposed inspection commands only. Future inspection must verify arm64, every non-system library bundled, LC_BUILD_VERSION/LC_VERSION_MIN_MACOSX minOS no newer than13.0 for helper and linked code, nested signatures and resource seals. No such result exists now; no deployment claim is closed by naming a command.

## K — Fit against the locked Slice03 contract

FIT_MATRIX_BEGIN

YES means source-supported implementability (DIRECT or explicitly STRONG_INFERENCE), never runtime integration acceptance. Required UNRESOLVED keeps the gate closed; a documented NO applies only to the named artifact.

| LOCKED_REQUIREMENT | VERIFIED_MAGIKA_FACT | FIT | AUTHORITY |
| --- | --- | --- | --- |
| 0..4096 Data-only input | identify_content_sync accepts &[u8]; Empty rule; clamped offsets | YES | F1,F2,F3 |
| No path capability | Byte-slice implementation does not call identify_file/open/stat | YES | F1,F2 |
| No original tail/seek/additional-byte callback | End feature comes from received buffer only | YES | F2,F3 |
| Native arm64 | Exact Apple Silicon release and ort distribution target | YES | A1,D1,D3 |
| macOS13 minimum | No candidate minOS metadata; separate ONNX framework defaults14.0 | UNRESOLVED | D1,D3,D4 |
| No Python runtime/Homebrew/system Magika | Native Rust/ONNX manifests and reported system-only CLI linkage | YES | A2,A3,D1,D2 |
| Fully offline classification | Embedded model, memory inference; optional URL fetching disabled | YES (static inference) | E1,H2,H3 |
| No active telemetry | CLI disables it; ONNX POSIX provider is stubbed | YES (static inference) | H1,H4,H5,H6 |
| No daemon | No daemon path in inspected native invocation | YES (static inference) | H1,I1,I2 |
| No watcher/updater | No native classification watcher/updater call; installer updater separate | YES (static inference) | H1,D1,dist-workspace |
| No persistent descendants | No inherent process-spawn requirement found; real process observation future | YES (static inference) | H1,I1,I2;Slice06 limits |
| Fixed bundled separate process | Library can be called within one native helper at existing host path | YES (design inference) | A2,F1,J1;local host |
| Stdout<=4096 versioned metadata possible | Compact seven-field adapter is possible; CLI itself is incompatible | YES (adapter feasibility) | G1,G2,G3;local envelope |
| Upstream CLI unchanged as direct replacement | Requires args; emits path/result JSON | NO (direct CLI only) | H1;local host |
| Stderr diagnostic only<=4096 | Host already bounds/discards; no raw error/path need in adapter output | YES (design inference) | G3;Slice06 process ledger |
| Exact detected type | Final info().label including upstream overwrite | YES | G1,G2 |
| Exact MIME | Same final info().mime_type | YES | G1,G2 |
| Confidence | Inferred score, ruled null; generic overwritten score caveat explicit | YES | G1;local envelope |
| Exact detector version | Library manifest1.1.0 with pinned source SHA | YES | A2 |
| Exact distinct model version | MODEL_NAME=standard_v3_3; exact resolved model blob | YES | G2,C1,E2,E3 |
| Host-owned provider identity | Seven-field host schema rejects helper provider identity | YES | local host;Slice06 ledger |
| License permits runtime redistribution | Magika/ort/ONNX own grants yes; selected complete archive notices unclosed | UNRESOLVED | A2,A3,B1,B4,B5,D2,D3 |
| License permits model redistribution | No explicit exact-model rights grant in inspected material | UNRESOLVED | B2,B3 |
| Exact required source/model SHA256 | Crate/CLI/runtime archive digest available; individual model digest missing | UNRESOLVED | C1,C2,C3,D1,D3 |
| Self-contained app/resource inventory | Static native shape exists; exact components/notices/resources not closed | UNRESOLVED | D1,D2,D3,E1,B5 |
| Signed nested helper/sealed data | Apple placement/signing requirements can be followed; actual signing future | YES (contract feasibility) | J1 |

FIT_MATRIX_END

## Slice06 ledger consumption and preserved limits

HOST_SIDE_NETWORK_CAPABILITY=NONE
PROVIDER_PATH_AUTHORITY=DENIED
ADDITIONAL_BYTE_API=NONE
SOURCE_BYTES_MAX=4096
PROCESS_HOST_CAPS_ALREADY_TESTED=YES
REAL_HELPER_NETWORK_SIGNING_PROCESS_TREE=NOT_YET_PROVEN
SLICE06_TESTS_RERUN=NO

Authority: handoffs/FSD_P15_RUNTIME_SLICE_06_CROSS_WORKFLOW_SECURITY_REGRESSION_MATRIX_D_20261006-034630.md §9 zero_network_activity_during_classification, adversarial A/B/C, provenance paragraph and process-boundary regression ledger. Existing fake-runner tests credited there cover one raw stdin delivery+EOF, cumulative4096 stdout/stderr caps, malformed schema, cleanup/reap, fixed no-PATH resolution and host provenance ownership. Those are consumed as previously accepted host evidence, not freshly executed claims. They supply no helper license, actual binary, network, signing or descendant-process proof.

## Exact blockers and BRAIN decision boundary

1. B1 — standard_v3_3/model.onnx licensing/redistribution/attribution is unresolved under the explicit-model-rights rule. Authority B2/B3 offers generic software text and model output documentation, not the required artifact-specific application.
2. B2 — exact model SHA-256 is NOT_PUBLISHED in inspected official tree/model metadata/release/registry material; model/config/metadata individual digests and full selected artifact allowlist are not closed. The Git blob and outer package digests are recorded but do not close the required checksum gate.
3. B3 — native candidate macOS13 compatibility is not authoritatively established. Build-host15.7.4 and arm64 triples are insufficient; ONNX's separate full-framework14.0 build is directly incompatible for that shape. No build flag or dependency downgrade is invented.
4. B4 — exact dependent ONNX/ort linked-component distribution, notice/license/source-offer and auxiliary-resource closure is incomplete. Own-project Apache/MIT grants do not automatically establish the complete native distribution.

Smallest BRAIN decision is adjudication of STOP and continued closure of this integration gate. Any further fact collection or architecture decision must be separately bounded by BRAIN. There is no proposed implementation contract, no helper/source allowlist approval, and no Slice08 start. Future real-helper builds/tests/network/process/signature observations remain obligations if BRAIN later authorizes a verified integration; they were not performed in this research.

## Requirement map and postflight

| # | Requirement | Accounting / evidence |
| --- | --- | --- |
| 1 | Exact task/repo/main/base/fresh upstream | EVIDENCED; reanchor receipt |
| 2 | Locked research scope; protected state/history | EVIDENCED; base unchanged pre-mutation; exact four-path return only |
| 3 | A exact published baseline and stability qualifications | EVIDENCED; A1–A4,C2,C3 |
| 4 | B explicit model rights | UNPROVEN; blockerB1 |
| 5 | C required exact asset checksums | UNPROVEN; blockerB2 |
| 6 | D native arm64/macOS13 compatibility | UNPROVEN; blockerB3; arm64 component evidenced |
| 7 | B/D/E exact native components/resources/notices | UNPROVEN; blockerB4 |
| 8 | E footprint and unknown performance distinguished | EVIDENCED; C1,D1,E1; no benchmark |
| 9 | F bytes-only0/4096 API without source capability | EVIDENCED; F1–F3 |
| 10 | G exact truthful output/detector/model/host identity mapping | EVIDENCED; G1–G3,local host; score caveat |
| 11 | H source evidence distinct from real runtime proof | EVIDENCED; H1–H6; future observation explicit |
| 12 | I process/daemon/updater scope and future test | EVIDENCED; I1–I2,H1,D1; source-only limitations |
| 13 | J Apple placement/signing/sealing candidate | EVIDENCED; J1; no commands executed |
| 14 | K fit matrix with explicit gaps/conditional native adapter | EVIDENCED; matrix |
| 15 | Slice06 capability/process limits preserved; no rerun | EVIDENCED; exact ledger entries above |
| 16 | No code/test/project/dependency/artifact/tool install or execution | EVIDENCED; commands/source research only; scoped diff closure |
| 17 | STOP exact blockers/decision; no workaround/no next | EVIDENCED; decision section |
| 18 | PASS-only2–4-step implementation contract | NOT_APPLICABLE; STOP expressly forbids proposing one |
| 19 | Real helper Debug/Release/runtime/network/process tests now | NOT_APPLICABLE; forbidden in research and future integration obligations |
| 20 | One handoff/current/pending projection/Desktop/finalizer publication | EVIDENCED_BY_REQUIRED_CLOSURE_RECEIPT; receipts in Desktop after publication |

Guard counts reconcile20=14 evidenced+2 not applicable+4 unproven. WORKER_POSTFLIGHT FAIL means integration-fact closure failed; it is not a fabricated validation failure or missing authorization. Research record is complete enough to return STOP. Publication mechanics may PASS while this semantic gate remains closed.

Fresh execution postflight before finalizer: exact task requirements mapped; pinned source facts distinguished from inference/unproven runtime facts; required blockers preserved; candidate contains one proposal and one guard; no product test/build command performed. Canonical checker, immutable-history/scope verification, Git diff check, pending ledger/event projection, commit/push/fetch clean0/0 and exact CURRENT/Desktop/Operator parity are mandatory finalizer closure checks. Their actual receipts belong in Desktop and terminal return, not an invented future publication SHA in this immutable file.

PRODUCTION_DELTA=NONE
TEST_DELTA=NONE
PROJECT_DELTA=NONE
DEPENDENCY_DELTA=NONE
HELPER_MODEL_ARTIFACT_DELTA=NONE
DOC_SCHEMA_DELTA=NONE
ACCEPTED_PROJECT_STATE_DELTA=NONE
PROPOSED_STATE_DELTA=BRAIN_ADJUDICATE_STOP_AND_FOUR_REQUIRED_EXTERNAL_FACT_GAPS;NO_ACCEPTANCE_OR_ACTIVE_NEXT_AUTHORED
