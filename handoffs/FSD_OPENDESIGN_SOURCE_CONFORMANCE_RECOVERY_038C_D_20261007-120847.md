# OpenDesign source-conformance recovery — task038C

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_OPENDESIGN_SOURCE_CONFORMANCE_RECOVERY_038C_D_20261007-120847.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=96d45c40b232efd1c77a7d7c94d23ee36494a75f
REMOTE_HEAD=96d45c40b232efd1c77a7d7c94d23ee36494a75f
LAST_VERIFIED_AT=2026-10-07T12:08:47+0700
AUTHORITY_PTRS=AGENTS.md|STATE/PROJECT_STATE.md|handoffs/CURRENT_HANDOFF.md|docs/BRAIN_OPERATOR.md|docs/UX_UI_SPEC.md|scripts/check_control_plane.py|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_OPENDESIGN_SOURCE_CONFORMANCE_RECOVERY_038C
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_FOR_WORKER_SCOPE;NATIVE_SYSTEM_GRAY_TITLEBAR_ADVISORY
PROPOSED_NEXT=OWNER_VISUAL_REVIEW
NO_AUTO_NEXT=YES

## Task lock and result

PROJECT=FSD
TASK_ID=FSD_OPENDESIGN_SOURCE_CONFORMANCE_RECOVERY_038C
ROLE=WORKER
MODE=FAILED_CLOSURE_RECOVERY_AND_EXISTING_PRODUCT_CANDIDATE_PUBLICATION
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
BASE_HEAD=96d45c40b232efd1c77a7d7c94d23ee36494a75f
UPSTREAM_HEAD=96d45c40b232efd1c77a7d7c94d23ee36494a75f
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=RECOVER_FAILED_038B_CLOSURE_AND_PUBLISH_BYTE_IDENTICAL_UI_CANDIDATE
ALLOWED_PATHS=FSD/App/FSDApp.swift|FSD/UI/ComparisonSharedViews.swift|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|handoffs/CURRENT_HANDOFF.md|handoffs/FSD_OPENDESIGN_SOURCE_CONFORMANCE_RECOVERY_038C_D_20261007-120847.md
FORBIDDEN_PATHS=FSD/Catalog/**|FSD/Scanner/**|FSD/Diff/**|FSD/Classification/**|FSD/Provider/**|DATABASE_SCHEMA_MIGRATIONS|HELPER|GO_FILES_DEPENDENCIES|FSD.xcodeproj/**|FSDTests/**|CANONICAL_PRODUCT_DOCS|STATE/PROJECT_STATE.md|STATE/RULE_PROMOTION_LEDGER.tsv|PRIOR_PUBLISHED_HANDOFFS|OWNER_IGNORED_UNRELATED_FILES
SUCCESS_CRITERIA=FAILED_CLOSURE_BYTE_PRESERVATION;EXACT_UI_CANDIDATE_IDENTITY;NO_PRODUCT_MUTATION;VALID_038C_RETURN;CHECKER_AND_DIFF_CHECK;PUBLICATION_AND_POSTPUBLICATION_PARITY
VALIDATIONS=SOURCE_AND_CONTROL_AUTHORITY;TASK038B_RECEIPT_REUSE;BYTE_HASHES;DIFF_CHECK;CONTROL_PLANE_CHECKER;PUSH_FETCH_CLEAN_SYNCED;POSTPUBLICATION_CHECKER
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
RESULT=PASS_WITH_ADVISORY
WORKER_RESULT=PASS_WITH_ADVISORY
BACKEND_MUTATION=NO
VISUAL_AUTHORITY=OWNER_SUPPLIED_SOURCE_VALUES_PLUS_UX_UI_SPEC_AND_EXISTING_PRODUCTION_BEHAVIOR
OWNER_VISUAL_ACCEPTANCE=NOT_CLAIMED;PENDING_OWNER_REVIEW

## Re-anchor and authority — FACT

- Physical canonical root is `/Users/cenvu/DEV/FSD`; branch `main`; origin `https://github.com/cenvu/FSD.git`. Non-destructive fetch found local/upstream `96d45c40b232efd1c77a7d7c94d23ee36494a75f`, 0 ahead / 0 behind. The only pre-recovery non-ignored changes were the two authorized UI candidate files, the three task038B reporting surfaces, and its one unpublished historical candidate. The ignored task038B scratch contained build/test derived data, build logs, focused test logs/result bundles, route screenshots and the production Overview screenshot. The task038B Desktop recovery packet was also present.
- Read `AGENTS.md`, `STATE/PROJECT_STATE.md`, `docs/BRAIN_OPERATOR.md`, `scripts/check_control_plane.py`, the task-execution skill and the handoff-finalizer skill. The checker rejects historical Worker handoffs containing any of four BRAIN-owned assignment prefixes. The finalizer says a validation failure after immutable handoff creation is a blocker returned to BRAIN, not permission to rewrite that file. This explains the prior task038B STOP.
- Current accepted state and all previously published historical handoffs remain untouched. Task038B's invalid unpublished history was quarantined only under the explicit task038C authorization, which permits exact-byte preservation followed by removal of the failed unpublished closure candidate.

## Failed task038B closure preservation — FACT

Before quarantine, byte-for-byte copies were placed under `.ai-scratch/task038b/failed-closure/`; each copy compared equal to its then-canonical source. SHA-256:

| Preserved artifact | SHA-256 |
|---|---|
| `handoffs/FSD_OPENDESIGN_SOURCE_CONFORMANCE_REPAIR_038B_D_20261007-114605.md` → `.ai-scratch/task038b/failed-closure/handoffs/FSD_OPENDESIGN_SOURCE_CONFORMANCE_REPAIR_038B_D_20261007-114605.md` | `dcd97b2a1896c530003dbca036c4f1e2a93914df9af98872ba071a5ddc12641d` |
| `handoffs/CURRENT_HANDOFF.md` → `.ai-scratch/task038b/failed-closure/handoffs/CURRENT_HANDOFF.md` | `2b482340f13abfcb70106fec2015570ce4ae08038eb721576c09bdcc3359a711` |
| `STATE/TASK_LEDGER.tsv` → `.ai-scratch/task038b/failed-closure/STATE/TASK_LEDGER.tsv` | `5ad714260f272490e6d663616511ea2aa040c8961a342681089c6cac10827f75` |
| `STATE/EVENTS.jsonl` → `.ai-scratch/task038b/failed-closure/STATE/EVENTS.jsonl` | `85e3610aee18924b732628a5f711001a857ed0b71185e92e8a6a3d2fb2babe0c` |
| `/Users/cenvu/Desktop/04_FSD_BRAIN.md` → `.ai-scratch/task038b/failed-closure/Desktop/04_FSD_BRAIN.md` | `44733cfe77efb8c01f0f68a7c9a8cfeb439a405c103de931150c853dcafcb6c3` |

Only `STATE/TASK_LEDGER.tsv`, `STATE/EVENTS.jsonl`, and `handoffs/CURRENT_HANDOFF.md` were restored to exact base `96d45c4` bytes. The sole unpublished 038B historical path was removed after its preserved copy was hash-verified. No published history or Owner file was touched. The three reporting files now have no diff from base.

## Exact product-candidate identity — FACT

Recovery made no changes to either product file. Their SHA-256 before and after quarantine is identical:

- `FSD/App/FSDApp.swift`: `d601fc78d392fd8ee767d316b18050c855c97813ec0955a50f63356477aac2d0`
- `FSD/UI/ComparisonSharedViews.swift`: `bb34a9ed7d068ff6fabd6ab6082f7fd29e572d5441d924af1a0e13c6e6dde270`

`PRODUCT_CANDIDATE_DIFF_SHA256=23bc3ee565f20b3da2c1ca305675a9705edcc9f75ebe0cf39366f531ba60e86c` for `git diff --binary 96d45c40b232efd1c77a7d7c94d23ee36494a75f -- FSD/App/FSDApp.swift FSD/UI/ComparisonSharedViews.swift`. The same digest was measured before and immediately after quarantine. Current non-ignored product delta is exactly those two paths. No product or backend mutation occurred in task038C.

## Reused task038B technical evidence — FACT

The preserved 038B source-conformance handoff records the candidate and its tested scope. The current exact UI bytes match the candidate used for those receipts: the final app-file modification time was 11:37:58+0700, before the Debug log closed at 11:38:10+0700 and Release log at 11:38:27+0700; both clean-build logs show arm64 compile entries for both changed product files and end in `BUILD SUCCEEDED`. The source files were not changed during or after those runs. Receipt hashes: Debug log `819fe0c68a1a2266c94e8d354f8da68b03702caa249a7959e88d7b14dcbc6330`; Release log `66382d351f7f28ab6b436df247ba27402c928afdc882ad0e506835b3e5f453a3`.

Commands recorded in those logs:

- `xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug -destination platform=macOS,arch=arm64 -derivedDataPath .ai-scratch/task038b/debug-derived clean build` — clean and build succeeded.
- `xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Release -destination platform=macOS,arch=arm64 -derivedDataPath .ai-scratch/task038b/release-derived clean build` — clean and build succeeded.

The final focused Debug run selected the same 14 regression suites: `SnapshotHistoryTests`, `LazyTreeBrowsingTests`, `MetadataSearchTests`, `SnapshotBrowserClassificationTests`, `ComparisonWorkspaceModelTests`, `ComparisonBrowserModelTests`, `ComparisonGUIValidationTests`, `ComparisonGUISourceBoundaryTests`, `ComparisonPersistenceTests`, `ComparisonSemanticsTests`, `ClassificationInvocationIsolationTests`, `Milestone2CaptureTests`, `CaptureErrorBoundaryTests`, and `FSDProbeSeedTests`. `xcresulttool` reports Passed, 179 total / 178 passed / 0 failed / 1 skipped. The sole skip is `FSDProbeSeedTests/testSeedIsolatedProbeCatalog`; its log records the ordinary guard (environment variable unset and marker file absent), physically reproduced at recovery. Result-bundle plist and SQLite integrity checks passed. Test log SHA-256 is `69291efdfd2e4c12555e64b4333ee99a66c90c35ff3d3afef87380d27fc38a61`.

The preserved static conformance receipt and a fresh read-only assertion on the byte-identical current source pass. Exact source values: sidebar 198pt below 1280pt / 224pt otherwise; toolbar 50pt; ordinary radius 4pt; insets 24/28/32pt; title 22pt; home grid 1.13:0.87, 28pt gap, 330pt right minimum. Palette: `#161A1F #20252C #11161C #2A3038 #343C47 #EDF1F6 #A7B1BD #7AB6FF #2463AA #70D8A0 #FFD080 #FF9094 #C7B8DE`.

Existing actual Debug screenshots remain under ignored scratch. The Library Overview screenshot is `.ai-scratch/task038b/library-overview-production.png`, 2464×1720 PNG, SHA-256 `eb450bc3c2eb9195cfa5f8c65683517737a9b4a675b08c20eacc91b581018a6a`. It is reused because product file hashes and candidate diff hash are unchanged; no new screenshot was made.

The truthful titlebar advisory remains: native window configuration uses the intended `#191E24` family, while macOS still renders gray titlebar chrome. Owner visual acceptance remains pending. Existing live observations from the exact candidate show Overview initially, manual Capture, History and Compare routes reachable, unavailable states truthful, and no automatic capture/classification or mount detection. The candidate did not add Connected Now, Drive Sets, Auto Capture or global Search backends, and contains no prototype fixture values.

## Proposed Worker state delta — FACT

The finalizer adds exactly one new row for task038C: status `WORKER_COMPLETE_PENDING_BRAIN`, scope `RECOVER_FAILED_038B_CLOSURE_AND_PUBLISH_BYTE_IDENTICAL_UI_CANDIDATE`, executor `WORKER`, technical basis `96d45c40b232efd1c77a7d7c94d23ee36494a75f`, result `PASS_WITH_ADVISORY`, handoff this file. Its note says the source-conformant UI delta is in the 038C publication, the basis is prepublication, and the product candidate diff was preserved and verified byte-identically from failed unpublished 038B. The BRAIN-owned classification cell remains pending. No 038B row is created.

The finalizer appends exactly one Worker `worker_return` event for task038C with `commit=null`, this handoff ref and the same result. It leaves `STATE/PROJECT_STATE.md`, `STATE/RULE_PROMOTION_LEDGER.tsv`, prior ledger rows, prior events and accepted classifications unchanged. CURRENT is generated as the exact historical bytes after one timestamp line and one blank line.

## Prepublication execution accounting — EVIDENCED

| # | Requirement | Evidence |
|---:|---|---|
| 1 | Physical root, base and upstream identified | `main`, base/upstream `96d45c4…`, 0/0 after fetch |
| 2 | Dirty scope inventoried | Only the task038B candidate/reporting files plus ignored task038B scratch and its Desktop packet |
| 3 | Required authority and failure policy read | Files and both skills listed above; checker/finalizer behaviors confirmed |
| 4 | Failed closure packet preserved | Five byte comparisons and SHA-256 values above |
| 5 | Explicit quarantine stayed within authorized paths | Three reporting surfaces restored; only invalid unpublished 038B history removed |
| 6 | Product candidate preserved exactly | Both file hashes and binary diff digest match before/after |
| 7 | No product/backend mutation in 038C | Current source diff remains exactly two allowed UI files |
| 8 | Debug arm64 clean build receipt passes | Complete log, both changed files compiled, success marker, intact receipt |
| 9 | Release arm64 clean build receipt passes | Complete log, both changed files compiled, success marker, intact receipt |
| 10 | Focused suites pass | Same 14 suites; 179/178/0/1; result bundle Passed |
| 11 | Sole test skip is the ordinary probe guard | Exact test identity and guard reason in log; env unset/marker absent |
| 12 | Static source conformance is valid | Preserved receipt and fresh assertions on exact current source pass |
| 13 | Actual production screenshot is available | Existing ignored screenshot path, dimensions, format and digest above |
| 14 | Stop at Owner review boundary | Native titlebar advisory retained; Owner visual review proposed, not claimed |

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=14
WORKER_REQUIREMENTS_EVIDENCED=14
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

## Publication boundary — PREPUBLICATION FACT

This immutable record is the source for the 038C ledger/event/CURRENT projection. At its creation, publication SHA is not yet known and cannot be self-recorded. After projection, `git diff --check`, the canonical prepublication checker, exact six-path commit, explicit push, fresh fetch, 0/0 clean synchronization, Desktop refresh and the postpublication checker remain finalizer actions to be physically observed before the Worker return claims closure. This handoff is not Owner/BRAIN visual acceptance.

RAW_REFS=.ai-scratch/task038b/failed-closure/handoffs/FSD_OPENDESIGN_SOURCE_CONFORMANCE_REPAIR_038B_D_20261007-114605.md|.ai-scratch/task038b/failed-closure/handoffs/CURRENT_HANDOFF.md|.ai-scratch/task038b/failed-closure/STATE/TASK_LEDGER.tsv|.ai-scratch/task038b/failed-closure/STATE/EVENTS.jsonl|.ai-scratch/task038b/failed-closure/Desktop/04_FSD_BRAIN.md|.ai-scratch/task038b/debug-build.log|.ai-scratch/task038b/release-build.log|.ai-scratch/task038b/focused-regressions-final.xcresult|.ai-scratch/task038b/library-overview-production.png
