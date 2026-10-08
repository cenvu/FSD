# Task040A — recovered unsigned v0.1.0 public-test candidate

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_V0_1_PUBLIC_RELEASE_PREP_RECOVERY_040A_D_20261008-153339.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=b1a11e2cc779867e43a739529a53667f7311b751
REMOTE_HEAD=b1a11e2cc779867e43a739529a53667f7311b751
LAST_VERIFIED_AT=2026-10-08T15:33:39+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|STATE/PROJECT_STATE.md|docs/PRODUCT_STATE.md|docs/TEST_PLAN.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=V0_1_PUBLIC_RELEASE_READINESS_AUDIT
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_FOR_CANDIDATE_PREPARATION;PUBLIC_EFFECTS_WAIT_INDEPENDENT_AUDIT_AND_BRAIN
PROPOSED_NEXT=FSD_V0_1_PUBLIC_RELEASE_AUDIT_041
NO_AUTO_NEXT=YES

## Task lock and technical result

TASK_ID=FSD_V0_1_PUBLIC_RELEASE_PREP_RECOVERY_040A
ROLE=WORKER
MODE=PROVENANCE_GATED_DIRTY_WORKTREE_RECOVERY_AND_RELEASE_PREPARATION
BASE_HEAD=b1a11e2cc779867e43a739529a53667f7311b751
UPSTREAM_HEAD=b1a11e2cc779867e43a739529a53667f7311b751
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=FAILED040_PROVENANCE_AND_QUARANTINE;VERSION_DOCS_UNSIGNED_CANDIDATE_VALIDATION;PRIVATE_PUBLICATION_FINALIZER
ALLOWED_PATHS=FSD.xcodeproj/project.pbxproj|README.md|docs/releases/v0.1.0.md|docs/images/v0.1.0/library-overview.png|docs/images/v0.1.0/capture.png|docs/images/v0.1.0/compare.png|docs/images/v0.1.0/history.png|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|handoffs/CURRENT_HANDOFF.md|handoffs/FSD_V0_1_PUBLIC_RELEASE_PREP_RECOVERY_040A_D_20261008-153339.md
FORBIDDEN_PATHS=RUNTIME_SOURCE|SCHEMA|CATALOG|SCANNER|DIFF|HELPER|TESTS|DEPENDENCIES|PUBLISHED_HISTORY|UNKNOWN_OWNER_MATERIAL|PUBLIC_VISIBILITY_TAG_RELEASE
SUCCESS_CRITERIA=ACCOUNTED_DIRTY;FAILED040_EXACT_PRESERVATION;VERSION_HELPER_RESOURCES_EXACT;BILINGUAL_DOCS_APPROVED_IMAGES;PUBLIC_SECRET_SCAN;CLEAN_BUILDS_FULL_TESTS;ZIP_ROUNDTRIP_GUI;PRIVATE_CLOSURE
VALIDATIONS=NATIVE_GIT;INSTALLED_GITLEAKS;XCODEBUILD;XCRESULTTOOL;PLIST_LIPO_OTOOL;DITTO;SHA256;ISOLATED_RELEASE_AX_GUI;CANONICAL_CHECKER
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
RESULT=PASS_WITH_ADVISORY
VERSION=0.1.0
BUILD=1
BUILDS=DEBUG_CLEAN_ARM64_PASS;RELEASE_CLEAN_ARM64_PASS
TESTS=494_EXECUTED;491_PASSED;0_FAILED;3_KNOWN_ENVIRONMENT_SKIPS
ARTIFACT=/Users/cenvu/DEV/FSD/.ai-scratch/release-v0.1.0/FSD-v0.1.0-macOS15-arm64.zip
ARTIFACT_BYTES=3542111
ARTIFACT_SHA256=6c840c66ca2677e849e64dc0802890ae8aa60d2901db7ed9d9c863884ee16134
HELPER_SHA256=665a6569ee60614313e50629c4166358b89859f15dac4c522905ee5a730752e7
SECRET_SCAN=PASS
README_PRESENT=YES
README=BILINGUAL
SCREENSHOTS=4
REPO_VISIBILITY=PRIVATE
TAG_CREATED=NO
RELEASE_CREATED=NO
RELEASE_CANDIDATE_SHA=RESOLVE_PRIVATE_PUBLICATION_FROM_THIS_HANDOFF_PATH;PREPUBLICATION_RECORD_HAS_NO_FUTURE_SELF_SHA

## Recovery provenance — FACT

Fresh physical main HEAD/upstream equal captured base, ahead0/behind0, canonical origin https://github.com/cenvu/FSD.git. Dirty is explicitly authorized for recovery. Exact initial porcelain, unstaged binary diff, empty staged diff, ignored file inventory and hashes: `.ai-scratch/task040a/inventory.json` (SHA256 `ed659bae69a1c39da688ee96c8d5d26a9ebd0f43440c409251d809cf98299cce`). Eleven dirty paths were individually classified: seven 040_PRODUCT_OR_DOC_CANDIDATE, four 040_REPORTING_CANDIDATE; zero OWNER_OR_UNRELATED/UNKNOWN dirty paths. The product candidates matched each exact digest in immutable failed040. Exclusive reporting provenance is one appended task040 ledger row, one appended worker_return, exact CURRENT mirror and the one unpublished task040 historical record. Filenames/mtime alone were not ownership evidence.

The failed original preflight/STOP and every reporting artifact were copied byte-for-byte before canonical mutation to `.ai-scratch/task040a/failed-040/`, retaining relative paths. Manifest digest `0daa8cea4c0c9f710d57e5bd50ccda0336324abde79557a476cea205837f9810`. Original historical SHA remains `ab5658652314a7f4c062a44afd748b292e2413d348b5a8ddecbd500b113d5e9e`; its only canonical copy was unpublished, proven absent from base/upstream, and is quarantined there without editing a byte. Exact copied reporting identities:

- `STATE/TASK_LEDGER.tsv`: `fa1a98b785ec4a417ce353a85e1dd96b24bd10b958beae2aa17dcf349d4a4069`.
- `STATE/EVENTS.jsonl`: `7e18f6f4130fa2216985bf9932f2b8dae84b1bc44edee84e488e7df37dd370d8`.
- `handoffs/CURRENT_HANDOFF.md`: `08fdc307b1998eacfa0b4ff50ec2318790f759fc3f62ef403c5102cdb9056930`.
- `handoffs/FSD_V0_1_PUBLIC_RELEASE_PREP_040_D_20261008-104728.md`: `ab5658652314a7f4c062a44afd748b292e2413d348b5a8ddecbd500b113d5e9e`.
- `STATE/PROJECT_STATE.md`: `1481d1e5ea64e14365fcea0d8c93f1c227ed3140bd07b55c2f47adb259db2b9b`.

Only failed040 reporting was removed from publication surfaces after verified copies: ledger/events/CURRENT restored with exact `git show <base>:<path>` bytes; the unpublished history path removed after copy confirmation. No canonical040 row/event/publication is fabricated. All 92 published historical handoffs remain byte-identical. Product inputs additionally preserved in `.ai-scratch/task040a/product-before/`. Prior ZIP/checksum/artifact receipt copied to `failed-040/ignored-release-artifact/` after matching its recorded artifact hash, before replacing the designated release ZIP. All other ignored material remains untouched. Existing task040 build/test/secret/ZIP receipts were not used as fresh040A proof. No reset/clean/stash/rebase/force-push or published-history rewrite.

## Product/documentation delta — FACT

Retained and individually audited existing version settings: Debug/Release app MARKETING_VERSION0.1.0/CURRENT_PROJECT_VERSION1 only. Bundle identifier com.fsd.FSD, deployment15.0, arm64 and CODE_SIGNING_ALLOWED=NO preserved. No runtime, classification, schema, scanner, catalog or diff mutation.

