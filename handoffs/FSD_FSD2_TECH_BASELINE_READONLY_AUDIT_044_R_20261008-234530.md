# FSD#2 technical baseline — Task044 independent Reviewer audit

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD2_TECH_BASELINE
HANDOFF_ID=handoffs/FSD_FSD2_TECH_BASELINE_READONLY_AUDIT_044_R_20261008-234530.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=2c435b071975a686d5e58b1c95281c9a5dc3c4f4
REMOTE_HEAD=2c435b071975a686d5e58b1c95281c9a5dc3c4f4
LAST_VERIFIED_AT=2026-10-08T23:45:30+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|docs/AGENT.md|STATE/PROJECT_STATE.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|docs/ARCHITECTURE.md|docs/PRODUCT_STATE.md|docs/UX_UI_SPEC.md|docs/PRD.md|docs/MVP_PLAN.md|docs/DECISIONS.md|docs/TEST_PLAN.md|docs/SECURITY_AND_READ_ONLY_POLICY.md|docs/CLASSIFIER_FILETYPE_INTEGRATION_CONTRACT.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-independent-review/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md
CURRENT_PHASE=POST_V0_1_TECH_BASELINE
CURRENT_GATE=FSD2_TECH_BASELINE_AUDIT
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_FOR_AUDIT_RETURN;STAGE_GO_REQUIRES_BRAIN_DECISION
PROPOSED_NEXT=OWNER_DECISION
NO_AUTO_NEXT=YES

## Task lock, result and authority

