# Classifier provider alternatives research — Architect fact packet

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_CLASSIFIER_PROVIDER_ALTERNATIVES_RESEARCH_A_20261006-173501.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=732027844a35715b4653faacaab66031c06bde3b
REMOTE_HEAD=732027844a35715b4653faacaab66031c06bde3b
LAST_VERIFIED_AT=2026-10-06T17:35:01+07:00
AUTHORITY_PTRS=AGENTS.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|STATE/PROJECT_STATE.md|docs/DECISIONS.md|docs/P15_RUNTIME_PLAN.md|docs/TEST_PLAN.md|docs/SECURITY_AND_READ_ONLY_POLICY.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_CLASSIFIER_PROVIDER_ALTERNATIVES_RESEARCH_027
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE
PROPOSED_NEXT=FSD_CLASSIFIER_PROVIDER_SELECTION_ADVISOR_028
NO_AUTO_NEXT=YES

## Task lock and decision

TASK_ID=FSD_CLASSIFIER_PROVIDER_ALTERNATIVES_RESEARCH_027
ROLE=ARCHITECT_RESEARCHER
MODE=EXTERNAL_PROVIDER_ALTERNATIVES_FACT_PACKET
BASE_HEAD=732027844a35715b4653faacaab66031c06bde3b
UPSTREAM_HEAD=732027844a35715b4653faacaab66031c06bde3b
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=EXTERNAL_FACT_PACKET_ONLY;CANDIDATE_MATRIX;NO_SELECTION;NO_IMPLEMENTATION;NO_PRODUCT_MUTATION
ALLOWED_PATHS=handoffs/FSD_CLASSIFIER_PROVIDER_ALTERNATIVES_RESEARCH_A_20261006-173501.md|handoffs/CURRENT_HANDOFF.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl
DESKTOP_TRANSPORT=/Users/cenvu/Desktop/04_FSD_BRAIN.md
FORBIDDEN_PATHS=PRODUCTION;TESTS;DOCS;XCODE_PROJECT;SCHEMA;DEPENDENCIES;PACKAGE_MANIFESTS;VENDOR_MODEL_HELPER_ARTIFACTS;STATE/PROJECT_STATE.md;STATE/RULE_PROMOTION_LEDGER.tsv;PRIOR_HANDOFFS
SUCCESS_CRITERIA=CITATION_BACKED_MATRIX_FOR_3_TO_6_CREDIBLE_CANDIDATES;PER_CANDIDATE_HARD_FACTS;FIT_CLASSIFICATION;MAGIKA_BLOCKED_BASELINE;APPLE_API_CHECK;MAGIC_DATABASE_SEPARATION;SECURITY_SURFACE;SHORTLIST_PACKET;NO_WINNER
VALIDATIONS=SOURCE_KIND_AND_URL_FOR_EVERY_HARD_EXTERNAL_FACT;PRIMARY_SOURCE_AUTHORITY_PRIORITY;NO_DOWNLOAD_OR_EXECUTION;REPOSITORY_DIFF_ALLOWLIST;CANONICAL_CHECKER;PUSH_FETCH_CLEAN_0_0;CURRENT_DESKTOP_PARITY
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
RESULT=PASS
TECHNICAL_SHA=732027844a35715b4653faacaab66031c06bde3b
RESULT_AUTHORITY=ARCHITECT_RESEARCH_EVIDENCE_ONLY;NO_BRAIN_ACCEPTANCE;NO_PROVIDER_SELECTED

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=24
WORKER_REQUIREMENTS_EVIDENCED=24
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

PROVIDER_SELECTED=NO
IMPLEMENTATION_STARTED=NO
PRODUCT_MUTATION=NONE
CANDIDATES_MATRIXD=5
RESEARCH_FIT_COUNT=4
NO_FIT_COUNT=2
UNRESOLVED_COUNT=1
MAGIKA_STATUS=BLOCKED_REFERENCE_REUSED_TASK025
RESEARCH_FIT_IDS=CAND_01_infer;CAND_03_libmagic_file_5_48;CAND_04_mimetype_hoslo_0_1_6;CAND_05_filetype_go_v1_1_3
NO_FIT_IDS=CAND_02_tree_magic_mini;CAND_06_APPLE_UTTYPE_METADATA_ONLY
UNRESOLVED_IDS=CAND_07_llama_cpp_plus_external_gguf
NOT_RESEARCHED_IDS=CAND_08_KMAGIC_primary_sources_unreachable_within_task
DOWNLOAD_OR_EXECUTION_PERFORMED=NO
MODEL_DOWNLOAD_PERFORMED=NO
PACKAGE_INSTALL_PERFORMED=NO
ACCURACY_BENCHMARK_PERFORMED=NO
RANKING_OR_SCORE_PERFORMED=NO

## RESEARCH_SCOPE_AND_LOCKED_CONTRACT

This packet gathers authoritative external evidence about credible native local file-classifier candidates so that a later independent Advisor can reason about selection. It selects nothing, implements nothing and changes no product surface.

Canonical floor and product authority (task 026A accepted at3e6f7d7, ADR-033): minimum supported macOS is 15.0, product wording "macOS 15 Sequoia or later", architecture arm64. ADR-033 is authoritative and states that no provider is selected.

Locked classification contract every candidate was tested against: trigger is an explicit selected-entry action only; FSD is the only source authority; the provider receives an immutable FSD-owned `Data` buffer of 0…4096 bytes and never receives path, URL, file descriptor, `FileHandle`, source identity, filesystem resolver, reader callback, range callback or any additional-byte API; source media stay read-only; no sample persistence, sample hashing, sample logging, source mutation, automatic classification, watcher, backfill, network-required runtime, telemetry, remote model lookup or runtime asset download; classification is inferred metadata only and is never historical content proof.

Packaging contract: runtime must be usable as one locally bundled helper process inside `FSD.app`, native arm64, macOS 15+, offline after bundling, self-contained, crash-isolated. Forbidden runtime requirements: Python, Java/JVM, Node, Homebrew, system package, user-installed classifier, `$PATH` lookup, app extension, daemon/service installation. A build-time compiler or toolchain dependency is permitted and reported, not automatically disqualifying. Runtime dependencies must be explicitly closed.

Provenance contract: `providerIdentifier` is host-owned and required; `detectorVersion`, `modelVersion`, `confidence` and MIME are optional. A model-free signature classifier is legitimate with `MODEL_VERSION=nil`, and a detector without a calibrated score is legitimate with `CONFIDENCE=nil`. Absence of confidence, MIME or model version is never a disqualifier. A classified result must still expose a meaningful detected type.

Existing host seam: Slice03 already provides a bounded bundled-helper process boundary (raw bounded bytes once on stdin, bounded versioned metadata result ≤4096 bytes on stdout, stderr diagnostic only and bounded/discarded, host owns `providerIdentifier`). A candidate need not natively speak that IPC; a thin FSD-owned helper wrapper may adapt a native buffer API, provided the candidate consumes only the bytes FSD supplies and never a source path.

Research method actually used: read-only HTTP retrieval of primary sources — official GitHub repository contents and raw files at pinned tags, the official crates.io sparse index and crates.io API metadata, the official Go checksum database, the official file(1) upstream distribution directory, and Apple developer documentation. Nothing was installed, downloaded as an artifact, built or executed. No candidate code, model or database was fetched. Community material was not used to close any hard fact. Model memory supplied no uncited fact in this packet.

Not-researched note: KMagic (KDE) was considered as a sixth candidate but its primary repository could not be reached through an authoritative endpoint within this task, so it is recorded as not researched rather than padded into the matrix with weaker sources.

## CANDIDATE_DISCOVERY

Discovery seeds used were: mature native signature/magic-database engines; model-free Rust/C/C++ libraries that classify from an in-memory buffer; compact native ML classifiers with straightforward redistribution; Apple-native APIs that classify from content bytes. Seeds were treated as starting points only.

Deliberately excluded before the matrix, without padding: Python-only classifiers, JVM-only classifiers such as Apache Tika, Node-only packages, extension/filename-only resolvers, and any solution requiring `$PATH`, a user install, an app extension or a daemon. These conflict with the packaging contract by construction and were not given matrix rows.

## CANDIDATE_FACT_MATRIX_BEGIN

### CAND_01 — infer

