# FSD — FishSock Differ

FSD is a native macOS metadata snapshot catalog and tree-comparison application.
Canonical repository: `/Users/cenvu/DEV/FSD`; documentation: `docs/`.
Product documents use English. Owner communication follows the Operator.

## Truth ownership

One fact has one current owner. [../STATE/PROJECT_STATE.md](../STATE/PROJECT_STATE.md)
owns BRAIN-accepted control phase, task/gate and next decision.
[../STATE/EVENTS.jsonl](../STATE/EVENTS.jsonl) owns append-only transitions;
[../STATE/TASK_LEDGER.tsv](../STATE/TASK_LEDGER.tsv) owns task retrieval;
[../STATE/RULE_PROMOTION_LEDGER.tsv](../STATE/RULE_PROMOTION_LEDGER.tsv) owns accepted
rule promotions. [../handoffs/CURRENT_HANDOFF.md](../handoffs/CURRENT_HANDOFF.md)
owns current Worker continuity, with immutable timestamped evidence in `handoffs/`.
Worker evidence is subject to BRAIN adjudication. Desktop is recovery transport.

Product requirements, design, validation and implementation facts have their own
scoped authorities below; they do not own control state or authorize progression.

## Read by task

Start with [../AGENTS.md](../AGENTS.md), CURRENT HOT, the exact task and its direct
authority references. BRAIN reads [BRAIN_OPERATOR.md](BRAIN_OPERATOR.md).
Expand only for the question being answered; [AGENT.md](AGENT.md) is deep governance.

| Task | Product/control authority to read |
|---|---|
| Worker execution | [task-execution](../.agents/skills/fsd-task-execution/SKILL.md) — mandatory provider-neutral preflight, bounded execution and fresh requirement postflight |
| Independent review | [independent-review](../.agents/skills/fsd-independent-review/SKILL.md) plus task-execution with ROLE=REVIEWER — risk-first, read-only review |
| Finalization | [finalizer](../.agents/skills/fsd-handoff-finalizer/SKILL.md) — guarded candidate, STATE projection, recovery parity and verified publication |
| Low-risk control | Accepted STATE, relevant ledger row, Operator applicable rules; [finalizer](../.agents/skills/fsd-handoff-finalizer/SKILL.md) for a Worker return |
| Product requirement | [PRD.md](PRD.md) — user promise, scope and exclusions |
| Product implementation or limitation | [PRODUCT_STATE.md](PRODUCT_STATE.md) — capabilities, gaps and limitation pointers |
| Schema or safety review | [ARCHITECTURE.md](ARCHITECTURE.md), [DECISIONS.md](DECISIONS.md), [TEST_PLAN.md](TEST_PLAN.md), [SECURITY_AND_READ_ONLY_POLICY.md](SECURITY_AND_READ_ONLY_POLICY.md), relevant `docs/database/` and source sections |
| Roadmap/dependency | [MVP_PLAN.md](MVP_PLAN.md) — stable milestone sequence |
| P15 runtime | [P15_RUNTIME_PLAN.md](P15_RUNTIME_PLAN.md), Architecture §9a, ADR-032, Test Plan §9 and safety policy §2.1 |

## Specialized references

- [FILESYSTEM_PROVIDER_ARCHITECTURE.md](FILESYSTEM_PROVIDER_ARCHITECTURE.md) — provider and helper boundaries.
- [FILESYSTEM_SUPPORT_MATRIX.md](FILESYSTEM_SUPPORT_MATRIX.md) — support proof and filesystem limitations.
- [FILESYSTEM_FEASIBILITY_PLAN.md](FILESYSTEM_FEASIBILITY_PLAN.md) — disk-image and physical-device verification methodology.
- [DEPENDENCY_AND_LICENSE_REVIEW.md](DEPENDENCY_AND_LICENSE_REVIEW.md) — library and redistribution research.
- [SNAPSHOT_COLLECTIONS.md](SNAPSHOT_COLLECTIONS.md) — organization/default/deletion contract.
- [UX_UI_SPEC.md](UX_UI_SPEC.md) — interaction requirements.
- [REFERENCE_VISUALDIFFER.md](REFERENCE_VISUALDIFFER.md) — comparison study and clean-room boundary.

Dated review/research documents are on-demand evidence, not implementation or
control authorities. Their original findings and then-next wording must be read
against the scoped authorities and accepted STATE. No history preload is required.
