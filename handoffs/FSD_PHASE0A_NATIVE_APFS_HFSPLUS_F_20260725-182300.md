# Phase 0A Handoff: Native AppleFS Feasibility (APFS & HFS+)
Date: 2026-07-25
Author: Claude (Primary Forge)

## 1. Goal
Execute a disk-image-only feasibility spike for native metadata enumeration of APFS and HFS+ using Foundation `FileManager`, confirming safety, determinism, and exact Unicode/case-sensitivity behavior.

## 2. Methodology
- Created four 50MB disk images: APFS (case-insensitive), APFSX (case-sensitive), HFS+ Journaled (case-insensitive), HFSX (case-sensitive).
- Populated images with edge-case fixtures: valid/broken symlinks, long filenames, sparse files, and specific NFC/NFD Unicode pairs (`café_NFC.txt`, `café_NFD.txt`). Case-distinct fixtures were added specifically for APFSX and HFSX.
- Computed baseline `shasum` of the populated images.
- Mounted images explicitly with `-readonly`.
- Wrote a Swift CLI tool using `FileManager.default.enumerator` configured with `includingPropertiesForKeys` to request standard volume and file metadata keys.
- Executed the enumerator deterministically (3 times per image) and compared hashes pre- and post-mount.

## 3. Results

### Read-Only Guarantee
- **PASS**: Hash checks (`shasum -a 256`) of the `.dmg` files were 100% identical before and after the `-readonly` mount and metadata extraction.

### Metadata Extraction
- **PASS**: The enumerator successfully returned relative paths, `.nameKey`, `.isDirectoryKey`, `.isSymbolicLinkKey` (without traversing or following them), file sizes, and timestamps.
- Sparse files (APFS) correctly reflected logical size `1048576` and allocated size `0`.

### Determinism
- **PASS**: 3 independent runs of the enumeration produced identical `diff` results for all file systems.

### Volume Case Sensitivity & Unicode Behavior
- **Volume Sensitivity Detection**: `volumeSupportsCaseSensitiveNamesKey` correctly reported `true` for APFSX/HFSX and `false` for APFS/HFS+.
- **Case Preservation (APFSX/HFSX)**: `Report.txt` and `REPORT.TXT` safely coexisted and were enumerated distinctly on the case-sensitive variants.
- **Unicode Canonicalization**: 
  - On APFS, the NFC and NFD strings were preserved exactly as written (e.g., retrieving the NFC file yielded exact NFC string bytes `c3 a9` and the NFD file yielded `cc 81`).
  - On HFS+, the volume natively forced NFD (`cc 81`) for both NFC and NFD writes.
  - **Conclusion**: Foundation faithfully forwards the string bytes maintained by the underlying file system. Because APFS does not automatically canonicalize filenames, FSD must enforce its own strict NFC canonicalization during the comparison phase (as outlined in ADR-009) to ensure cross-volume determinism.

### Malformed Volume Handling
- **PASS**: macOS `hdiutil attach` natively rejects the mounting of truncated (1MB) disk images. `FileManager` is completely shielded from malformed volume structures since they cannot be mounted.

## 4. Phase 0A Status
- **Phase 0A remains INCOMPLETE**. The libfsext (ext2/3/4) sub-gate has conditional production integration deferred. The Native AppleFS spike has passed feasibility. The Phase 0A exit gate has explicitly NOT been closed as per current instructions.

## 5. Artifacts
- Source, fixtures, and scripts located in `spikes/phase0a-native-applefs/`.
