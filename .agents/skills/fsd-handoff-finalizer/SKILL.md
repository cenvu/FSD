---
name: fsd-handoff-finalizer
description: Finalize one authorized FSD Worker cycle with immutable handoff, full CURRENT mirror, Worker ledger/event projection, Desktop recovery transport and verified Git publication. Use when FSD work requires a handoff or Worker return.
---

# FSD handoff finalizer

Read root AGENTS.md and the relevant stable rules in docs/BRAIN_OPERATOR.md;
docs/AGENT.md remains the deep reference. Resolve paths from the physical FSD
Git root. This is the sole current FSD handoff procedure; historical procedures
and references remain immutable evidence. Finalization does not authorize scope
expansion, product work, semantic repair or BRAIN acceptance.

Prerequisite: [fsd-task-execution](../fsd-task-execution/SKILL.md) has completed
fresh execution postflight on the already-reviewed candidate. Load that skill for
the provider-neutral execution discipline and exact Worker guard contract; do not
duplicate or bypass it here. The finalizer only validates, projects and publishes
that candidate. It must not repair execution scope. A discovered execution defect
returns to task-execution within the existing authorization and retry budget, or
to BRAIN if unresolved. Finalization never supplies missing semantic evidence.

## Re-anchor and prepare

1. Fetch the configured canonical upstream non-destructively. Record root,
   origin, branch, local/upstream HEAD, ahead/behind, verification time and status.
   Preserve owner dirty/untracked/ignored state; reconcile unexpected drift or
   stop. Never reset/clean/stash/rebase/merge to force a baseline. Capture the
   task's full base SHA, exact allowed paths and prior historical bytes before
   editing. Record command outcomes truthfully; no invented tests or review.
2. Read accepted STATE/PROJECT_STATE.md, the task's TASK_LEDGER row, CURRENT HOT
   and exact task/direct authorities. Worker writes evidence and proposals only.
   Preserve accepted state, other task rows and BRAIN_CLASSIFICATION. For a new
   Worker task use PENDING_BRAIN, even when its Worker-local checks pass. If BRAIN
   has adjudicated between base and return, re-anchor and reconcile first.
3. Decide one unused flat path
   handoffs/FSD_<CASE>_<ROLE>_<YYYYMMDD-HHMMSS>.md using local timezone. Create
   exactly one immutable historical file per meaningful Worker cycle. No SHORT/
   FULL pair, nested/session directory, separate report, per-task state directory
   or checksum sidecar. RAW stays reference-first in existing ignored scratch
   when useful; essential recovery evidence belongs in the handoff.

## Write and project one return

4. Validate implementation within the exact authorized scope, then compose the
   complete technical record in that single historical handoff: HOT identity,
   Git/freshness snapshot, scope, input refs, concrete delta, verified commands,
   validation limits, ownership, remaining issues, proposed state delta and
   exactly one PROPOSED_NEXT. Include exactly one contiguous Worker execution guard
   from task-execution, truthful requirement counts and NEXT_TASK_STARTED=NO.
   PASS/PASS_WITH_ADVISORY cannot finalize with material UNPROVEN requirements:
   the guard must have UNPROVEN=0, PREFLIGHT=PASS and POSTFLIGHT=PASS. Never author
   BRAIN review/classification/accepted
   state/active-next. Check the complete content before creating the immutable
   file; a validation failure after creation is a blocker to report, not license
   to rewrite history. Use actual prepublication HEAD/time in HOT. Its own future
   publication SHA cannot appear inside an immutable self-containing record.
5. CURRENT bytes = `UPDATED_AT: <local ISO timestamp with timezone>` + LF + blank
   line + the complete historical bytes. Set the task's Worker-owned ledger
   fields: STATUS=WORKER_COMPLETE_PENDING_BRAIN (or truthful incomplete status),
   SCOPE, EXECUTOR, known TECHNICAL_SHA, WORKER_RESULT, HANDOFF and concise NOTE.
   Preserve BRAIN_CLASSIFICATION=PENDING_BRAIN. TECHNICAL_SHA is a known captured
   implementation/basis commit; NOTE distinguishes basis from publication. Resolve
   publication with `git log -1 --format=%H -- <handoff>` after commit; do not
   create a second bookkeeping commit solely to insert a self-referential SHA.
