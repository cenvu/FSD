# Filesystem Support Matrix

## Status

Canonical for per-filesystem support level and behavior. Provider mechanics are defined once in [`FILESYSTEM_PROVIDER_ARCHITECTURE.md`](FILESYSTEM_PROVIDER_ARCHITECTURE.md) and referenced here, not repeated.

## 1. What "supported" means (the only definition FSD uses)

A filesystem is **Supported** only after FSD has, in this order, on a real or representative image:

1. detected it;
2. opened it read-only;
3. enumerated a real or representative image;
4. captured the required metadata;
5. persisted a complete snapshot;
6. reopened the snapshot offline;
7. verified no source write occurred (the CT-001 check, applied per filesystem).

Until all seven have actually happened, the correct label is **Targeted**, not "Supported" — regardless of what any library's own documentation claims. This matrix is amended in place as each filesystem clears the seven steps — it is not amended by asserting a higher status from research alone.

**Updated 2026-08-04 (Milestone 3 closeout).** APFS, case-sensitive APFS, HFS+, HFSX, FAT16, FAT32, exFAT and UDF cleared all seven steps against generated disk images; see §2.1.1 for the closeout measurements. NTFS remains **ENVIRONMENT-BLOCKED — PROVIDER PATH NOT INVALIDATED** because this stock macOS host has no formatter or `mount_ntfs` helper. No physical device, no removable medium and no raw device was used.

## 2. Support level summary

| Filesystem | Provider (preferred) | Provider (fallback) | Support level |
|---|---|---|---|
| APFS | `NativeMountedProvider` | none needed | **Supported** (2026-08-04 closeout, insensitive image) |
| APFS case-sensitive | `NativeMountedProvider` | none needed | **Supported** (2026-08-04 closeout, generated image) |
| HFS+ | `NativeMountedProvider` | none needed | **Supported** (2026-08-04 closeout, insensitive image) |
| HFSX (case-sensitive HFS+) | `NativeMountedProvider` | none needed | **Supported** (2026-08-04 closeout, generated image) |
| FAT16 | `NativeMountedProvider` | none needed | **Supported** (2026-08-04, disk image) |
| FAT32 | `NativeMountedProvider` | none needed | **Supported** (2026-08-04, disk image) |
| exFAT | `NativeMountedProvider` | none needed | **Supported** (2026-08-04, disk image) |
| NTFS | `NativeMountedProvider` (read-only mount) | none needed | Targeted — **ENVIRONMENT-BLOCKED for a stock-macOS proof** (see §2.2) |
| UDF | `NativeMountedProvider` | none needed | **Supported** (2026-08-04, disk image) |
| ext2 | `EmbeddedRawProvider` (libfsext adapter) | TSK, only if libfsext fails feasibility | Targeted |
| ext3 | `EmbeddedRawProvider` (libfsext adapter) | TSK, only if libfsext fails feasibility | Targeted |
| ext4 | `EmbeddedRawProvider` (libfsext adapter) | TSK, only if libfsext fails feasibility | Targeted |

The closeout rerun covers both case-sensitivity variants of the native Apple
filesystems. FSD records the driver-reported type (`apfs` or `hfs`) and the
detected case-sensitivity decision separately.

## 2.1 Milestone 3 empirical results

Method, identical for every row: `hdiutil create` a generated image; attach read-write and write a fixture tree; detach; take a SHA-256 of the **image file** with nothing mounted; re-attach **read-only**; run a real capture through `SnapshotScanner`/`NativeMountedProvider` into an isolated `/tmp` catalog; detach; re-take the SHA-256; then reopen the snapshot with the image detached and browse, search and export it. Harness: `FSDTests/FilesystemMatrixTests.swift`.

| | FAT16 | FAT32 | exFAT | UDF | NTFS |
|---|---|---|---|---|---|
| Image creation | `hdiutil create -size 16m -fs "MS-DOS FAT16"` | `-size 64m -fs "MS-DOS FAT32"` | `-size 64m -fs ExFAT` | `-size 64m -fs UDF` | blank image + `diskutil eraseVolume "Tuxera NTFS"` |
| Mount mode | read-only, `noowners`, `nobrowse` | read-only | read-only | read-only | read-only |
| Driver reported by `mount` | `msdos` (fskit) | `msdos` (fskit) | `exfat` (fskit) | `udf` | `tuxera_ntfs` (third party) |
| `statfs` type FSD records | `msdos` | `msdos` | `exfat` | `udf` | `tuxera_ntfs` |
| Detected read-only | yes | yes | yes | yes | yes |
| Detected case sensitivity | `insensitive` | `insensitive` | `insensitive` | `sensitive` | `sensitive` |
| Case **preservation** (`A001.RAW` / `A002.raw`) | preserved | preserved | preserved | preserved | preserved |
| Capture status | `complete` | `complete` | `complete` | `complete` | `complete` |
| Entries / files / folders | 10 / 6 / 4 | 10 / 6 / 4 | 10 / 6 / 4 | 10 / 6 / 4 | 14 / 9 / 5 |
| Inaccessible items / scan issues | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 |
| Capture duration | 0.009 s | 0.014 s | 0.013 s | 0.004 s | 0.009 s |
| Source integrity (image SHA-256 before vs after) | **identical** | **identical** | **identical** | **identical** | **identical** |
| Step 6 — reopen offline, source detached | pass | pass | pass | pass | pass |
| Unmount / cleanup | clean, 0 volumes left attached | clean | clean | clean | clean |

Notes worth carrying forward:

- **FAT16 and FAT32 are indistinguishable to FSD.** Both mount through `msdosfs` and `statfs` reports `msdos` for each, so `filesystem_variant` cannot separate them. Nothing in the MVP depends on the distinction; recorded here so no later feature assumes it exists.
- **UDF detects as case-sensitive**, unlike this document's §3 expectation of "effectively case-insensitive in common practice". The detection is empirical (`volumeSupportsCaseSensitiveNamesKey`), which is what ADR-010's two-source key selection consumes, so the behaviour is correct — but §3's prose is a prediction that the fixture did not confirm.
- **NTFS's extra four entries** are a `.fseventsd` directory macOS itself created while the image was attached read-write during fixture preparation. FSD saw it only through the read-only mount. It is a useful reminder that a mounted volume gains OS-created files whether or not FSD is running — and that FSD is provably not the writer here, since the image hash is identical across the capture.
- A `.hedge-enabled` file appeared on every image, written by unrelated third-party software on the test machine during the read-write preparation phase. Same reasoning: outside FSD, and outside the hashed window.

### 2.1.1 Milestone 3 closeout rerun

On 2026-08-04 the same seven-step harness was rerun for every format the host
could create and mount. The fixture contained four files and five directories;
all captures persisted one root, completed with zero issues, and reopened
offline after the mount point directory was removed. The source image SHA-256
was identical before and after each capture.

| Variant | Create/mount | Detected type / variant | Read-only | Case sensitivity | Capture | Entries / files / folders | Issues | Seconds | Offline |
|---|---|---|---|---|---|---:|---:|---:|---|
| APFS | pass | `apfs` / `apfs` | yes | insensitive | complete | 10 / 5 / 5 | 0 | 0.004 | pass |
| APFS case-sensitive | pass | `apfs` / `apfs` | yes | sensitive | complete | 10 / 5 / 5 | 0 | 0.003 | pass |
| HFS+ | pass | `hfs` / `hfs` | yes | insensitive | complete | 10 / 5 / 5 | 0 | 0.004 | pass |
| HFSX | pass | `hfs` / `hfs` | yes | sensitive | complete | 10 / 5 / 5 | 0 | 0.003 | pass |
| FAT16 | pass | `msdos` / `msdos` | yes | insensitive | complete | 10 / 5 / 5 | 0 | 0.013 | pass |
| FAT32 | pass | `msdos` / `msdos` | yes | insensitive | complete | 10 / 5 / 5 | 0 | 0.012 | pass |
| exFAT | pass | `exfat` / `exfat` | yes | insensitive | complete | 10 / 5 / 5 | 0 | 0.010 | pass |
| UDF | pass | `udf` / `udf` | yes | sensitive | complete | 10 / 5 / 5 | 0 | 0.005 | pass |

