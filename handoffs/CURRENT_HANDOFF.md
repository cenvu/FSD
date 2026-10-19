UPDATED_AT: 2026-10-19T13:45:35+07:00

# Task065R Internal Preview catalog-isolation repair — Worker return

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD2_INTERNAL_PREVIEW
HANDOFF_ID=handoffs/FSD_FSD2_INTERNAL_PREVIEW_ISOLATION_REPAIR_065R_D_20261019-134535.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=9f77d5068faa8237504adc131c1d68846a8f5817
REMOTE_HEAD=9f77d5068faa8237504adc131c1d68846a8f5817
LAST_VERIFIED_AT=2026-10-19T13:45:35+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|docs/AGENT.md|STATE/PROJECT_STATE.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-independent-review/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|FSD/Catalog/CatalogLocation.swift|FSD/App/FSDApp.swift|FSD.xcodeproj/project.pbxproj|FSDTests/InternalPreviewIsolationTests.swift|FSDTests/InternalPreviewSmokeTests.swift|scripts/build_internal_preview.sh|scripts/internal_preview_manifest.json|handoffs/FSD_FSD2_ISOLATED_INTERNAL_PREVIEW_BUILD_065_D_20261019-124928.md
CURRENT_PHASE=POST_V0_1_FSD2_FOUNDATION
CURRENT_GATE=FSD2_INTERNAL_PREVIEW_ISOLATION_REPAIR_065R
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_FOR_SCOPED_REPAIR;OWNER_MANUAL_DOUBLE_CLICK_ACCEPTANCE_PENDING;NO_DEVELOPER_ID_NOTARIZATION_OR_PUBLIC_RELEASE
PROPOSED_NEXT=WAIT(BRAIN_REVIEW_TASK065R_INTERNAL_PREVIEW_ISOLATION_REPAIR)
NO_AUTO_NEXT=YES

## Execution identity and scope

PROJECT=FSD
TASK_ID=FSD2_INTERNAL_PREVIEW_ISOLATION_REPAIR_065R
ROLE=WORKER
BASE_HEAD=9f77d5068faa8237504adc131c1d68846a8f5817
UPSTREAM_HEAD=9f77d5068faa8237504adc131c1d68846a8f5817
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=CATALOG_RESOLVER_PREVIEW_ISOLATION_REPAIR;PREVIEW_PACKAGING_SYNTHETIC_ONLY;FOCUSED_NEGATIVE_TESTS;MINIMAL_BUILD_CONFIGURATION;NORMAL_REPORTING
ALLOWED_PATHS=FSD/Catalog/CatalogLocation.swift|FSDTests/InternalPreviewIsolationTests.swift|scripts/build_internal_preview.sh|scripts/internal_preview_manifest.json|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|handoffs/CURRENT_HANDOFF.md|handoffs/FSD_FSD2_INTERNAL_PREVIEW_ISOLATION_REPAIR_065R_D_20261019-134535.md
FORBIDDEN_PATHS=OWNER_CATALOG_OR_MEDIA;HARDWARE_OBSERVER;SCHEMA;COMPLETION_RECEIPT;SAVE_DELETE;SOURCE_CAPTURE;PROVIDER_HELPER;SNAPSHOT_IMMUTABILITY;PUBLIC_RELEASE;TASK066;BRAIN_OWNED_PROJECT_STATE_AND_CLASSIFICATION
SUCCESS_CRITERIA=NO_RUNTIME_ENV_ARG_TEST_SEAM_OR_SYMLINK_REDIRECTS_SHIPPED_PREVIEW_TO_PRODUCTION;FAIL_CLOSED;PACKAGING_READS_NO_OWNER_CATALOG;SYNTHETIC_SENTINEL_INVARIANCE;NEGATIVE_REGRESSION_TESTS;CLEAN_ARM64_PREVIEW_DEBUG_RELEASE;SELECTED_TESTS;REPRODUCIBLE_BUNDLE;INDEPENDENT_REVIEW;IMMUTABLE_HISTORY
WORKER_RESULT=PASS_WITH_ADVISORY

