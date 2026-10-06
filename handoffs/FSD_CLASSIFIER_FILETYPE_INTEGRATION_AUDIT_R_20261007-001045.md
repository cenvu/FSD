# filetype bundled-helper integration audit — independent ADR-035 verification

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_CLASSIFIER_FILETYPE_INTEGRATION_AUDIT_R_20261007-001045.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=bb798162a65871cf512298a8c10697178ab195f7
REMOTE_HEAD=bb798162a65871cf512298a8c10697178ab195f7
LAST_VERIFIED_AT=2026-10-07T00:10:45+07:00
AUTHORITY_PTRS=AGENTS.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-independent-review/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|docs/BRAIN_OPERATOR.md|STATE/PROJECT_STATE.md|handoffs/FSD_CLASSIFIER_FILETYPE_BUNDLED_HELPER_INTEGRATION_RESCOPE_D_20261006-225618.md|docs/DECISIONS.md|docs/CLASSIFIER_FILETYPE_INTEGRATION_CONTRACT.md|docs/ARCHITECTURE.md|docs/SECURITY_AND_READ_ONLY_POLICY.md|docs/TEST_PLAN.md|docs/P15_RUNTIME_PLAN.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_CLASSIFIER_FILETYPE_INTEGRATION_AUDIT_034
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_FOR_AUDIT;BRAIN_ADJUDICATION_REQUIRED
PROPOSED_NEXT=PRODUCTION_PROVIDER_ACCEPTANCE_AND_SLICE08_GATE
NO_AUTO_NEXT=YES

## Task lock and result

TASK_ID=FSD_CLASSIFIER_FILETYPE_INTEGRATION_AUDIT_034
ROLE=REVIEWER
MODE=INDEPENDENT_HIGH_RISK_INTEGRATION_AUDIT
BASE_HEAD=cd41457f1ac6160ba3cb12d58d846d70ea708c58
CHECKER_BASE=bb798162a65871cf512298a8c10697178ab195f7
UPSTREAM_HEAD=cd41457f1ac6160ba3cb12d58d846d70ea708c58
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=INDEPENDENT_VERIFICATION_OF_TASK033A_AGAINST_EVERY_MATERIAL_ADR035_BOUNDARY
ALLOWED_PATHS=handoffs/CURRENT_HANDOFF.md|handoffs/FSD_CLASSIFIER_FILETYPE_INTEGRATION_AUDIT_R_20261007-001045.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl
FORBIDDEN_PATHS=ALL_PRODUCTION_SWIFT|HELPER_GO_SOURCE|HELPER_BINARY|MANIFEST|NOTICES|XCODE_PROJECT|TESTS|SCHEMA|PRODUCT_DOCS|RUNTIME_PLANS|SECURITY_DOCS|INTEGRATION_CONTRACT|STATE/PROJECT_STATE.md|STATE/RULE_PROMOTION_LEDGER.tsv|PRIOR_HISTORY
SUCCESS_CRITERIA=INDEPENDENTLY_REPRODUCED_EVIDENCE_FOR_EVERY_ADR035_BOUNDARY;NO_REJECTION_LEVEL_DEFECT;RETURN_TO_BRAIN_ONLY
VALIDATIONS=TWO_AUDIT_GO_REBUILDS;CFB_AND_FIXTURE_DETERMINISM;LLDB_AND_STATIC_MATCH_CALL_PROOF;MANIFEST_BINARY_BUNDLE_NOTICE_CHECKS;FRESH_DEBUG_RELEASE_BUILDS;ADHOC_SIGNING;PROCESS_NETWORK_OBSERVATION;TARGETED_FOCUSED_FULL_XCTEST;CHECKER_PRE_POSTPUBLICATION
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
RESULT=PASS_WITH_ADVISORY
RESULT_AUTHORITY=REVIEWER_EVIDENCE_ONLY_PENDING_BRAIN
TECHNICAL_SHA=cd41457f1ac6160ba3cb12d58d846d70ea708c58
REVIEWED_TECHNICAL_SHA=556872844b90640cc2a64e40d99594a78cef61af
PRODUCTION_PROVIDER_ACCEPTED=NO
INTEGRATION_AUDITED=NO
SLICE08_UNBLOCKED=NO
MANUAL_ACCEPTANCE=NOT PERFORMED — DEFERRED BY OWNER

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=49
WORKER_REQUIREMENTS_EVIDENCED=48
WORKER_REQUIREMENTS_NOT_APPLICABLE=1
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

