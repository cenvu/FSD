# Dependency and License Review — Embedded Filesystem Readers

## Status

- **Canonical for:** which third-party (or Apple-native) code paths FSD may use to read each required filesystem, and under what licensing/isolation constraints.
- **Not canonical for:** the provider contract or module boundaries (see [`FILESYSTEM_PROVIDER_ARCHITECTURE.md`](FILESYSTEM_PROVIDER_ARCHITECTURE.md)) or per-filesystem completion status (see [`FILESYSTEM_SUPPORT_MATRIX.md`](FILESYSTEM_SUPPORT_MATRIX.md)).
- This document records engineering research as of 2026-07-24. It contains no legal conclusions. Any statement about license obligations is an engineering interpretation offered to inform a decision, not legal advice; a redistribution decision beyond the user's own machine should get an actual legal review before it is finalized.

## 1. Governing constraint

FSD must ship as **one self-contained `.app`** that reads APFS, HFS+, FAT16, FAT32, exFAT, NTFS, ext2, ext3, ext4, and UDF **without the user installing** Homebrew, macFUSE, ntfs-3g, kernel extensions, or app extensions. FSD does not need Finder-level mounting of unsupported filesystems — only detect → open read-only → enumerate → extract metadata → stream to SQLite → close.

## 2. The scope-changing finding: most of the list is already native

Before evaluating third-party libraries, the first question has to be "does macOS already do this without FSD's help?" It does, for most of the list, across the entire macOS 15–26 range FSD targets:

| Filesystem | macOS native support | Mechanism | Requires user install? |
|---|---|---|---|
| APFS | Read/write | Kernel-native | No |
| HFS+ | Read/write | Kernel-native | No |
| FAT16 | Read/write | `msdosfs` (kext on 13/14; FSKit-based on 15+) | No |
| FAT32 | Read/write | `msdosfs` (kext on 13/14; FSKit-based on 15+) | No |
| exFAT | Read/write | `exfat` (kext on 13/14; FSKit-based on 15+) | No |
| NTFS | **Read-only** | Kernel-native, has shipped since Mac OS X 10.3 | No — write needs third-party, read does not |
| UDF | Read/write (optical-media use case) | Kernel-native | No |
| ISO9660 | Read/write | Kernel-native | No (not in FSD's required list, but relevant — same driver family as UDF) |
| ext2 / ext3 / ext4 | **None** | — | Yes, unavoidably |

This was verified against current documentation of macOS's built-in filesystem stack (see Sources), not assumed from the original library-research angle the task brief suggested. The practical consequence: **the "embedded raw filesystem reader" problem this task set out to solve is, for MVP, a single-filesystem-family problem: ext2/ext3/ext4.** Every other filesystem in the required list is already reachable by mounting it the normal way and reading through `FileManager`/`URL` — i.e. through the `NativeMountedProvider` that the original architecture already assumed, unchanged.

This does not make the other filesystems risk-free (allocated-size reliability, case sensitivity, timestamp precision, and NTFS/exFAT quirks are still real — see the support matrix) — it means they need **no new dependency, no new provider, and no new authorization path.** Only ext2/3/4 does.

One clarification the brief's exact wording invites: whether the OS's own bundled `msdosfs`/`exfat`/NTFS/UDF drivers count as "kernel extensions" the user is "installing." They do not, under the reading this document adopts: they ship inside every macOS installation FSD targets and require no action from the FSD user — no download, no `kextload`, no System Settings approval flow, no admin password. The user only ever inserts a drive and it mounts, exactly as it does today with no FSD involved. Sections 4–5 apply the same "already part of the OS vs. something FSD asks the user to add" distinction to the one filesystem family that does need help.

## 3. Candidates evaluated for the ext2/ext3/ext4 gap

### 3.1 libfsext (libyal project)

| Field | Finding |
|---|---|
| Supported filesystems | ext2, ext3, ext4 |
| Read-only capability | Yes — the library is read-only by design; it exposes no write API |
| macOS arm64 build status | Builds as a standard autotools/C library; no Apple-specific blockers found. Not distributed as a prebuilt Apple-Silicon binary by the project itself — FSD would build it from source as part of its own build, once |
| Minimum macOS compatibility | No macOS-version floor of its own; it links against nothing macOS-specific (pure C, POSIX file I/O over a byte-range source) |
| Maintenance status | Actively maintained; releases as recently as May 2026 per the project's release history. Labeled "experimental" by the project's own convention (libyal's standing label for its whole library family, not a project-specific abandonment signal) |
| License | LGPL-3.0-or-later |
| Static or dynamic linking implications | LGPL-3.0 is satisfiable either way, but **dynamic linking (bundled as a `.dylib`/framework inside `FSD.app/Contents/Frameworks/`) is the low-friction path**: it trivially satisfies the LGPL relinking requirement (a user could swap the dylib) without the extra bookkeeping static linking would invite. Recommendation: dynamic, bundled, never system-installed |
| Bundle size | Small — a single-purpose C library in the tens-to-low-hundreds of KB compiled, negligible next to a Swift/AppKit app bundle |
| Security risk | It parses untrusted, potentially adversarial on-disk structures (superblocks, inode tables, directory entries) from a filesystem FSD did not create. Treat as untrusted-input attack surface regardless of license — see Section 6 |
| Known limitations | "Experimental" status label; narrower community size than TSK; feature coverage tracks ext2/3/4 only (no bonus filesystems, which here is a feature, not a gap) |
| Elevated privileges to access source | No privilege of its own — it reads whatever byte-range file descriptor or buffer it is handed. The privilege question lives entirely in how FSD obtains that descriptor (Section 5), not in this library |

**Recommendation: primary candidate.** Narrowly scoped to exactly the one gap FSD has, LGPL is the most permissively-isolable license family reviewed here, and it is a small, embeddable, actively-maintained C library with no macOS-specific build risk identified.

### 3.2 The Sleuth Kit (TSK / libtsk)

| Field | Finding |
|---|---|
| Supported filesystems | NTFS, FAT12/16/32, exFAT, ext2/3/4, HFS+, ISO9660, YAFFS2, Btrfs, plus volume-system (partition table) parsing |
| Read-only capability | Yes — TSK is a forensic analysis toolkit; read-only is its whole design point |
| macOS arm64 build status | Historically the build system had no native arm64 target directory and assumed Intel macOS; more recently, Homebrew produces an `arm64_sequoia` bottle for TSK 4.14.0, indicating the project (via Homebrew's build farm) does now build natively for Apple Silicon. FSD would still need to build/vendor it itself rather than depend on a user's Homebrew install, per the governing constraint |
| Minimum macOS compatibility | No specific floor found beyond general POSIX/C++ toolchain requirements |
| Maintenance status | Actively maintained, large long-running forensics project |
| License | Core library (`libtsk`) is predominantly IBM Public License 1.0 / Common Public License 1.0 — file-scoped weak-copyleft licenses (conceptually closer to MPL than to GPL: they require sharing modifications to the licensed files themselves, not to the whole combined program) |
| Static or dynamic linking implications | IPL/CPL do not carry GPL's "combined work" linking clause, so linking (static or dynamic) does not by itself trigger an obligation to relicense FSD's own code. The obligation that does apply is to preserve TSK's own license and offer source for any modified TSK files, if redistributed |
| Bundle size | Materially larger than libfsext — TSK is a multi-filesystem, multi-tool toolkit with additional dependencies (e.g. `libewf` for forensic image formats, zlib); on the order of several MB once built, versus tens-to-low-hundreds of KB for a single-purpose libyal library |
| Security risk | Same untrusted-input surface as any raw filesystem parser, over a much larger and more complex codebase (multi-filesystem, multi-image-format) — larger attack surface for the one filesystem family FSD actually needs |
| Known limitations | Historically rougher on native Apple Silicon builds (improving, per the Homebrew bottle); broad scope is a poor fit when only ext2/3/4 is missing natively |
| Elevated privileges | Same as libfsext — no privilege of its own |

**Recommendation: not selected for MVP.** TSK's breadth is real value for a forensics tool, but for FSD it duplicates filesystems macOS already reads natively (NTFS, FAT, exFAT, HFS+), while adding bundle size, build complexity, and attack surface to close the one gap (ext2/3/4) that libfsext already closes more narrowly. Keep as a documented fallback only if libfsext's ext2/3/4 support fails a Phase 0A/2 feasibility test on real fixtures.

### 3.3 e2fsprogs / libext2fs

Not selected for evaluation in depth: it is GPL-2.0-licensed (a "combined work" copyleft, stronger than LGPL or IPL/CPL for linking purposes), and libfsext already covers the same ground under a materially easier-to-isolate license. Documented here only so the choice is visibly deliberate, not an oversight. If it is ever reconsidered, run it as a wholly separate helper **process** communicating over IPC (Section 6's "Reader helper process" boundary already required for security reasons independently covers the GPL isolation concern — see Section 7 for that reasoning generalized).

### 3.4 macFUSE + ext4fuse / ntfs-3g

Excluded by the user's explicit constraint: these require the user to install an app extension (macFUSE) themselves. Not evaluated further.

### 3.5 Apple FSKit (`FileSystemKit`, macOS 15+ public API)

| Field | Finding |
|---|---|
| Supported filesystems | Whatever a developer implements; third parties have built ext4 (`ExtendFS`) and other readers on it |
| Read-only capability | Can be implemented read-only |
| Minimum macOS compatibility | **macOS 15 (Sequoia) or later** for the public third-party API — it existed privately from macOS 14 but was not available to third-party developers until 15 |
| Maintenance status | Apple's own current direction for future userspace filesystems (exFAT/FAT32 themselves moved to FSKit internally in later macOS) |
| License | N/A — Apple system framework |
| Packaging | An FSKit reader ships as an **app extension** the user approves once in System Settings — this is precisely the category ("app extensions") the task's explicit constraint rules out, regardless of macOS version |

**Recommendation: excluded**, on one still-decisive reason: (b) FSKit extensions are packaged and approved as app extensions, which the user has explicitly said FSD must not require — this remains independent of any macOS version. The former reason (a) is **SUPERSEDED**: it read that FSKit's macOS 15+ floor sat above FSD's stated macOS 13+ minimum, and FSD's minimum supported deployment is now macOS 15+ (ADR-033), so reason (a) is no longer an exclusion ground and must not be cited again. The exclusion itself is unchanged: FSKit stays out. Recorded here so the exclusion is deliberate and documented, not a research gap — this is the one candidate the task brief did not explicitly name but that a reasonable "current options" search surfaces immediately, so it needs an explicit ruling.

### 3.6 UDF-specific libraries

No actively maintained, redistributable, permissively-isolable *userspace* UDF-reader library was found as a distinct candidate. This is a non-issue for MVP: Section 2 already established that macOS mounts UDF natively read/write with no user install across the whole target range. Recorded as a closed research item, not an open gap: **no UDF library decision is needed** because no UDF library is needed.

## 4. Raw access mechanics for the one real gap (ext2/3/4)

Reading an ext4 partition macOS will not mount means reading raw bytes from either (a) a disk-image file, or (b) the raw partition device node (`/dev/rdiskNsM`). This is a mechanics question, not a library question — libfsext (or whatever reader is chosen) only ever operates on a byte-range source FSD hands it.

- **Disk image (`.img`/`.dmg`/raw byte-for-byte file)**: a plain `open()`/`read()`/`mmap()` on a regular file. No privilege question at all. This is why Phase 0A/2 test first against disk images (Section 6 of [`FILESYSTEM_FEASIBILITY_PLAN.md`](FILESYSTEM_FEASIBILITY_PLAN.md)) — it isolates the filesystem-parsing risk from the device-authorization risk.
- **Physical raw device node**: ownership and permission of `/dev/rdiskN` varies by media type and macOS version — some sources describe removable-media raw nodes as owned by the console user (no extra privilege needed to open read-only), others report `Permission Denied` requiring Full Disk Access or an authorized handle. **This is not settled by research alone and must be verified empirically on real target hardware in Phase 0A/3** (see feasibility plan) — this document does not claim a runtime guarantee either way.

## 5. Authorization boundary — do not build a custom privileged helper

If direct `open()` of a raw device node is denied, the recommended mechanism is the **system-provided `/usr/libexec/authopen` utility**, not a custom SMJobBless helper or root daemon:

- `authopen` is a long-standing macOS utility (present through at least Sonoma/Sequoia per current documentation) that requests one-time user authorization (a native macOS authentication prompt) and hands back an already-open, read-only file descriptor over a Unix-domain socket, without granting the calling app any broader privilege, root access, or standing entitlement.
- FSD would invoke it as a subprocess exactly once per raw-device capture attempt, request the FD read-only, and never request write access.
- This avoids: writing and code-signing a privileged helper tool, `SMJobBless`/`SMAppService` registration, an XPC-based root daemon, or asking the user to grant FSD standing Full Disk Access — all heavier and riskier than a single scoped, user-visible authorization prompt.
- **Not yet empirically verified in this project** — Phase 0A/3 must confirm `authopen` (or the plain `open()` path, if permissions turn out to already allow it for the relevant media class) actually yields a working read-only descriptor for a real external ext4-formatted drive on the target hardware, before this is treated as proven.

This satisfies the brief's explicit "local authorization requirements" question: the answer is a single scoped, native, one-shot authorization prompt tied to the exact device being captured — never a standing grant, never sudo, never a background daemon with retained privilege.

## 6. Reader helper process — isolation for security, independent of license

Treat every embedded filesystem parser as an **untrusted-input attack surface**: it parses structures from removable media FSD did not create, which may be corrupted, adversarially crafted, or simply from an unfamiliar filesystem variant. A parser bug (buffer overrun, infinite loop, crash) should not be able to take down the main app process that holds the SQLite catalog and UI, and should not run with any more privilege than reading the bytes it was handed.

Recommendation: run libfsext (and any future embedded raw-filesystem library) inside a **separate helper process** bundled inside `FSD.app` (an XPC service under `Contents/XPCServices/`, or a plain subprocess under `Contents/MacOS/` invoked via `Process`) that:

- receives only a read-only file descriptor or byte-range handle (never a writable one, never broader filesystem access);
- has no network entitlement and no access to the app's own SQLite catalog file;
- streams parsed metadata records back to the main process over a defined IPC protocol (batched records, not a shared memory tree);
- can be killed and restarted by the main process if it crashes or hangs, without taking the capture's already-committed SQLite rows with it (consistent with the existing transactional/interrupted-snapshot model).

This is a **security** boundary, independent of licensing — it would be the right design even if libfsext were public domain. It also happens to be exactly the mechanism that would isolate a GPL component (Section 3.3/3.4) if one were ever chosen instead: running GPL code as a separate program communicating over IPC is the standard "mere aggregation, not a combined work" pattern most engineering guidance points to for keeping a GPL dependency's copyleft from reaching the calling program — again, an engineering interpretation, not a legal conclusion, and one that would need real legal review before any redistribution beyond the user's own machine.

## 7. Redistribution note

FSD today is a local-only build for the requesting user's own machine (no Apple Developer account, no notarization, no App Store, no public DMG — consistent with ADR-006). Every license obligation discussed above (LGPL relinking, IPL/CPL file-level source availability, GPL combined-work copyleft if ever introduced) is triggered by **distribution to someone else**, not by building and running the app locally. If FSD is ever shared beyond the requesting user, revisit this document and get an actual legal review before packaging any of the libraries discussed here for that wider audience — this document is engineering due diligence, not a substitute for that review.

## 8. Summary decision

- **Native filesystems (APFS, HFS+, FAT16, FAT32, exFAT, NTFS-read, UDF):** no new dependency. Use the existing `NativeMountedProvider` design unchanged.
- **ext2/ext3/ext4:** bundle **libfsext** (LGPL-3.0-or-later), dynamically linked inside `FSD.app/Contents/Frameworks/`, driven from an isolated reader helper process (Section 6), fed by either a disk-image file (trivial) or an `authopen`-obtained read-only raw-device descriptor (Phase 0A/3 must verify this empirically).
- **TSK, e2fsprogs, macFUSE-based tools, FSKit:** documented and explicitly not selected, for the reasons in Sections 3.2–3.5.
- **UDF-specific library:** none needed — native OS support already covers it.

Sources consulted: [libyal organization](https://github.com/libyal), [libfsext](https://github.com/libyal/libfsext), [libfsapfs](https://github.com/libyal/libfsapfs), [libfshfs](https://github.com/libyal/libfshfs), [libfsntfs](https://github.com/libyal/libfsntfs), [libfsfat](https://github.com/libyal/libfsfat), [The Sleuth Kit](https://github.com/sleuthkit/sleuthkit), [TSK arm64 Homebrew build issue discussion](https://github.com/sleuthkit/sleuthkit/issues/3213), [Eclectic Light Co. — macOS 26 native filesystem support](https://eclecticlight.co/2025/11/18/which-local-file-systems-does-macos-26-support/), [Apple FSKit developer forum thread](https://developer.apple.com/forums/thread/776322), [ExtendFS (FSKit-based ext4 reader)](https://github.com/kthchew/ExtendFS), [authopen man page](https://keith.github.io/xcode-man-pages/authopen.1.html).