FACT: started clean main at 9f77d5068faa8237504adc131c1d68846a8f5817;
`git fetch origin --prune` reported origin/main equal, ahead/behind 0/0. This task is a
bounded safety correction of the already-published Task065 preview under the direct
Owner/BRAIN task prompt; `STATE/PROJECT_STATE.md` (BRAIN-owned) still records Task065 as
the pending gate and was deliberately NOT modified. No BRAIN acceptance or next decision
was authored. Local Owner policy, Compact, accepted STATE, ledger/events, CURRENT and the
task-execution/independent-review/finalizer skills were read before mutation.

## Original BRAIN STOP and separate repair response

The published Task065 Worker return was `PASS_WITH_ADVISORY`, and this return is not a
rewrite of it. BRAIN review of Task065 returned `STOP_MATERIAL_PREVIEW_CATALOG_ISOLATION_GAP`.

- FINDING_A (STOP, material): `CatalogLocationResolver.resolve()` accepted
  `FSD_INTERNAL_PREVIEW_TEST_ROOT` inside the compiled Preview app, so the distributed
  binary could be pointed at an arbitrary directory — including the production
  `~/Library/Application Support/FSD` catalog — defeating the required never-production
  isolation.
- FINDING_B (material): `scripts/build_internal_preview.sh` hashed the real Owner
  production catalog and checked only the main SQLite file, not WAL-state invariance.

Repair evidence (separate from the original STOP):

- `FSD/Catalog/CatalogLocation.swift`: the `FSD_INTERNAL_PREVIEW_TEST_ROOT` seam was
  removed entirely (no constant, no branch, no string in the shipped preview binary). The
  preview branch now derives its URL only from `internalPreviewURL(...)` and reports any
  launch-argument/`FSD_CATALOG_PATH` request as rejected. `internalPreviewURL(...)`
  fails closed with `CatalogLocationError.internalPreviewConflictsWithProduction` when the
  symlink-resolved preview directory or catalog file aliases the production location.
- `scripts/build_internal_preview.sh`: every real Owner catalog read/hash was removed. The
  smokes run on a generated synthetic home (`CFFIXED_USER_HOME`) with a synthetic
  production sentinel + decoy; the smoke asserts the resolved path, sentinel byte
  invariance and override rejection, and a second smoke asserts the symlinked preview
  fails closed with the production-conflict error.

## Delivered behavior and boundaries

The flavor remains compile-time only: `Flavor.buildTime` returns `.internalPreview` only
under `#if FSD_INTERNAL_PREVIEW`, and the `Preview` build configuration is the only one
that sets `SWIFT_ACTIVE_COMPILATION_CONDITIONS = FSD_INTERNAL_PREVIEW`. In the preview
flavor `resolve(...)` has no runtime catalog override path at all: it ignores
`-FSDCatalogPath` and `FSD_CATALOG_PATH` (reporting them ignored), and the removed test
root variable is inert. It returns only
`~/Library/Application Support/FSD-Internal-Preview/catalog.sqlite3`, and when Application
Support is unavailable it throws instead of falling back. The XCTest host still receives
its own per-process temporary catalog.

The symlink guard resolves symbolic links on the preview directory and file and rejects
the location if it equals the production directory or file. This is a generated-fixture
verified fail-closed boundary, not policy machinery. Hardlink, case-insensitive-alias and
check/open TOCTOU aliases are not closed by a path-string comparison; they require local
write access to the user's own Application Support and are recorded as a residual
limitation, not a claim of completeness.

Packaged artifact flavor is verified twice: a static grep of the staged binary for
`FSD_PREVIEW_FLAVOR_ACTIVE` (failing if absent or if the production marker is present),
and behavioral launch smokes that assert the resolved isolated catalog and production
sentinel invariance rather than a log marker alone. `scripts/internal_preview_manifest.json`
gains `repair_task` and artifact name `FSD2-Internal-Preview-Task065R.zip`; identity,
required resources/helpers and flavor marker pass through unchanged.

## Executed validation and candidate applicability

Substantive changed-path SHA256 (working-tree content):

- `FSD/Catalog/CatalogLocation.swift` `f128a2ab6dc6bfe10e7f6a607381f4ca5d0a09a107a78afb77daead1e39290cc`
- `FSDTests/InternalPreviewIsolationTests.swift` `ce2932f3db3b29329bbd4caf89b904e3b50c1f7de8b6066ed682ef7d231d2e05`
- `scripts/build_internal_preview.sh` `c2339d0e03ae9bfec8c37728af5d998dc945f4201822d1efbacf95dead2a89cf`
- `scripts/internal_preview_manifest.json` `9d4b777d374697ae8148c324caff5046bfe7506e359bf35eff92ced3c4168acb`

Packaging (`.ai-scratch/task065r/package/build-receipt.json`):

- artifact `FSD2-Internal-Preview-Task065R.zip` SHA256
  `3daa4c1dc32cf2bbed8bd4191aa2348b6e6f55e6f7ce83e6e1e0265a3777967f`, bytes 4451704
- bundle tree SHA256 `fcf8ddbacbf24cdbce66455c5b69cd1dd22e72c32fb1e70cd4b07d62b8e6a594`,
  identical in three clean Preview builds and after re-extracting the ZIP
- launch smoke resolved
  `<synthetic-home>/Library/Application Support/FSD-Internal-Preview/catalog.sqlite3`
  (`source: internalPreview`), reported the decoy override ignored, and left the synthetic
  production sentinel byte-identical (`59fe0e3f7d9ef121028f1ff72f18965bf9d2073fb2a45f625356876fab444fde`)
- symlink smoke: preview refused to start with the production-conflict error
- no owner catalog was read, hashed, stat-ed or opened; all paths under `.ai-scratch/task065r/`

Selected XCTest (macOS, arm64, Debug) covering Task064's comparison set plus catalog,
schema/receipt, Save/Delete, classification, snapshot and the new preview tests:

```text
Executed 672 tests, with 0 failures (0 unexpected) in 328.6 seconds
** TEST SUCCEEDED **
```

New/updated tests: `InternalPreviewIsolationTests` now 18 tests (was 14), including
removed-test-root inertness, all runtime override channels rejected, directory-symlink and
file-symlink fail-closed, no production fallback, and compiled flavor identity;
`InternalPreviewSmokeTests` 3 tests unchanged and passing.

Clean arm64 builds (separate derived data):

```text
Preview (packaging clean build): BUILD SUCCEEDED
Debug   clean build:             BUILD SUCCEEDED
Release clean build:             BUILD SUCCEEDED
```

Binary flavor markers: staged `FSD2InternalPreview` carries only
`FSD_PREVIEW_FLAVOR_ACTIVE`; Debug (`FSD.debug.dylib`) and Release `FSD` carry only
`FSD_PRODUCTION_FLAVOR_ACTIVE`. All configs keep `CODE_SIGNING_ALLOWED = NO`,
`ENABLE_HARDENED_RUNTIME = NO`, `ARCHS = arm64`, `MACOSX_DEPLOYMENT_TARGET = 15.0`.

## Independent read-only review

A separate read-only reviewer (distinct context, no file writes, no `xcodebuild`, no owner
catalog access) examined the uncommitted diff against 9f77d50, the changed files, the
receipt smokes and the selected test log. Result PASS_WITH_ADVISORY: findings A and B
verified closed; production branch/first-order semantics verified unchanged; selected
672/672 and clean Debug/Release verified. Advisories: the symlink smoke initially accepted
any startup failure (tightened to require the production-conflict message); the symlink
guard is a path-string comparison so hardlink/case-alias/TOCTOU aliases are out of the
accidental-operator model (recorded as a residual limitation); and two new tests are
invariants that also held on 9f77d50, not repair-regression proofs.

## Requirements-to-evidence postflight