TASK_ID=FSD2_TECH_BASELINE_READONLY_AUDIT_044
ROLE=REVIEWER
MODE=READONLY_SOURCE_ARCHITECTURE_PERFORMANCE_BASELINE
BASE_HEAD=2c435b071975a686d5e58b1c95281c9a5dc3c4f4
UPSTREAM_HEAD=2c435b071975a686d5e58b1c95281c9a5dc3c4f4
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=READ_ONLY_CURRENT_SOURCE_SAFETY_ARCHITECTURE_PERFORMANCE_AND_STAGE_READINESS_AUDIT
ALLOWED_PATHS=STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|handoffs/CURRENT_HANDOFF.md|handoffs/FSD_FSD2_TECH_BASELINE_READONLY_AUDIT_044_R_20261008-234530.md
FORBIDDEN_PATHS=FSD/**|FSDTests/**|FSD.xcodeproj/**|Tools/**|docs/**|SCHEMA_AND_MIGRATIONS|DEPENDENCIES|RELEASE_TAG_ZIP_GITHUB_RELEASE|STATE/PROJECT_STATE.md|STATE/RULE_PROMOTION_LEDGER.tsv|PREVIOUS_HANDOFFS|OWNER_CATALOG_SOURCE_VOLUMES_AND_PERSONAL_MEDIA
SUCCESS_CRITERIA=EXACT_REANCHOR;SOURCE_REFERENCED_BASELINE_AND_SAFETY_TRACE;ISOLATED_BOUNDED_MEASUREMENTS;TECHNOLOGY_AND_STAGE_MATRIX;ONE_REVIEWER_REPORT;CANONICAL_REPORTING_CLOSURE
VALIDATIONS=GIT_FETCH_IDENTITY;TRACKED_BYTE_DIGESTS;SOURCE_TEST_REVIEW;ISOLATED_XCTEST;OPTIMIZED_SYNTHETIC_PROBES;EXPLAIN_QUERY_PLAN;SELF_RSS;PUBLIC_RELEASE_READ_RECEIPT;ALLOWLIST_DIFF;FINALIZER_CHECKER;DESKTOP_PARITY
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY

Reviewer-local audit result: **PASS_WITH_ADVISORY**. This means the authorized audit was performed and its limitations disclosed. It does not approve Stage 0–6, certify the application for production, accept a manual gate, or authorize repair. No CRITICAL or HIGH product defect was established in this bounded audit. Two MEDIUM functional gaps were reproduced: incomplete wide-folder outline presentation and existence-only source availability. Additional scale/authority advisories are below.

Evidence labels used throughout:

- **FRESHLY_OBSERVED**: this task's physical Git, source-byte, command, fixture or callback observations.
- **SOURCE_DERIVED**: behavior traced from the current implementation; not a fresh runtime observation unless explicitly paired with one.
- **PRIOR_ACCEPTED_EVIDENCE**: named earlier evidence accepted by BRAIN, not rerun here.
- **INFERENCE**: bounded judgment based on the cited facts, not direct measurement.
- **UNPROVEN**: deliberately unmeasured, deferred or not established. Capability absence and unresolved future contracts are audit findings, not omitted audit work.

### Fresh baseline and authority map

**FRESHLY_OBSERVED:** physical Git root `/Users/cenvu/DEV/FSD`, branch `main`, origin `https://github.com/cenvu/FSD.git`; non-destructive fetch verified HEAD = origin/main = expected base, ahead 0 / behind 0, clean tracked/untracked worktree before reporting. A baseline manifest hashes all 1,501 tracked files; all remained byte-identical after probes and before reporting. Protected-byte postflight rechecks use that original manifest, not a recaptured baseline. There are 96 prior immutable historical handoffs and 78 tracked files under FSD/FSDTests. Manifest: `.ai-scratch/task044/base-hashes.json`.

Accepted `STATE/PROJECT_STATE.md` SHA256 is `b980d39d092f86879cb76f8ae246ff81a297277a7ec753a50b8ce23c891449da`. It remains unchanged. Its accepted implementation pointer is Task043 publication `5c74b88761206c22a3f2b8c64cbed99521ae4726`; the newer audit authorization projection is baseline `2c435b071975a686d5e58b1c95281c9a5dc3c4f4`.

| Authority | Meaning and resolution |
|---|---|
| Exact Owner/BRAIN Task044 instruction; AGENTS.md; three loaded execution/review/finalizer skills | One read-only Reviewer cycle, isolated validation and reporting-only public publication. No delegated agent, product repair, dependency experiment or next task. |
| STATE/PROJECT_STATE.md; Task043 ledger row; final two BRAIN events at 2026-10-08T23:08:42+07:00 | Task043 accepted PASS_WITH_ADVISORY; exactly one live decision authorizes this Task044. State is acceptance authority, not old CURRENT's pending status. |
| CURRENT at entry: Task043 handoff | Prior Worker evidence, including 80/80 tests and actual UI screenshots. Its old pending-BRAIN status is superseded by accepted STATE/events. Historical bytes preserved. |
| docs/BRAIN_OPERATOR.md v1.3.0; docs/AGENT.md | Role, read-only boundaries, manual evidence distinction, one pending return, immutable history and Desktop transport. |
| ARCHITECTURE, PRODUCT_STATE, PRD, MVP_PLAN, DECISIONS, TEST_PLAN, UX_UI_SPEC, security policy and classifier contract | Scoped product contracts and documented gaps; implementation statements must be checked against source and accepted STATE. All required files were inspected; only question-specific additional source/schema/helper/fixture files were expanded. |
| Actual FSD source, Xcode settings, schema and tests | Current implementation truth. No separate FSD#2 repository/application. Earlier DRS#1 handover is future stage direction only. |

**SOURCE_DERIVED authority advisory:** UX_UI_SPEC §17 still calls the real runtime/schema-v9/Data-only request absent; TEST_PLAN's opening reconciliation still says inactive/v8; several task035 status paragraphs still say final runtime acceptance pending. Accepted STATE records Task036's completed independent audit and Phase 1.5 technical acceptance, and physical source implements them. These old status sentences do not revoke implementation or authorize work. Contract-time `NOT_IMPLEMENTED` in the filetype contract is explicitly historical contract state, not current source absence. No document was repaired.

### Public binary versus later main

**FRESHLY_OBSERVED:** `gh api repos/cenvu/FSD` reports PUBLIC/main. `gh api repos/cenvu/FSD/releases/tags/v0.1.0` reports prerelease ID `406906419`, title `FSD v0.1.0 — First Public Test`, published `2026-10-08T14:12:11Z`. Annotated tag object `b0bd9c4cfb6cc17e90f2c2733fda604d381bf9f7` peels to audited candidate `8a4223eeba93306ecba0262e4dbe38efed96c704`.

ZIP asset ID `622022503`, size 3,542,111 bytes, API digest `sha256:6c840c66ca2677e849e64dc0802890ae8aa60d2901db7ed9d9c863884ee16134`, updated `2026-10-08T14:12:11Z`. SHA256SUMS asset ID `622022504`, size 95 bytes, digest `sha256:1b3e076a81c09b11ca64c0ab375f39f8a0eeaf14e9640965c893239934ee7642`, updated `2026-10-08T14:12:10Z`. Task044 did not download/run/replace the release ZIP. Anonymous byte-download verification remains Task042 **PRIOR_ACCEPTED_EVIDENCE**. Current API identity/digests are fresh, not a second binary inspection. Receipt: `.ai-scratch/task044/release-baseline.json`.

`git diff v0.1.0^{} HEAD -- FSD FSDTests FSD.xcodeproj docs/database Tools` contains only two pane-minimum edits in `FSD/UI/SnapshotBrowserView.swift`: outline 380→320 and inspector 260→220, published in Task043. All reviewed backend/test/schema/helper implementation is unchanged relative to the public candidate. Main and both locally built test hosts still declare 0.1.0/build 1. **Task043's repaired layout did not ship in public v0.1.0.** This audit creates no new release.

## Implemented capability inventory

The status applies to current main; public binary distinction above governs the layout fix. A passing subset is automated evidence, not Owner acceptance.

| Capability | Status | Direct implementation / test evidence |
|---|---|---|
| Native macOS 15+ arm64 SwiftUI/AppKit app | IMPLEMENTED | FSD.xcodeproj/project.pbxproj:236–241 sets platform/arch/Swift5.9; FSD/App/FSDApp.swift:1 and SnapshotBrowserView.swift:326; fresh Debug/optimized Release test-host compilation. |
| Local SQLite catalog, explicit migrations and schema verification | IMPLEMENTED | CatalogDatabase.swift:82,245,259,298,323; CatalogMigrations.swift:25,32,274; fresh SchemaMigrationTests plus 18 actual ExpectedStateInventory/TerminalCollision tests. |
| Default native mounted metadata scanner/provider separation | IMPLEMENTED | SnapshotScanner.capture; FilesystemProvider.enumerate; NativeMountedProvider.enumerate/emit; SnapshotWriter.beginCapture/persist; eight fresh Milestone2CaptureTests. EmbeddedRawProvider production integration ABSENT; no generic nine-filesystem support claim. |
| Batched capture totals and immutable entries/capture facts | IMPLEMENTED | SnapshotWriter.swift:339,375,491,502; schema complete-root/capture-facts/completed-entry triggers; SnapshotLifecycleTests, SnapshotHistoryTests, Milestone2CaptureTests. Capture is an interval, not an atomic filesystem image. |
| Subtree aggregates/signature generation and skipping | ABSENT | Scanner/writer compute snapshot totals, not per-directory aggregates/signatures; nullable schema signature fields do not prove computation; ComparisonEngine.merge emits per-entry evidence. docs/ARCHITECTURE.md:146,265 and PRODUCT_STATE KI-016 retain the gap. |
| Interruption/cancellation and startup recovery | IMPLEMENTED | RecoveryService.swift:21; token finalization lock; ApplicationModel.init lock-before-open/recovery; TransientSnapshotLifecycle; fresh M5Reliability, ComparisonMode, SnapshotLifecycle and capture tests. Physical unplug/manual crash acceptance UNPROVEN here. |
| Offline history/selected-entry inspector | IMPLEMENTED | SnapshotHistoryRepository.listSnapshots/summary; SnapshotTreeDataSource.details; SnapshotBrowserModel.open/select; fresh history/search/reader tests and generated deletion fixture. Per-source latest-complete facade and paged per-drive history ABSENT. |
| Lazy bounded repository tree queries | IMPLEMENTED | SnapshotTreeDataSource.root/children, default500/request-clamped page; indexed parent/sort; fresh LazyTreeBrowsingTests and 10k/100k probe. |
| Complete wide-folder outline browsing and globally bounded UI cache | PARTIAL | Coordinator.children at SnapshotBrowserView.swift:401 fetches one default page and caches it; no next-page control/collapse eviction. Fresh callbacks: 1,000 stored children → 500 exposed; repository paging exists but UI does not consume later siblings. |
| Indexed offline metadata search | IMPLEMENTED (single snapshot) | MetadataSearchService.swift:124, bound ≤5,000, folded literal substring LIKE, issue annotation; MetadataSearchTests and query-plan/latency probes. Source-wide/Library-wide scope, search-result continuation and classification search ABSENT. |
| Ordered streaming metadata comparison | IMPLEMENTED | ComparisonEngine.swift:47,187,548,604; 5,000 rows/side default, 2,000-result batches, equal-key cap100,000/side; exact outcomes, profile revision and eligibility. Fresh semantics/lifecycle/100k fixtures; giant collision cap is source/prior scale evidence, not rerun. |
| Persisted comparison UI paging/navigation | IMPLEMENTED | ResultRepository.results LIMIT/OFFSET and navigate key anchors; BrowserModel replaces one ≤500-row page, generation suppression; 100k first/deep pages measured. Synchronized relative hierarchy/ancestor reveal PARTIAL/ABSENT; live-side history remains transient. |
| Explicit selected-entry file classification | IMPLEMENTED | SnapshotBrowserModel.productionStart/classifySelectedFile → runtime actor → bounded reader → fixed filetype helper → append API. Source-reader57 + invocation-isolation8 fresh; actual provider integration/runtime acceptance is prior Task034/036 evidence. No Magika integration. |
| Local-only/offline-first behavior | IMPLEMENTED | CatalogLocationResolver/ApplicationModel; database-only history/search/snapshot compare; no runtime web/client/source sync path in reviewed code; helper source stdin-only. Fresh helper hashes match accepted artifact. Universal network/process behavior is not re-proven by a code search. |
| Drive awareness/source identity/Overview/Collections | PARTIAL | Volume UUID/fallback registry and capture-time facts exist. All Drives/Connected Now/Library search explicitly unavailable in ComparisonSharedViews.swift:194,259,420. Dashboard has recent lists but unavailable aggregate cells:579. Collection/default tables exist; Collection-facing repository/UI ABSENT. |
| Quick Look, derived preview cache, opt-in autosnapshots | ABSENT | No corresponding implementation in tracked production target; not implied by content-type metadata, classifier sampling, placeholders or snapshot tables. Stages4–6 need new explicit contracts. |

## Actual architecture traces and safety review

### A. Capture and filesystem provider

**SOURCE_DERIVED:** `ApplicationModel.chooseSource` (`FSDApp.swift:152`) uses a directory-only NSOpenPanel with folder creation disabled. `startCapture` (:167) dispatches work off MainActor. `SnapshotScanner.capture` resolves the root with FilesystemDetector, constructs NativeMountedProvider and opens a SnapshotWriteSession. Detector canonicalizes the selected root alias; provider keeps entry URLs lexical. Provider prefetched URL metadata + lstat/readlink-like link metadata record entries without opening regular-file payloads, skip packages, do not traverse directory symlinks, and record/skip observed `st_dev` mount boundaries.

Scanner buffers 2,000 entries by default; writer stores each batch and snapshot total deltas in one `BEGIN IMMEDIATE` transaction. Parents are resolved from SQLite, rather than held as a whole-tree map. Root and source locator are persisted at admission. Finalization flushes pending entries, then commits terminal status/warning count under the cancellation token's shared lock. The completed transition occurs only after entry/totals transactions committed. Orphan startup scans become interrupted, never synthesized complete; the process lock is acquired before open/recovery. Fresh fixture tests verify root links/totals, late-cancel behavior, completed-entry rejection, idempotent recovery and source listing preservation.

**Limits:** no filesystem-wide namespace lock or atomic capture view; source-device probes that cannot observe a boundary do not invent one (`NativeMountedProvider.crossesMountBoundary`). Existing MilestoneConditionTests define nested-mount, symlink-sibling and generated-image checks; these were inspected, not executed here because the generated-image case mounts media. No new physical-mount/supported-filesystem proof is claimed. Per-directory totals/signatures and mount-event cancellation service are absent.

### B. Catalog and migration boundary

**SOURCE_DERIVED:** the actual architecture is **one shared read/write SQLite handle**, opened `READWRITE|CREATE|FULLMUTEX` and wrapped with NSRecursiveLock, not a writer actor plus a separate read-only comparison connection. Scanner/search/compare run synchronous operations on GCD workers and share ApplicationModel's catalog. `CatalogDatabase.query` materializes its result array, so repository LIMITs are the effective row bounds. No connection pool or statement cache was found: every call prepares/binds/steps/finalizes a statement; transaction locks cover BEGIN/body/COMMIT, rollback on error.

Each connection applies foreign_keys ON with verification, busy_timeout5000, synchronous NORMAL, temp_store MEMORY and WAL. Fresh databases use bundled schema once, atomically. Existing v4 (both known variants) moves through v5→v6→v7→v8→v9; 1–3/future/missing versions are rejected. Each migration commits statements + version together. v9 appends nullable/no-default provider_identifier only, leaving old rows NULL; root locator is not a second new v9 migration. Every open verifies ExpectedState tables, required added columns, and normalized canonical trigger/index SQL. Fresh migration/rollback and actual18 schema-inventory/evidence-immutability tests passed. Automated pre-migration backup is absent (ARCHITECTURE §297); transactional rollback is not a backup claim.

### C. Offline exploration and search

**SOURCE_DERIVED:** history reads user snapshot rows, immutable capture-time facts and statuses without live source access. ApplicationModel hands a stored summary to SnapshotBrowserModel; `open` loads root+bounded issues and makes the optional existence-only availability check. Coordinator root expansion asks SnapshotTreeDataSource for direct children. Entry selection reads one entry and its latest stored classification; selection cancels stale inference ownership and starts none. Search runs database-only on GCD, preserves snapshot ID, literal wildcard escaping and folded keys, caps rows, annotates issues only for returned hit IDs, then suppresses stale results by generation. It never consults source payloads/classifications.

**FRESHLY_OBSERVED gap:** actual AppKit data-source callbacks expose only500 of1,000 children. `children` catches any load error with `try?`, converts it to `[]` and caches it: a closed synthetic catalog produces0 children and a cached empty branch. This is independent of source availability and does not delete metadata. The row has `hasChildren`, but no error/retry/truncation presentation. UI cache retains pages for visited descendants until root replacement; no global eviction bound is implemented. Repository-only scale tests therefore do not prove complete wide-folder UI browsing or a globally fixed UI cache.

### D. Compare and disposal

**SOURCE_DERIVED:** UI freezes input mode/left-reference/right-changed/profile into the worker request. Snapshot/snapshot uses stored complete or complete-with-warnings sources; live modes first capture through the same scanner as transient snapshots. Engine refuses partial snapshots and normalization mismatch, freezes profile version, selects preserving keys only when both sources are sensitive (otherwise folded with unknown warning), merges SQLite-BINARY UTF8-ordered keyset streams, never pairs collisions arbitrarily, and persists bounded result/collision batches. Equal-key arrays are capped100,000 members per side and typed-fail above that; default pages/batches are bounded, not an assertion that configurable constructor sizes have a universal hard cap.

Terminalization recomputes counts from persisted evidence and commits under the cancellation-finalization lock. Failed/cancelled/orphaned work is not complete. Schema guards protect terminal results/collision evidence against mutation while explicit whole-comparison disposal cascades. v8's dedicated parent_result_id index supports cascade cleanup. `ComparisonResultRepository.results` uses count + LIMIT/OFFSET; only the **engine input streams** and adjacent-result navigation use keys. UI paging is not wholly keyset paging. BrowserModel retains one page; cross-page navigation uses repository anchors/positions. Workspace-close disposes live comparisons before transients, preserving user snapshots and snapshot/snapshot comparisons. Fresh ComparisonModeTests and M5Reliability prove synthetic close/recovery; no Owner Capture/Compare E2E acceptance follows.

### E. Explicit classification

**SOURCE_DERIVED:** inspector button → `classifySelectedFile` → `productionStart` → app-scoped ClassificationRuntimeService.start. The runtime admits one operation, returns busy without queuing, resolves source on a detached task, and launches inference only after the bounded reader has proved eligibility. Reader requires trustworthy schema-v9 capture context, exact current volume/mount identity, validated relative components, regular-file kind, no-follow descriptor-relative directory walk, dev+ino checks, a fresh pre-read object-authority barrier and post-read revalidation. It performs exactly one0…4096-byte offset-zero read; short reads are not topped up. The provider request owns only immutable Data, no source path/URL/fd/entry identity/resolver/range callback.

Fixed bundle helper receives stdin only, no arguments, empty environment. Host bounds stdout and discarded stderr cumulatively4096 each, validates the flat seven-field metadata envelope, kills/reaps on failure/cancellation, and maps metadata only. Runtime's five-second deadline covers inference, not source I/O; ownership remains until cleanup drains. Generation/selection suppression blocks stale UI publication. `mappedResult` appends classified/failed/sourceChanged/unsupportedEntry rows (failed status for the latter three), and zero rows for unavailable/cancelled/noMatch. EntryClassificationRepository exposes append/latest/history/page APIs, rejects duplicate runs and has no update/delete API. Append-only is an application API guarantee, not a new database UPDATE/DELETE trigger guarantee (MVP_PLAN Phase1.5 states this distinction). Classification never modifies entries/snapshot status/totals/comparison results. It represents current-source inferred type, never historical byte proof.

**FRESHLY_OBSERVED:** committed helper and both fresh unsigned test-host bundle copies hash to accepted `665a6569ee60614313e50629c4166358b89859f15dac4c522905ee5a730752e7`. No Go invocation, helper rebuild, dependency install or PoC ran. Helper source `Tools/FSDClassificationHelper/main.go` reads at most4097 stdin bytes, rejects over4096, applies short CFB `len≤513 + D0CF11E0 → no_match` before Match, then at most one pinned filetype.Match. It opens no source. Universal realistic legacy DOC/XLS/PPT determinism stays UNPROVEN; accepted bounded realistic PNG/DOCX/XLSX/PPTX evidence and reproducibility/notice/network closure remain prior Task033A/034/036 evidence.

### Risk / invariant / guard / evidence / gap matrix

| File/symbol | Invariant → current guard | Test/observation | Gap / severity |
|---|---|---|---|
| NativeMountedProvider.enumerate/emit; SnapshotScanner.capture | Default no source writes/payload reads → metadata-only provider contract; no source-mutation API; symlinks/packages not descended | Fresh Milestone2CaptureTests.testNativeProviderStreamsNestedMetadataAndDoesNotFollowSymlink / testSourceListingIsUnchangedByCapture; ComparisonModeTests.testLiveCaptureLeavesTheSourceByteForByteUnchanged; reader57 | Source listing and code trace are bounded evidence, not universal syscall tracing or physical unplug proof. Namespace/dev probe limitations remain; ADVISORY, no observed write defect. |
| SnapshotWriter.persist/finish; RecoveryService.recoverOrphanedScans; snapshot schema triggers | Completed facts immutable; interrupted never complete → transaction totals/root guard/token lock; completed entry INSERT/UPDATE/DELETE guards; comparisons reject partial sources | Fresh SnapshotLifecycle, Milestone2Capture, history, ComparisonSnapshotState and M5Reliability suites | Atomic filesystem image and automatic last-complete per-source facade absent; no observed lifecycle regression. ADVISORY. |
| CatalogDatabase.apply/verifyCurrentSchemaState; CatalogMigrations | Known schema only, no partial migrations → transaction+recorded version and object definition verification | Fresh migration tests + ExpectedStateInventoryTests/TerminalCollisionEvidenceTests18; probe integrity/FK clean | Backup absent; shared connection serializes work, no measured contention budget. LOW/ADVISORY. |
| LazyMetadataOutlineView.Coordinator.children; SnapshotTreeItem.children | All stored siblings discoverable, load failures explicit, bounded large-tree browsing → lazy first page only | Fresh AppKit callback probe: actual1000/exposed500; closed DB→empty cached branch; repository LazyTreeBrowsingTests pass | No continuation/error state; cached visited pages lack eviction; tests only prove repository bounds. MEDIUM (F1). |
| SourceAvailabilityProbe.availability; SnapshotBrowserModel.open | Truthful source state → `fileExists(mount_path_at_capture)` only | Fresh scratch capture then root removal: root_exists=false, reported=available; SnapshotHistoryTests cover path availability, not stable identity | Existence cannot establish captured drive/root identity; label is sampled only on open, no mount observer. MEDIUM (F2), not a bypass of classifier's stronger reader. |
| MetadataSearchService.search | Offline bounded results/literal semantics → LIMIT≤5000/folded escaped LIKE/indexed snapshot range | Fresh MetadataSearchTests; actual10k/100k latency and plan | `%needle%` may inspect snapshot-wide rows; no continuation/Library scope. LOW (F3), measured acceptable only for this fixture; no invented SLO breach. |
| ComparisonEngine.EntryStream/merge; ResultRepository.results/navigate | Metadata equivalence only, bounded inputs/results → keyset pages, group cap, terminal guards, one UI page | Fresh semantics,100k exact outcomes and deep result pages; schema18; prior million/collision evidence | Output OFFSET/count query grows with page depth; no subtree skipping/hierarchy reveal; pathological peak not freshly measured. LOW/ADVISORY (F4). |
| BoundedClassificationSourceReader; runtime; provider; append repository | Explicit bounded read, failures never rewrite facts → exact identity/no-follow/single read/Data-only/global single flight/generation/typed rows | Fresh source-reader57 and invocation-isolation8; helper hashes; prior runtime audit | Object proof is point-in-time; helper not OS sandboxed solely by Data-only IPC; source read has no5s deadline; universal network/process schedules/legacy determinism UNPROVEN. No new exploit established; ADVISORY. |

No false content-equivalence claim was found in the traced comparison engine/browser contracts: Fast Metadata/Structure/Strict Metadata compare stored facts; UI exposes “Metadata only. Content Not Verified.” (`SnapshotBrowserView.swift` footer; ComparisonWorkspaceView/ComparisonSharedViews summary/disclosure). Classification has its own historical-content disclaimer. Preserving these semantics is a requirement for every future stage.

## Bounded fresh performance and test evidence

### Isolation, fixture selection and environment

**FRESHLY_OBSERVED:** MacBookPro18,2, arm64,64GiB RAM; macOS15.7.7(24G720); Xcode26.3(17C529); Apple Swift6.2.4. Production language setting Swift5.9. Environment receipt: `.ai-scratch/task044/environment.json`.

Before execution, reviewed setup/teardown, source generators, catalog location and sizes. FinalScaleSnapshot/Comparison/Memory tests default to million-class catalogs, exports or pathological150k-key groups (Memory class setup creates million fixtures even for a selected method); excluded entirely. Existing LazyTreeBrowsing's SyntheticCatalog supports configurable dimensions; ComparisonScale's100,202/side fixture is bounded; small scanner/classification/recovery tests own disposable temporary folders. No external filesystem/probe seed tests, disk-image mount, Owner catalog or personal source was selected.

XCTest uses the application as a **permitted test host**; CatalogLocationResolver recognizes XCTest and isolates the startup catalog. Observed Debug host path: `/var/folders/…/T/FSD-TestHost-18191/catalog.sqlite3 (source: testHost)`. Setting TMPDIR for xcodebuild did not relocate that macOS-launched test host; these generated XCTest directories are system-temporary, not claimed to be task scratch. Standalone probes explicitly create only `.ai-scratch/task044` synthetic catalogs and never initialize ApplicationModel/default catalog.

The optimized probe reuses `SyntheticSnapshot` from FSDTests/TestSupport.swift (scratch copy removes only @testable import); bounded1,001-entry directory batches call its existing insert routine in production CatalogDatabase transactions. Same production schema/guards, not a second database implementation. Two complete snapshots at each size:10,011/side (10×1000 files+dirs+root) and100,101/side(100×1000+dirs+root), exactly100 logical-size changes. One generation/compare/disposal per size,3 repetitions of each query; no1M run. It measures synthetic metadata insertion/query/comparison, not filesystem scanner throughput. Scratch AppKit probe compiles the unchanged original SnapshotBrowserView and other production components, directly exercises actual NSOutlineViewDataSource callbacks, and displays no Owner window.

### Exact commands, results and failure accounting

Commands execute from the canonical root. Full logs/xcresults remain ignored RAW. These are independent runs; counts are not a full-suite claim.

```sh
TMPDIR="$PWD/.ai-scratch/task044/" xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath .ai-scratch/task044/debug-derived -resultBundlePath .ai-scratch/task044/focused.xcresult -parallel-testing-enabled NO -only-testing:FSDTests/LazyTreeBrowsingTests -only-testing:FSDTests/MetadataSearchTests -only-testing:FSDTests/SnapshotLifecycleTests -only-testing:FSDTests/SnapshotHistoryTests -only-testing:FSDTests/SchemaMigrationTests -only-testing:FSDTests/SchemaSafetyCorrectionTests -only-testing:FSDTests/ComparisonSemanticsTests -only-testing:FSDTests/ComparisonScaleTests/testHundredThousandVersusHundredThousandComparison -only-testing:FSDTests/ClassificationInvocationIsolationTests -only-testing:FSDTests/ClassificationSourceReaderTests test
```

Result marker TEST SUCCEEDED; xcresult166/166 passed,0 failures,0 skipped; selected tests26.777s. Initial asynchronous shell's final exit code was not retained; the completed log and `xcresulttool` Passed summary, not an invented exit receipt, establish success. The file-named SchemaSafetyCorrectionTests selector names no XCTest class; it contributes **zero** coverage. Exact real classes were selected separately below. Logs: focused-test.log/focused-summary.json.

```sh
TMPDIR="$PWD/.ai-scratch/task044/" xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath .ai-scratch/task044/debug-derived -resultBundlePath .ai-scratch/task044/schema-safety.xcresult -parallel-testing-enabled NO -only-testing:FSDTests/ExpectedStateInventoryTests -only-testing:FSDTests/TerminalCollisionEvidenceTests test
```

Exit0;18/18 passed,0 failed/skipped; selected tests0.602s. schema-safety-test.log/schema-safety.exit/schema-safety-summary.json.

Initial Release attempt used release-derived and release-scale.xcresult, configuration Release and only ComparisonScaleTests/testHundredThousandVersusHundredThousandComparison. **Exit65**, build failed before tests: unable to find FSD module dependency for @testable test imports. Release project settings do not enable testability. Classified CONFIGURATION, not an engine failure. One evidence-backed retry adds only command-line ENABLE_TESTABILITY=YES; no Xcode/scheme/source edit:

```sh
TMPDIR="$PWD/.ai-scratch/task044/" xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Release -destination 'platform=macOS,arch=arm64' -derivedDataPath .ai-scratch/task044/release-derived -resultBundlePath .ai-scratch/task044/release-verified.xcresult ENABLE_TESTABILITY=YES -parallel-testing-enabled NO -only-testing:FSDTests/ComparisonScaleTests/testHundredThousandVersusHundredThousandComparison -only-testing:FSDTests/M5ReliabilityTests -only-testing:FSDTests/ComparisonModeTests -only-testing:FSDTests/ComparisonSnapshotStateTests -only-testing:FSDTests/Milestone2CaptureTests test
```

Exit0;39/39 passed,0 failed/skipped; selected tests14.939s. This is an **optimized Release testability-enabled host**, not a clean normal Release distribution or newly shipped patched build. release-scale-test.log/exit preserve initial failure; release-verified-test.log/exit/release-summary.json preserve success. Test-result summaries were extracted with `xcrun xcresulttool get test-results summary --path <bundle> --format json` (exit0).

Standalone optimized Swift build argv is recorded exactly in probe-build-command.json; it uses `xcrun swiftc -O -module-cache-path .ai-scratch/task044/module-cache`, original Foundation catalog/model/provider/scanner/browser/search/diff/classification Swift files, the scratch SyntheticSnapshot and main.swift, output baseline-probe. Build exit0; `.ai-scratch/task044/baseline-probe` exit0; output probe.log/probe.exit. No helper inference is invoked. RSS uses mach_task_basic_info on **self only**, no process listings.

AppKit probe's first scratch build exit1 because the command omitted JSONSnapshotExporter.swift; production source was intact. One bounded retry adds that existing original Export source to the compile list (retry-build-command.json), build exit0; ui-probe/outline-probe exit0. observed.log records the1000/500 and error-as-empty assertions. This tests callbacks, not rendered scrolling/manual UI.

### Observed timings

All below **FRESHLY_OBSERVED**, ms unless specified. Values are exact fixture observations, no throughput/speedup/budget claims. After initial fixture creation the database was reopened; OS filesystem cache was not flushed. “First” means first request after reopen/comparison, **not cold storage**. Reps2/3 are repeated/warm requests. Probe shared the host with a Release build, so CPU/I/O contention was uncontrolled.

| Operation |10,011 entries/side |100,101 entries/side | Repetitions/scope |
|---|---:|---:|---|
| Synthetic insert+snapshot totals/completion, left/right |170.411 /168.369 |2688.951 /2982.934 |One per side; multirow fixture path, not scanner writer throughput |
| Reopen |8.038 |8.373 |One; OS cache uncontrolled |
| Root single row |0.072 |0.071 |One |
| Root first page (10/100 directories) |0.091 |0.716 |One; different returned root-row counts |
| First folder expansion,200 rows |0.513 /0.512 /0.506 |0.524 /0.554 /0.535 |Three; repository query only |
| Search f00500 (10/100 hits) |3.128 /1.509 /1.455 |20.871 /19.229 /19.070 |Three; limit100;100-hit response conservatively labeled truncated |
| Search no-match zzzz-no-match |1.109 /1.242 /1.102 |16.805 /16.738 /16.652 |Three; full candidate range may be inspected |
| Search f00999 (10/100 hits) |1.452 /1.491 /1.336 |19.696 /19.056 /19.666 |Three |
| Full persisted metadata comparison |709.942 |9491.893 |One per size;100 changes; totals10,011/100,101 |
| Result page offset0,100 rows |0.582 /0.561 /0.546 |3.236 /3.523 /3.905 |Three; includes count query |
| Deep result page, offset9900/99900 |4.425 /4.234 /4.537 |46.954 /45.873 /46.295 |Three; LIMIT/OFFSET, not keyset |
| Whole-comparison disposal |81.159 |1264.841 |One; user snapshots preserved; post-disposal integrity/FK clean |

Production existing XCTest infrastructure corroboration:

| Test / build | Fixture | Observations |
|---|---|---|
| LazyTreeBrowsingTests.testLargeCatalogOpensAndExpandsWithoutEagerLoading /Debug |100,101 entries,100×1000 files |Insert2.96s; history0.0001s; root1query/1row; first100dirs0.0007s; expansion200rows0.0011s;100 search hits0.0210s; catalog main-file43,470,848 bytes (not WAL-inclusive total). |
| ComparisonScaleTests.testHundredThousandVersusHundredThousandComparison /Debug |100,202 per side, added/removed branch plus100 changes |Compare11.669s; first100row page0.0031s; differences-only0.0125s. |
| Same test /optimized Release+testability |Same deterministic fixture |Compare7.503s; first100row page0.0029s; differences-only0.0119s. |

Both100,202 tests assert complete,100,001 matched/100 changed/101 added/101 removed, total100,303 and bounded100-row pages. Do not interpret the separate Debug/Release observations as a controlled speedup experiment. That test's existing30s/1s assertions passed in this environment; this audit invents no new budget.

### Plans and memory limits

Production methods supply the measured operation timings. EXPLAIN plans in probe.log use representative projections/predicates matching their access paths (tree plan omits correlated hasChildren, merge projection selects id); no query/index was tuned:

- Tree `(snapshot_id,parent_id) ORDER BY sort_key,id`: covering idx_entries_snapshot_parent_sort.
- Literal name-or-path `%needle%`, ordered folded path: idx_entries_snapshot_case_folded_path constrained by snapshot_id; **no selective text range** shown. Indexed snapshot access is not an FTS/full-text claim. Search scan-issue annotation stays hit-bounded.
- Merge cursor preserving key: covering idx_entries_snapshot_case_preserving_path with snapshot_id and key range.
- Result pages: sqlite_autoindex_comparison_results_1 by comparison_id; temp B-tree for right part of ORDER BY. OFFSET/count/deep-page growth is real; measured46ms deep query alone is not an SLO failure.

Self RSS endpoint after10k compare64,241,664 bytes; after100k compare102,940,672; largest logged endpoint105,365,504 after integrity/disposal. These are **resident snapshots at checkpoints, not sampled peaks, physical footprint, high-water deltas or app GUI memory**. Both sizes ran sequentially in one process, so allocator reuse and SQLite caches persist. Peak RSS, cold latency, UI frame latency/lock contention,100k real scanner throughput, pathological collision-group peak and fresh1M performance are **UNPROVEN** here. No watcher/sampler was started.

Both synthetic catalogs returned integrity_check=`ok`, foreign_key_check0rows, entry_classifications0rows. Prior accepted M5 evidence in TEST_PLAN §4 and the named M5 handoffs covers million-class fixtures and historical memory/disposal; no historical number is presented as fresh. Full Task036 suite494 executed/491 passed/0 failed/3 environment skips is prior accepted evidence only.

## Technology admission review

No dependency installation/update/migration/helper rebuild/PoC was authorized or performed. Current technologies are retained. External docs were read only from public primary-source pages; no FSD catalog, private paths/media or sample bytes were sent. These references describe upstream roles, not tested FSD compatibility, pinned candidate versions or admission.

| Pair | Current fact / candidate category | Admission judgment and evidence |
|---|---|---|
| Custom SQLite C wrapper vs GRDB | CURRENTLY IMPLEMENTED wrapper; GRDB FUTURE CANDIDATE | NO PRESENT EVIDENCE TO REPLACE. Wrapper's migration/safety semantics pass current tests and bounded measurements. A toolkit migration would require explicit parity for ExpectedState, transactions, errors, single-process lock and historical catalogs; no measured need for a pool was established. [GRDB upstream](https://github.com/groue/GRDB.swift) describes a SQLite application toolkit; detailed README was not fully rendered by the browser, so no version/API promise is made. |
| Indexed metadata LIKE vs FTS5 | CURRENTLY IMPLEMENTED indexes/LIKE; FTS5 FUTURE CANDIDATE | NO PRESENT EVIDENCE TO REPLACE now. Worst-case scan behavior measured; Library scope may justify future study after workload/semantics/budgets. FTS5's token/prefix semantics and optional trigram approach must preserve current literal substring, escaped wildcard, Unicode, offline and immutable-index contracts. [SQLite FTS5 docs](https://www.sqlite.org/fts5.html); source SearchService and probe plans. |
| Lazy NSOutlineView vs another tree UI | CURRENTLY IMPLEMENTED AppKit bridge; alternative FUTURE CANDIDATE | NO PRESENT EVIDENCE TO REPLACE widget. F1 is incomplete paging/error/cache integration, not a demonstrated NSOutlineView limitation. First repair/exercise existing bridge and preserve row identity, keyboard/accessibility and bounds; no eager OutlineGroup admission. ADR-002, SnapshotBrowserView.swift:326, callbacks. |
| Metadata FileManager/URL scanner vs getattrlistbulk | CURRENTLY IMPLEMENTED native scanner; bulk API FUTURE CANDIDATE | NO PRESENT EVIDENCE TO REPLACE. Synthetic SQL timing is not scanner bottleneck evidence. Require isolated real enumeration profile plus parity for Unicode, inaccessible entries, symlink/package/mount/identity/cancellation before provider-local optimization. [Apple XNU manpage](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/man/man2/getattrlistbulk.2) defines directory-fd packed bulk metadata; it is not a source identity/transaction solution. |
| Streaming ComparisonEngine vs DifferenceKit | CURRENTLY IMPLEMENTED metadata engine; DifferenceKit possible FUTURE UI CANDIDATE | NO PRESENT EVIDENCE TO REPLACE engine. [DifferenceKit upstream](https://github.com/ra1028/DifferenceKit) concerns collection changesets/UI updates. It does not establish parity for SQLite streaming, normalization, collision uncertainty, frozen profiles, terminal evidence/disposal or content-not-verified semantics. No UI diffing need was measured. |
| GCD+Swift tasks/actor/token ownership vs AsyncChannel | CURRENTLY IMPLEMENTED mixed orchestration; AsyncChannel FUTURE CANDIDATE | NO PRESENT EVIDENCE TO REPLACE. Scanner's synchronous callback→batched writer already backpressures through catalog calls. Actor single-flight classification and generation checks work; changing scheduling requires a measured producer/consumer backlog and causal cancellation/disposal evidence. [Apple Channel guide](https://github.com/apple/swift-async-algorithms/blob/main/Sources/AsyncAlgorithms/AsyncAlgorithms.docc/Guides/Channel.md) describes asynchronous send/consumption backpressure, not automatic fixes for lifecycle. |
| Mount awareness vs FSEvents | Current mount observer ABSENT; existence probe PARTIAL. NSWorkspace mount/unmount awareness FUTURE CANDIDATE; FSEvents FUTURE optional change-awareness candidate | Stage2 first needs identity/reconciliation/status contract. [NSWorkspace didMount](https://developer.apple.com/documentation/appkit/nsworkspace/didmountnotification) is a mount notification API; [Apple FSEvents guide](https://developer.apple.com/library/archive/documentation/Darwin/Conceptual/FSEvents_ProgGuide/Introduction/Introduction.html) describes hierarchy change awareness. Change notifications cannot prove drive identity, atomic capture, or authorize background capture. No watcher ran. |
| Google Magika PoC vs accepted filetype helper | CURRENTLY IMPLEMENTED filetype1.1.3; Magika BLOCKED NON-EXCLUSIVE FUTURE CANDIDATE | NO PRESENT EVIDENCE TO REPLACE accepted helper. Task025 ledger accepted STOP lists unresolved model redistribution/hash/license-resource closure and then-macOS13 compatibility; macOS15+ is now the required floor and needs a fresh candidate gate. [Magika upstream](https://github.com/google/magika) identifies a model-based detector; its upstream performance/accuracy claims are not FSD measurements. Preserve accepted4096/Data-only/current-source/IPC/provenance/noMatch contracts; no PoC or install here. |

## FSD#2 Stages0–6 readiness matrix

Accepted handover stages are future product direction, reconciled with current source and scoped product contracts. **No row is GO authorization.** Complexity is an INFERENCE about technical work, not time/cost/schedule. Optional preview/cache/autocapture must not redefine baseline capture or comparison.

| Stage | Implemented foundations | Missing UX/backend contracts and identity/security questions | Dependencies and minimal GO evidence | Complexity |
|---|---|---|---|---|
|0 Foundation/technical baseline | Native shell; schema9/migrations/lock/recovery; capture and immutable offline metadata; bounded search/merge; fresh tests and10k/100k evidence | Resolve status-document drift, F1 tree completeness/error/cache boundary and F2 availability semantics; define baseline scope and preserve public-vs-patched distinction; no universal memory/cold/physical-media/manual proof | BRAIN adjudicates this audit, explicitly disposes findings and decides one bounded action; frozen accepted baseline/evidence and source safety retained. Completion of this audit alone does not mark Stage0 approved |LOW for baseline adoption/document reconciliation; F1's repair is a separate MEDIUM integration scope |
|1 Source-centric Overview/Explore/Search/Collections | Recent captures/comparisons shell, stored metadata inspector/tree/query APIs; volume registry; Collection/default schema | Source facade independent of raw snapshots; honest scopes (snapshot vs source vs Library), dashboard bounded aggregates, history pages/latest-complete, full sibling access/reveal, search continuation; Collection repo/organization UX absent. Folder identity and historical vs current metadata rules unresolved; Collections are snapshot grouping, not physical Drive Sets |Stage0 disposition; use stored-source identity without pretending strong physical identity before2. Source-centric UX must not claim drive identity, full-library search or existing Collections behavior. GO needs Owner-reviewed scope/semantics + bounded repository/UX fixture evidence; reconcile SNAPSHOT_COLLECTIONS contract and UX Drive Set ADR |MEDIUM: cross-module catalog facades/paging/organization while preserving immutable generations; physical identity is explicitly deferred to2 |
|2 Native Drive Awareness/honest connected/offline | UUID/fallback and capture-time volume facts; detector/native read boundary; classifier has stronger source revalidation | No mounted-source observer/identity evidence tiers/ambiguity/remount reconciliation/refresh lifecycle. F2 path existence can mislabel. Define folder vs drive/root availability; duplicate/cloned UUIDs, missing roots, eject/race, no name-only merges; no standing raw privileges |Stable0/1 source model + explicit PHYSICAL_DRIVE_IDENTITY_AND_MOUNT_POLICY decision. GO evidence: mount/unmount/remount/wrong-drive/same-name/missing-root fixtures, unknown state, no source writes/automatic content read. Truthful status must precede optional autocapture |HIGH: identity reconciliation and asynchronous mount/disconnect races across UI/capture/reader |
|3 History/dedicated Compare workspace | User snapshot history; durable snapshot/snapshot comparisons; three metadata profiles; persisted pages/outcomes/navigation and transient live lifecycle | Per-source history/latest/paging; synchronized hierarchy/ancestors/reveal; collision-member UI; durable-live retention decision and evidence lifetime. Preserve existing Left/Before, Right/After, uncertainty and Content Not Verified; no replacement engine without evidence |0 and1 catalog contracts;2 for live connected status. GO: exact category→locate→ancestors→select path across pages, profile/collision/partial-state parity, explicit live retention/close/reopen policy, cancellation/disposal fixtures. Existing engine survives |HIGH: hierarchical UI projection and durable-live evidence choices; snapshot-only scope can be narrowed by BRAIN |
|4 Explicit opt-in Quick Look | Selected-entry inspector and current-source validation pattern; no Quick Look implementation | Separate preview consent/payload-read boundary, live availability/identity proof, no historical-byte illusion; resolve symlink/package/security scope, missing source and preview-provider lifecycle/cancel/errors. Quick Look may read file contents beyond classification ceiling; never route it into default scan |Stable0–3 source/selection/state semantics. GO: separately accepted preview security/product contract, explicit action-only invocation tests, offline/wrong-source/selection-change refusal and supported fixture behavior. Classifier's bounded-read permission does not authorize preview |HIGH: system preview/provider content-access/lifetime boundary is distinct from metadata capture |
|5 Optional local bounded derived-preview cache | Local catalog/location and derived-metadata separation patterns; no preview cache | Cache opt-in/location/key/provenance, current-source vs historical preview labels, eviction/size/storage limits, stale-source invalidation, crash consistency/privacy/export/deletion policy; avoid source writes and snapshot-fact mutation |4's accepted preview output and consent;2 identity; stable preceding lifecycle contracts. GO: enforced size/eviction and interrupted-write fixtures, clear derived/cached/offline UI, no automatic preview/source read and immutable-fact checks. Cache is optional and not necessary for baseline browsing |MEDIUM: bounded derived-artifact storage/lifecycle; identity/security complexity inherits4 |
|6 Optional per-source opt-in autosnapshots | Capture batching/cancellation/recovery plus independent immutable generations; no scheduler or opt-in implementation | Per-source persisted opt-in, trigger/lifecycle/retention/no-focus-steal policy, duplicate/rate/backpressure limits, admission during eject/remount/change, no marker/privileged/watch fallback; failed/interrupted never replaces last complete; default off |2 truthful source awareness,1/3 source/history lifecycle and preceding stage decisions; previews/cache are not a technical prerequisite for metadata-only automation. GO: explicit policy/source-safety independent review, opt-in/off/revocation/relaunch/eject/race/retention fixtures and bounded scheduling. No background classifier/payload reads |HIGH: autonomous admission/retention/recovery and source races require stronger evidence than an explicit capture |

Stage4/5 direction extends previously out-of-MVP preview requirements and needs explicit scoped authority reconciliation; it does not silently override current metadata-only defaults. Stage6 direction similarly requires its own opt-in/lifecycle authorization. No stage or dependency was installed/implemented by this audit.

## Prioritized findings and persistent advisories

**CRITICAL:** none established. **HIGH:** none established within observed scope. This does not clear deferred privacy/security/manual gates.

**F1 — MEDIUM, wide-folder outline completeness and hidden load failure.** Evidence: SnapshotBrowserView.swift:317,401 and fresh ui-probe/observed.log (1000actual/500exposed; closed DB0cached-empty). Blast radius: users exploring any directory wider than default500 siblings cannot reach remaining children through the outline; a query error can look empty. Existing LazyTreeBrowsingTests prove repository offset pages/bounds, not Coordinator continuation/error presentation. UI caches accumulate visited pages; global cache pressure was not measured. Smallest repair direction for BRAIN: one bounded native-outline continuation/truncation/error-state task with meaningful actual callback/GUI evidence and retained-page policy. No widget replacement, schema migration or broad UI redesign is justified.

**F2 — MEDIUM, connected label lacks identity/root proof.** Evidence: SourceAvailabilityProbe.availability at SnapshotHistoryRepository.swift:126 and scratch availability probe in main.swift/probe.log. Selected root removed, mount `/System/Volumes/Data` still exists, result available. Same-mount-path replacement identity is SOURCE_DERIVED from the existence-only branch, not separately mounted here. Blast radius: informational source status; classifier separately checks exact identity/object authority, so no classification bypass is claimed. History tests do not establish drive identity/live refresh. Smallest direction: Stage2 contract first, then a scoped identity-aware status service; do not quietly add watchers/auto snapshots in this audit.

**F3 — LOW, search is bounded output over a potentially broad scan.** Evidence: FSD/Search/MetadataSearchService.swift:124, `%needle%`/LOWER(extension) predicates, plan by snapshot_id only, no-match16.65–16.80ms at100k vs1.10–1.24ms at10k. Blast radius: future larger or Library workloads; no current measured budget failure. Tests catch escaping/filter/order/caps/offline semantics but not worst-case Library SLO. Direction: define scope/workload/budget before any FTS/index admission; retain working queries now.

**F4 — LOW, result paging work grows with depth.** Evidence: ResultRepository.results:65 count+OFFSET, observed deep100k page45.87–46.95ms versus first3.24–3.90ms, representative plan temporary right-order B-tree. Engine input keysets remain implemented and sound. Tests catch page bounds/outcomes; they do not prove constant deep-page latency. Direction: measure representative intended workspace navigation against a BRAIN-defined budget before any SQL/index change. None authorized here.

**F5 — ADVISORY, catalog/UI bounds and authority drift.** History listSnapshots:149 has no LIMIT and ApplicationModel loads all summaries; tree child loads, selected details, startup recovery and some compare navigation are synchronous at their UI boundary. No unacceptable MainActor pause was measured;100k entry fixture with two snapshots cannot establish large-history scaling. Actual single shared handle differs from architecture's aspirational actor/separate-reader diagram. Missing pre-migration backup and subtree signatures remain documented. UX_UI_SPEC/TEST_PLAN/task035 status sentences lag accepted STATE. Direction: retain technologies; reconcile a future narrowly authorized contract/status update rather than treating prose as source truth.

**Persistent known advisories — PRIOR_ACCEPTED_EVIDENCE, still open:**

- Public v0.1.0 unsigned/not notarized; no default-host Gatekeeper/quarantine acceptance inferred from build host. STATE Task042 and Xcode signing settings.
- Task043 repaired layout is only on later main; no new release. Owner accepted supplied repaired screenshots, not patched-build installation. STATE final BRAIN decision and exact tag-to-main diff.
- Long-path readability remains advisory after the pane fix. Accepted Task043 decision; no new Owner visual/VoiceOver acceptance here.
- Capture/Compare manual E2E remains unverified. Automated synthetic lifecycle/capture/comparison evidence cannot replace it (STATE, TEST_PLAN §8).
- Task041 residual privacy risk is expressly Owner-accepted but containment/external retention/credential liveness or revocation remain UNPROVEN. No credential search, full process-command-line dump, token collection or incident repair was attempted (STATE Task041/043 decision and ledger). No new material exposure was observed in this audit's bounded surfaces; no incident-resolution claim.
- General realistic legacy DOC/XLS/PPT determinism remains UNPROVEN; short-CFB ambiguity guard and accepted realistic bounded PNG/DOCX/XLSX/PPTX evidence are preserved (classifier contract §7/ADR035).

## One proposed bounded next decision

The sole proposal is **OWNER_DECISION**: BRAIN/Owner decide whether to authorize **one native snapshot-outline completeness repair** addressing later sibling pages, explicit load-error presentation and retained-page bounds before expanding Stage1. This is the smallest concrete next action suggested by reproduced F1. Source identity policy, new dependencies, comparison rewrites, Quick Look, cache and automatic snapshots stay separate future decisions. No repair or next task has begun. Accepted PROJECT_STATE remains byte-identical; Task044's ledger classification remains pending BRAIN.

## Execution requirement/evidence accounting and finalizer boundary

The audit execution guard accounts for24 applicable execution requirements below. Future capability gaps, optional unmeasured performance dimensions and prior manual/privacy unknowns are disclosed outcomes of the required audit; they are not concealed missing execution requirements. Publication/transport gates are a distinct finalizer phase and are not falsely claimed executed inside this prepublication immutable record. Fresh gate receipts and the actual publication SHA belong to Desktop transport, which is refreshed after commit/push/fetch. A failed gate requires STOP, preserved evidence and truthful partial-effects return.

|#| Task requirement | Disposition / evidence |
|---:|---|---|
|1| Physical identity/origin/main/expected-head/fetch/clean0/0 | EVIDENCED; fresh Git and initial manifest |
|2| Task043 acceptance/exact Task044 decision | EVIDENCED; accepted STATE/ledger/BRAIN events |
|3| Required authority and execution/review/finalizer skills | EVIDENCED; inspected named files, resolved historical status conflicts |
|4| Public release versus current main | EVIDENCED; tag/API identity/digests, exact scoped diff |
|5| Native platform/build baseline | EVIDENCED; Xcode settings/fresh test-host compilation/environment |
|6| Actual catalog/schema9/migration/transaction architecture | EVIDENCED; source trace/migration tests/schema18/probe integrity |
|7| Read-only scanner/provider capture flow | EVIDENCED; actual source+capture/source-preservation fixtures |
|8| Immutable completion/interruption/recovery | EVIDENCED; lifecycle/eligibility/recovery/source guards |
|9| Offline history/tree/inspector/search inventory | EVIDENCED; source/fresh focused tests/reproduced UI gap |
|10| Compare inputs/keysets/persistence/UI/cancel/disposal | EVIDENCED; source/exact100k semantics/Release lifecycle fixtures |
|11| Optional classification full trace/auto-invocation isolation | EVIDENCED; reader57/isolation8/source/helper identity/prior runtime acceptance |
|12| Local-only/no false content equivalence/source safety | EVIDENCED within bounded audit; source/invariant matrix/synthetic tests; universal external trace explicitly not claimed |
|13| Capability IMPLEMENTED/PARTIAL/ABSENT/UNPROVEN distinctions | EVIDENCED; source-linked inventory |
|14| Meaningful risk invariant/guard/test/gap/severity | EVIDENCED; risk matrix/F1–F5, no theoretical exploit invented |
|15| Inspect test cost/isolation before executing | EVIDENCED; excluded fixed million fixtures/physical mount tests; controlled hosts |
|16| Fresh bounded SQLite insert/query evidence10k/100k | EVIDENCED; optimized scratch production-stack probe |
|17| Tree first pages/search timings/plans/repetitions | EVIDENCED; probe.log and actual existing100k tree test |
|18| Comparison first/deep pages and bounded persistence | EVIDENCED;10k/100k probe + existing100202/side Debug/Release |
|19| Memory/measurement exits/environment/limits truthful | EVIDENCED; self RSS checkpoints, saved exits/summaries and disclosed unretained Debug exit/failed setup attempts; peak/cold left UNPROVEN |
|20| Technology admission8pairs, no replacement without measured need | EVIDENCED; current source and public upstream role references; no install/migration/PoC |
|21| Stage0–6 foundations/gaps/identity/dependencies/GO/complexity | EVIDENCED; matrix with explicit stage boundaries and no auto approval |
|22| Known release/layout/manual/privacy advisories retained | EVIDENCED; accepted-state provenance and findings above |
|23| Source/schema/dependency/accepted-state/prior-history preserved | EVIDENCED; original tracked manifest checked after probes; protected postflight repeated during finalization |
|24| One Reviewer evidence return and one proposed decision | EVIDENCED; reviewed candidate scoped to four reporting paths; pending classification, no auto-next |

Required finalizer gates: non-destructive fresh fetch; exact four-path allowlist and no product/test/schema/docs/accepted-state/prior-handoff diff; one new flat immutable report/full CURRENT parity; one appended worker_return and preserved prior ledger/classification/events; Desktop dated BRAIN-field preservation/exact Operator/full CURRENT; git diff --check; canonical checker; reporting-only normal commit/public main push; fetch clean/synced0/0; release identity preserved. These are required closure actions, never grants of semantic acceptance. Their actual completed receipts appear in the final Desktop packet. The immutable HOT correctly identifies prepublication HEAD, not its future self-containing publication SHA.

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=24
WORKER_REQUIREMENTS_EVIDENCED=24
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO
