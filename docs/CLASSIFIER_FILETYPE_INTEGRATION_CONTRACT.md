# filetype v1.1.3 bounded bundled-helper integration contract

Authority: ADR-035 (`docs/DECISIONS.md`), established by
`FSD_CLASSIFIER_FILETYPE_INTEGRATION_CONTRACT_032`.
This is the single implementation contract for the later bounded task
`FSD_CLASSIFIER_FILETYPE_BUNDLED_HELPER_INTEGRATION_033`. It is a contract only.
It implements, vendors, builds, bundles and signs nothing.

```text
INTEGRATION_TARGET=filetype_v1.1.3
INTEGRATION_TARGET_SELECTED=YES
PRODUCTION_PROVIDER_SELECTED=NO
PRODUCTION_PROVIDER_ACCEPTED=NO
INTEGRATION_IMPLEMENTED=NO
INTEGRATION_AUDITED=NO
INTEGRATION_AUTHORIZED=NO            # task033 needs its own BRAIN/Owner authorization
SLICE08_STARTED=NO
UPSTREAM_PATCH=NONE
NORMAL_XCODE_REQUIRES_GO=NO
NORMAL_XCODE_REQUIRES_NETWORK=NO
```

Only a successful independent audit (`FSD_CLASSIFIER_FILETYPE_INTEGRATION_AUDIT_034`)
followed by BRAIN acceptance may make filetype the accepted production provider and
unblock Slice 08 prerequisite reasoning.

## 1. Accepted feasibility basis (task029R STOP + task029S closure)

Evidence: `handoffs/FSD_CLASSIFIER_NATIVE_FEASIBILITY_CLOSURE_D_20261006-202845.md`
(published `878d3396666a8dae00dda079046aafceb0d96e50`, BRAIN-accepted
PASS_WITH_ADVISORY). Facts carried into this contract:

| Fact | Value |
| --- | --- |
| Target | `github.com/h2non/filetype@v1.1.3` |
| Module Sum | `h1:FKkx9QbD7HR/zjK1Ia5XiBsq9zdLi5Kf3zGyFTAFkGg=` |
| Module GoModSum | `h1:319b3zT68BvV+WRj7cwy856M2ehB3HqNOt6sy1HndBY=` |
| Feasibility helper SHA256 | `e7907f75903da75b5a3649f8fc894ac304fadef17d126ca37f2b76cd2ec8e2d6` |
| Native arch / observed minos | arm64 / 13.0 (product floor macOS 15+) |
| Runtime interpreter, external model/DB, third-party module deps | NONE |
| Helper network / descendants | NONE observed / 0 observed |
| Matcher keys / unique registered types / type registry | 73 / 73 / 74 |
| Unreconciled types | 0 (the extra registry entry is the matcher-less `Unknown` sentinel) |

> [!IMPORTANT]
> The feasibility helper SHA256 above belongs to the feasibility helper only. It
> MUST NOT be claimed as the production helper SHA256: the production helper adds
> the deterministic short-CFB guard (section 4), changes source, and is built by the
> pinned official toolchain (section 9) rather than the feasibility Homebrew copy.
> The production SHA256 is recorded only after two clean independent controlled
> builds are byte-identical.

Facts the implementation must not assume carried over: the feasibility module bytes
were reused from a prior scratch cache and the feasibility toolchain was a copied
Homebrew `libexec`. Task033 re-establishes both from the exact pins below.

## 2. Locked FSD safety contract (unchanged)

```text
SOURCE_READ_ONLY=YES
PROVIDER_INPUT=DATA_ONLY
INPUT_BYTES=0...4096
```

The Swift host owns the source read (`BoundedClassificationSourceReader`). The helper
receives only the bounded bytes on stdin. The helper and upstream library receive NO
source path, URL, file descriptor, `FileHandle`, source callback, range callback or
additional-byte API. NO network runtime, telemetry, runtime downloader, sample
persistence, sample hash, sample log, source mutation, automatic classification,
watcher or backfill. Snapshot facts remain immutable. Classification is derived
inferred metadata only; a detected type is never historical content verification.

## 3. ADR-034 result semantics (unchanged, no schema change)

Typed outcomes remain exactly seven: `classified`, `failed`, `sourceChanged`,
`unsupportedEntry`, `unavailable`, `cancelled`, `noMatch`. `busy` remains
control-only. Helper `resultKind` admits exactly `classified`, `no_match`,
`unavailable`, `failed`. `no_match` requires all five metadata fields
(`detectedType`, `mimeType`, `confidence`, `detectorVersion`, `modelVersion`) null.
The envelope stays the existing strict flat seven-field object: `schemaVersion`
(integer `1`), `resultKind`, `detectedType`, `mimeType`, `confidence`,
`detectorVersion`, `modelVersion`. Row writing
is unchanged: `noMatch` writes zero `entry_classifications` rows.

The short-CFB guard (section 4) returns `no_match`. It is the successful-execution /
type-not-recognized outcome and does not conflict with ADR-034: the provider ran on the
exact bounded `Data` and no single type is truthfully recognizable.

## 4. Mandatory deterministic short-CFB policy

Accepted advisory: filetype v1.1.3 builds its matcher priority list by Go-map
iteration. The legacy DOC, XLS and PPT matchers all accept the short Compound File
Binary prefix when input length is at most 513 bytes. The same short bytes can
therefore be labelled doc, xls or ppt across fresh processes.

```text
CFB_PREFIX = D0 CF 11 E0
SHORT_CFB_GUARD = len(input) <= 513 AND input begins with CFB_PREFIX
SHORT_CFB_GUARD -> resultKind="no_match", all metadata null, ZERO filetype.Match calls
```

Rationale: the bounded bytes do not contain the upstream discriminant at offsets
512-513 needed by the long DOC/XLS/PPT branches; choosing one overlapping label
would be arbitrary.

Exact helper decision order (the only permitted order):

1. Read stdin up to `4096 + 1` bytes. If more than 4096 bytes arrived: `failed`,
   zero `Match` calls.
2. If `len == 0`: handle per section 5 (zero byte).
3. If `SHORT_CFB_GUARD`: `no_match`, zero `Match` calls.
4. Otherwise call `filetype.Match(input)` exactly once and map per section 6.

Forbidden: sorting or editing `MatcherKeys`, a custom priority list, manual category
dispatch, forking filetype, patching or vendoring-with-edits upstream source, any
additional source read. The guard is an FSD adapter truthfulness guard, not a forked
detector. The upstream module remains byte-identical to the pinned Sum.

`SHORT_CFB_GUARD=len<=513 && prefix D0CF11E0 -> noMatch before Match`

The guard grants no authority and reads no additional bytes.

## 5. Zero byte

For exactly zero bytes filetype v1.1.3 returns `types.Unknown` with
`ErrEmptyBuffer`. The helper may map this to `no_match` only under the exact accepted
condition `len == 0` AND returned type is the exact `Unknown` sentinel AND error is
exactly `ErrEmptyBuffer`. The implementation may satisfy this by calling `Match` once
and checking those three conditions, or by an explicit `len == 0` branch that is
tested to be equivalent; either way there is never more than one `Match` call. Any
other error is `failed`.

## 6. Output mapping

For a successful upstream match with a recognized (non-`Unknown`) type:

| Output field | Value |
| --- | --- |
| `resultKind` | `classified` |
| `detectedType` | direct upstream extension |
| `mimeType` | direct upstream MIME value when non-empty, else null |
| `confidence` | null |
| `modelVersion` | null |
| `detectorVersion` | `github.com/h2non/filetype@v1.1.3` |

No transformed taxonomy, no UTI synthesis, no fallback MIME, no
`application/octet-stream` substitution for `Unknown`. An upstream `Unknown` result
without error (other than the guarded cases) is `no_match`. Provider identity stays
host-owned (`providerIdentifier = fsd.bundled-helper-host.v1`) and is never emitted
by the helper.

## 7. Determinism claim (truthful wording)

Do NOT claim filetype is universally deterministic. Accepted wording:

> The integration neutralizes the demonstrated short legacy-CFB ambiguity. Available
> pinned realistic PNG/DOCX/XLSX/PPTX fixtures were single-valued in feasibility
> probes. The exact upstream pin contains no realistic legacy DOC/XLS/PPT fixtures, so
> general legacy-Office determinism is not proven.

This remains a documented advisory in every report, audit and handoff.

## 8. Provider and host naming

`BundledMagikaClassificationProvider` is historical naming and must not remain the
production name. Task033 renames it to `BundledFiletypeClassificationProvider` and
renames the project/test file names consistently. The helper bundle path remains the
provider-neutral stable host protocol location
`Contents/Helpers/FSDClassificationHostSeam` (not detector provenance). Task032 itself
performs no rename. This partially discharges ADR-033 decision 8 (naming may be
addressed after a provider is selected): the integration target is now selected, and
the rename is authorized only inside task033.

