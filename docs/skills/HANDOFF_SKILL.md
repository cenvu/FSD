---
id: a4c.handoff
name: A4C Handoff
version: 0.1.0
type: universal-skill
status: active
default_load: false
compatible_roles:
  - writer
  - reviewer
  - researcher
  - tester
  - documentation
---

# A4C Handoff Skill

## Purpose

Create one compact AI-to-AI handoff that lets the next agent continue without rereading the whole repository.

A handoff is a continuity artifact, not a user-facing report and not a full project archive.

Use this Skill when:

- Work will continue in another agent session.
- The current session changes project state.
- A blocker, decision, test result, or unfinished operation must be preserved.
- Cen explicitly requests a handoff.

Do not create a handoff for a trivial answer that changes no project state.

## Core Rules

1. Create exactly one canonical handoff per task session.
2. Record verified state only.
3. Separate completed work from planned work.
4. Do not claim a test ran unless it actually ran.
5. Do not claim independent review when the current agent wrote the implementation.
6. Do not embed large logs, full source files, repository trees, or historical reports.
7. Reference paths instead of copying artifact contents.
8. Include exactly one next action.
9. Keep the handoff useful without forcing the next agent to open unrelated files.
10. Do not read all historical handoffs. Read `CURRENT.md`, then only the referenced handoff.

## Canonical Location

Use one directory for each task session:

```text
AI_HANDOFFS/<YYYY-MM-DD>/SESSION_<SESSION_ID>/
```

Recommended filename:

```text
H_<CASE_CODE>_<ROLE_CODE>_<MMDDHHMMSS>.md
```

Role codes:

- `C` — Writer / Coding
- `R` — Reviewer
- `T` — Tester
- `D` — Documentation
- `L` — Research / Log
- `F` — Forge / Build, only when the project defines this role

Example:

```text
AI_HANDOFFS/2026-08-03/SESSION_A4C_INIT/H_A4C_C_0803171500.md
```

A checksum sidecar is optional and must not be added unless the project has a real integrity requirement.

## CURRENT Pointer

A project may keep:

```text
AI_HANDOFFS/CURRENT.md
```

`CURRENT.md` must be a short pointer, not a copy of the full handoff.

Recommended format:

```markdown
# Current Handoff

Handoff: [H_A4C_C_0803171500.md](2026-08-03/SESSION_A4C_INIT/H_A4C_C_0803171500.md)
Task: Initialize minimal A4C scaffold
Status: COMPLETE
Updated: 2026-08-03T17:15:00+07:00
```

## Required Handoff Structure

```markdown
# Handoff

## Identity
- Project:
- Task:
- Case code:
- Role:
- Agent / model:
- Session ID:
- Started:
- Completed:

## Status
`COMPLETE`, `COMPLETE_WITH_KNOWN_LIMITATIONS`, `PARTIAL`, `BLOCKED`, or `REVIEW_REQUIRED`

## Repository State
- Root:
- Branch:
- Commit:
- Git status:
- Pre-existing user changes:

## Objective
One concise statement of the requested outcome.

## Inputs Read
Only files and sources that materially affected the work.

## Work Completed
Concrete completed actions.

## Files Changed
Created, modified, moved, or deleted files.

## Commands and Tests
- Command:
- Result:
- Evidence or relevant output:

## Decisions
Important choices and why they were made.

## Constraints Preserved
Protected paths, user requirements, safety boundaries, and explicit non-goals.

## Known Issues
Unresolved defects, unverified behavior, or follow-up risks.

## Exactly One Next Action
One executable next step.

## Resume Context
Optional concise instruction for the next agent.
```

## Status Definitions

### `COMPLETE`

The requested task is finished and relevant validation passed.

### `COMPLETE_WITH_KNOWN_LIMITATIONS`

The requested outcome is usable, but clearly stated non-blocking limitations remain.

### `PARTIAL`

Some requested work is complete, but the task is not finished.

### `BLOCKED`

Work cannot safely continue without a missing dependency, decision, permission, or environment.

### `REVIEW_REQUIRED`

Implementation is complete enough for an independent reviewer, but the Writer must not self-certify it.

## Context Budget

A normal handoff should be concise.

Recommended target:

- 500–1,500 words
- Fewer than 20 referenced paths when practical
- No raw logs longer than a short relevant excerpt
- No duplicated task packet or full documentation

When detail is large, store it in a dedicated project artifact and reference its path.

## Completion Checklist

Before publishing a handoff, verify:

- [ ] The repository path is exact.
- [ ] The role is accurate.
- [ ] Completed and incomplete work are separated.
- [ ] Changed files are listed.
- [ ] Tests are reported truthfully.
- [ ] User changes were preserved.
- [ ] Known issues are explicit.
- [ ] There is exactly one next action.
- [ ] The next agent can resume without reading the whole repository.
- [ ] `CURRENT.md` points to the new canonical handoff when required.

## User-Facing Completion Summary

The final response to Cen should normally remain short:

```text
Status
What changed
Tests run
Known limitations
Next action
Handoff path
```

Do not paste the full handoff into the user-facing response unless Cen asks for it.
