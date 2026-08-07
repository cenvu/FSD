# Filesystem Feasibility Plan

## Status

Canonical for the feasibility methodology and Phase 0A/0B detail referenced by [`MVP_PLAN.md`](MVP_PLAN.md). The full phase sequence (0A through 8) is listed once, in `MVP_PLAN.md`; this document supplies the detail for the two phases that did not exist before this replan (0A and 0B) plus the fixture/gating rules that apply to every later phase that touches a filesystem provider.

## 1. Governing rule

**Disk-image testing always precedes physical-device testing, for every filesystem in scope, no exceptions.** A disk image isolates the filesystem-parsing risk (Section 6 of `DEPENDENCY_AND_LICENSE_REVIEW.md`) from the device-authorization risk (Section 7 of `FILESYSTEM_PROVIDER_ARCHITECTURE.md`). Testing both at once means a failure can't be attributed to either cause. Physical-device work does not start until the same filesystem has already cleared image-based testing.

**No filesystem is marked "Supported" in [`FILESYSTEM_SUPPORT_MATRIX.md`](FILESYSTEM_SUPPORT_MATRIX.md) from library documentation or research alone.** Only the seven-step runtime proof defined there earns that label. This plan exists to produce that proof, in order, at acceptable risk.

## 2. Representative test images required

At minimum, one representative disk image per required filesystem, generated on a platform that natively writes that filesystem (not on macOS, for the filesystems macOS can't natively create):

| Filesystem | Suggested image origin |
|---|---|
| APFS, HFS+, FAT16, FAT32, exFAT, UDF | `hdiutil create` / Disk Utility on macOS itself — trivial, no external dependency |
| NTFS | A disposable Linux or Windows VM (`mkntfs`/`mkfs.ntfs`), or a small pre-existing NTFS image; read-only mounting is all FSD needs to validate |
| ext2, ext3, ext4 | A disposable Linux VM or container (`mkfs.ext2`/`mkfs.ext3`/`mkfs.ext4`) — this VM is a **test-fixture generator only**, never part of FSD's runtime or shipped product |

Each image should contain the fixture set already defined in `TEST_PLAN.md` §2 (empty folder, deep nesting, wide folder, Unicode names, NFC/NFD collisions, case-collision names, files without extensions, symlinks, broken symlinks, packages where applicable, hidden files, inaccessible folders, sparse files, zero-byte files, large files, near-limit path lengths) **plus**, specifically for ext2/3/4: at least one filename that is a non-UTF-8 byte sequence (legal on ext2/3/4, illegal as a Swift `String` — see `FILESYSTEM_SUPPORT_MATRIX.md`'s ext2 row), and for ext4 specifically: one volume with the case-insensitivity feature flag enabled and one with an fscrypt-encrypted subtree.

## 3. Phase 0A — Multi-filesystem feasibility and dependency proof

- **Objective:** prove, on disk images only, that `EmbeddedRawProvider` over libfsext can detect, open read-only, and enumerate ext2/ext3/ext4, and that `NativeMountedProvider` correctly reads metadata from mounted images of the other seven native-readable variants — before any UI or full scanner exists.
- **Dependencies:** `DEPENDENCY_AND_LICENSE_REVIEW.md` (library choice), `FILESYSTEM_PROVIDER_ARCHITECTURE.md` (contract shape), the fixture images from Section 2.
- **Deliverables:** a disposable command-line spike (not the production scanner) that, per filesystem: mounts or opens the image, runs `FilesystemDetector`, enumerates the fixture tree, and prints the metadata fields `FILESYSTEM_SUPPORT_MATRIX.md` claims as "required metadata available" for that filesystem.
- **Exit criteria:** every filesystem in Section 2's table completes detection + read-only open + full fixture enumeration against its image, with output cross-checked against a ground-truth listing (`find`/`stat` inside the fixture-generating VM for ext2/3/4; `find`/`stat` on macOS itself for the natively-created images).
- **Automated tests:** a scripted comparison of the spike's enumerated output against the ground-truth listing, per filesystem, checked into the eventual `Tests/Fixtures/` structure (`PROJECT_SUPPORT/TEST_STRUCTURE.md`).
- **Real manual tests:** none required — this phase is disk-image-only by design (Section 1).
- **Risks:** libfsext's ext2/3/4 support turns out to be incomplete or unstable against the non-UTF-8-name or fscrypt fixtures; the TSK fallback (`DEPENDENCY_AND_LICENSE_REVIEW.md` §3.2) is only invoked if this happens, and invoking it restarts this phase's exit criteria against TSK, not a shortcut past them.
- **Explicitly out of scope:** any physical device, any raw `/dev/rdiskN` access, any authorization prompt, any UI, any SQLite persistence (the spike may print to stdout).

## 4. Phase 0B — Final architecture and license decision

- **Objective:** convert Phase 0A's empirical results into accepted ADRs, closing every "Decisions Required" item this replan raises that depends on feasibility evidence rather than pure specification.
- **Dependencies:** Phase 0A complete with a documented pass/fail per filesystem.
- **Deliverables:** ADR entries in `DECISIONS.md` recording: which library actually reads ext2/3/4 (libfsext vs. the TSK fallback), confirmation that the provider contract in `FILESYSTEM_PROVIDER_ARCHITECTURE.md` needed no revision (or the revision it needed, made before Phase 1 starts), and the finalized `FILESYSTEM_SUPPORT_MATRIX.md` status update for every filesystem that passed.
- **Exit criteria:** no open "Decisions Required" item in this replan remains that Phase 0A evidence was supposed to resolve.
- **Automated tests:** none beyond Phase 0A's own.
- **Real manual tests:** none.
- **Risks:** discovering during 0A that a filesystem needs a different provider than assumed (e.g. libfsext fails and TSK's larger footprint becomes necessary) — acceptable to absorb here since it is exactly what this gate exists to catch before Phase 1's contract is built against an assumption instead of evidence.
- **Explicitly out of scope:** any new feasibility testing — 0B is a decision-recording phase, not a re-test phase.

## 5. Phase 1 onward — where physical-device testing fits

Physical-device testing (raw `/dev/rdiskN` access, `authopen` authorization, real external drives) is **Phase 3** in the revised sequence (`MVP_PLAN.md`), and its entry gate explicitly requires: Phase 0A/0B complete for the filesystem family being tested, plus the general four-condition gate already carried over from the prior architecture review (`REVIEW_CLAUDE_CODE.md` §13) for interrupted-scan recovery, volume identity, and schema-migration stability. Do not test a physical ext2/3/4 drive before its disk-image path has already cleared Phase 0A — that would violate Section 1's governing rule.

## 6. What this plan does not decide

This plan does not choose the library (see the dependency review), does not define the provider contract (see the provider architecture), and does not assign schema columns (see `database/schema.sql` and the schema-impact section of `FILESYSTEM_REPLAN_CLAUDE.md`). It only defines how feasibility gets proven, in what order, before those other documents' assumptions are trusted operationally.

## 7. Current feasibility status (established 2026-08-04 by independent audit)

Established 2026-08-04 by `handoffs/FSD_MVP_DEEP_AUDIT_R_20260804-003039.md`; amended 2026-08-04 by Milestone 3. Rows marked PASS are *feasibility evidence* from disposable spikes and do not earn the "Supported" label in [`FILESYSTEM_SUPPORT_MATRIX.md`](FILESYSTEM_SUPPORT_MATRIX.md). Rows marked SUPPORTED cleared the full seven-step proof through real production code under the Milestone 3 harness (`FSDTests/FilesystemMatrixTests.swift`); no physical or removable device was used for any of them.

| Filesystem | Status | Evidence | Blocks core MVP foundation? |
|---|---|---|---|
| ext2 | PASS WITH DEFERRED PRODUCTION CONDITIONS | `spikes/phase0a-libfsext/ext2_output.txt`; three independent reviews | No — deferred beyond MVP |
| ext3 | PASS WITH DEFERRED PRODUCTION CONDITIONS | `spikes/phase0a-libfsext/ext3_output.txt` | No — deferred beyond MVP |
| ext4 | PASS WITH DEFERRED PRODUCTION CONDITIONS | `spikes/phase0a-libfsext/ext4_output.txt`, plus encrypted-subtree, corrupt, truncated, and partition-offset fixtures | No — deferred beyond MVP |
| APFS | PASS WITH DEFERRED PRODUCTION CONDITIONS | `spikes/phase0a-native-applefs/`; read-only proven by pre/post image hash; 3-run determinism re-verified 2026-08-04 | No — this is the MVP's primary path, proven at Milestone 2 |
| APFS case-sensitive (APFSX) | PASS WITH DEFERRED PRODUCTION CONDITIONS | Same spike; case-distinct fixtures (`Report.txt` / `REPORT.TXT`) confirmed coexisting and distinctly enumerated | No |
| HFS+ | PASS WITH DEFERRED PRODUCTION CONDITIONS | Same spike; volume forces NFD for both NFC and NFD writes — characterized, not a defect | No |
| HFSX | PASS WITH DEFERRED PRODUCTION CONDITIONS | Same spike; case-sensitivity correctly reported by `volumeSupportsCaseSensitiveNamesKey` | No |
| FAT16 | **SUPPORTED** (2026-08-04) | Generated read-only disk image captured through production code; image SHA-256 identical before and after; snapshot reopened with the image detached. `FILESYSTEM_SUPPORT_MATRIX.md` §2.1 | No — done |
| FAT32 | **SUPPORTED** (2026-08-04) | As FAT16. Note: indistinguishable from FAT16 at the `statfs` level, both report `msdos` | No — done |
| exFAT | **SUPPORTED** (2026-08-04) | As FAT16 | No — done |
| NTFS read-only | ENVIRONMENT-BLOCKED — PROVIDER PATH NOT INVALIDATED | Captured correctly from a generated image with the image unchanged, but only through a third-party driver; this macOS build ships no `mount_ntfs` helper and no NTFS formatter. `FILESYSTEM_SUPPORT_MATRIX.md` §2.2 | No |
| UDF | **SUPPORTED** (2026-08-04) | As FAT16. Note: detected as case-**sensitive**, contrary to this document's earlier expectation | No — done |

**Deferred production condition applying to every "PASS WITH DEFERRED PRODUCTION CONDITIONS" row above:** feasibility was proven by a disposable spike, not by production code. Each filesystem must still clear the seven-step proof through the real `FilesystemProvider` implementation before it is marked Supported.

### libfsext accepted limitations (carried forward)

From `handoffs/FSD_PHASE0A_LIBFSEXT_CLAUDE_SIGNOFF_A_20260725-180621.md`, verified present and unresolved 2026-08-04:

| # | Condition | Gate |
|---|---|---|
| A | Invalid UTF-8 filename identity, `scan_issue` emission, uncertainty handling | Blocks embedded-raw production integration |
| B | Partition-offset implementation (currently dead code; `libbfio_file_range_io_handle` path unused) | Blocks embedded-raw production integration |
| C | LGPL-3.0-or-later compliance review | Blocks **distribution only** — not local builds, not MVP development |
| D | Production recursion-depth limit (currently unbounded recursion) | Blocks embedded-raw production integration |
| E | Verified case-distinct ext fixture (host APFS case-insensitivity artifact) | Does not block; required later test |
| F | Partial-success signaling (adapter always returns 0 regardless of enumeration errors) | Blocks embedded-raw production integration |
| G | `format_version` integer type / compiler warning | Does not block; optional improvement |

### Gating decision

**Completing the remaining filesystem feasibility work is NOT required before starting the Xcode foundation, `CatalogDatabase`, the snapshot model, the provider interface, or native folder scanning.** The provider architecture (`FILESYSTEM_PROVIDER_ARCHITECTURE.md`) deliberately isolates per-filesystem behavior behind one contract, so provider-specific feasibility is separable from core MVP foundation:

- **Blocks core MVP foundation:** nothing.
- **May run in parallel with Milestones 1–2:** FAT16/FAT32/exFAT/NTFS/UDF image generation and spike work, if a second worker is available.
- **Deferred until the provider milestone (Milestone 3):** FAT16, FAT32, exFAT, NTFS read-only, UDF.
- **Deferred beyond initial MVP:** all `EmbeddedRawProvider` production integration (ext2/3/4, conditions A/B/D/F) and all physical raw-device access — the PRD's success metrics (§9) are satisfiable without them.
