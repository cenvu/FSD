# Security and Read-Only Policy

## 1. Guarantee boundary

FSD — FishSock Differ is designed to read metadata from selected source paths and write only to its own local application database and user-selected report destinations.

## 2. Allowed writes

- application database under Application Support;
- logs under the application's local container or support directory;
- user-requested JSON or HTML reports;
- preferences and login-item registration.

As of Milestone 3 these are the only write calls in the production target, and each is named here so the list can be checked against the code rather than trusted:

| Call site | What it writes | Why it is allowed |
|---|---|---|
| `CatalogDatabase.init` | creates the catalog's own directory | FSD's catalog, under Application Support or an explicit DEBUG override (ADR-026) |
| `CatalogProcessLock.init` | creates and writes `<catalog>.lock` | Beside the catalog, never on a source (ADR-025) |
| `JSONSnapshotExporter.export(snapshotID:to:)` | creates and writes the export file | A destination the user chose in a save panel |

`JSONSnapshotExporter` is also the only place a `FileHandle` appears in production, and it is opened **for writing only**, to that chosen destination. There is no `FileHandle(forReadingFrom:)`, no `Data(contentsOf:)` on a source path, no hashing API, and no `FileManager` mutation call anywhere in the target; the only file-content read in the whole application is its own bundled `schema.sql`.

### 2.1 Bounded Byte Reads for Explicit Classification (verified implementation)

filetype v1.1.3 is the BRAIN-accepted production provider; ADR-035 integration is implemented by task033A (`556872844b90640cc2a64e40d99594a78cef61af`) and independently audited by task034 (accepted `PASS_WITH_ADVISORY` at publication `9d1a8ea237c6c2941895b1c3640118371d2e2d4d`). Task035 verifies the physical runtime and synchronizes status; final independent implementation audit and Phase 1.5 BRAIN acceptance remain pending. The preceding Milestone-3 inventory describes the pre-runtime milestone; this subsection is the current classification call-site inventory.

| Verified call site | Authority and effect |
|---|---|
| `SnapshotBrowserView` selected-entry button → `SnapshotBrowserModel.classifySelectedFile` → `productionStart` | Sole explicit UI trigger; constructs the bundled filetype provider. |
| `ClassificationRuntimeService.start` → `BoundedClassificationSourceReader.readPrefix` | FSD owns source identity, schema-v9 root locator, regular-file eligibility and no-follow descriptor-relative resolution. Pre-read object barrier binds dev+ino; post-read revalidation may fail closed. |
| `DarwinBoundedSourceFilesystem.readOnce` | One `Darwin.read` at offset zero, maximum 4096 bytes; no retry, tail, adaptive read, full-file read API or content hashing. Small files return only their actual bytes, which may all fit in that prefix. |
| `BundledFiletypeClassificationProvider` → `FoundationHelperProcessRunner` | Receives immutable bounded `Data` only; fixed bundle helper, no arguments, empty environment, one bounded stdin delivery. No original path/URL/fd/FileHandle/resolver/extra-byte/range capability. |
| `HelperPipePump` and `HelperMetadataEnvelope` | Cumulative stdout/stderr caps 4096 each; strict seven-field metadata envelope; stderr discarded. The `FileHandle`s here belong only to child pipes, never classified source files. |
| `ClassificationRuntimeService.mappedResult` → `EntryClassificationRepository.append` | Four row-writing outcomes / three no-row outcomes; `noMatch`, `unavailable`, `cancelled` write zero rows. Host-owned provenance only; no sample, content hash, source path or diagnostic persistence. |

Bytes read for classification are never written to storage, hashed or logged. The adapter operates offline with no runtime network or telemetry, no downloader, automatic invocation, bulk action, queue, retry, watcher or backfill. Capture, launch, history open, snapshot reopen, ordinary browsing/selection, search, comparison and JSON export remain zero-invocation workflows. Immutable snapshot/entry facts and historical comparison meaning are unchanged; JSON export remains version 1 and excludes classification.

Task035 current verification: clean Debug/Release arm64 builds passed; full Debug 494 executed / 491 passed / 0 failed / 3 existing external-probe skips; focused classification/isolation/schema 242 executed / 242 passed / 0 failed / 0 skipped; supplemental schema-safety 18 executed / 18 passed / 0 failed / 0 skipped. Exact commands, durations and per-suite counts: [FSD_P15_WHOLE_RUNTIME_VERIFICATION_D_20261007-015634.md](../handoffs/FSD_P15_WHOLE_RUNTIME_VERIFICATION_D_20261007-015634.md). Actual helper SHA256 `665a6569ee60614313e50629c4166358b89859f15dac4c522905ee5a730752e7`; detector `github.com/h2non/filetype@v1.1.3`; provider `fsd.bundled-helper-host.v1`. Fresh bundles preserve exact helper and notices. **AGENT-OBSERVED:** six real PNG runs had zero helper sockets/descendants, bounded to those runs; the already-audited dependency/API boundary corroborates offline behavior.

General realistic legacy DOC/XLS/PPT determinism remains unproven.
Available pinned realistic PNG/DOCX/XLSX/PPTX bounded fixtures were single-valued in accepted implementation/audit evidence.
The demonstrated short legacy-CFB ambiguity is neutralized by the guard.

Source proofs are point-in-time object authority, not filesystem namespace locks. Classification remains inferred current-source metadata, never historical content verification. Task034's Reviewer-only Go introspection telemetry counter was audit-process footprint, not a product defect; task035 invokes no Go and changes no Owner-global Go configuration/telemetry mode. **MANUAL NOT PERFORMED:** **NOT PERFORMED — DEFERRED BY OWNER** (visual UI, VoiceOver, physical media). No Developer ID, notarization or App Store readiness is claimed.

## 3. Prohibited writes

The application must not write to scanned source volumes:

- catalog databases;
- hidden files;
- marker files;
- thumbnails;
- extended attributes;
- tags;
- Finder comments;
- modified timestamps;
- temporary files.

## 4. Prohibited source operations

- copy;
- move;
- rename;
- delete;
- create folder;
- alter permissions;
- change ownership;
- change extended attributes;
- mount or unmount without explicit user action;
- any write syscall against a raw block device, at any privilege level.

### 4.1 Raw-device access boundary

Everything in Sections 3–4 applies identically whether the source is a macOS-mounted volume or a raw partition device (`FILESYSTEM_PROVIDER_ARCHITECTURE.md`). Specifically:

- `EmbeddedRawProvider` and its adapters open a raw device or disk image with `O_RDONLY` (or the read-only equivalent of whatever handle mechanism is used) and request nothing else — never `O_RDWR`, never a write-capable `authopen` grant.
- FSD does not build a custom privileged helper, root daemon, or `SMJobBless`/`SMAppService` service to gain raw-device access. The only authorization mechanism in scope is the system `/usr/libexec/authopen` utility, requested read-only, scoped to one device, one time (`DECISIONS.md` ADR-016).
- If a user declines an authorization prompt, the capture for that volume does not happen. There is no write-capable fallback and no silent privilege escalation.
- The filesystem parser reading raw device/image bytes runs in an isolated helper process with no access to any path but the one handle it was given (`FILESYSTEM_PROVIDER_ARCHITECTURE.md` §8) — this treats the parser as untrusted input, independent of the read-only guarantee itself.

## 5. Implementation controls

- scanner services receive read-only URLs (or read-only raw handles) and expose no mutation methods;
- source access and database access use separate service interfaces;
- code review must reject source-volume mutation APIs, including any raw-block write syscall;
- a lint/CI deny-list on write-capable filesystem APIs (`copyItem`, `moveItem`, `removeItem`, `createFile`, `setAttributes`, `replaceItem`, `trashItem`) applies to every target that can reach a `FilesystemProvider`;
- integration tests compare source filesystem state before and after capture, for both a mounted volume and a raw device;
- export destinations are selected independently from scanned paths;
- development scripts must not modify scanned media; only explicitly designated
  fixture generators may write inside their disposable fixture directory.

Unsigned ad-hoc builds must never be represented as official releases. Internal
release artifacts are prepared only under explicit distribution authorization
(ADR-006); template release directories do not establish a release requirement.

## 6. Privacy

Snapshots may reveal sensitive file and folder names. Therefore:

- catalog remains local by default;
- no analytics payload may include paths or filenames;
- exported reports must warn that they contain directory metadata;
- future cloud sync must be explicit opt-in and separately designed.


## Explicit Mount Consent Policy
1. If macOS independently auto-mounts a device, FSD may read the existing mounted volume.
2. FSD must never silently request a new mount or unmount.
3. When a readable native filesystem is not mounted, FSD may show an explicit user action: "Mount Read-Only and Capture".
4. Only after that user action may FSD request a read-only mount through the approved macOS mechanism.
5. Cancelling or denying the action performs no mount and no capture.
6. No read-write fallback exists.
