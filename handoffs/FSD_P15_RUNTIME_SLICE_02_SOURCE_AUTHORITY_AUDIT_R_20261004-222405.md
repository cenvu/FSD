# P15 Slice 02 independent source-authority/security audit

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_P15_RUNTIME_SLICE_02_SOURCE_AUTHORITY_AUDIT_R_20261004-222405.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=251737b6963daf4e350e3fcf9188717486173315
REMOTE_HEAD=251737b6963daf4e350e3fcf9188717486173315
LAST_VERIFIED_AT=2026-10-04T22:24:05+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|STATE/PROJECT_STATE.md|docs/P15_RUNTIME_PLAN.md|docs/ARCHITECTURE.md|docs/SECURITY_AND_READ_ONLY_POLICY.md|docs/DECISIONS.md|docs/TEST_PLAN.md|docs/PRODUCT_STATE.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_P15_RUNTIME_SLICE_02_SOURCE_AUTHORITY_AUDIT_013
STATUS=REVIEW_COMPLETE_REPAIR_PENDING_BRAIN
BLOCKER=THREE_REPRODUCED_SECURITY_CONTRACT_DEFECTS
PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_FSD_P15_SLICE_02_SOURCE_AUTHORITY_AUDIT_ADJUDICATION
NO_AUTO_NEXT=YES

## Task lock and execution guard

TASK_ID=FSD_P15_RUNTIME_SLICE_02_SOURCE_AUTHORITY_AUDIT_013
ROLE=REVIEWER
MODE=INDEPENDENT_SOURCE_READ_AUTHORITY_SECURITY_AUDIT
BASE_HEAD=251737b6963daf4e350e3fcf9188717486173315
UPSTREAM_HEAD=251737b6963daf4e350e3fcf9188717486173315
IMPLEMENTATION_BASE=ea0e2289fc0583446a67ccbeefbb015e457cd01a
REVIEWED_TECHNICAL_SHA=1316b937ebd74d07a990bf0d2f59210a039e58c2
IMPLEMENTER_PUBLICATION_SHA=965df74ee3e249ed26986dc3ddf512d73e9278da
IMPLEMENTER_HANDOFF=handoffs/FSD_P15_RUNTIME_SLICE_02_SOURCE_AUTHORITY_D_20261004-213748.md
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=READ_ONLY_INDEPENDENT_SOURCE_AUTHORITY_SECURITY_AUDIT_AND_AUTHORIZED_RETURN
ALLOWED_PATHS=handoffs/FSD_P15_RUNTIME_SLICE_02_SOURCE_AUTHORITY_AUDIT_R_20261004-222405.md|handoffs/CURRENT_HANDOFF.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl
FORBIDDEN_PATHS=ALL_OTHER_TRACKED_PATHS;PRODUCT_SOURCE_TEST_SCHEMA_DESIGN_DEPENDENCIES;STATE/PROJECT_STATE.md;STATE/RULE_PROMOTION_LEDGER.tsv;HISTORICAL_HANDOFFS
SUCCESS_CRITERIA=INDEPENDENT_REQUIREMENT_ACCOUNTING;FRESH_VALIDATION;MATERIAL_FINDINGS_REPRODUCED;EXACT_RETURN_SCOPE
VALIDATIONS=SEMANTIC_DIFF;BYTE_PARITY;CLEAN_DEBUG_BUILD;84_FOCUSED_TESTS;41_RELATED_TESTS;THREE_REAL_POSIX_PROBES;FINALIZER_CHECKER_PUBLICATION
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
WORKER_RESULT=REPAIR
RESULT_AUTHORITY=REVIEWER_EVIDENCE_ONLY

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=24
WORKER_REQUIREMENTS_EVIDENCED=24
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

Guard PASS records completed review procedure and evidence coverage, including demonstrated implementation failures. It is not source-security acceptance. EVIDENCED means audited with evidence; failed contracts remain failed. BRAIN owns adjudication.

## Reanchor / independent baseline

FACT: physical root /Users/cenvu/DEV/FSD, branch main. Initial local HEAD was publication 965df74, upstream exact expected 251737b (0 ahead/1 behind). Fetch and ancestry/diff inspection showed one BRAIN control commit only: accepted STATE, prior ledger classification and two BRAIN events. git pull --ff-only origin main applied that existing canonical commit, with no new merge commit/history rewrite. Baseline and fresh postflight then showed 251737b6963daf4e350e3fcf9188717486173315=origin/main, 0/0, tracked/untracked clean. Owner ignored material retained; no reset/clean/stash/rebase/discard.

FACT: accepted STATE is DEMO_SPRINT, audit gate 013, LAST_ACCEPTED_TASK bounded authority 012, accepted publication 965df74. Task-execution and independent-review loaded with REVIEWER; finalizer loaded after fresh execution postflight. AGENTS, Compact, relevant FULL review policy and all direct authorities read. Historical preparation/runtime-not-started wording in product baseline/design is reconciled against accepted STATE, exact P15 Slice 02 and physical source; it does not override actual implemented bytes or authorize later slices. No product-document edits.

FACT: git diff TECHNICAL_SHA HEAD -- FSD FSDTests FSD.xcodeproj docs/P15_RUNTIME_PLAN.md is empty, exit0. Detector/schema/migration paths unchanged from implementation base. Reviewed semantic diff is ea0e228 -> 1316b93; publication/control-plane closure is distinct.

Exact changed-path manifest (10):
- FSD.xcodeproj/project.pbxproj
- FSD/Catalog/EntryClassificationRepository.swift
- FSD/Catalog/SnapshotWriter.swift
- FSD/Classification/BoundedClassificationSourceReader.swift
- FSD/Classification/LocalFileClassificationProvider.swift
- FSDTests/ClassificationEnrichmentTests.swift
- FSDTests/ClassificationProviderContractTests.swift
- FSDTests/ClassificationSourceReaderTests.swift
- FSDTests/SnapshotHistoryTests.swift
- docs/P15_RUNTIME_PLAN.md

## Verdict

REPAIR: three real-POSIX observations contradict locked race/source-authority or cancellation ordering contracts. Existing 84 focused and 41 related tests pass but omit these interleavings. No repair, Slice 03, schema change or authority extension was performed.

## F1 — acquired parent can read outside root before post-read rejection

SEVERITY=HIGH
FACT_OR_INFERENCE=FACT
EVIDENCE=FSD/Classification/BoundedClassificationSourceReader.swift:256,263,277,293,301,348-366; FSDTests/ClassificationSourceReaderTests.swift:443-453; independent reader-probes.log PARENT_RENAME.

After directory walk, the reader retains parent fds. Final stat/open are relative to the held parent, with no ancestry revalidation before payload I/O. Real captured source/sub/f.txt fixture: immediately before final statNoFollow, actor renames source/sub to outside/moved, removes its original f.txt, and moves a regular outside secret file into outside/moved/f.txt. Final fstatat/openat/fstat agree on the new regular child, same device. Real Darwin.read reads that outside object once. The second walk later detects source/sub missing and returns sourceChanged.

Receipt: PARENT_RENAME outcome=sourceChanged reads=1 outsideBytesRead=true pathOutsideRoot=true

BLAST_RADIUS=Up to 4096 bytes consumed from an attacker-selected regular file via a parent that has left the selected root. Demonstrated schedule discards bytes, invokes no provider and persists no result; post-read rejection still cannot undo unauthorized payload I/O. No whole-file read, source write, privilege elevation or demonstrated provider exfiltration is claimed.
WHY_EXISTING_TESTS_CATCH_OR_MISS=Between-lstat/open replacement tests catch inode mismatch before content. Parent replacement test changes parent only after content read. Symlink tests mutate before walk and prove no-follow. No existing case reparents an already-open directory and introduces an outside child before final lstat. Probe delegates every stat/open/read to real Darwin and uses actual detector/capture/catalog; only actor scheduling is injected, not fake filesystem identity.
SMALLEST_REPAIR_DIRECTION=Bind final resolution/open to established selected-root/source authority and reject changed ancestry before payload I/O; add acquired-parent rename/outside-child regression requiring zero reads. Preserve one-read/no-follow. Post-read rejection alone, or an extra non-atomic precheck advertised as full proof, is insufficient. Escalate architecture if locked containment cannot be guaranteed rather than weaken it.

## F2 — late cancellation can lose to validation errors

SEVERITY=MEDIUM
FACT_OR_INFERENCE=FACT
EVIDENCE=FSD/Classification/BoundedClassificationSourceReader.swift:317,331-367,369; independent reader-probes.log CANCEL_DURING_REVALIDATION; repaired tests FSDTests/ClassificationSourceReaderTests.swift:548-571.

Immediate afterRead cancellation check precedes post-read fstat/detection/second walk. These can return failed/sourceChanged directly and bypass final cancellation observation. Probe flips the cancellation signal used by isCancelled during the second detectMount call, then throws ENOENT. The earlier afterRead check saw false; cancellation is true at terminal sourceChanged return.

Receipt: CANCEL_DURING_REVALIDATION outcome=sourceChanged cancelled=true reads=1 detects=2

BLAST_RADIUS=Outcome ordering depends on whether cancellation arrives during the payload attempt or during later source/path validation. No retry, successful provider request or result row in the observed schedule. Post-read fstat/walk/final-stat errors have analogous early returns. Cancellation can also arrive between afterOpen and read with no additional pre-payload checkpoint.
WHY_EXISTING_TESTS_CATCH_OR_MISS=Repaired EINTR/read+disappearance REDs flip cancellation during read and pass. Task cancellation test cancels before entry. No test cancels during the second detector/walk failure. Thus green repaired tests do not establish every later boundary.
SMALLEST_REPAIR_DIRECTION=Observe cancellation consistently at post-read validation/error completion and immediately before payload I/O. Preserve genuine pre-read sourceChanged/unsupported when cancellation had not occurred. Add late detector/walk errors plus pre-read outcome controls; no content retry.

## F3 — alias root proof can accept a locator naming a different object

SEVERITY=MEDIUM
FACT_OR_INFERENCE=FACT
EVIDENCE=FSD/Catalog/SnapshotWriter.swift:93,186-191,233,241-242; root-probe.log ROOT_PROOF_RACE; no revalidation before INSERT at 101-117.

Stage D compares canonical pathname stat to held candidate fd fstat, proving sampled objects match, not current pathname association. Real /System/Volumes/Data alias fixture: syscall scheduler calls genuine fstat for candidate A, then renames A aside and creates B at the same pathname before returning the unmodified fstat result. Held fd remains A and matches canonicalStat A. Unchanged rootRelativePath accepts. At helper return the candidate named by its locator is B, different inode, same device.

Receipt: ROOT_PROOF_RACE locatorAccepted=true differentObjectAtReturn=true sameDevice=true

BLAST_RADIUS=Alias-route capture admission can accept a locator after pathname/object association proved by Stage D has changed. beginCapture stores that locator without further association validation (STRONG_INFERENCE from inspected call/INSERT). Probe exercised helper acceptance, not a persisted malicious snapshot or payload read. This is a TOCTOU defect, not a missing inode comparison or second-candidate fallback. Explicitly authorized no-I/O direct route is outside this finding.
WHY_EXISTING_TESTS_CATCH_OR_MISS=Static different-object/symlink fixtures never replace a pathname after candidate fd/stat acquisition. Probe uses real Data-volume namespace and unmodified actual dev/ino; interposition schedules ordinary external rename/mkdir in a syscall-return window. No fabricated mount/identity.
SMALLEST_REPAIR_DIRECTION=Keep proven root object/namespace association bound across alias proof and capture admission/consumption, fail closed on substitution, and add Stage-D replacement regression. No alternate candidate, /var mapping, entry realpath, device-only acceptance or backfill. One additional check has a later TOCTOU window; architecture must specify how the proven root is consumed if pathname-only plumbing cannot retain the guarantee.

## Requirement / evidence map

All 24 review obligations EVIDENCED. FAIL denotes known implementation-contract failure, not absent review evidence.

| # | Obligation | Independent evidence |
|---|---|---|
| 1 | Canonical root/branch/heads/state/preservation | Fetch, exact 251737b, main 0/0 clean, accepted gate/task. |
| 2 | Stage A lexical/empty/no alias I/O | Writer 155-167; direct missing-child, mount-root, nested/dot tests pass. Branch has no filesystem call. |
| 3 | Only root realpath, one physical candidate | Writer 172/179/199/220; one callsite; no raw /var fallback/table/firmlink/basename/display matching; no reader realpath. |
| 4 | Candidate no-follow/dev+ino/rejection matrix | Writer 186-188/235-242; static canonicalization/missing/different/symlink/unprovable rejection; real /var success executed. |
| 5 | Root proof/use TOCTOU | FAIL F3; real Data-volume reproduction. |
| 6 | Legacy<9 unavailable/no row/no backfill | Reader 219; legacy reader/history/fingerprint tests pass. |
| 7 | Exact volume equality | Reader 236/345; same-name impostor rejected. Mount equality is an additional check, never volume identity substitute. |
| 8 | Relative components/escape | Reader 126-135/225/246; absolute/dot/dotdot/empty/NUL/length/depth gates; matrix green. |
| 9 | Regular-only/no-follow path | Actual O_RDONLY/O_NOFOLLOW/O_DIRECTORY openat; AT_SYMLINK_NOFOLLOW fstatat; final O_NONBLOCK + regular fstat. Packages/symlink/directory/special rejected before content. |
| 10 | Parent/final race authority | Final symlink never followed. FAIL F1 for acquired-parent reparenting. |
| 11 | Opened fd/path/source identity | Before-read dev+ino compare and metadata-only post-read fd/detector/chain/final path checks; standard races green, insufficient for F1. |
| 12 | Ceiling and exactly one read | Single Darwin.read at 83, single call 301, 4096 allocation, fresh fd offset zero; small/exact/above/short/EINTR green, no retry/fill/tail/seek loop. |
| 13 | Alternate access/hash/log absence | New-source callsite search: no pread/FileHandle/Data(contentsOf)/readToEnd/whole-file fallback; no invoked sample-hash pipeline. Hashable conformance alone is not a persisted/invoked sample hash. |
| 14 | Immediate cancellation repairs | Read error/EINTR and read+disappearance cancellation cases pass with one call; cancellation before error mapping. |
| 15 | All late cancellation boundaries | FAIL F2; pre-read genuine sourceChanged/unsupported remain when cancellation false. |
| 16 | Data-only structural bound | Provider 14-26, one let Data; internal failable initializer rejects >4096; custom initializer suppresses memberwise init; no extensions/alternate/bypass init target-wide. |
| 17 | Async/disabled provider | Protocol 76 async; pure unavailable at 88-89, no I/O/database state; contract tests green. |
| 18 | Result/sample persistence absent | Reader only SELECT, provider no DB, old service removed; no sample Data/hex/base64/hash/absolute-source-path/raw-diagnostic/payload logging added. |
| 19 | Immutable entries/snapshots/comparison | Reader no writes; fingerprints/legacy unchanged; new locator INSERT only and update trigger rejection green. |
| 20 | Source read-only/network/mount boundary | No O_WRONLY/O_RDWR/create/unlink/rename/copy/move/remove/truncate/chmod/chown/xattr/marker/temp/network/mount calls in new production paths. Actor fixtures separate. |
| 21 | Test falsifiability and realistic seams | Matrix below; actual POSIX delegation; no names-only proof. |
| 22 | Fresh executable validation | Fresh clean build success, 84 focused + 41 related pass, 0 failures/skips; independent probes positively reproduce defects. |
| 23 | Three external skips assessed | Prior probe-catalog seed and two external matrix fixtures are not core reader/provider/root security proof; actual /var integration passed this audit. |
| 24 | Fresh postflight/scope/no-auto-next | Fresh fetched heads/parity/diff-check/scope; no product repair/next task. Publication mechanics pending at capture, checked by finalizer before terminal return. |

