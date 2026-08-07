# Filesystem Provider Architecture

## Status

Canonical for how FSD reads a filesystem, regardless of whether macOS mounted it natively or FSD read it through an embedded raw reader. This document is normative; [`ARCHITECTURE.md`](ARCHITECTURE.md) defers to it for everything filesystem-access-related and should not restate these rules. Dependency choices live in [`DEPENDENCY_AND_LICENSE_REVIEW.md`](DEPENDENCY_AND_LICENSE_REVIEW.md); per-filesystem completion status lives in [`FILESYSTEM_SUPPORT_MATRIX.md`](FILESYSTEM_SUPPORT_MATRIX.md).

## 1. Why this layer exists

The original architecture assumed every scan target was a live path macOS had already mounted (`FileManager`/`URL` enumeration). That assumption is only true for 7 native-readable target variants (Section 2 of the dependency review). For ext2/ext3/ext4, FSD must read filesystem structures itself, from either a disk image or a raw partition, without macOS ever mounting anything. The scanner, the SQLite writer, and the UI must not need to know or care which of these happened — they consume the same provider contract either way.

## 2. Component separation

```text
FSD UI (SwiftUI/AppKit)
        |
Snapshot Orchestration (CaptureCoordinator)
        |
        +--> Filesystem Provider Contract  <-- single abstraction, Section 4
        |         |
        |         +--> NativeMountedProvider   (APFS, HFS+, FAT16/32, exFAT, NTFS-ro, UDF)
        |         |         uses FileManager/URL against an already-mounted path
        |         |
        |         +--> EmbeddedRawProvider     (ext2, ext3, ext4; fallback path for anything
        |         |         else macOS fails to auto-mount)
        |         |         talks to the Reader Helper Process over IPC
        |         |
        |         +--> Filesystem Detector     (Section 5 — runs before a provider is chosen)
        |
        +--> SQLite Persistence (CatalogRepository) -- never talks to a provider directly
        |
Authorization Boundary (Section 7) -------- only touched by EmbeddedRawProvider
        |
Reader Helper Process (Section 8) --------- only exists for EmbeddedRawProvider
        |
Filesystem-specific adapters (Section 8.2) - one per embedded-raw filesystem family
```

The UI and the SQLite persistence layer never import or reference a specific provider type. They see the contract in Section 4 and nothing else. This is what lets "compare a live ext4 drive against an APFS snapshot" be an ordinary comparison rather than a special case — both sides already went through the identical `MetadataScanner -> SnapshotWriter` pipeline described in `ARCHITECTURE.md`, regardless of which provider fed the scanner.

## 3. Provider selection: deterministic fallback rule

For a given partition, in this order:

1. **Ask macOS first.** If macOS has already mounted the volume independently, FSD may read it through `NativeMountedProvider`. If the volume is recognized as a native-readable filesystem but is not mounted, FSD displays: "Mount Read-Only and Capture". FSD requests a read-only mount only after that explicit user action. If the user cancels or authorization fails, FSD performs no mount and no capture. FSD never silently requests a mount. FSD never silently unmounts. No read-write fallback exists. (See `SECURITY_AND_READ_ONLY_POLICY.md` for the complete normative policy.) This is always preferred when available — it is simpler, it is what macOS itself validated, and it carries no raw-device authorization burden.
2. **If mounting fails or the filesystem is one macOS never mounts** (currently: ext2/ext3/ext4; provisionally: any filesystem the [`FilesystemDetector`](#5-filesystem-detection-before-a-provider-is-chosen) recognizes but macOS refuses), run detection (Section 5) to confirm the filesystem family, then hand the partition to `EmbeddedRawProvider` with the matching adapter (Section 8.2).
3. **If detection cannot identify the filesystem, or no adapter exists for what it identifies**, FSD must not guess. Record a `scan_issue` with `severity = 'error'`, leave the volume unsupported for this capture, and never fall back to a "best-effort" partial read of an unrecognized structure. Guessing at an unknown on-disk format is exactly the kind of overclaim [`FILESYSTEM_SUPPORT_MATRIX.md`](FILESYSTEM_SUPPORT_MATRIX.md) rules out.

This rule is deterministic and has no user-facing "pick a provider" step in MVP — the fallback is automatic and the result records which path was taken (`filesystem_provider` on the snapshot row — see [Schema Impact](#9-schema-touch-points)).

## 4. The provider contract

Every provider — native or embedded — implements the same contract. It intentionally does not assume a live `URL` exists for every item (an embedded-raw entry has no Finder-visible path at all).

```text
FilesystemProvider
├── sourceIdentity        : device_identifier + partition_identifier (+ volume UUID, when the
│                            filesystem itself carries one) -- see FILESYSTEM_SUPPORT_MATRIX for
│                            which filesystems expose a stable identity
├── partitionIdentity      : partition_offset, partition_length, filesystem_variant
├── filesystemType         : one of the 10 filesystem variants (detected, not assumed)
├── providerKind           : .native | .embeddedRaw
├── accessMode             : always .readOnly -- there is no other value; see Section 6
├── rootEntry()            : the synthetic root node (relative_path = '')
├── children(of: EntryRef, page: PageRequest) : lazy, paged child enumeration -- never
│                            "list everything," matching the existing lazy-tree requirement
├── metadata(for: EntryRef) : the metadata fields this provider can supply -- see the support
│                            matrix's "required metadata available / unsupported metadata"
│                            columns; a provider must NEVER synthesize a value it cannot read
├── cancel()                : cooperative cancellation, checked at every batch boundary
├── progress                : entries/bytes/current-path progress stream, same shape the
│                            scanner already reports for native captures
├── readerVersion           : library + version string that produced this data (e.g.
│                            "libfsext 20260514" or "native/FileManager"); persisted verbatim
│                            into snapshots.provider_version
└── featureLimitations()    : filesystem-feature caveats the provider knows about up front
                             (e.g. "sparse-file detection unavailable on this adapter") --
                             surfaced as scan_issues with severity='info', not silently dropped
```

Nothing in this contract returns a write handle, a rename operation, a delete operation, or a "repair" operation. There is no method that can mutate the source. This is enforced by the contract's shape, not by a runtime flag: **the protocol simply has no such method for any provider to implement.**

## 5. Filesystem detection before a provider is chosen

Detection is a bounded, read-only prefix/offset sniff — it never depends on the filesystem being mountable:

- Read a small bounded prefix (recommend first 64 KiB) plus the handful of well-known fixed offsets each filesystem's magic signature lives at (ext2/3/4 superblock magic `0xEF53` at byte offset 1080; NTFS OEM ID `"NTFS    "` at offset 3; FAT `0x55AA` boot-sector signature plus `"FAT12"/"FAT16"/"FAT32"` string; exFAT OEM ID `"EXFAT   "`; APFS container magic `"NXSB"`; HFS+/HFSX magic `"H+"`/`"HX"`; UDF/ISO9660 volume descriptor identifiers `"NSR02"/"NSR03"/"CD001"` in the volume recognition sequence).
- This step requires only a readable byte source — it works identically whether that source is a mounted volume, a disk image file, or a raw partition device node once one is obtainable.
- Detection output feeds Section 3's fallback rule and is persisted as `filesystem_variant` (e.g. distinguishing FAT16 from FAT32, or ext2 from ext3/ext4 by journal-feature flags) — see [Schema Impact](#9-schema-touch-points).
- Detection is **advisory, not authoritative**, for the mounted case: if macOS already mounted the volume, trust its own filesystem-type report (via `DiskArbitration`'s volume-kind description) over a raw sniff, since macOS's own driver is the ground truth for anything it successfully mounted.

## 6. Read-only is architectural, not a disabled button

No production module in `Capture/`, `Catalog/`, or this provider layer may expose copy, move, rename, delete, touch, format, repair, or recovery operations, on either a mounted volume or a raw device. Concretely:

- `EmbeddedRawProvider` and every adapter open their source with `O_RDONLY` (or the read-only equivalent for whatever handle mechanism Section 7 settles on) and never request write access from `authopen` or any other authorization path.
- `NativeMountedProvider` only ever uses read-only `FileManager`/`URL` APIs — the same restriction the original `ARCHITECTURE.md` already stated for the live-folder case; this document does not relax it for raw devices, it extends it to them.
- Enforce this the same way [`SECURITY_AND_READ_ONLY_POLICY.md`](SECURITY_AND_READ_ONLY_POLICY.md) already requires for the mounted case: a lint/CI deny-list on write-capable APIs (`copyItem`, `moveItem`, `removeItem`, `createFile`, `setAttributes`, `replaceItem`, `trashItem`, plus, for the raw path, any block-device write syscall) inside every target that can reach a `FilesystemProvider`.

## 7. Authorization boundary

Only `EmbeddedRawProvider` ever needs this; `NativeMountedProvider` never does (mounting is a normal Finder/DiskArbitration action the user already performed).

- Attempt a plain read-only `open()` on the raw partition device node first.
- If that is denied, request a one-time, scoped, read-only file descriptor via the system `/usr/libexec/authopen` utility (Section 5 of the dependency review) — a native macOS authorization prompt naming the exact device, never a standing grant, never root, never Full Disk Access.
- If the user declines authorization, the capture for that volume simply does not happen. There is no degraded write-capable fallback and no silent retry with escalated privilege.
- Record whether a given snapshot needed this path (`authorization_required` — see [Schema Impact](#9-schema-touch-points)), so history is honest about which captures needed it.
- This exact mechanism is **unverified on real hardware** as of this document — see [`FILESYSTEM_FEASIBILITY_PLAN.md`](FILESYSTEM_FEASIBILITY_PLAN.md) Phase 0A/3 for the empirical test that must happen before this section is trusted operationally.

## 8. Reader helper process

### 8.1 Why a separate process

Every embedded-raw filesystem parser is an untrusted-input attack surface (Section 6 of the dependency review) — it parses on-disk structures FSD did not create and cannot assume are well-formed. Running that parsing in the same process as the UI and the SQLite catalog means a parser crash or exploit takes the whole app and its catalog connection down with it.

### 8.2 Shape

- A bundled process inside `FSD.app` (an XPC service under `Contents/XPCServices/`, or a subprocess under `Contents/MacOS/`) that links the embedded reader library (`libfsext` per the dependency review) dynamically.
- Receives only: a read-only file descriptor or byte-range handle to the partition (from Section 7), plus the detected `filesystem_variant`.
- Has no network entitlement, no access to the app's own SQLite catalog file, no access to any path outside the one handle it was given.
- One **filesystem-specific adapter** per embedded-raw family behind a small internal dispatch (currently just one: the ext2/3/4 adapter over libfsext; the contract allows more without changing the provider shape above it).
- Streams parsed metadata as batched records back to the main process over a defined IPC message shape (the same entry-batch shape the native scanner already produces for `SnapshotWriter` — no separate ingestion path in `CatalogRepository`).
- Can be killed and relaunched by the main process on crash or timeout without losing already-committed SQLite rows from the in-progress snapshot (consistent with the existing transactional/`interrupted` snapshot model in `ARCHITECTURE.md` §7).

### 8.3 What it must never do

Never write to the source, never write anywhere but its IPC channel back to the main process, never hold the raw-device handle open longer than the active capture, never retain elevated authorization across captures.

## 9. Schema touch points

This document defines *why* the following fields exist; [`database/schema.sql`](database/schema.sql) and its accompanying migration notes are the canonical *definition* of them — do not restate column types or constraints here:

`filesystem_provider`, `provider_version`, `source_access_mode`, `device_identifier`, `partition_identifier`, `partition_offset`, `partition_length`, `filesystem_variant`, `filesystem_features`, `authorization_required`. (`source_access_mode` alone covers `'mounted' | 'raw_device' | 'disk_image'` — a single field rather than a separate `raw_source_kind`, to avoid two overlapping enumerations describing the same fact.) See [`FILESYSTEM_SUPPORT_MATRIX.md`](FILESYSTEM_SUPPORT_MATRIX.md) for which of these apply to which filesystem, and the schema-impact section of [`FILESYSTEM_REPLAN_CLAUDE.md`](FILESYSTEM_REPLAN_CLAUDE.md) for the reasoning behind each field's inclusion.

## 10. What this document deliberately does not cover

Camera-vendor folder recognition, media validation, codec analysis, playback, thumbnails, file recovery, filesystem repair, and read-write mounting are not FSD features and have no provider-layer hook of any kind. If a future task proposes adding one, it must start by amending this document and its contract in Section 4 — not by special-casing it inside a specific adapter.

Snapshot Collections (`SNAPSHOT_COLLECTIONS.md`) are also out of scope here, in the other direction: a provider has no concept of, and never queries, which Collection a snapshot belongs to. Collection membership is purely catalog-layer metadata attached to a `snapshots` row after the provider has already finished producing it.

