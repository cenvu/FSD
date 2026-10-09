# Task048 — Source Navigator Main/Home three-point UX polish

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD2_STAGE0_5_SOURCE_NAVIGATOR_MAIN_UX_POLISH
HANDOFF_ID=handoffs/FSD_FSD2_SOURCE_NAVIGATOR_MAIN_UX_POLISH_048_D_20261009-185002.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=7e5c5580cd19aca6ffc8ac2729a3da2f708e2d80
REMOTE_HEAD=7e5c5580cd19aca6ffc8ac2729a3da2f708e2d80
LAST_VERIFIED_AT=2026-10-09T19:37:20+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|STATE/PROJECT_STATE.md|handoffs/CURRENT_HANDOFF.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|scripts/check_control_plane.py
CURRENT_PHASE=POST_V0_1_FSD2_FOUNDATION
CURRENT_GATE=FSD2_SOURCE_NAVIGATOR_MAIN_UX_POLISH_048
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE;ADVISORY=KEYBOARD_FOCUS_NOT_DEMONSTRATED|VOICEOVER_AND_OWNER_VISUAL_PENDING|TASK047_EXTERNAL_RETENTION_UNPROVEN
PROPOSED_NEXT=OWNER_VISUAL_ACCEPTANCE_AFTER_BRAIN_CLASSIFICATION
NO_AUTO_NEXT=YES

## Reporting recovery (2026-10-09T19:35:57+07:00)

The first finalizer result was STOP and did not publish. Its sole reported blocker was the invalid unpublished filename `handoffs/FSD_FSD2_SOURCE_NAVIGATOR_MAIN_UX_POLISH_048_WORKER_20261009-185002.md`; the exact original bytes are preserved at `.ai-scratch/task048/reporting-recovery/invalid-original-handoff.md` (SHA-256 `873b847965049fcbd9a9842502cb3993dcbca8e52f6ec4a431c202afbec09740`). The pre-recovery Desktop transport containing that failure evidence is preserved byte-for-byte at `.ai-scratch/task048/reporting-recovery/desktop-before-recovery.bin` (SHA-256 `2b7d2d54f1739c1c0670fe194cbaf6f9a2e2864eb2c25fb7972f06046304f738`).

BRAIN explicitly authorized one controlled recovery of this unpublished candidate. The corrected historical identity is `handoffs/FSD_FSD2_SOURCE_NAVIGATOR_MAIN_UX_POLISH_048_D_20261009-185002.md`. A later canonical check identified a separate reporting-only issue: the Worker handoff repeated a BRAIN-owned classification assignment. That assignment was removed from Worker history; the Task048 ledger remains PENDING_BRAIN. The failed checker receipt is preserved at `.ai-scratch/task048/reporting-recovery/checker-prepublication-recovery.json` (SHA-256 `53a15fb923435f261370adc8d86fac3ed9c5f4f81a721bd02583a396ea6fe81b`). Filename mismatch was the only blocker reported by the original finalizer. Product/test bytes and behavior did not change; existing Task048 evidence is reused. The corrected candidate passed the canonical prepublication checker with exact Desktop Operator/CURRENT parity (receipt SHA-256 `36e373d29faad1782643f34e580be595c1de14ab6f8300280693a7d40717bac2`).


## Task lock and authority

TASK_ID=FSD2_SOURCE_NAVIGATOR_MAIN_UX_POLISH_048
ROLE=WORKER
MODE=OWNER_APPROVED_THREE_POINT_UX_POLISH
BASE_HEAD=7e5c5580cd19aca6ffc8ac2729a3da2f708e2d80
UPSTREAM_HEAD=7e5c5580cd19aca6ffc8ac2729a3da2f708e2d80
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=EXACT_THREE_OWNER_REQUESTED_MAIN_HOME_POLISH;NO_REDESIGN_EXPLORE_STAGE1_STAGE2_OR_RELEASE
ALLOWED_PATHS=FSD/UI/ComparisonSharedViews.swift|FSDTests/ComparisonGUIValidationTests.swift|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|handoffs/CURRENT_HANDOFF.md|handoffs/FSD_FSD2_SOURCE_NAVIGATOR_MAIN_UX_POLISH_048_D_20261009-185002.md
FORBIDDEN_PATHS=STATE/PROJECT_STATE.md|AGENTS.md|docs/BRAIN_OPERATOR.md|docs/UX_UI_SPEC.md|DATABASE_SCHEMA_BACKEND_DEPENDENCIES|OTHER_UI_SCREENS_OR_TESTS|PUBLIC_RELEASE_TAG_ASSETS|OWNER_CATALOG_OR_SOURCE_MEDIA|NATIVE_FOLDER_PICKER|GLOBAL_OR_RECURSIVE_AX|SYSTEM_ACCESSIBILITY_SETTINGS
SUCCESS_CRITERIA=PARTIAL_SELECTION_STICKY_AND_EXPLICITLY_ACTIONABLE|UNAVAILABLE_NAV_COMPACT_AND_TRUTHFUL|SELECTED_CAPTURE_CARD_COMPACT_WITH_ALL_FACTS_AND_ROUTES
VALIDATIONS=FOCUSED_XCTEST|ARM64_DEBUG_RELEASE|SYNTHETIC_FSD_WINDOW_SCREENSHOTS|BOUNDED_FSD_AX|GIT_DIFF_CHECK|CANONICAL_CHECKER|DESKTOP_PARITY|MAIN_PUBLICATION
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY

## Re-anchor and protected state

At start, the physical repository was `/Users/cenvu/DEV/FSD`, origin was `https://github.com/cenvu/FSD.git`, branch `main`, and the worktree was clean at `094988961b7d1d9e915e329a7f6be99a2faa9cbd`. A non-destructive `git fetch origin` advanced `origin/main` from `0949889...` to the authorized `7e5c5580cd19aca6ffc8ac2729a3da2f708e2d80`. The local commit was an ancestor; `git merge --ff-only 7e5c5580cd19aca6ffc8ac2729a3da2f708e2d80` advanced only the branch pointer. No dirty or untracked owner work was present. Re-anchor result was `HEAD=origin/main=7e5c558...`, ahead/behind `0/0`.

At that expected head, Task047 was BRAIN-accepted `PASS_WITH_ADVISORY` at `094988961b7d1d9e915e329a7f6be99a2faa9cbd`. Owner Task048 authority is recorded in `STATE/PROJECT_STATE.md` and commit `7e5c558...`; it authorizes exactly the three Main/Home corrections in the task prompt. No Task048 ledger row or historical handoff existed at re-anchor. Owner Policy was read from the local canonical section in `AGENTS.md`, with applicable rules from `docs/BRAIN_OPERATOR.md`, accepted State, CURRENT HOT, task-execution and handoff-finalizer skills, and the macOS SwiftUI/build skills.

The accepted `STATE/PROJECT_STATE.md`, `AGENTS.md`, `docs/BRAIN_OPERATOR.md`, `docs/UX_UI_SPEC.md`, Task047 historical handoff, schema/backend/dependencies, other UI screens/tests, public release/tag/assets remain unchanged. Worker classification remains pending BRAIN.

## Work completed

### Polish A — partial capture selection

- Main selection remains keyed by stable `SnapshotID`. A selected partial snapshot stays selected when history refreshes; the refresh helper no longer replaces any explicit selection.
- Partial Browse remains disabled and now has the requested visible explanation: “This capture is incomplete. Select a completed capture to browse its stored metadata.”
- When a completed snapshot exists, the secondary `Select latest complete` action targets the first completed item in existing `ApplicationModel.history` ordering and stores that summary's `SnapshotID`. The action changes selection only when activated. Browse then becomes enabled for that completed selection and still calls the existing `model.openSnapshot(summary)` route.
- The CTA is omitted when there is no completed snapshot. The normal manual Capture action remains available.

### Polish B — sidebar density

- Home, Recent Captures, and Comparisons remain the prominent working sidebar destinations. Manual Capture remains in the active toolbar.
- All Drives, Drive Sets, Connected Now, and Auto Capture are grouped under one native `DisclosureGroup`, collapsed by default. Selecting All Drives keeps the group expanded so the selected route remains visible; the existing All Drives destination still presents its unavailable placeholder.
- Connected Now says no connected-drive service exists. Auto Capture remains disabled and labeled unavailable. Search was removed from the active toolbar.
- No mounted-drive, connected-source, drive-library, or automatic-capture capability was added or implied.

### Polish C — selected-card density

- Reduced the selected-card spacing and padding, compacted metadata/count cells, and tightened Home section spacing.
- Preserved source label, snapshot label/root, SnapshotID, capture timestamp, completion/partial/warning badge, live-source-identity qualifier, all recorded counts, Browse, History, Compare, and manual Capture.
- Partial actions use a two-row layout so the explanation sits directly beside disabled Browse and the selection/History/Compare buttons retain their natural widths.

## Test and build evidence

Causal RED was observed by temporarily removing the selected-ID guard: the focused selection test executed `1/1` and failed the exact partial-selection assertion (`XCTAssertNil failed: "4"`). The guard was restored. An initial compile reported a missing explicit `return` after the guard; that one-line correction was made before the final run.

Final command:

```text
xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath .ai-scratch/task048/DerivedData -resultBundlePath .ai-scratch/task048/results/required-suites-acceptance.xcresult -only-testing:FSDTests/ComparisonGUIValidationTests -only-testing:FSDTests/ComparisonGUISourceBoundaryTests -only-testing:FSDTests/SnapshotHistoryTests -only-testing:FSDTests/LazyTreeBrowsingTests
```

Result: exit `0`, `84` executed, `84` passed, `0` failed, `0` skipped: `ComparisonGUIValidationTests` 37/37, `ComparisonGUISourceBoundaryTests` 7/7, `SnapshotHistoryTests` 28/28, `LazyTreeBrowsingTests` 12/12. The GUI validation tests now cover latest-complete ordering by stable ID, selected-partial preservation, Browse ineligibility, no completed target, repeated source labels, and existing Main route callback wiring.

Arm64 builds on the final product source:

- `xcodebuild build -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath .ai-scratch/task048/DerivedData` — exit `0`, `BUILD SUCCEEDED`.
- Same command with `-configuration Release` — exit `0`, `BUILD SUCCEEDED`.

## Synthetic GUI and bounded accessibility evidence

The GUI app was launched with explicit `-FSDCatalogPath` arguments pointing only to isolated Task048 copies of the synthetic Task047 `main` and `empty` catalogs. The copied databases passed SQLite integrity and foreign-key checks. No Owner catalog or source-media path was used.

Only the FSD application window was captured via its FSD-owned window ID. Pixel dimensions correspond to the exact requested logical widths:

- `.ai-scratch/task048/screenshots/populated-main-1330.png` — 2660×1496 pixels (1330×748 pt).
- `.ai-scratch/task048/screenshots/partial-selected-main-1120.png` — 2240×1496 pixels (1120×748 pt).
- `.ai-scratch/task048/screenshots/completed-selected-main-1440.png` — 2880×1496 pixels (1440×748 pt).
- `.ai-scratch/task048/screenshots/empty-main-1120.png` — 2240×1496 pixels (1120×748 pt).

The populated 1330 and completed 1440 views show the collapsed compact sidebar and multiple Capture History rows above the fold. The 1120 partial view shows the selected partial context, disabled Browse, exact guidance, and available `Select latest complete` action without clipping. The 1440 completed view shows the selected complete SnapshotID and enabled Browse. The empty 1120 view retains the manual Capture button. Task047 screenshots were inspected for comparison and were not modified.

Bounded interaction checks used the FSD process/window and direct UI elements only. The partial capture stayed selected until the `Select latest complete` control was clicked. Its accessible help/label identified snapshot `#3`; after activation, the History row value became `Selected` and Browse was enabled. Browse and History both routed to `Library / Recent Captures`; Compare routed to `Compare / Comparisons`; Capture routed to `Library / Capture` without opening the folder picker; All Drives routed to `Library / All Drives` placeholder. The sidebar disclosure expanded by mouse and its disabled Auto Capture state and “No connected-drive service yet” text were observed.

A separate keyboard activation was not demonstrated: the disclosure's focused AX value was unavailable and Space did not toggle it. Mouse activation passed. No keyboard/accessibility preference was inspected or changed. Manual VoiceOver was not performed; Owner visual acceptance remains pending as requested.

## Privacy, review, and scope

No native folder picker, source-media content, or Owner catalog was accessed. No Finder/Desktop directory listing or global/recursive AX scan was performed. The only Desktop interaction is the explicitly requested BRAIN transport file for finalizer parity. No system-wide accessibility setting was changed. Screenshots contain only the FSD application window and synthetic catalog facts. The original Task047 privacy STOP remains preserved; external retention of its prior AX output remains UNPROVEN and no resolution/containment claim is made. No new privacy exposure occurred.

Full diff review: PASS. Reviewed sticky `SnapshotID` selection, history ordering, incomplete-snapshot browse ineligibility, only explicit CTA selection mutation, existing route closures, truthful placeholders/offline identity, accessible labels/hints, native controls, compact layout at the target widths, and source-read-only/privacy boundaries. No snapshot semantics, database/schema/backend, other UI screens, or release assets changed. `git diff --check`: PASS. Current tracked candidate is limited to the two authorized product/test files.

## Execution requirement map

