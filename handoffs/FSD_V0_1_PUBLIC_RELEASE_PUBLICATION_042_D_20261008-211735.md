# Task042 — public v0.1.0 prerelease verified; reporting closure STOP

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_V0_1_PUBLIC_RELEASE_PUBLICATION_042_D_20261008-211735.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=b053490c030a46a5edc8f7b999397d05e69646f8
REMOTE_HEAD=b053490c030a46a5edc8f7b999397d05e69646f8
LAST_VERIFIED_AT=2026-10-08T21:17:35+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|STATE/PROJECT_STATE.md|docs/releases/v0.1.0.md|README.md|docs/DEPENDENCY_AND_LICENSE_REVIEW.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=V0_1_PUBLIC_RELEASE_PUBLICATION_PRECHECK
STATUS=PUBLICATION_ALREADY_VISIBLE;REPORTING_CLOSURE_BLOCKED_PENDING_BRAIN
BLOCKER=CANONICAL_CHECKER_REJECTS_EXISTING_BRAIN_ACCEPTED_STOP041
PROPOSED_NEXT=OWNER_DECISION
NO_AUTO_NEXT=YES

## Locked authority and outcome

TASK_ID=FSD_V0_1_PUBLIC_RELEASE_PUBLICATION_042
ROLE=WORKER
MODE=GUARDED_GITHUB_PUBLIC_PRERELEASE_PUBLICATION
BASE_HEAD=b053490c030a46a5edc8f7b999397d05e69646f8
UPSTREAM_HEAD=b053490c030a46a5edc8f7b999397d05e69646f8
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=EXACT_EXISTING_REPOSITORY_PUBLIC_PRERELEASE_AND_TASK042_REPORTING
ALLOWED_PATHS=STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|handoffs/CURRENT_HANDOFF.md|handoffs/FSD_V0_1_PUBLIC_RELEASE_PUBLICATION_042_D_20261008-211735.md
FORBIDDEN_PATHS=PRODUCT_SOURCE|BINARY|ZIP_REBUILD_REPACKAGE_RESIGN|README|OLD_HANDOFFS|ACCEPTED_PROJECT_STATE|ARCHIVED_DECISIONS|CHECKER_REPAIR|UNRELATED_GITHUB_SETTINGS
SUCCESS_CRITERIA=EXACT_AUDITED_TAG_ZIP_BODY;PRIVATE_STAGING;PUBLIC_VISIBILITY;ANONYMOUS_DOWNLOAD;CANONICAL_REPORTING_CLOSURE
VALIDATIONS=GIT_GH_API;ALL_REACHABLE_SECRET_SCAN;41_BUILD_INPUTS;PLIST_MACHO_CODESIGN;ZIP_CRC_HASH;ANONYMOUS_HTTP;CANONICAL_CHECKER
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
RESULT=STOP
PUBLICATION_STATE=PUBLICATION_ALREADY_VISIBLE
RELEASE_EFFECTS=VERIFIED
REPORTING_PUBLICATION=BLOCKED_BY_PREEXISTING_CANONICAL_STATE_CHECKER_CONFLICT

FACT: the real public prerelease and exact downloads were independently verified. The overall Worker result is STOP because required clean committed/pushed reporting closure cannot pass the existing checker. This is not a failed or private release. No duplicate release, visibility reversal or concealment is proposed. Reversing visibility would not erase already exposed history.

Task040A remains BRAIN-accepted PASS_WITH_ADVISORY at candidate 8a4223eeba93306ecba0262e4dbe38efed96c704. Task041 remains BRAIN-accepted STOP at d8888421e87fd1117903072a9e1ce24f92631434, with three privacy requirements UNPROVEN. The Owner explicitly authorized publishing cenvu/FSD and its reachable history, and distributing the exact unsigned candidate, accepting residual process-privacy risk. This acceptance does not establish credential revocation, expiry, exact containment or external retention. No new material credential finding appeared in Task042's covered publication surfaces.

## Actual GitHub publication receipt — FACT

PREPUBLICATION_HEAD=b053490c030a46a5edc8f7b999397d05e69646f8
TAG=v0.1.0
TAG_OBJECT=b0bd9c4cfb6cc17e90f2c2733fda604d381bf9f7
TAG_TARGET=8a4223eeba93306ecba0262e4dbe38efed96c704
RELEASE_ID=406906419
RELEASE_URL=https://github.com/cenvu/FSD/releases/tag/v0.1.0
REPO_URL=https://github.com/cenvu/FSD
REPO_VISIBILITY=PUBLIC
PRIVATE_FLAG=false
PRERELEASE=YES
DRAFT=NO
RELEASE_TITLE=FSD v0.1.0 — First Public Test
ZIP_NAME=FSD-v0.1.0-macOS15-arm64.zip
ZIP_URL=https://github.com/cenvu/FSD/releases/download/v0.1.0/FSD-v0.1.0-macOS15-arm64.zip
ZIP_ASSET_ID=622022503
ZIP_BYTES=3542111
ZIP_SHA256=6c840c66ca2677e849e64dc0802890ae8aa60d2901db7ed9d9c863884ee16134
CHECKSUM_NAME=SHA256SUMS.txt
CHECKSUM_URL=https://github.com/cenvu/FSD/releases/download/v0.1.0/SHA256SUMS.txt
CHECKSUM_ASSET_ID=622022504
CHECKSUM_BYTES=95
CHECKSUM_SHA256=1b3e076a81c09b11ca64c0ab375f39f8a0eeaf14e9640965c893239934ee7642
HELPER_SHA256=665a6569ee60614313e50629c4166358b89859f15dac4c522905ee5a730752e7
RELEASE_BODY_SHA256=36abea177a5660f7dace3c947ed494eaf272b545d2c66ee8a49d18655b939d83
ANONYMOUS_DOWNLOAD=PASS
ANONYMOUS_VERIFIED_AT=2026-10-08T21:14:15.191673+07:00
PRIVACY_RISK=OWNER_ACCEPTED_UNRESOLVED
CREDENTIAL_REVOKED=NOT_VERIFIED

## Fresh prechecks and exact source/artifact identity

FACT: physical /Users/cenvu/DEV/FSD, main, canonical origin https://github.com/cenvu/FSD.git; initial/fresh prepublication HEAD and origin/main equal the requested base, clean ahead0/behind0. Canonical ACTION is this exact task. GitHub account cenvu has admin and push permissions. Repository was PRIVATE, remote only main, no tags/Releases and no Actions runs. No unknown local delta was accommodated. Full initial tracked baseline, including literal symlink targets, is recorded in ignored protected-baseline.json. The first baseline read followed a known broken fixture symlink and failed; one bounded evidence-backed correction captured literal symlink target bytes. No repository mutation or cleanup resulted.

All41 documented build inputs match manifest SHA256 1f5d6a4c3fe238bdad466de824be8a057d97415fb2c0034f27c4979b0951ce74 and exact audited candidate/current bytes. Candidate-to-base diff is only STATE and handoffs, including041 and Owner acceptance projection; no later product delta. README is identical at candidate/current. All four approved images match039/candidate/current: library-overview 25cbc92662237d71d809ab6907e1d815a8f7751374aa4888e8bbddb95489ab8d; capture ac88c523ab900512d4198b1ddb5a96a6b86b785d9498e740ad65e165630dde42; compare e1c3409b65c381edc4b01fd21e57fa6b8d94b50eb84d6ebe2ce1baace31810f4; history 3f7ac727b0e79c9afc8336445bf8bf9e4422900f8377b8c82295a4c7494acfa7.

Actual ZIP CRC, path inventory, all contained bytes and fresh ditto extraction match041's audited artifact. Exactly six app files: Info.plist, PkgInfo, MacOS/FSD, Helpers/FSDClassificationHostSeam, Resources/schema.sql and Resources/THIRD_PARTY_NOTICES.txt. No private catalog, media, log/test output or additional resource. AppleDouble entries match the audited provenance metadata. Version0.1.0/build1/com.fsd.FSD/FishSock Differ; app arm64/minos15.0; helper arm64/minos13.0; exact schema/notices hashes match source. Existing intrinsic linker ad-hoc signatures and absent TeamIdentifier are unchanged; no Developer ID/notarization claim. No build, repackaging, helper mutation, re-signing or notarization performed.

## Security and truthful bilingual body

Fresh installed read-only gitleaks with default plus prior explicit session-token rule, no ignore file/baseline/allow directive, full redaction and decode-depth5: full history147 reachable commits (146 nonmerge scanner commits) and all1674 full blobs/35,421,639 bytes. History scanner reports0 findings; full-blob input35,505,339 bytes exits0/0 findings. Native literal scan includes commit metadata and full historical filename inventory; no metadata finding and no new literal finding. All17 binary objects and prior benign literal hits are identical to independently reviewed041 inventory. New041 report and Owner-risk projection were reviewed as governance prose; no credential value. Existing Owner development identity/path and approved example capture metadata remain authorized exposure. These checks support no known material public-source/ZIP secret finding, not mathematical absence or incident containment. Broad process listing was never rerun and no raw credential was copied.

Release body is derived from docs/releases/v0.1.0.md in ignored release-body.md only. Entire preparation commit bullet was replaced with audited full candidate SHA; final preparation-only bilingual status paragraph removed. Exact submitted body retains EN/VI first public test identity, macOS15+/arm64, feature summary/limitations, UNSIGNED/NOT NOTARIZED, conditional per-app Open/Open Anyway, Content Not Verified, notices/no FSD OSS license grant, exact ZIP size/SHA and redacted-feedback instructions. Zero preparation placeholders and no premature success statement. README accurately discloses unavailable controls/features, unsigned distribution and no OSS license. No existing release-candidate documentation/handoff was altered.

## Ordered mutations and independent anonymous verification

Local annotated tag was pinned explicitly to audited candidate and pushed only as refs/tags/v0.1.0 while PRIVATE. Fresh remote ls-remote, fetch/FETCH_HEAD dereference and independent GitHub annotated-tag API all agree. gh release create used --verify-tag, explicit full --target, --prerelease, --latest=false, exact title/body file and two original assets. Private API verification independently checks exact body, tag target, prerelease/draft and asset IDs/sizes/SHA256 digests. Authenticated private downloaded ZIP and checksum match actual original bytes before exposure.

Only after all gates, official gh repo edit cenvu/FSD --visibility public --accept-visibility-change-consequences executed under recorded Owner authorization. Fresh authenticated API reports visibility public/private false, same Release identity/body/assets. No ambiguous acknowledgement or mutation retry occurred.

Anonymous verification uses curl -q with minimal environment excluding auth variables, empty Authorization/Cookie headers and no browser session/cookies. Repository HTML renders both English/Vietnamese README text; raw README equals source. Four image URLs are extracted from rendered README HTML, downloaded and hash-matched. Public tag page, tag API/dereferenced annotated object, Release HTML/API, ZIP and checksum all return HTTP200/curl exit0. Exact ZIP download is3,542,111 bytes and matches expected SHA; downloaded checksum is95 bytes and matches original. Release HTML/API contain no preparation-only placeholder and API body equals submitted body. Public observed main is the prepublication base. No authenticated-session-only or invented URL proof.

Observed image URLs:

- https://github.com/cenvu/FSD/raw/main/docs/images/v0.1.0/library-overview.png
- https://github.com/cenvu/FSD/raw/main/docs/images/v0.1.0/capture.png
- https://github.com/cenvu/FSD/raw/main/docs/images/v0.1.0/compare.png
- https://github.com/cenvu/FSD/raw/main/docs/images/v0.1.0/history.png

## Reporting blocker and preserved ownership