CANDIDATE_ID=CAND_01
PROJECT_NAME=infer
OFFICIAL_REPOSITORY=https://github.com/bojand/infer
LATEST_RELEVANT_STABLE_RELEASE=v0.22.0
PINNABLE_TAG_OR_COMMIT=tag v0.22.0 = commit cb05400c5f43e07200fbc1c5753e15946e9b1de8; crates.io artifact checksum f4200d433cbd5178df7797c9c2e75b348b728e39631cf14520d1e2fc424201f4
IMPLEMENTATION_LANGUAGE=Rust (edition 2021, rust-version 1.74, no build script, no C or C++ dependency)
MAINTENANCE_STATUS=ACTIVE; v0.22.0 published 2026-07-15, repository pushed 2026-07-15, ~128 million crates.io downloads
LICENSE_RUNTIME=MIT (LICENSE at tag: "MIT License, Copyright (c) 2019 Bojan")
LICENSE_DATA_OR_MODEL=NOT_APPLICABLE; detection rules are Rust source, no external data or model
REDISTRIBUTION_ALLOWED=YES; MIT with dependency closure MIT-only (sole dependency `cfb`, MIT, mdsteele/rust-cfb, crates.io cfb 0.15.0 checksum 0f13298d9178622b7916ec5d01d470425c04273c8ed07e87b1c38b34c4f4612b)
NOTICE_REQUIREMENTS=Retain MIT copyright and permission notice for infer and for the transitive cfb dependency
PACKAGE_OR_RELEASE_CHECKSUM_AVAILABLE=YES; official crates.io index checksum recorded above
EXTERNAL_RESOURCE_FILES=NONE
RESOURCE_LICENSE_CLOSED=YES; no external resource exists
RESOURCE_IDENTITY_CLOSED=NOT_APPLICABLE; no external resource
IN_MEMORY_BUFFER_API=infer::get(buf: &[u8]) -> Option<Type>; also Infer::get(&self, buf: &[u8]) -> Option<Type>, infer::is(buf,&str), infer::is_mime(buf,&str)
REQUIRES_PATH=NO for the buffer API; infer::get_from_path exists in the same crate and must never be called by an FSD helper
REQUIRES_FILENAME=NO
REQUIRES_SEEK=NO
REQUIRES_TAIL=NO
REQUIRES_FULL_FILE=NO
CAN_OPERATE_ON_0_TO_4096_PREFIX=YES; matchers are length-guarded byte predicates over the supplied slice, for example is_png requires only 4 bytes and is_jpeg2000 requires 13, so a 0…4096-byte prefix is a legal input; coverage for any matcher whose signature lies beyond the supplied prefix is simply reduced, which is a coverage property and not a contract violation
OUTPUT_TYPE_AVAILABLE=YES; `Type` enum with Type::mime_type() -> &'static str and Type::extension() -> &'static str
MIME_AVAILABLE=YES
CONFIDENCE_AVAILABLE=NO; the detector publishes no score. This is permitted; FSD would supply CONFIDENCE=nil
MODEL_PRESENT=NO
EXACT_DETECTOR_VERSION_SOURCE=crate version string of the pinned crate version, available at build time as the crate's declared version and reproducible from Cargo.lock; no upstream version constant is exposed by the API itself
EXACT_MODEL_VERSION_SOURCE=NOT_APPLICABLE
RUNTIME_NETWORK_REQUIRED=NO; no networking code or dependency exists; dependency closure is cfb only
TELEMETRY=NO
RUNTIME_DOWNLOADER=NO
RUNTIME_INTERPRETER_REQUIREMENT=NONE
NATIVE_ARM64_FEASIBILITY=YES as a language-level inference; pure Rust, no build script, no FFI, no platform-gated code
MACOS15_COMPATIBILITY_EVIDENCE=NONE upstream; repository CI runs ubuntu-latest only (no macOS runner, no macOS job), so no upstream statement covers macOS or arm64. Actual arm64/macOS 15 build and run evidence must be produced by a later authorized implementation task; this task may not build
SELF_CONTAINED_HELPER_FEASIBILITY=YES as an inference; a single statically linked helper binary carrying compiled-in rules needs no runtime data files, no interpreter, no network and no $PATH lookup
KNOWN_SUBPROCESS_OR_DAEMON_REQUIREMENT=NO
RUNTIME_PROCESS_TREE_PROOF_NEEDED=YES; a later implementation must still observe the helper's process tree at runtime
FORMAT_COVERAGE_DESCRIPTION=README "Supported types" section enumerates 91 documented types; matchers are organized as Rust modules app, archive, audio, book, doc, font, image, odf, text, video
UNKNOWN_FALLBACK_BEHAVIOR=infer::get returns Option::None when no matcher matches; a helper must map None to the FSD typed "not classified / unavailable" outcome rather than inventing a type
FIT=RESEARCH_FIT

### CAND_02 — tree_magic_mini

CANDIDATE_ID=CAND_02
PROJECT_NAME=tree_magic_mini
OFFICIAL_REPOSITORY=https://github.com/mbrubeck/tree_magic (branch "mini")
LATEST_RELEVANT_STABLE_RELEASE=3.2.2
PINNABLE_TAG_OR_COMMIT=tag v3.2.2; crates.io checksum b8765b90061cba6c22b5831f675da109ae5561588290f9fa2317adab2714d5a6
IMPLEMENTATION_LANGUAGE=Rust (edition 2024, rust-version 1.85)
MAINTENANCE_STATUS=ACTIVE; 3.2.2 published 2025-11-14, repository pushed 2025-11-14
LICENSE_RUNTIME=MIT for tree_magic_mini itself
LICENSE_DATA_OR_MODEL=tree_magic_db is GPL-2.0-or-later and packages the FreeDesktop.org shared MIME database
REDISTRIBUTION_ALLOWED=NO for the only configuration that carries real detection data; see HARD_CONFLICTS
NOTICE_REQUIREMENTS=MIT notice for the library; GPL-2.0-or-later obligations plus the shared-mime-info database's own terms if the data path is used
PACKAGE_OR_RELEASE_CHECKSUM_AVAILABLE=YES for both crates
EXTERNAL_RESOURCE_FILES=FreeDesktop.org shared MIME database files (magic, aliases, subclasses) read at runtime in the default build; the same content optionally embedded via the tree_magic_db crate behind the `with-gpl-data` feature
RESOURCE_LICENSE_CLOSED=NO; the README states plainly that "the magic database files themselves are licensed under the GPL, you must make sure your project uses a compatible license if you enable this behaviour"
RESOURCE_IDENTITY_CLOSED=NO; runtime-loaded files are read from operator-controlled standard locations with no pin and no checksum
IN_MEMORY_BUFFER_API=tree_magic_mini::from_u8(bytes: &[u8]) -> Mime, plus match_u8(mimetype: &str, bytes: &[u8]) -> bool
REQUIRES_PATH=NO for from_u8 itself, but the library internally resolves and reads filesystem paths to obtain its rule set
REQUIRES_FILENAME=NO
REQUIRES_SEEK=NO
REQUIRES_TAIL=NO
REQUIRES_FULL_FILE=NO
CAN_OPERATE_ON_0_TO_4096_PREFIX=UNRESOLVED in practice; the buffer API exists but the rule set is empty unless an external database is present, and `from_u8` panics with "No filetype definitions are loaded." when no external definitions load
OUTPUT_TYPE_AVAILABLE=YES; a MIME string
MIME_AVAILABLE=YES
CONFIDENCE_AVAILABLE=NO
MODEL_PRESENT=NO in the library; the shared-mime-info magic database is the detection data
EXACT_DETECTOR_VERSION_SOURCE=crate version 3.2.2; the upstream shared-mime-info database version, which actually determines results, is not tracked by the crate
EXACT_MODEL_VERSION_SOURCE=UNRESOLVED; the effective data version is whatever shared-mime-info the host filesystem happens to provide
RUNTIME_NETWORK_REQUIRED=NO
TELEMETRY=NO
RUNTIME_DOWNLOADER=NO
RUNTIME_INTERPRETER_REQUIREMENT=NONE
NATIVE_ARM64_FEASIBILITY=YES as a language-level inference
MACOS15_COMPATIBILITY_EVIDENCE=NOT APPLICABLE; excluded before compatibility matters
SELF_CONTAINED_HELPER_FEASIBILITY=NO in the default configuration; see HARD_CONFLICTS
KNOWN_SUBPROCESS_OR_DAEMON_REQUIREMENT=NO
RUNTIME_PROCESS_TREE_PROOF_NEEDED=NOT_APPLICABLE
FORMAT_COVERAGE_DESCRIPTION=coverage is whatever the host's shared-mime-info database provides, so it is host-dependent rather than a property of the pinned library
UNKNOWN_FALLBACK_BEHAVIOR=none/panic rather than a neutral unknown result, which is incompatible with deterministic FSD typed outcomes
FIT=NO_FIT

### CAND_03 — libmagic / file(1)

CANDIDATE_ID=CAND_03
PROJECT_NAME=libmagic (file)
OFFICIAL_REPOSITORY=https://astron.com/pub/file/ (upstream distribution, maintained by Christos Zoulas); https://github.com/file/file is the official read-only CVS mirror
LATEST_RELEVANT_STABLE_RELEASE=file-5.48
PINNABLE_TAG_OR_COMMIT=release tarball file-5.48.tar.gz dated 2026-06-07 19:49 on the upstream directory; the CVS mirror's master ChangeLog carries entries dated 2026-08-28; a detached file-5.48.tar.gz.asc signature is published; no published SHA-256 exists for the tarball
IMPLEMENTATION_LANGUAGE=C (POSIX/autoconf; libmagic is the library, file(1) the CLI)
MAINTENANCE_STATUS=ACTIVE; upstream tarball 2026-06-07, mirror pushed 2026-08-28
LICENSE_RUNTIME=BSD-2-Clause; the project's COPYING states redistribution in source and binary form is permitted provided the copyright notice, conditions and disclaimer are reproduced
LICENSE_DATA_OR_MODEL=the magic database is generated from the project's own magic/Magdir source entries under the same BSD-2-Clause terms; 359 Magdir entries exist at master
REDISTRIBUTION_ALLOWED=YES; permissive BSD-2-Clause, with the obligation to reproduce the notice in distributed materials
NOTICE_REQUIREMENTS=Reproduce the file(1) copyright notice, conditions and disclaimer in documentation or other distributed materials
PACKAGE_OR_RELEASE_CHECKSUM_AVAILABLE=NO; upstream publishes file-5.48.tar.gz.asc but file-5.48.tar.gz.sha256 and .sha256sum both return 404
EXTERNAL_RESOURCE_FILES=magic.mgc, the compiled magic database, produced from magic/Magdir; the project README describes it as shared data that is not machine code and included in release packaging
RESOURCE_LICENSE_CLOSED=UNRESOLVED; the generated database derives from BSD-2-Clause Magdir sources, but the generated artifact's own license and notice treatment should be confirmed explicitly rather than assumed from the root license
RESOURCE_IDENTITY_CLOSED=NO; upstream publishes no checksum for the tarball or for a prebuilt magic.mgc. A pin would have to be established by building magic.mgc from a pinned source revision and recording the sha256 of the locally produced artifact, which is implementation-time work
IN_MEMORY_BUFFER_API=const char *magic_buffer(magic_t, const void *, size_t) declared in src/magic.h.in, with magic_open, magic_load, magic_setflags, magic_compile and magic_version
REQUIRES_PATH=NO for magic_buffer; magic_file(magic_t, const char *) exists in the same API and must never be called by an FSD helper. magic_load takes the path of FSD's own bundled database resource, never a source path
REQUIRES_FILENAME=NO
REQUIRES_SEEK=NO
REQUIRES_TAIL=NO; magic rules that need bytes beyond the supplied slice simply do not match
REQUIRES_FULL_FILE=NO
CAN_OPERATE_ON_0_TO_4096_PREFIX=YES as an inference from the buffer API and rule semantics; truncated input reduces rule coverage but does not violate the API contract
OUTPUT_TYPE_AVAILABLE=YES; a description string, from which the leading type token and, with MAGIC_MIME_TYPE, the MIME type are derivable
MIME_AVAILABLE=YES
CONFIDENCE_AVAILABLE=NO; libmagic has no calibrated score output
MODEL_PRESENT=NO in the ML sense; the magic database is a signature rule set
EXACT_DETECTOR_VERSION_SOURCE=magic_version(int) reports the compiled library version, so the exact detector version is obtainable at runtime from the library itself
EXACT_MODEL_VERSION_SOURCE=value source; the magic database has no upstream version identifier published alongside the artifact, so database identity would rest on the sha256 of the bundled magic.mgc computed at build time
RUNTIME_NETWORK_REQUIRED=NO; libmagic performs no network access and has no runtime fetcher
TELEMETRY=NO
RUNTIME_DOWNLOADER=NO
RUNTIME_INTERPRETER_REQUIREMENT=NONE
NATIVE_ARM64_FEASIBILITY=YES as an inference; portable C with no platform-specific dependencies; the project's INSTALL documents macOS builds including fat/universal binaries, though that guidance is legacy (10.5, i386/ppc era) and is not arm64 or macOS 15 evidence
MACOS15_COMPATIBILITY_EVIDENCE=PARTIAL upstream: macOS buildability is documented in INSTALL; nothing upstream states macOS 15 or arm64 support. A real arm64/macOS 15 build remains implementation-time proof
SELF_CONTAINED_HELPER_FEASIBILITY=YES as an inference provided magic.mgc is generated from pinned sources and bundled inside the helper's resource directory
KNOWN_SUBPROCESS_OR_DAEMON_REQUIREMENT=NO
RUNTIME_PROCESS_TREE_PROOF_NEEDED=YES
FORMAT_COVERAGE_DESCRIPTION=359 Magdir source files at master covering legacy magic plus FreeDesktop-style rules; the breadth of the generated database is the coverage claim and was not measured
UNKNOWN_FALLBACK_BEHAVIOR=magic_buffer returns NULL when nothing matches or on error, and magic_error/magic_errno distinguish error from no-match; a helper must map NULL-with-error to FSD `.failed` and NULL-without-error to not-classified rather than inventing a type
FIT=RESEARCH_FIT

### CAND_04 — mimetype (hoslo)

CANDIDATE_ID=CAND_04
PROJECT_NAME=mimetype
OFFICIAL_REPOSITORY=https://github.com/hoslo/mimetype
LATEST_RELEVANT_STABLE_RELEASE=0.1.6
PINNABLE_TAG_OR_COMMIT=crates.io artifact checksum ad81b1e703d84473c6b6e6b8999ede6b9a918662ba7d89d9970c036bb72edd17; the repository has no tags or releases, so only the registry artifact is pinnable
IMPLEMENTATION_LANGUAGE=Rust (edition 2021, no build script)
MAINTENANCE_STATUS=STALE; the three most recent commits are all dated 2024-08-11 and titled "first version", repository has one star and no CI configuration. This is a material Advisor risk, not a hard-contract conflict
LICENSE_RUNTIME=Apache-2.0 (Cargo.toml and LICENSE)
LICENSE_DATA_OR_MODEL=NOT_APPLICABLE; detectors are Rust source under src/magic
REDISTRIBUTION_ALLOWED=YES; Apache-2.0 with a permissive dependency closure (parking_lot MIT OR Apache-2.0, serde MIT OR Apache-2.0, serde_json MIT OR Apache-2.0, quick-xml MIT, byteorder Unlicense OR MIT)
NOTICE_REQUIREMENTS=Apache-2.0 notice and license text; Apache-2.0 §4 obligations
PACKAGE_OR_RELEASE_CHECKSUM_AVAILABLE=YES; official crates.io index checksum recorded above
EXTERNAL_RESOURCE_FILES=NONE
RESOURCE_LICENSE_CLOSED=YES; no external resource exists
RESOURCE_IDENTITY_CLOSED=NOT_APPLICABLE; no external resource
IN_MEMORY_BUFFER_API=mimetype::detect(content: &[u8]) -> Mime; Mime exposes public fields mime: String, aliases: Vec<String>, extension: String. A reader variant detech_from_reader exists and is unnecessary for FSD
REQUIRES_PATH=NO; the crate exposes no path-based detection entry point
REQUIRES_FILENAME=NO
REQUIRES_SEEK=NO
REQUIRES_TAIL=NO
REQUIRES_FULL_FILE=NO; detect() internally truncates to a rate limit whose default is 3072 bytes, which is inside FSD's 4096-byte budget
CAN_OPERATE_ON_0_TO_4096_PREFIX=YES; detectors are prefix/offset byte predicates over the supplied slice and the library's own default limit of 3072 bytes is smaller than FSD's ceiling
OUTPUT_TYPE_AVAILABLE=YES
MIME_AVAILABLE=YES
CONFIDENCE_AVAILABLE=NO
MODEL_PRESENT=NO
EXACT_DETECTOR_VERSION_SOURCE=crate version 0.1.6 available at build time from Cargo.lock
EXACT_MODEL_VERSION_SOURCE=NOT_APPLICABLE
RUNTIME_NETWORK_REQUIRED=NO; no networking dependency exists (tokio is optional and only for the async reader feature)
TELEMETRY=NO
RUNTIME_DOWNLOADER=NO
RUNTIME_INTERPRETER_REQUIREMENT=NONE
NATIVE_ARM64_FEASIBILITY=YES as a language-level inference; pure Rust, no build script, no FFI
MACOS15_COMPATIBILITY_EVIDENCE=NONE upstream; no CI at all, no macOS or arm64 statement. Build proof is implementation-time work
SELF_CONTAINED_HELPER_FEASIBILITY=YES as an inference; compiled-in detectors, no runtime data, no interpreter
KNOWN_SUBPROCESS_OR_DAEMON_REQUIREMENT=NO
RUNTIME_PROCESS_TREE_PROOF_NEEDED=YES
FORMAT_COVERAGE_DESCRIPTION=detectors are organized as Rust modules archive, audio, base, binary, ftyp, image, text and are compiled into a detection tree
UNKNOWN_FALLBACK_BEHAVIOR=detect() returns the tree ROOT Mime when nothing matches, which is application/octet-stream; a helper must distinguish that documented fallback from a genuine positive match rather than reporting octet-stream as a detected type
FIT=RESEARCH_FIT

### CAND_05 — filetype (Go)

CANDIDATE_ID=CAND_05
PROJECT_NAME=filetype
OFFICIAL_REPOSITORY=https://github.com/h2non/filetype
LATEST_RELEVANT_STABLE_RELEASE=v1.1.3
PINNABLE_TAG_OR_COMMIT=tag v1.1.3 = commit a977222ef406; official Go checksum database entry github.com/h2non/filetype v1.1.3 h1:FKkx9QbD7HR/zjK1Ia5XiBsq9zdLi5Kf3zGyFTAFkGg=
IMPLEMENTATION_LANGUAGE=Go (module github.com/h2non/filetype, go 1.13 directive)
MAINTENANCE_STATUS=ACTIVE repository (pushed 2026-07-01) with a stale release tag (v1.1.3); CI runs ubuntu-latest on Go 1.19–1.21 with no macOS runner
LICENSE_RUNTIME=MIT (LICENSE at tag v1.1.3: "The MIT License, Copyright (c) Tomas Aparicio")
LICENSE_DATA_OR_MODEL=NOT_APPLICABLE; matchers are Go source
REDISTRIBUTION_ALLOWED=YES; MIT with no third-party runtime dependency
NOTICE_REQUIREMENTS=Retain the MIT notice
PACKAGE_OR_RELEASE_CHECKSUM_AVAILABLE=YES; the Go module ecosystem publishes content-addressed h1 checksums through sum.golang.org, recorded above
EXTERNAL_RESOURCE_FILES=NONE
RESOURCE_LICENSE_CLOSED=YES; no external resource exists
RESOURCE_IDENTITY_CLOSED=NOT_APPLICABLE; no external resource
IN_MEMORY_BUFFER_API=func Match(buf []byte) (types.Type, error), aliased as Get; types.Type carries exported fields MIME types.MIME and Extension string
REQUIRES_PATH=NO for Match; MatchFile(filepath string) exists in the same package and must never be called by an FSD helper
REQUIRES_FILENAME=NO
REQUIRES_SEEK=NO
REQUIRES_TAIL=NO
REQUIRES_FULL_FILE=NO
CAN_OPERATE_ON_0_TO_4096_PREFIX=YES; Match iterates in-memory matcher funcs over the supplied slice and returns ErrEmptyBuffer only for a zero-length buffer
OUTPUT_TYPE_AVAILABLE=YES
MIME_AVAILABLE=YES
CONFIDENCE_AVAILABLE=NO
MODEL_PRESENT=NO
EXACT_DETECTOR_VERSION_SOURCE=module version tag v1.1.3, recordable at build time via Go module build info
EXACT_MODEL_VERSION_SOURCE=NOT_APPLICABLE
RUNTIME_NETWORK_REQUIRED=NO; the library has no network code and Go builds a static native binary
TELEMETRY=NO
RUNTIME_DOWNLOADER=NO
RUNTIME_INTERPRETER_REQUIREMENT=NONE at runtime; a Go toolchain is required only at build time, which the packaging contract permits and this packet reports rather than hides
NATIVE_ARM64_FEASIBILITY=YES as a language-level inference; cross-compiling to darwin/arm64 is standard Go toolchain output
MACOS15_COMPATIBILITY_EVIDENCE=NONE upstream; CI is Linux-only with no macOS or arm64 statement. Build proof is implementation-time work
SELF_CONTAINED_HELPER_FEASIBILITY=YES as an inference; a static Go binary with no data files and no runtime dependency
KNOWN_SUBPROCESS_OR_DAEMON_REQUIREMENT=NO
RUNTIME_PROCESS_TREE_PROOF_NEEDED=YES
FORMAT_COVERAGE_DESCRIPTION=matchers are organized as Go source packages application, archive, audio, document, font, image, isobmff and video
UNKNOWN_FALLBACK_BEHAVIOR=Match returns types.Unknown with a nil error when nothing matches, and ErrEmptyBuffer for an empty buffer; a helper must map Unknown to not-classified and an empty buffer to the FSD typed outcome rather than inventing a type
FIT=RESEARCH_FIT

### CAND_06 — Apple type-identification APIs (UniformTypeIdentifiers / LaunchServices metadata)

CANDIDATE_ID=CAND_06
PROJECT_NAME=UniformTypeIdentifiers (UTType) and related system type metadata
OFFICIAL_REPOSITORY=https://developer.apple.com/documentation/uniformtypeidentifiers
LATEST_RELEVANT_STABLE_RELEASE=macOS 15 SDK surface
PINNABLE_TAG_OR_COMMIT=Apple developer documentation as published; macOS 15 (SDK MacOSX15.x) documentation revision
IMPLEMENTATION_LANGUAGE=platform framework (Swift/Objective-C API surface)
MAINTENANCE_STATUS=Apple-supported platform API
LICENSE_RUNTIME=Apple platform terms; not an open-source redistribution candidate
LICENSE_DATA_OR_MODEL=NOT_APPLICABLE
REDISTRIBUTION_ALLOWED=NOT_APPLICABLE; it is a system framework call, not a redistributable dependency
NOTICE_REQUIREMENTS=NOT_APPLICABLE
PACKAGE_OR_RELEASE_CHECKSUM_AVAILABLE=NOT_APPLICABLE
EXTERNAL_RESOURCE_FILES=NONE
RESOURCE_LICENSE_CLOSED=NOT_APPLICABLE
RESOURCE_IDENTITY_CLOSED=NOT_APPLICABLE
IN_MEMORY_BUFFER_API=NONE. Apple's public initializers create a type from an identifier, a filename extension, a MIME tag or URL resource values. Apple's documentation for init(filenameExtension:conformingTo:) states "To get the type of a file on disk, use URLResourceValues.contentType", which requires a URL, and the same page warns that a type cannot always be derived from the filename extension alone. No public API was found that infers a type by inspecting content bytes supplied as Data
REQUIRES_PATH=YES in practice for the URL-resource-values route
REQUIRES_FILENAME=YES for the extension route
REQUIRES_SEEK=NOT_APPLICABLE
REQUIRES_TAIL=NOT_APPLICABLE
REQUIRES_FULL_FILE=YES for any route that reads the item from disk
CAN_OPERATE_ON_0_TO_4096_PREFIX=NO; there is no content-byte entry point to supply a prefix to
OUTPUT_TYPE_AVAILABLE=YES but only for metadata-derived types
MIME_AVAILABLE=YES but only from declared type metadata
CONFIDENCE_AVAILABLE=NO
MODEL_PRESENT=NOT_APPLICABLE
EXACT_DETECTOR_VERSION_SOURCE=NOT_APPLICABLE
EXACT_MODEL_VERSION_SOURCE=NOT_APPLICABLE
RUNTIME_NETWORK_REQUIRED=NO
TELEMETRY=NOT_APPLICABLE
RUNTIME_DOWNLOADER=NO
RUNTIME_INTERPRETER_REQUIREMENT=NONE
NATIVE_ARM64_FEASIBILITY=YES; it is a system framework
MACOS15_COMPATIBILITY_EVIDENCE=YES; it is the macOS 15 system framework
SELF_CONTAINED_HELPER_FEASIBILITY=NOT_APPLICABLE; there is nothing to bundle
KNOWN_SUBPROCESS_OR_DAEMON_REQUIREMENT=NO
RUNTIME_PROCESS_TREE_PROOF_NEEDED=NOT_APPLICABLE
FORMAT_COVERAGE_DESCRIPTION=declares and maps system-known types; it is a type registry, not a content classifier
UNKNOWN_FALLBACK_BEHAVIOR=returns a dynamic or nil type when no declared type matches
FIT=NO_FIT

