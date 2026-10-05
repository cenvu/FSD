# P15 Slice 02 compact premium security advisor (Q-F1 + Q-F3)

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_P15_RUNTIME_SLICE_02_SECURITY_ADVISOR_R_20261005-114500.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=9f62f12478a1bbb04238d3996241b35275332443
REMOTE_HEAD=9f62f12478a1bbb04238d3996241b35275332443
LAST_VERIFIED_AT=2026-10-05T11:45:00+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|STATE/PROJECT_STATE.md|handoffs/FSD_P15_RUNTIME_SLICE_02_SECURITY_PROOF_PACKET_D_20261005-112148.md|handoffs/FSD_P15_RUNTIME_SLICE_02_SECURITY_REAUDIT_R_20261005-032259.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_P15_RUNTIME_SLICE_02_SECURITY_ADVISOR_017
STATUS=ADVISOR_COMPLETE_F1_F3_CLOSED_WITH_ADVISORY_PENDING_BRAIN
BLOCKER=NONE
PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_FSD_P15_SLICE_02_SECURITY_ADVISOR_ADJUDICATION
NO_AUTO_NEXT=YES

## Task lock / execution guard

TASK_ID=FSD_P15_RUNTIME_SLICE_02_SECURITY_ADVISOR_017
ROLE=REVIEWER
MODE=COMPACT_PREMIUM_SECURITY_ADVISOR;SEMANTIC_SOURCE_REVIEW_ONLY
BASE_HEAD=9f62f12478a1bbb04238d3996241b35275332443
UPSTREAM_HEAD=9f62f12478a1bbb04238d3996241b35275332443
PREFLIGHT_LOCAL_HEAD=5f9f202ec8103467866e0deaad66d274ad07ca50
REPAIR_TECHNICAL_SHA=1e6f72b8f329fff5fe54234037b3af3d02e803ed
ACCEPTED_PUBLICATION_SHA=dd8d92d435684204da2b359acdff527757465521
ACCEPTED_PACKET_PUBLICATION=5f9f202ec8103467866e0deaad66d274ad07ca50
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=Q-F1_AND_Q-F3_SEMANTIC_RECOMMENDATION_ONLY;NO_PRODUCT_MUTATION;NO_CUSTOM_PROBES;NO_SLICE_03
ALLOWED_PATHS=handoffs/FSD_P15_RUNTIME_SLICE_02_SECURITY_ADVISOR_R_20261005-114500.md|handoffs/CURRENT_HANDOFF.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl
FORBIDDEN_PATHS=SWIFT_TEST_DOC_CHECKER_SCHEMA_XCODE;STATE/PROJECT_STATE.md;STATE/RULE_PROMOTION_LEDGER.tsv;HISTORICAL_HANDOFFS
SUCCESS_CRITERIA=F1_RECOMMENDATION;F3_RECOMMENDATION;INVARIANT_COUNTEREXAMPLE_MISSING_FACT_FIELDS;PACKET_PLUS_SIX_RANGES_DEFAULT
VALIDATIONS=DIRECT_SOURCE_READS;GIT_REANCHOR;REPAIR_BYTE_DIFF;FINALIZER_CANONICAL_CHECKER
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
WORKER_RESULT=PASS_WITH_ADVISORY
RESULT_AUTHORITY=REVIEWER_RECOMMENDATION_ONLY_NOT_BRAIN_ACCEPTANCE

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=13
WORKER_REQUIREMENTS_EVIDENCED=13
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

## Recommendation (advisory; BRAIN adjudicates)

F1_RECOMMENDATION=CLOSED
F1_DECISIVE_INVARIANT=Opened object X is pinned by fd, so dev+ino cannot be recycled while open. The barrier derives a fresh fd chain (mount root, then openat O_NOFOLLOW per component, all fds held) and the final fstatat through the last pinned parent fd must return regular dev+ino == X (R385-388). That link is the authorization point; R394 return nil, then R307/R312 cancel checks, then the sole read R314. Authority is capability derivation from the selected-root fd chain, not instantaneous path simultaneity.
F1_COUNTEREXAMPLE=NONE under the accepted standard. A strictly-simultaneous-chain schedule exists (see advisory A1) but grants no privilege or effect beyond in-tree placement.
F1_MINIMUM_MISSING_FACT=NONE

