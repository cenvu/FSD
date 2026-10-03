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

### 2.1 Bounded Byte Reads for Future Classification (Not Yet Implemented)

The Phase 1.5 Magika runtime adapter will perform local reads under strict constraints:
- It uses bounded byte-range reads only (a single 4096-byte prefix read PROPOSED).
- It never reads full file payloads and never computes content hashes.
- Bytes read for classification are never written to storage, never logged to any diagnostic surface, and never persisted in any outcome.
- It operates on a memory buffer provided by the host; the classification adapter itself receives no `URL` or file handle.
- Zero network traffic: The adapter operates fully offline with no network access.
- Zero telemetry: The adapter collects and transmits zero telemetry.
- No historical backfill: It never automatically processes or backfills old snapshots.
- No background watcher: It responds only to explicit user requests, with no background watcher process.

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