README has all17 requested bilingual sections, four exact approved production task039 images, requirements, manual capture/offline history/bounded snapshot search, persistent snapshot comparison and temporary live-side lifecycle, snapshot-only JSON, explicit one-file <=4096-byte Detected File Type, content-not-verified and privacy. All Drives/Connected Now/Drive Sets/Auto Capture/global Search are explicitly unavailable. No HTML, hashing/content proof, cloud/multi-Library, strong physical identity or universal classifier claim. Source visibility grants no FSD OSS license; no LICENSE added. Exact shipped filetype MIT, Go license/patents and Sun notices retained and referenced; filesystem-reader research is clearly separate from shipped inventory.

Release notes are bilingual authoritative body source; fresh ZIP checksum/size replace the old unvalidated040 values. Release-commit receipt field remains a deliberate publication placeholder with a deterministic Git lookup, because this immutable commit cannot contain its own future SHA. Full actual publication SHA belongs in Desktop/final receipt and can be resolved from this handoff. Public-facing notes omit internal task/BRAIN instructions. Installation uses ZIP/unzip/Applications/normal open, per-app Open/Open Anyway. UNSIGNED/NOT NOTARIZED/FIRST PUBLIC TEST and native system-gray titlebar disclosed; no global Gatekeeper-disable instruction.

All four source PNG hashes match immutable039 and public copies, distinct, unchanged. Container parsing shows only numeric EXIF dimension/pointer tags34665/40962/40963 and ICC color profile; no text/GPS/author/timestamp metadata. Approved screenshots were visually reviewed and retain unavailable-feature truth/local example catalog, not bundled data. Receipts: `screenshots.json`, `doc-hygiene.json` under current scratch.

Final product/documentation identities:

- `FSD.xcodeproj/project.pbxproj`: `035effd5a4ed4467562a3094402b2e1f14051915be1a1522d0312efd336a2eca`.
- `README.md`: `315bfe86e05ebc78d55523e73f3712112788f12313cf6c57be4d3ac735814d8a`.
- `docs/releases/v0.1.0.md`: `2889523c5d2ec145c1e7829d3997dca7ed05046e8bafed588e33dcf21400dcbc`.
- `docs/images/v0.1.0/library-overview.png`: `25cbc92662237d71d809ab6907e1d815a8f7751374aa4888e8bbddb95489ab8d`.
- `docs/images/v0.1.0/capture.png`: `ac88c523ab900512d4198b1ddb5a96a6b86b785d9498e740ad65e165630dde42`.
- `docs/images/v0.1.0/compare.png`: `e1c3409b65c381edc4b01fd21e57fa6b8d94b50eb84d6ebe2ce1baace31810f4`.
- `docs/images/v0.1.0/history.png`: `3f7ac727b0e79c9afc8336445bf8bf9e4422900f8377b8c82295a4c7494acfa7`.

## Pre-public security audit — FACT, bounded scope

Installed gitleaks8.30.1 read-only, no installs/config mutation: `gitleaks git --log-opts=--all --redact --ignore-gitleaks-allow` examined historical diffs (142 nonmerge commits) with no leaks; complete1492 tracked plus six new public asset paths directory scan likewise zero. Native Git read all five available refs,143 unique commits,2325 reachable objects,1653 blobs totaling32,588,203 bytes; filenames and commit metadata separately inspected. Remote has only main and no tags; all accessible historical exposure was covered, including the two local retained benchmark refs. Native patterns cover private-key headers, GitHub/OpenAI/AWS/Slack tokens, bearer authorization/client-secret/API-key/access-token/password spellings.306 broad matches are benign disk/task/risk prose suffixes, Asia timezone and third-party option parsers; two strong matches are `disk-image-before-physical-device` prose, not keys. Suspicious names are AUTHORS or authority governance docs. No real credential/private key/token/password was found. Benign historical development paths are Owner-authorized exposure. Current closure files are scanned again during finalizer before commit; actual scan receipt follows in Desktop. Coverage does not imply mathematical proof against arbitrarily hidden secrets.

