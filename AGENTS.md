# FSD always-on kernel

PROJECT=FSD
PRODUCT=FishSock Differ
BRAIN_ROLE=PM_PLUS_TECH_LEAD;NOT_WORKER
REPO_OR_PHYSICAL_WORKTREE_TRUTH_WINS=YES
OWNER_AUTHORIZATION_WINS=YES
WORKER_OUTPUT=EVIDENCE_NOT_TRUTH
MODEL_MEMORY=NON_AUTHORITY
UNKNOWN=PRESERVE
DIRTY_STATE=PRESERVE

SOURCE_READ_ONLY=YES
PRODUCT_METADATA_ONLY_DEFAULT=YES
NO_SOURCE_MUTATION=YES
COMPLETED_SNAPSHOT_IMMUTABLE=YES
INTERRUPTED_NEVER_REPLACES_LAST_COMPLETE=YES
NO_FALSE_CONTENT_EQUIVALENCE=YES

RESEARCH_BEFORE_GUESS=YES
REUSE_BEFORE_REIMPLEMENT=YES
NO_SILENT_FALLBACK=YES
NO_MODEL_BENCHMARK=YES
NO_AUTO_NEXT=YES
BRAIN_OWNS=REVIEW|CLASSIFICATION|ACCEPTED_STATE|ACTIVE_NEXT
WORKER_NEXT=PROPOSAL_ONLY

CURRENT_HANDOFF=handoffs/CURRENT_HANDOFF.md
COMPACT_OPERATOR=docs/BRAIN_OPERATOR.md
FULL_REFERENCE=docs/AGENT.md
ACCEPTED_LIVE_STATE=STATE/PROJECT_STATE.md
WORKER_EXECUTION_SKILL=.agents/skills/fsd-task-execution/SKILL.md
INDEPENDENT_REVIEW_SKILL=.agents/skills/fsd-independent-review/SKILL.md
ALL_WORKERS_ANTI_FORGET=FSD_WORKER_EXECUTION_V1
CONTEXT_DEFAULT=HOT+EXACT_TASK+DIRECT_AUTHORITY_REFS
DO_NOT_PRELOAD_ALL_HISTORY=YES
HANDOFF=ONE_FLAT_IMMUTABLE_HISTORY;CURRENT_FULL_COPY_WITH_UPDATED_AT
HIGH_RISK_REVIEW=SOURCE_SAFETY|SNAPSHOT_IMMUTABILITY|RECOVERY|SCHEMA_COMPATIBILITY|DESTRUCTIVE_BEHAVIOR|BROAD_COMPARISON_SEMANTICS|PRE_MVP_ACCEPTANCE

Use the exact task to resolve your role and authorized scope. Read CURRENT's
HOT first. BRAIN loads the Compact; Workers load its directly applicable rules.
Meaningful non-BRAIN execution must load WORKER_EXECUTION_SKILL; independent
review additionally loads INDEPENDENT_REVIEW_SKILL, regardless of model/harness.
Load relevant FULL sections on demand for audits, policy ambiguity, governance
conflicts, operator repair, rule promotion or high-risk adjudication.

## Owner Policy Always Read

OWNER_POLICY=https://github.com/cenvu/FSD/issues/1
OWNER_POLICY_LOCAL_CANONICAL=AGENTS.md#owner-policy-always-read
OWNER_POLICY_ONLINE_FETCH_REQUIRED=NO_WHEN_THIS_LOCAL_TEXT_IS_AVAILABLE
BRAIN_READS_OWNER_POLICY=BEFORE_EVERY_WORKER_PROMPT|BEFORE_EVERY_BRAIN_REVIEW_OR_ADJUDICATION

This section is the local canonical copy of the Owner directive recorded in
Issue #1. BRAIN reads and applies it alongside the exact task, this kernel,
`docs/BRAIN_OPERATOR.md` and accepted `STATE/PROJECT_STATE.md` before every
Worker prompt and every BRAIN review/adjudication. The local copy satisfies the
read requirement; an online GitHub fetch is not required while this text is
available. At every prompt and review, BRAIN asks: “Is this a real
technical/security/scope gate or redundant bureaucracy? Can code review and
existing evidence replace this extra round?” Remove a redundant round.

- One authorized bounded task includes ordinary implementation and test
  failures, iterative debugging, evidenced test/fixture/assertion corrections,
  in-scope research and validation. Do not require a new approval after each
  ordinary failure or bounded correction.
- Code review and executable tests are the default correctness mechanism.
  Inspect the actual source, failing assertion/fixture and result before
  deciding whether a failure is product behavior or a test expectation issue.
  An evidenced one-line test correction stays in the existing task scope.
- After three ineffective implementation attempts on the same cause, research
  official API/SDK contracts, upstream and credible community/issues evidence,
  then change approach based on that evidence. This is a research and
  approach-change trigger, not an automatic STOP or permission round.
- A failed required test blocks PASS/publication but does not prohibit continued
  debugging inside the authorized task. Do not repeat a failed patch blindly.
- Preserve STOP/escalation for genuine authority or safety boundaries: source
  writes or unauthorized source-content reads; credentials, secrets or privacy
  exposure; destructive data/schema/security changes; risk of corruption or
  lost work; unexplained dirty-work conflicts or unreconciled remote drift; an
  out-of-scope required change; or an unresolved technical impasse after
  evidence-based attempts. Do not weaken source-read-only, snapshot
  immutability, cancellation/recovery, privacy or accepted-history protections.
- Consolidate routine preflight, validation and reporting; do not create
  repetitive permission rounds, redundant Worker handoffs or duplicate audits.
  Keep one historical handoff per task and publish only after required evidence
  and review pass.
- Current Owner routing for Antigravity CLI/IDE is OPUS 4.6 only; SONNET is
  excluded. Use a cheaper preparation Worker before an OPUS round only when
  OPUS is actually warranted by task risk or unresolved reasoning complexity.