6. Append one worker_return JSON object to STATE/EVENTS.jsonl with ts (timezone),
   actor=WORKER, event_type=worker_return, task_id, truthful result, commit=null
   if publication is not yet known, ref=the handoff path and short note. Never
   rewrite/reorder earlier lines, fabricate BRAIN events or duplicate the same
   return. Leave PROJECT_STATE's accepted decision untouched. BRAIN performs its
   later deterministic post-adjudication STATE projection under Compact policy.

## Desktop full recovery transport

7. Refresh ~/Desktop/04_FSD_BRAIN.md using the established packet envelope: HOT,
   actual Git receipt, Worker evidence/proposal, dated prior BRAIN fields clearly
   distinguished from new acceptance, compact accepted STATE projection/pointers,
   exact canonical Operator and full CURRENT recovery copy. Preserve existing
   BRAIN-owned bytes unless an explicit BRAIN directive supplies replacement.
   Keep full ledgers/events in the repo; include the four STATE paths, accepted
   state's provenance and accepted-head pointer for reconstruction. Desktop is
   transport, not authority. Product authority remains its repository pointers.
8. Embed docs/BRAIN_OPERATOR.md's raw bytes immediately after the unique LF line
   `# BRAIN OPERATOR BEGIN` and before `# BRAIN OPERATOR END`. Include canonical
   trailing LF; add no wrapper/blank/newline conversion. Outside payload record
   BRAIN_OPERATOR_PATH=docs/BRAIN_OPERATOR.md, VERSION as BRAIN_OPERATOR_VERSION,
   SHA-256 of exact bytes as BRAIN_OPERATOR_SHA256 and
   BRAIN_OPERATOR_PROJECTION=EXACT. Keep volatile state outside this payload.

## Check, publish, verify, stop

9. Run scripts/check_control_plane.py from the repo with --task-id, --base (full
   captured SHA), --expect-branch and --expect-origin, plus one --allow-path per
   exact authorized path, including the one chosen handoff. Do not widen the
   allowlist on failure. The checker is read-only and never fetches or accepts
   semantic decisions. It reports local Git/fetch receipt freshness; fetch is
   this procedure's responsibility. Supply --max-fetch-age-seconds when needed
   (default 900). Run git diff --check and verify prior historical bytes and
   protected product/schema/test paths. Checker PASS means mechanics only.
10. Commit only authorized task paths; publish only when task authorization
    permits. Push the expected branch explicitly, fetch again, reconcile remote
    movement and require 0/0 plus primary clean when the task's clean-baseline
    contract permits. Preserve preexisting dirty owner state for tasks that
    explicitly allow it; never stage it. Refresh Desktop's final Git receipt,
    preserving the immutable historical record. Re-run checker with
    --require-clean --require-synced for clean publication tasks. On a failed
    push/fetch/parity/scope check, report the truthful blocker; never claim success.
    Final verification must freshly inspect physical HEAD/upstream, diff/status,
    exact artifacts and Desktop parity after push/fetch. A timeout or lost network
    acknowledgement is AMBIGUOUS_RECOVERY: fetch and reconcile the actual remote
    branch before considering a retry. Never issue a blind second push; unresolved
    delivery or material drift returns evidence to BRAIN. Confirm NEXT_TASK_STARTED=NO.

Return only TASK, worker-local RESULT, one dense verifiable WHAT, and
`BRAIN=SEND FILE=/Users/cenvu/Desktop/04_FSD_BRAIN.md`; optionally at most five short
material evidence lines. End exactly `NEW HANDOFF!!!`. Human explanation belongs
to BRAIN. STOP; do not execute the proposal or a next-next task.