## Git, authority and supplied BRAIN projection (FACT)

Physical canonical root `/Users/cenvu/DEV/FSD`, branch `main`, origin `https://github.com/cenvu/FSD.git`. Non-destructive fetch left local/upstream at `cd41457f1ac6160ba3cb12d58d846d70ea708c58` clean 0/0 before any mutation; both the task033A publication and its technical commit `556872844b90640cc2a64e40d99594a78cef61af` are ancestry-verified against the accepted pre-task baseline `307791e020e63c11177266ea5eb2ac11746d8942`. Owner dirty/ignored state preserved; no reset, clean, stash, rebase or automatic next task. Required skills, CURRENT HOT, the task033A handoff, ADR-034, ADR-035, the integration contract, and the relevant ARCHITECTURE/SECURITY/TEST_PLAN §9/P15 sections were read before inspection.

The supplied BRAIN decision was mechanically projected in separate commit `bb798162a65871cf512298a8c10697178ab195f7`: task033A accepted PASS_WITH_ADVISORY at publication `cd41457f1ac6160ba3cb12d58d846d70ea708c58` with technical implementation `556872844b90640cc2a64e40d99594a78cef61af`; the legacy DOC/XLS/PPT determinism advisory preserved verbatim; CURRENT_GATE and the single next decision set to this audit. That projection is this cycle's checker base because the canonical checker's ownership rules require already-accepted STATE and prior classifications to be byte-stable across the closing commit. `STATE/RULE_PROMOTION_LEDGER.tsv` was not modified. Two append-only BRAIN events record only the supplied acceptance/authorization.

## Independent reproduction of the artifact (FACT)

The exact pinned official archive `.ai-scratch/task033/go1.27.1.darwin-arm64.tar.gz` was freshly SHA256-verified as `ee215d57e0ec269c60cc9ceca68e6bda321ba9ee5afe24f4b0988703c2d87d12` **before** extraction, in every run. Two fresh audit rebuilds were performed in separate new scratch trees (`.ai-scratch/task034/build-A`, `build-B`) via the committed `scripts/build_classification_helper.sh`. Both exited 0 and produced `HELPER_SHA256=665a6569ee60614313e50629c4166358b89859f15dac4c522905ee5a730752e7`, identical to each other **and** to the committed `FSD/Helpers/FSDClassificationHostSeam`. The script emits both `HELPER=` paths proving the outputs are distinct independent trees.

Containment receipts: every Go invocation ran under `sandbox-exec` with `(deny network*)` and `(allow file-write* (subpath <scratch>))`; `GOPROXY=file://<scratch>/proxy` served only the exact `github.com/h2non/filetype@v1.1.3` info/mod/zip objects; `GOENV=off`, `GOTOOLCHAIN=local`, `GOSUMDB=off`, `CGO_ENABLED=0`, `GOOS=darwin`, `GOARCH=arm64`, and `GOROOT/GOPATH/GOMODCACHE/GOCACHE/GOTMPDIR/TMPDIR/HOME/XDG_*/TEST_TELEMETRY_DIR` all resolved inside the fresh scratch tree. `GOTELEMETRY` was deliberately absent. All 16 Go commands across both builds exited 0 with `external_telemetry_unchanged=true`, and the extracted `cmd/internal/telemetry/counter` source still matched the relocation assumption. Module identity JSON reported `Sum=h1:FKkx9QbD7HR/zjK1Ia5XiBsq9zdLi5Kf3zGyFTAFkGg=` and `GoModSum=h1:319b3zT68BvV+WRj7cwy856M2ehB3HqNOt6sy1HndBY=`, matching `go.sum`, the manifest and ADR-035 §5 exactly.

Independent note, reported for transparency and not a product finding: my own read-only Go introspection calls (`go version -m`, `go tool nm`, `go tool objdump`, `go tool addr2line`) were made with the Owner's Homebrew `go1.27.1`, and macOS Go telemetry recorded one `local/addr2line@...count` entry in `~/Library/Application Support/go/telemetry` as a result. Both controlled rebuild runs' internal before/after telemetry metadata diffs were identical, and the rebuild never invokes `addr2line`; the change is audit-tool footprint, not build-script writable-state leakage.

## Source-authority and bounded-byte boundary (FACT)