### CAND_07 — llama.cpp plus an externally obtained GGUF model

CANDIDATE_ID=CAND_07
PROJECT_NAME=llama.cpp
OFFICIAL_REPOSITORY=https://github.com/ggml-org/llama.cpp
LATEST_RELEVANT_STABLE_RELEASE=repository is updated continuously; no stable release tag is used for this evaluation
PINNABLE_TAG_OR_COMMIT=repository pushed 2026-10-06; a specific commit was not pinned because no candidate model was identified
IMPLEMENTATION_LANGUAGE=C/C++
MAINTENANCE_STATUS=ACTIVE
LICENSE_RUNTIME=MIT
LICENSE_DATA_OR_MODEL=UNRESOLVED; the runtime code is MIT but every usable model is a separate artifact with its own license
REDISTRIBUTION_ALLOWED=UNRESOLVED; undecidable without a chosen model artifact
NOTICE_REQUIREMENTS=UNRESOLVED; depend on the model artifact's terms
PACKAGE_OR_RELEASE_CHECKSUM_AVAILABLE=NOT_APPLICABLE for the runtime; no model artifact was identified
EXTERNAL_RESOURCE_FILES=one or more GGUF model files, which the project's own README obtains externally (for example by pointing the tool at a Hugging Face repository)
RESOURCE_LICENSE_CLOSED=NO; no file-type-classification model was identified with closed redistribution terms
RESOURCE_IDENTITY_CLOSED=NO; no artifact identity or checksum exists for a model that has not been chosen
IN_MEMORY_BUFFER_API=llama.cpp loads a model from memory and evaluates token probabilities, but that is a language-modelling interface, not a file-type classifier
REQUIRES_PATH=YES for any shipped configuration, because the model must be read from a bundled resource path
REQUIRES_FILENAME=NOT_APPLICABLE
REQUIRES_SEEK=YES in practice for weight loading from a GGUF container
REQUIRES_TAIL=YES in practice; a model cannot be classified from a 4096-byte prefix of the media file being classified, and the classifier's own weights are a separate artifact
REQUIRES_FULL_FILE=NO for the media being classified, but the model file must be read in full by the runtime
CAN_OPERATE_ON_0_TO_4096_PREFIX=UNRESOLVED; there is no established file-type classification model to test, and any such model would consume bytes of the input far beyond a 4096-byte prefix in the general case
OUTPUT_TYPE_AVAILABLE=NO for a file-type taxonomy as shipped
MIME_AVAILABLE=NO
CONFIDENCE_AVAILABLE=UNRESOLVED; token probabilities are not a calibrated file-type confidence and must not be relabelled as one
MODEL_PRESENT=UNRESOLVED; no suitable model artifact identified
EXACT_DETECTOR_VERSION_SOURCE=NOT_APPLICABLE
EXACT_MODEL_VERSION_SOURCE=UNRESOLVED; would depend on an unchosen GGUF artifact
RUNTIME_NETWORK_REQUIRED=NO once a model is bundled, but the project's normal acquisition path is an external download, which the contract forbids at runtime
TELEMETRY=NO
RUNTIME_DOWNLOADER=NO in the library; the external model acquisition step is what conflicts
RUNTIME_INTERPRETER_REQUIREMENT=NONE
NATIVE_ARM64_FEASIBILITY=YES as a language-level inference; widely built for darwin/arm64
MACOS15_COMPATIBILITY_EVIDENCE=NONE specific to this task; the project is actively built for Apple silicon, but no file-type classifier has been verified
SELF_CONTAINED_HELPER_FEASIBILITY=UNRESOLVED; feasible in principle only once a redistributable model artifact exists
KNOWN_SUBPROCESS_OR_DAEMON_REQUIREMENT=NO
RUNTIME_PROCESS_TREE_PROOF_NEEDED=YES
FORMAT_COVERAGE_DESCRIPTION=NOT_APPLICABLE; no file-type taxonomy is shipped
UNKNOWN_FALLBACK_BEHAVIOR=NOT_APPLICABLE
FIT=UNRESOLVED

### CANDIDATE_FACT_MATRIX_END

## HARD_CONFLICTS

CAND_02_tree_magic_mini_default_build_conflict=the crate's entire detection rule set is obtained at runtime, not compiled in. src/fdo_magic/builtin/mod.rs selects `super::ruleset::from_u8(tree_magic_db::magic())` only under the `with-gpl-data` feature and otherwise calls `runtime::rules()`; src/fdo_magic/builtin/runtime.rs then resolves directories through the TREE_MAGIC_DIR, XDG_DATA_DIRS and XDG_DATA_HOME environment variables and defaults to /usr/local/share and /usr/share, reading files with std::fs. On macOS those shared-mime-info locations do not exist, so the graph loads no concrete types and from_u8 panics with "No filetype definitions are loaded." This conflicts with self-contained offline bundling and introduces environment-variable and foreign-filesystem authority inside the classifier.
CAND_02_tree_magic_mini_feature_build_conflict=enabling `with-gpl-data` embeds the FreeDesktop.org shared MIME database, whose package crate tree_magic_db declares license GPL-2.0-or-later and whose README warns the project must use a GPL-compatible license. That is a hard licensing conflict for FSD's distribution model and is not resolved by this packet.
CAND_06_apple_api_conflict=Apple's public type-identification surface resolves types from identifiers, filename extensions, MIME tags or URL resource values. It requires a filename or a URL, and Apple itself points to URLResourceValues.contentType for on-disk items. There is no public content-byte classification entry point, so it cannot consume FSD's bounded Data buffer and cannot satisfy the contract's no-path, no-filename rule. Type metadata lookup is not content classification.

## UNRESOLVED_EXTERNAL_FACTS

U1_MACOS15_ARM64_BUILD_AND_RUN_EVIDENCE=none of the candidates has upstream CI or documentation proving an arm64 macOS 15 build. infer CI is ubuntu-latest only; filetype CI is ubuntu-latest only; mimetype has no CI; libmagic documents macOS builds in legacy universal-binary guidance without arm64 or macOS 15 statements. This task may not build or execute anything, so arm64 macOS 15 proof is deferred to a later authorized implementation task and must not be claimed from this packet.
U2_LIBMAGIC_ARTIFACT_IDENTITY=upstream publishes file-5.48.tar.gz.asc but no SHA-256 for the tarball or for a prebuilt magic.mgc. Closing this requires either an upstream checksum request or building magic.mgc from a pinned source revision and recording the sha256 of the locally produced artifact.
U3_LIBMAGIC_GENERATED_DATABASE_LICENSE=the magic database derives from the project's own BSD-2-Clause Magdir sources, but the license and notice treatment of the generated magic.mgc artifact should be confirmed explicitly rather than inferred from the root license.
U4_LIBMAGIC_RESULT_TOKENIZATION=magic_buffer returns a human-readable description string. The exact mapping from that string to a stable detectedType token is an implementation-time decision, and it must be pinned by tests, not assumed.
U5_MIMETYPE_MAINTENANCE_RISK=the repository's entire commit history is three commits dated 2024-08-11 with no releases, no tags and one star. License, API and resource facts are closed, but sustained maintenance is not established. This is an Advisor risk input, not a contract violation.
U6_NATIVE_ML_MODEL_ARTIFACT=no file-type classification model with closed redistribution, identity and checksum facts was identified for a compact native ML route. That is the honest state of the seed, and it is why CAND_07 is UNRESOLVED rather than RESEARCH_FIT.
U7_KMAGIC_PRIMARY_SOURCES=KDE's KMagic could not be reached through an authoritative endpoint in this task, so it has no matrix row. It is not counted as either fit or no-fit.
U8_PROVENANCE_VERSION_STRINGING=none of the model-free candidates exposes an upstream runtime version constant for the detection data. For infer, mimetype and filetype the only exact version available is the pinned library/module version; for libmagic, magic_version reports the library version but not the database revision. FSD must therefore treat `detectorVersion` as host-owned provenance text built from the pinned build identity, not as upstream-asserted data.

## MAGIKA_BLOCKED_REFERENCE