| # | Requirement | Result | Evidence |
|---:|---|---|---|
| 1 | Correct repository/origin/main, expected head, clean initial state, safe re-anchor | EVIDENCED | Fetch and fast-forward-only receipt above; final re-anchor remained 0/0. |
| 2 | Task047 accepted and Task048 authorized/not previously published | EVIDENCED | Accepted State, Owner decision at expected head; no Task048 ledger/history at start. |
| 3 | Exact two-file product/test scope and protected State/docs/backend/release boundaries | EVIDENCED | `git diff --name-only`; protected paths unchanged. |
| 4 | Partial capture remains selected before explicit user action | EVIDENCED | Causal RED/GREEN selection test and bounded GUI interaction. |
| 5 | Partial Browse disabled with exact visible explanation | EVIDENCED | Focused test and 1120 FSD-window screenshot/AX state. |
| 6 | Latest completed selection follows history ordering and stable SnapshotID | EVIDENCED | Helper test, accessible CTA activation selecting snapshot #3. |
| 7 | No completed capture omits fake CTA and preserves manual Capture | EVIDENCED | Nil latest-complete test, conditional UI, empty Main screenshot. |
| 8 | Completed Browse uses existing stored-snapshot route | EVIDENCED | Callback test and bounded Browse activation to Recent Captures. |
| 9 | Existing History route remains | EVIDENCED | Callback test and bounded route activation. |
| 10 | Existing Compare route remains | EVIDENCED | Callback test and bounded route activation. |
| 11 | Existing manual Capture route remains without opening picker | EVIDENCED | Callback test and toolbar activation to Capture; no picker opened. |
| 12 | Repeated source names stay distinct | EVIDENCED | Synthetic test creates three “Shared Card” records and selects by ID. |
| 13 | Home, Recent Captures, Comparisons and manual Capture stay prominent/functional | EVIDENCED | Source review, screenshots and route activations. |
| 14 | Planned/unavailable items grouped compactly and collapsed by default | EVIDENCED | Native disclosure state and populated screenshots. |
| 15 | All Drives placeholder remains truthful; no drive/connection/automation claims | EVIDENCED | Placeholder route and scoped AX labels; Auto Capture disabled. |
| 16 | Disabled Search no longer competes with working toolbar actions | EVIDENCED | Search removed; populated screenshots show only working toolbar actions. |
| 17 | Card retains capture context, identity qualifier, status, counts, and routes | EVIDENCED | Source review, AX, and populated/partial/complete screenshots. |
| 18 | Card/history compact and readable at requested widths | EVIDENCED | Exact 1120/1330/1440 screenshots; no clipping/truncation. |
| 19 | Focused XCTest suites pass | EVIDENCED | 84/84, zero skipped/failed. |
| 20 | Arm64 Debug and Release builds pass | EVIDENCED | Both final product builds succeeded. |
| 21 | Privacy-safe visual proof uses synthetic catalogs and FSD-only window capture | EVIDENCED | Four exact ignored paths and sizes above. |
| 22 | Bounded FSD accessibility and input activation | EVIDENCED | Direct FSD labels; mouse activation of partial row, latest-complete CTA and disclosure. |
| 23 | No source-media read, picker launch, broad AX scan, or global setting change | EVIDENCED | GUI process args and bounded action history; no picker/Owner path accessed. |
| 24 | Task047 STOP and external-retention advisory preserved | EVIDENCED | No Task047 history/event bytes modified; advisory repeated without a closure claim. |
| 25 | Full diff review and diff check | EVIDENCED | Review summary above; `git diff --check` exit `0`. |
| 26 | Separate keyboard activation | NOT_APPLICABLE | Mouse path satisfied the input activation check; host focus property unavailable and no system setting changed. Keyboard path is not claimed. |
| 27 | Manual VoiceOver | NOT_APPLICABLE | Not performed; remains pending. |
| 28 | Owner visual acceptance | NOT_APPLICABLE | Pending Owner review after BRAIN adjudication. |

## Finalizer-owned closure

The immutable handoff is prepared from prepublication `HEAD=7e5c558...`; its self-publication SHA is intentionally not recorded here. Canonical prepublication checker PASS and exact Desktop Operator/CURRENT parity are evidenced by the recovery receipt (SHA-256 `36e373d29faad1782643f34e580be595c1de14ab6f8300280693a7d40717bac2`); `git diff --check` passes. The normal commit/push, clean/synced postpublication checker and publication SHA are reported in the final Desktop transport and Worker return after those physical checks run. `STATE/PROJECT_STATE.md` remains unchanged. Public release/tag/assets remain unchanged. No Task049 or Stage1/Stage2 work started.

RESULT=PASS_WITH_ADVISORY
Worker handoff leaves classification to BRAIN; Task048 ledger remains PENDING_BRAIN.
OWNER_VISUAL_ACCEPTANCE=PENDING

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=28
WORKER_REQUIREMENTS_EVIDENCED=25
WORKER_REQUIREMENTS_NOT_APPLICABLE=3
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO
