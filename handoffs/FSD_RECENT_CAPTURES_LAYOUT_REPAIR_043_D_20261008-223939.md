# Recent Captures nested split repair — Task043

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_RECENT_CAPTURES_LAYOUT_REPAIR_043_D_20261008-223939.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=ab99d0547b6139761c9f28cce149003376cbc3aa
REMOTE_HEAD=ab99d0547b6139761c9f28cce149003376cbc3aa
LAST_VERIFIED_AT=2026-10-08T22:39:39+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|STATE/PROJECT_STATE.md|STATE/TASK_LEDGER.tsv|handoffs/CURRENT_HANDOFF.md|FSD/UI/ComparisonSharedViews.swift|FSD/UI/SnapshotBrowserView.swift|FSD/App/FSDApp.swift|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=V0_1_OWNER_DOWNLOAD_INSTALL_ACCEPTANCE
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_FOR_AUTHORIZED_UI_SCOPE
PROPOSED_NEXT=OWNER_UI_REVIEW
NO_AUTO_NEXT=YES

## Task lock and authority

PROJECT=FSD
TASK_ID=FSD_RECENT_CAPTURES_LAYOUT_REPAIR_043
ROLE=WORKER
MODE=BOUNDED_NATIVE_UI_LAYOUT_REPAIR
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
BASE_HEAD=ab99d0547b6139761c9f28cce149003376cbc3aa
UPSTREAM_HEAD=ab99d0547b6139761c9f28cce149003376cbc3aa
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=RECENT_CAPTURES_NESTED_SPLIT_LAYOUT_ONLY_PLUS_TASK043_RETURN
ALLOWED_PATHS=FSD/UI/ComparisonSharedViews.swift|FSD/UI/SnapshotBrowserView.swift|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|handoffs/CURRENT_HANDOFF.md|handoffs/FSD_RECENT_CAPTURES_LAYOUT_REPAIR_043_D_20261008-223939.md
FORBIDDEN_PATHS=FSD/App/FSDApp.swift|FSD/Catalog/**|FSD/Scanner/**|FSD/Browser/**|FSD/Comparison/**|DATABASE_AND_SCHEMA|SEARCH_SEMANTICS|CLASSIFIER|COMPARISON_ENGINE|SOURCE_ACCESS|EXPORT_DATA|FSDTests/**|PRODUCT_VERSION|PUBLIC_RELEASE_ARTIFACTS|STATE/PROJECT_STATE.md|STATE/RULE_PROMOTION_LEDGER.tsv|OLD_HANDOFFS|CHECKER_REPAIR
SUCCESS_CRITERIA=REPRODUCE_OLD_HISTORY_CLIP;READABLE_METADATA_AT_1120_1330_1440;SEARCH_TREE_INSPECTOR_NAVIGATION_RESIZE_PRESERVED;DEBUG_RELEASE_ARM64;FOCUSED_XCTEST;NO_OWNER_CATALOG_OR_SOURCE_MUTATION;SCOPE_CHECKER_HANDOFF_PUBLICATION
VALIDATIONS=FRESH_GIT_REANCHOR;ACTUAL_MACOS_GUI_BEFORE_AFTER;AX_PANE_BOUNDS;SEARCH_AND_CLEAR;TREE_EXPANSION_AND_HORIZONTAL_SCROLL;RESIZE_SELECTION_RETENTION;DEBUG_RELEASE_CLEAN_BUILDS;FOCUSED_XCTEST;GIT_DIFF_SCOPE;DIFF_CHECK;CANONICAL_CHECKER;DESKTOP_PARITY
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY

OWNER_REPORT: Public v0.1.0 was installed and launched on the Owner's Mac. Library Overview, All Drives and Comparisons appeared usable in supplied screenshots. Recent Captures clipped snapshot browser header and metadata after selection. Capture and end-to-end comparison are not fully accepted.

BRAIN_AUTHORIZATION: Treat this as launch/navigation success with one unresolved Recent Captures defect. Repair only the authorized native UI layout. Keep capture and comparison acceptance pending. The accepted STATE file remains unchanged; this Worker return is pending BRAIN adjudication.

## Fresh re-anchor — FACT

- Physical repository: /Users/cenvu/DEV/FSD; origin https://github.com/cenvu/FSD.git; branch main.
- Before task mutation, HEAD, origin/main and FETCH_HEAD were ab99d0547b6139761c9f28cce149003376cbc3aa; ahead 0, behind 0; tracked worktree clean.
- The final non-destructive fetch at 2026-10-08T22:39:39+07:00 returned main at the same SHA. No remote movement was observed.
- STATE/PROJECT_STATE.md remains byte-identical to the base, SHA-256 e94e32324253c92b84a9b9999d8b9e0d9c31ae6e525d45c3d47c36732fc3396b. Its accepted Task042 provenance and Owner download/install gate are preserved.

## Old-layout reproduction and cause — FACT

The pre-repair Debug app was built from the clean base and launched with -FSDCatalogPath /Users/cenvu/DEV/FSD/.ai-scratch/task043/catalog. The selected source was the controlled synthetic folder .ai-scratch/task043/source. The actual macOS window was captured by window ID only; no desktop or other app contents appear in these screenshots.

At AX/AppKit window width 1120, the old history split allocated a 599-point browser pane. SnapshotBrowserView's inner HSplitView imposed minimum widths of 380 points for the outline and 260 points for the inspector, before its surrounding 20-point padding and divider. AX reported the tree group beginning at x=804 while the browser pane began at x=825, and the inspector ending at x=1445 while the window ended at x=1424. The tree/browser header, snapshot metadata and Search label therefore painted underneath the History selection pane; the inspector also extended past the window's right edge.

FSDCaptureHistoryView's outer split still had room at the 1120-point minimum window. The nested browser minima were larger than the browser pane assigned by the outer split. This mismatch, rather than catalog data or navigation, caused the clipping.

The AppKit outline integration was inspected before editing. Its NSScrollView enables vertical and horizontal scrollers; the outline has Name/Kind/Logical size columns sized 320/90/110 points, and the Name cell truncates in the middle. The fixed SwiftUI pane minima caused the observed overdraw. No AppKit data source, row behavior or table column was changed.

Before screenshots, same selected synthetic snapshot with expanded tree and selected long-path entry:

| AX window width | Screenshot | Pixel dimensions | SHA-256 |
|---:|---|---:|---|
| 1120 | .ai-scratch/task043/repro-before-1120.png | 2464 x 2024 | 7aa23990b169215c7efbb7542ae088d333d66175d9c1d41d1d4f1e5c0e92edf5 |
| 1330 | .ai-scratch/task043/repro-before-1330.png | 2884 x 2024 | bc970e0019cff8e2fba4b324d67441d4522bf6b0b8042d4fa036c7000ee7c5aa |
| 1440 | .ai-scratch/task043/repro-before-1440.png | 3104 x 2024 | 7278b1a290e3f8e2de6d292cf85d751d13b302ced1971682da22b26a648abf24 |

The bitmap dimensions include the captured window shadow. AppKit window widths above are the observed logical widths.

## Bounded UI delta — FACT

Only FSD/UI/SnapshotBrowserView.swift changed:

- The outline minimum changed from 380 to 320 points.
- The inspector minimum changed from 260 to 220 points.

At the minimum window width, measured browser bounds remain x=825..1424; the tree is x=845 with width 330 and the inspector x=1176 with width 227. Both panes now stay inside the browser/window bounds with the existing padding.

At width 1330, the tree was x=830/401 points and the inspector x=1232/276. At width 1440, the tree was x=813/444 and the inspector x=1258/305. The History list, tree and inspector were all within the window; no pane painted across another. The existing app minimum width in FSD/App/FSDApp.swift was read as reference only and was not changed. ComparisonSharedViews.swift and FSDApp.swift remain unchanged.

After screenshots, same snapshot and selected expanded entry:

| AX window width | Screenshot | Pixel dimensions | SHA-256 |
|---:|---|---:|---|
| 1120 | .ai-scratch/task043/after-1120.png | 2464 x 2024 | 0be6c92db13e52376e5dfb0874fa2b4e26165b6c8d714bbb93e2c3ffcda607b6 |
| 1330 | .ai-scratch/task043/after-1330.png | 2884 x 2024 | 0ce15010a782862020fd146a8dd3e00c537955b7eba9a1b5b5b692f065635721 |
| 1440 | .ai-scratch/task043/after-1440.png | 3104 x 2024 | 619c7ad19ed463c750d036599c461db968005b226134c87750e66e091e4c061 |

## Actual GUI verification — EVIDENCED

- The 1120-point window showed the selected snapshot name, Complete status, capture-time source metadata, file/folder totals, Search picker/text/button, expanded tree and selected-entry inspector without left-edge clipping.
- The fixture selected entry was clip_0003_editor_review_proxy_long_name_for_layout_regression.mov at LongProductionDay_20261008_Camera_A001/DeliverySet_06_ProRes4444XQ_UHD_Files/ReviewExports/.... Its long Name and Path wrapped within the inspector.
- Search input was filled with zzzz through the focused field, Search was enabled and clicked, and the browser reported 0 match(es) in snapshot 2. Clear was then clicked and the field/results returned to the empty state. Search controls remained visible at 1120, 1330 and 1440.
- The root and nested LongProductionDay/DeliverySet/ReviewExports branches remained expanded. The selected file's inspector remained populated. Setting the outline's horizontal scroll value to 0.8 visibly exposed the Kind and Logical size columns; it was restored to 0.0.
- During 1120 -> 1330 -> 1440 -> 1120 window resizing, AX continued to report the selected History row and selected tree row. The History breadcrumb remained visible.

## Build and XCTest evidence — EVIDENCED

- Debug clean arm64 build: xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath .ai-scratch/task043/debug-derived clean build. Exit 0; BUILD SUCCEEDED. Log: .ai-scratch/task043/debug-build.log.
- Release clean arm64 build: xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Release -destination 'platform=macOS,arch=arm64' -derivedDataPath .ai-scratch/task043/release-derived clean build. Exit 0; BUILD SUCCEEDED. Log: .ai-scratch/task043/release-build.log.
- Focused Debug XCTest selected SnapshotHistoryTests, LazyTreeBrowsingTests, MetadataSearchTests, SnapshotBrowserClassificationTests and ManualSessionASubstituteTests. xcodebuild exited 0; xcresult summary is Passed: 80 total, 80 passed, 0 failed, 0 skipped. Evidence: .ai-scratch/task043/focused-test.log and .ai-scratch/task043/focused.xcresult.

## Source/catalog isolation and release boundary — FACT

- The GUI process command line named the isolated catalog under .ai-scratch/task043/catalog. The folder picker named the synthetic source under .ai-scratch/task043/source. The owner catalog path was not supplied to the app; the six synthetic fixture files are separate from the catalog. No classification action was invoked and no source writes were observed.
- XCTest's host isolation path was reviewed in CatalogLocationResolver: XCTest host resolves to its own temporary FSD-TestHost catalog.
- Public v0.1.0 tag, Release, ZIP and checksum were not changed. No version change, package/release operation, scanner/database/search/classifier/comparison/source-access/export-data change, or test-file change was made.

## Requirement/evidence map

| # | Requirement | Disposition | Evidence |
|---:|---|---|---|
| 1 | Fresh clean/synced re-anchor at expected base | EVIDENCED | Git HEAD/origin/FETCH_HEAD and initial status |
| 2 | Reproduce old clipping in isolated fixture | EVIDENCED | Actual pre-repair Debug app; repro-before screenshots |
| 3 | Inspect nested sizing, padding and outline integration | EVIDENCED | Source review plus measured AX bounds |
| 4 | Before/after screenshots at 1120, 1330 and 1440 | EVIDENCED | Six window-only screenshot files and hashes |
| 5 | Identity/status/source metadata readable across widths | EVIDENCED | After screenshots and AX contents |
| 6 | Search controls usable | EVIDENCED | Search action returned 0 matches; Clear restored field |
| 7 | Tree scrolling and expansion preserved | EVIDENCED | Expanded nested path; horizontal scroll exposed other columns |
| 8 | Selected-entry inspector accessible; long path bounded | EVIDENCED | Selected fixture entry and wrapped inspector text |
| 9 | No cross-pane painting or hidden required controls | EVIDENCED | Screenshots and pane bounds at all three widths |
| 10 | Resize preserves selected snapshot and entry | EVIDENCED | AX selected states across 1120/1330/1440/1120 |
| 11 | Debug arm64 clean build | EVIDENCED | Debug build log |
| 12 | Release arm64 clean build | EVIDENCED | Release build log |
| 13 | Focused relevant XCTest | EVIDENCED | 80 passed, 0 failed, 0 skipped |
| 14 | No Owner source/catalog mutation | EVIDENCED | Isolated process arguments, scratch fixture, no classifier action |
| 15 | Exact UI/reporting scope; accepted STATE preserved | EVIDENCED | One-file product diff; PROJECT_STATE hash unchanged |
| 16 | Diff check, canonical checker and Git publication | EVIDENCED | Finalizer pre/post checks and publication receipt in Desktop packet |
| 17 | One handoff, CURRENT/ledger/event and exact Desktop recovery | EVIDENCED | Finalizer byte-parity and Git receipts in Desktop packet |

Worker-local outcome is PASS; BRAIN classification remains pending. The public release is unchanged. The proposed next decision is Owner UI review; no Capture or comparison acceptance is inferred.

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=17
WORKER_REQUIREMENTS_EVIDENCED=17
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO
