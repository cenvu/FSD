# FSD Embedded Filesystem Replan

- **Task:** FSD-FSCORE-REPLAN-0724-04
- **Date:** 2026-07-24
- **Scope:** documentation, architecture, feasibility planning, schema review, and dependency review only. No production Swift code, no Xcode project, no compiled or bundled third-party library, no Git initialization, no camera-vendor recognition (explicitly excluded).

## Executive Verdict

The self-contained, multi-filesystem requirement is **feasible as specified, and turns out to be smaller than the task brief assumed**: 7 of the 9 required filesystems (APFS, HFS+, FAT16, FAT32, exFAT, NTFS-read, UDF) are already natively readable by macOS across the entire 13–26 target range with no user-installed driver, kext, or app extension — verified against current documentation of macOS's own filesystem stack, not assumed. Only ext2/ext3/ext4 genuinely needs an embedded reader, and a narrowly-scoped, actively-maintained, LGPL-licensed library (libfsext) covers it without requiring TSK's larger footprint, GPL entanglement, or FSKit's macOS 15+/system-extension packaging (both of which are excluded, the latter for two independent reasons — see below).

This replan produces a complete, internally consistent specification package: a provider architecture that unifies both access paths behind one contract, a per-filesystem support matrix that refuses to claim "Supported" without runtime proof, a dependency/license review with an explicit isolation and redistribution posture, a feasibility plan enforcing disk-image-before-physical-device testing, a schema revision (version 2) that is tested against a fresh SQLite database, and updates to every canonical document that assumed a mounted-only, camera-agnostic-but-undocumented scope.

**This replan does not, and could not, resolve the pre-existing R0 audit rejection** (path normalization/transient-snapshot correctness — `handoffs/FSD_R0BLOCKERSAUDIT_A_20260724-211837.md`, decision REJECT). That is a separate, still-open gate this task was not asked to touch. Nor does it execute Phase 0A's empirical feasibility spike — it specifies that spike in enough detail to run, but running it is out of this task's scope (no code, no compiled libraries).

## New Canonical Scope

FSD reads APFS, HFS+, FAT16, FAT32, exFAT, NTFS, ext2, ext3, ext4, and UDF, delivered as one self-contained `.app` with no Homebrew/macFUSE/ntfs-3g/kernel-extension/system-extension install requirement, no Apple Developer account, and no notarization. It does not recognize camera-vendor folder layouts (ARRI, RED, Sony, Canon, Nikon), validate media, or analyze codecs, at any phase — a permanent exclusion (`DECISIONS.md` ADR-018), not a deferred item. Every other MVP invariant from before this replan (metadata-only, read-only, immutable snapshots, SQLite-canonical, honest equality language) is preserved unchanged.

## Feasibility Assessment

| Filesystem | Native to macOS 13–26, no install? | Embedded reader needed? |
|---|---|---|
| APFS, HFS+, FAT16, FAT32, exFAT, UDF | Yes | No |
| NTFS | Yes (read-only) | No |
| ext2, ext3, ext4 | No | Yes — libfsext |

Source: `DEPENDENCY_AND_LICENSE_REVIEW.md` §2, cross-checked against current documentation of macOS's built-in filesystem stack (Eclectic Light Co.'s macOS 26 filesystem-support survey and Apple developer-forum threads on FSKit, both cited there). This is the single fact that reshapes the rest of this replan: the task brief's premise ("without requiring... kernel extensions, app extensions" for nine filesystems) reads as a nine-filesystem problem; it is actually a one-filesystem-family problem once macOS's own native support is accounted for.

**What is not yet proven:** whether libfsext's ext2/3/4 support holds up against real and adversarial fixtures (non-UTF-8 names, fscrypt-encrypted subtrees, corrupted images), and whether raw physical-device access needs `authopen` or succeeds with a plain read-only `open()`. Both are empirical questions this replan could not answer without running code — they are Phase 0A and Phase 3 respectively (`FILESYSTEM_FEASIBILITY_PLAN.md`), not open specification gaps.

## Recommended Dependency Strategy

**libfsext** (libyal project, LGPL-3.0-or-later), dynamically linked inside `FSD.app/Contents/Frameworks/`, driven from an isolated reader helper process. Evaluated and not selected: The Sleuth Kit (broader scope than needed, larger bundle, weak-copyleft IPL/CPL licensing, historically rougher Apple Silicon build story though improving), e2fsprogs/libext2fs (GPL-2.0, harder to isolate than LGPL for no added benefit here), macFUSE/ntfs-3g-based tools (require a user-installed app extension — excluded by the task's own constraint), and Apple FSKit (requires macOS 15+, above FSD's stated 13+ floor, *and* packages as an app extension regardless of OS version — excluded on both grounds independently). Full research, license fields, and reasoning: `DEPENDENCY_AND_LICENSE_REVIEW.md`.

## Filesystem-by-Filesystem Decision

Full detail, including per-filesystem case-sensitivity, normalization, symlink/hard-link/sparse-file/allocated-size/encryption/corruption behavior, is canonical in `FILESYSTEM_SUPPORT_MATRIX.md` and not repeated here. Summary:

| Filesystem | Provider | Fallback |
|---|---|---|
| APFS, HFS+, FAT16, FAT32, exFAT, NTFS, UDF | `NativeMountedProvider` | none needed |
| ext2, ext3, ext4 | `EmbeddedRawProvider` (libfsext) | TSK, only if libfsext fails Phase 0A/2 |

Every row is currently labeled **Targeted**, not "Supported" — the matrix's own seven-step definition (detect → open read-only → enumerate → capture metadata → persist → reopen offline → verify no write) has not been executed for any filesystem yet, because no scanner code exists (`PRODUCT_STATE.md`).

## Native vs Raw Provider Rules

A single `FilesystemProvider` contract (`FILESYSTEM_PROVIDER_ARCHITECTURE.md` §4) covers both `NativeMountedProvider` and `EmbeddedRawProvider` — the scanner, catalog, and UI never know which produced a given entry. Selection is deterministic (§3): try native mounting first; if that fails or the filesystem is one macOS never mounts, run detection and hand off to the embedded-raw provider if a matching adapter exists; if detection can't identify the filesystem or no adapter exists, record an error and decline the capture — never guess at an unrecognized format. This is what makes comparing an ext4 capture against an APFS capture an ordinary comparison rather than a special case.

## Authorization and Helper Architecture

Raw-device access, only ever needed by `EmbeddedRawProvider`, first attempts a plain read-only `open()`; if denied, it requests a one-time, scoped, read-only file descriptor via the system `/usr/libexec/authopen` utility — never a custom privileged helper, `SMJobBless` service, or root daemon, and never a standing Full Disk Access grant (`FILESYSTEM_PROVIDER_ARCHITECTURE.md` §7, `DECISIONS.md` ADR-016). If the user declines, that capture simply does not happen — no write-capable fallback exists. Separately, and for security reasons independent of the authorization question, all embedded-raw filesystem parsing runs inside its own bundled helper process (XPC service or subprocess) with no network entitlement and no access to the app's own catalog file, so a parser crash or exploit cannot take down the main app (§8, ADR-017). Neither mechanism is empirically verified yet — both are named, scoped Phase 3 and Phase 0A/2 proofs respectively, not assumed facts.

## Security Boundary

Read-only is architectural, not a disabled button, and now extends explicitly to raw-device access: no method on the provider contract can mutate a source; the deny-list of write-capable APIs (`copyItem`, `moveItem`, `removeItem`, `createFile`, `setAttributes`, `replaceItem`, `trashItem`) extends to a "no raw-block write syscall, at any privilege level" rule; CT-001 (no source writes) now runs against a raw device as well as a mounted volume (`SECURITY_AND_READ_ONLY_POLICY.md` §4.1, `TEST_PLAN.md` CT-001). Every embedded-raw parser is treated as untrusted-input attack surface regardless of its license.

## License Boundary

libfsext is LGPL-3.0-or-later; dynamic linking (bundled `.dylib`) satisfies its relinking requirement without static-linking complexity. This is engineering due diligence, not legal advice — see `DEPENDENCY_AND_LICENSE_REVIEW.md` §7: every obligation discussed (LGPL relinking, IPL/CPL file-level source availability, GPL combined-work copyleft if such a component were ever introduced) is triggered by distribution beyond the requesting user's own machine, which FSD does not currently do (ADR-006, unchanged). If FSD is ever shared more broadly, get an actual legal review before packaging any of these libraries for that audience.

## Schema Impact

Schema version 2 adds, on `snapshots`: `filesystem_provider`, `provider_version`, `source_access_mode`, `device_identifier`, `partition_identifier`, `partition_offset`, `partition_length`, `filesystem_variant`, `filesystem_features_json`, `authorization_required` — plus two new `CHECK` constraints enforcing that `native`⇔`mounted` and `embedded_raw`⇔`raw_device`/`disk_image` never cross-contaminate, and that partition offset/length are sane. On `scan_issues`: a `source` discriminator (`'scanner' | 'reader'`) instead of separate `reader_warning_count`/`reader_error_count` denormalized columns — the brief asked that those be considered; they were, and rejected in favor of a query-derivable discriminator that needs no separate consistency maintenance (`GROUP BY source, severity` gives the same answer). `case_sensitivity_source` was requested by the brief but already exists as `source_case_sensitivity` from the R0 wave — not duplicated. `raw_source_kind` was requested but folded into `source_access_mode`, which already carries the same three-way distinction (`mounted`/`raw_device`/`disk_image`) — two overlapping enumerations for one fact would have been the wrong call. All prior R0 corrections (normalization_version, snapshot_kind, source_case_sensitivity, case_preserving/folded columns, parent/root integrity constraints and triggers, transient-safe `ON DELETE RESTRICT` comparisons) are preserved unchanged. schema_migrations now records version 2; the R0 wave's own failure to bump past version 1 despite materially changing the schema is noted and corrected going forward, not silently re-committed (`database/schema.sql` header comment). Applied fresh to a temporary SQLite database with `PRAGMA integrity_check`/`foreign_key_check` both clean, and every new constraint's accept/reject behavior exercised in `database/verify.sql` — see Verification section below for exact output.

