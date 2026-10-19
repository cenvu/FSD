UPDATED_AT: 2026-10-19T12:49:28+07:00

# Task065 isolated FSD2 Internal Preview build — Worker return

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD2_INTERNAL_PREVIEW
HANDOFF_ID=handoffs/FSD_FSD2_ISOLATED_INTERNAL_PREVIEW_BUILD_065_D_20261019-124928.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=13dc15944349f73f443808ac3193833aa5ab5dcd
REMOTE_HEAD=13dc15944349f73f443808ac3193833aa5ab5dcd
LAST_VERIFIED_AT=2026-10-19T12:49:28+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|docs/AGENT.md|STATE/PROJECT_STATE.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-independent-review/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|FSD/Catalog/CatalogLocation.swift|FSD/App/FSDApp.swift|FSD/UI/ComparisonSharedViews.swift|FSD.xcodeproj/project.pbxproj|FSDTests/InternalPreviewIsolationTests.swift|FSDTests/InternalPreviewSmokeTests.swift|scripts/build_internal_preview.sh|scripts/internal_preview_manifest.json|handoffs/FSD_FSD2_COMPARE_ANCESTOR_REVEAL_064_D_20261019-120311.md
CURRENT_PHASE=POST_V0_1_FSD2_FOUNDATION
CURRENT_GATE=FSD2_ISOLATED_INTERNAL_PREVIEW_BUILD_065
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_FOR_SCOPED_PREVIEW;OWNER_MANUAL_DOUBLE_CLICK_ACCEPTANCE_PENDING;NO_DEVELOPER_ID_NOTARIZATION_OR_PUBLIC_RELEASE
PROPOSED_NEXT=WAIT(BRAIN_REVIEW_TASK065_ISOLATED_INTERNAL_PREVIEW_BUILD)
NO_AUTO_NEXT=YES

## Execution identity and scope

PROJECT=FSD
TASK_ID=FSD2_ISOLATED_INTERNAL_PREVIEW_BUILD_065
ROLE=WORKER
BASE_HEAD=13dc15944349f73f443808ac3193833aa5ab5dcd
UPSTREAM_HEAD=13dc15944349f73f443808ac3193833aa5ab5dcd
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=ISOLATED_DOUBLE_CLICKABLE_FSD2_INTERNAL_PREVIEW_BUILD_COMPILE_TIME_FLAVOR_SEPARATE_CATALOG_ARM64_APP_ZIP_MANIFEST_SMOKE
ALLOWED_PATHS=EIGHT_SUBSTANTIVE_PATHS_LISTED_BELOW_PLUS_ONE_HISTORY_CURRENT_WORKER_LEDGER_EVENT_DESKTOP
FORBIDDEN_PATHS=ACCEPTED_STATE_RULE_LEDGER_OLD_HISTORY_SCHEMA_RECEIPT_WRITER_SAVE_DELETE_SOURCE_CAPTURE_PROVIDER_HELPER_OWNER_DATA_HARDWARE_PUBLIC_RELEASE_TASK066
SUCCESS_CRITERIA=COMPILE_TIME_PREVIEW_ISOLATION_DEDICATED_CATALOG_NEVER_PRODUCTION_ARM64_APP_AND_ZIP_DETERMINISTIC_MANIFEST_GENERATED_FIXTURE_E2E_SMOKE_ISOLATION_TESTS_SELECTED_SUITE_CLEAN_BUILDS_REVIEW_PUBLICATION
VALIDATIONS=GENERATED_FIXTURE_XCTEST_OWN_WINDOW_CAPTURE_ARTIFACT_HASH_PREVIEW_LAUNCH_SMOKE_PRODUCTION_HASH_INVARIANT_CLEAN_ARM64_BUILDS_PROTECTED_HASHES_EXACT_CHECKER
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
WORKER_RESULT=PASS_WITH_ADVISORY

FACT: started clean main at 13dc15944349f73f443808ac3193833aa5ab5dcd. Fresh fetch
found exactly one BRAIN-only commit showing the Task064 acceptance and the Task065
authorization (STATE/PROJECT_STATE.md, STATE/TASK_LEDGER.tsv, STATE/EVENTS.jsonl only).
Read local Owner policy, Compact, accepted PROJECT_STATE/ledger/events, CURRENT,
the exact Task065 authorization and the current CatalogLocation implementation
before any mutation. Loaded task-execution, independent-review and finalizer.
No reset,stash,clean,force,rebase or Owner work overwrite.

