# Project Manifest

## Identity

- Short name: FSD
- Expanded name: FishSock Differ

- Product: FSD — FishSock Differ
- Project type: Native macOS application
- Distribution: Internal local-only distribution
- Minimum OS: macOS 13
- CPU architecture: Apple Silicon arm64
- Working language: English
- Canonical repository path: `/Users/cenvu/DEV/FSD`
- Canonical docs path: `/Users/cenvu/DEV/FSD/docs`

## Product promise

Capture immutable metadata snapshots of folders and volumes, browse them offline, and compare directory structures without modifying or reading the content payload of source files.

## Canonical documents

- `PRD.md` — requirements and scope
- `AGENT.md` — implementation rules for AI and human contributors
- `PRODUCT_STATE.md` — current implementation state
- `KNOWN_ISSUES.md` — limitations and risks
- `DECISIONS.md` — architecture decision log
- `ARCHITECTURE.md` — system design
- `FILESYSTEM_PROVIDER_ARCHITECTURE.md` — provider contract, authorization boundary, reader helper process
- `FILESYSTEM_SUPPORT_MATRIX.md` — per-filesystem support level and behavior
- `DEPENDENCY_AND_LICENSE_REVIEW.md` — embedded reader library research and license posture
- `FILESYSTEM_FEASIBILITY_PLAN.md` — Phase 0A/0B feasibility methodology
- `SNAPSHOT_COLLECTIONS.md` — Collection semantics, capture prompt, defaults, deletion behavior
- `UX_UI_SPEC.md` — screens and interaction model
- `MVP_PLAN.md` — implementation phases
- `TEST_PLAN.md` — critical validation
- `SECURITY_AND_READ_ONLY_POLICY.md` — source safety policy
- `database/schema.sql` — catalog schema (version 5)

## Canonical product invariants

1. Metadata-only scanning by default.
2. No source-volume writes — applies identically to a mounted volume and a raw block device.
3. SQLite is the primary store.
4. JSON and HTML are export formats.
5. Completed snapshots are immutable.
6. Interrupted snapshots never replace the last complete snapshot.
7. Metadata Match must never be described as content verification.
8. Large trees use lazy database-backed loading.
9. FSD ships as one self-contained `.app`; it never requires the user to install Homebrew, macFUSE, ntfs-3g, a kernel extension, or an app extension.
10. No camera-vendor folder recognition, media validation, or codec analysis, at any phase.
11. Collection membership, snapshot display name, and snapshot note are mutable catalog metadata; changing them never mutates snapshot entries, aggregates, capture timestamps, or comparison results, and deleting a Collection never deletes a snapshot.

## MVP deliverable

A user can select a folder, optionally file the capture under a Collection, capture a complete metadata snapshot, eject or remove the source, browse the saved tree by Collection or search, compare it with another snapshot, and export a report.