FACT: scripts/check_control_plane.py:227–230 permits the last accepted classification only PASS/PASS_WITH_ADVISORY or accepted REVIEWER REPAIR. Existing PROJECT_STATE points to041 and existing ledger correctly contains REVIEWER/ACCEPTED/STOP. Exact unchanged predicate is false, with error `last accepted task lacks accepted classification`. Ignored control-precondition.json records this contradiction. Task042 forbids checker and accepted PROJECT_STATE mutation; relabeling041 or changing accepted provenance would violate authority. Canonical invocation follows this immutable record's projection and its actual output is captured in ignored checker-prepublication.json/Desktop. No canonical PASS, reporting commit, main push or clean reporting closure is claimed in this preclosure immutable source.

One new Task042 history/full CURRENT, one PENDING_BRAIN Worker ledger row and one append-only worker_return are authorized reporting only. Existing accepted STATE, prior rows/classifications/events/rules, product and all prior immutable handoffs remain preserved. If canonical check reproduces the blocker, leave truthful reporting bytes locally; do not bypass checker, commit/push an unvalidated closure, rewrite this immutable source or create another bookkeeping/reporting commit. Actual final Git/checker/public re-verification receipts belong in Desktop/ignored scratch, never a future self-referential commit SHA here.

Proposed BRAIN-only disposition: acknowledge independently verified public release and reconcile the preexisting checker/accepted-STOP contract in a separately authorized control-plane repair before finishing Task042 reporting publication. Successful public-release next would be Owner download/install acceptance, but the present whole-task STOP routes Owner decision only; no next gate or product task is executed by Worker.

Advisories remain: three041 process-privacy requirements UNPROVEN with Owner risk acceptance; no credential revocation/expiry/containment evidence; unsigned/not notarized; default downloaded-host Gatekeeper first launch not proven by security-disabled build host; native gray titlebar; manual VoiceOver/physical-media acceptance deferred; prior040A doc-hygiene receipt digest freshness advisory retained.

## Requirement/evidence map

| Requirement | Disposition | Fresh evidence under .ai-scratch/task042/ |
|---|---|---|
| Authority, physical Git/account/private/absence preflight | EVIDENCED | task-lock.json, prepublication-gate.json, repo-before.json, releases-before.json |
| Exact ZIP/checksum/extraction/resources/signing | EVIDENCED | candidate-verification.json, executable load/signing observations |
|41 exact build inputs/no later product delta | EVIDENCED | candidate-verification.json, manifest/candidate/current comparisons |
| Accessible history/metadata/filenames/new content/no new material secret | EVIDENCED | history-security.json, gitleaks-history.json/.log, gitleaks-blobs-receipt.json |
| Exact4 screenshots and truthful README/license | EVIDENCED | candidate-verification.json, direct bilingual source reading, anonymous hashes |
| Final resolved truthful bilingual body | EVIDENCED | release-body.md, exact body SHA/API/HTML comparisons |
| Annotated audited tag/private-only tag push/independent fetch | EVIDENCED | tag-receipt.json, remote dereferenced object |
| Private prerelease staging/exact assets/download | EVIDENCED | release-verified-private.json, private-download-receipt.json |
| Official authorized public change/API visibility | EVIDENCED | release-verified-public.json, anonymous repository API |
| Anonymous public pages/images/tag/Release/exact downloads | EVIDENCED | anonymous-verified-initial.json, anonymous-initial/http-observations.json |
| Passing canonical checker and clean committed/pushed Task042 reporting | UNPROVEN | control-precondition.json: existing accepted STOP is rejected; no authorized inline repair |

Publication semantics are verified; Worker completion is blocked. Desktop must retain exact canonical Operator bytes, full CURRENT copy and prior dated BRAIN decisions with actual final receipts. No material privacy unknown is relabeled PASS: the Task042 requirement is honoring explicit risk acceptance and stopping for new findings, not proving the three unproven041 containment requirements.

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=11
WORKER_REQUIREMENTS_EVIDENCED=10
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=1
WORKER_POSTFLIGHT=FAIL
NEXT_TASK_STARTED=NO
