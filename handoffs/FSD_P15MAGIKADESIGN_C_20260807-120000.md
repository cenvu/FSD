# FSD-P15-MAGIKA-RUNTIME-DESIGN-0807-20 Handoff
UPDATED_AT: 2026-08-07T12:00:00Z

## Summary
The runtime adapter design for Phase 1.5 Magika integration is complete. The design strictly adheres to FSD invariants: out-of-process isolation for untrusted parsers, a single self-contained `.app` footprint, zero source writes, and explicit-only invocation.

## Decisions Recorded
1. **Packaging**: Locally bundled helper executable (isolated per `FILESYSTEM_PROVIDER_ARCHITECTURE.md` §8). 
2. **Byte Contract**: Bounded 4096-byte single prefix read (PROPOSED). The provider receives only `Data`, no `URL`. Bytes read are unconditionally never persisted, never hashed, and never logged.
3. **Trigger Scope**: Explicit user action on a single entry only. The 8 canonical workflows (capture, application launch, history open, snapshot reopen, browsing, search, comparison, JSON export) never trigger it.
4. **Cancellation**: Runtime-only abort. Writes zero rows.
5. **Schema Verdict**: SCHEMA CHANGE REQUIRED BEFORE RUNTIME. A `provider_identifier` column must be added to `entry_classifications`.

## Documentation Updates
- `ARCHITECTURE.md` (appended §9a)
- `DECISIONS.md` (added ADR-032)
- `SECURITY_AND_READ_ONLY_POLICY.md` (appended §2.1)
- `TEST_PLAN.md` (added §9)
- `MVP_PLAN.md` and `PRODUCT_STATE.md` (prepended status line)
