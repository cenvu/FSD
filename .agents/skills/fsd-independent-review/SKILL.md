---
name: fsd-independent-review
description: Perform a read-only, risk-first independent FSD review of Worker claims/diffs or architecture, schema and security boundaries, including explicit Owner/BRAIN review requests. Verify evidence and recommend bounded repair without authorizing or applying it.
---

# FSD independent review

READ_ONLY=YES

Load [fsd-task-execution](../fsd-task-execution/SKILL.md) with ROLE=REVIEWER.
Its preflight, failure limits, MCP boundary, fresh postflight and single handoff
guard apply equally to every model/harness. Review skill use does not turn an
implementer's self-check into independent review. Preserve separation required by
the exact task and `docs/AGENT.md`; BRAIN owns acceptance and repair authorization.

## Inputs and scope

Require precise REQUIREMENTS, BASE_SHA, HEAD_SHA, CHANGED_PATHS and
DIRECT_AUTHORITIES. Verify identities/diffs against the physical repository and
accepted STATE. Reconcile a moving target before conclusions. Read the exact
requirements, relevant source and tests; do not preload the implementer's session
history or private reasoning. Missing material review inputs remain UNPROVEN.

Read-only review allows inspection and explicitly authorized isolated validation.
It does not allow production repair, fixture weakening or owner-state mutation.
An authorized review return may write only its scoped handoff/CURRENT/Worker
ledger/event and Desktop projections through the canonical finalizer; this is
reporting, not permission to change reviewed artifacts.

## Review risk first

Trace changed inputs, callers, state transitions and failure paths against these
FSD priorities; state which apply and which were outside the review:

1. Source read-only invariants.
2. Default metadata-only scanner boundaries.
3. Snapshot immutability and completion truth.
4. Interruption/recovery correctness.
5. Schema, migration and data compatibility.
6. Root, symlink and source-identity escape.
7. Comparison semantics and Content Not Verified disclosure.
8. Cancellation, races and resource disposal.
9. Bounded memory and large-tree behavior.
10. Classification bounded reads, privacy and provider authority.
11. Dependencies, licenses and packaging changes.
12. MCP, tool, network and credential boundaries.
13. False PASS from stale or partial evidence.
14. Scope widening and unrelated cleanup.

Review tests for falsifiability and causal sensitivity: identify the plausible
production regression each test catches and inspect whether RED failed for the
intended reason. A green subset does not prove a required broader suite. Exercise
adversarial cases only within the authorized isolated validation scope.

Worker reports, checker PASS, OCR output, compiler success and test success each
have bounded meaning. None automatically establishes architecture acceptance.
Distinguish directly observed FACT, STRONG_INFERENCE and UNPROVEN. Do not invent
findings to fill a list; an empty finding set must still state coverage and limits.

## Findings and feedback reception

For each material finding record:

```text
SEVERITY
EVIDENCE
BLAST_RADIUS
WHY_EXISTING_TESTS_OR_EVIDENCE_DO_OR_DO_NOT_CATCH_IT
SMALLEST_REPAIR_DIRECTION
```

Cite exact paths/lines or reproducible observations and prioritize by risk.
External reviewer/OCR advice is not truth. Before recommending implementation:
READ → UNDERSTAND → VERIFY AGAINST FSD → EVALUATE → ACCEPT OR PUSH BACK TECHNICALLY.
Explain disagreements using repository facts. A Reviewer never authorizes its
own repair; return the smallest repair direction to BRAIN.

## Open Code Review boundary

FSD has no current pinned OCR wrapper. Do not install OCR, configure an OCR-side
LLM, create `.opencodereview`/MCP configuration or apply automatic fixes through
this skill. OCR absence is not a blocker for FSD independent review.

If a future exact task separately authorizes OCR, prefer the reviewed
LOOP_ROUTER-style delegation concept: deterministic file/exclusion/rule selection
→ host FSD Reviewer reasoning. Verify that task's tool/version/transport and
allowlist under fsd-task-execution first. Account for every selected file as
reviewed or skipped with a reason. OCR remains advisory; it does not obtain
acceptance authority, hidden provider configuration or permission to mutate.

## Return

Complete fsd-task-execution postflight and guard; use
[fsd-handoff-finalizer](../fsd-handoff-finalizer/SKILL.md) for an authorized return.
Report findings, evidence coverage and unresolved requirements as Worker evidence.
PASS/PASS_WITH_ADVISORY cannot hide a material UNPROVEN review requirement.
Return exactly one proposal to BRAIN and STOP; do not begin repair or product work.

## Design provenance

Original FSD adaptation of LOOP_APP lapp-adversarial-review, evidence/debug/context
and verification-before-completion; LOOP_ROUTER task-execution-v1, generalized
GEMINI_ENFORCEMENT, loop-adversarial-review/evidence/debug, curated ECC skills,
open-code-review-delegate and SKILL_POLICY. writing-for-agents informs narrow
activation/pointers; FSD authority and independent-review rules remain controlling.

- [ECC](https://github.com/affaan-m/ecc/tree/ef648e01899ba3e8dc6371642deaaf64b4477775)
  — reviewed pin `ef648e01899ba3e8dc6371642deaaf64b4477775`: security, causal tests,
  context and bounded verification; no imported coverage quotas or hooks.
- [Superpowers](https://github.com/obra/superpowers/tree/8ca22dba9a94f28898bbce59f2537ff4d87c747d)
  — reviewed pin `8ca22dba9a94f28898bbce59f2537ff4d87c747d`: root-cause investigation,
  fresh evidence and technical evaluation of review feedback.
- [Open Code Review](https://github.com/alibaba/open-code-review/tree/a758d9cbfb689937c7857ad64b2dd66adb58c0c2)
  — reviewed pin `a758d9cbfb689937c7857ad64b2dd66adb58c0c2`: deterministic delegation
  and coverage accounting, with host reasoning and advisory-only conclusions.
- [Karpathy Guidelines](https://github.com/multica-ai/andrej-karpathy-skills/tree/2c606141936f1eeef17fa3043a72095b4765b9c2)
  — reviewed pin `2c606141936f1eeef17fa3043a72095b4765b9c2`: challenge assumptions,
  constrain repair scope and require observable success.

ECC/Superpowers declare MIT, Karpathy skill frontmatter declares MIT and OCR
declares Apache-2.0. Upstream rights remain with their authors; no upstream files,
wrappers or configuration are vendored or installed by this skill.