## 9. Pinned build toolchain

```text
GO_TOOLCHAIN_PIN=go1.27.1_darwin_arm64
GO_ARCHIVE=go1.27.1.darwin-arm64.tar.gz
OFFICIAL_SOURCE=https://go.dev/dl/
GO_ARCHIVE_SHA256=ee215d57e0ec269c60cc9ceca68e6bda321ba9ee5afe24f4b0988703c2d87d12
```

Task033 may download only that exact official archive for the controlled helper
build, verify its SHA256 BEFORE extraction (mismatch = STOP), and extract it into
scratch only. It may also acquire only the exact `github.com/h2non/filetype@v1.1.3`
module into the scratch module cache, verified against the module Sum and GoModSum
above and `go.sum`, and only if task033's own authorization permits that module
acquisition (otherwise STOP; do not widen). No Homebrew toolchain, no `.pkg`
installer, no system-wide install, no other module, no other download.

## 10. Controlled Go build containment

Every Go invocation in the controlled rebuild isolates all writable state under a
fresh task scratch directory `<scratch>`:

```text
TEST_TELEMETRY_DIR=<scratch>/go-telemetry
HOME=<scratch>/home
XDG_CONFIG_HOME=<scratch>/xdg-config
XDG_CACHE_HOME=<scratch>/xdg-cache
GOROOT=<scratch>/toolchain
GOPATH=<scratch>/gopath
GOMODCACHE=<scratch>/gomodcache
GOCACHE=<scratch>/gocache
GOTMPDIR=<scratch>/gotmp
TMPDIR=<scratch>/gotmp
GOENV=off
GOTOOLCHAIN=local
```

Do NOT use `GOTELEMETRY=off`. Create only scratch-local telemetry mode/state. Do NOT
run any command that changes the Owner's global Go telemetry setting. Capture
metadata-only (names, types, sizes, mtimes, inodes; never contents) before/after proof
of the user telemetry directory. `OUTSIDE_SCRATCH_WRITES` must remain zero.

## 11. Build flags and binary checks

```text
CGO_ENABLED=0
GOOS=darwin
GOARCH=arm64
go build -trimpath -buildvcs=false -ldflags="-buildid="   # empty/suppressed build ID as supported
```

Two independent clean controlled builds (separate fresh caches and scratch trees)
must produce identical bytes. The final production helper SHA256 is recorded only
after those two builds match. A mismatch is a STOP (no averaging, no picking one).

Required binary checks recorded in the manifest evidence: `file`, `lipo -info`,
`vtool` or `otool -l`, `otool -L`, `go version -m`. Required results: arm64 only,
`minos` at most 15.0, no non-system dylib, no external model/database/resource.

## 12. Normal Xcode builds do not require Go

The normal FSD Debug/Release build MUST NOT invoke Go, download Go, download
filetype, access the Go module proxy, or use the network for helper construction.
Task033 produces and commits exactly one audited native helper artifact. Xcode copies
that pinned artifact into `FSD.app`. The controlled rebuild
(`scripts/build_classification_helper.sh`) is a separate, manually invoked procedure
that exists only to reproduce or update the artifact; no Xcode build phase calls it.

## 13. Tracked helper source / artifact shape

Task033 allowlist for new tracked paths (STOP only if an existing repository
convention makes one materially unsafe; pre-mutation inspection at task032 found none:
`Tools/` and `FSD/Helpers/` do not exist, the paths are not git-ignored, and the
Xcode project uses explicit file references, so nothing is auto-included):

```text
Tools/FSDClassificationHelper/main.go
Tools/FSDClassificationHelper/go.mod
Tools/FSDClassificationHelper/go.sum
scripts/build_classification_helper.sh
FSD/Helpers/FSDClassificationHostSeam
FSD/Helpers/FSDClassificationHostSeam.manifest.json
FSD/Helpers/THIRD_PARTY_NOTICES.txt
```

`FSD/Helpers/FSDClassificationHostSeam` is the unsigned audited source artifact copied
into the bundle. It must be tracked as a binary (no text/EOL conversion; verify
`git check-attr`/`.gitattributes` do not alter it).

The manifest records at least, as one strict JSON object, no sampled bytes:

```text
schemaVersion
helperSHA256
helperSourceSHA256            # SHA256 over a defined, documented canonical source set
filetypeModule / filetypeVersion
moduleSum
goModSum
goVersion
goArchiveSHA256
GOOS / GOARCH
minos
buildFlags
detectorVersion               # "github.com/h2non/filetype@v1.1.3"
```