Receipts: `native-secret-scan.json`, `commit-metadata-scan.json`, `secret-review.json`, `gitleaks-history.json/.log`, `gitleaks-tree-complete.json/.log` under `.ai-scratch/task040a/`. Full historical scan outputs redact values; the native receipt stores locations/pattern IDs only.

## Fresh build/test evidence — FACT

Xcode26.3/17C529, native arm64; new isolated DerivedData for each. Commands (repository root):

```sh
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath .ai-scratch/task040a/debug-derived clean build
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Release -destination 'platform=macOS,arch=arm64' -derivedDataPath .ai-scratch/task040a/release-derived clean build
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath .ai-scratch/task040a/test-derived -resultBundlePath .ai-scratch/task040a/full-tests.xcresult test
```

Both clean builds exit0/BUILD SUCCEEDED; full XCTest exit0/TEST SUCCEEDED and xcresult Passed, 494 executed/491 passed/0 failed/3 skipped. Log and xcresult counts reconciled. Exactly three skips individually match canonical contracts: FilesystemMatrixTests/testCaptureExternallyPreparedMountedFilesystem (FSD_MATRIX_SOURCE unset), FilesystemMatrixTests/testReopenCapturedSnapshotWithTheSourceDetached (FSD_MATRIX_OFFLINE_CATALOG unset), FSDProbeSeedTests/testSeedIsolatedProbeCatalog (FSD_PROBE_CATALOG unset and /tmp marker absent). No fixture/marker prepared to force a skip. Full suite includes all14 task039 focused boundary suites: 179 total/178 passed/0 failed/1 skipped; UI/runtime isolation is covered without redundant rerun. Detail counts in `test-counts.json`, full `test-summary.json`, full-tests.log/.xcresult. Source safety and million-entry tests use isolated fixtures; no destructive source-media test or manual physical-drive acceptance is claimed.

## Bundle, signing, packaging and launch — FACT

Release physically verified plist0.1.0/build1/CFBundleDisplayName FishSock Differ/com.fsd.FSD/minimum15.0; main thin arm64 with LC_BUILD_VERSION minos15.0. Accepted helper at Contents/Helpers/FSDClassificationHostSeam remains exact SHA above (helper minos13.0 is compatible with app floor15.0). Exact bundled THIRD_PARTY_NOTICES and schema.sql match source. File-only tree (six files):

```text
Contents/Info.plist
Contents/PkgInfo
Contents/MacOS/FSD
Contents/Helpers/FSDClassificationHostSeam
Contents/Resources/THIRD_PARTY_NOTICES.txt
Contents/Resources/schema.sql
```

No XCTest, scratch/log/database/catalog/private file included. No codesign mutation/helper rebuild; Apple Silicon main contains intrinsic linker ad-hoc signature, not Developer ID signing or notarization. `spctl --assess` returned accepted/override=security disabled on this already-configured machine, exit0. No Gatekeeper setting changed; this is not per-user quarantine/Gatekeeper acceptance proof and does not alter UNSIGNED/NOT NOTARIZED boundary.

`ditto -c -k --sequesterRsrc --keepParent` packages fresh Release exactly as built; `.ai-scratch/release-v0.1.0/FSD-v0.1.0-macOS15-arm64.zip` is 3,542,111 bytes, SHA256 `6c840c66ca2677e849e64dc0802890ae8aa60d2901db7ed9d9c863884ee16134`; root SHA256SUMS.txt contains it. Fresh empty `task040a/roundtrip/` extraction with ditto re-verifies plist, architecture/deployment/helper/notices/schema and all six per-file hashes identical to original.

Extracted Release app launched as a normal app in CFFIXED_USER_HOME isolated applicationSupport context (no DEBUG override/XCTest injection/source selected). All four routes Overview/Capture/History/Compare observed via Accessibility and captured screenshots; every route counts snapshots0/comparisons0/entry_classifications0, zero child process. Normal terminate exit0; no crash. First standalone launch lacked persistent command context; first live probe had empty AX readiness and failed observation. Diagnostic proved trust=true and window/finished launch; one bounded readiness repair succeeded on a new empty context. No product change or blind repeated repair. Receipts bundle-release.json/bundle-roundtrip.json/roundtrip-runtime.json/ui-*.txt/roundtrip-*.png/ax-live-readiness.txt under task040a; manual VoiceOver/physical-media acceptance remains deferred.

## Exact source attribution and preserved boundaries — FACT

All41 release-relevant build-input files are SHA256 recorded before clean builds in `build-inputs.json`, digest `1f5d6a4c3fe238bdad466de824be8a057d97415fb2c0034f27c4979b0951ce74`. They remained identical after tests/ZIP/GUI and are checked against the eventual published commit before final return. Documentation/closure receipt changes after build are not app inputs; Xcode resources are only schema/notices plus exact helper. No undocumented source difference; no rebuild needed when only checksum prose/closure changes. ZIP identity remains fixed and is attributable to the private candidate publication resolved from this handoff.

## Owner/BRAIN projection and advisories

BRAIN accepts STOP040 as correct preservation, not release readiness. Owner accepted039 visuals YES, authorized later PUBLIC source visibility, version0.1.0/build1/title/tag; public effects are prohibited in040A. Task040A remains PENDING_BRAIN. Canonical checker line251 requires PROJECT_STATE byte identity; Owner/BRAIN explicitly replied during040A: “Giữ STATE nguyên byte; project trong handoff/Desktop, BRAIN cập nhật sau”. This supersedes section14's direct state projection only. Accepted12-key state/hash `1481d1e5ea64e14365fcea0d8c93f1c227ed3140bd07b55c2f47adb259db2b9b` and prior BRAIN classifications remain untouched. Proposed BRAIN-only state delta: visual acceptance YES in prose; public-release visibility authorized but unexecuted; v0.1.0 candidate prepared; CURRENT_GATE=V0_1_PUBLIC_RELEASE_READINESS_AUDIT; BLOCKERS=NONE_FOR_PREPARATION; exactly one next ACTION(FSD_V0_1_PUBLIC_RELEASE_AUDIT_041). Last accepted task/head remain039/8606a114930fc366cbf6def1e72e3f7d25e2d305; no Worker acceptance of040A.

Advisories: intentional unsigned/not notarized first test; native gray titlebar; Gatekeeper security-disabled host cannot prove download quarantine approval; manual VoiceOver/physical drive deferred. A too-broad read-only process listing briefly exposed unrelated local IDE session-token command arguments in tool output; acknowledged to Owner, not repeated/persisted in release docs/Git/public artifact. This is tooling-process privacy footprint, not a committed-secret finding. No network disclosure/public assets/announcement/tag/visibility operation; only authorized private main push is permitted after finalizer checks.

## Requirement/evidence map — execution postflight

Sixteen material preparation checks are EVIDENCED: physical anchor/accounted dirty; failed040 byte preservation/quarantine; permitted source delta; version/build; bilingual full truthful README; four approved/privacy-reviewed images; bilingual release notes/license/install; complete accessible-history secret scan; fresh Debug/Release; full XCTest/known skips/focused isolation; exact helper/signing boundary; bundle resources/tree; ZIP/checksum/roundtrip; extracted GUI/routes/no auto actions; build-input source identity; accepted-state preservation/current Owner projection/no public effect. References above bind each to fresh receipts. Finalizer creates one040A history/CURRENT/ledger/event and then checks/publishes; publication/control-check/transport outcomes are closure receipts outside this immutable prepublication source. Final PASS return is conditional on their observed success; no future commit SHA or command success is fabricated here.

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=16
WORKER_REQUIREMENTS_EVIDENCED=16
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO
