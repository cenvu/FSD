# Screenshot-authorized native FSD shell — task037A

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_OPENDESIGN_SCREENSHOT_UI_SHELL_RESCOPE_037A_D_20261007-105206.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=082d5816e9397bfab3e88e0d5aadeff95061a4b0
REMOTE_HEAD=082d5816e9397bfab3e88e0d5aadeff95061a4b0
LAST_VERIFIED_AT=2026-10-07T10:51:15+07:00
AUTHORITY_PTRS=AGENTS.md|STATE/PROJECT_STATE.md|docs/BRAIN_OPERATOR.md|docs/AGENT.md|docs/UX_UI_SPEC.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_OPENDESIGN_SCREENSHOT_UI_SHELL_RESCOPE_037A
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_FOR_WORKER_SCOPE;OWNER_VISUAL_REVIEW_PENDING
PROPOSED_NEXT=FSD_OPENDESIGN_OWNER_VISUAL_REVIEW_038
NO_AUTO_NEXT=YES

## Task lock and result

TASK_ID=FSD_OPENDESIGN_SCREENSHOT_UI_SHELL_RESCOPE_037A
ROLE=WORKER
MODE=BOUNDED_NATIVE_UI_IMPLEMENTATION
BASE_HEAD=082d5816e9397bfab3e88e0d5aadeff95061a4b0
UPSTREAM_HEAD=082d5816e9397bfab3e88e0d5aadeff95061a4b0
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=OWNER_SCREENSHOT_DERIVED_NATIVE_APP_SHELL_AND_LIBRARY_OVERVIEW
ALLOWED_PATHS=FSD/App/FSDApp.swift|FSD/UI/ComparisonSharedViews.swift|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|handoffs/CURRENT_HANDOFF.md|handoffs/FSD_OPENDESIGN_SCREENSHOT_UI_SHELL_RESCOPE_037A_D_20261007-105206.md
FORBIDDEN_PATHS=FSD/Catalog/**|FSD/Scanner/**|FSD/Diff/**|FSD/Classification/**|FSD/Provider/**|FSD/Helpers/**|DATABASE_SCHEMA_MIGRATIONS|GO_FILES_DEPENDENCIES|FSD.xcodeproj/**|FSDTests/**|STATE/PROJECT_STATE.md|STATE/RULE_PROMOTION_LEDGER.tsv|CANONICAL_DOCS|PRIOR_HANDOFFS|OWNER_IGNORED_UNTRACKED_FILES|ALL_OTHER_PRODUCT_SOURCE
SUCCESS_CRITERIA=NATIVE_DARK_SHELL_AND_LIBRARY_OVERVIEW;REAL_CAPTURE_HISTORY_COMPARE_ROUTES;TRUTHFUL_UNAVAILABLE_STATES;DEBUG_RELEASE_AND_REGRESSIONS;LIVE_APP_SCREENSHOT;NO_AUTO_CAPTURE_CLASSIFICATION_OR_MOUNT_DETECTION
VALIDATIONS=FRESH_FETCH_AND_IDENTITY;DEBUG_RELEASE_ARM64_CLEAN_BUILDS;FOCUSED_EXISTING_REGRESSIONS;LIVE_DEBUG_APP_ROUTE_OBSERVATION;WINDOW_SCREENSHOT;SOURCE_BOUNDARY_AUDIT;POSTFLIGHT_SCOPE_AND_HISTORY;CONTROL_CHECKER;PUBLICATION_PARITY
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
RESULT=PASS_WITH_ADVISORY
VISUAL_AUTHORITY=OWNER_SCREENSHOT_PLUS_UX_UI_SPEC
PRODUCT_BACKEND_MUTATION=NO
BUILDS=DEBUG_ARM64_CLEAN_BUILD_PASS;RELEASE_ARM64_CLEAN_BUILD_PASS
TESTS=14_FOCUSED_SUITES;179_TOTAL;178_PASSED;0_FAILED;1_SKIPPED
SCREENSHOT=.ai-scratch/task037a/library-overview-production.png
OWNER_VISUAL_ACCEPTANCE=NOT_CLAIMED;OWNER_REVIEW_PROPOSED

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=23
WORKER_REQUIREMENTS_EVIDENCED=22
WORKER_REQUIREMENTS_NOT_APPLICABLE=1
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

## Authority and physical re-anchor — FACT

- The task-provided Owner screenshot is the visual authority, with `docs/UX_UI_SPEC.md` governing semantic/product wording and existing production code governing implemented behavior. The task explicitly removed the local OpenDesign HTML/CSS/JS discovery gate; no such source was searched for or required.
- Physical canonical root is `/Users/cenvu/DEV/FSD`, branch `main`, origin `https://github.com/cenvu/FSD.git`, upstream `origin/main`. A fresh `git fetch origin` before product mutation found local and upstream exactly at `082d5816e9397bfab3e88e0d5aadeff95061a4b0` (`0/0`); the primary worktree was clean. A second fresh fetch before finalization again found the same base and `0/0`.
- `.ai-scratch/task037a` did not exist before this task. It now contains only this task's ignored build, test, screenshot and closure evidence. Existing ignored/untracked Owner files and prior scratch were not changed or removed.
- Loaded the task-execution and handoff-finalizer skills, root `AGENTS.md`, accepted `STATE/PROJECT_STATE.md`, Compact and `docs/UX_UI_SPEC.md`. Accepted state and rule-promotion ledger remain byte-identical to the re-anchor. Task037's historical STOP handoff remains unchanged.

## Native UI delta — FACT

- `FSD/App/FSDApp.swift` now enters `FSDAppShellView` with a 1120×720 minimum window. `ApplicationModel`, capture semantics, snapshot history ownership, process lock and classification runtime ownership remain unchanged.
- `FSD/UI/ComparisonSharedViews.swift` now contains the screenshot-derived shell as separate SwiftUI components: centralized dark tokens; sidebar; breadcrumb/action top bar; Library Overview; metric, history and unavailable-state panels; and the existing history/capture screen presentation extracted for shell routing. No project-file membership changes or new source files were needed.
- The initial destination is Library Overview. Sidebar sections show HOME, LIBRARY, DRIVE SETS, COMPARE and CONNECTED NOW, with blue selected treatment and a bottom Auto Capture affordance. Capture, Search, Compare and History appear in the top bar.
- Overview uses the already-loaded `model.history` count and a bounded three-capture prefix. Recent comparisons use the existing read-only `ComparisonResultRepository.listComparisons(limit: 3)` API. Drives, item totals and storage show `—`; Recent Drives, Connected Now and Drive Sets state that their services are unavailable. Search is disabled with help for snapshot-scoped search. No prototype sample values or preview fixtures were added.
- Capture routes to the existing explicit folder-selection/metadata-capture workflow; it does not open a panel or start scanning until the user chooses those controls. History/Recent Captures route to the existing snapshot history/browser. Compare/Comparisons route to the existing comparison destination. All Drives shows an explicit unavailable state and makes no mount query.
- The new root applies `.preferredColorScheme(.dark)` locally. New controls have accessibility labels/hints; the sidebar exposes selection by text/selected trait. This is not a VoiceOver acceptance claim.
- The only tracked product paths changed are `FSD/App/FSDApp.swift` and `FSD/UI/ComparisonSharedViews.swift`. No Catalog, Scanner, Diff, Classification, Provider, helper, schema, Go dependency, comparison/capture/classification semantics, JSON format, test source, project file or canonical document changed.

## Validation — FACT

Fresh Debug arm64 build:

`xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath .ai-scratch/task037a/debug-derived clean build` — exit 0, `BUILD SUCCEEDED`.

Fresh Release arm64 build:

`xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Release -destination 'platform=macOS,arch=arm64' -derivedDataPath .ai-scratch/task037a/release-derived clean build` — exit 0, `BUILD SUCCEEDED`.

Focused Debug regressions ran these 14 existing suites: `SnapshotHistoryTests`, `LazyTreeBrowsingTests`, `MetadataSearchTests`, `SnapshotBrowserClassificationTests`, `ComparisonWorkspaceModelTests`, `ComparisonBrowserModelTests`, `ComparisonGUIValidationTests`, `ComparisonGUISourceBoundaryTests`, `ComparisonPersistenceTests`, `ComparisonSemanticsTests`, `ClassificationInvocationIsolationTests`, `Milestone2CaptureTests`, `CaptureErrorBoundaryTests` and `FSDProbeSeedTests`. `xcrun xcresulttool get test-results summary --path .ai-scratch/task037a/focused-regressions-final.xcresult --format json` reports 179 total, 178 passed, 0 failed, 1 skipped; result `Passed`. Full suite was not run; earlier accepted evidence records it as a multi-thousand-second run, so focused suites cover this UI boundary.

Agent observation used the actual rebuilt Debug app at `.ai-scratch/task037a/debug-derived/Build/Products/Debug/FSD.app` on macOS 15.7.7 arm64. Window text and screenshots confirmed Library Overview is initial. System Events clicks observed top Capture → `Library / Capture` with `No folder selected` and `Ready` (no chooser opened), History → `Library / Recent Captures`, Compare → `Compare / Comparisons`, sidebar Recent Captures → history, sidebar Comparisons → comparison destination, and All Drives → explicit unavailable state. Search, New Drive Set and Auto Capture reported `enabled=false` and explanatory help. Debug process PID 84815 remained alive after navigation; no immediate crash observed.

The final window-only production Debug screenshot is `.ai-scratch/task037a/library-overview-production.png` (2240×1496). It shows actual local catalog content, no prototype sample data, disabled/unavailable controls, the four metric cards, two-column recent panels and Recent Drives state.

## Automatic-behavior regression — FACT

- The fresh `ClassificationInvocationIsolationTests` suite passed. Its existing launch/capture/history/browsing checks include `testApplicationLaunchNeverStartsClassification`, `testCaptureWorkflowNeverStartsClassification` and `testHistoryOpenNeverStartsClassification`.
- The new shell and overview have no classification-start, classifier, `FileManager`, `/Volumes` or mount-observer calls. The only shell path to `model.startCapture` is the explicit Start Metadata Capture button in the routed capture screen; Library Overview and navigation do not call it. Opening a saved snapshot continues through the existing `ApplicationModel.openSnapshot` path, which documents and preserves no automatic classification.
- Live launch stayed on Library Overview; the explicit Capture destination showed no source selected and Ready. No capture was started. All Drives explicitly reports that this screen does not detect mounted drives.

## Requirement accounting against the exact task

E = evidenced; N = not applicable with reason. No material requirement is unproven.

| Clause | Status | Evidence |
|---|---|---|
| 1 Re-anchor | E | Fresh fetch, exact base/upstream, clean primary baseline; protected state preserved |
| 2 Owner screenshot | E | Screenshot-derived native shell; no HTML/CSS/JS gate used |
| 3 Screenshot mock interpretation | E | No prototype values or preview fixtures in production |
| 4 Product truth boundary | E | Bounded existing records, unavailable totals as `—`, truthful placeholders |
| 5 Preserve accepted backend | E | Zero forbidden-path/backend/schema/helper/dependency changes |
| 6 UI scope | E | Only app entry and UI layer changed |
| 7 Shell architecture | E | Native SwiftUI shell separated into components |
| 8 Dark visual system | E | Central tokens; local dark appearance; blue selected state |
| 9 Navigation | E | Required destinations and live Capture/History/Compare routes |
| 10 Library Overview | E | Initial screen; bounded records, four metrics and lower panels |
| 11 Existing functional views | E | Snapshot browser and comparison creation/workspace remain existing views |
| 12 Capture UX | E | Manual workflow route; no automatic selection or scan |
| 13 Accessibility | E | Labels, hints, textual selection; no VoiceOver claim |
| 14 Preview data | E | No preview/mock fixture added |
| 15 UI-focused tests | N | No standalone pure navigation logic; live route observation and existing regression suites provide evidence |
| 16 Validation | E | Fresh Debug/Release arm64 builds; focused suite counts recorded |
| 17 Automatic behavior | E | Isolation suite, source-boundary audit and live Ready/no-source state |
| 18 Agent observation | E | Actual Debug app and destination routes observed |
| 19 Screenshot | E | Window-only screenshot exists at the reported path |
| 20 Owner visual acceptance | E | Worker makes no taste/acceptance claim; Owner review is proposed |
| 21 Stop conditions | E | No backend, schema, mount, auto-capture, Drive Set or search semantics work |
| 22 Success criteria | E | Shell, truthful overview, routes, builds, regressions and screenshot supplied |
| 23 Publication | E | One immutable handoff/current mirror and Worker projection are the authorized closure packet; postpublication receipt is recorded in Desktop transport because this handoff cannot contain its own publication SHA |

## Proposed Worker state delta — not accepted state

Add exactly one task037A row to `STATE/TASK_LEDGER.tsv` with status `WORKER_COMPLETE_PENDING_BRAIN`, scope `OWNER_SCREENSHOT_DERIVED_NATIVE_APP_SHELL_AND_LIBRARY_OVERVIEW`, executor `WORKER`, technical basis `082d5816e9397bfab3e88e0d5aadeff95061a4b0`, Worker result `PASS_WITH_ADVISORY`, pending BRAIN classification, this handoff path and a concise evidence note. Append exactly one `worker_return` event with `commit=null` and this handoff ref. Do not alter `STATE/PROJECT_STATE.md`, rule promotions, task037 row, prior events or prior handoffs. Advisory: Owner visual taste/acceptance has not been adjudicated; propose `FSD_OPENDESIGN_OWNER_VISUAL_REVIEW_038`.

## Publication boundary

This immutable record uses the actual prepublication base in HOT. It cannot contain its own future commit/publication SHA. Finalizer checker, commit, explicit push, fresh fetch, clean/synced verification and Desktop final receipt must be observed after this source is created; no future outcome is preclaimed here.

RAW_REFS=.ai-scratch/task037a/closure-preflight.json|.ai-scratch/task037a/focused-regressions-final.xcresult|.ai-scratch/task037a/library-overview-production.png
