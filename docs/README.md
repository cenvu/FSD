# FSD — FishSock Differ

FSD — FishSock Differ is a read-only native macOS application for capturing metadata-only snapshots of volumes and folders — APFS, HFS+, FAT16, FAT32, exFAT, NTFS, ext2, ext3, ext4, and UDF — browsing them after eject, and comparing two trees by structure, file count, and logical size. It ships as one self-contained `.app`: no Homebrew, macFUSE, ntfs-3g, kernel extension, or app extension is ever required of the user.

## Project identity

- **Short name:** FSD
- **Full name:** FishSock Differ
- **Display name:** FSD — FishSock Differ
- **Canonical repository path:** `/Users/cenvu/DEV/FSD`
- **Canonical documentation path:** `/Users/cenvu/DEV/FSD/docs`

## Product statement

> Scan metadata once. Browse offline forever. Compare structure instantly. Never modify source files.

## Target platform

- macOS 13+
- Apple Silicon arm64
- Swift 5.9+
- SwiftUI application shell
- AppKit `NSOutlineView` for large trees
- SQLite for persistent catalog storage

## Core capabilities

1. Detect mounted external volumes and, for filesystems macOS cannot mount at all (ext2/ext3/ext4), read them directly through a bundled embedded reader — see [`FILESYSTEM_PROVIDER_ARCHITECTURE.md`](FILESYSTEM_PROVIDER_ARCHITECTURE.md).
2. Capture read-only metadata snapshots.
3. Browse the last complete snapshot while the volume is offline.
4. Keep multiple capture sessions per volume.
5. Compare live folders and snapshots by relative path, item type, file count, and logical size.
6. Export snapshot and diff reports as JSON and self-contained HTML.

## Documentation bundle map

The documentation set lives at `/Users/cenvu/DEV/FSD/docs`. (The historical bundle-extraction instructions in `PLACEMENT.md` reference an older `Desktop/DEV/FSD` path and are superseded.)

```text
docs/
├── README.md
├── PROJECT_MANIFEST.md
├── PLACEMENT.md
├── PRD.md
├── AGENT.md
├── PRODUCT_STATE.md
├── KNOWN_ISSUES.md
├── DECISIONS.md
├── ARCHITECTURE.md
├── FILESYSTEM_PROVIDER_ARCHITECTURE.md
├── FILESYSTEM_SUPPORT_MATRIX.md
├── DEPENDENCY_AND_LICENSE_REVIEW.md
├── FILESYSTEM_FEASIBILITY_PLAN.md
├── UX_UI_SPEC.md
├── MVP_PLAN.md
├── TEST_PLAN.md
├── SECURITY_AND_READ_ONLY_POLICY.md
├── REFERENCE_VISUALDIFFER.md
├── REVIEW_CLAUDE_CODE.md
├── FILESYSTEM_REPLAN_CLAUDE.md
├── database/
│   ├── schema.sql
│   └── verify.sql
├── samples/
│   ├── snapshot.example.json
│   └── diff.example.json
└── PROJECT_SUPPORT/
    ├── HANDOFFS.md
    ├── APP_STRUCTURE.md
    ├── CONFIG.md
    ├── GITIGNORE.template
    ├── RELEASES.md
    ├── SCRIPTS.md
    └── TEST_STRUCTURE.md
```

Agent handoffs themselves live at `<FSD_ROOT>/handoffs/` (exactly one flat Markdown file per session, no separate reports, no checksums — `PROJECT_SUPPORT/HANDOFFS.md`), outside the `docs/` tree.

## Reference implementations

- [`REFERENCE_VISUALDIFFER.md`](REFERENCE_VISUALDIFFER.md) records the VisualDiffer comparison study, reusable UX patterns, architectural differences, GPLv3 constraints and clean-room implementation policy.

## Filesystem scope

FSD reads APFS, HFS+, FAT16, FAT32, exFAT, NTFS, ext2, ext3, ext4, and UDF. The provider architecture, per-filesystem support level, and dependency/license research are canonical in [`FILESYSTEM_PROVIDER_ARCHITECTURE.md`](FILESYSTEM_PROVIDER_ARCHITECTURE.md), [`FILESYSTEM_SUPPORT_MATRIX.md`](FILESYSTEM_SUPPORT_MATRIX.md), and [`DEPENDENCY_AND_LICENSE_REVIEW.md`](DEPENDENCY_AND_LICENSE_REVIEW.md) — this README does not restate them.

## MVP boundary

The first release does not hash file contents, play media, generate thumbnails, modify source files, synchronize folders, recognize camera-vendor folder layouts, or claim bit-for-bit verification.

## Implementation order

The canonical, current phase sequence is [`MVP_PLAN.md`](MVP_PLAN.md) — this README does not maintain a second copy of it.

## Status

**Milestones 1–5 technical core is closed with known limitations.** FSD captures metadata snapshots, browses and searches them offline, compares snapshot/live trees, and exports JSON. Phase 1.5 nullable enrichment preparation is implemented and audited; Magika runtime design is complete, while runtime implementation is not started/inactive.

- Foundational R0 schema issues are **closed** (final independent audit APPROVE, `handoffs/FSD_PLAN_GATE_FINAL_REAUDIT_A_20260725-154907.md`).
- Milestone 2 was audited **APPROVE WITH CONDITIONS**. Milestone 3 closed its five technical conditions; the sixth, Manual Session A, is **NOT PERFORMED — DEFERRED BY OWNER** and is the only thing holding Milestone 2 acceptance sign-off.
- The M5 focused schema-v8/disposal re-audit is **CLOSED — APPROVE WITH CONDITIONS** (`handoffs/FSD_M5_SCHEMA_V8_DISPOSAL_REAUDIT_A_20260805-223211.md`). The nullable enrichment boundary audit is also **CLOSED — APPROVE WITH CONDITIONS** (`handoffs/FSD_P15_MAGIKA_NULLABLE_ENRICHMENT_AUDIT_R_20260807-142313.md`).
- Catalog schema is currently **version 8**, reached by explicit transactional migrations (ADR-024/ADR-028/ADR-030).
- FAT16, FAT32, exFAT and UDF are **Supported** (seven-step proof, generated read-only disk images, 2026-08-04). NTFS captured correctly but only through a third-party driver, so its stock-macOS proof is environment-blocked. ext2/3/4 feasibility passed and remains deferred beyond the MVP.
- Runtime design is **COMPLETE** (`handoffs/FSD_P15_MAGIKA_RUNTIME_DESIGN_A_20260807-155630.md`, ADR-032); **SCHEMA CHANGE REQUIRED BEFORE RUNTIME**, under separate authorization. No schema v9 or runtime implementation is included in the current state.
- Owner manual acceptance remains **NOT PERFORMED — DEFERRED BY OWNER**; overall MVP approval is **NOT CLAIMED**. Historical build/test evidence is recorded in `TEST_PLAN.md` and the accepted audits; this summary does not report a new test run.

Current state of record: [`PRODUCT_STATE.md`](PRODUCT_STATE.md). Current implementation sequence: [`MVP_PLAN.md`](MVP_PLAN.md).

The original `PROJECT_MANIFEST.md` schema-v5 bundle annotation is historical
and superseded by the current v8 state here and in `PRODUCT_STATE.md`; it is
not a current schema gate.