## 14. License / notice contract

Bundled distribution materials preserve the notice set closed by task029S:

1. filetype v1.1.3 MIT notice;
2. Go 1.27.1 `LICENSE`;
3. Go 1.27.1 `PATENTS`;
4. the linked Sun Microsystems notice required by the exact built helper's
   `math/log.go` closure (task029S inventory: `Go1.27.1/src/math/log.go` lines 17-22,
   SunPro / Sun Microsystems 1993).

Do not include unrelated Go source notices merely because files existed in the
toolchain. Task033 MUST rerun the linked-source notice inventory for the FINAL
production helper, because the guard changes helper source and could alter dead-code
and link closure. If the final linked notice closure differs from the set above:
STOP for BRAIN adjudication. No legal conclusion is claimed by this contract.

Explicit bundle location: `FSD.app/Contents/Resources/THIRD_PARTY_NOTICES.txt`,
copied from `FSD/Helpers/THIRD_PARTY_NOTICES.txt` by the app target's existing
Resources phase pattern (one new file reference). It is human-readable plain text.

## 15. Xcode packaging contract

- One project Copy Files phase (destination Wrapper, subpath `Contents/Helpers`)
  copies exactly one executable to `FSD.app/Contents/Helpers/FSDClassificationHostSeam`.
  `Contents/Helpers` contains no other file.
- The phase file reference carries the project's normal nested-code signing attribute
  (`CodeSignOnCopy` equivalent). The notice file is a separate Resources entry.
- No Go toolchain, source, module cache, model or database enters `FSD.app`.
- The existing project sets `CODE_SIGNING_ALLOWED=NO`. For existing signing-disabled
  Debug/Release validation, do not claim nested signing was verified.
- Task033 additionally performs a bounded local ad-hoc signing/package verification
  that needs no developer account: sign a COPY of the built app in scratch with
  `codesign --force --deep --sign -` (or inner-then-outer), then `codesign --verify
  --deep --strict` and `codesign -dv`. Record only facts actually obtained. Do NOT
  claim Developer ID, notarization or App Store signing; those are outside this
  integration unless separately authorized.

## 16. Artifact integrity

- Before packaging, tracked helper bytes SHA256 must equal the manifest `helperSHA256`.
- After copying into an unsigned signing-disabled build, bundle helper bytes must equal
  tracked helper bytes.
- For a signed copy, byte-hash equality is NOT required; verify codesign validity,
  architecture, bundle location and the designated/ad-hoc signing facts actually
  available.
- No runtime download, no self-update.

## 17. Implementation code contract (task033 allowlist)

Minimal host/provider wiring only:

- rename `FSD/Classification/BundledMagikaClassificationProvider.swift` to
  `FSD/Classification/BundledFiletypeClassificationProvider.swift`; rename the type to
  `BundledFiletypeClassificationProvider`; rename
  `FSDTests/BundledMagikaClassificationProviderTests.swift` to
  `FSDTests/BundledFiletypeClassificationProviderTests.swift`; update
  `FSD.xcodeproj/project.pbxproj` references/IDs consistently;
- update `FSD/UI/SnapshotBrowserView.swift` (explicit production classification
  constructs the filetype-backed bundled provider);
- add the helper copy phase and the notice resource to `project.pbxproj`;
- add the section 13 paths and the real-helper/bundle tests of sections 19 and 20.

Semantics of `LocalFileClassificationProvider`, `BoundedClassificationSourceReader`,
`ClassificationRuntimeService` and `EntryClassificationRepository` stay unchanged
except exhaustive naming references to the new concrete provider. Do NOT redesign the
runtime, do NOT change DB/schema, do NOT add automatic classification, do NOT change
IPC caps (stdout 4096, stderr 4096), timeout (five seconds) or the envelope.

## 18. Helper contract

The Go helper:

- takes zero command arguments;
- reads stdin only; reads at most `maximumInput + 1` (4097) bytes to reject oversize;
- never opens a classified source; never calls `MatchFile` or `MatchReader`; never
  performs a second source read;
- never writes, hashes, logs or echoes a sample; never creates descendants; never
  uses the network; writes one strict JSON envelope to stdout and nothing else.

Input at most 4096: at most one upstream `Match` call. Input greater than 4096: zero
`Match` calls, result `failed`. Short ambiguous CFB: zero `Match` calls, `no_match`.
Call counts must be proven by an executable test (a test seam or instrumented
verification build is allowed only if the shipped helper bytes are the tested bytes;
otherwise prove via behavior, not source grep).