The full chain was read: `SnapshotBrowserModel.productionStart` → `BundledFiletypeClassificationProvider` → `HelperProcessRunner` → `Process` → helper stdin. The provider receives a `LocalClassificationRequest` whose only stored field is `data` (reflection asserted by the shipped test), so no path, URL, `FileHandle`, descriptor, resolver, read callback, range callback or second source range can reach the provider or the helper. `FSD/Classification/BoundedClassificationSourceReader.swift`, `ClassificationRuntimeService.swift`, `LocalFileClassificationProvider.swift` and `EntryClassificationRepository.swift` are byte-identical to the accepted pre-task033A baseline; FSD alone owns `O_NOFOLLOW` source resolution and the single bounded prefix read. `LocalClassificationRequest.maximumByteCount` is exactly 4096 and the runner refuses any larger payload, so the helper's ceiling cannot be exceeded from the host side either. No sampled byte is persisted, hashed or logged, and classification stays derived metadata that cannot touch snapshot facts or comparison conclusions.

## Helper semantics and call boundary (FACT)

`Tools/FSDClassificationHelper/main.go` was inspected directly and read against the contract's mandated decision order: oversize first (`len > 4096` → `failed`, before any match), then the short-CFB guard, then a single `match(input)`. Independently observed on the shipped bytes: zero arguments required (any argument yields `failed`); stdin only via `io.LimitReader(os.Stdin, 4097)`; empty input maps to `no_match` only under the exact `len==0 && types.Unknown && filetype.ErrEmptyBuffer` conjunction; a recognised type copies the direct upstream extension and MIME with `confidence`/`modelVersion` null and `detectorVersion` exactly `github.com/h2non/filetype@v1.1.3`; upstream `Unknown` maps to `no_match`; any other error maps to `failed`. Output is one strict seven-field JSON object with a single trailing LF; no sample, hash, log, echo, source opening, descendant or network path exists in the helper source.

The `SHORT_CFB_GUARD` is exactly as contracted — `len(input) <= 513` (with a redundant but harmless `len(input) > 0`) AND prefix `D0 CF 11 E0` → `no_match`, all five metadata fields null, and **zero** `filetype.Match` calls. Upstream `matchers/document.go` was read: `Doc`, `Xls` and `Ppt` share the ambiguous branch only when `len(buf) > 3 && len(buf) <= 513`, and take the discriminating long branch only when `len(buf) > 513` using `buf[512]`/`buf[513]` (`0xEC 0xA5`, `0x09 0x08`, `0xA0 0x46`). The guard therefore covers exactly the ambiguous window and is neither over- nor under-broad; it was **not** widened during this audit. No `MatcherKeys` sorting, custom priority list, category dispatch, fork, patch or vendored-with-edits upstream source is present; the module is byte-identical to the pinned Sum.

Determinism was re-probed across fresh processes on the final committed helper: lengths 4, 32 and 513 with the CFB prefix each yielded `no_match` 100/100; lengths 514, 515, 1024 and 4096 with the DOC/XLS/PPT discriminants each yielded the corresponding single type 50–100/100; and the same lengths with a non-matching `00 00` discriminant each yielded `no_match` 50–100/100. Exact boundary confirmed: 512 and 513 → `no_match`, 514 → `classified`. 1,150 CFB launches produced no multi-valued result. Separately, the bounded prefixes the shipped test embeds were decoded and proved to be the first exactly 4096 bytes of the pinned module's own `fixtures/sample.{png,docx,xlsx,pptx}` files, and each was re-probed 32 times directly against the committed helper with a single-valued correct result. A 400-case randomised fuzz over lengths 0–5000 (including CFB prefixes and discriminants) produced zero schema, cap, exit-status, metadata-nullity or provenance violations; maximum stdout was 201 bytes against a 4096 cap and stderr was always 0.

Match-call counts were established by two independent methods on the exact shipped bytes (SHA `665a6569ee60614313e50629c4166358b89859f15dac4c522905ee5a730752e7`). Static: `go tool objdump -s main\.classify` shows exactly one indirect call site (`CALL (R3)` at `main.go:38`); the oversize test branches past it and the short-CFB guard returns before it, and `image lookup` confirms `github.com/h2non/filetype.Match` at file address `0x10010dec0` with image base `0x100000000` — exactly the manifest's `matchSymbolFileAddress`/`imageBaseFileAddress`. Dynamic: LLDB breakpoints on that address over the actual artifact, with the harness first validated by a positive control, gave 0 calls for CFB 4/32/513 and for 4097/8192, and 1 call for empty, unknown, PNG, DOCX-sized PNG, long CFB DOC 514, long CFB PPT 1024 and long CFB non-matching 514. No instrumented or substituted binary was used. The Worker's LLDB evidence was reviewed critically: named breakpoints genuinely do not resolve, and address breakpoints set before launch report `resolved=false`, so the shipped test's `--stop-at-entry` plus explicit load-address relocation is the correct and reproducible form.

## Manifest, binary and notice closure (FACT)

The manifest fields were recomputed against physical contents: `helperSHA256` matches the working tree and the Git blob (`60643aef64e21575e2538b844d18f8af3aad8613`, 3,879,234 bytes); `helperSourceSHA256=37d3b38eb1e51e74a53c1c37e8389b4bde8b587a1be8ca4abdaf913fbd60feae` reproduces exactly under the documented path+NUL+length+NUL canonicalization over the four listed source paths; module, Sum, GoModSum, `goVersion`, `goArchiveSHA256`, `GOOS`/`GOARCH`, `minos`, `buildFlags` and `detectorVersion` all agree with the artifact and the pinned sources. There is no `.gitattributes` in the tracked tree, no `info/attributes`, no `core.autocrlf`/`core.eol`/`core.attributesFile`, and `git ls-files --eol` reports `i/-text w/-text attr/` for the helper, so the committed helper is a binary-safe blob that no attribute transforms.

`file` and `lipo -info` report a non-fat Mach-O arm64 executable; `vtool -show-build` reports `platform MACOS`, `minos 13.0`, SDK 26.2 (within the ≤15.0 contract and the macOS 15+ product floor); `otool -L` reports only `/usr/lib/libSystem.B.dylib` and `/usr/lib/libresolv.9.dylib`, both system libraries, with no external model, database or resource dependency; `go version -m` reports `go1.27.1`, `path fsd.local/classification-helper`, sole dependency `github.com/h2non/filetype v1.1.3 h1:FKkx9QbD7HR/zjK1Ia5XiBsq9zdLi5Kf3zGyFTAFkGg=`, `-trimpath=true`, `CGO_ENABLED=0`, `GOARCH=arm64`, `GOOS=darwin`, `GOARM64=v8.0`; `go tool buildid` returns empty. `go list -deps` yields 77 packages — 72 standard plus main and four `github.com/h2non/filetype*` packages — with **no** `net`, `net/*` or `os/exec` package anywhere in the closure. `syscall.Open` is linked, but its only callers are `os.openDirNolog` and the `time` timezone reader; no path from `main.classify` or `filetype.Match` reaches it, and the helper receives no path at all, so "never opens a classified source" holds for the shipped artifact.

The notice closure was re-derived independently rather than accepted. `go tool addr2line` over all 2,772 text symbols enumerated 289 live source-mapped files; scanning every one for non-Go-authored copyright or preservation notices found exactly one — `math/log.go`, whose lines 17–22 carry the Sun Microsystems 1993 SunPro notice. `math/frexp.go`, the only other linked `math` file, is pure Go Authors BSD. All four shipped notices were verified to exist verbatim and their SHA256 values matched the manifest: `filetype v1.1.3 MIT` `85ffa04d…`, `Go 1.27.1 LICENSE` `911f8f57…`, `Go 1.27.1 PATENTS` `96f408bf…`, and the Sun notice `dbd7c05d…`. The bounded four-part inventory is therefore confirmed for the final linked artifact; no legal conclusion is claimed.

## Xcode packaging, bundles and signing (FACT)

`FSD.xcodeproj/project.pbxproj` was read directly: the FSD application target has exactly one `PBXCopyFilesBuildPhase` (`dstSubfolderSpec = 1` wrapper, `dstPath = Contents/Helpers`) containing exactly one file — `FSDClassificationHostSeam` with `ATTRIBUTES = (CodeSignOnCopy,)`; the notice is a separate entry in the existing `Resources` phase; `COPY_PHASE_STRIP = NO` is set only on the app's Debug and Release configurations; `CODE_SIGNING_ALLOWED = NO` and `CODE_SIGN_IDENTITY = ""` are unchanged; and the `PBXShellScriptBuildPhase` section is empty, so no Go, downloader or network step exists in a normal build.

Fresh isolated clean Debug and Release builds were run into audit-only derived-data trees; both exited 0 with `BUILD SUCCEEDED`. Neither build log contains `go build`, `GOROOT`, `golang`, `curl`, `git clone`, `proxy.golang`, `go.dev/dl` or `GOMODCACHE`, and the only `strip`-family lines are `bitcode_strip` inside `swiftStdLibTool` scanning `Contents/MacOS/FSD` and `Contents/Frameworks` — never the helper. Both unsigned bundles contain exactly `Contents/Helpers/FSDClassificationHostSeam` (no other helper), `Contents/Resources/THIRD_PARTY_NOTICES.txt` byte-identical to the committed notice (`17115e87…`), plus `Contents/MacOS/FSD`, `Info.plist`, `PkgInfo` and `Resources/schema.sql`; no Go toolchain, cache, module source, model or database is bundled. The bundle helper's SHA256 equals both the committed helper and the manifest hash in Debug and Release, and it is arm64 with `minos 13.0`.

Ad-hoc signing was performed on a scratch COPY of the built Release app: inner-then-outer `codesign --force --sign -` followed by `codesign --verify --deep --strict` on the app (exit 0, nested helper validated) and `codesign --verify --strict` on the helper (exit 0). `codesign -dv` reports `Signature=adhoc`, `flags=0x2(adhoc)`, `TeamIdentifier=not set`, Mach-O thin arm64, at the exact contracted path. The pre-sign helper hash equalled the committed hash; signed byte equality is not required and is not claimed. No Developer ID, notarization or App Store readiness is claimed.

## Process, network and cancellation (FACT)

Six supervised launches of the final helper with stdin held open after a PNG header showed zero sockets (`lsof -p <pid> -a -i`) and zero descendants (`pgrep -P <pid>`) while alive, then exit 0 with exactly one classified envelope and zero stderr bytes. Static dependency and symbol inspection corroborates this: no `net`, no `os/exec`, and no socket/connect/listen API surfaces in the 77-package closure. The shipped XCTest suite additionally exercises normal completion, direct-child `SIGKILL` crash → `failed`, `SIGSTOP`-suspended child followed by task cancellation → `cancelled` with terminate/close/reap before return, a real five-second runtime deadline → `failed` with exactly one failed append, and a post-inference generation invalidation that yields `cancelled` with no append and no stale publication. Cumulative stdout and stderr caps remain bounded by the unchanged driver. These are bounded observations of these runs, not a universal claim.

## noMatch, persistence and provenance (FACT)

`ClassificationRuntimeService.mappedResult` maps `.unavailable`, `.cancelled` and `.noMatch` to `input = nil`, so `noMatch` writes zero `entry_classifications` rows and mints no detected type, confidence, detector version, model version or provider row. A real-helper end-to-end test drives the actual repository: the result is `.noMatch`, the row is nil, `SELECT COUNT(*) FROM entry_classifications` is 0, and the `entries` table is byte-identical before and after. For a classified result the persisted `providerIdentifier` is host-owned (`dependencies.provider.providerIdentifier` = `fsd.bundled-helper-host.v1`, never emitted by the helper), `detectorVersion` is exactly `github.com/h2non/filetype@v1.1.3`, and `modelVersion`/`confidence` are nil. Cancellation is arbitrated by the unchanged commit-authorization lock, which seals an outcome before any later cancel can win, so cancellation cannot manufacture success evidence, and snapshot/entry immutable facts are asserted unchanged by the retained security tests.

## Scope, history and control-plane integrity (FACT)

`git diff --name-status` from the accepted baseline `307791e020e63c11177266ea5eb2ac11746d8942` to publication `cd41457f1ac6160ba3cb12d58d846d70ea708c58` contains only the authorized task033A paths: the provider rename (`R097` `BundledMagikaClassificationProvider.swift` → `BundledFiletypeClassificationProvider.swift`), `SnapshotBrowserView.swift` (one line), the three new helper paths, `scripts/build_classification_helper.sh`, the three Go helper sources, `project.pbxproj`, the four rescope test files plus the renamed provider test file, and the STATE/handoff paths. The four dependent test paths are the only scope added relative to the original task033 allowlist. No compatibility alias remains anywhere in live paths, the old provider production source is gone, and the new concrete name is used consistently in production, tests, and the project file. No unrelated product, schema, canonical-document or runtime-plan mutation occurred. Prior historical handoffs are byte-identical (only `CURRENT_HANDOFF.md` and the one new handoff changed under `handoffs/`), `STATE/EVENTS.jsonl` grew by exactly three appended lines with the prior 114 lines preserved as an exact prefix, and `STATE/RULE_PROMOTION_LEDGER.tsv` is unchanged.

The four rescope regressions were reviewed semantically, not by diff size. `ClassificationInvocationIsolationTests` changed only its constructor token while retaining all forbidden-token guards for automatic invocation. `ClassificationRuntimeServiceTests` changed only its constructor spelling while retaining timeout, cancel, terminate, close and reap-before-slot behaviour. `ClassificationSecurityIntegrationTests` changed only the inspected filename and still reads the renamed provider source, failing closed if it were absent, with every network/telemetry/self-update token retained and the `process.arguments = []`/`process.environment = [:]` assertions intact. `SnapshotBrowserClassificationTests` replaced the obsolete "no real helper exists in a normal build" premise with a truthful detached-source premise, and the paired real-helper test asserts the helper is resolvable in the test-host bundle — so the retained `.unavailable` + zero-row assertions now genuinely prove pre-inference source resolution wins over a present helper, and would fail if the provider were reached and returned `noMatch`. No weakened assertion was hidden as rename adaptation.

Automatic-invocation isolation holds: the only production construction of `BundledFiletypeClassificationProvider` is inside `productionStart`, reachable solely from the `SelectedEntryClassificationControl.start` closure, which is wired only to the explicit `Button("Classify selected file")`. Capture, launch, history open, snapshot reopen, browsing, selection, search, comparison and JSON export do not invoke classification; there is no queue, bulk run, background watcher, `FSEventStream`, `DispatchSource` or backfill anywhere in `FSD/`, and the runtime retains its single global in-flight run guarded by `busy`. The only `DispatchQueue` uses are the pre-existing metadata-search path and the provider's own single owned blocking operation.

## Notice-only correction (FACT)

The implementation report's one-byte notice correction was re-checked against physical state. `FSD/Helpers/THIRD_PARTY_NOTICES.txt` is 91 lines ending in exactly one LF after `// is preserved.` with no trailing blank line, and the four notice texts inside it are byte-verbatim copies of the pinned sources whose SHA256 values match the manifest. No production code reads the file — the only reader is the shipped test that compares the bundle copy to the repository copy — and the Xcode project copies it as an inert `Resources` entry. The delta is therefore genuinely notice-formatting-only and cannot change executable or test semantics; the audit additionally ran its own current full suite rather than relying on the Worker's earlier run.

## Test reproduction (FACT)

Independently obtained on the current tree, using `test-without-building` against a fresh
audit-only Debug derived-data tree, after an isolated clean build.

- Targeted real-helper file `FSDTests/BundledFiletypeClassificationProviderTests`: 32 executed / 32 passed / 0 failed / 0 skipped, exit 0.
- Focused classification suite (the eight suites `BundledFiletypeClassificationProviderTests`,
  `ClassificationEnrichmentTests`, `ClassificationSourceReaderTests`, `ClassificationProviderContractTests`,
  `ClassificationRuntimeServiceTests`, `SnapshotBrowserClassificationTests`,
  `ClassificationInvocationIsolationTests`, `ClassificationSecurityIntegrationTests`): 183 executed / 183 passed / 0 failed / 0 skipped, exit 0.
- Full fresh clean Debug XCTest: 494 executed / 491 passed / 0 failed / 3 skipped, exit 0, `** TEST SUCCEEDED **`.

The three full-suite skips were independently identified as exactly
`FSDProbeSeedTests/testSeedIsolatedProbeCatalog` (`FSD_PROBE_CATALOG` absent),
`FilesystemMatrixTests/testCaptureExternallyPreparedMountedFilesystem` (`FSD_MATRIX_SOURCE` absent) and
`FilesystemMatrixTests/testReopenCapturedSnapshotWithTheSourceDetached` (`FSD_MATRIX_OFFLINE_CATALOG` absent).
None is a classification, helper, provider, bundle or process test; the eight classification suites contain
zero `XCTSkip` calls, and the real-helper file fails rather than skipping when the committed helper is absent.
These independently obtained counts match the implementation's reported 32/32, 183/183 and
494 executed / 491 passed / 0 failed / 3 skipped exactly.