CANDIDATE=Magika
STATUS=BLOCKED_REFERENCE
EVIDENCE_SOURCE=task025 handoff handoffs/FSD_P15_RUNTIME_SLICE_07_EXTERNAL_MAGIKA_VERIFICATION_A_20261006-110611.md and its accepted ledger row; this task did not repeat that investigation
PRESERVED_SUPPORTED_FACTS=native bounded byte-slice fit was supported, meaning the selected native API can classify the supplied prefix as an independent byte buffer; exact detector/model provenance looked feasible
PRESERVED_UNRESOLVED_FACTS=model redistribution rights unresolved; exact model and resource SHA256 closure unresolved; complete native-runtime license/notice/resource closure unresolved
SUPERSEDED_HISTORICAL_FACT=the task025 macOS13 compatibility gap is historical evidence against the then-current macOS 13 floor and is superseded as product-floor reasoning now that the floor is macOS 15
NOT_TREATED_AS_MACOS15_COMPATIBLE=this packet does not assert macOS 15 compatibility for Magika; that still requires candidate-specific evidence
NOT_REJECTED_AND_NOT_APPROVED=Magika remains BLOCKED_NON_EXCLUSIVE_CANDIDATE per ADR-033. Nothing here rejects it, and nothing here approves it
MODEL_FIELDS_NOT_FABRICATED=per the provenance contract, no model version or confidence value was invented for any candidate in this packet

## SECURITY_SURFACE

UNSAFE_OR_NATIVE_PARSER_SURFACE=infer matchers are safe Rust byte predicates with explicit length guards; the transitive cfb crate parses Compound File Binary headers, which is real parsing of untrusted bytes inside the classifier process and therefore belongs inside the crash-isolated helper boundary rather than the main app. libmagic is C and interprets a large attacker-influenced rule and input surface in-process; nom is used by tree_magic_mini's rule engine. All three are exactly the class of code the bundled-helper process boundary exists to contain.
EXTERNAL_DATABASE_PARSING=libmagic parses its compiled magic database, so a corrupted or substituted magic.mgc is an input-trust question that must be closed by pinning the artifact hash at build time. tree_magic_mini parses externally supplied FreeDesktop database text at runtime and honours environment-variable overrides, which is the worst case in this matrix for input and configuration trust.
REGEX_OR_SIGNATURE_INTERPRETATION=infer, filetype and mimetype interpret fixed byte comparisons with no general regular-expression engine; libmagic interprets a rule language with offsets, masks and string tests.
FFI_REQUIREMENT=none for infer, mimetype and filetype, which are pure Rust/Go; required for libmagic and llama.cpp, which are C/C++ and would be linked or wrapped by an FSD-owned helper.
CANDIDATE_OWNED_FILESYSTEM_API_AVAILABILITY=infer exposes get_from_path, filetype exposes MatchFile and libmagic exposes magic_file. Per the contract, a library exposing path APIs is not disqualified when the chosen buffer API needs no path, and the FSD helper must simply never call them. tree_magic_mini is different in kind: it internally resolves and reads filesystem paths to obtain its rule set, which is a disqualifying internal dependency rather than an unused convenience API.
PROCESS_BOUNDARY_NOTE=none of these libraries requires a subprocess or daemon. Every candidate fits the existing Slice03 single bundled helper process seam, subject to the RUNTIME_PROCESS_TREE_PROOF_NEEDED observation at implementation time.

## SHORTLIST_PACKET_BEGIN

### Shortlist entry 1

CANDIDATE=infer (CAND_01)
WHY_STILL_IN_SCOPE=cleanest fit in the matrix: MIT closure, buffer-first API that needs no path, no external resource, no interpreter, no network, actively maintained with a July 2026 release, and a registry-published artifact checksum. Nothing upstream contradicts any hard FSD requirement.
EXACT_UPSTREAM_PIN=github.com/bojand/infer tag v0.22.0, commit cb05400c5f43e07200fbc1c5753e15946e9b1de8; crates.io checksum f4200d433cbd5178df7797c9c2e75b348b728e39631cf14520d1e2fc424201f4; transitive cfb 0.15.0 checksum 0f13298d9178622b7916ec5d01d470425c04273c8ed07e87b1c38b34c4f4612b
LICENSE_SUMMARY=MIT; sole dependency cfb is MIT; permissive redistribution with notice retention
RESOURCE_SUMMARY=no external resource files; detection rules are compiled Rust source, so resource license and identity are not applicable
BUFFER_API=infer::get(&[u8]) -> Option<Type>, with Type::mime_type() and Type::extension()
MACOS15_ARM64_EVIDENCE=none upstream; pure-Rust no-build-script crate makes an arm64 build straightforward but unproven, and upstream CI is Linux-only
OUTPUT_MAPPING=detectedType and MIME from Type::mime_type(); CONFIDENCE=nil is legitimate; MODEL_VERSION=nil is legitimate; detectorVersion must be host-owned text derived from the pinned crate version because no upstream version constant exists; unknown input maps to not-classified
NETWORK_RUNTIME_SUMMARY=none; no network, telemetry or runtime downloader
MAJOR_UNRESOLVED_FACTS=arm64 macOS 15 build and run proof; whether FSD wants CFB parsing inside the helper's trust boundary; documented coverage of 91 types is narrower than a magic database
MAX_5_SOURCE_URLS=https://github.com/bojand/infer;https://raw.githubusercontent.com/bojand/infer/v0.22.0/Cargo.toml;https://raw.githubusercontent.com/bojand/infer/v0.22.0/src/lib.rs;https://raw.githubusercontent.com/bojand/infer/v0.22.0/src/matchers/image.rs;https://index.crates.io/in/fe/infer

### Shortlist entry 2

CANDIDATE=libmagic / file 5.48 (CAND_03)
WHY_STILL_IN_SCOPE=the most mature native signature engine in the matrix with a real buffer-only API, permissive BSD-2-Clause terms, a runtime library version call and broad rule coverage. It is the only candidate with documented macOS build guidance.
EXACT_UPSTREAM_PIN=file-5.48.tar.gz from https://astron.com/pub/file/ dated 2026-06-07 19:49, with published detached file-5.48.tar.gz.asc; the official CVS mirror master carried ChangeLog entries dated 2026-08-28; no upstream SHA-256 exists
LICENSE_SUMMARY=BSD-2-Clause per the project COPYING, requiring reproduction of the copyright notice, conditions and disclaimer in distributed materials
RESOURCE_SUMMARY=external resource magic.mgc generated from the project's own BSD-2-Clause Magdir sources; artifact identity and the generated artifact's own notice treatment are unclosed
BUFFER_API=magic_buffer(magic_t, const void *, size_t) with magic_open, magic_load, magic_setflags, magic_compile, magic_version
MACOS15_ARM64_EVIDENCE=INSTALL documents macOS builds including fat/universal binaries, but only in legacy 10.5-era terms; nothing states arm64 or macOS 15
OUTPUT_MAPPING=detectedType derived from the leading token of the description string and MIME via MAGIC_MIME_TYPE; CONFIDENCE=nil is legitimate; detectorVersion from magic_version; database identity needs a build-time sha256 of the bundled magic.mgc
NETWORK_RUNTIME_SUMMARY=none; libmagic performs no network access and has no runtime fetcher; it is C parsing untrusted bytes in-process, so the helper boundary matters
MAJOR_UNRESOLVED_FACTS=no upstream artifact checksum; generated-database license and notice treatment; stable tokenization of the description string; arm64 macOS 15 proof
MAX_5_SOURCE_URLS=https://astron.com/pub/file/;https://raw.githubusercontent.com/file/file/master/COPYING;https://raw.githubusercontent.com/file/file/master/src/magic.h.in;https://raw.githubusercontent.com/file/file/master/ChangeLog;https://raw.githubusercontent.com/file/file/master/INSTALL

### Shortlist entry 3

CANDIDATE=mimetype (CAND_04)
WHY_STILL_IN_SCOPE=Apache-2.0, buffer-only API with no path entry point at all, compiled-in detectors, no external resource, and a built-in 3072-byte rate limit that sits comfortably inside FSD's 4096-byte ceiling.
EXACT_UPSTREAM_PIN=crates.io artifact checksum ad81b1e703d84473c6b6e6b8999ede6b9a918662ba7d89d9970c036bb72edd17 for 0.1.6; the repository publishes no tag or release, so only the registry artifact is pinnable
LICENSE_SUMMARY=Apache-2.0 with a permissive dependency closure (parking_lot, serde, serde_json dual MIT/Apache-2.0; quick-xml MIT; byteorder Unlicense OR MIT)
RESOURCE_SUMMARY=no external resource files; detectors are Rust source under src/magic
BUFFER_API=mimetype::detect(&[u8]) -> Mime with public mime, aliases and extension fields
MACOS15_ARM64_EVIDENCE=none upstream; no CI configuration exists at all, so no macOS or arm64 statement
OUTPUT_MAPPING=detectedType and MIME from Mime.mime; CONFIDENCE=nil is legitimate; MODEL_VERSION=nil is legitimate; the library's application/octet-stream ROOT fallback must not be reported as a positive detection
NETWORK_RUNTIME_SUMMARY=none; no network, telemetry or runtime downloader; tokio is optional and only for the unused async reader feature
MAJOR_UNRESOLVED_FACTS=arm64 macOS 15 proof; sustained maintenance is unestablished since 2024-08-11; no upstream version constant for detectorVersion
MAX_5_SOURCE_URLS=https://github.com/hoslo/mimetype;https://raw.githubusercontent.com/hoslo/mimetype/master/Cargo.toml;https://raw.githubusercontent.com/hoslo/mimetype/master/src/mime.rs;https://raw.githubusercontent.com/hoslo/mimetype/master/src/lib.rs;https://index.crates.io/mi/me/mimetype

### Shortlist entry 4

CANDIDATE=filetype (Go) (CAND_05)
WHY_STILL_IN_SCOPE=MIT, buffer-first API, no third-party runtime dependency, no external resource, no path requirement on the chosen entry point, and content-addressed official checksums that make the pin exact.
EXACT_UPSTREAM_PIN=github.com/h2non/filetype tag v1.1.3, commit a977222ef406; sum.golang.org entry h1:FKkx9QbD7HR/zjK1Ia5XiBsq9zdLi5Kf3zGyFTAFkGg=
LICENSE_SUMMARY=MIT with notice retention; no runtime dependency
RESOURCE_SUMMARY=no external resource files; matchers are Go source
BUFFER_API=filetype.Match([]byte) (types.Type, error) with types.Type.MIME and types.Type.Extension
MACOS15_ARM64_EVIDENCE=none upstream; CI is ubuntu-latest on Go 1.19–1.21 with no macOS runner
OUTPUT_MAPPING=detectedType and MIME from types.Type; CONFIDENCE=nil is legitimate; MODEL_VERSION=nil is legitimate; types.Unknown with nil error must map to not-classified and ErrEmptyBuffer to a typed FSD outcome
NETWORK_RUNTIME_SUMMARY=none; the library performs no network access and a Go build yields a static native binary. A Go toolchain is a build-time-only dependency, which the packaging contract permits and this packet reports explicitly
MAJOR_UNRESOLVED_FACTS=arm64 macOS 15 proof; release tag is older than the active repository history, so the pin must be by commit rather than by a fresh release
MAX_5_SOURCE_URLS=https://github.com/h2non/filetype;https://raw.githubusercontent.com/h2non/filetype/v1.1.3/match.go;https://raw.githubusercontent.com/h2non/filetype/v1.1.3/types/type.go;https://raw.githubusercontent.com/h2non/filetype/v1.1.3/LICENSE;https://sum.golang.org/lookup/github.com/h2non/filetype@v1.1.3

## SHORTLIST_PACKET_END

No winner, ranking, score or preference is expressed in this packet. `RESEARCH_FIT` means only that no authoritative fact currently contradicts a hard FSD requirement and that the facts a later feasibility implementation needs are sufficiently closed for Advisor consideration. It does not mean integrated, audited or selected.

## Source ledger for hard external facts

SOURCE_LEDGER_BEGIN

S01
SOURCE_KIND=OFFICIAL_PACKAGE_METADATA
OFFICIAL_REPOSITORY=OFFICIAL_PACKAGE_METADATA_APPLIES
SOURCE_URL=https://index.crates.io/in/fe/infer
REVISION_OR_DATE=infer 0.22.0 published 2026-07-15T15:05:03Z
FACT=Official crates.io sparse index publishes version 0.22.0, not yanked, checksum f4200d433cbd5178df7797c9c2e75b348b728e39631cf14520d1e2fc424201f4, single normal dependency cfb ^0.14
CONFIDENCE=DIRECT

S02
SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://raw.githubusercontent.com/bojand/infer/v0.22.0/Cargo.toml
REVISION_OR_DATE=tag v0.22.0, commit cb05400c5f43e07200fbc1c5753e15946e9b1de8
FACT=license = "MIT"; rust-version 1.74; no build script declared; dependencies are cfb only
CONFIDENCE=DIRECT

S03
SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://raw.githubusercontent.com/bojand/infer/v0.22.0/src/lib.rs
REVISION_OR_DATE=tag v0.22.0
FACT=buffer entry points Infer::get(&self, buf: &[u8]) -> Option<Type> and free function infer::get(buf: &[u8]) -> Option<Type); Type exposes mime_type() -> &'static str, extension() -> &'static str, matcher_type(); a separate get_from_path exists
CONFIDENCE=DIRECT

S04
SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://raw.githubusercontent.com/bojand/infer/v0.22.0/src/matchers/image.rs
REVISION_OR_DATE=tag v0.22.0
FACT=matchers are length-guarded byte predicates over the supplied slice, for example is_png requires 4 bytes and is_jpeg2000 requires 13 bytes, so a bounded prefix is a legal input and no seek or tail read occurs
CONFIDENCE=DIRECT

S05
SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://raw.githubusercontent.com/bojand/infer/v0.22.0/README.md
REVISION_OR_DATE=tag v0.22.0
FACT=README states the crate "Does not require magic file database (i.e. /etc/magic)" and its Supported types section enumerates 91 types
CONFIDENCE=DIRECT

S06
SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://raw.githubusercontent.com/bojand/infer/v0.22.0/.github/workflows/build.yml
REVISION_OR_DATE=tag v0.22.0
FACT=all CI jobs run on ubuntu-latest; no macOS runner and no macOS build job exist
CONFIDENCE=DIRECT

S07
SOURCE_KIND=OFFICIAL_PACKAGE_METADATA
SOURCE_URL=https://index.crates.io/3/c/cfb
REVISION_OR_DATE=cfb 0.15.0 published 2026-09-18T22:22:45Z
FACT=checksum 0f13298d9178622b7916ec5d01d470425c04273c8ed07e87b1c38b34c4f4612b; crates.io repository field for cfb points to github.com/mdsteele/rust-cfb, whose GitHub license is MIT
CONFIDENCE=DIRECT

S08
SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://raw.githubusercontent.com/mbrubeck/tree_magic/mini/Cargo.toml
REVISION_OR_DATE=branch mini at tree_magic_mini 3.2.2
FACT=license = "MIT"; tree_magic_db is an optional dependency behind the feature `with-gpl-data`
CONFIDENCE=DIRECT

S09
SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://raw.githubusercontent.com/mbrubeck/tree_magic/mini/src/fdo_magic/builtin/mod.rs
REVISION_OR_DATE=branch mini
FACT=ALL_RULES is built from tree_magic_db::magic() when `with-gpl-data` is enabled and otherwise from runtime::rules(), so the default build has no compiled-in detection rules
CONFIDENCE=DIRECT

S10
SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://raw.githubusercontent.com/mbrubeck/tree_magic/mini/src/fdo_magic/builtin/runtime.rs
REVISION_OR_DATE=branch mini
FACT=runtime rule loading resolves directories through the TREE_MAGIC_DIR, XDG_DATA_DIRS and XDG_DATA_HOME environment variables, defaults to /usr/local/share and /usr/share, and reads files with std::fs::read
CONFIDENCE=DIRECT

S11
SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://raw.githubusercontent.com/mbrubeck/tree_magic/mini/src/lib.rs
REVISION_OR_DATE=branch mini
FACT=CHECKERS consists of fdo_magic::builtin::check::FdoMagic and basetype::check::BaseType only; basetype provides five base types (all/all, all/allfiles, inode/directory, text/plain, application/octet-stream); from_u8 panics with "No filetype definitions are loaded." when no external definitions load
CONFIDENCE=DIRECT

S12
SOURCE_KIND=OFFICIAL_PACKAGE_METADATA
SOURCE_URL=https://index.crates.io/tr/ee/tree_magic_db
REVISION_OR_DATE=tree_magic_db 3.0.1 published 2024-10-22
FACT=checksum bd30f22e7532ed0d3d846e24841a132c8dcb779f5b497bda82d904aa04755375; crates.io version license is GPL-2.0-or-later; description states it packages the FreeDesktop.org shared MIME database
CONFIDENCE=DIRECT

S13
SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://raw.githubusercontent.com/mbrubeck/tree_magic/mini/README.md
REVISION_OR_DATE=branch mini
FACT="By default, tree_magic_mini will attempt to load the shared MIME info database from the standard locations at runtime" and "As the magic database files themselves are licensed under the GPL, you must make sure your project uses a compatible license if you enable this behaviour"
CONFIDENCE=DIRECT

S14
SOURCE_KIND=OFFICIAL_RELEASE
SOURCE_URL=https://astron.com/pub/file/
REVISION_OR_DATE=listing retrieved 2026-10-06
FACT=file-5.48.tar.gz dated 2026-06-07 19:49, 2.6M, with file-5.48.tar.gz.asc dated the same time; file-5.47 dated 2026-02-26
CONFIDENCE=DIRECT

S15
SOURCE_KIND=OFFICIAL_RELEASE
SOURCE_URL=https://astron.com/pub/file/file-5.48.tar.gz.sha256
REVISION_OR_DATE=checked 2026-10-06
FACT=HTTP 404; the sibling .sha256sum path also returns 404, so upstream publishes no SHA-256 for the release tarball
CONFIDENCE=DIRECT

S16
SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://raw.githubusercontent.com/file/file/master/COPYING
REVISION_OR_DATE=CVS master, ChangeLog entries dated 2026-08-28
FACT=BSD-2-Clause style terms: redistribution in source and binary form permitted provided the copyright notice, conditions and disclaimer are reproduced
CONFIDENCE=DIRECT

S17
SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://raw.githubusercontent.com/file/file/master/src/magic.h.in
REVISION_OR_DATE=CVS master
FACT=declares const char *magic_buffer(magic_t, const void *, size_t) alongside magic_open, magic_file, magic_load, magic_setflags, magic_compile and magic_version
CONFIDENCE=DIRECT

S18
SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://raw.githubusercontent.com/file/file/master/README.md
REVISION_OR_DATE=CVS master
FACT=release manifest lists magic/C/magic.mgc as shared data that is not machine code
CONFIDENCE=DIRECT

S19
SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://raw.githubusercontent.com/file/file/master/INSTALL
REVISION_OR_DATE=CVS master
FACT=documents creating fat/universal libraries and executables on MacOS X with multiple -arch options; guidance is legacy and mentions 10.5, i386 and ppc, not arm64 or macOS 15
CONFIDENCE=DIRECT

S20
SOURCE_KIND=OFFICIAL_PACKAGE_METADATA
SOURCE_URL=https://index.crates.io/mi/me/mimetype
REVISION_OR_DATE=mimetype 0.1.6 published 2024-08-11T03:09:48Z
FACT=checksum ad81b1e703d84473c6b6e6b8999ede6b9a918662ba7d89d9970c036bb72edd17; dependencies parking_lot, serde, serde_json, quick-xml, byteorder and optional tokio; no build script
CONFIDENCE=DIRECT

S21
SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://raw.githubusercontent.com/hoslo/mimetype/master/src/mime.rs
REVISION_OR_DATE=repository master, latest commits all dated 2024-08-11
FACT=pub fn detect(content: &[u8]) -> Mime truncates input to a rate limit whose DEFAULT_LIMIT is 3072 bytes; Mime exposes pub mime, pub aliases and pub extension; there is no path-based detection entry point
CONFIDENCE=DIRECT

S22
SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://raw.githubusercontent.com/hoslo/mimetype/master/Cargo.toml
REVISION_OR_DATE=master
FACT=license = "Apache-2.0"; default feature is sync; tokio is optional behind the async feature
CONFIDENCE=DIRECT

S23
SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://api.github.com/repos/hoslo/mimetype
REVISION_OR_DATE=retrieved 2026-10-06
FACT=repository pushed_at 2024-08-11T03:09:31Z, one star, no releases and no tags, so only the crates.io artifact is pinnable
CONFIDENCE=DIRECT

S24
SOURCE_KIND=OFFICIAL_PACKAGE_METADATA
SOURCE_URL=https://sum.golang.org/lookup/github.com/h2non/filetype@v1.1.3
REVISION_OR_DATE=tag v1.1.3
FACT=official Go checksum database entry github.com/h2non/filetype v1.1.3 h1:FKkx9QbD7HR/zjK1Ia5XiBsq9zdLi5Kf3zGyFTAFkGg= and the corresponding go.mod hash
CONFIDENCE=DIRECT

S25
SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://raw.githubusercontent.com/h2non/filetype/v1.1.3/match.go
REVISION_OR_DATE=tag v1.1.3, commit a977222ef406
FACT=func Match(buf []byte) (types.Type, error) iterates in-memory matchers and returns types.Unknown with a nil error when nothing matches; ErrEmptyBuffer is returned for a zero-length buffer; MatchFile(filepath string) also exists
CONFIDENCE=DIRECT

S26
SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://raw.githubusercontent.com/h2non/filetype/v1.1.3/LICENSE
REVISION_OR_DATE=tag v1.1.3
FACT="The MIT License, Copyright (c) Tomas Aparicio"
CONFIDENCE=DIRECT

S27
SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://api.github.com/repos/h2non/filetype
REVISION_OR_DATE=retrieved 2026-10-06
FACT=repository not archived, pushed_at 2026-07-01, MIT license, CI workflow runs ubuntu-latest on Go 1.19 to 1.21 with no macOS runner
CONFIDENCE=DIRECT

S28
SOURCE_KIND=APPLE_OFFICIAL
SOURCE_URL=https://developer.apple.com/documentation/uniformtypeidentifiers/uttype-swift.struct/init(filenameextension:conformingto:)
REVISION_OR_DATE=Apple developer documentation as published, retrieved 2026-10-06
FACT=UTType creation is from a filename extension, a MIME tag or an identifier; the page directs callers to URLResourceValues.contentType for on-disk items and warns a type cannot always be derived from the extension alone; no content-byte classification entry point is documented
CONFIDENCE=DIRECT

S29
SOURCE_KIND=OFFICIAL_REPO
SOURCE_URL=https://api.github.com/repos/ggml-org/llama.cpp
REVISION_OR_DATE=retrieved 2026-10-06, repository pushed 2026-10-06
FACT=license MIT; the project's README obtains models externally, for example by pointing the tool at a Hugging Face GGUF repository; no file-type-classification model is published
CONFIDENCE=DIRECT

SOURCE_LEDGER_END

## Ownership, limits and remaining issues

This packet is Architect research evidence only. It does not classify, accept, select or authorize any provider, and it changed no product surface: no production Swift, tests, docs, schema, Xcode project, dependency, package manifest, or helper/model/vendor artifact was modified, and no candidate was installed, downloaded as a build artifact, built or executed. STATE/PROJECT_STATE.md and STATE/RULE_PROMOTION_LEDGER.tsv were not touched, and no historical handoff was rewritten.

Two evidence labels are used throughout. DIRECT means the cited primary source states the fact. STRONG_INFERENCE means the fact follows from cited primary sources plus a stated reasoning step, and is labelled as such at each use; the arm64 macOS 15 build feasibility statements are all STRONG_INFERENCE and none is presented as measured fact.

No accuracy benchmark, quality score, ranking or preference was produced, and no upstream accuracy claim was recorded because no inspected primary source published one for these candidates.

## Proposed state delta and exactly one proposed next

PROPOSED_ACCEPTANCE=FSD_CLASSIFIER_PROVIDER_ALTERNATIVES_RESEARCH_027_PASS
PROPOSED_NEXT_TASK=FSD_CLASSIFIER_PROVIDER_SELECTION_ADVISOR_028 (identical to the single HOT PROPOSED_NEXT field, which the canonical checker requires to appear exactly once)
PROPOSED_NEXT_RATIONALE=at least one RESEARCH_FIT candidate exists (four do), so the contract routes to an independent selection Advisor rather than back to BRAIN for strategy adjudication
PROPOSED_NEXT_CONTENT_SUMMARY_ONLY=an independent Advisor compares the four RESEARCH_FIT candidates against the locked macOS 15+ bounded bundled-helper contract, weighs the documented maintenance risk for CAND_04 and the artifact-identity gap for CAND_03, and recommends or rejects without relying on this Architect's ordering
PROPOSED_NEXT_NOT_STARTED=YES