## 19. Real-helper test plan (task033)

All tests run the actual committed helper binary (directly and through the existing
Swift host seam). No fake-runner result substitutes. A missing helper fails the test;
it must not skip.

| Area | Required cases |
| --- | --- |
| Classified | known PNG classified |
| No match | unknown bytes `no_match`; empty `no_match` |
| Bounds | exact 4096 bounded and processed; 4097 rejected before `Match` |
| Short CFB | lengths 4, 32, 513 with prefix `D0 CF 11 E0`: all deterministic `no_match` across fresh launches |
| Long CFB | synthetic CFB, length 514 or more: DOC discriminant -> `doc`; XLS -> `xls`; PPT -> `ppt` |
| Pinned fixtures | available pinned DOCX, XLSX, PPTX, PNG: each repeated across fresh helper launches and single-valued |
| Envelope | strict seven-field envelope; stdout cap; stderr cap |
| Process | zero network observation; zero descendants; normal exit; crash; SIGTERM/cancellation; five-second host timeout |
| Runtime | no stale publication; no row for `noMatch` |
| Provenance | exact `detectorVersion`; `modelVersion` nil; `confidence` nil; providerIdentifier host-owned |
| Authority | source/path authority absent; sample persistence absent |

> [!WARNING]
> The short-CFB cases must never be removed or weakened because they look like an odd
> synthetic edge. They are the regression guard for a demonstrated real upstream
> nondeterminism. A later implementer may not delete them.

Additional guard-edge requirement: a CFB-prefixed input of length 514 or more whose
discriminant matches none of the long branches must be probed across fresh helper
launches. If any CFB-prefixed length at least 514 is multi-valued across launches,
STOP for BRAIN. Do not extend the guard past 513 inside task033 (it would change
accepted contract semantics).

No general legacy DOC/XLS/PPT fixture claim: synthetic discriminant tests prove the
adapter guard and upstream branch routing only, not realistic-document determinism.

## 20. Bundle / integration tests (task033)

Build the actual FSD app and inspect the built bundle. Require: helper exists exactly
at `Contents/Helpers/FSDClassificationHostSeam`; helper arm64; helper `minos` at most
15; helper/manifest hash correspondence for the unsigned artifact; the notice resource
present at `Contents/Resources/THIRD_PARTY_NOTICES.txt`; no Go toolchain, no Go
cache, no module source, no model/database; no unexpected executable in the helper
directory. Run the real bundled provider through the existing host seam
(`BundledFiletypeClassificationProvider` -> `FoundationHelperProcessRunner`), not only
direct helper invocation.

## 21. Validation required of task033

Causal RED where applicable; fresh clean Debug build; targeted real-helper
integration tests; all existing classification focused tests; full Debug suite;
clean Release build; bundle inspection; network/process observation; codesign/package
inspection appropriate to the actual signing mode; `git diff --check`; canonical
checker. No fake-runner result may substitute for real-helper evidence.

## 22. Independent audit (mandatory)

Task033 does NOT directly unblock Slice 08, and MUST NOT self-authorize its audit.
`FSD_CLASSIFIER_FILETYPE_INTEGRATION_AUDIT_034` independently reviews: source
authority; short-CFB guard truthfulness; actual upstream pin; artifact reproducibility;
manifest/hash integrity; license/notices; bundle placement; nested signing evidence;
runtime network; process tree; crash/timeout/cancellation; stdout/stderr caps;
provenance; noMatch persistence; full-suite evidence. Slice 08 remains blocked until
that audit passes and BRAIN accepts.

## 23. Stop conditions for task033

STOP and return to BRAIN if: the guard conflicts with ADR-034 in practice; truthful
determinism requires more than 4096 source bytes; any upstream modification or fork
is needed; the normal app build or runtime needs Go, module source or network; linked
notice closure differs or is no longer bounded; two controlled builds differ; the
archive or module identity does not match its pin; any write lands outside scratch;
the nested helper placement cannot satisfy the fixed bundle path; a CFB-prefixed length
at least 514 is multi-valued; another active authority outside the allowlist must
change; or a bounded implementation requires redesigning Slice 03/04 semantics. Do not
implement around a contradiction.

## 24. Not claimed

No production-provider acceptance; no general classifier determinism; no legal
conclusion; no Developer ID / notarization / App Store signing; no realistic legacy
DOC/XLS/PPT fixture coverage; no implementation exists.