The generated image set and machine-readable reports were held under
`/tmp/FSD-M3-Matrix.AtpxYE` during the run. NTFS was not attempted because
`/System/Library/Filesystems/ntfs.fs/mount_ntfs` and a stock formatter are
absent; it remains environment-blocked, not provider-invalidated.

## 2.2 NTFS — ENVIRONMENT-BLOCKED, PROVIDER PATH NOT INVALIDATED

The NTFS capture succeeded, but it cannot be counted toward `Supported`:

- This macOS build ships `/System/Library/Filesystems/ntfs.fs` **without a `mount_ntfs` helper**, and provides no NTFS formatter. A stock-only NTFS image could be neither created nor mounted here.
- The only NTFS path available on the test machine is **Tuxera NTFS**, third-party software installed for unrelated reasons. `AGENT.md`'s platform invariant forbids FSD requiring any such install, so a Tuxera-mediated result says nothing about what a stock macOS user would get.
- `statfs` reported `tuxera_ntfs`, so `filesystem_variant` records the *driver*, not the filesystem. Any future code that keys on `filesystem_variant` must treat it as a driver identifier.

What the run does establish: `NativeMountedProvider` is genuinely generic. It captured an NTFS volume correctly with no NTFS-specific code, and left the image byte-identical. The provider path is not invalidated — only the stock-macOS proof is missing. Re-run on a machine with a stock NTFS mount path, or with a supplied NTFS image, to close it.

## 3. Per-filesystem detail

### APFS

- Preferred / fallback provider: `NativeMountedProvider` / none needed.
- Required metadata available: full — logical/allocated size, creation/modification/change/access times, resource identifier (`fileResourceIdentifierKey`, stable only while mounted), package flag, symlink flag, hidden flag, content type.
- Unsupported metadata: content-level Merkle/`fsverity`-style trees are out of scope regardless (FSD does not read content).
- Case sensitivity: both case-sensitive and case-insensitive APFS variants exist; must be read per-volume (`URLResourceKey.volumeSupportsCaseSensitiveNamesKey`), never assumed from filesystem type alone.
- Unicode/name normalization: APFS is normalization-**preserving** and normalization-**insensitive** for lookup, but does not itself force a canonical form on disk — two visually identical names can arrive in different Unicode normalization forms from different write origins. FSD's own path-normalization recipe (`ARCHITECTURE.md` §5) is what makes this comparable, not the filesystem.
- Symbolic-link behavior: native symlinks; recorded, not followed, per the existing default.
- Hard-link behavior: supported by APFS; recorded as ordinary distinct entries (per the existing product decision that a metadata catalog shows the tree as it is, not deduplicated).
- Sparse-file behavior: supported; logical vs. allocated size diverges — logical remains the default equality field.
- Allocated-size reliability: reliable for APFS's own allocation model, but not portable across the comparison boundary to other filesystems (`PRODUCT_STATE.md` KI-004 already covers this).
- Encryption: FileVault-encrypted APFS volumes present as an ordinary mounted, decrypted volume to a process running as the unlocked user — no additional handling needed; an **unmounted, still-encrypted** APFS volume is out of scope (FSD does not prompt for or handle unlock secrets).
- Corruption behavior: a corrupt APFS container generally fails to mount at all; if it does mount, treat any read error as a per-entry `scan_issue`, never as a `complete` snapshot with silently-omitted regions.
- Read-only guarantee: absolute — normal mount access grants no write capability FSD would use.

### HFS+

