# Task065S Internal Preview XCTest-host escape repair — Worker return

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD2_INTERNAL_PREVIEW
HANDOFF_ID=handoffs/FSD_FSD2_INTERNAL_PREVIEW_TEST_HOST_ESCAPE_REPAIR_065S_D_20261019-143536.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=e36d4eed17376629189d0ab69bf626ca5d49461b
REMOTE_HEAD=e36d4eed17376629189d0ab69bf626ca5d49461b
LAST_VERIFIED_AT=2026-10-19T14:32:02+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|docs/AGENT.md|STATE/PROJECT_STATE.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|handoffs/CURRENT_HANDOFF.md|handoffs/FSD_FSD2_ISOLATED_INTERNAL_PREVIEW_BUILD_065_D_20261019-124928.md|handoffs/FSD_FSD2_INTERNAL_PREVIEW_ISOLATION_REPAIR_065R_D_20261019-134535.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-independent-review/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|FSD/Catalog/CatalogLocation.swift|FSD/App/FSDApp.swift|FSD.xcodeproj/project.pbxproj|FSDTests/InternalPreviewIsolationTests.swift|scripts/build_internal_preview.sh|scripts/internal_preview_manifest.json|scripts/check_control_plane.py
CURRENT_PHASE=POST_V0_1_FSD2_FOUNDATION
CURRENT_GATE=FSD2_INTERNAL_PREVIEW_TEST_HOST_ESCAPE_REPAIR_065S
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_FOR_SCOPED_REPAIR;SAME_USER_CHECK_OPEN_RACE_ADVISORY;OWNER_PREVIEW_MANUAL_ACCEPTANCE_NOT_PERFORMED;NO_PUBLIC_RELEASE
PROPOSED_NEXT=WAIT(BRAIN_REVIEW_TASK065S_INTERNAL_PREVIEW_TEST_HOST_ESCAPE_REPAIR)
NO_AUTO_NEXT=YES

## Execution identity, authority and scope

PROJECT=FSD
TASK_ID=FSD2_INTERNAL_PREVIEW_TEST_HOST_ESCAPE_REPAIR_065S
ROLE=WORKER
BASE_HEAD=e36d4eed17376629189d0ab69bf626ca5d49461b
UPSTREAM_HEAD=e36d4eed17376629189d0ab69bf626ca5d49461b
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=REMOVE_SHIPPED_PREVIEW_XCTEST_HOST_REDIRECT;PRESERVE_DEBUG_PRODUCTION_TEST_HOST_ISOLATION;FILESYSTEM_IDENTITY_ALIAS_GUARD;SYNTHETIC_PACKAGED_LAUNCH_REGRESSIONS;CLEAN_BUILDS_AND_REVIEW;NORMAL_REPORTING
ALLOWED_PATHS=FSD/Catalog/CatalogLocation.swift|FSDTests/InternalPreviewIsolationTests.swift|scripts/build_internal_preview.sh|scripts/internal_preview_manifest.json|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|handoffs/CURRENT_HANDOFF.md|handoffs/FSD_FSD2_INTERNAL_PREVIEW_TEST_HOST_ESCAPE_REPAIR_065S_D_20261019-143536.md
FORBIDDEN_PATHS=STATE/PROJECT_STATE.md;STATE/RULE_PROMOTION_LEDGER.tsv;PRIOR_HANDOFFS;SCHEMA_V13;COMPLETION_RECEIPTS;SAVE_DELETE;SOURCE_CAPTURE;OWNER_CATALOG_OR_MEDIA;HARDWARE;AUTO_CAPTURE;PUBLIC_RELEASE;TASK066
SUCCESS_CRITERIA=PREVIEW_HAS_NO_RUNTIME_XCTEST_REDIRECT;SPOOFED_KEYS_RESOLVE_ONLY_DEDICATED_SYNTHETIC_PREVIEW_CATALOG;GENERATED_HOST_ALIAS_SENTINEL_UNCHANGED;SYMLINK_CASE_HARDLINK_ALIASES_FAIL_CLOSED;DEBUG_TEST_HOST_ISOLATION_PRESERVED;CLEAN_ARM64_PREVIEW_DEBUG_RELEASE;FOCUSED_REGRESSIONS_AND_PACKAGE_VERIFICATION;READ_ONLY_REVIEW;ONE_HISTORY_CURRENT_LEDGER_EVENT;PRE_POST_CHECKS_AND_SYNCED_PUBLICATION
WORKER_RESULT=PASS_WITH_ADVISORY