## Requirement / evidence map (49 groups)

1 E reviewer role/independence; all three canonical skills read; no implementer behaviour.
2 E physical re-anchor: root/branch/origin, clean 0/0 fetch, publication and technical ancestry vs 307791e.
3 E supplied BRAIN decision projected only; gate/next = this audit; rule-promotion ledger untouched; no production acceptance; no Slice 08 unblock.
4 E audit read/test-only: no production Swift, Go source, helper binary, manifest, notices, Xcode project, tests, schema or product doc mutated.
5 E baseline->publication diff limited to the authorized task033A paths.
6 E the four rescope test paths are the only scope added relative to task033.
7 E no compatibility alias remains; old provider production source gone; new concrete name used consistently.
8 E no unrelated product/schema/canonical-doc mutation; prior handoffs byte-identical; EVENTS append-only with prior lines an exact prefix.
9 E provider/helper receive no path, URL, FileHandle, descriptor, resolver, read callback, range callback or second source range.
10 E FSD owns source resolution and the bounded no-follow read; reader/runtime/protocol/repository byte-identical to accepted baseline.
11 E maximum source payload exactly 4096; no full-file read; no source mutation; no symlink or root escape introduced.
12 E no sampled byte persisted, hashed or logged; classification stays derived metadata that cannot mutate snapshot facts or comparisons.
13 E helper takes zero command arguments and reads stdin only; any argv yields failed.
14 E helper reads at most 4097 bytes; >4096 fails before any Match call.
15 E short-CFB guard: len<=513 plus D0 CF 11 E0 -> no_match, all metadata null, zero Match calls.
16 E guard scope matches the upstream ambiguous window exactly and was not widened during audit.
17 E empty-data handling matches ADR-035 exact Unknown + ErrEmptyBuffer conjunction.
18 E ordinary eligible data calls upstream Match exactly once (my implementation) / at most once per contract.
19 E recognised type copies direct upstream extension and MIME; Unknown maps to no_match; other errors map to failed.
20 E no transformed taxonomy, fallback MIME, sample echo, logging, source opening or runtime downloader/network in helper source.
21 E one strict seven-field JSON object with a single trailing LF; caps bounded (max observed 201 stdout, 0 stderr).
22 E toolchain archive SHA256 verified before extraction; module version/Sum/GoModSum verified against go.sum and proxy.
23 E writable Go state scratch-local; GOENV=off; GOTOOLCHAIN=local; no GOTELEMETRY; no Owner-global config mutation.
24 E Go commands network-denied under sandbox and consume only the scratch-local exact file:// module proxy.
25 E two fresh independent audit rebuilds performed in separate new scratch trees.
26 E both audit rebuilds byte-identical to each other and to the committed helper.
27 E short-CFB lengths 4/32/513 deterministic no_match across fresh processes.
28 E CFB-prefixed lengths >=514 (DOC/XLS/PPT and non-matching) single-valued across fresh processes; 1150 launches no multi-value.
29 E pinned PNG/DOCX/XLSX/PPTX bounded fixtures independently probed and proven to be the upstream module's own 4096-byte prefixes.
30 E Match-call counts proven on the actual shipped bytes by static call-site analysis and by LLDB breakpoint counts on the final SHA.
31 E symbol/address provenance bound to the exact final helper SHA via image lookup and manifest cross-check.
32 E manifest recomputed against physical contents: helper SHA, canonical source-set SHA, module/toolchain fields, flags, GOOS/GOARCH, minos, detectorVersion.
33 E committed helper is a binary-safe Git blob; no .gitattributes, info/attributes, autocrlf, eol or attributesFile transformation.
34 E file/lipo/vtool/otool -L/go version -m: arm64 only, minos 13.0, Go1.27.1, sole filetype dependency, system dylibs only, no model/database/resource.
35 E notice closure bounded to the four-part set, re-derived from 289 live source-mapped files with all four digests matching.
36 E Xcode: one helper Copy Files phase at Contents/Helpers with only the helper and CodeSignOnCopy; notice in Resources; empty shell-script section; narrow COPY_PHASE_STRIP.
37 E fresh isolated clean Debug and Release builds succeed with no Go, downloader or network step in the build log.
38 E unsigned Debug/Release bundles carry the exact helper and notices; helper bytes equal committed and manifest; no Go toolchain/cache/module/model/database bundled.
39 E process behaviour: normal completion, crash, termination, cancellation, five-second timeout, cleanup/reap and bounded caps exercised by the shipped suite on the real child.
40 E zero sockets and zero descendants observed on the final helper; no net or os/exec package in the 77-package closure.
41 E noMatch writes zero rows, mints no type or provenance row, stays neutral, and cannot overwrite a successor via stale completion.
42 E classified provenance: exact detector version github.com/h2non/filetype@v1.1.3, nil model/confidence, host-owned provider identity.
43 E cancellation cannot create success evidence; snapshot and entry immutable facts asserted unchanged.
44 E four rescope regression tests reviewed semantically; no weakened assertion hidden as rename adaptation.
45 E test reproduction: targeted real-helper, focused classification suite and full Debug suite with independently obtained exact counts.
46 E notice-only post-full-suite correction verified formatting-only and incapable of changing executable or test semantics.
47 E ad-hoc signing verification on a copy: inner-then-outer sign, deep strict verify and -dv facts; no Developer ID/notarization claim.
48 E no automatic invocation from capture/launch/history/reopen/browsing/selection/search/comparison/export; no queue, bulk, watcher or backfill.
49 N/A owner manual acceptance expressly deferred by the Owner; not performed and not claimed.

## Advisory, ownership and next boundary

1. Legacy Office determinism — accepted advisory, preserved verbatim per ADR-035 §9 and integration contract §7: the integration neutralizes the demonstrated short legacy-CFB ambiguity; available pinned realistic PNG/DOCX/XLSX/PPTX fixtures were single-valued in feasibility probes; the exact upstream pin contains no realistic legacy DOC/XLS/PPT fixtures, so general legacy-Office determinism is not proven. This audit narrows nothing and broadens nothing: it independently located the upstream ambiguity window at `len(buf) > 3 && len(buf) <= 513`, confirmed the guard covers exactly that window, and observed no multi-valued result in 1,150 fresh-process CFB launches including synthetic long DOC/XLS/PPT and non-matching branches at 514/515/1024/4096. Realistic legacy DOC/XLS/PPT determinism remains unproven.

2. Bounded observations — the match-call counts, socket/descendant absence, crash/termination/cancellation/timeout behaviour, fuzz results and bundle inspections are evidence about the specific runs performed on this host, not universal guarantees. The five-second timeout is asserted by the shipped test as an elapsed lower bound together with a single failed append, not as an upper bound.

3. Precision note, not a defect — `syscall.Open` is present in the shipped binary via `os.openDirNolog` and the `time` timezone reader. Nothing reachable from `main.classify` or `filetype.Match` calls it and the helper receives no path, so "never opens a classified source" is accurate, but the claim should not be restated as "the binary contains no file-opening capability".

4. Audit-tool footprint, disclosed for completeness — the Owner-global Go telemetry directory gained one `local/addr2line@…count` entry from my own read-only Go introspection during this audit, not from the controlled rebuild: both rebuild runs reported identical internal before/after metadata diffs and the rebuild never invokes `addr2line`.

No rejection-level defect was found and no material requirement is UNPROVEN.

## Ownership and next boundary

Reviewer evidence only. Accepted STATE owns `ACTION(FSD_CLASSIFIER_FILETYPE_INTEGRATION_AUDIT_034)` and this task's classification remains with BRAIN. This audit does not set production-provider acceptance, does not mark the integration audited, and does not unblock Slice 08; those remain BRAIN decisions. Exactly one proposal: `BRAIN_DECISION(PRODUCTION_PROVIDER_ACCEPTANCE_AND_SLICE08_GATE)`. Stop after finalizer publication; no repair, no Slice 08 work and no further task was started.

Raw recovery pointers (ignored, essential conclusions included above): `.ai-scratch/task034/` build-A/B environment/module/go/telemetry/deps/symbols objdump receipts and logs; audit-cfb-probes.json; audit-fixture-probes.json; audit-protocol-probes.json; audit-process-observation.json; audit-nm.txt; live-source-files.txt and live-files-clean.txt; text-symbol-addresses.txt; lldb/ case inputs and lldb_count.sh; audit-debug-build.log, audit-release-build.log, audit-test.log and the audit signing copy. No task033A self-report substitutes for this execution.