## Delivered behavior and boundaries

The preview flavor is selected only at compile time. `CatalogLocationResolver.Flavor.buildTime`
returns `.internalPreview` only under `#if FSD_INTERNAL_PREVIEW`, and the `Preview`
build configuration in `FSD.xcodeproj/project.pbxproj` is the only configuration that
sets `SWIFT_ACTIVE_COMPILATION_CONDITIONS = FSD_INTERNAL_PREVIEW`. Debug and Release
keep `DEBUG` only, so a stray runtime flag can never move production onto the preview
catalog or the preview onto production.

In the preview flavor `resolve(...)` returns only its dedicated catalog at
`~/Library/Application Support/FSD-Internal-Preview/catalog.sqlite3` (origin
`.internalPreview`). It never consults the production path, it reports a rejected
production-looking override instead of honouring it, and when Application Support is
unavailable it throws `CatalogLocationError.internalPreviewUnavailable` rather than
falling back. The XCTest host still receives its own per-process isolated catalog in
both flavors, so automated runs never touch preview or production data. The
preview-only seam `FSD_INTERNAL_PREVIEW_TEST_ROOT` is read only after the flavor gate
and only outside a test host; it cannot be reached by the production build.

Product identity is explicit: bundle id `com.fsd.FSD-InternalPreview`, name
`FSD2InternalPreview`, display name `FSD2 Internal Preview`, window title carries the
`Internal Preview` marker, and the shell shows an `internalPreviewIndicator` banner
only in the preview flavor. A compile-time `FSDProductIdentity.flavorMarker` is
compiled in and printed once to standard error at startup so an automated probe can
confirm the flavor of the shipped binary.

Isolation of the actual shipped artifact is verified twice by
`scripts/build_internal_preview.sh`: a static grep of the staged binary for the
preview marker `FSD_PREVIEW_FLAVOR_ACTIVE` (aborting packaging if the flag is missing,
or if the production marker is present), then a bounded launch smoke with the isolated
test root asserting `source: internalPreview`, that the isolated root was honoured, that
no `/Application Support/FSD/` path was resolved, and that the production catalog hash is
byte-identical before and after. The script builds the `Preview` configuration arm64,
verifies bundle identity against `scripts/internal_preview_manifest.json`, computes a
bundle-tree digest, creates the ZIP and writes a machine-readable receipt.

No schema, completion receipt, Save/Delete body, saved format, source capture,
provider, helper, hardware observer, source-media read, auto capture, public release or
Task066 change was made. Production catalog was never opened or migrated.

## Executed validation and candidate applicability

Final candidate aggregate SHA256 (sorted path + NUL + file SHA hex + LF over the eight
substantive paths below) =
4b22935b7ac4fda9dceeb99d4383db449fc3626fd82c188b8ee75e2df96ee711

Artifact: `~/Desktop/FSD2-Internal-Preview-Task065.zip` (Desktop transport copy):
SHA256 c68ce3e8fc64ba28506b84bd6613e598ef2adef64526081fcb2f08c6d250ad90, bytes 4451080.
Bundle tree digest f8de413d1d3d8a7fa3dbb03cb65902c63b23d89ca6dfe3e8434e592c9e4db430.
Receipt `.ai-scratch/task065/package/build-receipt.json`.

- Extracted the Desktop ZIP to a fresh temp directory: recomputed bundle tree digest is
  f8de413d1d3d8a7fa3dbb03cb65902c63b23d89ca6dfe3e8434e592c9e4db430 (matches), bundled
  identity matches the manifest, resources `schema.sql`/`THIRD_PARTY_NOTICES.txt` and
  helper `FSDClassificationHostSeam` present.
- Launched the extracted copy: standard error printed
  `FSD Internal Preview catalog: /Users/cenvu/Library/Application Support/FSD-Internal-Preview/catalog.sqlite3 (source: internalPreview)`
  and `FSD flavor: FSD_PREVIEW_FLAVOR_ACTIVE`; the isolated preview catalog was created
  and then removed. Production catalog SHA256 c2f7f9ba2078c409d00d0053f44f7381103f44b56cd8edc2d8060a748cf1daa6
  was byte-identical before and after every launch.
- Packaging script self-check (in-script bounded smoke over
  `.ai-scratch/task065/package/launch-smoke-root`): marker present
  `FSD_PREVIEW_FLAVOR_ACTIVE`; smoke line confirmed isolated preview resolution;
  production catalog unchanged.

Selected XCTest (macOS, arm64, Debug) — InternalPreview isolation + smoke, comparison
semantics/identity/snapshot/mode/persistence/workspace/browser/completion-receipt/
end-to-end probe/GUI source-boundary/GUI validation, SavedComparison + migration,
SchemaMigration/SchemaSafetyCorrection, DriveSet/PhysicalDrive/CompletionReceipt
migration, SourceObservationResolver, Classification source-reader/invocation-isolation/
security-integration, SnapshotCollections/SnapshotLifecycle, CatalogDatabase:

```text
Executed 371 tests, with 0 failures (0 unexpected) in 122.085 seconds
** TEST SUCCEEDED **
```

New tests: `InternalPreviewIsolationTests` (14) + `InternalPreviewSmokeTests` (3) = 17.
The smoke exercises the real synthetic capture/explore/collections/drive-sets and
comparison save/reopen/delete journeys over generated fixtures only.

Clean builds (separate derived data, arm64):

```text
Debug   clean build: BUILD SUCCEEDED
Release clean build: BUILD SUCCEEDED
```

Production binaries carry only `FSD_PRODUCTION_FLAVOR_ACTIVE`; the Preview binary
carries `FSD_PREVIEW_FLAVOR_ACTIVE`. All configs keep `CODE_SIGNING_ALLOWED = NO`,
`ENABLE_HARDENED_RUNTIME = NO`, `ARCHS = arm64`, `MACOSX_DEPLOYMENT_TARGET = 15.0`;
no signing, notarization, release or tag change.

Measured own-window screenshots regenerated by the smoke (`.ai-scratch/task065/screenshots`,
FSD-owned window only, 1120/1330/1440):

- `shell-1120.png` SHA256 a8c873d9d095d09d1fec5fc2fc65defe27e1356f7129a2d0d06c2abf0fbbe2fe
- `shell-1330.png` SHA256 b18d42db65af9fb268e11598533f2ad0d0b8582431e43242f08fe0eb9e3534bd
- `shell-1440.png` SHA256 64278218c59859fb335d538c3ec6c76ab676f6465168ddd47a30796448e5f747

These captures are the shell rendered in the Debug XCTest host (production flavor), so
they evidence the synthetic journeys' UI dimensions, not the packaged preview identity;
preview identity is evidenced by the launch smoke above.

## Independent read-only review

A separate read-only reviewer (distinct context, no file writes) verified the base SHA,
the changed path set and the isolation code, test seam, project configuration, test
falsifiability and the packaging script. Result PASS_WITH_ADVISORY. One material
finding (F1) was reported: the packaging script verified bundle identity but had no
falsifiable check that the compiled artifact actually resolves the preview catalog, so a
missing compile-time flag would still produce a bundle that opens the production
catalog. F1 was repaired within scope by the compile-time `flavorMarker`, the static
binary-marker gate and the bounded isolated launch smoke now in the packaging script.
Advisories retained: the smoke screenshots are production-flavor UI evidence (provenance
labelled above); the preview test-root seam is honored in the built preview binary for
launch-smoke purposes; the artifact ZIP is staged to the Desktop as Owner test transport.

## Requirements-to-evidence postflight

1. EVIDENCED — Authority and baseline: clean 13dc159; sole BRAIN-only authorization commit inspected; canonical Task065 action; execution/review/finalizer loaded; no forbidden reset/clean/stash/rebase.
2. EVIDENCED — Compile-time isolation: `.internalPreview` only under `#if FSD_INTERNAL_PREVIEW`; `SWIFT_ACTIVE_COMPILATION_CONDITIONS = FSD_INTERNAL_PREVIEW` only on the Preview configuration; Debug/Release semantics unchanged.
3. EVIDENCED — Dedicated catalog only: preview resolves `~/Library/Application Support/FSD-Internal-Preview/catalog.sqlite3`; production path never consulted; override reported not honoured.
4. EVIDENCED — No fallback: unavailable Application Support throws `internalPreviewUnavailable`; asserted in tests.
5. EVIDENCED — Production unchanged: Debug/Release resolve Application Support default and report ignored overrides as before; existing suites pass.
6. EVIDENCED — Test-host isolation preserved: XCTest host still gets its own isolated catalog in both flavors.
7. EVIDENCED — Test seam gated: `FSD_INTERNAL_PREVIEW_TEST_ROOT` read only in the preview flavor and outside a test host; unreachable by production.
8. EVIDENCED — Product identity: distinct bundle id/name/display name/window title and preview-only indicator banner.
9. EVIDENCED — Artifact: arm64 `Preview` app + ZIP built, identity verified against the manifest, bundle-tree digest reproducible after ZIP extraction.
10. EVIDENCED — Deterministic manifest: `scripts/internal_preview_manifest.json` drives identity, flavor marker, required resources/helpers and artifact naming.
11. EVIDENCED — Flavor of the shipped binary proven: static marker gate plus bounded isolated launch smoke asserting preview resolution and production byte-invariance.
12. EVIDENCED — Omni-journey smoke: capture/explore/collections/drive-sets and comparison save/reopen/delete over generated fixtures; own-window screenshots at 1120/1330/1440.
13. EVIDENCED — Isolation acceptance tests: 14 `InternalPreviewIsolationTests` incl. lock independence/relaunch persistence/v12->v13 migration/failed-migration rollback.
14. EVIDENCED — Selected suite: 371/371 with 0 failures, 0 unexpected.
15. EVIDENCED — Clean builds: clean arm64 Debug and Release `BUILD SUCCEEDED`.
16. EVIDENCED — No forbidden access: no hardware observer, source-media, Owner data, auto capture, public release or Task066.
17. EVIDENCED — Independent read-only review: PASS_WITH_ADVISORY; material F1 repaired; advisories recorded.
18. EVIDENCED — Immutable data preserved: accepted PROJECT_STATE, rule ledger, prior histories, schema/receipt/Save/Delete/provider/helper unchanged.
19. EVIDENCED — Canonical finalization: one flat history, CURRENT full mirror, one Worker ledger row, one append-only Worker event, Desktop transport refresh, exact checker.

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=19
WORKER_REQUIREMENTS_EVIDENCED=19
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

## Exact substantive scope and preservation

- `FSD/Catalog/CatalogLocation.swift` SHA256 `8ad821443de3dac2807ebf1315c4143eaeca9b3d222d22f2dd71a5e0247ab7ff`
- `FSD/App/FSDApp.swift` SHA256 `f0a0c7997a7aeeba4a928d3733365326eb6605ecf725bc06efa11deb9de579d5`
- `FSD/UI/ComparisonSharedViews.swift` SHA256 `16f75c4ea66709c236c3e94c6dd89c30b7e7cae00c354c532f2ae67b4d8fe5c5`
- `FSD.xcodeproj/project.pbxproj` SHA256 `7074bca7daee98104ac8abc9aa757154a37ebfdced5692cb627960f756e65c19`
- `FSDTests/InternalPreviewIsolationTests.swift` SHA256 `fe3de73f9941acb694f2071142969dcd2dd34894f81c749240cc03865b04785c`
- `FSDTests/InternalPreviewSmokeTests.swift` SHA256 `90ad64912635eedbcb1f11c48e119d97046f5c7d79502edced3d36172b7b40a5`
- `scripts/build_internal_preview.sh` SHA256 `74ec0547f9965f8dcfc42e3549fe0bb37e69e6f1922c290e54402a6333523fa0`
- `scripts/internal_preview_manifest.json` SHA256 `a87a9affbf725c9a8811a798af197fcebc15d47637c60adee2aff768e7b19b90`

Reporting only adds this one history, the CURRENT full mirror, one Worker ledger row and
one append-only Worker event; the Desktop packet is transport. TECHNICAL_SHA is the
captured prepublication basis; publication resolves from the handoff Git history. The
packaged artifact, screenshots and receipt live under ignored `.ai-scratch/task065/` and
on the Desktop; they are not repository authority.

## Publication closure boundary

This immutable technical record uses the actual prepublication HEAD/time. Its future
publication SHA cannot be embedded self-referentially. The finalizer runs the exact
canonical precheck, normal commit/push/fetch, postcheck with clean+synced 0/0,
protected-byte/history verification and Desktop/CURRENT/Operator parity. Worker return
is evidence for BRAIN review, not acceptance. Stop after Task065; no Task066.