FACT: The physical repository is `/Users/cenvu/DEV/FSD`, branch `main`, origin `https://github.com/cenvu/FSD.git`. A fresh non-destructive fetch at 2026-10-19T14:32:02+07:00 found local `HEAD`, `origin/main` and the authorized base equal at `e36d4eed17376629189d0ab69bf626ca5d49461b` with 0/0 divergence. The initial candidate was limited to the four authorized implementation/test/package paths listed below; no pre-existing dirty or untracked repository state was present. The only later repository additions for this return are this one handoff, its CURRENT mirror and one Worker ledger row/event.

The Owner Policy, Compact Operator, accepted State, ledger/events, CURRENT HOT, exact Task065 and Task065R immutable handoffs, and task-execution, independent-review and handoff-finalizer skills were read. Owner standing bounded sprint authority covers this same-preview safety repair. This Worker does not accept Task065/065R, edit BRAIN-owned State, or begin another task.

## Finding, root cause and bounded repair

BRAIN finding C was confirmed in the compiled resolver: the `.internalPreview` runtime branch checked XCTest environment keys and returned `testHostCatalogURL()` before calling `internalPreviewURL()`. Because the keys are environment-controlled, a shipped Preview process could be given `XCTestConfigurationFilePath`, `XCTestBundlePath` or `XCTestSessionIdentifier` and redirected to the process-specific test-host catalog path. Before the fix, the added `testInternalPreviewIgnoresSpoofedXCTestEnvironmentKeys` regression reproduced `.testHost`; `testInternalPreviewCatalogHardlinkedToProductionFailsClosed` also reproduced the missing hardlink rejection.

The Preview branch now goes directly to its dedicated catalog resolver. The runtime XCTest host branch and its keys/path helper compile only under `#if DEBUG && !FSD_INTERNAL_PREVIEW`; the helper is absent from Release and Preview. This preserves the Debug production test host while removing the environment-controlled branch from the shipped Preview. A Preview still rejects launch argument and environment catalog overrides, including the old test-root key.

## Filesystem identity and fail-closed behavior

`internalPreviewURL` now compares both the preview/production directories and the catalog paths. For existing paths, `fstatat(AT_FDCWD, path, ..., 0)` follows symbolic links and compares device/inode identity. For paths without an identity yet, or distinct existing objects, canonical symlink-resolved standardized paths remain a second check. ENOENT/ENOTDIR permits the canonical-name comparison; other metadata errors raise a generic error and fail closed. This covers existing symlink targets, case-folded aliases that resolve to one object, and hardlinks with different names. The failure text does not disclose a catalog path.

The exact synthetic negative regressions passed: `testInternalPreviewDirectorySymlinkedOntoProductionFailsClosed`, `testInternalPreviewDirectoryCaseAliasToProductionFailsClosed`, `testInternalPreviewCatalogFileSymlinkedOntoProductionFailsClosed` and `testInternalPreviewCatalogHardlinkedToProductionFailsClosed`. The case-only fixture asserted equal device/inode before the resolver call; the hardlink fixture likewise asserted equal device/inode. The generated fixture volume supported the case alias, so that test did not skip. Each fixture uses a private synthetic Application Support root and generated catalog bytes.

This is a check-before-open guard, not an atomic open-by-identity design. A same-user local process able to mutate Application Support could replace an alias after `internalPreviewURL` validates it and before the later database open by path. The tests and package smoke cover aliases present at resolution time and do not claim to close this race. No absolute protection claim is made.

## Compiled flavor and runtime evidence

`xcodebuild -showBuildSettings` reported Debug `SWIFT_ACTIVE_COMPILATION_CONDITIONS=DEBUG`, Preview `FSD_INTERNAL_PREVIEW`, and no Debug flag for Release. On this Xcode configuration, Debug application logic is in `FSD.debug.dylib`: it contains all three XCTest keys and `FSD-TestHost-`. The arm64 Release app and packaged Preview executable contain none of those strings. Release retains `FSD_PRODUCTION_FLAVOR_ACTIVE`; Preview retains `FSD_PREVIEW_FLAVOR_ACTIVE` and excludes the production marker. The Preview bundle uses identifier `com.fsd.FSD-InternalPreview`, name `FSD2InternalPreview`, display name `FSD2 Internal Preview`, and the existing distinct preview banner. The packaging manifest remains the source for these identities and now names Task065S's artifact and repair receipt.

The packaged Preview was launched with `CFFIXED_USER_HOME` pointing under `.ai-scratch/task065s/package/launch-xctest-home`, all three spoofed XCTest keys, synthetic override decoys, and a process-specific `FSD-TestHost-41675` symlink to a generated sentinel. The actual packaged process logged only:

```text
FSD Internal Preview catalog: /Users/cenvu/DEV/FSD/.ai-scratch/task065s/package/launch-xctest-home/Library/Application Support/FSD-Internal-Preview/catalog.sqlite3 (source: internalPreview)
```

The generated test-host alias path `/var/folders/89/bwjml4px7bd8_gc4y493myh80000gn/T/FSD-TestHost-41675/catalog.sqlite3` did not appear in the startup log, and no `testHost` source was reported. The test-host sentinel SHA-256 before/after was `dc3ebb2ec972ddde8677ead8282314ce6f11d93fb0fe0e385340b8d07f96f1e6`; the script verified it unchanged and removed only its recorded symlink after verifying the link still targeted that generated sentinel. The synthetic production sentinel also remained unchanged at `59fe0e3f7d9ef121028f1ff72f18965bf9d2073fb2a45f625356876fab444fde`. The receipt and logs are in `.ai-scratch/task065s/package/`.

The existing Preview launch smoke still resolved only its synthetic `FSD-Internal-Preview/catalog.sqlite3` and reported its override as ignored. The actual packaged symlink smoke still refused to start with the production-conflict error and left its synthetic target sentinel unchanged. A separate arm64 Release launch used the same three spoofed keys plus a synthetic host-path alias; it resolved only the generated home's `Library/Application Support/FSD/catalog.sqlite3` with `source: applicationSupport`, while its test-host sentinel stayed at SHA-256 `743039566a3c452d80edeb7957f8db6853b23a021d402c7860c9f52d5d94f119`. Debug's `testDebugXCTestHostKeepsItsOwnIsolatedCatalogWhenXCTestKeysArePresent` passed and asserts `.testHost` plus the Debug-only `testHostCatalogURL()` path.

Every task test and package process used generated roots under `.ai-scratch/task065s` or UUID-named temporary fixtures. No task validation opened, hashed, statted or otherwise inspected the Owner production or preview catalog. The resolver's identity calls in these tests were directed only at generated synthetic paths.

## Build, tests and package verification

Clean arm64 builds passed for Preview, Debug and Release. The Preview packaging script performed two independent `clean build` runs using its Preview configuration; the separate clean Debug and Release app builds exited 0. The Preview source files predate the final packaged binary, and the shipped bundle was extracted and checked against the final receipt.

The focused macOS 15.7.7 arm64 Debug XCTest run passed 147/147 with zero failures or skips. It included all 21 `InternalPreviewIsolationTests`, catalog database/migration and completion receipt tests, comparison semantics/identity/modes/persistence, and saved comparison Save/Delete and migration coverage. A second selected Task064 `ComparisonAncestorNavigationTests` run passed 15/15 with zero failures or skips. Its screenshot/keyboard/AX compositor test was excluded so `.ai-scratch/task064/screenshots` remained untouched. No Task065 smoke test wrote to the prior `.ai-scratch/task065/screenshots`.

The two clean Preview package builds had identical file-tree SHA-256 `d00832f7c94e46025b5673c19e4bea8794a2d1fa48ed63671a6d20bf32fe1fd4`. Extracting the final ZIP produced the same tree digest, and its Preview executable SHA-256 matched the staged executable at `dac075e3d0af76cda1ace05f33e09ee6ddb623f3903616faf0ddd1d12b762fd9`. The ZIP hash varies across build times as expected from archive metadata: first run `a9f53a19c0f47531d68bcb1dcd8853f75cfa14a1d02f860210c3d8da8a4704f6`; final workspace and Desktop ZIP hash `cad333889b8f1912386ccd2da9e407b721fd984f40dcc3686884912ee7a616b9` (4,451,319 bytes). The workspace and Desktop artifacts match exactly. `git diff --check`, `bash -n scripts/build_internal_preview.sh` and JSON manifest parsing passed.

## Independent read-only review