F3_RECOMMENDATION=CLOSED
F3_DECISIVE_INVARIANT=Committed root_relative_path is exactly components.joined("/") (W247). The final validateAdmission (W145) ends with a fresh no-follow walk of those same components (W203-205), the last of four samples, required == pinned P identity (fd held, so non-recyclable). Failure throws inside the txn closure, so rollback. COMMIT follows closure return (W146-147), and later drift is indistinguishable from post-commit drift, which the contract accepts. A different object cannot pass the physical sample; selected/canonical samples only corroborate user intent and are not part of the committed string.
F3_COUNTEREXAMPLE=NONE under the accepted standard. A selected-root flip after sample W201 yields a committed physical locator still naming P, equivalent to post-proof drift.
F3_MINIMUM_MISSING_FACT=NONE

RECOMMENDATION=PASS_WITH_ADVISORY (F1=CLOSED AND F3=CLOSED, no material contradiction, bounded nonblocking caveats below).

## Reanchor / provenance

FACT: preflight local main 5f9f202 was one commit behind canonical origin/main 9f62f12 (BRAIN state-only commit accepting packet 016 and authorizing 017: STATE/EVENTS.jsonl, STATE/PROJECT_STATE.md, STATE/TASK_LEDGER.tsv). Worktree was clean, so `git merge --ff-only origin/main` applied that existing commit with no reset, clean, stash, rebase, force or discard. Post-sync HEAD=origin/main=9f62f12, AHEAD=0, BEHIND=0, status empty. Ignored Owner state untouched.
FACT: `git diff 1e6f72b..HEAD` over the four product/test paths is empty, so the repair source bytes still equal the technical basis named in the packet. Source and packet agree; no packet/source contradiction found.
Read set: ADVISOR_PACKET_BEGIN..END (packet L108-252), the six named ranges (R297-314, R365-452, W100-147, W198-212, T686-729, H448-533) and ONE context expansion (see below).

## Q-F1 reasoning

PINNED by fd: the opened regular-file object X (fstat dev+ino at open, bound to candidate); every directory fd in the fresh walk (bag holds all until defer closeAll R378); the final parent fd.
SAMPLED: mount-volume identity (detectMount, R373-375, by path); first-walk directory identities (expected[]); each name→object link (one openat/fstatat each) at its own instant.
ORDER: detectMount, then openMountRoot(path), then c1..cn each openat(parent_fd, name, O_NOFOLLOW)+fstat, then dev+ino equality vs first-walk identities (R441-444), then fstatat(last_parent_fd, file, NOFOLLOW) must equal X (R385-388).
Final stat through a parent fd acquired earlier in the same walk is not recursive uncertainty. That fd pins directory D_n, so its entry table is the authority for "name→X", and X is pinned so the equality identifies the live same object. A rename of D_n or an ancestor after fd acquisition cannot redirect the fd; it can only detach D_n from the root, which is the one residual (A1).
Logical attempt: for the opened object to pass, X must be the object at D_n/name at final stat, and D_n must be the object reached by the descriptor chain from the root fd with each link identical to the first walk. A different or foreign object fails dev+ino at some link; inode recycling is excluded because the compared fresh objects are fd-held during compare and X is fd-held throughout. The only schedule that passes while the chain is never simultaneously whole is: detach an ancestor after the sample that crossed it, then re-link below it before the next sample (A1). Everything it can make pass is an object whose directories and file already matched the first walk.
The authorization point is R385-388 success (with R394 return nil). After that, perpetual stability is not required; the post-read fstat plus barrier-again at R332-350 can still downgrade to sourceChanged.
Test role: T686-729 proves ordering, 1 read x 4096, fd-pinned after-barrier behavior and pre-payload cancel. They do not mutate inside the walk. That is a test limit, not a product defect, because the standard derived above is capability derivation, not instant simultaneity.

## Q-F3 reasoning

PINNED by fd: P (fd W182-183, deinit-close W196; lifetime held by use inside the txn closure and by W101 extended-lifetime across commit/rollback).
SAMPLED in order (W200-205): pinned fstat (confirms fd still valid object), selected statFollowing, canonical statFollowing, fresh no-follow physical candidate walk + fstat (last).
Commit string is components.joined(), derived once (W232, W247) and re-validated by the same `components` in the final physical sample, so the committed locator and the last sample talk about the same path.
Commit point: after validateAdmission returns at W145 and the closure returns at W146, the SQLite transaction wrapper issues COMMIT (W104-147; commit only if closure returns, rollback on throw per packet D5/D7 and tests H467-485). The gap from the last sample to COMMIT is not distinguishable from post-commit drift.
Logical attempt: committed row naming a different object requires physical path to resolve to Q != P at the committing sample; that fails dev+ino and throws. Selected-root flip between W201 and W203 leaves the committed physical path naming P and only changes where the user's alias points afterward. Canonical flip is caught at W202 if it precedes it; after it, same as post-proof drift. The earlier 013 ROOT_PROOF_RACE (locatorAccepted + differentObjectAtReturn) required a single early check with no re-validation after row insertion; both boundaries are now validated, tests H448-519 cover both.
Test role: H448-533 are concrete schedules (before admission, during admission, canonical replaced, unchanged, direct lexical). They do not mutate inside validateAdmission; not required for the point-in-time contract.

## Advisories (bounded, nonblocking)

A1: Instant-vs-interval caveat for both descriptor-relative walks (F1 R432-440, F3 W203/openRootCandidate). Each link is verified through a pinned parent in sequence; the walk is not an instantaneous snapshot (same as kernel path lookup). A writer with rename rights could in principle detach an ancestor after it was crossed and relink beneath it before the next link, so the chain is never simultaneously whole, yet every object still matches the first walk and the pinned object. It needs strictly more rename privilege than simply placing the object in-tree and grants no new reach, and no fs primitive makes it atomic. Not recommending repair. Residual evidence gap: no test mutates inside either walk (consistent with no-custom-probe mode).
A2: Mount-volume identity is path-sampled (detectMount R373-375) and openMountRoot(path) is a separate path open. Root fd st_dev is compared only against first-walk root identity, not against the recorded volume identity. Defeating this requires privileged mount manipulation (outside source-write threat model). Observed from the named ranges only; wider authority not read.
A3: Reader first-walk bag lifetime was not read (outside ranges). It is not needed for F1 closure, which rests on the fresh chain plus X, but the cross-check against first-walk identities would be weaker than stated if those fds were closed before the barrier. Not material to the decision.

## Context expansion

CONTEXT_EXPANSION_REQUIRED=FSD/Catalog/SnapshotWriter.swift:168-197 and 213-300 (one contiguous expansion pass). Reason: F3 invariant depends on `relativePath` being the same `components` re-validated at W203, plus proof lifetime and pinned-fd deinit. Confirmed: W232/W247 derive components once, W246-247 pass them to both AliasRootProof and the committed relativePath, W177-196 shows pinned descriptor with deinit close. One expansion, within the two-expansion limit. CONTEXT_PACKET_INSUFFICIENT not invoked.

## Requirement / evidence map

| # | Requirement | Evidence |
|---|---|---|
| 1 | Load task-execution and independent-review skills (REVIEWER) | Both SKILL.md read in full at start |
| 2 | Reanchor, ff-only, 0/0, clean, preserve Owner state | Git receipts above; no reset/clean/stash/rebase/force |
| 3 | Repair bytes still match technical basis | git diff 1e6f72b..HEAD empty on four product/test paths |
| 4 | Packet BEGIN..END only | L108-252 read |
| 5 | Six ranges read | R297-314, R365-452, W100-147, W198-212, T686-729, H448-533 |
| 6 | Q-F1 answer with invariant/counterexample/missing fact | Recommendation section and Q-F1 reasoning |
| 7 | Q-F3 answer with invariant/counterexample/missing fact | Recommendation section and Q-F3 reasoning |
| 8 | Expansion within limit | One contiguous SnapshotWriter expansion |
| 9 | No custom probes/mutation/tests rerun | No Swift/test/doc/checker/schema edits; no tests run |
| 10 | Test evidence not treated as universal proof | Test-role paragraphs; A1 evidence gap |
| 11 | Mutation allowlist | Only handoff, CURRENT, ledger, events, Desktop |
| 12 | Single handoff via finalizer, NEXT_TASK_STARTED=NO | This file; guard above |
| 13 | Recommendation is not acceptance | RESULT_AUTHORITY line; BRAIN adjudicates |

## Completion

ADVISOR_COMPLETE=YES. F1=CLOSED. F3=CLOSED. PRODUCT_MUTATION=NONE. CUSTOM_PROBES=NONE. SLICE_03_STARTED=NO. NEXT_TASK_STARTED=NO.
Single proposal: RETURN_TO_BRAIN_FOR_FSD_P15_SLICE_02_SECURITY_ADVISOR_ADJUDICATION (proposal only; not started).