1. EVIDENCED — Authority/baseline: clean 9f77d50, upstream 0/0, direct repair authorization, owner dirty preserved, no reset/clean/stash/rebase.
2. EVIDENCED — Pre-change research: resolver, packaging script, tests and `CFFIXED_USER_HOME` Foundation behavior inspected/measured before editing.
3. EVIDENCED — FINDING_A repair: `FSD_INTERNAL_PREVIEW_TEST_ROOT` seam removed; absent from resolver, tests and shipped binary strings.
4. EVIDENCED — No runtime redirect: preview ignores launch argument and `FSD_CATALOG_PATH`; compile-time flavor gate retained.
5. EVIDENCED — Fail-closed symlink boundary: preview directory/file aliasing production throws `internalPreviewConflictsWithProduction`.
6. EVIDENCED — No production fallback: unavailable Application Support throws `internalPreviewUnavailable`.
7. EVIDENCED — FINDING_B repair: packaging reads/hashes/stats no real owner FSD or preview catalog.
8. EVIDENCED — Synthetic invariance: synthetic home/sentinel/decoy; resolved-path, sentinel-invariance and override-rejection assertions.
9. EVIDENCED — Packaged flavor verification: static marker gate plus behavioral launch smokes (not marker-only).
10. EVIDENCED — Negative tests: removed seam inert, runtime overrides rejected, dir/file symlink fail-closed, no fallback, compiled flavor identity.
11. EVIDENCED — Normal preview resolution correct: dedicated `FSD-Internal-Preview` directory and `catalog.sqlite3` asserted.
12. EVIDENCED — Build-flavor identity enforced: `FSD_INTERNAL_PREVIEW` only on Preview; markers verified per binary.
13. EVIDENCED — Production semantics preserved: `productionDirectoryName` refactor behavior-identical; Debug/Release resolve Application Support.
14. EVIDENCED — Preview identity/banner preserved: bundle id/name/display name/window title/indicator unchanged.
15. EVIDENCED — Schema v13/receipt/Save/Delete untouched; migration/receipt/Save suites pass in selected run.
16. EVIDENCED — Source read-only, providers, immutable snapshots, classification untouched; selected suites pass.
17. EVIDENCED — Prior Task064 comparison/ancestor behavior untouched; ancestor tests pass.
18. EVIDENCED — Clean arm64 Preview/Debug/Release builds all `BUILD SUCCEEDED`.
19. EVIDENCED — Tests: 18 isolation + 3 smoke; selected 672/672, 0 failures, 0 unexpected.
20. EVIDENCED — Reproducible bundle digest across three builds and ZIP extraction; artifact SHA and receipt recorded.
21. EVIDENCED — Independent read-only review PASS_WITH_ADVISORY; advisories recorded and one tightened.
22. EVIDENCED — History/State preserved: Task065 handoff and history untouched, PROJECT_STATE unchanged, one history + ledger row + event; no Task066 or forbidden access.

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=22
WORKER_REQUIREMENTS_EVIDENCED=22
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

## Exact substantive scope and preservation

Reporting adds only this one history, the CURRENT full mirror, one Worker ledger row and
one append-only Worker event; the Desktop packet is transport. The published Task065
handoff bytes, BRAIN-owned `STATE/PROJECT_STATE.md` and all prior ledger/event rows are
byte-preserved. TECHNICAL_SHA is the captured prepublication implementation basis
(`9f77d50`); publication resolves from the immutable handoff Git history. The packaged
artifact, smokes and receipt live under ignored `.ai-scratch/task065r/`; they are not
repository authority.

## Residual limitations

- The symlink guard compares symlink-resolved path strings; a hardlink, a
  case-insensitive-filesystem alias, or a check/open race can still alias the production
  inode and requires local write access to the user's own Application Support. Documented,
  not claimed closed.
- The ZIP container hash is not byte-reproducible across runs (archive timestamps); the
  bundle-tree digest is reproducible and is the artifact equivalence measure.
- Owner manual double-click of the packaged Preview, Developer ID/notarization and public
  release remain out of scope and unperformed.

## Publication closure boundary

This immutable technical record uses the actual prepublication HEAD/time. Its future
publication SHA cannot be embedded self-referentially. The finalizer runs the exact
canonical precheck, normal commit/push/fetch, postcheck with clean+synced 0/0,
protected-byte/history verification and Desktop/CURRENT/Operator parity. Worker return is
evidence for BRAIN review, not acceptance. Stop after Task065R; no Task066.
