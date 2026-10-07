# OpenDesign core-route visual conformance — task039

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_OPENDESIGN_CORE_ROUTE_VISUAL_CONFORMANCE_039_D_20261007-152250.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=add08dfe2e706dfca6620725afb3199f8b8e8bb5
REMOTE_HEAD=add08dfe2e706dfca6620725afb3199f8b8e8bb5
LAST_VERIFIED_AT=2026-10-07T15:22:50+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|STATE/PROJECT_STATE.md|handoffs/CURRENT_HANDOFF.md|docs/UX_UI_SPEC.md|FSD/UI/ComparisonSharedViews.swift|FSD/UI/ComparisonCreationView.swift|scripts/check_control_plane.py|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=OPENDESIGN_OWNER_VISUAL_REVIEW
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_FOR_WORKER_SCOPE;NATIVE_SYSTEM_GRAY_TITLEBAR_ADVISORY
PROPOSED_NEXT=OWNER_VISUAL_REVIEW
NO_AUTO_NEXT=YES

## Task lock and result

PROJECT=FSD
TASK_ID=FSD_OPENDESIGN_CORE_ROUTE_VISUAL_CONFORMANCE_039
ROLE=WORKER
MODE=UI_ONLY_CORE_ROUTE_VISUAL_CONFORMANCE
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
BASE_HEAD=add08dfe2e706dfca6620725afb3199f8b8e8bb5
UPSTREAM_HEAD=add08dfe2e706dfca6620725afb3199f8b8e8bb5
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=UI_ONLY_NATIVE_VISUAL_CONFORMANCE_FOR_CAPTURE_COMPARE_RECENT_CAPTURES
ALLOWED_PATHS=FSD/UI/ComparisonSharedViews.swift|FSD/UI/ComparisonCreationView.swift|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|handoffs/CURRENT_HANDOFF.md|handoffs/FSD_OPENDESIGN_CORE_ROUTE_VISUAL_CONFORMANCE_039_D_20261007-152250.md
FORBIDDEN_PATHS=FSD/Catalog/**|FSD/Scanner/**|FSD/Diff/**|FSD/Classification/**|FSD/Provider/**|SCHEMA_AND_MIGRATIONS|HELPER_AND_GO|DEPENDENCIES|FSD.xcodeproj/**|FSDTests/**|PRODUCT_DOCS|STATE/PROJECT_STATE.md|STATE/RULE_PROMOTION_LEDGER.tsv|FSD/App/FSDApp.swift
SUCCESS_CRITERIA=CAPTURE_COMPARE_HISTORY_USE_ACCEPTED_OPENDESIGN_TOKENS;EXISTING_WORKFLOWS_UNCHANGED;TRUTHFUL_DATA;DEBUG_RELEASE_PASS;FOCUSED_TESTS_ZERO_FAILURES;FOUR_DISTINCT_DEBUG_SCREENSHOTS
VALIDATIONS=SOURCE_DIFF_REVIEW;DEBUG_RELEASE_CLEAN_ARM64_BUILDS;FOCUSED_14_SUITE_REGRESSIONS;LIVE_DEBUG_ROUTE_OBSERVATION;SCREENSHOT_IDENTITY;GIT_SCOPE;CHECKER_AND_DIFF_CHECK
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
RESULT=PASS_WITH_ADVISORY
WORKER_RESULT=PASS_WITH_ADVISORY
BACKEND_MUTATION=NO
VISUAL_AUTHORITY=OWNER_ROUTE_DIRECTION_PLUS_ACCEPTED_038C_FSD_DESIGN_TOKENS_AND_EXISTING_PRODUCTION_BEHAVIOR
OWNER_VISUAL_ACCEPTANCE=NOT_CLAIMED;OWNER_REVIEW_PROPOSED
PRODUCT_DIFF_SHA256=7f2ed8a526edd6af934077a57d7d85814667b7be278a0078f22917f3bc654998

## Re-anchor and source authority — FACT

- Fresh non-destructive fetch identified the physical canonical repository `/Users/cenvu/DEV/FSD`, `main`, origin `https://github.com/cenvu/FSD.git`, base/upstream `add08dfe2e706dfca6620725afb3199f8b8e8bb5`, 0 ahead / 0 behind, and a clean initial worktree.
- The current BRAIN-accepted state is preserved: task038C remains the latest accepted product publication; the Owner visual review gate and `OWNER_DECISION` remain unchanged. Task039 is a Worker return only.
- Local search under the canonical repository and Desktop found no copies named `index.html` or `design-system.html`. This task used the route-specific Owner direction, the accepted 038C shell, and the exact existing `FSDDesignTokens` palette/layout values. The supplied screenshots are for Owner visual adjudication; no pixel-perfect acceptance is claimed.
- Before finalizer projection the only non-ignored product changes were `FSD/UI/ComparisonSharedViews.swift` and `FSD/UI/ComparisonCreationView.swift`. `FSD/App/FSDApp.swift`, Catalog, Scanner, Diff, Classification, Provider, schema, helper, Go, dependencies, Xcode project and tests were untouched. The existing CURRENT byte SHA-256 before finalization was `96357ec5a679a8c8ac46c1d0ce2edc6fe0252a12cbaf00890871fce4d71a8a76`.

## UI delta — FACT

- `FSD/UI/ComparisonSharedViews.swift` reuses the accepted `FSDDesignTokens` only. Capture now uses a compact dark OpenDesign surface, shared button styles, selected-source display, explicit Choose Source / Start Metadata Capture controls, status/progress/cancel presentation, and the metadata-only / Content Not Verified disclosure. The ordinary UI no longer displays `catalogDiagnostics` or the internal catalog path. Selected source and progress display only their final path component.
- `FSD/UI/ComparisonSharedViews.swift` presents real `model.history` entries in a compact Recent Captures list using already-loaded start time, status, file/folder/logical-size counts and capture-time source label. The existing List selection binding still calls `model.openSnapshot(summary)`; selecting the saved snapshot opened the existing offline browser. No aggregate query was added.
- `FSD/UI/ComparisonCreationView.swift` now uses accepted dark surfaces, hairline separators, compact type and 4pt radii. Native segmented/popup controls were replaced by token-styled mode buttons and snapshot/profile menus bound to the same existing model properties. The same `ComparisonMode.allCases`, complete snapshot list, profile list, validation, `model.start`, cancellation and Recent Comparisons history remain in use. The UI retains Left/Before/Reference and Right/After/Changed wording.
- Source-only scope check: the new capture screen invokes `chooseSource`, `startCapture` and `cancelCapture` only from explicit buttons. No auto-select, auto-capture, classifier call, mount query/service, catalog query or new domain model was introduced.

## Build and regression evidence — EVIDENCED

- Debug clean arm64 build PASS: `xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug -destination platform=macOS,arch=arm64 -derivedDataPath .ai-scratch/task039/debug-derived clean build`. Log: `.ai-scratch/task039/debug-build.log` (SHA-256 `88f067afaadabff61707a47b9579f8e94aa617c56196d916f9ae6cf08d8eb990`).
- Release clean arm64 build PASS: `xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Release -destination platform=macOS,arch=arm64 -derivedDataPath .ai-scratch/task039/release-derived clean build`. Log: `.ai-scratch/task039/release-build.log` (SHA-256 `19f5eec7f964c30bd1fe2f12ada827e0767e56491a4e176210cf763f2ffdabfd`).
- Focused Debug regression boundary: 14 suites, 179 tests total, 178 passed, 0 failed, 1 skipped. The `xcresult` summary reports `Passed`; log `.ai-scratch/task039/focused-regressions-final.log` (SHA-256 `e5a2823009f5f8c0150868c209e3f39ba8629165a0e875fb87dc5abedf57e488`), bundle `.ai-scratch/task039/focused-regressions-final.xcresult`.
- The sole skip is `FSDProbeSeedTests/testSeedIsolatedProbeCatalog`: ordinary guard reproduced with `FSD_PROBE_CATALOG` unset and `/tmp/fsd-probe-catalog-path.txt` absent. No marker or fixture catalog was created.
- Suites: `SnapshotHistoryTests`, `LazyTreeBrowsingTests`, `MetadataSearchTests`, `SnapshotBrowserClassificationTests`, `ComparisonWorkspaceModelTests`, `ComparisonBrowserModelTests`, `ComparisonGUIValidationTests`, `ComparisonGUISourceBoundaryTests`, `ComparisonPersistenceTests`, `ComparisonSemanticsTests`, `ClassificationInvocationIsolationTests`, `Milestone2CaptureTests`, `CaptureErrorBoundaryTests`, `FSDProbeSeedTests`.

## Production Debug observation and screenshots — FACT

- Launched the actual task039 Debug app. Library Overview appeared initially. Capture, Compare and History toolbar actions routed to their matching interiors; no immediate crash. Capture remained Ready with no source selected and no capture started. Compare showed no comparisons, real profile/snapshot options, and a disabled Start action until valid selections. History showed Recent Captures, the actual saved row, and opening that row loaded the existing snapshot browser in its stored offline state. No classification was invoked.
- Four window-only screenshots were captured from that Debug process at 3336×2136 PNG. Each is a distinct image and remains ignored under `.ai-scratch/task039/`:
  - `.ai-scratch/task039/library-overview.png` — SHA-256 `25cbc92662237d71d809ab6907e1d815a8f7751374aa4888e8bbddb95489ab8d`
  - `.ai-scratch/task039/capture.png` — SHA-256 `ac88c523ab900512d4198b1ddb5a96a6b86b785d9498e740ad65e165630dde42`
  - `.ai-scratch/task039/compare.png` — SHA-256 `e1c3409b65c381edc4b01fd21e57fa6b8d94b50eb84d6ebe2ce1baace31810f4`
  - `.ai-scratch/task039/history.png` — SHA-256 `3f7ac727b0e79c9afc8336445bf8bf9e4422900f8377b8c82295a4c7494acfa7`
- The History screenshot visibly shows `Recent Captures` and saved capture rows; it is not a Capture view. The route screenshot shows real production catalog content only. No OpenDesign fixture data was added to runtime.

## Requirement/evidence map — EVIDENCED

| # | Requirement | Evidence |
|---:|---|---|
| 1 | Reuse the accepted visual tokens | Source review: both views use `FSDDesignTokens`; no second palette. |
| 2 | Capture route uses the dark operational visual system | Production `capture.png`; compact source row, separators, controls and density. |
| 3 | Preserve manual source selection and selected-source state | Explicit `chooseSource` button; Ready/no-selection screenshot; model unchanged. |
| 4 | Preserve explicit capture, progress, status, cancel and metadata disclosure | Explicit `startCapture`/`cancelCapture` actions and status/progress presentation; no automatic invocation. |
| 5 | Keep internal catalog filesystem path out of ordinary UI | `catalogDiagnostics` has no use in the new screen; displayed source/progress names are leaf components. |
| 6 | Restyle real comparison modes and selectors | Production `compare.png`; custom controls bind the existing mode, snapshot and profile model fields. |
| 7 | Preserve comparison mode/side/start semantics and empty history | Existing model and validation tests pass; UI retains Reference Left / Changed Right labels; empty state reads No comparisons yet. |
| 8 | Preserve real comparison history data | `ComparisonDestinationView` refresh and existing history model are unchanged; the list uses `model.history`. |
| 9 | Present real saved capture history densely | Production `history.png`; live catalog snapshot row includes actual date, status, counts and capture-time source information. |
| 10 | Preserve snapshot open/browser behavior | Selected the actual history row in the live app; existing offline browser loaded; existing selection binding remains. |
| 11 | Keep truthfulness and avoid new backend services | Only two UI source paths differ; no fixture values, aggregate query, mount service, provider, catalog or classifier change. |
| 12 | No automatic capture or classification | Capture remained Ready/no source on route navigation; explicit button is the only new `startCapture` call; focused isolation tests pass. |
| 13 | Debug arm64 clean build | Fresh command/log ends `BUILD SUCCEEDED`. |
| 14 | Release arm64 clean build | Fresh command/log ends `BUILD SUCCEEDED`. |
| 15 | Focused regression boundary has zero failures | 14 suites; 179 total / 178 passed / 0 failed / 1 ordinary guard skip; `xcresult` Passed. |
| 16 | Four distinct production Debug screenshots | Four window screenshots exist at requested paths; PNG signatures, dimensions and distinct SHA-256 values verified. |
| 17 | Live shell routes and app startup | Overview initial; Capture, Compare and History clicked and visually observed; saved snapshot browser opened; app exited normally. |
| 18 | No backend mutation and bounded Git scope | `git diff --name-only` is exactly the two allowed UI files; `git diff --check` passes. |

## Advisory and boundary — FACT

The native titlebar remains macOS system-gray despite the existing dark titlebar token; no window architecture or fake traffic lights were added. Owner visual acceptance is not claimed; review the four production screenshots. Manual VoiceOver acceptance is not claimed.

## Proposed Worker projection

One task039 ledger row: `STATUS=WORKER_COMPLETE_PENDING_BRAIN`, `WORKER_RESULT=PASS_WITH_ADVISORY`, `TECHNICAL_SHA=add08dfe2e706dfca6620725afb3199f8b8e8bb5` (prepublication basis), `HANDOFF=handoffs/FSD_OPENDESIGN_CORE_ROUTE_VISUAL_CONFORMANCE_039_D_20261007-152250.md`; preserve all other task rows and BRAIN-owned project state. Append one Worker return event; no automatic next implementation. `PROPOSED_NEXT=OWNER_VISUAL_REVIEW`.

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=18
WORKER_REQUIREMENTS_EVIDENCED=18
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO
