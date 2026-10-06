# filetype bundled-helper integration rescope — PASS_WITH_ADVISORY

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_CLASSIFIER_FILETYPE_BUNDLED_HELPER_INTEGRATION_RESCOPE_D_20261006-225618.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=556872844b90640cc2a64e40d99594a78cef61af
REMOTE_HEAD=307791e020e63c11177266ea5eb2ac11746d8942
LAST_VERIFIED_AT=2026-10-06T22:56:18+07:00
AUTHORITY_PTRS=AGENTS.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|docs/BRAIN_OPERATOR.md|STATE/PROJECT_STATE.md|handoffs/FSD_CLASSIFIER_FILETYPE_BUNDLED_HELPER_INTEGRATION_D_20261006-212119.md|docs/DECISIONS.md|docs/CLASSIFIER_FILETYPE_INTEGRATION_CONTRACT.md|docs/ARCHITECTURE.md|docs/SECURITY_AND_READ_ONLY_POLICY.md|docs/TEST_PLAN.md|docs/P15_RUNTIME_PLAN.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_CLASSIFIER_FILETYPE_BUNDLED_HELPER_INTEGRATION_RESCOPE_033A
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_FOR_AUTHORIZED_INTEGRATION;INDEPENDENT_AUDIT_REQUIRED_BEFORE_ACCEPTANCE
PROPOSED_NEXT=FSD_CLASSIFIER_FILETYPE_INTEGRATION_AUDIT_034
NO_AUTO_NEXT=YES

## Task lock and result

TASK_ID=FSD_CLASSIFIER_FILETYPE_BUNDLED_HELPER_INTEGRATION_RESCOPE_033A
ROLE=WORKER
MODE=BOUNDED_PRODUCTION_HELPER_INTEGRATION_RESCOPE
BASE_HEAD=307791e020e63c11177266ea5eb2ac11746d8942
UPSTREAM_HEAD=307791e020e63c11177266ea5eb2ac11746d8942
CHECKER_BASE=26e52271b1a2008291f53b33e09dbba578ac467c
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=EXACT_ADR035_BOUNDED_HELPER_INTEGRATION_PLUS_FOUR_DEPENDENT_TEST_ADAPTATIONS
ALLOWED_PATHS=Tools/FSDClassificationHelper/main.go|Tools/FSDClassificationHelper/go.mod|Tools/FSDClassificationHelper/go.sum|scripts/build_classification_helper.sh|FSD/Helpers/FSDClassificationHostSeam|FSD/Helpers/FSDClassificationHostSeam.manifest.json|FSD/Helpers/THIRD_PARTY_NOTICES.txt|FSD/Classification/BundledMagikaClassificationProvider.swift|FSD/Classification/BundledFiletypeClassificationProvider.swift|FSDTests/BundledMagikaClassificationProviderTests.swift|FSDTests/BundledFiletypeClassificationProviderTests.swift|FSD/UI/SnapshotBrowserView.swift|FSD.xcodeproj/project.pbxproj|FSDTests/ClassificationRuntimeServiceTests.swift|FSDTests/SnapshotBrowserClassificationTests.swift|FSDTests/ClassificationSecurityIntegrationTests.swift|FSDTests/ClassificationInvocationIsolationTests.swift|STATE/PROJECT_STATE.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|handoffs/CURRENT_HANDOFF.md|handoffs/FSD_CLASSIFIER_FILETYPE_BUNDLED_HELPER_INTEGRATION_RESCOPE_D_20261006-225618.md
FORBIDDEN_PATHS=OTHER_PRODUCTION_TEST_DOC_SCHEMA_PATHS|PROTECTED_RUNTIME_MODULES|STATE/RULE_PROMOTION_LEDGER.tsv|PRIOR_HISTORY|OWNER_GLOBAL_CONFIGURATION|SOURCE_MEDIA
SUCCESS_CRITERIA=PINNED_REPRODUCIBLE_BOUNDED_REAL_HELPER;EXACT_BUNDLE;ACTUAL_PROCESS_TESTS;REQUIRED_VALIDATIONS;RETURN_ONLY
VALIDATIONS=RED;TWO_CLEAN_GO_BUILDS;DEBUG_RELEASE_CLEAN;TARGETED_FOCUSED_FULL_XCTEST;BINARY_NOTICE_BUNDLE_NETWORK_PROCESS_SIGNING;GIT_AND_CONTROL_CHECKS
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
RESULT=PASS_WITH_ADVISORY
RESULT_AUTHORITY=WORKER_EVIDENCE_ONLY_PENDING_BRAIN
TECHNICAL_SHA=556872844b90640cc2a64e40d99594a78cef61af
PRODUCTION_PROVIDER_ACCEPTED=NO
INTEGRATION_AUDITED=NO
SLICE08_UNBLOCKED=NO
MANUAL_ACCEPTANCE=NOT PERFORMED — DEFERRED BY OWNER

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=36
WORKER_REQUIREMENTS_EVIDENCED=35
WORKER_REQUIREMENTS_NOT_APPLICABLE=1
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

## Git/authority and supplied BRAIN projection (FACT)

Initial physical canonical main/origin at 307791e020e63c11177266ea5eb2ac11746d8942, clean 0/0 after non-destructive fetch. Required skills, CURRENT HOT, task033 STOP handoff and all named direct authorities read. Owner dirty/ignored work preserved; no reset/clean/stash/rebase or automatic next task.

Explicit Owner task033A BRAIN decision mechanically projected in separate commit 26e52271b1a2008291f53b33e09dbba578ac467c: task033 ledger accepted historical STOP at publication307791e020e63c11177266ea5eb2ac11746d8942, technical/control b6a2021470ddf2fa670db1ee9c90a40c54e1afdd, no product implementation; scope gap resolved solely by four added test paths; one gate/next ACTION(task033A). Two append-only BRAIN events cite this prompt as authorization provenance. Last successful accepted task/head remain task032A/3ad13b491bfe779157ae0a698cc304720e1a501f; historical accepted STOP is recorded separately. No production-provider acceptance or audit was invented.

Checker Worker-closure base is that supplied BRAIN-projection commit because its ownership checks require already accepted STATE/prior classifications unchanged. Original task baseline remains fixed above; full original-base allowlist/history/append-only checks independently include the explicit projection and all product changes. No checker rewrite or baseline absorption of unknown drift. Technical commit above contains reviewed implementation; publication is resolved later from this handoff's Git history, never embedded as a future self-containing SHA.

## Concrete implementation

- `Tools/FSDClassificationHelper/main.go`: zero command arguments; stdin only via 4097-byte LimitReader; >4096 returns failed before matching; len<=513 with D0CF11E0 returns no_match with all metadata null before matching. Empty input calls once and accepts no_match only for exact Unknown/ErrEmptyBuffer. Other eligible inputs call upstream Match once; recognized extension/MIME copied directly, unknown becomes no_match, other errors failed. One strict seven-field JSON envelope, no sample echo/log/hash/persistence, source opening, descendant creation or network. Matcher order/module source untouched.
- `go.mod/go.sum`: fsd.local/classification-helper, Go1.27.1 and sole filetypev1.1.3 dependency with exact contract sums.
- `scripts/build_classification_helper.sh`: manual-only archive-pin check BEFORE extraction into NEW scratch tree; exact module proxy info/mod/zip acquisition; Go uses local file proxy, GOSUMDB=off, readonly module build and an inherited OS sandbox denying network and persistent writes outside scratch. All writable env isolated, GOENV=off, GOTOOLCHAIN=local, TEST_TELEMETRY_DIR relocated and scratch mode off. No GOTELEMETRY override or global command/config change. Metadata-only external telemetry names/types/sizes/mtime-ns/inodes compared before/after each Go call. No other module/download/install, Homebrew Go or global toolchain.
- Exactly one committed native helper at `FSD/Helpers/FSDClassificationHostSeam`, plus strict manifest and four-part THIRD_PARTY_NOTICES. No toolchain/source/cache/model/database in app.
- Concrete Swift/test filenames/types renamed to BundledFiletypeClassificationProvider; stable helper path and host identity unchanged. SnapshotBrowserView constructs it only in explicit productionStart. FoundationHelperProcessRunner visibility changes from private to internal solely for real-child test decoration; launch/input/poll/cancel/reap implementation is byte-identical apart from class naming references/comments. No runtime/source-reader/provider-protocol/repository redesign, schema or comparison change.
- Xcode: one Wrapper Copy Files phase, subpath Contents/Helpers, one helper with CodeSignOnCopy; notice in existing Resources phase. COPY_PHASE_STRIP=NO in app Debug/Release so the signing-disabled bundle preserves pinned bytes. No Go build phase, downloader or network requirement.
- Four dependent tests narrowly adapted: runtime constructor spelling only (timeout/cancel/close/reap-before-slot assertions intact); browser constructor/name/comment updated to truthful detached-source unavailable (same outcome/zero-row assertions); security source filename renamed with all network/telemetry/update guards intact; application-launch constructor token updated. No compatibility alias/duplicate source or unrelated test path.
- New actual-helper tests in the renamed authorized test file: direct helper strict envelopes/caps; short/long CFB and guard edge; pinned fixture prefixes embedded only as public test assets from the verified upstream module; provider→Foundation runner; physical SIGKILL/crash and SIGSTOP/cancel; real five-second runtime timeout; actual noMatch generation invalidation and zero-row real repository; deliberate missing bundle; manifest/source/artifact/unsigned-bundle/notices/architecture/minos/resource closure. No missing-helper skip.

## Pins, reproducibility and containment (FACT)

Existing task033 archive freshly SHA-verified before extraction; no archive reacquisition. Locked archive SHA:
`ee215d57e0ec269c60cc9ceca68e6bda321ba9ee5afe24f4b0988703c2d87d12`.
Module Sum `h1:FKkx9QbD7HR/zjK1Ia5XiBsq9zdLi5Kf3zGyFTAFkGg=` and GoModSum `h1:319b3zT68BvV+WRj7cwy856M2ehB3HqNOt6sy1HndBY=` freshly verified against go.sum, module download JSON and go mod verify in BOTH independent trees. Only exact filetype info/mod/zip proxy objects acquired; Go network denied via sandbox and file:// proxy. Toolchain official VERSION and Go command output both go1.27.1 darwin/arm64. Official source confirms counter.OpenDir(os.Getenv("TEST_TELEMETRY_DIR")); owner telemetry contents never read.

Build A/B fresh separate toolchains/source/GOPATH/GOMODCACHE/GOCACHE/GOTMP/home/XDG/telemetry trees under ignored `.ai-scratch/task033A/build-A` and `build-B`. Each env JSON/command receipt preserved there. CGO_ENABLED=0, GOOS=darwin, GOARCH=arm64; flags `['-mod=readonly', '-trimpath', '-buildvcs=false', '-ldflags=-buildid=']`. Bytes identical; no selection between unequal outputs.

HELPER_SHA256=665a6569ee60614313e50629c4166358b89859f15dac4c522905ee5a730752e7
HELPER_SOURCE_SET_SHA256=37d3b38eb1e51e74a53c1c37e8389b4bde8b587a1be8ca4abdaf913fbd60feae
Source canonicalization: lexicographically sorted main.go/go.mod/go.sum/build script paths; for each concatenate UTF8 repo-relative path + NUL + ASCII decimal byte length + NUL + exact bytes; concatenate all and SHA256. Manifest lists exact source paths and definition. No sampled bytes hashed. Go build ID suppressed (go tool buildid returns only newline). Git attributes text/eol/filter/working-tree-encoding unspecified; binary NUL-containing content is verified against actual committed Git blob by finalizer.

OUTSIDE_SCRATCH_WRITES=0
Evidence: inherited OS sandbox denies persistent writes except the fresh build tree (and nonpersistent /dev/null); all Go calls exited0; relevant owner telemetry metadata stayed identical before/after both builds and all additional inspection calls. No global telemetry setting/config/install modified. The later Xcode/XCTest temp/catalog writes are required validation activity, not a claim of Go writable-state leakage.

## Final linked-source notice closure (FACT; engineering inventory only)

Exact shipped helper's deps:77 packages,72 standard plus main/four filetype packages;662 selected std compilation files. Standard debug/macho DWARF walker run in controlled Go scratch enumerates344 live source-mapped files including inline/assembly (Apple dwarfdump returned no compressed Go line records, so it was not treated as closure proof). Complete go tool nm and math.log objdump cross-check actual linked code.

Twenty selected standard files contain non-Go copyright. Only math/log.go is live source-mapped and linked; other19 math notice-bearing sources remain absent from live mappings and corresponding linked symbols. Seven physical assembly include headers inspected, all Go-owned. Other inspected ChaCha8/SwissTable/Abseil/tcmalloc/pdqsort/design/platform attributions retain Go-owned headers without another inherited required notice. No vendored third-party standard package in helper graph. Actual source/module notice digests preserved in manifest and plain notice file.

Final bounded set matches authority exactly: filetypev1.1.3 MIT; Go1.27.1 LICENSE; Go1.27.1 PATENTS; required Sun Microsystems1993 preservation notice from actual math/log.go lines17-22. System dylibs referenced, not redistributed inside artifact. No legal conclusion or unrelated source notice added.

## Actual helper/protocol/process evidence (FACT)

XCTest direct helper: PNG classified; unknown and empty no_match; exact4096 processed;4097 failed with all metadata null. Strict schemaVersion1/seven keys/one newline, stdout<=4096 and stderr0 observed. Five metadata fields null for no_match/failed; classified has direct type/MIME and detector `github.com/h2non/filetype@v1.1.3`, nil confidence/model. Provider identity `fsd.bundled-helper-host.v1` host-owned; parser rejection/cap/pump security tests retained. Request reflection exposes exactly Data and no source capability; protected reader/schema/repository tests pass. No sample hash/log/persistence feature added.

Permanent fresh-process tests: CFB4/32/513 each32 launches/no_match; >=514/515/1024/4096 DOC ECA5, XLS0908, PPTA046 and nonmatching0000 each16 launches per case; all expected/single-valued. Verified public upstream PNG/DOCX/XLSX/PPTX bounded prefixes each16 direct launches plus actual bundled provider calls. Additional Python probes23 cases×100 launches=2300 against final exact artifact; no multi-valued result. Initial scratch PPT probe mistakenly used006E, which correctly returned no_match; upstream source inspection corrected that test pattern to A046. No adapter fix/guard widening or acceptance claim relied on the mistaken probe.

Actual Match-call proof uses LLDB on the SHA-pinned shipped bytes, with Go nm's symbol file address and loaded-image relocation stored in manifest: 0 for shortCFB4/32/513 and4097;1 for empty, unknown, PNG,4096 PNG and longDOC514. No separate instrumented helper/build substituted. Named breakpoints were unresolved during tool investigation; those runs supplied no call-count proof. Address-relocated breakpoints resolve/hit on actual artifact and the permanent XCTest asserts all nine expected counts.

Actual production runner tests pass: normal classification; direct-child SIGKILL →failed; child suspended before pipe delivery then task cancellation →cancelled, terminate/close/reap before return; real five-second runtime deadline →failed with one failed append; actual noMatch held after inference then generation invalidation →cancelled/zero append/no stale success; actual noMatch against real repository→zero rows and immutable entry facts. Existing cleanup-before-slot-release and stale UI/no-auto-invocation tests preserved and passed.

Eight supervised final-helper launches under deny-network/deny-process-fork/deny-write sandbox each exited0 with PNG metadata and stderr0; lsof observed0 sockets, ps observed0 descendants while stdin held open. Supplemental direct SIGTERM exited-15 and reaped, stdout/stderr0. Production dependency closure has no net or os/exec package and helper source exposes no runtime acquisition/second source read. Observations are bounded to these runs, not a universal legacy-document claim.

## Validation receipts and one bounded packaging repair

- Causal RED before helper implementation: targeted testActualCommittedHelperIsRequired, xcodebuild exit65, executed1/passed0/failed1/skipped0, exact missing executable assertion (not setup failure).
- Two controlled Go builds exit0, identical artifact above, pins/telemetry/notice closure verified.
- Initial fresh clean Debug build exit0 but first targeted run exit65:32 executed/31 passed/1 failed/0 skipped. Failure was required unsigned bundle equality: Xcode builtin-copy called strip -D -S -no_atom_info and changed helper bytes (3879234→3879272). Complete log identified copy-phase stripping. One evidence-backed repair: COPY_PHASE_STRIP=NO only app Debug/Release. No hash-test weakening, fallback or artifact repin. Fresh clean isolated Debug and Release after repair both exit0 and no strip invocation on helper.
- Targeted GREEN:32 executed/32 passed/0 failed/0 skipped, exit0.
- Focused eight classification suites including all four newly scoped regression files:183 executed/183 passed/0 failed/0 skipped, exit0.
- Full fresh Debug XCTest: executed494/passed491/failed0/skipped3, exit0. Exactly three existing external probes skipped: FSDProbeSeedTests/testSeedIsolatedProbeCatalog (FSD_PROBE_CATALOG absent), FilesystemMatrixTests/testCaptureExternallyPreparedMountedFilesystem (FSD_MATRIX_SOURCE absent), testReopenCapturedSnapshotWithTheSourceDetached (FSD_MATRIX_OFFLINE_CATALOG absent). No actual-helper test skipped. Expected test-host catalog-lock diagnostics do not represent XCTest failures. Full run also emitted Thread Performance Checker priority-inversion diagnostic at the existing M5PeakSampler.stop; that memory test passed, no scoped source change or claim of resolving that unrelated diagnostic.
- file/lipo/vtool/otool-L/otool-l and fresh controlled go version-m on final artifact: Mach-O arm64 only; minos13.0, SDK26.2; linked `/usr/lib/libSystem.B.dylib` and `/usr/lib/libresolv.9.dylib`; Go1.27.1, sole filetypev1.1.3 dependency+locked Sum; trimpath, CGO0, GOOSdarwin, GOARCHarm64, GOARM64v8.0; empty buildID.
- Actual Debug/Release bundles: exactly Contents/Helpers/FSDClassificationHostSeam, SHA=tracked=manifest; notice resource exact; no unexpected helper/Go/toolchain/cache/module source/model/database. Normal build phases have no Go/download/network construction. Signing-disabled builds establish byte placement, not nested distribution signing.
- Scratch COPY of Release app: helper pre-sign SHA equal; codesign --force --sign - inner then outer; codesign --verify --deep --strict --verbose=2 app and strict helper exit0; codesign-dv confirms adhoc/TeamIdentifier not set; arm64/minos/exact placement preserved. Go linker already embeds a reproducible adhoc linker signature in the tracked Mach-O; this is distinct from Xcode account signing. Post-sign helper byte equality not required. No DeveloperID/notarization/AppStore readiness claim.
- Staged full-addition git diff --cached --check caught one extra final blank line in notices (earlier unstaged diff did not cover that untracked addition). Removed exactly one formatting LF without altering the four notice texts/digests, helper/source-set hash or executable semantics. Fresh clean Debug/Release builds and final actual-helper targeted32/32 repeated after this notice-only correction; full suite above preceded this formatting-only correction and is not claimed as rerun afterward. Final bundle/signing verification repeated against corrected notice.
- git diff --check and staged diff --check passed; original-base allowlist/history/rules and protected surfaces unchanged checked. Canonical pre/postpublication checker and final Git/Desktop/blob parity are finalizer closure checks, recorded as actual receipts in Desktop/ignored scratch after execution; this immutable record does not pre-claim its future publication/checker result.

## Requirement/evidence map (36 groups)

1 E canonical skills/read authority;2 E physical baseline/fresh fetch;3 E exact supplied BRAIN STOP/rescope projection;4 E exact expanded allowlist/no shims;5 E seven-outcome/control semantics unchanged;6 E source/read-only/no automatic/backfill/schema/comparison boundaries;7 E fresh archive pin;8 E sole module/sums/go.sum verified twice;9 E all Go writable env isolated/GOENV/GOTOOLCHAIN;10 E metadata-only external telemetry and OS write containment;11 E target/flags/buildID;12 E two independent identical builds;13 E 4097 oversize preMatch;14 E mandatory shortCFB rule before Match;15 E exact empty Unknown/ErrEmptyBuffer mapping;16 E eligible one-call/direct upstream mapping;17 E no upstream sort/fork/category dispatch;18 E single strict envelope/stdout/stderr bounds;19 E repeatedCFB short/long/edge;20 E pinned realistic fixture repetitions/advisory;21 E actual committed source/artifact/script;22 E manifest/canonical source/artifact integrity;23 E binary Git attributes/blob checks;24 E final bounded notice closure;25 E concrete provider/test/UI rename;26 E four test adapters preserve all prior invariants;27 E offline normal Xcode copy/notices/CodeSignOnCopy/no stripping;28 E actual provider→Foundation runner and host-owned provenance;29 E real normal/crash/SIGTERM/cancel/timeout/reap;30 E actual noMatch zero-row/stale and retained source/no-auto regression;31 E Debug causalRED/targeted/focused/full current receipts;32 E Release/binary/module metadata;33 E runtime network/descendant observation;34 E bundle hash/resource architecture/minos closure;35 E bounded adhoc-copy signing and protected-history/diff postflight;36 N/A manual acceptance expressly deferred by Owner. No material implementation requirement UNPROVEN. Publication closure remains separately verifiable finalizer work.

## Advisory, ownership and next boundary

The integration neutralizes demonstrated short legacy-CFB ambiguity. Current pinned PNG/DOCX/XLSX/PPTX and synthetic discriminant cases were single-valued. Exact module pin has no realistic legacy DOC/XLS/PPT fixtures; general legacy-Office determinism is not proven and no universal claim is made. Three unrelated external-probe skips/manual deferral are explicit above. These are the PASS_WITH_ADVISORY limits.

Worker evidence only. Accepted STATE still owns ACTION(task033A); task033A classification remains PENDING_BRAIN. Proposed state delta: BRAIN review this bounded implementation/receipts and independently route the sole proposal in HOT if accepted. No acceptance/audit/Slice08 gate adjudicated here. Stop after finalizer publication; task034 not run, simulated, authorized or started.

Raw recovery pointers (ignored, essential conclusions included above): `.ai-scratch/task033A/` red/targeted/targeted-green/focused/full-debug logs+xcresults, verified-test-counts.json; build-A/B environment/module/go/telemetry/deps/symbols/objdump receipts; dwarf.stdout/final-notice-scan.json/notice-includes.json; final-fixture-probes.json/process-observation.json/sigterm-receipt.json; bundle-signing-receipts.json/bundle-signing-final-receipts.json and final notice rebuild/targeted logs; initial/scope receipts and final checker JSON. No old task test/build result substitutes for this execution.
