---
id: a4c.model-suggestion
name: A4C Model Suggestion
version: 0.1.0
type: universal-skill
status: active
default_load: false
depends_on:
  - a4c.model-routing-rule
---

# A4C Model Suggestion Skill

## Purpose

Recommend a practical primary model, alternative model, and harness for Cen’s current task.

This Skill applies the Model Routing Rule to the tools currently available to Cen. It provides a recommendation only. It does not launch multiple agents, install tools, or change system configuration.

Use this Skill when:

- Cen asks which model or harness to use.
- A task packet needs a routing recommendation.
- A Writer and independent Reviewer must be separated.
- Token, speed, privacy, or context materially affect execution.

Do not load it when the model and harness are already selected.

## Known Working Environments

Cen commonly works with:

- Claude Code
- Codex CLI
- Gemini CLI
- Antigravity IDE
- VS Code
- DeepSeek-compatible CLI harnesses
- Local models on Apple Silicon or NVIDIA GPU

This is operational context, not a permanent ranking. Concrete model names and versions may change and should be verified when that difference materially affects the recommendation.

## Suggestion Method

### Step 1 — Identify the role

Choose one:

- Writer
- Reviewer
- Researcher
- Tester
- Documentation

### Step 2 — Rate the task

Record:

- Scope: narrow / medium / broad
- Risk: low / medium / high
- Context: selected files / module / repository / external research
- Work type: implementation / review / research / planning / automation / document
- Tool needs
- Token sensitivity
- Time sensitivity
- Privacy requirement
- Independent review requirement

### Step 3 — Choose a capability category

Select one primary category from the Model Routing Rule:

- Strong Repository Writer
- Focused Patch Writer
- Independent Reviewer
- Large-Context Researcher
- Low-Cost Mechanical Worker
- Local / Private Worker

### Step 4 — Map to the available stack

Use the following defaults unless the task provides stronger evidence.

## Practical Defaults for Cen

### Claude Code

Suggest when:

- The task is complex repository implementation.
- Many files interact.
- Constraint following matters.
- Refactoring or architecture-sensitive work is required.
- A long interactive coding session is justified.

Avoid as the first choice for cheap inventory, simple mechanical work, or an unscoped noisy repository.

### Codex CLI

Suggest when:

- The task is a focused code change.
- Git diff and exact repository work matter.
- CI, tests, review, or patch quality are central.
- An independent technical review is needed.
- CLI consistency matters.

Use a stronger reasoning configuration for architecture and review, and a faster configuration for small patches.

### Gemini CLI

Suggest when:

- CLI consistency matters.
- The task needs broad but bounded context.
- Documentation synthesis or planning is central.
- Google ecosystem knowledge is useful.
- A repository needs orientation before implementation.

### Antigravity IDE

Suggest as the harness when:

- Visual repository navigation helps.
- UI or frontend work is involved.
- Gemini-based coding benefits from IDE context.
- Interactive project inspection matters.

Prefer Gemini CLI when reproducible command-line workflow matters more than IDE integration.

### DeepSeek-compatible CLI

Suggest when:

- Cost sensitivity is high.
- Work is mechanical, repetitive, or clearly bounded.
- The reading surface is small.
- The implementation contract is simple.

Do not suggest as primary for open-ended governance, large historical review, ambiguous architecture, or tasks with many independent artifact obligations.

### Local model

Suggest when:

- Privacy or offline operation matters.
- Selected files fit local context and capability.
- The task is repetitive or low risk.
- External tools are unnecessary.

Do not recommend local execution for a difficult task merely to avoid API cost.

## Default Task Recommendations

| Task | Primary suggestion | Alternative |
|---|---|---|
| Small code patch | Codex CLI, focused configuration | DeepSeek CLI |
| Complex repository feature | Claude Code | Codex CLI, strong reasoning configuration |
| Independent code review | Codex CLI, strong reasoning configuration | Claude Code in read-only reviewer role |
| Broad architecture review | Claude Code or strong Codex reviewer | Gemini CLI |
| Large documentation synthesis | Gemini CLI | Claude Code |
| Google ecosystem automation | Gemini CLI or Antigravity | Claude Code |
| Mechanical bulk edit | DeepSeek CLI | Codex CLI, fast configuration |
| Frontend or visual project work | Antigravity IDE | Claude Code |
| DaVinci Resolve scripting | Claude Code | Codex CLI |
| Primary-source technical research | Gemini CLI or web-enabled researcher | Claude Code |
| Sensitive offline transformation | Suitable local model | Manual narrow cloud task |
| High-risk destructive automation | Claude Code | Codex independent review |

These are defaults, not fixed rankings.

## Writer and Reviewer Pairing

For medium or high-risk work:

- Select one Writer.
- Select one separate Reviewer.
- Avoid using the same run as both.
- Prefer a different model family when the change is high risk.

Examples:

```text
Writer: Claude Code
Reviewer: Codex CLI
```

```text
Writer: Codex CLI
Reviewer: Claude Code, read-only
```

Do not use parallel Writers on the same files.

## Recommendation Output

```text
Primary model:
Primary harness:
Role:
Alternative model:
Alternative harness:
Why:
Load:
Exclude:
Expected task size:
Independent review: yes/no
Escalate when:
```

For simple questions, keep the recommendation to 5–8 lines.

## Suggestion Safety

Do not:

- Invent access to a model or subscription.
- Assume a model version is current when that matters.
- Recommend simultaneous Writers.
- Recommend a model solely from benchmark reputation.
- Ignore context and token cost.
- Suggest reading the full A4C library.
- Turn model selection into a benchmark project unless Cen requests it.
- Promise that different models will produce identical results.

## Consistency Target

The 90% consistency target refers to process:

- Same contract
- Same task scope
- Same protected paths
- Same role separation
- Similar validation
- Same handoff structure

It does not mean identical wording, code style, implementation strategy, or model choice.

## When No Clear Winner Exists

Choose the option that:

1. Meets the task’s risk level.
2. Requires the least unnecessary context.
3. Preserves project safety.
4. Fits Cen’s token and time budget.
5. Has the simplest recovery path.

State uncertainty briefly and provide one primary recommendation, not a list of equal choices.