A normalized `devices`/`partitions` identity table (distinct from `volumes`) remains a **future** decision, cross-referenced from `PRD.md` §6.1 — not required for MVP.

## Revised Full Project Plan

`MVP_PLAN.md` is the single canonical phase sequence and is not duplicated here. Summary of the renumbering: **Phase 0A** (multi-filesystem feasibility, disk-image-only) and **Phase 0B** (resulting ADRs) precede **Phase 0** (Xcode/catalog foundation, gated behind both R0 audit APPROVE and Phase 0B); then **Phase 1** (provider contract + native provider), **Phase 2** (embedded-raw prototype, disk images only), **Phase 3** (physical-device authorization — the first phase to touch a real raw device, gated behind Phase 2 for the same filesystem family), **Phase 4** (snapshot persistence, now provider-agnostic), **Phase 5** (offline browser), **Phase 6** (comparison engine), **Phase 7** (automatic detection/capture, behind the pre-existing four-condition gate plus Phase 3's authorization proof), **Phase 8** (export and local packaging). Each phase in `MVP_PLAN.md` carries its own objective, dependencies, deliverables, exit criteria, automated tests, manual tests, risks, and explicit out-of-scope list, as required.

## Phase 0 Exit Criteria

Unchanged in kind from before this replan, with one addition: application launches on Apple Silicon; database is created and schema version **2** is readable; no source-volume write APIs exist anywhere in the target, **including no raw-block write syscalls**. Phase 0 itself does not start until R0 audit APPROVE and Phase 0B's ADRs are both recorded.

## Risks and Blockers

- **R0 rejection remains open and blocking Phase 0** (not resolved by this task — separate concern, separate corrective round required).
- **Phase 0A/3 are unexecuted specifications, not proofs.** libfsext could fail against the harder ext2/3/4 fixtures (non-UTF-8 names, fscrypt); raw-device permissions could require more than a single `authopen` prompt handles cleanly. Both have documented fallbacks (TSK; a defined decline-means-no-capture behavior) rather than open-ended risk.
- **Unattended authorization (Phase 7) has no user present to approve an `authopen` prompt at mount time.** `MVP_PLAN.md` Phase 7 names this as a risk to resolve during that phase (defer the capture vs. skip with a notification) rather than deciding it here, since it depends on Phase 3's empirical result.
- **Two ADR line items are explicitly "pending empirical confirmation"** (ADR-015 libfsext, ADR-016 authopen) — this is intentional honesty, not an oversight; treat them as provisional until Phase 0A/3 close them out.

## Decisions Required Before Swift Implementation

1. R0 correction round 2, closing all 14 required fixes from the rejected audit, followed by a fresh independent audit APPROVE.
2. Phase 0A executed on real disk images, confirming or overturning ADR-015 (libfsext vs. TSK fallback).
3. Phase 3 executed on a real external drive, confirming or overturning ADR-016 (authopen vs. plain `open()`).
4. Whether a normalized `devices`/`partitions` table is worth building now or genuinely deferrable (leaning deferrable, per `PRD.md` §6.1 and the schema-impact note above).
5. Phase 7's unattended-authorization behavior (defer vs. skip-with-notification), which depends on decision 3's outcome.

None of these require the user to make a snap call today — 2 and 3 are proof-gathering, not judgment calls, and 1 is a known, already-scoped corrective task.

## Final Verdict

**READY FOR INDEPENDENT AUDIT.**

This means the specification package produced by this task — `FILESYSTEM_PROVIDER_ARCHITECTURE.md`, `FILESYSTEM_SUPPORT_MATRIX.md`, `DEPENDENCY_AND_LICENSE_REVIEW.md`, `FILESYSTEM_FEASIBILITY_PLAN.md`, the schema v2 revision, and the updated canonical documents — is complete, internally consistent, evidence-based rather than research-assumed, and does not claim any runtime capability it hasn't proven. It is not a claim that Swift implementation may start: that remains blocked behind R0 audit APPROVE (unchanged, pre-existing) and Phase 0A/0B's actual execution (new, from this replan). An independent auditor reviewing this package should be checking whether the specification itself holds up — not whether the app works, since no app exists yet.