A distinct-context reviewer `/root/review_065s` returned PASS_WITH_ADVISORY on the four-path candidate. It confirmed Preview returns before the Debug host branch, the runtime helper is compile-gated, the receipt and manifest agree, the final ZIP hash matches, the alias PID matches the record, the launch log resolves to the synthetic Preview catalog, and cleanup is restricted to task scratch plus the generated process-specific symlink after target verification. The reviewer did not run Xcode or inspect Owner catalogs. Its advisory is the check/open race described above; no material unresolved finding remains within this bounded correction.

## Exact candidate and protected state

The substantive diff is exactly four paths: `FSD/Catalog/CatalogLocation.swift` (42 additions/15 removals), `FSDTests/InternalPreviewIsolationTests.swift` (118/14), `scripts/build_internal_preview.sh` (152/5), and `scripts/internal_preview_manifest.json` (2/2): 314 insertions and 36 deletions. The pre-report binary diff SHA-256 is `b2b578ed84c90457f11980ae253fa77c56c79ddb85d32f8bf3c3b2d645bc03e9`. No schema, receipt, Save/Delete, source capture, provider, or UI implementation path changed. `STATE/PROJECT_STATE.md` remains byte-identical to base SHA-256 `78021b2ef73ef5eaae8991daf2f06f34b48674a0d3bfc8d6cca5bc80c2c8e6e9`; `STATE/RULE_PROMOTION_LEDGER.tsv` remains byte-identical at `5ba4add0fb410c7b2b324f8ca962cda5ed84c90ee0edfa54e0036b66987e1221`. The Task065 and Task065R immutable handoff bytes remain unchanged (SHA-256 `954368b0dd52223eed4240b914b89556998a9dbc48f661a7ee742c861b1c2503` and `25f1ca449dd9898951ac3d5ae37222fe4b5d0bddc79f2e0639de37f862ab5d34`). The accepted State is schema/version 1.0.0 and continues to record Task064 as the last accepted task; catalog schema v13 and all prior receipts remain unchanged.

## Requirement/evidence map

1. EVIDENCED — actual compile conditions, startup order and XCTest host behavior inspected; Preview runtime redirect removed behind the compile-time Debug production boundary; Debug host isolation regression passes.
2. EVIDENCED — the actual packaged arm64 Preview launched with synthetic `CFFIXED_USER_HOME` and all three spoofed XCTest keys and resolved only its dedicated synthetic Preview catalog.
3. EVIDENCED — generated process-specific test-host symlink and sentinel were present during the packaged launch, absent from the resolution log, unchanged by hash, then safely removed by the smoke.
4. EVIDENCED — device/inode identity checks and exact negative symlink, case-alias and hardlink tests pass; the remaining local-writer check/open race is explicitly recorded.
5. EVIDENCED — Preview marker, bundle identity/banner, manifest packaging, synthetic sentinel smoke, synthetic symlink smoke, Debug test-host behavior, Release production behavior and 15 Task064 ancestor/navigation regressions pass; schema v13 and Save/Delete are unchanged.
6. EVIDENCED — clean arm64 Preview/Debug/Release builds, 147 focused tests, 15 Task064 tests, extracted bundle-tree verification and distinct-context read-only review pass.
7. EVIDENCED — no Owner catalog/media, hardware, auto capture or public release was used; accepted State, rule ledger, prior handoffs, schema v13, receipts and Save/Delete boundaries are preserved.
8. EVIDENCED — this is the one Task065S handoff, with CURRENT, one Worker ledger row/event, Desktop transport refresh, canonical PRE/POST checks and normal commit/push/fetch closure performed by the finalizer. Its self-publication SHA is intentionally resolved from Git history and the final Desktop receipt.

## Remaining boundary and return

The local same-user TOCTOU limit is the only material technical advisory. Owner manual Preview acceptance, signing/notarization, hardware observation, Owner media/catalog validation, auto capture and public release remain outside this task and were not performed. No changes were made to BRAIN-owned accepted State or prior handoffs. The proposed next action is BRAIN review/classification of this Worker evidence; no Task066 implementation was started.

## Finalizer publication note

This immutable record captures the authorized prepublication base and verified candidate. The finalizer performs the canonical precheck, publishes only the exact authorized task paths with a normal `main` commit/push/fetch, updates Desktop with the observed publication receipt, and runs the postcheck with clean/synced 0/0. The future publication SHA is not embedded self-referentially in this file.

## Worker execution guard

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=8
WORKER_REQUIREMENTS_EVIDENCED=8
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO
