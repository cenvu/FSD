# Handoffs

Store exactly one handoff per agent task session.

Canonical path:

```text
handoffs/FSD_<CASE_CODE>_<ROLE_CODE>_<YYYYMMDD-HHMMSS>.md
```

Do not create date subdirectories, SESSION directories, or `.sha256` checksum files.

The legacy nested `AI_HANDOFFS/<date>/SESSION_<id>/H_<CASE_CODE>_<ROLE_CODE>_<MMDDHHMMSS>.md` layout is retired. Its two historical files were inventoried and migrated into the flat `handoffs/` directory under this convention (`FSD_R0BLOCKERSCLOSURE_C_20260724-210734.md`, `FSD_R0BLOCKERSAUDIT_A_20260724-211837.md`); the checksum sidecars were not carried over. The `AI_HANDOFFS/` directory itself has been deleted. No canonical document should reference it going forward.

**Mandatory Single-File Handoff Policy**:
- Exactly one Markdown Handoff per session;
- No separate session report file;
- The Handoff is the complete technical record;
- The Handoff may be long because it replaces the report;
- The user only needs to provide the latest single Handoff to CONTROL CENTER.

Minimum handoff content:

- objective;
- repository state;
- files changed;
- decisions made;
- tests run;
- unresolved risks;
- exact next action.