- Same provider path as APFS.
- Required/unsupported metadata: same core set as APFS; no `fileResourceIdentifierKey` stability guarantee assumed (HFS+ semantics differ from APFS here — verify empirically rather than assuming APFS behavior carries over).
- Case sensitivity: both case-sensitive (HFSX) and case-insensitive HFS+ variants exist; read per-volume, same as APFS.
- Unicode/name normalization: HFS+ is well known for storing names in NFD; this is the specific case FSD's normalization recipe must handle, since a file written on HFS+ and later compared against an APFS or exFAT capture of "the same" name can differ at the raw string level despite being the same logical name.
- Symbolic-link / hard-link / sparse-file: supported by HFS+; same recording policy as APFS.
- Allocated-size reliability: HFS+ allocation blocks are large by modern standards; expect bigger logical/allocated deltas on small files than APFS — informational only, not an equality field.
- Encryption: CoreStorage-encrypted HFS+ volumes present decrypted once mounted and unlocked; same out-of-scope note as APFS for locked volumes.
- Corruption / read-only guarantee: same as APFS.

### FAT16

- Preferred provider: `NativeMountedProvider` (native `msdosfs` driver; see `DEPENDENCY_AND_LICENSE_REVIEW.md` §2 for the kext-vs-FSKit distinction across macOS versions — irrelevant to FSD either way since it is OS-bundled).
- Required metadata available: name, type, logical size, a single coarse modification timestamp (FAT date/time fields are commonly 2-second granularity), directory/file flag.
- Unsupported metadata: no resource identifier, no true creation-vs-modification distinction beyond FAT's own limited date fields, no package concept, no native symlink concept (FAT has none — any "link-like" entry is a `.lnk`/shortcut file at the content level, which FSD does not parse).
- Case sensitivity: FAT16 itself is case-insensitive (commonly case-preserving only via the VFAT long-name extension); treat as `insensitive` for the diff engine's two-source key selection (`ARCHITECTURE.md` §5.1).
- Unicode/name normalization: long filenames (VFAT LFN) are UTF-16-based; short 8.3 names are a separate legacy representation FSD should ignore in favor of the long name when present.
- Symbolic-link / hard-link: not a FAT concept; both fields simply absent.
- Sparse-file behavior: not a FAT concept.
- Allocated-size reliability: cluster-size rounding can be coarse on old FAT16 media (small partitions, large cluster sizes); informational only.
- Encryption: none at the filesystem level.
- Corruption behavior: FAT16 media is old and more failure-prone than modern filesystems in practice; expect a higher `scan_issues` rate on real legacy hardware — do not treat that as a bug in FSD.
- Read-only guarantee: absolute.

### FAT32

- Same as FAT16 in every respect except: 4-byte cluster addressing (larger volumes), and the same 2-second-granularity modification timestamp caveat (already reflected in the seeded Strict Metadata profile's tolerance default). Same case-insensitivity and normalization notes as FAT16.

### exFAT

- Preferred provider: `NativeMountedProvider` (native driver across the whole target range, per the dependency review).
- Required metadata available: name, type, logical size, allocated size (exFAT's allocation model is cluster-based like FAT but with finer-grained sizing), creation and modification timestamps (10ms-resolution creation time is possible on exFAT, unlike FAT16/32 — verify actual resolution empirically rather than assuming the spec ceiling), hidden flag.
- Unsupported metadata: no resource identifier, no native symlink concept, no package concept.
- Case sensitivity: exFAT is case-insensitive, case-preserving; treat as `insensitive` for diff key selection, same as FAT.
- Unicode/name normalization: exFAT stores UTF-16 names; no on-disk normalization guarantee — same NFC/NFD collision risk as HFS+/APFS applies here on the FSD normalization layer, not the filesystem.
- Symbolic-link / hard-link: not an exFAT concept.
- Sparse-file behavior: exFAT does support a form of sparse allocation for some use cases; treat allocated size as best-effort, never as an equality field (`KI-004`).
- Allocated-size reliability: better than legacy FAT but still not portable across filesystems for comparison purposes.
- Encryption: none at the filesystem level (exFAT itself has no built-in encryption).
- Corruption behavior: common on cheap USB/SD media; expect real-world `scan_issues`.
- Read-only guarantee: absolute — exFAT is also natively read-write on macOS, so this is a case where FSD deliberately uses less capability than the OS offers, by design (metadata-only, read-only regardless of what the mount itself would allow).

### NTFS

- Preferred provider: `NativeMountedProvider`, **read-only mount** (macOS has never offered native NTFS write support without third-party software; FSD only ever needs read, so this is a non-issue rather than a limitation for FSD specifically).
- Required metadata available: name, type, logical size, allocated size, creation/modification/MFT-change/access timestamps (NTFS carries all four), hidden and system attribute flags, reparse-point (symlink/junction) flag.
- Unsupported metadata: NTFS resource forks/alternate data streams are not read (FSD does not read content, and ADS enumeration is explicitly out of scope — do not add it as a "just the name" special case, since a stream name without content is low-value and adds surface area).
- Case sensitivity: NTFS is case-sensitive at the filesystem level in principle but is used case-insensitively by convention (and by the Windows subsystem layer); treat as `insensitive` for FSD's diff key selection unless empirical testing on a real macOS-mounted NTFS volume shows otherwise.
- Unicode/name normalization: NTFS stores UTF-16 names with no forced normalization; same collision-handling responsibility falls on FSD's own normalization layer.
- Symbolic-link behavior: NTFS reparse points (symlinks/junctions) exist; record their presence and target string when readable via the mounted macOS view, do not follow them, consistent with the existing default.
- Hard-link behavior: NTFS supports hard links; record as distinct entries, same policy as APFS/HFS+.
- Sparse-file behavior: NTFS supports sparse files; logical vs. allocated divergence is possible — logical remains the equality field.
- Allocated-size reliability: NTFS cluster sizing varies by volume; informational only.
- Encryption: EFS-encrypted files/folders on NTFS will not be readable as data by a macOS mount in any useful sense; treat as an inaccessible-item `scan_issue`, never as a silent zero-size entry.
- Corruption behavior: macOS's read-only NTFS driver is conservative; a sufficiently damaged NTFS volume may simply fail to mount rather than mount partially — treat mount failure as "not currently readable," not as an EmbeddedRawProvider trigger (NTFS is not in the embedded-provider fallback list; see Section 2).
- Read-only guarantee: absolute, and in this specific case also structurally guaranteed by the OS (there is no write path to accidentally use).

### UDF

- Preferred provider: `NativeMountedProvider` (native across the target range).
- Required metadata available: name, type, logical size, a modification timestamp; UDF's metadata richness is generally lower than APFS/HFS+ since it targets optical/write-once media semantics.
- Unsupported metadata: no resource identifier, no package concept, symlink support is UDF-revision-dependent and should be treated as absent unless empirically observed.
- Case sensitivity: UDF is effectively case-insensitive in common practice; treat as `insensitive`.
- Unicode/name normalization: UDF uses OSTA-compressed Unicode names; no forced normalization — same FSD-side handling as other filesystems.
- Symbolic-link / hard-link: treat as absent by default; revisit only if a real UDF fixture shows otherwise.
- Sparse-file behavior: not applicable to UDF's typical (optical/write-once or rewritable) use case.
- Allocated-size reliability: UDF packet/sector sizing (commonly 2048 bytes for optical media) makes allocated size a poor comparison field even more than usual; logical size only.
- Encryption: none at the filesystem level.
- Corruption behavior: scratched/degraded optical media is the realistic failure mode; expect read errors mid-enumeration and record them as `scan_issues`, never as silent gaps.
- Read-only guarantee: absolute; UDF media in FSD's actual use case (data drives, disk images) is read-only in practice regardless.

### ext2

- Preferred provider: `EmbeddedRawProvider`, ext2/3/4 adapter over libfsext (see the dependency review). Fallback: TSK, only if libfsext fails a Phase 0A/2 feasibility test.
- Required metadata available (per libfsext's documented capability, **not yet runtime-verified by FSD**): name, type (file/directory/symlink/device-special — FSD only records file/directory/symlink, per the existing item-type taxonomy), logical size, inode change/modification/access timestamps, permission bits (captured for diagnostic display only — FSD does not model or compare POSIX permissions as an equality field, per the existing MVP scope), symlink target.
- Unsupported metadata: no macOS-style resource identifier or content-type UTI (these are macOS-specific concepts absent from ext2's own metadata); no package concept (ext2 has no bundle notion).
- Case sensitivity: ext2 is case-sensitive by default (standard Linux behavior); record `source_case_sensitivity = 'sensitive'` unless a specific volume is later found to use a case-insensitivity feature flag (rare, ext4-era addition — see ext4 below).
- Unicode/name normalization: ext2 stores names as an uninterpreted byte sequence — there is no filesystem-level Unicode concept at all. This is the filesystem where FSD's "unrepresentable bytes" handling (`ARCHITECTURE.md` §5 / ADR-009) is most likely to actually trigger, since a non-UTF-8 byte sequence is legal on ext2 and illegal as a Swift `String`. This must be exercised in the Phase 0A/2 fixture set (see feasibility plan), not assumed away.
- Symbolic-link behavior: native; recorded, not followed, same default as everywhere else.
- Hard-link behavior: native; recorded as distinct entries, same policy as elsewhere.
- Sparse-file behavior: supported; logical remains the equality field.
- Allocated-size reliability: block-size dependent (commonly 4096 bytes); informational only, and additionally only as reliable as the embedded reader's own block-accounting — this is a place a library bug or an FSD adapter bug could plausibly under/over-report, so cross-check against a ground-truth tool (e.g. `du`/`stat` inside a disposable Linux VM used only to build the test fixture, never as part of FSD's own runtime) during Phase 0A/2.
- Encryption: ext2 itself has no filesystem-level encryption (unlike ext4's fscrypt, see below); not a concern for this specific version.
- Corruption behavior: **the highest-risk row in this matrix**, because the parser reading it is new, third-party, and driven by data FSD does not control. A malformed ext2 image must produce bounded `scan_issues`, never a crash that takes the whole app down (this is precisely why Section 8 of `FILESYSTEM_PROVIDER_ARCHITECTURE.md` isolates the parser into its own process) and never a partial read presented as `complete`.
- Read-only guarantee: enforced by the provider contract (Section 6 of the provider architecture) — libfsext itself has no write API to misuse in the first place.

### ext3

- Same as ext2 in every respect, plus: a journal is present. The journal is metadata-irrelevant to FSD (FSD does not replay or validate journals — it reads the current on-disk state as-is) but its presence is exactly what `filesystem_variant` should record to distinguish ext3 from ext2 during detection (Section 5 of the provider architecture), since the two are otherwise structurally identical at the level FSD reads.

### ext4

- Same base metadata set as ext2/ext3, plus features detection must account for: extents-based allocation (affects how the adapter walks block/extent trees, not what metadata FSD records), a 64-bit block feature flag on very large volumes, and optional **case-insensitivity** and **fscrypt encryption** feature flags that a subset of real-world ext4 volumes enable.
  - Case sensitivity: **must be read per-volume from the ext4 feature flags**, not assumed `sensitive` by default the way ext2/ext3 can be — this is the one embedded-raw filesystem where the case-sensitivity field genuinely needs feature-flag inspection rather than a fixed default.
  - Encryption: an fscrypt-encrypted directory subtree, read without the decryption key (which FSD never has and never requests), exposes only encrypted filenames and unreadable content. Treat such a subtree as `is_inaccessible = 1` with a `scan_issue`, never as a decoded name — this must not be quietly misrepresented as a normal entry.
- Corruption / read-only guarantee: same reasoning as ext2/ext3, at higher stakes given the larger feature surface (extents, 64-bit, encryption, case-folding) the adapter must correctly recognize or safely decline rather than misparse.

## 4. Filesystems and features explicitly out of scope

Network filesystems (SMB, NFS, AFP) remain experimental/deferred per `PRODUCT_STATE.md` KI-007, unchanged by this replan — they are a transport/latency problem orthogonal to the provider architecture, not a new filesystem-family problem. ZFS and Btrfs were considered during dependency research (`DEPENDENCY_AND_LICENSE_REVIEW.md` §3.5) and are not part of the required list — no work is planned for them.
