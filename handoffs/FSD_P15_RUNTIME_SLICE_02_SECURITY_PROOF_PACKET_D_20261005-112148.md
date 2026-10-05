# P15 Slice 02 F1/F3 security proof packet (read-only preparation)

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_P15_RUNTIME_SLICE_02_SECURITY_PROOF_PACKET_D_20261005-112148.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=9b8333f4669acaa6ffea6ff58fa9de91421f597f
REMOTE_HEAD=9b8333f4669acaa6ffea6ff58fa9de91421f597f
LAST_VERIFIED_AT=2026-10-05T11:21:48+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|STATE/PROJECT_STATE.md|docs/P15_RUNTIME_PLAN.md|docs/ARCHITECTURE.md|docs/SECURITY_AND_READ_ONLY_POLICY.md|docs/DECISIONS.md|docs/TEST_PLAN.md|handoffs/FSD_P15_RUNTIME_SLICE_02_SOURCE_AUTHORITY_D_20261004-213748.md|handoffs/FSD_P15_RUNTIME_SLICE_02_SOURCE_AUTHORITY_AUDIT_R_20261004-222405.md|handoffs/FSD_P15_RUNTIME_SLICE_02_SECURITY_REPAIR_D_20261005-010050.md|handoffs/FSD_P15_RUNTIME_SLICE_02_SECURITY_REAUDIT_R_20261005-032259.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_P15_RUNTIME_SLICE_02_SECURITY_PROOF_PACKET_016
STATUS=EXECUTION_VERIFIED_PACKET_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_FOR_PACKET_SCOPE
PROPOSED_NEXT=FSD_P15_RUNTIME_SLICE_02_SECURITY_ADVISOR_017
NO_AUTO_NEXT=YES

## Task lock / execution guard

TASK_ID=FSD_P15_RUNTIME_SLICE_02_SECURITY_PROOF_PACKET_016
ROLE=WORKER
MODE=READ_ONLY_SECURITY_EVIDENCE_PREPARATION
BASE_HEAD=9b8333f4669acaa6ffea6ff58fa9de91421f597f
UPSTREAM_HEAD_AT_PREFLIGHT=9b8333f4669acaa6ffea6ff58fa9de91421f597f
PREFLIGHT_LOCAL_HEAD=a8e2d32b9c7b3f8a0df21a18e37d5c6b38d236e3
REPAIR_TECHNICAL_SHA=1e6f72b8f329fff5fe54234037b3af3d02e803ed
ACCEPTED_PUBLICATION_SHA=dd8d92d435684204da2b359acdff527757465521
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=READ_ONLY_F1_F3_DECISION_PACKET;NO_REPAIR;NO_CUSTOM_PROBES;NO_SLICE_03;NO_VERDICT
ALLOWED_PATHS=handoffs/FSD_P15_RUNTIME_SLICE_02_SECURITY_PROOF_PACKET_D_20261005-112148.md|handoffs/CURRENT_HANDOFF.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl
FORBIDDEN_PATHS=SWIFT_TEST_DOC_CHECKER_SCHEMA_XCODE;STATE/PROJECT_STATE.md;STATE/RULE_PROMOTION_LEDGER.tsv;HISTORICAL_HANDOFFS
SUCCESS_CRITERIA=COMPACT_PACKET_WITH_SECTIONS_A_TO_I;PACKET_WITHIN_12000_CHARS;F1_F3_FLOWS_MAPPED;TEST_LIMITS_EXPLICIT;UNPROVEN_QUESTIONS_EXPLICIT;READ_SET_WITHIN_6_RANGES;NO_SECURITY_VERDICT
VALIDATIONS=DIRECT_SOURCE_READS;BYTE_PARITY_DIGESTS;LEDGER_EVENT_PROVENANCE;PRIOR_RECEIPT_INSPECTION;FINALIZER_CANONICAL_CHECKER
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
WORKER_RESULT=PASS
RESULT_AUTHORITY=WORKER_EVIDENCE_ONLY

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=17
WORKER_REQUIREMENTS_EVIDENCED=17
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

Postflight mapped every packet requirement to fresh evidence below; UNPROVEN=0 because
packet completeness (not F1/F3 closure) is this task's requirement set. No verdict issued.

## Reanchor / provenance

FACT: preflight local main was a8e2d32, canonical origin/main 9b8333f (1 behind).
Diff/ancestry inspection showed one BRAIN control commit only (STATE classification of
015 STOP + two events; no product/test/doc/checker bytes). Non-destructive
git pull --ff-only applied that existing canonical commit; no merge commit, reset,
clean, stash, rebase, force or discard. Post-sync baseline is exact expected
HEAD=origin/main=9b8333f, 0/0, tracked/untracked clean, ignored Owner state untouched.
Worktree truth reconciled against accepted STATE (gate 016, repair_014 accepted at
dd8d92d, re-audit_015 STOP classified as evidence limitation).

BYTE_PARITY (sha256, worktree vs technical 1e6f72b, all MATCH):
Reader.swift 86ef9fa2; Writer.swift da2675b6; ReaderTests 6aaa720b; HistoryTests
893e59c8; P15 plan d3d11648; checker f98ff368. Technical==publication dd8d92d on all
four product/test paths; origin/main product bytes==technical. HEAD->origin delta is
STATE-only control plane. Control-plane commits are not product changes.

RECEIPTS: /tmp/FSD-P15-S02-Repair-RED-causal.log (83 tests/27 assertion failures/0
unexpected, causal F1/F2/F3 RED), -GREEN.log (102/102), -focused.log (103/103),
-full-debug.log (384 executed/381 pass/3 external skips/0 fail) all present on disk.
015 DerivedData holds clean-build.log exit0 and focused.log exit0 (56+28+9+10=103,
0 fail/0 skip) per CURRENT HOT. Ledger tail confirms repair_014 ACCEPTED
PASS_WITH_ADVISORY and re-audit_015 WORKER_COMPLETE_PENDING_BRAIN STOP; events chain
is gap-free. No suite was rerun here: no contradiction was discovered, and 015
forbids duplicate expensive validation without one.

FULL_LONG_CONTEXT_READ_BY_PREP_WORKER=YES (all mandatory reads above absorbed).

## Requirement / evidence map

All EVIDENCED from fresh reads, digests, Git and receipts; no material UNPROVEN
against packet completeness.

| # | Requirement | Evidence |
|---|---|---|
| 1 | Kernel/Compact/STATE/skill loaded | AGENTS, BRAIN_OPERATOR, PROJECT_STATE, task-execution read fresh |
| 2 | Product authorities absorbed | P15 Slice-02 locked decisions, ARCH 9/9a, SEC 2.1, ADR-031/032, TEST-PLAN 9 read |
| 3 | Four historical handoffs absorbed | D-012, audit-013, repair-014, re-audit-015 read in full |
| 4 | Production/tests/checker read | Reader 535 lines, Writer 512 lines, both test files, checker predicate read |
| 5 | Non-destructive reanchor | Fetch + ff-only of one BRAIN commit; 0/0 clean recorded above |
| 6 | Byte/provenance distinction | Six digests MATCH; tech==pub; control-plane delta isolated |
| 7 | 015 receipts/ledger provenance | Log files present; ledger/events tails inspected |
| 8 | Packet sections A to I | Single marked block below; size verified by wc |
| 9 | F1 flow mapped with state/identity/fail/read flags | Section B, 11 steps |
| 10 | F3 flow mapped with pin/assoc/DB/rollback flags | Section D, 9 stages |
| 11 | Proof obligations separated | Sections C/E: source vs test vs prior-audit vs unproven |
| 12 | Regression matrix with test limits | Section F: 13 tests, WHAT_IT_DOES_NOT_PROVE mandatory |
| 13 | Finding-to-repair map | Section G with exact refs and 015-still-unproven reasons |
| 14 | Challenge questions bounded | Section H: 8 logical questions, no verdict requested |
| 15 | Minimal read set bounded | Section I: 6 ranges + packet; expansion only on contradiction |
| 16 | No repair/probes/slice-03/verdict | Full diff scope holds only 4 allowlisted return paths; verdict strings absent |
| 17 | Finalizer closure | Checker + diff-check + push/fetch/parity verified at capture |

ADVISOR_PACKET_BEGIN
PKT=016. PRODUCT_BASELINE=dd8d92d(accepted pub); TECH=1e6f72b. Worktree 6/6 repair
paths==TECH==PUB; origin/main product bytes==TECH; HEAD delta STATE-only. F2=CLOSED
BY_REAUDIT_015. CHECKER=PASS_BY_REAUDIT_015. F1/F3=UNPROVEN_INDEPENDENT_CLOSURE
(evidence limitation, NOT product failure). This packet decides NOTHING.
R=FSD/Classification/BoundedClassificationSourceReader.swift.
W=FSD/Catalog/SnapshotWriter.swift. T=FSDTests/ClassificationSourceReaderTests.swift.
H=FSDTests/SnapshotHistoryTests.swift.
A. AUTHORITY CONTRACT (P15 Slice-02 locked decisions, no reinterpretation). F1: after
no-follow open + regular fstat, PRE-READ OBJECT BARRIER re-resolves exact
volume/mount identity, fresh no-follow walk from physical mount through root+parent
components, EVERY dir matched by st_dev AND st_ino, fresh final regular-file path
bound to opened fd by exact object identity. Failed check => ZERO payload reads.
Successful barrier authorizes the OPENED OBJECT, not perpetual pathname stability: a
later rename cannot redirect its fd; post-read revalidation may still return
sourceChanged. F3: alias proof retains proven object through admission: INSIDE the
existing transaction, current selected/canonical-root + physical-candidate
associations must agree with pinned identity BEFORE row insertion AND AGAIN BEFORE
accepting transaction; substitution fails capture and rolls back admission.
POINT-IN-TIME capture admission proof, NOT a namespace lock. Direct lexical
containment needs no alias I/O/proof. Legacy schema<9 fails closed (.unavailable,
no backfill). One 4096-byte prefix read max; provider gets Data only.
B. F1 CONTROL-FLOW MAP. 1:R231-238 initial detectMount(recordedMount); IN recorded
identity/mount; ID none; FAIL .unavailable/.sourceChanged; READ=NO. 2:R256-259 first
walkDirectories(expected=nil) mount->parent; IN recordedMount+dirComponents; ID
sampled walk.identities; FAIL outcome; READ=NO. 3:R261-273 statNoFollow(parent,file)
+regular+device==mountDevice; FAIL outcome; READ=NO. 4:R275-295 openRegularFile +
fstat==candidate(dev/ino)+regular; afterOpen cancel R283; FAIL outcome/cancelled;
READ=NO. 5:R300-307 validateOpenedAuthority(pre); FAIL failure (or cancelled if
beforeRead observed); READ=NO. 6:R373-375 fresh detectMount==recorded identity+mount;
FAIL .sourceChanged; READ=NO. 7:R380-383 fresh walkDirectories(expected=identities);
per-dir dev+ino equality R441-444; FAIL outcome; READ=NO. 8:R384-393 statNoFollow via
FRESH parent; regular+==opened dev/ino; FAIL outcome; READ=NO. 9:R307,312 pre-read
isCancelled(.beforeRead); FAIL .cancelled; READ=NO. 10:R310-314 SOLE readOnce (sole
Darwin.read R82-86), max4096 offset0; READ=YES first+only. 11:R319-354 post-read:
afterRead cancel, count guard, short/truncation, fstat identity, barrier AGAIN,
request build; every exit via finishAfterRead R359-361; READ already consumed. No
alternate payload path (single readOnce callsite; 015-inspected).
C. F1 PROOF OBLIGATIONS. PROVEN_BY_SOURCE: O_NOFOLLOW opens R47-57,70-74; fstat binds
open object to candidate R285-295; barrier mandatory before sole read R300-314;
post-read object+path revalidation R332-350; all post-read terminals via
finishAfterRead R315-354/359-361. PROVEN_BY_PERMANENT_TEST (RecordingFilesystem
delegates real Darwin; FileManager moves real fixtures): T602-617 acquired-parent
rename before final stat => .sourceChanged readCalls=0; T619-631 after-open-before-
barrier => 0 reads; T633-646 fresh-parent-different => 0; T648-661 fresh-final-
different => 0; T663-684 fresh-volume-mismatch on 2nd detect => 0, resolutions=2;
T686-696 unchanged barrier => 1x4096 read, 3 mountOpens/3 statNoFollow; T698-717
after-barrier move => reads ORIGINAL bytes once then .sourceChanged (fd-pinned, not
pathname-lock); T719-729 pre-payload cancel => .cancelled 0 reads.
SUPPORTED_BY_ACCEPTED_PRIOR_AUDIT: 013 F1 real-POSIX PARENT_RENAME on OLD bytes
(reads=1 outsideBytes=true) is WHY the barrier exists; repair direction (rebind +
zero-reads) implemented, never independently replayed on new bytes under Owner
no-probe mode. UNPROVEN Q-F1: fresh walk R432-446 samples directories SEQUENTIALLY
into identities then compares immutable samples; final stat R385 uses a parent fd
acquired EARLIER in the same walk. Does sequential dev/ino equality across that walk
constitute a successful-authorization point for the OPENED object covering namespace
transitions DURING the walk? Pre-barrier tests mutate BEFORE the fresh walk;
after-barrier test mutates AFTER success; NONE mutates INSIDE it. Ranges:
R297-314, R365-395, R413-446.
D. F3 CONTROL-FLOW MAP. 1:W215-227 prepareRootLocator: lexical direct remainder =>
no alias I/O; PIN none; ASSOC lexical; DB untouched; ROLLBACK n/a. 2:W230-234 alias:
SOLE realpath(selectedRoot), ONE physicalCandidate, canonicalStat; PIN none yet;
FAIL throw; DB untouched. 3:W236-247 no-follow openRootCandidate W284-298 +
stat==canonical dev/ino; PIN fd+identity in AliasRootProof; FAIL throw+close; DB
untouched. 4:W91-104 beginCapture: proof pre-write; withExtendedLifetime W101 pins
through commit/rollback; observer afterPreparation W102 (alias only). 5:W104-110 txn
opens (CatalogDatabase.transaction commits ONLY if closure returns); ensureVolume;
FIRST validateAdmission W110; PIN fd; ASSOC current; DB volume row maybe; ROLLBACK
YES. 6:W111-143 snapshot INSERT + root entry + totals; observer afterRowInsertion
W144; DB rows inside txn; ROLLBACK YES. 7:W145 SECOND validateAdmission, closure
returns => COMMIT; PIN released after; DB committed; ROLLBACK NO after return.
8:W198-212 validateAdmission: pinned fstat W200 + selected statFollowing W201 +
canonical statFollowing W202 + fresh openRootCandidate+stat W203-205; ALL==identity
dir W206-208 else sourceRootNotWithinMount; any throw => same W209-211. 9:Lifetime
end: defer W101 scope exit; deinit closes pinned fd W196.
E. F3 PROOF OBLIGATIONS. PROVEN_BY_SOURCE: single candidate derivation, no
plural/fallback W255-261; deinit-close W196; dual-validation ordering W110,145; txn
atomicity boundary W104-147; catch-all to sourceRootNotWithinMount W209-211; direct
route no-I/O W221-227. PROVEN_BY_PERMANENT_TEST (real Data-volume fixtures;
H535-546 asserts selected==physical dev/ino, never fabricated): H448-465 replace
after-proof-before-admission => throws, 0 snapshots/entries/volumes; H467-485
replace during admission => 1 snapshot+1 entry visible INSIDE txn, 0/0/0 after;
H487-507 canonical=>symlink during admission => throws+rollback; H509-519 unchanged
=> both boundaries observed, capture admitted; H521-533 direct lexical => observer
never fires, success. SUPPORTED_BY_ACCEPTED_PRIOR_AUDIT: 013 ROOT_PROOF_RACE on OLD
bytes (locatorAccepted + differentObjectAtReturn) is WHY pin+dual-validation exists.
UNPROVEN Q-F3: final validation W198-212 samples pinned/selected/canonical/physical
SEQUENTIALLY then compares. Does that comparison define a defensible POINT-IN-TIME
admission proof covering association transitions DURING that sampling? Tests mutate
at afterPreparation/afterRowInsertion -- OUTSIDE either validation. No namespace
lock may be demanded (platform gives none); formalize only what the code needs: that
post-commit rows name the PINNED object. Ranges: W100-147, W198-212.
F. REGRESSION MATRIX (F1/F3 only; F2 late-cancel tests excluded as 015-CLOSED).
F1: AcquiredParentBeforeFinalStat|F1|before-final-stat rename+outside child|REAL|
.sourceChanged+0 reads|removing rebind reads outside child|not inside-walk window.
AcquiredParentAfterOpenBeforeBarrier|F1|move on first regular fstat|REAL|0 reads|skip
rebind reads moved parent|not inside-walk window. FreshParentDifferent|F1|replace
sub/ after open|REAL|0 reads|no dir ino compare authorizes replacement|not final-
object swap. FreshFinalDifferent|F1|replace f.txt after open|REAL|0 reads|no fresh-
final compare reads replacement|not inside-walk window. FreshExactVolume|F1|2nd
detect returns OTHER identity|FAKE-detect,real-fs|0 reads+resolutions=2|no fresh
guard allows payload|not fs-object proof (own admission). UnchangedBarrier|F1|none|
REAL|1x4096,3 walks|missing walk/retry breaks counts|call counts alone prove no race.
AfterBarrierMove|F1|move after barrier success, before read|REAL|ORIGINAL bytes
once+sourceChanged|reopen-by-path reads replacement|not pre-read authorization.
PrePayloadCancel|F1|barrier success then cancel|REAL|.cancelled+0 reads|missing check
attempts payload|not late-cancel ordering (F2). F3: BeforeAdmission|F3|replace
candidate at afterPreparation|REAL|throws+0/0/0 rows|drop 1st check admits stale
locator|not inside-validation window. DuringAdmission|F3|replace at
afterRowInsertion|REAL|1+1 rows inside, 0/0/0 after|drop 2nd check commits
replacement|not inside-validation window. CanonicalReplaced|F3|canonical=>symlink at
afterRowInsertion|REAL|throws+rollback|skip current-assoc check admits|not pinned-fd
sufficiency. UnchangedAdmits|F3|none|REAL|both boundaries+rows|reject valid identity
breaks it|proves ordering, not race-freedom. DirectLexical|F3|missing child|REAL|
success+observer never fires|alias-gating direct fails|no alias claim at all.
G. FINDING->REPAIR. F1: ORIG=013 PARENT_RENAME receipt (outcome=sourceChanged
reads=1 outsideBytes=true; old Reader L256/263/277/293/301/348-366). REPAIR=
validateOpenedAuthority R365-395 + pre/post calls R300-307,R344-350 + zero-read
failure mapping + pre-payload cancel R307,312; 8 regressions T602-729. 015-STILL-
UNPROVEN: internal fresh-walk window Q-F1. F3: ORIG=013 ROOT_PROOF_RACE
(locatorAccepted+differentObjectAtReturn; old Writer L93/186-191/233/241-242).
REPAIR=AliasRootProof pinned fd W177-196 + dual validateAdmission W110,145 +
withExtendedLifetime W101; 5 regressions H448-533. 015-STILL-UNPROVEN: internal
final-sampling window Q-F3.
H. ADVISOR CHALLENGES (answer none here). 1: At which exact statement does F1
authority become sufficient -- R307 fall-through, R312, or R314? 2: Which F1 facts
are PINNED (fd+fstat R285-295) vs SAMPLED (identities R419-446, confirmed R385)? 3:
Can a transition between two samples INSIDE the fresh walk R432-440 survive the
later dev/ino comparison R441-444 undetected? 4: Does the final stat's use of a
parent fd acquired earlier in the same walk reopen Q-F1 recursively? 5: At which
exact statement is F3 admission irrevocable -- W145 return or txn-closure return
W147? 6: Which F3 facts are PINNED (fd W182-183) vs SAMPLED (W200-205)? 7: Can a
transition between selected-sample W201 and physical-sample W203-205 leave all four
equal to identity yet commit rows naming a different object? 8: What minimal extra
SAMPLING (never locking) would close Q-F1/Q-F3, and which existing seam
(RecordingFilesystem hooks; admission observer) could schedule it?
I. MINIMAL PREMIUM READ SET (packet + 6 ranges; expand ONLY on concrete
contradiction). 1:R297-314 barrier-success to sole read (Q-F1 statement point).
2:R365-452 fresh binding + walk equality (unproven window). 3:W100-147 dual-
validation ordering + proof lifetime (Q-F3 commit point). 4:W198-212 final sampling
sequence (unproven window). 5:T686-729 positive barrier + after-barrier + pre-
payload cancel (F1 test limits). 6:H448-533 all five admission regressions (F3 test
limits). Do NOT preload: full P15/ARCH/SEC/DECISIONS/TEST-PLAN, four handoffs, full
test files, F2 tests, checker mechanics.
ADVISOR_PACKET_END

## Completion

PACKET_COMPLETE=YES. ADVISOR_PACKET_PRESENT=YES. Packet size verified within limit
by wc at capture. F1_CONTROL_FLOW_MAPPED=YES. F3_CONTROL_FLOW_MAPPED=YES.
TEST_LIMITS_EXPLICIT=YES. UNPROVEN_QUESTIONS_EXPLICIT=YES.
MINIMAL_PREMIUM_READ_SET=6_RANGES. SECURITY_VERDICT_ISSUED=NO. PRODUCT_MUTATION=NONE.
No follow-on work was started. No custom probes, no Slice 03, no verdict strings in source.

Single proposal (in HOT above) is FSD_P15_RUNTIME_SLICE_02_SECURITY_ADVISOR_017; it is
a proposal only and was not started.