## Attack disposition / proof limits

Parent/final symlink swaps cannot redirect descriptor-relative opens: directory and final O_NOFOLLOW plus safe single components reject links; final lstat/fstat prove regularity. Already-open directory reparenting is distinct and violates authority as F1.

Regular replacement between lstat/open is caught by dev+ino before read. Replacement/disappearance after open cannot redirect pinned fd: original object's bytes may be read, then current path mismatch rejects. This bounded discarded read of the originally validated object differs from F1's newly introduced outside child. File absent before open yields sourceChanged/zero read; initial unresolved/detached source yields unavailable.

Mount/source changes after initial detect are checked after payload by detector/device/path identity. Initial volume detection is pathname-based and not atomically tied to opened mount fd; zero payload access during detect-to-open mount substitution is not independently proven. No privileged mount/unmount attack was attempted; F1 provides a concrete nonprivileged authority violation. Candidate path changes while fd remains open are quantified by F1/F3. No second content read verifies anything. In-place same-inode byte changes are not content equivalence claims: classification describes current inferred bytes, never retroactive snapshot proof.

Provider API grants only bounded bytes: no path/URL/fd/entryID/snapshotID/volume/mount/metadata/filesystem object/callback/resolver/budget/extra-read method. Reflection tests alone cannot prove absence of members or global side channels; whole-target constructor/member/callsite inspection supplies API proof. An arbitrary in-process provider is not an OS sandbox, and Data may itself contain location text from payload; no source location capability is carried by FSD request fields. Provider-supplied result strings are outside Slice-02 orchestration, which persists nothing.

## Falsifiability matrix

- Direct/mount/nested: wrong prefix/remainder/empty handling fails exact locator values. Missing direct child detects required identity/alias proof, but would miss ignored optional I/O; source inspection establishes no-I/O branch.
- Canonical success: wrong raw derivation or rejection of equal dev+ino fails real /var case. It ran here, no host skip.
- Missing/canonicalization/different object: permissive fallback/dropping inode comparison permits capture/rows and fails throws/no-row assertions. Same-device-only acceptance fails different-object fixture.
- Escape candidate: following symlink to same selected object fails reject/no-row tests. Unreadable-candidate fixture also differs by object, so does not isolate permissions; actual POSIX and separate reader permission test prove permission handling.
- Single candidate unit tests establish constructor values, not attempted call count; complete production branch inspection proves one construction/no fallback.
- Legacy: removing schema guard/backfilling fails unavailable/no-I/O/no-row/fingerprint checks. Exact volume mismatch: name-based matching accepts impostor and fails.
- Component/no-follow: removal permits outside secret or invalid paths and fails zero-read/typed outcomes. Kind gate removal fails regular-only/zero-content assertions.
- Preopen replacement: removing dev+ino comparison allows replacement read and fails zero-read expectation. Existing parent test only mutates after read, misses F1.
- Byte boundary/count: ceiling increase/retry/fill/tail/short-result acceptance/EINTR retry fails bytes/count/outcome assertions. forcedReadCount wraps a real read and reports short count; it proves no top-up, not host short-read causation.
- Repaired cancellation REDs: mapping read error before cancellation or validating disappeared path before immediate cancellation fails. No late detector/walk cancel schedule; F2.
- Hostile provider: extra stored capability/metadata/oversized Data fails reflection/marker/data assertions. Compile/API inspection establishes no callable bypass or memberwise initializer.
- Immutability/persistence: adding writes changes row counts/fingerprints. Deny-list tests supplemented by complete syscall/API search.
- Root proof: all existing rejection fixtures static; no post-fd pathname substitution, F3.

## Fresh validation receipts / skips

Required DerivedData did not exist before build: /tmp/FSD-P15-S02-Audit-DerivedData.

```sh
xcodebuild -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-P15-S02-Audit-DerivedData clean build
xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-P15-S02-Audit-DerivedData -only-testing:FSDTests/ClassificationSourceReaderTests -only-testing:FSDTests/ClassificationProviderContractTests -only-testing:FSDTests/ClassificationEnrichmentTests -only-testing:FSDTests/SnapshotHistoryTests
xcodebuild test -project FSD.xcodeproj -scheme FSD -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FSD-P15-S02-Audit-DerivedData -only-testing:FSDTests/SnapshotLifecycleTests -only-testing:FSDTests/MilestoneConditionTests -only-testing:FSDTests/ComparisonSnapshotStateTests
git diff --check ea0e2289fc0583446a67ccbeefbb015e457cd01a 1316b937ebd74d07a990bf0d2f59210a039e58c2
git diff --exit-code 1316b937ebd74d07a990bf0d2f59210a039e58c2 HEAD -- FSD FSDTests FSD.xcodeproj docs/P15_RUNTIME_PLAN.md
```

/tmp/FSD-P15-S02-Audit-build.log: CLEAN SUCCEEDED, BUILD SUCCEEDED.
/tmp/FSD-P15-S02-Audit-focused.log: xcodebuild exit0; 42 source + 9 provider + 10 enrichment + 23 history = 84 tests, 0 fail, 0 skip. xcresult Logs/Test/Test-FSD-2026.10.04_22-07-29-+0700.xcresult beneath fresh DerivedData.
/tmp/FSD-P15-S02-Audit-broader.log: exit0; 41 tests, 0 fail, 0 skip. Wider capture/lifecycle/comparison subset justified by shared Writer root helper; no unexplained wider schema/comparison defect warrants repeating million-scale/full suite.

Prior full 365 total/362 pass/3 skips is implementer evidence, not independent proof. Three external probes identified in FSDTests/FSDProbeSeedTests.swift:26 and FilesystemMatrixTests.swift:25,89 require external catalog/matrix fixtures; none proves root-reader/provider matrix. They are not claimed passed. Current /var root integration did execute/pass. Deterministic rejection/reader/provider tests do not require those three fixtures; independent root race uses host Data layout present here.

Probe executables link the freshly built FSD.debug.dylib through @testable import FSD, not copied/reimplemented production. All filesystem return values real. Exit0 means defect preconditions satisfied, not security PASS. Initial -lFSD.debug link failed because actual dylib lacks lib prefix; inspected build path and passed exact dylib path on one corrected invocation. No product/config repair. Return-script first attempt had Python SyntaxError (Unicode in bytes literal), before any mutation; corrected encoding before creating this sole handoff.

## Postflight / finalization capture

Fresh fetch and physical inspection at postflight: exact canonical 251737b6963daf4e350e3fcf9188717486173315, 0/0 clean; implementation/test/P15 bytes equal technical SHA; no tracked audit delta before finalization. Reviewed source is unchanged. No implementation repair, accepted state change or next-task work.

Finalizer creates this one immutable audit source, full CURRENT, one pending Reviewer ledger row (basis 251737b6963daf4e350e3fcf9188717486173315), one worker_return event, and Desktop transport. PROJECT_STATE/rule ledger/historical handoffs remain unchanged. Guard reflects completed independent review, not future publication. At immutable capture checker/push/fetch/final Desktop Git receipt are pending; terminal return waits for actual closure checks. Publication SHA resolved outside source by git log -1 --format=%H -- <handoff>, no self-referential bookkeeping commit. The single HOT proposal returns to BRAIN for adjudication only.

Essential probe sources below survive temporary-artifact cleanup. Actual grouped sources/executables/logs/fixtures live at /tmp/FSD-P15-S02-Audit-DerivedData/AuditProbes. Actor writes only its disposable fixtures; logs contain booleans/count/outcome, no actual sampled payload.

## Standalone reproduction

Compile each Swift probe with:
```sh
xcrun swiftc <main.swift> -I /tmp/FSD-P15-S02-Audit-DerivedData/Build/Products/Debug /tmp/FSD-P15-S02-Audit-DerivedData/Build/Products/Debug/FSD.app/Contents/MacOS/FSD.debug.dylib -Xlinker -rpath -Xlinker /tmp/FSD-P15-S02-Audit-DerivedData/Build/Products/Debug/FSD.app/Contents/MacOS -o <probe>
xcrun clang -dynamiclib <root-race.c> -o <root-race.dylib>
```
Reader executable runs directly. Root executable needs a newly created disposable directory's canonical absolute path in FSD_AUDIT_ROOT_RACE_TARGET and DYLD_INSERT_LIBRARIES=<root-race.dylib>. Real /System/Volumes/Data namespace was present here; no skip counted as success.

### Reader probes

```swift
import Darwin
import Foundation
@testable import FSD

final class ProbeFilesystem: BoundedSourceFilesystem {
    let real = DarwinBoundedSourceFilesystem()
    var beforeStat: (() throws -> Void)?
    var reads = 0
    var sawOutsideBytes = false
    let expectedOutside = Data("AUDIT-OUTSIDE-SECRET".utf8)
    func openMountRoot(path: String) throws -> Int32 { try real.openMountRoot(path: path) }
    func openDirectory(parent: Int32, name: String) throws -> Int32 { try real.openDirectory(parent: parent, name: name) }
    func statNoFollow(parent: Int32, name: String) throws -> ClassificationFileStat {
        if let hook = beforeStat { beforeStat = nil; try hook() }
        return try real.statNoFollow(parent: parent, name: name)
    }
    func openRegularFile(parent: Int32, name: String) throws -> Int32 { try real.openRegularFile(parent: parent, name: name) }
    func stat(descriptor: Int32) throws -> ClassificationFileStat { try real.stat(descriptor: descriptor) }
    func readOnce(descriptor: Int32, into buffer: UnsafeMutableRawBufferPointer) throws -> Int {
        reads += 1
        let n = try real.readOnce(descriptor: descriptor, into: buffer)
        sawOutsideBytes = Data(buffer.prefix(n)) == expectedOutside
        return n
    }
    func close(descriptor: Int32) { real.close(descriptor: descriptor) }
}
let base = URL(fileURLWithPath: "/tmp/FSD-P15-S02-Audit-DerivedData/AuditProbes/fixtures-" + UUID().uuidString)
let fm = FileManager.default
try fm.createDirectory(at: base, withIntermediateDirectories: true)
let source = base.appendingPathComponent("source")
let outside = base.appendingPathComponent("outside")
try fm.createDirectory(at: source.appendingPathComponent("sub"), withIntermediateDirectories: true)
try fm.createDirectory(at: outside, withIntermediateDirectories: true)
try Data("original".utf8).write(to: source.appendingPathComponent("sub/f.txt"))
let fs = ProbeFilesystem()
try fs.expectedOutside.write(to: outside.appendingPathComponent("secret.txt"))
let db = try CatalogDatabase(url: base.appendingPathComponent("catalog.sqlite3"), schemaURL: URL(fileURLWithPath: "/Users/cenvu/DEV/FSD/docs/database/schema.sql"))
defer { db.close() }
let snap = try SnapshotScanner(database: db).capture(root: source)
let id = try db.scalar("SELECT id FROM entries WHERE snapshot_id = ? AND relative_path = 'sub/f.txt'", bindings: [.integer(snap.id.rawValue)])!.int64Value!
fs.beforeStat = {
    try fm.moveItem(at: source.appendingPathComponent("sub"), to: outside.appendingPathComponent("moved"))
    try fm.removeItem(at: outside.appendingPathComponent("moved/f.txt"))
    try fm.moveItem(at: outside.appendingPathComponent("secret.txt"), to: outside.appendingPathComponent("moved/f.txt"))
}
let parentReader = BoundedClassificationSourceReader(database: db, detectMount: { try FilesystemDetector().detect(root: $0) }, filesystem: fs, isCancelled: { _ in false })
let parentOutcome = try parentReader.readPrefix(forEntryID: id)
print("PARENT_RENAME outcome=\(parentOutcome) reads=\(fs.reads) outsideBytesRead=\(fs.sawOutsideBytes) pathOutsideRoot=\(!fm.fileExists(atPath: source.appendingPathComponent("sub/f.txt").path))")
precondition(parentOutcome == .sourceChanged && fs.reads == 1 && fs.sawOutsideBytes)
try fm.moveItem(at: outside.appendingPathComponent("moved"), to: source.appendingPathComponent("sub"))
var cancelled = false
var detectCalls = 0
let cancelFS = ProbeFilesystem()
let cancelReader = BoundedClassificationSourceReader(database: db, detectMount: { url in
    detectCalls += 1
    if detectCalls == 2 { cancelled = true; throw ClassificationPOSIXFailure(code: ENOENT) }
    return try FilesystemDetector().detect(root: url)
}, filesystem: cancelFS, isCancelled: { _ in cancelled })
let cancelOutcome = try cancelReader.readPrefix(forEntryID: id)
print("CANCEL_DURING_REVALIDATION outcome=\(cancelOutcome) cancelled=\(cancelled) reads=\(cancelFS.reads) detects=\(detectCalls)")
precondition(cancelOutcome == .sourceChanged && cancelled && cancelFS.reads == 1)
```

### Root syscall scheduler

```c
#include <sys/stat.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
static int fired = 0;
static int audit_fstat(int fd, struct stat *result) {
    int rc = fstat(fd, result);
    const char *path = getenv("FSD_AUDIT_ROOT_RACE_TARGET");
    if (rc == 0 && path && !fired) {
        struct stat target;
        if (stat(path, &target) == 0 && target.st_dev == result->st_dev && target.st_ino == result->st_ino) {
            char backup[4096];
            snprintf(backup, sizeof(backup), "%s-old", path);
            fired = 1;
            if (rename(path, backup) != 0 || mkdir(path, 0700) != 0) abort();
        }
    }
    return rc;
}
__attribute__((used)) static const struct { const void *replacement; const void *replacee; } interpose_fstat
__attribute__((section("__DATA,__interpose"))) = { (const void *)(uintptr_t)&audit_fstat, (const void *)(uintptr_t)&fstat };
```

### Root probe

```swift
import Darwin
import Foundation
@testable import FSD
let source = URL(fileURLWithPath: ProcessInfo.processInfo.environment["FSD_AUDIT_ROOT_RACE_TARGET"]!)
let mount = "/System/Volumes/Data"
let fs = DarwinBoundedSourceFilesystem()
let before = try fs.statFollowing(path: source.path)
let descriptor = FilesystemDescriptor(rootURL: source, volumeName: "Data", volumeIdentifier: "audit", filesystemType: "apfs", sourceCaseSensitivity: .insensitive, isReadOnly: false, mountPath: mount, capacityBytes: nil, availableBytes: nil)
let relative = try SnapshotWriter.rootRelativePath(for: descriptor)
let current = try fs.statFollowing(path: mount + "/" + relative)
print("ROOT_PROOF_RACE locatorAccepted=true differentObjectAtReturn=\(before.inode != current.inode) sameDevice=\(before.device == current.device)")
precondition(before.inode != current.inode)
```
